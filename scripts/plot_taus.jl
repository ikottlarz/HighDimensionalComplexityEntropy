using DrWatson
@quickactivate
include(scriptsdir("standard_plot_generation.jl"))

quantity_name = "τs"
quantity = τs

inset_kwargs = (
    lower_left=[0.01, 0.01],
    upper_right=[0.45, 0.45]
)

inset_xlims = Dict(
    "lorenz_96" => (low=0.96, high=1.005),
    "generalized_henon" => (low=0.985, high=1.005),
    "mackey_glass" => (low=0.96, high=1.005),
    "kuramoto_sivashinsky" => (low=0.96, high=1.005),
)
inset_ylims = Dict(
    "lorenz_96" => (low=-0.005, high=0.05),
    "generalized_henon" => (low=-0.005, high=0.035),
    "mackey_glass" => (low=-0.005, high=0.05),
    "kuramoto_sivashinsky" => (low=-0.005, high=0.05),
)

inset = true

@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure(
    ;
    cbar_label=cbar_labels[quantity_name],
    cbar_limits=fix_quantities_for_plot[
        single_iterator_names[quantity_name]
    ]["limits"],
    quantity=single_iterator_names[quantity_name]
)
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    fix_qs_copy = copy(fixed_quantities["functions"])
    delete!(fix_qs_copy, single_iterator_names[quantity_name])

    @unpack originals, ft_surrogates, aaft_surrogates = data[system_name]
    filtered_originals = subset(
        originals,
        fix_qs_copy...
    )
    filtered_ft_surrogates = subset(
        ft_surrogates,
        fix_qs_copy...
    )
    filtered_aaft_surrogates = subset(
        aaft_surrogates,
        fix_qs_copy...
    )
    plot_system!(
        system_ax,
        filtered_originals,
        filtered_surrogates,
        filtered_aaft_surrogates,
        "τs",
        inset,
        inset_xlims[system_name],
        inset_ylims[system_name],
        inset_kwargs
    )
end
wsave(plotsdir("$quantity_name.pdf"), fig)