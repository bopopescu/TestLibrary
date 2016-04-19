# -*- coding: utf-8 -*- 

import sys
import time
from wlan.wlan import WLan

import attlog as log

WLAN_OK = 1
WLAN_ERROR = -1
#add 2013-11-08
WLAN_DISCONNECT	= -2

class ATTWireless():

    def __init__(self, index):
        self.obj = WLan(index)
    
    def ssid_connect_by_shared_wep(self, ssid, key, key_index=1, timeout=120):
        """采用shared wep模式连接SSID（只下发连接命令，不关注连接结果）。"""
        key_index = int(key_index)
        timeout = int(timeout)
        #change by jxy,2013-4-3，增加timeout参数判断。
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='shared', encryption='WEP', 
                                key=key, keyIndex=key_index) == WLAN_OK:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)
        
    def ssid_connect_by_open_wep(self, ssid, key, key_index=1, timeout=120):
        """采用open wep模式连接SSID（只下发连接命令，不关注连接结果）。"""
        key_index = int(key_index)
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data) 

        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='WEP', 
                                key=key, keyIndex=key_index) == WLAN_OK:
            log_data = u'无线网卡采用open wep模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用open wep模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)
            
    def ssid_connect_by_none(self, ssid, timeout=120):
        """采用不加密模式连接SSID（只下发连接命令，不关注连接结果）。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='none') == WLAN_OK:
            log_data = u'无线网卡采用不加密模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用不加密模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)
        
    def ssid_connect_by_WPA_PSK_TKIP(self, ssid, key, timeout=120):
        """采用WPA_PSK_TKIP模式连接SSID（只下发连接命令，不关注连接结果）。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='TKIP', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)

    def ssid_connect_by_WPA2_PSK_TKIP(self, ssid, key, timeout=120):
        """采用WPA2_PSK_TKIP模式连接SSID（只下发连接命令，不关注连接结果）。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='TKIP', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)

    def ssid_connect_by_WPA_PSK_AES(self, ssid, key, timeout=120):
        """采用WPA_PSK_AES模式连接SSID（只下发连接命令，不关注连接结果）。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='AES', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)

    def ssid_connect_by_WPA2_PSK_AES(self, ssid, key, timeout=120):
        """采用WPA_PSK_AES模式连接SSID（只下发连接命令，不关注连接结果）。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='AES', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 连接成功。' % ssid
        else:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 连接失败。' % ssid
        log.user_info(log_data)
            
    def ssid_should_connect_by_shared_wep_success(self, ssid, key, key_index=1, timeout=120):
        """采用shared wep模式连接SSID，应连接成功。"""
        key_index = int(key_index)
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='shared', encryption='WEP', 
                                key=key, keyIndex=key_index) == WLAN_OK:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    
        
    def ssid_should_connect_by_open_wep_success(self, ssid, key, key_index=1, timeout=120):
        """采用open wep模式连接SSID，应连接成功。"""
        key_index = int(key_index)
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='WEP', 
                                key=key, keyIndex=key_index) == WLAN_OK:
            log_data = u'无线网卡采用open wep模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用open wep模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)   

    def ssid_should_connect_by_none_success(self, ssid, timeout=120):
        """采用不加密模式连接SSID，应连接成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='none') == WLAN_OK:
            log_data = u'无线网卡采用不加密模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用不加密模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    
        
    def ssid_should_connect_by_WPA_PSK_TKIP_success(self, ssid, key, timeout=120):
        """采用WPA_PSK_TKIP模式连接SSID，应连接成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='TKIP', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    

    def ssid_should_connect_by_WPA2_PSK_TKIP_success(self, ssid, key, timeout=120):
        """采用WPA2_PSK_TKIP模式连接SSID，应连接成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='TKIP', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)          

    def ssid_should_connect_by_WPA_PSK_AES_success(self, ssid, key, timeout=120):
        """采用WPA_PSK_AES模式连接SSID，应连接成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='AES', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)       

    def ssid_should_connect_by_WPA2_PSK_AES_success(self, ssid, key, timeout=120):
        """采用WPA2_PSK_AES模式连接SSID，应连接成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='AES', 
                                key=key) == WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 应该连接成功，实际连接成功。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 应该连接成功，实际连接失败。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)
            
    def ssid_should_connect_by_shared_wep_fail(self, ssid, key, key_index=1, timeout=120):
        """采用shared wep模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        key_index = int(key_index)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='shared', encryption='WEP', 
                                key=key, keyIndex=key_index) != WLAN_OK:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用shared wep模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    
        
    def ssid_should_connect_by_open_wep_fail(self, ssid, key, key_index=1, timeout=120):
        """采用open wep模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        key_index = int(key_index)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='WEP', 
                                key=key, keyIndex=key_index) != WLAN_OK:
            log_data = u'无线网卡采用open wep模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用open wep模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)   

    def ssid_should_connect_by_none_fail(self, ssid, timeout=120):
        """采用不加密模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='open', encryption='none') != WLAN_OK:
            log_data = u'无线网卡采用不加密模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用不加密模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    
        
    def ssid_should_connect_by_WPA_PSK_TKIP_fail(self, ssid, key, timeout=120):
        """采用WPA_PSK_TKIP模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='TKIP', 
                                key=key) != WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA_PSK_TKIP模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    

    def ssid_should_connect_by_WPA2_PSK_TKIP_fail(self, ssid, key, timeout=120):
        """采用WPA2_PSK_TKIP模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='TKIP', 
                                key=key) != WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA2_PSK_TKIP模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)
    def ssid_should_connect_by_WPA_PSK_AES_fail(self, ssid, key, timeout=120):
        """采用WPA_PSK_AES模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPAPSK', encryption='AES', 
                                key=key) != WLAN_OK:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA_PSK_AES模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)  

    def ssid_should_connect_by_WPA2_PSK_AES_fail(self, ssid, key, timeout=120):
        """采用WPA2_PSK_AES模式连接SSID，应连接不成功。"""
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication='WPA2PSK', encryption='AES', 
                                key=key) != WLAN_OK:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 应该连接失败，实际连接失败。' % ssid
            log.user_info(log_data)
        else:
            log_data = u'无线网卡采用WPA2_PSK_AES模式连接SSID %s 应该连接失败，实际连接成功。' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)    

    def ssid_should_in_available_network_list(self, ssid):
        """无线SSID应在可用的无线网络列表中可以查询到"""
        check_status = 0
        if ssid in self.get_available_network_list():
            log_data =  u'SSID %s 在当前可用的无线网络列表中' %  ssid
            log.user_info(log_data)
        else:
            log_data = u'SSID %s 不在当前可用的无线网络列表中' %  ssid
            log.user_err(log_data)
            raise RuntimeError(log_data) 

    def ssid_should_not_in_available_network_list(self, ssid):
        """无线SSID应在可用的无线网络列表中查询不到"""
        if ssid not in self.get_available_network_list():
            log_data = u'SSID %s 不在当前可用的无线网络列表中' %  ssid
            log.user_info(log_data)
        else:
            log_data = u'SSID %s 在当前可用的无线网络列表中' %  ssid 
            log.user_err(log_data)
            raise RuntimeError(log_data) 

        
    def connect(self, ssid, timeout=120, 
                authentication="", encryption="", 
                key="", key_index=1):
        """
        按照指定的ssid及其加密模式连接无线AP
        """
        key_index = int(key_index)
        timeout = int(timeout)
        if timeout<=0:
            log_data = u'timout<=0,请设置>0的值。' 
            log.user_err(log_data)
            raise RuntimeError(log_data)
        if self.obj.connect(ssid, timeout=timeout, 
                                authentication=authentication, encryption=encryption, 
                                key=key, keyIndex=key_index) == WLAN_OK:
            log_data = u'无线网卡连接成功'
            log.user_info(log_data)
        else:
            log_data = u'连接失败。'
            raise RuntimeError(log_data) 
        
    def _security_convert(self, security):
        """
        """
        #authentication取值范围：[u"Open",u"Shared",u"WPA",u"WPAPSK",u"WPANone",u"WPA2" ,u"WPA2PSK",u"Other"]
        #encryption取值范围： [u"None", u"WEP40", u"TKIP", u"AES", u"WEP104", u"WEP", u"Other"]
        
        authentication = u""
        if security[1] in [u"WPA",u"WPAPSK",u"WPANone"]:
            authentication = u"WPAPSK"
        elif security[1] in[u"WPA2" ,u"WPA2PSK"]:
            authentication = u"WPA2PSK"
        elif  security[1] in [u"Other"]:
            log_info = "查找加密模式得到的结果异常，不能自动识别登录"
            raise RuntimeError(log_data)
        else :
            authentication = security[1]         
        
        encryption = u"" 
        if security[2] in [u"WEP40", u"WEP104", u"WEP"]:
            encryption = u"WEP"
        elif  security[2] in [u"Other"]:
            log_info = "查找加密模式得到的结果异常，不能自动识别登录"
            raise RuntimeError(log_data)
        else :
            encryption = security[2]
        
        #当CPE配置开放启用和共享启用时，查询到的都是Open WEP(这是根因)
        #但用Open WEP不能连接共享启用的CPE
        #且用Shared WEP可以连接开放启用的CPE
        #故做如下修改
        if authentication == u"Open" and encryption == u"WEP":
            log_info = u"""因为当无线AP配置为开放启用和共享启用时，查询到的都是Open WEP安全模式，
用Open WEP模式不能连接共享启用模式的AP，且用Shared WEP模式可以连接开放启用模式的AP。
故当查询到是Open WEP模式时，用Shared WEP模式去配置profile、连接无线AP。"""
            log.user_info(log_info)
            authentication = u"Shared"
            encryption = u"WEP"
            
        return [authentication, encryption]
        
    def auto_connect(self, ssid, timeout=120, key="", key_index=1):
        """
        """
        #
        if self.obj.delete_profile(ssid) == WLAN_OK:
            log_data = u'删除名称为 %s 的无线Profile成功' % ssid
            log.user_info(log_data)
        else:
            log_data = u'删除名称为 %s 的无线Profile失败' % ssid
            log.user_err(log_data)
        
        #
        s = self.query_security_info(ssid)
        authentication = ""
        encryption = ""
        t = self._security_convert(s)        
        authentication = t[0]
        encryption = t[1]        
        
        log_data = u"采用连接模式：authentication=%s, encryption=%s" % (authentication, encryption)
        log.user_info(log_data)
        
        if self.obj.connect(ssid, timeout, authentication, encryption, key, key_index) == WLAN_OK:
            log_data = u'无线网卡连接成功'
            log.user_info(log_data)
        else:
            log_data = u'连接失败。'
            raise RuntimeError(log_data)

    def disconnect(self):
        """
        断开无线网卡连接。
        """
        # Change by jxy 2013/3/15 断开连接之后，增加查询无线网卡状态，如果状态不是断开状态，重复三次。
        i = 0
        while i < 3:
            i += 1
            try:               
                nret = self.obj.disconnect()                
                time.sleep(3)
                status = self.query_interface_status()
                if status == 'wlan_interface_state_disconnected':
                    log_data = u'断开无线网卡连接成功'
                    log.user_info(log_data)
                    break
      
            except Exception,e:
                log_data = u"多次断开无线网卡连接失败。错误信息如下：%s" % e
                log.user_err(log_data)
                raise RuntimeError(log_data)
        else:
            log_data = u"多次断开无线网卡连接失败。"
            log.user_err(log_data)
            raise RuntimeError(log_data)
        
        return nret
        
    def get_available_network_list(self):
        """
        查询可用的无线网络连接，返回可用的无线网络列表。
        """
        
        ret = self.obj.get_available_network_list()
        if ret != WLAN_OK:
            log_data = u'查询可用的无线网络连接失败。'
            log.user_err(log_data)
            raise RuntimeError(log_data) 
        else:
            #return self.obj.get_desc().decode(sys.getfilesystemencoding()).split('\n')
            # default unicode
            return self.obj.get_return().split('\n')
        
    def delete_profile(self, ssid):
        """
        删除指定SSID的profile。
        """
        if self.obj.delete_profile(ssid) == WLAN_OK:
            log_data = u'删除名称为 %s 的无线Profile成功' % ssid
            log.user_info(log_data)
        else:
            log_data = u'删除名称为 %s 的无线Profile失败' % ssid
            log.user_err(log_data)
            raise RuntimeError(log_data)

    def delete_all_profile(self):
        """
        删除所有profile。
        """
        if self.obj.delete_all_profile() == WLAN_OK:
            log_data = u'删除所有profile成功'
            log.user_info(log_data)
        else:
            log_data = u'删除所有无线Profile失败'
            log.user_err(log_data)
            raise RuntimeError(log_data)

    def query_interface_status(self):
        """
        查询并返回当前无线网卡状态。
        """        
        if self.obj.query_interface_status() == WLAN_OK:
            interface_status = self.obj.get_return()
            if interface_status[:1] == '{' and interface_status[-1:] == '}':
                interface_status = interface_status[1:-1]           
            
            return interface_status
        else:
            log_data = u'查询网卡状态失败'
            log.user_err(log_data)
            raise RuntimeError(log_data)

    def should_be_connected(self):
        """无线网卡当前应处于连接状态"""
        if self.query_interface_status() == 'wlan_interface_state_connected':
            log_data = u'当前无线网卡处于连接状态'
            log.user_info(log_data)
        else:
            log_data = u'当前无线网卡没有连接成功'
            log.user_err(log_data)
            raise RuntimeError(log_data) 

    def should_be_disconnected(self):
        """无线网卡当前应处于断开状态"""
        if self.query_interface_status() == 'wlan_interface_state_disconnected':
            log_data = u'当前无线网卡处于断开状态'
            log.user_info(log_data)
        else:
            log_data = u'当前无线网卡处于连接状态'
            log.user_err(log_data)
            raise RuntimeError(log_data)
        
    def query_security_info(self, ssid):
        """
        获取ssid的安全属性，ssid必须是AvailableNetworkList中的一个，否则查询失败，成功返回list
        """
        security = self.obj.query_security_info(ssid)
        if WLAN_ERROR == security:
            log_data = u'查询%s的安全属性失败'%ssid
            raise RuntimeError(log_data)
        else:            
            log_data = u'查询%s的安全属性成功'%ssid
            log.user_info(log_data)
            log.user_info(security)
            return security
        
    def _query_connection_attributes(self):
        """
        查询当前连接的相关属性，成功返回字典
        """
        attr = self.obj.query_connection_attributes()
        if  WLAN_DISCONNECT == attr:
            log_data = u'当前是断开状态，不能查看连接属性。'
            raise RuntimeError(log_data)
        elif WLAN_ERROR == attr:
            log_data = u'查询当前连接属性失败'
            raise RuntimeError(log_data)
        else:
            log.user_info(attr)
            return attr
        
    def query_connection_bssid(self):
        """
        """
        attr = self._query_connection_attributes()  
        return attr.get('BSSID')
        
    def query_connection_signalquality(self):
        """
        """
        attr = self._query_connection_attributes()        
        return attr.get('Signalquality')
            
def Test():
    w = ATTWireless(0)
    #w.ssid_connect_by_WPA_PSK_TKIP('WLAN_9C39','87654321')
    w.delete_all_profile()
            
if __name__ == '__main__':
    Test()
    """
    from os.path import abspath, dirname, join
    import sys
    Ping_HOME = abspath(dirname(dirname(__file__)))
    sys.path.append(Ping_HOME)
    import attpythonpath as _____a
    from wlan.wlan import WLan
    from robotremoteserver import RobotRemoteServer
    RobotRemoteServer(Wireless(0),'0.0.0.0','58112', *sys.argv[1:])
    """
    