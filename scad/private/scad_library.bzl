ScadInfo = provider(fields = [
    "libraries",  # Dict of library name to depset of its files.
])
     
def _scad_library_impl(ctx):
    libraries = {}
    for dep in ctx.attr.deps:
        if ctx.label.name in dep[ScadInfo].libraries:
            fail("Conflicting library name in deps of {}".format(ctx.label))
        libraries |= dep[ScadInfo].libraries

    libraries[ctx.label.name] = depset(ctx.files.srcs)

    return [ScadInfo(libraries = libraries)]

scad_library = rule(
    implementation = _scad_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
    },
)
