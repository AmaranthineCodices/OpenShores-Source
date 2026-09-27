# OpenShores Build Guide

OpenShores uses CMake. Docker builds are the default, with native Linux builds available for development.

## Requirements

- Docker with Linux container support
- GNU Make
- Bash

Docker Desktop can be used on Windows.

## Installing WSL and Docker on Windows

Open PowerShell as Administrator and install WSL:

```powershell
wsl --install -d Ubuntu
```

Restart Windows, open Ubuntu, and finish its user setup. Then install Docker Desktop, enable its WSL 2 engine, and enable integration for Ubuntu under **Settings > Resources > WSL Integration**.

Alternatively, skip Docker Desktop and install Docker Engine directly inside Ubuntu using Docker's [Ubuntu installation guide](https://docs.docker.com/engine/install/ubuntu/).

Inside Ubuntu, install the remaining tools and verify Docker:

```bash
sudo apt update
sudo apt install git make
docker run --rm hello-world
```

Keep the repository in the WSL filesystem, such as `~/src/OpenShores`, for better build performance than `/mnt/c`.

## Build

```bash
make client          # Linux client
make servers         # Linux multiplayer servers
make windows-client  # Windows x64 client
```

Use `make help` to list the other targets.

Linux builds support three configurations:

```bash
make CONFIG=release client
make CONFIG=debug client
make CONFIG=relwithdebinfo client
```

`release` is the default. The Windows client currently builds in release mode only.

## Output

```text
build/
├── linux-release/
│   ├── bin/
│   └── lib/
└── windows-release/
    ├── bin/
    └── lib/
```

The Windows `bin/` directory contains `AuSceneClient.exe`, its DLLs, and its Qt plugins. Keep the whole directory together.

## Build Cache

Source files are bind-mounted read-only into the build containers. CMake objects and metadata are stored in separate Docker volumes:

```text
hazeron-linux-release-cache
hazeron-windows-release-cache
```

Only final `bin/` and `lib/` files are written under `build/`.

## Native Linux Build

```bash
make native-client
make native-servers
make native-build
```

Native builds require CMake, Ninja, Qt 5, OpenGL, OpenAL, and SDL2 development packages.

## Clean

```bash
make clean    # Remove artifacts and build-cache volumes
make rebuild  # Clean and rebuild all migrated Linux programs
```

Docker toolchain images are not removed by `make clean`.
