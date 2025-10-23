# Problem #7: Moving Average Parameter Sweep

This directory contains the implementation for Problem #7, which involves creating SLURM submission scripts for parameter sweeping with a Moving Average (MA) program.

## Files Description

### Core Program
- **`MA.cpp`**: The main C++ program that implements moving average calculations with different computation types and boundary handling methods.

### SLURM Scripts
- **`MA_parameter_sweep.slurm`**: First SLURM script for parameter sweeping
- **`MA_ramdisk_optimized.slurm`**: Second SLURM script with RAMdisk I/O optimization
- **`MA_calculator.slurm`**: Original SLURM script (refactored to match assignment standards)

## Program Features

The MA program accepts the following command-line arguments:

### Computation Types
- `--forward`: Forward-looking moving average
- `--backward`: Backward-looking moving average  
- `--centered`: Centered moving average

### Boundary Handling
- `--restricted`: Only use available data points
- `--cyclic`: Wrap around using cyclic boundary conditions
- `--padding`: Use edge values for out-of-bounds indices

### Data Points
- `N`: Number of data points (positive integer, default: 100)

### Help
- `--help` or `-h`: Display usage information

## Usage Examples

```bash
# Compile the program
g++ -O3 -std=c++17 -o MA MA.cpp

# Basic usage
./MA --forward --restricted 5

# Different computation type and boundary handling
./MA --centered --cyclic 10

# Show help
./MA --help
```

## SLURM Scripts Usage

### 1. Parameter Sweep Script
```bash
sbatch MA_parameter_sweep.slurm
```

**Features:**
- Systematically varies N from 1 to 5
- Tests all combinations of computation types and boundary handling
- Total runs: 5 × 3 × 3 = 45 parameter combinations
- Uses GNU parallel for efficient CPU utilization
- Outputs results to `out/` directory

### 2. RAMdisk Optimized Script
```bash
sbatch MA_ramdisk_optimized.slurm
```

**Features:**
- Same parameter sweep as above
- Uses RAMdisk (`/dev/shm/`) for faster I/O during computation
- Automatically recovers results to `out/` directory before job completion
- Optimized for high-throughput scenarios

## Output Format

Each run produces output in the following format:
```
Number of data points (N): [N]
Computation type: [computation_type]
Boundary handling: [boundary_handling]
Original data, MA5, MA10:
[data_point] [ma5_value] [ma10_value]
...
```

## Requirements

- GCC compiler with C++17 support
- GNU parallel module
- SLURM job scheduler
- Sufficient memory for RAMdisk operations (second script)

## Performance Notes

- Both scripts utilize all 40 available CPU cores
- RAMdisk optimization provides faster I/O for large parameter sweeps
- Jobs include performance monitoring and result statistics
- Automatic error handling and status reporting

## Job Monitoring

After submission, monitor jobs with:
```bash
squeue -u $USER
sacct -j [JOB_ID]
```

Results will be available in the `out/` directory after job completion.
