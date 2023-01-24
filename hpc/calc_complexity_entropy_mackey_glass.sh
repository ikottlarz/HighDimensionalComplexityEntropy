#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy_mackey_glass"
gitdir=`git rev-parse --show-toplevel`

echo "#!/bin/bash" > "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -p medium" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -c 50" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -t 200" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH --mem-per-cpu 1G" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -o $gitdir/hpc/outputs/$fn.out" >> "$gitdir/hpc/slurm_scripts/$fn.sh"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "julia -t 50 $gitdir/scripts/calc_complexity_entropy_mackey_glass.jl" >> "$gitdir/hpc/slurm_scripts/$fn.sh"

sbatch -C scratch $gitdir/hpc/slurm_scripts/$fn.sh