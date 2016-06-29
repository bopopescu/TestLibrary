# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: TestCenter
#  function: 提供TestCenter相关操作的关键字，包括连接TestCenter，预约端口，
#            配置端口，配流，发流，抓包，统计结果，IGMP报文模拟等
#  Author: ATT development group
#  version: V1.0
#  date: 2013.4.5
#  change log:
#  lana     20130405    created
#  lana     20130524    添加对入参ip地址的合法性进行检测
#
# ***************************************************************************

import os
from os.path import join, dirname
import subprocess
import time
from datetime import datetime

from robot import utils
from robot.libraries.BuiltIn import BuiltIn
from robot.api import logger

from TestCenter.client import ATTTestCenter
import attcommonfun
from attcommonfun import *
import attlog as log


VERSION = '1.0.0'
TESTCENTER_SUC  = 0
TESTCENTER_FAIL = -1


class TestCenter(object):

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION

    def __init__(self):
        """
        initial
        """

        self.obj = None                               # 保存ATTTestCenter对象
        self.proc_obj = None                          # 保存TestCenter服务器进程对象
        self.start_flag = False                       # TestCenter测试开始的标志，如果测试未开始，不需要释放资源
        self.dict_port_pcap_path = {}                 # 保存各个端口对应的抓包文件的路径


    def _format_args(self, list_args):
        """
        功能描述：将元组格式的参数列表转化为字典格式
                  eg: list_args is ("key1=value1", "key2=value2")
                  dict_ret is {"key1":"value1", "key2":"value2"}

        参数： list_args: 元组格式的参数列表

        返回值：执行成功，返回(TESTCENTER_SUC(0)，转化后的字典)
                执行失败，返回(TESTCENTER_FAIL(-1)，错误信息)
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        dict_ret = {}

        for i in [1]:
            try:
                if type(list_args) != type(()):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"传入参数格式不对!"
                    break
                for var in list_args:
                    tmp_key = var.split('=', 1)[0]
                    tmp_value = var.split('=', 1)[1]
                    dict_ret.update({tmp_key:tmp_value})

            except Exception, e:
                n_ret = TESTCENTER_FAIL
                str_ret = u"转化参数发生异常，错误信息为%s" % e
                break

        if n_ret == TESTCENTER_FAIL:
            return n_ret, str_ret

        return n_ret, dict_ret


    def _get_default_log_dir(self):
        """
        功能描述: 获取默认的testcenter的log相关信息的保存的路径

        参数：无

        返回值：执行成功，返回(TESTCENTER_SUC(0)，默认的文件保存的路径)
                执行失败，返回(TESTCENTER_FAIL(-1)，错误信息)

        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        try:

            variables = BuiltIn().get_variables()
            log_file = variables['${LOGFILE}']
            log_dir = dirname(log_file) if log_file != 'NONE' else '.'

            # 在log目录下创建testcenter目录，用于保存testcenter相关的log信息
            tc_log_path = join(log_dir, "testcenter")
            if not os.path.exists(tc_log_path):
                os.mkdir(tc_log_path)

            str_ret = tc_log_path

        except Exception,e:
            str_ret = u"获取当前测试的log路径发生异常, 错误信息为：%s" % e
            n_ret = TESTCENTER_FAIL

        return n_ret, str_ret


    def _link_capture_file(self, path):
        """
        功能描述：将抓包文件链接到log文件中

        参数： path：抓包文件全路径

        返回值：执行成功，返回(TESTCENTER_SUCCESS(0)，成功信息)
                执行失败，返回(TESTCENTER_FAIL(-1)，错误信息)
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:

            try:
                variables = BuiltIn().get_variables()
                outdir = variables['${OUTPUTDIR}']
                log_file = variables['${LOGFILE}']
                log_dir = dirname(log_file) if log_file != 'NONE' else '.'

                tmp_log_dir = join(outdir, log_dir)

            except Exception,e:
                str_ret = u"获取当前测试的log路径发生异常，错误信息为：%s" % e
                n_ret = TESTCENTER_FAIL
                break

            try:
                link = utils.get_link_path(path, tmp_log_dir)
                logger.info("Capture file saved to '<a href=\"%s\">%s</a>'."
                        % (link, path), html=True)

                str_ret = u"链接报文文件到log文件中成功！"

            except Exception, e:
                str_ret = u"在log文件中链接抓包文件发生异常，错误信息为：%s" % e
                n_ret = TESTCENTER_FAIL
                break

        return n_ret, str_ret


    def _check_ipaddr_validity(self, ip_addr, ip_addr_type="unicast"):
        """
        功能描述：检查IP地址是否合法，合法返回True，非法返回False

        参数： ip_addr: 待检查的IP地址
               ip_addr_type: IP地址类型，暂时分单播和组播，取值范围 unicast | multicast
        """

        if ip_addr_type == "unicast":
            regex_ip = '^(2[0-4]\d|25[0-5]|[01]?\d\d?)\.((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){2}(2[0-4]\d|25[0-5]|[01]?\d\d?)$'
        elif ip_addr_type == "multicast":
            regex_ip = '^(2[2][4-9]|2[3][0-9])\.((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){2}(2[0-4]\d|25[0-5]|[01]?\d\d?)$'
        else:
            return False
        if re.search(regex_ip, ip_addr) is not None:
            return True
        else:
            return False


    def testcenter_connect(self, chassis_addr):
        """
        功能描述：使用TestCenter机框IP地址连接TestCenter

        参数： chassis_addr: TestCenter机框IP地址

        Example:
        | testcenter connect  | 192.168.11.11  |       |
        """

        # 设置系统默认编码，解决打印乱码的问题
        # import sys
        # if 'utf-8' != sys.getdefaultencoding():
        #    reload(sys)
        #    sys.setdefaultencoding('utf-8')

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:

            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(chassis_addr):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % chassis_addr
                break

            # 开启TestCenter server端服务
            try:
                # 获取server端启动文件的全路径，同时支持tcl文件和tbc文件
                cur_file_path = os.path.abspath(__file__)
                file_dir = join(dirname(cur_file_path), 'server')
                file_path = join(file_dir, 'ATTTestCenter.tcl')
                if not os.path.exists(file_path):
                    file_path = join(file_dir, 'ATTTestCenter.tbc')

                # 获取log路径，创建log文件，用于保存TestCenter server端的log信息
                n_ret, str_ret = self._get_default_log_dir()
                if n_ret == TESTCENTER_SUC:
                    curtime = datetime.now()
                    tc_log_file_name = "testcenter_%s-%s-%s_%s-%s-%s.txt" % (curtime.year, curtime.month,
                                       curtime.day, curtime.hour,
                                       curtime.minute, curtime.second)
                    file_name = join(str_ret, tc_log_file_name)
                else:
                    break

                self.log_file_id = open(file_name, "a+")

                # 通过子进程运行tclsh 启动TestCenter server端
                tclsh_path = join(dirname(dirname(dirname(cur_file_path))), "vendor", "tcl", "bin", "tclsh" )
                cmd = '%s %s' %(tclsh_path, file_path)
                self.proc_obj = subprocess.Popen(cmd, shell=True, stdout=self.log_file_id)

            except Exception, e:
                n_ret = TESTCENTER_FAIL
                str_ret = u"启动TestCenter服务发生异常，错误信息为: %s" % e
                break

            # 设置testcenter server端url
            self.obj = ATTTestCenter.ATTTestCenter()   # 初始化ATTTestCenter对象

            n_ret, str_ret = self.obj.testcenter_set_remote_url("http://localhost:51800")
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

            # 等待服务器起来
            wait_couter = 20      # 等待计数器
            while wait_couter:
                time.sleep(5)
                n_ret, str_ret = self.obj._check_server_is_start()
                if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                    log.debug_err(str_ret)
                    wait_couter -= 1
                else:
                    log.debug_info(str_ret)
                    break

            # 连接TestCenter
            n_ret, str_ret = self.obj.testcenter_connect(chassis_addr)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

            # 成功连接TestCenter，设置开始标志为True
            self.start_flag = True

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return str_ret


    def testcenter_reserve_port(self, port_name, port_location, port_type='Ethernet'):
        """
        功能描述：预约端口，需要指明端口的别名和端口的位置

        参数：

            port_name: 端口别名，用于后面对该端口进行其他操作

            port_location: 端口的位置，格式为"板卡号/端口号",例如预约板卡1上的1号端口："1/1"

            port_type: 端口类型，默认为Ethernet(暂时只支持Ethernet)

        Example:
        | testcenter reserve port | port1  | 1/1 |  |
        | testcenter reserve port | port2  | 1/2 |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_reserve_port(port_name, port_location, port_type)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return str_ret


    def testcenter_config_port(self, port_name, *args):
        """
        功能描述：配置端口属性

        参数：

            port_name: 表示要配置的端口名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                media_type: 表示端口介质类型，取值范围为COPPER、FIBER。默认为COPPER

                link_speed: 表示端口速率，取值范围为10M,100M,1G,10G,AUTO。默认为AUTO

                duplex_mode: 表示端口的双工模式，取值范围为FULL、HALF。默认为FULL

                auto_neg: 表示是否开启端口的自动协商模式，取值范围为Enable、Disable。
                          当设置为Enable时，link_speed和duplex_mode两个参数的设置无效。默认为Enable

                flow_control: 表示是否开启端口的流控功能，取值范围为ON、OFF。默认为OFF

                mtu_size: 表示端口的MTU。默认为1500

                master_or_slave: 表示自协商模式，取值范围为MASTER,SLAVE。
                                 只有当auto_neg为Enable时，该参数才有效。默认为MASTER

                port_mode: 仅当link_speed为10G时,该参数才有效，取值范围为LAN、WAN。默认为LAN

        Example:
        | testcenter config port | port1 | link_speed=10M   | auto_neg=Disable |
        | testcenter config port | port2 | duplex_mode=HALF | auto_neg=Disable |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_config_port(port_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_get_port_state(self, port_name, option):
        """
        功能描述：获取端口属性的状态

        参数：

            port_name: 表示要获取端口状态的端口名

            option:  表示端口属性项，取值范围为PhyState, LinkState, LinkSpeed, DuplexMode

        Example:
        | ${ret} | testcenter get port state | port1 | PhyState   |  |
        | ${ret} | testcenter get port state | port1 | LinkState  |  |
        | ${ret} | testcenter get port state | port1 | LinkSpeed  |  |
        | ${ret} | testcenter get port state | port1 | DuplexMode |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        state = ""                  # 用于存储端口属性的状态

        n_ret, str_ret, state = self.obj.testcenter_get_port_state(port_name, option)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  state


    def testcenter_create_profile(self, port_name, profile_name, *args):
        """
        功能描述：在指定端口创建profile, 设置发流时的特性参数，注意，
                  如果是多条流引用同一个profile，traffic_load 和 frame_num会均分到各条流上

        参数：

            port_name: 表示要创建profile的端口名

            profile_name: 要创建的profile的名字，该名字可用于后面对profile的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                data_type: 数据流的类型，是持续的还是突发的，取值范围constant | burst，默认为constant

                traffic_load: 流量的负荷（结合流量的单位来设置），默认为10

                traffic_load_unit: 流量的单位，取值范围fps | kbps | mbps | percent，默认为percent

                burst_size: 当data_type是burst时，连续发送的报文数量，默认为1

                frame_num: 一次发送报文的数量（注意：设置了该变量，data_type自动变为burst），应设置为 burst_size 的整数倍，默认为100

        Example:
        | testcenter create profile | port1 | profile1 | data_type=burst | burst_size=5           | frame_num=5000 |
        | testcenter create profile | port2 | profile2 | traffic_load=20 | traffic_load_unit=kbps |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_profile(port_name, profile_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_empty_stream(self, port_name, stream_name, *args):
        """
        功能描述：在端口上创建空流，仅创建流的名字，帧数据长度等属性，流的其他属性通过
                  ADD PDU的方式构造

        参数：

            port_name: 表示要创建流的端口名

            stream_name: 指明创建的流的名字，该名字可用于后面对流的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                frame_len: 指明数据帧长度，单位为byte，默认为128

                frame_len_mode: 指明数据帧长度的变化方式，取值范围为：AUTO | DECR | FIXED | IMIX | INCR | RANDOM
                                参数设置为random时，随机变化范围为:( frame_len至frame_len + frame_len_count-1)
                                默认为FIXED

                frame_len_step: 表示数据帧长度的变化步长，默认为1

                frame_len_count: 表示数据帧长度的数量，默认为1

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

                fill_type: 指明Payload的填充方式，取值范围为CONSTANT | INCR |DECR | PRBS，默认为CONSTANT

                constant_fill_pattern: 当FillType为Constant的时候，相应的填充值。格式是十六进制，取值范围为0x0到0xffff,默认为0x0

                enable_fcserror_insertion: 指明是否插入CRC错误帧，取值范围为: true | false，默认为false

                insert_signature: 指明是否在数据流中插入signature field，取值：true | false  默认为true，插入signature field

        Example:
        | testcenter create empty stream | port1 | stream1 | frame_len=256 |
        | testcenter create empty stream | port2 | stream2 | constant_fill_pattern=0xaa |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_empty_stream(port_name, stream_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_ethernet_header(self, header_name, src_mac, dst_mac, *args):
        """
        功能描述：创建Ethernet报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            src_mac: 表示源MAC

            dst_mac: 表示目的MAC

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                sa_repeat_mode: 表示源MAC的变化方式，fixed | incr | decr，默认为fixed

                sa_step: 表示源MAC的变化步长，默认为00:00:00:00:00:01

                da_repeat_mode: 表示目的MAC的变化方式，fixed | incr | decr，默认为fixed

                da_step: 表示目的MAC的变化步长，默认为00:00:00:00:00:01

                num_da: 表示变化的目的MAC数量，默认为1

                num_sa: 表示变化的源MAC数量，默认为1

                eth_type: 表示以太网类型，默认值为auto，即此字段自动与添加的协议头相匹配,取值范围为0x0-0xFFFF。

                eth_type_mode: 表示eth_type变化的方式，fixed | incr | decr，默认为fixed

                eth_type_step: 表示eth_type变化的步长，默认为1

                eth_type_count: 表示eth_type的数量，默认为1

        Example:
        | testcenter create ethernet header | eth_header1 | 00:00:00:00:00:01 | 00:00:00:00:00:02 |  |
        | testcenter create ethernet header | eth_header2 | 00:00:00:00:00:03 | 00:00:00:00:00:04 |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_ethernet_header(header_name, src_mac, dst_mac, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_vlan_header(self, header_name, vlan_id, *args):
        """
        功能描述：创建vlan报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            vlan_id: 表示Vlan值

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                user_priority: 表示用户优先级，取值范围为0-7，默认为0

                cfi: 表示Cfi值，默认为0

                mode: 表示Vlan值的变化方式 fixed | incr | decr，默认为fixed

                repeat: 表示Vlan变化数量，默认为1

                step: 表示Vlan变化步长，取值必须是2的幂（1,2,4,8...），默认为1

                maskval: 表示vlan的掩码，默认为"FFF"

                protocol_tagId: 表示TPID,取值8100、9100等16进制数值，默认为8100

                vlan_stack: 表示Vlan的多层标签，取值范围是Single | Multiple，默认为Single

                stack: 表示属于多层标签的哪一层，默认为1

        Example:
        | testcenter create vlan header | vlan_header1 | 100 | vlan_stack=Multiple | stack=1 |
        | testcenter create valn header | vlan_header2 | 200 | vlan_stack=Multiple | stack=2 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_vlan_header(header_name, vlan_id, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_ipv4_header(self, header_name, src_ip, dst_ip, *args):
        """
        功能描述：创建IPV4报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            src_ip: 表示源IP

            dst_ip: 表示目的IP

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                precedence: 表示Tos中的优先转发，取值范围0-7，默认为0

                delay: 表示Tos的最小时延，取值normal、low，默认为normal，
                       注意该参数与throughput,reliability和cost四个参数只有一个可以设置为非normal.

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

                ip_protocol: 表示协议类型，10进制取值或者枚举（1 (ICMP), 2 (IGMP), 6 (TCP), 17 (UDP)...），默认为6(TCP)

                ip_protocol_mode: 表示ip_protocol的变化方式，fixed |incr | decr，默认为fixed

                ip_protocol_step: 表示ip_protocol的变化步长，10进制，默认为1

                ip_protocol_count: 表示ip_protocol数量，10进制，默认为1

                use_valid_checksum: 表示CRC是否自动计算，默认为true

                src_ip_mask: 表示源IP的掩码，默认为"255.0.0.0"

                src_ip_mode: 表示源IP的变化类型fixed | random | incr | decr，默认为fixed

                src_ip_offset: 指定开始变化的位置，默认为0

                src_ip_repeat_count: 表示源IP的变化数量，默认为1

                dst_ip_mask: 表示目的IP的掩码，默认为"255.0.0.0"

                dst_ip_mode: 表示目的IP的变化类型其取值范围为：fixed | random | incr | decr，默认为fixed

                dst_ip_offset: 指定开始变化的位置，默认为0

                dst_ip_repeat_count: 表示目的IP的变化数量，默认为1

                dst_dut_ip_addr: 指定对应DUT的ip地址，即网关，默认为192.85.1.1

                qos_mode: 表示Qos的类型，取值范围是tos | dscp，默认为dscp

                qos_value: 表示Qos取值，Dscp取值0~63，tos取值0~255，十进制取值，默认为 0

                qos_value_enable: 当qos_mode为tos时，设置qos_value_enable为False，则delay，throughput，reliability，cost参数生效，
                                  否则，使用qos_value的值，默认为True

        Example:
        | testcenter create ipv4 header | ipv4_header1 | 10.10.10.10 | 20.20.20.20 | throughput=High |
        | testcenter create ipv4 header | ipv4_header2 | 10.10.10.20 | 20.20.20.10 | dst_dut_ip_addr=10.10.10.1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(src_ip):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % src_ip
                break

            if not self._check_ipaddr_validity(dst_ip):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % dst_ip
                break

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            if "dst_dut_ip_addr" in dict_args:
                if not self._check_ipaddr_validity(dict_args["dst_dut_ip_addr"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["dst_dut_ip_addr"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_ipv4_header(header_name, src_ip, dst_ip, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_tcp_header(self, header_name, src_port, dst_port, *args):
        """
        功能描述：创建TCP报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            src_port: 表示源端口

            dst_port: 表示目的端口

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

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

        Example:
        | testcenter create tcp header | tcp_header1 | 1000 | 2000 | urgent_pointer_valid=True  |
        | testcenter create tcp header | tcp_header2 | 1001 | 2002 | window=5  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_tcp_header(header_name, src_port, dst_port, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_udp_header(self, header_name, src_port, dst_port, *args):
        """
        功能描述：创建UDP报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            src_port: 表示源端口

            dst_port: 表示目的端口

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_port_mode: 表示端口改变模式 fixed | incr | decr，默认为fixed

                src_port_count: 表示数量，默认为1

                src_port_step: 表示步长，默认为1

                dst_port_mode: 表示端口改变模式 fixed | incr | decr，默认为fixed

                dst_port_count: 表示数量，默认为1

                dst_port_step: 表示步长，默认1

                checksum: 表示校验和，默认为0

                enable_checksum: 表示是否使能校验和，默认为Enable

                length: 表示长度,默认为10

                length_override: 表示长度是否可重写，默认为Disable

                enable_checksum_override: 表示是否使能校验和重写，默认为Disable

                checksum_mode: 表示校验和类型，默认为auto

        Example:
        | testcenter create udp header | udp_header1 | 2000 | 3000 |   |
        | testcenter create udp header | udp_header2 | 2100 | 3100 |   |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_udp_header(header_name, src_port, dst_port, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def _testcenter_create_mpls_header(self, header_name, *args):
        """
        功能描述：创建MPLS报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                mpls_type: 表示MPLS标记类型，mplsUnicast | mplsMulticast，默认为mplsUnicast

                label: 表示MPLS标记值，默认为0

                label_count: 表示标记变化的个数，默认为1

                label_mode: 表示标记改变的模式，fixed | incr | decr，默认为fixed

                label_step: 表示标记变化的步长，默认为1

                experimental_use: 表示MPLS的qos的优先级，取值范围为0-7，默认为0

                time_to_live: 表示TTL，默认为64

                bottom_of_stack: 表示MPLS标记栈位置，默认为0

        Example:
        | testcenter create mpls header | mpls_header1 | mpls_type=mplsMulticast |
        | testcenter create mpls header | mpls_header2 | experimental_use=3 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_mpls_header(header_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_ipv6_header(self, header_name, *args):
        """
        功能描述：创建IPV6报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                flow_label: 表示Flow 标记值, 默认为0

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

        Example:
        | testcenter create ipv6 header | ipv6_header1 | src_addr=2000::100 | dst_addr=3000::200 |
        | testcenter create ipv6 header | ipv6_header2 | hop_limit=64 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        flow_label = 0

        for i in [1]:

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 如果用户配置了flow_label,使用用户配置的值，否则使用默认值
            if "flow_label" in dict_args:
                flow_label = dict_args["flow_label"]
                del dict_args["flow_label"]

            n_ret, str_ret = self.obj.testcenter_create_ipv6_header(header_name, flow_label, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def _testcenter_create_pos_header(self, header_name, *args):
        """
        功能描述：创建POS报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                hdlc_address: 表示接口地址，默认为FF

                hdlc_control: 表示接口控制类型，默认为03

                hdlc_protocol: 表示接口链路层协议，默认为0021

        Example:
        | testcenter create pos header | pos_header1 |  |
        | testcenter create pos header | pos_header2 |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_pos_header(header_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def _testcenter_create_hdlc_header(self, header_name, *args):
        """
        功能描述：创建hdlc报头PDU

        参数：

            header_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                hdlc_address: 表示接口地址，默认为0F

                hdlc_control: 表示接口控制类型，默认为00

                hdlc_protocol: 表示接口链路层协议，默认为0800

        Example:
        | testcenter create hdlc header | hdlc_header1 |   |
        | testcenter create hdlc header | hdlc_header2 |   |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_hdlc_header(header_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_dhcp_packet(self, packet_name, op, htype, hlen,
                                      hops, xid, secs, bflag, mbz15, ciaddr,
                                      yiaddr, siaddr, giaddr, chaddr, *args):
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

            bflag: 表示广播标志位, 可设置 0或者1

            mbz15: 表示广播标志位后的 15 位 bit 位

            ciaddr: 表示客户端 IP 地址，格式为0.0.0.0

            yiaddr: 表示测试机 IP 地址，格式为0.0.0.0

            siaddr: 表示服务器 IP 地址，格式为0.0.0.0

            giaddr: 表示中继代理 IP 地址，格式为 0.0.0.0

            chaddr: 表示客户机硬件地址，格式为 00:00:00:00:00:00

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                sname: 表示服务器名称，64 Bytes 的 16 进制值

                file: 表示DHCP 可选参数/启动文件名, 128 Bytes 的 16 进制值

                option: 表示可选项

        Example:
        | testcenter create dhcp packet | dhcp_pkt1 | ... |
        | testcenter create dhcp packet | dhcp_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(ciaddr):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % ciaddr
                break

            if not self._check_ipaddr_validity(yiaddr):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % yiaddr
                break

            if not self._check_ipaddr_validity(siaddr):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % siaddr
                break

            if not self._check_ipaddr_validity(giaddr):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % giaddr
                break

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_dhcp_packet(packet_name, op, htype, hlen,
                                      hops, xid, secs, bflag, mbz15, ciaddr,
                                      yiaddr, siaddr, giaddr, chaddr, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def _testcenter_create_pim_packet(self, packet_name, type, *args):
        """
        功能描述：创建PIM报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            type: 表示消息类型，可选值为 Hello, Join_Prune, Register, Register_Stop, Assert，Bootstrap, Graft, Graft_Reply,C-RP_Advertisement必须指定

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

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

                group_ip_addr: 表示组播组的IP地址，默认为"225.0.0.1"

                group_ip_bbit: 表示group ip BBit，默认为0

                group_ip_zbit: 表示group ip ZBit, 默认为0

                source_ip_addr: 表示 srouce ip addr, 默认为"192.0.0.1"

                pruned_source_ip_addr: 表示pruned srouce ip addr, 默认为"192.0.0.1"

                reg_border_bit: 表示 reg border bit, 默认为0

                reg_null_reg_bit: 表示 reg null reg bit, 默认为0

                reg_reserved_field: 表示 reg reserved filed, 默认为0

                reg_encap_multi_pkt: 表示 reg encap multi pkt， 默认为空

                reg_group_ip_addr: 表示 reg group ip addr, 默认为"225.0.0.1"

                reg_source_ip_addr: 表示 reg source ip addr, 默认为"192.0.0.1"

                assert_rpt_bit: 表示 assert rpt bit, 默认为0

                assert_metric_perf: 表示 assert metric perf, 默认为0

                assert_metric: 表示 assert metric, 默认为2

        Example:
        | testcenter create pim packet | pim_pkt1 | ... |
        | testcenter create pim packet | pim_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_pim_packet(packet_name, type, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_igmp_packet(self, packet_name, protocol_type, group_start_ip, *args):
        """
        功能描述：创建IGMP报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            protocol_type: 表示IGMP消息类型，必须指定，取值范围为 membershipreport | membershipquery | leavegroup

            group_start_ip: 组播组地址，必须指定

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

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

        Example:
        | testcenter create igmp packet | igmp_pkt1 | ... |
        | testcenter create igmp packet | igmp_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(group_start_ip, "multicast"):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的组播地址." % group_start_ip
                break

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_igmp_packet(packet_name, protocol_type, group_start_ip, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_pppoe_packet(self, packet_name, PPPoE_type, *args):
        """
        功能描述：创建PPPoE报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            PPPoE_type: 表示PPPoE 报文类型，必须指定，取值范围为：PPPoE_Discovery | PPPoE_Session

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                version: 表示报文协议版本号,默认为1

                type: 表示报文协议类型，默认为1

                code: 表示报文代码,取值范围为PADI | PADO | PADR | PADS | PADT | 0 (当对应 PPPoE_Session 时，code 为整数0)，默认为空

                session_id: 表示会话 ID，默认为0

                length: 表示报文长度，默认为0

                tag: 表示报文标签类型，默认为空

                tag_length: 表示报文标签长度(16 进制)，默认为0

                tag_value: 表示报文标签值(16 进制)，默认为0

        Example:
        | testcenter create pppoe packet | pppoe_pkt1 | ... |
        | testcenter create pppoe packet | pppoe_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_pppoe_packet(packet_name, PPPoE_type, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_icmp_packet(self, packet_name, icmp_type, code, *args):
        """
        功能描述：创建ICMP报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            icmp_type: 表示ICMP包类型，echo_request，echo_reply，destination_unreachable，
                       source_quench，redirect，time_exceeded，parameter_problem，
                       timestamp_request，timestamp_reply，information_request，
                       information_reply支持直接填写上述关键字段，同时也支持0-255 十进制数字书写

            code: 表示Icmp包代码，支持0-255 十进制数字书写

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

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

        Example:
        | testcenter create icmp packet | icmp_pkt1 | ... |
        | testcenter create icmp packet | icmp_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_icmp_packet(packet_name, icmp_type, code, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_icmpv6_packet(self, packet_name, icmpv6_type, *args):
        """
        功能描述：创建ICMPV6报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            icmpv6_type: 表示ICMPV6包类型，Icmpv6DestUnreach, Icmpv6EchoReply, Icmpv6EchoRequest,
                         Icmpv6PacketTooBig, Icmpv6ParameterProblem, Icmpv6TimeExceeded

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                code: 表示Icmp包代码，支持0-255 十进制数字书写

                checksum: 表示校验码,默认自动计算

                identifier: 表示标识符，默认为 0

                sequ_num: 表示Icmp包序列号

                data: 表示ICMP包数据，默认为0000

        Example:
        | testcenter create icmpv6 packet | icmp_pkt1 | Icmpv6EchoReply   |
        | testcenter create icmpv6 packet | icmp_pkt2 | Icmpv6EchoRequest |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_icmpv6_packet(packet_name, icmpv6_type, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return str_ret


    def testcenter_create_arp_packet(self, packet_name, *args):
        """
        功能描述：创建ARP报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                operation: 指明 arp 报文类型，可选值为 arpRequest,arpReply，默认为arpRequest

                src_hw_addr: 指明 arp 报文中的 sender hardware address，默认为00:00:01:00:00:02

                src_hw_addr_mode: 指明 sourceHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed

                src_hw_addr_repeat_count: 指明 sourceHardwareAddr 的变化次数，默认为1

                src_hw_addr_repeat_step: 指明 sourceHardwareAddr 的变化步长，默认为00:00:00:00:00:01

                dst_hw_addr: 指明 arp 报文中的 target hardware address，默认为00:00:01:00:00:02

                dst_hw_addr_mode: 指明 destHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed

                dst_hw_addr_repeat_count: 指明 destHardwareAddr 的变化次数，默认为1

                dst_hw_addr_repeat_step: 指明 destHardwareAddr 的变化步长，默认为00:00:00:00:00:01

                src_protocol_addr: 指明 arp 报文中的 sender ip address，默认为192.85.1.2

                src_protocol_addr_mode: 指明 sourceProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed

                src_protocol_addr_repeat_count: 指明 sourceProtocolAddr 变化次数，默认为1

                src_protocol_addr_repeat_step: 指明 sourceProtocolAddr 变化步长，默认为0.0.0.1

                dst_protocol_addr: 指明 arp 报文中的 tartget ip address，默认为192.85.1.2

                dst_protocol_addr_mode: 指明 destProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed

                dst_protocol_addr_repeat_count: 指明 destProtocolAddr 变化次数，默认为1

                dst_protocol_addr_repeat_step: 指明 destProtocolAddr 变化步长，默认为0.0.0.1

        Example:
        | testcenter create arp packet | arp_pkt1 | ... |
        | testcenter create arp packet | arp_pkt2 | ... |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_arp_packet(packet_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_custom_packet(self, packet_name, hex_string="aaaa"):
        """
        功能描述：创建Custom报文PDU

        参数：

            packet_name: 创建的PDU的名字,该名字可用于后面对PDU的其他操作

            hex_string: 指明数据包内容,默认为"aaaa"

        Example:
        | testcenter create custom packet | custom_pkt1 |      |
        | testcenter create custom packet | custom_pkt2 | bbbb |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_create_custom_packet(packet_name, hex_string)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_add_pdu_into_stream(self, stream_name, pdu_list):
        """
        功能描述：添加pdu（header和packet,统称pdu）到stream中，组建完整的流

        参数：

            stream_name: 指定要添加PDU的stream名字,这里的stream必须是create emtpy stream时指定的

            pdu_list: 表示需要添加到stream_name中的PDU列表

        Example:
        | testcenter add pdu into stream | stream1 | pdu1         |      |
        | ${pdu_list} | create list      | pdu1    | pdu2         | pdu3 |
        | testcenter add pdu into stream | stream2 | ${pdu_list}  |      |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_add_pdu_into_stream(stream_name, pdu_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_clear_test_result(self, port_or_stream="all", cleared_list=""):
        """
        功能描述：清零当前的测试统计结果，通过port_or_stream指明清零端口的统计还是清零stream的统计，或者是所有的统计结果。
                  通过cleared_list指明清零某些端口或某些stream的统计，如果cleared_list为空，则清零所有统计。

        参数：
            port_or_stream: 指定是清零端口的统计，还是清零stream的统计,默认为all，清零所有统计

            cleared_list: 指定要清零的对象列表，可以是端口列表，也可以是数据流列表

        Example:
        | testcenter clear test result | port        | port1        |       |
        | testcenter clear test result | stream      | stream1      |       |
        | ${port_list}                 | create list | port1        | port2 |
        | testcenter clear test result | port        | ${port_list} |       |
        | testcenter clear test result |             |              |       |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_clear_test_result(port_or_stream, cleared_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_filter(self, port_name, filter_name, filter_type,
                                 filter_value, filter_on_streamid=False):
        """
        功能描述：在端口创建过滤器,注意STC Port 只支持一个 stack 类型的 filter,
                  多个 UDF 类型或者offset类型的 filter。可以将 stack与 UDF 类型或者offset类型的 filter组合(相与关系)起来使用。
                  还有, 一个 stack 类型的filter 中支持多个过滤字段的相与组合。利用这些特征应该可以满足绝大部分的过滤需求。

        参数：

            port_name： 表示要创建过滤器的端口名

            filter_name: 表示需要创建的过滤器名

            filter_type: 表示过滤器对象类型,取值范围为：Stack | UDF | offset,
                         其中Stack类型filter既可用于抓包，也可用于统计，UDF类型filter只用于统计，offset类型filter只用于抓包

            filter_value: 表示过滤器对象的值，格式为{{FilterExpr1}{FilterExpr2}…}

                          当FilterType为Stack时，FilterExpr 的格式为：

                               -ProtocolField ProtocolField -min min -max max -mask mask

                                -ProtocolField: 指明具体的过滤字段，必选参数。ProtocolField 的具体过虑字段及说明如下：

                                    | eth.srcMac  | 源 MAC 地址 |
                                    | eth.dstMac  | 目的 MAC 地址 |
                                    | eth:vlan.id |    VLAN ID |
                                    | eth:vlan.pri |   VLAN 优先级 |
                                    | eth:ipv4.srcIp |    源 IP 地址 |
                                    | eth:ipv4.dstIp |    目的 IP地址 |
                                    | eth:ipv4.pro   |    Ipv4协议字段 |
                                    | eth:ipv4:tcp.srcPort |   TCP协议源端口号 |
                                    | eth:ipv4:udp.srcPort |   UDP协议源端口号 |
                                    | eth:ipv4:tcp.dstPort |    TCP协议目的端口号 |
                                    | eth:ipv4:udp.dstPort |    UDP协议目的端口号 |

                                -min：指明过滤字段的起始值。必选参数

                                -max:指明过滤字段的最大值。可选参数，若未指定，默认值为 min（注意：该参数目前无效）

                                -mask：指明过滤字段的掩码值。可选参数，取值与具体的字段相关。（注意：一般不设置，但是eth:vlan.pri必须设置，且取值为"0b111"）

                          当FilterType为UDF时，FilterExpr 的格式为：

                                -pattern pattern -offset offset  -max max -mask mask

                                -pattern：表示过滤匹配值， 16进制。必选参数，例如0x0806

                                -max：表示匹配的最大值，16进制。可选参数默认与Pattern相同

                                -offset：表示偏移值，可选参数，默认值为 0，起始位置从包的第一个字节起，参考取值为：0:DMAC 6:SMAC 12:ETH_TYPE 23:IP_PROTOCOL 26:SIP 30-DIP 34:SPORT 36:DPORT

                                -mask：表示掩码值, 16进制.可选参数，默认值为与 pattern长度相同的全 f。例如0xffff

                          当FilterType为offset时，FilterExpr的格式为：

                                -pattern pattern –condition condition -offset offset -mask mask -mode mode

                                -pattern: 表示过滤匹配指， 16进制。必选参数，例如0x6103

                                -condition	取值为true或false。取值true时，该filter不应用逻辑非，取值为false时，应用逻辑非(即勾选NOT项)	默认true

                                -offset	表示偏移值，可选参数，默认值为0,起始位置从包的第一个字节起，参考取值为：0:DMAC 6:SMAC 12:ETH_TYPE 23:IP_PROTOCOL 26:SIP 30-DIP 34:SPORT 36:DPORT

                                -mask	表示掩码值, 16进制.可选参数，默认值为与pattern长度相同的全f。例如0xffff

                                -mode	取值为 or或and。取值为or时，该filter与其后面的filter之间为或关系，取值为and时，为与关系。	默认and


            filter_on_streamid: 表示是否使用StreamId进行过滤，这种情况针对获取流的实时统计比较有效。
                                取值范围为TRUE | FALSE，默认为FALSE

        注意：

            统计过滤，总共支持4个16比特的filter，1个32比特filter，合计12个字节的filter，最小单位为2个字节，
            如果设置filter_on_streamid为TRUE,会占用掉32个比特。

            抓包过滤，总共支持8个32比特的filter,最小单位为4个字节，如果要过滤源MAC地址，需要占用掉8个字节。

        Example:
        | ${x} | create list       | -pattern       | 0xaa45        |          |      |
        | ${y} | create list       | ${x}           |               |          |      |
        | testcenter create filter | port1          | filter1       | UDF      | ${y} |
        | ${m} | create list       | -ProtocolField | eth:vlan.pri  | -min     | 3    | -mask  | 0b111 |
        | ${n} | create list       | ${m}           |               |          |      |
        | testcenter create filter | port1          | filter2       | Stack    | ${n} |
        | ${p} | create list       | -pattern       | 0x0102        | -offset  | 28   |
        | ${q} | create list       | ${p}           |               |          |      |
        | testcenter create filter | port1          | filter3       | offset   | ${q} |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_create_filter(port_name, filter_name, filter_type,
                                                           filter_value, filter_on_streamid)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_start_capture(self, port_name, save_path="", filter_name=""):
        """
        功能描述：在指定端口上开始抓包，保存报文到指定路径下，如果没有给定保存路径，则保存到默认路径下

        参数：

            port_name: 表示要开始抓包的端口名

            save_path: 表示捕获的报文保存的路径名。如果该参数为空,则保存到默认路径下

            filter_name: 表示要过滤保存报文使用的过滤器的名字

        Example:
        | testcenter start capture | port1 |          |         |
        | testcenter start capture | port2 | D:\\\\test |         |
        | testcenter start capture | port3 | E:\\\\test | filter1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        # 组建抓包文件保存路径
        if save_path == "":
            n_ret, str_ret = self._get_default_log_dir()
            if n_ret == TESTCENTER_SUC:
                tmp_path = str_ret
            else:
                raise RuntimeError(str_ret)
        else:
            tmp_path = save_path

        curtime = datetime.now()
        file_name = "%s_%s-%s-%s_%s-%s-%s.pcap" % (port_name, curtime.year, curtime.month,
                                       curtime.day, curtime.hour,
                                       curtime.minute, curtime.second)
        file_full_path = join(tmp_path, file_name)

        # 保存报文文件全路径，用于link
        self.dict_port_pcap_path[port_name] = file_full_path

        # 替换目录分割符为 "/", 防止tcl解析错误
        file_full_path = file_full_path.replace("\\", "/")

        n_ret, str_ret = self.obj.testcenter_start_capture(port_name, file_full_path, filter_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_stop_capture(self, port_name):
        """
        功能描述：停止指定端口的抓包

        参数：port_name: 表示要停止抓包的端口名

        Example:
        | testcenter stop capture | port1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_stop_capture(port_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)

        if port_name in self.dict_port_pcap_path:
            n_ret, str_ret = self._link_capture_file(self.dict_port_pcap_path[port_name])
            if n_ret == TESTCENTER_FAIL:
                log.user_err(str_ret)
                raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_traffic_on_port(self, port_list="", arp_study=True, time=0):
        """
        功能描述：基于端口开始发流，发指定时间的流后，停止发流，如果时间为0，立刻返回，由用户停止发流

        参数：

            port_list: 表示需要发流的端口组成的列表,默认为空，表示所有端口

            arp_study: 表示发流之前是否进行ARP学习，默认为TRUE

            time: 表示发流时间，单位为s, 默认为0

        Example:
        | testcenter traffic on port |       |        |
        | testcenter traffic on port | port1 |        |
        | testcenter traffic on port | port2 | time=5 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_traffic_on_port(port_list, arp_study, time)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_stop_traffic_on_port(self, port_list=""):
        """
        功能描述：停止端口发流

        参数：port_list: 表示需要停止发流的端口组成的列表,默认为空，表示所有端口

        Example:
        | testcenter stop traffic on port |       |   |
        | testcenter stop traffic on port | port2 |   |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_stop_traffic_on_port(port_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_traffic_on_stream(self, port_name, stream_list="", arp_study=True, time=0):
        """
        功能描述：在指定端口基于数据流开始发流，发指定时间的流后，停止发流，如果时间为0，立刻返回，由用户停止

        参数：

            port_name: 表示要发流的端口名

            stream_list: 表示需要发流的数据流名组成的列表，默认为空，表示当前端口上的所有数据流

            arp_study: 表示发流之前是否进行ARP学习，默认为TRUE

            time: 表示发流时间，单位为s, 默认为0

        Example:
        | testcenter traffic on stream | port1 |         |  |
        | testcenter traffic on stream | port1 | stream1 |  |
        | testcenter traffic on stream | port1 | time=10 |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_traffic_on_stream(port_name, stream_list, arp_study, time)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_stop_traffic_on_stream(self, port_name, stream_list=""):
        """
        功能描述：在端口停止数据流发流

        参数：

            port_name: 表示要停止发流的端口名

            stream_list: 表示需要停止发流的数据流名组成的列表，默认为空，表示当前端口上的所有数据流

        Example:
        | testcenter stop traffic on stream | port1 |         |
        | testcenter stop traffic on stream | port1 | stream1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_stop_traffic_on_stream(port_name, stream_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_get_port_statistic_snapshot(self, port_name, filter_stream=0, result_path=""):
        """
        功能描述：获取端口的统计结果快照，如果在端口上添加了过滤器，可以通过filter_stream获取过滤后的统计结果

        参数：

            port_name: 表示要获取统计结果的端口名

            filter_stream: 表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值，默认为0

            result_path: 表示统计结果保存的路径名。如果该参数为空,则默认保存到log路径下

        Example:
        | testcenter get port statistic snapshot | port1 |   |
        | testcenter get port statistic snapshot | port2 |   |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        # 组建统计结果文件保存路径
        if result_path == "":
            n_ret, str_ret = self._get_default_log_dir()
            if n_ret == TESTCENTER_SUC:
                tmp_path = str_ret
            else:
                raise RuntimeError(str_ret)
        else:
            tmp_path = result_path

        # 替换目录分割符为 "/", 防止tcl解析错误
        tmp_path = tmp_path.replace("\\", "/")

        n_ret, str_ret = self.obj.testcenter_get_port_statistic_snapshot(port_name, filter_stream, tmp_path)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_get_stream_statistic_snapshot(self, port_name, stream_name, result_path=""):
        """
        功能描述：获取端口的数据流的统计结果快照

        参数：

            port_name: 表示要获取统计结果的端口名

            stream_name: 表示需要获取统计结果的数据流名

            result_path: 表示统计结果保存的路径名。如果该参数为空,则默认保存到log路径下

        Example:
        | testcenter get stream statistic snapshot | port1 | stream1 |    |
        | testcenter get stream statistic snapshot | port1 | stream2 |    |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        # 组建统计结果文件保存路径
        if result_path == "":
            n_ret, str_ret = self._get_default_log_dir()
            if n_ret == TESTCENTER_SUC:
                tmp_path = str_ret
            else:
                raise RuntimeError(str_ret)
        else:
            tmp_path = result_path

        # 替换目录分割符为 "/", 防止tcl解析错误
        tmp_path = tmp_path.replace("\\", "/")

        n_ret, str_ret= self.obj.testcenter_get_stream_statistic_snapshot(port_name, stream_name, tmp_path)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_get_port_statistic_result(self, port_name, option, filter_stream=0):
        """
        功能描述：获取端口的统计结果，需要先获取端口的统计结果快照，如果没有获取快照，返回实时值。
                   获取实时值时，如果在端口上添加了过滤器，可以通过filter_stream获取过滤后的统计结果

        参数：

            port_name: 表示要获取统计结果的端口名

            option: 表示需要获取的统计项名，取值范围为：
                    | TxFrames          | 发送帧统计值                   |
                    | TxRateFrames      | 发送帧速率(包数)               |
                    | RxFrames          | 接收帧统计值                   |
                    | RxRateFrames      | 接收帧速率(包数)               |
                    | TxBytes           | 发送字节统计值                 |
                    | RxBytes           | 接收字节统计值                 |
                    | TxRateBytes       | 发送帧速率(字节数)             |
                    | RxRateBytes       | 接收帧速率(字节数)             |
                    | TxSignature       | 发送标记帧统计值               |
                    | TxSignatureRate   | 发送标记帧速率                 |
                    | RxSignature       | 接收标记帧统计值               |
                    | RxSignatureRate   | 接收标记帧统计速率             |
                    | RxIPv4Frames      | 接收 ipv4 帧统计值             |
                    | RxIPv6Frames      | 接收 ipv6 帧统计值             |
                    | RxMPLSFrames      | 接收 mpls 帧统计值             |
                    | RxCRCErrors       | 接收 Crc 错误统计值            |
                    | Oversize          | 接收 Oversize 帧统计值         |
                    | FragOrUndersize   | 接收 Undersize 帧统计值        |
                    | RxArpReplies      | 接收 arp 响应统计值            |
                    | RxArpRequests     | 接收 arp 请求统计值            |
                    | RxVLANFrames      | 接收 vlan 帧统计值             |
                    | RxJumboFrames     | 接收 jumbo 帧统计值            |
                    | RxIPv4chesumError | 接收 Ipv4 头部校验和错误统计值 |
                    | RxPauseFrames     | 接收的 pause 帧统计值          |
                    | RxMplsFrames      | 接收的 Mpls 帧统计值           |
                    | RxIcmpFrames      | 接收的 Icmp 帧统计值           |
                    | RxTrigger1        | 过滤器 1 对应的报文统计值      |
                    | RxTrigger2        | 过滤器 2 对应的报文统计值      |
                    | RxTrigger3        | 过滤器 3 对应的报文统计值      |
                    | RxTrigger4        | 过滤器 4 对应的报文统计值      |
                    | RxTrigger5        | 过滤器 5 对应的报文统计值      |
                    | RxTrigger6        | 过滤器 6 对应的报文统计值      |
                    | RxTrigger7        | 过滤器 7 对应的报文统计值      |
                    | RxTrigger8        | 过滤器 8 对应的报文统计值      |

            filter_stream: 表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值，默认为0

        Example:
        | testcenter get port statistic result   | port1 | TxFrames  | #返回实时值 |
        | testcenter get port statistic snapshot | port1 |           | #获取快照   |
        | testcenter get port statistic result   | port1 | RxFrames  | #返回快照里的值  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        state = ""

        n_ret, str_ret, state = self.obj.testcenter_get_port_statistic_result(port_name, option, filter_stream)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  state


    def testcenter_get_stream_statistic_result(self, port_name, stream_name, option):
        """
        功能描述：获取端口的数据流的统计结果,需要先获取数据流的统计结果快照，如果没有获取快照，返回实时值

        参数：

            port_name: 表示要获取统计结果的端口名

            stream_name: 表示需要获取统计结果的数据流名

            option: 表示需要获取的统计项名,取值范围为：
                    | TxFrames            | 发送帧统计值              |
                    | RxFrames            | 接收帧统计值              |
                    | TxBytes             | 发送字节统计值            |
                    | RxBytes             | 接收字节统计值            |
                    | TxSigFrames         | 发送带有标记帧统计值      |
                    | RxSigFrames         | 接收带有标记帧统计值      |
                    | TxIPv4Frames        | 发送 IPv4 帧统计值        |
                    | RxIPv4Frames        | 接收 IPv4 帧统计值        |
                    | CRCErrors           | Crc 错误统计值            |
                    | RxIPv4chesumError   | Ipv4 头部校验和错误统计值 |
                    | RxAvgLatency        | 接收帧平均时延            |
                    | RxAvgJitter         | 接收帧平均抖动            |
                    | RxInSeq             | 接收顺序帧                |
                    | RxDupelicated       | 接收重复帧                |
                    | RxOutSeq            | 接收乱序帧                |
                    | RxDrop              | 传输过程丢帧              |
                    | RxPrbsBytes         | 接收 PRBS 字节数          |
                    | RxPrbsBitErr        | 接收 PRBS 错误比特数      |
                    | RxTcpUdpChecksumErr | 接收 TCP/UDP 校验和错误帧 |
                    | TxRateBytes         | 发送帧速率(字节数)        |
                    | TxRateFrames        | 发送帧速率(包数)          |
                    | RxRateBytes         | 接收帧速率(字节数)        |
                    | RxRateFrames        | 接收帧速率(包数)          |
                    | FirstArrivalTime    | 最先到达时间              |
                    | LastArrivalTime     | 最后到达时间              |

        Example:
        | testcenter get stream statistic result   | port1 | stream1 | TxFrames | #返回实时值     |
        | testcenter get stream statistic snapshot | port1 | stream2 |          | #获取快照       |
        | testcenter get stream statistic result   | port1 | stream2 | RxFrames | #返回快照里的值 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        state = ""

        n_ret, str_ret, state = self.obj.testcenter_get_stream_statistic_result(port_name, stream_name, option)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  state


    def testcenter_create_host(self, port_name, host_name, *args):
        """
        功能描述：在端口创建host，并配置相关属性

        参数：

            port_name: 表示要创建host的端口别名

            host_name: 表示创建的host的名字

            dict_args: 表示可选参数字典,具体参数描述如下：

                ip_version: 指明IP的版本,可设置ipv4 | ipv6，默认为ipv4

                host_type: 指明服务器类型，可设置normal | MldHost，默认为normal

                ipv4_addr: 指明主机ipv4地址，默认为192.168.1.2

                ipv4_addr_gateway: 指明主机ipv4网关，默认为192.168.1.1

                ipv4_addr_mask: 指明主机ipv4地址递增掩码，默认为0.0.0.255

                ipv4_addr_prefix_len: 表示Host IPv4地址Prefix长度

                ipv6_addr: 指明主机ipv6地址，默认为 2000:201::1:2

                ipv6_addr_mask: 指明主机ipv6地址递增掩码，默认为0000::FFFF:FFFF:FFFF:FFFF

                ipv6_link_local_addr: 表示Host起始IPv6 Link Local地址，默认为fe80::

                ipv6_addr_gateway: 指明主机ipv6网关，默认为2000:201::1:1

                ipv6_addr_prefix_len: 表示Host IPv6地址Prefix长度，默认为64

                mac_addr: 指明Host起始MAC地址，默认内部自动生成，依次递增00:20:94:SlotId:PortId:seq

                mac_mask: 指明Host起始MAC地址递增掩码，默认为00:00:FF:FF:FF:FF

                mac_count: 指明Mac地址变化的数量，默认为1，注意该参数要与count设置为一致，否则不生效

                mac_increase: 指明Mac地址递增的步长，默认为1

                count: 指明Host IP地址个数，默认为1

                increase: 指明IP地址增幅，默认为1

                flag_ping: 指明是否支持Ping功能，enable | disable，默认为enable

                enable_vlan: 指明是否添加vlan，enable | disable, 默认为disable

                vlan_id: 指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100

                vlan_pri: 优先级,取值范围0-7，默认为0

        Example:
        | testcenter create host | port1 | host1 | ipv4_addr=10.10.10.10 | ipv4_addr_gateway=10.10.10.1	| mac_addr=00:00:00:10:00:10 |
        | testcenter create host | port1 | host2 | ipv4_addr=10.10.10.10 | count=10                     | increase=1                 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        log.user_info(args)

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret
            log.user_info(dict_args)

            # 检测IP地址的合法性
            if "ipv4_addr" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_addr"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_addr"]
                    break

            if "ipv4_addr_gateway" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_addr_gateway"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_addr_gateway"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_host(port_name, host_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_start_arp_study(self, src_host, dst_host):
        """
        功能描述：发送ARP请求，学习目的主机的MAC地址

        参数：

            src_host: 表示发送ARP请求的主机名,该主机必须是通过已创建的主机

            dst_host: 表示所请求的目的IP地址或者主机名称

        Example:
        | testcenter start arp study | host1 | host2      |  |
        | testcenter start arp study | host1 | 10.10.10.1 |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:

            n_ret, str_ret = self.obj.testcenter_start_arp_study(src_host, dst_host)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_dhcp_server(self, port_name, router_name, *args):
        """
        功能描述：在端口创建DHCP server,并配置相关属性

        参数：

            port_name: 表示要创建DHCP server的端口名

            router_name: 表示创建的DHCP server的名字

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

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

        Example:
        | testcenter create dhcp server | port1 | router1 | tester_ip_addr=10.10.10.2 | pool_start=10.10.10.10 |
        | testcenter create dhcp server | port2 | router2 | enable_vlan=enable        | vlan_id=1000           |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 检测IP地址的合法性
            if "router_id" in dict_args:
                if not self._check_ipaddr_validity(dict_args["router_id"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["router_id"]
                    break

            if "tester_ip_addr" in dict_args:
                if not self._check_ipaddr_validity(dict_args["tester_ip_addr"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["tester_ip_addr"]
                    break

            if "pool_start" in dict_args:
                if not self._check_ipaddr_validity(dict_args["pool_start"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["pool_start"]
                    break

            if "ipv4_gateway" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_gateway"]):
                    n_ret = TESTCENTER_FAIL
                    set_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_gateway"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_dhcp_server(port_name, router_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_enable_dhcp_server(self, router_name):
        """
        功能描述：开启DHCP Server，开始协议仿真

        参数：

            router_name: 表示要开始协议仿真的DHCP Server名称

        Example:
        | testcenter create dhcp server | port1 | router1 | tester_ip_addr=10.10.10.2 | pool_start=10.10.10.10 |
        | testcenter enable dhcp server | router1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_enable_dhcp_server(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_disable_dhcp_server(self, router_name):
        """
        功能描述：关闭DHCP Server，停止协议仿真

        参数：

            router_name: 表示要停止协议仿真的DHCP Server名称

        Example:
        | testcenter create dhcp server | port1 | router1 | tester_ip_addr=10.10.10.2 | pool_start=10.10.10.10 |
        | testcenter enable dhcp server | router1 |
        | testcenter disable dhcp server | router1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_disable_dhcp_server(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_dhcp_client(self, port_name, router_name, *args):
        """
        功能描述：在端口创建DHCP client,并配置相关属性

        参数：

            port_name: 表示要创建DHCP client的端口名

            router_name: 表示创建的DHCP client的名字

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                pool_name: 可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
                           注意：PoolName和routerName不要相同，默认为空。

                router_id: 表示指定的RouterId，默认为1.1.1.1

                local_mac: 表示server接口MAC，默认为00:00:00:11:01:01

                count: 表示模拟的主机数量，默认为1

                auto_retry_num: 表示最大尝试建立连接的次数，默认为1

                flag_gateway: 表示是否配置网关IP地址，默认为FALSE

                ipv4_gateway: 表示网关IP地址，默认为192.0.0.1

                active：表示DHCP client会话是否激活，默认为TRUE

                flag_broadcast：表示广播标识位，广播为TRUE，单播为FALSE，默认为TRUE

                enable_vlan: 指明是否添加vlan，enable/disable, 默认为disable

                vlan_id: 指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100

                vlan_pri: 优先级,取值范围0-7，默认为0

        Example:
        | testcenter create dhcp client | port1 | router1 | pool_name=client   | router_id=192.168.0.1 |
        | testcenter create dhcp client | port2 | router2 | enable_vlan=enable | vlan_id=1000          |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 检测IP地址的合法性
            if "router_id" in dict_args:
                if not self._check_ipaddr_validity(dict_args["router_id"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["router_id"]
                    break

            if "ipv4_gateway" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_gateway"]):
                    n_ret = TESTCENTER_FAIL
                    set_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_gateway"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_dhcp_client(port_name, router_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_enable_dhcp_client(self, router_name):
        """
        功能描述：使能DHCP Client

        参数：

            router_name: 表示要使能的DHCP Client名称

        Example:
        | testcenter create dhcp client | port1 | router1 | pool_name=client | router_id=192.168.0.1 |
        | testcenter enable dhcp client | router1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_enable_dhcp_client(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_disable_dhcp_client(self, router_name):
        """
        功能描述：停止DHCP Client

        参数：

            router_name: 表示要停止的DHCP Client名称

        Example:
        | testcenter create dhcp client | port1 | router1 | pool_name=client   | router_id=192.168.0.1 |
        | testcenter enable dhcp client | router1 |
        | testcenter disable dhcp client | router1 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_disable_dhcp_client(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


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
        Example:
        | testcenter create dhcp client | port1 | router1 | pool_name=client   | router_id=192.168.0.1 |
        | testcenter enable dhcp client | router1 |
        | testcenter method dhcp client | router1 | Bind |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_method_dhcp_client(router_name, method)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_igmp_host(self, port_name, host_name, *args):
        """
        功能描述：在端口创建IGMP host，并配置相关属性

        参数：

            port_name: 表示要创建IGMP host的端口名

            host_name: 表示创建的host的名字

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_mac: 表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02

                src_mac_step: 表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1

                ipv4_addr: 表示Host起始IPv4地址，默认为192.85.1.3

                ipv4_addr_gateway: 表示GateWay的IPv4地址，默认为192.85.1.1

                ipv4_addr_prefix_len: 表示Host IPv4地址Prefix长度，默认为24

                count: 表示Host IP、MAC地址个数，默认为1

                increase: 表示IP地址增幅，默认为1

                protocol_ver: 表示组播协议的版本。合法值：IGMPv1 | IGMPv2 | IGMPv3。默认为IGMPv2

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

                vlan_id: 指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100

                vlan_pri: 优先级,取值范围0-7，默认为0

        Example:
        | testcenter create igmp host | port1 | host1 | ipv4_addr=10.10.10.10 | ipv4_addr_gateway=10.10.10.1 |
        | testcenter create igmp host | port2 | host2 | protocol_type=IGMPv3  |                              |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 检测IP地址的合法性
            if "ipv4_addr" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_addr"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_addr"]
                    break

            if "ipv4_addr_gateway" in dict_args:
                if not self._check_ipaddr_validity(dict_args["ipv4_addr_gateway"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["ipv4_addr_gateway"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_igmp_host(port_name, host_name, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_igmp_group_pool(self, host_name, group_pool_name, start_ip, *args):
        """
        功能描述：创建IGMP GroupPool, 并配置相关属性

        参数：

            host_name: 表示要创建IGMP GroupPool的主机名

            group_pool_name: 表示IGMP Group的名称标识，要求在当前 IGMP Host 唯一

            start_ip: 表示Group 起始 IP 地址

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                prefix_len: 表示IP 地址前缀长度，取值范围：5到32，默认为24

                group_cnt: 表示Group 个数，默认为1

                group_increment: 表示Group IP 地址的增幅，默认为1

                filter_mode: Specific Source Filter Mode(IGMPv3), 取值范围为Include | Exclude，默认为Exclude

                src_start_ip: 表示起始主机 IP 地址（IGMPv3），默认为192.168.1.2

                src_cnt: 表示主机地址个数（IGMPv3），默认为1

                src_increment: 表示主机 IP 地址增幅（IGMPv3），默认为1

                src_prefix_len: 表示主机 IP 地址前缀长度（IGMPv3），取值范围：1到32，默认为24

        Example:
        | testcenter create igmp group pool | host1 | group1 | 225.0.0.2 | group_cnt=2 | group_increment=10 |
        | testcenter create igmp group pool | host2 | group2 | 225.0.0.4 | src_cnt=10  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(start_ip, "multicast"):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的组播地址." % start_ip
                break

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            if "src_start_ip" in dict_args:
                if not self._check_ipaddr_validity(dict_args["src_start_ip"]):
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"%s 不是合法的IP地址." % dict_args["src_start_ip"]
                    break

            n_ret, str_ret = self.obj.testcenter_create_igmp_group_pool(host_name, group_pool_name, start_ip, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_send_igmp_leave(self, host_name, group_pool_list=""):
        """
        功能描述：向指定组播组发送IGMP Leave报文

        参数：

            host_name: 表示要发送报文的host名字

            group_pool_list: 表示IGMP Group 的名称标识列表,不指定表示针对所有group

        Example:
        | testcenter create igmp group pool | host1 | group1 | 225.0.0.4 |  |
        | testcenter send igmp report       | host1 | group1 |           |  |
        | testcenter send igmp leave        | host1 | group1 |           |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_send_igmp_leave(host_name, group_pool_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_send_igmp_report(self, host_name, group_pool_list=""):
        """
        功能描述：向指定组播组发送IGMP report报文

        参数：

            host_name: 表示要发送报文的host名字

            group_pool_list: 表示IGMP Group 的名称标识列表,不指定表示针对所有group

        Example:
        | testcenter create igmp group pool | host1 | group1 | 225.0.0.4 |  |
        | testcenter send igmp report       | host1 | group1 |           |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_send_igmp_report(host_name, group_pool_list)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_igmp_router(self, port_name, router_name, router_ip, *args):
        """
        功能描述：在端口创建IGMP router,并配置相关属性

        参数：

            port_name: 表示要创建IGMP router的端口名

            router_name: 表示创建的IGMP router的名字

            router_ip: 表示 IGMP Router 的接口 IPv4 地址

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_mac: 表示源Mac，创建多个Router时，默认值按照步长1递增

                protocol_type: 表示Protocol的类型。合法值：IGMPv1 | IGMPv2 | IGMPv3。默认为IGMPv2

                ignore_v1reports: 指明是否忽略接收到的 IGMPv1 Host的报文，默认为False

                ipv4_dont_fragment: 指明当报文长度大于 MTU 时，是否进行分片，默认为False

                last_member_query_count:: 表示在认定组中没有成员之前发送的特定组查询的次数，默认为2

                last_member_query_interval: 表示在认定组中没有成员之前发送指定组查询报文的 时间间隔（单位 ms），默认为1000

                query_interval: 表示发送查询报文的时间间隔（单位 s），，默认为32

                query_response_uper_bound: 表示Igmp Host对于查询报文的响应的时间间隔的上限值（单位 ms），默认为10000

                startup_query_count: 指明Igmp Router启动之初发送的Query报文的个数，取值范围：1-255,默认为2

                active: 表示IGMP Router会话是否激活，默认为TRUE

        Example:
        | testcenter create igmp router | port1 | router1 | 10.10.10.10 |
        | testcenter create igmp router | port2 | router2 | 20.20.20.20 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # 检查IP地址是否合法
            if not self._check_ipaddr_validity(router_ip):
                n_ret = TESTCENTER_FAIL
                str_ret = u"%s 不是合法的IP地址." % router_ip
                break

            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_igmp_router(port_name, router_name, router_ip, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_start_igmp_query(self, router_name):
        """
        功能描述：开始通用IGMP查询

        参数：
            router_name: 表示要开始通用IGMP查询的IGMP Router名

        Example:
        | testcenter start igmp query | router1  |   |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_start_igmp_query(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_stop_igmp_query(self, router_name):
        """
        功能描述：停止通用IGMP查询

        参数：
            router_name: 表示要停止通用IGMP查询的IGMP Router名

        Example:
        | testcenter stop igmp query | router1  |   |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_stop_igmp_query(router_name)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_ipv4_stream(self, port_name, stream_name, src_host, dst_host, *args):
        """
        功能描述：创建一条或多条IPv4的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host        | port1 | host1   | ipv4_addr=10.10.10.10   | ipv4_addr_gateway=10.10.10.1	| mac_addr=00:00:00:10:00:10 |
        | testcenter create host        | port2 | host2   | ipv4_addr=192.168.2.150 | ipv4_addr_gateway=192.168.2.1	| mac_addr=00:00:00:10:00:20 |
        | testcenter create ipv4 stream | port1 | stream1 | host1                   | host2                         |                            |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_ipv4_stream(port_name, stream_name,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_ipv6_stream(self, port_name, stream_name, src_host, dst_host, *args):
        """
        功能描述：创建一条或多条IPv6的数据流

        参数：
            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host        | port1 | host1   | ipv4_addr=2000::1 | ipv4_addr_gateway=2000::3 | mac_addr=00:00:00:10:00:10 |
        | testcenter create host        | port2 | host2   | ipv4_addr=2000::2 | ipv4_addr_gateway=2000::4 | mac_addr=00:00:00:10:00:20 |
        | testcenter create ipv6 stream | port1 | stream1 | host1             | host2                     |                            |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        enable_vlan = "False"

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            n_ret, str_ret = self.obj.testcenter_create_ipv6_stream(port_name, stream_name,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_tcp_stream(self, port_name, stream_name,
                                            src_host, dst_host, *args):
        """
        功能描述：创建一条或多条TCP IPv4的数据流

        参数：

            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_port: TCP数据流的源端口, 默认为2000

                dst_port: TCP数据流的目的端口， 默认为3000

                src_port_count: TCP数据流的源端口的个数，默认为1

                dst_port_count: TCP数据流的目的端口的个数，默认为1

                inc_src_port: 源端口递增值，默认为1

                inc_dst_port: 目的端口递增值，默认为1

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host        | port1 | host1   | ipv4_addr=10.10.10.10   | ipv4_addr_gateway=10.10.10.1	| mac_addr=00:00:00:10:00:10 |
        | testcenter create host        | port2 | host2   | ipv4_addr=192.168.2.150 | ipv4_addr_gateway=192.168.2.1	| mac_addr=00:00:00:10:00:20 |
        | testcenter create tcp stream  | port1 | stream1 | host1                   | host2 |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        src_port = 2000
        dst_port = 3000

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 如果用户配置了src_port, dst_port,使用用户配置的值，否则使用默认值

            if "src_port" in dict_args:
                src_port = dict_args["src_port"]
                del dict_args["src_port"]

            if "dst_port" in dict_args:
                dst_port = dict_args["dst_port"]
                del dict_args["dst_port"]

            n_ret, str_ret = self.obj.testcenter_create_tcp_stream(port_name, stream_name,
                                                                    src_port, dst_port,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_tcpv6_stream(self, port_name, stream_name,
                                            src_host, dst_host, *args):
        """
        功能描述：创建一条或多条TCP IPv6的数据流

        参数：

            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_port: TCP数据流的源端口, 默认为2000

                dst_port: TCP数据流的目的端口， 默认为3000

                src_port_count: TCP数据流的源端口的个数，默认为1

                dst_port_count: TCP数据流的目的端口的个数，默认为1

                inc_src_port: 源端口递增值，默认为1

                inc_dst_port: 目的端口递增值，默认为1

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host         | port1 | host1   | ipv4_addr=2000::1 | ipv4_addr_gateway=2000::3 | mac_addr=00:00:00:10:00:10 |
        | testcenter create host         | port2 | host2   | ipv4_addr=2000::2 | ipv4_addr_gateway=2000::4 | mac_addr=00:00:00:10:00:20 |
        | testcenter create tcpv6 stream | port1 | stream1 | host1             | host2                     |                            |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        src_port = 2000
        dst_port = 3000

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 如果用户配置了src_port, dst_port,使用用户配置的值，否则使用默认值
            if "src_port" in dict_args:
                src_port = dict_args["src_port"]
                del dict_args["src_port"]

            if "dst_port" in dict_args:
                dst_port = dict_args["dst_port"]
                del dict_args["dst_port"]

            n_ret, str_ret = self.obj.testcenter_create_tcpv6_stream(port_name, stream_name,
                                                                    src_port, dst_port,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_udp_stream(self, port_name, stream_name,
                                            src_host, dst_host, *args):
        """
        功能描述：创建一条或多条UDP IPv4的数据流

        参数：

            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_port: UDP数据流的源端口, 默认为2000

                dst_port: UDP数据流的目的端口， 默认为3000

                src_port_count: UDP数据流的源端口的个数，默认为1

                dst_port_count: UDP数据流的目的端口的个数，默认为1

                inc_src_port: 源端口递增值，默认为1

                inc_dst_port: 目的端口递增值，默认为1

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host        | port1 | host1   | ipv4_addr=10.10.10.10   | ipv4_addr_gateway=10.10.10.1	| mac_addr=00:00:00:10:00:10 |
        | testcenter create host        | port2 | host2   | ipv4_addr=192.168.2.150 | ipv4_addr_gateway=192.168.2.1	| mac_addr=00:00:00:10:00:20 |
        | testcenter create udp stream  | port1 | stream1 | host1                   | host2                         |                            |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        src_port = 2000
        dst_port = 3000

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 如果用户配置了src_port, dst_port,使用用户配置的值，否则使用默认值
            if "src_port" in dict_args:
                src_port = dict_args["src_port"]
                del dict_args["src_port"]

            if "dst_port" in dict_args:
                dst_port = dict_args["dst_port"]
                del dict_args["dst_port"]

            n_ret, str_ret = self.obj.testcenter_create_udp_stream(port_name, stream_name,
                                                                    src_port, dst_port,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_create_udpv6_stream(self, port_name, stream_name,
                                            src_host, dst_host, *args):
        """
        功能描述：创建一条或多条UDP IPv6的数据流

        参数：

            port_name: 需要建流的端口的别名，必须是预约端口时指定的名字

            stream_name: 指明创建的流的别名，该名字可用于后面对流的其他操作

            src_host: 指明发送端主机名

            dst_host: 指明接收端主机名

            args: 表示可选参数，传入的格式为"varname=value",具体参数描述如下：

                src_port: UDP数据流的源端口, 默认为2000

                dst_port: UDP数据流的目的端口， 默认为3000

                src_port_count: UDP数据流的源端口的个数，默认为1

                dst_port_count: UDP数据流的目的端口的个数，默认为1

                inc_src_port: 源端口递增值，默认为1

                inc_dst_port: 目的端口递增值，默认为1

                frame_len: 指明数据帧长度 单位为byte，默认为128

                profile_name: 指明Profile 的名字,流可以引用里面的配置信息。

        Example:
        | testcenter create host         | port1 | host1   | ipv4_addr=2000::1 | ipv4_addr_gateway=2000::3 | mac_addr=00:00:00:10:00:10 |
        | testcenter create host         | port2 | host2   | ipv4_addr=2000::2 | ipv4_addr_gateway=2000::4 | mac_addr=00:00:00:10:00:20 |
        | testcenter create udpv6 stream | port1 | stream1 | host1             | host2                     |                            |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""
        src_port = 2000
        dst_port = 3000

        for i in [1]:
            # covert args format
            n_ret, tmp_ret = self._format_args(args)
            if n_ret == TESTCENTER_FAIL:
                str_ret = tmp_ret
                break
            else:
                dict_args = tmp_ret

            # 如果用户配置了src_port, dst_port使用用户配置的值，否则使用默认值
            if "src_port" in dict_args:
                src_port = dict_args["src_port"]
                del dict_args["src_port"]

            if "dst_port" in dict_args:
                dst_port = dict_args["dst_port"]
                del dict_args["dst_port"]

            n_ret, str_ret = self.obj.testcenter_create_udpv6_stream(port_name, stream_name,
                                                                    src_port, dst_port,
                                                                    src_host, dst_host, dict_args)
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_save_config_as_xml(self, path=""):
        """
        功能描述：将脚本配置保存为xml文件

        参数：
            path: 指定保存的xml文件的路径.如果未指定，保存到log路径下，文件名默认为testcenter_curtime.xml

        Example:
        | testcenter save config as xml |           |  |
        | testcenter save config as xml | E:\\\\test  |  |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        if path == "":
            n_ret, str_ret = self._get_default_log_dir()
            if n_ret == TESTCENTER_SUC:
                tmp_path = str_ret
            else:
                raise RuntimeError(str_ret)
        else:
            tmp_path = path

        curtime = datetime.now()
        file_name = "testcenter_%s-%s-%s_%s-%s-%s.xml" % (curtime.year, curtime.month,curtime.day,
                                               curtime.hour, curtime.minute, curtime.second)

        full_path = join(tmp_path, file_name)

        # 替换目录分割符为 "/", 防止tcl解析错误
        full_path = full_path.replace("\\", "/")

        n_ret, str_ret = self.obj.testcenter_save_config_as_xml(full_path)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_set_stream_scheduling_mode(self, port_name, scheduling_mode="RATE_BASED"):
        """
        功能描述：设置端口上数据流的调度模式

        参数：
            port_name: 需要配置数据流调度模式的端口名，必须是预约端口时指定的名字

            scheduling_mode：数据流的调度模式，取值范围为：PORT_BASED | RATE_BASED | PRIORITY_BASED，默认为RATE_BASED

        Example:
        | testcenter set stream scheduling_mode | port1 | PORT_BASED     |
        | testcenter set stream scheduling_mode | port2 | PRIORITY_BASED |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        n_ret, str_ret = self.obj.testcenter_set_stream_scheduling_mode(port_name, scheduling_mode)
        if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return  str_ret


    def testcenter_cleanup_test(self):
        """
        功能描述：消除测试，释放资源，每次测试结束必须调用该方法

        参数： 无

        Example:
        | testcenter cleanup test |   |
        """

        n_ret = TESTCENTER_SUC
        str_ret = ""

        for i in [1]:

            if self.start_flag == False:
                str_ret = u"测试还未开始，不需要消除测试，释放资源！"
                break

            # 调用testcenter_cleanup_test释放资源
            n_ret, str_ret = self.obj.testcenter_cleanup_test()
            if n_ret == ATTTestCenter.ATT_TESTCENTER_FAIL:
                n_ret = TESTCENTER_FAIL
                break

            # 还原开始标识
            self.start_flag = False

        # 如果testcenter server log文件已经打开，需要关闭
        if self.log_file_id:
            self.log_file_id.close()

        # 如果TestCenter server已经开启，需要关闭
        if self.proc_obj and self.proc_obj.pid:
            if self.proc_obj.poll()== None:
                tmp_ret, data = attcommonfun.get_process_children(self.proc_obj.pid)
                if tmp_ret == attcommonfun.ATTCOMMONFUN_SUCCEED:
                    dict_process = data
                    for process_pid,process_name in dict_process.items():
                        if process_name.lower() == "tclsh.exe":
                            # 关闭当前子进程的子进程
                            try:
                                os.kill(process_pid, 9)
                            except Exception, e:
                                n_ret = TESTCENTER_FAIL
                                str_ret = u"关闭TestCenter服务发生异常，错误信息为：%s" % e
                else:
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"关闭TestCenter服务发生异常，错误信息为：%s" % data

                # 关闭当前子进程
                try:
                    os.kill(self.proc_obj.pid, 9)
                except Exception, e:
                    n_ret = TESTCENTER_FAIL
                    str_ret = u"关闭TestCenter服务发生异常，错误信息为：%s" % e

        if n_ret == TESTCENTER_FAIL:
            log.user_err(str_ret)
            raise RuntimeError(str_ret)

        log.user_info(str_ret)
        return str_ret
