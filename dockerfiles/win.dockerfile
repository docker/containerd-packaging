ARG  GOLANG_IMAGE
FROM ${GOLANG_IMAGE}
ENV  chocolateyUseWindowsCompression=false
# Install make and gcc
RUN  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')); \
     choco feature disable --name showDownloadProgress; \
     choco install -y make mingw
