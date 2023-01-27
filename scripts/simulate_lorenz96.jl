using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems, DifferentialEquations
using ProgressMeter

function simulate_lorenz96(config::NamedTuple)
    @unpack reltol, abstol, Ttr, N, F, Δt, Dmin, Dmax = config
    data = DataFrame(dim=Int[], trajectory=Vector{Float64}[])
    diffeq = (
        alg = Vern9(),
        reltol = reltol,
        abstol = abstol,
        maxiters = typemax(Int)
    )
    @showprogress for D in Dmin:Dmax
        ds = Systems.lorenz96(D, range(0; length = D, step = 0.1); F)
        X = trajectory(ds, N*Δt; Δt, Ttr, diffeq)

        push!(data, Dict(:dim => D, :trajectory => X[:, 1]))
    end
    return Dict("data"=>data, "parameters"=>@strdict(reltol, abstol, Ttr, N, F, Δt))
end