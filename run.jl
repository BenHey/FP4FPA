#!/usr/bin/env julia
using Revise
using ArgParse
using FilePathsBase
using FileIO
using Plots
includet("./fictitious_play.jl")
includet("./helper.jl")
###############################################################################
# Parse command line
###############################################################################
function parse_cmd()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--niter"
            help = "number of iterations"
            arg_type = Int
            default = 10^4

        "--agent_values"
            help = "agent values, e.g. 0,1,0,1"
            arg_type = String
            default = "0,1,0,1"

        "--scenarios"
            help = "scenarios, e.g. 1-3;1-4;2-3;2-4"
            arg_type = String
            default = "1-3;1-4;2-3;2-4"

        "--B_step"
            help = "step size for B grid"
            arg_type = Float64
            default = 1/400
        "--scaling"
            help = "scaling "
            arg_type = Float64
            default = 1.0
    end

    return parse_args(s)
end

###############################################################################
# Helpers to convert strings → vectors
###############################################################################
parse_vec_float(s) = parse.(Float64, split(s, ","))
parse_vec_int_vec(s) = [parse.(Int, split(block, "-")) for block in split(s, ";")]

###############################################################################
# Main
###############################################################################
function main()
    args = parse_cmd()

    # Convert parameters
    agent_values = parse_vec_float(args["agent_values"])
    scenarios = parse_vec_int_vec(args["scenarios"])
    scenarios_proba = fill(1.0/length(scenarios), length(scenarios))
    niter = args["niter"]
    B_step = args["B_step"]
    scaling = args["scaling"]

    # Build B
    B = get_B(0.0, 1.0, B_step)

    # Build a title-safe string for the folder
    title = "agent_values=$(agent_values)-scenarios=$(scenarios)"

    # Directory where images will be saved
    out_dir = "images/$(title)"
    isdir(out_dir) || mkpath(out_dir)

    # Run simulation
    histo, ret_epsilon = fictitious_play(
        agent_values,
        scenarios,
        scenarios_proba,
        B,
        niter
    )

    # Density
    policy_density = [h ./ sum(h) for h in histo]

    # Plot for each agent
    for agent in 1:length(agent_values)
        payoff = get_payoff_vector(
            agent,
            agent_values[agent],
            policy_density,
            scenarios,
            scenarios_proba,
            B
        )

        factor = maximum(policy_density[agent]) / maximum(payoff)

        plt = plot(B, policy_density[agent], label = "policy density", title = "agent=$agent", ylims=(-0.02, Inf))
        plot!(plt, B, payoff*scaling, label = "scaled payoff")

        savefig(joinpath(out_dir, "agent=$(agent).png"))
    end
end

main()
