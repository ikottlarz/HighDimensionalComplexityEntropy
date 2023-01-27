using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))

function standard_figure(; cbar_label::String, cbar_limits::Tuple)
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20
        )
    )
    fig = Figure(resolution=(800, 900))
    ga = fig[1:8, 1:2] = GridLayout()
    ca = fig[9, 1] = GridLayout()
    la = fig[9, 2] = GridLayout()
    lorenz_96 = Axis(ga[1, 1], title="Lorenz-96")
    generalized_henon = Axis(ga[1, 2], title="Generalized Henon")
    mackey_glass = Axis(ga[2, 1], title="Mackey-Glass")
    kuramoto_sivashinsky = Axis(ga[2, 2], title="Kuramoto-Sivashinsky")
    linkaxes!(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    Colorbar(
        ca[1, 1], colormap=:hawaii, limits=cbar_limits,
        vertical=false, label = cbar_label,
        flipaxis=false
    )

    orig_marker = [
        MarkerElement(color=:black, marker=:circle, markersize=ms)
    ]
    sur_marker = [
        MarkerElement(color=:black, marker=:dtriangle, markersize=ms)
    ]

    Legend(
        la[1, 1],
        [orig_marker, sur_marker],
        ["original", "surrogates"],
        framevisible=false
    )
    return (
        fig=fig,
        lorenz_96=lorenz_96,
        generalized_henon=generalized_henon,
        mackey_glass=mackey_glass,
        kuramoto_sivashinsky=kuramoto_sivashinsky,
        ca=ca,
        la=la
    )
end

function plot_system!(
    ax::Axis, originals::AbstractMatrix{Float64},
    surrogates::AbstractArray{Float64, 3},
    iterator_quantity::Union{UnitRange, AbstractVector},
    iterator_quantity_name::String)
    scatter!(
        ax,
        originals[:, :entropy], originals[:, :complexity],
        marker=:circle, color=iterator_quantity,
        strokecolor=:black, strokewidth=0.5
    )
    for val in iterator_quantity
        val_surrogates = subset(
            surrogates,
            single_iterator_names[iterator_quantity_name] => x -> x .== val
        )
        scatter!(
            ax,
            val_surrogates[:, :entropy], val_surrogates[:, :complexity],
            color=fill(val, size(val_surrogates[:, :entropy])), marker=:dtriangle,
            strokecolor=:black, strokewidth=0.5
        )
    end
end

@unpack τs, ms, data_lengths, dims = general_analysis_config
iterator_quantities = @strdict(τs, ms, data_lengths, dims)
single_iterator_names = Dict(
    "τs" => :τ,
    "ms" => :m,
    "data_lengths" => :data_length,
    "dims" => :dim
)
fixed_quantities = Dict(
    "τs" => Dict(
        :dim => dim -> dim .== 50,
        :m => m -> m .== 6,
        :data_length => data_length -> data_length .== 10^6
    ),
    "ms" => Dict(
        :dim => dim -> dim .== 50,
        :τ => τ -> τ .== 6,
        :data_length => data_length -> data_length .== 10^6
    ),
    "data_lengths" => Dict(
        :dim => dim -> dim .== 50,
        :m => m -> m .== 6,
        :τ => τ -> τ .== 6
    ),
    "dims" => Dict(
        :data_length => data_length -> data_length .== 10^6,
        :m => m -> m .== 6,
        :τ => τ -> τ .== 6
    ),
)

const systems = [
    "lorenz_96",
    "generalized_henon",
    "mackey_glass",
    "kuramoto_sivashinsky"
]
data = Dict{String, NamedTuple}()
for system in systems
    @unpack analysis_config = system_configs[system]
    @unpack num_surrogates, prefix = analysis_config
    original_file, _ = produce_or_load(complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix)
    surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix="$(prefix)_surrogates")
    data[system] = (
        originals = original_file["data"],
        surrogates = surrogate_file["data"]
    )
end

for (quantity_name, quantity) in iterator_quantities

    @unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure()
    for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
        @unpack originals, surrogates = data[system_name]
        filtered_originals = subset(
            originals,
            fixed_quantities[quantity_name]...
        )
        filtered_surrogates = subset(
            surrogates,
            fixed_quantities[quantity_name]...
        )
        plot_system!(
            system_ax,
            filtered_originals,
            filtered_surrogates,
            quantity,
            quantity_name
        )
    end
    save(plotsdir("$quantity_name.eps"), fig)
end