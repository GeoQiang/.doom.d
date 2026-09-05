#!/usr/bin/env python3
"""每天检测 elfeed.org 里订阅的 RSS 源是否失效。

检测三件事：HTTP 状态是不是 2xx、返回的是不是合法的 RSS/Atom、里面有没有
文章条目。失效时用 macOS 桌面通知提醒；每次运行的结果覆盖写一份日志
（rss-check.log），方便出问题时排查，不会无限增长。
"""
import re
import subprocess
import sys
from pathlib import Path

ELFEED_ORG = Path.home() / "Dropbox/org-literate/elfeed.org"
LOG_FILE = Path(__file__).parent / "rss-check.log"
TIMEOUT = 15

LINK_RE = re.compile(r"^\*+\s+\[\[([^\]]+)\]\[([^\]]+)\]\]", re.M)


def extract_feeds(org_path: Path):
    text = org_path.read_text(encoding="utf-8")
    return [
        (title, url)
        for url, title in LINK_RE.findall(text)
        if url.startswith("http")
    ]


def check_feed(url: str):
    try:
        result = subprocess.run(
            ["curl", "-sL", "-A", "Mozilla/5.0", "--max-time", str(TIMEOUT),
             "-w", "\n__HTTP_CODE__:%{http_code}", url],
            capture_output=True, text=True, timeout=TIMEOUT + 5,
        )
    except subprocess.TimeoutExpired:
        return "curl 超时"
    except Exception as e:
        return f"curl 执行失败: {e}"

    stdout = result.stdout
    m = re.search(r"__HTTP_CODE__:(\d+)$", stdout)
    if not m:
        return "没拿到 HTTP 状态码"
    http_code = int(m.group(1))
    body = stdout[: m.start()]

    if not (200 <= http_code < 300):
        return f"HTTP {http_code}"
    if not re.search(r"<rss|<feed", body):
        return "不是合法的 RSS/Atom 内容"
    if not re.search(r"<item|<entry", body):
        return "没有任何文章条目"
    return None


def notify(title: str, message: str):
    # osascript display notification 不支持真正的换行，用；替代
    flat = message.replace("\n", "；")
    subprocess.run([
        "osascript", "-e",
        f'display notification "{flat}" with title "{title}" sound name "Basso"',
    ])


def main():
    if not ELFEED_ORG.exists():
        notify("RSS 检测脚本出错", f"找不到 {ELFEED_ORG}")
        sys.exit(1)

    feeds = extract_feeds(ELFEED_ORG)
    log_lines = []
    failed = []

    for title, url in feeds:
        reason = check_feed(url)
        if reason:
            failed.append((title, reason))
            log_lines.append(f"[FAIL] {title} -> {reason} ({url})")
        else:
            log_lines.append(f"[OK]   {title}")

    log_lines.append(f"共检测 {len(feeds)} 个源，失效 {len(failed)} 个")
    LOG_FILE.write_text("\n".join(log_lines) + "\n", encoding="utf-8")

    if failed:
        summary = "\n".join(f"{t}: {r}" for t, r in failed[:5])
        if len(failed) > 5:
            summary += f"\n...等共 {len(failed)} 个"
        notify("RSS 订阅源检测：发现失效", summary)


if __name__ == "__main__":
    main()
