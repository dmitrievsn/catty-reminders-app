#!/usr/bin/env python3
import json
import os
import subprocess
import threading
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8080

def branch_from_ref(ref: str) -> str:
    prefix = "refs/heads/"
    return ref[len(prefix):] if isinstance(ref, str) and ref.startswith(prefix) else ""

class WebhookHandler(BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()

        deploy_base = os.environ.get("DEPLOY_BASE", "")
        last_deploy = ""
        if deploy_base:
            p = os.path.join(deploy_base, "last_deploy.txt")
            if os.path.exists(p):
                try:
                    with open(p, "r", encoding="utf-8") as f:
                        last_deploy = f.read().strip()
                except Exception:
                    last_deploy = "(read error)"

        html = f"""
<h1>Webhook server</h1>
<p>Status: ok</p>
<p>Time: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
<p>Port: {PORT}</p>
<p>Last deploy: {last_deploy or "(none)"}</p>
"""
        self.wfile.write(html.encode("utf-8"))

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else b""

        event_type = self.headers.get("X-GitHub-Event", "unknown")
        delivery = self.headers.get("X-GitHub-Delivery", "-")

        try:
            payload = json.loads(body.decode("utf-8")) if body else {}
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return

        self._process(event_type, delivery, payload)

        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status":"success"}')

    def _process(self, event_type, delivery, payload):
        repo = (payload.get("repository") or {}).get("full_name", "unknown")
        print(f"{datetime.now().isoformat()} event={event_type} repo={repo} delivery={delivery}")

        if event_type == "ping":
            return

        if event_type == "push":
            self._handle_push(payload)
            return

        if event_type == "pull_request":
            action = payload.get("action", "")
            number = payload.get("number", "")
            print(f"{datetime.now().isoformat()} pull_request action={action} number={number}")
            return

        if event_type == "release":
            action = payload.get("action", "")
            tag = (payload.get("release") or {}).get("tag_name", "")
            print(f"{datetime.now().isoformat()} release action={action} tag={tag}")
            return

    def _handle_push(self, payload):
        ref = payload.get("ref", "")
        branch = branch_from_ref(ref)
        if not branch:
            print(f"{datetime.now().isoformat()} push ignored ref={ref}")
            return

        sha = payload.get("after", "")
        repo_full = (payload.get("repository") or {}).get("full_name", "")
        clone_url = (payload.get("repository") or {}).get("clone_url", "")

        base_dir = os.path.dirname(os.path.abspath(__file__))
        deploy_script = os.path.join(base_dir, "deploy.sh")

        def run_deploy():
            env = os.environ.copy()
            if not env.get("REPO_URL") and clone_url:
                env["REPO_URL"] = clone_url
            try:
                subprocess.run([deploy_script, branch, sha, repo_full], check=True, env=env)
            except subprocess.CalledProcessError as e:
                print(f"{datetime.now().isoformat()} deploy failed rc={e.returncode}")

        threading.Thread(target=run_deploy, daemon=True).start()
        print(f"{datetime.now().isoformat()} deploy scheduled branch={branch} sha={sha}")

def main():
    server = HTTPServer(("0.0.0.0", PORT), WebhookHandler)
    print(f"{datetime.now().isoformat()} start port={PORT}")
    server.serve_forever()

if __name__ == "__main__":
    main()
