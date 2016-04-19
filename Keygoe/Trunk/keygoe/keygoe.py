# -*- coding: utf-8 -*- 
#
#    jias 2013-09-23

import os
import sys
from ctypes import *
import time
#import cgi

import attlog as log
VOIP_PRINT_LOG = False

class Keygoe:
    """
    Keygoe 系统的语音卡
    """       
    #h_voip = CDLL(os.path.join(os.path.dirname(__file__), 'VoipKeygoe.dll'))     
  
    def __init__(self):
        """
        检查是否准备OK
        """
        self.h_voip = CDLL(os.path.join(os.path.dirname(__file__), 'VoipKeygoe.dll'))
           
    def init_keygoe_system(self):
        """
        准备是否OK 状态Free
        """
        configfile = os.path.join(os.path.dirname(__file__), '')
        n_ret = self.h_voip.InitKeygoeSystem(c_char_p(configfile))
        if n_ret == -2:
            log_info = u"读取配置文件XMS_KEYGOE.INI失败。请确认配置文件内容是否正确。"
            log.user_info(log_info)
        elif n_ret == -3:
            log_info = u"""连接keygoe流程模块失败。请确认IP地址，端口号，账号、密码等信息输入是否正确。
注意IP地址、端口号是指流程模块的配置。"""
            log.user_info(log_info)   
        return n_ret
    
    def clear_keygoe_trunk(self, trunk_id):
        """
        重置Trunk的状态到Free
        """
        trunk_id -= 1
        try:
            n_ret = self.h_voip.ClearCall(c_int(trunk_id))
        except Exception, e:
            raise RuntimeError(u"调用DLL中的方法失败")
        time.sleep(3) #reset need time
        return n_ret
    
    def exit_keygoe_system(self):
        """
        准备是否OK 状态Free
        """        
        n_ret = self.h_voip.ExitKeygoeSystem()
        del(self.h_voip)
        self.h_voip = None
        return n_ret

    def wait_trunk_init(self):
        """
        准备是否OK 状态Free
        """   
        n_ret = self.h_voip.WaitTrunkReady()
        if n_ret == -1:
            log_info = u"""未接收到keygoe流程返回的事件。请确认以下信息：
1、输入参数是否与keygoe系统流程模块的配置一致。
2、keygoe服务是否正常运行。请重启keygoe服务，重新连接。
重启方法：先运行C:\\DJKeygoe\\Bin\\Remove server.bat，再运行C:\\DJKeygoe\\Bin\\start server.bat。"""
            log.user_info(log_info)
        return n_ret
    
    def call_out_off_hook(self, trunk_id):
        """
        """
        trunk_id -= 1
        try:
            n_ret = self.h_voip.CallOutOffHook(c_int(trunk_id))
        except Exception:
            raise RuntimeError(u"调用DLL中的方法失败")
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)
            
        return n_ret    
        
    def dial(self, trunk_id, number):
        """
        """
        trunk_id -= 1
        if isinstance(number, unicode):
            str_number = number.encode("ASCII")
        else:
            str_number = number

        n_ret = self.h_voip.Dial(c_int(trunk_id), c_int(len(str_number)), c_char_p(str_number))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
       
    def send_data(self, trunk_id, data):
        """
        """        
        trunk_id -= 1
        if isinstance(data, unicode):
            str_data = data.encode("ASCII")
        else:
            str_data = data

        #log_info = u"发送DTMF为%s, 长度为%d" % (str_data, len(str_data))
        #log.user_err (log_info)
        n_ret = self.h_voip.SendData(c_int(trunk_id), c_char_p(str_data))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)
        return n_ret
        
    def get_recv_data(self, trunk_id, iLen=0, seconds=3):
        """
        """
        trunk_id -= 1
        self.h_voip.GetRecvData.restype = c_char_p
        n_ret = self.h_voip.GetRecvData(c_int(trunk_id), c_int(iLen), c_int(seconds))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def clear_recv_data(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.ClearRecvData(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def send_fax_prepare(self, trunk_id):
        """
        """
        trunk_id -= 1
        
        n_ret = self.h_voip.SendFax_prepare(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
        
    
    def send_fax(self, trunk_id, sendfile, bps_int, seconds, recordfile_send, recordfile_recv):
        """
        SendFax 必须先调用send_fax_prepare
        """
        trunk_id -= 1
        if isinstance(sendfile, unicode):
            str_sendfile = sendfile.encode("ASCII")
        else:
            str_sendfile = sendfile
            
        iRecord = 0 #0不录音 1录音
        str_recordfile_send = ""
        str_recordfile_recv = ""
        if len(recordfile_send) < len("wav") :
            #不用录音
            iRecord = 0
        else:
            iRecord = 1
            if isinstance(recordfile_send, unicode):
                str_recordfile_send = recordfile_send.encode("ASCII")
            else:
                str_recordfile_send = recordfile_send
            
            if isinstance(recordfile_recv, unicode):
                str_recordfile_recv = recordfile_recv.encode("ASCII")
            else:
                str_recordfile_recv = recordfile_recv
        
        info_c = c_char_p()
        n_ret = self.h_voip.SendFax(c_int(trunk_id),
                                    c_int(bps_int),
                                    c_char_p(str_sendfile),
                                    c_int(seconds),
                                    byref(info_c),
                                    c_int(iRecord),
                                    c_char_p(str_recordfile_send),
                                    c_char_p(str_recordfile_recv))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)
            #add 2013-11-15
            log_info = u"%s" % info_c.value
            log.user_info(log_info)
            
        return n_ret,info_c.value
        
    def recv_fax_prepare(self, trunk_id):
        """
        """
        trunk_id -= 1   
        n_ret = self.h_voip.RecvFax_prepare(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def start_recv_fax(self, trunk_id, savefile, bps_int, recordfile_send, recordfile_recv):
        """
        必须先调用 recv_fax_prepare
        """
        trunk_id -= 1
        if isinstance(savefile, unicode):
            str_savefile = savefile.encode("ASCII")
        else:
            str_savefile = savefile
        
        iRecord = 0 #0不录音 1录音
        str_recordfile_send = ""        
        str_recordfile_recv = ""
        if len(recordfile_send)< len("wav") :
            #不用录音
            iRecord = 0
        else:
            iRecord = 1
            if isinstance(recordfile_send, unicode):
                str_recordfile_send = recordfile_send.encode("ASCII")
            else:
                str_recordfile_send = recordfile_send
                
            if isinstance(recordfile_recv, unicode):
                str_recordfile_recv = recordfile_recv.encode("ASCII")
            else:
                str_recordfile_recv = recordfile_recv
        
        n_ret = self.h_voip.StartRecvFax(c_int(trunk_id),
                                         c_int(bps_int),
                                         c_char_p(str_savefile),
                                         c_int(iRecord),
                                         c_char_p(str_recordfile_send),
                                         c_char_p(str_recordfile_recv))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def get_recv_fax_result(self, trunk_id, seconds):
        """
        """
        trunk_id -= 1
        info_c = c_char_p()
        n_ret = self.h_voip.GetRecvFaxResult(c_int(trunk_id), c_int(seconds), byref(info_c))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)
            #add 2013-11-15
            log_info = u"%s" % info_c.value
            log.user_info(log_info)
            
        return n_ret,info_c.value
    
    def check_call_in(self, trunk_id, seconds):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.CheckCallIn(c_int(trunk_id), c_int(seconds))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def call_in_off_hook(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.CallInOffHook(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret     
        
    def on_hook(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.ClearCall(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def get_trunk_state(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.GetTrunkState(c_int(trunk_id))
        #log
        log_info = u"TrunkState is %d" % n_ret
        log.user_info(log_info)
        return n_ret
    
    def get_trunk_link_state(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.GetTrunkLinkState(c_int(trunk_id))
        #log
        log_info = u"TrunkLinkState is %d" % n_ret
        log.user_info(log_info)
        return n_ret 
    
    def set_flash(self, trunk_id):
        """
        """
        trunk_id -= 1
        n_ret = self.h_voip.SetFlash(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def set_flash_time(self, iTimes):
        """
        """
        n_ret = self.h_voip.SetFlashTime(c_int(iTimes))
        #log
        
        return n_ret
    
    def set_fax_file(self, trunk_id, sendfile):
        """
        必须在prepare之后调用， 添加传真文件
        """
        trunk_id -= 1        
        
        if isinstance(sendfile, unicode):
            str_sendfile = sendfile.encode("ASCII")
        else:
            str_sendfile = sendfile
            
        n_ret = self.h_voip.SetFaxFile(c_int(trunk_id), c_char_p(str_sendfile))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def wait_some_tone(self, trunk_id, sTone, milliseconds):
        """
        检测音，音用"G" -"L"表示
        """
        trunk_id -= 1
        milliseconds = 1000*milliseconds
        
        if isinstance(sTone, unicode):
            str_sTone = sTone.encode("ASCII")
        else:
            str_sTone = sTone
            
        n_ret = self.h_voip.WaitSomeTone(c_int(trunk_id),
                                         c_char_p(str_sTone),
                                         c_int(milliseconds))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def update_tones_set(self):
        """
        """
        n_ret = self.h_voip.UpdateTones()
        #log
        return n_ret
    
    def start_record(self, trunk_id, savefile):
        """
        """
        trunk_id -= 1        
        
        if isinstance(savefile, unicode):
            str_savefile = savefile.encode("ASCII")
        else:
            str_savefile = savefile
            
        n_ret = self.h_voip.StartRecord(c_int(trunk_id), c_char_p(str_savefile))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
    def stop_record(self, trunk_id):
        """
        """
        trunk_id -= 1        
          
        n_ret = self.h_voip.StopRecord(c_int(trunk_id))
        #log
        if (VOIP_PRINT_LOG):
            self.get_trunk_state(trunk_id)
            self.get_trunk_link_state(trunk_id)      
        return n_ret
    
def Test():
    
    from time import ctime,sleep    
    
    print u'start test...'
       
    return
  

if __name__ == '__main__':        
    
    Test()
    print 'Test end...'
