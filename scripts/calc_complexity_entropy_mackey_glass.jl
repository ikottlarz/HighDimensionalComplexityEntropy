using DrWatson
@quickactivate

using ProgressMeter

include(scriptsdir("calc_complexity_entropy.jl"))
include(scriptsdir("simulate_mackey_glass.jl"))

simulation_config = (
    β = 2.,
    γ = 1.,
    n = 9.65,
    max_τ = 50,
    Δt = 0.1,
    t_sample = 0.2,
    N = 1000000,
    Ttr = 1000,
    commit_hash = gitdescribe() # get current commit id to generate new hash if it differs
)

config = (
    filename_prefix="mackey_glass",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(1:50),
    simulation_parameters=simulation_config,
    data_producing_function=simulate_mackey_glass
)

data, filename = produce_or_load(
    complexity_entropy,
    config,
    datadir("analysis");
    filename=hash,
    prefix="mackey_glass"
)

surrogate_config = (
    filename_prefix="mackey_glass",
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    dims=collect(1:50),
    num_surrogates=50,
    simulation_parameters=simulation_config,
    data_producing_function=simulate_mackey_glass
)

surrogate_data, filename = produce_or_load(
    surrogate_complexity_entropy,
    surrogate_config,
    datadir("analysis");
    filename=hash,
    prefix="mackey_glass_surrogates"
)
