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

# A well-conditioned symmetric positive-definite metric with eigenvalues in [1, 3].
function spd_metric(N)
    Q = Matrix(qr(randn(N, N)).Q)
    Hermitian(Q * Diagonal(range(1.0, 3.0, N)) * Q')
end

@testset "generalized eigenproblem (B != I)" begin
    N, nev = 60, 4
    A = test_matrix(Float64, N)
    B = spd_metric(N)
    X0 = rand(N, nev)

    res = lobpcg(A, X0, B, Diagonal(A), 1e-9, 200)
    ref = sort(eigen(Matrix(A), Matrix(B)).values)[1:nev]
    @test res.λ ≈ ref atol=1e-7
    # Residual of the generalized eigenproblem A x = λ B x
    @test norm(A * res.X - B * res.X * Diagonal(res.λ)) < 1e-6
    # B-orthonormality of the returned eigenvectors
    @test norm(res.X' * B * res.X - I) < 1e-7
end

@testset "largest keyword is rejected" begin
    A = test_matrix(Float64, 40)
    X0 = rand(40, 3)
    @test_throws AssertionError lobpcg_hyper(A, X0; largest=true)
end
