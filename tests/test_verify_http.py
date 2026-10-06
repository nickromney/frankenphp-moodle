"""Synthetic localhost verifier acceptance. No Moodle, container or database."""
import http.server
import subprocess
import threading
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        status = 503 if self.path == '/failure' else 200
        self.send_response(status)
        self.end_headers()
        self.wfile.write(b'Synthetic Moodle login' if self.path != '/wrong' else b'Wrong page')

    def log_message(self, *args):
        pass


class HTTPAcceptance(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def verify(self, path='/', query='printf 489', ping='true'):
        return subprocess.run([
            'bash', str(ROOT / 'verify-moodle.sh'), '--backend', 'none',
            '--php-runtime', 'none', '--database', 'mariadb', '--skip-config-check',
            '--skip-web-check', '--skip-php-check', '--url',
            f'http://127.0.0.1:{self.server.server_port}{path}',
            '--content-match', 'Synthetic Moodle login', '--db-ping-command', ping,
            '--db-query-command', query,
        ], capture_output=True, text=True, timeout=10)

    def test_success(self):
        result = self.verify()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('HTTP probe returned 200', result.stdout)
        self.assertIn('Moodle database contains 489 tables', result.stdout)

    def test_http_and_content_failure(self):
        for path, message in [('/failure', 'Unexpected HTTP status'), ('/wrong', 'did not contain expected text')]:
            with self.subTest(path=path):
                result = self.verify(path)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)

    def test_database_failure_and_invalid_counts(self):
        for query in ['printf 399', 'printf invalid', 'printf 489; exit 1']:
            with self.subTest(query=query):
                result = self.verify(query=query)
                self.assertNotEqual(result.returncode, 0, result.stdout)
        result = self.verify(ping='false')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Database connectivity check failed', result.stderr)


if __name__ == '__main__':
    unittest.main()
