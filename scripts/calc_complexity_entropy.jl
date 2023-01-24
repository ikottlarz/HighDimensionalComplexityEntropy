using DrWatson
@quickactivate
include(srcdir("complexity_entropy.jl"))
include(srcdir("threadsafe_dict.jl"))
using .ThreadsafeDict

"""
function complexity_entropy!(time_series; ms, τs, ce_values::Dict)

This function calculates the statistical complexity and permutation entropy
of `time_series` for all combinations of word lengths (`ms`), lags (`τs`).

Fills a Dict `ce_values` with entries
    - "m=\$m"
        - "τ=\$τ"
"""
function complexity_entropy!(
    time_series::AbstractVector{Float64};
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    ce_values::Dict{String, Dict}
    )
    for m in ms
        d = dictsrv(Dict{String, Vector{Float64}}())
        Threads.@threads for τ in τs
            est = SymbolicPermutation(; m, τ)
            entropy, complexity = entropy_stat_complexity(est, time_series)
            d["τ$τ"]  = [entropy,  complexity]
        end
        ce_values["m=$m"] = d()
    end
end

function complexity_entropy(config::NamedTuple)
    @unpack filename_prefix, τs, ms, dims, lengths, simulation_parameters, data_producing_function = config
    data, _ = produce_or_load(
        data_producing_function,
        simulation_parameters,
        datadir("sims");
        filename=hash,
        prefix=filename_prefix
    )
    ce_values = Dict{String, Dict}()
    @showprogress for dim in dims
        ce_values["dim=$dim"] = Dict{String, Dict}()
        for data_length in lengths
            ce_values["dim=$dim"]["data_length=$data_length"] = Dict{String, Dict}()
            complexity_entropy!(
                data["data"][1:data_length];
                ms, τs,
                ce_values=ce_values["dim=$dim"]["data_length=$data_length"]
            )
        end
    end
    return Dict("data"=>ce_values, "simulation_parameters"=>simulation_parameters, "parameters"=>@strdict(ms, τs, lengths, dims))
end

function surrogate_complexity_entropy(config::NamedTuple)
    @unpack filename_prefix, τs, ms, dims, lengths, num_surrogates, simulation_parameters, data_producing_function = config
    data, _ = produce_or_load(
        data_producing_function,
        simulation_parameters,
        datadir("sims");
        filename=hash,
        prefix=filename_prefix
    )
    surrogate_ce = Dict{String, Dict}()
    for n in 1:num_surrogates
        surrogate_ce["n=$n"] = Dict{String, Dict}()
        @showprogress for dim in dims
            surrogate_ce["n=$n"]["dim=$dim"] = Dict{String, Dict}()
            for data_length in lengths
                surrogate_ce["n=$n"]["dim=$dim"]["data_length=$data_length"] = Dict{String, Dict}()
                sur = surrogate(data["dim$dim"][1:data_length], RandomFourier(true))
                complexity_entropy!(
                    sur;
                    ms, τs, ce_values=surrogate_ce["n$n"]["dim=$dim"]["data_length=$data_length"]
                )
            end
        end
    end
    parameters = @strdict(
        num_surrogates,
        ms,
        τs,
        lengths,
        dims
        )
    return Dict("data"=>surrogate_ce, "simulation_parameters"=>loaded_file["parameters"], "parameters"=>parameters)
end