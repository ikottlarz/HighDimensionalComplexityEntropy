using DrWatson
@quickactivate

using ComplexityMeasures, TimeseriesSurrogates, Distances, Random
using ProgressMeter
include(srcdir("threadsafe_dict.jl"))
using .ThreadsafeDict

surrogate_methods = Dict(:RandomFourier=>RandomFourier(true), :AAFT=>AAFT())

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
    data_length::Int64,
    dim::Int64,
    ce_values::DataFrame,
    seed::Union{Int,Nothing} = nothing
    )
    @assert ndims(time_series) == 1
    for m in ms
        d = dictsrv(Dict{String, Vector{Float64}}())
        Threads.@threads for τ in τs
            c = StatisticalComplexity(
                dist = JSDivergence(),
                est = SymbolicPermutation(; m, τ),
                entr = Renyi()
            )
            entropy, complexity = entropy_complexity(c, time_series)
            d["τ$τ"]  = [entropy,  complexity]
        end
        for τ in τs
            push!(ce_values, Dict(
                :m=>m,
                :entropy=>d["τ$τ"][1],
                :complexity=>d["τ$τ"][2],
                :τ=>τ,
                :data_length=>data_length,
                :dim=>dim,
                :seed=>seed
                )
            )
        end
    end
end

function complexity_entropy(config::NamedTuple)
    @unpack prefix, τs, ms, dims, lengths, simulation_parameters, simulation_function = config
    file, _ = produce_or_load(
        simulation_function,
        simulation_parameters,
        datadir("sims");
        filename=hash,
        prefix=prefix
    )
    data = file["data"]
    ce_values = DataFrame(
        dim=Int[], data_length=Int[], m=Int[], τ=Int[],
        complexity=Float64[], entropy=Float64[], seed=Nothing[]
    )
    @showprogress for dim in dims
        for data_length in lengths
            complexity_entropy!(
                data[data.dim .== dim, :trajectory][1][1:data_length];
                ms, τs, dim, data_length, ce_values
            )
        end
    end
    return Dict("data"=>ce_values, "simulation_parameters"=>simulation_parameters, "parameters"=>@strdict(ms, τs, lengths, dims))
end

function surrogate_complexity_entropy(config::NamedTuple)
    @unpack prefix, τs, ms, dims, lengths, num_surrogates, surrogate_func, simulation_parameters, simulation_function = config
    file, _ = produce_or_load(
        simulation_function,
        simulation_parameters,
        datadir("sims");
        filename=hash,
        prefix=prefix
    )
    data = file["data"]
    ce_values = DataFrame(
        dim=Int[], data_length=Int[], m=Int[], τ=Int[],
        complexity=Float64[], entropy=Float64[], seed=Int[]
    )
    for _ in 1:num_surrogates
        seed = rand(1:typemax(Int))
        rng = Xoshiro(seed)
        @showprogress for dim in dims
            for data_length in lengths
                sur = surrogate(
                    data[data.dim .== dim, :trajectory][1][1:data_length],
                    surrogate_methods[surrogate_func],
                    rng
                )
                @assert ndims(sur) == 1
                complexity_entropy!(
                    sur;
                    ms, τs, ce_values, dim, data_length, seed
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
    return Dict(
        "data"=>ce_values,
        "simulation_parameters"=>simulation_parameters,
        "parameters"=>parameters
    )
end