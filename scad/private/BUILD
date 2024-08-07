load("//scad/private:appimage.bzl", "appimage_binary")

appimage_binary(
    name = "openscad",
    appimage = select({
        "@platforms//cpu:aarch64": "@openscad-aarch64//file",
        "@platforms//cpu:x86_64": "@openscad-x86_64//file",
    }),
    visibility = ["//visibility:public"],
)

exports_files(["openscad.sh"])
