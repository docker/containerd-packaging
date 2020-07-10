#!groovy

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "docker.io/library/ubuntu:focal",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
]

def generatePackageStep(opts, arch) {
    return {
        wrappedNode(label: "ubuntu-1804&&${arch}") {
            stage("${opts.image}-${arch}") {
                try {
                    if (arch == "armhf") {
                        // TODO remove this: temporarily using "insecure" builds on armhf to disable seccomp
                        sh '''
                        sudo mkdir -p /etc/docker
                        sudo sh -c \'echo {\\"builder\\":{\\"entitlements\\":{\\"security-insecure\\": true}}} > /etc/docker/daemon.json\'
                        cat /etc/docker/daemon.json
                        sudo systemctl restart docker
                        '''
                    }
                    sh 'docker version'
                    sh 'docker info'
                    sh '''
                    curl -fsSL "https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh" | bash || true
                    '''
                    checkout scm
                    sh 'make clean'
                    withDockerRegistry([url: "", credentialsId: "dockerbuildbot-index.docker.io"]) {
                        sh "make CREATE_ARCHIVE=1 ${opts.image}"
                    }
                    archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
                } finally {
                    deleteDir()
                }
            }
        }
    }
}

def generatePackageSteps(opts) {
    return opts.arches.collectEntries {
        ["${opts.image}-${it}": generatePackageStep(opts, it)]
    }
}

def packageBuildSteps = [:]

packageBuildSteps << images.collectEntries { generatePackageSteps(it) }

pipeline {
    agent none
    stages {
        stage('Build packages') {
            steps {
                script {
                    parallel(packageBuildSteps)
                }
            }
        }
    }
}
