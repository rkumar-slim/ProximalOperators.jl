# squared L2 norm (times a constant, or weighted)

export SqrNormL2

"""
**Squared Euclidean norm (weighted)**

    SqrNormL2(λ=1.0)

With a nonnegative scalar `λ`, returns the function
```math
f(x) = \\tfrac{λ}{2}\\|x\\|^2.
```
With a nonnegative array `λ`, returns the function
```math
f(x) = \\tfrac{1}{2}∑_i λ_i x_i^2.
```
"""

immutable SqrNormL2{T <: Union{Real, AbstractArray}} <: ProximableFunction
  lambda::T
  function SqrNormL2{T}(lambda::T) where {T <: Union{Real,AbstractArray}}
    if any(lambda .< 0)
      error("coefficients in λ must be nonnegative")
    else
      new(lambda)
    end
  end
end

is_convex(f::SqrNormL2) = true
is_smooth(f::SqrNormL2) = true
is_separable(f::SqrNormL2) = true
is_quadratic(f::SqrNormL2) = true
is_strongly_convex(f::SqrNormL2) = all(f.lambda .> 0)

SqrNormL2{T <: Real}(lambda::T=1.0) = SqrNormL2{T}(lambda)

SqrNormL2{T <: AbstractArray}(lambda::T) = SqrNormL2{T}(lambda)

function (f::SqrNormL2{S}){S <: Real, T <: RealOrComplex}(x::AbstractArray{T})
  return (f.lambda/2)*vecnorm(x)^2
end

function (f::SqrNormL2{S}){S <: AbstractArray, T <: RealOrComplex}(x::AbstractArray{T})
  sqnorm = 0.0
  for k in eachindex(x)
    sqnorm += f.lambda[k]*abs2(x[k])
  end
  return 0.5*sqnorm
end

function gradient!(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::Real=1.0) where {S <: Real, T <: RealOrComplex}
  sqnx = 0.0
  for k in eachindex(x)
    y[k] = f.lambda*x[k]
    sqnx += abs2(x[k])
  end
  return (f.lambda/2)*sqnx
end

function gradient!(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::Real=1.0) where {S <: AbstractArray, T <: RealOrComplex}
  sqnx = 0.0
  for k in eachindex(x)
    y[k] = f.lambda[k]*x[k]
    sqnx += f.lambda[k]*abs2(x[k])
  end
  return 0.5*sqnx
end

function prox!{S <: Real, T <: RealOrComplex}(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::Real=1.0)
  gl = gamma*f.lambda
  sqny = 0.0
  for k in eachindex(x)
    y[k] = x[k]/(1+gl)
    sqny += abs2(y[k])
  end
  return (f.lambda/2)*sqny
end

function prox!{S <: AbstractArray, T <: RealOrComplex}(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::Real=1.0)
  wsqny = 0.0
  for k in eachindex(x)
    y[k] = x[k]/(1+gamma*f.lambda[k])
    wsqny += f.lambda[k]*abs2(y[k])
  end
  return 0.5*wsqny
end

function prox!{S <: Real, T <: RealOrComplex}(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::AbstractArray)
  sqny = 0.0
  for k in eachindex(x)
    y[k] = x[k]/(1+gamma[k]*f.lambda)
    sqny += abs2(y[k])
  end
  return (f.lambda/2)*sqny
end

function prox!{S <: AbstractArray, T <: RealOrComplex}(y::AbstractArray{T}, f::SqrNormL2{S}, x::AbstractArray{T}, gamma::AbstractArray)
  wsqny = 0.0
  for k in eachindex(x)
    y[k] = x[k]/(1+gamma[k]*f.lambda[k])
    wsqny += f.lambda[k]*abs2(y[k])
  end
  return 0.5*wsqny
end

fun_name(f::SqrNormL2) = "weighted squared Euclidean norm"
fun_dom(f::SqrNormL2) = "AbstractArray{Real}, AbstractArray{Complex}"
fun_expr{T <: Real}(f::SqrNormL2{T}) = "x ↦ (λ/2)||x||^2"
fun_expr{T <: AbstractArray}(f::SqrNormL2{T}) = "x ↦ (1/2)sum( λ_i (x_i)^2 )"
fun_params{T <: Real}(f::SqrNormL2{T}) = "λ = $(f.lambda)"
fun_params{T <: AbstractArray}(f::SqrNormL2{T}) = string("λ = ", typeof(f.lambda), " of size ", size(f.lambda))

function prox_naive{T <: RealOrComplex}(f::SqrNormL2, x::AbstractArray{T}, gamma=1.0)
  y = x./(1+f.lambda.*gamma)
  return y, 0.5*real(vecdot(f.lambda.*y,y))
end
