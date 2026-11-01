# Simple Flask Docker project
# This project contains a minimal Flask application that runs a web server.
# Directory structure:
#   docker-demo-flask/
#       Dockerfile
#       requirements.txt
#       main.py
#       app.py
#   tests/
#       test_app.py

# Dockerfile (multi‑stage build, health check):
# Stage 1 – Build a lightweight image
FROM python:3.12-slim AS builder
WORKDIR /app
# Install any build‑time dependencies
RUN pip install --disable-pip-version-check --no-cache-dir pip==24.0 setuptools==75.1.

# Stage 2 – Runtime image
FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1
WORKDIR /app
# Copy requirements from the builder
COPY --from=builder /app/requirements.txt ./
# Install runtime dependencies
RUN pip install --disable-pip-version-check --no-cache-dir -r requirements.txt
# Copy over the source code
COPY --from=builder /app/app.py ./
COPY --from=builder /app/main.py ./
# Health‑check endpoint for Docker
HEALTHCHECK --interval=10s --timeout=5s CMD curl -f http://localhost:5000/health || exit 1
# Default command
CMD ["python", "main.py"]

# requirements.txt – specify Flask and its test client
Flask==3.0.3

# app.py – a simple Flask app exposing a health endpoint
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/health", methods=["GET"])
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

# main.py – starts the Flask server (invoked by Docker)
from app import app

if __name__ == "__main__":
    app.run()

# tests/test_app.py – simple unit test for the health endpoint
import unittest
import json

from app import app

class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data.get("status"), "ok")

if __name__ == "__main__":
    unittest.main()
