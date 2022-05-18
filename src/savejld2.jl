const _jld2_count = Ref(0)
const _default_folder = Ref{String}(@get_scratch!("simple_abm_data"))   #joinpath(@__DIR__,"../data")
const _data_names = Dict{String, String}()

struct DataAlreadyExistsException <: Exception
    err::String
end

Base.showerror(io::IO, e::DataAlreadyExistsException) = print(io, e.err)

"""
$(TYPEDSIGNATURES)
"""
function _save_object_to_disk(object_to_save, name::String; make_unique=false, filename = joinpath(_default_folder[], "model_data.jld2"))
    global _default_folder
    if (filename == joinpath(_default_folder[], "model_data.jld2")) && !isdir(_default_folder[])
        _default_folder[] = @get_scratch!("simple_abm_data")
        filename == joinpath(_default_folder[], "model_data.jld2")
    end
    if _jld2_count[]==0
        files = readdir(_default_folder[], join=true)
        for file in files
            rm(file)
        end
    end
    
    if make_unique
        name = name*string(_jld2_count[])
    end

    for (key, value) in _data_names
        if (key == name)&&(value==filename)
            throw(DataAlreadyExistsException("Data with $key already exists at path $value"))
        end
    end

    _data_names[name] = filename

    f = jldopen(filename, "a+")

    f[name] = object_to_save

    close(f)

    _jld2_count[]+=1
end


"""
$(TYPEDSIGNATURES)
"""
function _reset_counter()
    _jld2_count[]=0
    return nothing
end