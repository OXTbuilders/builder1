#!/bin/sh

set -e

BUILD_USER=%BUILD_USER%
BUILD_DIR=%BUILD_DIR%
IP_C=%IP_C%
SUBNET_PREFIX=%SUBNET_PREFIX%
ALL_BUILDS_SUBDIR_NAME=%ALL_BUILDS_SUBDIR_NAME%
BUILDID=%BUILDID%
BRANCH=%BRANCH%

mkdir $BUILD_DIR
cd $BUILD_DIR

git clone -b $BRANCH git://${SUBNET_PREFIX}.${IP_C}.1/${BUILD_USER}/openxt.git

cd openxt

# Get the latest Windows tools for the branch
mkdir wintools
rsync -r builds@158.69.227.117:/home/builds/win/$BRANCH/ wintools/
WINTOOLS="`pwd`/wintools"
WINTOOLS_ID="`grep -o '[0-9]*' wintools/BUILD_ID`"

cp example-config .config
cat >>.config <<EOF
BRANCH="${BRANCH}"
NAME_SITE="oxt"
OPENXT_MIRROR="http://158.69.227.117/mirror"
OE_TARBALL_MIRROR="http://158.69.227.117/mirror"
OPENXT_GIT_MIRROR="${SUBNET_PREFIX}.${IP_C}.1/${BUILD_USER}"
OPENXT_GIT_PROTOCOL="git"
REPO_PROD_CACERT="/home/build/certs/prod-cacert.pem"
REPO_DEV_CACERT="/home/build/certs/dev-cacert.pem"
REPO_DEV_SIGNING_CERT="/home/build/certs/dev-cacert.pem"
REPO_DEV_SIGNING_KEY="/home/build/certs/dev-cakey.pem"
WIN_BUILD_OUTPUT="$WINTOOLS"
XC_TOOLS_BUILD=$WINTOOLS_ID
SYNC_CACHE_OE=builds@158.69.227.117:/home/builds/oe
NETBOOT_HTTP_URL=http://158.69.227.117/builds
EOF

./do_build.sh -i $BUILDID | tee build.log

# The return value of `do_build.sh` got hidden by `tee`. Bring it back.
ret=${PIPESTATUS[0]}
( exit $ret )

# Build the tools and the extra packages
./do_build.sh -i $BUILDID -s xctools,ship #,extra_pkgs

# TODO: figure out `do_build.sh -s packages_tree`, which probably requires fixing the step first...

# Copy the build output
scp -r build-output/* "${BUILD_USER}@${SUBNET_PREFIX}.${IP_C}.1:${ALL_BUILDS_SUBDIR_NAME}/${BUILD_DIR}/"

# The script may run in an "ssh -t -t" environment, that won't exit on its own
set +e
exit
