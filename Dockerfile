# Docker image for a tmpnb server, used to teach the EE Python API
# v006

FROM jupyter/minimal

MAINTAINER Tyler Erickson <tylere@google.com>

USER root

RUN mkdir /home/jovyan/communities && mkdir /home/jovyan/featured
ADD notebooks/ /home/jovyan/
#ADD datasets/ /home/jovyan/datasets/
RUN chown -R jovyan:jovyan /home/jovyan

EXPOSE 8888

USER jovyan
ENV HOME /home/jovyan
ENV SHELL /bin/bash
ENV USER jovyan
ENV PATH $CONDA_DIR/bin:$CONDA_DIR/envs/python2/bin:$PATH
WORKDIR $HOME

USER jovyan

# Python packages
RUN conda install --yes numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh && conda clean -yt

# Now for a python2 environment
RUN conda create -p $CONDA_DIR/envs/python2 python=2.7 ipython numpy pandas scikit-learn scikit-image matplotlib scipy seaborn sympy cython patsy statsmodels cloudpickle dill numba bokeh && conda clean -yt

# install the Earth Engine package and dependencies
RUN conda install -y -n python2 --channel bcbio oauth2client
RUN conda install -y -n python2 --channel tylerickson --channel pandas earthengine-api

RUN $CONDA_DIR/envs/python2/bin/python $CONDA_DIR/envs/python2/bin/ipython kernelspec install-self --user

# Extra Kernels
RUN pip install --user bash_kernel

# Featured notebooks
#RUN git clone --depth 1 https://github.com/jvns/pandas-cookbook.git /home/jovyan/featured/pandas-cookbook/
#RUN git clone --depth 1 https://github.com/ipython/ipython.git /home/jovyan/featured/ipython-examples/

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
