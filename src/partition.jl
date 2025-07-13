struct PartitionBlock
    pb::NTuple{2, UInt8}
end
PB(m,p) = (@assert m>=0; @assert p>=0; PartitionBlock((m,p)))
getindex(pb::PartitionBlock, i) = pb.pb[i]
length(pb::PartitionBlock) = pb[1]
num_of_copies(pb::PartitionBlock) = pb[2]

isless(pb1::T, pb2::T) where {T<:PartitionBlock} = length(pb1)<length(pb2)
==(pb1::T, pb2::T) where {T<:PartitionBlock} = length(pb1)==length(pb2)
isequal(pb1::T, pb2::T) where {T<:PartitionBlock} = isequal(pb1.pb, pb2.pb)
hash(pb::PartitionBlock) = hash(pb.pb)

decrement(pb::PartitionBlock) = PB(pb[1],pb[2]-1)
increment(pb::PartitionBlock) = PB(pb[1],pb[2]+1)
decrement2(pb::PartitionBlock) = PB(pb[1],pb[2]-2)
change(pb::PartitionBlock, n) = PB(pb[1]+n, 1)

struct Partition <: AbstractPartition
    p::Vector{PartitionBlock}
end
Partition(n::Int) = Partition([PB(1,n)])
getindex(p::Partition, i) = p.p[i]
length(p::Partition) = length(p.p)

isequal(p1::T, p2::T) where T<:Partition = isequal(p1.p, p2.p)
hash(p::Partition) = hash(p.p)

function mutations(pb::PartitionBlock)
    if num_of_copies(pb)<2
        return Vector{NTuple{3, PartitionBlock}}()
    end
    return [(change(pb, 1), decrement2(pb), change(pb, -1))]
end
function mutations(pb1::T, pb2::T) where T<:PartitionBlock
    @assert pb1>pb2
    if num_of_copies(pb1)>1 || num_of_copies(pb2)>1
        return Vector{NTuple{2, PartitionBlock}}()
    end
    return [(change(pb1, 1), change(pb2, -1))]
end
mutations(p::Partition, I::NTuple{2,Integer}) = mutations(p[I[1]], p[I[2]])
mutations(p::Partition, i::Integer) = mutations(p[i])


is_scippable(pb::PartitionBlock) = pb[1]==0 || pb[2]==0

function mutate_partition(p::Partition, i::Integer, mutation::NTuple{3,PartitionBlock})
    new_p = vcat(p.p[1:i-1], mutation..., p.p[i+1:end])
    i₀ = i
    j₀ = i+2

    move_left!(new_p, i₀)
    move_right!(new_p, j₀)
    return Partition(filter(x->!is_scippable(x), new_p))
end
function mutate_partition(p::Partition, I::NTuple{2,Integer}, mutation::NTuple{2,PartitionBlock})
    @assert I[2]-I[1]==1
    new_p = vcat(p.p[1:I[1]-1], mutation..., p.p[I[2]+1:end])
    i₀ = I[1]
    j₀ = I[2]

    move_left!(new_p, i₀)
    move_right!(new_p, j₀)
    return Partition(filter(x->!is_scippable(x), new_p))
end

function get_mutated_partitions(p::Partition, I)
    mts = mutations(p, I)
    if isempty(mts)
        return Vector{Partition}()
    end
    return [mutate_partition(p, I, m) for m in mts]
end
function get_mutated_partitions(p::Partition)
    new_ps = Vector{Partition}()

    for i=1:length(p)-1
        append!(new_ps, get_mutated_partitions(p, (i,i+1)))
        append!(new_ps, get_mutated_partitions(p, i))
    end
    append!(new_ps, get_mutated_partitions(p, length(p)))
    return new_ps
end

function to_text(pb::PartitionBlock)
    t = "$(length(pb))"
    return repeat(t * ", ", num_of_copies(pb)-1) * t
end

total_length(p::Partition) = sum(x->x[1]*x[2], p.p)
