# GNOME SearchProvider for Bazzite Portal

A GNOME SearchProvider written in Python that looks at the YAML file for Bazzite Portal, puts it in Plasma Search, then calls Bazzite Portal to highlight the option if it is selected.

## Code Origins

This is only made possible by:

- Heavy inspiration(especially the build system!) from the [Krunner-Bazaar](https://github.com/bazaar-org/krunner-bazaar/) project,
- Documentation/Tutorial on [developer.gnome.org](https://developer.gnome.org/documentation/tutorials/search-provider.html)
- Some liberal use of LLMs (not agentic AI!) to help generate most of the boilerplate(though tbh this project *is* mostly just boilerplate). The code is manually reviewed and implemented.

## Installation

Requires Podman. Tested on Bazzite.
Building RPM Locally
```bash
# Build RPM package
just rpm
```

## Development

### Release Process

Update the .spec file, then:

Create a version tag:
```bash
just bump-version 1.x.x
```
Verify your changes, then run the following to add the appropriate tag and push the change:
```bash
just commit 1.x.x
```
GitHub Actions will hopefully automatically:

- Build the RPM packages
- Create a GitHub release
- Upload RPM artifacts with checksums
