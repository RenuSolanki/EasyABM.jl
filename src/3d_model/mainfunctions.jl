
"""
$(TYPEDSIGNATURES)

Creates a model with 
- agents : list of agents.
- graphics : if true properties of pos, shape, color, orientation will be assigned to each agent by default, if not already assigned by the user.
- `fix_agent_num` : Set it to true if agents do not die and new agents are not born during simulation. 
- `grid_size` : A tuple (dimx, dimy, dimz) which tells the number of blocks the space is to be divided into along x, y and z directions. An agent can take
positions from 0 to dimx in x-direction, 0 to dimy in y direction and 0 to dimz in z direction in order to stay within grid space. The word `grid` in the function
`create_grid_model` does not imply that agents will be restricted to move in discrete steps. The agents can move continuously or 
in discrete steps depending upon how user implements the step rule. Each grid block is called a patch which like agents can be assigned 
its own properties.  Other than the number of patches in the model, `grid_size` also restricts the domain of `neighbors` function 
(which when called with either :grid or :euclidean metric option) will only take into account the agents within the grid dimensions and 
will ignore any agents which have crossed the boundary of grid space(unless periodic is set to true). 
- periodic : If `periodic` is true the grid space will be periodic in x, y and z directions. 
- `random_positions` : If this property is true, each agent, which doesn't already have a position defined, will be given a default random continous position. 
- kwargs : Keyword argments used as model parameters. 
"""
function create_3d_model(agents::Vector{AgentDict3D{Symbol, Any}}; graphics=true, fix_agents_num=false, 
    grid_size::NTuple{3,Int}= (10,10,10), periodic = false, random_positions=false, kwargs...)

    xdim = grid_size[1]
    ydim = grid_size[2]
    zdim = grid_size[3]
    n = length(agents)
    patches = [PropDataDict(Dict{Symbol, Any}(:color => :red)) for i in 1:xdim, j in 1:ydim, k in 1:zdim]
    for k in 1:zdim
        for j in 1:ydim
            for i in 1:xdim
                patches[i,j,k]._extras._agents= Int[]
            end
        end
    end
    patches[1,1,1]._extras._periodic = periodic
    patches[1,1,1]._extras._xdim = xdim
    patches[1,1,1]._extras._ydim = ydim
    patches[1,1,1]._extras._zdim = zdim
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)


    if !fix_agents_num
        atype = MortalType
        parameters._extras._agents_added = Vector{AgentDict3D{Symbol, Any}}()
        parameters._extras._agents_killed = Vector{AgentDict3D{Symbol, Any}}()
    else
        atype =StaticType
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true
    parameters._extras._num_agents = n # number of active agents
    parameters._extras._len_model_agents = n #number of agents in model.agents
    parameters._extras._num_patches = xdim*ydim*zdim
    parameters._extras._keep_deads_data = true


    for (i, agent) in enumerate(agents)

        agent._extras._id = i

        if !fix_agents_num
            agent._extras._active = true
            agent._extras._birth_time = 1 
            agent._extras._death_time = Inf
        end

        if random_positions && !haskey(agent, :pos)                    
            agent.pos = (rand()*xdim, rand()*ydim, rand()*zdim) 
        end

        manage_default_graphics_data!(agent, graphics, random_positions, grid_size)


        if haskey(agent, :pos)
            pos = agent.pos
            if periodic || (pos[1]>0 && pos[1]<=xdim && pos[2]>0 && pos[2]<=ydim && pos[3]>0 && pos[3]<=zdim)
                x = mod1(Int(ceil(pos[1])), xdim)
                y = mod1(Int(ceil(pos[2])), ydim)
                z = mod1(Int(ceil(pos[3])), zdim)
                push!(patches[x,y,z]._extras._agents, i)
                agent._extras._last_grid_loc = (x,y,z)
            else
                agent._extras._last_grid_loc = Inf
            end
        end

        _recalculate_position!(agent, grid_size, periodic)

        _init_agent_record!(agent)

        agent._extras._grid = patches

    end


    model = GridModel3D(grid_size, patches, agents, Ref(n), periodic, graphics, parameters, (aprops = Symbol[], pprops = Symbol[], mprops = Symbol[]), Ref(1), atype = atype)

    return model

end

function null_init!(model::GridModel3D)
    nothing
end


function model_null_step!(model::GridModel3D)
    nothing
end

function _init_patches!(model::GridModel3D)
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
Model parameters along with agent properties can be set (or modified if set through the `create_3d_agents` and `create_3d_model` 
functions) from within a user defined function and then sending it as `initialiser` argument in `init_model!`. The properties of 
agents, patches and model that are to be recorded during time evolution can be specified through the dictionary argument `props_to_record`. 
List of agent properties to be recorded are specified with key "agents" and value the list of property names as symbols. If a nonempty list of 
agents properties is specified, it will replace the `keeps_record_of` list of each agent. Properties of patches and model are similarly specified
with keys "patches" and "model" respectively.
"""
function init_model!(model::GridModel3D; initialiser::Function = null_init!, 
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
function run_model!(model::GridModel3D; steps=1, step_rule::Function=model_null_step!)

    _run_sim!(model, steps, step_rule)
    
end



"""
$(TYPEDSIGNATURES)

Runs the simulation for `num_epochs` number of epochs where each epoch consists of `steps_per_epoch` number of steps.
The model is saved as .jld2 file and the model.tick is reset to 1 at the end of each epoch.
"""
function run_model_epochs!(model::GridModel3D; steps_per_epoch = 1, num_epochs=1, 
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
function save_sim(model::GridModel3D, frames::Int = model.tick, scl::Number = 1.0; kwargs...)
    println(
    "    The save function for 3D models has not yet been implemented in SimpleABM package. 
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
function animate_sim(model::GridModel3D, frames::Int=model.tick; show_grid=false, tail=(1, agent->false))
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
function create_interactive_app(inmodel::GridModel3D; initialiser::Function = null_init!, 
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

    agent_df, patch_df, node_df, model_df = _init_interactive_model()

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





