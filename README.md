# FLI pipeline T2

* ``matlab``: Matlab code of the pipeline
* ``compile.sh``: a script to compile the Matlab code using the [ Matlab Compiler ] (http://www.mathworks.com/products/compiler) (requires a licence). 
* ``pipeline_T2.json``: a JSON descriptor in the [Boutiques] (http://boutiques.github.io) format, used to include the pipeline in a computing platform.
* ``Dockerfile``: a Dockerfile to build a container (requires that the pipeline is compiled using ``bin/compile.sh``

