# Image used to run contrib/jenkins.sh scripts of most Osmocom projects.
# See master-builds.yml, gerrit-verifications.yml in osmo-ci.git.

ARG DEBIAN_VERSION=stretch
FROM debian:${DEBIAN_VERSION}

# Make "$DEBIAN_VERSION" available after FROM
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG DEBIAN_VERSION

# Install apt dependencies (keep in alphabetic order)
RUN \
	dpkg --add-architecture i386 && \
	DEBIAN_FRONTEND=noninteractive apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		asciidoc \
		asciidoc-dblatex \
		autoconf \
		autoconf-archive \
		automake \
		bc \
		bison \
		bzip2 \
		cmake \
		coccinelle \
		cppcheck \
		dahdi-source \
		dblatex \
		dbus \
		debhelper \
		devscripts \
		dh-autoreconf \
		dh-systemd \
		docbook5-xml \
		doxygen \
		flex \
		g++ \
		gawk \
		gcc \
		gcc-arm-none-eabi \
		git \
		git-buildpackage \
		graphviz \
		htop \
		inkscape \
		lcov \
		libaio-dev \
		libasound2-dev \
		libboost-all-dev \
		libc-ares-dev \
		libcsv-dev \
		libdbd-sqlite3 \
		libdbi-dev \
		libffi-dev \
		libfftw3-dev \
		libgmp-dev \
		libgnutls28-dev \
		libgps-dev \
		libgsm1-dev \
		libjansson-dev \
		liblua5.3-dev \
		libmnl-dev \
		libncurses5-dev \
		libnewlib-arm-none-eabi \
		libnl-3-dev \
		libnl-route-3-dev \
		liboping-dev \
		libortp-dev \
		libpcap-dev \
		libpcsclite-dev \
		libreadline-dev \
		libsctp-dev \
		libsigsegv-dev \
		libsnmp-dev \
		libsofia-sip-ua-glib-dev \
		libsqlite3-dev \
		libssl-dev \
		libtalloc-dev \
		libtool \
		libusb-1.0-0-dev \
		libusb-dev \
		libxml2-utils \
		libzmq3-dev \
		locales \
		lua-socket \
		make \
		mscgen \
		ofono \
		openssh-client \
		osc \
		patchelf \
		pkg-config \
		python3 \
		python3-gi \
		python3-mako \
		python3-nwdiag \
		python3-pip \
		python3-pyflakes \
		python3-setuptools \
		python3-usb \
		python3-yaml \
		rsync \
		sdcc \
		sqlite3 \
		source-highlight \
		stow \
		sudo \
		systemd \
		tcpdump \
		texinfo \
		unzip \
		wget \
		xsltproc

# Install pip dependencies (keep in alphabetic order)
RUN pip3 install \
	git+https://github.com/podshumok/python-smpplib.git \
	git+https://github.com/eriwen/lcov-to-cobertura-xml.git \
	pydbus \
	pysispm

# match the outside user
RUN useradd --uid=1000 build
#RUN echo "build ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/build

RUN mkdir /build
RUN chown build:build /build

# Install osmo-python-tests
ADD http://git.osmocom.org/python/osmo-python-tests/patch /tmp/commit
RUN git clone git://git.osmocom.org/python/osmo-python-tests && cd osmo-python-tests && ./contrib/jenkins.sh

# Set a UTF-8 locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# osmo-remsim needs libulfius which is built in osmocom OBS repos:
ARG	OSMOCOM_REPO="http://download.opensuse.org/repositories/network:/osmocom:/nightly/Debian_9.0/"
COPY	Release.key /tmp/Release.key
RUN	apt-key add /tmp/Release.key && \
	rm /tmp/Release.key && \
	echo "deb " $OSMOCOM_REPO " ./" > /etc/apt/sources.list.d/osmocom-nightly.list
ADD	$OSMOCOM_REPO/Release /tmp/Release
RUN	apt-get update && \
	apt-get install -y --no-install-recommends \
		libulfius-dev && \
	apt-get clean

# osmo-python-tests' contrib/jenkins.sh writes to /usr/local as user
RUN chown -R build:build /usr/local
