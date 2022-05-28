const _jld2_count = Ref(0)
const _default_folder = Ref{String}(@get_scratch!("abm_data"))   #joinpath(@__DIR__,"../data")
const _default_filename = "model_data.jld2"
const _default_modelname = "model"
const _data_names = Dict{String, String}()

struct DataAlreadyExistsException <: Exception
    err::String
end

Base.showerror(io::IO, e::DataAlreadyExistsException) = print(io, e.err)

"""
$(TYPEDSIGNATURES)
"""
function _save_object_to_disk(object_to_save; name::String = _default_modelname, make_unique=false, save_as = _default_filename, folder = _default_folder[])

    global _default_folder, _jld2_count, _data_names

    filename = joinpath(folder, save_as)

    if  (folder != _default_folder[]) && !isdir(folder)
        println("The folder $folder does not exist!")
        return 
    end

    if (folder == _default_folder[])
        _default_folder[] = @get_scratch!("abm_data") # this line makes sure that default folder exists
        filename = joinpath(_default_folder[], save_as)

        if (_jld2_count[]==0)
            files = readdir(_default_folder[], join=true)
            for file in files
                rm(file)
            end
        end
    end
    
    if make_unique
        name = name*string(_jld2_count[])
    end

    for (key, value) in _data_names
        if (key == name)&&(value==filename)
            throw(DataAlreadyExistsException("Data with name $key already exists at path $value"))
        end
    end

    _data_names[name] = filename

    f = jldopen(filename, "w")

    f[name] = object_to_save

    close(f)

    println("Model with name $name saved as $save_as in folder $folder")

    _jld2_count[]+=1
end


"""
$(TYPEDSIGNATURES)
"""
function _reset_counter()
    _jld2_count[]=0
    return nothing
end