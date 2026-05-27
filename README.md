# Cyber City

Verilog implementation of the Cyber City closed-loop resource system.

## Structure

- `src/city_define.vh`: shared constants and FSM states
- `src/department.v`: reusable production department with valid/ready handshakes
- `src/government.v`: central government fund arbiter
- `src/resource_router4.v`: round-robin resource router
- `src/cyber_city_top.v`: integrated city top module
- `tb/tb_cyber_city.v`: simulation testbench for Beginner, Expert, and 6-2 Challenge modes

## Run Simulation

```powershell
iverilog -g2012 -I src -o cyber_city_tb.vvp src/department.v src/government.v src/resource_router4.v src/cyber_city_top.v tb/tb_cyber_city.v
vvp cyber_city_tb.vvp
```

Expected final line:

```text
PASS: Cyber City survived 1000 clocks in all modes.
```
