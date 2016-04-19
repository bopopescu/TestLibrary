###########################################################################
#                                                                        
#  File Name£ºWanPort.tcl                                                                                              
# 
#  Description£ºDefinition of STC WAN port class                                             
# 
#  Author£º David.Wu
#
#  Create time:  2007.5.10
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

##########################################
#Definition of Pos port class
##########################################  
::itcl::class WanPort {
    #Variables
    public variable m_FramingMode "OC3"
    public variable m_scrambler ""
    public variable m_descrambler ""
    public variable m_rxFcs ""
    public variable m_txFcs ""
    public variable m_payloadType ""
    public variable m_portName 
    public variable m_POSPhy ""
    public variable m_authentication "none"
    public variable m_Username "Spirent"
    public variable m_Password "Spirent"
    public variable m_MagicNumber "false"
    public variable m_MruSize 1500
    public variable m_MPLSCP "false"
    public variable m_OSINLCP "false"
    public variable m_IPCPv4 "true"
    public variable m_IPCPv6 "false"
    public variable m_TxFcs 32
    public variable m_RxFcs 32
    public variable m_Scrambler "TRUE"
    public variable m_Gateway "0.0.0.0"
    public variable m_Peeripv4 "0.0.0.0"
    public variable m_Localipv4 "192.85.1.3"
    public variable m_Peeripv6 "::"
    public variable m_Localipv6 "fe80::"

    public variable m_ifStack wan

    #Inherit from TestPot
    inherit TestPort
    #Constructor 
    constructor { portName hPort portType chassisName portLocation hProject chassisIp mode} { TestPort::constructor $portName $hPort $portType $chassisName $portLocation $hProject $chassisIp $mode} { 
        set ::mainDefine::objectName $portName 
        if {$mode == "inherit"} {
            uplevel 1 { 
                uplevel 1 {    
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
                }
            }     
        } else {
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
        }
        set hPort $::mainDefine::result 
        set m_portName $portName    
    }
    #Destructor
    destructor {
    }

     #Methods
    public method ConfigPort 
    public method ConfigPPP 
    public method ConnectPPP 
    public method GetPPPState 
}
  
############################################################################
#APIName: ConfigPort
#
#Description: Configure ppp attribute
#
#Input: 1. args:argument list£¬including
#        (1)-FramingMode FramingMode:POS interface framing mode
#        (2)-Scrambler Scrambler:POS interface scrambler
#        (3)-Descrambler Descrambler:POS interface descrambler
#        (4)-RxFcs RxFcs:Frame Check Sequence size
#        (5)-TxFcs TxFcs:Frame Check Sequence size
#        (6)-PayloadType PayloadType:port payload type
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body WanPort::ConfigPort {args} {
 
     #Convert the attribute of args to lower case
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of WanPort::ConfigPort"

    set index [lsearch $args -framingmode]
    if {$index != -1} {
        set FramingMode [lindex $args [expr $index + 1]]
        set m_FramingMode $FramingMode 
    } 

    set index [lsearch $args -scrambler]
    if {$index != -1} {
        set Scrambler [lindex $args [expr $index + 1]]
        set m_Scrambler $Scrambler
    }

    if {[string tolower $m_Scrambler] == "true"} {
        set ScramblerMode "ENABLE"
    } else {
        set ScramblerMode "DISABLE"
    }

    set index [lsearch $args -descrambler]
    if {$index != -1} {
        set Descrambler [lindex $args [expr $index + 1]]
    } else {
        set Descrambler TRUE
    }

    set index [lsearch $args -rxfcs]
    if {$index != -1} {
        set RxFcs [lindex $args [expr $index + 1]]
        set m_RxFcs $RxFcs
    } 

    set index [lsearch $args -txfcs]
    if {$index != -1} {
        set TxFcs [lindex $args [expr $index + 1]]
        set m_TxFcs $TxFcs
    } 

    if {$m_TxFcs == "16"} {
        set FcsMode "FCS16"
    } else {
        set FcsMode "FCS32"
    }

    set index [lsearch $args -payloadtype]
    if {$index != -1} {
        set PayloadType [lindex $args [expr $index + 1]]
    } else {
        set PayloadType PPP
    }

    if {[string tolower $PayloadType] == "ppp"} {
        set hdlcEnable "DISABLE"
    } else {
        set hdlcEnable "ENABLE"
    }

    if {$m_POSPhy == ""} {
        set POSPhy(1) [lindex [stc::get $m_hPort -children-POSPhy] 0] 
        if {$POSPhy(1) == ""} {
            set POSPhy(1) [stc::create "POSPhy" \
               -under $m_hPort \
               -DataPathMode "NORMAL" \
               -Mtu "4470" \
               -PortSetupMode "PORTCONFIG_ONLY" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {POS Phy 1} ]
        }  
        set m_POSPhy $POSPhy(1)
    } else {
        set POSPhy(1) $m_POSPhy
    }
       
    set HdlcLinkConfig(1) [lindex [stc::get $POSPhy(1) -children-HdlcLinkConfig] 0]
    stc::config $HdlcLinkConfig(1) \
               -Enabled "FALSE" \
               -KeepAliveTxSeqNumEnabled "TRUE" \
               -KeepAliveRxSeqNumEnabled "TRUE" \
               -KeepAliveInterval "10000" \
               -MaxDropCount "3" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {HDLC Keep Alive 1}
       
    set SonetConfig(1) [lindex [stc::get $POSPhy(1) -children-SonetConfig] 0]
    stc::config $SonetConfig(1) \
               -LineSpeed $m_FramingMode \
               -LoopbackMode "NONE" \
               -TxClockSrc "RX_LOOP" \
               -InternalPpmAdjust "0" \
               -HdlcEnable $hdlcEnable \
               -Framing "SDH" \
               -AutoAlarmResponse "DISABLE" \
               -LaisLrdiThreshold "5" \
               -LaserEnable "ENABLE" \
               -TxS1 "0" \
               -RxS1 "0" \
               -ExS1 "0" \
               -FCS $FcsMode \
               -HDLCScrambling $ScramblerMode \
               -TxK1 "0" \
               -TxK2 "4" \
               -TxK1K2Enable "ENABLE" \
               -TxJ0Trace "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" \
               -J0TraceMode "SIXTEEN_BYTES_MSB_CRC7" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {SONET Config 1}
       
     set SonetInjectors(1) [lindex [stc::get $POSPhy(1) -children-SonetInjectors] 0]
     stc::config $SonetInjectors(1) \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {SonetInjectors 1}
       
     set SonetPathConfig(1) [lindex [stc::get $POSPhy(1) -children-SonetPathConfig] 0]
     stc::config $SonetPathConfig(1) \
               -TxC2 "22" \
               -RxC2 "0" \
               -ExC2 "22" \
               -TxJ1Trace "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" \
               -J1TraceMode "SIXTYFOUR_BYTES_CRLF" \
               -ExJ1Trace "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" \
               -TimpEnable "ENABLE" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {SONET Path Config 1}
       
     set SonetPathInjectors(1) [lindex [stc::get $POSPhy(1) -children-SonetPathInjectors] 0]
     stc::config $SonetPathInjectors(1) \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {SonetPathInjectors 1}
        
     stc::config $m_hPort -ActivePhy-targets $POSPhy(1)  
     
     debugPut "exit the proc of WanPort::ConfigPort"
     return $::mainDefine::gSuccess  
}

############################################################################
#APIName: ConfigPPP
#
#Description: Configure ppp interface attribute
#
#Input: 1. args:argument list£¬including
#        (1) -LCP LCP:ppp LCP mode
#        (2) -IPCP IPCP:ppp IPCP negotiation mode
#        (3) -IPv6CP IPv6CP:ppp IPv6CP negotiation mode
#        (4) -MPLSCP MPLSCP:ppp MPLSCP negotiation mode
#        (5) -OSINLCP OSINLCP:ppp OSINLCP negotiation mode
#        (6) -MruSize MruSize:ppp MruSize
#        (7) -MagicNumber MagicNumber:ppp MagicNumber mode
#        (8) -Lqm Lqm:ppp Lqm negotiation mode
#        (9) -Username Username:Specify ppp Username
#        (10) -Password Password:Specify ppp Password
#        (11) -Authentication Authentication:Specify ppp Authentication mode
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body WanPort::ConfigPPP {args} {
    
    #Convert the attribute of args to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of WanPort::ConfigPPP"

    set index [lsearch $args -lcp]
    if {$index != -1} {
        set LCP [lindex $args [expr $index + 1]]
    } else {
        set LCP enable
    }

    set index [lsearch $args -ipcp]
    if {$index != -1} {
        set IPCP [lindex $args [expr $index + 1]]
        set m_IPCPv4 $IPCP 
    } 

    set index [lsearch $args -ipv6cp]
    if {$index != -1} {
        set IPv6CP [lindex $args [expr $index + 1]]
        set m_IPCPv6 $IPv6CP
    } 

    set index [lsearch $args -mplscp]
    if {$index != -1} {
        set MPLSCP [lindex $args [expr $index + 1]]
        set m_MPLSCP $MPLSCP
    } 

    set index [lsearch $args -osinlcp]
    if {$index != -1} {
        set OSINLCP [lindex $args [expr $index + 1]]
        set m_OSINLCP $OSINLCP
    } 

    set index [lsearch $args -mrusize]
    if {$index != -1} {
        set MruSize [lindex $args [expr $index + 1]]
        set m_MruSize $MruSize
    } 

    set index [lsearch $args -magicnumber]
    if {$index != -1} {
        set MagicNumber [lindex $args [expr $index + 1]]
        set m_MagicNumber $MagicNumber
    } 

    set index [lsearch $args -lqm]
    if {$index != -1} {
        set Lqm [lindex $args [expr $index + 1]]
    } else {
        set Lqm Disable
    }

    set index [lsearch $args -username]
    if {$index != -1} {
        set Username [lindex $args [expr $index + 1]]
        set m_Username $Username  
    } 

    set index [lsearch $args -password]
    if {$index != -1} {
        set Password [lindex $args [expr $index + 1]]
        set m_Password $Password
    } 

    set index [lsearch $args -gateway]
    if {$index != -1} {
        set Gateway [lindex $args [expr $index + 1]]
        set m_Gateway $Gateway
    }
    
    #added by caimuyong 2011.08.12 peer/local ipv4/ipv6
    set index [lsearch $args -peeripv4]
    if {$index != -1} {
        set peeripv4 [lindex $args [expr $index + 1]]
        set m_Peeripv4 $peeripv4
    }
    
    set index [lsearch $args -localipv4]
    if {$index != -1} {
        set localipv4 [lindex $args [expr $index + 1]]
        set m_Localipv4 $localipv4
    }
    
    set index [lsearch $args -peeripv6]
    if {$index != -1} {
        set peeripv6 [lindex $args [expr $index + 1]]
        set m_Peeripv6 $peeripv6
    }
    
    set index [lsearch $args -localipv6]
    if {$index != -1} {
        set localipv6 [lindex $args [expr $index + 1]]
        set m_Localipv6 $localipv6
    } 

    set index [lsearch $args -authentication]
    if {$index != -1} {
        set Authentication [lindex $args [expr $index + 1]]
        set Authentication [string tolower $Authentication]
        set m_authentication $Authentication
    } 

    switch $m_authentication {
        "none" {
            set Authentication NONE
        }
        "pap" {
            set Authentication PAP
        }
        "chap" {
            set Authentication CHAP_MD5
        }
        "sut" {
            set Authentication AUTO
        }
        default {
            error "Wrong authenticationRole,should be one of none, pap, chap or sut."
        }
    }

    set FlagIPCPv4 [string tolower $m_IPCPv4]
    set FlagIPCPv6 [string tolower $m_IPCPv6]

    if {$FlagIPCPv4 == "true" && $FlagIPCPv6 == "false"} {
        set IpcpEncap "IPV4"
    } elseif {$FlagIPCPv6 == "true" && $FlagIPCPv4 == "false"} {
        set IpcpEncap "IPV6"
    } elseif {$FlagIPCPv6 == "true" && $FlagIPCPv4 == "true"} {
        set IpcpEncap "IPV4V6"
    } else {
        set IpcpEncap "IPV4"
    }

    set PppProtocolConfig(1) [lindex [stc::get $m_hPort -children-PppProtocolConfig] 0]
    stc::config $PppProtocolConfig(1) \
               -PapRequestTimeout "3" \
               -MaxPapRequestAttempts "10" \
               -ChapChalRequestTimeout "3" \
               -ChapAckTimeout "3" \
               -MaxChapRequestReplyAttempts "10" \
               -AutoRetryCount "65535" \
               -EnableAutoRetry "FALSE" \
               -Ipv4PeerAddr $m_Peeripv4 \
               -Ipv6PeerAddr $m_Peeripv6 \
               -IpcpEncap $IpcpEncap \
               -Protocol "PPPOPOS" \
               -EnableMruNegotiation "TRUE" \
               -EnableMagicNum $m_MagicNumber \
               -Authentication $Authentication \
               -IncludeTxChapId "TRUE" \
               -EnableOsi $m_OSINLCP \
               -EnableMpls $m_MPLSCP \
               -MruSize $m_MruSize \
               -EnableEchoRequest "FALSE" \
               -EchoRequestGenFreq "10" \
               -MaxEchoRequestAttempts "0" \
               -LcpConfigRequestTimeout "3" \
               -LcpConfigRequestMaxAttempts "10" \
               -LcpTermRequestTimeout "3" \
               -LcpTermRequestMaxAttempts "10" \
               -NcpConfigRequestTimeout "3" \
               -NcpConfigRequestMaxAttempts "10" \
               -MaxNaks "5" \
               -Username $m_Username \
               -Password $m_Password \
               -UsePartialBlockState "FALSE" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {PppProtocolConfig 1}  
    catch {
        #added by caimuyong 2011.08.12
        set Host(1) [lindex [stc::get $m_hPort -children-Host] 0]
        stc::config $Host(1) \
            -DeviceCount "1" \
            -EnablePingResponse "FALSE" \
            -Active "TRUE" \
            -LocalActive "TRUE" \
            -Name {Host}
        
        set EthIIIf(1) [stc::get $Host(1) -children-EthIIIf]
        set HdlcIf(1) [stc::get $Host(1) -children-HdlcIf]
        set PppIf(1) [lindex [split [stc::get $Host(1) -children-pppif] ] 0]
        set PppIf(2) [lindex [split [stc::get $Host(1) -children-pppif] ] 1]
        set Ipv4If(1) [stc::get $Host(1) -children-ipv4if]
        set Ipv6If(1) [lindex [split [stc::get $Host(1) -children-ipv6if] ] 0]
        set Ipv6If(2) [lindex [split [stc::get $Host(1) -children-ipv6if] ] 1]
        stc::config $Ipv4If(1) -Address $m_Localipv4
        stc::config $Ipv6If(1) -Address "2000::2"
        stc::config $Ipv6If(2) -Address $m_Localipv6
        stc::config $Host(1) -TopLevelIf-targets " $Ipv4If(1) $Ipv6If(1) $Ipv6If(2) "
        stc::config $Ipv4If(1) -StackedOnEndpoint-targets " $PppIf(1) "
        stc::config $Ipv6If(1) -StackedOnEndpoint-targets " $PppIf(2) "
        stc::config $Ipv6If(2) -StackedOnEndpoint-targets " $PppIf(2) "
        if {$IpcpEncap == "IPV4"} {
            stc::config $PppProtocolConfig(1) -UsesIf-targets " $Ipv4If(1) "
        } elseif {$IpcpEncap =="IPV6"} {
            stc::config $PppProtocolConfig(1) -UsesIf-targets " $Ipv6If(2) "
        } elseif {$IpcpEncap =="IPV4V6"} {
            stc::config $PppProtocolConfig(1) -UsesIf-targets " $Ipv6If(2) $Ipv4If(1)"
        }
    }
    
    debugPut "exit the proc of WanPort::ConfigPPP"
    return $::mainDefine::gSuccess          
}
    
############################################################################
#APIName: GetPPPState
#
#Description: Get ppp negotiation state
#
#Input: 1. args:atgument list£¬including
#         (1)-LCPState LCPState : ppp LCP state
#         (2)-IPCPState IPCPState :ppp ipcp state
#         (3)-IPv6CPState IPv6CPState :ppp ipv6cp state
#         (4)-OSINLCPState OSINLCPState :ppp osinlcp state
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body WanPort::GetPPPState {args} {
   
    #Convert the attribute of args to lower case
    set args [ConvertAttrToLowerCase $args]  
    set PppProtocolConfig(1) [lindex [stc::get $m_hPort -children-PppProtocolConfig] 0]
    set PppProtocolResults [stc::get $PppProtocolConfig(1) -children-PppProtocolResults]
    
    set index [lsearch $args -lcpstate]
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] LCPState
        set LCPState "[stc::get $PppProtocolResults -PosLcpOrNcpState]"   
    } 

    set index [lsearch $args -ipcpstate]
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] IPCPState 
        set IPCPState "[stc::get $PppProtocolResults -Ipv4CpState]"  
    } 

    set index [lsearch $args -ipv6cpstate]
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] IPv6CPState 
        set IPv6CPState "[stc::get $PppProtocolResults -Ipv6CpState]"  
    } 

    set index [lsearch $args -mplscpstate]
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] MPLSCPState 
        set MPLSCPState "[stc::get $PppProtocolResults -MplsCpState]"  
    } 

    set index [lsearch $args -osinlcpstate]
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] OSINLCPState
        set OSINLCPState "[stc::get $PppProtocolResults -OsiNlcpState]"  
    } 
    
    return $::mainDefine::gSuccess
}  

############################################################################
#APIName: ConnectPPP
#
#Description: Connect PPP
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body WanPort::ConnectPPP {args} {
    
    #Convert the attribute of args to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of WanPort::ConnectPPP"
  
    set pppconfig [stc::get $m_hPort -children-pppprotocolconfig]
    if {$pppconfig != ""} {
        stc::perform PppconnectCommand -Blocklist $pppconfig
    } 
    
    debugPut "exit the proc of WanPort::ConnectPPP"
    return $::mainDefine::gSuccess          
}
       
