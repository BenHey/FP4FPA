install_julia:
	yes '' | (curl -fsSL https://install.julialang.org | sh)
	. ~/.bashrc

install_packages:
	julia installer.jl
	export JULIA_NUM_THREADS=16
    
    
# Run with default parameters
run:
	julia run.jl --niter 10000  --agent_values 0,1,0,1  --scenarios "1-3;1-4;2-3;2-4"   --B_step 0.0025


clean:
	rm -f *.png
