using DrWatson
@quickactivate

include(srcdir("git_helpers.jl"))
include(scriptsdir("calc_complexity_entropy.jl"))
include(scriptsdir("simulate_lorenz96.jl"))

simulation_config = (
    reltol = 1e-9,
    abstol = 1e-9,
    Ttr = 1000.0,
    N = 1000000,
    F = 24.0,
    Δt = 0.02,
    Dmax = 50,
    commit_hash = last_modifying_commit(
        scriptsdir("simulate_lorenz96.jl"),
        srcdir("git_helpers.jl")
    )
)

config = (
    filename_prefix="lorenz96",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(4:50),
    simulation_parameters=simulation_config,
    data_producing_function=simulate_lorenz96,
    commit_hash=last_modifying_commit(
        srcdir("complexity_entropy.jl"),
        scriptsdir("calc_complexity_entropy.jl"),
        projectdir(PROGRAM_FILE)
    )
)

data, filename = produce_or_load(
    complexity_entropy,
    config,
    datadir("analysis");
    filename=hash,
    prefix="lorenz96"
)

surrogate_config = (
    filename_prefix="lorenz96",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(4:50),
    num_surrogates=50,
    simulation_parameters=simulation_config,
    data_producing_function=simulate_lorenz96,
    commit_hash=last_modifying_commit(
        srcdir("complexity_entropy.jl"),
        scriptsdir("calc_complexity_entropy.jl"),
        projectdir(PROGRAM_FILE)
    )
)

surrogate_data, filename = produce_or_load(
    surrogate_complexity_entropy,
    surrogate_config,
    datadir("analysis");
    filename=hash,
    prefix="lorenz96_surrogates"
)
