using OrdinaryDiffEq, DynamicalSystems
import LinearAlgebra
import FFTW

function kse_spectral_and_tangent!(dw, w, p, t)
    @unpack  ks, forward_plan, inverse_plan, yd, ud, ud2, ud3, yd2, ik2, k²_k⁴ = p
    y = view(w, :, 1)
    dy = view(dw, :, 1)

    # KS equation in spectral space
    LinearAlgebra.mul!(ud, inverse_plan, y) # create current u in x-space
    @. ud3 = ud*ud
    y² = LinearAlgebra.mul!(yd, forward_plan, ud3) # transform to k-space
    @. dy = - y²*ik2 + k²_k⁴*y

    # Equations for tangent space in spectral space (loop over each deviation vector)
    for i in 2:size(w, 2)
        δy = view(w, :, i)
        dδy = view(dw, :, i)
        ud2 .= ud # keeps track for tangent
        LinearAlgebra.mul!(ud2, inverse_plan, δy)
        ud2 .*= ud
        spectral_tan = LinearAlgebra.mul!(yd2, forward_plan, ud2)
        @. dδy = k²_k⁴*δy + im*ks*spectral_tan
    end
    return nothing
end

function orthonorm_spectral(D, M = D) # Orthonormal vectors converted to spectral space
    M > D && throw(ArgumentError("M must be ≤ D"))
    Δ = Matrix(LinearAlgebra.qr(rand(D, M)).Q)
    FFTW.rfft(Δ)
end

function tannorm(u::AbstractMatrix, t)
    s = size(u)[1]
    x = 0.0
    for i in 1:s; @inbounds x += abs2(u[i, 1]); end
    return sqrt(x/length(x))
end
tannorm(u, t) = abs(u)

# %% Lyapunov code
# This function uses some convenience methods from DynamicalSystems.jl
# based on the `tangent_integrator` format (state is a matrix. first column
# is actual system state, all other columns are deviation vectors)
import ProgressMeter
function kse_lyapunovs_spectral(integ, N, Δt::Real)
    progress = ProgressMeter.Progress(N; desc = "KSE Lyapunov Spectrum: ", dt = 1.0)
    M = size(integ.u, 2) - 1 # number of Ls
    λ = zeros(M)
    forward_plan = integ.p.forward_plan
    inverse_plan = integ.p.inverse_plan
    W = zeros(length(inverse_plan*integ.u[:, 1]), M) # for use in buffer
    t0 = integ.t
    ud = zeros(size(W, 1))
    yd = integ.u[:, 1]

    for n in 1:N
        step!(integ, Δt)
        # Get deviations in real space
        for i in 1:M
            LinearAlgebra.mul!(ud, inverse_plan, view(integ.u, :, i+1))
            W[:, i] .= ud
        end
        # Perform a (buffered) QR decomposition
        Q, R = LinearAlgebra.qr!(W)
        # Keep track of LEs
        for j in 1:M
            @inbounds λ[j] += log(abs(R[j,j]))
        end
        # Set the new deviations (also convert back to spectral)
        for i in 1:M
            ud .= Q[:, i]
            LinearAlgebra.mul!(yd, forward_plan, ud)
            integ.u[:, i+1] .= yd
        end
        u_modified!(integ, true) # Ensure that DiffEq knows we did something!
        ProgressMeter.update!(progress, n)
    end
    λ ./= (integ.t - t0)
    return λ
end
