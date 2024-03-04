using Distributed
using BenchmarkTools

nprc = 2
addprocs(nprc) 
w = workers()

@everywhere using DistributedData

function gen_matrix(n)
    A = randn(n, n)
    for i in 1:n
        A[i, i] = sum(abs.(A[i, :])) + 1
    end
    return A
end


function create_ranges(n, t)
    ranges = []
    start = 1
    while start <= n
        if start + t - 1 <= n
            push!(ranges, range(start, start+t-1))
        else
            push!(ranges, range(start, n))
        end
        start += t
    end
    return ranges
end


function jacobi(A, b, x0, max_count = 1000, ε = 1e-6)
    n = length(b)
    x_old = copy(x0)
    x_new = similar(x_old)
    count = 0
    while count < max_count
        for i in 1:n
            Σ = 0.0
            for j in 1:n
                if j != i
                    Σ += A[i, j] * x_old[j]
                end
            end
            x_new[i] = (b[i] - Σ) / A[i, i]
        end
        if maximum(abs.(x_new - x_old)) < ε 
            return x_new
        end
        copy!(x_old, x_new)
        count += 1
    end
    return x_old
end

# computes div(n, nprc) x's on every proc
@everywhere function worker_func(n, x_old, α, β, ind)
# function worker_func(n, x_old, α, β, ind)
    x_new = copy(β)
    for i in 1:length(β)
        Σ = 0.0
        for j in 1:n
            if j != ind[i]
                Σ += α[i, j] * x_old[j]
            end
        end
        x_new[i] = (β[i] - Σ) / α[i, ind[i]]
    end
    return x_new
end


function pjacobi(max_count, ε, nprc, x0)
    x_old = copy(x0)
    x_new = []
    count = 0
    while count < max_count
        # send data to processes
        for r in range(1, nprc)
            save_at(w[r], :x_old, x_old)
        end
        # obtain another x_new
        x_new = reduce(vcat, map(fetch, [get_from(i, :(begin worker_func(N, x_old, data, b, ind) end))
                                         for i in workers()]))
        if maximum(abs.(x_new - x_old)) < ε 
            return x_new
        end
        copy!(x_old, x_new)
        count += 1
    end

    return x_old
end


max_count = 1000
ε = 1e-3

N = 1000

A = gen_matrix(N)
b = gen_matrix(N)[1, :]
x0 = zeros(N)

@btime x = jacobi(A, b, x0, max_count, ε)
x = jacobi(A, b, x0, max_count, ε)

# PARALLEL
#
per_w = div(N, nprc)
@info "rows per proc: $per_w"
if nprc > N
    @error "The number of procs $nprc is bigger then number of equations"
    @info "Reduce the number of procs at least to $n!"
    return 1
end
if mod(N, nprc) != 0
    @error "mod(n, nprc) != 0!!!!!"
    return 2
end


# create range for every proc
ranges = create_ranges(N, div(N, nprc))

@warn "PUTTING DATA AND VARS ON NODES"

for r in range(1, nprc)
    save_at(w[r], :data, A[ranges[r], :])
    save_at(w[r], :N, N)
    save_at(w[r], :b, b[ranges[r]])
    save_at(w[r], :ind, ranges[r])
end


@warn "STARTING PARALLEL PROCESSING..."

@btime X = pjacobi(max_count, ε, nprc, x0)
X = pjacobi(max_count, ε, nprc, x0)

rmprocs(procs()[2:end])
