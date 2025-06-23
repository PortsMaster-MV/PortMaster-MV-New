FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update

RUN apt install -y --no-install-recommends \
        whiptail ca-certificates apt-utils nano wget curl \
        lsb-release

RUN apt install -y --no-install-recommends \
        make gcc g++

RUN apt-get install -y --no-install-recommends \
        clang lld git cmake ninja-build lsb-release libsdl2-dev \
        libpng-dev libsdl2-net-dev libzip-dev zipcmp zipmerge \
        ziptool nlohmann-json3-dev libtinyxml2-dev libspdlog-dev \
        libboost-dev libopengl-dev libogg-dev libvorbis-dev \
        libstdc++-10-dev

# newer version of cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.31.3/cmake-3.31.3-linux-`uname -m`.sh
RUN chmod a+x ./cmake-3.31.3-linux-`uname -m`.sh
RUN ./cmake-3.31.3-linux-`uname -m`.sh --prefix=/usr/local --exclude-subdir --skip-license

WORKDIR "/root"

CMD ["bash"]
