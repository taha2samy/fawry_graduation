FROM registry.access.redhat.com/ubi9/ubi

RUN dnf install -y --allowerasing \
      git \
      curl \
      vim \
      python3 \
      python3-pip \
      java-11-openjdk \
      dnf-plugins-core \
      unzip \
      sudo && \
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf install -y terraform && \
    curl -Lo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/latest/download/kops-linux-amd64 && \
    chmod +x /usr/local/bin/kops && \
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    dnf clean all

ARG USERNAME=vscode
RUN useradd -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME
