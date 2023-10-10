
"""
$(TYPEDSIGNATURES)
"""
@inline function checkbound(x, y, z, xdim, ydim, zdim)
    (x>0)&&(x<=xdim)&&(y>0)&&(y<=ydim)&&(z>0)&&(z<=zdim)
end


# """
# $(TYPEDSIGNATURES)
# """
# @inline function move_agent!(agent, pos, model::SpaceModel3D)
#     unwrap(agent)[:pos]=GeometryBasics.Vec(Float64(pos[1]),pos[2], pos[3])
#     update_grid!(agent, model.patches)
# end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring given agent's patch.
"""
function neighbor_patches(patch::NTuple{3,Int}, model::SpaceModel3D{T,S,P}, dist::Real;  dist_func::Function = moore_distance, range::Int=Int(ceil(dist))) where {T,S,P<:Periodic}
    x,y,z = patch
    lst = NTuple{3, Int}[]
    for i in -range:range
        for j in -range:range
            for k in -range:range
                if dist_func(patch, (x+i,y+j,z+k)) <= dist
                    pnew = (mod1(x+i, model.size[1]), mod1(y+j, model.size[2]), mod1(z+k, model.size[3]))
                    if pnew != (x,y,z)
                        push!(lst, pnew)
                    end
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

Returns patches neighboring given agent's patch.
"""
function neighbor_patches(patch::NTuple{3,Int}, model::SpaceModel3D{T,S,P}, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist))) where {T,S,P<:NPeriodic}
    x,y,z = patch
    lst = NTuple{3, Int}[]
    for i in -range:range
        for j in -range:range
            for k in -range:range
                if (i,j,k)!=(0,0,0) && (dist_func(patch, (x+i,y+j,z+k)) <= dist)
                    pnew = (x+i, y+j, z+k)
                    if all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
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
function neighbor_patches(agent::Agent3D{<:AbstractFloat}, model::SpaceModel3D, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist)))
    patch = getfield(agent, :last_grid_loc)
    return neighbor_patches(patch, model, dist, dist_func=dist_func, range=range)
end


"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches(agent::Agent3D{Int}, model::SpaceModel3D, dist::Real; dist_func::Function = moore_distance, range::Int=Int(ceil(dist)))
    patch = agent.pos
    return neighbor_patches(patch, model, dist, dist_func=dist_func, range=range)
end


"""
$(TYPEDSIGNATURES)
"""
function _get_neighbors(agent::Agent3D, model::SpaceModel3D{T,S,P}, dist::Int) where {T<:MType, S<:AbstractFloat,P<:Periodic}
    x,y,z = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    id = getfield(agent, :id)
    id_list = Int[]

    for k in -dist:dist
        for j in -dist:dist
            for i in -dist:dist
                x_n = mod1(x+i, xdim)
                y_n = mod1(y+j, ydim)
                z_n = mod1(z+k, zdim)
                ags = model.patches[x_n, y_n, z_n].agents # all these agents are active for any inactive agent is removed from its container
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
function _get_neighbors(agent::Agent3D, model::SpaceModel3D{T,S,P}, dist) where {T<:MType, S<:AbstractFloat,P<:NPeriodic}
    x,y,z = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    id = getfield(agent, :id)
    id_list = Int[]
    for k in -dist:dist
        for j in -dist:dist
            for i in -dist:dist
                if checkbound(x+i, y+j, z+k, xdim, ydim, zdim)
                    ags = model.patches[x+i, y+j, z+k].agents
                    for l in ags
                        if l != id
                            push!(id_list, l)
                        end
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
function _get_neighbors(agent::Agent3D, model::SpaceModel3D{T,S,P}, dist) where {T<:MType, S<:Int,P<:Periodic}
    x,y,z = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    id = getfield(agent, :id)
    id_list = Int[]
    
    for k in -dist:dist
        for j in -dist:dist
            for i in -dist:dist
                x_n = mod1(x+i, xdim)
                y_n = mod1(y+j, ydim)
                z_n = mod1(z+k, zdim)
                ags = model.patches[x_n, y_n, z_n].agents # all these agents are active for any inactive agent is removed from its container
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
function _get_neighbors(agent::Agent3D, model::SpaceModel3D{T,S,P}, dist) where {T, S<:Int,P<:NPeriodic}
    x,y,z = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    id = getfield(agent, :id)
    id_list = Int[]
    
    for k in -dist:dist
        for j in -dist:dist
            for i in -dist:dist
                if checkbound(x+i, y+j, z+k, xdim, ydim, zdim)
                    ags = model.patches[x+i, y+j, z+k].agents
                    for l in ags
                        if l != id
                            push!(id_list, l)
                        end
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
@inline function toroidal_distancesq(pos1,pos2, xdim, ydim, zdim)
    x1,y1,z1=pos1
    x2,y2,z2=pos2
    x1, y1, z1 = mod1(x1, xdim), mod1(y1, ydim), mod1(z1, zdim)
    x2, y2, z2 = mod1(x2, xdim), mod1(y2, ydim), mod1(z2, zdim)
    dx = abs(x2-x1)
    dy = abs(y2-y1)
    dz = abs(z2-z1)
    dx = min(dx, xdim-dx)
    dy = min(dy, ydim-dy)
    dz = min(dz, zdim-dz)
    return dx^2+dy^2+dz^2
end


"""
$(TYPEDSIGNATURES)
"""
function _find_eu_neighbors(agent::Agent3D, neighbors_list, model::SpaceModel3D{T, S, P},dist::Number ) where {T<:MType, S<:Union{Int, AbstractFloat}, P<:NPeriodic}
        distsq = dist^2
        return Iterators.filter(ag->begin vec = ag.pos .- agent.pos; dotprod(vec,vec)<distsq end, neighbors_list)
end


"""
$(TYPEDSIGNATURES)
"""
function _find_eu_neighbors(agent::Agent3D, neighbors_list, model::SpaceModel3D{T, S,P},dist::Number ) where {T<:MType, S<:Union{Int, AbstractFloat}, P<:Periodic}
        distsq = dist^2
        xdim, ydim, zdim = model.size
        return Iterators.filter(ag-> toroidal_distancesq(ag.pos, agent.pos, xdim, ydim, zdim)<distsq, neighbors_list)
end


"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:grid`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
@inline function neighbors(agent::Agent3D, model::SpaceModel3D{Mortal, S, P}, dist::Number=1.0; metric::Symbol =:euclidean) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent3D{S, P, Mortal}[])
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
@inline function neighbors(agent::Agent3D, model::SpaceModel3D{Static}, dist::Number=1.0; metric::Symbol =:grid)
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
function grid_neighbors(agent::Agent3D, model::SpaceModel3D{Mortal, S, P}, dist::Int=1) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent3D{S, P, Mortal}[])
    end
    return _get_neighbors(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function grid_neighbors(agent::Agent3D, model::SpaceModel3D{Static}, dist::Int=1)

    return _get_neighbors(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function euclidean_neighbors(agent::Agent3D, model::SpaceModel3D{Mortal, S, P}, dist::Number=1.0) where {S<:Union{Int, AbstractFloat}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent3D{S, P, Mortal}[])
    end
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)
    return _find_eu_neighbors(agent, neighbors_list, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function euclidean_neighbors(agent::Agent3D, model::SpaceModel3D{Static}, dist::Number=1.0)
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)
    return _find_eu_neighbors(agent, neighbors_list, model, dist)
end


"""
$(TYPEDSIGNATURES)

Returns a random patch where no agents are present. Returns nothing if there is no such patch.
"""
function random_empty_patch(model::SpaceModel3D; search_method = :exact, attempts=*(model.size...))
    if search_method !=:exact
        a,b,c = model.size
        for i in 1:attempts
            x,y,z = rand(1:a), rand(1:b), rand(1:c)
            if length(model.patches[x,y,z].agents) == 0
                return (x,y,z)
            end
        end
        return nothing
    else
        empty_patches = Tuple{Int, Int, Int}[]
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

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent3D{<:AbstractFloat})
    return getfield(agent, :last_grid_loc)
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent3D{Int})
    return agent.pos
end

"""
$(TYPEDSIGNATURES)

Returns list of agents at a given patch.
"""
function agents_at(patch, model::SpaceModel3D)
    lst = model.patches[patch...].agents
    return (agent_with_id(l, model) for l in lst)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel3D{Mortal, S, P}, condition::Function) where {S<:Union{Int, <:AbstractFloat}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> (ag._extras._active::Bool)&&(condition(ag)), all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel3D{Mortal, S, P}) where {S<:Union{Int, <:AbstractFloat}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> ag._extras._active::Bool, all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel3D{Static}, condition::Function)
    return Iterators.filter(ag->condition(ag), model.agents)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel3D{Static})
    return (ag for ag in model.agents)
end

"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::SpaceModel3D{Mortal, S, P}) where {S<:Union{Int, AbstractFloat}, P<:SType}
    m = model.parameters._extras._len_model_agents::Int

    if i<=m  
        for j in i:-1:1 # will work if the list of model agents has not been shuffled
            ag = model.agents[j]
            if getfield(ag, :id) == i
                return ag
            end
        end
    end

    for ag in model.agents_added# still assuming that the user will avoid shuffling agents list
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

    for ag in model.agents_killed # finally check in the list of killed agents
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
function agent_with_id(i::Int, model::SpaceModel3D{Static})
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

