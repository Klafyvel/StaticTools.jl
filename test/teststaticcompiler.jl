   using StaticCompiler

## --- Times table:

function times_table(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = parse(Int64, argv, 2)            # First command-line argument
    cols = parse(Int64, argv, 3)            # Second command-line argument

    M = MallocArray{Int64}(undef, rows, cols)
    @inbounds for i=1:rows
       for j=1:cols
           M[i,j] = i*j
       end
    end
    printf(M)
    free(M)
end

# Attempt to compile
path = compile_executable(times_table, (Int64, Ptr{Ptr{UInt8}}), tempdir())
@test isa(path, String)
# Attempt to run
println("5x5 times table:")
status = run(`$path 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## --- Random number generation

function rand_matrix(argc::Int, argv::Ptr{Ptr{UInt8}})
    argc == 3 || return printf(stderrp(), c"Incorrect number of command-line arguments\n")
    rows = parse(Int64, argv, 2)            # First command-line argument
    cols = parse(Int64, argv, 3)            # Second command-line argument

    M = MallocArray{Float64}(undef, rows, cols)
    rng = static_rng()
    @inbounds for i=1:rows
     for j=1:cols
        M[i,j] = rand(rng)
     end
    end
    printf(M)
    free(M)
end

# Attempt to compile
path = compile_executable(rand_matrix, (Int64, Ptr{Ptr{UInt8}}), tempdir())
@test isa(path, String)
# Attempt to run
println("5x5 random matrix:")
status = run(`$path 5 5`)
@test isa(status, Base.Process)
@test status.exitcode == 0

## ---
