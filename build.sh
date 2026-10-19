#!/usr/bin/env sh
# Build dist/cv.html and dist/cv.pdf from cv.yml.
# Usage: ./build.sh [version]     e.g. ./build.sh v1.2.0
# CI runs this exact script, so a local build matches the release.
set -eu

VERSION="${1:-dev}"
mkdir -p dist
rm -f dist/cv.html dist/cv.pdf

typst compile --font-path fonts --ignore-system-fonts \
  --input version="$VERSION" cv.typ dist/cv.pdf

TYPST_FEATURES=html typst compile --font-path fonts --ignore-system-fonts \
  --input version="$VERSION" cv.typ dist/cv.html 2>&1 \
  | grep -v -e 'html export is under active development' -e '= hint:' >&2 || true
test -s dist/cv.html

echo "Built dist/cv.html and dist/cv.pdf ($VERSION)"
