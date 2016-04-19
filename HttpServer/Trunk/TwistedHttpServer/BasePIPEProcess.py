# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: BasePIPEProcess
#  class:
#       提供了父子进程通过管道的方式，进行通讯的一种实现方式。
#       BasePIPEProcess类：子进程基础类，它是运行提供服务对象实例的进程接口
#       BasePIPEParentControl类：父进程对象基础类，它是关键字封装底层实现库继承的类，封装了发送请求消息函数接口，接收子进程请求处理结果消息函数接口。  
#       BasePIPEChildControl类：子进程中提供服务对象实例的基础类，它封装了分发消息函数接口，发送响应消息接口。
#
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
# ***************************************************************************

import time
import multiprocessing
import threading
import subprocess
import sys

#=================================================
#管道消息通讯接口

#消息格式:[请求类型，消息ID，数据参数]
REQUEST_MESSAGE_FORMAT_ITEM_COUNT=3

#消息格式:[响应类型，消息ID，成功/失败类型，执行结果数据]
RESPONSE_MESSAGE_FORMAT_ITEM_COUNT=4

#请求类型
REQUEST="REQUEST"
RESPONSE="RESPONSE"

#常用消息错误和退出
MESSAGE_ID_SUC="MESSAGE_ID_SUC"
MESSAGE_ID_ERROR="MESSAGE_ID_ERROR"
MESSAGE_ID_QUIT="MESSAGE_ID_QUIT"

#启动服务状态
PROCESS_START_STATUS_INIT=-1
PROCESS_START_STATUS_FAIL=0
PROCESS_START_STATUS_SUC=1


#共享字典变量KEY值定义
PROCESS_SHARE_RUN_STATUS="STATUS"
PROCESS_SHARE_RUN_RESPONSE="RESPONSE"


from MyEvent import MESSAGE_ID_UNKNOWN
#=================================================


#=================================================
#打印信息语言类型
local_lang_type=1

#字符串消息
STRING_DISPATH_REQUEST_MESSAGE_HANDLE_NOT_INIT=[u"Process object not init",u"HTTP服务器对象没有初始化"]
STRING_DISPATH_REQUEST_MESSAGE_HANDLE_NOT_FOUND_RECV_ACTION_FUNCTION=[u"Process object not found dispatch dispatch_request_message_data() function",u"HTTP服务器对象没有找到接收消息请求函数入口"]
STRING_DISPATH_REQUEST_MESSAGE_MESSAGE_TYPE_ERROR=[u"messgae type is not match 'REQUEST'",u"读取到的请求节点消息数据类型不是'REQUEST'"]
STRING_DISPATH_REQUEST_DATA_TYPE_ERROR=[u"date type is not match list",u"读取到的请求数据类型不是LIST类型"]

#=================================================


#=================================================
#解析子进程返回数据处理结果

#请求处理完成结果
RECV_PIPE_HANDLE_NOT_INIT="RECV_PIPE_HANDLE_NOT_INIT"
RESPONSE_MESSAGE_TYPE_ERROR="RESPONSE_MESSAGE_TYPE_ERROR"
RESPONSE_DATA_TYPE_ERROR="RESPONSE_DATA_TYPE_ERROR"
RESPONSE_REQUEST_RUN_FAIL="RESPONSE_REQUEST_RUN_FAIL"
RESPONSE_REQUEST_QUIT_PROCESS_FAIL="RESPONSE_REQUEST_QUIT_PROCESS_FAIL"

RESPONSE_REQUEST_RUN_SUC="RESPONSE_REQUEST_RUN_SUC"
#=================================================



#LOG模块
from MyEvent import ProcessOutLog as log



#监听父进程发送的管道消息
class _ListenPipe(threading.Thread):
    
    def __init__(self,pipe_conn, parent_handle):
        log.debug_info(u"_ListenPipe init()\n")
        
        threading.Thread.__init__(self)
        self.pipe_conn=pipe_conn
        self.parent_handle=parent_handle
        self.exit_listen_pipe_thread_flag=False
        
        
    def get_listen_thread_exit_flag(self):
        return self.exit_listen_pipe_thread_flag
    
    
    def run(self):
        """
        监听父进程发送的管道消息
        """
        while not self.exit_listen_pipe_thread_flag:
            
            log.debug_info(u"_ListenPipe runing ......")

            try:
                rc=self.recv_pipe_data(self.pipe_conn)
                if not rc:
                    self.exit_listen_pipe_thread_flag=True
                    break
                
                time.sleep(0.25)
                
            except Exception, e:
                error_info=u"recv_pipe_data error:%s" % e.message
                log.debug_info(error_info)
                self.exit_listen_pipe_thread()
            
        log.debug_info(u"_ListenPipe exit\n")
        
        
    def exit_listen_pipe_thread(self):
        log.debug_info(u"_ListenPipe exit_listen\n")
        
        self.exit_listen_pipe_thread_flag=True
            
        
    def recv_pipe_data(self,conn):
        """
        收取消息
        """
        #判断通讯管道句柄
        if not conn:
            return False
        
        #收取pipe中的消息数据
        log.debug_info(u"_ListenPipe recv_pipe_data begin...")
        
        try:
            #接收管道中的消息
            r_data=conn.recv()
            log.debug_info(r_data)
            
        except Exception, e:
            error_info=u"recv_pipe_data error:%s" % e.message
            log.debug_info(error_info)
            conn.send([RESPONSE, MESSAGE_ID_UNKNOWN, MESSAGE_ID_ERROR, error_info])
            
            #抛出异常到调用的函数接口
            raise RuntimeError(error_info)
        
        if (isinstance(r_data, list) and
            REQUEST_MESSAGE_FORMAT_ITEM_COUNT==len(r_data)):
            message_type=r_data[0]
            message_id=r_data[local_lang_type]
            message_data=r_data[2]
            
            if REQUEST!=message_type:
                conn.send([RESPONSE, message_id, MESSAGE_ID_ERROR, STRING_DISPATH_REQUEST_MESSAGE_MESSAGE_TYPE_ERROR[local_lang_type] ])
                return True
            
            #分发消息
            self.parent_handle.dispatch_request_message_data(message_id,message_data)

        else:
            conn.send([RESPONSE, message_id, MESSAGE_ID_ERROR, STRING_DISPATH_REQUEST_DATA_TYPE_ERROR[local_lang_type]])

        return True



#运行提供服务的模块进程接口
class BasePIPEProcess(multiprocessing.Process):
    
    def __init__(self,pipe_conn,
                 in_serve_listen_address,
                 in_serve_listen_port,
                 in_home_workspace_dir):
        
        log.debug_info(u"BasePIPEProcess init()\n")
        
        #初始化基类
        multiprocessing.Process.__init__(self)
        
        #服务对象句柄
        self.serve_modle_object_handle=None
        
        #监听管道消息线程句柄
        self.listen_pipe_thread_handle=None
        
        #与父进程通信管道
        self.pipe_conn=pipe_conn

        #监听地址
        self.serve_listen_address=in_serve_listen_address
        self.serve_listen_port=in_serve_listen_port
        self.home_workspace_dir=in_home_workspace_dir
    
    def get_http_server_address(self):
        return self.serve_listen_address, self.serve_listen_port
        
    def start_listen_pipe_thread(self):
        """
        启动处理管道消息的子线程
        """
        log.debug_info(u"BasePIPEProcess start_listen_pipe_thread\n")
        
        if not self.listen_pipe_thread_handle:
            self.listen_pipe_thread_handle=_ListenPipe(self.pipe_conn, self)
            self.listen_pipe_thread_handle.setDaemon(True)
            self.listen_pipe_thread_handle.start()
        
        
    def stop_listen_pipe_thread(self):
        """
        停止处理管道消息的子线程
        """ 
        log.debug_info(u"BasePIPEProcess stop_listen_pipe_thread\n")

        if self.listen_pipe_thread_handle:
            self.listen_pipe_thread_handle.exit_listen_pipe_thread()
            #self.listen_pipe_thread_handle.join()
            
    
    def dispatch_request_message_data(self,in_message_id,in_message_data):
        """
        分发消息
        """
        log.debug_info(u"BasePIPEProcess dispatch_request_message_data")
        
        if self.serve_modle_object_handle:
            if hasattr(self.serve_modle_object_handle,'dispatch_request_message_data'):
                
                #下发具体消息请求
                self.serve_modle_object_handle.dispatch_request_message_data(in_message_id,in_message_data)
                
            else:
                #HTTP服务器对象没有找到接收消息请求函数入口
                response_data=STRING_DISPATH_REQUEST_MESSAGE_HANDLE_NOT_INIT[local_lang_type]
                log.debug_info(response_data)
                self.pipe_conn.send([RESPONSE, in_message_id, MESSAGE_ID_ERROR, response_data])
        else:
            
            #HTTP服务器对象没有初始化
            response_data=STRING_DISPATH_REQUEST_MESSAGE_HANDLE_NOT_FOUND_RECV_ACTION_FUNCTION[local_lang_type]
            log.debug_info(response_data)
            self.pipe_conn.send([RESPONSE, in_message_id, MESSAGE_ID_ERROR, response_data])
             
             
        #退出消息监听线程
        if MESSAGE_ID_QUIT == in_message_id:
            self.stop_listen_pipe_thread()



#父进程对象基础类
class BasePIPEParentControl():
    
    def __init__(self):
        """
        初始化
        """
        log.debug_info(u"BasePIPEParentControl init()\n")

        #初始化管道通讯句柄
        self.parent_conn,self.child_conn = multiprocessing.Pipe()  
    
            
    def __del__(self):
        """
        析构
        """
        log.debug_info(u"BasePIPEParentControl del()\n")
        
        try:
            log.debug_info(u"BasePIPEParentControl close pipe handle")
            
            self.parent_conn.close()
            self.child_conn.close()

        except Exception, e:
            pass

        
    def recv_child_pipe_response_message_data(self):
        """
        处理管道中的消息
        """
        log.debug_info(u"BasePIPEParentControl recv_child_pipe_response_message_data()\n")
        
        if not self.parent_conn:
            log.debug_info(u"%s" % RECV_PIPE_HANDLE_NOT_INIT)
            error_info=u"HttpServer process recv pipe handle not init."
            return False,RECV_PIPE_HANDLE_NOT_INIT, error_info
        
        log.debug_info(u"_recv_message_response_data running...")
        
        try:
            #接收管道中的消息
            r_data=self.parent_conn.recv()
            
        except Exception, e:
            error_info=u"recv_pipe_data error:%s" % e.message
            log.debug_info(error_info)
            
            if message_id != MESSAGE_ID_QUIT:
                log.debug_info(u"%s" % RESPONSE_REQUEST_RUN_FAIL)
                return False, RESPONSE_REQUEST_RUN_FAIL, error_info
                    
            else:
                log.debug_info(u"%s" % RESPONSE_REQUEST_QUIT_PROCESS_FAIL)
                return False, RESPONSE_REQUEST_QUIT_PROCESS_FAIL, error_info  
                
        #解析消息体
        if (isinstance(r_data, list) and
            RESPONSE_MESSAGE_FORMAT_ITEM_COUNT==len(r_data)):
            message_type=r_data[0]
            message_id=r_data[1]
            message_status=r_data[2]
            message_data=r_data[3]
            
            log.debug_info(u"message_type=%s" % message_type)
            log.debug_info(u"message_status=%s" % message_status)
            log.debug_info(u"message_id=%s" % message_id)
            log.debug_info(u"message_data=%s" % (message_data))
            
            #消息类型错误
            if RESPONSE!=message_type:
                log.debug_info(u"%s" % RESPONSE_MESSAGE_TYPE_ERROR)
                return False, RESPONSE_MESSAGE_TYPE_ERROR, message_data
            
            #消息执行失败
            if MESSAGE_ID_ERROR==message_status:
                
                if message_id != MESSAGE_ID_QUIT:
                    
                    #请求执行失败
                    log.debug_info(u"%s" % RESPONSE_REQUEST_RUN_FAIL)
                    return False, RESPONSE_REQUEST_RUN_FAIL, message_data
                    
                else:
                    #请求退出子进程失败
                    log.debug_info(u"%s" % RESPONSE_REQUEST_QUIT_PROCESS_FAIL)
                    return False, RESPONSE_REQUEST_QUIT_PROCESS_FAIL, message_data
                
            else:
                #消息执行正常
                return True, RESPONSE_REQUEST_RUN_SUC, message_data
            
        else:
            #消息体错误
            log.debug_info(u"%s" % RESPONSE_DATA_TYPE_ERROR)
            return False, RESPONSE_DATA_TYPE_ERROR, message_data
        


#子进程中运行的对象实例基础类，封装了分发消息函数接口
class BasePIPEChildControl():
    
    def __init__(self,pipe_conn):
        """
        初始化
        """
        log.debug_info(u"BasePIPEChildControl init()\n")

        #保存通讯的管道句柄
        self.pipe_conn=pipe_conn


    def __del__(self):
        """
        析构
        """
        log.debug_info(u"BasePIPEChildControl del()\n")

        
    def dispatch_request_message_data(self,in_message_id,in_message_data):
        """
        将父进程管道连接下发的请求分发到具体处理模块
        """
        log.debug_info(u"BasePIPEChildControl dispatch_request_message_data message_id=%s" % in_message_id)
        
        #TODO
        self.response_run_methond_data(MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER, MESSAGE_ID_ERROR, u'Dispatch request message function not interface is not implemented.')
        
            
    def response_run_methond_data(self,in_message_id, in_response_status, in_message_data):
        """
        给父进程管道连接回响应信息
        """
        log.debug_info(u"BasePIPEChildControl response_run_methond_data start")
        
        if self.pipe_conn:
            log.debug_info(u"Pipe send response data success")
            
            #发送正常处理数据结果
            self.pipe_conn.send([RESPONSE, in_message_id, in_response_status, in_message_data])
            return True
        
        else:
            #管道句柄数据为空，打印错误信息
            log.debug_info(u"Pipe send response data fail")
            return False
    

