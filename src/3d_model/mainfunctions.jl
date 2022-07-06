
"""
$(TYPEDSIGNATURES)

Creates a 3d model with 
- `agents` : list of agents.
- `graphics` : if true, properties of shape, color, orientation will be assigned to each agent by default, if not already assigned by the user.
- `agents_type` : Set it to Static if number of agents is fixed during model run. Otherwise set it to Mortal. 
- `size` : A tuple (dimx, dimy, dimz) which tells the number of blocks the space is to be divided into along x, y and z directions. An agent can take
positions from 0 to dimx in x-direction, 0 to dimy in y direction and 0 to dimz in z direction. The agents can move continuously or 
in discrete steps depending upon how user implements the step rule (unless the agents are of grid type which can only move in dicrete steps). 
Each unit block of space is called a patch which like agents can be assigned 
its own properties.  
- `random_positions` : If this property is true, each agent, will be assigned a random position. 
- `space_type` : Set it to Periodic or NPeriodic depending upon if the space is periodic or not. 
- `kwargs`` : Keyword argments used as model parameters. 
"""
function create_3d_model(agents::Vector{Agent3D{Symbol, Any, S, A}}; 
    graphics=true, agents_type::Type{T} = Static, 
    size::NTuple{3,Int}= (10,10,10), random_positions=false, 
    space_type::Type{P} = Periodic,
    kwargs...) where {S<:Union{Int, AbstractFloat}, T<:MType, P<:SType, A<:SType}

    xdim = size[1]
    ydim = size[2]
    zdim = size[3]
    n = length(agents)

    patches = _set_patches3d(size)

    agents_new = Vector{Agent3D{Symbol, Any, S, P}}()

    for agent in agents
        dc = unwrap(agent)
        dcd = unwrap_data(agent)
        pos = getfield(agent, :pos)
        ag = Agent3D{P}(1, pos, dc, dcd, nothing)
        push!(agents_new, ag)
    end

    agents = agents_new
    

    parameters = _set_parameters3d(size, n, random_positions; kwargs...)


    model = SpaceModel3D{T, S, P}(size, patches, agents, Ref(n), graphics, parameters, (aprops = Symbol[], pprops = Symbol[], mprops = Symbol[]), Ref(1))

    for (i, agent) in enumerate(agents)

        setfield!(agent, :id, i)
        agent._extras._new = false

        if random_positions
            _set_pos!(agent, xdim, ydim, zdim)
        end

        manage_default_graphics_data!(agent, graphics, size)

        if T<:Mortal
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = typemax(Int)
        end
        
        _setup_grid!(agent, model, i, xdim, ydim, zdim)

        _init_agent_record!(agent)

        setfield!(agent, :model, model)

    end

    return model

end

"""
$(TYPEDSIGNATURES)
"""
function create_3d_model(;
    graphics=true, 
    size::NTuple{3,Int}= (10,10,10), random_positions=false, 
    space_type::Type{P} = Periodic,
    kwargs...) where {P<:SType}

    agents = Agent3D{Symbol, Any, Float64, P}[]
    model = create_3d_model(agents; graphics=graphics, agents_type=Static, 
    size= size, random_positions=random_positions, space_type=space_type, kwargs...)
    return model
end

function null_init!(model::SpaceModel3D)
    nothing
end


function model_null_step!(model::SpaceModel3D)
    nothing
end

function _init_patches!(model::SpaceModel3D)
    if length(model.record.pprops)>0
        for k in 1:model.size[3]
            for j in 1:model.size[2]
                for i in 1:model.size[1]
                    patch_dict = unwrap(model.patches[i,j,k])
                    patch_data = unwrap_data(model.patches[i,j,k])
                    for key in model.record.pprops
                        patch_data[key] = [patch_dict[key]]
                    end
                end
            end
        end
    end
end


"""
$(TYPEDSIGNATURES)

Initiates the simulation with a user defined initialiser function which takes the model as its only argument. 
Model parameters along with agent properties can be set (or modified) from within a user defined function and then sending it as `initialiser` 
argument in `init_model!`. The properties of agents, patches and model that are to be recorded during time evolution can be specified through 
the dictionary argument `props_to_record`. List of agent properties to be recorded are specified with key "agents" and value the list of property 
names as symbols. If a nonempty list of agents properties is specified, it will replace the `keeps_record_of` list of each agent. Properties of 
patches and model are similarly specified with keys "patches" and "model" respectively.
"""
function init_model!(model::SpaceModel3D; initialiser::Function = null_init!, 
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
function run_model!(model::SpaceModel3D; steps=1, step_rule::Function=model_null_step!)

    _run_sim!(model, steps, step_rule)
    
end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `num_epochs` number of epochs where each epoch consists of `steps_per_epoch` number of steps.
The model is saved as .jld2 file and the model.tick is reset to 1 at the end of each epoch.
"""
function run_model_epochs!(model::SpaceModel3D; steps_per_epoch = 1, num_epochs=1, 
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
function save_sim(model::SpaceModel3D, frames::Int = model.tick, scl::Number = 1.0; kwargs...)
    println(
    "    The save function for 3D models has not yet been implemented in EasyABM package. 
    In order to save the video file of simulation do following -
        1. Run the model for required number of steps using run_model! function.
        2. Animate the simulation using animate_sim. 
        3. In the GUI interface of animation use the record optio on the RHS dropdown menu.
        4. This will record a sequence of png files of simulation as a .tar file which can be
           converted inot a video file either using ffmpeg or with MeshCat's inbuilt ffmpeg
           functionality as :- 
        
           using MeshCat
           convert_frames_to_video(tar_file_path, output_path, framerate=60, overwrite=false)
    ")
end

"""
$(TYPEDSIGNATURES)

Creates a 3d animation from the data collected during the model run.
"""
function animate_sim(model::SpaceModel3D, frames::Int=model.tick; show_grid=false, tail=(1, agent->false))
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_grid
        fr = min(frames, ticks)
        vis = Visualizer()
        anim = Animation()
        
        _adjust_origin_and_draw_bounding_box(vis, true)

        if show_grid
            draw_patches_static(vis,model)
        end

        all_agents = _get_all_agents(model)
  
        draw_agents_static(vis, model, all_agents, tail...)

        for i in 1:fr
            atframe(anim, i) do
                draw_agents_and_patches(vis, model, i, 1.0, tail...)
            end
        end
        
        #setprop!(vis["/Animations/default"],"timeScale", 0.1)
        setanimation!(vis, anim)
        # if (@__FILE__)[1:2]=="In"
        render(vis)
        #else
            #open(vis)
        #end

    end

end


"""
$(TYPEDSIGNATURES)

Creates an interactive app for the model.
"""
function create_interactive_app(inmodel::SpaceModel3D; initialiser::Function = null_init!, 
    props_to_record::Dict{String, Vector{Symbol}} = Dict{String, Vector{Symbol}}("agents"=>Symbol[], "patches"=>Symbol[], "model"=>Symbol[]),
    step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), #initialiser will override the changes made
    agent_plots::Dict{String, <:Function} = Dict{String, Function}(),
    patch_plots::Dict{String, <:Function} = Dict{String, Function}(),
    model_plots::Vector{Symbol} = Symbol[],
    plots_only = false,
    frames=200, show_grid=false, tail=(1, agent->false)) 

    model = deepcopy(inmodel)

    model.parameters._extras._show_space = show_grid


    function _run_interactive_model(t)
        run_model!(model, steps=t, step_rule=step_rule)
    end

    function _save_sim(scl)
        save_sim(model, fr)
    end

    function _does_nothing(t,scl::Number=1)
        nothing
    end

    if !plots_only
        vis = Visualizer()
        _adjust_origin_and_draw_bounding_box(vis, true)
    end

    if show_grid
        draw_patches_static(vis,model)
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

    function _init_interactive_model(ufun::Function = x-> nothing)
        model = deepcopy(inmodel)
        ufun(model)
        init_model!(model, initialiser=initialiser, props_to_record=props_to_record)
        ufun(model)
        _run_interactive_model(frames)
        if !plots_only
            delete!(vis["agents"])
            delete!(vis["tails"])
            all_agents = _get_all_agents(model)
            draw_agents_static(vis, model, all_agents, tail...)
        end
        agent_df = get_agents_avg_props(model, condsa..., labels= lblsa)
        patch_df = get_patches_avg_props(model, condsp..., labels= lblsp)
        model_df = get_model_data(model, model_plots).record
        return agent_df, patch_df, DataFrame(), model_df
    end

    agent_df, patch_df, node_df, model_df = DataFrame(), DataFrame(), DataFrame(), DataFrame() #_init_interactive_model()

    function _draw_interactive_frame(t, scl)
        draw_agents_and_patches(vis, model, t, scl, tail...)
    end

    function _render_trivial(s)
        return render(vis)
    end

    if plots_only
        _draw_interactive_frame = _does_nothing
        _save_sim = _does_nothing
        _render_trivial = _does_nothing
    end

    _live_interactive_app(model, frames, plots_only, _save_sim, _init_interactive_model, 
    _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls, 
    agent_df, _render_trivial, patch_df, node_df, model_df)

end





