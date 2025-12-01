pipeline {
    agent any

    environment {
        GIT_REPO       = "https://github.com/tin12q/react-starter-kit-main.git"
        IMAGE_NAME     = "react-starter-kit"
        APP_HOST       = "54.210.126.158"       // IP App Server
        SSH_CRED_ID    = "ssh-app-server"       // Jenkins Credentials ID
        APP_USER       = "ubuntu"
        CONTAINER_NAME = "react-starter"
        HOST_PORT      = "80"                   // Cổng ngoài EC2
        APP_PORT       = "80"                   // Cổng trong container (Dockerfile EXPOSE 80)
    }

    stages {

        stage("Checkout Source") {
            steps {
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage("Build Docker Image") {
            steps {
                sh """
                    echo "Building Docker image..."
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                """
            }
        }

        stage("Export Image & Transfer to App Server") {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: SSH_CRED_ID,
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh """
                        echo "Saving image..."
                        docker save ${IMAGE_NAME}:${BUILD_NUMBER} | bzip2 > image.tar.bz2

                        echo "Copying image to App Server..."
                        scp -i $SSH_KEY -o StrictHostKeyChecking=no image.tar.bz2 ${SSH_USER}@${APP_HOST}:/tmp/image.tar.bz2
                    """
                }
            }
        }

        stage("Deploy on App Server") {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: SSH_CRED_ID,
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh """
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ${SSH_USER}@${APP_HOST} << 'EOF'
                            
                            echo "Unpacking image..."
                            cd /tmp
                            bunzip2 -f image.tar.bz2
                            docker load -i image.tar

                            echo "Stopping old container..."
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            echo "Running new container..."
                            docker run -d \
                                --name ${CONTAINER_NAME} \
                                -p ${HOST_PORT}:${APP_PORT} \
                                ${IMAGE_NAME}:${BUILD_NUMBER}

                            echo "Deployment done."
                        EOF
                    """
                }
            }
        }
    }
}
