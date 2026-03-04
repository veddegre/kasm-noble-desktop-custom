FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# Ensure Ubuntu repos include universe and multiverse
RUN set -eux; \
  if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
    sed -i 's/^Components: .*/Components: main restricted universe multiverse/' /etc/apt/sources.list.d/ubuntu.sources || true; \
  fi; \
  if [ ! -s /etc/apt/sources.list ]; then \
    printf '%s\n' \
      'deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse' \
      'deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse' \
      'deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse' \
      > /etc/apt/sources.list; \
  fi; \
  apt-get update

# Base utilities + security tools + browser dependencies
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
    jq \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-color-emoji \
    libu2f-udev \
    xclip \
    unzip \
    zip \
    p7zip-full \
    default-jre \
    nmap \
    libnss3 \
    libgtk-3-0t64 \
    libgbm1 \
    libdrm2 \
    libxkbcommon0 \
    libxss1 \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatspi2.0-0t64 \
    libcups2t64 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxfixes3 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libcairo2 \
    libglib2.0-0 \
    libxrender1 \
    xdg-utils \
  ; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# Install Microsoft Edge
RUN set -eux; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/microsoft-edge.gpg; \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
    > /etc/apt/sources.list.d/microsoft-edge.list; \
  apt-get update; \
  apt-get install -y --no-install-recommends microsoft-edge-stable; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# Patch Edge launcher for container environment
RUN sed -i 's|Exec=.*|Exec=/usr/bin/microsoft-edge-stable --no-sandbox --disable-dev-shm-usage %U|g' \
  /usr/share/applications/microsoft-edge.desktop

# Install Burp Suite Community (latest at build time)
RUN set -eux; \
  curl -fsSL -L "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
    -o /tmp/burpsuite.sh; \
  chmod +x /tmp/burpsuite.sh; \
  /tmp/burpsuite.sh -q -dir /opt/burpsuite; \
  rm -f /tmp/burpsuite.sh

# Wrapper so Burp always runs correctly in containers
RUN printf '%s\n' \
  '#!/bin/bash' \
  'exec /opt/burpsuite/BurpSuiteCommunity --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"' \
  > /usr/local/bin/burpsuite && chmod +x /usr/local/bin/burpsuite

# Force Burp embedded browser to use container-safe flags
RUN set -eux; \
  CHROME_PATH="$(find /opt/burpsuite/burpbrowser -maxdepth 4 -type f -name chrome -perm -111 | head -n 1)"; \
  test -n "$CHROME_PATH"; \
  mv "$CHROME_PATH" "${CHROME_PATH}.real"; \
  printf '%s\n' \
    '#!/bin/sh' \
    'DIR="$(cd "$(dirname "$0")" && pwd)"' \
    'exec "$DIR/chrome.real" --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"' \
    > "$CHROME_PATH"; \
  chmod +x "$CHROME_PATH"

# Install OWASP ZAP weekly automatically
RUN set -eux; \
  ZAP_URL="$(curl -fsSL https://api.github.com/repos/zaproxy/zaproxy/releases \
    | jq -r '[.[] | select(.prerelease==true) | .assets[]? | select(.name | test("^ZAP_WEEKLY_D-.*\\.zip$")) | .browser_download_url][0]')"; \
  test -n "$ZAP_URL" -a "$ZAP_URL" != "null"; \
  mkdir -p /opt/zap; \
  curl -fsSL -L "$ZAP_URL" -o /tmp/zap.zip; \
  unzip -q /tmp/zap.zip -d /opt/zap; \
  rm -f /tmp/zap.zip; \
  ln -sf /opt/zap/ZAP_*/zap.sh /usr/local/bin/zaproxy

# Desktop launchers
RUN printf '%s\n' \
  '[Desktop Entry]' \
  'Name=Burp Suite Community' \
  'Exec=/usr/local/bin/burpsuite' \
  'Type=Application' \
  'Categories=Development;Security;' \
  'Terminal=false' \
  > /usr/share/applications/burpsuite.desktop && \
printf '%s\n' \
  '[Desktop Entry]' \
  'Name=OWASP ZAP' \
  'Exec=/usr/local/bin/zaproxy' \
  'Type=Application' \
  'Categories=Development;Security;' \
  'Terminal=false' \
  > /usr/share/applications/zaproxy.desktop && \
printf '%s\n' \
  '[Desktop Entry]' \
  'Name=Nmap Scanner' \
  'Exec=x-terminal-emulator -e nmap --help' \
  'Type=Application' \
  'Categories=Security;' \
  'Terminal=false' \
  > /usr/share/applications/nmap.desktop

# Passwordless sudo
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
