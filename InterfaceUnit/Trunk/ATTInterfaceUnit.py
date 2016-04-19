# -*- coding: utf-8 -*-
import base64
import socket
import struct
import json


class ATTInterfaceUnit(object):
    
    def __init__(self):
        self.tcp_socket = None
        self.http_conn = None
        self.app_interface_prefix=None
        self.set_tcp_dst_addr()
    def set_tcp_dst_addr(self, ip='192.168.1.1',port=17998):
        """
        重新设置TCP访问的IP和端口
        """
        self.tcp_ip = ip
        self.tcp_port = int(port)
        
    def set_app_interface_prefix(self,RPCMethod='',ID='',Plugin_Name='',Version='',SequenceId=''):
        """
        设置post1的前缀
        """
        self.app_interface_prefix={}
        name=['RPCMethod','ID','Plugin_Name','Version']
        for i in name:
            if eval(i)!='' and eval(i)!=None:
                self.app_interface_prefix.update({i:eval(i)})
        if SequenceId=='' or SequenceId==None:
            self.app_interface_prefix.update({"Parameter":{}})
        else:
            self.app_interface_prefix.update({"Parameter": {"SequenceId":SequenceId}})
    def compose_app_interface_data(self,CmdType,args={}):
        """
        将app_interface的前缀和parameter组合起来
        CmdType格式str，args格式dict
        """
        data=self.app_interface_prefix.copy()
        paramValue = data['Parameter']
        paramValue['CmdType']=CmdType
        if args!='' and args!=None and args!={}:
            paramValue.update(args)
        return data
    def base64_data(self,data,base64_type='b64encode'):
        """
        将数据进行base64编码。
        """
        if base64_type=='b64encode':
            ret_data= base64.b64encode(str(data))
        elif base64_type=='b64decode':
            ret_data= base64.b64decode(str(data))
        else:
            raise TypeError(u"base64编码格式为:%s，请检查" %base64_type)
        return ret_data
    def base64_interface_parameter(self,data,dict_key='Parameter',base64_type='b64encode'):
        """
        将字典里指定的字段base64编码,base64_type='b64encode'base64_type='b64decode'为解密
        data输入dict格式，输出dict格式，没有对应的dict_key字段将不仅学base64转化。
        """
        try:
            if data.has_key(dict_key):
                paramValue = data[dict_key]
                paramValue = json.dumps(paramValue,sort_keys=True)
                temp=self.base64_data(str(paramValue),base64_type)
                #加密
                if base64_type=='b64encode':
                    data[dict_key]=temp
                #解密，需要转换为python格式
                else:
                    data[dict_key]=json.loads(temp)
            return True,data
        except Exception, e:
            err_info=u"转换%s的%s字段编码失败：%s" %(data,dict_key,e)
            return False,err_info
        
    def _tcp_receive(self,req_len=True):
        """
        接受TCP请求回复，返回接收数据
        """
        #数据携带数据长度
        if req_len:
            resp = self.tcp_socket.recv(4)
            (respLen, ) = struct.unpack("!I", resp)
        #数据未携带数据长度
        else:
            respLen=1024
        resp = self.tcp_socket.recv(respLen)
        respJson = json.loads(resp)
        #return_Parameter参数b64decode编码
        ret,resp_data=self.base64_interface_parameter(respJson,'return_Parameter','b64decode')
        if ret:
            return resp_data
        else:
            raise TypeError(resp_data)
        
    def execute_tcp_request(self,req,req_len=True,timeout=15):
        """
        发送TCP请求，及返回接收数据
        req:TCP请求内容，要求输入dict或str，不能是json格式。
        """
        #转换为json格式
        req = json.dumps(req)
        #转换可传输报文格式
        reqLen = len(req)
        if req_len:
            fmt = "!I%us" %(reqLen)
            req_data = struct.pack(fmt,int(reqLen),req)
        else:
            fmt = "!%us" %(reqLen)
            req_data = struct.pack(fmt,req)
        #socket建立
        try:
            self.tcp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.tcp_socket.connect((self.tcp_ip,self.tcp_port))
            self.tcp_socket.settimeout(float(timeout))
        except Exception,e:
            self.tcp_socket.close()
            user_err=u"TCP连接失败，失败原因：%s" %e
            return False,user_err
        #TCP进行发包，收包处理
        try:
            self.tcp_socket.send(req_data)
            resp_data=self._tcp_receive()
        except Exception, e:
            user_err=u"TCP数据传输失败，失败原因：%s" %e
            return False, user_err
        finally:
            self.tcp_socket.close()
        return True,resp_data
        
        
if __name__ == '__main__':
    print 123
    aa=ATTInterfaceUnit()
    aa.set_tcp_dst_addr()
    #cc={"enable":"1"}
    #print cc
    #aa.set_app_interface_prefix("Post1",12345,"test","1.0","1234AABB")
    #d=aa.compose_app_interface_data('SET_LANDEVSTATS_STATUS',cc)
    #print d
    c={u"RPCMethod":u"Post1",
       u"ID":12345,
       u"Plugin_Name":"test",
       u"Version":"1.0",
       u"Parameter":{u"CmdType":u"SYSTEST",u"SequenceId": u"1234AABB"}
        }
    print type(c)
#    dd={u'Version': u'1.0', u'Parameter': u'eydNQUMnOiAnNDQ6OEE6NUI6NTM6NTY6OEEnLCAnU2VxdWVuY2VJZCc6ICcxMjM0QUFCQicsICdDbWRUeXBlJzogJ0dFVF9BVFRBQ0hfREVWSUNFX0JBTkRXSURUSCd9', u'ID': 12345, u'Plugin_Name': u'test', u'RPCMethod': u'Post1'}
    #req = json.dumps(c)
    #print req
    e,dd=aa.base64_interface_parameter(c)
    
    print dd
    #req_data = json.dumps("ddddggggggggggggggggggggggggggggggggggdd")
    a,b= aa.execute_tcp_request(dd)
    print a,type(b),b
    ccc=json.dumps(b)
    print type(ccc)
    ##
    #d=aa.compose_app_interface_data('QUERY_SYSTEM_INFO')
    #e,dd=aa.base64_interface_parameter(d)
    #a,b= aa.execute_tcp_request(dd)
    #InterfaceUnit
    #reqJson = eval(b)
   # print aa.execute_http_request('/',c)
    
    #c=reqJson['return_Parameter']
    #c = eval(c)
    #print c['Status']