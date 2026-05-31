#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# build-macos-app.sh
# Wraps a .NET single-file publish into a proper macOS .app bundle.
#
# Usage:
#   ./build-macos-app.sh <publish-dir> <arch> [--dmg]
#
# Arguments:
#   publish-dir   Path to the dotnet publish output directory (e.g. ./publish-arm64)
#   arch          Target architecture: arm64 or x64
#   --dmg         (optional) Also create a DMG disk image
#
# Example:
#   dotnet publish Portramatic -r osx-arm64 -c Release \
#       -p:PublishReadyToRun=true --self-contained \
#       -p:PublishSingleFile=true -p:DebugType=embedded \
#       -p:IncludeAllContentForSelfExtract=true \
#       -o ./publish-arm64
#
#   ./build-macos-app.sh ./publish-arm64 arm64 --dmg
# =============================================================================

# ----- Configuration ---------------------------------------------------------

APP_NAME="Portramatic"
BUNDLE_ID="com.wabbajack.portramatic"
EXECUTABLE_NAME="Portramatic"
MIN_MACOS_VERSION="10.15"
ICON_NAME="AppIcon.icns"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"

# ----- Parse arguments -------------------------------------------------------

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <publish-dir> <arch> [--dmg]" >&2
    echo "  publish-dir   Path to the dotnet publish output" >&2
    echo "  arch          arm64 or x64" >&2
    echo "  --dmg         (optional) Also create a DMG" >&2
    exit 1
fi

PUBLISH_DIR="$(cd "$1" && pwd)"
ARCH="$2"
MAKE_DMG=false

if [[ "${3:-}" == "--dmg" ]]; then
    MAKE_DMG=true
fi

if [[ "$ARCH" != "arm64" && "$ARCH" != "x64" ]]; then
    echo "Error: architecture must be 'arm64' or 'x64', got '$ARCH'" >&2
    exit 1
fi

# ----- Determine version from git --------------------------------------------

VERSION="$(git -C "$PROJECT_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
    VERSION="1.0.0"
fi
# Strip leading 'v' if present
VERSION="${VERSION#v}"
# If the tag is just a major version like "1.0", normalize to "1.0.0"
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    VERSION="${VERSION}.0"
fi

echo "=== Building ${APP_NAME}.app ==="
echo "  Publish dir : ${PUBLISH_DIR}"
echo "  Architecture: ${ARCH}"
echo "  Version     : ${VERSION}"
echo ""

# ----- Output paths ----------------------------------------------------------

OUTPUT_DIR="${SCRIPT_DIR}/dist"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# ----- Clean previous build --------------------------------------------------

if [[ -d "$APP_BUNDLE" ]]; then
    echo "Removing previous .app bundle..."
    rm -rf "$APP_BUNDLE"
fi

# ----- Create bundle structure -----------------------------------------------

echo "Creating .app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# ----- Copy published files into Resources -----------------------------------

# Place the actual published files inside Resources/App (hidden from the user)
APP_RESOURCES="${RESOURCES_DIR}/App"
mkdir -p "$APP_RESOURCES"

echo "Copying published files..."
rsync -a --delete "${PUBLISH_DIR}/" "${APP_RESOURCES}/"

# Find the main executable in the publish output
BINARY_NAME=""
if [[ -f "${APP_RESOURCES}/${EXECUTABLE_NAME}" ]]; then
    BINARY_NAME="${EXECUTABLE_NAME}"
elif [[ -f "${APP_RESOURCES}/${EXECUTABLE_NAME}.dll" ]]; then
    BINARY_NAME="${EXECUTABLE_NAME}.dll"
else
    # Try to find the main executable (the one without .dll that is +x)
    BINARY_NAME="$(find "${APP_RESOURCES}" -maxdepth 1 -type f -perm +111 ! -name '*.dll' ! -name '*.so' ! -name '*.dylib' | head -1)"
    if [[ -z "$BINARY_NAME" ]]; then
        echo "Error: Could not find main executable in ${PUBLISH_DIR}" >&2
        exit 1
    fi
    BINARY_NAME="$(basename "$BINARY_NAME")"
fi

echo "  Main binary : ${BINARY_NAME}"

# Make sure the binary is executable
chmod +x "${APP_RESOURCES}/${BINARY_NAME}" 2>/dev/null || true

# ----- Create launch script --------------------------------------------------

echo "Creating launch script..."
cat > "${MACOS_DIR}/${EXECUTABLE_NAME}" << LAUNCH_EOF
#!/bin/bash
# Launch script for ${APP_NAME}
# Sets up the environment and runs the .NET single-file binary.

# Resolve the directory where this script lives
SELF="\$(cd "\$(dirname "\$0")" && pwd)"
RESOURCES="\${SELF}/../Resources"
APP_DIR="\${RESOURCES}/App"

# Export library path so native deps resolve correctly
export DYLD_FALLBACK_LIBRARY_PATH="\${APP_DIR}:\${DYLD_FALLBACK_LIBRARY_PATH:-}"

# Set runtime identifier for any Avalonia/Skia detection
export DOTNET_RUNTIME_IDENTIFIER="osx-${ARCH}"

# Run the actual binary
exec "\${APP_DIR}/${BINARY_NAME}" "\$@"
LAUNCH_EOF

chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"

# ----- Handle app icon -------------------------------------------------------

ICON_SOURCE=""
# Check for .icns in project Assets
if [[ -f "${PROJECT_DIR}/Portramatic/Assets/${ICON_NAME}" ]]; then
    ICON_SOURCE="${PROJECT_DIR}/Portramatic/Assets/${ICON_NAME}"
# Check for .icns at project root
elif [[ -f "${PROJECT_DIR}/${ICON_NAME}" ]]; then
    ICON_SOURCE="${PROJECT_DIR}/${ICON_NAME}"
fi

ICON_FILE_REF=""
if [[ -n "$ICON_SOURCE" ]]; then
    echo "Copying icon: ${ICON_SOURCE}"
    cp "$ICON_SOURCE" "${RESOURCES_DIR}/${ICON_NAME}"
    ICON_FILE_REF="<key>CFBundleIconFile</key>
    <string>${ICON_NAME}</string>"
else
    echo "  No .icns icon found; skipping icon. To add one, place ${ICON_NAME} in Portramatic/Assets/"
    ICON_FILE_REF=""
fi

# ----- Create Info.plist -----------------------------------------------------

echo "Generating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS_VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    ${ICON_FILE_REF}
</dict>
</plist>
PLIST_EOF

# ----- Create PkgInfo --------------------------------------------------------

printf "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# ----- Verify bundle structure -----------------------------------------------

echo ""
echo "Bundle structure:"
find "$APP_BUNDLE" -maxdepth 3 -not -path "*/App/*" | sort | sed "s|${APP_BUNDLE}|${APP_NAME}.app|"

echo ""
echo "=== ${APP_NAME}.app created successfully ==="
echo "  Path:    ${APP_BUNDLE}"
echo "  Version: ${VERSION}"
echo "  Arch:    ${ARCH}"
echo ""

# ----- Clean extended attributes (required for codesign) ----------------------

xattr -cr "$APP_BUNDLE" 2>/dev/null || true
find "$APP_BUNDLE" -name "._*" -delete 2>/dev/null || true

# ----- Code signing (adhoc) ---------------------------------------------------

echo "Signing .app bundle..."
# Sign inner binary first (needed for .NET single-file bundles)
codesign --force -s - "${APP_RESOURCES}/${BINARY_NAME}" 2>/dev/null || true
# Sign any dylibs
find "$APP_BUNDLE" -name "*.dylib" -exec codesign --force -s - {} \; 2>/dev/null || true
# Sign the bundle (use --no-strict because .NET single-file bundles have embedded resources)
codesign --force --no-strict -s - "$APP_BUNDLE" 2>&1 || {
    echo "Warning: Ad-hoc code signing failed. The app will still run but may show a Gatekeeper warning." >&2
    echo "To fix, run: System Preferences → Privacy & Security → click 'Open Anyway'" >&2
}
echo ""

# ----- Optional: Create DMG --------------------------------------------------

if [[ "$MAKE_DMG" == true ]]; then
    if ! command -v hdiutil &>/dev/null; then
        echo "Warning: hdiutil not found; skipping DMG creation." >&2
    else
        DMG_NAME="${APP_NAME}-${VERSION}-macos-${ARCH}.dmg"
        DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

        echo "Creating DMG: ${DMG_NAME}..."

        # Remove existing DMG if present
        rm -f "$DMG_PATH"

        # Create a temporary staging directory
        STAGING="$(mktemp -d)"
        cp -a "$APP_BUNDLE" "${STAGING}/"

        # Create an Applications symlink for drag-and-drop install
        ln -s /Applications "${STAGING}/Applications"

        # Create the DMG
        hdiutil create -volname "${APP_NAME}" \
            -srcfolder "${STAGING}" \
            -ov -format UDZO \
            "$DMG_PATH"

        # Clean up staging
        rm -rf "${STAGING}"

        echo ""
        echo "=== DMG created successfully ==="
        echo "  Path: ${DMG_PATH}"
        echo ""
    fi
fi

echo "Done."
