#!/usr/bin/env python3
"""Validate EDUNEXUS's checked-in Knowledge Library catalogue (stdlib only)."""
import json
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import urlparse

CATALOG = Path("web/app/knowledge-sources.json")
REQUIRED = ("id", "title", "publisher", "url", "domain", "trust", "use", "license", "agentRoles")
ALLOWED_TRUST = {"A", "B", "C", "D"}


def main() -> int:
    errors = []
    warnings = []
    try:
        payload = json.loads(CATALOG.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read valid JSON at {CATALOG}: {exc}")
        return 1

    if not isinstance(payload, dict):
        print("ERROR: catalogue root must be an object")
        return 1
    if not isinstance(payload.get("version"), str) or not payload["version"].strip():
        errors.append("top-level version must be a non-empty string")
    sources = payload.get("sources")
    if not isinstance(sources, list) or not sources:
        errors.append("sources must be a non-empty array")
        sources = []

    seen_ids = {}
    url_records = defaultdict(list)
    for index, item in enumerate(sources):
        label = f"sources[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{label} must be an object")
            continue
        source_id = item.get("id")
        if not isinstance(source_id, str) or not source_id.strip():
            errors.append(f"{label}.id must be a non-empty string")
            source_id = f"<invalid-index-{index}>"
        elif source_id in seen_ids:
            errors.append(f"duplicate id {source_id!r} at {label}; first seen at sources[{seen_ids[source_id]}]")
        else:
            seen_ids[source_id] = index

        for key in REQUIRED:
            value = item.get(key)
            if value is None or value == "" or (isinstance(value, str) and not value.strip()):
                errors.append(f"{label}.{key} is required")
        url = item.get("url")
        if isinstance(url, str) and url.strip():
            parsed = urlparse(url)
            if parsed.scheme != "https" or not parsed.netloc:
                errors.append(f"{label}.url must be an absolute HTTPS URL")
            url_records[url.rstrip("/")].append(source_id)

        if item.get("trust") not in ALLOWED_TRUST:
            errors.append(f"{label}.trust must be one of {sorted(ALLOWED_TRUST)}")
        roles = item.get("agentRoles")
        if not isinstance(roles, list) or not roles or any(not isinstance(role, str) or not role.strip() for role in roles):
            errors.append(f"{label}.agentRoles must be a non-empty array of non-empty strings")
        elif len(roles) != len(set(roles)):
            errors.append(f"{label}.agentRoles contains duplicate role names")

        if not item.get("knowledgePolicy"):
            if not (isinstance(source_id, str) and source_id.startswith("chunk-")):
                warnings.append(f"{label} ({source_id}): knowledgePolicy is absent; review whether metadata/synthesis policy should be explicit")

    for url, ids in sorted(url_records.items()):
        if len(ids) > 1:
            chunk_ids = [value for value in ids if isinstance(value, str) and value.startswith("chunk-")]
            source_ids = [value for value in ids if value not in chunk_ids]
            if chunk_ids and source_ids:
                print(f"INFO: URL shared by source and synthesized chunk records: {url} -> {', '.join(str(x) for x in ids)}")
            else:
                warnings.append(f"URL shared by multiple non-chunk records; review for intentional editions/aliases: {url} -> {', '.join(str(x) for x in ids)}")

    print(f"Catalogue version: {payload.get('version', '<missing>')}")
    print(f"Records checked: {len(sources)}")
    print(f"Unique IDs: {len(seen_ids)}")
    print(f"Errors: {len(errors)} | Warnings: {len(warnings)}")
    for error in errors:
        print(f"ERROR: {error}")
    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        return 1
    print("PASS: catalogue structure and safety invariants are valid; warnings require editorial review.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
