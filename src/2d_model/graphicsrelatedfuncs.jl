
############################

@inline function _get_grid_colors(model::SpaceModel2D, t)
    if :color in model.record.pprops
        colors = [unwrap_data(model.patches[i,j])[:color][t]::Symbol for i in 1:model.size[1] for j in 1:model.size[2]]
    else
        colors = [model.patches[i,j].color::Symbol for i in 1:model.size[1] for j in 1:model.size[2]]
    end
    return colors
end

@inline function _get_tail(agent, model::SpaceModel2D{Mortal, S}, t, tail_length) where S<:AbstractFloat # we don't have tails for grid agents
    agent_tail = GeometryBasics.Vec2{S}[]
    if !(:pos in agent.keeps_record_of)
        push!(agent_tail, GeometryBasics.Vec(agent.pos...))
        return agent_tail
    end
    agent_data = unwrap_data(agent)
    offset = model.parameters._extras._offset::Tuple{Float64, Float64}
    birth_time = agent._extras._birth_time::Int
    death_time = agent._extras._death_time::Int
    if (birth_time<= t)&&(t<= death_time)
        index = t - birth_time +1
        for i in max(1, index-tail_length):index
            v = agent_data[:pos][i]::Vect{2, S} .+ offset
            push!(agent_tail, GeometryBasics.Vec(v...))
        end   
    end
    return agent_tail
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_tail(agent, model::SpaceModel2D{Static, S}, t::Int, tail_length) where S<:AbstractFloat
    agent_tail = GeometryBasics.Vec2{S}[]
    if !(:pos in agent.keeps_record_of)
        push!(agent_tail, GeometryBasics.Vec(agent.pos...))
        return agent_tail
    end
    agent_data = unwrap_data(agent)
    index = t 
    offset = model.parameters._extras._offset::Tuple{Float64, Float64}
    for i in max(1, index-tail_length):index
        v = agent_data[:pos][i]::Vect{2, S} .+ offset
        push!(agent_tail, GeometryBasics.Vec(v...))
    end   
    return agent_tail
end



@inline function _create_makie_frame(ax, model::SpaceModel2D, points, markers, colors, rotations, sizes, grid_colors, show_space)
    ax.aspect = DataAspect()
    xlims!(ax, 0.0, model.size[1])
    ylims!(ax, 0.0, model.size[2])
    if show_space
        hlines!(ax, collect(1:model.size[2]), color = :black)
        vlines!(ax, collect(1:model.size[1]), color = :black)
        grid_points = [ GeometryBasics.Vec(i-0.5,j-0.5) for i in 1:model.size[1] for j in 1:model.size[2]]
        scatter!(ax, grid_points, color = grid_colors, marker_size = GeometryBasics.Vec( gparams.width/model.size[1], gparams.height/model.size[2]) )
    end
    scatter!(ax, points, marker = markers, color = colors, rotations = rotations, markersize = sizes)
    return 
end

############################



@inline function _draw_a_patch(i,j,w,h,cl, width, height)
    x =  w*(i-0.5)
    y =  h*(j-0.5)
    gsave()
    translate(-(width/2), (height/2))
    Luxor.transform([1 0 0 -1 0 0]) #reflects in xaxis
    ##
    translate(x,y)
    sethue(String(cl))
    box(Luxor.Point(0, 0), max(w-1,1), max(h-1,1), 0.0001, :fill)
    grestore()
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_patches_static(model::SpaceModel2D)
    xdim = model.size[1]
    ydim = model.size[2]
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    sethue("black")
    box(Luxor.Point(0, 0), width, height, 0.0001, :fill)
 
 
    @sync for j in 1:model.size[2], i in 1:model.size[1]
       @async _draw_a_patch(i, j, w, h, model.patches[i,j].color, width, height)
    end

end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_patches(model::SpaceModel2D, frame::Int)
    xdim = model.size[1]
    ydim = model.size[2]
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    sethue("black")
    box(Luxor.Point(0, 0), width, height, 0.0001, :fill)
                
    @sync for j in 1:model.size[2], i in 1:model.size[1]
        @async _draw_a_patch(i, j, w, h, unwrap_data(model.patches[i,j])[:color][frame]::Symbol, width, height)
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agent(agent, model::SpaceModel2D, xdim::Int, ydim::Int, scl, index::Int, tail_length, tail_condition)
    record = agent.keeps_record_of::Vector{Symbol}
    periodic = is_periodic(model)
    agent_data = unwrap_data(agent)
    offset = model.parameters._extras._offset::Tuple{Float64, Float64}

    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    pos = (:pos in record) ? agent_data[:pos][index]::Vect{2, <:Real} .+ offset : agent.pos .+ offset
    orientation = (:orientation in record) ? agent_data[:orientation][index]::Float64 : agent.orientation::Float64
    shape = (:shape in record) ? agent_data[:shape][index]::Symbol : agent.shape::Symbol
    shape_color = (:color in record) ? agent_data[:color][index]::Symbol : agent.color::Symbol

    if !(shape in keys(shapefunctions2d))
        shape = :circle
    end

    size = xdim/50

    if haskey(agent_data, :size)
        size = (:size in record) ? agent_data[:size][index]::Union{Int, <:AbstractFloat} : agent.size::Union{Int, <:AbstractFloat}
    end
   
    size = size*scl*w

    posx,posy = pos
    x =  w*posx #- w/2
    y =  h*posy #-h/2

    
    #First thre lines in following, translate and transform, 
    #make sure that any object's position can be specified by 
    #coordinates x,y in the coordinate system centered at
    #lower left corner of the grid (with + X to right, and + Y upwards
    gsave()
    translate(-(width/2), (height/2))
    Luxor.transform([1 0 0 -1 0 0])         
    translate(x,y)  
    rotate(orientation)                        
    sethue(String(shape_color))             
    setline(1)   
    if shape==:bug
        gsave()
        b1 = cos(pi * (index+getfield(agent, :id))/10) - 1
        a1 = (0.4 - 0.08* b1)*size
        a2 =  (0.9 + 0.18* b1)*size
        blnd = blend(Luxor.Point(0, 0), size/18, Luxor.Point(0, 0), size/4, "white", String(shape_color))
        setblend(blnd)
        Luxor.ellipse(Luxor.Point(0,0), a1, a2, action=:fill)
        sethue("black") 
        Luxor.circle(Luxor.Point(-0.125*size,0.2*size), 0.08*size, :fill)
        Luxor.circle(Luxor.Point(0.125*size,0.2*size), 0.08*size, :fill)
        Luxor.line(Luxor.Point(-0.1*size,0.2*size), Luxor.Point(-0.2*size,0.6*size), :stroke)
        Luxor.line(Luxor.Point(0.1*size,0.2*size), Luxor.Point(0.2*size,0.6*size), :stroke)
        grestore()   
    else                           
        shapefunctions2d[shape](size, index)  
    end
    grestore()   

    
    if tail_condition(agent)
        gsave()
        translate(-(width/2), (height/2))
        Luxor.transform([1 0 0 -1 0 0]) 
        agent_tail = _get_tail(agent, model, index, tail_length)
        ln = length(agent_tail)
        if ln > 1
            for j in 1:(ln-1)
                p1 = Luxor.Point(agent_tail[j]...)*(w,h)
                p2 = Luxor.Point(agent_tail[j+1]...)*(w,h)
                a, b = p1-p2
                if ((a^2+b^2) > 0.5*min(w^2,h^2)) && periodic
                    continue
                else
                    sethue("blue")
                    setopacity(tail_opacity(ln-j, tail_length))
                    Luxor.line(p1, p2, :stroke)
                end
            end
        end
        grestore()
    end

end
