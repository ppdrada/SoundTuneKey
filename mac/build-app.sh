#!/bin/zsh
# Compila e monta build/SoundTuneKey.app (não precisa do Xcode completo).
# O app sai "universal": roda em Macs com chip Apple e com Intel.
# Uso: ./build-app.sh        monta o app
#      ./build-app.sh zip    monta o app e gera ../download/SoundTuneKey-mac.zip
set -euo pipefail
cd "${0:A:h}"

# Sem o Xcode completo o SwiftPM não compila as duas arquiteturas juntas,
# então compila uma de cada vez e junta com o lipo.
binaries=()
for arch in arm64 x86_64; do
    triple=$arch-apple-macosx14.2
    swift build -c release --triple $triple
    binaries+=("$(swift build -c release --triple $triple --show-bin-path)/SoundTuneKey")
done

app=build/SoundTuneKey.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
lipo -create "${binaries[@]}" -output "$app/Contents/MacOS/SoundTuneKey"
cp Resources/Info.plist "$app/Contents/"

# Ícone do app a partir do ícone do projeto (assets/icon/icon.png, 512 px).
iconset=build/AppIcon.iconset
rm -rf "$iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z $size $size ../assets/icon/icon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    if (( size * 2 <= 512 )); then
        sips -z $((size * 2)) $((size * 2)) ../assets/icon/icon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
    fi
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$iconset"

# Assinatura local ("ad-hoc"), gratuita: só para o macOS aceitar rodar o app.
codesign --force --sign - "$app"

echo "Pronto: mac/$app"

if [[ ${1:-} == zip ]]; then
    zip=../download/SoundTuneKey-mac.zip
    rm -f "$zip"
    ditto -c -k --keepParent "$app" "$zip"
    echo "Pronto: download/SoundTuneKey-mac.zip"
fi
