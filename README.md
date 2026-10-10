# APB UVC and Verification Environment for an APB Peripheral

A SystemVerilog/UVM verification environment for an APB peripheral (`apb_top`) with a memory space and control registers. The project was developed as part of the bachelor thesis *"Development of a Complete Verification Environment for an APB Module"* (School of Electrical Engineering, University of Belgrade).

The repository contains two main parts:

1. **APB UVC**: a reusable verification component built from scratch, configurable as either a master or a slave agent.
2. **DUT environment**: tests, a scoreboard with a reference model, and a functional coverage model for `apb_top`.

## Table of Contents

- [APB UVC](#apb-uvc)
- [Two Environments](#two-environments)
- [DUT](#dut)
- [Verification Methodology](#verification-methodology)

## APB UVC

The `apb_uvc_pkg` package contains:

| Component | Role |
|---|---|
| `apb_uvc_if` | Interface with built-in SVA assertions (SETUP/ENABLE phases, stability of `PADDR`/`PWRITE`/`PSEL`, `PREADY` duration, `PSLVERR` only with `PREADY`, `PSTRB` on reads, no unknown values after reset) |
| `apb_uvc_item` | Sequence item (address, data, `PSTRB`, operation kind, start delay, `PREADY` delay, `PSLVERR`) |
| `apb_uvc_driver` | Drives signals in `MASTER` or `SLAVE` mode and handles reset in the middle of a transaction |
| `apb_uvc_monitor` | Passively reconstructs transactions and forwards them through analysis ports |
| `apb_uvc_sequencer` | Standard sequencer |
| `apb_uvc_cov` | Functional coverage (operation, `PSTRB`, address, delays, error, and their crosses, reset) |
| `apb_uvc_agent` | Agent (driver + sequencer + monitor + coverage) |
| `apb_uvc_env` | Environment that selects the active agents through `agents_active_bitmap` |
| `apb_uvc_seq_lib` | Sequence library: `write`, `read`, `read_modify_write`, `read_modify_write_read`, `back_to_back`, `master`, `slave` |

Configuration (`apb_uvc_cfg`, `apb_uvc_agent_cfg`):

- `agents_active_bitmap`: `01` master only, `10` slave only, `11` both
- `agent_mode`: `MASTER` or `SLAVE`
- `m_has_coverage`: enables the coverage model inside the agent

Signal widths are set with macros in `apb_uvc_pkg.sv` (`ADDR_WIDTH`, `DATA_WIDTH`, `STRB_WIDTH`).

## Two Environments

### 1. UVC-to-UVC (component self-check)

Before connecting the UVC to the DUT, it is verified against itself: one agent acts as the master and the other as the slave, sharing one interface, with random traffic. This separates bugs in the UVC from bugs in the DUT.

- Top: `apb_uvc_to_uvc_tb_top`
- Test: `test_apb_uvc_to_uvc_example`

### 2. UVC + DUT

The master agent drives `apb_top`, while the monitor feeds two DUT-specific components developed for this environment:

- **Scoreboard** (`apb_scoreboard`): contains a reference model of `apb_top` (address map, RO region, `STATUS`/`CTRL` registers) and automatically compares the observed behavior of the DUT (read data and `PSLVERR`) against the model's prediction for every monitored transaction.
- **Coverage component**: a functional coverage model that crosses protocol states (operation, wait states, errors, byte strobes) with the DUT address map (memory regions, RO region, `STATUS`, `CTRL`, unmapped addresses). It measures whether, for example, an error access has been exercised in every region of the address map.

- Top: `apb_uvc_tb_top`
- Test: `test_apb_uvc_example`

## DUT

`apb_top` is an APB peripheral with a deliberately "interesting" address map, so the scoreboard has something meaningful to check. The DUT has no outputs outside the APB bus.

| `paddr` | Meaning |
|---|---|
| 0..191 | `mem0`..`mem2`, 64 locations each, RW |
| 192..239 | `mem3`, local addresses 0..47, RW |
| 240..255 | `mem3`, local addresses 48..63, **RO** (a write gives `PSLVERR`) |
| 256 | `STATUS`, read-only: `pending`, `cause`, `err_addr` |
| 257 | `CTRL`, RW: bit 0 `ack` (clears `pending`), bit 1 `clear` (zeroes RW memory) |
| 258..511 | unmapped, every access gives `PSLVERR` |

Additional behavior: a random number of wait states (`MAX_WAIT_STATES`, default 3), byte-masked writes through `PSTRB`, an error wins over `ack` in the same cycle, and `clear` intentionally never touches the RO part of `mem3`.

Hierarchy:

```
apb_top
 ├── apb_mem mem0..mem3
 └── apb
```

A detailed description of the registers and behavior rules is in the README of the RTL directory.

## Verification Methodology

- Coverage-driven verification with constrained-random tests
- Automatic checking in the scoreboard against a reference model
- Protocol SVA assertions in the interface
- Functional coverage that crosses protocol states with the device address map
- Progress tracked through both functional coverage

## Author

Mihailo, School of Electrical Engineering, University of Belgrade
