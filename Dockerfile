# Docker image for a tmpnb server, used to teach the EE Python API

FROM debian:jessie

MAINTAINER Tyler Erickson <tylere@google.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y git vim wget build-essential python-dev ca-certificates bzip2 libsm6 && apt-get clean

ENV CONDA_DIR /opt/conda

# Install conda for the jovyan user only (this is a single user container)
RUN echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-3.9.1-Linux-x86_64.sh && \
    /bin/bash /Miniconda3-3.9.1-Linux-x86_64.sh -b -p $CONDA_DIR && \
    rm Miniconda3-3.9.1-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes conda==3.10.1

# We run our docker images with a non-root user as a security precaution.
# jovyan is our user
RUN useradd -m -s /bin/bash jovyan
RUN chown -R jovyan:jovyan $CONDA_DIR

# Workaround for issue with ADD permissions
USER root
ADD profile_default /home/jovyan/.ipython/profile_default
ADD templates/ /srv/templates/
RUN chmod a+rX /srv/templates
RUN chown jovyan:jovyan /home/jovyan -R

USER jovyan

# Expose our custom setup to the installed ipython (for mounting by nginx)
RUN cp /home/jovyan/.ipython/profile_default/static/custom/* /opt/conda/lib/python3.4/site-packages/IPython/html/static/custom/

RUN conda install --yes ipython-notebook terminado && conda clean -yt
RUN ipython profile create

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
