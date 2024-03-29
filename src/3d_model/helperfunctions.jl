#####################
#####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent3D{<:Float64}, xdim, ydim, zdim)
    setfield!(agent, :pos, Vect(rand()*xdim, rand()*ydim, rand()*zdim) )
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent3D{Int}, xdim, ydim, zdim)
    setfield!(agent, :pos, Vect(rand(1:xdim), rand(1:ydim), rand(1:zdim)))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent3D{S, P, T}, model::SpaceModel3D{T,S,P}, i, xdim, ydim, zdim) where {T<:MType,S<:Float64,P<:PeriodicType}
    patches = model.patches
    x,y,z = agent.pos
    a = mod1(x, xdim)
    b = mod1(y, ydim)
    c = mod1(z, zdim)
    setfield!(agent, :pos, Vect(a,b,c))
    a,b,c = Int(ceil(a)), Int(ceil(b)), Int(ceil(c))
    push!(patches[a,b,c].agents, i)
    setfield!(agent, :last_grid_loc, (a,b,c))

end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent3D{S, P, T}, model::SpaceModel3D{T,S,P}, i, xdim, ydim, zdim) where {T<:MType,S<:Float64,P<:NPeriodicType}
    patches = model.patches
    x,y,z = agent.pos
    if (x>0 && x<=xdim && y>0 && y<=ydim && z>0 && z<=zdim)
        a,b,c = Int(ceil(x)), Int(ceil(y)), Int(ceil(z))
        push!(patches[a,b,c].agents, i)
        setfield!(agent, :last_grid_loc, (a,b,c))
    else
        p = S(eps())
        setfield!(agent, :pos, Vect(p,p,p))
        push!(patches[1,1,1].agents, i)
        setfield!(agent, :last_grid_loc, (1,1,1))
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent3D{S, P, T}, model::SpaceModel3D{T,S,P}, i, xdim, ydim, zdim) where {T<:MType,S<:Int,P<:PeriodicType}
    patches = model.patches
    x,y,z = agent.pos
    a = mod1(x, xdim)
    b = mod1(y, ydim)
    c = mod1(z, zdim)
    setfield!(agent, :pos, Vect(a,b,c))
    push!(patches[a,b,c].agents, i)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent3D{S, P, T}, model::SpaceModel3D{T,S,P}, i, xdim, ydim, zdim) where {T<:MType,S<:Int,P<:NPeriodicType}
    patches = model.patches
    x,y,z = agent.pos
    if (x>0 && x<=xdim && y>0 && y<=ydim  && z>0 && z<=zdim)
        push!(patches[x,y,z].agents, i)
    else
        setfield!(agent, :pos, Vect(1,1,1))
        push!(patches[1,1,1].agents, i)
    end 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_patches3d(grid_size)
    xdim, ydim, zdim = grid_size
    patches = [ContainerDataDict(Dict{Symbol, Any}(:color => Col(1,1,1,0.1))) for i in 1:xdim, j in 1:ydim, k in 1:zdim]   
    return patches
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_parameters3d(grid_size, n, random_positions; kwargs...)
    xdim, ydim, zdim = grid_size
    dict_parameters = Dict{Symbol, Any}(kwargs)
    properties = PropDataDict(dict_parameters)

    properties._extras._random_positions = random_positions
    properties._extras._show_space = true
    properties._extras._num_agents = n # number of active agents
    properties._extras._len_model_agents = n #number of agents in model.agents
    properties._extras._num_patches = xdim*ydim*zdim
    return properties
end



"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::Agent3D, graphics, size)
    if graphics

        if !haskey(agent, :shape)
            agent.shape = :sphere
        end

        if !haskey(agent, :color)
            agent.color = Col("red")
        end

        if !haskey(agent, :size)
            agent.size = 0.25 # absolute size like position from 0 to xdim ...
        end

        if !haskey(agent, :orientation)
            agent.orientation = Vect(0.0,0.0,1.0)
        end

    end
end



"""
$(TYPEDSIGNATURES)

Adds the agent to the model.
"""
function add_agent!(agent, model::SpaceModel3D{MortalType})
    if (agent._extras._active::Bool)&&(agent._extras._new::Bool)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.size)

        xdim = model.size[1]
        ydim = model.size[2]
        zdim = model.size[3]

        _setup_grid!(agent, model, getfield(agent, :id), xdim, ydim, zdim)

        setfield!(agent, :model, model)

        _create_agent_record!(agent, model)

        _init_agent_record!(agent)

        getfield(model,:max_id)[] += 1
        model.properties._extras._num_agents::Int += 1
    end
end





"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_agents_record!(model::SpaceModel3D) 
    @threads for agent in model.agents
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::SpaceModel3D)
    if length(model.record.pprops)>0 
        @threads for k in 1:model.size[3]
            @threads for j in 1:model.size[2]
                @threads for i in 1:model.size[1]
                    patch_dict = unwrap(model.patches[i, j, k])
                    patch_data = unwrap_data(model.patches[i,j, k])
                    for key in model.record.pprops
                        push!(patch_data[key]::Vector, patch_dict[key])
                    end
                end
            end
        end
    end
end




"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function do_after_model_step!(model::SpaceModel3D{MortalType})
    
    _permanently_remove_inactive_agents!(model)

    commit_add_agents!(model) 
    
    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function do_after_model_step!(model::SpaceModel3D{StaticType})

    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end





#################
"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_agents_interact_frame(vis, model::SpaceModel3D{MortalType}, frame, scl)

    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim 

    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
        if (agent._extras._birth_time::Int<= frame)&&(frame<= agent._extras._death_time::Int)
            draw_agent_interact_frame(vis, agent, model, frame- agent._extras._birth_time::Int+1, scl, w, l, h)
        end
    end

end

@inline function _draw_agents_interact_frame(vis, model::SpaceModel3D{StaticType}, frame, scl)

    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim 
    
    for agent in model.agents
        draw_agent_interact_frame(vis, agent, model, frame, scl, w, l, h)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _if_alive_draw_agent(vis, agent, model, frame, scl, tail_length::Int, tail_condition::Function, w, l, h)
    if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
        draw_agent(vis, agent, model, frame - agent._extras._birth_time::Int +1, scl, tail_length, tail_condition, w, l, h)
    else
    #if haskey(agent._extras, :_shapes) && haskey(agent._extras, :_colors) # this will be true if all agents are drawn initially which is true for animate_sim and create_interactive_app
        clrs = agent._extras._colors::Vector{Col}
        shps = agent._extras._shapes::Vector{Symbol}
        for sh in shps
            for cl in clrs
                setvisible!(vis["agents"]["$(getfield(agent, :id))"*string(sh)][string(cl)], false)
            end
        end
        if tail_condition(agent)
            for i in 1:tail_length
                setvisible!(vis["tails"]["$(getfield(agent, :id))"]["$i"], false)
            end
        end
    #end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::SpaceModel3D{MortalType}, frame, scl::Number=1.0, tail_length = 1, tail_condition = agent->false)
    show_patches = model.properties._extras._show_space
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim
    if show_patches
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end
    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
         _if_alive_draw_agent(vis, agent, model, frame, scl, tail_length, tail_condition, w, l, h)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::SpaceModel3D{StaticType}, frame, scl::Number=1.0, tail_length = 1, tail_condition = agent->false)
    show_patches = model.properties._extras._show_space::Bool
    xlen = gparams3d.xlen+0.0
    ylen = gparams3d.ylen+0.0
    zlen = gparams3d.zlen+0.0
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    w = xlen/xdim
    l = ylen/ydim
    h = zlen/zdim
    if show_patches
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end

    for agent in model.agents
        draw_agent(vis, agent, model, frame, scl, tail_length, tail_condition, w, l, h)
    end
end


#########################
#Thebes
#########################

#################
# """
# $(TYPEDSIGNATURES)
# """
# @inline function draw_agents_and_patches(model::SpaceModel3D{MortalType}, frame, scl, ep, tail_length = 1, tail_condition = agent-> false)
#     # eyepoint(Point3D(ep.xe,ep.ye,ep.ze))
#     # perspective(ep.zoom)
#     show_patches = model.properties._extras._show_space::Bool
#     if show_patches
#         if :color in model.record.pprops
#             draw_patches(model, frame)
#         end
#     end
#     all_agents = vcat(model.agents, model.agents_killed)
#     @sync for agent in all_agents
#         if (agent._extras._birth_time::Int <= frame)&&(frame<= agent._extras._death_time::Int)
#             @async draw_agent(agent, model, scl, frame - agent._extras._birth_time::Int +1, tail_length, tail_condition)
#         end
#     end
# end


# """
# $(TYPEDSIGNATURES)
# """
# @inline function draw_agents_and_patches(model::SpaceModel3D{StaticType}, frame, scl, ep, tail_length = 1, tail_condition = agent-> false)
#     # eyepoint(Point3D(ep.xe,ep.ye,ep.ze))
#     # perspective(ep.zoom)
#     show_patches = model.properties._extras._show_space::Bool
#     if show_patches
#         if :color in model.record.pprops
#             draw_patches(model, frame)
#         end
#     end

#    @sync for agent in model.agents
#         @async draw_agent(agent, model, scl, frame, tail_length, tail_condition)
#     end
# end
