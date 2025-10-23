# 1
we can get the information of the queue configuration through 
```
sinfo
```
or
```
sinfo -s
```
the result will be like
```
[lcl_uotcscd71s1408@teach-login01 q6]$ sinfo -s
PARTITION AVAIL  TIMELIMIT   NODES(A/I/O/T) NODELIST
debug        up    4:00:00        0/63/1/64 teach[01-64]
compute*     up 1-00:00:00        0/63/1/64 teach[01-64]
[lcl_uotcscd71s1408@teach-login01 q6]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug        up    4:00:00      1 drain* teach37
debug        up    4:00:00     63   idle teach[01-36,38-64]
compute*     up 1-00:00:00      1 drain* teach37
compute*     up 1-00:00:00     63   idle teach[01-36,38-64]
```
here the debug, and the compute will be the queues

# 2
for checking the nodes, the same thing above, we can see that the denbug and compute has their own number of nodes,both the debug and compute queue has 64 nodes

# 3
still using the sinfo we will see the time limit will be 4hours for debug and 1day for compute.
the debug has 63 idle and one drain, so is  the compute
# 4
teach 37 node is currently drain none of the nodes are allocated, other 63 nodes are idle