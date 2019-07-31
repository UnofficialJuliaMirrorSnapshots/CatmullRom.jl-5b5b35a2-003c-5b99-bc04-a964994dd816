Approaching the Unit Circle

    x(t) = cospi(t);  y(t) = sinpi(t)
    (x(t), y(t)) circles as t ↦ 0..2

```julia
using CatmullRom, Plots

fx(t) = cospi(t);
fy(t) = sinpi(t);

xs = [fx(t) for t=range(0.0, stop=2.0, length=17)];
ys = [fy(t) for t=range(0.0, stop=2.0, length=17)];
points = collect(zip(xs, ys));

cxs,cys = catmullrom(points, 16);

plot(cxs,cys, linecolor=:grey, linewidth=4, size=(600,600), legend=nothing, xaxis=nothing, yaxis=nothing)
plot!(xs, ys, linecolor=:blue, linewidth=2, size=(600,600), legend=nothing, xaxis=nothing, yaxis=nothing)
```
