using Plots
using YAML
using Pkg
using DataFrames
using Combinatorics
using IterTools
using Base.Threads
using ProgressMeter

function get_payoff_for_bid(agent::Int64,value::Float64,bid::Float64,bid_index::Int64,histo::Vector{Vector{Float64}},scenarios::Vector{Vector{Int}},scenarios_proba::Vector{Float64})::Float64
    pwin_total::Float64 = 0.0
    p_scenario_total::Float64 = 0.0
    for (scenario,proba) in zip(scenarios,scenarios_proba)
            if agent in scenario
                p_scenario_total = p_scenario_total + proba
                pwin_scenario =  prod([sum(histo[competitor][1:(bid_index-1)]) for competitor in filter(x -> x != agent, scenario)])
                pwin_total    = pwin_total      +  pwin_scenario*proba
                
            end
    end
    return (value-bid)*pwin_total/p_scenario_total
end

function get_payoff_vector(agent::Int64,value::Float64,histo::Vector{Vector{Float64}},scenarios::Vector{Vector{Int}},scenarios_proba::Vector{Float64},Β::Vector{Float64})::Vector{Float64}
    return [get_payoff_for_bid(agent,value,Β[i],i,histo,scenarios,scenarios_proba) for i in 1:length(Β)]
end

function get_agent_best_reply(agent::Int64,value::Float64,histo::Vector{Vector{Float64}},scenarios::Vector{Vector{Int}},scenarios_proba::Vector{Float64},Β::Vector{Float64})::Tuple{Int64,Float64}
    payoff_vectors = get_payoff_vector(agent,value,histo,scenarios,scenarios_proba,Β) 
    best_reply = argmax(payoff_vectors)
    agent_historical_distribution = histo[agent]
    normalized_agent_historical_distribution = agent_historical_distribution/sum(agent_historical_distribution)
    payoff_historical_distribution = sum(payoff_vectors.*normalized_agent_historical_distribution)
    epsilon = payoff_vectors[best_reply] - payoff_historical_distribution
    return best_reply, epsilon
end

function one_step_fictitous_play(
    agent_values::Vector{Float64},
    scenarios::Vector{Vector{Int}},
    scenarios_proba:: Vector{Float64},
    Β::Vector{Float64},
    histo::Vector{Vector{Float64}},
)::Tuple{Vector{Vector{Float64}},Vector{Float64}}
    normalized_histograms = [histo[i]/sum(histo[i]) for i in 1:length(agent_values)]
    
    #best_replies = [get_agent_best_reply(agent,value,normalized_histograms,scenarios,scenarios_proba,Β,with_tight) for (agent, value) in enumerate(agent_values)]
    best_replies = fetch.(Threads.@spawn get_agent_best_reply(agent,value,normalized_histograms,scenarios,scenarios_proba,Β) for (agent, value) in enumerate(agent_values))
    new_histo = [zeros(length(Β)) for i = 1:length(agent_values)]
   for (agent, (best_bid, _)) in enumerate(best_replies)
        new_histo[agent][best_bid] += 1.0
    end
    epsilons = [epsilon for (_, epsilon) in best_replies]
        
    new_histo .= 1. .* histo .+ new_histo
    
    return new_histo, epsilons
end

function initialize_agent_histogram(Β::Vector{Float64})::Vector{Float64}
    nbid = length(Β)
    ret =  zeros(nbid) 
    ret[1]=.1
    return ret
end

function initialize_all_agent_histogram(agent_values::Vector{Float64},Β::Vector{Float64})::Vector{Vector{Float64}}
    return [initialize_agent_histogram(Β) for i in 1:length(agent_values)]
end

function fictitious_play(agent_values::Vector{Float64},
    scenarios::Vector{Vector{Int}},
    scenarios_proba:: Vector{Float64},
    Β::Vector{Float64},
    niter::Int64,;
    histo = initialize_all_agent_histogram(agent_values,Β)
    )::Tuple{Vector{Vector{Float64}},Vector{Float64}}
    ret_epsilon = Float64[]
    epsilons = zeros(niter)
    @showprogress for i in 1:niter
        histo,epsilons = one_step_fictitous_play(agent_values,scenarios,scenarios_proba,Β,histo)
        push!(ret_epsilon,maximum(epsilons))
    end

    return histo, ret_epsilon
end

