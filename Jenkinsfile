#!groovy

// List of packages to build. Note that this list is overridden in the packaging
// repository, where additional variants may be added for enterprise.
//
// This list is ordered by Distro (alphabetically), and release (chronologically).
// When adding a distro here, also open a pull request in the release repository.
def images = [
    [image: "docker.io/library/amazonlinux:2",          arches: ["aarch64"]],
    [image: "quay.io/centos/centos:stream9",            arches: ["amd64", "aarch64"]],          // CentOS Stream 9 (EOL: 2027)
    [image: "quay.io/centos/centos:stream10",           arches: ["amd64", "aarch64"]],          // CentOS Stream 10 (EOL: 2030)
    [image: "docker.io/library/rockylinux:8",           arches: ["amd64", "aarch64"]],          // Rocky Linux 8 (EOL: 2029-05-31)
    [image: "docker.io/library/rockylinux:9",           arches: ["amd64", "aarch64"]],          // Rocky Linux 9 (EOL: 2032-05-31)
    [image: "docker.io/library/almalinux:8",            arches: ["amd64", "aarch64"]],          // AlmaLinux 8 (EOL: 2029)
    [image: "docker.io/library/almalinux:9",            arches: ["amd64", "aarch64"]],          // AlmaLinux 9 (EOL: 2032)
    [image: "docker.io/library/debian:bullseye",        arches: ["amd64", "aarch64", "armhf"]], // Debian 11 (oldstable, EOL: 2024-08-14, EOL (LTS): 2026-08-31)
    [image: "docker.io/library/debian:bookworm",        arches: ["amd64", "aarch64", "armhf"]], // Debian 12 (stable, EOL: 2026-06-10, EOL (LTS): 2028-06-30)
    [image: "docker.io/library/debian:trixie",          arches: ["amd64", "aarch64", "armhf"]], // Debian 13 (testing)
    [image: "docker.io/library/fedora:40",              arches: ["amd64", "aarch64"]],          // Fedora 40 (EOL: May 13, 2025)
    [image: "docker.io/library/fedora:41",              arches: ["amd64", "aarch64"]],          // Fedora 41 (EOL: November, 2025)
    [image: "docker.io/library/fedora:42",              arches: ["amd64", "aarch64"]],          // Fedora 42 (EOL: May 13, 2026)
    [image: "docker.io/library/fedora:rawhide",         arches: ["amd64", "aarch64"]],          // Rawhide is the name given to the current development version of Fedora
    [image: "docker.io/opensuse/leap:15",               arches: ["amd64"]],
    [image: "docker.io/balenalib/rpi-raspbian:bullseye",arches: ["armhf"]],
    [image: "docker.io/balenalib/rpi-raspbian:bookworm",arches: ["armhf"]],
    [image: "docker.io/library/ubuntu:jammy",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 22.04 LTS (End of support: April, 2027. EOL: April, 2032)
    [image: "docker.io/library/ubuntu:noble",           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 24.04 LTS (End of support: April, 2029. EOL: April, 2034)
    [image: "docker.io/library/ubuntu:oracular",        arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 24.10 (EOL: July, 2025)
    [image: "docker.io/library/ubuntu:plucky",          arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 25.04 (EOL: January, 2026)
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
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    try {
                        checkout scm
                        sh("make -f Makefile.win archive")
                    } finally {
                        deleteDir()
                    }
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
