#!/bin/bash
# Разрешает активному пользователю сессии захватывать клавиатуру/указатель
# через evdev (нужно для работы kblock под Wayland).
#
# Правило udev с TAG+="uaccess": доступ выдаётся только активной локальной
# сессии и только к устройствам ввода (клавиатуры, мыши, тачпады).
# Понимает, что это ослабляет защиту от кейлоггеров в рамках сессии, —
# при необходимости удалите правило через remove-input-access.sh.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

RULE=/etc/udev/rules.d/70-kblock-input.rules

tee "$RULE" >/dev/null <<'EOF'
# Managed by kblock: allow the active local user to grab input devices.
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_KEYBOARD}=="1", TAG+="uaccess"
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_MOUSE}=="1", TAG+="uaccess"
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
EOF

udevadm control --reload-rules
udevadm trigger --subsystem-match=input --action=change

echo "Готово: правило $RULE установлено."
echo "Проверка: kblock --backend evdev -t 1"
echo "Удалить доступ: sudo $(dirname "$0")/remove-input-access.sh"
