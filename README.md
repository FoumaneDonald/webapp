# DevOps Project: Automated CI/CD Pipeline with Jenkins & Docker

This project demonstrates a complete Continuous Integration and Continuous Deployment (CI/CD) pipeline. A `git push` to the `dev` branch of this repository automatically triggers a Jenkins pipeline that builds a Docker image for the web application and deploys it as a running container.

## Pipeline Workflow

The automation is configured to follow these steps:

1.  **Commit & Push**: A developer pushes a commit to the `dev` branch on GitHub.
2.  **Webhook Trigger**: GitHub sends a webhook notification to our Jenkins server.
3.  **Jenkins Pipeline Starts**: Jenkins receives the notification and starts the pipeline defined in the `Jenkinsfile`.
    *   **Stage 1: Clone**: Jenkins clones the `dev` branch of the repository.
    *   **Stage 2: Build**: Jenkins uses the `Dockerfile` in the repository to build a new Docker image of the application.
    *   **Stage 3: Deploy**: Jenkins stops and removes any old version of the application container and then runs a new container from the image built in the previous stage.
4.  **Notification**: Jenkins sends a success or failure notification to a Slack channel.

## Prerequisites

Before you begin, ensure you have the following installed and configured on your machine:

*   **Jenkins**: An up-to-date Jenkins installation.
*   **Docker**: Docker Desktop (or Docker Engine on Linux) must be running.
*   **Git**: For version control.
*   **Ngrok**: A tool to expose your local Jenkins server to the internet.

## Configuration Steps

Follow these steps to set up the CI/CD pipeline environment.

### Step 1: Jenkins Server Setup

1.  **Install Necessary Plugins**:
    In your Jenkins dashboard, go to `Manage Jenkins` > `Plugins` and install the following:
    *   `GitHub Integration`
    *   `Docker Pipeline`
    *   `Slack Notification`

2.  **Grant Docker Permissions to Jenkins**:
    For Jenkins to execute Docker commands, the `jenkins` user must be part of the `docker` group. Open a terminal on the machine running Jenkins and execute:
    ```bash
    # For Linux/macOS
    sudo usermod -aG docker jenkins
    
    # For Windows, add the Jenkins user to the 'docker-users' group manually
    ```
    **You must restart Jenkins** for this change to take effect.

3.  **Configure Slack Integration (Optional)**:
    Go to `Manage Jenkins` > `System` and scroll down to the "Slack" section. Add your Slack workspace credentials to allow Jenkins to send notifications.

### Step 2: Expose Jenkins with Ngrok

Since our Jenkins server is running on `localhost`, GitHub cannot reach it. We will use `ngrok` to create a secure public URL.

1.  Open a new terminal.
2.  Start `ngrok` to forward traffic to Jenkins (which typically runs on port 1212):
    ```bash
    ngrok http 1212
    ```
3.  `ngrok` will provide a public "Forwarding" URL (e.g., `https://random-string.ngrok.io`). **Copy this URL**, as you will need it for the next step.

### Step 3: Configure GitHub Webhook

1.  Navigate to your GitHub repository and go to `Settings` > `Webhooks`.
2.  Click `Add webhook`.
3.  In the **Payload URL** field, paste your `ngrok` forwarding URL and add `/github-webhook/` at the end.
    *   Example: `https://random-string.ngrok.io/github-webhook/`
4.  For **Content type**, select `application/json`.
5.  Leave the other settings as default and click `Add webhook`.

### Step 4: Create the Jenkins Pipeline Job

1.  On the Jenkins dashboard, click `New Item`.
2.  Enter a name for your pipeline (e.g., `webapp-pipeline`) and select **Pipeline**. Click `OK`.
3.  In the configuration page, go to the **Build Triggers** section and check the box for `GitHub hook trigger for GITScm polling`.
4.  Go to the **Pipeline** section.
    *   For **Definition**, select `Pipeline script from SCM`.
    *   For **SCM**, select `Git`.
    *   In **Repository URL**, paste the URL of your GitHub repository.
    *   In **Branch Specifier**, enter `*/dev`.
    *   Ensure **Script Path** is `Jenkinsfile`.
5.  Click `Save`.

## How to Trigger and Verify the Deployment

### Triggering the Pipeline

To run the pipeline, simply make a change, commit it, and push it to the `dev` branch.

```bash
git checkout dev
# ...make a code change...
git add .
git commit -m "feat: updated application feature"
git push origin dev
```

### Verifying the Deployment

1.  **Check Jenkins**: Open your pipeline view in Jenkins. You will see a new build running. Watch the stages turn green.
2.  **Check Docker**: Once the pipeline succeeds, open a terminal and run `docker ps` to see your container running.
    ```bash
    docker ps
    ```
    You should see an output similar to this, confirming your container is up and port `80` is mapped.
    ```
    CONTAINER ID   IMAGE                COMMAND                  STATUS         PORTS                NAMES
    c1a2b3d4e5f6   my-webapp:1          "/usr/sbin/nginx -g…"   Up 5 seconds   0.0.0.0:80->80/tcp   my-webapp-container-1
    ```
3.  **Access the Application**: Open your web browser and navigate to:
    **`http://localhost`**

    You should see your deployed web application.

## Project Files

### `Jenkinsfile`

This file defines the CI/CD pipeline stages and steps. It uses environment variables to keep image and container names consistent and dynamic. The `bat` command is used for execution on a Windows-based Jenkins agent.

```groovy
pipeline {
    // Define environment variables for use in pipeline stages
    environment {
        IMAGE_NAME = "my-webapp"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        CONTAINER_NAME = "my-webapp-container-${env.BUILD_NUMBER}"
    }

    agent any

    stages {
        stage('Clone') {
            steps {
                echo 'Cloning the repository from the dev branch...'
                git branch: 'dev', url: 'https://github.com/FoumaneDonald/webapp.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                // 'bat' is used for Windows agents. Use 'sh' for Linux/macOS.
                bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Deploy - Run Docker Container') {
            steps {
                echo "Running Docker container ${CONTAINER_NAME}"
                // The container is run in detached mode and maps port 80 on the host to port 80 in the container.
                bat "docker run -d -p 80:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    // The 'post' block runs after all stages are complete.
    post {
        // 'always' runs regardless of pipeline status. It's used here for cleanup.
        always {
            echo "Cleaning up old container..."
            // Stop and remove the container. '|| true' prevents the pipeline from failing if the container doesn't exist.
            bat "docker stop ${CONTAINER_NAME} || true"
            bat "docker rm ${CONTAINER_NAME} || true"
        }
        // 'success' runs only if the pipeline is successful.
        success {
           slackSend(channel: '#jenkins_notification', color: 'good', message: "Deployment Successful: ${IMAGE_NAME}:${IMAGE_TAG} - Build #${env.BUILD_NUMBER}")
        }
        // 'failure' runs only if the pipeline fails.
        failure {
            slackSend(channel: '#jenkins_notification', color: 'danger', message: "Deployment Failed: ${IMAGE_NAME}:${IMAGE_TAG} - Build #${env.BUILD_NUMBER}")
        }
    }
}
```

### `Dockerfile`

This file contains the instructions to build a Docker image for our Nginx-based web application.

```dockerfile
# Use the official Ubuntu 22.04 image as a parent image
FROM ubuntu:22.04

# Set a label for the maintainer
LABEL maintainer="donald"

# Update package lists and install nginx and git in a single command
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git

# Clean up the default nginx content directory
RUN rm -Rf /var/www/html/*

# Clone the application's source code from GitHub into the web root
RUN git clone https://github.com/FoumaneDonald/carnet_address.git /var/www/html/

# Expose port 80 to allow traffic to nginx
EXPOSE 80

# Command to run when the container starts. This keeps nginx in the foreground.
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
```