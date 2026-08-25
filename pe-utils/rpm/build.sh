#!/bin/bash

# The previous override ran `npm install` in the source tree before packaging.
# It cannot work and is not needed: the pe-utils repo has no package.json at the
# packaged tag, and the spec installs only shell scripts, a data directory and a
# systemd unit - no Node artifacts are packaged. Dropping it also removes the
# reason for the spec's old BuildRequires on the nonexistent pe-nodejs package.
#
# The default conjure_sources from rpm-common.sh is used instead.

. "${0%/*}"/../../build-env/inc/rpm-common.sh
