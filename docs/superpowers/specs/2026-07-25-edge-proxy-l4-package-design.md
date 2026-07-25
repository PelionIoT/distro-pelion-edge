# edge-proxy-l4: a second edge-proxy package for stargate

Date: 2026-07-25
Status: approved

## Problem

`edge-proxy` today serves the KaaS product. The `edge-proxy-l4-proxy-staging`
branch changes it to run as a layer 4 outbound proxy for stargate: upstream
`v1.3.0` -> `v1.5.0`, and a rewritten `launch-edge-proxy.sh` that prefers the
myriplane address, passes `-server-name` for SNI, and adds `-use-l4-proxy`,
`-http-tunnel-listen`, `-proxy-listen` and `-disable-reverse-tunnel`.

Merging that to `master` would change the package KaaS installs. We need both
behaviours available from `master`, selectable at install time, with KaaS
unaffected.

## Approach

Ship a second Debian package, `edge-proxy-l4`, carrying the stargate build.
Leave `edge-proxy` exactly as `master` has it.

This follows the existing variant pattern in this repo: `mbed-edge-core`,
`mbed-edge-core-devmode` and `mbed-edge-core-byocmode` are three separate
source packages that all install `/usr/bin/edge-core` and declare
`Conflicts:`/`Replaces:` on each other.

Both packages own `/usr/bin/edge-proxy`, so they are mutually exclusive by
construction. That is intended: a gateway runs one product or the other.

## Design

### Package identity

New directory `edge-proxy-l4/deb/`, cloned from the staging branch's
`edge-proxy/deb/`. In `debian/control` these fields change or are added:

```
Source: edge-proxy-l4
Package: edge-proxy-l4
Provides: edge-proxy
Conflicts: edge-proxy
Replaces: edge-proxy
```

Every other field is copied unchanged, including `Architecture: any`,
`Multi-Arch: foreign`, the `Build-Depends` on `pe-golang:native`, and
`Depends: ${misc:Depends}, ${shlibs:Depends}, pe-utils`. The `Description`
gains a line naming this as the L4 variant.

`Conflicts`/`Replaces` make the two mutually exclusive. `Provides: edge-proxy`
lets `edge-proxy-l4` satisfy an unversioned `Depends: edge-proxy`, so
`pelion-edge-base` installs on a stargate gateway without being edited. No
metapackage changes.

### The binary keeps its name

No work required. `debian/auto_build` hardcodes the Go import path:

```sh
package=github.com/PelionIoT/edge-proxy
go build -buildmode=pie "$package"/cmd/edge-proxy
```

The executable is named from the last element of the Go package path, not from
the Debian package name, and `debian/install` references
`go-workspace/src/github.com/PelionIoT/edge-proxy/edge-proxy`. Both files are
copied unchanged and `/usr/bin/edge-proxy` results.

### The systemd unit keeps its name

Seven references across six packages name the unit directly, and all would
break if it were renamed:

| Consumer | Reference |
|---|---|
| `edge-resource-manager.service` | `Requires=` / `After=` |
| `pe-terminal.service` | `Requires=` / `After=` |
| `kubelet.service` | `Requires=` / `After=` |
| `k3s.service` | `Requires=` / `After=` |
| `fluent-bit.service` | `Requires=` / `After=` |
| `fluent-bit.conf` | `Systemd_Filter _SYSTEMD_UNIT=edge-proxy.service` |
| `pe-utils/launch-wait-for-pelion-identity.sh` | `systemctl restart edge-proxy` |

debhelper installs `debian/<package>.service` as `<package>.service`, so a file
named `edge-proxy.service` inside a package named `edge-proxy-l4` would be
ignored, and one named `edge-proxy-l4.service` would install a unit nothing
requires. Use debhelper's `<package>.<name>.service` form instead:

```
debian/edge-proxy-l4.edge-proxy.service  ->  /lib/systemd/system/edge-proxy.service
```

### File-by-file

Copied unchanged from staging's `edge-proxy/deb/`:

- `debian/auto_build`, `debian/goflags.guess`, `debian/install`
- `debian/compat`, `debian/copyright`, `debian/source/format`
- `debian/launch-edge-proxy.sh` (the v1.5.0 L4 version)
- `debian/edge-proxy.conf.json`

Changed:

| File | Change |
|---|---|
| `deb/build.sh` | `PELION_PACKAGE_NAME="edge-proxy-l4"`; component stays `v1.5.0` |
| `debian/control` | as above |
| `debian/changelog` | fresh `edge-proxy-l4 (1.5.0-1)` entry, no inherited history |
| `debian/rules` | `dh_installinit -pedge-proxy` -> `-pedge-proxy-l4` |
| `debian/edge-proxy.service` | renamed to `debian/edge-proxy-l4.edge-proxy.service` |
| `debian/fog-proxy.lintian-overrides` | renamed to `debian/edge-proxy-l4.lintian-overrides` |

The `fog-proxy.lintian-overrides` name is dead in the original: debhelper only
applies `<package>.lintian-overrides` and no package is named `fog-proxy`, so
it has never taken effect. The copy is named correctly. The original is left
alone — fixing it is out of scope and would change `edge-proxy`.

### Build registration

Add `edge-proxy-l4` to `PACKAGES` in
`build-env/target/common/debian_packages.conf.sh` so full builds produce it,
and add it to the `package` dropdown in the publish workflow.

`build-env/bin/deb2tar.sh` needs no change: its `/^edge-proxy/d` dependency
filter is a prefix match that already covers `edge-proxy-l4`.

The RPM side (`edge-proxy/rpm/`) is out of scope; only the Debian package is
duplicated.

## What does not change

`edge-proxy/` stays byte-identical to `master`: v1.3.0 and the original launch
script. KaaS is unaffected by construction rather than by testing. No
metapackage is edited.

## Scope of the master PR

Only: the new `edge-proxy-l4` package, the `PACKAGES` entry, the workflow
dropdown option, and the CI workflow file itself. `edge-proxy` is reverted to
master's state. The other commits on `edge-proxy-l4-proxy-staging` (`pe-utils`
bumps and related) are a separate decision and are not carried.

Landing the workflow file on `master` also fixes a second problem: a
`workflow_dispatch` workflow only appears in the Actions tab once it exists on
the default branch, which is `master`.

## Verification

1. `edge-proxy-l4_1.5.0-1_amd64.deb` builds via
   `./build-env/bin/docker-run-env.sh bullseye ./edge-proxy-l4/deb/build.sh --install --arch=amd64`.
2. `dpkg-deb -c` shows `/usr/bin/edge-proxy` and
   `/lib/systemd/system/edge-proxy.service`.
3. `dpkg-deb -f` shows `Provides`, `Conflicts` and `Replaces` on `edge-proxy`.
4. `git diff origin/master -- edge-proxy` is empty.
5. A full build still produces `edge-proxy_1.3.0-1_amd64.deb` alongside it.
6. Installing `edge-proxy-l4` over `edge-proxy` swaps cleanly and leaves the
   dependent units satisfied.
