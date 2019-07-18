```julia
using CatmullRom, Plots

xt(t) = 16 * sin(t)^3
yt(t) = 13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)

ts = collect(range(0.0, length=15, stop=2.0*pi));
n_between = 28;

xs=xt.(ts); ys=yt.(ts);
points = collect(zip(xs,ys));

crpts = catmullrom(points, n_between);
cxs,cys=crpts;

plot(xs, ys, linecolor=:lightgreen, linewidth=7, size=(500,500), xaxis=nothing, yaxis=nothing, legend=nothing)
plot!(cxs, cys, linecolor=:black, linewidth=2, size=(500,500), xaxis=nothing, yaxis=nothing, legend=nothing)

arcpoints = (8, 64)
crpts = catmullrom_by_arclength(points, arcpoints);
cxs,cys=crpts;

plot(xs, ys, linecolor=:lightgreen, linewidth=7, size=(500,500), xaxis=nothing, yaxis=nothing, legend=nothing)
plot!(cxs, cys, linecolor=:black, linewidth=2, size=(500,500), xaxis=nothing, yaxis=nothing, legend=nothing)

```
