FROM ubuntu:22.04
USER root
ENV PATH=/opt/miniconda/bin:/opt/miniconda/envs/py39/bin:/opt/snap/bin:$PATH
RUN apt-get update && apt-get install -y wget libgfortran5 libfftw3-dev fonts-dejavu openjdk-8-jre curl jq vim git && \
  apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  curl -LO "http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" && \
  bash Miniconda3-latest-Linux-x86_64.sh -p /opt/miniconda -b && \
  rm Miniconda3-latest-Linux-x86_64.sh && \
  conda update -c conda-forge -y conda && \
  conda create -n py39 -c conda-forge python=3.9 pip mamba && \
  # install isce2
  mamba install -c conda-forge -y isce2 && \
  # install LiCSBAS \
  cd /opt && git clone https://github.com/comet-licsar/LiCSBAS && \
  mamba install -c conda-forge -y --file LiCSBAS/LiCSBAS_requirements.txt && \
  echo "export PATH=\$PATH:/opt/LiCSBAS/bin" >> ~/.bashrc && \
  echo "export PYTHONPATH=\$PYTHONPATH:/opt/LiCSBAS/LiCSBAS_lib" >> ~/.bashrc && \
  # install LiCSAR_proc
  git clone https://github.com/comet-licsar/licsar_proc && \
  mamba install -c conda-forge -y --file licsar_proc/requirements.txt && \
  LiCSARpath="/opt/licsar_proc" && \
  echo "export LiCSARpath=/opt/licsar_proc" >> ~/.bashrc && \
  echo "export PATH=\$PATH:\$LiCSARpath/bin:\$LiCSARpath/bin/orig:\$LiCSARpath/bin/scripts:\$LiCSARpath/python" >> ~/.bashrc && \
  echo "export PYTHONPATH=\$PYTHONPATH:\$LiCSARpath/python:\$LiCSARpath/python/LiCSAR_lib:\$LiCSARpath/python/LiCSAR_db" >> ~/.bashrc && \
  echo "source activate py39" >> ~/.bashrc && \
  # install snaphu
  apt-get update && apt-get install -y build-essential && \
  wget https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/snaphu-v2.0.5.tar.gz && tar -xzf snaphu-v2.0.5.tar.gz && rm snaphu-v2.0.5.tar.gz && \
  cd snaphu-v2.0.5/src && make -f Makefile && mkdir -p /usr/local/man/man1 && make install && cd
## Installing SNAP9
ENV \
URL="http://step.esa.int/downloads/9.0/installers" \
TBX="esa-snap_sentinel_unix_9_0_0.sh"
RUN echo -e "deleteAllSnapEngineDir\$Boolean=false\ndeleteOnlySnapDesktopDir\$Boolean=false\nexecuteLauncherWithPythonAction\$Boolean=false\nforcePython\$Boolean=false\npythonExecutable=/usr/bin/python\nsys.adminRights\$Boolean=true\nsys.component.RSTB\$Boolean=false\nsys.component.S1TBX\$Boolean=true\nsys.component.S2TBX\$Boolean=true\nsys.component.S3TBX\$Boolean=false\nsys.component.SNAP\$Boolean=true\nsys.installationDir=/opt/snap\nsys.languageId=en\nsys.programGroupDisabled\$Boolean=false\nsys.symlinkDir=/usr/local/bin" >/tmp/snap.varfile
RUN wget $URL/$TBX -O /opt/$TBX && chmod +x /opt/$TBX && sh /opt/esa-snap_sentinel_unix_9_0_0.sh -q -varfile /tmp/snap.varfile && rm /opt/esa-snap_sentinel_unix_9_0_0.sh && sed -i 's+jdkhome="./jre"+jdkhome="$JAVA_HOME"+g' /opt/snap/etc/snap.conf && echo -Xmx14G > /opt/snap/bin/gpt.vmoptions && rm -rf /opt/snap/jre && find /opt/snap -name "*-ui.jar" | while read modules ; do rm -f $modules ; done 
COPY snap.auxdata.properties /opt/snap/etc/snap.auxdata.properties
COPY snap.properties /opt/snap/etc/snap.properties
