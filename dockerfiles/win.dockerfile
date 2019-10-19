ARG  GOVERSION
FROM dockereng/go-crypto-swap:windows-go${GOVERSION}
ENV  chocolateyUseWindowsCompression=false
# Install make
RUN  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')); \
     choco feature disable --name showDownloadProgress; \
     choco install -y make
