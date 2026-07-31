#!/bin/bash

# Thanks to https://www.reddit.com/r/kernel/comments/1hu2hj8/which_version_of_gcc_can_compile_kernel_2611/
set -e
# Get current user info
CURRENT_USER=$(id -un)
CURRENT_GROUP=$(id -gn)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# Check if the linux26-builder image exists
if ! docker image inspect debian-sarge-builder-i386 >/dev/null 2>&1; then
    echo "debian-sarge-builder-i386 image not found, building it now..."
    docker build -t debian-sarge-builder-i386 --build-arg USERNAME="$CURRENT_USER" \
                                      --build-arg GROUPNAME="$CURRENT_GROUP" \
                                      --build-arg UID="$CURRENT_UID" \
                                      --build-arg GID="$CURRENT_GID" - <<EOF
FROM debian/eol:sarge


RUN apt-get update 
RUN apt-get -y install gcc-2.95 ncurses-dev build-essential make
RUN apt-get -y install sudo wget gawk

# Create user matching host user
ARG USERNAME
ARG GROUPNAME
ARG UID
ARG GID
RUN if [ "\$GID" -ne 0 ]; then groupadd -g \$GID \$GROUPNAME; fi && \
    useradd -m -u \$UID -g \$GID -s /bin/bash \$USERNAME && \
    echo "\$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup environment
USER \$USERNAME
WORKDIR /home/\$USERNAME/src
ENV HOME /home/\$USERNAME

CMD ["bash"]
EOF
else
    echo "debian-sarge-builder-i386 image already exists, skipping build"
fi

set -x
# Run the container
docker run --rm -it \
    -v "$PWD":"$PWD" \
    -w "$PWD" \
    debian-sarge-builder-i386 /bin/bash "$@"
