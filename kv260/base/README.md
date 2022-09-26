# Base Overlay Kria KV260 Vision Started Kit 

## Prerequisites

- Xilinx Vivado 2020.2.2 (= Vivado 2020.2 + Service Pack 2) (other versions have not been verified)
- Apply the [2Y22 patch](https://support.xilinx.com/s/article/76960?language=en_US). 

## Rebuild overlay

Ensure you are in the `Kria-PYNQ/kv260/base` folder., then in your Linux/Windows terminal run:

```sh
make
```

Once the overlay generation is finished, the corresponding bitstream and hwh files are copied to this `base` directory.

## Binary File License

Pre-compiled binary files are not provided under an OSI-approved open source license, because Xilinx is incapable of providing 100% corresponding sources.

Binary files are provided under the following [license](LICENSE).

------------------------------------------------------
<p align="center">Copyright&copy; 2022 Xilinx</p>
