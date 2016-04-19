# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: MyHttpFactory
#  class:
#       封装了基于twidted web框架httpserver实现，包括正常http请求处理，客户端请求用户权限验证，对指定状态码响应等。
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
#         wangjun   2013.11.19   修复客户端权限认证响应消息头错误并且实现Basic/Digest认证
# ***************************************************************************


from twisted.web import http
from twisted.cred import portal, credentials
from twisted.internet import defer

#user interface
from MyCheck import TestRealm, PasswordDictChecker, INamedUserAvatar
#from MyRender import RenderPage, PageMenagement
from MyRenderPage import MyRenderPage

import MyChars

from MyEvent import ProcessOutLog as log

CALLBACK_HANDLE_NOTINIT="CALLBACK_HANDLE_NOTINIT"
CALLBACK_HANDLE_INIT="CALLBACK_HANDLE_INIT"

CONNECTION_KEEP_CLOSE='Close'


#客户端权限认证模块控制
from hashlib import md5
import time
import DigestAuthorization

CFG_AUTH_RELM_VALUE = 'ATT'


class MyRequestHandler(http.Request):
    

    def process(self):
        """
        处理来自客户端的连接请求
        """
        try:
            
            #获取客户端HTTP版本信息
            http_proto_version=self.clientproto
            log.debug_info(http_proto_version)
            
            #解析Connection头数据
            connection_type=self.getHeader('Connection')
            if 'HTTP/1.1' == http_proto_version:
                #主动关闭连接是，在响应头中设置close连接属性
                if (connection_type and CONNECTION_KEEP_CLOSE.lower() == connection_type.lower()):
                    self.setHeader('Connection', CONNECTION_KEEP_CLOSE)

            #获取用户权限验证是否打开
            temp_check_authorization_flag=self._get_check_authorization_flag()
            self.__enable_check_authorization_status=temp_check_authorization_flag
            
            if self.__enable_check_authorization_status:

                #权限认证
                self.process_authorization()
                
            else:
                
                #处理客户端具体数据请求
                self.process_dispath_request()
                
        except Exception,e:
            #服务器内部错误
            self._internal_server_error(e)

        finally:
            if 'HTTP/1.0' == http_proto_version:
                #1.0协议默认断开连接
                self.transport.loseConnection()
                
            elif 'HTTP/1.1' == http_proto_version:
                #1.1协议如果是Close属性，则断开连接
                if (connection_type and CONNECTION_KEEP_CLOSE.lower() == connection_type.lower()):
                    self.transport.loseConnection()


    def process_authorization(self):
        """
        进行权限验证
        """
        
        #获取客户端请求认证头数据
        authorization_data=self.getHeader('authorization')
        
        #获取服务器设置的默认认证模式
        rc_status, temp_cfg_client_authorization_type=self._get_client_authorization_string()
        
        #识别认证类型状态，
        # ---- 0是初始化状态，表示没有找到认证消息头，
        # ---- -1表示不识别类型，
        # ---- -2表示识别类型不匹配，
        # ---- 1表示识别类型成功
        temp_check_authorization_type_state=0
        
        if authorization_data:

            #读取客户端请求消息认证头认证类型数据
            temp_request_authorization_type = None

            if 0 == authorization_data.find('Digest'):
                temp_request_authorization_type='Digest'
                
            elif 0 == authorization_data.find('Basic'):
                temp_request_authorization_type='Basic'

            if not temp_request_authorization_type:
                
                #不识别认证类型
                temp_check_authorization_type_state=-1
                
            else:
                
                #配置的认证类型与客户端请求认证类型相同
                if (temp_request_authorization_type == temp_cfg_client_authorization_type):
                                    
                    #识别类型成功
                    temp_check_authorization_type_state=1
                    
                    #'Digest'认证
                    if ('Digest' == temp_request_authorization_type):
                        self.process_authorization_digest(authorization_data)
                    
                    #Basic认证    
                    else:
                        self.process_authorization_basic()
                    
                    return
                
                else:
                    #不匹配认证类型
                    temp_check_authorization_type_state=-2
                    
            
        #认证不成功，构造认证失败的消息给客户端响应
        if 1 != temp_check_authorization_type_state:
            
            rsp_string_data='401 Unauthorized'
            
            #未找到验证头数据
            if 0 == temp_check_authorization_type_state:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_401_ERROR)

            #不识别认证类型
            elif -1 == temp_check_authorization_type_state:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_DOES_NOT_RECOGNIZE_AUTH_TYPE)
            
            #不匹配认证类型    
            else:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_AUTH_TYPE_IS_NOT_CONFIGURED_MODE)
                
            #回响应数据给客户端请求
            log.debug_info(rsp_string_data)
            
            #获取返回数据长度
            rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))
                
            #设置响应消息常规头数据
            self._construct_response_header(http.UNAUTHORIZED,"text/html; charset=utf-8",str(rsp_string_data_length))
            
            #未授权的, 构建Basic/Digest认证返回信息, 默认为Basic
            if 'Digest'== temp_cfg_client_authorization_type:
                self.setHeader("WWW-Authenticate", self._construct_auth_digest_response())
            else:
                self.setHeader("WWW-Authenticate", self._construct_auth_basic_response())
                    
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()
            
        return
            
            
    def process_authorization_basic(self):
        """
        basic权限验证
        """
        
        #读取用户账户信息
        client_username=self.getUser()
        client_password=self.getPassword()
        
        if client_username:
            log.debug_info(u"%s" % client_username)
            log.debug_info(u"%s" % client_password)
    
            #验证用户权限，如果有权限则处理客户端具体数据请求
            self.basic_authorization_handle_login(client_username, client_password)

        else:
            #未授权的
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_401_ERROR)
            
            #获取返回数据长度
            rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            
            #设置响应消息常规头数据
            self._construct_response_header(http.UNAUTHORIZED,"text/html; charset=utf-8",str(rsp_string_data_length))
            
            #未授权的, 构建Basic认证返回信息
            self.setHeader("WWW-Authenticate", self._construct_auth_basic_response())
            
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()


    def process_authorization_digest(self, authorization_data):
        """
        调用digest权限验证
        """
        
        #保存验证状态，-1表示账户未注册，-2表示密码认证失败
        check_request_digest_authorization_stauts=0
        
        #解析客户端digest认证数据
        request_auth_digest_data_dict=DigestAuthorization.parse_request_digest_authorization_data(authorization_data,
                                                                                                  self.method)
        #print request_auth_digest_data_dict

        #查找用户名是否注册,并返回注册的密码数据
        client_request_username=request_auth_digest_data_dict.get('username')
        rc_status, rc_client_register_password=self._get_digest_authorization_uername_register_password(client_request_username)
        if not rc_status:
            
            #账户未注册
            check_request_digest_authorization_stauts=-1
            
        else:
            #配置约定数据
            cfg_auth_digest_option={}
            cfg_auth_digest_option['username']= client_request_username
            cfg_auth_digest_option['password']= rc_client_register_password
            cfg_auth_digest_option['realm']= CFG_AUTH_RELM_VALUE
            
            #进行客户端digest权限验证
            check_suc_flag=DigestAuthorization.check_digest_authorization_data(cfg_auth_digest_option,
                                                                                request_auth_digest_data_dict)
    
            if check_suc_flag:
                #权限认证通过
                check_request_digest_authorization_stauts=1
                
                #处理客户端具体数据请求
                self.process_dispath_request()
        
            else:
                #密码认证失败
                check_request_digest_authorization_stauts=-2
                
        
        #授权不成功
        if 1 != check_request_digest_authorization_stauts:
            
            if -2 == check_request_digest_authorization_stauts:
                
                #授权不成功
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_401_ERROR)
            
            else:
                #账户未注册
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_CRED_NO_SUCH_USER)

            #获取返回数据长度
            rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            
            #设置响应消息常规头数据
            self._construct_response_header(http.UNAUTHORIZED,"text/html; charset=utf-8",str(rsp_string_data_length))
            
            #未授权的, 构建Digest认证返回信息
            self.setHeader("WWW-Authenticate", self._construct_auth_digest_response())
            
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()

    
    def _construct_auth_basic_response(self):
        """
        构建baisc认证返回信息
        """
        realm_value = CFG_AUTH_RELM_VALUE
        header_value = "Basic realm=%s" % realm_value
        return header_value
        
        
    def _construct_auth_digest_response(self):
        """
        构建digest认证返回信息
        Digest认证模式需要通讯双方知道一组共享的口令
        """
        realm_value = CFG_AUTH_RELM_VALUE
        qop = 'auth'
        auth_type = 'Digest'
        nonce = md5("%d:%s" % (time.time(), realm_value)).hexdigest()
        opaque = md5("%d%s" % (time.time(), realm_value)).hexdigest()
            
        header_value='%s realm="%s",nonce="%s",opaque="%s",qop="%s"' % (auth_type,
                                                                        realm_value,
                                                                        nonce,
                                                                        opaque,
                                                                        qop)
        return header_value

       

    #-------------------------------------------------
    #add by wangjun 20131118
    def _get_client_authorization_string(self):
        """
        获取客户端认证模式basic/Digest
        """
        #检查用户回调模块接口是否开放
        if CALLBACK_HANDLE_NOTINIT == self.channel.factory.callback_app_hanlde_init_status:
            return False, None

        #获取TWHttpServer对象句柄
        temp_hanlde=self.channel.factory.callback_app_hanlde
        if not temp_hanlde:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE)
            log.debug_info(rsp_string_data)
            return False, None

        #检查接口是否存在
        if not hasattr(temp_hanlde,"get_client_authorization_type"):
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CLIENT_AUTH_TYPE)
            log.debug_info(rsp_string_data)
            return False, None
   
        #获取客户端认证模式basic/Digest
        temp_client_authorization_type=temp_hanlde.get_client_authorization_type()
        log.debug_info(u"get_client_authorization_type:%s" % temp_client_authorization_type)

        #返回客户端认证模式basic/Digest
        return True, temp_client_authorization_type
    
    
    def _get_client_upload_type_string(self):
        """
        获取客户端上传模式POST/PUT/BOTH
        """
        #检查用户回调模块接口是否开放
        if CALLBACK_HANDLE_NOTINIT == self.channel.factory.callback_app_hanlde_init_status:
            return False, None

        #获取TWHttpServer对象句柄
        temp_hanlde=self.channel.factory.callback_app_hanlde
        if not temp_hanlde:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE)
            log.debug_info(rsp_string_data)
            return False, None

        #检查接口是否存在
        if not hasattr(temp_hanlde,"get_client_upload_type"):
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_AUTH_TYPE)
            log.debug_info(rsp_string_data)
            return False, None

        #获取客户端上传模式POST/PUT/BOTH
        temp_client_upload_type=temp_hanlde.get_client_upload_type()
        log.debug_info(u"get_client_upload_type:%s" % temp_client_upload_type)

        #返回客户端上传模式POST/PUT/BOTH
        return True, temp_client_upload_type


    def _get_digest_authorization_uername_register_password(self,username):
        """
        获取Digest认证中username注册的密码数据
        """
        #检查用户回调模块接口是否开放
        if CALLBACK_HANDLE_NOTINIT == self.channel.factory.callback_app_hanlde_init_status:
            return False, None

        #获取TWHttpServer对象句柄
        temp_hanlde=self.channel.factory.callback_app_hanlde
        if not temp_hanlde:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE)
            log.debug_info(rsp_string_data)
            return False, None

        #检查接口是否存在
        if not hasattr(temp_hanlde,"get_client_register_password"):
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_AUTH_TYPE)
            log.debug_info(rsp_string_data)
            return False, None

        #获取客户端上传模式POST/PUT/BOTH
        rc_status, temp_client_register_password=temp_hanlde.get_client_register_password(username)
        log.debug_info(u"get_client_register_password:%s" % temp_client_register_password)

        #返回客户端上传模式POST/PUT/BOTH
        return rc_status, temp_client_register_password
    #-------------------------------------------------
    
    
    def _get_check_authorization_flag(self):
        """
        获取用户权限验证是否打开状态
        """
        #检查用户回调模块接口是否开放
        if CALLBACK_HANDLE_NOTINIT == self.channel.factory.callback_app_hanlde_init_status:
            return False

        #获取TWHttpServer对象句柄
        temp_hanlde=self.channel.factory.callback_app_hanlde
        if not temp_hanlde:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE)
            log.debug_info(rsp_string_data)
            return False
        
        #检查句柄是否有获取用户权限验证模块接口
        if not hasattr(temp_hanlde,"get_enable_check_authorization_flag"):
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CHECKAUTH_MOTHOD)
            log.debug_info(rsp_string_data)
            return False
        
        #获取用户权限验证是否打开
        temp_enable_status=temp_hanlde.get_enable_check_authorization_flag()
        log.debug_info(u"get_enable_check_authorization_flag:%s" % temp_enable_status)
        
        #返回状态标志  
        return temp_enable_status


    def _get_response_status_code_value(self):
        """
        获取响应指定状态码功能模块是否打开状态
        """
        
        #检查用户回调模块接口是否开放
        if CALLBACK_HANDLE_NOTINIT == self.channel.factory.callback_app_hanlde_init_status:
            return 0, None
        
        #获取TWHttpServer对象句柄
        temp_hanlde=self.channel.factory.callback_app_hanlde
        if not temp_hanlde:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE)
            log.debug_info(rsp_string_data)
            return -1, rsp_string_data
        
        #检查句柄是否有获取状态码功能模块接口
        if not (hasattr(temp_hanlde,"get_enable_response_status_code_flag") and
            hasattr(temp_hanlde,"get_enable_response_status_code_flag") ):
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_RESPONSE_STATUS_CODE_MOTHOD)
            log.debug_info(rsp_string_data)
            return -1, rsp_string_data
        
        #获取响应指定状态码功能模块是否打开
        temp_enable_status=temp_hanlde.get_enable_response_status_code_flag()
        log.debug_info(u"get_enable_response_status_code_flag:%s" % temp_enable_status)

        if not temp_enable_status:
            #响应指定状态码功能模块是关闭的
            return 0, None
            
        else:
            #获取指定状态码的值
            tmp_response_status_code_number=temp_hanlde.get_response_status_code()
            log.debug_info(u"get_response_status_code:%d" % tmp_response_status_code_number)
            
            #返回指定状态码的值
            return 1, tmp_response_status_code_number
        
        
    def process_response_status_code(self):
        """
        实现响应指定状态码功能模块
        """
        run_method_flag=False

        #获取用户权限验证是否打开
        rc_enble_status,rc_data=self._get_response_status_code_value()
        
        #将请求传递到后续处理模块
        if 0 == rc_enble_status:
            run_method_flag=False
        
        #获取属性数据错误
        elif -1 == rc_enble_status:
            #服务器内部错误
            self._internal_server_error(e)
            run_method_flag=True
            
        else:
            #响应固定状态码
            rsp_string_data="Response status code:[%d]" % int(rc_data)
            
            #设置响应消息常规头数据
            self._construct_response_header(int(rc_data),"text/html; charset=utf-8",str(len(rsp_string_data)))
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()
            run_method_flag=True

        return run_method_flag
        
        
    def process_dispath_request(self):
        """
        处理客户端具体数据请求
        """
        #调用响应指定状态码功能模块
        rc_run_method_flag=self.process_response_status_code()
        if rc_run_method_flag:
            return
        
        #处理上传类型
        rc_status, temp_cfg_client_upload_type=self._get_client_upload_type_string()
        if (not rc_status or
            ("GET" != self.method and
            "BOTH" != temp_cfg_client_upload_type and
            self.method != temp_cfg_client_upload_type)):

            #上传类型错误
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_UPLOAD_TYPE_IS_NOT_CONFIGURED_MODE)
            
            #获取返回数据长度
            rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            
            #设置响应消息常规头数据
            self._construct_response_header(http.NOT_ALLOWED,"text/html; charset=utf-8",str(rsp_string_data_length))
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()
            return
            
        #处理消息正常流程
        self.site = self.channel.factory.site
        
        if self.method=="PUT":
            self.site.render_PUT(self)
            
        elif self.method=="POST":
            self.site.render_POST(self)

        elif self.method=="GET":
            self.site.render_GET(self)

        else:
            #方法不支持
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_405_ERROR)
            
            #获取返回数据长度
            rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))
                
            #设置响应消息常规头数据
            self._construct_response_header(http.NOT_ALLOWED,"text/html; charset=utf-8",str(rsp_string_data_length))
            self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            self.finish()
            
            
    def basic_authorization_handle_login(self, user_name, password):
        """
        账户登入
        """
        #验证用户权限
        creds = credentials.UsernamePassword(user_name, password)
        
        #登入
        self.channel.factory.portal.login(creds, None, INamedUserAvatar).addCallback(
                                                    self._loginSucceeded).addErrback(
                                                    self._loginFailed)
        
    def _loginSucceeded(self, avatarInfo):
        """
        用户登录成功
        """
        avatarInterface, avatar, logout = avatarInfo
        log.debug_info(u"_loginSucceeded:fullname=%s" % avatar.fullname)
                       
        #处理客户端具体数据请求
        self.process_dispath_request()
        
        #登出
        defer.maybeDeferred(logout).addBoth(self._logoutFinished)


    def _logoutFinished(self, result):
        """
        端口客户端连接
        """
        pass
            
            
    def _loginFailed(self, failure):
        """
        用户登录失败
        """
        log.debug_info(u"_loginFailed: %s" % failure.getErrorMessage())
        rsp_string_data=str(failure.getErrorMessage())
        
        #构建常规响应消息头
        self._construct_response_header(http.UNAUTHORIZED,"text/html; charset=utf-8",str(len(rsp_string_data)))
        
        #未授权的, 构建Basic认证返回信息
        self.setHeader("WWW-Authenticate", self._construct_auth_basic_response())
        self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
        self.finish()

        
    def _construct_response_header(self,
                                   rsp_code,
                                   content_type,
                                   content_length):
        
        #设置响应消息常规头数据
        self.setResponseCode(rsp_code)
        self.setHeader("Pragma", "No-cache")
        self.setHeader("Cache-Control", "no-cache")
        self.setHeader("Content-type", content_type)
        self.setHeader("Content-Length", content_length)
        

    def _internal_server_error(self, except_e):
        """
        服务器内部错误响应
        """
        log.debug_info(type(except_e))
        log.debug_info(except_e)
        
        #服务器内部错误
        rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_PROCESS_500_ERROR)
        log.debug_info(rsp_string_data)
        
        #获取返回数据长度
        rsp_string_data_length=len(MyChars.build_value_type_unicode_to_string(rsp_string_data))

        #设置响应消息常规头数据
        self._construct_response_header(http.INTERNAL_SERVER_ERROR,"text/html; charset=utf-8",str(rsp_string_data_length))
        self.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
        self.finish()
        
        
class MyHttp(http.HTTPChannel):
    requestFactory = MyRequestHandler


class MyHttpFactory(http.HTTPFactory):
    protocol = MyHttp
    
    #保存TWHttpServer对象句柄
    callback_app_hanlde=None
    callback_app_hanlde_init_status=CALLBACK_HANDLE_NOTINIT

    def set_callback_app_handle(self,object_handle):
        """
        更新TWHttpServer对象句柄
        """
        self.callback_app_hanlde=object_handle
        self.callback_app_hanlde_init_status=CALLBACK_HANDLE_INIT




#+++++++++++++++++++++++++++++++++
#测试
users = {
    "admin": "Admin User",
    "user1": "Joe Smith",
    "user2": "Bob King",
    }
                
passwords = {
    "admin": "aaa",
    "user1": "bbb",
    "user2": "ccc"
    }
    
def test1():
    from twisted.internet import reactor
   
    p = portal.Portal(TestRealm(users))
    p.registerChecker(PasswordDictChecker(passwords))
    factory=MyHttpFactory()
    factory.portal = p
    
    #pageshandle=PageMenagement("renderpages.dat")
    #root = RenderPage(pageshandle)
    
    #root=MyRenderPage("e://httpserver//")
    root=MyRenderPage(u"e://我的目录//")
    factory.site=root

    tmp_listeningport=reactor.listenTCP(8000, factory, interface="172.16.28.59") #IListeningPort.
    #print tmp_listeningport.getHost()
    #factory.set_callback_app_handle(None)
    
    reactor.run()
    

if __name__ == "__main__":   
    test1()
    
    nExit = raw_input("Press any key to end...")
