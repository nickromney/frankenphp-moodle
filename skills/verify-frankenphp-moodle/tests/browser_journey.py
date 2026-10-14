#!/usr/bin/env python3
"""Exercise Moodle's login page in a real browser engine."""
import os
import sys

from playwright.sync_api import sync_playwright


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: browser_journey.py chromium|firefox|webkit")
    engine = sys.argv[1]
    url = os.environ["MOODLE_VERIFY_URL"]
    with sync_playwright() as playwright:
        browser = getattr(playwright, engine).launch()
        try:
            page = browser.new_page(ignore_https_errors=True)
            response = page.goto(url + "/login/index.php", wait_until="networkidle", timeout=120000)
            assert response and response.ok, "login route did not return a successful response"
            assert page.get_by_role("heading", name="Log in to Moodle").is_visible()
            assert page.locator('input[name="username"]').is_visible()
            assert page.locator('input[name="password"]').is_visible()
            theme = page.locator('link[href*="/theme/styles.php/lovely/"]').first
            assert theme.count() == 1, "Lovely theme stylesheet link is missing from the DOM"
            stylesheet_url = theme.evaluate("element => element.href")
            stylesheet = page.request.get(stylesheet_url)
            assert stylesheet.ok, "Lovely theme stylesheet did not load in the browser"
            print("PASS: login heading, username/password inputs, and Lovely stylesheet loaded")
        finally:
            browser.close()


if __name__ == "__main__":
    main()
