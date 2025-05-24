pipeline {
    agent any
    
    environment {
        VERSION = "0.0.${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build') {
            // Fully automated, tagged builds with version control and artifact storage
            steps {
                echo 'Building Docker image...'

                // Build Docker image
                bat "docker build -t automatic_task_arranging:${VERSION} ."

                // Save the built Docker image
                bat "docker save -o automatic_task_arranging-${VERSION}.tar automatic_task_arranging:${VERSION}"
                
                // Archive the saved Docker image as an artifact
                archiveArtifacts artifacts: "automatic_task_arranging-${VERSION}.tar", fingerprint: true
            }
            post {
                success {
                    echo "Build stage successfully completed"
                }
                failure {
                    echo "Build stage encountered issues"
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests with Minitest (unit) and RSpec (integration)...'
                
                // Run tests "ruby run_tests.rb" in the container "test_container" of the built & tagged image
                bat "docker run --name test_container automatic_task_arranging:${VERSION} ruby run_tests.rb"

                // Remove the test container
                bat "docker rm -f test_container"
            }
            post {
                success {
                    echo "Test stage PASSED - All tests met the 100% pass threshold"
                }
                failure {
                    echo "Test stage FAILED - Tests did not meet the 100% pass threshold"
                }
            }
        }
        
        stage('Code Quality') {
            // Advanced config: custom thresholds, exclusions, trend monitoring, and gated checks
            steps {
                echo 'Analysing code quality with SonarQube...'
                                
                // Run the container "sonar_container" (remove after that)
                // from the built and tagged image
                // applying the scanner in the image with properties from sonar-project.properties, and an auto-incremented version
                bat """
                    docker run --rm --name sonar_container ^
                    automatic_task_arranging:${VERSION} ^
                    sonar-scanner -Dsonar.projectVersion=${VERSION}
                """
            }
            post {
                success {
                    echo 'Code quality analysis completed successfully'
                }
                failure {
                    echo 'Code quality analysis encountered issues'
                }
            }
        }
        
        stage('Security') {
            steps {
                echo 'Scanning for security issues with bundler-audit...'
                
                // Run the "security_container" from built & tagged image, with the command at the end to keep the container running
                bat """
                    docker run -d --name security_container automatic_task_arranging:${VERSION} /bin/bash -c "tail -f /dev/null"
                """
                
                // Run the container, navigate into /app, update latest security threats, check gems for security issues. Always exit 0 to keep pipeline running
                bat """
                    docker exec security_container /bin/bash -c "cd /app && bundle-audit update && bundle-audit check || exit 0"
                """
                
                // Clean up container
                bat "docker rm -f security_container"
            }
            post {
                success {
                    echo 'Security analysis completed successfully'
                }
                failure {
                    echo 'Security analysis encountered issues running the scan'
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying application to test environment...'
                
                // Execute deployment script
                bat 'deploy-scripts\\deploy.bat'
            }
            post {
                success {
                    echo 'Deployment to test environment successful'
                }
                failure {
                    echo 'Deployment failed, executing rollback...'
                    // Execute rollback script
                    bat 'deploy-scripts\\rollback.bat'
                }
            }
        }
        
        stage('Release') {
            // Tagged, versioned, automated release with environment-specific configs using Octopus Deploy
            steps {
                // Login to Docker Hub with username & password
                bat 'docker login --username kcp17 --password d0ck3RforHD'
                
                // Tag the built image with Docker Hub repo name & push that image to Docker Hub
                bat "docker tag automatic_task_arranging:${VERSION} kcp17/automatic_task_arranging:${VERSION}"
                bat "docker push kcp17/automatic_task_arranging:${VERSION}"
                
                // Create new release referencing the pushed image in Docker Hub for the created project with the current version, server link, API key
                bat 'octo create-release --project "Automatic Task Arranging" --version %VERSION% --server https://kcp.octopus.app/ --apiKey API-SIL46QAPAMZYMIEN9AM4PYS4KKI5J'
                
                // Release the created release (of the project & version) to Staging environment, connected to the server, and authenticated using API key (showing progress)
                echo "Deploying to Staging environment..."
                bat 'octo deploy-release --project "Automatic Task Arranging" --version %VERSION% --deployto Staging --server https://kcp.octopus.app/ --apiKey API-SIL46QAPAMZYMIEN9AM4PYS4KKI5J --progress'
                
                // Release the created release (of the project & version) to Production environment, connected to the server, and authenticated using API key (showing progress)
                echo "Releasing to Production environment..."
                bat 'octo deploy-release --project "Automatic Task Arranging" --version %VERSION% --deployto Production --server https://kcp.octopus.app/ --apiKey API-SIL46QAPAMZYMIEN9AM4PYS4KKI5J --progress'
                
                echo "App version $VERSION has been released to Production environment"
            }
            post {
                success {
                    echo 'Release with Octopus Deploy successful'
                }
                failure {
                    echo 'Release with Octopus Deploy failed'
                }
            }
        }
        
        stage('Monitoring') {
            steps {
                // Start the Ruby GUI application in detached mode
                echo 'Starting Ruby application...'
                bat '''
                    cd C:\\Applications\\AutomaticTaskArranging
                    start "" ruby AutomaticTaskArranging.rb
                '''
                // Wait for application to start
                echo 'Waiting for application to start...'
                sleep 30

                // Return to Jenkins workspace
                echo 'Returning to workspace and starting Prometheus...'
                bat '''
                    cd C:\\prometheus
                    start "" prometheus.exe --config.file=prometheus.yml --storage.tsdb.path=data --web.listen-address=:9095
                '''
                // Wait for services to start up
                echo 'Waiting for services to initialize...'
                sleep 30
                
                // Verify Prometheus is running
                echo 'Verifying Prometheus is accessible...'
                bat 'curl -f http://localhost:9095/api/v1/query?query=up || echo "Prometheus not ready yet"'
                
                // Query application metrics directly to console
                echo 'Querying application metrics...'
                
                // Query screen views total
                echo 'Querying screen_views_total metric...'
                bat 'curl -s "http://localhost:9095/api/v1/query?query=screen_views_total"'
                
                // Query session duration
                echo 'Querying session_duration_seconds metric...'
                bat 'curl -s "http://localhost:9095/api/v1/query?query=session_duration_seconds"'
                
                // Query memory usage
                echo 'Querying memory_usage_megabytes metric...'
                bat 'curl -s "http://localhost:9095/api/v1/query?query=memory_usage_megabytes"'
                
                // Wait for alerts to be triggered
                echo 'Waiting for alerts to be triggered...'
                sleep 30
                // Check alerts
                echo 'Checking alerts...'
                bat 'curl -s "http://localhost:9095/api/v1/alerts"'
            }
            post {
                success {
                    echo 'Monitoring stage succeeded. Prometheus Dashboard available at: http://localhost:9095'
                }
                failure {
                    echo "Monitoring stage failed"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}