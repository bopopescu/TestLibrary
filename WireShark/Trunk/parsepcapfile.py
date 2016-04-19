#!/usr/bin/env python
# -*- coding: utf-8 -*-
try:
    from xml.etree import cElementTree as ET
except:
    from xml.etree import ElementTree as ET
import os
import sys
import re
import subprocess
import time

from initapp import ATTROBOT_TEMP_FILE_PAHT
import attcommonfun
import attlog as log
    
MAX_BLOCK_LEN           = 100   # 每次解析的最大包数量
MAX_EMPTY_XML_FILE_LEN  = 430L  # XML空文件的最大长度
MAX_EMPTY_PCAP_FILE_LEN = 260L  # PCAP空文件最大长度
MAX_TIME_OUT            = 600   # tshark.exe最长处理时间为10分钟
LIMIT_RETURN_LIST_LEN   = True  # 是否对返回的列表做限制
MAX_RETURN_LEN          = 100   # 返回用户查询结果列表的最大长度

PARSE_PCAP_FILE_S =  1    # 标志执行成功
PARSE_PCAP_FILE_F = -1    # 标志执行失败

class ParsePcapFile(object):
    
    def __init__(self, tshark_install_path, pcap_file_path):
        self.pcap_file_path      = pcap_file_path
        self.tshark_install_path = tshark_install_path
        self.wireshark_version   = None
        self.flag_version        = self._set_wireshark_version()      # 为1表示1.8版本；为1表示高于1.8版本；-1表示低于1.8版本，不支持

    def query_option_value(self, option_name_or_offset, read_filter, value_type="str_value"):
        """
        函数功能：查询所有包中指定字段值
        
        函数参数：
            option_name_or_offset   字段别名或偏移量    如：franme.num or frame[xx:xx]
            read_filter             读过滤器
            value_type              查找的结果类型str or byte
        
        返回值：list_data or None
        """
        ret         = PARSE_PCAP_FILE_S
        err_dta     = ""
        ret_data    = None
        option_type = None  # 默认为None代表按字段别名
        
        for i in [1]:
            
            if isinstance(option_name_or_offset, str) or\
               isinstance(option_name_or_offset, unicode):
                
                option_name_or_offset = option_name_or_offset.strip().lower()
                
            else:
                ret      = PARSE_PCAP_FILE_F
                err_data = u"输入 %s 的字段名或偏移量错误！" % option_name_or_offset
                break
            
            if not option_name_or_offset:
                ret      = PARSE_PCAP_FILE_F
                err_data = u"输入的字段名或偏移量不能为空！"
                break
            
            if isinstance(read_filter, str) or\
               isinstance(read_filter, unicode):
                
                read_filter = read_filter.strip()
            
            # 区分是按字段偏移量还是按字段名来取值
            if re.match('frame\[[0-9]+:[0-9]+\]', option_name_or_offset):
                option_type = "offset"
            else:
                # 对rtpevent协议做特殊处理，不进行过滤
                if read_filter and ("rtp" not in read_filter):
                    
                    if ("rtp" not in option_name_or_offset):
                        read_filter = "%s and %s" % (read_filter, option_name_or_offset) # 为了区分是读过滤错误还是字段名错误
                    else:
                        pass
                        
                elif "rtp" in option_name_or_offset:
                    read_filter = ""
                else:
                    read_filter = option_name_or_offset
            
            # 根据读过滤器生成新的pcap文件
            try:
                new_pcap_path = self._creat_new_pcap_file(self.pcap_file_path, read_filter)
            except Exception,e:
                err_data = u"生成新的pcap文件失败，详细信息：%s！" % e
                if ('tshark: "%s" is neither a field nor a protocol name.' % option_name_or_offset) in err_data:
                    pass
                else:
                    ret = PARSE_PCAP_FILE_F
                break
            
            try:
                ret_data = self._handle_pcap_file(new_pcap_path, option_name_or_offset, value_type)
            except Exception,e:
                ret      = PARSE_PCAP_FILE_F
                err_data = u"解析处理pcap文件失败，详细信息：%s！" % e
            
        if ret == PARSE_PCAP_FILE_F:
            log.user_err(err_data)
            raise RuntimeError(err_data)
        
        return ret_data
 
    def _run_cmd(self, cmd):
        """
        函数功能：运行cmd进程
        
        参数：
            cmd   cmd命令
            
        返回值：无
        """
        err_data = ""
        
        if cmd:
            popen_stdout_name  = "%s_popen_stdout.txt" % attcommonfun.get_time_stamp()
            popen_stdout_path  = os.path.join(ATTROBOT_TEMP_FILE_PAHT, popen_stdout_name)
            
            try:
                with open(popen_stdout_path, "w") as obj_file:
                    popen = subprocess.Popen(cmd,
                                             stdout=obj_file,
                                             stderr=obj_file,
                                             shell=True)
                
                # 判断经常是否运行完毕
                self._check_popen_run_over(popen)
                
                # 判断多进程是否执行成功
                self._check_popen_succeed(popen_stdout_path)
                
            except Exception,e:
                 # 针对异常中给出cmd命令中包含中文的错误信息！
                if hasattr(e, "start") and hasattr(e, "end"):
                    err_data = u"运行cmd命令失败，失败原因：参数 %s 非法(%s)！" % (cmd[e.start:e.end],e)
                else:
                    err_data = u"运行cmd命令失败，失败原因：%s" % e
        else:
            err_data = u"cmd命令不能为空！"
        
        if err_data:
            raise RuntimeError(err_data)
    
    def _check_popen_run_over(self, popen):
        """
        函数功能：判断popen是否执行完
        
        参数：
            popen  subprocess.Popen对象
        
        返回值：无
        """
        start_time = time.time()
        while popen.poll() == None:
            time.sleep(1)
            dif_time = time.time() - start_time
            if dif_time > MAX_TIME_OUT:
                raise RuntimeError(u"执行 %s 命令超时（超时时间 %ss）！" % (cmd, MAX_TIME_OUT))
        
    def _check_popen_succeed(self, file_path):
        """
        函数功能：检查多进程是否执行成功
        
        参数：
            file_path   多进程输出定向的文件
            
        返回值：
            ret         PARSE_PCAP_FILE_S为执行成功，PARSE_PCAP_FILE_F为执行失败
        """
        err_data = ""
        
        try:
            with open(file_path, "r") as obj_file:
                err_data = obj_file.read()
                if err_data:
                    err_data = err_data.decode(sys.getfilesystemencoding())
            try:
                os.remove(file_path)
            except Exception,e:
                pass
        except Exception,e:
            err_data = "%s" % e
        
        if err_data:
            raise RuntimeError(u"%s" % err_data)
    
    def check_file_empty(self, file_path):
        """
        函数功能：检查文件是否为空
        
        参数：
            file_path   被检查的文件全路径
            
        返回值：
            ret         PARSE_PCAP_FILE_S为不空，PARSE_PCAP_FILE_F为空
        """
        ret = PARSE_PCAP_FILE_F
            
        if isinstance(file_path, str) or\
           isinstance(file_path, unicode):
            
            file_path   = file_path.strip()
            file_suffix = os.path.splitext(file_path)[-1]
            
            if ".xml" == file_suffix:
                pass
            else:
                read_filter = "frame.number==1"   # 生成小的xml数据文件
                file_path = self._creat_xml_packet_file(file_path, read_filter)
                
            if self._check_xml_empty(file_path):
                ret = PARSE_PCAP_FILE_S
            try:
                os.remove(file_path)
            except Exception,e:
                pass  # 删除产生的临时文件
        else:
            raise RuntimeError(u"文件路径 %s 格式不合法" % file_path)
        
        return ret
    
    def _check_xml_empty(self, xml_file_path):
        """
        """
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
        
        # 对每个数据按字典格式包做解析
        list_packet_element = root.findall("packet")
        if len(list_packet_element) <= 0:
            return False
        else:
            return True
            
    def _creat_new_pcap_file(self, pcap_file_path, read_filter=""):
        """
        函数功能：通过tshark.exe在原pcap的基础上生成新的pcap文件
        
        参数：
            read_filter  读过滤器
        
        返回：
            file_path     经过过滤后的pcap文件路径
        """
        new_pcap_file_name = "%s_new_wireshark.pcap" % attcommonfun.get_time_stamp()
        new_pcap_file_path = os.path.join(ATTROBOT_TEMP_FILE_PAHT, new_pcap_file_name)
        
        if read_filter:
            if self.flag_version == 1:
                cmd = '"%s\\tshark.exe" -r "%s" -Y "%s" -w "%s"' % (self.tshark_install_path,
                                                                    pcap_file_path,
                                                                    read_filter,
                                                                    new_pcap_file_path)
            else:
                cmd = '"%s\\tshark.exe" -r "%s" -R "%s" -w "%s"' % (self.tshark_install_path,
                                                                    pcap_file_path,
                                                                    read_filter,
                                                                    new_pcap_file_path)
        else:
            cmd = '"%s\\tshark.exe" -r "%s" -w "%s"' % (self.tshark_install_path,
                                                        pcap_file_path,
                                                        new_pcap_file_path)
        self._run_cmd(cmd)
        
        return new_pcap_file_path

    def _creat_xml_packet_file(self, pcap_file, read_filter=""):
        """
        函数功能：根据抓到的pcap文件，生成xml格式的数据文件
        
        参数：
            pcap_file      抓包生成的pcap文件路径
            read_filter   读取过滤器
            
        返回值：
            xml_file_path  生成的xml文件路径
        """
        temp_xml_file_name = "%s_temp_wireshark.xml" % attcommonfun.get_time_stamp()
        temp_xml_file_path = os.path.join(ATTROBOT_TEMP_FILE_PAHT, temp_xml_file_name)
        
        if os.path.exists(temp_xml_file_path):
            os.remove(temp_xml_file_path)
            
        if read_filter:
            if self.flag_version == 1:
                cmd = '"%s\\tshark.exe" -r "%s" -Y "%s" -T "%s" -V>"%s"' % (self.tshark_install_path,
                                                                            pcap_file,
                                                                            read_filter,
                                                                            "pdml",
                                                                            temp_xml_file_path)
            else:
                cmd = '"%s\\tshark.exe" -r "%s" -R "%s" -T "%s" -V>"%s"' % (self.tshark_install_path,
                                                                            pcap_file,
                                                                            read_filter,
                                                                            "pdml",
                                                                            temp_xml_file_path)
        else:
            cmd = '"%s\\tshark.exe" -r "%s" -T "%s" -V>"%s"' % (self.tshark_install_path,
                                                                pcap_file,
                                                                "pdml",
                                                                temp_xml_file_path)
        self._run_cmd(cmd)
        
        return temp_xml_file_path
        
    def _parse_xml_file(self, xml_file_path):
        """
        函数功能：解析xml格式的数据文件
        """
        list_packet_data = []           # [{proto_name1:[{name1:xxx, showname1:xxxx}],
                                        #               [{name2:xxx, showname2:xxxx}],
                                        #   proto_name1:[{name:xxx, showname:xxxx}],
                                        #  },
                                        #  {proto_name1:[{name:xxx, showname:xxxx}],
                                        #   proto_name1:[{name:xxx, showname:xxxx}]
                                        #  }
                                        # ]
        
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
        
        # 对每个数据按字典格式包做解析
        list_packet_element = root.findall("packet")
        for packet in list_packet_element:
            dict_packet_data = self._parse_packet(packet)
            
            list_packet_data.append(dict_packet_data)
            
        return list_packet_data
        
    def _parse_packet(self, packet):
        """
        函数功能：解析单个数据包
        
        参数：packet  一个数据包的xml elemet对象
        
        返回：数据包的字典结构
        """
        dict_packet_data = {}
        list_proto_element = packet.findall("proto")
        for proto in list_proto_element:
            dict_packet_data.update(self._parse_proto(proto))
            
        return dict_packet_data
    
    def _parse_proto(self, proto):
        """
        函数功能：按数据包的协议解析proto字段内容
        
        参数： proto 数据包一个协议的xml element对象
        
        返回：一种协议数据的字典结构
        """
        dict_proto_data    = {}
        list_field_data    = []
        proto_name         = proto.attrib.get("name")
        # 对每个协议中的项做解析
        list_field_element = proto.iter()
        temp_value         = ""
        for field in list_field_element:
            dict_field_attrib = field.attrib
            dict_field_data   = {}
            
            # 获取字段的pos和size组建字段的偏移量
            frame_location = "frame[%s:%s]" % (dict_field_attrib.get("pos"),
                                               dict_field_attrib.get("size")
                                               )
            key         = (dict_field_attrib.get("name"), frame_location)
            temp_value += dict_field_attrib.get("value","")
            
            dict_field_data[key] = dict_field_attrib
            list_field_data.append(dict_field_data)
        
        # 把协议下面所有字段的value值添加到协议字段的数据中
        dict_data                   = list_field_data[0].values()[0]
        dict_data["value"]          = temp_value
        
        dict_proto_data[proto_name] = list_field_data
        
        return dict_proto_data

    def _handle_pcap_file(self, pcap_file_path, option_name_or_offset, value_type):
        """
        函数功能：处理pcpa_file文件
        
        参数：
            pcap_file_path  pcap文件路径
        """
        file_path   = pcap_file_path
        read_filter = ""
        ret_data    = []
        
        count       = 1   # 拆分pcap包的次数
        frame_start = 1   # 开始解析xml的包的序号
        
        while True:
            if self.check_file_empty(file_path) == PARSE_PCAP_FILE_S:
                
                frame_end     = count*MAX_BLOCK_LEN
            
                read_filter   = "frame.number>=%s and frame.number<=%s" % (frame_start, frame_end)
                xml_file_path = self._creat_xml_packet_file(pcap_file_path, read_filter)
                
                file_path     = xml_file_path
                frame_start   = frame_end+1
                
                list_packet_data = self._parse_xml_file(xml_file_path)
                temp_data        = self._get_option_value(list_packet_data,
                                                          option_name_or_offset,
                                                          value_type)
                
                if temp_data:
                    ret_data +=temp_data
                
                # 是否对返回值的长度做限制
                if LIMIT_RETURN_LIST_LEN and len(ret_data) >= MAX_RETURN_LEN:
                    ret_data = ret_data[:MAX_RETURN_LEN]
                    break
                
            else:
                break
            
            count += 1
        try:
            os.remove(pcap_file_path)
        except Exception,e:
            pass
        
        try:
            os.remove(file_path)
        except Exception,e:
            pass
        
        if not ret_data:
            ret_data = None
        
        return ret_data 

    def _get_option_value(self, list_packet_data, option_name_or_offset,value_type):
        """
        函数功能：按字段偏移量查询字段值
        
        参数：
            list_packet_data            数据包列表值
            option_name_or_offset       用户输入的字段偏名或移量
            value_type                  查找的结果类型str or ascii
        
        返回值： str_data or None
        """
        value     = None
        list_data = []
        
        # rtp.payload字段特殊，他的str和ascii相同，统一取ascii modified zsj 2013-12-27
        if option_name_or_offset == "rtp.payload":
            value_type = "ascii_value"
            
        for dict_packet_data in list_packet_data:
            for key, list_field_data in dict_packet_data.items():
                for dict_field_data in list_field_data:
                    for key, dict_data in dict_field_data.items():
                        if option_name_or_offset not in key:
                            continue
                        elif value_type == "str_value":
                            value = self._get_value(dict_data)
                            break
                        else:
                            value = dict_data.get("value")
                            break
                    else:
                        continue
                    break
                
            if value is not None:
                list_data.append(value)
                value = None #add 20140630  修改BUG  #添加后清空， 不然导致重复
            
        return list_data

    def _get_value(self, dict_field_data):
        """
        函数功能：返回指定字段的值，如果show字段存在返回show的值，没有返回showname中':'后面的值
        
        参数： dict_field_data  数据包中一个范围段内的字典数据结构
        
        返回：str_data
        """
        show      = dict_field_data.get("show", "")
        show_name = dict_field_data.get("showname", "")
        data      = ""
        
        if show:
            value = show
        else:
            value = show_name
        
        if ": " in value:               # ": "分号后面带空格的情况下做取空格后面的部分，其他情况不处理 zsj 2013/11/13
            list_data = value.split(": ")
            if len(list_data) > 1:
                data = list_data[-1]
            else:
                data = list_data[0]
        else:
            data = value
        
        return data
    
    def _set_wireshark_version(self):
        """
        """
        flag_version = 0
        warn_data    = ""
        
        if not self.wireshark_version:
            self.wireshark_version = self._get_wireshark_version()
        
        try:
            list_data = self.wireshark_version.split(".")
            version = int(list_data[1])
            if version > 8:
                flag_version = 1
            elif version < 8:
                flag_version = -1
                warn_data = u"WireShark软件版本为 %s 过低，请使用更高版本的WireShark版本，\
                            否则测试效果不好！" % self.wireshark_version
            elif version ==8:
                pass
            else:
                warn_data = u"判定WireShark库的版本信息 %s 不识别，将使用1.8.x版本做处理！\
                        错误信息：%s" % (self.wireshark_version, e)
                
        except Exception,e:
            warn_data = u"判定WireShark库的版本信息 %s 高低出错将使用1.8.x版本做处理！\
                        错误信息：%s" % (self.wireshark_version, e)
            
        if warn_data:
            log.user_warn(warn_data)
        
        return flag_version
    
    def _get_wireshark_version(self):
        """
        """
        ret               = PARSE_PCAP_FILE_F
        wireshark_version = None
        err_data          = ""
        
        if not self.wireshark_version:
            
            cmd = '"%s\\Tshark.exe" -h' % self.tshark_install_path
            
            try:  
                popen = subprocess.Popen(cmd,
                                         stdout=subprocess.PIPE,
                                         stderr=subprocess.PIPE,
                                         shell=True)
                data = popen.stdout.read()
                data = data.decode(sys.getfilesystemencoding())
                
                list_data = data.split(" ")
                if len(list_data)>1:
                    if re.match("\d+\.\d+\.\d+", list_data[1]):
                        wireshark_version = list_data[1]
                        ret = PARSE_PCAP_FILE_S
            except Exception,e:
                err_data = u"获取wireshark版本信息失败，失败原因：%s" % e
        else:
            ret = PARSE_PCAP_FILE_S
            wireshark_version = self.wireshark_version
            
        if ret == PARSE_PCAP_FILE_S:
            return wireshark_version
        
        elif not err_data:
            err_data = u"获取wireshark版本信息失败!"
            
        raise RuntimeError(err_data)
    
def test(wireshark_install_path):
    #tmp_path = r"c:\wireshark\wews.pcapng"
    tmp_path = r"c:\RTP\DTMF_20131218_172127_22000.pcap"  # tcp flow
    obj = ParsePcapFile(wireshark_install_path, tmp_path)
    str_value = obj.query_option_value("rtp.payload","")
    byte_value = obj.query_option_value("rtp.payload","", "ascii_value")
    pass
    #data = obj.wireshark_query_tcpflow()
    #print data
    
if __name__=="__main__":
    tmp_path = r"c:\program files\wireshark"
    #print 3333333333
    test(tmp_path)
    #test_nbns()