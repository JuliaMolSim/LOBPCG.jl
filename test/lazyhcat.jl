@testset "LazyHcat internal data structure" begin
    a1 = rand(10, 5)
    a2 = rand(10, 2)
    a3 = rand(10, 7)
    b1 = rand(10, 6)
    b2 = rand(10, 2)
    A = hcat(a1, a2, a3)
    B = hcat(b1, b2)
    Ablock = LazyHcat(a1, a2, a3)
    Bblock = LazyHcat(b1, b2)
    @test Ablock' * Bblock ≈ A' * B
    @test Ablock' * B ≈ A' * B

    C = rand(14, 4)
    @test Ablock * C ≈ A * C

    D = rand(10, 4)
    @test mul!(D, Ablock, C, 1, 0) ≈ A * C

    @test mul_hermi(Ablock', Ablock) ≈ A' * A

    @test size(Ablock) == size(A)
end
