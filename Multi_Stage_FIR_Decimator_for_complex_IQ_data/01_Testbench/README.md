# Testbench & Verification Environment: Configurable FIR Decimator

This directory contains the behavioral simulation testbench used to verify the multi-stage configurable complex decimator in AMD Vivado Simulator (`xsim`).

## 📁 File Manifest

| File | Language | Purpose |
|:---|:---:|:---|
| [`tb_Configurable_Decimator.v`](tb_Configurable_Decimator.v) | Verilog (IEEE 1364) | Top-level testbench for functional and timing verification |

---

## 🎯 Verification Objectives

The testbench is structured to validate:
1. **Reset Behavior & Sequence:** Verification of system behavior during active-high `fir_rst` assertion and clean recovery after deassertion.
2. **Clock Generation:** Verification at a continuous 100 MHz reference frequency (10 ns clock period).
3. **Decimation Rate Timing:** Measuring the exact pulse period of the `decimator_v` valid output for all four selection modes (`2'b00`, `2'b01`, `2'b10`, `2'b11`).
4. **Signal Integrity & I/Q Coherence:** Ensuring that both the In-Phase (`decimator_i`) and Quadrature (`decimator_q`) paths maintain identical group delay, phase relationship, and sample timing.
5. **Dynamic Mode Switching:** Confirming glitch-free output multiplexing when switching between decimation ratios during continuous operation.

---

## ⏱️ Testbench Architecture & Timing Setup

```verilog
`timescale 1ns / 1ps

module tb_Configurable_Decimator;
    reg         clk            ;
    reg         fir_rst        ;
    reg  [31:0] Rx_data        ;
    reg         Rx_ttl         ;
    reg  [ 1:0] decimation_rate;
    wire [15:0] decimator_i    ;
    wire [15:0] decimator_q    ;
    wire        decimator_v    ;
```

### Clock Generation
A 100 MHz master clock is synthesized using a 10 ns period (5 ns half-period toggle):
```verilog
always #5 clk = ~clk;  // 100 MHz System Clock (T = 10 ns)
```

### Reset & Control Sequence
```verilog
initial begin
    clk             = 0;
    decimation_rate = 2'd3;  // Select Stage 4 (1.25 MHz)
    fir_rst         = 1;     // Assert reset
    #100;
    fir_rst         = 0;     // Release reset
end
```

---

## 📋 Comprehensive Verification Sequence

To thoroughly exercise all cascaded filter stages, the test sequence proceeds through the following phases:

```
[Phase 1: Power-on & Reset]
  ├── Assert fir_rst = 1 for 100 ns (10 clock cycles)
  └── Deassert fir_rst = 0; initialize input streaming

[Phase 2: Stage 1 Verification (decimation_rate = 2'b00)]
  ├── Target: 10 MSPS Output (Decimate by 10)
  ├── Expected decimator_v strobe period: 100 ns (10 clk cycles)
  └── Verify In-Phase & Quadrature envelope downsampling

[Phase 3: Stage 2 Verification (decimation_rate = 2'b01)]
  ├── Target: 5 MSPS Output (Decimate by 20 cumulative)
  ├── Expected decimator_v strobe period: 200 ns (20 clk cycles)
  └── Verify subsequent factor-of-2 decimation

[Phase 4: Stage 3 Verification (decimation_rate = 2'b10)]
  ├── Target: 2.5 MSPS Output (Decimate by 40 cumulative)
  ├── Expected decimator_v strobe period: 400 ns (40 clk cycles)
  └── Verify subsequent factor-of-2 decimation

[Phase 5: Stage 4 Verification (decimation_rate = 2'b11)]
  ├── Target: 1.25 MSPS Output (Decimate by 80 cumulative)
  ├── Expected decimator_v strobe period: 800 ns (80 clk cycles)
  └── Verify final narrow-band decimation output
```

---

## 🚀 Running the Simulation in AMD Vivado

### Method 1: Using Vivado GUI
1. Open your project in **Vivado 2024.2**.
2. Under the **Sources** hierarchy, expand **Simulation Sources $\rightarrow$ sim_1**.
3. Right-click `tb_Configurable_Decimator` and select **Set as Top**.
4. In the Flow Navigator, click **Run Simulation $\rightarrow$ Run Behavioral Simulation**.
5. Once the waveform window opens:
   - Select signals `decimator_i`, `decimator_q`, `Rx_data`.
   - Right-click $\rightarrow$ **Radix** $\rightarrow$ **Signed Decimal**.
   - Right-click $\rightarrow$ **Waveform Style** $\rightarrow$ **Analog**.
6. Run the simulation for at least **1 ms** (`run 1ms;`) to capture complete radar pulse envelopes across all decimation stages.

### Method 2: Batch / Tcl Execution
In the Vivado Tcl Console:
```tcl
launch_simulation -mode behavioral
run 1000 us
```

---

## 📊 Expected Output Summary

| Observation Signal | Parameter | Expected Value | Measured in Waveforms |
|:---|:---|:---:|:---:|
| `clk` | Period / Frequency | 10.0 ns / 100.0 MHz | 10.0 ns / 100.0 MHz |
| `fir_st1_valid` | Strobe Period | 100.0 ns | 100.0 ns (10 MSPS) |
| `fir_st2_valid` | Strobe Period | 200.0 ns | 200.0 ns (5.0 MSPS) |
| `fir_st3_valid` | Strobe Period | 400.0 ns | 400.0 ns (2.5 MSPS) |
| `fir_st4_valid` | Strobe Period | 800.0 ns | 800.0 ns (1.25 MSPS) |
| `decimator_v` | Mode `00` Interval | 100 ns | Confirmed |
| `decimator_v` | Mode `01` Interval | 200 ns | Confirmed |
| `decimator_v` | Mode `10` Interval | 400 ns | Confirmed |
| `decimator_v` | Mode `11` Interval | 800 ns | Confirmed |

Refer to [`02_RESULTS/README.md`](../02_RESULTS/README.md) for full screenshots and detailed timing analysis.
