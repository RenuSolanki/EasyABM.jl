#####################
#####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::AgentDict2D, xdim, ydim)
    setfield!(agent, :pos, (rand()*xdim, rand()*ydim) )
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::AgentDict2DGrid, xdim, ydim)
    setfield!(agent, :pos, (rand(1:xdim), rand(1:ydim)) )
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::AgentDict2D, patches, periodic, i, xdim, ydim)
    x,y = agent.pos
    if periodic || (x>0 && x<=xdim && y>0 && y<=ydim )
        a = mod1(x, xdim)
        b = mod1(y, ydim)
        setfield!(agent, :pos, (a,b))
        a,b = Int(ceil(a)), Int(ceil(b))
        push!(patches[a,b]._extras._agents, i)
        agent._extras._last_grid_loc = (a,b)
    else
        p = typeof(x)(0.5)
        setfield!(agent, :pos, (p,p))
        push!(patches[1,1]._extras._agents, i)
        agent._extras._last_grid_loc = (1,1)
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::AgentDict2DGrid, patches, periodic, i, xdim, ydim)
    x,y = agent.pos
    if periodic || (x>0 && x<=xdim && y>0 && y<=ydim )
        a = mod1(x, xdim)
        b = mod1(y, ydim)
        setfield!(agent, :pos, (a, b))
        push!(patches[a,b]._extras._agents, i)
    else
        setfield!(agent, :pos, (1,1))
        push!(patches[1,1]._extras._agents, i)
    end 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_patches(periodic, grid_size)
    xdim, ydim = grid_size
    patches = [PropDataDict(Dict{Symbol, Any}(:color => :white)) for i in 1:xdim, j in 1:ydim]   
    for j in 1:ydim
        for i in 1:xdim
            patches[i,j]._extras._agents = Int[]
        end
    end
    patches[1,1]._extras._periodic = periodic
    patches[1,1]._extras._size = grid_size
    return patches
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_parameters(grid_size, n, fix_agents_num, random_positions, st; kwargs...)
    xdim, ydim = grid_size
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)


    if !fix_agents_num
        atype = MortalType
        if st == :c
            parameters._extras._agents_added = Vector{AgentDict2D{Symbol, Any}}()
            parameters._extras._agents_killed = Vector{AgentDict2D{Symbol, Any}}()
        else
            parameters._extras._agents_added = Vector{AgentDict2DGrid{Symbol, Any}}()
            parameters._extras._agents_killed = Vector{AgentDict2DGrid{Symbol, Any}}()
        end
    else
        atype =StaticType
    end

    if st == :c
        parameters._extras._offset = (0.0,0.0)
    else
        parameters._extras._offset = (-0.5,-0.5)
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._num_patches = xdim*ydim
    parameters._extras._keep_deads_data = true
    return parameters, atype
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::AbstractAgent2D, graphics, random_positions, size)
    if graphics
        if random_positions
            _set_pos!(agent, size[1], size[2])
        end

        if !haskey(agent, :shape)
            agent.shape = :circle
        end

        if !haskey(agent, :color)
            agent.color = :red
        end

        if !haskey(agent, :size)
            agent.size = size[1]/50
        end

        if !haskey(agent, :orientation)
            agent.orientation = 0.0
        end

    end
end


"""
$(TYPEDSIGNATURES)

Adds the agent to the model.
"""
function add_agent!(agent, model::SpaceModel2D{MortalType})
    if !haskey(agent._extras, :_id)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.parameters._extras._random_positions, model.size)

        xdim = model.size[1]
        ydim = model.size[2]

        
        _setup_grid!(agent, model.patches, model.periodic, agent._extras._id, xdim, ydim)
        

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
@inline function update_agents_record!(model::SpaceModel2D) 
    for agent in model.agents
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::SpaceModel2D)
    if length(model.record.pprops)>0 
        for j in 1:model.size[2]
            for i in 1:model.size[1]
                patch_dict = unwrap(model.patches[i, j])
                patch_data = unwrap_data(model.patches[i,j])
                for key in model.record.pprops
                    push!(patch_data[key], patch_dict[key])
                end
            end
        end
    end
end








"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
"""
@inline function do_after_model_step!(model::SpaceModel2D{MortalType})

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
@inline function do_after_model_step!(model::SpaceModel2D{StaticType})

    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end





#################
"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::SpaceModel2D{MortalType}, frame, scl, tail_length = 1, tail_condition = agent-> false)
    xdim = model.size[1]
    ydim = model.size[2]
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    @sync for agent in all_agents
        if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
            @async draw_agent(agent, model, xdim, ydim, scl, frame - agent._extras._birth_time +1, tail_length, tail_condition)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::SpaceModel2D{StaticType}, frame, scl, tail_length = 1, tail_condition = agent-> false)
    xdim = model.size[1]
    ydim = model.size[2]
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end

   @sync for agent in model.agents
        @async draw_agent(agent, model, xdim, ydim, scl, frame, tail_length, tail_condition)
    end
end
