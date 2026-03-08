FROM python:3.9-slim 

WORKDIR /app


RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && \
rm -rf /var/lib/apt/lists/* 

COPY requirement.txt .

RUN pip install --no-cache-dir -r requirement.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]