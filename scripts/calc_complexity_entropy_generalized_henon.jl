using DrWatson
@quickactivate

using ProgressMeter

include(scriptsdir("calc_complexity_entropy.jl"))
include(scriptsdir("simulate_generalized_henon.jl"))

simulation_config = (
    a = 1.76,
    b = 0.1,
    Dmax = 50,
    N = 1000000,
    Ttr = 1000,
    commit_hash = gitdescribe() # get current commit id to generate new hash if it differs
)

config = (
    filename_prefix="generalized_henon",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(1:50),
    simulation_parameters=simulation_config,
    data_producing_function=simulate_generalized_henon
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
