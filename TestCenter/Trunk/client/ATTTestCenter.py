#coding:utf-8

# /*************************************************************************
#  Copyright (C), 2013-2014, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: ATTTestCenter
#  function: Providing interface to control testcenter
#
#  Author: ATT development group
#  version: V1.0
#  date: 2013.02.27
#  change log:
#  lana     20130227    created
#  lana     2013-12-23   添加编码转换函数，将底层返回的字符串转换成unicode编码
#
# ***************************************************************************


import os
import sys
import time
import Tkinter
from Tkinter import *


ATT_TESTCENTER_SUC = 0
ATT_TESTCENTER_FAIL = -1


class ATTTestCenter(object):

    """
    ATTTestCenter class
    """

    def __init__(self):
        """
        初始化 tcl/tk 解释器，加载tcl文件
        """

        # 初始化TCL/TK解释器对象
        self.tcl = Tkinter.Tcl()
        self.tcl_ret = ""

        try:
            file_path = os.path.abspath(__file__)

            # 加载tbcload库
            tbclib_path = os.path.join(os.path.dirname
                                      (os.path.dirname
                                      (os.path.dirname
                                      (os.path.dirname(file_path)))), "vendor", "tcl", "lib", "tcl8.5", "tbcload1.7", "tbcload17.dll" )
            tbclib_path = tbclib_path.replace("\\", '/')
            cmd = 'load {%s}' % tbclib_path
            self.tcl_ret = self.tcl.eval(cmd)

            # 获取要调用的tcl文件的全路径
            file_dir = os.path.dirname(file_path)
            file_path = os.path.join(file_dir, 'ATTTestCenter.tcl')
            if not os.path.exists(file_path):
                file_path = os.path.join(file_dir, 'ATTTestCenter.tbc')

            # source tcl文件
            cmd ='source {%s}' % file_path
            self.tcl_ret = self.tcl.eval(cmd)
        except Exception,e:
            print "加载tcl包发生异常.错误信息为：%s" % e


    def _check_server_is_start(self):
        """
        功能描述：通过向xmlrpc server发送一个请求，检查xmlrpc server端是否已经成功开启
        """

        n_ret = ATT_TESTCENTER_SUC    # 执行结果：SUC or FAIL
        str_ret = ""                  # 执行结果信息
        useless = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::CheckServerIsStart %s"  % useless

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def _convert_coding(self, string):
        """
        功能描述：将string的编码转换成unicode编码

        参数： string: 原始字符串

        返回值： ret_str: unicode编码的字符串
        """

        try:
            import chardet
            ret_data = chardet.detect(string)
            str_encoding = ret_data.get('encoding')
        except Exception, e:
            print u"获取字符串编码失败，错误信息为:%s" % e

        if not isinstance(string, unicode):
            ret_str = string.decode(str_encoding)
        else:
            ret_str = string

        return ret_str


    def testcenter_set_remote_url(self, remote_url):
        """
        功能描述：设置TestCenter远端库的url

        参数： remote_url: 表示TestCenter远端库的url,格式为http://ip:port
        """

        n_ret = ATT_TESTCENTER_SUC    # 执行结果：SUC or FAIL
        str_ret = ""                  # 执行结果信息

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::SetURL %s"  % remote_url

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_connect(self, chassis_addr):
        """
        功能描述：使用TestCenter机框IP地址连接TestCenter

        参数： chassis_addr: TestCenter机框IP地址
        """

        n_ret = ATT_TESTCENTER_SUC    # 执行结果：SUC or FAIL
        str_ret = ""                  # 执行结果信息

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::ConnectChassis %s"  % chassis_addr

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_reserve_port(self, port_name, port_location, port_type='Ethernet'):
        """
        功能描述：预约端口，需要指明端口的别名和端口的位置

        参数：
            port_name: 端口别名，用于后面对该端口进行其他操作
            port_location: 端口的位置，格式为"板卡号/端口号",例如预约板卡1上的1号端口："1/1"
            port_type: 端口类型，默认为Ethernet(暂时只支持Ethernet)
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::ReservePort %s %s %s"  % (port_location, port_name, port_type)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_config_port(self, port_name, dict_args):
        """
        功能描述：配置端口属性

        参数：
            port_name: 端口的别名，必须是预约端口时指定的名字
            dict_args: 表示可选参数字典,具体参数描述如下：
               media_type: 表示端口介质类型，取值范围为COPPER、FIBER。默认为COPPER
               link_speed: 表示端口速率，取值范围为10M,100M,1G,10G,AUTO。默认为AUTO
               duplex_mode:表示端口的双工模式，取值范围为FULL、HALF。默认为FULL
               auto_neg:   表示是否开始端口的自动协商模式，取值范围为Enable、Disable。
                            当设置为Enable时，link_speed和duplex_mode两个参数的设置无效。默认为Enable
               flow_control: 表示是否开启端口的流控功能，取值范围为ON、OFF。默认为OFF
               mtu_size:     表示端口的MTU。默认为1500
               master_or_slave: 表示自协商模式，取值范围为MASTER,SLAVE。
                                只有当auto_neg为Enable时，该参数才有效。默认为MASTER
               port_mode: 仅当link_speed为10G时,该参数才有效，取值范围为LAN、WAN。默认为LAN
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::ConfigPort %s " % port_name

            # check user input args
            for var in tmp_dict.keys():

                if var == "media_type":
                    cmd = "%s -mediaType %s" % (cmd, tmp_dict[var])

                elif var == "link_speed":
                    cmd = "%s -linkSpeed %s" % (cmd, tmp_dict[var])

                elif var == "duplex_mode":
                    cmd = "%s -duplexMode %s" % (cmd, tmp_dict[var])

                elif var == "auto_neg":
                    cmd = "%s -autoNeg %s" % (cmd, tmp_dict[var])

                elif var == "flow_control":
                    cmd = "%s -flowControl %s" % (cmd, tmp_dict[var])

                elif var == "mtu_size":
                    cmd = "%s -mtuSize %s" % (cmd, tmp_dict[var])

                elif var == "master_or_slave":
                    cmd = "%s -autoNegotiationMasterSlave %s" % (cmd, tmp_dict[var])

                elif var == "port_mode":
                    cmd = "%s -portMode %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_config_port fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_get_port_state(self, port_name, option):
        """
        功能描述：获取端口属性的状态

        参数：
               port_name: 端口的别名，必须是预约端口时指定的名字
               option:  要获取状态的端口属性项，取值范围为PhyState, LinkState, LinkSpeed, DuplexMode
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        state = ""                  # 用于存储端口属性的状态

        try:

            # build TCL Command
            cmd = "::ATTTestCenter::GetPortState %s %s"  % (port_name, option)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {value} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                state = self.tcl_ret.split(' ', 2)[1]
                str_ret = self.tcl_ret.split(' ', 2)[2].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret, state


    def testcenter_create_profile(self, port_name, profile_name, dict_args):
        """
        功能描述：在指定端口创建profile, 设置发流时的特性参数

        参数：
            port_name: 端口的别名，必须是预约端口时指定的名字
            profile_name: profile的别名，该名字可用于后面对profile的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                data_type: 数据流的类型，是持续的还是突发的，取值范围constant/burst，默认为constant
                traffic_load: 流量的负荷（结合流量的单位来设置），默认为10
                traffic_load_unit: 流量的单位，取值范围fps/kbps/mbps/percent，默认为percent
                burst_size: 当data_type是burst时，连续发送的报文数量，默认为1
                frame_num: 一次发送报文的数量（如果data_type为burst，应设置为 burst_size 的整数倍），默认为100
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateProfile %s %s  " % (port_name, profile_name )

            # check user input args
            for var in tmp_dict.keys():

                if var == "data_type":
                    cmd = "%s -Type %s" % (cmd, tmp_dict[var])

                elif var == "traffic_load":
                    cmd = "%s -TrafficLoad %s" % (cmd, tmp_dict[var])

                elif var == "traffic_load_unit":
                    cmd = "%s -TrafficLoadUnit %s" % (cmd, tmp_dict[var])

                elif var == "burst_size":
                    cmd = "%s -BurstSize %s" % (cmd, tmp_dict[var])

                elif var == "frame_num":
                    cmd = "%s -FrameNum %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_profile fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_empty_stream(self, port_name, stream_name, dict_args):
        """
        功能描述：创建空流，仅创建流的名字，帧数据长度等属性，流的其他属性通过
                  ADD PDU的方式构造

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                frame_len: 指明数据帧长度，单位为byte，默认为128
                frame_len_mode: 指明数据帧长度的变化方式，取值范围为：AUTO | DECR | FIXED | IMIX | INCR | RANDOM
                                参数设置为random时，随机变化范围为:( frame_len至frame_len + frame_len_count-1)
                                默认为fixed
                frame_len_step: 表示数据帧长度的变化步长，默认为1
                frame_len_count: 表示数据帧长度的数量，默认为1
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
                fill_type: 指明Payload的填充方式，取值范围为CONSTANT | INCR |DECR | PRBS，默认为CONSTANT
                constant_fill_pattern: 当FillType为Constant的时候，相应的填充值。格式是十六进制，取值范围为0x0到0xffff,默认为0x0
                enable_fcserror_insertion: 指明是否插入CRC错误帧，取值范围为: true | false，默认为false
                insert_signature: 指明是否在数据流中插入signature field，取值：true | false  默认为true，插入signature field
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s "  % (port_name, stream_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "frame_len_mode":
                    cmd = "%s -frameLenMode %s" % (cmd, tmp_dict[var].upper())

                elif var == "frame_len_step":
                    cmd = "%s -frameLenStep %s" % (cmd, tmp_dict[var])

                elif var == "frame_len_count":
                    cmd = "%s -frameLenCount %s" % (cmd, tmp_dict[var])

                elif var == "insert_signature":
                    cmd = "%s -insertSignature %s" % (cmd, tmp_dict[var])

                elif var == "fill_type":
                    cmd = "%s -fillType %s" % (cmd, tmp_dict[var].upper())

                elif var == "constant_fill_pattern":
                    cmd = "%s -constantFillPattern %s" % (cmd, tmp_dict[var])

                elif var == "enable_fcserror_insertion":
                    cmd = "%s -enableFcsErrorInsertion %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_empty_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_ethernet_header(self, header_name, src_mac, dst_mac, dict_args):
        """
        功能描述：创建Ethernet报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            src_mac: 表示源MAC
            dst_mac: 表示目的MAC
            dict_args: 表示可选参数字典,具体参数描述如下：
                sa_repeat_mode: 表示源MAC的变化方式，fixed | incr | decr，默认为fixed
                sa_step: 表示源MAC的变化步长，默认为00:00:00:00:00:01
                da_repeat_mode: 表示目的MAC的变化方式，fixed | incr | decr，默认为fixed
                da_step: 表示目的MAC的变化步长，默认为00:00:00:00:00:01
                num_da: 表示变化的目的MAC数量，默认为1
                num_sa: 表示变化的源MAC数量，默认为1
                eth_type: 表示以太网类型，默认值为auto，即此字段自动与添加的协议头相匹配
                eth_type_mode: 表示eth_type变化的方式，fixed | incr | decr，默认为fixed
                eth_type_step: 表示eth_type变化的步长，默认为1
                eth_type_count: 表示eth_type的数量，默认为1


        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s Eth -DA %s -SA %s "  % (header_name, dst_mac, src_mac)

            # check user input args
            for var in tmp_dict.keys():

                if var == "sa_repeat_mode":
                    cmd = "%s -saRepeatCounter %s" % (cmd, tmp_dict[var])

                elif var == "sa_step":
                    cmd = "%s -saStep %s" % (cmd, tmp_dict[var])

                elif var == "da_repeat_mode":
                    cmd = "%s -daRepeatCounter %s" % (cmd, tmp_dict[var])

                elif var == "da_step":
                    cmd = "%s -daStep %s" % (cmd, tmp_dict[var])

                elif var == "num_da":
                    cmd = "%s -numDA %s" % (cmd, tmp_dict[var])

                elif var == "num_sa":
                    cmd = "%s -numSA %s" % (cmd, tmp_dict[var])

                elif var == "eth_type":
                    # 去掉十六进制的“0x”前缀
                    if tmp_dict[var].find("0x") != -1:
                        tmp_dict[var] = tmp_dict[var][2:]
                    cmd = "%s -ethtype %s" % (cmd, tmp_dict[var])

                elif var == "eth_type_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -ethtypemode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -ethtypemode decrement" % cmd
                    else:
                        cmd = "%s -ethtypemode %s" % (cmd, tmp_dict[var])

                elif var == "eth_type_step":
                    cmd = "%s -ethtypestep %s" % (cmd, tmp_dict[var])

                elif var == "eth_type_count":
                    cmd = "%s -ethtypecount %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_ethernet_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd


        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_vlan_header(self, header_name, vlan_id, dict_args):
        """
        功能描述：创建vlan报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            vlan_id: 表示Vlan值
            dict_args: 表示可选参数字典,具体参数描述如下：
                user_priority: 表示用户优先级，取值范围为0-7，默认为0
                cfi: 表示Cfi值，默认为0
                mode: 表示Vlan值的变化方式 fixed | incr | decr，默认为fixed
                repeat: 表示Vlan变化数量，默认为1
                step: 表示Vlan变化步长，取值必须是2的幂，默认为1
                maskval: 表示vlan的掩码，默认为"FFF"
                protocol_tagId: 表示TPID,取值8100、9100等16进制数值，默认为8100
                vlan_stack: 表示Vlan的多层标签，Single/Multiple 如 -Vlanstack Single，默认为Single
                stack: 表示属于多层标签的哪一层，默认为1

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s Vlan -vlanId %s "  % (header_name, vlan_id)

            # check user input args
            for var in tmp_dict.keys():

                if var == "user_priority":
                    cmd = "%s -userPriority %s" % (cmd, tmp_dict[var])

                elif var == "cfi":
                    cmd = "%s -cfi %s" % (cmd, tmp_dict[var])

                elif var == "mode":
                    cmd = "%s -mode %s" % (cmd, tmp_dict[var])

                elif var == "repeat":
                    cmd = "%s -repeat %s" % (cmd, tmp_dict[var])

                elif var == "step":
                    cmd = "%s -step %s" % (cmd, tmp_dict[var])

                elif var == "maskval":
                    if "0x" not in tmp_dict[var]:
                        tmp_value = "0x" + tmp_dict[var]
                    else:
                        tmp_value = tmp_dict[var]
                    cmd = "%s -maskval %s" % (cmd, tmp_value)

                elif var == "protocol_tagId":
                    cmd = "%s -protocolTagId %s" % (cmd, tmp_dict[var])

                elif var == "vlan_stack":
                    cmd = "%s -Vlanstack %s" % (cmd, tmp_dict[var])

                elif var == "stack":
                    cmd = "%s -Stack %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_vlan_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_ipv4_header(self, header_name, src_ip, dst_ip, dict_args):
        """
        功能描述：创建IPV4报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            src_ip: 表示源IP
            dst_ip: 表示目的IP
            dict_args: 表示可选参数字典,具体参数描述如下：
                precedence: 表示Tos中的优先转发，取值范围0-7，默认为0
                delay: 表示Tos的最小时延，取值normal、low，默认为normal，注意该参数与throughput,reliability和cost四个参数只有一个可以设置为非normal.
                throughput: 表示Tos的最大吞吐量，取值normal，High，默认为normal
                reliability: 表示Tos的最佳可靠性，取值normal，High，默认为normal
                cost: 表示Tos的最小开销，取值normal，Low，默认为normal
                identifier: 表示数据报标记，默认为0
                total_length: 表示IP数据包的总长度，默认为46
                length_override: 表示长度是否自定义，取值True，False，默认为False
                fragment: 表示能否分片，取值True，False，默认为True
                last_fragment: 表示是否最后一片，取值True，False，默认为False
                fragment_offset: 表示分片的偏移量，默认为0
                ttl: 表示Time to live，默认为64
                ip_protocol: 表示协议类型，10进制取值或者枚举，默认为6（TCP）
                ip_protocol_mode: 表示ip_protocol的变化方式，fixed |incr | decr，默认为fixed
                ip_protocol_step: 表示ip_protocol的变化步长，10进制，默认为1
                ip_protocol_count: 表示ip_protocol数量，10进制，默认为1
                use_valid_checksum: 表示CRC是否自动计算，默认为true
                src_ip_mask: 表示源IP的掩码，默认为"255.0.0.0"
                src_ip_mode: 表示源IP的变化类型Fixed Random Incr Decr，默认为fixed
                src_ip_offset: 指定开始变化的位置，默认为0
                src_ip_repeat_count: 表示源IP的变化数量，默认为1
                dst_ip_mask: 表示目的IP的掩码，默认为"255.0.0.0"
                dst_ip_mode: 表示目的IP的变化类型其取值范围为：Fixed Random Incr Decr，默认为Fixed
                dst_ip_offset: 指定开始变化的位置，默认为0
                dst_ip_repeat_count: 表示目的IP的变化数量，默认为1
                dst_dut_ip_addr: 指定对应DUT的ip地址，即网关，默认为192.85.1.1
                options: 表示可选项，4字节整数倍16进制数值
                qos_mode: 表示Qos的类型，tos/dscp 如 -qosMode tos，默认为dscp
                qos_value: 表示Qos取值，Dscp取值0~63，tos取值0~255，十进制取值，默认为 0
                qos_value_enable: 当qos_mode为tos时，设置qos_value_enable为False，则delay，throughput，reliability，cost参数生效，
                                  否则，使用qos_value的值，默认为True

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s IPV4 -sourceIpAddr %s -destIpAddr %s " % (header_name, src_ip, dst_ip)

            # check user input args
            for var in tmp_dict.keys():

                if var == "precedence":
                    cmd = "%s -precedence %s" % (cmd, tmp_dict[var])

                elif var == "delay":
                    if tmp_dict[var].lower() == "low":
                        cmd = "%s -delay lowdelay" % cmd
                    else:
                        cmd = "%s -delay %s" % (cmd, tmp_dict[var])

                elif var == "throughput":
                    if tmp_dict[var].lower() == "high":
                        cmd = "%s -throughput highthruput" % cmd
                    else:
                        cmd = "%s -throughput %s" % (cmd, tmp_dict[var])

                elif var == "reliability":
                    if tmp_dict[var].lower() == "high":
                        cmd = "%s -reliability highreliability" % cmd
                    else:
                        cmd = "%s -reliability %s" % (cmd, tmp_dict[var])

                elif var == "cost":
                    if tmp_dict[var].lower() == "low":
                        cmd = "%s -cost lowcost" % cmd
                    else:
                        cmd = "%s -cost %s" % (cmd, tmp_dict[var])

                elif var == "identifier":
                    cmd = "%s -identifier %s" % (cmd, tmp_dict[var])

                elif var == "total_length":
                    cmd = "%s -totalLength %s" % (cmd, tmp_dict[var])

                elif var == "length_override":
                    cmd = "%s -lengthOverride %s" % (cmd, tmp_dict[var])

                elif var == "fragment":
                    if tmp_dict[var].lower() == "true":
                        cmd = "%s -fragment may" % cmd
                    else:
                        cmd = "%s -fragment %s" % (cmd, tmp_dict[var])

                elif var == "last_fragment":
                    cmd = "%s -lastFragment %s" % (cmd, tmp_dict[var])

                elif var == "fragment_offset":
                    cmd = "%s -fragmentOffset %s" % (cmd, tmp_dict[var])

                elif var == "ttl":
                    cmd = "%s -ttl %s" % (cmd, tmp_dict[var])

                elif var == "ip_protocol":
                    cmd = "%s -ipProtocol %s" % (cmd, tmp_dict[var])

                elif var == "ip_protocol_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -ipProtocolMode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -ipProtocolMode decrement" % cmd
                    else:
                        cmd = "%s -ipProtocolMode %s" % (cmd, tmp_dict[var])

                elif var == "ip_protocol_step":
                    cmd = "%s -ipProtocolStep %s" % (cmd, tmp_dict[var])

                elif var == "ip_protocol_count":
                    cmd = "%s -ipProtocolCount %s" % (cmd, tmp_dict[var])

                elif var == "use_valid_checksum":
                    cmd = "%s -useValidChecksum %s" % (cmd, tmp_dict[var])

                elif var == "src_ip_mask":
                    cmd = "%s -sourceIpMask %s" % (cmd, tmp_dict[var])

                elif var == "src_ip_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -sourceIpAddrMode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -sourceIpAddrMode decrement" % cmd
                    else:
                        cmd = "%s -sourceIpAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "src_ip_offset":
                    cmd = "%s -sourceIpAddrOffset %s" % (cmd, tmp_dict[var])

                elif var == "src_ip_repeat_count":
                    cmd = "%s -sourceIpAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_ip_mask":
                    cmd = "%s -destIpMask %s" % (cmd, tmp_dict[var])

                elif var == "dst_ip_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -destIpAddrMode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -destIpAddrMode decrement" % cmd
                    else:
                        cmd = "%s -destIpAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_ip_offset":
                    cmd = "%s -destIpAddrOffset %s" % (cmd, tmp_dict[var])

                elif var == "dst_ip_repeat_count":
                    cmd = "%s -destIpAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_dut_ip_addr":
                    cmd = "%s -destDutIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "options":
                    cmd = "%s -options %s" % (cmd, tmp_dict[var])

                elif var == "qos_mode":
                    cmd = "%s -qosMode %s" % (cmd, tmp_dict[var])

                elif var == "qos_value":
                    cmd = "%s -qosvalue %s" % (cmd, tmp_dict[var])

                elif var == "qos_value_enable":
                    cmd = "%s -qosValueExist %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_ipv4_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_tcp_header(self, header_name, src_port, dst_port, dict_args):
        """
        功能描述：创建TCP报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            src_port: 表示源端口
            dst_port: 表示目的端口
            dict_args: 表示可选参数字典,具体参数描述如下：
                offset: 表示TCP段中数据偏移量，即数据起始的位置，单位是32bit，默认为5
                src_port_mode: 表示端口改变模式fixed | incr | decr，默认为fixed
                src_port_count: 表示数量，默认为1
                src_port_step: 表示步长，默认为1
                dst_port_mode: 表示端口改变模式fixed | incr | decr，默认为fixed
                dst_port_count: 表示数量，默认为1
                dst_port_step: 表示步长，默认为1
                window: 表示窗口，默认为0
                urgent_pointer: 表示紧急指针，用于指示紧急数据的末端，默认为0
                options: 表示可选项
                urgent_pointer_valid: 表示是否置位URG，默认为False
                acknowledge_valid: 表示是否置位ACK。默认为False
                push_function_valid: 表示是否置位PSH，默认为False
                reset_connection: 表示是否置位RST，默认为False
                synchronize: 表示是否置位SYN，默认为False
                finished: 表示是否置位FIN，默认为False
                use_valid_checksum: 表示Tcp的校验和是否自动计算，默认为Enable

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s TCP -sourcePort %s -destPort %s " % (header_name, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "offset":
                    cmd = "%s -offset %s" % (cmd, tmp_dict[var])

                elif var == "src_port_mode":
                    cmd = "%s -srcPortMode %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -srcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "src_port_step":
                    cmd = "%s -srcPortStep %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_mode":
                    cmd = "%s -dstPortMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -dstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_step":
                    cmd = "%s -dstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "window":
                    cmd = "%s -window %s" % (cmd, tmp_dict[var])

                elif var == "urgent_pointer":
                    cmd = "%s -urgentPointer %s" % (cmd, tmp_dict[var])

                elif var == "urgent_pointer_valid":
                    cmd = "%s -urgentPointerValid %s" % (cmd, tmp_dict[var])

                elif var == "acknowledge_valid":
                    cmd = "%s -acknowledgeValid %s" % (cmd, tmp_dict[var])

                elif var == "push_function_valid":
                    cmd = "%s -pushFunctionValid %s" % (cmd, tmp_dict[var])

                elif var == "reset_connection":
                    cmd = "%s -resetConnection %s" % (cmd, tmp_dict[var])

                elif var == "synchronize":
                    cmd = "%s -synchronize %s" % (cmd, tmp_dict[var])

                elif var == "finished":
                    cmd = "%s -finished %s" % (cmd, tmp_dict[var])

                elif var == "use_valid_checksum":
                    cmd = "%s -useValidChecksum %s" % (cmd, tmp_dict[var])

                elif var == "options":
                    cmd = "%s -options %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_tcp_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_udp_header(self, header_name, src_port, dst_port, dict_args):
        """
        功能描述：创建UDP报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            src_port: 表示源端口
            dst_port: 表示目的端口
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_port_mode: 表示端口改变模式 fixed | incr | decr，默认为fixed
                src_port_count: 表示数量，默认为1
                src_port_step: 表示步长，默认为1
                dst_port_mode: 表示端口改变模式fixed | incr | decr，默认为fixed
                dst_port_count: 表示数量，默认为1
                dst_port_step: 表示步长，默认1
                checksum: 表示校验和，默认为0
                enable_checksum: 表示是否使能校验和，默认为Enable
                length: 表示长度,默认为10
                length_override: 表示长度是否可重写，默认为Disable
                enable_checksum_override: 表示是否使能校验和重写，默认为Disable
                checksum_mode: 表示校验和类型，默认为auto

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s UDP -sourcePort %s -destPort %s " % (header_name, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "src_port_mode":
                    cmd = "%s -srcPortMode %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -srcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "src_port_step":
                    cmd = "%s -srcPortStep %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_mode":
                    cmd = "%s -dstPortMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -dstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_step":
                    cmd = "%s -dstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "checksum":
                    cmd = "%s -checksum %s" % (cmd, tmp_dict[var])

                elif var == "enable_checksum":
                    cmd = "%s -enableChecksum %s" % (cmd, tmp_dict[var])

                elif var == "length":
                    cmd = "%s -length %s" % (cmd, tmp_dict[var])

                elif var == "length_override":
                    cmd = "%s -lengthOverride %s" % (cmd, tmp_dict[var])

                elif var == "enable_checksum_override":
                    cmd = "%s -enableChecksumOverride %s" % (cmd, tmp_dict[var])

                elif var == "checksum_mode":
                    cmd = "%s -checksumMode %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_udp_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_mpls_header(self, header_name, dict_args):
        """
        功能描述：创建MPLS报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                mpls_type: 表示MPLS标记类型，mplsUnicast | mplsMulticast，默认为mplsUnicast
                label: 表示MPLS标记值，默认为0
                label_count: 表示标记变化的个数，默认为1
                label_mode: 表示标记改变的模式，fixed | incr | decr，默认为fixed
                label_step: 表示标记变化的步长，默认为1
                experimental_use: 表示MPLS的qos的优先级，取值范围为0-7，默认为0
                time_to_live: 表示TTL，默认为64
                bottom_of_stack: 表示MPLS标记栈位置，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s MPLS "  % header_name

            # check user input args
            for var in tmp_dict.keys():

                if var == "mpls_type":
                    cmd = "%s -type %s" % (cmd, tmp_dict[var])

                elif var == "label":
                    cmd = "%s -label %s" % (cmd, tmp_dict[var])

                elif var == "label_count":
                    cmd = "%s -labelCount %s" % (cmd, tmp_dict[var])

                elif var == "label_mode":
                    cmd = "%s -labelMode %s" % (cmd, tmp_dict[var])

                elif var == "label_step":
                    cmd = "%s -labelStep %s" % (cmd, tmp_dict[var])

                elif var == "experimental_use":
                    cmd = "%s -Exp %s" % (cmd, tmp_dict[var])

                elif var == "time_to_live":
                    cmd = "%s -TTL %s" % (cmd, tmp_dict[var])

                elif var == "bottom_of_stack":
                    cmd = "%s -bottomOfStack %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_mpls_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_ipv6_header(self, header_name, flow_label, dict_args):
        """
        功能描述：创建IPV6报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            flow_label: 表示Flow 标记值
            dict_args: 表示可选参数字典,具体参数描述如下：
                traffic_class: 表示流分类等级，默认为0
                pay_load_len: 表示负荷长度，没有设置则自动计算，默认为20
                next_header: 表示下一个头类型，默认为6
                hop_limit: 表示Hop限制，默认为255
                src_addr: 表示源ipv6Address，默认为2000::2
                dst_addr: 表示目的ipv6Address，默认为2000::1
                src_addr_mode: 表示原地址改变模式 fixed | incr | decr，默认为fixed
                src_addr_count: 表示数量，默认为1
                src_addr_step: 表示变化步长，默认为0000:0000:0000:0000:0000:0000:0000:0001
                src_addr_offset: 表示原地址变化偏移量，默认为0
                dst_addr_mode: 表示目的地址改变模式，fixed | incr | decr，默认为fixed
                dst_addr_count: 表示数量，默认为1
                dst_addr_step: 表示变化步长，默认为0000:0000:0000:0000:0000:0000:0000:0001
                dst_addr_offset: 表示偏移量，默认为0
                dst_dut_ip_addr: 指定对应DUT的ip地址，即网关，默认为::0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s IPV6 -FlowLabel %s "  % (header_name, flow_label)

             # check user input args
            for var in tmp_dict.keys():

                if var == "traffic_class":
                    cmd = "%s -TrafficClass %s" % (cmd, tmp_dict[var])

                elif var == "pay_load_len":
                    cmd = "%s -PayLoadLen %s" % (cmd, tmp_dict[var])

                elif var == "next_header":
                    cmd = "%s -NextHeader %s" % (cmd, tmp_dict[var])

                elif var == "hop_limit":
                    cmd = "%s -HopLimit %s" % (cmd, tmp_dict[var])

                elif var == "src_addr":
                    cmd = "%s -SourceAddress %s" % (cmd, tmp_dict[var])

                elif var == "dst_addr":
                    cmd = "%s -DestinationAddress %s" % (cmd, tmp_dict[var])

                elif var == "src_addr_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -SourceAddressMode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -SourceAddressMode decrement" % cmd
                    else:
                        cmd = "%s -SourceAddressMode %s" % (cmd, tmp_dict[var])

                elif var == "src_addr_count":
                    cmd = "%s -SourceAddressCount %s" % (cmd, tmp_dict[var])

                elif var == "src_addr_step":
                    cmd = "%s -SourceAddressStep %s" % (cmd, tmp_dict[var])

                elif var == "src_addr_offset":
                    cmd = "%s -SourceAddressOffset %s" % (cmd, tmp_dict[var])

                elif var == "dst_addr_mode":
                    if tmp_dict[var].lower() == "incr":
                        cmd = "%s -DestAddressMode increment" % cmd
                    elif tmp_dict[var].lower() == "decr":
                        cmd = "%s -DestAddressMode decrement" % cmd
                    else:
                        cmd = "%s -DestAddressMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_addr_count":
                    cmd = "%s -DestAddressCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_addr_step":
                    cmd = "%s -DestAddressStep %s" % (cmd, tmp_dict[var])

                elif var == "dst_addr_offset":
                    cmd = "%s -DestAddressOffSet %s" % (cmd, tmp_dict[var])

                elif var == "dst_dut_ip_addr":
                    cmd = "%s -destDutIpAddr %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_ipv6_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_pos_header(self, header_name, dict_args):
        """
        功能描述：创建POS报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                hdlc_address: 表示接口地址，默认为FF
                hdlc_control: 表示接口控制类型，默认为03
                hdlc_protocol: 表示接口链路层协议，默认为0021

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s POS "  % header_name

            # check user input args
            for var in tmp_dict.keys():

                if var == "hdlc_address":
                    cmd = "%s -HdlcAddress %s" % (cmd, tmp_dict[var])

                elif var == "hdlc_control":
                    cmd = "%s -HdlcControl %s" % (cmd, tmp_dict[var])

                elif var == "hdlc_protocol":
                    cmd = "%s -HdlcProtocol %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_pos_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_hdlc_header(self, header_name, dict_args):
        """
        功能描述：创建hdlc报头PDU

        参数：
            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                hdlc_address: 表示接口地址，默认为0F
                hdlc_control: 表示接口控制类型，默认为00
                hdlc_protocol: 表示接口链路层协议，默认为0800

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHeader %s HDLC "  %  header_name

            # check user input args
            for var in tmp_dict.keys():

                if var == "hdlc_address":
                    cmd = "%s -HdlcAddress %s" % (cmd, tmp_dict[var])

                elif var == "hdlc_control":
                    cmd = "%s -HdlcControl %s" % (cmd, tmp_dict[var])

                elif var == "hdlc_protocol":
                    cmd = "%s -HdlcProtocol %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_hdlc_header fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_dhcp_packet(self, packet_name, op, htype, hlen,
                                      hops, xid, secs, bflag, mbz15, ciaddr,
                                      yiaddr, siaddr, giaddr, chaddr, dict_args):
        """
        功能描述：创建DHCP报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            op: 表示发送报文的类型，可设置 1 或者 2，1:client,2:server
            htype: 表示硬件地址类型，非负整数值
            hlen: 表示硬件地址长度，非负整数值
            hops: 表示跳数，非负整数值
            xid: 表示事务编号，非负整数值
            secs: 表示秒数，非负整数值
            bflag: 表示广播标志位, 可设置 0/1
            mbz15: 表示广播标志位后的 15 位 bit 位
            ciaddr: 表示客户端 IP 地址，格式为0.0.0.0
            yiaddr: 表示测试机 IP 地址，格式为0.0.0.0
            siaddr: 表示服务器 IP 地址，格式为0.0.0.0
            giaddr: 表示中继代理 IP 地址，格式为 0.0.0.0
            chaddr: 表示客户机硬件地址，格式为 00：00：00：00：00：00
            dict_args: 表示可选参数字典,具体参数描述如下：
                sname: 表示服务器名称，64 Bytes 的 16 进制值
                file: 表示DHCP 可选参数/启动文件名, 128 Bytes 的 16 进制值
                option: 表示可选项

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s DHCP \
                                                 -op %s \
                                                 -htype %s \
                                                 -hlen %s \
                                                 -hops %s \
                                                 -xid %s \
                                                 -secs %s \
                                                 -bflag %s \
                                                 -mbz15 %s \
                                                 -ciaddr %s \
                                                 -yiaddr %s \
                                                 -siaddr %s \
                                                 -giaddr %s \
                                                 -chaddr %s "  % (
                                                 packet_name,
                                                 op,
                                                 htype,
                                                 hlen,
                                                 hops,
                                                 xid,
                                                 secs,
                                                 bflag,
                                                 mbz15,
                                                 ciaddr,
                                                 yiaddr,
                                                 siaddr,
                                                 giaddr,
                                                 chaddr)

            # check user input args
            for var in tmp_dict.keys():

                if var == "sname":
                    cmd = "%s -sname %s" % (cmd, tmp_dict[var])

                elif var == "file":
                    cmd = "%s -file %s" % (cmd, tmp_dict[var])

                elif var == "option":
                    cmd = "%s -option %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_dhcp_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)
            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_pim_packet(self, packet_name, type, dict_args):
        """
        功能描述：创建PIM报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            type: 表示消息类型，可选值为 Hello, Join_Prune, Register, Register_Stop, Assert，Bootstrap, Graft, Graft_Reply,C-RP_Advertisement必须指定
            dict_args: 表示可选参数字典,具体参数描述如下：
                version: 表示协议版本,默认为2
                reserved: 表示保留位，默认为0
                option_type: 表示协议 option 字段类型，默认为"HoldTIme"
                option_length: 表示协议 option 字段长度, 默认为2
                option_value: 表示协议 option 字段内容， 默认为105
                unicast_addr_family: 表示单播地址类型，默认为"IPv4"
                unicast_Ip_addr: 表示单播IP地址，默认为"192.0.0.1"
                group_num: 表示组个数，默认为1
                hold_time: 表示HoldTime,默认为105
                joined_source_num: 表示joined source num, 默认为1
                pruned_source_num: 表示pruned srouce num, 默认为1
                group_ip_addr: 表示组播组的IP地址，默认为"255.0.0.1"
                group_ip_bbit: 表示group ip BBit，默认为0
                group_ip_zbit: 表示group ip ZBit, 默认为0
                source_ip_addr: 表示 srouce ip addr, 默认为"192.0.0.1"
                pruned_source_ip_addr: 表示pruned srouce ip addr, 默认为"192.0.0.1"
                reg_border_bit: 表示 reg border bit, 默认为0
                reg_null_reg_bit: 表示 reg null reg bit, 默认为0
                reg_reserved_field: 表示 reg reserved filed, 默认为0
                reg_encap_multi_pkt: 表示 reg encap multi pkt， 默认为空
                reg_group_ip_addr: 表示 reg group ip addr, 默认为"255.0.0.1"
                reg_source_ip_addr: 表示 reg source ip addr, 默认为"192.0.0.1"
                assert_rpt_bit: 表示 assert rpt bit, 默认为0
                assert_metric_perf: 表示 assert metric perf, 默认为0
                assert_metric: 表示 assert metric, 默认为2

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s PIM -Type %s "  % (packet_name, type)

            # check user input args
            for var in tmp_dict.keys():

                if var == "version":
                    cmd = "%s -Version %s" % (cmd, tmp_dict[var])

                elif var == "reserved":
                    cmd = "%s -Reserved %s" % (cmd, tmp_dict[var])

                elif var == "option_type":
                    cmd = "%s -OptionType %s" % (cmd, tmp_dict[var])

                elif var == "option_length":
                    cmd = "%s -OptionLength %s" % (cmd, tmp_dict[var])

                elif var == "option_value":
                    cmd = "%s -Version %s" % (cmd, tmp_dict[var])

                elif var == "unicast_addr_family":
                    cmd = "%s -UnicastAddrFamily %s" % (cmd, tmp_dict[var])

                elif var == "unicast_Ip_addr":
                    cmd = "%s -UnicastIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "group_num":
                    cmd = "%s -GroupNum %s" % (cmd, tmp_dict[var])

                elif var == "hold_time":
                    cmd = "%s -HoldTime %s" % (cmd, tmp_dict[var])

                elif var == "joined_source_num":
                    cmd = "%s -JoinedSourceNum %s" % (cmd, tmp_dict[var])

                elif var == "pruned_source_num":
                    cmd = "%s -PrunedSourceNum %s" % (cmd, tmp_dict[var])

                elif var == "group_ip_addr":
                    cmd = "%s -GroupIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "group_ip_bbit":
                    cmd = "%s -GroupIpBBit %s" % (cmd, tmp_dict[var])

                elif var == "group_ip_zbit":
                    cmd = "%s -GroupIpZBit %s" % (cmd, tmp_dict[var])

                elif var == "source_ip_addr":
                    cmd = "%s -SourceIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "pruned_source_ip_addr":
                    cmd = "%s -PrunedSourceIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "reg_border_bit":
                    cmd = "%s -RegBorderBit %s" % (cmd, tmp_dict[var])

                elif var == "reg_null_reg_bit":
                    cmd = "%s -RegNullRegBit %s" % (cmd, tmp_dict[var])

                elif var == "reg_reserved_field":
                    cmd = "%s -RegReservedField %s" % (cmd, tmp_dict[var])

                elif var == "reg_group_ip_addr":
                    cmd = "%s -RegGroupIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "reg_source_ip_addr":
                    cmd = "%s -RegSourceIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "assert_rpt_bit":
                    cmd = "%s -AssertRptBit %s" % (cmd, tmp_dict[var])

                elif var == "assert_metric_perf":
                    cmd = "%s -AssertMetricPerf %s" % (cmd, tmp_dict[var])

                elif var == "assert_metric":
                    cmd = "%s -AssertMetric %s" % (cmd, tmp_dict[var])

                elif var == "reg_encap_multi_pkt":
                    cmd = "%s -RegEncapMultiPkt %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_pim_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_igmp_packet(self, packet_name, protocol_type, group_start_ip, dict_args):
        """
        功能描述：创建IGMP报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            protocol_type: 表示IGMP消息类型，必须指定
            group_start_ip: 必须指定
            dict_args: 表示可选参数字典,具体参数描述如下：
                protocol_ver: 表示IGMP 版本号，默认为IGMPv2
                group_count: 表示组播组的个数，默认为1
                increase_step: 表示递增步长，默认为1
                max_resp_time: 表示最大回应时间，默认为0
                check_sum: 默认为0
                sflag: 表示suppress Flag，默认为0
                qrv: 表示QRV,默认为0
                qqic: 表示QQIC,默认为0
                src_num: 表示source num，默认为0
                src_ip_list: 表示源ip地址列表（当src_num不为0），默认为空
                reserved: 默认为0
                group_records: 默认为True
                group_num: 默认为0
                group_type: 表示RecordType默认为"ALLOW_NEW_SOURCES"
                aux_len: 表示Auxiliary data length, 默认为0
                group_ip: 表示MultiCastAddr, 默认为"225.0.0.1"

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s IGMP -ProtocolType %s -GroupStartIp %s "  % ( packet_name,
                                                                                                  protocol_type,
                                                                                                  group_start_ip )
            # check user input args
            for var in tmp_dict.keys():

                if var == "protocol_ver":
                    cmd = "%s -ProtocolVer %s" % (cmd, tmp_dict[var])

                elif var == "group_count":
                    cmd = "%s -GroupCount %s" % (cmd, tmp_dict[var])

                elif var == "increase_step":
                    cmd = "%s -IncreaseStep %s" % (cmd, tmp_dict[var])

                elif var == "max_resp_time":
                    cmd = "%s -MaxRespTime %s" % (cmd, tmp_dict[var])

                elif var == "check_sum":
                    cmd = "%s -Checksum %s" % (cmd, tmp_dict[var])

                elif var == "sflag":
                    cmd = "%s -sflag %s" % (cmd, tmp_dict[var])

                elif var == "qrv":
                    cmd = "%s -qrv %s" % (cmd, tmp_dict[var])

                elif var == "qqic":
                    cmd = "%s -qqic %s" % (cmd, tmp_dict[var])

                elif var == "src_num":
                    cmd = "%s -SrcNum %s" % (cmd, tmp_dict[var])

                elif var == "src_ip_list":
                    cmd = "%s -SrcIpList %s" % (cmd, tmp_dict[var])

                elif var == "reserved":
                    cmd = "%s -Reserved %s" % (cmd, tmp_dict[var])

                elif var == "group_records":
                    cmd = "%s -GroupRecords %s" % (cmd, tmp_dict[var])

                elif var == "group_num":
                    cmd = "%s -GroupNum %s" % (cmd, tmp_dict[var])

                elif var == "group_type":
                    cmd = "%s -GroupType %s" % (cmd, tmp_dict[var])

                elif var == "aux_len":
                    cmd = "%s -AuxLen %s" % (cmd, tmp_dict[var])

                elif var == "group_ip":
                    cmd = "%s -GroupIp %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_igmp_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_pppoe_packet(self, packet_name, PPPoE_type, dict_args):
        """
        功能描述：创建PPPoE报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            PPPoE_type: 表示PPPoE 报文类型，必须指定
            dict_args: 表示可选参数字典,具体参数描述如下：
                version: 表示报文协议版本号,默认为1
                type: 表示报文协议类型，默认为1
                code: 表示报文代码(当对应 PPPoE_Session 时，code 为整数)，默认为空
                session_id: 表示会话 ID，默认为0
                length: 表示报文长度，默认为0
                tag: 表示报文标签类型，默认为空
                tag_length: 表示报文标签长度(16 进制)，默认为0
                tag_value: 表示报文标签值(16 进制)，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s PPPoE -PPPoEType %s "  % (packet_name,PPPoE_type)

            # check user input args
            for var in tmp_dict.keys():

                if var == "version":
                    cmd = "%s -Version %s" % (cmd, tmp_dict[var])

                elif var == "type":
                    cmd = "%s -Type %s" % (cmd, tmp_dict[var])

                elif var == "session_id":
                    cmd = "%s -SessionId %s" % (cmd, tmp_dict[var])

                elif var == "length":
                    cmd = "%s -Length %s" % (cmd, tmp_dict[var])

                elif var == "tag_length":
                    cmd = "%s -TagLength %s" % (cmd, tmp_dict[var])

                elif var == "tag_value":
                    cmd = "%s -TagValue %s" % (cmd, tmp_dict[var])

                elif var == "code":
                    cmd = "%s -Code %s" % (cmd, tmp_dict[var])

                elif var == "tag":
                    cmd = "%s -Tag %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_pppoe_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_icmp_packet(self, packet_name, icmp_type, code, dict_args):
        """
        功能描述：创建ICMP报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            icmp_type: 表示ICMP包类型，echo_request，echo_reply，destination_unreachable，
                       source_quench，redirect，time_exceeded，parameter_problem，
                       timestamp_request，timestamp_reply，information_request，
                       information_reply支持直接填写上述关键字段，同时也支持0-255 十进制数字书写
            code: 表示Icmp包代码，支持0-255 十进制数字书写
            dict_args: 表示可选参数字典,具体参数描述如下：
                checksum: 表示校验码,默认自动计算
                sequ_num: 表示Icmp包序列号
                data: 表示ICMP包数据，默认为0000
                internet_header: 表示IP首部，当IcmpType设为destination_unreachable、
                                 parameter_problem、redirect、source_quench、time_exceeded时有效
                original_date_fragment:: 表示初始数据片段，当IcmpType设为destination_unreachable、
                                         parameter_problem、redirect、source_quench、time_exceeded时有效,
                                         默认为0000000000000000
                gateway_internet_add: 表示网关IP地址，当IcmpType设为redirect时有效，默认为192.0.0.1
                pointer: 表示指针，当IcmpType设为parameter_problem时有效，默认为0
                identifier: 表示标识符，默认为 0
                originate_timestamp: 表示初始时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0
                receive_timestamp: 表示接收时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0
                transmit_timestamp: 表示传送时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s ICMP -IcmpType %s -Code %s"  % (packet_name, icmp_type, code)

            # check user input args
            for var in tmp_dict.keys():

                if var == "checksum":
                    cmd = "%s -Checksum %s" % (cmd, tmp_dict[var])

                elif var == "sequ_num":
                    cmd = "%s -SequNum %s" % (cmd, tmp_dict[var])

                elif var == "data":
                    cmd = "%s -Data %s" % (cmd, tmp_dict[var])

                elif var == "original_date_fragment":
                    cmd = "%s -OriginalDateFragment %s" % (cmd, tmp_dict[var])

                elif var == "gateway_internet_add":
                    cmd = "%s -GatewayInternetAdd %s" % (cmd, tmp_dict[var])

                elif var == "pointer":
                    cmd = "%s -Pointer %s" % (cmd, tmp_dict[var])

                elif var == "identifier":
                    cmd = "%s -Identifier %s" % (cmd, tmp_dict[var])

                elif var == "originate_timestamp":
                    cmd = "%s -OriginateTimeStamp %s" % (cmd, tmp_dict[var])

                elif var == "receive_timestamp":
                    cmd = "%s -ReceiveTimeStamp %s" % (cmd, tmp_dict[var])

                elif var == "transmit_timestamp":
                    cmd = "%s -TransmitTimeStamp %s" % (cmd, tmp_dict[var])

                elif var == "internet_header":
                    cmd = "%s -InternetHeader %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_icmp_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)
            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_icmpv6_packet(self, packet_name, icmpv6_type, dict_args):
        """
        功能描述：创建ICMPV6报文PDU

        参数:
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            icmpv6_type: 表示ICMPV6包类型，Icmpv6DestUnreach, Icmpv6EchoReply, Icmpv6EchoRequest,
                         Icmpv6PacketTooBig, Icmpv6ParameterProblem, Icmpv6TimeExceeded

            dict_args: 表示可选参数字典,具体参数描述如下：
                code: 表示Icmp包代码，支持0-255 十进制数字书写
                checksum: 表示校验码,默认自动计算
                identifier: 表示标识符，默认为 0
                sequ_num: 表示Icmp包序列号
                data: 表示ICMPV6包数据，默认为0000

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s Icmpv6 -IcmpPktType %s"  % (packet_name, icmpv6_type)

            # check user input args
            for var in tmp_dict.keys():

                if var == "code":
                    cmd = "%s -Code %s" % (cmd, tmp_dict[var])

                elif var == "checksum":
                    cmd = "%s -CheckSum %s" % (cmd, tmp_dict[var])

                elif var == "sequ_num":
                    cmd = "%s -SequNum %s" % (cmd, tmp_dict[var])

                elif var == "data":
                    cmd = "%s -Data %s" % (cmd, tmp_dict[var])

                elif var == "identifier":
                    cmd = "%s -Identifier %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_icmp_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)
            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_arp_packet(self, packet_name, dict_args):
        """
        功能描述：创建ARP报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            dict_args: 表示可选参数字典,具体参数描述如下：
                operation: 指明 arp 报文类型，可选值为 request,reply，默认为request
                src_hw_addr: 指明 arp 报文中的 sender hardware address，默认为00:00:01:00:00:02
                src_hw_addr_mode: 指明 sourceHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed
                src_hw_addr_repeat_count: 指明 sourceHardwareAddr 的变化次数，默认为1
                src_hw_addr_repeat_step: 指明 sourceHardwareAddr 的变化步长，默认为00-00-00-00-00-01
                dst_hw_addr: 指明 arp 报文中的 target hardware address，默认为00:00:01:00:00:02
                dst_hw_addr_mode: 指明 destHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed
                dst_hw_addr_repeat_count: 指明 destHardwareAddr 的变化次数，默认为1
                dst_hw_addr_repeat_step: 指明 destHardwareAddr 的变化步长，默认为00-00-00-00-00-01
                src_protocol_addr: 指明 arp 报文中的 sender ip address，默认为192.85.1.2
                src_protocol_addr_mode: 指明 sourceProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed
                src_protocol_addr_repeat_count: 指明 sourceProtocolAddr 变化次数，默认为1
                src_protocol_addr_repeat_step: 指明 sourceProtocolAddr 变化步长，默认为0.0.0.1
                dst_protocol_addr: 指明 arp 报文中的 tartget ip address，默认为192.85.1.2
                dst_protocol_addr_mode: 指明 destProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed
                dst_protocol_addr_repeat_count: 指明 destProtocolAddr 变化次数，默认为1
                dst_protocol_addr_repeat_step: 指明 destProtocolAddr 变化步长，默认为0.0.0.1

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s ARP "  % (packet_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "operation":
                    cmd = "%s -operation %s" % (cmd, tmp_dict[var])

                elif var == "src_hw_addr":
                    cmd = "%s -sourceHardwareAddr %s" % (cmd, tmp_dict[var])

                elif var == "src_hw_addr_mode":
                    cmd = "%s -sourceHardwareAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "src_hw_addr_repeat_count":
                    cmd = "%s -sourceHardwareAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "src_hw_addr_repeat_step":
                    cmd = "%s -sourceHardwareAddrRepeatStep %s" % (cmd, tmp_dict[var])

                elif var == "dst_hw_addr":
                    cmd = "%s -destHardwareAddr %s" % (cmd, tmp_dict[var])

                elif var == "dst_hw_addr_mode":
                    cmd = "%s -destHardwareAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_hw_addr_repeat_count":
                    cmd = "%s -destHardwareAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_hw_addr_repeat_step":
                    cmd = "%s -destHardwareAddrRepeatStep %s" % (cmd, tmp_dict[var])

                elif var == "src_protocol_addr":
                    cmd = "%s -sourceProtocolAddr %s" % (cmd, tmp_dict[var])

                elif var == "src_protocol_addr_mode":
                    cmd = "%s -sourceProtocolAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "src_protocol_addr_repeat_count":
                    cmd = "%s -sourceProtocolAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "src_protocol_addr_repeat_step":
                    cmd = "%s -sourceProtocolAddrRepeatStep %s" % (cmd, tmp_dict[var])

                elif var == "dst_protocol_addr":
                    cmd = "%s -destProtocolAddr %s" % (cmd, tmp_dict[var])

                elif var == "dst_protocol_addr_mode":
                    cmd = "%s -destProtocolAddrMode %s" % (cmd, tmp_dict[var])

                elif var == "dst_protocol_addr_repeat_count":
                    cmd = "%s -destProtocolAddrRepeatCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_protocol_addr_repeat_step":
                    cmd = "%s -destProtocolAddrRepeatStep %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_arp_packet fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_custom_packet(self, packet_name, hex_string="aaaa"):
        """
        功能描述：创建Custom报文PDU

        参数：
            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作
            hex_string: 指明数据包内容,默认为"aaaa"

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::CreatePacket %s Custom -HexString %s"  % (packet_name, hex_string)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_add_pdu_into_stream(self, stream_name, pdu_list):
        """
        功能描述：添加pdu（即header和packet,统称pdu）到stream中，组建完整的流

        参数：
            stream_name: 指定要添加PDU的stream名字,这里的stream必须是create emtpy stream时指定的
            pdu_list: 表示需要添加到stream_name中的PDU列表

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # 将pdu_list字符串化
            str_pdu_list = ""

            # 多个pdu和单个pdu需要分开处理
            if type(pdu_list) == type([]):
                for pdu in pdu_list:
                    str_pdu_list = "%s %s" % (str_pdu_list, pdu)
            else:
                str_pdu_list = pdu_list

            # build TCL Command
            cmd = "::ATTTestCenter::AddPDUToStream %s %s"  % (stream_name, str_pdu_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_clear_test_result(self, port_or_stream="all", cleared_list=""):
        """
        功能描述：清零测试统计结果

        参数：
            port_or_stream: 指定是清零端口还是stream,或者是所有的统计结果,取值为port | stream | all，默认为all
            cleared_list: 指定要清零的对象列表，可以是端口列表，也可以是数据流列表

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # 将cleared_list字符串化
            str_cleared_list = ""

            # 多个obj和单个obj需要分开处理
            if type(cleared_list) == type([]):
                for obj in cleared_list:
                    str_cleared_list = "%s %s" % (str_cleared_list, obj)
            else:
                str_cleared_list = cleared_list

            # build TCL Command
            cmd = "::ATTTestCenter::ClearTestResult %s %s"  % (port_or_stream, str_cleared_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_filter(self, port_name, filter_name, filter_type,
                                 filter_value, filter_on_streamid=False):
        """
        功能描述：基于端口创建过滤器

        参数：
            port_name: 表示需要创建过滤器的端口名
            filter_name: 表示需要创建的过滤器名
            filter_type: 表示过滤器对象类型,取值范围为：UDF | Stack
            filter_value: 表示过滤器对象的值，格式为{{FilterExpr1}{FilterExpr2}…}
                          当FilterType为Stack时，FilterExpr 的格式为：
                               -ProtocolField ProtocolField -min min -max max -mask mask
                                -ProtocolField: 指明具体的过滤字段，必选参数。ProtocolField 的具体过虑字段及说明如下：
                                    eth.srcMac   源 MAC 地址
                                    eth.dstMac   目的 MAC 地址
                                    eth:vlan.id        VLAN ID
                                    eth:vlan.pri       VLAN 优先级
                                    eth:ipv4.srcIp     源 IP 地址
                                    eth:ipv4.dstIp     目的 IP地址
                                    eth:ipv4.tos       Ipv4中tos字段
                                    eth:ipv4.pro       Ipv4协议字段
                                    eth:vlan:ipv4.srcIp     源 IP 地址(带vlan头)
                                    eth:vlan:ipv4.dstIp     目的 IP地址(带vlan头)
                                    eth:vlan:ipv4.tos       Ipv4中tos字段(带vlan头)
                                    eth:vlan:ipv4.pro       Ipv4协议字段(带vlan头)
                                    eth:ipv4:tcp.srcPort    TCP协议源端口号
                                    eth:ipv4:udp.srcPort    UDP协议源端口号
                                    eth:ipv4:any.srcPort    TCP或者UDP协议源端口号
                                    eth:ipv4:tcp.dstPort     TCP协议目的端口号
                                    eth:ipv4:udp.dstPort     UDP协议目的端口号
                                    eth:ipv4:any.dstPort     TCP或者UDP协议目的端口号
                                    eth:vlan:ipv4:tcp.srcPort    TCP协议源端口号(带vlan头)
                                    eth:vlan:ipv4:udp.srcPort    UDP协议源端口号(带vlan头)
                                    eth:vlan:ipv4:any.srcPort    TCP或者UDP协议源端口号(带vlan头)
                                    eth:vlan:ipv4:tcp.dstPort     TCP协议目的端口号(带vlan头)
                                    eth:vlan:ipv4:udp.dstPort     UDP协议目的端口号(带vlan头)
                                    eth:vlan:ipv4:any.dstPort     TCP或者UDP协议目的端口号(带vlan头)
                                -min：指明过滤字段的起始值。必选参数
                                -max:指明过滤字段的最大值。可选参数，若未指定，默认值为 min
                                -mask：指明过滤字段的掩码值。可选参数，取值与具体的字段相关。
                          当FilterType为UDF时，FilterExpr 的格式为：
                                -pattern pattern -offset offset  -max max -mask mask
                                -Pattern：表示过滤匹配值， 16 进制。必选参数，例如0x0806
                                -max：表示匹配的最大值，16进制。可选参数默认与Pattern相同
                                -Offset：表示偏移值，可选参数，默认值为 0，起始位置从包的第一个字节起
                                -Mask：表示掩码值, 16 进制.可选参数，默认值为与 pattern长度相同的全 f。例如 0xffff
            filter_on_streamid: 表示是否使用StreamId进行过滤，这种情况针对获取流的实时统计比较有效。
                                取值范围为TRUE/FALSE，默认为FALSE

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # 将filter_value字符串化
            str_filter_value = ""

            # 将每一项FilterExpr字符串化
            for expr in filter_value:
                str_expr = ""
                for element in expr:
                    str_expr = "%s %s" % (str_expr, element)

                # 去掉字符串前后的空格
                str_expr = str_expr.strip()

                # 在字符串前后加上{}，转化为tcl列表
                str_expr = "{%s}" % str_expr

                str_filter_value = "%s %s" % (str_filter_value, str_expr)

            # 去掉字符串前后的空格
            str_filter_value = str_filter_value.strip()
            str_filter_value = "{%s}" % str_filter_value

            # build TCL Command
            cmd = "::ATTTestCenter::CreateFilter %s %s %s %s %s"  % (
                                                   port_name,
                                                   filter_name,
                                                   filter_type,
                                                   str_filter_value,
                                                   filter_on_streamid)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_start_capture(self, port_name, save_path="", filter_name=""):
        """
        功能描述：在指定的端口上开始抓包，保存报文到指定路径下，如果没有给定保存路径，则保存到默认路径下

        参数：
            port_name: 表示需要开启捕获报文的端口名，这里的端口名是预约端口时指定的名字
            save_path: 表示捕获的报文保存的路径名。如果该参数为空,则保存到默认路径下
            filter_name: 表示要过滤保存报文使用的过滤器的名字

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::StartCapture %s"  % port_name

            if save_path != "":
                cmd = "%s %s" % (cmd, save_path)
            else:
                # 当save_path为""时，设置为default,防止filter_name不为空，传参发生异常
                cmd = "%s default" % cmd

            if filter_name != "":
                cmd = "%s %s" % (cmd, filter_name)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_stop_capture(self, port_name):
        """
        功能描述：停止指定端口的抓包

        参数：
            port_name: 表示需要开启捕获报文的端口名，这里的端口名是预约端口时指定的名字

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::StopCapture %s"  % port_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_traffic_on_port(self, port_list="", arp_study=True, time=0):
        """
        功能描述：基于端口开始发流，发指定时间的流后，停止发流，如果时间为0，立刻返回，由用户停止

        参数：
            port_list: 表示需要发流的端口组成的列表,默认为空，表示所有端口
            arp_study: 表示发流之前是否进行ARP学习，默认为TRUE
            time: 表示发流时间，单位为s,默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # 将port_list字符串化
            str_port_list = ""

            # 多个port和单个port需要分开处理
            if type(port_list) == type([]):
                for port in port_list:
                    str_port_list = "%s %s" % (str_port_list, port)
            else:
                str_port_list = port_list

            # build TCL Command
            cmd = "::ATTTestCenter::TrafficOnPort %s %s"  % (time, arp_study)

            if str_port_list != "":
                cmd = "%s %s" % (cmd, str_port_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_stop_traffic_on_port(self, port_list=""):
        """
        功能描述：停止端口发流

        参数：
            port_list: 表示需要停止发流的端口组成的列表,默认为空，表示所有端口

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # 将port_list字符串化
            str_port_list = ""

            # 多个port和单个port需要分开处理
            if type(port_list) == type([]):
                for port in port_list:
                    str_port_list = "%s %s" % (str_port_list, port)
            else:
                str_port_list = port_list

            # build TCL Command
            cmd = "::ATTTestCenter::StopTrafficOnPort %s"  % str_port_list

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_traffic_on_stream(self, port_name, stream_list="", arp_study=True, time=0):
        """
        功能描述：基于数据流开始发流，发指定时间的流后，停止发流，如果时间为0，立刻返回，由用户停止

        参数：
            port_name: 表示需要发流的端口名
            stream_list: 表示需要发流的数据流名组成的列表，默认为空，表示port_name上的所有数据流
            arp_study: 表示发流之前是否进行ARP学习，默认为TRUE
            time: 表示发流时间，单位为s, 默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # 将stream_list字符串化
            str_stream_list = ""

            # 多个stream和单个stream需要分开处理
            if type(stream_list) == type([]):
                for stream in stream_list:
                    str_stream_list = "%s %s" % (str_stream_list, stream)
            else:
                str_stream_list = stream_list

            # build TCL Command
            cmd = "::ATTTestCenter::TrafficOnStream %s %s %s"  % (
                             port_name, arp_study, time)

            if str_stream_list != "":
                cmd = "%s %s" % (cmd, str_stream_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_stop_traffic_on_stream(self, port_name, stream_list=""):
        """
        功能描述：停止数据流发流

        参数：
            port_name: 表示需要停止发流的端口名
            stream_list: 表示需要停止发流的数据流名组成的列表，默认为空，表示port_name上的所有数据流

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # 将stream_list字符串化
            str_stream_list = ""

            # 多个stream和单个stream需要分开处理
            if type(stream_list) == type([]):
                for stream in stream_list:
                    str_stream_list = "%s %s" % (str_stream_list, stream)
            else:
                str_stream_list = stream_list

            # build TCL Command
            cmd = "::ATTTestCenter::StopTrafficOnStream %s %s"  % (port_name, str_stream_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_get_port_statistic_snapshot(self, port_name, filter_stream=0, result_path=""):
        """
        功能描述：获取端口的统计结果快照

        参数：
            port_name: 表示需要获取统计结果的端口名
            filter_stream: 表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值
            result_path: 表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        state = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::GetPortStatsSnapshot %s %s %s"  % (port_name, filter_stream, result_path)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_get_stream_statistic_snapshot(self, port_name, stream_name, result_path):
        """
        功能描述：获取数据流的统计结果快照

        参数：
            port_name: 表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
            stream_name: 表示需要获取统计结果的数据流名
            result_path: 表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        state = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::GetStreamStatsSnapshot %s %s %s"  % (port_name, stream_name, result_path)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_get_port_statistic_result(self, port_name, option, filter_stream=0):
        """
        功能描述：获取端口的统计结果

        参数：
            port_name: 表示需要获取统计结果的端口名
            option: 表示需要获取的统计项名
            filter_stream: 表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        state = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::GetPortStats %s %s %s"  % (port_name, option, filter_stream)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {value} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                state = self.tcl_ret.split(' ', 2)[1]
                str_ret = self.tcl_ret.split(' ', 2)[2].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret, state


    def testcenter_get_stream_statistic_result(self, port_name, stream_name, option):
        """
        功能描述：获取数据流的统计结果

        参数：
            port_name: 表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
            stream_name: 表示需要获取统计结果的数据流名
            option: 表示需要获取的统计项名

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        state = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::GetStreamStats %s %s %s"  % (port_name, stream_name, option)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {value} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                state = self.tcl_ret.split(' ', 2)[1]
                str_ret = self.tcl_ret.split(' ', 2)[2].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret, state


    def testcenter_create_host(self, port_name, host_name, dict_args):
        """
        功能描述：创建host，并配置相关属性

        参数：
            port_name: 表示要创建host的端口别名，必须是预约端口时指定的名字
            host_name: 表示创建的host的名字
            dict_args: 表示可选参数字典,具体参数描述如下：
                ip_version: 指明IP的版本,可设置ipv4/ipv6，默认为ipv4
                host_type: 指明服务器类型，可设置normal/IgmpHost/MldHost，默认为normal
                ipv4_addr: 指明主机ipv4地址，默认为192.168.1.2
                ipv4_addr_gateway: 指明主机ipv4网关，默认为192.168.1.1
                ipv4_addr_mask: 指明主机ipv4的掩码，默认为0.0.0.255
                ipv4_addr_prefix_len: 表示Host IPv4地址Prefix长度
                ipv6_addr: 指明主机ipv6地址，默认为 2000:201::1:2
                ipv6_addr_mask: 指明主机ipv6的掩码，默认为0000::FFFF:FFFF:FFFF:FFFF
                ipv6_link_local_addr: 表示Host起始IPv6 Link Local地址，默认为fe80::
                ipv6_addr_gateway: 指明主机ipv6网关，默认为2000:201::1:1
                ipv6_addr_prefix_len: 表示Host IPv4地址Prefix长度，默认为64
                mac_addr: 指明Host起始MAC地址，默认内部自动生成，依次递增00:20:94:SlotId:PortId:seq
                mac_mask: 指明Host起始MAC的掩码地址，默认为00:00:FF:FF:FF:FF
                mac_count: 指明Mac地址变化的数量，默认为1
                mac_increase: 指明Mac地址递增的步长，默认为1
                count: 指明Host IP地址个数，默认为1
                increase: 指明IP地址增幅，默认为1
                flag_ping: 指明是否支持Ping功能，enable/disable，默认为enable
                enable_vlan: 指明是否添加vlan，enable/disable, 默认为disable
                vlan_id: 指明Vlan id的值，取值范围1-4096， 默认为100
                vlan_pri: 优先级,取值范围0-7，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateHost %s %s "  % (port_name, host_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "ip_version":
                    cmd = "%s -IpVersion %s" % (cmd, tmp_dict[var])

                elif var == "host_type":
                    cmd = "%s -HostType %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr":
                    cmd = "%s -Ipv4Addr %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr_gateway":
                    cmd = "%s -Ipv4AddrGateway %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr_mask":
                    cmd = "%s -Ipv4StepMask %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr_prefix_len":
                    cmd = "%s -Ipv4Mask %s" % (cmd, tmp_dict[var])

                elif var == "ipv6_addr":
                    cmd = "%s -Ipv6Addr %s" % (cmd, tmp_dict[var])

                elif var == "ipv6_addr_mask":
                    cmd = "%s -Ipv6StepMask %s" % (cmd, tmp_dict[var])

                elif var == "ipv6_link_local_addr":
                    cmd = "%s -Ipv6LinkLocalAddr %s" % (cmd, tmp_dict[var])

                elif var == "ipv6_addr_gateway":
                    cmd = "%s -Ipv6AddrGateway %s" % (cmd, tmp_dict[var])

                elif var == "ipv6_addr_prefix_len":
                    cmd = "%s -Ipv6Mask %s" % (cmd, tmp_dict[var])

                elif var == "mac_addr":
                    cmd = "%s -MacAddr %s" % (cmd, tmp_dict[var])

                elif var == "mac_mask":
                    cmd = "%s -MacStepMask %s" % (cmd, tmp_dict[var])

                elif var == "mac_count":
                    cmd = "%s -MacCount %s" % (cmd, tmp_dict[var])

                elif var == "mac_increase":
                    cmd = "%s -MacIncrease %s" % (cmd, tmp_dict[var])

                elif var == "count":
                    cmd = "%s -Count %s" % (cmd, tmp_dict[var])

                elif var == "increase":
                    cmd = "%s -Increase %s" % (cmd, tmp_dict[var])

                elif var == "flag_ping":
                    cmd = "%s -FlagPing %s" % (cmd, tmp_dict[var])

                elif var == "enable_vlan":
                    cmd = "%s -EnableVlan %s" % (cmd, tmp_dict[var])

                elif var == "vlan_id":
                    cmd = "%s -VlanId %s" % (cmd, tmp_dict[var])

                elif var == "vlan_pri":
                    cmd = "%s -VlanPriority %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_host fail, errInfo:%s" % str_ret)
            log.user_info(cmd)
            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)
            log.user_info(self.tcl_ret)
            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_start_arp_study(self, src_host, dst_host):
        """
        功能描述：发送ARP请求，学习目的主机的MAC地址

        参数：
            src_host: 表示发送ARP请求的主机名,该主机必须是通过已创建的主机
            dst_host: 表示所请求的目的IP地址或者主机名称

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # build TCL Command
            cmd = "::ATTTestCenter::StartARPStudy %s %s "  % (src_host, dst_host)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_dhcp_server(self, port_name, router_name, dict_args):
        """
        功能描述：在端口创建DHCP server,并配置相关属性

        参数：
            port_name: 表示要创建DHCP server的端口别名，必须是预约端口时指定的名字
            router_name: 表示创建的DHCP server的名字
            dict_args: 表示可选参数字典，具体参数描述如下：
                router_id: 表示指定的RouterId，默认为1.1.1.1
                local_mac: 表示server接口MAC，默认为00:00:00:11:01:01
                tester_ip_addr: 表示server接口IP，默认为192.0.0.2
                pool_start: 表示地址池开始的IP地址，默认为192.0.0.1
                pool_num: 表示地址池的数量，默认为254
                pool_modifier: 表示地址池中变化的步长，步长从IP地址的最后一位依次增加，默认为1
                flag_gateway: 表示是否配置网关IP地址，默认为FALSE
                ipv4_gateway: 表示网关IP地址，默认为192.0.0.1
                active：表示DHCP server会话是否激活，默认为TRUE
                lease_time: 表示租约时间，单位为秒。默认为3600
                enable_vlan: 指明是否添加vlan，enable/disable, 默认为disable
                vlan_id: 指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100
                vlan_pri: 优先级,取值范围0-7，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateDHCPServer %s %s "  % (port_name, router_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "router_id":
                    cmd = "%s -RouterId %s" % (cmd, tmp_dict[var])

                elif var == "local_mac":
                    cmd = "%s -LocalMac %s" % (cmd, tmp_dict[var])

                elif var == "tester_ip_addr":
                    cmd = "%s -TesterIpAddr %s" % (cmd, tmp_dict[var])

                elif var == "pool_start":
                    cmd = "%s -PoolStart %s" % (cmd, tmp_dict[var])

                elif var == "pool_num":
                    cmd = "%s -PoolNum %s" % (cmd, tmp_dict[var])

                elif var == "pool_modifier":
                    cmd = "%s -PoolModifier %s" % (cmd, tmp_dict[var])

                elif var == "flag_gateway":
                    cmd = "%s -FlagGateway %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_gateway":
                    cmd = "%s -Ipv4Gateway %s" % (cmd, tmp_dict[var])

                elif var == "active":
                    cmd = "%s -Active %s" % (cmd, tmp_dict[var])

                elif var == "lease_time":
                    cmd = "%s -LeaseTime %s" % (cmd, tmp_dict[var])

                elif var == "enable_vlan":
                    cmd = "%s -EnableVlan %s" % (cmd, tmp_dict[var])

                elif var == "vlan_id":
                    cmd = "%s -VlanId %s" % (cmd, tmp_dict[var])

                elif var == "vlan_pri":
                    cmd = "%s -VlanPriority %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_dhcp_server fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_enable_dhcp_server(self, router_name):
        """
        功能描述：开启DHCP Server，开始协议仿真

        参数：
            router_name: 表示要开始协议仿真的DHCP Server名称

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::EnableDHCPServer %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_disable_dhcp_server(self, router_name):
        """
        功能描述：关闭DHCP Server，停止协议仿真

        参数：
            router_name: 表示要停止协议仿真的DHCP Server名称

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::DisableDHCPServer %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_dhcp_client(self, port_name, router_name, dict_args):
        """
        功能描述：在端口创建DHCP client,并配置相关属性

        参数：
            port_name: 表示要创建DHCP client的端口别名，必须是预约端口时指定的名字
            router_name: 表示创建的DHCP client的名字
            dict_args: 表示可选参数字典，具体参数描述如下：
                pool_name: 可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
                           注意：PoolName和routerName不要相同，默认为空。
                router_id: 表示指定的RouterId，默认为1.1.1.1
                local_mac: 表示server接口MAC，默认为00:00:00:11:01:01
                count: 表示模拟的主机数量，默认为1
                auto_retry_num: 表示最大尝试建立连接的次数，默认为1
                flag_gateway: 表示是否配置网关IP地址，默认为FALSE
                ipv4_gateway: 表示网关IP地址，默认为192.0.0.1
                active：表示DHCP server会话是否激活，默认为TRUE
                flag_broadcast：表示广播标识位，广播为TRUE，单播为FALSE，默认为TRUE
                enable_vlan: 指明是否添加vlan，enable/disable, 默认为disable
                vlan_id: 指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100
                vlan_pri: 优先级,取值范围0-7，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateDHCPClient %s %s "  % (port_name, router_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "pool_name":
                    cmd = "%s -PoolName %s" % (cmd, tmp_dict[var])

                elif var == "router_id":
                    cmd = "%s -RouterId %s" % (cmd, tmp_dict[var])

                elif var == "local_mac":
                    cmd = "%s -LocalMac %s" % (cmd, tmp_dict[var])

                elif var == "count":
                    cmd = "%s -Count %s" % (cmd, tmp_dict[var])

                elif var == "auto_retry_num":
                    cmd = "%s -AutoRetryNum %s" % (cmd, tmp_dict[var])

                elif var == "flag_gateway":
                    cmd = "%s -FlagGateway %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_gateway":
                    cmd = "%s -Ipv4Gateway %s" % (cmd, tmp_dict[var])

                elif var == "active":
                    cmd = "%s -Active %s" % (cmd, tmp_dict[var])

                elif var == "flag_broadcast":
                    cmd = "%s -FlagBroadcast %s" % (cmd, tmp_dict[var])

                elif var == "enable_vlan":
                    cmd = "%s -EnableVlan %s" % (cmd, tmp_dict[var])

                elif var == "vlan_id":
                    cmd = "%s -VlanId %s" % (cmd, tmp_dict[var])

                elif var == "vlan_pri":
                    cmd = "%s -VlanPriority %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_dhcp_client fail, errInfo:%s" % str_ret)

                # execute TCL Command
                self.tcl_ret = self.tcl.eval(cmd)

                # parse return value
                if self.tcl_ret:
                    n_ret = int(self.tcl_ret.split(' ', 1)[0])
                    str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                    str_ret = self._convert_coding(str_ret)

                else:
                    n_ret = ATT_TESTCENTER_FAIL
                    str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_enable_dhcp_client(self, router_name):
        """
        功能描述：使能DHCP Client

        参数：
            router_name: 表示要使能的DHCP Client名称

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::EnableDHCPClient %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_disable_dhcp_client(self, router_name):
        """
        功能描述：停止DHCP Client

        参数：
            router_name: 表示要停止的DHCP Client名称

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::DisableDHCPClient %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_method_dhcp_client(self, router_name, method):
        """
        功能描述：DHCP Client协议仿真

        参数：

            port_name: 表示要创建DHCP client的端口名
            router_name: 表示创建的DHCP client的名字
            method: 表示DHCP client仿真的方法，
                    Bind:       启动DHCP 绑定过程
                    Release:    释放绑定过程
                    Renew:      重新启动DHCP 绑定过程
                    Abort:      停止所有active Session的dhcp router，迫使其状态进入idle
                    Reboot:     迫使dhcp router重新reboot。即完成一个完整的过程，重新开始新的一个循环。
                                Reboot应该发送请求以前分配的IP地址。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::MethodDHCPClient %s %s"  % (router_name, method)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception as e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_igmp_host(self, port_name, host_name, dict_args):
        """
        功能描述：创建IGMP host，并配置相关属性

        参数：
            port_name: 表示要创建IGMP host的端口别名，必须是预约端口时指定的名字
            host_name: 表示创建的host的名字
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_mac: 表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02
                src_mac_step: 表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1
                ipv4_addr: 表示Host起始IPv4地址，默认为192.85.1.3
                ipv4_addr_gateway: 表示GateWay的IPv4地址，默认为192.85.1.1
                ipv4_addr_prefix_len: 表示Host IPv4地址Prefix长度，默认为24
                count: 表示Host IP、MAC地址个数，默认为1
                increase: 表示IP地址增幅，默认为1
                protocol_ver: 表示IGMP的版本。合法值：IGMPv1/IGMPv2/IGMPv3。默认为IGMPv2
                send_group_rate: 指明Igmp Host发送组播协议报文时，发送报文的速率，单位fps默认为线速
                active: 表示IGMP Host会话是否激活，默认为TRUE
                v1_router_present_timeout: 指明Igmp Host收到query与发送report报文的时间间隔，默认为400
                force_robust_join: 指明当第一个Igmpv1/v2 host加入group时，是否连续发送2个，默认为FALSE
                force_leave: 指明当除最后一个之外的Igmpv2 Host从group中离开时，是否发送leave报文，默认为FALSE
                unsolicited_report_interval: 指明Igmp host发送unsolicited report的时间间隔，默认为10
                insert_checksum_errors: 指明是否在Igmp Host发送的报文中插入Checksum error，默认为FALSE
                insert_length_errors: 指明是否在Igmp Host发送的报文中插入Length error，默认为FALSE
                ipv4_dont_fragment: 指明当报文长度大于MTU是是否需要分片，默认为FALSE
                enable_vlan: 指明是否添加vlan，enable/disable, 默认为disable
                vlan_id: 指明Vlan id的值，取值范围1-4096， 默认为100
                vlan_pri: 优先级,取值范围0-7，默认为0

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateIGMPHost %s %s "  % (port_name, host_name)

            # check user input args
            for var in tmp_dict.keys():

                if var == "src_mac":
                    cmd = "%s -SrcMac %s" % (cmd, tmp_dict[var])

                elif var == "src_mac_step":
                    cmd = "%s -SrcMacStep %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr":
                    cmd = "%s -Ipv4Addr %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr_gateway":
                    cmd = "%s -Ipv4AddrGateway %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_addr_prefix_len":
                    cmd = "%s -Ipv4AddrPrefixLen %s" % (cmd, tmp_dict[var])

                elif var == "count":
                    cmd = "%s -Count %s" % (cmd, tmp_dict[var])

                elif var == "increase":
                    cmd = "%s -Increase %s" % (cmd, tmp_dict[var])

                elif var == "protocol_ver":
                    cmd = "%s -ProtocolType %s" % (cmd, tmp_dict[var])

                elif var == "active":
                    cmd = "%s -Active %s" % (cmd, tmp_dict[var])

                elif var == "v1_router_present_timeout":
                    cmd = "%s -V1RouterPresentTimeout %s" % (cmd, tmp_dict[var])

                elif var == "force_robust_join":
                    cmd = "%s -ForceRobustJoin %s" % (cmd, tmp_dict[var])

                elif var == "force_leave":
                    cmd = "%s -ForceLeave %s" % (cmd, tmp_dict[var])

                elif var == "unsolicited_report_interval":
                    cmd = "%s -UnsolicitedReportInterval %s" % (cmd, tmp_dict[var])

                elif var == "insert_checksum_errors":
                    cmd = "%s -InsertCheckSumErrors %s" % (cmd, tmp_dict[var])

                elif var == "insert_length_errors":
                    cmd = "%s -InsertLengthErrors %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_dont_fragment":
                    cmd = "%s -Ipv4DontFragment %s" % (cmd, tmp_dict[var])

                elif var == "send_group_rate":
                    cmd = "%s -SendGroupRate %s" % (cmd, tmp_dict[var])

                elif var == "enable_vlan":
                    cmd = "%s -EnableVlan %s" % (cmd, tmp_dict[var])

                elif var == "vlan_id":
                    cmd = "%s -VlanId %s" % (cmd, tmp_dict[var])

                elif var == "vlan_pri":
                    cmd = "%s -VlanPriority %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_igmp_host fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_igmp_group_pool(self, host_name, group_pool_name, start_ip, dict_args):
        """
        功能描述：创建IGMP GroupPool, 并配置相关属性

        参数：
            host_name: 表示要创建IGMP GroupPool的主机名
            group_pool_name: 表示IGMP Group的名称标识，要求在当前 IGMP Host 唯一
            start_ip: 表示Group 起始 IP 地址
            dict_args: 表示可选参数字典,具体参数描述如下：
                prefix_len: 表示IP 地址前缀长度，取值范围：5到32，默认为24
                group_cnt: 表示Group 个数，默认为1
                group_increment: 表示Group IP 地址的增幅，默认为1
                filter_mode: Specific Source Filter Mode(IGMPv3), 取值范围为Include Exclude，默认为Exclude
                src_start_ip: 表示起始主机 IP 地址（IGMPv3），默认为192.168.1.2
                src_cnt: 表示主机地址个数（IGMPv3），默认为1
                src_increment: 表示主机 IP 地址增幅（IGMPv3），默认为1
                src_prefix_len: 表示主机 IP 地址前缀长度（IGMPv3），取值范围：1到32，默认为24

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::SetupIGMPGroupPool %s %s %s "  % (host_name, group_pool_name, start_ip)

            # check user input args
            for var in tmp_dict.keys():

                if var == "prefix_len":
                    cmd = "%s -PrefixLen %s" % (cmd, tmp_dict[var])

                elif var == "group_cnt":
                    cmd = "%s -GroupCnt %s" % (cmd, tmp_dict[var])

                elif var == "group_increment":
                    cmd = "%s -GroupIncrement %s" % (cmd, tmp_dict[var])

                elif var == "filter_mode":
                    cmd = "%s -FilterMode %s" % (cmd, tmp_dict[var])

                elif var == "src_start_ip":
                    cmd = "%s -SrcStartIP %s" % (cmd, tmp_dict[var])

                elif var == "src_cnt":
                    cmd = "%s -SrcCnt %s" % (cmd, tmp_dict[var])

                elif var == "src_increment":
                    cmd = "%s -SrcIncrement %s" % (cmd, tmp_dict[var])

                elif var == "src_prefix_len":
                    cmd = "%s -SrcPrefixLen %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_igmp_group_pool fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_send_igmp_leave(self, host_name, group_pool_list=""):
        """
        功能描述：向指定组播组发送IGMP Leave报文

        参数：
            host_name: 表示要发送报文的host名字
            group_pool_list: 表示IGMP Group 的名称标识列表,不指定表示针对所有group

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # 将group_pool_list字符串化
            str_group_pool_list = ""

            # 多个group pool和单个group pool需要分开处理
            if type(group_pool_list) == type([]):
                for group_pool in group_pool_list:
                    str_group_pool_list = "%s %s" % (str_group_pool_list, group_pool)
            else:
                str_group_pool_list = group_pool_list

            # build TCL Command
            cmd = "::ATTTestCenter::SendIGMPLeave %s %s"  % (host_name, str_group_pool_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_send_igmp_report(self, host_name, group_pool_list=""):
        """
        功能描述：向指定组播组发送IGMP report报文

        参数：
            host_name: 表示要发送报文的host名字
            group_pool_list: 表示IGMP Group 的名称标识列表,不指定表示针对所有group

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            # 将group_pool_list字符串化
            str_group_pool_list = ""

            # 多个group pool和单个group pool需要分开处理
            if type(group_pool_list) == type([]):
                for group_pool in group_pool_list:
                    str_group_pool_list = "%s %s" % (str_group_pool_list, group_pool)
            else:
                str_group_pool_list = group_pool_list

            # build TCL Command
            cmd = "::ATTTestCenter::SendIGMPReport %s %s"  % (host_name, str_group_pool_list)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_igmp_router(self, port_name, router_name, router_ip, dict_args):
        """
        功能描述：创建IGMP router,并配置相关属性

        参数：
            port_name: 表示要创建IGMP router的端口名，这里的端口名是预约端口时指定的名字
            router_name: 表示创建的IGMP router的名字
            router_ip: 表示 IGMP Router 的接口 IPv4 地址
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_mac: 表示源Mac，创建多个Router时，默认值按照步长1递增
                protocol_type: 表示Protocol的类型。合法值：IGMPv1/IGMPv2/IGMPv3。默认为IGMPv2
                ignore_v1reports: 指明是否忽略接收到的 IGMPv1 Host的报文，默认为False
                ipv4_dont_fragment: 指明当报文长度大于 MTU 时，是否进行分片，默认为False
                last_member_query_count:: 表示在认定组中没有成员之前发送的特定组查询的次数，默认为2
                last_member_query_interval: 表示在认定组中没有成员之前发送指定组查询报文的 时间间隔（单位 ms），默认为1000
                query_interval: 表示发送查询报文的时间间隔（单位 s），，默认为32
                query_response_uper_bound: 表示Igmp Host对于查询报文的响应的时间间隔的上限值（单位 ms），默认为10000
                startup_query_count: 指明Igmp Router启动之初发送的Query报文的个数，取值范围：1-255,默认为2
                active: 表示IGMP Router会话是否激活，默认为TRUE

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateIGMPRouter %s %s %s "  % (port_name, router_name, router_ip)

            # check user input args
            for var in tmp_dict.keys():

                if var == "src_mac":
                    cmd = "%s -SrcMac %s" % (cmd, tmp_dict[var])

                elif var == "protocol_type":
                    cmd = "%s -ProtocolType %s" % (cmd, tmp_dict[var])

                elif var == "IgnoreV1Reports":
                    cmd = "%s -ignore_v1reports %s" % (cmd, tmp_dict[var])

                elif var == "ipv4_dont_fragment":
                    cmd = "%s -Ipv4DontFragment %s" % (cmd, tmp_dict[var])

                elif var == "last_member_query_count":
                    cmd = "%s -LastMemberQueryCount %s" % (cmd, tmp_dict[var])

                elif var == "last_member_query_interval":
                    cmd = "%s -LastMemberQueryInterval %s" % (cmd, tmp_dict[var])

                elif var == "query_interval":
                    cmd = "%s -QueryInterval %s" % (cmd, tmp_dict[var])

                elif var == "query_response_uper_bound":
                    cmd = "%s -QueryResponseUperBound %s" % (cmd, tmp_dict[var])

                elif var == "startup_query_count":
                    cmd = "%s -StartupQueryCount %s" % (cmd, tmp_dict[var])

                elif var == "active":
                    cmd = "%s -Active %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_igmp_router fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_start_igmp_query(self, router_name):
        """
        功能描述：开始通用IGMP查询

        参数：
            router_name: 表示要开始通用IGMP查询的IGMP Router名

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::StartIGMPRouterQuery %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_stop_igmp_query(self, router_name):
        """
        功能描述：停止通用IGMP查询

        参数：
            router_name: 表示要停止通用IGMP查询的IGMP Router名

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::StopIGMPRouterQuery %s"  % router_name

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value, in normal case, return valus is {{num} {string}}
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_ipv4_stream(self, port_name, stream_name,
                                            src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条IPv4的bound流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s"  % (port_name, stream_name, src_host, dst_host)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_ipv4_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_ipv6_stream(self, port_name, stream_name,
                                            src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条IPv6的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s"  % (port_name, stream_name, src_host, dst_host)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_ipv6_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_tcp_stream(self, port_name, stream_name,
                                        src_port, dst_port, src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条TCP IPv4的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_port: TCP数据流的源端口
            dst_port:TCP数据流的目的端口
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_port_count: TCP数据流的源端口的个数，默认为1
                dst_port_count: TCP数据流的目的端口的个数，默认为1
                inc_src_port: 源端口递增值，默认为1
                inc_dst_port: 目的端口递增值，默认为1
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s"  % (port_name, stream_name, src_host, dst_host)

            # add L4
            cmd = "%s -L4 TCP -TcpSrcPort %s -TcpDstPort %s" % (cmd, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -TcpSrcPortMode increment -TcpSrcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -TcpDstPortMode increment -TcpDstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "inc_src_port":
                    cmd = "%s -TcpSrcPortStep %s" % (cmd, tmp_dict[var])

                elif var == "inc_dst_port":
                    cmd = "%s -TcpDstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_tcp_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_tcpv6_stream(self, port_name, stream_name,
                                            src_port, dst_port, src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条TCP IPv6的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_port: TCP数据流的源端口
            dst_port:TCP数据流的目的端口
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_port_count: TCP数据流的源端口的个数，默认为1
                dst_port_count: TCP数据流的目的端口的个数，默认为1
                inc_src_port: 源端口递增值，默认为1
                inc_dst_port: 目的端口递增值，默认为1
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s -Ipv6NextHeader 6"  % (port_name, stream_name, src_host, dst_host)

            # add L4
            cmd = "%s -L4 TCP -TcpSrcPort %s -TcpDstPort %s" % (cmd, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -TcpSrcPortMode increment -TcpSrcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -TcpDstPortMode increment -TcpDstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "inc_src_port":
                    cmd = "%s -TcpSrcPortStep %s" % (cmd, tmp_dict[var])

                elif var == "inc_dst_port":
                    cmd = "%s -TcpDstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_tcpv6_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_udp_stream(self, port_name, stream_name,
                                            src_port, dst_port, src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条UDP IPv4的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_port: UDP数据流的源端口
            dst_port: UDP数据流的目的端口
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_port_count: UDP数据流的源端口的个数，默认为1
                dst_port_count: UDP数据流的目的端口的个数，默认为1
                inc_src_port: 源端口递增值，默认为1
                inc_dst_port: 目的端口递增值，默认为1
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s"  % (port_name, stream_name, src_host, dst_host)

            # add L4
            cmd = "%s -L4 UDP -UdpSrcPort %s -UdpDstPort %s" % (cmd, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -UdpSrcPortMode increment -UdpSrcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -UdpDstPortMode increment -UdpDstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "inc_src_port":
                    cmd = "%s -UdpSrcStep %s" % (cmd, tmp_dict[var])

                elif var == "inc_dst_port":
                    cmd = "%s -UdpDstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_udp_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_create_udpv6_stream(self, port_name, stream_name,
                                            src_port, dst_port, src_host, dst_host, dict_args):
        """
        功能描述：创建一条或多条UDP IPv6的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字
            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作
            src_port: UDP数据流的源端口
            dst_port: UDP数据流的目的端口
            src_host: 指明发送端主机名
            dst_host: 指明接收端主机名
            dict_args: 表示可选参数字典,具体参数描述如下：
                src_port_count: UDP数据流的源端口的个数，默认为1
                dst_port_count: UDP数据流的目的端口的个数，默认为1
                inc_src_port: 源端口递增值，默认为1
                inc_dst_port: 目的端口递增值，默认为1
                frame_len: 指明数据帧长度 单位为byte，默认为128
                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:

            tmp_dict = dict_args

            # build TCL Command
            cmd = "::ATTTestCenter::CreateEmptyStream %s %s -StreamType host \
                   -SrcPoolName %s -DstPoolName %s -Ipv6NextHeader 17"  % (port_name, stream_name, src_host, dst_host)

            # add L4
            cmd = "%s -L4 UDP -UdpSrcPort %s -UdpDstPort %s" % (cmd, src_port, dst_port)

            # check user input args
            for var in tmp_dict.keys():

                if var == "frame_len":
                    cmd = "%s -frameLen %s" % (cmd, tmp_dict[var])

                elif var == "src_port_count":
                    cmd = "%s -UdpSrcPortMode increment -UdpSrcPortCount %s" % (cmd, tmp_dict[var])

                elif var == "dst_port_count":
                    cmd = "%s -UdpDstPortMode increment -UdpDstPortCount %s" % (cmd, tmp_dict[var])

                elif var == "inc_src_port":
                    cmd = "%s -UdpSrcStep %s" % (cmd, tmp_dict[var])

                elif var == "inc_dst_port":
                    cmd = "%s -UdpDstPortStep %s" % (cmd, tmp_dict[var])

                elif var == "profile_name":
                    cmd = "%s -profileName %s" % (cmd, tmp_dict[var])

                else:
                    str_ret = "unsupport argument %s." % var
                    raise RuntimeError("execute testcenter_create_udpv6_stream fail, errInfo:%s" % str_ret)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_save_config_as_xml(self, path):
        """
        功能描述：将脚本配置保存为xml文件

        参数：
            path: 指定保存的xml文件的全路径，包括目录和文件名

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        useless = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::SaveConfigAsXML %s" % path

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret


    def testcenter_set_stream_scheduling_mode(self, port_name, scheduling_mode="RATE_BASED"):
        """
        功能描述：设置端口上数据流的调度模式

        参数：
            port_name: 需要配置数据流调度模式的端口名，必须是预约端口时指定的名字
            scheduling_mode：数据流的调度模式，取值范围为：PORT_BASED | RATE_BASED | PRIORITY_BASED，默认为RATE_BASED
        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::SetStreamSchedulingMode %s %s"  % (port_name,scheduling_mode)

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return n_ret, str_ret


    def testcenter_cleanup_test(self):
        """
        功能描述：消除测试，释放资源，每次测试结束必须调用该方法

        参数： 无

        """

        n_ret = ATT_TESTCENTER_SUC
        str_ret = ""
        useless = ""

        try:
            # build TCL Command
            cmd = "::ATTTestCenter::CleanupTest %s" % useless

            # execute TCL Command
            self.tcl_ret = self.tcl.eval(cmd)

            # parse return value
            if self.tcl_ret:
                n_ret = int(self.tcl_ret.split(' ', 1)[0])
                str_ret = self.tcl_ret.split(' ', 1)[1].strip('{}')
                str_ret = self._convert_coding(str_ret)

            else:
                n_ret = ATT_TESTCENTER_FAIL
                str_ret = u"执行TCL command %s 失败，无错误信息返回。" % cmd

        except Exception,e:
            n_ret = ATT_TESTCENTER_FAIL
            str_ret = u"执行TCL command %s 发生异常，错误信息为：%s" % (cmd, e)

        return  n_ret, str_ret
