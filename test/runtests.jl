using LOBPCGEigensolver
using LinearAlgebra
using Random
using Test

using LOBPCGEigensolver: LazyHcat, mul_hermi, ortho!

Random.seed!(0)

@testset "LOBPCGEigensolver.jl" begin
    include("lazyhcat.jl")
    include("ortho.jl")
    include("diagonalization.jl")
    include("callback.jl")
end
