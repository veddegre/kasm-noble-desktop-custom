FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly

USER root

# --- APT repo hardening (make sure universe/multiverse exist) ---
# Some base images ship with minimal/modified sources; this forces standard Noble repos.
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

# --- Base utilities + XFCE Whisker + browser compat + security basics ---
RUN set -eux; \
  apt-get update; \
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
    libnss3 \
    libgtk-3-0t64 \
    nmap \
  ; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# --- Microsoft Edge (official repo) ---
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

# --- Burp Suite Community (latest at build time via redirect) ---
RUN set -eux; \
  curl -fsSL -L "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
    -o /tmp/burpsuite.sh; \
  chmod +x /tmp/burpsuite.sh; \
  /tmp/burpsuite.sh -q -dir /opt/burpsuite; \
  ln -sf /opt/burpsuite/BurpSuiteCommunity /usr/local/bin/burpsuite; \
  rm -f /tmp/burpsuite.sh

# --- OWASP ZAP (download latest weekly from GitHub Releases API) ---
# This avoids relying on the 'zaproxy' apt package being present/enabled.
RUN set -eux; \
  ZAP_URL="$(curl -fsSL https://api.github.com/repos/zaproxy/zaproxy/releases \
    | jq -r '[.[] | select(.prerelease==true) | .assets[]? | select(.name | test("^ZAP_WEEKLY_D-.*\\.zip$")) | .browser_download_url][0]')"; \
  test -n "$ZAP_URL" -a "$ZAP_URL" != "null"; \
  echo "Downloading ZAP from: $ZAP_URL"; \
  mkdir -p /opt/zap; \
  curl -fsSL -L "$ZAP_URL" -o /tmp/zap.zip; \
  unzip -q /tmp/zap.zip -d /opt/zap; \
  rm -f /tmp/zap.zip; \
  ln -sf /opt/zap/ZAP_*/zap.sh /usr/local/bin/zaproxy

# --- Desktop launchers (Burp, ZAP, Nmap) ---
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
    'Exec=/usr/local/bin/zaproxy' \
    'Type=Application' \
    'Categories=Development;Security;' \
    'Terminal=false' \
    > /usr/share/applications/zaproxy.desktop; \
  printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Nmap (Help)' \
    'Exec=x-terminal-emulator -e nmap --help' \
    'Type=Application' \
    'Categories=Security;' \
    'Terminal=false' \
    > /usr/share/applications/nmap.desktop

# Passwordless sudo for kasm-user
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
