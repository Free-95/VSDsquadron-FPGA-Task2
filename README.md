# Task 1 Submission

## Setting up GitHub Codespace

>Fork the `vsd-riscv2` repository and create a GitHub codespace

**Glimpse of Codespace:**
![](images/9.png)
___
## Verifying RISC-V Reference Flow

>Build and run the provided fundamental RISC-V programs, and observe successful execution on console 
### Program 1 : `sum1ton.c`
**Commands :**
```bash
# Navigate to 'samples' directory
cd samples 
# Compile the program
riscv64-unknown-elf-gcc -o sum1ton.o sum1ton.c
# Load and execute the program
spike pk sum1ton.o
```

**Output :**

![](images/10.png)


### Program 2 : `1ton_custom.c`
**Commands :**
```bash
# Compile the program and link with assembly code
riscv64-unknown-elf-gcc -o 1ton_custom.o 1ton_custom.c load.S
# Load and execute the program
spike pk 1ton_custom.o
```

**Output :**

![](images/11.png)


### Custom Program : `factorial.c`
**Commands :**
```bash
riscv64-unknown-elf-gcc -o factorial.o factorial.c
spike pk factorial.o
```

**Output :**

![](images/12.png)


### Verilog Program : `adder.v` (with testbench `tb.v`)
**Commands :**
```bash
# Compile the Verilog program
iverilog -o adder adder.v tb.v
# Simulate the testbench
vvp adder
```

**Output :**

![](images/13.png)
___
## Verifying the Working of GUI Desktop (noVNC)

>Build and run programs using Native GCC and RISC-V GCC on noVNC desktop
#### 1. Glimpse of Desktop
![](images/14.png)

#### 2. Run Program using Native GCC
![](images/15.png)

#### 3. Run Program using RISC-V GCC and Spike
![](images/16.png)
___
## Clone and Build the VSDFPGA Labs

>Build and run the basic labs that do not require FPGA hardware
#### Verification of successful cloning :
![](images/17.png)

#### Reviewing RISC-V Logo code :
![](images/18.png)

#### Building Firmware and FPGA bitstream :
![](images/19.png)
___
## Local Machine Preparation

>Perform the same setup as GitHub Codespaces on Local Machine

**Docker Commands :**
```bash
# Build the image
docker build -t riscv-lab-env .
# Run the container
docker run -it -p 6080:6080 -v $(pwd):/workspaces riscv-lab-env # Bash
```

#### Verification of local setup :
![](images/20.png)
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
