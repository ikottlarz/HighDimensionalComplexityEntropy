using DrWatson
@quickactivate
include(projectdir("configs/base.jl"))
using TimeseriesSurrogates, Random, HypothesisTests
using DataFrames, ComplexityMeasures
using CairoMakie, ProgressMeter
using Printf

set_theme!(
    Theme(
        markersize=20,
        fontsize=25,
        Axis = (
            titlefont = projectdir("cmu/cmunbx.ttf"),
            xlabelfont=projectdir("cmu/cmunrm.ttf"),
            ylabelfont=projectdir("cmu/cmunrm.ttf"),
            xticklabelfont=projectdir("cmu/cmunrm.ttf"),
            yticklabelfont=projectdir("cmu/cmunrm.ttf"),
            yticklabelsize=20,
            xticklabelsize=20,
        ),
        Legend = (
            labelfont=projectdir("cmu/cmunrm.ttf"),
        )
    )
)

# hard coded bc part of the files are not produced with this git repo!!!
hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

function pe_aape(config::NamedTuple)
    @unpack m, τ, ky_dim, data_length, system, n_sur = config
    @unpack analysis_config = system_configs[system]
    @unpack prefix, simulation_parameters, simulation_function = analysis_config
    file, _ = produce_or_load(
        simulation_function,
        simulation_parameters,
        datadir("sims");
        filename=hash,
        prefix=prefix
    )

    ky_dims = wload(datadir("analysis/$(prefix)_ky_dims_$(hashes[prefix]).jld2"))
    ky_data = ky_dims["data"]
    data = outerjoin(
        file["data"],
        ky_data,
        on=:dim
    )
    ts = data[isapprox.(data.ky_dim, ky_dim, atol=.5), :trajectory][1][1:data_length]
    est = SymbolicPermutation(; m, τ)
    west = SymbolicAmplitudeAwarePermutation()

    data = DataFrame(
        permutation_entropy=Float64[],
        amplitude_aware_permutation_entropy=Float64[],
        surrogate_algorithm=Symbol[],
        seed=Int[]
    )

    @showprogress for _ in 1:n_sur
        seed = rand(1:typemax(Int))
        rng = Xoshiro(seed)
        aaft_sur = surrogate(
            ts,
            AAFT(),
            rng
        )
        push!(data, Dict(
            :permutation_entropy=>entropy_normalized(Renyi(), est, aaft_sur),
            :amplitude_aware_permutation_entropy=>entropy_normalized(Renyi(), west, aaft_sur),
            :surrogate_algorithm=>:AAFT,
            :seed=>seed
        ))

        ft_sur = surrogate(
            ts,
            RandomFourier(true),
            rng
        )
        push!(data, Dict(
            :permutation_entropy=>entropy_normalized(Renyi(), est, ft_sur),
            :amplitude_aware_permutation_entropy=>entropy_normalized(Renyi(), west, ft_sur),
            :surrogate_algorithm=>:FT,
            :seed=>seed
        ))
    end
    parameters = @strdict(config)
    return @strdict(data, parameters)
end

for pe in [:permutation_entropy, :amplitude_aware_permutation_entropy]

    fig = Figure(
        resolution=(800, 900),
        )
    lorenz_96 = Axis(fig[1:4, 2:5]; title="Lorenz-96", xticks=[0.9962, 0.9964, 0.9966])
    generalized_henon = Axis(fig[1:4, 6:9]; title="Generalized Hénon", xticks=[0.99993, 0.99994, 0.99995])
    mackey_glass = Axis(fig[5:8, 2:5]; title="Mackey-Glass")
    kuramoto_sivashinsky = Axis(fig[5:8, 6:9]; title="Kuramoto-Sivashinsky", xticks=[0.9960, 0.9962, 0.9964])
    la = fig[10, :] = GridLayout()
    layouts = @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

    lorenz_96_legend = fig[1, 2] = GridLayout()
    henon_legend = fig[1, 6] = GridLayout()
    mackey_glass_legend = fig[5, 2] = GridLayout()
    ksiva_legend = fig[5, 6] = GridLayout()

    Label(fig[1:8, 1], "density", rotation=pi/2, font=projectdir("cmu/cmunrm.ttf"))
    Label(fig[9, 2:end], L"H_S")

    legend_layouts = Dict(
        "lorenz_96"=>lorenz_96_legend,
        "mackey_glass"=>mackey_glass_legend,
        "generalized_henon"=>henon_legend,
        "kuramoto_sivashinsky"=>ksiva_legend
    )

    system_names = Dict(
        "lorenz_96"=>"Lorenz-96",
        "generalized_henon"=>"Generalized Hénon",
        "mackey_glass"=>"Mackey-Glass",
        "kuramoto_sivashinsky"=>"Kuramoto-Sivashinsky"
    )

    for system in ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"]
        file, _ = produce_or_load(pe_aape, (m=6, τ=10, ky_dim=43, system=system, data_length=10^6, n_sur=400), datadir("analysis"), filename=hash, prefix="$(system)_pe_aape")
        @show system
        pe_ax = layouts[system]
        data = file["data"]
        # aape_ax = Axis(layout[2, :]; title="Amplitude Aware PE")
        aaft_pe = subset(
            data,
            :surrogate_algorithm => x-> x.==:AAFT,
        )[:, pe]
        hist!(
            pe_ax,
            aaft_pe;
            color=(:maroon, 0.75),
            density=true
        )
        ft_pe = subset(
            data,
            :surrogate_algorithm => x-> x.==:FT,
        )[:, pe]
        hist!(
            pe_ax,
            ft_pe;
            color=(:teal, 0.75),
            density=true
        )
        p = HypothesisTests.pvalue(
            ApproximateTwoSampleKSTest(
                ft_pe,
                aaft_pe
            )
        )
        p_scientific = p < 1e-10 ? L"p\,<\, 10^{-10}" : L"p \approx %$(round(p; digits=2))"
        Legend(legend_layouts[system][1, 1], [MarkerElement(color=:white, marker=:rect)], [p_scientific]; framevisible=false, labelsize=20)

    end

    Legend(
        la[1, 1],
        [LineElement(
            color=(:maroon, 0.75),
            linewidth=20
        ),
        LineElement(
            color=(:teal, 0.75),
            linewidth=20
        )],
        ["AAFT surrogates", "FT surrogates"];
        nbanks=2
    )



    safesave(plotsdir("surrogate_$(pe)_inspection.eps"), fig)
end