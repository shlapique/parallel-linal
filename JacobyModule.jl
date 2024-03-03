module JacobyModule
using SharedArrays

export worker_func

# computes div(n, nprc) x's on every proc
function worker_func(n, x_old, α, β, ind)
    # @warn "TESTGINS FROM WORKER FUNC FOR VARS..."
    x_new = copy(β)
    for i in 1:length(β)
        Σ = 0.0
        for j in 1:n
            if j != ind[i]
                Σ += α[i, j] * x_old[j]
            end
        end
        x_new[i] = (β[i] - Σ) / α[i, ind[i]]
        # @warn "from MODUL"
    end
    # @error x_new
    return x_new
end

println("JacobyModule is loaded!")

end
