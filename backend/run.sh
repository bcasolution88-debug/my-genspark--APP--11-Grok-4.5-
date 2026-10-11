#!/usr/bin/env bash
# 启动后端：bash run.sh [port]
cd "$(dirname "$0")"
PORT=${1:-8000}
pip install -q -r requirements.txt
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
