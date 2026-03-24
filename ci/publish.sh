#!/bin/bash
# -----------------------------------------------
# Publish packages to Cloudsmith.io
# -----------------------------------------------
set -e

help() {
    cat <<EOF
Publish packages from a path to a Cloudsmith repository.

All necessary dependencies will be downloaded automatically if they are not
already present.

Usage:
    $0 [flags] [path]

Flags:
    --token <string>    Cloudsmith API token used to authenticate
    --owner <string>    Cloudsmith repository owner (default: thinedge)
    --repo <string>     Name of the Cloudsmith repository to publish to
    --path <string>     Path to search for packages (default: ./)
    --help|-h           Show this help

Environment variables (alternative to flags):
    PUBLISH_TOKEN       Equivalent to --token
    PUBLISH_OWNER       Equivalent to --owner
    PUBLISH_REPO        Equivalent to --repo

Examples:
    $0 --token "mytoken" --repo "community" --path ./dist

    Publish all debian/alpine/rpm packages found under ./dist
EOF
}

PUBLISH_TOKEN="${PUBLISH_TOKEN:-}"
PUBLISH_OWNER="${PUBLISH_OWNER:-thinedge}"
PUBLISH_REPO="${PUBLISH_REPO:-community}"
SOURCE_PATH="./"

#
# Argument parsing
#
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --owner)
            PUBLISH_OWNER="$2"
            shift
            ;;
        --token)
            PUBLISH_TOKEN="$2"
            shift
            ;;
        --path)
            SOURCE_PATH="$2"
            shift
            ;;
        --repo)
            PUBLISH_REPO="$2"
            shift
            ;;
        --help|-h)
            help
            exit 0
            ;;
        -*)
            echo "Unrecognized flag: $1" >&2
            help
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            ;;
    esac
    shift
done
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

# Remaining positional arg is an optional path override
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    SOURCE_PATH="${POSITIONAL[0]}"
fi

if [[ -z "$PUBLISH_TOKEN" ]]; then
    echo "Error: --token or PUBLISH_TOKEN is required" >&2
    help
    exit 1
fi

# Add local tools path
LOCAL_TOOLS_PATH="$HOME/.local/bin"
export PATH="$LOCAL_TOOLS_PATH:$PATH"

# Install cloudsmith CLI if missing
if ! command -v cloudsmith &>/dev/null; then
    echo "Installing cloudsmith CLI..." >&2
    if command -v pip3 &>/dev/null; then
        pip3 install --upgrade cloudsmith-cli
    elif command -v pip &>/dev/null; then
        pip install --upgrade cloudsmith-cli
    else
        echo "Error: could not install cloudsmith CLI (pip3/pip not found)" >&2
        exit 2
    fi
fi

publish() {
    local sourcedir="$1"
    local pattern="$2"
    local package_type="$3"
    local distribution="$4"
    local distribution_version="$5"

    find "$sourcedir" -name "$pattern" -print0 | while read -r -d $'\0' file; do
        echo "Publishing $file to ${PUBLISH_OWNER}/${PUBLISH_REPO} (${package_type}/${distribution}/${distribution_version})..." >&2
        cloudsmith upload "$package_type" \
            "${PUBLISH_OWNER}/${PUBLISH_REPO}/${distribution}/${distribution_version}" \
            "$file" \
            --no-wait-for-sync \
            --api-key "${PUBLISH_TOKEN}"
    done
}

publish "$SOURCE_PATH" "*.deb" deb "any-distro" "any-version"
publish "$SOURCE_PATH" "*.rpm" rpm "any-distro" "any-version"
publish "$SOURCE_PATH" "*.apk" alpine "alpine" "any-version"
