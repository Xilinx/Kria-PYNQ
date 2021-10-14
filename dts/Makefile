# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

NAME = pynq

all:
	dtc -I dts -O dtb -o $(NAME).dtbo pynq.dts -q

clean:
	rm -rf $(NAME).dtbo
