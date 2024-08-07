def _appimage_binary(ctx):
    """Makes the executable binary within an AppImage available without FUSE."""
    extract_dir = ctx.actions.declare_directory("{}.extract".format(ctx.attr.name))
    ctx.actions.run_shell(
        outputs = [extract_dir],
        tools = [ctx.file.appimage],
        command = """
set -eu
"{appimage}" --appimage-extract >/dev/null

# The file `AppRun.wrapped` is a symlink pointing to the real binary. The
# final binary _must_ be in the right directory. In some circumstances, Bazel
# likes to remove the symlink and copy up the binary. This breaks the dynamic
# linker. Replace the symlink with a short script that execs the proper binary.
APPRUN_WRAPPED=squashfs-root/AppRun.wrapped
WRAPPED_REAL="$(readlink "$APPRUN_WRAPPED")"
rm "$APPRUN_WRAPPED"
echo -e "#!/bin/sh\\nexec \\"\\$(readlink -f \\"\\$(dirname \\$0)\\")/$WRAPPED_REAL\\" \\"\\$@\\"" >"$APPRUN_WRAPPED"
chmod +x "$APPRUN_WRAPPED"

rmdir "{extract_dir}"
mv squashfs-root "{extract_dir}"
""".format(
            extract_dir = extract_dir.path,
            appimage = ctx.file.appimage.path,
        ),
        mnemonic = "AppImageExtract",
    )

    wrapper = ctx.actions.declare_file("{}.sh".format(ctx.attr.name))
    # We need a reliable rlocationpath, but none of the `File` members seem to
    # give it. In particular, `short_path` is relative to the execution root,
    # thus may include a `..` component. What we really want is the path minus
    # the root (which is what `short_path` is documented to be, but isn't
    # exactly). We also need to include the workspace name.
    extract_dir_rlocation = "".join([
            ctx.workspace_name,
            extract_dir.path.removeprefix(extract_dir.root.path),
        ])
    ctx.actions.write(
        output = wrapper,
        content = """#!/bin/bash -eu
# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

exec "$(rlocation %s)/AppRun" "$@"
""" % (extract_dir_rlocation),
        is_executable = True,
    )

    return DefaultInfo(
        runfiles = ctx.runfiles(files = [extract_dir] + ctx.files._runfiles),
        executable = wrapper,
    )

appimage_binary = rule(
    implementation = _appimage_binary,
    executable = True,
    attrs = {
        "appimage": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "_runfiles": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
    },
)
