
const _node_size = 10

const _scale_graph = 0.95
const _boundary_frame = 0.025

const gsize = 10

"""
$(TYPEDSIGNATURES)
"""
function _get_node_size(n::Int)
    node_size = 0.15*gsize/sqrt(n)
    return node_size        
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos(graph::AbstractPropGraph{MortalType}, vert, frame, nprops)
    birth_time = graph.nodesprops[vert]._extras._birth_time
    index = frame-birth_time +1 
    if haskey(graph.nodesprops[vert], :pos)
        vert_pos = (:pos in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos][index] : graph.nodesprops[vert].pos
    else 
        x,y = graph.nodesprops[vert]._extras._pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    end
    return vert_pos
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos(graph::AbstractPropGraph{StaticType}, vert, frame, nprops)
    index = frame
    if haskey(graph.nodesprops[vert], :pos)
        vert_pos = (:pos in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos][index] : graph.nodesprops[vert].pos
    else
        x,y = graph.nodesprops[vert]._extras._pos
        vert_pos = GeometryBasics.Vec(Float64(x),y)
    end
    return vert_pos
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_col(graph::AbstractPropGraph{MortalType}, vert, frame, nprops)
    birth_time = graph.nodesprops[vert]._extras._birth_time
    index = frame-birth_time +1 
    if haskey(graph.nodesprops[vert], :color)
        vert_col = (:color in nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index] : graph.nodesprops[vert].color
    else 
        vert_col = :white
    end
    return vert_col
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_col(graph::AbstractPropGraph{StaticType}, vert, frame, nprops)
    index = frame
    if haskey(graph.nodesprops[vert], :color)
        vert_col = (:color in nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index] : graph.nodesprops[vert].color
    else 
        vert_col = :white
    end
    return vert_col
end


@inline function _get_norm(a, b)
    x,y = a
    z,w = b
    return sqrt((x-z)^2+(y-w)^2)
end




"""
$(TYPEDSIGNATURES)
"""
@inline function _get_graph_layout_info(model::GraphModelDynGrTop, frame)
    graph = model.graph
    verts = vertices(graph)
    alive_verts = verts[[(graph.nodesprops[nd]._extras._birth_time <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time) for nd in verts]]
    verts_pos = Vector{GeometryBasics.Point2{Float64}}()
    verts_dir = Vector{GeometryBasics.Vec2{Float64}}()
    verts_color = Vector{Symbol}()
    for vert in alive_verts
        index = frame-graph.nodesprops[vert]._extras._birth_time + 1
        out_structure = out_links(graph, vert)
        active_out_structure = out_structure[[(graph.edgesprops[(vert, nd)]._extras._birth_time <= frame)&&(frame<=graph.edgesprops[(vert, nd)]._extras._death_time) for nd in out_structure]]
        pos = _get_vert_pos(graph, vert, frame, model.record.nprops)
        pos_p = GeometryBasics.Point(pos)
        vert_col = :black 
        if haskey(graph.nodesprops[vert], :color)
            vert_col = (:color in model.record.nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index] : graph.nodesprops[vert].color
        end
        push!(verts_pos, pos_p)
        push!(verts_dir, GeometryBasics.Vec(0.0,0))
        push!(verts_color, vert_col)

        for x in active_out_structure
            push!(verts_pos, pos_p)
            pos_x = _get_vert_pos(graph, x, frame, model.record.nprops)
            push!(verts_dir, GeometryBasics.Vec(pos_x-pos_p))
            push!(verts_color, vert_col)
        end


    end
    return (verts_pos, verts_dir, verts_color)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_graph_layout_info(model::GraphModelFixGrTop, frame)
    graph = model.graph
    alive_verts = vertices(graph)
    verts_pos = Vector{GeometryBasics.Point2{Float64}}()
    verts_dir = Vector{GeometryBasics.Vec2{Float64}}()
    verts_color = Vector{Symbol}()
    index = frame
    for vert in alive_verts
        active_out_structure = out_links(graph, vert)
        pos = _get_vert_pos(graph, vert, frame, model.record.nprops)
        pos_p = GeometryBasics.Point(pos)

        vert_col = :black 
        if haskey(graph.nodesprops[vert], :color)
            vert_col = (:color in model.record.nprops) ? unwrap_data(graph.nodesprops[vert])[:color][index] : graph.nodesprops[vert].color
        end

        push!(verts_pos, pos_p)
        push!(verts_dir, GeometryBasics.Vec(0.0,0))
        push!(verts_color, vert_col)

        for x in active_out_structure
            push!(verts_pos, pos_p)
            pos_x = _get_vert_pos(graph, x, frame, model.record.nprops)
            push!(verts_dir, GeometryBasics.Vec(pos_x-pos_p))
            push!(verts_color, vert_col)
        end
    end
    return (verts_pos, verts_dir, verts_color)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos(model::GraphModelDynAgNum, frame)
    posits = Vector{GeometryBasics.Vec2{Float64}}()
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        agent_data = unwrap_data(agent)
        if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
            index = frame - agent._extras._birth_time +1
            node = (:node in agent.keeps_record_of) ? agent_data[:node][index] : agent.node
            pos = _get_vert_pos(model.graph, node, frame, model.record.nprops)+GeometryBasics.Vec(0.05-0.1*rand(), 0.05-0.1*rand())
            push!(posits, pos)
        end
    end
    return posits
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos(model::GraphModelFixAgNum, frame) 
    posits = Vector{GeometryBasics.Vec2{Float64}}()
    for agent in model.agents
        agent_data = unwrap_data(agent)
        index = frame 
        node = (:node in agent.keeps_record_of) ? agent_data[:node][index] : agent.node
        pos = _get_vert_pos(model.graph, node, frame, model.record.nprops)+GeometryBasics.Vec(0.05-0.1*rand(), 0.05-0.1*rand())
        push!(posits, pos)
    end
    return posits
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _create_makie_frame(ax, model::GraphModel, points, markers, colors, rotations, sizes, verts_pos, verts_dir, verts_color, show_space)
    ax.aspect = DataAspect()
    xlims!(ax, 0.0, gsize)
    ylims!(ax, 0.0, gsize)
    if show_space
        scatter!(ax, verts_pos, marker=:circle, color = verts_color)
        arrowhead = is_digraph(model.graph) ? '△'  :  '.' #\bigtriangleup<tab>
        arrows!(ax, verts_pos, verts_dir, arrowhead=arrowhead)
    end
    
    scatter!(ax, points, marker = markers, color = colors, rotations = rotations, markersize = sizes)
    return 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_vert(pos, col, node_size, neighs_pos, oriented) 

    width = gparams.width
    height = gparams.height
    w, h = width/gsize, height/gsize

    node_size = node_size*w


    posx,posy = pos

    x =  w*posx #- w/2
    y =  h*posy #-h/2
    cl = string(col)

    gsave()
    translate(-width/2, height/2)
    Luxor.transform([1 0 0 -1 0 0]) #reflects in xaxis
    ##
    translate(x,y)
    sethue(cl)
    circle(Luxor.Point(0,0), node_size, :fill)
    setline(1)
    sethue("black")
    circle(Luxor.Point(0,0), node_size, :stroke)
    grestore()

    if oriented
        for v in neighs_pos
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
            sethue("black")
            setline(1)
            arrow(Luxor.Point(x,y)+corr_point, Luxor.Point(x_v, y_v)-corr_point, arrowheadlength= 8)
            grestore()
        end
    else
        for v in neighs_pos
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
            sethue("black")
            setline(1)
            line(Luxor.Point(x,y)+corr_point, Luxor.Point(x_v, y_v)-corr_point, :stroke)
            grestore()
        end
    end
end



"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agent(agent::AgentDictGr, model::GraphModel, node_size, scl, index, frame) # the check 0<index< length(data) has been made before calling the function.
    record = agent.keeps_record_of
    agent_data = unwrap_data(agent)   
    
    width = gparams.width
    height = gparams.height
    w, h = width/gsize, height/gsize

    node_size = node_size*w


    node = (:node in record) ? agent_data[:node][index] : agent.node

    
    pos = _get_vert_pos(model.graph, node, frame, model.record.nprops) #model.graph.nodesprops[node]._extras._pos

    orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
    shape = (:shape in record) ? agent_data[:shape][index] : agent.shape
    shape_color = (:color in record) ? agent_data[:color][index] : agent.color


    size = node_size
    
    if haskey(agent_data, :size)
        size = (:size in record) ? agent_data[:size][index] : agent.size
    end
    size = size*scl
    
    posx,posy = pos

    x =  w*posx #- w/2
    y =  h*posy #-h/2
    k1 = agent._extras._id
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
    sethue(String(shape_color))             
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


"""
$(TYPEDSIGNATURES)
"""
function draw_graph(graph)
    if typeof(graph)<:SimpleGraph
        graph = create_simple_graph(graph)
    end
    if typeof(graph)<:SimpleDiGraph
        graph = create_dir_graph(graph)
    end
    verts = sort!(vertices(graph))
    if length(verts)==0
        return 
    end

    if !is_digraph(graph)
        structure = graph.structure
    else
        structure = Dict{Int, Vector{Int}}()
        for node in verts
            structure[node] = vcat(graph.in_structure[node], graph.out_structure[node]) 
        end
    end

    first_vert = verts[1]
    if !(first_vert in keys(graph.nodesprops))
        graph.nodesprops[first_vert] = PropDataDict()
    end
    if !haskey(graph.nodesprops[first_vert], :pos) && !haskey(graph.nodesprops[first_vert]._extras, :_pos)
        locs_x, locs_y = spring_layout(structure)
        for (i,vt) in enumerate(verts)
            if !(vt in keys(graph.nodesprops))
                graph.nodesprops[vt] = PropDataDict()
            end
            graph.nodesprops[vt]._extras._pos = (locs_x[i], locs_y[i])
        end
    end

    drawing = Drawing(gparams.width, gparams.height, :png)
    node_size = _get_node_size(length(verts))
    Luxor.origin()
    Luxor.background("white")
    nprops=Symbol[]
    for vert in verts
        vert_pos = _get_vert_pos(graph, vert, 1, nprops)
        vert_col = _get_vert_col(graph, vert, 1, nprops)
        out_structure = out_links(graph, vert)
        neighs_pos = [_get_vert_pos(graph, nd, 1, nprops) for nd in out_structure]
        draw_vert(vert_pos, vert_col, node_size, neighs_pos, is_digraph(graph))
    end
    finish()
    drawing
end

