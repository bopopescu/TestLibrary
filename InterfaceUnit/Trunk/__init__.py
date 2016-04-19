# -*- coding: utf-8 -*-
#加载测试库依赖的平台模块
from robot.utils import ConnectionCache
from robot.errors import DataError

#测试库远端属性客户端
from robot.libraries.Remote import Remote
#测试库远端属性服务端
from robotremoteserver import RobotRemoteServer

#加载测试库依赖平台公共接口
import attlog as log
from attcommonfun import *

#加载测试库底层功能实现模块
from ATTInterfaceUnit import ATTInterfaceUnit

VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600


#没有对象的异常类
class No_Remote_or_local_Exception(Exception):
    pass

class InterfaceUnit():
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        """
        initial
        """
        
        self._cache = ConnectionCache()
        self.dict_alias = {}  
    
    def _register_alias(self, alias, remote_url):
        """
        注册别名和remote_url
        """
        
        self.dict_alias[alias] = (remote_url,)
    
    def _is_init(self, alias, remote_url):
        """
        判断别名是否被使用过，
        如果是被同一个对象使用，返回别名,不是同一个对象，报错，
        没有被使用过则返回None
        """
        
        # 先判断别名是否被使用过
        tuple_value  = self.dict_alias.get(alias)
        if tuple_value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url）
            if remote_url in tuple_value:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            return None
    
    
    def _current_remotelocal(self):
        """
        返回当前别名的对象，可能是remote，也可能是local。如果不存在则抛出异常
        """
        
        if not self._cache.current:
            raise No_Remote_or_local_Exception
            
        return self._cache.current     
         
    def init_interfaceUnit(self, alias, remote_url=False):
        """
        功能描述：初始化一个本地或远端的Interface Unit；
        
        参数：
            alias：InterfaceUnit的别名，用于唯一标识某一个InterfaceUnit；
            
            remote_url：如果要进行远程控制，传入远程控制的地址，格式为：http://remote_IP；否则使用默认值；
            
        注意别名请设置为不同的别名，切换的时候用别名进行切换。
        
        Example:
        | Init InterfaceUnit  | local   |                    |
        | Init InterfaceUnit  | remote  | http://10.10.10.85 |
        """
        
        # 检测用户输入的remote_url是否有“http://”头，如果没有则自动添加
        remote_url = modified_remote_url(remote_url)
        
        # 本地和远端采用不同的处理
        if (is_remote(remote_url)):
            # 判断当前别名是否已经初始化了,如果初始化了，则切换之前注册的remote object，否则新注册一个Remote object
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            # 设置远端连接的超时
            reallib._client.set_timeout(REMOTE_TIMEOUT)
            # 发送消息到远端执行
            auto_do_remote(reallib)
            
        else:
            # 判断当前别名是否已经初始化了,如果初始化了，则切换之前注册的local object，否则新注册一个local object
            ret_alias = self._is_init(alias, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTInterfaceUnit()
                
        # 注册object对象和别名    
        tag = self._cache.register(reallib, alias)
        # 注册别名和remote_url
        self._register_alias(alias, remote_url)
        
        return tag
        
    def switch_interfaceUnit(self, alias):
        """
        功能描述：切换当前已初始化的InterfaceUnit；
        
        参数：
            alias：InterfaceUnit的别名，用于唯一标识某一个InterfaceUnit；
        
        返回值：
            无
        
        Example:
        | Init InterfaceUnit   | local   |                    |
        | Init InterfaceUnit   | remote  | http://10.10.10.85 |
        | Switch InterfaceUnit | local   |                    |
        """
        
        try:
            obj = self._cache.switch(alias)                 
            if (isinstance(obj, Remote)):
                # remote class do switch
                auto_do_remote(obj)
            else:
                log_data = u'切换到别名为：%s 的Interface Unit成功' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError(u"没有找到别名对应的对象：'%s'" % alias)
    def app_interface_set_tcp_dst_addr(self, ip, port):
        """
        功能描述：设置TCP发包的目的IP和端口；
        
        参数：
            ip：APP接口TCP发送数据报文的目的IP；
            port：APP接口TCP发送数据报文的目的port；
        
        返回值：
            无
        
        Example:
        | Init InterfaceUnit   | local   |                    |
        | Init InterfaceUnit   | remote  | http://10.10.10.85 |
        | App Interface Set Tcp Dst Addr | 192.168.1.1 | 17998 |
        """
        # 检查IP地址合法性
        if not check_ipaddr_validity(ip):
            raise RuntimeError(u"关键字执行失败，IP地址为非法地址！")
        
        # 检查port端口合法性
        ret, ret_str = check_port(port)
        if ret == ATTCOMMONFUN_FAIL:
            raise RuntimeError(ret_str)
        try:
            obj = self._current_remotelocal()
        except No_Remote_or_local_Exception:
            raise RuntimeError(u"Interface Unit未初始化，请先初始化!")
        
        #判断节点对象属性是否为远端库
        if (isinstance(obj, Remote)):
            #调用接口请求远端执行关键字
            auto_do_remote(obj)
        else:
            obj.set_tcp_dst_addr(ip, port)
            log.user_info(u'APP接口TCP目的地址：(%s:%s)' %(obj.tcp_ip,obj.tcp_port))
    
    def app_interface_set_prefix(self, RPCMethod='',ID='',Plugin_Name='',Version='',SequenceId=''):
        """
        功能描述：设置APP接口测试报文的前缀，将RPCMethod，ID，Plugin_Name，Version，SequenceId固定值设置
        
        参数：
            RPCMethod: 请求数据中的RPCMethod值
            
            ID： 请求数据中的ID值
            
            Plugin_Name:请求数据中的Plugin_Name值
            
            Version:请求数据中的Version值
            
            SequenceId:请求数据中的SequenceId值
        
        返回值：
            无
        
        Example:
            | App Interface Set Prefix | Post1 | 12345 | test | 1.0 | 1234AABB |
        """
        try:
            obj = self._current_remotelocal()
        except No_Remote_or_local_Exception:
            raise RuntimeError(u"Interface Unit未初始化，请先初始化!")
        #判断节点对象属性是否为远端库
        if (isinstance(obj, Remote)):
            #调用接口请求远端执行关键字
            auto_do_remote(obj)
        else:
            obj.set_app_interface_prefix(str(RPCMethod),str(ID),str(Plugin_Name),str(Version),str(SequenceId))
            log.user_info(u'APP接口设置前缀成功：(%s)' %(obj.app_interface_prefix))
            
    def app_interface_send_tcp_request(self,CmdType,args='',timeout=15):
        """
        功能描述：发送APP接口指定的TCP请求报文。
        
        参数：
            CmdType: 请求报文中parameter字段中的CmdType；
            
            args：请求报文中parameter字段中的其它内容；
        
        返回值：
            响应报文中的内容，以字典格式返回。
        
        Example:
        | Init InterfaceUnit   | local   |                    |
        | Init InterfaceUnit   | remote  | http://10.10.10.85 |
        | App Interface Set Tcp Dst Addr | 192.168.1.1 | 17998 |
        | App Interface Set Prefix | Post1 | 12345 | test | 1.0 | 1234AABB |
        | ${resp} | App Interface Send Tcp Request | SET_LANDEVSTATS_STATUS | ${'enable':'1'} |
        | ${parameter} | Get From Dictionary | ${resp} | return_Parameter |
        | ${status} | Get From Dictionary | ${parameter} | Status |
        """
        try:
            obj = self._current_remotelocal()
        except No_Remote_or_local_Exception:
            raise RuntimeError(u"Interface Unit未初始化，请先初始化!")
        #判断节点对象属性是否为远端库
        if (isinstance(obj, Remote)):
            #调用接口请求远端执行关键字
            resp_data=auto_do_remote(obj)
        else:
            #转换为dict
            if not isinstance(args,dict) and args!='':
                args=eval(args)
            #查看APP接口前缀是否设置    
            if obj.app_interface_prefix==None:
                raise RuntimeError(u"APP接口报文前缀未设置，请先设置")
            #组合APP接口数据
            req_data=obj.compose_app_interface_data(CmdType,args)
            #加密数据   
            ret,req_data=obj.base64_interface_parameter(req_data)   
            if not ret:
                raise RuntimeError(req_data)
            #执行TCP发送并接收
            ret,resp_data= obj.execute_tcp_request(req_data,timeout=timeout)     
            if ret:
                log.user_info(u'APP接口发送TCP请求成功')
            else:
                raise RuntimeError(resp_data)
        return resp_data
    def _convert_bool(self, arg):
        """
        转换字符串类型True和False为布尔型
        """        
        if isinstance(arg, bool):
            return arg        
        elif arg.lower() == 'false':
            return False
        else:
            return True

def start_library(library_name=""):
    try:
        RobotRemoteServer(ATTInterfaceUnit())
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)
        
        
        
if __name__ == '__main__':
    tcp = InterfaceUnit()
    tcp.init_interfaceUnit(alias = "local")
    c={"RPCMethod":u"Post1",
       "ID":12345,
       "Plugin_Name":u"test",
       "Version":u"1.0",
       "Parameter":
        {
        "CmdType":"GET_ATTACH_DEVICE_BANDWIDTH",
        "MAC":"44:8A:5B:53:56:8A",
        "SequenceId":"1234AABB"
        }
        }
    tcp.app_interface_set_prefix("Post1",12345,"test","1.0","1234AABB")
    #b= tcp.send_tcp_request_of_app_interface('SET_LANDEVSTATS_STATUS',{"enable":"1"})QUERY_SYSTEM_INFO
    b= tcp.send_tcp_request('QUERY_SYSTEM_INFO')

    print type(b),b