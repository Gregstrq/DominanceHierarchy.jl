function update_level!(hierarchy::MetaGraph, p::PT, level::UInt8) where PT<:AbstractPartition
    hierarchy[p] = level
    stk = Stack{PT}()
    push!(stk, p)

    while !isempty(stk)
        p = pop!(stk)
        new_level = hierarchy[p] + one(UInt8)
        new_ps = inneighbor_labels(hierarchy, p)
        for new_p in new_ps
            if hierarchy[new_p] < new_level
                hierarchy[new_p] = new_level
                push!(stk, new_p)
            end
        end
    end
end

function build_hierarchy(n::Integer)
    @assert n>0
    p = Partition(n)
    return build_hierarchy(p, "hierarchy of EPs with algebraic multiplicity $n")
end
function build_hierarchy(p::Integer, q::Integer)
    @assert p>=0
    @assert q>=0
    @assert p+q>1

    sp = SignedPartition(p, q)
    return build_hierarchy(sp, "hierarchy of EPs with algebraic multiplicity $(p+q) for the ($p,$q)-pseudometric")
end

function build_hierarchy(p0::PT, hname::AbstractString="hierarchy of EPs starting with $(to_text(p0))") where PT<:AbstractPartition
    hierarchy = MetaGraph(DiGraph(), PT, UInt8, Nothing, hname)
    stk = Stack{PT}()

    push!(stk, p0)
    hierarchy[p0] = zero(UInt8)

    while !isempty(stk)
        p = pop!(stk)
        level = hierarchy[p] + one(UInt8)
        new_ps = get_mutated_partitions(p)
        for new_p in reverse(new_ps)
            if haskey(hierarchy, new_p)
                if level > hierarchy[new_p]
                    update_level!(hierarchy, new_p, level)
                end
                add_edge!(hierarchy, new_p, p)
            else
                hierarchy[new_p] = level
                add_edge!(hierarchy, new_p, p)
                push!(stk, new_p)
            end
        end
    end

    return hierarchy
end

total_length(hierarchy::MetaGraph{T, Graphs.SimpleGraphs.SimpleDiGraph{T}, Partition}) where {T} = total_length(label_for(hierarchy, 1))
compute_signature(hierarchy::MetaGraph{T, Graphs.SimpleGraphs.SimpleDiGraph{T}, SignedPartition}) where {T} = compute_signature(label_for(hierarchy, 1))

default_name(hierarchy::MetaGraph{T, GT, PT}) where {T, GT, PT<:Partition} = "hierarchy_$(total_length(hierarchy))"
default_name(hierarchy::MetaGraph{T, GT, PT}) where {T, GT, PT<:SignedPartition} = "hierarchy_$(compute_signature(hierarchy))"
