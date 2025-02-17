#!/bin/sh

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "Installing Steam Deck Plugin Loader nightly..."

USER_DIR="$(getent passwd $SUDO_USER | cut -d: -f6)"
HOMEBREW_FOLDER="${USER_DIR}/homebrew"

# Create folder structure
rm -rf ${HOMEBREW_FOLDER}/services
sudo -u $SUDO_USER mkdir -p "${HOMEBREW_FOLDER}/services"
sudo -u $SUDO_USER mkdir -p "${HOMEBREW_FOLDER}/plugins"

# Download latest nightly build and install it
rm -rf /tmp/plugin_loader
mkdir -p /tmp/plugin_loader
curl -L https://nightly.link/SteamDeckHomebrew/PluginLoader/workflows/build/main/Plugin%20Loader.zip --output /tmp/plugin_loader/PluginLoader.zip
unzip /tmp/plugin_loader/PluginLoader.zip -d /tmp/plugin_loader
cp /tmp/plugin_loader/PluginLoader ${HOMEBREW_FOLDER}/services/PluginLoader
rm -rf /tmp/plugin_loader
chmod +x ${HOMEBREW_FOLDER}/services/PluginLoader

systemctl --user stop plugin_loader 2> /dev/null
systemctl --user disable plugin_loader 2> /dev/null
rm -f ${USER_DIR}/.config/systemd/user/plugin_loader.service

systemctl stop plugin_loader 2> /dev/null
systemctl disable plugin_loader 2> /dev/null
rm -f /etc/systemd/system/plugin_loader.service

cat > /etc/systemd/system/plugin_loader.service <<- EOM
[Unit]
Description=SteamDeck Plugin Loader

[Service]
Type=simple
User=root
Restart=always

ExecStart=${HOMEBREW_FOLDER}/services/PluginLoader
WorkingDirectory=${HOMEBREW_FOLDER}/services
Environment=PLUGIN_PATH=${HOMEBREW_FOLDER}/plugins

[Install]
WantedBy=multi-user.target
EOM
systemctl daemon-reload
systemctl start plugin_loader
systemctl enable plugin_loader
