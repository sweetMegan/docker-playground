FROM debian:stretch

MAINTAINER Harald Welte <laforge@gnumonks.org>

ARG	OSMOCOM_REPO="http://download.opensuse.org/repositories/network:/osmocom:/latest/Debian_9.0/"

COPY	Release.key /tmp/Release.key

RUN	apt-get update && \
	apt-get install -y --no-install-recommends \
		gnupg

RUN	apt-key add /tmp/Release.key && \
	rm /tmp/Release.key && \
	echo "deb " $OSMOCOM_REPO " ./" > /etc/apt/sources.list.d/osmocom-latest.list

ADD	$OSMOCOM_REPO/Release /tmp/Release
RUN	apt-get update && \
	apt-get install -y --no-install-recommends \
		telnet \
		osmo-bsc \
		osmo-bsc-ipaccess-utils && \
	apt-get clean

WORKDIR	/tmp

VOLUME	/data

COPY	osmo-bsc.cfg /data/osmo-bsc.cfg

WORKDIR	/data
CMD	["/bin/sh", "-c", "/usr/bin/osmo-bsc -c /data/osmo-bsc.cfg >/data/osmo-bsc.log 2>&1"]

EXPOSE	3003 3002 4242
