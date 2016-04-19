# -*- coding: utf-8 -*- 

import os
from os.path import join, dirname, isdir, isfile, exists, getsize
import sys
import time
import base64
import re

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote
from robot import utils
from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger

from attcommonfun import *
from ATTWireShark import ATTWireShark,\
                         WIRESHARK_NO_STOP,\
                         WIRESHARK_FAIL,\
                         WIRESHARK_SUCCESS
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log

  
REMOTE_PORT    =  REMOTE_PORTS.get('WireShark')
VERSION        =  '1.0.0'
REMOTE_TIMEOUT =  3600
FLAG_SUCCEED   =  1
FLAG_FAIL      = -1

class WireShark():
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}
        self.flag_stop_all = False
        self.dict_all_capture_pid_and_cls = {}  # 保存所有启动的抓包服务器的pid和cls

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

    def init_wireshark_network_card(self, alias, name_or_mac ,remote_url=False):
        """
        功能描述：初始化网卡，为网卡配置别名；
        
        参数：
        alias:别名\n
        name_or_mac:网卡名称或者是MAC地址\n
        remote_url：是否要进行远程控制。（默认不进行远程）。\n
        remote_url格式为：http://remote_IP.可以用以下的几种方式进行初始化。注意别名请设置为
        不同的别名，切换的时候用别名进行切换。
        
        返回值：无
        
        Example:
        | Init WireShark Network Card  | One | 本地连接1         |                          
        | Init WireShark Network Card  | two | 本地连接1         | http://10.10.10.84 |
        | Init WireShark Network Card  |  3  | 44-37-E6-99-7C-B9 |                          
        | Init WireShark Network Card  |  4  | 44:37:E6:99:7C:B9 |                          
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
            network_name, network_mac = auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(name_or_mac, remote_url, alias)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTWireShark(name_or_mac)
            
            network_name = reallib.get_network_name()
            network_mac  = reallib.get_network_mac()
                
        tag = self._cache.register(reallib, alias) 
        self._register_alias(alias, network_name, network_mac, remote_url)
        
        return network_name, network_mac
    
    def _current_remotelocal(self):
        if not self._cache.current:
            raise RuntimeError('No remotelocal is open')
        return self._cache.current      
    
    def switch_wireshark_network_card(self, alias):
        """

        功能描述：使用alias在当前已存在的网卡对象中进行切换
                  
        参数：alias,别名。
        
        返回值：无
        
        Example:
        | Init WireShark Network Card    | 1           | 本地连接1 |
        | Init WireShark Network Card    | 2           | 本地连接1 | http://10.10.10.84 |
        | Switch WireShark Network Card  | 1           |
        | Switch WireShark Network Card  | 2           |
        """
        try:
            cls=self._cache.switch(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'成功切换到别名为：%s 的网卡下，后续抓包操作都是针对该网卡，直到下一个切换动作' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)
   
    def set_wireshark_install_path(self, file_path):
        """
        功能描述：设置抓包电脑上wireshark的安装路径；\n
        
        参数：\n
            file_path: wireshark软件的安装路径
                
        Example:
        | Set Wireshark Install Path |  c:\\\\Program Files\\\\WireShark |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.set_wireshark_install_path(file_path)
    
    def start_wireshark_capture(self, capture_filter="", prefix="ATT", file_path="default"):
        """
        功能描述: 开始当前网卡设备的抓包
        
        参数：\n
            capture_filter:  抓包过滤器表达式,不下发表示抓取所有包\n\n
            perfix：         保存抓包文件的前缀\n
            file_path：      保存抓包文件的路径\n
            
        返回值：\n
            flag_pid:        启动成功返回进程标识
            
        Example:
        |  ${flag_pid1}  | Start WireShark Capture  |        |  ATT  |
        |  ${flag_pid2}  | Start WireShark Capture  |   tcp  |  ATT  |
        |  ${flag_pid3}  | Start WireShark Capture  |   tcp  |  ATT  |  c:\\\\wireshark  |
        """        
        if IS_LOCAL:
            self._check_prefix(prefix)
            
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.start_wireshark_capture(capture_filter, prefix, file_path)
        
        self.dict_all_capture_pid_and_cls.update({ret:cls})
        
        return ret
    
    def stop_wireshark_capture(self, flag_pid):
        """
        功能描述: 停止当前网卡设备的抓包
        
        参数：\n
            flag_pid:   Start WireShark Capture关键字执行成功后的返回值
            
        返回值：无
        
        *注意：flag_pid传入为空或者None时不进行关闭动作。
            
        Example:
        |  ${flag_pid}            |  Start WireShark Capture  |          |  ATT  |
        |  Stop WireShark Capture |  ${flag_pid}              |
        """
        # 当同时开启多个抓包的时候会有抓不到包的情况，如果加1s延时效果好点 zsj2013/12/23
        if not self.flag_stop_all:
            time.sleep(1)
        
        cls = self.dict_all_capture_pid_and_cls.get(flag_pid)
        
        if not cls:
            str_warn = u"没有找到相应抓包服务器%s" % flag_pid
            log.user_warn(str_warn)
            return
        
        if (isinstance(cls, Remote)):
            ret, ret_data = auto_do_remote(cls)
        else:
            ret, ret_data = cls.stop_wireshark_capture(flag_pid)
            
            if not IS_LOCAL:   # 如果是如果不运行后面的保存文件等，直接返回
                return ret, ret_data 
        
        # 根据停止返回的数据保存抓包文件   
        if ret == WIRESHARK_SUCCESS:
            self._save_pcap_file_and_link_file(ret_data)
        
        # 删除已关闭的抓包服务器的存储
        if self.dict_all_capture_pid_and_cls.get(flag_pid):   
            self.dict_all_capture_pid_and_cls.pop(flag_pid)
    
    def wireshark_query_option_str_value(self, flag_pid, option_name_or_offset, read_filter=""):
        """
        
        功能描述: 查询抓到数据包中某个字段的值
        
        参数：\n
            flag_pid:                  Start WireShark Capture关键字执行成功后的返回值\n
            option_name_or_offset:     所要查询的字段名\n
            read_filter:               读取过滤器表达式\n
            
        返回值：\n
            list_data:       查询成功返回列表形式option_name字段值或None
            
        Example:
        | ${list_data}  | Wireshark Query Option Str Value  |  ${flag_pid}  |  ip.version    |  tcp   |
        | ${list_data}  | Wireshark Query Option Str Value  |  ${flag_pid}  |  frame[58:34]  |  tcp   |
        
        """
        ret       = None
        cls       = self._current_remotelocal()
        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret= cls.wireshark_query_option_str_value(flag_pid, option_name_or_offset, read_filter)
        
        if IS_LOCAL and ret == WIRESHARK_NO_STOP:
            str_data = u"抓包服务器未停止，开始自动停止抓包服务器！"
            log.user_warn(str_data)
            
            self.stop_wireshark_capture(flag_pid)
            
            ret = self.wireshark_query_option_str_value(flag_pid, option_name_or_offset, read_filter)
            
        else:
            pass
        
        return ret
    
    def wireshark_query_option_byte_value(self, flag_pid, option_name_or_offset, read_filter=""):
        """
        
        功能描述: 查询抓到数据包中某个字段的十六进制值。
        
        参数：\n
            flag_pid:                  Start WireShark Capture关键字执行成功后的返回值\n
            option_name_or_offset:     所要查询的字段名\n
            read_filter:               读取过滤器表达式\n
            
        返回值：\n
            list_data:       查询成功返回列表形式option_name字段值或None
            
        Example:
        | ${list_data}  | Wireshark Query Option Byte Value  |  ${flag_pid}  |  ip.version    |  tcp   |
        | ${list_data}  | Wireshark Query Option Byte Value  |  ${flag_pid}  |  frame[58:34]  |  tcp   | 
        
        """
        ret       = None
        cls       = self._current_remotelocal()
        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret= cls.wireshark_query_option_byte_value(flag_pid, option_name_or_offset, read_filter)
        
        if IS_LOCAL and ret == WIRESHARK_NO_STOP:
            str_data = u"抓包服务器未停止，开始自动停止抓包服务器！"
            log.user_warn(str_data)
            
            self.stop_wireshark_capture(flag_pid)
            
            ret = self.wireshark_query_option_byte_value(flag_pid, option_name_or_offset, read_filter)

        else:
            pass
        
        return ret
    
    def stop_all_wireshark_capture(self):
        """
        功能描述: 关闭所有开启的抓包浏览器并保存.\n
        
        参数：无
            
        返回值：无
            
        Example:
        | Init WireShark Network Card  | One | 本地连接1          | 
        |  ${flag_pid1}                | Start WireShark Capture  |        |  ATT  |
        |  ${flag_pid2}                | Start WireShark Capture  |   tcp  |  ATT  |
        |  ${flag_pid3}                | Start WireShark Capture  |   tcp  |  ATT  |  c:\\\\wireshark  |
        |  Stop All WireShark Capture  |    
        """
        # 当同时开启多个抓包的时候会有抓不到包的情况，如果加2s延时效果好点 zsj2013/12/23
        time.sleep(2)
        self.flag_stop_all = True
        
        for flag_pid in self.dict_all_capture_pid_and_cls.keys():
            try:
                self.stop_wireshark_capture(flag_pid)
            except:
                pass
        self.flag_stop_all = False

    def wireshark_capture_packet_success(self, flag_pid):
        """
        功能描述: 成功抓到报文关键字执行成功，报文为空，关键字执行失败.\n
        
        参数：\n
            flag_pid:   Start WireShark Capture关键字执行成功后的返回值
            
        返回值：无
            
        Example:
        |  Wireshark Capture Packet Success  |  ${flag_pid}  |
        """
        ret       = None
        cls       = self._current_remotelocal()
        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.wireshark_capture_success(flag_pid)
        
        if IS_LOCAL and ret == WIRESHARK_NO_STOP:
            str_data = u"抓包服务器未停止，开始自动停止抓包服务器！"
            log.user_warn(str_data)
            
            self.stop_wireshark_capture(flag_pid)
            
            self.wireshark_capture_packet_success(flag_pid)
        else:
            return ret
 
    def _save_pcap_file_and_link_file(self, tuple_data):
        """
        """
        ret           = FLAG_SUCCEED
        
        packet_data   = tuple_data[0]
        
        if packet_data is None:   # 如果停止的时候没有找到数据文件，返回成功
            return ret
        
        ret, str_data = self._get_packet_file_path(tuple_data[1])
        
        if ret == FLAG_SUCCEED:
            file_path = str_data
            try:
                with open(file_path, "wb") as obj_file2:
                    obj_file2.write(base64.b64decode(packet_data))
                
                str_data = u"保存抓包数据到指定路径 %s 成功！" % file_path
                self._link_wireshark_file(file_path)
            except Exception,e:
                ret = FLAG_FAIL
                str_data = "%s" % e
                
        if ret == FLAG_SUCCEED:
            log.user_info(str_data)
        else:
            err_data = u"把抓包文件保存到用户指定文件错误，错误信息：%s" % str_data
            log.user_err(err_data)
   
    def _link_wireshark_file(self, path):
        """
        功能描述：将抓包文件链接到log文件中
        
        参数： path：抓包文件全路径
        
        返回值：执行成功，返回(WIRESHARK_SUCCESS(0)，成功信息)
                执行失败，返回(WIRESHARK_FAIL(-1)，错误信息)
        """
        err_info = ""
        
        for i in [1]:
            err_info = u"开始链接报文文件到log文件中..."
            log.user_info(err_info)
            
            if not isinstance(path, unicode):
                path = path.decode('utf-8')
            default_log_path = self._get_default_log_dir()
            if not default_log_path:
                err_info = u"获取log文件路径失败!"
                break
         
            try:
                link = utils.get_link_path(path, default_log_path)
                logger.info("Capture file saved to '<a href=\"%s\">%s</a>'."
                        % (link, path), html=True)
                
                err_info = u"链接报文文件到log文件中成功！"
                log.user_info(err_info)
                return
                
            except Exception, e:
                err_info = u"在log文件中链接抓包文件发生异常: %s" % e

        log.user_warn(err_info)
    
    def _get_default_log_dir(self):
        """
        功能描述: 获取默认的log保存路径
        
        参数：无
        
        返回：
            ret       1 or -1 成功状态码
            ret_data  log保存路径 or 错误信息
        """
        ret      = FLAG_SUCCEED
        ret_data = ""
        
        try:
            variables = BuiltIn().get_variables()
            outdir = variables['${OUTPUTDIR}']
            log_file = variables['${LOGFILE}']
            log_dir = os.path.dirname(log_file) if log_file != 'NONE' else '.'
            
            ret_data = os.path.join(outdir, log_dir)
        except Exception,e:
            ret_data = u"获取当前测试的log路径发生异常,异常信息：%s" % e

        return ret, ret_data
    
    def _get_packet_file_path(self, tuple_data):
        """
        功能描述：获取默认的抓包文件保存的路径
        
        参数：tuple_data  (prefix, file_path)
        
        返回：file_path or error_message
                
        """
        ret       = FLAG_SUCCEED
        ret_data  = ""
        prefix    = tuple_data[0]
        file_path = tuple_data[1]
        
        for i in [1]:
            try:
                # 根据用户输入组建文件名
                file_name = "%s_%s.pcap" % (prefix, get_time_stamp())
                
                # 对用户输入的文件路径做检查                 
                if isdir(file_path):
                    file_path = join(file_path, file_name)
                        
                elif isfile(file_path):
                    file_path = join(dirname(file_path), file_name) 
                
                elif file_path == "default":
                    pass                
                else:
                    try:
                        drive_name = os.path.splitdrive(file_path)[0]
                        if exists(drive_name): 
                            os.mkdir(file_path)
                            str_data = u"输入的路径不存在，创建新的目录 %s 成功！" % file_path
                            file_path = join(file_path, file_name)
                        else:
                            str_data = u"输入的路径 %s 盘符不合法或者没有包含盘符，将使用默认路径！" % file_path
                            log.user_warn(str_data)
                            file_path = "default"
                    except Exception,e:
                        err_info = u"输入的路径 %s 不存在，创建新目录失败，失败原因：%s\n将使用默认路径！" % (file_path, e)
                        log.user_warn(err_info)
                        file_path = "default"
                        
                if file_path == "default":
                    ret, ret_data = self._get_default_file_path(file_name)
                
            except Exception, e:
                ret = FLAG_FAIL
                ret_data = u"设置报文文件保存的路径发生异常，错误信息为：%s" % e
        
        if not ret_data:
            ret_data = file_path
            
        if ret != FLAG_FAIL:
            str_data = u"设置抓包报文文件保存的路径成功，完整路径为：%s" %  ret_data
            log.user_info(str_data)
            
        return ret, ret_data
    
    def _get_default_file_path(self, file_name):
        """
        """
        ret_data = ""
        
        ret, str_data = self._get_default_log_dir()
        if ret == FLAG_SUCCEED:
            ret_data = join(str_data, file_name)
        else:
            ret_data = str_data
            
        return ret, ret_data
    
    def _check_prefix(self, prefix="ATT"):
        """
        功能描述：检查用户输入的文件名前缀
        
        参数：prifix: 文件名前缀，默认ATT
              file_path: 文件保存的路径,默认default，表示保存到log路径下
                
        返回值：无
        """
    
        if not isinstance(prefix, unicode):
            prefix = prefix.decode('utf-8')
                
        # 文件名前缀入参检查 
        special_char_reg = "[^\\\/\:\*\?\"\<\>\|]*[\\\/\:\*\?\"\<\>\|]"
        if  re.match(special_char_reg,prefix):
            err_info = u'输入的文件名前缀 %s 包含特殊字符（: \\ / " | * < >等），无法设置为文件名，请确认！' % prefix
            raise RuntimeError(err_info)
        
    def _check_wireshark_stop(self, flag_pid):
        """
        """
        cls = self._current_remotelocal()

        dict_data = cls.dict_capture_obj.get(flag_pid)

        if not dict_data:
            err_data = u"没有找到相应抓包服务器"
            log.user_err(err_data)
            raise RuntimeError(err_data)
        elif dict_data.get("flag_stop"):
            return True
        else:
            return False
    
 
def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(WireShark(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)
    
def test():
    cls = WireShark()
    cls.init_wireshark_network_card("1",u"办公网")
    #flag_pid = cls.start_wireshark_capture("tchgfhgp", "111", "c:\\zshijie")
    #time.sleep(20)
    #ret = cls.stop_wireshark(flag_pid)
    #time.sleep(4)
    #ret = cls.stop_wireshark(flag_pid)
    flag_pid = "46546546"
    cls.stop_wireshark_capture(flag_pid)
    ret = cls.wireshark_query_option_str_value(flag_pid, "smb", "")
    ret2 = cls.wireshark_query_option_byte_value(flag_pid, "ip.version", "")
    pass
    
if __name__ == '__main__':
    test()