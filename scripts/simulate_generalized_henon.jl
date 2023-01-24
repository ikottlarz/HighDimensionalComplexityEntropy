using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter
include(srcdir("henon.jl"))

function simulate_henon(
    a::Float64,
    b::Float64,
    Dmax::Int,
    N::Int,
    Ttr::Int,
    )
    trajectories = Dict{String, Any}()
    @showprogress for D in 1:Dmax
        u0 = zeros(D)
        ds = DiscreteDynamicalSystem(henons!, u0, [a, b], henons_jac!)
        X = trajectory(ds, N; Ttr = 1000)

        trajectories["D$D"] = hcat(X[:, 1]...)
    end
    return Dict("data"=>trajectories, "parameters"=>@strdict(a, b, N, Ttr))
end

function simulate_henon(config::NamedTuple)
    return simulate_henon(config...)
end

config = (
    a = 1.76,
    b = 0.1,
    Dmax = 50,
    N = 1000000,
    T = 1000
)
produce_or_load(simulate_henon, config, datadir("sims"); filename="generalized_henon")