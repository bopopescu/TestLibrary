# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2013-2014, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTTCPClient
#  function: 模拟TCPClient，连接到TCPServer，发送TCP消息到服务器并接收回应消息
#  Author: ATT development group
#  version: V1.0
#  date: 2013.09.09
#  change log:
#  lana     20130909     created
#  lana     20130917     将发送的数据转换为str类型
#  lana     20130922     利用子进程发送数据包；增加发送多个数据包的功能
# ***************************************************************************


from twisted.internet import protocol, reactor
import subprocess
import hashlib
from multiprocessing import Process, Value

import attlog as log
from attcommonfun import check_port_status

ATTTCPCLIENT_SUC = 0
ATTTCPCLIENT_FAIL = -1
ATTTCPCLIENT_PORT_BUSY = -2

class TSClntProtocol(protocol.Protocol):
	
	send_data = []
	connection_status = []
	data = ""
	
	def sendData(self):
		# 将send_data列表中的数据一个一个的发送出去，发送完后断开连接
		if len(TSClntProtocol.send_data):
			TSClntProtocol.data = TSClntProtocol.send_data.pop(0)
			log_data = '...sending %s...' % TSClntProtocol.data
			log.debug_info(log_data)
			
			if isinstance(TSClntProtocol.data, unicode):
				TSClntProtocol.data = TSClntProtocol.data.encode("utf-8") 
				
			self.transport.write(str(TSClntProtocol.data))
		else:
			self.transport.loseConnection()
		
	def connectionMade(self):
		self.sendData()
		
	def dataReceived(self, data):
		
		# 加密发送的数据，用于验证接收的数据是否正确
		encoded_send_data = hashlib.md5(TSClntProtocol.data).hexdigest().upper()
		
		# 检测接收的数据是否正确，用于判断链路是否正常
		if encoded_send_data == data:
			TSClntProtocol.connection_status.append(1)
		else:
			TSClntProtocol.connection_status.append(0)
			
		# 继续发送数据	
		self.sendData()
		
		
class TSClntFactory(protocol.ClientFactory):
	
	protocol = TSClntProtocol
	
	clientConnectionLost = clientConnectionFailed = \
						lambda self, connector, reason: reactor.stop()


class ATTTCPClient(object):
	"""
	ATTTCPClient
	"""
	
	def __init__(self, src_ip="0.0.0.0", src_port=0):
		"""
		初始化TCP报文的源IP和源端口，如果端口为0,表示不指定源端口
		"""
		
		self.connection_status = Value('i', -1)
		self.src_ip = src_ip
		self.src_port = int(src_port)
		
	
	def set_tcp_src_addr(self, src_port, src_ip="0.0.0.0"):
		"""
		设置tcp报文的源IP和源端口，在需要指定发送报文的源端口时使用
		"""
		
		self.src_ip = src_ip
		self.src_port = int(src_port)
	
	
	def _send_tcp_package(self, dst_ip, dst_port, send_msg, status):
		"""
		功能描述：发送tcp报文到TCP Server，并接收回应，验证链路是否通
		
		参数：
			dst_ip: TCP报文的目的IP
			dst_port: TCP报文的目的port
			send_msg: TCP报文的消息内容
			status: 链路状态，为1，表示链路正常，为2，表示端口被占用，为3表示connectTCP发生异常，负数表示失败的次数,为0表示链路不通
			
		返回值：
			ATTTCPCLIENT_SUC， log_data 表示通
			ATTTCPCLIENT_FAIL, log_data 表示不通
			ATTTCPCLIENT_PORT_BUSY, log_data 表示端口被占用 
		"""
		
		# 检测端口是否被占用,如果源端口为0，表示不用指定源端口，则不用检测
		if self.src_port == 0 or check_port_status(self.src_ip, self.src_port):
			
			# 设置发送的消息,如果send_msg是列表则直接赋值，如果不是列表，则将send_msg加入到TSClntProtocol.send_data列表中
			if type(send_msg) == type([]):
				TSClntProtocol.send_data = send_msg
			else:
				TSClntProtocol.send_data.append(send_msg)
			
			try:
				# 判断是否需要绑定源端口
				if self.src_port == 0:
					reactor.connectTCP(dst_ip, int(dst_port), TSClntFactory())
				else:
					reactor.connectTCP(dst_ip, int(dst_port), TSClntFactory(), bindAddress=(self.src_ip, self.src_port))
					
				reactor.run()
			except Exception,e:
				status.value = 3
				log_data = "send tcp package ocurrs exception, error info is %s" % e
				log.debug_info(log_data)
				
			if TSClntProtocol.connection_status:
				fail_num = TSClntProtocol.connection_status.count(0)
				if  fail_num == 0:
					# 没有失败的记录，发送报文全部成功
					status.value = 1
					
				else:
					# 有失败记录，返回失败的次数,用负数表示
					status.value = -fail_num
			else:
				status.value = 0
				
		else:
			status.value = 2
			log_data = "The addr %s:%s have been used, choose another port please!" % (self.src_ip, str(self.src_port))
			log.debug_info(log_data)
			
	
	def send_tcp_package(self, dst_ip, dst_port, send_msg="hello,world!"):
		"""
		功能描述：发送tcp报文到TCP Server，并接收回应，验证链路是否通
		
		参数：
			dst_ip: TCP报文的目的IP
			dst_port: TCP报文的目的port
			send_msg: TCP报文的消息内容
			
		返回值：
			ATTTCPCLIENT_SUC， log_data 表示通
			ATTTCPCLIENT_FAIL, log_data 表示不通
			ATTTCPCLIENT_PORT_BUSY, log_data 表示端口被占用 
		"""
		
		# 创建子进程启动TCP client并发送报文
		try:
			sub_process = Process(target=self._send_tcp_package, args=(dst_ip, dst_port, send_msg, self.connection_status))
			sub_process.start()
			sub_process.join()
		except Exception, e:
			log_data = "Send TCP package occurs exception, error info is: %s" % e
			log.debug_err(log_data)
			return ATTTCPCLIENT_FAIL, log_data
		
		if self.connection_status.value <= 0:
			log_data = u"发送报文失败，链路不通"
			return ATTTCPCLIENT_FAIL, log_data
		
		elif self.connection_status.value == 2:
			log_data = u"地址 %s 的 %s 端口已经被占用，请使用其他端口." % (self.src_ip, str(self.src_port))
			return ATTTCPCLIENT_PORT_BUSY, log_data
		
		elif self.connection_status.value == 3:
			log_data = u"发送报文发生异常" 
			return ATTTCPCLIENT_FAIL, log_data
		
		else:
			log_data = u"发送报文成功!"
			return ATTTCPCLIENT_SUC, log_data
		

def test():
	dst_ip = "172.16.28.39"
	dst_port = 55555
	
	send_msg = "123456789"
	
	obj = ATTTCPClient()
	obj.set_tcp_src_addr(50001)
	ret = obj.send_tcp_package(dst_ip, dst_port, send_msg)
	print ret
	
	
if __name__ == '__main__':
	test() 