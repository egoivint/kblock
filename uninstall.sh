#!/bin/bash
# Удаление пользовательской установки kblock.
# С --purge удаляет и настройки.
set -euo pipefail

BIN="${HOME}/.local/bin"
APPS="${HOME}/.local/share/applications"
ICONS="${HOME}/.local/share/icons/hicolor/scalable/apps"
SHARE="${HOME}/.local/share/kblock"

rm -f "${BIN}/kblock" "${BIN}/kblock-gui"
rm -f "${APPS}/kblock.desktop"
rm -f "${ICONS}/kblock.svg"
rm -f "${SHARE}/setup-input-access.sh" "${SHARE}/remove-input-access.sh"
rmdir "${SHARE}" 2>/dev/null || true

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q "${APPS}" 2>/dev/null || true
fi

if [ "${1:-}" = "--purge" ]; then
    rm -f "${HOME}/.config/kblock-gui.json"
    echo "Удалены ярлыки, иконка, вспомогательные скрипты и настройки."
else
    echo "Удалены ярлыки, иконка и вспомогательные скрипты."
echo "Настройки остались в ~/.config/kblock-gui.json."
fi
