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

- Launch an **Ubuntu** EC2 instance (t2.medium recommended)
- Open inbound ports: **22** (SSH), **8080** (Jenkins), **5000** (Flask)
- Connect via SSH

---

## Step 2: Install Dependencies on EC2
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git docker.io docker-compose-v2 -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```

---

## Step 3: Jenkins Installation and Setup
```bash
sudo apt install openjdk-17-jdk -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## Step 4: GitHub Repository Configuration

### Dockerfile
```dockerfile
FROM python:3.9-slim 

WORKDIR /app


RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && \
rm -rf /var/lib/apt/lists/* 

COPY requirement.txt .

RUN pip install --no-cache-dir -r requirement.txt

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
      MYSQL_ROOT_PASSWORD: "root"
      MYSQL_DATABASE: "devops"
    ports:
      - "3306:3306"

    volumes:
      - mysql_data:/var/lib/mysql

    networks:
      - two-tier-nt

    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot","-proot"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s


  flask-app:
    container_name: two-tier-app
    build:
      context: .

    ports:
      - "5000:5000"

    environment:
      - MYSQL_HOST=mysql
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root
      - MYSQL_DB=devops

    networks:
      - two-tier-nt

    depends_on:
      mysql:
        condition: service_healthy

    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s

volumes:
  mysql_data:

networks:
  two-tier-nt:
```

### Jenkinsfile
```groovy
pipeline{
    agent any
    stages{
        stage('Clone repo'){
            steps{
                git branch: 'main', url: 'https://github.com/prashantgohel321/DevOps-Project-Two-Tier-Flask-App.git'
            }
        }
        stage('Build image'){
            steps{
                sh 'docker build -t flask-app .'
            }
        }
        stage('Deploy with docker compose'){
            steps{
                // existing container if they are running
                sh 'docker compose down || true'
                // start app, rebuilding flask image
                sh 'docker compose up -d --build'
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
5. Click **Build Now**
6. Access the Flask app at `http://<ec2-public-ip>:5000`
7. Monitor build logs in **Jenkins Stage View**

---

## Conclusion

The CI/CD pipeline is fully automated. Every `git push` triggers Jenkins to build and deploy the application automatically — no manual intervention required.

---

## Infrastructure Diagram

![Infrastructure](screen%20and%20diagrams/Infrastructure.png)

---

## Workflow Diagram

![Workflow](screen%20and%20diagrams/project_workflow.png)
