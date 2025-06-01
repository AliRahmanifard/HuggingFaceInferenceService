# -------------------------------------------------------------------
# Dockerfile (single-stage, based on Debian-slim)
# -------------------------------------------------------------------
FROM python:3.9-slim

# 1. Install system packages: nginx and any build-essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nginx \
      build-essential \
      curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Copy our FastAPI server code
COPY server.py .

# 4. Copy nginx configuration (adjust if your file is elsewhere)
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# 5. Expose ports:
#    - Nginx listens on 80
#    - (Gunicorn/Uvicorn could optionally listen on 8000, but nginx proxies to it)
EXPOSE 80

# 6. Add a small shell script to launch both Gunicorn and nginx
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 7. Default command: run our start.sh
CMD ["/app/start.sh"]
