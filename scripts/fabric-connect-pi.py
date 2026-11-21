#!/usr/bin/env python3
"""Connect a Synadia Fabric Pi agent and fix its generated OpenAI configuration.

Fabric generates a Pi profile that uses Chat Completions. For gpt-6.2-sol,
that endpoint rejects requests that combine reasoning with function tools.
After Fabric connects the agent, this script updates that model's entry in
the profile's models.json to use the Responses API and enable reasoning in Pi.
Pi still uses the Fabric proxy and the agent's model key, so the proxy must
support /v1/responses.

The script reads OPENAI_FABRIC_KEY and passes it to Fabric through
OPENAI_API_KEY, Fabric's documented fallback for --provider-key. This keeps
the upstream key out of command-line arguments.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


MODEL = "gpt-6.2-sol"


def configure_responses(path):
    config = json.loads(path.read_text(encoding="utf-8"))
    provider = config.get("providers", {}).get("fabric", {})
    matches = [model for model in provider.get("models", []) if model.get("id") == MODEL]
    if len(matches) != 1:
        raise ValueError(f"Expected one fabric/{MODEL} entry in {path}")

    model = matches[0]
    if model.get("api") == "openai-responses" and model.get("reasoning") is True:
        return
    model.update(api="openai-responses", reasoning=True)

    # Replace the credentials-bearing file atomically with a private temporary file.
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent, delete=False
        ) as output:
            temporary_path = Path(output.name)
            json.dump(config, output, indent=2)
            output.write("\n")
        temporary_path.replace(path)
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("agent_name")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", args.agent_name):
        parser.error("agent_name must start with a letter or digit and contain only letters, digits, dashes, or underscores")

    key = os.environ.get("OPENAI_FABRIC_KEY")
    if not key or not key.strip():
        parser.error("set OPENAI_FABRIC_KEY before running this script")

    # Fabric accepts OPENAI_API_KEY as the fallback for --provider-key.
    env = os.environ.copy()
    env["OPENAI_API_KEY"] = env.pop("OPENAI_FABRIC_KEY")
    fabric_home = Path(env.get("FABRIC_HOME") or Path.home() / ".fabric").expanduser()
    models_path = fabric_home / "agents" / args.agent_name / "pi" / "models.json"
    try:
        result = subprocess.run(
            [
                "fabric", "connect", args.agent_name, "--harness", "pi",
                "--expires", "90d", "--provider", "openai", "--model", MODEL,
            ],
            env=env,
        )
    except OSError as error:
        parser.exit(1, f"Could not run fabric connect: {error}\n")
    if result.returncode:
        parser.exit(1, f"fabric connect failed (exit {result.returncode})\n")

    try:
        configure_responses(models_path)
    except (OSError, ValueError, TypeError, AttributeError) as error:
        parser.exit(1, f"fabric connect succeeded, but the Pi profile update failed: {error}\n")
    print(f"Configured fabric/{MODEL} to use the Responses API in {models_path}")


if __name__ == "__main__":
    main()
