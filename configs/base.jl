using DrWatson
@quickactivate

include(srcdir("git_helpers.jl"))
include(scriptsdir("simulate_mackey_glass.jl"))
include(scriptsdir("simulate_generalized_henon.jl"))
include(scriptsdir("simulate_lorenz96.jl"))
include(scriptsdir("simulate_kuramoto_sivashinsky.jl"))
include(scriptsdir("calc_complexity_entropy.jl"))
include(srcdir("kuramoto_sivashinsky_kj.jl"))
include(scriptsdir("calc_ky_kuramoto_sivashinsky.jl"))
include(scriptsdir("calc_ky_generalized_henon.jl"))
include(scriptsdir("calc_ky_lorenz96.jl"))
include(scriptsdir("calc_ky_mackey_glass.jl"))

general_analysis_config = (
    ms=[3, 4, 5, 6, 7],
    τs=collect(1:50),
    lengths=10 .^(3:6),
    commit_hash=last_modifying_commit(
        srcdir("complexity_entropy.jl"),
        scriptsdir("calc_complexity_entropy.jl")
    ),
    num_surrogates=50
)

significance_config = (
    commit_hash=last_modifying_commit(
        scriptsdir("calc_significances.jl")
    )
)

system_configs = Dict(
    "mackey_glass" => (
        analysis_config = (
            prefix="mackey_glass",
            simulation_parameters=(
                β = 2.,
                γ = 1.,
                n = 9.65,
                max_τ = 50,
                min_τ = 4,
                Δt = 0.1,
                t_sample = 0.2,
                N = 1000000,
                Ttr = 1000,
                commit_hash = last_modifying_commit(
                    scriptsdir("simulate_mackey_glass.jl"),
                    srcdir("git_helpers.jl"),
                    srcdir("mackey_glass.jl")
                )
            ),
            simulation_function=simulate_mackey_glass,
            dims=collect(4:50),
            general_analysis_config...
        ),
        significance_config=significance_config,
        ky_config = (
            commit_hash=last_modifying_commit(
                scriptsdir("calc_ky_mackey_glass.jl"),
                srcdir("mackey_glass.jl")
            ),
            calculation_function=ky_dim_mackey_glass,
            simulation_parameters=(
                β = 2.,
                γ = 1.,
                n = 9.65,
                max_τ = 50,
                min_τ = 4,
                Δt = 0.1,
                N = 1000000,
                Ttr = 1000
            ),
        )
    ),
    "generalized_henon" => (
        analysis_config = (
            prefix="generalized_henon",
            simulation_parameters=(
                a = 1.76,
                b = 0.1,
                Dmax = 50,
                Dmin = 4,
                N = 1000000,
                Ttr = 1000,
                commit_hash = last_modifying_commit(
                    scriptsdir("simulate_generalized_henon.jl"),
                    srcdir("git_helpers.jl"),
                    srcdir("henon.jl")
                )
            ),
            simulation_function=simulate_generalized_henon,
            dims=collect(4:50),
            general_analysis_config...
        ),
        significance_config=significance_config,
        ky_config = (
            commit_hash=last_modifying_commit(
                scriptsdir("calc_ky_generalized_henon.jl"),
                srcdir("henon.jl")
            ),
            calculation_function=ky_dim_generalized_henon,
            simulation_parameters=(
                a = 1.76,
                b = 0.1,
                Dmax = 50,
                Dmin = 4,
                N = 1000000,
                Ttr = 1000,
            ),
        )
    ),
    "lorenz_96" => (
        analysis_config = (
            prefix="lorenz96",
            simulation_parameters=(
                reltol = 1e-9,
                abstol = 1e-9,
                Ttr = 1000.0,
                N = 1000000,
                F = 24.0,
                Δt = 0.02,
                Dmax = 50,
                Dmin = 4,
                commit_hash = last_modifying_commit(
                    scriptsdir("simulate_lorenz96.jl"),
                    srcdir("git_helpers.jl")
                )
            ),
            simulation_function=simulate_lorenz96,
            dims=collect(4:50),
            general_analysis_config...
        ),
        significance_config=significance_config,
        ky_config = (
            commit_hash=last_modifying_commit(
                scriptsdir("calc_ky_lorenz96.jl")
            ),
            calculation_function=ky_dim_lorenz96,
            simulation_parameters=(
                reltol = 1e-9,
                abstol = 1e-9,
                Ttr = 1000.0,
                N = 1000000,
                F = 24.0,
                Dmax = 50,
                Dmin = 4,
            )
        )
    ),
    "kuramoto_sivashinsky" => (
        analysis_config = (
            prefix="kuramoto_sivashinsky",
            simulation_parameters = (
                b_min=4,
                b_step=1,
                b_max=38, # total domain size
                T=1000000.0,
                Δt=1.0, # sampling rate
                Δx=0.2, # spatial discretization
                N=400000,
                commit_hash = last_modifying_commit(
                    scriptsdir("simulate_kuramoto_sivashinsky.jl"),
                    srcdir("git_helpers.jl"),
                    srcdir("kuramoto_sivashinsky.jl")
                )
            ),
            simulation_function=simulate_kuramoto_sivashinsky,
            dims=collect(4:38),
            general_analysis_config...
        ),
        significance_config=significance_config,
        ky_config = (
            commit_hash=last_modifying_commit(
                srcdir("kuramoto_sivashinsky_kj.jl"),
                scriptsdir("calc_ky_kuramoto_sivashinsky.jl")
            ),
            calculation_function=ky_dim_kuramoto_sivashinsky,
            simulation_parameters = (
                b_min=4,
                b_step=1,
                b_max=38, # total domain size
                T=1000000.0,
                Δt=1.0, # sampling rate
                Δx=0.2, # spatial discretization
                N=400000,
            ),
        )
    )
)