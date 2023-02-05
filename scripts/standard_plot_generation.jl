using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))

function standard_figure(;
    cbar_label::String,
    cbar_limits::Tuple,
    quantity::Symbol,
    fix_quantities_for_plot)
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20
        )
    )
    # copy info dict and delete fix value of quantity that will
    # be iterated in this plot
    info_dict = copy(fixed_quantities["values"])
    delete!(info_dict, quantity)

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
        ca[1, 1],
        colormap=cgrad(
            :hawaii,
            scale=fix_quantities_for_plot[quantity]["scale"]),
        limits=cbar_limits,
        vertical=false, label = cbar_label,
        flipaxis=false,
        scale=fix_quantities_for_plot[quantity]["scale"]
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

    meta_layout = fig[1:10, 4] = GridLayout()
    for (i, (q, value)) in enumerate(info_dict)
        Colorbar(
            meta_layout[i, 1],
            limits=fix_quantities_for_plot[q]["limits"],
            label=fix_quantities_for_plot[q]["label"],
            colormap=cgrad(
                :grayC,
                scale=fix_quantities_for_plot[q]["scale"]
            ),
            scale=fix_quantities_for_plot[q]["scale"]
        )
        cb_ax = Axis(meta_layout[i, 1])
        ylims!(cb_ax, fix_quantities_for_plot[q]["limits"])
        hidedecorations!(cb_ax)
        lines!(
            cb_ax,
            [0, 1],
            ones(2)*value,
            linewidth=5,
            color=ones(2)*value,
            colormap=cgrad(
                :hawaii,
                scale = fix_quantities_for_plot[q]["scale"]
            ),
            colorrange=fix_quantities_for_plot[q]["limits"],
        )
    end

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
        marker=:circle, color=originals[:,
        single_iterator_names[iterator_quantity_name]],
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
    "functions" => Dict(
        :dim => dim -> dim .== 38,
        :m => m -> m .== 6,
        :data_length => data_length -> data_length .== 10^6,
        :τ => τ -> τ .== 10,
    ),
    "values" => Dict(
        :dim => 38,
        :m => 6,
        :data_length => 10^6,
        :τ => 10
    )
)

fix_quantities_for_plot = Dict(
    :dim => Dict(
        "limits" => (1, 50),
        "label" => L"$\Delta^{(KY)}$",
        "scale" => identity
    ),
    :m => Dict(
        "limits" => (3, 7),
        "label" => "pattern length",
        "scale" => identity
    ),
    :data_length => Dict(
        "limits" => (10^3, 10^6),
        "label" => "data length",
        "scale" => log10
    ),
    :τ => Dict(
        "limits" => (1, 50),
        "label" => L"lag [$\delta t$]",
        "scale" => identity
    )
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
        ;
        cbar_label=cbar_labels[quantity_name],
        cbar_limits=(minimum(quantity), maximum(quantity)),
        quantity=single_iterator_names[quantity_name],
        fix_quantities_for_plot
    )
    for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
        fix_qs_copy = copy(fixed_quantities["functions"])
        delete!(fix_qs_copy, single_iterator_names[quantity_name])
        @unpack originals, surrogates = data[system_name]
        filtered_originals = subset(
            originals,
            fix_qs_copy...
        )
        filtered_surrogates = subset(
            surrogates,
            fix_qs_copy...
        )
        plot_system!(
            system_ax,
            filtered_originals,
            filtered_surrogates,
            quantity,
            quantity_name
        )
    end
    wsave(plotsdir("$quantity_name.eps"), fig)
end