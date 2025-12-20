# VSDSquadron FPGA Mini Internship - Task 1 Submission

## Setting up GitHub Codespace

>Fork the `vsd-riscv2` repository and create a GitHub codespace

**Steps:**
1. Fork the repository - https://github.com/vsdip/vsd-riscv2
2. Launch the GitHub Codespace and build it successfully.

**Glimpse of Codespace:**
![](images/9.png)
___
## Verifying RISC-V Reference Flow

>Build and run the provided fundamental RISC-V programs, and observe successful execution on console 

**Steps:**
1. Verify the setup.
2. Run the provided programs using RISC-V GCC and Spike.
3. Test the working of RISC-V GCC, Spike and Iverilog using custom programs.

### Setup Verification
**Commands:**
```bash
riscv64-unknown-elf-gcc --version
spike --version
iverilog -V
```

**Output:**




### Program 1 : `sum1ton.c`
**Commands:**
```bash
# Navigate to 'samples' directory
cd samples 
# Compile the program
riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
# Load and execute the program
spike pk sum1ton.o
```

**Output:**

![](images/10.png)


### Program 2 : `1ton_custom.c`
**Commands:**
```bash
# Compile the program and link with assembly code
riscv64-unknown-elf-gcc -o 1ton_custom.o 1ton_custom.c load.S
# Load and execute the program
spike pk 1ton_custom.o
```

**Output:**

![](images/11.png)


### Custom Program : `factorial.c`
**Commands:**
```bash
riscv64-unknown-elf-gcc -o factorial.o factorial.c
spike pk factorial.o
```

**Output:**

![](images/12.png)


### Verilog Program : `adder.v` (with testbench `tb.v`)
**Commands:**
```bash
# Compile the Verilog program
iverilog -o adder adder.v tb.v
# Simulate the testbench
vvp adder
```

**Output:**

![](images/13.png)
___
## Verifying the Working of GUI Desktop (noVNC)

>Build and run programs using Native GCC and RISC-V GCC on noVNC desktop

**Steps:**
1. Launch the noVNC Desktop by clicking on the Forwarded Address Link for port `noVNC Desktop 6080` in `PORTS` tab.
2. Click on `vnc_lite.html` in the new browser tab that opens after Step 1. 
3. Open the terminal in noVNC desktop.
4. Compare the native and RISC-V compilers by running a program using both.

### Glimpse of Desktop
![](images/14.png)

### Run Program using Native GCC
![](images/15.png)

### Run Program using RISC-V GCC and Spike
![](images/16.png)
___
## Clone and Build the VSDFPGA Labs

>Build and run the basic labs that do not require FPGA hardware

**Steps:**
1. Install the prerequisites i.e., general dependencies, FPGA toolchain & RISC-V toolchain.
2. Clone the repository https://github.com/vsdip/vsdfpga_labs inside the current repository.
3. Build the firmware and FPGA bitstream and flash to FPGA.
4. Run the lab.

### Prerequisites installation
**Commands:**
```bash
# General dependencies
sudo apt-get install git vim autoconf automake autotools-dev curl libmpc-dev \
libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool \
patchutils bc zlib1g-dev libexpat1-dev gtkwave picocom -y

# FPGA toolchain (Yosys/NextPNR/IceStorm)
sudo apt-get install yosys nextpnr-ice40 fpga-icestorm iverilog -y

# RISC-V Toolchain (GCC 8.3.0)
cd ~
mkdir -p riscv_toolchain && cd riscv_toolchain
wget "https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz"
tar -xvzf riscv64-unknown-elf-gcc-*.tar.gz
echo 'export PATH=$HOME/riscv_toolchain/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Cloning the repository 
**Commands:**
```bash
git clone https://github.com/vsdip/vsdfpga_labs
```

**Verification of successful cloning:**
![](images/17.png)

### Building the Firmware and FPGA bitstream 
#### **Reviewing RISC-V Logo code :**
**Commands:**
```bash
cd vsdfpga_labs/basicRISCV/Firmware
nano riscv_logo.c  # Review and close (Ctrl+X)
make riscv_logo.bram.hex
```

**Output:**
![](images/18.png)

#### **Build Firmware and FPGA bitstream :**
**Commands:**
```bash
cd ../RTL
make clean
sed -i 's/-abc9 -device u -dsp //g' Makefile
make build
```

**Output:**
![](images/19.png)

#### **Flash to FPGA :**
**Command:**
```bash
make flash
```

### Running the Lab 
**Command:**
```bash
make terminal
```

**Output:**


___
## Local Machine Preparation

>Perform the same setup as GitHub Codespaces on Local Machine

**Steps:**
1. Clone the `vsd-riscv2` and `vsdfpga_labs` repositories in a parent directory.
2. Setup the dockerfile and configuration file `supervisord.conf`.
3. Build and run the docker container.
4. Open the noVNC desktop on local machine at port 6080 on any browser.
5. Setup and verify the FPGA Lab environment and RISC-V Toolchain.

### Cloning the repositories 
**Commands:**
```bash
git clone https://github.com/vsdip/vsd-riscv2
git clone https://github.com/vsdip/vsdfpga_labs
```

### Write docker files 
**Configuration File:**
```CONF
[supervisord]
nodaemon=true

[program:X11]
command=/usr/bin/Xvfb :1 -screen 0 1280x800x24
autorestart=true

[program:xfce4]
command=/usr/bin/startxfce4
env=DISPLAY=:1
autorestart=true

[program:novnc]
command=/usr/bin/websockify --web=/usr/share/novnc/ 6080 localhost:5900
autorestart=true

[program:x11vnc]
command=/usr/bin/x11vnc -display :1 -nopw -forever -shared
autorestart=true
```

**Docker File:**
```bash
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# 1) Core deps
RUN apt-get update && apt-get install -y \
    git curl wget ca-certificates vim \
    build-essential gcc g++ make pkg-config \
    autoconf automake autotools-dev libtool \
    bison flex texinfo gperf patchutils \
    gawk libmpc-dev libmpfr-dev libgmp-dev \
    zlib1g-dev libexpat1-dev \
    device-tree-compiler libfdt-dev \
    python3 iverilog gtkwave \
    libboost-regex-dev libboost-system-dev \
        libx11-dev libxext-dev libxrender-dev libxpm-dev libxaw7-dev libcairo2-dev libfontconfig1-dev \
    libreadline-dev libncurses-dev flex bison gawk tcsh \
    python3 python3-pip pkg-config curl ca-certificates \
    xfce4 xfce4-terminal x11vnc xvfb novnc websockify supervisor dbus-x11 gedit vim \
 && rm -rf /var/lib/apt/lists/*

# 2) Host GCC sanity (force clean host PATH so cross tools can't interfere)
RUN /usr/bin/env -i PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    bash -lc 'echo "int main(){return 0;}" > /tmp/cc.c && gcc /tmp/cc.c -o /tmp/cc && /tmp/cc'

# 3) Prebuilt SiFive toolchain (no PATH change yet)
WORKDIR /opt
RUN wget -q https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz \
 && tar -xzf riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz \
 && mv riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14 /opt/riscv \
 && rm -f *.tar.gz



# 4) Spike (host build) with CLEAN_PATH
WORKDIR /tmp
RUN set -eux; \
    CLEAN_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; \
    git clone --depth 1 https://github.com/riscv-software-src/riscv-isa-sim.git; \
    cd riscv-isa-sim; git submodule update --init --recursive; \
    mkdir -p build && cd build; \
    PATH="$CLEAN_PATH" ../configure --prefix=/opt/riscv \
      || { echo '--- spike config.log ---'; cat config.log || true; exit 1; }; \
    PATH="$CLEAN_PATH" make -j"$(nproc)"; \
    make install; \
    rm -rf /tmp/*

# 5) riscv-pk (cross) pinned to v1.0.0 to match 2019 toolchain
WORKDIR /tmp
RUN set -eux; \
    CROSS_PATH="/opt/riscv/bin:/opt/riscv/riscv64-unknown-elf/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"; \
    git clone https://github.com/riscv-software-src/riscv-pk.git; \
    cd riscv-pk; git checkout v1.0.0; \
    mkdir -p build && cd build; \
    PATH="$CROSS_PATH" \
    CC=riscv64-unknown-elf-gcc CXX=riscv64-unknown-elf-g++ \
    AR=riscv64-unknown-elf-ar RANLIB=riscv64-unknown-elf-ranlib \
    ../configure --prefix=/opt/riscv --host=riscv64-unknown-elf \
      || { echo '--- pk config.log ---'; cat config.log || true; exit 1; }; \
    PATH="$CROSS_PATH" make -j"$(nproc)" V=1; \
    make install; \
    rm -rf /tmp/*

# 6) Finally, set a clean PATH: system tools first, then RISC-V tools
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/riscv/bin:/opt/riscv/riscv64-unknown-elf/bin"

# 7) Ensure interactive shells always use the same clean PATH
RUN printf '%s\n' \
  'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/riscv/bin:/opt/riscv/riscv64-unknown-elf/bin"' \
  > /etc/profile.d/00-reset-path.sh && \
  chmod +x /etc/profile.d/00-reset-path.sh

WORKDIR /workspaces

# -----------------------------
# noVNC desktop environment
# -----------------------------
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf

EXPOSE 6080
CMD ["/usr/bin/supervisord", "-n"]
```

### Build and Run Docker container 
**Docker Commands :**
```bash
# Build the image
docker build -t riscv-lab-env .
# Run the container
docker run -it -p 6080:6080 -v $(pwd):/workspaces riscv-lab-env # Bash
```

### Verification of local setup 
**Comparison of RISC-V and Native GCC:**
![](images/20.png)

**Output of FPGA Lab environment:**


___
## Understanding Check

>**1. Where is the RISC-V program located in the vsd-riscv2 repository?**

- The RISC-V source programs are located in the **`samples`** folder.
- Specific files include **`sum1ton.c`** (C code), **`load.S`** (Assembly code), and **`1ton_custom.c`** (C code). 
- To access them in the environment, we navigate using the command: `cd samples`.


>**2. How is the program compiled and loaded into memory?**

- The GNU Toolchain is used for compilation and the Spike simulator is used for loading and execution:
- **Compilation:** The C program is compiled using the *GCC cross-compiler*.
    - Command: `riscv64-unknown-elf-gcc -o <output_name>.o <input_file>.c`.
    - This creates an ELF object file (e.g., `sum1ton.o`).
    
- **Loading:** The program is loaded and executed using the *Spike ISA Simulator* combined with the *Proxy Kernel (pk)*.    
    - Command: `spike pk <output_name>.o`.
    - The Proxy Kernel (`pk`) serves as a lightweight bootloader/OS that loads the ELF file into the simulated memory and handles system calls.


>**3. How does the RISC-V core access memory and memory-mapped IO?**

- The RISC-V architecture uses a *Load/Store architecture* for all memory accesses:
	- **Memory Access:** The core moves data between memory and registers using dedicated instructions like `lw` (load word) and `sw` (store word). It cannot perform arithmetic operations directly on memory addresses; data must first be loaded into a register.
    
	- **Memory-Mapped I/O (MMIO):** RISC-V does not have special "IN" or "OUT" instructions for Input/Output. Instead, I/O devices (like an IP block) are assigned specific addresses in the main memory map. The core communicates with these devices by reading from and writing to these specific memory addresses using the same standard load/store instructions.


>**4. Where would a new FPGA IP block logically integrate in this system?**

- A new FPGA IP block would logically integrate onto the *System Bus* (interconnect). The IP block connects to the bus that links the RISC-V core to memory and other peripherals. To the software (like the C programs in `samples`), the IP block appears as a set of registers at a specific base address. The driver code would define a pointer to this address (e.g., `#define IP_BASE 0x10000000`) and read/write to it to control the hardware.
