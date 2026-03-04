FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# Make sure Ubuntu repos are enabled (Universe is required for many tools like nmap/zaproxy)
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common ca-certificates gnupg && \
    add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get update && \
    rm -rf /var/lib/apt/lists/*

# Base utilities + XFCE Whisker + security tools + browser compatibility
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        dnsutils \
        xfce4-whiskermenu-plugin \
        curl \
        wget \
        vim \
        iputils-ping \
        fonts-liberation \
        fonts-noto-core \
        fonts-noto-color-emoji \
        libu2f-udev \
        xclip \
        unzip \
        zip \
        p7zip-full \
        default-jre \
        libnss3 \
        libgtk-3-0t64 \
        nmap \
        zaproxy \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Microsoft Edge repository
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/microsoft-edge.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
    > /etc/apt/sources.list.d/microsoft-edge.list

# Install Microsoft Edge
RUN apt-get update && \
    apt-get install -y --no-install-recommends microsoft-edge-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Burp Suite Community (latest at build time)
RUN curl -fsSL -L "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
    -o /tmp/burpsuite.sh && \
    chmod +x /tmp/burpsuite.sh && \
    /tmp/burpsuite.sh -q -dir /opt/burpsuite && \
    ln -sf /opt/burpsuite/BurpSuiteCommunity /usr/local/bin/burpsuite && \
    rm -f /tmp/burpsuite.sh

# Desktop launchers
RUN printf '%s\n' \
'[Desktop Entry]' \
'Name=Burp Suite Community' \
'Exec=/opt/burpsuite/BurpSuiteCommunity' \
'Type=Application' \
'Categories=Development;Security;' \
'Terminal=false' \
> /usr/share/applications/burpsuite.desktop && \
printf '%s\n' \
'[Desktop Entry]' \
'Name=OWASP ZAP' \
'Exec=zaproxy' \
'Type=Application' \
'Categories=Development;Security;' \
'Terminal=false' \
> /usr/share/applications/zaproxy.desktop && \
printf '%s\n' \
'[Desktop Entry]' \
'Name=Nmap Scanner' \
'Exec=xfce4-terminal -e "nmap --help"' \
'Type=Application' \
'Categories=Security;' \
'Terminal=false' \
> /usr/share/applications/nmap.desktop

# Passwordless sudo for kasm-user
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
