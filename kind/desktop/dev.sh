package gcc gdb rust make ninja cmake

write -au .config/dropin/env << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF
