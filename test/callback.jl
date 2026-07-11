@testset "DefaultLobpcgCallback runs" begin
    A = randn(40, 40)
    A = A + A' + 20I
    X = randn(40, 3)

    # Run the callback to make sure it works, but don't print anything
    res = redirect_stdout(devnull) do
        lobpcg_hyper(A, X; prec=Diagonal(A), callback=DefaultLobpcgCallback(), tol=1e-6)
    end
    @test res.converged
end
