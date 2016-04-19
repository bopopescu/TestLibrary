# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2013-2014, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTDUPClient
#  function: 模拟UDPClient，发送UDP消息到服务器并接收回应消息
#  Author: ATT development group
#  version: V1.0
#  date: 2013.09.11
#  change log:
#  lana     20130911     created
#  lana     20130917     将发送的数据转换为str类型
#  lana     20130922     利用子进程发送数据包；增加发送多个数据包的功能
# ***************************************************************************


from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
import hashlib
import subprocess
from multiprocessing import Process, Value

import attlog as log
from attcommonfun import check_port_status

ATTUDPCLIENT_SUC = 0
ATTUDPCLIENT_FAIL = -1
ATTUDPCLIENT_PORT_BUSY = -2

class TSClntDatagramProtocol(DatagramProtocol):
	
	send_data = []
	connection_status = []
	data = ""
	dst_ip = "0.0.0.0"
	dst_port = 0
	recv_flag = 0
	
	def startProtocol(self):
		self.transport.connect(TSClntDatagramProtocol.dst_ip, TSClntDatagramProtocol.dst_port)
		self.sendDatagram()
		
	def sendDatagram(self):
		# 将send_data列表中的数据一个一个的发送出去，发送完后退出reactor循环
		if len(TSClntDatagramProtocol.send_data):
			TSClntDatagramProtocol.data = TSClntDatagramProtocol.send_data.pop(0)
			log_data = '...sending %s...' % TSClntDatagramProtocol.data
			log.debug_info(log_data)
			
			if isinstance(TSClntDatagramProtocol.data, unicode):
				TSClntDatagramProtocol.data = TSClntDatagramProtocol.data.encode("utf-8") 
			
			self.transport.write(str(TSClntDatagramProtocol.data))
		else:
			reactor.stop()
		
	def datagramReceived(self, datagram, host):
		log_data = 'Datagram from %s received: %s ' % (host, repr(datagram))
		log.debug_info(log_data)
		
		TSClntDatagramProtocol.recv_flag = 1
		
		# 加密发送的数据，用于验证接收的数据是否正确
		encoded_send_data = hashlib.md5(TSClntDatagramProtocol.data).hexdigest().upper()
		
		# 检测接收的数据是否正确，用于判断链路是否正常
		if encoded_send_data == datagram:
			TSClntDatagramProtocol.connection_status.append(1)
		else:
			TSClntDatagramProtocol.connection_status.append(0)
		
		# 继续发送数据	
		self.sendDatagram()
		

class ATTUDPClient(object):
	"""
	ATTUDPClient
	"""
	
	def __init__(self, src_ip="0.0.0.0", src_port=0):
		"""
		初始化UDP报文的源IP和源端口，如果端口为0,表示不指定源端口
		"""
		self.connection_status = Value('i', -1)
		self.src_ip = src_ip
		self.src_port = int(src_port)
		
	
	def set_udp_src_addr(self, src_port, src_ip="0.0.0.0"):
		"""
		设置udp报文的源IP和源端口，在需要指定发送报文的源端口时使用
		"""
		
		self.src_ip = src_ip
		self.src_port = int(src_port)
		
	def _check_recv_flag(self):
		"""
		检查是否有接收到回应消息
		"""
		if TSClntDatagramProtocol.recv_flag:
			TSClntDatagramProtocol.recv_flag = 0
			reactor.callLater(30, self._check_recv_flag)
		else:
			reactor.stop()
		
	
	def _send_udp_package(self, dst_ip, dst_port, send_msg, status):
		"""
		功能描述：发送udp报文到UDP Server，并接收回应，验证链路是否通
		
		参数：
			dst_ip: UDP报文的目的IP
			dst_port: UDP报文的目的port
			send_msg: UDP报文的消息内容
			status: 链路状态，为1，表示链路正常，为2，表示端口被占用，为3表示connectTCP发生异常，负数表示失败的次数,为0表示链路不通
			
		返回值：
			ATTUDPCLIENT_SUC， log_data 表示通
			ATTUDPCLIENT_FAIL, log_data 表示不通
			ATTUDPCLIENT_PORT_BUSY, log_data 表示端口被占用 
		"""
		
		# 检测端口是否被占用,如果源端口为0，表示不用指定源端口，则不用检测
		if self.src_port == 0 or check_port_status(self.src_ip, self.src_port, "UDP"):
			
			# 设置目的IP和目的端口
			TSClntDatagramProtocol.dst_ip = dst_ip
			TSClntDatagramProtocol.dst_port = int(dst_port)
			
			# 设置发送的消息,如果send_msg是列表则直接赋值，如果不是列表，则将send_msg加入到TSClntDatagramProtocol.send_data列表中
			if type(send_msg) == type([]):
				TSClntDatagramProtocol.send_data = send_msg
			else:
				TSClntDatagramProtocol.send_data.append(send_msg)
				
			protocol = TSClntDatagramProtocol()
			try:
				# 判断是否需要绑定源端口
				if self.src_port == 0:
					reactor.listenUDP(0, protocol)
				else:
					reactor.listenUDP(self.src_port, protocol, interface=self.src_ip)
				
				reactor.callLater(30, self._check_recv_flag)	
				reactor.run()
			except Exception, e:
				status.value = 3
				log_data = "send udp package ocurrs exception, error info is %s" % e
				log.debug_info(log_data)
			
			if TSClntDatagramProtocol.connection_status:
				fail_num = TSClntDatagramProtocol.connection_status.count(0)
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
		
		
	def send_udp_package(self, dst_ip, dst_port, send_msg="hello,world!"):
		"""
		功能描述：发送udp报文到UDP Server，并接收回应，验证链路是否通
		
		参数：
			dst_ip: UDP报文的目的IP
			dst_port: UDP报文的目的port
			send_msg: UDP报文的消息内容
			
		返回值：
			ATTUDPCLIENT_SUC， log_data 表示通
			ATTUDPCLIENT_FAIL, log_data 表示不通
			ATTUDPCLIENT_PORT_BUSY, log_data 表示端口被占用 
		"""
		
		# 创建子进程启动UDP Client
		try:
			sub_process = Process(target=self._send_udp_package, args=(dst_ip, dst_port, send_msg, self.connection_status))
			sub_process.start()
			sub_process.join()
		except Exception, e:
			log_data = "Start UDP Client occurs exception,error message is: %s" % e
			log.debug_err(log_data)
			return ATTUDPCLIENT_FAIL, log_data
		
		if self.connection_status.value <= 0:
			log_data = u"发送报文失败，链路不通"
			return ATTUDPCLIENT_FAIL, log_data
		
		elif self.connection_status.value == 2:
			log_data = u"地址 %s 的 %s 端口已经被占用，请使用其他端口." % (self.src_ip, str(self.src_port))
			return ATTUDPCLIENT_PORT_BUSY, log_data
		
		elif self.connection_status.value == 3:
			log_data = u"发送报文发生异常" 
			return ATTUDPCLIENT_FAIL, log_data
		
		else:
			log_data = u"发送报文成功!"
			return ATTUDPCLIENT_SUC, log_data


def test():
	src_ip = '172.16.28.49'
	src_port = 50000
	
	dst_ip = "172.16.28.49"
	dst_port = 55555
	
	send_msg = "123456789"
	
	obj = ATTUDPClient()
	ret = obj.is_udp_port_idle(src_port, src_ip)
	print ret
	
	obj.set_udp_src_addr(src_port, src_ip)
	
	ret = obj.send_udp_package(dst_ip, dst_port, send_msg)
	print ret
	

if __name__ == '__main__':
	test() 