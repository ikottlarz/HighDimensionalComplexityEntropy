
"""
    function mackey_glass!(un, u, p, t)

forwards the Mackey-Glass equation [^MackeyGlass1977, ^GlassMackey1979]

```math
\\dot{x}(t) = \\beta \\frac{x(t-\\tau)}{1+x(t-\\tau)^n}-\\gamma x(t)
```

with an explicit RK4-step.

## Arguments
- `un`: Vector of length τ*Δt in which `x([t+Δt, t, t-Δt, ..., t-τ+Δt])` is written
- `u`: Vector of length τ*Δt containing `x([t, t-Δt, t- 2Δt, ..., t-τ])`
- `p`: parameters `[β, γ, n, Δt]`
    - `β`: Mackey-Glass parameter
    - `γ`: Mackey-Glass parameter
    - `n`: Mackey-Glass paramter
    - `Δt`: Integration time step for RK4-Scheme.

## Description
This function is used in combination with the DynamicalSystems.DiscreteDynamicalSystem.
In every discrete time step, an RK4 integration step is explicitly performed.
This is because there is currently no native way to implement a DelayDifferentialEquation
in DynamicalSystems.jl and still be able to use all functionalities, like calculating the
KY dimension.

## References
[^MackeyGlass1977] Mackey, Michael C., and Leon Glass. 1977. “Oscillation and Chaos in Physiological Control Systems.” Science 197 (4300): 287–89. https://doi.org/10.1126/science.267326.
[^GlassMackey1979] Glass, Leon, and Michael C. Mackey. 1979. “Pathological Conditions Resulting from Instabilities in Physiological Control Systems*.” Annals of the New York Academy of Sciences 316 (1): 214–35. https://doi.org/10.1111/j.1749-6632.1979.tb29471.x.


"""
function mackey_glass!(un::AbstractVector{T}, u::AbstractVector{T}, p::NTuple{4, T}, t) where T
    β, γ, n, Δt = p
    L = length(u)
    x_τ = u[L]
    # Explicit RK4 with factorizing of terms
    K = β * x_τ / (1+x_τ^n)
    C = 0.5*Δt*γ
    un[1] = u[1] + Δt/6 * (K-γ*u[1]) * (6 - 2C * (3 - C * (2 - C)))
    un[2:L] = u[1:L-1]
    return
end

function mackey_glass_jac!(J, u, p, n)
    β, γ, n, Δt = p
    L = length(u)
    x_τ = u[L]
    K = β * x_τ / (1+x_τ^n)
    C = 0.5*Δt*γ
    J[:, :] .= 0
    J[1, 1] = 1 - Δt/6 * γ * (6 - 2C * (3 - C * (2 - C)))
    J[1, L] = Δt * β * (1 - (n-1)*x_τ^n) / (1+x_τ^n)^2
    for i in 2:L
        J[i, i-1] = 1
    end
    return
end