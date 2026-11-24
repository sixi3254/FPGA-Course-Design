
# ==================================================
# 自动同步工程源文件
# ==================================================

source [file join [file dirname [info script]] config.tcl]

# 检查工程是否已经打开
if {[current_project -quiet] eq ""} {
    error "Please open a Vivado project first."
}

# 避免在另一个项目的 Tcl Console 中误同步本仓库文件。
if {![string equal -nocase [file normalize [get_property DIRECTORY [current_project]]] [file normalize $PROJECT_DIR]] ||
    [get_property NAME [current_project]] ne $PROJECT_NAME} {
    error "Wrong project. Open $PROJECT_DIR/$PROJECT_NAME.xpr first."
}
if {[get_property PART [current_project]] ne $FPGA_PART} {
    error "Project part differs from config.tcl; recreate the local project."
}

# --------------------------------------------------
# 收集指定目录下的文件
# --------------------------------------------------

proc collect_files {dir patterns {recursive 1}} {

    set result {}

    foreach pattern $patterns {

        foreach f [glob -nocomplain -directory $dir $pattern] {

            if {[file isfile $f]} {
                lappend result [file normalize $f]
            }
        }
    }

    if {$recursive} {
        foreach child [glob -nocomplain -types d -directory $dir *] {
            set result [concat $result [collect_files $child $patterns]]
        }
    }

    return [lsort -unique $result]
}

# Planned testbench files contain comments until their owner implements them.
# Do not ask Vivado to validate a nonexistent module during project creation.
proc files_define_module {paths module_name} {
    if {![regexp {^[A-Za-z_][A-Za-z0-9_$]*$} $module_name]} {
        error "Unsupported module identifier: $module_name"
    }
    set pattern [format {(?m)^[ \t]*module[ \t]+%s[ \t#(;]} $module_name]
    foreach path $paths {
        if {![file isfile $path] || [file extension $path] ni {.v .sv}} {continue}
        set stream [open $path r]
        set contents [read $stream]
        close $stream
        if {[regexp $pattern $contents]} {return 1}
    }
    return 0
}

# --------------------------------------------------
# 同步指定文件集合
# --------------------------------------------------

proc sync_fileset {fileset_name desired_files} {

    set fs [get_filesets $fileset_name]
    set desired_files [lsort -unique $desired_files]

    # 获取已经注册的文件
    set existing {}

    foreach f [get_files -quiet -of_objects $fs] {
        lappend existing [file normalize [get_property NAME $f]]
    }

    # 文件清单以仓库目录为准；移除旧引用，不删除磁盘文件。
    foreach f [get_files -quiet -of_objects $fs] {

        set path [get_property NAME $f]

        if {[lsearch -exact $desired_files [file normalize $path]] == -1} {

            puts "REMOVE: $path"

            remove_files -fileset $fileset_name $f
        }
    }

    # Batch additions to avoid Vivado's per-file performance warning.
    set new_files {}
    foreach f $desired_files {

        if {[lsearch -exact $existing $f] == -1} {

            puts "ADD: $f"

            lappend new_files $f
        }
    }
    if {[llength $new_files] > 0} {
        add_files -fileset $fileset_name -norecurse $new_files
    }
}

# --------------------------------------------------
# 1. 同步 RTL 文件
# --------------------------------------------------

set rtl_files [collect_files $RTL_DIR {*.v *.sv *.vh *.svh}]

sync_fileset sources_1 $rtl_files

set_property include_dirs [list $INCLUDE_DIR] \
    [get_filesets sources_1]

set_property top $DESIGN_TOP [get_filesets sources_1]

# --------------------------------------------------
# 2. 同步 XDC 文件
# --------------------------------------------------

set xdc_files [collect_files $XDC_DIR {*.xdc *.tcl}]

sync_fileset constrs_1 $xdc_files

# --------------------------------------------------
# 3. 同步仿真文件
# --------------------------------------------------

# Retire the local-only common-test fileset from the earlier development check.
if {[llength [get_filesets -quiet sim_common]] > 0 &&
    [lsearch -exact $SIM_GROUPS common] < 0} {
    delete_fileset [get_filesets sim_common]
}
set implemented_simsets {}

foreach group $SIM_GROUPS {

    set simset "sim_$group"

    # 仿真集合不存在则自动创建
    set new_simset [expr {[llength [get_filesets -quiet $simset]] == 0}]
    if {$new_simset} {

        create_fileset -simset $simset

    }
    set_property SOURCE_SET sources_1 [get_filesets $simset]
    set_property top_auto_set 0 [get_filesets $simset]

    # 收集仿真文件
    if {$group eq "system"} {

        # 系统集合只取 sim 根目录和 sim/system，避免混入单元测试顶层。
        set sim_files [concat \
            [collect_files $SIM_DIR {*.v *.sv *.vh *.svh} 0] \
            [collect_files "$SIM_DIR/system" {*.v *.sv *.vh *.svh}]]

    } else {

        set sim_files [collect_files \
            "$SIM_DIR/$group" {*.v *.sv *.vh *.svh}]
    }

    # 为传感器和系统仿真添加外设模型
    if {$group eq "sensor" || $group eq "system"} {

        set model_files [collect_files \
            "$SIM_DIR/models" {*.v *.sv *.vh *.svh}]

        set sim_files [concat $sim_files $model_files]
    }

    sync_fileset $simset $sim_files

    set_property include_dirs [list $INCLUDE_DIR] \
        [get_filesets $simset]

    # 仅在没有指定仿真顶层时设置默认值
    set old_top [get_property TOP [get_filesets $simset]]
    if {$new_simset || $old_top eq "" || $old_top eq $DESIGN_TOP} {
        set old_top [dict get $SIM_TOPS $group]
    }
    if {[files_define_module $sim_files $old_top]} {
        set_property TOP $old_top [get_filesets $simset]
        lappend implemented_simsets $simset
    } else {
        # Keep a valid design reference until the owner writes a real TB.
        # run_tb checks the requested TB declaration and refuses this fallback.
        set_property TOP $DESIGN_TOP [get_filesets $simset]
        puts "TODO: Implement [dict get $SIM_TOPS $group] before simulating $simset."
    }
}

# --------------------------------------------------
# 4. 更新编译顺序
# --------------------------------------------------

update_compile_order -fileset sources_1

foreach simset $implemented_simsets {
    update_compile_order -fileset $simset
}

puts "======================================"
puts "Source synchronization completed."
puts "======================================"
