using DrWatson
@quickactivate
using ComplexityMeasures, Distances

function complexity_entropy(est::ProbabilitiesEstimator, x::AbstractVector{T}) where T<:Real
    probs = probabilities(est, x)
    entropy = entropy_normalized(est, x)
    L = total_outcomes(est, x)
    dist = evaluate(JSDivergence(), probs.p, fill(1.0/L, size(probs)))
    deterministic = zeros(size(probs))
    deterministic[1] = 1
    max_dist = evaluate(JSDivergence(), deterministic, fill(1.0/L, size(probs)))
    complexity = dist / max_dist * entropy
    return entropy, complexity
end