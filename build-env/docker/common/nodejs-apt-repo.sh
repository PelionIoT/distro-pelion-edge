#!/bin/bash

set -e

NODEJS_VERSION="8.11.4-1nodesource1"
APT_REPO_PATH="/opt/apt-repo"
APT_REPO_NAME="nodejs"

mkdir -p "$APT_REPO_PATH/$APT_REPO_NAME"
cd "$APT_REPO_PATH/$APT_REPO_NAME"

wget https://deb.nodesource.com/node_8.x/pool/main/n/nodejs/nodejs_"$NODEJS_VERSION"_amd64.deb

cd ..
dpkg-scanpackages $APT_REPO_NAME | gzip > $APT_REPO_NAME/Packages.gz

echo "deb [trusted=yes] file://$APT_REPO_PATH $APT_REPO_NAME/" > /etc/apt/sources.list.d/nodejs.list

cat > "/etc/apt/preferences.d/90-nodejs" <<EOF
Package: nodejs
Pin: version $NODEJS_VERSION
Pin-Priority: 900
EOF

