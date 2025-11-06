pipeline {
    agent any
    stages {
        stage('Clone') {
            steps {
                // Jenkins automatically clones the code when the pipeline starts
                // from the configured repository and branch.
                // This stage is implicitly handled but good to visualize.
                echo 'Cloning the repository...'
                // git branch: 'dev', url: 'https://github.com/FoumaneDonald/webapp.git'
            }
        }
        stage('Build') {
            steps {
                // The commands here depend on your project.
                // For a Java project, you might run: sh 'mvn clean install'
                // For a Node.js project, you might run: sh 'npm install'
                echo 'Building the application...'
                
                // script {

                //     echo "Building Docker image: ${imageName}"

                //     // The 'sh' step runs a shell command. This command builds the Docker image.
                //     // The '.' refers to the current directory (the root of your cloned repo),
                //     // where your Dockerfile should be.
                //     // sh "docker build -t webapp:v1 ."
                // }
            }
        }
        stage('Deploy') {
            steps {
                // The commands here depend on your deployment target.
                // You might copy files to a server or push a Docker image.
                echo 'Deploying the application...'
                // Add your deployment commands here
            }
        }
    }

    post {
        // The 'always' block runs after all stages, regardless of success or failure.
        // It's a good practice to clean up containers to avoid leaving old ones running.
        always {
            script {
                //  def containerName = "my-app-container-${env.BUILD_NUMBER}"
                 echo "Cleaning up old container..."
                 // This command stops and removes the container. The '|| true' part
                 // ensures the pipeline doesn't fail if the container doesn't exist.
                //  sh "docker stop ${containerName} || true"
                //  sh "docker rm ${containerName} || true"
            }
        }
    }
}