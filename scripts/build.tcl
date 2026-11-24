
# ==================================================
# 系统自动构建
# ==================================================

source [file join [file dirname [info script]] config.tcl]

if {[current_project -quiet] eq ""} {
    open_project "$PROJECT_DIR/$PROJECT_NAME.xpr"
}

# 先同步最新代码
source "$SCRIPT_DIR/sync_sources.tcl"

file mkdir $OUTPUT_DIR

# --------------------------------------------------
# 1. 重新运行综合
# --------------------------------------------------

puts "Starting synthesis..."

reset_run synth_1

launch_runs synth_1 -jobs $JOBS

wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
if {[get_property PROGRESS [get_runs synth_1]] ne "100%" ||
    ![string match "*synth_design Complete*" $synth_status]} {
    error "Synthesis failed: $synth_status"
}

# --------------------------------------------------
# 2. 运行实现和生成比特流
# --------------------------------------------------

puts "Starting implementation..."

reset_run impl_1

launch_runs impl_1 \
    -to_step write_bitstream \
    -jobs $JOBS

wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {[get_property PROGRESS [get_runs impl_1]] ne "100%" ||
    ![string match "*write_bitstream Complete*" $impl_status]} {
    error "Implementation or bitstream generation failed: $impl_status"
}

# --------------------------------------------------
# 3. 生成设计报告
# --------------------------------------------------

open_run impl_1

report_utilization \
    -file "$OUTPUT_DIR/utilization.rpt"

report_timing_summary \
    -file "$OUTPUT_DIR/timing_summary.rpt"

report_drc \
    -file "$OUTPUT_DIR/drc.rpt"

# --------------------------------------------------
# 4. 导出 Bitstream
# --------------------------------------------------

set run_dir [get_property DIRECTORY [get_runs impl_1]]

set bit_file "$run_dir/$DESIGN_TOP.bit"

if {![file exists $bit_file]} {
    error "Bitstream file not found."
}

file copy -force $bit_file \
    "$OUTPUT_DIR/${PROJECT_NAME}.bit"

puts "======================================"
puts "Build completed."
puts "Output directory: $OUTPUT_DIR"
puts "======================================"
