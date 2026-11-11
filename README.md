# turtlebot2_ros2 (Jazzy)
Fork of [idorobotics/turtlebot2_ros2](https://github.com/idorobotics/turtlebot2_ros2), updated for **ROS 2 Jazzy on Ubuntu 24.04**, for the Kobuki [TurtleBot 2 platform](https://www.turtlebot.com/). Teleoperation using the keyboard and a joystick controller is demonstrated.
For a comprehensive guide to the original Humble setup, see [idorobotics.com](https://idorobotics.com/2024/02/20/ros2-on-kobuki-turtlebot/).

There are no Jazzy binaries for the Kobuki driver (`ros-jazzy-kobuki-node` is not in apt), so it is built from source. The submodules are pinned to commits known to build on Jazzy.

## Setup
Requires ROS 2 Jazzy (`ros-jazzy-desktop` or similar) already installed.

```bash
mkdir -p ~/ros2_ws/src && cd ~/ros2_ws/src
git clone --recurse-submodules https://github.com/lkaixian/turtlebot2_ros2_jazzy.git turtlebot2_ros2
conda deactivate   # if you use conda: it breaks the ROS 2 build
./turtlebot2_ros2/setup.sh
```

`setup.sh` installs the apt/rosdep dependencies, installs the udev rule that creates `/dev/kobuki`, adds you to `dialout`, and builds with `colcon`. It uses `sudo` for the apt and udev steps. Log out and back in afterwards so the `dialout` group takes effect.

### Notes on the build
- **Conda:** with conda active, CMake picks up conda's Python and fails with `No module named 'catkin_pkg'`. `setup.sh` refuses to run while conda is active, and passes `-DPython3_EXECUTABLE=/usr/bin/python3`.
- **`-Werror`:** the `ecl_*` packages build with `-Werror`, which fails on GCC 13 over a harmless `-Woverloaded-virtual` warning. `setup.sh` passes `-DCMAKE_CXX_FLAGS="-Wno-error=overloaded-virtual"` so the warning is no longer fatal. If you build by hand, pass the same flag. Remaining compiler and CMake warnings during the build are expected.

## Testing
Check the device exists, then start the driver:
```bash
ls -l /dev/kobuki
source ~/ros2_ws/install/setup.bash
ros2 launch kobuki_node kobuki_node-launch.py
```
If the port cannot be opened: `ros2 launch kobuki_node kobuki_node-launch.py device_port:=/dev/kobuki`.

In a second terminal (source the workspace again), drive with the keyboard:
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=commands/velocity
```
Or with a joystick:
```bash
ros2 launch teleop_twist_joy teleop-launch.py config_filepath:='/path/to/ros2_ws/src/turtlebot2_ros2/configs/pdp.config.yaml' joy_vel:='commands/velocity'
```
For a different joystick like PS3: `ros2 launch teleop_twist_joy teleop-launch.py joy_config:='ps3' joy_vel:='commands/velocity'`

The Kobuki stops if velocity commands stop arriving, so publish continuously. Useful topics: `/odom`, `/events/bumper`, `/events/cliff`, `/sensors/core`.

Both terminals must use the same `ROS_DOMAIN_ID` (and `ROS_LOCALHOST_ONLY` setting).
