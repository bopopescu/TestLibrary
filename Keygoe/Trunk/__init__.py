# -*- coding: utf-8 -*- 


#加载测试库依赖的平台模块
from robot.errors import DataError

#测试库远端属性客户端
#from robot.libraries.Remote import Remote
#测试库远端属性服务端
#from robotremoteserver import RobotRemoteServer

#加载测试库依赖平台公共接口
import attlog as log
from attcommonfun import *


#加载测试库继承基类模块
#from TestlibraryBaseCache import TestlibraryBaseCache, No_Cache_Exception

#加载测试库底层功能实现模块
from ATTVoip import ATTVoip,AttToneConfig

#加载其他
import os
import sys
import time

class Keygoe(): 
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = '1.0.0'
    
    def __init__(self):
        """
        初始化资源
        """
        self.att_voip = None  #keygoe系统实例
        self.att_tone_config = None
        self.remote_url = None
        #配置限制
        self.dict= {}
        self.dict["DIAL_TONE"] = "G"
        self.dict["BUSY_TONE"] = "H"
        self.dict["HOWLER_TONE"] = "I" #嗥鸣音
        self.dict["WAITING_TONE"] = "J"
        self.dict["RINGING_TONE"] = "K"
        self.dict["SECOND_DIAL_TONE"] = "L"
        self.dict["CONGESTION_TONE"] = "M"   
        self.dict["NUMBER_UNOBTAINABLE_TONE"] = "N"         
        
    def _check_trunk_index(self, trunk_id):
        """
        检查输入， 并转换为int
        """
        try:
            trunk_id = int(trunk_id)
            if (trunk_id < 1 or trunk_id > 16):                
                raise ValueError
        except Exception, e:
            raise RuntimeError(u"trunk_id输入错误，请输入[1,16]的整数")
        
        return trunk_id
    
    def _check_bps(self, bps_int):
        """
        检查输入， 并转换为int
        """
        try:
            bps_int = int(bps_int)
            if bps_int not in [2400, 4800, 7200, 9600, 12000, 14400]:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"bps_int设置错误")
        
        return bps_int
    
    def _check_fax_file(self, sendfiles_list):
        """
        检查输入，文件是否存在
        """
        if not isinstance(sendfiles_list, list):
            sendfiles_list = [sendfiles_list]
        
        for index in range(len(sendfiles_list)):
            if isinstance(sendfiles_list[index], unicode):
                try:
                    t = sendfiles_list[index].encode("ASCII")
                except Exception:
                    log_info = u"路径参数输入错误，目前只支持ASCII码字符"
                    raise RuntimeError(log_info)
                #检查文件是否存在
                if not os.path.isfile(sendfiles_list[index]):
                    log_info = u"要发送的文件%s不存在" % sendfiles_list[index]
                    raise RuntimeError(log_info)

    def _check_save_filename(self, filename, endwith_tuple=()):
        """
        检查输入的保存路径
        """        
        if isinstance(filename, unicode):
            try:
                t = filename.encode("ASCII")
            except Exception:
                log_info = u"路径参数输入错误，目前只支持ASCII码字符"
                raise RuntimeError(log_info)
            
        if  isinstance(endwith_tuple, tuple):
            if len(endwith_tuple) > 0:
                if not filename.lower().endswith(endwith_tuple):
                    log_info = u"文件后缀名输入错误，请按照参数描述输入正确的后缀名。"
                    raise RuntimeError(log_info)
        
        #如果目录不存在则创建
        path = os.path.dirname(filename)
        if not os.path.isdir(path):
            try :
                os.makedirs(path)
            except Exception:
                raise Exception(u"创建目录失败，请检查输入的目录是否正确")  

    def keygoe_set_tone_to_inifile(self,
                                   tone_name,
                                   freq,
                                   envelopemode,
                                   ontime1,
                                   offtime1=0,
                                   ontime2=0,
                                   offtime2=0,
                                   timedeviation=10):
        """        
        功能描述：配置待检测音到配置文件；
        
        参数:
        
            tone_name : 待检测音的名称。
            
            取值范围["Dial_Tone"，"Busy_Tone"，"Howler_Tone"，"Waiting_Tone"，"Ringing_Tone"，
            "Second_Dial_Tone"，"Congestion_Tone"，"Number_Unobtainable_Tone"]
            
            freq : 频率, 取值范围[300, 3400]
            
            envelopemode :包络类型，取值范围[0,1,2]
            
            ontime1/ontime2：持续时间,单位毫秒, 取值范围[100, 5000]
            
            offtime1/offtime2 ：间断时间, 单位毫秒,取值范围[100,5000]
            
            timedeviation ：时间误差百分比, 取值范围[0,30]
            
        说明：
        
            1）envelopemode:用来描述待检测音模型，各取值意义如下：
            
            0: 表示是持续音。持续响ontime1毫秒(当时持续响铃声，输入的ontime1不能小于其他OnTime，以防被包含)
            
            1: 表示是一次响停音。响ontime1毫秒、停offtime1毫秒
            
            2: 表示是二次响停音。响ontime1毫秒、停offtime1毫秒，再响ontime2毫秒、停offtime2毫秒
            
            2）timedeviation: 用来描述持续时间和间断时间的一个范围，当包络类型为1和2的时候生效。计算公式如下：
            
            Min_ontime1 = (OnTime * ((100 - timedeviation) / 100))
            
            Max_ontime1 = (OnTime * ((100 + timedeviation) / 100))
            
            Min_offtime1 = (OffTime * ((100 - timedeviation) / 100))
            
            Max_offtime1 = (OffTime * ((100 + timedeviation) / 100))
            
            Min_ontime2,Max_ontime2,Min_offtime2,Max_offtime2同上。
            
            2）该关键字只会更新配置文件中的待检测音配置，不会立即更新到底层服务。故，
            
            要么在connect_keygoe_system之前完成所有音的配置，
            
            要么在完成所有音的配置后调用关键字keygoe_update_tones_config。
            
            3）请尽量避免配置的待检测音之间存在包含关系。包含关系举例：
            
            声音A、B频率一样，且A：envelopemode=0，ontime1=300；B：envelopemode=1，ontime1=350，offtime1=350；
            
            当检测到声音B时，一定会检测到声音B，因为A包含于B。
            
            4）当前默认配置如下：
            
            Dial_Tone:
            freq = 450;
            envelopemode = 0;
            on_time1 = 500;
            timedeviation = 10;
            
            Busy_Tone:
            freq = 450;
            envelopemode = 1;
            on_time1 = 350;
            off_time1 = 350;
            timedeviation = 10;
            
            Howler_Tone:
            freq = 950;
            envelopemode = 0;
            on_time1 = 500;
            timedeviation = 10;
            
            Waiting_Tone:
            freq = 450;
            envelopemode = 1;
            on_time1 = 400;
            off_time1 = 4000;
            timedeviation = 10;
            
            Ringing_Tone:
            freq = 450;
            envelopemode = 1;
            on_time1 = 1000;
            off_time1 = 4000;
            timedeviation = 10;
            
            Second_Dial_Tone:
            freq = 450;
            envelopemode = 0;
            on_time1 = 300;
            timedeviation = 10;
            
            Congestion_Tone:
            freq = 450;
            envelopemode = 1;
            on_time1 = 700;
            off_time1 = 700;
            timedeviation = 10;
            
            Number_Unobtainable_Tone:
            freq = 450;
            envelopemode = 2;
            on_time1 = 100;
            off_time1 = 100;
            on_time2 = 400;
            off_time2 = 400;
            timedeviation = 10;
            
        Example:
        | Keygoe Set Tone To Inifile | Dial_Tone |  450  | 0 | 1000 | timedeviation=10 |
        | Keygoe Set Tone To Inifile | Busy_Tone |  450  | 1 | 350 |350 | timedeviation=10 |
        | Keygoe Set Tone To Inifile | Number_Unobtainable_Tone |  450  | 2 | 100 | 100 | 400 | 400 | timedeviation=10 |
        """
        if self.att_tone_config == None:
            self.att_tone_config = AttToneConfig()
        
        tone_key = ""        
        tone_name = tone_name.upper()
        if tone_name not in self.dict.keys():
            raise RuntimeError(u"tone_name输入错误.")
        else:
            tone_key = self.dict.get(tone_name)
            
        try:
            envelopemode = int(envelopemode)
            if (envelopemode < 0 or envelopemode > 2):                
                raise ValueError
        except Exception, e:
            raise RuntimeError(u"envelopemode输入错误，请输入[1,2,3]中的整数")

        try:
            freq = int(freq)
            if (freq < 300 or freq > 3400):                
                raise ValueError
        except Exception, e:
            raise RuntimeError(u"freq输入错误，请输入[300, 3400]的整数")
        
        try:
            ontime1 = int(ontime1)
            if (ontime1 < 100 or ontime1 > 5000):                
                raise ValueError
        except Exception, e:
            raise RuntimeError(u"ontime1输入错误，请输入[100, 5000]的整数")
        
        if envelopemode > 0:
            try:
                offtime1 = int(offtime1)
                if (offtime1 < 100 or offtime1 > 5000):                
                    raise ValueError
            except Exception, e:
                raise RuntimeError(u"offtime1输入错误，请输入[100,5000]的整数")
            
        if envelopemode == 2:
            try:
                ontime2 = int(ontime2)
                if (ontime2 < 100 or ontime2 > 5000):                
                    raise ValueError
            except Exception, e:
                raise RuntimeError(u"ontime2输入错误，请输入[100, 5000]的整数")
        
            try:
                offtime2 = int(offtime2)
                if (offtime2 < 100 or offtime2 > 5000):                
                    raise ValueError
            except Exception, e:
                raise RuntimeError(u"offtime2输入错误，请输入[100,5000]的整数")        
        try:
            timedeviation = int(timedeviation)
            if (timedeviation < 0 or timedeviation > 30):                
                raise ValueError
        except Exception, e:
            raise RuntimeError(u"timedeviation输入错误，请输入[0,30]的整数")
        
        if (is_remote(self.remote_url)):            
            """
            reallib = Remote(remote_url)
            reallib._client.set_timeout(REMOTE_TIMEOUT)
            auto_do_remote(reallib)
            """
            pass
        else:
            self.att_tone_config.config_some_tone(tone_key,
                                                  freq,
                                                  envelopemode,
                                                  ontime1, offtime1,
                                                  ontime2, offtime2,
                                                  timedeviation)
        
    
    def connect_keygoe_system(self,
                              server_ip,
                              port,
                              user_name,
                              password):#, remote_url=False):
        """
        功能描述：初始化语音卡设备, 连接底层服务；
        
        参数:
        
            server_ip: 语音卡底层服务的IP地址
            
            port: 语音卡底层服务的端口号
            
            user_name: 语音卡底层服务的系统用户名
            
            password: 语音卡底层服务的系统密码
            
        说明：
        
            不用重复连接、断开底层服务，可以把连接和断开底层服务关键字放在测试集的初始化和拆除中
        
        Example:
        | Connect Keygoe System	| 192.168.2.58 | 9000 | admin | admin |
        
        """         
        if self.att_voip != None:
            log_info = u"已经初始化，不用重复初始化系统"
            log.user_info(log_info)
            return       
        
        #参数检查
        if not check_ipaddr_validity(server_ip):
            raise RuntimeError(u"server_ip地址为非法地址!")        
        try:
            port = int(port)
        except Exception,e :
            raise RuntimeError(u"port输入错误!")
        
        if self.att_tone_config == None:
            self.att_tone_config = AttToneConfig()        
        self.att_tone_config.config_system_param(server_ip, port, user_name, password)
        
        if (is_remote(self.remote_url)):            
            """
            reallib = Remote(remote_url)
            reallib._client.set_timeout(REMOTE_TIMEOUT)
            auto_do_remote(reallib)
            """
            pass
        else:
            self.att_voip = ATTVoip()
            
    def disconnect_keygoe_system(self):
        """
        功能描述：关闭语音卡设备，断开底层服务。
        
        参数：
        
            无
        
        Example:
        | Connect Keygoe System	| 192.168.2.58 | 9000 | admin | admin |
        | Disconnect Keygoe System |         | 
        
        """       
        if self.att_voip == None:
            log_info = u"未初始化系统,不用退出"
            log.user_info(log_info)
            return
        
        self.att_voip.exit_keygoe_system()        
        self.att_voip = None
    
    def keygoe_reset_trunk(self, trunk_id):
        """
        功能描述：重置语音卡中的一个通道设备。
        
        参数：
        
            trunk_id :语音卡上模拟通道编号
        
        Example:
        | Keygoe Reset Trunk   |    1    |
        | Keygoe Reset Trunk   |    2    | 
        
        """       
        if self.att_voip == None:
            log_info = u"未初始化系统"
            return
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.reset_trunk(trunk_id)
            
    def keygoe_reset_all_trunk(self):
        """
        功能描述：重置语音卡中的前面使用过的通道设备。
        
        参数：
            
            无
        
        Example:        
        | Keygoe Reset All Trunk  |        |
        
        """       
        if self.att_voip == None:
            log_info = u"未初始化系统"
            return

        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.reset_all_trunk()   
        
            
    def keygoe_call_out_offhook(self, trunk_id):
        """
        功能描述：呼出拨号前的摘机操作。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
        
        Example:
        | Keygoe Reset All Trunk    |         |
        | Keygoe Call Out Offhook   |    1    | 
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.call_out_offhook(trunk_id)
    
    
    def keygoe_dial(self, trunk_id, phone_number):
        """
        功能描述：在模拟通道trunk_id上拨号给phone_number。用于摘机之后的拨号，和拍叉之后的拨号。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            phone_number :被叫号码
        
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Dial               |    1    |  1003 |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        if len(phone_number) < 3:
            raise RuntimeError (u"输入的号码太短")
        else:
            for item in phone_number:
                if item not in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "#", "A", "B", "C", "D"]:
                    raise RuntimeError (u"输入的号码格式有误")
            
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.dial_by_number(trunk_id, phone_number)
                
    def keygoe_send_dtmf(self, trunk_id, dtmf):
        """
        功能描述：发送DTMF，发送完成后返回。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            dtmf: DTMF字符串；
            
        说明：
        
            1、使用Keygoe Send Dtmf关键字发送DTMF码后，用Keygoe Get Recv Dtmf关键字接收DTMF码，
            可能存在丢号的情况（在接收端录音，发现是该DTMF码的波形损坏，导致语音卡没有识别）。
            
            2、由于网络等环境原因，丢号并不能判定通话功能异常，建议在用例中做丢号重发处理。
            
            3、可以使用keygoe Compare Dtmf关键字判断是否丢号。
            
        
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Check Dial Tone    |    1    |  
        | Keygoe Dial               |    1    |  1003 |
        | Keygoe Check Call In      |    2    |  5    |
        | Keygoe Call In Offhook    |    2    |
        | Keygoe Send Dtmf          |    1    | 56789*#  |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)            
        
        trunk_id = self._check_trunk_index(trunk_id)
            
        #检查dtmf
        for item in dtmf:
            if item not in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "#", "A", "B", "C", "D"]:
                raise RuntimeError (u"输入的数据不是DTMF码")            
        if len(dtmf) > 32:
            log_info = u"不支持大于32位的码串"
            raise RuntimeError(log_info)       
            
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.send_dtmf(trunk_id, dtmf)
            
    def keygoe_get_recv_dtmf(self, trunk_id):
        """
        功能描述：获取接收到的DTMF串。
        
        参数：
        
            trunk_id :语音卡上模拟通道编号
            
        返回值：
            
            字符串（DTMF串），没有接收到DTMF码，则返回空字符串
        
        Example:
        | Keygoe Send Dtmf  | 2	| 56789*#   | 
        | ${GetDtmf}        | Keygoe Get Recv Dtmf | 1	|
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            return self.att_voip.get_recv_dtmf(trunk_id)
        
    def keygoe_send_fax(self,
                        trunk_id,
                        sendfiles_list,
                        bps_int,
                        seconds=0,
                        recordfile_dir="",
                        recordfile_prefix=""):
        """
        功能描述：发送一个或多个传真文件，在发送结束后返回。若超过seconds还没发送完成则返回失败。
        
        参数：
        
            trunk_id :语音卡上模拟通道编号
            
            sendfiles_list: 一个tif文件全路径或多个tif文件全路径组成的列表，路径只支持ASCII码字符；
            
            bps_int: 发送速率,取值范围[2400, 4800, 7200, 9600, 12000, 14400]
            
            seconds: 预留发送的时间（秒），0表示没有超时限制
            
            recordfile_dir: 传真录音文件保存路径，只支持ASCII码字符，默认为空
            
            recordfile_prefix：录音文件名前缀，只支持ASCII码字符，默认为空
        
        说明：
        
            recordfile_dir为空时，表示不进行录音。不为空，举例如下：
            
            recordfile_dir 为 D:\\DIR，recordfile_prefix为 XXX，会生成
            发送通道录音 D:\\DIR\\XXX_SSChannel.wav，接收通道录音 D:\\DIR\\XXX_SRChannel.wav
            
        注意：
            
            先配置传真ECM功能使能。 配置方法：
            
            在keygoe系统配置界面，选择"Keygoe 系统"->"媒体"->"业务参数配置"->"功能参数配置"，
            将"传真ECM功能"项设置为"已使能“。
        
        返回值：
            
            发送的页数，类型为整型，发送成功时返回。
                  
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Dial               |    1    |  1003 |
        | Keygoe Check Call In      |    2    |  5    |
        | Keygoe Call In Offhook    |    2    |
        | Keygoe Start Recv Fax     |    1    | E:\\temp01.tif  | 9600  |
        | Keygoe Send Fax           |    2    | C:\\r21.tif     | 9600  | 60 |        
        | Keygoe Start Recv Fax     |    1    | E:\\temp02.tif  | 9600  |
        | ${list}                   | Create List | C:\\r21.tif | C:\\r22.tif |
        | Keygoe Send Fax           |    2    | ${list}         | 9600  | 60 |
        """        
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
              
        trunk_id = self._check_trunk_index(trunk_id)
        
        self._check_fax_file(sendfiles_list)
        
        bps_int = self._check_bps(bps_int)
        
        try:
            seconds = int(seconds)
            if seconds < 0:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"seconds设置错误，请输入大于等于零的整数")
        
        recordfile_send = ""
        recordfile_recv = ""
        if len(recordfile_dir) > 0:
            recordfile_send = os.path.join(recordfile_dir, recordfile_prefix + "_SSChannel.wav")
            self._check_save_filename(recordfile_send)
            recordfile_recv = os.path.join(recordfile_dir, recordfile_prefix + "_SRChannel.wav")
            self._check_save_filename(recordfile_recv)
            
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:            
            return self.att_voip.send_fax(trunk_id, sendfiles_list, bps_int, seconds, recordfile_send, recordfile_recv)
            
    def keygoe_start_recv_fax(self,
                              trunk_id,
                              faxfile,
                              bps_int,
                              recordfile_dir="",
                              recordfile_prefix=""):
        """
        功能描述：准备接收传真，并设置保存路径。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            faxfile：保存全路径, 只支持ASCII码字符
            
            bps_int: 传真速率，取值范围[2400, 4800, 7200, 9600, 12000, 14400]
            
            recordfile_dir: 传真录音文件保存路径，只支持ASCII码字符，默认为空
            
            recordfile_prefix：录音文件名前缀，只支持ASCII码字符，默认为空
        
        说明：
        
            recordfile_dir为空时，表示不进行录音。不为空，举例如下：
            
            recordfile_dir 为 D:\\DIR，recordfile_prefix为 XXX，会生成
            发送通道录音 D:\\DIR\\XXX_RSChannel.wav，接收通道录音 D:\\DIR\\XXX_RRChannel.wav
        
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Dial               |    1    |  1003 |
        | Keygoe Check Call In      |    2    |  5    |
        | Keygoe Call In Offhook    |    2    |
        | Keygoe Start Recv Fax     |    1    | E:\\temp01.tif  | 9600 |
        | Keygoe Send Fax           |    2    | E:\\temp.tif    | 9600 | 120 |        
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
              
        trunk_id = self._check_trunk_index(trunk_id)
        
        tup = (".tif",)
        self._check_save_filename(faxfile, tup)
        
        bps_int = self._check_bps(bps_int)
        
        recordfile_send = ""
        recordfile_recv = ""
        if len(recordfile_dir) > 0:
            recordfile_send = os.path.join(recordfile_dir, recordfile_prefix + "_RSChannel.wav")
            self._check_save_filename(recordfile_send)
            recordfile_recv = os.path.join(recordfile_dir, recordfile_prefix + "_RRChannel.wav")
            self._check_save_filename(recordfile_recv)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.start_recv_fax(trunk_id, faxfile, bps_int, recordfile_send, recordfile_recv)
        
    def keygoe_get_recv_fax_result(self, trunk_id, seconds=3):
        """
        功能描述：获取接收传真的结果。在seconds秒内检查到接收传真成功，则返回成功，否则异常。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            seconds ：预留时间（秒）,默认3秒
        
        返回值：
            
            接收的页数，类型为整型，接收成功时返回。
            
        Example:
        | Keygoe Start Recv Fax      |    1    | E:\\temp01.tif  | 9600 |
        | Keygoe Send Fax            |    2    | E:\\temp.tif    | 9600 | 120 |
        | Keygoe Get Recv Fax Result |    1    |
        
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        try:
            seconds = int(seconds)
            if seconds <= 0:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"seconds设置错误，请输入大于零的整数")
            
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            return self.att_voip.get_recv_fax_result(trunk_id, seconds)
        
        
    def keygoe_check_call_in(self, trunk_id, seconds):
        """
        功能描述：检查在seconds秒内是否有电话呼入。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            seconds ：预留时间（秒）
        
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Dial               |    1    |  1003 |
        | Keygoe Check Call In      |    2    |  5    |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
            
        try:
            seconds = int(seconds)
            if seconds <= 0:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"seconds设置错误，请输入大于零的整数")
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.check_call_in(trunk_id, seconds)
    
    def keygoe_call_in_offhook(self, trunk_id):
        """
        功能描述：摘机，当有电话呼入时调用。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
        
        Example:
        | Keygoe Call Out Offhook   |    1    | 
        | Keygoe Dial               |    1    |  1003 |
        | Keygoe Check Call In      |    2    |  5    |
        | Keygoe Call In Offhook    |    2    |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
           
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.call_in_offhook(trunk_id)
            
    def keygoe_onhook(self, trunk_id):
        """
        功能描述：挂机。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
        
        Example:
        | Keygoe Onhook	   | 1  |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
         
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.onhook(trunk_id)
            
    def keygoe_hook_flash(self, trunk_id):
        """
        功能描述：拍叉。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
        
        Example:
        | Keygoe Hook Flash   | 1  |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
         
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.hook_flash(trunk_id)
            
    def keygoe_set_hook_flash_time(self, times):
        """
        功能描述：设置拍叉簧时间。
        
        参数：
            
            times :拍叉簧时间，单位是20ms。
        
        Example:
        | Keygoe Set Hook Flash Time	   | 10 |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
          
        try:
            times = int(times)
            if times <= 0:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"times设置错误，请输入大于零的整数")
         
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.set_flash_time(times)
            
    def keygoe_wait_tone(self, trunk_id, tone_name, times):
        """
        功能描述：检测音。
        
        参数：
            
            trunk_id :语音卡上模拟通道编号
            
            tone_name : 待检测音的名称, 取值范围["Dial_Tone"，"Busy_Tone"，"Howler_Tone"，
            "Waiting_Tone"，"Ringing_Tone"，"Second_Dial_Tone"，"Congestion_Tone"，"Number_Unobtainable_Tone"]
            
            times :最长等待时间（秒）取值范围(0,300]。
            
        返回值：
            
            在times内检测到音，立即返回True，否则返回False
        
        Example:
        | ${result} | Keygoe Wait Tone  |  1  |  Dial_Tone  | 10 |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        tone_key = ""
        tone_name = tone_name.upper()
        if tone_name not in self.dict.keys():
            raise RuntimeError(u"tone_name输入错误.")
        else:
            tone_key = self.dict.get(tone_name)
            
        try:
            times = int(times)
            if times <= 0 or times > 300:
                raise ValueError
        except ValueError,e:
            raise RuntimeError(u"times设置错误，请输入(0,300]之间的整数。")
         
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            return self.att_voip.wait_some_tone(trunk_id, tone_name, tone_key, times)
        
    def keygoe_update_tones_from_inifile(self):
        """
        功能描述：读取配置文件，将检测音配置信息更新到底层服务。在配置完所有待检测的音之后，在摘机操作之前调用。
          
        参数：
            
            无
            
        返回值：
            
            无
        
        Example:        
        | Keygoe Set Tone To Inifile | Dial_Tone |  450  | 0 | 1000 | timedeviation=10 |
        | Keygoe Update Tones From Inifile |           |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.update_tones_set()
    
    
    def keygoe_start_record(self, trunk_id, recordfile):
        """
        功能描述：在某模拟通道中启动录音，并指定录音文件的保存路径。
        
        参数：
        
            trunk_id :语音卡上模拟通道编号
            
            recordfile: 录音文件的保存全路径，路径只支持ASCII码字符；后缀名只能是vox、pcm、wav。
            
        说明：
            
            只能摘机的状态下才能录音。不支持对传真录音。            
                
        返回值：
            
            无
        
        Example:  
        | Keygoe Start Record | 1 | D:\\keygoe.wav   |
        | Keygoe Send Dtmf    | 2 | 56789*#          | 
        | ${GetDtmf}          | Keygoe Get Recv Dtmf | 1 |
        | Keygoe Stop Record  | 1 |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
        
        tup = (".vox", ".pcm", ".wav",)
        self._check_save_filename(recordfile, tup)
        
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.start_record(trunk_id, recordfile)
            
            
    def keygoe_stop_record(self, trunk_id):
        """
        功能描述：在某模拟通道中停止录音。
        
        参数：
        
            trunk_id :语音卡上模拟通道编号
            
        说明：
            
            只能摘机的状态下才能录音。
            
        返回值：
            
            无
        
        Example:
        | Keygoe Start Record | 1 | D:\\keygoe.wav   |
        | Keygoe Send Dtmf    | 2 | 56789*#          | 
        | ${GetDtmf}          | Keygoe Get Recv Dtmf | 1 |
        | Keygoe Stop Record  | 1 |
        
        """
        if self.att_voip == None:
            log_info = u"请先初始化系统"
            raise RuntimeError(log_info)
        
        trunk_id = self._check_trunk_index(trunk_id)
         
        if (is_remote(self.remote_url)):
            #TODO
            pass
        else:
            self.att_voip.stop_record(trunk_id)
            
    def keygoe_compare_dtmf(self, send_dtmf, recv_dtmf, lost_count=0):
        """
        功能描述：比较发送的DTMF码和接收到的DTMF码， lost_count表示可以丢号个数。
        
        参数：
        
            send_dtmf :发送方SEND的DTMF码
            
            recv_dtmf :接收方RECV的DTMF码
            
            lost_count :允许丢号个数，默认为0，取值范围[0,4]
            
        说明：
            
            lost_count为n，表示允许丢n个DTMF码。例，lost_count = 2，send_dtmf = "1234"，
            则recv_dtmf in {"1234", "123", "124", "134", "234", "12", "13", "14", "23", "24", "34"}
            都是符合要求的，返回True
            
        返回值：
            
            丢号情况满足要求则返回True，否则返回False
        
        Example:
        | Keygoe Start Record | 1 | D:\\keygoe.wav   |
        | Keygoe Send Dtmf    | 2 | 56789*#          | 
        | ${GetDtmf}          | Keygoe Get Recv Dtmf | 1 |
        | ${ret}              | keygoe Compare Dtmf  | 56789*# | ${GetDtmf} | 1 |
        | Keygoe Stop Record  | 1 |
        
        """
        if lost_count == "" or lost_count == None:
            lost_count = 0
            
        try:
            lost_count = int(lost_count)
            if (lost_count < 0 or lost_count > 4):                
                raise ValueError
        except Exception, e:
            #raise RuntimeError(u"trunk_id输入错误，请输入[1,16]的整数")
            lost_count = 0  #异常默认采用1
            
        send_len = len(send_dtmf)
        recv_len = len(recv_dtmf)
        if send_len > (recv_len + lost_count): #长度不足
            return False
        
        if send_len < recv_len: #长度超过
            return False
        
        r = 0
        for s in range(send_len):
            if recv_dtmf[r] == send_dtmf[s]:
                #相同
                r += 1
                if (r == recv_len): #recv遍历完成
                    return True
            else:
                #不同 丢一个 s增 r不增
                lost_count -= 1  
                if lost_count < 0: #丢号个数超过了
                    return False
                
        return True
        

    
if __name__ == '__main__':
    #test()
    
    k = Keygoe()
    for rm in {"1234", "123", "124", "134", "2345", "21", "12", "13", "14", "23", "2", "34343434"}:
        print rm
        print k.keygoe_compare_dtmf("1234", rm, 8)
    pass

