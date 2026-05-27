# Cyber City

Verilog implementation of the Cyber City closed-loop resource system.

## Table of Contents

- [Project Directory](#project-directory)
- [System Architecture](#system-architecture)
- [Resource Flow](#resource-flow)
- [Module Responsibilities](#module-responsibilities)
- [Structure](#structure)
- [Run Simulation](#run-simulation)

## Project Directory

```text
cybercity/
|-- README.md
|-- Cyber City.pdf
|-- Cyber City.md
|-- Hint.txt
|-- src/
|   |-- city_define.vh
|   |-- department.v
|   |-- government.v
|   |-- resource_router4.v
|   `-- cyber_city_top.v
`-- tb/
    `-- tb_cyber_city.v
```

## System Architecture

Cyber City is a closed-loop resource economy. Each department is modeled as a
registered valid/ready producer-consumer block. A transfer is accepted only
when `valid && ready` are both high on a clock edge.

```text
                    tax
        +--------------------------+
        |                          v
+----------------+       +----------------+
|   Commerce     |       |  Government    |
| funds producer |       | fund arbiter   |
+----------------+       +----------------+
      ^   ^   ^             |        |
      |   |   |             |        |
      |   |   |             v        v
      |   |   |        +--------+ +--------+
      |   |   +--------| Power  | | Water  |
      |   | electricity+--------+ +--------+
      |   |                 |        |
      |   |                 v        v
      |   |             resource routers
      |   |                 |        |
      |   +-----------------+        |
      | labor                       water
      |                              |
+-------------+      labor     +-------------+
| Residential |--------------->|  Industry   |
| labor maker |                | material    |
+-------------+                +-------------+
                                      |
                                      v
                                  Commerce
```

## Resource Flow

The integrated top module wires the six logical departments into the handout's
economy:

1. Government sends funds to the power plant and water plant.
2. Power plant consumes funds and water, then produces electricity.
3. Water plant consumes funds and electricity, then produces water.
4. Residential area consumes water and electricity, then produces labor.
5. Industry consumes electricity and labor, then produces materials.
6. Commerce consumes materials, electricity, and labor, then produces tax
   income back to the government.

Routers distribute shared resources through registered round-robin arbitration:

- Electricity goes to water, residential, industry, and commerce.
- Water goes to power and residential.
- Labor goes to industry and commerce.
- Materials go to commerce.

## Module Responsibilities

- `cyber_city_top`: top-level integration of all departments and routers.
- `government`: stores city funds and issues registered grants.
- `department`: reusable production engine for all non-government departments.
- `resource_router4`: one-input, four-output round-robin valid/ready router.
- `city_define.vh`: shared constants, resource width, reset values, and FSM
  state definitions.
- `tb_cyber_city`: runs Beginner, Expert, and 6-2 Challenge modes for 1000
  clocks and fails if any module enters `S_DEAD`.

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
