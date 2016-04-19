# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: capture
#  function: 提供抓包相关操作的关键字，包括开始抓包，停止抓包，
#            设置抓包设备等
#  Author: ATT development group
#  version: V1.0
#  date: 2013-9-30
#  change log:
#  zsj     10130930     created
#
# ***************************************************************************

import os
from os.path import join, dirname, isdir, isfile, exists, getsize
import time
from datetime import datetime
import re
import sys
import subprocess
import base64

import networkcardinfo  
import attlog as log     
from initapp import ATTROBOT_TEMP_FILE_PAHT
import attcommonfun

from parsepcapfile import ParsePcapFile, PARSE_PCAP_FILE_F

WIRESHARK_SUCCESS  =  1   # 执行成功
WIRESHARK_FAIL     = -1  # 执行失败
WIRESHARK_NO_STOP  = -2  # 抓包服务器未停止

MAX_EMPTY_PCAP_FILE_LEN = 388L  # PCAP空文件最大长度
MAX_TIME_OUT            = 600  # tshark.exe最长处理时间为10分钟


class ATTWireShark(object):
    """
    ATTWireShark
    """
    
    dict_network_networkid = {}   # 保存本地网卡信息避免每次调用都初始化的映射关系{(网卡名，网卡mac):网卡id}
    
    def __init__(self, device_name):
        """
        initial
        """
        # 如没有获取网卡描述，先获取网卡描述
        if not ATTWireShark.dict_network_networkid:
            self._get_network_info()
        
        self.dict_process_obj       = {}          # 保存启动的进程及进程对象
        self.network_name           = ""
        self.network_mac            = ""
        
        self.device_name            = device_name
        self.device_id              = self._get_device_id()    # 获取要抓包的网卡id
        self.wireshark_install_path = None
    
    def get_network_name(self):
        """
        函数功能：获取网卡名称
        
        参数：无
        
        返回值：
            network_name
        """
        return self.network_name
    
    def get_network_mac(self):
        """
        函数功能：获取网卡mac地址
        
        参数：无
        
        返回值：
            network_mac
        """
        return self.network_mac
    
    def set_wireshark_install_path(self, wireshark_install_path=""):
        """
        功能描述：设置抓包电脑上wireshark的安装路径:
        
        参数：file_path: wireshark软件的安装路径
        """
        ret = WIRESHARK_FAIL
        if not wireshark_install_path:
            str_data = u"设置wirershark路径为空！"
        else:
            temp_wireshark_install_path = join(wireshark_install_path, "tshark.exe")
            if isfile(temp_wireshark_install_path):
                ret = WIRESHARK_SUCCESS
                self.wireshark_install_path = wireshark_install_path
                str_data = u"设置wirershark路径 %s 成功！" % wireshark_install_path
            else:
                str_data = u"设置wirershark路径 %s 不合法！" % wireshark_install_path
                
        if ret == WIRESHARK_FAIL:
            err_info = u"%s 将采用默认的wireshark安装路径！" % str_data
            log.user_warn(err_info)
            self.wireshark_install_path = self._get_default_install_path()
        else:
            log.user_info(str_data)
   
    def start_wireshark_capture(self, capture_filter="", prefix="ATT", file_path="default"):
        """
        功能描述: 开始当前网卡设备的抓包
        
        参数：\n
            capture_filter:  抓包过滤器表达式,不下发表示抓取所有包\n
            perfix：         保存抓包文件的前缀\n
            file_path：      保存抓包文件的路径\n
        """
        
        if not self.wireshark_install_path:
            self.wireshark_install_path = self._get_default_install_path()
            
        str_data = u"开始启动抓包服务器……"
        log.user_info(str_data)
        
        ret                   = WIRESHARK_SUCCESS
        capture_filter        = self._check_input_str_unicode(capture_filter)
        file_path             = (prefix, file_path)  # 将文件前缀及文件路径保存在一个字典中
        
        popen_stdout_name     = "%s_popen_stdout.txt" % attcommonfun.get_time_stamp()
        popen_stdout_path     = join(ATTROBOT_TEMP_FILE_PAHT, popen_stdout_name)
        
        temp_packet_file_name = "%s_wireshark.pcap" % attcommonfun.get_time_stamp()
        temp_packet_file_path = join(ATTROBOT_TEMP_FILE_PAHT, temp_packet_file_name)
        
        if capture_filter:
            try:
                t = capture_filter.encode("ASCII")
            except Exception:
                log_info = u"capture_filter参数输入错误，目前只支持ASCII码字符"
                raise RuntimeError(log_info)
            
            cmd = '"%s\\Tshark.exe" -i "%s" -f "%s" -w "%s" ' % (self.wireshark_install_path,
                                                                 self.device_id,
                                                                 capture_filter,
                                                                 temp_packet_file_path)
        else:
            cmd = '"%s\\Tshark.exe" -i "%s" -w "%s"' % (self.wireshark_install_path,
                                                        self.device_id,
                                                        temp_packet_file_path)
        try:
            with open(popen_stdout_path, "w") as obj_file:
                popen = subprocess.Popen(cmd,
                                         stdout=obj_file,
                                         stderr=obj_file,
                                         shell=True)
        except Exception,e:
            ret      = WIRESHARK_FAIL
            ret_data = u"启动抓包服务器失败，失败原因：%s" % e
        else:
            ret, ret_data = self._check_start(popen, popen_stdout_path, temp_packet_file_path)
            
        if ret == WIRESHARK_SUCCESS:
            log.user_info(ret_data)
            flag_pid = "%s_%s" % (attcommonfun.get_time_stamp(), popen.pid)
            
            # 储存改抓包的数据，以便后续使用
            dict_data={}   
            dict_data["popen"]                  = popen
            dict_data["file_path"]              = file_path
            dict_data["temp_packet_file_path"]  = temp_packet_file_path
            dict_data["popen_stdout_path"]      = popen_stdout_path
            
            self.dict_process_obj.update({flag_pid:dict_data})
            
            cmd_pid_with_tshark_path = os.path.join(ATTROBOT_TEMP_FILE_PAHT, "cmd_pid_with_tshark.txt")
            try:
                with open(cmd_pid_with_tshark_path,"a+") as file_obj:
                    file_obj.write("%s\n" % popen.pid)
            except Exception,e:
                debug_msg = u"保存抓包服务器flag_pid=%s失败，该服务器不能自动关闭" % popen.pid
                log.debug_warn(debug_msg)
        else:
            log.user_err(ret_data)
            raise RuntimeError(ret_data)
   
        return flag_pid

    def stop_wireshark_capture(self, flag_pid):
        """
        功能描述: 停止当前网卡设备的抓包
        
        参数：
            flag_pid:   Start WireShark 关键字执行成功后的返回值
        """
        ret       = WIRESHARK_SUCCESS
        ret_data  = ""
        dict_data = self.dict_process_obj.get(flag_pid)
        
        if dict_data is None:
            str_warn = u"没有找到相应抓包服务器%s" % flag_pid
            log.user_warn(str_warn)
            ret_data = (None, "")
            
        elif dict_data.get("flag_stop"):
            str_data = u"%s该抓包服务器已停止过" % flag_pid
            log.user_info(str_data)
            ret_data = (None, "")

        else:
            ret, ret_data = self._stop_wireshark(dict_data)
            
        if dict_data and not dict_data.get("flag_stop"):
            dict_data["flag_stop"] = True
            self.dict_process_obj.update({flag_pid:dict_data})
        
        return ret, ret_data
    
    def wireshark_capture_success(self, flag_pid):
        """
        功能描述: 成功抓到报文关键字执行成功，报文为空，关键字执行失败
        
        参数：
            flag_pid:   Start WireShark 关键字执行成功后的返回值
        """
        ret       = WIRESHARK_FAIL
        str_data  = ""
        dict_data = self.dict_process_obj.get(flag_pid)
        
        if dict_data:
            popen          = dict_data.get("popen")
            file_path      = dict_data.get("temp_packet_file_path")
            obj_parse_pcap = dict_data.get("obj_parse_pcap")
            
            if popen and popen.poll() == None:
                if dict_data.get("flag_2_stop"):
                    err_data = u"停止抓包服务器失败，判断 %s 服务器成功与否失败！" % flag_pid
                    raise RuntimeError(err_data)
                else:
                    dict_data["flag_2_stop"] = True
                    self.dict_process_obj.update({flag_pid:dict_data})
                    
                ret = WIRESHARK_NO_STOP
                return ret
            
            if file_path is None:
                str_data = u"获取 %s 相应的抓包文件失败！" % flag_pid
                
            elif os.path.exists(file_path):
                if not obj_parse_pcap :
                    obj_parse_pcap               = ParsePcapFile(self.wireshark_install_path, file_path)
                    dict_data["obj_parse_pcap"]  = obj_parse_pcap 
                    
                    self.dict_process_obj.update({flag_pid:dict_data})
                else:
                    obj_parse_pcap  = dict_data.get("obj_parse_pcap")
                    
                if obj_parse_pcap.check_file_empty(file_path) != PARSE_PCAP_FILE_F:
                    ret      = WIRESHARK_SUCCESS
                    str_data = u"成功捕获到报文"
                else:
                    str_data = u"捕获到报文为空"
            else:
                str_data = u"捕获到报文为空"
        else:
            str_data = u"%s 相应抓包服务器不存在，不能判定成功捕获到报文！" % flag_pid
       
        if ret == WIRESHARK_FAIL:
            log.user_err(str_data)
            raise RuntimeError(str_data)
        else:
            log.user_info(str_data)
            
    
    def wireshark_query_option_str_value(self, flag_pid, option_name_or_offset, read_filter=""):
        """
        函数功能：查询用户指定字段（字段别名或偏移量）str型值
        
        参数：
            flag_pid                Start WireShark 关键字执行成功后的返回值
            option_name_or_offset   字段别名或偏移量 如：franme.num or frame[xx:xx]
            read_filter            读取过滤器表达式 
        
        返回值：list_data or None
        """
        ret_data  = None
        dict_data = self.dict_process_obj.get(flag_pid)
        
        if dict_data:
            try:
                ret_data = self._get_option_value(flag_pid,
                                                  dict_data,
                                                  option_name_or_offset,
                                                  read_filter)
            except Exception,e:
                raise e
            
        else:
            err_data = u"没有找到相应抓包服务器"
            log.user_err(err_data)
            raise RuntimeError(err_data)
        
        return ret_data
    
    def wireshark_query_option_byte_value(self, flag_pid, option_name_or_offset, read_filter):
        """
        函数功能：查询用户指定字段（字段别名或偏移量）str型值
        
        参数：
            flag_pid                Start WireShark 关键字执行成功后的返回值
            option_name_or_offset   字段别名或偏移量 如：franme.num or frame[xx:xx]
            read_filter            读取过滤器表达式 
        
        返回值：list_data or None
        """
        ret_data   = None
        dict_data  = self.dict_process_obj.get(flag_pid)
        query_type ="ascii_value"
        if dict_data:
            try:
                ret_data = self._get_option_value(flag_pid,
                                                  dict_data,
                                                  option_name_or_offset,
                                                  read_filter,
                                                  query_type)
            except Exception,e:
                raise e
                
        else:
            err_data = u"没有找到相应抓包服务器"
            log.user_err(err_data)
            raise RuntimeError(err_data)
        
        return ret_data
    
    def _get_network_info(self):
        """
        功能描述: 获取本地网卡信息的映射关系{(网卡名，网卡mac):网卡id}
        
        参数：无
        
        返回值：无
        
        """
        ret = WIRESHARK_SUCCESS
        str_data = ""
        
        for i in [1]:
            try:
                # 获取本机所有网卡信息
                col_nic_configs = networkcardinfo.get_network_card_objs(IPEnabled=1)
                if col_nic_configs and isinstance(col_nic_configs, list):
                    # 保存网卡相关信息的映射关系到字典中    
                    for obj_nic_config in col_nic_configs:
                        NetConnectionID = obj_nic_config.associators()[0].NetConnectionID
                        MACAddress = obj_nic_config.MACAddress
                        SettingID = "\\Device\\NPF_" + obj_nic_config.SettingID
                        
                        # 保存本地网卡信息的映射关系{(网卡名，网卡mac):网卡id}
                        ATTWireShark.dict_network_networkid.update({(NetConnectionID,MACAddress):SettingID})
                else:
                    str_data = u"没有发现任何可用网卡设备，请检查网络连接!" 
                    ret = WIRESHARK_FAIL
                    break
                
            except Exception,e:
                str_data = u"获取网卡设备信息发生异常:%s" % e
                ret = WIRESHARK_FAIL
                break
            
        if ret == WIRESHARK_FAIL:
            log.user_err(str_data)
            raise RuntimeError(str_data)
        else:
            str_data = u"获取网卡信息成功。"
            log.user_info(str_data)
    
    def _get_device_id(self):
        """
        功能描述： 获取当前网卡的id,网卡名，网卡mac
        参数：无
        返回值：
            device_id   当前抓包网卡的id
            network_name 网卡名
            network_mac  网卡mac地址
        """
        device_id = None
        for key, value in ATTWireShark.dict_network_networkid.items():
            if self.device_name in key:
                device_id         = value
                self.network_name = key[0]
                self.network_mac  = key[1]
                break
            elif not self.device_name:
                err_data = u"输入的网卡名或Mac地址不能为空！"
            else:
                err_data = u"输入的网卡名或网卡Mac地址不识别"
        else:
            raise RuntimeError(err_data)
        
        str_data = u"初始化抓包网卡成功！"
        log.user_info(str_data)  
        return device_id
    
    def _get_default_install_path(self):
        """
        功能描述：获取默认的wireshark安装目录
        """
        temp_wireshark_install_path = "Program Files\\WireShark\\tshark.exe"
        list_system_dirve = self._get_system_drive()
        for dirver in list_system_dirve:
            wireshark_install_path = join(dirver,temp_wireshark_install_path)
            if isfile(wireshark_install_path):
                wireshark_install_path = dirname(wireshark_install_path)
                break
        else:
            err_data = u"获取默认的wireshark的安装路径失败！"
            raise RuntimeError(err_data)
        
        return wireshark_install_path
    
    def _get_system_drive(self):
        """
        功能描述：获取系统盘符
        
        参数：无
        
        返回值：盘符列表
        """
        import ctypes
        
        list_system_dirve = []
        try:
            lpBuffer = ctypes.create_string_buffer(78)
            ctypes.windll.kernel32.GetLogicalDriveStringsA(ctypes.sizeof(lpBuffer),lpBuffer)
            vol = lpBuffer.raw.split('\x00')
            for i in vol:
                if i:
                    list_system_dirve.append(i)
        except Exception,e:
            pass
                
        return list_system_dirve
    
    def _check_input_str_unicode(self, str_or_unicode):
        """
        函数功能：检查输入的参数是不是str或者unicode，并去掉前后的空格
        
        参数：
            str_or_unicode   字符串
            
        返回值：
            str_or_unicode   经过转换后的字符串
        """
        err_data = ""

        if isinstance(str_or_unicode, str) or\
            isinstance(str_or_unicode, unicode):
            
            str_or_unicode     = str_or_unicode.strip()
            
            if str_or_unicode:
                str_or_unicode = str_or_unicode.lower() 
                 
        else:
            err_data = u"输入的信息格式 %s 不合法！" % str_or_unicode
        
        if err_data:
            log.user_err(err_data)
            raise RuntimeError(err_data)
        
        return str_or_unicode
    
    def _check_start(self, popen, popen_stdout_path, temp_packet_file_path):
        """
        """
        ret          = WIRESHARK_FAIL
        str_data     = ""

        try:
            start_time = time.time()
            while 1:
                time.sleep(0.5) # 间隔0.5s查询一次，让出cpu执行时间
                if exists(temp_packet_file_path) and not popen.poll():
                    ret      = WIRESHARK_SUCCESS
                    str_data = u"抓包服务器启动成功！"
                    break
                
                elif exists(popen_stdout_path):
                    with open(popen_stdout_path, "r") as obj_file:
                        str_temp = obj_file.read()
                        str_temp = str_temp.decode(sys.getfilesystemencoding())
                        
                        if str_temp and popen.poll():
                            str_data = u"启动wireshark抓包失败，失败原因:%s" % str_temp
                            break
                else:
                    pass
              
                dif_time = time.time() - start_time
                if dif_time > MAX_TIME_OUT:
                    str_data = u"启动抓包服务失败，启动超时！"
                    self._stop_popen(popen, popen_stdout_path)
                    break
                
        except Exception,e:
            str_data = u"启动wireshark抓包失败，失败原因：%s" % e
        
        return ret,str_data

    def _stop_wireshark(self, dict_data):
        """
        """
        ret                   = WIRESHARK_SUCCESS
        ret_data              = ""
        str_data              = ""
        warn_data             = ""
        packet_data           = None  # 该值设为默认的None是对没有找到包和包为空做区别
        
        popen                 = dict_data.get("popen")
        file_path             = dict_data.get("file_path")
        temp_packet_file_path = dict_data.get("temp_packet_file_path")
        popen_stdout_path     = dict_data.get("popen_stdout_path")
        
        if popen.poll() == None:
            ret, str_data = self._stop_popen(popen, popen_stdout_path)
        else:
            pass
        
        # 读取数据包的数据内容，返回Robot本端
        if ret == WIRESHARK_SUCCESS:
            str_data = u"停止抓包服务器成功"
            if temp_packet_file_path and exists(temp_packet_file_path):
                try:
                    with open(temp_packet_file_path, "rb") as obj_file:
                        packet_data = base64.b64encode(obj_file.read())
                except Exception,e:
                    warn_data = u"获取抓包文件内容失败！失败信息：%s " % e
                    log.user_warn(warn_data)
            else:
                warn_data = u"未找到数据包文件!"
                log.user_warn(warn_data)
                
        if ret == WIRESHARK_SUCCESS:
            log.user_info(str_data)
            ret_data = (packet_data, file_path)
        else:
            log.user_err(str_data)
            raise RuntimeError(str_data)
            
        return ret, ret_data
    
    def _stop_popen(self, popen, popen_stdout_path):
        """
        """
        ret       = WIRESHARK_SUCCESS
        str_data  = ""
        
        ret, data = attcommonfun.get_process_children(popen.pid)
        if ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
            dict_process = data
            for process_pid,process_name in dict_process.items():
                # 全转为小写，防止系统数据不一致    zsj2013/11/2
                if process_name.lower() == "tshark.exe":
                    try:
                        os.kill(process_pid, 9)
                    except:
                        pass
        else:
            ret      = WIRESHARK_FAIL
            str_data = u"获取子进程信息失败，错误信息：%s。\n" % data
            
        try:
            os.kill(popen.pid, 9)
        except Exception,e:
            pass
        
        # 删除启动抓包服务器进程的输出文件
        try:
            time.sleep(0.5)
            os.remove(popen_stdout_path)
        except Exception,e:
            pass
        
        return ret, str_data
   
    def _get_option_value(self, flag_pid, dict_data, option_name_or_offset, read_filter, query_type="str_value"):
        """
        """
        ret                   = WIRESHARK_SUCCESS
        ret_data              = None
   
        popen                 = dict_data.get("popen")
        temp_packet_file_path = dict_data.get("temp_packet_file_path")
        obj_parse_pcap        = dict_data.get("obj_parse_pcap")
        
        if popen and popen.poll() == None:
            if dict_data.get("flag_2_stop"):
                    err_data = u"停止抓包服务器失败，判断 %s 服务器成功与否失败！" % flag_pid
                    raise RuntimeError(err_data)
            else:
                dict_data["flag_2_stop"] = True
                self.dict_process_obj.update({flag_pid:dict_data})
                
            ret = WIRESHARK_NO_STOP
            return ret
        
        elif not exists(temp_packet_file_path):
                ret      = WIRESHARK_FAIL
                return ret_data
            
        if read_filter:
            try:
                t = read_filter.encode("ASCII")
            except Exception:
                log_info = u"read_filter参数输入错误，目前只支持ASCII码字符"
                raise RuntimeError(log_info)
            
        if option_name_or_offset:   # 对取值参数做限制，如果中文报错
            try:
                t = option_name_or_offset.encode("ASCII")
            except Exception:
                log_info = u"option_name_or_offset参数输入错误，目前只支持ASCII码字符"
                raise RuntimeError(log_info)
        
        if not obj_parse_pcap :
            obj_parse_pcap               = ParsePcapFile(self.wireshark_install_path, temp_packet_file_path)
            dict_data["obj_parse_pcap"] = obj_parse_pcap 
            
            self.dict_process_obj.update({flag_pid:dict_data})
        else:
            obj_parse_pcap = dict_data.get("obj_parse_pcap")

        ret_data = obj_parse_pcap.query_option_value(option_name_or_offset, read_filter, query_type)
         
        return ret_data

    