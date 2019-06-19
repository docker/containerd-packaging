#!groovy

def arches = ["amd64", "armhf", "aarch64"]

def images = [
	// Ubuntu is really the only distribution where we produce everything
	[image: "ubuntu:bionic",              arches: arches],
	[image: "debian:stretch",             arches: arches],
	[image: "resin/rpi-raspbian:stretch", arches: arches - ["amd64", "aarch64"]],
	[image: "centos:7",                   arches: arches - ["armhf"]],
	[image: "fedora:latest",              arches: arches - ["armhf"]],
	[image: "opensuse/leap:15",           arches: arches - ["armhf", "aarch64"]],
]

def generatePackageStep(opts, arch) {
	return {
		node("linux&&${arch}") {
			stage("${opts.image}-${arch}") {
				checkout scm
				sh("docker pull ${opts.image}")
				sh("make BUILD_IMAGE=${opts.image} CREATE_ARCHIVE=1 clean build")
				archiveArtifacts(artifacts: 'archive/*.tar.gz', onlyIfSuccessful: true)
			}
			// TODO: Add upload step here
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
