# Note that this function will return λ on the CPU,
# but X and the history on the device (for GPU runs)
"""
    lobpcg_hyper(A, X0; maxiter, prec, tol, largest, n_conv_check, kwargs...)

Compute the smallest eigenpairs of the Hermitian operator `A` using the LOBPCG
algorithm, starting from the initial guess `X0` (one column per sought eigenvector).
`prec` is an optional preconditioner supporting `ldiv!`. Returns a named tuple with
fields `λ` (eigenvalues, on the CPU), `X` (eigenvectors), `residual_norms`,
`residual_history`, `n_iter`, `n_matvec` and `converged`.
"""
function lobpcg_hyper(A, X0; maxiter=100, prec=nothing,
                      tol=20size(A, 2)*eps(real(eltype(A))),
                      largest=false, n_conv_check=nothing, kwargs...)
    prec === nothing && (prec = I)

    @assert !largest "Only seeking the smallest eigenpairs is implemented."
    result = lobpcg(A, X0, I, prec, tol, maxiter; n_conv_check, kwargs...)

    n_conv_check === nothing && (n_conv_check = size(X0, 2))
    converged = maximum(result.residual_norms[1:n_conv_check]) < tol
    n_iter = size(result.residual_history, 2) - 1

    merge(result, (; n_iter, converged))
end
