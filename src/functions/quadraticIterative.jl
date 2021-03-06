### CONCRETE TYPE: ITERATIVE PROX EVALUATION

struct QuadraticIterative{R <: Real, M, V <: AbstractVector{R}} <: Quadratic
  Q::M
  q::V
  temp::V
end

is_prox_accurate(f::QuadraticIterative) = false

function QuadraticIterative(Q::M, q::V) where {R <: Real, M, V <: AbstractVector{R}}
  if size(Q, 1) != size(Q, 2) || length(q) != size(Q, 2)
    error("Q must be squared and q must be compatible with Q")
  end
  QuadraticIterative{R, M, V}(Q, q, similar(q))
end

function (f::QuadraticIterative{R, M, V})(x::AbstractArray{R}) where {R, M, V}
  A_mul_B!(f.temp, f.Q, x)
  return 0.5*vecdot(x, f.temp) + vecdot(x, f.q)
end

function prox!(y::AbstractArray{R}, f::QuadraticIterative{R, M, V}, x::AbstractArray{R}, gamma::R=one(R)) where {R, M, V}
  f.temp .= x./gamma .- f.q
  op = Shift(f.Q, one(R)/gamma)
  IterativeSolvers.cg!(y, op, f.temp)
  A_mul_B!(f.temp, f.Q, y)
  fy = 0.5*vecdot(y, f.temp) + vecdot(y, f.q)
  return fy
end

function gradient!(y::AbstractArray{R}, f::QuadraticIterative{R, M, V}, x::AbstractArray{R}) where {R, M, V}
  A_mul_B!(y, f.Q, x)
  y .+= f.q
  return 0.5*(vecdot(x, y) + vecdot(x, f.q))
end

function prox_naive(f::QuadraticIterative, x, gamma=1.0)
  y = IterativeSolvers.cg(gamma*f.Q + I, x - gamma*f.q)
  fy = 0.5*vecdot(y, f.Q*y) + vecdot(y, f.q)
  return y, fy
end
