#!/usr/bin/env bash
#
# build-xcframework.sh
#
# Regenerates the RouteKit binary distribution:
#   1. Syncs RouteInterface source from the dev package into this package.
#   2. Compiles the Route engine as module `RouteBinary` with library evolution,
#      for iOS device + iOS simulator + Mac Catalyst.
#   3. Assembles Artifacts/RouteBinary.xcframework.
#   4. Zips it and prints the SPM checksum (for remote hosting).
#
# The Route SOURCE is read from the dev package and never copied into this
# distribution package — only the compiled binary is published here.
#
# Usage:  Scripts/build-xcframework.sh
#
set -euo pipefail

# --- Paths -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"             # Xc/RouteKit-Distribution
DEV_ROOT="$(cd "${DIST_ROOT}/../../RouteKit" && pwd)"   # source-of-truth dev package (Packages/RouteKit)

MODULE_NAME="RouteBinary"                              # binary module name
BUILD_DIR="${DIST_ROOT}/.xcbuild"                     # scratch (git-ignored)
BUILD_PKG="${BUILD_DIR}/RouteBinaryBuild"             # temp SwiftPM package
ARTIFACTS_DIR="${DIST_ROOT}/Artifacts"
XCFRAMEWORK="${ARTIFACTS_DIR}/${MODULE_NAME}.xcframework"

echo "▸ Dev package:          ${DEV_ROOT}"
echo "▸ Distribution package: ${DIST_ROOT}"

# --- 1. Sync the public interface source -------------------------------------
echo "▸ Syncing RouteInterface source…"
rsync -a --delete \
    "${DEV_ROOT}/Sources/RouteInterface/" \
    "${DIST_ROOT}/Sources/RouteInterface/"

# --- 2. Assemble a throwaway build package ------------------------------------
# It compiles the Route sources under the module name `RouteBinary` (the dev
# target is named `Route`; renaming the module here avoids a clash with the
# distribution `Route` shim). RouteInterface is compiled alongside because the
# engine imports it, but it is NOT part of the shipped xcframework.
echo "▸ Preparing build package…"
rm -rf "${BUILD_PKG}"
mkdir -p "${BUILD_PKG}/Sources/${MODULE_NAME}"
mkdir -p "${BUILD_PKG}/Sources/RouteInterface"

rsync -a "${DEV_ROOT}/Sources/Route/"          "${BUILD_PKG}/Sources/${MODULE_NAME}/"
rsync -a "${DEV_ROOT}/Sources/RouteInterface/" "${BUILD_PKG}/Sources/RouteInterface/"

cat > "${BUILD_PKG}/Package.swift" <<EOF
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "${MODULE_NAME}",
    platforms: [.iOS(.v14), .macCatalyst(.v14)],
    products: [
        .library(name: "${MODULE_NAME}", type: .dynamic, targets: ["${MODULE_NAME}"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kaVish2214/UtilityKit", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/kaVish2214/AuthSessionKit", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "RouteInterface",
            dependencies: [
                .product(name: "DependencyResolver", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ]
        ),
        .target(
            name: "${MODULE_NAME}",
            dependencies: [
                "RouteInterface",
                .product(name: "DependencyResolver", package: "UtilityKit"),
                .product(name: "SwiftConcurrency", package: "UtilityKit"),
                .product(name: "AuthSessionInterface", package: "AuthSessionKit"),
            ],
            // Library evolution is scoped to THIS target only — never a global
            // BUILD_LIBRARY_FOR_DISTRIBUTION. Globally, source dependencies would
            // also be forced to emit textual interfaces, and deps whose module name
            // equals a contained type name (UtilityKit's \`MultiCastDelegate\`) emit
            // an interface the compiler then fails to verify — a hard archive error
            // that SWIFT_VERIFY_EMITTED_MODULE_INTERFACE=NO does not suppress.
            // Scoping evolution here keeps the dependency graph out of it.
            // \`-emit-module-interface\` writes RouteBinary.swiftinterface next to the
            // .swiftmodule; the build script copies that module dir into the framework.
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution", "-emit-module-interface"])
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
EOF

# --- 3. Archive one framework per platform slice ------------------------------
ARCHIVE_DIR="${BUILD_DIR}/archives"
rm -rf "${ARCHIVE_DIR}"
mkdir -p "${ARCHIVE_DIR}"

# Pretty-print with xcbeautify if available, otherwise pass through raw.
PRETTY=(cat)
command -v xcbeautify >/dev/null 2>&1 && PRETTY=(xcbeautify)

BPP="${BUILD_DIR}/DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/${MODULE_NAME}/BuildProductsPath"

# build_slice <destination> <archive-name> <config-suffix>
#
# Archives one platform slice, then copies the emitted <MODULE_NAME>.swiftmodule
# (containing the binary module + the resilient .swiftinterface) into the
# framework's Modules/ directory. Library evolution is enabled per-target via the
# generated manifest, so the archive itself does NOT set
# BUILD_LIBRARY_FOR_DISTRIBUTION — that global setting would drag every source
# dependency into interface emission and trip the MultiCastDelegate verifier bug.
# The trade-off is that the swiftmodule is not auto-packaged into the framework,
# so we copy it in ourselves.
build_slice () {
    local destination="$1"
    local name="$2"
    local config="$3"
    echo "▸ Archiving ${name} (${destination})…"
    set -o pipefail
    xcodebuild archive \
        -workspace "${BUILD_PKG}" \
        -scheme "${MODULE_NAME}" \
        -destination "${destination}" \
        -archivePath "${ARCHIVE_DIR}/${name}.xcarchive" \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        SKIP_INSTALL=NO \
        | "${PRETTY[@]}"

    # Package the Swift module into the framework bundle.
    local fw="${ARCHIVE_DIR}/${name}.xcarchive/Products/usr/local/lib/${MODULE_NAME}.framework"
    local module_src="${BPP}/Release-${config}/${MODULE_NAME}.swiftmodule"
    if [[ ! -d "${module_src}" ]]; then
        # Fallback: locate it if the config directory name differs.
        module_src="$(find "${BPP}" -type d -name "${MODULE_NAME}.swiftmodule" | head -1)"
    fi
    echo "▸ Embedding module: ${module_src}"
    rm -rf "${fw}/Modules"
    mkdir -p "${fw}/Modules"
    cp -R "${module_src}" "${fw}/Modules/${MODULE_NAME}.swiftmodule"

    # The .swiftinterface is emitted into the per-arch intermediates rather than the
    # product module dir, so copy it in alongside each .swiftmodule. create-xcframework
    # requires a .swiftinterface per slice for a Swift framework.
    local dst_mod="${fw}/Modules/${MODULE_NAME}.swiftmodule"
    local objects="${BUILD_DIR}/DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/${MODULE_NAME}/IntermediateBuildFilesPath/${MODULE_NAME}.build/Release-${config}/${MODULE_NAME}.build/Objects-normal"
    local mod triple arch iface
    for mod in "${dst_mod}"/*.swiftmodule; do
        triple="$(basename "${mod}" .swiftmodule)"   # e.g. arm64-apple-ios-simulator
        arch="${triple%%-*}"                         # e.g. arm64
        iface="${objects}/${arch}/${MODULE_NAME}.swiftinterface"
        if [[ -f "${iface}" ]]; then
            cp "${iface}" "${dst_mod}/${triple}.swiftinterface"
        else
            echo "⚠︎  missing .swiftinterface for ${triple} (looked in ${iface})"
        fi
    done
}

build_slice "generic/platform=iOS"                          "ios"       "iphoneos"
build_slice "generic/platform=iOS Simulator"                "ios-sim"   "iphonesimulator"
build_slice "generic/platform=macOS,variant=Mac Catalyst"   "catalyst"  "maccatalyst"

# --- 4. Assemble the xcframework ---------------------------------------------
echo "▸ Creating xcframework…"
rm -rf "${XCFRAMEWORK}"
mkdir -p "${ARTIFACTS_DIR}"

# SwiftPM installs archived frameworks under usr/local/lib (not Library/Frameworks).
fw_path () { echo "${ARCHIVE_DIR}/$1.xcarchive/Products/usr/local/lib/${MODULE_NAME}.framework"; }

xcodebuild -create-xcframework \
    -framework "$(fw_path ios)" \
    -framework "$(fw_path ios-sim)" \
    -framework "$(fw_path catalyst)" \
    -output "${XCFRAMEWORK}"

# --- 5. Zip + checksum (for remote hosting) ----------------------------------
ZIP_PATH="${ARTIFACTS_DIR}/${MODULE_NAME}.xcframework.zip"
echo "▸ Zipping for distribution…"
( cd "${ARTIFACTS_DIR}" && rm -f "${ZIP_PATH}" && zip -qry "${ZIP_PATH}" "${MODULE_NAME}.xcframework" )

echo ""
echo "✅ Done."
echo "   xcframework: ${XCFRAMEWORK}"
echo "   zip:         ${ZIP_PATH}"
echo "   checksum:    $(cd "${DIST_ROOT}" && swift package compute-checksum "${ZIP_PATH}")"
echo ""
echo "   • Local distribution: keep the .binaryTarget(path:) in Package.swift."
echo "   • Remote distribution: upload the zip, then switch Package.swift to"
echo "     .binaryTarget(url:checksum:) using the checksum above."
