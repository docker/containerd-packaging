#!/groovy

properties(
	[
		parameters(
			[
				booleanParam(name: 'ARCHIVE', defaultValue: false, description: 'Archive the build artifacts by pushing to an S3 bucket.'),
				string(name: 'CONTAINERD_REF', defaultValue: 'master', description: 'Git ref of containerd repo to build.'),
			]
		)
	]
)

hubCred = [
	$class: 'UsernamePasswordMultiBinding',
	usernameVariable: 'REGISTRY_USERNAME',
	passwordVariable: 'REGISTRY_PASSWORD',
	credentialsId: 'orcaeng-hub.docker.com',
]

DEFAULT_AWS_IMAGE = "anigeo/awscli@sha256:f4685e66230dcb77c81dc590140aee61e727936cf47e8f4f19a427fc851844a1"

def saveS3(def Map args=[:]) {
	def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/"
	def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
	withCredentials([[
		$class: 'AmazonWebServicesCredentialsBinding',
		accessKeyVariable: 'AWS_ACCESS_KEY_ID',
		secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
		credentialsId: 'ci@docker-qa.aws'
	]]) {
		sh("${awscli} s3 cp --only-show-errors ${args.name} '${destS3Uri}'")
	}
}

def genDEBBuild(String arch, String cmd) {
	return [ "${cmd}-${arch}": { ->
			wrappedNode(label:"linux&&${arch}", cleanWorkspace: true) {
				checkout scm
				try {
					stage("Build DEB ${arch}") {
						sh("make REF=${params.CONTAINERD_REF} ${cmd}")
					}
					stage("Archive DEB ${arch}") {
						if (params.ARCHIVE) {
							print('Pushing deb file to S3 bucket.')
							saveS3(name: "build/DEB/*.deb", awscli_image: DEFAULT_AWS_IMAGE)
						} else {
							print('Skipping archiving of deb.')
						}
					}
				} finally {
					sh("make clean")
				}
			}
		}
	]
}

def genRPMBuild(String arch, String cmd) {
	return [ "${cmd}-${arch}": { ->
			wrappedNode(label:"linux&&${arch}", cleanWorkspace: true) {
				checkout scm
				try {
					stage("Build RPM for ${arch}") {
						sh("make REF=${params.CONTAINERD_REF} ${cmd}")
					}
					stage("Archive RPM for ${arch}") {
						if (params.ARCHIVE) {
							print('Pushing rpm file to S3 bucket.')
							saveS3(name: "build/RPMS/${arch}/*.rpm", awscli_image: DEFAULT_AWS_IMAGE)
						} else {
							print('Skipping archiving of rpm.')
						}
					}
				} finally {
					sh("make clean")
				}
			}
		}
	]
}

def windowsBuild() {
	return ["WINDOWS":{ ->
			node('windows-1803') {
				checkout scm
				try {
					withCredentials([hubCred]) {
						bat("docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD")
						stage('Build Binaries') {
							sshagent(['docker-jenkins.github.ssh']) {
								bat("make windows-binaries")
							}
						}
					}
				} finally {
					bat("make clean")
				}
			}
		}
	]
}

arches = [
	"x86_64",
	//"s390x",
	"ppc64le",
	"aarch64",
	"armhf",
]

rpms = [
	"fedora-27",
	"fedora-28",
	"centos-7",
	"centos-7.fips",
	"sles",
	"sles.fips"
]

debs = [
	"deb",
	"deb.fips"
]

packageLookup = [
	"fedora-27": arches - ["s390x"],
	"fedora-28": arches - ["s390x"],
	"centos-7": arches - ["x86_64"],
	"centos-7.fips": ["x86_64"],
	"sles": arches - ["x86_64", "aarch64", "armhf"],
	"sles.fips": ["x86_64"],
	"deb" : arches - ["x86_64"],
	"deb.fips": ["x86_64"],
]

buildSteps = [:]
for (rpm in rpms) {
	arches = packageLookup[rpm]
	for (arch in arches) {
		buildSteps << genRPMBuild(arch, rpm)
	}
}

for (deb in debs) {
	arches = packageLookup[deb]
	for (arch in arches) {
		buildSteps << genDEBBuild(arch, deb)
	}
}

buildSteps << windowsBuild()
parallel(buildSteps)
