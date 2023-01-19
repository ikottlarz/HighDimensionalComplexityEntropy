
"""
    function henons!(un, u, p, t)

implements the generalized H\'enon map according to
"""
function henons!(un, u, p, t)
    a, b = p
    L = length(u)
    un[1] = a - (u[L-1])^2 - b * u[L]
    un[2:L] = u[1:L-1]
    return
end

function henons_jac!(J, u, p, t)
    a, b = p
    L = length(u)
    J[:, :] .= 0
    J[1, L-1] = -2*u[L-1]
    J[1, L] = -b
    for i in 2:L
        J[i, i-1] = 1
    end
    return
end