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

def host_to_container_path(host_path: str, user: str) -> tuple[str, str]:
    """
    Convert host path to container path.

    Args:
        host_path: Path on host (e.g., /Users/ralph5/Dev)
        user: ralph5

    Returns:
        (suffix, container_path) - e.g., ("/Dev", "/home/ralph5/Dev")
    """
    home = os.environ.get("HOME", "")
    if not host_path.startswith(home):
        raise ValueError(
            f"Path must start with $HOME ({home}), got: {host_path}"
        )

    suffix = host_path[len(home):]
    container_path = f"/home/{user}{suffix}"
    return suffix, container_path


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
    mount_suffix, container_mount = host_to_container_path(args.mount, user)
    folder_suffix, container_folder = host_to_container_path(args.folder, user)

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


if __name__ == "__main__":
    main()