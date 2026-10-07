# ICMP Guard — Real-Time ICMP Flood Detection & Mitigation in SDN

> **University of South Australia (UniSA) — STEM Capstone Project, 2025**

ICMP Guard is a Software-Defined Networking (SDN) security project designed to **detect and mitigate ICMP flood attacks in real time**.

The project uses **Ryu**, **Mininet**, **Open vSwitch**, and **OpenFlow 1.3** to monitor ICMP traffic, identify suspicious packet rates, block malicious hosts, and preserve legitimate network communication.

---

## Project Objective

The goal of this project is to demonstrate how an SDN controller can centrally monitor network traffic and automatically respond to an ICMP flood attack.

The controller continuously observes ICMP traffic and applies a threshold-based detection mechanism. When a source host exceeds the configured ICMP packet threshold, it is identified as malicious and mitigation is applied.

**The key objective is selective mitigation: the attacking host is blocked while legitimate hosts continue to communicate normally.**

---

## Network Topology

```text
                 Ryu SDN Controller
                        |
                    OpenFlow 1.3
                        |
                       s1
                  /     |     \
                 /      |      \
               h1       h2      h3
            10.0.0.1 10.0.0.2 10.0.0.3
            Attacker   Normal   Victim
```

| Host | IP Address | Role |
|---|---|---|
| `h1` | `10.0.0.1` | Attacker |
| `h2` | `10.0.0.2` | Legitimate host |
| `h3` | `10.0.0.3` | Victim |

---

## Key Features

- **Real-time ICMP traffic monitoring**
- **Per-host flood detection**
- **Threshold-based attack identification**
- **Automatic mitigation of malicious hosts**
- **Selective blocking while legitimate traffic remains available**
- **OpenFlow 1.3 integration**
- **Mininet-based SDN test environment**
- **CSV-based controller and host activity logging**
- **Reusable start and stop scripts for easier lab operation**

---

## Detection Logic

The controller currently uses:

```python
THRESHOLD = 50
WINDOW_INTERVAL = 1
```

This means that when the controller observes **more than 50 ICMP packets within a 1-second window** for the same source/destination pair, the source host is treated as an attacker.

Once detected, the malicious source IP is added to the controller's blocked-host list and its traffic is prevented from being forwarded normally.

---

## Technologies Used

- **Python**
- **Ryu SDN Controller**
- **Mininet**
- **Open vSwitch**
- **OpenFlow 1.3**
- **Docker**
- **Ubuntu Linux**
- **hping3**

---

## Repository Structure

```text
Capstone_Project_UniSA_STEM_2025/
├── .gitignore
├── README.md
├── icmp_guard_v1_6_lts.py
├── start.sh
└── stop.sh
```

### File Overview

**`icmp_guard_v1_6_lts.py`**  
Main Ryu SDN controller application. It monitors ICMP traffic, detects floods, records host statistics, identifies attackers, and applies mitigation.

**`start.sh`**  
Starts the existing Docker container, launches the Ryu controller, cleans any old Mininet state, and starts the Mininet topology.

**`stop.sh`**  
Stops the Ryu controller, stops the Docker container, and cleans remaining Mininet processes and interfaces.

**`.gitignore`**  
Prevents virtual environments, runtime logs, temporary files, and generated experiment data from being committed to the repository.

**`README.md`**  
Project documentation and usage instructions.

---

## Tested Environment

The project was successfully tested using:

```text
macOS
└── UTM Virtual Machine
    └── Ubuntu
        ├── Mininet
        ├── Open vSwitch
        └── Docker
            └── Ubuntu 20.04
                └── Ryu 4.34
```

**Why Docker is used for Ryu:**  
Ryu 4.34 relies on older Python/Eventlet dependencies. Running Ryu inside an Ubuntu 20.04 Docker container provides a compatible environment while Mininet and Open vSwitch run on the Ubuntu VM.

---

## Prerequisites

Before running the project, ensure the following are available:

- Ubuntu Linux
- Mininet
- Open vSwitch
- Docker
- hping3
- Existing `ryu-controller` Docker container with Ryu 4.34 configured

---

## Running the Project

### 1. Start the Lab

From the project directory:

```bash
./start.sh
```

The script will:

1. Clean old Mininet state
2. Start the existing Ryu Docker container
3. Stop any leftover Ryu process
4. Start the ICMP Guard controller
5. Launch the Mininet topology

Once Mininet starts, you should see:

```text
mininet>
```

---

## Demonstration Procedure

### Step 1 — Verify Network Connectivity

At the Mininet prompt:

```bash
pingall
```

Expected result:

```text
*** Results: 0% dropped
```

---

### Step 2 — Test Legitimate Traffic

```bash
h2 ping -c 5 10.0.0.3
```

Expected result:

```text
5 packets transmitted, 5 received, 0% packet loss
```

---

### Step 3 — Simulate an ICMP Flood Attack

Use `h1` as the attacker:

```bash
h1 timeout 3 hping3 -1 --flood 10.0.0.3
```

> **Important:** Use this command only inside the isolated Mininet lab environment.

The controller should detect the abnormal ICMP packet rate and identify `10.0.0.1` as malicious.

Example controller output:

```text
ICMP Flood Detected src=10.0.0.1 dst=10.0.0.3
BLOCK_INSTALLED: 10.0.0.1
```

---

### Step 4 — Confirm the Attacker Is Blocked

```bash
h1 ping -c 5 10.0.0.3
```

Expected result:

```text
5 packets transmitted, 0 received, 100% packet loss
```

---

### Step 5 — Confirm Legitimate Traffic Still Works

```bash
h2 ping -c 5 10.0.0.3
```

Expected result:

```text
5 packets transmitted, 5 received, 0% packet loss
```

**This is the main result of the project: the attacker is isolated while legitimate communication continues.**

---

## Example Successful Result

```text
Before Attack
-------------
h1 -> h3   Reachable
h2 -> h3   Reachable

Attack
------
h1 -> h3   ICMP Flood

Controller Response
-------------------
Flood detected
Attacker identified: 10.0.0.1
Mitigation activated

After Attack
------------
h1 -> h3   Blocked
h2 -> h3   Still reachable
```

---

## Logging

The controller generates runtime CSV logs for analysis.

### `controller_log.csv`

Stores security-related events such as:

- attacker detection
- block installation
- blocked packet activity

### `icmp_rtt_log.csv`

Stores host activity information including:

- timestamp
- host IP address
- cumulative ICMP packet count
- RTT field

These runtime files are excluded from the repository through `.gitignore`.

---

## Current Limitations

- The controller currently uses a **fixed threshold** rather than an adaptive detection model.
- The RTT value stored by the controller is currently a **placeholder value**, not a true RTT measurement.
- The current mitigation approach forwards blocked-source traffic to the controller and stops forwarding there; a more efficient production design would install a direct OpenFlow drop rule on the switch.
- Ryu is an older SDN framework and requires a compatible Python/Eventlet environment.

---

## Future Improvements

Potential improvements include:

- Real RTT measurement
- Direct OpenFlow drop rules
- Adaptive or dynamic thresholds
- Packet-per-second traffic graphs
- Real-time monitoring dashboard
- Multiple-switch SDN topologies
- Additional attack detection methods
- Automated experiment reporting
- Full Docker-based deployment

---

## Stop the Lab

Exit Mininet:

```bash
exit
```

Then stop and clean the lab:

```bash
./stop.sh
```

This stops Ryu, stops the Docker container, and cleans Mininet state.

---

## Academic Context

This project was developed as part of the **STEM Capstone Project at the University of South Australia (UniSA) in 2025**.

It demonstrates practical knowledge in:

- Software-Defined Networking
- OpenFlow
- Network security
- ICMP flood / DoS detection
- Automated network mitigation
- Virtualised network testing
- Linux networking tools

---

## Disclaimer

**This project is intended strictly for academic, educational, and authorised laboratory use.**

Traffic-generation tools such as `hping3 --flood` should only be used inside isolated test environments such as Mininet or on systems where explicit permission has been granted.

---

## Author

**Kawsar Mia**  
University of South Australia — STEM Capstone Project, 2025
