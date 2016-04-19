# -*- coding: utf-8 -*-
import os
import sys
import time

from robot.utils import ConnectionCache
from robot.errors import DataError
from robot.libraries.Remote import Remote

from attcommonfun import *
from ATTFtpClient import ATTFtpClient
from robotremoteserver import RobotRemoteServer
from initapp import REMOTE_PORTS
import attlog as log
REMOTE_PORT = REMOTE_PORTS.get('FtpClient')
VERSION = '1.0.0'
REMOTE_TIMEOUT = 3600
MAX_TRA_FILE_TIME = 86400

class FtpClient():
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        self._cache = ConnectionCache()
        self.dict_alias = {}
        self.clientpath = os.getcwd() # GCW 2013-02-21 初始化时将工程目录名保存
        
    def _register_alias(self, alias, port, remote_url):
        
        # 对别名判断做了修改 zsj 2013-3-28
        # 改成以别名为健（当前要求别名唯一） change by yzm @ 20130328
        # 因前面已经保证了alias唯一，则直接对alias进行赋值（赋新值可保证网卡信息为最新的信息）
        self.dict_alias[alias] = (port, remote_url)

    def _is_init(self, alias, port, remote_url):
        """
        return alias
        """
        # 先判断别名是否被使用过
        tuple_value  = self.dict_alias.get(alias)
        if tuple_value:
            # 如果被使用过，需要判断是否被当前对象使用（相同的remote_url以及name或者mac）
            if remote_url in tuple_value and port in tuple_value:
                # 如果相符，则可以直接返回alias
                return alias 
            else:
                raise RuntimeError(u"别名 %s 正在被另外的对象使用，请选择另外的别名！" % alias)
        else:
            # 如果没被使用过，需判断当前的对象是否曾经被初始化过
            for key, tuple_value in self.dict_alias.items():
                if remote_url in tuple_value and port in tuple_value:
                    # 如果相符，则可以直接返回_key（只要找到即可返回）
                    return key 

        # 两种情况都不包含，则返回None
        return None
    
    def init_ftp_client(self, alias ,port, remote_url=False):
        """
        功能描述：初始化执行ftp client；
        
        参数：
            alias：别名；
            port：服务器所打开的端口号；
            remote_url：是否要进行远程控制；
        格式为：http://remote_IP.可以用以下的几种方式进行初始化。
        注意别名请设置为不同的别名，切换的时候用别名进行切换。
        
        Example:
        | Init Ftp Client  | Local   | 21     |
        | Init Ftp Client  | remote  | 21     | http://10.10.10.85 |
        """
        # 对用户输入的remote_url做处理转换，添加http://头等
        remote_url = modified_remote_url(remote_url)
        
        if (is_remote(remote_url)):
            # already init?
            ret_alias = self._is_init(alias, port, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
            else:
                reallib = Remote(remote_url)
            
            reallib._client.set_timeout(REMOTE_TIMEOUT)  # add connection remote timeout zsj 2013-3-28
            auto_do_remote(reallib)
                           
        else:
            # already init?
            ret_alias = self._is_init(alias, port, remote_url)
            if (ret_alias):
                reallib =  self._cache.switch(ret_alias)
                #清空之前建立的连接对象  #add by jias 20130810               
                #当相同的2个用例一起执行的时候，第二个用例初始化时，会直接去第一用的ftpclient对象，
                #这时，远端server已经重新启动，故清空之前的连接和标志
                reallib.clear()
            else:
                reallib = ATTFtpClient(port)
            
        tag = self._cache.register(reallib, alias)
        self._register_alias(alias, port, remote_url)

        return tag
    
    def _current_remotelocal(self):
        if not self._cache.current:
            raise RuntimeError('No remotelocal is open')
        return self._cache.current       
    
    def switch_ftp_client(self, alias):
        """
        功能描述：切换当前已开启的ftp client；
        
        参数：
            alias：别名；
        
        Example:
        | Init  Ftp Client  | local_1     | 21       |
        | Should Connect Ftp success  | 10.10.10.10 |  ftptest | ftptest |
        | Init  Ftp Client  | local_2     | 22       |
        | Should Connect Ftp success  | 10.10.10.10 |  ftptest | ftptest |
        | Switch Ftp Client | local_1     |          |
        """
        try:
            cls=self._cache.switch(alias)                 
            if (isinstance(cls, Remote)):
                # remote class do switch
                auto_do_remote(cls)
            else:
                log_data = u'切换到别名为：%s 的FtpClient成功' % alias
                log.user_info(log_data)
        except (RuntimeError, DataError):  # RF 2.6 uses RE, earlier DE
            raise RuntimeError("No remotelocal with alias '%s' found."
                                       % alias)  
    
        
    def should_connect_ftp_fail(self, host, username='', password='', timeout=20):
        """
        功能描述：连接并登录FTP服务器。登录失败则表示关键字执行成功
        
        参数： 
            host: FTP服务器地址
            username: 连接服务器的用户名,空表示匿名登录,一般服务器对匿名登录的用户有权限限制
            password: 连接服务器的密码
            timeout: 连接超时时长，单位为秒
            
        返回：无,关键字执行失败则抛出错误
        
        Example:
        | Should Connect Ftp Fail | 172.24.11.22 |
        | Should Connect Ftp Fail | 172.24.11.10 | 
        | Should Connect Ftp Fail | 172.24.11.10 | abc | abc |
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # change by jxy ,2013/4/2,增加超时机制。
            try: 
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_connect_ftp_fail(host, username, password, timeout)
        
    def should_connect_ftp_success(self, host, username='', password='', timeout='20'):
        """
        功能描述：连接并登录FTP服务器。登录成功则表示关键字执行成功
        
        参数： 
            host: FTP服务器地址
            username: 连接服务器的用户名,空表示匿名登录,一般服务器对匿名登录的用户有权限限制
            password: 连接服务器的密码
            timeout: 连接超时时长，单位为秒
            
        返回：无,关键字执行失败则抛出错误
        
        Example:
        | Should Connect Ftp Success | 172.24.11.10 | 
        | Should Connect Ftp Success | 172.24.11.10 | ftptest | ftptest |
        """
        #modified by jias 20130722移到外面，让本端也能检查输入，以异常显示
        try:
            timeout = int(timeout)
        except ValueError,e:
            raise RuntimeError(u"timeout设置错误，请输入整数：%s" % e) 
        
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # change by jxy ,2013/4/2,增加超时机制。
            try:
                cls._client.set_timeout(REMOTE_TIMEOUT + timeout)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_connect_ftp_success(host, username, password, timeout)
        os.chdir(self.clientpath)  # GCW 2013-02-21 初始化客户端的工作目录为工程目录
        
    def should_disconnect_ftp_success(self):
        """
        功能描述：退出FTP服务器
        
        参数：无
        
        返回值：无，退出异常时则抛出错误
        
        Example:
        | Should Disconnect Ftp Success |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.should_disconnect_ftp_success()
        
        
    def should_upload_ftp_file_success(self, filepath):
        """
        功能描述：FTP上传文件成功
        
        参数：
            filepath：上传的文件的全路径
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | Should Upload Ftp File Success | d:\\\测试1.txt |
        
        注意：如果文件不存在，或者不是一个文件（比如是文件夹），均会抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_upload_ftp_file_success(filepath)
        
        
    def should_upload_ftp_files_success(self, f_list):
        """
        功能描述：FTP上传文件列表成功
        
        参数：
            f_list：由本地文件全路径组成的列表。eg:["e:\\test.txt","e:\\test1.txt"]
            
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | Create List | d:\\\中文1.txt | d:\\\中文2.txt |
        | Should Upload Ftp Files Success | ${files} |
        
        注意：如果文件不存在，或者不是一个文件（比如是文件夹），均会抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_upload_ftp_files_success(f_list)
        
        
    def should_upload_ftp_file_fail(self, filepath):
        """
        功能描述：FTP上传文件失败。文件不存在、是文件夹、上传失败，均符合预期，表示关键字执行成功。
                  当且仅当上传成功时，表示关键字执行失败。
        
        参数：
            filepath：上传的文件的全路径
        
        返回值：无，关键字失败则抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_upload_ftp_file_fail(filepath)
        
        
    def should_download_ftp_file_success(self, filename):
        """
        功能描述：FTP下载文件成功。
        
        参数：
            filename: 需要下载的文件的文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | Should Download Ftp File Success | 测试1.txt |
        
        注意：如果服务器当前工作目录下，无此文件，则会抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_download_ftp_file_success(filename)
        
        
    def should_download_ftp_files_success(self, f_list):
        """
        功能描述：FTP下载文件列表成功。
        
        参数：
            f_list: 有由需要下载的文件的文件名组成的列表
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | Create List | 中文1.txt | 中文2.txt |
        | Should Download Ftp Files Success | ${files}  |
        
        注意：如果服务器当前工作目录下，无此文件，则会抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_download_ftp_files_success(f_list)
        
        
    def should_download_ftp_file_fail(self, filename):
        """
        功能描述：FTP下载文件失败。无此文件、下载失败均表示关键字执行成功，符合预期。
                  当且仅当下载成功时表示关键字执行失败。
        
        参数：
            filename：需要下载的文件的文件名
            
        返回值：无，关键字失败则抛出错误
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            # 增加超时机制,change by jxy ,2013/4/26。
            try:
                cls._client.set_timeout(MAX_TRA_FILE_TIME)
                auto_do_remote(cls)
            except ValueError,e:
                raise RuntimeError(u"设定的超时时间格式错误，ErrorMessage：%s" % e) 
            finally:
                cls._client.set_timeout(REMOTE_TIMEOUT)
        else:
            cls.should_download_ftp_file_fail(filename)
        
        
    def change_ftp_model_to_pasv(self):
        """
        功能描述：修改FTP客户端的工作模式为被动模式（PASV）。
        
        参数：无
        
        返回值：无
        
        注意：必须先登录服务器后，才允许执行此关键字
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.change_ftp_model_to_pasv()
        
        
    def change_ftp_model_to_port(self):
        """
        功能描述：修改FTP客户端的工作模式为主动模式（PORT）。
        
        参数：无
        
        返回值：无
        
        注意：必须先登录服务器后，才允许执行此关键字
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.change_ftp_model_to_port()
        
    def files_is_in_ftp_site(self, f_list):
        """
        功能描述：判断FTP服务器是否存在列表f_list。只要有一个元素不存在，则关键字失败。
        
        参数：
            f_list：列表，元素为文件名(或目录名)
            
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | Create List | 测试1.txt | 测试2.txt |
        | Files Is In Ftp Site | ${files} |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.files_is_in_ftp_site(f_list)
        
        
    def file_is_in_ftp_site(self, filename):
        """
        功能描述：判断FTP服务器是否存在filename文件。不存在则关键字失败。
        
        参数：
            filename: 文件名(或目录名)
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | File Is In Ftp Site | 测试1.txt |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.file_is_in_ftp_site(filename)
        
        
    def files_is_not_in_ftp_site(self, f_list):
        """
        功能描述：判断FTP服务器是否存在列表f_list文件。只要有一个元素存在，则关键字失败。
        
        参数：
            f_list：列表，元素为文件名(或目录名)
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | Create List | 测试1.txt | 测试2.txt |
        | Files Is Not In Ftp Site | ${files} |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.files_is_not_in_ftp_site(f_list)
        
        
    def file_is_not_in_ftp_site(self, filename):
        """
        功能描述：判断FTP服务器是否存在filename文件。存在则关键字失败。
        
        参数：
            filename：文件名(或目录名)
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | File Is Not In Ftp Site | 测试1.txt |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.file_is_not_in_ftp_site(filename)
        
        
    def list_in_ftp_site(self):
        """
        功能描述：列出远端服务器当前目录下的所有文件详细信息
        
        参数：无
        
        返回值：当前目录下的所有文件详细信息列表,如下表
                726855680 DEEP_GhostXP ftptest  ftp E7.5产测工具
        
        Example:
        | List In Ftp Site |
        """
        #add by nzm 2014-01-20 增加远端服务器当前目录下的所有文件列表返回值
        list_file = []
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            list_file = auto_do_remote(cls)
        else:
            list_file = cls.list_in_ftp_site()
        return list_file
        
    def del_files_in_ftp_site(self, f_list):
        """
        功能描述：删除FTP服务器上的文件列表.一个一个地删除，只要有一个删除失败，则抛出错误.
        
        参数：
            f_list：文件列表
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | Create List | 测试1.txt | 测试2.txt |
        | Del Files In Ftp Site | ${files} |
        
        注意：如果没有相应的文件，则等同于删除成功。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.del_files_in_ftp_site(f_list)
        
        
    def del_file_in_ftp_site(self, filename):
        """
        功能描述：删除服务器上的单个文件
        
        参数：
            filename：文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | Del File In Ftp Site | 测试1.txt |
        
        注意：如果没有相应的文件，则等同于删除成功。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.del_file_in_ftp_site(filename)
        
        
    def makedir_in_ftp_site(self, dirname):
        """
        功能描述：在服务器上的新建文件夹。
        
        参数：
            dirname：目录名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | Makedir In Ftp Site | 测试目录 |
        
        注意：如果服务器上有同名的文件夹存在，则服务器会返回550 exists，
        
              这种情况下关键字认为新建目录也是成功的。
              
              不支持一次新建多个嵌套文件夹，如：test1\test2\test3\
        
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.makedir_in_ftp_site(dirname)
        
        
    def removedir_in_ftp_site(self, dirname):
        """
        功能描述：删除服务器上的某个文件夹。
        
        参数：
            dirname：目录名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | Removedir In Ftp Site | 测试目录 |
        
        注意：如果服务器上没有此文件夹，则关键字认为是成功的
        
              如果对非空文件夹执行删除操作，则服务器会返回550 Operation not permitted错误，
        
              这种情况下，关键字认为是失败的。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.removedir_in_ftp_site(dirname)
        
        
    def changeworkdir_in_ftp_site(self,dirname):
        """
        功能描述：修改远端服务器的工作目录
        
        参数：
            dirname：目录名
        
        返回值：无，如果进入文件夹失败，则抛出错误。
        
        Example:
        | Changeworkdir In Ftp Site | 测试目录 |
        
        注意：如果无此文件夹，执行此关键字时会报550 Operation not permitted错误，则此关键字执行是失败的。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.changeworkdir_in_ftp_site(dirname)
        
        
    def changeworkdir_in_ftp_client(self, path):
        """
        功能描述：修改客户端本地的工作目录
        
        参数：
            path: 表示路径名，须以完整路径名并以\\\结尾表示是文件夹
            
        返回值：无，如果进入文件夹失败，则抛出错误。
        
        Example:
        | Changeworkdir In Ftp Client | d:\\\ |
        | Changeworkdir In Ftp Client | d:\\\kest\\\ |
        | Changeworkdir In Ftp Client | d:\\\ |
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.changeworkdir_in_ftp_client(path)
        
        
    def makedir_in_ftp_client(self, dirname):
        """
        功能描述：新建客户端本地的文件夹
        
        参数：
            dirname：表示新建文件夹名
        
        返回值：无，如果新建文件夹失败，则抛出错误。
        
        Example:
        | Makedir In Ftp Client | test |
        
        注意：不支持一次新建多个嵌套文件夹，如：test1\test2\test3\
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.makedir_in_ftp_client(dirname)
        
        
    def removedir_in_ftp_client(self, dirname):
        """
        功能描述：删除客户端本地的文件夹
        
        参数：
            dirname:表示要删除的文件夹名
        
        返回值：无，如果删除文件夹失败，则抛出错误。
        
        Example:
        | Removedir In Ftp Client | test |
        
        注意：如果文件夹不存在，则关键字认为是成功的；如果是文件，则关键字认为是失败的。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.removedir_in_ftp_client(dirname)
        
        
    def del_file_in_ftp_client(self, filename):
        """
        功能描述：删除客户端本地的文件
        
        参数：
            filename: 表示要删除的文件名
        
        返回值：无，如果删除文件失败，则抛出错误
        
        Example:
        | Del File In Ftp Client | test.txt |
        
        注意：如果文件不存在，则关键字认为是成功的；如果是文件夹，则关键字认为是失败的。
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.del_file_in_ftp_client(filename)
            
    def del_files_in_ftp_client(self, f_list):
        """
        功能描述：删除客户端本地的文件列表
        
        参数：
            f_list: 表示要删除的文件列表
        
        返回值：无，如果删除文件失败，则抛出错误
        
        Example:
        | @{files} | Create List | 测试1.txt | 测试2.txt |
        | Del Files In Ftp Client | ${files} |
        
        注意：如果文件不存在，则关键字认为是成功的；如果是文件夹，则关键字认为是失败的。
        
        """
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            auto_do_remote(cls)
        else:
            cls.del_files_in_ftp_client(f_list)
        
    def list_in_ftp_client(self):
        """
        功能描述：列出客户端本地目录下的文件
        
        参数：无
        
        返回值：客户端当前目录下的文件列表
        
        Example:
        | List In Ftp Client |
        
        """
        #add by nzm 2014-01-20 增加客户端当前目录下的文件列表返回值
        list_file = []
        cls = self._current_remotelocal()        
        if (isinstance(cls, Remote)):
            list_file = auto_do_remote(cls)
        else:
            list_file = cls.list_in_ftp_client()
        return list_file
def start_library(host = "172.0.0.1",port = REMOTE_PORT, library_name = ""):
    try:
        log.start_remote_process_log(library_name)
    except ImportError, e:
        raise RuntimeError(u"创建log模块失败，失败信息：%" % e) 
    try:
        RobotRemoteServer(FtpClient(), host, port)
        return None
    except Exception, e:
        log_data = "start %s library fail!\n message:%s" % (library_name, e)
        log.user_err(log_data)
        raise RuntimeError(log_data)

if __name__ == '__main__':
    t = FtpClient()
    print "test"