#!/bin/sh

. ../jenkins-common.sh
IMAGE_SUFFIX="${IMAGE_SUFFIX:-master}"
docker_images_require \
	"osmo-hlr-$IMAGE_SUFFIX" \
	"ttcn3-hlr-test"

ADD_TTCN_RUN_OPTS=""
ADD_TTCN_RUN_CMD=""
ADD_TTCN_VOLUMES=""
ADD_HLR_VOLUMES=""
ADD_HLR_RUN_OPTS=""
HLR_RUN_CMD="osmo-hlr -c /data/osmo-hlr.cfg"

if [ "x$1" = "x-h" ]; then
	ADD_TTCN_RUN_OPTS="-ti"
	ADD_TTCN_RUN_CMD="bash"
	if [ -d "$2" ]; then
		ADD_TTCN_VOLUMES="$ADD_TTCN_VOLUMES -v $2:/osmo-ttcn3-hacks"
	fi
	if [ -d "$3" ]; then
		ADD_HLR_VOLUMES="$ADD_HLR_VOLUMES -v $3:/src"
		HLR_RUN_CMD="sleep 9999999"
		ADD_HLR_RUN_OPTS="--privileged"
	fi
fi

network_create 172.18.10.0/24

mkdir $VOL_BASE_DIR/hlr-tester
cp HLR_Tests.cfg $VOL_BASE_DIR/hlr-tester/

# Disable D-GSM tests until osmo-hlr.git release > 1.2.0 is available
if [ "$IMAGE_SUFFIX" = "latest" ]; then
	sed "s/HLR_Tests.mp_hlr_supports_dgsm := true/HLR_Tests.mp_hlr_supports_dgsm := false/g" -i \
		"$VOL_BASE_DIR/hlr-tester/HLR_Tests.cfg"
fi

mkdir $VOL_BASE_DIR/hlr
cp osmo-hlr.cfg $VOL_BASE_DIR/hlr/

echo Starting container with HLR
docker run	--rm \
		--network $NET_NAME --ip 172.18.10.20 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/hlr:/data \
		$ADD_HLR_VOLUMES \
		--name ${BUILD_TAG}-hlr -d \
		$DOCKER_ARGS \
		$ADD_HLR_RUN_OPTS \
		$REPO_USER/osmo-hlr-$IMAGE_SUFFIX \
		$HLR_RUN_CMD

echo Starting container with HLR testsuite
docker run	--rm \
		--network $NET_NAME --ip 172.18.10.103 \
		--ulimit core=-1 \
		-e "TTCN3_PCAP_PATH=/data" \
		-v $VOL_BASE_DIR/hlr-tester:/data \
		$ADD_TTCN_VOLUMES \
		--name ${BUILD_TAG}-ttcn3-hlr-test \
		$DOCKER_ARGS \
		$ADD_TTCN_RUN_OPTS \
		$REPO_USER/ttcn3-hlr-test \
		$ADD_TTCN_RUN_CMD

echo Stopping containers
docker container kill ${BUILD_TAG}-hlr

network_remove
collect_logs
