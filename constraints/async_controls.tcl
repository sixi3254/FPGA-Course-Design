# Tcl constraint script: conditional selection is not legal in managed XDC.
# Registered by sync_sources.tcl in constrs_1; loaded after XDC files.
# Only asynchronous physical controls -> first synchronization stage are exempt.
# Synchronizer stage-to-stage and downstream synchronous logic remain timed.
set control_stage1 [get_cells -quiet -hier -filter {NAME =~ u_controls/input_meta_reg*}]
if {[llength $control_stage1] > 0} {
    set_false_path -from [get_ports {sw[*] btn_center btn_up btn_right btn_down}] \
        -to $control_stage1
}
# CPU_RESETN asynchronously presets the reset synchronizer only.
set reset_async_pins [get_pins -quiet -hier -filter {NAME =~ u_reset/reset_pipe_reg*/PRE}]
if {[llength $reset_async_pins] > 0} {
    set_false_path -from [get_ports rst_n] -to $reset_async_pins
}
