# -*- coding: utf-8 -*- 
import os
import sys
import platform
from os.path import join, dirname
import re

import time
import datetime

import _winreg
import subprocess 
from ctypes import *
import networkcardinfo    # modify by shenlige 2013-6-3
import attlog as log

NETCONFIG_SUCCESS = 0
NETCONFIG_FAIL = -1

EXECUTE_PATH = dirname(dirname(dirname(__file__)))

X86_EXE_PATH = join(EXECUTE_PATH, "plugin","Netconfig","resource","devcon_x86.exe")
X64_EXE_PATH = join(EXECUTE_PATH, "plugin","Netconfig","resource","devcon_x64.exe")

#本地连接

class ATTNetConfig():

    def __init__(self, name_or_mac):
        # 先假定是mac地址，如果判断格式和mac地址一样（支持00-1C-85-11-15-FF
        # 和00:1C:85:11:15:FF形式的mac地址），则按mac地址配置，否则按name进行配置
        self.name_or_mac = name_or_mac
        self.nic_index = None  # 使用索引进行初始化modify by shenlige
        self._create_nic_config()
        
        
    def _create_nic_config(self):
        """
        把创建nic_config提前出来做为公共部分
        """
        # zsj modified 2013/2/27
        # zsj networkcardmsg跟名为networkcardinfo 2013/3/11
        # 使用索引进行初始化 modify shenlige 2013-4-6
        if self.nic_index:
            obj_nic_config,index = networkcardinfo.get_network_card_obj(self.nic_index)
        else:
            obj_nic_config,index = networkcardinfo.get_network_card_obj(self.name_or_mac)
        
        if obj_nic_config:
            self.name = obj_nic_config.associators()[0].NetConnectionID
            self.mac_address = obj_nic_config.MACAddress # zsj modified 2013-3-27
            self.nic_config = _NetConfig(obj_nic_config,self.name)
            self.nic_index = index
        else:
            raise ValueError,  u'没有找到匹配的网络适配器。'

    def get_nic_ipv4_address(self):
        '''返回当前网卡的IPv4地址，如果没有查找到或者当前网卡没有IPv4地址，返回None。
        TODO：目前只考虑了单IP的情况，多IP暂没考虑。'''
        
        # 防止每次读的缓存存在，查询的时候，每次均新建对象来进行处理；
        self._create_nic_config()   # zsj  modified 2013/2/18
        
        # 暂不考虑多个IP的情况，默认取第一个
       
        ipv4_address_temp = self.nic_config.get_nic_ipv4_address()
        
        if ipv4_address_temp == None:
            log_data = u'名为 \"%s\" 的网卡未启用，ipv4地址返回为None' % self.name
            log.user_info(log_data)
            return None
            # raise RuntimeError(u'查找Mac地址为 %s 名称为 \"%s\" 的网卡的IPv4地址失败，当前网卡可能处于断开状态' % (mac_address, self.nic_config.name))
        elif ipv4_address_temp == []:
            # 兼容列表返回为空时的情况，执行网卡禁用启用操作时出现获取到ipv4地址为空列表的情况
            
            return None
        elif ipv4_address_temp[0] == u'0.0.0.0/':      
            # 网卡断开时拿到ip地址为0.0.0.0；
            # 此时统一返回None modify by shenlige 2013-4-10
            log_data = u'名为 \"%s\" 的网卡连接断开或连接受限，ipv4地址返回为None' % self.name
            log.user_info(log_data)
            return None
        else:
            # 支持多个ipv4地址，返回地址类型为ip_address/subnet  modify  by shenlige  2013-3-26
            ipv4_address = ipv4_address_temp
            log_data = u'查找Mac地址为 %s 名称为 \"%s\" 的网卡IP成功，IP地址为：%s' % (self.mac_address, self.name,ipv4_address)
            log.user_info(log_data)
            return ipv4_address
 
    # 将DNS的设置从接口中分割出来
    def config_nic_to_ipv4_static_address(self, ip_address, ip_subnet='255.255.255.0', gateway = ''):
        '''
        配置当前网卡IP为'ip_address'，掩码为'ip_subnet'（默认为255.255.255.0），网关为'gateway'，Dns服务器为'dns'。
        '''
        log_data = u'开始配置MAC地址为 %s 名称为 \"%s\" 的网卡IP地址为 %s 子网掩码为 %s ' % (self.mac_address, self.name, ip_address, ip_subnet)
        log.user_info(log_data)
        if gateway != '':
            log_data = u'网关为 %s ' % gateway
            log.user_info(log_data)
        
        self._set_static_ip(ip_address, ip_subnet=ip_subnet, gateway = gateway)

    def config_nic_to_ipv4_dhcp(self):
        '''配置当前网卡为DHCP模式'''
        log_data = u'开始配置MAC地址为 %s 名称为 \"%s\" 的网卡为DHCP模式' %(self.mac_address, self.name)
        log.user_info(log_data)
        ret = NETCONFIG_SUCCESS
        pc_system = self.judge_system()
        for i in [1]:
            # win7 系统下先删除原有的默认网关，然后再配置DHCP add by shenlige 2013-4-10
            if pc_system == 1:
                pass
            elif pc_system == 2:
            # 获取当前网卡的索引
                result, result_data = self._netsh_cmd('netsh interface ipv4 show interface')
                result_data = result_data.split("\n")
            
                nic_index = None              # 默认网卡不在列表中，索引为None
                for i in result_data:
                
                    if self.name in i:
                        i = i.strip()
                        tmp_list = i.split(" ")    
                        nic_index = tmp_list[0]
                        break
                
                if  nic_index == None:
                    log_data = u"名称为 %s 的网卡未启用，获取不到网卡索引" % self.name
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
                # 删除当前网卡所有的默认网关
                result, result_data = self._netsh_cmd('netsh interface ipv4 show route')
                result_data = result_data.split("\r\n")
        
                for i in result_data:
                    if i != '':
                        list_result = []
                        tmp_list = i.split(" ")
                        
                        # 去掉split后的空字符串
                        for element in tmp_list:
                            if element != "":
                                list_result.append(element)
                        
                        if "0.0.0.0/0" in i and nic_index == list_result[4]:
                            # 删除当前网卡的默认ipv4网关                            
                            result, result_data = self._netsh_cmd('netsh interface ipv4 delete route prefix="0.0.0.0/0" interface="%s" ' % nic_index)  # 接口名称修改为网卡索引，配置DHCP方式时，删除默认网关长期有效
                            if result == 1:
                                log_data = u"通过netsh命令删除ipv4默认网关成功"
                                log.user_info(log_data)
                            else:
                                log_data = u"通过netsh命令删除ipv4默认网关失败，详细原因： %s" % result_data
                                log.app_err(log_data)
                                ret =  NETCONFIG_FAIL
                                break    
            
                if ret ==  NETCONFIG_FAIL:
                    break
            else:
                pass
        
        if ret ==  NETCONFIG_FAIL:
            log.app_err(log_data)
           
        self._enable_dhcp() 
        time.sleep(2) # 增加短暂时间，确保release操作正常 modify by shenlige 2013-4-12
        
        # DHCP后强行release、renew  add by shenlige 2013-4-2
        self.nic_dhcpv4_release()
        self.nic_dhcpv4_renew()

    def _set_static_ip(self, ip_address, ip_subnet='255.255.255.0', gateway = ''):
        interface_name = self.nic_config.get_interface_name()
        pc_system = self.judge_system()
       
        ret_set_ip = self.nic_config.set_nic_ip_address(ip_address, ip_subnet)
        
        if pc_system == 1:    
            if ret_set_ip == 0:
                # 如果失败，换用netsh去修改
                log_data =  u'开始尝试通过netsh命令修改网卡IP地址信息'
                log.user_info(log_data)
                ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static addr=%s mask=%s' % 
                                               (interface_name, ip_address, ip_subnet))
                log_data = u'通过netsh命令修改网卡IP地址信息完毕.修改结果：%s' % ret_data
            
                if ret == 1:
                    log.user_info(log_data)
                else:
                    raise RuntimeError(log_data)
                
            if self.nic_config.set_nic_gateway(gateway) == 0:
                if gateway != '':
                    log_data = u'开始尝试通过netsh命令修改网关'
                    log.user_info(log_data)
                    ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static gateway=%s gwmetric=0' %  
                                              (interface_name, gateway))             
                    log_data = u'通过netsh命令修改网关完毕.修改结果：%s' % ret_data
                else:
                    log_data = u'开始尝试通过netsh命令修改网关'
                    log.user_info(log_data)
                    ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static gateway=%s' %  
                                              (interface_name, "none"))             
                    log_data = u'通过netsh命令修改网关完毕.修改结果：%s' % ret_data
                
                if ret == 1:
                    log.user_info(log_data)
                else:
                    raise RuntimeError(log_data)
    
        elif pc_system == 2:
            ret = -1
            if ret_set_ip == 0:
                if gateway != "":                    
                    log_data =  u'开始尝试通过netsh命令修改网卡IP地址信息和默认网关'
                    log.user_info(log_data)
                    ret,ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static addr=%s mask=%s gateway=%s' % 
                                             (interface_name, ip_address, ip_subnet, gateway))
                    log_data = u'通过netsh命令修改网_netsh_cmd卡IP地址信息和默认网关完毕.修改结果：%s' % ret_data
                else:
                    log_data =  u'开始尝试通过netsh命令修改网卡IP地址信息'
                    log.user_info(log_data)
                    ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static addr=%s mask=%s' % 
                                              (interface_name, ip_address, ip_subnet))
                    log_data = u'通过netsh命令修改网卡IP地址信息和默认网关完毕.修改结果：%s' % ret_data
                
            elif self.nic_config.set_nic_gateway(gateway) == 0:
                if gateway != "":
                    log_data = u'开始尝试通过netsh命令修改网关'
                    log.user_info(log_data)
                    ret,ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static addr=%s mask=%s gateway=%s' % 
                                             (interface_name, ip_address, ip_subnet, gateway))
                    log_data = u'通过netsh命令修改网关完毕.修改结果：%s' % ret_data
                else:
                    log_data =  u'开始尝试通过netsh命令修改网卡IP地址信息'
                    log.user_info(log_data)
                    ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=static addr=%s mask=%s' % 
                                              (interface_name, ip_address, ip_subnet))
                    log_data = u'通过netsh命令修改网卡IP地址信息和默认网关完毕.修改结果：%s' % ret_data
            if ret == 1:
                log.user_info(log_data)
            elif ret == 0:
                raise RuntimeError(log_data)
            else:
                pass
            
    
    # 将dns服务器的配置从静态地址配置中分割出来 add by shenlige 2013-3-28
    def config_nic_ipv4_dns_server(self,dns = ''):
        """
        功能描述：配置ipv4 dns服务器地址，默认为空，即不改变当前dns服务器配置模式
        参数：
                dns：dns服务器的ip地址，list形式
        返回：无
        """
        self._create_nic_config()  # 重新初始化网卡对象  add by shenlige 2013-5-8
        interface_name = self.nic_config.get_interface_name()
        pc_system = self.judge_system()
        
        dhcp_enabled = self.nic_config.get_ipv4_dhcp_enabled()
        
        if dhcp_enabled:
            if dns == "None" or dns == "none" or dns == '':
                # 如果判断当前网卡为DHCP方式，用户配置dns参数为"None"或空字符串时，设置DNS为DHCP模式
                if self.nic_config.enable_dns_dhcp() == 0:
                    # 如果WMI失败，则用netsh命令实现
                    self._nic_ipv4_set_dns_to_dhcp_by_netsh()
            else:
                if pc_system == 1:
                    if self.nic_config.set_nic_dns(dns) == 0:
                        # 如果失败，换用netsh去修改
                        # 如果不配置dns服务器，此时netsh 命令中的addr=none
                        for tmp_dns in dns:
                            # 输入的dns为list形式
                            log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                            log.user_info(log_data)
                            ret, ret_data = self._netsh_cmd('netsh interface ip set dns name="%s" source=static addr=%s' % 
                                              (interface_name, tmp_dns)) 
                            log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                            if ret == 1:
                                log.user_info(log_data)
                            else:
                                raise RuntimeError(log_data)
                elif pc_system == 2:
                    if self.nic_config.set_nic_dns(dns) == 0:
                        # 如果失败，换用netsh去修改
                        # 设置dns服务器地址前，先删除dns列表
                        self._nic_ipv4_clear_dns_list_by_netsh()
                            
                        for tmp_dns in dns:
                            # 输入的dns为list形式
                            log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                            log.user_info(log_data)
                            ret, ret_data = self._netsh_cmd('netsh interface ip add dnsservers name="%s" address=%s validate=no' % 
                                              (interface_name, tmp_dns)) 
                            log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                            if ret == 1:
                                log.user_info(log_data)
                            else:
                                raise RuntimeError(log_data)
                else:
                    pass
        
        else:
            if dns == "None" or dns == "none":
                # 静态地址时，如果参数设置为“None”时，清除dns列表
                self._nic_ipv4_clear_dns_list_by_netsh()
            elif dns == '':
                pass
            else:
                if pc_system == 1:
                    if self.nic_config.set_nic_dns(dns) == 0:
                            
                        # 如果失败，换用netsh去修改，修改前先清空原DNS服务器列表
                        self._nic_ipv4_clear_dns_list_by_netsh()
                        
                        for tmp_dns in dns:
                            # 输入的dns为list形式
                            log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                            log.user_info(log_data)
                            ret, ret_data = self._netsh_cmd('netsh interface ip set dns name="%s" source=static addr=%s' % 
                                              (interface_name, tmp_dns)) 
                            log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                            if ret == 1:
                                log.user_info(log_data)
                            else:
                                raise RuntimeError(log_data)
                elif pc_system == 2:
                    if self.nic_config.set_nic_dns(dns) == 0:
                            
                        # 如果失败，换用netsh去修改，修改前先清空原DNS服务器列表
                        self._nic_ipv4_clear_dns_list_by_netsh()
                        
                        for tmp_dns in dns:
                            # 输入的dns为list形式
                            log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                            log.user_info(log_data)
                            ret, ret_data = self._netsh_cmd('netsh interface ip add dnsservers name="%s" address=%s validate=no' % 
                                              (interface_name, tmp_dns)) 
                            log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                            if ret == 1:
                                log.user_info(log_data)
                            else:
                                raise RuntimeError(log_data)
                else:
                    pass
                            
    
    def _nic_ipv4_clear_dns_list_by_netsh(self):
        """
        功能描述：通过netsh命令清除dns服务器列表
        参数：无
        返回值：无
        """
        pc_system = self.judge_system()
        if pc_system == 1:
            
            log_data = u'开始尝试通过netsh命令清除DNS服务器列表'
            log.user_info(log_data)
            ret, ret_data = self._netsh_cmd('netsh interface ip set dns name="%s" source=static addr=%s' % 
                        (self.name, "none")) 
            log_data = u'通过netsh命令清除DNS服务器列表完毕.修改结果：%s' % ret_data
        elif pc_system == 2:
            log_data = u'开始尝试通过netsh命令清除DNS服务器列表'
            log.user_info(log_data)
            ret, ret_data = self._netsh_cmd('netsh interface ip set dns name="%s" source=static addr=%s validate=no' % 
                        (self.name, "none")) 
            log_data = u'通过netsh命令清除DNS服务器列表完毕.修改结果：%s' % ret_data
        else:
            pass
        
        if ret == 1:
            log.user_info(log_data)
        else:
            raise RuntimeError(log_data)
   
    def _nic_ipv4_set_dns_to_dhcp_by_netsh(self):
        """
        功能描述：通过netsh命令设置dns为自动获取方式
        参数：无
        返回值：无
        """
        log_data = u'开始尝试通过netsh命令修改DNS服务器为自动获取'
        log.user_info(log_data)
        ret, ret_data = self._netsh_cmd('netsh interface ip set dns name="%s" source=dhcp' % self.name) 
        log_data = u'通过netsh命令修改DNS服务器为自动获取完毕.修改结果：%s' % ret_data
        if ret == 1:
            log.user_info(log_data)
        else:
            raise RuntimeError(log_data)      
        
   
    #  将dns的设置从接口中分割出来 modify by shenlige 2013-3-28    
    def _enable_dhcp(self):
        interface_name = self.nic_config.get_interface_name()
        if self.nic_config.enable_dhcp() == 0:
            # 如果wmi修改失败，则尝试使用netsh修改（无线网卡断开的时候，用wmi修改失败，但用netsh可以修改成功）
            #             add by yzm @ 20121009
            
            log_data = u'开始尝试通过netsh命令网卡ip为DHCP模式'
            log.user_info(log_data)
            ret, ret_data = self._netsh_cmd('netsh interface ip set address name="%s" source=dhcp' % interface_name)
            log_data = u'通过netsh命令网卡ip为DHCP模式完毕,配置结果：%s' % ret_data
            if ret == 1:
                log.user_info(log_data)
            else:
                raise RuntimeError(log_data)
            
    
    # 将cmd命令执行结果的判断从_exec_cmd函数中拆分出来  modified by shenlige 2013-3-12  
    def _exec_cmd(self, cmd):
        """执行系统命令"""
        # TODO 需要增加对执行结果的判断    add by yzm @ 20121010
        pid = subprocess.Popen(cmd.encode(sys.getfilesystemencoding()), 
                               shell=True, 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.STDOUT)
        # 修改了调用cmd命令后读取运行结果返回用户 zsj 2013/2/25
        sub_return = pid.stdout.read()
        
        return sub_return
        
    def judge_system(self):
        """
        功能描述： 获取当前系统描述
        return:
                1--xp system
                2--win7 system
                3--else system
        """
        import wmi
        wmishell = wmi.WMI()
        os_info = wmishell.Win32_OperatingSystem()[0].Caption
        if "xp" in os_info.lower():
            return 1
        elif "7" in os_info:
            return 2
        else:
            return 3
    
    # 增加netsh命令结果判断的接口
    def _netsh_cmd(self,cmd):
        """
        功能描述：对cmd命令行中的返回结果进行判断
        return：
                1 ---执行成功
                0 ---执行失败
        """
        result = self._exec_cmd(cmd)
        pc_system = self.judge_system()
        result = result.decode(sys.getfilesystemencoding())
        if pc_system == 1:
            if u"确定" in result:
                ret = 1
                ret_data = u"配置成功"
            elif  u"已经" in result:
                ret = 1
                ret_data = result
            elif u"WINS 服务器" in result:
                ret = 1
                ret_data = result
            else:
                ret = 0
                ret_data = result
        elif pc_system == 2:
            if len(result) == 2:
                ret = 1
                ret_data = u"配置成功"
            elif u"已在" in result:
                # win7下，dhcp生效后返回“已在此接口上启用dhcp” modify by shenlige 2013-3-15
                ret = 1
                ret_data = result
            elif u"WINS 服务器" in result:
                ret = 1
                ret_data = result
            elif u"确定" in result:
                # 增加下发ipv6命令时的返回 add by shenlige 2013-3-19
                ret = 1
                ret_data = result
            elif "WINS servers" in result or "WINS Servers" in result:
                # 增加英文版获取WINS的成功返回信息 add by shenlige 2013-3-21
                ret = 1
                ret_data = result       
            elif "Ok" in result:
                # 增加英文版ipv6的成功返回信息 add by shenlige 2013-3-21
                ret = 1
                ret_data = result
            elif "exists" in result: 
                # 增加英文版win7 下添加一个已存在ipv6地址时的返回 add by shenlige 2013-3-21
                ret = 1
                ret_data = result
            elif "already" in result:
                # 增加英文版win7 下设置本身已经是dhcp方式的网卡为dhcp方式时的返回 add by shenlige 2013-4-1
                ret = 1
                ret_data = result
            else:
                ret = 0
                ret_data = result
        else:
            ret = 0
            ret_data = u"当前系统暂不支持netsh指令"
    
        return ret, ret_data
    
    # 增加devcon命令结果返回的判断 add by shenlige 2013-3-12
    def _devcon_cmd(self,cmd):
        """
        功能描述：对devcon中命令的返回结果做判断
        return：
                1 ---执行成功
                0 ---执行失败 
        """
        result = self._exec_cmd(cmd)
        result = result.decode(sys.getfilesystemencoding())
        # devcon中网卡启用禁用的判断 add by shenlige 2013-3-12
        if "Disabled" in result:
            ret = 1
            ret_data = result
        elif "Enabled" in result:
            ret = 1
            ret_data = result
        else:
            ret = 0
            ret_data = result
        return ret, ret_data    
        
    
    # 获取mac地址 add by shenlige 2013-3-9
    def get_nic_mac_address(self):
        """
        功能描述：获取当前网卡的MAC地址
        return：
                mac_addr
        """
        ret = NETCONFIG_SUCCESS
        self._create_nic_config()
        try:
            mac_addr = self.mac_address
            # 网卡未启用时MAC返回为None
            if mac_addr == None:
                log_data = u"当前网卡未启用，获取到的MAC为None"
                log.user_info(log_data)
            
            else:
                log_data = u"当前网卡MAC地址为：%s" % mac_addr
                log.user_info(log_data)
        except Exception, e:
            log_data = u"获取名为%s 网卡的MAC地址发生异常： %s" % (self.name,e)
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return mac_addr
    
    
    #
    def _check_nic_status(self):
        """
        功能描述：检查当前网卡状态
        返回：
                0  ：当前网卡连接正常
                1  ：当前网卡断开或连接受限
                2  ：当前网卡禁用
              
        """
        mac_addr = self.get_nic_mac_address()
        ip_addr = self.get_nic_ipv4_address()
            
        if mac_addr == None:
            ret = 2
        elif ip_addr == None:
            ret = 1
        else:
            ret = 0
        return ret
        
    
    # 获取网关地址 add by shenlige 2013-3-9
    # 网卡为启用或连接断开时，网关获取异常，抛出该异常
    def get_nic_ipv4_gateway(self):
        """
        功能描述：获取当前网卡的网关地址
        return:
                gateway
        """
        
        ret = NETCONFIG_SUCCESS
        connect_status =  self._check_nic_status()
        
        if connect_status == 1:            
            log_data = u"当前网卡断开或连接受限，网关返回为None"
            log.user_info(log_data)
            gateway = None
        elif connect_status == 2:
            log_data = u"当前网卡未启用，网关返回为None"
            log.user_info(log_data)
            gateway = None
        else:
            try:
                gateway = self.nic_config.get_nic_ipv4_gateway()
                # win7系统接测试网，会有ipv6的fe80::XXXX的网关网关
                # 此时获取到的ipv4网关为[],这里统一处理为None   add by shenlige 2013-6-19
                if gateway == []:
                    gateway = None
                
                log_data = u"当前网卡网关为：%s" % gateway
                log.user_info(log_data)
            
            except Exception, e:
                if e[0] == "'NoneType' object is not iterable":
                    log_data = u"网卡未启用或连接断开或静态IP未配置网关，返回None"
                    log.user_info(log_data)
                    gateway = None
                else:
                    log_data = u"当前网卡未启用或连接断开或连接受限，获取网关发生异常：%s" % e
                    log.app_err(log_data)
                    ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return gateway
    
   
    def get_nic_ipv4_dhcp_server(self):
        """
        功能描述：获取当前DHCP服务器地址
        """
        # 如果当前网卡未启用或连接断开或静态地址，获取到的返回值为None，不做异常处理，给出LOG提示
        # 连接受限时返回为255.255.255.255
        
        ret = NETCONFIG_SUCCESS
        connect_status =  self._check_nic_status()
        
        if connect_status == 1:
            
            log_data = u"当前网卡断开或连接受限，DHCP Server为None"
            log.user_info(log_data)
            ip_dhcpserver = None
        elif connect_status == 2:
            log_data = u"当前网卡未启用，DHCP Server为None"
            log.user_info(log_data)
            ip_dhcpserver = None
        else:   
            try:
                ip_dhcpserver =self.nic_config.get_nic_ip_dhcpserver()
            
                if ip_dhcpserver == None:
                    log_data = u"当前网卡未启用或连接断开或静态IP地址，DHCP Server为None"
                    log.user_info(log_data)        
                else:
                    log_data = u"当前DHCP Server的ip地址为：%s" % ip_dhcpserver
                    log.user_info(log_data)
            except Exception, e:
                log_data = u"获取名为%s 网卡的dhcp服务器发生异常： %s" % (self.name,e)
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)

        return ip_dhcpserver
    
    # 获取当前网卡DNS服务器地址 add by shenlige 2013-3-11
    def get_nic_ipv4_dns_server(self):
        """
        功能描述：获取当前DNS服务器地址
        """
        ret = NETCONFIG_SUCCESS       
        connect_status =  self._check_nic_status()
        
        if connect_status == 1:
            
            log_data = u"当前网卡断开或连接受限，DNS服务器地址返回None"
            log.user_info(log_data)
            ip_dnsserver = None
        elif connect_status == 2:
            
            log_data = u"当前网卡未启用，DNS服务器地址返回None"
            log.user_info(log_data)
            ip_dnsserver = None
        else:   
            try:
                tmp_ip_dnsserver =self.nic_config.get_nic_dns()           
                # 如果网卡断开或未启用，ip_dnsserver为None,
                if tmp_ip_dnsserver != None:
                    # 将返回值统一格式，以list形式返回，而不是WMI原始的元组形式
                    ip_dnsserver = []
                    len_dns = len(tmp_ip_dnsserver)
                    for i in range(len_dns):
                        ip_dnsserver.append(tmp_ip_dnsserver[i])
                        
                    log_msg = u"当前DNS Server的ip地址为："
                    while len_dns:
                        len_dns -= 1
                        log_msg = log_msg + " %s"
                    log_data = log_msg % tmp_ip_dnsserver 
                    log.user_info(log_data)
                else:
                    log_data = u"当前网卡未启用或连接断开或连接受限或静态IP未配置DNS，DNS服务器返回为None"
                    log.user_info(log_data)
                    ip_dnsserver = None
            except Exception, e:
                log_data = u"获取当前网卡DNS服务器地址发生异常：%s" % e
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return ip_dnsserver
    
    # 获取当前租约时间 add by shenlige  2013-3-10 
    def get_nic_ipv4_dhcp_lease_time(self):
        """
        功能描述：获取当前租约时间，该时间是租约到期时间与租约获取时间的差，单位为妙
        return:
                time_dhcplease --- 租约时间，单位为秒(s)
        """
        
        ret = NETCONFIG_SUCCESS
        connect_status =  self._check_nic_status()
        
        if connect_status == 1:
            
            log_data = u"当前网卡断开或连接受限，DHCP租约时间返回为None"
            log.user_info(log_data)
            time_dhcplease = None
        elif connect_status == 2:
            log_data = u"当前网卡尚未启用，DHCP租约时间返回为None"
            log.user_info(log_data)
            time_dhcplease = None
        else:   
            try:
                time_dhcplease = self.nic_config.get_nic_dhcpleasetime()
                # 网卡未启用时，静态IP时WMI获取到的租约到期时间和租约获得时间均为None
                
                if time_dhcplease != None:
                    log_data = u"当前网卡DHCP租约时间为：%s 秒" % time_dhcplease
                    log.user_info(log_data)
                else:
                    log_data = u"当前网卡未启用或静态地址，DHCP租约时间返回为None"
                    log.user_info(log_data)
                    
            except Exception, e: 
                log_data = u"获取名为%s 网卡的dhcp租约时间发生异常： %s" % (self.name,e)
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return time_dhcplease
    
    # 对当前网卡进行release操作 add by shenlige 2013-3-11
    # release、releasenew只能对DHCP方式的网卡设备生效
    def nic_dhcpv4_release(self):
        """
        功能描述：对当前网卡执行release操作
        """
        ret = NETCONFIG_SUCCESS
        try:
            result = self.nic_config.nic_dhcp_release()
            log_data = u"通过WMI对MAC地址为 %s 的网卡执行release操作成功，WMI返回码为：%s" % (self.mac_address,result)
            log.user_info(log_data)
            
        except Exception, e: 
            log_data = u"对当前网卡执行release操作发生异常： %s" % e
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return 1
    
    # 对当前网卡进行renew操作add by shenlige  2013-3-11 
    def nic_dhcpv4_renew(self):
        """
        功能描述：对当前网卡执行renew操作
        """
        ret = NETCONFIG_SUCCESS
        try:
            result = self.nic_config.nic_dhcp_renew()
            log_data = log_data = u"通过WMI对MAC地址为 %s 的网卡执行renew操作成功，WMI返回码为：%s" % (self.mac_address,result)
            log.user_info(log_data)
            
        except Exception, e: 
            log_data = u"对当前网卡执行renew操作发生异常： %s" % e
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return 1
    
    # 启用网卡add by shenlige 2013-3-12 
    def enable_nic_card(self):
        """
        功能描述：启用当前网卡
        """
        ret = NETCONFIG_SUCCESS
        #修改可执行文件路径 modify by shenlige 2013-5-22
        
        cpu_bits = platform.machine()
        
        # PC机内存位数不同，所使用的文件时不同的
        if cpu_bits == "32bit" or cpu_bits == "x86":
            devcon_path = X86_EXE_PATH
        else:
            devcon_path = X64_EXE_PATH
        
        pnp_instance_ID = networkcardinfo.get_network_pnp_instance_id(self.nic_index)
        if pnp_instance_ID:
            cmd_str = "\"" + devcon_path + "\"" +" enable @" + '"' + pnp_instance_ID + '"'
            result,result_data = self._devcon_cmd(cmd_str)
            
            if result == 1:
                # 网卡启用后加10s的时延  modify by shenlige 2013-3-14
                time.sleep(10)
                log_data = u"名称为 %s 的网卡启用成功." % self.name
                log.user_info(log_data)    
            else:
                log_data = u"名称为 %s 的网卡启用异常： %s" % (self.name,result_data)
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
        else:
            log_data = u"获取网卡对象发生异常，PnpInstanceID获取失败."
            ret = NETCONFIG_FAIL
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return 1
        
    # 禁用网卡 add by shenlige  2013-3-12  
    def disable_nic_card(self):
        """
        功能描述：禁用当前网卡
        """
        ret = NETCONFIG_SUCCESS
        #修改可执行文件路径 modify by shenlige 2013-5-22
      
        cpu_bits = platform.machine()
        
        # PC机内存位数不同，所使用的文件时不同的
        if cpu_bits == "32bit" or cpu_bits == "x86":
            devcon_path = X86_EXE_PATH
        else:
            devcon_path = X64_EXE_PATH
        
        pnp_instance_ID = networkcardinfo.get_network_pnp_instance_id(self.name_or_mac)
        
        if pnp_instance_ID:
            cmd_str = "\"" + devcon_path + "\"" + " disable @" + '"' + pnp_instance_ID + '"'
            result,result_data = self._devcon_cmd(cmd_str)
            
            if result == 1:
                log_data = u"名称为 %s 的网卡禁用成功." % self.name
                log.user_info(log_data)
            else:
                log_data = u"名称为 %s 的网卡禁用异常： %s" % (self.name,result_data)
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
        else:
            log_data = u"获取网卡对象发生异常，PnpInstanceID获取失败."
            ret = NETCONFIG_FAIL
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return 1    
    
    # 网卡重启  add by shenlige 2013-3-14
    def restart_nic_card(self):
        """
        功能描述：实现网卡的重启
        return：
                无
        """
        ret = NETCONFIG_SUCCESS
        try:
            self.disable_nic_card()
            self.enable_nic_card()
            log_data = u"名称为 %s 的网卡重启成功" % self.name
            log.user_info(log_data)
        except Exception, e: 
            log_data = u"名称为 %s 的网卡重启异常：%s" % (self.name,e)
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return 1
    
    
   
    # 通过netsh命令获取WINS服务器  add by shenlige   2013-3-12
    # 因WMI最多只能获取两个WINS服务器地址，因此这里采用netsh命令来获取
    def get_nic_ipv4_wins(self):
        """
        功能描述：获取网卡的WINS服务器列表
        return:
                wins_ip --- WINS ip地址
        """
        ret = NETCONFIG_SUCCESS
        
        result, result_data = self._netsh_cmd('netsh interface ip show wins name="%s"' % self.name)
        re_str = "([0-9]+.){3}[0-9]+"
        str_list = result_data.split(" ")
        wins_ip = []
        connect_status =  self._check_nic_status()
        
        if connect_status == 2:
            log_data = u"当前网卡未启用，获取到的WINS服务器为None"
            log.user_info(log_data)
            wins_ip = None
        else:
            if result == 1:
                for i in str_list:
                    m = re.match(re_str,i)
                    if m:
                        tmp_ip = m.group()
                        wins_ip.append(tmp_ip)
                len_wins = len(wins_ip)
                if len_wins:
                    log_data = u"成功获取当前网卡的WINS服务器： %s" % wins_ip
                    log.user_info(log_data)
                else:
                    log_data = u"当前网卡WINS服务器为None"
                    log.user_info(log_data)
                    wins_ip = None
            else:
                log_data = u"通过netsh命令获取WINS服务器执行异常：%s" % result_data
                log.app_err(log_data)
                ret = NETCONFIG_FAIL
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return wins_ip
        
    # 增加获取主机名称的关键字 add by shenlige 2013-3-12
    def get_host_name(self):
        """
        功能描述：获取主机名称
        return：
                host_name ---主机名
        """
        host_name = platform.node().decode(sys.getfilesystemencoding())   # 兼容中文主机名，做编码转换 modify by shenlige 2013-4-10       
        log_data = u"成功获取主机名称： %s" % host_name
        log.user_info(log_data)
        return host_name
    
    # 修改网卡的MAC地址 add by shenlige 2013-3-13
    def nic_change_mac(self,macaddr):
        """
        功能描述：修改当前网卡的MAC地址
        """
        
        ret = NETCONFIG_SUCCESS
        try:
            self.nic_config._change_nic_mac(macaddr)
            #MAC修改后需要禁用、启用网卡才能生效
            self.disable_nic_card()           
            self.enable_nic_card()
            #MAC地址改变，需要更新对象
            self._create_nic_config()
            log_data = u"成功修改名称为 %s 网卡的MAC地址，并生效，后续操作都是针对生效后的网卡" % self.name
        except Exception, e: 
            log_data = u"修改当前网卡的MAC地址发送异常： %s" % e
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
            
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
    
    
    # 增加ipv6下的dhcp方式获取地址 add by shenlige 2013-3-19
    def config_nic_to_ipv6_dhcp(self):
        """
        功能描述：配置当前网卡为ipv6 DHCP 模式,xp环境下接口报错
        return:
                    
        """
        ret = NETCONFIG_SUCCESS
        re_fe80 = "^fe80"
        
        log_data = u"开始通过netsh配置当前网卡为ipv6 DHCP模式"
        log.app_err(log_data)
        
        for i in [1]:          
            os_system = self.judge_system()
            if os_system == 2:
                # win7下先设置routerdiscovery=enabled
                result, result_data = self._netsh_cmd('netsh interface ipv6 set interface interface="%s" routerdiscovery=enabled' % self.name)
                if result == 1:
                    log_data = u"通过netsh命令启用路由发现成功"
                    log.user_info(log_data)
                else:
                    log_data = u"通过netsh命令启用路由发现失败，详细信息：%s" % result_data
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break

                # 获取当前网卡的ipv6地址
                try: 
                    ipv6_addr = self.get_nic_ipv6_address()
                except Exception, e:
                    log_data = u"通过netsh命令获取名称为 %s 网卡的v6地址失败：%s" % self.name,e
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
                # 先删除所有非fe80打头的地址，然后再禁用启用网卡来实现v6的DHCP
                if ipv6_addr != None:
                    for i in ipv6_addr:
                        is_fe80 = re.match(re_fe80,i)
                        if is_fe80:
                            pass
                        else:
                            
                            result, result_data = self._netsh_cmd('netsh interface ipv6 delete address interface="%s" address="%s"' % (self.name,i))
                            if result == 1:
                                log_data = u"删除当前网卡ipv6地址 %s 成功" % i
                                log.user_info(log_data)
                            else:
                                log_data = u"通过netsh命令删除ipv6地址失败失败，详细信息： %s：" % result_data
                                log.app_err(log_data)
                                ret =  NETCONFIG_FAIL
                                break
                else:
                    pass
                
                if ret == NETCONFIG_FAIL:
                    break
                
                # 删除所有的默认网关 add by shenlige 2013-3-20
                self._nic_delete_all_ipv6_default_gateway()
 
                # 重启网卡来让配置生效
                self.restart_nic_card()

            elif os_system == 1:
                pass
            else:
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        else:
            log_data = u"通过netsh命令设置网卡ip为DHCP模式完毕"
            log.user_info(log_data)
        

    # 设置静态ipv6 地址的接口，当前v6地址的配置采用netsh命令来实现 add by shenlige 2013-3-19
    def config_nic_to_ipv6_static_address(self, ipv6_address, prefix_length=64, default_gateway = ''):
        """
        功能描述：设置当前网卡为静态方式的ipv6地址
        return:
                无
        """
        ret = NETCONFIG_SUCCESS
        
        log_data = u"开始通过netsh配置当前网卡为ipv6 静态模式"
        log.app_err(log_data)
        
        prefix_length = int(prefix_length)        # robot下发的参数为字符串，这里做转换 modify by shenlige 2013-3-20
        for i in [1]: 
            os_system = self.judge_system()
            if os_system == 2:
                
                # 修改为本次有效，网卡重启后配置不存在
                # 首先禁用路由发现，
                result, result_data = self._netsh_cmd('netsh interface ipv6 set interface interface="%s" routerdiscovery=disabled store=active' % self.name)
                if result == 1:
                    log_data = u"通过netsh命令禁用路由发现成功"
                    log.user_info(log_data)
                else:
                    log_data = u"通过netsh命令禁用路由发现失败，详细信息：%s" % result_data
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
                # 删除当前网卡的ipv6地址  如果为set address 则删除当前所有ipv6地址，只让用户唯一的地址生效 add by shenlige 2013-3-20
                tmp_ipv6_list = self.get_nic_ipv6_address()
                if tmp_ipv6_list != None:
                    for i in tmp_ipv6_list:
                        
                        result, result_data = self._netsh_cmd('netsh interface ipv6 delete address interface="%s" address="%s" store=active' % (self.name,i))
                        if result ==1:
                            log_data = u"通过netsh命令删除ipv6地址成功"
                            log.user_info(log_data)
                        else:
                            log_data = u"通过netsh命令删除ipv6地址失败，详细原因： %s" % result_data
                            log.app_err(log_data)
                            ret =  NETCONFIG_FAIL
                            break
               
                if ret == NETCONFIG_FAIL:
                    break
                
                # 设置静态ipv6 地址
                result, result_data = self._netsh_cmd('netsh interface ipv6 set address interface="%s" address="%s"/"%d" store=active' % (self.name,ipv6_address,prefix_length))
                if result == 1:
                    log_data = u"通过netsh命令设置ipv6地址成功"
                    log.user_info(log_data)
                else:
                    log_data = u"通过netsh命令设置ipv6地址失败，详细原因： %s" % result_data
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
                # 设置默认网关，ipv6默认情况下不配置网关
                if default_gateway != '':
                    
                    self._nic_add_ipv6_default_gateway(default_gateway)
                else:
                    pass
            
            elif os_system == 1:
                pass
            else:
                pass   
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        else:
            log_data = u"通过netsh命令修改静态ipv6地址完毕"
            log.user_info(log_data)
            
    # 解析出当前网卡是否为DHCP方式
    def _get_nic_ipv6_route_mode(self):
        """
        功能描述：获取当前网卡ipv6路由发现模式是否启用
        参数：无
        return：
                True：当前网卡是DHCP模式
                False：当前网卡是受到模式
        """
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        dhcp_mode = False
        for i in [1]:
            if os_system == 2:
                # 当网卡断开时WMI获取到的地址未None，而实际网卡是有地址的，因此这里用netsh命令来获取地址  modify by shenlige 2013-3-23
                result, result_data = self._netsh_cmd('netsh interface ipv6 show interface interface="%s"' % self.name)
                data_list = result_data.split("\n")
                for tmp_msg in data_list:
                    if u"路由器发现" in tmp_msg or 'Router Discovery' in tmp_msg:
                        dhcp_msg_list = tmp_msg.split(":")
                        dhcp = dhcp_msg_list[-1].strip()
                        if dhcp == "enabled":
                            dhcp_mode = True
                        elif dhcp == "disabled":
                            dhcp_mode = False
                        else:
                            log_data = u"通过netsh命令解析当前网卡模式（DHCP或手动配置）失败，详细原因： %s" % result_data
                            log.app_err(log_data)
                            ret =  NETCONFIG_FAIL
                            break
                        break
                if ret == NETCONFIG_FAIL:
                    break
            elif os_system == 1:
                pass
            else:
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return dhcp_mode
    
    
    def _nic_ipv6_clear_dns_list_by_netsh(self):
        """
        功能描述：通过netsh命令清除dns服务器列表
        参数：无
        返回值：无
        """
        log_data = u'开始尝试通过netsh命令清除DNS服务器列表'
        log.user_info(log_data)
        ret, ret_data = self._netsh_cmd('netsh interface ipv6 set dnsservers name="%s" source=static address=%s validate=no' % 
                        (self.name, "none")) 
        log_data = u'通过netsh命令清除DNS服务器列表完毕.修改结果：%s' % ret_data
        if ret == 1:
            log.user_info(log_data)
        else:
            raise RuntimeError(log_data)
   
    def _nic_ipv6_set_dns_to_dhcp_by_netsh(self):
        """
        功能描述：通过netsh命令设置dns为自动获取方式
        参数：无
        返回值：无
        """
        log_data = u'开始尝试通过netsh命令修改DNS服务器为自动获取'
        log.user_info(log_data)
        ret, ret_data = self._netsh_cmd('netsh interface ipv6 set dnsservers name="%s" source=dhcp' % self.name) 
        log_data = u'通过netsh命令修改DNS服务器为自动获取完毕.修改结果：%s' % ret_data
        if ret == 1:
            log.user_info(log_data)
        else:
            raise RuntimeError(log_data) 
    
    
    # 将dns服务器的配置从静态地址配置中分割出来 add by shenlige 2013-3-28
    def config_nic_ipv6_dns_server(self,dns = ''):
        """
        功能描述：配置dns服务器地址
        参数：list格式的dns服务器地址
        return：无
        """
        pc_system = self.judge_system()
        
        dhcp_enabled = self._get_nic_ipv6_route_mode()
        
        if dhcp_enabled:
            if dns == "None" or dns == '' or dns == "none":
                # 如果判断当前网卡为DHCP方式，用户配置dns参数为"None"或空字符串时，设置DNS为DHCP模式
                self._nic_ipv6_set_dns_to_dhcp_by_netsh()
            else:
                if pc_system == 2:
                    # 设置前先清除DNS服务器列表
                    self._nic_ipv6_clear_dns_list_by_netsh()
                    for tmp_dns in dns:
                        # 输入的dns为list形式
                        log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                        log.user_info(log_data)
                        ret, ret_data = self._netsh_cmd('netsh interface ipv6 add dnsservers name="%s" address=%s validate=no' % 
                                              (self.name, tmp_dns)) 
                        log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                        if ret == 1:
                            log.user_info(log_data)
                        else:
                            raise RuntimeError(log_data)
                elif pc_system == 1:
                    pass
                else:
                    pass
        else:
            if dns == "None" or dns == "none":
                # 静态地址时，如果参数设置为“None”时，清除dns列表
                self._nic_ipv6_clear_dns_list_by_netsh()
            elif dns == '':
                # 用户不配置采用默认值时，不修改当前DNS设置
                pass
            else:
                if pc_system == 2:
                    # 先清除dns服务器列表
                    self._nic_ipv6_clear_dns_list_by_netsh()
                    for tmp_dns in dns:
                        # 输入的dns为list形式
                        log_data = u'开始尝试通过netsh命令设置DNS服务器信息，当前即将设置的dns地址为：%s' % tmp_dns
                        log.user_info(log_data)
                        ret, ret_data = self._netsh_cmd('netsh interface ipv6 add dnsservers name="%s" address=%s validate=no' % 
                                              (self.name, tmp_dns)) 
                        log_data = u'通过netsh命令设置DNS服务器信息完毕.修改结果：%s' % ret_data
                        if ret == 1:
                            log.user_info(log_data)
                        else:
                            raise RuntimeError(log_data)
                
                elif pc_system == 1:
                    pass
                else:
                    pass
    
    def _get_ipv6_nic_index(self):
        """
        功能描述：获取当前网卡的索引号；
        注意：如果当前网卡未启用，则抛出异常
        return :nic_index
        """

        nic_index = None     
        result, result_data = self._netsh_cmd('netsh interface ipv6 show interface')
        result_data = result_data.split("\n")
                

        for i in result_data:
                    
            if self.name in i:
                if "disconnected" in i:
                    re_str = "disconnected(.*)"
                else:
                    re_str = "connected(.*)"
                
                i = i.strip()
                tmp_list = i.split(" ")
                
                m = re.search(re_str,i)
                if m:
                    tmp_name = m.group(1)
                    if tmp_name.strip() == self.name.strip():
                        nic_index = tmp_list[0]
                        log_data = u"名称为%s的网卡，其索引为%s" % (self.name,nic_index)
                        log.user_info(log_data)
                        break
                else:
                    continue
                            
        if  nic_index == None:
            log_data = u"名称为 %s 的网卡未启用，或无ipv6连接，netsh获取不到网卡索引" % self.name
            log.user_info(log_data)
              
        return nic_index

    def _nic_delete_all_ipv6_default_gateway(self):
        """
        功能描述：删除所有的默认网关
        return：
                无
        """
        ret = NETCONFIG_SUCCESS
        for i in [1]:
            os_system = self.judge_system()
            if os_system == 2:
                # 获取当前网卡的索引号
                nic_index = self._get_ipv6_nic_index()
                
                # 删除当前网卡所有的默认网关
                result, result_data = self._netsh_cmd('netsh interface ipv6 show route')
                result_data = result_data.split("\r\n")
            
                for i in result_data:
                    if i != '':
                        
                        list_result = []
                        tmp_list = i.split(" ")
                        # 去掉split后的空字符串
                        for element in tmp_list:
                            if element != "":
                                list_result.append(element)
                        
                        if "::/0" in i and nic_index == list_result[4]:
                            # 删除当前网卡的默认网关                            
                            result, result_data = self._netsh_cmd('netsh interface ipv6 delete route prefix="::/0" interface="%s"  store=active' % nic_index)  # 接口名称修改为网卡索引，配置为名称时偶现错误  modify by shenlige 2013-4-6
                            if result == 1:
                                log_data = u"通过netsh命令删除ipv6默认网关成功"
                                log.user_info(log_data)
                            else:
                                log_data = u"通过netsh命令删除ipv6默认网关失败，详细原因： %s" % result_data
                                log.app_err(log_data)
                                ret =  NETCONFIG_FAIL
                                break    
            
                if ret ==  NETCONFIG_FAIL:
                    break
              
            elif os_system == 1:
                pass
            else:
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        

    def _nic_add_ipv6_default_gateway(self,default_gateway):
        """
        功能描述：添加ipv6默认网关
        return:
                无
        """
        ret = NETCONFIG_SUCCESS
        for i in [1]:
            os_system = self.judge_system()
            if os_system == 2:
                
                # step1首先删除当前网卡的默认网关               
                self._nic_delete_all_ipv6_default_gateway()                
                
                # step2  增加静态默认网关
                result, result_data = self._netsh_cmd('netsh interface ipv6 add route prefix="::/0" interface="%s" nexthop="%s" store=active' % (self.name,default_gateway))
                if result == 1:
                    log_data = u"通过netsh命令添加ipv6默认网关成功"
                    log.user_info(log_data)
                else:
                    log_data = u"通过netsh命令添加ipv6默认网关失败，详细原因： %s" % result_data
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break 
            
            elif os_system == 1:
                pass
            else:
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
         
        return 1
    
    
    
    def nic_add_an_ipv6_address(self,ipv6_address):
        """
        功能描述：增加一个ipv6地址，该设置本次有效，网卡重启后配置不存在
        return：
                无
        """
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        dhcp_enabled = self._get_nic_ipv6_route_mode()
        
        for i in [1]:
            if os_system == 2:
                
                if not dhcp_enabled:
                    result, result_data = self._netsh_cmd('netsh interface ipv6 add address interface="%s" address="%s" store=active' % (self.name,ipv6_address))
                    if result == 1:
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv6地址： %s 成功" % (self.name,ipv6_address)
                        log.user_info(log_data)
                    else:
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv6地址： %s 失败，详细原因： %s" % (self.name,ipv6_address,result_data)
                        log.app_err(log_data)
                        ret =  NETCONFIG_FAIL
                        break
                else:
                    # 网卡为DHCP方式时，执行添加ipv6地址的操作报错
                    log_data = u"当前网卡为DHCP方式，不允许添加ipv6地址，请确认"
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
            elif os_system == 1:
                
                pass
            else:
                
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return  1
    
    def nic_delete_an_ipv6_address(self,ipv6_address):
        """
        功能描述：删除一个ipv6地址，该设置本次有效，网卡重启后配置不存在
        return：
                无
        """
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        dhcp_enabled = self._get_nic_ipv6_route_mode()
        
        
        for i in [1]:
            if os_system == 2:
                
                if not dhcp_enabled:
                    
                    ipv6_list = self.get_nic_ipv6_address()       
                    if ipv6_address in ipv6_list:
                        
                        # 当ipv6_address存在时才能执行删除动作
                        result, result_data = self._netsh_cmd('netsh interface ipv6 delete address interface="%s" address="%s" store=active' % (self.name,ipv6_address))
                        if result == 1:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv6地址： %s 成功" % (self.name,ipv6_address)
                            log.user_info(log_data)
                        else:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv6地址： %s 失败，详细原因： %s" % (self.name,ipv6_address,result_data)
                            log.app_err(log_data)
                            ret =  NETCONFIG_FAIL
                            break
                    else:
                        # 当ipv6_address不存在时给出LOG提示
                        log_data = u"预删除的ipv6地址：%s不存在，请确认" % ipv6_address
                        log.user_info(log_data)
                else:
                    # 网卡为DHCP方式时，执行删除ipv6地址的操作报错
                    log_data = u"当前网卡为DHCP方式，不允许删除ipv6地址，请确认"
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
                
            elif os_system == 1:
                
                pass
            else:
                
                pass
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return  1
    
        
    def get_nic_ipv6_default_gateway(self):
        """
        功能描述：获取当前网卡的ipv6默认网关地址
        return:
                ipv6_default_gateway
        """
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        ipv6_default_gateway = []
        for i in [1]:
            if os_system == 2:

                # 获取当前网卡的索引
                nic_index = self._get_ipv6_nic_index()

                if nic_index != None:
                    result, result_data = self._netsh_cmd('netsh interface ipv6 show route')
                    route_lines = result_data.split("\r\n")
                                                 
                    for tmp_line in route_lines:
                        # 修改获取默认网关的方法，改用精确匹配
                        if tmp_line != '':
                            list_result = []
                            tmp_list = tmp_line.split(" ")
                            # 去掉split后的空字符串
                            for i in tmp_list:
                                if i != "":
                                    list_result.append(i)
                            
                            if len(list_result) > 6:
                                # “网关/接口名称”为接口名称的话，若接口由空格组成的多个字符，split后会有多个，此时忽略
                                pass
                            elif "::/0" == list_result[3] and nic_index == list_result[4] and self.name != list_result[5]:
                                # 精确匹配::/0和接口索引
                                # 忽略网关是接口名称的情况
                                ipv6_default_gateway.append(list_result[5])
                else:
                    pass
                
                if ipv6_default_gateway != []:
                    log_data = u"名称为 %s 网卡的默认网关为: %s " % (self.name,ipv6_default_gateway)
                    log.user_info(log_data)
                else:
                    log_data = u"当前网卡未启用或没有获取到ipv6默认网关，返回为None"
                    log.user_info(log_data)
                    ipv6_default_gateway = None
                
            elif os_system == 1:
                pass
            else:
                pass
       
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return ipv6_default_gateway            
        
    
    def get_nic_ipv6_address(self):
        '''
        功能描述：返回当前网卡的IPv6地址，如果没有查找到或者当前网卡没有IPv6地址，返回None。
        return：
                无
        '''
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        ipv6_address = []
        for i in [1]:
            if os_system == 2:
                # 当网卡断开时WMI获取到的地址未None，而实际网卡是有地址的，因此这里用netsh命令来获取地址  modify by shenlige 2013-3-23
                result, result_data = self._netsh_cmd('netsh interface ipv6 show address interface="%s"' % self.name)
                result_data_list = result_data.split("\r\n")
                
                for i in result_data_list:
                    if  "Parameters" in i or u'参数' in i:                      
                        address = i.split(" ")[1]
                        tmp_index = address.find("%")
                        if tmp_index != -1:
                            address = address[0:tmp_index]    
                        ipv6_address.append(address)
                
                if ipv6_address != []:
                    log_data = u"当前网卡的ipv6地址为：%s" % ipv6_address
                    log.user_info(log_data)
                else:
                    log_data = u"当前网卡未获取到ipv6地址，返回为None"
                    log.user_info(log_data)
                    ipv6_address = None
            elif os_system == 1:
                pass
            else:
                pass
        
        return ipv6_address
    
    def get_nic_ipv6_dns_server(self):
        '''
        功能描述：返回当前网卡的IPv6 DNS服务器地址，如果没有查找到返回None。
        return：
                无
        '''
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        for i in [1]:
            if os_system == 2:
            
                # 通过WMI无法获取ipv6的dns服务器，以下通过netsh命令来获取
                result, result_data = self._netsh_cmd('netsh interface ipv6 show dnsservers interface="%s" ' % self.name)
                if self.name in result_data:
                    ipv6_dnsserver = []
                    result_data = result_data.strip()
                    data_list = result_data.split("\r\n")
                    tmp_len = len(data_list)
                    
                    for i in range(1,tmp_len-1):
                        tmp_dns = data_list[i].split(" ")[-1]
                        if tmp_dns == u"无" or tmp_dns == "None":
                            ipv6_dnsserver = None
                        else:
                            ipv6_dnsserver.append(tmp_dns)
                    
                    log_data = u"成功获取当前网卡的ipv6 dnsserver：%s" % ipv6_dnsserver
                    log.user_info(log_data)
                        
                else:
                    log_data = u"当前网卡未启用，获取到的ipv6 dns服务器为None"
                    log.user_info(log_data)
                    ipv6_dnsserver = None
        
            elif os_system == 1:
                pass
            else:
                pass    
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        return ipv6_dnsserver
    
    # 增加解析ip_subnet的接口 add by shenlige 2013-3-26
    def analyze_ip_and_subnet(self,ip_subnet):
        """
        功能描述：解析出ip地址和子网掩码
        参数：
                无
        返回值：
                ip地址和子网掩码组成的列表
        """
        ret = NETCONFIG_SUCCESS
        list_ip_subnet = []
        for i in [1]:
            if ip_subnet != None:
                if '.' in ip_subnet:
                    tmp_ipv4_list = ip_subnet.split("/")
                    list_ip_subnet.append(tmp_ipv4_list[0])
                    list_ip_subnet.append(tmp_ipv4_list[1])
                elif ':' in ip_subnet:
                    tmp_ipv6_list = ip_subnet.split("%")
                    tmp_len = len(tmp_ipv6_list)
                    if tmp_len == 2:
                        list_ip_subnet.append(tmp_ipv6_list[0])
                        list_ip_subnet.append(tmp_ipv6_list[1])
                    elif tmp_len == 1:
                        list_ip_subnet.append(tmp_ipv6_list[0],)
                        list_ip_subnet.append(None)
                    else:
                        log_data = u"输入的ipv6地址： %s 有误，请确认" % ip_subnet
                        log.app_err(log_data)
                        ret =  NETCONFIG_FAIL
                        break
                else:
                    log_data = u"输入的参数：%s 有误，请确认" % ip_subnet
                    log.app_err(log_data)
                    ret =  NETCONFIG_FAIL
                    break
            else:
                list_ip_subnet.append(None)
                list_ip_subnet.append(None)
                log_data = u"输入的参数为None，解析的结果将是[None,None]"
                log.user_info(log_data)
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return list_ip_subnet
    
    def nic_add_an_ipv4_address(self,ipv4_addr,subnet):
        """
        功能描述：增加一个ipv4地址
        参数：
                ipv4_addr：ipv4地址
                subnet：子网掩码
                gateway：网关地址
        返回：
                无
        """
        ret = NETCONFIG_SUCCESS
        os_system = self.judge_system()
        self._create_nic_config()  # 重新初始化网卡对象 
        dhcp_enabled = self.nic_config.get_ipv4_dhcp_enabled()
        
        for i in [1]:
            if not dhcp_enabled:
                if os_system == 1:
                
                    result, result_data = self._netsh_cmd('netsh interface ip add address name="%s" addr="%s" mask="%s"' % (self.name,ipv4_addr,subnet))
                    if result == 1:                  
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv4地址： %s 成功" % (self.name,ipv4_addr)
                        log.user_info(log_data)
                    else:
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv4地址： %s 失败，详细原因： %s" % (self.name,ipv4_addr,result_data)
                        log.app_err(log_data)
                        ret =  NETCONFIG_FAIL
                        break    
                elif os_system == 2:
                
                    result, result_data = self._netsh_cmd('netsh interface ipv4 add address name="%s" address="%s" mask="%s"' % (self.name,ipv4_addr,subnet))
                    if result == 1:
                        
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv4地址： %s 成功" % (self.name,ipv4_addr)
                        log.user_info(log_data)
                    else:
                        log_data = u"通过netsh命令为名为 %s 的网卡添加ipv4地址： %s 失败，详细原因： %s" % (self.name,ipv4_addr,result_data)
                        log.app_err(log_data)
                        ret =  NETCONFIG_FAIL
                        break
                else:
                    pass
            else:
                # 网卡为DHCP方式时，执行删除ipv4地址的操作报错
                log_data = u"当前网卡为DHCP方式，不允许增加一个ipv4地址，请确认"
                log.app_err(log_data)
                ret =  NETCONFIG_FAIL
                break
        
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
    
    
    
    # 增加删除ipv4地址的接口 add by shenlige 2013-4-7
    def nic_delete_an_ipv4_address(self,ipv4_address):
        """
        功能描述：配置ipv4 dns服务器地址，默认为空，即不改变当前dns服务器配置模式
        参数：
                dns：dns服务器的ip地址，list形式
        返回：无
        """
        ret = NETCONFIG_SUCCESS
        pc_system = self.judge_system()
        self._create_nic_config()  # 重新初始化网卡对象 
        dhcp_enabled = self.nic_config.get_ipv4_dhcp_enabled()
        
        ipv4_list = []
        ipv4_ret = self.get_nic_ipv4_address()
        
        for i in [1]:
            
            # 解析出当前网卡的ipv4地址
            if ipv4_ret != None:
                for tmp_ip_sub in ipv4_ret:
                    tmp_ipv4 = self.analyze_ip_and_subnet(tmp_ip_sub)[0]
                    ipv4_list.append(tmp_ipv4)
            else:
                log_data = u"当前网卡未启用、或连接断开，获取到的ipv4地址为None"
                log.app_err(log_data)
                ret =  NETCONFIG_FAIL
                break
            
            if not dhcp_enabled:
                if ipv4_address in ipv4_list:
                    if pc_system == 1:
                        # 当ipv4_address存在时才能执行删除动作
                        result, result_data = self._netsh_cmd('netsh interface ip delete address name=%s addr=%s' % (self.name,ipv4_address))
                        if result:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv4地址： %s 成功" % (self.name,ipv4_address)
                            log.user_info(log_data)
                        else:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv4地址： %s 失败，详细原因： %s" % (self.name,ipv4_address,result_data)
                            log.app_err(log_data)
                            ret =  NETCONFIG_FAIL
                            break
                    elif pc_system == 2:
                        
                        result, result_data = self._netsh_cmd('netsh interface ipv4 delete address name=%s address=%s' % (self.name,ipv4_address))
                        if result:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv4地址： %s 成功" % (self.name,ipv4_address)
                            log.user_info(log_data)
                        else:
                            log_data = u"通过netsh命令删除名为 %s 网卡的ipv4地址： %s 失败，详细原因： %s" % (self.name,ipv4_address,result_data)
                            log.app_err(log_data)
                            ret =  NETCONFIG_FAIL
                            break
                else:        
                    # 当ipv4_address不存在时给出LOG提示
                    log_data = u"预删除的ipv4地址：%s不存在，请确认" % ipv4_address
                    log.user_info(log_data)
            else:
                # 网卡为DHCP方式时，执行删除ipv4地址的操作报错
                log_data = u"当前网卡为DHCP方式，不允许删除ipv4地址，请确认"
                log.app_err(log_data)
                ret =  NETCONFIG_FAIL
                break
                
        if ret == NETCONFIG_FAIL:
            raise RuntimeError(log_data)
        
        return  1
           
     #添加获取通过名称或MAC获取MAC或名称的关键字 add by shenlige 2014-3-18
    def get_nic_name_or_mac(self,name_or_mac):
        """
        通过名称或MAC获取MAC或名称;
        """
        ret = NETCONFIG_SUCCESS
        self._create_nic_config()
        
        name_or_mac = name_or_mac.strip()
        mac_or_name = None
        
        try:
            nic_mac = networkcardinfo.get_network_card_mac(name_or_mac)
            nic_name = networkcardinfo.get_network_card_name(name_or_mac)
        except Exception, e: 
            log_data = u"通过WMI获取网卡信息发生异常： %s" % e
            log.app_err(log_data)
            ret = NETCONFIG_FAIL
            raise RuntimeError(log_data)
            
        if name_or_mac == nic_name:
            log_data = u"用户输入的名称为: %s 的网卡，其MAC地址为: %s" % (name_or_mac,nic_mac)
            mac_or_name = nic_mac
        
        if name_or_mac == nic_mac:
            log_data = u"用户输入的MAC为: %s 的网卡，其网卡名称为: %s" % (name_or_mac,nic_name)
            mac_or_name = nic_name
        
        if mac_or_name == None:
            log_data = u"用户输入的名称或MAC为: %s 的网卡不存在或未启用，返回为None" % name_or_mac
        
        log.user_info(log_data)
        return mac_or_name
           
class _NetConfig:

    def __init__(self, obj_nic_config, name):
        self.name = name
        self.obj_nic_config = obj_nic_config
        
    def get_interface_name(self):
        return self.name
    
    # 增加获取网卡DHCP状态的接口 add by shenlige 2013-3-28
    def get_ipv4_dhcp_enabled(self):
        return self.obj_nic_config.DHCPEnabled
    
    def get_nic_ipv4_address(self):
        '''返回网卡ipv4地址列表'''
        return self._get_nic_ip_address()['ipv4']

    def get_nic_ipv6_address(self):
        '''返回网卡ipv6地址列表'''
        return self._get_nic_ip_address()['ipv6']

    def _get_nic_ip_address(self):
        ip_address = self.obj_nic_config.IPAddress
        if ip_address == None:
            return {'ipv4':None, 'ipv6':None}
        ip_subnet = self.obj_nic_config.IPSubnet
        ip_address_list_len = len(ip_address)
        nic_ip_address = {'ipv4':[], 'ipv6':[]}
        ipv4_re = r'(?<![\.\d])(?:\d{1,3}\.){3}\d{1,3}(?![\.\d])'
        ipv4_address = []
        ipv6_address = []
        for i in range(ip_address_list_len):
            if re.findall(ipv4_re,ip_address[i]) != []:
                nic_ip_address['ipv4'].append(ip_address[i] + '/' + ip_subnet[i])
            else:
                nic_ip_address['ipv6'].append(ip_address[i] + '/' + ip_subnet[i])
        return nic_ip_address
    
    def _change_nic_mac(self,mac_address): 
        netCfgInstanceID = None
        hkey = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE, \
                               r'System\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}')
        keyInfo = _winreg.QueryInfoKey(hkey)
        for index in range(keyInfo[0]):
            hSubKeyName = _winreg.EnumKey(hkey, index)
            hSubKey = _winreg.OpenKey(hkey, hSubKeyName,0,_winreg.KEY_ALL_ACCESS)
            try:
                netCfgInstanceID = _winreg.QueryValueEx(hSubKey, 'NetCfgInstanceId')[0]
            except WindowsError, [e,msg]:  
                continue
            if netCfgInstanceID == self.obj_nic_config.SettingID:
                _winreg.SetValueEx(hSubKey, 'NetworkAddress',0,_winreg.REG_SZ, mac_address)
                _mac_address = _winreg.QueryValueEx(hSubKey, 'NetworkAddress')[0]
                if _mac_address == mac_address:
                    pass
                else:
                    raise ValueError,  u'修改网卡MAC地址失败'
                try:
                    _winreg.CloseKey(hSubKey)
                except WindowsError, [e,msg]:  
                    pass
                break
            else:
                try:
                    _winreg.CloseKey(hSubKey)
                except WindowsError, [e,msg]:  
                    pass
        else:
            raise ValueError,  u'没有找到匹配的网络适配器。'
            
        try:
            _winreg.CloseKey(hkey)  
        except WindowsError, [e,msg]:  
            pass

        # self._restart_nic()   # 此处需增加网卡重启操作，网卡重启后才能生效
        
        log_data =  u"修改当前网卡MAC地址为 %s 成功" % mac_address
        log.user_info(log_data)


    def get_nic_ipv4_gateway(self):
        '''返回网卡ipv4网关地址列表'''
        return self._get_nic_gateway()['ipv4']

    def get_nic_ipv6_gateway(self):
        '''返回网卡ipv6网关地址列表'''
        return self._get_nic_gateway()['ipv6']

    def _get_nic_gateway(self):
        ip_gateway = self.obj_nic_config.DefaultIPGateway
        nic_ip_gateway = {'ipv4':[], 'ipv6':[]}
        ipv4_re = r'(?<![\.\d])(?:\d{1,3}\.){3}\d{1,3}(?![\.\d])'
        for gateway in ip_gateway:
            if re.findall(ipv4_re,gateway) != []:
                nic_ip_gateway['ipv4'].append(gateway)
            else:
                nic_ip_gateway['ipv6'].append(gateway)
        return nic_ip_gateway

    def get_nic_dns(self):
        '''返回网卡DNS服务器列表'''
        return self.obj_nic_config.DNSServerSearchOrder
    
    def set_nic_ip_address(self, ip_address, ip_subnet=''):
        '''配置网卡ip地址'''
        ipv4_re = r'(?<![\.\d])(?:\d{1,3}\.){3}\d{1,3}(?![\.\d])'
        if ip_subnet == '':
            if re.findall(ipv4_re,ip_address) != []:
                ip_subnet = '255.255.255.0'
            else:
                ip_subnet = 64
        # 传入值需要是list，先判断参数是否是list，如果不是，转换为list
        if type(ip_address) != type([]):
            ip_address = [ip_address]
        if type(ip_subnet) != type([]):
            ip_subnet = [ip_subnet]
                
        returnValue = self.obj_nic_config.EnableStatic(IPAddress = ip_address, SubnetMask = ip_subnet)

        if returnValue[0] == 0:
            log_data = u'设置IP为 %s 成功'% ip_address
            log.user_info(log_data)
            return 1
        elif returnValue[0] == 1:
            log_data = u'设置IP %s 成功，系统需要重启生效'% ip_address
            log.user_info(log_data)
            intReboot += 1
            return 1
        else:
            #log_data = u'通过WMI设置网卡IP发生错误，错误信息为： %s' % returnValue
            #log.user_info(log_data)
            return 0
            
            
    def set_nic_gateway(self, gateway, gateway_cost_metrics=1):
        '''配置网卡网关信息'''
        # 传入值需要是list，先判断参数是否是list，如果不是，转换为list
        if type(gateway) != type([]):
            gateway = [gateway]
        if type(gateway_cost_metrics) != type([]):
            gateway_cost_metrics = [gateway_cost_metrics]

        returnValue = self.obj_nic_config.SetGateways(DefaultIPGateway = gateway, GatewayCostMetric = gateway_cost_metrics)

        if returnValue[0] == 0:
            log_data = u'设置网关为 %s 成功'% gateway
            log.user_info(log_data)
            return 1
        elif returnValue[0] == 1:
            log_data = u'设置网关为 %s 成功，系统需要重启生效'% gateway
            log.user_info(log_data)
            intReboot += 1
            return 1
        else:
            #log_data = u'通过WMI网关设置发生错误，错误信息为： %s' % returnValue
            #log.user_info(log_data)
            return 0

    def set_nic_dns(self, dns_server):
        '''配置网卡dns服务器'''
        # 传入值需要是list，先判断参数是否是list，如果不是，转换为list
        if type(dns_server) != type([]):
            dns_server = [dns_server]
        returnValue = self.obj_nic_config.SetDNSServerSearchOrder(DNSServerSearchOrder = dns_server)

        if returnValue[0] == 0:
            log_data = u'设置DNS服务器为 %s 成功'% dns_server
            log.user_info(log_data)
            return 1
        elif returnValue[0] == 1:
            log_data = u'设置DNS服务器为 %s 成功，系统需要重启生效'% dns_server
            log.user_info(log_data)
            intReboot += 1
            return 1
        else:
            #log_data = u'通过WMI配置DNS服务器发生错误，错误信息为： %s' % returnValue
            #log.user_info(log_data)
            return 0
    
    # 将dns的设置从dhcp中分割出来
    def enable_dhcp(self):
        '''配置网卡为DHCP模式'''
        need_reboot = 0

        # 配置自动获取地址
        returnValue = self.obj_nic_config.EnableDHCP()
        if returnValue[0] == 0:
            pass
        elif returnValue[0] == 1:
            need_reboot += 1
        else:
            return 0
        
        if need_reboot > 0:
            log_data = u'配置网卡ip为DHCP模式成功，系统需要重启生效'
        else:
            log_data = u'配置网卡ip为DHCP模式成功'
        log.user_info(log_data)
        return 1
    
    def enable_dns_dhcp(self):
        ''' 配置dns为dhcp模式 '''
        need_reboot = 0
      
        returnValue = self.obj_nic_config.SetDNSServerSearchOrder()
        if returnValue[0] == 0:
            pass
        elif returnValue[0] == 1:
            need_reboot += 1
        else:
            
            return 0

        if need_reboot > 0:
            log_data = u'配置网卡dns为DHCP模式成功，系统需要重启生效'
        else:
            log_data = u'配置网卡dns为DHCP模式成功'
        log.user_info(log_data)
        return 1
    
    # 获取子网掩码 add by shenlige 2013-3-9 
    def get_nic_ip_subnet(self):
        '''  当前网卡子网掩码 '''
        ip_subnet = self.obj_nic_config.IPSubnet
        return ip_subnet
    
    # 获取DHCP服务器地址add by shenlige 2013-3-9 
    def get_nic_ip_dhcpserver(self):
        '''返回当前dhcpserver的ip地址 '''
        ip_dhcpserver = self.obj_nic_config.DHCPServer
        return ip_dhcpserver
    
    # 获取DHCP租约时间add by shenlige 2013-3-9
    def _get_nic_dhcpleaseexpires(self):
        ''' 返回当前dhcp服务器租约到期时间 '''
        
        time_expires = self.obj_nic_config.DHCPLeaseExpires
        return time_expires
    
    
    def _get_nic_dhcpleaseobtained(self):
        ''' 返回当前dhcp服务器租约获取时间 '''
        
        time_obtained = self.obj_nic_config.DHCPLeaseObtained
        return time_obtained
    
    
    def _convert_format_time(self,time_str):
        ''' 将获取的租约时间转化为整数类型'''
        time = time_str.split(".")[0]
        time_year = int(time[0:4])
        time_month = int(time[4:6])
        time_day = int(time[6:8])
        time_hour = int(time[8:10])
        time_minute = int(time[10:12])
        time_second = int(time[12:])
        
        return time_year,time_month,time_day,time_hour,time_minute,time_second
        
    def get_nic_dhcpleasetime(self):
        ''' 获取租约时间，为租约到期时间与租约获取时间的差 '''
        expires = self._get_nic_dhcpleaseexpires()
        obtained = self._get_nic_dhcpleaseobtained()
        
        if expires != None and obtained != None:
            expires_year,expires_month,expires_day,expires_hour,expires_minute,expires_second = self._convert_format_time(expires)
            obtained_year,obtained_month,obtained_day,obtained_hour,obtained_minute,obtained_second = self._convert_format_time(obtained)
                        
            expires_time = datetime.datetime(expires_year,expires_month,expires_day,expires_hour,expires_minute,expires_second)
            obtained_time = datetime.datetime(obtained_year,obtained_month,obtained_day,obtained_hour,obtained_minute,obtained_second)

            lease_day = (expires_time-obtained_time).days
            lease_second = (expires_time-obtained_time).seconds
            
            lease_time = lease_day*24*3600 + lease_second
        else:
            lease_time = None
        
        
        return lease_time
    
    # 实现网卡的release操作add by shenlige 2013-3-11
    # 网卡模式为手动时命令不生效，不报错
    # 网卡未启用时不报错，连接断开时不报错
    def nic_dhcp_release(self):
        ''' 实现DHCP方式下网卡的release操作 '''
        need_reboot = self.obj_nic_config.ReleaseDHCPLease()
        
        if need_reboot[0] == 1:
            log_data = u'网卡执行release操作成功，系统需要重启生效.'
            log.user_info(log_data)
        elif need_reboot[0] == 0:
            log_data = u'网卡执行release操作成功.'
        else:
            log_data = u'WMI下release操作正常执行，但因其他原因未生效，如静态IP、网卡未启用、连接断开等.'
            log.user_info(log_data)
        
        return need_reboot[0]
    
    def nic_dhcp_renew(self):
        ''' 实现DHCP方式下网卡的renew操作 '''
        need_reboot = self.obj_nic_config.RenewDHCPLease()
        
        if need_reboot[0] == 1:
            log_data = u'网卡执行renew操作成功,系统需要重启生效.'
            log.user_info(log_data)
        elif need_reboot[0] == 0:
            log_data = u'网卡执行renew操作成功.'
        else:
            log_data = u'WMI下renew操作正常执行，但因其他原因未生效，如静态IP、网卡未启用、连接断开等.'
            log.user_info(log_data)
        
        return need_reboot[0]
    
    
        
if __name__ == '__main__':
    name = raw_input("enter network name:")
    """
    while name != '1':    
        a = ATTNetConfig(name)
        choice = raw_input("enter config dhcp(1):")
        if choice == "1":
            a.config_nic_to_ipv4_dhcp()
        if choice == "2":
            print a.get_nic_ipv4_address()
        else:
            ip = raw_input("enter ip:")
            subnet = raw_input("enter subwork:")
            gateway = raw_input("enter gateway:")
            dns = raw_input("enter dns:")
            a.config_nic_to_ipv4_static_address(ip,subnet,gateway,dns)
        name = raw_input("enter network name:")
    """
    #name = "office"
    card = ATTNetConfig(name)
    #card.get_nic_ipv4_ipsubnet()
    card.config_nic_to_ipv4_dhcp()
    #card.get_nic_ipv4_dns_server()
    """
    card.get_nic_ipv4_address()
    card.get_nic_ipv4_dhcp_lease_time()
    card.get_nic_ipv4_dhcp_server()
    card.get_nic_ipv4_gateway()
    card.get_nic_ipv4_dns_server()
    card.get_nic_ipv4_wins()
    """
    card.config_nic_ipv4_dns_server()
    
   
    
    
    
    
   
    