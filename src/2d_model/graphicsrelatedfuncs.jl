
############################

@inline function _get_grid_colors(model::GridModel2D, t)
    if :color in model.record.pprops
        colors = [unwrap_data(model.patches[(i,j)])[:color][t] for i in 1:model.size[1] for j in 1:model.size[2]]
    else
        colors = [model.patches[(i,j)].color for i in 1:model.size[1] for j in 1:model.size[2]]
    end
    return colors
end


@inline function _create_makie_frame(model::GridModel2D, points, markers, colors, rotations, sizes, grid_colors, show_space )
    fig = Figure(resolution = (gparams.height, gparams.width))
    ax = Axis(fig[1, 1])
    ax.title = ""
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
    return fig
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
@inline function draw_patches_static(model::GridModel2D)
    xdim = model.size[1]
    ydim = model.size[2]
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    sethue("black")
    box(Luxor.Point(0, 0), width, height, 0.0001, :fill)
 
 
    @sync for j in 1:model.size[2], i in 1:model.size[1]
       @async _draw_a_patch(i, j, w, h, model.patches[(i,j)].color, width, height)
    end

end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_patches(model::GridModel2D, frame)
    xdim = model.size[1]
    ydim = model.size[2]
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    sethue("black")
    box(Luxor.Point(0, 0), width, height, 0.0001, :fill)
                
    @sync for j in 1:model.size[2], i in 1:model.size[1]
        @async _draw_a_patch(i, j, w, h, unwrap_data(model.patches[(i,j)])[:color][frame], width, height)
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agent(agent::AgentDict2D, model::GridModel2D, xdim::Int, ydim::Int, scl, index::Int)
    record = agent.keeps_record_of
    periodic = model.periodic
    agent_data = unwrap_data(agent)

    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim

    pos = (:pos in record) ? agent_data[:pos][index] : agent.pos
    orientation = (:orientation in record) ? agent_data[:orientation][index] : agent.orientation
    shape = (:shape in record) ? agent_data[:shape][index] : agent.shape
    shape_color = (:color in record) ? agent_data[:color][index] : agent.color


    size = max(4, w/2)

    if haskey(agent_data, :size)
        size = (:size in record) ? agent_data[:size][index] : agent.size
    end
   
    size = size*scl

    posx,posy = pos
    if periodic
        posx = mod1(posx, xdim)
        posy = mod1(posy, ydim)
    end
    x =  w*posx #- w/2
    y =  h*posy #-h/2
                
    #posx, posy coordinate system is centered at lower left corner of the grid
    #with + POSX to right and +POSY upwards; Except for scale, the x, y coordinate 
    #system coincides with posx, post system. 

    
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
    shapefunctions2d[shape](size)  
    grestore()   
    
    #uncomment this to mark each agent with its id
    # gsave()
    # translate(-(width/2), (height/2))
    # Luxor.transform([1 0 0 -1 0 0]) 
    # translate(x,y)
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
