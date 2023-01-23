#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy"

echo "#!/bin/bash" > "slurm_scripts/$fn.sh"
echo "#SBATCH -p medium" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -c 40" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -t 500" >> "slurm_scripts/$fn.sh"
echo "#SBATCH --mem-per-cpu 1G" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -o $fn.out" >> "output/$fn.out"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "slurm_scripts/$fn.sh"
echo "julia scripts/simulate.jl" >> "slurm_scripts/$fn.sh"
echo "julia - t 40 scripts/calc_complexity_entropy.jl" >> "slurm_scripts/$fn.sh"

sbatch -C scratch slurm_scripts/$fn.sh