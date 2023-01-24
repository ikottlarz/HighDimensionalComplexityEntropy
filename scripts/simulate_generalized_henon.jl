using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter
include(srcdir("henon.jl"))

function simulate_generalized_henon(config::NamedTuple)
    @unpack a, b, Dmax, N, Ttr = config
    trajectories = Dict{String, Any}()
    @showprogress for D in 2:Dmax
        u0 = zeros(D)
        ds = DiscreteDynamicalSystem(henons!, u0, [a, b], henons_jac!)
        X = trajectory(ds, N; Ttr = 1000)
        trajectories["dim=$D"] = hcat(X[:, 1]...)
    end
    return Dict("data"=>trajectories, "parameters"=>@strdict(a, b, N, Ttr))
end