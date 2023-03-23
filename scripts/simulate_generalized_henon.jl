using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter
include(srcdir("henon.jl"))

function simulate_generalized_henon(config::NamedTuple)
    @unpack a, b, Dmax, N, Dmin, Ttr = config
    data = DataFrame(dim=Int[], trajectory=Vector{Float64}[])
    @showprogress for D in Dmin:Dmax
        u0 = zeros(D)
        ds = DiscreteDynamicalSystem(henons!, u0, [a, b])
        tds = TangentDynamicalSystem(ds; J=henons_jac!)
        X, _ = trajectory(tds, N; Ttr = Ttr)
        push!(data, Dict(:dim => D, :trajectory => X[:, 1]))
    end
    return Dict("data"=>data, "parameters"=>@strdict(a, b, N, Ttr))
end