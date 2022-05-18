"""
$(TYPEDSIGNATURES)
"""
function get_agent_data(agent::AbstractPropDict, model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType}}) where T<:MType
    datadict=Dict{Symbol,Any}()
    uptick = agent._extras._death_time == Inf ? model.tick+1 : agent._extras._death_time+1
    downtick = agent._extras._birth_time-1
    for key in agent.keeps_record_of
        datadict[key] = vcat(fill(missing, downtick),unwrap_data(agent)[key], fill(missing, model.tick-uptick+1))
    end
    df = DataFrame(datadict)
    return (birthtime = agent._extras._birth_time, deathtime = agent._extras._death_time, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_agent_data(agent::AbstractPropDict, model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType}}) where T<:MType
    datadict=Dict{Symbol,Any}()
    for key in agent.keeps_record_of
        datadict[key] = unwrap_data(agent)[key]
    end
    df = DataFrame(datadict)
    return (record=df,) 
end


"""
$(TYPEDSIGNATURES)
"""
function get_patch_data(patch, model::AbstractGridModel)
    if !(all(1 .<= patch) && all(patch .<= model.size))
        println("Patch $patch does not exist!")
        return
    end
    datadict=Dict{Symbol,Any}()
    for key in model.record.pprops
        datadict[key] = unwrap_data(model.patches[patch])[key]
    end
    df = DataFrame(datadict)
    return (record=df,)  
end



"""
$(TYPEDSIGNATURES)
"""
function get_model_data(model::Union{AbstractGridModel, AbstractGraphModel})
    datadict=Dict{Symbol,Any}()
    for key in model.record.mprops
        datadict[key] = unwrap_data(model.parameters)[key]
    end
    df = DataFrame(datadict)
    return (record=df,)  
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
                temp_dict = Dict{Symbol,Any}()
                if (tick>=agent._extras._birth_time)&&(tick<=agent._extras._death_time)
                    for key in agent.keeps_record_of
                        temp_dict[key]=unwrap_data(agent)[key][tick-agent._extras._birth_time+1]
                    end

                    if condition(PropDict(temp_dict))
                        num+=1
                    end
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of agents", legend=:topright)) #outertopright
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
                temp_dict = Dict{Symbol,Any}()
                for key in agent.keeps_record_of
                    temp_dict[key]=unwrap_data(agent)[key][tick-agent._extras._birth_time+1]
                end
                if condition(PropDict(temp_dict))
                    num+=1
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of agents", legend=:topright)) #outertopright
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
            
            for pkey in keys(model.patches)
                if all(0 .< pkey)
                    temp_dict = Dict{Symbol,Any}()
                    patch_data = unwrap_data(model.patches[pkey])
                    for key in model.record.pprops
                        temp_dict[key]=patch_data[key][tick]
                    end
                    if condition(PropDict(temp_dict))
                        num+=1
                    end
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of patches", legend=:topright)) #outertopright
    end
    return df
end
