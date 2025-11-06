pipeline {
    agent any
    stages {
        stage('Clone') {
            steps {
                // Jenkins automatically clones the code when the pipeline starts
                // from the configured repository and branch.
                // This stage is implicitly handled but good to visualize.
                echo 'Cloning the repository...'
                git branch: 'dev', url: 'https://github.com/FoumaneDonald/webapp.git'
            }
        }
        stage('Build') {
            steps {
                // The commands here depend on your project.
                // For a Java project, you might run: sh 'mvn clean install'
                // For a Node.js project, you might run: sh 'npm install'
                echo 'Building the application...'
                
                script {

                    echo "Building Docker image: ${IMAGE_NAME}"

                    // The 'sh' step runs a shell command. This command builds the Docker image.
                    // The '.' refers to the current directory (the root of your cloned repo),
                    // where your Dockerfile should be.
                    bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
        stage('Deploy - Run docker container') {
            steps {
                script {
                    echo "Running Docker container from image: ${IMAGE_NAME}"

                    // This command will run the container.
                    // -d runs the container in detached mode (in the background).
                    // -p 8080:80 maps port 8080 on your host to port 80 in the container.
                    //    (Adjust the ports according to your application's needs).
                    // --name gives the container a unique name to avoid conflicts.
                    bat "docker run -d -p 80:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        // The 'always' block runs after all stages, regardless of success or failure.
        // It's a good practice to clean up containers to avoid leaving old ones running.
        always {
            script {
                echo "Cleaning up old container..."
                // This command stops and removes the container. The '|| true' part
                // ensures the pipeline doesn't fail if the container doesn't exist.
                bat "docker stop ${CONTAINER_NAME} || true"

                echo 'Deploying the application...'
                
                bat "docker rm ${CONTAINER_NAME} || true"
            }
        }
         success {
           slackSend(channel: '#jenkins_notification', color: 'good', message: "Deployment Successful: ${IMAGE_NAME} - Build ${CONTAINER_NAME}")
        }
        failure {
            slackSend(channel: '#jenkins_notification', color: 'danger', message: "Deployment Failed: ${IMAGE_NAME} - Build ${CONTAINER_NAME}")
        }
    }
}