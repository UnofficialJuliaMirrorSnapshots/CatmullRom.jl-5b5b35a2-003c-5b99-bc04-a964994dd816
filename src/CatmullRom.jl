"""
    CatmullRom

Interpolate using the centripetal parameterization of Catmull-Rom splines.
This is the form that does not crimp, provides taughtness, and looks good.
"""
module CatmullRom

export catmullrom,               # populates with points placed between those given
       catmullrom_by_arclength,  # populates with points placed between those given relative to arclength
       close_seq!,               # ensures a point sequence is closed, precisely
       floatvecs                 # obtain a vector of vectors of floats

using LinearAlgebra: dot, norm, normalize
using Polynomials: Poly, polyval

include("utilities.jl")

# The sorts of sequences understood to hold point coordinates
#     defines `Points`m `npoints(Points)`, `ncoords(Points)`
include("presence/pointsequences.jl")

# suggest outermost two points for Catmull-Rom spline sequence
const ReflectionScale = 1.0
const ArcpointsMin = 8
const ArcpointsMax = 64


include("fewpoints/outside.jl")

# centripetal Catmull-Rom compution
include("centripetal/catmullrom.jl")
include("centripetal/arcbased.jl")

# extrapolation using low-order interpolatory fits
include("fewpoints/twopoints.jl")    # linear fit, reflection
include("fewpoints/threepoints.jl")  # thiele3 rational fit, general quadratic fit
include("fewpoints/fourpoints.jl")   # thiele4 rational fit (preferred)

# myunzip, anglesep
include("presence/support.jl")

end # CatmullRom
