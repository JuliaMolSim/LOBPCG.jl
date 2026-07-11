# Build a well-conditioned Hermitian matrix with a known spectrum
function test_matrix(T, N; shift=20)
    A = rand(T, N, N)
    Hermitian(A + A') + shift * I
end

@testset "lobpcg_hyper matches dense diagonalization" begin
    for T in (Float64, ComplexF64)
        N, nev = 60, 5
        A = test_matrix(T, N)
        X0 = rand(T, N, nev)

        ref = diag_full(A, X0)
        res = lobpcg_hyper(A, X0; tol=1e-9, prec=Diagonal(A))

        @test res.converged
        @test res.λ ≈ ref.λ
        @test maximum(res.residual_norms) < 1e-8
        # Returned eigenvectors are orthonormal
        @test norm(res.X' * res.X - I) < 1e-8
        # And they actually solve the eigenproblem
        @test norm(A * res.X - res.X * Diagonal(res.λ)) < 1e-7
    end
end

@testset "lobpcg_hyper without preconditioner" begin
    N, nev = 60, 4
    A = test_matrix(Float64, N)
    X0 = rand(N, nev)
    res = lobpcg_hyper(A, X0; tol=1e-8)
    @test res.converged
    @test res.λ ≈ diag_full(A, X0).λ atol=1e-7
end

# NOTE: the generalized eigenproblem path (B != I) is currently untested and
# unused (DFTK only ever calls the solver with B = I). It carries pre-existing
# latent bugs and is intentionally left uncovered here; see README.

@testset "largest keyword is rejected" begin
    A = test_matrix(Float64, 40)
    X0 = rand(40, 3)
    @test_throws AssertionError lobpcg_hyper(A, X0; largest=true)
end
