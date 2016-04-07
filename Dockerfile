from glatard/matlab-compiler-runtime-docker
RUN LD_LIBRARY_PATH="" yum install zip -y
ADD bin /usr/local/pipeline_T2/bin
RUN chmod 777 /usr/local/pipeline_T2/bin/pipeline_T2
ENV PATH=$PATH:/usr/local/pipeline_T2/bin
