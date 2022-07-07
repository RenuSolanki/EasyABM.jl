
"""
$(TYPEDSIGNATURES)

Creates a 2d model with 
- `agents` : list of agents.
- `graphics` : if true, properties of shape, color, orientation will be assigned to each agent by default, if not already assigned by the user.
- `agents_type` : Set it to Static if number of agents is fixed during model run. Otherwise set it to Mortal. 
- `size` : A tuple (dimx, dimy) which tells the number of blocks the space is to be divided into along x and y directions. An agent can take
positions from 0 to dimx in x-direction and 0 to dimy in y direction. The agents can move continuously or 
in discrete steps depending upon how user implements the step rule (unless the agents are of grid type which can only move in dicrete steps). 
Each unit block of space is called a patch which like agents can be assigned 
its own properties.  
- `random_positions` : If this property is true, each agent, will be assigned a random position. 
- `space_type` : Set it to Periodic or NPeriodic depending upon if the space is periodic or not. 
- `kwargs`` : Keyword argments used as model parameters. 
"""
function create_2d_model(agents::Vector{Agent2D{Symbol, Any, S, A}}; 
    graphics=true, agents_type::Type{T} = Static, 
    size::NTuple{2,Int}= (10,10), random_positions=false, 
    space_type::Type{P} = Periodic,
    kwargs...) where {T<:MType, S<:Union{Int, AbstractFloat}, P<:SType, A<:SType}

    xdim, ydim = size 
    n = length(agents)

    patches = _set_patches(size)

    agents_new = Vector{Agent2D{Symbol, Any, S, P}}()

    for agent in agents
        dc = unwrap(agent)
        dcd = unwrap_data(agent)
        pos = getfield(agent, :pos)
        ag = Agent2D{P}(1, pos, dc, dcd, nothing)
        push!(agents_new, ag)
    end

    agents = agents_new
       

    parameters = _set_parameters(size, n, random_positions; kwargs...)

    model = SpaceModel2D{T, S, P}(size, patches, agents, Ref(n), graphics, parameters, (aprops = Symbol[], pprops = Symbol[], mprops = Symbol[]), Ref(1))

    for (i, agent) in enumerate(agents)

        setfield!(agent, :id, i)
        agent._extras._new = false

        if random_positions
            _set_pos!(agent, xdim, ydim)
        end

        manage_default_graphics_data!(agent, graphics, size)

        if T<:Mortal
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = typemax(Int)
        end
  
        _setup_grid!(agent, model, i, xdim, ydim)
        
        _init_agent_record!(agent)
         
        setfield!(agent, :model, model)

    end

    return model

end


"""
$(TYPEDSIGNATURES)
"""
function create_2d_model(; 
    graphics=true,
    size::NTuple{2,Int}= (10,10), random_positions=false, 
    space_type::Type{P} = Periodic,
    kwargs...) where {P<:SType}

    agents = Agent2D{Symbol, Any, Float64, P}[]
    model = create_2d_model(agents; graphics=graphics, agents_type=Static, 
    size=size, random_positions=random_positions, space_type = space_type, kwargs...)   
    return model
end

function null_init!(model::SpaceModel2D)
    nothing
end


function model_null_step!(model::SpaceModel2D)
    nothing
end


function _init_patches!(model::SpaceModel2D)
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
Model parameters along with agent properties can be set (or modified) from within a user defined function and then sending it as `initialiser` argument in `init_model!`. The properties of 
agents, patches and model that are to be recorded during time evolution can be specified through the dictionary argument `props_to_record`. 
List of agent properties to be recorded are specified with key "agents" and value the list of property names as symbols. If a nonempty list of 
agents properties is specified, it will replace the `keeps_record_of` list of each agent. Properties of patches and model are similarly specified
with keys "patches" and "model" respectively.
"""
function init_model!(model::SpaceModel2D; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Vector{Symbol}} = Dict{String, Vector{Symbol}}("agents"=>Symbol[], "patches"=>Symbol[], "model"=>Symbol[]),
    keep_deads_data = true)

    model.parameters._extras._keep_deads_data= keep_deads_data
    aprops = get(props_to_record, "agents", Symbol[])
    pprops = get(props_to_record, "patches", Symbol[])
    mprops = get(props_to_record, "model", Symbol[])

    initialiser(model) 

    _create_props_lists(aprops, pprops, mprops, model)

    getfield(model, :tick)[] = 1

    _init_agents!(model)

    _init_patches!(model)
    
    _init_model_record!(model)

end




"""
$(TYPEDSIGNATURES)

Runs the simulation for `steps` number of steps.
"""
function run_model!(model::SpaceModel2D; steps=1, step_rule::Function=model_null_step!)

    _run_sim!(model, steps, step_rule)
    
end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `num_epochs` number of epochs where each epoch consists of `steps_per_epoch` number of steps.
The model is saved as .jld2 file and the model.tick is reset to 1 at the end of each epoch.
"""
function run_model_epochs!(model::SpaceModel2D; steps_per_epoch = 1, num_epochs=1, 
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
function save_sim_luxor(model::SpaceModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), 
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
function save_sim_makie(model::SpaceModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), 
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
function save_sim(model::SpaceModel2D, frames::Int=model.tick, scl::Number=1.0; path= joinpath(@get_scratch!("abm_anims"), "anim_2d.gif"), show_space=true, backend = :luxor, tail = (1, agent-> false))
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
function animate_sim(model::SpaceModel2D, frames::Int=model.tick; 
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(), 
    patch_plots::Dict{String, <:Function} = Dict{String, Function}(),
    model_plots::Vector{Symbol} = Symbol[],
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
    model_df = get_model_data(model, model_plots).record

    _interactive_app(model, fr, plots_only, _save_sim, draw_frame, agent_df, patch_df, DataFrames.DataFrame(),model_df )

end


"""
$(TYPEDSIGNATURES)

Draws a specific frame.
"""
function draw_frame(model::SpaceModel2D; frame=model.tick, show_grid=false)
    frame = min(frame, model.tick)
    model.parameters._extras._show_space = show_grid
    drawing = Drawing(gparams.width+gparams.border, gparams.height+gparams.border, :png)
    if model.graphics
        Luxor.origin()
        Luxor.background("white")
        if show_grid && !(:color in model.record.pprops)
            draw_patches_static(model)
        end
        draw_agents_and_patches(model, frame, 1.0)
    end
    finish()
    drawing
end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app(inmodel::SpaceModel2D; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Vector{Symbol}} = Dict{String, Vector{Symbol}}("agents"=>Symbol[], "patches"=>Symbol[], "model"=>Symbol[]),
    step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(),
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(),
    patch_plots::Dict{String, <:Function} = Dict{String, Function}(),
    model_plots::Vector{Symbol} = Symbol[],
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
        model_df = get_model_data(model, model_plots).record
        return agent_df, patch_df, DataFrame(), model_df
    end


   agent_df, patch_df, node_df, model_df = DataFrame(), DataFrame(), DataFrame(), DataFrame() #_init_interactive_model()

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

    _live_interactive_app(model, frames, plots_only, _save_sim, _init_interactive_model, _run_interactive_model, 
    _draw_interactive_frame, agent_controls, model_controls, agent_df, ()->nothing, patch_df, node_df, model_df)

end


