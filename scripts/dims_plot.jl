using DrWatson
@quickactivate
include(scriptsdir("standard_plot_generation.jl"))

quantity_name = "dims"
quantity = dims

inset_kwargs = (
    width=Relative(0.45),
    height=Relative(0.45),
    halign=0.15,
    valign=0.1,
    backgroundcolor=:white,
    xgridcolor=:gray35,
    ygridcolor=:gray35,
    xticklabelsize=20,
    yticklabelsize=20,
    xticks=[.98, .99, 1.0]
)
inset_xlims_lorenz = (low=0.97, high=.985)
inset_ylims_lorenz = (low=0.04, high=0.065)

inset_xlims_henon = (low=0.995, high=1.00)
inset_ylims_henon = (low=0.003, high=0.006)

inset_xlims_mg = (low=0.97, high=.985)
inset_ylims_mg = (low=0.04, high=0.06)

inset_xlims_ksiva = (low=0.985, high=1.00)
inset_ylims_ksiva = (low=0.01, high=0.03)

inset = true

@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure(
    ;
    cbar_label=cbar_labels[quantity_name],
    cbar_limits=fix_quantities_for_plot[
        single_iterator_names[quantity_name]
    ]["limits"],
    quantity=single_iterator_names[quantity_name],
    inset
)
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    @show system_name
    fix_qs_copy = copy(fixed_quantities["functions"])
    delete!(fix_qs_copy, :ky_dim)
    if system_name == "generalized_henon"
        fix_qs_copy[:τ] = τ -> τ .== 1
    end
    @unpack originals, surrogates = data[system_name]
    filtered_originals = subset(
        originals,
        fix_qs_copy...
    )
    filtered_surrogates = subset(
        surrogates,
        fix_qs_copy...
    )
    if system_name == "lorenz_96"
        @show filtered_surrogates[:, [:ky_dim, :entropy, :complexity]]
    end
    plot_system!(
        system_ax,
        filtered_originals,
        filtered_surrogates,
        quantity,
        "dims",
        inset
    )
end

# draw inset boxes manually
@unpack ax = lorenz_96
lorenz_96 = ax
@unpack ax = generalized_henon
generalized_henon = ax
@unpack ax = mackey_glass
mackey_glass = ax
@unpack ax = kuramoto_sivashinsky
kuramoto_sivashinsky = ax
box!(lorenz_96, inset_xlims_lorenz, inset_ylims_lorenz)
box!(generalized_henon, inset_xlims_henon, inset_ylims_henon)
box!(mackey_glass, inset_xlims_mg, inset_ylims_mg)
box!(kuramoto_sivashinsky, inset_xlims_ksiva, inset_ylims_ksiva)
wsave(plotsdir("$quantity_name.pdf"), fig)