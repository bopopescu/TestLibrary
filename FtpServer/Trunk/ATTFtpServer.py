# -*- coding: utf-8 -*- 

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTFTPServer
#  function: 模拟FTPServer，提供开启和关闭FTP服务器的功能
#  Author: ATT development group
#  version: V1.0
#  date: 2013.01.04
#  change log:
#  guochenwei     20130104     created
#  lana           20130116     optimize log info
#  lana           20130117     added FTPServerThread to start ftp server
#  jiangxiaoyan   20130401     Change FTPServerTread to FTPServerprocess to start ftp server
# ***************************************************************************

import time 
import multiprocessing
import threading
import sys,os

import pyftpdlib
from pyftpdlib import *
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
from pyftpdlib._compat import getcwdu
    
import attlog as log
from attcommonfun import *

ATTFTPSEVER_SUC = 0
ATTFTPSEVER_FAIL = -1

#add class by jias
class RecvMsgThread(threading.Thread):
    """
    接收消息的线程, 调用父进程的退出函数
    """
    def __init__(self, conn, pro_handle):
        threading.Thread.__init__(self)
        self.recv_conn = conn
        self.parent_handle = pro_handle
        
        self.run_flg = True
        
    def run(self):
        while self.run_flg:
            tmpdata = self.recv_conn.recv()
            
            if 81 == tmpdata[0]:
                self.parent_handle.exit_server()
                
                self.recv_conn.close()
                break #线程自己退出
    

        
            
class FTPServerProcess(multiprocessing.Process):
    """
    custom define process, used to start FTP server
    """
    
    def __init__(self, ip, port=21, username="ftptest", password="ftptest", homedir="C:\\", conn = None):
        """
        initial
        """
        multiprocessing.Process.__init__(self)
        
        self.ip = ip
        self.port = int(port)
        self.username = username
        self.password = password
        self.homedir = homedir
        
        self.ftpd = None
        self.err_info = ""
        
        # add by jias 
        self.conn = conn
        self.thread_recv = None
        
    def run(self):
        """
        start ftp server
        """
        #add by jias
        #创建一个子线程，用于接收管道里面的消息
        #若是退出消息点调用退出函数        
        if  not self.thread_recv:
            self.thread_recv = RecvMsgThread(self.conn, self)
            self.thread_recv.start()
        
        start =  8000
        stop =  9000
        passive_ports = range(start, stop + 1)
        perm = "elradfmwM"
        # GCW 20130302 无须进行编码转换,否则中文目录时报编码错误,误认为不是文件夹,
        #if (isinstance(self.homedir, unicode)):
        #    self.homedir= self.homedir.encode('utf-8')
        directory = self.homedir
        try:
            authorizer = pyftpdlib.authorizers.DummyAuthorizer()
            if self.username != "":
                authorizer.add_user(self.username, self.password, self.homedir, perm)    #新建帐号，权限全开
            
            authorizer.add_anonymous(directory)    #新建匿帐号，权限只有elr
            
        except Exception, e:
            #err_info = u"新建账户发生异常，%s" % e
            #log.debug_err(err_info)
            err_info = e
            self.err_info = err_info
            # GCW20130304 解决当服务器拉起失败后,RF中没有停止的问题.如错误的路径
            return
        
        try:
            handler = pyftpdlib.handlers.FTPHandler
            handler.authorizer = authorizer
            handler.passive_ports = passive_ports
            
            self.ftpd = pyftpdlib.servers.FTPServer((self.ip, self.port), handler)
            self.ftpd.serve_forever()
            
        except Exception, e:
            #err_info = u"开启FTP服务器发生异常： %s" % e.message
            err_info = e
            #log.debug_err(err_info)
            self.err_info = err_info
            # GCW20130304 解决当服务器拉起失败后,RF中没有停止的问题
            return
        finally:
            if self.ftpd:
                if self.ftpd.socket:
                    self.ftpd.socket.close()
                self.ftpd.socket = None
                
    def exit_server(self):
        """
        退出ftp服务
        """              
        if self.ftpd:            
            self.ftpd.close_all()
            
class ATTFtpServer():
    

    # Change by jxy 2013/4/1 ,变量放到Init里面去；
    # 这样一台电脑不同的端口可以启用不同的FTPserver。
    # 对port的取值范围和是否被占用进行检查，change by jxy ,2013/5/7
    def __init__(self, port):
        self.pid = None
        self.port = int(port)
        
        self.m_ftpstartflag  = False
        self.m_ftpd = None
        self.m_ip_port = None
        
        #add by jias
        #建立管道，通过管道给服务进程发送退出消息
        self.recv_conn, self.send_conn = multiprocessing.Pipe(False)

    def _check_init_port(self,ip,port):
        """
        功能描述：对port的取值范围和是否被占用进行检查。
        
        参数：port:端口号
        
        返回值： ATTFTPSEVER_SUC,ret_data,  port在(0,65536)之内，且没有被占用。
                 ATTFTPSEVER_FAIL,ret_data,  port不在(0,65536)之内，或者已经被占用。ret_data为具体原因。
        
        """
        ret = ATTFTPSEVER_SUC
        ret_data = u"检查port参数成功!"
        for i in [1]:
            try:
                # 对用户输入的端口做检查是否符合要求， change by jxy ,2013/5/7.
                port = int(port)
                ret,data = check_port(port)
                if ret == ATTCOMMONFUN_FAIL:
                    ret_data = data
                    ret = ATTFTPSEVER_FAIL
                    break
            except Exception,e:
                ret_data= u"对用户输入的端口做检查失败。 " 
                ret = ATTFTPSEVER_FAIL
                break
        
            try:
                # 查询端口是否被占用， change by jxy ,2013/5/7.
                ret = check_port_open(ip, port)
                if ret == ATTCOMMONFUN_FAIL:
                    ret_data = u"端口 %s 已经被占用，请使用其他端口。" % port
                    ret = ATTFTPSEVER_FAIL
                    break
            except Exception,e:
                ret_data= u"查询端口 %s 是否被占用失败。 "  % port
                ret = ATTFTPSEVER_FAIL
                break
         
        return ret, ret_data

    def _start(self, ip, port=21, username="ftptest", password="ftptest", homedir="C:\\"):
        """
        功能描述：创建FTP账户并启动FTP服务器
        
        参数：  ip--IP地址,
                port--端口号，默认21,
                username--用户名,默认为ftptest,
                password--密码,默认为ftptest,
                homedir--根目录,windows下默认是C盘
                
        返回值：执行成功，返回(ATTFTPSEVER_SUC，成功信息)
                执行失败，返回(ATTFTPSEVER_FAIL，失败信息)
        """
        ret = ATTFTPSEVER_SUC
        
        for i in [1]:
            
            # 查询主机网卡是否有获取到 host地址，change by jxy ,2013/5/7.
            try:
                ret,ip_list = get_local_ip()
                #支持0.0.0.0监听 add by jias 20140225
                ip_list.append("0.0.0.0")
                
                if ret == ATTCOMMONFUN_SUCCEED:
                    if ip in ip_list:
                        pass
                    else:
                        ret_data = u"主机没有网卡的地址为：%s " % ip
                        ret = ATTFTPSEVER_FAIL
                        break
                else:
                    ret_data = u"查询主机网卡是否有获取到 %s 地址失败" % ip
                    ret = ATTFTPSEVER_FAIL
                    break
            except Exception,e:
                ret_data= u"查询主机网卡是否有获取到 %s 地址异常。 " % ip
                ret = ATTFTPSEVER_FAIL
                break
                
            ret,ret_data = self._check_init_port(ip,port)
            if ret == ATTFTPSEVER_FAIL:
                break

                # 检查home_dir是不是目录，或者目录是不是存在。
            
            if not os.path.isdir(homedir):
                ret_data = u"%s 不是目录，或者目录不存在。 " % homedir
                ret = ATTFTPSEVER_FAIL
                break
 
            try:
                self.pid = FTPServerProcess(ip, port, username, password, homedir, self.recv_conn)
                self.pid.start()
                time.sleep(3)
                
                #检查进程进程以及服务器是否正常启动
                count = 10
                while count>0:
                    
                    if self.pid.is_alive():
                        
                        #连接测试
                        if self._check_zero_string_server_working(ip,port):
                            count = -1
                            break
                    
                    time.sleep(1)
                    count = count -1
                if count == 0:
                    ret = ATTFTPSEVER_FAIL
                    log.user_info(u"检测ftp服务器失败！")
                    ret_data = u"检测不到ftp服务器存在，启动失败！"
                    os.kill(self.pid.pid,9)
                else:
                    if not check_port_status(ip,port):
                        ret= ATTFTPSEVER_SUC
                    else:
                        ret= ATTFTPSEVER_FAIL
                        log.user_info(u"检测ftp服务端口失败！")
                        os.kill(self.pid.pid,9)
                        ret_data = u"检测不到ftp服务器存在，启动失败！"

            except Exception, e:
                err_info = "Starting HTTPServerProcess Error:%s" % e
                ret_data = err_info
                log.user_err(ret_data)
                ret = ATTFTPSEVER_FAIL
                break
            
            #del by jias 不能通过下面的代码获取到子进程的错误消息
            # wait a moment to check whether the pid is ok
            """
            log.debug_info(u"调用FTPServerProcess启动FTP服务器成功，等待5s,检查服务器运行是否正常!")
            time.sleep(5)
            if self.pid.err_info != "":
                ret_data = self.pid.err_info
                log.debug_err(u"FTP服务器运行出错，详细信息为：%s" % ret_data)
                ret = ATTFTPSEVER_FAIL
            """
        if ret != ATTFTPSEVER_FAIL:
            ret_data = u"FTP服务器启动成功!"
            
        return ret, ret_data
    
    def _check_zero_string_server_working(self, in_address, in_port):
        """
        特殊处理"0.0.0.0"地址
        """
        
        if "0.0.0.0" == in_address:
            ret_tmp,local_ip_list = get_local_ip()
            
            ret = False
            for ip_item in local_ip_list:
                ret = self._check_server_working(ip_item,int(in_port))
                if True == ret:
                    break
                
            return ret
        
        else:
            return self._check_server_working(in_address,int(in_port))
        
      
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
        
    def start_ftp_server(self, ip, username="ftptest", password="ftptest", homedir="C:\\"):
        """
        功能描述：启动FTP服务器，如果username不为空，则会新建一个拥有所有权限的账户
        
        参数：  ip: IP地址,
                port: 端口号，默认21,
                username: 新建账户用户名,默认为ftptest,
                password: 新建账户密码,默认为ftptest,
                homedir: 根目录,windows下默认是C盘。
                
        返回值：无，如果启动失败，则返回异常
        
        Example:
        | start ftp server | 10.10.10.10 | 21  | test | test | E:\\Test\\ |
        | start ftp server | 10.10.10.10 | 21  |      |      |   |
        """
        
        try:
            if self.m_ftpstartflag == True:
                # GCW 2013-02-23 将已启动的IP:port打印,便于重复启动时客户端连接失败的定位
                log.user_warn(u"FTP服务器已经启动，不需要再启动!地址和端口号为: %s" % self.m_ip_port)  
                return
            ret, ret_info = self._start(ip, self.port, username, password, homedir)           
        except Exception, e:
            err_info = u"启动FTP服务器异常，异常信息为：%s" % e
            #log.user_err(err_info)
            self.m_ftpstartflag = False
            self.m_ftpd = None
            raise RuntimeError(err_info)
        
        if ret == ATTFTPSEVER_FAIL:
            err_info = u"启动FTP服务器失败，错误信息为:%s" % ret_info
            #log.user_err(ret_info)
            raise RuntimeError(err_info)
        else:
            log.user_info(ret_info)
            self.m_ftpstartflag = True
            self.m_ip_port = ip + ':' + str(self.port)
            self.m_ftpd = self.pid.pid
        
        
    def stop_ftp_server(self):
        """
        功能描述：停止FTP服务器
        
        参数：无
        Example:
        | stop ftp server |   |   |  | 
        
        """
        try:
            if self.m_ftpd:                
                log.debug_info(u"FTP服务器%s!" % str(self.m_ftpd))
                #self.pid.terminate()
                #time.sleep(5)
                self.send_conn.send([81, "EXIT"])
                self.pid.join(10)
                #add by nzm 2014-1-13 解决stop卡死问题 强制杀死进程
                if self.pid.is_alive():
                    log.user_info(u"进程服务仍然存在，terminate...")
                    self.pid.terminate()
                    time.sleep(3)
                
                self.m_ftpstartflag = False
                self.m_ftpd = None
                log.user_info(u"停止FTP服务器成功!")
            else:
                log.user_warn(u"FTP服务器未开启，不需要停止!")
        except Exception, e:
            err_info = u"停止FTP服务器出现异常， %s" % e
            #log.user_err(err_info)
            raise RuntimeError(err_info)

if __name__ == '__main__':
    a = ATTFtpServer(21)
    a.start_ftp_server('172.16.28.82')
    time.sleep(10)
    a.stop_ftp_server()
    print "ok"