# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


import hashlib
import os
import re
import subprocess
import shutil
import tempfile
import urllib.request
from glob import glob
#from pynq.utils import build_py
from pynqutils.setup_utils import build_py, find_version, extend_package
from setuptools import setup, find_packages


# global variables
module_name = "kv260"
board = os.environ["BOARD"]
data_files = []


overlay = {
    "KV260": {
                "url": "https://www.xilinx.com/bin/public/openDownload?filename=kv260_base_3.0.zip",
                "md5sum": "",
                "format": "zip"
             }
}


def download_overlay(board, overlay_dest):
    """Download pre-compiled overlay from the Internet"""

    if board not in overlay.keys():
        return

    download_link = overlay[board]["url"]
    md5sum = overlay[board].get("md5sum")
    archive_format = overlay[board].get("format")
    tmp_file = tempfile.mkstemp()[1]

    with urllib.request.urlopen(download_link) as response, \
            open(tmp_file, "wb") as out_file:
        data = response.read()
        out_file.write(data)
    if md5sum:
        file_md5sum = hashlib.md5()
        with open(tmp_file, "rb") as out_file:
            for chunk in iter(lambda: out_file.read(4096), b""):
                file_md5sum.update(chunk)
        if md5sum != file_md5sum.hexdigest():
            os.remove(tmp_file)
            raise ImportWarning("Incorrect checksum for file. The base "
                                "overlay will not be delivered")

    shutil.unpack_archive(tmp_file, overlay_dest, archive_format)


def compile_dtbo(src_path: str, dst_path: str):
    """Compile devicetree overlay"""

    sp = subprocess.Popen(["make"], stdout=subprocess.PIPE, cwd=src_path)
    p_status = sp.wait()
    shutil.copy(src_path + 'base.dtbo', dst_path)


def copy_notebooks(board_folder, module_name):
    """Copy notebooks"""

    src_dir = "{}/notebooks".format(board_folder)
    if not os.path.exists(src_dir):
        return

    for folder in glob(src_dir + '/*'):
        dst = folder.replace(board_folder, module_name)
        if os.path.exists(dst):
            shutil.rmtree(dst)
        shutil.copytree(folder, dst)


copy_notebooks("kv260/base", module_name)
download_overlay(board, module_name)
compile_dtbo("kv260/base/dts/", module_name)
extend_package(module_name, data_files)
pkg_version = find_version("{}/__init__.py".format(module_name))

setup(
    name=module_name,
    version=pkg_version,
    description="KV260-PYNQ Base Overlay",
    author="Xilinx PYNQ Development Team",
    author_email="pynq_support@xilinx.com",
    url="https://github.com/Xilinx/Kria-PYNQ",
    license="BSD 3-Clause License",
    packages=find_packages(),
    package_data={
        "": data_files,
    },
    python_requires=">=3.8.0",
    install_requires=[
        "pynq>=3.0.1"
    ],
    entry_points={
        "pynq.notebooks": ["kv260 = {}.notebooks".format(module_name)],
        "pynq.overlays": ["kv260 = {}".format(module_name)]
    },
    cmdclass={"build_py": build_py},
    platforms=[board]
)
