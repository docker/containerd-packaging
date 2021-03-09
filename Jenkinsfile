#!groovy

properties(
    [
        parameters(
            [
                booleanParam(name: 'ARCHIVE', defaultValue: false, description: 'Archive the build artifacts by pushing to an S3 bucket.'),
                string(name: 'CONTAINERD_REF', defaultValue: 'master', description: 'Git ref of containerd repo to build.'),
                string(name: 'RUNC_REF', defaultValue: '', description: 'Git ref of runc repo to build.'),
            ]
        )
    ]
)

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "docker.io/library/amazonlinux:2",          arches: ["aarch64"]],
    [image: "docker.io/library/centos:7",               arches: ["amd64", "aarch64"]],
    [image: "docker.io/dockereng/rhel:7-s390x",         arches: ["s390x"]],
    [image: "docker.io/library/centos:8",               arches: ["amd64", "aarch64"]],
    [image: "docker.io/library/debian:buster",          arches: ["amd64", "aarch64", "armhf"]], // Debian 10 (EOL: 2024)
    [image: "docker.io/library/debian:bullseye",        arches: ["amd64", "aarch64", "armhf"]], // Debian 11 (Next stable)
    [image: "docker.io/library/fedora:32",              arches: ["amd64", "aarch64"]],
    [image: "docker.io/library/fedora:33",              arches: ["amd64", "aarch64"]],
    [image: "docker.io/library/fedora:rawhide",         arches: ["amd64"]],                     // Rawhide is the name given to the current development version of Fedora
    [image: "docker.io/opensuse/leap:15",               arches: ["amd64"]],
    [image: "docker.io/balenalib/rpi-raspbian:buster",  arches: ["armhf"]],
    [image: "docker.io/balenalib/rpi-raspbian:bullseye",arches: ["armhf"]],
    [image: "docker.io/library/ubuntu:xenial",          arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 16.04 LTS (End of support: April, 2021. EOL: April, 2024)
    [image: "docker.io/library/ubuntu:bionic",          arches: ["amd64", "aarch64", "armhf", "s390x"]], // Ubuntu 18.04 LTS (End of support: April, 2023. EOL: April, 2028)
    [image: "docker.io/library/ubuntu:focal",           arches: ["amd64", "aarch64"]],          // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
    [image: "docker.io/library/ubuntu:groovy",          arches: ["amd64", "aarch64"]],          // Ubuntu 20.10 (EOL: July, 2021)
]

def generatePackageStep(opts, arch) {
    return {
        wrappedNode(label: "linux&&${arch}") {
            stage("${opts.image}-${arch}") {
                try {
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

def packageBuildSteps = [
    "windows": { ->
        node("windows-2019") {
            stage("windows") {
                try {
                    checkout scm
                    sh("make -f Makefile.win REF=v1.2.13 archive")
                    archiveArtifacts(artifacts: 'build/windows/containerd.zip', onlyIfSuccessful: true)
                } finally {
                    deleteDir()
                }
            }
        }
    }
]

packageBuildSteps << images.collectEntries { generatePackageSteps(it) }

pipeline {
    agent none
    stages {
        stage('Check file headers') {
            agent { label 'linux&&amd64' }
            steps{
                script{
                    checkout scm
                    sh "make validate"
                }
            }
        }
        stage('Build packages') {
            steps {
                script {
                    parallel(packageBuildSteps)
                }
            }
        }
    }
}
