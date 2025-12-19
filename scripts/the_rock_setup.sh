#! /bin/bash

#===----------------------------------------------------------------------===#
# Configure TheRock development environment
#
# Must be sourced from TheRock directory:
#   source build_the_rock.sh [OPTIONS]
#
# Run with --help for options.
#===----------------------------------------------------------------------===#

# ----------------------------------------------------------------------
# Verify the script is being sourced
# ----------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed"
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi

# ----------------------------------------------------------------------
# Set shell options
# ----------------------------------------------------------------------
# -e: Exit immediately if a command exits with a non-zero status
# -u: Treat unset variables as an error and exit
# -o pipefail: Pipeline returns the exit status of the rightmost command
#              to exit with a non-zero status, rather than the last command
# -x: Print each command before executing (for debugging)
#
# `set +o` outputs the current shell options as executable `set` commands,
# allowing us to capture and restore the caller's original state. This is
# important because this script is sourced, not executed in a subshell.
#
# The RETURN trap fires when the sourced script finishes (even on early
# `return`), restoring the caller's options so we don't pollute their shell.
_old_opts=$(set +o)
set -xeuo pipefail
trap 'set +x; eval "$_old_opts"' RETURN

# ----------------------------------------------------------------------
# Verify we're in the TheRock directory
# ----------------------------------------------------------------------
CURRENT_DIR=$(basename "$PWD")
if [[ "$CURRENT_DIR" != "TheRock" ]] && [[ "$CURRENT_DIR" != "_TheRock" ]]; then
  echo "Error: This script must be run from the TheRock directory."
  echo "Current directory: $PWD"
  echo "Please cd to the TheRock directory and run this script again."
  return 1
fi

# ----------------------------------------------------------------------
# Variables that control configuration
# ----------------------------------------------------------------------
# TODO: this could be set using rocm_agent_enumerator, though that won't work
# when building TheRock on a bare machine.
THEROCK_ASIC=gfx942

# Preset name
PRESET_NAME="iree-libs-debug"

# Whether to apt-get build dependencies (such as patchelf)
INSTALL_DEPS=false

# Whether configure TheRock
CONFIGURE=true

# Whether to install CMake preset, always true if build is true
INSTALL_PRESET=true

# ----------------------------------------------------------------------
#  Parse arguments and validate build variables
# ----------------------------------------------------------------------
function help() {
  cat <<EOF
Usage: ${BASH_SOURCE[0]} [OPTIONS]

Configures TheRock development environment with pre-built options.

Options:
  -h,  --help                       Display this help message
  -i,  --install-deps               Apt get install dependencies

  --no-configure                    Don't configure TheRock, only do requisite shell setup
  --no-install-preset               Don't add CMakeUserPresets.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    help
    return
    ;;
  -i | --install-deps)
    INSTALL_DEPS=true
    ;;
  --no-configure)
    CONFIGURE=false
    ;;
  --no-install-preset)
    INSTALL_PRESET=false
    ;;
  *)
    echo "unknown flag $1"
    help
    return 1
    ;;
  esac
  shift
done

# ----------------------------------------------------------------------
# apt-get install build dependencies (such as patchelf)
# ----------------------------------------------------------------------
if [[ $INSTALL_DEPS == true ]]; then
  sudo apt-get update && sudo apt-get install -y \
    git \
    gdb \
    gfortran \
    git-lfs \
    ninja-build \
    cmake \
    g++ \
    pkg-config \
    xxd \
    patchelf \
    automake \
    python3-venv \
    python3-dev \
    libegl1-mesa-dev \
    curl \
    unzip \
    libtool \
    python3-pip \
    vim \
    rsync \
    ca-certificates \
    wget \
    texinfo \
    bison \
    flex \
    jq
fi

# ----------------------------------------------------------------------
# Setup python
# ----------------------------------------------------------------------
# should upgrade environment if it already exists, harmless I would assume?
python3 -m venv .venv --prompt the-rock
# setup python
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-test.txt

# ----------------------------------------------------------------------
# Fetch submodules
# ----------------------------------------------------------------------
python3 ./build_tools/fetch_sources.py

# ----------------------------------------------------------------------
# Install CMakePresetsLocal.json with local configurations
# ----------------------------------------------------------------------
cat > CMakeUserPresets.json << EOF
{
  "version": 6,
  "configurePresets": [
    {
      "name": "${PRESET_NAME}",
      "description": "Builds IREE_LIBS, Ninja generator, default compiler, Debug",
      "generator": "Ninja",
      "binaryDir": "\${sourceDir}/build",
      "environment": {
        "PATH": "\${sourceDir}/.venv/bin:$PATH"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "amd-llvm_BUILD_TYPE": "Release",
        "THEROCK_ENABLE_ALL": "OFF",
        "THEROCK_ENABLE_IREE_LIBS": "ON",
        "Python3_EXECUTABLE": "$PWD/.venv/bin/python",
        "THEROCK_SPLIT_DEBUG_INFO": "ON",
        "THEROCK_QUIET_INSTALL": "OFF",
        "CMAKE_INSTALL_PREFIX": "..",
        "THEROCK_AMDGPU_FAMILIES": "$THEROCK_ASIC"
      }
    }
  ]
}
EOF
# "THEROCK_ENABLE_MIOPEN_PLUGIN": "ON",

# ----------------------------------------------------------------------
# CMake Configure
# ----------------------------------------------------------------------
if [[ $CONFIGURE == true ]]; then
  mkdir -p build
  cmake -B build \
      --preset=$PRESET_NAME
fi

if [[ $INSTALL_PRESET == false ]]; then
  rm CMakeUserPresets.json
fi
