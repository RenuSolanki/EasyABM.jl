#####################
#####################


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported. 
It takes an agent as first argument, and if `graphics` is true, some
graphics related properties are added to the agent if not already defined. 
"""
@inline function manage_default_graphics_data!(agent::AgentDict3D, graphics, random_positions, size)
    if graphics
        if !haskey(agent, :pos)
            pos = random_positions ? (size[1]*rand(), size[2]*rand(), size[3]*rand()) : (0.0,0.0, 0.0)
            agent.pos = pos
        end

        if !haskey(agent, :shape)
            agent.shape = :cone
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
function add_agent!(agent, model::GridModel3DDynAgNum)
    if !haskey(agent._extras, :_id)
        _manage_default_data!(agent, model)
        manage_default_graphics_data!(agent, model.graphics, model.parameters._extras._random_positions, model.size)

        xdim = model.size[1]
        ydim = model.size[2]
        zdim = model.size[3]

        if haskey(agent, :pos)
            pos = agent.pos
            if model.periodic || checkbound(pos[1],pos[2],pos[3], xdim, ydim, zdim)
                x = mod1(Int(ceil(pos[1])), xdim)
                y = mod1(Int(ceil(pos[2])), ydim)
                z = mod1(Int(ceil(pos[3])), zdim)
                push!(model.patches[(x,y,z)]._extras._agents, agent._extras._id)
                agent._extras._last_grid_loc = (x,y,z)
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
@inline function update_agents_record!(model::GridModel3DDynAgNum) 
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
@inline function update_agents_record!(model::GridModel3DFixAgNum) 
    for agent in model.agents
        _recalculate_position!(agent, model.size, model.periodic)
        _update_agent_record!(agent)
    end
end


"""
$(TYPEDSIGNATURES)

This function is for use from within the module and is not exported.
"""
@inline function update_patches_record!(model::GridModel3D)
    if length(model.record.pprops)>0 
        for k in 1:model.size[3]
            for j in 1:model.size[2]
                for i in 1:model.size[1]
                    patch_dict = unwrap(model.patches[(i, j, k)])
                    patch_data = unwrap_data(model.patches[(i,j, k)])
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
@inline function do_after_model_step!(model::GridModel3DDynAgNum)
    
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
@inline function do_after_model_step!(model::GridModel3DFixAgNum)

    update_agents_record!(model)

    update_patches_record!(model)

    _update_model_record!(model)

    getfield(model, :tick)[] += 1
end





#################
"""
$(TYPEDSIGNATURES)
"""
@inline function _draw_agents_interact_frame(vis, model::GridModel3DDynAgNum, frame, scl)
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
            index = frame- agent._extras._birth_time+1
            draw_agent_interact_frame(vis, agent, model, index, scl)
        end
    end

end

@inline function _draw_agents_interact_frame(vis, model::GridModel3DFixAgNum, frame, scl)
    for agent in model.agents
        draw_agent_interact_frame(vis, agent, model, frame, scl)
    end
end



"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::GridModel3DDynAgNum, frame)
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        if (agent._extras._birth_time<= frame)&&(frame<= agent._extras._death_time)
            draw_agent(vis, agent, model, frame - agent._extras._birth_time +1)
        else
            setvisible!(vis["agents"]["$(agent._extras._id)"], false)
        end
    end
end


"""
$(TYPEDSIGNATURES)
"""
@inline function draw_agents_and_patches(vis, model::GridModel3DFixAgNum, frame)
    show_grid = model.parameters._extras._show_space
    if show_grid
        if :color in model.record.pprops
            draw_patches(vis, model, frame)
        end
    end

    for agent in model.agents
        draw_agent(vis, agent, model, frame)
    end
end
