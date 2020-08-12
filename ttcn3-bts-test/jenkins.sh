#!/bin/sh

. ../jenkins-common.sh
IMAGE_SUFFIX="${IMAGE_SUFFIX:-master}"
# NOTE: there is no osmocom-bb-host-latest, hence always use master!
docker_images_require \
	"osmo-bsc-$IMAGE_SUFFIX" \
	"osmo-bts-$IMAGE_SUFFIX" \
	"osmocom-bb-host-master" \
	"ttcn3-bts-test"

ADD_TTCN_RUN_OPTS=""
ADD_TTCN_RUN_CMD=""
ADD_TTCN_VOLUMES=""
BTS_JUST_IDLE=""
ADD_BTS_VOLUMES=""
ADD_BTS_RUN_OPTS=""

if [ "x$1" = "x-h" ]; then
	ADD_TTCN_RUN_OPTS="-ti"
	ADD_TTCN_RUN_CMD="bash"
	if [ -d "$2" ]; then
		ADD_TTCN_VOLUMES="$ADD_TTCN_VOLUMES -v $2:/osmo-ttcn3-hacks"
	fi
	if [ -d "$3" ]; then
		BTS_JUST_IDLE="1"
		ADD_BTS_VOLUMES="$ADD_BTS_VOLUMES -v $3:/src"
		ADD_BTS_RUN_OPTS="--privileged"
	fi
fi

start_bsc() {
	echo Starting container with BSC
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.11 \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/bsc:/data \
			--name ${BUILD_TAG}-bsc -d \
			$DOCKER_ARGS \
			$REPO_USER/osmo-bsc-$IMAGE_SUFFIX \
			/bin/sh -c "osmo-bsc -c /data/osmo-bsc.cfg >>/data/osmo-bsc.log 2>&1"
}

start_bts() {
	local variant
	variant="$1"
	sleep_time_respawn="$2"
	echo Starting container with BTS
	if [ -z "$variant" ]; then
		echo ERROR: You have to specify a BTS variant
		exit 23
	fi
	if [ "$BTS_JUST_IDLE" = 1 ]; then
		# for running tests manually:
		# practically idle forever, but for sanity not really forever
		BTS_RUN_CMD="sleep 9999999"
	else
		# normal command to run unattended tests
		BTS_RUN_CMD="/bin/sh -c \"/usr/local/bin/respawn.sh osmo-bts-$variant -c /data/osmo-bts.cfg -i 172.18.9.10 >>/data/osmo-bts.log 2>&1\""
	fi
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.20 \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/bts:/data \
			-v $VOL_BASE_DIR/unix:/data/unix \
			$ADD_BTS_VOLUMES \
			-e "SLEEP_BEFORE_RESPAWN=$sleep_time_respawn" \
			--name ${BUILD_TAG}-bts -d \
			$DOCKER_ARGS \
			$ADD_BTS_RUN_OPTS \
			$REPO_USER/osmo-bts-$IMAGE_SUFFIX \
			$BTS_RUN_CMD
}

start_fake_trx() {
	echo Starting container with fake_trx
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.21 \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/fake_trx:/data \
			--name ${BUILD_TAG}-fake_trx -d \
			$DOCKER_ARGS \
			$REPO_USER/osmocom-bb-host-master \
			/bin/sh -c "/tmp/osmocom-bb/src/target/trx_toolkit/fake_trx.py \
				--log-file-name /data/fake_trx.log \
				--log-file-level DEBUG \
				--log-file-time \
				--log-level INFO \
				-R 172.18.9.20 -r 172.18.9.22 \
				--trx TRX1@172.18.9.20:5700/1 \
				--trx TRX2@172.18.9.20:5700/2 \
				--trx TRX3@172.18.9.20:5700/3 >>/data/fake_trx.out 2>&1"
}

start_trxcon() {
	echo Starting container with trxcon
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.22 \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/trxcon:/data \
			-v $VOL_BASE_DIR/unix:/data/unix \
			--name ${BUILD_TAG}-trxcon -d \
			$DOCKER_ARGS \
			$REPO_USER/osmocom-bb-host-master \
			/bin/sh -c "trxcon -i 172.18.9.21 -s /data/unix/osmocom_l2 >>/data/trxcon.log 2>&1"
}

start_virtphy() {
	echo Starting container with virtphy
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.22 \
			--ulimit core=-1 \
			-v $VOL_BASE_DIR/virtphy:/data \
			-v $VOL_BASE_DIR/unix:/data/unix \
			--name ${BUILD_TAG}-virtphy -d \
			$DOCKER_ARGS \
			$REPO_USER/osmocom-bb-host-master \
			virtphy -s /data/unix/osmocom_l2
			/bin/sh -c "virtphy -s /data/unix/osmocom_l2 >>/data/virtphy.log 2>&1"
}

start_testsuite() {
	echo Starting container with BTS testsuite
	docker run	--rm \
			--network $NET_NAME --ip 172.18.9.10 \
			--ulimit core=-1 \
			-e "TTCN3_PCAP_PATH=/data" \
			-v $VOL_BASE_DIR/bts-tester:/data \
			-v $VOL_BASE_DIR/unix:/data/unix \
			$ADD_TTCN_VOLUMES \
			--name ${BUILD_TAG}-ttcn3-bts-test \
			$DOCKER_ARGS \
			$ADD_TTCN_RUN_OPTS \
			$REPO_USER/ttcn3-bts-test \
			$ADD_TTCN_RUN_CMD
}

network_create 172.18.9.0/24

mkdir $VOL_BASE_DIR/bts-tester
mkdir $VOL_BASE_DIR/bts-tester/unix
cp BTS_Tests.cfg $VOL_BASE_DIR/bts-tester/

# Work around for a bug in osmo-bts when all transceivers use IPAC_PROTO_RSL_TRX0.
# Enables patching of IPA stream ID. TODO: remove as soon as we make a new release.
if [ "$IMAGE_SUFFIX" = "latest" ]; then
	sed "s/RSL_Emulation.mp_rslem_patch_ipa_cid := false/RSL_Emulation.mp_rslem_patch_ipa_cid := true/g" -i \
		"$VOL_BASE_DIR/bts-tester/BTS_Tests.cfg"
fi

mkdir $VOL_BASE_DIR/bsc
cp osmo-bsc.cfg $VOL_BASE_DIR/bsc/

mkdir $VOL_BASE_DIR/bts
mkdir $VOL_BASE_DIR/bts/unix
cp osmo-bts.cfg $VOL_BASE_DIR/bts/

mkdir $VOL_BASE_DIR/unix

mkdir $VOL_BASE_DIR/fake_trx
mkdir $VOL_BASE_DIR/trxcon
mkdir $VOL_BASE_DIR/virtphy

# 1) classic test suite with BSC for OML and trxcon+fake_trx
start_bsc
start_bts trx 0
start_fake_trx
start_trxcon
start_testsuite

# 2) some GPRS tests require virt_phy
echo "Changing to virtphy configuration"
# switch from osmo-bts-trx + trxcon + faketrx to virtphy + osmo-bts-virtual
docker container kill ${BUILD_TAG}-trxcon
docker container kill ${BUILD_TAG}-fake_trx
docker container kill ${BUILD_TAG}-bts
cp virtphy/osmo-bts.cfg $VOL_BASE_DIR/bts/
start_bts virtual 0
start_virtphy
# ... and execute the testsuite again with different cfg
cp virtphy/BTS_Tests.cfg $VOL_BASE_DIR/bts-tester/
#start_testsuite

# 3) OML tests require us to run without BSC
docker container kill ${BUILD_TAG}-bsc
# switch back from virtphy + osmo-bts-virtual to osmo-bts-trx
docker container kill ${BUILD_TAG}-virtphy
docker container kill ${BUILD_TAG}-bts
cp oml/osmo-bts.cfg $VOL_BASE_DIR/bts/
start_bts trx 1
start_fake_trx
start_trxcon
# ... and execute the testsuite again with different cfg
cp oml/BTS_Tests.cfg $VOL_BASE_DIR/bts-tester/
start_testsuite

# 4) Frequency hopping tests require different configuration files
cp fh/BTS_Tests.cfg $VOL_BASE_DIR/bts-tester/
cp fh/osmo-bsc.cfg $VOL_BASE_DIR/bsc/
cp osmo-bts.cfg $VOL_BASE_DIR/bts/
# restart the BSC/BTS and run the testsuite again
docker container kill ${BUILD_TAG}-bts
start_bsc
start_bts trx 0
start_testsuite
# rename the test results, so they appear as 'BTS_Tests:hopping' in Jenkins
sed -i "s#classname='BTS_Tests'#classname='BTS_Tests:hopping'#g" \
	$VOL_BASE_DIR/bts-tester/junit-xml-hopping-*.log

echo Stopping containers
docker container kill ${BUILD_TAG}-trxcon
docker container kill ${BUILD_TAG}-fake_trx
docker container kill ${BUILD_TAG}-bsc
docker container kill ${BUILD_TAG}-bts


network_remove
rm -rf $VOL_BASE_DIR/unix
collect_logs
