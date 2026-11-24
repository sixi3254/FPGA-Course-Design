
# ==========================================================
# FPGA Motion System
# Target Board: Digilent Nexys A7-100T
# ==========================================================

# 获取工程根目录
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR [file normalize "$SCRIPT_DIR/.."]

# ----------------------------------------------------------
# 1. 工程基本信息
# ----------------------------------------------------------

set PROJECT_NAME "FPGA_Motion_System"

# Nexys A7-100T
set FPGA_PART "xc7a100tcsg324-1"

# 综合顶层
set DESIGN_TOP "top"

# ----------------------------------------------------------
# 2. 开发板参数
# ----------------------------------------------------------

# 板载时钟
set SYS_CLK_FREQ 100000000

# 时钟周期（ns）
set SYS_CLK_PERIOD 10.000

# VGA目标模式
# 初版计划采用640x480@60Hz
set VGA_WIDTH  640
set VGA_HEIGHT 480
# 初版单时钟域：100 MHz / 4 像素使能，约 59.52 Hz 帧率。
# 此处为架构说明，不会自动生成 RTL 或修改 XDC。
set VGA_PIXEL_FREQ 25000000

# PMOD接口规划
set GYRO_PMOD "JA"
set ALS_PMOD  "JB"

# ----------------------------------------------------------
# 3. 工程目录
# ----------------------------------------------------------

set RTL_DIR "$ROOT_DIR/rtl"
set SIM_DIR "$ROOT_DIR/sim"
set XDC_DIR "$ROOT_DIR/constraints"
set INCLUDE_DIR "$RTL_DIR/include"

set PROJECT_DIR "$ROOT_DIR/vivado"
set OUTPUT_DIR "$ROOT_DIR/output"

# ----------------------------------------------------------
# 4. 源文件分类
# ----------------------------------------------------------

set RTL_GROUPS {
    common
    sensor
    video
    motion
    include
}

set SIM_GROUPS {
    sensor
    video
    motion
    system
}

set SIM_TOPS [dict create \
    sensor tb_sensor_top \
    video  tb_video_top \
    motion tb_motion_top \
    system tb_system_top \
]

# ----------------------------------------------------------
# 5. 构建参数
# ----------------------------------------------------------

set JOBS 4

puts "=========================================="
puts "Project: $PROJECT_NAME"
puts "Board: Nexys A7-100T"
puts "FPGA: $FPGA_PART"
puts "Clock: $SYS_CLK_FREQ Hz"
puts "VGA: ${VGA_WIDTH}x${VGA_HEIGHT}"
puts "=========================================="
