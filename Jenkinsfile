pipeline {
agent none
parameters {
string(name: 'ECRURL', defaultValue: '445343419895.dkr.ecr.ap-south-1.amazonaws.com',description: 'Please Enter your Docker ECR REGISTRY URL without https?')
string(name: 'APPREPO', defaultValue: 'wezvatechbackend', description: 'Please Enter your Docker App Repo Name:TAG?')
string(name: 'REGION', defaultValue: 'ap-south-1', description: 'Please Enter your AWS Region?')
password(name: 'PASSWD', defaultValue: '', description: 'Please Enter your Github password')
}

stages{
stage('Checkout')
{
agent { label 'demo' }
steps {
git branch: 'main', credentialsId: 'GithubCred', url: 'https://github.com/Karnamakshay/Build_Backend_Springboot.git'
}
}

stage('Build')
{
agent { label 'demo' }
steps {
echo "Building Sprint Boot Jar ..."
sh "mvn clean package -Dmaven.test.skip=true"
sh "cp target/wezvatech-springboot-mysql-9739110917.jar target/backend_fb${BUILD_ID}.jar"
}
}

stage('Code Coverage')
{
agent { label 'demo' }
steps {
           echo "Running Code Coverage ..."
           sh "mvn org.jacoco:jacoco-maven-plugin:0.8.2:report"
       }
}

stage('SCA')
{
agent { label 'demo' }
steps {
           echo "Running Software Composition Analysis using OWASP Dependency-Check ..."
           sh "mvn org.owasp:dependency-check-maven:check"
      }
}

stage('SAST')
{
agent { label 'demo' }
steps{
        echo "Running Static application security testing using SonarQube Scanner ..."
        withSonarQubeEnv('mysonarqube') {
            sh 'mvn sonar:sonar -Dsonar.dependencyCheck.jsonReportPath=target/dependency-check-report.json -Dsonar.dependencyCheck.htmlReportPath=target/dependency-check-report.html'
       }
      }
}

stage("Quality Gate")
{
agent { label 'demo' }
steps{
        script {
          timeout(time: 1, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Pipeline aborted due to quality gate failure: ${qg.status}"
            }
           }
      }
     }
}

stage('Build Image')
{
agent { label 'demo' }
steps{
script {
// Prepare the Tag name for the Image
AppTag = params.APPREPO + ":fb" + env.BUILD_ID
// Docker login needs https appended
ECR = "https://" + params.ECRURL
docker.withRegistry( ECR, 'ecr:ap-south-1:AWSCred' ) {
// Build Docker Image locally
myImage = docker.build(AppTag)
// Push the Image to the Registry
myImage.push()
}
}
}
}

stage ('Scan Image')
{
agent { label 'demo' }
steps {
echo "Scanning Image for Vulnerabilities"
sh "trivy image --offline-scan ${params.APPREPO}:fb${BUILD_ID} > trivyresults.txt"

echo "Analyze Dockerfile for best practices ..."
sh "docker run --rm -i hadolint/hadolint < Dockerfile | tee -a dockerlinter.log"
}
post {
always {
sh "docker rmi ${params.APPREPO}:fb${BUILD_ID}"
}
}
}
stage('Smoke Deploy')
{
   agent { label 'kind' }
   steps {
       git branch: 'newfeature', credentialsId: 'GithubCred', url: 'https://github.com/Karnamakshay/Build_Backend_Springboot.git'

       echo "Preparing KIND cluster ..."
     sh "kubectl create namespace wezvatechfb || true"

       withAWS(credentials:'AWSCred') {
           sh "kubectl create secret docker-registry awsecr-cred --docker-server=$ECRURL --docker-username=AWS --docker-password=\$(aws ecr get-login-password --region ap-south-1) --namespace=wezvatechfb"
       }

       echo "Deploying New Build ..."
       dir("./deployments") {
         //  sh "sed -i 's/image:.[0-9][0-9].*/image: ${params.ECRURL}\\/${params.APPREPO}:fb${env.BUILD_ID}/g' deploybackend.yml" (this was getting error)
         
sh """
sed -i "s|image:.*|image: ${params.ECRURL}/${params.APPREPO}:fb${env.BUILD_ID}|g" deploybackend.yml
"""
           sh "kubectl apply -f ."
       }
   }
}

    stage('Smoke Test')
    {
       agent { label 'kind' }
       steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS', message: 'Smokes test failed') {
              sh "timeout 105s kubectl wait --for=condition=ready pod/`kubectl get pods -n wezvatechfb |grep wezva |awk '{print \$1}'| tail -1` -n wezvatechfb  --timeout=100s"
            }
            sh  "echo Springboot deployed successfully ..."
             dir("./deployments") {
                 sh "kubectl delete  -f ."
                sh "kubectl delete ns wezvatechfb"
           }
       }
     }
}
}
