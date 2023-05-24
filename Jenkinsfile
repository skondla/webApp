pipeline {
  agent any
  stages {
    stage('build') {
      steps {
        echo 'build stage'
      }
    }

    stage('test') {
      parallel {
        stage('test') {
          steps {
            echo 'testing stage'
          }
        }

        stage('period') {
          steps {
            sleep(time: 5, unit: 'MINUTES')
          }
        }

      }
    }

    stage('deploy') {
      steps {
        echo 'deploy stage'
      }
    }

  }
}