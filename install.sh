#!/bin/bash
# Установка kblock для текущего пользователя (без root).
# Создаёт симлинки в ~/.local и ярлык в меню приложений.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
APPS="${HOME}/.local/share/applications"
ICONS="${HOME}/.local/share/icons/hicolor/scalable/apps"
SHARE="${HOME}/.local/share/kblock"

echo "Установка kblock из ${DIR}"

mkdir -p "${BIN}" "${APPS}" "${ICONS}" "${SHARE}"
chmod +x "${DIR}/kblock" "${DIR}/kblock-gui"
install -m 755 "${DIR}/setup-input-access.sh" "${SHARE}/setup-input-access.sh"
install -m 755 "${DIR}/remove-input-access.sh" "${SHARE}/remove-input-access.sh"

if ! python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk  # noqa: F401
PY
then
    echo "Внимание: не найдены python3-gi / gir1.2-gtk-3.0." >&2
    echo "Установите: sudo apt install python3-gi gir1.2-gtk-3.0" >&2
    echo "CLI kblock при этом всё равно будет установлен." >&2
fi

ln -sfn "${DIR}/kblock" "${BIN}/kblock"
ln -sfn "${DIR}/kblock-gui" "${BIN}/kblock-gui"

# Ярлык генерируем с абсолютным путём: он работает, даже если ~/.local/bin не в PATH.
python3 - "$DIR" "${APPS}/kblock.desktop" <<'PY'
import sys
from pathlib import Path

src, dst = Path(sys.argv[1], "kblock.desktop"), Path(sys.argv[2])
lines = []
for line in src.read_text(encoding="utf-8").splitlines():
    if line.startswith("Exec="):
        line = f"Exec={sys.argv[1]}/kblock-gui"
    elif line.startswith("TryExec="):
        line = f"TryExec={sys.argv[1]}/kblock-gui"
    lines.append(line)
dst.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
chmod 644 "${APPS}/kblock.desktop"

ln -sfn "${DIR}/assets/kblock.svg" "${ICONS}/kblock.svg"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q "${APPS}" 2>/dev/null || true
fi

echo
echo "Готово."
echo "  GUI: kblock-gui (или «kblock» в меню приложений)"
echo "  CLI: kblock --help"
echo
echo "Wayland: один раз выдайте доступ к /dev/input:"
echo "  sudo ${SHARE}/setup-input-access.sh"
