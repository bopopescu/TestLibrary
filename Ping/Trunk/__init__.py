# -*- coding: utf-8 -*- 

import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTPing import ATTPing
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS, IS_LOCAL

import attlog as log
  
REMOTE_PORT = REMOTE_PORTS.get('Ping')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600

class Ping():
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}  
        self.init_ping_site("Local")
        
    def _register_alias(self, alias, remote_url):
        
        # 改成以别名为健（当前要求别名唯一） change by yzm @ 20130328
        # 因前面已经保证了alias唯一，则直接对alias进行赋值（赋新值可保证网卡信息为最新的信息）
        self.dict_alias[alias] = remote_url

    def _is_init(self, alias, remote_url):
        """
        return alias
        """
        # 先判断别名是否被使用过
        if alias in self.dict_alias.keys():
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url以及name或者mac）
            if self.dict_alias.get(alias) == remote_url:
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            # 如果没被使用过，需判断当前的对象是否曾经被初始化过
            for key, value in self.dict_alias.items():
                if remote_url == value:
                    # 如果相符，则可以直接返回_key（只要找到即可返回）
                    return key 

        # 两种情况都不包含，则返回None
        return None
        
    def init_ping_site(self, alias ,remote_url=False):
        """
        功能描述：初始化执行ping的主机
        
        参数：alias：别名。remote_url：是否要进行远程控制。（默认不进行远程）。
        格式为：http://remote_IP.可以用以下几种方式进行初始化。
        注意请设置为不同的别名，切换时用别名进行切换。
        
        返回值：无
        
        Example:
        | Init Ping Site  | One | #初始化本地Ping主机      |                          
        | Init Ping Site  | two | http://10.10.10.84 | #初始化远程Ping主机 |
        """
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTPing()
            
        tag = self._cache.register(reallib, alias)
        self._register_alias(alias, remote_url)

        return tag
    
    def _current_remotelocal(self):
        if not self._cache.current:
            log_data = 'No remotelocal is open'
            log.user_info(log_data)
            raise RuntimeError(log_data)
        return self._cache.current       
    
    def switch_ping_site(self, alias):
        """
        功能描述：切换当前ping操作所在的主机
        
        参数：alias，别名
        
        返回值：无
        
        Example:
        | Init Ping Site                    | 1           |
        | Should Ping Ipv4 Success By Count | 192.168.1.1 | 4                 |
        | Init Ping Site                    | 2           | 10.10.10.84       |
        | Should Ping Ipv4 Fail By Count    | 192.168.1.1 | 4                 |       
        | Switch Ping Site                  | 1           |
        | Should Ping Ipv4 Success By Time  | 192.168.1.1 | 10                |
        | Switch Ping Site                  | 2           |
        | Should Ping Ipv4 Fail By Time     | 192.168.1.1 | 4                 |
        """
        try:
            cls=self._cache.switch(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'成功切换到别名为：%s 的主机下，后续Ping操作都是针对该主机，直到下一个初始化或切换动作' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            log_data = "No remotelocal with alias '%s' found." % alias
            log.user_err(log_data)
            raise RuntimeError(log_data)  
        

    def should_ping_ipv4_success_by_time(self, ipv4_domain, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv4 Ping测试，通过时间来进行Ping，如实际丢包率小于等于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        参数：
        ipv4_domain:Ping的IPv4地址或者域名（如果是域名，需解析出来是IPv4地址）； 
        total_time:Ping的总时间（默认120秒）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                   | 1           |
        | Should Ping Ipv4 Success By Time | 192.168.1.1 | 4 |
        """
        # check ipv4_domain, if it is ip addr, check ipaddr validity
        parttern = "([a-zA-Z]+)"
        
        # 检查是否是域名
        if not re.match(parttern, ipv4_domain):
            # 检查IP地址合法性
            if not check_ipaddr_validity(ipv4_domain):
                raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    
                    
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv4_success_by_time(ipv4_domain, total_time, psize, success_percent_lost)
            
    def should_ping_ipv4_fail_by_time(self, ipv4_domain, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv4 Ping测试，通过时间来进行Ping，如实际丢包率大于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        参数：
        ipv4_domain:Ping的IPv4地址或者域名（如果是域名，需解析出来是IPv4地址）； 
        total_time:Ping的总时间（默认120秒）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于 'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                | 1           |
        | Should Ping Ipv4 Fail By Time | 192.168.1.1 | 4 |
        """
        # check ipv4_domain, if it is ip addr, check ipaddr validity
        parttern = "([a-zA-Z]+)"
        # 检查是否是域名
        if not re.match(parttern, ipv4_domain):
            # 检查IP地址合法性
            if not check_ipaddr_validity(ipv4_domain):
                raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:                                
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
            
        else:
            cls.should_ping_ipv4_fail_by_time(ipv4_domain, total_time, psize, success_percent_lost)
    
    def should_ping_ipv4_success_by_count(self, ipv4_domain, count = 10, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv4 Ping测试，通过设置Ping的次数来进行Ping，如实际丢包率小于等于 'success_percent_lost'%为关键字执行成功，否则失败报错。。
        
        参数：
        ipv4_domain:Ping的IPv4地址或者域名（如果是域名，需解析出来是IPv4地址）； 
        count:Ping的次数（默认10次）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于 'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                    | 1           |
        | Should Ping Ipv4 Success By Count | 192.168.1.1 | 4 |
        """
        # check ipv4_domain, if it is ip addr, check ipaddr validity
        parttern = "([a-zA-Z]+)"
        # 检查是否是域名
        if not re.match(parttern, ipv4_domain):
            # 检查IP地址合法性
            if not check_ipaddr_validity(ipv4_domain):
                raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 先做次数参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(count, int)):
                timeout = int(count)
            else:
                timeout = count
        except ValueError,e:
            raise RuntimeError(u"输入的count参数 %s 格式不正确，需为有效的数字：%s" % (count,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping次数有误，需为[0-2592000]之间的数字")    
            
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv4_success_by_count(ipv4_domain, count, psize, success_percent_lost)
    
    def should_ping_ipv4_fail_by_count(self, ipv4_domain, count = 10, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv4 Ping测试，通过设置Ping的次数来进行Ping，如实际丢包率大于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        参数：
        ipv4_domain:Ping的IPv4地址或者域名（如果是域名，需解析出来是IPv4地址）； 
        count:Ping的次数（默认10次）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于 'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                 | 1           |
        | Should Ping Ipv4 Fail By Count | 192.168.1.1 | 4 |
        """
        # check ipv4_domain, if it is ip addr, check ipaddr validity
        parttern = "([a-zA-Z]+)"
        # 检查是否是域名
        if not re.match(parttern, ipv4_domain):
            # 检查IP地址合法性
            if not check_ipaddr_validity(ipv4_domain):
                raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 先做次数参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(count, int)):
                timeout = int(count)
            else:
                timeout = count
        except ValueError,e:
            raise RuntimeError(u"输入的count参数 %s 格式不正确，需为有效的数字：%s" % (count,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping次数有误，需为[0-2592000]之间的数字")    
    
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv4_fail_by_count(ipv4_domain, count, psize, success_percent_lost)

    def should_ping_ipv6_success_by_time(self, ipv6_domain, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv6 Ping测试，通过时间来进行Ping，如实际丢包率小于等于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        
        参数：
        ipv6_domain:Ping的IPv6地址或者域名（如果是域名，需解析出来是IPv6地址）； 
        total_time:Ping的总时间（默认120秒）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无

        
        Example:
        | Init Ping Site                   | 1           |
        | Should Ping Ipv6 Success By Time | 2111:3c:123::1 | 15 |
        """
        
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    

        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try: 
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv6_success_by_time(ipv6_domain, total_time, psize, success_percent_lost)
            
    def should_ping_ipv6_fail_by_time(self, ipv6_domain, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv6 Ping测试，通过时间来进行Ping，如实际丢包率大于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        
        参数：
        ipv6_domain:Ping的IPv6地址或者域名（如果是域名，需解析出来是IPv6地址）； 
        total_time:Ping的总时间（默认120秒）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                | 1           |
        | Should Ping Ipv6 Fail By Time | 2111:3c:123::1 | 15 |
        """
        
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    

        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:               
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv6_fail_by_time(ipv6_domain, total_time, psize, success_percent_lost)
    
    def should_ping_ipv6_success_by_count(self, ipv6_domain, count = 10, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv6 Ping测试，通过设置Ping的次数来进行Ping，如实际丢包率小于等于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        参数：
        ipv6_domain:Ping的IPv6地址或者域名（如果是域名，需解析出来是IPv6地址）； 
        count:Ping的次数（默认10次）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                    | 1              |
        | Should Ping Ipv6 Success By Count | 2111:3c:123::1 | 4 |
        """
        
        # 先做次数参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(count, int)):
                timeout = int(count)
            else:
                timeout = count
        except ValueError,e:
            raise RuntimeError(u"输入的count参数 %s 格式不正确，需为有效的数字：%s" % (count,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping次数有误，需为[0-2592000]之间的数字")    
    
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv6_success_by_count(ipv6_domain, count, psize, success_percent_lost)
    
    def should_ping_ipv6_fail_by_count(self, ipv6_domain, count = 10, psize = 32, success_percent_lost = 50):
        """
        功能描述：IPv6 Ping测试，通过设置Ping的次数来进行Ping，如实际丢包率大于 'success_percent_lost'%为关键字执行成功，否则失败报错。
        
        参数：
        ipv6_domain:Ping的IPv6地址或者域名（如果是域名，需解析出来是IPv6地址）； 
        count:Ping的次数（默认10次）；
        psize:数据字段长度（默认为32）；
        success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
                
        返回值：无
        
        Example:
        | Init Ping Site                 | 1              |
        | Should Ping Ipv6 Fail By Count | 2111:3c:123::1 | 4 |
        """
        
        # 先做次数参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(count, int)):
                timeout = int(count)
            else:
                timeout = count
        except ValueError,e:
            raise RuntimeError(u"输入的count参数 %s 格式不正确，需为有效的数字：%s" % (count,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping次数有误，需为[0-2592000]之间的数字")    
    
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_ping_ipv6_fail_by_count(ipv6_domain, count, psize, success_percent_lost)


    def start_ping_ipv4(self, ipv4_domain, total_time = 3600, psize = 32):
        """
        功能描述：IPv4 Ping测试，按时间持续ping，直到用户执行Stop Ping，Stop Ping And Should Ping Success或Stop Ping And Should Ping Fail关键字，\n
                  若用户未下发停止ping的命令，则持续ping指定的total_time时间；
        
        参数：
        ipv4_domain:Ping的IPv4地址或者域名（如果是域名，需解析出来是IPv4地址）； 
        total_time:Ping的总时间（默认3600秒）；
        psize:数据字段长度（默认为32）；
        
        返回值：进程对象的ID，作为停止ping操作的参数；
        
        Example:
        | Init Ping Site   |  1               |
        |  ${pid1}         |  Start Ping Ipv4 |   192.168.1.1 |
        |  ${pid2}         |  Start Ping Ipv4 |   172.16.28.1 |  60  |
        |  Sleep           |  10              |
        |  ${lost_precent} |  Stop Ping       |      ${pid1}     |       
        """
        
        parttern = "([a-zA-Z]+)"
        # 检查是否是域名
        if not re.match(parttern, ipv4_domain):
            # 检查IP地址合法性
            if not check_ipaddr_validity(ipv4_domain):
                raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    
           
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                ret = auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            ret = cls.start_ping_ipv4(ipv4_domain,total_time,psize)
        return ret

    def start_ping_ipv6(self, ipv6_domain, total_time = 3600, psize = 32):
        """
        功能描述：IPv6 Ping测试，按时间持续ping，直到用户执行Stop Ping，Stop Ping And Should Ping Success或Stop Ping And Should Ping Fail关键字，\n
                  若用户未下发停止ping的命令，则持续ping指定的total_time时间；
        
        参数：
        ipv6_domain:Ping的IPv6地址或者域名（如果是域名，需解析出来是IPv6地址）； 
        total_time:Ping的总时间（默认3600秒）；
        psize:数据字段长度（默认为32）；
        
        返回值：进程对象的ID，作为停止ping操作的参数；
        
        Example:
        | Init Ping Site   |  1               |
        |  ${pid1}         |  Start Ping Ipv6 |   2111:3c:123::1 |
        |  ${pid2}         |  Start Ping Ipv6 |   2111:3c:456::1 |  60  |
        |  Sleep           |  10              | 
        |  ${lost_precent} |  Stop Ping       |      ${pid1}     |       
        """
        # 先做时间参数检查， 以防止参数非法时本端远端log信息不一致  modify by shenlige 2013-6-26
        try:
            if not (isinstance(total_time, int)):
                timeout = int(total_time)
            else:
                timeout = total_time
        except ValueError,e:
            raise RuntimeError(u"输入的total_time参数 %s 格式不正确，需为有效的数字：%s" % (total_time,e)) 
        
        if timeout > 2592000:
            raise RuntimeError(u"输入的ping时间有误，需为[0-2592000]之间的数字")    
            
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):      
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                ret = auto_do_remote(cls)
            except Exception,e:
                raise RuntimeError(u"远端执行失败，具体原因：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            ret = cls.start_ping_ipv6(ipv6_domain,total_time,psize)
        return ret
    
    def stop_ping(self,pid):
        """
        功能描述：停止关键字Start Ping Ipv4或Start Ping Ipv6的执行，打印出ping命令的执行结果，并返回对应的丢包率；
        
        参数：
            pid：进程对象，为Start Ping Ipv4或Start Ping Ipv6关键字的返回值
            
        返回值：丢包率
        
        Example:
        | Init Ping Site   |  1               |
        |  ${pid1}         |  Start Ping Ipv4 |   192.168.1.1 |
        |  ${pid2}         |  Start Ping Ipv4 |   172.16.28.1 |  60  |
        |  Sleep           |  10              |
        |  ${lost_precent} |  Stop Ping       |      ${pid1}  |       
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):      
            ret = auto_do_remote(cls)
        else:
            ret = cls.stop_ping(pid)
        return ret

    def stop_ping_and_should_ping_success(self,pid,success_percent_lost = 50):
        """
        功能描述：停止关键字Start Ping Ipv4或Start Ping Ipv6的执行，打印ping命令的执行结果；\n
                  如实际丢包率小于等于 'success_percent_lost'关键字执行成功，否则失败报错。
        
        参数：
            pid：进程对象，为Start Ping Ipv4或Start Ping Ipv6关键字的返回值
            success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
        
        返回值：无
        
        Example:
        | Init Ping Site  |  1               |
        |  ${pid1}        |  Start Ping Ipv4 |   192.168.1.1 |
        |  Sleep          |  10              |
        |  Stop Ping And Should Ping Success |  ${pid1}      |
        |  Stop Ping And Should Ping Success |  ${pid1}      |    60     |
        """
        cls = self._current_remotelocal() 
        if (isinstance(cls, Remote)):      
            auto_do_remote(cls)
        else:
            cls.stop_ping_and_should_ping_success(pid,success_percent_lost)
            
            
    def stop_ping_and_should_ping_fail(self,pid,success_percent_lost = 50):
        """
        功能描述：停止关键字Start Ping Ipv4或Start Ping Ipv6的执行，打印ping命令的执行结果；\n
                  如实际丢包率大于等于 'success_percent_lost'关键字执行成功，否则失败报错。
        
        参数：
            pid：进程对象，为Start Ping Ipv4或Start Ping Ipv6关键字的返回值
            success_percent_lost：丢包率，丢包率小于等于'success_percent_lost'%为ping成功（默认丢包率50%）。
        
        返回值：无
        
        Example:
        | Init Ping Site  |  1               |
        |  ${pid1}        |  Start Ping Ipv4 |   192.168.1.1 |
        |  Sleep          |  10              |
        |  Stop Ping And Should Ping Fail    |  ${pid1}      |
        |  Stop Ping And Should Ping Fail    |  ${pid1}      |    60     |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):      
            auto_do_remote(cls)
        else:
            cls.stop_ping_and_should_ping_fail(pid,success_percent_lost)


       
def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(Ping(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)   
            
def test():
    pass

    if (0):
        cls1 = RemotePingATT()
        #cls1.open_ping_remotelocal("remote", "http://172.16.28.55:8888")
        cls1.init_ping_site("local")
        cls1.should_ping_success_by_count("172.16.28.41")
        cls1.init_ping_site("remote", "http://172.16.28.55:58002")
        cls1.should_ping_success_by_count("172.16.28.55")
        cls1.switch_ping_remotelocal('local')
        cls1.should_ping_success_by_count("172.16.28.41")
    
    if (0):
        cls1 = RemotePingATT()
        #cls1.open_ping_remotelocal("remote", "http://172.16.28.55:8889")
        cls1.init_ping_site("local1")
        cls1.should_ping_success_by_count("172.16.28.47")
        
        cls2 = RemotePingATT()
        cls2.init_ping_site("local2")
        cls2.should_ping_success_by_count("172.16.28.34")        
        
        cls1.switch_ping("local1")
        cls1.should_ping_success_by_count("172.16.28.34")
        
    if (1):
        cls1 = RemotePingATT()
        cls1.init_ping_site("remote1", "http://172.16.28.47:8889")
        cls1.should_ping_success_by_count("172.16.28.47")
        
        cls2 = RemotePingATT()
        cls2.init_ping_site("remote2", "http://172.16.28.47:8889")
        cls2.should_ping_success_by_count("172.16.28.34")        
        
        cls1.switch_ping("remote1")
        cls1.should_ping_success_by_count("172.16.28.34")          
    

if __name__ == '__main__':
    test()
