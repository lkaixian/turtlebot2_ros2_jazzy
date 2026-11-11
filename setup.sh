#!/usr/bin/env bash
# One-shot setup for the Kobuki TurtleBot 2 on ROS 2 Jazzy (Ubuntu 24.04).
# Run from the root of your colcon workspace's src/turtlebot2_ros2 checkout:
#   ./setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_DIR="$(cd "$REPO_DIR/../.." && pwd)"

if [[ -n "${CONDA_PREFIX:-}" ]]; then
  echo "Conda is active ($CONDA_PREFIX). Run 'conda deactivate' first: it breaks the ROS 2 build." >&2
  exit 1
fi

source /opt/ros/jazzy/setup.bash

echo "==> Fetching submodules"
git -C "$REPO_DIR" submodule update --init --recursive

echo "==> Installing apt dependencies (sudo)"
sudo apt-get update
sudo apt-get install -y \
  ros-jazzy-ecl-build ros-jazzy-ecl-license ros-jazzy-ros-testing \
  ros-jazzy-sophus ros-jazzy-teleop-twist-keyboard ros-jazzy-teleop-twist-joy \
  python3-colcon-common-extensions python3-rosdep

echo "==> Installing remaining rosdep dependencies"
rosdep install -i --from-path "$REPO_DIR" --rosdistro jazzy -y

echo "==> Installing udev rule for /dev/kobuki (sudo)"
sudo cp "$REPO_DIR/udev/60-kobuki.rules" /etc/udev/rules.d/60-kobuki.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG dialout "$USER"

# The ecl packages build with -Werror, which fails on GCC 13 over a harmless
# -Woverloaded-virtual warning. Keep the warning but make it non-fatal.
echo "==> Building"
cd "$WS_DIR"
colcon build --symlink-install --executor sequential \
  --packages-up-to kobuki_node \
  --cmake-args -DPython3_EXECUTABLE=/usr/bin/python3 -Wno-dev \
  -DCMAKE_CXX_FLAGS="-Wno-error=overloaded-virtual"

echo
echo "Done. In every new terminal:  source $WS_DIR/install/setup.bash"
echo "Then:  ros2 launch kobuki_node kobuki_node-launch.py"
