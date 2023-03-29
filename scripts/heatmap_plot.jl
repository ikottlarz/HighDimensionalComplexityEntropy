using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))
include(scriptsdir("calc_significances.jl"))

struct SignificanceTicks end

# we need this custom function to make our colorbar tick labels
function Makie.get_ticks(::SignificanceTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals_h = [0, 1]
    labels = [val > 0.5 ? L"significant $ $" : L"not significant $ $" for val in vals_h]

    vals_h, labels
end

struct MTicks end

# we need this custom function to make our m tick labels
function Makie.get_ticks(::MTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals_h = collect(1:length(ms))
    labels = [L"%$(m)" for m in ms]

    vals_h, labels
end

struct XTicks end

# we need this custom function to make our m tick labels
function Makie.get_ticks(::XTicks, any_scale, ::Makie.Automatic, vmin, vmax)
    vals_h = collect(5:5:length(τs))
    labels = [L"%$(m)" for m in τs[5:5:end]]

    vals_h, labels
end

function heatmap_figure()
    set_theme!(
        Theme(
            colormap=:hawaii,
            markersize=20,
            fontsize=32,
        )
    )
    fig = Figure(resolution=(800, 900))
    ga = fig[1:4, 2:5] = GridLayout()
    ca = fig[1:4, 6] = GridLayout()
    lor_a = ga[1, 1] = GridLayout()
    hen_a = ga[2, 1] = GridLayout()
    mg_a = ga[3, 1] = GridLayout()
    ks_a = ga[4, 1] = GridLayout()
    xlabel = L"lag [$\delta t$]"
    ylabel = L"pattern length $ $"
    xticks = XTicks()
    yticks = MTicks()
    lorenz_96 = Axis(lor_a[1, 1], title=L"Lorenz-96 $ $"; xticks, yticks)
    generalized_henon = Axis(hen_a[1, 1], title=L"Generalized Henon $ $"; xticks, yticks)
    mackey_glass = Axis(mg_a[1, 1], title=L"Mackey-Glass $ $"; xticks, yticks)
    kuramoto_sivashinsky = Axis(ks_a[1, 1], title=L"Kuramoto-Sivashinsky $ $"; xticks, yticks, xlabel)
    linkaxes!(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

    Label(fig[1:4, 1], ylabel, rotation=pi/2)

    Colorbar(
        ca[1, 1], colormap=cgrad(:hawaii, 2, categorical = true),
        vertical=true, label = L"significance $ $", limits=(-.5, 1.5),
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

# hard coded bc part of the files are not produced with this git repo!!!
hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

ky_dim = 43
data_length = 10^6
@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = heatmap_figure()
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    @unpack analysis_config = system_configs[system_name]
    @unpack prefix = analysis_config
    @show system_name
    file, _ = produce_or_load(significance_heatmap, system_configs[system_name], datadir("analysis"); filename=hash, prefix="$(system_name)_significances")
    data = file["data"]
    ky_dims = wload(datadir("analysis/$(prefix)_ky_dims_$(hashes[prefix]).jld2"))
    ky_data = ky_dims["data"]
    joined = outerjoin(
            data["ft_heatmaps"],
            ky_data,
            on=:dim)
    heatmap_matrices = joined[
        (isapprox.(joined.ky_dim, ky_dim, atol=.5)) .&
        (joined.data_length .== data_length),
        :heatmap
    ]
    @assert length(heatmap_matrices) == 1
    heatmap!(
        system_ax,
        (heatmap_matrices[1] .< 0.05)',
        colorrange=(0, 1)
    )

end
safesave(plotsdir("significance_heatmap_ft.pdf"), fig)

@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = heatmap_figure()
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    @unpack analysis_config = system_configs[system_name]
    @unpack prefix = analysis_config
    @show system_name
    file, _ = produce_or_load(significance_heatmap, system_configs[system_name], datadir("analysis"); filename=hash, prefix="$(system_name)_significances")
    data = file["data"]
    ky_dims = wload(datadir("analysis/$(prefix)_ky_dims_$(hashes[prefix]).jld2"))
    ky_data = ky_dims["data"]
    joined = outerjoin(
            data["aaft_heatmaps"],
            ky_data,
            on=:dim)
    heatmap_matrices = joined[
        (isapprox.(joined.ky_dim, ky_dim, atol=.5)) .&
        (joined.data_length .== data_length),
        :heatmap
    ]
    @assert length(heatmap_matrices) == 1
    heatmap!(
        system_ax,
        (heatmap_matrices[1] .< 0.05)',
        colorrange=(0, 1)
    )

end
safesave(plotsdir("significance_heatmap_aaft.pdf"), fig)