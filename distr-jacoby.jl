using Distributed 

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
            @warn "from normal jacobi"
            @error x_new[i]
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
    w = workers()

    # create range for every proc
    ranges = create_ranges(n, per_w)

    @everywhere include("JacobyModule.jl")

    # send parts of matrix A to procs
    # for r in range(1, nprc)
    #     ed = @spawnat w[r] 
    # end

    x_old = copy(x0)
    x_new = []

    count = 0
    while count < max_count
        x_new = []
        for r in range(1, nprc)
            ans = @spawnat w[r] JacobyModule.worker_func(n, x_old, 
                                                         view(A, ranges[r], :), 
                                                         b[ranges[r]], ranges[r])
            f = fetch(ans)
            @error f
            @info count
            append!(x_new, f)
        end
        @warn "TEST TEST"
        @error x_new
        if maximum(abs.(x_new - x_old)) < ε 
            return x_new
        end
        copy!(x_old, x_new)
        count += 1
    end

    rmprocs(procs()[2:end])
    return x_old
end


max_count = 1000
ε = 1e-3

N = 6000

# A = [4.0 1.0 1.0; 4.0 -8.0 0.0; -2.0 2.0 5.0]
A = gen_matrix(N)
# b = [7.0; -21.0; 15.0]
b = gen_matrix(N)[1, :]

# x0 = [0.0; 0.0; 0.0]
x0 = zeros(N)

x = jacobi(A, b, x0, max_count, ε)

X = pjacobi(A, b, x0, max_count, ε, 6)

rmprocs(procs()[2:end])
