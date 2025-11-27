FROM archlinux:base-devel
RUN pacman -Sy --noconfirm git pacman-contrib && \
    pacman -Scc --noconfirm
RUN useradd -m aur

USER aur
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
RUN git config --global user.name "${GIT_USER_NAME}" && \
    git config --global user.email "${GIT_USER_EMAIL}" && \
    git config --global --add safe.directory "*"

WORKDIR /pkg
