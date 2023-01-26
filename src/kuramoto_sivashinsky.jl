using LinearAlgebra: mul!

function kse_spectral!(dy, y, p, t)
    forward_plan, inverse_plan, udummy, ydummy, k²_k⁴, ik2 = p
    y² = begin # nonlinear term
        mul!(udummy, inverse_plan, y) # create current u in x-space
        udummy .*= udummy # square current u
        mul!(ydummy, forward_plan, udummy) # transform to k-space
    end
    # KS equation in spectral space
    @. dy = y²*ik2 + k²_k⁴*y
    return nothing
end