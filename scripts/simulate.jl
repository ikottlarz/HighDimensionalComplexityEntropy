using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter

include(srcdir("mackey_glass.jl"))

function simulate_mackey_glass(;
    β::Float64,
    γ::Float64,
    n::Float64,
    max_τ::Int64,
    Δt::Float64,
    t_sample::Float64,
    N::Int64,
    Ttr::Int64
    )
    trajectories = Dict{String, Any}()
    @showprogress for τ in 1:max_τ
        u0 = zeros(Int(τ/Δt))
        u0[1] = 1.
        p = β, γ, n, Δt
        ds = DiscreteDynamicalSystem(mackey_glass!, u0, p, mackey_glass_jac!)

        steps_per_sample = Int(t_sample/Δt)
        X = trajectory(ds, Int(N*steps_per_sample); Ttr=Int(Ttr/Δt))

        X = X[1:steps_per_sample:end, 1]

        trajectories["τ$τ"] = X
    end
    return trajectories, @strdict(β, γ, n, Δt, N, Ttr, t_sample)
end


function simulate_mackey_glass(config::NamedTuple)
    simulate_mackey_glass(;config...)
end

config = (
    β = 2.,
    γ = 1.,
    n = 9.65,
    max_τ = 50,
    Δt = 0.1,
    t_sample = 0.2,
    N = 1000000,
    Ttr = 1000,
)
produce_or_load(simulate_mackey_glass, config, datadir("sims"); filename="mackey_glass")