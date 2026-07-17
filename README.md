# LOBPCGEigensolver.jl

[![CI](https://github.com/JuliaMolSim/LOBPCGEigensolver.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaMolSim/LOBPCGEigensolver.jl/actions/workflows/CI.yml)

A stability-focused implementation of the **Locally Optimal Block Preconditioned
Conjugate Gradient (LOBPCG)** algorithm for computing the lowest eigenpairs of a
large Hermitian operator. It was originally developed inside
[DFTK.jl](https://github.com/JuliaMolSim/DFTK.jl) and extracted into a standalone,
dependency-light package. The algorithm and its implementation are described in
[this paper](https://hal.science/hal-04094087).

The implementation follows the scheme of Hetmaniuk & Lehoucq (with refinements from
Duersch et al.) and is designed to be *very hard to break*, even at tight tolerances.

- Repeated Cholesky based fast orthogonalization with careful stabilization.
- Careful locking of converged eigenvectors with minimal impact on the others.
- Reuse of matrix–vector products wherever it is numerically safe.
- Works transparently on the **CPU and the GPU** — the same code path runs on plain
  `Array`s and on `CuArray`/`ROCArray` (via `GPUArraysCore`), with an AMDGPU
  extension supplying a few `LinearAlgebra` workarounds.

## Installation

```julia
using Pkg
Pkg.add("LOBPCGEigensolver")
```

## Usage

```julia
using LOBPCGEigensolver, LinearAlgebra

N, nev = 500, 6
M = randn(N, N); A = Hermitian(M + M') + 50I   # some Hermitian operator
X0 = randn(N, nev)                              # initial guess (one column per eigenvector)

res = lobpcg(A, X0, I, Diagonal(A), 1e-8, 200)  # (A, X, B, precon, tol, maxiter)

res.λ                # the nev smallest eigenvalues (on the CPU)
res.X                # the corresponding eigenvectors
res.residual_norms   # per-eigenvector residual norms
```

`A`, `B` and the preconditioner only need to support `mul!`/`ldiv!` against a block of
vectors, so matrix-free operators work. If the preconditioner supports adaptive updates
it may implement `precondprep!(prec, X)`, which is called before each application.

To profile where the solver spends its time, pass a `TimerOutputs.TimerOutput` as the
`timer` keyword; the time of the individual steps (matrix-vector products,
orthogonalization, Rayleigh-Ritz, preconditioning) is recorded into it:

```julia
using TimerOutputs
to = TimerOutput()
lobpcg(A, X0, I, Diagonal(A), 1e-8, 200; timer=to)
print_timer(to)
```

## Scope

- Computes the `size(X, 2)` **smallest** eigenpairs.
- Solves the **standard** eigenproblem, or the **generalized** problem `A x = λ B x`
  when a symmetric positive-definite metric `B` is passed (both paths are tested).

## License

MIT, see [LICENSE](LICENSE). Developed as part of the
[JuliaMolSim](https://github.com/JuliaMolSim) ecosystem.
