# escape=`
FROM dockereng/go-crypto-swap:windows-go1.10.5-cd940a7
ENV AUTO_GOPATH=1
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Invoke-WebRequest 'https://raw.githubusercontent.com/jhowardmsft/docker-tdmgcc/master/gcc.zip' -OutFile C:\gcc.zip; `
    Expand-Archive C:\gcc.zip C:\gcc; `
    Remove-Item C:\gcc.zip
RUN Invoke-WebRequest 'https://raw.githubusercontent.com/jhowardmsft/docker-tdmgcc/master/runtime.zip' -OutFile C:\runtime.zip; `
    Expand-Archive C:\runtime.zip C:\gcc -Force; `
    Remove-Item C:\runtime.zip
RUN Invoke-WebRequest 'https://raw.githubusercontent.com/jhowardmsft/docker-tdmgcc/master/binutils.zip' -OutFile C:\binutils.zip; `
    Expand-Archive C:\binutils.zip C:\gcc -Force; `
    Remove-Item C:\binutils.zip
RUN setx /M Path "$Env:Path`;C:\gcc\bin" | Out-Null
ENTRYPOINT ["go", "build"]
