# LOBPCG.jl

[![CI](https://github.com/JuliaMolSim/LOBPCG.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaMolSim/LOBPCG.jl/actions/workflows/CI.yml)

A stability-focused implementation of the **Locally Optimal Block Preconditioned
Conjugate Gradient (LOBPCG)** algorithm for computing the lowest eigenpairs of a
large Hermitian operator. It was originally developed inside
[DFTK.jl](https://github.com/JuliaMolSim/DFTK.jl) and extracted into a standalone,
dependency-light package.

The implementation follows the scheme of Hetmaniuk & Lehoucq (with refinements from
Duersch et al.) and is designed to be *very hard to break*, even at tight tolerances:

- Cholesky-based orthogonalization (fast, with a shifted-overlap fallback for
  ill-conditioned blocks and an SVD gold-standard fallback).
- Careful locking of converged eigenvectors with minimal impact on the others.
- Reuse of matrix–vector products wherever it is numerically safe.
- Works transparently on the **CPU and the GPU** — the same code path runs on plain
  `Array`s and on `CuArray`/`ROCArray` (via `GPUArraysCore`), with an AMDGPU
  extension supplying a few `LinearAlgebra` workarounds.

## Installation

```julia
using Pkg
Pkg.add("LOBPCG")
```

## Usage

```julia
using LOBPCG, LinearAlgebra

N, nev = 500, 6
M = randn(N, N); A = Hermitian(M + M') + 50I   # some Hermitian operator
X0 = randn(N, nev)                              # initial guess (one column per eigenvector)

res = lobpcg_hyper(A, X0; tol=1e-8, prec=Diagonal(A))

res.λ                # the nev smallest eigenvalues (on the CPU)
res.X                # the corresponding eigenvectors
res.converged        # convergence flag
res.residual_norms   # per-eigenvector residual norms
```

`A` only needs to support `mul!(Y, A, X)` (matrix-vector products against a block of
vectors), so matrix-free operators work. A preconditioner `prec` is any object
supporting `ldiv!`; if it also supports adaptive updates it may implement
`precondprep!(prec, X)`, which is called before each application.

`diag_full(A, X0)` is provided as a dense reference solver (full diagonalization),
mostly for testing and small problems.

## Scope and limitations

- Only the **smallest** eigenpairs are computed (`largest=true` is rejected).
- `lobpcg_hyper` solves the **standard** eigenproblem. The low-level
  `lobpcg(A, X, B, ...)` entry point additionally accepts a symmetric
  positive-definite metric `B` for the generalized problem `A x = λ B x` (both paths
  are tested).

## License

MIT, see [LICENSE](LICENSE). Developed as part of the
[JuliaMolSim](https://github.com/JuliaMolSim) ecosystem.
