#!/usr/bin/env bash

# import the lib.
source "$ROOT/utils/common.sh"
source "$ROOT/utils/layout.sh"
source "$ROOT/utils/config.sh"

master_size=$TALL_RATIO

node_filter="!hidden"

join_array() {
  local -r _delimiter="$1"
  local -ra _arr=("${@:2}")

  (
    IFS="$_delimiter"
    echo "${_arr[*]}"
  )
}

# List[args] -> ()
execute_layout() {
  while [[ ! "$#" == 0 ]]; do
    case "$1" in
    --master-size)
      master_size="$2"
      shift
      ;;
    *) echo "$x" ;;
    esac
    shift
  done

  local newest_node
  local root_at_2

  readarray all_windows <<<"$(bspc query -N '@/' -n .descendant_of.window.$node_filter)"
  readarray master_windows <<<"$(bspc query -N '@/1' -n .descendant_of.window.$node_filter)"
  newest_node=$(bspc query -N '@/' -n last.descendant_of.window.$node_filter | head -n 1)

  if [[ ${#master_windows[@]} -lt 2 ]]; then
    root_at_2=$(bspc query -N '@/2' -n .descendant_of.window.$node_filter | head -n1)

    [ -n "$root_at_2" ] && bspc node "$root_at_2" -n '@/1'

    rotate '@/1' vertical 90
  else
    local -ra excess_master_windows=${master_windows[@]:3}

    for node in "${excess_master_windows[@]}"; do
      bspc node "$node" -n '@/2'
    done

    rotate '@/2' horizontal 180
  fi

  local mon_width=$(jget width "$(bspc query -T -m)")

  local want=$(rcalc "$master_size * $mon_width")
  local have=$(jget width "$(bspc query -T -n '@/1')")

  if [[ ${#all_windows[@]} -le 2 ]]; then return; fi

  # Seems like we can only resize a single window, not just any node, so we
  # do just that before resizing the whole master node
  bspc node '@/1/2' -z right $((want - have)) 0

  auto_balance '@/1'
  auto_balance '@/2'
}

cmd=$1
shift
case "$cmd" in
run) execute_layout "$@" ;;
esac
