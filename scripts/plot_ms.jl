using DrWatson
@quickactivate
include(scriptsdir("standard_plot_generation.jl"))

quantity_name = "ms"
quantity = ms

inset = false

@unpack fig, lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky = standard_figure(
    ;
    cbar_label=cbar_labels[quantity_name],
    cbar_limits=fix_quantities_for_plot[
        single_iterator_names[quantity_name]
    ]["limits"],
    quantity=single_iterator_names[quantity_name],
)
for (system_name, system_ax) in @strdict(lorenz_96, generalized_henon, mackey_glass, kuramoto_sivashinsky)
    fix_qs_copy = copy(fixed_quantities["functions"])
    delete!(fix_qs_copy, single_iterator_names[quantity_name])
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
    plot_system!(
        system_ax,
        filtered_originals,
        filtered_surrogates,
        "ms",
        inset,
    )
end

wsave(plotsdir("$quantity_name.pdf"), fig)