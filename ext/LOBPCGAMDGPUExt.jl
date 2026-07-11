module LOBPCGAMDGPUExt
using AMDGPU
using LinearAlgebra

# Workarounds for LinearAlgebra routines that LOBPCG relies on (Cholesky
# orthogonalization, the SVD fallback, and 5-argument `mul!`) but that are
# currently broken or slow for AMDGPU `ROCArray`s.

# Temporary workaround to not trigger https://github.com/JuliaGPU/AMDGPU.jl/issues/734
function LinearAlgebra.cholesky(A::Hermitian{T, <:AMDGPU.ROCArray}) where {T}
    Acopy, info = AMDGPU.rocSOLVER.potrf!(A.uplo, copy(A.data))
    LinearAlgebra.Cholesky(Acopy, A.uplo, info)
end

# Temporary workaround for SVD. See https://github.com/JuliaGPU/AMDGPU.jl/issues/837
function LinearAlgebra.LAPACK.gesdd!(jobz::Char, A::AMDGPU.ROCArray{T}) where {T}
    AMDGPU.rocSOLVER.gesvd!(jobz, jobz, A)
end

# Temporary workaround for 5-argument mul!, where performance is very bad when array
# element types and scaling factors types differ.
# See https://github.com/JuliaGPU/AMDGPU.jl/issues/866#issuecomment-3636981853
# Scaling a Float/Complex matrix with an Integer:
function LinearAlgebra.mul!(C::AMDGPU.ROCArray{T}, A::AMDGPU.ROCArray{T}, B::AMDGPU.ROCArray{T},
                            α::U, β::U) where {T<:Union{AbstractFloat,Complex}, U<:Integer}
    LinearAlgebra.mul!(C, A, B, T(α), T(β))
end
# Scaling a Complex matrix with a Float:
function LinearAlgebra.mul!(C::AMDGPU.ROCArray{T}, A::AMDGPU.ROCArray{T}, B::AMDGPU.ROCArray{T},
                            α::U, β::U) where {T<:Complex, U<:AbstractFloat}
    LinearAlgebra.mul!(C, A, B, T(α), T(β))
end

end
