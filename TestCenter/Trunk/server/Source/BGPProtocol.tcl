###########################################################################
#                                                                        
#  File Name：BGPProtocol.tcl                                                                                              
# 
#  Description：Define BGP class and corresponding API implement                                    
# 
#  Author： Jaimin
#
#  Create time:  2007.6.6
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

::itcl::class BgpV4Session {
     #Inherit Router class
    inherit Router

    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName
    public variable m_hbgpRouter
    public variable m_bgpCapList
    public variable m_hBgpblock
    public variable m_hBgpVpn
    public variable m_hVpngrp
    public variable m_hVpnSite
    public variable m_awdTime ""
    public variable m_wadTime ""
    public variable m_hMpls ""
    public variable m_hEncapMplsIf ""
    public variable m_vpnList ""
    public variable m_vpnSiteVpnList ""
    public variable m_peIPv4Address 
    public variable m_bgpAdverFlag
    public variable m_vpnAdverFlag
    public variable m_hResultDataSet
    public variable m_vpnRD
    public variable m_vpnRT
    public variable m_SiteToBlock
    public variable m_SiteToVpnName
    public variable m_VpnNameList ""
    public variable m_hIpv4
    public variable m_vpnRouterBlock
    public variable m_portType "ethernet"
    public variable m_firstRouteListFlag "FALSE"
    public variable m_viewRoutes "FALSE"
	public variable m_enablePackRoutes "FALSE" 
     
    public variable m_hEthIIIf ""
    public variable m_LocalMac "00:00:00:11:01:01"
    public variable m_LocalMacModifier "00:00:00:00:00:01"
    
    public variable m_bfdSession ""

    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
          { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     

        set m_routerName $routerName       
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_portType $portType
        
        #Create Bgp Router 
        set bgpcfg1 [stc::create BgpRouterConfig -under $m_hRouter]
        set m_hbgpRouter $bgpcfg1
     
        #Get Ethernet interface
        if {$m_portType == "ethernet"} {
            set EthIIIf1 [stc::get $hRouter -children-EthIIIf]
            set m_hMacAddress $EthIIIf1    
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set EthIIIf1 [stc::get $hRouter -children-HdlcIf]
            } else {
                set EthIIIf1 [stc::get $hRouter -children-PppIf]
            }
        } 
        set m_hEthIIIf $EthIIIf1
        #Get Ipv4 interface
        set ipv4if1 [stc::get $hRouter -children-Ipv4If]       
        set m_hIpv4 $ipv4if1
        set m_hIpAddress $ipv4if1
     
        stc::config $bgpcfg1 -UsesIf-targets $ipv4if1
    }

    destructor {
    }

    public method BgpV4SetSession
    public method BgpV4RetrieveRouter
    public method BgpV4SetCapability
    public method BgpV4RetrieveCapability
    public method BgpV4Enable
    public method BgpV4Disable
    public method BgpV4CreateRouteBlock    
    public method BgpV4DeleteRouteBlock
    public method BgpV4ListRouteBlock
    public method BgpV4SetRouteBlock
    public method BgpV4RetrieveRouteBlock
    public method BgpV4AdvertiseRouteBlock
    public method BgpV4WithdrawRouteBlock
    public method BgpV4StartFlapRouteBlock    
    public method BgpV4StopFlapRouteBlock
    public method BgpV4SetFlapRouteBlock
    public method BgpV4RetrieveRouteStats
    public method BgpV4CreateMplsVpn
    public method BgpV4SetMplsVpn
    public method BgpV4DeleteMplsVpn
    public method BgpV4CreateMplsVpnSite    
    public method BgpV4CreateVpnToSite
    public method BgpV4DeleteVpnFromSite
    public method BgpV4SetMplsVpnSite
    public method BgpV4ListMplsVpnSite
    public method BgpV4DeleteMplsVpnSite
    public method BgpV4CreateVpnRouteBlock
    public method BgpV4DeleteVpnRouteBlock    
    public method BgpV4SetVpnRouteBlock
    public method BgpV4RetrieveVpnRouteBlock
    
    public method BgpV4CreateRouteBlockToVPN
    public method BgpV4DeleteRouteBlockFromVPN
    public method BgpV4RetrieveVPNRoutes
    public method BgpImportRouteTable
    #added by yuanfen 8.24 2011
    public method Bgpv4RouterLinkIGP
    public method BgpV4ViewRouter
    
    #added by yuanfen 10.27 2011
    public method BgpV4Create6VPEVpn
    public method BgpV4Create6VPESite
    
    public method BgpV4SetBfd
    public method BgpV4UnsetBfd
    public method BgpV4StartBfd
    public method BgpV4StopBfd
    
}
    
############################################################################
#APIName: BgpV4SetSession
#Description: Config BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetSession {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetSession"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of PeerType 
    set index [lsearch $args -peertype] 
    if {$index != -1} {
        set PeerType [lindex $args [expr $index + 1]]
    } 

    #Abstract the value of TesterIp 
    set index [lsearch $args -testerip] 
    if {$index != -1} {
        set TesterIp [lindex $args [expr $index + 1]]
        #Find and config the Mac address from Host according to TesterIp
        SetMacAddress $TesterIp
    } 

    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of TesterAs 
    set index [lsearch $args -testeras] 
    if {$index != -1} {
        set TesterAs [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of SutIp 
    set index [lsearch $args -sutip] 
    if {$index != -1} {
        set SutIp [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of SutAs 
    set index [lsearch $args -sutas] 
    if {$index != -1} {
        set SutAs [lindex $args [expr $index + 1]]
    }

    #Abstract the value of FlagMd5 
    set index [lsearch $args -flagmd5] 
    if {$index != -1} {
        set FlagMd5 [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of Md5 
    set index [lsearch $args -md5] 
    if {$index != -1} {
        set Md5 [lindex $args1 [expr $index + 1]]
    } else  {
        set Md5 ""
    }

    #Abstract the value of HoldTimer 
    set index [lsearch $args -holdtimer] 
    if {$index != -1} {
        set HoldTimer [lindex $args [expr $index + 1]]
    } 

    #Abstract the value of KeepaliveTimer 
    set index [lsearch $args -keepalivetimer] 
    if {$index != -1} {
        set KeepaliveTimer [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ConnectRetryTimer 
    set index [lsearch $args -connectretrytimer] 
    if {$index != -1} {
        set ConnectRetryTimer [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ConnectRetryCount 
    set index [lsearch $args -connectretrycount] 
    if {$index != -1} {
        set ConnectRetryCount [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of GateWay 
    set index [lsearch $args -gateway] 
    if {$index != -1} {
        set GateWay [lindex $args [expr $index + 1]]
    } else {
        set GateWay ""
    }
    
    #Abstract the value of RoutesPerUpdate 
    set index [lsearch $args -routesperupdate] 
    if {$index != -1} {
        set RoutesPerUpdate [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of InterUpdateDelay 
    set index [lsearch $args -interupdatedelay] 
    if {$index != -1} {
        set InterUpdateDelay [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of StartingLabel 
    set index [lsearch $args -startinglabel] 
    if {$index != -1} {
        set StartingLabel [lindex $args [expr $index + 1]]
    }
    
    #added by yuanfen 7.21 2011
    #Abstract the value of LocalMac
    set index [lsearch $args -localmac]
    if {$index != -1} {
        set LocalMac [lindex $args [expr $index + 1]]
        set m_LocalMac $LocalMac
    } 
    
    #Abstract the value of LocalMacModifier
    set index [lsearch $args -localmacmodifier]
    if {$index != -1} {
        set LocalMacModifier [lindex $args [expr $index + 1]]
        set m_LocalMacModifier $LocalMacModifier
    }

    #Abstract the value of ViewRoutes
    set index [lsearch $args -viewroutes]
    if {$index != -1} {
        set ViewRoutes [lindex $args [expr $index + 1]]
        set m_viewRoutes $ViewRoutes
    }
	#Added by Yong @2013.7.24 for enablepackrouters 	
	set index [lsearch $args -enablepackroutes]
	if {$index != -1} {
		set EnablePackRoutes [lindex $args [expr $index + 1]]
		set m_enablePackRoutes $EnablePackRoutes
	}
    
    #Config BGP router

    set bgpcfg1 $m_hbgpRouter
    set glbgpcfg1 [stc::get $m_hProject -children-BgpGlobalConfig]
    if {[info exists ConnectRetryCount]} {
        stc::config $glbgpcfg1 -ConnectionRetryCount $ConnectRetryCount
    }
    if {[info exists ConnectRetryTimer]} {
        stc::config $glbgpcfg1 -ConnectionRetryInterval $ConnectRetryTimer
    }
    if {[info exists InterUpdateDelay]} {
        stc::config $glbgpcfg1 -UpdateDelay $InterUpdateDelay
    }
    if {[info exists RoutesPerUpdate]} {
        stc::config $glbgpcfg1 -UpdateCount $RoutesPerUpdate
    }
    if {[info exists PeerType]} {
        if {$PeerType == "ibgp"} {
            if {$TesterAs != $SutAs} {
                error "Bgp Type is IBgp,TesterAs number should be same with SutAs number"
            }
        }
        if {$PeerType == "ebgp"} {
            if {$TesterAs == $SutAs} {
                error "Bgp Type is EBgp,TesterAs number should be different with SutAs number"
            }
        }
    }
    if {[info exists TesterAs]} {
        stc::config $bgpcfg1 -AsNum $TesterAs
    }
    if {[info exists SutAs]} {
        stc::config $bgpcfg1 -PeerAs $SutAs
    }
    if {[info exists SutIp]} {
        stc::config $bgpcfg1 -DutIpv4Addr $SutIp
    }
    if {[info exists HoldTimer]} {
        stc::config $bgpcfg1 -HoldTimeInterval $HoldTimer
    }
    if {[info exists KeepaliveTimer]} {
        stc::config $bgpcfg1 -KeepAliveInterval $KeepaliveTimer
    }
    if {[info exists StartingLabel]} {
        stc::config $bgpcfg1 -MinLabel $StartingLabel
    }
    if {[info exists ViewRoutes]} {
        stc::config $bgpcfg1 -ViewRoutes $ViewRoutes
    }
	
	if {[info exists EnablePackRoutes]} {
		stc::config $bgpcfg1 -EnablePackRoutes $EnablePackRoutes
	}
    
    if {[string tolower $m_portType]=="ethernet"} {
        set hEthIIIf $m_hEthIIIf    
        if {[info exists LocalMac]} {
            stc::config $hEthIIIf -SourceMac $m_LocalMac
        }
        if {[info exists LocalMacModifier]} {
            stc::config $hEthIIIf -SrcMacStep $m_LocalMacModifier
        }
    }
    
    stc::config $bgpcfg1 -IpVersion IPV4
    if {[info exists TesterAs]} {
        if {[info exists Active]} {
            if {$Active == "true"} {
                stc::config $bgpcfg1 -Active TRUE
            } elseif {$Active == "false"} {
                stc::config $bgpcfg1 -Active FALSE
            }
        }
    }
    
    #Link router to specified object
    set ipv4if1 $m_hIpv4
    if {[info exists TesterIp]} { 
        stc::config $ipv4if1 -Address $TesterIp
    }
    if {[info exists PrefixLen]} { 
        stc::config $ipv4if1 -PrefixLength $PrefixLen
    }

    if {$GateWay !=""} {
        stc::config $ipv4if1 -Gateway $GateWay
    } else {
       set GateWay [GetGatewayIp $TesterIp]
       stc::config $ipv4if1 -Gateway $GateWay
    }
    
    if {[info exists FlagMd5]} {
        if {$FlagMd5 == "true"} {
            set auth1 [stc::get $bgpcfg1 -children-BgpAuthenticationParams]
            stc::config $auth1 -Authentication MD5 -Password $Md5
        } else {
            set auth1 [stc::get $bgpcfg1 -children-BgpAuthenticationParams]
            stc::config $auth1 -Authentication NONE
        }
    }

    debugPut "exit the proc of BgpV4Session::BgpV4SetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveRouter
#Description: Get routing information of BGP according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveRouter {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveRouter"
    #set args [string tolower $args]  
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]  
    
    #Abstract the value of PeerType 
    set index [lsearch $args -peertype] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] PeerType
    }    
    
    #Abstract the value of TesterIp 
    set index [lsearch $args -testerip] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] TesterIp 
    }
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] PrefixLen
    }
    
    #Abstract the value of TesterAs 
    set index [lsearch $args -testeras] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] TesterAs
    } 
    
    #Abstract the value of SutIp 
    set index [lsearch $args -sutip] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] SutIp
    }
    
    #Abstract the value of SutAs 
    set index [lsearch $args -sutas] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] SutAs
    }
    
    #Abstract the value of FlagMd5 
    set index [lsearch $args -flagmd5] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FlagMd5
    }
    
    #Abstract the value of Md5 
    set index [lsearch $args -md5] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Md5
    }
      
    #Abstract the value of HoldTimer 
    set index [lsearch $args -holdtimer] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] HoldTimer
    }
    
    #Abstract the value of KeepaliveTimer 
    set index [lsearch $args -keepalivetimer] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] KeepaliveTimer
    }
    
    #Abstract the value of ConnectRetryTimer 
    set index [lsearch $args -connectretrytimer] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ConnectRetryTimer
    }
    
    #Abstract the value of ConnectRetryCount 
    set index [lsearch $args -connectretrycount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ConnectRetryCount
    }
    
    #Abstract the value of RoutesPerUpdate 
    set index [lsearch $args -routesperupdate] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RoutesPerUpdate
    }
	
	   
    #Added by Yong @ 2013.7.24 
    set index [lsearch $args -enablepackroutes] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] EnablePackRoutes
    }
    
    #Abstract the value of GateWay 
    set index [lsearch $args -gateway] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] GateWay
    }
    
    #Abstract the value of InterUpdateDelay 
    set index [lsearch $args -interupdatedelay] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] InterUpdateDelay
    }    
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Active
    }
    
    #Abstract the value of State 
    set index [lsearch $args -state] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] State
    }
    #Abstract the value of FlagEndOfRib 
    set index [lsearch $args -flagendofrib] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FlagEndOfRib
    }
    #Abstract the value of StartingLabel 
    set index [lsearch $args -startinglabel] 
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] StartingLabel
    }
    
    set bgpRouter $m_hbgpRouter
    set Result ""
    set TesterAs [stc::get $bgpRouter -AsNum]
    lappend Result -TesterAs
    lappend Result $TesterAs
    set FlagEndOfRib "nonsupport"
    lappend Result -FlagEndOfRib
    lappend Result $FlagEndOfRib
    set SutAs [stc::get $bgpRouter -PeerAs]
    lappend Result -SutAs
    lappend Result $SutAs
    set SutIp [stc::get $bgpRouter -DutIpv4Addr]
    lappend Result -SutIp
    lappend Result $SutIp
	set EnablePackRoutes   [stc::get $bgpRouter -EnablePackRoutes]
    lappend Result -EnablePackRoutes
    lappend Result $EnablePackRoutes

    set StartingLabel [stc::get $bgpRouter -MinLabel]
    lappend Result -StartingLabel
    lappend Result $StartingLabel
    
    set HoldTimer [stc::get $bgpRouter -HoldTimeInterval]
    lappend Result -HoldTimer
    lappend Result $HoldTimer
    set KeepaliveTimer [stc::get $bgpRouter -KeepAliveInterval]
    lappend Result -KeepaliveTimer
    lappend Result $KeepaliveTimer
    set Active [stc::get $bgpRouter -Active]
    lappend Result -Active
    lappend Result $Active
    set State [stc::get $bgpRouter -RouterState]
    lappend Result -State
    lappend Result $State
    set PeerType [stc::get $bgpRouter -EiBgp]
    #puts "PeerType:$PeerType"
    lappend Result -PeerType
    lappend Result $PeerType
    lappend Result -Active
    lappend Result $Active
    set auth1 [stc::get $bgpRouter -children-BgpAuthenticationParams]
    
    set FlagMd5 [stc::get $auth1 -Authentication]
    
    if {$FlagMd5 == "MD5"} {
        set FlagMd5 true
        set Md5 [stc::get $auth1 -Password]
    } else {
        set FlagMd5 false
        set Md5 novalue
    }
    lappend Result -FlagMd5
    lappend Result $FlagMd5
    lappend Result -Md5
    lappend Result $Md5
    set ipv4if1 $m_hIpv4
    set TesterIp [stc::get $ipv4if1 -Address]
    lappend Result -TesterIp
    lappend Result $TesterIp
    set PrefixLen [stc::get $ipv4if1 -PrefixLength] 
    lappend Result -PrefixLen
    lappend Result $PrefixLen
    set GateWay [stc::get $ipv4if1 -Gateway]
    lappend Result -GateWay
    lappend Result $GateWay
    
    set glbgpcfg1 [stc::get $m_hProject -children-BgpGlobalConfig]
    set ConnectRetryCount [stc::get $glbgpcfg1 -ConnectionRetryCount]
    lappend Result -ConnectRetryCount
    lappend Result $ConnectRetryCount
    set ConnectRetryTimer [stc::get $glbgpcfg1 -ConnectionRetryInterval]
    lappend Result -ConnectRetryTimer
    lappend Result $ConnectRetryTimer
    set InterUpdateDelay  [stc::get $glbgpcfg1 -UpdateDelay]
    lappend Result -InterUpdateDelay
    lappend Result $InterUpdateDelay
    set RoutesPerUpdate   [stc::get $glbgpcfg1 -UpdateCount]
    lappend Result -RoutesPerUpdate
    lappend Result $RoutesPerUpdate
    if {$args == ""} {
        return $Result
    }
 
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveRouter"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetCapability
#Description: Config parameter related with Session according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetCapability {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetCapability"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of IPv4 
    set index [lsearch $args -ipv4] 
    if {$index != -1} {
        set IPv4 [lindex $args [expr $index + 1]]
    } else  {
        set IPv4 enable
    }
    set m_bgpCapList(IPv4) $IPv4
    set bgpcfg1 $m_hbgpRouter
    if {[string tolower $IPv4] =="enable" || [string tolower $IPv4] =="true" } {
        stc::config $bgpcfg1 -Afi 1
    }
    
    #Abstract the value of IPv6 
    set index [lsearch $args -ipv6] 
    if {$index != -1} {
        set IPv6 [lindex $args [expr $index + 1]]
    } else  {
        set IPv6 disable
    }    
    set m_bgpCapList(IPv6) $IPv6
    if {[string tolower $IPv6] =="enable" || [string tolower $IPv6] =="true" } {
        stc::config $bgpcfg1 -Afi 2
    }
    
    #Abstract the value of VPNv4 
    set index [lsearch $args -vpnv4] 
    if {$index != -1} {
        set VPNv4 [lindex $args [expr $index + 1]]
    } else  {
        set VPNv4 enable
    }    
    set m_bgpCapList(VPNv4) $VPNv4
    
    #Abstract the value of VPNv6 
    set index [lsearch $args -vpnv6] 
    if {$index != -1} {
        set VPNv6 [lindex $args [expr $index + 1]]
    } else  {
        set VPNv6 disable
    }
    set m_bgpCapList(VPNv6) $VPNv6
    
    #Abstract the value of LabeledIPv4 
    set index [lsearch $args -labeledipv4] 
    if {$index != -1} {
        set LabeledIPv4 [lindex $args [expr $index + 1]]
    } else  {
        set LabeledIPv4 enable
    }
    set m_bgpCapList(LabeledIPv4) $LabeledIPv4
    
    #Abstract the value of LabeledIPv6 
    set index [lsearch $args -labeledipv6] 
    if {$index != -1} {
        set LabeledIPv6 [lindex $args [expr $index + 1]]
    } else  {
        set LabeledIPv6 disable
    }
    set m_bgpCapList(LabeledIPv6) $LabeledIPv6
    
    #Abstract the value of IPv4Multicast 
    set index [lsearch $args -ipv4multicast] 
    if {$index != -1} {
        set IPv4Multicast [lindex $args [expr $index + 1]]
    } else  {
        set IPv4Multicast enable
    }
    set m_bgpCapList(IPv4Multicast) $IPv4Multicast
    
    #Abstract the value of IPv6Multicast 
    set index [lsearch $args -ipv6multicast] 
    if {$index != -1} {
        set IPv6Multicast [lindex $args [expr $index + 1]]
    } else  {
        set IPv6Multicast disable
    }
    set m_bgpCapList(IPv6Multicast) $IPv6Multicast
    
    debugPut "exit the proc of BgpV4Session::BgpV4SetCapability"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveCapability
#Description: Get configuration of parameter related with Session 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveCapability {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveCapability"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of IPv4 
    set index [lsearch $args -ipv4] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IPv4
    }
    set IPv4 $m_bgpCapList(IPv4)
    
    #Abstract the value of IPv6 
    set index [lsearch $args -ipv6] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IPv6        
    } 
    set IPv6 $m_bgpCapList(IPv6)
    
    #Abstract the value of VPNv4 
    set index [lsearch $args -vpnv4] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] VPNv4
    } 
    set VPNv4 $m_bgpCapList(VPNv4)
    
    #Abstract the value of VPNv6 
    set index [lsearch $args -vpnv6] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] VPNv6
    }
    set VPNv6 $m_bgpCapList(VPNv6)
    
    #Abstract the value of LabeledIPv4 
    set index [lsearch $args -labeledipv4] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LabeledIPv4
    }
    set LabeledIPv4 $m_bgpCapList(LabeledIPv4) 
    
    #Abstract the value of LabeledIPv6 
    set index [lsearch $args -labeledipv6] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LabeledIPv6
    }
    set LabeledIPv6 $m_bgpCapList(LabeledIPv6)
    
    #Abstract the value of IPv4Multicast 
    set index [lsearch $args -ipv4multicast] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IPv4Multicast
    }
    set IPv4Multicast $m_bgpCapList(IPv4Multicast)
    
    #Abstract the value of IPv6Multicast 
    set index [lsearch $args -ipv6multicast] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IPv6Multicast
    }
    set IPv6Multicast $m_bgpCapList(IPv6Multicast)
    
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveCapability"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4Enable
#Description: Enable BGP router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4Enable {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4Enable"
    set bgpRouter [stc::get $m_hRouter -children-BgpRouterConfig]
    stc::config $bgpRouter -Active TRUE  

    stc::apply 
    after 1000
      
    debugPut "exit the proc of BgpV4Session::BgpV4Enable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4Disable
#Description: Disable specified BGP router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4Disable {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4Disable"
        
    set bgpRouter [stc::get $m_hRouter -children-BgpRouterConfig]
    stc::config $bgpRouter -Active FALSE
    stc::apply
    set stat1 [stc::get $bgpRouter -RouterState]
    set stat2 [stc::get $bgpRouter -Active]
    #puts "test11---$stat1:$stat2"
        
    debugPut "exit the proc of BgpV4Session::BgpV4Disable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateRouteBlock
#Description: Create address block according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4CreateRouteBlock"
    
    set args [ConvertAttrPlusValueToLowerCase $args]
 
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set AddressFamily [lindex $args [expr $index + 1]]
    } else  {
        set AddressFamily ipv4
    }
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        set FirstRoute [lindex $args [expr $index + 1]]
    } else  {
        set FirstRoute 1.0.0.0
    }

    #判断是否是列表输入 add by Andy
    if {[llength $FirstRoute]>1} {
        set m_firstRouteListFlag TRUE
    } else {
        set m_firstRouteListFlag FALSE
    }
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    } else  {
        set PrefixLen 24
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        set RouteNum [lindex $args [expr $index + 1]]
    } else  {
        set RouteNum 1
    }
    
    #Abstract the value of Modifier 
    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set Modifier [lindex $args [expr $index + 1]]
    } else  {
        set Modifier 1
    }
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active enable
    }
    
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        set AS_SEQUENCE [lindex $args [expr $index + 1]]
    } else  {
        set AS_SEQUENCE yes
    }
    
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        set AS_SET [lindex $args [expr $index + 1]]
    } else  {
        set AS_SET no
    }
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        set CONFED_SEQUENCED [lindex $args [expr $index + 1]]
    } else  {
        set CONFED_SEQUENCED no
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        set CONFED_SET [lindex $args [expr $index + 1]]
    } else  {
        set CONFED_SET no
    }
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        set ORIGIN [lindex $args [expr $index + 1]]
    } else  {
        set ORIGIN INCOMPLETE
    }
    
    set ORIGIN [string map {0 EGP} $ORIGIN]
    set ORIGIN [string map {1 IGP} $ORIGIN]
    set ORIGIN [string map {2 INCOMPLETE} $ORIGIN]
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NEXTHOP [lindex $args [expr $index + 1]]
    } else {
        set NEXTHOP 1.0.0.1
    }
    
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        set MED [lindex $args [expr $index + 1]]
    } else  {
        set MED ""
    }
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        set AS_PATH [lindex $args [expr $index + 1]]
        regsub -all "," $AS_PATH " " AS_PATH
        set AS_PATH1 [lindex $AS_PATH 0]
        if {$AS_PATH1!=""} {
            set AsPathSegmentType [lindex $AS_PATH1 0] 
            switch $AsPathSegmentType {
                    1 {
                        set AS_SET  yes
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED no 
                        set CONFED_SET no
                    }
                    2 {
                        set AS_SET  no
                        set AS_SEQUENCE yes
                        set CONFED_SEQUENCED no 
                        set CONFED_SET no
                    }
                    3 {
                        set AS_SET  no
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED yes 
                        set CONFED_SET no
                    }
                    4 {
                        set AS_SET  no
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED no 
                        set CONFED_SET yes
                    }
                    default {
                        error "The AsPathSegmentType should be 1, 2 , 3 or 4.\n"
                    }
            }
        }
        if {[llength $AS_PATH1]>1} {
            foreach AS_PATH1 $AS_PATH {               
                for {set i 1} {$i< [llength $AS_PATH1]} { incr i} {
                    lappend AsPath [lindex $AS_PATH1 $i]
                }
            }
        } else {
             for {set i 1} {$i< [llength $AS_PATH]} { incr i} {
                    lappend AsPath [lindex $AS_PATH $i]
             }
        } 
    } 
    
    
    #提取参数LOCAL_PREF的值
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        set LOCAL_PREF [lindex $args [expr $index + 1]]
    } else {
        set LOCAL_PREF 100
    }
    
    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        set ATOMATIC_AGGREGATE [lindex $args [expr $index + 1]]
        set ATOMATIC_AGGREGATE [string toupper $ATOMATIC_AGGREGATE]
    } else  {
        set ATOMATIC_AGGREGATE FALSE
    }
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        set AGGREGATOR_AS [lindex $args [expr $index + 1]]
    } else  {
        set AGGREGATOR_AS ""
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        set AGGRGATOR_IPADDRESS [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        set ORIGINATOR_ID [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        set CLUSTER_LIST [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        set COMMUNITIES [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of FlagLabel 
    set index [lsearch $args -flaglabel] 
    if {$index != -1} {
        set Label [lindex $args [expr $index + 1]]
    } else  {
        set Label false
    }
    
    #Abstract the value of LabelMode 
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        set LabelMode [lindex $args [expr $index + 1]]
        set LabelMode [string toupper $LabelMode]
    } else  {
        set LabelMode FIXED
    }
    
    #Abstract the value of FlagAdvertise 
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
    } else  {
        set FlagAdvertise true
        set m_bgpAdverFlag $FlagAdvertise
    }
        
    set bgpcfg1 [stc::get  $m_hRouter -children-BgpRouterConfig]
    if {$AddressFamily == "ipv4"} {
        set bgpblock1 [stc::create BgpIpv4RouteConfig -under $bgpcfg1 -RouteSubAfi "UNICAST"]
        stc::config $bgpblock1 -Name $BlockName -AtomicAggregatePresent $ATOMATIC_AGGREGATE 
        if {[info exists AS_PATH]} {
            stc::config $bgpblock1 -AsPath $AsPath
        }
        if {[string tolower $Active] =="enable" ||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } elseif {[string tolower $Active] =="disable"||[string tolower $Active] =="false"} {
            #puts "1222222222222"
            stc::config $bgpblock1 -Active FALSE
        }
        set m_hBgpblock($BlockName) $bgpblock1
        set ipv4bk1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
        #判断是否是列表输入 add by Andy
        if {$m_firstRouteListFlag=="TRUE" } {
            stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount 1 \
                    -AddrIncrement 1 
        } else {
            stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount $RouteNum \
                    -AddrIncrement $Modifier
        }
                    

        set ::mainDefine::gPoolCfgBlock($BlockName) $ipv4bk1
       
        set ORIGIN [string toupper $ORIGIN]
        if {$ORIGIN=="IGP"} {
        
        } elseif {$ORIGIN =="EGP"} {
        
        } elseif {$ORIGIN =="INCOMPLETE"} {
            
        } else {
            error "The ORIGIN id $ORIGIN is invalid"
        }                 
        stc::config $bgpblock1  -Origin $ORIGIN 
                    
        if {[info exists CLUSTER_LIST]} {
            stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
        }  
        if {[info exists NEXTHOP]} {
            stc::config $bgpblock1 -NextHop $NEXTHOP
        }
        if {[info exists COMMUNITIES]} {
            stc::config $bgpblock1 -Community $COMMUNITIES 
        }
        if {[info exists LOCAL_PREF]} {
            stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
        }  
        if {[info exists ORIGINATOR_ID]} {
            stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
        }        
        if {$AGGREGATOR_AS !=""} {
            
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }    
        }
        if {$MED !=""} {
            stc::config $bgpblock1 -Med $MED
        }
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        } elseif {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        } elseif {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        } elseif {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }
        if {$Label =="true"} {
            stc::config $bgpblock1 -Label $LabelMode 
        } elseif {$Label =="false"} {
            stc::config $bgpblock1 -Label NONE
        }      
    } elseif {$AddressFamily == "ipv6"} {
        set bgpblock1 [stc::create BgpIpv6RouteConfig -under $bgpcfg1 -RouteSubAfi "UNICAST"]
        stc::config $bgpblock1 -Name $BlockName -AtomicAggregatePresent $ATOMATIC_AGGREGATE 
        if {[info exists AS_PATH]} {
            stc::config $bgpblock1 -AsPath $AS_PATH
        }
        if {[string tolower $Active] =="enable"||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } elseif {[string tolower $Active] =="disable"||[string tolower $Active] =="false"} {
            stc::config $bgpblock1 -Active FALSE
        }
        set m_hBgpblock($BlockName) $bgpblock1
        set ipv4bk1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
        #判断是否是列表输入 add by Andy
        if {$m_firstRouteListFlag=="TRUE" } {
            stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount 1 \
                    -AddrIncrement 1 
        } else {
            stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount $RouteNum \
                    -AddrIncrement $Modifier 
        }
        

        set ::mainDefine::gPoolCfgBlock($BlockName) $ipv4bk1
        
        set ORIGIN [string toupper $ORIGIN]
        if {$ORIGIN=="IGP"} {

        } elseif {$ORIGIN =="EGP"} {

        } elseif {$ORIGIN =="INCOMPLETE"} {
            
        } else {
            error "The ORIGIN id $ORIGIN is invalid"
        }                 
        stc::config $bgpblock1  -Origin $ORIGIN  
        if {[info exists CLUSTER_LIST]} {
            stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
        }  
        if {[info exists NEXTHOP]} {
            stc::config $bgpblock1 -NextHop $NEXTHOP
        }
        if {[info exists COMMUNITIES]} {
            stc::config $bgpblock1 -Community $COMMUNITIES 
        }
        if {[info exists LOCAL_PREF]} {
            stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
        }  
        if {[info exists ORIGINATOR_ID]} {
            stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
        } 
        if {$AGGREGATOR_AS !=""} {
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }
        }
        if {$MED !=""} {
            stc::config $bgpblock1 -Med $MED
        }
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        } elseif {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        } elseif {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        } elseif {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }
        if {$Label =="true"} {
            stc::config $bgpblock1 -Label $LabelMode 
        } elseif {$Label =="false"} {
            stc::config $bgpblock1 -Label NONE
        }      
    }
    if {$FlagAdvertise =="true"} {
       stc::perform BgpReadvertiseRoute -RouterList $m_hbgpRouter
    }
    debugPut "exit the proc of BgpV4Session::BgpV4CreateRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteRouteBlock
#Description: Delete routing block according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4DeleteRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set RouteBlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }

    if {[info exists m_hBgpblock($RouteBlockName)]} {
        set bgpblock1 $m_hBgpblock($RouteBlockName)
        if {$bgpblock1 !=""} {
            for {set i 0} {$i <[llength $bgpblock1]} {incr i} {
                stc::delete [lindex $bgpblock1 $i]
            } 
        }
    } else {
        error "RouteBlockName $RouteBlockName does not exist."
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4DeleteRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4ListRouteBlock
#Description: List routing block according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4ListRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4ListRouteBlock"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of BlockNameList 
    set index [lsearch $args -blocknamelist] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] BlockNameList
    } 
    set BlockNameList ""
    set bgpcfg1 [stc::get $m_hRouter -children-BgpRouterConfig]
    set bgpblock1 [stc::get $bgpcfg1 -children-BgpIpv4RouteConfig]
    #puts "bgpblock1:$bgpblock1"
    if {[info exists bgpblock1]} {
        if {$bgpblock1 !=""} {
            for {set i 0} {$i <[llength $bgpblock1]} {incr i} {
                lappend BlockNameList [stc::get [lindex $bgpblock1 $i] -Name]
                #puts "BlockNameList:$BlockNameList"
            }
        }
    }
    set bgpblock2 [stc::get $bgpcfg1 -children-BgpIpv6RouteConfig]
    #puts "bgpblock2:$bgpblock2"
    if {[info exists bgpblock2]} {
        if {$bgpblock2 !=""} {
            for {set i 0} {$i <[llength $bgpblock2]} {incr i} {
                lappend BlockNameList [stc::get [lindex $bgpblock2 $i] -Name]
            }
        }
    }
 
    debugPut "exit the proc of BgpV4Session::BgpV4ListRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetRouteBlock
#Description: Config BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set AddressFamily [lindex $args [expr $index + 1]]
    }
        
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else {
        error "Please specify BlockName parameter"
    }
    if {![info exists m_hBgpblock($BlockName)]} {
        error "BlockName $BlockName does not exist."
    }
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        set FirstRoute [lindex $args [expr $index + 1]] 

        #判断是否是列表输入 add by Andy
        if {[llength $FirstRoute]>1} {
            set m_firstRouteListFlag TRUE
        } else {
            set m_firstRouteListFlag FALSE
        }
    }
    
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        set FirstRoute [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        set RouteNum [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of RouteStep 
    set index [lsearch $args -routestep] 
    if {$index != -1} {
        set RouteStep [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NEXTHOP [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        set AS_PATH [lindex $args [expr $index + 1]]
        regsub -all "," $AS_PATH " " AS_PATH
        set AS_PATH1 [lindex $AS_PATH 0]
        if {$AS_PATH1!=""} {
            set AsPathSegmentType [lindex $AS_PATH1 0] 
            switch $AsPathSegmentType {
                    1 {
                        set AS_SET  yes
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED no 
                        set CONFED_SET no
                    }
                    2 {
                        set AS_SET  no
                        set AS_SEQUENCE yes
                        set CONFED_SEQUENCED no 
                        set CONFED_SET no
                    }
                    3 {
                        set AS_SET  no
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED yes 
                        set CONFED_SET no
                    }
                    4 {
                        set AS_SET  no
                        set AS_SEQUENCE no
                        set CONFED_SEQUENCED no 
                        set CONFED_SET yes
                    }
                    default {
                        error "The AsPathSegmentType should be 1, 2 , 3 or 4.\n"
                    }
            }
        }
        if {[llength $AS_PATH1]>1} {
            foreach AS_PATH1 $AS_PATH {               
                for {set i 1} {$i< [llength $AS_PATH1]} { incr i} {
                    lappend AsPath [lindex $AS_PATH1 $i]
                }
            }
        } else {
             for {set i 1} {$i< [llength $AS_PATH]} { incr i} {
                    lappend AsPath [lindex $AS_PATH $i]
             }
        } 
    }
   
    #Abstract the value of FlagLabel 
    set index [lsearch $args -flaglabel] 
    if {$index != -1} {
        set Label [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of LabelMode 
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        set LabelMode [lindex $args [expr $index + 1]]
    }
  
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        set AS_SEQUENCE [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        set AS_SET [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        set CONFED_SEQUENCED [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        set CONFED_SET [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        set ORIGIN [lindex $args [expr $index + 1]]
        set ORIGIN [string map {0 EGP} $ORIGIN]
        set ORIGIN [string map {1 IGP} $ORIGIN]
        set ORIGIN [string map {2 INCOMPLETE} $ORIGIN]
    }
   
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        set MED [lindex $args [expr $index + 1]]
    } else  {
        set MED ""
    }
    
    #Abstract the value of LOCAL_PREF 
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        set LOCAL_PREF [lindex $args [expr $index + 1]]
    }

    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        set ATOMATIC_AGGREGATE [lindex $args [expr $index + 1]]
        set ATOMATIC_AGGREGATE [string toupper $ATOMATIC_AGGREGATE]
    }
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        set AGGREGATOR_AS [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        set AGGRGATOR_IPADDRESS [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        set ORIGINATOR_ID [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        set CLUSTER_LIST [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        set COMMUNITIES [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of FlagAdvertise 
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
        set m_bgpAdverFlag $FlagAdvertise
    }

    set bgpblock1 $m_hBgpblock($BlockName)
    set AddressFamily [stc::get $m_hbgpRouter -IpVersion]
    set iFlag [string match *ipv4* $bgpblock1]
    if {$iFlag == 1} {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
    } else {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
    }
    if {[info exists ATOMATIC_AGGREGATE]} {
        stc::config $bgpblock1 -AtomicAggregatePresent $ATOMATIC_AGGREGATE
    }
    if {[info exists Active]} {
        if {[string tolower $Active] =="enable"||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } else {
            stc::config $bgpblock1 -Active FALSE
        } 
    }
    if {[info exists AsPath]} {
        stc::config $bgpblock1 -AsPath $AsPath
    }
    if {[info exists FirstRoute]} {
        stc::config $ipblock1 -StartIpList $FirstRoute
    }
    if {[info exists PrefixLen]} {
        stc::config $ipblock1 -PrefixLength $PrefixLen
    }
  
    if {$m_firstRouteListFlag=="TRUE" } {
        stc::config $ipblock1 -NetworkCount 1
    } else {
        if {[info exists RouteNum]} {
            stc::config $ipblock1 -NetworkCount $RouteNum
        }
    }
    if {[info exists RouteStep]} {
         stc::config $ipblock1 -AddrIncrement $RouteStep
    }
    if {[info exists ORIGIN]} {
        set ORIGIN [string toupper $ORIGIN]
        stc::config $bgpblock1 -Origin $ORIGIN
    }
    if {[info exists AS_SEQUENCE]} {
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        }
    }
    if {[info exists AS_SET]} {
        if {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        }
    }              
    if {[info exists CONFED_SEQUENCED]} {
        if {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        }
    }
    if {[info exists CONFED_SET]} {
        if {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }
    }
    if {[info exists CLUSTER_LIST]} {
        stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
    }
    if {[info exists ORIGINATOR_ID]} {
        stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
    }
    if {[info exists COMMUNITIES]} {
        stc::config $bgpblock1 -Community $COMMUNITIES
    }
    if {[info exists NEXTHOP]} {
        stc::config $bgpblock1 -NextHop $NEXTHOP
    }
    if {[info exists LOCAL_PREF]} {
        stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
    }
    if {[info exists AGGREGATOR_AS]} {
        if {$AGGREGATOR_AS !=""} {
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }        
        }
    }
    if {$MED !=""} {
        stc::config $bgpblock1 -Med $MED
    }
    if {[info exists Label]} {
        if {$Label =="true"} {
            if {[info exists LabelMode]} {
                stc::config $bgpblock1 -Label [string toupper $LabelMode]
            }
        } elseif {$Label =="false"} {
            stc::config $bgpblock1 -Label NONE
        }
    }
    if {[info exists FlagAdvertise]} {
        if {$FlagAdvertise =="true"} {
           stc::perform BgpReadvertiseRoute -RouterList $m_hbgpRouter
        }
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4SetRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveRouteBlock
#Description: Get routing information of BGP according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveRouteBlock"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AddressFamily
    }
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set BlockName parameter you want to get the routeBlock."
    } 
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FirstRoute
    } 
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] PrefixLen
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RouteNum
    } 
    
    #Abstract the value of RouteStep 
    set index [lsearch $args -routestep] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RouteStep
    } 
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NEXTHOP
    } 
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Active
    } 
    
    #Abstract the value of FlagLabel 
    set index [lsearch $args -flaglabel] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Label
    } 
    #Abstract the value of LabelMode 
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LabelMode
    } 
    
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_SEQUENCE
    }
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_SET
    } 
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CONFED_SEQUENCED
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CONFED_SET
    } 
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ORIGIN
    } 
    
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MED
    } 
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_PATH
    }
    
    #Abstract the value of LOCAL_PREF 
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LOCAL_PREF
    } 
    
    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ATOMATIC_AGGREGATE
    } 
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AGGREGATOR_AS
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AGGRGATOR_IPADDRESS
    } 
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ORIGINATOR_ID
    }
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CLUSTER_LIST
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] COMMUNITIES
    } 
    
    #Abstract the value of FlagAdvertise 
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FlagAdvertise
        set FlagAdvertise $m_bgpAdverFlag
    }
    
    if {![info exists m_hBgpblock($BlockName)]} {
        error "BlockName $BlockName does not exist."
    } else {
        set bgpblock1  $m_hBgpblock($BlockName)
        set Result ""
        set iFlag [string match *ipv4* $bgpblock1]
        set AddressFamily [stc::get $m_hbgpRouter -IpVersion ]
        lappend Result -AddressFamily
        lappend Result $AddressFamily
        if {$iFlag == 1} {
            set ipblock1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
        } else {
            set ipblock1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
        }
        set FirstRoute [stc::get $ipblock1 -StartIpList]
        lappend Result -FirstRoute
        lappend Result $FirstRoute
        set PrefixLen [stc::get $ipblock1 -PrefixLength]
        lappend Result -PrefixLen
        lappend Result $PrefixLen
        set RouteNum [stc::get $ipblock1 -NetworkCount]
        lappend Result -RouteNum
        lappend Result $RouteNum
        set RouteStep [stc::get $ipblock1 -AddrIncrement]
        lappend Result -RouteStep
        lappend Result $RouteStep
        set NEXTHOP [stc::get $bgpblock1 -NextHop]
        lappend Result -NEXTHOP
        lappend Result $NEXTHOP
        set Active [stc::get $bgpblock1 -Active]
        lappend Result -Active
        lappend Result $Active
        if {[stc::get $bgpblock1 -Label] == "NONE"} {
            set label false
            set LabelMode NONE
        } else {
            set label true
            set LabelMode [stc::get $bgpblock1 -Label]
        }
        lappend Result -label
        lappend Result $label
        lappend Result -LabelMode
        lappend Result $LabelMode
        if {[stc::get $bgpblock1 -AsPathSegmentType] == "SEQUENCE"} {
            set AS_SEQUENCE yes
            set AS_SET no
            set CONFED_SEQUENCED no
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "SET"} {
            set AS_SEQUENCE no
            set AS_SET yes
            set CONFED_SEQUENCED no
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "CONFED_SEQ"} {
            set AS_SEQUENCE no
            set AS_SET no
            set CONFED_SEQUENCED yes
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "CONFED_SET"} {
            set AS_SEQUENCE no
            set AS_SET no
            set CONFED_SEQUENCED no
            set CONFED_SET yes
        }
        lappend Result -AS_SEQUENCE
        lappend Result $AS_SEQUENCE
        lappend Result -AS_SET
        lappend Result $AS_SET
        lappend Result -CONFED_SEQUENCED
        lappend Result $CONFED_SEQUENCED
        lappend Result -CONFED_SET
        lappend Result $CONFED_SET
        set ORIGIN [stc::get $bgpblock1 -Origin]
        lappend Result -ORIGIN
        lappend Result $ORIGIN
        set MED [stc::get $bgpblock1 -Med]
        lappend Result -MED
        lappend Result $MED
        set LOCAL_PREF [stc::get $bgpblock1 -LocalPreference]
        lappend Result -LOCAL_PREF
        lappend Result $LOCAL_PREF
        set ATOMATIC_AGGREGATE [stc::get $bgpblock1 -AtomicAggregatePresent]
        lappend Result -ATOMATIC_AGGREGATE
        lappend Result $ATOMATIC_AGGREGATE
        set AGGREGATOR_AS [stc::get $bgpblock1 -AggregatorAs]
        lappend Result -AGGREGATOR_AS
        lappend Result $AGGREGATOR_AS
        set AGGRGATOR_IPADDRESS [stc::get $bgpblock1 -AggregatorIp]
        lappend Result -AGGRGATOR_IPADDRESS
        lappend Result $AGGRGATOR_IPADDRESS
        set CLUSTER_LIST [stc::get $bgpblock1 -ClusterIdList]
        lappend Result -CLUSTER_LIST
        lappend Result $CLUSTER_LIST
        set ORIGINATOR_ID [stc::get $bgpblock1 -OriginatorId]
        lappend Result -ORIGINATOR_ID
        lappend Result $ORIGINATOR_ID
        set COMMUNITIES [stc::get $bgpblock1 -Community]
        lappend Result -COMMUNITIES
        lappend Result $COMMUNITIES
        
        #added by yuanfen
        set BlockName [stc::get $bgpblock1 -Name]
        lappend Result -BlockName
        lappend Result $BlockName
        
        set AS_PATH [stc::get $bgpblock1 -AsPath]
        lappend Result -AS_PATH
        lappend Result $AS_PATH
    }            
    if {[llength $args] ==2} {
        return $Result
    }
   
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4AdvertiseRouteBlock
#Description: Advertise BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4AdvertiseRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4AdvertiseRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    stc::apply
    after 2000
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        set BlockName ""
        #error "Please specify BlockName parameter "
    }
    if {[info exists m_hBgpblock($BlockName)]} {
        #puts "m_hBgpblock($BlockName):$m_hBgpblock($BlockName)"
        #stc::perform ProtocolAdvertise -ProtocolList $m_hbgpRouter
        #stc::perform BgpWithdrawRoute -RouteList $m_hBgpblock($BlockName)
        after 2000
        stc::perform BgpReadvertiseRoute -RouterList $m_hbgpRouter
        #$m_hBgpblock($BlockName)
    } elseif {$BlockName == ""} {
        set routelist [stc::get $m_hbgpRouter -children-BgpIpv4RouteConfig]
        #puts "route:$routelist"
        foreach hBRoute $routelist {
            #stc::perform BgpWithdrawRoute -RouteList $hBRoute        
        }
        stc::perform BgpReadvertiseRoute -RouterList $m_hbgpRouter
        
    } else {
        error "The BlockName $BlockName does not exist."
    }
        
    debugPut "exit the proc of BgpV4Session::BgpV4AdvertiseRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4WithdrawRouteBlock
#Description: Withdraw BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4WithdrawRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4WithdrawRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    stc::apply
    after 2000
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }
    if {[info exists m_hBgpblock($BlockName)]} {
        stc::perform BgpWithdrawRoute -RouteList $m_hBgpblock($BlockName)
    } else {
        error "The BlockName $BlockName does not exist."
    }
       
    debugPut "exit the proc of BgpV4Session::BgpV4WithdrawRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4StartFlapRouteBlock
#Description: Start BGP Router oscillation according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4StartFlapRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4StartFlapRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }
    #Abstract the value of FlapNumber 
    set index [lsearch $args -flapnumber] 
    if {$index != -1} {
        set FlapNumber [lindex $args [expr $index + 1]]
    } else  {
        set FlapNumber 10
    }
    
    if {[info exists m_hBgpblock($BlockName)]} {
        set existing_sequencer [stc::get system1 -Children-Sequencer]
        if {$existing_sequencer == ""} { 
            set sequencer1 [stc::create Sequencer -under system1 -Name "BgpScheduler$m_routerName"]
        } else {
            set sequencer1 $existing_sequencer
        }

        set loop1 [stc::create SequencerLoopCommand -under $sequencer1 -ContinuousMode FALSE -IterationCount $FlapNumber]
        stc::perform SequencerClear
        stc::perform SequencerInsert -CommandList $loop1
        set adbgp1 [stc::create BgpReadvertiseRouteCommand -under $loop1 -RouterList $m_hbgpRouter]
        set wdbgp1 [stc::create BgpWithdrawRouteCommand -under $loop1 -RouteList $m_hBgpblock($BlockName)]
        if {$m_awdTime ==""} {
            set waitTime1 [stc::create WaitCommand -under $loop1 -WaitTime 3]
        } else {
            set waitTime1 [stc::create WaitCommand -under $loop1 -WaitTime $m_awdTime]
        }
        if {$m_wadTime ==""} {
            set waitTime2 [stc::create WaitCommand -under $loop1 -WaitTime 3]
        } else {
            set waitTime2 [stc::create WaitCommand -under $loop1 -WaitTime $m_wadTime]
        }
        stc::perform SequencerInsert -CommandList $adbgp1 -CommandParent $loop1
        stc::perform SequencerInsert -CommandList $waitTime1 -CommandParent $loop1
        stc::perform SequencerInsert -CommandList $wdbgp1 -CommandParent $loop1
        stc::perform SequencerInsert -CommandList $waitTime2 -CommandParent $loop1
        stc::perform SequencerStart 
    } else {
        error "BlockName $BlockName does not exist,please set another one."
    }
  
    debugPut "exit the proc of BgpV4Session::BgpV4StartFlapRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4StopFlapRouteBlock
#Description: Stop BGP Router oscillation
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4StopFlapRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4StopFlapRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }
    if {[info exists m_hBgpblock($BlockName)]} {
        stc::perform SequencerStop
    } else {
        error "BlockName $BlockName does not exist,please set another one."
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4StopFlapRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetFlapRouteBlock
#Description: Config BGP router oscillation time
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetFlapRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetFlapRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
       
    #Abstract the value of AWDTimer 
    set index [lsearch $args -awdtimer] 
    if {$index != -1} {
        set AWDTimer [lindex $args [expr $index + 1]]
        set AWDTimer [expr $AWDTimer / 1000]
        if {$AWDTimer == 0} {
             set AWDTimer 1
        }
    } else  {
        set AWDTimer 5
    }
    
    #Abstract the value of WADTimer 
    set index [lsearch $args -wdatimer] 
    if {$index != -1} {
        set WADTimer [lindex $args [expr $index + 1]]
        set WADTimer [expr $WADTimer / 1000]
        if {$WADTimer == 0} {
             set WADTimer 1
        }
    } else  {
        set WADTimer 5
    }
    set m_awdTime $AWDTimer
    set m_wadTime $WADTimer
        
    debugPut "exit the proc of BgpV4Session::BgpV4SetFlapRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveRouteStats
#Description: Get result of BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveRouteStats {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveRouteStats"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
   #Abstract the value of Duration 
    set index [lsearch $args -duration] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] BgpDuration
    } 
    set BgpDuration "nonsupport"
    
    #Abstract the value of NumRouteRefreshRecevied 
    set index [lsearch $args -numrouterefreshrecevied] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumRouteRefreshRecevied
    }
    
    #Abstract the value of NumRouteRefreshSent 
    set index [lsearch $args -numrouterefreshsent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumRouteRefreshSent
    }
    
    #Abstract the value of State 
    set index [lsearch $args -state] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] State
    }
    
    #Abstract the value of NumOpenReceived 
    set index [lsearch $args -numopenreceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumOpenReceived
    }
    
    #Abstract the value of NumOpenSent 
    set index [lsearch $args -numopensent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumOpenSent
    }
    
    #Abstract the value of NumKeepAlivesReceived 
    set index [lsearch $args -numkeepalivesreceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumKeepAlivesReceived
    }
    
    #Abstract the value of NumKeepAlivesSent 
    set index [lsearch $args -numkeepalivessent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumKeepAlivesSent
    }
    
    #Abstract the value of NumUpdateReceived 
    set index [lsearch $args -numupdatereceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumUpdateReceived
    }
    
    #Abstract the value of NumUpdeateSent 
    set index [lsearch $args -numupdeatesent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumUpdeateSent
    }
    
    #Abstract the value of NumNotificationReceived 
    set index [lsearch $args -numnotificationreceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumNotificationReceived
    }
    
    #Abstract the value of NumNotificationSent 
    set index [lsearch $args -numnotificationsent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumNotificationSent
    }
    
    #Abstract the value of NumWithdrawRouteReceived 
    set index [lsearch $args -numwithdrawroutereceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumWithdrawRouteReceived
    }
    
    #Abstract the value of NumWtihdrawRoutSent 
    set index [lsearch $args -numwtihdrawroutsent] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumWtihdrawRoutSent
    }
    
    #Abstract the value of NumNlriReceived 
    set index [lsearch $args -numnlrireceived] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumNlriReceived
    }
    set NumNlriReceived "nonsupport"
    
    #Abstract the value of NumNlriSend 
    set index [lsearch $args -numnlrisend] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumNlriSend
    }
    set NumNlriSend "nonsupport"
    
    #Abstract the value of NumTcpWindowClosed 
    set index [lsearch $args -numtcpwindowclosed] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumTcpWindowClosed
    }
    set NumTcpWindowClosed "nonsupport"
    
    #Abstract the value of DurationTcpWindowClosed 
    set index [lsearch $args -durationtcpwindowclosed] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] DurationTcpWindowClosed
    }
    set DurationTcpWindowClosed "nonsupport"
    
    #Abstract the value of LastStatistics 
    set index [lsearch $args -laststatistics] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LastStatistics
    }  

     set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_bgpRouterResultHandle ]
     }
     set bgpRouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $bgpRouterResultHandle  ]
     } err]} {
         return $errorCode
     }

    after 2000
    set result1 [stc::get $m_hbgpRouter -children-BgpRouterResults]
    set NumKeepAlivesSent [stc::get $result1 -TxKeepAliveCount]
    set NumKeepAlivesReceived [stc::get $result1 -RxKeepAliveCount]
    set NumNotificationSent  [stc::get $result1 -TxNotificationCount]
    set NumNotificationReceived  [stc::get $result1 -RxNotificationCount]
    set NumWtihdrawRoutSent [stc::get $result1 -TxWithdrawnRouteCount]
    set NumWithdrawRouteReceived [stc::get $result1 -RxWithdrawnRouteCount]
    set State [stc::get $result1 -ResultState]
    set NumRouteRefreshRecevied [stc::get $result1 -RxAdvertisedRouteCount]
    set NumRouteRefreshSent [stc::get $result1 -TxAdvertisedRouteCount]
    set NumOpenReceived [stc::get $result1 -RxOpenCount]
    set NumOpenSent [stc::get $result1 -TxOpenCount]
    set NumUpdeateSent [stc::get $result1 -TxAdvertisedUpdateCount]
    set NumUpdateReceived [stc::get $result1 -RxAdvertisedUpdateCount]
    set LastStatistics [stc::get $result1 -LastRxUpdateRouteCount]
    
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveRouteStats"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateMplsVpn
#Description: Create MPLS VPN according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateMplsVpn {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4CreateMplsVpn"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter."
    }
    if {[lsearch $m_VpnNameList $VpnName] !=-1} {
        error "The VpnName $VpnName existed,please set another one."    
    }
    
    set findFlag 0
    set vpnList [stc::get $m_hProject -Children-VpnIdGroup]
    foreach vpn $vpnList {
        set name [stc::get $vpn -Name]
        if {$name == $VpnName} {
             set findFlag 1
             set vpnid1 $vpn
             break
        }
    }
    
    if {$findFlag == 0} { 
        set vpnid1 [stc::create VpnIdGroup -under $m_hProject -Name $VpnName]
        set ::mainDefine::gVpnSiteList($VpnName) ""
    }
    
    set m_hVpngrp($VpnName) $vpnid1
    lappend m_VpnNameList $VpnName
    lappend m_vpnList $vpnid1
  
    #if {$m_hMpls == ""} {
    #    set mpls1 [stc::create MplsIf -under $m_hRouter -LabelResolver Bgp]
    #    set m_hMpls $mpls1
    #}
    debugPut "exit the proc of BgpV4Session::BgpV4CreateMplsVpn"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetMplsVpn
#Description: Config MPLS VPN according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetMplsVpn {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetMplsVpn"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter "
    }
    if {[lsearch $m_VpnNameList $VpnName] ==-1} {
        error "The VpnName $VpnName does not exist,please set another one."    
    }   
    
    #Abstract the value of RTType 
    set index [lsearch $args -rttype] 
    if {$index != -1} {
        set RTType [lindex $args [expr $index + 1]]
    } 
     
    #Abstract the value of RTExport 
    set index [lsearch $args -rtexport] 
    if {$index != -1} {
        set RTExport [lindex $args [expr $index + 1]]
    }    
    
    debugPut "exit the proc of BgpV4Session::BgpV4SetMplsVpn"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteMplsVpn
#Description: Delete MPLS VPN according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteMplsVpn {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4DeleteMplsVpn"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter "
    }
    if {[lsearch $m_VpnNameList $VpnName] ==-1} {
        error "The VpnName $VpnName does not exist,please set another one."    
    }
    
    set index [lsearch $m_vpnList $m_hVpngrp($VpnName)]
    set m_vpnList [lreplace $m_vpnList $index $index] 
    stc::delete $m_hVpngrp($VpnName)
  
    array unset m_hVpngrp $VpnName
    
    set index [lsearch $m_VpnNameList $VpnName]
    set m_VpnNameList [lreplace $m_VpnNameList $index $index]

    debugPut "exit the proc of BgpV4Session::BgpV4DeleteMplsVpn"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateMplsVpnSite
#Description: Create MPLS Vpn site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateMplsVpnSite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4CreateMplsVpnSite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    
    #Abstract the value of peIpv4Address 
    set index [lsearch $args -peipv4address] 
    if {$index != -1} {
        set peIpv4Address [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify peIpv4Address parameter "
    }
    
    #Abstract the value of peIpv4PrefixLength 
    set index [lsearch $args -peipv4prefixlength] 
    if {$index != -1} {
        set peIpv4PrefixLength [lindex $args [expr $index + 1]]
    } else  {
        set peIpv4PrefixLength 32
    }
    
    # 将VpnNameList修改为VpnName
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    }

    #Abstract the value of FlagOverride 
    set index [lsearch $args -flagoverride] 
    if {$index != -1} {
        set FlagOverride [lindex $args [expr $index + 1]]
    } else  {
        set FlagOverride false
    }

    #Abstract the value of RouteTarget 
    set index [lsearch $args -routetarget] 
    if {$index != -1} {
        set RouteTarget [lindex $args [expr $index + 1]]
    } else {
        set RouteTarget 100:1
    }
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }

    #Abstract the value of RTType 
    set index [lsearch $args -rttype] 
    if {$index != -1} {
        set RTType [lindex $args [expr $index + 1]]
    } else  {
        set RTType AS
    }
    
    #Abstract the value of RD 
    set index [lsearch $args -rd] 
    if {$index != -1} {
        set RD [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify RD parameter "
    }
    
    #Abstract the value of RTImport 
    set index [lsearch $args -rtimport] 
    if {$index != -1} {
        set RTImport [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify RTImport parameter "
    }
    
    #记录RT,RD全局变量
    set m_vpnRD($VpnSiteName) $RD
    set m_vpnRT($VpnSiteName) $RTImport
    
    set m_SiteToVpnName($VpnSiteName) $VpnName
	set m_peIPv4Address($VpnSiteName) $peIpv4Address
    
    set vpnsite1 [stc::create VpnSiteInfoRfc2547 -under $m_hProject -Name $VpnSiteName] 
    stc::config $vpnsite1 -PeIpv4Addr $peIpv4Address -PeIpv4PrefixLength $peIpv4PrefixLength    

    set m_hVpnSite($VpnSiteName) $vpnsite1
    
    # 将vpnsite1添加到全局变量vpnsitelist中
    if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $vpnsite1] == -1} {
        lappend ::mainDefine::gVpnSiteList($VpnName) $vpnsite1
    }
    
    #stc::config $m_hVpngrp($VpnName) -MemberOfVpnIdGroup-targets $::mainDefine::gVpnSiteList($VpnName)

    lappend m_vpnSiteVpnList $VpnSiteName

    if {$FlagOverride =="true"} {
        stc::config $vpnsite1 -RouteDistinguisher $RouteTarget
    } else {
        stc::config $vpnsite1 -RouteDistinguisher $RD
    }
            
    debugPut "exit the proc of BgpV4Session::BgpV4CreateMplsVpnSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateVpnToSite
#Description: Add VPN to Site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateVpnToSite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4CreateVpnToSite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    
    #Abstract the value of VPNname 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter "
    }
    
    set m_SiteToVpnName($VpnSiteName) $VpnName
    if {[info exists m_hVpnSite($VpnSiteName)]} {
        if {[info exists m_hVpngrp($VpnName)]} {
            if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $m_hVpnSite($VpnSiteName)] == -1} {
                lappend ::mainDefine::gVpnSiteList($VpnName) $m_hVpnSite($VpnSiteName)
                #set m_SiteToVpnName(VpnSiteName) $VpnName
            }
            set m_SiteToVpnName($VpnSiteName) $VpnName
            stc::config $m_hVpngrp($VpnName) -MemberOfVpnIdGroup-targets "$::mainDefine::gVpnSiteList($VpnName)"
            #lappend m_vpnSiteVpnList($VpnSiteName) $VpnName
        } else {
            error "VpnName $VpnName you set does not exist."
        }  
    } else {
        error "VpnSiteName $VpnSiteName you set does not exist."
    }  
    
    debugPut "exit the proc of BgpV4Session::BgpV4CreateVpnToSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteVpnFromSite
#Description: Delete relation of Vpn and Site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteVpnFromSite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4DeleteVpnFromSite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    
    #Abstract the value of VPNname 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter "
    }  
    set siteIndex [lsearch $::mainDefine::gVpnSiteList($VpnName) $m_hVpnSite($VpnSiteName)] 
    if {$siteIndex != -1} {
       set ::mainDefine::gVpnSiteList($VpnName) [lreplace $::mainDefine::gVpnSiteList($VpnName) $siteIndex $siteIndex]
    }
    stc::config $m_hVpngrp($VpnName) -MemberOfVpnIdGroup-targets "$::mainDefine::gVpnSiteList($VpnName)"    
    #set index [lsearch $m_vpnSiteVpnList($VpnSiteName) $VpnName]
    #if {$index !=-1} {
        #set m_vpnSiteVpnList($VpnSiteName) [lreplace $m_vpnSiteVpnList($VpnSiteName) $index $index]
            
    #}
    debugPut "exit the proc of BgpV4Session::BgpV4DeleteVpnFromSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetMplsVpnSite
#Description: Config BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetMplsVpnSite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetMplsVpnSite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    
    #Abstract the value of VpnNameList 
    set index [lsearch $args -vpnnamelist] 
    if {$index != -1} {
        set VpnNameList [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of RouteTarget 
    set index [lsearch $args -routetarget] 
    if {$index != -1} {
        set RouteTarget [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of FlagOverride 
    set index [lsearch $args -flagoverride] 
    if {$index != -1} {
        set FlagOverride [lindex $args [expr $index + 1]]
    } 
      
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }
    
    set vpnsite1 $m_hVpnSite($VpnSiteName)
     
    if {[info exists VpnNameList]} {
        for {set i 0} {$i <[llength $VpnNameList]} {incr i} {
            set VpnName [lindex $VpnNameList $i]
            if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $vpnsite1] == -1} {
                lappend ::mainDefine::gVpnSiteList($VpnName) $vpnsite1
            }
            stc::config $m_hVpngrp([lindex $VpnNameList $i]) -MemberOfVpnIdGroup-targets "$::mainDefine::gVpnSiteList($VpnName)"
        }
        
        #set m_vpnSiteVpnList($VpnSiteName) $VpnNameList
    }
    if  {[info exist FlagOverride]} {
        if {$FlagOverride =="true" && [info exist RouteTarget]} {
            stc::config $vpnsite1 -RouteDistinguisher $RouteTarget
        } 
    }
   
    debugPut "exit the proc of BgpV4Session::BgpV4SetMplsVpnSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4ListMplsVpnSite
#Description: List current Vpn site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4ListMplsVpnSite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4ListMplsVpnSite"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        upvar  [lindex $args1 [expr $index + 1]] VpnSiteName
    } 
    
    #Abstract the value of VPNNameList 
    set index [lsearch $args -vpnnamelist] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] VPNNameList
    } 

    for {set i 0} {$i <[array size m_hVpngrp]} {incr i 2} {
        set VPNNameList [lindex [array get m_hVpngrp] $i]
    }
    for {set i 0} {$i <[array size m_hVpnSite]} {incr i 2} {
        set VpnSiteName [lindex [array get m_hVpnSite] $i]
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4ListMplsVpnSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteMplsVpnSite
#Description: Config BGP router according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteMplsVpnSite {args} {
   
    debugPut "enter the proc of BgpV4Session::DeleteMplsVpnSite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    # 将VpnNameList修改为VpnName
    #提取参数VpnName 的值
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter "
    }
    
    if {[info exists m_hVpnSite($VpnSiteName)]} {
        if {$m_hVpnSite($VpnSiteName) !=""} {
            stc::delete $m_hVpnSite($VpnSiteName)             
            set siteIndex [lsearch $::mainDefine::gVpnSiteList($VpnName) $m_hVpnSite($VpnSiteName)] 
            if {$siteIndex != -1} {
                set ::mainDefine::gVpnSiteList($VpnName) [lreplace $::mainDefine::gVpnSiteList($VpnName) $siteIndex $siteIndex]
            }
            array unset m_hVpnSite $VpnSiteName
        }
    } 
    
    debugPut "exit the proc of BgpV4Session::BgpV4DeleteMplsVpnSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateVpnRouteBlock
#Description: Config BGP Vpn block router according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateVpnRouteBlock {args} {
 
    debugPut "enter the proc of BgpV4Session::BgpV4CreateVpnRouteBlock"
    
    set args [ConvertAttrPlusValueToLowerCase $args]
 
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify BlockName parameter "
    }
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set AddressFamily [lindex $args [expr $index + 1]]
    } else  {
        set AddressFamily ipv4
    }
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        set FirstRoute [lindex $args [expr $index + 1]]
    } else  {
        set FirstRoute 2.1.1.0
    }
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    } else  {
        set PrefixLen 24
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        set RouteNum [lindex $args [expr $index + 1]]
    } else  {
        set RouteNum 1
    }
    
    #Abstract the value of Modifier 
    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set Modifier [lindex $args [expr $index + 1]]
    } else  {
        set Modifier 1
    }
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active enable
    }
    
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        set AS_SEQUENCE [lindex $args [expr $index + 1]]
    } else  {
        set AS_SEQUENCE yes
    }
    
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        set AS_SET [lindex $args [expr $index + 1]]
    } else  {
        set AS_SET no
    }
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        set CONFED_SEQUENCED [lindex $args [expr $index + 1]]
    } else  {
        set CONFED_SEQUENCED no
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        set CONFED_SET [lindex $args [expr $index + 1]]
    } else  {
        set CONFED_SET no
    }
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        set ORIGIN [lindex $args [expr $index + 1]]
    } else  {
        set ORIGIN INCOMPLETE
    }
    set ORIGIN [string map {0 EGP} $ORIGIN]
    set ORIGIN [string map {1 IGP} $ORIGIN]
    set ORIGIN [string map {2 INCOMPLETE} $ORIGIN]
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NEXTHOP [lindex $args [expr $index + 1]]
    } else {
        set NEXTHOP 1.1.1.1
    }
    
    #Abstract the value of LOCALNEXTHOP 
    set index [lsearch $args -localnexthop] 
    if {$index != -1} {
        set LOCALNEXTHOP [lindex $args [expr $index + 1]]
    } else {
        set LOCALNEXTHOP fe80::2
    }
    
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        set MED [lindex $args [expr $index + 1]]
    } else  {
        set MED ""
    }
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        set AS_PATH [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of LOCAL_PREF 
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        set LOCAL_PREF [lindex $args [expr $index + 1]]
    } else {
        set LOCAL_PREF 100
    }
    
    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        set ATOMATIC_AGGREGATE [lindex $args [expr $index + 1]]
        set ATOMATIC_AGGREGATE [string toupper $ATOMATIC_AGGREGATE]
    } else  {
        set ATOMATIC_AGGREGATE FALSE
    }
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        set AGGREGATOR_AS [lindex $args [expr $index + 1]]
    } else  {
        set AGGREGATOR_AS ""
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        set AGGRGATOR_IPADDRESS [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        set ORIGINATOR_ID [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        set CLUSTER_LIST [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        set COMMUNITIES [lindex $args [expr $index + 1]]
    } 
        
    set bgpcfg1 [stc::get  $m_hRouter -children-BgpRouterConfig]
    if {$AddressFamily == "ipv4"} {
        set bgpblock1 [stc::create BgpIpv4RouteConfig -under $bgpcfg1 ]
        stc::config $bgpblock1 -RouteSubAfi "VPN"
        stc::config $bgpblock1 -Name $BlockName -AtomicAggregatePresent $ATOMATIC_AGGREGATE 
        if {[info exists AS_PATH]} {
            stc::config $bgpblock1 -AsPath $AS_PATH
        }
        if {[string tolower $Active] =="enable"||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } elseif {[string tolower $Active] =="disable"||[string tolower $Active] =="false"} {
            stc::config $bgpblock1 -Active FALSE
        }
        set m_hBgpblock($BlockName) $bgpblock1
        set ipv4bk1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
        set ::mainDefine::gIpv4NetworkBlock($BlockName) $ipv4bk1
        set ::mainDefine::gPoolCfgBlock($BlockName) $ipv4bk1
        stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount $RouteNum \
                    -AddrIncrement $Modifier 
        set ORIGIN [string toupper $ORIGIN]
        if {$ORIGIN !="IGP" && $ORIGIN !="EGP" && $ORIGIN !="INCOMPLETE"} {
            error "The ORIGIN id $ORIGIN is invalid"
        }                  
        stc::config $bgpblock1  -Origin $ORIGIN  
        if {[info exists CLUSTER_LIST]} {
            stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
        }  
        if {[info exists NEXTHOP]} {
            stc::config $bgpblock1 -NextHop $NEXTHOP
        }
        if {[info exists COMMUNITIES]} {
            stc::config $bgpblock1 -Community $COMMUNITIES 
        }
        if {[info exists LOCAL_PREF]} {
            stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
        }  
        if {[info exists ORIGINATOR_ID]} {
            stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
        } 
        if {$AGGREGATOR_AS !=""} {
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }
        }
        if {$MED !=""} {
            stc::config $bgpblock1 -Med $MED
        }
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        } elseif {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        } elseif {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        } elseif {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }
          
    } elseif {$AddressFamily == "ipv6"} {
        set bgpblock1 [stc::create BgpIpv6RouteConfig -under $bgpcfg1 ]
        stc::config $bgpblock1 -RouteSubAfi "VPN"
        stc::config $bgpblock1 -Name $BlockName -AtomicAggregatePresent $ATOMATIC_AGGREGATE 
        if {[info exists AS_PATH]} {
            stc::config $bgpblock1 -AsPath $AS_PATH
        }
        if {[string tolower $Active] =="enable"||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } elseif {[string tolower $Active] =="disable"||[string tolower $Active] =="false"} {
            stc::config $bgpblock1 -Active FALSE
        }
        set m_hBgpblock($BlockName) $bgpblock1
        set ipv4bk1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
        set ::mainDefine::gPoolCfgBlock($BlockName) $ipv4bk1
        stc::config $ipv4bk1 -StartIpList $FirstRoute -PrefixLength $PrefixLen -NetworkCount $RouteNum \
                    -AddrIncrement $Modifier 
        set ORIGIN [string toupper $ORIGIN]
        if {$ORIGIN !="IGP" && $ORIGIN !="EGP" && $ORIGIN !="INCOMPLETE"} {
            error "The ORIGIN id $ORIGIN is invalid"
        }                  
        stc::config $bgpblock1  -Origin $ORIGIN  
        if {[info exists CLUSTER_LIST]} {
            stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
        }  
        if {[info exists NEXTHOP]} {
            stc::config $bgpblock1 -NextHop $NEXTHOP
        }
        if {[info exists LOCALNEXTHOP]} {
            stc::config $bgpblock1 -LocalNextHop $LOCALNEXTHOP
        }
        if {[info exists COMMUNITIES]} {
            stc::config $bgpblock1 -Community $COMMUNITIES 
        }
        if {[info exists LOCAL_PREF]} {
            stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
        }  
        if {[info exists ORIGINATOR_ID]} {
            stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
        } 
        if {$AGGREGATOR_AS !=""} {
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }
        }
        if {$MED !=""} {
            stc::config $bgpblock1 -Med $MED
        }
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        } elseif {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        } elseif {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        } elseif {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }         
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4CreateVpnRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteVpnRouteBlock
#Description: Delete Vpn Route block according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteVpnRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4DeleteVpnRouteBlock"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set RouteBlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify RouteBlockName parameter "
    }
    if {[info exists m_hBgpblock($RouteBlockName)]} {
        stc::delete $m_hBgpblock($RouteBlockName)
        array unset m_hBgpblock $RouteBlockName
    } else {
        error "The BlockName $BlockName does not exist."
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4DeleteVpnRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4SetVpnRouteBlock
#Description: Config MPLS vpn block router according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4SetVpnRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetVpnRouteBlock"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
     #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set AddressFamily [lindex $args [expr $index + 1]]
    }
        
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set RouteBlockName [lindex $args [expr $index + 1]]
    } else {
        error "Please specify RouteBlockName parameter"
    }
    if {![info exists m_hBgpblock($RouteBlockName)]} {
        error "RouteBlockName $RouteBlockName does not exist."
    }
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        set FirstRoute [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        set RouteNum [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of RouteStep 
    set index [lsearch $args -routestep] 
    if {$index != -1} {
        set RouteStep [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NEXTHOP [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of LOCALNEXTHOP 
    set index [lsearch $args -localnexthop] 
    if {$index != -1} {
        set LOCALNEXTHOP [lindex $args [expr $index + 1]]
    } 
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        set AS_PATH [lindex $args [expr $index + 1]]
    }
  
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        set AS_SEQUENCE [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        set AS_SET [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        set CONFED_SEQUENCED [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        set CONFED_SET [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        set ORIGIN [lindex $args [expr $index + 1]]
        set ORIGIN [string map {0 EGP} $ORIGIN]
        set ORIGIN [string map {1 IGP} $ORIGIN]
        set ORIGIN [string map {2 INCOMPLETE} $ORIGIN]
    }
 
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        set MED [lindex $args [expr $index + 1]]
    } else  {
        set MED ""
    }
    
    #Abstract the value of LOCAL_PREF 
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        set LOCAL_PREF [lindex $args [expr $index + 1]]
    }

    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        set ATOMATIC_AGGREGATE [lindex $args [expr $index + 1]]
        set ATOMATIC_AGGREGATE [string toupper $ATOMATIC_AGGREGATE]
    }
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        set AGGREGATOR_AS [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        set AGGRGATOR_IPADDRESS [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        set ORIGINATOR_ID [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        set CLUSTER_LIST [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        set COMMUNITIES [lindex $args [expr $index + 1]]
    }

    set bgpblock1 $m_hBgpblock($RouteBlockName)
    set AddressFamily [stc::get $m_hbgpRouter -IpVersion]
    set iFlag [string match *ipv4* $bgpblock1]
    if {$iFlag == 1} {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
    } else {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
    }
    if {[info exists ATOMATIC_AGGREGATE]} {
        stc::config $bgpblock1 -AtomicAggregatePresent $ATOMATIC_AGGREGATE
    }
    if {[info exists Active]} {
        if {[string tolower $Active] =="enable"||[string tolower $Active] =="true"} {
            stc::config $bgpblock1 -Active TRUE
        } else {
            stc::config $bgpblock1 -Active FALSE
        } 
    }
    if {[info exists AS_PATH]} {
        stc::config $bgpblock1 -AsPath $AS_PATH
    }
    if {[info exists FirstRoute]} {
        stc::config $ipblock1 -StartIpList $FirstRoute

    }
    if {[info exists PrefixLen]} {
        stc::config $ipblock1 -PrefixLength $PrefixLen
    }
    if {[info exists RouteNum]} {
        stc::config $ipblock1 -NetworkCount $RouteNum
    }
    if {[info exists RouteStep]} {
        stc::config $ipblock1 -AddrIncrement $RouteStep
    }
    if {[info exists ORIGIN]} {
        set ORIGIN [string toupper $ORIGIN]
        if {$ORIGIN !="IGP" && $ORIGIN !="EGP" && $ORIGIN !="INCOMPLETE"} {
            error "The ORIGIN id $ORIGIN is invalid"
        }
        stc::config $bgpblock1 -Origin $ORIGIN 
    }
    if {[info exists AS_SEQUENCE]} {
        if {$AS_SEQUENCE == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SEQUENCE
        }
    }
    if {[info exists AS_SET]} {
        if {$AS_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType SET
        }
    }              
    if {[info exists CONFED_SEQUENCED]} {
        if {$CONFED_SEQUENCED == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SEQ
        }
    }
    if {[info exists CONFED_SET]} {
        if {$CONFED_SET == "yes"} {
            stc::config $bgpblock1 -AsPathSegmentType CONFED_SET
        }
    }
    if {[info exists CLUSTER_LIST]} {
        stc::config $bgpblock1 -ClusterIdList $CLUSTER_LIST
    }
    if {[info exists ORIGINATOR_ID]} {
        stc::config $bgpblock1 -OriginatorId $ORIGINATOR_ID
    }
    if {[info exists COMMUNITIES]} {
        stc::config $bgpblock1 -Community $COMMUNITIES
    }
    if {[info exists NEXTHOP]} {
        stc::config $bgpblock1 -NextHop $NEXTHOP
    }
    if {[info exists LOCALNEXTHOP]} {
        stc::config $bgpblock1 -LocalNextHop $LOCALNEXTHOP
    }
    if {[info exists LOCAL_PREF]} {
        stc::config $bgpblock1 -LocalPreference $LOCAL_PREF
    }
    if {[info exists AGGREGATOR_AS]} {
        if {$AGGREGATOR_AS !=""} {
            stc::config $bgpblock1 -AggregatorAs $AGGREGATOR_AS 
            if {[info exists AGGRGATOR_IPADDRESS]} {
                stc::config $bgpblock1 -AggregatorIp $AGGRGATOR_IPADDRESS
            }
        }
    }
    if {$MED !=""} {
        stc::config $bgpblock1 -Med $MED
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4SetVpnRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveVpnRouteBlock
#Description: Get Vpn BGP routing information according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveVpnRouteBlock {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveVpnRouteBlock"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AddressFamily
    }
    
    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set BlockName parameter you want to get the routeBlock."
    } 
    
    #Abstract the value of FirstRoute 
    set index [lsearch $args -firstroute] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FirstRoute
    } 
    
    #Abstract the value of PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] PrefixLen
    }
    
    #Abstract the value of RouteNum 
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RouteNum
    } 
    
    #Abstract the value of RouteStep 
    set index [lsearch $args -routestep] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RouteStep
    } 
    
    #Abstract the value of NEXTHOP 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NEXTHOP
    } 
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Active
    } 
    
    #Abstract the value of AS_SEQUENCE 
    set index [lsearch $args -as_sequence] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_SEQUENCE
    }
    #Abstract the value of AS_SET 
    set index [lsearch $args -as_set] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_SET
    } 
    
    #Abstract the value of Confed_Sequence 
    set index [lsearch $args -confed_sequence] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CONFED_SEQUENCED
    }
    
    #Abstract the value of CONFED_SET 
    set index [lsearch $args -confed_set] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CONFED_SET
    } 
    
    #Abstract the value of ORIGIN 
    set index [lsearch $args -origin] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ORIGIN
    } 
     
    #Abstract the value of MED 
    set index [lsearch $args -med] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MED
    } 
    
    #Abstract the value of AS_PATH 
    set index [lsearch $args -as_path] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AS_PATH
    }
    
    #Abstract the value of LOCAL_PREF 
    set index [lsearch $args -local_pref] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LOCAL_PREF
    } 
    
    #Abstract the value of FlagAtomaticAggregate 
    set index [lsearch $args -flagatomaticaggregate] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ATOMATIC_AGGREGATE
    } 
    
    #Abstract the value of AGGREGATOR_AS 
    set index [lsearch $args -aggregator_as] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AGGREGATOR_AS
    }
    
    #Abstract the value of AGGRGATOR_IPADDRESS 
    set index [lsearch $args -aggrgator_ipaddress] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AGGRGATOR_IPADDRESS
    } 
    
    #Abstract the value of ORIGINATOR_ID 
    set index [lsearch $args -originator_id] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ORIGINATOR_ID
    }
    
    #Abstract the value of CLUSTER_LIST 
    set index [lsearch $args -cluster_list] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] CLUSTER_LIST
    }
    
    #Abstract the value of COMMUNITIES 
    set index [lsearch $args -communities] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] COMMUNITIES
    } 
   
    if {![info exists m_hBgpblock($BlockName)]} {
        error "BlockName $BlockName does not exist."
    } else {
        set bgpblock1  $m_hBgpblock($BlockName) 
        set Result ""
        set AddressFamily [stc::get $m_hbgpRouter -IpVersion ]
        set iFlag [string match *ipv4* $bgpblock1]
        lappend Result -AddressFamily
        lappend Result $AddressFamily
        if {$iFlag == 1} {
            set ipblock1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
        } else {
            set ipblock1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
        }
        set FirstRoute [stc::get $ipblock1 -StartIpList]
        lappend Result -FirstRoute
        lappend Result $FirstRoute
        set PrefixLen [stc::get $ipblock1 -PrefixLength]
        lappend Result -PrefixLen
        lappend Result $PrefixLen
        set RouteNum [stc::get $ipblock1 -NetworkCount]
        lappend Result -RouteNum
        lappend Result $RouteNum
        set RouteStep [stc::get $ipblock1 -AddrIncrement]
        lappend Result -RouteStep
        lappend Result $RouteStep
        set NEXTHOP [stc::get $bgpblock1 -NextHop]
        lappend Result -NEXTHOP
        lappend Result $NEXTHOP
        set Active [stc::get $bgpblock1 -Active]
        lappend Result -Active
        lappend Result $Active
       
        if {[stc::get $bgpblock1 -AsPathSegmentType] == "SEQUENCE"} {
            set AS_SEQUENCE yes
            set AS_SET no
            set CONFED_SEQUENCED no
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "SET"} {
            set AS_SEQUENCE no
            set AS_SET yes
            set CONFED_SEQUENCED no
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "CONFED_SEQ"} {
            set AS_SEQUENCE no
            set AS_SET no
            set CONFED_SEQUENCED yes
            set CONFED_SET no
        } elseif {[stc::get $bgpblock1 -AsPathSegmentType] == "CONFED_SET"} {
            set AS_SEQUENCE no
            set AS_SET no
            set CONFED_SEQUENCED no
            set CONFED_SET yes
        }
        lappend Result -AS_SEQUENCE
        lappend Result $AS_SEQUENCE
        lappend Result -AS_SET
        lappend Result $AS_SET
        lappend Result -CONFED_SEQUENCED
        lappend Result $CONFED_SEQUENCED
        lappend Result -CONFED_SET
        lappend Result $CONFED_SET
        set ORIGIN [stc::get $bgpblock1 -Origin]

        lappend Result -ORIGIN
        lappend Result $ORIGIN
        set MED [stc::get $bgpblock1 -Med]
        lappend Result -MED
        lappend Result $MED
        set LOCAL_PREF [stc::get $bgpblock1 -LocalPreference]
        lappend Result -LOCAL_PREF
        lappend Result $LOCAL_PREF
        set ATOMATIC_AGGREGATE [stc::get $bgpblock1 -AtomicAggregatePresent]
        lappend Result -ATOMATIC_AGGREGATE
        lappend Result $ATOMATIC_AGGREGATE
        set AGGREGATOR_AS [stc::get $bgpblock1 -AggregatorAs]
        lappend Result -AGGREGATOR_AS
        lappend Result $AGGREGATOR_AS
        set AGGRGATOR_IPADDRESS [stc::get $bgpblock1 -AggregatorIp]
        lappend Result -AGGRGATOR_IPADDRESS
        lappend Result $AGGRGATOR_IPADDRESS
        set CLUSTER_LIST [stc::get $bgpblock1 -ClusterIdList]
        lappend Result -CLUSTER_LIST
        lappend Result $CLUSTER_LIST
        set ORIGINATOR_ID [stc::get $bgpblock1 -OriginatorId]
        lappend Result -ORIGINATOR_ID
        lappend Result $ORIGINATOR_ID
        set COMMUNITIES [stc::get $bgpblock1 -Community]
        lappend Result -COMMUNITIES
        lappend Result $COMMUNITIES
    }            
    if {[llength $args] ==2} {
        puts $Result
    }     
    
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveVpnRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4CreateRouteBlockToVPN
#Description: Create relation of BGP router and VPN according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4CreateRouteBlockToVPN {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4CreateRouteBlockToVPN"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]

    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set RouteBlockName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set BlockName parameter you want to create the routeBlock."
    } 
    
    if {![info exists m_hBgpblock($RouteBlockName)]} {
        error "RouteBlockName $RouteBlockName does not exist."
    }
    

    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set VPNSiteName parameter you want to create the routeBlock."
    }
         
    if {[lsearch $m_vpnSiteVpnList $VpnSiteName] ==-1} {
        error "The VpnSiteName $VpnSiteName does not exist,please set another one."    
    }   
    
    if {$m_hMpls == ""} {
       set mpls1 [stc::create MplsIf -under $m_hRouter -LabelResolver Bgp -IsRange "FALSE"]
	   #puts "bgpmplsif:$mpls1"
       set m_hMpls $mpls1
    }

    stc::config $m_hbgpRouter -ResolvesInterface-targets $m_hMpls
    set bgpblock1 $m_hBgpblock($RouteBlockName)
    
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        set LabelMode [lindex $args [expr $index + 1]] 
    } else {
        set LabelMode FIXED        
    }
    if {[string tolower $LabelMode] !="fixed"} {
        set LabelMode INCREMENTAL
    }
    
    #Abstract the value of AddressFamily 
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set AddressFamily [lindex $args [expr $index + 1]]
    } else  {
        set AddressFamily ipv4
    }
    
   
    set index [lsearch $args -mplsvpnedgetype] 
    if {$index != -1} {
        set MplsVpnEdgeType [lindex $args [expr $index + 1]] 
    } else {
        set MplsVpnEdgeType CE        
    }
    #set vpnsite1 $m_hVpnSite($VpnSiteName)

    if {[string tolower $MplsVpnEdgeType] =="pe"} {
        set m_hmpls1 [stc::create MplsIf -under $m_hRouter -LabelResolver Auto -ttl 64 -label 3]
        set m_hmpls2 [stc::create MplsIf -under $m_hRouter -LabelResolver Auto -ttl 64 -label 3] 
        #puts "simulatemplsif:$m_hmpls1,$m_hmpls2"		
        stc::config $m_hmpls1 -StackedOnEndpoint-targets $m_hmpls2
        stc::config $m_hmpls2 -StackedOnEndpoint-targets $m_hEthIIIf
        set m_hEncapMplsIf $m_hmpls2
        stc::config $bgpblock1 -VpnPresent TRUE
        set vpnblock [stc::get $bgpblock1 -children-BgpVpnRouteConfig]
        stc::config $vpnblock -RouteTarget $m_vpnRT($VpnSiteName) \
                    -RouteDistinguisher $m_vpnRD($VpnSiteName)
		stc::config $bgpblock1 -Label $LabelMode
    } else {       
        set vpnsite1 [stc::create VpnSiteInfoRfc2547 -under $m_hProject] 
        stc::config $vpnsite1 -PeIpv4Addr $m_peIPv4Address($VpnSiteName) -RouteDistinguisher $m_vpnRD($VpnSiteName)
        stc::config $m_hRouter -MemberOfVpnSite-targets $vpnsite1
        set VpnName $m_SiteToVpnName($VpnSiteName)
        if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $vpnsite1] == -1} {
            lappend ::mainDefine::gVpnSiteList($VpnName) $vpnsite1
        }
        stc::config $m_hVpngrp($VpnName) -MemberOfVpnIdGroup-targets "$::mainDefine::gVpnSiteList($VpnName)" 
        stc::config $bgpblock1 -Label NONE		
    }  
         
    set iFlag [string match *ipv4* $bgpblock1]
    if {$iFlag == 1} {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
    } else {
        set ipblock1 [stc::get $bgpblock1 -children-Ipv6NetworkBlock]
    }
    stc::config $ipblock1 -MemberOfVpnSite-targets $m_hVpnSite($VpnSiteName)
    
    debugPut "exit the proc of BgpV4Session::BgpV4CreateRouteBlockToVPN"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4DeleteRouteBlockFromVPN
#Description: Delete relation of BGP router and VPN according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4DeleteRouteBlockFromVPN {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4DeleteRouteBlockFromVPN"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]

    #Abstract the value of BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set RouteBlockName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set BlockName parameter you want to create the routeBlock."
    } 
    
    if {![info exists m_hBgpblock($RouteBlockName)]} {
        error "RouteBlockName $RouteBlockName does not exist."
    }
    
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set VPNName parameter you want to create the routeBlock."
    }
         
    if {[lsearch $m_VpnNameList $VpnName] ==-1} {
        error "The VpnName $VpnName does not exist,please set another one."    
    } 
    set bgpblock1 $m_hBgpblock($RouteBlockName)
    stc::config $bgpblock1 -Label NONE
    stc::config $bgpblock1 -VpnPresent FALSE
    set ipv4bk1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
    stc::config $ipv4bk1 -MemberOfVpnSite-targets ""
    set vpnblock [stc::get $bgpblock1 -children-BgpVpnRouteConfig]
    stc::config $vpnblock -RouteTarget 100:1 \
                    -RouteDistinguisher 100:1
    set index [lsearch $m_vpnRouterBlock($VpnName) $bgpblock1]
    set m_vpnRouterBlock($VpnName) [lreplace $m_vpnRouterBlock($VpnName) $index $index]
    
    debugPut "exit the proc of BgpV4Session::BgpV4DeleteRouteBlockFromVPN"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4RetrieveVPNRoutes
#Description: Get VPN router information according to incoming parameter 
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body BgpV4Session::BgpV4RetrieveVPNRoutes {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4RetrieveVPNRoutes"
    #set args [string tolower $args]
    set args [ConvertAttrPlusValueToLowerCase $args]

    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set VPNName parameter you want to create the routeBlock."
    }
         
    if {[lsearch $m_VpnNameList $VpnName] ==-1} {
        error "The VpnName $VpnName does not exist,please set another one."    
    }
   
    if {$m_vpnRouterBlock($VpnName) !=""} {
        puts "VpnName $VpnName has below vpn routeblock:"
        foreach bgpblock1 $m_vpnRouterBlock($VpnName) {
            set vpnblock [stc::get $bgpblock1 -children-BgpVpnRouteConfig]
            puts "VPN Config-RouterTarget:[stc::get $vpnblock -RouteTarget],RouteDistinguisher:[stc::get $vpnblock -RouteDistinguisher]"
            set ipv4bk1 [stc::get $bgpblock1 -children-Ipv4NetworkBlock]
            puts "IP Config-IP Address:[stc::get $ipv4bk1 -StartIpList],PrefixLength:[stc::get $ipv4bk1 -PrefixLength],Routes Number:[stc::get $ipv4bk1 -NetworkCount]"
        }
    } else {
        puts "There is no vpn routes under VpnName $VpnName."
    }
      
    debugPut "exit the proc of BgpV4Session::BgpV4RetrieveVPNRoutes"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BGPImportRouteTable
#Description: Import BGP routes in the file
#Input: 
#Output: None
#Coded by: Michael
#############################################################################
::itcl::body BgpV4Session::BgpImportRouteTable {args} {
   
    debugPut "enter the proc of BgpV4Session::BgpImportRouteTable"
    set args [ConvertAttrToLowerCase $args]

    #Parse FileName parameter
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args [expr $index + 1]] 
    } else {
        error "Please specify FileName parameter you want to import."
    }

    #Parse MaxRouteBlks parameter
    set index [lsearch $args -maxrouteblks] 
    if {$index != -1} {
        set MaxRouteBlks [lindex $args [expr $index + 1]] 
    } else {
        set MaxRouteBlks 2000000
    } 

    #Parse MaxRoutesPerRouteBlock parameter
    set index [lsearch $args -maxroutesperrouteblock] 
    if {$index != -1} {
        set MaxRoutesPerRouteBlock [lindex $args [expr $index + 1]] 
    } else {
        set MaxRouteBlks 2000000
    }
    
    #Parse seTesterIpAsNextHop parameter
    set index [lsearch $args -usetesteripasnexthop] 
    if {$index != -1} {
        set UseTesterIpAsNextHop [lindex $args [expr $index + 1]] 
    } else {
        set UseTesterIpAsNextHop TRUE
    }

    #Parse FileFormat parameter
    set index [lsearch $args -fileformat] 
    if {$index != -1} {
        set FileFormat [lindex $args [expr $index + 1]] 
    } else {
        set FileFormat "CISCO"
    }
 
    debugPut "Begin to import Bgp routes, please be patient ..."

    set BgpImportRouteParams [stc::get project1 -children-BgpImportRouteTableParams]
         
    stc::config $BgpImportRouteParams -MaxRouteBlks $MaxRouteBlks \
           -MaxRoutesPerRouteBlock $MaxRoutesPerRouteBlock \
           -UseTesterIpAsNextHop $UseTesterIpAsNextHop

    stc::config $BgpImportRouteParams -FileName $FileName -SelectedRouterRelation-targets " $m_hRouter "
    stc::perform BgpImportRouteTable -ImportParams $BgpImportRouteParams -RouterList $m_hRouter -ExecuteSynchronous TRUE 

    stc::apply
    debugPut "Finished importing the route table"
    
    debugPut "exit the proc of BgpV4Session::BgpImportRouteTable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Bgpv4RouterLinkIGP
#Description: Add the link between BgpRouter and IgpRouter
#Input: 
#Output: None
#Coded by: Yuanfen
#############################################################################
::itcl::body BgpV4Session::Bgpv4RouterLinkIGP {args} {

    debugPut "enter the proc of BgpV4Session::Bgpv4RouterLinkIGP"
    #set args [string tolower $args]
    set args [ConvertAttrToLowerCase $args]

    set index [lsearch $args -bgproutername] 
    if {$index != -1} {
        set BgpRouterName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set BgpRouterName parameter you want to create"
    }

    set index [lsearch $args -igproutername] 
    if {$index != -1} {
        set IgpRouterName [lindex $args [expr $index + 1]] 
    } else {
        error "Please set IgpRouterName parameter you want to create"
    }

    set index [lsearch $args -linktype] 
    if {$index != -1} {
        set LinkType [lindex $args [expr $index + 1]] 
    } else {
        set LinkType VRFProviderLink
    }
    #先固定连接类型为VRFProviderLink
    set LinkType VRFProviderLink
    set ::mainDefine::objectName $BgpRouterName
    uplevel 1 {  
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]
    }
    set bgpParentRouter $::mainDefine::result
    set ::mainDefine::objectName $IgpRouterName
    uplevel 1 {  
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]
    }
    set igpParentRouter $::mainDefine::result
    
	  if {[string tolower $LinkType]=="vrfproviderlink"} {
        set iMplsForwardingLink [stc::create "MplsForwardingLink" \
            -under $bgpParentRouter \
            -Active "TRUE" \
            -LocalActive "TRUE" ]

        set iL3ForwardingLink [stc::create "L3ForwardingLink" \
            -under $bgpParentRouter \
            -Active "TRUE" \
            -LocalActive "TRUE" ]

        set iVrfProviderLink [stc::create "VrfProviderLink" \
            -under $bgpParentRouter \
            -Active "TRUE" \
            -LocalActive "TRUE" ]
        set iMplsHierarchicalLink [stc::create "MplsHierarchicalLink" \
            -under $bgpParentRouter \
            -Active "TRUE" \
            -LocalActive "TRUE" ]
        
        set iMplsL2VpnPeToPLink [stc::create "MplsL2VpnPeToPLink" \
            -under $bgpParentRouter \
            -Active "TRUE" ]   
         
        set ipv4if [stc::get $igpParentRouter -TopLevelIf-targets]
        set mplsif [stc::get $ipv4if -StackedOnEndpoint-targets]
        stc::config $bgpParentRouter -ContainedLink-targets " $iVrfProviderLink "
        stc::config $iMplsForwardingLink -LinkDstDevice-targets $igpParentRouter
        stc::config $iMplsForwardingLink -LinkSrc-targets $m_hIpv4
        stc::config $iMplsForwardingLink -LinkDst-targets $mplsif
        stc::config $iL3ForwardingLink -LinkDstDevice-targets $igpParentRouter
        stc::config $iL3ForwardingLink -ContainedLink-targets " $iMplsForwardingLink $iMplsHierarchicalLink "
        stc::config $iVrfProviderLink -LinkDstDevice-targets $igpParentRouter
        stc::config $iVrfProviderLink -ContainedLink-targets "$iL3ForwardingLink $iMplsL2VpnPeToPLink"
        
        stc::config $iMplsHierarchicalLink -LinkDstDevice-targets $igpParentRouter
        stc::config $iMplsHierarchicalLink -LinkSrc-targets $m_hEncapMplsIf
        stc::config $iMplsHierarchicalLink -LinkDst-targets $mplsif 
        stc::config $iMplsL2VpnPeToPLink -LinkDstDevice-targets $igpParentRouter
        stc::config $iMplsL2VpnPeToPLink -LinkSrc-targets $m_hEncapMplsIf
        stc::config $iMplsL2VpnPeToPLink -LinkDst-targets $mplsif 
    } elseif {[string tolower $igpParentRouter]=="vrfcustomerlink"} {
        set iVrfCustomerLink [stc::create "VrfCustomerLink" \
            -under $igpParentRouter ]

        set iVplsBgpCeToPeLink [stc::create "VplsBgpCeToPeLink" \
            -under $igpParentRouter ]

       stc::config $igpParentRouter -ContainedLink-targets " $iVrfCustomerLink "
       stc::config $iVrfCustomerLink -LinkDstDevice-targets " $bgpParentRouter "
       stc::config $iVrfCustomerLink -ContainedLink-targets " $iVplsBgpCeToPeLink "
       stc::config $iVplsBgpCeToPeLink -LinkDstDevice-targets " $bgpParentRouter "
       stc::config $iVplsBgpCeToPeLink -LinkSrc-targets " $m_hEthIIIf "
       stc::config $iVplsBgpCeToPeLink -LinkDst-targets " $m_hEncapMplsIf "
    }
    
    debugPut "exit the proc of BgpV4Session::Bgpv4RouterLinkIGP"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Bgpv4ViewRouter
#Description: View BGP router 
#Input: 
#Output: None
#Coded by: Andy
#############################################################################
::itcl::body BgpV4Session::BgpV4ViewRouter {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4ViewRouter"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    set bgpRouter [stc::get $m_hRouter -children-BgpRouterConfig]
    set routerStates [stc::get $bgpRouter -Active]
    if {[string tolower $routerStates]!="true"} {
        error "The Routers to be view should be active."  
    } elseif {[string tolower $m_viewRoutes]!="true"} {
        error "The attribute of ViewRoutes should be TRUE before run this function."
    }
    #Abstract the  FileName 
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args [expr $index + 1]]
    } else {
        set FileName "c:/routes.txt"
    }

    set hRouter $m_hRouter
    stc::perform  BgpViewRoutes -FileName $FileName -RouterList $hRouter
    
    debugPut "exit the proc of BgpV4Session::BgpV4ViewRouter"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: BgpV4Create6VPEVpn
#Description: Create 6PE VPN according to incoming parameter
#Input: 
#Output: None
#Coded by: Yuanfen
#############################################################################
::itcl::body BgpV4Session::BgpV4Create6VPEVpn {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4Create6VPEVpn"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnName parameter."
    }
    if {[lsearch $m_VpnNameList $VpnName] !=-1} {
        error "The VpnName $VpnName existed,please set another one."    
    }
    
    set findFlag 0
    set vpnList [stc::get $m_hProject -Children-VpnIdGroup]
    foreach vpn $vpnList {
        set name [stc::get $vpn -Name]
        if {$name == $VpnName} {
             set findFlag 1
             set vpnid1 $vpn
             break
        }
    }
    
    if {$findFlag == 0} { 
        set vpnid1 [stc::create VpnIdGroup -under $m_hProject -Name $VpnName]
        set ::mainDefine::gVpnSiteList($VpnName) ""
    }
    
    set m_hVpngrp($VpnName) $vpnid1
    lappend m_VpnNameList $VpnName
    lappend m_vpnList $vpnid1
  
    debugPut "exit the proc of BgpV4Session::BgpV4Create6VPEVpn"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4Create6VPESite
#Description: Create 6VPE Vpn site according to incoming parameter
#Input: 
#Output: None
#Coded by: Yuanfen
#############################################################################
::itcl::body BgpV4Session::BgpV4Create6VPESite {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4Create6VPESite"
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    #Abstract the value of VpnSiteName 
    set index [lsearch $args -vpnsitename] 
    if {$index != -1} {
        set VpnSiteName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify VpnSiteName parameter "
    }
    
    #Abstract the value of peIpv4Address 
    set index [lsearch $args -peipv4address] 
    if {$index != -1} {
        set peIpv4Address [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify peIpv4Address parameter "
    }
    
    #Abstract the value of peIpv4PrefixLength 
    set index [lsearch $args -peipv4prefixlength] 
    if {$index != -1} {
        set peIpv4PrefixLength [lindex $args [expr $index + 1]]
    } else  {
        set peIpv4PrefixLength 32
    }
    
    #将VpnNameList修改为VpnName
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }
    
    #Abstract the value of RD 
    set index [lsearch $args -rd] 
    if {$index != -1} {
        set RD [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify RD parameter "
    }
    
    #Abstract the value of RTImport 
    set index [lsearch $args -rtimport] 
    if {$index != -1} {
        set RTImport [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify RTImport parameter "
    }
    
    # 记录RT,RD全局变量
    set m_vpnRD($VpnSiteName) $RD
    set m_vpnRT($VpnSiteName) $RTImport
    
    set m_SiteToVpnName($VpnSiteName) $VpnName
    set m_peIPv4Address($VpnSiteName) $peIpv4Address
    
    set vpnsite1 [stc::create VpnSiteInfo6Pe -under $m_hProject -Name $VpnSiteName] 
    stc::config $vpnsite1 -PeIpv4Addr $peIpv4Address -PeIpv4PrefixLength $peIpv4PrefixLength    

    set m_hVpnSite($VpnSiteName) $vpnsite1
    
    #将vpnsite1添加到全局变量vpnsitelist中
    if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $vpnsite1] == -1} {
        lappend ::mainDefine::gVpnSiteList($VpnName) $vpnsite1
    }

    lappend m_vpnSiteVpnList $VpnSiteName
    stc::config $vpnsite1 -RouteDistinguisher $RD
 
    debugPut "exit the proc of BgpV4Session::BgpV4Create6VPESite"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: BgpV4SetBfd
#Description: Set bfdconfig on bgpv4router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body BgpV4Session::BgpV4SetBfd {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4SetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    if {$m_bfdSession == ""} {
        stc::config $m_hbgpRouter -EnableBfd true
        lappend args -router $m_hRouter -routerconfig $m_hbgpRouter
        set m_bfdSession [CreateBfdConfigHLAPI $args]
    } else {
        lappend args -bfdsession $m_bfdSession
        SetBfdConfigHLAPI $args
    }
    
    debugPut "exit the proc of BgpV4Session::BgpV4SetBfd"
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: BgpV4UnsetBfd
#Description: Unset bfdconfig on bgpv4router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body BgpV4Session::BgpV4UnsetBfd {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4UnsetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -bfdsession $m_bfdSession -routerconfig $m_hbgpRouter
    UnsetBfdConfigHLAPI $args
    set m_bfdSession ""
    
    debugPut "exit the proc of BgpV4Session::BgpV4UnsetBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4StartBfd
#Description: start bfdconfig on bgpv4router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body BgpV4Session::BgpV4StartBfd {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4StartBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StartBfdHLAPI $args
    
    debugPut "exit the proc of BgpV4Session::BgpV4StartBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BgpV4StopBfd
#Description: start bfdconfig on bgpv4router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body BgpV4Session::BgpV4StopBfd {args} {

    debugPut "enter the proc of BgpV4Session::BgpV4StopBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StopBfdHLAPI $args
    
    debugPut "exit the proc of BgpV4Session::BgpV4StopBfd"
    return $::mainDefine::gSuccess
}