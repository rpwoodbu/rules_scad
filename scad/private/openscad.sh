#!/bin/bash -e

# Sets up OpenSCAD environment. Usage:
#   openscad.sh BIN SRC FLAGS [...] -- LIBNAME=SRC[,SRC,...] [...]
# Subdirectories will be created for each LIBNAME and their SRCs linked into them.

## --- begin runfiles.bash initialization v3 ---
## Copy-pasted from the Bazel Bash runfiles library v3.
#set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
## shellcheck disable=SC1090
#source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
#  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
#  source "$0.runfiles/$f" 2>/dev/null || \
#  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
#  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
#  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
## --- end runfiles.bash initialization v3 ---

args=()
# DO NOT MERGE
#args+=("$(rlocation "${1}")"); shift  # OpenSCAD binary
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
