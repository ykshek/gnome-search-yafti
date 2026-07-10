image_name := "localhost/gnome-search-yafti:dev"
default: rpm

build-container:
    #!/usr/bin/env bash
    echo "Building development container image..."
    podman build -t {{image_name}} -f Containerfile .

rpm: build-container
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Getting version..."
    VERSION=$(grep 'Version:' gnome-search-yafti.spec | sed -E 's/Version: *//' || echo "1.0.0")
    echo "Building gnome-search-yafti..."

    # Create RPM build structure
    mkdir -p rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

    # Create source tarball
    echo "Creating source tarball..."
    tar -czf rpmbuild/SOURCES/gnome-search-yafti-$VERSION.tar.gz -C src .

    # Copy spec file
    cp gnome-search-yafti.spec rpmbuild/SPECS/

    podman run --rm \
        --userns=keep-id \
        --volume "$(pwd):/workspace:Z" \
        --workdir /workspace \
        {{image_name}} \
        bash -c "
            set -euo pipefail

            # Build the RPM
            rpmbuild --define '_topdir /workspace/rpmbuild' \
                     --define 'version ${VERSION}' \
                     -ba rpmbuild/SPECS/gnome-search-yafti.spec
        "

    echo "RPM build complete!"
    echo "Built packages:"
    find rpmbuild/RPMS -name "*.rpm" -type f
    find rpmbuild/SRPMS -name "*.rpm" -type f
