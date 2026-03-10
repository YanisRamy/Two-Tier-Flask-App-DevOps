# Two-Tier Flask App — Automated CI/CD Pipeline on AWS

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/YanisRamy/Two-Tier-Flask-App-DevOps/ci-cd.yml?branch=main)
![GitHub Repo stars](https://img.shields.io/github/stars/YanisRamy/Two-Tier-Flask-App-DevOps)
![License](https://img.shields.io/github/license/YanisRamy/Two-Tier-Flask-App-DevOps)

**Author:** Oulad Daoud Yanis Ramy  
**Date:** March 10, 2026

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Step 1: AWS EC2 Instance Preparation](#step-1-aws-ec2-instance-preparation)
4. [Step 2: Install Dependencies on EC2](#step-2-install-dependencies-on-ec2)
5. [Step 3: Jenkins Installation and Setup](#step-3-jenkins-installation-and-setup)
6. [Step 4: GitHub Repository Configuration](#step-4-github-repository-configuration)
   - [Dockerfile](#dockerfile)
   - [docker-compose.yml](#docker-composeyml)
   - [Jenkinsfile](#jenkinsfile)
7. [Step 5: Jenkins Pipeline Creation and Execution](#step-5-jenkins-pipeline-creation-and-execution)
8. [Conclusion](#conclusion)
9. [Infrastructure Diagram](#infrastructure-diagram)
10. [Workflow Diagram](#workflow-diagram)
11. [External Links](#external-links)

---

## Project Overview

This project demonstrates deploying a **2-tier Flask + MySQL application** on AWS EC2 using Docker, Docker Compose, and Jenkins CI/CD automation.  
Every push to GitHub triggers a pipeline that automatically builds and deploys the application.

---

## Architecture Diagram
```text
+-----------------+      +----------------------+      +-----------------------------+
|   Developer     |----->|     GitHub Repo      |----->|        Jenkins Server       |
| (pushes code)   |      | (Source Code Mgmt)   |      |  (on AWS EC2)               |
+-----------------+      +----------------------+      |                             |
                                                       | 1. Clones Repo              |
                                                       | 2. Builds Docker Image      |
                                                       | 3. Runs Docker Compose      |
                                                       +--------------+--------------+
                                                                      |
                                                                      | Deploys
                                                                      v
                                                       +-----------------------------+
                                                       |      Application Server     |
                                                       |      (Same AWS EC2)         |
                                                       |                             |
                                                       | +-------------------------+ |
                                                       | | Docker Container: Flask | |
                                                       | +-------------------------+ |
                                                       |              |              |
                                                       |              v              |
                                                       | +-------------------------+ |
                                                       | | Docker Container: MySQL | |
                                                       | +-------------------------+ |
                                                       +-----------------------------+
```

---

## Step 1: AWS EC2 Instance Preparation

![EC2 Setup](screen%20and%20diagrams/EC2%20instance%20configuration.png)
![Security Group](screen%20and%20diagrams/connecting%20instance%20using%20SSH.png)

### 1. Launch EC2 Instance
- Navigate to the **AWS EC2 console**
- Launch a new instance using the **Ubuntu 22.04 LTS** AMI
- Select the **t2.micro** instance type for free-tier eligibility
- Create and assign a new **key pair** for SSH access

### 2. Configure Security Group
Create a security group with the following inbound rules:

| Type       | Protocol | Port | Source                |
|------------|----------|------|-----------------------|
| SSH        | TCP      | 22   | Your IP               |
| HTTP       | TCP      | 80   | Anywhere (0.0.0.0/0)  |
| Custom TCP | TCP      | 5000 | Anywhere (0.0.0.0/0)  |
| Custom TCP | TCP      | 8080 | Anywhere (0.0.0.0/0)  |

### 3. Connect to EC2 Instance
```bash
ssh -i /path/to/key.pem ubuntu@<ec2-public-ip>
```

---

## Step 2: Install Dependencies on EC2

### 1. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Git, Docker, and Docker Compose
```bash
sudo apt install git docker.io docker-compose-v2 -y
```

### 3. Start and Enable Docker
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 4. Add User to Docker Group (to run Docker without sudo)
```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

## Step 3: Jenkins Installation and Setup

### 1. Install Java (OpenJDK 17)
```bash
sudo apt install openjdk-17-jdk -y
```

### 2. Add Jenkins Repository and Install
```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
```

### 3. Start and Enable Jenkins Service
```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 4. Initial Jenkins Setup
- Retrieve the initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

- Access the Jenkins dashboard at `http://<ec2-public-ip>:8080`
- Paste the password, install suggested plugins, and create an admin user

### 5. Grant Jenkins Docker Permissions
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## Step 4: GitHub Repository Configuration

### Dockerfile
```dockerfile
FROM python:3.9-slim
WORKDIR /app
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

### docker-compose.yml
```yaml
version: "3.8"

services:
  mysql:
    container_name: mysql
    image: mysql
    environment:
      MYSQL_DATABASE: "devops"
      MYSQL_ROOT_PASSWORD: "root"
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - two-tier
    restart: always

  flask:
    build: .
    container_name: two-tier-app
    ports:
      - "5000:5000"
    environment:
      - MYSQL_HOST=mysql
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root
      - MYSQL_DB=devops
    networks:
      - two-tier
    depends_on:
      - mysql
    restart: always

volumes:
  mysql-data:

networks:
  two-tier:
```

### Jenkinsfile
```groovy
pipeline {
    agent any
    stages {
        stage('Clone Code') {
            steps {
                git branch: 'main', url: 'https://github.com/YanisRamy/Two-Tier-Flask-App-DevOps.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t flask-app:latest .'
            }
        }
        stage('Deploy with Docker Compose') {
            steps {
                sh 'docker compose down || true'
                sh 'docker compose up -d --build'
            }
        }
        stage('Health Check') {
            steps {
                sh 'sleep 5 && curl -f http://localhost:5000 || exit 1'
            }
        }
    }
}
```

---

## Step 5: Jenkins Pipeline Creation and Execution

1. In Jenkins, create a **Pipeline** job
2. Under *Pipeline definition*, select **Pipeline script from SCM**
3. Set SCM to **Git** and paste your repo URL
4. Set *Script Path* to `Jenkinsfile`
5. Under *Build Triggers*, check **GitHub hook trigger for GITScm polling**
6. In your GitHub repo, go to **Settings → Webhooks → Add webhook**:
   - Payload URL: `http://<ec2-public-ip>:8080/github-webhook/`
   - Content type: `application/json`
   - Event: **Just the push event**
7. Click **Build Now** for the first manual run

### Verify Deployment

After a successful build, your Flask application will be accessible at `http://<ec2-public-ip>:5000`.  
Confirm the containers are running with:
```bash
docker ps
docker logs two-tier-app
```

---

## Conclusion

The CI/CD pipeline is fully automated. Every `git push` triggers Jenkins via GitHub webhook to build and deploy the application automatically — no manual intervention required.

---

## Infrastructure Diagram

![Infrastructure](screen%20and%20diagrams/Infrastructure.png)

---

## Workflow Diagram

![Workflow](screen%20and%20diagrams/project_workflow.png)

---
