#!/usr/bin/env bash

if [ -f /data/.catchup-completed ]; then
  echo "Not publishing archives because a full catchup has been completed before"
  exit 0
fi

# publish history archives
IFS=$'\n'
LOCAL_ARCHIVE="/data/history-archive"
for HISTORY_ARCHIVE in $(echo $HISTORY | jq -rc 'to_entries | map(select(.value.put?)) | .[]'); do
  NAME=$(echo $HISTORY_ARCHIVE | jq -r '.key')
  echo "Publishing archive $NAME..."
  PUTDIR=$(echo $HISTORY_ARCHIVE | jq -r '.value.putdir')
  if [ "$PUTDIR" != "null" ]; then
    CMD=${PUTDIR//\{0\}/$LOCAL_ARCHIVE}
    CMD=${CMD//\{1\}/""}
    bash -c "$CMD"
  else
    PUT=$(echo $HISTORY_ARCHIVE | jq -r '.value.put')
    MKDIR=$(echo $HISTORY_ARCHIVE | jq -r '.value.mkdir')
    if [ "$MKDIR" != "null" ]; then
      for DIR in $(find $LOCAL_ARCHIVE -type d -printf '%P\n'); do
        CMD=${MKDIR//\{0\}/$DIR}
        bash -c "$CMD"
      done
      for FILE in $(find $LOCAL_ARCHIVE -type f -printf '%P\n'); do
        CMD=${PUT//\{0\}/"$LOCAL_ARCHIVE/$FILE"}
        CMD=${CMD//\{1\}/$FILE}
        bash -c "$CMD"
      done
    fi
  fi
  echo "Published archive $NAME."
done

touch /data/.catchup-completed
