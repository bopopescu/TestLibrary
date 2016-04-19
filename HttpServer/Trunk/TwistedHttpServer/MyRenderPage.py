# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: MyRenderPage
#  class:
#       封装了基于twidted web框架request请求中GET/POST/PUT接口实现
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
# ***************************************************************************


from twisted.web import http
from twisted.web import resource
import mimetypes

import os
import sys
import re
import shutil
import time
import posixpath
import urllib
import cgi
import platform
import copy


import MyChars



#加载StringIO模块
g_import_stringio_type=0
try:
    from cStringIO import StringIO
    g_import_stringio_type=1
except ImportError:
    from StringIO import StringIO
    g_import_stringio_type=2


    
#格式化长度单位
def sizeof_fmt(num):
    for x in ['bytes','KB','MB','GB']:
        if num < 1024.0:
            return "%3.1f%s" % (num, x)
        num /= 1024.0
    return "%3.1f%s" % (num, 'TB')


#返回一个时间数据
def modification_date(filename):
    return time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(os.path.getmtime(filename)))

      
            
class MyRenderPage(resource.Resource):
    
    if not mimetypes.inited:
        mimetypes.init() #try to read system mime.types
        
    extensions_map = mimetypes.types_map.copy()
    extensions_map.update({'': 'application/octet-stream', # Default
                        '.py': 'text/plain',
                        '.c': 'text/plain',
                        '.h': 'text/plain',
                        })
    
    def __init__(self, in_home_workspace_dir):

        resource.Resource.__init__(self)

        #将路径转为系统默认编码 #modify by wangjun 20131224
        if isinstance(in_home_workspace_dir, unicode):
            in_home_workspace_dir = in_home_workspace_dir.encode("utf8")

        self.home_workspace_dir=in_home_workspace_dir


    def __del__(self):
        pass
        
        
    def render_GET(self, request):
        """
        GET响应接口
        """
        f=self.deal_get_data(request)
        
        if f:
            self.wirte_result_data(f, request)
            f.close()
   

    def render_POST(self, request):
        """
        POST响应接口
        """
        r, info = self.deal_post_data(request)
        
        f = StringIO()
        f.write('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">')
        f.write('<html>\n<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>\n<title>Upload Result Page</title>\n')
        f.write('<body>\n<h2>Upload Result Page</h2>\n')
        f.write('<hr>\n')
        if r:
            f.write("<strong>Success:</strong>")
        else:
            f.write("<strong>Failed:</strong>")
        f.write(MyChars.build_value_type_unicode_to_string(info))
        f.write("<br><a href=\"%s\">back</a>" % request.getHeader('referer'))
        f.write("<hr><small>Powered By: bones7456, check new version at ")
        f.write("<a href=\"http://li2z.cn/?s=SimpleHTTPServerWithUpload\">")
        f.write("here</a>.</small></body>\n</html>\n")
        length = f.tell()
        f.seek(0)

        request.setResponseCode(200)
        request.setHeader("Content-type", "text/html; charset=utf-8")
        request.setHeader("Content-Length", str(length))
        
        if f:
            self.wirte_result_data(f, request)
            f.close()
        
        
    def render_PUT(self, request):
        """
        PUT响应接口
        """
        r, info = self.deal_put_data(request)
        
        f = StringIO()
        f.seek(0)
        f.write(MyChars.build_value_type_unicode_to_string(info))
        
        request.setResponseCode(200)
        request.setHeader("Content-Length", 0)
        
        if f:
            self.wirte_result_data(f, request)
            f.close()
            
            
    def deal_get_data(self, request):
        """
        GET方法数据处理方法
        """
        
        #获取文件地址信息
        self.path=request.path
        path = self.translate_path(self.path, request)
        f = None
        
        #转化编码格式
        path = MyChars.convert_coding(path)
        
        if os.path.isdir(path):    
            
            if not self.path.endswith('/'):
                
                #重定向浏览器
                request.setResponseCode(301)
                request.setHeader("Location", self.path + "/")
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_NO_PERMISSION_TO_LIST_DIRECTORY)                
                request.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
                request.finish()
                return None
            
            #文件地址下是否存在index HTML文件
            for index in "index.html", "index.htm":
                index = os.path.join(path, index)
                if os.path.exists(index):
                    path = index
                    break
            else:
                #创建一个以目录列表文件为数据来源的HTML文件，并将数据流句柄做为返回值
                return self.list_directory(path,request)
        
        #获取文件类型，获取到的数据用于MIME Content-type头
        ctype = self.guess_type(path)
        
        #初始化f文件句柄
        try:
            f = open(path, 'rb')
            
        except IOError:
            request.setResponseCode(http.NOT_FOUND)
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_404_ERROR)
            request.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            request.finish()
            return None
        
        #获取文件的大小,以位为单位
        fs = os.fstat(f.fileno())
        
        request.setResponseCode(200)
        request.setHeader("Content-type", "%s; charset=utf-8" % ctype)
        request.setHeader("Content-Length", str(fs[6]))
        
        last_modified_data=time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(fs.st_mtime))
        request.setHeader("Last-Modified", last_modified_data)

        return f
    
    
    def deal_post_data(self, request):
        """
        POST方法数据处理方法
        
        ++++++++++++++++++++++++++++++++++++++++++++
        数据内容格式：
        
        ""
        -----------------------------7dd17727d02ae--
        Content-Disposition: form-data; name="file"; filename="C:\test.txt"\r\n
        Content-Type: text/plain\r\n
        \r\n
        要上传的数据流
        -----------------------------7dd17727d02ae--
        ""

        ++++++++++++++++++++++++++++++++++++++++++++
        """

        #获取content-type头
        contenttype=request.getHeader('content-type')
        boundary=None
        if contenttype:
            boundary = contenttype.split("=")[1]
        
        #获取content-length头
        remainbytes = int(request.getHeader('content-length'))

        #数据以boundary开头
        line = request.content.readline()
        remainbytes -= len(line)
        if not boundary or not boundary in line:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_POST_CONTENT_NOT_BEGIN_WITH_BOUNDAR)
            return (False, rsp_string_data)

        #获取Content-Disposition数据内容
        line = request.content.readline()
        remainbytes -= len(line)
        fn = re.findall(r'Content-Disposition.*name="file"; filename="(.*)"', line)
        if not fn:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_CAN_NOT_FINE_OUT_FILENAME)
            return (False, rsp_string_data)
        
        #获取文件名字和存放路径
        self.path=request.path
        path = self.translate_path(self.path,request)
        osType = platform.system()
        filedir,cfilename = os.path.split(fn[0])
        filename = cfilename
        try:
            if osType == "Linux":
                fn = os.path.join(path, fn[0].decode('gbk').encode('utf-8'))
            else:
                fn = os.path.join(path, filename)
                
        except Exception, e:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_FILENAME_ERROR)
            return (False, rsp_string_data)
        
        #如果文件已经存在则文件名加'_'
        while os.path.exists(fn):
            fn += "_"

        #获取Content-Type数据内容
        line = request.content.readline()
        remainbytes -= len(line)
        line = request.content.readline()
        remainbytes -= len(line)
        
        try:
            #转换文件名编码为utf-8 
            fn = MyChars.convert_coding(fn) #add by wangjun 20131224
            
            #打开文件
            out = open(fn, 'wb')

        except Exception,e:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_CAN_NOT_WRITE_FILE)
            return (False, rsp_string_data)

        #开始保存请求上传的数据
        preline = request.content.readline()
        remainbytes -= len(preline)
        
        while remainbytes > 0:

            line = request.content.readline()
            remainbytes -= len(line)
            
            if boundary in line:
                preline = preline[0:-1]
                if preline.endswith('\r'):
                    preline = preline[0:-1]
                out.write(preline)
                out.close()
                
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_UPLOAD_FILE_SUCCESS)
                return (True, rsp_string_data % fn)
        
            else:
                out.write(preline)
                preline = line
        
        rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_UNEXPECT_ENDS_OF_DATA)
        return (False, rsp_string_data)
    
         
    def deal_put_data(self, request):
        """
        PUT方法数据处理方法
        """
        
        #获取content-length头
        remainbytes = int(request.getHeader('content-length'))
        
        #获取文件名字和存放路径
        self.path=request.path
        path = self.translate_path(self.path,request)
        
        osType = platform.system()
        try:
            if osType == "Linux":
                fn = os.path.join(path, fn[0].decode('gbk').encode('utf-8'))
            else:
               fn = path
               
        except Exception, e:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_FILENAME_ERROR)
            return (False, rsp_string_data)

        try:
            #转换文件名编码为系统编码
            fn = MyChars.convert_coding(fn) #add by wangjun 20131224
            
            #打开文件    
            out = open(fn, 'wb')
                
        except Exception,e:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_CAN_NOT_WRITE_FILE)
            return (False, rsp_string_data)
        
        #开始保存请求上传的数据
        while remainbytes > 0:
            preline = request.content.readline()
            remainbytes -= len(preline)

            if preline.endswith('\r'):
                preline = preline[0:-1]
                
            out.write(preline)
            
        out.close()
        
        rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_UPLOAD_FILE_SUCCESS)        
        return (True, rsp_string_data % fn)
    
    

    def list_directory(self, path, request):
        """
        创建一个以目录列表文件为数据来源的HTML文件，并将数据流句柄做为返回值
        """
        try:
            list_dir_data = os.listdir(path)
            
        except os.error:
            request.setResponseCode(http.NOT_FOUND)
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_NO_PERMISSION_TO_LIST_DIRECTORY)
            request.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
            request.finish()
            return None
        
        #排序文件列表
        list_dir_data.sort(key=lambda a: a.lower())
        
        #构建HTML文件
        f = StringIO()
        displaypath = cgi.escape(urllib.unquote(self.path))
        
        #add by wangjun 20131224
        displaypath_string = MyChars.convert_coding(displaypath)
        if isinstance(displaypath_string, unicode):
            displaypath_string = displaypath_string.encode("utf8")
        
        #写HTML TITLE数据
        f.write('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">')
        f.write('<html>\n<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>\n<title>Directory listing for %s</title>\n' % displaypath_string)
        f.write('<body>\n<h2>Directory listing for %s</h2>\n' % displaypath_string)
        f.write('<hr>\n')
        
        """
        #写HTML表单数据(upload)
        f.write("<form ENCTYPE=\"multipart/form-data\" method=\"post\">")
        f.write("<input name=\"file\" type=\"file\"/>")
        f.write("<input type=\"submit\" value=\"upload\"/>")
        f.write("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp")
        f.write("<input type=\"button\" value=\"HomePage\" onClick=\"location='/'\">")
        f.write("</form>\n")
        
        f.write("<hr>\n<ul>\n")
        """
        
        #写文件列表数据
        #这里数据节点的数据全部为str类型
        for name in list_dir_data:
            
            try:
                fullname = os.path.join(path, name)
                
                #获取文件是否文件夹属性
                temp_isdir_flag = os.path.isdir(fullname)
                #获取文件是否连接的属性
                temp_islink_flag = os.path.islink(fullname)
                
                #转换编码格式
                if isinstance(name, unicode):
                    name = name.encode("utf8")
                
                #[step-1]
                temp_workspace_dir = MyChars.convert_coding(self.home_workspace_dir)
                if isinstance(temp_workspace_dir, unicode):
                    temp_workspace_dir = temp_workspace_dir.encode("utf8")
                    
                filename =  temp_workspace_dir + '/' + displaypath + name
                
                #转化编码格式
                filename = MyChars.convert_coding(filename)
                                
                #获取文件长度
                file_size=sizeof_fmt(os.path.getsize(filename))
                
                #获取文件修改日期
                modif_date=modification_date(filename)
                
                #[step-2]
                colorName=name
                linkname=name
    
                #追加文件和连接
                if temp_isdir_flag:
                    colorName = '<span style="background-color: #CEFFCE;">' + name + '/</span>'
                    linkname = name + "/"
    
                if temp_islink_flag:
                    colorName = '<span style="background-color: #FFBFFF;">' + name + '@</span>'
                
                #文件显示名称
                if isinstance(colorName, unicode):
                    colorName = colorName.encode("utf8")
    
                #文件或文件夹连接地址
                url_item=urllib.quote(copy.deepcopy(linkname))
                
                #将数据写入到HTML数据体中
                f.write('<table><tr><td width="60%%"><a href="%s">%s</a></td><td width="20%%">%s</td><td width="20%%">%s</td></tr>\n'
                        % (url_item, colorName, file_size, modif_date) )
            
            except Exception,e:
                log.debug_info(u"MyRenderPage:list_directory coding error")
                
                
        #写HTML结束数据    
        f.write("</table>\n<hr>\n</body>\n</html>\n")
        length = f.tell()
        f.seek(0)

        request.setResponseCode(200)
        request.setHeader("Content-type", "text/html; charset=utf-8")
        request.setHeader("Content-Length", str(length))
        
        return f
    

    def translate_path(self, path, request):
        """
        分隔路径的本地文件名
        """
        path = path.split('?',1)[0]
        path = path.split('#',1)[0]
        path = posixpath.normpath(urllib.unquote(path))

        words = path.split('/')
        words = filter(None, words)
        path = self.home_workspace_dir
        
        for word in words:
            drive, word = os.path.splitdrive(word)
            head, word = os.path.split(word)
            if word in (os.curdir, os.pardir): continue
            path = os.path.join(path, word)
            
        return path
    

    def wirte_result_data(self, source, request):
        """
        填充数据内容，并发送
        """
        try:
            if isinstance(source, file):
              request.write(MyChars.build_value_type_unicode_to_string(source.read()))
              
            else:
                global g_import_stringio_type
                
                type_string=str(type(source))
                #print type_string
                
                if type_string.find(".StringO"):
                    request.write(MyChars.build_value_type_unicode_to_string(source.getvalue())) 
                else:
                    rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_READ_VALUE_ERROR)
                    request.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
                
        except Exception,e:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_RENDER_ERROR_READ_VALUE_ERROR)
            request.write(MyChars.build_value_type_unicode_to_string(rsp_string_data))
        
        finally:
            request.finish()
        
    
    def guess_type(self, path):
        """
        获取文件类型，获取到的数据可用于MIME Content-type头，格式为type/subtype
        """
        base, ext = posixpath.splitext(path)
        if ext in self.extensions_map:
            return self.extensions_map[ext]
        ext = ext.lower()
        if ext in self.extensions_map:
            return self.extensions_map[ext]
        else:
            return self.extensions_map['']

