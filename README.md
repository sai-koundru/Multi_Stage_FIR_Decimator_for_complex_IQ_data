[README.md](https://github.com/user-attachments/files/33153329/README.md)
# Configurable Multi-Stage Complex (I/Q) FIR Decimator for FPGA Radar/RF Receivers

[![Target Device](https://img.shields.io/badge/Target%20Device-AMD%20Zynq%20UltraScale%2B%20MPSoC-orange.svg)](https://www.xilinx.com/products/silicon-devices/soc/zynq-ultrascale-plus.html)
[![Toolchain](https://img.shields.io/badge/Vivado-2024.2-blue.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![HDL](https://img.shields.io/badge/Language-VHDL%20%7C%20Verilog-green.svg)](#)
[![DSP Architecture](https://img.shields.io/badge/DSP-Multi--Rate%20FIR%20Decimation-purple.svg)](#)

A high-performance, modular **4-Stage Cascaded FIR Decimation Processor** designed in **VHDL** for FPGA-based Radar and Digital RF receive (Rx) chains. The architecture processes **32-bit interleaved complex I/Q samples** ($16\text{-bit } I + 16\text{-bit } Q$) sampled at **100 MSPS** and provides **runtime-selectable output sample rates** (10 MHz, 5 MHz, 2.5 MHz, and 1.25 MHz) via a 2-bit control word without disrupting ongoing processing.

Implemented and verified on the **AMD Zynq™ UltraScale+™ MPSoC (`xczu15eg-ffvc900-2-i`)** using **AMD Vivado™ ML 2024.2**.

---

## 📌 Executive Summary

Modern Radar and Software-Defined Radio (SDR) front-ends digitize wideband signals at high sampling frequencies (e.g., 100 MSPS). However, subsequent baseband algorithms (such as Doppler filtering, Pulse Compression / Matched Filtering, and Moving Target Detection) require configurable, narrower bandwidths and decimated sample rates to conserve DSP slices and memory bandwidth.

This design implements an efficient **multi-rate cascaded decimation chain**:
- **Stage 1 (Decimate by 10):** Reduces $100\text{ MSPS} \rightarrow 10\text{ MSPS}$ using a 21-tap symmetric anti-aliasing FIR filter.
- **Stage 2 (Decimate by 2):** Halves the rate from $10\text{ MSPS} \rightarrow 5\text{ MSPS}$.
- **Stage 3 (Decimate by 2):** Halves the rate from $5\text{ MSPS} \rightarrow 2.5\text{ MSPS}$.
- **Stage 4 (Decimate by 2):** Halves the rate from $2.5\text{ MSPS} \rightarrow 1.25\text{ MSPS}$.
- **Dynamic Output Selection:** A single-cycle registered multiplexer selects any of the 4 decimated rates at runtime using the `decimation_rate` control bus.

---

## 🏗️ Architecture & Signal Datapath

```
                                  +---------------------------------------+
                                  |       100 MHz Processing Clock        |
                                  +---------------------------------------+
                                                      |
    Complex Input                                     v
    Rx_data [31:0] --------+-------------> [ fir_compiler_st1 ] (÷10)
    {Q[15:0], I[15:0]}     |                      |
    @ 100 MSPS             |                      |--> fir_st1_valid (10 MHz) --------------------> [00]
                           |                      v                                                  |
                           +-------------> [ fir_compiler_st2 ] (÷2)                                 |
                                                  |                                                  |   Registered
                                                  |--> fir_st2_valid (5 MHz) ---------------------> [01] Multiplexer
                                                  v                                                  |   (Select by
                                           [ fir_compiler_st3 ] (÷2)                                 |  decimation_rate)
                                                  |                                                  |       |
                                                  |--> fir_st3_valid (2.5 MHz) -------------------> [10]     |
                                                  v                                                  |       v
                                           [ fir_compiler_st4 ] (÷2)                                 |  decimator_i [15:0]
                                                  |                                                  |  decimator_q [15:0]
                                                  +--> fir_st4_valid (1.25 MHz) ------------------> [11]  decimator_v
```

### Decimation Modes & Specifications

| `decimation_rate` | Selected Stage | Stage Decimation | Cumulative Factor | Output Sample Rate | Output Interval |
|:-----------------:|:--------------:|:----------------:|:-----------------:|:------------------:|:---------------:|
| `2'b00`           | Stage 1        | $\div 10$        | $10\times$        | **10.00 MSPS**     | Every 10 clocks (100 ns) |
| `2'b01`           | Stage 2        | $\div 2$         | $20\times$        | **5.00 MSPS**      | Every 20 clocks (200 ns) |
| `2'b10`           | Stage 3        | $\div 2$         | $40\times$        | **2.50 MSPS**      | Every 40 clocks (400 ns) |
| `2'b11`           | Stage 4        | $\div 2$         | $80\times$        | **1.25 MSPS**      | Every 80 clocks (800 ns) |

---

## 📦 I/Q Word Organization

Input and internal data streams use standard 32-bit interleaved two's complement signed fixed-point samples:

```
 31                    16 15                     0
+------------------------+------------------------+
|    Q (Quadrature)      |      I (In-Phase)      |
|    16-bit Signed       |      16-bit Signed     |
+------------------------+------------------------+
```

* **In-Phase Component ($I$):** `data(15 downto 0)`
* **Quadrature Component ($Q$):** `data(31 downto 16)`
* All intermediate stages preserve this packing to maintain phase coherence and sample synchronization throughout the decimation cascade.

---

## 📂 Repository Structure

Each subdirectory includes dedicated documentation explaining its role and implementation details:

```text
├── README.md                      # Primary repository overview (this file)
├── .gitignore                     # Optimized gitignore for Xilinx Vivado builds
│
├── 00_RTL/                        # Synthesizable RTL source files
│   ├── Configurable_Decimator.vhd # Top-level multi-stage VHDL architecture
│   └── README.md                  # Detailed RTL architecture & port documentation
│
├── 01_Testbench/                  # Simulation testbench & verification environment
│   ├── tb_Configurable_Decimator.v# Behavioral testbench in Verilog
│   └── README.md                  # Testbench methodology & simulation guide
│
├── 02_RESULTS/                    # Simulation waveform captures from Vivado Simulator
│   ├── 00_clock_frequency.png     # Valid pulse timing across all 4 decimation stages
│   ├── 01_Input_Signal.png        # Input polyphase complex I/Q waveform
│   ├── 02_Stage_1_decimation.png  # Stage 1 filtered analog waveforms (10 MSPS)
│   ├── 03_Stage_1_valid.png       # Stage 1 valid strobe periodicity (100 ns)
│   ├── 04_Stage_2_decimation.png  # Stage 2 filtered analog waveforms (5 MSPS)
│   ├── 05_Stage_2_valid.png       # Stage 2 valid strobe periodicity (200 ns)
│   ├── 06_Stage_3_decimation.png  # Stage 3 filtered analog waveforms (2.5 MSPS)
│   ├── 07_Stage_3_valid.png       # Stage 3 valid strobe periodicity (400 ns)
│   ├── 08_Stage_4_decimation.png  # Stage 4 filtered analog waveforms (1.25 MSPS)
│   ├── 09_Stage_4_valid.png       # Stage 4 valid strobe periodicity (800 ns)
│   └── README.md                  # Complete waveform analysis & verification report
│
└── 03_IP_Scripts/                 # AMD/Xilinx FIR Compiler IP Core configuration files
    ├── Stage_1_FIR/               # fir_compiler_st1.xci (Decimate by 10, 100 MSPS)
    ├── Stage_2_FIR/               # fir_compiler_st2.xci (Decimate by 2, 10 MSPS)
    ├── Stage_3_FIR/               # fir_compiler_st3.xci (Decimate by 2, 5 MSPS)
    ├── Stage_4_FIR/               # fir_compiler_st4.xci (Decimate by 2, 2.5 MSPS)
    └── README.md                  # Detailed IP parameters & filter coefficient specifications
```

---

## 🔬 Simulation & Verification Highlights

Simulation was executed in **AMD Vivado Simulator (xsim)** using a 100 MHz clock period (10 ns). The waveforms confirm precise decimation timing and signal integrity across all four cascaded filter stages:

1. **Clock & Rate Distribution (`00_clock_frequency.png`):**
   - Shows all 4 valid strobes concurrently running on the 100 MHz master clock.
   - `fir_st1_valid` pulses every **10 clocks** ($100\text{ ns} \rightarrow 10\text{ MHz}$).
   - `fir_st2_valid` pulses every **20 clocks** ($200\text{ ns} \rightarrow 5\text{ MHz}$).
   - `fir_st3_valid` pulses every **40 clocks** ($400\text{ ns} \rightarrow 2.5\text{ MHz}$).
   - `fir_st4_valid` pulses every **80 clocks** ($800\text{ ns} \rightarrow 1.25\text{ MHz}$).

2. **Analog Waveform Reconstruction (`01_Input_Signal.png` - `08_Stage_4_decimation.png`):**
   - In-phase and quadrature components are displayed in analog format in Vivado Simulator.
   - Demonstrates smooth reconstruction of the decimated complex envelope while suppressing out-of-band aliases.

*(Refer to [`02_RESULTS/README.md`](02_RESULTS/README.md) for full high-resolution waveform walkthroughs and detailed analysis).*

---

## ⚙️ How to Build and Simulate

### Prerequisites
* **AMD Vivado™ ML Edition** (v2024.2 or compatible 2020.x–2024.x versions).
* Device support installed for **AMD Zynq™ UltraScale+™** (`xczu15eg-ffvc900-2-i`).

### Steps in Vivado GUI
1. **Create Project:**
   - Launch Vivado and create an RTL project targeting part `xczu15eg-ffvc900-2-i`.
2. **Add IP Cores:**
   - Go to **Add Sources $\rightarrow$ Add or create IP**.
   - Import the 4 `.xci` files from `03_IP_Scripts/Stage_1_FIR` through `Stage_4_FIR`.
   - Right-click each IP and select **Generate Output Products**.
3. **Add RTL Source:**
   - Add `00_RTL/Configurable_Decimator.vhd`.
4. **Add Simulation Testbench:**
   - Add `01_Testbench/tb_Configurable_Decimator.v` as a simulation source.
5. **Run Behavioral Simulation:**
   - Click **Run Simulation $\rightarrow$ Run Behavioral Simulation**.
   - Set signal radixes for I/Q to Signed Decimal and Waveform Style to Analog for envelope visualization.

---

## 💡 Key Design Decisions & Engineering Trade-offs

1. **Cascaded Multi-Stage vs. Single Large Decimator:**
   - Implementing an $80\times$ decimation in a single stage requires a very narrow transition band relative to the 100 MHz sampling rate, demanding hundreds of taps and excessive DSP48 slices.
   - Cascading $\div 10 \rightarrow \div 2 \rightarrow \div 2 \rightarrow \div 2$ allows each subsequent stage to operate at relaxed transition bandwidths and lower rates, reducing total DSP resources by over **70%**.
2. **Continuous Streaming Architecture (`tready` left open):**
   - In radar ADC receiver pipelines, data arrives continuously in real time. ADCs cannot be backpressured without overflowing front-end FIFOs. Hence, the design uses a continuous-streaming AXI4-Stream valid-qualified architecture.
3. **Synchronous Registered Multiplexer:**
   - The output multiplexer stage is fully registered to prevent combinatorial glitches during decimation rate switching and preserve clean clock-to-out timing.

---

## 👤 Author

**K Sree Sai Venkat**  
FPGA & RTL Design Engineer  
Specialization: Digital Signal Processing (DSP) & High-Speed FPGA Architectures  

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — feel free to use and adapt it for academic and professional reference.
