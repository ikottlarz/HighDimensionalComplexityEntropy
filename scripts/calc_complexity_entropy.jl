using DrWatson
@quickactivate
include(srcdir("complexity_entropy.jl"))
using ProgressMeter
using TimeseriesSurrogates

function complexity_entropy(
    data::Dict{String, Any};
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    lengths::AbstractVector{Int},
    dims::AbstractVector{Int}
    )
    ce_values = Dict{String, Any}()
    @showprogress for m in ms
        ce_values["m=$m"] = Dict{String, Any}()
        for τ in τs
            ce_values["m=$m"]["τ=$τ"] = Dict{String, Any}()
            est = SymbolicPermutation(; m, τ)
            for data_length in lengths
                ce_values["m=$m"]["τ=$τ"]["data_length=$data_length"] = Dict{String, Any}()
                for dim in dims
                    ts = data["τ$τ"][1:data_length]
                    entropy, complexity = entropy_stat_complexity(est, ts)
                    ce_values["m=$m"]["τ=$τ"]["data_length=$data_length"]["dim=$dim"] = [entropy,  complexity]
                end
            end
        end
    end
    return ce_values
end

function complexity_entropy(
    filename::String,
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    lengths::AbstractVector{Int},
    dims::AbstractVector{Int}
    )
    loaded_file = wload(filename)
    data = loaded_file["data"]
    ce_values = complexity_entropy(data; ms, τs, lengths, dims)
    return Dict("data"=>ce_values, "simulation_parameters"=>loaded_file["parameters"], "parameters"=>@strdict(ms, τs, lengths, dims))
end

function complexity_entropy(config)
    return complexity_entropy(config...)
end

data, filename = produce_or_load(
    complexity_entropy,
    (
        filename=datadir("sims/mackey_glass.jld2"),
        ms=[3, 4, 5, 6, 7],
        τs=collect(1:50),
        lengths=10 .^(2:6),
        dims=collect(1:50)
    ),
    datadir("analysis");
    filename="mackey_glass"
)

function surrogate_complexity_entropy(filename::String; num_surrogates, kwargs...)
    loaded_file = wload(filename)
    x = loaded_file["data"]
    surrogate_ce = Dict{String, Any}()
    for n in 1:num_surrogates
        sur = surrogate(x, RandomFourier(true))
        surrogate_ce["n$n"] = complexity_entropy(sur, kwargs...)
    end
    return Dict("data"=>surrogate_ce, "simulation_parameters"=>loaded_file["parameters"], "parameters"=>@strdict(kwargs...))
end
