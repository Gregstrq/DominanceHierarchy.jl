struct SignedPartitionBlock
    spb::Tuple{UInt8,Int8,UInt8}
end
SPB(m,s,p) = (@assert m>=0; @assert p>=0; SignedPartitionBlock((m,s,p)))
getindex(spb::SignedPartitionBlock, i) = spb.spb[i]
length(spb::SignedPartitionBlock) = spb[1]
num_of_copies(spb::SignedPartitionBlock) = spb[3]

isless(spb1::T, spb2::T) where {T<:SignedPartitionBlock} = spb1[1]<spb2[1] || (spb1[1]==spb2[1] && spb1[2]<spb2[2])
==(spb1::T, spb2::T) where {T<:SignedPartitionBlock} = spb1[1]==spb2[1] && spb1[2]==spb2[2]
isequal(spb1::T, spb2::T) where {T<:SignedPartitionBlock} = isequal(spb1.spb, spb2.spb)
hash(spb::SignedPartitionBlock) = hash(spb.spb)

decrement(spb::SignedPartitionBlock) = SPB(spb[1],spb[2],spb[3]-1)
increment(spb::SignedPartitionBlock) = SPB(spb[1],spb[2],spb[3]+1)
decrement2(spb::SignedPartitionBlock) = SPB(spb[1],spb[2],spb[3]-2)
change(spb::SignedPartitionBlock, n, s) = SPB(spb[1]+n, spb[2]*s,1)

struct SignedPartition <: AbstractPartition
    sp::Vector{SignedPartitionBlock}
    function SignedPartition(sp::Vector{SignedPartitionBlock})
        flag = false
        if length(sp)>1
            for i = 1:length(sp)-1
                if isequal(sp[i],sp[i+1])
                    flag = true
                    break
                end
            end
        end
        if flag
            error("Trying to construct not a valid SignedPartition out of $sp")
        end
        return new(sp)
    end
end
SignedPartition(p::Int, q::Int) = SignedPartition([SPB(1,1,p), SPB(1,-1,q)])
getindex(sp::SignedPartition, i) = sp.sp[i]
length(sp::SignedPartition) = length(sp.sp)

isequal(sp1::T, sp2::T) where T<:SignedPartition = isequal(sp1.sp, sp2.sp)
hash(sp::SignedPartition) = hash(sp.sp)

function compute_signature(spb::SignedPartitionBlock)
    q = Int(div(length(spb),2))
    p = q + Int(rem(length(spb),2))
    return (spb[2]==1 ? (p,q) : (q,p)) .* num_of_copies(spb)
end
function compute_signature(sp::SignedPartition)
    sig = (0,0)
    for i=1:length(sp)
        sig = sig .+ compute_signature(sp[i])
    end
    return sig
end

function mutations_I(spb1::T, spb2::T) where T<:SignedPartitionBlock
    @assert spb1>spb2
    if spb1[2]*spb2[2]>0
        return Vector{NTuple{4,SignedPartitionBlock}}()
    end
    if length(spb1)==length(spb2)
        return [(change(spb2, 1, -1), decrement(spb1), decrement(spb2),change(spb1,-1,-1)), (change(spb1, 1, -1), decrement(spb1), decrement(spb2), change(spb2,-1,-1))]
    else
        return [(change(spb1, 1, -1), decrement(spb1), decrement(spb2), change(spb2,-1,-1))]
    end
end
function mutations_II(spb1::T, spb2::T) where T<:SignedPartitionBlock
    @assert spb1>spb2
    if length(spb2)==1 || spb1[2]*spb2[2]<0
        return Vector{NTuple{4,SignedPartitionBlock}}()
    end
    return [(change(spb1,2,1), decrement(spb1), decrement(spb2), change(spb2,-2,1))]
end
function mutations_II(spb::SignedPartitionBlock)
    if length(spb)==1 || num_of_copies(spb)<2
        return Vector{NTuple{3,SignedPartitionBlock}}()
    else
        return [(change(spb, 2, 1), decrement2(spb), change(spb, -2, 1))]
    end
end
function mutations_III(spb1::T, spb2::T) where T<:SignedPartitionBlock
    if (mod(length(spb1)-length(spb2),2)==0 && spb1[2]*spb2[2]>0) || (mod(length(spb1)-length(spb2),2)!=0 && spb1[2]*spb2[2]<0)
        return Vector{NTuple{4,SignedPartitionBlock}}()
    end
    if length(spb1)==length(spb2)
        return [(change(spb1, 1, 1), decrement(spb1), decrement(spb2), change(spb2,-1,1)), (change(spb2, 1, 1), decrement(spb1), decrement(spb2), change(spb1,-1,1))]
    else
        return [(change(spb1, 1, 1), decrement(spb1), decrement(spb2), change(spb2,-1,1))]
    end
end
function mutations(spb1::T, spb2::T) where T<:SignedPartitionBlock
    S = OrderedSet(mutations_I(spb1, spb2))
    union!(S, mutations_II(spb1,spb2))
    union!(S, mutations_III(spb1,spb2))
    return S
end
mutations(spb::SignedPartitionBlock) = mutations_II(spb)

mutations(sp::SignedPartition, I::NTuple{2,Integer}) = mutations(sp[I[1]], sp[I[2]])
mutations(sp::SignedPartition, i::Integer) = mutations(sp[i])

function swap!(a::AbstractVector, i, j)
    temp = a[i]
    a[i] = a[j]
    a[j] = temp
    nothing
end

function move_left!(new_p, i₀)
    while i₀>1
        if new_p[i₀-1] < new_p[i₀]
            swap!(new_p, i₀-1, i₀)
        elseif new_p[i₀-1] == new_p[i₀]
            new_p[i₀-1] = increment(new_p[i₀-1])
            new_p[i₀] = decrement(new_p[i₀])
        else
            break
        end
        i₀ -= 1
    end
end

function move_right!(new_p, j₀)
    while j₀<length(new_p)
        if new_p[j₀+1]>new_p[j₀]
            swap!(new_p, j₀+1, j₀)
        elseif new_p[j₀+1] == new_p[j₀]
            new_p[j₀+1] = increment(new_p[j₀+1])
            new_p[j₀] = decrement(new_p[j₀])
        else
            break
        end
        j₀ += 1
    end
end

is_scippable(spb::SignedPartitionBlock) = spb[1]==0 || spb[3] == 0

function mutate_partition(sp::SignedPartition, I::NTuple{2,Integer}, mutation::NTuple{4,SignedPartitionBlock})
    i,j = I
    new_p = vcat(sp.sp[1:i-1], mutation[1:2]..., sp.sp[i+1:j-1], mutation[3:4]...,sp.sp[j+1:end])
    i₀ = i
    j₀ = j+2

    move_left!(new_p, i₀)
    move_right!(new_p, j₀)
    try
        return SignedPartition(filter(x->!is_scippable(x), new_p))
    catch e
        if isa(e, ErrorException)
            println("Error while mutating partition $sp with mutation $mutation at the index $I.")
        end
        rethrow(e)
    end
end

function mutate_partition(sp::SignedPartition, i::Integer, mutation::NTuple{3,SignedPartitionBlock})
    new_p = vcat(sp.sp[1:i-1], mutation..., sp.sp[i+1:end])
    i₀ = i
    j₀ = i+2

    move_left!(new_p, i₀)
    move_right!(new_p, j₀)
    try
        return SignedPartition(filter(x->!is_scippable(x), new_p))
    catch e
        if isa(e, ErrorException)
            println("Error while mutating partition $sp with mutation $mutation at the index $i.")
        end
        rethrow(e)
    end
end

function get_mutated_partitions(sp::SignedPartition, I)
    mts = mutations(sp, I)
    if isempty(mts)
        return Vector{SignedPartition}()
    end
    return [mutate_partition(sp, I, m) for m in mts]
end
function get_mutated_partitions(sp::SignedPartition)
    new_sps = Vector{SignedPartition}()

    for i=1:length(sp)-1
        for j=i+1:length(sp)
            append!(new_sps, get_mutated_partitions(sp, (i,j)))
        end
    end

    for i=1:length(sp)
        append!(new_sps, get_mutated_partitions(sp, i))
    end
    return new_sps
end

function to_text(spb::SignedPartitionBlock)
    t = "$(spb[1])$(spb[2]==1 ? "+" : "-")"
    return repeat(t*", ", spb[3]-1) * t
end
function to_text(p::AbstractPartition)
    output = "("
    output *= to_text(p[1])
    i = 2
    while i<=length(p)
        output *= ", "*to_text(p[i])
        i+=1
    end
    return output * ")"
end
