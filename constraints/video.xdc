
# ==========================================
# Nexys A7-100T VGA
# ==========================================

# Red
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]

# Green
set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]

# Blue
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]

# Horizontal sync
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {vga_hsync}]

# Vertical sync
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports {vga_vsync}]
