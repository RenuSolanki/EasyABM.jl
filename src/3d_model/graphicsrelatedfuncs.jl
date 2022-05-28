const _palpha = 0.1
const _aalpha = 0.9
const _colors = [:white, :black, :red, :green, :blue, :yellow, :grey, :orange, :purple]
const bounding_box_color = RGBA(0, 0, 1, _palpha)
const patchwhite  = RGBA(1, 1, 1, _palpha)
const patchblack  = RGBA(0, 0, 0, _palpha)
const patchred    = RGBA(1, 0, 0, _palpha)
const patchgreen  = RGBA(0, 1, 0, _palpha)
const patchblue   = RGBA(0, 0, 1, _palpha)
const patchyellow = RGBA(1, 1, 0, _palpha)
const patchgrey   = RGBA(0.5,  0.5,  0.5,  _palpha)
const patchorange = RGBA(1.0,  0.65, 0.0,  _palpha)
const patchpurple = RGBA(0.93, 0.51, 0.93, _palpha)

const agentwhite  = RGBA(1, 1, 1, _aalpha)
const agentblack  = RGBA(0, 0, 0, _aalpha)
const agentred    = RGBA(1, 0, 0, _aalpha)
const agentgreen  = RGBA(0, 1, 0, _aalpha)
const agentblue   = RGBA(0, 0, 1, _aalpha)
const agentyellow = RGBA(1, 1, 0, _aalpha)
const agentgrey   = RGBA(0.5,  0.5,  0.5,  _aalpha)
const agentorange = RGBA(1.0,  0.65, 0.0,  _aalpha)
const agentpurple = RGBA(0.93, 0.51, 0.93, _aalpha)

@inline function _adjust_origin_and_draw_bounding_box(vis, show_grid)
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
    
end


@inline function draw_patches_static(vis, model::GridModel3D)
    record = model.record.pprops
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim
    g = min(0.05,w/20, l/20, h/20)
    # redl = LineBasicMaterial(color=RGBA(1,0,0,1))
    # greenl = LineBasicMaterial(color=RGBA(0,1,0,1))
    # bluel = LineBasicMaterial(color=RGBA(0,0,1,1))
    blackl = LineBasicMaterial(color=RGBA(0,0,0,1))
 
    for k in 0:model.size[3]
        z=h*k
        for j in 0:model.size[2]
            y =  l*j
            #setobject!(vis["line_segments"]["yz($j,$k)"], MeshCat.LineSegments([MeshCat.Point(0.0, y, z),MeshCat.Point(xlen, y, z)], blackl))
            for i in 0:model.size[1]
                x =  w*i
                #setobject!(vis["line_segments"]["zx($k,$i)"], MeshCat.LineSegments([MeshCat.Point(x, 0.0, z),MeshCat.Point(x, ylen, z)], blackl))
                #setobject!(vis["line_segments"]["xy($i,$j)"], MeshCat.LineSegments([MeshCat.Point(x, y, 0.0),MeshCat.Point(x, y, zlen)], blackl))
                if (i>0)&&(j>0)&&(k>0)
                    patch = model.patches[i,j,k]
                    patch_data = unwrap_data(patch)
                    clrs = (:color in record) ? unique(patch_data[:color]) : [patch.color]
                    patch._extras._colors = clrs
                    clrs_rgb = [eval(Symbol("patch"*string(cl))) for cl in clrs]
                    materials = [MeshPhongMaterial(color=cl) for cl in clrs_rgb]
                    box = HyperRectangle(MeshCat.Vec(x-w+g,y-l+g,z-h+g), MeshCat.Vec(w-g,l-g,h-g))

                    for (s, cl) in enumerate(clrs)
                        setobject!(vis["patches"]["($i,$j,$k)"][cl],box,materials[s])
                        if (:color in model.record.pprops)
                            setvisible!(vis["patches"]["($i,$j,$k)"][cl], false)
                        end
                    end  

                end      
            end
        end
    end

end

function draw_tail(vis, agent, tail_length)
    for i in 1:tail_length
        bluel = LineBasicMaterial(color=RGBA(0,0,1,tail_opacity(i, tail_length)))
        setobject!(vis["tails"]["$(agent._extras._id)"]["$i"],MeshCat.LineSegments([MeshCat.Point(0.0, 0, 0),MeshCat.Point(0, 0, 1.0)], bluel)) 
        setvisible!(vis["tails"]["$(agent._extras._id)"]["$i"], false)
    end
end

@inline function draw_agents_static(vis, model::GridModel3D, all_agents, tail_length = 1,  tail_condition = agent -> false)
    
    if length(all_agents)==0
        return
    end

    index=1

    periodic = model.periodic
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim 



    for agent in all_agents
        record = agent.keeps_record_of
        agent_data = unwrap_data(agent)
        pos = (:pos in record) ? agent_data[:pos][index] : agent.pos
        orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
        pclr = (:color in record) ? agent_data[:color][index] : agent.color
    
    
        ao,bo,co = orientation
    
    
        posx,posy,posz = pos

        if periodic
            posx  = mod1(posx, xdim)
            posy  = mod1(posy, ydim)
            posz  = mod1(posz, zdim)
        end
        
        x =  w*posx 
        y =  l*posy 
        z =  h*posz

        shape = agent.shape
        clrs = (:color in record) ? unique(agent_data[:color]) : [agent.color]
        agent._extras._colors = clrs
        clrs_rgb = [eval(Symbol("agent"*string(cl))) for cl in clrs]
        materials = [MeshPhongMaterial(color=cl) for cl in clrs_rgb]


        size = 0.3

        if haskey(agent_data, :size)
            size = (:size in record) ? agent_data[:size][index] : agent.size
        end

        if !(shape in [:sphere, :box, :cone, :cylinder])
            shape = :cone
        end

        shape_rendered = shapefunctions3d[shape](size)
        for (i, cl) in enumerate(clrs)
            setobject!(vis["agents"]["$(agent._extras._id)"][cl],shape_rendered,materials[i]) 
            setvisible!(vis["agents"]["$(agent._extras._id)"][cl], false)
        end

        trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0)))
        settransform!(vis["agents"]["$(agent._extras._id)"], trans)
        setvisible!(vis["agents"]["$(agent._extras._id)"][pclr], true)

        if tail_condition(agent)
            draw_tail(vis, agent, tail_length)
        end

    end


end



@inline function draw_patches(vis, model::GridModel3D, frame)
    for k in 1:model.size[3]            
        for j in 1:model.size[2]
            for i in 1:model.size[1]
                clrs = model.patches[i,j,k]._extras._colors
                pclr = unwrap_data(model.patches[i,j,k])[:color][frame]
                for cl in clrs
                    setvisible!(vis["patches"]["($i,$j,$k)"][cl], false) 
                end
                setvisible!(vis["patches"]["($i,$j,$k)"][pclr], true)  
            end
        end
    end
end


@inline function draw_agent(vis, agent::AgentDict3D, model::GridModel3D, index::Int, scl::Number=1.0, tail_length = 1, tail_condition= agent-> false)
        record = agent.keeps_record_of
        periodic = model.periodic
        agent_data = unwrap_data(agent)

        xlen = gparams3d.xlen+0.0
        ylen = gparams3d.ylen+0.0
        zlen = gparams3d.zlen+0.0
        xdim = model.size[1]
        ydim = model.size[2]
        zdim = model.size[3]
        w = xlen/xdim
        l = ylen/ydim
        h = zlen/zdim 
        pos = (:pos in record) ? agent_data[:pos][index] : agent.pos
        nextpos = (:pos in record)&&(index<model.tick) ? agent_data[:pos][index+1] : agent.pos 
        orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
        pclr = (:color in record) ? agent_data[:color][index] : agent.color
        clrs = agent._extras._colors

        
        sc = (:size in record) ? agent_data[:size][index]/(agent_data[:size][1])  : 1.0

        sc = sc*scl

        ao,bo,co = orientation


        posx,posy,posz = pos
        posx0,posy0,posz0 = nextpos
        if periodic
            posx  = mod1(posx, xdim)
            posy  = mod1(posy, ydim)
            posz  = mod1(posz, zdim)
            posx0 = mod1(posx0, xdim)
            posy0 = mod1(posy0, ydim)
            posz0 = mod1(posz0, zdim)
            distsq = (posx-posx0)^2+(posy-posy0)^2+(posz-posz0)^2 
            condition = distsq > 0.5*min(xdim, ydim, zdim)^2 # hack for proper periodic case visualization
        end
        
        x =  w*posx 
        y =  l*posy 
        z =  h*posz


        for cl in clrs
            setvisible!(vis["agents"]["$(agent._extras._id)"][cl], false)
        end
        
        trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0)))
        settransform!(vis["agents"]["$(agent._extras._id)"], trans)
        setprop!(vis["agents"]["$(agent._extras._id)"], "scale", MeshCat.Vec(sc, sc, sc))
        #settransform!(vis["agents"]["$(agent._extras._id)"], Translation(x, y, z))
        #setprop!(vis["agents"]["$(agent._extras._id)"], "position", MeshCat.Vec(x,y,z))
        if !(periodic && condition)
            setvisible!(vis["agents"]["$(agent._extras._id)"][pclr], true)
        end

        if tail_condition(agent) && index>2
            for i in 1:min(tail_length, index-2)
                x,y,z = agent_data[:pos][index-i]
                a,b,c = agent_data[:pos][index-i+1]
                sca = sqrt((x-a)^2+(y-b)^2+(z-c)^2)
                if (x,y,z)==(a,b,c)
                    c = 1.0+c
                end
                trans = Translation(x, y, z) ∘ LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1.0), MeshCat.Vec(a-x,b-y,c-z)))
                settransform!(vis["tails"]["$(agent._extras._id)"]["$i"], trans)
                setprop!(vis["tails"]["$(agent._extras._id)"]["$i"], "scale", MeshCat.Vec(sca, sca, sca))
                if !(periodic && (sca > 0.5*min(xdim, ydim, zdim)))
                    setvisible!(vis["tails"]["$(agent._extras._id)"]["$i"], true)
                else
                    setvisible!(vis["tails"]["$(agent._extras._id)"]["$i"], false)
                end
            end
        end
        
end


@inline function draw_patches_interact_frame(vis, model::GridModel3D, frame)
    record = model.record.pprops
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim
    g = min(0.05,w/20, l/20, h/20)
    blackl = LineBasicMaterial(color=RGBA(0,0,0,1))
 
    for k in 0:model.size[3]
        z=h*k
        for j in 0:model.size[2]
            y =  l*j
            setobject!(vis["line_segments"]["yz($j,$k)"], MeshCat.LineSegments([MeshCat.Point(0.0, y, z),MeshCat.Point(xlen, y, z)], blackl))
            for i in 0:model.size[1]
                x =  w*i
                setobject!(vis["line_segments"]["zx($k,$i)"], MeshCat.LineSegments([MeshCat.Point(x, 0.0, z),MeshCat.Point(x, ylen, z)], blackl))
                setobject!(vis["line_segments"]["xy($i,$j)"], MeshCat.LineSegments([MeshCat.Point(x, y, 0.0),MeshCat.Point(x, y, zlen)], blackl))
                if (i>0)&&(j>0)&&(k>0)
                    patch = model.patches[i,j,k]
                    patch_data = unwrap_data(patch)
                    cl = (:color in record) ? patch_data[:color][frame] : patch.color
                    cl_rgb = eval(Symbol("patch"*string(cl)))
                    material = MeshPhongMaterial(color=cl_rgb)
                    box = HyperRectangle(MeshCat.Vec(x-w+g,y-l+g,z-h+g), MeshCat.Vec(w-g,l-g,h-g))
                    setobject!(vis["patches"]["($i,$j,$k)"],box,material)

                end      
            end
        end
    end
end

@inline function draw_agent_interact_frame(vis, agent::AgentDict3D, model::GridModel3D, index::Int, scl)
    record = agent.keeps_record_of
    periodic = model.periodic
    agent_data = unwrap_data(agent)

    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim 
    pos = (:pos in record) ? agent_data[:pos][index] : agent.pos
    orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
    pclr = (:color in record) ? agent_data[:color][index] : agent.color

    ao,bo,co = orientation


    posx,posy,posz = pos
    if periodic
        posx  = mod1(posx, xdim)
        posy  = mod1(posy, ydim)
        posz  = mod1(posz, zdim)
    end
    
    x =  w*posx 
    y =  l*posy 
    z =  h*posz


    clr = eval(Symbol("agent"*string(pclr)))
    material = MeshPhongMaterial(color=clr) 


    size = 0.3

    if haskey(agent_data, :size)
        size = (:size in record) ? agent_data[:size][index] : agent.size
    end

    size = size*scl
    
    shape = agent.shape

    if !(shape in [:sphere, :box, :cone, :cylinder])
        shape = :cone
    end

    shape_rendered = shapefunctions3d[shape](size)
    
    setobject!(vis["agents"]["$(agent._extras._id)"],shape_rendered,material) 
    settransform!(vis["agents"]["$(agent._extras._id)"], LinearMap(rotation_between(MeshCat.Vec(0, 0.0, 1), MeshCat.Vec(ao,bo,co+0.0))))
    setprop!(vis["agents"]["$(agent._extras._id)"], "position", MeshCat.Vec(x,y,z))
end

