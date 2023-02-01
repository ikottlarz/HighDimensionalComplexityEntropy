using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems, DifferentialEquations
using ProgressMeter

function ky_dim_lorenz96(config::NamedTuple)
    @unpack simulation_parameters = config
    @unpack reltol, abstol, Ttr, N, F, Dmin, Dmax = simulation_parameters
    data = DataFrame(dim=Int[], ky_dim=Float64[], lyapunov_spectrum=Vector{Float64}[])
    diffeq = (
        alg = Vern9(),
        reltol = reltol,
        abstol = abstol,
        maxiters = typemax(Int)
    )
    @showprogress for D in Dmin:Dmax
        ds = Systems.lorenz96(D, range(0; length = D, step = 0.1); F)
        Lambdas = lyapunovspectrum(ds, N; Ttr, diffeq)
        push!(
            data,
            Dict(
                :dim => D,
                :ky_dim => kaplanyorke_dim(Lambdas),
                :lyapunov_spectrum=>Lambdas
            )
        )
    end
    return Dict("data"=>data, "parameters"=>@strdict(reltol, abstol, Ttr, N, F))
end