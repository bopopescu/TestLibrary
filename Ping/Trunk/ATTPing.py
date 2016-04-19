# -*- coding: UTF-8 -*-

import sys
import os
from os.path import join, dirname,isfile,getsize,exists
import time
import multiprocessing
import select
import binascii
import math
import subprocess
import re
import tempfile
import attlog as log
import attcommonfun
from initapp import ATTROBOT_TEMP_FILE_PAHT

PING_SUCCESS = 0
PING_FAIL = -1
ICMP_DATA_STR = 32

EXECUTE_PATH = dirname(dirname(dirname(__file__)))
EXE_PATH = join(EXECUTE_PATH, "plugin","Ping","resource","ping.exe")

# modify by shenlige 针对偶现的临时文件目录生成失败的问题，在内部多加一个check处理 2013-7-9
try:
    if not exists(ATTROBOT_TEMP_FILE_PAHT):
        os.makedirs(ATTROBOT_TEMP_FILE_PAHT)
    PING_TMP_FILE = os.path.join(ATTROBOT_TEMP_FILE_PAHT,"ping_temp_file.txt")
except Exception,e:
    log_data = u"生成平台的临时目录发生错误： %s" % e
    raise RuntimeError(log_data)


class ATTPing():

    def __init__(self):
        
        self.dict_process_obj = {}
    
    # 丢包率参数入参检查接口 add by shenlige 2013-4-27
    def _check_percent_lost_para (self,success_percent_lost):
        """
        对丢包率参数做入参检查
        """
        try:
            success_percent_lost = float(success_percent_lost)
        except Exception,e:
            log_data = u"输入的丢包率格式有误，必须为可转成数字的字符串"
            log.app_err(log_data)
            raise RuntimeError(log_data)
        
        if success_percent_lost <= 100 and success_percent_lost >= 0:
            pass
        else:
            log_data = u"输入的丢包率有误，必须在[0,100]之间"
            log.app_err(log_data)
            raise RuntimeError(log_data)
        
        return success_percent_lost
    
    def _check_ping_para(self,psize,count,total_time):
        """
        对ping命令参数做入参检查
        """
        try:
            # 类型转换，防止从robot框架传进来的参数为字符串类型 modify by shenlige 2013-3-16
            psize = int(psize)
        except Exception, e:
            log_data = u"输入的包长参数psize： %s 有误，需为有效的数字" % psize
            raise RuntimeError(log_data)
                    
        if psize < 0 or psize > 65500:
                log_data = u"包长psize的大小应在0到65500字节之间"
                raise RuntimeError(log_data)
        
        try:
            if count:
                count = int(count)
        except Exception, e:
            log_data = u"输入的ping次数参数count： %s 有误，需为有效的数字" % count
            raise RuntimeError(log_data)
        
        # ping 的最大次数与按时间ping时保持一致
        if count:
            if count < 0 or count > 2592000:
                log_data = u"输入的ping次数有误，需为[0-2592000]之间的数字"
                raise RuntimeError(log_data)
        
        try:
            if total_time:    
                total_time = float(total_time)
            
        except Exception, e:
            log_data = u"输入的时间参数 %s 有误需为有效的数字" % total_time
            raise RuntimeError(log_data)
                    
        # 将ping的最长时间改为30天，即2592000秒
        # modify by shenlige 2013-6-26
        if total_time:
            if total_time < 0 or total_time > 2592000:
                log_data = u"输入的ping时间有误，需为[0-2592000]之间的数字"
                raise RuntimeError(log_data)
        
        return psize,count,total_time
    
    def _ping_by_time(self, ip_url, total_time = 120, psize = 32, success_percent_lost = 50):
        """根据时间ping，默认ping时长120秒，ICMP数据长度为32，丢包率小于 'success_percent_lost'%既成功，成功返回1，失败返回0。"""
        
        if psize == "":
            psize = 32        
        if total_time == "":
            total_time = 120
        if success_percent_lost == "":
            success_percent_lost = 50
        
        success_percent_lost = self._check_percent_lost_para(success_percent_lost)
        
        psize,count,total_time = self._check_ping_para(psize,None,total_time)
            
        percent_lost = pingNode(node=ip_url, total_time=total_time, size=psize)
        #log_data = u'测试丢包率为：%.3f%% ，最大时延为：%.3f 毫秒，平均时延为：%.3f 毫秒'% (percent_lost, max_round_trip, avg_round_trip)
        #log.user_info(log_data)
        if percent_lost <= success_percent_lost:
            # 丢包率小于50%（即成功率大于50%）认为成功；
            return 1,total_time,psize
        else:
            return 0,total_time,psize

    def _ping_by_count(self, ip_url, count = 10, psize = 32, success_percent_lost = 50):
        """根据次数ping，默认ping 10 次，ICMP数据长度为32，丢包率小于 'success_percent_lost'%既成功，成功返回1，失败返回0。"""
        
        if count == "":
            count = 10
        if success_percent_lost == "":
            success_percent_lost = 50
        if psize == "":
            psize = 32
             
        success_percent_lost = self._check_percent_lost_para(success_percent_lost)
        
        psize,count,total_time = self._check_ping_para(psize,count,None)

        percent_lost = pingNode(node=ip_url, number=count, size=psize)
        #log_data = u'测试丢包率为：%.3f%% ，最大时延为：%.3f 毫秒，平均时延为：%.3f 毫秒'% (percent_lost, max_round_trip, avg_round_trip)
        #log.user_info(log_data)
        if percent_lost <= success_percent_lost:
            # 丢包率小于50%（即成功率大于50%）认为成功；
            return 1,count,psize
        else:
            return 0,count,psize
        
    def _pingprocess_by_time(self, ip_url, total_time = 3600, psize = 32):
        """子进程中持续ping，ICMP包长默认为32，默认时间为3600秒"""
        
        if psize == "":
            psize = 32        
        if total_time == "":
            total_time = 3600
        
        psize,count,total_time = self._check_ping_para(psize,None,total_time)
            
        ret = PING_SUCCESS
        counter = 0
        
        for i in [1]:
            try:
                pid = PingProcess(node=ip_url, total_time = total_time, size=psize)
                pid.start()
                        
            except Exception, e:
                err_info = "Starting PingProcess Error:%s" % e
                ret_data = err_info
                log.user_err(ret_data)
                ret = PING_FAIL
                break                
            
            # 修改偶现长时间临时文件生成失败的问题，这里延长等待时间
            # modify by shenlige 2014-1-13
            while not isfile(pid.get_ping_tmp_file()) and counter < 120:
                # 等待ping文件正常生成，这里默认等待15秒，若超过15秒则报错退出  modify by shenlige 2013-4-9
                time.sleep(1)
                counter += 1
            
            if counter >= 120:
                ret_data = u"等待120s后，进程执行ping还是存在异常，请确认"
                log.user_err(ret_data)
                ret = PING_FAIL
                break
            
            # wait a moment to check whether the ping pid is ok
            if not pid.is_alive:
                ret_data = pid.err_info
                ret = PING_FAIL
        
        if ret == PING_FAIL:
            raise RuntimeError(ret_data)
            
        return ret,pid
        

    def should_ping_ipv4_success_by_time(self, ip_url, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ip_url'，持续'total_time'秒，丢包率小于 'success_percent_lost'%既成功，应Ping成功。
        """
        
        ret,total_time,psize = self._ping_by_time(ip_url, total_time, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping成功" % \
                                (psize, ip_url, total_time)
            log.user_info(log_data)
        else:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping失败，应Ping成功" % \
                                (psize, ip_url, total_time)
            log.user_info(log_data)
            raise RuntimeError(log_data)
            
    def should_ping_ipv4_fail_by_time(self, ip_url, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ip_url'，持续'total_time'秒，丢包率小于 'success_percent_lost'%既成功，应Ping失败。
        """
     
        ret,total_time,psize = self._ping_by_time(ip_url, total_time, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping成功，应Ping失败" % \
                                (psize, ip_url, total_time)
            log.user_info(log_data)
            raise RuntimeError(log_data)
        else:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping失败" % \
                                (psize, ip_url, total_time)
            log.user_info(log_data)
            
    def should_ping_ipv4_success_by_count(self, ip_url, count = 10, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ip_url'，持续'count'次，丢包率小于 'success_percent_lost'%既成功，应Ping成功。
        """
        ret,count,psize = self._ping_by_count(ip_url, count, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping成功" % \
                                (psize, ip_url, count)
            log.user_info(log_data)
        else:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping失败，应Ping成功" % \
                                (psize, ip_url, count)
            log.user_info(log_data)
            raise RuntimeError(log_data)
            
    def should_ping_ipv4_fail_by_count(self, ip_url, count = 10, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ip_url'，持续'count'次，丢包率小于 'success_percent_lost'%既成功，应Ping失败。
        """   
        ret,count,psize = self._ping_by_count(ip_url, count, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping成功，应Ping失败" % \
                                (psize, ip_url, count)
            log.user_info(log_data)
            raise RuntimeError(log_data)
        else:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping失败" % \
                                (psize, ip_url, count)
            log.user_info(log_data)

    def should_ping_ipv6_success_by_time(self, ipv6_url, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包'ipv6_url'，持续'total_time'秒，丢包率小于 'success_percent_lost'%既成功，应Ping成功。
        """
        ret,total_time,psize = self._ping_by_time(ipv6_url, total_time, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping成功" % \
                                (psize, ipv6_url, total_time)
            log.user_info(log_data)
        else:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping失败，应Ping成功" % \
                                (psize, ipv6_url, total_time)
            log.user_info(log_data)
            raise RuntimeError(log_data)
         
            
    def should_ping_ipv6_fail_by_time(self, ipv6_url, total_time = 120, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ipv6_url'，持续'total_time'秒，丢包率小于 'success_percent_lost'%既成功，应Ping失败。
        """
        ret,total_time,psize = self._ping_by_time(ipv6_url, total_time, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping成功，应Ping失败" % \
                                (psize, ipv6_url, total_time)
            log.user_info(log_data)
            raise RuntimeError(log_data)
        else:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'秒，Ping失败" % \
                                (psize, ipv6_url, total_time)
            log.user_info(log_data)
            
    def should_ping_ipv6_success_by_count(self, ipv6_url, count = 10, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ipv6_url'，持续'count'次，丢包率小于 'success_percent_lost'%既成功，应Ping成功。
        """
        ret,count,psize = self._ping_by_count(ipv6_url, count, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping成功" % \
                                (psize, ipv6_url, count)
            log.user_info(log_data)
        else:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping失败，应Ping成功" % \
                                (psize, ipv6_url, count)
            log.user_info(log_data)
            raise RuntimeError(log_data)
            
    def should_ping_ipv6_fail_by_count(self, ipv6_url, count = 10, psize = 32, success_percent_lost = 50):
        """
        采用包长为'psize'的数据包Ping地址'ipv6_url'，持续'count'次，丢包率小于 'success_percent_lost'%既成功，应Ping失败。
        """
        ret,count,psize = self._ping_by_count(ipv6_url, count, psize, success_percent_lost)
        if ret == 1:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping成功，应Ping失败" % \
                                (psize, ipv6_url, count)
            log.user_info(log_data)
            raise RuntimeError(log_data)
        else:
            log_data = u"采用ICMPv6数据字段长度为'%s'的数据包Ping地址'%s'，持续'%s'次，Ping失败" % \
                                (psize, ipv6_url, count)
            log.user_info(log_data)
    
 
    def start_ping_ipv4(self, ip_url, total_time = 3600, psize = 32):
        """
        采用包长为'psize'的数据包Ping地址'ip_url'，调用进程执行ping 命令，持续'total_time'秒。
        """
        
        if psize == "":
            psize = 32        
        if total_time == "":
            total_time = 3600
        
        ret,pid = self._pingprocess_by_time(ip_url,total_time,psize)
        str_pid = str(pid)
        tmp_pro_dict = {str_pid:pid}
        self.dict_process_obj.update(tmp_pro_dict)
        
        if ret == PING_SUCCESS:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，ping命令后台执行,后续可调用关键字来停止ping命令的执行并获取ping结果，否则将持续ping %s 秒。" % \
                       (psize, ip_url, total_time)
            log.user_info(log_data)
            return  str_pid
        else:
            log_data = u"ping命令后台执行失败。"
            log.user_info(log_data)
            raise RuntimeError(log_data)
            
                
       
    def start_ping_ipv6(self, ipv6_url, total_time = 3600, psize = 32):
        """
        采用包长为'psize'的数据包Ping地址'ipv6_url'，调用进程执行ping 命令，持续'total_time'秒。
        """
        if psize == "":
            psize = 32        
        if total_time == "":
            total_time = 3600
            
        ret,pid = self._pingprocess_by_time(ipv6_url,total_time,psize)
        str_pid = str(pid)
        tmp_pro_dict = {str_pid:pid}
        self.dict_process_obj.update(tmp_pro_dict)
        
        if ret == PING_SUCCESS:
            log_data = u"采用ICMP数据字段长度为'%s'的数据包Ping地址'%s'，ping命令后台执行,后续可调用关键字来停止ping命令的执行并获取ping结果，否则将持续ping %s 秒。" % \
                       (psize, ipv6_url, total_time)
            log.user_info(log_data)
            return  str_pid
        else:
            log_data = u"ping命令后台执行失败。"
            log.user_info(log_data)
            raise RuntimeError(log_data)
                 
                                         
    def stop_ping(self,pid):
        '''
        停止进程并返回丢包率，打印ping执行。
        '''        
        lost_percent = None
        str_data = ''
        process_obj = self.dict_process_obj[pid]
        counter = 0
        
        while counter < 20:
            content = getsize(process_obj.ping_tmp_file)
            if content > 0L:
                break
            else:
                counter += 1
                time.sleep(1)

        try:
            if process_obj.is_alive:
                ret,data = attcommonfun.get_process_children(process_obj.pid)
                if ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
                    dict_process = data
                    for process_pid, process_name in dict_process.items():
                        if process_name not in ["ATT.exe","robot.exe","cmd.exe"]:
                            try:
                                os.kill(process_pid, 9)
                            except:
                                pass               
                try:
                    os.kill(process_obj.pid, 9)
                except:
                    pass
               
                time.sleep(0.5)
            else:
                pass
            
        except Exception,e:
            
            ret_data = u"停止ping进程发生异常： %s" % e
            log.debug_info(ret_data)
            #log.user_info(ret_data)       
            #raise RuntimeError(ret_data)
        
        ret_data = u"停止ping进程 %s 成功，下面开始获取ping结果" % pid
        log.user_info(ret_data)
            
        try:
            
            lost_percent,str_data = process_obj.get_result() 
            log.user_info(str_data)
        except Exception,e:
            log_data = u"获取ping结果发生异常: %s" % e
            log.user_info(log_data)
            raise RuntimeError(log_data)
        
        return lost_percent
    
    def stop_ping_and_should_ping_success(self,pid,success_percent_lost = 50):
        """  停止ping进程执行，且ping执行成功 """
        
        if success_percent_lost == "":
            success_percent_lost = 50
        
        # 增加success_percent_lost入参处理及入参检查 add by shenlige 2013-4-26
        success_percent_lost = self._check_percent_lost_para(success_percent_lost)
        
        ret_lost_percent = self.stop_ping(pid)
        
        if ret_lost_percent <= success_percent_lost:
            log_data = u"进程中持续执行Ping命令，Ping成功"
            log.user_info(log_data)            
        else:
            log_data = u"进程中持续执行Ping命令，Ping失败，应Ping成功" 
            log.user_info(log_data)
            raise RuntimeError(log_data)
        
    def stop_ping_and_should_ping_fail(self,pid,success_percent_lost = 50):
        """  停止ping进程执行，且ping执行成功 """
        
        if success_percent_lost == "":
            success_percent_lost = 50
        
        # 增加success_percent_lost入参处理及入参检查 add by shenlige 2013-4-26
        success_percent_lost = self._check_percent_lost_para(success_percent_lost)
        
        ret_lost_percent = self.stop_ping(pid)

        if ret_lost_percent <= success_percent_lost:
            log_data = u"进程中持续执行Ping命令，Ping成功，应Ping失败" 
            log.user_info(log_data)
            raise RuntimeError(log_data)
        else:
            log_data = u"进程中持续执行Ping命令，Ping失败" 
            log.user_info(log_data)
            
    
    
class PingProcess(multiprocessing.Process):
    """
    调用线程执行ping命令。
    """
    
    def __init__(self, node, size=ICMP_DATA_STR, total_time = 3600):
        multiprocessing.Process.__init__(self)
        
        self.node = node       
        self.size = size         
        self.total_time = total_time
        self.tep_filename = "ping_temp_file_%s.txt" % time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
        
        try:
            if not exists(ATTROBOT_TEMP_FILE_PAHT):
                os.makedirs(ATTROBOT_TEMP_FILE_PAHT)
            self.ping_tmp_file = os.path.join(ATTROBOT_TEMP_FILE_PAHT,self.tep_filename)
        except Exception,e:
            log_data = u"生成平台的临时目录发生错误： %s" % e
            raise RuntimeError(log_data)
            
        self.lost_percent = None                   # 最终ping结果保存。
   
        self.err_info = ""
        self.file_handel = None
        self.popen = None
        self.wait_time = 20  # ping临时文件中有没有内容的最长等待时间 add by shenlige 2013-4-27
    
    def get_ping_tmp_file(self):
        
        return self.ping_tmp_file
    
    def ping(self):
        ret = PING_SUCCESS
        counter = 0
        for i in [1]:
            
            try:                
                # 默认使用ping次数
                # 修改最长时间为30天 modify by shenlige 2013-6-26
                number = 2592000       
                cmd_smg = " -l %s -n %s %s" % (self.size,number,self.node)
                cmd = "\"" + EXE_PATH + "\"" + cmd_smg
                
                with open(self.ping_tmp_file,"w") as self.file_handel:
                    self.popen = subprocess.Popen(cmd,shell=True,
                                     stdin=subprocess.PIPE,
                                     stdout=self.file_handel,
                                     stderr=subprocess.PIPE)
            
            except Exception, e:
                log_data = u"执行并行ping命令发生异常,message:%s" % e
                log.user_err(log_data)
                self.err_info = log_data
                ret = PING_FAIL
                break
                           
            # 确认ping临时文件不为空，增加等待时间，最长等待20秒  add by shenlige 2013-4-26
            while counter < self.wait_time:
                content = getsize(self.ping_tmp_file)
                if content > 0L:
                    break
                else:
                    counter += 1
                    time.sleep(1)
                                 
            time.sleep(self.total_time)    # 执行指定时间长度的ping命令
            
            try:
                if self.popen.poll() == None:
                    # 修改kill进程的实现方式 modify by shenlige 2013-7-4
                    pro_ret,data = attcommonfun.get_process_children(self.popen.pid)
                    if pro_ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
                        dict_process = data
                        for process_pid, process_name in dict_process.items():
                            # modify by shenlige 2013-11-2 修改kill进程
                            #if process_name not in ["ATT.exe","robot.exe","cmd.exe"]:
                            if process_name.lower() == 'ping.exe':
                                try:
                                    os.kill(process_pid, 9)
                                except:
                                    pass
                
                    try:
                        os.kill(self.popen.pid, 9)
                    except:
                        pass
                else:
                    pass
                
                time.sleep(0.5)    # zsj add 解决报windows32错误问题   2013-3-25
                
            except Exception, e:
                log_data = u"停止并行ping发生异常,message:%s" % e
                log.user_err(log_data)
                self.err_info = log_data
                ret = PING_FAIL
        
        if ret == PING_FAIL:
            raise RuntimeError(log_data)
        return self.popen
            
    
    def get_result(self):
        '''
        功能描述：获取ping结果
        参数：无
        返回：[lost_percent,str_data] ：[丢包率,ping执行结果打印信息]
        '''
        
        ret = PING_SUCCESS
        for i in [1]:
            
            if not exists(self.ping_tmp_file):
                log_data = u"进程ping的临时文件未正常生成"
                ret = PING_FAIL
                break
            
            try:
                with open(self.ping_tmp_file,"r") as f_tmp:
                    data = f_tmp.read()
            except Exception, e:
                log_data = u"从临时文件中读取ping结果发生异常,message:%s" % e
                log.user_err(log_data)
                self.err_info = log_data
                ret = PING_FAIL
                break
            
            
            try:    
                time.sleep(0.1)
                if exists(self.ping_tmp_file):
                    os.remove(self.ping_tmp_file)
                    
                data = data.decode(sys.getfilesystemencoding())
                data = re.sub("\r\r\n","\n", data)
                empty_line_re = "^\\r"
                num_send = 0
                success_num = 0
                flag = False
                dns_analysis_fail = False    # 增加域名解析失败时的标识位  add by shenlige 2013-4-2
                
                if data == "":
                    log_data = u"Ping临时文件内容为空，可能的原因是指定时间内域名解析失败"
                    log.user_err(log_data)
                    ret = PING_FAIL
                    break
            
                if  "Minimum" in data:
                    flag = True
            
                if u"Ping request could not find host" in data:
                    # 域名解析失败时的异常处理
                    dns_analysis_fail = True
                    lost_percent = 100
                else:    
                    data_list = data.split("\n")[:-1]
                    if len(data_list) < 3:
                        log_data = data
                        print data
                        ret = PING_FAIL
                    
                    if not self.total_time:
                        if flag:  
                            data_list = data_list[:-5]
                        else:
                            data_list = data_list[:-3]
            
                    for i in data_list:
                        if  "time" in i and "Reply from" in i:
                            success_num +=1
                        if not re.match(empty_line_re,i):
                            num_send += 1
           
                    num_send = num_send - 1
                    lost_num = num_send - success_num
    
                    if lost_num == 0:
                        lost_percent = 0
                    else:
                        lost_percent = float(lost_num)/float(num_send)*100
                        lost_percent = int(lost_percent)
         
                if dns_analysis_fail:
                    # 增加域名解析失败时的结果处理 modyfi by shenlige 2013-4-2
                    str_data = "Ping request could not find host %s. Please check the name and try again." % self.node
                else:
                    data_list.append("Ping statistics for %s:" % self.node)
                    str_tmp = "    Packets: Sent = %s, Received = %s, Lost = %s (%s" % (num_send,
                                                                               success_num,
                                                                               lost_num,
                                                                               lost_percent)
                    str_tmp += "% loss)"                                                                          
                    data_list.append(str_tmp)   
                    str_data = "\n".join(data_list)
            except Exception, e:
                    log_data = u"获取ping.exe结果发生异常,message:%s" % e
                    log.user_err(log_data)
                    self.err_info = log_data
                    ret = PING_FAIL
                    break
            
        if ret == PING_FAIL:
            raise RuntimeError(log_data)
        
        #if os.path.exists(self.ping_tmp_file):
        #    os.remove(self.ping_tmp_file)
        return lost_percent,str_data

    def run(self):
        """
        执行_ping命令
        """
        self.ping()


def pingNode(node,number=5,size=ICMP_DATA_STR,total_time=None):
    """
    功能描述：ping接口
    """
    ret = PING_SUCCESS
    counter = 0
    for i in [1]:
        
        try:
            if not exists(ATTROBOT_TEMP_FILE_PAHT):
                os.makedirs(ATTROBOT_TEMP_FILE_PAHT)
            PING_TMP_FILE = os.path.join(ATTROBOT_TEMP_FILE_PAHT,"ping_temp_file.txt")
        except Exception,e:
            log_data = u"生成平台的临时目录发生错误： %s" % e
            raise RuntimeError(log_data)
        
           
        try:
            # 修改可执行文件路径 modify by shenlige 2013-5-22            
            # 默认使用ping次数
            if total_time:
                number = 2592000
            
            
            cmd_smg = " -l %s -n %s %s" % (size,number,node)
            cmd = "\"" + EXE_PATH + "\"" + cmd_smg
            
            with open(PING_TMP_FILE,"w") as file_tmp:
                popen = subprocess.Popen(cmd,shell=True,
                                 stdin=subprocess.PIPE,
                                 stdout=file_tmp,
                                 stderr=subprocess.PIPE)                   
        except Exception, e:
            log_data = u"执行ping.exe发生异常,message:%s" % e
            log.user_err(log_data)
            ret = PING_FAIL
            break
        
             
        while counter < 20:
            content = getsize(PING_TMP_FILE)
            if content > 0L:
                break
            else:
                counter += 1
                time.sleep(1)
        try:
            # modify by shenlige 2013-7-10 修改域名解析失败时attcommonfun.get_process_children执行失败的问题
            if total_time:
                if popen.poll() == None:
                    time.sleep(total_time)  # 等待指定的ping时间
                    pro_ret,data = attcommonfun.get_process_children(popen.pid)
                    if pro_ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
                        dict_process = data
                        for process_pid, process_name in dict_process.items():
                            # modify by shenlige 2013-11-2 修改kill进程
                            #if process_name not in ["ATT.exe","robot.exe","cmd.exe"]:
                            if process_name.lower() == 'ping.exe':
                                try:
                                    os.kill(process_pid, 9)
                                except:
                                    pass
                
                    try:
                        os.kill(popen.pid, 9)
                    except:
                        pass
                else:
                    pass
            else:
                popen.wait()  
                     
            time.sleep(0.5)    # zsj add 解决报windows32错误问题   2013-3-25
               
        except Exception, e:
            log_data = u"停止按时间ping发生异常,message:%s" % e
            log.user_err(log_data)
            ret = PING_FAIL
            break
        
        if not exists(PING_TMP_FILE):
            log_data = u"ping临时文件未正常生成"
            ret = PING_FAIL
            break
        
        try:
            with open(PING_TMP_FILE,"r") as f_tmp:
                    data = f_tmp.read()
            data = data.decode(sys.getfilesystemencoding())
            
        except Exception, e:
            log_data = u"获取ping.exe结果发生异常,message:%s" % e
            log.user_err(log_data)
            ret = PING_FAIL
            break
        
        time.sleep(0.1)
        if exists(PING_TMP_FILE):
            os.remove(PING_TMP_FILE)
                    
        # 对丢包率的返回做修改，不再去匹配lost，而是先统计出成功的报文，然后计算出丢包率
        # modify by shenlige 2013-3-16
        data = re.sub("\r\r\n","\n", data)
        empty_line_re = "^\\r"
        num_send = 0
        success_num = 0
        flag = False
        dns_analysis_fail = False    # 增加域名解析失败时的标识位  add by shenlige 2013-4-2
        
        if data == "":
            log_data = u"Ping临时文件内容为空，可能的原因是指定时间内域名解析失败"
            log.user_err(log_data)
            ret = PING_FAIL
            break
        
        if  "Minimum" in data:
            flag = True
        
        if u"Ping request could not find host" in data:
            # 域名解析失败时的异常处理
            dns_analysis_fail = True
            lost_percent = 100
        else:    
            data_list = data.split("\n")[:-1]
            if len(data_list) < 3:
                log_data = data
                print data
                ret = PING_FAIL
                break
        
            if not total_time:
                if flag:  
                    data_list = data_list[:-5]
                else:
                    data_list = data_list[:-3]
        
            for i in data_list:
                if  "time" in i and "Reply from" in i:
                    success_num +=1
                if not re.match(empty_line_re,i):
                    num_send += 1
       
            num_send = num_send - 1
            lost_num = num_send - success_num

            if lost_num == 0:
                lost_percent = 0
            else:
                lost_percent = float(lost_num)/float(num_send)*100
                lost_percent = int(lost_percent)
     
        if dns_analysis_fail:
            # 增加域名解析失败时的结果处理 modyfi by shenlige 2013-4-2
            str_data = "Ping request could not find host %s. Please check the name and try again." % node
        else:
            data_list.append("Ping statistics for %s:" % node)
            str_tmp = "    Packets: Sent = %s, Received = %s, Lost = %s (%s" % (num_send,
                                                                           success_num,
                                                                           lost_num,
                                                                           lost_percent)
            str_tmp += "% loss)"                                                                          
            data_list.append(str_tmp)   
            str_data = "\n".join(data_list)
        
        print str_data
        
    if ret == PING_FAIL:
        raise RuntimeError(log_data)
    
    # 解决远端偶现RuntimeError ，暂时定位为这里的问题，因偶现还需要验证修改是否正确
    #if os.path.exists(PING_TMP_FILE):
    #    os.remove(PING_TMP_FILE)
    return lost_percent    
    
    
if __name__ == '__main__':
    """Main loop
    """
    '''
    print pingNode(alive=0, timeout=1, ipv6=0, total_time =10, \
             node='172.16.25.25', size=15000)
    # if we made it this far, do a clean exit
    sys.exit(0)
    '''
    #pingNode(node="172.16.28.1",number=5,timeout=1.0,size=ICMP_DATA_STR,total_time=10)
    #test.should_ping_ipv4_fail_by_count("10.10.10.10",4)
    #test.should_ping_ipv4_success_by_time("172.16.28.1",10)
    #test.should_ping_ipv4_fail_by_time("10.10.10.10",10)
    #test.should_ping_ipv6_success_by_count("fe80::1",4)
    #test.should_ping_ipv6_fail_by_count("fe80::10",4)
    #test.should_ping_ipv6_success_by_time("fe80::1",10)
    #test.should_ping_ipv6_fail_by_time("fe08::1",10)
    test = ATTPing()
    test.should_ping_ipv4_success_by_time("www.asdfasd.com",20)