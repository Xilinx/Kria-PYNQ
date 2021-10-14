# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

DTB = base

all:
	dtc -I dts -O dtb -o $(DTB).dtbo $(DTB).dtsi -q

clean:
	rm -rf $(DTB).dtbo