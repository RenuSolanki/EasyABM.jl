
"""
$(TYPEDSIGNATURES)
"""
@inline function checkbound(x, y, xdim, ydim)
    (x>0)&&(x<=xdim)&&(y>0)&&(y<=ydim)
end




"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist))) where {T,S,P<:Periodic} # -range to range for both x and y
    x,y = patch
    lst = NTuple{2, Int}[]
    for i in -range:range
        for j in -range:range
            if dist_func(patch, (x+i,y+j))<=dist
                pnew = (mod1(x+i, model.size[1]), mod1(y+j, model.size[2]))
                if pnew != (x,y)
                    push!(lst, pnew)
                end
            end
        end
    end

    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < range+1
        unique!(lst)
    end

    return lst
end

"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist))) where {T,S,P<:NPeriodic}
    x,y = patch
    lst = NTuple{2, Int}[]

    for i in -range:range
        for j in -range:range
            if (i,j)!=(0,0) && (dist_func(patch, (x+i,y+j)) <= dist)
                pnew = (x+i, y+j)
                if all(1 .<= pnew) && all(pnew .<= model.size)
                    push!(lst, pnew)
                end
            end
        end
    end

    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < range+1
        unique!(lst)
    end

    return lst
end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches(agent::Agent2D{Symbol, Any, <:AbstractFloat}, model::SpaceModel2D, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist)))
    patch = getfield(agent, :last_grid_loc)
    return neighbor_patches(patch, model, dist, dist_func=dist_func, range=range)
end


"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches(agent::Agent2D{Symbol, Any, Int}, model::SpaceModel2D, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist)))
    patch = agent.pos
    return neighbor_patches(patch, model, dist, dist_func=dist_func, range=range)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::Agent2D{Symbol, Any}, model::SpaceModel2D{T,S,P}, dist::Int) where {T, S<:AbstractFloat, P<:Periodic}
    x,y = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    id = getfield(agent, :id)
    id_list = Int[]
    for j in -dist:dist
        for i in -dist:dist
            x_n = mod1(x+i, xdim)
            y_n = mod1(y+j, ydim)
            ags = model.patches[x_n, y_n].agents # all these agents are active for any inactive agent is removed from its container
            for l in ags
                if l != id
                    push!(id_list, l)
                end
            end
        end
    end

    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end

    return (agent_with_id(l,model) for l in id_list)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::Agent2D{Symbol, Any}, model::SpaceModel2D{T,S,P}, dist::Int) where {T, S<:AbstractFloat, P<:NPeriodic}
    x,y = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    id = getfield(agent, :id)
    id_list = Int[]

    for j in -dist:dist
        for i in -dist:dist
            if checkbound(x+i, y+j, xdim, ydim)
                ags = model.patches[x+i,y+j].agents
                for l in ags
                    if l != id::Int
                        push!(id_list, l)
                    end
                end
            end
        end
    end


    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end

    return (agent_with_id(l,model) for l in id_list)
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::Agent2D{Symbol, Any}, model::SpaceModel2D{T,S,P}, dist::Int) where {T, S<:Int, P<:Periodic}
    x,y = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    id_list = Int[]
    id = getfield(agent, :id)

    for j in -dist:dist
        for i in -dist:dist
            x_n = mod1(x+i, xdim)
            y_n = mod1(y+j, ydim)
            ags = model.patches[x_n, y_n].agents # all these agents are active for any inactive agent is removed from its container
            for l in ags
                if l != id
                    push!(id_list, l)
                end
            end
        end
    end

    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end
    

    return (agent_with_id(l,model) for l in id_list)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::Agent2D{Symbol, Any}, model::SpaceModel2D{T,S,P}, dist::Int) where {T, S<:Int, P<:NPeriodic}
    x,y = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    id_list = Int[]
    id = getfield(agent, :id)

    for j in -dist:dist
        for i in -dist:dist
            if checkbound(x+i, y+j, xdim, ydim)
                ags = model.patches[x+i, y+j].agents
                for l in ags
                    if l != id
                        push!(id_list, l)
                    end
                end
            end
        end
    end

    sz = min(model.size...)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end
    

    return (agent_with_id(l,model) for l in id_list)
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
function _find_eu_neighbors(agent::Agent2D{Symbol, Any}, neighbors_list, model::SpaceModel2D{T, S, P},dist ) where {T, S<:Union{Int, AbstractFloat}, P<:NPeriodic}
    distsq = dist^2
    return Iterators.filter(ag->begin vec = ag.pos .- agent.pos; dotprod(vec,vec)<distsq end, neighbors_list)       
end


"""
$(TYPEDSIGNATURES)
"""
function _find_eu_neighbors(agent::Agent2D{Symbol, Any}, neighbors_list, model::SpaceModel2D{T, S, P},dist ) where {T, S<:Union{Int, AbstractFloat}, P<:Periodic}
    distsq = dist^2
    xdim, ydim = model.size
    return Iterators.filter(ag-> toroidal_distancesq(ag.pos, agent.pos, xdim, ydim)<distsq, neighbors_list)
end



"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:grid`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
function neighbors(agent::Agent2D, model::SpaceModel2D{Mortal, S, P}, dist::Number=1.0; metric::Symbol =:euclidean) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{Symbol, Any, S, P}[])
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
function neighbors(agent::Agent2D, model::SpaceModel2D{Static}, dist::Number=1.0; metric::Symbol =:euclidean)
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
"""
function grid_neighbors(agent::Agent2D, model::SpaceModel2D{Mortal, S, P}, dist::Int=1) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{Symbol, Any, S, P}[])
    end
    return _get_neighbors(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function grid_neighbors(agent::Agent2D, model::SpaceModel2D{Static}, dist::Int=1)

    return _get_neighbors(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function euclidean_neighbors(agent::Agent2D, model::SpaceModel2D{Mortal, S, P}, dist::Number=1.0) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{Symbol, Any, S, P}[])
    end
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)
    return _find_eu_neighbors(agent, neighbors_list, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function euclidean_neighbors(agent::Agent2D, model::SpaceModel2D{Static}, dist::Number=1.0)
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)
    return _find_eu_neighbors(agent, neighbors_list, model, dist)
end



"""
$(TYPEDSIGNATURES)

Returns a random patch where no agents are present. Rerurns nothing if there is no such patch.
"""
function random_empty_patch(model::SpaceModel2D; search_method = :exact, attempts=*(model.size...))
    if search_method !=:exact
        a,b = model.size
        for i in 1:attempts
            x,y = rand(1:a), rand(1:b)
            if length(model.patches[x,y].agents) == 0
                return (x,y)
            end
        end
        return nothing
    else
        empty_patches = Tuple{Int, Int}[]
        n = 0
        for p in CartesianIndices(model.patches)
            if length(model.patches[p].agents) == 0
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
end



"""
$(TYPEDSIGNATURES)

Returns patches satisfying the given condition.
"""
function get_patches(model::SpaceModel2D, condition::Function )
    patches =  ((i,j) for i in 1:model.size[1] for j in 1:model.size[2])
    req_patches = Iterators.filter(pt->condition(model.patches[pt...]), patches)
    return req_patches
end


"""
$(TYPEDSIGNATURES)

Returns patches satisfying the given condition.
"""
function get_patches(model::SpaceModel2D)
    return ((i,j) for i in 1:model.size[1] for j in 1:model.size[2])
end


"""
$(TYPEDSIGNATURES)

Returns number of patches satisfying the given condition.
"""
function num_patches(model::SpaceModel2D, condition::Function )
    return count(x->true,get_patches(model, condition))
end


"""
$(TYPEDSIGNATURES)

Returns number of patches satisfying the given condition.
"""
function num_patches(model::SpaceModel2D)
    return model.parameters._extras._num_patches::Int
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent2D{Symbol, Any, <:AbstractFloat})
    return getfield(agent, :last_grid_loc)
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent2D{Symbol, Any, Int})
    return agent.pos
end

"""
$(TYPEDSIGNATURES)

Returns list of agents at a given patch.
"""
function agents_at(patch, model::SpaceModel2D)
    lst = model.patches[patch...].agents
    return (agent_with_id(l, model) for l in lst)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{Mortal, S, P}, condition::Function) where {S<:Union{Int, AbstractFloat}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> (ag._extras._active::Bool)&&(condition(ag)), all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{Mortal, S, P}) where {S<:Union{Int, AbstractFloat}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return  Iterators.filter(ag->ag._extras._active::Bool, all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{Static}, condition::Function )
    return Iterators.filter(ag->condition(ag), model.agents)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{Static})
    return (ag for ag in model.agents)
end


"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::SpaceModel2D{Mortal, S, P}) where {S<:Union{Int, AbstractFloat}, P<:SType}
    m = model.parameters._extras._len_model_agents::Int

    if i<=m  
        for j in i:-1:1 # will work if the list of model agents has not been shuffled
            ag = model.agents[j]
            if getfield(ag, :id) == i
                return ag
            end
        end
    end

    for ag in model.agents_added # still assuming that the user will avoid shuffling agents list
        if getfield(ag, :id) == i
            return ag
        end
    end

    for j in m:-1:1  # check in model.agents list beginning from the end as the initial part has been checked above
        ag = model.agents[j]
        if getfield(ag, :id) == i 
            return ag
        end
    end

    for ag in model.agents_killed# finally check in the list of killed agents
        if getfield(ag, :id) == i
            return ag
        end
    end

    return nothing
    
end

"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::SpaceModel2D{Static})
    if getfield(model.agents[i], :id) == i  # will work if agents list has not been shuffled
        return model.agents[i]
    end

    for ag in model.agents
        if getfield(ag, :id) == i 
            return ag
        end
    end

    return nothing
end



