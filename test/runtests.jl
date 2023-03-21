using DrWatson, Test
@quickactivate "2023-01-19_JuliaSimulations"

# Here you include files using `srcdir`
include(srcdir("complexity_entropy.jl"))
include(srcdir("min_max_complexity_entropy.jl"))

# Run test suite
println("Starting tests")
ti = time()

using Distances

@testset "Statistical Complexity" begin

    m, τ = 6, 1
    x = randn(10000)
    est = SymbolicPermutation(; m, τ)
    h, c = entropy_stat_complexity(est, x)
    @test c isa Real
    @test h isa Real
    @test 0 < c < 0.02
    h, c = entropy_stat_complexity(est, collect(1:100))
    @test c == 0.0
    @test h == 0.0

    # test minimum and maximum complexity entropy curves
    h, c_js = minimum_complexity_entropy(est; num=10000)
    @test minimum(h) == 0
    @test maximum(h) ≈ 1
    @test minimum(c_js) == 0
    # this value is calculated with statcomp
    @test maximum(c_js) ≈ 0.197402387702839

    h, c_js = maximum_complexity_entropy(est)
    @test minimum(h) == 0
    @test 0.99 <= maximum(h) <= 1
    @test minimum(c_js) == 0
    # this value is calculated with statcomp
    @test maximum(c_js) ≈ 0.496700423446187
end

ti = time() - ti
println("\nTest took total time of:")
println(round(ti/60, digits = 3), " minutes")
