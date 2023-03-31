using DrWatson
@quickactivate

using CairoMakie

include(projectdir("configs/base.jl"))

# hard coded bc part of the files are not produced with this git repo!!!
hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

set_theme!(
        Theme(
            markersize=15,
            fontsize=32,
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

fig = Figure(resolution=(1600, 600))
ky_layout = fig[1:4, 2:9] = GridLayout()
lyap_layout = fig[5:8, 2:9] = GridLayout()

Label(fig[1:4, 1], L"\Delta^{(KY)}"; rotation=pi/2)
Label(fig[5:8, 1], L"\lambda_j"; rotation=pi/2)
ky_axes = Axis[]

system_names = Dict(
        "lorenz_96"=>"Lorenz-96",
        "generalized_henon"=>"Generalized Hénon",
        "mackey_glass"=>"Mackey-Glass",
        "kuramoto_sivashinsky"=>"Kuramoto-Sivashinsky"
    )

for (i, system) in enumerate( ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"])
    system_config = system_configs[system]
    @unpack analysis_config = system_config
    @unpack prefix = analysis_config
    ky_dims = wload(datadir("analysis/$(prefix)_ky_dims_$(hashes[prefix]).jld2"))
    ky_data = ky_dims["data"]

    ky_ax = Axis(ky_layout[1, i]; title=system_names[system])
    push!(ky_axes, ky_ax)

    scatter!(ky_ax, ky_data[:, :dim], ky_data[:, :ky_dim]; color=:red, marker=:diamond)
    if system == "generalized_henon"

        lims = Observable(((-2.755, -2.7), (0, 0.15)))
        g = lyap_layout[1, i] = GridLayout()

        ax_top = Axis(g[1, 1])
        ax_bottom = Axis(g[2, 1]; yticks=[-2.75])

        on(lims) do (bottom, top)
            ylims!(ax_bottom, bottom)
            ylims!(ax_top, top)
            rowsize!(g, 1, Auto(top[2] - top[1]))
            rowsize!(g, 2, Auto(bottom[2] - bottom[1]))
        end

        hidexdecorations!(ax_top, grid = false)
        ax_top.bottomspinevisible = false
        ax_bottom.topspinevisible = false

        linkxaxes!(ax_top, ax_bottom)
        rowgap!(g, 10)

        angle = pi/8
        linelength = 15

        segments = lift(
                @lift($(ax_top.yaxis.attributes.endpoints)[1]),
                @lift($(ax_bottom.yaxis.attributes.endpoints)[2]),
                @lift($(ax_top.yaxis.attributes.endpoints)[1]),
                @lift($(ax_bottom.yaxis.attributes.endpoints)[2]),
            ) do p1, p2, p3, p4
            ps = Point2f[p1, p2, p3, p4]
            ps[3] += Point2f(295, 0)
            ps[4] += Point2f(295, 0)

            map(ps) do p
                a = p + Point2f(cos(angle), sin(angle)) * 0.5 * linelength
                b = p - Point2f(cos(angle), sin(angle)) * 0.5 * linelength
                (a, b)
            end
        end

        linesegments!(fig.scene, segments)

        for (dim, λs) in zip(ky_data[:, :dim], ky_data[:, :lyapunov_spectrum])
            scatter!(ax_top, ones(length(λs))*dim, λs, marker=:circle, color=:black, markersize=5)
            scatter!(ax_bottom, ones(length(λs))*dim, λs, marker=:circle, color=:black, markersize=5)
        end

        notify(lims)
    else
        lyap_ax = Axis(lyap_layout[1, i])

        linkxaxes!(ky_ax, lyap_ax)
        try
            for (dim, λs) in zip(ky_data[:, :dim], ky_data[:, :λs])
                scatter!(lyap_ax, ones(length(λs))*dim, λs, marker=:circle, color=:black, markersize=5)
            end
        catch error
            println(error)
            for (dim, λs) in zip(ky_data[:, :dim], ky_data[:, :lyapunov_spectrum])
                scatter!(lyap_ax, ones(length(λs))*dim, λs, marker=:circle, color=:black, markersize=5)
            end
        end
    end
end
linkyaxes!(ky_axes...)
fig
safesave(plotsdir("ky_dims.eps"), fig)
