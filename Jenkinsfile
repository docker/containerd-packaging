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
  stages {
    stage('build') {
      parallel {
        stage('deb') {
          steps {
            sh 'make deb'
            script {
              if(params.ARCHIVE_PKGS) {
                archiveArtifacts(artifacts: 'build/**/containerd_*.deb')
              }
            }
            deleteDir()
          }
        }
        stage('rpm') {
          steps {
            sh 'make rpm'
            script {
              if(params.ARCHIVE_PKGS) {
                archiveArtifacts(artifacts: 'rpm/**/containerd-*.rpm')
              }
            }
            deleteDir()
          }
        }
      }
    }
  }
}
