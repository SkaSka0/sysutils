#!/usr/bin/env python3
import json
import sys
from pathlib import Path

HELP_FILE = Path.home() / ".local/bin/utils/keybind_help.json"

def normalize_key(mods, primary):
    # bikin format konsisten: SUPER_C, CTRL_ALT_T, dll.
    tokens = mods + ([primary] if primary else [])
    return "_".join(tokens).upper()

def main():
    if len(sys.argv) < 2:
        print("Usage: check_keybind.py 'SUPER, C'")
        sys.exit(1)

    # argumen misalnya "SUPER, C"
    raw = sys.argv[1]
    tokens = [t.strip().upper() for t in raw.split(",")]
    mods = tokens[:-1] if len(tokens) > 1 else tokens
    primary = tokens[-1] if len(tokens) > 1 else ""

    new_key = normalize_key(mods, primary)

    # load JSON
    try:
        with open(HELP_FILE, "r") as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        sys.exit(1)

    # flatten semua keybind
    all_keys = []
    for category, binds in data.items():
        for bind in binds:
            all_keys.append((bind["normalized_key"], bind["key"], category, bind["description"]))

    # cek apakah sudah ada
    for nk, display, cat, desc in all_keys:
        if nk == new_key:
            print(f"❌ Keybind '{raw}' sudah dipakai!")
            print(f"   → Category: {cat}, Action: {desc}, Display: {display}")
            sys.exit(0)

    print(f"✅ Keybind '{raw}' belum dipakai, aman untuk digunakan.")

if __name__ == "__main__":
    main()
