# Hashcat Benchmark Results - AMD Radeon RX 9070 XT

## Test Configuration

| Parameter | Your Setup | Reference |
|-----------|------------|-----------|
| Card | AMD Radeon RX 9070 XT (eGPU) | Sapphire Pulse RX 9070 XT |
| Connection | Thunderbolt 3 | Native PCIe |
| OS | NixOS Linux | Windows 10 Pro |
| Driver | ROCm OpenCL 3649.0 | AMD 25.3.1 |
| Hashcat | 7.1.2 | 6.2.6 |
| BIOS Mode | Quiet (?) | Default |

## Benchmark Comparison

| Hash Type | Your Result | Reference (100% power) | Difference |
|-----------|-------------|------------------------|------------|
| MD5 | 31.3 GH/s | 52.6 GH/s | -40% |
| SHA1 | 17.0 GH/s | 21.8 GH/s | -22% |
| SHA2-256 | 8.4 GH/s | 9.3 GH/s | -10% |
| SHA2-512 | 1.8 GH/s | 2.1 GH/s | -14% |

## After BIOS Switch (Performance Mode)

| Hash Type | Quiet Mode | Performance Mode | Difference |
|-----------|------------|------------------|------------|
| MD5 | 31.3 GH/s | | |
| SHA1 | 17.0 GH/s | | |
| SHA2-256 | 8.4 GH/s | | |
| SHA2-512 | 1.8 GH/s | | |

## Commands

```bash
# Run GPU-only benchmark
hashcat -b -D 2 --force

# Show device info
hashcat -I
```

## Notes

- Reference data from [hashcat forum](https://hashcat.net/forum/thread-12521-newpost.html)
- TB3 bandwidth (~22 Gbps effective) unlikely to be bottleneck for compute-bound hashcat workloads
- Performance gap likely due to Linux ROCm vs Windows driver optimizations
