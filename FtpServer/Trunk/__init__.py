# -*- coding: utf-8 -*-
import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTFtpServer import ATTFtpServer
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log
REMOTE_PORT = REMOTE_PORTS.get('FtpServer')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600

#add by jias
#没有对象的异常类
class No_Remote_or_local_Exception(Exception):
    pass

class FtpServer():
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}
        
    def _register_alias(self, alias, port, remote_url):
        
        # 对别名判断做了修改 zsj 2013-3-28
        # 改成以别名为健（当前要求别名唯一） change by yzm @ 20130328
        # 因前面已经保证了alias唯一，则直接对alias进行赋值（赋新值可保证网卡信息为最新的信息）
        self.dict_alias[alias] = (port, remote_url)

    def _is_init(self, alias, port, remote_url):
        """
        return alias
        """
        # 先判断别名是否被使用过
        tuple_value  = self.dict_alias.get(alias)
        if tuple_value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url以及name或者mac）
            if remote_url in tuple_value and port in tuple_value:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            # 如果没被使用过，需判断当前的对象是否曾经被初始化过
            for key, tuple_value in self.dict_alias.items():
                if remote_url in tuple_value and port in tuple_value:
                    # 如果相符，则可以直接返回_key（只要找到即可返回）
                    return key 

        # 两种情况都不包含，则返回None
        return None
    
    def init_ftp_server(self, alias, port, remote_url=False):
        """
        功能描述：初始化执行ftp server；
        
        参数：
            alias：别名；
            port：打开服务所用的端口号；
            remote_url：是否要进行远程控制；
        格式为：http://remote_IP.可以用以下的几种方式进行初始化。
        注意别名请设置为不同的别名，切换的时候用别名进行切换。
        
        Example:
        | Init Ftp Server  | Local   | 21     |
        | Init Ftp Server  | remote  | 21     | http://10.10.10.85 |
        
        """
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._is_init(alias, port, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(alias, port, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTFtpServer(port)
            
        tag = self._cache.register(reallib, alias)
        self._register_alias(alias, port, remote_url)

        return tag
    
    def _current_remotelocal(self):
        if not self._cache.current:
            #raise RuntimeError('No remotelocal is open')
            #modified by jias 改为抛出异常，让外面的函数处理
            raise No_Remote_or_local_Exception
        
        return self._cache.current       
    
    def switch_ftp_server(self, alias):
        """
        功能描述：切换当前已开启的ftp server；
        
        参数：
            alias：别名；
        
        Example:
        | Init  Ftp Server  | local_1     | 21       |
        | Start Ftp Server  | 10.10.10.10 |  ftptest | ftptest |
        | Init Ftp Server  | local_2     | 22       |
        | Start Ftp Server  | 10.10.10.10 |  ftptest | ftptest |
        | Switch Ftp Server | local_1     |          |
        """
        try:
            cls=self._cache.switch(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'切换到别名为：%s 的FtpServer成功' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)  
    
    
    def start_ftp_server(self, ip, username="ftptest", password="ftptest", homedir="C:\\"):
        """
        功能描述：启动FTP服务器，如果username不为空，则会新建一个拥有所有权限的账户
        
        参数：  ip: IP地址,
                username: 新建账户用户名,默认为ftptest,
                password: 新建账户密码,默认为ftptest,
                homedir: 根目录,windows下默认是C盘。
                
        返回值：无，如果启动失败，则返回异常
        
        Example:
        | Init  Ftp Server  | local_1     | 21   |
        | Start Ftp Server  | 10.10.10.10 | test | test | E:\\\Test\\\  |
        | Init  Ftp Server  | local_1     | 21   | 172.16.28.41   |
        | Start Ftp Server  | 10.10.10.9  | test | test | E:\\\Test\\\  |
        """
        # 检查IP地址合法性
        if not check_ipaddr_validity(ip):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        try:
            cls = self._current_remotelocal()      
        except No_Remote_or_local_Exception:
            raise RuntimeError('No remotelocal is open')
        
        if (isinstance(cls, Remote)):
             # 底层等待FTP服务器起来和判断进程是否已经真正起来需要10s
            cls._client.set_timeout(REMOTE_TIMEOUT + 10) 
            auto_do_remote(cls)
            cls._client.set_timeout(REMOTE_TIMEOUT) 
        else:
            cls.start_ftp_server(ip, username, password, homedir)
        
    def stop_ftp_server(self):
        """
        功能描述：停止ftp服务器
        
        参数：无
        
        Example:
        | Stop Ftp Server |   |   | 
        
        """
        try:
            cls = self._current_remotelocal()              
        except No_Remote_or_local_Exception:
            #modified by jias
            #修改为 没初始化实例的时候，调用关闭不报错
            log.user_warn(u"FTP服务器未开启，不需要停止!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.stop_ftp_server()
            
    def stop_all_ftp_server(self):
        """
        功能描述：停止所有ftp服务器
        
        参数：无
        
        Example:
        | Stop All Ftp Server |   |   | 
        
        """
        alias_list = self.dict_alias.keys()
            
        if not alias_list:
            log.user_warn(u"没有ftp服务器对象，不需要关闭!")
            return

        for alias in alias_list:            
            try:
                self.switch_ftp_server(alias)
                self.stop_ftp_server()
            except Exception, e:
                continue

def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(FtpServer(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)

if __name__ == '__main__':
    t = FtpServer()
    print "test"