#!/usr/bin/env python3

import json
import argparse
from pathlib import Path

# =========================================================
# CONFIG
# =========================================================

CATEGORY_ICONS = {
    "custom": "󰘳",
    "launcher": "󰣇",
    "session": "󰐥",
    "brightness": "󰃟",
    "media": "󰎆",
    "system": "󰒓",
    "workspace": "󰆍",
    "workspace_extra": "󰆍",
    "window_workspace": "󰖲",
    "window_movement": "󰆾",
    "window_resize": "󰩨",
    "window_resize_extra": "󰩨",
    "window_actions": "󰖯",
    "window_groups": "󰕴",
    "window_groups_extra": "󰕴",
    "window_layout": "󰝘",
    "special_workspaces": "󰠱",
    "applications": "󰀻",
    "applications_extra": "󰀻",
    "screenshots": "󰄀",
    "recording": "󰻃",
    "audio": "󰕾",
    "clipboard": "󰅍",
    "utilities_extra": "󰨸",
    "testing": "󰙨"
}

VALID_BIND_TYPES = {"bind", "binde", "bindl", "bindle", "bindm"}

DANGEROUS_KEYWORDS = {
    "kill",
    "suspend",
    "hibernate",
    "shutdown",
    "reboot",
    "lock",
    "close"
}

REPEATABLE_BIND_TYPES = {"binde", "bindle"}

MODIFIERS = {"SUPER", "SHIFT", "CTRL", "ALT"}

DISPLAY_REPLACEMENTS = {
    "mouse:272": "MOUSE_LEFT",
    "mouse:273": "MOUSE_RIGHT",
    "mouse_up": "MOUSE_UP",
    "mouse_down": "MOUSE_DOWN",
    "XF86AudioRaiseVolume": "VOLUME_UP",
    "XF86AudioLowerVolume": "VOLUME_DOWN",
}

# =========================================================
# HELPERS
# =========================================================

def normalize_key(key: str):
    return key.upper().replace(" + ", "_").replace(" ", "_")


def tokenize_key(key: str):
    return [x.strip().upper() for x in key.split("+")]


def extract_mods(tokens):
    return [t for t in tokens if t in MODIFIERS]


def extract_primary_key(tokens):
    non_mods = [t for t in tokens if t not in MODIFIERS]
    return non_mods[-1] if non_mods else ""


def prettify_display(key: str):
    display = key

    for k, v in DISPLAY_REPLACEMENTS.items():
        display = display.replace(k, v)

    return display


def is_dangerous(action: str, description: str):
    text = f"{action} {description}".lower()
    return any(word in text for word in DANGEROUS_KEYWORDS)


def is_hidden(category: str, action: str):
    category = category.lower()
    action = action.lower()

    return "testing" in category or "interrupt" in action


def generate_search_blob(entry, category):
    parts = [
        category,
        entry.get("key", ""),
        entry.get("action", ""),
        entry.get("description", "")
    ]

    return " ".join(parts).lower()


def enrich_entry(entry, category):
    key = entry.get("key", "")
    bind_type = entry.get("type", "bind")

    tokens = tokenize_key(key)

    return {
        **entry,
        "category": category,
        "display": prettify_display(key),
        "mods": extract_mods(tokens),
        "primary_key": extract_primary_key(tokens),
        "key_tokens": tokens,
        "normalized_key": normalize_key(key),
        "repeatable": bind_type in REPEATABLE_BIND_TYPES,
        "dangerous": is_dangerous(
            entry.get("action", ""),
            entry.get("description", "")
        ),
        "hidden": is_hidden(
            category,
            entry.get("action", "")
        ),
        "category_icon": CATEGORY_ICONS.get(category, ""),
        "search": generate_search_blob(entry, category)
    }

# =========================================================
# VALIDATION
# =========================================================

def validate_category(category):
    if category not in CATEGORY_ICONS:
        raise ValueError(
            f"Invalid category '{category}'.\n"
            f"Available categories:\n"
            f"  {', '.join(CATEGORY_ICONS.keys())}"
        )


def validate_bind_type(bind_type):
    if bind_type not in VALID_BIND_TYPES:
        raise ValueError(
            f"Invalid bind type '{bind_type}'.\n"
            f"Available types:\n"
            f"  {', '.join(sorted(VALID_BIND_TYPES))}"
        )

# =========================================================
# CRUD HELPERS
# =========================================================

def reassign_ids(data):
    new_id = 1

    for category, items in data.items():
        for item in items:
            item["id"] = new_id
            new_id += 1

    return data


def generate_new_id(data):
    existing_ids = [
        item["id"]
        for items in data.values()
        for item in items
        if "id" in item
    ]

    return max(existing_ids, default=0) + 1


def add_entry(data, entry):
    entry["id"] = generate_new_id(data)

    category = entry["category"]

    if category not in data:
        data[category] = []

    data[category].append(entry)

    return data


def update_entry(data, entry_id, updates):
    for category, items in data.items():
        for item in items:
            if item.get("id") == entry_id:
                item.update(updates)
                return data

    raise ValueError(f"ID {entry_id} not found")


def delete_entry(data, entry_id):
    for category, items in data.items():
        for i, item in enumerate(items):
            if item.get("id") == entry_id:
                del items[i]
                return reassign_ids(data)

    raise ValueError(f"ID {entry_id} not found")

# =========================================================
# PROCESSOR
# =========================================================

def process_json(data):
    generated = {}

    for category, items in data.items():
        generated[category] = []

        for item in items:
            generated_item = enrich_entry(item, category)
            generated[category].append(generated_item)

    return generated

# =========================================================
# IO
# =========================================================

def load_json(path: Path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)

    except json.JSONDecodeError:
        raise ValueError("Invalid JSON format")


def save_json(path: Path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

# =========================================================
# MAIN
# =========================================================

def main():

    parser = argparse.ArgumentParser(
        prog="hyprkeys",
        description="""
Hyprland Keybind CRUD Generator

Features:
- Generate metadata automatically
- Add new keybind
- Update existing keybind
- Delete keybind
- Regenerate helper/search fields
""",
        epilog="""
Examples:

  Generate metadata:
    python script.py keybinds.json

  Generate to custom output:
    python script.py keybinds.json -o output.json

  Add new entry:
    python script.py input.json -o output.json \\
      --add "SUPER+Q" "killactive" "bind" "Close active window" \\
      --category window_actions

  Update entry:
    python script.py keybinds.json \\
      --update 10 \\
      --updates key=SUPER+W description="New Description"

  Delete entry:
    python script.py keybinds.json --delete 5

Notes:
- IDs are automatically generated
- Delete operation reassigns IDs
- Metadata is always regenerated
""",
        formatter_class=argparse.RawTextHelpFormatter
    )

    # =====================================================
    # BASIC
    # =====================================================

    parser.add_argument(
        "input",
        help="Input JSON file"
    )

    parser.add_argument(
        "-o",
        "--output",
        default="generated_keybinds.json",
        help="Output JSON file (default: generated_keybinds.json)"
    )

    # =====================================================
    # CRUD GROUP
    # =====================================================

    crud_group = parser.add_argument_group("CRUD Operations")

    crud_group.add_argument(
        "--add",
        nargs=4,
        metavar=("KEY", "ACTION", "TYPE", "DESCRIPTION"),
        help="""
Add new entry.

Arguments:
  KEY          Example: SUPER+Q
  ACTION       Example: killactive
  TYPE         Example: bind / binde / bindle
  DESCRIPTION  Human readable description
"""
    )

    crud_group.add_argument(
        "--category",
        help="""
Category for new entry.

Examples:
  launcher
  media
  window_actions
  workspace
"""
    )

    crud_group.add_argument(
        "--update",
        type=int,
        metavar="ID",
        help="Update entry by ID"
    )

    crud_group.add_argument(
        "--updates",
        nargs="+",
        metavar="KEY=VALUE",
        help="""
Fields to update.

Examples:
  key=SUPER+W
  description="New Description"
  action=fullscreen
"""
    )

    crud_group.add_argument(
        "--delete",
        type=int,
        metavar="ID",
        help="Delete entry by ID"
    )

    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    # =====================================================
    # FILE VALIDATION
    # =====================================================

    if not input_path.exists():
        print(f"[ERROR] File not found: {input_path}")
        return

    try:
        data = load_json(input_path)

    except ValueError as e:
        print(f"[ERROR] {e}")
        return

    # =====================================================
    # CRUD OPERATIONS
    # =====================================================

    try:

        # -------------------------------------------------
        # ADD
        # -------------------------------------------------

        if args.add:

            if not args.category:
                raise ValueError(
                    "--category is required when using --add"
                )

            validate_category(args.category)

            key, action, bind_type, description = args.add

            validate_bind_type(bind_type)

            new_entry = {
                "key": key,
                "action": action,
                "type": bind_type,
                "description": description,
                "category": args.category
            }

            data = add_entry(data, new_entry)

            print(
                f"[OK] Added new entry "
                f"to category '{args.category}'"
            )

        # -------------------------------------------------
        # UPDATE
        # -------------------------------------------------

        if args.update:

            if not args.updates:
                raise ValueError(
                    "--updates is required when using --update"
                )

            updates = {}

            for kv in args.updates:

                if "=" not in kv:
                    raise ValueError(
                        f"Invalid update format: {kv}\n"
                        f"Expected format: key=value"
                    )

                k, v = kv.split("=", 1)

                if k == "type":
                    validate_bind_type(v)

                if k == "category":
                    validate_category(v)

                updates[k] = v

            data = update_entry(
                data,
                args.update,
                updates
            )

            print(f"[OK] Updated entry ID {args.update}")

        # -------------------------------------------------
        # DELETE
        # -------------------------------------------------

        if args.delete:

            data = delete_entry(data, args.delete)

            print(
                f"[OK] Deleted entry ID {args.delete} "
                f"and reassigned IDs"
            )

    except ValueError as e:
        print(f"[ERROR] {e}")
        return

    # =====================================================
    # GENERATE OUTPUT
    # =====================================================

    generated = process_json(data)

    save_json(output_path, generated)

    total = sum(len(v) for v in generated.values())

    print(f"[OK] Output written: {output_path}")
    print(f"[OK] Total keybinds: {total}")

# =========================================================
# ENTRY
# =========================================================

if __name__ == "__main__":
    main()