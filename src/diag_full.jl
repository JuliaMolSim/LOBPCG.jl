"""
    diag_full(A, X0; kwargs...)

Dense reference "solver" that fully diagonalizes `A` (densified to a Hermitian
matrix) and returns the eigenpairs matching the number of columns of `X0`. Mostly
useful for testing and small problems; it ignores tolerances and preconditioners.
"""
function diag_full(A, X0; kwargs...)
    Neig = size(X0, 2)
    Afull = Hermitian(Array(A))
    E = eigen(Afull)
    X = E.vectors[:, 1:Neig]
    λ = E.values[1:Neig]
    (; λ, X,
     residual_norms=zeros(Neig),
     n_iter=0,
     converged=true,
     n_matvec=0)
end
