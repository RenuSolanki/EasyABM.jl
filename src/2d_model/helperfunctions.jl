#####################
#####################

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent2D{<:Float64}, xdim, ydim)
    setfield!(agent, :pos, Vect(rand()*xdim, rand()*ydim) )
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _set_pos!(agent::Agent2D{Int}, xdim, ydim)
    setfield!(agent, :pos, Vect(rand(1:xdim), rand(1:ydim)) )
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T<:MType,S<:Float64,P<:PeriodicType}
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
@inline function _setup_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T<:MType,S<:Float64,P<:NPeriodicType}
    patches = model.patches
    x,y = agent.pos
    if (x>0 && x<=xdim && y>0 && y<=ydim )
        a,b = Int(ceil(x)), Int(ceil(y))
        push!(patches[a,b].agents, i)
        setfield!(agent, :last_grid_loc, (a,b))
    else
        p = S(eps())
        setfield!(agent, :pos, Vect(p,p))
        push!(patches[1,1].agents, i)
        setfield!(agent, :last_grid_loc, (1,1))
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _setup_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T<:MType,S<:Int,P<:PeriodicType}
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
@inline function _setup_grid!(agent::Agent2D{S, P, T}, model::SpaceModel2D{T,S,P}, i, xdim, ydim) where {T<:MType,S<:Int,P<:NPeriodicType}
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
    patches = [ContainerDataDict(Dict{Symbol, Any}(:color => Col("white"))) for i in 1:xdim, j in 1:ydim]   
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
            agent.color = Col("red")
        end

        if !haskey(agent, :size)
            agent.size = 0.25 # % absolute like position from 0 to xdim
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
    @threads for agent in model.agents
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::SpaceModel2D)
    if length(model.record.pprops)>0 
        @threads for j in 1:model.size[2]
            @threads for i in 1:model.size[1]
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
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim
    show_patches = model.parameters._extras._show_space::Bool
    if show_patches
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end
    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
        if (agent._extras._birth_time::Int <= frame)&&(frame<= agent._extras._death_time::Int)
            draw_agent(agent, model, scl, frame - agent._extras._birth_time::Int +1, tail_length, tail_condition, w, h)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::SpaceModel2D{StaticType}, frame, scl, tail_length = 1, tail_condition = agent-> false)
    xdim = model.size[1]
    ydim = model.size[2]
    width = gparams.width
    height = gparams.height
    w = width/xdim
    h = height/ydim
    show_patches = model.parameters._extras._show_space::Bool
    if show_patches
        if :color in model.record.pprops
            draw_patches(model, frame)
        end
    end

   for agent in model.agents
        draw_agent(agent, model, scl, frame, tail_length, tail_condition, w, h)
    end
end
