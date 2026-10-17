#!/usr/bin/env python3
"""Exercise Moodle's login page in a real browser engine."""
import os
import hashlib
from pathlib import Path
import sys
import shutil
import subprocess

from playwright.sync_api import sync_playwright


def assert_login_form(page):
    assert page.get_by_role("heading", name="Welcome to Moodle", exact=True).is_visible()
    assert page.get_by_role("main").get_by_role(
        "heading", name="Welcome back", exact=True
    ).is_visible()
    assert page.locator('input[name="username"]').is_visible()
    assert page.locator('input[name="password"]').is_visible()


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: browser_journey.py chromium|firefox|webkit")
    engine = sys.argv[1]
    url = os.environ["MOODLE_VERIFY_URL"]
    with sync_playwright() as playwright:
        profile = None
        if engine == "firefox":
            root_ca = Path(os.environ["MOODLE_VERIFY_ROOT_CA"])
            if not root_ca.is_file() or root_ca.stat().st_size == 0:
                raise RuntimeError("owned Caddy public root certificate is missing")
            certutil = shutil.which("certutil")
            if not certutil:
                raise RuntimeError("NSS certutil is required for isolated Firefox trust")
            profile = Path(os.environ["MOODLE_VERIFY_FIREFOX_PROFILE"])
            profile.mkdir(parents=True, exist_ok=False)
            try:
                subprocess.run([certutil, "-N", "-d", f"sql:{profile}", "--empty-password"], check=True, capture_output=True)
                subprocess.run([certutil, "-A", "-d", f"sql:{profile}", "-n", "verify-moodle-run", "-t", "C,,", "-i", str(root_ca)], check=True, capture_output=True)
                browser = playwright.firefox.launch_persistent_context(str(profile), ignore_https_errors=False)
            except Exception:
                shutil.rmtree(profile)
                raise
        else:
            browser = getattr(playwright, engine).launch()
        try:
            page = browser.new_page() if engine == "firefox" else browser.new_page(ignore_https_errors=True)
            response = page.goto(url + "/login/index.php", wait_until="networkidle", timeout=120000)
            assert response and response.ok, "login route did not return a successful response"
            assert_login_form(page)
            theme = page.locator('link[href*="/theme/styles.php/lovely/"]').first
            assert theme.count() == 1, "Lovely theme stylesheet link is missing from the DOM"
            stylesheet_url = theme.evaluate("element => element.href")
            stylesheet = page.evaluate("""async url => {
                const response = await fetch(url);
                return {ok: response.ok, status: response.status, bytes: (await response.text()).length};
            }""", stylesheet_url)
            assert stylesheet["ok"] and stylesheet["bytes"] > 0, "Lovely theme stylesheet did not load in the browser"
            if engine == "firefox":
                print("PASS: Firefox verified HTTPS with only the owned Caddy root in a temporary NSS profile; ignore_https_errors=False; root_sha256=" + hashlib.sha256(root_ca.read_bytes()).hexdigest())
            print("PASS: login heading, username/password inputs, and Lovely stylesheet loaded")
        except Exception:
            evidence = os.environ.get("MOODLE_VERIFY_EVIDENCE")
            if evidence and "page" in locals():
                directory = Path(evidence)
                try:
                    directory.mkdir(parents=True, exist_ok=True)
                    (directory / f"{engine}-failure.html").write_text(page.content(), encoding="utf-8")
                    page.screenshot(path=str(directory / f"{engine}-failure.png"), full_page=True)
                except Exception as capture_error:
                    print(f"Failed to capture browser evidence: {capture_error}", file=sys.stderr)
            raise
        finally:
            try:
                browser.close()
            finally:
                if profile is not None:
                    shutil.rmtree(profile)


if __name__ == "__main__":
    main()
