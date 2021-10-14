# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import os
import warnings

""" Insert DeviceTree Fragment using pynq

If the segment is not inserted already import pynq and create the a
DeviceTreeSegment with the full path to the \'pynq.dtbo\' file.
Then insert the fragment
"""

path = os.path.dirname(__file__)
dtbo = 'pynq.dtbo'
sysfs_dir = '/sys/kernel/config/device-tree/overlays/' + \
    os.path.splitext(dtbo)[0]

if not os.path.exists(sysfs_dir):
    try:
        from pynq import DeviceTreeSegment
    except UserWarning:
        pass

    if path != '':
        path = path + '/'

    db = DeviceTreeSegment(path + dtbo)
    db.insert()