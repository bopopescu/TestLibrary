# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTTWHttpServer
#  class:
#       ATTTWHttpServer类：继承自BasePIPEParentControl类，实现了对HttpServer库关键字功能支撑模块封装
#       HttpServerPIPEProcess类：加载提供HttpServer服务的子进程，并建立父子进程间管道通讯机制
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
#         wangjun   2014.1.13    删除ATTTWHttpServer类中_check_port_status解决，改为调用框架提供的公共函数接口，check_port_status。
#         wangjun   2014.2.25    修改检查服务器是否启动成功检查对“0.0.0.0”地址支持
# ***************************************************************************


import os
import time
import multiprocessing
import threading
import copy
import subprocess
import sys

from attcommonfun import check_port_status

#加载string语句定义
import TwistedHttpServer.MyChars as MyChars

#LOG模块
from TwistedHttpServer.MyEvent import ProcessOutLog as log



#导入MyHttpServer模块
g_import_twhttserver_suc_flag=False
try:
    from TwistedHttpServer.MyHttpServer import MyHttpServer
    g_import_twhttserver_suc_flag=True
except Exception, e:
    g_import_twhttserver_suc_flag=False
    #log.debug_info(str(e))
                

#具体接口消息ID
from TwistedHttpServer.MyEvent import MESSAGE_ID_REGISTER_USER_ACCOUNT,\
                                        MESSAGE_ID_UNREGISTER_USER_ACCOUNT,\
                                        MESSAGE_ID_OPEN_CHECK_AUTHORIZATION,\
                                        MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION,\
                                        MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE,\
                                        MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE,\
                                        MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER,\
                                        MESSAGE_ID_SET_AUTH_TYPE,\
                                        MESSAGE_ID_SET_UPLOAD_TYPE

#加载进程通讯基础类
from TwistedHttpServer.BasePIPEProcess import BasePIPEProcess, BasePIPEParentControl

#共享变量数据项
from TwistedHttpServer.BasePIPEProcess import PROCESS_SHARE_RUN_STATUS, PROCESS_SHARE_RUN_RESPONSE

#导入消息体中用的的常量定义
from TwistedHttpServer.BasePIPEProcess import REQUEST_MESSAGE_FORMAT_ITEM_COUNT, REQUEST
from TwistedHttpServer.BasePIPEProcess import RESPONSE_MESSAGE_FORMAT_ITEM_COUNT, RESPONSE
from TwistedHttpServer.BasePIPEProcess import MESSAGE_ID_SUC, MESSAGE_ID_ERROR, MESSAGE_ID_QUIT
from TwistedHttpServer.BasePIPEProcess import PROCESS_START_STATUS_INIT,PROCESS_START_STATUS_FAIL,PROCESS_START_STATUS_SUC

#=================================================
#子进程返回数据处理结果标志
from TwistedHttpServer.BasePIPEProcess import RECV_PIPE_HANDLE_NOT_INIT,\
                                                RESPONSE_MESSAGE_TYPE_ERROR,\
                                                RESPONSE_DATA_TYPE_ERROR,\
                                                RESPONSE_REQUEST_RUN_FAIL,\
                                                RESPONSE_REQUEST_QUIT_PROCESS_FAIL

#=================================================


#请求处理完成结果
ATTTHTTPSERVER_SUC=True
ATTTHTTPSERVER_FAIL=False


#表示服务器运行状态
TWFHTTPSERVER_PROCESS_STATUS_INIT="TWFHTTPSERVER_PROCESS_STATUS_INIT"
TWFHTTPSERVER_PROCESS_STATUS_READY_SUC="TWFHTTPSERVER_PROCESS_STATUS_READY_SUC"
TWFHTTPSERVER_PROCESS_STATUS_READY_FAIL="TWFHTTPSERVER_PROCESS_STATUS_READY_FAIL"
TWFHTTPSERVER_PROCESS_STATUS_START_SUC="TWFHTTPSERVER_PROCESS_STATUS_START_SUC"
TWFHTTPSERVER_PROCESS_STATUS_START_FAIL="TWFHTTPSERVER_PROCESS_STATUS_START_FAIL"
TWFHTTPSERVER_PROCESS_STATUS_STOP_SUC="TWFHTTPSERVER_PROCESS_STATUS_STOP_SUC"
TWFHTTPSERVER_PROCESS_STATUS_STOP_FAIL="TWFHTTPSERVER_PROCESS_STATUS_STOP_FAIL"


class ATTTWHttpServer(BasePIPEParentControl):
    
    def __init__(self,in_server_listen_port):
        """
        初始化Twisted Http Server
        """
        try:
            #初始化基类
            BasePIPEParentControl.__init__(self)
            
            self.pro_server_handle=None
            
            self.server_listen_port=in_server_listen_port
            self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_INIT
            
            
        except Exception,e:
            log.debug_info(u"ATTTWHttpServer __init__ except :%s" % e)
            raise RuntimeError(e)
        

    def __del__(self):
        #销毁基类
        BasePIPEParentControl.__del__(self)
    
    
    def init_httpservet(self,server_address,server_home_workspace_dir):
        """
        初始化Twisted Http Server
        """
        log.debug_info(u"PROCESS_STATUS:%s" % self.server_running_flag)

        if TWFHTTPSERVER_PROCESS_STATUS_INIT != self.server_running_flag:
            
            #强制关闭遗留进程
            self._kill_httpserver_process()

        try:
            log.debug_info(u"call init_httpservet")
            
            global g_import_twhttserver_suc_flag
            if not g_import_twhttserver_suc_flag:
                error_info=u"No module named MyHttpServer"
                log.debug_info(error_info)
                return ATTTHTTPSERVER_FAIL,error_info

            if not check_port_status(server_address,self.server_listen_port):
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_CANNOT_LISTEN_THIS_PORT) % (server_address, self.server_listen_port)
                
                log.debug_err(rsp_string_data)
                return ATTTHTTPSERVER_FAIL,rsp_string_data
            
            #创建并启动进程对象
            self.pro_server_handle = HttpServerPIPEProcess(self.child_conn,
                                                   server_address,
                                                   self.server_listen_port,
                                                   server_home_workspace_dir)
            
            #add by wangjun 20131218
            self.pro_server_handle.daemon = True
            
            self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_READY_SUC
            
            return ATTTHTTPSERVER_SUC, ""
        
        except Exception, e:
            self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_READY_FAIL
            return self._exception_response(u"init_httpservet", e)
        


    def start_httpservet(self):
        """
        启动Twisted Http Server
        """
        log.debug_info(u"PROCESS_STATUS:%s" % self.server_running_flag)
        
        if TWFHTTPSERVER_PROCESS_STATUS_READY_SUC != self.server_running_flag:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_PEOCESS_STATUS_ERROR) % TWFHTTPSERVER_PROCESS_STATUS_READY_SUC
            log.debug_info(rsp_string_data)
            return ATTTHTTPSERVER_FAIL,rsp_string_data
        
        if not self.pro_server_handle:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_PEOCESS_NOT_INIT)
            log.debug_info(rsp_string_data)
            return ATTTHTTPSERVER_FAIL,rsp_string_data

        try:
            log.debug_info(u"call start_httpservet")

            self.pro_server_handle.start()
            #time.sleep(1)
            
            #获取到配置的HTTPSERVER服务器地址
            temp_server_host,temp_server_port = self.pro_server_handle.get_http_server_address()
            
            #检查进程进程以及服务器是否正常启动
            count = 30
            while count>0:
                
                if self.pro_server_handle.is_alive():
                    
                    #连接测试
                    #if self._check_server_working(temp_server_host,temp_server_port):
                    if self._check_zero_string_server_working(temp_server_host,temp_server_port):
                        count = -1
                        break

                time.sleep(2)
                count = count -1
            
            #启动服务器失败
            if 0 == count:
                self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_START_FAIL
                
                #关闭服务进程
                self._kill_httpserver_process()
                
                rc_status = ATTTHTTPSERVER_FAIL
                rc_data = "start httpserver process fail, check process status not alive."
                
            else:
                
                self.pro_server_object_pid=self.pro_server_handle.pid
                log.debug_info(u"HttpServerPIPEProcess pro_server_object_pid=%d" % self.pro_server_object_pid)
                
                self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_START_SUC
                
                rc_status = ATTTHTTPSERVER_SUC
                rc_data = "start httpservet process SUC"    
                
            #返回启动结果
            return rc_status,rc_data
            
        except Exception, e:
            self.server_running_flag=TWFHTTPSERVER_PROCESS_STATUS_START_FAIL
            
            #关闭服务进程
            self._kill_httpserver_process()
            
            return self._exception_response(u"start_httpservet", e)


    def _check_zero_string_server_working(self, in_address, in_port):
        """
        特殊处理"0.0.0.0"地址
        """
        
        if "0.0.0.0" == in_address:
            local_ip_list = self._get_local_ip()
            
            ret = False
            for ip_item in local_ip_list:
                ret = self._check_server_working(ip_item,int(in_port))
                if True == ret:
                    break
                
            return ret
        
        else:
            return self._check_server_working(in_address,int(in_port))
        
        
    def _get_local_ip(self):
        """
        函数功能：获取本机所有ip地址
        return:
            list_ip = []
        """
        import socket
        
        list_ip = []
        try:
            ip_data = socket.gethostbyname_ex(socket.gethostname())
            
            temp_in = []
            if len(ip_data) > 1:
                temp_ip = ip_data[2]
                
            if not isinstance(temp_in, list):
                list_ip = [temp_ip]
            else:
                list_ip = temp_ip
                
        except Exception, e:
            _log_string(u"获取本机所有ip地址失败,失败信息：%s" % e)
            
        return list_ip


    def _check_server_working(self, in_address, in_port):
        """
        通过telnetlib库open socket从服务器地址列表中探测本机可用的服务器地址
        如果找到可用地址，返回True，否则返回False
        """
        
        ret = False
        
        try:
            import telnetlib

            timeout = 2
            telent_obj = telnetlib.Telnet()
            log.debug_info(u"connect to %s:%s\n" % (in_address,int(in_port)))

            telent_obj.open(in_address,int(in_port),timeout)
            rc_sock = telent_obj.get_socket()
            telent_obj.close()

            ret = True
            log.debug_info(u"connect to %s:%s suc\n" % (in_address,in_port))
        
        except Exception, e:
            log.debug_info(u"connect to %s:%s %s\n" % (in_address,in_port,e) )
                
        return ret
        

   
    def _kill_httpserver_process(self):
        """
        强制杀死进程服务模块进程
        """
        try:
            if not self.pro_server_handle or not self.pro_server_handle.is_alive():
                return

            #强制关闭进程
            log.debug_info(u"_kill_httpserver_process")

            try:
                os.kill(self.pro_server_handle.pid, 9)
                del self.pro_server_handle
            except Exception,e:
                try:
                    os.kill(self.pro_server_handle.pid, 9)
                    del self.pro_server_handle
                except Exception,e:
                    pass
                
            self.pro_server_handle = None
            self.server_running_flag = TWFHTTPSERVER_PROCESS_STATUS_INIT

        except Exception,e:
            self.pro_server_handle = None
            self.server_running_flag = TWFHTTPSERVER_PROCESS_STATUS_INIT
        
    
    def stop_httpservet(self):
        """
        停止Twisted Http Server
        """
        log.debug_info(u"PROCESS_STATUS:%s" % self.server_running_flag)
        
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag and
            TWFHTTPSERVER_PROCESS_STATUS_START_FAIL!= self.server_running_flag):
            return ATTTHTTPSERVER_SUC, ""
        
        if not self.parent_conn:
            log.debug_info(u"parent_conn is NoneType")
            return ATTTHTTPSERVER_SUC, ""
        
        if not self.pro_server_handle:
            log.debug_info(u"pro_server_handle is NoneType")
            return ATTTHTTPSERVER_SUC, ""

        try:
            log.debug_info(u"call stop_httpservet")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_QUIT, None])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            rc_flag,rc_data=self._recv_message_response_data()
            log.debug_info(u"wait run serve porcess object exit")
            #self.pro_server_handle.join()
            
            try:
                os.kill(self.pro_server_handle.pid, 9)
                del self.pro_server_handle
            except Exception,e:
                try:
                    os.kill(self.pro_server_handle.pid, 9)
                    del self.pro_server_handle
                except Exception,e:
                    pass

            self.pro_server_handle=None
            self.server_running_flag = TWFHTTPSERVER_PROCESS_STATUS_STOP_SUC
            
            return rc_flag,rc_data

        except Exception, e:
            self.server_running_flag = TWFHTTPSERVER_PROCESS_STATUS_STOP_FAIL
            return self._exception_response(u"stop_httpservet", e)
    
    
    def register_user_account(self,uname,upassword):
        """
        创建用户账户信息
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call register_user_account")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_REGISTER_USER_ACCOUNT, (uname,upassword)])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"register_user_account", e)
        

    def unregister_user_account(self,uname):
        """
        删除用户账户信息
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call register_user_account")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_UNREGISTER_USER_ACCOUNT, uname])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"unregister_user_account", e)


    def open_check_authorization(self):
        """
        开启用户权限验证
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call open_check_authorization")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_OPEN_CHECK_AUTHORIZATION, None])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"open_check_authorization", e)
        
    
    def close_check_authorization(self):
        """
        关闭用户权限验证
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call open_check_authorization")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION, None])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"close_check_authorization", e)
        
        
    def set_response_status_code(self, status_code):
        """
        设置状态码的值
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call set_response_status_code")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER, status_code])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"set_response_status_code", e)

        
    def open_response_status_code(self):
        """
        开启状态码响应模块
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call open_response_status_code")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE, None])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"open_response_status_code", e)
    
    
    def close_response_status_code(self):
        """
        关闭状态码响应模块
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call close_response_status_code")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE, None])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"close_response_status_code", e)
        
        
    #add by wangjun 20131119
    def set_client_authorization_type(self, type_string):
        """
        设置客户端认证模式Basic/Digest
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call set_client_authorization_type")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_SET_AUTH_TYPE, type_string])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
            
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"set_client_authorization_type", e)
        
        
    def set_client_upload_type(self, type_string):
        """
        设置客户端上传模式POST/PUT/BOTH
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        if not self.parent_conn:
            error_info = u"parent_conn is NoneType"
            return ATTTHTTPSERVER_FAIL,error_info
        
        try:
            log.debug_info(u"call set_client_upload_type")
            rc_send_flag = self._send_message_request_data([REQUEST, MESSAGE_ID_SET_UPLOAD_TYPE, type_string])
            if not rc_send_flag:
                error_info = u"send request message data fail"
                return ATTTHTTPSERVER_FAIL,error_info
        
            return self._recv_message_response_data()
        
        except Exception, e:
            return self._exception_response(u"set_client_upload_type", e)
                                        
                                        
    
    def _send_message_request_data(self, in_request_data_list ):
        
        if not self.pro_server_handle:
            log.debug_info(u"pro_server_handle is NoneType")
            return False
        
        if not self.pro_server_handle.is_alive():
            log.debug_info(u"pro_server_handle link process is not aliva")
            return False
        
        try:
            self.parent_conn.send(in_request_data_list)
            return True
        
        except Exception,e:
            log.debug_info(u"send request message data error")
            return False

    
    def _recv_message_response_data(self):
        """
        处理管道中的消息
        """
        if (TWFHTTPSERVER_PROCESS_STATUS_START_SUC != self.server_running_flag):
            return ATTTHTTPSERVER_FAIL, MyChars.STRING_PEOCESS_NOT_RUNNING
        
        #获取子进程处理消息返回结果
        rsp_status,rsp_type,rsp_data=self.recv_child_pipe_response_message_data()

        if rsp_status:
            
            #消息执行正常
            return ATTTHTTPSERVER_SUC, rsp_data
        
        else:
            #消息执行失败
            response_message_data=u"%s" % rsp_data
            log.debug_info(response_message_data)
            
            if RESPONSE_REQUEST_RUN_FAIL==rsp_type:
                
                #停止服务进程
                self.stop_httpservet()

            elif RESPONSE_REQUEST_QUIT_PROCESS_FAIL==rsp_type:
                
                #强制关闭进程
                log.debug_info(u"message_status MESSAGE_ID_ERROR, kill process object")
                os.kill(self.pro_server_object_pid, 9)

            #返回错误消息
            return ATTTHTTPSERVER_FAIL,response_message_data
        
        
    def _exception_response(self, method_name, error_info):
        
        log.debug_info(type(error_info))
        
        if isinstance(error_info,str):
            error_string=error_info
            log.debug_info(error_string)
            
        else:
            #消息体错误
            try:
                error_string=error_info.message
                log.debug_info(error_string)
                
            except Exception, e:
                error_string=u"Unknown Error"
                
        error_string=error_info
        return ATTTHTTPSERVER_FAIL, error_string
            


#================进程通信管理模块 START==========================

            
#运行HTTP服务模块进程接口
class HttpServerPIPEProcess(BasePIPEProcess):
    
    def __init__(self,
                 pipe_conn,
                 in_serve_listen_address,
                 in_serve_listen_port,
                 in_home_workspace_dir):
        
        log.debug_info(u"HttpServerPIPEProcess init()\n")
        
        #初始化基础对象类
        BasePIPEProcess.__init__(self,
                                pipe_conn,
                                in_serve_listen_address,
                                in_serve_listen_port,
                                in_home_workspace_dir)
        
    def run(self):
        """
        运行接口
        """
        log.debug_info(u"HttpServerPIPEProcess runing ......\n")
        
        #启动通讯管道数据监听线程
        self.start_listen_pipe_thread()
        
        serve_modle_object_handle=None
        
        global g_import_twhttserver_suc_flag
        if g_import_twhttserver_suc_flag:
            
            #创建服务对象
            try:
                serve_modle_object_handle =MyHttpServer(self.pipe_conn,
                                                        self.serve_listen_address,
                                                        self.serve_listen_port,
                                                        self.home_workspace_dir)
            except Exception,e:
                error_info=e
                
                log.debug_info(error_info)
            
        if not serve_modle_object_handle:
            pass
        
        else:
            #启动服务模块
            try:
               
                self.serve_modle_object_handle=serve_modle_object_handle
                self.serve_modle_object_handle.start_httpservet()

            except Exception,e:
                log.debug_info(u"============================================")
                log.debug_info(type(e))
                error_info=""

                if isinstance(e,RuntimeError):
                    error_info=e.message
                    if isinstance(error_info,unicode):
                        #error_info=error_info.encode("utf8")
                        pass
                    else:
                        error_info=error_info.decode(sys.getfilesystemencoding())#.encode("utf8")

                log.debug_info(type(error_info))
                log.debug_info(error_info)
                
                log.debug_info(u"============================================")


        #等待退出消息
        while not self.listen_pipe_thread_handle.get_listen_thread_exit_flag():
            time.sleep(0.25)
            
        log.debug_info(u"HttpServerPIPEProcess run exit\n")

  
#================进程通信管理模块 END============================




def test2():
    
    #创建服务对象
    try:
        serve_modle_object_handle =MyHttpServer(None,
                                                "172.16.28.59",
                                                "8000",
                                                "e://httpserver//")
        
        serve_modle_object_handle.open_check_authorization()
        serve_modle_object_handle.register_user_account("wangjun-httpserver","123456")
        
        serve_modle_object_handle.start_httpservet()
        
    except Exception,e:
        #error_info=u"%s" % str(e)
        #log.debug_info(error_info)
        log.debug_info(u"============================================")
        log.debug_info(type(e))
        error_info="*****************************"
        if isinstance(e,RuntimeError):
            error_info=e.message
            if isinstance(error_info,unicode):
                error_info=error_info.encode("utf8")
            else:
                #s.decode('utf-8').encode('gb2312')
                error_info=error_info.decode(sys.getfilesystemencoding()).encode("utf8")
                        

def test_httpftpserver():
    """
    测试接口
    """
    test_flag=True
    att_https_test_obj=None
    
    while test_flag:
        test_flag=False
        
        if att_https_test_obj:
            #停止HTTP服务
            att_https_test_obj.stop_httpservet()
            if not rc_status:
                log.debug_info(rc_data)
                break
            
            else:
                log.debug_info(u"stop_httpservet suc")
          
        log.debug_info(u"pid=%d" % os.getpid())
        
        #初始化对象
        att_https_test_obj=ATTTWHttpServer(8080)
        rc_status,rc_data=att_https_test_obj.init_httpservet("172.16.28.59", "e:\\httpserver\\")
        if not rc_status:
            log.debug_info(rc_data)
            break

        log.debug_info(u"init_httpservet suc ")

        #启动HTTP服务
        rc_status,rc_data=att_https_test_obj.start_httpservet()
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        log.debug_info(u"start_httpservet suc")

        """
        #=====================================================
        #打开用户权限验证
        rc_status,rc_data=att_https_test_obj.open_check_authorization()
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        time.sleep(20)
        
        
        #注册用户
        rc_status,rc_data=att_https_test_obj.register_user_account("wangjun-httpserver","123456")
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        
        time.sleep(20)
        """
        
        #设置状态码的值
        status_code="405"
        rc_status,rc_data=att_https_test_obj.set_response_status_code(status_code)
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        """
        #开启状态码响应模块
        rc_status,rc_data=att_https_test_obj.open_response_status_code()
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        time.sleep(20)
    
        #关闭状态码响应模块
        rc_status,rc_data=att_https_test_obj.close_response_status_code()
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        time.sleep(20)
        
        
        #注销用户
        rc_status,rc_data=att_https_test_obj.unregister_user_account("wangjun-httpserver")
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        time.sleep(20)
        
        #关闭用户权限验证
        rc_status,rc_data=att_https_test_obj.close_check_authorization()
        if not rc_status:
            log.debug_info(rc_data)
            break
        
        time.sleep(20)
        #=====================================================
        
        break
    """
    
    log.debug_info(u"wait stop_httpservet")
    time.sleep(3)


    #停止HTTP服务
    att_https_test_obj.stop_httpservet()
    if not rc_status:
        log.debug_info(rc_data)
        
    else:    
        log.debug_info(u"stop_httpservet suc")

    
# this only runs if the module was *not* imported
if __name__ == "__main__":
    #test2()
    test_httpftpserver()

    nExit = raw_input("Press any key to end...")

