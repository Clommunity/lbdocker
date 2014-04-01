# Makefile
DESTDIR ?= devel
ARCH ?= amd64
FLAVOUR ?= amd64
IMAGE ?= iso-hybrid # or iso, hdd, tar or netboot
INSTALL ?= live # or businesscard, netinst, cdrom...
AREAS ?= "main contrib" # non-free

GET_KEY := curl -s 'http://pgp.mit.edu/pks/lookup?op=get&search=0xKEY_ID' | sed -n '/^-----BEGIN/,/^-----END/p'
ARCHDIR := ${DESTDIR}/config/archives
PKGDIR := ${DESTDIR}/config/package-lists
HOOKDIR := ${DESTDIR}/config/hooks
CUSTDIR := ${DESTDIR}/config/custom

NAME := Docker-Clommunity
SPLASH_TITLE := ${NAME}
SPLASH_SUBTITLE := ${ARCH} ${FLAVOUR}
TIMESTAMP := $(shell date -u '+%d %b %Y %R %Z')
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_HASH := $(shell git rev-parse --short=12 HEAD)
MAKEFILEPWD := $(shell pwd)

all: build

describe: packages
	@cat packages

build_environment:
	mkdir -p ${DESTDIR}/auto
	cp res/auto/* ${DESTDIR}/auto/

prepare_configure: build_environment
	echo 'lb config noauto \
		--binary-images ${IMAGE} \
		--architectures ${ARCH} \
		--linux-flavours ${FLAVOUR} \
		--debian-installer ${INSTALL} \
		--archive-areas ${AREAS} \
		--bootappend-live "boot=live config keyboard-layouts=es,es" \
		--apt-indices false \
		"$${@}"' > ${DESTDIR}/auto/config

make_config: prepare_configure
	cd ${DESTDIR} && lb config

add_repos: make_config
	which curl >/dev/null
	mkdir -p ${ARCHDIR}
	# Add Backports Repo
	echo "deb http://ftp.debian.org/debian wheezy-backports ${AREAS}" > ${ARCHDIR}/backports.list.chroot
	# Docker key 
	echo "deb http://get.docker.io/ubuntu docker main" > ${ARCHDIR}/docker.list.chroot
	$(subst KEY_ID,36A1D7869245C8950F966E92D8576A8BA88D21E9, ${GET_KEY}) > ${ARCHDIR}/docker.key.chroot

add_packages: add_repos
	mkdir -p ${PKGDIR}
	while IFS=':	' read name pkgs; do \
		echo $$pkgs > ${PKGDIR}/$$name.list.chroot; \
	done < packages

add_files: make_config
	cp -a includes/chroot/* config/includes.chroot/
	cp -a includes/binary/* config/includes.binary/

hooks: add_packages
	mkdir -p ${HOOKDIR}
	cp hooks/* ${HOOKDIR}/

custom: hooks res/clommunity-docker.png
	mkdir -p ${CUSTDIR}
	convert res/clommunity-docker.png -gravity NorthWest -background black \
		-bordercolor black -border 80x50 -extent 640x480 \
		-fill white -pointsize 28 -gravity NorthWest -annotate +330+55 \
		"${SPLASH_TITLE}\n${SPLASH_SUBTITLE}" \
		-fill white -pointsize 20 -gravity NorthWest -annotate +330+120 \
		"${TIMESTAMP}\n${GIT_BRANCH}@${GIT_HASH}" \
		${CUSTDIR}/splash.png

build: .build

.build: custom
	cd ${DESTDIR} && lb build
	@touch .build

clean:
	cd ${DESTDIR} && lb clean
	# Remove packages...
	@rm -f ${DESTDIR}/config/package-lists/*
	@rm -f .build

.PHONY: all describe build_environment prepare_configure make_config add_repos add_packages hooks custom build clean
