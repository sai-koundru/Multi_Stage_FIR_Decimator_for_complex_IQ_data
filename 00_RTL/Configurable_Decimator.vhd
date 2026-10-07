----------------------------------------------------------------------------------
-- Engineer         : K SREE SAI VENKAT
-- Create Date      : 24.11.2025 09:50:00
-- Design Name      : Configurable_Decimator
-- Project Name     : RADAR_RX
-- Target Devices   : MPSoC (xczu15eg-ffvc900-2-i)
-- Tool Versions    : 2024.2
-- Description      : Multi-Stage Cascaded FIR Decimator for Complex (I/Q) Data
--                    Supports runtime selectable decimation rates (10MHz, 5MHz, 2.5MHz, 1.25MHz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Configurable_Decimator is
  Port (
        clk                     : IN STD_LOGIC;
        fir_rst                 : IN STD_LOGIC;
        Rx_data                 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Rx_ttl                  : IN STD_LOGIC; -- Reserved hardware trigger pin for received frame marker
        decimation_rate         : IN STD_LOGIC_VECTOR(1 DOWNTO 0);        
        
        decimator_i             : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        decimator_q             : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        decimator_v             : OUT STD_LOGIC
    );
end Configurable_Decimator;


architecture Behavioral of Configurable_Decimator is

COMPONENT fir_compiler_st1
  PORT (
    aresetn             : IN STD_LOGIC;
    aclk                : IN STD_LOGIC;
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;


COMPONENT fir_compiler_st2
  PORT (
    aresetn             : IN STD_LOGIC;
    aclk                : IN STD_LOGIC;
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;


COMPONENT fir_compiler_st3
  PORT (
    aresetn             : IN STD_LOGIC;
    aclk                : IN STD_LOGIC;
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;


COMPONENT fir_compiler_st4
PORT (
    aresetn             : IN STD_LOGIC;
    aclk                : IN STD_LOGIC;
    s_axis_data_tvalid  : IN STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT;

signal fir_rstn : std_logic := '1';

signal fir_st1_output   : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st1_valid    : std_logic := '0';
signal fir_st1_o_i      : std_logic_vector(15 downto 0) := (others => '0');
signal fir_st1_o_q      : std_logic_vector(15 downto 0) := (others => '0');

signal fir_st2_input    : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st2_output   : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st2_valid    : std_logic := '0';
signal fir_st2_o_i      : std_logic_vector(15 downto 0) := (others => '0');
signal fir_st2_o_q      : std_logic_vector(15 downto 0) := (others => '0');

signal fir_st3_input    : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st3_output   : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st3_valid    : std_logic := '0';
signal fir_st3_o_i      : std_logic_vector(15 downto 0) := (others => '0');
signal fir_st3_o_q      : std_logic_vector(15 downto 0) := (others => '0');

signal fir_st4_input    : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st4_output   : std_logic_vector(31 downto 0) := (others => '0');
signal fir_st4_valid    : std_logic := '0';
signal fir_st4_o_i      : std_logic_vector(15 downto 0) := (others => '0');
signal fir_st4_o_q      : std_logic_vector(15 downto 0) := (others => '0');

signal decimator_i_temp : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
signal decimator_q_temp : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
signal decimator_v_temp : STD_LOGIC := '0';
     
begin

fir_rstn <= not fir_rst;

-- Stage 1: Decimation by 10 (100 MHz -> 10 MHz)
fir_st1_10mhz : fir_compiler_st1
PORT MAP (
    aresetn             => fir_rstn,
    aclk                => clk,
    s_axis_data_tvalid  => '1',
    s_axis_data_tready  => open,
    s_axis_data_tdata   => Rx_data,
    m_axis_data_tvalid  => fir_st1_valid,
    m_axis_data_tdata   => fir_st1_output
);

fir_st1_o_i <= fir_st1_output(15 downto 0);
fir_st1_o_q <= fir_st1_output(31 downto 16);

fir_st2_input <= fir_st1_o_q & fir_st1_o_i;

-- Stage 2: Decimation by 2 (10 MHz -> 5 MHz)
fir_st2_5mhz : fir_compiler_st2
PORT MAP (
    aresetn             => fir_rstn,
    aclk                => clk,
    s_axis_data_tvalid  => fir_st1_valid,
    s_axis_data_tready  => open,
    s_axis_data_tdata   => fir_st2_input,
    m_axis_data_tvalid  => fir_st2_valid,
    m_axis_data_tdata   => fir_st2_output
);

fir_st2_o_i <= fir_st2_output(15 downto 0); 
fir_st2_o_q <= fir_st2_output(31 downto 16);

fir_st3_input <= fir_st2_o_q & fir_st2_o_i;
      
-- Stage 3: Decimation by 2 (5 MHz -> 2.5 MHz)
fir_st3_2p5mhz : fir_compiler_st3
PORT MAP (
    aresetn             => fir_rstn,
    aclk                => clk,
    s_axis_data_tvalid  => fir_st2_valid,
    s_axis_data_tready  => open,
    s_axis_data_tdata   => fir_st3_input,
    m_axis_data_tvalid  => fir_st3_valid,
    m_axis_data_tdata   => fir_st3_output
);

fir_st3_o_i <= fir_st3_output(15 downto 0); 
fir_st3_o_q <= fir_st3_output(31 downto 16);

fir_st4_input <= fir_st3_o_q & fir_st3_o_i;    
    
-- Stage 4: Decimation by 2 (2.5 MHz -> 1.25 MHz)
fir_st4_1p25mhz : fir_compiler_st4
PORT MAP (
    aresetn             => fir_rstn,
    aclk                => clk,
    s_axis_data_tvalid  => fir_st3_valid,
    s_axis_data_tready  => open,
    s_axis_data_tdata   => fir_st4_input,
    m_axis_data_tvalid  => fir_st4_valid,
    m_axis_data_tdata   => fir_st4_output
);

fir_st4_o_i <= fir_st4_output(15 downto 0); 
fir_st4_o_q <= fir_st4_output(31 downto 16);


-- Registered Multiplexer for Output Rate Selection
process(clk) begin
    if rising_edge(clk) then
        if fir_rst = '1' then
            decimator_i_temp <= (others => '0');
            decimator_q_temp <= (others => '0');
            decimator_v_temp <= '0';
        else
            if      decimation_rate = "00" then   
                decimator_i_temp <= fir_st1_o_i;
                decimator_q_temp <= fir_st1_o_q;
                decimator_v_temp <= fir_st1_valid;
            elsif   decimation_rate = "01" then   
                decimator_i_temp <= fir_st2_o_i;
                decimator_q_temp <= fir_st2_o_q;
                decimator_v_temp <= fir_st2_valid;
            elsif   decimation_rate = "10" then   
                decimator_i_temp <= fir_st3_o_i;
                decimator_q_temp <= fir_st3_o_q;
                decimator_v_temp <= fir_st3_valid;
            elsif   decimation_rate = "11" then   
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

decimator_i <= decimator_i_temp;
decimator_q <= decimator_q_temp;
decimator_v <= decimator_v_temp;
   
end Behavioral;
