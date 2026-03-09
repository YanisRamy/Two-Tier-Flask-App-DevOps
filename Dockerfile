FROM python:3.9-slim

WORKDIR /app

# Installer les dépendances système pour MySQL
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Copier le fichier requirements
COPY requirement.txt .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirement.txt

# Copier tout le code de l'application
COPY . .

# Exposer le port Flask
EXPOSE 5000

# Lancer l'application
CMD ["python", "app.py"]