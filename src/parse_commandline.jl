using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--system"
            help = "which system to do the calculations for"
            required = true
        "--env"
            help = "which config environment to use"
            default = "base"
    end
    parsed_args = parse_args(s)
    return (system = parsed_args["system"], env = parsed_args["env"])
end