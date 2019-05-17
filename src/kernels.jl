Pkg.add("Distributed")
using Distributed

@everywhere using Distributions


"""
    bubbleKernel(x::Float64, r::Float64)::Float64
Return 1.0 if dist <= r, otherwise 0.0.
"""
function bubbleKernel(x::Float64, r::Float64)::Float64
    return x <= r ? 1.0 : 0.0
end

@everywhere begin
    """
        gaussianKernel(x::Float64, r::Float64)::Float64
    Return Gaussian(x) for μ=0.0 and σ = r/3.
    (a value of σ = r/3 makes the training results comparable between different kernels
    for same values of r).
    """
    # just for performance measure, let's see the time if we only return
    # a simple linear calculation
    function gaussianKernel(x::Float64, r::Float64)::Float64
        # return x / r
        return Distributions.pdf.(Distributions.Normal(0.0,r/3), x)
    end
end
