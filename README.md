# DominanceHierarchy.jl

Exceptional Points (EP) in non-Hermitian systems are in a one-to-one correspondence with the Young diagrams (which encode the sizes of the corresponding Jordan blocks in the Jordan normal form).
For the Young diagrams, one can define partial "dominance" order. If diagram A dominates diagram B, then type-B EP belongs to the closure of the manifold of type-A EPs.
Correspondingly, infinitesimal perturbation of type-B EP can create a type-A EP.

For pseudo-Hermitian systems, one associates EPs with signed Young diagrams. The "dominance" order can be defined for signed diagrams as well and analogously describes behaviour of the EP-manifolds under closure.

The package provides the means to construct the hierarchy of (signed) Young diagrams and plot the corresponding graph.



## Overview

```julia
build_hierarchy(n)
```
creates the hierarchy of Exceptional Points with algebraic multiplicity `n` in the non-symmetric case.
```
build_hierarchy(p, q)
```
creates the hierarchy of EPs with algebraic multiplicity `p+q` in the pseudo-Hermitian case. `(p, q)` is the inertia of the pseudo-metric operator.

```julia
plot_hierarchy(hierarchy; fname = default_name(hierarchy), dir=pwd())
```
plots the hierarchy using the tikz graph library and saves it into the file `"fname.pdf"` in the `dir` directory.
For simplicity, the (signed) Young diagrams are represented by listing the lengths of the Young diagram rows (and the signs) separated by commas.
Default name is `"hierarchy_n"` in the non-symmetric case and `"hierarchy_(p,q)"` in the case of the pseudo-Hermitian symmetry.

## Finer control

The layout of the plotted graph is determined automatically by the tikz graph library, which does not always lead to the optimal results.
Therefore we provide
```julia
plot_hierarchy(hierarchy; ordering=permutation_vector, labels=:default, fname = default_name(hierarchy), dir=pwd())
```
Under the hood, each vertex (Young diagram) of the hierarchy graph has an integer code, which is basically an ordinal number of the vertex in the order the vertices were added to the graph.
`ordering=permutation_vector` specifies the permutation vector of vertex codes. The vertices and edges are sent to tikz in the order determined by the `ordering` vector, which allows to influence the resulting layout.

To see the vertex codes in the plotted ".pdf" file, specify `labels=:Code`.
Correspondingly, `labels=:default` specifies the default text representation of (signed) Young diagrams.

## Manual output to tex for publication quality graphs.

To generate tikz graph in the publication quality, use
```julia
manual_output_to_tex(hierarchy, layout_dict; output_to_file = false, fname = default_name(hierarchy), dir=pwd())
```
This variant uses tikzcd library and allows to manually specify the layout of the plotted graph.
It also nicely plots the Young diagrams as Young diagrams and not as strings.
The vertices are arranged inside a regular matrix, the corresponding rows are computed automatically under the hood.
So one only needs to specify the horizontal coordinates of the vertices in the matrix,
which is done by specifying the layout dictionary of the form
```julia
layout_dict = Dict(code1=>horizontal_coord1, code2=>horizontal_coord2, ...)
```

By default, the function spews out the string with LaTeX code. If you capture the output `s` with `clipboard(s)` function, it will send the string to the clipboard, so that you can past the code into the LaTeX file.
Alternatively, one can specify `output_to_file=true` and save it into a ".tex" file, that can be then included explicitly in the main file.

## Internals
In the non-symmetric case, we define the `PartitionBlock` struct, which can be constructed as `PB(m, nc)`. It represents part of the Young diagram consisting of `nc` rows of the same length `m`.

In the symmetric case, we define `SignedPartitionBlock` struct. It is constructed via `SPB(m, s, nc)` and described the part of the signed Young diagram consisting of `nc` signed rows of the same length `m` and with the same sign `s`.

The type `Partition` (`SignedPartition`) is basically the vector of `PartitionBlock`-s (`SignedPartitionBlock`-s) ordered by decreasing `m` and by sign `s` (plus precedes minus). It represents the whole (signed) Young diagram.

One can also build the partial hierarchy consisting of the (signed) Young diagrams that dominate the given diagram:
```julia
build_hierarchy(starting_partition)
```
Actually, under the hood `build_hierarchy(n)` effectively calls `build_hierarchy(Partition([PB(1,n)]))`, while `build_hierarchy(p,q)` effectively calls `build_hierarchy(SignedPartition([SPB(1,1,p), SPB(1,-1,q)]))`.


