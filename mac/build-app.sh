#!/bin/zsh
# Compila e monta build/SoundTuneKey.app (não precisa do Xcode completo).
# Uso: ./build-app.sh          (release)
#      ./build-app.sh debug
set -euo pipefail
cd "${0:A:h}"

config=${1:-release}
swift build -c "$config"

app=build/SoundTuneKey.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c "$config" --show-bin-path)/SoundTuneKey" "$app/Contents/MacOS/"
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

# Assinatura local ("ad-hoc"), gratuita: só para o macOS aceitar rodar o app neste Mac.
codesign --force --sign - "$app"

echo "Pronto: mac/$app"
