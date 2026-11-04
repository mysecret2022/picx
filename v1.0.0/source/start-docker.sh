#!/usr/bin/env bash
set -e
echo "=============================================="
echo "Starting PicX in Docker..."
echo "=============================================="
docker compose up -d --build
echo "=============================================="
echo "PicX started successfully!"
echo "Access PicX at: http://localhost:8088"
echo "=============================================="
