# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import pynq

__author__ = "Parimal Patel, Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


class BaseOverlay(pynq.Overlay):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.is_loaded():
            self.iop_pmod0.mbtype = "Pmod"

            self.PMOD0 = self.iop_pmod0.mb_info
            self.PMODA = self.PMOD0
