FROM quay.io/fedora/fedora:latest

LABEL description="Development environment for Bazzite Portal GNOME Search Provider"
LABEL maintainer="Alex Shek <hms.starryfish@gmail.com>"

# Update system and install build dependencies
RUN dnf5 update -y && \
    dnf5 install -y \
        # RPM build tools
        rpm-build \
        rpmdevtools \
        && dnf5 clean all

# Set up workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
