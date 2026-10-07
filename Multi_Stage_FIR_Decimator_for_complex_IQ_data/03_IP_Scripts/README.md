# AMD/Xilinx FIR Compiler IP Core Specifications & Integration

This directory contains the AMD/Xilinx FIR Compiler IP Core customization files (`.xci`) configured for the multi-stage decimation datapath targeting the **AMD Zynq™ UltraScale+™ MPSoC** (`xczu15eg-ffvc900-2-i`).

---

## 📁 IP File Manifest

```text
03_IP_Scripts/
├── Stage_1_FIR/
│   └── fir_compiler_st1.xci    # Stage 1: Decimate by 10 (100 MSPS -> 10 MSPS)
├── Stage_2_FIR/
│   └── fir_compiler_st2.xci    # Stage 2: Decimate by 2  (10 MSPS -> 5 MSPS)
├── Stage_3_FIR/
│   └── fir_compiler_st3.xci    # Stage 3: Decimate by 2  (5 MSPS -> 2.5 MSPS)
└── Stage_4_FIR/
    └── fir_compiler_st4.xci    # Stage 4: Decimate by 2  (2.5 MSPS -> 1.25 MSPS)
```

---

## ⚙️ Filter Specifications & IP Parameters

All four stages utilize the Xilinx FIR Compiler IP Core (v7.2) with symmetric 21-tap anti-aliasing filter profiles:

| IP Instance Name | Component Name | Clock Frequency | Input Sample Rate | Decimation Rate | Output Sample Rate | Filter Type | Number of Taps |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| `fir_compiler_st1` | `Stage_1_FIR` | 100.0 MHz | 100.0 MSPS | **10** | **10.00 MSPS** | Decimation | 21 |
| `fir_compiler_st2` | `Stage_2_FIR` | 100.0 MHz | 10.0 MSPS  | **2**  | **5.00 MSPS**  | Decimation | 21 |
| `fir_compiler_st3` | `Stage_3_FIR` | 100.0 MHz | 5.0 MSPS   | **2**  | **2.50 MSPS**  | Decimation | 21 |
| `fir_compiler_st4` | `Stage_4_FIR` | 100.0 MHz | 2.5 MSPS   | **2**  | **1.25 MSPS**  | Decimation | 21 |

---

## 🔢 Filter Coefficients & Symmetry

The filter uses a 21-tap symmetric impulse response with integer coefficients:

```text
h[n] = [ 6, 0, -4, -3, 5, 6, -6, -13, 7, 44, 64, 44, 7, -13, -6, 6, 5, -3, -4, 0, 6 ]
```

* **Symmetry:** Even Symmetric ($h[n] = h[N-1-n]$). Exploited by the Xilinx FIR Compiler IP to halve the number of required hardware multipliers.
* **Coefficient Width:** 16-bit signed integer.
* **Quantization:** Integer Coefficients (no fractional scaling error).
* **Data Width:** 32-bit AXI4-Stream (`s_axis_data_tdata[31:0]` and `m_axis_data_tdata[31:0]`).

---

## 🔌 AXI4-Stream Interface Details

Each generated IP core provides standard AXI4-Stream framing:
* `aclk`: Synchronous system clock (100 MHz).
* `aresetn`: Active-low synchronous reset.
* `s_axis_data_tvalid`: Input sample valid qualifier.
* `s_axis_data_tready`: Flow control output (unconnected / open in streaming radar datapath).
* `s_axis_data_tdata[31:0]`: Complex input sample word (`[31:16] = Q`, `[15:0] = I`).
* `m_axis_data_tvalid`: Single-cycle output sample valid strobe.
* `m_axis_data_tdata[31:0]`: Filtered and decimated output sample word.

---

## 🛠️ Importing the IP into a Vivado Project

To import these IP cores into a fresh Vivado project:

### GUI Method:
1. Open your Vivado project.
2. In the Flow Navigator, click **Settings $\rightarrow$ IP $\rightarrow$ Repository**.
3. Alternatively, click **Add Sources $\rightarrow$ Add Existing IP (`.xci`)** and select all four `.xci` files.
4. When prompted, select **Generate Output Products**.

### Tcl Console Method:
```tcl
import_ip [list \
  [file normalize "03_IP_Scripts/Stage_1_FIR/fir_compiler_st1.xci"] \
  [file normalize "03_IP_Scripts/Stage_2_FIR/fir_compiler_st2.xci"] \
  [file normalize "03_IP_Scripts/Stage_3_FIR/fir_compiler_st3.xci"] \
  [file normalize "03_IP_Scripts/Stage_4_FIR/fir_compiler_st4.xci"] \
]
generate_target all [get_ips]
```
