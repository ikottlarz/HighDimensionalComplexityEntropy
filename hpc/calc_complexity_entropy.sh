#SBATCH -p medium
#SBATCH -c 40
#SBATCH -t 500
#SBATCH --mem-per-cpu 1G
#SBATCH -o hpc/`date +"%Y-%m-%d_%H-%M"`_calc_complexity_entropy.out

julia -e 'import Pkg; Pkg.add("DrWatson"); using DrWatson; @quickactivate; Pkg.instantiate()'
julia scripts/simulate.jl
julia - t 40 scripts/calc_complexity_entropy.jl