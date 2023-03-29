using DrWatson
@quickactivate
include(projectdir("configs/base.jl"))
using TimeseriesSurrogates, Random
using CairoMakie, FFTW

set_theme!(
    Theme(
        markersize=20,
        fontsize=20,
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

# hard coded bc part of the files are not produced with this git repo!!!
hashes = Dict(
    "kuramoto_sivashinsky" => "2102259424389999364",
    "mackey_glass" => "686837168688022898",
    "lorenz96"=>"6585490124554813738",
    "generalized_henon"=>"14298432815589460241"
)

for system in ["lorenz_96", "generalized_henon", "mackey_glass", "kuramoto_sivashinsky"]
    @unpack analysis_config = system_configs[system]
    @unpack prefix, τs, ms, dims, lengths, num_surrogates, simulation_parameters, simulation_function = analysis_config
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
    ts = data[isapprox.(data.ky_dim, 43, atol=.5), :trajectory][1][1:10^6]
    rng = Xoshiro(1234)
    aaft_sur = surrogate(
        ts,
        AAFT(),
        rng
    )

    ft_sur = surrogate(
        ts,
        RandomFourier(true),
        rng
    )


    fig = Figure(; title="Lorenz-96 surrogates")
    ax1 = Axis(fig[1, 1]; title="example time series", ylabel="original signal")
    ax2 = Axis(fig[2, 1]; ylabel="AAFT surrogate")
    ax3 = Axis(fig[3, 1]; ylabel="FT surrogate")
    linkaxes!(ax1, ax2, ax3)
    t = 0.02:0.02:0.02*400
    lines!(ax1, t, ts[1:400]; color=:teal)
    lines!(ax2, t, aaft_sur[1:400]; color=:teal)
    lines!(ax3, t, ft_sur[1:400]; color=:teal)

    L = length(ts)
    freqs = fftfreq(L, 1/0.02)
    nbins = 100

    ax4 = Axis(fig[1, 2]; title="amplitude distribution")
    ax5 = Axis(fig[2, 2];)
    ax6 = Axis(fig[3, 2];)
    linkaxes!(ax4, ax5, ax6)
    hist!(ax4, ts; color=:maroon, bins=nbins)
    hist!(ax5, aaft_sur; color=:maroon, bins=nbins)
    hist!(ax6, ft_sur; color=:maroon, bins=nbins)

    ax7 = Axis(fig[1, 3]; title="power spectrum", xscale=log10, yscale=log10)
    ax8 = Axis(fig[2, 3]; xscale=log10, yscale=log10)
    ax9 = Axis(fig[3, 3]; xscale=log10, yscale=log10)
    linkaxes!(ax7, ax8, ax8)
    lines!(ax7, freqs[2:Int(L/2)], abs.(fft(ts)[2:Int(L/2)]).^2; color=:darkgreen, bins=nbins)
    lines!(ax8, freqs[2:Int(L/2)], abs.(fft(aaft_sur)[2:Int(L/2)]).^2; color=:darkgreen, bins=nbins)
    lines!(ax9, freqs[2:Int(L/2)], abs.(fft(ft_sur)[2:Int(L/2)]).^2; color=:darkgreen, bins=nbins)

    safesave(plotsdir("surrogate_inspection_$system.png"), fig)
end