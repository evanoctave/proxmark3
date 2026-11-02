#
# Proxmark3 / Proxmark3-ULT / iCopy-X FPGA build (Xilinx ISE toolchain)
#
# Invoked by the fpga/Makefile dispatcher, or directly:
#   make -C fpga -f proxmark3_fpga.mk [<target>|all|clean]
#
# The top part of this file is used to define custom options for a number of compilation targets
# To define an additional target simply look at the other defined targets and add a new TARGET entry with a unique number and the custom options required

include $(dir $(lastword $(MAKEFILE_LIST)))common_src.mk

XILINX_TOOLS_PREFIX=

# Each target is built into its own separate directory name formed by combining the PREFIX and TARGET names.
# This way the source is not polluted with build files and the build directories are left behind after compilation so logs and reports can be
# examined or can be easily deleted with "make clean"

# Options to be passed to XST
XST_OPTS_BASE  = run
XST_OPTS_BASE += -ifn xst.prj
XST_OPTS_BASE += -ifmt mixed
XST_OPTS_BASE += -ofmt NGC
XST_OPTS_BASE += -lso xst.lso
XST_OPTS_BASE += -top fpga_top
XST_OPTS_BASE += -resource_sharing yes

# Optimizations for speed (default)
XST_OPTS_SPEED  = -opt_mode Speed
XST_OPTS_SPEED += -opt_level 1
XST_OPTS_SPEED += -fsm_style lut
XST_OPTS_SPEED += -fsm_encoding auto

# Optimization for reduced space
XST_OPTS_AREA  = -opt_mode area
XST_OPTS_AREA += -opt_level 2
XST_OPTS_AREA += -fsm_style bram
XST_OPTS_AREA += -fsm_encoding compact

# par specific option (set determistic seed)
PAR_OPTIONS = -t 2

# Types of selective module compilation:
# WITH_LF  Enables selection of LF modules (and disables all HF)

# To enable these modules WITH_LF _MUST_ be defined
# WITH_LF0 enable LF reader (generic)
# WITH_LF1 enable LF edge detect (generic)
# WITH_LF2 enable LF passthrough
# WITH_LF3 enable LF ADC (read/write)

# To enable these modules WITH_LF _MUST_NOT_ be defined
# WITH_HF0 enable HF reader (see also WITH_HF_15 below)
# WITH_HF_15 select "iso15 2sc mode" extensions instead of original
#          (the iso15 low-signal reader detection thresholds are selected at runtime
#           in hi_reader.v, based on subcarrier/minor mode -- no separate define)
# WITH_HF1 enable HF simulated tag
# WITH_HF2 enable HF ISO14443-A
# WITH_HF3 enable sniff
# WITH_HF4 enable HF ISO18092 FeliCa
# WITH_HF5 enable HF get trace

# WITH_TIMODE enable TI mode (for SPI_SSC. PM5 only currently)

# RDV40/Generic - Enable LF and all the LF modules
TARGET1_OPTIONS = -define \{WITH_LF WITH_LF0 WITH_LF1 WITH_LF2 WITH_LF3\}
# RDV40/Generic - Enable all HF modules except Felica
TARGET2_OPTIONS = -define \{WITH_HF0 WITH_HF1 WITH_HF2 WITH_HF3 WITH_HF5\}
# RDV40/Generic - Enable all HF modules except Felica and ISO14443, select HF_15 instead of HF
TARGET3_OPTIONS = -define \{WITH_HF0 WITH_HF1 WITH_HF3 WITH_HF5 WITH_HF_15\}
# RDV40/Generic - Enable all HF modules except ISO14443
TARGET4_OPTIONS = -define \{WITH_HF0 WITH_HF1 WITH_HF3 WITH_HF4 WITH_HF5 WITH_FELICA_PROBE\}
# ICOPYX
TARGET5_OPTIONS = $(TARGET1_OPTIONS)
# PM3-ULT (xc2s50): same four images as the RDV4 targets
TARGET6_OPTIONS = $(TARGET1_OPTIONS)
TARGET7_OPTIONS = $(TARGET1_OPTIONS)
TARGET8_OPTIONS = $(TARGET1_OPTIONS)
TARGET9_OPTIONS = $(TARGET1_OPTIONS)
# PM3 generic with xc2s15 (192 slices, 4 block RAMs): only two reduced images fit.
# LF without edge detect (lo_edge_detect alone needs 297 slices), HF reader + sniffer
# only (hi_iso14443a alone is 194, get_trace needs 6 block RAMs)
TARGET10_OPTIONS = -define \{WITH_LF WITH_LF0 WITH_LF2 WITH_LF3\}
TARGET11_OPTIONS = -define \{WITH_HF0 WITH_HF3\}

# Here we list the target names
TARGET1_NAME = fpga_pm3_lf
TARGET2_NAME = fpga_pm3_hf
TARGET3_NAME = fpga_pm3_hf_15
TARGET4_NAME = fpga_pm3_felica
TARGET5_NAME = fpga_icopyx_hf
TARGET6_NAME = fpga_pm3_ult_lf
TARGET7_NAME = fpga_pm3_ult_hf
TARGET8_NAME = fpga_pm3_ult_hf_15
TARGET9_NAME = fpga_pm3_ult_felica
TARGET10_NAME = fpga_pm3_s15_lf
TARGET11_NAME = fpga_pm3_s15_hf

# Targets can be compiled for different FPGA flavours
TARGET1_FPGA = xc2s30-5-vq100
TARGET2_FPGA = $(TARGET1_FPGA)
TARGET3_FPGA = $(TARGET1_FPGA)
TARGET4_FPGA = $(TARGET1_FPGA)
TARGET5_FPGA = xc3s100e-4-vq100
TARGET6_FPGA = xc2s50-5-tq144
TARGET7_FPGA = $(TARGET6_FPGA)
TARGET8_FPGA = $(TARGET6_FPGA)
TARGET9_FPGA = $(TARGET6_FPGA)
TARGET10_FPGA = xc2s15-5-vq100
TARGET11_FPGA = $(TARGET10_FPGA)

# Pin constraints, one file per FPGA flavour
TARGET1_UCF = $(PM3_DIR)/xc2s30-5-vq100.ucf
TARGET2_UCF = $(TARGET1_UCF)
TARGET3_UCF = $(TARGET1_UCF)
TARGET4_UCF = $(TARGET1_UCF)
TARGET5_UCF = $(ICOPYX_DIR)/xc3s100e-4-vq100.ucf
TARGET6_UCF = $(PM3_DIR)/xc2s50-5-tq144.ucf
TARGET7_UCF = $(TARGET6_UCF)
TARGET8_UCF = $(TARGET6_UCF)
TARGET9_UCF = $(TARGET6_UCF)
# xc2s15 and xc2s30 share the VQ100 pinout
TARGET10_UCF = $(TARGET1_UCF)
TARGET11_UCF = $(TARGET1_UCF)

# Assemble the final XST options for each target
TARGET1_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET1_FPGA) -ofn $(TARGET1_NAME) $(TARGET1_OPTIONS)
TARGET2_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET2_FPGA) -ofn $(TARGET2_NAME) $(TARGET2_OPTIONS)
TARGET3_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET3_FPGA) -ofn $(TARGET3_NAME) $(TARGET3_OPTIONS)
TARGET4_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET4_FPGA) -ofn $(TARGET4_NAME) $(TARGET4_OPTIONS)
TARGET5_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_SPEED) -p $(TARGET5_FPGA) -ofn $(TARGET5_NAME) $(TARGET5_OPTIONS)
TARGET6_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_SPEED) -p $(TARGET6_FPGA) -ofn $(TARGET6_NAME) $(TARGET6_OPTIONS)
TARGET7_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_SPEED) -p $(TARGET7_FPGA) -ofn $(TARGET7_NAME) $(TARGET7_OPTIONS)
TARGET8_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_SPEED) -p $(TARGET8_FPGA) -ofn $(TARGET8_NAME) $(TARGET8_OPTIONS)
TARGET9_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_SPEED) -p $(TARGET9_FPGA) -ofn $(TARGET9_NAME) $(TARGET9_OPTIONS)
TARGET10_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET10_FPGA) -ofn $(TARGET10_NAME) $(TARGET10_OPTIONS)
TARGET11_XST_OPTS = $(XST_OPTS_BASE) $(XST_OPTS_AREA)  -p $(TARGET11_FPGA) -ofn $(TARGET11_NAME) $(TARGET11_OPTIONS)

# Add the files that are unique per target and all the common files
TARGET1_FILES = $(COMMON_HDL) $(PM3_DIR)/fpga_pm3_top.v
TARGET2_FILES = $(TARGET1_FILES)
TARGET3_FILES = $(TARGET1_FILES)
TARGET4_FILES = $(TARGET1_FILES)
TARGET5_FILES = $(COMMON_HDL) $(COMMON_DIR)/mux2_onein.v $(COMMON_DIR)/mux2_oneout.v $(ICOPYX_DIR)/fpga_icopyx_hf.v $(ICOPYX_DIR)/fpga_icopyx_lf.v $(ICOPYX_DIR)/fpga_icopyx_top.v
TARGET6_FILES = $(TARGET1_FILES)
TARGET7_FILES = $(TARGET1_FILES)
TARGET8_FILES = $(TARGET1_FILES)
TARGET9_FILES = $(TARGET1_FILES)
TARGET10_FILES = $(TARGET1_FILES)
TARGET11_FILES = $(TARGET1_FILES)

# List of all valid target FPGA images to build
TARGETS = $(TARGET1_NAME) $(TARGET2_NAME) $(TARGET3_NAME) $(TARGET4_NAME) $(TARGET5_NAME) $(TARGET6_NAME) $(TARGET7_NAME) $(TARGET8_NAME) $(TARGET9_NAME) $(TARGET10_NAME) $(TARGET11_NAME)

