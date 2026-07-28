#!/bin/bash

# Allows to switch automatically to tag 1 if current tag is empty
mmsg watch all-monitors | while read -r line; do
  echo "$line" | jq -c '.monitors[] | select(.active==true) | .tags[] | select(.is_active==true)' \
  | while read -r tag; do
      idx=$(echo "$tag" | jq -r '.index')
      count=$(echo "$tag" | jq -r '.client_count')
      if [[ "$count" == "0" && "$idx" != "1" ]]; then
        mmsg dispatch view,1
      fi
    done
done
