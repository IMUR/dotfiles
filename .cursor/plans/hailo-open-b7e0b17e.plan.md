<!-- b7e0b17e-dc87-4b1a-a0ba-910ba89dc091 299a79a8-d824-4616-b1bc-1d4e8247ecae -->
# Hailo AI HAT+ Open-Source Integration Plan

## Current State Analysis

The Hailo-8 AI processor is detected on PCIe bus (0001:01:00.0) but lacks kernel drivers. System runs kernel 6.12.47+rpt-rpi-2712 on aarch64 with GCC 14.2.0 and Python 3.13.5 available. Docker/closed-source solutions are present but will be avoided per open-source-first strategy.

## Implementation Roadmap

### Phase 1: Environment Preparation

Create dedicated workspace at `/home/crtr/Projects/hailo-open` for all Hailo-related development. Install essential build dependencies including `build-essential`, `linux-headers-$(uname -r)`, `dkms`, `pciutils`, and development libraries. Set up Python virtual environment for any Python-based tools while maintaining system package isolation.

### Phase 2: Kernel Driver Build & Installation

Clone and build the open-source Hailo kernel driver from `github.com/hailo-ai/hailort-drivers`. The driver requires kernel headers matching the running kernel (6.12.47+rpt-rpi-2712). Build process involves:

- Configuring DKMS for automatic kernel module rebuilding
- Compiling the PCIe driver module
- Installing udev rules for proper device permissions
- Loading the module and verifying `/dev/hailo*` device nodes appear

### Phase 3: HailoRT Runtime Compilation

Build the HailoRT runtime library from `github.com/hailo-ai/HailoRT` which provides the core API for device interaction. This involves:

- CMake-based build configuration for aarch64
- Compilation of shared libraries and CLI tools
- Installation to `/usr/local` or custom prefix
- Verification through `hailortcli` device discovery

### Phase 4: Baseline Validation & Benchmarking

Create minimal C++ test application linking against HailoRT to:

- Enumerate and query device capabilities
- Load a simple ONNX model converted to Hailo format
- Run inference benchmarks to establish performance baseline
- Document PCIe bandwidth and inference throughput metrics

### Phase 5: Open Model Pipeline Development

Implement model conversion workflow using open tools:

- Set up ONNX to Hailo model converter (if open-source available)
- Create Python scripts for pre/post-processing pipelines
- Build modular inference service with clean API
- Integrate with video4linux2 for camera input if needed

### Phase 6: Documentation & Community Contribution

Document entire build process with:

- Detailed build instructions for Debian 13/Trixie
- Troubleshooting guide for common issues
- Performance benchmarks and optimization tips
- Example applications and integration patterns

Create GitHub repository with all custom code, patches, and documentation to benefit the community.

## Key Files to Create/Modify

- `/home/crtr/Projects/hailo-open/build/` - Build workspace
- `/home/crtr/Projects/hailo-open/drivers/` - Kernel driver source
- `/home/crtr/Projects/hailo-open/runtime/` - HailoRT source
- `/home/crtr/Projects/hailo-open/models/` - Model files and converters
- `/home/crtr/Projects/hailo-open/apps/` - Custom applications
- `/home/crtr/Projects/hailo-open/docs/` - Documentation

## Success Metrics

- Hailo device nodes present in `/dev/hailo*`
- `hailortcli scan` detects the Hailo-8 processor
- Successful inference on a test model
- Documented build process reproducible on fresh Debian 13 system
- All components buildable from source without proprietary dependencies

### To-dos

- [ ] Create project workspace and install build dependencies (build-essential, linux-headers, dkms)
- [ ] Clone, build and install Hailo kernel driver from github.com/hailo-ai/hailort-drivers
- [ ] Build and install HailoRT runtime library from github.com/hailo-ai/HailoRT
- [ ] Validate device detection with hailortcli and verify /dev/hailo* nodes
- [ ] Create minimal C++ test application for baseline inference
- [ ] Implement open model conversion and inference pipeline
- [ ] Document complete build process and create community resources