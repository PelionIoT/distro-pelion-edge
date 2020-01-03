At this point, dpkg-buildpackageas is used to build deb package.

It requires that all dependencies be installed on the host machine.

Please install them:

sudo apt install build-essential cmake git    \
		dh-systemd doxygen graphviz libc6-dev \
		libmosquitto-dev mosquitto-clients
