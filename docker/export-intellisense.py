#!/usr/bin/env python3
"""Export Docker toolchain headers for compiler-free VS Code IntelliSense."""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


def parse_arguments(entry):
    if "arguments" in entry:
        return entry["arguments"]
    return shlex.split(entry["command"])


def collect_compile_settings(database):
    include_directories = []
    definitions = []
    seen_includes = set()
    seen_definitions = set()

    for entry in database:
        arguments = parse_arguments(entry)
        index = 1
        while index < len(arguments):
            argument = arguments[index]
            include = None
            definition = None
            if argument in ("-I", "-isystem", "-iquote") and index + 1 < len(arguments):
                include = arguments[index + 1]
                index += 1
            elif argument.startswith("-I") and len(argument) > 2:
                include = argument[2:]
            elif argument == "-D" and index + 1 < len(arguments):
                definition = arguments[index + 1]
                index += 1
            elif argument.startswith("-D") and len(argument) > 2:
                definition = argument[2:]

            if include:
                path = str(Path(include).resolve())
                if path not in seen_includes:
                    seen_includes.add(path)
                    include_directories.append(path)
            if definition and definition not in seen_definitions:
                seen_definitions.add(definition)
                definitions.append(definition)
            index += 1

    return include_directories, definitions


def compiler_settings(compiler):
    environment = dict(os.environ, CCACHE_DISABLE="1")
    common = [compiler, "-std=c++11", "-E", "-x", "c++", "-"]
    include_result = subprocess.run(
        [*common, "-v"], input="", text=True, capture_output=True,
        check=True, env=environment,
    )
    macro_result = subprocess.run(
        [compiler, "-std=c++11", "-dM", "-E", "-x", "c++", "-"],
        input="", text=True, capture_output=True, check=True, env=environment,
    )

    include_directories = []
    reading = False
    for line in include_result.stderr.splitlines():
        if line == "#include <...> search starts here:":
            reading = True
            continue
        if reading and line == "End of search list.":
            break
        if reading:
            path = line.strip()
            if path:
                include_directories.append(str(Path(path).resolve()))

    if not include_directories:
        raise RuntimeError(f"could not read include paths from {compiler}")
    return include_directories, macro_result.stdout


def is_under(path, root):
    try:
        Path(path).relative_to(root)
        return True
    except ValueError:
        return False


def copy_tree_contents(source, destination):
    if not source.is_dir():
        return
    shutil.copytree(source, destination, dirs_exist_ok=True, symlinks=False)


def replace_directory(source, destination):
    backup = destination.with_name(f".{destination.name}.old")
    if backup.exists():
        shutil.rmtree(backup)
    if destination.exists():
        destination.rename(backup)
    try:
        source.rename(destination)
    except BaseException:
        if backup.exists() and not destination.exists():
            backup.rename(destination)
        raise
    if backup.exists():
        shutil.rmtree(backup)


def write_defines(path, compiler_macros, definitions):
    lines = [compiler_macros.rstrip(), "", "/* CMake target definitions. */"]
    for definition in definitions:
        name, separator, value = definition.partition("=")
        if not name.isidentifier():
            continue
        lines.extend((f"#ifndef {name}", f"#define {name} {value if separator else '1'}", "#endif"))
    path.write_text("\n".join(lines) + "\n")


def rewrite_database(
    database, source_root, build_root, workspace_root, output_root, external_includes
):
    editor_root = f"{workspace_root}/build/editor/{output_root.name}"
    external = {
        str(path): f"{editor_root}/include/{index:02d}"
        for index, path in enumerate(external_includes)
    }

    def rewrite_path(value):
        if value == str(source_root) or value.startswith(str(source_root) + "/"):
            return workspace_root + value[len(str(source_root)):]
        if value == str(build_root) or value.startswith(str(build_root) + "/"):
            return editor_root + "/generated"
        if value in external:
            return external[value]
        return value

    rewritten = []
    for entry in database:
        copy = {key: value for key, value in entry.items() if key not in ("command", "arguments")}
        for key in ("directory", "file", "output"):
            if key in copy:
                copy[key] = rewrite_path(copy[key])

        original = parse_arguments(entry)
        arguments = [Path(original[0]).name]
        index = 1
        while index < len(original):
            argument = original[index]
            if argument in ("-I", "-isystem", "-iquote") and index + 1 < len(original):
                arguments.extend((argument, rewrite_path(original[index + 1])))
                index += 2
                continue
            if argument.startswith("-I") and len(argument) > 2:
                arguments.append("-I" + rewrite_path(argument[2:]))
            else:
                arguments.append(rewrite_path(argument))
            index += 1
        copy["arguments"] = arguments
        rewritten.append(copy)
    return rewritten


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--compile-commands", required=True, type=Path)
    parser.add_argument("--compiler", required=True)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--build-root", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--workspace-root", required=True)
    parser.add_argument("--image-id", required=True)
    arguments = parser.parse_args()

    source_root = arguments.source_root.resolve()
    build_root = arguments.build_root.resolve()
    output_root = arguments.output_root
    output_root.mkdir(parents=True, exist_ok=True)

    database = json.loads(arguments.compile_commands.read_text())
    compile_includes, definitions = collect_compile_settings(database)
    compiler_includes, compiler_macros = compiler_settings(arguments.compiler)
    all_includes = list(dict.fromkeys([*compile_includes, *compiler_includes]))

    external_includes = [
        Path(path) for path in all_includes
        if not is_under(path, source_root) and not is_under(path, build_root)
    ]
    generated_includes = [
        Path(path) for path in compile_includes
        if Path(path) == build_root / "generated"
    ]

    image_marker = output_root / "image-id"
    snapshot_key = f"2:{arguments.image_id}"
    if not image_marker.exists() or image_marker.read_text().strip() != snapshot_key:
        include_temp = Path(tempfile.mkdtemp(prefix=".include-", dir=output_root))
        try:
            for index, source in enumerate(external_includes):
                copy_tree_contents(source, include_temp / f"{index:02d}")
            replace_directory(include_temp, output_root / "include")
        finally:
            if include_temp.exists():
                shutil.rmtree(include_temp)
        image_marker.write_text(snapshot_key + "\n")

    generated_temp = Path(tempfile.mkdtemp(prefix=".generated-", dir=output_root))
    try:
        for source in generated_includes:
            copy_tree_contents(source, generated_temp)
        replace_directory(generated_temp, output_root / "generated")
    finally:
        if generated_temp.exists():
            shutil.rmtree(generated_temp)

    defines_temp = output_root / ".defines.h.tmp"
    write_defines(defines_temp, compiler_macros, definitions)
    defines_temp.replace(output_root / "defines.h")

    rewritten = rewrite_database(
        database,
        source_root,
        build_root,
        arguments.workspace_root,
        output_root,
        external_includes,
    )
    database_temp = output_root / ".compile_commands.json.tmp"
    database_temp.write_text(json.dumps(rewritten, indent=2) + "\n")
    database_temp.replace(output_root / "compile_commands.json")

    metadata = {
        "compiler": arguments.compiler,
        "image": arguments.image_id,
        "includeDirectories": [str(path) for path in external_includes],
    }
    metadata_temp = output_root / ".metadata.json.tmp"
    metadata_temp.write_text(json.dumps(metadata, indent=2) + "\n")
    metadata_temp.replace(output_root / "metadata.json")


if __name__ == "__main__":
    main()
