FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-daily

USER root

RUN apt-get update && \
    apt-get install -y \
        sudo \
        dnsutils \
        xfce4-whiskermenu-plugin \
        curl \
        wget \
        vim \
        iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
