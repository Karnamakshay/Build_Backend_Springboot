pipeline {
    agent none

    parameters {
        string(name: 'ECRURL',
               defaultValue: '445343419895.dkr.ecr.ap-south-1.amazonaws.com',
               description: 'Please Enter your Docker ECR REGISTRY URL without https?')

        string(name: 'APPREPO',
               defaultValue: 'wezvatechbackend',
               description: 'Please Enter your Docker App Repo Name:TAG?')

        string(name: 'REGION',
               defaultValue: 'ap-south-1',
               description: 'Please Enter your AWS Region?')

        password(name: 'PASSWD',
                 defaultValue: '',
                 description: 'Please Enter your Github password')
    }

    stages {

        stage('Checkout') {
            agent { label 'demo' }
            steps {
                git branch: 'main',
                    credentialsId: 'GithubCred',
                    url: 'https://github.com/Karnamakshay/Build_Backend_Springboot.git'
            }
        }

        stage('Build') {
            agent { label 'demo' }
            steps {
                echo "Building Spring Boot Jar ..."
                sh "mvn clean package -Dmaven.test.skip=true"
                sh "cp target/wezvatech-springboot-mysql-9739110917.jar target/backend_rel${BUILD_ID}.jar"
            }
        }

        stage('Build Image') {
            agent { label 'demo' }
            steps {
                script {
                    // Prepare the Tag name for the Image
                    AppTag = params.APPREPO + ":rel" + env.BUILD_ID

                    // Docker login needs https appended
                    ECR = "https://" + params.ECRURL

                    docker.withRegistry(ECR, 'ecr:ap-south-1:AWSCred') {
                        // Build Docker Image locally
                        myImage = docker.build(AppTag)

                        // Push the Image to the Registry
                        myImage.push()
                    }
                }
            }
        }

        stage('Scan Image') {
            agent { label 'demo' }
            steps {
                echo "Scanning Image for Vulnerabilities"
                sh "trivy image --offline-scan ${params.APPREPO}:rel${BUILD_ID} > trivyresults.txt"

                echo "Analyze Dockerfile for best practices ..."
                sh "docker run --rm -i hadolint/hadolint < Dockerfile | tee -a dockerlinter.log"
            }
            post {
                always {
                    sh "docker rmi ${params.APPREPO}:rel${BUILD_ID}"
                }
            }
        }

    }
}
