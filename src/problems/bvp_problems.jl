"""
$(TYPEDEF)
"""
struct StandardBVProblem end

"""
$(TYPEDEF)
"""
struct BVProblem{uType,tType,isinplace,P,F,bF,PT,K} <: AbstractBVProblem{uType,tType,isinplace}
    f::F
    bc::bF
    u0::uType
    tspan::tType
    p::P
    problem_type::PT
    kwargs::K
    @add_kwonly function BVProblem{iip}(f::AbstractODEFunction,bc,u0,tspan,p=NullParameters(),
                            problem_type=StandardBVProblem();
                            kwargs...) where {iip}
        _tspan = promote_tspan(tspan)
        new{typeof(u0),typeof(tspan),iip,typeof(p),
                  typeof(f),typeof(bc),
                  typeof(problem_type),typeof(kwargs)}(
                  f,bc,u0,_tspan,p,
                  problem_type,kwargs)
    end

    function BVProblem{iip}(f,bc,u0,tspan,p=NullParameters();kwargs...) where {iip}
        BVProblem(convert(ODEFunction{iip},f),bc,u0,tspan,p;kwargs...)
      end
end

function BVProblem(f::AbstractODEFunction,bc,u0,tspan,args...;kwargs...)
    BVProblem{isinplace(f,4)}(f,bc,u0,tspan,args...;kwargs...)
end

function BVProblem(f,bc,u0,tspan,p=NullParameters();kwargs...)
    BVProblem(convert(ODEFunction,f),bc,u0,tspan,p;kwargs...)
end

# convenience interfaces:
# Allow any previous timeseries solution
function BVProblem(f::AbstractODEFunction,bc,sol::T,tspan::Tuple,p=NullParameters();kwargs...) where {T<:AbstractTimeseriesSolution}
    BVProblem(f,bc,sol.u,tspan,p)
end
# Allow a function of time for the initial guess
function BVProblem(f::AbstractODEFunction,bc,initialGuess,tspan::AbstractVector,p=NullParameters();kwargs...)
    u0 = [ initialGuess( i ) for i in tspan]
    BVProblem(f,bc,u0,(tspan[1],tspan[end]),p)
end


"""
$(TYPEDEF)
"""
struct TwoPointBVPFunction{bF}
    bc::bF
end
TwoPointBVPFunction(; bc = error("No argument bc")) = TwoPointBVPFunction(bc)
(f::TwoPointBVPFunction)(residual, ua, ub, p) = f.bc(residual, ua, ub, p)
(f::TwoPointBVPFunction)(residual, u, p) = f.bc(residual, u[1], u[end], p)


"""
$(TYPEDEF)
"""
struct TwoPointBVProblem{iip} end
function TwoPointBVProblem(f,bc,u0,tspan,p=NullParameters();kwargs...)
    iip = isinplace(f,4)
    TwoPointBVProblem{iip}(f,bc,u0,tspan,p;kwargs...)
end
function TwoPointBVProblem{iip}(f,bc,u0,tspan,p=NullParameters();kwargs...) where {iip}
    BVProblem{iip}(f,TwoPointBVPFunction(bc),u0,tspan,p;kwargs...)
end
