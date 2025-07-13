plot_hierarchy(hierarchy::MetaGraph{T, Graphs.SimpleGraphs.SimpleDiGraph{T}, PT}; ordering=nothing, labels=:default, fname=default_name(hierarchy), dir=pwd()) where {T, PT<:AbstractPartition} = plot_hierarchy(hierarchy, ordering, get_labels(hierarchy, Val(labels)), joinpath(dir, fname * ".pdf"))

plot_hierarchy(hierarchy::MetaGraph{T, GT, PT}, ::Nothing, labels, fname) where {T, GT, PT<:AbstractPartition} = save(PDF(fname), TikzGraphs.plot(hierarchy.graph, labels))
function plot_hierarchy(hierarchy::MetaGraph{T, GT, PT}, ordering::AbstractVector, labels, fname) where {T, GT, PT<:AbstractPartition}
    @assert sort(ordering)==collect(1:nv(hierarchy))
    p = _plot_h(hierarchy, ordering; labels=labels)
    save(PDF(fname), p)
end

get_labels(hierarchy, ::Val{:default}) = map(i -> to_text(label_for(hierarchy, i)), Base.OneTo(nv(hierarchy)))
get_labels(hierarchy, ::Val{:Code}) = map(string, Base.OneTo(nv(hierarchy)))

function _plot_h(g::MetaGraph, ordering::AbstractVector; layout::TikzGraphs.Layouts.Layout = TikzGraphs.Layouts.Layered(), labels::Vector{T}=map(string, vertices(g)), edge_labels::Dict = Dict(), node_styles::Dict = Dict(), node_style="", edge_styles::Dict = Dict(), edge_style="", options="", graph_options="", prepend_preamble::String="") where T<:AbstractString
    o = IOBuffer()
    println(o, "\\graph [$(TikzGraphs.layoutname(layout)), $(TikzGraphs.options_str(layout)), $graph_options] {")
    for v in ordering
        TikzGraphs.nodeHelper(o, v, labels, node_styles, node_style)
    end
    println(o, ";")
    for e in reorder_edges(g, ordering)
        a = src(e)
        b = dst(e)
        print(o, "$a $(TikzGraphs.edge_str(g))")
        TikzGraphs.edgeHelper(o, a, b, edge_labels, edge_styles, edge_style)
        println(o, "$b;")
    end
    println(o, "};")
    mypreamble = prepend_preamble * TikzGraphs.preamble * "\n\\usegdlibrary{$(TikzGraphs.libraryname(layout))}"
    TikzPicture(String(take!(o)), preamble=mypreamble, options=options)
end



function reorder_edges(hierarchy, ordering)
    ev = edges(hierarchy)|>collect
    function idx(e::Graphs.SimpleEdge)
        return (findfirst(x->x==src(e), ordering), findfirst(x->x==dst(e), ordering))
    end
    compare_idx(idx1, idx2) = idx1[1]<idx2[1] || (idx1[1]==idx2[1] && idx1[2]<idx2[2])
    sort!(ev; by=idx, lt=compare_idx)
    return ev
end

TikzGraphs.edge_str(g::MetaGraph) = "->"

to_ydiagram!(io::Union{IOBuffer, IOStream}, p::Partition) = println(io, "    \\ydiagram{$(to_text(p)[2:end-1])}")

function to_ydiagram!(io::Union{IOBuffer,IOStream}, sp::SignedPartition)
    println(io, "    \\begin{ytableau}")
    for i=1:length(sp)
        to_ydiagram!(io, sp[i])
    end
    println(io, "    \\end{ytableau}")
end
function to_ydiagram!(io::Union{IOBuffer,IOStream}, spb::SignedPartitionBlock)
    m = spb[1]
    s = (-1)^(m-1)*spb[2]
    sigs = map(x->(x==1 ? "+" : "-"), [s, -s])

    output = "    "^2*"$(sigs[1]) "
    counter = 2
    is = 1
    while counter <= m
        output *= "& $(sigs[is+1])"
        counter += 1
        is = is ⊻ 1
    end
    output *= " \\\\"
    for i=1:num_of_copies(spb)
        println(io, output)
    end
end

function skip_columns!(io::Union{IOBuffer,IOStream}, n)
    @assert n>-1
    if n==0
        return
    end
    print(io, "    \\&")
    counter = 2
    while counter <= n
        print(io, " \\&")
        counter += 1
    end
    print(io, "\n")
end

function process_arrow!(io::Union{IOBuffer,IOStream}, arrow::NTuple{2,Int})
    @assert arrow[1]<0
    identifier = repeat("d", -arrow[1]) * repeat(arrow[2]>0 ? "r" : "l", abs(arrow[2]))
    print(io, "\\arrow[$identifier]")
end
function process_arrows!(io::Union{IOBuffer,IOStream}, arrows::Vector{NTuple{2, Int}})
    if isempty(arrows)
        return
    end
    print(io, "    ")
    for arrow in arrows
        process_arrow!(io, arrow)
    end
    print(io, "\n")
end

function manual_output_to_tex(hierarchy::MetaGraph{T, Graphs.SimpleGraphs.SimpleDiGraph{T}, PT}, layout::Dict{Int,Int}; output_to_file=false, fname=default_name(hierarchy), dir = pwd()) where {T<:Integer, PT<:AbstractPartition}
    @assert sort(keys(layout)|>collect)==collect(1:nv(hierarchy))

    graph = hierarchy.graph

    levels = [hierarchy[label_for(hierarchy, i)]|>Int for i=1:nv(hierarchy)]
    horizontals = zeros(Int, length(levels))
    for (code,horizontal) in layout
        horizontals[code] = horizontal
    end

    left = minimum(horizontals)
    right = maximum(horizontals)

    max_level = maximum(levels)
    full_layout  = zip(1:nv(hierarchy), levels, horizontals)|>collect
    p = sortperm(full_layout, lt = (x,y)->(x[2]>y[2] || (x[2]==y[2] && x[3]<y[3])))
    permute!(full_layout, p)
    ordering = invperm(p)

    level_starts = zeros(Int, max_level+2)
    level_starts[1] = 1
    counter = 1
    for i=2:length(full_layout)
        if full_layout[i][2]<full_layout[i-1][2]
            counter += 1
            level_starts[counter] = i
        end
    end
    level_starts[end] = length(full_layout)+1

    io = IOBuffer()
    println(io, "\\begin{tikzcd}[ampersand replacement=\\&]")
    for il = 1:length(level_starts)-1
        prev = left
        for (code, level, horizontal) in view(full_layout, level_starts[il]:level_starts[il+1]-1)
            skip_columns!(io, horizontal - prev)
            to_ydiagram!(io, label_for(hierarchy, code))
            process_arrows!(io, full_layout[ordering[outneighbors(graph, code)]] .|> x -> (x[2:3] .- (level, horizontal)))
            prev = horizontal
        end
        skip_columns!(io, right-prev)
        println(io, "    \\\\")
    end
    println(io, "\\end{tikzcd}")

    str = String(take!(io))

    if output_to_file
        open(joinpath(dir, filename * ".tex"), "w") do file
            print(file, str)
        end
    end
    return str
end
