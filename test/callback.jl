@testset "DefaultLobpcgCallback runs" begin
    A = randn(40, 40)
    A = A + A' + 20I
    X = randn(40, 3)

    # Run the callback to make sure it works, but don't print anything
    res = redirect_stdout(devnull) do
        lobpcg(A, X, I, Diagonal(A), 1e-6, 100; callback=DefaultLobpcgCallback())
    end
    @test maximum(res.residual_norms) < 1e-5
end
