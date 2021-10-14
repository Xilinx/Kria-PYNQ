# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

# PCAM MIPI ISP
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_clk_p}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_clk_n}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_data_p[*]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_isp_data_n[*]}]

#I2C signals --> I2C switch 0--> ISP AP1302 + Sensor AR1335
#I2C signals --> I2C switch 1--> Sensor AR1335
#I2C signals --> I2C switch 2--> Raspi Camera
set_property PACKAGE_PIN G11 [get_ports iic_scl_io]
set_property PACKAGE_PIN F10 [get_ports iic_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_*]

# PMOD
set_property PACKAGE_PIN B11      [get_ports "pmod[7]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L10P_AD10P_45
set_property PACKAGE_PIN D11      [get_ports "pmod[6]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L8N_HDGC_45
set_property PACKAGE_PIN E12      [get_ports "pmod[5]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L8P_HDGC_45
set_property PACKAGE_PIN B10      [get_ports "pmod[4]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L9N_AD11N_45
set_property PACKAGE_PIN C11      [get_ports "pmod[3]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L9P_AD11P_45
set_property PACKAGE_PIN D10      [get_ports "pmod[2]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L7N_HDGC_45
set_property PACKAGE_PIN E10      [get_ports "pmod[1]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L7P_HDGC_45
set_property PACKAGE_PIN H12      [get_ports "pmod[0]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L4N_AD12N_45
set_property IOSTANDARD LVCMOS33 [get_ports pmod[*]]
set_property PULLUP true [get_ports {pmod[2]}];
set_property PULLUP true [get_ports {pmod[3]}];
set_property PULLUP true [get_ports {pmod[6]}];
set_property PULLUP true [get_ports {pmod[7]}];

# Digilent PCAM 5C MIPI Camera Enable
set_property PACKAGE_PIN F11      [get_ports "cam_gpio_tri_o[0]"] ;# Bank  45 VCCO - som240_1_b13 - IO_L6N_HDGC_45
set_property IOSTANDARD LVCMOS33 [get_ports cam_gpio_tri_o[*]]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
