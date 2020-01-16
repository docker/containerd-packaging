#!groovy

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "amazonlinux:2",                  arches: ["aarch64"]],
    [image: "centos:7",                       arches: ["amd64", "aarch64", "armhf"]],
    [image: "centos:8",                       arches: ["amd64", "aarch64", "armhf"]],
    [image: "debian:stretch",                 arches: ["amd64", "aarch64", "armhf"]], // Debian 9  (EOL: June, 2022)
    [image: "debian:buster",                  arches: ["amd64", "aarch64", "armhf"]], // Debian 10 (EOL: 2024)
    [image: "fedora:29",                      arches: ["amd64", "aarch64"]],
    [image: "fedora:30",                      arches: ["amd64", "aarch64"]],
    [image: "fedora:31",                      arches: ["amd64", "aarch64"]],
    [image: "fedora:latest",                  arches: ["amd64"]],
    [image: "opensuse/leap:15",               arches: ["amd64"]],
    [image: "balenalib/rpi-raspbian:stretch", arches: ["armhf"]],
    [image: "balenalib/rpi-raspbian:buster",  arches: ["armhf"]],
    [image: "ubuntu:xenial",                  arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 16.04 LTS (End of support: April, 2021. EOL: April, 2024)
    [image: "ubuntu:bionic",                  arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 18.04 LTS (End of support: April, 2023. EOL: April, 2028)
    [image: "ubuntu:disco",                   arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 19.03  (EOL: January, 2020)
    [image: "ubuntu:eoan",                    arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 19.10  (EOL: July, 2020)
]

// Required for windows
hubCred = [
    $class: 'UsernamePasswordMultiBinding',
    usernameVariable: 'REGISTRY_USERNAME',
    passwordVariable: 'REGISTRY_PASSWORD',
    credentialsId: 'orcaeng-hub.docker.com',
]

def generatePackageStep(opts, arch) {
    return {
        node("linux&&${arch}") {
            stage("${opts.image}-${arch}") {
                try {
                    checkout scm
                    sh("docker pull ${opts.image}")
                    sh("make BUILD_IMAGE=${opts.image} CREATE_ARCHIVE=1 clean build")
                    archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
                } finally {
                    sh "sudo chmod -R 777 ."
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
                    withDockerRegistry(url: "https://index.docker.io/v1/", credentialsId: "dockerbuildbot-index.docker.io") {
                        sh("git clone https://github.com/containerd/containerd containerd-src")
                        def sanitized_workspace=env.WORKSPACE.replaceAll("\\\\", '/')
                        // Replace windows path separators with unix style path
                        sh("make CONTAINERD_DIR=${sanitized_workspace}/containerd-src -f Makefile.win archive")
                    }
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
        stage('Build packages') {
            steps {
                script {
                    parallel(packageBuildSteps)
                }
            }
        }
    }
}
