using DrWatson, Test
@quickactivate "2023-01-19_JuliaSimulations"

# Here you include files using `srcdir`
include(srcdir("complexity_entropy.jl"))

# Run test suite
println("Starting tests")
ti = time()

@testset "2023-01-19_JuliaSimulations tests" begin
    x = randn(10000)
    est = SymbolicPermutation(; m=3)
    entropy, complexity = entropy_stat_complexity(est, x)
    @test 0 < complexity < 0.01
end

ti = time() - ti
println("\nTest took total time of:")
println(round(ti/60, digits = 3), " minutes")
