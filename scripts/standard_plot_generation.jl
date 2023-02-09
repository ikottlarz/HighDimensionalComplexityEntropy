using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))

struct TeXTicks end

function Makie.get_ticks(::TeXTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals = Makie.get_tickvalues(
        Makie.automatic, any_scale, vmin, vmax)
    labels = [L"%$(floor(val) == val ? Int(round(val)) : round(val, digits=2))" for val in vals]
    vals, labels
end

struct TeXLogTicks end

function Makie.get_ticks(::TeXLogTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals = lengths
    labels = [L"10^{%$(Int(log10(val)))}" for val in vals]
    vals, labels
end

struct InsXTicks end

function Makie.get_ticks(::InsXTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals = [0.98, 1.0]
    labels = [L"%$(round(val, digits=2))" for val in vals]
    vals, labels
end

function standard_figure(;
    cbar_label,
    cbar_limits::Tuple,
    quantity::Symbol,
    inset::Bool,
    fix_quantities_for_plot)
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20,
            fontsize=27
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
    ylabel = L"complexity $C_{JS}$"
    xlabel = L"entropy $H_S$"
    xticks = TeXTicks()
    yticks = TeXTicks()
    lorenz_96 = Axis(ga[1, 1], title=L"Lorenz-96 $ $"; xticks, yticks)
    generalized_henon = Axis(ga[1, 2], title=L"Generalized Henon $ $"; xticks, yticks)
    mackey_glass = Axis(ga[2, 1], title=L"Mackey-Glass $ $"; xticks, yticks)
    kuramoto_sivashinsky = Axis(ga[2, 2], title=L"Kuramoto-Sivashinsky $ $"; xticks, yticks)
    linkaxes!(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

    if inset
        lorenz_96_inset = Axis(
            ga[1, 1];
            xticks=InsXTicks(), yticks,
            inset_kwargs...
        )
        generalized_henon_inset = Axis(
            ga[1, 2];
            xticks=InsXTicks(), yticks,
            inset_kwargs...
        )
        mackey_glass_inset = Axis(
            ga[2, 1];
            xticks=InsXTicks(), yticks,
            inset_kwargs...
        )
        kuramoto_sivashinsky_inset = Axis(
            ga[2, 2];
            xticks=InsXTicks(), yticks,
            inset_kwargs...
        )
        for ax in [lorenz_96_inset, generalized_henon_inset, mackey_glass_inset, kuramoto_sivashinsky_inset]
            xlims!(ax; inset_xlims...)
            ylims!(ax; inset_ylims...)
            translate!(ax.blockscene, 0, 0, 10)
        end
    end

    Colorbar(
        ca[1, 1],
        colormap=cgrad(
            :hawaii,
            scale=fix_quantities_for_plot[quantity]["scale"]),
        limits=cbar_limits,
        vertical=false, label = cbar_label,
        flipaxis=false, ticks= fix_quantities_for_plot[quantity]["scale"] == identity ? TeXTicks() : TeXLogTicks(),
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
        [L"original $ $", L"surrogates $ $"],
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
            scale=fix_quantities_for_plot[q]["scale"],
            ticks= fix_quantities_for_plot[q]["scale"] == identity ? TeXTicks() : TeXLogTicks()
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

    if inset
        return (
            fig=fig,
            lorenz_96=(ax=lorenz_96, ins=lorenz_96_inset),
            generalized_henon=(ax=generalized_henon, ins=generalized_henon_inset),
            mackey_glass=(ax=mackey_glass, ins=mackey_glass_inset),
            kuramoto_sivashinsky=(ax=kuramoto_sivashinsky, ins=kuramoto_sivashinsky_inset),
            ca=ca,
            la=la
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
    ax::Union{Axis, NamedTuple},
    originals::DataFrame,
    surrogates::DataFrame,
    iterator_quantity::Union{UnitRange, AbstractVector},
    iterator_quantity_name::String,
    inset::Bool)
    if inset
        @unpack ax, ins = ax
    end
    scatter!(
        ax,
        originals[:, :entropy], originals[:, :complexity],
        marker=:circle, color=originals[:,
        single_iterator_names[iterator_quantity_name]],
        strokecolor=:black, strokewidth=0.5,
        colorrange=(minimum(iterator_quantity), maximum(iterator_quantity))
    )
    if inset
        scatter!(
            ins,
            originals[:, :entropy], originals[:, :complexity],
            marker=:circle, color=originals[:,
            single_iterator_names[iterator_quantity_name]],
            strokecolor=:black, strokewidth=0.5,
            colorrange=(minimum(iterator_quantity), maximum(iterator_quantity))
        )
    end
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
        if inset
            scatter!(
                ins,
                val_surrogates[:, :entropy], val_surrogates[:, :complexity],
                color=fill(val, size(val_surrogates[:, :entropy])), marker=:dtriangle,
                strokecolor=:black, strokewidth=0.5,
                colorrange=(minimum(iterator_quantity), maximum(iterator_quantity))
            )
        end
    end
end

@unpack τs, ms, lengths = general_analysis_config
dims = 1:50
iterator_quantities = @strdict(τs, ms, lengths, dims)
single_iterator_names = Dict(
    "τs" => :τ,
    "ms" => :m,
    "lengths" => :data_length,
    "dims" => :ky_dim
)
fixed_quantities = Dict(
    "functions" => Dict(
        :ky_dim => x -> isapprox.(x, 43, atol=.5),
        :m => m -> m .== 6,
        :data_length => data_length -> data_length .== 10^6,
        :τ => τ -> τ .== 10,
    ),
    "values" => Dict(
        :ky_dim => 43,
        :m => 6,
        :data_length => 10^6,
        :τ => 10
    )
)

fix_quantities_for_plot = Dict(
    :ky_dim => Dict(
        "limits" => (1, 50),
        "label" => L"$\Delta^{(KY)}$",
        "scale" => identity
    ),
    :m => Dict(
        "limits" => (3, 7),
        "label" => L"pattern length $m$",
        "scale" => identity
    ),
    :data_length => Dict(
        "limits" => (10^3, 10^6),
        "label" => L"data length $ $",
        "scale" => log10
    ),
    :τ => Dict(
        "limits" => (1, 50),
        "label" => L"lag [$\delta t$]",
        "scale" => identity
    )
)

cbar_labels = Dict(
    "dims" => L"$\Delta^{(KY)}$",
    "lengths" => L"data length $ $",
    "ms" => L"pattern length $m$",
    "τs" => L"lag [$\delta t$]"
)

inset_kwargs = (
    width=Relative(0.5),
    height=Relative(0.5),
    halign=0.4,
    valign=0.25,
    backgroundcolor=:white,
    xgridcolor=:gray35,
    ygridcolor=:gray35,
    xticklabelsize=20,
    yticklabelsize=20
)
inset_xlims = (low=0.97, high=1.01)
inset_ylims = (low=-0.01, high=0.05)

const systems = [
    "lorenz_96",
    "generalized_henon",
    "mackey_glass",
    "kuramoto_sivashinsky"
]
# hard coded bc part of the files are not produced with this git repo!!!
hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "2102259424389999364",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

data = Dict{String, NamedTuple}()
for system in systems
    @unpack analysis_config = system_configs[system]
    @unpack num_surrogates, prefix = analysis_config
    original_file, _ = produce_or_load(complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix)
    surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix="$(prefix)_surrogates")
    ky_dims = wload(datadir("analysis/$(prefix)_ky_dims_$(hashes[prefix]).jld2"))
    ky_data = ky_dims["data"]
    data[system] = (
        originals = outerjoin(
            original_file["data"],
            ky_data,
            on=:dim),
        surrogates = outerjoin(
            surrogate_file["data"],
            ky_data,
            on=:dim
        )
    )
end

for (quantity_name, quantity) in iterator_quantities
    inset = quantity_name ∈ ["τs", "dims"] ? true : false
    @unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure(
        ;
        cbar_label=cbar_labels[quantity_name],
        cbar_limits=(minimum(quantity), maximum(quantity)),
        quantity=single_iterator_names[quantity_name],
        fix_quantities_for_plot,
        inset
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
            quantity_name,
            inset
        )
    end
    wsave(plotsdir("$quantity_name.pdf"), fig)
end