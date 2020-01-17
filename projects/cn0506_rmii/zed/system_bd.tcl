
source $ad_hdl_dir/projects/common/zed/zed_system_bd.tcl

ad_ip_parameter sys_ps7 CONFIG.PCW_EN_CLK2_PORT 1
ad_ip_parameter sys_ps7 CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE 1
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET0_ENET0_IO EMIO
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET0_GRP_MDIO_IO EMIO
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {100 Mbps}
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET1_PERIPHERAL_ENABLE 1
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET1_GRP_MDIO_ENABLE 1
ad_ip_parameter sys_ps7 CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {100 Mbps}

create_bd_port -dir I rmii_mac_sel_0

create_bd_port -dir O reset
create_bd_port -dir I clk_in_50
create_bd_port -dir O clk_out_50
create_bd_port -dir I ref_clk_125
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rmii_rtl:1.0 RMII_PHY_M_0
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rmii_rtl:1.0 RMII_PHY_M_1
make_bd_intf_pins_external  [get_bd_intf_pins sys_ps7/MDIO_ETHERNET_0]
make_bd_intf_pins_external  [get_bd_intf_pins sys_ps7/MDIO_ETHERNET_1]

ad_connect reset sys_rstgen/peripheral_reset

# 50MHz
ad_ip_instance clk_wiz clk_wiz
ad_ip_parameter clk_wiz CONFIG.PRIM_IN_FREQ 125
ad_ip_parameter clk_wiz CONFIG.MMCM_CLKIN1_PERIOD 8.000
ad_ip_parameter clk_wiz CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50
ad_ip_parameter clk_wiz CONFIG.PRIM_SOURCE "No_buffer"

ad_connect ref_clk_125 clk_wiz/clk_in1
ad_connect sys_rstgen/peripheral_reset clk_wiz/reset
ad_connect clk_out_50 clk_wiz/clk_out1

create_bd_cell -type ip -vlnv xilinx.com:ip:mii_to_rmii:2.0 mii_to_rmii_0
ad_ip_parameter mii_to_rmii_0 CONFIG.C_MODE 1

ad_connect mii_to_rmii_0/GMII    sys_ps7/GMII_ETHERNET_0
ad_connect mii_to_rmii_0/ref_clk clk_in_50
ad_connect mii_to_rmii_0/rst_n   sys_ps7/FCLK_RESET1_N

ad_connect mii_to_rmii_0/RMII_PHY_M RMII_PHY_M_0

create_bd_cell -type ip -vlnv xilinx.com:ip:mii_to_rmii:2.0 mii_to_rmii_1
ad_ip_parameter mii_to_rmii_1 CONFIG.C_MODE 1

ad_connect mii_to_rmii_1/GMII    sys_ps7/GMII_ETHERNET_1
ad_connect mii_to_rmii_1/ref_clk clk_in_50
ad_connect mii_to_rmii_1/rst_n   sys_ps7/FCLK_RESET1_N

ad_connect mii_to_rmii_1/RMII_PHY_M RMII_PHY_M_1

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9
set sys_cstring "sys rom custom string placeholder"
sysid_gen_sys_init_file $sys_cstring

disconnect_bd_net /sys_ps7_FCLK_RESET1_N [get_bd_pins mii_to_rmii_0/rst_n]
disconnect_bd_net /sys_ps7_FCLK_RESET1_N [get_bd_pins mii_to_rmii_1/rst_n]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_ports clk_in_50]
connect_bd_net [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins sys_rstgen/peripheral_aresetn]
delete_bd_objs [get_bd_nets sys_cpu_reset]
connect_bd_net [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/peripheral_reset]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins mii_to_rmii_0/rst_n]
connect_bd_net [get_bd_pins mii_to_rmii_1/rst_n] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_in

set_property -dict [list CONFIG.C_PROBE2_WIDTH {2} CONFIG.C_DATA_DEPTH {2048} CONFIG.C_NUM_OF_PROBES {3} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_in]
connect_bd_net [get_bd_pins ila_in/clk] [get_bd_pins sys_ps7/FCLK_CLK2]
connect_bd_net [get_bd_pins ila_in/probe0] [get_bd_pins RMII_PHY_M_1_crs_dv]
connect_bd_net [get_bd_pins ila_in/probe1] [get_bd_pins RMII_PHY_M_0_crs_dv]
connect_bd_net [get_bd_pins ila_in/probe2] [get_bd_pins rmii_mac_sel_0]
