#!groovy

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "ubuntu:focal",                   arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
]

def generatePackageStep(opts, arch) {
    return {
        node("linux&&${arch}") {
            stage("${opts.image}-${arch}") {
                try {
                    sh 'docker version'
                    sh 'docker info'
                    sh 'apt list libseccomp2 -a'
                    sh '''
                    curl -fsSL "https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh" | bash || true
                    '''
                    checkout scm
                    sh '''
                    if [ "$(uname -p)" = "armv7l" ]; then
                        echo "installing libseccomp2_2.4.3-0ubuntu2_armhf.deb"
                        curl -fsSL https://launchpad.net/ubuntu/+archive/primary/+files/libseccomp2_2.4.3-0ubuntu2_armhf.deb > libseccomp2_2.4.3-0ubuntu2_armhf.deb

                        sudo dpkg -i libseccomp2_2.4.3-0ubuntu2_armhf.deb

                        rm libseccomp2_2.4.3-0ubuntu2_armhf.deb

                        apt list libseccomp2 -a

                        docker pull arm32v7/ubuntu:focal;

                        echo "Minimal reproducer: this should pass (seccomp disabled)"
                        docker run -e DEBIAN_FRONTEND=noninteractive --rm --security-opt seccomp=unconfined arm32v7/ubuntu:focal sh -c 'apt-get -q update && apt-get install -y libc6';

                        echo "Minimal reproducer: this should pass (updated seccomp profile)"
                        docker run -e DEBIAN_FRONTEND=noninteractive --rm --security-opt seccomp=./default.json arm32v7/ubuntu:focal sh -c 'apt-get -q update && apt-get install -y libc6';

                        echo "Minimal reproducer: default seccomp profile"
                        docker run -e DEBIAN_FRONTEND=noninteractive --rm --security-opt seccomp=./default.json arm32v7/ubuntu:focal sh -c 'apt-get -q update && apt-get install -y libc6';
                    fi
                    '''
                    sh("docker pull ${opts.image}")
                    sh("make BUILD_IMAGE=${opts.image} CREATE_ARCHIVE=1 clean build")
                    archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
                } finally {
                    sh "sudo chmod -R 777 ."
                    sh "sudo apt-get install -y --allow-downgrades libseccomp2=2.4.1-0ubuntu0.16.04.2"
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
