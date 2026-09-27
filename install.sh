#!/bin/bash
set -e

# Define variables
APP_NAME="CopyStack"
REPO="sharky-3/CopyStack"
LATEST_URL="https://github.com/$REPO/releases/latest/download/$APP_NAME.zip"
INSTALL_DIR="/Applications"

echo "Downloading $APP_NAME..."
curl -L -o /tmp/$APP_NAME.zip "$LATEST_URL"

echo "Installing to $INSTALL_DIR..."
unzip -q /tmp/$APP_NAME.zip -d /tmp/
rm -rf "$INSTALL_DIR/$APP_NAME.app"
mv /tmp/$APP_NAME.app "$INSTALL_DIR/"

# Cleanup
rm /tmp/$APP_NAME.zip

echo "$APP_NAME successfully installed to your Applications folder!"
