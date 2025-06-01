#!/bin/sh

# 1. Launch Gunicorn in the background, listening on 127.0.0.1:8000
gunicorn --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 127.0.0.1:8000 server:app &

# 2. Launch nginx in the foreground
nginx -g "daemon off;"
