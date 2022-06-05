
"""
$(TYPEDSIGNATURES)

Creates a model with 
- agents : list of agents.
- graphics : if true properties of pos, shape, color, orientation will be assigned to each agent by default, if not already assigned by the user.
- `fix_agent_num` : Set it to true if agents do not die and new agents are not born during simulation.
- `grid_size` : A tuple (dimx, dimy) which tells the number of blocks the space is to be divided into along x and y directions. An agent can take
positions from 0 to dimx in x-direction and 0 to dimy in y direction in order to stay within grid space. The word `grid` in the function
`create_grid_model` does not imply that agents will be restricted to move in discrete steps. The agents can move continuously or 
in discrete steps depending upon how user implements the step rule. Each grid block is called a patch which like agents can be assigned 
its own properties.  Other than the number of patches in the model, `grid_size` will also restrict the domain of `neighbors` function 
(which when called with either :grid or :euclidean metric option) will only take into account the agents within the grid dimensions and 
will ignore any agents which have crossed the boundary of grid space(unless periodic is set to true). 
- periodic : If `periodic` is true the grid space will be periodic in both x and y directions. 
- `random_positions` : If this property is true, each agent, which doesn't already have a position defined, will be given a default random continous position. 
- kwargs : Keyword argments used as model parameters. 

```@julia 
create_2d_model(agents)
```
"""
function create_2d_model(agents::Vector{AgentDict2D{Symbol, Any}}; graphics=true, fix_agents_num=false, 
    grid_size::NTuple{2,Int}= (10,10), periodic = false, random_positions=false, kwargs...)

    xdim = grid_size[1]
    ydim = grid_size[2]
    n = length(agents)
    patches = [PropDataDict(Dict{Symbol, Any}(:color => :white)) for i in 1:xdim, j in 1:ydim]   #Dict{Tuple{Int, Int},Union{PropDataDict{Symbol, Any},Bool,Int}}()
    # for i in 1:xdim
    #     for j in 1:ydim
    #         madict = PropDataDict(Dict{Symbol, Any}(:color => :white))
    #         madict._extras._agents = Int[]
    #         patches[(i,j)] = madict
    #     end
    # end
    for j in 1:ydim
        for i in 1:xdim
            patches[i,j]._extras._agents = Int[]
        end
    end
    patches[1,1]._extras._periodic = periodic
    patches[1,1]._extras._xdim = xdim
    patches[1,1]._extras._ydim = ydim
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)


    if !fix_agents_num
        atype = MortalType
        parameters._extras._agents_added = Vector{AgentDict2D{Symbol, Any}}()
        parameters._extras._agents_killed = Vector{AgentDict2D{Symbol, Any}}()
    else
        atype =StaticType
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._num_patches = xdim*ydim
    parameters._extras._keep_deads_data = true


    for (i, agent) in enumerate(agents)

        agent._extras._id = i

        if !fix_agents_num
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = Inf
        end

        if random_positions && !haskey(agent, :pos)                    
            agent.pos = (rand()*xdim, rand()*ydim) 
        end

        manage_default_graphics_data!(agent, graphics, random_positions, grid_size)


        if haskey(agent, :pos)
            pos = agent.pos
            if periodic || (pos[1]>0 && pos[1]<=xdim && pos[2]>0 && pos[2]<=ydim )
                x = mod1(Int(ceil(pos[1])), xdim)
                y = mod1(Int(ceil(pos[2])), ydim)
                push!(patches[x,y]._extras._agents, i)
                agent._extras._last_grid_loc = (x,y)
            else
                agent._extras._last_grid_loc = Inf
            end
        end

        if length(agent.keeps_record_of)==0
            keeps_record_of = Symbol[]
            for key in keys(agent)
                if !(key == :_extras) && !(key==:keeps_record_of)
                    push!(keeps_record_of, key)
                end
            end
            unwrap(agent)[:keeps_record_of] = keeps_record_of
        end

        _recalculate_position!(agent, grid_size, periodic)
        
        _init_agent_record!(agent)

        agent._extras._grid = patches

    end


    model = GridModel2D(grid_size, patches, agents, Ref(n), periodic, graphics, parameters, (aprops = Symbol[], pprops = Symbol[], mprops = Symbol[]), Ref(1), atype = atype)

    return model

end

function null_init!(model::GridModel2D)
    nothing
end


function model_null_step!(model::GridModel2D)
    nothing
end


function _init_patches!(model::GridModel2D)
    if length(model.record.pprops)>0
        for j in 1:model.size[2]
            for i in 1:model.size[1]
                patch_dict = unwrap(model.patches[i,j])
                patch_data = unwrap_data(model.patches[i,j])
                for key in model.record.pprops
                    patch_data[key] = [patch_dict[key]]
                end
            end
        end 
    end
end

"""
$(TYPEDSIGNATURES)

Initiates the simulation with a user defined initialiser function which takes the model as its only argument. 
Model parameters along with agent properties can be set (or modified if set through the `create_2d_agents` and `create_2d_model` 
functions) from within a user defined function and then sending it as `initialiser` argument in `init_model!`. The properties of 
agents, patches and model that are to be recorded during time evolution can be specified through the dictionary argument `props_to_record`. 
List of agent properties to be recorded are specified with key "agents" and value the list of property names as symbols. If a nonempty list of 
agents properties is specified, it will replace the `keeps_record_of` list of each agent. Properties of patches and model are similarly specified
with keys "patches" and "model" respectively.
"""
function init_model!(model::GridModel2D; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Vector{Symbol}} = Dict{String, Vector{Symbol}}("agents"=>Symbol[], "patches"=>Symbol[], "model"=>Symbol[]),
    keep_deads_data = true)

    model.parameters._extras._keep_deads_data= keep_deads_data
    aprops = get(props_to_record, "agents", Symbol[])
    pprops = get(props_to_record, "patches", Symbol[])
    mprops = get(props_to_record, "model", Symbol[])

    _create_props_lists(aprops, pprops, mprops, model)

    initialiser(model) 

    getfield(model, :tick)[] = 1

    _init_agents!(model)

    _init_patches!(model)
    
    _init_model_record!(model)

end




"""
$(TYPEDSIGNATURES)

Runs the simulation for `steps` number of steps.
"""
function run_model!(model::GridModel2D; steps=1, step_rule::Function=model_null_step!)

    _run_sim!(model, steps, step_rule)
    
end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `num_epochs` number of epochs where each epoch consists of `steps_per_epoch` number of steps.
The model is saved as .jld2 file and the model.tick is reset to 1 at the end of each epoch.
"""
function run_model_epochs!(model::GridModel2D; steps_per_epoch = 1, num_epochs=1, 
    step_rule::Function=model_null_step!, save_to_folder=_default_folder[])
    
    for epoch in num_epochs
        run_model!(model, steps=steps_per_epoch, step_rule = step_rule)
        save_model(model, model_name = "model", save_as = "run"*string(epoch)*".jld2", folder = save_to_folder)
        getfield(model, :tick)[] = 1
        _init_agents!(model)
        _init_patches!(model)
        _init_model_record!(model)
    end

end


"""
$(TYPEDSIGNATURES)
"""
function save_sim_luxor(model::GridModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), 
    show_space=true, tail = (1, agent->false))
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_space
        fr = min(frames, ticks)
        movie_abm = Movie(gparams.width, gparams.height, "movie_abm", 1:fr)
        scene_array = Vector{Luxor.Scene}()
        function with_grid(scene, frame)
            _draw_title(scene, frame)
            draw_patches_static(model)
        end
        function no_grid(scene, frame)
            _draw_title(scene, frame)
            Luxor.background("white")
        end
        backdrop_p = show_space ? with_grid : no_grid
        push!(scene_array, Luxor.Scene(movie_abm, backdrop_p, 1:fr))

        for i in 1:fr
            draw_all(scene, frame) = draw_agents_and_patches(model, frame, scl, tail...)
            push!(scene_array, Luxor.Scene(movie_abm, draw_all, i:i))
        end

        anima= animate(movie_abm, scene_array, creategif=true, framerate=gparams.fps, pathname = path);
        return
    end

end


"""
$(TYPEDSIGNATURES)
"""
function save_sim_makie(model::GridModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), 
    show_space=true, tail = (1, agent->false))
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_space
        fr = min(frames, ticks)


        time = Observable(1)

        #[[Point2f(5*rand(),5*rand()) for i in 1:20] for j in 1:n]
        points = @lift(_get_propvals(model,$time, :pos))
        markers = @lift(_to_makie_shapes.(_get_propvals(model,$time, :shape)))
        colors = @lift(_get_propvals(model, $time, :color))
        rotations = @lift(_get_propvals(model, $time, :orientation))
        sizes = @lift(_get_propvals(model, $time, :size, scl))
        title = @lift((t->"t = $t")($time))
        grid_colors = Symbol[]
        if show_space
            grid_colors = @lift(_get_grid_colors(model, $time))
        end

        fig = Figure(resolution = (gparams.height, gparams.width))
        ax = Axis(fig[1, 1], title=title)

        _create_makie_frame(ax, model, points, markers, colors, rotations, sizes, grid_colors, show_space)

        tail_condition = tail[2]
        tail_length = tail[1]
        all_agents=_get_all_agents(model)
        for agent in all_agents
            if tail_condition(agent)
                agent_tail = @lift(_get_tail(agent, model, $time, tail_length))
                lines!(ax, agent_tail)
            end
        end

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
function save_sim(model::GridModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), show_space=true, backend = :luxor, tail = (1, agent-> false))
    if backend == :makie
        save_sim_makie(model, frames, scl, path= path , show_space= show_space, tail = tail)
    else
        save_sim_luxor(model, frames, scl, path= path , show_space= show_space, tail = tail)
    end
    println("Animation saved at ", path)
end


"""
$(TYPEDSIGNATURES)

Creates an animation from the data collected during model run.
"""
function animate_sim(model::GridModel2D, frames::Int=model.tick; 
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    patch_plots::Dict{String, <:Function} = Dict{String, Function}(),
    plots_only = false,
    path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), show_grid=false, backend=:luxor, tail = (1, agent->false))

    ticks = getfield(model, :tick)[]
    model.parameters._extras._show_space = show_grid
    fr = min(frames, ticks)

    fig = Figure(resolution = (gparams.height, gparams.width))
    ax = Axis(fig[1, 1])
    ax.title = " "
    function draw_frame_makie(t, scl)
        empty!(ax)
        points = _get_propvals(model, t, :pos)
        markers = _to_makie_shapes.(_get_propvals(model,t, :shape))
        colors = _get_propvals(model, t, :color)
        rotations = _get_propvals(model, t, :orientation)
        sizes = _get_propvals(model, t, :size, scl)
        grid_colors = Symbol[]
        if show_grid
            grid_colors = _get_grid_colors(model, t)
        end
        _create_makie_frame(ax, model, points, markers, colors, rotations, sizes, grid_colors, show_grid)
        tail_condition = tail[2]
        tail_length = tail[1]
        all_agents=_get_all_agents(model)
        for agent in all_agents
            if tail_condition(agent)
                agent_tail = _get_tail(agent, model, t, tail_length)
                lines!(ax, agent_tail)
            end
        end
        return fig
    end

    function draw_frame_luxor(t, scl)
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            Luxor.origin()
            Luxor.background("white")
            if show_grid && !(:color in model.record.pprops)
                draw_patches_static(model)
            end
            draw_agents_and_patches(model, t, scl, tail...)
        end
        finish()
        drawing
    end

    function _save_sim(scl)
        save_sim(model, fr, scl, path= path, show_space=show_grid, backend = backend, tail = tail)
    end

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    draw_frame = backend == :makie ? draw_frame_makie : draw_frame_luxor

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
    for (lbl, cond) in patch_plots
        push!(labels, lbl)
        push!(conditions, cond)
    end
    patch_df = get_patches_avg_props(model, conditions..., labels= labels)

    _interactive_app(model, fr, plots_only, _save_sim, draw_frame, agent_df, patch_df, DataFrames.DataFrame())

end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app(inmodel::GridModel2D; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Vector{Symbol}} = Dict{String, Vector{Symbol}}("agents"=>Symbol[], "patches"=>Symbol[], "model"=>Symbol[]),
    step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(),
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(),
    patch_plots::Dict{String, <:Function} = Dict{String, Function}(),
    plots_only = false,
    path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"),
    frames=200, show_grid=false, backend = :luxor, tail =(1, agent-> false)) 

    model = deepcopy(inmodel)

    model.parameters._extras._show_space = show_grid

    
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
    for (lbl, cond) in patch_plots
        push!(lblsp, lbl)
        push!(condsp, cond)
    end

    function _init_interactive_model(ufun::Function = x -> nothing)
        model = deepcopy(inmodel)
        ufun(model) # will provide init with updated model parameters
        init_model!(model, initialiser=initialiser, props_to_record=props_to_record)
        ufun(model) # will override init if some parameters are changed inside it
        _run_interactive_model(frames)
        agent_df = get_agents_avg_props(model, condsa..., labels= lblsa)
        patch_df = get_patches_avg_props(model, condsp..., labels= lblsp)
        return agent_df, patch_df, DataFrame()
    end


   agent_df, patch_df, node_df = _init_interactive_model()

    function _save_sim(scl)
        save_sim(model, frames, scl, path= path, show_space=show_grid, backend = backend, tail = tail)
    end

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    #_run_interactive_model()
    fig = Figure(resolution = (gparams.height, gparams.width))
    ax = Axis(fig[1, 1])
    ax.title = " "

    function _draw_interactive_frame_makie(t, scl)
        empty!(ax)
        points = _get_propvals(model, t, :pos)
        markers = _to_makie_shapes.(_get_propvals(model,t, :shape))
        colors = _get_propvals(model, t, :color)
        rotations = _get_propvals(model, t, :orientation)
        sizes = _get_propvals(model, t, :size, scl)
        grid_colors = Symbol[]
        if show_grid
            grid_colors = _get_grid_colors(model, t)
        end
        _create_makie_frame(ax, model, points, markers, colors, rotations, sizes, grid_colors, show_grid)
        tail_condition = tail[2]
        tail_length = tail[1]
        all_agents=_get_all_agents(model)
        for agent in all_agents
            if tail_condition(agent)
                agent_tail = _get_tail(agent, model, t, tail_length)
                lines!(ax, agent_tail)
            end
        end
        return fig   
    end

    function _draw_interactive_frame_luxor(t, scl)
        drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
        if model.graphics
            Luxor.origin()
            Luxor.background("white")
            if show_grid && !(:color in model.record.pprops)
                draw_patches_static(model)
            end
            draw_agents_and_patches(model, t, scl, tail...)
        end
        finish()
        drawing
    end

    _draw_interactive_frame = backend == :makie ? _draw_interactive_frame_makie : _draw_interactive_frame_luxor

    if plots_only
        _draw_interactive_frame = _does_nothing
        _save_sim = _does_nothing
    end

    _live_interactive_app(model, frames, plots_only, _save_sim, _init_interactive_model, _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls, agent_df, ()->nothing, patch_df, node_df)

end


