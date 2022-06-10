"""
$(TYPEDSIGNATURES)
"""
function get_agent_data(agent::AbstractPropDict, model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType}}, props = agent.keeps_record_of) where T<:MType
    datadict=Dict{Symbol,Any}()
    uptick = agent._extras._death_time == Inf ? model.tick+1 : agent._extras._death_time+1
    downtick = agent._extras._birth_time-1
    for key in props
        datadict[key] = vcat(fill(missing, downtick),unwrap_data(agent)[key], fill(missing, model.tick-uptick+1))
    end
    df = DataFrame(datadict)
    return (birthtime = agent._extras._birth_time, deathtime = agent._extras._death_time, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_agent_data(agent::AbstractPropDict, model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType}}, props = agent.keeps_record_of) where T<:MType
    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(agent)[key]
    end
    df = DataFrame(datadict)
    return (record=df,) 
end


"""
$(TYPEDSIGNATURES)
"""
function get_patch_data(patch, model::AbstractGridModel, props = model.record.pprops)
    if !(all(1 .<= patch) && all(patch .<= model.size))
        println("Patch $patch does not exist!")
        return
    end
    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(model.patches[patch...])[key]
    end
    df = DataFrame(datadict)
    return (record=df,)  
end

# We don't do any "data exists" checks in latest_propvals but the function will just throw an error if it doesn't.
# This is because latest_propvals is expected to be used during model run rather than after the run for getting data.

"""
$(TYPEDSIGNATURES)
"""
@inline function latest_propvals(obj::AbstractPropDict, propname::Symbol, n::Int)
    return unwrap_data(obj)[propname][max(end-n,1): end]
end

"""
$(TYPEDSIGNATURES)
"""
function latest_propvals(agent::AbstractPropDict, model::Union{AbstractGridModel, AbstractGraphModel}, propname::Symbol, n::Int)
   return latest_propvals(agent, propname, n)
end


"""
$(TYPEDSIGNATURES)
"""
function latest_propvals(patch, model::AbstractGridModel, propname::Symbol, n::Int)
   return latest_propvals(model.patches[patch...], propname, n) 
end


"""
$(TYPEDSIGNATURES)
"""
@inline function propnames(obj::AbstractPropDict)
    names = Symbol[]
    for key in keys(unwrap(obj))
        if (key!=:_extras)&&(key!=:keeps_record_of)
            push!(names, key)
        end
    end
    return names
end





"""
$(TYPEDSIGNATURES)
"""
function get_model_data(model::Union{AbstractGridModel, AbstractGraphModel}, props = model.record.mprops)
    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(model.parameters)[key]
    end
    df = DataFrame(datadict)
    return (record=df,)  
end



######################
@inline function create_temp_prop_dict(obj::Dict{Symbol, Any}, objdata::Dict{Symbol, Any}, record::Vector{Symbol}, index::Int)
    temp_dict = Dict{Symbol,Any}()
    for key in keys(obj)
        if !(key in record)
            temp_dict[key] = obj[key]
        else
            temp_dict[key] = objdata[key][index]
        end
    end
    return PropDict(temp_dict)
end

"""
$(TYPEDSIGNATURES)
"""
function get_nums_agents(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType}}, 
    conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Int}}()
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for agent in all_agents
                if (tick>=agent._extras._birth_time)&&(tick<=agent._extras._death_time)
                    index = tick-agent._extras._birth_time+1
                    agentcp = create_temp_prop_dict(unwrap(agent), unwrap_data(agent), agent.keeps_record_of, index)

                    if condition(agentcp)
                        num+=1
                    end
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of agents", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_agents_avg_props(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType}}, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)

    if length(all_agents)==0
        return DataFrame(dict)
    end

    first_agent = all_agents[1]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_agent) - fun(first_agent)
            num_alive = 0
            for agent in all_agents
                if (tick>=agent._extras._birth_time)&&(tick<=agent._extras._death_time)
                    index = tick-agent._extras._birth_time+1
                    agentcp = create_temp_prop_dict(unwrap(agent), unwrap_data(agent), agent.keeps_record_of, index)
                    val += fun(agentcp)
                    num_alive+=1
                end
            end
            if num_alive >0
                val = val/num_alive
            end
            push!(dict[name], val)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="", legend=:topright)) #outertopright
    end
    return df

end

"""
$(TYPEDSIGNATURES)
"""
function get_nums_agents(model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType}}, 
    conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for agent in model.agents
                agentcp = create_temp_prop_dict(unwrap(agent), unwrap_data(agent), agent.keeps_record_of, tick)
                if condition(agentcp)
                    num+=1
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of agents", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_agents_avg_props(model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType}}, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    all_agents = model.agents
    num_alive = length(all_agents)

    if num_alive==0
        return DataFrame(dict)
    end

    first_agent = all_agents[1]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_agent) - fun(first_agent)
            for agent in all_agents
                agentcp = create_temp_prop_dict(unwrap(agent), unwrap_data(agent), agent.keeps_record_of, tick)
                val += fun(agentcp)
            end

            val = val/num_alive

            push!(dict[name], val)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="", legend=:topright)) #outertopright
    end
    return df

end


"""
$(TYPEDSIGNATURES)
"""
function get_nums_patches(model::AbstractGridModel, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false )
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            
            for patch in model.patches
                patchcp = create_temp_prop_dict(unwrap(patch), unwrap_data(patch), model.record.pprops, tick)
                if condition(patchcp)
                    num+=1
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of patches", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_patches_avg_props(model::AbstractGridModel, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()

    first_patch = model.patches[[1 for _ in model.size]...]

    num_patches = 1

    for num in model.size
        num_patches *= num
    end

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_patch) - fun(first_patch)
            for patch in model.patches
                patchcp = create_temp_prop_dict(unwrap(patch), unwrap_data(patch), model.record.pprops, tick)       
                val += fun(patchcp)                
            end
            val = val/num_patches

            push!(dict[name], val)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="", legend=:topright)) #outertopright
    end
    return df

end


