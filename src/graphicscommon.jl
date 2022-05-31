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

const gparams = GrParams(width=400,height=400,border=10, fps=12) # graphics parameters
const gparams3d = GrParams3D(xlen=10, ylen=10, zlen=10)
const type_dict = Dict(:color => Symbol, :shape => Symbol, :pos => GeometryBasics.Vec2{Float64}, :orientation => Float64, :size => Union{Int, Float64})
const makie_shape_dict = Dict(:circle => :circle, :star=>:star5, :arrow=>:utriangle, :diamond => :diamond, :square=>:rect, :box => 'B')


@inline function _draw_title(scene, frame)
    Luxor.text(string("frame $frame of $(scene.framerange.stop)"),  Luxor.Point(O.x, O.y-gparams.height/2+20),halign=:center)
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_propvals(model::Union{AbstractGridModel{MortalType}, AbstractGraphModel{T, MortalType} }, t, prop::Symbol, scl=1.0) where T<:MType
    propvals = Vector{type_dict[prop]}()
    all_agents = vcat(model.agents, model.parameters._extras._agents_killed)
    for agent in all_agents
        agent_data = unwrap_data(agent)
        agent_dict = unwrap(agent)
        if (agent._extras._birth_time<= t)&&(t<= agent._extras._death_time)
            index = t - agent._extras._birth_time +1
            propval = (prop in agent.keeps_record_of) ? agent_data[prop][index] : agent_dict[prop]
            propval = (prop == :size) ? propval*scl*gparams.width/model.size[1] : propval
            push!(propvals, propval)
        end
    end
    return propvals
end


"""
$(TYPEDSIGNATURES)
"""
@inline function _get_propvals(model::Union{AbstractGridModel{StaticType}, AbstractGraphModel{T, StaticType} }, t, prop::Symbol, scl=1.0) where T<:MType
    propvals = Vector{type_dict[prop]}()
    for agent in model.agents
        agent_data = unwrap_data(agent)
        agent_dict = unwrap(agent)
        propval = (prop in agent.keeps_record_of) ? agent_data[prop][t] : agent_dict[prop]
        propval = (prop == :size) ? propval*scl : propval
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
    background("green")
end

"""
$(TYPEDSIGNATURES)
"""
function _interactive_app(model::Union{AbstractGridModel, AbstractGraphModel}, fr, _save_sim::Function, draw_frame::Function, df::DataFrames.DataFrame)
        timeS = slider(1:fr, label = "time")
        scaleS = slider(0.1:0.1:5, label = "scale")
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
            sfun()
        end

        plots = Any[]
        num_plots = length(names(df))
        for nm in names(df)
            height =Int(ceil((gparams.height+gparams.border)/num_plots))
            pl = Interact.@map plot(df[:,nm][1:&timeS], legend=false, xlabel = "time", ylabel= nm, size=(300,150) );
            push!(plots, pl)
        end

        animlux = Interact.@map draw_frame(&timeS, &scaleS)#&output)
        spc = Widgets.latex("\\;"^2) #smallspace
        spclarge = Widgets.latex("\\;"^45) #largespace
        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "sv"=>sv])
        @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, hbox(spc, :run, spc, :stop, spc, :sv)), spc, animlux, spc, vbox(plots...) ) )  
end

###########

"""
$(TYPEDSIGNATURES)
"""
function _live_interactive_app(model::Union{AbstractGridModel, AbstractGraphModel}, fr,_save_sim::Function, 
    _init_interactive_model::Function, _run_interactive_model::Function, 
    _draw_interactive_frame::Function, agent_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), 
    model_controls=Vector{Tuple{Symbol, Symbol, AbstractArray}}(), plots::Dict{String, Function} = Dict{String, Function}(), render_trivial = ()->nothing)

    timeS = slider(1:fr, label = "time")
    scaleS = slider(0.1:0.1:5, label = "scale")
    emptyS = slider(1:1, label = "hack")
    ag_controls = Any[]
    ag_listeners = Any[]
    for (a,b,lst) in agent_controls
        if b==:s
            s = slider(lst, label = string(a))
            push!(ag_controls, s)
        elseif b==:d
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
        if b==:s
            s = slider(lst, label = string(a))
            push!(md_controls, s)
        elseif b==:d
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
        #timeS[]+=1
        if (timeS[]<fr)&&(check[]==0)
            @sync donecessarystuff()
            sleep(0.05)
            run[] = run[]
        elseif check[] ==1
            check[] = 0
        end
    end

    ufun() = begin
        for cg in ag_controls
            cg[]=cg[]
        end
        for cg in md_controls
            cg[]=cg[]
        end  
    end
    rfun() = begin 
        check[] = 1
        timeS[]=1
        _init_interactive_model(ufun)
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

    function _draw_a_frame(t, scl)
        _draw_interactive_frame(t, scl)
    end

    function draw_plot(t, nm,con)

        if t>model.tick
            _run_interactive_model(t-model.tick)
        end
        df = get_agents_avg_props(model, con, labels= [nm]);

        plot(df[:,nm][1:t], legend=false, xlabel = "time", ylabel= nm, size=(300,150) )

    end
        


    pls = Any[]
    num_plots = length(plots)
    for (nm, con) in plots
        height =Int(ceil((gparams.height+gparams.border)/num_plots))
        pl = Interact.@map draw_plot(&timeS, nm, con);
        push!(pls, pl)
    end

    animlux = Interact.@map _draw_a_frame(&timeS, &scaleS)#&output)

    
    spc = Widgets.latex("\\;"^2) #smallspace
    spclarge = Widgets.latex("\\;"^45) #largespace

    if !(typeof(model)<:GridModel3D)
        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "rst"=>rst, "sv"=>sv])
        return @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, vbox(ag_controls...), vbox(md_controls...), hbox(spc, :run, spc, :stop, spc, :rst, spc, :sv)), spc, animlux, spc, vbox(pls...) ) )  
    else
        render3d = Interact.@map render_trivial(&emptyS)
        wdg = Widget(["timeS"=>timeS,"scaleS"=>scaleS, "run"=>run, "stop"=>stop, "rst"=>rst])
        return @layout! wdg vbox( hbox( vbox(:timeS,:scaleS, vbox(ag_controls...), vbox(md_controls...), hbox(spc, :run, spc, :stop, spc, :rst)), render3d, spc, vbox(pls...) ) )  
    end

end


