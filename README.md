# setup-repo-tedge

Linux packages that configure thin-edge.io apt repositories on a device. Installing a package adds the corresponding Cloudsmith repository and GPG signing key, enabling `apt install` of packages from that repository.

## Repositories

| Package | Repository | Purpose |
|---|---|---|
| `thinedge-community-repo` | `thinedge/community` | Community plugins (as-is basis) |
| `thinedge-tedge-main-repo` | `thinedge/tedge-main` | Unstable / nightly builds |
| `thinedge-tedge-release-repo` | `thinedge/tedge-release` | Stable releases |

## Building

### Prerequisites

- [nfpm](https://nfpm.goreleaser.com/install/) — package builder
- [just](https://just.systems/man/en/packages.html) — task runner
- `curl` + `gpg` — for downloading signing keys

### Steps

```sh
# Build all .deb packages into dist/
just build

# Or build a specific package
just build-community
just build-main
just build-release
```

The `SEMVER` environment variable sets the package version (default: `0.0.0`):

```sh
SEMVER=1.2.3 just build
```

Built packages are written to `dist/`.

### Updating GPG keys

The `.gpg` keyring files are committed to the repository (they are public keys). To refresh them if Cloudsmith rotates the key:

```sh
just download-keys
```

Then commit the updated files.

## Releasing

Pushing a tag triggers the [release workflow](.github/workflows/release.yaml), which:

1. Builds packages with the tag as the version
3. Creates a draft GitHub release with the packages attached
4. Publishes to Cloudsmith (requires secrets below)

### Required GitHub secrets

| Secret | Description |
|---|---|
| `PUBLISH_TOKEN` | Cloudsmith API token |
| `PUBLISH_OWNER` | Cloudsmith owner (default: `thinedge`) |
| `PUBLISH_REPO` | Cloudsmith repository name to publish to |

## Project structure

```
packages/
  thinedge-community-repo/
    nfpm.yaml                         # package definition
    files/
      etc/apt/sources.list.d/         # apt source list
      usr/share/keyrings/             # GPG key (gitignored, see above)
  thinedge-tedge-main-repo/
  thinedge-tedge-release-repo/
ci/
  publish.sh                          # Cloudsmith upload script
.github/workflows/
  release.yaml                        # CI/CD release pipeline
justfile                              # build tasks
```
