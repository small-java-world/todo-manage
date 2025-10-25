import os
import sys
import argparse
import json
from typing import Any, Dict

try:
    import requests  # type: ignore
except Exception as e:
    print("requests is required. Run: pip install -r requirements.txt", file=sys.stderr)
    raise

API_URL = os.getenv("API_URL", "http://localhost:8000").rstrip("/")


def req(method: str, path: str, **kwargs) -> "requests.Response":
    url = f"{API_URL}{path}"
    return requests.request(method, url, timeout=10, **kwargs)


def cmd_health(_: argparse.Namespace) -> None:
    r = req("GET", "/")
    r.raise_for_status()
    print(json.dumps(r.json(), ensure_ascii=False, indent=2))


def cmd_list(args: argparse.Namespace) -> None:
    params = {
        "type": "task",
        "status": args.status,
        "limit": args.limit,
        "fields": "hid,title,status,updated_at",
    }
    r = req("GET", "/tasks", params=params)
    r.raise_for_status()
    try:
        print(json.dumps(r.json(), ensure_ascii=False, indent=2))
    except Exception:
        print(r.text)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="TODO API minimal client")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("health", help="GET /")
    sp.set_defaults(func=cmd_health)

    sp = sub.add_parser("list", help="GET /tasks (minimal fields)")
    sp.add_argument("--status", default="in_progress")
    sp.add_argument("--limit", type=int, default=5)
    sp.set_defaults(func=cmd_list)

    args = p.parse_args(argv)
    try:
        args.func(args)
        return 0
    except requests.HTTPError as e:  # type: ignore
        print(f"HTTP error: {e} — {getattr(e.response, 'text', '')}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
