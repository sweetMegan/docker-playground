#!/bin/sh

. ../jenkins-common.sh
IMAGE_SUFFIX="${IMAGE_SUFFIX:-master}"
docker_images_require \
	"osmo-mgw-$IMAGE_SUFFIX" \
	"ttcn3-mgw-test"

ADD_TTCN_RUN_OPTS=""
ADD_TTCN_RUN_CMD=""
ADD_TTCN_VOLUMES=""
ADD_MGW_VOLUMES=""
ADD_MGW_ARGS=""

if [ "x$1" = "x-h" ]; then
	ADD_TTCN_RUN_OPTS="-ti"
	ADD_TTCN_RUN_CMD="bash"
	if [ -d "$2" ]; then
		ADD_TTCN_VOLUMES="$ADD_TTCN_VOLUMES -v $2:/osmo-ttcn3-hacks"
	fi
	if [ -d "$3" ]; then
		ADD_MGW_RUN_CMD="sleep 9999999"
		ADD_MGW_VOLUMES="$ADD_MGW_VOLUMES -v $3:/src"
		ADD_MGW_RUN_OPTS="--privileged"
	fi
fi

mkdir $VOL_BASE_DIR/mgw-tester
cp MGCP_Test.cfg $VOL_BASE_DIR/mgw-tester/

mkdir $VOL_BASE_DIR/mgw
cp osmo-mgw.cfg $VOL_BASE_DIR/mgw/

network_create 172.18.4.0/24

# start container with mgw in background
docker run	--rm \
		--network $NET_NAME --ip 172.18.4.180 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/mgw:/data \
		$ADD_MGW_VOLUMES \
		--name ${BUILD_TAG}-mgw -d \
		$DOCKER_ARGS \
		$ADD_MGW_RUN_OPTS \
		$REPO_USER/osmo-mgw-$IMAGE_SUFFIX \
		$ADD_MGW_RUN_CMD

# start docker container with testsuite in foreground
docker run	--rm \
		--network $NET_NAME --ip 172.18.4.181 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/mgw-tester:/data \
		$ADD_TTCN_VOLUMES \
		-e "TTCN3_PCAP_PATH=/data" \
		--name ${BUILD_TAG}-ttcn3-mgw-test \
		$DOCKER_ARGS \
		$ADD_TTCN_RUN_OPTS \
		$REPO_USER/ttcn3-mgw-test \
		$ADD_TTCN_RUN_CMD

# stop mgw after test has completed
docker container stop ${BUILD_TAG}-mgw

network_remove
collect_logs
