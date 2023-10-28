

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos3d(graph::AbstractPropGraph{MortalType}, vert, frame, nprops) # the calling function needs to make sure that the vert is alive at given frame
    birth_time = graph.nodesprops[vert]._extras._birth_time::Int
    index = frame-birth_time +1 
    if haskey(graph.nodesprops[vert], :pos3)
        x, y, z = (:pos3 in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos3][index] : graph.nodesprops[vert].pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    else 
        x,y, z = graph.nodesprops[vert]._extras._pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    end
    return vert_pos
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_pos3d(graph::AbstractPropGraph{StaticType}, vert, frame, nprops)
    index = frame
    if haskey(graph.nodesprops[vert], :pos3)
        x,y,z = (:pos3 in nprops) ? unwrap_data(graph.nodesprops[vert])[:pos3][index] : graph.nodesprops[vert].pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    else
        x,y,z = graph.nodesprops[vert]._extras._pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    end
    return vert_pos
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_size_ratio(graph::AbstractPropGraph{MortalType}, vert, frame, nprops)
    birth_time = graph.nodesprops[vert]._extras._birth_time::Int
    index = frame-birth_time +1 

    data = unwrap_data(graph.nodesprops[vert])
    vert_size_ratio= (:size in nprops) ? data[:size][index] / (data[:size][1]+0.0001) : 1.0

    return vert_size_ratio
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_vert_size_ratio(graph::AbstractPropGraph{StaticType}, vert, frame, nprops)
    index = frame

    data = unwrap_data(graph.nodesprops[vert])
    vert_size_ratio= (:size in nprops) ? data[:size][index] / (data[:size][1]+0.0001) : 1.0
    
    return vert_size_ratio
end


function randomise_within_vert(posx, posy, posz, w, l, h, vert_size)
    x =  w*posx + 1.8*vert_size*w*(rand()-0.5) #meshcat x goes from 0 to xlen, y from 0 to ylen, z from 0 to zlen
    y =  l*posy + 1.8*vert_size*l*(rand()-0.5) 
    z =  h*posz + 1.8*vert_size*h*(rand()-0.5) 
    return x,y,z
end







"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos3d(model::GraphModelDynAgNum, graph, frame)
    posits = Vector{GeometryBasics.Vec3{Float64}}()
    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
        agent_data = unwrap_data(agent)
        if (agent._extras._birth_time::Int<= frame)&&(frame<= agent._extras._death_time::Int)
            index = frame - agent._extras._birth_time::Int +1
            node = (:node in agent._keeps_record_of::Set{Symbol}) ? agent_data[:node][index]::Int : agent.node
            pos = _get_vert_pos3d(graph, node, frame, model.record.nprops) # agent is alive and is at given node so that node must be alive; hence _get_vert_pos3d can be called. 
            push!(posits, pos)
        end
    end
    return posits
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_agents_pos3d(model::GraphModelFixAgNum, graph, frame) 
    posits = Vector{GeometryBasics.Vec3{Float64}}()
    for agent in model.agents
        agent_data = unwrap_data(agent)
        index = frame 
        node = (:node in agent._keeps_record_of::Set{Symbol}) ? agent_data[:node][index]::Int : agent.node
        pos = _get_vert_pos3d(graph, node, frame, model.record.nprops) 
        push!(posits, pos)
    end
    return posits
end



function _adjust_origin_and_draw_bounding_box_graph(vis, show_graph=true)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    t = Translation(-xlen/2, -ylen/2, 0)
    blackl = LineBasicMaterial(color=RGBA(0,0,0,1))
    settransform!(vis, t)
    setobject!(vis["/Axes/<object>"], Triad(zlen*1.5))
    settransform!(vis["/Axes/<object>"], t)
    setobject!(vis["bbox_line_segments"]["1"], MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(xlen, 0, 0.0)], blackl))
    setobject!(vis["bbox_line_segments"]["2"], MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, ylen, 0.0)], blackl))
    setobject!(vis["bbox_line_segments"]["3"], MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0.0, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["4"], MeshCat.LineSegments([MeshCat.Point(xlen, 0.0, 0),MeshCat.Point(xlen, 0.0, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["5"], MeshCat.LineSegments([MeshCat.Point(xlen, 0.0, 0),MeshCat.Point(xlen, ylen, 0.0)], blackl))
    setobject!(vis["bbox_line_segments"]["6"], MeshCat.LineSegments([MeshCat.Point(0, ylen, 0),MeshCat.Point(xlen, ylen, 0.0)], blackl))
    setobject!(vis["bbox_line_segments"]["7"], MeshCat.LineSegments([MeshCat.Point(0, ylen, 0),MeshCat.Point(0.0, ylen, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["8"], MeshCat.LineSegments([MeshCat.Point(xlen, ylen, zlen),MeshCat.Point(xlen, ylen, 0)], blackl))
    setobject!(vis["bbox_line_segments"]["9"], MeshCat.LineSegments([MeshCat.Point(xlen, ylen, zlen),MeshCat.Point(xlen, 0, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["10"], MeshCat.LineSegments([MeshCat.Point(xlen, ylen, zlen),MeshCat.Point(0, ylen, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["11"], MeshCat.LineSegments([MeshCat.Point(0, 0, zlen),MeshCat.Point(0, ylen, zlen)], blackl))
    setobject!(vis["bbox_line_segments"]["12"], MeshCat.LineSegments([MeshCat.Point(0, 0, zlen),MeshCat.Point(xlen, 0, zlen)], blackl))
 
    return   
end

const _vert_opacity =0.2
function _dim_vert_col(col)
    clr = col.val
    return Col(clr.r, clr.g, clr.b, _vert_opacity)
end

function draw_nodes_and_edges_static(vis, model::GraphModel, graph, verts, edges, node_size, show_nodes=true, show_edges=true)
    nrecord = model.record.nprops
    erecord = model.record.eprops
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    directed = is_directed(model.graph)
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    if show_nodes
        for vt in verts
            vert = graph.nodesprops[vt]
            data = unwrap_data(vert)
            clrs = (:color in nrecord) ? unique(data[:color]::Vector{Col}) : (haskey(vert, :color) ? [vert.color::Col] : [_default_vert_color])
            size = (:size in nrecord) ? data[:size][1] : (haskey(vert, :size) ? vert.size : node_size)
            clrsmat = [_dim_vert_col(x) for x in clrs]
            vert._extras._colors = clrs
            materials = [MeshPhongMaterial(color=cl.val) for cl in clrsmat]
            sphere = HyperSphere(MeshCat.Point(0,0,0.0), size)

            for (s, cl) in enumerate(clrs)
                clnm = string(cl)
                setobject!(vis["nodes"]["$vt"][clnm],sphere,materials[s])
                setvisible!(vis["nodes"]["$vt"][clnm], false)
            end

        end
    end


    if show_edges
        for ed in edges
            edge = graph.edgesprops[ed]
            data = unwrap_data(edge)
            clrs = (:color in erecord) ? unique(data[:color]::Vector{Col}) : (haskey(edge, :color) ? [edge.color::Col] : [_default_edge_color])
            edge._extras._colors = clrs
            materials = [LineBasicMaterial(color=cl.val) for cl in clrs]
            
            if !(directed)
                for (s, cl) in enumerate(clrs)
                    clnm = string(cl)
                    setobject!(vis["edges"]["$ed"][clnm],MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0, 1.0)], materials[s])) 
                    setvisible!(vis["edges"]["$ed"][clnm], false)
                end
            else
                for (s, cl) in enumerate(clrs)
                    clnm = string(cl)
                    setobject!(vis["edges"]["$ed"][clnm]["1"],MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0, 1.0)], materials[s])) 
                    setobject!(vis["edges"]["$ed"][clnm]["2"],MeshCat.LineSegments([MeshCat.Point(-0.07, 0, 0.9),MeshCat.Point(0, 0, 1.0)], materials[s])) 
                    setobject!(vis["edges"]["$ed"][clnm]["3"],MeshCat.LineSegments([MeshCat.Point(0.07, 0, 0.9),MeshCat.Point(0, 0, 1.0)], materials[s])) 
                    setvisible!(vis["edges"]["$ed"][clnm], false)
                end

            end

        end
    end
 

end

# for cylinder shaped arrows
# clnm = string(cl)
# arrow = ArrowVisualizer(vis["edges"]["$ed"][clnm])
# setobject!(arrow, materials[s])  
# setvisible!(vis["edges"]["$ed"][clnm], false)
# ## later for transforming do settransform!(ArrowVisualizer(vis["edges"]["$ed"][clnm]), Point(0.0, 0.0, 0.0), Vec(2, 1, 1.0))


function draw_graph_agents_static(vis, model, graph, all_agents, node_size)
    if length(all_agents)==0
        return
    end
    index=1
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    nrecord = model.record.nprops
    node_size = node_size*w

    for agent in all_agents
        record = agent._keeps_record_of::Set{Symbol}
        agent_data = unwrap_data(agent) 
        node_pos = (:node in record) ? agent_data[:node][index]::Int : agent.node
        vert_size = _get_vert_size(graph, node_pos, 1, nrecord,node_size)
        vert = graph.nodesprops[node_pos]
        pos = (:pos3 in nrecord) ? unwrap_data(vert)[:pos3][index] : (haskey(vert, :pos3) ? vert.pos3 : vert._extras._pos3)
        orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
        pclr = (:color in record) ? agent_data[:color][index]::Col : agent.color::Col
        size = (:size in record) ? agent_data[:size][index]::Union{Int, <:Float64} : agent.size::Union{Int, <:Float64}
        pshp = (:shape in record) ? agent_data[:shape][index]::Symbol : agent.shape::Symbol
    
    
        ao,bo,co = orientation
        if ao^2+bo^2+co^2 < 0.00001
            ao = 0.001
        end
    
    
        posx,posy,posz = pos # posx in range 0 to xdim, posy in range 0 to ydim, posz in range 0 to zdim. Default values of xdim, ydim, zdim are 10,10,10
        
        x,y,z= randomise_within_vert(posx,posy,posz,w,l,h,vert_size)

        vert_size = vert_size*w

        clrs = (:color in record) ? unique(agent_data[:color]::Vector{Col}) : [agent.color::Col]
        shps = (:shape in record) ? unique(agent_data[:shape]::Vector{Symbol}) : [agent.shape::Symbol]
        agent._extras._colors = clrs
        clrs_rgb = [cl.val for cl in clrs]
        materials = [MeshPhongMaterial(color=cl) for cl in clrs_rgb]
        size = size*vert_size/100 # 

        if !(pshp in keys(shapefunctions3d))
            pshp = :cone
        end

        shapes=Symbol[]
        for sh in shps
            if !(sh in keys(shapefunctions3d))
                push!(shapes, :cone)
            else
                push!(shapes, sh)
            end 
        end 
        shapes = unique(shapes)
        agent._extras._shapes = shapes
        for sh in shapes
            shape_rendered = shapefunctions3d[sh](size)
            for (i, cl) in enumerate(clrs)
                clnm = string(cl)
                setobject!(vis["agents"]["$(getfield(agent, :id))"*string(sh)][clnm],shape_rendered,materials[i]) 
                setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(sh)][clnm], false)
            end
        end

        trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0)))

        for sh in shapes
            settransform!(vis["agents"]["$(getfield(agent, :id))"*string(sh)], trans)
        end

        setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(pshp)][string(pclr)], true)

    end

end


function draw_agent3dgraph(vis, agent, model, graph, scl, index, frame, node_size, w, l, h)
    record = agent._keeps_record_of::Set{Symbol}
    nrecord = model.record.nprops
    agent_data = unwrap_data(agent)
    node_pos = (:node in record) ? agent_data[:node][index]::Int : agent.node
    vert_size = _get_vert_size(graph, node_pos, frame, nrecord,node_size)
    pos = _get_vert_pos3d(graph,node_pos,frame,nrecord) # agebt is alive and is at given node; therefore node must be alive; hence _get_vert_pos3d can be called
    #nextpos = (:pos in record)&&(index<model.tick) ? agent_data[:pos][index+1]::Vect{3, S} .+ offset : agent.pos .+ offset
    orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
    pclr = (:color in record) ? agent_data[:color][index]::Col : agent.color::Col
    pshp = (:shape in record) ? agent_data[:shape][index]::Symbol : agent.shape::Symbol
    clrs = agent._extras._colors::Vector{Col}
    shps = agent._extras._shapes::Vector{Symbol}
    sc = (:size in record) ? agent_data[:size][index]::Union{Int, <:Float64}/(agent_data[:size][1]::Union{Int, <:Float64}+0.0001)  : 1.0 # scale
    sc = sc*scl
    ao,bo,co = orientation
    if ao^2+bo^2+co^2 < 0.00001
        ao = 0.001
    end

    posx,posy,posz = pos

    
    x,y,z= randomise_within_vert(posx,posy,posz,w,l,h,vert_size)

    if !(pshp in keys(shapefunctions3d))
        pshp = :cone
    end

    for sh in shps
        for cl in clrs
            setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(sh)][string(cl)], false)
        end
    end
    
    trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0)))
    for sh in shps
        settransform!(vis["agents"]["$(getfield(agent, :id))"*string(sh)], trans)
        setprop!(vis["agents"]["$(getfield(agent, :id))"*string(sh)], "scale", MeshCat.Vec(sc, sc, sc))
    end
    #settransform!(vis["agents"]["$(getfield(agent, :id))"], Translation(x, y, z))
    #setprop!(vis["agents"]["$(getfield(agent, :id))"], "position", MeshCat.Vec(x,y,z))
    #if (!periodic) || condition
    setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(pshp)][string(pclr)], true)
    #end
end

function draw_vert3d(vis, graph, vert, pos, col, sc, outs, all_outs, neighs_pos, neighs_sizes, edge_cols, w, l, h, show_nodes=true, show_edges=true)
    # sc = (:size in record) ? agent_data[:size][index]::Union{Int, <:Float64}/(agent_data[:size][1]::Union{Int, <:Float64})  : 1.0 # scale

    posx,posy,posz = pos


    x =  w*posx #- w/2
    y =  l*posy #-h/2
    z =  h*posz

    if show_nodes

        clrs = graph.nodesprops[vert]._extras._colors
        for clr in clrs
            setvisible!(vis["nodes"]["$vert"][string(clr)], false) 
        end
        trans = Translation(x, y, z) 
        settransform!(vis["nodes"]["$vert"], trans)
        setprop!(vis["nodes"]["$vert"], "scale", MeshCat.Vec(sc, sc, sc))
        #setprop!(vis["agents"]["$(getfield(agent, :id))"*string(sh)], "scale", MeshCat.Vec(sc, sc, sc))
        setvisible!(vis["nodes"]["$vert"][string(col)], true)
    end
    
    if show_edges
        outs=collect(outs)
        all_outs=collect(all_outs)

        for nd in all_outs
            if nd in outs
                ind = findfirst(x->x==nd, outs)
                edge = (vert, nd)
                v = neighs_pos[ind]
                posvx, posvy, posvz = v
                vx, vy, vz = w*posvx, l*posvy, h*posvz 
                ecols = graph.edgesprops[edge]._extras._colors
                sca = sqrt((x-vx)^2+(y-vy)^2+(z-vz)^2) #rotation_between can't have zero vecs
                if sca< 0.00001
                    vx = x + 0.001
                    sca = 0.001
                end
                trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1.0), MeshCat.Vec(vx-x,vy-y,vz-z)))
                for clr in ecols
                    setvisible!(vis["edges"]["$edge"][string(clr)], false) 
                end
                settransform!(vis["edges"]["$edge"], trans)
                setprop!(vis["edges"]["$edge"], "scale", MeshCat.Vec(sca, sca, sca)) 
                setvisible!(vis["edges"]["$edge"][string(edge_cols[ind])], true)
            else
                edge = (vert, nd)
                ecols = graph.edgesprops[edge]._extras._colors
                for clr in ecols
                    setvisible!(vis["edges"]["$edge"][string(clr)], false) 
                end
            end
        end
    end
end
##############
@inline function draw_agent_interact_frame(vis, agent::GraphAgent, model::GraphModel, graph, node_size, index::Int, frame, w, l, h)
    record = agent._keeps_record_of::Set{Symbol}
    agent_data = unwrap_data(agent)
    node_pos = (:node in record) ? agent_data[:node][index]::Int : agent.node
    vert_size = _get_vert_size(graph, node_pos, frame, model.record.nprops,node_size)
    pos = _get_vert_pos3d(graph,node_pos,frame,model.record.nprops)
    orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
    pclr = (:color in record) ? agent_data[:color][index]::Col : agent.color::Col
    pshp = (:shape in record) ? agent_data[:shape][index]::Symbol : agent.shape::Symbol
    size = (:size in record) ? agent_data[:size][index]::Union{Int, <:Float64} : agent.size::Union{Int, <:Float64}

    ao,bo,co = orientation
    if ao^2+bo^2+co^2 < 0.00001
        ao = 0.001
    end
    
    posx,posy,posz = pos
    
    x,y,z= randomise_within_vert(posx,posy,posz,w,l,h,vert_size)

    vert_size = vert_size*w


    material = MeshPhongMaterial(color=pclr.val) 
        
    size = size*vert_size/100

    if !(pshp in keys(shapefunctions3d))
        pshp = :cone
    end

    shape_rendered = shapefunctions3d[pshp](size)
    
    setobject!(vis["agents"]["$(getfield(agent, :id))"],shape_rendered,material) 
    settransform!(vis["agents"]["$(getfield(agent, :id))"], LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0))))
    setprop!(vis["agents"]["$(getfield(agent, :id))"], "position", MeshCat.Vec(x,y,z))
end

#################
"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_agents_interact_frame(vis, model::GraphModelDynAgNum,graph, node_size, frame)
    all_agents = vcat(model.agents, model.agents_killed)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    for agent in all_agents
        if (agent._extras._birth_time::Int<= frame)&&(frame<= agent._extras._death_time::Int)
            index = frame- agent._extras._birth_time::Int+1
            draw_agent_interact_frame(vis, agent, model, graph, node_size, index, frame, w, l, h)
        end
    end

end

@inline function _draw_agents_interact_frame(vis, model::GraphModelFixAgNum, graph, node_size, frame)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    for agent in model.agents
        draw_agent_interact_frame(vis, agent, model, graph, node_size, frame, frame, w, l, h)
    end
end

####################################

function draw_vert_interact_frame(vis, vert, vert_pos, vert_col, vert_size, outs, neighs_pos, neighs_sizes, directed, edge_cols, w, l, h, show_nodes=true, show_edges=true)
    posx,posy,posz = vert_pos
    x,y,z = posx*w, posy*l, posz*h
    if show_nodes
        vert_col = _dim_vert_col(vert_col)
        material = MeshPhongMaterial(color=vert_col.val)
        sphere = HyperSphere(MeshCat.Point(0,0,0.0), vert_size)
        setobject!(vis["nodes"]["$vert"],sphere,material)
        trans = Translation(x, y, z) 
        settransform!(vis["nodes"]["$vert"],trans)
    end

    if show_edges

        outs=collect(outs)

        for ind in 1:length(neighs_pos)
            edge = (vert, outs[ind])
            v = neighs_pos[ind]
            posvx, posvy, posvz = v
            vx, vy, vz = w*posvx, l*posvy, h*posvz   
            sca = sqrt((x-vx)^2+(y-vy)^2+(z-vz)^2) #rotation_between can't have zero vecs
            if sca< 0.00001
                vx = x + 0.001
                sca = 0.001
            end
            ecol = edge_cols[ind]
            mat = LineBasicMaterial(color=ecol.val)

            if !(directed)
                setobject!(vis["edges"]["$edge"],MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0, 1.0)], mat)) 

            else
                setobject!(vis["edges"]["$edge"]["1"],MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0, 1.0)], mat)) 
                setobject!(vis["edges"]["$edge"]["2"],MeshCat.LineSegments([MeshCat.Point(-0.07, 0, 0.9),MeshCat.Point(0, 0, 1.0)], mat)) 
                setobject!(vis["edges"]["$edge"]["3"],MeshCat.LineSegments([MeshCat.Point(0.07, 0, 0.9),MeshCat.Point(0, 0, 1.0)], mat)) 

            end
            trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1.0), MeshCat.Vec(vx-x,vy-y,vz-z)))
            settransform!(vis["edges"]["$edge"], trans)
            setprop!(vis["edges"]["$edge"], "scale", MeshCat.Vec(sca, sca, sca)) 

        end
    end

end

function _draw_da_vert_interact_frame(vis, graph::AbstractPropGraph{MortalType}, vert, node_size, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true) 
    vert_pos = _get_vert_pos3d(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)    
    vert_size=_get_vert_size(graph, vert, frame, nprops, node_size)
    out_structure = out_links(graph, vert) # each node nd in out_links(vert) is > vert for simple graph. 
    active_out_structure, indices = _get_active_out_structure(graph, vert, out_structure, frame) # indices[i] is the index to be used for accessing any recorded property of the edge from vert to active_out_structure[i] corresponding to given frame
    neighs_pos = [_get_vert_pos3d(graph, nd, frame, nprops) for nd in active_out_structure]
    neighs_sizes = [_get_vert_size(graph, nd, frame, nprops, node_size) for nd in active_out_structure]
    edge_cols = [_get_edge_col(graph, vert, active_out_structure[i], indices[i], eprops) for i in 1:length(indices)]
    draw_vert_interact_frame(vis, vert, vert_pos, vert_col, vert_size, active_out_structure, neighs_pos, neighs_sizes, is_digraph(graph), edge_cols, w, l, h, show_nodes, show_edges)
end

function _draw_da_vert_interact_frame(vis, graph::AbstractPropGraph{StaticType}, vert, node_size, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true) 
    vert_pos = _get_vert_pos3d(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    
    vert_size=_get_vert_size(graph, vert, frame, nprops, node_size)

    out_structure = out_links(graph, vert) # each node nd in out_links(vert) is > vert for simple graph. 
    neighs_pos = [_get_vert_pos3d(graph, nd, frame, nprops) for nd in out_structure]
    neighs_sizes = [_get_vert_size(graph, nd, frame, nprops, node_size) for nd in out_structure]
    edge_cols = [_get_edge_col(graph, vert, nd, frame, eprops) for nd in out_structure] 
    draw_vert_interact_frame(vis, vert, vert_pos, vert_col, vert_size, out_structure, neighs_pos, neighs_sizes, is_digraph(graph), edge_cols, w, l, h, show_nodes, show_edges)
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph_interact_frame(vis, graph::AbstractPropGraph{MortalType}, verts, node_size, frame, nprops, eprops, show_nodes=true, show_edges=true)
    alive_verts = verts[[(graph.nodesprops[nd]._extras._birth_time::Int <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time::Int) for nd in verts]]
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    for vert in alive_verts
        _draw_da_vert_interact_frame(vis, graph, vert, node_size, frame, nprops, eprops, w, l, h, show_nodes, show_edges) 
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_graph_interact_frame(vis, graph::AbstractPropGraph{StaticType}, verts, node_size, frame, nprops, eprops, show_nodes=true, show_edges=true)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize
    for vert in verts
        _draw_da_vert_interact_frame(vis, graph, vert, node_size, frame, nprops, eprops, w, l, h, show_nodes, show_edges) 
    end
end






####################################################
####################################################

"""
$(TYPEDSIGNATURES)
"""
function _draw_da_vert3d(vis, graph::AbstractPropGraph{MortalType}, vert, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true)
    vert_pos = _get_vert_pos3d(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)    
    vert_size=_get_vert_size_ratio(graph, vert, frame, nprops)
    out_structure = out_links(graph, vert) # each node nd in out_links(vert) is > vert for simple graph. 
    active_out_structure, indices = _get_active_out_structure(graph, vert, out_structure, frame) # indices[i] is the index to be used for accessing any recorded property of the edge from vert to active_out_structure[i] corresponding to given frame
    neighs_pos = [_get_vert_pos3d(graph, nd, frame, nprops) for nd in active_out_structure]
    neighs_sizes = [_get_vert_size_ratio(graph, nd, frame, nprops) for nd in active_out_structure]
    edge_cols = [_get_edge_col(graph, vert, active_out_structure[i], indices[i], eprops) for i in 1:length(indices)]
    draw_vert3d(vis,graph, vert, vert_pos, vert_col, vert_size, active_out_structure,out_structure, neighs_pos, neighs_sizes, edge_cols, w, l, h, show_nodes, show_edges)
end

function _draw_da_vert3d(vis, graph::AbstractPropGraph{StaticType}, vert, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true)
    vert_pos = _get_vert_pos3d(graph, vert, frame, nprops)
    vert_col = _get_vert_col(graph, vert, frame, nprops)
    
    vert_size=_get_vert_size_ratio(graph, vert, frame, nprops)

    out_structure = out_links(graph, vert) # each node nd in out_links(vert) is > vert for simple graph. 
    neighs_pos = [_get_vert_pos3d(graph, nd, frame, nprops) for nd in out_structure]
    neighs_sizes = [_get_vert_size_ratio(graph, nd, frame, nprops) for nd in out_structure]
    edge_cols = [_get_edge_col(graph, vert, nd, frame, eprops) for nd in out_structure] 
    draw_vert3d(vis,graph, vert, vert_pos, vert_col, vert_size, out_structure, out_structure, neighs_pos, neighs_sizes, edge_cols, w, l, h, show_nodes, show_edges)
end

"""
$(TYPEDSIGNATURES)
"""
function _draw_graph3d(vis, graph::AbstractPropGraph{MortalType}, verts, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true)
    # alive_verts = verts[[(graph.nodesprops[nd]._extras._birth_time::Int <=frame)&&(frame<=graph.nodesprops[nd]._extras._death_time::Int) for nd in verts]]
    # for vert in alive_verts
    #     _draw_da_vert3d(vis, graph, vert, frame, nprops, eprops, w, l, h) 
    # end

    for vert in verts
        if (graph.nodesprops[vert]._extras._birth_time::Int <=frame)&&(frame<=graph.nodesprops[vert]._extras._death_time::Int)
            _draw_da_vert3d(vis, graph, vert, frame, nprops, eprops, w, l, h, show_nodes, show_edges) 
        else
            if show_nodes
                clrs = graph.nodesprops[vert]._extras._colors
                for clr in clrs
                    setvisible!(vis["nodes"]["$vert"][string(clr)], false) 
                end
            end
        end
    end

end


"""
$(TYPEDSIGNATURES)
"""
function _draw_graph3d(vis, graph::AbstractPropGraph{StaticType}, verts, frame, nprops, eprops, w, l, h, show_nodes=true, show_edges=true)
    for vert in verts
        _draw_da_vert3d(vis, graph, vert, frame, nprops, eprops, w, l, h, show_nodes, show_edges) 
    end
end

"""
$(TYPEDSIGNATURES)
"""
function draw_agents_and_graph3d(vis, model::GraphModelDynAgNum, graph, verts, frame, scl, node_size, show_nodes=true, show_edges=true)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize

    if model.parameters._extras._show_space::Bool
        _draw_graph3d(vis, graph, verts, frame, model.record.nprops, model.record.eprops, w, l, h, show_nodes, show_edges)
    end

    all_agents = vcat(model.agents, model.agents_killed)

    for agent in all_agents
        if (agent._extras._birth_time::Int <= frame)&&(frame<= agent._extras._death_time::Int)
            draw_agent3dgraph(vis, agent, model, graph, scl, frame - agent._extras._birth_time::Int + 1, frame, node_size, w, l, h)
        else
            #if haskey(agent._extras, :_shapes) && haskey(agent._extras, :_colors) # this will be true if all agents are drawn initially which is true for animate_sim and create_interactive_app
            clrs = agent._extras._colors::Vector{Col}
            shps = agent._extras._shapes::Vector{Symbol}
            for sh in shps
                for cl in clrs
                    setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(sh)][string(cl)], false)
                end
            end
        #end
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_graph3d(vis, model::GraphModelFixAgNum, graph, verts, frame, scl, node_size, show_nodes=true, show_edges=true)
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize

    if model.parameters._extras._show_space::Bool
        _draw_graph3d(vis, graph, verts, frame, model.record.nprops, model.record.eprops, w, l, h, show_nodes, show_edges)
    end


    for agent in model.agents
       draw_agent3dgraph(vis, agent, model, graph, scl, frame, frame, node_size, w, l, h)
    end
end

#########################

function _get_vert_pos3d_isolated_graph(graph, vert)
    if haskey(graph.nodesprops[vert], :pos3)
        x,y,z = graph.nodesprops[vert].pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    else
        x,y,z = graph.nodesprops[vert]._extras._pos3
        vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    end
    return vert_pos
end

function _get_vert_pos3d_isolated_graph_internal(graph, vert)
    x,y,z = graph.nodesprops[vert]._extras._pos3
    vert_pos = GeometryBasics.Vec(Float64(x),y,z)
    return vert_pos
end

"""
$(TYPEDSIGNATURES)
"""
function draw_graph3d(graph; use_internal_layout=false, vis::Any=nothing, show_nodes=true, show_edges=true)
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

    node_size = _get_node_size(length(verts))

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
    if !haskey(graph.nodesprops[first_vert], :pos3) && !haskey(graph.nodesprops[first_vert]._extras, :_pos3) ##?##
        locs_x, locs_y, locs_z = spring_layout3d(structure)
        for (i,vt) in enumerate(verts)
            if !(vt in keys(graph.nodesprops))
                graph.nodesprops[vt] = ContainerDataDict()
            end
            graph.nodesprops[vt]._extras._pos3 = (locs_x[i], locs_y[i], locs_z[i])
        end
    end

    _function_for_pos = use_internal_layout ? _get_vert_pos3d_isolated_graph_internal : _get_vert_pos3d_isolated_graph

    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/gsize
    l = ylen/gsize
    h = zlen/gsize

    if isnothing(vis)
        vis=Visualizer()
    end 

    _adjust_origin_and_draw_bounding_box_graph(vis)

    directed = is_digraph(graph)

    vert_col = nothing
    vert_size = nothing
    out_structure = nothing
    neighs_pos = nothing
    neighs_sizes = nothing
    edge_cols = nothing


    for vert in verts
        vert_pos = _function_for_pos(graph, vert)
        if show_nodes
            vert_col = _get_vert_col_isolated_graph(graph, vert)
            vert_size = _get_vert_size_isolated_graph(graph, vert, node_size)
        end
        if show_edges
            out_structure = out_links(graph, vert)
            neighs_pos = [_get_vert_pos3d_isolated_graph(graph, nd) for nd in out_structure]
            neighs_sizes = [_get_vert_size_isolated_graph(graph, nd, node_size) for nd in out_structure]
            edge_cols =  [_get_edge_col_isolated_graph(graph, vert, nd) for nd in out_structure]
        end
        draw_vert_interact_frame(vis, vert, vert_pos, vert_col, vert_size, out_structure, neighs_pos, neighs_sizes, directed, edge_cols, w, l, h, show_nodes, show_edges)
    end
    render(vis)

end

#########################



"""
$(TYPEDSIGNATURES)

Creates an animation from the data collected during model run.
"""
function animate_sim3d(model::GraphModel, frames::Int=model.tick; 
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    node_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    model_plots::Vector{Symbol} = Symbol[],
    plots_only = false, 
    show_graph = true, vis::Any=nothing,
    show_nodes=true, show_edges=true)

    ticks = getfield(model, :tick)[]
    model.parameters._extras._show_space = show_graph
    graph = is_static(model.graph) ? model.graph : combined_graph(model.graph, model.dead_meta_graph)
    fr = min(frames, ticks)
    verts = getfield(graph, :_nodes)
    edges = keys(graph.edgesprops)
    node_size = _get_node_size(model.parameters._extras._num_verts::Int)

    no_graphics = plots_only || !(model.graphics)

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    _save_sim = _does_nothing

    if isnothing(vis) 
        vis=Visualizer()
    end

    if !(no_graphics)
        _adjust_origin_and_draw_bounding_box_graph(vis, true)
        if show_graph
            draw_nodes_and_edges_static(vis,model,graph, verts, edges, node_size, show_nodes, show_edges)
        end
        all_agents = _get_all_agents(model)
        draw_graph_agents_static(vis, model, graph, all_agents, node_size)
    end

    labels = String[]
    conditions = Function[]
    for (lbl, cond) in agent_plots
        push!(labels, lbl)
        push!(conditions, cond)
    end
    agent_df = get_agents_avg_props(model, conditions..., labels= labels)

    labels = String[]
    conditions = Function[]
    for (lbl, cond) in node_plots
        push!(labels, lbl)
        push!(conditions, cond)
    end

    node_df = get_agents_avg_props(model, conditions..., labels= labels)
    model_df = get_model_data(model, model_plots).record

    function _draw_frame(t, scl)
        draw_agents_and_graph3d(vis, model, graph, verts, t, scl, node_size, show_nodes, show_edges)
    end

    function _render_trivial(s)
        return render(vis)
    end
    
    if no_graphics
        _draw_frame = _does_nothing
        _render_trivial = _does_nothing
    end

    _interactive_app(model, fr, no_graphics, _save_sim, _draw_frame,
    agent_df, DataFrame(), node_df, model_df, _render_trivial)
end


"""
$(TYPEDSIGNATURES)

Draws a specific frame.
"""
function draw_frame3d(model::GraphModel; frame=model.tick, show_graph=true, vis::Any=nothing, show_nodes=true, show_edges=true)
    frame = min(frame, model.tick)
    model.parameters._extras._show_space = show_graph
    graph = is_static(model.graph) ? model.graph : combined_graph(model.graph, model.dead_meta_graph)
    verts = getfield(graph, :_nodes)
    node_size = _get_node_size(model.parameters._extras._num_verts::Int)
    
    if isnothing(vis) 
        vis=Visualizer()
    end
    delete!(vis)
    _adjust_origin_and_draw_bounding_box_graph(vis)

    if show_graph
        _draw_graph_interact_frame(vis, graph ,verts, node_size, frame, model.record.nprops, model.record.eprops, show_nodes, show_edges)
    end

    _draw_agents_interact_frame(vis, model, graph, node_size, frame)

    render(vis)
end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app3d(model::GraphModel; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Set{Symbol}} = Dict{String, Set{Symbol}}("agents"=>Set{Symbol}([]), "nodes"=>Set{Symbol}([]), "edges"=>Set{Symbol}([]), "model"=>Set{Symbol}([])),
    step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), #initialiser will override the changes made
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(),
    node_plots::Dict{String, <:Function} = Dict{String, Function}(),
    model_plots::Vector{Symbol} = Symbol[],
    plots_only = false,
    frames=200, show_graph=true, vis::Any=nothing, show_nodes=true, show_edges=true) 
    
    # if !is_static(model.graph)
    #     combined_graph!(model.graph, model.dead_meta_graph)
    #     empty!(model.dead_meta_graph)
    # end

    model.parameters._extras._show_space = show_graph

    no_graphics = plots_only || !(model.graphics)

    node_size = Ref(_get_node_size(model.parameters._extras._num_verts::Int))


    init_model!(model, initialiser=initialiser, props_to_record = props_to_record)

    #copy_agents = deepcopy(model.agents)
    function _run_interactive_model(t)
        run_model!(model, steps=t, step_rule=step_rule)
    end

    graph = Ref(model.graph)

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    _save_sim = _does_nothing

    if isnothing(vis) 
        vis=Visualizer()
    end

    if !(no_graphics)
        _adjust_origin_and_draw_bounding_box_graph(vis, true)
    end


    lblsa = String[]
    condsa = Function[]
    for (lbl, cond) in agent_plots
        push!(lblsa, lbl)
        push!(condsa, cond)
    end

    lblsp = String[]
    condsp = Function[]
    for (lbl, cond) in node_plots
        push!(lblsp, lbl)
        push!(condsp, cond)
    end



    function _init_interactive_model(ufun::Function = x -> nothing)
        ufun(model)
        init_model!(model, initialiser=initialiser, props_to_record = props_to_record)
        ufun(model)
        _run_interactive_model(frames)
        if !is_static(model.graph)
            graph[] = combined_graph(model.graph, model.dead_meta_graph)
        else
            graph[] = model.graph
        end
        node_size[] = _get_node_size(model.parameters._extras._num_verts::Int)
        verts = getfield(graph[], :_nodes)
        edges = keys(graph[].edgesprops)

        if !(no_graphics)
            delete!(vis["agents"])
            if show_graph
                delete!(vis["edges"])
                delete!(vis["nodes"])
                draw_nodes_and_edges_static(vis,model,graph[], verts, edges, node_size[], show_nodes, show_edges)
            end
            all_agents = _get_all_agents(model)
            draw_graph_agents_static(vis, model,graph[], all_agents, node_size[])
        end
        agent_df = get_agents_avg_props(model, condsa..., labels= lblsa)
        node_df = get_nodes_avg_props(model, condsp..., labels= lblsp)
        model_df = get_model_data(model, model_plots).record
        return agent_df, DataFrame(), node_df, model_df
    end

    agent_df, patch_df, node_df, model_df= DataFrame(), DataFrame(), DataFrame(), DataFrame() #_init_interactive_model()

    function _draw_interactive_frame(t, scl)
        verts = getfield(graph[], :_nodes)
        draw_agents_and_graph3d(vis, model, graph[], verts, t, scl, node_size[], show_nodes, show_edges)
    end

    function _render_trivial(s)
        return render(vis)
    end

    if no_graphics
        _draw_interactive_frame = _does_nothing
        _render_trivial = _does_nothing
    end

    _live_interactive_app(model, frames, no_graphics, _save_sim, _init_interactive_model, 
    _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls, 
    agent_df, _render_trivial, patch_df, node_df, model_df)

end

