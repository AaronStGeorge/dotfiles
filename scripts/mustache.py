"""
Minimal mustache-style template engine.

Supports:
    {{key}}                  - substitution; error if key is missing
    {{#key}}content{{/key}}  - conditional; content kept if key is present,
                               dropped otherwise. Nesting not supported.

Usage (from a sibling script in this directory):
    import mustache
    output = mustache.apply_template(template_text, {"name": "value"})
"""

import re


def resolve_ifdefs(template: str, items: dict) -> str:
    """Handle {{#key}}content{{/key}} conditionals."""
    pattern = re.compile(r"\{\{#(.*?)\}\}(.*?)\{\{/(.*?)\}\}", re.DOTALL)

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
            template = template[: match.start()] + content + template[match.end() :]
        else:
            template = template[: match.start()] + template[match.end() :]

    return template


def apply_template(template: str, items: dict) -> str:
    """Apply mustache-style template substitution."""
    template = resolve_ifdefs(template, items)

    pattern = re.compile(r"\{\{(\w+)\}\}")

    while True:
        match = pattern.search(template)
        if not match:
            break

        key = match.group(1).strip()
        if key not in items:
            raise ValueError(f"Template expected key '{key}' but it was not provided")

        template = template[: match.start()] + str(items[key]) + template[match.end() :]

    return template
