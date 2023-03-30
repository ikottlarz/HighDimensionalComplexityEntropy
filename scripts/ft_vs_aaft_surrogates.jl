using DrWatson
@quickactivate
include(projectdir("configs/base.jl"))
using TimeseriesSurrogates, Random
using DataFrames, ComplexityMeasures
using CairoMakie, ProgressMeter

set_theme!(
    Theme(
        markersize=20,
        fontsize=20,
        Axis = (
            titlefont = projectdir("cmu/cmunrm.ttf"),
            xlabelfont=projectdir("cmu/cmunrm.ttf"),
            ylabelfont=projectdir("cmu/cmunrm.ttf"),
            xticklabelfont=projectdir("cmu/cmunrm.ttf"),
            yticklabelfont=projectdir("cmu/cmunrm.ttf"),
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
            :permutation_entropy=>entropy(Renyi(), est, ft_sur),
            :amplitude_aware_permutation_entropy=>entropy(Renyi(), west, ft_sur),
            :surrogate_algorithm=>:FT,
            :seed=>seed
        ))
    end
    parameters = @strdict(config)
    return @strdict(data, parameters)
end

fig = Figure(
    resolution=(800, 900),
    )
lorenz_96 = fig[1:4, 1] = GridLayout()
generalized_henon = fig[1:4, 2] = GridLayout()
mackey_glass = fig[5:8, 1] = GridLayout()
kuramoto_sivashinsky = fig[5:8, 2] = GridLayout()
la = fig[9, :] = GridLayout()
layouts = @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

for (label, system) in zip(["A", "B", "C", "D"], ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"])
    layout = layouts[system]
    Label(layout[1, 1, TopLeft()], label,
        padding = (0, 5, 5, 0),
        halign = :right)
end

for system in ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"]
    file, _ = produce_or_load(pe_aape, (m=6, τ=10, ky_dim=43, system=system, data_length=10^6, n_sur=400), datadir("analysis"), filename=hash, prefix="$(system)_pe_aape")
    @show system
    layout = layouts[system]
    data = file["data"]
    pe_ax = Axis(layout[1, :]; title="PE")
    aape_ax = Axis(layout[2, :]; title="Amplitude Aware PE")

    hist!(
        pe_ax,
        subset(
            data,
            :surrogate_algorithm => x-> x.==:AAFT,
        )[:, :permutation_entropy],
        color=(:maroon, 0.75)
    )
    hist!(
        pe_ax,
        subset(
            data,
            :surrogate_algorithm => x-> x.==:FT,
        )[:, :permutation_entropy],
        color=(:teal, 0.75)
    )
    hist!(
        aape_ax,
        subset(
            data,
            :surrogate_algorithm => x-> x.==:AAFT,
        )[:, :amplitude_aware_permutation_entropy],
        color=(:maroon, 0.75)
    )
    hist!(
        aape_ax,
        subset(
            data,
            :surrogate_algorithm => x-> x.==:FT,
        )[:, :amplitude_aware_permutation_entropy],
        color=(:teal, 0.75)
    )

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



safesave(plotsdir("surrogate_pe_inspection.png"), fig)