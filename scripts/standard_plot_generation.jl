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
    lines!(ax, [xlims[1], xlims[1]], [ylims[1], ylims[2]]; color=:black, linewidth, overdraw=true)
    lines!(ax, [xlims[1], xlims[2]], [ylims[1], ylims[1]]; color=:black, linewidth, overdraw=true)
    lines!(ax, [xlims[1], xlims[2]], [ylims[2], ylims[2]]; color=:black, linewidth, overdraw=true)
    lines!(ax, [xlims[2], xlims[2]], [ylims[1], ylims[2]]; color=:black, linewidth, overdraw=true)
end

function inset_ax!(ax::Axis, xlims::NamedTuple, ylims::NamedTuple, lower_left::Vector{Float64}, upper_right::Vector{Float64})

    bbox = lift(ax.scene.camera.projectionview, ax.scene.px_area) do _, pxa
        bl = Makie.project(ax.scene, Point2f(lower_left...)) + pxa.origin
        tr = Makie.project(ax.scene, Point2f(upper_right...)) + pxa.origin
        Rect2f(bl, tr - bl)
    end

    # inset
    ins_ax = Axis(fig, bbox = bbox)
    translate!(ins_ax.blockscene, 0, 0, 100)
    xlims!(ins_ax; xlims...)
    ylims!(ins_ax, ylims...)
    hidedecorations!(ins_ax)

    lines!(ax, [xlims[:high], upper_right[1]], [ylims[:low], lower_left[2]], color=:black)
    lines!(ax, [xlims[:high], upper_right[1]], [ylims[:high], upper_right[2]], color=:black)
    return ins_ax
end

function standard_figure(;
    cbar_label,
    cbar_limits::Tuple,
    quantity::Symbol)
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
    iterator_quantity_name::String,
    inset::Bool,
    inset_xlims=nothing,
    inset_ylims=nothing,
    inset_kwargs=nothing)
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
        @unpack lower_left, upper_right = inset_kwargs
        x_l, y_l = lower_left
        x_h, y_h = upper_right
        ins = inset_ax!(
            ax,
            inset_xlims,
            inset_ylims,
            [min_h+x_l*h_span, min_c+y_l*c_span],
            [max_h-x_h*h_span, max_c-y_h*c_span])
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
        box!(ax, inset_xlims, inset_ylims)
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
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

data = Dict{String, NamedTuple}()
for system in systems
    system_config = system_configs[system]
    @unpack analysis_config = system_config
    @unpack num_surrogates, τs, ms, lengths, dims, prefix, simulation_parameters = analysis_config
    original_file, _ = produce_or_load(complexity_entropy, analysis_config, datadir("analysis"); filename=hash, prefix)
    # generate phase randomized surrogates
    ft_sur_config = (analysis_config..., surrogate_func=RandomFourier(true))
    @show ft_sur_config
    @show hash(ft_sur_config)
    ft_surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, ft_sur_config, datadir("analysis"); filename=hash, prefix="$(prefix)_ft_surrogates")
    aaft_sur_config = (analysis_config..., surrogate_func=AAFT())
    aaft_surrogate_file, _ = produce_or_load(surrogate_complexity_entropy, aaft_sur_config, datadir("analysis"); filename=hash, prefix="$(prefix)_aaft_surrogates")
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