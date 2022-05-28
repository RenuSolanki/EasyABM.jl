#####################
#####################


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::AgentDict2D, graphics, random_positions, size)
    if graphics
        if !haskey(agent, :pos)
            pos = random_positions ? (size[1]*rand(), size[2]*rand()) : (0.0,0.0)
            agent.pos = pos
        end

        if !haskey(agent, :shape)
            agent.shape = :circle
        end

        if !haskey(agent, :color)
            agent.color = :red
        end

        if !haskey(agent, :size)
            agent.size = 4
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
function add_agent!(agent, model::GridModel2DDynAgNum)
    if !haskey(agent._extras, :_id)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.parameters._extras._random_positions, model.size)

        xdim = model.size[1]
        ydim = model.size[2]

        if haskey(agent, :pos)
            pos = agent.pos
            if model.periodic || checkbound(pos[1],pos[2],xdim, ydim)
                x = mod1(Int(ceil(pos[1])), xdim)
                y = mod1(Int(ceil(pos[2])), ydim)
                push!(model.patches[x,y]._extras._agents, agent._extras._id)
                agent._extras._last_grid_loc = (x,y)
            else
                agent._extras._last_grid_loc = Inf
            end
        end

        agent._extras._grid = model.patches

        _create_agent_record!(agent, model)

        _recalculate_position!(agent, model.size, model.periodic)
        
        _init_agent_record!(agent)

        getfield(model,:max_id)[] += 1
    end
end







"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_agents_record!(model::GridModel2DDynAgNum) 
    for agent in model.agents
        if agent._extras._active
            _recalculate_position!(agent, model.size, model.periodic)
            _update_agent_record!(agent)
        end
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_agents_record!(model::GridModel2DFixAgNum) 
    for agent in model.agents
        _recalculate_position!(agent, model.size, model.periodic)
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::GridModel2D)
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
@inline function do_after_model_step!(model::GridModel2DDynAgNum)

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
@inline function do_after_model_step!(model::GridModel2DFixAgNum)

    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end



"""
$(TYPEDSIGNATURES)

This function adds up a list of position 2-tuples. 
"""
function sumall(lst::Vector{T}) where {T}
    sum_x = zero(eltype(T))
    sum_y = zero(eltype(T))
    for a in lst
        x, y = a
        sum_x+=x
        sum_y+=y
    end
    return sum_x, sum_y        
end


"""
$(TYPEDSIGNATURES)

This function finds mean of a list of position 2-tuples. 
"""
function avg(lst::Vector{T}) where {T}
    sum_x, sum_y = sumall(lst)
    avg_x = (sum_x+0.0)/length(lst)
    avg_y = (sum_y+0.0)/length(lst)
    return avg_x, avg_y        
end

#################
"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(model::GridModel2DDynAgNum, frame, scl, tail_length = 1, tail_condition = agent-> false)
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
@inline function draw_agents_and_patches(model::GridModel2DFixAgNum, frame, scl, tail_length = 1, tail_condition = agent-> false)
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










