using PrecompileTools: @setup_workload, @compile_workload

# Running a tiny solve during precompilation bakes the specialized method
# instances of the whole `lobpcg` call tree (Rayleigh-Ritz eigen, Cholesky
# orthogonalization, LazyHcat products, broadcasts, …) into the package cache,
# for the two element types that dominate usage (real and complex dense
# operators). Without this the first solve in a fresh session pays ~10 s of
# compilation; with it that drops to a fraction of a second.
@setup_workload begin
    @compile_workload begin
        for T in (Float64, ComplexF64)
            N, nev = 30, 3
            M = rand(T, N, N)
            A = Hermitian(M + M') + 10I
            X0 = rand(T, N, nev)
            # Preconditioned and unpreconditioned paths.
            lobpcg(A, X0, I, Diagonal(real(diag(A))), 1e-3, 20)
            lobpcg(A, X0, I, I, 1e-3, 20)
        end
    end
end
