# -*- coding: utf-8 -*-
import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTTCPServer import ATTTCPServer, ATTTCPSERVER_SUC, ATTTCPSERVER_FAIL
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log

REMOTE_PORT = REMOTE_PORTS.get('TCPServer')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600


#没有对象的异常类
class No_Remote_or_local_Exception(Exception):
    pass

class TCPServer():
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        """
        initial
        """
        
        self._cache = ConnectionCache()
        self.dict_alias = {}  
    
    
    def _register_alias(self, alias, remote_url):
        """
        注册别名和remote_url
        """
        
        self.dict_alias[alias] = (remote_url,)
    
    
    def _is_init(self, alias, remote_url):
        """
        判断别名是否被使用过，
        如果是被同一个对象使用，返回别名,不是同一个对象，报错，
        没有被使用过则返回None
        """
        
        # 先判断别名是否被使用过
        tuple_value  = self.dict_alias.get(alias)
        if tuple_value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url）
            if remote_url in tuple_value:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            return None
    
    
    def _current_remotelocal(self):
        """
        返回当前别名的对象，可能是remote，也可能是local。如果不存在则抛出异常
        """
        
        if not self._cache.current:
            raise No_Remote_or_local_Exception
            
        return self._cache.current      
    
    
    def init_tcp_server(self, alias, remote_url=False):
        """
        功能描述：初始化一个本地或远端的TCP Server；
        
        参数：
            alias：TCP Server的别名，用于唯一标识某一个TCP Server；
            
            remote_url：如果要进行远程控制，传入远程控制的地址，格式为：http://remote_IP；否则使用默认值；
            
        注意别名请设置为不同的别名，切换的时候用别名进行切换。
        
        Example:
        | Init Tcp Server  | local   |                    |
        | Init Tcp Server  | remote  | http://10.10.10.85 |
        """
        
        # 检测用户输入的remote_url是否有“http://”头，如果没有则自动添加
        remote_url = modified_remote_url(remote_url)
        
        # 本地和远端采用不同的处理
        if (is_remote(remote_url)):
            # 判断当前别名是否已经初始化了,如果初始化了，则切换之前注册的remote object，否则新注册一个Remote object
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            # 设置远端连接的超时
            reallib._client.set_timeout(REMOTE_TIMEOUT)
            # 发送消息到远端执行
            auto_do_remote(reallib)
            
        else:
            # 判断当前别名是否已经初始化了,如果初始化了，则切换之前注册的local object，否则新注册一个local object
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTTCPServer()
                
        # 注册object对象和别名    
        tag = self._cache.register(reallib, alias)
        # 注册别名和remote_url
        self._register_alias(alias, remote_url)
        
        return tag 
    
    
    def switch_tcp_server(self, alias):
        """
        功能描述：切换当前已初始化的TCP Server；
        
        参数：
            alias：TCP Server的别名，用于唯一标识某一个TCP Server；
        
        Example:
        | Init Tcp Server   | local   |                    |
        | Init Tcp Server   | remote  | http://10.10.10.85 |
        | Switch Tcp Server | local   |                    |
        """
        
        try:
            obj = self._cache.switch(alias)                 
            if (isinstance(obj, Remote)):
                # remote class do switch
                auto_do_remote(obj)
            else:
                log_data = u'切换到别名为：%s 的TCPServer成功' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)  
        
    def start_tcp_server(self, port=60000, ip='0.0.0.0'):
        """
        功能描述：开启TCP Server
        
        参数：
            port: TCP Server监听的端口号，默认为60000
            
            ip:   TCP server监听的IP地址,默认为0.0.0.0，监听主机上所有的地址
            
        Example:
        | Init Tcp Server  | local  |             |
        | Start Tcp Server | 60010  | 10.10.10.10 |
        """
        
        # 检查IP地址合法性
        if not check_ipaddr_validity(ip):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 检查port端口合法性
        ret, ret_str = check_port(port)
        if ret == ATTCOMMONFUN_FAIL:
            raise RuntimeError(ret_str)
        
        try:
            obj = self._current_remotelocal()
        except No_Remote_or_local_Exception:
            raise RuntimeError('No remote or local object is inited')
        
        if (isinstance(obj, Remote)):
            auto_do_remote(obj)
        else:
            ret, log_data = obj.start_tcp_server(ip, int(port))
            
            if ret == ATTTCPSERVER_SUC:
                log.user_info(log_data)
            else:
                raise RuntimeError(log_data)
       
    
    def stop_tcp_server(self):
        """
        功能描述：停止TCP Server
        
        参数：无
        
        Example:
        | Stop Tcp Server |   |   |  | 
        """
        
        try:
            obj = self._current_remotelocal()
        except No_Remote_or_local_Exception:
            log.user_warn(u"TCP Server未开启，不需要停止!")
            return
        
        if (isinstance(obj, Remote)):
            auto_do_remote(obj)
        else:
            ret, log_data = obj.stop_tcp_server()
            
            if ret == ATTTCPSERVER_SUC:
                log.user_info(log_data)
            else:
                raise RuntimeError(log_data)
            
            
    def stop_all_tcp_server(self):
        """
        功能描述：停止所有开启的 TCP Server
        
        参数：无
        
        Example:
        | Stop All Tcp Server |   |   |  | 
        """
        
        alias_list = self.dict_alias.keys()
        
        if not alias_list:
            log.user_info(u"没有初始化TCP Server!")
            
        for alias in alias_list:
            try:
                self.switch_tcp_server(alias)
                self.stop_tcp_server()
            except Exception, e:
                log_info = u"关闭TCP Server %s 发生异常，错误信息为%s" % (alias, e)
                raise RuntimeError(log_info)
            
        
    
def start_library(host="172.0.0.1", port=REMOTE_PORT, library_name=""):
    
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e)
    
    try:
        RobotRemoteServer(TCPServer(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)
    
    
def test():
    tcp = TCPServer()
    tcp.stop_tcp_server()
    tcp.init_tcp_server(alias = "local")
    tcp.stop_tcp_server()
    tcp.start_tcp_server(port=55555, ip='172.16.28.49')
    import time
    time.sleep(300)
    tcp.stop_tcp_server()    
    tcp.stop_tcp_server()

def test1():
    tcp = TCPServer()
    tcp.init_tcp_server(alias="local1")
    tcp.init_tcp_server(alias="local2")
    tcp.switch_tcp_server("local1")
    tcp.start_tcp_server(port=55555, ip='127.0.0.1')
    tcp.switch_tcp_server("local2")
    tcp.start_tcp_server(port=55555, ip='0.0.0.0')
    import time
    time.sleep(10)
    tcp.stop_tcp_server()
    tcp.switch_tcp_server("local1")
    tcp.stop_tcp_server()
    
    
if __name__ == '__main__':
    test1()