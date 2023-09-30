"""
$(TYPEDSIGNATURES)

Creates a model with 
- `agents` : list of agents.
- `graph`  : A graph created with Graphs.jl and converted to EasyABM graph type Or created directly using EasyABM graph functionality.
- `graphics` : if true properties of pos, shape, color, orientation will be assigned to each agent by default, if not already assigned by user.
- `agents_type` : Set it to Static if number of agents is fixed during model run. Otherwise set it to Mortal. 
- `decorated_edges` : Set it to true if edges are to be assigned weights or any other properties.
- `random_positions` : If this property is true, each agent will be assigned a random node on the graph. 
- `kwargs` : Keyword argments used as model parameters. 
"""
function create_graph_model(agents::Vector{GraphAgent{Symbol, Any, A}}, 
    graph::AbstractPropGraph{S, G}; agents_type::Type{T} = Static, decorated_edges = false, 
    graphics=true, random_positions=false, kwargs...) where {S<:MType, T<:MType, G<:GType, A<:MType}
    
    n = length(agents)

    agents_new = Vector{GraphAgent{Symbol, Any, S}}()

    for agent in agents
        dc = unwrap(agent)
        dcd = unwrap_data(agent)
        nd = getfield(agent, :node)
        ag = GraphAgent{S}(1, nd, dc, dcd, nothing)
        push!(agents_new, ag)
    end

    agents = agents_new
    

    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)

    if length(getfield(graph, :_nodes)) == 0
        _add_vertex!(graph, 1)
    end
    verts = sort!(getfield(graph, :_nodes))
    default_node = verts[1]
    num_verts = length(verts)

    if !is_digraph(graph)
        structure = graph.structure
    else
        structure = Dict{Int, Vector{Int}}()
        for node in verts
            structure[node] = unique!(sort!(vcat(graph.in_structure[node], graph.out_structure[node])))
        end
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._num_verts = num_verts # number of active verts - change when node killed / added
    parameters._extras._num_all_verts = num_verts # num of all verts alive or dead - change when node added / permanently removed
    parameters._extras._max_node_id = num_verts # largest of the number tags of nodes - change when node added / permanently removed
    parameters._extras._num_edges = count(x->true,edges(graph)) # number of active edges
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._show_space = true
    parameters._extras._keep_deads_data = true
    parameters._extras.gparams_width = gparams.width
    parameters._extras.gparams_height = gparams.height

    if graphics
        locs_x, locs_y = spring_layout(structure)
    end


    for (i,vt) in enumerate(verts)
        if !(vt in keys(graph.nodesprops))
            graph.nodesprops[vt] = ContainerDataDict()
        end

        if graphics && !haskey(graph.nodesprops[vt], :pos) && !haskey(graph.nodesprops[vt]._extras, :_pos)
            graph.nodesprops[vt]._extras._pos = (locs_x[i], locs_y[i])
        end

        if S<:Mortal #dynamic graph
            graph.nodesprops[vt]._extras._active = true
            graph.nodesprops[vt]._extras._birth_time = 1
            graph.nodesprops[vt]._extras._death_time = typemax(Int)
        end
        v_dict = unwrap(graph.nodesprops[vt])
        v_data = unwrap_data(graph.nodesprops[vt])
        for (key, value) in v_dict
            if !(key == :_extras)
                v_data[key] = [value]
            end
        end
    end

    if (S<:Mortal) || decorated_edges
        for ed in edges(graph)
            if !(ed in keys(graph.edgesprops))
                graph.edgesprops[ed] = PropDataDict()
            end
            if S<:Mortal
                graph.edgesprops[ed]._extras._active = true
                graph.edgesprops[ed]._extras._bd_times = [(1, typemax(Int))]
            end
            e_dict = unwrap(graph.edgesprops[ed])
            e_data = unwrap_data(graph.edgesprops[ed])
            for (key, value) in e_dict
                if !(key == :_extras)
                    e_data[key] = [value]
                end
            end
        end
    end

    
    dead_meta_graph =  _create_dead_meta_graph(graph)
    

    model = GraphModel{S,T, G}(graph, dead_meta_graph, agents, Ref(n), graphics, parameters, (aprops=Set{Symbol}([]), nprops=Set{Symbol}([]), eprops=Set{Symbol}([]), mprops=Set{Symbol}([])), Ref(1))

    for (i, agent) in enumerate(agents)
        setfield!(agent, :id, i)
        agent._extras._new = false

        if T<:Mortal
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = typemax(Int)
        end

        ag_node = random_positions ? verts[rand(1:num_verts)] : default_node

        if !(agent.node in verts)  
            setfield!(agent, :node, ag_node)      # if random_positions is true, we need to assign a node property
        end

        manage_default_graphics_data!(agent, graphics)

        
        push!(graph.nodesprops[agent.node].agents, i)   
    

        _init_agent_record!(agent)

        setfield!(agent, :model, model)
    end

    return model
end



"""
$(TYPEDSIGNATURES)
"""
function create_graph_model(
    graph::AbstractPropGraph{S, G}; decorated_edges = false, 
    graphics=true, random_positions=false, kwargs...) where {S<:MType, G<:GType}

    agents = GraphAgent{Symbol, Any, S}[]
    model = create_graph_model(agents, graph; agents_type=Static, 
    decorated_edges = decorated_edges, 
    graphics=graphics, random_positions=random_positions, kwargs...)
    return model
end

function null_init!(model::GraphModel)
    nothing
end


function model_null_step!(model::GraphModel)
    nothing
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _init_vertex_data!(model::GraphModelDynGrTop)
    for vt in getfield(model.graph, :_nodes)
        model.graph.nodesprops[vt]._extras._birth_time = 1
        if length(model.record.nprops)>0
            v_dict = unwrap(model.graph.nodesprops[vt])
            v_data = unwrap_data(model.graph.nodesprops[vt])
            for key in model.record.nprops
                v_data[key] = [v_dict[key]]
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_vertex_data!(model::GraphModelFixGrTop)
    if length(model.record.nprops)>0
        for vt in getfield(model.graph, :_nodes)
            v_dict = unwrap(model.graph.nodesprops[vt])
            v_data = unwrap_data(model.graph.nodesprops[vt])
            for key in model.record.nprops
                v_data[key] = [v_dict[key]]
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_edge_data!(model::GraphModelDynGrTop)
    for ed in edges(model.graph)
        model.graph.edgesprops[ed]._extras._birth_time = 1
        if length(model.record.eprops)>0
            e_dict = unwrap(model.graph.edgesprops[ed])
            e_data = unwrap_data(model.graph.edgesprops[ed])
            for key in model.record.eprops
                e_data[key] = [e_dict[key]]
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_edge_data!(model::GraphModelFixGrTop)
    if length(model.record.eprops)>0
        for ed in edges(model.graph)
            e_dict = unwrap(model.graph.edgesprops[ed])
            e_data = unwrap_data(model.graph.edgesprops[ed])
            for key in model.record.eprops
                e_data[key] = [e_dict[key]]
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function _init_graph!(model::GraphModel)

    _reshift_node_numbers(model) # not yet implemented

    _permanently_remove_dead_graph_data!(model)

    if length(getfield(model.graph, :_nodes)) == 0
        _create_a_node!(model)
    end

    _init_vertex_data!(model)

    _init_edge_data!(model)
end

"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::GraphModelDynAgNum)
    _permanently_remove_inactive_agents!(model)
    commit_add_agents!(model)
    empty!(model.agents_killed)
    getfield(model,:max_id)[] = model.parameters._extras._len_model_agents::Int > 0 ? max([getfield(ag, :id) for ag in model.agents]...) : 0
    for agent in model.agents
        agent._extras._birth_time = 1
        _init_agent_record!(agent)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function _init_agents!(model::GraphModelFixAgNum)
    for agent in model.agents
        _init_agent_record!(agent)
    end
end



"""
$(TYPEDSIGNATURES)

Initiates the simulation with a user defined initialiser function which takes the model as its only argument. 
Model parameters along with agent and graph properties can be set (or modified) from within a user defined function and then sending 
it as `initialiser` argument in `init_model!`. The properties of 
agents, nodes, edges and the model that are to be recorded during time evolution can be specified through the dictionary argument `props_to_record`. 
List of agent properties to be recorded are specified with key "agents" and value the list of property names as symbols. If a nonempty list of 
agents properties is specified, it will replace the `keeps_record_of` list of each agent. Properties of nodes, edges and model are similarly specified
with keys "nodes", "edges" and "model" respectively.
"""
function init_model!(model::GraphModel; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Set{Symbol}} = Dict{String, Set{Symbol}}("agents"=>Set{Symbol}([]), "nodes"=>Set{Symbol}([]), "edges"=>Set{Symbol}([]), "model"=>Set{Symbol}([])),
    keep_deads_data = true)

    model.parameters._extras._keep_deads_data= keep_deads_data

    aprops = get(props_to_record, "agents", Set{Symbol}([]))
    nprops = get(props_to_record, "nodes", Set{Symbol}([]))
    eprops = get(props_to_record, "edges", Set{Symbol}([]))
    mprops = get(props_to_record, "model", Set{Symbol}([]))

    initialiser(model)

    _create_props_lists(aprops, nprops, eprops, mprops, model)

    getfield(model, :tick)[] = 1 

    _init_agents!(model)

    _init_graph!(model)

    _init_model_record!(model)

end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `steps` number of steps.
"""
function run_model!(model::GraphModel; steps=1, step_rule::Function=model_null_step!)

    _run_sim!(model, steps, step_rule)

end


"""
$(TYPEDSIGNATURES)

Runs the simulation for `num_epochs` number of epochs where each epoch consists of `steps_per_epoch` number of steps.
The model is saved as .jld2 file and the model.tick is reset to 1 at the end of each epoch.
"""
function run_model_epochs!(model::GraphModel; steps_per_epoch = 1, num_epochs=1, 
    step_rule::Function=model_null_step!, save_to_folder=_default_folder[])
    
    for epoch in num_epochs
        run_model!(model, steps=steps_per_epoch, step_rule = step_rule)
        save_model(model, model_name = "model", save_as = "run"*string(epoch)*".jld2", folder = save_to_folder)
        getfield(model, :tick)[] = 1 
        _init_agents!(model)
        _init_graph!(model)
        _init_model_record!(model)
    end

end


"""
$(TYPEDSIGNATURES)
"""
function save_sim_luxor(model::GraphModel, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_space = true) 
    if model.graphics
        graph = is_static(model.graph) ? model.graph : combined_graph(model.graph, model.dead_meta_graph)
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_space
        fr = min(frames, ticks)
        movie_abm = Movie(gparams.width+gparams.border, gparams.height+gparams.border, "movie_abm", 1:fr)
        scene_array = Vector{Luxor.Scene}()
        verts = getfield(graph, :_nodes)
        node_size = _get_node_size(model.parameters._extras._num_verts::Int)
        
        function backdrop_sg(scene, frame)
            Luxor.background("white")
            for vert in verts
                _draw_da_vert(graph, vert, node_size, frame, model.record.nprops)
            end
            _draw_title(scene, frame)
        end
    
        function backdrop_g(scene, frame)
            Luxor.background("white")
            _draw_title(scene, frame)
        end
        
        use_backdrop = (is_static(model.graph) && show_space) ? backdrop_sg : backdrop_g

        push!(scene_array, Luxor.Scene(movie_abm, use_backdrop, 1:fr))
        for i in 1:fr
            draw_all(scene, frame) = draw_agents_and_graph(model, graph, verts, node_size, frame,scl)

            push!(scene_array, Luxor.Scene(movie_abm, draw_all, i:i))
        end

        anima= animate(movie_abm, scene_array, creategif=true, framerate=gparams.fps, pathname = path);
        return
    end

end



"""
$(TYPEDSIGNATURES)

Creates and saves the gif of simulation from the data collected during model run. 
"""
function save_sim(model::GraphModel, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_space=true)
    save_sim_luxor(model, frames, scl, path= path , show_space= show_space)
    println("Animation saved at ", path)
end



"""
$(TYPEDSIGNATURES)

Creates an animation from the data collected during model run.
"""
function animate_sim(model::GraphModel, frames::Int=model.tick; 
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    node_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    model_plots::Vector{Symbol} = Symbol[],
    plots_only = false, 
    path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_graph = true)
    ticks = getfield(model, :tick)[]
    model.parameters._extras._show_space = show_graph
    graph = is_static(model.graph) ? model.graph : combined_graph(model.graph, model.dead_meta_graph)
    fr = min(frames, ticks)
    verts = getfield(graph, :_nodes)
    node_size = _get_node_size(model.parameters._extras._num_verts::Int)

    function draw_frame_luxor(t, scl)
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            Luxor.origin()
            Luxor.background("white")
            if is_static(model.graph) && show_graph
                for vert in verts
                    _draw_da_vert(graph, vert, node_size, t, model.record.nprops)
                end
            end
            draw_agents_and_graph(model,graph, verts, node_size, t, scl)
        end
        finish()
        drawing
    end

    function _save_sim(scl)
        save_sim(model, fr, scl, path= path, show_space=show_graph, backend = :luxor)
    end

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    draw_frame = draw_frame_luxor

    if plots_only
        draw_frame = _does_nothing
        _save_sim = _does_nothing
    end

    labels = String[]
    conditions = Function[]
    for (lbl, cond) in agent_plots
        push!(labels, lbl)
        push!(conditions, cond)
    end
    agent_df = get_agents_avg_props(model, conditions..., labels= labels)

    labels = String[]
    conditions = Function[]
    for (lbl, cond) in node_plots
        push!(labels, lbl)
        push!(conditions, cond)
    end

    node_df = get_agents_avg_props(model, conditions..., labels= labels)
    model_df = get_model_data(model, model_plots).record

    _interactive_app(model, fr, plots_only,_save_sim, draw_frame, agent_df, DataFrames.DataFrame(), node_df, model_df)
end



"""
$(TYPEDSIGNATURES)

Draws a specific frame.
"""
function draw_frame(model::GraphModel; frame=model.tick, show_graph=true)
    frame = min(frame, model.tick)
    model.parameters._extras._show_space = show_graph
    graph = combined_graph(model.graph, model.dead_meta_graph)
    verts = getfield(graph, :_nodes)
    node_size = _get_node_size(model.parameters._extras._num_verts::Int)
    drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
    if model.graphics
        Luxor.origin()
        Luxor.background("white")
        if is_static(model.graph) && show_graph
            for vert in verts
                _draw_da_vert(graph, vert, node_size, frame, model.record.nprops)
            end
        end
        draw_agents_and_graph(model,graph, verts, node_size, frame, 1.0)
    end
    finish()
    drawing
end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app(inmodel::GraphModel; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Set{Symbol}} = Dict{String, Set{Symbol}}("agents"=>Set{Symbol}([]), "nodes"=>Set{Symbol}([]), "edges"=>Set{Symbol}([]), "model"=>Set{Symbol}([])),
    step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), #initialiser will override the changes made
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(),
    node_plots::Dict{String, <:Function} = Dict{String, Function}(),
    model_plots::Vector{Symbol} = Symbol[],
    plots_only = false,
    path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"),
    frames=200, show_graph=true) 

    model = deepcopy(inmodel)
    
    if !is_static(model.graph)
        combined_graph!(model.graph, model.dead_meta_graph)
        empty!(model.dead_meta_graph)
    end

    model.parameters._extras._show_space = show_graph

    #copy_agents = deepcopy(model.agents)
    function _run_interactive_model(t)
        run_model!(model, steps=t, step_rule=step_rule)
    end


    lblsa = String[]
    condsa = Function[]
    for (lbl, cond) in agent_plots
        push!(lblsa, lbl)
        push!(condsa, cond)
    end

    lblsp = String[]
    condsp = Function[]
    for (lbl, cond) in node_plots
        push!(lblsp, lbl)
        push!(condsp, cond)
    end

    function _init_interactive_model(ufun::Function = x -> nothing)
        model = deepcopy(inmodel)
        ufun(model)
        init_model!(model, initialiser=initialiser, props_to_record = props_to_record)
        ufun(model)
        _run_interactive_model(frames)
        if !is_static(model.graph)
            combined_graph!(model.graph, model.dead_meta_graph)
            empty!(model.dead_meta_graph)
        end
        agent_df = get_agents_avg_props(model, condsa..., labels= lblsa)
        node_df = get_nodes_avg_props(model, condsp..., labels= lblsp)
        model_df = get_model_data(model, model_plots).record
        return agent_df, DataFrame(), node_df, model_df
    end

    agent_df, patch_df, node_df, model_df= DataFrame(), DataFrame(), DataFrame(), DataFrame() #_init_interactive_model()

    function _save_sim(scl)
        save_sim(model, frames, scl, path= path, show_space=show_graph, backend = :luxor)
    end

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    function _draw_interactive_frame_luxor(t, scl)
        verts = getfield(model.graph, :_nodes)
        node_size = _get_node_size(model.parameters._extras._num_verts::Int)
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            Luxor.origin()
            Luxor.background("white")
            if is_static(model.graph) && show_graph
                for vert in verts
                    _draw_da_vert(model.graph, vert, node_size, t, model.record.nprops)
                end
            end
            draw_agents_and_graph(model,model.graph, verts, node_size, t, scl)
        end
        finish()
        drawing
    end

    _draw_interactive_frame = _draw_interactive_frame_luxor

    if plots_only
        _draw_interactive_frame = _does_nothing
        _save_sim = _does_nothing
    end

    _live_interactive_app(model, frames, plots_only, _save_sim, _init_interactive_model, 
    _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls, 
    agent_df, ()->nothing, patch_df, node_df, model_df)

end




 
