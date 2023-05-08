# HighDimensionalComplexityEntropy

Repository for our Paper "Ordinal pattern-based complexity analysis of high-dimensional chaotic time series" (https://doi.org/10.1063/5.0147219).

This code base is using the [Julia Language](https://julialang.org/) and
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> HighDimensionalComplexityEntropy

It is authored by Inga Kottlarz.

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
1. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate
```
which auto-activate the project and enable local path handling from DrWatson.


### Running Scripts
Some scripts expect command line arguments to be easily run on an hpc cluster,
which means you cannot run them by clicking "run" in `VSCode`.
Instead, execute them using the shell commands, e.g.
```bash
$ julia -t <number of threads you want to use> scripts/run_calculations.jl --system=<system>
```
This will run all calculations (simulation, calculation of complexity and entropy for all
combinations of `dims`, `data_lengths`, `ms` (pattern lengths) and `τs` (lags) specified in
`config/base.jl`).
Note that this will take some time if you're not using a cluster.
Once you produced all data, simply execute the `standard_plot_generation.jl` and
`heatmap_plot.jl` scripts to generate the plots.
