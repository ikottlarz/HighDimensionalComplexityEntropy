using DrWatson
@quickactivate

include(srcdir("parse_commandline.jl"))
@unpack system, env = parse_commandline()
include(projectdir("configs/$env.jl"))
include(scriptsdir("calc_significances.jl"))

@info "Producing significance heatmaps for $system with env $env"
produce_or_load(significance_heatmap, system_configs[system], datadir("analysis"); filename=hash, prefix="$(system)_significances")