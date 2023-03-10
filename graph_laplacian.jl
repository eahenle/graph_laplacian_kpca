### A Pluto.jl notebook ###
# v0.19.20

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 499fa1fa-95d9-11ed-30ff-2b7a001a43ae
begin
	using CairoMakie, GraphMakie, PlutoTest, PlutoUI, ShortCodes
	using Graphs, SparseArrays, LinearAlgebra
	import ForwardDiff.gradient
	TableOfContents(title="")
end

# ╔═╡ d22f6168-cd5a-4e78-bb78-9d85281528b0
md"""
!!! ok "Shout-Out to Gilbert Strang"
	This video (MIT open courseware) heavily influenced this notebook's content and structure.
"""

# ╔═╡ 2915ef04-6b31-44a8-a31a-3a24608939be
YouTube("cxTmmasBiC8")

# ╔═╡ 5428e4c4-f59c-44fd-b405-52a5e2eb2e50
md"""
# Graph Matrices
"""

# ╔═╡ e8441276-2be8-4dae-bfe3-beda768deab6
md"""
Consider an undirected simple graph ``G``:
"""

# ╔═╡ a6401037-5c6a-4e9b-aaeb-7eaf25f2bae0
G = begin
	local graph = SimpleGraph(4)
	add_edge!(graph, 1, 2)
	add_edge!(graph, 1, 3)
	add_edge!(graph, 1, 4)
	add_edge!(graph, 2, 3)
	add_edge!(graph, 2, 4)
	graph
end

# ╔═╡ 4d46de85-6759-4233-a16f-109f63cd149a
begin
	graphplot_ax_kwargs = [
		:xgridvisible => false
		:xticksvisible => false
		:xticklabelsvisible => false
		:ygridvisible => false
		:yticksvisible => false
		:yticklabelsvisible => false
		:spinewidth => 0
		:aspect => DataAspect()
	]
	local fig = Figure()
	local ax = Axis(
		fig[1, 1];
		graphplot_ax_kwargs...
	)
	graphplot!(
		ax,
		G;
		nlabels=["$i" for i in 1:nv(G)],
		elabels=["$i" for i in 1:ne(G)],
		layout=GraphMakie.Spectral()
	)
	fig
end

# ╔═╡ 2837816a-7438-4aa9-ae8e-748f59fb27d0
md"""
## Adjacency Matrix
"""

# ╔═╡ 94c69584-7fa1-450c-9ac7-941c4e17b0dc
md"""
The adjacency matrix ``A`` of simple graph ``G`` is a positive semidefinite matrix with elements ``A_{ij}`` denoting whether the ``i``th and ``j``th nodes in ``G`` are connected by an edge ``e_{ij}``:

$$A_{ij}=\begin{cases}1, & e_{ij}\in\mathcal{E}(G) \\ 0 &\end{cases}$$

For a simple undirected graph, the diagonal will be zeros (no self-loops) and the matrix will be symmetric (undirected edges).
"""

# ╔═╡ a042b3c6-f28d-49e9-ad9b-6f3c1c23db1a
A = adjacency_matrix(G)

# ╔═╡ de7475f9-a94a-4fa7-9ae4-0610bbe96da7
md"""
!!! note
	`Graphs.jl` uses sparse matrices, so ``0`` entries are shown as ``\cdot``
"""

# ╔═╡ b0182d38-49af-49d4-874e-1a3536d168a7
md"""
## Degree Matrix
"""

# ╔═╡ fe1f6716-9586-4b69-abb6-1ffae12257f7
md"""
The degree matrix ``D`` of graph ``G`` is a diagonal positive semidefinite matrix containing the degree (edge count) of each node.

$$D_{ij}=\begin{cases}\text{deg}(v_i),&i=j\\0\end{cases}$$
"""

# ╔═╡ aa2705f0-e03a-4583-a71d-ccc8c8fcc556
function degree_matrix(G::AbstractGraph)
	D = spzeros(Int, nv(G), nv(G))
	for (d, deg) in enumerate(degree(G))
		D[d, d] = deg
	end
	return D
end

# ╔═╡ 323a4dc0-b689-44c5-b1ad-ec68ffd3a1f0
D = degree_matrix(G)

# ╔═╡ 78e54473-42d5-47ca-95d2-3a34858b0f5c
md"""
## Incidence Matrix
"""

# ╔═╡ 968ff5dc-9c3e-44aa-afdd-644a24c9acee
md"""
The incidence matrix ``B`` of simple graph ``G`` is a rectangular matrix with number of rows equal to the number of nodes, and number of columns equal to the number of edges, having elements denoting whether a given edge is incoming or outgoing at each node (for a directed graph).  In the case of an undirected graph, the incidence matrix elements may be strictly non-negative, or a sign convention may be applied.

$$B=\begin{bmatrix}
	b_{11} & \cdots & b_{1m} \\
	\vdots & \ddots & \vdots \\
	b_{n1} & \cdots & b_{nm}
\end{bmatrix}
: m=|\mathcal{E}(G)| \wedge n=|\mathcal{V}(G)|$$

$$b_{ij}=\begin{cases}
	1, & i=\max\mathcal{V}(e_{j}) \\
	-1, & i=\min\mathcal{V}(e_{j}) \\
	0
\end{cases}$$
"""

# ╔═╡ 88302a0f-52cd-4af7-8cba-3faa95a168fe
B = incidence_matrix(G; oriented=true)

# ╔═╡ 1ce279b0-7670-4fa0-a868-d9750463d54d
md"""
!!! note
	1. This is the transpose of the matrix as defined in Gilbert Strang's lectures.
	1. On undirected graphs, the sign of the elements is arbitrary, *BUT* must be chosen consistently.
"""

# ╔═╡ 60a6bebf-ba80-4ec5-92f6-d2133c52f163
md"""
We will use the convention that `Graphs.jl` uses: undirected edges are considered as though they are directed from the lower-index node to the higher-index node.
"""

# ╔═╡ b78de7d4-0673-496b-8392-0c776b8e13a4
md"""
# Laplacian Matrix
"""

# ╔═╡ 7e212751-c446-43fe-bce9-98b11f064eff
md"""
The (positive semi-definite) graph Laplacian matrix ``L`` is computed as:

$$L=BB^T=D-A$$
"""

# ╔═╡ 5f794783-ee69-4fba-bebc-eafe340f8dea
md"""
!!! note
	Strang defines ``L=B^TB``, because his ``B`` is the transpose of ours.
"""

# ╔═╡ 9a7beb41-2b76-4b28-9f80-458e77f4d8f6
L = laplacian_matrix(G)

# ╔═╡ 7e1dc7f3-f95e-45e6-8352-17c9c988aa57
@test L == B * B'

# ╔═╡ 5f68596a-70c3-4af7-9170-9459ae7146fe
@test L == D - A

# ╔═╡ a1c5c766-6ae7-40f9-8cc1-99892273ea31
md"""
Because ``G`` is a simple graph (no self-loops) ``L`` contains the node degrees along the diagonal and the adjacency information (as ``0/-1`` Booleans) in the upper and lower triangles; and because ``G`` is undirected, ``L`` is symmetric.
"""

# ╔═╡ 524dda81-be87-46ef-9e7f-e599286d9d09
md"""
## The Laplacian Operator
"""

# ╔═╡ 550e6cc9-ba15-475b-a30d-3959e3f36d25
md"""
There is an operator known as the Laplacian, denoted ``\nabla\cdot\nabla``, ``\nabla^2``, or ``\Delta``, defined as:

$$\Delta(f(\vec{x}))=\text{divergence}(\text{gradient}(f(\vec{x})))$$

(Note that both divergence and gradient use the ``\nabla`` symbol, hence the ``\nabla\cdot\nabla`` and ``\nabla^2`` notation.)

The Laplacian of a function operating on a vector in a plane (``f(\vec{x})``) is intuitive enough to visualize as follows.  Let ``f(\vec{x})`` be defined as:

$$f(x, y) = \frac{-1}{2\sqrt{2\pi}}\left(e^{-\frac{1}{2}x^2}+e^{-\frac{1}{2}y^2}\right)$$
"""

# ╔═╡ e91a191f-afd4-4d53-8a97-02bff4968883
begin
	f(x, y; σ) = -(exp(-(x/2σ)^2) + exp(-(y/2σ)^2)) / (2σ√(2π))
	f(v; kwargs...) = f(v...; kwargs...)
end

# ╔═╡ e6b8f814-e82f-4ab8-8888-f5ab110ccc1d
md"""
Let's set ``\sigma=0.1`` and visualize ``f(x, y)`` over ``4`` square units of the ``xy`` plane.
"""

# ╔═╡ 3fb0d9c5-6605-47cc-a927-9be7a727d983
begin
	xy_range = -1.:0.001:1.
	σ = 0.1
end;

# ╔═╡ 72054f47-2f63-435f-a424-f6ea72023ef7
F = begin
	F = zeros(length(xy_range), length(xy_range))
	for j in axes(F, 2)
		for i in axes(F, 1)
			F[i, j] = f(xy_range[i], xy_range[j]; σ=σ)
		end
	end
	F
end;

# ╔═╡ e409c8d9-d4a9-4eea-b447-187f7b72313e
md"""
Visualization:
"""

# ╔═╡ e48e4b33-085e-48a6-9dc3-13a7aa159f02
scatter(xy_range, xy_range, F; color=F[:])

# ╔═╡ 8a86969b-65b5-4aec-a1a0-cd948920a62b
md"""
Gradient (direction of steepest ascent):
"""

# ╔═╡ 44bb41d3-4ae6-4ea5-988e-ff53625d12b7
∇f = begin
	∇f = zeros(length(xy_range), length(xy_range), 2)
	for j in axes(∇f, 2)
		for i in axes(∇f, 1)
			∇f[i, j, :] = gradient(v -> f(v; σ=σ), [xy_range[i], xy_range[j]])
		end
	end
	∇f
end;

# ╔═╡ 2be9e231-fe98-408f-8207-df2ce8a29d62
md"""
Divergence of gradient (Laplacian):
"""

# ╔═╡ 1c8cafd9-bec3-4dea-8c94-bcbb5d5f7bb3
Δf = begin
	Δf = zeros(size(∇f)[1:2])
	for j in axes(Δf, 2)
		for i in axes(Δf, 1)
			gx = gradient(
				v -> gradient(v -> f(v; σ=σ), v)[1],
				[xy_range[i], xy_range[j]]
			)[1]
			gy = gradient(
				v -> gradient(v -> f(v; σ=σ), v)[2],
				[xy_range[i], xy_range[j]]
			)[2]
			Δf[i, j] = gx + gy
		end
	end
	Δf
end;

# ╔═╡ c82c188e-0d63-4042-b8b6-1ad2494482df
begin
	local fig = Figure()

	# gradient vectors (sample) plotted over f(x, y) heatmap
	local ax = Axis(fig[1, 1]; aspect=DataAspect(), title="Gradient over Heatmap")
	local hm1 = heatmap!(ax, xy_range, xy_range, F)
	for j in axes(∇f, 2)
		for i in axes(∇f, 1)
			if i % 500 == j % 500 == 0
				x = xy_range[i]
				y = xy_range[j]
				u, v = ∇f[i, j, :]
				arrows!(ax, [x-0.25], [y-0.25], [u], [v]) ##! wtf offset...
			end
		end
	end

	Colorbar(fig[1, 2], hm1)

	# divergence of gradient
	local hm2 = heatmap!(
		Axis(fig[2, 1]; aspect=DataAspect(), title="Laplacian"), 
		xy_range,
		xy_range,
		Δf;
		colormap=:cool
	)

	Colorbar(fig[2, 2], hm2)
	
	fig
end

# ╔═╡ 2ab71373-61bb-4324-bca2-2b8d691ee839
md"""
## Connection to the Graph Laplacian
"""

# ╔═╡ bc25a4cc-8f4a-40c3-afe8-30e81759cf22
md"""
!!! ok "Major Concept"
	A 2D grid is a graph!
"""

# ╔═╡ dd8cab9c-6690-457f-8833-43b7f7cfdfba
begin
	xy_range2 = -1:0.5:1
	grid_5x5 = grid((length(xy_range2), length(xy_range2)))
end

# ╔═╡ ae8979ee-fd6e-4d55-9c18-062c3a6baa8e
begin
	local fig = Figure()
	graphplot!(
		Axis(fig[1, 1]; title="2D Grid", graphplot_ax_kwargs...),
		grid_5x5;
		layout=GraphMakie.SquareGrid()
	)
	fig
end

# ╔═╡ 5d30b1c6-3097-483a-a980-a43ae9251821
md"""
Calculate the Laplacian matrix ``\Delta`` from the grid graph; the product of the discrete Laplacian matrix and vector ``f_\phi``; and the product of the Laplacian matrix and vector ``f_\phi``:
"""

# ╔═╡ c76da5f8-89e7-47d4-947b-51fd99353d3c
begin
	# graph Laplacian
	Δ = laplacian_matrix(grid_5x5)
	# grid values from function f
	fϕ = [f(i, j; σ=σ) for i in -1:0.5:1 for j in -1:0.5:1]
	# discrete Laplacian product with fϕ
	dΔfϕ = [
		sum(abs(fϕ[v] - fϕ[w]) for w in neighbors(grid_5x5, v)) 
		for v in vertices(grid_5x5)
	]
	# graph Laplacian product with fϕ
	Δfϕ = -Δ * fϕ
end;

# ╔═╡ 3fef1ca6-6bf8-437c-88ec-1f482201fbba
begin
	local fig = Figure()

	graphplot!(
		Axis(fig[1, 2]; title="Graph Laplacian Product", graphplot_ax_kwargs...), 
		grid_5x5; 
		layout=GraphMakie.SquareGrid(),
		node_color=Δfϕ
	)

	graphplot!(
		Axis(fig[1, 1]; title="Discrete Laplacian Product", graphplot_ax_kwargs...), 
		grid_5x5; 
		layout=GraphMakie.SquareGrid(),
		node_color=dΔfϕ
	)
	
	fig
end

# ╔═╡ 698d5930-8bda-423a-aefb-12dbb5fa81c2
md"""
!!! ok "The Point:"
	The product of the discrete Laplacian with the vertex value column vector is approximately the product of the graph Laplacian with the vertex value column vector.

	I.e., the graph Laplacian is approximately the discrete Laplacian over the grid!
"""

# ╔═╡ b563f867-15b2-44e7-b69b-d015cfe9e5d6
md"""
## Clustering
"""

# ╔═╡ 796b5768-8876-44ab-a52c-79b280de28c5
md"""
Back to considering ``G``!
"""

# ╔═╡ 454027e3-4733-40ec-8ae0-4b18d5386cb3
begin
	local fig = Figure()
	local ax = Axis(
		fig[1, 1];
		graphplot_ax_kwargs...
	)
	graphplot!(
		ax,
		G
	)
	fig
end

# ╔═╡ 7b15c2e0-eb73-4fe0-b692-688e1a56c17f
md"""
### Eigendecomposition
"""

# ╔═╡ 962db6c6-9453-4b9a-b3f0-301a01cec327
md"""
`LinearAlgebra.eigen` calculates the eigendecomposition of a matrix:
"""

# ╔═╡ f95cee56-df99-4a4f-8e80-515cc1c7df50
eigen(Matrix(L))

# ╔═╡ a847dd0a-ed33-4a3d-95a3-b2b7cc93af79
md"""
!!! note
	`LinearAlegra.jl` doesn't work on sparse matrices, and will return eigenrelations with ``\lambda=0``
"""

# ╔═╡ c2e6f122-7835-43da-a5e3-81b629809863
md"""
The first eigenvector of ``L`` is in the null space; i.e. it has eigenvalue ``\lambda_1=0`` and is of the form ``\phi_1=c\hat{1}``.  This is not useful.
"""

# ╔═╡ 72785005-3956-4737-93e8-cf24de1f5154
λ, ψ = eigen(Matrix(L));

# ╔═╡ 39cdbeb9-270f-4b53-9920-c1404d17a5b9
λ # eigenvalues

# ╔═╡ ef9ec87b-2b40-41e4-8045-9f7da7ad19b6
ψ # eigenvectors (columns)

# ╔═╡ 26f0c057-5748-4627-ae6e-0712a31fb8df
md"""
The Fiedler vector ``\psi_2`` (Strang's ``x_2``) is the column of ``\psi`` corresponding to the lowest non-zero value in ``\lambda``.
"""

# ╔═╡ 0c231f7f-d7c7-4e1f-bb1f-e15989d4d702
ψ₂ = ψ[:, sortperm(λ)[2]]

# ╔═╡ 5c23dcd9-9486-4b35-bfcd-6404203d0f27
md"""
### Example 1
"""

# ╔═╡ eebb5288-5c64-4148-82ce-e048c259dd42
md"""
Coloring the nodes by their corresponding weights in the Fiedler vector shows a clustering!
"""

# ╔═╡ 2e9e0659-7544-4445-a6a7-317497fa0574
begin
	local fig = Figure()
	graphplot!(
		Axis(fig[1, 1]; graphplot_ax_kwargs...),
		G; 
		node_color=ψ₂
	)
	fig
end

# ╔═╡ 520ff1c1-5d40-42af-a4cc-8b27663383f7
md"""
### Example 2
"""

# ╔═╡ ad71e4ab-c1a1-4e96-be04-6505eb5e76c7
md"""
Let's try a more complex graph:
"""

# ╔═╡ 62b45813-ffd9-440b-bf04-b6e1dceca140
H = begin
	H = reduce(
		blockdiag,
		[
			join(SimpleGraph(2), cycle_graph(6)), # 1-8
			join(star_graph(5), path_graph(2)), # 9 - 15
			join(star_graph(5), path_graph(2)) # 16+
		]
	)
	add_edge!(H, 8, 9)
	add_edge!(H, 15, 16)
	add_edge!(H, 1, 17)
	H
end

# ╔═╡ 4d11e228-6082-4a19-bbd9-b50c97ec328b
begin
	local fig = Figure()
	graphplot!(
		Axis(fig[1, 1]; graphplot_ax_kwargs...),
		H
	)
	fig
end

# ╔═╡ 1398722a-2ce7-437e-b67e-83779fec0639
md"""
Eigendecompose the graph Laplacian:
"""

# ╔═╡ ecc9d934-ddb0-4310-a52d-9f919f1c7455
begin
	lambda, psi = eigen(Matrix(laplacian_matrix(H)))
	psi2 = psi[:, sortperm(lambda)[2]]
end;

# ╔═╡ e91440c2-f2c7-4067-aa9c-a369b18cb229
md"""
Color the nodes by the sign of ``\psi_{2i}``:
"""

# ╔═╡ 6141cb44-e94e-488f-9133-0f09e13a0a67
begin
	local fig = Figure()
	graphplot!(
		Axis(fig[1, 1]; graphplot_ax_kwargs...),
		H; 
		node_color=sign.(psi2),
		layout=GraphMakie.Spectral()
	)
	fig
end

# ╔═╡ 4666b59e-ddf2-40cb-8703-ecadccc14387
hist(psi2; bins=100)

# ╔═╡ 22919ac6-ce75-4b8a-bf6c-935d7f67364e
md"""
Nice!
"""

# ╔═╡ 5510a572-7026-49ba-b924-9e9d70114354
md"""
# Graph Laplacian PCA
"""

# ╔═╡ 3b1ba68b-de0f-4cd1-9b51-17d1e7fa0ed4
md"""
!!! note "Source"
	__Graph-Laplacian PCA: Closed-form Solution and Robustness__
	
	Bo Jiang, Chris Ding, Bin Luo, Jin Tang; CVPR 2013
"""

# ╔═╡ 0c906855-eb78-43e3-97b3-7915c1a33a1c
md"""
## Data
"""

# ╔═╡ db10dd50-4cdf-48f9-b5fe-9c0923a07977
md"""
!!! quote
	"input data contains vector data ``X`` and graph data ``W``"

Input data matrix ``X`` of ``n`` column vectors ``x_i\in\mathbb{R}^p``

$$X=\begin{bmatrix}x_1&\dots&x_n\end{bmatrix}\in\mathbb{R}^{p\times n}$$

Input data "graph" ``W`` is actually a Gram matrix

$$W=\begin{bmatrix}
	k_{1,1}&\cdots&k_{1,n}\\
	\vdots&\ddots&\vdots\\
	k_{n,1}&\cdots&k_{n,n}
\end{bmatrix}\in\mathbb{R}^{n\times n}$$
"""

# ╔═╡ 6d8c1e7a-e340-430e-abfb-c1937f537eeb
md"""
## Objective
"""

# ╔═╡ 88b0485d-e3d7-4e4f-894d-e2bf883acb80
md"""
!!! quote
	"We wish to learn a low dimensional data representation of ``X`` that incorporates data cluster structures inherent in ``W``, i.e., a representation regularized by the data manifold encoded in ``W``."

The solution presented is to combine PCA with Laplacian embedding.

For Laplacian embedding, the objective is

$$\min_Q\sum_{i,j=1}^n||q_i-q_j||^2W_{ij}:Q^TQ=I$$

which is also

$$\min_Q\text{Tr}(Q^TLQ)$$

where ``Q\in\mathbb{R}^{n\times k}`` is the matrix of embedding column vectors ``q_i``.

In PCA, the objective is

$$\min_{U,V}||\tilde{X}-UV^T||^2_F:V^TV=I$$

where ``U\in\mathbb{R}^{p\times k}`` is the matrix of principal components, ``V\in\mathbb{R}^{n\times k}`` is the matrix of ``k``-dimensional data embeddings, and ``\tilde{X}`` is the matrix ``X`` after row-centering (i.e. subtracting the mean of each row from every element in the row).

Combining the PCA and Laplacian embedding objectives by setting ``V=Q`` and taking a weighted sum gives the gLPCA objective:

$$\min_{U,Q}J=||\tilde{X}-UQ^T||^2_F+\alpha\text{Tr}(Q^TLQ):Q^TQ=I$$
"""

# ╔═╡ cfeb71f3-a9d4-4b50-80d9-911c41f698c7
md"""
## Solution
"""

# ╔═╡ ae415d67-6c73-414f-8870-8747b8fb2e84
md"""
### Finding ``U``

The optimal ``U`` for a given ``Q`` is obtained by solving

$$\frac{\partial{J}}{\partial{U}}=-2\tilde{X}Q+2U=0$$

which yields

$$U=\tilde{X}Q$$
"""

# ╔═╡ 311e5317-f4ee-4b35-812b-8c458bc59187
md"""
### Normalizations

Let's also impose some normalizations.

Normalization term for ``\tilde{X}^T\tilde{X}``:

$$\lambda_n=\max\lambda:\lambda \tilde{X}^T\tilde{X}=\Psi \tilde{X}^T\tilde{X}$$

Normalization term for ``L``:

$$\xi_n=\max\xi:\xi L=\Psi L$$

Alternative trade-off factor:

$$\alpha=\frac{\lambda_n\beta}{\xi_n(1-\beta)}$$
"""

# ╔═╡ d78444fd-b7a7-4fec-829c-58dc93752aff
md"""
### Finding ``Q``

The optimal ``Q`` is obtained by applying this result to the gLPCA objective function:

$$\min_{Q}||\tilde{X}-\tilde{X}QQ^T||^2_F+\alpha\text{Tr}(Q^TLQ)=\min_Q\text{Tr}\left(Q^T(\alpha L-\tilde{X}^T\tilde{X})Q\right)$$

Let 

$$G_\alpha=\alpha L-\tilde{X}^T\tilde{X}$$  

Then the objective is 

$$\min_Q\text{Tr}(Q^TG_\alpha Q)$$

Applying the normalizations from above, this becomes:

$$\min_Q\text{Tr}\left(Q^T\left[(1-\beta)(I-\frac{\tilde{X}^T\tilde{X}}{\lambda_n})+\frac{\beta}{\xi_n}L\right]Q\right)$$

Finally, let

$$G_\beta=(1-\beta)(I-\frac{\tilde{X}^T\tilde{X}}{\lambda_n})+\frac{\beta}{\xi_n}L$$

Which gives the objective function in its final form:

$$\min_Q\text{Tr}(Q^TG_\beta Q)$$

``\therefore`` The optimal ``Q`` is composed of the eigenvectors corresponding to the smallest eigenvalues of ``G_\beta``.
"""

# ╔═╡ bcb1d763-19b9-4306-9146-c845bf7ce2cb
md"""
## Projecting to ``\mathbb{R}^k``
"""

# ╔═╡ c9532ba1-694f-4e46-814d-2da52a602d3e
md"""
The matrix ``U`` contains the ``k`` graph-``W``-regularized principal components of ``\tilde{X}``.
This is also referred to as the "data representation" in the paper.

``U`` is a matrix of dimension ``p\times k``, and ``\tilde{X}`` is of dimension ``p\times n``.
We want to get ``\hat{X}\in\mathbb{R}^{k\times n}``.

$$\hat{X}=U^T\tilde{X}=Q^T\tilde{X}^T\tilde{X}$$
"""

# ╔═╡ 3d989556-89cf-48e8-ad7c-c05461d862b0
md"""
## Reconstruction in ``\mathbb{R}^p``

The reconstruction of the data is:

$$\tilde{X}\approx\tilde{X}QQ^T$$

We can use this to make a loss function which can be tuned over ``\beta``:

$$E=\frac{||\tilde{X}-\tilde{X}QQ^T||}{||\tilde{X}||}$$
"""

# ╔═╡ 5cbe18b2-23ff-4ac7-ae89-1209eb2cb678
md"""
## Example
"""

# ╔═╡ 4151ea1e-611d-4d92-8f9f-af13fc441d96
md"""
### Data
"""

# ╔═╡ eeee05dc-cf41-4cc9-af85-030a2a2b9bb1
md"""
Let's try this out on the grid graph example.

The ``X`` matrix will just be the vector of values from the function ``f`` applied to each grid point's coordinates.
"""

# ╔═╡ 5e4ba570-f890-4b88-8cc6-80f9c47d3be6
X = fϕ'

# ╔═╡ 4c8cdb41-915a-47f9-9aff-bcca06294fff
md"""
Apply the centering procedure to ``X``
"""

# ╔═╡ 7d59270f-af25-4e9d-816f-1ec9fe449f4a
X̃ = X .- sum(X)/length(X)

# ╔═╡ 87d8d815-9fb2-453a-b675-bf0d057c250b
md"""
The graph ``W`` is the grid
"""

# ╔═╡ 785d4d8c-a8d1-4713-8b83-0d7f877fca64
W = grid_5x5

# ╔═╡ cf03334b-29a0-41c1-95b0-3b434cca27bd
md"""
### gLPCA
"""

# ╔═╡ ef6a86c1-4bb2-4ca1-9a0e-7123a44d53ce
md"""
We choose the parameter ``\beta``
"""

# ╔═╡ fd1fe80e-37d2-4d15-841c-0cd76bc95c2a
md"""
β = $(@bind β NumberField(0:0.1:1; default=0.5))
"""

# ╔═╡ d6ffa999-3317-4f46-9758-d39f0eb212f3
Q = begin
	XTX = X̃' * X̃
	λXTX, ψXTX = eigen(XTX)
	λn = maximum(λXTX)
	
	wL = Matrix(laplacian_matrix(W))
	λL, ψL = eigen(wL)
	ξn = maximum(λL)
	
	Gβ = (1 - β) * (I - XTX / λn) + β * wL / ξn
	λQ, ψQ = eigen(Gβ)
	Q = ψQ[:, sortperm(λQ)[2:3]]
end;

# ╔═╡ dc1fedc4-16e6-4961-a04e-a7a989db0324
md"""
### Projection
"""

# ╔═╡ 6596c5fc-cc4b-41df-a6b3-93bc461eda55
X̂ = Q' * X̃' * X̃;

# ╔═╡ 3d3cb8c1-9602-4d31-b30b-d1e5e70ac25e
scatter(X̂)

# ╔═╡ 02fc9724-83d9-4978-92df-c090dbc5d9f8
md"""
### Reconstruction
"""

# ╔═╡ c6683ba7-f1a5-4aa8-9421-409a4b7facb1
md"""
!!! danger "Hmm."
	The reconstruction is WAY OFF!
"""

# ╔═╡ e22c804d-c5de-45fd-9c22-b0483c7a7b4d
begin
	local fig = Figure()
	
	hist!(
		Axis(fig[1, 1]; title="Original"), 
		X̃[:]; 
		color=:orange, 
		normalization=:probability
	)
	
	hist!(
		Axis(fig[1, 2]; title="Reconstruction"), 
		X̂[:];
		color=:black, 
		normalization=:probability
	)
	fig
end

# ╔═╡ 085de9b1-00b4-4720-b281-e6f4259dd479
@test norm(X̃ - X̃ * Q * Q') / norm(X̃) ≤ 0.1

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
GraphMakie = "1ecd5474-83a3-4783-bb4f-06765db800d2"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ShortCodes = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[compat]
CairoMakie = "~0.10.1"
ForwardDiff = "~0.10.34"
GraphMakie = "~0.5.1"
Graphs = "~1.7.4"
PlutoTest = "~0.2.2"
PlutoUI = "~0.7.49"
ShortCodes = "~0.3.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.5"
manifest_format = "2.0"
project_hash = "e2722d40ff543340a040860caa1a1db07ea8fb96"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "52b3b436f8f73133d7bc3a6c71ee7ed6ab2ab754"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.3"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["Printf", "ScanByte", "TranscodingStreams"]
git-tree-sha1 = "d50976f217489ce799e366d9561d56a98a30d7fe"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "0.8.2"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "1dd4d9f5beebac0c03446918741b1a03dc5e5788"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.6"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[deps.CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "SnoopPrecompile"]
git-tree-sha1 = "439517f69683932a078b2976ca040e21dd18598c"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.10.1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e7ff6cadf743c098e08fca25c91103ee4303c9bb"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.6"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "00a2cccc7f098ff3b66806862d275ca3db9e6e5a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.5.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "c5b6685d53f933c11404a3ae9822afe30d522494"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.12.2"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "74911ad88921455c6afcad1eefa12bd7b1724631"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.80"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "7be5f99f7d15578798f338f5433b6c432ea8037b"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "9a0472ec2f5409db243160a8b030f94c380167a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "a69dd6db8a809f78846ff259298678f0d6212180"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.34"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics"]
git-tree-sha1 = "38a92e40157100e796690421e34a11c107205c86"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "6872f5ec8fd1a38880f027a26739d42dcda6691f"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.2"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "fb28b5dc239d0174d7297310ef7b84a11804dfab"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.0.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "fe9aea4ed3ec6afdfbeb5a4f39a2208909b162a6"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.5"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.GraphMakie]]
deps = ["GeometryBasics", "Graphs", "LinearAlgebra", "Makie", "NetworkLayout", "StaticArrays"]
git-tree-sha1 = "3e2a15c851ea53cc28501c600f3df30647e3885b"
uuid = "1ecd5474-83a3-4783-bb4f-06765db800d2"
version = "0.5.1"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "ba2d094a88b6b287bd25cfa86f301e7693ffae2f"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.4"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "678d136003ed5bceaab05cf64519e3f956ffa4ba"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.9.1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "a1fd86ba1fae7c73fd98c7e60f8adf036c31d441"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.7.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "342f789fd041a55166764c351da1710db97ce0e0"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.6"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "16c0cc91853084cb5f58a78bd209513900206ce6"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.4"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "SnoopPrecompile", "StructTypes", "UUIDs"]
git-tree-sha1 = "84b10656a41ef564c39d2d477d7236966d2b5683"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.12.0"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "a77b273f1ddec645d1b7c4fd5fb98c8f90ad10a5"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "946607f84feb96220f480e0422d3484c49c00239"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.19"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "2ce8695e1e699b68702c03402672a69f54b8aca9"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Makie]]
deps = ["Animations", "Base64", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "InteractiveUtils", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MakieCore", "Markdown", "Match", "MathTeXEngine", "MiniQhull", "Observables", "OffsetArrays", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "RelocatableFolders", "Setfield", "Showoff", "SignedDistanceFields", "SnoopPrecompile", "SparseArrays", "StableHashTraits", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun"]
git-tree-sha1 = "20f42c8f4d70a795cb7927d7312b98a255209155"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.19.1"

[[deps.MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "c5b3ce048ee73a08bbca1b9f4a776e64257611d5"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.6.1"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Match]]
git-tree-sha1 = "1d9bc5c1a6e7ee24effb93f175c9342f9154d97f"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.2.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "Test", "UnicodeFun"]
git-tree-sha1 = "f04120d9adf4f49be242db0b905bea0be32198d1"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.5.4"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Memoize]]
deps = ["MacroTools"]
git-tree-sha1 = "2b1dfcba103de714d31c033b5dacc2e4a12c7caa"
uuid = "c03570c3-d221-55d1-a50c-7939bbd78826"
version = "0.4.4"

[[deps.MiniQhull]]
deps = ["QhullMiniWrapper_jll"]
git-tree-sha1 = "9dc837d180ee49eeb7c8b77bb1c860452634b0d1"
uuid = "978d7f02-9e05-4691-894f-ae31a51d76ca"
version = "0.4.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "5ae7ca23e13855b3aba94550f26146c01d259267"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.0"

[[deps.NetworkLayout]]
deps = ["GeometryBasics", "LinearAlgebra", "Random", "Requires", "SparseArrays"]
git-tree-sha1 = "cac8fc7ba64b699c678094fa630f49b80618f625"
uuid = "46757867-2c16-5918-afeb-47bfcb05e46a"
version = "0.4.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "6862738f9796b3edc1c09d0890afce4eca9e7e93"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.4"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "f71d8950b724e9ff6110fc948dff5a329f901d64"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "6503b77492fd7fcb9379bf73cd31035670e3c509"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.3.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6e9dba33f9f2c44e08a020b0caf6903be540004"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.19+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.40.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "f809158b27eba0c18c269cf2a2be6ed751d3e81d"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.17"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "ec3edfe723df33528e085e632414499f26650501"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "84a314e3926ba9ec66ac097e3635e270986b0f10"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.9+0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "8175fc2b118a3755113c8e68084dc1a9e63c61ee"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f6cf8e7944e50901594838951729a1861e668cb8"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.2"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "5b7690dd212e026bbab1860016a6601cb077ab66"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.2"

[[deps.PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "17aa9b81106e661cffa1c4c36c17ee1c50a86eda"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.2.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eadad7b14cf046de6eb41f13c9275e5aa2711ab6"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.49"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.QhullMiniWrapper_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Qhull_jll"]
git-tree-sha1 = "607cf73c03f8a9f83b36db0b86a3a9c14179621f"
uuid = "460c41e3-6112-5d7f-b78c-b6823adb3f2d"
version = "1.0.0+1"

[[deps.Qhull_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "238dd7e2cc577281976b9681702174850f8d4cbc"
uuid = "784f63db-0788-585a-bace-daefebcd302b"
version = "8.0.1001+0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "97aa253e65b784fd13e83774cadc95b38011d734"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.6.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "8b20084a97b004588125caebf418d8cab9e393d1"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.4.4"

[[deps.ScanByte]]
deps = ["Libdl", "SIMD"]
git-tree-sha1 = "2436b15f376005e8790e318329560dcc67188e84"
uuid = "7b38b023-a4d7-4c5e-8d43-3f3097f304eb"
version = "0.3.3"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShortCodes]]
deps = ["Base64", "CodecZlib", "HTTP", "JSON3", "Memoize", "UUIDs"]
git-tree-sha1 = "ac4f9037fd6f0cd51948dba5eee2c508116f7f41"
uuid = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
version = "0.3.4"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StableHashTraits]]
deps = ["CRC32c", "Compat", "Dates", "SHA", "Tables", "TupleTools", "UUIDs"]
git-tree-sha1 = "0b8b801b8f03a329a4e86b44c5e8a7d7f4fe10a3"
uuid = "c5dd0088-6c3f-4803-b00e-f31a60c170fa"
version = "0.3.1"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "6954a456979f23d05085727adb17c4551c19ecd1"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.12"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "ab6083f09b3e617e34a956b43e9d51b824206932"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.1.1"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "GPUArraysCore", "StaticArraysCore", "Tables"]
git-tree-sha1 = "b03a3b745aa49b566f128977a7dd1be8711c5e71"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.14"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "ca4bccb03acf9faaf4137a9abc1881ed1841aa70"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.10.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "7e6b0e3e571be0b4dd4d2a9a3a83b65c04351ccc"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.3"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

[[deps.TupleTools]]
git-tree-sha1 = "3c712976c47707ff893cf6ba4354aa14db1d8938"
uuid = "9d95972d-f1c8-5527-a6e0-b4b365fa01f6"
version = "1.3.0"

[[deps.URIs]]
git-tree-sha1 = "ac00576f90d8a259f2c9d823e91d1de3fd44d348"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "libpng_jll"]
git-tree-sha1 = "d4f63314c8aa1e48cd22aa0c17ed76cd1ae48c3c"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.3+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╠═499fa1fa-95d9-11ed-30ff-2b7a001a43ae
# ╟─d22f6168-cd5a-4e78-bb78-9d85281528b0
# ╟─2915ef04-6b31-44a8-a31a-3a24608939be
# ╟─5428e4c4-f59c-44fd-b405-52a5e2eb2e50
# ╟─e8441276-2be8-4dae-bfe3-beda768deab6
# ╠═a6401037-5c6a-4e9b-aaeb-7eaf25f2bae0
# ╟─4d46de85-6759-4233-a16f-109f63cd149a
# ╟─2837816a-7438-4aa9-ae8e-748f59fb27d0
# ╟─94c69584-7fa1-450c-9ac7-941c4e17b0dc
# ╠═a042b3c6-f28d-49e9-ad9b-6f3c1c23db1a
# ╟─de7475f9-a94a-4fa7-9ae4-0610bbe96da7
# ╟─b0182d38-49af-49d4-874e-1a3536d168a7
# ╟─fe1f6716-9586-4b69-abb6-1ffae12257f7
# ╠═aa2705f0-e03a-4583-a71d-ccc8c8fcc556
# ╠═323a4dc0-b689-44c5-b1ad-ec68ffd3a1f0
# ╟─78e54473-42d5-47ca-95d2-3a34858b0f5c
# ╟─968ff5dc-9c3e-44aa-afdd-644a24c9acee
# ╠═88302a0f-52cd-4af7-8cba-3faa95a168fe
# ╟─1ce279b0-7670-4fa0-a868-d9750463d54d
# ╟─60a6bebf-ba80-4ec5-92f6-d2133c52f163
# ╟─b78de7d4-0673-496b-8392-0c776b8e13a4
# ╟─7e212751-c446-43fe-bce9-98b11f064eff
# ╟─5f794783-ee69-4fba-bebc-eafe340f8dea
# ╠═9a7beb41-2b76-4b28-9f80-458e77f4d8f6
# ╠═7e1dc7f3-f95e-45e6-8352-17c9c988aa57
# ╠═5f68596a-70c3-4af7-9170-9459ae7146fe
# ╟─a1c5c766-6ae7-40f9-8cc1-99892273ea31
# ╟─524dda81-be87-46ef-9e7f-e599286d9d09
# ╟─550e6cc9-ba15-475b-a30d-3959e3f36d25
# ╠═e91a191f-afd4-4d53-8a97-02bff4968883
# ╟─e6b8f814-e82f-4ab8-8888-f5ab110ccc1d
# ╠═3fb0d9c5-6605-47cc-a927-9be7a727d983
# ╠═72054f47-2f63-435f-a424-f6ea72023ef7
# ╟─e409c8d9-d4a9-4eea-b447-187f7b72313e
# ╟─e48e4b33-085e-48a6-9dc3-13a7aa159f02
# ╟─8a86969b-65b5-4aec-a1a0-cd948920a62b
# ╠═44bb41d3-4ae6-4ea5-988e-ff53625d12b7
# ╟─2be9e231-fe98-408f-8207-df2ce8a29d62
# ╠═1c8cafd9-bec3-4dea-8c94-bcbb5d5f7bb3
# ╟─c82c188e-0d63-4042-b8b6-1ad2494482df
# ╟─2ab71373-61bb-4324-bca2-2b8d691ee839
# ╟─bc25a4cc-8f4a-40c3-afe8-30e81759cf22
# ╠═dd8cab9c-6690-457f-8833-43b7f7cfdfba
# ╟─ae8979ee-fd6e-4d55-9c18-062c3a6baa8e
# ╟─5d30b1c6-3097-483a-a980-a43ae9251821
# ╠═c76da5f8-89e7-47d4-947b-51fd99353d3c
# ╟─3fef1ca6-6bf8-437c-88ec-1f482201fbba
# ╟─698d5930-8bda-423a-aefb-12dbb5fa81c2
# ╟─b563f867-15b2-44e7-b69b-d015cfe9e5d6
# ╟─796b5768-8876-44ab-a52c-79b280de28c5
# ╟─454027e3-4733-40ec-8ae0-4b18d5386cb3
# ╟─7b15c2e0-eb73-4fe0-b692-688e1a56c17f
# ╟─962db6c6-9453-4b9a-b3f0-301a01cec327
# ╠═f95cee56-df99-4a4f-8e80-515cc1c7df50
# ╟─a847dd0a-ed33-4a3d-95a3-b2b7cc93af79
# ╟─c2e6f122-7835-43da-a5e3-81b629809863
# ╠═72785005-3956-4737-93e8-cf24de1f5154
# ╠═39cdbeb9-270f-4b53-9920-c1404d17a5b9
# ╠═ef9ec87b-2b40-41e4-8045-9f7da7ad19b6
# ╟─26f0c057-5748-4627-ae6e-0712a31fb8df
# ╠═0c231f7f-d7c7-4e1f-bb1f-e15989d4d702
# ╟─5c23dcd9-9486-4b35-bfcd-6404203d0f27
# ╟─eebb5288-5c64-4148-82ce-e048c259dd42
# ╟─2e9e0659-7544-4445-a6a7-317497fa0574
# ╟─520ff1c1-5d40-42af-a4cc-8b27663383f7
# ╟─ad71e4ab-c1a1-4e96-be04-6505eb5e76c7
# ╠═62b45813-ffd9-440b-bf04-b6e1dceca140
# ╟─4d11e228-6082-4a19-bbd9-b50c97ec328b
# ╟─1398722a-2ce7-437e-b67e-83779fec0639
# ╠═ecc9d934-ddb0-4310-a52d-9f919f1c7455
# ╟─e91440c2-f2c7-4067-aa9c-a369b18cb229
# ╠═6141cb44-e94e-488f-9133-0f09e13a0a67
# ╠═4666b59e-ddf2-40cb-8703-ecadccc14387
# ╟─22919ac6-ce75-4b8a-bf6c-935d7f67364e
# ╟─5510a572-7026-49ba-b924-9e9d70114354
# ╟─3b1ba68b-de0f-4cd1-9b51-17d1e7fa0ed4
# ╟─0c906855-eb78-43e3-97b3-7915c1a33a1c
# ╟─db10dd50-4cdf-48f9-b5fe-9c0923a07977
# ╟─6d8c1e7a-e340-430e-abfb-c1937f537eeb
# ╟─88b0485d-e3d7-4e4f-894d-e2bf883acb80
# ╟─cfeb71f3-a9d4-4b50-80d9-911c41f698c7
# ╟─ae415d67-6c73-414f-8870-8747b8fb2e84
# ╟─311e5317-f4ee-4b35-812b-8c458bc59187
# ╟─d78444fd-b7a7-4fec-829c-58dc93752aff
# ╟─bcb1d763-19b9-4306-9146-c845bf7ce2cb
# ╟─c9532ba1-694f-4e46-814d-2da52a602d3e
# ╟─3d989556-89cf-48e8-ad7c-c05461d862b0
# ╟─5cbe18b2-23ff-4ac7-ae89-1209eb2cb678
# ╟─4151ea1e-611d-4d92-8f9f-af13fc441d96
# ╟─eeee05dc-cf41-4cc9-af85-030a2a2b9bb1
# ╠═5e4ba570-f890-4b88-8cc6-80f9c47d3be6
# ╟─4c8cdb41-915a-47f9-9aff-bcca06294fff
# ╠═7d59270f-af25-4e9d-816f-1ec9fe449f4a
# ╟─87d8d815-9fb2-453a-b675-bf0d057c250b
# ╠═785d4d8c-a8d1-4713-8b83-0d7f877fca64
# ╟─cf03334b-29a0-41c1-95b0-3b434cca27bd
# ╟─ef6a86c1-4bb2-4ca1-9a0e-7123a44d53ce
# ╟─fd1fe80e-37d2-4d15-841c-0cd76bc95c2a
# ╠═d6ffa999-3317-4f46-9758-d39f0eb212f3
# ╟─dc1fedc4-16e6-4961-a04e-a7a989db0324
# ╠═6596c5fc-cc4b-41df-a6b3-93bc461eda55
# ╟─3d3cb8c1-9602-4d31-b30b-d1e5e70ac25e
# ╟─02fc9724-83d9-4978-92df-c090dbc5d9f8
# ╟─c6683ba7-f1a5-4aa8-9421-409a4b7facb1
# ╟─e22c804d-c5de-45fd-9c22-b0483c7a7b4d
# ╠═085de9b1-00b4-4720-b281-e6f4259dd479
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
