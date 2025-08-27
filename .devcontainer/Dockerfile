FROM registry.access.redhat.com/ubi9/ubi

RUN dnf install -y --allowerasing \
    git \
    curl \
    vim \
    python3 \
    python3-pip \
    java-11-openjdk \
    dnf-plugins-core \
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
    dnf -y install terraform \
    curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 \
    chmod +x kops \
    mv kops /usr/local/bin/kops \
    dnf clean all


ARG USERNAME=vscode
RUN useradd -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME