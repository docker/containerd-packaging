#!groovy

def arches = ["amd64", "armhf", "aarch64"]

def images = [
    //Ubuntu is really the only distribution where we produce everything
    [image: "ubuntu:bionic",    arches: arches],
    [image: "amazonlinux:2",    arches: arches - ["amd64", "armhf"]],
    [image: "debian:stretch",   arches: arches],
    [image: "centos:7",         arches: arches - ["armhf"]],
    [image: "fedora:latest",    arches: arches - ["armhf"]],
    [image: "fedora:30",        arches: arches - ["armhf"]],
    [image: "fedora:29",        arches: arches - ["armhf"]],
    [image: "opensuse/leap:15", arches: arches - ["armhf", "aarch64"]],
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
