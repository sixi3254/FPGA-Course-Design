
# ==================================================
# 模块仿真工具
# ==================================================

proc run_tb {group tb {duration "all"}} {

    # 根据分组确定仿真集合
    set simset "sim_$group"

    set fs [get_filesets -quiet $simset]

    # 检查仿真集合
    if {[llength $fs] == 0} {
        error "Simulation set does not exist: $simset"
    }

    # A placeholder filename alone is not an implemented testbench.
    set paths {}
    foreach f [get_files -quiet -of_objects $fs] {
        lappend paths [get_property NAME $f]
    }
    if {[llength [info commands files_define_module]] == 0} {
        error "Run source scripts/sync_sources.tcl before loading a testbench."
    }
    if {![files_define_module $paths $tb]} {
        error "Testbench module $tb is not implemented in $simset. Replace the placeholder first."
    }

    # 关闭之前打开的仿真
    catch {close_sim}

    # 设置当前仿真集合
    current_fileset -simset $fs

    # 设置仿真顶层
    set_property top_auto_set 0 $fs
    set_property top $tb $fs

    # 不自动运行固定时间
    set_property xsim.simulate.runtime 0ns $fs

    # 更新编译顺序
    update_compile_order -fileset $simset

    if {[get_property top $fs] ne $tb} {
        error "Testbench $tb could not be selected. Implement its module first; refusing to simulate a fallback top."
    }

    puts "Simulation set: $simset"
    puts "Testbench: $tb"

    # 启动行为级仿真
    launch_simulation -simset $simset -mode behavioral

    # 运行仿真
    if {$duration eq "all"} {
        run all
    } else {
        run $duration
    }
}

puts "Simulation helper loaded."
puts "Usage: run_tb group testbench duration"
