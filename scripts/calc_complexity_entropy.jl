using DrWatson
@quickactivate
include(srcdir("complexity_entropy.jl"))
using ProgressMeter

function calc_complexity_entropy(filename::String;
    ms::AbstractVector{Int},
    τs::AbstractVector{Int},
    lengths::AbstractVector{Int},
    dims::AbstractVector{Int}
)
    loaded_file = wload(filename)
    data = loaded_file["data"]
    ce_values = Dict{String, Any}()
    @showprogress for m in ms
        ce_values["m=$m"] = Dict{String, Any}()
        for τ in τs
            ce_values["m=$m"]["τ=$τ"] = Dict{String, Any}()
            est = SymbolicPermutation(; m, τ)
            for data_length in lengths
                ce_values["m=$m"]["τ=$τ"]["data_length=$data_length"] = Dict{String, Any}()
                for dim in dims
                    x = data["τ$dim"][1:data_length]
                    entropy, complexity = complexity_entropy(est, x)
                    ce_values["m=$m"]["τ=$τ"]["data_length=$data_length"]["dim=$dim"] = [entropy,  complexity]
                end
            end
        end
    end
    return Dict("data"=>ce_values, "simulation_parameters"=>loaded_file["parameters"], "parameters"=>@strdict(ms, τs, lengths, dims))
end

calc_complexity_entropy(
    datadir("sims/mackey_glass.jld2");
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(2:6),
    dims=collect(1:50)
)