#!groovy

def arches = ["amd64", "armhf", "aarch64"]

def images = [
    //Ubuntu is really the only distribution where we produce everything
    [image: "ubuntu:bionic",    arches: arches],
    [image: "debian:stretch",   arches: arches],
    [image: "centos:7",         arches: arches - ["armhf"]],
    [image: "fedora:latest",    arches: arches - ["armhf"]],
    [image: "opensuse/leap:15", arches: arches - ["armhf", "aarch64"]],
    [image: "sles",             arches: arches - ["armhf", "aarch64"]],
    [image: "WINDOWS",			arches: ["1809"]],
]

// Required for windows
hubCred = [
    $class: 'UsernamePasswordMultiBinding',
    usernameVariable: 'REGISTRY_USERNAME',
    passwordVariable: 'REGISTRY_PASSWORD',
    credentialsId: 'orcaeng-hub.docker.com',
]

def generatePackageStep(opts, arch) {
    // Different flow because Windows
    if ("${opts.image}" == "WINDOWS") {
        return {
            node("windows-${arch}") {
                stage("${opts.image}-${arch}") {
                  checkout scm
                    try {
                        withCredentials([hubCred]) {
                            sh("docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD")
                            sshagent(['docker-jenkins.github.ssh']) {
                                sh("make -f Makefile.win windows-binaries")
                            }
                        }
                    } finally {
                            sh("make -f Makefile.win clean")
                    }
              }
            }
        }
    }

    return {
        node("linux&&${arch}") {
            stage("${opts.image}-${arch}") {
                checkout scm
                sh("docker pull ${opts.image}")
                sh("make BUILD_IMAGE=${opts.image} CREATE_ARCHIVE=1 clean build")
                archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
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
