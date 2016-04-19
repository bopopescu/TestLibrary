# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: HttpServerCache
#  class:
#       实现HttpServer库多实例对象管理
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
#         wangjun   2014.8.11    修改_clear_all_object_alias接口逻辑错误。
# ***************************************************************************


from robot.utils import ConnectionCache


#没有对象的异常类
class No_Remote_or_local_Exception(Exception):
    pass

class HttpServerCache():

    def __init__(self):
        """
        初始化cache需要的数据成员
        """
        self._cache = ConnectionCache()
        self.dict_alias = {}  

    def _switch_current_object(self, alias):
        """
        切换当前对象节点到别名关联的对象节点
        """
        return self._cache.switch(alias)  

    def _get_current_object(self):
        """
        获取当前对象节点
        """
        if not self._cache.current:
            raise No_Remote_or_local_Exception
            
        return self._cache.current
    
    def _register_alias(self, alias, port, remote_url):
        """
        保存别名对应的prot和remote_url数据
        """
        self.dict_alias[alias] = (port, remote_url)
        
    def _register_object(self, lib_handle, alias, port, remote_url ):
        """
        注册并保存别名对象句柄
        """
        tag = self._cache.register(lib_handle, alias)
        self._register_alias(alias, port, remote_url)
        return tag

    def _check_init_alias(self, alias, port, remote_url):
        """
        判断别名对象是否存在
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

    def _get_object_alias_list(self):
        """
        返回对接节点别名列表
        """
        return self.dict_alias.keys()
    
    
    def _clear_all_object_alias(self):
        """
        清除测试库中所有对象数据节点
        """
        for item_key in self.dict_alias.keys():
            item_handle = self.dict_alias.get(item_key)
            self.dict_alias[item_key] = None
            del item_handle
        
        #清空列表
        self.dict_alias.clear()
            