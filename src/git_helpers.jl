using DrWatson
@quickactivate

"""
    function last_modifying_commit(filenames...) -> githash

This function goes through all modifying commits of a list of filenames
and returns the hash of the last modifying commit.
Manifest.toml and Project.toml are added to the list of filenames,
because they document the package versions used.
"""
function last_modifying_commit(filenames...)
    # make filenames mutable
    filenames_list = [filenames...]
    # add versioning files to list of filenames
    push!(filenames_list, projectdir("Manifest.toml"))
    push!(filenames_list, projectdir("Project.toml"))
    # get git log for list of files
    commits = readlines(`git log $(filename for filename in filenames_list)`)
    # the commits are ordered descendingly wrt time.
    # the last commit hash is thus the first string in the list
    # it is formated as "commit <commit-hash>, thus we split it
    # at the space to get the hash
    last_hash = split(commits[1])[2]
    return last_hash
end