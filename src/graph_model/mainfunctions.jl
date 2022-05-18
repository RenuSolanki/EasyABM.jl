"""
$(TYPEDSIGNATURES)

Creates a model with 
- agents : list of agents.
- graph  : A graph created with Graph.jl or with SimpleABM graph functionality.
- graphics : if true properties of pos, shape, color, orientation will be assigned to each agent by default, if not already assigned by user.
- fix_agent_num : Set it to true if agents do not die and new agents are not born during simulation. 
- static_graph : Set it to false if graph topology needs to be changed during simulation.
- random_positions : If this property is true, each agent, which doesn't already have a node property defined, will be given a default random node on the graph. 
- kwargs : Keyword argments used as model parameters. 
"""
function create_graph_model(agents::Vector{AgentDictGr}, 
    graph::Union{SimplePropGraph,DirPropGraph, SimpleGraph{Int64}, SimpleDiGraph{Int64}}; fix_agents_num=false, 
    static_graph = true, graphics=true, random_positions=false, kwargs...)
    
    n = length(agents)

    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)

    if (typeof(graph)<:AbstractPropGraph{MortalType}) # if user deliberately sends a MortalType graph, then static_graph (=true by default) will be set to false
        static_graph = false
    end

    if (typeof(graph)<:AbstractPropGraph{StaticType}) && !(static_graph) # if user sends a (default) statictype graph but deliberately sets static_graph to false then change graph type to dynamic
        if !is_directed(graph)
            graph = create_simple_graph(graph.structure, gtype = MortalType)
        else
            graph = create_dir_graph(graph.in_structure, gtype = MortalType)
        end
    end

    gtype = static_graph ? StaticType : MortalType
    atype = fix_agents_num ? StaticType : MortalType

    if (typeof(graph)<:SimpleGraph) 
        graph = create_simple_graph(graph, gtype = gtype)
    end

    if typeof(graph)<:SimpleDiGraph
        graph = create_dir_graph(graph, gtype = gtype)
    end

    graph.nodesprops[-1] = static_graph
    graph.nodesprops[-2] = fix_agents_num

    if !is_directed(graph)
        structure = graph.structure
    else
        structure = Dict{Int, Vector{Int}}()
        for node in graph.nodes
            structure[node] = vcat(graph.in_structure[node], graph.out_structure[node]) 
        end
    end

    if length(vertices(graph)) == 0
        _add_vertex!(graph, 1)
    end
    verts = vertices(graph)
    default_node = verts[1]
    num_verts = length(verts)



    if !fix_agents_num
        parameters._extras._agents_added =  Vector{AgentDictGr}()
        parameters._extras._agents_killed = Vector{AgentDictGr}()
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._num_verts = num_verts
    parameters._extras._show_space = true

    if graphics
        locs_x, locs_y = spring_layout(structure)
    end


    for (i,vt) in enumerate(verts)
        if vt in keys(graph.nodesprops)
            graph.nodesprops[vt]._extras._agents = Int[]
        else
            graph.nodesprops[vt] = PropDataDict()
            graph.nodesprops[vt]._extras._agents = Int[]
        end

        if graphics && !haskey(graph.nodesprops[vt]._extras, :_pos)
            graph.nodesprops[vt]._extras._pos = (locs_x[i], locs_y[i])
        end

        if !is_static(graph)
            graph.nodesprops[vt]._extras._active = true
            graph.nodesprops[vt]._extras._birth_time = 1
            graph.nodesprops[vt]._extras._death_time = Inf
        end
        v_dict = unwrap(graph.nodesprops[vt])
        v_data = unwrap_data(graph.nodesprops[vt])
        for (key, value) in v_dict
            if !(key == :_extras)
                v_data[key] = [value]
            end
        end
    end

    for ed in graph.edges
        if !(ed in keys(graph.edgesprops))
            graph.edgesprops[ed] = PropDataDict()
        end
        if !is_static(graph)
            graph.edgesprops[ed]._extras._active = true
            graph.edgesprops[ed]._extras._birth_time = 1
            graph.edgesprops[ed]._extras._death_time = Inf
        end
        e_dict = unwrap(graph.edgesprops[ed])
        e_data = unwrap_data(graph.edgesprops[ed])
        for (key, value) in e_dict
            if !(key == :_extras)
                e_data[key] = [value]
            end
        end
    end

    for (i, agent) in enumerate(agents)
        agent._extras._id = i
        if !fix_agents_num
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = Inf
        end

        ag_node = random_positions ? verts[rand(1:num_verts)] : default_node

        if random_positions && (!haskey(agent, :node) || !(agent.node in verts))          
            unwrap(agent)[:node] = ag_node # if random_positions is true, we need to assign a node property
        end

        manage_default_graphics_data!(agent, graphics, ag_node)


        if haskey(agent, :node)
            node = agent.node
            if node in verts
                push!(graph.nodesprops[node]._extras._agents, i)
                agent._extras._last_node_loc = node    
            else
                push!(graph.nodesprops[ag_node]._extras._agents, i)
                agent._extras._last_node_loc = ag_node
                unwrap(agent)[:node] = ag_node
            end
        end    
        
        if length(agent.keeps_record_of) == 0
            keeps_record_of = Symbol[]
            for key in keys(agent)
                if !(key == :_extras) && !(key==:keeps_record_of)
                    push!(keeps_record_of, key)
                end
            end
            unwrap(agent)[:keeps_record_of] = keeps_record_of
        end

        _init_agent_record!(agent)

        agent._extras._nodesprops = graph.nodesprops
    end

    
    model = GraphModel(graph, agents, Ref(n), graphics, parameters, (aprops=Symbol[], nprops=Symbol[], eprops=Symbol[], mprops = Symbol[]), Ref(1), gtype = gtype, atype = atype)

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
    for vt in vertices(model.graph)
        model.graph.nodesprops[vt]._extras._birth_time = 1
        v_dict = unwrap(model.graph.nodesprops[vt])
        v_data = unwrap_data(model.graph.nodesprops[vt])
        for key in model.record.nprops
            v_data[key] = [v_dict[key]]
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_vertex_data!(model::GraphModelFixGrTop)
    for vt in vertices(model.graph)
        v_dict = unwrap(model.graph.nodesprops[vt])
        v_data = unwrap_data(model.graph.nodesprops[vt])
        for key in model.record.nprops
            v_data[key] = [v_dict[key]]
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_edge_data!(model::GraphModelDynGrTop)
    for ed in model.graph.edges
        model.graph.edgesprops[ed]._extras._birth_time = 1
        e_dict = unwrap(model.graph.edgesprops[ed])
        e_data = unwrap_data(model.graph.edgesprops[ed])
        for key in model.record.eprops
            e_data[key] = [e_dict[key]]
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
@inline function _init_edge_data!(model::GraphModelFixGrTop)
    for ed in model.graph.edges
        e_dict = unwrap(model.graph.edgesprops[ed])
        e_data = unwrap_data(model.graph.edgesprops[ed])
        for key in model.record.eprops
            e_data[key] = [e_dict[key]]
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function _init_graph!(model::GraphModel)

    _permanently_remove_inactive_edges!(model)
    _permanently_remove_inactive_nodes!(model)

    if length(vertices(model.graph)) == 0
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
    empty!(model.parameters._extras._agents_killed)
    getfield(model,:max_id)[] = max([ag._extras._id for ag in model.agents]...)
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
Model parameters along with agent and graph properties can be set (or modified if set through the `create_graph_agents` and `create_graph_model` 
functions) from within a user defined function and then sending it as `initialiser` argument in `init_model!`.
"""
function init_model!(model::GraphModel; initialiser::Function = null_init!)
    initialiser(model)

    getfield(model, :tick)[] = 1 

    _init_agents!(model)

    _init_graph!(model)

    _init_model_record!(model)

end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `steps` number of model-steps. Agent properties specified in `aprops` will replace each agents `keeps_record_of` list and will be recorded during simulation. 
The patch properties to be recorded can be specified as list of symbols `pprops`. The model properties to be recorded are specified as `mprops`. 
"""
function run_model!(model::GraphModel; steps=1,
    step_rule::Function=model_null_step!, aprops::Vector{Symbol} = Symbol[], 
    nprops::Vector{Symbol} = Symbol[], eprops::Vector{Symbol} = Symbol[], mprops::Vector{Symbol} = Symbol[],
    save_to_folder = _default_folder[])


    for sym in aprops
        if !(sym in model.record.aprops)
            push!(model.record.aprops, sym)
        end
    end

    if length(model.record.aprops)>0
        for agent in model.agents
            unwrap(agent)[:keeps_record_of] = copy(model.record.aprops)
        end
    end

    for sym in mprops
        if !(sym in model.record.mprops)
            push!(model.record.mprops, sym)
        end
    end
 

    for sym in nprops
        if !(sym in model.record.nprops)
            push!(model.record.nprops, sym)
        end
    end

    for sym in eprops
        if !(sym in model.record.eprops)
            push!(model.record.eprops, sym)
        end
    end


    init_model!(model)

    _run_sim!(model, steps, step_rule, do_after_model_step!)

    filename = "rungr"*string(_jld2_count[])

    _save_object_to_disk(model, "modelgr", filename = joinpath(save_to_folder, filename))

end


"""
$(TYPEDSIGNATURES)
"""
function run_without_init!(model::GraphModel; steps=1, step_rule::Function=model_null_step!)



    _run_sim!(model, steps, step_rule, do_after_model_step!)
    
end

"""
$(TYPEDSIGNATURES)

Returns an animated simulation created from data collected during the run. Unless a path is specified
the gif file of the simulation is saved as `anim_graph.gif` inside `your_home/.julia/dev/SimpleABM/gifs/`.
"""
function save_sim_luxor(model::GraphModel, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_space = true) 
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_space
        fr = min(frames, ticks)
        movie_abm = Movie(gparams.width, gparams.height, "movie_abm", 1:fr)
        scene_array = Vector{Luxor.Scene}()
        verts = vertices(model.graph)
        node_size = _get_node_size(length(verts))
        
        function backdrop_sg(scene, frame)
            Luxor.background("black")
            for vert in verts
                vert_pos = model.graph.nodesprops[vert]._extras._pos
                out_structure = out_links(model.graph, vert)
                neighs_pos = [model.graph.nodesprops[nd]._extras._pos for nd in out_structure]
                draw_vert(vert_pos, node_size, neighs_pos, is_directed(model.graph)) 
            end
        end
    
        function backdrop_g(scene, frame)
            Luxor.background("black")
        end
        
        use_backdrop = (is_static(model.graph) && show_space) ? backdrop_sg : backdrop_g

        push!(scene_array, Luxor.Scene(movie_abm, use_backdrop, 1:fr))
        for i in 1:fr
            draw_all(scene, frame) = draw_agents_and_graph(model, verts, node_size, frame,scl)

            push!(scene_array, Luxor.Scene(movie_abm, draw_all, i:i))
        end

        anima= animate(movie_abm, scene_array, creategif=true, framerate=gparams.fps, pathname = path);
        return
    end

end



"""
$(TYPEDSIGNATURES)

Returns an animated simulation created from data collected during the run. Unless a path is specified
the gif file of the simulation is saved as `anim_graph.gif` inside `your_home/.julia/dev/SimpleABM/gifs/`.
"""
function save_sim_makie(model::GraphModel, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_space = true) 
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_space
        fr = min(frames, ticks)


        time = Observable(1)

        #[[Point2f(5*rand(),5*rand()) for i in 1:20] for j in 1:n]
        points = @lift(_get_agents_pos(model,$time))
        markers = @lift(_get_propvals(model,$time, :shape))
        colors = @lift(_get_propvals(model, $time, :color))
        rotations = @lift(_get_propvals(model, $time, :orientation))
        sizes = @lift(_get_propvals(model, $time, :size))
        verts_pos = @lift(_get_graph_layout_info(model, $time)[1])
        verts_dir = @lift(_get_graph_layout_info(model, $time)[2]) 
        verts_color = @lift(_get_graph_layout_info(model, $time)[3])



        fig = _create_makie_frame(model, points, markers, colors, rotations, sizes, verts_pos, verts_dir, verts_color, show_space)

        framerate = gparams.fps
        timestamps = 1:fr

        sim = record(fig, path, timestamps;
                framerate = framerate) do t
            time[] = t
        end

        return sim
        

    end

end


"""
$(TYPEDSIGNATURES)

Creates and saves the gif of simulation from the data collected during model run. 
"""
function save_sim(model::GraphModel, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_space=true, backend = :luxor)
    if backend == :makie
        save_sim_makie(model, frames, scl, path= path , show_space= show_space)
    else
        save_sim_luxor(model, frames, scl, path= path , show_space= show_space)
    end
    println("Animation saved at ", path)
end



"""
$(TYPEDSIGNATURES)

Creates an animation from the data collected during model run.
"""
function animate_sim(model::GraphModel, frames::Int=model.tick; plots::Dict{String, Function} = Dict{String, Function}(), 
    path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"), show_graph = true, backend= :luxor)
    ticks = getfield(model, :tick)[]
    model.parameters._extras._show_space = show_graph
    fr = min(frames, ticks)
    verts = vertices(model.graph)
    node_size = _get_node_size(length(verts))
    function draw_frame_luxor(t, scl)
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            Luxor.origin()
            Luxor.background("black")
            if is_static(model.graph) && show_graph
                for vert in verts
                    vert_pos = model.graph.nodesprops[vert]._extras._pos
                    out_structure = out_links(model.graph, vert)
                    neighs_pos = [model.graph.nodesprops[nd]._extras._pos for nd in out_structure]
                    draw_vert(vert_pos, node_size, neighs_pos, is_directed(model.graph)) 
                end
            end
            draw_agents_and_graph(model, verts, node_size, t, scl)
        end
        finish()
        drawing
    end

    function draw_frame_makie(t, scl)
        points = _get_agents_pos(model,t)
        markers = _get_propvals(model,t, :shape)
        colors = _get_propvals(model, t, :color)
        rotations = _get_propvals(model, t, :orientation)
        sizes = _get_propvals(model, t, :size, scl)
        verts_pos, verts_dir, verts_color   = _get_graph_layout_info(model, t)

        fig = _create_makie_frame(model, points, markers, colors, rotations, sizes, verts_pos, verts_dir, verts_color, show_graph)
        return fig
    end

    function _save_sim(scl)
        save_sim(model, fr, scl, path= path, show_space=show_graph, backend = backend)
    end


    draw_frame = backend==:makie ? draw_frame_makie : draw_frame_luxor

    labels = String[]
    conditions = Function[]
    for (lbl, cond) in plots
        push!(labels, lbl)
        push!(conditions, cond)
    end
    df = get_num_agents(model, conditions..., labels= labels)

    _interactive_app(model, fr,_save_sim, draw_frame, df)
end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app(model::GraphModel; initialiser::Function = null_init!, step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    plots::Dict{String, Function} = Dict{String, Function}(),
    path= joinpath(@get_scratch!("abm_anims"), "anim_graph.gif"),
    frames=200, show_graph=true, backend = :luxor) 

    model.parameters._extras._show_space = show_graph
    
    for agent in model.agents
        props = Symbol[]
        for key in keys(unwrap(agent))
            if (key != :_extras)&&(key != :keeps_record_of)
                push!(props, key)
            end
        end
        agent.keeps_record_of = props
    end
    
    empty!(model.record.mprops)

    for key in keys(unwrap(model.parameters))
        if key!=:_extras 
            push!(model.record.mprops, key)
        end
    end

    empty!(model.record.nprops)

    for key in keys(unwrap(model.graph.nodesprops[1]))
        if key!=:_extras 
            push!(model.record.nprops, key)
        end
    end

    empty!(model.record.eprops)

    if length(model.graph.edges)>0
        edge = model.graph.edges[1]
        for key in keys(unwrap(model.graph.edgesprops[edge]))
            if key!=:_extras 
                push!(model.record.eprops, key)
            end
        end
    end

    init_model!(model, initialiser=initialiser)
    


    #copy_agents = deepcopy(model.agents)


    function _init_interactive_model()
        init_model!(model, initialiser=initialiser)
    end

    function _run_interactive_model(t)
        run_without_init!(model, steps=t, step_rule=step_rule)
    end

    function _save_sim(scl)
        save_sim(model, frames, scl, path= path, show_space=show_graph, backend = backend)
    end

    #_run_interactive_model()

    function _draw_interactive_frame_luxor(t, scl)
        if t>model.tick
            _run_interactive_model(t-model.tick)
        end
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            verts = vertices(model.graph)
            node_size = _get_node_size(length(verts))
            Luxor.origin()
            Luxor.background("black")
            if is_static(model.graph) && show_graph
                for vert in verts
                    vert_pos = model.graph.nodesprops[vert]._extras._pos
                    out_structure = out_links(model.graph, vert)
                    neighs_pos = [model.graph.nodesprops[nd]._extras._pos for nd in out_structure]
                    draw_vert(vert_pos, node_size, neighs_pos, is_directed(model.graph)) 
                end
            end
            draw_agents_and_graph(model, verts, node_size, t, scl)
        end
        finish()
        drawing
    end

    function _draw_interactive_frame_makie(t, scl)
        if t>model.tick
            _run_interactive_model(t-model.tick)
        end
        points = _get_agents_pos(model,t)
        markers = _get_propvals(model,t, :shape)
        colors = _get_propvals(model, t, :color)
        rotations = _get_propvals(model, t, :orientation)
        sizes = _get_propvals(model, t, :size, scl)
        verts_pos, verts_dir, verts_color  = _get_graph_layout_info(model, t)

        fig = _create_makie_frame(model, points, markers, colors, rotations, sizes, verts_pos, verts_dir, verts_color, show_graph)
        return fig
    end

    _draw_interactive_frame = backend==:makie ? _draw_interactive_frame_makie : _draw_interactive_frame_makie

    _live_interactive_app(model, frames, _save_sim, _init_interactive_model, _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls,plots)

end

 
