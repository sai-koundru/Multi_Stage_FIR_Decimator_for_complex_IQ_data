# Synthesizable RTL Architecture: Configurable Multi-Stage FIR Decimator

This directory contains the primary synthesizable VHDL architecture for the multi-stage configurable complex decimator.

## 📁 File Manifest

| File | Language | Purpose |
|:---|:---:|:---|
| [`Configurable_Decimator.vhd`](Configurable_Decimator.vhd) | VHDL-93/2008 | Synthesizable top-level wrapper and cascaded filter datapath |

---

## 📐 Entity Port Interface

```vhdl
entity Configurable_Decimator is
  Port (
        clk             : IN  STD_LOGIC;                      -- Main processing clock (100 MHz)
        fir_rst         : IN  STD_LOGIC;                      -- Active-high external reset
        Rx_data         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Complex input sample {Q[15:0], I[15:0]}
        Rx_ttl          : IN  STD_LOGIC;                      -- Reserved hardware trigger pin for radar frame marker
        decimation_rate : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);   -- Output rate selector ("00","01","10","11")
        
        decimator_i     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);  -- Decimated In-Phase (I) output sample
        decimator_q     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);  -- Decimated Quadrature (Q) output sample
        decimator_v     : OUT STD_LOGIC                       -- Valid strobe for selected decimated rate
  );
end Configurable_Decimator;
```

### Port Descriptions

| Port Name | Direction | Width | Logical Level / Encoding | Description |
|:---|:---:|:---:|:---|:---|
| `clk` | Input | 1-bit | Rising Edge | System clock running at 100 MHz. Drives all FIR stages and registered logic. |
| `fir_rst` | Input | 1-bit | Active-High (`'1' = reset`) | Top-level reset. Inverted internally to active-low `aresetn` for FIR Compiler IPs. |
| `Rx_data` | Input | 32-bit | Two's Complement Signed | Complex input word. High half `[31:16]` carries Q, low half `[15:0]` carries I. |
| `Rx_ttl` | Input | 1-bit | Active-High Pulse | Dedicated hardware trigger reserved for Radar PRF / frame start marker. |
| `decimation_rate` | Input | 2-bit | Binary Code | Dynamically selects the active decimated output rate (`00`=10M, `01`=5M, `10`=2.5M, `11`=1.25M). |
| `decimator_i` | Output | 16-bit | Two's Complement Signed | Decimated In-Phase component selected by `decimation_rate`. |
| `decimator_q` | Output | 16-bit | Two's Complement Signed | Decimated Quadrature component selected by `decimation_rate`. |
| `decimator_v` | Output | 1-bit | Active-High Single-Cycle | Valid indicator synchronous to `clk`, pulsing at the selected decimated sample frequency. |

---

## 🔄 Cascaded Architecture & Inter-Stage Connectivity

The core cascades four Xilinx FIR Compiler IP instances. All four stages are clocked synchronously by `clk` (100 MHz). Each downstream stage is triggered exclusively by the `m_axis_data_tvalid` strobe of the preceding stage:

```
+-----------------------------------------------------------------------------------------------------+
|                                          Configurable_Decimator                                     |
|                                                                                                     |
|  Rx_data(31:0)                                                                                      |
|  --------------+                                                                                    |
|                |                                                                                    |
|                v (s_axis_data_tvalid = '1')                                                         |
|         +--------------+ fir_st1_output(31:0)                                                       |
|         | FIR Stage 1  |----------------------+                                                     |
|         |  (÷10 FIR)   |                      |                                                     |
|         +--------------+                      v (s_axis_data_tvalid = fir_st1_valid)                |
|                | fir_st1_valid         +--------------+ fir_st2_output(31:0)                        |
|                | (10 MHz)              | FIR Stage 2  |----------------------+                      |
|                |                       |   (÷2 FIR)   |                      |                      |
|                |                       +--------------+                      v                      |
|                |                              | fir_st2_valid         +--------------+              |
|                |                              | (5 MHz)               | FIR Stage 3  |----+         |
|                |                              |                       |   (÷2 FIR)   |    |         |
|                |                              |                       +--------------+    |         |
|                |                              |                              | fir_st3_valid      |
|                |                              |                              | (2.5 MHz)  |         |
|                |                              |                              v            v         |
|                |                              |                       +--------------+ fir_st4_     |
|                |                              |                       | FIR Stage 4  | output(31:0) |
|                |                              |                       |   (÷2 FIR)   |    |         |
|                |                              |                       +--------------+    |         |
|                |                              |                              | fir_st4_valid        |
|                |                              |                              | (1.25 MHz) |         |
|                v                              v                              v            v         |
|        +------------------------------------------------------------------------------------+       |
|        |                  Registered Multiplexer Process (process(clk))                     |       |
|        |             Selects output based on decimation_rate: "00", "01", "10", "11"        |       |
|        +------------------------------------------------------------------------------------+       |
|                                     |                   |                   |                       |
|                                     v                   v                   v                       |
|                                decimator_i         decimator_q         decimator_v                  |
+-----------------------------------------------------------------------------------------------------+
```

### Inter-Stage Signal Routing

```vhdl
-- Stage 1 to Stage 2 connection
fir_st2_input <= fir_st1_o_q & fir_st1_o_i;

-- Stage 2 to Stage 3 connection
fir_st3_input <= fir_st2_o_q & fir_st2_o_i;

-- Stage 3 to Stage 4 connection
fir_st4_input <= fir_st3_o_q & fir_st3_o_i;
```

---

## 🎛️ Registered Output Multiplexer

To guarantee clean, glitch-free transitions and optimal setup/hold margins during dynamic decimation rate switching, the output assignment is fully registered within a synchronous process:

```vhdl
process(clk) begin
    if rising_edge(clk) then
        if fir_rst = '1' then
            decimator_i_temp <= (others => '0');
            decimator_q_temp <= (others => '0');
            decimator_v_temp <= '0';
        else
            if    decimation_rate = "00" then   
                decimator_i_temp <= fir_st1_o_i;
                decimator_q_temp <= fir_st1_o_q;
                decimator_v_temp <= fir_st1_valid;
            elsif decimation_rate = "01" then   
                decimator_i_temp <= fir_st2_o_i;
                decimator_q_temp <= fir_st2_o_q;
                decimator_v_temp <= fir_st2_valid;
            elsif decimation_rate = "10" then   
                decimator_i_temp <= fir_st3_o_i;
                decimator_q_temp <= fir_st3_o_q;
                decimator_v_temp <= fir_st3_valid;
            elsif decimation_rate = "11" then   
                decimator_i_temp <= fir_st4_o_i;
                decimator_q_temp <= fir_st4_o_q;
                decimator_v_temp <= fir_st4_valid;
            else                                  
                decimator_i_temp <= (others => '0');
                decimator_q_temp <= (others => '0');
                decimator_v_temp <= '0';
            end if;
        end if;
    end if;
end process;
```

---

## ⚙️ Design Considerations

1. **Continuous Real-Time Streaming (`tready => open`):**
   - High-throughput RF front-ends (direct RF-ADC sampling) stream real-time radar echoes continuously. 
   - ADCs cannot stall, so backpressure cannot be applied to the analog front-end. The filter chain is designed to process every valid sample without requiring upstream stalls.
2. **Deterministic Latency:**
   - Because each stage is instantiated and continuously running, switching `decimation_rate` takes effect immediately at the next clock cycle without needing filter pipeline re-priming.
3. **Reset Management:**
   - The top-level design accepts an active-high reset (`fir_rst`), which is inverted internally to `fir_rstn` (`fir_rstn <= not fir_rst;`) to conform to Xilinx AXI IP active-low reset standards (`aresetn`).
