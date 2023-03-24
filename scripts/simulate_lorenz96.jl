using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems, DifferentialEquations
using ProgressMeter

include(srcdir("lorenz_96.jl"))

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
        u0 = range(0; length = D, step = 0.1)
        ds = ContinuousDynamicalSystem(lorenz96_rule!, u0, [F]; diffeq)
        # we don't need the jacobian here for the trajectory
        X, _ = trajectory(ds, N*Δt; Δt, Ttr)

        push!(data, Dict(:dim => D, :trajectory => X[:, 1]))
    end
    return Dict("data"=>data, "parameters"=>@strdict(reltol, abstol, Ttr, N, F, Δt))
end