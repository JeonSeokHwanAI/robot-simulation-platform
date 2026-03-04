# Technical Data Request

**To: Technical Support Department, Changguangxi Intelligent Manufacturing (Wuxi) Co., Ltd.**
**(长广溪智能制造（无锡）有限公司)**

---

| Item | Details |
|------|---------|
| Date | March 3, 2026 |
| Robot Model | G-Series Collaborative Robot R12-135S |
| Controller | K20 |
| Requesting Party | [Your Company Name] |
| Contact Person | [Name / Email / Phone] |

---

## 1. Background

We are building a digital-twin simulation environment for the R12-135S based on **ROS2 (Humble) / Gazebo (Fortress)** for the following purposes:

- Offline trajectory planning and collision detection
- Motion planning verification using MoveIt2
- Simulation-based development of Pick & Place and other process tasks

To achieve this, we need to create a **URDF (Unified Robot Description Format)** model file. The `<inertial>` tag in URDF requires **mass, center-of-gravity coordinates, and inertia tensor** for each link, which directly affect the dynamics accuracy of the simulation.

### Data Already Obtained

We have extracted the following data from the manuals and drawings provided by your company:

| Category | Status | Source |
|----------|--------|--------|
| Basic specifications (payload, reach, precision, speed, etc.) | Confirmed | Manuals + Drawings |
| Joint velocities (J1,2: 150 deg/s, J3: 210 deg/s, J4,5,6: 240 deg/s) | Confirmed | Manuals (consistent across both) |
| Link dimensions (DH-R12-135S drawing) | Confirmed | DH parameter drawing V100 |
| Communication interfaces (EtherCAT, Modbus TCP/RTU, TCP/IP SDK) | Confirmed | Hardware Manual |
| I/O specifications (digital/analog/safety/encoder) | Confirmed | Hardware Manual |

### Data Still Needed

The following data **could not be found** in the existing manuals and drawings. We respectfully request your company to provide them.

---

## 2. Request Items

### [HIGHEST PRIORITY] Item 1: Joint Range-of-Motion Discrepancy

We have identified a discrepancy in the joint motion ranges between two manuals:

| Source Document | J1 | J2 | J3 | J4 | J5 | J6 |
|-----------------|-----|-----|-----|-----|-----|-----|
| "Cobots manual 2025.2.21" p.8 | ±360° | ±360° | ±360° | ±360° | ±360° | **±165°** |
| "Collaborative Robot G12 Hardware User Manual" Appendix A, p.53 | ±360° | ±360° | **±165°** | ±360° | ±360° | ±360° |

**Question: Does the ±165 degree limitation apply to J3 or J6? Please confirm the correct motion range for each joint.**

> Note: These values will be written directly into the URDF `<limit lower="..." upper="..."/>` tag. Incorrect values will cause motion planning failures or collisions.

---

### Item 2: Dynamic Parameters for Each Link

Please provide the dynamic parameters for each link in the following format (corresponding to the URDF `<inertial>` tag):

| Link | Mass (kg) | Center of Gravity — relative to link frame origin | Inertia Tensor (kg-m^2) |
|------|-----------|---------------------------------------------------|------------------------|
| | | x (mm) | y (mm) | z (mm) | Ixx | Iyy | Izz | Ixy | Ixz | Iyz |
| Base | | | | | | | | | | |
| Link 1 | | | | | | | | | | |
| Link 2 | | | | | | | | | | |
| Link 3 | | | | | | | | | | |
| Link 4 | | | | | | | | | | |
| Link 5 | | | | | | | | | | |
| Link 6 | | | | | | | | | | |

**Additional notes:**
- Please specify the reference coordinate frame for the center-of-gravity coordinates (e.g., each link's own frame origin, or DH frame)
- All 6 inertia tensor components are needed (Ixx, Iyy, Izz, Ixy, Ixz, Iyz)
- A CAD mass properties report (e.g., SolidWorks Mass Properties export) is also acceptable
- Reference: The manual states the total robot mass is 36 kg (excluding cables)

---

### Item 3: Precise DH Parameter Table

Please provide the complete DH parameter table for the R12-135S:

| Joint | a (mm) | d (mm) | alpha (deg) | theta offset (deg) |
|-------|--------|--------|-------------|---------------------|
| J1 | | | | |
| J2 | | | | |
| J3 | | | | |
| J4 | | | | |
| J5 | | | | |
| J6 | | | | |

**Please indicate which DH convention is used:**
- [ ] Standard DH (Classic DH)
- [ ] Modified DH (Craig's convention)

> Note: We have made preliminary estimates based on the dimensions from drawing DH-R12-135S (V100, 2024.04.23), but we need your confirmation of the precise values and the DH convention used to ensure kinematic model accuracy.

---

### Item 4: Precise Location of the 176.6mm Offset

The DH parameter drawing DH-R12-135S shows a **176.6mm horizontal offset**.

Please confirm:
1. Which joint segment does this offset belong to? (e.g., between J1 and J2?)
2. Which DH parameter does this offset correspond to? (e.g., the d-value of J2? or the a-value of J1?)

> Note: The correct attribution of this offset directly affects the link length definitions and joint frame positions in the URDF model.

---

### Item 5: TCP/IP SDK Documentation and Network Configuration

The "Collaborative Robot G12 Hardware User Manual" mentions:
> *"TCP/IP SDK programming, detailed usage in Advanced User Guide"*

Please provide:
1. The **Advanced User Guide** (TCP/IP SDK programming guide) in electronic format
2. The **default IP address of the K20 controller** (factory setting)
3. The SDK communication port number
4. A summary of supported SDK commands (joint control, status reading, I/O control, etc.)

> Note: We plan to develop a ROS2 communication interface with the R12 physical robot via the TCP/IP SDK.

---

## 3. Preferred Data Formats

For convenient import into the simulation model, any of the following formats are acceptable (listed by preference):

1. **Excel / CSV spreadsheet** — Most preferred; can be parsed directly
2. **PDF technical document** — Acceptable if it contains tables
3. **CAD mass properties report** — SolidWorks / CATIA / Creo Mass Properties export
4. **Text description** — Any format containing numerical values is acceptable

---

## 4. Reference: How the Requested Data Maps to URDF

| Requested Item | URDF Tag | Purpose |
|----------------|----------|---------|
| Joint motion range | `<limit lower="..." upper="..."/>` | Motion planning boundary constraints |
| Link mass | `<mass value="..."/>` | Dynamics simulation (gravity/inertia) |
| Center of gravity | `<origin xyz="..." rpy="..."/>` | Dynamics simulation (torque calculation) |
| Inertia tensor | `<inertia ixx="..." iyy="..." .../>` | Dynamics simulation (angular acceleration) |
| DH parameters | `<joint>` + `<link>` geometric relationships | Forward/inverse kinematics |

---

## 5. Contact Information

If you have any questions regarding this request, please do not hesitate to contact us:

| Item | Details |
|------|---------|
| Contact Person | [Name] |
| Email | [email@example.com] |
| Phone | [Phone Number] |
| Company | [Company Name] |

Thank you very much for your technical support! This data will help us build a high-fidelity
digital-twin simulation model and fully leverage the performance capabilities of the R12-135S
collaborative robot.

We look forward to your reply.

---

*This request was prepared by [Company Name] on March 3, 2026.*
