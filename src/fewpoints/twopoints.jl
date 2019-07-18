function reflectback(pt₁::T, pt₂::T; scale=ReflectionScale) where {T}
   return @. pt₁ - ((pt₂ - pt₁) * scale)
end

function reflectforward(pt₁::T, pt₂::T; scale=ReflectionScale) where {T}
    return @. pt₂ + ((pt₂ - pt₁) * scale)
end

linear(pt₁, pt₂, x) =
    linear.(pt₁[1], pt₂[1],
            pt₁[2:end], pt₂[2:end], x)

function linear(pt₁x, pt₂x, pt₁y, pt₂y, x)
    a = (pt₁y - pt₂y) * x
    b = (pt₁x*pt₂y - pt₁y*pt₂x)
    den = pt₁x - pt₂x
    return (a + b) / den
end

# use two of three points (degenerate quadratic)
function linear(pt₁, pt₂, pt₃, x)
    x₁, x₂, x₃ = pt₁[1], pt₂[1], pt₃[1]
    # sort points
    if x₃ === min(x₂, x₃)
        pt₃, pt₂ = pt₂, pt₃
        x₃, x₂ = x₂, x₃
    end
    if  x₃ === min(x₁, x₃)
        pt₃, pt₁ = pt₁, pt₃
        x₃, x₁ = x₁, x₃
    end
    if  x₂ === min(x₁, x₂)
        pt₂, pt₁ = pt₁, pt₂
        x₂, x₁ = x₁, x₂
    end
    # select two abcissae for linear extrapolation
    if x <= x₂
        result = linear(x₁, x₂, x)
    else
        result = linear(x₂, x₃, x)
    end
    return result
end

function linterp(pt₁, pt₂, n::Int)
    pt₁x, pt₂x = pt₁[1], pt₂[1]
    pt₁y, pt₂y = pt₁[2:end], pt₂[2:end]
    dx = pt₂x - pt₁x
    dy = pt₂y .- pt₁y
    nxs = range(pt₁x, pt₂x, length = n+2)
    nys = range.(pt₁y, pt₂y, length = n+2)
    return collect(zip(nxs, nys...,))
end
