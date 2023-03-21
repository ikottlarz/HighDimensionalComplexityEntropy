using Distances, ComplexityMeasures

linearpermissiverange(start; stop, length) = length==1 ? (start:start) : range(start, stop=stop, length=length)

"""
    maximum_complexity_entropy(c::StatisticalComplexity; num=1)
Calculate the maximum complexity-entropy curve for the statistical complexity according to [^Rosso2007]
for `num * m!` different values of the normalized permutation entropy.
## Description
The way the statistical complexity is designed, there is a minimum and maximum possible complexity
for data with a given permutation entropy.
The calculation time of the maximum complexity curve grows as O((m!)^2), and thus takes very long for higher `m`.
This function is adapted from S. Sippels implementation in statcomp [^statcomp].
[^Rosso2007] Rosso, O. A., Larrondo, H. A., Martin, M. T., Plastino, A., & Fuentes, M. A. (2007).
            [Distinguishing noise from chaos](https://doi.org/10.1103/PhysRevLett.99.154102).
            Physical review letters, 99(15), 154102.
[^statcomp] Sippel, S., Lange, H., Gans, F. (2019).
            [statcomp: Statistical Complexity and Information Measures for Time Series Analysis](https://cran.r-project.org/web/packages/statcomp/index.html)
"""
function maximum_complexity_entropy(est::ComplexityMeasures.ProbabilitiesEstimator; num::Int=1)

    L = total_outcomes(est, randn(10))
    # in these we'll write the entropy (h) and corresponding max. complexity (c) values
    hs, cs = zeros(L-1, num), zeros(L-1, num)
    deterministic = zeros(L)
    deterministic[1] = 1
    max_dist = evaluate(JSDivergence(), deterministic, fill(1.0/L, L))
    max_entropy = entropy(ComplexityMeasures.Probabilities(ones(L)/L))
    for i in 1:L-1
        p = zeros(L)
        prob_params = linearpermissiverange(0; stop=1/L, length=num)
        for k in 1:num
            p[1] = prob_params[k]
            for j in 1:L-i
                p[j] = (1-prob_params[k]) / (L-i)
            end
            p_k = ComplexityMeasures.Probabilities(p)
            h = entropy(p_k) / max_entropy
            hs[i, k] = h
            dist = evaluate(JSDivergence(), p_k.p, fill(1.0/L, L))
            cs[i, k] = dist / max_dist * h
        end
    end
    hs = vcat(hs...)
    cs = vcat(cs...)
    args = sortperm(hs)
    return hs[args], cs[args]
end

"""
    minimum_complexity_entropy(c::StatisticalComplexity; num=100) -> entropy, complexity
Calculate the maximum complexity-entropy curve for the statistical complexity according to [^Rosso2007]
for `num` different values of the normalized permutation entropy.
## Description
The way the statistical complexity is designed, there is a minimum and maximum possible complexity
for data with a given permutation entropy.
Here, the lower bound of the statistical complexity is calculated as a function of the permutation entropy
This function is adapted from S. Sippels implementation in statcomp [^statcomp].
[^Rosso2007] Rosso, O. A., Larrondo, H. A., Martin, M. T., Plastino, A., & Fuentes, M. A. (2007).
            [Distinguishing noise from chaos](https://doi.org/10.1103/PhysRevLett.99.154102).
            Physical review letters, 99(15), 154102.
[^statcomp] Sippel, S., Lange, H., Gans, F. (2019).
            [statcomp: Statistical Complexity and Information Measures for Time Series Analysis](https://cran.r-project.org/web/packages/statcomp/index.html)
"""
function minimum_complexity_entropy(est::ComplexityMeasures.ProbabilitiesEstimator; num::Int=1000)

    L = total_outcomes(est, randn(10))
    prob_params = linearpermissiverange(1/L; stop=1, length=num)
    hs = Float64[]
    cs = Float64[]

    deterministic = zeros(L)
    deterministic[1] = 1
    max_dist = evaluate(JSDivergence(), deterministic, fill(1.0/L, L))
    max_entropy = entropy(ComplexityMeasures.Probabilities(ones(L)/L))

    for i in 1:num
        p_i = ones(L) * (1-prob_params[i]) / (L-1)
        p_i[1] = prob_params[i]
        p_i = ComplexityMeasures.Probabilities(p_i)
        h = entropy(p_i) / max_entropy
        push!(hs, h)
        dist = evaluate(JSDivergence(), p_i.p, fill(1.0/L, L))
        push!(cs, dist / max_dist * h)
    end
    return reverse(hs), reverse(cs)
end