load("//scad/private:scad_library.bzl", "ScadInfo")

_COMMON_ATTRS = {
    "srcs": attr.label_list(allow_files = True, mandatory = True),
    "deps": attr.label_list(),
    "_openscad": attr.label(
        cfg = "exec",
        executable = True,
        allow_single_file = True,
        default = Label("//scad/private:openscad")
    ),
    "_openscad_wrapper": attr.label(
        cfg = "exec",
        executable = True,
        allow_single_file = True,
        default = Label("//scad/private:openscad_wrapper.sh")
    ),
}

def _scad_to_stl(ctx):
    if len(ctx.attr.srcs) != 1:
      fail("scad_to_stl can only take one element for srcs")

    out = ctx.actions.declare_file(ctx.attr.name + ".stl")

    args = ctx.actions.args()
    args.add(ctx.file._openscad.path)
    if ctx.attr.quiet:
        args.add("--quiet")
    if ctx.attr.hardwarnings:
        args.add("--hardwarnings")
    args.add("-o", out.path)
    args.add(ctx.files.srcs[0].path)
    args.add("--")
    deps_files = []
    for dep in ctx.attr.deps:
        for lib, files in dep[ScadInfo].libraries.items():
            files_as_list = files.to_list()
            deps_files.extend(files_as_list)
            args.add("{}={}".format(
                lib,
                ",".join([f.path for f in files_as_list]),
            ))

    ctx.actions.run(
        inputs = ctx.files.srcs + deps_files,
        tools = ctx.files._openscad,
        outputs = [out],
        arguments = [args],
        executable = ctx.executable._openscad_wrapper,
        mnemonic = "OpenSCADRender",
    )

    return [DefaultInfo(files = depset([out]))]

_scad_to_stl_rule = rule(
    implementation = _scad_to_stl,
    attrs = _COMMON_ATTRS | {
        "hardwarnings": attr.bool(default = True),
        "quiet": attr.bool(default = False),
    },
)

def _scad_gui(ctx):
    if len(ctx.attr.srcs) != 1:
      fail("scad_gui can only take one element for srcs")

    # DO NOT MERGE: Factor all this out.
    deps_files = []
    libs = []
    for dep in ctx.attr.deps:
        for lib, files in dep[ScadInfo].libraries.items():
            files_as_list = files.to_list()
            deps_files.extend(files_as_list)
            libs.append("{}={}".format(
                lib,
                ",".join([f.path for f in files_as_list]),
            ))

    script = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        output = script,
        is_executable = True,
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

exec $(rlocation "%s") "%s" $(rlocation "%s") -- %s
""" % (
            "{}/{}".format(ctx.workspace_name, ctx.file._openscad_wrapper.path),
            ctx.file._openscad.short_path,
            "{}/{}".format(ctx.workspace_name, ctx.files.srcs[0].path),
            " ".join(libs),
        ),
    )

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(
            files = [
                ctx.file._openscad,
                ctx.file._openscad_wrapper,
            ] + ctx.files.srcs + deps_files + ctx.files._runfiles,
            transitive_files = ctx.attr._openscad[DefaultInfo].default_runfiles.files,
        ),
    )]

_scad_gui_rule = rule(
    implementation = _scad_gui,
    attrs = _COMMON_ATTRS | {
        "_runfiles": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
    },
    executable = True,
)


def scad_to_stl(name, srcs, deps = [], **kwargs):
    if len(srcs) != 1:
        fail("scad_to_stl can only take one element for srcs")

    _scad_to_stl_rule(
        name = name,
        srcs = srcs,
        deps = deps,
        **kwargs
    )

    _scad_gui_rule(
        name = "{}.gui".format(name),
        srcs = srcs,
        deps = deps,
    )
