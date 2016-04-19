# -*- coding: utf-8 -*-
import sys


#定义消息
#=================================================
#具体功能消息ID

#打开/关闭用户权限验证
MESSAGE_ID_REGISTER_USER_ACCOUNT="MESSAGE_ID_REGISTER_USER_ACCOUNT"
MESSAGE_ID_UNREGISTER_USER_ACCOUNT="MESSAGE_ID_UNREGISTER_USER_ACCOUNT"

#注册/清除注册用户账户
MESSAGE_ID_OPEN_CHECK_AUTHORIZATION="MESSAGE_ID_OPEN_CHECK_AUTHORIZATION"
MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION="MESSAGE_ID_CLOSE_CHECK_AUTHORIZATION"

#打开/关闭指定状态码响应
MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE="MESSAGE_ID_OPEN_RESPONSE_STATUS_CODE"
MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE="MESSAGE_ID_CLOSE_RESPONSE_STATUS_CODE"

#设置状态码的值
MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER="MESSAGE_ID_SET_RESPONSE_STATUS_CODE_NUMBER"

#add by wangjun 20131119
#设置用户权限验证模式
MESSAGE_ID_SET_AUTH_TYPE="MESSAGE_ID_SET_AUTH_TYPE"

#设置上传类型模式 
MESSAGE_ID_SET_UPLOAD_TYPE="MESSAGE_ID_SET_UPLOAD_TYPE"

#未知消息类型
MESSAGE_ID_UNKNOWN = "MESSAGE_ID_UNKNOWN"
#=================================================



    

#LOG接口
#=================================================
#测试标志
DEBUG_FLAG=True

if not DEBUG_FLAG:
    import attlog as log
    
import threading
LOCK__LOG= threading.Lock()

import os
import datetime

OUT_LOG_FILE=None

    
def _log_string(log_string):
    """
    将LOG信息写入LOG文件中
    """
    global OUT_LOG_FILE
    
    if not OUT_LOG_FILE:
        _set_logfile_path() 
        
    if not DEBUG_FLAG:
        _del_logfile_path()
        return
    
    try:
        global LOCK__LOG
        LOCK__LOG.acquire()
        
        if isinstance(log_string, unicode):
            log_string=log_string.encode("utf8")
            
        elif not isinstance(log_string, str):
            return
        
        else:
            pass

        #print log_string
        with open(OUT_LOG_FILE,'a+') as item :
            item.seek(os.SEEK_END )
            item.write(log_string)
            item.write('\n')
            
    except Exception, e:
        pass
        
    finally:  
        LOCK__LOG.release()


def _set_logfile_path():
    """
    设置LOG文件存放的路径
    """
    global OUT_LOG_FILE

    #更新LOG文件地址
    LOG_DIRECTORY = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
    OUT_LOG_DIR = os.path.join(LOG_DIRECTORY, 'log', 'HttpServer-LOG')
    
    dt_obj=datetime.datetime.now()
    log_file_name = "log-%s.txt" % dt_obj.date()

    OUT_LOG_FILE = os.path.join(OUT_LOG_DIR,log_file_name)
    if not os.path.exists(OUT_LOG_DIR):
        os.makedirs(OUT_LOG_DIR, 777)


def _del_logfile_path():
    try:
        #更新LOG文件地址
        LOG_DIRECTORY = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        OUT_LOG_DIR = os.path.join(LOG_DIRECTORY, 'log', 'HttpServer-LOG')
    
        #删除测试文件夹
        if os.path.exists(OUT_LOG_DIR):
            
            import shutil
            shutil.rmtree(OUT_LOG_DIR)
    except Exception,e:
        pass
    
        
class ProcessOutLog():
    """
    自定义LOG接口,用于DEBUG模式
    """
    @staticmethod        
    def debug_info(log_string):

        try:
            global DEBUG_FLAG
            if not DEBUG_FLAG:
                log.app_info(log_string)
                
            _log_string(log_string)
            
        except Exception, e:
            pass


    @staticmethod
    def debug_err(log_string):
        try:
            global DEBUG_FLAG
            if not DEBUG_FLAG:
                log.debug_err(log_string)
                
            _log_string(log_string)
            
        except Exception, e:
            pass


    @staticmethod
    def user_info(log_string):
        try:
            global DEBUG_FLAG
            if not DEBUG_FLAG:
                log.user_info(log_string)
                
            _log_string(log_string)
            
        except Exception, e:
            pass
            
            

