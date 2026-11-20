#!/bin/bash
set -euo pipefail

deno run --quiet --allow-read --allow-write /sbbs/scripts/post-build.ts
/sbbs/exec/sbbs version > /sbbs/exec/version.txt
printf '\nGit Hash %s\n' "$SYNCHRONET_COMMIT" >> /sbbs/exec/version.txt

cp /sbbs/exec/node /sbbs/exec/sbbsnode
mkdir -p /sbbs/dist
for path in ctrl docs text xtrn web webv4 webmail node1; do
    if [ -e "/sbbs/$path" ]; then
        target="$path"
        if [ "$path" = web ]; then target=web-runemaster; fi
        if [ "$path" = webv4 ]; then target=web-ecweb4; fi
        mv "/sbbs/$path" "/sbbs/dist/$target"
    fi
done
rm -rf /sbbs/node2 /sbbs/node3 /sbbs/node4 /sbbs/3rdp /sbbs/src /sbbs/repo
rm -rf /sbbs/data
