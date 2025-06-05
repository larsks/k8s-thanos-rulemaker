#!/bin/bash
# shellcheck disable=SC2162

LOG() {
  echo "$(date -Iseconds) ${0##*/}: $*" >&2
}

set -e

while :; do
  LOG "watching for changes"

  # Watch for changes to configmaps with the "thanos-rules" label
  oc get cm -l thanos-rules \
    --watch --output-watch-events --no-headers \
    -o custom-columns=TYPE:.type,NAME:.object.metadata.name | while read event name; do
    LOG "triggered by: $event $name"
    fragsdir=$(mktemp -d assembleXXXXXX)

    # We know something has been updated; fetch all the configmaps and re-generate the
    # merged configuration.
    oc get cm -l thanos-rules -o name | while read cm; do
      LOG "processing : $cm"
      tmpdir=$(mktemp -d rulesXXXXXX)
      oc extract "$cm" --to "$tmpdir"

      # A configmap may contain multiple files, and there may be multiple configmaps. We
      # copy all the files into `$fragsdir`, and we name them using a sha256sum in
      # order to avoid filename conflicts (e.g., the situation in which two configmaps
      # both contain `config.yaml`).
      for file in "$tmpdir/"*; do
        LOG "copying file ${file##*/} from $cm"
        cp "$file" "$fragsdir/$(sha256sum "$file" | awk '{print $1}').yaml"
      done
      rm -rf "$tmpdir"
    done

    LOG "merging configuration fragments"
    yq eval-all '. as $item ireduce ({}; . *+ $item)' "$fragsdir"/* >/tmp/custom-rules.yaml

    LOG "creating custom-rules configmap"
    oc create cm custom-rules --from-file=/tmp/custom-rules.yaml -o yaml --dry-run=client | oc apply -f-

    rm -rf "$fragsdir"
  done

  LOG "watch failed; sleeping"
  sleep 5
done
