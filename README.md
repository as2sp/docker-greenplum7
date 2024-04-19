# docker-greenplum7

## Build images
The parameter SEG_NUM determines the number of segments with which the database will be deployed.
```
$ docker build --build-arg SEG_NUM=4 -t as2sp/greenplum7:latest .
```

## Usage
```
$ docker run --name greenplum -p 5432:5432 -d as2sp/greenplum7:latest
```
