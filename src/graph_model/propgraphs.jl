####################################
####################################
#    SIMPLE_PROP_GRAPH BEGIN       #
####################################
####################################


struct SimplePropGraph{T, G<:SimGType} <: AbstractPropGraph{T, G}
    _nodes::Vector{Int}
    structure:: Dict{Int, Vector{Int}}
    nodesprops::Dict{Int, ContainerDataDict{Symbol, Any} }
    edgesprops::Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}

    SimplePropGraph{T}() where {T<:MType} = new{T, SimGType}(Vector{Int}(), Dict{Int, Vector{Int}}(), 
    Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())

    SimplePropGraph(structure::Nothing = nothing, w::T=Static) where T<:MType = new{T, SimGType}(Vector{Int}(), Dict{Int, Vector{Int}}(), 
    Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())
    function SimplePropGraph(structure::Dict{Int, Vector{Int}}, w::T) where T<:MType
        nodes = sort!(collect(keys(structure)))
        for i in nodes
            if i in structure[i]
                print("Simple graph can't have loops")
                return nothing
            end
        end
        new{T, SimGType}(nodes, structure, Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())
    end

    function SimplePropGraph(n::Int, w::T) where T<:MType
        structure = Dict{Int, Vector{Int}}()
        for i in 1:n
            structure[i] = Int[]
        end
        new{T, SimGType}(collect(1:n), structure, Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int, Int}, PropDataDict{Symbol, Any}}())
    end

    function SimplePropGraph(_nodes, structure, nodesprops, edgesprops, w::T) where T<:MType
        return new{T, SimGType}(_nodes, structure, nodesprops, edgesprops)
    end
end

function Base.empty!(graph::SimplePropGraph)
    empty!(graph._nodes)
    empty!(graph.structure)
    empty!(graph.nodesprops)
    empty!(graph.edgesprops)
end

"""
$(TYPEDSIGNATURES)
"""
vertices(g::SimplePropGraph) = (node for node in getfield(g, :_nodes))

function edges(g::SimplePropGraph)
    return ((i,j) for i in keys(g.structure) for j in g.structure[i] if j>i)
end

nv(g::SimplePropGraph) = length(getfield(g, :_nodes))

ne(g::SimplePropGraph) = count(x->true,edges(g))


function Base.show(io::IO, ::MIME"text/plain", g::SimplePropGraph) # works with REPL
    println(io, "SimplePropGraph")
    println(io, "vertices: ", getfield(g, :_nodes) )
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "<==>", x[2])
    end
end

function Base.show(io::IO, g::SimplePropGraph) # works with print
    println(io, "SimplePropGraph")
    println(io, "vertices: ", getfield(g, :_nodes) )
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "<==>", x[2])
    end
end

function out_links(g::SimplePropGraph, i)
    structure = g.structure[i]
    return (k for k in structure if k>i)
end


@inline function has_edge(g::SimplePropGraph, i, j)
    if (i in getfield(g, :_nodes)) && (j in g.structure[i])
        return true
    end
    return false
end

@inline function has_edge(g::SimplePropGraph, edge)
    i,j = edge
    if (i in getfield(g, :_nodes)) && (j in g.structure[i])
        return true
    end
    return false
end


function _add_edge!(g::SimplePropGraph, i::Int, j::Int)
    nodes = getfield(g, :_nodes)
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
    nodes = getfield(g, :_nodes)
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
    nodes = getfield(g, :_nodes)
    if !(i in nodes)
        g.structure[i] = Int[]
        push!(nodes, i)
    end
end

function _add_vertex_f!(g::SimplePropGraph, i::Int) #f = check !(i in nodes) done before calling function
    g.structure[i] = Int[]
    push!(getfield(g, :_nodes), i)
end

function _add_vertex_with_props!(g::SimplePropGraph, i::Int; kwargs...)
    nodes = getfield(g, :_nodes)
    if !(i in nodes)
        g.structure[i] = Int[]
        dict = Dict{Symbol, Any}(kwargs)
        g.nodesprops[i] = ContainerDataDict(dict) 
        push!(nodes, i)
    end
end

function _add_vertex_with_props_f!(g::SimplePropGraph, i::Int; kwargs...) # f= checks !(i in nodes) done before calling function
    g.structure[i] = Int[]
    dict = Dict{Symbol, Any}(kwargs)
    g.nodesprops[i] = ContainerDataDict(dict)
    push!(getfield(g, :_nodes), i)
end

function _rem_vertex!(g::SimplePropGraph, i::Int)
    nodes = getfield(g, :_nodes)
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
        deleteat!(nodes, searchsortedfirst(nodes,i)) 
    end 
end

function _rem_vertex_f!(g::SimplePropGraph, i::Int) #f = check (i in nodes) done before calling function
    num = 0 
    for j in g.structure[i]
        x, y = j>i ? (i,j) : (j,i)
        if (x,y) in keys(g.edgesprops)
            delete!(g.edgesprops, (x,y))
        end
        num+=1
        deleteat!(g.structure[j], findfirst(m->m==i, g.structure[j]))   
    end
    if i in keys(g.nodesprops)
        delete!(g.nodesprops, i)
    end
    delete!(g.structure, i)
    deleteat!(getfield(g, :_nodes), searchsortedfirst(getfield(g, :_nodes),i)) 
    return num # number of edges deleted
end

function _num_edges_at(node, g::SimplePropGraph)
    return length(g.structure[node])
end

function _rem_edge!(g::SimplePropGraph, i::Int, j::Int)
    if i>j
        i,j = j,i
    end
    if (j in getfield(g, :_nodes))&&(i in g.structure[j])
        deleteat!(g.structure[j], findfirst(x->x==i,g.structure[j]))
        deleteat!(g.structure[i], findfirst(x->x==j,g.structure[i]))
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
    end
end


function _rem_edge_f!(g::SimplePropGraph, i::Int, j::Int) #f = checks Set([i, j]) in edges(g) done before calling function
    if i>j
        i,j = j,i
    end
    deleteat!(g.structure[j], findfirst(x->x==i,g.structure[j]))
    deleteat!(g.structure[i], findfirst(x->x==j,g.structure[i]))
    if (i,j) in keys(g.edgesprops)
        delete!(g.edgesprops, (i,j))
    end
end

all_neighbors(g::SimplePropGraph, i::Int) = g.structure[i]
in_neighbors(g::SimplePropGraph, i::Int) =  g.structure[i]
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
    elseif i in getfield(g, :_nodes)
        g.nodesprops[i] = ContainerDataDict(dprop)
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
        g.nodesprops[i] = ContainerDataDict(dprop)
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

"""
$(TYPEDSIGNATURES)
"""
is_digraph(g::SimplePropGraph) = false

"""
$(TYPEDSIGNATURES)
"""
is_static(g::SimplePropGraph{T}) where T<:MType = T <: StaticType


"""
$(TYPEDSIGNATURES)
"""
mortal_type(g::SimplePropGraph{T}) where T<:MType = T


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with n vertices. 
"""
static_simple_graph(n::Int) = SimplePropGraph(n,Static)

"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with n vertices. 
"""
dynamic_simple_graph(n::Int) = SimplePropGraph(n,Mortal)


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with given structure. 
"""
static_simple_graph(structure::Dict{Int, Vector{Int}}) = SimplePropGraph(structure,Static)


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph with given structure. 
"""
dynamic_simple_graph(structure::Dict{Int, Vector{Int}}) = SimplePropGraph(structure,Mortal)


"""
$(TYPEDSIGNATURES)
"""
function convert_type(graph::SimplePropGraph, w::T) where T<:MType
    return SimplePropGraph(getfield(graph, :_nodes), graph.structure, graph.nodesprops, graph.edgesprops, w)
end

@inline function _structure_from_mat(A::Matrix{Int})
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
    return structure
end

"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for given Adjacency matrix. 
"""
function static_simple_graph(A::Matrix{Int}) 
    structure = _structure_from_mat(A) 
    SimplePropGraph(structure,Static)
end


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for given Adjacency matrix. 
"""
function dynamic_simple_graph(A::Matrix{Int}) 
    structure = _structure_from_mat(A) 
    SimplePropGraph(structure,Mortal)
end


@inline function _structure_from_smat(A::SparseArrays.SparseMatrixCSC{Int64, Int64})
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
    return structure
end


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for adjacency_matrix given as a Sparse Matrix. 
"""
function static_simple_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64})
    structure = _structure_from_smat(A)
    SimplePropGraph(structure,Static)
end


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph for adjacency_matrix given as a Sparse Matrix. 
"""
function dynamic_simple_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64})
    structure = _structure_from_smat(A)
    SimplePropGraph(structure,Mortal)
end

"""
$(TYPEDSIGNATURES)

Creates a simple prop graph from a given simple graph created with Graphs.jl. 
"""
function static_simple_graph(g::SimpleGraph{Int64})
    ad_mat = Graphs.adjacency_matrix(g)
    static_simple_graph(ad_mat)
end


"""
$(TYPEDSIGNATURES)

Creates a simple prop graph from a given simple graph created with Graphs.jl. 
"""
function dynamic_simple_graph(g::SimpleGraph{Int64})
    ad_mat = Graphs.adjacency_matrix(g)
    dynamic_simple_graph(ad_mat)
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
    for node in getfield(g, :_nodes)
        for x in structure[node]
            push!(rows, node)
            push!(cols, x)
            push!(vals, 1)
        end
    end
    sparse(rows, cols, vals)
end


"""
$(TYPEDSIGNATURES)
not meant to combine general graph; serves only a specific use case.
"""
function combined_graph(grapha::SimplePropGraph, graphb::SimplePropGraph)
    graphc = deepcopy(grapha)
    nodesc = getfield(graphc, :_nodes)
    structurec = graphc.structure

    nodesb = getfield(graphb, :_nodes)
    structureb = graphb.structure
    for node in nodesb
        push!(nodesc, node)
    end
    sort!(nodesc)
    for (key, value) in structureb
        append!(structurec[key], value)
    end
    return graphc   
end

"""
$(TYPEDSIGNATURES)
not meant to combine general graph; serves only a specific use case.
"""
function combined_graph!(grapha::SimplePropGraph, graphb::SimplePropGraph)
    graphc = grapha
    nodesc = getfield(graphc, :_nodes)
    structurec = graphc.structure

    nodesb = getfield(graphb, :_nodes)
    structureb = graphb.structure

    for node in nodesb
        push!(nodesc, node)
    end
    sort!(nodesc)
    for (key, value) in structureb
        append!(structurec[key], value)
    end
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

struct DirPropGraph{T, G<:DirGType}<: AbstractPropGraph{T, G}
    _nodes::Vector{Int}
    in_structure::Dict{Int, Vector{Int}}
    out_structure::Dict{Int, Vector{Int}}
    nodesprops::Dict{Int, ContainerDataDict{Symbol, Any}}
    edgesprops::Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}
    DirPropGraph(in_structure::Nothing = nothing, w::T=Static) where T<:MType = new{T, DirGType}(Vector{Int}(), Dict{Int, Vector{Int}}(), Dict{Int, Vector{Int}}(), 
    Dict{Int,ContainerDataDict{Symbol, Any}}(), Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}())

    function DirPropGraph(in_structure::Dict{Int, Vector{Int}},w::T) where T<:MType
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
        new{T,DirGType}(nodes, in_structure, out_structure, Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{NTuple{2, Int64}, PropDataDict{Symbol, Any}}())
    end

    function DirPropGraph(n::Int,w::T) where T <: MType
        dc1 = Dict{Int, Vector{Int}}()
        dc2 = Dict{Int, Vector{Int}}()
        for i in 1:n
            dc1[i] = Int[]
            dc2[i] = Int[]
        end
        new{T, DirGType}(collect(1:n), dc1, dc2, Dict{Int, ContainerDataDict{Symbol, Any}}(), Dict{Tuple{Int,Int}, PropDataDict{Symbol, Any}}())
    end

    function DirPropGraph(_nodes, in_structure, out_structure, nodesprops, edgesprops, w::T) where T<:MType
        return new{T, DirGType}(_nodes, in_structure, out_structure, nodesprops, edgesprops)
    end
end

function Base.empty!(graph::DirPropGraph)
    empty!(graph._nodes)
    empty!(graph.in_structure)
    empty!(graph.out_structure)
    empty!(graph.nodesprops)
    empty!(graph.edgesprops)
end


out_links(g::DirPropGraph, i) = (nd for nd in g.out_structure[i])


"""
$(TYPEDSIGNATURES)
"""
vertices(g::DirPropGraph) = (node for node in getfield(g, :_nodes))

function edges(g::DirPropGraph)
    return ((j,i) for i in getfield(g, :_nodes) for j in g.in_structure[i]) 
end

nv(g::DirPropGraph) = length(getfield(g, :_nodes))

ne(g::DirPropGraph) = count(x->true,edges(g))


function Base.show(io::IO, ::MIME"text/plain", g::DirPropGraph) # works with REPL
    println(io, "DirPropGraph")
    println(io, "vertices: ", getfield(g, :_nodes))
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "==>", x[2])
    end
end

function Base.show(io::IO, g::DirPropGraph) # works with print
    println(io, "DirPropGraph")
    println(io, "vertices: ", getfield(g, :_nodes))
    println(io, "edges: ")
    for x in edges(g)
        println(io, x[1], "==>", x[2])
    end
end

@inline function has_edge(g::DirPropGraph, i, j)
    if (i in getfield(g, :_nodes)) && (j in g.out_structure[i])
        return true
    end
    return false
end

@inline function has_edge(g::DirPropGraph, edge)
    i,j = edge
    if (i in getfield(g, :_nodes)) && (j in g.out_structure[i])
        return true
    end
    return false
end

function _add_edge!(g::DirPropGraph, i::Int, j::Int)
    nodes = getfield(g, :_nodes)
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
    nodes = getfield(g, :_nodes)
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
    nodes = getfield(g, :_nodes)
    if !(i in nodes)
        g.in_structure[i] = Int[]
        g.out_structure[i] = Int[]
        push!(nodes, i)
    end
end

function _add_vertex_f!(g::DirPropGraph, i::Int) #f = checks !(i in nodes) done before
    g.in_structure[i] = Int[]
    g.out_structure[i] = Int[]
    push!(getfield(g, :_nodes), i)
end

function _add_vertex_with_props!(g::DirPropGraph, i::Int; kwargs...)
    dict = Dict{Symbol, Any}(kwargs)
    nodes = getfield(g, :_nodes)
    if !(i in nodes)
        g.in_structure[i] = Int[]
        g.out_structure[i] = Int[]
        g.nodesprops[i] = ContainerDataDict(dict)
        push!(nodes, i)
    end
end

function _add_vertex_with_props_f!(g::DirPropGraph, i::Int; kwargs...) # f = checks !(i in nodes) done before calling function
    dict = Dict{Symbol, Any}(kwargs)
    g.in_structure[i] = Int[]
    g.out_structure[i] = Int[]
    g.nodesprops[i] = ContainerDataDict(dict)
    push!(getfield(g, :_nodes), i)
end

function _rem_vertex!(g::DirPropGraph, i::Int)
    nodes = getfield(g, :_nodes)
    if i in nodes
        for j in g.out_structure[i]
            if (i,j) in keys(g.edgesprops)
                delete!(g.edgesprops, (i,j))
            end
            deleteat!(g.in_structure[j], findfirst(m->m==i, g.in_structure[j]))   
        end
        for j in g.in_structure[i]
            if (j,i) in keys(g.edgesprops)
                delete!(g.edgesprops, (j,i))
            end
            deleteat!(g.out_structure[j], findfirst(m->m==i, g.out_structure[j]))   
        end
        
        delete!(g.out_structure, i)
        delete!(g.in_structure, i)

        if i in keys(g.nodesprops)
            delete!(g.nodesprops, i)
        end
        deleteat!(nodes, searchsortedfirst(nodes,i))
    end
end


function _rem_vertex_f!(g::DirPropGraph, i::Int) # f = checks i in nodes done before calling function
    num = 0 
    for j in g.out_structure[i]
        num+=1
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
        deleteat!(g.in_structure[j], findfirst(m->m==i, g.in_structure[j])) 
    end
    for j in g.in_structure[i]
        num+=1
        if (j,i) in keys(g.edgesprops)
            delete!(g.edgesprops, (j,i))
        end
        deleteat!(g.out_structure[j], findfirst(m->m==i, g.out_structure[j])) 
    end
    
    delete!(g.out_structure, i)
    delete!(g.in_structure, i)

    if i in keys(g.nodesprops)
        delete!(g.nodesprops, i)
    end
    deleteat!(getfield(g, :_nodes), searchsortedfirst(getfield(g, :_nodes),i))
    return num
end

function _num_edges_at(node, g::DirPropGraph)
    return length(g.in_structure[node])+length(g.out_structure[node])
end

function _rem_edge!(g::DirPropGraph, i::Int, j::Int)
    if (i in getfield(g, :_nodes)) && (j in g.out_structure[i])
        deleteat!(g.out_structure[i], findfirst(x->x==j, g.out_structure[i]))
        deleteat!(g.in_structure[j], findfirst(x->x==i, g.in_structure[j]))
        if (i,j) in keys(g.edgesprops)
            delete!(g.edgesprops, (i,j))
        end
    end
end

function _rem_edge_f!(g::DirPropGraph, i::Int, j::Int) # f = checks (i,j) in g.edges done before calling function
    deleteat!(g.out_structure[i], findfirst(x->x==j, g.out_structure[i]))
    deleteat!(g.in_structure[j], findfirst(x->x==i, g.in_structure[j]))
    if (i,j) in keys(g.edgesprops)
        delete!(g.edgesprops, (i,j))
    end
end

in_neighbors(g::DirPropGraph, i::Int) = g.in_structure[i] # we don't send generator as these arrays are already stored in memory and user has access to them
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
    elseif i in getfield(g, :_nodes)
        g.nodesprops[i]=ContainerDataDict(dprop)
    end
end

function _set_vertexprops_f!(g::DirPropGraph, i::Int; kwargs...) #f = checks i in getfield(g, :_nodes) done before calling function
    dprop = Dict{Symbol, Any}(kwargs)
    if i in keys(g.nodesprops)
        dc = unwrap(g.nodesprops[i])
        for (key, value) in dprop
            dc[key] = value
        end    
    else
        g.nodesprops[i]=ContainerDataDict(dprop)
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

"""
$(TYPEDSIGNATURES)
"""
is_digraph(g::DirPropGraph) = true

"""
$(TYPEDSIGNATURES)
"""
is_static(g::DirPropGraph{T}) where T<:MType = T <: StaticType


"""
$(TYPEDSIGNATURES)
"""
mortal_type(g::DirPropGraph{T}) where T<:MType = T


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with n vertices. 
"""
static_dir_graph(n::Int) = DirPropGraph(n,Static)


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with n vertices. 
"""
dynamic_dir_graph(n::Int) = DirPropGraph(n,Mortal)

"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with given structure. 
"""
static_dir_graph(in_structure::Dict{Int, Vector{Int}}) = DirPropGraph(in_structure, Static)


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph with given structure. 
"""
dynamic_dir_graph(in_structure::Dict{Int, Vector{Int}}) = DirPropGraph(in_structure, Mortal)


"""
$(TYPEDSIGNATURES)
"""
function convert_type(graph::DirPropGraph, w::T) where T<:MType
    return DirPropGraph(getfield(graph, :_nodes), graph.in_structure, graph.out_structure, graph.nodesprops, graph.edgesprops, w)
end


@inline function _in_structure_from_mat(A::Matrix{Int})
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
    return in_structure
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for given Adjacency matrix. 
"""
function static_dir_graph(A::Matrix{Int})
    in_structure = _in_structure_from_mat(A)  
    DirPropGraph(in_structure, Static)
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for given Adjacency matrix. 
"""
function dynamic_dir_graph(A::Matrix{Int})
    in_structure = _in_structure_from_mat(A)  
    DirPropGraph(in_structure, Mortal)
end

@inline function _in_structure_from_smat(A::SparseArrays.SparseMatrixCSC{Int64, Int64})
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
    return in_structure
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for adjacency matrix given as a Sparse Matrix. 
"""
function static_dir_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64})    
    in_structure = _in_structure_from_smat(A)
    DirPropGraph(in_structure,Static)
end


"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for adjacency matrix given as a Sparse Matrix. 
"""
function dynamic_dir_graph(A::SparseArrays.SparseMatrixCSC{Int64, Int64})    
    in_structure = _in_structure_from_smat(A)
    DirPropGraph(in_structure,Mortal)
end

"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for a given directed graph created with Graphs.jl. 
"""
function static_dir_graph(g::SimpleDiGraph{Int64})
    ad_mat = Graphs.adjacency_matrix(g)
    static_dir_graph(ad_mat)
end

"""
$(TYPEDSIGNATURES)

Creates a directed prop graph for a given directed graph created with Graphs.jl. 
"""
function dynamic_dir_graph(g::SimpleDiGraph{Int64})
    ad_mat = Graphs.adjacency_matrix(g)
    dynamic_dir_graph(ad_mat)
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



"""
$(TYPEDSIGNATURES)
not meant to combine general graphs; serves only a specific use case.
"""
function combined_graph(grapha::DirPropGraph, graphb::DirPropGraph) 
    graphc = deepcopy(grapha)
    nodesc = getfield(graphc, :_nodes)
    structure_inc = graphc.in_structure
    structure_outc = graphc.out_structure
    nodespropsc = graphc.nodesprops
    edgespropsc= graphc.edgesprops

    nodesb = getfield(graphb, :_nodes)
    structure_inb = graphb.in_structure
    structure_outb = graphb.out_structure
    nodespropsb = graphb.nodesprops
    edgespropsb= graphb.edgesprops

    for node in nodesb
        push!(nodesc, node)
    end
    sort!(nodesc)
    for (key, value) in structure_inb
        append!(structure_inc[key],value)
    end
    for (key, value) in structure_outb
        append!(structure_outc[key], value)
    end
    for (key, value) in nodespropsb
        nodespropsc[key] = value
    end
    for (key, value) in edgespropsb
        edgespropsc[key] = value
    end
    return graphc   
end


"""
$(TYPEDSIGNATURES)
not meant to combine general graphs; serves only a specific use case.
"""
function combined_graph!(grapha::DirPropGraph, graphb::DirPropGraph)
    graphc = grapha
    nodesc = getfield(graphc, :_nodes)
    structure_inc = graphc.in_structure
    structure_outc = graphc.out_structure
    nodespropsc = graphc.nodesprops
    edgespropsc= graphc.edgesprops

    nodesb = getfield(graphb, :_nodes)
    structure_inb = graphb.in_structure
    structure_outb = graphb.out_structure
    nodespropsb = graphb.nodesprops
    edgespropsb= graphb.edgesprops
    for node in nodesb
        push!(nodesc, node)
    end
    sort!(nodesc)
    for (key, value) in structure_inb
        append!(structure_inc[key],value)
    end
    for (key, value) in structure_outb
        append!(structure_outc[key],value)
    end
    for (key, value) in nodespropsb
        nodespropsc[key] = value
    end
    for (key, value) in edgespropsb
        edgespropsc[key] = value
    end  
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
