# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: MyCheck
#  class:
#       定义了HttpServer库打印的关键语句描述
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
# ***************************************************************************

#key
STRING_REQUEST_PROCESS_401_ERROR=0
STRING_REQUEST_PROCESS_500_ERROR=1
STRING_REQUEST_PROCESS_405_ERROR=2
STRING_REQUEST_RENDER_404_ERROR=3
STRING_REQUEST_PROCESS_UNKNOWN_ERROR=4

STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE=100
STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CHECKAUTH_MOTHOD=101
STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_RESPONSE_STATUS_CODE_MOTHOD=102

#add by wangjun 20131119
STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CLIENT_AUTH_TYPE=103
STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CLIENT_UPLOAD_TYPE=104
STRING_REQUEST_PROCESS_UPLOAD_TYPE_IS_NOT_CONFIGURED_MODE=105
STRING_REQUEST_PROCESS_AUTH_TYPE_IS_NOT_CONFIGURED_MODE=106
STRING_REQUEST_PROCESS_DOES_NOT_RECOGNIZE_AUTH_TYPE=107

STRING_REQUEST_CRED_NOTDEFINE_INTERFACE=200
STRING_REQUEST_CRED_NO_SUCH_USER=201
STRING_REQUEST_CRED_BAD_PASSWORD=202

STRING_REQUEST_RENDER_ERROR_NO_PERMISSION_TO_LIST_DIRECTORY=300
STRING_REQUEST_RENDER_ERROR_POST_CONTENT_NOT_BEGIN_WITH_BOUNDAR=301
STRING_REQUEST_RENDER_ERROR_CAN_NOT_FINE_OUT_FILENAME=302
STRING_REQUEST_RENDER_ERROR_FILENAME_ERROR=303
STRING_REQUEST_RENDER_ERROR_CAN_NOT_WRITE_FILE=304
STRING_REQUEST_RENDER_ERROR_UNEXPECT_ENDS_OF_DATA=305
STRING_REQUEST_RENDER_ERROR_READ_VALUE_ERROR=306
STRING_REQUEST_RENDER_UPLOAD_FILE_SUCCESS=307

STRING_HTTPSERVER_FACTORY_OBJECT_HANDLE_NOT_INIT=400
STRING_HTTPSERVER_REACTOR_LISTEN_TCP_ERROR=401
STRING_HTTPSERVER_REACTOR_RUN_ERROR=402
STRING_HTTPSERVER_REACTOR_STOP_SUC=403
STRING_HTTPSERVER_REACTOR_STOP_ERROR=404

STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_DATA_FAIL=407
STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_NOT_FOUND_MATCH_INTERFACE=408

STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_SUC=409
STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_FAIL=410

STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_SUC=411
STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_FAIL=412

STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_SUC=413
STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_FAIL=414

STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_SUC=415
STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_FAIL=416

STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_SUC=417
STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_FAIL=418

STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_SUC=419
STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_FAIL=420

STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_SUC=421
STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_FAIL=422

STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_SUC=423
STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_FAIL=424

STRING_HTTPSERVER_STOP_SUC=425
STRING_HTTPSERVER_STOP_ERROR=426

STRING_HTTPSERVER_START_SUC=427
STRING_HTTPSERVER_START_ERROR=428
STRING_HTTPSERVER_REACTOR_CANNOT_LISTEN_THIS_PORT=429

STRING_HTTPSERVER_UNREGISTER_NOTFOUND_USER_ACCOUNT=450

#add by wangjun 20131119
STRING_HTTPSERVER_SET_AUTH_TYPE_SUC=451
STRING_HTTPSERVER_SET_AUTH_TYPE_FAIL=452
STRING_HTTPSERVER_SET_UPLOAD_TYPE_SUC=453
STRING_HTTPSERVER_SET_UPLOAD_TYPE_FAIL=454


STRING_PEOCESS_STATUS_ERROR=500
STRING_PEOCESS_NOT_INIT=501
STRING_PEOCESS_NOT_RUNNING=502


lang_type=1 # 0:en 1:cn


#value
dict_httpserver_string = {}


dict_httpserver_string[STRING_REQUEST_PROCESS_401_ERROR] = [u"401 Unauthorized",u"401 未授权"]
dict_httpserver_string[STRING_REQUEST_PROCESS_500_ERROR] = [u"Internal Server Error",u"500 服务器内部错误"]
dict_httpserver_string[STRING_REQUEST_PROCESS_405_ERROR] = [u"Method Not Allowed",u"405 方法为定义"]
dict_httpserver_string[STRING_REQUEST_RENDER_404_ERROR] = [u"Not found",u"404 没有找到"]

dict_httpserver_string[STRING_REQUEST_PROCESS_UNKNOWN_ERROR]=[u"Unknown Error", u"未知错误"]

dict_httpserver_string[STRING_FACTORY_CALLBACK_APP_HANDLE_NONETYPE] = [u"Factory callback app object hanlde is not init",u"工厂对象没有初始化"]
dict_httpserver_string[STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CHECKAUTH_MOTHOD] = [u"Factory callback app object is not define get authorized status method",u"没有找到获取用户权限验证模块是否打开接口"]
dict_httpserver_string[STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_RESPONSE_STATUS_CODE_MOTHOD] = [u"Factory callback app object is not define get response code method",u"没有找到获取对指定状态码响应模块是否打开接口"]

#add by wangjun 20131119
dict_httpserver_string[STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CLIENT_AUTH_TYPE] = [u"Factory callback app object is not define get client authorization string",u"没有找到获取客户端认证类型接口"]
dict_httpserver_string[STRING_FACTORY_CALLBACK_APP_NOTDEFINE_GET_CLIENT_UPLOAD_TYPE] = [u"Factory callback app object is not define get client upload type string",u"没有找到获取客户端上传类型接口"]
dict_httpserver_string[STRING_REQUEST_PROCESS_UPLOAD_TYPE_IS_NOT_CONFIGURED_MODE] = [u"Client upload the data type is not the type of configuration",u"客户端请求上传数据的消息类型不是配置的类型"]
dict_httpserver_string[STRING_REQUEST_PROCESS_AUTH_TYPE_IS_NOT_CONFIGURED_MODE] = [u"401 Unauthorized, Client request the authorization type is not the type of configuration",u"401 未授权, 客户端请求的认证类型不是配置的认证类型"]
dict_httpserver_string[STRING_REQUEST_PROCESS_DOES_NOT_RECOGNIZE_AUTH_TYPE] = [u"401 Unauthorized, Does not recognize the client request authentication type",u"401 未授权, 无法识别客户端请求的认证类型"]


dict_httpserver_string[STRING_REQUEST_CRED_NOTDEFINE_INTERFACE] = [u"None of the requested interfaces is supported",u"没有找到工厂用户权限验证接口"]
dict_httpserver_string[STRING_REQUEST_CRED_NO_SUCH_USER] = [u"No such user",u"用户未注册"]
dict_httpserver_string[STRING_REQUEST_CRED_BAD_PASSWORD] = [u"Bad password",u"密码错误"]

dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_NO_PERMISSION_TO_LIST_DIRECTORY] = [u"No permission to list directory",u"没有列出目录权限"]
dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_POST_CONTENT_NOT_BEGIN_WITH_BOUNDAR] = [u"Content Not begin with boundary",u"内容不以boundary开始"]
dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_CAN_NOT_FINE_OUT_FILENAME] = [u"Can't find out file name...",u"没有找到输出文件"]
dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_FILENAME_ERROR] = [u"File name err",u"文件名错误"]
dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_CAN_NOT_WRITE_FILE] = [u"Can't create file to write, do you have permission to write?", u"创建文件无法写操作，确认是否有写权限？"]
dict_httpserver_string[STRING_REQUEST_RENDER_ERROR_UNEXPECT_ENDS_OF_DATA] = [u"Unexpect Ends of data",u"数据意外结束"]
dict_httpserver_string[STRING_REQUEST_RENDER_UPLOAD_FILE_SUCCESS] = [u"File '%s' upload success!",u"文件 '%s' 上传成功！"]

dict_httpserver_string[STRING_HTTPSERVER_FACTORY_OBJECT_HANDLE_NOT_INIT] = [u"Factory object handle not init",u"工厂对象句柄没有初始化"]
dict_httpserver_string[STRING_HTTPSERVER_REACTOR_LISTEN_TCP_ERROR] = [u"Reactor.listenTCP error",u"Reactor 启动监听服务失败"]
dict_httpserver_string[STRING_HTTPSERVER_REACTOR_RUN_ERROR] = [u"Reactor.run error",u"Reactor 启动运行服务失败"]
dict_httpserver_string[STRING_HTTPSERVER_REACTOR_STOP_SUC] = [u"Reactor.stop success",u"Reactor 停止服务成功"]
dict_httpserver_string[STRING_HTTPSERVER_REACTOR_STOP_ERROR] = [u"Reactor.stop error",u"Reactor 停止服务失败"]
dict_httpserver_string[STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_DATA_FAIL] = [u"Dispath request message data exception",u"分发管道消息失败"]
dict_httpserver_string[STRING_HTTPSERVER_DISPATH_REQUEST_MESSGAE_NOT_FOUND_MATCH_INTERFACE] = [u"Dispath request message not found match interface",u"分发管道消息失败，没有找到对应的处理方法"]

dict_httpserver_string[STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_SUC] = [u"Set response status code method success",u"设置响应状态码的值成功"]
dict_httpserver_string[STRING_HTTPSERVER_SET_RESPONSE_STATUS_CODE_FAIL] = [u"Set response status code method fail",u"设置响应状态码的值失败"]
dict_httpserver_string[STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_SUC] = [u"Open response status code method success",u"开启状态码响应模块成功"]
dict_httpserver_string[STRING_HTTPSERVER_OPEN_RESPONSE_STATUS_CODE_MODULE_FAIL] = [u"Open response status code method fail",u"开启状态码响应模块失败"]
dict_httpserver_string[STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_SUC] = [u"Close response status code method success",u"关闭状态码响应模块成功"]
dict_httpserver_string[STRING_HTTPSERVER_CLOSE_RESPONSE_STATUS_CODE_MODULE_FAIL] = [u"Close response status code method fail",u"关闭状态码响应模块成功"]
dict_httpserver_string[STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_SUC] = [u"Open check authorization method success",u"开启用户权限验证模块成功"]
dict_httpserver_string[STRING_HTTPSERVER_OPEN_CHECK_AUTHORIZATION_MODULE_FAIL] = [u"Open check authorization method fail",u"开启用户权限验证模块失败"]
dict_httpserver_string[STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_SUC] = [u"Close check authorization method success",u"关闭用户权限验证模块成功"]
dict_httpserver_string[STRING_HTTPSERVER_CLOSE_CHECK_AUTHORIZATION_MODULE_FAIL] = [u"Close check authorization method fail",u"关闭用户权限验证模块失败"]
dict_httpserver_string[STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_SUC] = [u"Register user account suc method success",u"注册访问HTTP服务器账号成功"]
dict_httpserver_string[STRING_HTTPSERVER_REGISTER_USER_ACCOUNT_FAIL] = [u"Register user account suc method fail",u"注册访问HTTP服务器账号失败"]
dict_httpserver_string[STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_SUC] = [u"Unregister user account suc method success",u"注销访问HTTP服务器账号成功"]
dict_httpserver_string[STRING_HTTPSERVER_UNREGISTER_USER_ACCOUNT_FAIL] = [u"Unregister user account suc method fail",u"注销访问HTTP服务器账号失败"]
dict_httpserver_string[STRING_HTTPSERVER_UNREGISTER_NOTFOUND_USER_ACCOUNT] = [u"Unregister user account suc method fail",u"注销访问HTTP服务器账号失败,没有找到需要注销的账户信息"]

#add by wangjun 20131119
dict_httpserver_string[STRING_HTTPSERVER_SET_AUTH_TYPE_SUC] = [u"Set authorization type success",u"设置HTTP服务器验证客户端用户权限类型成功"]
dict_httpserver_string[STRING_HTTPSERVER_SET_AUTH_TYPE_FAIL] = [u"Set authorization type success",u"设置HTTP服务器验证客户端用户权限类型失败，参数值非法，有效取值为: BASIC或DIGEST，值不区分大小写"]
dict_httpserver_string[STRING_HTTPSERVER_SET_UPLOAD_TYPE_SUC] = [u"Set upload type success",u"设置HTTP服务器支持客户端上传类型成功"]
dict_httpserver_string[STRING_HTTPSERVER_SET_UPLOAD_TYPE_FAIL] = [u"Set upload type success",u"设置HTTP服务器支持客户端上传类型失败，参数值非法，有效取值为: POST或PUT或BOTH，值不区分大小写"]

dict_httpserver_string[STRING_HTTPSERVER_STOP_SUC] = [u"Httpserver stop method success",u"停止HTTP服务器成功"]
dict_httpserver_string[STRING_HTTPSERVER_STOP_ERROR] = [u"Httpserver stop method success fail: %s",u"停止HTTP服务器失败，错误：%s"]
dict_httpserver_string[STRING_HTTPSERVER_START_SUC] = [u"Httpserver start method success",u"启动HTTP服务器成功"]
dict_httpserver_string[STRING_HTTPSERVER_START_ERROR] = [u"Httpserver start method success fail: %s",u"启动HTTP服务器失败，错误：%s"]

dict_httpserver_string[STRING_HTTPSERVER_REACTOR_CANNOT_LISTEN_THIS_PORT] = [u"Cannot listen on this addr(%s:%s),choose another port please!", u"无法绑定到所需的端口(%s:%s)，请选择其他端口。"]

dict_httpserver_string[STRING_PEOCESS_STATUS_ERROR] = [u"Process object state is error, status=%s",u"HTTP服务对象状态错误，当前状态为=%s"]
dict_httpserver_string[STRING_PEOCESS_NOT_INIT] = [u"Process object not init",u"HTTP服务器对象没有初始化"]
dict_httpserver_string[STRING_PEOCESS_NOT_RUNNING] = [u"Process object not start",u"HTTP服务器对象没有运行"]


def convert_coding(string):
    """
    功能描述：将string的编码转换成unicode编码
    
    参数： string: 原始字符串
    
    返回值： ret_str: unicode编码的字符串
    """
    if isinstance(string,unicode):
        string = string.encode('utf-8')
        
    try:
        import chardet
        ret_data = chardet.detect(string)
        str_encoding = ret_data.get('encoding')

    except Exception, e:
        print u"获取字符串编码失败，错误信息为:%s" % e
    
    if not isinstance(str_encoding,unicode):
        ret_str = string.decode(str_encoding)

    return ret_str
    
    
def get_string_value(string_key):
    
    if string_key in dict_httpserver_string:
        return convert_coding(dict_httpserver_string.get(string_key)[lang_type])

    else:
        return ""


def build_value_type_unicode_to_string(unicode_data):
    
    if isinstance(unicode_data, unicode):
        return unicode_data.encode("utf8")
    else:
        return unicode_data
    

