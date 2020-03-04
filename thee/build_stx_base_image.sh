OS=centos
BUILD_STREAM=stable
BRANCH=master
IMAGE_VERSION=${BRANCH}-${BUILD_STREAM}-${USER}
LATEST=${BRANCH}-${BUILD_STREAM}-latest
DOCKER_USER=${USER}
DOCKER_REGISTRY=172.16.206.38:5000 # Some private registry you've setup for your testing, for example
export MY_REPO=designer/chant/starlingx/cgcs-root/
export MY_WORKSPACE=loadbuild/chant/starlingx/
time workspace/localdisk/$MY_REPO/build-tools/build-docker-images/build-stx-base.sh \
    --os ${OS} \
    --stream ${BUILD_STREAM} \
    --version ${IMAGE_VERSION} \
    --user ${DOCKER_USER} --registry ${DOCKER_REGISTRY} \
    --push \
    --latest-tag ${LATEST} \
    --repo local-stx-build,http://172.16.206.38:8088/${MY_WORKSPACE}/std/rpmbuild/RPMS \
    --repo stx-distro,http://172.16.206.38:8088/${MY_REPO}/cgcs-${OS}-repo/Binary
#    --clean

