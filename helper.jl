
using Plots
using YAML
using Pkg
using DataFrames
#using Combinatorics
using IterTools
using JLD2
using FileIO

include("./fictitious_play.jl")

function save_res(name,tup)
    @save name tup
end


function load_res(name::String)
    # Load the named tuple from the file
    data = JLD2.load(name, "res")
    return data
end


function get_B(Β_min::Float64,Β_max::Float64,Β_step::Float64)::Vector{Float64}
    return collect(Β_min:Β_step:Β_max)
end

function get_scenario_description_type(xp_index::Int64)::String
    XP =  get_data(xp_index)
    ret = XP["scenario_description_type"]
    if ret == "explicit" || ret == "implicit"
        return ret
    else

        error("scenario_description_type is not well defined")
    end
end

function get_input_from_YAML_explicite(xp_index::Int64
    )::Tuple{Vector{Float64},Vector{Vector{Int}},Vector{Float64},Vector{Float64},Int64,Bool}
    XP = get_data(xp_index)
    agent_values = float(XP["agent_values"])  # Convert to float
    Β = get_B(XP["B_min"],XP["B_max"], XP["B_step"])
    n_iter = Int(XP["n_iter"])
    scenarios = XP["scenarios"]
    scenarios_proba = XP["scenarios_proba"]
    with_tight = Bool(XP["with_tight"])
    return agent_values,scenarios,scenarios_proba,Β,n_iter,with_tight
end

function  get_agent_factorized(agent_values::Vector{Vector{Float64}})::Vector{Vector{Int}}
    c = 1    
    ret = []
    for i in 1:length(agent_values)
        agents_i = [collect(c:(c+length(agent_values[i])-1))]
        c += (length(agent_values[i]))
        ret = vcat(ret,agents_i)
    end
    return ret
end

function get_values_scenario_proba_from_values_function(agent_values::Vector{Vector{Float64}},proba_function::Function
    )::Tuple{Vector{Float64},Vector{Vector{Int}},Vector{Float64}}
    agents_factorized = get_agent_factorized(agent_values)
    scenario_agents = collect([collect(a) for a in IterTools.product(agents_factorized...)])[:]
    scenarios_vals = collect(IterTools.product(agent_values...))[:]
    proba = (arg1, arg2) ->  Base.invokelatest(proba_function, arg1, arg2)
    scenarios_probas = [proba(val...) for val in scenarios_vals][:]
    scenarios_probas = scenarios_probas/sum(scenarios_probas)
    return vcat(agent_values...),scenario_agents,scenarios_probas
end

function  get_data(xp_index::Int64)
    data = YAML.load_file("experiments_parameters.yaml")
    return data[findfirst(x -> x["ID"] == xp_index, data)]
    
end

function get_input_from_YAML_implicit(xp_index::Int64
    )::Tuple{Vector{Float64},Vector{Vector{Int}},Vector{Float64},Vector{Float64},Int64,Bool}
    XP = get_data(xp_index)
    values_per_player_string = XP["values_per_player"]
    values_per_player = eval(Meta.parse(values_per_player_string))
    proba_function_string = XP["proba_function"]
    proba_function = eval(Meta.parse(proba_function_string))
    agent_values,scenarii,proba= get_values_scenario_proba_from_values_function(values_per_player,proba_function)
    Β = get_B(XP["B_min"],XP["B_max"], XP["B_step"])
    n_iter = Int(XP["n_iter"])
    with_tight = Bool(XP["with_tight"])
    return agent_values,scenarii,proba,Β,n_iter,with_tight
end


function get_input_from_YAML(xp_index::Int64)::Tuple{Vector{Float64},Vector{Vector{Int}},Vector{Float64},Vector{Float64},Int64,Bool}
    description_type = get_scenario_description_type(xp_index)
    if description_type == "explicit"
        return get_input_from_YAML_explicite(xp_index)
    else
        return get_input_from_YAML_implicit(xp_index)
    end
end

function run_xp(xp_index::Int64)::@NamedTuple{parameters::Dict{Any, Any}, epsilon::Vector{Float64}, histo::Vector{Vector{Float64}}, beta::Vector{Float64}} 
    agent_values,scenarios,scenarios_proba,Β,n_iter,with_tight = get_input_from_YAML(xp_index)
    histo,epsilon = fictitious_play(agent_values,scenarios,scenarios_proba,Β,n_iter,with_tight)
    data = YAML.load_file("experiments_parameters.yaml")
    XP = get_data(xp_index)
    res = (parameters = XP,epsilon =  epsilon,  histo = histo,beta= Β)  
    return res
end
