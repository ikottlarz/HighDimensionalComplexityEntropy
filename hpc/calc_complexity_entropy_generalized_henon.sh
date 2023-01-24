#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy_generalized_henon"
gitdir=`git rev-parse --show-toplevel`

echo "#!/bin/bash" > "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -p medium" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -c 50" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -t 200" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH --mem-per-cpu 2G" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "#SBATCH -o $gitdir/hpc/outputs/$fn.out" >> "$gitdir/hpc/slurm_scripts/$fn.sh"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "$gitdir/hpc/slurm_scripts/$fn.sh"
echo "julia -t 50 scripts/calc_complexity_entropy_generalized_henon.jl" >> "$gitdir/hpc/slurm_scripts/$fn.sh"

sbatch -C scratch $gitdir/hpc/slurm_scripts/$fn.sh