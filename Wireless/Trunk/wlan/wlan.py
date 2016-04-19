# -*- coding: utf-8 -*- 
#
#    nwf 2012-05-23
#    1   wireless card module  1.0
#        API return result is int, if the result fail,use GetDesc get detail
#    2   2012-08-07    + build profile(移植TCL)
#    3   2012-08-10    + 适应RF编码规范
#            + 支持多个无线网卡(index=0表示第一个插入的无线网卡; index=1表示第二个插入的无线网卡)
#    4   2012-09-27  + 一次删除所有profiles
#    5   2013-01-14  + 支持int 网卡序号 或 网卡的 网络连接 名称(注意 名称被转为description传入dll)
#    6   2013-01-21  + unicode(not support str[local])
#    8   2013-08-23  + 删除重复调用self.get_index() 添加打印信息 errorcode = 6/1003
#    9   2013-09-09  + 添加query_security_info和query_connection_attributes

import os
import sys
from ctypes import *
import cgi
import networkcardinfo

import attlog as log
from time import sleep
# nwf 2012-08-07
WLAN_OK = 1
WLAN_ERROR = -1
#add 2013-11-08
WLAN_DISCONNECT	= -2

#jias 2013-08-23
import attlog as log
WLAN_PRINT_LOG = False



#jias 2013-09-05
class SecurityStruct(Structure):
    pass
SecurityStruct._fields_ = [('success', c_int),
                            ('bSecurity', c_int),
                            ('auth', c_int),
                            ('cipher', c_int)]#,('next', POINTER(SecurityStruct))]

#jias 2013-09-05
class ConnectionAttrStruct(Structure):
    pass
ConnectionAttrStruct._fields_ = [('success', c_int),
                                ('istate', c_int),
                                ('ssid', c_wchar * 35),
                                ('bssid', c_wchar * 35),
                                ('signalquality', c_int),
                                ('rxrate', c_int),
                                ('txrate', c_int),]

class _DOT11_AUTH_ALGORITHM :
    """
    """
    DOT11_AUTH_ALGO_80211_OPEN         = 1
    DOT11_AUTH_ALGO_80211_SHARED_KEY   = 2
    DOT11_AUTH_ALGO_WPA                = 3
    DOT11_AUTH_ALGO_WPA_PSK            = 4
    DOT11_AUTH_ALGO_WPA_NONE           = 5
    DOT11_AUTH_ALGO_RSNA               = 6
    DOT11_AUTH_ALGO_RSNA_PSK           = 7
    DOT11_AUTH_ALGO_IHV_START          = 0x80000000
    DOT11_AUTH_ALGO_IHV_END            = 0xffffffff
    
class _DOT11_CIPHER_ALGORITHM :
    """
    """
    DOT11_CIPHER_ALGO_NONE            = 0x00
    DOT11_CIPHER_ALGO_WEP40           = 0x01
    DOT11_CIPHER_ALGO_TKIP            = 0x02
    DOT11_CIPHER_ALGO_CCMP            = 0x04
    DOT11_CIPHER_ALGO_WEP104          = 0x05
    DOT11_CIPHER_ALGO_WPA_USE_GROUP   = 0x100
    DOT11_CIPHER_ALGO_RSN_USE_GROUP   = 0x100
    DOT11_CIPHER_ALGO_WEP             = 0x101
    DOT11_CIPHER_ALGO_IHV_START       = 0x80000000
    DOT11_CIPHER_ALGO_IHV_END         = 0xffffffff

  
class WLan:
    """
    wireless card module
    WLan=无线网络 Wireless Lan
    """       
    m_h_wlan = CDLL(os.path.join(os.path.dirname(__file__), 'wlan.dll') )     
    # api n_ret type      
    #m_h_wlan.WLanDisconnect.restype = c_int      
    #m_h_wlan.WLanGetDesc.restype = c_int

    def __init__(self, index):
        """
        index= 0表示第一个
        无线网卡插入到PC的先后顺序
        index is unicode
        """
    
        # init
        self.index = index
        
        # Change by jxy 增加一个网卡描述变量。如果信息已经存在就不需要多次读取网卡信息。
        self.desc = None        
            
        self.p_desc = c_wchar_p() #wlan api desc
        self.p_return = c_wchar_p() #wlan api desc
        self.xmlProfile = ""        
        
        self.cname, self.cindex = self.get_index()
        
    def get_desc(self):
        """
        get wlan api desc
        """
        
        WLan.m_h_wlan.WLanGetDesc(byref(self.p_desc))
        
        return self.p_desc.value
    
    def get_return(self):
        """
        get wlan api return desc
        """
        
        WLan.m_h_wlan.WLanGetRet(byref(self.p_return))
        
        return self.p_return.value
    
    def query_security_info(self, ssid):
        """
        get wlan api return desc
        """        
        ssid_c = c_wchar_p(ssid)
        
        #win7 有时不能查到可用SSID， 重复5次规避，中间相隔5秒。
        #该方法不一定有效.
        for i in range(5):        
            WLan.m_h_wlan.WLanGetSecurityStruct.restype = POINTER(SecurityStruct)  
            p = WLan.m_h_wlan.WLanGetSecurityStruct(ssid_c, self.cname, self.cindex)
            
            #print detail info add by jias 20130823
            if WLAN_PRINT_LOG:
                info = self.get_desc()
                log.user_info(info)
                
            n_ret = p.contents.success
            if WLAN_ERROR == n_ret :
                #return n_ret
                sleep(5)
                if WLAN_PRINT_LOG:
                    log.user_info(u"再查询一次")                    
                continue
            else:
                break
        
        if WLAN_ERROR == n_ret :
            return n_ret
        
        SecurityInfo = []
        if p.contents.bSecurity == 0:
            SecurityInfo.append(u"Security is not enabled")
        else:            
            SecurityInfo.append(u"Security enabled")
        #
        if   (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_80211_OPEN == p.contents.auth):
            SecurityInfo.append(u"Open")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_80211_SHARED_KEY == p.contents.auth):
            SecurityInfo.append(u"Shared")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_WPA == p.contents.auth):
            SecurityInfo.append(u"WPA")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_WPA_PSK == p.contents.auth):
            SecurityInfo.append(u"WPAPSK")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_WPA_NONE == p.contents.auth):
            SecurityInfo.append(u"WPANone")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_RSNA == p.contents.auth):
            SecurityInfo.append(u"WPA2") #("RSNA")
            pass
        elif (_DOT11_AUTH_ALGORITHM.DOT11_AUTH_ALGO_RSNA_PSK == p.contents.auth):
            SecurityInfo.append(u"WPA2PSK") #"("RSNA with PSK")
            pass
        else:
            SecurityInfo.append(u"Other")
            pass
        #
        if  (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_NONE == p.contents.cipher):
            SecurityInfo.append(u"None")
            pass
        elif (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_WEP40 == p.contents.cipher):
            SecurityInfo.append(u"WEP40")
            pass
        elif (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_TKIP == p.contents.cipher):
            SecurityInfo.append(u"TKIP")
            pass
        elif (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_CCMP == p.contents.cipher):
            SecurityInfo.append(u"AES")#("CCMP")
            pass
        elif (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_WEP104 == p.contents.cipher):
            SecurityInfo.append(u"WEP104")
            pass
        elif (_DOT11_CIPHER_ALGORITHM.DOT11_CIPHER_ALGO_WEP == p.contents.cipher):
            SecurityInfo.append(u"WEP")
            pass
        else:
            SecurityInfo.append(u"Other")
            pass
        
        #print "SecurityInfo"
        #print SecurityInfo        
        return SecurityInfo
    
    def query_connection_attributes(self):
        """
        get wlan api return desc
        """        
        WLan.m_h_wlan.WLanQueryConnectionAttributes.restype = POINTER(ConnectionAttrStruct)   
   
        p = WLan.m_h_wlan.WLanQueryConnectionAttributes(self.cname, self.cindex)
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)   
        
        n_ret = p.contents.success
        if WLAN_ERROR == n_ret :
            return n_ret
        if WLAN_DISCONNECT == n_ret :
            return n_ret
        
        conn_attr = {}
        conn_attr['SSID'] = p.contents.ssid  #unicode
        conn_attr['BSSID'] = p.contents.bssid       
        conn_attr['Signalquality'] = p.contents.signalquality
        conn_attr['Rxrate'] = p.contents.rxrate
        conn_attr['Txrate'] = p.contents.txrate
        #print conn_attr     
        return conn_attr
    
    def _check_wep_key_len(self, key):
        """
        """
        if len(key) not in [5, 10, 13, 26]:
            log_data = u'密匙长度错误，可能导致设置profile失败(WEP加密模式下128位密匙要求输入13或26位，64为密匙要求输入5或10位)'
            log.user_info(log_data)
    
    def connect(self, ssid, timeout=30, 
                authentication="", encryption="", 
                key="", keyIndex=1):
        """
        connect wlan
        command= connect(ssid, timeout=30, authentication, encryption, key, keyIndex)
        """
        if encryption.upper() == "WEP":
            self._check_wep_key_len(key)
        
        # step1 加载profile
        n_ret = self._build_profile(ssid, authentication, encryption, key, keyIndex)
        if (WLAN_OK != n_ret):
            return n_ret
        
        n_ret = self.set_profile(self.xmlProfile)
        if (WLAN_OK != n_ret):
            return n_ret        
        
        # step2  connect
        #str_index_c, n_index_c 	= self.get_index()
        timeout_c 	= c_int(timeout)
        ssid_c		= c_wchar_p(ssid)
    
        n_ret = WLan.m_h_wlan.WLanConnect(ssid_c, self.cname, self.cindex, timeout_c) 
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)            
        
        return n_ret        

    def get_index(self):
        """
        becareful  index is unicode 
        """
        index = self.index
        if (isinstance(index, int)):
            nIndex_c = c_int(index)
            n_ret = WLan.m_h_wlan.WLanIndexExist(nIndex_c)
            
            #print detail info add by jias 20130823
            if WLAN_PRINT_LOG:
                info = self.get_desc()
                log.user_info(info)
            
            if (n_ret != WLAN_OK):                
                raise RuntimeError(u'wireless card not exist!')
        
            return c_wchar_p(u""), nIndex_c
        elif (isinstance(index, basestring)):
            # 对网卡的信息读取统一放在networkcardinfo文件中 zsj 2013/2/27
            # zsj networkcardmsg跟名为networkcardinfo 2013/3/11
            
            # Change by jxy 增加一个网卡描述变量。如果信息已经存在就不需要多次读取网卡信息。
            if not self.desc:
                self.desc = networkcardinfo.get_network_card_dsc(index)
                
            if not self.desc:
                raise RuntimeError(u'wireless card not exist!')
            
            return c_wchar_p(self.desc), c_int(-1)           
    
    def disconnect(self):
        """
        disconnect wlan
        command=disconnect()
        """
        
        #str_index_c, n_index_c 	= self.get_index()

        n_ret	= WLan.m_h_wlan.WLanDisconnect(self.cname, self.cindex)   
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret
        
        
    def set_profile(self, content):
        """
        wlan set profile
        command=set_profile(content)
        """
        
        #str_index_c, n_index_c 	= self.get_index()
        content_c	= c_wchar_p(content)

        n_ret = WLan.m_h_wlan.WLanSetProfile(content_c, self.cname, self.cindex) 
        
        #print detail info add by jias 20130823
        #ERROR_BAD_PROFILE                1206L
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret
    
    
    def get_profile(self, ssid):
        """
        wlan 
        command=get_profile(ssid)
        """
        
        #str_index_c, n_index_c 	= self.get_index()
        ssid_c=c_wchar_p(ssid)

        n_ret = WLan.m_h_wlan.WLanGetProfile(self.cname, self.cindex)
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret           
            
    def get_available_network_list(self):
        """
        wlan get available networklist
        command=get_available_network_list()
        """
        
        #str_index_c, n_index_c 	= self.get_index()

        n_ret = WLan.m_h_wlan.WLanGetAvailableNetworkList(self.cname, self.cindex) 
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret
    
    def query_interface_status(self):
        """
        wlan 
        command=query_interface()
        """
        
        #str_index_c, n_index_c 	= self.get_index()

        n_ret = WLan.m_h_wlan.WLanQueryInterface(self.cname, self.cindex)#, 6)    #add 20130221 by jias    
        #print n_ret, self.GetDesc()
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)
        
        return n_ret
        
    def delete_profile(self, ssid):
        """
        wlan 
        command=delete_profile(ssid)
        """
        
        #str_index_c, n_index_c 	= self.get_index()
        ssid_c	= c_wchar_p(ssid)

        n_ret = WLan.m_h_wlan.WLanDeleteProfile(ssid_c, self.cname, self.cindex) 
        
        #print detail info add by jias 20130823
        #ERROR_NOT_FOUND                  1168L
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret
    
    def delete_all_profile(self):
        """
        wlan 
        command=delete_all_profile()
        """
        
        #str_index_c, n_index_c 	= self.get_index()

        n_ret = WLan.m_h_wlan.WLanDeleteProfiles(self.cname, self.cindex) 
        
        #print detail info add by jias 20130823
        if WLAN_PRINT_LOG:
            info = self.get_desc()
            log.user_info(info)    
        
        return n_ret    
    
    
    #  support method----------------------------------------------------------
    #
    def _get_ssid_hex(self, ssid):
        """
        把ssid 每个字符ascii码 求出来 组成字符串(全部大写 0123456789ABCDEF)
        """
        ssid_hex=""
        
        for c in ssid:
            ssid_hex +="%X" %(ord(c) )
        
        return ssid_hex
    
    def _build_profile(self, ssid, 
                            authentication="",  encryption="", 
                            key="", keyIndex=1):
        """
        profile xml ,ref wireless's profile
        support method
            authentication= eg  ["shared", "open", "WPA2PSK", "WPAPSK"] 
            encryption=     eg  ["none", "WEP", "AES", "TKIP"]
            key=            eg  [WEP default=1234567890; other default=12345678]
            
        """
        n_ret = WLAN_ERROR
        # 增加参数错误的判断
        value_error = 0       
        
        # loop once
        for x in [1]:
            # 开始对参数进行预处理（authentication和encryption修改为大小写不区分模式）
            # change by yzm @ 20121010
            # 支持的参数值
            encryption_support = ["none", "WEP", "AES", "TKIP"]
            authentication_support = ["shared", "open", "WPA2PSK", "WPAPSK"]
            
            # 参数检查并更新
            if encryption.upper() not in '^'.join(encryption_support).upper().split('^'):
                log_data = "encryption not in ", encryption_support
                log.user_info(log_data)
                value_error +=1
                break
            else:
                if encryption.lower() == 'none':
                    encryption = encryption.lower()
                else:
                    encryption = encryption.upper()
            
            if authentication.upper() not in '^'.join(authentication_support).upper().split('^'):
                log_data = "authentication not in ", authentication_support
                log.user_info(log_data)
                value_error +=1
                break
            else:
                if authentication.lower() == 'shared' or authentication.lower() == 'open':
                    authentication = authentication.lower()
                else:
                    authentication = authentication.upper()

            
            # 参数匹配 
            if ((encryption in ["none", "WEP"]) and (authentication not in ["shared", "open"])):
                log_data = "encryption in (none, WEP), authentication not in (shared, open)"
                log.user_info(log_data)
                value_error +=1
                break    
            
            if ((encryption in ["AES", "TKIP"]) and (authentication not in ["WPA2PSK", "WPAPSK"])):
                log_data = "encryption in (AES, TKIP), authentication not in (WPA2PSK, WPAPSK)"
                log.user_info(log_data)
                value_error +=1
                break
            
            # key  默认值
            if ("" == key):
                if ("WEP" == encryption):
                    key = "1234567890"
                else:
                    key = "12345678"
                    
            #keyIndex-1
            keyIndex = keyIndex-1
                    
            # ssid 特殊字符处理
            ssid_hex = self._get_ssid_hex(ssid)            
            ssid_special = cgi.escape(ssid)
            # keyMaterial 特殊字符处理
            key_special = cgi.escape(key)

            # wpa-psk  64位特殊处理  keyType=networkKey
            keytype_special = "passPhrase"
            if ((len(key) == 64) and
                (authentication in ["WPAPSK", "WPA2PSK"]) ):
                keytype_special = "networkKey"

            #先生成公共的头部和加密类型的xml代码
            xmlProfile = u""
            xmlProfile += """<?xml version=\"1.0\"?>
<WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\">
    <name>%s</name>
    <SSIDConfig>
        <SSID>
            <hex>%s</hex>
            <name>%s</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <MSM>
        <security>
            <authEncryption>
                <authentication>%s</authentication>
                <encryption>%s</encryption>
                <useOneX>false</useOneX>
            </authEncryption>""" %(ssid_special,ssid_hex, ssid_special, authentication, encryption)
            #生成加密密钥部分的代码
            if ("none" == encryption):
                xmlProfile += """
        </security>
    </MSM>
</WLANProfile>"""
            elif ("WEP" == encryption):
                xmlProfile += """
                        <sharedKey>
                <keyType>networkKey</keyType>
                <protected>false</protected>
                <keyMaterial>%s</keyMaterial>
            </sharedKey>
            <keyIndex>%s</keyIndex>
        </security>
    </MSM>
</WLANProfile>""" %(key_special, keyIndex)
            else :
                xmlProfile += """
                    <sharedKey>
                <keyType>%s</keyType>
                <protected>false</protected>
                <keyMaterial>%s</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>"""  % (keytype_special, key_special)    
            
            n_ret = WLAN_OK  # 都成功 才成功
            self.xmlProfile = xmlProfile            
            #print xmlProfile            
        
        if value_error != 0:
            raise ValueError(u"加密认证参数配置不合法或其组合不合法，请检查输入。")
        return n_ret                 


def Test():
    
    from time import ctime,sleep    
    
    print u'start test...'
    #wlan1=WLan(u"中文无线1")
    wlan1=WLan(0)

    wlan1.get_security_info(u"ASUS-60")
    print "a"
    wlan1.query_interface_status()
    print "b"
    wlan1.query_connection_attributes()
    print "c"
    
    return
  

if __name__ == '__main__':        
    
    Test()
    print 'start end...'
