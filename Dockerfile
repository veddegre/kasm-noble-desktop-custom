FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# Enable Ubuntu universe/multiverse (Noble commonly uses Deb822 sources)
RUN set -eux; \
  if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
    sed -i 's/^Components: .*/Components: main restricted universe multiverse/' /etc/apt/sources.list.d/ubuntu.sources; \
  fi; \
  apt-get update

# Install base utilities and UI bits (group 1)
RUN set -eux; \
  apt-get install -y --no-install-recommends \
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
    fonts-noto-core \
    fonts-noto-color-emoji \
    libu2f-udev \
    xclip \
    unzip \
    zip \
    libnss3 \
    libgtk-3-0t64 \
  ; \
  rm -rf /var/lib/apt/lists/*

# Security tools + Java (group 2)  -- kept separate so failures are obvious in logs
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    p7zip-full \
    default-jre \
    nmap \
    zaproxy \
  ; \
  rm -rf /var/lib/apt/lists/*

# Add Microsoft Edge repository
RUN set -eux; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/microsoft-edge.gpg; \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
    > /etc/apt/sources.list.d/microsoft-edge.list

# Install Microsoft Edge
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends microsoft-edge-stable; \
  rm -rf /var/lib/apt/lists/*

# Install Burp Suite Community (latest at build time)
RUN set -eux; \
  curl -fsSL -L "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
    -o /tmp/burpsuite.sh; \
  chmod +x /tmp/burpsuite.sh; \
  /tmp/burpsuite.sh -q -dir /opt/burpsuite; \
  ln -sf /opt/burpsuite/BurpSuiteCommunity /usr/local/bin/burpsuite; \
  rm -f /tmp/burpsuite.sh

# Desktop launchers
RUN set -eux; \
  printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Burp Suite Community' \
    'Exec=/opt/burpsuite/BurpSuiteCommunity' \
    'Type=Application' \
    'Categories=Development;Security;' \
    'Terminal=false' \
    > /usr/share/applications/burpsuite.desktop; \
  printf '%s\n' \
    '[Desktop Entry]' \
    'Name=OWASP ZAP' \
    'Exec=zaproxy' \
    'Type=Application' \
    'Categories=Development;Security;' \
    'Terminal=false' \
    > /usr/share/applications/zaproxy.desktop; \
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
