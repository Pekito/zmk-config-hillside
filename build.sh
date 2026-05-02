#!/usr/bin/env bash
set -e

BOARD="nice_nano//zmk"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="${SCRIPT_DIR}/.zmk-workspace"
IMAGE=zmkfirmware/zmk-build-arm:4.1

mkdir -p "${WORKSPACE}"

# First run: initialize west workspace and fetch ZMK + Zephyr (~1GB, takes a few minutes)
if [ ! -d "${WORKSPACE}/.west" ]; then
  echo "==> Initializing ZMK workspace (first run, this will take a while)..."
  docker run --rm \
    -v "${WORKSPACE}:/workspace" \
    -v "${SCRIPT_DIR}/config:/workspace/config:ro" \
    -w /workspace \
    "${IMAGE}" \
    bash -c "west init -l config && west update"
fi

echo "==> Building hillside46 (left + right)..."
docker run --rm \
  -v "${WORKSPACE}:/workspace" \
  -v "${SCRIPT_DIR}/config:/workspace/config:ro" \
  "${IMAGE}" \
  bash -c "
    set -e
    # Register Zephyr so CMake can find it
    cmake -P /workspace/zephyr/share/zephyr-package/cmake/zephyr_export.cmake

    cd /workspace/zmk
    west build -s app -d /workspace/build/left  -b '${BOARD}' -- -DSHIELD=hillside46_left  -DZMK_CONFIG=/workspace/config
    west build -s app -d /workspace/build/right -b '${BOARD}' -- -DSHIELD=hillside46_right -DZMK_CONFIG=/workspace/config
  "

mkdir -p "${SCRIPT_DIR}/firmware"
cp "${WORKSPACE}/build/left/zephyr/zmk.uf2"  "${SCRIPT_DIR}/firmware/hillside46_left.uf2"
cp "${WORKSPACE}/build/right/zephyr/zmk.uf2" "${SCRIPT_DIR}/firmware/hillside46_right.uf2"

echo ""
echo "Done! Flash these files:"
echo "  Left:  firmware/hillside46_left.uf2"
echo "  Right: firmware/hillside46_right.uf2"
