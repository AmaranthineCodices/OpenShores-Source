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

For Linux development, keep the repository under `~/src/OpenShores` in WSL for better filesystem performance. For native Windows F5 debugging, open a Windows checkout such as `C:\src\OpenShores` in Windows VS Code.

## Build

```bash
make client          # Linux client
make servers         # Linux multiplayer servers
make windows-client  # Windows x64 client
```

Use `make help` to list the other targets.

Linux and Windows builds support three configurations:

```bash
make CONFIG=release client
make CONFIG=debug client
make CONFIG=relwithdebinfo client
```

`release` is the default. Use `make CONFIG=debug windows-client` for a Windows Debug build. Each platform/configuration has its own output directory and cache.

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

## Native Linux Build

```bash
make native-client
make native-servers
make native-build
```

Native builds require CMake, Ninja, Qt 5, OpenGL, OpenAL, and SDL2 development packages.

## F5 Debugging in VS Code

Install the recommended C/C++ extension. Run and Debug groups the launch options under Linux and Windows. Each platform has Debug and RelWithDebInfo. Select one and press `F5`.

Docker builds the client. GDB runs it on the selected platform. You do not need a local compiler or CMake.

The first build also exports the Qt and compiler headers to `build/editor/`. The C/C++ extension uses them for IntelliSense. The cache refreshes when the Docker toolchain changes. CMake Tools is not required. If it is already installed, disable it for this workspace.

RelWithDebInfo gives better game performance. Some variables may be unavailable in the debugger because of optimization.

### Windows

Set up WSL and Docker as described above. Make sure Docker works without `sudo` in Ubuntu. Set Ubuntu as the default in PowerShell:

```powershell
wsl --set-default Ubuntu
```

Install [MSYS2](https://www.msys2.org/) at `C:\msys64`. Open its UCRT64 terminal and run:

```bash
pacman -Syu
pacman -S --needed mingw-w64-ucrt-x86_64-gdb
```

If the update asks you to restart the terminal, do that and finish updating before installing GDB.

Open the repository in Windows VS Code or Remote WSL. Select a Windows launch option and press `F5`. From WSL, VS Code starts Windows GDB through WSL interop. The game runs natively on Windows. No Windows Qt SDK is needed.

If you installed MSYS2 elsewhere, change `miDebuggerPath` in `.vscode/launch.json`.

### Linux

Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) and follow the [post-install steps](https://docs.docker.com/engine/install/linux-postinstall/) to run it without `sudo`.

On Ubuntu 22.04, install GDB and the runtime libraries:

```bash
sudo apt update
sudo apt install make git gdb libqt5opengl5 libqt5network5 \
    libqt5sql5-psql libopenal1 libsdl2-2.0-0 libglu1-mesa
docker run --rm hello-world
```

Open the repository in VS Code, select a Linux launch option, and press `F5`. Other distributions need libraries compatible with the Ubuntu 22.04 build.

To debug the Linux client in WSL, use `WSL: Reopen Folder in WSL`. The game needs WSLg and a working OpenGL driver.

## Clean

```bash
make clean    # Remove artifacts and build-cache volumes
make rebuild  # Clean and rebuild all migrated Linux programs
```

Docker toolchain images are not removed by `make clean`.
