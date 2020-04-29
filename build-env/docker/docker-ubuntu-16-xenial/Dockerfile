FROM ubuntu:16.04

ARG USER_ID
ARG GROUP_ID
ARG LOCAL_SRC_PATH=./docker-ubuntu-16-xenial

RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
RUN usermod -aG sudo user

COPY $LOCAL_SRC_PATH/sources.list.xenial /etc/apt/sources.list

RUN dpkg --add-architecture arm64
RUN dpkg --add-architecture armhf

RUN apt-get update && apt-get install -y --no-install-recommends \
		sudo \
		emacs-nox \
		ssh \
		git \
		vim \
		fakeroot \
		ca-certificates \
		build-essential \
		crossbuild-essential-arm64 \
		crossbuild-essential-armhf

RUN sed -i 's/%sudo	ALL=(ALL:ALL) ALL/%sudo	ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

COPY --chown=user ./common/.bash_aliases /home/user/

USER user
WORKDIR /pelion-build
