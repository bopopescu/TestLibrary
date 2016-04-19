# -*- coding: utf-8 -*- 
import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from initapp import REMOTE_PORTS

from attcommonfun import *
from ATTTelnet import ATTTelnet
from robotremoteserver import RobotRemoteServer
import attlog as log
REMOTE_PORT = REMOTE_PORTS.get('Telnet')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 60*60

class Telnet(): 
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION
    
    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}
        self._conn = None
        self.list_cls_local = []         # lwb: 2013-04-20 定义本端的实例列表
        self.list_cls_remote = []        # lwb: 2013-04-20 定义远端的实例列表

    def _register_alias(self, alias, host, remote_url):
        
        # 对别名判断做了修改 zsj 2013-3-28
        # 改成以别名为健（当前要求别名唯一） change by yzm @ 20130328
        # 因前面已经保证了alias唯一，则直接对alias进行赋值（赋新值可保证网卡信息为最新的信息）
        self.dict_alias[alias] = (host, remote_url)

    def _is_init(self, alias, host, remote_url):
        """
        return alias
        """
        # 先判断别名是否被使用过
        tuple_value  = self.dict_alias.get(alias)
        if tuple_value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url以及name或者mac）
            if remote_url in tuple_value and host in tuple_value:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            # 如果没被使用过，需判断当前的对象是否曾经被初始化过
            for key, tuple_value in self.dict_alias.items():
                if remote_url in tuple_value and host in tuple_value:
                    # 如果相符，则可以直接返回_key（只要找到即可返回）
                    return key 

        # 两种情况都不包含，则返回None
        return None
    
    def init_telnet_connection(self, alias, host, remote_url=False):
        """
        功能描述：初始化telnet连接，将本端或远端的telnet使用别名代替，方便后面的切换； 
        
        参数: 
            
            alias：用户自定义的telnet连接别名；
            
            host：将要打开的telnet连接CPE的IP地址；
            
            remote_url：配置远端地址,默认为False，即不启用远端； 
        
        返回值：
            
            初始化telnet连接的个数；
        
        Example:
        | Init Telnet Connection    | local   |  192.168.1.1    |
        | Init Telnet Connection    | remote  |  192.168.1.1    | http://172.16.28.55 | 
        """
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._is_init(alias, host, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
                self.list_cls_remote.append(reallib)  # lwb: 2013-04-20 把所有的ATTTelnet对象放在实例列表中
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(alias, host, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = ATTTelnet(host)
                self.list_cls_local.append(reallib)  # lwb: 2013-04-20 把本端的ATTTelnet对象放在本端实例列表中
        
        tag = self._cache.register(reallib, alias) 
        self._register_alias(alias, host, remote_url)
        
        return tag
    
    def _current_remotelocal(self):
        if not self._cache.current:
            raise RuntimeError('No remotelocal is open')
        
        return self._cache.current       
    
    def switch_telnet_connection(self, alias):
        """
        功能描述：切换telnet连接；
        
        参数：
            
            alias：用户初始化时设置的telnet连接别名；
        
        返回值：
            
            无；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23     |  3    |   >     |
        | Telnet Login              |  admin  |  admin  |  
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23     |  3    |   >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |  
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |  
        """
        try:
            cls=self._cache.switch(alias)    # 返回的是一个连接实例
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            # lwb:2013-03-12 增加个else分支，防止切换到远端的时候重复打印。
            else:
                log_data = u'成功切换到别名为：%s 的远程登录下，后续操作都是针对该远程登录连接，直到下一个切换动作' % (alias)
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)
        
    def telnet_open_connection(self, port, timeout=None,
                               prompt='> ', prompt_is_regexp=False, encoding=None):
        """
        功能描述：打开telnet连接；
        
        参数：
            
            port：打开telnet连接的端口号；
            
            timeout: 设置打开telnet连接的超时时间；
            
            prompt：提示符；
            
            pormpt_is_regexp：所给出的提示符是不是以正则表达式的形式给出；
            
            encoding：字符编码，默认为'UTF-8'；
        
        返回值：
        
            无；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23    |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |  
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.telnet_open_connection(int(port), timeout, prompt, prompt_is_regexp, encoding, default_log_level="INFO")
    

    def telnet_close_all_connections(self):
        """
        功能描述：关闭所有打开的telnet连接,包括本端和远端所有打开的telnet连接
        
        参数：
            
            无；
        
        返回值：
            
            无；
    
        备注：
            
            此关键字常用于拆除里面作清理操作，对所有已打开的telnet连接进行关闭，如果打开连接失败
            再在拆除里面执行此关键字，此关键字也会报关闭已打开的所有telnet连接成功；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |  
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |
        | Telnet Close All Connections        |
        """
       # 重新封装telnet_close_all_connections函数，增加log输出，方便用户查看 lwb:2013-05-02
        
        if 0 == len(self.list_cls_remote) and 0 == len(self.list_cls_local):
            return
        
        # 判断有没有远端实例 lwb: 2013-04-20 
        for cls in self.list_cls_remote:
            if (isinstance(cls, Remote)):
                auto_do_remote(cls)
        
        # 关闭所有打开的连接,如果list_cls_local列表中没有数据，就不进行关闭 lwb: 2013-04-22 
        for cls in self.list_cls_local:
            cls.telnet_close_all_connections()
        
        # 如果只有本端，则在本端进行log输出 lwb:2013-05-02
        if len(self.list_cls_remote)>0: 
            pass
        elif len(self.list_cls_remote)==0 and len(self.list_cls_local)>0: 
            log_data = u"关闭所有telnet连接,包括本端和远端" 
            log.user_err(log_data)
        
        # 清空列表 lwb:2013-04-22
        #del by jias 用例重复执行时，第二次self.list_cls_remote为NULL，不能调用到ATT层的关闭
        #self.list_cls_remote = []
        #self.list_cls_local = []
   
    def telnet_set_timeout(self, timeout):
        """
        功能描述：设置超时时间，并返回上一次设置的超时时间；
        
        参数：
             
             timeout：设置超时时间，此超时时间用于底层模块的read操作的超时时间；
        
        返回值：
            
            返回上一次模块的超时时间；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |
        | ${old_timeout}            | Telnet Set Timeout  | 10  |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_set_timeout(timeout)
        return ret

    def telnet_set_newline(self, newline=""):
        """
        功能描述：设置回车换行符，并返回上一次设置的回车换行符；
        
        参数：
            
            newline：回车换行符；
             
            参数取值范围为['LF','CR','CRLF'](大小写不限)或空值
            
        备注：
            
            1、回车换行符参数('LF','CR','CRLF')相当于('\\n','\\r','\\r\\n').
            
            2、空值表示不进行设置。
        
        返回值：
        
            返回上一次模块的回车换行；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |
        | ${old_newline}            | Telnet Set Newline  | CR  |
        """        
        if newline == None:
            newline = "" 
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_set_newline(newline)
        return ret

    def telnet_set_prompt(self, prompt, prompt_is_regexp=False):
        """
        功能描述：设置提示符，并返回上一次设置的提示符；
        
        参数：
             
             prompt：设置提示符；
             
             prompt_is_regexp：提示符是否是正则表达式；
        
        返回值：
            
            返回上一次模块的提示符；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  |
        | ${old_prompt}             | Telnet Set Prompt | >  |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_set_prompt(prompt, prompt_is_regexp)
        return ret

    def telnet_set_encoding(self, encoding):
        """
        功能描述：设置编码，并返回上一次设置的编码；
        
        参数：
             
             encoding：设置编码，默认编码为'UTF-8'；
        
        返回值：
            
            返回上一次模块的编码；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  |
        | ${old_encoding}            | Telnet Set Encoding  | ASCII  |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_set_encoding(encoding)
        return ret


    def _telnet_set_default_log_level(self, level):
        """
        功能描述：设置日志等级，并返回上一次设置的日志等级；
        
        参数：
             
             level：设置日志等级，默认日志等级为'INFO'，其取值范围为['TRACE', 'DEBUG', 'INFO', 'WARN']；
        
        返回值：
        
            返回上一次模块的日志等级；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  |
        | ${old_log_level}          | Telnet Set Default Log Level  | DEBUG  |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_set_default_log_level(level)
        return ret


    def telnet_close_connection(self):
        """
        功能描述：关闭当前已打开的telnet连接；
        
        参数：
            
            无
        
        返回值：
            
            无；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |
        | Telnet Close Connection   |         |
        """
        cls = self._current_remotelocal()  
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.telnet_close_connection(loglevel="INFO")
        # self._del_dict_alias(alias)
        
    def _del_dict_alias(self, alias):
        """
        在远端先初始化打开一个telnet连接(alias=local,host=192.168.1.1)，然后再关闭此telnet连接时，再远程初始化打开此telnet连接(alias=remote,port=192.168.1.1)，
        由于(alias=local,host=192.168.1.1)等信息还保存在alias中,所以再远程初始化的时候,并不到远程做初始化,仅仅在本端做切换,所以
        远端的信息并没有改变.因此再做切换(alias=remote)，在远端会找不到别名remote,依然存在的是local
        """
        for key in self.dict_alias.keys():
            if self.dict_alias[key] == alias:
                del self.dict_alias[key]

    def telnet_login(self, username, password, login_prompt='Login: ',
              password_prompt='Password: ', login_timeout='10',
              success_prompt="> "):
        """
        功能描述：用户登录；
        
        参数：
             
             username：登录用户名；
             
             passeord：登录密码；
             
             login_prompt：登录用户名提示符；
             
             password_prompt：登录密码提示符；
             
             login_timeout：登录超时时间，默认为10s；
             
             success_prompt：成功登录提示符；
        
        备注：
        
            1、telnet open connection里面的timeout是模块超时时间，主要运用于底层的read相关操作。
              login_timeout是用户登录的超时时间，主要用于用户登录，由于用户登录功能封装了read相关操作，
              所以login_timeout超时时间应该要大于telnet open connection里面的timeout超时时间。
            
            2、若登录前没有使用Telnet Set Newline关键字设置newline，则会遍历('\\n','\\r','\\r\\n')自动识别newline。
        
        返回值：
        
            返回成功登录过程，若登录失败，则抛出异常；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  Login:  |  Passwrod:  |  10  |  >  |
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |
        | Telnet Close Connection   |         |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_login(username, password, login_prompt, password_prompt, login_timeout, success_prompt)
        return ret


    def telnet_write(self, text):
        """
        功能描述：写入数据，并追加一个换行符，相当于执行了一个命令；
        
        参数：
             
             text：写入的命令；
        
        返回值：
            
            返回写入的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet write    |  help   |
        | ${res} |  Telnet Read Until |  cat  |
        | Telnet Close Connection   |         |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_write(text, loglevel="INFO")
        return ret

    def telnet_write_bare(self, text):
        """
        功能描述：写入数据，并不追加一个换行符，相当于写入一个字符串文本；
        
        参数：
             
             text：写入的文本；
        
        返回值：
            
            无；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet Write Bare    |  please help me  |  #写入字符串   |
        | ${res} |  Telnet Read Until |  help  | #读取字符串，直到help为止  |
        | Telnet Close Connection   |       |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.telnet_write_bare(text)

    def telnet_write_until_expected_output(self, text, expected, timeout,
                                    retry_interval):
        """
        功能描述：写入数据，并不追加一个换行符，相当于写入一个字符串文本text，
                  重复写入timeout/retry_interval次，若在第1次中找到text中与expected
                  相匹配的字符串，就停止，并返回写入的数据；
        
        参数：
             
             text：写入的文本；
             
             expected：与写入文本里面相匹配的字符串；
             
             timeout：超时时间；
             
             retry_interval：时间间隔；
        
        返回值：
            
            返回所读取到的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | ${res} | Telnet Write Until Expected Output   |  help\\n  |  cat  |  5  |  0.5  | #下发一个help命令，在返回的数据中查找cat,若10次都没有找到，则失败  |
        | ${res} | Telnet Write Until Expected Output   |  help cat me  |  cat  |  5  |  0.5  | #在'help cat me '中查找cat,若10次都没有找到，则失败  |
        | Telnet Close Connection   |      |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_write_until_expected_output(text, expected, timeout, retry_interval, loglevel="INFO")
        return ret

    def telnet_read(self):
        """
        功能描述：读出当前输出流中的数据；
        
        参数：
            
            无；
        
        备注：
            
            telnet read读取一次数据最大花费时间由telnet set timeout控制
        
        返回值：
            
            返回所读取到的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet Write    |  help   |
        | ${res} |  Telnet Read     |         | 
        | Log    |  ${res}          |         | 
        | Telnet Close Connection   |       |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_read(loglevel="INFO")
        return ret

    def telnet_read_until(self, expected):
        """
        功能描述：读出当前输出流中的数据直到与给出的expected期望值相匹配才停止；
        
        参数：
             
             expected：期望匹配的字符串；
             
        备注：
            
            telnet read until读取一次数据最大花费时间由telnet set timeout控制；
        
        返回值：
            
            根据所给出的expected，返回所读取到的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet Write    |  help   |
        | ${res} |  Telnet Read Until  |    cat     | 
        | Log    |  ${res}          |         | 
        | Telnet Close Connection   |     |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_read_until(expected, loglevel="INFO")
        return ret

    def telnet_read_until_regexp(self, *expected):
        """
        功能描述：读出当前输出流中的数据直到与给出的expected列表中的期望值相匹配才停止，
                  参数可以是正则表达式，也可以是字符串，如果与给出的参数一个都不匹配，
                  用例题执行失败；
        
        参数：
             
             *expected：期望匹配的字符串或正则表达式，参数个数不限；
        
        备注：
            
            telnet read until regexp读取一次数据最大花费时间由telnet set timeout控制；
        
        返回值：
            
            根据所给出的*expected，返回所读取到的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3     |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet Write    |  help   |
        | ${res} |  Telnet Read Until Regexp  |   catte   |   c\\\wt  | #第2个参数与输出流中的cat相匹配   |
        | Telnet Write    |  help   |
        | ${res} |  Telnet Read Until Regexp  |   cat     |   save  | #第1个参数与输出流中的cat相匹配   |
        | Log    |  ${res}          |         | 
        | Telnet Close Connection   |        |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_read_until_regexp(*expected)
        return ret


    def telnet_read_until_prompt(self):
        """
        功能描述：读取当前的输出信息，直到出现当前设置的prompt为止，系统默认为'> '；
        
        参数：
            
            无；
        
        备注：
            
            telnet read until prompt读取一次数据最大花费时间由telnet set timeout控制；
        
        返回值：
            
            返回所读取到的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  | 
        | Telnet Write    |  help   |
        | ${res} |  Telnet Read Until Prompt  |         |
        | Telnet Close Connection   |       |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_read_until_prompt(loglevel="INFO")
        return ret

    def telnet_execute_command(self, command):
        """
        功能描述：执行命令，里面包括了读和写的功能；
        
        参数：
             
             command：执行的命令；
        
        返回值：
            
            返回写入的命令执行后的数据；
        
        Example:
        | Init Telnet Connection    |  local  |  192.168.1.1     |
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  Login:  |  Passwrod:  |  10  | >  |
        | Init Telnet Connection    |  remote |  192.168.1.1     | http://172.16.28.55 |  
        | Telnet Open Connection    |  23      |  3    |  >     |
        | Telnet Login              |  admin  |  admin  |  
        | Switch Telnet Connection  |  local  |
        | Telnet Execute Command    |  help   |
        | Switch Telnet Connection  |  remote |
        | Telnet Execute Command    |  ps     |
        | Telnet Close Connection   |      |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            ret = auto_do_remote(cls)
        else:
            ret = cls.telnet_execute_command(command, loglevel="INFO")
        return ret

def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(Telnet(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)

def Test():
    tel = Telnet()
    tel.init_telnet_connection(alias="local", host="192.168.1.1", remote_url = "192.168.1.2:58013")
    tel.telnet_open_connection(port=23, prompt="> ")
    tel.telnet_login('admin', 'admin')
    tel.init_telnet_connection(alias="remote", host="192.168.0.1", remote_url = "192.168.1.2:58013")
    tel.telnet_open_connection(port=23, prompt="> ")
    tel.telnet_login('admin', 'admin')
    tel.telnet_close_all_connections()
    tel.switch_telnet_connection("local")
    tel.telnet_execute_command('ifconfig')
    tel.switch_telnet_connection("remote")
    tel.telnet_execute_command('ifconfig')
    
if __name__ == '__main__':
    Test()