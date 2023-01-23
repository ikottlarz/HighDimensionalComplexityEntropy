#SBATCH -p medium
#SBATCH -c 40
#SBATCH -t 500
#SBATCH --mem-per-cpu 1G

julia -e 'import Pkg; Pkg.add("DrWatson"); using DrWatson; @quickactivate; Pkg.instantiate()'
julia scripts/simulate.jl
julia - t 40 scripts/calc_complexity_entropy.jl