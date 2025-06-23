## Building instructions

### On a machine with docker
```
cd <portfolder>
cp -r src build
cd build

./docker-setup.txt port-build
```

In the docker container:
``
cd build
./build.txt
```

Back on the host machine:
```
cd <portfolder>
./build/retrieve-products.txt ./build .
``
