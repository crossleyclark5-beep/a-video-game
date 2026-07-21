#!/usr/bin/env python3
"""Fetch a Sketchfab downloadable model (CC-BY etc.) via API token.

Usage:
  export SKETCHFAB_API_TOKEN=your_token
  python3 tools/fetch_sketchfab.py <model_uid> --out assets/models/external/sketchfab/
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request
import zipfile
from pathlib import Path


def api_get(url: str, token: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": f"Token {token}"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("uid")
    parser.add_argument("--out", default="assets/models/external/sketchfab")
    args = parser.parse_args()
    token = os.environ.get("SKETCHFAB_API_TOKEN", "").strip()
    if not token:
        print("SKETCHFAB_API_TOKEN missing — create one at https://sketchfab.com/settings/password", file=sys.stderr)
        return 2

    meta = api_get(f"https://api.sketchfab.com/v3/models/{args.uid}", token)
    name = meta.get("name", args.uid)
    faces = meta.get("faceCount", 0)
    lic = (meta.get("license") or {}).get("label", "?")
    print(f"Model: {name} | faces={faces} | license={lic}")
    if faces and faces > 25000:
        print(f"WARNING: {faces} faces may be heavy for handheld — review before integrating.")

    dl = api_get(f"https://api.sketchfab.com/v3/models/{args.uid}/download", token)
    gltf = ((dl.get("gltf") or {}).get("url")) or ((dl.get("glb") or {}).get("url"))
    if not gltf:
        print("No gltf/glb download URL in response:", json.dumps(dl)[:400], file=sys.stderr)
        return 1

    out_dir = Path(args.out) / args.uid
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / "source.zip"
    print(f"Downloading to {zip_path}…")
    urllib.request.urlretrieve(gltf, zip_path)
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(out_dir)
    (out_dir / "ATTRIBUTION.txt").write_text(
        f"Source: https://sketchfab.com/3d-models/{args.uid}\nName: {name}\nLicense: {lic}\nFaces: {faces}\n",
        encoding="utf-8",
    )
    print("Done:", out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
