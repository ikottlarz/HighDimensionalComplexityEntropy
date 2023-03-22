using DrWatson
@quickactivate

using HypothesisTests, Distances
using LinearAlgebra: triu
using ProgressMeter

function surrogate_dists(surrogates; dim, data_length, m, τ)
    surrogate_values = surrogates[
        (surrogates.dim .== dim) .&
        (surrogates.data_length .== data_length) .&
        (surrogates.m .== m) .&
        (surrogates.τ .== τ),
        [:entropy, :complexity]
    ]
    # collect all surrogate points on CE plane and make into matrix, which we can use for pairwise distance calc
    sp_matrix = hcat(
        surrogate_values[:, :entropy],
        surrogate_values[:, :complexity]
    )

    surrogate_distances = pairwise(Euclidean(), sp_matrix, dims=1)
    # check that we didn't make a mistake with the dims=... argument
    @assert all(size(surrogate_distances) .== (num_surrogates, num_surrogates))
    # take only upper triangluar part of symmetric matrix!
    return surrogate_distances[triu(trues(size(surrogate_dists)), 1)], sp_matrix
end

"""
    function significance_heatmap(configs) -> heatmap::Matrix{Float64}

Compute the p-value of the KS-2sample test that the original data point is drawn
from the distribution of surrogates.
"""
function significance_heatmap(system_config)
    @unpack analysis_config = system_config
    @unpack num_surrogates, τs, ms, lengths, dims, prefix, simulation_parameters = analysis_config
    original_file, _ = produce_or_load(complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix)
    # generate phase randomized surrogates
    ft_sur_config = (analysis_config..., surrogate_func=RandomFourier(true))
    ft_surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, ft_sur_config, datadir("analysis"); filename=hash, prefix="$(prefix)_ft_surrogates")
    aaft_sur_config = (analysis_config..., surrogate_func=AAFT())
    aaft_surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, aaft_sur_config, datadir("analysis"); filename=hash, prefix="$(prefix)_aaft_surrogates")

    original = original_file["data"]
    ft_surrogates = ft_surrogate_file["data"]
    aaft_surrogates = aaft_surrogate_file["data"]

    ft_heatmaps = DataFrame(dim=Int[], data_length=Int[], heatmap=Matrix{Float64}[])
    aaft_heatmaps = DataFrame(dim=Int[], data_length=Int[], heatmap=Matrix{Float64}[])

    @showprogress for dim in dims
        for data_length in lengths
            # fill with NaN to immediately see if some values didn't get filled
            ft_heatmap = fill(NaN64, (length(ms), length(τs)))
            aaft_heatmap = fill(NaN64, (length(ms), length(τs)))
            for (i, m) in enumerate(ms)
                for (j, τ) in enumerate(τs)
                    # get original and surrogate values for combination of dim and data_length
                    original_value = original[
                        (original.dim .== dim) .&
                        (original.data_length .== data_length) .&
                        (original.m .== m) .&
                        (original.τ .== τ),
                        [:entropy, :complexity]
                    ]
                    ft_surrogate_dist_vec, ft_sp_matrix = surrogate_dists(ft_surrogates)
                    aaft_surrogate_dist_vec, aaft_sp_matrix = surrogate_dists(aaft_surrogates)

                    truth_point = hcat(
                        original_value[:, :entropy],
                        original_value[:, :complexity]
                    )
                    truth_surrogate_dists = pairwise(Euclidean(), ft_sp_matrix, truth_point, dims=1)
                    @assert length(truth_surrogate_dists) == num_surrogates
                    truth_surrogate_dist_vec = vcat(truth_surrogate_dists...)
                    p = pvalue(
                            ApproximateTwoSampleKSTest(
                                truth_surrogate_dist_vec,
                                ft_surrogate_dist_vec
                            )
                        )

                    ft_heatmap[i, j] = p
                    truth_surrogate_dists = pairwise(Euclidean(), aaft_sp_matrix, truth_point, dims=1)
                    @assert length(truth_surrogate_dists) == num_surrogates
                    truth_surrogate_dist_vec = vcat(truth_surrogate_dists...)
                    p = pvalue(
                            ApproximateTwoSampleKSTest(
                                truth_surrogate_dist_vec,
                                aaft_surrogate_dist_vec
                            )
                        )

                    aaft_heatmap[i, j] = p
                end
            end
            push!(ft_heatmaps, Dict(
                :dim => dim,
                :data_length => data_length,
                :heatmap => ft_heatmap
                )
            )
            push!(aaft_heatmaps, Dict(
                :dim => dim,
                :data_length => data_length,
                :heatmap => aaft_heatmap
                )
            )
        end
    end
    return Dict(
        "data" => @strdict(ft_heatmaps, aaft_heatmaps),
        "parameters"=>@strdict(num_surrogates, τs, ms, lengths, dims),
        "simulation_parameters"=>simulation_parameters
    )
end