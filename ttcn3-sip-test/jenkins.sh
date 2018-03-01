#!/bin/sh

. ../jenkins-common.sh
IMAGE_SUFFIX="${IMAGE_SUFFIX:-master}"
docker_images_require \
	"osmo-sip-$IMAGE_SUFFIX" \
	"ttcn3-sip-test"

ADD_TTCN_RUN_OPTS=""
ADD_TTCN_RUN_CMD=""
ADD_TTCN_VOLUMES=""
ADD_SIP_VOLUMES=""
ADD_SIP_ARGS=""
SIP_RUN_CMD="/bin/sh -c \"osmo-sip-connector -c /data/osmo-sip-connector.cfg >>/data/osmo-sip-connector.log 2>&1\""

if [ "x$1" = "x-h" ]; then
	ADD_TTCN_RUN_OPTS="-ti"
	ADD_TTCN_RUN_CMD="bash"
	if [ -d "$2" ]; then
		ADD_TTCN_VOLUMES="$ADD_TTCN_VOLUMES -v $2:/osmo-ttcn3-hacks"
	fi
	if [ -d "$3" ]; then
		SIP_RUN_CMD="sleep 9999999"
		ADD_SIP_VOLUMES="$ADD_SIP_VOLUMES -v $3:/src"
		ADD_SIP_RUN_OPTS="--privileged"
	fi
fi


network_create 172.18.11.0/24

mkdir $VOL_BASE_DIR/sip-tester
mkdir $VOL_BASE_DIR/sip-tester/unix
cp SIP_Tests.cfg $VOL_BASE_DIR/sip-tester/

mkdir $VOL_BASE_DIR/sip
mkdir $VOL_BASE_DIR/sip/unix
cp osmo-sip-connector.cfg $VOL_BASE_DIR/sip/

mkdir $VOL_BASE_DIR/unix

echo Starting container with osmo-sip-connector
docker run	--rm \
		--network $NET_NAME --ip 172.18.11.10 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/sip:/data \
		-v $VOL_BASE_DIR/unix:/data/unix \
		$ADD_SIP_VOLUMES \
		--name ${BUILD_TAG}-sip-connector -d \
		$DOCKER_ARGS \
		$ADD_SIP_RUN_OPTS \
		$REPO_USER/osmo-sip-$IMAGE_SUFFIX \
		$SIP_RUN_CMD

echo Starting container with SIP testsuite
docker run	--rm \
		--network $NET_NAME --ip 172.18.11.103 \
		--ulimit core=-1 \
		-e "TTCN3_PCAP_PATH=/data" \
		-v $VOL_BASE_DIR/sip-tester:/data \
		-v $VOL_BASE_DIR/unix:/data/unix \
		$ADD_TTCN_VOLUMES \
		--name ${BUILD_TAG}-ttcn3-sip-test \
		$DOCKER_ARGS \
		$ADD_TTCN_RUN_OPTS \
		$REPO_USER/ttcn3-sip-test \
		$ADD_TTCN_RUN_CMD

echo Stopping containers
docker container kill ${BUILD_TAG}-sip-connector

network_remove
rm -rf $VOL_BASE_DIR/unix
collect_logs
