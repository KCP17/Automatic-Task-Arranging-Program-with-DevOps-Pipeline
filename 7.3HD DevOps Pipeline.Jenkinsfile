pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building the Ruby application...'
                bat 'ruby -v'
                bat 'gem install bundler'
                bat 'bundle install'
                bat 'gem build automatic_task_arranging.gemspec'
                archiveArtifacts artifacts: '*.gem', fingerprint: true
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                bat 'if not exist test-reports mkdir test-reports'
                bat 'bundle exec rspec --format RspecJunitFormatter --out test-reports/rspec.xml'
                junit 'test-reports/*.xml'
                
                // Run Cucumber tests if available
                bat 'bundle exec cucumber --format json --out cucumber.json || exit 0'
                cucumber 'cucumber.json'
            }
        }
        
        stage('Code Quality') {
            steps {
                echo 'Checking code quality...'
                bat 'bundle exec rubocop --format html --out rubocop-report.html'
                bat 'bundle exec rubycritic --format html --out rubycritic-report'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '',
                    reportFiles: 'rubocop-report.html',
                    reportName: 'RuboCop Report'
                ])
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'rubycritic-report',
                    reportFiles: 'overview.html',
                    reportName: 'RubyCritic Report'
                ])
            }
        }
        
        stage('Security') {
            steps {
                echo 'Scanning for security vulnerabilities...'
                bat 'bundle exec bundle-audit check --update'
                bat 'bundle exec brakeman -o brakeman-report.html || exit 0'
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '',
                    reportFiles: 'brakeman-report.html',
                    reportName: 'Brakeman Security Report'
                ])
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                bat 'docker build -t taskapp:staging .'
                bat 'docker stop taskapp-staging || exit 0'
                bat 'docker rm taskapp-staging || exit 0'
                bat 'docker run -d --name taskapp-staging -p 8081:4567 taskapp:staging'
            }
        }
        
        stage('Release') {
            steps {
                echo 'Releasing to production...'
                bat 'docker build -t taskapp:production .'
                bat 'docker tag taskapp:production taskapp:%BUILD_NUMBER%'
                bat 'docker stop taskapp-production || exit 0'
                bat 'docker rm taskapp-production || exit 0'
                bat 'docker run -d --name taskapp-production -p 8082:4567 taskapp:production'
            }
        }
        
        stage('Monitoring') {
            steps {
                echo 'Setting up monitoring...'
                bat 'docker run -d --name prometheus -p 9090:9090 prom/prometheus || exit 0'
                bat 'docker run -d --name grafana -p 3000:3000 grafana/grafana || exit 0'
                
                echo 'Creating a dashboard link for monitoring'
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '',
                    reportFiles: 'monitoring-dashboard.html',
                    reportName: 'Monitoring Dashboard'
                ])
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
            emailext subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                     body: "The pipeline failed. Check the logs at ${env.BUILD_URL}",
                     to: 'your.email@example.com'
        }
    }
}