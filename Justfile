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


bump-version version:
    #!/usr/bin/env bash
    set -euo pipefail

    VERSION="{{version}}"

    # Validate version format (should be like 1.2.3)
    if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "Error: Version must be in format X.Y.Z (e.g., 1.2.3)"
        exit 1
    fi

    echo "Bumping version to $VERSION..."

    # Check if working directory is clean
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Error: Working directory is not clean. Please commit or stash changes first."
        git status --porcelain
        exit 1
    fi

    # Update the version in gnome-search-yafti.spec
    echo "Updating version in gnome-search-yafti.spec..."
    sed -i "s/^Version:.*/Version:        $VERSION/" gnome-search-yafti.spec

    # Verify the change was made in gnome-search-yafti.spec
    if ! grep -q "^Version:[[:space:]]*$VERSION" gnome-search-yafti.spec; then
        echo "Error: Failed to update version in gnome-search-yafti.spec"
        exit 1
    fi

    echo "Version updated successfully in metadata.json"
    git diff gnome-search-yafti.spec
    git add gnome-search-yafti.spec
    git commit -m "chore: bump version to v$VERSION"


commit version:
    #!/usr/bin/env bash
    set -euo pipefail

    VERSION="{{version}}"

    # Validate version format (should be like 1.2.3)
    if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "Error: Version must be in format X.Y.Z (e.g., 1.2.3)"
        exit 1
    fi

    echo "Tagging version $VERSION..."

    # Check if working directory is clean
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Error: Working directory is not clean. Please commit or stash changes first."
        git status --porcelain
        exit 1
    fi

    git push origin HEAD

    git tag "v$VERSION"
    git push origin "v$VERSION"
