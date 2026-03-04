FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# Install base utilities + security tools
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
        fonts-liberation \
        fonts-noto \
        fonts-noto-color-emoji \
        libu2f-udev \
        xclip \
        unzip \
        zip \
        p7zip-full \
        openjdk-21-jre \
        libnss3 \
        libgtk-3-0 \
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
    apt-get install -y microsoft-edge-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Burp Suite Community (latest version at build time)
RUN curl -fsSL -L "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
    -o /tmp/burpsuite.sh && \
    chmod +x /tmp/burpsuite.sh && \
    /tmp/burpsuite.sh -q -dir /opt/burpsuite && \
    ln -sf /opt/burpsuite/BurpSuiteCommunity /usr/local/bin/burpsuite && \
    rm -f /tmp/burpsuite.sh

# Burp desktop launcher
RUN printf '%s\n' \
'[Desktop Entry]' \
'Name=Burp Suite Community' \
'Exec=/opt/burpsuite/BurpSuiteCommunity' \
'Type=Application' \
'Categories=Development;Security;' \
'Terminal=false' \
> /usr/share/applications/burpsuite.desktop

# OWASP ZAP desktop launcher
RUN printf '%s\n' \
'[Desktop Entry]' \
'Name=OWASP ZAP' \
'Exec=zaproxy' \
'Type=Application' \
'Categories=Development;Security;' \
'Terminal=false' \
> /usr/share/applications/zaproxy.desktop

# Nmap launcher (opens terminal)
RUN printf '%s\n' \
'[Desktop Entry]' \
'Name=Nmap Scanner' \
'Exec=xfce4-terminal -e "nmap --help"' \
'Type=Application' \
'Categories=Security;' \
'Terminal=false' \
> /usr/share/applications/nmap.desktop

# Allow passwordless sudo
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
