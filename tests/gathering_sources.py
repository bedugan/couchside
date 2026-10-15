"""Locate real source files after the Minimap/Gathering ownership split."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATHERING_FILES = {'Gathering.lua', 'ResourceCatalog.lua', 'ResourceDifficulty.lua', 'SkillProbe.lua'}


def source_path(name):
    owner = 'Couchside_Gathering' if name in GATHERING_FILES else 'Couchside_Minimap'
    return ROOT / owner / name
