####################################
####################################
#    SIMPLE_PROP_GRAPH BEGIN       #
####################################
####################################


struct SimplePropGraph{T} <: AbstractPropGraph{T}
    structure::Dict{Int, Vector{Int}}
    nodesprops::Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}
    edgesprops::Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}
    SimplePropGraph(w::Type{T}) where T<:MType = new{w}(Dict{Int, Vector{Int}}(), 
    Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())
    function SimplePropGraph(structure::Dict{Int, Vector{Int}}, w::Type{T}) where T<:MType
        nodes = keys(structure)
        for i in nodes
            if i in structure[i]
                print("Simple graph can't have loops")
                return nothing
            end
        end
        new{w}(structure, Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())
    end

    function SimplePropGraph(n::Int, w::Type{T}) where T<:MType
        structure = Dict{Int, Vector{Int}}()
        for i in 1:n
            structure[i] = Int[]
        end
        SimplePropGraph(structure,w)
    end
end

vertices(g::SimplePropGraph) = collect(keys(g.structure))

function edges(g::SimplePropGraph)
    _edges = Vector{Tuple{Int, Int}}()
    for i in vertices(g)
        for j in g.structure[i]
            if (i<j)
                push!(_edges, (i,j))
            end
        end
    end
    return _edges
end

nv(g::SimplePropGraph) = length(keys(g.structure))

ne(g::SimplePropGraph) = length(edges(g))


function Base.show(io::IO, ::MIME"text/plain", g::SimplePropGraph) # works with REPL
    println(io, "SimplePropGraph")
    println(io, "vertices: ", vertices(g) )
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "<==>", x[2])
    end
end

function Base.show(io::IO, g::SimplePropGraph) # works with print
    println(io, "SimplePropGraph")
    println(io, "vertices: ", keys(g.structure) )
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "<==>", x[2])
    end
end

function out_links(g::SimplePropGraph, i)
    out_structure = Int[]
    structure = g.structure[i]
    for k in structure
        if k>i
            push!(out_structure, k)
        end
    end
    return out_structure
end


@inline function has_edge(g::SimplePropGraph, i, j)
    if (i in vertices(g)) && (j in g.structure[i])
        return true
    end
    return false
end

@inline function has_edge(g::SimplePropGraph, edge)
    i,j = edge
    if (i in vertices(g)) && (j in g.structure[i])
        return true
    end
    return false
end


function _add_edge!(g::SimplePropGraph, i::Int, j::Int)
    nodes = keys(g.structure)
    if i>j
        i,j= j,i
    end
    if (i in nodes) && (j in nodes) && (i!=j)
        if !(j in g.structure[i])
            push!(g.structure[i],j)
            push!(g.structure[j],i)
        end
    end
end

function _add_edge_f!(g::SimplePropGraph, i::Int, j::Int) #f = checks (i in nodes) && (j in nodes) && (i!=j) done before calling function
    if i>j
        i,j= j,i
    end
    if !(j in g.structure[i])
        push!(g.structure[i],j)
        push!(g.structure[j],i)
    end
end

function _add_edge_with_props!(g::SimplePropGraph, i::Int, j::Int; kwargs...)
    nodes = keys(g.structure)
    dict = Dict{Symbol, Any}(kwargs)
    if i>j
        i,j= j,i
    end
    if (i in nodes) && (j in nodes) && (i!=j)
        if !(j in g.structure[i])
            push!(g.structure[i],j)
            push!(g.structure[j],i)
            g.edgesprops[(i,j)]= PropDataDict(dict)
        end
    end
end

function _add_edge_with_props_f!(g::SimplePropGraph, i::Int, j::Int; kwargs...)# f = checks (i in nodes) && (j in nodes) && (i!=j) done before calling function
    dict = Dict{Symbol, Any}(kwargs)
    if i>j
        i,j= j,i
    end
    
    if !(j in g.structure[i])
        push!(g.structure[i],j)
        push!(g.structure[j],i)
        g.edgesprops[(i,j)]= PropDataDict(dict) 
    end
    
end

function _add_vertex!(g::SimplePropGraph, i::Int)
    nodes = keys(g.structure)
    if !(i in nodes)
        g.structure[i] = Int[]
    end
end

function _add_vertex_f!(g::SimplePropGraph, i::Int) #f = check !(i in nodes) done before calling function
    g.structure[i] = Int[]
end

function _add_vertex_with_props!(g::SimplePropGraph, i::Int; kwargs...)
    nodes = keys(g.structure)
    if !(i in nodes)
        g.structure[i] = Int[]
        dict = Dict{Symbol, Any}(kwargs)
        g.nodesprops[i] = PropDataDict(dict) 
    end
end

function _add_vertex_with_props_f!(g::SimplePropGraph, i::Int; kwargs...) # f= checks !(i in nodes) done before calling function
    g.structure[i] = Int[]
    dict = Dict{Symbol, Any}(kwargs)
    g.nodesprops[i] = PropDataDict(dict)
end

function _rem_vertex!(g::SimplePropGraph, i::Int)
    nodes = keys(g.structure)
    if i in nodes
        for j in g.structure[i]
            x, y = j>i ? (i,j) : (j,i)
            if (x,y) in keys(g.edgesprops)
                delete!(g.edgesprops, (x,y))
            end
            deleteat!(g.structure[j], findfirst(m->m==i, g.structure[j]))   
        end
        if i in keys(g.nodesprops)
            delete!(g.nodesprops, i)
        end
        delete!(g.structure, i)
    end
end

function _rem_vertex_f!(g::SimplePropGraph, i::Int) #f = check (i in nodes) done before calling function
    for j in g.structure[i]
        x, y = j>i ? (i,j) : (j,i)
        if (x,y) in keys(g.edgesprops)
            delete!(g.edgesprops, (x,y))
        end
        deleteat!(g.structure[j], findfirst(m->m==i, g.structure[j]))   
    end
    if i in keys(g.nodesprops)
        delete!(g.nodesprops, i)
    end
    delete!(g.structure, i)
end

function _rem_edge!(g::SimplePropGraph, i::Int, j::Int)
    if i>j
        i,j = j,i
    end
    if (j in keys(g.structure))&&(i in g.structure[j])
        deleteat!(g.structure[j], findfirst(x->x==i,g.strucrure[j]))
        deleteat!(g.structure[i], findfirst(x->x==j,g.strucrure[i]))
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
    end
end


function _rem_edge_f!(g::SimplePropGraph, i::Int, j::Int) #f = checks Set([i, j]) in g.edges done before calling function
    if i>j
        i,j = j,i
    end
    deleteat!(g.structure[j], findfirst(x->x==i,g.strucrure[j]))
    deleteat!(g.structure[i], findfirst(x->x==j,g.strucrure[i]))
    if (i,j) in keys(g.edgesprops)
        delete!(g.edgesprops, (i,j))
    end
end

all_neighbors(g::SimplePropGraph, i::Int) = g.structure[i]
in_neighbors(g::SimplePropGraph, i::Int) = g.structure[i]
out_neighbors(g::SimplePropGraph, i::Int) = g.structure[i]

function _set_edgeprops!(g::SimplePropGraph, i::Int, j::Int; kwargs...)
    if i>j
        i,j=j,i
    end
    dprop = Dict{Symbol, Any}(kwargs)
    if (i,j) in keys(g.edgesprops)
        dc = unwrap(g.edgesprops[(i,j)])
        for (key, value) in dprop
            dc[key] = value
        end  
    elseif (j in keys(g.structure))&&(i in g.structure[j])
        g.edgesprops[(i,j)] = PropDataDict(dprop) 
    end
    return i,j
end

function _set_edgeprops_f!(g::SimplePropGraph, i::Int, j::Int; kwargs...) # f = checks (i,j) in g.edges done before calling the function
    if i>j
        i,j=j,i
    end
    dprop = Dict{Symbol, Any}(kwargs)
    if (i,j) in keys(g.edgesprops)
        dc = unwrap(g.edgesprops[(i,j)])
        for (key, value) in dprop
            dc[key] = value
        end  
    else
        g.edgesprops[(i,j)] = PropDataDict(dprop) 
    end
end

function _set_vertexprops!(g::SimplePropGraph, i::Int; kwargs...)
    dprop = Dict{Symbol, Any}(kwargs)
    if i in keys(g.nodesprops)
        dc = unwrap(g.nodesprops[i])
        for (key, value) in dprop
            dc[key] = value
        end
    elseif i in keys(g.structure)
        g.nodesprops[i] = PropDataDict(dprop)
    end
end

function _set_vertexprops_f!(g::SimplePropGraph, i::Int; kwargs...) # f = checks i in keys(g.structure) done before calling function
    dprop = Dict{Symbol, Any}(kwargs)
    if i in keys(g.nodesprops)
        dc = unwrap(g.nodesprops[i])
        for (key, value) in dprop
            dc[key] = value
        end
    else
        g.nodesprops[i] = PropDataDict(dprop)
    end
end

function _get_edgeprop(g::SimplePropGraph, i::Int, j::Int, key::Symbol)
    if i>j
        i,j=j,i
    end
    if (i,j) in keys(g.edgesprops)
        return unwrap(g.edgesprops[(i,j)])[key]
    end
end

function _get_edgeprop_f(g::SimplePropGraph, i::Int, j::Int, key::Symbol) #f = checks (i,j) in keys(g.edgesprops) done before calling function
    if i>j
        i,j=j,i
    end
    return unwrap(g.edgesprops[(i,j)])[key]
end

function _get_vertexprop(g::SimplePropGraph, i::Int, key::Symbol)
    if i in keys(g.nodesprops)
        return unwrap(g.nodesprops[i])[key]
    end
end

function _get_vertexprop_f(g::SimplePropGraph, i::Int, key::Symbol) #f = checks i in keys(g.nodesprops) done before calling function
    return unwrap(g.nodesprops[i])[key]
end

is_directed(g::SimplePropGraph) = false
is_static(g::SimplePropGraph) = typeof(g) <: SimplePropGraph{StaticType}


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with n vertices. 
"""
create_simple_graph(n::Int; gtype::Type{T}=StaticType) where T<:MType = SimplePropGraph(n,gtype)


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with given structure. 
"""
create_simple_graph(structure::Dict{Int, Vector{Int}}; gtype::Type{T}=StaticType) where T<: MType = SimplePropGraph(structure,gtype)


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for given Adjacency matrix. 
"""
function create_simple_graph(A::Matrix{Int}; gtype::Type{T}=StaticType) where T<: MType
    n, m = size(A)
    if (n != m)||(A != A')
        print("Adjacency matrix needs to be symmetric for a simple graph")
        return nothing
    end
    structure = Dict{Int, Vector{Int}}()
    nodes = collect(1:n)
    for j in 1:n
        mask = Bool.(A[:,j])
        structure[j] = copy(nodes[mask])
    end
    SimplePropGraph(structure,gtype)
end


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for adjacency_matrix given as a Sparse Matrix. 
"""
function create_simple_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64}; gtype::Type{T}=StaticType) where T<:MType
    m = A.m
    n = A.n
    rowsa, colsa, vals = findnz(A)
    valsmask = vals .== 1
    rows = rowsa[valsmask]
    cols = colsa[valsmask]

    
    if (n != m)||(A != A')
        print("Adjacency matrix needs to be symmetric for a simple graph")
        return nothing
    end
    structure = Dict{Int, Vector{Int}}()
    nodes = collect(1:n)
    for i in nodes
        if !(i in rows)
            structure[i] = Int[]
        else
            mask = rows .== i
            structure[i] = copy(cols[mask])
        end
    end
    SimplePropGraph(structure,gtype)
end

"""
$(TYPEDSIGNATURES)

Creates a simple prop graph from a given simple graph created with Graphs.jl. 
"""
function create_simple_graph(g::SimpleGraph{Int64}; gtype::Type{T}=StaticType) where T<:MType
    ad_mat = adjacency_matrix(g)
    create_simple_graph(ad_mat, gtype=gtype)
end


"""
$(TYPEDSIGNATURES)

Returns Adjacency matrix as a Sparse Matrix for a given simple prop graph.
"""
function adjacency_matrix(g::SimplePropGraph)
    structure = g.structure
    rows = Int[]
    cols = Int[]
    vals = Int[]
    for node in keys(structure)
        for x in structure[node]
            push!(rows, node)
            push!(cols, x)
            push!(vals, 1)
        end
    end
    sparse(rows, cols, vals)
end
####################################
####################################
#    SIMPLE_PROP_GRAPH END         #
####################################
####################################

####################################
####################################
#      DIR_PROP_GRAPH BEGIN        #
####################################
####################################

struct DirPropGraph{T}<: AbstractPropGraph{T}
    in_structure::Dict{Int, Vector{Int}}
    out_structure::Dict{Int, Vector{Int}}
    nodesprops::Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}
    edgesprops::Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}
    DirPropGraph(w::Type{T}) where T<:MType = new{w}(Dict{Int, Vector{Int}}(), Dict{Int, Vector{Int}}(), Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}(), Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}())
    function DirPropGraph(in_structure::Dict{Int, Vector{Int}},w::Type{T}) where T<:MType
        nodes = vcat(collect(keys(in_structure)), collect(Iterators.flatten(values(in_structure))))
        sort!(nodes)
        unique!(nodes)
        for i in nodes
            if i in in_structure[i]
                print("Simple graph can't have loops")
                return nothing
            end
            if !(i in keys(in_structure))
                in_structure[i]=Int[]
            end
        end
        out_structure = Dict{Int, Vector{Int}}()
        for i in nodes
            out_structure[i] = Int[]
            
            for k in nodes
                if i in in_structure[k]
                    push!(out_structure[i], k)    
                end
            end
        end
        new{w}(in_structure, out_structure, Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}(), Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}())
    end

    function DirPropGraph(n::Int,w::Type{T}) where T <: MType
        dc1 = Dict{Int, Vector{Int}}()
        dc2 = Dict{Int, Vector{Int}}()
        for i in 1:n
            dc1[i] = Int[]
            dc2[i] = Int[]
        end
        new{w}(dc1, dc2, Dict{Int, Union{PropDataDict{Symbol, Any},Bool}}(), Dict{Tuple{Int,Int}, PropDataDict{Symbol, Any}}())
    end
end


out_links(g::DirPropGraph, i) = g.out_structure[i]
vertices(g::DirPropGraph) = collect(keys(g.in_structure))

function edges(g::DirPropGraph)
    eds = Vector{Tuple{Int, Int}}()
    for i in vertices(g)
        for j in in_structure[i]
            push!(eds, (j, i))
        end
    end 
    return eds 
end

nv(g::DirPropGraph) = length(vertices(g))

ne(g::DirPropGraph) = length(edges(g))


function Base.show(io::IO, ::MIME"text/plain", g::DirPropGraph) # works with REPL
    println(io, "DirPropGraph")
    println(io, "vertices: ", vertices(g))
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "==>", x[2])
    end
end

function Base.show(io::IO, g::DirPropGraph) # works with print
    println(io, "DirPropGraph")
    println(io, "vertices: ", vertices(g))
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "==>", x[2])
    end
end

@inline function has_edge(g::DirPropGraph, i, j)
    if (i in vertices(g)) && (j in g.out_structure[i])
        return true
    end
    return false
end

@inline function has_edge(g::DirPropGraph, edge)
    i,j = edge
    if (i in vertices(g)) && (j in g.out_structure[i])
        return true
    end
    return false
end

function _add_edge!(g::DirPropGraph, i::Int, j::Int)
    nodes = vertices(g)
    if (i in nodes) && (j in nodes) && (i!=j)
        if !(j in g.out_structure[i])
            push!(g.out_structure[i],j)
            push!(g.in_structure[j], i)
        end
    end
end

function _add_edge_f!(g::DirPropGraph, i::Int, j::Int) #f = checks (i in nodes) && (j in nodes) && (i!=j) done before calling function
    if !(j in g.out_structure[i])
        push!(g.out_structure[i],j)
        push!(g.in_structure[j], i)
    end
end

function _add_edge_with_props!(g::DirPropGraph, i::Int, j::Int; kwargs...)
    dict = Dict{Symbol, Any}(kwargs)
    nodes = vertices(g)
    if (i in nodes) && (j in nodes) && (i!=j)
        if !(j in g.out_structure[i])
            push!(g.out_structure[i],j)
            push!(g.in_structure[j], i)
            g.edgesprops[(i,j)] = PropDataDict(dict)
        end
    end
end

function _add_edge_with_props_f!(g::DirPropGraph, i::Int, j::Int; kwargs...) #f= checks (i in nodes) && (j in nodes) && (i!=j) done before calling function
    dict = Dict{Symbol, Any}(kwargs)
    if !(j in g.out_structure[i])
        push!(g.out_structure[i],j)
        push!(g.in_structure[j], i)
        g.edgesprops[(i,j)] = PropDataDict(dict)
    end

end



function _add_vertex!(g::DirPropGraph, i::Int)
    nodes = vertices(g)
    if !(i in nodes)
        g.in_structure[i] = Int[]
        g.out_structure[i] = Int[]
    end
end

function _add_vertex_f!(g::DirPropGraph, i::Int) #f = checks !(i in nodes) done before
    g.in_structure[i] = Int[]
    g.out_structure[i] = Int[]
end

function _add_vertex_with_props!(g::DirPropGraph, i::Int; kwargs...)
    dict = Dict{Symbol, Any}(kwargs)
    nodes = vertices(g)
    if !(i in nodes)
        g.in_structure[i] = Int[]
        g.out_structure[i] = Int[]
        g.nodesprops[i] = PropDataDict(dict)
    end
end

function _add_vertex_with_props_f!(g::DirPropGraph, i::Int; kwargs...) # f = checks !(i in nodes) done before calling function
    dict = Dict{Symbol, Any}(kwargs)
    g.in_structure[i] = Int[]
    g.out_structure[i] = Int[]
    g.nodesprops[i] = PropDataDict(dict)
end

function _rem_vertex!(g::DirPropGraph, i::Int)
    nodes = vertices(g)
    if i in nodes
        for j in g.out_structure[i]
            if (i,j) in keys(g.edgesprops)
                delete!(g.edgesprops, (i,j))
            end
        end
        for j in g.in_structure[i]
            if (j,i) in keys(g.edgesprops)
                delete!(g.edgesprops, (j,i))
            end
        end
        
        delete!(g.out_structure, i)
        delete!(g.in_structure, i)

        if i in keys(g.nodesprops)
            delete!(g.nodesprops, i)
        end
    end
end


function _rem_vertex_f!(g::DirPropGraph, i::Int) # f = checks i in nodes done before calling function
    for j in g.out_structure[i]
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
    end
    for j in g.in_structure[i]
        if (j,i) in keys(g.edgesprops)
            delete!(g.edgesprops, (j,i))
        end
    end
    
    delete!(g.out_structure, i)
    delete!(g.in_structure, i)

    if i in keys(g.nodesprops)
        delete!(g.nodesprops, i)
    end
end

function _rem_edge!(g::DirPropGraph, i::Int, j::Int)
    if (i in keys(g.out_structure)) && (j in g.out_structure[i])
        deleteat!(g.out_structure[i], findfirst(x->x==j, g.out_structure[i]))
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
    end
end

function _rem_edge_f!(g::DirPropGraph, i::Int, j::Int) # f = checks (i,j) in g.edges done before calling function
    deleteat!(g.out_structure[i], findfirst(x->x==j, g.out_structure[i]))
    if (i,j) in keys(g.edgesprops)
        delete!(g.edgesprops, (i,j))
    end
end

in_neighbors(g::DirPropGraph, i::Int) = g.in_structure[i]
out_neighbors(g::DirPropGraph, i::Int) = g.out_structure[i]
all_neighbors(g::DirPropGraph, i::Int) = unique!(sort!(vcat(g.in_structure[i], g.out_structure[i])))

function _set_edgeprops!(g::DirPropGraph, i::Int, j::Int; kwargs...)
    dprop = Dict{Symbol, Any}(kwargs)
    if (i,j) in keys(g.edgesprops)
        dc = unwrap(g.edgesprops[(i,j)]) 
        for (key, value) in dprop
            dc[key] = value
        end
    elseif (i in keys(g.out_structure))&&(j in g.out_structure[i])
        g.edgesprops[(i,j)] = PropDataDict(dprop)
    end
    return i,j
end

function _set_edgeprops_f!(g::DirPropGraph, i::Int, j::Int; kwargs...) #f = checks (i,j) in g.edges done before calling function
    dprop = Dict{Symbol, Any}(kwargs)
    if (i,j) in keys(g.edgesprops)
        dc = unwrap(g.edgesprops[(i,j)]) 
        for (key, value) in dprop
            dc[key] = value
        end
    else
        g.edgesprops[(i,j)] = PropDataDict(dprop)
    end
end

function _set_vertexprops!(g::DirPropGraph, i::Int; kwargs...)
    dprop = Dict{Symbol, Any}(kwargs)
    if i in keys(g.nodesprops)
        dc = unwrap(g.nodesprops[i])
        for (key, value) in dprop
            dc[key] = value
        end    
    elseif i in vertices(g)
        g.nodesprops[i]=PropDataDict(dprop)
    end
end

function _set_vertexprops_f!(g::DirPropGraph, i::Int; kwargs...) #f = checks i in g.nodes done before calling function
    dprop = Dict{Symbol, Any}(kwargs)
    if i in keys(g.nodesprops)
        dc = unwrap(g.nodesprops[i])
        for (key, value) in dprop
            dc[key] = value
        end    
    else
        g.nodesprops[i]=PropDataDict(dprop)
    end
end

function _get_edgeprop(g::DirPropGraph, i::Int, j::Int, key::Symbol)
    if (i,j) in keys(g.edgesprops)
        return unwrap(g.edgesprops[(i,j)])[key]
    end
end

function _get_edgeprop_f(g::DirPropGraph, i::Int, j::Int, key::Symbol) #f = checks (i,j) in keys(g.edgesprops) done before
    return unwrap(g.edgesprops[(i,j)])[key]
end

function _get_vertexprop(g::DirPropGraph, i::Int, key::Symbol)
    if i in keys(g.nodesprops)
        return unwrap(g.nodesprops[i])[key]
    end
end

function _get_vertexprop_f(g::DirPropGraph, i::Int, key::Symbol) #f = checks i in keys(g.nodesprops) done before calling function 
    return unwrap(g.nodesprops[i])[key]
end


is_directed(g::DirPropGraph) = true
is_static(g::DirPropGraph) = typeof(g) <: DirPropGraph{StaticType}

"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with n vertices. 
"""
create_dir_graph(n::Int;gtype::Type{T}=StaticType) where T <: MType = DirPropGraph(n,gtype)

"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with given structure. 
"""
create_dir_graph(in_structure::Dict{Int, Vector{Int}}; gtype::Type{T}=StaticType) where T <: MType = DirPropGraph(in_structure, gtype)


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for given Adjacency matrix. 
"""
function create_dir_graph(A::Matrix{Int}; gtype::Type{T}=StaticType) where T <: MType
    n, m = size(A)
    if (n != m)
        print("Adjacency matrix needs to be a square matrix")
        return nothing
    end
    in_structure = Dict{Int, Vector{Int}}()
    nodes = collect(1:n)
    for j in 1:n
        mask = Bool.(A[:,j])
        in_structure[j] = copy(nodes[mask])
    end
    DirPropGraph(in_structure, gtype)
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for adjacency matrix given as a Sparse Matrix. 
"""
function create_dir_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64}; gtype::Type{T}=StaticType) where T <: MType
    m = A.m
    n = A.n
    rowsa, colsa, vals = findnz(A)
    valsmask = vals .== 1
    rows = rowsa[valsmask]
    cols = colsa[valsmask]

    
    if (n != m)
        print("Adjacency matrix needs to be a square matrix.")
        return nothing
    end
    in_structure = Dict{Int, Vector{Int}}()
    nodes = collect(1:n)
    for i in nodes
        if !(i in cols)
            in_structure[i] = Int[]
        else
            mask = cols .== i
            in_structure[i] = copy(rows[mask])
        end
    end
    DirPropGraph(in_structure,gtype)
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for a given directed graph created with Graphs.jl. 
"""
function create_dir_graph(g::SimpleDiGraph{Int64}; gtype::Type{T}=StaticType) where T <: MType
    ad_mat = adjacency_matrix(g)
    create_dir_graph(ad_mat, gtype = gtype)
end


"""
$(TYPEDSIGNATURES)

Returns Adjacency matrix as a Sparse Matrix for a given directed prop graph.
"""
function adjacency_matrix(g::DirPropGraph)
    out_structure = g.out_structure
    rows = Int[]
    cols = Int[]
    vals = Int[]
    for node in keys(out_structure)
        for x in out_structure[node]
            push!(rows, node)
            push!(cols, x)
            push!(vals, 1)
        end
    end
    sparse(rows, cols, vals)
end
####################################
####################################
#       DIR_PROP_GRAPH END         #
####################################
####################################


####################################
####################################
#  GRAPH_UTILITY_FUNCTIONS BEGIN   #
####################################
####################################

const PropGraphDynTop = Union{SimplePropGraph{MortalType}, DirPropGraph{MortalType}}
const PropGraphFixTop = Union{SimplePropGraph{StaticType}, DirPropGraph{StaticType}}


####################################
####################################
#  GRAPH_UTILITY_FUNCTIONS END     #
####################################
####################################
