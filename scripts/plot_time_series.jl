using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))

set_theme!(
    Theme(
        colormap=:hawaii,
        markersize=25,
        fontsize=30,
        Axis = (
            titlefont = projectdir("cmu/cmunbx.ttf"),
            xlabelfont=projectdir("cmu/cmunrm.ttf"),
            ylabelfont=projectdir("cmu/cmunrm.ttf"),
            xticklabelfont=projectdir("cmu/cmunrm.ttf"),
            yticklabelfont=projectdir("cmu/cmunrm.ttf"),
            yticklabelsize=25,
            xticklabelsize=25,
            xgridvisible = false,
            ygridvisible = false,
            viewmode=:fitzoom
        ),
        Legend = (
            labelfont=projectdir("cmu/cmunrm.ttf"),
            labelsize=25
        )
    )
)

hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

ky_dim = 43

fig = Figure(
    resolution=(800, 900),
)

lorenz_96 = Axis(fig[1:3, 1:10]; title="Lorenz-96", ylabel=L"x_1(t)")
generalized_henon = Axis(fig[4:6, 1:10]; title="Generalized Hénon", ylabel=L"x_1(t)")
mackey_glass = Axis(fig[7:9, 1:10]; title="Mackey-Glass", ylabel=L"x(t)", yticks=[0.25, 0.75, 1.25])
kuramoto_sivashinsky = Axis(fig[10:12, 1:10]; title="Kuramoto-Sivashinsky", ylabel=L"y(t; x=0)", xlabel=L"system time $t$")
la = fig[14, 1:9] = GridLayout()
axes = @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)

markers = [:circle, :dtriangle, :utriangle, :cross, :xcross, :diamond]
linestyles = [:solid, :dash, :dot, :dashdot, :solid, :dash]

for system in ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"]
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
    ts = data[isapprox.(data.ky_dim, ky_dim, atol=.5), :trajectory][1][1:450]
    Δt = nothing
    try
        @unpack Δt = simulation_parameters
    catch exception
        # for gen. Henon no Δt
        println(system)
        println(exception)
        Δt = 1
    end

    ax = axes[system]

    lines!(ax,
        Δt:Δt:450Δt,
        ts;
        color=:gray40,
        linewidth=3
    )
    lags = [1, 2, 7, 15, 25, 50]
    for (i, τ) in enumerate(lags)
        st = cumsum(lags)[i] * 3 + 20
        lines!(ax,
            Δt*(st:τ:(st+3τ-1)),
            ts[st:τ:(st+3τ-1)];
            color=:black,
            linewidth=4,
            grid=false
        )
        lines!(ax,
            Δt*(st:τ:(st+3τ-1)),
            ts[st:τ:(st+3τ-1)];
            color=[τ, τ, τ],
            colormap=:hawaii,
            colorrange=(1, 50),
            linewidth=3,
            grid=false
        )

        scatter!(ax,
            Δt*(st:τ:(st+3τ-1)),
            ts[st:τ:(st+3τ-1)];
            color=ones(3)*τ,
            marker=markers[i],
            colormap=:hawaii,
            colorrange=(1, 50),
            strokecolor=:black, strokewidth=1,
            grid=false
        )
        xlims!(ax, (low=0, high=451Δt))
    end
end

legend_markers = [
    MarkerElement(;
        marker=markers[i],
        color=cgrad(:hawaii)[Int(ceil(τ/50*256))],
        strokecolor=:black,
        strokewidth=1
    )
    for (i, τ) in enumerate([1, 2, 7, 15, 25, 50])
]
legend_labels = [L"l = %$τ \delta t" for τ in [1, 2, 7, 15, 25, 50]]
Legend(
    la[1, 1],
    legend_markers,
    legend_labels;
    nbanks=6
)
rowgap!(fig.layout, 0)

fig
safesave(plotsdir("example_time_series.pdf"), fig)