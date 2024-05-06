# Домашнее задание: Vagrant стенд для NFS

  Цель работы: научиться разворачивать сервис NFS и подключать к нему клиентов.

  Для выполнения домашнего задания использовать прилагаемую методичку.
  
Что нужно сделать?

  - создать две виртуальные машины: сервер и клиент;
  - на сервере подготовить и экспортировать директорию для подключения;
  - создать в директории папку upload с правами на запись;
  - обеспечить автоматическое монтирование директории на клиенте (fstab или autofs);
  - соблюсти требования для NFS: NFSv3 по UDP, включенный firewall.
  - создать два bash-скрипта, `nfss_script.sh` - для конфигурирования сервера и `nfsc_script.sh` - для конфигурирования клиента, 
  в которых описать bash-командами ранее выполненные шаги. Альтернатива - воспользоваться Ansible. 
  
	Задание со звездочкой*

  Настроить аутентификацию через KERBEROS (NFSv4)


# Выполнение


## Создаём две виртуальные машины: сервер и клиент

Создаю в домашней директории Vagrantfile, в тело данного файла копирую содержимое из прилагаемой методички.
 
Собираю стенд командой:

``` [nur@test hw-4]$ vagrant up ```

 С текущей конфигурацией Vagrantfile получаю две проблемы:

 - В скачиваемом Vagrant - box "centos/7' version '2004.01" не найдены гостевые дополнения:

 > ==> nfss: Machine booted and ready!
 > [nfss] No Virtualbox Guest Additions installation found.
 
 - Не найден пакет обновления "kernel-devel-3.10.0-1127.el7.x86_64": 
 
 > yum install -y kernel-devel-`uname -r` 

 > Stdout from the command:

 > Loaded plugins: fastestmirror
 > Loading mirror speeds from cached hostfile
 > * base: centos-mirror.rbc.ru
 > * extras: centos-mirror.rbc.ru
 > * updates: centos-mirror.rbc.ru
 > No package kernel-devel-3.10.0-1127.el7.x86_64 available.


 > Stderr from the command:

 > Error: Nothing to do
 
 В результате, vagrant останавливает работу, созданная машина "nfss" не имеет ip - адреса и отклоняет 
 подключения по ssh из vagrant.
 Подключившись к машине из терминала vbox, попробовал подключить репозиторий EPEL и обновить все системные приложения.
 Данный шаг устранил проблемы, машина "nfss" создалась но, потребывалось обновить системые пакеты и на машине "nfsс".
 
 В результате чего, было принято решение отредактировать vagrantfile, изменив текущий box "centos/7' version '2004.01" на "generic/centos7".
 Что в свою очередь позволило собрать требуемые машины.
 
 ## Подготавливаем и экспортируем директорию на сервере

 Подключаюсь к стенду:
 
``` [nur@test hw-6]$ vagrant ssh nfss ```

 Переходим в рута и устанавливаем необходимые утилиты:
 
``` [vagrant@nfss ~]$ sudo -i ```

``` [root@nfss ~]# yum install -y nfs-utils ```
 
 Смотрим состояние firewall и разрешаем доступ сервисам nfs:

``` [root@nfss ~]# systemctl status firewalld ```

 > ● firewalld.service - firewalld - dynamic firewall daemon

 >   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
 
 >   Active: active (running) since Sun 2024-05-05 11:57:36 UTC; 2h 46min ago
 
   
``` [root@nfss ~]# firewall-cmd --add-service="nfs3" \ ```

``` > --add-service="rpc-bind" \ ```

``` > --add-service="mountd" \ ```

``` > --permanent ```

 > success
 
 Пересчитываем конфигурацию firewall:
 
``` [root@nfss ~]# firewall-cmd --reload ```

 > success

 Сохраняем текущие правила и делаем их постоянными:
 
 ``` [root@nfss ~]# firewall-cmd --runtime-to-permanent ```
 
 > success
 
 Включаем сервер NFS:
 
``` [root@nfss ~]# systemctl enable nfs --now ```

 > Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
 
 Проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,  20048/tcp, 111/udp, 111/tcp:
 
``` [root@nfss ~]# ss -tnplu ```

``` 
Netid  State      Recv-Q Send-Q                           Local Address:Port                                          Peer Address:Port              
udp    UNCONN     0      0                                    127.0.0.1:766                                                      *:*                   users:(("rpc.statd",pid=25606,fd=5))
udp    UNCONN     0      0                                            *:2049                                                     *:*                  
udp    UNCONN     0      0                                            *:770                                                      *:*                   users:(("rpcbind",pid=25613,fd=7))
udp    UNCONN     0      0                                    127.0.0.1:323                                                      *:*                   users:(("chronyd",pid=675,fd=5))
udp    UNCONN     0      0                                            *:68                                                       *:*                   users:(("dhclient",pid=2392,fd=6))
udp    UNCONN     0      0                                            *:20048                                                    *:*                   users:(("rpc.mountd",pid=25625,fd=7))
udp    UNCONN     0      0                                            *:111                                                      *:*                   users:(("rpcbind",pid=25613,fd=6))
udp    UNCONN     0      0                                            *:51605                                                    *:*                  
udp    UNCONN     0      0                                            *:35028                                                    *:*                   users:(("rpc.statd",pid=25606,fd=8))
udp    UNCONN     0      0                                         [::]:2049                                                  [::]:*                  
udp    UNCONN     0      0                                         [::]:770                                                   [::]:*                   users:(("rpcbind",pid=25613,fd=10))
udp    UNCONN     0      0                                         [::]:36103                                                 [::]:*                  
udp    UNCONN     0      0                                        [::1]:323                                                   [::]:*                   users:(("chronyd",pid=675,fd=6))
udp    UNCONN     0      0                                         [::]:20048                                                 [::]:*                   users:(("rpc.mountd",pid=25625,fd=9))
udp    UNCONN     0      0                                         [::]:111                                                   [::]:*                   users:(("rpcbind",pid=25613,fd=9))
udp    UNCONN     0      0                                         [::]:50132                                                 [::]:*                   users:(("rpc.statd",pid=25606,fd=10))
tcp    LISTEN     0      64                                           *:2049                                                     *:*                  
tcp    LISTEN     0      128                                          *:48812                                                    *:*                   users:(("rpc.statd",pid=25606,fd=9))
tcp    LISTEN     0      128                                          *:111                                                      *:*                   users:(("rpcbind",pid=25613,fd=8))
tcp    LISTEN     0      128                                          *:20048                                                    *:*                   users:(("rpc.mountd",pid=25625,fd=8))
tcp    LISTEN     0      128                                          *:22                                                       *:*                   users:(("sshd",pid=1137,fd=3))
tcp    LISTEN     0      64                                           *:34936                                                    *:*                  
tcp    LISTEN     0      100                                  127.0.0.1:25                                                       *:*                   users:(("master",pid=1273,fd=13))
tcp    LISTEN     0      64                                        [::]:2049                                                  [::]:*                  
tcp    LISTEN     0      128                                       [::]:111                                                   [::]:*                   users:(("rpcbind",pid=25613,fd=11))
tcp    LISTEN     0      128                                       [::]:20048                                                 [::]:*                   users:(("rpc.mountd",pid=25625,fd=10))
tcp    LISTEN     0      128                                       [::]:22                                                    [::]:*                   users:(("sshd",pid=1137,fd=4))
tcp    LISTEN     0      64                                        [::]:36377                                                 [::]:*                  
tcp    LISTEN     0      128                                       [::]:55231                                                 [::]:*                   users:(("rpc.statd",pid=25606,fd=11))
``` 

 Создаем директорию:
 
``` [root@nfss ~]# mkdir -p /srv/share/uplоad ```

 Задаём владельца рекурсивно для всех подкаталогов:
 
``` [root@nfss ~]# chown -R nfsnobody:nfsnobody /srv/share ```

 Задаём права на полный доступ для всех групп пользователей:
 
``` [root@nfss ~]# chmod 0777 /srv/share/upload ```

 Создаём в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию:
 
``` [root@nfss ~]# cat << EOF > /etc/exports ```

 > /srv/share 192.168.56.11/32(rw,sync,root_squash)
 
 > EOF

 Экспортируем и проверяем ранее созданную директорию:
 
``` [root@nfss ~]# exportfs -r ```

``` [root@nfss ~]# exportfs -s ```
 > /srv/share  192.168.56.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
 
 ## Обеспечить автоматическое монтирование директории на клиенте (fstab или autofs) и соблюсти требования для NFS: NFSv3 по UDP, включенный firewall.
    
 
 Подключаюсь к стенду:
 
``` [nur@test hw-6]$ vagrant ssh nfss ```

 Переходим в рута и устанавливаем необходимые утилиты:
 
``` [vagrant@nfss ~]$ sudo -i ```

``` [root@nfss ~]# yum install -y nfs-utils ```

 Смотрим состояние firewall: 

``` [root@nfss ~]# systemctl status firewalld ```

 > ● firewalld.service - firewalld - dynamic firewall daemon
 
 >   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
	 
 >   Active: active (running) since Sun 2024-05-05 12:18:33 UTC; 4h 46min ago
 
 Добавляем в __/etc/fstab строку:

``` [root@nfsc ~]# echo "192.168.56.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab ```

 Далее выполняем:
 
``` [root@nfsc ~]# systemctl daemon-reload ```

``` [root@nfsc ~]# systemctl restart remote-fs.target```
 
 Заходим в директорию /mnt и проверяем успешность монтирования папки:
 
``` [root@nfsc ~]# cd /mnt ```

``` [root@nfsc mnt]# mount | grep mnt ```

```
systemd-1 on /mnt type autofs (rw,relatime,fd=27,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=107783)
192.168.56.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,
timeo=11,retrans=3,sec=sys,mountaddr=192.168.56.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.56.10)
```
 ### Проверка работоспособности
 
 Заходим на сервер, в каталоге /srv/share/upload создаем тестовый файл "check_file":

``` [root@nfss ~]# cd /srv/share/upload ```

``` [root@nfss upload]# touch check_file ```

``` [root@nfss upload]# ls ```
 > check_file

Заходим на клиент , в каталоге /mnt/upload наблюдаем тестовый файл "check_file", и создаём "client_file":

``` [vagrant@nfsc ~]$ cd /mnt/upload ```

``` [vagrant@nfsc upload]$ ls ```

 > check_file
 
``` [vagrant@nfsc upload]$ touch client_file ```

``` [vagrant@nfsc upload]$ ls ```

 > check_file  client_file
 
 С правами всё хорошо.
 
 Перезагружаем клиент и заходим в каталог /mnt/upload:
 
``` [root@nfsc ~]# shutdown -r now ```

``` [vagrant@nfsc ~]$ cd /mnt ```

``` [vagrant@nfsc mnt]$ ls ```

 > virtualbox
 
 Созданных файлов нет, после перезагрузки папка не подмонтировалась.
 Проверим состояние "remote-fs.target":
 
``` [vagrant@nfsc ~]$ systemctl status remote-fs.target ```
````
● remote-fs.target - Remote File Systems
   Loaded: loaded (/usr/lib/systemd/system/remote-fs.target; disabled; vendor preset: enabled)
   Active: inactive (dead) since Sun 2024-05-05 18:05:09 UTC; 14min ago
````
 
 Как видим - модуль не активен, создадим симлинк на него:
 
``` [root@nfsc ~]# systemctl enable remote-fs.target ```

 > Created symlink from /etc/systemd/system/multi-user.target.wants/remote-fs.target to /usr/lib/systemd/system/remote-fs.target.
 
 После перезагрузки папка подмонтировалась автоматически:
 
``` [vagrant@nfsc ~]$ cd /mnt/upload ```

``` [vagrant@nfsc upload]$ ls ```

 > check_file  client_file
 
 Заходим на сервер, перезагружаемся, проверяем наличие файлов в каталоге /srv/share/upload/, 
 статус сервера NFS, статус Firewall, проверяем экспорты и RPC:
 
``` [vagrant@nfss ~]$ cd /srv/share/upload ```

``` [vagrant@nfss upload]$ ls ```

 > check_file  client_file
 
``` [vagrant@nfss upload]$ systemctl status firewalld ```
```
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2024-05-06 07:58:28 UTC; 31min ago
     Docs: man:firewalld(1)
 Main PID: 714 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─714 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid
```
		   
``` [root@nfss ~]# systemctl status nfs ```
```
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Mon 2024-05-06 07:58:37 UTC; 50min ago
```
``` [root@nfss ~]# exportfs -s ```

 > /srv/share  192.168.56.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
 
``` [root@nfss ~]# showmount -a 192.168.56.10 ```

 > All mount points on 192.168.56.10:
 
 > 192.168.56.11:/srv/share
 
 Возвращаемся на клиент, перезагружаемся, проверяем статус монтирования, работу RPC,
 создаём теcтовый фаил:
 
``` [root@nfsc ~]# cd /mnt/upload ```
 
``` [root@nfsc upload]# mount | grep mnt ```
```
systemd-1 on /mnt type autofs (rw,relatime,fd=35,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=9715)
192.168.56.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,
mountaddr=192.168.56.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.56.10)
```
``` [root@nfsc ~]# showmount -a 192.168.56.10 ```

 > All mount points on 192.168.56.10:
 
 > 192.168.56.11:/srv/share
 
``` [root@nfsc upload]# ls ```
 > check_file  client_file
 
``` [root@nfsc upload]# touch final_check ```

``` [root@nfsc upload]# ls ```

 > check_file  client_file  final_check
 
 Проверки пройдены.

### Создаём bash-скрипты
 
 Создаём  два bash-скрипта, `nfss_script.sh` - для конфигурирования сервера и `nfsc_script.sh` - для конфигурирования клиента.
 
 Дополним Vagrantfile конструкцией "vm.provision "shell"" как для сервера так и для клиента
 c указанием файлов-скриптов:
 ```
  config.vm.define "nfss" do |nfss| 
 nfss.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
 nfss.vm.hostname = "nfss" 
 nfss.vm.provision "shell", path: "nfss_script.sh"  end 
 config.vm.define "nfsc" do |nfsc| 
 nfsc.vm.network "private_network", ip: "192.168.56.11",  virtualbox__intnet: "net1" 
 nfsc.vm.hostname = "nfsc" 
 nfsc.vm.provision "shell", path: "nfsc_script.sh"  end 
end 
```
 После сборки получаем смонтированную директорию и повторяем проверку работоспособности.
