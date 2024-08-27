#!groovy

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "docker.io/library/amazonlinux:2",          arches: ["aarch64"]],
    [image: "quay.io/centos/centos:stream9",            arches: ["amd64", "aarch64"]],          // CentOS Stream 9 (EOL: 2027)
    [image: "docker.io/library/rockylinux:8",           arches: ["amd64", "aarch64"]],          // Rocky Linux 8 (EOL: 2029-05-31)
    [image: "docker.io/library/rockylinux:9",           arches: ["amd64", "aarch64"]],          // Rocky Linux 9 (EOL: 2032-05-31)
    [image: "docker.io/library/almalinux:8",            arches: ["amd64", "aarch64"]],          // AlmaLinux 8 (EOL: 2029)
    [image: "docker.io/library/almalinux:9",            arches: ["amd64", "aarch64"]],          // AlmaLinux 9 (EOL: 2032)
    [image: "docker.io/library/debian:bullseye",        arches: ["amd64", "aarch64", "armhf"]], // Debian 11 (EOL: 2024)
    [image: "docker.io/library/debian:bookworm",        arches: ["amd64", "aarch64", "armhf"]], // Debian 12 (stable)
    [image: "docker.io/library/fedora:39",              arches: ["amd64", "aarch64"]],          // Fedora 39 (EOL: November 12, 2024)
    [image: "docker.io/library/fedora:40",              arches: ["amd64", "aarch64"]],          // Fedora 40 (EOL: May 13, 2025)
    [image: "docker.io/library/fedora:41",              arches: ["amd64", "aarch64"]],          // Fedora 41 (EOL: November, 2025)
// FIXME(thaJeztah): temporarily disabled; see https://github.com/docker/runtime-team/issues/140 and https://github.com/docker/containerd-packaging/pull/354#issuecomment-2148423969
//     [image: "docker.io/library/fedora:rawhide",         arches: ["amd64", "aarch64"]],          // Rawhide is the name given to the current development version of Fedora
    [image: "docker.io/opensuse/leap:15",               arches: ["amd64"]],
    [image: "docker.io/balenalib/rpi-raspbian:bullseye",arches: ["armhf"]],
    [image: "docker.io/balenalib/rpi-raspbian:bookworm",arches: ["armhf"]],
    [image: "docker.io/library/ubuntu:focal",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
    [image: "docker.io/library/ubuntu:jammy",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 22.04 LTS (End of support: April, 2027. EOL: April, 2032)
    [image: "docker.io/library/ubuntu:noble",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 24.04 LTS (End of support: April, 2029. EOL: April, 2034)
]

def generatePackageStep(opts, arch) {
    return {
        wrappedNode(label: "ubuntu-2004 && ${arch}") {
            stage("${opts.image}-${arch}") {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                sh 'echo starting...'
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
                sh '''
                curl -fsSL "https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh" | bash || true
                '''
            }
            stage("checkout") {
                checkout scm
                sh 'make clean'
            }
            stage("build") {
                sh "make CREATE_ARCHIVE=1 ARCH=${arch} ${opts.image}"
                archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
            }
            stage("build-main") {
                // We're not archiving these builds as they have the same name
                // as the 1.7 builds, so would replace those. We're building
                // the main branch to verify that the scripts work for main (2.0)
                sh "make REF=main ARCH=${arch} ${opts.image}"
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
        node("windows-2022") {
            stage("windows") {
                try {
                    checkout scm
                    sh("make -f Makefile.win archive")
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
            agent { label 'ubuntu-2004 && amd64' }
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
