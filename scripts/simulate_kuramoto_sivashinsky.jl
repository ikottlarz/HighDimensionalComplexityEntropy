using OrdinaryDiffEq
# This code is basically taken from https://github.com/JuliaDynamics/NonlinearDynamicsTextbook,
# the git repository belonging to the textbook "Nonlinear Dynamics - A Concise Introduction Interlaced with Code"
# by George Datseris and Ulrich Parlitz (https://link.springer.com/book/10.1007/978-3-030-91032-7)

function simulate_kuramoto_sivashinsky(config)
    @unpack b_min, b_max, b_step, T, Δt, Δx = config
    saveat = 0:Δt:T
    trajectories = Dict{String, Any}()
    for b in b_min:b_step:b_max
        xs = range(0, b, step = dx) # space
        u0 = @. cos(xs) + 0.1*sin(xs/8) + 0.01*cos((2π/b)*xs)
        ks = Vector(FFTW.rfftfreq(length(u0))/dx) # conjugate space (wavenumbers)

        forward_plan = FFTW.plan_rfft(u0)
        y0 = forward_plan * u0
        inverse_plan = FFTW.plan_irfft(y0, length(u0))
        ik2 = -im .* ks ./ 2
        k²_k⁴ = @. ks^2 - ks^4

        ydummy = copy(y0)
        udummy = copy(u0)
        ksparams = (forward_plan, inverse_plan, udummy, ydummy, k²_k⁴, ik2)

        prob = ODEProblem(kse_spectral!, y0, (0.0, T), ksparams)
        sol = solve(prob, Vern9(); saveat, maxiters=typemax(Int))
        u = [inverse_plan*y for y in sol.u]
        U = hcat(u...)
        trajectories["dim=$b"] = U[:, 1]
    end
    return trajectories
end
