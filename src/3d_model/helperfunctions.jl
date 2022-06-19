#####################
#####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::AgentDict3D, xdim, ydim, zdim)
    setfield!(agent, :pos, (rand()*xdim, rand()*ydim, rand()*zdim) )
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::AgentDict3DGrid, xdim, ydim, zdim)
    setfield!(agent, :pos, (rand(1:xdim), rand(1:ydim), rand(1:zdim)))
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::AgentDict3D, patches, periodic, i, xdim, ydim, zdim)
    x,y,z = agent.pos
    if periodic || (x>0 && x<=xdim && y>0 && y<=ydim && z>0 && z<=zdim)
        a = mod1(x, xdim)
        b = mod1(y, ydim)
        c = mod1(z, zdim)
        setfield!(agent, :pos, (a,b,c))
        a,b,c = Int(ceil(a)), Int(ceil(b)), Int(ceil(c))
        push!(patches[a,b,c]._extras._agents, i)
        agent._extras._last_grid_loc = (a,b,c)
    else
        p = typeof(x)(0.5)
        setfield!(agent, :pos, (p,p,p))
        push!(patches[1,1,1]._extras._agents, i)
        agent._extras._last_grid_loc = (1,1,1)
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::AgentDict3DGrid, patches, periodic, i, xdim, ydim, zdim)
    x,y,z = agent.pos
    if periodic || (x>0 && x<=xdim && y>0 && y<=ydim  && z>0 && z<=zdim)
        a = mod1(x, xdim)
        b = mod1(y, ydim)
        c = mod1(z, zdim)
        setfield!(agent, :pos, (a,b,c))
        push!(patches[a,b,c]._extras._agents, i)
    else
        setfield!(agent, :pos, (1,1,1))
        push!(patches[1,1,1]._extras._agents, i)
    end 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_patches3d(periodic, grid_size)
    xdim, ydim, zdim = grid_size
    patches = [PropDataDict(Dict{Symbol, Any}(:color => :red)) for i in 1:xdim, j in 1:ydim, k in 1:zdim]   
    for k in 1:zdim
        for j in 1:ydim
            for i in 1:xdim
                patches[i,j,k]._extras._agents = Int[]
            end
        end
    end
    patches[1,1,1]._extras._periodic = periodic
    patches[1,1,1]._extras._size = grid_size
    return patches
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_parameters3d(grid_size, n, fix_agents_num, random_positions, st; kwargs...)
    xdim, ydim, zdim = grid_size
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)


    if !fix_agents_num
        atype = MortalType
        if st == :c
            parameters._extras._agents_added = Vector{AgentDict3D{Symbol, Any}}()
            parameters._extras._agents_killed = Vector{AgentDict3D{Symbol, Any}}()
        else
            parameters._extras._agents_added = Vector{AgentDict3DGrid{Symbol, Any}}()
            parameters._extras._agents_killed = Vector{AgentDict3DGrid{Symbol, Any}}()
        end
    else
        atype =StaticType
    end

    if st == :c
        parameters._extras._offset = (0.0,0.0,0.0)
    else
        parameters._extras._offset = (-0.5,-0.5,-0.5)
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._num_patches = xdim*ydim*zdim
    parameters._extras._keep_deads_data = true
    return parameters, atype
end



"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::AbstractAgent3D, graphics, random_positions, size)
    if graphics
        if random_positions
            _set_pos!(agent, size[1], size[2], size[3])
        end

        if !haskey(agent, :shape)
            agent.shape = :sphere
        end

        if !haskey(agent, :color)
            agent.color = :red
        end

        if !haskey(agent, :size)
            agent.size = 0.3
        end

        if !haskey(agent, :orientation)
            agent.orientation = (0.0,0.0,1.0)
        end

    end
end



"""
$(TYPEDSIGNATURES)

Adds the agent to the model.
"""
function add_agent!(agent, model::SpaceModel3D{MortalType})
    if !haskey(agent._extras, :_id)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.parameters._extras._random_positions, model.size)

        xdim = model.size[1]
        ydim = model.size[2]
        zdim = model.size[3]

        _setup_grid!(agent, model.patches, model.periodic, agent._extras._id, xdim, ydim, zdim)

        agent._extras._grid = model.patches

        _create_agent_record!(agent, model)

        _init_agent_record!(agent)

        getfield(model,:max_id)[] += 1
        model.parameters._extras._num_agents += 1
    end
end





"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_agents_record!(model::SpaceModel3D) 
    for agent in model.agents
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::SpaceModel3D)
    if length(model.record.pprops)>0 
        for k in 1:model.size[3]
            for j in 1:model.size[2]
                for i in 1:model.size[1]
                    patch_dict = unwrap(model.patches[i, j, k])
                    patch_data = unwrap_data(model.patches[i,j, k])
                    for key in model.record.pprops
                        push!(patch_data[key], patch_dict[key])
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
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
            index = frame- agent._extras._birth_time+1
            draw_agent_interact_frame(vis, agent, model, index, scl)
        end
    end

end

@inline function _draw_agents_interact_frame(vis, model::SpaceModel3D{StaticType}, frame, scl)
    for agent in model.agents
        draw_agent_interact_frame(vis, agent, model, frame, scl)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _if_alive_draw_agent(vis, agent, model, frame, scl, tail_length::Int, tail_condition::Function)
    if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
        setvisible!(vis["agents"]["$(agent._extras._id)"], true)
        if tail_condition(agent)
            setvisible!(vis["tails"]["$(agent._extras._id)"], true)
        end
        draw_agent(vis, agent, model, frame - agent._extras._birth_time +1, scl, tail_length, tail_condition)
    else
        setvisible!(vis["agents"]["$(agent._extras._id)"], false)
        if tail_condition(agent)
            setvisible!(vis["tails"]["$(agent._extras._id)"], false)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::SpaceModel3D{MortalType}, frame, scl::Number=1.0, tail_length = 1, tail_condition = agent->false)
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        _if_alive_draw_agent(vis, agent, model, frame, scl, tail_length, tail_condition)
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::SpaceModel3D{StaticType}, frame, scl::Number=1.0, tail_length = 1, tail_condition = agent->false)
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end

    for agent in model.agents
        draw_agent(vis, agent, model, frame, scl, tail_length, tail_condition)
    end
end
