#!groovy

def arches = ["amd64", "armhf", "aarch64"]

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "amazonlinux:2",                arches: arches - ["amd64", "armhf"]],
    [image: "centos:7",                     arches: arches - ["armhf"]],
    [image: "debian:stretch",               arches: arches],    // Debian 9 (EOL: June, 2022)
    [image: "debian:buster",                arches: arches],    // Debian 10 (EOL: 2024)
    [image: "fedora:29",                    arches: arches - ["armhf"]],
    [image: "fedora:30",                    arches: arches - ["armhf"]],
    [image: "fedora:31",                    arches: arches - ["armhf"]],
    [image: "fedora:latest",                arches: arches - ["armhf"]],
    [image: "opensuse/leap:15",             arches: arches - ["armhf", "aarch64"]],
    [image: "resin/rpi-raspbian:stretch",   arches: ["armhf"]],
    [image: "resin/rpi-raspbian:buster",    arches: ["armhf"]],
    [image: "ubuntu:xenial",                arches: arches],    // Ubuntu 16.04 LTS (End of support: April, 2021. EOL: April, 2024)
    [image: "ubuntu:bionic",                arches: arches],    // Ubuntu 18.04 LTS (End of support: April, 2023. EOL: April, 2028)
    [image: "ubuntu:disco",                 arches: arches],    // Ubuntu 19.03  (EOL: January, 2020)
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
