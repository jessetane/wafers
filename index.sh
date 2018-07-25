#!/bin/bash

set -e
# set -x

argv=("$@")
wafers="${WAFERS:-/var/lib/wafers}"
stacks="${STACKS:-/var/lib/machines}"

# parse args
for arg in "${argv[@]}"; do
  if [[ $arg =~ ^\- ]]; then
    continue
  elif [ -z ${cmd+x} ]; then
    cmd="$arg"
  elif [ "$cmd" = "stack" ]; then
    if [ -z ${name+x} ]; then
      name="$arg"
    elif [ -z ${parent+x} ]; then
      parent="$arg"
    else
      echo "too many arguments" >&2
      exit 2
    fi
  elif [ "$cmd" = "unstack" ]; then
    stack="${stacks}/${arg}"
    if findmnt "$stack" &>/dev/null; then
      umount "$stack"
      rmdir "$stack" &>/dev/null || true
      echo "unstacked ${stack}"
    else
      echo "nothing stacked at ${stack}"
    fi
  else
    echo "unknown command ${cmd}" >&2
    exit 1
  fi
done
 
if [ "$cmd" = "unstack" ]; then
  if [ -z "$stack" ]; then
    echo "nothing to unstack"
  fi
  exit 0
elif [ "$cmd" = "tree" ]; then
  echo "not implemented yet, could render a visualization here" >&2
  exit -1
else
  wafer="${wafers}/${name}"
  stack="${stacks}/${name}"
fi

# check for existing stack, parent link
if [ -z "$name" ]; then
  echo "no wafer specified" >&2
  exit 3
elif findmnt "$stack" &>/dev/null; then
  echo "something is already mounted at ${stack}"
  exit 0
elif [ -z "$parent" ]; then
  parent="$(cat "${wafer}/parent" 2>/dev/null || true)"
fi

# stack wafers if they are all available
numberOfWafersStacked=1
if [ -n "$parent" ]; then
  if [ -d "$wafer" ]; then
    if [ ! -f "${wafer}/parent" ] || [ "$parent" != "$(< "${wafer}/parent")" ]; then
      echo "parent was specified but does not match existing" >&2
      exit 4
    fi
  fi
  traceancestry () {
    ((numberOfWafersStacked++)) || true
    if [ ! -d "${wafers}/${1}/data" ]; then
      echo "ancestry corrupt" >&2
      exit 5
    fi
    ancestry="${ancestry}${wafers}/${1}/data"
    if [ -f "${wafers}/${1}/parent" ]; then
      ancestry="${ancestry}:"
      traceancestry "$(< "${wafers}/${1}/parent")"
    fi
  }
  ancestry=""
  traceancestry "$parent"
  if [ ! -d "${wafer}/data" ]; then
    mkdir -p "${wafer}/"{work,data} "$stack"
    echo "$parent" > "${wafer}/parent"
    user="$(stat -c %u "${wafers}/${parent}/data")"
    group="$(stat -c %g "${wafers}/${parent}/data")"
    chown -R "${user}:${group}" "${wafer}/data"
  fi
  mount -t overlay -o lowerdir="$ancestry",workdir="${wafer}/work",upperdir="${wafer}/data" overlay "$stack"
elif [ -d "${wafer}/data" ]; then
  mkdir -p "$stack"
  mount -o bind "${wafer}/data" "$stack"
else
  echo "wafer not found" >&2
  exit 6
fi

echo "${numberOfWafersStacked} wafers stacked at ${stack}"
