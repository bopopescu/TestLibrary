# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2013-2014, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTUDPServer
#  function: 模拟UDPServer，接收UDPClient的请求，并发送回应消息
#  Author: ATT development group
#  version: V1.0
#  date: 2013.09.11
#  change log:
#  lana     20130911     created
#  lana     20130922     added exception catch
#  lana     20130924     修改array共享内存的长度为128字节
#  lana     20131018     关闭server时，还原标志变量
# ***************************************************************************


from twisted.internet.protocol import DatagramProtocol
from multiprocessing import Process, Value, Array
from twisted.internet import reactor
import hashlib
import subprocess
import time

import attlog as log
from attcommonfun import check_port_status

ATTUDPSERVER_SUC = 0
ATTUDPSERVER_FAIL = -1

class TSServDatagramProtocol(DatagramProtocol):
	
	def datagramReceived(self, datagram, address):
		"""
		将收到的信息md5加密后，发送回client
		"""
		
		log_data = "from %s, recv: %s" % (address, datagram)
		log.debug_info(log_data)
		
		response_data = hashlib.md5(datagram).hexdigest().upper()
		self.transport.write(response_data, address)
		

class MyUDPServer(object):
	"""
	MyUDPServer
	"""
	
	def _check_flag(self, flag):
		"""
		检查服务器标识
		flag.value=1，表示继续运行服务器，
		flag.value=0，表示需要关闭服务器
		"""
		
		if flag.value == 0:
			
			reactor.stop()
			log_data = "UDPServer Stopped"
			log.debug_info(log_data)
			
		else:
			reactor.callLater(1, self._check_flag, flag)
	
	
	def start_udp_server(self, ip, port, flag, error):
		"""
		功能描述：开启UDP Server
		
		参数：
			ip: UDP server所在主机IP地址
			port: UDP Server监听的端口号
			flag: 服务器运行标识
		"""
		
		if check_port_status(ip, port, "UDP"):
			try:
				reactor.listenUDP(port, TSServDatagramProtocol(), interface=ip)
				reactor.callLater(1, self._check_flag, flag)
				reactor.run()
			except Exception,e:
				log_data = "ListenUDP occurs exception, error info is %s" % e
				log.debug_info(log_data)
				flag.value = 3
				error.value = log_data
			
		else:
			log_data = "The addr %s:%s have been used, choose another port please!" % (ip, str(port))
			log.debug_info(log_data)
			
			flag.value = 2
		
		
	def stop_udp_server(self, flag):
		"""
		关闭UDPServer
		"""
		
		flag.value = 0
		

class ATTUDPServer(object):
	"""
	ATTUDPServer
	"""
	
	def __init__(self):
		
		self.obj = MyUDPServer()
		self.flag = Value('i', 1)     # 初始共享内存变量
		self.error = Array('c', 128)  # 初始共享内存变量
		self.start_flag = 0           # 服务器是否已经开启的标志，为0，表示没有开启
	
	def start_udp_server(self, ip, port):
		"""
		功能描述：开启UDP Server
		
		参数：
			ip: UDP server所在主机IP地址
			port: UDP Server监听的端口号
		"""
		
		# 创建子进程启动UDP Server
		try:
			sub_process = Process(target=self.obj.start_udp_server, args=(ip, port, self.flag, self.error))
			sub_process.start()
		except Exception, e:
			log_data = "Start UDP Server occurs exception,error message is: %s" % e
			log.debug_err(log_data)
			return ATTUDPSERVER_FAIL, log_data
		
		# 等待5s,检测服务器启动是否成功
		time.sleep(5)
		if self.flag.value == 2:
			log_data = u"地址%s 的%s 端口已经被占用，请使用其他端口." % (ip, str(port))
			# 返回之前还原状态标志
			self.flag.value = 1
			self.error.value = " "
			return ATTUDPSERVER_FAIL, log_data
		
		elif self.flag.value == 3:
			self.obj.stop_udp_server(self.flag)
			log_data = u"UDP Server启动失败，错误信息为:%s." % self.error.value
			# 返回之前还原状态标志
			self.flag.value = 1
			self.error.value = " "
			return ATTUDPSERVER_FAIL, log_data
		
		else:
			if check_port_status(ip, port, "UDP"):
				self.obj.stop_udp_server(self.flag)
				log_data = u"UDP Server启动失败，UDPListen失败."
				# 返回之前还原状态标志
				self.flag.value = 1
				self.error.value = " "
				return ATTUDPSERVER_FAIL, log_data
			else:
				self.start_flag = 1
				log_data = u"UDP Server启动成功"
				return ATTUDPSERVER_SUC, log_data
		
	
	def stop_udp_server(self):
		"""
		关闭UDPServer
		"""
		
		if self.start_flag == 1:
			self.obj.stop_udp_server(self.flag)
			# 等待进程退出后，还原标志
			time.sleep(5)
			self.start_flag = 0
			self.flag.value = 1
			self.error.value = " "
			log_data = u"UDP Server停止成功"
			return ATTUDPSERVER_SUC, log_data
		else:
			log_data = u"UDP Server未开启, 不需要停止"
			return ATTUDPSERVER_SUC, log_data
		
		
def test():
	obj = ATTUDPServer()
	ret = obj.start_udp_server("172.16.28.49", 55555) 
	print ret
	time.sleep(300)
	ret = obj.stop_udp_server()
	print ret

if __name__ == '__main__':
	test() 
