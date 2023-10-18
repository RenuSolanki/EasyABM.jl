function random_positions(n::Int)
    return rand(n), rand(n)
end

"""
$(TYPEDSIGNATURES)

This function is copied, with some modifications, from 
https://github.com/JuliaGraphs/GraphPlot.jl/blob/master/src/layout.jl
"""
function spring_layout(structure;
    C=3.5,
    REPEL_NUM = 25,
    MAXITER=200,
    INITTEMP=2.0)

    rng= Random.MersenneTwister(123)
    locs_x=rand(rng, length(keys(structure)))
    locs_y=rand(rng, length(keys(structure)))

    verts = sort!(collect(keys(structure)))
    nvg = length(verts)
    if nvg ==1
        return [0.5*gsize], [0.5*gsize]
    end
    if nvg==2
        return [0.3*gsize, 0.7*gsize], [0.5*gsize,0.5*gsize]
    end
    if nvg==3
        return [0.5*gsize,0.3*gsize,0.7*gsize], [0.7*gsize,0.3*gsize,0.3*gsize]
    end
    k = C * sqrt(1.0 / nvg)
    k² = k * k

    for iter = 1:MAXITER
        for (l, node) in enumerate(verts)
            force_vec_x = 0.0
            force_vec_y = 0.0

            for vt in structure[node]
                ind = findfirst(s->s==vt, verts)
                d_x = locs_x[ind] - locs_x[l]
                d_y = locs_y[ind] - locs_y[l]
                dist²  = (d_x * d_x) + (d_y * d_y)
                dist = sqrt(dist²)
                F_d = dist / k - k² / dist²
                force_vec_x += F_d*d_x
                force_vec_y += F_d*d_y
            end

            num = min(REPEL_NUM, nvg)
            for _ in 1:num
                vt = verts[rand(1:nvg)]
                if (vt!=node) && !(vt in structure[node])
                    ind = findfirst(s->s==vt, verts)
                    d_x = locs_x[ind] - locs_x[l]
                    d_y = locs_y[ind] - locs_y[l]
                    dist²  = (d_x * d_x) + (d_y * d_y)
                    dist = sqrt(dist²)
                    F_d =  - k² / dist²
                    force_vec_x += F_d*d_x
                    force_vec_y += F_d*d_y
                end
            end

            temp = INITTEMP / iter
            fx = force_vec_x
            fy = force_vec_y
            force_mag  = sqrt((fx * fx) + (fy * fy))
            scale      = min(force_mag, temp) / force_mag
            locs_x[l] += fx*scale 
            locs_y[l] += fy*scale
        end

    end

    # Scale
    min_x, max_x = minimum(locs_x), maximum(locs_x)
    min_y, max_y = minimum(locs_y), maximum(locs_y)
    function scaler(z, a, b)
        ((z - a)/(b - a))*_scale_graph+_boundary_frame
    end
    map!(z -> gsize*scaler(z, min_x, max_x), locs_x, locs_x)
    map!(z -> gsize*scaler(z, min_y, max_y), locs_y, locs_y)

    return locs_x, locs_y
end



function spring_layout3d(structure;
    C=3.5,
    REPEL_NUM = 25,
    MAXITER=200,
    INITTEMP=2.0)

    rng= Random.MersenneTwister(123)
    locs_x=rand(rng, length(keys(structure)))
    locs_y=rand(rng, length(keys(structure)))
    locs_z=rand(rng, length(keys(structure)))


    verts = sort!(collect(keys(structure)))
    nvg = length(verts)
    if nvg ==1
        return [0.5*gsize], [0.5*gsize], [0.5*gsize]
    end
    if nvg==2
        return [0.4*gsize, 0.7*gsize], [0.4*gsize,0.7*gsize], [0.5*gsize,0.5*gsize]
    end
    if nvg==3
        return [0.5*gsize,0.3*gsize,0.7*gsize], [0.7*gsize,0.3*gsize,0.3*gsize], [0.5*gsize,0.5*gsize,0.5*gsize]
    end
    k = C * sqrt(1.0 / nvg)
    k² = k * k

    for iter = 1:MAXITER
        for (l, node) in enumerate(verts)
            force_vec_x = 0.0
            force_vec_y = 0.0
            force_vec_z = 0.0

            for vt in structure[node]
                ind = findfirst(s->s==vt, verts)
                d_x = locs_x[ind] - locs_x[l]
                d_y = locs_y[ind] - locs_y[l]
                d_z = locs_z[ind] - locs_z[l]
                dist²  = (d_x * d_x) + (d_y * d_y) + (d_z * d_z)
                dist = sqrt(dist²)
                F_d = dist / k - k² / dist²
                force_vec_x += F_d*d_x
                force_vec_y += F_d*d_y
                force_vec_z += F_d*d_z
            end

            num = min(REPEL_NUM, nvg)
            for _ in 1:num
                vt = verts[rand(1:nvg)]
                if (vt!=node) && !(vt in structure[node])
                    ind = findfirst(s->s==vt, verts)
                    d_x = locs_x[ind] - locs_x[l]
                    d_y = locs_y[ind] - locs_y[l]
                    d_z = locs_z[ind] - locs_z[l]
                    dist²  = (d_x * d_x) + (d_y * d_y) + (d_z * d_z)
                    F_d =  - k² / dist²
                    force_vec_x += F_d*d_x
                    force_vec_y += F_d*d_y
                    force_vec_z += F_d*d_z
                end
            end

            temp = INITTEMP / iter
            fx = force_vec_x
            fy = force_vec_y
            fz = force_vec_z
            force_mag  = sqrt((fx * fx) + (fy * fy) + (fz * fz))
            scale      = min(force_mag, temp) / force_mag
            locs_x[l] += fx*scale 
            locs_y[l] += fy*scale
            locs_z[l] += fz*scale
        end

    end

    # Scale 
    min_x, max_x = minimum(locs_x), maximum(locs_x)
    min_y, max_y = minimum(locs_y), maximum(locs_y)
    min_z, max_z = minimum(locs_z), maximum(locs_z)
    function scaler(z, a, b)
        ((z - a)/(b - a))*_scale_graph+_boundary_frame
    end
    map!(z -> gsize*scaler(z, min_x, max_x), locs_x, locs_x)
    map!(z -> gsize*scaler(z, min_y, max_y), locs_y, locs_y)
    map!(z -> gsize*scaler(z, min_z, max_z), locs_z, locs_z)

    return locs_x, locs_y, locs_z
end





