 参考[stratus](https://github.com/planetlabs/stratus)
# 部署
docker-compse build  
docker-compose up -d
# Sentinel 哨兵模式（高可用）
部署主库请参考其他部署redis的文档，下面的文档仅仅描述
## 哨兵模式部署架构图
![Redis Sentinel 简单架构图](https://note.youdao.com/yws/res/4649/C2AAD6A82B9B43B4BEF693A87BBC6F3D)

本架构使用“主从从”的方式同步数据，减轻主库的同步压力

## 建立Redis从库
复制原来的配置文件

在192.168.132.129的机器上，增加以下配置：

```
slaveof 192.168.132.129 6379
```
表示作为主库的从库


在192.168.132.130的机器上，增加以下配置：

```
slaveof 192.168.132.129 6378
```
表示作为主库从库的从库

## 启动从库命令

```
redis-server <从库配置文件>
```


## 建立哨兵集群
因为需要高可用，哨兵程序也需要高可用，不能只有一个哨兵程序，所以每台服务器上配置两个哨兵程序保持高可用，哨兵程序间会通讯互相会知道状态

修改 sentinel.conf 文件
找到 sentinel myid，如下所示（id会不一样）

```
sentinel myid f9de0333fd8944f959c096cb0c04826c37879c22
```
修改id值，可以只是修改最后两位数字，只需要保持每个哨兵程序的不一样就可以了

新增配置项：

```
rename-command SHUTDOWN REDIS_SHUTDOWN
sentinel monitor mymaster 192.168.132.129 6379 2
```
其中2代表需要有两个哨兵选举某一个从库可以成为主库，才代表选举成功

其余三个哨兵配置也需要修改根据上面所述进行修改
并需要修改端口，如：

```
port 26379
```
同一个服务器哨兵端口需不一致

## 启动哨兵程序

```
redis-sentinel <哨兵配置文件>
```

例如：
```
redis-sentinel sentinel.conf
```

## Sentinel命令
- SENTINEL masters 显示被监控的所有master以及它们的状态.
- SENTINEL master <master name> 显示指定master的信息和状态
- SENTINEL slaves <master name> 显示指定master的所有slave以及它们的状态
- SENTINEL get-master-addr-by-name <master name> 返回指定master的ip和端口，如果正在进行failover或者failover已经完成，将会显示被提升为master的slave的ip和端口
- SENTINEL reset <pattern> 重置名字匹配该正则表达式的所有的master的状态信息，清楚其之前的状态信息，以及slaves信息
- SENTINEL failover <master name> 强制sentinel执行failover，并且不需要得到其他sentinel的同意。但是failover后会将最新的配置发送给其他sentinel
- SENTINEL MONITOR <name> <ip> <port> <quorum> 这个命令告诉sentinel去监听一个新的master
- SENTINEL REMOVE <name> 命令sentinel放弃对某个master的监听
- SENTINEL SET <name> <option> <value> 这个命令很像Redis的CONFIG SET命令，用来改变指定master的配置。支持多个<option><value>。例如以下实例：SENTINEL SET objects-cache-master down-after-milliseconds 1000


## Sentinel 日志解析

```
+reset-master <instance details> -- 当master被重置时.
+slave <instance details> -- 当检测到一个slave并添加进slave列表时.
+failover-state-reconf-slaves <instance details> -- Failover状态变为reconf-slaves状态时
+failover-detected <instance details> -- 当failover发生时
+slave-reconf-sent <instance details> -- sentinel发送SLAVEOF命令把它重新配置时
+slave-reconf-inprog <instance details> -- slave被重新配置为另外一个master的slave，但数据复制还未发生时。
+slave-reconf-done <instance details> -- slave被重新配置为另外一个master的slave并且数据复制已经与master同步时。
-dup-sentinel <instance details> -- 删除指定master上的冗余sentinel时 (当一个sentinel重新启动时，可能会发生这个事件).
+sentinel <instance details> -- 当master增加了一个sentinel时。
+sdown <instance details> -- 进入SDOWN状态时;
-sdown <instance details> -- 离开SDOWN状态时。
+odown <instance details> -- 进入ODOWN状态时。
-odown <instance details> -- 离开ODOWN状态时。
+new-epoch <instance details> -- 当前配置版本被更新时。
+try-failover <instance details> -- 达到failover条件，正等待其他sentinel的选举。
+elected-leader <instance details> -- 被选举为去执行failover的时候。
+failover-state-select-slave <instance details> -- 开始要选择一个slave当选新master时。
no-good-slave <instance details> -- 没有合适的slave来担当新master
selected-slave <instance details> -- 找到了一个适合的slave来担当新master
failover-state-send-slaveof-noone <instance details> -- 当把选择为新master的slave的身份进行切换的时候。
failover-end-for-timeout <instance details> -- failover由于超时而失败时。
failover-end <instance details> -- failover成功完成时。
switch-master <master name> <oldip> <oldport> <newip> <newport> -- 当master的地址发生变化时。通常这是客户端最感兴趣的消息了。
+tilt -- 进入Tilt模式。
-tilt -- 退出Tilt模式。
```

TILT 模式
> redis sentinel非常依赖系统时间，例如它会使用系统时间来判断一个PING回复用了多久的时间。
然而，假如系统时间被修改了，或者是系统十分繁忙，或者是进程堵塞了，sentinel可能会出现运行不正常的情况。
当系统的稳定性下降时，TILT模式是sentinel可以进入的一种的保护模式。当进入TILT模式时，sentinel会继续监控工作，但是它不会有任何其他动作，它也不会去回应is-master-down-by-addr这样的命令了，因为它在TILT模式下，检测失效节点的能力已经变得让人不可信任了。
如果系统恢复正常，持续30秒钟，sentinel就会退出TITL模式






