# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: MyHttpServer
#  class:
#       继承自BasePIPEChildControl类，实现了对MyHttpFactory功能封装，完成对ATTTWHttpServer功能支撑
#
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
#         wangjun   2013.11.28   修改启动服务器接口，当监听异常时，添加停止reactor的调用
# ***************************************************************************


from twisted.internet import reactor
from twisted.cred import portal, credentials
from twisted.internet import defer
from twisted.internet.error import CannotListenError

#user interface
from MyHttpFactory import MyHttpFactory
from MyCheck import TestRealm, PasswordDictChecker, INamedUserAvatar
from MyRenderPage import MyRenderPage

#加载string语句定义
import MyChars

#LOG模块
from MyEvent import ProcessOutLog as log


#加载进程通讯基础类
from BasePIPEProcess import BasePIPEChildControl

#导入消息体中用的的常量定义
from BasePIPEProcess import RESPONSE
from BasePIPEProcess import MESSAGE_ID_SUC, MESSAGE_ID_ERROR, MESSAGE_ID_QUIT


#具体接口消息ID
from MyEvent import MESSAGE_ID_REGISTER_USER_ACCOUNT,\
                    MESSAGE_ID_UNREGISTER_USER_ACCOUNT,\
                    MESSAGE_ID_OPEN_CHECK_AUTHORIZATION,\
                    MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION,\
                    MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE,\
                    MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE,\
                    MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER,\
                    MESSAGE_ID_SET_AUTH_TYPE,\
                    MESSAGE_ID_SET_UPLOAD_TYPE



class MyHttpServer(BasePIPEChildControl):
    
    def __init__(self,pipe_conn,in_address,in_port,in_home_workspace_dir):
        """
        初始化Twisted Http Server
        """
        log.debug_info(u"init")
        
        BasePIPEChildControl.__init__(self, pipe_conn)
        
        
        #开启和关闭用户权限验证标示
        self.enable_check_authorization_flag=False
        
        #开启和关闭状态码响应模块标示
        self.enable_response_status_code_flag=False
        
        #保存指定响应状态码
        self.response_status_code_data=200

        #-----------------------------------------------------
        #add by wangjun 20131119
        #设置客户端认证模式Basic/Digest
        self.authorization_type='Basic'
        
        #设置客户端上传模式POST/PUT/BOTH
        self.client_upload_type_string='BOTH'
        #-----------------------------------------------------
        
        #保存用户账户信息
        self.users = {}
        self.passwords = {}

        self.http_factory=None
            
        #监听的端口号
        self.http_address=in_address
        self.http_port=int(in_port)
            
        #权限控制
        self.http_portal = portal.Portal(TestRealm(self.users))
        self.http_portal.registerChecker(PasswordDictChecker(self.passwords))
            
        #服务工厂
        #set portal
        self.http_factory = MyHttpFactory()
        self.http_factory.portal = self.http_portal

        #set site
        render_page_handle=MyRenderPage(in_home_workspace_dir)
        self.http_factory.site=render_page_handle

        #保存对象句柄到MyHttpFactory对象中
        self.http_factory.set_callback_app_handle(self)
      
        
    def __del__(self):
        #销毁基类
        BasePIPEChildControl.__del__(self)
        
        
    def start_httpservet(self):
        """
        启动Twisted Http Server
        """
        if not self.http_factory:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_FACTORY_OBJECT_HANDLE_NOT_INIT)
            log.debug_info(rsp_string_data)
            raise RuntimeError(rsp_string_data) #将异常抛到上层接口
        
        log.debug_info(u"start_httpservet start")
        
        try:                  
            log.debug_info(u"reactor.listenTCP start")
            
            #设置监听对象
            reactor.listenTCP(self.http_port, self.http_factory, interface=self.http_address)
        
        except Exception, e: #reactor.listenTCP mthod
            
            #add by wangjun 20131127
            #停止SERVER监听网络
            reactor.stop
            
            if isinstance(e,CannotListenError):
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_CANNOT_LISTEN_THIS_PORT) % (self.http_address,self.http_port)
            else:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_LISTEN_TCP_ERROR)

            log.debug_info("-------------------------------------")
            log.debug_info(rsp_string_data)
            log.debug_info("-------------------------------------")
            raise RuntimeError(rsp_string_data) #将异常抛到上层接口
        
        try:
            log.debug_info(u"reactor.run start")
            
            #启动SERVER监听网络
            reactor.run()

        except Exception, e: #reactor.run method
            #log.debug_info(e)
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_RUN_ERROR)
            log.debug_info(rsp_string_data)
            raise RuntimeError(rsp_string_data) #将异常抛到上层接口
            
            
    def stop_httpservet(self):
        """
        停止Twisted Http Server
        """
        try:
            log.debug_info(u"reactor.stop start")
            
            #停止SERVER监听网络
            reactor.callFromThread(reactor.stop)
            
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_STOP_SUC)
            log.debug_info(rsp_string_data)
            return True, rsp_string_data
        
        except Exception, e: #stop_httpservet method
            #log.debug_info(e)
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REACTOR_STOP_ERROR)
            log.debug_info(rsp_string_data)
            return False, rsp_string_data


    def dispatch_request_message_data(self,in_message_id,in_message_data):
        """
        重载基类接口，将父进程管道连接下发的请求分发到具体处理模块
        """
        log.debug_info(u"dispatch_request_message_data message_id=%s" % in_message_id)
        
        try: 
            #退出消息
            if MESSAGE_ID_QUIT == in_message_id:
                rc_status,rc_data=self.stop_httpservet()
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_STOP_SUC)
                log.debug_info(response_data)
                    
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_STOP_FAIL) % rc_data
                    log.debug_info(response_data)

                self.response_run_methond_data(MESSAGE_ID_QUIT, response_status, response_data)
                
            #创建账户消息
            elif MESSAGE_ID_REGISTER_USER_ACCOUNT == in_message_id:
                rc_status=self.register_user_account(*in_message_data)

                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_FAIL)
                    log.debug_info(response_data)
                
                self.response_run_methond_data(MESSAGE_ID_REGISTER_USER_ACCOUNT, response_status, response_data)
                
            #注销账户消息
            elif MESSAGE_ID_UNREGISTER_USER_ACCOUNT == in_message_id:
                rc_status=self.unregister_user_account(in_message_data)
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_SUC)
                log.debug_info(response_data)
                    
                if not rc_status:
                    #response_status=MESSAGE_ID_ERROR
                    #response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_FAIL)
                    response_status=MESSAGE_ID_SUC
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_UNREGISTER_NOTFOUND_USER_ACCOUNT)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_UNREGISTER_USER_ACCOUNT, response_status, response_data)
                
            #打开用户权限验证模块
            elif MESSAGE_ID_OPEN_CHECK_AUTHORIZATION == in_message_id:
                rc_status=self.open_check_authorization()
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_FALSE)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_OPEN_CHECK_AUTHORIZATION, response_status, response_data)
            
            #关闭用户权限验证模块    
            elif MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION == in_message_id:
                rc_status=self.close_check_authorization()
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_FAIL)
                    log.debug_info(response_data)
                
                self.response_run_methond_data(MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION, response_status, response_data)
            
            #打开响应状态码模块    
            elif MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE == in_message_id:
                rc_status=self.open_response_status_code()
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_FAIL)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE, response_status, response_data)
                
            #关闭响应状态码模块    
            elif MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE == in_message_id:
                rc_status=self.close_response_status_code()

                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_FAIL)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE, response_status, response_data)
    
            #设置状态码的值  
            elif MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER == in_message_id:
                rc_status=self.set_response_status_code(in_message_data)
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_SUC)
                log.debug_info(response_data)

                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_FAIL)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER, response_status, response_data)

            #add by wangjun 20131119
            #设置用户权限验证模式    
            elif MESSAGE_ID_SET_AUTH_TYPE == in_message_id:
                rc_status=self.set_client_authorization_type(in_message_data)
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_AUTH_TYPE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_AUTH_TYPE_FAIL)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_SET_AUTH_TYPE, response_status, response_data)
            
            #设置上传类型模式   
            elif MESSAGE_ID_SET_UPLOAD_TYPE == in_message_id:
                rc_status=self.set_client_upload_type(in_message_data)
                
                response_status=MESSAGE_ID_SUC
                response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_UPLOAD_TYPE_SUC)
                log.debug_info(response_data)
                
                if not rc_status:
                    response_status=MESSAGE_ID_ERROR
                    response_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_SET_UPLOAD_TYPE_FAIL)
                    log.debug_info(response_data)
                    
                self.response_run_methond_data(MESSAGE_ID_SET_UPLOAD_TYPE, response_status, response_data)
                
            else:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_NOT_FOUND_MATCH_INTERFACE)
                log.debug_info(rsp_string_data)
                self.response_run_methond_data(in_message_id, MESSAGE_ID_ERROR, rsp_string_data)
            
        except Exception, e: #dispatch_request_message_data method
            #log.debug_info(e)
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_DATA_FAIL)
            log.debug_info(rsp_string_data)
            self.response_run_methond_data(in_message_id, MESSAGE_ID_ERROR, rsp_string_data)


    def register_user_account(self,uname,upassword):
        """
        创建用户账户信息
        """
        if len(uname)==0:
            return False

        if self.users.has_key(uname):
            #账户已经存在，不再创建
            return False
        
        else:
            self.users[uname]=uname
            self.passwords[uname]=upassword
            
        self.http_portal = portal.Portal(TestRealm(self.users))
        self.http_portal.registerChecker(PasswordDictChecker(self.passwords))
        self.http_factory.portal = self.http_portal
        
        return True
            
    
    def unregister_user_account(self,uname):
        """
        删除用户账户信息
        """
        if not self.users.has_key(uname):
            #账户不存在
            return False
        
        else:
            #账户已经存在，删除键值
            del(self.users[uname])
            del(self.passwords[uname])
            
        self.http_portal = portal.Portal(TestRealm(self.users))
        self.http_portal.registerChecker(PasswordDictChecker(self.passwords))
        self.http_factory.portal = self.http_portal
        
        return True

    
    def open_check_authorization(self):
        """
        开启用户权限验证
        """
        self.enable_check_authorization_flag=True
        return True
    
    
    def close_check_authorization(self):
        """
        关闭用户权限验证
        """
        self.enable_check_authorization_flag=False
        return True
    
    
    def set_response_status_code(self, status_code):
        """
        设置状态码的值
        """
        if status_code.isdigit():

            if int(status_code)<100 or int(status_code)>600:
                return False
            
            self.response_status_code_data=int(status_code)
            log.debug_info(u"set status code=%d" % self.response_status_code_data)
            return True
        else:
            return False


    def open_response_status_code(self):
        """
        开启状态码响应模块
        """
        self.enable_response_status_code_flag=True
        log.debug_info(u"response status code status=%s" % self.enable_response_status_code_flag)
        return True
    
    
    def close_response_status_code(self):
        """
        关闭状态码响应模块
        """
        self.enable_response_status_code_flag=False
        log.debug_info(u"response status code status=%s" % self.enable_response_status_code_flag)
        return True


    def get_enable_check_authorization_flag(self):
        """
        返回用户权限验证功能是否开启标志位
        """
        return self.enable_check_authorization_flag
    
    
    def get_enable_response_status_code_flag(self):
        """
        返回状态码响应模块功能是否开启标志位
        """
        #log.debug_info(u"get enable response status code flag=%s" % self.enable_response_status_code_flag)
        return self.enable_response_status_code_flag

        
    def get_response_status_code(self):
        """
        获取状态码的值
        """
        #log.debug_info(u"get status code=%d" % self.response_status_code_data)
        return int(self.response_status_code_data)
    
    
    #-------------------------------------------------
    #add by wangjun 20131118
    def set_client_authorization_type(self, type_string):
        """
        设置客户端认证模式Basic/Digest
        """
        #强制转换为大写来比较值
        type_string=type_string.upper()

        if type_string == 'BASIC':
            self.authorization_type='Basic'
            
        elif type_string == 'DIGEST':
            self.authorization_type = 'Digest'
        
        else:
            #设置认证模式失败
            return False
        
        #设置认证模式成功
        return True 
            
            
    def get_client_authorization_type(self):
        """
        获取客户端认证模式Basic/Digest
        """
        return self.authorization_type
            
            
    def set_client_upload_type(self, type_string):
        """
        设置客户端上传模式POST/PUT/BOTH
        """
        
        #强制转换为大写来比较值
        type_string=type_string.upper()
        
        if type_string == "POST":
            self.client_upload_type_string='POST'
        elif type_string == "PUT":
            self.client_upload_type_string='PUT'
        elif type_string == "BOTH":
            self.client_upload_type_string='BOTH'
        else:
            #设置上传模式失败
            return False
        
        #设置上传模式成功
        return True
    
    
    def get_client_upload_type(self):
        """
        获取客户端上传模式POST/PUT/BOTH
        """
        return self.client_upload_type_string


    def get_client_register_password(self,username):
        """
        检查用户名是否注册过，如果注册过则取出对应的密码数据
        """
        if not username in self.passwords.keys():
            return False, None
        
        return True, self.passwords.get(username)
    
    
    #-------------------------------------------------
    
    
    
    
def test1():
    tw_httpserver_object=MyHttpServer(None, "172.16.28.59", 8000, "e:\\httpserver") #"e:\\httpserver\\"
    tw_httpserver_object.start_httpservet()


if __name__ == "__main__":   
    test1()
    
    nExit = raw_input("Press any key to end...")
