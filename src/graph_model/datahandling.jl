
##############################
##############################
#  specific to graph models  #
##############################
##############################


"""
$(TYPEDSIGNATURES)
"""
function get_node_data(node::Int, model::GraphModelDynGrTop, props = model.record.nprops)
    graph = model.graph
    dead_graph = model.dead_meta_graph
    if !(node in getfield(model.graph, :_nodes))
        if node in getfield(dead_graph, :_nodes)
            graph = dead_graph
        else
            println("node ", node, " does not exist!")
            return (birthtime = 0, deathtime = 0, record = DataFrame()) 
        end
    end
    datadict=Dict{Symbol,Any}()
    birth_time = graph.nodesprops[node]._extras._birth_time::Int
    death_time = graph.nodesprops[node]._extras._death_time::Int
    uptick = death_time == typemax(Int) ? model.tick+1 : death_time+1
    downtick = birth_time-1
    for key in props
        datadict[key] = vcat(fill(missing, downtick),unwrap_data(graph.nodesprops[node])[key]::Vector, fill(missing, model.tick-uptick+1))
    end
    df = DataFrame(datadict);
    return (birthtime = birth_time, deathtime = death_time, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_node_data(node::Int, model::GraphModelFixGrTop, props = model.record.nprops)
    if !(node in getfield(model.graph, :_nodes))
        println("node ", node, " does not exist!")
        return (record=DataFrame(),)
    end
    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(model.graph.nodesprops[node])[key]::Vector
    end
    df = DataFrame(datadict);
    return (record=df,)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_edge_data_condition(i,j, graph)
    if !(is_digraph(graph))
        i,j = i>j ? (j,i) : (i,j)
        condition = haskey(graph.structure, i) && (j in graph.structure[i])
    else
        condition = haskey(graph.out_structure, i) && (j in graph.out_structure[i])
    end
    return i,j, condition
end


"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(i::Int,j::Int, model::GraphModelDynGrTop, props = model.record.eprops)
    graph = model.graph
    dead_graph = model.dead_meta_graph
    i,j,condition = _get_edge_data_condition(i,j, graph)
    if !(condition)
        i,j,condition = _get_edge_data_condition(i,j, dead_graph)
        if !condition
            println("edge ", (i,j), " does not exist!")
            return (birth_death_times =[(0,0)], record = DataFrame()) 
        else
            graph = dead_graph
        end
    end

    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(model.graph.edgesprops[(i,j)])[key]::Vector
    end
    df = DataFrame(datadict);
    return (birth_death_times = graph.edgesprops[(i,j)]._extras._bd_times::Vector{Tuple{Int, Int}}, record = df)   
end

"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(edge, model::GraphModelDynGrTop, props = model.record.eprops)
    i,j=edge
    get_edge_data(i,j, model, props)
end


"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(i::Int,j::Int, model::GraphModelFixGrTop, props = model.record.eprops)
    i,j,condition = _get_edge_data_condition(i,j,model)
    if !condition
        println("edge ", (i,j), " does not exist!")
        return (record=DataFrame(),)
    end
    datadict=Dict{Symbol,Any}()
    for key in props
        datadict[key] = unwrap_data(model.graph.edgesprops[(i,j)])[key]::Vector
    end
    df = DataFrame(datadict);
    return (record=df,)
end

"""
$(TYPEDSIGNATURES)
"""
function get_edge_data(edge, model::GraphModelFixGrTop, props = model.record.eprops)
    i,j=edge
    get_edge_data(i,j, model, props)
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
    return latest_propvals(model.graph.edgesprops[(i,j)], propname, n)
end




##############################
##############################
#     NUM AGENTS, PATCHES    #
##############################
##############################

"""
$(TYPEDSIGNATURES)
"""
function get_nums_nodes(model::GraphModelDynGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false )
    dict = Dict{Symbol, Vector{Int}}()
    dead_graph = model.dead_meta_graph
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for node in getfield(model.graph, :_nodes)
                birth_time = model.graph.nodesprops[node]._extras._birth_time::Int
                death_time = model.graph.nodesprops[node]._extras._death_time::Int
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, index)
                    if condition(nodecp)
                        num+=1
                    end
                end
            end
            for node in getfield(dead_graph, :_nodes)
                birth_time = dead_graph.nodesprops[node]._extras._birth_time::Int
                death_time = dead_graph.nodesprops[node]._extras._death_time::Int
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(dead_graph.nodesprops[node]), unwrap_data(dead_graph.nodesprops[node]), model.record.nprops, index)
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
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false )

    dead_graph = model.dead_meta_graph
    verts = getfield(model.graph, :_nodes)
    vertsd = getfield(dead_graph, :_nodes)
    first_node = PropDataDict()

    if (length(verts)!=0) 
        first_node = model.graph.nodesprops[verts[1]]
    elseif (length(vertsd)!= 0)
        first_node = dead_graph.nodesprops[vertsd[1]]
    else
        return DataFrame()
    end

    dict = _get_dict(props, first_node)

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        val = fun(first_node) .- fun(first_node)
        dict[name]=typeof(val./2)[]
        for tick in 1:model.tick
            num_alive = 0
            for node in verts
                birth_time = model.graph.nodesprops[node]._extras._birth_time::Int
                death_time = model.graph.nodesprops[node]._extras._death_time::Int
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, index)
                    val = val .+ fun(nodecp)
                    num_alive+=1
                end
            end

            for node in vertsd
                birth_time = dead_graph.nodesprops[node]._extras._birth_time::Int
                death_time = dead_graph.nodesprops[node]._extras._death_time::Int
                if (tick>=birth_time)&&(tick<=death_time)
                    index = tick-birth_time+1
                    nodecp = create_temp_prop_dict(unwrap(dead_graph.nodesprops[node]), unwrap_data(dead_graph.nodesprops[node]), model.record.nprops, index)
                    val = val .+ fun(nodecp)
                    num_alive+=1
                end
            end
            if num_alive >0
                val = val./num_alive
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
function get_nums_nodes(model::GraphModelFixGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false )
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
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false )

    verts = getfield(model.graph, :_nodes)
    num_alive = length(verts)

    if num_alive==0
        return DataFrame()
    end

    first_node = model.graph.nodesprops[1]

    dict = _get_dict(props, first_node)

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        val = fun(first_node) .- fun(first_node)
        dict[name]=typeof(val./2)[]
        for tick in 1:model.tick
            for node in verts
                nodecp = create_temp_prop_dict(unwrap(model.graph.nodesprops[node]), unwrap_data(model.graph.nodesprops[node]), model.record.nprops, tick)
                val = val .+ fun(nodecp)
            end
            val = val./num_alive
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
function get_nums_edges(model::GraphModelDynGrTop, conditions::Function...; labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false )
    dict = Dict{Symbol, Vector{Int}}()
    dead_graph = model.dead_meta_graph
    for i in 1:length(conditions)
        name = Symbol(labels[i])
        condition = conditions[i]
        dict[name]=Int[]
        for tick in 1:model.tick
            num=0
            for edge in edges(model.graph)
                len = 0
                for (birth_time, death_time) in model.graph.edgesprops[edge]._extras._bd_times::Vector{Tuple{Int, Int}}
                    if (tick>=birth_time)&&(tick<=death_time)
                        index = tick-birth_time+len+1
                        edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, index)

                        if condition(edgecp)
                            num+=1
                        end
                        break
                    end

                    if death_time < typemax(Int)
                        len+=death_time - birth_time +1
                    end

                end
            end
            for edge in edges(dead_graph)
                len = 0
                for (birth_time, death_time) in model.graph.edgesprops[edge]._extras._bd_times::Vector{Tuple{Int, Int}}
                    if (tick>=birth_time)&&(tick<=death_time)
                        index = tick-birth_time+len+1
                        edgecp = create_temp_prop_dict(unwrap(dead_graph.edgesprops[edge]), unwrap_data(dead_graph.edgesprops[edge]), model.record.eprops, index)

                        if condition(edgecp)
                            num+=1
                        end
                        break
                    end
                    if death_time < typemax(Int)
                        len+=death_time - birth_time +1
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
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false )

    dead_graph = model.dead_meta_graph
    eds = collect(edges(model.graph))
    edsd = collect(edges(dead_graph))
    first_edge = PropDataDict()

    if length(eds)!=0
        first_edge = model.graph.edgesprops[eds[1]]
    elseif length(edsd)!=0 
        first_edge = dead_graph.edgesprops[edsd[1]]
    else
        return DataFrame()
    end

    dict = _get_dict(props, first_edge)


    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        val = fun(first_edge) .- fun(first_edge)
        dict[name]=typeof(val./2)[]
        for tick in 1:model.tick
            num_alive = 0
            for edge in eds
                len = 0
                for (birth_time, death_time) in model.graph.edgesprops[edge]._extras._bd_times::Vector{Tuple{Int, Int}}
                    if (tick>=birth_time)&&(tick<=death_time)
                        index = tick-birth_time+len+1
                        edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, index)
                        val = val .+ fun(edgecp)
                        num_alive+=1
                        break
                    end
                    if death_time < typemax(Int)
                        len+=death_time - birth_time +1
                    end
                end
            end
            for edge in edsd
                len = 0
                for (birth_time, death_time) in model.graph.edgesprops[edge]._extras._bd_times::Vector{Tuple{Int, Int}}
                    if (tick>=birth_time)&&(tick<=death_time)
                        index = tick-birth_time+len+1
                        edgecp = create_temp_prop_dict(unwrap(dead_graph.edgesprops[edge]), unwrap_data(dead_graph.edgesprops[edge]), model.record.eprops, index)
                        val = val .+ fun(edgecp)
                        num_alive+=1
                        break
                    end
                    if death_time < typemax(Int)
                        len+=death_time - birth_time +1
                    end
                end
            end
            if num_alive >0
                val = val./num_alive
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
function get_nums_edges(model::GraphModelFixGrTop, conditions::Function...;labels::Vector{String} = string.(collect(1:length(conditions))), plot_result = false )
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
    props::Function...; labels::Vector{String} = string.(collect(1:length(props))), plot_result = false )

    eds = collect(edges(model.graph))
    num_alive = length(eds)

    if num_alive==0
        return DataFrame()
    end

    first_edge = model.graph.edgesprops[eds[1]]

    dict = _get_dict(props, first_edge)

    for i in 1:length(props)
        fun = props[i]
        name = Symbol(labels[i])
        val = fun(first_edge) .- fun(first_edge)
        dict[name]=typeof(val./2)[]
        for tick in 1:model.tick
            for edge in eds 
                edgecp = create_temp_prop_dict(unwrap(model.graph.edgesprops[edge]), unwrap_data(model.graph.edgesprops[edge]), model.record.eprops, tick)
                val = val .+ fun(edgecp)
            end
            val = val./num_alive

            push!(dict[name], val)
        end
    end
    df = DataFrame(dict);
    if plot_result
        display(plot(Matrix(df), labels=permutedims(names(df)), xlabel="ticks", ylabel="", legend=:topright)) #outertopright
    end
    return df
end




