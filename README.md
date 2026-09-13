\# REWin



\*\*REWin (Ramazan Erdogan Windows IT Toolkit)\*\* is a PowerShell-based Windows IT toolkit designed to help IT administrators diagnose system health, identify common Windows issues, generate health reports, and perform controlled system repairs.



REWin focuses on practical Windows administration, diagnostics, health scoring, and safe repair workflows from a single command-line interface.



\---



\## Features



\### System Diagnostics



Collects important Windows system information and evaluates the general system condition.



\- Operating system information

\- Windows version and build

\- CPU information

\- Memory information

\- Memory usage

\- System uptime

\- Computer name

\- Domain / Workgroup information

\- Architecture

\- Last boot information

\- System health score



\---



\### Disk Diagnostics



Checks local disk health and storage conditions.



\- Disk information

\- Total capacity

\- Free space

\- Free space percentage

\- Disk status



\---



\### Network Diagnostics



Checks basic network connectivity and TCP connectivity.



\- Network adapter information

\- Connectivity checks

\- TCP 443 connectivity

\- Network health score

\- Network status



\---



\### Windows Update Diagnostics



Checks Windows Update related conditions.



\- Windows Update status

\- Windows Update services

\- Latest installed updates

\- Pending reboot detection

\- Update-related warnings



\---



\### Event Log Diagnostics



Analyzes recent Windows Event Log activity.



\- Critical events

\- Error events

\- Warning events

\- Information events

\- Event statistics

\- Event Log health status



\---



\### Crash Diagnostics



Checks Windows crash-related information.



\- BugCheck events

\- Kernel Power events

\- Minidumps

\- Live Kernel Dumps

\- Memory dump configuration

\- Automatic restart configuration



\---



\### Hardware Diagnostics



Checks important hardware components and device health.



\- CPU information

\- RAM information

\- GPU information

\- Storage health

\- Battery status

\- Device problem detection

\- Network device problems

\- WHEA hardware errors



Virtual devices are evaluated separately from physical hardware problems where appropriate.



\---



\### Security Diagnostics



Checks important Windows security conditions.



\- Microsoft Defender status

\- Real-time protection

\- Defender signatures

\- Windows Firewall

\- UAC status

\- TPM status

\- Secure Boot status

\- BitLocker-related conditions



\---



\## Health Engine



REWin combines diagnostic results into a single health score.



Each diagnostic area has a configurable weight.



| Module | Weight |

|---|---:|

| System | 10 |

| Disk | 15 |

| Network | 15 |

| Windows Update | 10 |

| Event Log | 10 |

| Crash | 15 |

| Hardware | 10 |

| Security | 15 |



The health engine produces:



\- Overall health score

\- Overall health status

\- Module scores

\- Weak areas

\- Health summary



\### Health Status



| Score | Status |

|---:|---|

| 90 - 100 | EXCELLENT |

| 75 - 89 | GOOD |

| 50 - 74 | WARNING |

| 0 - 49 | CRITICAL |



\---



\## Health Report



REWin provides a consolidated health report that combines all diagnostic modules with the Health Engine.



The report includes:



\- Overall score

\- Overall status

\- Module scores

\- Weak areas

\- Attention status

\- Issue counts

\- Recommendations

\- Detailed diagnostic results



An HTML health report is also available from the main menu.



\---



\## Repair Center



REWin includes a controlled Repair Center for common Windows repair operations.



Available repairs:



```text

\[1] System File Repair       \[MEDIUM]

\[2] Component Store Repair   \[MEDIUM]

\[3] DNS Cache Reset          \[LOW]

\[4] Network Stack Reset      \[MEDIUM]

\[5] Windows Update Services  \[LOW]

