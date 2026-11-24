
# ==========================================================
# Create Project: Nexys A7-100T
# ==========================================================

source [file join [file dirname [info script]] config.tcl]

if {[current_project -quiet] ne ""} {
    error "Close the current project before creating this project."
}

# 检查器件是否有效
if {[llength [get_parts -quiet $FPGA_PART]] == 0} {
    error "FPGA part not found: $FPGA_PART"
}

# 检查工程是否已经存在
if {[file exists "$PROJECT_DIR/$PROJECT_NAME.xpr"]} {
    error "Project already exists. Please open it instead."
}

# 创建目录
file mkdir $PROJECT_DIR
file mkdir $OUTPUT_DIR

# 创建 Vivado 工程
create_project $PROJECT_NAME $PROJECT_DIR \
    -part $FPGA_PART

# 设置语言
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 设置默认综合策略
set_property strategy Flow_PerfOptimized_high \
    [get_runs synth_1]

# 设置实现策略
set_property strategy Performance_Explore \
    [get_runs impl_1]

# 添加 RTL、XDC 和仿真文件
source "$SCRIPT_DIR/sync_sources.tcl"

# 设置综合顶层
set_property top $DESIGN_TOP [get_filesets sources_1]

# 更新编译顺序
update_compile_order -fileset sources_1

# 设置系统仿真集合
current_fileset -simset [get_filesets sim_system]

# Vivado 项目设置会自动持久化；没有 save_project 命令。

puts "=========================================="
puts "Nexys A7-100T Project Created!"
puts "FPGA: $FPGA_PART"
puts "=========================================="
