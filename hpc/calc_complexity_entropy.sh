#!/bin/bash

fn="`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy"

echo "#!/bin/bash" > "$fn.sh"
echo "#SBATCH -p medium" >> "$fn.sh"
echo "#SBATCH -c 40" >> "$fn.sh"
echo "#SBATCH -t 500" >> "$fn.sh"
echo "#SBATCH --mem-per-cpu 1G" >> "$fn.sh"
echo "#SBATCH -o hpc/$fn.out" >> "$fn.sh"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "$fn.sh"
echo "julia scripts/simulate.jl" >> "$fn.sh"
echo "julia - t 40 scripts/calc_complexity_entropy.jl" >> "$fn.sh"

sbatch -C scratch $fn.sh