load("//scad:repositories.bzl", "rules_scad_repositories")

def _repositories_impl(ctx):
    rules_scad_repositories()

repositories = module_extension(
    implementation = _repositories_impl,
)
