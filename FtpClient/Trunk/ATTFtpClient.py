# -*- coding: utf-8 -*- 

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTFTPClient
#  function: 模拟FTPClent，提供FTPClient支持的基本功能
#  Author: ATT development group
#  version: V1.0
#  date: 2013.01.04
#  change log:
#  guochenwei     20130104     created
#  lana           20130116     optimize log info
#  guochunwei     20130123     增加客户端的操作关键字;修改*files*关键字为调用*file*关键字实现
# ***************************************************************************

import sys
import os
import socket
import time
import ftplib
import chardet
import cStringIO
import codecs
import attlog as log

CONST_BUFFER_SIZE = 8192

ATTFTPCLENT_SUC  = 0
ATTFTPCLENT_FAIL = -1

#reload(sys)
#sys.setdefaultencoding('utf-8')


class ATTFtpClient():

    def __init__(self, port):
        """
        initial
        """
        self.ftp = None
        self.ftp_server_encode = 'GBK'
        self.port = int(port)
        self.login = False
        
            
    def clear(self):
        """
        清空连接和标志
        """
        try:
            if self.ftp:
                self.ftp.quit() #在server关闭后，请求断开，会报异常            
        except Exception:
            pass
        finally:
            self.ftp = None
            self.login = False
            self.ftp_server_encode = 'GBK'
            
        
    def _connect_ftp(self, host, port=21, username='', password='', timeout=20):
        """
        功能描述：连接并登录FTP服务器
        
        参数：
            host: FTP服务器地址
            port: FTP服务器监听端口，默认为21
            username: 连接服务器的用户名,空表示匿名登录,一般服务器对匿名登录的用户有权限限制
            password: 连接服务器的密码
            timeout: 连接超时时长，单位为秒
        
        返回：
            成功返回：(ATTFTPCLENT_SUC,成功信息)
            失败返回：(ATTFTPCLENT_FAIL,失败信息)
        """        
        #add by jias 20130808
        if self.login :
            info = u"已经连接并登录FTP服务器"
            return ATTFTPCLENT_SUC, info
        
        try:
            
            # 创建对象，并连接服务器
            self.ftp = ftplib.FTP()
            ret_info = self.ftp.connect(host, int(port), int(timeout))
            log.debug_info(u"连接FTP服务器成功.详细信息为：%s" % ret_info)
            
        except Exception, e:
            ret_info = u"连接FTP服务器发生异常：%s" % e
            log.debug_err(ret_info)
            #add by jias 20130808 恢复conn前状态
            if self.ftp:
                self.ftp.close()
                self.ftp = None
            return ATTFTPCLENT_FAIL, ret_info
        
        try:
            ret_info = self.ftp.login(username, password)
            self.login = True
            return ATTFTPCLENT_SUC, ret_info
        except Exception, e:
            ret_info = u"登陆FTP服务器发生异常：%s" % e
            log.debug_err(ret_info)
            #add by jias 20130808 恢复conn前状态
            if self.ftp:
                self.ftp.close()
                self.ftp = None            
            return ATTFTPCLENT_FAIL, ret_info        
        
    def should_connect_ftp_fail(self, host, username='', password='', timeout=20):
        """
        功能描述：连接并登录FTP服务器。登录失败则表示关键字执行成功
        
        参数： 
            host: FTP服务器地址
            port: FTP服务器监听端口，默认为21
            username: 连接服务器的用户名,空表示匿名登录,一般服务器对匿名登录的用户有权限限制
            password: 连接服务器的密码
            timeout: 连接超时时长，单位为秒
            
        返回：无,关键字执行失败则抛出错误
        
        Example:
        | should_connect_ftp_fail | 172.24.11.22 |
        | should_connect_ftp_fail | 172.24.11.10 | 22 |
        | should_connect_ftp_fail | 172.24.11.10 | 21 | abc | abc |

        """
        ret, ret_info = self._connect_ftp(host, self.port, username, password, timeout)
        if ret == ATTFTPCLENT_SUC:
            raise RuntimeError(u"关键字执行失败。登录FTP服务器成功,详细信息为：%s" % ret_info)
        elif ret == ATTFTPCLENT_FAIL:
            log.user_info(u"关键字执行成功。登录FTP服务器失败,详细信息为：%s" % ret_info)
        
        
    def should_connect_ftp_success(self, host, username='', password='', timeout='20'):
        """
        功能描述：连接并登录FTP服务器。登录成功则表示关键字执行成功
        
        参数： 
            host: FTP服务器地址
            port: FTP服务器监听端口，默认为21
            username: 连接服务器的用户名,空表示匿名登录,一般服务器对匿名登录的用户有权限限制
            password: 连接服务器的密码
            timeout: 连接超时时长，单位为秒
            
        返回：无,关键字执行失败则抛出错误
        
        Example:
        | should_connect_ftp_success | 172.24.11.10 | 21 |
        | should_connect_ftp_success | 172.24.11.10 | 21 | ftptest | ftptest |

        """
        ret, ret_info = self._connect_ftp(host, self.port, username, password, timeout)
        if ret == ATTFTPCLENT_SUC:
            log.user_info(u"登录FTP服务器成功.详细信息为：%s " % ret_info)
        elif ret == ATTFTPCLENT_FAIL:
            raise RuntimeError(ret_info)
        
    def should_disconnect_ftp_success(self):
        """
        功能描述：退出FTP服务器
        
        参数：无
        
        返回值：无，退出异常时则抛出错误
        
        Example:
        | should_disconnect_ftp_success |

        """
        #add by jias 20130808
        if not self.login :
            log.user_info(u"未检测到有Ftp连接不用关闭")
            return 
        
        try:
            ret_info = self.ftp.quit()
            self.login = False
            self.ftp = None
            log.user_info(u"退出FTP服务器成功.详细信息为：%s " % ret_info)
        except Exception, e:
            #add by jias #add clear
            if self.ftp:
                self.ftp.close()
            self.login = False
            
            # GCW20130217 服务器远端,客户端本地,先停止了服务器再退出客户端的操作时
            # 报"AttributeError: 'exceptions.EOFError' object has no attribute 'errno'"错误的处理
            tmp = dir(e)
            if 'errno' in tmp:
                if e.errno == 10054:
                    log.user_info(u"退出FTP服务器成功.返回信息：The connection has been reset.")
                else:
                    raise RuntimeError(u"退出FTP服务器异常.详细信息为：%s" % e)
            else:
                log.user_info(u"退出FTP服务器成功.返回信息为空.")

    def _fstr(self, inputstr, encoding='utf-8'):
        """Force convert unicode to encoding"""
        
        s = cStringIO.StringIO()
        w = codecs.getwriter(encoding)(s)
        w.write(inputstr)
        return s.getvalue()

    def _ftpupload(self, filepath):
        """
        功能描述：上传文件
        
        参数：
            filepath: 需要上传的文件的全路径
            
        返回值：
            成功返回：(ATTFTPCLENT_SUC,成功信息)
            失败返回：(ATTFTPCLENT_FAIL,失败信息)
        """        
        #add by jias 20130808
        if not self.login :
            info = u"请先登录FTP服务器"
            return ATTFTPCLENT_FAIL, info
        
        try:
            with  open(filepath, "rb") as f:
                filename = os.path.split(filepath)[-1]
                # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
                tmp_filename = filename
                if not isinstance(filename, unicode):
                    filename = filename.decode('utf-8')
                else:
                    filename = filename.encode('utf-8')
                    
                filename = 'STOR %s' % filename
                ret_info = self.ftp.storbinary(filename, f, CONST_BUFFER_SIZE)
                return ATTFTPCLENT_SUC, ret_info
        except ftplib.error_perm, e:
            return ATTFTPCLENT_FAIL, e
        

    def should_upload_ftp_file_success(self, filepath):
        """
        功能描述：FTP上传文件成功
        
        参数：
            filepath：上传的文件的全路径
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | should_upload_ftp_file_success | d:\\测试1.txt |
        
        注意：如果文件不存在，或者不是一个文件（比如是文件夹），均会抛出错误
        """
        
        # 判断filepath是否在本地存在
        if not os.path.exists(filepath):
            raise RuntimeError(u"FTP上传文件: %s 失败，文件不存在" % filepath)
         
        # 判断filepath是否是一个文件的全路径 
        if not os.path.isfile(filepath):
            raise RuntimeError(u"FTP上传文件: %s 失败，%s 不是一个文件" % (filepath, filepath))
        
        ret, ret_info = self._ftpupload(filepath)
        if ret == ATTFTPCLENT_SUC:
            log.user_info(u"FTP上传文件 %s 成功.详细信息为:%s" % (filepath, ret_info))
        else:
            raise RuntimeError(u"FTP上传文件：%s 失败.详细信息为：%s" % (filepath, ret_info))

    def should_upload_ftp_files_success(self, f_list):
        """
        功能描述：FTP上传文件列表成功
        
        参数：
            f_list：由本地文件全路径组成的列表。eg:["e:\\test.txt","e:\\test1.txt"]
            
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | create list | d:\\中文1.txt | d:\\中文2.txt |
        | should_upload_ftp_files_success | ${files} |
        
        注意：如果文件不存在，或者不是一个文件（比如是文件夹），均会抛出错误
        """
        
        # Change by jxy ,2013/3/20,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for filepath in f_list:
            if not os.path.exists(filepath):
                raise RuntimeError(u"FTP上传文件: %s 失败，文件不存在" % filepath)
            if not os.path.isfile(filepath):
                raise RuntimeError(u"FTP上传文件: %s 失败，%s 不是一个文件" % (filepath, filepath))
            
            ret, ret_info = self._ftpupload(filepath)
            if ret == ATTFTPCLENT_SUC:
                log.user_info(u"FTP上传文件 %s 成功.详细信息为:%s" % (filepath, ret_info))
            else:
                raise RuntimeError(u"FTP上传文件：%s 失败.详细信息为：%s" % (filepath, ret_info))

    def should_upload_ftp_file_fail(self, filepath):
        """
        功能描述：FTP上传文件失败。文件不存在、是文件夹、上传失败，均符合预期，表示关键字执行成功。
                  当且仅当上传成功时，表示关键字执行失败。
        
        参数：
            filepath：上传的文件的全路径
        
        返回值：无，关键字失败则抛出错误
        """
        
        if not os.path.exists(filepath):
            log.user_info(u"关键字执行成功。文件: %s 不存在" % filepath)
            return
            
        if not os.path.isfile(filepath):
            log.user_info(u"关键字执行成功。%s 是一个文件夹" % filepath)
            return
            
        ret, ret_info = self._ftpupload(filepath)
        if ret == ATTFTPCLENT_SUC:
            raise RuntimeError(u"关键字执行失败。FTP上传文件：%s 成功.详细信息为：%s" % (filepath, ret_info))
        else:
            log.user_info(u"关键字执行成功。FTP上传文件：%s 失败.详细信息为：%s" % (filepath, ret_info))

    def _ftpdownload(self, filename):
        """
        功能描述：下载文件
        
        参数：
            filename: 需要下载的文件的文件名
            
        返回值：
            成功返回：(ATTFTPCLENT_SUC,成功信息)
            失败返回：(ATTFTPCLENT_FAIL,失败信息)
        """
        # 先查找一下服务器上是否有此文件
        try:
            ret, ret_info = self._find(filename)
        except Exception, e:
            raise RuntimeError(u"查找服务器上的文件发生异常，详细信息为：%s" % e)
        
        if ret == ATTFTPCLENT_SUC:
            #modified by jias 如果open file fail
            try:
                if os.path.exists(filename) and (not os.path.isfile(filename)):
                    ret_info = u"保存下载数据的文件不是文件类型"
                    return ATTFTPCLENT_FAIL, ret_info
                else:
                    f_o = open(filename, "wb")
            except IOError, e:
                ret_info = u"打开保存下载数据的目标文件失败"
                return ATTFTPCLENT_FAIL, ret_info
        
            try:
                f = f_o.write
                
                # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
                if not isinstance(filename, unicode):
                    filename = filename.decode('utf-8')
                else:
                    filename = filename.encode('utf-8')
                
                ret_info = self.ftp.retrbinary("RETR %s" % filename, f, CONST_BUFFER_SIZE)
                return ATTFTPCLENT_SUC, ret_info
            
            except (ftplib.error_perm), e:
                return ATTFTPCLENT_FAIL, e
            finally:
                f_o.close()
        else:
            return ATTFTPCLENT_FAIL, ret_info

    def should_download_ftp_file_success(self, filename):
        """
        功能描述：FTP下载文件成功。
        
        参数：
            filename: 需要下载的文件的文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | should_download_ftp_file_success | 测试1.txt |
        
        注意：如果服务器当前工作目录下，无此文件，则会抛出错误
        """
        
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
        
        tmp_filename = filename
        try:
            ret, ret_info = self._ftpdownload(filename)
        except Exception, e:
            raise RuntimeError(u"FTP下载文件 %s 异常.详细信息为：%s" % (tmp_filename, e))
        if ret == ATTFTPCLENT_SUC:
            log.user_info(u"FTP下载文件 %s 成功.详细信息为：%s" % (tmp_filename, ret_info))
        else:
            raise RuntimeError(u"FTP下载文件 %s 失败.详细信息为：%s" % (tmp_filename, ret_info))

    def should_download_ftp_files_success(self, f_list):
        """
        功能描述：FTP下载文件列表成功。
        
        参数：
            f_list: 有由需要下载的文件的文件名组成的列表
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | create list | 中文1.txt | 中文2.txt |
        | should_download_ftp_files_success | ${files}  |
        
        注意：如果服务器当前工作目录下，无此文件，则会抛出错误
        """
        
        # Change by jxy ,2013/3/20,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for filename in f_list:
            tmp_filename = filename
            try:
                ret, ret_info = self._ftpdownload(filename)
            except Exception, e:
                raise RuntimeError(u"FTP下载文件 %s 异常.详细信息为：%s" % (tmp_filename, e))
            
            if ret == ATTFTPCLENT_SUC:
                log.user_info(u"FTP下载文件 %s 成功.详细信息为：%s" % (tmp_filename, ret_info))
            else:
                raise RuntimeError(u"FTP下载文件 %s 失败.详细信息为：%s" % (tmp_filename, ret_info))

    def should_download_ftp_file_fail(self, filename):
        """
        功能描述：FTP下载文件失败。无此文件、下载失败均表示关键字执行成功，符合预期。
                  当且仅当下载成功时表示关键字执行失败。
        
        参数：
            filename：需要下载的文件的文件名
            
        返回值：无，关键字失败则抛出错误
        """
        
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
        
        tmp_filename = filename
        try:
            ret, ret_info = self._ftpdownload(filename)
        except Exception, e:
            raise RuntimeError(u"关键字执行失败.FTP下载文件 %s 异常.详细信息为：%s" % (tmp_filename, e))
        
        if ret == ATTFTPCLENT_SUC:
            raise RuntimeError(u"关键字执行失败.FTP下载文件 %s 成功.详细信息为：%s" % (tmp_filename, ret_info))
        else:
            log.user_info(u"关键字执行成功.FTP下载文件 %s 失败.详细信息为：%s" % (tmp_filename, ret_info))

    def change_ftp_model_to_pasv(self):
        """
        功能描述：修改FTP客户端的工作模式为被动模式（PASV）。
        
        参数：无
        
        返回值：无
        
        注意：必须先登录服务器后，才允许执行此关键字
        """
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        try:
            self.ftp.set_pasv(1)
        except Exception, e:
            raise RuntimeError(u"修改客户端为被动模式时异常.详细信息为：%s" % e)
        
        log.user_info(u"修改客户端为被动模式成功.")

    def change_ftp_model_to_port(self):
        """
        功能描述：修改FTP客户端的工作模式为主动模式（PORT）。
        
        参数：无
        
        返回值：无
        
        注意：必须先登录服务器后，才允许执行此关键字
        """        
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        try:
            self.ftp.set_pasv(0)
        except Exception, e:
            raise RuntimeError(u"修改客户端为主动模式时异常.详细信息为：%s" % e)
        
        log.user_info(u"修改客户端为主动模式成功.")

    def _find(self, filename):        
        
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        ftp_f_list = self.ftp.nlst()
        for tmp_filename in ftp_f_list:
            
            # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
            # GCW 20130312 unicode 经以下处理后变成了str,解决k歌.doc文件特殊编码不能找到的问题
            tmp_filename_2 = filename
            if not isinstance(tmp_filename_2, unicode):
                tmp_filename_2 = tmp_filename_2.decode('utf-8')
            else:
                tmp_filename_2 = tmp_filename_2.encode('utf-8')
            
            if tmp_filename == tmp_filename_2:
                return ATTFTPCLENT_SUC, u"文件: %s 在服务器上找到." % filename
            else:
                continue
        return ATTFTPCLENT_FAIL, u"文件: %s 在服务器上找不到." % filename

    def files_is_in_ftp_site(self, f_list):
        """
        功能描述：远端FTP服务器有列表f_list文件。只要有一个文件查无，则关键字失败。
        
        参数：
            f_list：文件名列表
            
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | create list | 测试1.txt | 测试2.txt |
        | files_is_in_ftp_site | ${files} |
        """
        
        # Change by jxy ,2013/3/20,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for filename in f_list:
            try:
                self.file_is_in_ftp_site(filename)
            except Exception, e:
                raise RuntimeError(e.message)
        
    def file_is_in_ftp_site(self, filename):
        """
        功能描述：远端FTP服务器有filename文件。
        
        参数：
            filename: 文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | file_is_in_ftp_site | 测试1.txt |
        """
        
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
        
        try:
            ret, ret_info = self._find(filename)
            if ret == ATTFTPCLENT_SUC:
                log.user_info(ret_info)
            else:
                raise RuntimeError(ret_info)
        except Exception, e:
            raise RuntimeError(u"查找失败，异常信息为：%s " % e)

    def files_is_not_in_ftp_site(self, f_list):
        """
        功能描述：远端FTP服务器没有列表f_list文件。只要有一个文件查到有，则关键字失败。
        
        参数：
            f_list：文件名列表
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | create list | 测试1.txt | 测试2.txt |
        | files_is_not_in_ftp_site | ${files} |
        """
        
        # Change by jxy ,2013/3/20,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for filename in f_list:
            try:
                self.file_is_not_in_ftp_site(filename)
            except Exception, e:
                raise RuntimeError(e.message)

    def file_is_not_in_ftp_site(self, filename):
        """
        功能描述：远端FTP服务器没有filename文件。
        
        参数：
            filename：文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | file_is_not_in_ftp_site | 测试1.txt |
        """
        
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
        
        try:
            ret, ret_info = self._find(filename)
            if ret == ATTFTPCLENT_SUC:
                raise RuntimeError(u"关键字执行失败。%s" % ret_info)
            else:
                log.user_info(u"关键字执行成功。%s" % ret_info)
        except Exception, e:
            raise RuntimeError(u"查找失败，异常信息为：%s " % e)

    def list_in_ftp_site(self):
        """
        功能描述：列出远端服务器当前目录下的所有文件详细信息
        
        参数：无
        
        返回值：当前目录下的所有文件详细信息列表,如下表
                726855680 DEEP_GhostXP ftptest  ftp E7.5产测工具
        
        Example:
        | list_in_ftp_site |
        
        """        
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        try:
            #self.ftp.dir()  如果用此句，在RF中会报编码错误。
            ret = self.ftp.nlst()
            log.user_info(u"服务器上的文件信息如下")
            tmp_item = []
            for item in ret:
                # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
                #add by nzm 2014-01-20 增加ftp服务器文件列表返回值
                #tmp_item = item
                if not isinstance(item, unicode):
                    item = item.decode('utf-8')
                else:
                    item = item.encode('utf-8')
                log.user_info(item)
                tmp_item.append(item)
            return tmp_item
                
        except Exception, e:
            raise RuntimeError(u"获取服务器上的文件列表信息失败，异常信息为：%s " % e)

    def del_files_in_ftp_site(self, f_list):
        """
        功能描述：删除FTP服务器上的文件列表.一个一个地删除，只要有一个删除失败，则抛出错误.
        
        参数：
            f_list：文件列表
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | @{files} | create list | 测试1.txt | 测试2.txt |
        | del_files_in_ftp_site | ${files} |
        
        注意：如果没有相应的文件，则等同于删除成功。
        
        """
        # Change by jxy ,2013/3/20,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for del_file in f_list:
            try:
                self.del_file_in_ftp_site(del_file)
            except Exception, e:
                #modified by jias 2013-7-10
                err_info = ""
                try:
                    err_info = e.message
                except Exception, ex:
                    err_info = u"删除文件列表失败."
                finally:
                    raise RuntimeError(err_info)

    def del_file_in_ftp_site(self, filename):
        """
        功能描述：删除服务器上的单个文件
        
        参数：
            filename：文件名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | del_file_in_ftp_site | 测试1.txt |
        
        注意：如果没有相应的文件，则等同于删除成功。
        
        """
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
            
        del_file = filename
        try:
            ret, ret_info = self._find(del_file)
        except Exception, e:
            raise RuntimeError(u"查找失败，异常信息为：%s " % e)
        if ret == ATTFTPCLENT_SUC:
            log.user_info(u"找到文件或文件夹 %s" % del_file)
            # 查到服务器上有此文件，则删除
            try:
                # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
                tmp_del_file = del_file
                if not isinstance(del_file, unicode):
                    del_file = del_file.decode('utf-8')
                else:
                    del_file = del_file.encode('utf-8')
                    
                ret_info = self.ftp.delete(del_file)
                log.user_info(u"删除FTP服务器上的文件 %s 成功.详细信息为：%s" % (tmp_del_file, ret_info))
            except Exception, e:
                # GCW20130217解决删除查到有文件夹同名,用户误用文件夹名去删除的问题,同时兼容测试网服务器
                # e = e.decode(self.ftp_server_encode).encode('utf-8')
                # raise RuntimeError(u"删除FTP服务器上的文件：%s 异常.错误信息：%s" % (del_file, e))
                if '550' in e.message and 'Permission denied' in e.message:
                    raise RuntimeError(u"待删除的 %s 不是一个文件,返回信息:%s " % (tmp_del_file, e))
                else:
                    e.message = e.message.decode(self.ftp_server_encode)
                    raise RuntimeError(u"在FTP服务器上删除文件：%s 异常.返回错误信息: %s " % (tmp_del_file, e.message))

        else:
            # 查到服务器上没有此文件，则不用删除
            log.user_warn(u"FTP服务器上没有要删除的文件: %s ." % del_file)

    def makedir_in_ftp_site(self, dirname):
        """
        功能描述：在服务器上的新建文件夹。
        
        参数：
            dirname：目录名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | makedir_in_ftp_site | 测试目录 |
        
        注意：如果服务器上有同名的文件夹存在，则服务器会返回550 exists，
        
              这种情况下关键字认为新建目录也是成功的。
              
              不支持一次新建多个嵌套文件夹，如：test1\test2\test3\
        
        """        
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        try:
            # GCW 20130306 更换ftpserver代码后无须关心编码,替换
            # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
            tmp_dirname = dirname
            if not isinstance(dirname, unicode):
                dirname = dirname.decode('utf-8')
            else:
                dirname = dirname.encode('utf-8')
            
            ret_info = self.ftp.mkd(dirname)
            # GCW END
            
            log.user_info(u"在FTP服务器上新建文件夹 %s 成功" % tmp_dirname)
        except Exception, e:
            # ret = "550 File exists."    #兼容172.24.11.10
            # ret2 = "550 %s: File exists" % dirname    #兼容python版本的FTP服务器
            # 为了兼容不同的服务器回复的不一致的情况，采用以下方法
            if '550' in e.message and 'exists' in e.message:
                log.user_warn(u"在FTP服务器上已经存在文件夹：%s ,无须新建!" % tmp_dirname)
            else:
                e.message = e.message.decode(self.ftp_server_encode)
                raise RuntimeError(u"在FTP服务器上新建文件夹：%s 失败。详细信息为：%s" % (tmp_dirname, e.message))

    def removedir_in_ftp_site(self, dirname):
        """
        功能描述：删除服务器上的某个文件夹。
        
        参数：
            dirname：目录名
        
        返回值：无，关键字失败则抛出错误
        
        Example:
        | removedir_in_ftp_site | 测试目录 |
        
        注意：如果服务器上没有此文件夹，则关键字认为是成功的
        
              如果对非空文件夹执行删除操作，则服务器会返回550 Operation not permitted错误，
        
              这种情况下，关键字认为是失败的。

        """
        del_dir = dirname
        try:
            ret, ret_info = self._find(del_dir)
        except Exception, e:
            raise RuntimeError(u"查找失败，异常信息为：%s " % e)
        if ret == ATTFTPCLENT_SUC:
            try:
                # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
                tmp_dirname = dirname
                if not isinstance(dirname, unicode):
                    dirname = dirname.decode('utf-8')
                else:
                    dirname = dirname.encode('utf-8')
                    
                ret_info = self.ftp.rmd(dirname)
                log.user_info(u"在FTP服务器上删除文件夹 %s 成功." % tmp_dirname)
            except Exception, e:
                if '550' in e.message and 'Operation not permitted' in e.message:
                    e.message = e.message.decode(self.ftp_server_encode)
                    raise RuntimeError(u"在FTP服务器上删除文件夹：%s 失败,返回提示信息: %s " % (tmp_dirname, e.message))
                else:
                    e.message = e.message.decode(self.ftp_server_encode)
                    raise RuntimeError(u"在FTP服务器上删除文件夹：%s 异常.返回错误信息: %s " % (tmp_dirname, e.message))
        else:
            log.user_warn(u"在FTP服务器上没有要删除的文件夹: %s ." % dirname)
        
    def changeworkdir_in_ftp_site(self,dirname):
        """
        功能描述：修改远端服务器的工作目录
        
        参数：
            dirname：目录名
        
        返回值：无，如果进入文件夹失败，则抛出错误。
        
        Example:
        | changeworkdir_in_ftp_site | 测试目录 |
        
        注意：如果无此文件夹，执行此关键字时会报550 Operation not permitted错误，则此关键字执行是失败的。
        """        
        #add by jias 20130808
        if not self.login :
            raise RuntimeError(u"请先登录FTP服务器")
        
        try:
            # GCW 20130312 更新服务器代码出现远端无法解析K歌.doc的问题,统一处理
            tmp_dirname = dirname
            if not isinstance(dirname, unicode):
                dirname = dirname.decode('utf-8')
            else:
                dirname = dirname.encode('utf-8')
            ret_info = self.ftp.cwd(dirname)
            
            log.user_info(u"进入FTP服务器的文件夹: %s 成功" % tmp_dirname)
        except Exception, e:
            # GCW 20130302 用例中两次调用进入中文目录,第二次目录不存在的情况下报编码错误
            path = self.ftp.pwd()
            raise RuntimeError(u"进入FTP服务器的文件夹: %s 失败,当前路径为: %s.异常信息为：%s" % (tmp_dirname, path, e) )
    
    def changeworkdir_in_ftp_client(self, path):
        """
        功能描述：修改客户端本地的工作目录
        
        参数：
            path: 表示路径名，须以完整路径名并以\\\结尾表示是文件夹
            
        返回值：无，如果进入文件夹失败，则抛出错误。
        
        Example:
        | changeworkdir_in_ftp_client | d:\\\ |
        | changeworkdir_in_ftp_client | d:\\\test\\\ |
        | changeworkdir_in_ftp_client | d:\\\ |
        """
        
        try:
            if os.path.exists(path):
                os.chdir(path)
                log.user_info(u"修改客户端工作目录为：%s 成功." % path)
            else:
                raise RuntimeError(u"修改客户端工作目录为: %s 失败. 目录不存在" % path)
        except Exception, e:
            raise RuntimeError(u"修改客户端工作目录为: %s 失败." % path)

    def makedir_in_ftp_client(self, dirname):
        """
        功能描述：新建客户端本地的文件夹
        
        参数：
            dirname：表示新建文件夹名
        
        返回值：无，如果新建文件夹失败，则抛出错误。
        
        Example:
        | makedir_in_ftp_client | test |
        
        注意：不支持一次新建多个嵌套文件夹，如：test1\test2\test3\
        """
        if os.path.exists(dirname):
            log.user_warn(u"已存在同名文件夹：%s，无须新建." % dirname)
            return
        try:
            os.mkdir(dirname)
            log.user_info(u"新建本地文件夹：%s 成功." % dirname)
        except Exception, e:
            raise RuntimeError(u"新建本地文件夹：%s 失败." % dirname)

    def removedir_in_ftp_client(self, dirname):
        """
        功能描述：删除客户端本地的文件夹
        
        参数：
            dirname:表示要删除的文件夹名
        
        返回值：无，如果删除文件夹失败，则抛出错误。
        
        Example:
        | removedir_in_ftp_client | test |
        
        注意：如果文件夹不存在，则关键字认为是成功的；如果是文件，则关键字认为是失败的。
        
        """
        if not os.path.exists(dirname):
            log.user_warn(u"不存在文件夹: %s" % dirname)
            return
        
        if os.path.isfile(dirname):
            raise RuntimeError(u"%s 是文件，请勿使用此关键字删除." % dirname)
        try:
            os.rmdir(dirname)
            log.user_info(u"删除本地文件夹：%s 成功." % dirname)
        except Exception, e:
            raise RuntimeError(u"删除本地文件夹：%s 失败." % dirname)

    def del_file_in_ftp_client(self, filename):
        """
        功能描述：删除客户端本地的文件
        
        参数：
            filename: 表示要删除的文件名
        
        返回值：无，如果删除文件失败，则抛出错误
        
        Example:
        | del_file_in_ftp_client | test.txt |
        
        注意：如果文件不存在，则关键字认为是成功的；如果是文件夹，则关键字认为是失败的。
        
        """
        # Change by jxy ,3013/3/20,增加参数合法性判断  
        if type(filename) is str:
            pass
        elif type(filename) is unicode:
            pass
        else:
             raise RuntimeError(u"传入的参数不是单个文件名，请传入单个文件名!" )
        
        if not os.path.exists(filename):
            log.user_warn(u"不存在文件: %s" % filename)
            return
        if os.path.isdir(filename):
            raise RuntimeError(u"%s 是文件夹，请勿使用此关键字删除." % filename)
        try:
            os.remove(filename)
            log.user_info(u"删除本地文件：%s 成功." % filename)
        except Exception, e:
            raise RuntimeError(u"删除本地文件：%s 失败." % filename)
    
    def del_files_in_ftp_client(self, f_list):
        """
        功能描述：删除客户端本地的文件
        
        参数：
            f_list: 表示要删除的文件列表
        
        返回值：无，如果删除文件失败，则抛出错误
        
        Example:
        | @{files} | create list | 测试1.txt | 测试2.txt |
        | del_file_in_ftp_client | ${files} |
        
        注意：如果文件不存在，则关键字认为是成功的；如果是文件夹，则关键字认为是失败的。
        
        """
        # Change by jxy ,增加参数合法性判断
        if type(f_list) is not list:
             raise RuntimeError(u"传入的参数不是list类型，请传入list类型的值。" )
        
        for filename in f_list:
            try:
                self.del_file_in_ftp_client(filename)
            except Exception, e:
                raise RuntimeError(e.message)
        
    def list_in_ftp_client(self):
        """
        功能描述：列出客户端本地目录下的文件
        
        参数：无
        
        返回值：客户端当前目录下的文件列表
        
        Example:
        | list_in_ftp_client |
        
        """
        f_list = os.listdir(os.getcwd())
        log.user_info(u"当前客户端目录下的文件有：")
        tmp_item = []
        for item in f_list:
            # GCW 20130217 以下第一句或第二三句不能同时兼容172.24.11.10和自己搭建的服务器上有中文名文件夹的情况
            # 因为在XP下手动新建的中文目录名,是KOI8-R编码            
            encoding = chardet.detect(item).get("encoding")
            if encoding == 'ascii' or encoding == 'utf-8':
                encoding = chardet.detect(item).get("encoding","utf-8")
                item = item.decode(encoding)
            else:
                item = item.decode(self.ftp_server_encode)
            log.user_info(item)
            #add by nzm 2014-01-20 增加f客户端本地目录文件列表返回值
            tmp_item.append(item)
        return tmp_item
