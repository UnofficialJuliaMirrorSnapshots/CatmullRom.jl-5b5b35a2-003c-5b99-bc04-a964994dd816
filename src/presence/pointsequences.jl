function extend_seq(points::P; scale=ReflectionScale) where P
    return if isclosed(points)
               extend_closed_seq(points)
           else
               extend_open_seq(points, scale=scale)
           end
end

function unextend_seq(points::P) where P
    pop!(points)
    popfirst!(points)
    return points
end

function extend_closed_seq(points::P) where P
    !isclosed(points) && throw(ErrorException("sequence is not closed"))
    npoints(points) < 3 && throw(ErrorException("cannot extend a sequence with fewer than 3 points"))

    pushfirst!(points, points[end-1])
    push!(points, points[3]) 
    return points
end    

function extend_open_seq(points::P; scale=ReflectionScale) where P
    isclosed(points) && throw(ErrorException("sequence is not open"))
    npoints(points) < 3 && throw(ErrorException("cannot extend a sequence with fewer than 3 points"))
    
    initialpoint = pointbefore(points[1:4], scale)
    finalpoint   = pointafter(points[end-3:end], scale)
    pushfirst!(points, initialpoint)
    push!(points, finalpoint) 
    return points
end
    
function close_seq(points::P) where P
    isempty(points) && throw(ErrorException("cannot close an empty sequence"))
    if isapproxclosed(points)
        points[end] = points[1]
    end
    if !isclosed(points)
        push!(points, points[1])
    end
    return points
end


isclosed(firstpoint::P, lastpoint::P) where P = firstpoint == lastpoint
isclosed(points::P) where P = isclosed(first(points), last(points))

isapproxclosed(points::P) where P = isapproxclosed(first(points), last(points))

function isapproxclosed(firstpoint::P, lastpoint::P) where P
    nrm1 = norm(sqrt(eps(norm(firstpoint))), sqrt(eps(norm(lastpoint))))
    nrm2 = norm(firstpoint .- lastpoint)
    return nrm1 >= nrm2
end

npoints(pts::P) where P = length(pts)
npoints(pts::Base.Iterators.Zip) = length(pts)

ncoords(pts::P) where P = eltype(pts) <: NamedTuple ? length(Tuple(pts[1])) : length(pts[1])
ncoords(pts::Base.Iterators.Zip) = eltype(pts) <: NamedTuple ? length(Tuple(first(pts))) : length(first(pts))

coordtype(pts::P) where P = eltype(pts) <: Number ? eltype(pts) : eltype(eltype(pts))

function coordtype(::Type{T}) where {T}
    result = T
    !(result<:Number) ? (result = eltype(result)) : (return result)
    !(result<:Number) ? (result = eltype(result)) : (return result)
    !(result<:Number) ? (result = eltype(result)) : (return result)
    !(result<:Number) ? throw(ErrorException("unable to discern the coordinate type for $T")) : (return result)
end

Base.convert(::Type{Array{T,1}}, x::NTuple{N,T}) where {N,T} = [x...,]
Base.convert(::Type{NTuple{N,T}}, x::Array{T,1}) where {N,T} = (x...,)

function coords_to_cols(coords...)
    n_cols = length(coords)
    n_rows = length(coords[1])
    return reshape(vcat(coords...,), n_rows, n_cols)
end

cols_to_coords(cols::Array{T,2}) where T = [cols[:,i] for i=1:(size(cols)[2])]

coords_to_points(coords...) = collect(zip(coords...,))

function points_to_coords(x)
    n_dims  = length(x[1])
    n_items = length(x)
    typ = eltype(eltype(x[1]))
    res = Array{typ, 2}(undef, (n_items, n_dims))
    for k=1:n_points
       for i=1:n_dims
          res[k,i] = x[k][i]
       end
    end
    return res
end

cols_to_points(x) = coords_to_points(cols_to_coords(x))
points_to_cols(x) = coords_to_cols(points_to_coords(x))
