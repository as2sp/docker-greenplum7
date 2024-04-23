# docker-greenplum7

Docker for GreenPlum 7.

While running this image, GreenPlum version 7.1.0 is deployed with a primary coordinator (master in previous GP versions) and the required number of segments (specified by the SEG_NUM parameter during image building). It should be noted that segments are created without mirrors, considering local redundancy, to reduce disk space consumption.
The container runs on Debian 12 slim version.

## Run
You can directly install and run the Docker using this command. In this case, a pre-built image from Docker Hub will be deployed, it will have 4 segments. Default username/password: gpadmin/gppass
```
docker run --name greenplum -p 5432:5432 -d as2sp/greenplum7
```

## Build images
The parameter SEG_NUM determines the number of segments with which the database will be deployed.
```
docker build --build-arg SEG_NUM=4 -t as2sp/greenplum7 .
```

## Usage
```
docker run --name greenplum -p 5432:5432 -d as2sp/greenplum7
```

## Save image
```
docker save as2sp/greenplum7 as2sp_greenplum7.tar
```
or with compression:
```
docker save as2sp/greenplum7 | gzip > as2sp_greenplum7.tar.gz
```

## Load image
```
docker load -i as2sp_greenplum7.tar
```
or if the image was compressed:
```
docker load -i as2sp_greenplum7.tar.gz
```
