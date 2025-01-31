#!/bin/bash
#
# Copyright (c) 2018-2019 Wind River Systems, Inc.
#
# SPDX-License-Identifier: Apache-2.0
#
# This utility builds the StarlingX base image
#

MY_SCRIPT_DIR=$(dirname $(readlink -f $0))

source ${MY_SCRIPT_DIR}/../build-wheels/utils.sh

# Required env vars
if [ -z "${MY_WORKSPACE}" -o -z "${MY_REPO}" ]; then
    echo "Environment not setup for builds" >&2
    exit 1
fi

SUPPORTED_OS_ARGS=('centos')
OS=centos
OS_VERSION=7.5.1804
BUILD_STREAM=stable
IMAGE_VERSION=
PUSH=no
PROXY=""
DOCKER_USER=${USER}
DOCKER_REGISTRY=
declare -a REPO_LIST
REPO_OPTS=
LOCAL=no
CLEAN=no
TAG_LATEST=no
LATEST_TAG=latest
HOST=${HOSTNAME}
declare -i MAX_ATTEMPTS=1

function usage {
    cat >&2 <<EOF
Usage:
$(basename $0)

Options:
    --os:         Specify base OS (valid options: ${SUPPORTED_OS_ARGS[@]})
    --os-version: Specify OS version
    --version:    Specify version for output image
    --stream:     Build stream, stable or dev (default: stable)
    --repo:       Software repository (Format: name,baseurl), can be specified multiple times
    --local:      Use local build for software repository (cannot be used with --repo)
    --push:       Push to docker repo
    --proxy:      Set proxy <URL>:<PORT>
    --latest:     Add a 'latest' tag when pushing
    --latest-tag: Use the provided tag when pushing latest.
    --user:       Docker repo userid
    --registry:   Docker registry
    --clean:      Remove image(s) from local registry
    --hostname:   build repo host
    --attempts:   Max attempts, in case of failure (default: 1)

EOF
}

OPTS=$(getopt -o h -l help,os:,os-version:,version:,stream:,release:,repo:,push,proxy:,latest,latest-tag:,user:,registry:,local,clean,hostname:,attempts: -- "$@")
if [ $? -ne 0 ]; then
    usage
    exit 1
fi

eval set -- "${OPTS}"

while true; do
    case $1 in
        --)
            # End of getopt arguments
            shift
            break
            ;;
        --os)
            OS=$2
            shift 2
            ;;
        --os-version)
            OS_VERSION=$2
            shift 2
            ;;
        --version)
            IMAGE_VERSION=$2
            shift 2
            ;;
        --stream)
            BUILD_STREAM=$2
            shift 2
            ;;
        --release) # Temporarily keep --release support as an alias for --stream
            BUILD_STREAM=$2
            shift 2
            ;;
        --repo)
            REPO_LIST+=($2)
            shift 2
            ;;
        --local)
            LOCAL=yes
            shift
            ;;
        --push)
            PUSH=yes
            shift
            ;;
        --proxy)
            PROXY=$2
            shift 2
            ;;
        --latest)
            TAG_LATEST=yes
            shift
            ;;
        --latest-tag)
            LATEST_TAG=$2
            shift 2
            ;;
        --user)
            DOCKER_USER=$2
            shift 2
            ;;
        --registry)
            # Add a trailing / if needed
            DOCKER_REGISTRY="${2%/}/"
            shift 2
            ;;
        --clean)
            CLEAN=yes
            shift
            ;;
        --hostname)
            HOST=$2
            shift 2
            ;;
        --attempts)
            MAX_ATTEMPTS=$2
            shift 2
            ;;
        -h | --help )
            usage
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Validate the OS option
VALID_OS=1
for supported_os in ${SUPPORTED_OS_ARGS[@]}; do
    if [ "$OS" = "${supported_os}" ]; then
        VALID_OS=0
        break
    fi
done
if [ ${VALID_OS} -ne 0 ]; then
    echo "Unsupported OS specified: ${OS}" >&2
    echo "Supported OS options: ${SUPPORTED_OS_ARGS[@]}" >&2
    exit 1
fi

if [ -z "${IMAGE_VERSION}" ]; then
    IMAGE_VERSION=${OS_VERSION}
fi

if [ ${#REPO_LIST[@]} -eq 0 ]; then
    # Either --repo or --local must be specified
    if [ "${LOCAL}" = "yes" ]; then
        REPO_LIST+=("local-std,http://${HOST}:8088${MY_WORKSPACE}/std/rpmbuild/RPMS")
        REPO_LIST+=("stx-distro,http://${HOST}:8088${MY_REPO}/cgcs-${OS}-repo/Binary")
    elif [ "${BUILD_STREAM}" != "dev" -a "${BUILD_STREAM}" != "master" ]; then
        echo "Either --local or --repo must be specified" >&2
        exit 1
    fi
else
    if [ "${LOCAL}" = "yes" ]; then
        echo "Cannot specify both --local and --repo" >&2
        exit 1
    fi
fi

BUILDDIR=${MY_WORKSPACE}/std/build-images/stx-${OS}
if [ -d ${BUILDDIR} ]; then
    # Leftover from previous build
    rm -rf ${BUILDDIR}
fi

mkdir -p ${BUILDDIR}
if [ $? -ne 0 ]; then
    echo "Failed to create ${BUILDDIR}" >&2
    exit 1
fi

# Get the Dockerfile
echo "1. Get the Dockerfile"
SRC_DOCKERFILE=${MY_SCRIPT_DIR}/stx-${OS}/Dockerfile.${BUILD_STREAM}
cp ${SRC_DOCKERFILE} ${BUILDDIR}/Dockerfile

# Generate the stx.repo file
echo "2. Generate the stx.repo file"
STX_REPO_FILE=${BUILDDIR}/stx.repo
for repo in ${REPO_LIST[@]}; do
    repo_name=$(echo $repo | awk -F, '{print $1}')
    repo_baseurl=$(echo $repo | awk -F, '{print $2}')

    echo ${repo_name}
    echo ${repo_baseurl}

    if [ -z "${repo_name}" -o -z "${repo_baseurl}" ]; then
        echo "Invalid repo specified: ${repo}" >&2
        echo "Expected format: name,baseurl" >&2
        exit 1
    fi

    cat >>${STX_REPO_FILE} <<EOF
[${repo_name}]
name=${repo_name}
baseurl=${repo_baseurl}
enabled=1
gpgcheck=0
skip_if_unavailable=1
metadata_expire=0

EOF

    REPO_OPTS="${REPO_OPTS} --enablerepo=${repo_name}"
done

# Check to see if the OS image is already pulled
echo "3. Check to see if the OS image is already pulled"
docker images --format '{{.Repository}}:{{.Tag}}' ${OS}:${OS_VERSION} | grep -q "^${OS}:${OS_VERSION}$"
BASE_IMAGE_PRESENT=$?
echo ${OS} 
echo ${OS_VERSION}
echo ${BASE_IMAGE_PREST}

# Pull the image anyway, to ensure it is up to date
echo "4. Pull the image anyway, to ensure it is up to date"
docker pull ${OS}:${OS_VERSION}

# Build the image
echo "5. Build the image"
IMAGE_NAME=${DOCKER_REGISTRY}${DOCKER_USER}/stx-${OS}:${IMAGE_VERSION}
IMAGE_NAME_LATEST=${DOCKER_REGISTRY}${DOCKER_USER}/stx-${OS}:${LATEST_TAG}

declare -a BUILD_ARGS
BUILD_ARGS+=(--build-arg RELEASE=${OS_VERSION})
BUILD_ARGS+=(--build-arg REPO_OPTS=${REPO_OPTS})

# Add proxy to docker build
if [ ! -z "$PROXY" ]; then
    BUILD_ARGS+=(--build-arg http_proxy=$PROXY)
fi
BUILD_ARGS+=(--tag ${IMAGE_NAME} ${BUILDDIR})

#chant no cache
BUILD_ARGS+=(--no-cache)

# Build base image
echo "6. Build base image"
echo ${BUILD_ARGS[@]}
with_retries ${MAX_ATTEMPTS} docker build "${BUILD_ARGS[@]}"
if [ $? -ne 0 ]; then
    echo "Failed running docker build command" >&2
    exit 1
fi

if [ "${PUSH}" = "yes" ]; then
    # Push the image
    echo "Pushing image: ${IMAGE_NAME}"
    docker push ${IMAGE_NAME}
    if [ $? -ne 0 ]; then
        echo "Failed running docker push command" >&2
        exit 1
    fi

    if [ "$TAG_LATEST" = "yes" ]; then
        docker tag ${IMAGE_NAME} ${IMAGE_NAME_LATEST}
        echo "Pushing image: ${IMAGE_NAME_LATEST}"
        docker push ${IMAGE_NAME_LATEST}
        if [ $? -ne 0 ]; then
            echo "Failed running docker push command on latest" >&2
            exit 1
        fi
    fi
fi

echo "7. Clean or not"
if [ "${CLEAN}" = "yes" ]; then
    # Delete the images
    echo "Deleting image: ${IMAGE_NAME}"
    docker image rm ${IMAGE_NAME}
    if [ $? -ne 0 ]; then
        echo "Failed running docker image rm command" >&2
        exit 1
    fi

    if [ "$TAG_LATEST" = "yes" ]; then
        echo "Deleting image: ${IMAGE_NAME_LATEST}"
        docker image rm ${IMAGE_NAME_LATEST}
        if [ $? -ne 0 ]; then
            echo "Failed running docker image rm command" >&2
            exit 1
        fi
    fi

    if [ ${BASE_IMAGE_PRESENT} -ne 0 ]; then
        # The base image was not already present, so delete it
        echo "Removing docker image ${OS}:${OS_VERSION}"
        docker image rm ${OS}:${OS_VERSION}
        if [ $? -ne 0 ]; then
            echo "Failed to delete base image from docker" >&2
        fi
    fi
fi

