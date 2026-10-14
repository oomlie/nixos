import argparse
import calendar
import grp
import html
import os
import pwd
import tempfile
import time
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

import feedparser


FEED_FILES = ("feed.xml", "atom.xml", "rss.xml")


def members():
    return sorted(set(grp.getgrnam("tilde").gr_mem))


def read_line(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as file:
            return file.readline(512).strip()
    except OSError:
        return ""


def atomic_write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as file:
            file.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    os.chmod(path, 0o644)


def member_page(users, home_root="/home"):
    rows = []
    for user in users:
        home = os.path.join(home_root, user)
        plan = html.escape(read_line(os.path.join(home, ".plan")))
        project = html.escape(read_line(os.path.join(home, ".project")))
        rows.append(
            f'<li><a href="https://{user}.daze.lol/">~{html.escape(user)}</a>'
            f"<br>{plan or 'No .plan yet.'}<br><small>{project}</small></li>"
        )
    return (
        """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width"><title>daze.lol members</title>
<style>body{max-width:48rem;margin:3rem auto;padding:0 1rem;font:18px/1.55 system-ui;background:#101116;color:#ececf1}a{color:#b7a7ff}li{margin:1.4rem 0}small{color:#b9bac5}</style>
<main><h1>daze.lol members</h1><p>Shell users publishing from their home directories.</p>
<ul>"""
        + "".join(rows)
        + "</ul><p><a href='/'>Back home</a></p></main></html>\n"
    )


def entry_time(entry):
    parsed = entry.get("published_parsed") or entry.get("updated_parsed")
    return calendar.timegm(parsed) if parsed else 0


def planet_entries(users, home_root="/home"):
    entries = []
    for user in users:
        public = os.path.join(home_root, user, "public_html")
        feed_path = next(
            (
                os.path.join(public, name)
                for name in FEED_FILES
                if os.path.isfile(os.path.join(public, name))
            ),
            None,
        )
        if not feed_path:
            continue
        feed = feedparser.parse(feed_path)
        base = f"https://{user}.daze.lol/"
        for entry in feed.entries[:50]:
            link = urllib.parse.urljoin(base, entry.get("link", ""))
            if not link.startswith(("https://", "http://")):
                continue
            title = entry.get("title", "Untitled")
            entries.append(
                {
                    "user": user,
                    "title": title,
                    "link": link,
                    "timestamp": entry_time(entry),
                }
            )
    return sorted(entries, key=lambda item: item["timestamp"], reverse=True)[:100]


def atom_timestamp(timestamp):
    value = timestamp or int(time.time())
    return (
        datetime.fromtimestamp(value, timezone.utc).isoformat().replace("+00:00", "Z")
    )


def planet_outputs(entries):
    items = []
    root = ET.Element("{http://www.w3.org/2005/Atom}feed")
    ET.SubElement(root, "{http://www.w3.org/2005/Atom}title").text = "daze.lol planet"
    ET.SubElement(
        root, "{http://www.w3.org/2005/Atom}id"
    ).text = "https://planet.daze.lol/"
    ET.SubElement(root, "{http://www.w3.org/2005/Atom}updated").text = atom_timestamp(
        entries[0]["timestamp"] if entries else 0
    )
    ET.SubElement(
        root,
        "{http://www.w3.org/2005/Atom}link",
        {"href": "https://planet.daze.lol/atom.xml", "rel": "self"},
    )
    for item in entries:
        title = html.escape(item["title"])
        user = html.escape(item["user"])
        link = html.escape(item["link"], quote=True)
        items.append(f'<li><a href="{link}">{title}</a> <small>by ~{user}</small></li>')
        entry = ET.SubElement(root, "{http://www.w3.org/2005/Atom}entry")
        ET.SubElement(entry, "{http://www.w3.org/2005/Atom}title").text = item["title"]
        ET.SubElement(entry, "{http://www.w3.org/2005/Atom}id").text = item["link"]
        ET.SubElement(
            entry, "{http://www.w3.org/2005/Atom}updated"
        ).text = atom_timestamp(item["timestamp"])
        ET.SubElement(
            entry, "{http://www.w3.org/2005/Atom}link", {"href": item["link"]}
        )
        ET.SubElement(entry, "{http://www.w3.org/2005/Atom}author").append(
            ET.Element("{http://www.w3.org/2005/Atom}name")
        )
        entry[-1][0].text = f"~{item['user']}"
    page = (
        """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width"><title>daze.lol planet</title>
<link rel="alternate" type="application/atom+xml" href="/atom.xml">
<style>body{max-width:48rem;margin:3rem auto;padding:0 1rem;font:18px/1.55 system-ui;background:#101116;color:#ececf1}a{color:#b7a7ff}li{margin:1rem 0}small{color:#b9bac5}</style>
<main><h1>daze.lol planet</h1><p>Recent posts from member feeds named <code>feed.xml</code>, <code>atom.xml</code>, or <code>rss.xml</code>.</p><ul>"""
        + "".join(items)
        + "</ul></main></html>\n"
    )
    atom = ET.tostring(root, encoding="unicode", xml_declaration=True) + "\n"
    return page, atom


def build(args):
    users = members()
    if args.command == "members":
        atomic_write(args.output, member_page(users))
    else:
        page, atom = planet_outputs(planet_entries(users))
        atomic_write(os.path.join(args.output, "index.html"), page)
        atomic_write(os.path.join(args.output, "atom.xml"), atom)


def self_test(_args):
    with tempfile.TemporaryDirectory() as directory:
        home = os.path.join(directory, "alice")
        os.makedirs(os.path.join(home, "public_html"))
        atomic_write(os.path.join(home, ".plan"), "Building small things.\n")
        atomic_write(
            os.path.join(home, "public_html", "feed.xml"),
            """<feed xmlns="http://www.w3.org/2005/Atom"><title>Alice</title>
<entry><title>Hello &amp; goodbye</title><id>hello</id><link href="/hello"/>
<updated>2026-09-22T00:00:00Z</updated></entry></feed>""",
        )
        assert "Building small things" in member_page(["alice"], directory)
        entries = planet_entries(["alice"], directory)
        assert entries[0]["link"] == "https://alice.daze.lol/hello"
        page, atom = planet_outputs(entries)
        assert "Hello &amp; goodbye" in page
        assert "https://alice.daze.lol/hello" in atom
    print("tilde site tools self-test passed")


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    members_parser = subparsers.add_parser("members")
    members_parser.add_argument("--output", required=True)
    members_parser.set_defaults(func=build)
    planet_parser = subparsers.add_parser("planet")
    planet_parser.add_argument("--output", required=True)
    planet_parser.set_defaults(func=build)
    test_parser = subparsers.add_parser("self-test")
    test_parser.set_defaults(func=self_test)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
