SEMVER := env_var_or_default("SEMVER", "0.0.0")

# List available recipes
default:
    @just --list

# Download/refresh GPG signing keys for all repositories (keys are committed to the repo)
download-keys:
    curl -fsSL https://dl.cloudsmith.io/public/thinedge/community/gpg.key \
        | gpg --dearmor \
        > packages/thinedge-community-repo/files/usr/share/keyrings/thinedge-community-archive-keyring.gpg
    curl -fsSL https://dl.cloudsmith.io/public/thinedge/tedge-main/gpg.key \
        | gpg --dearmor \
        > packages/thinedge-tedge-main-repo/files/usr/share/keyrings/thinedge-tedge-main-archive-keyring.gpg
    curl -fsSL https://dl.cloudsmith.io/public/thinedge/tedge-release/gpg.key \
        | gpg --dearmor \
        > packages/thinedge-tedge-release-repo/files/usr/share/keyrings/thinedge-tedge-release-archive-keyring.gpg

# Build all packages
build: _dist build-community build-main build-release

# Build community repo package
build-community: _dist
    cd packages/thinedge-community-repo && SEMVER={{SEMVER}} nfpm package \
        --config nfpm.yaml \
        --target ../../dist/ \
        --packager deb

# Build tedge-main repo package
build-main: _dist
    cd packages/thinedge-tedge-main-repo && SEMVER={{SEMVER}} nfpm package \
        --config nfpm.yaml \
        --target ../../dist/ \
        --packager deb

# Build tedge-release repo package
build-release: _dist
    cd packages/thinedge-tedge-release-repo && SEMVER={{SEMVER}} nfpm package \
        --config nfpm.yaml \
        --target ../../dist/ \
        --packager deb

# Remove build artifacts
clean:
    rm -rf dist/

_dist:
    mkdir -p dist
