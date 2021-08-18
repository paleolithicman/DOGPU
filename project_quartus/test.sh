#!/bin/bash

export LM_LICENSE_FILE='1800@iam-harp-lic'
export QUARTUS_PATH='/export/utexas/intelFPGA_pro/20.4'
export QSYS_SIMDIR="$HOME/DOGPU/project_quartus"

export QUARTUS_INSTALL_DIR="$QUARTUS_PATH/quartus"
export PATH="$QUARTUS_PATH/quartus/bin:$QUARTUS_PATH/quartus/sopc_builder/bin:$QUARTUS_PATH/modelsim_ase/bin:$PATH"
export QUARTUS_ROOTDIR_OVERRIDE="$QUARTUS_PATH/quartus"
export QSYS_ROOTDIR="$QUARTUS_PATH/quartus/qsys/bin"

cd "$QSYS_SIMDIR"
vsim -c -do ./mentor/fgpu.do > ./report_sim.log
