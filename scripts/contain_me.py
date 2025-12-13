#!/usr/bin/env python3
"""
Generate devcontainer.json and Dockerfile for a project.

Usage:
    cd /path/to/project
    contain_me.py --name myproject

    # Or with explicit paths:
    contain_me.py --mount ~/Dev --folder ~/Dev/js/blog --name P001
"""

import argparse
import os
import re
import subprocess
from pathlib import Path


# =============================================================================
# Template engine (ported from lib/template.js)
# =============================================================================

def resolve_ifdefs(template: str, items: dict) -> str:
    """Handle {{#key}}content{{/key}} conditionals."""
    pattern = re.compile(r'\{\{#(.*?)\}\}(.*?)\{\{/(.*?)\}\}', re.DOTALL)

    while True:
        match = pattern.search(template)
        if not match:
            break

        open_key = match.group(1).strip()
        content = match.group(2)
        close_key = match.group(3).strip()

        if open_key != close_key:
            raise ValueError(
                f"Open and close keys don't match: {{{{#{open_key}}}}} vs {{{{/{close_key}}}}}. "
                "Nested conditionals not supported."
            )

        if open_key in items:
            template = template[:match.start()] + content + template[match.end():]
        else:
            template = template[:match.start()] + template[match.end():]

    return template


def apply_template(template: str, items: dict) -> str:
    """Apply mustache-style template substitution."""
    template = resolve_ifdefs(template, items)

    pattern = re.compile(r'\{\{(\w+)\}\}')

    while True:
        match = pattern.search(template)
        if not match:
            break

        key = match.group(1).strip()
        if key not in items:
            raise ValueError(f"Template expected key '{key}' but it was not provided")

        template = template[:match.start()] + str(items[key]) + template[match.end():]

    return template


# =============================================================================
# ROCm device detection
# =============================================================================

# ROCm requires access to the host's /dev/kfd (Kernel Fusion Driver, AMD's GPU
# compute interface) and /dev/dri/* (Direct Rendering Infrastructure) device
# nodes. Since the container uses the GPU drivers on the host, the container
# user must belong to the same GIDs that own these devices on the host.
#
# We query the owning GID of each device directly. It should be the groups
# 'render' and 'video' respectively, but if there's some odd configuration it
# might not be. If instead one looked up the GID of named groups you would
# almost always get the same result.

def detect_rocm_devices() -> tuple[list[str], set[int]] | None:
    """
    Detect ROCm devices and their owning GIDs.

    Returns:
        (devices, gids) tuple if ROCm available, None otherwise
        - devices: ["/dev/kfd", "/dev/dri/card0", "/dev/dri/renderD128", ...]
        - gids: unique GIDs that own these devices
    """
    kfd = Path("/dev/kfd")
    if not kfd.exists():
        return None

    devices = [str(kfd)]
    gids = {kfd.stat().st_gid}

    dri_dir = Path("/dev/dri")
    if dri_dir.exists():
        for dev in sorted(dri_dir.iterdir()):
            # /dev/dri may contain subdirectories like 'by-path' that should be
            # filtered out.  We only need to expose files that are actually
            # device drivers masquerading as files. Specifically character
            # device drivers, block drivers are for storage I/O.
            if dev.is_char_device():
                devices.append(str(dev))
                gids.add(dev.stat().st_gid)

    return devices, gids


# =============================================================================
# Machine values
# =============================================================================

def get_user() -> str:
    return os.environ.get("USER") or subprocess.run(
        ["id", "-un"], capture_output=True, text=True
    ).stdout.strip()


def get_uid() -> str:
    return subprocess.run(["id", "-u"], capture_output=True, text=True).stdout.strip()


def get_gid() -> str:
    return subprocess.run(["id", "-g"], capture_output=True, text=True).stdout.strip()


# =============================================================================
# Path utilities
# =============================================================================

def host_to_container_path(host_path: str, user: str) -> str:
    """
    Convert host path to container path.

    Args:
        host_path: Path on host (e.g., /Users/ralph5/Dev)
        user: ralph5

    Returns:
        container_path - e.g., "/home/ralph5/Dev"
    """
    home = os.environ.get("HOME", "")
    if not host_path.startswith(home):
        raise ValueError(
            f"Path must start with $HOME ({home}), got: {host_path}"
        )

    suffix = host_path[len(home):]
    container_path = f"/home/{user}{suffix}"
    return container_path


def compute_dockerfile_path(devcontainer_dir: Path, dockerfile_dir: Path) -> str:
    """Compute relative path from devcontainer.json to Dockerfile."""
    devcontainer_dir = devcontainer_dir.resolve()
    dockerfile_dir = dockerfile_dir.resolve()

    rel_path = os.path.relpath(dockerfile_dir, devcontainer_dir)
    return os.path.join(rel_path, "Dockerfile")


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate devcontainer.json and Dockerfile for a project."
    )
    cwd = str(Path.cwd())
    parser.add_argument(
        "--mount", default=cwd,
        help="Host path to mount into container (default: current directory)"
    )
    parser.add_argument(
        "--folder", default=cwd,
        help="Host path for working directory (default: current directory)"
    )
    parser.add_argument(
        "--name", required=True,
        help="Container name, also used as .devcontainer/<name>/ disambiguator"
    )
    parser.add_argument(
        "--dockerfile-dir",
        help="Where to write Dockerfile (default: .devcontainer/<name>/)"
    )
    parser.add_argument(
        "--existing-dockerfile",
        help="Path to existing Dockerfile (skips Dockerfile generation)"
    )

    args = parser.parse_args()

    # Get machine values
    user = get_user()
    uid = get_uid()
    gid = get_gid()

    # Convert host paths to container paths
    container_mount = host_to_container_path(args.mount, user)
    container_folder = host_to_container_path(args.folder, user)

    # Compute paths
    devcontainer_dir = Path.cwd() / ".devcontainer" / args.name

    if args.existing_dockerfile:
        # Use existing Dockerfile
        existing_path = Path(args.existing_dockerfile).resolve()
        dockerfile_dir = existing_path.parent
        dockerfile_path = compute_dockerfile_path(devcontainer_dir, dockerfile_dir)
        generate_dockerfile = False
    else:
        dockerfile_dir = Path(args.dockerfile_dir) if args.dockerfile_dir else devcontainer_dir
        dockerfile_path = compute_dockerfile_path(devcontainer_dir, dockerfile_dir)
        generate_dockerfile = True

    # Find templates
    script_dir = Path(__file__).resolve().parent
    assets_dir = script_dir.parent / "assets"

    devcontainer_template = (assets_dir / "devcontainer.json.mustache").read_text()

    # Template values
    items = {
        "name": args.name,
        "hostMount": args.mount,
        "containerMount": container_mount,
        "folder": container_folder,
        "user": user,
        "uid": uid,
        "gid": gid,
        "dockerfilePath": dockerfile_path,
    }

    # Add ROCm device passthrough if available
    rocm = detect_rocm_devices()
    if rocm:
        devices, gids = rocm
        device_args = [f'"--device={dev}"' for dev in devices]
        group_args = [f'"--group-add={gid}"' for gid in sorted(gids)]
        items["rocm"] = True
        items["rocmRunArgs"] = ", ".join(device_args + group_args)

    # Apply templates
    devcontainer_output = apply_template(devcontainer_template, items)

    # Create output directories
    devcontainer_dir.mkdir(parents=True, exist_ok=True)

    # Write devcontainer.json
    devcontainer_file = devcontainer_dir / "devcontainer.json"
    devcontainer_file.write_text(devcontainer_output)
    print(f"Generated {devcontainer_file}")

    # Write Dockerfile if not using existing
    if generate_dockerfile:
        dockerfile_template = (assets_dir / "Dockerfile.mustache").read_text()
        dockerfile_output = apply_template(dockerfile_template, items)
        dockerfile_dir.mkdir(parents=True, exist_ok=True)
        dockerfile_file = dockerfile_dir / "Dockerfile"
        dockerfile_file.write_text(dockerfile_output)
        print(f"Generated {dockerfile_file}")

    print(f"  User: {user} (uid={uid}, gid={gid})")
    print(f"  Mount: {args.mount} -> {container_mount}")
    print(f"  Folder: {args.folder} -> {container_folder}")
    print(f"  ROCm Support: {bool(rocm)}")


if __name__ == "__main__":
    main()