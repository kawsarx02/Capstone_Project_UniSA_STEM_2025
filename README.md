# Real-Time Detection and Mitigation of ICMP Flood Attacks in Software-Defined Networks

> **University of South Australia (UniSA) — STEM Capstone Project, 2025**

This project demonstrates a small **Software-Defined Networking (SDN)** security lab that detects high-rate ICMP traffic and selectively prevents traffic from an identified source from being forwarded to its destination.

The lab uses **Ryu**, **Mininet**, **Open vSwitch**, **OpenFlow 1.3**, **Docker**, and **hping3**. It was developed and tested as part of a UniSA STEM capstone project in a controlled virtual environment.

---

## Project Objective

The purpose of this project is to demonstrate how an SDN controller can centrally monitor ICMP traffic and respond automatically when a host exceeds a defined traffic threshold.

The controller is designed to:

- monitor ICMP traffic in real time,
- count ICMP packets for each source/destination pair,
- detect high-rate ICMP traffic using a fixed threshold,
- identify the source host as an attacker when the threshold is exceeded,
- prevent packets from that blocked source from being forwarded normally,
- allow legitimate hosts to continue communicating,
- and record controller events and host statistics in CSV files.

This is a **threshold-based academic proof of concept**, not a production intrusion-detection system.

---

## Network Topology

The project is demonstrated with one Open vSwitch and three Mininet hosts:

```text
                 Ryu Controller
                       |
                  OpenFlow 1.3
                       |
                      s1
                 /     |     \
                /      |      \
              h1       h2      h3
          10.0.0.1 10.0.0.2 10.0.0.3
          Attacker   Normal   Target
```

| Host | IP Address | Role |
|---|---|---|
| `h1` | `10.0.0.1` | ICMP flood source |
| `h2` | `10.0.0.2` | Legitimate host |
| `h3` | `10.0.0.3` | Target host |

---

## How Detection Works

The controller currently uses:

```python
THRESHOLD = 50
WINDOW_INTERVAL = 1
```

For each ICMP source/destination pair, the controller counts packets within a one-second window.

When the count becomes **greater than 50**, the source is treated as an attacker.

The controller then:

1. records an `ATTACKER_DETECTED` event,
2. adds the source IP to an in-memory blocked-IP set,
3. installs a higher-priority OpenFlow rule matching traffic from that source,
4. sends later packets from that source to the controller,
5. records those packets as `BLOCKED_PACKET`,
6. and returns without forwarding them to the destination.

> **Important:** the current mitigation is controller-mediated. Blocked-source traffic is redirected to the controller and then not forwarded. A direct OpenFlow drop rule at the switch would be a more efficient future improvement.

---

## Demonstrated Behaviour

The intended test sequence is:

### Before the attack

```text
h1 -> h3   reachable
h2 -> h3   reachable
```

### During the attack

`h1` generates an ICMP flood toward `h3`:

```bash
h1 timeout 3 hping3 -1 --flood 10.0.0.3
```

The controller detects the high packet rate and marks `10.0.0.1` as blocked.

### After detection

```text
h1 -> h3   blocked
h2 -> h3   still reachable
```

In the successful lab test:

- `h1 -> h3` produced **100% packet loss** after blocking.
- `h2 -> h3` continued to work with **0% packet loss**.

This demonstrates selective mitigation: the identified source is blocked while legitimate traffic continues.

---

## Repository Contents

```text
Capstone_Project_UniSA_STEM_2025/
├── .gitignore
├── README.md
├── icmp_guard_v1_6_lts.py
├── start.sh
└── stop.sh
```

### `icmp_guard_v1_6_lts.py`

The main Ryu controller application.

It:

- handles OpenFlow 1.3 switch connections,
- behaves as a simple learning switch,
- inspects IPv4 ICMP packets,
- counts ICMP packets per source/destination pair,
- detects traffic above the configured threshold,
- tracks blocked source IP addresses,
- writes controller events to `controller_log.csv`,
- and writes host statistics to `icmp_rtt_log.csv`.

### `start.sh`

A helper script for the **existing configured lab environment**.

It:

- cleans old Mininet state,
- starts the existing Docker container named `ryu-controller`,
- stops any old copy of the Ryu application inside the container,
- launches the ICMP Guard controller in the background,
- writes Ryu console output to `ryu.log`,
- waits briefly for the controller to start,
- and starts a three-host Mininet topology connected to the controller on TCP port `6653`.

### `stop.sh`

A helper script that:

- cleans Mininet state,
- stops the Ryu application inside the container,
- and stops the `ryu-controller` Docker container.

### `.gitignore`

Keeps local and generated files out of the repository, including:

- the Python virtual environment,
- Python cache files,
- Ryu runtime logs,
- generated CSV logs,
- and other temporary files.

### `README.md`

Contains the project overview, environment details, test procedure, known limitations, and usage instructions.

---

## Tested Environment

The project was successfully reconstructed and tested using:

```text
Apple Silicon Mac
└── UTM
    └── Ubuntu 26.04 ARM64
        ├── Mininet 2.3.0
        ├── Open vSwitch
        ├── hping3
        └── Docker
            └── Ubuntu 20.04 container
                ├── Python 3.8
                └── Ryu 4.34
```

Ryu was placed inside an Ubuntu 20.04 Docker container because the older Ryu/Eventlet dependency stack did not run cleanly with the newer Python environment on the Ubuntu 26.04 host.

---

## Important Setup Note

This repository contains the project code and helper scripts, but it is **not currently a complete installer for a fresh machine**.

The supplied `start.sh` assumes that:

- Mininet is already installed,
- Open vSwitch is already installed and working,
- `hping3` is installed,
- Docker is installed,
- a Docker container named `ryu-controller` already exists,
- that container already contains the compatible Ryu environment,
- and the project directory is mounted inside the container as `/project`.

The helper scripts are therefore intended to make the **existing tested environment** easier to start and stop.

---

## Running the Existing Lab

### Start the lab

From the project directory:

```bash
./start.sh
```

Once Mininet starts, you should see:

```text
mininet>
```

---

## Test Procedure

### 1. Verify initial connectivity

```bash
pingall
```

Expected result:

```text
*** Results: 0% dropped
```

### 2. Test legitimate traffic

```bash
h2 ping -c 5 10.0.0.3
```

Expected result:

```text
5 packets transmitted, 5 received, 0% packet loss
```

### 3. Generate the ICMP flood

Run this only inside the isolated Mininet lab:

```bash
h1 timeout 3 hping3 -1 --flood 10.0.0.3
```

The controller should report the flood detection and blocking activity.

### 4. Verify that the identified attacker is blocked

```bash
h1 ping -c 5 10.0.0.3
```

Expected result in the tested scenario:

```text
5 packets transmitted, 0 received, 100% packet loss
```

### 5. Verify that legitimate traffic still works

```bash
h2 ping -c 5 10.0.0.3
```

Expected result:

```text
5 packets transmitted, 5 received, 0% packet loss
```

---

## Stopping the Lab

Exit Mininet:

```bash
exit
```

Then run:

```bash
./stop.sh
```

This stops the Ryu process, stops the Docker container, and cleans Mininet state.

---

## Runtime Logging

The controller creates two CSV files while it is running.

### `controller_log.csv`

Stores controller events such as:

- `ATTACKER_DETECTED`
- `BLOCK_INSTALLED`
- `BLOCKED_PACKET`

### `icmp_rtt_log.csv`

Stores:

```text
timestamp, host, total, rtt
```

The `total` field is the cumulative ICMP packet count maintained for each source host.

These generated files are excluded from Git through `.gitignore`.

---

## RTT Limitation

The current controller assigns:

```python
self.host_stats[src_ip]['rtt'] = 0.1
```

This is a **placeholder value**, not a real RTT measurement calculated by the controller.

Actual RTT can still be observed from standard Linux `ping` output. Implementing true RTT measurement inside the Ryu application would require additional work.

---

## Current Limitations

The current implementation has several known limitations:

- detection uses a fixed threshold,
- blocked traffic is redirected to the controller rather than dropped directly in the switch,
- the RTT value stored by the controller is a placeholder,
- the blocked-IP list is stored in memory and resets when the Ryu controller restarts,
- the helper scripts depend on a pre-configured Docker/Ryu environment,
- and Ryu 4.34 is an older framework with dependency compatibility constraints.

These limitations reflect the current state of the project and are documented here for clarity.

---

## Possible Future Improvements

Possible improvements include:

- installing a direct OpenFlow drop rule after detection,
- implementing real RTT measurement,
- adding adaptive or dynamic traffic thresholds,
- improving traffic statistics and reporting,
- supporting multiple-switch topologies,
- detecting additional traffic-flood patterns,
- and providing an automated installation process for a fresh environment.

---

## Academic Context

This project was developed as part of the **STEM Capstone Project at the University of South Australia (UniSA) in 2025**.

The project was completed collaboratively by a **team of four students, including myself and three other team members**, under the guidance of a **mentor assigned through UniSA STEM**. The team worked together on the design, implementation, testing, and documentation of the SDN-based ICMP flood detection and mitigation solution.

The project provided practical experience with:

- **Software-Defined Networking (SDN)**
- **OpenFlow**
- **Network security**
- **ICMP flood / DoS detection**
- **Automated network mitigation**
- **Virtualised network testing**
- **Linux networking tools**

---

## Responsible Use

**This project is intended for academic, educational, and authorised laboratory use only.**

The ICMP flood command shown in this README is intended only for the isolated Mininet topology used by this project. Do not generate flood traffic against systems or networks without explicit authorisation.

---

## Author

**Kawsar Mia**  
University of South Australia — STEM Capstone Project, 2025
