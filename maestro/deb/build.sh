#!/bin/sh

package=maestro

url=git@github.com:armPelionEdge/maestro.git
rev=d224292b87dd5d60fae4e24d746875e2c49c802d
rel=0.0

# All code below may potentially be shared between multiple packages.

set -e
cd "${0%/*}"/../..

pkgoar=${package}_${rel}.orig.tar.gz
pkgdar=${package}_${rel}.debian.tar.xz
pkgdsc=${package}_${rel}.dsc
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
