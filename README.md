# docker-greenplum7

Docker for GreenPlum v7.1.0.

During startup, GreenPlum version 7.1.0 is deployed with a primary coordinator (master in previous GP versions) and the required number of segments (specified by the SEG_NUM parameter during image building). It should be noted that segments are created without mirrors, considering local redundancy, to reduce disk space consumption.
The container runs on the Debian 12 slim version.

## Build images
The parameter SEG_NUM determines the number of segments with which the database will be deployed.
```
$ docker build --build-arg SEG_NUM=4 -t as2sp/greenplum7:latest .
```

## Usage
```
$ docker run --name greenplum -p 5432:5432 -d as2sp/greenplum7:latest
```
