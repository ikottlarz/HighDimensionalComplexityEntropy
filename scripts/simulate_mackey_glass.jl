using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter

include(srcdir("mackey_glass.jl"))

function simulate_mackey_glass(config::NamedTuple)
    @unpack β, γ, n, max_τ, min_τ, Δt, t_sample, N, Ttr = config
    trajectories = Dict{String, Any}()
    @showprogress for τ in min_τ:max_τ
        u0 = zeros(Int(τ/Δt))
        u0[1] = 1.
        p = β, γ, n, Δt
        ds = DiscreteDynamicalSystem(mackey_glass!, u0, p, mackey_glass_jac!)

        steps_per_sample = Int(t_sample/Δt)
        X = trajectory(ds, Int(N*steps_per_sample); Ttr=Int(Ttr/Δt))

        X = X[1:steps_per_sample:end, 1]

        trajectories["dim=$τ"] = X
    end
    return Dict("data"=>trajectories, "parameters"=>@strdict(β, γ, n, Δt, N, Ttr, t_sample))
end