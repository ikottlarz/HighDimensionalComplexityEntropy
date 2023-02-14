using DrWatson
@quickactivate

using ComplexityMeasures
using CairoMakie

include(projectdir("configs/base.jl"))
include(srcdir("min_max_complexity_entropy.jl"))

function box!(ax::Axis, xlims::NamedTuple, ylims::NamedTuple)
    @unpack low, high = xlims
    xlims = [low, high]
    @unpack low, high = ylims
    ylims = [low, high]
    linewidth = 3
    lines!(ax, [xlims[1], xlims[1]], [ylims[1], ylims[2]]; color=:black, linewidth)
    lines!(ax, [xlims[1], xlims[2]], [ylims[1], ylims[1]]; color=:black, linewidth)
    lines!(ax, [xlims[1], xlims[2]], [ylims[2], ylims[2]]; color=:black, linewidth)
    lines!(ax, [xlims[2], xlims[2]], [ylims[1], ylims[2]]; color=:black, linewidth)
end

function standard_figure(;
    cbar_label,
    cbar_limits::Tuple,
    quantity::Symbol,
    inset::Bool)
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20,
            fontsize=27,
            Axis = (
                titlefont = projectdir("cmu/cmunrm.ttf"),
                xlabelfont=projectdir("cmu/cmunrm.ttf"),
                ylabelfont=projectdir("cmu/cmunrm.ttf"),
                xticklabelfont=projectdir("cmu/cmunrm.ttf"),
                yticklabelfont=projectdir("cmu/cmunrm.ttf"),
            )
        )
    )
    # copy info dict and delete fix value of quantity that will
    # be iterated in this plot
    info_dict = copy(fixed_quantities["values"])
    delete!(info_dict, quantity)

    fig = Figure(
        resolution=(800, 900),
        )
    ga = fig[1:8, 2:3] = GridLayout()
    ca = fig[10, 2] = GridLayout()
    la = fig[10, 3] = GridLayout()
    ylabel = L"complexity $C_{JS}$"
    xlabel = L"entropy $H_S$"
    lorenz_96 = Axis(ga[1, 1]; title="Lorenz-96")
    generalized_henon = Axis(ga[1, 2], title="Generalized Hénon")
    mackey_glass = Axis(ga[2, 1], title="Mackey-Glass")
    kuramoto_sivashinsky = Axis(ga[2, 2], title="Kuramoto-Sivashinsky")

    if inset
        lorenz_96_inset = Axis(
            ga[1, 1];
            inset_kwargs...
        )
        xlims!(lorenz_96_inset; inset_xlims_lorenz...)
        ylims!(lorenz_96_inset; inset_ylims_lorenz...)
        generalized_henon_inset = Axis(
            ga[1, 2];
            inset_kwargs...
        )
        xlims!(generalized_henon_inset; inset_xlims_henon...)
        ylims!(generalized_henon_inset; inset_ylims_henon...)
        box!(generalized_henon, inset_xlims_henon, inset_ylims_henon)
        mackey_glass_inset = Axis(
            ga[2, 1];
            inset_kwargs...
        )
        xlims!(mackey_glass_inset; inset_xlims_mg...)
        ylims!(mackey_glass_inset; inset_ylims_mg...)
        box!(mackey_glass, inset_xlims_mg, inset_ylims_mg)

        kuramoto_sivashinsky_inset = Axis(
            ga[2, 2];
            inset_kwargs...
        )
        xlims!(kuramoto_sivashinsky_inset; inset_xlims_ksiva...)
        ylims!(kuramoto_sivashinsky_inset; inset_ylims_ksiva...)
        box!(kuramoto_sivashinsky, inset_xlims_ksiva, inset_ylims_ksiva)

        for ax in [lorenz_96_inset, generalized_henon_inset, mackey_glass_inset, kuramoto_sivashinsky_inset]
            translate!(ax.blockscene, 0, 0, 10)
            translate!(ax.scene, 0, 0, 9)
            hidedecorations!(ax)
        end
    end
    Colorbar(
        ca[1, 1],
        limits=cbar_limits,
        vertical=false, label = cbar_label,
        flipaxis=false, ticklabelfont=projectdir("cmu/cmunrm.ttf")
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
    scale = fix_quantities_for_plot[
        single_iterator_names[
            iterator_quantity_name
        ]
    ]["scale"]
    crange = fix_quantities_for_plot[
        single_iterator_names[
            iterator_quantity_name
        ]
    ]["limits"]
    if iterator_quantity_name != "ms"
        est = ComplexityMeasures.SymbolicPermutation(; m=fixed_quantities["values"][:m]
        )
        h_min, c_min = minimum_complexity_entropy(est)
        h_max, c_max = maximum_complexity_entropy(est)
        lines!(ax, h_min, c_min, color=:black, linewidth=2)
        lines!(ax, h_max, c_max, color=:black, linewidth=2)
    end
    scatter!(
        ax,
        originals[:, :entropy], originals[:, :complexity],
        marker=:circle, color=scale.(originals[:,
        single_iterator_names[iterator_quantity_name]]),
        strokecolor=:black, strokewidth=0.5,
        colorrange=crange,
    )
    min_h = minimum([originals[:, :entropy]..., surrogates[:, :entropy]...])
    min_c = minimum([originals[:, :complexity]..., surrogates[:, :complexity]...])
    max_h = maximum([originals[:, :entropy]..., surrogates[:, :entropy]...])
    max_c = maximum([originals[:, :complexity]..., surrogates[:, :complexity]...])
    h_span = max_h-min_h
    c_span = max_c-min_c
    xlims!(ax; low=min_h-.1h_span, high=max_h+.1h_span)
    ylims!(ax; low=min_c-.1c_span, high=max_c+.1c_span)

    if inset
        scatter!(
            ins,
            originals[:, :entropy], originals[:, :complexity],
            marker=:circle,
            color=scale.(originals[:,
            single_iterator_names[iterator_quantity_name]]),
            strokecolor=:black, strokewidth=0.5,
            colorrange=crange,
        )
        if iterator_quantity_name != "ms"
            lines!(ins, h_min, c_min, color=:black, linewidth=2)
            lines!(ins, h_max, c_max, color=:black, linewidth=2)
        end
    end
    # for val in iterator_quantity
    #     val_surrogates = subset(
    #         surrogates,
    #         single_iterator_names[iterator_quantity_name] => x -> isapprox.(x, val, atol=.5)
    #     )
    scatter!(
        ax,
        surrogates[:, :entropy], surrogates[:, :complexity],
        color=scale.(surrogates[:, single_iterator_names[iterator_quantity_name]]), marker=:dtriangle,
        strokecolor=:black, strokewidth=0.5,
        colorrange=crange,
    )
    if inset
        scatter!(
            ins,
            surrogates[:, :entropy], surrogates[:, :complexity],
            color=scale.(surrogates[:, single_iterator_names[iterator_quantity_name]]),
            marker=:dtriangle,
            strokecolor=:black, strokewidth=0.5,
            colorrange=crange,
        )
    end
    # end
end

@unpack τs, ms, lengths = general_analysis_config
dims = 1:.1:50
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
        "limits" => (3, 6),
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
    "lengths" => L"log(data length) $ $",
    "ms" => L"pattern length $m$",
    "τs" => L"lag [$\delta t$]"
)

systems = [
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