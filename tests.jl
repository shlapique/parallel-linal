function run_tests(Ns, nprcs)
    for j in 1:length(nprcs)
        for i in 1:length(Ns)
            println("==========")
            Main.newARGS = [Ns[i], nprcs[j]]
            @warn "TEST: (N=$(Ns[i])), (nprc=$(nprcs[j]))"
            include(prog)
            @info "stime=$stime, ptime=$ptime"
            data[i, j] = (stime, ptime)
            println("==========")
            sleep(1)
        end
    end
end


default_nprcs = [2, 4, 6, 8, 10]
default_max_cores = maximum(default_nprcs)

prog = "distr-jacobi.jl"
Ns = [600, 1080, 2040, 5040, 10080]

# get max_cores from a user
cores = isdefined(Main, :max_cores) ? max_cores : default_max_cores

if cores in default_nprcs
    @warn "The program will use up to $cores cores(threads) for tests!"
    if !isdefined(Main, :max_cores)
        @info "if want less or more, set the `max_cores` value in env"
    end
    println("Do you want to continue? (y/n)")
    response = lowercase(strip(readline()))

    if response == "y" || response == "yes"
        nprcs = default_nprcs[1:findfirst(x->x==cores, default_nprcs)]
        data = Array{Tuple{Float64, Float64}}(undef, length(Ns), length(nprcs))
        run_tests(Ns, nprcs)
        @show data
    elseif response == "n" || response == "no"
        exit(2)
    else
        println("Invalid input. Please enter either 'y' or 'n'.")
        exit(2)
    end
else
    @error "`max_cores` values can be only from this list [2, 4, 6, 8, 10]"
    exit(1)
end
