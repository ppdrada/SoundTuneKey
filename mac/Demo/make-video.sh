#!/bin/zsh
# Gera o vídeo de demonstração do README (docs/demo/) com as telas de verdade do app.
# Uso: mac/Demo/make-video.sh
set -euo pipefail
mac="${0:A:h:h}"
build=$(mktemp -d)
sources=(${(f)"$(ls "$mac"/Sources/SoundTuneKey/*.swift | grep -v -E '/(main|AppDelegate)\.swift$')"})
swiftc -O -parse-as-library -swift-version 5 -target arm64-apple-macosx14.2 "${sources[@]}" "$mac/Demo/make-video.swift" -o "$build/make-video"
mkdir -p "$mac/../docs/demo"
for lang in pt en; do
    "$build/make-video" "${mac:h}" $lang
    echo "Pronto: docs/demo/demo-$lang.mp4 e .gif"
done
rm -rf "$build"
