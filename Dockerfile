FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-daily

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

# Base utilities + security tools + browser dependencies + flatpak deps + icon tooling + xfce terminal
RUN set -eux; \
  apt-get install -y --no-install-recommends \
    sudo \
    dnsutils \
    xfce4-whiskermenu-plugin \
    xfce4-terminal \
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
    \
    # Flatpak + desktop integration (portals)
    flatpak \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    \
    # Icon + desktop entry utilities
    librsvg2-bin \
    desktop-file-utils \
    \
    # Your existing GUI/lib deps
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
  \
  # Add Flathub system-wide (so all users in the container can see it)
  flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo; \
  \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

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

# --- Icons for desktop launchers (ZAP only; no Nmap launcher) ---
RUN set -eux; \
  install -d /usr/share/icons/hicolor/256x256/apps; \
  \
  # OWASP ZAP logo (SVG -> PNG)
  curl -fsSL -L "https://commons.wikimedia.org/wiki/Special:FilePath/OWASP%20ZAP%20logo.svg" \
    -o /tmp/owasp-zap.svg; \
  rsvg-convert -w 256 -h 256 /tmp/owasp-zap.svg \
    -o /usr/share/icons/hicolor/256x256/apps/zaproxy.png; \
  rm -f /tmp/owasp-zap.svg; \
  \
  # Update caches (best-effort)
  gtk-update-icon-cache -f /usr/share/icons/hicolor || true; \
  update-desktop-database /usr/share/applications || true

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
  'Icon=zaproxy' \
  'Type=Application' \
  'Categories=Development;Security;' \
  'Terminal=false' \
  > /usr/share/applications/zaproxy.desktop && \
update-desktop-database /usr/share/applications || true

# --- Remove unwanted apps (present in the base image) ---
RUN set -eux; \
  \
  # APT removals (if present)
  apt-get update; \
  apt-get purge -y --auto-remove \
    thunderbird \
    nextcloud-desktop \
    telegram-desktop \
    signal-desktop \
    zoom \
    sublime-text \
  || true; \
  \
  # SNAP removals (if present)
  if command -v snap >/dev/null 2>&1; then \
    snap remove --purge thunderbird 2>/dev/null || true; \
    snap remove --purge nextcloud-desktop 2>/dev/null || true; \
    snap remove --purge telegram-desktop 2>/dev/null || true; \
    snap remove --purge signal-desktop 2>/dev/null || true; \
    snap remove --purge zoom-client 2>/dev/null || true; \
  fi; \
  \
  # FLATPAK removals (if present)
  if command -v flatpak >/dev/null 2>&1; then \
    flatpak uninstall -y --system --noninteractive \
      us.zoom.Zoom \
      org.signal.Signal \
      org.telegram.desktop \
      com.sublimetext.three \
      com.sublimetext.four \
      com.nextcloud.desktopclient.nextcloud \
      org.mozilla.Thunderbird \
    || true; \
  fi; \
  \
  # Remove leftover desktop launchers so they don't show in menus
  rm -f \
    /usr/share/applications/*zoom*.desktop \
    /usr/share/applications/*sublime*.desktop \
    /usr/share/applications/*signal*.desktop \
    /usr/share/applications/*telegram*.desktop \
    /usr/share/applications/*nextcloud*.desktop \
    /usr/share/applications/*thunderbird*.desktop \
  || true; \
  \
  update-desktop-database /usr/share/applications || true; \
  \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

# Passwordless sudo
RUN echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kasm-user
