using LOBPCG
using LinearAlgebra
using Random
using Test

using LOBPCG: LazyHcat, mul_hermi, ortho!

Random.seed!(0)

@testset "LOBPCG.jl" begin
    include("lazyhcat.jl")
    include("ortho.jl")
    include("diagonalization.jl")
    include("callback.jl")
end
