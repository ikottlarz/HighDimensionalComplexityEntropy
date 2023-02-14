using DrWatson
@quickactivate
include(scriptsdir("standard_plot_generation.jl"))

quantity_name = "τs"
quantity = τs

inset_kwargs = (
    width=Relative(0.4),
    height=Relative(0.4),
    halign=0.25,
    valign=0.25,
    backgroundcolor=:white,
    xgridcolor=:gray35,
    ygridcolor=:gray35,
    xticklabelsize=20,
    yticklabelsize=20,
    xticks=[.98, .99, 1.0]
)
inset_xlims_lorenz = (low=0.96, high=1.005)
inset_ylims_lorenz = (low=-0.005, high=0.05)

inset_xlims_henon = (low=0.985, high=1.005)
inset_ylims_henon = (low=-0.005, high=0.035)

inset_xlims_mg = (low=0.96, high=1.005)
inset_ylims_mg = (low=-0.005, high=0.05)

inset_xlims_ksiva = (low=0.96, high=1.005)
inset_ylims_ksiva = (low=-0.005, high=0.05)

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