# Stage 1 - Build
FROM python:3.9-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY requirement.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirement.txt

# Stage 2 - Runtime
FROM python:3.9-slim
WORKDIR /app
RUN apt-get update && apt-get install -y default-libmysqlclient-dev && rm -rf /var/lib/apt/lists/*
COPY --from=builder /install /usr/local
COPY . .
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
