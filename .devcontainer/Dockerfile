FROM registry.access.redhat.com/ubi9/ubi

RUN yum install -y --allowerasing \
    git \
    curl \
    vim \
    python3 \
    python3-pip \
    java-11-openjdk \
    && yum clean all

ARG USERNAME=vscode
RUN useradd -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME