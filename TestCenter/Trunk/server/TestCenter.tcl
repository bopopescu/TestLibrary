#***************************************************************************
#  Copyright (C), 2012-1, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  模块名称：TestCenter
#  模块功能：提供TestCenter的基本接口。完成连接TestCenter,配置相关属性，收发流，统计结果等操作
#  作者: ATT项目开发组
#  版本: V1.0
#  日期: 2013.02.27
#  修改记录：
#      lana   2013-02-27  created
#      lana   2013-09-27   添加STC命令的打印

#***************************************************************************

package require LOG
package provide TestCenter  1.0


namespace eval ::TestCenter {

    set currentFileName TestCenter.tcl

    # 用来保存测试过程中建立的对象
    set chassisObject ""
    array set object {}

    set ExpectSuccess 0            ;#表示成功
    set FunctionExecuteError -1    ;#表示调用函数失败

}


#*******************************************************************************
#Function:   ::TestCenter::ConnectChassis {chassisAddr}
#Description:  使用给定的chassisAddr连接TestCenter
#Calls:  无
#Data Accessed:   无
#Data Updated:
#     TestCenter::chassisObject
#Input:
#      chassisAddr     表示机框地址，用于连接TestCenter的IP地址
#
#Output:   无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                       表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::ConnectChassis {chassisAddr } {

	set log [LOG::init TestCenter_ConnectChassis]
	set errMsg ""

	foreach once {once} {

		# 检查参数chassisAddr是否为空，如果为空，则无法连接TestCenter，返回失败
		if {$chassisAddr == ""} {
			set errMsg "chassisAddr为空，无法连接TestCenter."
			break
		}

		# 检查chassis1对象是否已经存在了，如果存在，直接返回成功
		if {[string match $::TestCenter::chassisObject "chassis1"] == 1} {
			set errMsg "已经连接了$chassisAddr 上的TestCenter，不用再连接."
			return [list $TestCenter::ExpectSuccess $errMsg]
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: TestDevice chassis1 $chassisAddr"

		# 利用传入的机框地址，连接机框，并生成chassis1对象,如果发生异常，返回失败
		if {[catch {set ::TestCenter::chassisObject [TestDevice chassis1 $chassisAddr]} err] == 1} {
			set errMsg "连接TestCenter发生异常，错误信息为: $err ."
			break
		}
		# 判断生成机框对象的返回值是否正确，如果不正确，返回失败
		if {[string match $::TestCenter::chassisObject "chassis1"] != 1} {
			set errMsg "生成机框对象失败，返回值为:$::TestCenter::chassisObject ."
			break
		}

		set errMsg "连接$chassisAddr 上的TestCenter成功."
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:   ::TestCenter::ReservePort {portLocation portName {portType "Ethernet"}}
#Description:  预约端口，在预约端口时，需要指明端口的位置，端口的名字和端口的类型
#             （即该端口数据链路层要使用的协议类型），取值范围为：Ethernet,Wan,Atm,LowRate
#Calls:  无
#Data Accessed:   无
#Data Updated:
#     TestCenter::object
#Input:
#      portLocation     表示端口的位置，由板卡号与端口号组成，用'/'连接。例如预约1号板卡的1号端口，则传入 "1/1"
#      portName         指定预约端口的别名，用于后面对该端口的其他操作。
#      portType         指定预约的端口类型。默认为"Ethernet"
#
#Output:   无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                       表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::ReservePort {portLocation portName {portType "Ethernet"}} {

	set log [LOG::init TestCenter_ReservePort]
	set errMsg ""

	foreach once {once} {
		# 如果参数portLocation或portName为空，返回失败
		if {$portLocation == "" || $portName == ""} {
			set errMsg "端口位置和端口名不能为空."
			break
		}

		# 判断是否已经连接上了机框
		if {$::TestCenter::chassisObject == ""} {
			set errMsg "还未连接TestCenter机框，不能预约端口."
			break
		}

		# 检查端口对象名是否已被使用过
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo != ""} {
			set errMsg "$portName 已经被使用过，预约端口名不可重复!"
			break
		}

		# 组建命令，预约端口
		set cmd "$::TestCenter::chassisObject CreateTestPort -PortLocation $portLocation -PortName $portName -PortType $portType"
		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		if {[catch {set res [eval $cmd]} err] == 1} {
			set errMsg "预约$portLocation 端口发生异常，错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($portName) $portName
		} else {
			set errMsg "预约$portLocation 端口失败，返回值为:$res ."
			break
		}

		set errMsg "预约 $portLocation 端口成功."
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:   ::TestCenter::ConfigPort {portName args}
#Description:  配置Ethernet端口的属性
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      portName     表示要配置的端口的名字，这里的端口名是预约端口时指定的名字
#      args         表示要配置的端口的属性的列表，由{属性项，值，属性项，值...}组成{-options value}：
#        -mediaType   表示端口介质类型，取值范围为COPPER、FIBER。默认为COPPER
#        -linkSpeed   表示端口速率，取值范围为10M,100M,1G,10G,AUTO。默认为AUTO
#        -duplexMode  表示端口的双工模式，取值范围为FULL、HALF。默认为FULL
#        -autoNeg     表示端口的协商模式，取值范围为Enable、Disable。默认为Enable
#        -flowControl 表示是否开启端口的流控功能，取值范围为ON、OFF。默认为OFF
#        -mtuSize     表示端口的MTU。默认为1500
#        -autoNegotiationMasterSlave 表示自协商模式，取值范围为MASTER,SLAVE。默认为MASTER
#        -portMode    仅针对10G,取值范围为LAN、WAN。默认为LAN
#
#Output:   无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                       表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::ConfigPort {portName args} {

	set log [LOG::init TestCenter_ConfigPort]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法配置端口."
			break
		}

		# 配置端口的属性
		set tmpCmd "$portName ConfigPort"
		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}

			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "配置端口$portName 发生异常，错误信息为:$err ."
			break
		}

		if {$res != 0} {
			set errMsg "配置端口$portName 失败，返回值为:$res ."
			break
		}

		set errMsg "配置端口$portName 成功"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:   ::TestCenter::GetPortState {portName portStates}
#Description:  获取Ethernet端口的状态信息，包括端口的物理状态，链路状态，链路速率，链路双工状态
#Calls:  无
#Data Accessed:   无
#Data Updated:  无
#Input:
#      portName     表示要获取状态的端口的名字，这里的端口名是预约端口时指定的名字
#
#Output:
#      portStates    表示端口的状态列表，格式为{{-option value} {-option value} ...}
#Return:
#    list $TestCenter::ExpectSuccess  $msg              表示成功
#    list $TestCenter::FunctionExecuteError $msg        表示调用函数失败
#    其他值                                            表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::GetPortState {portName portStates} {

	set log [LOG::init TestCenter_GetPortState]
	upvar 1 $portStates tmpPortStates
	set tmpPortStates ""
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法获取端口信息."
			break
		}

		# 获取端口的属性
		set tmpCmd "$portName GetPortState"
		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "获取端口$portName 属性发生异常，错误信息为:$err ."
			break
		}

		for {set i 0} {$i < [llength $res]} {incr i} {
			lappend tmpPortStates [lindex $res $i]
		}

		set errMsg "获取端口$portName 属性成功"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupVlan {portName vlanName args}
#Description:   在指定端口创建vlan，并配置vlan的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建vlan子接口的端口名
#    vlanName   表示需要创建的vlan子接口的名字
#    args       表示需要创建的vlan子接口的属性列表。其格式为{-option value}.vlan的属性有：
#       -VlanType     指明Vlan类型，默认为：0x8100，表示以太网
#       -VlanId       指明 VlanId 值，默认为100
#       -VlanPriority 指明子接口的优先级取值，默认为0
#       -QinQList     指明 QinQ 模式下，各层 Vlan的 VlanId 以及 Priority 值，QinQList中的元素由一个｛tpid vlanid priority｝三元组组成。
#    注意，前三个属性与最后一个属性不能同时使用
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupVlan {portName vlanName args} {

	set log [LOG::init TestCenter_SetupVlan]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建Vlan子接口."
			break
		}

		# 检查参数vlanName是否为空
		if {$vlanName == ""} {
			set errMsg "vlanName为空，无法创建Vlan子接口."
			break
		}

		# 创建vlan子接口
		set tmpCmd "$portName CreateSubInt -SubIntName $vlanName"
		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "创建$vlanName 子接口发生异常, 错误信息为:$err ."
			break
		}
		# 如果创建成功，保存子接口句柄
		if {$res == 0} {
			set TestCenter::object($vlanName) $vlanName
		} else {
			set errMsg "创建$vlanName 子接口失败，返回值为:$res ."
			break
		}

		# 配置Vlan子接口的属性
		set tmpCmd "$vlanName ConfigPort"
		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "配置$vlanName 子接口属性发生异常, 错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "配置$vlanName 子接口属性失败，返回值为:$res ."
			break
		}

		set errMsg "在$portName 端口创建$vlanName 子接口并配置它的属性成功"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupHost {portName hostName args}
#Description:   在指定端口创建Host，并配置host的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建host的端口名或子接口名
#    hostName   表示需要创建的host的名字。该名字用于后面对该host的其他操作
#    args       表示需要创建的host的属性列表。其格式为{-option value}.host的属性有：
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
#       -Increase         指明IP地址增幅，默认为1, 取值范围为2的幂
#       -FlagPing         指明是否支持Ping功能，enable/disable，默认为enable
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupHost {portName hostName args} {

	set log [LOG::init TestCenter_SetupHost]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建Host对象."
			break
		}

		# 检查参数hostName是否为空
		if {$hostName == ""} {
			set errMsg "hostName为空，无法创建Host对象."
			break
		}

		# 创建Host对象，并配置它的属性
		set tmpCmd "$portName CreateHost -HostName $hostName"

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "创建$hostName 发生异常, 错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($hostName) $hostName
		} else {
			set errMsg "创建$hostName 失败，返回值为:$res ."
			break
		}

		set errMsg "在端口$portName 创建$hostName 成功"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupDHCPServer {routerName args}
#Description:   配置DHCP Server
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName     表示要配置的DHCP Server的主机名
#    args          表示DHCP Server的属性列表,格式为{-option value}.具体属性描述如下：
#    DHCPServer:
#       -PoolName     可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
#                     注意：PoolName和routerName不要相同，默认为空。
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
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupDHCPServer {routerName args} {

	set log [LOG::init TestCenter_SetupDHCPServer]
	set errMsg ""

	foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法配置DHCP Server."
			break
		}

		# 组建命令
		if {$args != ""} {
			set tmpCmd  "$routerName SetSession"
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "配置DHCP Server发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "配置DHCP Server失败，返回值为:$res ."
				break
			}
		} else {
			set errMsg "未传入DHCP Server的任何属性，无法配置DHCP Server"
			break
		}

		set errMsg "配置DHCP Server成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::EnableDHCPServer {routerName}
#Description:   开启DHCP Server，开始协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要开始协议仿真的DHCP Server名称
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::EnableDHCPServer {routerName } {

    set log [LOG::init EnableDHCPServer]
	set errMsg ""

    foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法开始协议仿真."
			break
		}

		# 组建命令
		set tmpCmd  "$routerName Enable"

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$routerName 开启DHCP Server协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$routerName 开启DHCP Server协议仿真发生异常，返回值为:$res ."
			break
		}

		set errMsg "开启DHCP Server协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
}


#*******************************************************************************
#Function:    ::TestCenter::DisableDHCPServer {routerName}
#Description:   关闭DHCP Server，停止协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要停止协议仿真的DHCP Server名称
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#******************************************************************************
proc ::TestCenter::DisableDHCPServer {routerName } {

    set log [LOG::init DisableDHCPServer]
	set errMsg ""

    foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法关闭协议仿真."
			break
		}

		# 组建命令
		set tmpCmd  "$routerName Disable"

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$routerName 关闭DHCP Server协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$routerName 关闭DHCP Server协议仿真发生异常，返回值为:$res ."
			break
		}

		set errMsg "关闭DHCP Server协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
}


#*******************************************************************************
#Function:    ::TestCenter::SetupDHCPClient {routerName args}
#Description:   配置DHCP Client
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName     表示要配置的DHCP Client的主机名
#    args           表示DHCP Client的属性列表,格式为{-option value}.具体属性描述如下：
#    DHCPClient:
#       -PoolName        可以用于创建流量的目的地址和源地址。仪表能完成其相应的地址变化，与其仿真功能对应的各层次的封装。
#                        注意：PoolName和routerName不要相同，默认为空。
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
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupDHCPClient {routerName args} {

    set log [LOG::init TestCenter_SetupDHCPClient]
	set errMsg ""

    foreach once {once} {
        # 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法开始协议仿真."
			break
		}

        # 组建命令
		if {$args != ""} {
			set tmpCmd  "$routerName SetSession"
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

            LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "配置DHCP Client发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "配置DHCP Client失败，返回值为:$res ."
				break
			}
		} else {
			set errMsg "未传入DHCP Client的任何属性，无法配置DHCP Client"
			break
		}

        set errMsg "配置DHCP Client成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
    }
    LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::EnableDHCPClient {routerName}
#Description:   使能DHCP Client
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要使能的DHCP Client名称
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::EnableDHCPClient {routerName } {

    set log [LOG::init EnableDHCPClient]
	set errMsg ""

    foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法开始协议仿真."
			break
		}

		# 组建命令
		set tmpCmd  "$routerName Enable"

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$routerName 开启DHCP Client协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$routerName 开启DHCP Client协议仿真发生异常，返回值为:$res ."
			break
		}

		set errMsg "开启DHCP Client协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
}


#*******************************************************************************
#Function:    ::TestCenter::DisableDHCPClient {routerName}
#Description:   停止DHCP Client
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName   表示要停止的DHCP Client名称
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#******************************************************************************
proc ::TestCenter::DisableDHCPClient {routerName } {

    set log [LOG::init DisableDHCPClient]
	set errMsg ""

    foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法关闭协议仿真."
			break
		}

		# 组建命令
		set tmpCmd  "$routerName Disable"

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$routerName 关闭DHCP Client协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$routerName 关闭DHCP Client协议仿真发生异常，返回值为:$res ."
			break
		}

		set errMsg "关闭DHCP Client协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
}


#*******************************************************************************
#Function:    ::TestCenter::MethodDHCPClient {routerName method}
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
proc ::TestCenter::MethodDHCPClient {routerName method} {

    set log [LOG::init MethodDHCPClient]
	set errMsg ""

    foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法进行协议仿真."
			break
		}
        # 检查参数method输入的对象是否正确，如果不正确，返回失败
        set method_list [list Bind Release Renew Abort Reboot]
        set index [lsearch -nocase $method_list $method]
        if {$index == -1} {
            set errMsg "$method 仿真操作输入错误."
            break
        }

		# 组建命令
		set tmpCmd  "$routerName $method"

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$routerName 进行DHCP Client协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$routerName 进行DHCP Client协议仿真发生异常，返回值为:$res ."
			break
		}

		set errMsg "DHCP Client $mehtod 协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
}



#*******************************************************************************
#Function:    ::TestCenter::SetupIGMPHost {hostName args}
#Description:   配置IGMP Host或者MLD Host
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要配置的IGMP主机名
#    args          表示IGMP/MLD host的属性列表,格式为{-option value}.具体属性描述如下：
#    IGMPHost:
#       -SrcMac             表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02
#       -SrcMacStep         表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1
#       -Ipv4Addr           表示Host起始IPv4地址，默认为192.85.1.3
#       -Ipv4AddrGateway    表示GateWay的IPv4地址，默认为192.85.1.1
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
#   MLDHost
#       -SrcMac             表示源MAC，创建多个host时，默认值依次增1，默认为00:10:94:00:00:02
#       -SrcMacStep         表示源MAC的变化步长，步长从MAC地址的最后一位依次增加，默认为1
#       -Ipv6Addr           表示Host起始IPv6地址，默认为2000::2
#       -Ipv6AddrGateway    表示GateWay的IPv6地址
#       -Ipv6AddrPrefixLen  表示Host IPv6地址Prefix长度，默认为64
#       -Count              表示Host IP、MAC地址个数，默认为1
#       -Increase           表示IP地址增幅，默认为1
#       -ProtocolType       表示Protocol的类型。合法值：MLDv1/MLDv2，默认为MLDv1
#       -SendGroupRate      指明MLD Host发送组播协议报文时，发送报文的速率，单位fps，默认为0
#       -Active             表示MLD Host会话是否激活,取值范围：TRUE/FALSE，默认为TRUE
#       -ForceLeave         指明当除最后一个之外的MLD Host从group中离开时，是否发送leave报文,取值范围：TRUE/FALSE。默认为FALSE
#       -ForceRobustJoin    指明当第一个MLD host加入group时，是否连续发送，取值范围：TRUE/FALSE，默认为FALSE
#       -UnsolicitedReportInterval  指明MLD host发送unsolicited report的时间间隔，默认为10
#       -InsertCheckSumErrors       指明是否在MLD Host发送的报文中插入Checksum error，取值范围：TRUE/FALSE。默认为FALSE
#       -InsertLengthErrors         指明是否在Mld Host发送的报文中插入Length error，取值范围：TRUE/FALSE。默认为FALSE
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupIGMPHost {hostName args} {

	set log [LOG::init TestCenter_SetupIGMPHost]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法配置IGMP/MLD host."
			break
		}

		# 组建命令
		if {$args != ""} {
			set tmpCmd  "$hostName SetSession"
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "配置IGMP/MLD host发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "配置IGMP/MLD host失败，返回值为:$res ."
				break
			}
		} else {
			set errMsg "未传入IGMP/MLD host的任何属性，无法配置IGMP host"
			break
		}

		set errMsg "配置IGMP/MLD host成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupIGMPGroupPool {hostName groupPoolName startIP args}
#Description:   创建或配置IGMP/MLD GroupPool
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要创建或配置IGMP/MLD GroupPool的主机名
#    groupPoolName 表示IGMP/MLD Group的名称标识，要求在当前 IGMP/MLD Host 唯一
#    startIP       表示Group 起始 IP 地址，取值约束：String，IPv4的地址值(IGMP),或IPV6的地址值（MLD）
#    args          表示IGMP Group pool的属性列表,格式为{-option value}.具体属性描述如下：
#      IGMP GroupPool:
#       -PrefixLen       表示IP 地址前缀长度，取值范围：5到32，默认为24
#       -GroupCnt        表示Group 个数，取值约束：32位正整数，默认为1
#       -GroupIncrement  表示Group IP 地址的增幅，取值范围：32为正整数，默认为1
#       -FilterMode       Specific Source Filter Mode(IGMPv3), 取值范围为Include Exclude，默认为Exclude
#       -SrcStartIP       表示起始主机 IP 地址（IGMPv3），取值约束：String，默认为192.168.1.2
#       -SrcCnt           表示主机地址个数（IGMPv3），取值范围：32位整数，默认为1
#       -SrcIncrement     表示主机 IP 地址增幅（IGMPv3），取值范围：32位整数，默认为1
#       -SrcPrefixLen     表示主机 IP 地址前缀长度（IGMPv3），取值范围：1到32，默认为24
#
#      MLD GroupPool
#       -PrefixLen       表示IP 地址前缀长度，取值范围：9到128，默认为64
#       -GroupCnt        表示Group 个数，取值约束：32位正整数，默认为1
#       -GroupIncrement  表示Group IP 地址的增幅，取值范围：32为正整数，默认为1
#       -FilterMode       Specific Source Filter Mode(IGMPv3), 取值范围为Include Exclude，默认为Exclude
#       -SrcStartIP       起始主机IP地址（MLDv2），取值范围：String ipv6格式地址值，默认为2000::3
#       -SrcCnt           表示主机地址个数（MLDv2），取值范围：32位整数，默认为1
#       -SrcIncrement     表示主机 IP 地址增幅（MLDv2），取值范围：32位整数，默认为1
#       -SrcPrefixLen     表示主机 IP 地址前缀长度（MLDv2），取值范围：1到128，默认为64
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupIGMPGroupPool {hostName groupPoolName startIP args} {

	set log [LOG::init TestCenter_SetupIGMPHost]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法配置IGMP/MLD host."
			break
		}

		# 组建命令
		# 检查groupPoolName是否已经存在，如果存在则对它进行配置，否则新建
		set tmpInfo [array get TestCenter::object $groupPoolName]
		if {$tmpInfo == ""} {
			set tmpCmd "$hostName CreateGroupPool -GroupPoolName $groupPoolName -StartIP $startIP"
		} else {
			set tmpCmd "$hostName SetGroupPool -GroupPoolName $groupPoolName -StartIP $startIP"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "创建或配置IGMP/MLD GroupPool发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "创建或配置IGMP/MLD GroupPool失败，返回值为:$res ."
				break
			}
		}

		set errMsg "创建或配置IGMP/MLD GroupPool成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SendIGMPLeave {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送IGMP/MLD leave（组播离开）报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示IGMP/MLD Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SendIGMPLeave {hostName {groupPoolList ""}} {

	set log [LOG::init TestCenter_SendIGMPLeave]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法发送IGMP/MLD leave报文."
			break
		}

		# 组建命令
		if {$groupPoolList == ""} {
			set tmpCmd "$hostName SendLeave"
		} else {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $groupPoolList] == 1} {
					set groupPoolList [lindex $groupPoolList 0]
				} else {
					break
				}
			}
			set tmpCmd "$hostName SendLeave -GroupPoolList $groupPoolList"
		}

		if {$groupPoolList == ""} {
			set groupPoolList "所有的组播组"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Leave报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Leave报文失败，返回值为:$res ."
			break
		}

		set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Leave报文成功。"

		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SendIGMPReport {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送IGMP/MLD Join(组播加入)报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示IGMP/MLD Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SendIGMPReport {hostName {groupPoolList ""}} {

	set log [LOG::init TestCenter_SendIGMPReport]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法发送IGMP/MLD Join报文."
			break
		}

		# 组建命令
		if {$groupPoolList == ""} {
			set tmpCmd "$hostName SendReport"
		} else {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $groupPoolList] == 1} {
					set groupPoolList [lindex $groupPoolList 0]
				} else {
					break
				}
			}
			set tmpCmd "$hostName SendReport -GroupPoolList $groupPoolList"
		}

		if {$groupPoolList == ""} {
			set groupPoolList "所有的组播组"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Join报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Join报文失败，返回值为:$res ."
			break
		}

		set errMsg "$hostName 向$groupPoolList 发送IGMP/MLD Join报文成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupMLDHost {hostName args}
#Description:   配置MLD Host
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要配置的MLD主机名
#    args          表示MLD host的属性列表,格式为{-option value}.具体属性描述如下：
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
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupMLDHost {hostName args} {

	set log [LOG::init TestCenter_SetupMLDHost]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法配置MLD host."
			break
		}

		# 组建命令
		if {$args != ""} {
			set tmpCmd  "$hostName SetSession"
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "配置MLD host发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "配置MLD host失败，返回值为:$res ."
				break
			}
		} else {
			set errMsg "未传入MLD host的任何属性，无法配置MLD host"
			break
		}

		set errMsg "配置MLD host成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupMLDGroupPool {hostName groupPoolName startIP args}
#Description:   创建或配置MLD GroupPool
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要创建或配置MLD GroupPool的主机名
#    groupPoolName 表示MLD Group的名称标识，要求在当前 MLD Host 唯一
#    startIP       表示Group 起始 IP 地址，取值约束：IPV6的地址值（MLD）
#    args          表示IGMP Group pool的属性列表,格式为{-option value}.具体属性描述如下：
#       -PrefixLen       表示IP 地址前缀长度，取值范围：9到128，默认为64
#       -GroupCnt        表示Group 个数，取值约束：32位正整数，默认为1
#       -GroupIncrement  表示Group IP 地址的增幅，取值范围：32为正整数，默认为1
#       -SrcStartIP       起始主机IP地址（MLDv2），取值范围：String ipv6格式地址值，默认为2000::3
#       -SrcCnt           表示主机地址个数（MLDv2），取值范围：32位整数，默认为1
#       -SrcIncrement     表示主机 IP 地址增幅（MLDv2），取值范围：32位整数，默认为1
#       -SrcPrefixLen     表示主机 IP 地址前缀长度（MLDv2），取值范围：1到128，默认为64
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupMLDGroupPool {hostName groupPoolName startIP args} {

	set log [LOG::init TestCenter_SetupMLDGroupPool]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法配置MLD host."
			break
		}

		# 组建命令
		# 检查groupPoolName是否已经存在，如果存在则对它进行配置，否则新建
		set tmpInfo [array get TestCenter::object $groupPoolName]
		if {$tmpInfo == ""} {
			set tmpCmd "$hostName CreateGroupPool -GroupPoolName $groupPoolName -StartIP $startIP"
		} else {
			set tmpCmd "$hostName SetGroupPool -GroupPoolName $groupPoolName -StartIP $startIP"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}

			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
			# 执行命令
			if {[catch {set res [eval $tmpCmd]} err] == 1} {
				set errMsg "创建或配置MLD GroupPool发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "创建或配置MLD GroupPool失败，返回值为:$res ."
				break
			}
		}

		set errMsg "创建或配置MLD GroupPool成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SendMLDLeave {hostName {groupPoolList ""}}
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
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SendMLDLeave {hostName {groupPoolList ""}} {

	set log [LOG::init TestCenter_SendMLDLeave]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法发送MLD leave报文."
			break
		}

		# 组建命令
		if {$groupPoolList == ""} {
			set tmpCmd "$hostName SendLeave"
		} else {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $groupPoolList] == 1} {
					set groupPoolList [lindex $groupPoolList 0]
				} else {
					break
				}
			}
			set tmpCmd "$hostName SendLeave -GroupPoolList $groupPoolList"
		}

		if {$groupPoolList == ""} {
			set groupPoolList "所有的组播组"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$hostName 向$groupPoolList 发送MLD Leave报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$hostName 向$groupPoolList 发送MLD Leave报文失败，返回值为:$res ."
			break
		}

		set errMsg "$hostName 向$groupPoolList 发送MLD Leave报文成功。"

		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SendMLDReport {hostName {groupPoolList ""}}
#Description:   向groupPoolList指定的组播组发送MLD Join(组播加入)报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    hostName      表示要发送报文的主机名
#    groupPoolList 表示MLD Group 的名称标识列表,不指定表示针对所有group
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SendMLDReport {hostName {groupPoolList ""}} {

	set log [LOG::init TestCenter_SendMLDReport]
	set errMsg ""

	foreach once {once} {
		# 检查参数hostName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $hostName]
		if {$tmpInfo == ""} {
			set errMsg "$hostName不存在，无法发送MLD Join报文."
			break
		}

		# 组建命令
		if {$groupPoolList == ""} {
			set tmpCmd "$hostName SendReport"
		} else {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $groupPoolList] == 1} {
					set groupPoolList [lindex $groupPoolList 0]
				} else {
					break
				}
			}
			set tmpCmd "$hostName SendReport -GroupPoolList $groupPoolList"
		}

		if {$groupPoolList == ""} {
			set groupPoolList "所有的组播组"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$hostName 向$groupPoolList 发送MLD Join报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$hostName 向$groupPoolList 发送MLD Join报文失败，返回值为:$res ."
			break
		}

		set errMsg "$hostName 向$groupPoolList 发送MLD Join报文成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupRouter {portName routerName routerType args}
#Description:   在指定端口创建router，并配置router的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建router的端口名
#    routerName 表示需要创建的ruoter的名字。该名字用于后面对该router的其他操作
#    routerType 指明Router类型,取值范围为：Ospfv2Router、 Ospfv3Router、
#                        IsisRouter、RipRouter、RIPngRouter、BgpV4Router、 BgpV6Router、
#                        LdpRouter、RsvpRouter、IgmpRouter、MldRouter、PimRouter,
#                        MldHost, IGMPHost, PPPoEClient, DHCPClient, DHCPServer,
#                        PPPoEServer, DHCPRelay, PPPoL2TPLAC, PPPoL2TPLNS, IGMPoDHCP,
#                        IGMPoPPPoE。
#    args       表示需要创建的router的属性列表。其格式为{-option value}.具体的属性有：
#       -RouterId        指明RouterId，默认为1.1.1.1
#       -RelateRouter    指明要叠加的路由器的名称；如果为空则不叠加。
#                        此参数只在不同协议叠加时，才有意义；
#                        目前支持叠加的协议有ospfv2/bgp/ldp
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupRouter {portName routerName routerType args} {

	set log [LOG::init TestCenter_SetupRouter]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建Router对象."
			break
		}

		# 检查参数routerName是否为空
		if {$routerName == ""} {
			set errMsg "routerName为空，无法创建Router对象."
			break
		}

		# 检查参数routerType是否为空
		if {$routerType == ""} {
			set errMsg "routerType为空，无法创建Router对象."
			break
		}

		# 创建Router对象，并配置它的属性
		set tmpCmd "$portName CreateRouter -RouterName $routerName -RouterType $routerType"

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "创建$routerName 发生异常, 错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($routerName) $routerName
		} else {
			set errMsg "创建$routerName 失败，返回值为:$res ."
			break
		}

		set errMsg "在端口$portName 创建$routerName 成功"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StartRouter {portName {routerList ""}}
#Description:   在指定端口上开启指定的Router，开始协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示要开始协议仿真的端口名
#    routerList 指明要开始协议仿真的Router对象的名称，如果为空，表示当前端口上所有的协议对象
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StartRouter {portName {routerList ""}} {

	set log [LOG::init TestCenter_StartRouter]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法开始协议仿真."
			break
		}

		# 组建命令
		if {$routerList == ""} {
			set tmpCmd "$portName StartRouter"
		} else {
			set tmpCmd "$portName StartRouter -RouterList $routerList"
		}

		if {$routerList == ""} {
			set routerList "所有的"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$portName 开启$routerList 协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$portName 开启$routerList 协议仿真失败，返回值为:$res ."
			break
		}

		set errMsg "$portName 开启$routerList 协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StopRouter {portName {routerList ""}}
#Description:   在指定端口上关闭指定的Router，停止协议仿真
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示要停止协议仿真的端口名
#    routerList 指明要停止协议仿真的Router对象的名称，如果为空，表示当前端口上所有的协议对象
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StopRouter {portName {routerList ""}} {

	set log [LOG::init TestCenter_StopRouter]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法停止协议仿真."
			break
		}

		# 组建命令
		if {$routerList == ""} {
			set tmpCmd "$portName StopRouter"
		} else {
			set tmpCmd "$portName StopRouter -RouterList $routerList"
		}

		if {$routerList == ""} {
			set routerList "所有的"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$portName 关闭$routerList 协议仿真发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$portName 关闭$routerList 协议仿真失败，返回值为:$res ."
			break
		}

		set errMsg "$portName 关闭$routerList 协议仿真成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupIGMPRouter {routerName routerIp args}
#Description:   配置IGMP/MLD router
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName      表示要配置的IGMP/MLD Router名
#    routerIp        表示 IGMP/MLD Router 的接口 IPv4/IPv6 地址
#    args            表示IGMP router的属性列表,格式为{-option value}.具体属性描述如下：
#     IGMP router:
#       -SrcMac             表示源Mac，创建多个Router时，默认值按照步长1递增
#       -ProtocolType       表示Protocol的类型。合法值：IGMPv1/IGMPv2/IGMPv3。默认为IGMPv2
#       -IgnoreV1Reports    指明是否忽略接收到的 IGMPv1 Host的报文，默认为False
#       -Ipv4DontFragment   指明当报文长度大于 MTU 时，是否进行分片，默认为False
#       -LastMemberQueryCount  表示在认定组中没有成员之前发送的特定组查询的次数，默认为2
#       -LastMemberQueryInterval  表示在认定组中没有成员之前发送指定组查询报文的 时间间隔（单位 ms），默认为1000
#       -QueryInterval            表示发送查询报文的时间间隔（单位 s），，默认为32
#       -QueryResponseUperBound   表示Igmp Host对于查询报文的响应的时间间隔的上限值（单位 ms），默认为10000
#       -StartupQueryCount      指明Igmp Router启动之初发送的Query报文的个数，取值范围：1-255,默认为2
#       -Active                表示IGMP Router会话是否激活，默认为TRUE
#     MLD router:
#       -SrcMac             表示源Mac，创建多个Router时，默认值按照步长1递增
#       -ProtocolType       表示Protocol的类型。合法值：MLDv1/MLDv2。默认为 MLDv1
#       -LastMemberQueryCount  表示在认定组中没有成员之前发送的特定组查询的次数
#       -LastMemberQueryInterval  表示在认定组中没有成员之前发送指定组查询报文的 时间间隔（单位 ms），默认为1000
#       -QueryInterval            表示发送查询报文的时间间隔（单位 s），，默认为125
#       -QueryResponseUperBound   表示MLD Host对于查询报文的响应的时间间隔的上限值（单位 ms），默认为10000
#       -StartupQueryCount      指明MLD Router启动之初发送的Query报文的个数，取值范围为正整数,默认为2
#       -Active                表示MLD Router是否激活，取值范围：TRUE/FALSE,默认为TRUE
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupIGMPRouter {routerName routerIp args} {

	set log [LOG::init TestCenter_SetupIGMPRouter]
	set errMsg ""

	foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法配置IGMP/MLD Router."
			break
		}

		if {$routerIp == ""} {
			set errMsg "$routerIp为空，无法配置IGMP/MLD Router."
			break
		}

		# 组建命令
		set tmpCmd  "$routerName SetSession -TesterIp $routerIp"

		# 追加属性
		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "配置IGMP/MLD Router发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "配置IGMP/MLD Router失败，返回值为:$res ."
			break
		}

		set errMsg "配置IGMP/MLD Router成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StartIGMPRouterQuery {routerName}
#Description:   开始通用、特定IGMP/MLD查询
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName      表示要开始通用、特定IGMP/MLD查询的IGMP/MLD Router名
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StartIGMPRouterQuery {routerName} {

	set log [LOG::init TestCenter_StartIGMPRouterQuery]
	set errMsg ""

	foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法开始通用、特定IGMP/MLD查询."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $routerName StartAllQuery"
		# 执行命令
		if {[catch {set res [$routerName StartAllQuery]} err] == 1} {
			set errMsg "开始通用IGMP/MLD查询发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "开始通用IGMP/MLD查询失败，返回值为:$res ."
			break
		}

		set errMsg "开始通用IGMP/MLD查询成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StopIGMPRouterQuery {routerName}
#Description:   停止通用、特定IGMP/MLD查询
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    routerName      表示要开始通用、特定IGMP/MLD查询的IGMP/MLD Router名
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StopIGMPRouterQuery {routerName} {

	set log [LOG::init TestCenter_StopIGMPRouterQuery]
	set errMsg ""

	foreach once {once} {
		# 检查参数routerName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $routerName]
		if {$tmpInfo == ""} {
			set errMsg "$routerName不存在，无法停止通用IGMP/MLD查询."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $routerName StopAllQuery"
		# 执行命令
		if {[catch {set res [$routerName StopAllQuery]} err] == 1} {
			set errMsg "停止通用IGMP/MLD查询发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "停止通用IGMP/MLD查询失败，返回值为:$res ."
			break
		}

		set errMsg "停止通用IGMP/MLD查询成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StartARPStudy {srcHost dstHost retries interval}
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
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StartARPStudy {srcHost {dstHost ""} {retries "3"} {interval "1"}} {

	set log [LOG::init TestCenter_StartARPStudy]
	set errMsg ""

	foreach once {once} {
		# 检查参数srcHost指定的host对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $srcHost]
		if {$tmpInfo == ""} {
			set errMsg "$srcHost不存在，无法进行ARP学习."
			break
		}

		# 发送ARP学习请求
		if {$dstHost == ""} {
			set tmpCmd "$srcHost SendArpRequest -retries $retries -timer $interval"
		} else {
			set tmpCmd "$srcHost SendArpRequest -host $dstHost -retries $retries -timer $interval"
		}

		if {$dstHost == ""} {
			set dstHost "网关地址"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$srcHost 向$dstHost 发送ARP请求发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$srcHost 向$dstHost 发送ARP请求失败，返回值为:$res ."
			break
		}

		set errMsg "$srcHost 向$dstHost 发送ARP请求成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:   ::TestCenter::CreateTraffic {portName trafficName}
#Description:    创建流量引擎对象
#Calls:   无
#Data Accessed:    无
#Data Updated:   无
#Input:
#     portName      表示需要创建traffic流量引擎对象的端口的端口名。
#     trafficName   表示要创建的引擎对象名。
#Output:    无
# Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数出错
#   其他值                                表示失败
#Others:         无
#*******************************************************************************
proc ::TestCenter::CreateTraffic {portName trafficName} {

	set log [LOG::init TestCenter_CreateTraffic]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建流量引擎对象."
			break
		}
		# 检查参数trafficName是否为空
		if {$trafficName == ""} {
			set errMsg "$trafficName为空，无法创建流量引擎对象"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $portName CreateTraffic -TrafficName $trafficName"
		# 创建引擎对象
		if {[catch {set res [$portName CreateTraffic -TrafficName $trafficName]} err] == 1} {
			set errMsg "创建引擎对象$trafficName 发生异常，错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($trafficName) $trafficName
		} else {
			set errMsg "创建引擎对象$trafficName 失败，返回值为:$res ."
			break
		}

		set errMsg "$portName 创建引擎对象$trafficName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:   ::TestCenter::SetupTrafficProfile {trafficName profileName args}
#Description:    创建或配置流量发送引擎的特性参数,如果profileName已存在，则进行配置，
#                如果不存在，则创建一个新的profile
#Calls:   无
#Data Accessed:    无
#Data Updated:   无
#Input:
#     trafficName   表示需要创建或配置profile的流量发送引擎对象
#     profileName   表示需要创建或配置的profile名字
#     args          表示流量发送引擎的特性参数,格式为{-option value ...}.具体特性参数如下：
#        -Type      表示是持续还是Burst，取值范围Constant/Burst，默认为Constant
#        -TrafficLoad      表示流量的负荷（结合流量的单位设置该值），默认为10
#        -TrafficLoadUnit  表示流量单位，取值范围fps/kbps/mbps/percent，默认为Percent
#        -BurstSize        表示Burst 中连续发送的报文数量，默认为1
#        -FrameNum         表示一次发送报文的数量（为 BurstSize 的整数倍），默认为100
#        -Blocking         表示是否开启堵塞模式（Enable/Disable），默认为Disable
#Output:    无
# Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数出错
#   其他值                                         表示失败
#Others:         无
#*******************************************************************************
proc ::TestCenter::SetupTrafficProfile {trafficName profileName args} {

	set log [LOG::init TestCenter_SetupTrafficProfile]
	set errMsg ""

	foreach once {once} {
		# 检查参数trafficName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $trafficName]
		if {$tmpInfo == ""} {
			set errMsg "$trafficName不存在，无法创建流量引擎的profile."
			break
		}

		# 检查参数profileName是否为空
		if {$profileName == ""} {
			set errMsg "profileName为空，无法创建流量引擎的profile."
			break
		}

		# 判断profileName是否已存在，如果存在，修改它的属性，否则，新建profile，并设置它的属性
		set tmpInfo [array get TestCenter::object $profileName]
		if {$tmpInfo != ""} {
			# 配置profile
			set tmpCmd "$trafficName ConfigProfile -Name $profileName"
		} else {
			# 创建profile
			set tmpCmd "$trafficName CreateProfile -Name $profileName"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$trafficName 创建$profileName 发生异常,错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($profileName) $profileName
		} else {
			set errMsg "$trafficName 创建$profileName 失败，返回值为:$res ."
			break
		}

		set errMsg "$trafficName 创建$profileName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupStream {trafficName streamName args}
#Description:  创建或配置流对象，如果流对象已存在，则修改它的属性，如果不存在，则
#              创建新的流对象，并配置它的属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    trafficName  表示需要创建stream对象的traffic对象的对象名。
#    streamName   表示需要创建的stream对象的名字
#    args         表示流对象的属性列表，格式为{-option value ...}。具体的流对象属性如下：
#       -FrameLen 指明数据帧长度 单位为byte，默认为128
#       -StreamType 指明流量模板类型; 取值范围为:Normal,VPN,PPPoX DHCP…默认为Normal
#       -FrameLenMode 指明数据帧长度的变化方式，fixed | increment | decrement | random
#                     参数设置为random时，随机变化范围为:( FrameLen至FrameLen+ FrameLenCount-1)
#                     默认为fixed
#       -FrameLenStep 表示数据帧长度的变化步长，默认为1
#       -FrameLenCount 表示数量，默认为1
#       -insertsignature 指明是否在数据流中插入signature field，取值：true | false  默认为true，插入signature field
#       -ProfileName  指明Profile 的名字
#       -FillType   指明Payload的填充方式，取值范围为CONSTANT | INCR |DECR | PRBS，默认为CONSTANT
#       -ConstantFillPattern  当FillType为Constant的时候，相应的填充值。默认为0
#       -EnableFcsErrorInsertion  指明是否插入CRC错误帧，取值范围为TRUE | FALSE，默认为FALSE
#       -EnableStream  指定modifier使用stream/flow功能, 当使用stream模式时，单端口stream数不能超过32k。
#                      取值范围TRUE | FALSE，默认为FALSE
#       -TrafficPattern 主要用于流绑定的情形（使用SrcPoolName以及DstPoolName时），
#                        取值范围为PAIR | BACKBONE | MESH，默认为PAIR
#
#Output:    无
# Return:
#    list $CPEConfig::ExpectSuccess  $msg         表示成功
#    list $CPEConfig::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                       表示失败
#
#Others:    无
#*******************************************************************************
proc ::TestCenter::SetupStream {trafficName streamName args} {

	set log [LOG::init TestCenter_SetupStream]
	set errMsg ""

	foreach once {once} {
		# 检查参数trafficName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $trafficName]
		if {$tmpInfo == ""} {
			set errMsg "$trafficName不存在，无法创建流量引擎的流对象."
			break
		}

		# 检查参数streamName是否为空
		if {$streamName == ""} {
			set errMsg "streamName为空，无法创建流量引擎的流对象."
			break
		}

		# 判断streamName是否已存在，如果存在，修改它的属性，否则，新建stream，并设置它的属性
		set tmpInfo [array get TestCenter::object $streamName]
		if {$tmpInfo != ""} {
			# 配置profile
			set tmpCmd "$trafficName ConfigStream -StreamName $streamName"
		} else {
			# 创建profile
			set tmpCmd "$trafficName CreateStream -StreamName $streamName"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$trafficName 创建$streamName 发生异常,错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($streamName) $streamName
		} else {
			set errMsg "$trafficName 创建$streamName 失败，返回值为:$res ."
			break
		}

		set errMsg "$trafficName 创建$streamName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupHeader {headerName headerType args}
#Description:   创建或配置数据报的报头信息，如果headerName已存在，则配置，如果不存在，则创建并配置
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      headerName     表示需要创建或配置的数据报的报头名字。
#      headerType     表示需要创建或配置的数据报的报头类型，取值范围为：
#                     Eth | Vlan | IPV4 | TCP | UDP | MPLS | IPV6 | POS | HDLC
#      args           表示配置属性的参数列表，格式为{-option value ...},具体参数根据报文类型有所不同。
#        ETH
#          -DA                表示目的MAC,必须指定
#          -SA                表示源MAC，必须指定
#           -saRepeatCounter  表示源MAC的变化方式，fixed | increment | decrement，默认为Fixed
#           -saStep           表示源MAC的变化步长，默认为1
#           -SrcOffset        表示源MAC的变化步长的开始位置，默认为0
#           -daRepeatCounter  表示目的MAC的变化方式，fixed | increment | decrement，默认为Fixed
#           -daStep           表示目的MAC的变化步长，默认为1
#           -DstOffset        表示目的MAC的变化步长的开始位置，默认为0
#           -numDA            表示变化的目的MAC数量，默认为1
#           -numSA            表示变化的源MAC数量，默认为1
#           -EthType          表示以太网类型，16进制，默认值为auto，即如果以太网头上不添加其他协议头时，
#                             此默认值为88B5，如果添加其他协议头，则此字段自动与添加的协议头相匹配。
#           -EthTypeMode      表示EthType的变化方式，fixed |increment | decrement，默认为fixed
#           -EthTypeStep      表示EthType的变化步长，10进制，默认为1
#           -EthTypeCount     表示EthType数量，10进制，默认为1
#        Vlan
#          -vlanId             表示Vlan值，必须指定
#           -userPriority      表示用户优先级，默认为0
#           -cfi               表示Cfi值，默认为0
#           -mode              表示Vlan值的变化方式 fixed | increment | decrement，默认为Fixed
#           -repeat            表示Vlan变化数量，默认为10
#           -step              表示Vlan变化步长，默认为1
#           -maskval           表示vlan的掩码，默认为"0000XXXXXXXXXXXX"
#           -protocolTagId     表示TPID,取值8100、9100等16进制数值，默认为8100
#           -Vlanstack         表示Vlan的多层标签，Single/Multiple 如 -Vlanstack Single，默认为Single
#           -Stack             表示属于多层标签的哪一层，默认为1
#        IPV4
#           -precedence        表示Tos中的优先转发，取值参见特殊需求，默认为routine
#           -delay             表示Tos的最小延时，取值normal、low，默认为normal
#           -throughput        表示Tos的最大吞吐量，取值normal，High，默认为normal
#           -reliability       表示Tos的最佳可靠性，取值normalReliability，HighReliability，默认为normalReliability
#           -cost              表示Tos的开销，取值normalCost，LowCost，默认为normalCost
#           -identifier        表示包的标记，默认为0
#           -reserved          表示保留位，默认为0（注意，该属性的代码已被屏蔽）
#           -totalLength       表示总长度，默认为46
#           -lengthOverride    表示长度是否自定义，取值bool值，默认为False或者0
#           -fragment          表示能否分片，取值bool值，默认为May或者1
#           -lastFragment      表示是否最后一片，取值bool值，默认为Last或者1
#           -fragmentOffset    表示帧的偏移量，默认为0
#           -ttl               表示TTL，默认为64
#           -ipProtocol        表示协议类型，10进制取值或者枚举，默认为6（TCP）
#           -ipProtocolMode    表示ipProtocol的变化方式，fixed |increment | decrement，默认为fixed
#           -ipProtocolStep    表示ipProtocol的变化步长，10进制，默认为1
#           -ipProtocolCount   表示ipProtocol数量，10进制，默认为1
#           -useValidChecksum  表示CRC是否自动计算，默认为true
#          -sourceIpAddr       表示源IP，必须指定
#           -sourceIpMask      表示源IP的掩码，默认为"255.0.0.0"
#           -sourceIpAddrMode  表示源IP的变化类型Fixed Random Increment Decrement，默认为Fixed
#           -sourceIpAddrOffset 指定开始变化的位置，默认为0
#           -sourceIpAddrRepeatCount  表示源IP的变化数量，默认为10
#          -destIpAddr                表示目的IP，必须指定
#           -destIpMask               表示目的IP的掩码，默认为"255.0.0.0"
#           -destIpAddrMode    表示目的IP的变化类型其枚举值如下：Fixed Random Increment Decrement，默认为Fixed
#           -destIpAddrOffset  指定开始变化的位置，默认为0
#           -destIpAddrRepeatCount 表示目的IP的变化数量，默认为10
#           -destDutIpAddr         指定对应DUT的ip地址，即网关，默认为192.85.1.1
#           -options               表示可选项，4字节整数倍16进制数值
#           -qosMode            表示Qos的类型，tos/dscp 如 -qosMode tos，默认为dscp
#           -qosvalue           表示Qos取值，Dscp取值0~63，tos取值0~255，十进制取值，默认为 0
#        TCP
#           -offset        表示偏移量，默认为5
#          -sourcePort     表示源端口，必须指定
#           -srcPortMode   表示端口改变模式fixed | increment | decrement，默认为fixed
#           -srcPortCount  表示数量，默认为1
#           -srcPortStep   表示步长，默认为1
#          -destPort       表示目的端口，必须指定
#           -dstPortMode   表示端口改变模式fixed | increment | decrement，默认为fixed
#           -dstPortCount  表示数量，默认为1
#           -dstPortStep   表示步长，默认为1
#           -sequenceNumber 表示次序号，默认为0
#           -acknowledgementNumber   表示回应号，默认为0
#           -window                  表示窗口，默认为0
#           -urgentPointer           表示urgentPointer ，默认为0
#           -options                 表示可选项
#           -urgentPointerValid      表示是否置位uP，默认为False
#           -acknowledgeValid        表示是否置位回应。默认为False
#           -pushFunctionValid       表示是否置位pF，默认为False
#           -resetConnection         表示是否重置tcp连接，默认为False
#           -synchronize             表示是否同步，默认为False
#           -finished                表示是否结束，默认为False
#           -useValidChecksum        表示Tcp的校验和是否自动计算，默认为Enable
#        UDP
#           -sourcePort       表示源端口，必须指定
#            -srcPortMode     表示端口改变模式 fixed | increment | decrement，默认为fixed
#            -srcPortCount    表示数量，默认为1
#            -srcPortStep     表示步长，默认为1
#           -destPort         表示目的端口，必须指定
#            -dstPortMode     表示端口改变模式fixed | increment | decrement，默认为fixed
#            -dstPortCount    表示数量，默认为1
#            -dstPortStep     表示步长，默认1
#            -checksum        表示校验和， 默认为0
#            -enableChecksum  表示是否使能校验和，默认为Enable
#            -length           表示长度,默认为10
#            -lengthOverride   表示长度是否可重写，默认为Disable
#            -enableChecksumOverride   表示是否使能校验和重写，默认为Disable
#            -checksumMode      表示校验和类型，默认为auto
#        MPLS
#            代码中的参数
#            -type type optional,MPLS type, mplsUnicast or mplsMulticast, i.e -type mplsUnicast
#            -label label optional, MPLS label，i.e -label 0
#            -LabelCount LabelCount optional, MPLS label count，i.e -LabelCount 1
#            -LabelMode LabelMode optional, MPLS label change mode, fixed |increment | decrement，i.e -LabelMode fixed
#            -LabelStep LabelStep optional, MPLS label step，i.e -LabelStep 1
#            -Exp Exp optional，experience value，i.e  -Exp 0
#            -TTL TTL optional，TTL value，i.e -TTL 0
#            -bottomOfStack bottomOfStack optional，MPLS label stack，i.e -bottomOfStack 0
#            用户手册中的参数
#            -type                 表示MPLS标记类型，mplsUnicast | mplsMulticast，默认为mplsUnicast
#            -label                表示MPLS标记值，默认为0
#            -experimentalUse      表示经验值，默认为2
#            -timeToLive           表示TTL，默认为64
#            -bottomOfStack        表示MPLS标记栈位置，默认为0
#        IPV6
#            -TrafficClass    表示流分类等级，默认为0
#           -FlowLabel        表示Flow 标记值，必须指定
#            -PayLoadLen      表示负荷长度，没有设置则自动计算 ，默认为20
#            -NextHeader      表示下一个头类型，默认为6
#            -HopLimit        表示Hop限制，默认为255
#            -SourceAddress   表示源ipv6Address，默认为2000::2
#            -DestinationAddress  表示目的ipv6Address，默认为2000::1
#            -SourceAddressMode   表示原地址改变模式 fixed | increment | decrement，默认为fixed
#            -SourceAddressCount  表示数量，默认为1
#            -SourceAddressStep   表示变化步长，默认为0000:0000:0000:0000:0000:0000:0000:0001
#            -SourceAddressOffset  示原地址变化偏移量，默认为0
#            -DestAddressMode      表示目的地址改变模式，fixed | increment | decrement，默认为fixed
#            -DestAddressCount     表示数量，默认为1
#            -DestAddressStep      表示变化步长 ，默认为0000:0000:0000:0000:0000:0000:0000:0001
#            -DestAddressOffSet     表示偏移量，默认为0
#        POS
#            -HdlcAddress      表示接口地址，默认为FF
#            -HdlcControl      表示接口控制类型，默认为03
#            -HdlcProtocol     表示接口链路层协议，默认为0021
#        HDLC
#            -HdlcAddress       表示接口地址，默认为0F
#            -HdlcControl       表示接口控制类型，默认为00
#            -HdlcProtocol      表示接口链路层协议，默认为0800
#
# 注意：POS 和 HDLC只提供创建新的报文头，不支持配置已有报文头
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError   $msg 表示调用函数失败
#    其他值                               表示失败
#
#Others:    无
#*******************************************************************************
proc ::TestCenter::SetupHeader {headerName headerType args} {

	set log [LOG::init TestCenter_SetupHeader]
	set errMsg ""

	foreach once {once} {
		# 检查参数headerName是否为空
		if {$headerName == ""} {
			set errMsg "headerName为空，无法创建或配置数据报的报头."
			break
		}

		# 检查参数headerType是否为空
		if {$headerType == ""} {
			set errMsg "headerType为空，无法创建或配置数据报的报头."
			break
		}

		# 判断HeaderCreator对象是否存在，如果不存在，则新建一个名为header1的对象
		set tmpInfo [array get TestCenter::object "header1"]
		if {$tmpInfo == ""} {
			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: HeaderCreator header1"
			# 创建HeaderCreator对象
			if {[catch {set headerObject [HeaderCreator header1]} err ] == 1} {
				set errMsg "创建header对象发生异常，错误信息为: $err ."
				break
			}
			if {[string match $headerObject "header1"] != 1} {
				set errMsg "创建header对象失败，返回值为:$headerObject ."
				break
			}
			set TestCenter::object($headerObject) $headerObject
		}

		# 判断headerName是否已存在，如果存在，修改它的属性，否则，新建header，并设置它的属性
		set tmpInfo [array get TestCenter::object $headerName]
		if {$tmpInfo != ""} {
			# 组建配置header的命令
			if {$headerType == "POS" || $headerType == "HDLC"} {
				set errMsg "不支持配置POS或者HDLC类型的报文头。"
				break
			}
			set tmpSubCmd ""
			append tmpSubCmd Config $headerType Header
			set tmpCmd "header1 $tmpSubCmd -PduName $headerName"
		} else {
			# 组建创建header的命令
			set tmpSubCmd ""
			append tmpSubCmd Create $headerType Header
			set tmpCmd "header1 $tmpSubCmd -PduName $headerName"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "创建或配置$headerName 发生异常,错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "创建或配置$headerName 失败，返回值为:$res ."
			break
		}

		set errMsg "创建或配置$headerName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetupPacket {packetName packetType args}
#Description:   创建数据报的报文信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    packetName     指明需要创建的数据报的报文对象名
#    packetType     表示需要创建的数据报的报文类型，取值范围为：
#                    DHCP | PIM | IGMP | PPPoE | ICMP | ARP | Custom
#    args           表示配置属性的参数列表，格式为{-option value ...},具体参数根据报文类型有所不同。
#        DHCP
#          -op     表示发送报文的类型，可设置 1 或者 2，1:client,2:server，必须指定
#          -htype  表示硬件地址类型，非负整数值，必须指定
#          -hlen   表示硬件地址长度，非负整数值，必须指定
#          -hops   表示跳数，非负整数值，必须指定
#          -xid    表示事务编号，非负整数值，必须指定
#          -secs   表示秒数，非负整数值，必须指定
#          -bflag  表示广播标志位, 可设置 0/1，必须指定
#          -mbz15  表示广播标志位后的 15 位 bit 位，必须指定
#          -ciaddr 表示客户端 IP 地址，格式为0.0.0.0，必须指定
#          -yiaddr 表示测试机 IP 地址，格式为0.0.0.0，必须指定
#          -siaddr 表示服务器 IP 地址，格式为0.0.0.0，必须指定
#          -giaddr 表示中继代理 IP 地址，格式为 0.0.0.0，必须指定
#          -chaddr 表示客户机硬件地址，格式为 00：00：00：00：00：00，必须指定
#           -sname  表示服务器名称，64 Bytes 的 16 进制值
#           -file   表示DHCP 可选参数/启动文件名, 128 Bytes 的 16 进制值
#        PIM
#          -Type    表示消息类型，可选值为 Hello, Join_Prune, Register, Register_Stop, Assert，必须指定
#           -Version          表示协议版本
#           -Reserved         表示占用标志位
#           -OptionType       表示协议 option 字段类型
#           -OptionLength     表示协议 option 字段长度
#           -OptionValue      表示协议 option 字段内容
#           -UnicastAddrFamily
#           -GroupNum
#           -HoldTime
#           -GroupIpAddr
#           -GroupIpBBit
#           -GroupIpZBit
#           -SourceIpAddr
#           -PrunedSourceIpAddr
#           -RegBorderBit
#           -RegNullRegBit
#           -RegReservedField
#           -RegEncapMultiPkt
#           -RegGroupIpAddr
#           -RegSourceIpAddr
#           -AssertRptBit
#　　　　　 -AssertMetricPerf
#           -AssertMetric
#        IGMP(参数与代码中不一致，待确认)
#          -Type          表示IGMP 消息类型，必须指定
#           -GroupAddr    表示组播组地址
#           -MaxReponseTime 表示IGMPv2 最大响应时间
#           -SuppressFlag   表示IGMPv3Query 处理抑制位
#           -SourceNum      表示IGMPv3源地址个数(包括 Query 和 Report)
#           -SourceAddr     表示IGMPv3 源地址(包括 Query 和 Report)
#           -SourceAddrCnt  表示IGMPv3 源地址个数(包括 Query 和 Report)
#           -SourceAddrStep 表示IGMPv3 源地址掩码(包括 Query 和 Report)
#           -Reserved       表示IGMPv3Report 占用位
#           -GroupRecords   表示IGMPv3Report 组播组信息
#           -RecordType     表示IGMPv3Report 组播组信息类型
#           -AuxiliaryDataLen  表示IGMPv3Report 补充信息长度
#           -MulticastAddr   表示IGMPv3Report 组播地址
#        PPPoE
#          -PPPoEType  表示PPPoE 报文类型，必须指定
#           -Version   表示报文协议版本号
#           -Type      表示报文协议类型
#           -Code      表示报文代码(当对应 PPPoE_Session 时，code 为整数)
#           -SessionId 表示会话 ID
#           -Length    表示报文长度
#           -Tag       表示报文标签类型
#           -TagLength 表示报文标签长度(16 进制)
#           -TagValue  表示报文标签值(16 进制)
#        ICMP
#           -IcmpType  表示ICMP包类型，echo_request，echo_reply，destination_unreachable，
#                      source_quench，redirect，time_exceeded，parameter_problem，
#                      timestamp_request，timestamp_reply，information_request，information_reply
#                      支持直接填写上述关键字段，同时也支持0-255 十进制数字书写
#           -Code      表示Icmp包代码，支持0-255 十进制数字书写
#           -Checksum  表示校验码,默认自动计算
#           -SequNum   表示Icmp包序列号
#           -Data      表示ICMP包数据，默认为0000
#           -InternetHeader  表示IP首部，当IcmpType设为destination_unreachable、parameter_problem、redirect、
#                            source_quench、time_exceeded时有效
#           -OriginalDateFragment   表示初始数据片段，当IcmpType设为destination_unreachable、
#                                   parameter_problem、redirect、source_quench、time_exceeded时有效
#                                   默认为0000000000000000
#           -GatewayInternetAdd    表示网关IP地址，当IcmpType设为redirect时有效，默认为192.0.0.1
#           -Pointer               表示指针，当IcmpType设为parameter_problem时有效，默认为0
#           -Identifier            表示标识符，默认为 0
#           -OriginateTimeStamp    表示初始时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0
#           -ReceiveTimeStamp      表示接收时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0
#           -TransmitTimeStamp     表示传送时间戳，当IcmpType设为timestamp_request，timestamp_reply时有效，默认为0
#        ARP
#           -operation    指明 arp 报文类型，可选值为 request,reply，默认为request
#           -sourceHardwareAddr   指明 arp 报文中的 sender hardware address，默认为00:00:01:00:00:02
#           -sourceHardwareAddrMode  指明 sourceHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed
#           -sourceHardwareAddrRepeatCount  指明 sourceHardwareAddr 的变化次数，默认为1
#           -sourceHardwareAddrRepeatStep   指明 sourceHardwareAddr 的变化步长，默认为00-00-00-00-00-01
#           -destHardwareAddr    指明 arp 报文中的 target hardware address，默认为00:00:01:00:00:02
#           -destHardwareAddrMode 指明 destHardwareAddr 的变化方式，可选值为：fixed、incr、decr。默认为fixed
#           -destHardwareAddrRepeatCount  指明 destHardwareAddr 的变化次数， 默认为1
#           -destHardwareAddrRepeatStep   指明 destHardwareAddr 的变化步长，默认为00-00-00-00-00-01
#           -sourceProtocolAddr   指明 arp 报文中的 sender ip address，默认为192.85.1.2
#           -sourceProtocolAddrMode  指明 sourceProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed
#           -sourceProtocolAddrRepeatCount  指明 sourceProtocolAddr 变化次数，默认为1
#           -sourceProtocolAddrRepeatStep    指明 sourceProtocolAddr 变化步长，默认为0.0.0.1
#           -destProtocolAddr   指明 arp 报文中的 tartget ip address，默认为192.85.1.2
#           -destProtocolAddrMode 指明 destProtocolAddr 变化方式，可选值为 fixed、incr、decr。默认为fixed
#           -destProtocolAddrRepeatCount  指明 destProtocolAddr 变化次数，默认为1
#           -destProtocolAddrRepeatStep  指明 destProtocolAddr 变化步长，默认为0.0.0.1
#        Custom
#            -HexString  指明数据包内容,默认为"aaaa"
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess   $msg        表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                               表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupPacket {packetName packetType args} {

	set log [LOG::init TestCenter_SetupPacket]
	set errMsg ""

	foreach once {once} {
		# 检查参数packetName是否为空
		if {$packetName == ""} {
			set errMsg "packetName为空，无法创建或配置数据报的报文对象."
			break
		}

		# 检查参数packetType是否为空
		if {$packetType == ""} {
			set errMsg "packetType为空，无法创建或配置数据报的报文对象."
			break
		}

		# 判断PacketBuilder对象是否存在，如果不存在，则新建一个名为packet1的对象
		set tmpInfo [array get TestCenter::object "packet1"]
		if {$tmpInfo == ""} {
			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: PacketBuilder packet1"
			# 创建PacketBuilder对象
			if {[catch {set packetObject [PacketBuilder packet1]} err ] == 1} {
				set errMsg "创建packet对象发生异常，错误信息为: $err ."
				break
			}
			if {[string match $packetObject "packet1"] != 1} {
				set errMsg "创建packet对象失败，返回值为:$packetObject ."
				break
			}
			set TestCenter::object($packetObject) $packetObject
		}

		# 判断packetName是否已存在，如果存在，不可以创建同名的对象
		set tmpInfo [array get TestCenter::object $packetName]
		if {$tmpInfo != ""} {
			set errMsg "$packetName已经创建过，不可以创建同名的对象。"
		} else {
			# 组建创建packet的命令
			set tmpSubCmd ""
			append tmpSubCmd Create $packetType Pkt
			set tmpCmd "packet1 $tmpSubCmd -PduName $packetName"
		}

		if {$args != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $args] == 1} {
					set args [lindex $args 0]
				} else {
					break
				}
			}
			foreach {option value} $args {
				lappend tmpCmd $option $value
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		# 执行命令
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "创建$packetName 发生异常,错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "创建$packetName 失败，返回值为:$res ."
			break
		}

		set errMsg "创建$packetName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::AddPDUToStream {streamName PduList}
#Description:   将PDUList中的PDU添加进streamName中
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    streamName     指定要添加PDU的steam对象
#    PduList        表示需要添加到streamName中的PDU列表。
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::AddPDUToStream {streamName PduList} {

	set log [LOG::init TestCenter_AddPDUToStream]
	set errMsg ""

	foreach once {once} {

		# 检查参数PduList是否为空
		if {$PduList == ""} {
			set errMsg "PduList为空，无法添加PDU."
			break
		}
		# 去掉PduList多余的列表层{}
		for {set i 0} {$i<10} {incr i} {
			if {[llength $PduList] == 1} {
				set PduList [lindex $PduList 0]
			} else {
				break
			}
		}

		# 检查参数PduList中的元素是否合法
		#set pduValid 1
		#foreach pdu $PduList {
		#	set tmpInfo [array get TestCenter::object $pdu]
		#	if {$tmpInfo == ""} {
		#		set pduValid 0
		#		break
		#	}
		#}
		#if {$pduValid == 0} {
		#	set errMsg "PduList中的某些对象不存在，无法添加PDU."
		#	break
		#}

		# 判断streamName是否已存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $streamName]
		if {$tmpInfo != ""} {
			if {[llength $PduList] == 1} {
				set tmpPduList $PduList
			} else {
				set tmpPduList [list $PduList]
			}

			set tmpCmd "$streamName AddPdu -PduName $tmpPduList"
		} else {
			set errMsg "$streamName 还未创建，无法添加PDU。"
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$streamName 添加$PduList 发生异常,错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$streamName 添加$PduList 失败，返回值为:$res ."
			break
		}

		set errMsg "$streamName 添加$PduList 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::ClearTestResult {portOrStream {nameList ""}}
#Description:   清零当前的测试统计结果
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       portOrStream: 指明是清零端口的统计结果还是stream的统计结果,或者是所有的统计结果，取值范围为 port | stream | all
#       nameList: 表示端口名list或者stream名list，如果为空，表示清零所有结果
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::ClearTestResult {portOrStream {nameList ""}} {

	set log [LOG::init TestCenter_ClearTestResult]
	set errMsg ""

	foreach once {once} {
		# 利用之前创建的chassis1对象，释放资源
		if {$::TestCenter::chassisObject == ""} {
			set errMsg "chassis1对象不存在，无法清零统计结果 ."
			break
		}

		# 根据portOrStream和namelist参数组建不同的命令
		if {$portOrStream == "port"} {
			if {$nameList == ""} {

				set tmpCmd "$::TestCenter::chassisObject ClearTestResults -portnamelist All"
			} else {
				# 去掉nameList多余的列表层{}
				for {set i 0} {$i<10} {incr i} {
					if {[llength $nameList] == 1} {
						set nameList [lindex $nameList 0]
					} else {
						break
					}
				}

				set nameList [list $nameList]

				set tmpCmd "$::TestCenter::chassisObject ClearTestResults -portnamelist $nameList"

			}

		} elseif {$portOrStream == "stream"} {
			if {$nameList == ""} {

				set tmpCmd "$::TestCenter::chassisObject ClearTestResults -streamnamelist All"
			} else {
				# 去掉nameList多余的列表层{}
				for {set i 0} {$i<10} {incr i} {
					if {[llength $nameList] == 1} {
						set nameList [lindex $nameList 0]
					} else {
						break
					}
				}

				set nameList [list $nameList]

				set tmpCmd "$::TestCenter::chassisObject ClearTestResults -streamnamelist $nameList"
			}

		} elseif {$portOrStream == "all"} {
			set tmpCmd "$::TestCenter::chassisObject ClearTestResults"
		}

		if {$nameList == ""} {
			if {$portOrStream == "stream"} {
				set nameList "所有stream"
			} elseif {$portOrStream == "port"} {
				set nameList "所有port"
			} elseif {$portOrStream == "all"} {
				set nameList "所有"
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "清零 $nameList 的统计结果发生异常,错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "清零 $nameList 的统计结果失败，返回值为:$res ."
			break
		}

		set errMsg "清零 $nameList 的统计结果成功。"

		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::RemovePDUFromStream {streamName PduList}
#Description:   将PDUList中的PDU从streamName中移除
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    streamName     指定要移除PDU的steam对象
#    PduList        表示需要移除的PDU列表。
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::RemovePDUFromStream {streamName PduList} {

	set log [LOG::init TestCenter_AddPDUToStream]
	set errMsg ""

	foreach once {once} {
		# 检查参数PduList是否为空
		if {$PduList == ""} {
			set errMsg "PduList为空，无法移除PDU."
			break
		}

		# 去掉PduList多余的列表层{}
		for {set i 0} {$i<10} {incr i} {
			if {[llength $PduList] == 1} {
				set PduList [lindex $PduList 0]
			} else {
				break
			}
		}

		# 检查参数PduList中的元素是否合法
		set pduValid 1
		foreach pdu $PduList {
			set tmpInfo [array get TestCenter::object $pdu]
			if {$tmpInfo == ""} {
				set pduValid 0
				break
			}
		}
		if {$pduValid == 0} {
			set errMsg "PduList中的某些对象不存在，无法移除PDU."
			break
		}

		# 判断streamName是否已存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $streamName]
		if {$tmpInfo != ""} {
			set tmpCmd "$streamName RemovePdu -PduName $PduList"
		} else {
			set errMsg "$streamName 还未创建，无法移除PDU。"
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$streamName 移除$PduList 发生异常,错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "$streamName 移除$PduList 失败，返回值为:$res ."
			break
		}

		set errMsg "$streamName 移除$PduList 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]

}


#*******************************************************************************
#Function:    ::TestCenter::SetupFilter {portName filterName filterType filterValue {filterOnStreamId FALSE}}
#Description:   在指定端口创建或配置过滤器，如果过滤器已存在，则配置其属性，如果不存在，
#               则先创建一个新的过滤器对象并配置其属性
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要创建或配置过滤器的端口名
#    filterName 表示需要创建或配置的过滤器名
#    filterType 表示过滤器对象类型 UDF 或者Stack
#    filtervalue 表示过滤器对象的值，格式为{{FilterExpr1}{FilterExpr2}…}
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
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetupFilter {portName filterName filterType filterValue {filterOnStreamId FALSE}} {

	set log [LOG::init TestCenter_SetupFilter]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建或配置过滤器对象."
			break
		}

		# 检查参数filterName是否为空
		if {$filterName == ""} {
			set errMsg "filterName为空，无法创建或配置过滤器对象."
			break
		}

		set tmpFilterValue [list $filterValue]

		# 判断filterName是否已存在，如果存在，修改它的属性，否则，新建filter，并设置它的属性
		set tmpInfo [array get TestCenter::object $filterName]
		if {$tmpInfo != ""} {
			# 配置filter
			set tmpCmd "$portName ConfigFilter -FilterName $filterName -FilterType $filterType \
			            -Filtervalue $tmpFilterValue -FilterOnStreamId $filterOnStreamId"
		} else {
			# 创建filter
			set tmpCmd "$portName CreateFilter -FilterName $filterName -FilterType $filterType \
			            -Filtervalue $tmpFilterValue -FilterOnStreamId $filterOnStreamId"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$portName 创建$filterName 发生异常,错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($filterName) $filterName
		} else {
			set errMsg "$portName 创建$filterName 失败，返回值为:$res ."
			break
		}

		set errMsg "$portName 创建$filterName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]

}


#*******************************************************************************
#Function:    ::TestCenter::SetupStaEngine {portName staEngineName staEngineType}
#Description:   在指定端口创建统计分析引擎
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName          表示需要创建统计分析引擎的端口名
#    staEngineName     表示需要创建的统计分析引擎的名字
#    staEmgomeType     表示创建的StaEngine 的类型 可选值Statistics, Analysis。
#                      Statistics主要用于结果统计，而Analysis主要用于抓包分析
#                      默认为Statistics

#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:    无
#*******************************************************************************
proc ::TestCenter::SetupStaEngine {portName staEngineName {staEngineType "Statistics"}} {

	set log [LOG::init TestCenter_SetupStaEngine]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法创建统计分析引擎."
			break
		}

		# 检查参数staEngineName是否为空
		if {$staEngineName == ""} {
			set errMsg "staEngineName为空，无法创建统计分析引擎."
			break
		}

		# 判断staEngineName是否已存在，如果存在，则返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo != ""} {
			set errMsg "$staEngineName已经存在，不能创建同名对象."
			break
		} else {
			# 创建staEngineName
			set tmpCmd "$portName CreateStaEngine -StaEngineName $staEngineName -staType $staEngineType"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $tmpCmd"
		if {[catch {set res [eval $tmpCmd]} err] == 1} {
			set errMsg "$portName 创建$staEngineName 发生异常,错误信息为:$err ."
			break
		}
		if {$res == 0} {
			set TestCenter::object($staEngineName) $staEngineName
		} else {
			set errMsg "$portName 创建$staEngineName 失败，返回值为:$res ."
			break
		}

		set errMsg "$portName 创建$staEngineName 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]

}


#*******************************************************************************
#Function:    ::TestCenter::StartStaEngine {portName }
#Description:   在指定端口开启统计分析引擎
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要开启统计引擎的端口名
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StartStaEngine {portName} {

	set log [LOG::init TestCenter_StartStaEngine]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法开启统计分析引擎."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $portName StartStaEngine"
		# 开启指定端口的统计引擎
		if {[catch {set res [$portName StartStaEngine]} err] == 1} {
			set errMsg "开启$portName 的统计引擎发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "开启$portName 的统计引擎失败，返回值为:$res ."
			break
		}
		set errMsg "$portName 开启统计分析引擎成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]

}


#*******************************************************************************
#Function:    ::TestCenter::StopStaEngine {portName }
#Description:   在指定端口停止统计引擎
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName   表示需要停止统计引擎的端口名
#
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg    表示调用函数失败
#    其他值                                         表示失败
#
#Others:         无
#*******************************************************************************
proc ::TestCenter::StopStaEngine {portName} {

	set log [LOG::init TestCenter_StopStaEngine]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法停止统计分析引擎."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $portName StopStaEngine"
		# 停止指定端口的统计引擎
		if {[catch {set res [$portName StopStaEngine]} err] == 1} {
			set errMsg "停止$portName 的统计引擎发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "停止$portName 的统计引擎失败，返回值为:$res ."
			break
		}
		set errMsg "$portName 停止统计分析引擎成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]

}


#*******************************************************************************
#Function:    ::TestCenter::PortStartTraffic {chassisName {portList ""} { clearStatistic "1"} { flagArp "TRUE" } }
#Description:   控制端口进行发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    chassisName     表示发流端口所属机框的机框对象名
#    portList        表示需要发流的端口的端口名列表。为空表示所有端口 ，默认为空
#    clearStatistic  表示是否清除端口的统计计数，为1，清除，为0，不清除,默认为1
#    flagArp         表示是否进行ARP学习，为TRUE, 进行，为FLASE，不进行，默认为TRUE
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::PortStartTraffic {chassisName {portList ""} {clearStatistic "1"} {flagArp "TRUE"} } {

	set log [LOG::init TestCenter_PortStartTraffic]
	set errMsg ""

	foreach once {once} {
		# 检查参数chassisName指定的对象是否存在，如果不存在，返回失败
		if {$::TestCenter::chassisObject != $chassisName} {
			set errMsg "$chassisName不存在，无法开启发流."
			break
		}

		# 根据portList是否为空，组建不同控制开始发流的命令
		if {$portList != ""} {
			# 去除portList多余的列表层
			for {set i 0} {$i<10} {incr i} {
				if {[llength $portList] == 1} {
					set portList [lindex $portList 0]
				} else {
					break
				}
			}
			# 转化portList为列表
			if {[llength $portList] == 1} {
				set tmpPortList $portList
			} else {
				set tmpPortList [list $portList]
			}

			set cmd "$chassisName StartTraffic -PortList $tmpPortList -ClearStatistic $clearStatistic -FlagArp $flagArp"
		} else {
			set cmd "$chassisName StartTraffic -ClearStatistic $clearStatistic -FlagArp $flagArp"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		# port开始发流
		if {[catch {set res [eval $cmd]} err] == 1} {
			set errMsg "开启port发流发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "开启port发流失败，返回值为:$res ."
			break
		}
		set errMsg "开启port发流成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::PortStopTraffic {chassisName portList}
#Description:   控制端口停止发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    chassisName   表示发流端口所属机框的机框对象名
#    portList      表示需要停止发流的端口的端口名列表。为空表示所有端口，默认为空
#Output:   无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:    无
#*******************************************************************************
proc ::TestCenter::PortStopTraffic {chassisName {portList ""}} {

	set log [LOG::init TestCenter_PortStopTraffic]
	set errMsg ""

	foreach once {once} {
		# 检查参数chassisName指定的对象是否存在，如果不存在，返回失败
		if {$::TestCenter::chassisObject != $chassisName} {
			set errMsg "$chassisName不存在，无法停在发流."
			break
		}

		# 根据portList是否为空，组建不同控制停止发流的命令
		if {$portList != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $portList] == 1} {
					set portList [lindex $portList 0]
				} else {
					break
				}
			}
			if {[llength $portList] == 1} {
				set tmpPortList $portList
			} else {
				set tmpPortList [list $portList]
			}
			set cmd "$chassisName StopTraffic -PortList $tmpPortList"
		} else {
			set cmd "$chassisName StopTraffic"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		# 停止port发流
		if {[catch {set res [eval $cmd]} err] == 1} {
			set errMsg "停止port发流发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "停止port发流失败，返回值为:$res ."
			break
		}
		set errMsg "停止port发流成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StreamStartTraffic {portName { clearStatistic "1"} {flagArp "TRUE" } {streamList ""}}
#Description:   控制stream进行发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName        表示发流stream所属端口的端口对象名
#    clearStatistic  表示是否清除端口的统计计数，为1，清除，为0，不清除，默认为1
#    flagArp         表示是否进行ARP学习，为TRUE, 进行，为FLASE，不进行，默认为TRUE
#    streamList      表示需要发流的stream的名字列表。为空表示该端口下所有流,默认为空
#
#Output:  无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StreamStartTraffic {portName {clearStatistic "1"} {flagArp "TRUE"} {streamList ""}} {

	set log [LOG::init TestCenter_StreamStartTraffic]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法开启发流."
			break
		}

		# 根据streamList是否为空，组建不同控制开始发流的命令
		if {$streamList != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $streamList] == 1} {
					set streamList [lindex $streamList 0]
				} else {
					break
				}
			}

			if {[llength $streamList] == 1} {
				set tmpStreamList $streamList
			} else {
				set tmpStreamList [list $streamList]
			}

			set cmd "$portName StartTraffic -StreamNameList $tmpStreamList -ClearStatistic $clearStatistic -FlagArp $flagArp"
		} else {
			set cmd "$portName StartTraffic -ClearStatistic $clearStatistic -FlagArp $flagArp"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		# stream开始发流
		if {[catch {set res [eval $cmd]} err] == 1} {
			set errMsg "开启stream发流发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "开启stream发流失败，返回值为:$res ."
			break
		}
		set errMsg "开启stream发流成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StreamStopTraffic {portName streamList}
#Description:   控制stream停止发流
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    portName       表示发流stream所属端口的端口对象名
#    streamList     表示需要停止发流的stream的名字列表。为空表示该端口下所有流
#Output:    无
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:    无
#*******************************************************************************
proc ::TestCenter::StreamStopTraffic {portName {streamList ""}} {

	set log [LOG::init TestCenter_StreamStopTraffic]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法停止发流."
			break
		}

		# 根据streamList是否为空，组建不同控制停止发流的命令
		if {$streamList != ""} {
			for {set i 0} {$i<10} {incr i} {
				if {[llength $streamList] == 1} {
					set streamList [lindex $streamList 0]
				} else {
					break
				}
			}
			if {[llength $streamList] == 1} {
				set tmpStreamList $streamList
			} else {
				set tmpStreamList [list $streamList]
			}
			set cmd "$portName StopTraffic -StreamNameList $tmpStreamList"
		} else {
			set cmd "$portName StopTraffic"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		# 停止stream发流
		if {[catch {set res [eval $cmd]} err] == 1} {
			set errMsg "停止stream发流发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "停止stream发流失败，返回值为:$res ."
			break
		}
		set errMsg "停止stream发流成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StartCapture {staEngineName {savePath ""} {filterName ""}}
#Description:   控制分析引擎开始捕获报文，保存报文到指定路径下
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    staEngineName   表示需要开启捕获报文的分析引擎名
#    savePath        表示捕获的报文保存的路径名。如果该参数为空，
#                    默认保存到C盘下，以端口号命名。例如:C:/port1.pap
#    filterName      表示要过滤保存报文使用的过滤器的名字。
#Output:         无
# Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::StartCapture {staEngineName {savePath ""} {filterName ""}} {

	set log [LOG::init TestCenter_StartCapture]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法开启捕获报文."
			break
		}

		#根据传入参数组建命令
		if {$filterName != "" } {
			if {$savePath  != ""} {
				set cmd "$staEngineName ConfigCaptureMode -FilterName $filterName -CaptureFile $savePath"
			} else {
				set cmd "$staEngineName ConfigCaptureMode -FilterName $filterName"
			}
		} else {
			if {$savePath != ""} {
				set cmd "$staEngineName ConfigCaptureMode -CaptureFile $savePath"
			} else {
				set cmd  ""
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		#设置报文保存的路径和过滤器
		if {$cmd != ""} {
			if {[catch {set res [eval $cmd]} err] == 1} {

				set errMsg "设置报文保存的路径和过滤器发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "设置报文保存的路径和过滤器失败，返回值为:$res ."
				break
			}
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $staEngineName StartCapture"
		#开启捕获报文
		if {[catch {set res [$staEngineName StartCapture]} err] == 1} {
			set errMsg "开启捕获报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "开启捕获报文失败，返回值为:$res ."
			break
		}
		set errMsg "开启捕获报文成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::StopCapture {staEngineName}
#Description:    停止分析引擎捕获报文
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#      staEngineName   表示需要停止捕获报文的分析引擎名
#Output:         无
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:         无
#*******************************************************************************
proc ::TestCenter::StopCapture {staEngineName} {

	set log [LOG::init TestCenter_StopCapture]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法关闭捕获报文."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $staEngineName StopCapture"
		# 停止捕获报文
		if {[catch {set res [$staEngineName StopCapture]} err] == 1} {
			set errMsg "停止捕获报文发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "停止捕获报文失败，返回值为:$res ."
			break
		}

		set errMsg "停止捕获报文成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::GetPortStats {staEngineName resultData {subOption ""} {filterStream "0"}}
#Description:   从端口统计信息中获取指定项option的信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    staEngineName    表示获取统计信息的端口的统计引擎名
#    filterStream     表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值
#    subOption        表示需要获取的统计结果子项名。如果为空，返回所有信息
#Output:
#    resultData    返回获取的统计结果信息。如果指定了过滤，则返回过滤后的所有信息。
#                  如果指定了subOption，则返回指定项的信息
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:  无
#*******************************************************************************
proc ::TestCenter::GetPortStats {staEngineName resultData {filterStream "0"} {subOption ""}} {

	set log [LOG::init TestCenter_GetPortStats]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法获取端口统计结果."
			break
		}

		# 绑定本地变量和返回值
		upvar 1 $resultData tmpResult

		# 判断是否获取过滤统计结果信息,执行相应命令
		if {$filterStream == 0} {
			set cmd "$staEngineName GetPortStats"
		} else {
			set cmd "$staEngineName GetPortStats -FilteredStream 1"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		if {[catch {set result [eval $cmd]} err] == 1} {
			set errMsg "通过$staEngineName 获取端口的统计数据信息发生异常，错误信息为:$err ."
			break
		}

		# 返回subOption指定项的信息
		if {$result != ""} {
			if {$subOption != ""} {
				if {$filterStream == 0} {
					set index [lsearch -nocase $result -$subOption]
					if {$index != -1} {
						set tmpResult [lindex $result [expr $index + 1]]
					} else {
						set errMsg "从统计结果中获取$subOption的信息失败，返回值为:$result ."
						break
					}
				} else {
					set aggregateResult [lindex $result 0]

					set index [lsearch -nocase $aggregateResult -$subOption]
					if {$index != -1} {
						set tmpResult [lindex $aggregateResult [expr $index + 1]]
					} else {
						set errMsg "从统计结果中获取$subOption的信息失败，返回值为:$aggregateResult ."
						break
					}
				}
			} else {
				set tmpResult $result
			}
		} else {
			set errMsg "通过$staEngineName 获取端口的统计数据信息失败，返回值为:$result ."
			break
		}

		set errMsg "通过$staEngineName 获取端口的统计数据信息成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::GetPortStatsSnapshot {staEngineName resultData {filterStream "0"} {resultPath ""}}
#Description:   获取端口统计信息快照
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    staEngineName    表示获取统计信息的端口的统计引擎名
#    filterStream     表示是否过滤统计结果。为1，返回过滤过后的结果值，为0，返回过滤前的值
#    resultPath      表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下
#Output:
#    resultData    返回获取的统计结果信息。如果指定了过滤，则返回过滤后的所有信息。
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:  无
#*******************************************************************************
proc ::TestCenter::GetPortStatsSnapshot {staEngineName resultData {filterStream "0"} {resultPath ""}} {

	set log [LOG::init TestCenter_GetPortStats]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法获取端口统计结果."
			break
		}

		# 绑定本地变量和返回值
		upvar 1 $resultData tmpResult

		# 判断是否获取过滤统计结果信息,执行相应命令
		if {$filterStream == 0} {
			set cmd "$staEngineName GetPortStats -ResultPath $resultPath"
		} else {
			set cmd "$staEngineName GetPortStats -FilteredStream 1 -ResultPath $resultPath"
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		if {[catch {set result [eval $cmd]} err] == 1} {
			set errMsg "通过$staEngineName 获取端口的统计数据信息发生异常，错误信息为:$err ."
			break
		}

		# 判断result
		if {$result != ""} {
			if {$filterStream == 0} {
				set tmpResult $result
			} else {
				set tmpResult [lindex $result 0]
			}
		} else {
			set errMsg "通过$staEngineName 获取端口的统计数据信息失败，返回值为:$result ."
			break
		}

		set errMsg "通过$staEngineName 获取端口的统计数据信息成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::GetStreamStats {staEngineName streamName resultData option }
#Description:   从Stream统计信息中获取指定项option的信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    staEngineName   表示获取统计信息的端口的统计引擎名
#    streamName      表示需要统计的流的名字
#    subOption       表示需要获取的统计结果的子项名。如果为空，返回所有子项信息
#Output:
#    resultData    返回获取的统计结果信息。
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::GetStreamStats {staEngineName streamName resultData {subOption ""}} {

	set log [LOG::init TestCenter_GetStreamStats]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法获取流统计结果."
			break
		}

		# 绑定本地变量和返回值
		upvar 1 $resultData tmpResult

		if {$subOption != ""} {
			# 获取流的统计信息中的指定子项的信息
			set cmd "$staEngineName GetStreamStats -StreamName $streamName -$subOption tmpResult"
			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
			if {[catch {set res [eval $cmd]} err] == 1} {
				set errMsg "获取$streamName 中的$subOption 的信息发生异常，错误信息为:$err ."
				break
			}
			if {$res != 0} {
				set errMsg "获取$streamName 中的$subOption 的信息失败，返回值为:$res ."
				break
			}
		} else {
			# 获取流的所有子项的统计信息
			set cmd "$staEngineName GetStreamStats -StreamName $streamName"
			LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
			if {[catch {set tmpResult [eval $cmd]} err] == 1} {
				set errMsg "获取$streamName 中的$subOption 的信息发生异常，错误信息为:$err ."
				break
			}
			if {$tmpResult == ""} {
				set errMsg "获取$streamName 中的$subOption 的信息失败，返回值为:$tmpResult ."
				break
			}
		}

		set errMsg "获取$streamName 中的$subOption 的信息成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::GetStreamStatsSnapshot {staEngineName streamName resultData {resultPath ""}}
#Description:   获取Stream统计信息
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#    staEngineName   表示获取统计信息的端口的统计引擎名
#    streamName      表示需要统计的流的名字
#    resultPath      表示统计结果保存的路径名。如果该参数为空,则保存到默认路径下
#Output:
#    resultData    返回获取的统计结果信息。
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::GetStreamStatsSnapshot {staEngineName streamName resultData {resultPath ""}} {

	set log [LOG::init TestCenter_GetStreamStatsSnapshot]
	set errMsg ""

	foreach once {once} {
		# 检查参数staEngineName指定的对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $staEngineName]
		if {$tmpInfo == ""} {
			set errMsg "$staEngineName不存在，无法获取流统计结果."
			break
		}

		# 绑定本地变量和返回值
		upvar 1 $resultData tmpResult

		# 获取流的所有子项的统计信息
		set cmd "$staEngineName GetStreamStats -StreamName $streamName -ResultPath $resultPath"
		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $cmd"
		if {[catch {set tmpResult [eval $cmd]} err] == 1} {
			set errMsg "获取$streamName 的统计信息快照发生异常，错误信息为:$err ."
			break
		}
		if {$tmpResult == ""} {
			set errMsg "获取$streamName 的统计信息快照失败，返回值为:$tmpResult ."
			break
		}

		set errMsg "获取$streamName 的统计信息快照成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SaveConfig { path}
#Description:  将脚本配置保存为xml文件
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       path  xml文件保存的路径
#Output:
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SaveConfig {path} {

	set log [LOG::init TestCenter_SaveConfig]
	set errMsg ""

	LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: SaveConfigAsXML $path"
	if {[catch {SaveConfigAsXML $path} err] == 1} {

		set errMsg "保存配置到$path 文件发生异常，错误信息为:$err ."
		LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
		return [list $TestCenter::FunctionExecuteError $errMsg]
	}

	set errMsg "保存配置到$path 文件成功。"
	return [list $TestCenter::ExpectSuccess $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::SetStreamSchedulingMode {portName {schedulingMode RATE_BASED}}
#Description:  设置端口上数据流的调度模式
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:
#       portName  端口名
#       schedulingMode 数据流的调度模式，取值范围为：PORT_BASED | RATE_BASED | PRIORITY_BASED，默认为RATE_BASED
#Output:
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::SetStreamSchedulingMode {portName {schedulingMode RATE_BASED}} {

	set log [LOG::init TestCenter_SetStreamSchedulingMode]
	set errMsg ""

	foreach once {once} {

		# 利用之前创建的chassis1对象，设置端口数据流的调度模式
		if {$::TestCenter::chassisObject == ""} {
			set errMsg "未连接TestCenter,无法设置数据流的调度模式 ."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $::TestCenter::chassisObject ConfigStreamSchedulingMode -portname $portName -schedulingmode $schedulingMode"
		if {[catch {set res [$::TestCenter::chassisObject ConfigStreamSchedulingMode -portname $portName -schedulingmode $schedulingMode]} err] == 1} {
			set errMsg "设置端口$portName上数据流的调度模式为$schedulingMode 发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "设置端口$portName上数据流的调度模式为$schedulingMode 失败，错误信息为:$err ."
			break
		}

		set errMsg "设置端口$portName上数据流的调度模式为$schedulingMode 成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}

	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::CleanupTest { }
#Description:  清除测试，释放资源
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:   无
#Output:
#Return:
#    list $TestCenter::ExpectSuccess $msg          表示成功
#    list $TestCenter::FunctionExecuteError $msg   表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::CleanupTest {} {

	set log [LOG::init TestCenter_CleanupTest]
	set errMsg ""

	foreach once {once} {
		# 利用之前创建的chassis1对象，释放资源
		if {$::TestCenter::chassisObject == ""} {
			set errMsg "chassis1对象不存在，无法释放资源 ."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $::TestCenter::chassisObject CleanupTest"
		if {[catch {set res [$::TestCenter::chassisObject CleanupTest]} err] == 1} {
			set errMsg "释放资源发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "释放资源失败，错误信息为:$err ."
			break
		}

		# 清空保存对象的变量
		set ::TestCenter::chassisObject ""
		array unset ::TestCenter::object
		array set ::TestCenter::object {}

		set errMsg "释放资源成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}

    LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::DestroyFilter { }
#Description:  销毁过滤器对象
#Calls:   无
#Data Accessed:  无
#Data Updated:  无
#Input:   无
#Output:
#Return:
#    list $TestCenter::ExpectSuccess  $msg         表示成功
#    list $TestCenter::FunctionExecuteError  $msg  表示调用函数失败
#    其他值                                        表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::DestroyFilter {portName} {

	set log [LOG::init TestCenter_DestroyFilter]
	set errMsg ""

	foreach once {once} {
		# 检查参数portName指定的端口对象是否存在，如果不存在，返回失败
		set tmpInfo [array get TestCenter::object $portName]
		if {$tmpInfo == ""} {
			set errMsg "$portName不存在，无法销毁过滤器对象."
			break
		}

		LOG::DebugInfo $log [expr $[namespace current]::currentFileName] "RUN CMD: $portName DestroyFilter"
		# 利用之前创建的portName对象，释放资源
		if {[catch {set res [$portName DestroyFilter]} err] == 1} {
			set errMsg "销毁过滤器对象发生异常，错误信息为:$err ."
			break
		}
		if {$res != 0} {
			set errMsg "销毁过滤器对象失败，错误信息为:$err ."
			break
		}

		set errMsg "$portName 销毁过滤器对象成功。"
		return [list $TestCenter::ExpectSuccess $errMsg]
	}
	LOG::DebugErr $log [expr $[namespace current]::currentFileName] $errMsg
	return [list $TestCenter::FunctionExecuteError $errMsg]
}


#*******************************************************************************
#Function:    ::TestCenter::IsObjectExist { objectName }
#Description:  检查objectName是否存在::TestCenter::object数组中，存在返回1，不存在返回0
#Calls:   无
#Data Accessed:
#     ::TestCenter::object
#Data Updated:  无
#Input:
#       objectName    表示要检查的对象名
#Output:
#Return:
#    1           表示存在
#    0           表示不存在
#    其他值      表示失败
#
#Others:   无
#*******************************************************************************
proc ::TestCenter::IsObjectExist {objectName} {

	set tmpInfo [array get TestCenter::object $objectName]
	if {$tmpInfo == ""} {
		return 0
	} else {
		return 1
	}
}
