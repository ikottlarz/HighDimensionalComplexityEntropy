using LinearAlgebra

"""
    function lorenz96_rule(du, u, p, t)

Implementation of the lorenz96 rule taken from
DynamicalSystems.jl
"""
function lorenz96_rule!(du, u, p, t)
    F = p[1]; N = length(u)
    # 3 edge cases
    du[1] = (u[2] - u[N - 1]) * u[N] - u[1] + F
    du[2] = (u[3] - u[N]) * u[1] - u[2] + F
    du[N] = (u[1] - u[N - 2]) * u[N - 1] - u[N] + F
    # then the general case
    for n in 3:(N - 1)
        du[n] = (u[n + 1] - u[n - 2]) * u[n - 1] - u[n] + F
    end
    return nothing # always `return nothing` for in-place form!
end


"""
    function lorenz96_jacob!(J, u, p, t)

Calculate jacobian matrix of N-dimensional Lorenz-96
system, where N=length(u).
"""
function lorenz96_jacob!(J, u, p, t)
    N = length(u)

    J[:, :] .= 0

    J[1, 1] = -1
    J[1, 2] = u[N]
    J[1, N - 1] = -u[N]
    J[1, N] = u[2] - u[N - 1]

    J[2, 1] = u[3] - u[N]
    J[2, 2] = -1
    J[2, 3] = u[1]
    J[2, N] = -u[1]

    J[N, 1] = u[N - 1]
    J[N, N - 2] = -u[N - 1]
    J[N, N - 1] = u[1] - u[N - 2]
    J[N, N] = - 1

    for n in 3:(N - 1)
        J[n, n - 2] = -u[n - 1]
        J[n, n - 1] = u[n + 1] - u[n - 2]
        J[n, n] = -1
        J[n, n + 1] = u[n - 1]
    end

    return nothing
end