# -*- coding: utf-8 -*- 

import os
import sys
import time


from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTWireless import ATTWireless
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log
REMOTE_PORT = REMOTE_PORTS.get('Wireless')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600

class Wireless(): 
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION
    
    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}  # (index,url) = alias
        try:
            self.init_wireless_card('MAIN_WIRELESS_CARD')
        except:
            pass

    def _register_alias(self, alias, index_or_name_or_mac, remote_url):
        
        # 对别名判断做了修改 zsj 2013-3-28
        if self.dict_alias.get((index_or_name_or_mac, remote_url)):
            self.dict_alias[(index_or_name_or_mac, remote_url)].append(alias)
        else:
            self.dict_alias[(index_or_name_or_mac, remote_url)] = [alias]

    def _is_init(self, index_or_name_or_mac, remote_url, alias):
        """
        return alias
        """
        list_alias = self.dict_alias.get((index_or_name_or_mac, remote_url))
        if list_alias and alias in  list_alias:
             return alias 
        elif alias in self._cache._aliases.keys():
            raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            return None 
    
    def init_wireless_card(self, alias ,index_or_name_or_mac=0, remote_url=False):
        """
        功能描述：初始化网卡，将本端或远端的网卡使用别名代替，方便后面的切换；\n
        
        参数:
            
            alias：用户自定义的无线网卡别名；
            
            index_or_name_or_mac：可以使用无线网卡的序号（index）、名称（name）或者Mac地址（mac）来对无线网卡进行初始化，
                                  如果为序号（index）时，一般表示该无线网卡插入电脑的顺序，默认是0（以0开始计数），该数字小于当前PC机中插入的网卡数；
                                  注意：无线网卡的名称不要使用数字序号，否则程序会默认使用index进行初始化
            
            remote_url:配置远端地址，默认为False，即不启用远端；
        
        Example:
        | Init Wireless Card    | one        |              |       | #使用默认配置，即本端,网卡索引为0    |
        | Init Wireless Card    | two        | ${1}         |       | #使用索引为1的网卡                   |
        | Init Wireless Card    | remote1    | wireless_1   | remote_url=http://172.16.26.35    | #远端，使用连接名称                  |
        
        """        
        # 对用户输入的remote_url做处理转换，添加http://头等 add by jias 20131210
        remote_url = modified_remote_url(remote_url)
        
        if index_or_name_or_mac == "":
            index_or_name_or_mac = 0   # 2013-1-4 zsj modified 
        
        if (is_remote(remote_url)):
            reallib = Remote(remote_url)
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
        else:
            # already init?
            ret_alias = self._is_init(index_or_name_or_mac, remote_url, alias)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTWireless(index_or_name_or_mac)
                
        tag = self._cache.register(reallib, alias) 
        self._register_alias(alias, index_or_name_or_mac, remote_url)
        
        return tag
    
    def _current_remotelocal(self):
        if not self._cache.current:
            log_data = 'No remotelocal is open'
            log.user_err(log_data)
            raise RuntimeError(log_data)
        return self._cache.current       
    
    
    def switch_wireless_card(self, alias):
        """
        功能描述：切换无线网卡；
        
        参数：
            
            alias：用户初始化时设置的网卡别名
        
        Example:
        | Switch Wireless Card    | remote1    | 
        
        """
        try:
            cls=self._cache.switch(alias) 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'成功切换到别名为：%s 的网卡下，后续操作都是针对该网卡，直到下一个切换动作' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            log_data = "No remotelocal with alias '%s' found." % alias
            log.user_err(log_data)
            raise RuntimeError(log_data)            
            
    def ssid_connect_by_shared_wep(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用shared wep模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
        
        Example:
        | Ssid Connect By Shared Wep    | NETGEAR_ATT    | 8FB4FB6FE9    |      |
        | Ssid Connect By Shared Wep    | TEST_Robot     | 73B9B73F4D    | 2    |
            
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e)
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 根据关键字执行时间设定和远端的超时时间 zsj 2013-3-28
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_shared_wep(ssid, key, key_index, timeout)
    
        
    def ssid_connect_by_open_wep(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用open wep模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Connect By Open Wep    | NETGEAR_ATT    | 8FB4FB6FE9    |      |
        | Ssid Connect By Open Wep    | TEST_Robot     | 73B9B73F4D    | 2    |    
            
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e)
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 根据关键字执行时间设定和远端的超时时间 zsj 2013-3-28
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_open_wep(ssid, key, key_index, timeout)     
            
    def ssid_connect_by_none(self, ssid, timeout=120):
        """
        功能描述：采用不加密模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid: 要连接的SSID号；
            
            timeout：连接超时时间，默认为120秒；
            
        Example:
        | Ssid Connect By None    | NETGEAR_ATT    |       |
        | Ssid Connect By None    | TEST_Robot     | 90    |   
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e)
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 根据关键字执行时间设定和远端的超时时间 zsj 2013-3-28
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_none(ssid, timeout)  
        
    def ssid_connect_by_WPA_PSK_TKIP(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_TKIP模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            timeout:连接超时时间，默认为120秒；
        
        Example:
        | Ssid Connect By WPA PSK TKIP    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Connect By WPA PSK TKIP    | TEST_Robot     | 1234567890    | 90    |
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 根据关键字执行时间设定和远端的超时时间 zsj 2013-3-28
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_WPA_PSK_TKIP(ssid, key, timeout) 

    def ssid_connect_by_WPA2_PSK_TKIP(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_TKIP模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Connect By WPA2 PSK TKIP    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Connect By WPA2 PSK TKIP    | TEST_Robot     | 1234567890    | 90    |    
       
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_WPA2_PSK_TKIP(ssid, key, timeout)       

    def ssid_connect_by_WPA_PSK_AES(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_AES模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Connect By WPA PSK AES    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Connect By WPA PSK AES    | TEST_Robot     | 1234567890    | 90    | 
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_WPA_PSK_AES(ssid, key, timeout)  

    def ssid_connect_by_WPA2_PSK_AES(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_AES模式连接SSID（只下发连接命令，不关注连接结果）。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Connect By WPA2 PSK AES    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Connect By WPA2 PSK AES    | TEST_Robot     | 1234567890    | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_connect_by_WPA2_PSK_AES(ssid, key, timeout)               
            
    def ssid_should_connect_by_shared_wep_success(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用shared wep模式连接SSID，连接应成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By Shared WEP Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By Shared WEP Success    | TEST_Robot     | 1234567890    | 2     | 
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_shared_wep_success(ssid, key, key_index, timeout)   
        
    def ssid_should_connect_by_open_wep_success(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用open wep模式连接SSID，应连接成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By Open WEP Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By Open WEP Success    | TEST_Robot     | 1234567890    | 2     | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_open_wep_success(ssid, key, key_index, timeout)   

    def ssid_should_connect_by_none_success(self, ssid, timeout=120):
        """
        功能描述：采用不加密模式连接SSID，应连接成功。
        
        参数：
            
            ssid:要连接的SSID号
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By None Success    | NETGEAR_ATT    |       |
        | Ssid Should Connect By None Success    | TEST_Robot     | 90    |     
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_none_success(ssid, timeout)    
        
    def ssid_should_connect_by_WPA_PSK_TKIP_success(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_TKIP模式连接SSID，应连接成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
        
        Example:
        | Ssid Should Connect By WPA PSK TKIP Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA PSK TKIP Success    | TEST_Robot     | 1234567890    | 90    | 
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 根据关键字执行时间设定和远端的超时时间 zsj 2013-3-28
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA_PSK_TKIP_success(ssid, key, timeout)    

    def ssid_should_connect_by_WPA2_PSK_TKIP_success(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_TKIP模式连接SSID，应连接成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By WPA2 PSK TKIP Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA2 PSK TKIP Success    | TEST_Robot     | 1234567890    | 90    | 

        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA2_PSK_TKIP_success(ssid, key, timeout)            

    def ssid_should_connect_by_WPA_PSK_AES_success(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_AES模式连接SSID，应连接成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By WPA PSK AES Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA PSK AES Success    | TEST_Robot     | 1234567890    | 90    | 

        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA_PSK_AES_success(ssid, key, timeout)      

    def ssid_should_connect_by_WPA2_PSK_AES_success(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_AES模式连接SSID，应连接成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By WPA2 PSK AES Success    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA2 PSK AES Success    | TEST_Robot     | 1234567890    | 90    | 
  
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA2_PSK_AES_success(ssid, key, timeout)
            
    def ssid_should_connect_by_shared_wep_fail(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用shared wep模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By Shared WEP Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By Shared WEP Fail    | TEST_Robot     | 1234567890    | 2     | 
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_shared_wep_fail(ssid, key, key_index, timeout) 
        
    def ssid_should_connect_by_open_wep_fail(self, ssid, key, key_index=1, timeout=120):
        """
        功能描述：采用open wep模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By Open WEP Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By Open WEP Fail    | TEST_Robot     | 1234567890    | 2     | 
        
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_open_wep_fail(ssid, key, key_index, timeout)  

    def ssid_should_connect_by_none_fail(self, ssid, timeout=120):
        """
        功能描述：采用不加密模式连接SSID，应连接不成功。
        
        参数：
            
            ssid:要连接的SSID号
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By None Fail    | NETGEAR_ATT    |       |
        | Ssid Should Connect By None Fail    | TEST_Robot     | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_none_fail(ssid, timeout)
        
    def ssid_should_connect_by_WPA_PSK_TKIP_fail(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_TKIP模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
        
        Example:
        | Ssid Should Connect By WPA PSK TKIP Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA PSK TKIP Fail    | TEST_Robot     | 1234567890    | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA_PSK_TKIP_fail(ssid, key, timeout)

    def ssid_should_connect_by_WPA2_PSK_TKIP_fail(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_TKIP模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
        
        Example:
        | Ssid Should Connect By WPA2 PSK TKIP Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA2 PSK TKIP Fail    | TEST_Robot     | 1234567890    | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA2_PSK_TKIP_fail(ssid, key, timeout)

    def ssid_should_connect_by_WPA_PSK_AES_fail(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA_PSK_AES模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By WPA PSK AES Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA PSK AES Fail    | TEST_Robot     | 1234567890    | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA_PSK_AES_fail(ssid, key, timeout)
            
    def ssid_should_connect_by_WPA2_PSK_AES_fail(self, ssid, key, timeout=120):
        """
        功能描述：采用WPA2_PSK_AES模式连接SSID，应连接不成功。
        
        参数：
            
            ssid：要连接的SSID号；
            
            key：密钥；
            
            timeout:连接超时时间，默认为120秒；
            
        Example:
        | Ssid Should Connect By WPA2 PSK AES Fail    | NETGEAR_ATT    | icyhat123f    |       |
        | Ssid Should Connect By WPA2 PSK AES Fail    | TEST_Robot     | 1234567890    | 90    | 
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_connect_by_WPA2_PSK_AES_fail(ssid, key, timeout)
            
    def ssid_should_in_available_network_list(self, ssid):
        """
        功能描述：无线SSID应在可用的无线网络列表中可以查询到。
        
        参数：
            
            ssid:要查询的SSID号
        
        Example:
        | Ssid Should In Available Network List   | NETGEAR_ATT    |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_in_available_network_list(ssid)

    def ssid_should_not_in_available_network_list(self, ssid):
        """
        功能描述：无线SSID应在可用的无线网络列表中查询不到。
        
        参数：
            
            ssid:要查询的SSID号
        
        Example:
        | Ssid Should Not In Available Network List   | NETGEAR_ATT    |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.ssid_should_not_in_available_network_list(ssid)

    def wireless_connect(self, ssid, 
                authentication, encryption, 
                key="", key_index=1, timeout=120):
        """
        功能描述：按照指定的ssid及其加密模式连接无线AP
        
        参数：
            
            ssid:要连接的SSID号(必填)，；
            
            authentication:认证模式，(必填)，支持shared，open，WPA2PSK和WPAPSK；
            
            encryption:加密模式，(必填)，支持none，WEP，AES和TKIP；
            
            key:密钥；
            
            key_index:密钥索引，默认为1；
            
            timeout:连接超时时间，默认为120秒；
         
        Example:   
        | Wireless Connect   | NETGEAR_ATT1    | WPA2PSK    | AES    | icyhat123f    |
        | Wireless Connect   | NETGEAR_ATT2    | open       | WEP    | 8FB4FB6FE9    |
        | Wireless Connect   | NETGEAR_ATT3    | shared     | WEP    | 8FB4FB6FE9    | 2      |
    
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.connect(ssid, timeout, authentication, encryption, key, key_index)

    def wireless_auto_connect(self, ssid, key="", timeout=120,  key_index=1):
        """
        功能描述：首先删除SSID的profile，再自动识别该SSID的加密模式，然后通过Key连接无线AP
        
        参数：
            
            ssid:要连接的SSID号(必填)，；
            
            key:密钥；默认为空
            
            timeout:连接超时时间，默认为120秒；
            
            key_index:密钥索引，默认为1；当加密模式为WEP时使用
         
        Example:   
        | Wireless Auto Connect   | China_NetXX    |  icyhat123f    |
        | Wireless Auto Connect   | China_NetXX    |  8FB4FB6FE9    | 160 | 1  |
    
        """
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e)
        
        try:
            key_index = int(key_index)
        except ValueError,e1:
            raise RuntimeError(u"key_index设置错误，请输入整数")
        
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.auto_connect(ssid, timeout, key, key_index)  
    
    
    def wireless_disconnect(self):
        """
        功能描述：断开无线网卡连接。
        
        参数：
            
            无
        
        Example:   
        | Wireless Disconnect   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.disconnect()
        
    def get_available_network_list(self):
        """
        功能描述：查询可用的无线网络连接，返回可用的无线网络列表。
        
        参数：
        
            无
        
        返回值：
            
            当前可用的无线网络列表。
        
        Example:   
        | ${list} | Get Available Network List   |      |
        """
        ret = []
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.get_available_network_list()
        return ret
        
        
    def delete_wireless_profile(self, ssid):
        """
        功能描述：删除指定SSID的profile。
        
        参数：
            
            ssid:SSID号；
        
        Example:   
        | Delete Wireless Profile   | NETGEAR_ATT     |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.delete_profile(ssid)

    def delete_all_wireless_profile(self):
        """
        功能描述：删除当前网卡所有profile。
        
        参数：
            
            无
        
        Example:   
        | Delete All Wireless Profile   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.delete_all_profile()

    def query_wireless_interface_status(self):
        """
        功能描述：查询并返回当前无线网卡状态。
        
        参数：
            
            无
        
        Example:   
        | Query Wireless Interface Status   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.query_interface_status()
            
            # change by jxy ,增加LOG打印信息。    
            log_data = u'查询网卡状态为：%s' % ret
            log.user_err(log_data)
            
        return ret

    def wireless_should_be_connected(self):
        """
        功能描述：无线网卡当前应处于连接状态
        
        参数：
            
            无
        
        Example:   
        | Wireless Should Be Connected   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.should_be_connected()

    def wireless_should_be_disconnected(self):
        """
        功能描述：无线网卡当前应处于断开状态
        
        参数：
            
            无
        
        Example:   
        | Wireless Should Be Disonnected   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.should_be_disconnected()
    
    def query_connection_bssid(self):
        """
        功能描述：查询当前连接网络的BSSID。
        
        参数：
            
            无
        
        返回值：
            
            Unicode字符串（BSSID）
        
        Example:   
        | Query Connection Bssid   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.query_connection_bssid()  
        return ret
    
    def query_connection_signalquality(self):
        """
        功能描述：查询当前连接的网络的信号质量BSSID。
        
        参数：
            
            无
        
        返回值：
            
            整数 （信号质量）
        
        Example:   
        | Query Connection Signalquality   |      |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.query_connection_signalquality()
        return ret
        
    
    def query_security_info(self, ssid):
        """
        功能描述：查询并返回ssid的安全属性。
        
        参数：
            
            ssid  要查询的SSID号
        
        返回值：
            
            类型list.由三个元素组成["安全标示", authentication, encryption]
            
            "安全标示" 取值范围：[u"Security is not enabled",u"Security enabled"]
            
            authentication取值范围：[u"Open",u"Shared",u"WPA",u"WPAPSK",u"WPANone",u"WPA2" ,u"WPA2PSK",u"Other"]
            
            encryption取值范围： [u"None", u"WEP40", u"TKIP", u"AES", u"WEP104", u"WEP", u"Other"]
        
        说明：
            
            1、	该关键字不能正确区分Open WEP模式和Shared WEP模式。
            
            2、	有可能连接前查询是Open WEP模式，连接后查询又是Shared WEP模式。
            
            3、详细情况如下：
            
            XP ：
            
            CPE配置（open wep  ）- 连接前查询（open wep）- 用 open wep   连接（成功）- 连接后查询（open wep）
            
            CPE配置（open wep  ）- 连接前查询（open wep）- 用 shared wep 连接（成功）- 连接后查询（open wep）
            
            CPE配置（shared wep）- 连接前查询（open wep）- 用 open wep   连接（失败）
            
            CPE配置（shared wep）- 连接前查询（open wep）- 用 shared wep 连接（成功）- 连接后查询（open wep）
            
            Win7 ：
            
            CPE配置（open wep  ）- 连接前查询（open wep）- 用 open wep   连接（成功）- 连接后查询（open wep）
            
            CPE配置（open wep  ）- 连接前查询（open wep）- 用 shared wep 连接（成功）- 连接后查询（shared wep）
            
            CPE配置（shared wep）- 连接前查询（open wep）- 用 open wep   连接（失败）
            
            CPE配置（shared wep）- 连接前查询（open wep）- 用 shared wep 连接（成功）- 连接后查询（shared wep）
        
        Example:   
        | Query Security Info   |   ssidname   |
        """
        cls = self._current_remotelocal()
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.query_security_info(ssid)   #list
        
        return ret
    
    
def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(Wireless(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)   


def test():
    pass
    
if __name__ == '__main__':
    #test()
    w = Wireless()
    w.wireless_auto_connect()
    

