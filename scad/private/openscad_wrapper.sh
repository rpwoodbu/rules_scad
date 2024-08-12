#!/bin/bash -e

# Sets up OpenSCAD environment. Usage:
#   openscad.sh BIN SRC FLAGS [...] -- LIBNAME=SRC[,SRC,...] [...]
# Subdirectories will be created for each LIBNAME and their SRCs linked into them.

args=()
args+=("${1}"); shift  # OpenSCAD binary
args+=("${1}"); shift  # Source file
while [[ "${1}" != "--" ]]; do  # Flags
  args+=("${1}"); shift
done
shift  # Consume `--`

# Process libs
for lib in "${@}"; do
  IFS="=" read -a parts <<< "${lib}"
  readonly libname="${parts[0]}"
  IFS="," read -a files <<< "${parts[1]}"
  mkdir "${libname}"
  for file in "${files[@]}"; do
    # DO NOT MERGE: `basename` isn't going to be good enough.
    ln -s "../${file}" "${libname}/$(basename "${file}")"
  done
done

exec "${args[@]}"
