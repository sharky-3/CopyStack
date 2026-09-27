#!/bin/bash
set -e

APP_NAME="CopyStack"
REPO="sharky-3/CopyStack"
LATEST_URL="https://github.com/$REPO/releases/latest/download/$APP_NAME.zip"
INSTALL_DIR="/Applications"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading $APP_NAME..."
curl -fsSL -o "$TMP_DIR/$APP_NAME.zip" "$LATEST_URL"

echo "Unpacking..."
unzip -q "$TMP_DIR/$APP_NAME.zip" -d "$TMP_DIR"

APP_PATH=$(find "$TMP_DIR" -maxdepth 2 -name "$APP_NAME.app" -print -quit)

if [ -z "$APP_PATH" ]; then
  echo "Error: Could not find $APP_NAME.app in downloaded archive."
  exit 1
fi

echo "Installing $APP_NAME to $INSTALL_DIR (may prompt for admin password)..."
sudo rm -rf "$INSTALL_DIR/$APP_NAME.app"
sudo mv "$APP_PATH" "$INSTALL_DIR/"

sudo xattr -rd com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo "$APP_NAME successfully installed to $INSTALL_DIR!"
