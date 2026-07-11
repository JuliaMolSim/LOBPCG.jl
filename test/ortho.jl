@testset "ortho! produces orthonormal columns" begin
    for T in (Float64, ComplexF64)
        X = rand(T, 30, 6)
        Y = ortho!(copy(X))[1]
        @test norm(Y' * Y - I) < 1e-10
    end
end

@testset "ortho! against a subspace (B = I)" begin
    Y = ortho!(rand(40, 5))[1]        # already orthonormal
    X = rand(40, 4)
    ortho!(X, Y, Y)                   # make X orthonormal and ⟂ Y
    @test norm(X' * X - I) < 1e-9
    @test norm(Y' * X) < 1e-9
end
