### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ e23ef752-f690-11ea-0c9d-8fed12d250ef
using YaoPlots, Compose

# ╔═╡ e87c192c-f65c-11ea-3fe0-6bfba4889a9c
using YaoLang

# ╔═╡ 62f8fea4-f669-11ea-14b7-e51902a1d601
using YaoLang: gate_count

# ╔═╡ 86c69f8a-f685-11ea-321f-652db926da56
using YaoArrayRegister

# ╔═╡ 4cf89e78-f68c-11ea-381f-c137ddaf4173
using ZXCalculus

# ╔═╡ 2f4ce866-f693-11ea-2c36-3d18c82d6d2a
begin
	using LightGraphs, Multigraphs
	g = Multigraph(6)
	add_edge!(g, 1, 3)
	add_edge!(g, 2, 4)
	add_edge!(g, 3, 4)
	add_edge!(g, 3, 5)
	add_edge!(g, 4, 6)
	ps = [0//1 for i = 1:6]
	v_t = [SpiderType.In, SpiderType.In, SpiderType.X, SpiderType.Z, SpiderType.Out, SpiderType.Out]
	zxd_from_multigraph = ZXDiagram(g, v_t, ps)
end

# ╔═╡ 680d83b4-f651-11ea-0a8f-f1b1d998ab14
html"<button onclick=present()>Present</button>"

# ╔═╡ c98641c8-f690-11ea-0fea-ad1506652181
function Base.show(io::IO, mime::MIME"text/html", zx::Union{ZXDiagram, ZXGraph})
	g = plot(zx; size_x=13, size_y = 3, NODELABELSIZE=8pt)
	Compose.set_default_graphic_size(18cm, 5cm)
	Base.show(io, mime, compose(context(0.0, 0.0, 1.0, 1.0), g))
end

# ╔═╡ 544442d2-f651-11ea-3b85-15a6e3555de9
md"# ZXCalculus.jl: ZX-calculus in Julia

[Chen Zhao](https://github.com/ChenZhao44)

*PhD student, Academy of Mathematics and System Science, Chinese Academy of Sciences*

This project is for GSoC 2020. 

Mentored by [Roger Luo](https://github.com/Roger-luo) and [Jinguo Liu](https://github.com/GiggleLiu).

[https://github.com/QuantumBFS/ZXCalculus.jl](https://github.com/QuantumBFS/ZXCalculus.jl)
"

# ╔═╡ 43c4f7e2-f655-11ea-062b-e3876cf5130a
md"# Table of contents
1. Yao.jl ecosystem

2. Using ZXCalculus.jl as a circuit optimizer
    - YaoLang.jl
    - Loading OpenQASM codes


3. Low-level Usages
    - Constructing ZX-diagrams manually
    - Rewriting ZX-diagrams by rules


4. Why ZXCalculus.jl?

"

# ╔═╡ 7d8587d0-fb2b-11ea-2028-6b18fbbc3289
md"# Yao.jl ecosystem
![](https://github.com/ChenZhao44/ZXCalculusTutorials/raw/zx-meeting/assets/yao-01.png)
"

# ╔═╡ 5376aa3e-fb2c-11ea-33ff-5b44901bb2d2
md"# Yao.jl ecosystem
![](https://github.com/ChenZhao44/ZXCalculusTutorials/raw/zx-meeting/assets/yao-02.png)
"

# ╔═╡ 5a8db2b2-fb2c-11ea-1200-8918b662a634
md"# Yao.jl ecosystem
![](https://github.com/ChenZhao44/ZXCalculusTutorials/raw/zx-meeting/assets/yao-03.png)
"

# ╔═╡ 5fe94f80-fb2c-11ea-1278-2591ddbf30cb
md"# Yao.jl ecosystem
![](https://github.com/ChenZhao44/ZXCalculusTutorials/raw/zx-meeting/assets/yao-04.png)
"

# ╔═╡ 8771dae0-fb2c-11ea-2619-73e18f7782ee
md"# Yao.jl ecosystem
# YaoLang.jl: a new quantum domain specific language
[YaoLang.jl](https://github.com/QuantumBFS/YaoLang.jl) is a DSL for compiling quantum programs in Julia. It extends Julia grammar, such that one can define hybrid quantum-classical programs in Julia conveniently.

![](https://github.com/ChenZhao44/ZXCalculusTutorials/raw/zx-meeting/assets/yao-05.png)
## 
![](https://github.com/QuantumBFS/YaoLang.jl/raw/master/demo.gif)
"

# ╔═╡ 0f7c4f36-f65c-11ea-2ad7-fd7a5e566701
md"# Using ZXCalculus.jl as a circuit optimizer



## YaoLang.jl
"

# ╔═╡ d3b4bffe-f65d-11ea-2fec-dbcc3902e14b
md"### The macro `@device`

In any function which is decorated by the macro @device, one can use the following codes to define quantum circuits.

- `j => U` apply gate `U` on the `j`-th qubit
- `@ctrl j k => U` apply controlled-`U` gate on the `j`-th qubit with the `k`-th qubit as the controlling qubit
"

# ╔═╡ 23b2fab2-f65d-11ea-0999-b7d4254cc58d
@device function demo_circ()
    4 => H
    1 => H
    1 => Tdag
    4 => T
    4 => Sdag
    4 => H
    4 => S
    3 => Sdag
    4 => S
    1 => T
    4 => H
    1 => Sdag
    2 => Tdag
    @ctrl 3 4 => Z
    @ctrl 4 3 => Z
    1 => H
    3 => H
    @ctrl 1 2 => Z
    1 => Sdag
    @ctrl 2 1 => X
end

# ╔═╡ 571ac9e2-f65e-11ea-18e2-330b2a225eb3
md"## 
### Calling the optimizer

ZXCalculus.jl is highly integrated with YaoLang.jl.

We can simply add an argument `optimizer = [opts...]` to call the backend circuit optimizer in ZXCalculus.jl. Currently, there are two optimizers supported.

- `:zx_teleport` for the phase teleportation algorithm
- `:zx_clifford` for Clifford simplification based on the circuit extraction algorithm
"

# ╔═╡ 7880d40a-f65e-11ea-213b-fd34d729d463
@device optimizer = [:zx_teleport] function demo_circ_simp()
    4 => H
    1 => H
    1 => Tdag
    4 => T
    4 => Sdag
    4 => H
    4 => S
    3 => Sdag
    4 => S
    1 => T
    4 => H
    1 => Sdag
    2 => Tdag
    @ctrl 3 4 => Z
    @ctrl 4 3 => Z
    1 => H
    3 => H
    @ctrl 1 2 => Z
    1 => Sdag
    @ctrl 2 1 => X
end

# ╔═╡ 442ba382-f65f-11ea-2a2c-af2d14b1628c
md"##
### Let's check out the result
"

# ╔═╡ 55f06efe-f65f-11ea-07ff-1bcd79e64f98
gate_count(demo_circ) # the original circuit with 20 gates

# ╔═╡ 6c47f848-f65f-11ea-326a-43df59adc005
gate_count(demo_circ_simp) # the simplified circuit with 14 gates

# ╔═╡ 3c6e209c-f683-11ea-3f77-d7648115b7da
md"##
### Test the equivalence of two circuits

YaoLang.jl can compile quantum programs to instructions that can be run on different devices. For example, we can use the quantum simulator [Yao.jl](https://github.com/QuantumBFS/Yao.jl) as the backend.
"

# ╔═╡ 13ada46e-f685-11ea-000d-65752cb70820
md"By using [YaoArrayRegister.jl](https://github.com/QuantumBFS/YaoArrayRegister.jl), we can define quantum registers and apply circuits on them.
"

# ╔═╡ 87dc8952-f669-11ea-2f79-21ce8984a7be
begin
	reg = rand_state(4)
	reg_simp = copy(reg)
	
	circ = demo_circ()
	circ_simp = demo_circ_simp()
	
	reg |> circ
	reg_simp |> circ_simp
end

# ╔═╡ 2314d8a2-f66a-11ea-3268-adaf5cfab183
md"Let's check whether these two states are equivalent.

We can use the `fidelity` function in YaoArrayRegister.jl to check that.
"

# ╔═╡ ac124442-f669-11ea-3364-69954cf06d85
fidelity(reg, reg_simp) ≈ 1

# ╔═╡ b4c228ba-f686-11ea-3b50-3f94e666c971
md"# Loading OpenQASM codes

### The landscape of YaoLang.jl

In YaoLang.jl, quantum programs are represented in SSA (static single assignment) form intermidiate representation called **YaoIR**.
![YaoLang.jl-compilation](https://github.com/ChenZhao44/ChenZhao44.github.io/raw/master/assets/blog_res/ZX/Quantum_Compiling.png)
ZXCalculus.jl are integrated by defining the conversion between ZX-diagrams and YaoIRs. 

OpenQASM codes can be parsed to YaoIRs. Hence, we can load quantum circuits to ZXCalculus.jl from OpenQASM codes via YaoLang.jl.
"

# ╔═╡ 1bc14166-f68b-11ea-00eb-bf2eb3060b3c
md"## The API for loading ZX-diagram from QASM"

# ╔═╡ dbfbf7c6-f68b-11ea-085f-bda481d8a15d
md"We first load QASM codes from a file.
"

# ╔═╡ 4cf932b8-f68c-11ea-3d19-bfb0dbbfdb97
lines = readlines("assets/gf2^8_mult.qasm");

# ╔═╡ 6888138c-f68c-11ea-3b6b-af49a33c7ea5
src = prod(lines);

# ╔═╡ e1348176-f68c-11ea-2f3a-115392f5a331
md"Then we can simply use the constructor to construct a ZX-diagram directly.
"

# ╔═╡ b0f5718c-f68c-11ea-392d-5159abc3aca2
zxd_qasm = ZXDiagram(src, Val(:qasm));

# ╔═╡ 1b01c04e-f68d-11ea-0a4d-951675049aee
md"##
Now, we can simplify this ZX-diagram by using circuit simplification algorithms in ZXCalculus.jl.

- `phase_teleportation(zxd)` for the phase teleportation algorithm
- `clifford_simplification(zxd)` for Clifford simplification based on the circuit extraction algorithm

We use the phase teleportation algorithm in this example.
"

# ╔═╡ ba299942-f68c-11ea-38dc-9512204ffb06
pt_zxd_qasm = phase_teleportation(zxd_qasm);

# ╔═╡ 858cff46-f68d-11ea-1396-afaeba9a3020
md"Let's check out the change of T-counts.
"

# ╔═╡ c831dad0-f68d-11ea-3c69-af25f6ffbab7
tcount(zxd_qasm)

# ╔═╡ cef48b18-f68d-11ea-1257-a396b43179cd
tcount(pt_zxd_qasm)

# ╔═╡ d29d0f96-f68e-11ea-16d1-156555f74682
md"By now, we have showed how to use ZXCalculus.jl as a circuit simplification engine. It's time to open the black box to see how it works.
"

# ╔═╡ 3edb6b80-f68f-11ea-1871-b5010acd026c
md"# More details about ZXCalculus.jl

### ZXDiagram

In ZXCalculus.jl, general ZX-diagrams are stored in the data structure `ZXDiagram`. The graphical backend of `ZXDiagram` is the multigraph. 

We implemented a Julia multigraph library Multigraphs.jl base on APIs of LightGraphs.jl.
"

# ╔═╡ 3298fd08-f692-11ea-1393-1960d8f41cf4
md"## Constructing ZXDiagram

One can construct a ZXDiagram from a multigraph and some extra information.
"

# ╔═╡ f3dbf0dc-f693-11ea-0faa-1144010a3d0b
md"It will be extremely complicated when constructing large ZX-diagrams.
"

# ╔═╡ 1ff8b214-f693-11ea-002b-e3baabfe890f
md"## Constructing ZX-diagrams from quantum circuits

It is more recommanded to construct `ZXDiagram`s from quantum circuits. In ZXCalculus.jl, QCircuit is a data structure for representing quantum circuit.
"

# ╔═╡ 4d0334a4-f694-11ea-15df-2b0603b89f46
qc = QCircuit(2)

# ╔═╡ 67d1019e-f694-11ea-2e85-851c7c3e1059
begin
	push_gate!(qc, Val(:H), 1)
	push_gate!(qc, Val(:S), 1)
	push_gate!(qc, Val(:Tdag), 2)
	push_gate!(qc, Val(:CNOT), 2, 1)
	push_gate!(qc, Val(:CZ), 1, 2)
end

# ╔═╡ f13d3740-f694-11ea-1bf0-f189d2348e2e
md"Here we constructed a empty quantum circuit and then pushed 5 gates to it.
"

# ╔═╡ 339a6054-f695-11ea-092d-3931f9401765
md"##

Also we can generate a random circuit as an example.
"

# ╔═╡ 99191fec-f695-11ea-2525-895bc24f262b
qc_rand = random_circuit(4, 40); # generate a 4 qubit circuit with 40 gates

# ╔═╡ cc6b8ed4-f695-11ea-27d7-7b7c9e38923c
md"Let's convert it to a ZX-diagram.
"

# ╔═╡ c8c6483c-f695-11ea-1e86-67731b5a5e56
zxd_rand = ZXDiagram(qc_rand)

# ╔═╡ 56aa70c2-f698-11ea-2295-55f41a6085a9
md"## Simplifying ZX-diagrams
Now we can rewrite the ZX-diagram with rules.

One can use
```julia
	match(r, zxd)
```
to match all available vertices in a ZX-diagram for a rule. And use 
```julia
	rewrite!(r, zxd, matches)
```
to rewrite the ZX-diagram on matched vertices.

More simply, we can just use 
```julia
	replace!(r, zxd)
```
to do the above steps once or use  
```julia
	simplify!(r, zxd)
``` to rewrite recursively.
"

# ╔═╡ f6e37cb4-f75b-11ea-1126-5b22e87e103a
md"## Rules for the ZXDiagram
There are 7 rules available for `ZXDiagram`.
![](https://chenzhao44.github.io/assets/blog_res/ZX/rules.png)
"

# ╔═╡ 8af02a0a-f69a-11ea-37b7-5ba38ed14872
md"## Example
"

# ╔═╡ 7b579c50-f699-11ea-014b-f1eb7899b422
begin
	zxd_rand2 = copy(zxd_rand)
	simplify!(Rule{:h}(), zxd_rand2)	
	simplify!(Rule{:i1}(), zxd_rand2)
	simplify!(Rule{:i2}(), zxd_rand2)
end

# ╔═╡ a5c7881e-f69a-11ea-1349-2f436213c71f
md"Here we used the rule $i_1$, $i_2$, and $h$.
"

# ╔═╡ d9e4dc28-f69a-11ea-277a-d78dbc790dcc
md"## Graph-like ZX-diagrams

There is a special kind of ZX-diagram called the *graph-like ZX-diagram*, which is firstly introduced in [this paper](https://arxiv.org/abs/1902.03178). The graph-like ZX-diagram is very useful in many circuit simplification algorithms. 

In ZXCalculus.jl, we use the data structure `ZXGraph` to represent it. One can simply convert a `ZXDiagram` to a `ZXGraph` with the constructor
```julia
ZXGraph(zxd)
```
"

# ╔═╡ e5282e0e-f696-11ea-3518-cd0cf45d1b63
zxg_rand = ZXGraph(zxd_rand)

# ╔═╡ c83a5ad8-f69b-11ea-3d00-e3348ff46b2b
md"## Rules for ZXGraph

There are 7 rules available for `ZXGraph`: 

![](https://chenzhao44.github.io/assets/blog_res/ZX/zxgraph-rules.png)
"

# ╔═╡ 56d61204-f69d-11ea-08da-e7ec818b8cb0
md"## Example

We simplify this graph-like ZX-diagram with the rule `lc`, `p1`, and `pab`.
"

# ╔═╡ 442f7994-f696-11ea-0eed-dbe8c71ef719
begin
	simplify!(Rule{:lc}(), zxg_rand)
	simplify!(Rule{:p1}(), zxg_rand)
	replace!(Rule{:pab}(), zxg_rand)
end

# ╔═╡ be1a716c-f69d-11ea-2527-97802fc99667
md"Then we extract a new circuit from the simplified ZX-diagram.
"

# ╔═╡ 8c8de7ba-f697-11ea-0c9c-35325b89509b
ex_zxd_rand = circuit_extraction(zxg_rand)

# ╔═╡ b986fe5a-f697-11ea-18d1-f77ad5475f32
QCircuit(ex_zxd_rand)

# ╔═╡ e48652ee-f69d-11ea-0137-ef0e5c1913f8
md"## Two circuit simplification algorithms

```julia
	phase_teleportation(zxd)
``` 
```julia
	clifford_simplification(zxd)
```

These algorithms are assembled by the above rules.
"

# ╔═╡ 78987568-f69c-11ea-3c8a-c79b49fd5a41
clifford_simplification(phase_teleportation(zxd_rand))

# ╔═╡ 70f5b6ea-f755-11ea-3455-a3d4612134ea
md"# Visualization for ZXCalculus.jl

Visualization tools are in the package **YaoPlots.jl**. If you want to draw a diagram for a ZXDiagram or a ZXGraph. Just use the following codes.
```julia
using YaoPlots
zxd = ...
plot(zxd)
```
"

# ╔═╡ f263ae12-f755-11ea-009e-314cfa1f0cd2
plot(ZXDiagram(random_circuit(4, 10)))

# ╔═╡ ffbdbc28-f756-11ea-0259-df5c14ef457a
md"# Why ZXCalculus.jl?
The above algorithms are first implemented in a Python package [PyZX](https://github.com/Quantomatic/pyzx), a full-featured library for manipulating large-scale quantum circuits and ZX-diagrams. It provides many amazing features of visualization and supports different forms of quantum circuits including QASM, Quipper, and Quantomatic.

### Reasons
- We need a light-weighted circuit simplification engine for YaoLang.jl
- Julia is fast
"

# ╔═╡ 54c39576-f757-11ea-3cdf-918909c07eb0
md"## Benchmarks
We tested the phase teleportation algorithm on 40 circuits with ZXCalculus.jl and PyZX. The benchmark results shown that ZXCalculus.jl has 8x-45x speed-up.
![benchmarks](https://chenzhao44.github.io/assets/blog_res/ZX/benchmarks.png)
"

# ╔═╡ b2f69788-f75c-11ea-19fa-779a7b57845d
md"# Thank you!
"

# ╔═╡ Cell order:
# ╟─680d83b4-f651-11ea-0a8f-f1b1d998ab14
# ╟─e23ef752-f690-11ea-0c9d-8fed12d250ef
# ╟─c98641c8-f690-11ea-0fea-ad1506652181
# ╟─544442d2-f651-11ea-3b85-15a6e3555de9
# ╟─43c4f7e2-f655-11ea-062b-e3876cf5130a
# ╟─7d8587d0-fb2b-11ea-2028-6b18fbbc3289
# ╟─5376aa3e-fb2c-11ea-33ff-5b44901bb2d2
# ╟─5a8db2b2-fb2c-11ea-1200-8918b662a634
# ╠═5fe94f80-fb2c-11ea-1278-2591ddbf30cb
# ╠═8771dae0-fb2c-11ea-2619-73e18f7782ee
# ╟─0f7c4f36-f65c-11ea-2ad7-fd7a5e566701
# ╠═e87c192c-f65c-11ea-3fe0-6bfba4889a9c
# ╟─d3b4bffe-f65d-11ea-2fec-dbcc3902e14b
# ╠═23b2fab2-f65d-11ea-0999-b7d4254cc58d
# ╟─571ac9e2-f65e-11ea-18e2-330b2a225eb3
# ╠═7880d40a-f65e-11ea-213b-fd34d729d463
# ╟─442ba382-f65f-11ea-2a2c-af2d14b1628c
# ╠═62f8fea4-f669-11ea-14b7-e51902a1d601
# ╠═55f06efe-f65f-11ea-07ff-1bcd79e64f98
# ╠═6c47f848-f65f-11ea-326a-43df59adc005
# ╟─3c6e209c-f683-11ea-3f77-d7648115b7da
# ╟─13ada46e-f685-11ea-000d-65752cb70820
# ╠═86c69f8a-f685-11ea-321f-652db926da56
# ╠═87dc8952-f669-11ea-2f79-21ce8984a7be
# ╟─2314d8a2-f66a-11ea-3268-adaf5cfab183
# ╠═ac124442-f669-11ea-3364-69954cf06d85
# ╟─b4c228ba-f686-11ea-3b50-3f94e666c971
# ╟─1bc14166-f68b-11ea-00eb-bf2eb3060b3c
# ╟─dbfbf7c6-f68b-11ea-085f-bda481d8a15d
# ╠═4cf932b8-f68c-11ea-3d19-bfb0dbbfdb97
# ╠═6888138c-f68c-11ea-3b6b-af49a33c7ea5
# ╟─e1348176-f68c-11ea-2f3a-115392f5a331
# ╠═4cf89e78-f68c-11ea-381f-c137ddaf4173
# ╠═b0f5718c-f68c-11ea-392d-5159abc3aca2
# ╟─1b01c04e-f68d-11ea-0a4d-951675049aee
# ╠═ba299942-f68c-11ea-38dc-9512204ffb06
# ╟─858cff46-f68d-11ea-1396-afaeba9a3020
# ╠═c831dad0-f68d-11ea-3c69-af25f6ffbab7
# ╠═cef48b18-f68d-11ea-1257-a396b43179cd
# ╟─d29d0f96-f68e-11ea-16d1-156555f74682
# ╟─3edb6b80-f68f-11ea-1871-b5010acd026c
# ╟─3298fd08-f692-11ea-1393-1960d8f41cf4
# ╠═2f4ce866-f693-11ea-2c36-3d18c82d6d2a
# ╟─f3dbf0dc-f693-11ea-0faa-1144010a3d0b
# ╟─1ff8b214-f693-11ea-002b-e3baabfe890f
# ╠═4d0334a4-f694-11ea-15df-2b0603b89f46
# ╠═67d1019e-f694-11ea-2e85-851c7c3e1059
# ╟─f13d3740-f694-11ea-1bf0-f189d2348e2e
# ╟─339a6054-f695-11ea-092d-3931f9401765
# ╠═99191fec-f695-11ea-2525-895bc24f262b
# ╟─cc6b8ed4-f695-11ea-27d7-7b7c9e38923c
# ╠═c8c6483c-f695-11ea-1e86-67731b5a5e56
# ╟─56aa70c2-f698-11ea-2295-55f41a6085a9
# ╟─f6e37cb4-f75b-11ea-1126-5b22e87e103a
# ╟─8af02a0a-f69a-11ea-37b7-5ba38ed14872
# ╠═7b579c50-f699-11ea-014b-f1eb7899b422
# ╟─a5c7881e-f69a-11ea-1349-2f436213c71f
# ╟─d9e4dc28-f69a-11ea-277a-d78dbc790dcc
# ╠═e5282e0e-f696-11ea-3518-cd0cf45d1b63
# ╟─c83a5ad8-f69b-11ea-3d00-e3348ff46b2b
# ╟─56d61204-f69d-11ea-08da-e7ec818b8cb0
# ╠═442f7994-f696-11ea-0eed-dbe8c71ef719
# ╟─be1a716c-f69d-11ea-2527-97802fc99667
# ╠═8c8de7ba-f697-11ea-0c9c-35325b89509b
# ╠═b986fe5a-f697-11ea-18d1-f77ad5475f32
# ╟─e48652ee-f69d-11ea-0137-ef0e5c1913f8
# ╠═78987568-f69c-11ea-3c8a-c79b49fd5a41
# ╟─70f5b6ea-f755-11ea-3455-a3d4612134ea
# ╠═f263ae12-f755-11ea-009e-314cfa1f0cd2
# ╟─ffbdbc28-f756-11ea-0259-df5c14ef457a
# ╟─54c39576-f757-11ea-3cdf-918909c07eb0
# ╟─b2f69788-f75c-11ea-19fa-779a7b57845d
