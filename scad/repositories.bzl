load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_scad_repositories():
    maybe(
        http_file,
        name = "openscad-x86_64",
        executable = True,
        integrity = "sha256-91hSjyzSE/dzx6EF+2O/O0W/dUsPWG+7fJzWU//NCII=",
        urls = ["https://files.openscad.org/OpenSCAD-2021.01-x86_64.AppImage"],
    )

    maybe(
        http_file,
        name = "openscad-aarch64",
        executable = True,
        integrity = "sha256-UYt+FnGz7Lfp2oGk30fs+dycfe+XvObcDc1VN5W4nak=",
        urls = ["https://files.openscad.org/OpenSCAD-2021.01-aarch64.AppImage"],
    )
