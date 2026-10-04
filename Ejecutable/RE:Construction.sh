#!/bin/sh
printf '\033c\033]0;%s\a' RE-Construction
base_path="$(dirname "$(realpath "$0")")"
"$base_path/RE:Construction.x86_64" "$@"
