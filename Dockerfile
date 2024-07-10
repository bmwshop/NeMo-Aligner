# CUDA 12.2

## FROM nvcr.io/nvidia/pytorch:23.10-py3

# nemo r1.23.0
FROM nvcr.io/nvidia/pytorch:24.01-py3

### config tags
ARG APEX_TAG=master
# ARG TE_TAG=release_v1.1
# shifts is forked off the above
ARG TE_TAG=shifts
# ARG MLM_TAG=core_r0.4.0
# shifts is forked off the above
# ARG MLM_TAG=shifts
# shifts 0.7.0 are forked off 0.7
ARG MLM_TAG=shifts_r0.7.0
# ARG NEMO_TAG=r1.22.0
# shifts is forked off the above
# ARG NEMO_TAG=shifts
ARG NEMO_TAG=shifts_r1.23.0
ARG PYTRITON_VERSION=0.4.1
ARG PROTOBUF_VERSION=4.24.4
# ARG ALIGNER_COMMIT=main
# shifts is forked from the above
ARG ALIGNER_COMMIT=shifts

# if you get errors building TE or Apex, decrease this to 4
ARG MAX_JOBS=32

# needed in case git complains that it can't detect a valid email, this email is fake but works
RUN git config --global user.email "worker@nvidia.com"

# force FA
ENV NVTE_ALLOW_NONDETERMINISTIC_ALGO=1
ENV NVTE_FLASH_ATTN=1
ENV NVTE_FUSED_ATTN=0
ENV FORCE_FLASH_ATTN=1

WORKDIR /opt

# install TransformerEngine
RUN pip uninstall -y transformer-engine && \
    # git clone https://github.com/NVIDIA/TransformerEngine.git && \
    git clone https://github.com/bmwshop/TransformerEngine.git && \
    cd TransformerEngine && \
    if [ ! -z $TE_TAG ]; then \
        git fetch origin $TE_TAG && \
        git checkout FETCH_HEAD; \
    fi && \
    git submodule init && git submodule update && \
    NVTE_FRAMEWORK=pytorch NVTE_WITH_USERBUFFERS=1 MPI_HOME=/usr/local/mpi pip install .

# install latest apex
RUN pip uninstall -y apex && \
    git clone https://github.com/NVIDIA/apex && \
    cd apex && \
    if [ ! -z $APEX_TAG ]; then \
        git fetch origin $APEX_TAG && \
        git checkout FETCH_HEAD; \
    fi && \
    pip install install -v --no-build-isolation --disable-pip-version-check --no-cache-dir --config-settings "--build-option=--cpp_ext --cuda_ext --fast_layer_norm --distributed_adam --deprecated_fused_adam" ./

# place any util pkgs here
RUN pip install --upgrade-strategy only-if-needed nvidia-pytriton==$PYTRITON_VERSION
RUN pip install -U --no-deps protobuf==$PROTOBUF_VERSION
RUN pip install --upgrade-strategy only-if-needed jsonlines

# NeMo
# RUN git clone https://github.com/NVIDIA/NeMo.git && \
# RUN git clone https://github.com/bmwshop/NeMo.git && \
RUN echo "foiiiiiiiiiiiiiyiyierrcei9"
RUN git clone https://github.com/bmwshop/NeMo.git
RUN     cd NeMo && \
    git pull && \
    if [ ! -z $NEMO_TAG ]; then \
        git fetch origin $NEMO_TAG && \
        git checkout FETCH_HEAD; \
    fi && \
    pip uninstall -y nemo_toolkit sacrebleu && \
    rm -rf .git && pip install -e ".[nlp]" && \
    cd nemo/collections/nlp/data/language_modeling/megatron && make

#     git cherry-pick --no-commit -X theirs \
#         fa8d416793d850f4ce56bea65e1fe28cc0d092c0 \
#         a7f0bc1903493888c31436efc2452ff721fa5a67 \
#         52d50e9e09a3e636d60535fd9882f3b3f32f92ad \
#         9940ec60058f644662809a6787ba1b7c464567ad \
#         7d3d9ac3b1aecf5786b5978a0c1e574701473c62 && \
#     sed -i 's/shutil.rmtree(ckpt_to_dir(filepath))/shutil.rmtree(ckpt_to_dir(filepath), ignore_errors=True)/g' nemo/collections/nlp/parts/nlp_overrides.py && \


# MLM
RUN echo "iititrrinstalling mlm!!"
RUN pip uninstall -y megatron-core && \
    git clone https://github.com/bmwshop/Megatron-LM.git && \
#     git clone https://github.com/NVIDIA/Megatron-LM.git && \
    cd Megatron-LM && \
    git pull && \
    if [ ! -z $MLM_TAG ]; then \
        git fetch origin $MLM_TAG && \
        git checkout FETCH_HEAD; \
    fi && \
    pip install -e .

# NeMo Aligner
# RUN git clone https://github.com/NVIDIA/NeMo-Aligner.git && \
RUN echo "rawrr"
RUN git clone https://github.com/bmwshop/NeMo-Aligner.git && \
    cd NeMo-Aligner && \
    git pull && \
    if [ ! -z $ALIGNER_COMMIT ]; then \
        git fetch origin $ALIGNER_COMMIT && \
        git checkout FETCH_HEAD; \
    fi && \
    pip install --no-deps -e .

# fix the ImportError: cannot import name 'ALBERT_PRETRAINED_MODEL_ARCHIVE_LIST' from 'transformers' (/usr/local/lib/python3.10/dist-packages/transformers/__init__.py)
RUN pip install transformers==4.40.2
WORKDIR /workspace
