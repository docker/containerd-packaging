pipeline {
  agent {
    label 'ubuntu-1604-aufs-edge'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '30'))
    timestamps()
  }
  parameters {
    booleanParam(name: 'ARCHIVE_PKGS', description: 'Archive packages upon successful build.', defaultValue: false)
  }
  post {
    success {
      if(params.ARCHIVE_PKGS) {
        archiveArtifacts(artifacts: 'build/**/containerd_*.deb')
        archiveArtifacts(artifacts: 'rpm/**/containerd-*.rpm')
      }
    }
    always {
      deleteDir()
    }
  }
  stages {
    stage('build') {
      parallel {
        stage('deb') {
          steps {
            sh 'make deb'
          }
        }
        stage('rpm') {
          steps {
            sh 'make rpm'
          }
        }
      }
    }
  }
}
