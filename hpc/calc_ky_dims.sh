#!/bin/bash

env="base"
time=120
mem=2G
ncpus=50

while getopts s:e:t:m:c: flag
do
    case "${flag}" in
        s) system=${OPTARG};;
        e) env=${OPTARG:-base};;
        t) time=${OPTARG:-120};;
        m) mem=${OPTARG:-2G};;
        c) ncpus=${OPTARG:-50}
    esac
done

SCRIPTDIR="$(git rev-parse --show-toplevel)/hpc/slurm_scripts/"
OUTDIR="$(git rev-parse --show-toplevel)/hpc/outputs/"
GITDIR=`git rev-parse --show-toplevel`

fn="`date +"%Y-%m-%d_%H-%M"`_calc_ky_dims_$system"

echo "#!/bin/bash" > "$SCRIPTDIR/$fn.sh"
echo "#SBATCH -p medium" >> "$SCRIPTDIR/$fn.sh"
echo "#SBATCH -c $ncpus" >> "$SCRIPTDIR/$fn.sh"
echo "#SBATCH -t $time" >> "$SCRIPTDIR/$fn.sh"
echo "#SBATCH --mem-per-cpu $mem" >> "$SCRIPTDIR/$fn.sh"
echo "#SBATCH -o $OUTDIR/$fn.out" >> "$SCRIPTDIR/$fn.sh"

echo "julia -e 'import Pkg; Pkg.add(\"DrWatson\"); using DrWatson; @quickactivate; Pkg.instantiate()'" >> "$SCRIPTDIR/$fn.sh"
echo "julia -t 50 $GITDIR/scripts/run_ky_calculations.jl --system=$system --env=$env" >> "$SCRIPTDIR/$fn.sh"

sbatch -C scratch $SCRIPTDIR/$fn.sh
