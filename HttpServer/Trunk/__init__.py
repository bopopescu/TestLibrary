# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: HttpServer
#  function:
#       实现了HttpServer库关键字封装
#
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
# ***************************************************************************


import os
import sys
import time
import copy


from robot.errors import DataError
from robot.libraries.Remote import Remote

from ATTTWHttpServer import ATTTWHttpServer, ATTTHTTPSERVER_SUC, ATTTHTTPSERVER_FAIL

from attcommonfun import *
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log

REMOTE_PORT = REMOTE_PORTS.get('HttpServer')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600


#导入cache控制类
from HttpServerCache import HttpServerCache, No_Remote_or_local_Exception


#httpserver
class HttpServer(HttpServerCache):
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        HttpServerCache.__init__(self)
    
    def __del__(self):
        try:
            self._remote_release_stop_all_http_server()
        except Exception,e:
            pass

        
    def init_http_server(self, alias, port, remote_url=False):
        """
        功能描述：初始化HTTP服务器
        
        参数：
            alias：别名；
            port：打开服务所用的端口号；
            remote_url：是否要进行远程控制；
        格式为：http://remote_IP.可以用一下的几种方式进行初始化。
        注意别名请设置为不同的别名，切换的时候用别名进行切换。
        
        Example:
        | Init Http Server  | Local   | 8080     |
        | Init Http Server  | remote  | 8080     | http://10.10.10.85 |
        
        """
        #检查PORT数据的合法性
        ret,data = check_port(port)
        if ret == ATTCOMMONFUN_FAIL:
            raise RuntimeError(u"关键字执行失败，端口号为非法数据！")
        
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._check_init_alias(alias, port, remote_url)
            if (ret_alias):
                reallib = self._switch_current_object(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._check_init_alias(alias, port, remote_url)
            if (ret_alias):
                reallib =  self._switch_current_object(ret_alias)
            else:
                try:
                    #TODO
                    #创建ATTTWHttpServer实例对象
                    reallib = ATTTWHttpServer(port)
                    
                except Exception,e:
                    raise RuntimeError(u"初始化ATTTWHttpServer对象失败")
        
        tag = self._register_object(reallib, alias, port, remote_url)
        
        return tag
    
    
    def switch_http_server(self, alias):
        """
        功能描述：切换当前已开启的HTTP服务器
        
        参数：
            alias：别名；
        
        Example:
        | Init  Http Server  | local_1     | 8080 |
        | Start Http Server  | 10.10.10.10 |  E:\\\Test\\\ | HTTP/1.0 |
        | Init  Http Server  | local_2     | 8888 |
        | Start Http Server  | 10.10.10.10 |  E:\\\Test\\\ | HTTP/1.0 |
        | Switch Http Server | local_1     |      |
        
        """
        try:
            cls=self._switch_current_object(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'切换到别名为：%s 的Httpserver成功' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError(u"没有找到别名对应的对象：'%s'" % alias)
        
        
    def start_http_server(self, host, home_dir, protocol="HTTP/1.0"):
        """
        功能描述：开启HTTP服务器
        
        参数：
            host: HTTP服务器所在主机ip地址
            home_dir: HTTP服务器的主目录
            protocol：HTTP服务协议
            
        Example:
        | Init Http Server  | local       | 8080 |
        | Start Http Server | 10.10.10.10 |  E:\\\\Test\\\\ | HTTP/1.0 |
        | Start Http Server | 10.10.10.10 |  E:\\\\Test\\\\ |
        """
        # 检查IP地址合法性
        if not check_ipaddr_validity(host):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        #获取当前对象句柄
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            raise RuntimeError(u'没有可操作对象存在')
        
        #判断对象属性是远端还是本端
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
            cls._client.set_timeout(REMOTE_TIMEOUT)
            
        else:
            #检查文件夹是否可用
            if (not os.path.exists(home_dir)) or (not os.path.isdir(home_dir)):
                log_data=u"启动服务器失败，配置的服务器文件夹地址错误"
                raise RuntimeError(log_data)
            
            #初始化对象
            ret, log_data=cls.init_httpservet(host,home_dir)
            if ATTTHTTPSERVER_SUC == ret:
                #log.user_info(u'初始化HTTP服务器数据成功')
                
                #启动HTTP服务
                ret, log_data=cls.start_httpservet()
                #if ATTTHTTPSERVER_SUC == ret:
                #    log.user_info(u'启动HTTP服务器成功')
                    
            else:
                #log.user_info(u'初始化HTTP服务器数据失败')
                pass
            
            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'启动HTTP服务器成功')
                #log.user_info(log_data)
            else:
                log.user_info(u"启动HTTP服务器失败")
                raise RuntimeError(log_data)
        
        
    def stop_http_server(self):
        """
        功能描述：停止HTTP服务器
        
        参数：无
        
        Example:
        | Stop Http Server |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不需要停止!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #停止HTTP服务器
            ret, log_data=cls.stop_httpservet()
            
            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u"停止HTTP服务器成功")
            else:
                log.user_info(u"停止HTTP服务器失败")
                raise RuntimeError(log_data)
        

    def http_server_register_user_account(self,uname,upassword):
        """
        功能描述：注册账户
        
        参数：
            uname：账户名称，用于唯一标识某一个账户；
            upassword：账户密码；
        
        Example:
        | Http Server Register User Account | user1 | 123456 |
        """
        #检查账户名称的合法性
        temp_uname=copy.deepcopy(uname)
        if isinstance(uname, unicode):
            temp_uname=temp_uname.encode('utf-8')
        
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能注册账户!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #注册用户
            ret, log_data=cls.register_user_account(uname,upassword)
            
            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'注册访问HTTP服务器账号成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'注册访问HTTP服务器账号失败')
                if len(temp_uname)==0:
                    log_data=u'注册访问HTTP服务器账号失败,账户名称不能为空！'
                    
                raise RuntimeError(log_data)
        

    def http_server_unregister_user_account(self,uname):
        """
        功能描述：注销账户
        
        参数：
            uname：账户名称，用于唯一标识某一个账户；
        
        Example:
        | Http Server Unregister User Account | user1 |
        """
        #检查账户名称的合法性
        temp_uname=copy.deepcopy(uname)
        if isinstance(uname, unicode):
            temp_uname=temp_uname.encode('utf-8')
        
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能注销账户!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #注销用户
            ret, log_data = cls.unregister_user_account(uname)
            
            if ret == ATTTHTTPSERVER_SUC:
                #log.user_info(u'注销访问HTTP服务器账号成功')
                log.user_info(log_data)
            else:
                log.user_info(u'注销访问HTTP服务器账号失败')
                raise RuntimeError(log_data)


    def http_server_open_check_authorization(self):
        """
        功能描述：开启用户权限验证
        
        参数：无
        
        Example:
        | Http Server Open Check Authorization |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能开启用户权限验证!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #打开用户权限验证
            ret, log_data = cls.open_check_authorization()

            if ret == ATTTHTTPSERVER_SUC:
                #log.user_info(log_data)
                log.user_info(u'开启用户权限验证模块成功')
            else:
                log.user_info(u'开启用户权限验证模块失败')
                raise RuntimeError(log_data)
        
    
    def http_server_close_check_authorization(self):
        """
        功能描述：关闭用户权限验证
        
        参数：无
        
        Example:
        | Http Server Close Check Authorization |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能关闭用户权限验证!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #关闭用户权限验证
            ret, log_data = cls.close_check_authorization()

            if ret == ATTTHTTPSERVER_SUC:
                #log.user_info(log_data)
                log.user_info(u'关闭用户权限验证模块成功')
            else:
                log.user_info(u'关闭用户权限验证模块失败')
                raise RuntimeError(log_data)
        
        
    def http_server_set_response_status_code(self, status_code):
        """
        功能描述：设置响应状态码的值
        
        参数：
            status_code：设置HTTP状态码响应的值；
        
        Example:
        | Http Server Set Response Status Code | 403 |
        """
        
        #检查状态码的合法性
        temp_status_code=copy.deepcopy(status_code)
        if isinstance(status_code, unicode):
            temp_status_code=temp_status_code.encode('utf-8')
                
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能设置响应状态码的值!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #设置状态码的值
            ret, log_data = cls.set_response_status_code(status_code)

            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'设置响应状态码的值成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'设置响应状态码的值失败')
                
                if not temp_status_code.isdigit():
                    log_data=u"设置响应状态码的值失败，状态码响应的值非法！"
                else:
                    if int(temp_status_code) < 100 or int(temp_status_code)> 600:
                       log_data=u"设置响应状态码的值失败，状态码响应的值非法！"

                raise RuntimeError(log_data)

        
    def http_server_open_response_status_code(self):
        """
        功能描述：开启状态码响应模块
        
        参数：无

        Example:
        | Http Server Open Response Status Code |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能开启状态码响应模块!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #开启状态码响应模块
            ret, log_data = cls.open_response_status_code()

            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'开启状态码响应模块成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'开启状态码响应模块失败')
                raise RuntimeError(log_data)
    
    
    def http_server_close_response_status_code(self):
        """
        功能描述：关闭状态码响应模块
        
        参数：无

        Example:
        | Http Server Close Response Status Code |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能关闭状态码响应模块!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #关闭状态码响应模块
            ret, log_data = cls.close_response_status_code()

            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'关闭状态码响应模块成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'关闭状态码响应模块失败')
                raise RuntimeError(log_data)


    def stop_all_http_server(self):
        """
        功能描述：停止所有本地和远端的HTTP服务器
        
        参数：无
        
        Example:
        | Stop All Http Server |
        """
        try:
            alias_list=self._get_object_alias_list()
        except Exception, e:
            error_info=u"停止所有本地和远端的HTTP服务器失败，获取HTTP服务器对象别名列表异常！"
            raise RuntimeError(error_info)

        if not alias_list:
            log.user_warn(u"没有HTTP服务器对象，不需要关闭!")
            return
        
        for alias in alias_list:
            try:
                self.switch_http_server(alias)
                self.stop_http_server()
            except Exception, e:
                error_info=u"停止HTTP服务器(alias=%s)失败" % alias
                raise RuntimeError(error_info)
            
        log.user_info(u'停止所有本地和远端的HTTP服务器成功')
        return

    
    def _remote_release_stop_all_http_server(self):
        """
        功能描述：远端消费对象时调用停止所有本地和远端的HTTP服务器
        """
        try:
            alias_list=self._get_object_alias_list()
        except Exception, e:
            return

        if not alias_list:
            return
        
        for alias in alias_list:
            try:
                self.switch_http_server(alias)
                self.stop_http_server()
            except Exception, e:
                pass
            
        self._clear_all_object_alias()
        
        return
    
    
    #add by wangjun 20131119
    def http_server_set_client_authorization_type(self,type_string):
        """
        功能描述：设置客户端认证模式
        
        参数：
            type_string: 描述认证模式类型的字符串，有效取值为：BASIC或DIGEST，值不区分大小写;
        
        注意：
            BASIC类型表示只支持BASIC认证；默认客户端认证模式为BASIC类型；
            DIGEST类型表示只支持DIGEST认证；
            
        Example:
        | Http Server Set Client Authorization Type | BASIC |
        | Http Server Set Client Authorization Type | DIGEST |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能设置客户端认证模式!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #设置客户端认证模式
            ret, log_data = cls.set_client_authorization_type(type_string)

            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'设置客户端认证模式成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'设置客户端认证模式失败')
                raise RuntimeError(log_data)


    def http_server_set_client_upload_type(self,type_string):
        """
        功能描述：设置客户端上传模式
        
        参数：
            type_string: 描述上传模式类型的字符串，有效取值为：POST或PUT或BOTH，值不区分大小写;
        
        注意：
            POST类型表示只支持POST上传；
            PUT类型表示只支持PUT上传；
            BOTH类型表示既支持POST上传也支持PUT上传；默认客户端上传模式为BOTH类型；
            
        Example:
        | Http Server Set Client Upload Type | POST |
        | Http Server Set Client Upload Type | PUT |
        | Http Server Set Client Upload Type | BOTH |
        """
        try:
            cls = self._get_current_object()
        except No_Remote_or_local_Exception:
            log.user_warn(u"HTTP服务器未开启，不能设置客户端上传模式!")
            return
        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            #TODO
            #设置客户端上传模式
            ret, log_data = cls.set_client_upload_type(type_string)

            if ret == ATTTHTTPSERVER_SUC:
                log.user_info(u'设置客户端上传模式成功')
                #log.user_info(log_data)
            else:
                log.user_info(u'设置客户端上传模式失败')
                raise RuntimeError(log_data)



def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(HttpServer(), host, port)
        return None
    except Exception, e:
        log_data = u"start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)
    
    
def Test():
    try:
        time_length=10
        
        http = HttpServer()
        http.init_http_server(alias = "local", port=8080)
        http.start_http_server(host='172.16.28.59', home_dir="e:\\httpserver", protocol="HTTP/1.0")
        time.sleep(time_length)
        
        http.http_server_register_user_account("wangjun-httpserver","123456")
        time.sleep(time_length)
        http.http_server_open_check_authorization()
        time.sleep(time_length)
        http.http_server_close_check_authorization()
        time.sleep(time_length)
        http.http_server_unregister_user_account("wangjun-httpserver")
        time.sleep(time_length)
        
        http.http_server_set_response_status_code("405")
        time.sleep(time_length)
        http.http_server_open_response_status_code()
        time.sleep(time_length)
        http.http_server_close_response_status_code()
        time.sleep(time_length)
        
        time.sleep(time_length)
        
        http.stop_http_server()
    
    except Exception, e:
        print e

def test2():
    try:
        start_library("10.10.10.50",58017,"HttpServer")
        
    except Exception, e:
        print e

if __name__ == '__main__':
    #Test()
    test2()