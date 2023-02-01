using DrWatson
@quickactivate "2023-01-19_JuliaSimulations"
using DynamicalSystems
using ProgressMeter
include(srcdir("henon.jl"))

function ky_dim_generalized_henon(config::NamedTuple)
    @unpack simulation_parameters = config
    @unpack a, b, Dmax, N, Dmin, Ttr = simulation_parameters
    data = DataFrame(dim=Int[], ky_dim=Float64[], lyapunov_spectrum=Vector{Float64}[])
    @showprogress for D in Dmin:Dmax
        u0 = zeros(D)
        ds = DiscreteDynamicalSystem(henons!, u0, [a, b], henons_jac!)
        Lambdas = lyapunovspectrum(ds, N; Ttr)
        push!(
            data,
            Dict(
                :dim => D,
                :ky_dim => kaplanyorke_dim(Lambdas),
                :lyapunov_spectrum=>Lambdas
            )
        )
    end
    return Dict("data"=>data, "parameters"=>@strdict(a, b, N, Ttr))
end