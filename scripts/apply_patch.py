#!/usr/bin/env python3
"""
SnapBridge WebApiParameter Infinite Recursion Patcher

Patches `WebApiParameter.smali` to prevent StackOverflowError on modern Android runtimes.
Replaces `toDumpString()` implementation to return an empty string immediately,
avoiding recursive object reflection loop in `objectAna` / `getFieldString`.
"""

import sys
from pathlib import Path

TARGET_METHOD_OLD = """
.method public toDumpString()Ljava/lang/String;
    .locals 0

    .line 1
    invoke-direct {p0, p0}, Lcom/nikon/snapbridge/cmru/webclient/commons/WebApiParameter;->getFieldString(Ljava/lang/Object;)Ljava/lang/String;

    .line 2
    .line 3
    .line 4
    move-result-object p0

    .line 5
    return-object p0
.end method
""".strip()

TARGET_METHOD_NEW = """
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
""".strip()

def patch_file(smali_path: Path):
    if not smali_path.exists():
        print(f"Error: {smali_path} not found.")
        return False
    
    content = smali_path.read_text(encoding="utf-8")
    
    # Try exact match or normalized match
    if TARGET_METHOD_OLD in content:
        content = content.replace(TARGET_METHOD_OLD, TARGET_METHOD_NEW)
        smali_path.write_text(content, encoding="utf-8")
        print(f"Successfully patched {smali_path.name}")
        return True
    elif TARGET_METHOD_NEW in content:
        print(f"Already patched: {smali_path.name}")
        return True
    else:
        # Fallback line-by-line replacement for toDumpString method
        print("Standard pattern not matched, attempting regex/block replacement...")
        import re
        pattern = r"\.method public toDumpString\(\)Ljava/lang/String;.*?\.end method"
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, TARGET_METHOD_NEW, content, flags=re.DOTALL)
            smali_path.write_text(content, encoding="utf-8")
            print(f"Successfully patched via regex: {smali_path.name}")
            return True
        print(f"Could not find toDumpString method in {smali_path}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python apply_patch.py <path_to_decoded_directory_or_smali_file>")
        sys.exit(1)
    
    p = Path(sys.argv[1])
    if p.is_dir():
        matches = list(p.rglob("WebApiParameter.smali"))
        if not matches:
            print(f"No WebApiParameter.smali found in {p}")
            sys.exit(1)
        for target in matches:
            patch_file(target)
    else:
        patch_file(p)

if __name__ == "__main__":
    main()
