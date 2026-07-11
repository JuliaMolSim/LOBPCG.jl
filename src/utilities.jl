# Small self-contained helpers used by the LOBPCG implementation. They are
# intentionally kept minimal (only what the solver needs) so the package stays
# free of any application-specific dependencies. Device-agnostic versions are
# defined for generic `AbstractArray`s, with GPU-optimized variants dispatching
# on `AbstractGPUArray`.

"""
Transfer an array from a device (typically a GPU) to the CPU.
"""
to_cpu(x::AbstractArray) = Array(x)
to_cpu(x::Array) = x

"""
Create an array of the same "array type" as `X` filled with zeros, minimizing the
number of allocations. This unifies CPU and GPU code, as the output always lands
on the same device as the input.
"""
function zeros_like(X::AbstractArray, T::Type=eltype(X), dims::Integer...=size(X)...)
    Z = similar(X, T, dims...)
    Z .= zero(T)
    Z
end
zeros_like(X::AbstractArray, dims::Integer...) = zeros_like(X, eltype(X), dims...)
zeros_like(X::Array, T::Type=eltype(X), dims::Integer...=size(X)...) = zeros(T, dims...)

# Calculate the norms of the columns of an array
function columnwise_norms(X::AbstractArray)
    vec(sqrt.(sum(abs2, X; dims=1)))
end

# Returns a vector of dot(A[:, i], B[:, i]), for all columns of A, B
@views function columnwise_dots(A::AbstractArray{T}, B::AbstractArray{T}) where {T}
    [dot(A[:, i], B[:, i]) for i = 1:size(A, 2)]
end

# GPU-specific implementation: the massive parallelism of the GPU is only fully
# exploited by operating on whole arrays rather than looping over columns.
function columnwise_dots(A::AbstractGPUArray{T}, B::AbstractGPUArray{T}) where {T}
    vec(sum(conj(A) .* B; dims=1))
end

format_log8(e) = @sprintf "%8.2f" log10(abs(e))

# Preconditioner API (also used in Optim.jl): if the solver supports adaptive
# preconditioning it will call `precondprep!(P, X)` right before applying the
# preconditioner. The default is a no-op; concrete preconditioners may override it.
precondprep!(P, X) = P
