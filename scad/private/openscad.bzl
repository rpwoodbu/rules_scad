def _scad_to_stl(ctx):
    if len(ctx.attr.srcs) != 1:
      fail("scad_to_stl can only take one element for srcs")

    out = ctx.actions.declare_file(ctx.attr.name + ".stl")

    args = ctx.actions.args()
    if ctx.attr.quiet:
        args.add("--quiet")
    if ctx.attr.hardwarnings:
        args.add("--hardwarnings")
    args.add("-o", out.path)
    args.add(ctx.files.srcs[0].path)

    ctx.actions.run(
        inputs = ctx.files.srcs + ctx.files.deps,
        outputs = [out],
        arguments = [args],
        executable = ctx.executable._openscad,
        mnemonic = "OpenSCADRender",
    )

    return [DefaultInfo(files = depset([out]))]

_scad_to_stl_rule = rule(
    implementation = _scad_to_stl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "deps": attr.label_list(allow_files = True),
        "hardwarnings": attr.bool(default = True),
        "quiet": attr.bool(default = False),
        "_openscad": attr.label(
            cfg = "exec",
            executable = True,
            allow_files = True,
            default = Label("//scad/private:openscad")
        ),
    },
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

    native.sh_binary(
        name = "{}.gui".format(name),
        srcs = ["@rules_scad//scad/private:openscad.sh"],
        data = ["@rules_scad//scad/private:openscad"] + srcs + deps,
        args = [
            "$(rlocationpath @rules_scad//scad/private:openscad)",
            srcs[0],
        ],
    )
