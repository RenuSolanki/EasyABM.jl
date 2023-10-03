
const _node_size = 10 # percent of gparams.width(by defualt set to 400)

const _scale_graph = 0.95
const _boundary_frame = 0.025

const gsize = 1

"""
$(TYPEDSIGNATURES)
"""
function _get_node_size(n::Int)
    node_size = min(20*gsize/sqrt(n),4)
    return node_size        
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos(graph::AbstractPropGraph{Mortal}, vert, frame, nprops)
    birth_time = graph.nodesprops[vert]._extras._birth_time::Int
    index = frame-birth_time +1 
    if haskey(graph.nodesprops[vert], :pos)
        x, y = (:pos in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos][index] : graph.nodesprops[vert].pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    else 
        x,y = graph.nodesprops[vert]._extras._pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    end
    return vert_pos
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos(graph::AbstractPropGraph{Static}, vert, frame, nprops)
    index = frame
    if haskey(graph.nodesprops[vert], :pos)
        x,y = (:pos in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos][index] : graph.nodesprops[vert].pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    else
        x,y = graph.nodesprops[vert]._extras._pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    end
    return vert_pos
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_col(graph::AbstractPropGraph{Mortal}, vert, frame, nprops)
    birth_time = graph.nodesprops[vert]._extras._birth_time::Int
    index = frame-birth_time +1 
    if haskey(graph.nodesprops[vert], :color)
        vert_col = (:color in nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index]::Col : graph.nodesprops[vert].color::Col
    else 
        vert_col = Col("white")
    end
    return vert_col
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_col(graph::AbstractPropGraph{Static}, vert, frame, nprops)
    index = frame
    if haskey(graph.nodesprops[vert], :color)
        vert_col = (:color in nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index]::Col : graph.nodesprops[vert].color::Col
    else 
        vert_col = Col("white")
    end
    return vert_col
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_edge_col(graph::AbstractPropGraph, vert, nd, index, eprops)

    if haskey(graph.edgesprops[(vert,nd)], :color)
        edge_col = (:color in eprops) ? unwrap_data(graph.edgesprops[(vert,nd)])[:color][index]::Col : graph.edgesprops[(vert,nd)].color::Col
    else 
        edge_col = Col("black")
    end
    return edge_col
end




@inline function _get_norm(a, b)
    x,y = a
    z,w = b
    return sqrt((x-z)^2+(y-w)^2)
end

@inline function out_links(graph::PropDict, vert)
    if haskey(graph, :structure)
        structure = graph.structure[vert]
        return (k for k in structure if k>vert)
    elseif haskey(graph, :out_structure)
        return (nd for nd in graph.out_structure[vert])
    else
        return (i for i in 1:0)
    end
end


# """
# $(TYPEDSIGNATURES)
# """
# @inline function _get_graph_layout_info(model::GraphModelDynGrTop, graph, frame)
#     verts = vertices(graph)
#     alive_verts = Iterators.filter(nd-> (graph.nodesprops[nd]._extras._birth_time::Int <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time::Int), verts)
#     verts_pos = Vector{GeometryBasics.Point2{Float64}}()
#     verts_dir = Vector{GeometryBasics.Vec2{Float64}}()
#     verts_color = Vector{Col}()
#     for vert in alive_verts
#         index = frame-graph.nodesprops[vert]._extras._birth_time::Int + 1
#         out_structure = collect(out_links(graph, vert))
#         active_out_structure, indices = _get_active_out_structure(graph, vert, out_structure, frame)
#         pos = _get_vert_pos(graph, vert, frame, model.record.nprops)
#         pos_p = GeometryBasics.Point(pos)
#         vert_col = cl"black"
#         if haskey(graph.nodesprops[vert], :color)
#             vert_col = (:color in model.record.nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index]::Col : graph.nodesprops[vert].color::Col
#         end
#         push!(verts_pos, pos_p)
#         push!(verts_dir, GeometryBasics.Vec(0.0,0))
#         push!(verts_color, vert_col)

#         for x in active_out_structure
#             push!(verts_pos, pos_p)
#             pos_x = _get_vert_pos(graph, x, frame, model.record.nprops)
#             push!(verts_dir, GeometryBasics.Vec(pos_x-pos_p))
#             push!(verts_color, vert_col)
#         end
#     end

#     return (verts_pos, verts_dir, verts_color)
# end

# """
# $(TYPEDSIGNATURES)
# """
# @inline function _get_graph_layout_info(model::GraphModelFixGrTop, graph, frame)
#     alive_verts = vertices(graph)
#     verts_pos = Vector{GeometryBasics.Point2{Float64}}()
#     verts_dir = Vector{GeometryBasics.Vec2{Float64}}()
#     verts_color = Vector{Col}()
#     index = frame
#     for vert in alive_verts
#         active_out_structure = out_links(graph, vert)
#         pos = _get_vert_pos(graph, vert, frame, model.record.nprops)
#         pos_p = GeometryBasics.Point(pos)

#         vert_col = cl"black"
#         if haskey(graph.nodesprops[vert], :color)
#             vert_col = (:color in model.record.nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index]::Col : graph.nodesprops[vert].color::Col
#         end

#         push!(verts_pos, pos_p)
#         push!(verts_dir, GeometryBasics.Vec(0.0,0))
#         push!(verts_color, vert_col)

#         for x in active_out_structure
#             push!(verts_pos, pos_p)
#             pos_x = _get_vert_pos(graph, x, frame, model.record.nprops)
#             push!(verts_dir, GeometryBasics.Vec(pos_x-pos_p))
#             push!(verts_color, vert_col)
#         end
#     end
#     return (verts_pos, verts_dir, verts_color)
# end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos(model::GraphModelDynAgNum, graph, frame)
    posits = Vector{GeometryBasics.Vec2{Float64}}()
    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
        agent_data = unwrap_data(agent)
        if (agent._extras._birth_time::Int<= frame)&&(frame<= agent._extras._death_time::Int)
            index = frame - agent._extras._birth_time::Int +1
            node = (:node in agent._keeps_record_of::Set{Symbol}) ? agent_data[:node][index]::Int : agent.node
            pos = _get_vert_pos(graph, node, frame, model.record.nprops)+GeometryBasics.Vec(0.05-0.1*rand(), 0.05-0.1*rand())
            push!(posits, pos)
        end
    end
    return posits
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos(model::GraphModelFixAgNum, graph, frame) 
    posits = Vector{GeometryBasics.Vec2{Float64}}()
    for agent in model.agents
        agent_data = unwrap_data(agent)
        index = frame 
        node = (:node in agent._keeps_record_of::Set{Symbol}) ? agent_data[:node][index]::Int : agent.node
        pos = _get_vert_pos(graph, node, frame, model.record.nprops)+GeometryBasics.Vec(0.05-0.1*rand(), 0.05-0.1*rand())
        push!(posits, pos)
    end
    return posits
end


# """
# $(TYPEDSIGNATURES)
# """
# @inline function _create_makie_frame(ax, model::GraphModel, points, markers, colors, rotations, sizes, verts_pos, verts_dir, verts_color, show_space)
#     ax.aspect = DataAspect()
#     xlims!(ax, 0.0, gsize)
#     ylims!(ax, 0.0, gsize)
#     if show_space
#         scatter!(ax, verts_pos, marker=:circle, color = verts_color)
#         arrowhead = is_digraph(model.graph) ? '△'  :  '.' #\bigtriangleup<tab>
#         arrows!(ax, verts_pos, verts_dir, arrowhead=arrowhead)
#     end
    
#     scatter!(ax, points, marker = markers, color = colors, rotations = rotations, markersize = sizes)
#     return 
# end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_vert(pos, col, node_size, neighs_pos, oriented::Bool, edge_cols) 

    width = gparams.width
    height = gparams.height
    w, h = width/gsize, height/gsize

    node_size = node_size*w/100


    posx,posy = pos

    x =  w*posx #- w/2
    y =  h*posy #-h/2
    cl = col.val

    gsave()
    translate(-width/2, height/2)
    Luxor.transform([1 0 0 -1 0 0]) #reflects in xaxis
    ##
    translate(x,y)
    setcolor(cl)
    circle(Luxor.Point(0,0), node_size, :fill)
    setline(1)
    setcolor(RGBA(0,0,0,1))
    circle(Luxor.Point(0,0), node_size, :stroke)
    grestore()

    if oriented
        for ind in 1:length(neighs_pos)
            v = neighs_pos[ind]
            col = edge_cols[ind]
            posv_x, posv_y = v
            x_v, y_v = w*posv_x, h*posv_y 
            v1 = x_v-x
            v2 = y_v-y
            nrm = sqrt(v1^2+v2^2)
            corr_vec1 = node_size*v1/(nrm+0.00001)
            corr_vec2 = node_size*v2/(nrm+0.00001)
            corr_point = Luxor.Point(corr_vec1, corr_vec2)
            gsave()
            translate(-(width/2), (height/2))
            Luxor.transform([1 0 0 -1 0 0])
            setcolor(col.val)
            setline(1)
            arrow(Luxor.Point(x,y)+corr_point, Luxor.Point(x_v, y_v)-corr_point, arrowheadlength= node_size*0.3)
            grestore()
        end
    else
        for ind in 1:length(neighs_pos)
            v = neighs_pos[ind]
            col = edge_cols[ind]
            posv_x, posv_y = v
            x_v, y_v = w*posv_x, h*posv_y 
            v1 = x_v-x
            v2 = y_v-y
            nrm = sqrt(v1^2+v2^2)
            corr_vec1 = node_size*v1/(nrm+0.00001)
            corr_vec2 = node_size*v2/(nrm+0.00001)
            corr_point = Luxor.Point(corr_vec1, corr_vec2)
            gsave()
            translate(-(width/2), (height/2))
            Luxor.transform([1 0 0 -1 0 0])
            setcolor(col.val)
            setline(1)
            line(Luxor.Point(x,y)+corr_point, Luxor.Point(x_v, y_v)-corr_point, :stroke)
            grestore()
        end
    end
end



"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agent(agent::GraphAgent, model::GraphModel, graph, node_size, scl, index::Int, frame::Int) # the check 0<index< length(data) has been made before calling the function.
    record = agent._keeps_record_of::Set{Symbol}
    agent_data = unwrap_data(agent)   
    
    width = gparams.width
    height = gparams.height
    w, h = width/gsize, height/gsize

    node_size = node_size*w/100


    node = (:node in record) ? agent_data[:node][index]::Int : agent.node

    
    pos = _get_vert_pos(graph, node, frame, model.record.nprops) #model.graph.nodesprops[node]._extras._pos

    orientation = (:orientation in record) ? agent_data[:orientation][index]::Float64 : agent.orientation::Float64
    shape = (:shape in record) ? agent_data[:shape][index]::Symbol : agent.shape::Symbol
    shape_color = (:color in record) ? agent_data[:color][index]::Col : agent.color::Col

    if !(shape in keys(shapefunctions2d))
        shape = :circle
    end


    size = (:size in record) ? agent_data[:size][index]::Union{Int, Float64} : agent.size::Union{Int, Float64}

    size = size*scl*node_size/100
    
    posx,posy = pos

    x =  w*posx #- w/2
    y =  h*posy #-h/2
    k1 = getfield(agent, :id)
    k2 = agent.node
    pairing_number = Int(((k1+k2)*(k1+k2+1)/2) + k2) # Cantor pairing
    rng= Random.MersenneTwister(pairing_number)
    theta = rand(rng)*2*pi
    a = (node_size)*cos(theta)
    b = (node_size)*sin(theta)
                
    #posx, posy coordinate system is centered at lower left corner of the grid
    #with + POSX to right and +POSY upwards; Except for scale, the x, y coordinate 
    #system coincides with posx, post system. 

    gsave()
    translate(-(width/2), (height/2))
    Luxor.transform([1 0 0 -1 0 0])         
    translate(x+a,y+b)  
    rotate(-orientation)                        
    setcolor(shape_color.val)           
    setline(1)                              
    shapefunctions2d[shape](size)  
    grestore()  


    #uncomment this to mark each agent with its id
    # gsave()
    # translate(-(width/2), (height/2))
    # Luxor.transform([1 0 0 -1 0 0]) 
    # translate(x+a,y+b)
    # if shape_color != :white
    #     sethue("white")
    # else
    #     sethue("black")
    # end
    # fontface("Arial-Black")
    # fontsize(10)
    # text("$(agent._extras._id)", halign = :center, valign = :middle)
    # grestore()

end



@inline function _get_vert_pos_isolated_graph(graph, vert)
    if haskey(graph.nodesprops[vert], :pos)
        x,y = graph.nodesprops[vert].pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    else
        x,y = graph.nodesprops[vert]._extras._pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    end
    return vert_pos
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_col_isolated_graph(graph, vert)
    if haskey(graph.nodesprops[vert], :color)
        vert_col = graph.nodesprops[vert].color::Col
    else 
        vert_col = Col("white")
    end
    return vert_col
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_edge_col_isolated_graph(graph, vert, nd)
    if haskey(graph.edgesprops[(vert,nd)], :color)
        vert_col = graph.edgesprops[(vert,nd)].color::Col
    else 
        vert_col = Col("black")
    end
    return vert_col
end


"""
$(TYPEDSIGNATURES)
"""
function draw_graph(graph)
    if typeof(graph)<:SimpleGraph
        graph = static_simple_graph(graph)
    end
    if typeof(graph)<:SimpleDiGraph
        graph = static_dir_graph(graph)
    end
    verts = sort!(collect(vertices(graph)))
    if length(verts)==0
        return 
    end

    if !is_digraph(graph)
        structure = graph.structure
        if !is_static(graph)
            graph = convert_type(graph, Static)
        end
    else
        if !is_static(graph)
            graph = convert_type(graph, Static)
        end
        structure = Dict{Int, Vector{Int}}()
        for node in verts
            structure[node] = unique!(sort!(vcat(graph.in_structure[node], graph.out_structure[node])))
        end
    end

    first_vert = verts[1]
    if !(first_vert in keys(graph.nodesprops))
        graph.nodesprops[first_vert] = ContainerDataDict()
    end
    if !haskey(graph.nodesprops[first_vert], :pos) && !haskey(graph.nodesprops[first_vert]._extras, :_pos) ##?##
        locs_x, locs_y = spring_layout(structure)
        for (i,vt) in enumerate(verts)
            if !(vt in keys(graph.nodesprops))
                graph.nodesprops[vt] = ContainerDataDict()
            end
            graph.nodesprops[vt]._extras._pos = (locs_x[i], locs_y[i])
        end
    end

    drawing = Drawing(gparams.width, gparams.height, :png)
    node_size = _get_node_size(length(verts))
    Luxor.origin()
    Luxor.background("white")
    for vert in verts
        vert_pos = _get_vert_pos_isolated_graph(graph, vert)
        vert_col = _get_vert_col_isolated_graph(graph, vert)
        out_structure = out_links(graph, vert)
        neighs_pos = [_get_vert_pos_isolated_graph(graph, nd) for nd in out_structure]
        edge_cols =  [_get_edge_col_isolated_graph(graph, vert, nd) for nd in out_structure]
        draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph), edge_cols)
    end
    finish()
    drawing
end

