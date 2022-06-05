
##############################
##############################
#  specific to graph models  #
##############################
##############################


"""
$(TYPEDSIGNATURES)
"""
function get_node_data(node::Int, model::GraphModelDynGrTop)
    if !(node in getfield(model.graph, :_nodes))
        println("node ", node, " does not exist!")
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
    if !(node in getfield(model.graph, :_nodes))
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
    if !(is_digraph(model.graph))
        i,j = i>j ? (j,i) : (i,j)
        condition = (i in getfield(model.graph, :_nodes)) && (j in model.graph.structure[i])
    else
        condition = (i in getfield(model.graph, :_nodes)) && (j in model.graph.out_structure[i])
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


# We don't do any "data exists" checks in latest_propvals but the function will just throw an error if it doesn't.
# This is because latest_propvals is expected to be used during model run rather than after the run for getting data.

"""
$(TYPEDSIGNATURES)
"""
function latest_propvals(node::Int, model::GraphModel, propname::Symbol, n::Int)
    return latest_propvals(model.graph.nodesprops[node], propname, n)
end

"""
$(TYPEDSIGNATURES)
"""
function latest_propvals(i::Int,j::Int, model::GraphModel, propname::Symbol, n::Int)
    if !(is_digraph(model.graph))
        i,j = i>j ? (j,i) : (i,j)
    end
    return latest_propvals(model.graph.edgesprops[(i,j)], propname, n)
end


"""
$(TYPEDSIGNATURES)
"""
function latest_propvals(edge, model::GraphModel, propname::Symbol, n::Int)
    i,j=edge
    if !(is_digraph(model.graph))
        i,j = i>j ? (j,i) : (i,j)
    end
    return unwrap_data(model.graph.edgesprops[(i,j)])[propname][max(end-n,1):end]
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
            for node in getfield(model.graph, :_nodes)
                birth_time = model.graph.nodesprops[node]._extras._birth_time
                death_time = model.graph.nodesprops[node]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, index)
                    if condition(nodecp)
                        num+=1
                    end
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of nodes", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_nodes_avg_props(model::GraphModelDynGrTop, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    verts = getfield(model.graph, :_nodes)

    if length(verts)==0
        return DataFrame(dict)
    end

    first_node = model.graph.nodesprops[1]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_node) - fun(first_node)
            num_alive = 0
            for node in verts
                birth_time = model.graph.nodesprops[node]._extras._birth_time
                death_time = model.graph.nodesprops[node]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, index)
                    val += fun(nodecp)
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
function get_nums_nodes(model::GraphModelFixGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for node in getfield(model.graph, :_nodes)
                nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, tick)
                if condition(nodecp)
                    num+=1
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of nodes", legend=:topright)) #outertopright
    end
    return df
end




"""
$(TYPEDSIGNATURES)
"""
function get_nodes_avg_props(model::GraphModelFixGrTop, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    verts = getfield(model.graph, :_nodes)
    num_alive = length(verts)

    if num_alive==0
        return DataFrame(dict)
    end

    first_node = model.graph.nodesprops[1]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_node) - fun(first_node)
            for node in verts
                nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, tick)
                val += fun(nodecp)
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
function get_nums_edges(model::GraphModelDynGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for edge in edges(model.graph)
                birth_time = model.graph.edgesprops[edge]._extras._birth_time
                death_time = model.graph.edgesprops[edge]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, index)

                    if condition(edgecp)
                        num+=1
                    end
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of edges", legend=:topright)) #outertopright
    end
    return df
end




"""
$(TYPEDSIGNATURES)
"""
function get_edges_avg_props(model::GraphModelDynGrTop, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    eds = edges(model.graph)

    if length(eds)==0
        return DataFrame(dict)
    end

    first_edge = model.graph.edgesprops[eds[1]]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_edge) - fun(first_edge)
            num_alive = 0
            for edge in eds
                birth_time = model.graph.edgesprops[edge]._extras._birth_time
                death_time = model.graph.edgesprops[edge]._extras._death_time
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, index)
                    val += fun(edgecp)
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
function get_nums_edges(model::GraphModelFixGrTop, conditions::Function...;labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false ) where N
    dict = Dict{Symbol, Vector{Int}}()
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for edge in edges(model.graph)
                edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, tick)
                if condition(edgecp)
                    num+=1
                end
            end
            push!(dict[name], num)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="number of edges", legend=:topright)) #outertopright
    end
    return df
end


"""
$(TYPEDSIGNATURES)
"""
function get_edges_avg_props(model::GraphModelFixGrTop, 
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false ) where T<: MType

    dict = Dict{Symbol, Vector{Float64}}()
    eds = edges(model.graph)
    num_alive = length(eds)

    if num_alive==0
        return DataFrame(dict)
    end

    first_edge = model.graph.edgesprops[eds[1]]

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        dict[name]=Float64[]
        for tick in 1:model.tick
            val = fun(first_edge) - fun(first_edge)
            for edge in eds 
                edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, tick)
                val += fun(edgecp)
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




