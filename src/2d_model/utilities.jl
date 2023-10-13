
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
function neighbor_patches_moore(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Int=1) where {T,S,P<:PeriodicType} # -range to range for both x and y 
    
    # patch_dict = unwrap(model.patches[patch...])
    # key = Symbol((metric, dist))
    # if haskey(patch_dict, key)
    #     return patch_dict[key]
    # end
    x,y = patch
    lst = NTuple{2, Int}[]
    xdim = model.size[1]
    ydim = model.size[2]
    for i in -dist:dist
        for j in -dist:dist
            pnew = (mod1(x+i, xdim), mod1(y+j, ydim))
            if pnew != (x,y)
                push!(lst, pnew)
            end
        end
    end

    sz = min(xdim, ydim)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(lst)
    end
    
    #if dist<=2
    # patch_dict[key] = lst
    #end

    return lst
end

"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches_moore(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Int=1) where {T,S,P<:NPeriodicType}

    x,y = patch
    xdim=model.size[1]
    ydim=model.size[2]
    lst = NTuple{2, Int}[]

    for i in -dist:dist
        for j in -dist:dist
            x_n = x+i
            y_n = y+j 
            if (i,j)!=(0,0) && checkbound(x_n, y_n, xdim, ydim)
                push!(lst, (x_n,y_n))
            end
        end
    end

    # sz = min(size...)
    # if div(sz, 2)+ sz%2 < dist+1
    #     unique!(lst)
    # end

    return lst
end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches_moore(agent::Agent2D, model::SpaceModel2D, dist::Int=1)
    patch = getfield(agent, :last_grid_loc)::Tuple{Int, Int}
    return neighbor_patches_moore(patch, model, dist)
end


#################
##############
"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches_neumann(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Int=1) where {T,S,P<:PeriodicType} # -range to range for both x and y 
    
    # patch_dict = unwrap(model.patches[patch...])
    # key = Symbol((metric, dist))
    # if haskey(patch_dict, key)
    #     return patch_dict[key]
    # end
    x,y = patch
    lst = NTuple{2, Int}[]
    xdim = model.size[1]
    ydim = model.size[2]
    for i in -dist:dist
        for j in -dist:dist
            if manhattan_distance(patch, (x+i,y+j))<=dist
                pnew = (mod1(x+i, xdim), mod1(y+j, ydim))
                if pnew != (x,y)
                    push!(lst, pnew)
                end
            end
        end
    end

    sz = min(xdim, ydim)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(lst)
    end
    
    #if dist<=2
    # patch_dict[key] = lst
    #end

    return lst
end

"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given agent's patch.
"""
function neighbor_patches_neumann(patch::Tuple{Int, Int}, model::SpaceModel2D{T,S,P}, dist::Int=1) where {T,S,P<:NPeriodicType}

    x,y = patch
    xdim=model.size[1]
    ydim=model.size[2]
    lst = NTuple{2, Int}[]

    for i in -dist:dist
        for j in -dist:dist
            x_n = x+i
            y_n = y+j 
            if (i,j)!=(0,0) && (manhattan_distance(patch, (x_n,y_n)) <= dist) && checkbound(x_n, y_n, xdim, ydim)
                push!(lst, (x_n,y_n))
            end
        end
    end

    # sz = min(size...)
    # if div(sz, 2)+ sz%2 < dist+1
    #     unique!(lst)
    # end

    return lst
end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring the given patch.
"""
function neighbor_patches_neumann(agent::Agent2D, model::SpaceModel2D, dist::Int=1)
    patch = getfield(agent, :last_grid_loc)::Tuple{Int, Int}
    return neighbor_patches_moore(patch, model, dist)
end


"""
$(TYPEDSIGNATURES)
"""
function _get_neighbors(agent::Agent2D, model::SpaceModel2D{T,S,P}, dist::Int) where {T<:MType, S<:Union{Int,Float64}, P<:PeriodicType}
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

    sz = min(xdim, ydim)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end

    return (agent_with_id(l,model) for l in id_list)
end


"""
$(TYPEDSIGNATURES)
"""
function _get_neighbors(agent::Agent2D, model::SpaceModel2D{T,S,P}, dist::Int) where {T<:MType, S<:Union{Int,Float64}, P<:NPeriodicType}
    x,y = getfield(agent, :last_grid_loc)::Tuple{Int, Int} 
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


    # sz = min(model.size...)
    # if div(sz, 2)+ sz%2 < dist+1
    #     unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    # end

    return (agent_with_id(l,model) for l in id_list)
end




#########################
##########################


"""
$(TYPEDSIGNATURES)
"""
function _get_neighbors_neumann(agent::Agent2D, model::SpaceModel2D{T,S,P}, dist::Int) where {T<:MType, S<:Union{Int,Float64}, P<:PeriodicType}
    x,y = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    id = getfield(agent, :id)
    id_list = Int[]
    for j in -dist:dist
        for i in -dist:dist
            if manhattan_distance((x+i,y+j),(x,y))<=dist
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
    end

    sz = min(xdim, ydim)
    if div(sz, 2)+ sz%2 < dist+1
        unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    end

    return (agent_with_id(l,model) for l in id_list)
end


"""
$(TYPEDSIGNATURES)
"""
function _get_neighbors_neumann(agent::Agent2D, model::SpaceModel2D{T,S,P}, dist::Int) where {T<:MType, S<:Union{Int,Float64}, P<:NPeriodicType}
    x,y = getfield(agent, :last_grid_loc)
    xdim = model.size[1]
    ydim = model.size[2]
    id = getfield(agent, :id)
    id_list = Int[]

    for j in -dist:dist
        for i in -dist:dist
            x_n=x+i
            y_n=y+j
            if checkbound(x_n, y_n, xdim, ydim) && (manhattan_distance((x_n,y_n),(x,y))<=dist)
                ags = model.patches[x+i,y+j].agents
                for l in ags
                    if l != id::Int
                        push!(id_list, l)
                    end
                end
            end
        end
    end


    # sz = min(model.size...)
    # if div(sz, 2)+ sz%2 < dist+1
    #     unique!(sort!(id_list)) # unique! directly used with Agents list will be highly inefficient
    # end

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
function _find_eu_neighbors(agent::Agent2D, neighbors_list, model::SpaceModel2D{T, S, P},dist::Real ) where {T<:MType, S<:Union{Int, Float64}, P<:NPeriodicType}
    distsq = dist^2
    return Iterators.filter(ag->begin vec = ag.pos .- agent.pos; dotprod(vec,vec)<distsq end, neighbors_list)       
end


"""
$(TYPEDSIGNATURES)
"""
function _find_eu_neighbors(agent::Agent2D, neighbors_list, model::SpaceModel2D{T, S, P},dist::Real ) where {T<:MType, S<:Union{Int, Float64}, P<:PeriodicType}
    distsq = dist^2
    xdim, ydim = model.size
    return Iterators.filter(ag-> toroidal_distancesq(ag.pos, agent.pos, xdim, ydim)<distsq, neighbors_list)
end



"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent within euclidean distance `dist`. 
"""
function neighbors(agent::Agent2D, model::SpaceModel2D{MortalType, S, P}, dist::Real=1.0) where {S<:Union{Int, Float64}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{S, P, MortalType}[])
    end
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)
    eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
    return eu_neighbors

end


"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent within euclidean distance `dist`. 
"""
function neighbors(agent::Agent2D, model::SpaceModel2D{StaticType}, dist::Real=1.0)
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)

    eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
    return eu_neighbors
end



"""
$(TYPEDSIGNATURES)
"""
function neighbors_moore(agent::Agent2D, model::SpaceModel2D{MortalType, S, P}, dist::Int=1) where {S<:Union{Int, Float64}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{S, P, MortalType}[])
    end
    
    return _get_neighbors(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function neighbors_moore(agent::Agent2D, model::SpaceModel2D{StaticType, S, P},dist::Int=1) where {S<:Union{Int, Float64}, P<:SType}

    return _get_neighbors(agent, model, dist)#_get_grid_neighbors(agent, model, dist, metric=metric)

end


"""
$(TYPEDSIGNATURES)
"""
function neighbors_neumann(agent::Agent2D, model::SpaceModel2D{MortalType, S, P}, dist::Int=1) where {S<:Union{Int, Float64}, P<:SType}
    if !(agent._extras._active::Bool)
        return (ag for ag in Agent2D{S, P, MortalType}[])
    end
    
    return _get_neighbors_neumann(agent, model, dist)

end

"""
$(TYPEDSIGNATURES)
"""
function neighbors_neumann(agent::Agent2D, model::SpaceModel2D{StaticType},dist::Int=1)

    return _get_neighbors_neumann(agent, model, dist)#_get_grid_neighbors(agent, model, dist, metric=metric)

end



"""
$(TYPEDSIGNATURES)

Returns a random patch where no agents are present. Rerurns nothing if there is no such patch.
"""
function random_empty_patch(model::SpaceModel2D)
    empty_patches = filter(pt -> length(model.patches[pt...].agents::Vector{Int})==0, model.patch_locs)
    if length(empty_patches)>0
        return rand(empty_patches)
    else
        return nothing
    end
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent2D{<:Float64})
    return getfield(agent, :last_grid_loc)
end

"""
$(TYPEDSIGNATURES)

Returns grid location of the agent.
"""
function get_grid_loc(agent::Agent2D{Int})
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
@inline function get_agents(model::SpaceModel2D{MortalType, S, P}, condition::Function) where {S<:Union{Int, Float64}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return Iterators.filter(ag-> (ag._extras._active::Bool)&&(condition(ag)), all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{MortalType, S, P}) where {S<:Union{Int, Float64}, P<:SType}
    all_agents = [model.agents, model.agents_added]
    all_agents_itr = (ag for i in 1:2 for ag in all_agents[i])
    return  Iterators.filter(ag->ag._extras._active::Bool, all_agents_itr)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{StaticType}, condition::Function )
    return Iterators.filter(ag->condition(ag), model.agents)
end

"""
$(TYPEDSIGNATURES)
"""
@inline function get_agents(model::SpaceModel2D{StaticType})
    return (ag for ag in model.agents)
end


"""
$(TYPEDSIGNATURES)

Returns agent having given id.
"""
function agent_with_id(i::Int, model::SpaceModel2D{MortalType, S, P}) where {S<:Union{Int, Float64}, P<:SType}
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
function agent_with_id(i::Int, model::SpaceModel2D{StaticType})
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



