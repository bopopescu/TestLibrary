# -*- coding: utf-8 -*-
#  Copyright 2008-2012 Nokia Siemens Networks Oyj
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

from __future__ import with_statement
from contextlib import contextmanager
import telnetlib
import time
import re
import inspect
import attlog as log

from robot.api import logger
from robot.version import get_version
from robot import utils


class ATTTelnet:
    
    def __init__(self, host):
        self.host = str(host)
        self._atttelnet_init_(timeout='3 seconds', newline='CRLF', prompt=None,
                 prompt_is_regexp=False, encoding='UTF-8', default_log_level='INFO')

    def _atttelnet_init_(self, timeout='3 seconds', newline='CRLF', prompt=None,
                 prompt_is_regexp=False, encoding='UTF-8', default_log_level='INFO'):
        """Telnet library can be imported with optional configuration parameters.

        Configuration parameters are used as default values when new
        connections are opened with `Open Connection` keyword. They can also be
        overridden after opening the connection using the `Set Timeout`,
        `Set Newline`, `Set Prompt`, `Set Encoding`, and `Set Default Log Level`
        keywords. See these keywords and `Configuration` section above for more
        information about these parameters and their possible values.

        Examples (use only one of these):

        | *Setting* | *Value* | *Value* | *Value* | *Value* | *Value* | *Comment* |
        | Library | Telnet |     |    |     |    | # default values                |
        | Library | Telnet | 0.5 |    |     |    | # set only timeout              |
        | Library | Telnet |     | LF |     |    | # set only newline              |
        | Library | Telnet | newline=LF | encoding=ISO-8859-1 | | | # set newline and encoding using named arguments |
        | Library | Telnet | 2.0 | LF |     |    | # set timeout and newline       |
        | Library | Telnet | 2.0 | CRLF | $ |    | # set also prompt               |
        | Library | Telnet | 2.0 | LF | (> |# ) | True | # set prompt as a regular expression |
        """
        self._timeout = timeout or 3.0
        self._newline = newline or 'CRLF'
        self._prompt = (prompt, bool(prompt_is_regexp))
        self._encoding = encoding
        self._default_log_level = default_log_level
        self._cache = utils.ConnectionCache()
        self._conn = None
        self._conn_kws = self._lib_kws = None

    def get_keyword_names(self):
        return self._get_library_keywords() + self._get_connection_keywords()

    def _get_library_keywords(self):
        if self._lib_kws is None:
            self._lib_kws = self._get_keywords(self, ['get_keyword_names'])
        return self._lib_kws

    def _get_keywords(self, source, excluded):
        return [name for name in dir(source)
                if self._is_keyword(name, source, excluded)]

    def _is_keyword(self, name, source, excluded):
        return (name not in excluded and
                not name.startswith('_') and
                name != 'get_keyword_names' and
                inspect.ismethod(getattr(source, name)))

    def _get_connection_keywords(self):
        if self._conn_kws is None:
            conn = self._get_connection()
            excluded = [name for name in dir(telnetlib.Telnet())
                        if name not in ['write', 'read', 'read_until']]
            self._conn_kws = self._get_keywords(conn, excluded)
        return self._conn_kws

    def __getattr__(self, name):
        if name not in self._get_connection_keywords():
            raise AttributeError(name)
        # If no connection is initialized, get attributes from a non-active
        # connection. This makes it possible for Robot to create keyword
        # handlers when it imports the library.
        return getattr(self._conn or self._get_connection(), name)

    def telnet_open_connection(self, port, timeout=None,
                        prompt=None, prompt_is_regexp=False,
                        encoding=None, default_log_level=None):
        """Opens a new Telnet connection to the given host and port.

        The `timeout`, `prompt`, `prompt_is_regexp`, `encoding`,
        and `default_log_level` arguments get default values when the library
        is [#Importing|imported]. Setting them here overrides those values for
        the opened connection. See `Configuration` section for more information.

        Possible already opened connections are cached and it is possible to
        switch back to them using `Switch Connection` keyword. It is possible
        to switch either using explicitly given `alias` or using index returned
        by this keyword. Indexing starts from 1 and is reset back to it by
        `Close All Connections` keyword.
        """
        timeout = timeout or self._timeout
        encoding = encoding or self._encoding
        default_log_level = default_log_level or self._default_log_level
        
        try:
            ''.encode(encoding)
        except Exception,e:
            raise Exception (u"unknown encoding %s" % encoding)
        if default_log_level.upper() not in ['TRACE', 'DEBUG', 'INFO', 'WARN']:
            raise Exception (r"unknown log level: %s"  % default_log_level)
    
        if not prompt:
            prompt, prompt_is_regexp = self._prompt
        log.user_info(u'Opening connection to %s:%s with prompt: %s'
                    % (self.host, port, prompt))
        try:
            self._conn = self._get_connection(self.host, port, timeout, 
                                          prompt, prompt_is_regexp,
                                          encoding, default_log_level)
        except Exception:
            raise Exception(r"open telnet connection fail")
        return self._cache.register(self._conn)

    def _get_connection(self, *args):
        """Can be overridden to use a custom connection."""
        return TelnetConnection(*args)

    def telnet_close_all_connections(self):
        """Closes all open connections and empties the connection cache.

        If multiple connections are opened, this keyword should be used in
        a test or suite teardown to make sure that all connections are closed.
        It is not an error is some of the connections have already been closed
        by `Close Connection`.

        After this keyword, new indexes returned by `Open Connection`
        keyword are reset to 1.
        """
        self._conn = self._cache.close_all()


class TelnetConnection(telnetlib.Telnet):

    def __init__(self, host=None, port=23, timeout=3.0,
                 prompt=None, prompt_is_regexp=False, encoding='UTF-8',
                 default_log_level='INFO'):
        telnetlib.Telnet.__init__(self, host, int(port) if port else 23)
        self._set_timeout(timeout)
        self._set_prompt(prompt, prompt_is_regexp)
        self._set_encoding(encoding)
        self._set_default_log_level(default_log_level)
        self.set_option_negotiation_callback(self._negotiate_echo_on)
        
        #add by jias 2013-11-11
        #用户是否设置过newline标示
        self._newline = ""
        self.newline_set_flg = False

    def telnet_set_timeout(self, timeout):
        """Sets the timeout used for waiting output in the current connection.

        Read operations that expect some output to appear (`Read Until`, `Read
        Until Regexp`, `Read Until Prompt`, `Login`) use this timeout and fail
        if the expected output does not appear before this timeout expires.

        The `timeout` must be given in `time string format`. The old timeout is
        returned and can be used to restore the timeout later.

        Example:
        | ${old} =       | `Set Timeout` | 2 minute 30 seconds |
        | `Do Something` |
        | `Set Timeout`  | ${old}  |

        See `Configuration` section for more information about global and
        connection specific configuration.
        """  
        self._verify_connection()
        old = self._timeout
        self._set_timeout(timeout)
        return utils.secs_to_timestr(old)

    def _set_timeout(self, timeout):
        """
        设置timeout
        """
        # add by jias 20130729 支持${timeout}=1 minute 2 seconds输入
        try:
            time_nubmer = 0
            if (isinstance(timeout, float) or isinstance(timeout, int)):                
                time_nubmer = float(timeout)
            else:
                if not timeout.isdigit():
                    time_nubmer = utils.timestr_to_secs(timeout)
                else:
                    time_nubmer = float(timeout)
                    
            if time_nubmer <= 0:
                raise
            
            self._timeout = time_nubmer
                
        except Exception,e:            
            err_info = u"请输入正确的timeout参数(大于零的整数或者类似'2 minute 30 seconds'的字符串格式)" 
            raise Exception (err_info)

    def telnet_set_newline(self, newline):
        """Sets the newline used by `Write` keyword in the current connection.

        The old newline is returned and can be used to restore the newline later.

        See `Configuration` section for more information about global and
        connection specific configuration.
        """
        if newline == "":
            return (self._newline).replace('\n', 'LF').replace('\r', 'CR')
        
        # lwb:2013-03-05 对传入的参数进行判断
        if newline.upper() not in ['CR', 'LF', 'CRLF']:
            raise Exception (r"unknown newline: %s"  % newline)
        self._verify_connection() 
        old = self._newline
        self._set_newline(newline)
        
        self.newline_set_flg = True
        
        #midified by jias 2013-6-24 显示时，还原为LF.CR等可见字符
        return old.replace('\n', 'LF').replace('\r', 'CR')

    def _set_newline(self, newline):
        self._newline = newline.upper().replace('LF','\n').replace('CR','\r')

    def telnet_set_prompt(self, prompt, prompt_is_regexp=False):
        """Sets the prompt used by `Read Until Prompt` and `Login` in the current connection.

        If `prompt_is_regexp` is given any true value, including any non-empty
        string, the given `prompt` is considered to be a regular expression.

        The old prompt is returned and can be used to restore the prompt later.

        Example:
        | ${prompt} | ${regexp} = | `Set Prompt` | $ |
        | `Do Something` |
        | `Set Prompt` | ${prompt} | ${regexp} |

        See the documentation of
        [http://docs.python.org/2/library/re.html|Python `re` module]
        for more information about the supported regular expression syntax.
        Notice that possible backslashes need to be escaped in Robot Framework
        test data.

        See `Configuration` section for more information about global and
        connection specific configuration.
        """
        self._verify_connection()
        old = self._prompt
        self._set_prompt(prompt, prompt_is_regexp)
        if old[1]:
            return old[0].pattern, True
        return old

    def _set_prompt(self, prompt, prompt_is_regexp):
        if prompt_is_regexp:
            self._prompt = (re.compile(prompt), True)
        else:
            self._prompt = (prompt, False)

    def _prompt_is_set(self):
        return self._prompt[0] is not None

    def telnet_set_encoding(self, encoding):
        """Sets the encoding to use for `writing and reading` in the current connection.

        The old encoding is returned and can be used to restore the encoding
        later.

        See `Configuration` section for more information about global and
        connection specific configuration.

        Setting encoding is a new feature in Robot Framework 2.7.6. Earlier
        versions only supported ASCII.
        """
        # lwb:2013-03-05 对传入的参数进行判断
        try:
            ''.encode(encoding)
        except Exception,e:
            raise Exception (u"unknown encoding %s" % encoding)
        self._verify_connection()
        old = self._encoding
        self._set_encoding(encoding)
        return old

    def _set_encoding(self, encoding):
        self._encoding = encoding

    def _encode(self, text):
        """
        """
        ret = None
        if isinstance(text, str):
            ret = text     
        try:       
            ret = text.encode(self._encoding)
        except Exception,e:
            err_info = u"对输入的内容按照指定编码%s编码错误" % self._encoding
            raise Exception (err_info)
        return ret

    def _decode(self, bytes):
        """
        """
        ret = None
        try:
            ret = bytes.decode(self._encoding)
        except Exception, e:
            err_info = u"对读取的内容按照指定编码%s解码错误" % self._encoding
            raise Exception(err_info)
        return ret

    def telnet_set_default_log_level(self, level):
        """Sets the default log level used for `logging` in the current connection.

        The old default log level is returned and can be used to restore the
        log level later.

        See `Configuration` section for more information about global and
        connection specific configuration.
        """
        # lwb:2013-03-05 对传入的参数进行判断
        if level.upper() not in ['TRACE', 'DEBUG', 'INFO', 'WARN']:
            raise Exception (r"unknown log level: %s"  % level)
        self._verify_connection()
        old = self._default_log_level
        self._set_default_log_level(level)
        return old

    def _set_default_log_level(self, level):
        if level is None or not self._is_valid_log_level(level):
            raise AssertionError("Invalid log level '%s'" % level)
        self._default_log_level = level.upper()

    def _is_valid_log_level(self, level):
        return level is None or level.upper() in ('TRACE', 'DEBUG', 'INFO', 'WARN')

    def telnet_close_connection(self, loglevel=None):
        """Closes the current Telnet connection.

        Remaining output in the connection is read, logged, and returned.
        It is not an error to close an already closed connection.

        Use `Close All Connections` if you want to make sure all opened
        connections are closed.

        See `Logging` section for more information about log levels.
        """
        try:
            self.close()
            log_data = u"关闭当前的telnet连接成功"
            log.user_info(log_data)
        except Exception, e:
            err_info = u"关闭当前的telnet连接失败， %s" % e
            raise RuntimeError(err_info)
        output = self._decode(self.read_all().decode('ASCII', 'ignore'))
        #self._log(output, loglevel) #del by jias 20130719 关闭的时候不打印其他信息
        

    def telnet_login(self, username, password, login_prompt='Login: ',
              password_prompt='Password: ', login_timeout=10, success_prompt="> "):
        """Logs in to the Telnet server with the given user information.

        This keyword reads from the connection until the `login_prompt` is
        encountered and then types the given `username`. Then it reads until
        the `password_prompt` and types the given `password`. In both cases
        a newline is appended automatically and the connection specific
        timeout used when waiting for outputs.

        How logging status is verified depends on whether a prompt is set for
        this connection or not:

        1) If the prompt is set, this keyword reads the output until the prompt
        is found using the normal timeout. If no prompt is found, login is
        considered failed and also this keyword fails. Note that in this case
        both `login_timeout` and `login_incorrect` arguments are ignored.

        2) If the prompt is not set, this keywords sleeps until `login_timeout`
        and then reads all the output available on the connection. If the
        output contains `login_incorrect` text, login is considered failed
        and also this keyword fails. Both of these configuration parameters
        were added in Robot Framework 2.7.6. In earlier versions they were
        hard coded.

        See `Configuration` section for more information about setting
        newline, timeout, and prompt.
        """
        '''
        output = self._submit_credentials(username, password, login_prompt,
        
                                          password_prompt, success_prompt)
        if self._prompt_is_set():
            success, output2 = self._read_until_prompt()
        else:
            success, output2 = self._verify_login_without_prompt(
                    login_timeout, login_incorrect)
        output += output2
        self._log(output)
        if not success:
            raise AssertionError('Login incorrect')
        return output
        '''
        self._verify_timeout(login_timeout)
        if float(login_timeout) <= float(self._timeout):
            raise Exception (u"成功登录时间小于或等于模块系统设置时间，请设置成功登录时间大于模块系统设置时间")
        
        tStart = time.time()
        sleep_time = 0.05
        #cmd telnet 在3次登录失败的情况下 会退出连接 ，程序会么？
        #故要和输入的用户名和密码一起判断
        newline_list = ['\n', '\r', '\r\n']        
        log_title = u"自动获取newline成功，适配到的是：%s ('LF','CR','CRLF'相当于'\\n','\\r','\\r\\n')"
        
        #add by jias 2013-11-11
        #如果用户设置了， 则不再遍历
        if self.newline_set_flg == True:
            newline_list = [self._newline]
            log_title = u"当前newline为：%s ('LF','CR','CRLF'相当于'\\n','\\r','\\r\\n')"
        
        index = 0
        newline_setok = False
        isFirst = True        
        istate = 0 #0表示没有提示，1表示用户名提示，2表示密码提示

        while True:
            # 验证登录超时时间 lwb:2013-05-02
            self._verify_login_timeout(tStart,login_timeout)
                
            if index >= len(newline_list):
                #一轮完成了 ，还不成功 说明输入错误
                log_data = u"登录失败，请确认输入的用户名和密码是否正确。若有设置newline, 请确认newline是否正确。"
                raise Exception(log_data)
            cur_newline = newline_list[index]
            
            if (False == newline_setok):
                log_data = u"当前用%s作为newline登录"%cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                log.user_info(log_data)
                
            if (not isFirst) and (istate != 1):
                telnetlib.Telnet.write(self, self._encode(cur_newline))
                log_data = u"再按一次"
                log.debug_info(log_data)
               
            output = ""
            read = ""
            #找login_prompt    
            for i in range(3):  #担心有延时读两次                
                self._verify_login_timeout(tStart,login_timeout)
                
                # 找到用户名提示符，并输入用户名 lwb:2013-05-02
                read = self.telnet_read()
                if len(read.strip()) <= 0: #没有数据
                    continue
                output += read
                if login_prompt.strip() == (output.splitlines()[-1]).strip():
                    #找到输入name提示
                    istate = 1
                    break
                elif password_prompt.strip() == (output.splitlines()[-1]).strip():
                    #找到输入pass提示
                    istate = 2
                    break
                else:
                    istate = 0
            
            if (isFirst):
                if (1 != istate ):
                    log_data = u"没有找到%s提示符，请确认输入是否正确"%login_prompt
                    raise Exception(log_data)
                isFirst = False
            else:
                if (istate == 1):
                    if (not newline_setok):
                        self._newline = cur_newline
                        newline_setok = True
                        log_data = log_title % cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                        log.user_info(log_data)
                    #下面 输入用户名和密码
                elif (istate == 2):
                    if (not newline_setok):
                        self._newline = cur_newline
                        newline_setok = True
                        log_data = log_title % cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                        log.debug_info(log_data)                    
                    continue #回到 while(True)
                else:
                    istate = 0
                    #test
                    log_data = u"没有用户名提示, 也没有密码输入提示"
                    log.debug_info(log_data)
                    index += 1 #遍历下一个newline                    
                    continue #回到 while(True)
                    
                
            #对登录用户名进行一个字符一个字符的写入
            list_username = list(username)
            for i in range(len(list_username)):
                telnetlib.Telnet.write(self, self._encode(list_username[i]))
                time.sleep(sleep_time)
            
            try:
                telnetlib.Telnet.write(self, self._encode(cur_newline))
            except Exception:
                log_data = u"写newline%s错误"%cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                raise Exception(log_data)
            """
            # 找密码提示符
            find_password = False
            for j in range(3):        
                self._verify_login_timeout(tStart,login_timeout)
                
                read = self.telnet_read() 
                if len(read.strip()) <= 0: #没有数据
                    time.sleep(sleep_time)
                    continue
                output += read
                if password_prompt.strip() == (output.splitlines()[-1]).strip():
                    find_password = True
                    break                    
                else:
                    time.sleep(sleep_time)
                    continue
            if (find_password):
                #得到password提示认为new正确
                #self._newline = cur_newline
                #test
                loginfo = u"找到newline %s"% cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                log.user_info(loginfo)
            else:
                #没找到
                #下一个newline
                pass
            """
            time.sleep(1)
            
            #对登录密码进行一个字符一个字符的写入
            list_password = list(password)
            for i in range(len(list_password)):
                telnetlib.Telnet.write(self, self._encode(list_password[i]))
                time.sleep(sleep_time)
                
            try:
                telnetlib.Telnet.write(self, self._encode(cur_newline))
            except Exception:
                log_data = u"写newline%s错误"%cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                raise Exception(log_data)
            
            #找成功登录提示符 
            for i in range(3):                
                self._verify_login_timeout(tStart, login_timeout)
                  
                read = self.telnet_read()
                log_data = u"read onece:%s"%read
                log.debug_info(log_data)
                if len(read.strip()) <= 0: #没有数据
                    continue
                output += read              
                if success_prompt.strip() == (output.splitlines()[-1]).strip():
                    self._newline = cur_newline
                    newline_setok = True
                    log_data = log_title % cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                    log.user_info(log_data)
                    log_data = u"用户登录成功"
                    log.user_info(log_data)
                    return output      
                elif login_prompt.strip() == (output.splitlines()[-1]).strip():
                    istate = 1
                    #两次输入newline 又回到用户名提示
                    #表示换行正确，用户名和密码错误
                    self._newline = cur_newline
                    newline_setok = True
                    log_data = log_title % cur_newline.replace('\n', 'LF').replace('\r', 'CR')
                    log.user_info(log_data)
                    log_data = u"请检查用户名和密码是否正确"
                    log.debug_info(log_data)#todo raise 太多尝试会报 FAIL : EOFError: telnet connection closed
                    break
                elif password_prompt.strip() == (output.splitlines()[-1]).strip():
                    istate = 2                    
                    log_data = u"读取到的最后一行是: %s" % output.splitlines()[-1]
                    log.debug_info(log_data)
                    #break #err 输入密码（密码不显示)还没有得到成功提示符时（延时），最后一行是password_prompt
                    continue
                else:
                    istate = 3
                    
            if (False == newline_setok):
                #按两次没有用户名提示, 也没有登录成功，newline错误 ，下一个
                #test
                log_data = u"按两次没有用户名提示, 也没有登录成功"
                log.debug_info(log_data)
                index += 1 #遍历下一个newline
        return output
        
    # 登录超时时间的验证 lwb:2013-05-02
    def _verify_login_timeout(self, tStart,login_timeout):
        tEnd = time.time()  # lwb:2013-02-25 对超时时间进行判断
        if float(tEnd-tStart) > float(login_timeout):
            raise Exception (u"在给定的登录时间范围内登录失败, 请检查用户名和密码是否输入正确")
        
    def _submit_credentials(self, username, password, login_prompt, password_prompt):
        
        output = self.telnet_read_until(login_prompt, 'TRACE')
        output += self.telnet_write(username, 'TRACE')
        output += self.telnet_read_until(password_prompt, 'TRACE')
        output += self.telnet_write(password, 'TRACE')
        return output

    def _verify_login_without_prompt(self, delay, incorrect):
        time.sleep(utils.timestr_to_secs(delay))
        output = self.telnet_read('TRACE')
        success = incorrect not in output
        return success, output

    def telnet_write(self, text, loglevel=None):
        """Writes the given text plus a newline into the connection.

        The newline character sequence to use can be [#Configuration|configured]
        both globally and per connection basis. The default value is `CRLF`.

        This keyword consumes the written text, until the added newline, from
        the output and logs and returns it. The given text itself must not
        contain newlines. Use `Write Bare` instead if either of these features
        causes a problem.

        *Note:* This keyword does not return the possible output of the executed
        command. To get the output, one of the `Read ...` keywords must be used.
        See `Writing and reading` section for more details.

        See `Logging` section for more information about log levels.
        """
        self._verify_connection()       
        #调用的telnet_write_bare中有清空前面数据的操作，此处删除
        if self._newline in text:
            raise RuntimeError("'Write' keyword cannot be used with strings "
                               "containing newlines. Use 'Write Bare' instead.")
        self.telnet_write_bare(text + self._newline)
        # Can't read until 'text' because long lines are cut strangely in the output
        write_info = "cur newline :" + (self._newline).replace("\r", "CR").replace("\n", "LF")
        log.debug_info(write_info)
        
        return self.telnet_read_until(self._newline, loglevel)

    def telnet_write_bare(self, text):
        """Writes the given text, and nothing else, into the connection.

        This keyword does not append a newline nor consume the written text.
        Use `Write` if these features are needed.
        """
        self._verify_connection()
        #add by jias 2013-6-24 在写命令之前清空前面没有读完的数据   
        time.sleep(1)
        output = telnetlib.Telnet.read_very_eager(self)
        while (len(output) > 0):
            time.sleep(2)
            output = telnetlib.Telnet.read_very_eager(self)            
        #add end
        telnetlib.Telnet.write(self, self._encode(text))

    def telnet_write_until_expected_output(self, text, expected, timeout,
                                    retry_interval, loglevel=None):
        """Writes the given `text` repeatedly, until `expected` appears in the output.

        `text` is written without appending a newline and it is consumed from
        the output before trying to find `expected`. If `expected` does not
        appear in the output within `timeout`, this keyword fails.

        `retry_interval` defines the time to wait `expected` to appear before
        writing the `text` again. Consuming the written `text` is subject to
        the normal [#Configuration|configured timeout].

        Both `timeout` and `retry_interval` must be given in `time string
        format`. See `Logging` section for more information about log levels.

        Example:
        | Write Until Expected Output | ps -ef| grep myprocess\\r\\n | myprocess |
        | ...                         | 5 s                          | 0.5 s     |

        The above example writes command `ps -ef | grep myprocess\\r\\n` until
        `myprocess` appears in the output. The command is written every 0.5
        seconds and the keyword fails if `myprocess` does not appear in
        the output in 5 seconds.
        """
        # 2013-04-10 对入参进行判断
        self._verify_timeout(timeout)
        self._verify_timeout(retry_interval)
        
        # 传入的参数类型为unicode,要对类型先进行转换再判断 lwb:2013-05-02
        if float(timeout) < float(retry_interval):
            raise Exception(u"请把时间间隔retry_interval设置成小于或等于超时时间timeout")
        
        timeout = utils.timestr_to_secs(timeout)
        retry_interval = utils.timestr_to_secs(retry_interval)
        maxtime = time.time() + timeout
        while time.time() < maxtime:
            self.telnet_write_bare(text)
            # 此句注释如果这里用了读，哪下面的读就为空 lwb:2013-02-05
            # print self.telnet_read_until(text, loglevel)
            try:
                with self._custom_timeout(retry_interval):
                    # 在重复给CPE写入字符串的时候，避免写入和读取的数据不一致 lwb:2013-04-20
                    return self.telnet_read_until(expected, loglevel)
            except AssertionError:
                pass
        self._raise_no_match_found(expected, timeout)

    def telnet_read(self, loglevel=None):
        """Reads everything that is currently available in the output.

        Read output is both returned and logged. See `Logging` section for more
        information about log levels.
        """
        self._verify_connection()
        #延时1秒后再进行读操作
        time.sleep(1)
        output = self._decode(self.read_very_eager().decode('ASCII', 'ignore'))
        self._log(output, loglevel)
        return output

    def telnet_read_until(self, expected, loglevel=None):
        """Reads output until `expected` text is encountered.

        Text up to and including the match is returned and logged. If no match
        is found, this keyword fails. How much to wait for the output depends
        on the [#Configuration|configured timeout].

        See `Logging` section for more information about log levels. Use
        `Read Until Regexp` if more complex matching is needed.
        """
        output = self._read_until(expected)
        
        # CPE回显的特殊字符列表 lwb: 2013-04-24 
        cpe_echo_list= [' \x08','\x08 ','\x08']
        # 去掉cpe回显的特殊字符 lwb: 2013-04-24 
        for cpe_echo in cpe_echo_list:
            if cpe_echo in output:
                output = output.replace(cpe_echo,'')
            else:
                pass
        
        self._log(output, loglevel)
        if not output.endswith(expected):
            self._raise_no_match_found(expected)
        return output

    def _read_until(self, expected):
        self._verify_connection()
        expected = self._encode(expected)
        output = telnetlib.Telnet.read_until(self, expected, self._timeout)
        return self._decode(output.decode('ASCII', 'ignore'))

    def telnet_read_until_regexp(self, *expected):
        """Reads output until any of the `expected` regular expressions match.

        This keyword accepts any number of regular expressions patterns or
        compiled Python regular expression objects as arguments. Text up to
        and including the first match to any of the regular expressions is
        returned and logged. If no match is found, this keyword fails. How much
        to wait for the output depends on the [#Configuration|configured timeout].

        If the last given argument is a [#Logging|valid log level], it is used
        as `loglevel` similarly as with `Read Until` keyword.

        See the documentation of
        [http://docs.python.org/2/library/re.html|Python `re` module]
        for more information about the supported regular expression syntax.
        Notice that possible backslashes need to be escaped in Robot Framework
        test data.

        Examples:
        | `Read Until Regexp` | (#|$) |
        | `Read Until Regexp` | first_regexp | second_regexp |
        | `Read Until Regexp` | \\\\d{4}-\\\\d{2}-\\\\d{2} | DEBUG |
        """
        if not expected:
            raise RuntimeError('At least one pattern required')
        if self._is_valid_log_level(expected[-1]):
            loglevel = expected[-1]
            expected = expected[:-1]
        else:
            loglevel = None
        index, output = self._read_until_regexp(*expected)
        self._log(output, loglevel)
        if index == -1:
            expected = [exp if isinstance(exp, basestring) else exp.pattern
                        for exp in expected]
            self._raise_no_match_found(expected)
        return output

    def _read_until_regexp(self, *expected):
        self._verify_connection()
        expected = [self._encode(exp) if isinstance(exp, unicode) else exp
                    for exp in expected]
        try:
            index, _, output = self.expect(expected, self._timeout)
        except TypeError:
            index, output = -1, ''
        return index, self._decode(output.decode('ASCII', 'ignore'))

    def telnet_read_until_prompt(self, loglevel=None):
        """Reads output until the prompt is encountered.

        This keyword requires the prompt to be [#Configuration|configured]
        either in `importing` or with `Open Connection` or `Set Prompt` keyword.

        Text up to and including the prompt is returned and logged. If no prompt
        is found, this keyword fails. How much to wait for the output depends
        on the [#Configuration|configured timeout].

        See `Logging` section for more information about log levels.
        """
        if not self._prompt_is_set():
            raise RuntimeError('Prompt is not set')
        success, output = self._read_until_prompt()
        self._log(output, loglevel)
        if not success:
            prompt, regexp = self._prompt
            raise AssertionError("Prompt '%s' not found in %s"
                    % (prompt if not regexp else prompt.pattern,
                       utils.secs_to_timestr(self._timeout)))
        return output

    def _read_until_prompt(self):
        prompt, regexp = self._prompt
        if regexp:
            index, output = self._read_until_regexp(prompt)
            success = index != -1
        else:
            output = self._read_until(prompt)
            success = output.endswith(prompt)
        return success, output

    def telnet_execute_command(self, command, loglevel=None):
        """Executes the given `command` and reads, logs, and returns everything until the prompt.

        This keyword requires the prompt to be [#Configuration|configured]
        either in `importing` or with `Open Connection` or `Set Prompt` keyword.

        This is a convenience keyword that uses `Write` and `Read Until Prompt`
        internally Following two examples are thus functionally identical:

        | ${out} = | `Execute Command`   | pwd |

        | `Write`  | pwd                 |
        | ${out} = | `Read Until Prompt` |

        See `Logging` section for more information about log levels.
        """
        self.telnet_write(command, loglevel)
        return self.telnet_read_until_prompt(loglevel)

    @contextmanager
    def _custom_timeout(self, timeout):
        old = self.telnet_set_timeout(timeout)
        try:
            yield
        finally:
            self.telnet_set_timeout(old)
 
    def _verify_connection(self):
        if not self.sock:
            raise RuntimeError('No connection open')

    def _log(self, msg, level=None):
        msg = msg.strip()
        #lwb 2013-02-17 由于远端不支持logger，所以改成print
        if msg:
            log_data = msg
            log.user_info(log_data)
            #logger.write(msg, level or self._default_log_level)

    def _raise_no_match_found(self, expected, timeout=None):
        timeout = utils.secs_to_timestr(timeout or self._timeout)
        expected = "'%s'" % expected if isinstance(expected, basestring) \
            else utils.seq2str(expected, lastsep=' or ')
        raise AssertionError("No match found for %s in %s" % (expected, timeout))

    def _negotiate_echo_on(self, sock, cmd, opt):
        # This is supposed to turn server side echoing on and turn other options off.
        if opt == telnetlib.ECHO and cmd in (telnetlib.WILL, telnetlib.WONT):
            self.sock.sendall(telnetlib.IAC + telnetlib.DO + opt)
        elif opt != telnetlib.NOOPT:
            if cmd in (telnetlib.DO, telnetlib.DONT):
                self.sock.sendall(telnetlib.IAC + telnetlib.WONT + opt)
            elif cmd in (telnetlib.WILL, telnetlib.WONT):
                self.sock.sendall(telnetlib.IAC + telnetlib.DONT + opt)
    
    # 2013-4-10对输入的时间必需要大于0的判断
    def _verify_timeout(self, timeout):
        timeout_1 = timeout
        try:
            timeout_1 = float(timeout_1)
        except ValueError,e:
            raise e
        if timeout_1 <= 0 :
            raise Exception(u"请输入一个大于零的时间")
def Test():
    tel = ATTTelnet(host="192.168.0.1")
    tel.telnet_open_connection(port=23)
    tel.telnet_login(username='Admin', password='admin',login_prompt='Username: ',
              password_prompt='Password: ', login_timeout=12, success_prompt="AP#")
    print tel.telnet_write_until_expected_output('help\n', 'cat', 60, 30)
    
if __name__ == '__main__':
    Test()