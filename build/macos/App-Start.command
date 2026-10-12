#!/bin/bash

set -u

resource_directory="$(cd "$(dirname "$0")" && pwd)"
app_directory="$(cd "$resource_directory/../.." && pwd)"
application_directory="$(cd "$resource_directory/../MacOS" && pwd)"
application="$application_directory/DXManager.Mac"

cd "$application_directory" || exit 1
export PATH="$application_directory/tools/scrcpy:/usr/bin:/bin:/usr/sbin:/sbin"

if ! /usr/bin/codesign --verify --deep --strict "$app_directory"; then
    echo "The app's integrity check failed. Download the complete package again."
    echo "앱 무결성 검사에 실패했습니다. 전체 패키지를 다시 내려받으십시오."
    [[ ! -t 0 ]] || read -r -p "Press Return / Return 키를 누르십시오. "
    exit 1
fi

"$application" "$@"
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    echo
    echo "DX Manager exited with status $exit_code."
    echo "If macOS blocked a component, review System Settings > Privacy & Security > Open Anyway."
    echo "macOS가 구성요소를 차단한 경우 시스템 설정 > 개인정보 보호 및 보안 > 그래도 열기를 확인하십시오."
    [[ ! -t 0 ]] || read -r -p "Press Return / Return 키를 누르십시오. "
fi

exit "$exit_code"
