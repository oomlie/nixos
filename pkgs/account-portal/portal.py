import argparse
import base64
import html
import hmac
import http.server
import os
import pwd
import re
import sqlite3
import struct
import subprocess
import tempfile
import urllib.parse
from datetime import datetime, timezone


USERNAME = re.compile(r"^[a-z][a-z0-9_]{0,30}$")
RESERVED = {
    "adm",
    "agate",
    "auth",
    "bin",
    "caddy",
    "cdn",
    "chat",
    "code",
    "crawl",
    "daemon",
    "drive",
    "drop",
    "forgejo",
    "ftp",
    "games",
    "gemini",
    "git",
    "gopher",
    "halt",
    "halo",
    "harness",
    "hold",
    "hope",
    "inbox",
    "irc",
    "juubs",
    "kanban",
    "knot",
    "lesbin",
    "mail",
    "molly",
    "mollyterm",
    "music",
    "netdata",
    "niri",
    "nixbld",
    "nobody",
    "oauth2_proxy",
    "operator",
    "pds",
    "pet",
    "plan",
    "porrima",
    "qwen",
    "ratlogin",
    "registry",
    "requests",
    "resume",
    "root",
    "route",
    "s3",
    "searx",
    "search",
    "shutdown",
    "spindle",
    "scryphil",
    "sync",
    "systemd",
    "tasks",
    "tilde",
    "tilde_requests",
    "upload",
    "vikunja",
    "voicebox",
}


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def connect(path):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=DELETE")
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript(
        """
        CREATE TABLE IF NOT EXISTS requests (
          id INTEGER PRIMARY KEY,
          subject TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL DEFAULT '',
          username TEXT NOT NULL,
          ssh_key TEXT NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('pending', 'provisioning', 'approved', 'rejected')),
          note TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          reviewed_at TEXT
        );
        CREATE UNIQUE INDEX IF NOT EXISTS active_request_username
          ON requests(username)
          WHERE status IN ('pending', 'provisioning', 'approved');
        """
    )
    return db


def validate_username(username):
    if not USERNAME.fullmatch(username):
        raise ValueError(
            "Use 1-31 lowercase letters, digits, or underscores; start with a letter."
        )
    if username in RESERVED:
        raise ValueError("That username is reserved.")
    try:
        pwd.getpwnam(username)
    except KeyError:
        return username
    raise ValueError("That username already exists.")


def validate_ssh_key(value):
    value = value.strip()
    if "\n" in value or len(value) > 4096:
        raise ValueError("Provide one OpenSSH public key.")
    fields = value.split()
    if len(fields) not in (2, 3) or fields[0] != "ssh-ed25519":
        raise ValueError("Only ssh-ed25519 public keys are accepted.")
    try:
        blob = base64.b64decode(fields[1], validate=True)
        key_type_len = struct.unpack(">I", blob[:4])[0]
        key_type = blob[4 : 4 + key_type_len]
        offset = 4 + key_type_len
        key_len = struct.unpack(">I", blob[offset : offset + 4])[0]
        key = blob[offset + 4 :]
    except (ValueError, struct.error, IndexError):
        raise ValueError("The SSH key is malformed.") from None
    if key_type != b"ssh-ed25519" or key_len != 32 or len(key) != 32:
        raise ValueError("The SSH key is malformed.")
    return value


def authenticated_subject(headers, expected):
    subject = headers.get("X-Forwarded-User", "").strip()
    authorization = headers.get("Authorization", "")
    if not subject or not expected or not authorization.startswith("Basic "):
        return ""
    try:
        user, password = (
            base64.b64decode(authorization[6:], validate=True).decode().rsplit(":", 1)
        )
    except (ValueError, UnicodeDecodeError):
        return ""
    if user != subject or not hmac.compare_digest(password, expected):
        return ""
    return subject


def submit(db, subject, email, username, ssh_key):
    username = validate_username(username)
    ssh_key = validate_ssh_key(ssh_key)
    if not subject or len(subject) > 512:
        raise ValueError("Missing authenticated identity.")

    with db:
        existing = db.execute(
            "SELECT status FROM requests WHERE subject = ?", (subject,)
        ).fetchone()
        if existing and existing["status"] != "rejected":
            raise ValueError("You already have an active account request.")
        try:
            if existing:
                db.execute(
                    """UPDATE requests
                       SET email = ?, username = ?, ssh_key = ?, status = 'pending',
                           note = '', created_at = ?, reviewed_at = NULL
                       WHERE subject = ?""",
                    (email, username, ssh_key, now(), subject),
                )
            else:
                db.execute(
                    """INSERT INTO requests(subject, email, username, ssh_key, status, created_at)
                       VALUES (?, ?, ?, ?, 'pending', ?)""",
                    (subject, email, username, ssh_key, now()),
                )
        except sqlite3.IntegrityError:
            raise ValueError("That username already has an active request.") from None


def page(subject, request=None, message="", error=False):
    status = ""
    if request:
        status = f"<p><strong>Status:</strong> {html.escape(request['status'])}</p>"
    notice = (
        f'<p class="{"error" if error else "notice"}">{html.escape(message)}</p>'
        if message
        else ""
    )
    return f"""<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Request a daze.lol shell account</title>
<style>body{{max-width:42rem;margin:3rem auto;padding:0 1rem;font:18px/1.5 system-ui;background:#101116;color:#ececf1}}input,textarea,button{{box-sizing:border-box;width:100%;padding:.7rem;margin:.25rem 0 1rem;font:inherit}}textarea{{min-height:8rem}}button{{cursor:pointer}}a{{color:#b7a7ff}}.error{{color:#ff9c9c}}.notice{{color:#9ee6b8}}code{{background:#252631;padding:.15rem .35rem}}</style>
<main><h1>Request a shell account</h1>
<p>Authenticated as <code>{html.escape(subject)}</code>. Requests are reviewed manually.</p>
{status}{notice}
<form method="post" action="/request">
<label>Desired username <input name="username" required pattern="[a-z][a-z0-9_]{{0,30}}" maxlength="31" autocomplete="username"></label>
<label>SSH Ed25519 public key <textarea name="ssh_key" required maxlength="4096" placeholder="ssh-ed25519 AAAA... comment"></textarea></label>
<button type="submit">Submit request</button>
</form>
<p><a href="https://tilde.daze.lol/">Back to tilde.daze.lol</a></p></main></html>"""


class Server(http.server.ThreadingHTTPServer):
    db_path: str


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "tilde-requests/1"

    def identity(self):
        return authenticated_subject(
            self.headers, os.environ.get("TILDE_REQUEST_PROXY_SECRET", "")
        )

    def respond(self, status, body, content_type="text/html; charset=utf-8"):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'",
        )
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/healthz":
            self.respond(200, "ok\n", "text/plain; charset=utf-8")
            return
        if self.path != "/":
            self.respond(404, "not found\n", "text/plain; charset=utf-8")
            return
        subject = self.identity()
        if not subject:
            self.respond(
                403, "missing authenticated identity\n", "text/plain; charset=utf-8"
            )
            return
        server = self.server
        assert isinstance(server, Server)
        with connect(server.db_path) as db:
            request = db.execute(
                "SELECT * FROM requests WHERE subject = ?", (subject,)
            ).fetchone()
        self.respond(200, page(subject, request))

    def do_POST(self):
        if self.path != "/request":
            self.respond(404, "not found\n", "text/plain; charset=utf-8")
            return
        subject = self.identity()
        if not subject:
            self.respond(
                403, "missing authenticated identity\n", "text/plain; charset=utf-8"
            )
            return
        if self.headers.get("Origin") != "https://requests.daze.lol":
            self.respond(403, "invalid origin\n", "text/plain; charset=utf-8")
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if not 0 < length <= 8192:
            self.respond(413, "request too large\n", "text/plain; charset=utf-8")
            return
        try:
            if self.headers.get_content_type() != "application/x-www-form-urlencoded":
                raise ValueError("invalid form content type")
            form = urllib.parse.parse_qs(
                self.rfile.read(length).decode(), strict_parsing=True
            )
            username = form.get("username", [""])[0].strip()
            ssh_key = form.get("ssh_key", [""])[0].strip()
            email = self.headers.get("X-Forwarded-Email", "").strip()[:512]
            server = self.server
            assert isinstance(server, Server)
            with connect(server.db_path) as db:
                submit(db, subject, email, username, ssh_key)
                request = db.execute(
                    "SELECT * FROM requests WHERE subject = ?", (subject,)
                ).fetchone()
            self.respond(201, page(subject, request, "Request submitted."))
        except (ValueError, UnicodeDecodeError) as exc:
            self.respond(400, page(subject, None, str(exc), True))

    def log_message(self, format, *args):
        print(f"{self.address_string()} {format % args}", flush=True)


def serve(args):
    connect(args.db).close()
    server = Server((args.host, args.port), Handler)
    server.db_path = args.db
    server.serve_forever()


def list_requests(args):
    with connect(args.db) as db:
        rows = db.execute(
            "SELECT id, status, username, subject, created_at, note FROM requests ORDER BY id"
        ).fetchall()
    print("ID\tSTATUS\tUSERNAME\tSUBJECT\tCREATED\tNOTE")
    for row in rows:
        print("\t".join(str(row[key]) for key in row.keys()))


def run_best_effort(argv, env=None):
    try:
        subprocess.run(argv, check=True, env=env)
        return ""
    except (OSError, subprocess.CalledProcessError) as exc:
        return str(exc)


def provision(args, row):
    username = row["username"]
    notes = []
    if args.email_command:
        email = row["email"]
        if email and args.email_env_file:
            notes.append(
                run_best_effort(
                    [
                        args.email_command,
                        "email",
                        "--user",
                        username,
                        "--email",
                        email,
                        "--env-file",
                        args.email_env_file,
                    ]
                )
                or "email forwarding created"
            )
        elif not email:
            notes.append("email: no address provided, skipped forwarding")
    return notes


def approve(args):
    if os.geteuid() != 0:
        raise SystemExit("approval must run as root")
    db = connect(args.db)
    with db:
        row = db.execute(
            "SELECT * FROM requests WHERE id = ? AND status = 'pending'", (args.id,)
        ).fetchone()
        if not row:
            raise SystemExit("pending request not found")
        db.execute(
            "UPDATE requests SET status = 'provisioning', note = '' WHERE id = ?",
            (args.id,),
        )
    key_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", prefix="tilde-key-", delete=False
        ) as key_file:
            key_file.write(row["ssh_key"] + "\n")
            key_path = key_file.name
        os.chmod(key_path, 0o600)
        subprocess.run([args.add_user_command, row["username"], key_path], check=True)
        notes = provision(args, row)
    except Exception as exc:
        with db:
            db.execute(
                "UPDATE requests SET status = 'pending', note = ? WHERE id = ?",
                (str(exc), args.id),
            )
        raise
    finally:
        if key_path is not None:
            os.unlink(key_path)
    note = " | ".join(n for n in notes if n)
    with db:
        db.execute(
            "UPDATE requests SET status = 'approved', reviewed_at = ?, note = ? WHERE id = ?",
            (now(), note[:512], args.id),
        )
    print(f"approved {row['username']}" + (f" ({note})" if note else ""))


def reject(args):
    if os.geteuid() != 0:
        raise SystemExit("rejection must run as root")
    with connect(args.db) as db:
        changed = db.execute(
            "UPDATE requests SET status = 'rejected', reviewed_at = ?, note = ? WHERE id = ? AND status = 'pending'",
            (now(), args.note, args.id),
        ).rowcount
    if changed != 1:
        raise SystemExit("pending request not found")


def self_test(_args):
    assert validate_username("alice_2") == "alice_2"
    for bad in ("Alice", "2alice", "root", "a-b"):
        try:
            validate_username(bad)
        except ValueError:
            pass
        else:
            raise AssertionError(f"accepted username {bad}")
    blob = (
        struct.pack(">I", 11)
        + b"ssh-ed25519"
        + struct.pack(">I", 32)
        + bytes(range(32))
    )
    key = "ssh-ed25519 " + base64.b64encode(blob).decode() + " test"
    assert validate_ssh_key(key) == key
    authorization = "Basic " + base64.b64encode(b"did:plc:test:proxy-secret").decode()
    headers = {
        "X-Forwarded-User": "did:plc:test",
        "Authorization": authorization,
    }
    assert authenticated_subject(headers, "proxy-secret") == "did:plc:test"
    assert authenticated_subject(headers, "wrong") == ""
    with tempfile.TemporaryDirectory() as directory:
        db = connect(os.path.join(directory, "requests.db"))
        submit(db, "did:plc:test", "", "alice_2", key)
        assert db.execute("SELECT status FROM requests").fetchone()[0] == "pending"
    print("account portal self-test passed")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default="/var/lib/tilde-requests/requests.db")
    sub = parser.add_subparsers(required=True)
    serve_parser = sub.add_parser("serve")
    serve_parser.add_argument("--host", default="127.0.0.1")
    serve_parser.add_argument("--port", type=int, default=8090)
    serve_parser.set_defaults(func=serve)
    list_parser = sub.add_parser("list")
    list_parser.set_defaults(func=list_requests)
    approve_parser = sub.add_parser("approve")
    approve_parser.add_argument("id", type=int)
    approve_parser.add_argument(
        "--add-user-command", default="/run/current-system/sw/bin/tilde-add-user"
    )
    approve_parser.add_argument("--email-command")
    approve_parser.add_argument("--email-env-file")
    approve_parser.set_defaults(func=approve)
    reject_parser = sub.add_parser("reject")
    reject_parser.add_argument("id", type=int)
    reject_parser.add_argument("--note", default="Declined by administrator")
    reject_parser.set_defaults(func=reject)
    test_parser = sub.add_parser("self-test")
    test_parser.set_defaults(func=self_test)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
