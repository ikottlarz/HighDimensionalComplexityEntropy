using DrWatson
@quickactivate

include(srcdir("parse_commandline.jl"))
@unpack system, env = parse_commandline()
include(projectdir("configs/$env.jl"))

@info "Producing ky dimensions for $system with env $env"
@unpack ky_config = system_configs[system]
@unpack calculation_function = ky_config
produce_or_load(calculation_function, ky_config, datadir("analysis"); filename=hash, prefix="$(system)_ky_dims")