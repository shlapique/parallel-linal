module JacobyModule

export worker_func

# computes div(n, nprc) x's on every proc
function worker_func(n, x_old, α, β, ind)
    x_new = copy(β)
    for i in 1:length(β)
        Σ = 0.0
        for j in 1:n
            if j != ind[i]
                Σ += α[i, j] * x_old[j]
            end
        end
        x_new[i] = (β[i] - Σ) / α[i, ind[i]]
        @warn "from MODUL"
        @error x_new[i] 
    end
    return x_new
end

end
