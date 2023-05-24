pipeline {
  agent any
  stages {
    stage('build') {
      parallel {
        stage('build') {
          steps {
            echo 'build stage'
          }
        }

        stage('check') {
          steps {
            timeout(time: 180)
          }
        }

      }
    }

    stage('test') {
      steps {
        echo 'testing stage'
      }
    }

    stage('deploy') {
      steps {
        echo 'deploy stage'
      }
    }

  }
}