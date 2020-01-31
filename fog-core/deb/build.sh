#!/bin/sh

package=fog-core

url=git@github.com:armPelionEdge/fog-core.git
rev=5251afa5cfac4de73c25d2d38e9fd799f3f80f91
rel=0.8.0

debrev=1

# All code below may potentially be shared between multiple packages.
# Pay attention to debrev, it's not present in other versions of the
# script.

set -e
cd "${0%/*}"/../..

pkgoar=${package}_${rel}.orig.tar.gz
pkgdar=${package}_${rel}-${debrev}.debian.tar.xz
pkgdsc=${package}_${rel}-${debrev}.dsc
pkgdir=${package}-${rel}

top=`pwd`
srcdir=$top/$package/deb
builddir=$top/build/$package
deploydir=$top/build/deploy/deb
repo=$builddir/repo

if [ ! -d "$srcdir" ]; then
    echo "$package build.sh: unexpected directory structure" >&2
    exit 1
fi

mkdir -p "$builddir"
cd "$builddir"

# Download the code.
if [ ! -d "$repo" ]; then
    git clone "$url" "$repo"
fi

# Create a .orig tarball for dpkg-source.
if [ ! -f "$pkgoar" ]; then
    cd "$repo"
    git checkout "$rev"
    git archive --prefix="$pkgdir/" -o "$builddir/$pkgoar" HEAD
    cd -
fi

# Extract the tarball and generate a debian source package.
if [ ! -d "$pkgdir" ]; then
    tar xf "$pkgoar"
    cp -r "$srcdir/debian" "$pkgdir/debian"
    dpkg-source -b "$pkgdir"
fi

# Build a binary package.
cd "$pkgdir"
debuild -b -us -uc
cd -

mkdir -p "$deploydir"
cp *.deb "$deploydir/"
cp "$pkgoar" "$deploydir/"
cp "$pkgdar" "$deploydir/"
cp "$pkgdsc" "$deploydir/"
