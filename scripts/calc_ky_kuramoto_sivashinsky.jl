using DrWatson
@quickactivate
using ProgressMeter

include(srcdir("kuramoto_sivashinsky_kj.jl"))
# This code is basically taken from https://github.com/JuliaDynamics/NonlinearDynamicsTextbook,
# the git repository belonging to the textbook "Nonlinear Dynamics - A Concise Introduction Interlaced with Code"
# by George Datseris and Ulrich Parlitz (https://link.springer.com/book/10.1007/978-3-030-91032-7)

function ky_dim_kuramoto_sivashinsky(config)
    @unpack simulation_parameters = config
    @unpack b_min, b_max, b_step, N, Δt, Δx = simulation_parameters
    d = dictsrv(Dict{String, DataFrame}())
    Threads.@threads for b in b_min:b_step:b_max
        tmp_data = DataFrame(dim=Int[], ky_dim=Float64[], lyapunov_spectrum=Vector{Float64}[])
        if b == 20
            kport = 0.5
        else
            kport = 0.3
        end
        xs = range(0, b; step = Δx) # space
        u0 = @. cos(xs) + 0.1*sin(xs/8) + 0.01*cos((2π/b)*xs)
        ks = Vector(FFTW.rfftfreq(length(u0))/Δx) # conjugate space (wavenumbers)

        forward_plan = FFTW.plan_rfft(u0)
        y0 = forward_plan * u0
        inverse_plan = FFTW.plan_irfft(y0, length(u0))
        ik2 = -im .* ks ./ 2
        k²_k⁴ = @. ks^2 - ks^4

        ud = copy(u0)
        ud2 = copy(u0)
        ud3 = copy(u0)
        yd = copy(y0)
        yd2 = copy(y0)
        ksparams = @ntuple forward_plan inverse_plan ks ud ud2 ud3 yd yd2 k²_k⁴ ik2

        D = length(u0)
        M = round(Int, kport*D)
        δy0 = orthonorm_spectral(D, M)
        w0 = hcat(y0, δy0)
        prob = ODEProblem(kse_spectral_and_tangent!, w0, (0.0, 100.0), ksparams)
        integ = init(prob, Vern9(); save_everystep = false, internalnorm = tannorm, maxiters=typemax(Int))

        try
            Lambdas = kse_lyapunovs_spectral(integ, N, Δt)
            push!(
                tmp_data,
                Dict(
                    :dim => b,
                    :ky_dim => kaplanyorke_dim(Lambdas),
                    :lyapunov_spectrum=>vcat(Lambdas...)
                )
            )
            d["$b"] = tmp_data
            println("finished for b = $b")
        catch e
            println("Error $e for b = $b")
        end
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
    return Dict(
        "data" => data,
        "parameters" => @strdict(b_min, b_max, b_step, N, Δt, Δx)
    )
end