"""
    catmullrom_by_arclength( points )    
    catmullrom_by_arclength( points, (min_between_points, max_between_points))    

Calculates a Catmull-Rom fit through given `points`, where the number of interpoint knots
varys inversely with the approximate arclength of that arc.

`arcpoints_min` and `arcpoints_max` refer any one arc between two points.
""" catmullrom_by_arclength

function catmullrom_by_arclength(points::P, arcpoints::Tuple{I,I}=(ArcpointsMin, ArcpointsMax), extend::Bool=true) where {P, I<:Integer}
    catmullrom_requirement(npoints(points))    
    
    crpoints = deepcopy(points)
    if extend
        extend_seq(crpoints)
    end
    
    return catmullrombyarclength(crpoints, minmax(arcpoints...))
end


function catmullrombyarclength(points::P, arcpoints::Tuple{I,I}=(ArcpointsMin, ArcpointsMax)) where {P, I<:Integer}
    n_points = npoints(points)
    pointsperarc = arclength_interpolants(points, arcpoints)
    total_points = sum(pointsperarc) + n_points
    n_coords = ncoords(points)
    T = coordtype(points)
    result = []
    for i=1:n_coords
        push!(result, T[])
    end
    point_seqs = [points[i:i+3] for i=1:(length(points)-3)]

    n_points_3 = n_points - 3
    for idx=1:(n_points-3)
        fourpoints = point_seqs[idx]
        n_between  = pointsperarc[idx]
        fitted = catmullrom_splines(fourpoints, n_between)
        for j=1:n_coords
            append!(result[j], fitted[j][1:(end-1+(idx==n_points_3))])
        end
    end
    
    return result
end

"""
    arclength_interpolants(points; arcpoints_min=2, arcpoints_max=64)
Convert a sequence of points and a count of additional points to interpolate
to a sequence of arc-length specific point counts where each arc has at least
`arcpoints_min` and at most `arcpoints_max` points.
"""
function arclength_interpolants(points::P, arcpoints::Tuple{I,I}=(ArcpointsMin, ArcpointsMax)) where {P, I<:Integer}
    normalized_arclengths = normalized_catmullrom_arclengths(points)
    
    arclength_min = minimum(normalized_arclengths)
    multiplier = nextfloat(arcpoints_min / arclength_min)
    arcpoints = floor.(Int, normalized_arclengths .* multiplier)
    arcpoints = arcpoints .+ isodd.(arcpoints)

    most_arcpoints = maximum(arcpoints)
    if most_arcpoints > arcpoints_max
        multiplier = prevfloat(arcpoints_max / (most_arcpoints + arcpoints_min))
        arcpoints  = floor.(Int, muladd.(arcpoints .- arcpoints_min, multiplier, arcpoints_min))
        arcpoints = arcpoints .+ isodd.(arcpoints)
    end
        
    return arcpoints
end    
   

"""
    normalized_catmullrom_arclengths(points)
Convert a sequence of CatmullRom points, those given
as data and those interpolated through the data,
to a corresponding sequence of normalized arclengths.
The sum of the normalized arclengths is 1.0.  Each
arc's approximated length is a portion of unity.
The most probable arclength, and the mean of these
normalized arclengths are roughly equal; given by:
`1//number_of_arcs`.
The way to use normalized arclengths is to multiply
the fractional lengths by the number of "plottable"
points (the given data + the interpoint interpolants).
```
smallest_arc = minimum(normalized_arclengths)
rational_arc = rationalize(Float16(smallest_arc))
scalefactor = points_to_realize / denominator(rational_arc)
# scaled_arclengths_are_point_counts counting points on the arc
points_per_arc = round.(Int, normalized_arclengths .* scalefactor)
```
"""
function normalized_catmullrom_arclengths(points::P) where P
    arclengths = approx_catmullrom_arclengths(points)
    sum_of_arcs = sum(arclengths)
    arclengths[:] = arclengths ./ sum_of_arcs
    return arclengths
end


"""
    approx_catmullrom_arclengths(points)
Convert a sequence of CatmullRom points, those given
as data and those interpolated through the data,
to a corresponding sequence of arclength approximations.
"""
function approx_catmullrom_arclengths(points::P) where P
    L = float(coordtype(P))
    n_points = npoints(points)
    # the first two points and the last two points are boundary + anchor
    # boundary anchor first_internal_point ... final_internal_point anchor boundary
    #       noarc   arc                    arcs                   arc   noarc
    #    pt1     pt2     pt3                            ptN-2       ptN-1     ptN
    #                                   pt4 .. ptN-3
    #               1 arc               ((N-3)-4 arcs)          1 arc
    #  N-3-4+1+1 = N-1-4 = Npts-5 arcs
    n_arcs = n_points - 3 
    result = Array{L, 1}(undef, n_arcs)

    # points[1:4], points[2:5], .. points[idx:idx+3] .., points[N-3:N]
    for idx = 1:n_points-3
        arc = approx_catmullrom_arclength(points[idx:idx+3]...,)
        result[idx] = arc
    end   
    return result    
end


"""
    approx_catmullrom_arclength(pt0, pt1, pt2, pt3)
Given 4 ND points along a centripetal Catmull-Rom span,
roughly approximate the arclength of the curvilinear segment
that would be determined by the two bounding points
and the tangents they determine [the arc between p1 and p2].
This well-behaved approximation was developed by Jens Gravesen
```
    (2*corddist + (n-1)*bezdist)/(n+1), n is degree of the curve
    deg=2 --> (2*corddist + bezdist)/(3)
    deg=3 --> (2*corddist + 2*bezdist)/(4) --> (corddist + bezdist)/2
    deg=4 --> (2*corddsit + 3*bezdist)/(5)
```
"""
function approx_catmullrom_arclength(p0::T, p1::T, p2::T, p3::T) where T
    b0, b1, b2, b3 = catmullrom_as_bezier(p0, p1, p2, p3)
    cordal_dist = norm(b3 .- b0)
    bezier_dist = norm(b1 .- b0) + norm(b2 .- b1) + norm(b3 .- b2)
    
    return (cordal_dist + bezier_dist) * 0.5
end

function catmullrom_as_bezier(p0::T, p1::T, p2::T, p3::T) where T
    b0 = p1
    b3 = p2
    
    d1 = norm(p1 .- p0); d1a = sqrt(d1)
    d2 = norm(p2 .- p1); d2a = sqrt(d2)
    d3 = norm(p3 .- p2); d3a = sqrt(d3)
    
    b1n = @. (d1 * p2) - (d2 * p0) + ((2*d1 + 3*d1a*d2a+d2) * p1)
    b1d = 3*d1a*(d1a+d2a)
    b1 = b1n ./ b1d
    b2n = @. (d3 * p1) - (d2 * p3) + ((2*d3 + 3*d3a*d2a+d2) * p2)
    b2d = 3*d3a*(d3a+d2a)
    b2 = b2n ./ b2d
    
    return b0, b1, b2, b3
end
