using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter

function simulate_lorenz96(config::NamedTuple)
    @unpack reltol, abstol, Ttr, N, F, Δt, Dmax, commit_hash = config
    trajectories = Dict{String, Any}()
    const diffeq = (
        alg = Vern9(),
        reltol = reltol,
        abstol = abstol,
        maxiters = typemax(Int)
    )
    @showprogress for D in 4:Dmax
        ds = Systems.lorenz96(D, range(0; length = D, step = 0.1); F)
        X = trajectory(ds, N*Δt; Δt, Ttr, diffeq)

        trajectories["dim=$D"] = X[:, 1]
    end
    return Dict("data"=>trajectories, "parameters"=>@strdict(reltol, abstol, Ttr, N, F, Δt))
end