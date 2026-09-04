#!/usr/bin/env bash

RES="$(ykman otp calculate 2 50415343414c | sha256sum | cut -d " " -f 1)"

if [[ $RES == e1cba9fd67f19f28f76b44a2ad5c3f87a7b3bb213d1c39713fe280c1a34769bf ]]; then
  loginctl unlock-sessions
fi
