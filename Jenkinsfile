#!/groovy

properties(
	[
		parameters(
			[
				string(name: 'CONTAINERD_REPO', defaultValue: 'containerd/containerd', description: 'The repo to build the packages from.'),
				string(name: 'GIT_REF', defaultValue: 'master', description: 'The git ref to build the packages with.'),
				booleanParam(name: 'ARCHIVE', defaultValue: false, description: 'Archive the build artifacts by pushing to an S3 bucket.'),
			]
		)
	]
)

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
		sh("${awscli} s3 cp --only-show-errors '${args.name}' '${destS3Uri}'")
	}
}

parallel([
	"ubuntu-xenial" : { ->
		wrappedNode(label: 'x86_64&&ubuntu', cleanWorkspace: true) {
			checkout scm
			try {
				stage('Build Ubuntu Xenial') {
					if (params.CONTAINERD_REPO != 'containerd/containerd') {
						sh("git clone -b ${params.GIT_REF} --single-branch https://github.com/${params.CONTAINERD_REPO}")
						sh("make CONTAINERD_REPO=containerd RUN_REF=${params.GIT_REF} ubuntu-xenial")
					} else {
						sh("make ubuntu-xenial")
					}
				}
				stage('Verify Containerd Install') {
					sh("make verify-ubuntu-xenial")
				}
				stage('Bundle Ubuntu Xenial') {
					if (params.ARCHIVE) {
						saveS3(name: "build/ubuntu-xenial/containerd_1.1.0-1_amd64.deb", awscli_image: DEFAULT_AWS_IMAGE)
					}
				}
			} finally {
				sh("make clean")
				if (params.CONTAINERD_REPO != 'containerd/containerd') {
					sh("rm -rf containerd")
				}
			}
		}
	},
	"centos" : { ->
		wrappedNode(label: 'x86_64&&ubuntu', cleanWorkspace: true) {
			checkout scm
			try {
				stage('Build Centos') {
					sh("make centos")
				}
				stage('Verify Containerd Install') {
					sh("make verify-rpm-centos")
				}
				stage('Bundle Centos') {
					if (params.ARCHIVE) {
						saveS3(name: "rpm/rpmbuild/RPMS/x86_64/containerd-1.1.0-1.el7.x86_64.rpm", awscli_image: DEFAULT_AWS_IMAGE)
					}
				}
			} finally {
				sh("make clean")
			}
		}
	},
])
