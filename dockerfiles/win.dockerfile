#   Copyright 2018-2022 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG GOLANG_IMAGE=golang:latest
FROM ${GOLANG_IMAGE} AS golang
ARG GO111MODULE=auto
ENV GO111MODULE=$GO111MODULE \
    chocolateyUseWindowsCompression=false
# Install make and gcc
# We install an older version of MinGW to workaround issues in CGO;
# see https://github.com/golang/go/issues/51007
RUN  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')); \
     choco feature disable --name showDownloadProgress; \
     choco install -y make; \
     choco install -y mingw --version 10.2.0 --allow-downgrade
