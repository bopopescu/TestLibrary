# -*- coding: utf-8 -*- 

import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTNetConfig import ATTNetConfig
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log
  
REMOTE_PORT = REMOTE_PORTS.get('NetConfig')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600

class NetConfig():
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}  
    
    
    def _register_alias(self, alias, name, mac_address, remote_url):
        
        # 对别名判断做了修改 zsj 2013-3-28
        # 改成以别名为健（当前要求别名唯一） change by yzm @ 20130328
        # 因前面已经保证了alias唯一，则直接对alias进行赋值（赋新值可保证网卡信息为最新的信息）
        self.dict_alias[alias] = ((name, mac_address), remote_url)

    def _is_init(self, name_or_mac, remote_url, alias):
        """
        return alias
        """
        # 先判断别名是否被使用过
        _value  = self.dict_alias.get(alias)
        if _value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url以及name或者mac）
            if remote_url in _value and name_or_mac in _value[0]:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            # 如果没被使用过，需判断当前的对象是否曾经被初始化过
            for key, tuple_value in self.dict_alias.items():
                if remote_url in tuple_value and name_or_mac in tuple_value[0]:
                    # 如果相符，则可以直接返回_key（只要找到即可返回）
                    return key 

        # 两种情况都不包含，则返回None
        return None
            
       
    
    def init_nic_card(self, alias, name_or_mac ,remote_url=False):
        """
        功能描述：初始化网卡，为网卡配置别名；
        
        注意：用MAC地址来初始化，禁用网卡之后，启用网卡会有问题。
        需要在网卡禁用之后，再启用网卡的，请不要用MAC进行初始化，可以用网卡名称实现初始化。
        
        参数：
        alias:别名； 
        name_or_mac:网卡名称或者是MAC地址； 
        remote_url：是否要进行远程控制（默认不进行远程），remote_url格式为：http://remote_IP； 
        可以用以下的几种方式进行初始化。请设置不同的别名，切换的时候用别名进行切换。 
        
        返回值：无
        
        Example:
        | Init Nic Card  | One | 本地连接1         |                          
        | Init Nic Card  | two | 本地连接1         | http://10.10.10.84 |
        | Init Nic Card  |  3  | 44-37-E6-99-7C-B9 |                          
        | Init Nic Card  |  4  | 44:37:E6:99:7C:B9 |                          
        """
        # 输入的name_or_mac做转换，除去格式的差异
        name_or_mac = modified_name_or_mac(name_or_mac)
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._is_init(name_or_mac, remote_url, alias)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            name, mac_address = auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(name_or_mac, remote_url, alias)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTNetConfig(name_or_mac)
            
            name = reallib.name
            mac_address = reallib.mac_address
                
        tag = self._cache.register(reallib, alias) 
        self._register_alias(alias, name, mac_address, remote_url)
        
        return name, mac_address
    
    def _current_remotelocal(self):
        if not self._cache.current:
            raise RuntimeError('No remotelocal is open')
        return self._cache.current      
    
    def switch_nic_card(self,alias):
        """
        功能描述：切换当前所使用的网卡。
        
        参数：
        alias：别名。
        
        返回值：无
        
        Example:
        | Init Nic Card                     | 1           | 本地连接1 |
        | Config Nic To Ipv4 Static Address | 99.99.9.9   |
        | Init Nic Card                     | 2           | 本地连接1 | http://10.10.10.84 |
        | Config Nic To Ipv4 Static Address | 88.88.188.8 |
        | Switch Nic Card                   | 1           |
        | Config Nic To Ipv4 Dhcp           |
        | Switch Nic Card                   | 2           |
        | Config Nic To Ipv4 Dhcp           |
        """
        try:
            cls=self._cache.switch(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'成功切换到别名为：%s 的网卡下，后续Netconfig操作都是针对该网卡，直到下一个初始化或切换动作' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)
        
    def get_nic_ipv4_address(self):
        '''
        功能描述：获取当前网卡的IPv4地址及子网掩码。
        
        参数：无。
        
        返回值：当前网卡的IPv4地址和子网掩码，如果当前网卡未启用或连接断开，返回None。\n
                返回值为list形式，由ip/subnet构成，例如[u'172.16.28.21/255.255.254.0']
                
        
        Example:
        | Init Nic Card                     | 1                    | 本地连接1 |
        | ${ret}                            | Get Nic Ipv4 Address |
        | Config Nic To Ipv4 Static Address | 99.99.9.9            |
        | ${ret2}                           | Get Nic Ipv4 Address |
        '''     
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_address()
        return ret
    
    def config_nic_to_ipv4_static_address(self, ip_address, ip_subnet='255.255.255.0', gateway = ''):
        '''
        功能描述：配置当前网卡IP为IPV4的静态地址。
        
        参数：
        ip_address:当前网卡IP地址；
        ip_subnet:子网掩码（默认为255.255.255.0）；
        gateway:网关，默认为空，即不配置网关；
        
        返回值：无
        
        Example:
        | Init Nic Card                     | 1            | 本地连接1   |
        | Config Nic To Ipv4 Static Address | 99.99.9.9    | 255.255.0.0 | 99.99.9.1 |
        | Config Nic To Ipv4 Static Address | 192.168.1.50 |
        | Config Nic To Ipv4 Static Address | 99.99.9.9    | 255.255.0.0 |  #不配置网关   |
        '''
        # 检查IP地址合法性
        if not check_ipaddr_validity(ip_address):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_to_ipv4_static_address(ip_address, ip_subnet, gateway)
    
    def config_nic_ipv4_dns_server(self, dns = ''):
        '''
        功能描述：配置当前网卡的dns服务器地址。
        
        注意：若当前网卡为DHCP方式，参数为默认值或字符串"None"时，DNS配置为自动获取，否则配置为手动方式的DNS服务器；
              若当前网卡为静态IP方式，参数为默认值时，不修改当前DNS配置，参数为字符串"None"时，清除当前DNS列表，否则配置手动方式的DNS服务器；
        
        参数：
        dns： 由DNS服务器ipv4地址组成的列表，即使是只配置一个地址，也需要采用列表形式。可以配置为字符串"None"，默认为空;
            
        返回值：无
        
        Example:
        | Init Nic Card              | 1            | 本地连接1      |
        | ${dns_list}                | Create List  | 10.10.28.100   |
        | Config Nic Ipv4 Dns Server |              | 
        | Config Nic Ipv4 Dns Server |  None        |
        | Config Nic Ipv4 Dns Server |  ${dns_list} | 
        '''
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_ipv4_dns_server(dns)

    def config_nic_to_ipv4_dhcp(self):
        '''
        功能描述：配置当前网卡为DHCP模式
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card           | 1 | 本地连接1 |
        | Config Nic To Ipv4 Dhcp |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_to_ipv4_dhcp()
    
    #添加获取MAC地址的关键字 add by shenlige 2013-3-12
    def get_nic_mac_address(self):
        '''
        功能描述：获取当前网卡的MAC地址，网卡未启用时，返回None
        
        参数：无
        
        返回值：mac地址
        
        Example:
        | Init Nic Card  | 1                     | 本地连接1 |
        | ${macaddr}     | Get Nic Mac Address   |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_mac_address()
        return ret
    
    #获取网关IP地址
    def get_nic_ipv4_gateway(self):
        '''
        功能描述：获取当前网卡的网关地址，网卡未启用、连接断开或连接受限时返回为None
        
        参数：无
        
        返回值：网关IP地址。
        
        Example:
        | Init Nic Card  | 1                     | 本地连接1 |
        | ${gateway}     | Get Nic Ipv4 Gateway  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_gateway()
        return ret
    
    #获取DHCP服务器地址
    def get_nic_ipv4_dhcp_server(self):
        '''
        功能描述：获取当前网卡DHCP服务器地址，网卡未启用、连接断开或静态IP时返回为None
        
        参数：无
        
        返回值：DHCP服务器IP地址。
        
        Example:
        | Init Nic Card  | 1                         | 本地连接1 |
        | ${dhcp_server} | Get Nic Ipv4 Dhcp Server  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_dhcp_server()
        return ret
    
    #获取当前DNS服务器IP地址
    def get_nic_ipv4_dns_server(self):
        '''
        功能描述：获取当前网卡DNS服务器地址，网卡未启用、连接断开或连接受限时返回为None
        
        参数：无
        
        返回值：DNS服务器IP地址,返回值为list类型
        
        Example:
        | Init Nic Card  | 1                        | 本地连接1 |
        | ${dns_server}  | Get Nic Ipv4 Dns Server  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_dns_server()
        return ret
    
    #获取dhcp租约时间
    def get_nic_ipv4_dhcp_lease_time(self):
        '''
        功能描述：获取当前网卡DHCP租约时间，该时间为租约到期时间和租约获得时间的差，单位为秒；\n
                  当前网卡未启用或连接断开或非DHCP方式时返回None.
        
        参数：无
        
        返回值：租约时间
        
        Example:
        | Init Nic Card      | 1                             | 本地连接1 |
        | ${dhcp_lease_time} | Get Nic Ipv4 Dhcp Lease Time  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_dhcp_lease_time()
        return ret
    
    #执行release
    def nic_dhcpv4_release(self):
        '''
        功能描述：执行release操作，静态IP、网卡未启用、连接断开时不报错，提示相应的WMI返回码
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card         | 1   | 本地连接1 |
        | Nic Dhcpv4 Release    |     |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_dhcpv4_release()
        
    #执行renew
    def nic_dhcpv4_renew(self):
        '''
        功能描述：执行renew操作，静态IP、网卡未启用、连接断开时不报错，提示相应的WMI返回码
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card       | 1   | 本地连接1 |
        | Nic Dhcpv4 Renew    |     |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_dhcpv4_renew()
    
    #启用网卡 add by shenlige 2013-3-13
    def enable_nic_card(self):
        '''
        功能描述：启用网卡。
        
        注意：用MAC地址来初始化，禁用网卡之后，启用网卡会有问题。
              需要在禁用网卡之后，再启用网卡的。请不要用MAC来进行初始化。
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card       | 1   | 本地连接1 |
        | Enable Nic Card     |     |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.enable_nic_card()
    
    #禁用网卡 
    def disable_nic_card(self):
        '''
        功能描述：禁用网卡。
        
        注意：用MAC地址来初始化，禁用网卡之后，启用网卡会有问题。
              需要在禁用网卡之后，再启用网卡的。请不要用MAC来进行初始化。
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card       |  1   | 本地连接1 |
        | Disable Nic Card    |      |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.disable_nic_card()
    
    #网卡重启 add by shenlige 2013-3-14
    def restart_nic_card(self):
        '''
        功能描述：重启网卡
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card        |  1   | 本地连接1 |
        | Restart Nic Card     |      |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.restart_nic_card()
    
     
    #获取WINS服务器地址
    def get_nic_ipv4_wins(self):
        '''
        功能描述：获取WINS服务器地址，若为空则返回None，网卡禁用时返回为None；
        
        参数：无
        
        返回值：由WINS服务器ip地址组成的列表。
        
        Example:
        | Init Nic Card  | 1                  | 本地连接1 |
        | ${ip_wins}     | Get Nic Ipv4 Wins  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv4_wins()
        return ret
    
    #获取主机名
    def get_host_name(self):
        '''
        功能描述：获取主机名
        
        参数：无
        
        返回值：主机名。
        
        Example:
        | Init Nic Card  | 1              | 本地连接1 |
        | ${hostname}    | Get Host Name  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.get_host_name()
        return ret
    
    def config_nic_to_ipv6_dhcp(self):
        '''
        功能描述：配置当前网卡为IPV6 DHCP模式;
        
        注意：ipv6设置目前仅支持win7系统;
        
        参数：无
        
        返回值：无
        
        Example:
        | Init Nic Card           | 1 | 本地连接1 |
        | Config Nic To Ipv6 Dhcp |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_to_ipv6_dhcp()
    
    def config_nic_to_ipv6_static_address(self, ipv6_address, prefix_length=64, default_gateway = ''):
        '''
        功能描述：配置网卡为静态方式ipv6地址，支持默认网关配置，默认不配置，\n
                  使用该接口配置ipv6地址后，除fe80：开始的地址外，仅有本次设置的ipv6地址。\n
                  配置仅本次生效，网卡重启后该配置将不存在
        
        注意：ipv6设置目前仅支持win7系统
        
        参数：
        ipv6_address: 有效的ipv6地址； 
        prefix_length：前缀长度，有效长度为0——128，默认为64； 
        default_gateway：默认网关，默认不配置，即自动获取； 
        
        返回值：无
        
        Example:
        | Init Nic Card                     |     1                              | 本地连接1 |
        | Config Nic To Ipv6 Static Address | 2111:3c:123:0:cc38:7f4e:2810:9903  |
        | Config Nic To Ipv6 Static Address | 2111:3c:123:0:cc38:7f4e:2810:9903  |   96   |
        | Config Nic To Ipv6 Static Address | 2111:3c:123:0:cc38:7f4e:2810:9903  |   64   |  2111:3c:123::   |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_to_ipv6_static_address(ipv6_address, prefix_length, default_gateway)
    
    
    def config_nic_ipv6_dns_server(self, dns = ''):
        '''
        功能描述：配置当前网卡的dns服务器地址。
        
        注意：ipv6设置目前仅支持win7系统；\n
              若当前网卡为DHCP方式，参数为默认值或字符串"None"时，DNS配置为自动获取，否则依据参数配置手动方式的DNS服务器；
              若当前网卡为静态IP方式，参数为默认值时，不修改当前DNS配置，参数为字符串"None"时，清除当前DNS列表，否则依据参数配置手动方式DNS服务器；
              
        
        参数：
        dns：由DNS服务器ipv6地址组成的列表，即使是只配置一个地址，也需要采用列表形式。
             可以配置为字符串"None"，默认为空;
              
        
        返回值：无
        
        Example:
        | Init Nic Card              | 1              | 本地连接1   |
        | ${dns_list}                | Create List    | 2111:123::2013   |
        | Config Nic Ipv6 Dns Server |                | 
        | Config Nic Ipv6 Dns Server |  None          |
        | Config Nic Ipv6 Dns Server | ${dns_list}    | 
        '''
         
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.config_nic_ipv6_dns_server(dns)
    
    def nic_add_an_ipv6_address(self,ipv6_address):
        '''
        功能描述：增加一个IPV6地址，该设置本次有效，网卡重启后，设置将不存在；
        
        注意：  ipv6设置目前仅支持win7系统；\n
                若当前网卡为DHCP方式，则关键字执行失败
    
        参数：
        ipv6_address：有效的ipv6地址
        
        返回值：无
        
        Example:
        | Init Nic Card            |  1                                 | 本地连接1 |
        | Nic Add An Ipv6 Address  | 2111:3c:123:0:cc38:7f4e:2810:9903  |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_add_an_ipv6_address(ipv6_address)
            
    
    def nic_delete_an_ipv6_address(self,ipv6_address):
        '''
        功能描述：删除一个IPV6地址，该设置本次有效，网卡重启后，设置将不存在；
        
        注意：ipv6设置目前仅支持win7系统；\n
              若当前网卡为DHCP方式，则关键字执行失败；
              若预删除的ipv6地址不存在，关键字执行不报错，只在LOG中给出提示。
            
        参数：
        ipv6_address：有效的ipv6地址
        
        返回值：无
        
        Example:
        | Init Nic Card              |  1                                 | 本地连接1 |
        | Nic Delete An Ipv6 Address | 2111:3c:123:0:cc38:7f4e:2810:9903  |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_delete_an_ipv6_address(ipv6_address)
    
    
    def get_nic_ipv6_default_gateway(self):
        '''
        功能描述：获取当前网卡的默认网关地址，网卡未启用、连接断开或连接受限时返回为None
        
        注意：ipv6设置目前仅支持win7系统
        
        参数：无
        
        返回值：由当前网卡的网关IP地址所组成的列表
        
        Example:
        | Init Nic Card  | 1                             | 本地连接1 |
        | ${gateway}     | Get Nic Ipv6 Default Gateway  |           |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv6_default_gateway()
        return ret
    
    def get_nic_ipv6_address(self):
        '''
        功能描述：返回当前网卡的IPv6地址。
        
        注意：ipv6设置目前仅支持win7系统
        
        参数：无。
        
        返回值：由当前网卡的IPv6地址所组成的列表，一般情况下，其中的ipv6地址包含了前缀长度，如果没有查找到或者当前网卡没有IPv6地址，返回None。
        
        Example:
        | Init Nic Card                     | 1                    | 本地连接1 |
        | ${ret}                            | Get Nic Ipv6 Address |
        
        '''     
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv6_address()
        return ret
    
    def get_nic_ipv6_dns_server(self):
        '''
        功能描述：返回当前网卡的IPv6 DNS 服务器地址。
        
        注意：ipv6设置目前仅支持win7系统
        
        参数：无。
        
        返回值：由当前网卡的IPv6 DNS服务器地址组成的列表。
        
        Example:
        | Init Nic Card        | 1                       | 本地连接1 |
        | ${ret}               | Get Nic Ipv6 Dns Server |
        
        '''     
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_ipv6_dns_server()
        return ret
    
    # 增加解析ip地址返回值的接口  add by shenlige 2013-3-26
    def analyze_ip_and_subnet(self,ip_subnet):
        '''
        功能描述：主要是对关键字Get Nic Ipv4 Address返回值做解析。
        
        
        注意：只解析一个'ip地址-子网掩码'值对，不解析list形式的参数。
        
        参数：
        ip_subnet：ip地址和子网掩码所组成的字符串，格式为：ipv4_addr/subnet,例如ipv4的地址：'172.16.28.113/255.255.254.0'               
        
        返回值：由ip地址和子网掩码构成的list，即[ip_addr,subnet]，
                例如['172.16.28.113','255.255.254.0']，当参数为None时，返回为[None,None]
        
        Example:
        |  Init Nic Card       |  1                     | 本地连接1                |
        |  ${addr_subnet}      |  Get Nic Ipv4 Address  |
        |  ${addr_subnet}      |  Run Keyword If        |  ${addr_subnet} != None  |   Get From List   | ${addr_subnet} |   0   |
        |  ${ret}              |  Analyze Ip And Subnet |  ${addr_subnet}          |    
        
        '''     
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.analyze_ip_and_subnet(ip_subnet)
        return ret
    
    # 增加添加ipv4地址的接口 add by shenlige 2013-3-26
    def nic_add_an_ipv4_address(self,ipv4_addr,mask):
        '''
        功能描述：增加一个ipv4地址，若当前网卡为DHCP方式，则关键字执行失败；
        
        参数：
        ipv4_addr：ipv4地址；
        mask:子网掩码；
        
        返回值：无
        
        Example:
        | Init Nic Card            |  1            |  本地连接1      |
        | Nic Add An Ipv4 Address  | 192.168.1.11  |  255.255.255.0  |
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_add_an_ipv4_address(ipv4_addr,mask)
    
    
    def nic_delete_an_ipv4_address(self,ipv4_address):
        '''
        功能描述：删除一个IPV4地址;
        
        注意：若当前网卡为DHCP方式，则关键字执行失败；
              多个静态IP地址时该此关键字可正常执行，单个静态IP时关键字执行失败；
              若预删除的ipv4地址不存在，关键字执行不报错，只在LOG中给出提示。
        
        参数：
        ipv4_address：有效的ipv4地址
        
        返回值：无
        
        Example:
        | Init Nic Card              |  1            | 本地连接1 |
        | Nic Delete An Ipv4 Address | 192.168.1.10  |
        '''
        # 检查IP地址合法性
        if not check_ipaddr_validity(ipv4_address):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.nic_delete_an_ipv4_address(ipv4_address)
    
    #添加获取通过名称或MAC获取MAC或名称的关键字 add by shenlige 2014-3-18
    def get_nic_name_or_mac(self,name_or_mac):
        '''
        功能描述：根据用户输入的名称或MAC获取相应的MAC或名称，若用户输入的参数无法找到相匹配的信息，则返回None。
        
        参数：
        name_or_mac：网卡的名称或MAC值；
        
        返回值：
        相应网卡的MAC或名称；
        
        Example:
        | Init Nic Card      | 1                     | 本地连接1 |
        | ${mac_or_name}     | Get Nic Name Or Mac   |    test   |
        
        '''
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
            if not ret:
                ret = None
        else:
            ret = cls.get_nic_name_or_mac(name_or_mac)
        return ret
    

def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(NetConfig(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)   

def test():
    cls1 = NetConfig()
    
    cls1.init_nic_card("1", u"办公网")
    cls1.get_nic_ipv4_address()
    cls1.init_nic_card("1", u"本地连接 2", "http://10.10.10.6:58007")
    cls1.get_nic_ipv4_address()
    '''
    #cls1.get_ip_by_mac("44-37-E6-99-46-C1")
    #cls1.get_ip_by_mac("00-19-E0-03-20-C3")
    cls1.open_netconfig_remotelocal("local")
    cls1.get_ip_by_mac(mac_address="00-1A-A0-C0-0F-96")
    cls1.get_ip_by_mac("00-1A-A0-C0-0F-96")
    '''
    

if __name__ == '__main__':
    test()
