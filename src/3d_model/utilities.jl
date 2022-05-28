
"""
$(TYPEDSIGNATURES)
"""
@inline function checkbound(x, y, z, xdim, ydim, zdim)
    (x>0)&&(x<=xdim)&&(y>0)&&(y<=ydim)&&(z>0)&&(z<=zdim)
end



"""
$(TYPEDSIGNATURES)

Returns patches neighboring given agent's patch.
"""
function neighbor_patches(agent::AgentDict3D, model::GridModel3D, dist::Int)
    pos = agent.pos
    patch = Int.(ceil.(tuple(pos...)))
    x,y,z = patch
    lst = NTuple{3, Int}[]
    if model.periodic
        for i in -dist:dist
            for j in -dist:dist
                for k in -dist:dist
                    a,b,c = x+i, y+j, z+k
                    pnew= mod1.((a,b,c), model.size)
                    if pnew != (x,y,z)
                        push!(lst, pnew)
                    end
                end
            end
        end
    elseif agent._extras._last_grid_loc != Inf
        for i in -dist:dist
            for j in -dist:dist
                for k in -dist:dist
                    pnew = x+i, y+j, z+k
                    if (pnew != (x,y,z)) && all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
                end
            end
        end
    end
    return unique(lst)
end


"""
$(TYPEDSIGNATURES)

Returning patches neighboring given patch.
"""
function neighbor_patches(patch::Tuple{Int, Int, Int}, model::GridModel3D, dist::Int)
    x,y,z = patch
    lst = NTuple{3, Int}[]
    if model.periodic
        for i in -dist:dist
            for j in -dist:dist
                for k in -dist:dist
                    a,b,c = x+i, y+j, z+k
                    pnew= mod1.((a,b,c), model.size)
                    if pnew != (x,y,z)
                        push!(lst, pnew)
                    end
                end
            end
        end
    else
        for i in -dist:dist
            for j in -dist:dist
                for k in -dist:dist
                    pnew = x+i, y+j, z+k
                    if (pnew != (x,y,z)) && all(1 .<= pnew) && all(pnew .<= model.size)
                        push!(lst, pnew)
                    end
                end
            end
        end
    end
    return unique(lst)
     
end



"""
$(TYPEDSIGNATURES)
"""
@inline function _get_neighbors(agent::AgentDict3D, model::GridModel3D, dist)
    x,y,z = agent.pos
    xdim = model.size[1]
    ydim = model.size[2]
    zdim = model.size[3]
    neighbors_list = Vector{AgentDict3D{Symbol, Any}}()
    id_list = Int[]
    if model.periodic
        for k in -dist:dist
            for j in -dist:dist
                for i in -dist:dist
                    x_n = mod1(Int(ceil(x+i)), xdim)
                    y_n = mod1(Int(ceil(y+j)), ydim)
                    z_n = mod1(Int(ceil(z+k)), zdim)
                    ags = model.patches[x_n, y_n, z_n]._extras._agents # all these agents are active for any inactive agent is removed from its container
                    for l in ags
                        if l !=agent._extras._id
                            push!(id_list, l)
                        end
                    end
                end
            end
        end
    elseif agent._extras._last_grid_loc !=Inf
        for k in -dist:dist
            for j in -dist:dist
                for i in -dist:dist
                    if checkbound(x+i, y+j, z+k, xdim, ydim, zdim)
                        ags = model.patches[Int(ceil(x+i)), Int(ceil(y+j)), Int(ceil(z+k))]._extras._agents
                        for l in ags
                            if l != agent._extras._id
                                push!(id_list, l)
                            end
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
function _find_eu_neighbors(agent, neighbors_list::Vector{AgentDict3D{Symbol, Any}},model::GridModel3D,dist )
        distsq = dist^2
        xdim = model.size[1]
        ydim = model.size[2]
        zdim = model.size[3]
        eu_neighbors_list = Vector{AgentDict3D{Symbol, Any}}()
        if !model.periodic
            for ag in neighbors_list
                vec = ag.pos - agent.pos
                if (ag!=agent)&& (dotproduct(vec, vec)<distsq)
                    push!(eu_neighbors_list, ag)
                end
            end
            return eu_neighbors_list
        else
            for ag in neighbors_list
                if (ag!=agent)&& (toroidal_distancesq(ag.pos, agent.pos, xdim, ydim, zdim)<distsq)
                    push!(eu_neighbors_list, ag)
                end
            end

            return eu_neighbors_list

        end
end


"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:chessboard`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
@inline function neighbors(agent::AgentDict3D, model::GridModel3DDynAgNum, dist::Number=1.0; metric::Symbol =:chessboard)
    if !(agent._extras._active)
        return Vector{AgentDict3D{Symbol, Any}}()
    end
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)

    if metric == :chessboard
        return neighbors_list
    end

    if metric == :euclidean
        eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
        return eu_neighbors
    end

end



"""
$(TYPEDSIGNATURES)

Returns active neighboring agents to given agent. If the metric is `:chessboard`, then with dist =0 only agents present in the current 
block of the given agent are returned; with dist=1, agents in the current block of the given agent along with agents in the neighbouring 
8 blocks are returned; with dist=2 agents in the current block of given agent, along with agents in 24 nearest blocks are returned, and 
so on. With metric = `:euclidean` the agents within Euclidean distance `dist` are returned.
"""
@inline function neighbors(agent::AgentDict3D, model::GridModel3DFixAgNum, dist::Number=1.0; metric::Symbol =:chessboard)
    distint = Int(ceil(dist))
    neighbors_list = _get_neighbors(agent, model, distint)

    if metric == :chessboard
        return neighbors_list
    end

    if metric == :euclidean
        eu_neighbors = _find_eu_neighbors(agent, neighbors_list, model, dist)
        return eu_neighbors
    end

end


"""
$(TYPEDSIGNATURES)

Returns a random patch where no agents are present. Returns missing if there is no such patch.
"""
function random_empty_patch(model::GridModel3D)
    patches = [(i,j, k) for i in 1:model.size[1] for j in 1:model.size[2] for k in 1:model.size[3]]
    empty_patches = patches[[length(model.patches[patch...]._extras._agents)==0 for patch in patches]]
    n = length(empty_patches)
    if n>0
        m = rand(1:n)
        return empty_patches[m]
    else
        return missing
    end
end


"""
$(TYPEDSIGNATURES)

Returns patches satisfying given condition.
"""
function get_patches(model::GridModel3D, condition::Function=_default_true)
    patches = [(i,j, k) for i in 1:model.size[1] for j in 1:model.size[2] for k in 1:model.size[3]]
    req_patches = patches[[ condition(model.patches[pt...]) for pt in patches]]
    return req_patches
end


"""
$(TYPEDSIGNATURES)

Returns number of patches satisfying given condition.
"""
function num_patches(model::GridModel3D, condition::Function = _default_true )
    return length(get_patches(model, condition))
end
