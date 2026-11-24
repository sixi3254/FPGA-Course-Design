# ==========================================
# Nexys A7-100T
# Clock
# ==========================================

# Nexys A7 schematic: configuration bank and CFGBVS are tied to VCC3V3.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property -dict {
    PACKAGE_PIN E3
    IOSTANDARD LVCMOS33
} [get_ports {sys_clk}]

create_clock -name sys_clk \
    -period 10.000 \
    -waveform {0 5} \
    [get_ports {sys_clk}]

# ==========================================
# CPU Reset
# ==========================================

set_property -dict {
    PACKAGE_PIN C12
    IOSTANDARD LVCMOS33
} [get_ports {rst_n}]

# SW0/1: mode, SW2: maze enable, SW3: automatic brightness.
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

# Active-high board buttons. top.v synchronizes and debounces all controls.
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {btn_center}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {btn_up}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {btn_right}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {btn_down}]
