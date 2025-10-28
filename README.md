🏎️ Patcher-4-ArchLinux: High-Performance Configuration Repository

This repository is dedicated to optimizing Arch Linux installations on specific or legacy hardware to achieve maximum stability, performance, and power efficiency. We focus on solving common hardware pain points with kernel parameter tweaks, custom systemd services, and proprietary driver configurations.

🎯 Core Objectives

Performance Maximization: Enforcing high-performance CPU governors and low-latency I/O settings.

Thermal/Power Efficiency: Implementing hardware-level hacks (like the gmux GPU disable) to drastically reduce heat and extend battery life on laptops.

Hardware Stability: Providing validated drivers and configuration files for problematic components (e.g., Broadcom Wi-Fi, Apple SMC sensors).

🗂️ Available Patch Sets

Model

Key Focus

Status

Patch Folder

MacBookPro8,2

AMD GPU disable, cpupower, mbpfan, Broadcom Wi-Fi.

Stable/Tested

MacBookPro8,2-Patches

Future Patches

...

Planning



🚀 Deployment

Clone the repository: git clone [REPO_URL]

Navigate to the patch folder for your specific machine (e.g., cd Patcher-4-ArchLinux/MacBookPro8,2-Patches).

Run the included deployment script: ./deploy-patches.sh

REBOOT to apply all kernel changes.

📜 License

This project is licensed under the MIT License. See the LICENSE file for details.
