
"""
$(TYPEDSIGNATURES)

Creates a model with 
- agents : list of agents.
- graphics : if true properties of pos, shape, color, orientation will be assigned to each agent by default, if not already assigned by the user.
- fix_agent_num : Set it to true if agents do not die and new agents are not born during simulation. If set to false, each agent is 
assigned default properties `_birth_time`, `_death_time`, `_active` which are for internal use in the package and must not be modified
by the user. 
- grid_size : A tuple (dimx, dimy, dimz) which tells the number of blocks the space is to be divided into along x, y and z directions. An agent can take
positions from 0 to dimx in x-direction, 0 to dimy in y direction and 0 to dimz in z direction in order to stay within grid space. The word `grid` in the function
`create_grid_model` does not imply that agents will be restricted to move in discrete steps. The agents can move continuously or 
in discrete steps depending upon how user implements the step rule. Each grid block is called a patch which like agents can be assigned 
its own properties.  Other than the number of patches in the model, `grid_size` also restricts the domain of `neighbors` function 
(which when called with either :chessboard or :euclidean metric option) will only take into account the agents within the grid dimensions and 
will ignore any agents which have crossed the boundary of grid space(unless periodic is set to true). 
- periodic : If `periodic` is true the grid space will be periodic in x, y and z directions. 
- random_positions : If this property is true, each agent, which doesn't already have a position defined, will be given a default random continous position. 
- kwargs : Keyword argments used as model parameters. 
"""
function create_3d_model(agents::Vector{AgentDict3D}; graphics=true, fix_agents_num=false, 
    grid_size::NTuple{3,Int}= graphics ? (10,10,10) : (1,1,1), periodic = false, random_positions=false, kwargs...)

    xdim = grid_size[1]
    ydim = grid_size[2]
    zdim = grid_size[3]
    n = length(agents)
    patches = Dict{Tuple{Int, Int, Int},Union{PropDataDict{Symbol, Any},Bool,Int}}()
    for k in 1:zdim
        for j in 1:ydim
            for i in 1:xdim
                madict = PropDataDict(Dict{Symbol, Any}(:color => :red))
                madict._extras._agents= Int[]
                patches[(i,j, k)] = madict
            end
        end
    end
    patches[(-1,-1,-1)] = periodic
    patches[(-1,0,0)] = xdim
    patches[(0,-1,0)] = ydim
    patches[(0,0,-1)] = zdim
    dict_parameters = Dict{Symbol, Any}(kwargs)
    parameters = PropDataDict(dict_parameters)


    if !fix_agents_num
        atype = MortalType
        parameters._extras._agents_added = Vector{AgentDict3D}()
        parameters._extras._agents_killed = Vector{AgentDict3D}()
    else
        atype =StaticType
    end

    parameters._extras._random_positions = random_positions
    parameters._extras._show_space = true


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
                push!(patches[(x,y,z)]._extras._agents, i)
                agent._extras._last_grid_loc = (x,y,z)
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
                    patch_dict = unwrap(model.patches[(i,j,k)])
                    patch_data = unwrap_data(model.patches[(i,j,k)])
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
functions) from within a user defined function and then sending it as `initialiser` argument in `init_model!`.
"""
function init_model!(model::GridModel3D; initialiser::Function = null_init!)
    initialiser(model) 

    getfield(model, :tick)[] = 1

    _init_agents!(model)

    _init_patches!(model)
    
    _init_model_record!(model)

end




"""
$(TYPEDSIGNATURES)

Runs the simulation for `steps` number of model-steps. Agent properties specified in `aprops` will replace each agents `keeps_record_of` list and will be recorded during simulation. 
The patch properties to be recorded can be specified as list of symbols `pprops`. The model properties to be recorded are specified as `mprops`. 
"""
function run_model!(model::GridModel3D; steps=1, step_rule::Function=model_null_step!, 
    aprops::Vector{Symbol} = Symbol[], pprops::Vector{Symbol} = Symbol[] , mprops::Vector{Symbol} = Symbol[],
    save_to_folder=_default_folder[])

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

    for sym in pprops
        if !(sym in model.record.pprops)
            push!(model.record.pprops, sym)
        end
    end
    for sym in mprops
        if !(sym in model.record.mprops)
            push!(model.record.mprops, sym)
        end
    end

    init_model!(model)

    _run_sim!(model, steps, step_rule, do_after_model_step!)
    
    filename = "run3d"*string(_jld2_count[])

    _save_object_to_disk(model,"model3d", filename = joinpath(save_to_folder, filename))
    
end


function run_without_init!(model::GridModel3D; steps=1, step_rule::Function=model_null_step!)


    _run_sim!(model, steps, step_rule, do_after_model_step!)
    
end


"""
$(TYPEDSIGNATURES)
"""
function save_sim(model::GridModel3D, frames::Int = model.tick)
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
function animate_sim(model::GridModel3D, frames::Int=model.tick; show_grid=false)
    if model.graphics
        ticks = getfield(model, :tick)[]
        model.parameters._extras._show_space = show_grid
        fr = min(frames, ticks)
        vis = Visualizer()
        anim = Animation()
        
        _adjust_origin_and_draw_bounding_box(vis, show_grid)

        if show_grid
            draw_patches_static(vis,model)
        end

        draw_agents_static(vis, model)

        for i in 1:fr
            atframe(anim, i) do
                draw_agents_and_patches(vis, model, i)
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
function create_interactive_app(model::GridModel3D; initialiser::Function = null_init!, step_rule::Function=model_null_step!,
    agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    plots::Dict{String, Function} = Dict{String, Function}(),
    frames=200, show_grid=false) 

    model.parameters._extras._show_space = show_grid
    
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

    empty!(model.record.pprops)
    for key in keys(unwrap(model.patches[(1,1,1)]))
        if (key!=:_extras)
            push!(model.record.pprops, key)
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

    #_run_interactive_model()
    vis = Visualizer()
    function _draw_interactive_frame(t, scl)
        if t>model.tick
            _run_interactive_model(t-model.tick)
        end
        delete!(vis)
        if show_grid
            draw_patches_interact_frame(vis, model, t)
        end
        _draw_agents_interact_frame(vis, model, t, scl)
        return 
    end

    function _render_trivial(s)
        return render(vis)
    end

    _live_interactive_app(model, frames, _init_interactive_model, _run_interactive_model, _draw_interactive_frame, agent_controls, model_controls, plots, _render_trivial)

end





