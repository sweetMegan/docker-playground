#!/bin/sh

. ../jenkins-common.sh
IMAGE_SUFFIX="${IMAGE_SUFFIX:-master}"
docker_images_require \
	"osmo-stp-$IMAGE_SUFFIX" \
	"osmo-bsc-$IMAGE_SUFFIX" \
	"osmo-bts-$IMAGE_SUFFIX" \
	"ttcn3-bsc-test"

ADD_TTCN_RUN_OPTS=""
ADD_TTCN_RUN_CMD=""
ADD_TTCN_VOLUMES=""
ADD_BSC_VOLUMES=""
ADD_BSC_ARGS=""

if [ "x$1" = "x-h" ]; then
	ADD_TTCN_RUN_OPTS="-ti"
	ADD_TTCN_RUN_CMD="bash"
	if [ -d "$2" ]; then
		ADD_TTCN_VOLUMES="$ADD_TTCN_VOLUMES -v $2:/osmo-ttcn3-hacks"
	fi
	if [ -d "$3" ]; then
		ADD_BSC_RUN_CMD="sleep 9999999"
		ADD_BSC_VOLUMES="$ADD_BSC_VOLUMES -v $3:/src"
		#ADD_BSC_RUN_OPTS="--privileged"
	fi
fi

mkdir $VOL_BASE_DIR/bsc-tester
cp BSC_Tests.cfg $VOL_BASE_DIR/bsc-tester/

mkdir $VOL_BASE_DIR/stp
cp osmo-stp.cfg $VOL_BASE_DIR/stp/

mkdir $VOL_BASE_DIR/bsc
cp osmo-bsc.cfg $VOL_BASE_DIR/bsc/

mkdir $VOL_BASE_DIR/bts-omldummy

# Disable MSC pooling features until osmo-bsc.git release > 1.6.0 is available
if [ "$IMAGE_SUFFIX" = "latest" ]; then
	cp pre-mscpool-osmo-bsc.cfg $VOL_BASE_DIR/bsc/osmo-bsc.cfg
fi

network_create 172.18.2.0/24

echo Starting container with STP
docker run	--rm \
		--network $NET_NAME --ip 172.18.2.200 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/stp:/data \
		--name ${BUILD_TAG}-stp -d \
		--ulimit core=-1 \
		$DOCKER_ARGS \
		$REPO_USER/osmo-stp-$IMAGE_SUFFIX

echo Starting container with BSC
docker run	--rm \
		--network $NET_NAME --ip 172.18.2.20 \
		--ulimit core=-1 \
		-v $VOL_BASE_DIR/bsc:/data \
		$ADD_BSC_VOLUMES \
		--name ${BUILD_TAG}-bsc -d \
		$DOCKER_ARGS \
		$ADD_BSC_RUN_OPTS \
		$REPO_USER/osmo-bsc-$IMAGE_SUFFIX \
		$ADD_BSC_RUN_CMD

for i in `seq 0 2`; do
	echo Starting container with OML for BTS$i
	docker run	--rm \
			--network $NET_NAME --ip 172.18.2.10$i \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/bts-omldummy:/data \
			--name ${BUILD_TAG}-bts$i -d \
			$DOCKER_ARGS \
			$REPO_USER/osmo-bts-$IMAGE_SUFFIX \
			/bin/sh -c "/usr/local/bin/respawn.sh osmo-bts-omldummy 172.18.2.20 $((i + 1234)) 1 >>/data/osmo-bts-omldummy-${i}.log 2>&1"
done

echo Starting container with BSC testsuite
docker run	--rm \
		--network $NET_NAME --ip 172.18.2.203 \
		--ulimit core=-1 \
		-e "TTCN3_PCAP_PATH=/data" \
		-v $VOL_BASE_DIR/bsc-tester:/data \
		$ADD_TTCN_VOLUMES \
		--name ${BUILD_TAG}-ttcn3-bsc-test \
		$DOCKER_ARGS \
		$ADD_TTCN_RUN_OPTS \
		$REPO_USER/ttcn3-bsc-test \
		$ADD_TTCN_RUN_CMD

echo Stopping containers
for i in `seq 0 2`; do
	docker container kill ${BUILD_TAG}-bts$i
done
docker container kill ${BUILD_TAG}-bsc
docker container kill ${BUILD_TAG}-stp

network_remove
collect_logs
