#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy_mackey_glass"

echo "#!/bin/bash" > "slurm_scripts/$fn.sh"
echo "#SBATCH -p medium" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -c 50" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -t 200" >> "slurm_scripts/$fn.sh"
echo "#SBATCH --mem-per-cpu 1G" >> "slurm_scripts/$fn.sh"
echo "#SBATCH -o $fn.out" >> "output/$fn.out"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "slurm_scripts/$fn.sh"
echo "julia - t 50 scripts/calc_complexity_entropy_mackey_glass.jl" >> "slurm_scripts/$fn.sh"

sbatch -C scratch $DIRECTORY/hpc/slurm_scripts/$fn.sh