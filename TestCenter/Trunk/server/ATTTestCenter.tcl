#***************************************************************************
#  Copyright (C), 2012-1, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  模块名称：ATTTestCenter
#  模块功能：集成某些底层接口功能，提供中间层调用接口，屏蔽某些中间对象
#  作者: ATT项目开发组
#  版本: V1.0
#  日期: 2013.02.27
#  修改记录：
#      lana     created    2013-02-27
#
#***************************************************************************

# add project path to auto_path
set projectPath [file dirname [info script]]
lappend auto_path  $projectPath

if {[catch {

    # source testcenter pkgIndex.tcl
    set filepath [file join $projectPath "Source\\pkgIndexs.tcl"]
    source  $filepath
    puts "source TestCenter start_file successfully!"
    } err] == 1} {

    set msg "Source TestCenter 启动文件发生异常，错误信息为: $err ."
    puts $msg
    }

package require xmlrpc
package require LOG
package require TestCenter

set ::ATT_TESTCENTER_SUC 0
set ::ATT_TESTCENTER_FAIL -1


#全局函数: return proc name
proc ::__FUNC__ {args} {

    set procName ""

    if { [catch {

            set procName [lindex [info level -1] 0]
        }  err ] } {

            puts "Warning:__FUNC__: $err."
        }

    return [string trimleft $procName "::"]
}


package provide ::ATTTestCenter 1.0

namespace eval ::ATTTestCenter {


    set  __FILE__   ATTTestCenter.tcl
	set reservePort ""                  ;# 备份成功预约的端口
    array set PortStatsSnapshot {}            ;# 用于保存获取到的端口统计快照
    array set StreamStatsSnapshot {}          ;# 用于保存获取到的stream统计快照

}


#*******************************************************************************
#Function:   ::ATTTestCenter::ConnectChassis {chassisAddr}
#Description:  使用给定的chassisAddr连接TestCenter
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      chassisAddr     表示机框地址，用于连接TestCenter的IP地址
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::ConnectChassis {chassisAddr } {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::ConnectChassis连接TestCenter
		if {[catch {set res [TestCenter::ConnectChassis $chassisAddr]} err] == 1} {

			set msg "调用TestCenter::ConnectChassis发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:   ::ATTTestCenter::ReservePort {portLocation portName {portType "Ethernet"}}
#Description:  预约端口，在预约端口时，需要指明端口的位置，端口的名字和端口的类型
#             （即该端口数据链路层要使用的协议类型），取值范围为：Ethernet,Wan,Atm,LowRate
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      portLocation     表示端口的位置，由板卡号与端口号组成，用'/'连接。例如预约1号板卡的1号端口，则传入 "1/1"
#      portName         指定预约端口的别名，用于后面对该端口的其他操作。
#      portType         指定预约的端口类型。默认为"Ethernet"
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::ReservePort {portLocation portName {portType "Ethernet"}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::ReservePort预约端口
		if {[catch {set res [TestCenter::ReservePort $portLocation $portName $portType]} err] == 1} {

			set msg "调用TestCenter::ReservePort发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

			# 备份成功预约的端口名，以便其他操作使用
			lappend ::ATTTestCenter::reservePort $portName
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:   ::ATTTestCenter::ConfigPort {portName args}
#Description:  配置Ethernet端口的属性
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      portName     表示要配置的端口的名字，这里的端口名是预约端口时指定的名字
#      args         表示要配置的端口的属性的列表，格式为{-options value ...},端口的具体属性如下：
#        -mediaType   表示端口介质类型，取值范围为COPPER、FIBER。默认为COPPER
#        -linkSpeed   表示端口速率，取值范围为10M,100M,1G,10G,AUTO。默认为AUTO
#        -duplexMode  表示端口的双工模式，取值范围为FULL、HALF。默认为FULL
#        -autoNeg     表示是否开启端口的自协商模式，取值范围为Enable、Disable。默认为Enable
#        -autoNegotiationMasterSlave 表示自协商模式，取值范围为MASTER,SLAVE。默认为MASTER
#        -flowControl 表示是否开启端口的流控功能，取值范围为ON、OFF。默认为OFF
#        -mtuSize     表示端口的MTU。默认为1500
#        -portMode    仅针对10G,取值范围为LAN、WAN。默认为LAN
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::ConfigPort {portName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::ConfigPort配置端口的属性
		if {[catch {set res [TestCenter::ConfigPort $portName $args]} err] == 1} {

			set msg "调用TestCenter::ConfigPort发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:   ::ATTTestCenter::GetPortState {portName state}
#Description:  获取Ethernet端口的状态信息，包括端口的物理状态，链路状态，链路速率，链路双工状态
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      portName     表示要获取状态的端口的名字，这里的端口名是预约端口时指定的名字
#      state        表示要获取端口的哪一种状态，取值范围为：PhyState,LinkState, LinkSpeed, DuplexMode
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $state $msg 表示成功
#    $ATT_TESTCENTER_FAIL "err"  $msg 表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::GetPortState {portName state} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set portStates ""
	set value "err"
	set tmpState -$state

	foreach once {once} {

		# 调用::TestCenter::GetPortState获取端口状态信息
		if {[catch {set res [TestCenter::GetPortState $portName portStates]} err] == 1} {

			set msg "调用TestCenter::GetPortState发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
		# 获取查询的状态项的值,状态项可以不区分大小写
		set index [lsearch -nocase $portStates $tmpState]
		if {$index != -1} {

			set value [lindex $portStates [expr $index + 1]]
            set msg "获取端口$portName 的$state 属性成功，其值为$value 。"
		} else {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg "不支持查询状态项 $state.请确认拼写是否正确."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $value] [list string $msg] ]]
}


#*******************************************************************************
#Function:   ::ATTTestCenter::CreateProfile {portName profileName args}
#Description:    创建profile, profile中设置的属性可应用于端口
#Calls:   无
#Data Accessed:    无
#Data Updated:   无
#Input:
#     portName      表示需要创建profile的端口名，这里的端口名是预约端口时指定的名字
#     profileName   表示需要创建的profile名字，该名字可用于后面对profile的其他操作
#     args          表示profile的特性参数,格式为{-option value ...}.具体特性参数如下：
#        -Type             表示数据流是持续的还是突发的，取值范围Constant/Burst，默认为Constant
#        -TrafficLoad      表示流量的负荷（结合流量的单位设置该值），默认为10
#        -TrafficLoadUnit  表示流量单位，取值范围fps/kbps/mbps/percent，默认为Percent
#        -BurstSize        表示当type是Burst时，连续发送的报文数量，默认为1
#        -FrameNum         表示一次发送报文的数量（如果type为burst，应设置为 BurstSize 的整数倍），默认为100
#        -Blocking         表示是否开启堵塞模式（Enable/Disable），默认为Disable
#
#Output:    无
# Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#Others:         无
#*******************************************************************************
proc ::ATTTestCenter::CreateProfile {portName profileName args} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成traffic对象名，portName_traffic
		set trafficName $portName\_traffic
		# 检查traffic对象是否已存在
		set isExistFlag [TestCenter::IsObjectExist $trafficName]
		if {$isExistFlag == 0} {
			# 调用::TestCenter::CreateTraffic创建Traffic对象
			if {[catch {set res [TestCenter::CreateTraffic $portName $trafficName ] } err] == 1} {

				set msg "调用TestCenter::CreateTraffic发生异常，错误信息为: $err ."
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
			# 判断执行结果
			if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

				set msg [lindex $res 1]
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
		}

		# 调用::TestCenter::SetupTrafficProfile创建profile
		if {[catch {set res [TestCenter::SetupTrafficProfile $trafficName $profileName $args ] } err] == 1} {

			set msg "调用TestCenter::SetupTrafficProfile发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建 $profileName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateEmptyStream {portName streamName args}
#Description:  创建空流，仅创建流的名字， 帧长度以及速率等属性，
#             其他报文的内容通过 ADD PDU 的方式构造
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName     表示需要创建stream的端口名，这里的端口名是预约端口时指定的名字
#    streamName   表示需要创建的stream的名字，该名字可用于后面对stream的其他操作
#    args         表示流对象的属性列表，格式为{-option value ...}。具体的流对象属性如下：
#       -FrameLen   指明数据帧长度，单位为byte，默认为128
#       -StreamType 指明流量模板类型; 取值范围为:Normal,VPN,PPPoX DHCP…默认为Normal
#       -FrameLenMode 指明数据帧长度的变化方式，fixed | increment | decrement | random
#                     参数设置为random时，随机变化范围为:( FrameLen至FrameLen+ FrameLenCount-1)
#                     默认为fixed
#       -FrameLenStep 表示数据帧长度的变化步长，默认为1
#       -FrameLenCount 表示数据帧长度变化的数量，默认为1
#       -insertsignature 指明是否在数据流中插入signature field，取值：true | false  默认为true，插入signature field
#       -ProfileName     指明stream要使用的Profile 的名字，这里的profile必须是之前创建过的profile
#       -FillType        指明Payload的填充方式，取值范围为CONSTANT | INCR |DECR | PRBS，默认为CONSTANT
#       -ConstantFillPattern  当FillType为Constant的时候，相应的填充值。默认为0
#       -EnableFcsErrorInsertion  指明是否插入CRC错误帧，取值范围为TRUE | FALSE，默认为FALSE
#       -EnableStream  指定modifier使用stream/flow功能, 当使用stream模式时，单端口stream数不能超过32k。
#                      取值范围TRUE | FALSE，默认为FALSE
#       -TrafficPattern 主要用于流绑定的情形（使用SrcPoolName以及DstPoolName时），
#                        取值范围为PAIR | BACKBONE | MESH，默认为PAIR
#
#Output:    无
# Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:    无
#*******************************************************************************
proc ::ATTTestCenter::CreateEmptyStream {portName streamName args} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成traffic对象名，portName_traffic
		set trafficName $portName\_traffic

		# 检查traffic对象是否已存在
		set isExistFlag [TestCenter::IsObjectExist $trafficName]
		if {$isExistFlag == 0} {
			# 调用::TestCenter::CreateTraffic创建Traffic对象
			if {[catch {set res [TestCenter::CreateTraffic $portName $trafficName ] } err] == 1} {

				set msg "调用TestCenter::CreateTraffic发生异常，错误信息为: $err ."
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
			# 判断执行结果
			if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

				set msg [lindex $res 1]
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
		}

		# 调用::TestCenter::SetupStream创建流
		if {[catch {set res [TestCenter::SetupStream $trafficName $streamName $args ] } err] == 1} {

			set msg "调用TestCenter::SetupStream发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建 $streamName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateHeader {headerName headerType args}
#Description:   创建数据报的报头PDU
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      headerName     表示需要创建的数据报的报头名字，该名字可用于后面对报头PDU的其他操作
#      headerType     表示需要创建的数据报的报头类型，取值范围为：
#                     Eth | Vlan | IPV4 | TCP | UDP | MPLS | IPV6 | POS | HDLC
#      args           表示配置属性的参数列表，格式为{-option value ...},具体参数根据报文类型有所不同。
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无

#*******************************************************************************
proc ::ATTTestCenter::CreateHeader {headerName headerType args} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupHeader创建header pdu
		if {[catch {set res [TestCenter::SetupHeader $headerName $headerType $args]} err] == 1} {

			set msg "调用TestCenter::SetupHeader发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "创建$headerName header成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreatePacket {packetName packetType args}
#Description:   创建数据报的报文PDU
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    packetName     指明需要创建的数据报的报文对象名,该名字可用于后面对该报文PDU的其他操作
#    packetType     表示需要创建的数据报的报文类型，取值范围为：
#                    DHCP | PIM | IGMP | PPPoE | ICMP | ARP | Custom
#    args           表示配置属性的参数列表，格式为{-option value ...},具体参数根据报文类型有所不同。
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreatePacket {packetName packetType args} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupPacket创建packet PDU
		if {[catch {set res [TestCenter::SetupPacket $packetName $packetType $args]} err] == 1} {

			set msg "调用TestCenter::SetupPacket发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "创建$packetName packet成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::AddPDUToStream {streamName PduList}
#Description:   将PDUList中的PDU添加进streamName中,这里的pdu指的是前面创建的header和packet
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    streamName     指定要添加PDU的steam对象,这里的streamName必须是前面已经创建好的stream名字
#    PduList        表示需要添加到streamName中的PDU列表。
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::AddPDUToStream {streamName PduList} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::AddPDUToStream添加PDU到stream中
		if {[catch {set res [TestCenter::AddPDUToStream $streamName $PduList]} err] == 1} {

			set msg "调用TestCenter::AddPDUToStream发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::ClearTestResult {portOrStream {nameList ""}}
#Description:   清零当前的测试统计结果
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       portOrStream: 指明是清零端口的统计结果还是stream的统计结果，或者是所有的统计结果，取值范围为 port | stream | all
#       nameList: 表示端口名list或者stream名list，如果为空，表示清零所有结果
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::ClearTestResult {portOrStream {nameList ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::ClearTestResult清零指定对象的统计结果
		if {[catch {set res [TestCenter::ClearTestResult $portOrStream $nameList]} err] == 1} {

			set msg "调用TestCenter::ClearTestResult发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateFilter {portName filterName filterType filterValue {filterOnStreamId FALSE}}
#Description:   在指定端口创建过滤器
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建过滤器的端口名，这里的端口名是预约端口时指定的名字
#    filterName 表示需要创建的过滤器名
#    filterType 表示过滤器对象类型 UDF 或者Stack
#    filterValue 表示过滤器对象的值，格式为{{FilterExpr1}{FilterExpr2}…}
#         当FilterType为Stack时，FilterExpr 的格式为：
#              -ProtocolField ProtocolField -min min -max max -mask mask
#              -ProtocolField: 指明具体的过滤字段，必选参数。ProtocolField 的具体过虑字段及说明如下：
#                  srcMac   源 MAC 地址
#                  dstMac   目的 MAC 地址
#                  Id        VLAN ID
#                  Pri       VLAN 优先级
#                  srcIp     源 IP 地址
#                  dstIp     目的 IP地址
#                  tos       Ipv4中tos字段
#                  pro       Ipv4协议字段
#                  srcPort   TCP、UDP协议源端口号
#                  dstPort   TCP、UDP协议源端口号
#              -min：指明过滤字段的起始值。必选参数
#              -max:指明过滤字段的最大值。可选参数，若未指定，默认值为 min
#              -mask：指明过滤字段的掩码值。可选参数，取值与具体的字段相关。
#         当FilterType为UDF时，FilterExpr 的格式为：
#              -pattern pattern -offset offset  -max max -mask mask
#              -Pattern：表示过滤匹配值， 16 进制。必选参数，例如0x0806
#              -max： 表示匹配的最大值，16进制。可选参数默认与Pattern相同
#              -Offset：表示偏移值，可选参数，默认值为 0，起始位置从包的第一个字节起
#              -Mask：表示掩码值, 16 进制.可选参数，默认值为与 pattern长度相同的全 f。例如 0xffff
#       filterOnStreamId  表示是否使用StreamId进行过滤，这种情况针对
#                          获取流的实时统计比较有效。取值范围为TRUE/FALSE，默认为FALSE
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateFilter {portName filterName filterType filterValue {filterOnStreamId FALSE}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupFilter创建过滤器
		if {[catch {set res [TestCenter::SetupFilter $portName $filterName $filterType $filterValue $filterOnStreamId]} err] == 1} {

			set msg "调用TestCenter::SetupFilter发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$filterName 成功!"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StartCapture {portName {savePath ""} {filterName ""}}
#Description:   在指定的端口上开始抓包，保存报文到指定路径下，
#              如果没有给定保存路径，则保存到默认路径下
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示需要开启捕获报文的端口名，这里的端口名是预约端口时指定的名字
#    savePath        表示捕获的报文保存的路径名。如果该参数为空，
#                    则保存到默认路径下
#    filterName      表示要过滤保存报文使用的过滤器的名字
#
#Output:         无
# Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::StartCapture {portName {savePath ""} {filterName ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成分析引擎Analysis对象名，portName_Analysis
		set AnalysisName $portName\_Analysis

		# 检查Analysis对象是否已存在
		set isExistFlag [TestCenter::IsObjectExist $AnalysisName]

		# Analysis对象不存在，创建新的对象
		if {$isExistFlag == 0} {
			# 调用::TestCenter::SetupStaEngine创建Analysis对象
			if {[catch {set res [TestCenter::SetupStaEngine $portName $AnalysisName Analysis] } err] == 1} {

				set msg "调用TestCenter::SetupStaEngine发生异常，错误信息为: $err ."
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
			# 判断执行结果
			if {[lindex $res 0] != $TestCenter::ExpectSuccess} {
				set msg [lindex $res 1]
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
		}

		# 调用::TestCenter::StartCapture开启抓包
		if {[catch {set res [TestCenter::StartCapture $AnalysisName $savePath $filterName] } err] == 1} {

			set msg "调用TestCenter::SetupStaEngine发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portName 开启报文捕获成功"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StopCapture {portName}
#Description:    停止抓包
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      portName   表示需要停止捕获报文的端口名，这里的端口名是预约端口时指定的名字
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:         无
#*******************************************************************************
proc ::ATTTestCenter::StopCapture {portName} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成分析引擎Analysis对象名，portName_Analysis
		set AnalysisName $portName\_Analysis

		# 检查Analysis对象是否已存在
		set isExistFlag [TestCenter::IsObjectExist $AnalysisName]

		# Analysis对象不存在，返回失败
		if {$isExistFlag == 0} {
			set msg "$portName 端口未开启抓包，不用停止抓包."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::StopCapture停止抓包
		if {[catch {set res [TestCenter::StopCapture $AnalysisName]} err] == 1} {

			set msg "调用TestCenter::StopCapture发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portName 停止报文捕获成功"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::TrafficOnPort {{trafficTime 0} {flagArp "TRUE"} {portList ""}}
#Description:   基于端口开始发流，发指定时间的流，停止发流，
#              如果trafficTime为0,则开启发流后，立刻返回，由用户停止
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    trafficTime     表示发流时间，单位为s,默认为0
#    flagArp         表示是否进行ARP学习，为TRUE, 进行，为FLASE，不进行，默认为TRUE
#    portList        表示由需要发流的端口名组成的列表。为空表示所有端口 ，默认为空
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::TrafficOnPort {{trafficTime 0} {flagArp "TRUE"} {portList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 准备统计引擎,调用::ATTTestCenter::SetupStaEngine创建并开启统计引擎
		if {[catch {set res [::ATTTestCenter::SetupStaEngine] } err] == 1} {

			set msg "调用::ATTTestCenter::SetupStaEngine发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $::ATT_TESTCENTER_SUC} {
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 获取需要发流的端口
		if { $portList != "" } {
			set tmpPortList $portList
		} else {
			set tmpPortList $::ATTTestCenter::reservePort
		}
		# 调用::TestCenter::PortStartTraffic开始发流
		if {[catch {set res [TestCenter::PortStartTraffic "chassis1" $tmpPortList 1 $flagArp]} err] == 1} {

			set msg "调用TestCenter::PortStartTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 判断发流时间,如果为0，立刻返回，否则等待发流，时间到后，停止发流
		if {$trafficTime == 0} {
			set msg "开启发流成功!"
			set nRet $::ATT_TESTCENTER_SUC
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
			break
		}

		# 等待发流
		set sendTime [expr $trafficTime * 1000]
		after $sendTime

		# 停止发流
		# 调用::TestCenter::PortStopTraffic停止发流
		if {[catch {set res [TestCenter::PortStopTraffic "chassis1" $tmpPortList]} err] == 1} {

			set msg "调用TestCenter::PortStopTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portList 发流已经成功完成!"
		}

	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StopTrafficOnPort {portList}
#Description:   控制端口停止发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portList      表示需要停止发流的端口的端口名列表。为空表示所有端口，默认为空
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:    无
#*******************************************************************************
proc ::ATTTestCenter::StopTrafficOnPort {{portList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {
		# 获取需要停止发流的端口列表
		if {$portList == ""} {
			set tmpPortList $::ATTTestCenter::reservePort
		} else {
			set tmpPortList $portList
		}

		# 调用::TestCenter::PortStopTraffic停止发流
		if {[catch {set res [TestCenter::PortStopTraffic "chassis1" $tmpPortList]} err] == 1} {

			set msg "调用TestCenter::PortStopTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portList 停止发流成功!"
		}
	}
	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::TrafficOnStream {portName {flagArp "TRUE" } {trafficTime 0} {streamList ""}}
#Description:   基于数据流开始发流，发指定时间的流后，停止发流，如果时间为0，立刻返回，由用户停止
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示发流stream所属端口的端口对象名
#    flagArp         表示是否进行ARP学习，为TRUE, 进行，为FLASE，不进行，默认为TRUE
#    trafficTime     表示发流时间，单位为s，默认为0
#    streamList      表示需要发流的stream的名字列表。为空表示该端口下所有流,默认为空
#
#Output:  无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::TrafficOnStream {portName {flagArp "TRUE"} {trafficTime 0} {streamList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 准备统计引擎,调用::ATTTestCenter::SetupStaEngine创建并开启统计引擎
		if {[catch {set res [::ATTTestCenter::SetupStaEngine] } err] == 1} {

			set msg "调用::ATTTestCenter::SetupStaEngine发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $::ATT_TESTCENTER_SUC} {
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::StreamStartTraffic开启发流
		if {[catch {set res [TestCenter::StreamStartTraffic $portName 1 $flagArp $streamList]} err] == 1} {

			set msg "调用TestCenter::StreamStartTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 判断发流时间,如果为0，立刻返回，否则等待发流，时间到后，停止发流
		if {$trafficTime == 0} {
			set msg "开启发流成功!"
			set nRet $::ATT_TESTCENTER_SUC
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
			break
		}

		# 等待发流
		set sendTime [expr $trafficTime * 1000]
		after $sendTime

		# 停止发流
		# 调用::TestCenter::StreamStopTraffic停止发流
		if {[catch {set res [TestCenter::StreamStopTraffic $portName $streamList]} err] == 1} {

			set msg "调用TestCenter::StreamStopTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portName 上的数据流 $streamList 发流已经成功完成!"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StopTrafficOnStream {portName {streamList ""}}
#Description:   控制stream停止发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName       表示发流stream所属端口的端口对象名
#    streamList     表示需要停止发流的stream的名字列表。为空表示该端口下所有流
#
#Output:    无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:    无
#*******************************************************************************
proc ::ATTTestCenter::StopTrafficOnStream {portName {streamList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::StreamStopTraffic停止发流
		if {[catch {set res [TestCenter::StreamStopTraffic $portName $streamList]} err] == 1} {

			set msg "调用TestCenter::StreamStopTraffic发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "端口$portName 上的数据流 $streamList 成功停止发流!"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::GetPortStatsSnapshot {portName {filterStream "0"} {resultPath ""}}
#Description:   获取端口统计信息快照
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName         表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
#    filterStream     表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值
#    resultPath      表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:  无
#*******************************************************************************
proc ::ATTTestCenter::GetPortStatsSnapshot {portName {filterStream "0"} {resultPath ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成统计引擎StaEngine对象名，portName_StaEngine
		set StaEngineName $portName\_StaEngine

		# 检查StaEngine对象是否存在
		set isExistFlag [TestCenter::IsObjectExist $StaEngineName]

		# StaEngine对象不存在，返回失败
		if {$isExistFlag == 0} {
			set msg "$portName 端口未开启发流，不能获取统计结果."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::GetPortStatsSnapshot获取统计信息
		set resultData ""
		if {[catch {set res [TestCenter::GetPortStatsSnapshot $StaEngineName resultData $filterStream $resultPath]} err] == 1} {

			set msg "调用TestCenter::GetPortStatsSnapshot发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
            set ::ATTTestCenter::PortStatsSnapshot($portName) $resultData

            # set msg display to user
            set msg "获取端口$portName 的统计快照成功。结果为：$resultData"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::GetStreamStatsSnapshot {portName streamName {resultPath ""}}
#Description:   获取Stream统计信息快照
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
#    streamName      表示需要统计的流的名字，这里的stream名必须是创建过的stream
#    resultPath      表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下
#
#Output:    无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::GetStreamStatsSnapshot {portName streamName {resultPath ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 根据portName生成统计引擎StaEngine对象名，portName_StaEngine
		set StaEngineName $portName\_StaEngine

		# 检查StaEngine对象是否存在
		set isExistFlag [TestCenter::IsObjectExist $StaEngineName]

		# StaEngine对象不存在，返回失败
		if {$isExistFlag == 0} {
			set msg "$portName 端口未开启发流，不能获取统计结果."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::GetStreamStatsSnapshot获取统计信息
		set resultData ""

		if {[catch {set res [TestCenter::GetStreamStatsSnapshot $StaEngineName $streamName resultData $resultPath]} err] == 1} {

			set msg "调用TestCenter::GetStreamStatsSnapshot发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            set ::ATTTestCenter::StreamStatsSnapshot($streamName) $resultData

            # set msg display to user
            set msg "获取数据流$streamName 的统计结果快照成功。结果为：$resultData"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::GetPortStats {portName {filterStream "0"} {subOption ""}}
#Description:   从端口统计信息中获取指定项option的信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName         表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
#    filterStream     表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值
#    subOption        表示需要获取的统计结果子项名。如果为空，返回所有信息
#
#Output:   无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:  无
#*******************************************************************************
proc ::ATTTestCenter::GetPortStats {portName {filterStream "0"} {subOption ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set resultData ""

	foreach once {once} {

        # 判断portName是否已有快照
        set tmpInfo [array get ::ATTTestCenter::PortStatsSnapshot $portName]
		if {$tmpInfo != ""} {
            # 已经有快照，直接查找子项值
            set result [lindex $tmpInfo 1]
			# 获取指定子项的值，如果没有指定，返回所有结果
            if {$subOption != ""} {

                set index [lsearch -nocase $result -$subOption]
                if {$index != -1} {

                    set resultData [lindex $result [expr $index + 1]]
                    set msg "从$portName 的统计结果快照中获取$subOption 成功，其值为$resultData 。"
                    LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
                } else {

                    set msg "从$portName 的统计结果快照中获取$subOption的信息失败，统计结果快照为:$result ."
                    LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                    set nRet $::ATT_TESTCENTER_FAIL
                    break
                }
			} else {

                set resultData $result
                set msg "从$portName 的统计结果快照中获取$subOption 成功，其值为$resultData 。"
                LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
			}
		} else {
            # 还没有快照，获取实时数据值

            # 根据portName生成统计引擎StaEngine对象名，portName_StaEngine
            set StaEngineName $portName\_StaEngine

            # 检查StaEngine对象是否存在
            set isExistFlag [TestCenter::IsObjectExist $StaEngineName]

            # StaEngine对象不存在，返回失败
            if {$isExistFlag == 0} {
                set msg "$portName 端口未开启发流，不能获取统计结果."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }

            # 调用::TestCenter::GetPortStats获取统计信息
            if {[catch {set res [TestCenter::GetPortStats $StaEngineName resultData $filterStream $subOption]} err] == 1} {

                set msg "调用TestCenter::GetPortStats发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            } else {

                set msg [lindex $res 1]
                LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

                # set msg display to user
                set msg "获取端口$portName 的$subOption 成功，其值为$resultData 。"
            }
        }
	}

	return [list array [list [list int $nRet] [list string $resultData] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::GetStreamStats {portName streamName option}
#Description:   从Stream统计信息中获取指定项option的信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示获取统计信息的端口名，这里的端口名是预约端口时指定的名字
#    streamName      表示需要统计的流的名字，这里的stream名必须是创建过的stream
#    subOption       表示需要获取的统计结果的子项名。如果为空，返回所有子项信息
#Output:    无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::GetStreamStats {portName streamName {subOption ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

        # 判断streamName是否已有快照
        set tmpInfo [array get ::ATTTestCenter::StreamStatsSnapshot $streamName]
		if {$tmpInfo != ""} {
            # 已经有快照，直接查找子项值
            set result [lindex $tmpInfo 1]
			# 获取指定子项的值，如果没有指定，返回所有结果
            if {$subOption != ""} {

                set index [lsearch -nocase $result -$subOption]
                if {$index != -1} {

                    set resultData [lindex $result [expr $index + 1]]
                    set msg "从$streamName 的统计结果快照中获取$subOption 成功，其值为$resultData 。"
                    LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
                } else {

                    set msg "从$streamName 的统计结果快照中获取$subOption的信息失败，统计结果快照为:$result ."
                    LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                    set nRet $::ATT_TESTCENTER_FAIL
                    break
                }
			} else {

                set resultData $result
                set msg "从$streamName 的统计结果快照中获取$subOption 成功，其值为$resultData 。"
                LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
			}
		} else {
            # 还没有快照，获取实时数据值

            # 根据portName生成统计引擎StaEngine对象名，portName_StaEngine
            set StaEngineName $portName\_StaEngine

            # 检查StaEngine对象是否存在
            set isExistFlag [TestCenter::IsObjectExist $StaEngineName]

            # StaEngine对象不存在，返回失败
            if {$isExistFlag == 0} {
                set msg "$portName 端口未开启发流，不能获取统计结果."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }

            # 调用::TestCenter::GetStreamStats获取统计信息
            set resultData ""

            if {[catch {set res [TestCenter::GetStreamStats $StaEngineName $streamName resultData $subOption ]} err] == 1} {

                set msg "调用TestCenter::GetStreamStats发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            } else {

                set msg [lindex $res 1]
                LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

                # set msg display to user
                set msg "获取数据流$streamName 的$subOption 成功，其值为$resultData 。"
            }
        }
	}

	return [list array [list [list int $nRet] [list string $resultData] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateHost {portName hostName args}
#Description:   在指定端口创建Host，并配置host的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建host的端口名，这里的端口名是预约端口时指定的名字
#    hostName   表示需要创建的host的名字。该名字用于后面对该host的其他操作
#    args       表示需要创建的IGMP host的属性列表。其格式为{-option value}.host的属性有：
#       -IpVersion       指明IP的版本,可设置ipv4/ipv6，默认为ipv4
#       -HostType        指明服务器类型，可设置normal/IgmpHost/MldHost，默认为normal
#       -Ipv4Addr        指明主机ipv4地址，默认为192.168.1.2
#       -Ipv4AddrGateway 指明主机ipv4网关，默认为192.168.1.1
#       -Ipv4StepMask    指明主机ipv4的掩码，默认为0.0.0.255
#       -Ipv4Mask        表示Host IPv4地址Prefix长度
#       -Ipv6Addr        指明主机ipv6地址，默认为 2000:201::1:2
#       -Ipv6StepMask    指明主机ipv6的掩码，默认为0000::FFFF:FFFF:FFFF:FFFF
#       -Ipv6LinkLocalAddr 表示Host起始IPv6 Link Local地址，默认为fe80::
#       -Ipv6AddrGateway  指明主机ipv6网关，默认为2000:201::1:1
#       -Ipv6Mask         指明主机ipv6网关，默认为64
#       -MacAddr          指明Host起始MAC地址，默认内部自动生成，依次递增00:20:94:SlotId:PortId:seq
#       -MacStepMask      指明Host起始MAC的掩码地址，默认为00:00:FF:FF:FF:FF
#       -MacCount         指明Mac地址变化的数量，默认为1
#       -MacIncrease      指明Mac地址递增的步长，默认为1
#       -Count            指明Host IP地址个数，默认为1
#       -Increase         指明IP地址增幅，默认为1
#       -FlagPing         指明是否支持Ping功能，enable/disable，默认为enable
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateHost {portName hostName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName

	foreach once {once} {

        # 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        # 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$hostName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

		# 调用::TestCenter::SetupHost创建host
		if {[catch {set res [TestCenter::SetupHost $IntName $hostName $args]} err] == 1} {

			set msg "调用TestCenter::SetupHost发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StartARPStudy {srcHost dstHost retries interval}
#Description:   发送ARP请求，学习目的主机的MAC地址
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    srcHost  表示发送ARP请求的主机名
#    dstHost  表示所请求的目的IP地址或者主机名称，默认为网关地址或者地址列表
#    retries   指明Arp请求失败重试次数，默认为3
#    interval  表示发送两个ARP请求的间隔时间，单位s，默认为1
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::StartARPStudy {srcHost {dstHost ""} {retries "3"} {interval "1"}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupHost创建host
		if {[catch {set res [TestCenter::StartARPStudy $srcHost $dstHost $retries $interval]} err] == 1} {

			set msg "调用TestCenter::StartARPStudy发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateDHCPServer {portName routerName args}
#Description:   在指定端口创建DHCP server，并配置DHCP server的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName     表示需要创建DHCP Server的端口名，这里的端口名是预约端口时指定的名字
#    routerName   表示需要创建的DHCP Server的名字。该名字用于后面对该DHCP Server的其他操作
#    args         表示需要创建的DHCP Server的属性列表。其格式为{-option value}.router的属性有：
#       -PoolName     可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
#                     注意：PoolName和routerName不要相同，默认为空。
#       -RouterId     表示指定的RouterId，默认为1.1.1.1
#       -LocalMac     表示server接口MAC，默认为00:00:00:11:01:01
#       -TesterIpAddr 表示server接口IP，默认为192.0.0.2
#       -PoolStart    表示地址池开始的IP地址，默认为192.0.0.1
#       -PoolNum      表示地址池的数量，默认为254
#       -PoolModifier 表示地址池中变化的步长，步长从IP地址的最后一位依次增加，默认为1
#       -FlagGateway  表示是否配置网关IP地址，默认为FALSE
#       -Ipv4Gateway  表示网关IP地址，默认为192.0.0.1
#       -Active       表示DHCP server会话是否激活，默认为TRUE
#       -LeaseTime    表示租约时间，单位为秒。默认为3600
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateDHCPServer {portName routerName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName
    set argsSetupRouter ""

    foreach once {once} {

		# 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        # 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$routerName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

        # 判断是否要设置RouterId
        set index [lsearch -nocase $args -RouterId]
        if {$index != -1} {

            set RouterId [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
            set argsSetupRouter [list -RouterId $RouterId]
        }

        # 调用::TestCenter::SetupRouter创建DHCP Server
        if {[catch {set res [TestCenter::SetupRouter $IntName $routerName DHCPServer $argsSetupRouter]} err] == 1} {

            set msg "调用TestCenter::发生异常，错误信息为: $err ."
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

            set msg [lindex $res 1]
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }

        # 调用::TestCenter::SetupDHCPServer创建DHCP Server
		if {[catch {set res [TestCenter::SetupDHCPServer $routerName $args]} err] == 1} {

			set msg "调用TestCenter::SetupDHCPServer发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$routerName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::EnableDHCPServer {routerName}
#Description:   开启DHCP Server，开始协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要开始协议仿真的DHCP Server名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::EnableDHCPServer {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::EnableDHCPServer开启DHCP Server仿真
        if {[catch {set res [TestCenter::EnableDHCPServer $routerName]} err] == 1} {

			set msg "调用TestCenter::EnableDHCPServer 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::DisableDHCPServer {routerName}
#Description:   关闭DHCP Server，停止协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要停止协议仿真的DHCP Server名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::DisableDHCPServer {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::DisableDHCPServer关闭DHCP Server仿真
        if {[catch {set res [TestCenter::DisableDHCPServer $routerName]} err] == 1} {

			set msg "调用TestCenter::DisableDHCPServer 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateDHCPClient {portName routerName args}
#Description:   在指定端口创建DHCP Client，并配置DHCP Client的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName     表示需要创建DHCP Client的端口名，这里的端口名是预约端口时指定的名字
#    routerName   表示需要创建的DHCP Client的名字。该名字用于后面对该DHCP Client的其他操作
#    args         表示需要创建的DHCP Client的属性列表。其格式为{-option value}.router的属性有：
#       -PoolName     可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
#                     注意：PoolName和routerName不要相同，默认为空。
#       -RouterId     表示指定的RouterId，默认为1.1.1.1
#       -LocalMac        表示Client接口MAC，默认为00:00:00:11:01:01
#       -Count           表示模拟的主机数量，默认为1
#       -AutoRetryNum    表示最大尝试建立连接的次数，默认为1
#       -FlagGateway     表示是否配置网关IP地址，默认为FALSE
#       -Ipv4Gateway     表示网关IP地址，默认为空
#       -Active          表示DHCP server会话是否激活，默认为TRUE
#       -FlagBroadcast   表示广播标识位，广播为TRUE，单播为FALSE，默认为TRUE
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateDHCPClient {portName routerName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName
    set argsSetupRouter ""

    foreach once {once} {

		# 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        # 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$routerName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

        # 判断是否要设置RouterId
        set index [lsearch -nocase $args -RouterId]
        if {$index != -1} {

            set RouterId [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
            set argsSetupRouter [list -RouterId $RouterId]
        }

        # 调用::TestCenter::SetupRouter创建DHCP Client
        if {[catch {set res [TestCenter::SetupRouter $IntName $routerName DHCPClient $argsSetupRouter]} err] == 1} {

            set msg "调用TestCenter::发生异常，错误信息为: $err ."
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

            set msg [lindex $res 1]
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }

        # 调用::TestCenter::SetupDHCPServer创建DHCP Client
		if {[catch {set res [TestCenter::SetupDHCPClient $routerName $args]} err] == 1} {

			set msg "调用TestCenter::SetupDHCPServer发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$routerName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::EnableDHCPClient {routerName}
#Description:   使能DHCP Client
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要使能的DHCP Client名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::EnableDHCPClient {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::EnableDHCPClient使能DHCP Client
        if {[catch {set res [TestCenter::EnableDHCPClient $routerName]} err] == 1} {

			set msg "调用TestCenter::EnableDHCPClient 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::DisableDHCPClient {routerName}
#Description:   停止DHCP Client
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要停止的DHCP Client名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::DisableDHCPClient {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::DisableDHCPClient停止DHCP Client
        if {[catch {set res [TestCenter::DisableDHCPClient $routerName]} err] == 1} {

			set msg "调用TestCenter::DisableDHCPClient 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::MethodDHCPClient {routerName method}
#Description:   DHCP Client协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示创建的DHCP client的名字
#    method:      表示DHCP client仿真的方法，
#        Bind:       启动DHCP 绑定过程
#        Release:    释放绑定过程
#        Renew:      重新启动DHCP 绑定过程
#        Abort:      停止所有active Session的dhcp router，迫使其状态进入idle
#        Reboot:     迫使dhcp router重新reboot。即完成一个完整的过程，重新开始新的一个循环。
#                    Reboot应该发送请求以前分配的IP地址。
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::MethodDHCPClient {routerName method} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::MethodDHCPClient开始DHCP Client仿真
        if {[catch {set res [TestCenter::MethodDHCPClient $routerName $method]} err] == 1} {

			set msg "调用TestCenter::MethodDHCPClient 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreatePPPoEServer {portName routerName args}
#Description:   在指定端口创建PPPoE server，并配置PPPoE server的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName     表示需要创建PPPoE Server的端口名，这里的端口名是预约端口时指定的名字
#    routerName   表示需要创建的PPPoE Server的名字。该名字用于后面对该DHCP Server的其他操作
#    args         表示需要创建的PPPoE Server的属性列表。其格式为{-option value}.router的属性有：
#       -RouterId           表示指定的RouterId，默认为1.1.1.1
#       -SourceMacAddr      表示server接口MAC，默认为00:00:00:C0:00:01
#       -PoolNum            表示支持的PPPoE Client数量，默认为1
#       -PoolName           可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
#                           注意：PoolName和routerName不要相同，默认为空。
#       -PPPoEServiceName   表示服务类型名称，默认为spirent
#       -Active             表示PPPoE server会话是否激活，默认为TRUE
#       -MRU                表示上层可接受的最大传输单元字节，默认为1492
#       -EchoRequestTimer   表示发送echo request字节的间隔时间，默认为0
#       -MaxConfigCount     表示发送config request报文的最大次数，默认为10
#       -RestartTimer       表示重新发送config request报文的等待时间，默认为3s
#       -MaxTermination     表示发送termination request报文的最大次数，默认为2
#       -MaxFailure         表示在确认PPP失败前收到的NAK报文的最大次数，默认为5
#       -AuthenticationRole 表示认证类型和模式，默认为SUT
#                           注意：定义有SUT, CHAP, PAP。SUT表示设备在测试中需要认证。
#       -AuthenUsername     表示认证用户名，默认为who
#       -AuthenPassword     表示认证密码，默认为who
#       -SourceIPAddr       表示srouce ip addr，默认为192.0.0.1
#       -EnableVlan         指明是否添加vlan，enable/disable, 默认为disable
#       -VlanId             指明Vlan id的值，取值范围0-4095（超出范围设置为0）， 默认为100
#       -VlanPriority       优先级,取值范围0-7，默认为0
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreatePPPoEServer {portName routerName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName
    set argsSetupRouter ""

    foreach once {once} {

		# 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        # 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$routerName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

        # 判断是否要设置RouterId
        set index [lsearch -nocase $args -RouterId]
        if {$index != -1} {

            set RouterId [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
            set argsSetupRouter [list -RouterId $RouterId]
        }

        # 调用::TestCenter::SetupRouter创建PPPoE Server
        if {[catch {set res [TestCenter::SetupRouter $IntName $routerName PPPoEServer $argsSetupRouter]} err] == 1} {

            set msg "调用TestCenter::发生异常，错误信息为: $err ."
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

            set msg [lindex $res 1]
            LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
            set nRet $::ATT_TESTCENTER_FAIL
            break
        }

        # 调用::TestCenter::SetupPPPoEServer创建PPPoE Server
		if {[catch {set res [TestCenter::SetupPPPoEServer $routerName $args]} err] == 1} {

			set msg "调用TestCenter::SetupPPPoEServer发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$routerName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::EnablePPPoEServer {routerName}
#Description:   开启PPPoE Server，开始协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要开始协议仿真的PPPoE Server名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::EnablePPPoEServer {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::EnablePPPoEServer开启PPPoE Server仿真
        if {[catch {set res [TestCenter::EnablePPPoEServer $routerName]} err] == 1} {

			set msg "调用TestCenter::EnablePPPoEServer 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::DisablePPPoEServer {routerName}
#Description:   关闭PPPoE Server，停止协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要停止协议仿真的PPPoE Server名称
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::DisablePPPoEServer {routerName } {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::DisablePPPoEServer关闭PPPoE Server仿真
        if {[catch {set res [TestCenter::DisablePPPoEServer $routerName]} err] == 1} {

			set msg "调用TestCenter::DisablePPPoEServer 发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
        # 判断执行结果
        if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
        }
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateIGMPHost {portName hostName args}
#Description:   在指定端口创建IGMP Host，并配置IGMP host的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建host的端口名，这里的端口名是预约端口时指定的名字
#    hostName   表示需要创建的host的名字。该名字用于后面对该host的其他操作
#    args       表示需要创建的IGMP host的属性列表。其格式为{-option value}.host的属性有：
#       -SrcMac    表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02
#       -SrcMacStep 表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1
#       -Ipv4Addr   表示Host起始IPv4地址，默认为192.85.1.3
#       -Ipv4AddrGateway  表示GateWay的IPv4地址，默认为192.85.1.1
#       -Ipv4AddrPrefixLen  表示Host IPv4地址Prefix长度，默认为24
#       -Count              表示Host IP、MAC地址个数，默认为1
#       -Increase           表示IP地址增幅，默认为1
#       -ProtocolType       表示Protocol的类型。合法值：IGMPv1/IGMPv2/IGMPv3。默认为IGMPv2
#       -SendGroupRate      指明Igmp Host发送组播协议报文时，发送报文的速率，单位fps默认为线速
#       -Active             表示IGMP Host会话是否激活，默认为TRUE
#       -V1RouterPresentTimeout 指明Igmp Host收到query与发送report报文的时间间隔，默认为400
#       -ForceRobustJoin        指明当第一个Igmpv1/v2 host加入group时，是否连续发送2个，默认为FALSE
#       -ForceLeave             指明当除最后一个之外的Igmpv2 Host从group中离开时，是否发送leave报文，默认为FALSE
#       -UnsolicitedReportInterval 指明Igmp host发送unsolicited report的时间间隔，默认为10
#       -InsertCheckSumErrors      指明是否在Igmp Host发送的报文中插入Checksum error，默认为FALSE
#       -InsertLengthErrors        指明是否在Igmp Host发送的报文中插入Length error，默认为FALSE
#       -Ipv4DontFragment          指明当报文长度大于MTU是是否需要分片，默认为FALSE
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateIGMPHost {portName hostName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName

	foreach once {once} {

		# 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

		# 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$hostName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

		# 调用::TestCenter::SetupHost创建host
		if {[catch {set res [TestCenter::SetupHost $IntName $hostName -HostType IgmpHost]} err] == 1} {

			set msg "调用TestCenter::SetupHost发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::SetupIGMPHost创建IGMP host
		if {[catch {set res [TestCenter::SetupIGMPHost $hostName $args]} err] == 1} {

			set msg "调用TestCenter::SetupIGMPHost发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$hostName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SetupIGMPGroupPool {hostName groupPoolName startIP args}
#Description:   创建或配置IGMP GroupPool
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要创建或配置IGMP GroupPool的主机名
#    groupPoolName 表示IGMP Group的名称标识，要求在当前 IGMP Host 唯一
#    startIP       表示Group 起始 IP 地址，取值约束：String，IPv4的地址值
#    args          表示IGMP Group pool的属性列表,格式为{-option value}.具体属性描述如下：
#       -PrefixLen       表示IP 地址前缀长度，取值范围：5到32，默认为24
#       -GroupCnt        表示Group 个数，取值约束：32位正整数，默认为1
#       -GroupIncrement  表示Group IP 地址的增幅，取值范围：32为正整数，默认为1
#       -FilterMode       Specific Source Filter Mode(IGMPv3), 取值范围为Include Exclude，默认为Exclude
#       -SrcStartIP       表示起始主机 IP 地址（IGMPv3），取值约束：String，默认为192.168.1.2
#       -SrcCnt           表示主机地址个数（IGMPv3），取值范围：32位整数，默认为1
#       -SrcIncrement     表示主机 IP 地址增幅（IGMPv3），取值范围：32位整数，默认为1
#       -SrcPrefixLen     表示主机 IP 地址前缀长度（IGMPv3），取值范围：1到32，默认为24
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SetupIGMPGroupPool {hostName groupPoolName startIP args} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupIGMPGroupPool创建IGMP GroupPool
		if {[catch {set res [TestCenter::SetupIGMPGroupPool $hostName $groupPoolName $startIP $args]} err] == 1} {

			set msg "调用TestCenter::SetupIGMPGroupPool发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在$hostName 创建$groupPoolName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SendIGMPLeave {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送IGMP leave（组播离开）报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示IGMP Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SendIGMPLeave {hostName {groupPoolList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SendIGMPLeave
		if {[catch {set res [TestCenter::SendIGMPLeave $hostName $groupPoolList]} err] == 1} {

			set msg "调用TestCenter::SendIGMPLeave发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SendIGMPReport {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送IGMP leave（组播离开）报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示IGMP Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SendIGMPReport {hostName {groupPoolList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SendIGMPReport
		if {[catch {set res [TestCenter::SendIGMPReport $hostName $groupPoolList]} err] == 1} {

			set msg "调用TestCenter::SendIGMPReport发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateIGMPRouter {portName routerName routerIp args}
#Description:   配置IGMP router
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示需要创建router的端口名，这里的端口名是预约端口时指定的名字
#    routerName      表示要配置的IGMP Router名
#    routerIp        表示 IGMP Router 的接口 IPv4 地址
#    args            表示IGMP router的属性列表,格式为{-option value}.具体属性描述如下：
#       -SrcMac      表示源Mac，创建多个Router时，默认值按照步长1递增
#       -ProtocolType       表示Protocol的类型。合法值：IGMPv1/IGMPv2/IGMPv3。默认为IGMPv2
#       -IgnoreV1Reports    指明是否忽略接收到的 IGMPv1 Host的报文，默认为False
#       -Ipv4DontFragment   指明当报文长度大于 MTU 时，是否进行分片，默认为False
#       -LastMemberQueryCount  表示在认定组中没有成员之前发送的特定组查询的次数，默认为2
#       -LastMemberQueryInterval  表示在认定组中没有成员之前发送指定组查询报文的 时间间隔（单位 ms），默认为1000
#       -QueryInterval            表示发送查询报文的时间间隔（单位 s），，默认为32
#       -QueryResponseUperBound   表示Igmp Host对于查询报文的响应的时间间隔的上限值（单位 ms），默认为10000
#       -StartupQueryCount      指明Igmp Router启动之初发送的Query报文的个数，取值范围：1-255,默认为2
#       -Active                表示IGMP Router会话是否激活，默认为TRUE
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateIGMPRouter {portName routerName routerIp args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetupRouter创建router
		if {[catch {set res [TestCenter::SetupRouter $portName $routerName IgmpRouter]} err] == 1} {

			set msg "调用TestCenter::SetupRouter发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::SetupIGMPRouter创建IGMP Router
		if {[catch {set res [TestCenter::SetupIGMPRouter $routerName $routerIp $args]} err] == 1} {

			set msg "调用TestCenter::SetupIGMPRouter发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$routerName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StartIGMPRouterQuery {routerName}
#Description:   开始通用IGMP查询
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName      表示要开始通用IGMP查询的IGMP Router名
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::StartIGMPRouterQuery {routerName} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::StartIGMPRouterQuery
		if {[catch {set res [TestCenter::StartIGMPRouterQuery $routerName]} err] == 1} {

			set msg "调用TestCenter::StartIGMPRouterQuery发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::StopIGMPRouterQuery {routerName}
#Description:   停止通用IGMP查询
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName      表示要开始通用IGMP查询的IGMP Router名
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::StopIGMPRouterQuery {routerName} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::StopIGMPRouterQuery
		if {[catch {set res [TestCenter::StopIGMPRouterQuery $routerName]} err] == 1} {

			set msg "调用TestCenter::StopIGMPRouterQuery发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {
			set nRet $::ATT_TESTCENTER_SUC
			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CreateMLDHost {portName hostName args}
#Description:   在指定端口创建MLD Host，并配置MLD host的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建host的端口名，这里的端口名是预约端口时指定的名字
#    hostName   表示需要创建的host的名字。该名字用于后面对该host的其他操作
#    args       表示需要创建的MLD host的属性列表。其格式为{-option value}.host的属性有：
#       -SrcMac    表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02
#       -SrcMacStep 表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1
#       -Ipv6Addr   表示Host起始IPv6地址，默认为2000::2
#       -Ipv6AddrGateway  表示GateWay的IPv6地址，默认为2000::1
#       -Ipv6AddrPrefixLen  表示Host IPv6地址Prefix长度，默认为64
#       -Count              表示Host IP、MAC地址个数，默认为1
#       -Increase           表示IP地址增幅，默认为1
#       -ProtocolType       表示Protocol的类型。合法值：MLDv1/MLDv2。默认为MLDv1
#       -SendGroupRate      指明MLD Host发送组播协议报文时，发送报文的速率，单位fps默认为线速
#       -Active             表示MLD Host会话是否激活，默认为TRUE
#       -ForceRobustJoin        指明当第一个MLD host加入group时，是否连续发送2个，默认为FALSE
#       -ForceLeave             指明当除最后一个之外的MLD Host从group中离开时，是否发送leave报文，默认为FALSE
#       -UnsolicitedReportInterval 指明MLD host发送unsolicited report的时间间隔，默认为10
#       -InsertCheckSumErrors      指明是否在MLD Host发送的报文中插入Checksum error，默认为FALSE
#       -InsertLengthErrors        指明是否在MLD Host发送的报文中插入Length error，默认为FALSE
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CreateMLDHost {portName hostName args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""
	set IntName $portName

    foreach once {once} {

        # 去掉args外层{}
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }

        # 判断是否要添加vlan
        set index [lsearch -nocase $args -EnableVlan]
        if {$index != -1} {

            set EnableVlan [lindex $args [expr $index + 1]]
            set args [lreplace $args $index [expr $index + 1]]
        } else  {
            set EnableVlan disable
        }

        # 如果要添加vlan，需要先创建vlan子接口，然后再用子接口创建host
        if {[string tolower $EnableVlan] == "enable"} {
            # 获取子接口的配置信息
            set index [lsearch -nocase $args -VlanId]
            if {$index != -1} {
                set VlanId [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanId 100
            }

            set index [lsearch -nocase $args -VlanPriority]
            if {$index != -1} {
                set VlanPriority [lindex $args [expr $index + 1]]
                set args [lreplace $args $index [expr $index + 1]]
            } else  {
                set VlanPriority 0
            }

            # 调用::TestCenter::SetupVlan创建子接口
            set vlanName vlan_$hostName
            if {[catch {set res [TestCenter::SetupVlan $portName $vlanName -VlanId $VlanId -VlanPriority $VlanPriority]} err] == 1} {

                set msg "调用TestCenter::SetupVlan发生异常，错误信息为: $err ."
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            # 判断执行结果
            if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

                set msg [lindex $res 1]
                LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
                set nRet $::ATT_TESTCENTER_FAIL
                break
            }
            LOG::DebugInfo $func $::ATTTestCenter::__FILE__  "创建Vlan子接口成功。"
            set IntName $vlanName
        }

        # 调用::TestCenter::SetupHost创建host
		if {[catch {set res [TestCenter::SetupHost $IntName $hostName -IpVersion ipv6 -HostType MldHost]} err] == 1} {

			set msg "调用TestCenter::SetupHost发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		# 调用::TestCenter::SetupMldHost创建MLD host
		if {[catch {set res [TestCenter::SetupMLDHost $hostName $args]} err] == 1} {

			set msg "调用TestCenter::SetupMLDHost发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在端口$portName 创建$hostName 成功！"
		}
    }

    return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SetupMLDGroupPool {hostName groupPoolName startIP args}
#Description:   创建或配置MLD GroupPool
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要创建或配置MLD GroupPool的主机名
#    groupPoolName 表示MLD Group的名称标识，要求在当前 MLD Host 唯一
#    startIP       表示Group 起始 IP 地址，取值约束：String，IPv6的地址值
#    args          表示IGMP Group pool的属性列表,格式为{-option value}.具体属性描述如下：
#       -PrefixLen       表示IP 地址前缀长度，取值范围：9到128，默认为64
#       -GroupCnt        表示Group 个数，取值约束：32位正整数，默认为1
#       -GroupIncrement  表示Group IP 地址的增幅，取值范围：32为正整数，默认为1
#       -SrcStartIP       表示起始主机 IP 地址（MLDv2），取值约束：String，默认为2000::3
#       -SrcCnt           表示主机地址个数（MLDv2），取值范围：32位整数，默认为1
#       -SrcIncrement     表示主机 IP 地址增幅（MLDv2），取值范围：32位整数，默认为1
#       -SrcPrefixLen     表示主机 IP 地址前缀长度（MLDv2），取值范围：1到128，默认为64
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SetupMLDGroupPool {hostName groupPoolName startIP args} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

        # 调用::TestCenter::SetupIGMPGroupPool创建IGMP GroupPool
		if {[catch {set res [TestCenter::SetupMLDGroupPool $hostName $groupPoolName $startIP $args]} err] == 1} {

			set msg "调用TestCenter::SetupMLDGroupPool发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

            # set msg display to user
            set msg "在$hostName 创建$groupPoolName 成功！"
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SendMLDLeave {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送MLD leave（组播离开）报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示MLD Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SendMLDLeave {hostName {groupPoolList ""}} {

    set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

    foreach once {once} {

		# 调用::TestCenter::SendMLDLeave
		if {[catch {set res [TestCenter::SendMLDLeave $hostName $groupPoolList]} err] == 1} {

			set msg "调用TestCenter::SendMLDLeave发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SendMLDReport {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送MLD Report（组播加入）报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示MLD Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SendMLDReport {hostName {groupPoolList ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SendMLDReport
		if {[catch {set res [TestCenter::SendMLDReport $hostName $groupPoolList]} err] == 1} {

			set msg "调用TestCenter::SendMLDReport发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SaveConfigAsXML { path }
#Description:  将脚本配置保存为xml文件
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       path  xml文件保存的路径
#Output:
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SaveConfigAsXML {path} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SaveConfigAsXML
		if {[catch {set res [TestCenter::SaveConfig $path]} err] == 1} {
			set msg "调用TestCenter::SaveConfigAsXML发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {

			set nRet $::ATT_TESTCENTER_SUC
			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SetStreamSchedulingMode {portName {schedulingMode RATE_BASED}}
#Description:  设置端口上数据流的调度模式
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       portName  端口名
#       schedulingMode 数据流的调度模式，取值范围为：PORT_BASED | RATE_BASED | PRIORITY_BASED，默认为RATE_BASED
#Output:
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SetStreamSchedulingMode {portName {schedulingMode RATE_BASED}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::SetStreamSchedulingMode设置数据流的调度模式
		if {[catch {set res [TestCenter::SetStreamSchedulingMode $portName $schedulingMode]} err] == 1} {

			set msg "调用TestCenter::SetStreamSchedulingMode发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}
		# 判断执行结果
		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

			set nRet $::ATT_TESTCENTER_FAIL
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
		} else {

			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CleanupTest {{useless ""}}
#Description:  清除测试，释放资源
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      useless    没有用的参数，仅仅是为了xmlrpc调用格式的需要，必须传参
#Output:
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CleanupTest {{useless ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 调用::TestCenter::CleanupTest
		if {[catch {set res [TestCenter::CleanupTest]} err] == 1} {
			set msg "调用TestCenter::CleanupTest发生异常，错误信息为: $err ."
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		}

		if {[lindex $res 0] != $TestCenter::ExpectSuccess} {
			set msg [lindex $res 1]
			LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
			set nRet $::ATT_TESTCENTER_FAIL
			break
		} else {
			set nRet $::ATT_TESTCENTER_SUC
			set msg [lindex $res 1]
			LOG::DebugInfo $func $::ATTTestCenter::__FILE__  $msg

			# 删除备份的预约成功的端口名
			set ::ATTTestCenter::reservePort ""
		}
	}

	return [list array [list [list int $nRet] [list string $msg]]]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::SetupStaEngine {}
#Description:  创建并开启所有端口的统计引擎
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:   无
#Output:
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::SetupStaEngine {} {

	set nRet $::ATT_TESTCENTER_SUC
	set func [::__FUNC__]
	set msg  ""

	foreach once {once} {

		# 获取需要统计的端口列表
		set tmpPortList $::ATTTestCenter::reservePort

		# 准备统计引擎
		foreach portName $tmpPortList {
			# 针对每一个端口生成统计引擎StaEngine对象名，portName_StaEngine
			set StaEngineName $portName\_StaEngine

			# 检查StaEngine对象是否已存在
			set isExistFlag [TestCenter::IsObjectExist $StaEngineName]

			# StaEngine对象不存在，创建新的对象
			if {$isExistFlag == 0} {
				# 调用::TestCenter::SetupStaEngine创建StaEngine对象
				if {[catch {set res [TestCenter::SetupStaEngine $portName $StaEngineName ] } err] == 1} {

					set msg "调用TestCenter::SetupStaEngine发生异常，错误信息为: $err ."
					LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
					set nRet $::ATT_TESTCENTER_FAIL
					break
				}
				# 判断执行结果
				if {[lindex $res 0] != $TestCenter::ExpectSuccess} {
					set msg [lindex $res 1]
					LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
					set nRet $::ATT_TESTCENTER_FAIL
					break
				}
			}
		}

		# 如果创建统计引擎失败，退出循环，返回失败
		if {$nRet == $::ATT_TESTCENTER_FAIL} {
			break
		}

		# 开启统计引擎
		foreach portName $tmpPortList {
			# 调用::TestCenter::StartStaEngine开启统计引擎
			if {[catch {set res [TestCenter::StartStaEngine $portName] } err] == 1} {

				set msg "调用TestCenter::StartStaEngine发生异常，错误信息为: $err ."
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
			# 判断执行结果
			if {[lindex $res 0] != $TestCenter::ExpectSuccess} {

				set msg [lindex $res 1]
				LOG::DebugErr $func $::ATTTestCenter::__FILE__  $msg
				set nRet $::ATT_TESTCENTER_FAIL
				break
			}
		}

		# 如果开启统计引擎失败，退出循环，返回失败
		if {$nRet == $::ATT_TESTCENTER_FAIL} {
			break
		}
	}

	return [list $nRet $msg]
}


#*******************************************************************************
#Function:    ::ATTTestCenter::CheckServerIsStart {{useless ""}}
#Description:  该过程用来测试xmlrpc server是否成功开启，如果调用到该过程，说明服务器已经起来了
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      useless    没有用的参数，仅仅是为了xmlrpc调用格式的需要，必须传参
#Output:
#Return:
#    $ATT_TESTCENTER_SUC  $msg        表示成功
#    $ATT_TESTCENTER_FAIL $msg        表示调用函数失败
#    其他值                           表示失败
#
#Others:   无
#*******************************************************************************
proc ::ATTTestCenter::CheckServerIsStart {{useless ""}} {

	set nRet $::ATT_TESTCENTER_SUC
	set msg  "xmlrpc server is running..."

	return [list array [list [list int $nRet] [list string $msg]]]
}


if {[catch {

    # 由于该服务器运行在子进程中，不单独创建文件保存log
    #LOG::Start
    xmlrpc::serve 51800
    puts "start xmlrpc server successfully!"
    vwait forever
    } err] == 1} {

    set msg "启动xmlrpc server发生异常，错误信息为: $err ."
    puts $msg
    }
