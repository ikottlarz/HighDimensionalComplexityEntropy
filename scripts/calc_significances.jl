using DrWatson
@quickactivate

using HypothesisTests, Distances

"""
    function significance_heatmap(configs) -> heatmap::Matrix{Float64}

Compute the p-value of the KS-2sample test that the original data point is drawn
from the distribution of surrogates.
"""
function significance_heatmap(system_config)
    @unpack analysis_config = system_config
    @unpack num_surrogates, τs, ms, lengths, dims, prefix = analysis_config
    original, _ = produce_or_load(complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix)
    surrogates, _ = produce_or_load(surrogate_complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix="$(prefix)_surrogates")

    heatmaps = Dict{String, Dict}()
    for dim in dims
        heatmaps["dim=$dim"] = Dict{String, AbstractMatrix{Float64}}()
        for data_length in lengths
            # get original and surrogate values for combination of dim and data_length
            original_values = original["data"]["dim=$dim"]["data_length=$data_length"]
            surrogate_values = Dict("n=$n" => surrogates["data"]["n=$n"]["dim=$dim"]["data_length=$data_length"] for n in 1:num_surrogates)
            # fill with NaN to immediately see if some values didn't get filled
            heatmaps["dim=$dim"]["data_length=$data_length"] = fill(NaN64, (length(ms), length(τs)))
            for (i, m) in enumerate(ms)
                for (j, τ) in enumerate(τs)
                    # collect all surrogate points on CE plane and make into matrix, which we can use for pairwise distance calc
                    surrogate_points = [surrogate_values["n=$n"]["m=$m"]["τ=$τ"] for n in 1:num_surrogates]
                    sp_matrix = reduce(hcat, surrogate_points)'

                    surrogate_dists = pairwise(Euclidean(), sp_matrix, dims=1)
                    # check that we didn't make a mistake with the dims=... argument
                    @assert all(size(surrogate_dists) .== (num_surrogates, num_surrogates))

                    truth_point = original_values["m=$m"]["τ=$τ"]
                    truth_surrogate_dists = pairwise(Euclidean(), sp_matrix, hcat(truth_point...), dims=1)
                    @assert length(truth_surrogate_dists) == num_surrogates

                    p = ApproximateTwoSampleKSTest(truth_surrogate_dists, surrogate_dists)

                    heatmap["dim=$dim"]["data_length=$data_length"][i, j] = p
                end
            end
        end
    end
    return Dict("data" => heatmap, "parameters"=>original["parameters"], "")
end