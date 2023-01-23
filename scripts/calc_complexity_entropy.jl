using DrWatson
@quickactivate
include(srcdir("complexity_entropy.jl"))
using ProgressMeter
using TimeseriesSurrogates
include(srcdir("threadsafe_dict.jl"))
using .ThreadsafeDict


"""
    function complexity_entropy!(data; ms, τs, lengths, dims, ce_values::Dict)

This function calculates the statistical complexity and permutation entropy for
all
"""
function complexity_entropy!(
    data::Dict{String, Any};
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    lengths::AbstractVector{Int},
    dims::AbstractVector{Int},
    ce_values::Dict{String, Any}
    )
    @showprogress for dim in dims
        ce_values["dim=$dim"] = Dict{String, Any}()
        for data_length in lengths
            ce_values["dim=$dim"]["data_length=$data_length"] = Dict{String, Any}()
            ts = data["τ$dim"][1:data_length]
            for m in ms
                d = dictsrv(Dict{Int, Vector{Float64}}())
                Threads.@threads for τ in collect(τs)
                    est = SymbolicPermutation(; m, τ)
                    entropy, complexity = entropy_stat_complexity(est, ts)
                    d[τ]  = [entropy,  complexity]
                end
                ce_values["dim=$dim"]["data_length=$data_length"]["m=$m"] = d()
            end
        end
    end
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
    ce_values = Dict{String, Any}()
    complexity_entropy!(data; ms, τs, lengths, dims, ce_values)
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
        lengths=10 .^(3:6),
        dims=collect(1:50)
    ),
    datadir("analysis");
    filename="mackey_glass"
)


function surrogate_complexity_entropy(
    filename::String,
    num_surrogates::Int,
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    lengths::AbstractVector{Int},
    dims::AbstractVector{Int}
    )
    loaded_file = wload(filename)
    x = loaded_file["data"]
    surrogate_ce = Dict{String, Any}()
    for n in 1:num_surrogates
        surrogate_ce["n$n"] = Dict{String, Any}()
        @showprogress for dim in dims
            for data_length in lengths
                sur = surrogate(x["τ$dim"][1:data_length], RandomFourier(true))
                data = Dict{String, Any}("τ$dim"=>sur)
                complexity_entropy!(
                    data;
                    ms, τs, lengths=[data_length], dims=[dim], ce_values=surrogate_ce["n$n"]
                )
            end
        end
    end
    return Dict("data"=>surrogate_ce, "simulation_parameters"=>loaded_file["parameters"], "parameters"=>@strdict(kwargs...))
end

function surrogate_complexity_entropy(config::NamedTuple)
    return surrogate_complexity_entropy(config...)
end


surrogate_data, filename = produce_or_load(
    surrogate_complexity_entropy,
    (
        filename=datadir("sims/mackey_glass.jld2"),
        num_surrogates=50,
        ms=[3, 4, 5, 6, 7],
        τs=collect(1:50),
        lengths=10 .^(3:6),
        dims=collect(1:50)
    ),
    datadir("analysis");
    filename="mackey_glass_surrogates"
)

using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1])
m = 6
data_length = 10^6
dim = 40
for τ in 1:50
    entropy, complexity = data["data"]["dim=$dim"]["data_length=$data_length"]["m=$m"]["τ$τ"]
    plot!(ax, [entropy], [complexity])
end
fig