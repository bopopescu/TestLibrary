# -*- coding: utf-8 -*-

import os
import time

#定义基础库的属性KEY值
TEST_LIB_PROPERTY_NAME="name"
TEST_LIB_PROPERTY_ALIAS="alias"
TEST_LIB_PROPERTY_REMOTE_FLAG="remote_flag"

# 定义基础库库打包版本时需要的版本配置信息
MAJOR_VERSION_NUMBER = 1
MINOR_VERSION_NUMBER = 0
REVISION_NUMBER = 4

# 框架加载测试库接口包版本标示 #详见发布的框架版本LOAD_PLUGIN_VERSION属性数据
BASE_PLATFORM_LOAD_PLUGIN_VERSION = "v.plugin.svn3860"



class WireSharkProperty():

    @staticmethod  
    def _get_test_lib_property():
        """
        返回库的基本属性
        """
        return {TEST_LIB_PROPERTY_NAME:"WireShark",
                TEST_LIB_PROPERTY_ALIAS:"",
                TEST_LIB_PROPERTY_REMOTE_FLAG:True}
    
    
    @staticmethod  
    def _get_cfg_test_lib_version_property(testlib_version_type_is_bete_flag):
        """
        返回测试库打包版本时需要的版本配置信息
        """
        return MAJOR_VERSION_NUMBER,\
                MINOR_VERSION_NUMBER,\
                REVISION_NUMBER,\
                BASE_PLATFORM_LOAD_PLUGIN_VERSION


    @staticmethod  
    def _get_test_lib_pack_version():
        """
        返回基础库版本号
        """
        #加载获取测试库版本信息接口模块
        import os
        from loadpluginproperty.TestLibraryBaseProperty import TestLibraryBaseProperty
        
        #当前测试库代码路径
        in_testlib_folder_abspath = os.path.abspath(os.path.dirname(__file__))
        return TestLibraryBaseProperty.static_get_testlib_release_version(in_testlib_folder_abspath)
        
        
    @staticmethod  
    def _get_test_lib_Legitimacy_Detection(class_object_handle,
                                           current_platform_version,
                                           current_platform_load_plugin_version):
        """
        检测版本基础库在当前平台版本是否合法
        """
        #加载获取测试库版本信息接口模块
        import os
        from loadpluginproperty.TestLibraryBaseProperty import TestLibraryBaseProperty

        #当前测试库代码路径
        in_testlib_folder_abspath = os.path.abspath(os.path.dirname(__file__))
        return TestLibraryBaseProperty.static_get_test_lib_Legitimacy_Detection(in_testlib_folder_abspath,
                                                                                class_object_handle,
                                                                                current_platform_version,
                                                                                current_platform_load_plugin_version)
    
    
    @staticmethod
    def _clear_test_lib_resources(**kwargs):
        """
        清空和释放库的一些资源文件
        """
        try:
            KillTshark.close_all_tshark()
        except Exception,e:
            pass    
    
    
    @staticmethod
    def _init_test_lib_resources():
        """
        初始化库的一些资源
        """
        pass
        #TODO
        
class KillTshark(object):
    """
    """
    @staticmethod
    def close_all_tshark():
        """
        """
        try:
            from initapp import ATTROBOT_TEMP_FILE_PAHT
        except:
            return
        
        list_cmd_pid = []
        
        cmd_pid_with_tshark_path = os.path.join(ATTROBOT_TEMP_FILE_PAHT, "cmd_pid_with_tshark.txt")
        with open(cmd_pid_with_tshark_path,"r") as file_obj:
            file_data = file_obj.read()
            list_cmd_pid = file_data.split("\n")

        time.sleep(0.5)
        try:
            os.remove(cmd_pid_with_tshark_path)
        except:
            pass
        KillTshark._kill_process(list_cmd_pid)
        
    @staticmethod            
    def _kill_process(list_pid):
        """
        """
        try:
            import attcommonfun
        except:
            return
        
        for parent_pid in [pid for pid in list_pid if pid]:
            try:
                parent_pid = int(parent_pid)
            except:
                continue
            ret, data = attcommonfun.get_process_children(parent_pid)
            if ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
                dict_process = data
                for process_pid, process_name in dict_process.items():
                    if process_name.lower() == "tshark.exe":
                        try:
                            os.kill(process_pid, 9)
                        except:
                            pass             
            else:
                pass
            
            try:
                os.kill(parent_pid, 9)
            except:
                pass