# -*- coding: utf-8 -*-
# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: pack
#  function: 测试库打包模块
#  Author: ATT development group
#  version: V1.0
#  date: 2013.5.21
#  change log:
#  lana       20130521    created
#  lana       20130608    优化模块
#  lana       20130618    去掉GUI，采用命令行进行打包
#  lana       20130705    添加对上传安装包服务器地址的配置
#  wangjun    20130712    修改打包时生成的测试库包名字，依赖基础库文件夹命名有缺陷的问题
#                         添加打包完成时更新versin.py文件数据
#  wangjun    20131015    修改打包时生成的测试库版本规则，版本将之分为测试版本和稳定版本
#  wangjun    20131022    添加打包时校验当前库版本类型和当前库依赖框架版本的类型是否一致功能
#  wangjun    20141201    整理打包脚本文件兼容数据库版本升级服务器客户端通信接口
#                         添加测试库功能说明信息和依赖其他测试库版本信息配置数据上传功能
#  wangjun    20141202    提取与服务器通信的接口和打包需要的svn客户端库到TestLibrary/_packtools文件夹中，该文件夹与测试库文件夹同层级。
#                         任何测试库打包脚本打包时均依赖TestLibrary/_packtools文件夹中的文件
#  wangjun    20141204    导入TestLibrary/_packtools/loadtestlibdescriptionctrl模块来读取测试库功能说明信息
#  wangjun    20141223    删除打包时比较当前库版本类型和当前库依赖框架版本的类型是否一致处理,因为现在测试库和框架的匹配规则已经不在依赖框架版本类型
#  wangjun    20141223    添加获取测试库依赖的第三方软件包配置数据返回接口,更新测试库发布版本版本信息文件数据项，保存测试库依赖的第三方软件包配置数据。
#
# ***************************************************************************

import os
import sys
import re 
import zipfile 
import shutil
import time
import datetime
import compileall
import cStringIO 
import Tkinter
import imp
import inspect

#忽略不需要编译的目录和文件
RELEASE_SKIP_FOLDER_LIST = ["pack", '_INSTALL_']
RELEASE_SKIP_FILE_LIST =[]

#配置打包基本文件夹_packtools文件夹路径
#打包文件层次结构--"TestLibrary/HttpServer/Trunk/pack/pack.py"
CUR_FILE_DIR = os.path.split(os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__)))))[0]
TESTLIB_PACK_TOOLS_DIR = os.path.join(CUR_FILE_DIR, "_packtools")
if not os.path.exists(TESTLIB_PACK_TOOLS_DIR):
    #TAG目录和Trunk目录层级不同。--"TestLibrary/HttpServer/Tag/v1.0.0/pack/pack.py"
    CUR_FILE_DIR = os.path.split(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))))[0]
    TESTLIB_PACK_TOOLS_DIR = os.path.join(CUR_FILE_DIR, "_packtools")
#将_packtools文件夹加入到系统路径中
sys.path.insert(0, CUR_FILE_DIR)
sys.path.insert(0, TESTLIB_PACK_TOOLS_DIR)

#添加svn客户端文件
from _packtools import pysvn

#添加升级服务器客户端控制文件
from _packtools.uploadclient.uploadclient import UploadClient
from _packtools.uploadclient.uploadproperty import UploadPropertyClient
from _packtools.uploadclient._base_common.msgdef import Event, REQUEST_PROCESS_FAIL, REQUEST_PROCESS_SUC
from _packtools.uploadclient._base_common.loadconfigctrl import LoadConfigCtrl 
        
#加载测试库功能说明数据
from _packtools.loadtestlibdescriptionctrl import LoadTestLibDescriptionCtrl

#定义获取基础库的相关信息KEY值
PROJECT_HOME = ""
TESTLIB_NAME = ""

TEST_LIB_PROPERTY_NAME="name"
TEST_LIB_PROPERTY_ALIAS="alias"
TEST_LIB_PROPERTY_REMOTE_FLAG="remote_flag"


class ATT_Error(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return self.value


def walk_dir(dir,topdown=True):
    """
    遍历整个dir目录，返回dir下所有文件的全路径列表
    如果topdown为True,表示从上到下进行遍历，先返回父目录文件路径，再返回子目录文件路径
    如果topdown为False， 表示从下到上进行遍历，先返回子目录文件路径，再返回父目录文件路径
    """
    
    file_list = []
    for root, dirs, files in os.walk(dir, topdown):
        for name in files:
            file_list.append(os.path.join(root,name))
        
    return file_list


def zip_folder(folder_name, file_name, include_empty_dir=True):
    """
    将folder_name中的文件压缩成zip文件file_name
    """
    
    zip = zipfile.ZipFile(file_name, 'w', zipfile.ZIP_DEFLATED)   
    for root, dirs, files in os.walk(folder_name):  
        empty_dirs = []
        empty_dirs.extend([dir for dir in dirs if os.listdir(os.path.join(root, dir)) == []])   
        for name in files:  
            file_abs_path = os.path.join(os.path.join(root, name))
            file_rel_path = os.path.relpath(file_abs_path, folder_name)
            zip.write(file_abs_path, file_rel_path, zipfile.ZIP_DEFLATED)   
        if include_empty_dir:   
            for dir in empty_dirs:  
                empty_dir_abs_path = os.path.join(os.path.join(root, dir))
                empty_dir_rel_path = os.path.relpath(empty_dir_abs_path, folder_name)
                zif = zipfile.ZipInfo(empty_dir_rel_path + "/") 
                zip.writestr(zif, "")   
        empty_dirs = []   
    zip.close()  


def get_property_file_path(work_dir):
    """
    返回当前测试库的配置文件的路径
    """
    global TESTLIB_NAME
    
    file_list = os.listdir(work_dir)
    for tmp_file in file_list:
        if tmp_file.find("Property.py") != -1:
            
            #分割*Property.py文件，取得基础库文件名#add by wangjun 20130712
            testlib_property_file_name=os.path.basename(tmp_file)
            index=testlib_property_file_name.find("Property.py")
            TESTLIB_NAME=testlib_property_file_name[0:index]
            
            return os.path.join(work_dir, tmp_file)
    
    return None

    
class ClearTempFiles(object):
    """
    清零临时文件类
    """

    def clear_dir_tmp_files(self,work_dir):
        """
        删除临时文件
        """
        
        try:
            # 获取当前工作目录下的所有临时文件
            file_list = self.get_temp_files(walk_dir(work_dir))
            for file in file_list:
                # 删除文件
                os.remove(file)
                
        except Exception, e:
            err_info = u"删除临时文件出错，错误信息为: %s" % e.message
            raise ATT_Error, err_info
    
    
    def get_temp_files(self, all_file_list):
        """
        从文件列表all_file_list中过滤临时文件，然后返回临时文件列表
        """
        
        file_list = []
        for file in all_file_list:
            file_type = os.path.splitext(file)[1]
            
            #列举临时文件后缀
            if (file_type.lower() == ".pyc" or
                file_type.lower() == ".pyo" or
                file_type.lower() == ".bak"):
                
                file_list.append(file)
            else:
                pass
            
        return file_list
    
    
    def clear_dir_temp_dir(self, work_dir, remove_text):
        """
        清除work_dir中目录名包含remove_text的目录
        """
        
        try:
            list_dirs = os.walk(work_dir)
            for root, dirs, files in list_dirs:
                for d in dirs:
                    if d.find(remove_text) != -1:
                        _temp = os.path.join(root, d)
                        shutil.rmtree(_temp)
                        
        except Exception,e:
            err_info = u"删除含有 %s 的目录出错，错误信息为: %s" % (remove_text, e.message)
            raise ATT_Error, err_info
    
    
class CompileFiles(object):
    """
    打包文件类
    """
    
    def __init__(self, main_dir, version_type="a", need_compile=True, need_upload=True, need_update_fun_desc=False):
        """
        initial variable
        """
        
        self.main_dir = main_dir
        self.version_type = version_type
        self.need_compile = need_compile
        self.need_upload = need_upload        # 是否需要上传到升级服务器中
        
        self.need_update_fun_desc = need_update_fun_desc #是否更新测试库功能说明信息到服务器中 #added by wangjun@20141202
        
        self.version = ""
        #add by wangjun 20130702
        self.remote_property_flag=False
        self.temp_dir_name = "__att_temp_"
        self._zip_dir_name = "_INSTALL_"
        self.property_file_path = get_property_file_path(main_dir)
    
        #添加基础测试库别名数据获取 #add by wangjun 20130813 
        self.testlib_alias=""
        
        #changed by wangjun@20141222
        #-------------------------------------------------
        #测试库依赖框架加载控制模块版本，此为版本测试库和框架版本匹配数据
        self.base_platform_load_plugin_ver=""

        #测试库依赖核心代码包配置文件数据
        self.testlib_dependencies_cfg_dict = {}
        self.testlib_dependencies_cfg_dict['INCLUDE_KERNAL_CODE'] = False
        self.testlib_dependencies_cfg_dict['DEPENDENCIES_LIB_NAME'] = ''
        self.testlib_dependencies_cfg_dict['TESTLIB_KERNAL_CODE_FOLDER_NAME'] = ''


        #测试库依赖核心代码版本，默认为空
        self.testlib_kernal_identity=""
        
        #测试库依赖其他测试库名称以及内核版本信息
        self.testlib_dependencies_dict = {}
        #-------------------------------------------------
        
        
    def init_compiler_dir(self, work_dir, compiler_dir):
        """
        初始化compiler目录，将需要编译的文件拷贝到compiler目录下
        """
        
        # 目标文件夹不存在，则新建
        if not os.path.exists(compiler_dir):
            os.mkdir(compiler_dir)
        
        # 获取work_dir下的所有文件    
        names = os.listdir(work_dir)
        
        # 遍历源文件夹中的文件与文件夹
        for name in names:
            work_dir_name = os.path.join(work_dir, name)
            compiler_dir_name = os.path.join(compiler_dir, name)
            try:
                # 是文件夹则递归调用本拷贝函数，否则直接拷贝文件
                if os.path.isdir(work_dir_name):   
                    # 如果是IDE或版本管理生成的目录，则忽略
                    if (name.lower() == ".komodotools" or
                        name.lower() == ".svn" or
                        name.lower() == ".git" ):
                        pass
                    
                    # 忽略不需要编译的目录
                    elif name in RELEASE_SKIP_FOLDER_LIST:
                        pass
                    
                    # 忽略当前编译临时目录
                    elif work_dir_name == compiler_dir:
                        pass
                    
                    # 忽略未删除的之前的编译临时目录
                    elif name.find(self.temp_dir_name) != -1:
                        pass
                    
                    else:
                        self.init_compiler_dir(work_dir_name, compiler_dir_name)
                        
                else:
                    # 如果是IDE或版本管理生成的文件，或者是pyc和pyo文件，则忽略
                    if (os.path.splitext(name)[1].lower() == ".komodoproject" or
                        os.path.splitext(name)[1].lower() == ".buildpath" or
                        os.path.splitext(name)[1].lower() == ".project" or
                        os.path.splitext(name)[1].lower() == ".gitignore" or
                        os.path.splitext(name)[1].lower() == ".pyc" or
                        os.path.splitext(name)[1].lower() == ".pyo" or
                        os.path.splitext(name)[1] == ".IAB" or
                        os.path.splitext(name)[1] == ".IAD" or
                        os.path.splitext(name)[1] == ".IMB" or
                        os.path.splitext(name)[1] == ".IMD" or
                        os.path.splitext(name)[1] == ".PFI" or
                        os.path.splitext(name)[1] == ".PO" or
                        os.path.splitext(name)[1] == ".PR" or
                        os.path.splitext(name)[1] == ".PRI" or
                        os.path.splitext(name)[1] == ".PS" or
                        os.path.splitext(name)[1] == ".SearchResults" or
                        os.path.splitext(name)[1] == ".WK3" or
                        (work_dir_name == __file__ and self.need_compile == 1)):
                        pass
                    
                    # 忽略不需要编译的文件
                    elif os.path.split(name)[1] in RELEASE_SKIP_FOLDER_LIST:
                        pass
                    
                    elif (os.path.splitext(work_dir_name)[1].lower() == ".zip" and
                          os.path.split(work_dir_name)[1].find(TESTLIB_NAME) != -1 and
                          os.path.split(work_dir_name)[0] == os.path.join(self.main_dir)):
                        pass
                    
                    else:
                        shutil.copy2(work_dir_name, compiler_dir)
            except Exception, e:
                shutil.rmtree(compiler_dir)
                raise ATT_Error, e.message
    
    
    def check_svn_version(self):
        """
        检查当前工作目录中的文件版本是否与SVN库中的一致
        """
        
        client = pysvn.Client()
        changes = client.status(PROJECT_HOME)
        files_to_be_added = [f.path for f in changes if f.text_status == pysvn.wc_status_kind.added]
        files_to_be_removed = [f.path for f in changes if f.text_status == pysvn.wc_status_kind.deleted]
        files_that_have_changed = [f.path for f in changes if f.text_status == pysvn.wc_status_kind.modified]
        files_with_merge_conflicts = [f.path for f in changes if f.text_status == pysvn.wc_status_kind.conflicted]
        unversioned_files = [f.path for f in changes if f.text_status == pysvn.wc_status_kind.unversioned]
        
        if (files_to_be_added ==[] and
            files_to_be_removed == [] and
            files_with_merge_conflicts == []):
            pass
        else:
            err_info = u"当前目录存在修改，请将修改上传SVN后再进行打包操作，谢谢。"
            raise ATT_Error, err_info
        
        if files_that_have_changed == []:
            pass
        else:
            for file in files_that_have_changed:
                # 忽略pack.py的修改
                if file == os.path.join(self.main_dir, "pack", "pack.py"):
                    pass
                else:
                    err_info = u"当前目录存在修改，请将修改上传SVN后再进行打包操作，谢谢。"
                    raise ATT_Error, err_info
                    
            
        if unversioned_files == []:
            pass
        
        else:
            
            err_info = u"当前目录存在修改，请将修改上传SVN后再进行打包操作，谢谢。"
            raise ATT_Error, err_info
        
        print u'本地版本和服务器上版本一致。'
        

    def get_svn_version_info(self):    
        """
        读取当前工作目录中的文件SVN版本信息
        """
        client = pysvn.Client()
        
        # 验证本地的版本和远端服务器上面版本一致，则开始获取版本号。
        print u'本地版本和服务器上版本一致，开始获取当前版本的版本信息。'
        entry = client.info(PROJECT_HOME)
        
        print u'SVN路径:',entry.url
        print u'最新版本:',entry.commit_revision.number
        print u'提交人员:',entry.commit_author
        print u'更新日期:', datetime.datetime.fromtimestamp(entry.commit_time)
            
        self.svn_commit_revision = entry.commit_revision.number
        self.svn_url = entry.url
        self.svn_commit_time = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(entry.commit_time))
        self.pack_time = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))   

    
    def get_cfg_version_info(self, path, version_type):
        """
        根据path导入*Property模块，然后从模块中获取版本信息以及remote属性并返回
        """
        
        # 获取模块名
        dirpath, filename = os.path.split(path)
        modulename = os.path.splitext(filename)[0]
        
        # 查找模块是否存在
        try:
            file, imppath, description = imp.find_module(modulename, [dirpath])
        except ImportError, err:
            err_info = "Find test lib module '%s' failed:\n%s" % (path, err)
            print err_info
            raise ATT_Error, err_info
            
        # 导入模块
        try:
            module = imp.load_module(modulename, file, imppath, description)
        except Exception, err:
            err_info = "Importing  test lib  module '%s' failed:\n%s" % (path, err)
            print err_info
            raise ATT_Error, err_info
        
        finally:
            if file:
                file.close()
        
        #获取基础库打包基本信息信息
        testlib_ver_major=None
        testlib_ver_minor_number=None
        testlib_ver_revision_number=None
        testlib_ver_base_robot_ver=None
        testlib_remote_flag=False
        testlib_alias=""
        
        #获取基础库class列表
        class_list=[ cls for _, cls in inspect.getmembers(module, predicate=inspect.isclass) ]
        #print class_list

        load_data_count=0
        for cls_node in class_list:
                        
            #控制类节点是测试库属性配置类。add by wangjun 20140628
            try:
                cls_node_name = cls_node.__name__
                
                #当类节点是TestLibraryBaseProperty时或者不是测试库属性配置类，中断后续流程。
                if "TestLibraryBaseProperty" == cls_node_name or cls_node_name.find("Property") == -1:
                    continue
                
                print cls_node_name
                
            except Exception, e:
                continue
            
            method_list=inspect.classify_class_attrs(cls_node)
            for method_node in method_list:
                if(method_node.name == '_get_test_lib_property'):
                    
                    test_lib_property_dict=cls_node._get_test_lib_property()
                    if (isinstance(test_lib_property_dict, dict)):
                        #print cls, test_lib_property_dict

                        #获取基础测试库别名数据
                        testlib_name=test_lib_property_dict.get(TEST_LIB_PROPERTY_NAME)
                        testlib_alias=test_lib_property_dict.get(TEST_LIB_PROPERTY_ALIAS)
                        if not testlib_alias:
                            testlib_alias=testlib_name
                        
                        #获取测试库REMOTE标志   
                        testlib_remote_flag=test_lib_property_dict.get(TEST_LIB_PROPERTY_REMOTE_FLAG)
                    
                    load_data_count += 1
                
                elif(method_node.name == '_get_cfg_test_lib_version_property'):
                    
                    #默认为Stable版本
                    testlib_version_type_is_bete_flag=False
                    if version_type == "d" or version_type == "b":
                        testlib_version_type_is_bete_flag=True
                    
                    #获取打包测试库版本需要的配置信息
                    testlib_ver_major, \
                    testlib_ver_minor_number, \
                    testlib_ver_revision_number, \
                    testlib_ver_base_robot_ver, = cls_node._get_cfg_test_lib_version_property(testlib_version_type_is_bete_flag)
                    
                    load_data_count += 1
                
                
                #跳出数据查找循环
                if 2 == load_data_count:
                    break
                
        #返回基础库版本信息以及remote属性,别名数据
        return testlib_ver_major, \
                testlib_ver_minor_number, \
                testlib_ver_revision_number, \
                testlib_ver_base_robot_ver, \
                testlib_remote_flag, \
                testlib_alias
    
    
    def init_version(self,compiler_dir):
        """
        初始化打包文件的版本号
        """
        
        #获取SVN号相关信息
        self.get_svn_version_info()
        
        # 从property文件中获取版本信息
        try:
            if self.property_file_path:
                #changed by wangjun 20130702#添加基础测试库别名数据获取 #add by wangjun 20130813
                MAJOR_VERSION_NUMBER, \
                MINOR_VERSION_NUMBER, \
                REVISION_NUMBER,\
                BASED_ATTROBOT_VERSION,\
                REMOTE_PROPERTY_FLAG, \
                TESTLIB_ALIAS_STRING = self.get_cfg_version_info(self.property_file_path, self.version_type)
                
            else:
                err_info = u"未找到当前测试库的配置文件，请确认配置文件是否存在！"
                print err_info
                raise ATT_Error, err_info
            
        except Exception, e:
            raise ATT_Error, e.message

        #构建版本号
        if self.version_type == "b":
            
            #构建测试版版本号
            date_ver_string=datetime.datetime.now().strftime('%Y%m%d')
            date_ver_string=date_ver_string[2:]
            self.version ="v.beta%s.svn%s" % (date_ver_string,self.svn_commit_revision)

        elif self.version_type == "d":
            
            #构建调试版版本号
            date_ver_string=datetime.datetime.now().strftime('%Y%m%d')
            date_ver_string=date_ver_string[2:]
            self.version ="v.debug%s.svn%s" % (date_ver_string,self.svn_commit_revision)
            
        else:
            #构建正式版版本号
            self.version = "v%s.%s.%s"  % ( MAJOR_VERSION_NUMBER, MINOR_VERSION_NUMBER,REVISION_NUMBER)
            
        #add by wangjun 20130701
        self.base_platform_load_plugin_ver="%s"%(BASED_ATTROBOT_VERSION.lower())

        #add by wangjun 20130702
        self.remote_property_flag=REMOTE_PROPERTY_FLAG
        
        #添加基础测试库别名数据获取 #add by wangjun 20130813 
        self.testlib_alias=TESTLIB_ALIAS_STRING
        
        print u'当前打包版本版本号为： %s ' % self.version  
    
    
    #add by wangjun 20130712
    def update_version_file(self, version_file_dir):
        """
        写基础测试库version.py文件数据
        """
        version_file = os.path.join(version_file_dir, "testlibversion.py")
        version_string = "# -*- coding: utf-8 -*-"
        
        version_string += "\nVERSION = '%s'"
        version_string += "\nSVN_URL = '%s'"
        version_string += "\nSVN_VERSION = '%s'"
        version_string += "\nSVN_LAST_COMMIT_TIME = '%s'"
        version_string += "\nVERSION_PACK_TIME = '%s'"
        version_string += "\nBASE_PLATFORM_LOAD_PLUGIN_VERSION = '%s'"
        
        version_string += "\nINCLUDE_KERNAL_CODE = %s"
        version_string += "\nDEPENDENCIES_LIB_NAME = '%s'"
        version_string += "\nTESTLIB_KERNAL_CODE_FOLDER_NAME = '%s'"
        version_string += "\nTESTLIB_KERNAL_VERSION = '%s'"
        version_string += "\n"
        
        version_string = version_string%(self.version,
                                        self.svn_url,
                                        self.svn_commit_revision,
                                        self.svn_commit_time,
                                        self.pack_time,
                                        self.base_platform_load_plugin_ver,
                                        self.testlib_dependencies_cfg_dict.get('INCLUDE_KERNAL_CODE'),
                                        self.testlib_dependencies_cfg_dict.get('DEPENDENCIES_LIB_NAME'),
                                        self.testlib_dependencies_cfg_dict.get('TESTLIB_KERNAL_CODE_FOLDER_NAME'),
                                        self.testlib_kernal_identity )
        
        print u"\n%s" % version_string
        
        if True:
            file_object = open(version_file, 'wb')
            try:
                file_object.write(version_string)
            finally:
                file_object.close()
        else:
            pass
        
        
    def get_py_files(self, all_file_list):
        """
        从all_file_list中过滤所有以.py为后缀的文件
        """
        
        file_list = []
        for file in all_file_list:
            file_type = os.path.splitext(file)[1]
            if file_type.lower() == ".py":
                file_list.append(file)
            else:
                pass
        return file_list
    
    
    def TclCompile(self, compile_path):
        """
        编译tcl文件为tbc文件
        """
        
        print u"准备开始编译tcl文件"
        # 初始化TCL/TK解释器对象
        tcl_obj = Tkinter.Tcl()
        tcl_ret = ""
        
        try:
            # 获取要调用的tcl文件的全路径
            file_path = os.path.abspath(__file__)
            file_dir = os.path.dirname(file_path)
            file_path = os.path.join(file_dir, 'Compiler.tcl')
            
            # source tcl文件
            cmd ='source {%s}' %(file_path)
            tcl_ret = tcl_obj.eval(cmd)
            
            print u"开始编译tcl文件"
            
            # 执行编译命令
            compiler_dir = compile_path.replace("\\", "/")
            cmd ='Encrypt {%s} %s' % (compiler_dir, "Source")
            tcl_ret = tcl_obj.eval(cmd)
            if tcl_ret == "1":
                print u"编译tcl文件成功"
            else:
                print tcl_ret
        except Exception,e:
            err_info = u"编译tcl文件发生异常.错误信息为：%s" % e
            raise ATT_Error, err_info
    
    

    def main(self):
        """
        打包主流程
        """
        
        self.svn_commit_revision = 'debug_'
        self.svn_url = ""
        self.svn_commit_time = ""
        self.pack_time = ""
        
        print u"1、清除临时文件."
        try:
            clearobject=ClearTempFiles()
            clearobject.clear_dir_tmp_files(self.main_dir)        
        except Exception, e:
            print u"清除临时文件出错，错误信息为%s" % e
            return
        
        print u"2、清除上次打包的临时文件."
        try:
            clearobject.clear_dir_temp_dir(self.main_dir, self.temp_dir_name)
        except Exception, e:
            print u"清除上次打包的临时文件出错，错误信息为%s" % e
            return
        
        print u"3、清除打包后的结果文件."
        try:
            clearobject.clear_dir_temp_dir(self.main_dir, self._zip_dir_name)
        except Exception, e:
            print u"清除打包后的结果文件出错，错误信息为%s" % e
            return
        
        # 检查是否是debug模式
        if self.version_type == 'd':
            print u"4、当前模式为DEBUG模式，不需要检查svn版本."
        
        else:
            print u"4、当前模式为非DEBUG模式，开始检查svn版本."
            
            try:
                self.check_svn_version()
            except Exception, e:
                err_info = u"检查svn版本出错，错误信息为：%s" % e
                print err_info
                return
                
            print u"获取当前目录svn版本号成功，svn版本号为：%s" % self.svn_commit_revision
            
        print u"5、开始复制目录."
        work_dir = os.path.join(self.main_dir)
        
        # 创建编译目录
        compiler_dir = os.path.join(self.main_dir, self.temp_dir_name + time.strftime('%Y%m%d%H%M%S__'))
        if not os.path.exists(compiler_dir):
            os.mkdir(compiler_dir)
        
        print u"当前打包文件临时目录为：%s"  % compiler_dir
        print u"开始复制目录%s 到 %s " % (work_dir, compiler_dir)
        
        try:
            self.init_compiler_dir(work_dir, compiler_dir)
        except Exception, e:
            err_info = u"复制目录出错，错误信息为：%s" % e
            print err_info
            return
            
        print u"6、开始组建版本信息"
        try:
            self.init_version(compiler_dir)
        except Exception,e:
            print u"初始化版本号出错，错误信息为：%s" % e
            return

        #changed by wangjun@20141222
        #-------------------------------------------------
        #读取该测试库依赖其他测试库版本配置数据
        rc_status,\
        rc_testlib_dependencies_cfg_dict,\
        rc_kenal_code_ver,\
        rc_testlib_dependencies_dict = self.get_testlib_dependencies_data()
        
        if rc_status:
            #测试库依赖核心代码版本，默认为空
            self.testlib_kernal_identity = rc_kenal_code_ver
            
            #测试库依赖其他测试库名称以及内核版本信息,默认为空
            if len(rc_testlib_dependencies_dict.keys()):
                self.testlib_dependencies_dict = rc_testlib_dependencies_dict
                self.testlib_dependencies_cfg_dict = rc_testlib_dependencies_cfg_dict
        #-------------------------------------------------
        
        #add by wangjun 20130712
        print u"6.1、更新version.py文件信息"
        self.update_version_file(compiler_dir)
        
        if self.need_compile == True:
            
            print u"7、开始编译文件"
            
            try:
                #获取.py文件列表
                file_list = self.get_py_files(walk_dir(compiler_dir))
                
                #编译文件
                compileall.compile_dir(compiler_dir, 100, "", True, re.compile(r'____temp__temp____'), True)
                
                print u"编译.py文件成功"
                
                for file in file_list:
                    os.remove(file)
                
                # compile tcl files
                self.TclCompile(compiler_dir)
            except Exception, e:
                print u"编译文件出错，错误信息为: %s" % e
                return
            
        else:
            print u"7、设置为不编译文件"
        
        
        # 创建安装包目录
        print u"8、创建_INSTALL_文件夹"
        _install_dir = os.path.join(self.main_dir, "_INSTALL_" )
        if not os.path.exists(_install_dir):
            os.mkdir(_install_dir)
        
        # 组建安装包文件名
        install_dir = os.path.join(_install_dir, self.version )
        if not os.path.exists(install_dir):
            os.mkdir(install_dir)
        
        # 暂时不加版本号
        install_file = os.path.join(install_dir, TESTLIB_NAME + "_" + self.version + ".zip")
        #install_file = os.path.join(install_dir, TESTLIB_NAME + ".zip")
        
        print (u"9、开始打包文件到：%s."% install_file)
        
        # 打包zip安装包
        try:
            zip_folder(compiler_dir, install_file)
        except Exception,e:
            print u"打包文件出错，错误信息为：%s" % e
            return
        
        # 删除编译目录
        print u"10、打包成功，开始删除临时文件；"
        shutil.rmtree(compiler_dir)
        
        print u"生成安装包成功，本地安装包路径为 %s ；" % (install_file)
        
        if self.need_upload:
            #上传打包好的库到服务器
            #add by wangjun 20130701
            self.upload_testlib_zip_package(install_file)
            
            #added by wangjun@20141201
            #添加测试库功能说明信息和依赖其他测试库版本信息配置数据上传功能
            #------------------------------------------------------------begin
            self.upload_testlib_fun_desc()
            self.upload_testlib_dependencies()
            #------------------------------------------------------------ end
            
        else:
            #复制打包文件到packge/plugin下面
            _INSTALL_PACKAGE_PATH= os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
            output=os.path.join(_INSTALL_PACKAGE_PATH, "package")
            
            if not os.path.exists(output):
                print "mkdir: %s"%(output) 
                os.mkdir(output)
                
            output=os.path.join(output, "plugin")    
            if not os.path.exists(output):
                print "mkdir: %s"%(output) 
                os.mkdir(output)
                
            shutil.copy2(install_file, output)
            print u"复制 %s 到 %s ." % (install_file, output)
    
    
    #add by wangjun 20130701
    def upload_testlib_zip_package(self,in_upload_file_path):
        """
        上传
        """
        print(u"\n11、开始上传库文件：%s" % in_upload_file_path)
        
        if ""==self.base_platform_load_plugin_ver:
            print u"上传文件初始化失败，没有找到基于平台版本信息。错误版本信息为：%s" % self.base_platform_load_plugin_ver
            return REQUEST_PROCESS_FAIL
        
        if not self.testlib_dependencies_cfg_dict.get('INCLUDE_KERNAL_CODE'):
            self.testlib_kernal_identity = ""
            
        #print u'-------------------------------------------------------'
        upload_obj=UploadClient()
        rc_request_status=upload_obj.handle_upload(TESTLIB_NAME,
                                                    self.version,
                                                    self.testlib_kernal_identity,
                                                    self.base_platform_load_plugin_ver,
                                                    self.remote_property_flag,
                                                    self.testlib_alias,
                                                    in_upload_file_path)
        #print u'-------------------------------------------------------\n'
        
        if REQUEST_PROCESS_FAIL==rc_request_status:
            print(u"上传库失败：%s" % TESTLIB_NAME + '_' + self.version + '.zip')
            print (u"上传库失败原因：%s" % upload_obj.get_error_string())
            return rc_request_status
        
        print(u"上传库成功：%s" % TESTLIB_NAME + '_' + self.version + '.zip')
        return REQUEST_PROCESS_SUC
    
    
    #added by wangjun@20141201
    #添加测试库功能说明信息和依赖其他测试库版本信息配置数据上传功能
    #------------------------------------------------------------begin
    def get_testlib_fun_desc_data(self):
        """
        根据path导入testlibdescription.py模块，然后从模块中获取测试库功能说明信息
        """
        global TESTLIB_NAME
        
        testlibdescription_file_path = os.path.join(self.main_dir, 'testlibdescription.py')
        return LoadTestLibDescriptionCtrl.get_testlib_description_data(TESTLIB_NAME,
                                                                       testlibdescription_file_path)

    def get_testlib_dependencies_data(self):
        """
        根据testlibdependencies.cfg导入测试库依赖核心代码包SVN版本，然后组件依赖其他测试库版本信息数据并返回
        """
        
        def _get_testlib_kernal_code_version(in_version_type):
            """
            获取依赖测试库名称和测试库依赖核心代码包SVN版本数据
            """
            
            try:
                global CUR_FILE_DIR
                
                #加载数据状态
                rc_status = False
                
                #配置文件数据项的值
                rc_testlib_dependencies_cfg_dict = {}
                
                #测试库依赖核心代码包SVN版本，默认为空，标示不依赖第三方软件包
                rc_kenal_code_ver = ''
            
                #print u"------------------------------------------------------------"
                
                #[0]依赖测试库配置文件路径. -pack
                temp_pack_shell_folder_path = os.path.dirname(os.path.realpath(__file__))
                in_testlib_depe_cfg_file_path = os.path.join(temp_pack_shell_folder_path,'testlibdependencies.cfg')
                if not os.path.exists(in_testlib_depe_cfg_file_path):
                    print u"没有在pack找到测试库依赖关系配置文件: %s" % in_testlib_depe_cfg_file_path
                    return
                
                #[1]测试库代码SVN测试库跟节点路径
                in_testlib_root_dir = CUR_FILE_DIR
                
                #[2]源代码类型、-Branch/Tag/Trunk
                in_testlib_release_code_folder_name = os.path.split(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))[1]
                
                #[3]导入获取测试库依赖核心代码包SVN版本控制模块
                from _packtools.loadkernalcodesvnver import LoadKernalCodeSvnVer
                
                #[3-1]获取测试库依赖核心代码包SVN版本
                rc_status,\
                rc_testlib_dependencies_cfg_dict,\
                rc_kenal_code_ver = LoadKernalCodeSvnVer.get_kernal_code_version(in_version_type,
                                                                                 in_testlib_depe_cfg_file_path,
                                                                                  in_testlib_root_dir,
                                                                                  in_testlib_release_code_folder_name)
                
                if (not rc_status or
                    not rc_testlib_dependencies_cfg_dict or
                    not rc_kenal_code_ver):
                        return
                    
                rc_status = True
            
            except Exception, e:
                print u"获取依赖测试库名称和测试库依赖核心代码包SVN版本数据异常: %s" % e.message
                
            finally:
                #print u"------------------------------------------------------------"
                return rc_status, \
                        rc_testlib_dependencies_cfg_dict,\
                        rc_kenal_code_ver
        
        #[0] 
        #-------------------------------------------------------------
        #测试库依赖其他测试库版本信息，默认为空。
        #配置数据具体格式如下：
        #    {依赖测试库名称1：[依赖测试库版本1，...],
        #     依赖测试库名称2：[依赖测试库版本1，...],......}
        #-------------------------------------------------------------
        rc_testlib_dependencies_dict = {}
        
        #[1]获取依赖测试库名称和测试库依赖核心代码包SVN版本数据
        rc_status,\
        rc_testlib_dependencies_cfg_dict,\
        rc_kenal_code_ver = _get_testlib_kernal_code_version(self.version_type)
        
        rc_include_kernal_code_flag = rc_testlib_dependencies_cfg_dict.get("INCLUDE_KERNAL_CODE")
        rc_depe_testlib_name = rc_testlib_dependencies_cfg_dict.get("DEPENDENCIES_LIB_NAME")
        
        if rc_status:
            #[2]
            rc_testlib_dependencies_dict[rc_depe_testlib_name] = [rc_kenal_code_ver]
            print u"测试库依赖其他测试库版本信息:", rc_testlib_dependencies_dict
            
        #[3]返回测试库依赖其他测试库版本信息
        return rc_status, \
                rc_testlib_dependencies_cfg_dict, \
                rc_kenal_code_ver, \
                rc_testlib_dependencies_dict
            
    
    
    def upload_testlib_fun_desc(self):
        """
        上传测试库功能说明数据消息
        """
        global TESTLIB_NAME
        
        #不向服务器请求更新测试库功能描述信息
        if not self.need_update_fun_desc:
            return
        
        #从本地读取测试库功能说明信息
        rc_stauts, rc_data = self.get_testlib_fun_desc_data()
        if (not rc_stauts or
            not rc_data):
            print(u"从本地读取测试库(%s)功能说明信息失败" % TESTLIB_NAME)
            return REQUEST_PROCESS_FAIL
        
        #创建配置测试库属性数据对象
        upload_pro_obj = UploadPropertyClient()
        #发送上传测试库功能说明数据消息
        rc_request_status = upload_pro_obj.handle_upload_testlib_fun_desc(TESTLIB_NAME, rc_data)
        if REQUEST_PROCESS_FAIL==rc_request_status:
            print(u"上传测试库(%s)功能说明数据消息失败" % TESTLIB_NAME)
            print (u"上传数据失败原因：%s" % upload_pro_obj.get_error_string())
            return rc_request_status
        
        print(u"上传测试库(%s)功能说明数据消息成功" % TESTLIB_NAME)
        return REQUEST_PROCESS_SUC
        
    
    def upload_testlib_dependencies(self):
        """
        上传测试库依赖其他测试库版本配置数据消息
        """
        global TESTLIB_NAME
        
        #修改测试库依赖其他测试库版本配置数据数据来源 #changed by wangjun@20141222
        rc_testlib_dependencies_dict = self.testlib_dependencies_dict
                
        if self.testlib_dependencies_cfg_dict.get('INCLUDE_KERNAL_CODE'):
            print(u"测试库(%s)不依赖其他测试库版本" % TESTLIB_NAME)
            return REQUEST_PROCESS_SUC
        
        #检查测试是否有对其他测试库版本依赖
        if 0 == len(rc_testlib_dependencies_dict.keys()):
            print(u"测试库(%s)不依赖其他测试库版本" % TESTLIB_NAME)
            return REQUEST_PROCESS_SUC
        
        #创建配置测试库属性数据对象
        upload_pro_obj = UploadPropertyClient()
        #发送上传测试库依赖其他测试库版本配置数据消息
        rc_request_status = upload_pro_obj.handle_upload_testlib_dependencies(TESTLIB_NAME,
                                                                    self.version,
                                                                    rc_testlib_dependencies_dict)
        if REQUEST_PROCESS_FAIL==rc_request_status:
            print(u"上传测试库(%s)版本(%s)依赖其他测试库版本配置数据失败" % (TESTLIB_NAME,self.version) )
            print (u"上传数据失败原因：%s" % upload_pro_obj.get_error_string())
            return rc_request_status
        
        print(u"上传测试库(%s)版本(%s)依赖其他测试库版本配置数据成功" % (TESTLIB_NAME,self.version) )
        return REQUEST_PROCESS_SUC
    #------------------------------------------------------------ end
    
    
 
def pack():
    global PROJECT_HOME
    
    try:
        print("Welcome %s Packager!" % TESTLIB_NAME)
        
        #初始化是否向服务器更新测试库功能说明信息标志 #added by wangjun@20141202
        need_update_fun_desc = False
        
        # 设置版本
        user_input = raw_input("which kind of version do you want to compile?(d:Debug, b:Beta, s:Stable, default is s): ")
        if user_input.lower() == "b":
            version_type = "b"
        elif user_input.lower() == "d":
            version_type = "d"
        else:
            version_type = "s"
            
        # 选择是否上传打包后的文件到升级服务器上
        if version_type == "d":
            need_upload = False
            
        else:
            user_input = raw_input("Do you want to upload zip file to upgrade server?(y|n, default is n):")
            if user_input.lower() == "y":
                need_upload = True
            else:
                need_upload = False
        
        if need_upload:
            regex_ip = '^(2[0-4]\d|25[0-5]|[01]?\d\d?)\.((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){2}(2[0-4]\d|25[0-5]|[01]?\d\d?)$'
            
            while 1:
                user_input = raw_input("Please input upgrade server IP addr(default is 172.24.16.16):")
                if re.search(regex_ip, user_input) is not None:
                    LoadConfigCtrl.set_upgrade_server_addr_and_port(in_server_addr = user_input)
                    break
                
                elif user_input == "":
                    print(u"使用默认IP地址！")
                    LoadConfigCtrl.set_upgrade_server_addr_and_port(in_server_addr = "172.24.16.16")
                    break
                
                else:
                    print(u"IP 地址非法，请重新输入！\n")
                    
            #询问是否向服务器更新测试库功能说明信息 #added by wangjun@20141202
            user_input = raw_input("Do you want to update test lib function description to upgrade server?(y|n, default is n):")
            if user_input.lower() == "y":
                need_update_fun_desc = True
            else:
                need_update_fun_desc = False
        
        need_compile = True
        
        # 设置打包主目录
        main_dir = os.path.dirname(os.path.dirname(__file__))
        PROJECT_HOME = main_dir
        
        # 开始打包 #传入是否向服务器更新测试库功能说明信息标志 #added by wangjun@20141202
        compile_obj=CompileFiles(main_dir, version_type, need_compile, need_upload, need_update_fun_desc)
        compile_obj.main()
       
        print("\nExit %s Packager!" % TESTLIB_NAME)
        nExit = raw_input("Press any key to end...")
        
    except Exception, e:
        print e.message
        
    
    
if __name__ == '__main__':
    pack()
    

