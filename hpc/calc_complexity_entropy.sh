#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy"
DIRECTORY=`git rev-parse --show-toplevel`

echo "#!/bin/bash" > "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -p medium" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -c 40" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -t 500" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH --mem-per-cpu 2G" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -o $DIRECTORY/hpc/outputs/$fn.out" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "julia ../scripts/simulate.jl" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"
echo "julia -t 40 ../scripts/calc_complexity_entropy.jl" >> "$DIRECTORY/hpc/slurm_scripts/$fn.sh"

sbatch -C scratch $DIRECTORY/hpc/slurm_scripts/$fn.sh