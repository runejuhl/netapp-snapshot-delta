#!/usr/bin/env bash
#
# Get NetApp snapshot delta sizes between two snapshots.

set -euo pipefail

ssh_target="${1}"
vserver="${2}"
snapshot1="${3}"
snapshot2="${4}"

volumes=()

>&2 cat <<EOF
Comparing volume snapshot deltas on '${vserver}' between snapshots '${snapshot1}' and '${snapshot2}'

EOF

while read -r volume; do
  volumes+=("$volume")
done < <(ssh "${ssh_target}" volume show |
           grep -Po "^${vserver}\s+\K\S+")

for volume in "${volumes[@]}"; do
  bytes=$(ssh "${ssh_target}" snap delta -vserver "${vserver}" -volume "${volume}" -snapshot1 "${snapshot1}" -snapshot2 "${snapshot2}" |
            grep -Po '^A total of \K\d+' || true)
  if [[ "${bytes}" ]]; then
    echo "$(numfmt  --to=si --suffix=B "${bytes}") ${vserver} ${volume}"
  fi
done | sort -hr
