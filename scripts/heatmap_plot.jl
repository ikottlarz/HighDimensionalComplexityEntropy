using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))
include(scriptsdir("calc_significances.jl"))

struct SignificanceTicks end

# we need this custom function to make our colorbar tick labels
function Makie.get_ticks(::SignificanceTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals_h = [0, 1]
    labels = [val > 0.5 ? "significant" : "not significant" for val in vals_h]

    vals_h, labels
end

struct MTicks end

# we need this custom function to make our m tick labels
function Makie.get_ticks(::MTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals_h = collect(1:length(ms))
    labels = string.(ms)

    vals_h, labels
end

function heatmap_figure(; xticks::Union{AbstractVector, UnitRange})
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20
        )
    )
    fig = Figure(resolution=(800, 900))
    ga = fig[1:4, 2:5] = GridLayout()
    ca = fig[1:4, 6] = GridLayout()
    lor_a = ga[1, 1] = GridLayout()
    hen_a = ga[2, 1] = GridLayout()
    mg_a = ga[3, 1] = GridLayout()
    ks_a = ga[4, 1] = GridLayout()
    xlabel = "lag [\$\\delta t\$]"
    ylabel = "pattern length"
    lorenz_96 = Axis(lor_a[1, 1], title="Lorenz-96"; xticks, yticks=MTicks())
    generalized_henon = Axis(hen_a[1, 1], title="Generalized Henon"; xticks, yticks=MTicks())
    mackey_glass = Axis(mg_a[1, 1], title="Mackey-Glass"; xticks, yticks=MTicks())
    kuramoto_sivashinsky = Axis(ks_a[1, 1], title="Kuramoto-Sivashinsky"; xticks, yticks=MTicks(), xlabel)
    linkaxes!(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

    for (label, layout) in zip(["A", "B", "C", "D"], [lor_a, hen_a, mg_a, ks_a])
        Label(layout[1, 1, TopLeft()], label,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end
    Label(fig[1:4, 1], ylabel, rotation=pi/2)

    Colorbar(
        ca[1, 1], colormap=cgrad(:hawaii, 2, categorical = true),
        vertical=true, label = "significance", limits=(-.5, 1.5),
        flipaxis=true, ticks=SignificanceTicks(), ticklabelrotation=pi/2
    )
    return (
        fig=fig,
        lorenz_96=lorenz_96,
        generalized_henon=generalized_henon,
        mackey_glass=mackey_glass,
        kuramoto_sivashinsky=kuramoto_sivashinsky
    )
end

@unpack τs, ms = general_analysis_config

dim = 38
data_length = 10^6
@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = heatmap_figure(; xticks = τs[5:5:end])
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    file, _ = produce_or_load(significance_heatmap, system_configs[system_name], datadir("analysis"); filename=hash, prefix="$(system_name)_significances")
    data = file["data"]
    heatmap_matrices = data[
        (data.dim .== dim) .&
        (data.data_length .== data_length),
        :heatmap
    ]
    @assert length(heatmap_matrices) == 1
    heatmap!(
        system_ax,
        (heatmap_matrices[1] .< 0.05)',
        colorrange=(0, 1)
    )

end
save(plotsdir("significance_heatmap.eps"), fig)