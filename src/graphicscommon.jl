mutable struct GrParams
    width::Int
    height::Int
    border::Int
    fps::Int
    GrParams(;width::Int, height::Int, border::Int, fps::Int ) = new(width, height, border, fps)
end

mutable struct GrParams3D
    xlen::Int
    ylen::Int
    zlen::Int
    GrParams3D(;xlen::Int, ylen::Int, zlen::Int ) = new(xlen, ylen, zlen)
end

const gparams = GrParams(width=400,height=400,border=30, fps=12) # graphics parameters
const gparams3d = GrParams3D(xlen=10, ylen=10, zlen=10)
const type_dict = Dict(:color => Col, :shape => Symbol, :pos => GeometryBasics.Vec2{Float64}, :orientation => Float64, :size => Union{Int, Float64})
const makie_shape_dict = Dict(:circle => :circle, :star=>:star5, :arrow=>:utriangle, :diamond => :diamond, :square=>:rect, :box => 'B')


@inline function _draw_title(scene, frame)
    Luxor.text(string("frame $frame of $(scene.framerange.stop)"),  Luxor.Point(O.x, O.y-gparams.height/2+20),halign=:center)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_propvals(model::Union{AbstractSpaceModel{Mortal}, AbstractGraphModel{T, Mortal} }, t, prop::Symbol, scl=1.0) where T<:MType
    propvals = Vector{type_dict[prop]}()
    all_agents = vcat(model.agents, model.agents_killed)
    for agent in all_agents
        agent_data = unwrap_data(agent)
        agent_dict = unwrap(agent)
        if (agent._extras._birth_time<= t)&&(t<= agent._extras._death_time)
            index = t - agent._extras._birth_time +1
            propval = (prop in agent._keeps_record_of) ? agent_data[prop][index] : (prop == :pos ? agent.pos : agent_dict[prop])
            divisor = hasfield(typeof(model), :size) ? model.size[1] : gparams.width
            propval = (prop == :size) ? propval*scl*gparams.width/divisor : propval
            propval = (prop == :pos) ? GeometryBasics.Vec(propval...) : propval
            push!(propvals, propval)
        end
    end
    return propvals
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_propvals(model::Union{AbstractSpaceModel{Static}, AbstractGraphModel{T, Static} }, t, prop::Symbol, scl=1.0) where T<:MType
    propvals = Vector{type_dict[prop]}()
    for agent in model.agents
        agent_data = unwrap_data(agent)
        agent_dict = unwrap(agent)
        propval = (prop in agent._keeps_record_of) ? agent_data[prop][t] : (prop == :pos ? agent.pos : agent_dict[prop])
        divisor = hasfield(typeof(model), :size) ? model.size[1] : gparams.width
        propval = (prop == :size) ? propval*scl*gparams.width/divisor : propval
        propval = (prop == :pos) ? GeometryBasics.Vec(propval...) : propval
        push!(propvals, propval)
    end
    return propvals
end

@inline function _to_makie_shapes(shape::Symbol)
    makie_shape_dict[shape]
end



@inline function _create_circle(size, index=1)
    Luxor.circle(Luxor.Point(0,0), size, :fill)
end

@inline function _create_star(size,index=1)
    Luxor.star(Luxor.Point(0,0), size, 6, 0.5,0, :fill)
end

@inline function _create_diamond(size,index=1)
    Luxor.ngon(Luxor.Point(0,0), size, 4, 0, :fill)
end

@inline function _create_box(size,index=1)
    Luxor.box(Luxor.Point(0, 0), size, size, 5, :fill)
end

@inline function _create_square(size,index=1)
    Luxor.box(Luxor.Point(0, 0), size, size, 0.0001, :fill)
end

@inline function _create_arrow(size,index=1)
    points  = [Luxor.Point(0,size*0.8),Luxor.Point(-size*0.5,-size*0.8),Luxor.Point(size*0.5,-size*0.8)]
    Luxor.poly(points, :fill)
end

@inline function _create_circle_line(size,index=1)
    Luxor.circle(Luxor.Point(0,0), size, :stroke)
end

@inline function _create_star_line(size,index=1)
    Luxor.star(Luxor.Point(0,0), size, 6, 0.5,0, :stroke)
end

@inline function _create_diamond_line(size,index=1)
    Luxor.ngon(Luxor.Point(0,0), size, 4, 0, :stroke)
end

@inline function _create_box_line(size,index=1)
    Luxor.box(Luxor.Point(0, 0), size, size, 5, :stroke)
end

@inline function _create_square_line(size,index=1)
    Luxor.box(Luxor.Point(0, 0), size, size, 0.0001, :stroke)
end

@inline function _create_line(size,index=1)
    Luxor.box(Luxor.Point(0, -size/2), Luxor.Point(0, size/2), :stroke)
end



const shapefunctions2d = Dict{Symbol, Function}(:circle => _create_circle, :star => _create_star, :diamond => _create_diamond, :square=>_create_square, 
                        :box=> _create_box, :arrow=>_create_arrow, :circle_line => _create_circle_line, :star_line => _create_star_line, :diamond_line => _create_diamond_line,
                        :box_line => _create_box_line, :square_line => _create_square_line, :line => _create_line)

@inline function _create_sphere(size)
    HyperSphere(MeshCat.Point(0,0,0.0), size)
end

@inline function _create_3Dbox(size)
    HyperRectangle(MeshCat.Vec(0,0,0.0), MeshCat.Vec(size, size, size))
end

@inline function _create_cone(size)
    Cone(MeshCat.Point(0, 0, 0.0), MeshCat.Point(0,0.0,size), size/2)
end

@inline function _create_cylinder(size)
    Cylinder(MeshCat.Point(0,0,-size/2), MeshCat.Point(0,0,size/2), size/2)
end

@inline function tail_opacity(i::Int, tail_length::Int)
    1- (i/tail_length)^2
end

const shapefunctions3d = Dict{Symbol, Function}(:sphere => _create_sphere, :box => _create_3Dbox, :cone => _create_cone, :cylinder => _create_cylinder)


function backdrop(scene, frame)
    Luxor.background("green")
end

"""
$(TYPEDSIGNATURES)
"""
function _interactive_app(model::Union{AbstractSpaceModel, AbstractGraphModel}, fr, plots_only::Bool, _save_sim::Function, draw_frame::Function, 
    agent_df::DataFrames.DataFrame, patch_df::DataFrames.DataFrame, node_df::DataFrames.DataFrame, model_df::DataFrames.DataFrame)
        timeS = slider(1:fr, label = "time")
        scaleS = slider(0.1:0.1:2, label = "scale")
        run = button("run")
        stop = button("stop")
        sv = button("save")
        check = Ref(0)
        checkS = Ref(0)
        ffun() = begin
            #stop.val = 1
            if check[] ==0 
                check[] = 1
            end
            sleep(0.03)
        end
        gfun() = begin
            #run.val = 1
            timeS[]+=1
            if (timeS[]<fr)&&(check[]==0)
                sleep(0.03)
                run[]+=1
            elseif check[] ==1
                check[] = 0
            end
        end
        sfun() = begin
            if checkS[]==0
                checkS[] = 1
                println("Saving animation as gif....")
                _save_sim(scaleS[])
            else
                return
            end
            checkS[]=0
        end
        lis_stop = on(stop) do val
            @async ffun()
        end
        lis_run = on(run) do val
             @async gfun()
        end
        lis_sv = on(sv) do val
            @async sfun()
        end

        plots = Any[]
        if size(agent_df)[1]>0
            pl = Interact.@map plot(Matrix(agent_df)[1:&timeS, :], labels=permutedims(names(agent_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            push!(plots, pl)
        end

        if size(patch_df)[1]>0
            pl = Interact.@map plot(Matrix(patch_df)[1:&timeS, :], labels=permutedims(names(patch_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            push!(plots, pl)
        end

        if size(node_df)[1]>0
            pl = Interact.@map plot(Matrix(node_df)[1:&timeS, :], labels=permutedims(names(node_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            #pl = Interact.@map plot(node_df[:,nm][1:&timeS], legend=false, xlabel = "time", ylabel= nm, size=(300,150) );
            push!(plots, pl)
        end

        if size(model_df)[1]>0
            pl = Interact.@map plot(Matrix(model_df)[1:&timeS, :], labels=permutedims(names(model_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            #pl = Interact.@map plot(node_df[:,nm][1:&timeS], legend=false, xlabel = "time", ylabel= nm, size=(300,150) );
            push!(plots, pl)
        end

    
        animlux = Interact.@map draw_frame(&timeS, &scaleS)
        
        
        spc = Widgets.latex("\\;"^2) #smallspace
        spclarge = Widgets.latex("\\;"^45) #largespace

        if plots_only
            sv = spc
        end


        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "sv"=>sv])
        @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, hbox(spc, :run, spc, :stop, spc, :sv)), spc, animlux, spc, vbox(plots...) ) )  
end

###########

"""
$(TYPEDSIGNATURES)
"""
function _live_interactive_app(model::Union{AbstractSpaceModel, AbstractGraphModel}, fr,
    plots_only::Bool, _save_sim::Function, 
    _init_interactive_model::Function, _run_interactive_model::Function, 
    _draw_interactive_frame::Function, agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    agent_df = DataFrame(),
    render_trivial = ()->nothing, 
    patch_df = DataFrame(),
    node_df = DataFrame(),
    model_df = DataFrame()
    )
    timeS = slider(1:fr, label = "time")
    scaleS = slider(0.1:0.1:2, label = "scale")
    emptyS = slider(1:1, label = "hack")

    ag_controls = Any[]
    ag_listeners = Any[]
    for (a,b,lst) in agent_controls
        if b=="slider"
            s = slider(lst, label = string(a))
            push!(ag_controls, s)
        elseif b=="dropdown"
            dic = Dict{eltype(lst), eltype(lst)}()
            for _i in 1:length(lst)
                dic[lst[_i]] =lst[_i]
            end
            dr = dropdown(dic, label = string(a))
            push!(ag_controls, dr)
        end
        lis = on(ag_controls[end]) do val
            for agent in model.agents
                if agent._extras._active
                    setproperty!(agent, a, val)
                end
            end
        end
        push!(ag_listeners, lis)
    end

    md_controls = Any[]
    md_listeners = Any[]
    for (a,b,lst) in model_controls
        if b=="slider"
            s = slider(lst, label = string(a))
            push!(md_controls, s)
        elseif b=="dropdown"
            dic = Dict{eltype(lst), eltype(lst)}()
            for _i in 1:length(lst)
                dic[lst[_i]] =lst[_i]
            end
            dr = dropdown(dic, label = string(a))
            push!(md_controls, dr)
        end
        lis = on(md_controls[end]) do val
            setproperty!(model.parameters, a, val)
        end
        push!(md_listeners, lis)
    end

    run = button("run")

    stop = button("stop")

    rst = button("reset")

    sv = button("save")

    check = Ref(0)
    checkS = Ref(0)

    ffun() = begin
        if check[] ==0 
            check[] = 1
        end
        sleep(0.05)#yield()
    end

    donecessarystuff() = begin
        if timeS[]>model.tick
            _run_interactive_model(timeS[]-model.tick)
        end 
        timeS[]+=1
    end

    gfun() = begin
        if (timeS[]<fr)&&(check[]==0)
            @sync donecessarystuff()
            sleep(0.05)
            run[] = run[]
        elseif check[] ==1
            check[] = 0
        end
    end

    ufun(md) = begin
        model = md
        for cg in ag_controls
            cg[]=cg[]
        end
        for cg in md_controls
            cg[]=cg[]
        end  
    end

    pls = Any[]
    function _create_plots()
        empty!(pls)
        if size(agent_df)[1]>1
            pl = Interact.@map plot(Matrix(agent_df)[1:&timeS, :], labels=permutedims(names(agent_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            push!(pls, pl)
        end
    
        if size(patch_df)[1]>1
            pl = Interact.@map plot(Matrix(patch_df)[1:&timeS, :], labels=permutedims(names(patch_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            push!(pls, pl)
        end
    
        if size(node_df)[1]>1
            pl = Interact.@map plot(Matrix(node_df)[1:&timeS, :], labels=permutedims(names(node_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            #pl = Interact.@map plot(node_df[:,nm][1:&timeS], legend=false, xlabel = "time", ylabel= nm, size=(300,150) );
            push!(pls, pl)
        end

        if size(model_df)[1]>1
            pl = Interact.@map plot(Matrix(model_df)[1:&timeS, :], labels=permutedims(names(model_df)), xlabel="ticks", ylabel="", legend=:outertopright, size=(300,150))
            #pl = Interact.@map plot(node_df[:,nm][1:&timeS], legend=false, xlabel = "time", ylabel= nm, size=(300,150) );
            push!(pls, pl)
        end
    end

    rfun() = begin 
        check[] = 1
        agent_df, patch_df, node_df, model_df = _init_interactive_model(ufun)
        _create_plots()
        timeS[]= 1
        check[] = 0
    end

    sfun() = begin
        if fr >model.tick
            _run_interactive_model(fr-model.tick)
        end 
        if checkS[]==0
            checkS[] = 1
            println("Saving animation as gif....")
            _save_sim(scaleS[])
        else
            return
        end
        checkS[]=0
    end


    lis_stop = on(stop) do val
        @async ffun()
    end
    lis_run = on(run) do val
         @async gfun()
    end

    lis_rst = on(rst) do val
        @sync rfun()
    end

    lis_sv = on(sv) do val
        sfun()
    end

    rst[] = rst[] #reset initially
    
    function _draw_a_frame(t, scl)
        _draw_interactive_frame(t, scl)
    end

    Plots.gr(fmt=:png)
    _create_plots()

    animlux = Interact.@map _draw_a_frame(&timeS, &scaleS)#&output)

    spc = Widgets.latex("\\;"^2) #smallspace
    spclarge = Widgets.latex("\\;"^45) #largespace

    if plots_only
        sv = spc
        scaleS = spc
    end



    if !(typeof(model)<:SpaceModel3D)
        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "rst"=>rst, "sv"=>sv])
        return @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, vbox(ag_controls...), vbox(md_controls...), hbox(spc, :run, spc, :stop, spc, :rst, spc, :sv)), spc, animlux, spc, vbox(pls...) ) )  
    else
        render3d = Interact.@map render_trivial(&emptyS)
        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "rst"=>rst])
        return @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, vbox(ag_controls...), vbox(md_controls...), hbox(spc, :run, spc, :stop, spc, :rst)), render3d, spc, vbox(pls...) ) )  
    end
    
    # For a blink window do following 
    # w=Window()
    # body!(w, lay) #where lay is the layout defined in if else block

end

