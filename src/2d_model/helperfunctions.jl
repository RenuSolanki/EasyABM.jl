#####################
#####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent2D{Symbol, Any, <:AbstractFloat}, xdim, ydim)
    setfield!(agent, :pos, Vect(rand()*xdim, rand()*ydim) )
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent2D{Symbol, Any, Int}, xdim, ydim)
    setfield!(agent, :pos, Vect(rand(1:xdim), rand(1:ydim)) )
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{Symbol, Any, S, P}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T,S<:AbstractFloat,P<:Periodic}
    patches = model.patches
    x,y = agent.pos
    a = mod1(x, xdim)
    b = mod1(y, ydim)
    setfield!(agent, :pos, Vect(a,b))
    a,b = Int(ceil(a)), Int(ceil(b))
    push!(patches[a,b].agents, i)
    setfield!(agent, :last_grid_loc, (a,b))

end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{Symbol, Any, S, P}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T,S<:AbstractFloat,P<:NPeriodic}
    patches = model.patches
    x,y = agent.pos
    if (x>0 && x<=xdim && y>0 && y<=ydim )
        a,b = Int(ceil(x)), Int(ceil(y))
        push!(patches[a,b].agents, i)
        setfield!(agent, :last_grid_loc, (a,b))
    else
        p = S(0.5)
        setfield!(agent, :pos, Vect(p,p))
        push!(patches[1,1].agents, i)
        setfield!(agent, :last_grid_loc, (1,1))
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{Symbol, Any, S, P}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T,S<:Int,P<:Periodic}
    patches = model.patches
    x,y = agent.pos
    a = mod1(x, xdim)
    b = mod1(y, ydim)
    setfield!(agent, :pos, Vect(a, b))
    push!(patches[a,b].agents, i)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{Symbol, Any, S, P}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T,S<:Int,P<:NPeriodic}
    patches = model.patches
    x,y = agent.pos
    if (x>0 && x<=xdim && y>0 && y<=ydim )
        push!(patches[x,y].agents, i)
    else
        setfield!(agent, :pos, Vect(1,1))
        push!(patches[1,1].agents, i)
    end 
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_patches(grid_size)
    xdim, ydim = grid_size
    patches = [ContainerDataDict(Dict{Symbol, Any}(:color => :white)) for i in 1:xdim, j in 1:ydim]   
    return patches
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_parameters(grid_size, n, random_positions; kwargs...)
    xdim, ydim = grid_size
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._num_patches = xdim*ydim
    parameters._extras._keep_deads_data = true
    return parameters
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::Agent2D, graphics, size)
    if graphics

        if !haskey(agent, :shape)
            agent.shape = :circle
        end

        if !haskey(agent, :color)
            agent.color = :red
        end

        if !haskey(agent, :size)
            agent.size = 20
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
function add_agent!(agent, model::SpaceModel2D{Mortal})
    if (agent._extras._active::Bool)&&(agent._extras._new::Bool)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.size) #annotate any value that compiler doesn't know type of so that it can choose which function to call

        xdim = model.size[1]
        ydim = model.size[2]

        
        _setup_grid!(agent, model, getfield(agent, :id), xdim, ydim)
        

        setfield!(agent, :model, model)

        _create_agent_record!(agent, model)
        
        _init_agent_record!(agent)

        getfield(model,:max_id)[] += 1
        model.parameters._extras._num_agents::Int += 1
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
                    push!(patch_data[key]::Vector, patch_dict[key])
                end
            end
        end
    end
end








"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
"""
@inline function do_after_model_step!(model::SpaceModel2D{Mortal})

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
@inline function do_after_model_step!(model::SpaceModel2D{Static})

    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end





#################
"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::SpaceModel2D{Mortal}, frame, scl, tail_length = 1, tail_condition = agent-> false)
    xdim = model.size[1]
    ydim = model.size[2]
    show_grid = model.parameters._extras._show_space::Bool
    if show_grid
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end
    all_agents = vcat(model.agents, model.agents_killed)
    @sync for agent in all_agents
        if (agent._extras._birth_time::Int <= frame)&&(frame<= agent._extras._death_time::Int)
            @async draw_agent(agent, model, xdim, ydim, scl, frame - agent._extras._birth_time::Int +1, tail_length, tail_condition)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::SpaceModel2D{Static}, frame, scl, tail_length = 1, tail_condition = agent-> false)
    xdim = model.size[1]
    ydim = model.size[2]
    show_grid = model.parameters._extras._show_space::Bool
    if show_grid
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end

   @sync for agent in model.agents
        @async draw_agent(agent, model, xdim, ydim, scl, frame, tail_length, tail_condition)
    end
end
