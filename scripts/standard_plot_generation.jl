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
    ga = fig[1:8, 2:3] = GridLayout()
    ca = fig[10, 2] = GridLayout()
    la = fig[10, 3] = GridLayout()
    ylabel = "complexity"
    xlabel = "entropy"
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

    Label(fig[1:8, 1], ylabel, rotation=pi/2)
    Label(fig[9, 2:3], xlabel)

    orig_marker = [
        MarkerElement(color=:black, marker=:circle)
    ]
    sur_marker = [
        MarkerElement(color=:black, marker=:dtriangle)
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
    ax::Axis,
    originals::DataFrame,
    surrogates::DataFrame,
    iterator_quantity::Union{UnitRange, AbstractVector},
    iterator_quantity_name::String)
    scatter!(
        ax,
        originals[:, :entropy], originals[:, :complexity],
        marker=:circle, color=originals[:, single_iterator_names[iterator_quantity_name]],
        strokecolor=:black, strokewidth=0.5,
        colorrange=(minimum(iterator_quantity), maximum(iterator_quantity))
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
            strokecolor=:black, strokewidth=0.5,
            colorrange=(minimum(iterator_quantity), maximum(iterator_quantity))
        )
    end
end

@unpack τs, ms, lengths = general_analysis_config
dims = 1:50
iterator_quantities = @strdict(τs, ms, lengths, dims)
single_iterator_names = Dict(
    "τs" => :τ,
    "ms" => :m,
    "lengths" => :data_length,
    "dims" => :dim
)
fixed_quantities = Dict(
    "τs" => Dict(
        :dim => dim -> dim .== 38,
        :m => m -> m .== 6,
        :data_length => data_length -> data_length .== 10^6
    ),
    "ms" => Dict(
        :dim => dim -> dim .== 38,
        :τ => τ -> τ .== 6,
        :data_length => data_length -> data_length .== 10^6
    ),
    "lengths" => Dict(
        :dim => dim -> dim .== 38,
        :m => m -> m .== 6,
        :τ => τ -> τ .== 6
    ),
    "dims" => Dict(
        :data_length => length -> length .== 10^6,
        :m => m -> m .== 6,
        :τ => τ -> τ .== 6
    ),
)

cbar_labels = Dict(
    "dims" => "dimension",
    "lengths" => "data length",
    "ms" => "pattern length",
    "τs" => "lag [\$\\delta t\$]"
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
    @unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure(
        cbar_label=cbar_labels[quantity_name],
        cbar_limits=(minimum(quantity), maximum(quantity)))
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