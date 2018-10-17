#!/usr/bin/env bash

set -eu pipefail

if [ -f /data/.catchup-completed ]; then
  echo "Not running full catchup because a full catchup has been completed before"
  exit 0
fi

HISTORY_WRITE_NUM=$(echo $HISTORY | jq -rc 'to_entries | map(select(.value.put?)) | length')
if [ "$HISTORY_WRITE_NUM" = "0" ]; then
  echo "No writable archives configured"
else
  # get read-only archives and add local archive
  HISTORY_READ_ONLY=$(echo $HISTORY | jq -r 'to_entries | map(select (.value.put == null)) | from_entries')
  export HISTORY=$(echo $HISTORY_READ_ONLY | jq -r '. + {local: {get: "cp /data/history-archive/{0} {1}", put: "cp {0} /data/history-archive/{1}", mkdir: "mkdir -p /data/history-archive/{0}"}}')
fi

echo "Running a complete catchup"
ls /data

# generate config, init local archive and run catchup
exec /entry.sh /usr/local/bin/stellar-core --conf /stellar-core.cfg --catchup-complete
