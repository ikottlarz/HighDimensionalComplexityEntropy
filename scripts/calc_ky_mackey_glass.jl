using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems, DataFrames
using ProgressMeter

include(srcdir("mackey_glass.jl"))

function ky_dim_mackey_glass(config::NamedTuple)
    @unpack simulation_parameters = config
    @unpack β, γ, n, max_τ, min_τ, Δt, N, Ttr = simulation_parameters
    d = dictsrv(Dict{String, DataFrame}())
    Threads.@threads for τ in min_τ:max_τ
        tmp_data = DataFrame(dim=Int[], ky_dim=Float64[], lyapunov_spectrum=Vector{Float64}[])
        u0 = zeros(Int(τ/Δt))
        u0[1] = 1.
        p = β, γ, n, Δt
        ds = DiscreteDynamicalSystem(mackey_glass!, u0, p)
        tds = TangentDynamicalSystem(ds; J=mackey_glass_jac!)

        k = τ+5
        Lambdas = lyapunovspectrum(tds, N*Δt, k; Ttr=Int(Ttr/Δt), Δt=10)

        push!(
            tmp_data,
            Dict(
                :dim => τ,
                :ky_dim => kaplanyorke_dim(Lambdas),
                :lyapunov_spectrum=>vcat(Lambdas...)
            )
        )
        d["$τ"] = tmp_data
        println("finished for τ = $τ")
    end
    collected_dict = d()
    data = outerjoin(
        values(collected_dict)...,
        on = [
            :dim=>:dim,
            :ky_dim=>:ky_dim,
            :lyapunov_spectrum=>:lyapunov_spectrum
        ]
    )
    return Dict("data"=>data, "parameters"=>@strdict(β, γ, n, Δt, N, Ttr))
end