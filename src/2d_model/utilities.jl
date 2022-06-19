
"""
$(TYPEDSIGNATURES)
"""
@inline function checkbound(x, y, xdim, ydim)
    (x>0)&&(x<=xdim)&&(y>0)&&(y<=ydim)
end


# """
# $(TYPEDSIGNATURES)
# """
# @inline function move_agent!(agent, pos, model::SpaceModel2D)
#     unwrap(agent)[:pos]=GeometryBasics.Vec(Float64(pos[1]),pos[2])
#     update_grid!(agent, model.patches)
# end


"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches(agent::AgentDict2D, model::SpaceModel2D, dist::Int)
    x,y = Int(ceil(agent.pos[1])), Int(ceil(agent.pos[2]))
    lst = NTuple{2, Int}[]
    if model.periodic
        for i in -dist:dist
            for j in -dist:dist
                pnew = (mod1(x+i, model.size[1]), mod1(y+j, model.size[2]))
                if pnew != (x,y)
                    push!(lst, pnew)
                end
            end
        end
    else
        for i in -dist:dist
            for j in -dist:dist
                if (i,j)!=(0,0)
                    pnew = (x+i, y+j)
                    if all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
                end
            end
        end
    end
    return unique!(lst)
end

"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches(agent::AgentDict2DGrid, model::SpaceModel2D, dist::Int)
    x,y = agent.pos
    lst = NTuple{2, Int}[]
    if model.periodic
        for i in -dist:dist
            for j in -dist:dist
                pnew = (mod1(x+i, model.size[1]), mod1(y+j, model.size[2]))
                if pnew != (x,y)
                    push!(lst, pnew)
                end
            end
        end
    else
        for i in -dist:dist
            for j in -dist:dist
                if (i,j)!=(0,0)
                    pnew = (x+i, y+j)
                    if all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
                end
            end
        end
    end
    return unique!(lst)
end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches(patch::Tuple{Int, Int}, model::SpaceModel2D, dist::Int)
    x,y = patch
    lst = NTuple{2, Int}[]
    if model.periodic
        for i in -dist:dist
            for j in -dist:dist
                pnew = (mod1(x+i, model.size[1]), mod1(y+j, model.size[2]))
                if pnew != (x,y)
                    push!(lst, pnew)
                end
            end
        end
    else
        for i in -dist:dist
            for j in -dist:dist
                if (i,j)!=(0,0)
                    pnew = (x+i, y+j)
                    if all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
                end
            end
        end
    end
    return unique!(lst)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::AgentDict2D, model::SpaceModel2D, dist)
    x,y = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    neighbors_list = Vector{AgentDict2D{Symbol, Any}}()
    id_list = Int[]
    if model.periodic
        for j in -dist:dist
            for i in -dist:dist
                x_n = mod1(Int(ceil(x+i)), xdim)
                y_n = mod1(Int(ceil(y+j)), ydim)
                ags = model.patches[x_n, y_n]._extras._agents # all these agents are active for any inactive agent is removed from its container
                for l in ags
                    if l !=agent._extras._id
                        push!(id_list, l)
                    end
                end
            end
        end
    else
        for j in -dist:dist
            for i in -dist:dist
                if checkbound(x+i, y+j, xdim, ydim)
                    ags = model.patches[Int(ceil(x+i)), Int(ceil(y+j))]._extras._agents
                    for l in ags
                        if l != agent._extras._id
                            push!(id_list, l)
                        end
                    end
                end
            end
        end
    end
    unique!(id_list)
    for l in id_list
        ag = agent_with_id(l,model)
        push!(neighbors_list, ag)
    end
    return neighbors_list
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::AgentDict2DGrid, model::SpaceModel2D, dist)
    x,y = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    neighbors_list = Vector{AgentDict2DGrid{Symbol, Any}}()
    id_list = Int[]
    if model.periodic
        for j in -dist:dist
            for i in -dist:dist
                x_n = mod1(x+i, xdim)
                y_n = mod1(y+j, ydim)
                ags = model.patches[x_n, y_n]._extras._agents # all these agents are active for any inactive agent is removed from its container
                for l in ags
                    if l !=agent._extras._id
                        push!(id_list, l)
                    end
                end
            end
        end
    else
        for j in -dist:dist
            for i in -dist:dist
                if checkbound(x+i, y+j, xdim, ydim)
                    ags = model.patches[x+i, y+j]._extras._agents
                    for l in ags
                        if l != agent._extras._id
                            push!(id_list, l)
                        end
                    end
                end
            end
        end
    end
    unique!(id_list)
    for l in id_list
        ag = agent_with_id(l,model)
        push!(neighbors_list, ag)
    end
    return neighbors_list
end


"""
$(TYPEDSIGNATURES)
"""
@inline function toroidal_distancesq(pos1,pos2, xdim, ydim)
    x1,y1=pos1
    x2,y2=pos2
    x1, y1 = mod1(x1, xdim), mod1(y1, ydim)
    x2, y2 = mod1(x2, xdim), mod1(y2, ydim)
    dx = abs(x2-x1)
    dy = abs(y2-y1)
    dx = min(dx, xdim-dx)
    dy = min(dy, ydim-dy)
    return dx^2+dy^2
end


"""
$(TYPEDSIGNATURES)
"""
function _find_eu_neighbors(agent, neighbors_list, model::SpaceModel2D,dist )
        distsq = dist^2
        xdim = model.size[1]
        ydim = model.size[2]
        eu_neighbors_list = typeof(agent)[]
        if !model.periodic
            for ag in neighbors_list
                vec = ag.pos .- agent.pos
                if (ag._extras._id != agent._extras._id)&& (dotproduct(vec, vec)<distsq)
                    push!(eu_neighbors_list, ag)
                end
            end
            return eu_neighbors_list
        else
            for ag in neighbors_list
                if (ag._extras._id != agent._extras._id)&& (toroidal_distancesq(ag.pos, agent.pos, xdim, ydim)<distsq)
                    push!(eu_neighbors_list, ag)
                end
            end

            return eu_neighbors_list
        end
end



"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:grid`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
function neighbors(agent, model::SpaceModel2D{MortalType}, dist::Number=1.0; metric::Symbol =:euclidean)
    if !(agent._extras._active)
        return typeof(agent)[]
    end
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)

    if metric == :grid
        return neighbors_list
    else
        eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
        return eu_neighbors
    end

end


"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:grid`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
function neighbors(agent, model::SpaceModel2D{StaticType}, dist::Number=1.0; metric::Symbol =:euclidean)
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)

    if metric == :grid
        return neighbors_list
    else
        eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
        return eu_neighbors
    end

end


"""
$(TYPEDSIGNATURES)

Returns a random patch where no agents are present. Rerurns nothing if there is no such patch.
"""
function random_empty_patch(model::SpaceModel2D)
    # a,b = model.size
    # while true
    #     x,y = rand(1:a), rand(1:b)
    #     if length(model.patches[x,y]._extras._agents) == 0
    #         return (x,y)
    #     end
    # end
    empty_patches = Tuple{Int, Int}[]
    n = 0
    for p in CartesianIndices(model.patches)
        if length(model.patches[p]._extras._agents) == 0
            push!(empty_patches, Tuple(p))
            n+=1
        end
    end
    if n>0
        return rand(empty_patches)
    else
        return nothing
    end
end



"""
$(TYPEDSIGNATURES)

Returns patches satisfying the given condition.
"""
function get_patches(model::SpaceModel2D, condition::Function = _default_true )
    patches =  [(i,j) for i in 1:model.size[1] for j in 1:model.size[2]]
    if condition == _default_true
        return patches
    end
    req_patches = patches[[ condition(model.patches[pt...]) for pt in patches]]
    return req_patches
end


"""
$(TYPEDSIGNATURES)

Returns number of patches satisfying the given condition.
"""
function num_patches(model::SpaceModel2D, condition::Function = _default_true )
    return length(get_patches(model, condition))
end


"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::AgentDict2D, model::SpaceModel2D)
    return agent._extras._last_grid_loc
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::AgentDict2DGrid, model::SpaceModel2D)
    return agent.pos
end
