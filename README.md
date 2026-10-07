# Real-Time Detection and Mitigation of ICMP Flood Attacks in Software-Defined Networks

> **University of South Australia (UniSA) — STEM Capstone Project, 2025**

This capstone project presents a **Software-Defined Networking (SDN) security solution** for detecting and mitigating ICMP flood attacks in real time. It uses **Ryu**, **Mininet**, **Open vSwitch**, **OpenFlow 1.3**, **Docker**, and **hping3** to monitor ICMP traffic, identify a high-rate source, block that source, and preserve communication for legitimate hosts.

## Project Objective

The project demonstrates how an SDN controller can centrally monitor ICMP traffic and respond automatically when a source exceeds a defined traffic threshold.

The controller:

- monitors ICMP traffic,
- counts packets for each source/destination pair,
- detects high-rate ICMP traffic using a fixed threshold,
- identifies the source as an attacker,
- prevents blocked-source packets from being forwarded normally,
- allows legitimate hosts to continue communicating,
- and records controller events and host statistics in CSV files.

## Network Topology

```text
                 Ryu Controller
                       |
                  OpenFlow 1.3
                       |
                      s1
                 /     |     \
               h1      h2      h3
           10.0.0.1 10.0.0.2 10.0.0.3
           Attacker   Normal   Target
```

| Host | IP Address | Role |
|---|---|---|
| `h1` | `10.0.0.1` | ICMP flood source |
| `h2` | `10.0.0.2` | Legitimate host |
| `h3` | `10.0.0.3` | Target host |

## Detection Logic

The controller currently uses:

```python
THRESHOLD = 50
WINDOW_INTERVAL = 1
```

If more than **50 ICMP packets** are observed for the same source/destination pair within a **1-second window**, the source is treated as an attacker.

The source IP is added to an in-memory blocked list. Later packets from that source are sent to the controller and are not forwarded to the destination.

> The current mitigation is controller-mediated rather than a direct OpenFlow drop rule at the switch.

## Repository Contents

```text
Capstone_Project_UniSA_STEM_2025/
├── .gitignore
├── README.md
├── icmp_guard_v1_6_lts.py
├── start.sh
├── stop.sh
└── visual.py
```

- **`icmp_guard_v1_6_lts.py`** — main Ryu controller for ICMP monitoring, threshold-based detection, blocking, and CSV logging.
- **`start.sh`** — starts the existing Docker/Ryu environment and launches the three-host Mininet topology.
- **`stop.sh`** — stops Ryu, stops the Docker container, and cleans Mininet.
- **`visual.py`** — basic Pandas/Matplotlib visualization for generated ICMP statistics.
- **`.gitignore`** — excludes local environments, logs, cache files, and generated CSV files.
- **`README.md`** — project documentation and usage instructions.

## Tested Environment

```text
Apple Silicon Mac
└── UTM
    └── Ubuntu 26.04 ARM64
        ├── Mininet 2.3.0
        ├── Open vSwitch
        ├── hping3
        └── Docker
            └── Ubuntu 20.04
                ├── Python 3.8
                └── Ryu 4.34
```

Ryu runs inside an Ubuntu 20.04 Docker container because its older dependency stack is not compatible with the newer Python environment on the Ubuntu host.

## Running the Project

> `start.sh` assumes that Mininet, Open vSwitch, Docker, hping3, and the configured `ryu-controller` container already exist.

Start the project:

```bash
./start.sh
```

Once Mininet starts, verify connectivity:

```bash
pingall
```

Test legitimate traffic:

```bash
h2 ping -c 5 10.0.0.3
```

Generate the ICMP flood from `h1` to `h3`:

```bash
h1 timeout 3 hping3 -1 --flood 10.0.0.3
```

Verify that `h1` is blocked:

```bash
h1 ping -c 5 10.0.0.3
```

Verify that `h2` can still reach `h3`:

```bash
h2 ping -c 5 10.0.0.3
```

In the successful test, `h1 -> h3` resulted in **100% packet loss** after blocking, while `h2 -> h3` continued with **0% packet loss**.

Stop the project:

```bash
exit
./stop.sh
```

## Logging

The controller creates:

- **`controller_log.csv`** — detection, block-installation, and blocked-packet events.
- **`icmp_rtt_log.csv`** — timestamp, host, cumulative ICMP packet count, and RTT field.

These generated files are excluded from Git.

## Current Limitations

- Detection uses a fixed threshold.
- Blocked traffic is redirected to the controller instead of being dropped directly at the switch.
- The RTT value stored by the controller is currently a placeholder (`0.1`), not a measured RTT.
- `visual.py` uses the placeholder RTT values and fixed example positions for attack and mitigation timing.
- The blocked-IP list is stored in memory and resets when Ryu restarts.
- The helper scripts depend on a pre-configured Docker/Ryu environment.

## Academic Context

This project was developed as part of the **STEM Capstone Project at the University of South Australia (UniSA) in 2025**.

It was completed by a **team of four students, including myself and three other team members**, under the guidance of a **mentor assigned through UniSA STEM**. The team worked collaboratively on the design, implementation, testing, and documentation of the project.

The project provided practical experience with:

- **Software-Defined Networking (SDN)**
- **OpenFlow**
- **Network security**
- **ICMP flood / DoS detection**
- **Automated network mitigation**
- **Virtualised network testing**
- **Linux networking tools**

## Responsible Use

**This project is intended for academic, educational, and authorised testing only.**

The ICMP flood command shown above should only be used in the isolated Mininet environment or on systems where explicit permission has been granted.

## Author

**Kawsar Mia**  
University of South Australia — STEM Capstone Project, 2025
