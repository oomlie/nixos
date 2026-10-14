import argparse
import json
import urllib.error
import urllib.request


def load_env(path):
    values = {}
    try:
        with open(path, encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                name, value = line.split("=", 1)
                values[name.strip()] = value.strip().strip("'\"")
    except OSError:
        pass
    return values


def request_cloudflare(url, method, headers, body):
    data = json.dumps(body).encode()
    headers = dict(headers)
    headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        raise RuntimeError(f"{method} {url} -> {exc.code}: {detail}") from None
    except urllib.error.URLError as exc:
        raise RuntimeError(f"{method} {url} unreachable: {exc.reason}") from None


def email(args):
    env = load_env(args.env_file)
    token = env.get("CF_EMAIL_TOKEN", "")
    account = env.get("CF_ACCOUNT_ID", "")
    zone = env.get("CF_ZONE_ID", "")
    domain = env.get("EMAIL_DOMAIN", "daze.lol")
    if not (token and account and zone):
        raise SystemExit("missing CF_EMAIL_TOKEN/CF_ACCOUNT_ID/CF_ZONE_ID in env file")
    address = f"{args.user}@{domain}"
    destination = args.email.strip()
    if not destination or "@" not in destination:
        raise SystemExit("invalid destination email")
    headers = {"Authorization": f"Bearer {token}"}
    base = "https://api.cloudflare.com/client/v4"
    request_cloudflare(
        f"{base}/accounts/{account}/email/routing/addresses",
        "POST",
        headers,
        {"email": destination},
    )
    request_cloudflare(
        f"{base}/zones/{zone}/email/routing/rules",
        "POST",
        headers,
        {
            "actions": [{"type": "forward", "value": [destination]}],
            "matchers": [{"field": "to", "type": "literal", "value": address}],
            "enabled": True,
            "name": f"Forward {address}",
        },
    )
    print(f"email routing {address} -> {destination} (pending verification)")


def self_test(_args):
    assert load_env("") == {}
    values = load_env("/nonexistent")
    assert values == {}
    print("tilde provision self-test passed")


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(required=True)
    email_parser = subparsers.add_parser("email")
    email_parser.add_argument("--user", required=True)
    email_parser.add_argument("--email", required=True)
    email_parser.add_argument("--env-file", required=True)
    email_parser.set_defaults(func=email)
    test_parser = subparsers.add_parser("self-test")
    test_parser.set_defaults(func=self_test)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
