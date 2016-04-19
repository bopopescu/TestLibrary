# -*- coding: utf-8 -*- 

import sys
import time
from keygoe.keygoe import Keygoe
import attlog as log

import ConfigParser
import os

VOIP_FUN_OK = 1
VOIP_FUN_FIAL = -1

class _PHONESTATE():
    
    """
    """
    S_NONE                  = 1
    S_INIT                  = 2
    S_CALL_OUT_OFFHOOK      = 3
    S_CHECK_CALL_IN         = 5
    S_IN_CALL               = 7
    S_RECV_FAX_START        = 8
    S_ONHOOK                = 9
    S_CLEAR_CALL            = 10

class CPEPhone():
    
    def __init__(self, trunk_id):
        """
        CPE相关信息
        """
        self.trunk_id = trunk_id
        self.state = _PHONESTATE.S_NONE
           
    def get_trunk(self):
        return self.trunk_id
      
    def get_state(self):
        return self.state   
    
    def set_state(self, state):
        self.state = state
        
           
    def reset(self):
        #self.trunk_id = trunk_id
        self.state = _PHONESTATE.S_NONE
        
class AttToneConfig():
    
    def __init__(self):
        
        #配置文件
        self.freq_dict = {} #{freq:index,..}
        
        self.cf = ConfigParser.ConfigParser()
        self.inifile = os.path.join(os.path.dirname(__file__), 'keygoe\\XMS_KEYGOE.INI')
        self.cf.read(self.inifile)
        self._read_all_freq()
        self._update_freq()
        
    def _read_all_freq(self):
        """
        读取配置文件获取有哪频率
        """
        ##读取音
        #和用到的频率
        self.freq_dict.clear()
        index_freq = 0
        
        ss = self.cf.sections()
        for item in ss:
            if item in ["ConfigInfo", "Freq"]:
                continue
            try:
                Freq = self.cf.getint(item, "freq")
                if Freq not in self.freq_dict.keys():
                    self.freq_dict[Freq] = index_freq
                    index_freq += 1
                
            except Exception, e2:
                log_info = u"读取配置文件节点%s失败." % item
                raise RuntimeError (log_info)
                
    def _update_freq(self):
        """
        更新频率的配置，update 所有音的freqindexmask
        """        
        #更新频率
        try:            
            for freq in self.freq_dict.keys():
                index = self.freq_dict.get(freq)
                self.cf.set("Freq", str(index), freq)
            
            freq_count = len(self.freq_dict)
            self.cf.set("ConfigInfo", "freqcount", freq_count)
            
        except Exception:
            log_info = u"读取频率配置失败."
            raise RuntimeError (log_info)
        
        #update 所有音的freqindexmask        
        ss = self.cf.sections()
        for item in ss:
            if item in ["ConfigInfo", "Freq"]:
                continue
            try:
                cur_freq = self.cf.get(item, "freq")      
                cur_index = self.freq_dict[int(cur_freq)]
                cur_freq_maxk = 2**cur_index
                
                self.cf.set(item, "freqindexmask", cur_freq_maxk)
                #
                self.cf.write(open(self.inifile,'w'))
                
            except Exception, e2:
                log_info = u"修改配置文件节点%s失败." % item
                raise RuntimeError (log_info)
      
    def config_some_tone(self, name, freq, envelopemode, ontime1, offtime1, ontime2, offtime2, timedeviation):
        """
        配置要检测的音
        """
        skey = name
        try:
            if skey == None:
                skey = ""
                raise Exception(u"要配置的声音名称为none")
            self.cf.set(skey, "Freq", freq)
            self.cf.set(skey, "EnvelopeMode", envelopemode)
            self.cf.set(skey, "On_Time", ontime1)
            self.cf.set(skey, "Off_Time", offtime1)
            self.cf.set(skey, "On_Time_Two", ontime2)
            self.cf.set(skey, "Off_Time_Two", offtime2)
            self.cf.set(skey, "TimeDeviation", timedeviation)            
            
            self.cf.write(open(self.inifile,'w'))
            #
            index_freq = -1
            mark_freq = -1
            freq_count = len(self.freq_dict)
            if (freq in self.freq_dict.keys()):
                index_freq = self.freq_dict[freq]
                #存在
                mark_freq = 2**index_freq #   #2的index_freq次方
            else:
                #不存在 添加
                #freq_count = self.cf.get("ConfigInfo", "freqcount")                
                #print freq_count
                index_freq = (freq_count+1)-1   #增加1 从0开始
                if index_freq >= 16:
                    log_info = u"不能配置超过16个不同频率，请断开服务后重新连接"
                    raise RuntimeError (log_info)
                    pass
                #添加到字典
                self.freq_dict[freq] = index_freq
                #写到配置文件
                self.cf.set("Freq", str(index_freq), freq)
                self.cf.set("ConfigInfo", "freqcount", (index_freq+1))
                
                mark_freq = 2**index_freq  #  
            self.cf.set(skey, "freqindexmask", mark_freq)
            
            self.cf.write(open(self.inifile,'w'))
        except Exception, e: 
            log_info = u"修改配置文件节点%s失败. %s" % (skey, e)
            raise RuntimeError (log_info)
        
        log_info = u"将配置的待检测音信息写入到配置文件成功"
        log.user_info(log_info)
        return True
    
    def config_system_param(self, serverIp, port, username, password):
        """
        配置底层流程服务参数
        """        
        try:
            self.cf.set("ConfigInfo", "ipaddr", serverIp)
            self.cf.set("ConfigInfo", "port", port)
            self.cf.set("ConfigInfo", "username", username)
            self.cf.set("ConfigInfo", "password", password)
            
            self.cf.write(open(self.inifile,'w'))
        except Exception, e: 
            log_info = u"修改配置文件中语音卡流程服务配置信息失败. %s" 
            raise RuntimeError (log_info)
            
        return True

class ATTVoip():

    def __init__(self):
        self.obj = Keygoe()
        if self.obj == None:
            log_info = u"调用DLL失败" 
            raise RuntimeError (log_info)
        
        self.trunk_id_list = []  #可用Trunk列表
        #连接服务
        self.init_keygoe_system() #初始化self.trunk_id_list
        
        #业务相关
        self.phone_dict = {}
        self._init_all_trunk()
        
    
    def init_keygoe_system(self):
        """
        始化语音卡设备
        """        
        if (VOIP_FUN_OK == self.obj.init_keygoe_system()):
            log_info = u"开始初始化语音卡设备..." 
            log.user_info(log_info)
        else:
            log_info = u"启动系统初始化失败" 
            raise RuntimeError(log_info)
        
        nRet = self.obj.wait_trunk_init()
        if (VOIP_FUN_FIAL == nRet):
            log_info = u"初始化模拟中继通道失败"
            raise RuntimeError (log_info)
        
        log.debug_info(u"可用Trunk 是 %d" % nRet)
        for i in range(16): #1111111111111111(2进制)表示可用Trunk有16个
            if ((nRet & 1) == 1):
                self.trunk_id_list.append((i+1))
            nRet = (nRet >> 1)
        
        log_info = u"完成系统初始化,可用模拟通道列表如下：" 
        log.user_info(log_info)
        log.user_info(self.trunk_id_list)
                
    def exit_keygoe_system(self):
        """
        """        
        if (VOIP_FUN_OK == self.obj.exit_keygoe_system()):
            log_info = u"退出系统成功" 
            log.user_info(log_info)
        else:
            log_info = u"退出系统失败"
            raise RuntimeError(log_info)       
        
    def _init_all_trunk(self):
        """
        初始化16个通道的缓存
        """
        self.phone_dict.clear()
        for i in self.trunk_id_list:
            self.phone_dict[i] = CPEPhone(i)      
        
    def reset_trunk(self, trunk_id):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)
        
        #存在被呼叫、且没有摘机，也没有检查是否有呼入的状态， 该状态需要重置。
        #故删除状态检查 delete by jias 20131211
        
        if(VOIP_FUN_OK == self.obj.clear_keygoe_trunk(trunk_id)):
            log_info = u"重置模拟通道设备%d成功" % trunk_id
            log.user_info(log_info)
            #
            phone.reset()            
        else:
            log_info = u"重置模拟通道设备%d失败" % trunk_id
            raise RuntimeError(log_info)              
        
    def reset_all_trunk(self):
        """
        """
        trunk_id_list = self.phone_dict.keys()
        
        for trunk_id in trunk_id_list :
            self.reset_trunk(trunk_id)
        
    def _get_trunk_config_info(self, trunk_id):
        """
        """
        if (self.phone_dict.has_key(trunk_id)):
            try:
                return  (self.phone_dict.get(trunk_id))
            except Exception , e:
                raise RuntimeError (u"取字典失败")
        else:
            raise RuntimeError (u"该通道未被使用，获取相关信息失败")
    
    def call_out_offhook(self, trunk_id):
        """
        """        
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_NONE,_PHONESTATE.S_INIT,_PHONESTATE.S_ONHOOK, _PHONESTATE.S_CLEAR_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
            
        if (VOIP_FUN_OK == self.obj.call_out_off_hook(trunk_id)):
            log_info = u"模拟通道%d摘机成功" % trunk_id
            log.user_info(log_info)            
            #update state
            phone.set_state(_PHONESTATE.S_CALL_OUT_OFFHOOK)
        else:
            log_info = u"模拟通道%d摘机失败" % trunk_id
            raise RuntimeError(log_info)
       
    def dial_by_number(self, trunk_id, number):
        """
        """      
        phone_a = self._get_trunk_config_info(trunk_id)  
        #check state
        if phone_a.get_state() not in [_PHONESTATE.S_CALL_OUT_OFFHOOK, _PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK == self.obj.dial(trunk_id, number)):
            log_info = u"模拟通道%d拨号给%s成功" % (trunk_id, number)
            log.user_info(log_info)
            #update state
            phone_a.set_state(_PHONESTATE.S_IN_CALL)
        else:
            log_info = u"模拟通道%d拨号给%s失败" % (trunk_id, number)
            raise RuntimeError(log_info)  
        
    def send_dtmf(self, trunk_id, dtmf):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)        
        
        #check state
        if phone.get_state() not in [_PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        self._clear_call_recv_data()
        if (VOIP_FUN_OK == self.obj.send_data(trunk_id, dtmf)):
            log_info = u"模拟通道%d发送DTMF数据为:%s" % (trunk_id, dtmf)
            log.user_info(log_info)
            
        else:
            log_info = u"模拟通道%d发送DTMF数据失败" % (trunk_id)
            raise RuntimeError(log_info)            
        
    def get_recv_dtmf(self, trunk_id):
        """
        """   
        phone = self._get_trunk_config_info(trunk_id)   
        #check state
        if phone.get_state() not in [_PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        dtmf_recv = self.obj.get_recv_data(trunk_id)
        
        log_info = u"模拟通道%d接收到的DTMF为:%s" % (trunk_id, dtmf_recv)
        log.user_info(log_info)
        
        return dtmf_recv
        
    def _clear_call_recv_data(self):
        """
        """
        for i in self.trunk_id_list:
            self.obj.clear_recv_data(i)
            
    def _get_fax_info(self, info):
        """
        ASCII
        """
        #Receive Fax EvtState = %d, EvtErrCode = %d, ErrStep = %d,
        #T30SendState = %d, TotalPages = %d, RemoteID = %d
        ls =  info.split(",")
        errcode = -1
        errstep = -1
        pages = -1
        for item in ls:
            if "EvtErrCode" in item:                
                errcode = filter(lambda x:x.isdigit(),item)
            if "ErrStep" in item:                
                errstep = filter(lambda x:x.isdigit(),item)
            if "TotalPages" in item:                
                pages = filter(lambda x:x.isdigit(),item)
                
        return int(errcode),int(errstep),int(pages)
    
    def _get_code_meaning(self,errcode,errstep):
        """
        获取code值对应的意义
        """
        code_info = u""
        step_info = u""
        #
        errcode_dict = {}
        errcode_dict[0] = u"T30_COMPLETE_SUCCESS"
        errcode_dict[1] = u"T30_PRESTOP_BY_REMOTE"
        errcode_dict[2] = u"T30_PRESTOP_BY_LOCAL"
        errcode_dict[3] = u"T30_NOT_FAX_TERMINAL"
        errcode_dict[4] = u"T30_NOT_COMPATIBLE_FAX_TERMINAL"
        errcode_dict[5] = u"T30_BAD_SIGNAL_CONDITION"
        errcode_dict[6] = u"T30_PROTOCOL_ERROR"
        errcode_dict[7] = u"T30_PROTOCOL_ERROR_TIMEOUT"
        errcode_dict[8] = u"T30_FLOW_REQ_CLEAN_ERROR"
        errcode_dict[9] = u"T30_NOT_RECEIVE_MEDIA_DATA"
        #define 7  //to detect the error is timeout or default----zcq
        #define 8  //not receive flow req clean
        
        code_info = errcode_dict.get(errcode, u"unkown" )
        #
        step_info = {}
        step_info[0] = u"T30_INIT"
        step_info[1] = u"T30_INIT_SEND_CED"
        step_info[2] = u"T30_SEND_CED"
        step_info[3] = u"T30_INIT_SEND_DIS"
        step_info[4] = u"T30_SEND_DIS"
        step_info[5] = u"T30_INIT_RECV_DCS"
        step_info[6] = u"T30_RECV_DCS"
        step_info[7] = u"T30_INIT_RECV_TCF"
        step_info[8] = u"T30_RECV_TCF"
        step_info[9] = u"T30_INIT_SEND_CFR"
        step_info[0x0A] = u"T30_SEND_CFR" #0x0A
        step_info[0x0B] = u"T30_INIT_SEND_FTT"
        step_info[0x0C] = u"T30_SEND_FTT"
        step_info[0x0D] = u"T30_INIT_RECV_PAGE"
        step_info[0x0E] = u"T30_RECV_PAGE"
        step_info[0x0F] = u"T30_INIT_RECV_EOP"
        step_info[0x10] = u"T30_RECV_EOP" #0x10
        step_info[0x11] = u"T30_INIT_SEND_MCF"
        step_info[0x12] = u"T30_SEND_MCF"
          
        step_info[0x15] = u"T30_INIT_POSTPAGE_REQ"
        step_info[0x16] = u"T30_POSTPAGE_REQ"
        
        #//TRANSMIT SIDE FAX STATE  0x40-0x7F
        step_info[0x40] = u"T30_INIT_RECV_DIS" # 	0x40
        step_info[0x41] = u"T30_RECV_DIS" #   		0x41
        step_info[0x42] = u"T30_INIT_SEND_DCS" #   	0x42
        step_info[0x43] = u"T30_SEND_DCS" #   		0x43
        step_info[0x44] = u"T30_INIT_SEND_TCF" #  	0x44
        step_info[0x45] = u"T30_SEND_TCF" #  		0x45
        step_info[0x46] = u"T30_INIT_RECV_CFR" #   	0x46
        step_info[0x47] = u"T30_RECV_CFR" # 	    0x47
        step_info[0x48] = u"T30_INIT_SEND_PAGE" #  	0x48
        step_info[0x49] = u"T30_SEND_PAGE" #   		0x49
        step_info[0x4A] = u"T30_INIT_SEND_EOP" # 	0x4A
        step_info[0x4B] = u"T30_SEND_EOP" # 	    0x4B
        step_info[0x4C] = u"T30_INIT_SEND_MPS" #   	0x4C
        step_info[0x4D] = u"T30_SEND_MPS" # 	    0x4D
        step_info[0x4E] = u"T30_INIT_SEND_EOM" #   	0x4E
        step_info[0x4F] = u"T30_SEND_EOM" # 	     0x4F
        step_info[0x50] = u"T30_INIT_RECV_MCF" # 	0x50
        step_info[0x51] = u"T30_RECV_MCF" #   		0x51
        step_info[0x52] = u"T30_INIT_PREPAGE_REQ" #	0x52
        step_info[0x53] = u"T30_PREPAGE_REQ" #			0x53
        step_info[0x54] = u"T30_INIT_PAGE_REQ" #		0x54
        step_info[0x55] = u"T30_PAGE_REQ" #			0x55
        step_info[0x56] = u"T30_INIT_SEND_CNG" #		0x56
        step_info[0x57] = u"T30_SEND_CNG" #			0x57
        step_info[0x58] = u"T30_RECV_MCF_CLEAN" #     0x58
        step_info[0x59] = u"T30_INIT_RECV_PREDIS" # 	0x59
        step_info[0x6A] = u"T30_RECV_PREDIS" #  		0x6A
        step_info[0x6B] = u"T30_TIFF_CAHANGE_COMMAND" #  0x6B  
        step_info[0x6C] = u"T30_TIFF_CAHANGE_FINISH" #   0x6C
        step_info[0x6E] = u"T30_PRE_SEND_PAGE" #          0x6E
        step_info = step_info.get(errstep, u"unkown" )        
            
        return code_info,step_info
       
    def send_fax(self, trunk_id, sendfiles_list, bps_int, seconds, recordfile_send, recordfile_recv):
        """
        """ 
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        #check  b state            
        if (VOIP_FUN_OK != self.obj.send_fax_prepare(trunk_id)):
            log_info = u"模拟通道%准备传真设备失败" % trunk_id
            raise RuntimeError(log_info)
        
        firstfile = ""
        if (isinstance(sendfiles_list, list)):                    
            #添加文件
            for index in range(len(sendfiles_list)):
                if index == 0:
                    firstfile = sendfiles_list[index]
                    log_info = u"模拟通道%d准备发送传真文件%s, 速率设置为%d bps" % (trunk_id, firstfile, bps_int)
                    log.user_info(log_info)
                    continue
                
                if (VOIP_FUN_OK == self.obj.set_fax_file(trunk_id, sendfiles_list[index])):
                    log_info = u"添加待传的传真文件%s成功" % (sendfiles_list[index])
                    log.user_info(log_info)                    
                else:
                    log_info = u"添加待传的传真文件%s失败" % (sendfiles_list[index])
                    raise RuntimeError(log_info)
        else:
            firstfile = sendfiles_list
            log_info = u"模拟通道%d准备发送传真文件%s，速率设置为%d bps" % (trunk_id, firstfile, bps_int)
            log.user_info(log_info) 
        
        state,info = self.obj.send_fax(trunk_id, firstfile, bps_int, seconds, recordfile_send, recordfile_recv)
        
        ierrcode,ierrstep,ipages = self._get_fax_info(info)
        
        if (VOIP_FUN_OK == state):
            log_info = u"模拟通道%d发送传真成功,发送页数为%d。" % (trunk_id, ipages)
            log.user_info(log_info)
        else:
            log_info = u"模拟通道%d发送传真失败。" % trunk_id
            #
            c,s = self._get_code_meaning(ierrcode,ierrstep)        
            err_info = u"失败信息：%s，失败步骤：%s，传真页数：%d" %(c,s,ipages)
            log_info += err_info
            raise RuntimeError(log_info)
        
        return ipages
    
    def start_recv_fax(self, trunk_id, savefile, bps_int, recordfile_send, recordfile_recv):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK != self.obj.recv_fax_prepare(trunk_id)):
            log_info = u"模拟通道%d准备传真设备失败" % trunk_id
            raise RuntimeError(log_info)   
        
        if (VOIP_FUN_OK == self.obj.start_recv_fax(trunk_id, savefile, bps_int, recordfile_send, recordfile_recv)):
            log_info = u"模拟通道%d准备接收传真，速率设置为%d bps, 传真文件将保持到%s" % (trunk_id, bps_int, savefile)
            log.user_info(log_info)
            #update state
            phone.set_state(_PHONESTATE.S_RECV_FAX_START)
        else:
            log_info = u"模拟通道%d准备接收传真失败" % trunk_id
            raise RuntimeError(log_info)       
        
    
    def get_recv_fax_result(self, trunk_id, seconds):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_RECV_FAX_START]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        state,info = self.obj.get_recv_fax_result(trunk_id, seconds)
        
        ierrcode,ierrstep,ipages = self._get_fax_info(info)
           
        if (VOIP_FUN_OK == state):
            log_info = u"模拟通道%d接收传真成功，接收页数为%d。" % (trunk_id,ipages)
            log.user_info(log_info)
            #update state
            phone.set_state(_PHONESTATE.S_IN_CALL)
        else:
            #update state
            phone.set_state(_PHONESTATE.S_IN_CALL)
            log_info = u"模拟通道%d接收传真失败。" % trunk_id
            #
            c,s = self._get_code_meaning(ierrcode,ierrstep)        
            err_info = u"失败信息：%s，失败步骤：%s，传真页数：%d" %(c,s,ipages)
            log_info += err_info            
            raise RuntimeError(log_info)
        return ipages
    
    def check_call_in(self, trunk_id, seconds):
        """
        """    
        phone = self._get_trunk_config_info(trunk_id)
          
        #check state
        if phone.get_state() not in [_PHONESTATE.S_NONE,_PHONESTATE.S_INIT, _PHONESTATE.S_ONHOOK, _PHONESTATE.S_CLEAR_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK == self.obj.check_call_in(trunk_id, seconds)):
            log_info = u"模拟通道%d有呼入" % trunk_id
            log.user_info(log_info)
            #update state
            phone.set_state(_PHONESTATE.S_CHECK_CALL_IN)
        else:
            log_info = u"模拟通道%d在%d秒内无呼入" % (trunk_id, seconds)
            raise RuntimeError(log_info)      
    
    def call_in_offhook(self, trunk_id):
        """
        """    
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_CHECK_CALL_IN]:
            log_info = u"当前状态不能进行该操作，请先检查是否有电话呼入" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK == self.obj.call_in_off_hook(trunk_id)):
            log_info = u"模拟通道%d摘机成功" % trunk_id
            log.user_info(log_info)
            #update state
            phone.set_state(_PHONESTATE.S_IN_CALL)
        else:
            log_info = u"模拟通道%d摘机失败" % trunk_id
            raise RuntimeError(log_info)      
        
    def onhook(self, trunk_id):
        """
        """       
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() in [_PHONESTATE.S_NONE,_PHONESTATE.S_INIT,_PHONESTATE.S_CHECK_CALL_IN,_PHONESTATE.S_ONHOOK, _PHONESTATE.S_CLEAR_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK == self.obj.on_hook(trunk_id)):
            log_info = u"模拟通道%d挂机成功" % trunk_id
            log.user_info(log_info)
            #update state
            phone.set_state(_PHONESTATE.S_ONHOOK)
        else:
            log_info = u"模拟通道%d挂机失败" % trunk_id
            raise RuntimeError(log_info)
        
    def hook_flash(self, trunk_id):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        if phone.get_state() not in [_PHONESTATE.S_IN_CALL]:
            log_info = u"当前状态不能进行该操作，请检查关键字使用流程是否正确" 
            raise RuntimeError(log_info)
        
        if (VOIP_FUN_OK == self.obj.set_flash(trunk_id)):
            log_info = u"模拟通道%d拍叉成功" % trunk_id
            log.user_info(log_info)
            #update state
            #phone.set_state(_PHONESTATE.s_HOOK_FLASH)
        else:
            log_info = u"模拟通道%d拍叉失败" % trunk_id
            raise RuntimeError(log_info)
        
    def set_flash_time(self, times):
        """
        """
        #phone = self._get_trunk_config_info(trunk_id)
        #check state
        #not
        
        if (VOIP_FUN_OK == self.obj.set_flash_time(times)):
            log_info = u"设置拍叉时间为%d ms成功" % (times*20)
            log.user_info(log_info)
            #update state
            #not
        else:
            log_info = u"设置拍叉时间为%d ms失败" % (times*20)
            raise RuntimeError(log_info)
        
    def wait_some_tone(self, trunk_id, tone_name, tone_key, times):
        """
        """
        phone = self._get_trunk_config_info(trunk_id)
        #check state
        #all
        if (VOIP_FUN_OK == self.obj.wait_some_tone(trunk_id, tone_key, times)):  #trunk_id, sTone, milliseconds):
            log_info = u"模拟通道%d检测到%s音" % (trunk_id, tone_name)
            log.user_info(log_info)
            #update state
            #not
            return True
        else:
            log_info = u"模拟通道%d在%d秒内未检测到%s音" % (trunk_id, times, tone_name)
            log.user_info(log_info)
            #raise RuntimeError(log_info) #20131018功能不OK， 暂不报错
            
            return False
        
    def update_tones_set(self):
        """
        """
        #phone = self._get_trunk_config_info(trunk_id)
        #check state
        #not
        
        if (VOIP_FUN_OK == self.obj.update_tones_set()):
            log_info = u"更新待检测音配置到底层服务成功" 
            log.user_info(log_info)
            #update state
            #not
        else:
            log_info = u"更新待检测音配置到底层服务失败" 
            raise RuntimeError(log_info)
            
    
    def start_record(self, trunk_id, savefile):
        """
        """
        if (VOIP_FUN_OK == self.obj.start_record(trunk_id, savefile)):
            log_info = u"模拟通道%d 启动录音成功，保存路径为 %s" % (trunk_id, savefile)
            log.user_info(log_info)
        else:
            log_info = u"模拟通道%d 启动录音失败" % trunk_id
            log.user_info(log_info)
    
    def stop_record(self, trunk_id):
        """
        """
        if (VOIP_FUN_OK == self.obj.stop_record(trunk_id)):
            log_info = u"模拟通道%d 停止录音成功" % trunk_id
            log.user_info(log_info)
        else:
            log_info = u"模拟通道%d 停止录音失败" % trunk_id
            log.user_info(log_info)
            
def Test():
    v = ATTVoip(2)
    pass
          
if __name__ == '__main__':
    Test()
    
    