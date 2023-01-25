using DrWatson
@quickactivate

include(srcdir("git_helpers.jl"))
include(scriptsdir("calc_complexity_entropy.jl"))
include(scriptsdir("simulate_generalized_henon.jl"))

simulation_config = (
    a = 1.76,
    b = 0.1,
    Dmax = 50,
    N = 1000000,
    Ttr = 1000,
    commit_hash = last_modifying_commit(
        scriptsdir("simulate_generalized_henon.jl"),
        srcdir("git_helpers.jl"),
        srcdir("henon.jl")
    )
)

config = (
    filename_prefix="generalized_henon",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(2:50),
    simulation_parameters=simulation_config,
    data_producing_function=simulate_generalized_henon,
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
    prefix="generalized_henon"
)

surrogate_config = (
    filename_prefix="generalized_henon",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(1:50),
    num_surrogates=50,
    simulation_parameters=simulation_config,
    data_producing_function=simulate_generalized_henon
)

surrogate_data, filename = produce_or_load(
    surrogate_complexity_entropy,
    surrogate_config,
    datadir("analysis");
    filename=hash,
    prefix="generalized_henon_surrogates"
)
