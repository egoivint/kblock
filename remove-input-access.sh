#!/bin/bash
# Удаляет правило udev, выданное setup-input-access.sh.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

RULE=/etc/udev/rules.d/70-kblock-input.rules
rm -f "$RULE"
udevadm control --reload-rules
udevadm trigger --subsystem-match=input --action=change
echo "Правило $RULE удалено."
