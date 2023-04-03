using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems, DifferentialEquations
using ProgressMeter

function ky_dim_lorenz96(config::NamedTuple)
    @unpack simulation_parameters = config
    @unpack reltol, abstol, Ttr, N, F, Dmin, Dmax = simulation_parameters
    diffeq = (
        alg = Vern9(),
        reltol = reltol,
        abstol = abstol,
        maxiters = typemax(Int)
    )
    d = dictsrv(Dict{String, DataFrame}())
    Threads.@threads for D in Dmin:Dmax
        tmp_data = DataFrame(dim=Int[], ky_dim=Float64[], lyapunov_spectrum=Vector{Float64}[])
        ds = ContinuousDynamicalSystem(lorenz96_rule!, u0, [F]; diffeq)
        tds = TangentDynamicalSystem(ds; J=lorenz_96_jacob!)
        Lambdas = lyapunovspectrum(tds, N; Ttr, diffeq)
        push!(
            tmp_data,
            Dict(
                :dim => D,
                :ky_dim => kaplanyorke_dim(Lambdas),
                :lyapunov_spectrum=>vcat(Lambdas...)
            )
        )
        d["$D"] = tmp_data
        println("finished for D = $D")
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
    return Dict("data"=>data, "parameters"=>@strdict(reltol, abstol, Ttr, N, F))
end