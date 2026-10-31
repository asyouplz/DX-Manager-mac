#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
output_directory="$repository_root/dist"
version="${DXM_VERSION:-2.2.0}"
rid=""
extra_arguments=("--include-app")

fail() {
    echo "Create-AppBundle: $*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rid|--version|--output-dir|--scrcpy-archive)
            [[ $# -ge 2 ]] || fail "$1 requires a value"
            case "$1" in
                --rid) rid="$2" ;;
                --version) version="$2" ;;
                --output-dir) output_directory="$2" ;;
                --scrcpy-archive) extra_arguments+=("$1" "$2") ;;
            esac
            shift 2
            ;;
        --skip-tests)
            extra_arguments+=("$1")
            shift
            ;;
        -h|--help)
            cat <<'EOF'
Build a verified portable ZIP containing DX Manager.app, then extract the app.
The app has an ad-hoc signature, not Apple Developer ID signing or notarization.
No quarantine attributes or system security settings are changed.

Usage: scripts/Create-AppBundle.sh [--rid osx-arm64|osx-x64] [--version VERSION]
       [--output-dir DIRECTORY] [--scrcpy-archive FILE] [--skip-tests]

Defaults: current Mac architecture, version 2.2.0, repository dist directory.
An existing DX Manager.app is never replaced; select a new output directory.
EOF
            exit 0
            ;;
        *) fail "unknown argument: $1" ;;
    esac
done

[[ "$(uname -s)" == "Darwin" ]] || fail "this script must run on macOS"
if [[ -z "$rid" ]]; then
    case "$(uname -m)" in
        arm64) rid="osx-arm64" ;;
        x86_64) rid="osx-x64" ;;
        *) fail "unsupported Mac architecture" ;;
    esac
fi
case "$rid" in
    osx-arm64) package_arch="arm64" ;;
    osx-x64) package_arch="x64" ;;
    *) fail "unsupported RID: $rid" ;;
esac
[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || fail "invalid version"
output_directory="$(mkdir -p "$output_directory" && cd "$output_directory" && pwd)"
app_destination="$output_directory/DX Manager.app"
[[ ! -e "$app_destination" && ! -L "$app_destination" ]] || fail "app already exists; use a new --output-dir: $app_destination"

"$script_directory/Package-Mac-Release.sh" \
    --rid "$rid" --version "$version" --output-dir "$output_directory" \
    "${extra_arguments[@]}"

archive="$output_directory/DX-Manager-v$version-macos-$package_arch.zip"
(
    cd "$output_directory"
    shasum -a 256 -c "$(basename "$archive").sha256"
)
staging="$(mktemp -d "$output_directory/.dx-manager-app.XXXXXX")"
trap 'rm -rf -- "$staging"' EXIT
ditto -x -k "$archive" "$staging"
staged_app="$staging/DX Manager/DX Manager.app"
codesign --verify --deep --strict "$staged_app"
[[ ! -e "$app_destination" && ! -L "$app_destination" ]] || fail "app destination appeared during packaging; refusing to replace it"
mv "$staged_app" "$app_destination"
echo "App: $app_destination"
echo "Ad-hoc signed; Apple Developer ID and notarization are not present."
echo "Open the app in Finder. If macOS blocks it, review Privacy & Security > Open Anyway."
echo "Bundled components may require separate approval. No phone sessions were run by package smoke tests."
