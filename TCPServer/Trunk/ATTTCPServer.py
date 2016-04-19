# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2013-2014, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTTCPServer
#  function: 模拟TCPServer，接收TCPClient的请求，并发送回应消息
#  Author: ATT development group
#  version: V1.0
#  date: 2013.09.09
#  change log:
#  lana     20130909     created
#  lana     20130922     added exception catch
#  lana     20130924     修改array共享内存的长度为128字节
#  lana     20131018     关闭server时，还原标志变量
# ***************************************************************************


from twisted.internet import protocol, reactor
import hashlib
from multiprocessing import Process, Value, Array
import subprocess
import time

import attlog as log
from attcommonfun import check_port_status

ATTTCPSERVER_SUC = 0
ATTTCPSERVER_FAIL = -1


class TSServProtocol(protocol.Protocol):
	
	def connectionMade(self):
		"""
		当连接建立时，打印客户端的ip和端口
		"""
		
		client_ip = self.transport.getPeer().host
		client_port = self.transport.getPeer().port
		
		log_data = 'connected from %s:%s' % (client_ip, client_port)
		log.debug_info(log_data)
		
	
	def dataReceived(self, data):
		"""
		将收到的信息md5加密后，发送回client
		"""
		
		log_data = 'recv data is: %s' % data
		log.debug_info(log_data)
		
		# MD5加密收到的数据后发回给客户端
		response_data = hashlib.md5(data).hexdigest().upper()
		self.transport.write(response_data)
	
	
class MyTCPServer(object):
	"""
	MyTCPServer
	"""
	
	def _check_flag(self, flag):
		"""
		检查服务器运行标识
		flag.value=1，表示继续运行服务器，
		flag.value=0，表示需要关闭服务器
		"""
		
		if flag.value == 0:
			
			reactor.stop()
			
			log_data = 'TCPServer Stopped'
			log.debug_info(log_data)
			
		else:
			reactor.callLater(1, self._check_flag, flag)
	
	
	def start_tcp_server(self, ip, port, flag, error):
		"""
		功能描述：开启TCP Server
		
		参数：
			ip: TCP server所在主机IP地址
			port: TCP Server监听的端口号
			flag: 服务器运行标识
			error: 服务器运行的错误信息
		"""
		
		if check_port_status(ip, port):
			try:
				factory = protocol.Factory()
				factory.protocol = TSServProtocol
				
				log_data = "waiting for connection..."
				log.debug_info(log_data)
				
				reactor.listenTCP(port, factory, interface=ip)
				reactor.callLater(1, self._check_flag, flag)
				reactor.run()
				
			except Exception, e:
				log_data = "ListenTCP occurs exception, error info is %s" % e
				log.debug_info(log_data)
				flag.value = 3              # 开启服务器监听发生异常
				error.value = log_data
			
		else:
			log_data = "The addr %s:%s have been used, choose another port please!" % (ip, str(port))
			log.debug_err(log_data)
			
			flag.value = 2      # 端口被占用
		
		
	def stop_tcp_server(self, flag):
		"""
		关闭TCPServer
		"""
		
		flag.value = 0
		
	
class ATTTCPServer(object):
	"""
	ATTTCPServer
	"""
	
	def __init__(self):
		
		self.obj = MyTCPServer()
		self.flag = Value('i', 1)      # 初始共享内存变量
		self.error = Array('c', 128)   # 初始化共享内存变量
		self.start_flag = 0            # 服务器是否已经开启的标志，为0，表示没有开启
	
	def start_tcp_server(self, ip, port):
		"""
		功能描述：开启TCP Server
		
		参数：
			ip: TCP server所在主机IP地址
			port: TCP Server监听的端口号
		"""
		
		# 创建子进程启动TCP Server
		try:
			sub_process = Process(target=self.obj.start_tcp_server, args=(ip, port, self.flag, self.error))
			sub_process.start()
		except Exception, e:
			log_data = "Start TCP Server occurs exception, error info is: %s" % e
			log.debug_err(log_data)
			return ATTTCPSERVER_FAIL, log_data
		
		# 等待5s,检测服务器启动是否成功
		time.sleep(5)
		if self.flag.value == 2:
			log_data = u"地址%s 的%s 端口已经被占用，请使用其他端口." % (ip, str(port))
			# 返回之前还原状态标志
			self.flag.value = 1
			self.error.value = " "
			return ATTTCPSERVER_FAIL, log_data
		
		elif self.flag.value == 3:
			self.obj.stop_tcp_server(self.flag)
			log_data = u"TCP Server启动失败，错误信息为:%s." % self.error.value
			# 返回之前还原状态标志
			self.flag.value = 1
			self.error.value = " "
			return ATTTCPSERVER_FAIL, log_data
		
		else:
			if check_port_status(ip, port):
				# TCPListen失败，退出reactor.run()
				self.obj.stop_tcp_server(self.flag)
				log_data = u"TCP Server启动失败，TCPListen失败."
				# 返回之前还原状态标志
				self.flag.value = 1
				self.error.value = " "
				return ATTTCPSERVER_FAIL, log_data
			else:
				self.start_flag = 1
				log_data = u"TCP Server启动成功"
				return ATTTCPSERVER_SUC, log_data
		
	
	def stop_tcp_server(self):
		"""
		关闭TCPServer
		"""
		
		if self.start_flag == 1:
			self.obj.stop_tcp_server(self.flag)
			# 等待进程退出后，还原标志
			time.sleep(5)
			self.start_flag = 0
			self.flag.value = 1             
			self.error.value = " "
			log_data = u"TCP Server停止成功"
			return ATTTCPSERVER_SUC, log_data
		else:
			log_data = u"TCP Server未开启, 不需要停止"
			return ATTTCPSERVER_SUC, log_data
	

def test():
	obj = ATTTCPServer()
	ret = obj.start_tcp_server("172.16.28.49", 55555) 
	print ret
	time.sleep(300)
	ret = obj.stop_tcp_server()
	print ret
	

if __name__ == '__main__':
	test()
	
	
	