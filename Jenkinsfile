pipeline {
    agent any
    stages {
        stage('Clone') {
            steps {
                // Jenkins automatically clones the code when the pipeline starts
                // from the configured repository and branch.
                slackSend(channel: '#jenkins_notification', color: 'good', message: "Cloning repository...")
                git branch: 'dev', url: 'https://github.com/FoumaneDonald/webapp.git'
            }
        }
        stage('Build') {
            steps {
                script {

                    slackSend(channel: '#jenkins_notification', color: 'good', message: "Building the application...")

                    // The 'sh' step runs a shell command. This command builds the Docker image.
                    // The '.' refers to the current directory (the root of your cloned repo),
                    // where your Dockerfile should be.
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
        stage('Deploy - Run docker container') {
            steps {
                script {
                    slackSend(channel: '#jenkins_notification', color: 'good', message: "Running Docker container from image: ${IMAGE_NAME}")

                    // This command will run the container.
                    // -d runs the container in detached mode (in the background).
                    // -p 1212:80 maps port 1212 on your host to port 80 in the container.
                    //    (Adjust the ports according to your application's needs).
                    // --name gives the container a unique name to avoid conflicts.
                    sh "docker run -d -p 1212:80 --name ${IMAGE_NAME} ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        // The 'always' block runs after all stages, regardless of success or failure.
        // It's a good practice to clean up containers to avoid leaving old ones running.
        always {
            script {
                slackSend(channel: '#jenkins_notification', color: 'good', message: "Cleaning up old container...")
                // This command stops and removes the container. The '|| true' part
                // ensures the pipeline doesn't fail if the container doesn't exist.
                sh "docker stop ${IMAGE_NAME} || true"
                
                slackSend(channel: '#jenkins_notification', color: 'good', message: "Deploying the application...")
                
                sh "docker rm ${IMAGE_NAME} || true"
            }
        }
        success {
           slackSend(channel: '#jenkins_notification', color: 'good', message: "Deployment Successful: ${IMAGE_NAME} - Build ${IMAGE_NAME}")
        }
        failure {
            slackSend(channel: '#jenkins_notification', color: 'danger', message: "Deployment Failed: ${IMAGE_NAME} - Build ${IMAGE_NAME}")
        }
    }
}