using Distributed 
using SharedArrays
using BenchmarkTools

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
            # @warn "from normal jacobi"
            # @error x_new[i]
        end
        if maximum(abs.(x_new - x_old)) < ε 
            return x_new
        end
        copy!(x_old, x_new)
        count += 1
    end
    return x_old
end


function pjacobi(A, b, x0, max_count, ε, nprc)
    x_old = copy(x0)
    x_old = SharedVector(x_old)
    x_new = []
    count = 0
    # @warn "Time from while:"
    while count < max_count
        x_new = []
        # @warn "time from Parallel Jacoby insides:"
        x_new = @distributed vcat for r in range(1, nprc)
            JacobyModule.worker_func(n, x_old, view(A, ranges[r], :), 
                                            b[ranges[r]], ranges[r])
            end
        if maximum(abs.(x_new - x_old)) < ε 
            return x_new
        end
        copy!(x_old, x_new)
        count += 1
    end

    return x_old
end


max_count = 100
ε = 1e-3

N = 12000
nprc = 4

A = gen_matrix(N)
b = gen_matrix(N)[1, :]
x0 = zeros(N)

@btime x = jacobi(A, b, x0, max_count, ε)

# PARALLEL
#
n = length(b)
per_w = div(n, nprc)
@info "rows per proc: $per_w"
if nprc > n
    @error "The number of procs $nprc is bigger then number of equations"
    @info "Reduce the number of procs at least to $n!"
    return 1
end
if mod(n, nprc) != 0
    @error "mod(n, nprc) != 0!!!!!"
    return 2
end

addprocs(nprc) 

@everywhere include("JacobyModule.jl")

# create range for every proc
ranges = create_ranges(n, div(n, nprc))

A = SharedMatrix(A)
b = SharedVector(b)

@warn "STARTING PARALLEL PROCESSING..."

@btime X = pjacobi(A, b, x0, max_count, ε, nprc)

rmprocs(procs()[2:end])
