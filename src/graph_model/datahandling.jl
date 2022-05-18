
##############################
##############################
#  specific to graph models  #
##############################
##############################


"""
$(TYPEDSIGNATURES)
"""
function get_node_data(node::Int, model::GraphModelDynGrTop)
    if !(node in vertices(model.graph))
        return
    end
    datadict=Dict{Symbol,Any}()
    birth_time = model.graph.nodesprops[node]._extras._birth_time
    death_time = model.graph.nodesprops[node]._extras._death_time
    uptick = death_time == Inf ? model.tick+1 : death_time+1
    downtick = birth_time-1
    for key in model.record.nprops
        datadict[key] = vcat(fill(missing, downtick),unwrap_data(model.graph.nodesprops[node])[key], fill(missing, model.tick-uptick+1))
    end
    df = DataFrame(datadict);
    return (birthtime = birth_time, deathtime = death_time, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_node_data(node::Int, model::GraphModelFixGrTop)
    if !(node in vertices(model.graph))
        println("node ", node, " does not exist!")
        return
    end
    datadict=Dict{Symbol,Any}()
    for key in model.record.nprops
        datadict[key] = unwrap_data(model.graph.nodesprops[node])[key]
    end
    df = DataFrame(datadict);
    return (record=df,)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_edge_data_condition(i,j,model::GraphModel)
    if !(is_directed(model.graph))
        i,j = i>j ? (j,i) : (i,j)
        condition = (i in vertices(model.graph)) && (j in model.graph.structure[i])
    else
        condition = (i in model.graph.nodes) && (j in model.graph.out_structure[i])
    end
    return i,j, condition
end


"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(i::Int,j::Int, model::GraphModelDynGrTop)
    i,j,condition = _get_edge_data_condition(i,j,model)
    if !condition
        println("edge ", (i,j), " does not exist!")
        return
    end
    datadict=Dict{Symbol,Any}()
    birth_time = model.graph.edgesprops[(i,j)]._extras._birth_time
    death_time = model.graph.edgesprops[(i,j)]._extras._death_time
    uptick = death_time == Inf ? model.tick+1 : death_time+1
    downtick = birth_time-1
    for key in model.record.eprops
        datadict[key] = vcat(fill(missing, downtick),unwrap_data(model.graph.edgesprops[(i,j)])[key], fill(missing, model.tick-uptick+1))
    end
    df = DataFrame(datadict);
    return (birthtime = birth_time, deathtime = death_time, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(edge, model::GraphModelDynGrTop)
    i,j=edge
    get_edge_data(i,j, model)
end


"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(i::Int,j::Int, model::GraphModelFixGrTop)
    i,j,condition = _get_edge_data_condition(i,j,model)
    if !condition
        println("edge ", (i,j), " does not exist!")
        return
    end
    datadict=Dict{Symbol,Any}()
    for key in model.record.eprops
        datadict[key] = unwrap_data(model.graph.edgesprops[(i,j)])[key]
    end
    df = DataFrame(datadict);
    return (record=df,)
end

"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(edge, model::GraphModelFixGrTop)
    i,j=edge
    get_edge_data(i,j, model)
end




##############################
##############################
#     NUM AGENTS, PATCHES    #
##############################
##############################

"""
$(TYPEDSIGNATURES)
"""
function get_nums_nodes(model::GraphModelDynGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for node in vertices(model.graph)
                temp_dict = Dict{Symbol,Any}()
                birth_time = model.graph.nodesprops[node]._extras._birth_time
                death_time = model.graph.nodesprops[node]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    for key in model.record.nprops
                        temp_dict[key]=unwrap_data(model.graph.nodesprops[node])[key][tick-birth_time+1]
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
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of nodes", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_nums_nodes(model::GraphModelFixGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for node in vertices(model.graph)
                temp_dict = Dict{Symbol,Any}()
                for key in model.record.nprops
                    temp_dict[key]=unwrap_data(model.graph.nodesprops[node])[key][tick]
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
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of nodes", legend=:topright)) #outertopright
    end
    return df
end

"""
$(TYPEDSIGNATURES)
"""
function get_nums_edges(model::GraphModelDynGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for edge in model.graph.edges
                temp_dict = Dict{Symbol,Any}()
                birth_time = model.graph.edgesprops[edge]._extras._birth_time
                death_time = model.graph.edgesprops[edge]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    for key in model.record.eprops
                        temp_dict[key]=unwrap_data(model.graph.edgesprops[edge])[key][tick-birth_time+1]
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
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of edges", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_nums_edges(model::GraphModelFixGrTop, conditions::Function...;labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for edge in model.graph.edges
                temp_dict = Dict{Symbol,Any}()
                for key in model.record.eprops
                    temp_dict[key]=unwrap_data(model.graph.edgesprops[edge])[key][tick]
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
        display(plot(Matrix(df), labels=permutedims(labels), xlabel="ticks", ylabel="number of edges", legend=:topright)) #outertopright
    end
    return df
end



