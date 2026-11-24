# ==========================================
# Gyroscope PMOD - JA
# Pmod GYRO Rev. A J1 directly on JA, 3.3 V.
# Source: Digilent pmodgyro_rm.pdf and Nexys-A7-100T-Master.xdc.
# ==========================================

set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {gyro_cs_n}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {gyro_sclk}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {gyro_miso}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {gyro_mosi}]

# Polling architecture: no gyro interrupt input is used by this board shell.
# Pmod ALS Rev. A J1 on JB pins 1..6: 1=CS, 2=NC, 3=SDO, 4=SCLK.
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {als_cs_n}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {als_miso}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {als_sclk}]
