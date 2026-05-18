#!/usr/bin/env bash

DEVICE="$(wpctl inspect @DEFAULT_SINK@ | grep -F device.id | cut -d '"' -f 2)"
DEVICE="$(pw-dump | jq ".[] | select(.id == $DEVICE)")"
ROUTES="$(jq '.info.params.EnumRoute | .[] | select(.direction == "Output") | .index' <<< "$DEVICE")"
ROUTE="$(jq '.info.params.Route | .[] | select(.direction == "Output") | .index' <<< "$DEVICE")"

wpctl set-route @DEFAULT_SINK@ "$(echo -e "$ROUTES\n$ROUTES" | sed -n "/^$ROUTE$/{n;p;q}")"
