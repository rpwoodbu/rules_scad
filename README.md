# rules_scad
A (mostly) hermetic Bazel ruleset for building SCAD files using
[OpenSCAD](https://openscad.org/).

It is not required to install OpenSCAD to use this ruleset. It _may_ be
required to install some libraries that are not shipped with OpenSCAD in its
AppImage. Linux binaries for x86_64 and aarch64 have been defined.

## Getting Started

In your `WORKSPACE` file:
```Starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_SCAD_COMMIT = "88d3821f1ad44402aaeb40d4514a2d9d44c51d17"
RULES_SCAD_SHA256 = "1b3393650a88514ef151c75a8edefb904fafb934444dcf1fb45a474724caef7e"

http_archive(
    name = "rules_scad",
    urls = ["https://github.com/rpwoodbu/rules_scad/archive/{}.tar.gz".format(RULES_SCAD_COMMIT)],
    strip_prefix = "rules_scad-{}".format(RULES_SCAD_COMMIT),
    sha256 = RULES_SCAD_SHA256,
)

load("@rules_scad//scad:repositories.bzl", "rules_scad_repositories")

rules_scad_repositories()
```

Use the rules in your `BUILD` files:
```Starlark
load("@rules_scad//scad:defs.bzl", "scad_to_stl")

scad_to_stl(
    name = "awesome_model",
    srcs = ["awesome_model.scad"],
)
```

Then build in the usual way:
```shell
bazel build :awesome_model
```

You may also fire up the OpenSCAD GUI like so:
```shell
bazel run :awesome_model.gui
```

## SCAD dependencies

If you need to use any SCAD libraries, you may add `filegroup` targets to
`deps`.
