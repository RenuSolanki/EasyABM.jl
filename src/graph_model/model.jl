
struct GraphModel{S<:MType,T<:MType,G<:GType} <: AbstractGraphModel{S,T,G} #S graph mortality, T agent mortality, G dir or simple graph
    graph::AbstractPropGraph{S, G}
    dead_meta_graph::AbstractPropGraph{S, G}
    agents::Vector{GraphAgent{S, T}}
    agents_added::Vector{GraphAgent{S, T}}
    agents_killed::Vector{GraphAgent{S, T}}
    max_id::Base.RefValue{Int64}
    graphics::Bool
    parameters::PropDataDict{Symbol, Any}
    record::NamedTuple{(:aprops, :nprops, :eprops, :mprops), Tuple{Set{Symbol}, Set{Symbol}, Set{Symbol}, Set{Symbol}}}
    tick::Base.RefValue{Int64}

    GraphModel{S}() where {S} =  begin #needed for initially attaching with agents
        graph = SimplePropGraph{S}()
        dead_meta_graph = SimplePropGraph{S}()
        agents = Vector{GraphAgent{S, Mortal}}()
        agents_added =  Vector{GraphAgent{S, Mortal}}()
        agents_killed = Vector{GraphAgent{S, Mortal}}()
        max_id = Ref(1)
        graphics = true
        parameters = PropDataDict()
        record = (aprops=Set{Symbol}([]), nprops=Set{Symbol}([]), eprops=Set{Symbol}([]), mprops = Set{Symbol}([]))
        tick = Ref(1)
        new{S,Mortal,SimG}(graph, dead_meta_graph, agents, agents_added, agents_killed, max_id, graphics, parameters, record, tick) 
    end
    function GraphModel{S,T,G}(graph::AbstractPropGraph{S, G}, dead_meta_graph::AbstractPropGraph{S, G}, agents, max_id, graphics, parameters, record, tick) where {S<:MType, T<:MType, G<:GType} 
    
        agents_added =  Vector{GraphAgent{S, T}}()
        agents_killed = Vector{GraphAgent{S, T}}()
        
        new{S, T, G}(graph, dead_meta_graph, agents, agents_added, agents_killed, max_id, graphics, parameters, record, tick) 
    end
end

const GraphModelFixAgNum = Union{GraphModel{Static, Static}, GraphModel{Mortal, Static}}
const GraphModelDynAgNum = Union{GraphModel{Static, Mortal}, GraphModel{Mortal, Mortal}}
const GraphModelFixGrTop = Union{GraphModel{Static, Static}, GraphModel{Static, Mortal}}
const GraphModelDynGrTop = Union{GraphModel{Mortal, Static}, GraphModel{Mortal, Mortal}}




function Base.getproperty(d::AbstractGraphModel, n::Symbol) 
    if (n == :tick) || (n==:max_id)
       return getfield(d, n)[]
    else
       return getfield(d, n)
    end
end

function Base.show(io::IO, ::MIME"text/plain", v::GraphModel{T, S, G}) where {T,S, G} # works with REPL
    if (T==Mortal)&&(S==Mortal)
        str = "In a {$T, $S} model graph topology can change and agents can take birth or die"
    end
    if (T==Static)&&(S==Mortal)
        str = "In a {$T, $S} model graph topology is fixed while agents can take birth or die"
    end
    if (T==Static)&&(S==Static)
        str = "In a {$T, $S} model both graph topology and agents number is fixed"
    end
    if (T==Mortal)&&(S==Static)
        str = "In a {$T, $S} model graph topology can change and agents number is fixed"
    end
    
    println(io, "EasyABM GraphModel{$T, $S, $G}: $str.")
end

function Base.show(io::IO, v::GraphModel{T,S, G}) where {T,S, G} # works with print
    if (T==Mortal)&&(S==Mortal)
        str = "In a {$T, $S} model graph topology can change and agents can take birth or die"
    end
    if (T==Static)&&(S==Mortal)
        str = "In a {$T, $S} model graph topology is fixed while agents can take birth or die"
    end
    if (T==Static)&&(S==Static)
        str = "In a {$T, $S} model both graph topology and agents number is fixed"
    end
    if (T==Mortal)&&(S==Static)
        str = "In a {$T, $S} model graph topology can change and agents number is fixed"
    end
    
    println(io, "EasyABM GraphModel{$T, $S, $G}: $str.")
end


function Base.setproperty!(agent::GraphAgent{S, Mortal}, key::Symbol, x) where S<:MType

    if !(agent._extras._active::Bool)
        return
    end
    
    dict = unwrap(agent)
    
    if key != :node
        dict[key] = x
    else 
        update_nodesprops!(agent, getfield(agent, :model)::GraphModel{S, Mortal}, x)
    end

end

function Base.setproperty!(agent::GraphAgent{S, Static}, key::Symbol, x) where S<:MType
    
    dict = unwrap(agent)
    
    if key != :node
        dict[key] = x
    else 
        update_nodesprops!(agent, getfield(agent, :model)::GraphModel{S, Static}, x)
    end

end

function update_nodesprops!(agent::GraphAgent, model::Nothing)
    return
end

function update_nodesprops!(agent::GraphAgent{S}, model::GraphModel{S}, node_new) where {S<:Static}
    node_old = agent.node
    graph = model.graph

    if node_new != node_old
        i = getfield(agent, :id)
        nodesprops = graph.nodesprops
        deleteat!(nodesprops[node_old].agents, findfirst(x->x==i, nodesprops[node_old].agents))
        push!(nodesprops[node_new].agents, i)
        setfield!(agent, :node, node_new)
    end
end


function update_nodesprops!(agent::GraphAgent{S}, model::GraphModel{S}, node_new) where {S<:Mortal}
    graph = model.graph
    if !graph.nodesprops[node_new]._extras._active::Bool
        return 
    else
        node_old = agent.node

        if node_new != node_old
            i = getfield(agent, :id)
            nodesprops = graph.nodesprops
            deleteat!(nodesprops[node_old].agents, findfirst(x->x==i, nodesprops[node_old].agents))
            push!(nodesprops[node_new].agents, i)
            setfield!(agent, :node, node_new)
        end

    end 
end

