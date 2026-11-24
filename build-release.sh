#!/bin/bash
# Сборка релизов: .deb и tar.gz в каталог dist/.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="kblock"
VERSION="1.0"
DIST="${DIR}/dist"
BUILD="${DIR}/build"
# Замените на свои данные перед публикацией пакета.
MAINTAINER="${MAINTAINER:-egoivint <egoivint@users.noreply.github.com>}"
PKG="${BUILD}/${NAME}_${VERSION}_all"

rm -rf "${BUILD}" "${DIST}"
mkdir -p "${DIST}" \
    "${PKG}/DEBIAN" \
    "${PKG}/usr/bin" \
    "${PKG}/usr/share/applications" \
    "${PKG}/usr/share/icons/hicolor/scalable/apps" \
    "${PKG}/usr/share/doc/${NAME}" \
    "${PKG}/usr/share/kblock"

install -m 755 "${DIR}/kblock" "${PKG}/usr/bin/kblock"
install -m 755 "${DIR}/kblock-gui" "${PKG}/usr/bin/kblock-gui"
install -m 644 "${DIR}/assets/kblock.svg" \
    "${PKG}/usr/share/icons/hicolor/scalable/apps/kblock.svg"
install -m 644 "${DIR}/README.md" "${PKG}/usr/share/doc/${NAME}/README.md"
install -m 644 "${DIR}/README.ru.md" "${PKG}/usr/share/doc/${NAME}/README.ru.md"
install -d "${PKG}/usr/share/doc/${NAME}/assets"
install -m 644 "${DIR}/assets/"screenshot*.png \
    "${PKG}/usr/share/doc/${NAME}/assets/"
install -m 644 "${DIR}/LICENSE" "${PKG}/usr/share/doc/${NAME}/copyright"
install -m 755 "${DIR}/setup-input-access.sh" "${PKG}/usr/share/kblock/"
install -m 755 "${DIR}/remove-input-access.sh" "${PKG}/usr/share/kblock/"

sed 's|^Exec=.*|Exec=/usr/bin/kblock-gui|' "${DIR}/kblock.desktop" \
    > "${PKG}/usr/share/applications/kblock.desktop"
chmod 644 "${PKG}/usr/share/applications/kblock.desktop"

cat > "${PKG}/DEBIAN/control" <<EOF
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-gi, gir1.2-gtk-3.0, libx11-6
Recommends: libnotify-bin
Maintainer: ${MAINTAINER}
Description: Keyboard lock for cleaning the keyboard
 kblock grabs the keyboard (optionally the pointer) for a chosen time,
 so the device can be wiped without accidental input. Uses XGrabKeyboard
 on X11 and EVIOCGRAB on Wayland (needs one-time input access setup).
 Includes a GTK3 tray application with six languages.
EOF

cat > "${PKG}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
exit 0
EOF

cat > "${PKG}/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
exit 0
EOF

chmod 755 "${PKG}/DEBIAN/postinst" "${PKG}/DEBIAN/postrm"
find "${PKG}" -type d -exec chmod 755 {} +

dpkg-deb --root-owner-group --build "${PKG}" \
    "${DIST}/${NAME}_${VERSION}_all.deb"

TAR_DIR="${BUILD}/${NAME}-${VERSION}"
mkdir -p "${TAR_DIR}"
cp -a "${DIR}/kblock" "${DIR}/kblock-gui" "${DIR}/kblock.desktop" \
    "${DIR}/README.md" "${DIR}/README.ru.md" "${DIR}/LICENSE" \
    "${DIR}/install.sh" "${DIR}/uninstall.sh" \
    "${DIR}/setup-input-access.sh" "${DIR}/remove-input-access.sh" \
    "${TAR_DIR}/"
cp -a "${DIR}/assets" "${TAR_DIR}/assets"

tar -C "${BUILD}" -czf "${DIST}/${NAME}-${VERSION}.tar.gz" "${NAME}-${VERSION}"

rm -rf "${BUILD}"
echo "Собрано:"
ls -lh "${DIST}"
