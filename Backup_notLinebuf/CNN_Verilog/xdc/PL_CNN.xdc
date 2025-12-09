###### 100MHz Oscilator Clock Pins
set_property PACKAGE_PIN D7 [get_ports iClk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets iClk]
set_property IOSTANDARD LVCMOS18 [get_ports iClk]

###### Segment (FND) Pins
#set_property PACKAGE_PIN M2 [get_ports seg_out[7]]
#set_property PACKAGE_PIN M1 [get_ports seg_out[6]]
#set_property PACKAGE_PIN M5 [get_ports seg_out[5]]
#set_property PACKAGE_PIN M4 [get_ports seg_out[4]]
#set_property PACKAGE_PIN L2 [get_ports seg_out[3]]
#set_property PACKAGE_PIN L1 [get_ports seg_out[2]]
#set_property PACKAGE_PIN P3 [get_ports seg_out[1]]
#set_property PACKAGE_PIN R3 [get_ports seg_out[0]]
#set_property PACKAGE_PIN U2 [get_ports com_out[3]]
#set_property PACKAGE_PIN U1 [get_ports com_out[2]]
#set_property PACKAGE_PIN T3 [get_ports com_out[1]]
#set_property PACKAGE_PIN T2 [get_ports com_out[0]]

###### Text LCD (Character LCD) Control pins
#set_property PACKAGE_PIN M1 [get_ports lcd_rs]
#set_property PACKAGE_PIN M5 [get_ports lcd_rw]
#set_property PACKAGE_PIN M4 [get_ports lcd_en]
###### Text LCD (Character LCD) Data Pins
#set_property PACKAGE_PIN T2 [get_ports lcd_data[7]]
#set_property PACKAGE_PIN T3 [get_ports lcd_data[6]]
#set_property PACKAGE_PIN U1 [get_ports lcd_data[5]]
#set_property PACKAGE_PIN U2 [get_ports lcd_data[4]]
#set_property PACKAGE_PIN R3 [get_ports lcd_data[3]]
#set_property PACKAGE_PIN P3 [get_ports lcd_data[2]]
#set_property PACKAGE_PIN L1 [get_ports lcd_data[1]]
#set_property PACKAGE_PIN L2 [get_ports lcd_data[0]]

###### TFT LCD Control Pins
set_property PACKAGE_PIN F8 [get_ports iRsnButton]
set_property PACKAGE_PIN G1 [get_ports oLcdClk]
set_property PACKAGE_PIN E4 [get_ports oLcdHSync]
set_property PACKAGE_PIN F1 [get_ports oLcdVSync]
set_property PACKAGE_PIN E3 [get_ports oLcdDe]
set_property PACKAGE_PIN E1 [get_ports oLcdBackLight]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_DCLK]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_HSYNC]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_VSYNC]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_DE]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_BACKLIGHT]
###### TFT LCD RGB Data Pins RGB565
set_property PACKAGE_PIN R3 [get_ports {oLcdR[4]}]
set_property PACKAGE_PIN U2 [get_ports {oLcdR[3]}]
set_property PACKAGE_PIN U1 [get_ports {oLcdR[2]}]
set_property PACKAGE_PIN T3 [get_ports {oLcdR[1]}]
set_property PACKAGE_PIN T2 [get_ports {oLcdR[0]}]
set_property PACKAGE_PIN M1 [get_ports {oLcdG[5]}]
set_property PACKAGE_PIN M5 [get_ports {oLcdG[4]}]
set_property PACKAGE_PIN M4 [get_ports {oLcdG[3]}]
set_property PACKAGE_PIN L2 [get_ports {oLcdG[2]}]
set_property PACKAGE_PIN L1 [get_ports {oLcdG[1]}]
set_property PACKAGE_PIN P3 [get_ports {oLcdG[0]}]
set_property PACKAGE_PIN N2 [get_ports {oLcdB[4]}]
set_property PACKAGE_PIN P1 [get_ports {oLcdB[3]}]
set_property PACKAGE_PIN N5 [get_ports {oLcdB[2]}]
set_property PACKAGE_PIN N4 [get_ports {oLcdB[1]}]
set_property PACKAGE_PIN M2 [get_ports {oLcdB[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports TFT_RGB_*]

###### OV5640 CIS Camera Pins 
#set_property PACKAGE_PIN G5 [get_ports CAM_PCLK]
#set_property PACKAGE_PIN D7 [get_ports CAM_PCLK]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CAM_PCLK]

# create_generated_clock -name CAM_100KHz_FOR_RST \
#                        -source [get_ports CAM_PCLK] \
#                        -divide_by 800 \
#                        [get_pins -hier -filter {NAME =~ *clk_ww*}]
# set_property DONT_TOUCH TRUE [get_pins clk_w]
# set_property DONT_TOUCH TRUE [get_pins clk_ww]


#set_property PACKAGE_PIN A7 [get_ports CAM_PWDN]
#set_property PACKAGE_PIN A6 [get_ports CAM_RESETn]
#set_property PACKAGE_PIN E6 [get_ports CAM_SCCB_SCL]
#set_property PACKAGE_PIN G6 [get_ports CAM_SCCB_SDA]
#set_property PACKAGE_PIN F7 [get_ports CAM_HSYNC]
#set_property PACKAGE_PIN G7 [get_ports CAM_VSYNC]
#set_property PACKAGE_PIN G5 [get_ports CAM_PCLK]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CAM_PCLK]
#set_property PACKAGE_PIN F6 [get_ports CAM_MCLK]
#set_property PACKAGE_PIN E5 [get_ports {CAM_DATA[0]}]
#set_property PACKAGE_PIN D6 [get_ports {CAM_DATA[1]}]
#set_property PACKAGE_PIN D5 [get_ports {CAM_DATA[2]}]
#set_property PACKAGE_PIN C7 [get_ports {CAM_DATA[3]}]
#set_property PACKAGE_PIN B6 [get_ports {CAM_DATA[4]}]
#set_property PACKAGE_PIN C5 [get_ports {CAM_DATA[5]}]
#set_property PACKAGE_PIN E8 [get_ports {CAM_DATA[6]}]
#set_property PACKAGE_PIN D8 [get_ports {CAM_DATA[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_PCLK]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_PWDN]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_RESETn]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_SCCB_SCL]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_SCCB_SDA]
#set_property IOSTANDARD LVCMOS18 [get_ports {CAM_DATA[*]}]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_HSYNC]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_VSYNC]
#set_property IOSTANDARD LVCMOS18 [get_ports CAM_MCLK]

set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 26]]
set_property IOSTANDARD LVCMOS12 [get_ports -of_objects [get_iobanks 65]]

###### LED, Push Button, Slide Switch
#set_property PACKAGE_PIN D8 [get_ports {led_o[3]}]
#set_property PACKAGE_PIN E8 [get_ports {led_o[2]}]
#set_property PACKAGE_PIN C5 [get_ports {led_o[1]}]
#set_property PACKAGE_PIN B6 [get_ports {led_o[0]}]
#set_property PACKAGE_PIN A6 [get_ports {slide_sw_i[0]}]
#set_property PACKAGE_PIN A7 [get_ports {slide_sw_i[1]}]
#set_property PACKAGE_PIN G6 [get_ports {slide_sw_i[2]}]
#set_property PACKAGE_PIN E6 [get_ports {slide_sw_i[3]}]
#set_property PACKAGE_PIN F8 [get_ports {push_btn_i[0]}]
#set_property PACKAGE_PIN F7 [get_ports {push_btn_i[1]}]
#set_property PACKAGE_PIN G7 [get_ports {push_btn_i[2]}]
#set_property PACKAGE_PIN F6 [get_ports {push_btn_i[3]}]
#set_property PACKAGE_PIN G5 [get_ports {push_btn_i[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports iRsnButton]
#set_property IOSTANDARD LVCMOS18 [get_ports {push_btn_i[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {push_btn_i[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {push_btn_i[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {push_btn_i[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_o[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_o[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_o[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_o[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {slide_sw_i[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {slide_sw_i[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {slide_sw_i[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {slide_sw_i[0]}]

###### Motor
#set_property PACKAGE_PIN J5 [get_ports {motor_o[3]}]
#set_property PACKAGE_PIN H5 [get_ports {motor_o[2]}]
#set_property PACKAGE_PIN G1 [get_ports {motor_o[1]}]
#set_property PACKAGE_PIN F1 [get_ports {motor_o[0]}]

###### Ultra Sonic
#set_property PACKAGE_PIN E4 [get_ports {echo}]
#set_property PACKAGE_PIN E3 [get_ports {trig}]

###### SPI Bus (ADC0: Photo Register(CdS_GL5549), ADC1: Thermometor(LM35DM), ADC2~ADC7: ADC(BH2715FV))
#set_property PACKAGE_PIN E5 [get_ports {SCLK}]
#set_property PACKAGE_PIN D6 [get_ports {MOSI}]
#set_property PACKAGE_PIN D5 [get_ports {MISO}]
#set_property PACKAGE_PIN C7 [get_ports {CS}]
#set_property IOSTANDARD LVCMOS18 [get_ports {SCLK}]
#set_property IOSTANDARD LVCMOS18 [get_ports {MOSI}]
#set_property IOSTANDARD LVCMOS18 [get_ports {MISO}]
#set_property IOSTANDARD LVCMOS18 [get_ports {CS}]

###### PS UART1 (UART0 is not Connected)
#set_property PACKAGE_PIN MIO1 [get_ports {UART1_RX}]
#set_property PACKAGE_PIN MIO0 [get_ports {UART1_TX}]

###### PS SPI
#set_property PACKAGE_PIN MIO41 [get_ports {SPI0_CS}]
#set_property PACKAGE_PIN MIO38 [get_ports {SPI0_SCLK}]
#set_property PACKAGE_PIN MIO42 [get_ports {SPI0_MISO}]
#set_property PACKAGE_PIN MIO43 [get_ports {SPI0_MOSI}]
#set_property PACKAGE_PIN MIO9 [get_ports {SPI1_CS}]
#set_property PACKAGE_PIN MIO6 [get_ports {SPI1_SCLK}]
#set_property PACKAGE_PIN MIO10 [get_ports {SPI1_MISO}]
#set_property PACKAGE_PIN MIO11 [get_ports {SPI1_MOSI}]

###### PS I2C 1/2 (It is tied to I2C bus )
#set_property PACKAGE_PIN MIO4 [get_ports {SCL}]; #I2C 1/2 SCL
#set_property PACKAGE_PIN MIO5 [get_ports {SDA}]; #I2C 1/2 SDA

###### PS GPIO
#set_property PACKAGE_PIN MIO36 [get_ports {GPIO0}]
#set_property PACKAGE_PIN MIO37 [get_ports {GPIO1}]
#set_property PACKAGE_PIN MIO39 [get_ports {GPIO2}]
#set_property PACKAGE_PIN MIO40 [get_ports {GPIO3}]
#set_property PACKAGE_PIN MIO44 [get_ports {GPIO4}]
#set_property PACKAGE_PIN MIO45 [get_ports {GPIO5}]

# Set the bank voltage for IO Bank 26 to 1.8V
 set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 26]]
# Set the bank voltage for IO Bank 65 to 1.2V
 set_property IOSTANDARD LVCMOS12 [get_ports -of_objects [get_iobanks 65]]
# Set the bank voltage for IO Bank 66 to 1.2V (must match Bank 65)
 set_property IOSTANDARD LVCMOS12 [get_ports -of_objects [get_iobanks 66]]

