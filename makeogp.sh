#!/usr/bin/env bash
# This script generates an Open Graph image for a given markdown post using tcardgen.
set -euo pipefail

if [ $# != 1 ] || [ $1 = "" ]; then
    echo "One parameters are required"
    echo ""
    echo "string: path to markdown file of target post"
    echo ""
    echo "example command"
    echo "\t$ sh ./makeogp.sh ./content/post/test/test.md"
    exit
fi

TARGET_POST_PATH="$1"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

FONT_DIR="${REPO_ROOT}/assets/fonts/kinto-sans"
OUT_DIR="${REPO_ROOT}/static/img/og"
TEMPLATE="${REPO_ROOT}/static/ogp/ogp_template.png"
CONFIG="${REPO_ROOT}/tcardgen.yaml"

tcardgen \
  --fontDir "${FONT_DIR}" \
  --output "${OUT_DIR}" \
  --template "${TEMPLATE}" \
  --config "${CONFIG}" \
  "${REPO_ROOT}/${TARGET_POST_PATH#./}"
