FROM python:3.8 as mkl

RUN curl -s -L -o -  https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB | apt-key add - \
  && curl -s -L -o /etc/apt/sources.list.d/intelproducts.list https://apt.repos.intel.com/setup/intelproducts.list

RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free\n\
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free\n\
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free\n\
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free\n" > /etc/apt/sources.list

RUN apt update \
  && apt-get install -y gfortran intel-mkl-2020.4-912 \
  && rm -rf /var/lib/apt/lists/*

RUN echo "[mkl]\n\
library_dirs = /opt/intel/compilers_and_libraries_2020/linux/mkl/lib/intel64\n\
include_dirs = /opt/intel/compilers_and_libraries_2020/linux/mkl/include\n\
libraries = mkl_rt" > ~/.numpy-site.cfg

ENV LD_LIBRARY_PATH /opt/intel/compilers_and_libraries_2020/linux/mkl/lib/intel64

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
  && python3.8 -m pip install --upgrade pip \
  && pip install numpy scipy --no-binary :all: --force-reinstall -t .

RUN mkdir /wheels \
  && find ~/.cache/pip/ -name '*.whl' | xargs -n 1 -i mv {} /wheels

FROM python:3.8

WORKDIR /srv

COPY --from=mkl /opt/intel/compilers_and_libraries_2020.4.304 /opt/intel/compilers_and_libraries_2020.4.304
COPY --from=mkl /root/.numpy-site.cfg /root/.numpy-site.cfg
COPY --from=mkl /wheels /wheels

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
  && python3.8 -m pip install --upgrade pip \
  && pip install /wheels/*.whl

ENV LD_LIBRARY_PATH /opt/intel/compilers_and_libraries_2020/linux/mkl/lib/intel64

CMD python
