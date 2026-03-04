FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# Install base utilities
RUN apt-get update && \
    apt-get install -y \
        sudo \
        dnsutils \
        xfce4-whiskermenu-plugin \
        curl \
        wget \
        vim \
        iputils-ping \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add Microsoft Edge repository
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /etc/apt/keyrings/microsoft-edge.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
        > /etc/apt/sources.list.d/microsoft-edge.list

# Install Edge
RUN apt-get update && \
    apt-get install -y microsoft-edge-stable && \
    rm -rf /var/lib/apt/lists/*

# Allow passwordless sudo
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
