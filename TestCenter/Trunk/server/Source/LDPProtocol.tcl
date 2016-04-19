###########################################################################
#                                                                        
#  Filename£ºLDPProtocol.tcl                                                                                              
# 
#  Description£ºDefinition of LDP protocol classes and relevant API                                          
# 
#  Creator£º Penn.Chen
#
#  Time£º  2007.6.18
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################
proc GetLdpGatewayIpv4 {ipv4Addr} {
    set list [split $ipv4Addr .]
    set len [llength $list]
    set tail 1
    if {[lindex $list [expr $len - 1]] == 1} {
        set tail 2
    }
    set addr [lindex $list 0]
    for {set i 1} {$i < [expr $len - 1]} {incr i} {
        append addr .[lindex $list $i]        
    }
    append addr .$tail
    return $addr
}
proc bits2prefix {pMask} {
    if {![string is integer $pMask]} {
        return -1
    }
    if {$pMask < 0 || $pMask > 32} {
        return -1
    }
    set sum [expr wide(pow(2,32) - pow(2, 32-$pMask))]
    set bit0_7 [expr $sum & 0xff]
    set bit8_15 [expr ($sum >> 8) & 0xff ]
    set bit16_23 [expr ($sum >> 16) & 0xff ]
    set bit24_31 [expr ($sum >> 24) & 0xff ]

    return "$bit24_31.$bit16_23.$bit8_15.$bit0_7"    
}

proc prefix2bits {netmask} { 
   set list [split $netmask .]
   set len [llength $list]

   set bits 0
   foreach dec $list {
       set bin "" 
       set a 1 
       while {$a>0} { 
           set a [expr $dec/2] 
           set b [expr $dec%2] 
           set dec $a 
           if {$b == "1"} {
               set bits [expr $bits + 1]
           } 
      } 
   }
   return $bits
}

::itcl::class LdpSession {
     #Inherit Router class
     inherit Router

    #Variables
    public variable m_hPort ""
    public variable m_hIpv4If ""    
    public variable m_hProject ""
    public variable m_routerName ""
    public variable m_portName ""
    public variable m_hRouter ""
    public variable m_hLdpRouterConfig ""
    public variable m_ldpRouterConfig "" 
    public variable m_hIpv4PrefixLsp ""
    public variable m_ldpRouterResult ""           
    public variable m_routerNameList "" 
    public variable m_ldpLspNameList ""
    public variable m_ldpLspResult ""
    public variable LspPoolConfig
    
    public variable m_hResultDataSet

    #Relevant configuration about SetSession
    public variable m_addressfamily "IPV4"
    public variable m_ipv4addr "192.85.1.3"
    public variable m_macaddr "00:10:94:00:00:02"
    public variable m_ipv4prefixlen 24
    public variable m_ipv6addr "2000::2"
    public variable m_ipv6prefixlen 64
    public variable m_hellotimer 5
    public variable m_testerrouterid "192.0.0.1"
    public variable m_peertype "Link"
    public variable m_flaggracerestart "FALSE"
    public variable m_startinglabel 16
    public variable m_keepalivetimer 45
    public variable m_labelspaceid 0
    public variable m_ftreconnecttimeout 5
    public variable m_recoverytimer 10     
    public variable m_active TRUE
    public variable m_portType "ethernet"
 
    #Variables associated with VPN
    public variable m_hVpngrp
    public variable m_SiteToBlock
    public variable m_peIPv4Address 
    public variable m_SiteToVpnName
    public variable m_hVpnSite
    public variable m_hMpls ""
    public variable m_hEncapMplsIf ""
    public variable m_vpnList ""
    public variable m_vpnSiteVpnList ""
    public variable m_VpnNameList ""
    #added by yuanfen 7.21 2011
    public variable m_hEthIIIf ""
    public variable m_LocalMac "00:00:00:11:01:01"
    public variable m_LocalMacModifier "00:00:00:00:00:01"

    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
           { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {    

        set m_routerName $routerName
        set m_routerNameList $routerName       
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject   
        set m_portType $portType
          
        #Get Ipv4 interface
        set m_hIpv4If [stc::get $hRouter -children-Ipv4If] 
        set m_hIpAddress $m_hIpv4If 
        
        #Get Ethernet interface
        #added by yuanfen 8.11 2011
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
     
        #Create LDP router object under the router object    
        set m_hLdpRouterConfig [stc::create "LdpRouterConfig" -under $m_hRouter -name $routerName ]
        set hMplsIf [stc::get $m_hRouter -children-mplsif]
        #puts "$hMplsIf:[stc::get $hMplsIf]"
        #Create LdpRouterResult object under the LDP router object
        set m_ldpRouterResult [stc::create LdpRouterResults -under $m_hLdpRouterConfig ]
        
        #Create LdpLspResults object under the LDP router object
        set m_ldpLspResult [stc::create LdpLspResults -under $m_hLdpRouterConfig ]         

        #Make objects associated               
        stc::config $m_hLdpRouterConfig -UsesIf-targets "$m_hIpv4If "         
        stc::config $m_hLdpRouterConfig -ResolvesInterface-targets " $hMplsIf "
    set m_hMpls $hMplsIf
    set ::mainDefine::gLdpBoundMplsIF($routerName) $hMplsIf
    } 

    destructor { 
    }

    public method LdpSetSession
    public method LdpRetrieveRouter
    public method LdpRetrieveLdpStat 
    public method LdpRetrieveRouterStatus          
    public method LdpEnable
    public method LdpDisable
    public method LdpCreateIngressLspPool
    public method LdpCreateVCLspPool
    public method LdpRetrieveIngressLspPool
    public method LdpDeleteIngressLspPool
    public method LdpRetrieveIngressLspPoolStatus
    
    #Phase III
    public method LdpCreateEgressLspPool
    public method LdpRetrieveEgressLspPool    
    public method LdpDeleteEgressLspPool
    public method LdpRetrieveEgressLspPoolStatus    
    public method LdpGrStart
    public method LdpEstablishLspPool    
    public method LdpTeardownLspPool  
    
    public method LdpCreateVplsVpn 
    public method LdpCreateVplsVpnSite 
    public method LdpCreateVpnToSite           
}

############################################################################
#APIName: LdpSetSession
#
#Description: 
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpSetSession {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of LdpSession::LdpSetSession"
 
    set index [lsearch $args -testerip]
    if {$index != -1} {
       set testeripaddress [lindex $args [expr $index + 1]]
       set m_ipv4addr $testeripaddress
    } else {
       set index [lsearch $args -testeripaddress]
       if {$index != -1} {
          set testeripaddress [lindex $args [expr $index + 1]]
          set m_ipv4addr $testeripaddress
       } else { 
          set testeripaddress $m_ipv4addr
       }  
    }
   
    set index [lsearch $args -gateway]
    if {$index != -1} {
       set gateway [lindex $args [expr $index + 1]]
    } else {
       set gateway [GetLdpGatewayIpv4 $testeripaddress]
    }
              
    set index [lsearch $args -sutip]
    if {$index != -1} {
       set sutipaddress [lindex $args [expr $index + 1]]
    } else {
       set index [lsearch $args -sutipaddress]
       if {$index != -1} {
          set sutipaddress [lindex $args [expr $index + 1]]
       } else { 
          set sutipaddress  [GetLdpGatewayIpv4 $testeripaddress]
       }
    }
      
    set index [lsearch $args -submask]
    if {$index != -1} {
       set submask [lindex $args [expr $index + 1]]
       set submask [prefix2bits $submask]
       set m_ipv4prefixlen $submask
    } else {
       set submask $m_ipv4prefixlen
    }   
      
    set index [lsearch $args -testerrouterid]
    if {$index != -1} {
       set testerrouterid [lindex $args [expr $index + 1]]
       set m_testerrouterid $testerrouterid 
    } else {
       set testerrouterid $m_testerrouterid 
    }
      
    set index [lsearch $args -hellotimer]
    if {$index != -1} {
       set hellotimer [lindex $args [expr $index + 1]]
       set m_hellotimer $hellotimer
    } else {
       set hellotimer $m_hellotimer
    } 

     set index [lsearch $args -peertype]
    if {$index != -1} {
       set peertype [lindex $args [expr $index + 1]]
       set m_peertype $peertype
    } else {
       set peertype $m_peertype
    }
      
    set index [lsearch $args -startinglabel]
    if {$index != -1} {
       set startinglabel [lindex $args [expr $index + 1]]
       set m_startinglabel $startinglabel
    } else {
       set startinglabel $m_startinglabel 
    }    
     
    set index [lsearch $args -keepalivetimer]
    if {$index != -1} {
       set keepalivetimer [lindex $args [expr $index + 1]]
       set m_keepalivetimer $keepalivetimer
    } else {
       set keepalivetimer $m_keepalivetimer 
    }    
    
    set index [lsearch $args -labelspaceid]
    if {$index != -1} {
       set labelspaceid [lindex $args [expr $index + 1]]
       set m_labelspaceid $labelspaceid
    } else {
       set labelspaceid $m_labelspaceid 
    }   
 
    set index [lsearch $args -flaggracerestart]
    if {$index != -1} {
       set flaggracerestart [lindex $args [expr $index + 1]]
       set m_flaggracerestart $flaggracerestart
    } else {
       set flaggracerestart $m_flaggracerestart 
    } 
    set flaggracerestart [string map {0 false} $flaggracerestart]
    set flaggracerestart [string map {disable false} $flaggracerestart]
    set flaggracerestart [string map {off false} $flaggracerestart]
    set flaggracerestart [string map {1 true} $flaggracerestart]
    set flaggracerestart [string map {enable true} $flaggracerestart]
    set flaggracerestart [string map {on true} $flaggracerestart]
    set flaggracerestart [string map {on true} $flaggracerestart]      
       
    set index [lsearch $args -ftreconnecttimeout]
    if {$index != -1} {
       set ftreconnecttimeout [lindex $args [expr $index + 1]]
       set m_ftreconnecttimeout $ftreconnecttimeout
    } else {
       set ftreconnecttimeout $m_ftreconnecttimeout 
    }   
     
    set index [lsearch $args -recoverytimer]
    if {$index != -1} {
       set recoverytimer [lindex $args [expr $index + 1]]
       set m_recoverytimer $recoverytimer
    } else {
       set recoverytimer $m_recoverytimer 
    }   
    
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
       set m_active $active
    } else {
       set active $m_active
    } 
    set active [string map {0 false} $active]
    set active [string map {disable false} $active]
    set active [string map {off false} $active]
    set active [string map {1 true} $active]
    set active [string map {enable true} $active]
    set active [string map {on true} $active]
    set active [string map {on true} $active]     
    
    set peertype [string tolower $peertype]
    switch $peertype {
        link {
            set hellotype "LDP_DIRECTED_HELLO"
        }
        target {
            set hellotype "LDP_TARGETED_HELLO"        
        }
        targeted {
            set hellotype "LDP_TARGETED_HELLO"        
        }
    linktargeted {
            set hellotype "LDP_DIRECTED_AND_TARGETED_HELLO"        
        }
        default {
            error "The specified PeerType is invaild, valid input should be Link/Targeted"
        }
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
    
    #Configure relevant objects
    stc::config $m_hRouter -RouterId $testerrouterid
    
    stc::config $m_hIpv4If  \
        -Address $testeripaddress \
        -PrefixLength $submask \
        -Gateway $gateway
  
    stc::config $m_hLdpRouterConfig \
        -DutIp $sutipaddress \
        -LabelMin $startinglabel \
        -HelloInterval $hellotimer \
        -HelloType $hellotype \
        -KeepAliveInterval $keepalivetimer \
        -EnableGracefulRestart $flaggracerestart \
        -ReconnectTime $ftreconnecttimeout \
        -RecoveryTime $recoverytimer \
        -EnableEventLog "FALSE" \
        -Active $active
    
    #added by yuanfen 7.21 2011
    if {[string tolower $m_portType]=="ethernet"} {
        set hEthIIIf $m_hEthIIIf
        if {[info exists LocalMac]} {
            stc::config $hEthIIIf -SourceMac $m_LocalMac
        }
        if {[info exists LocalMacModifier]} {
            stc::config $hEthIIIf -SrcMacStep $m_LocalMacModifier
        }
    }
          
    #Find corresponding Mac address and set the address according to testerip from Host
    SetMacAddress $testeripaddress
    
    #Deliver configuration command and check
    ApplyValidationCheck

    debugPut "exit the proc of LdpSession::LdpSetSession"
    return $::mainDefine::gSuccess       
}

############################################################################
#APIName: LdpRetrieveRouter
#
#Description: Retrieve LDP configuration parameters
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveRouter {args} {   
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of LdpSession::LdpRetrieveRouter"
 
    set LdpRouterConfig ""
    lappend LdpRouterConfig -testeripaddress
    lappend LdpRouterConfig [stc::get $m_hIpv4If -Address]
    lappend LdpRouterConfig -submask
    set submask  [stc::get $m_hIpv4If -PrefixLength]   
    set submask [bits2prefix $submask]
    lappend LdpRouterConfig $submask
    lappend LdpRouterConfig -sutipaddress
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -DutIp]  
    lappend LdpRouterConfig -startinglabel
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -LabelMin]

    set peertype [stc::get $m_hLdpRouterConfig -HelloType] 
    switch $peertype {
        LDP_DIRECTED_HELLO {
            set peertype "LINK"
        }
        LDP_TARGETED_HELLO {
            set peertype "TARGETED"       
        }
    } 

    lappend LdpRouterConfig -peertype
    lappend LdpRouterConfig $peertype
    lappend LdpRouterConfig -testerrouterid
    lappend LdpRouterConfig [stc::get $m_hRouter -RouterId] 
    lappend LdpRouterConfig -state       
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -RouterState]                 
    lappend LdpRouterConfig -hellotimer
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -HelloInterval]  
    lappend LdpRouterConfig -labelspaceid
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -LabelSpaceId]            
    lappend LdpRouterConfig -keepalivetimer
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -KeepAliveInterval] 
    lappend LdpRouterConfig -flaggracerestart
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -EnableGracefulRestart] 
    lappend LdpRouterConfig -ftreconnecttimeout
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -ReconnectTime]  
    lappend LdpRouterConfig -recoverytimer
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -RecoveryTime]  
    lappend LdpRouterConfig -active
    lappend LdpRouterConfig [stc::get $m_hLdpRouterConfig -Active]  
            
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveRouter" 
        return $LdpRouterConfig
    } else {
    array set arr $LdpRouterConfig
    foreach {name valueVar}  $args {      
        set ::mainDefine::gAttrValue $arr($name)

        set ::mainDefine::gVar $valueVar
        uplevel 1 {
            set $::mainDefine::gVar $::mainDefine::gAttrValue
        }            
    }        
    debugPut "exit the proc of LdpSession::LdpRetrieveRouter" 
    return  $::mainDefine::gSuccess       
   }          
}

############################################################################
#APIName: LdpRetrieveLdpStat
#
#Description: Retrieve relevant statistic of LDP Router
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveLdpStat {args} {  
    
    debugPut "enter the proc of LdpSession::LdpRetrieveLdpStat"    
       
    #Retrieve relevant statistic
    set LdpRouterStats ""
    lappend  LdpRouterStats -NumLabelRequestReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxLabelRequestsCount]
    lappend  LdpRouterStats -NumLabelMappingReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxLabelMappingCount]
    lappend  LdpRouterStats -NumLabelReleaseReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxLabelReleaseCount]
    lappend  LdpRouterStats -NumLabelWithdrawReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxLabelWithdrawCount]
    lappend  LdpRouterStats -NumLabelAbortedReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxLabelAbortCount]
    lappend  LdpRouterStats -NumLabelNotificationReceived
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -RxNotificationCount]
    lappend  LdpRouterStats -NumLabelRequestSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxLabelRequestsCount]
    lappend  LdpRouterStats -NumLabelMappingSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxLabelMappingCount]
    lappend  LdpRouterStats -NumLabelReleaseSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxLabelReleaseCount]
    lappend  LdpRouterStats -NumLabeWithdrawSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxLabelWithdrawCount]
    lappend  LdpRouterStats -NumLabelAbortedSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxLabelAbortCount]
    lappend  LdpRouterStats -NumLabelNotificationSent
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -TxNotificationCount]
    lappend  LdpRouterStats -NumIngressLsps
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -LspUpCount]
    lappend  LdpRouterStats -NumEgressLsps
    lappend  LdpRouterStats [stc::get $m_ldpRouterResult -NumLspDownCount]
     
    #Return statistical items according to input parameters 
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveLdpStat"  
        return $LdpRouterStats
    } else {
        set args [ConvertAttrToLowerCase $args]
        set LdpRouterStats [string tolower $LdpRouterStats]
        array set arr $LdpRouterStats
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
        debugPut "exit the proc of LdpSession::LdpRetrieveLdpStat"
        return $::mainDefine::gSuccess        
    }                           
}



############################################################################
#APIName: LdpRetrieveRouterStatus
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveRouterStatus {args} {  
   
    debugPut "enter the proc of LdpSession::LdpRetrieveRouterStatus"
    
    set LdpRouterStatus ""
    lappend LdpRouterStatus -RouterState       
    lappend LdpRouterStatus [stc::get $m_hLdpRouterConfig -RouterState]
                   
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveRouterStatus"  
        return $LdpRouterStatus
    } else {
        set args [ConvertAttrToLowerCase $args]
        set LdpRouterStatus [ConvertAttrToLowerCase $LdpRouterStatus]
        array set arr $LdpRouterStatus
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of LdpSession::LdpRetrieveRouterStatus"
    return $::mainDefine::gSuccess        
    }     
}

############################################################################
#APIName: LdpEnable
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpEnable {args} {    
    
    debugPut "enter the proc of LdpSession::LdpEnable"    
    stc::config $m_hRouter -Active TRUE   
    stc::config $m_hLdpRouterConfig -Active TRUE   
    
    #Deliver configuration command and check
    ApplyValidationCheck
             
    debugPut "exit the proc of LdpSession::LdpEnable"  
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: LdpDisable
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpDisable {args} {   
   
    debugPut "enter the proc of LdpSession::LdpDisable"
    
    stc::config $m_hRouter -Active FALSE
    stc::config $m_hLdpRouterConfig -Active FALSE 
     
    #Deliver configuration command and check
    ApplyValidationCheck
          
    debugPut "exit the proc of LdpSession::LdpDisable" 
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: LdpCreateVCLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpCreateVCLspPool {args} {  
     #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of LdpSession::LdpCreateVCLspPool"
    set index [lsearch $args -encaptype]
    if {$index != -1} {
       set encaptype [lindex $args [expr $index + 1]]
    } else {
       set encaptype "ethVlan"
    }
    
    set index [lsearch $args -startvcid]
    if {$index != -1} {
       set StartVcId [lindex $args [expr $index + 1]]
    } else {
       set StartVcId 1
    }
    
    set index [lsearch $args -vcidcount]
    if {$index != -1} {
       set VcIdCount [lindex $args [expr $index + 1]]
    } else {
       set VcIdCount 1
    }
    
    set index [lsearch $args -vcidincrement]
    if {$index != -1} {
       set VcIdIncrement [lindex $args [expr $index + 1]]
    } else {
       set VcIdIncrement 1
    }
    
    set index [lsearch $args -groupid]
    if {$index != -1} {
       set GroupId [lindex $args [expr $index + 1]]
    } else {
       set GroupId "0"
    }
    
    set VcLsp1 [stc::create "VcLsp" \
        -under $m_hLdpRouterConfig \
        -StartVcId $StartVcId \
        -VcIdCount $VcIdCount \
        -VcIdIncrement $VcIdIncrement \
        -GroupId $GroupId]
    switch $encaptype {
        ethVlan {
            stc::config $VcLsp1 -Encap "LDP_LSP_ENCAP_ETHERNET_VLAN" -CustomEncap 4
        }
        default {
            error "The specified encaptype is invaild, valid input should be ethVlan"
        }
    } 
    
    debugPut "exit the proc of LdpSession::LdpCreateVCLspPool" 
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: LdpCreateIngressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpCreateIngressLspPool {args} {   
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of LdpSession::LdpCreateIngressLspPool"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpCreateIngressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index != -1} {
        error "The PoolName $poolname already existed,please specify another one, the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    } else {
        lappend m_ldpLspNameList $poolname
    } 
    
    set index [lsearch $args -numlsp]
    if {$index != -1} {
       set numlsp [lindex $args [expr $index + 1]]
    } else {
       set numlsp 1
    }

    set index [lsearch $args -fectype]
    if {$index != -1} {
       set fectype [lindex $args [expr $index + 1]]
    } else {
       set fectype "PREFIX"
    }
    
    set fectype1 [string tolower $fectype]
    if {$fectype1 == "prefix"} {
       set fectype "LDP_FEC_TYPE_PREFIX" 
    } elseif {$fectype1 == "host"} {
        set fectype "LDP_FEC_TYPE_HOST_ADDR" 
    } elseif {$fectype1 == "vc"} {
        set fectype "LDP_FEC_TYPE_VC"
    } else {
         set fectype "LDP_FEC_TYPE_PREFIX" 
         puts "Parameter $fectype not supported in LdpCreateIngressLspPool ..."
    }

     set index [lsearch $args -firstaddress]
    if {$index != -1} {
       set firstaddress [lindex $args [expr $index + 1]]
    } else {
       set firstaddress "192.0.1.0"
    }    
    
    set index [lsearch $args -increment]
    if {$index != -1} {
       set increment [lindex $args [expr $index + 1]]
    } else {
       set increment 1
    } 
    
    set index [lsearch $args -prefixlength]
    if {$index != -1} {
       set prefixlength [lindex $args [expr $index + 1]]
    } else {
       set prefixlength 24
    }     
        
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active "FALSE"
    }        
       
    #Configurate object attributes  
    set m_hIpv4PrefixLsp [stc::create "Ipv4PrefixLsp" \
        -under $m_hLdpRouterConfig \
        -FecType $fectype \
        -Active $active \
        -Name $poolname ]  
    lappend LspPoolConfig($poolname) -m_hIpv4PrefixLsp
    lappend LspPoolConfig($poolname) $m_hIpv4PrefixLsp               

    set hIpv4NetworkBlock [stc::get $m_hIpv4PrefixLsp -children-Ipv4NetworkBlock]
    stc::config $hIpv4NetworkBlock \
        -StartIpList $firstaddress \
        -PrefixLength $prefixlength \
        -NetworkCount $numlsp \
        -AddrIncrement $increment  
    lappend LspPoolConfig($poolname) -hIpv4NetworkBlock
    lappend LspPoolConfig($poolname) $hIpv4NetworkBlock          
    #added by cai muyong 2011.07.10
    set ::mainDefine::gPoolCfgBlock($poolname) $hIpv4NetworkBlock
    #Deliver configuration command and check
    ApplyValidationCheck
             
    debugPut "exit the proc of LdpSession::LdpCreateIngressLspPool" 
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: LdpRetrieveIngressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveIngressLspPool {args} {   

    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of LdpSession::LdpRetrieveIngressLspPool"
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpRetrieveIngressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The PoolName $poolname is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }
    
    #Retrieve handle attributes
    #puts $LspPoolConfig($poolname)
    set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
    set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]    
    set index [lsearch $LspPoolConfig($poolname) -hIpv4NetworkBlock]
    set hIpv4Network  [lindex $LspPoolConfig($poolname) [expr $index + 1]]     

    set LdpLspPoolConfig ""
    lappend LdpLspPoolConfig -fectype  

    set fectype [stc::get $m_hIpv4PrefixLsp -FecType]
    set fectype1 [string tolower $fectype]
    if {$fectype1 == "ldp_fec_type_prefix"} {
       set fectype "PREFIX" 
    } elseif {$fectype1 == "ldp_fec_type_host_addr"} {
        set fectype "HOST" 
    } elseif {$fectype1 == "ldp_fec_type_vc"} {
        set fectype "VC"
    } 

    lappend LdpLspPoolConfig $fectype
    lappend LdpLspPoolConfig -numlsp 
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -NetworkCount]    
    lappend LdpLspPoolConfig -firstaddress  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -StartIpList]     
    lappend LdpLspPoolConfig -increment  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -AddrIncrement]         
    lappend LdpLspPoolConfig -prefixlength  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -PrefixLength] 
    lappend LdpLspPoolConfig -active  
    lappend LdpLspPoolConfig [stc::get $m_hIpv4PrefixLsp -Active]    
 
    #Return statistical items according to input parameters
    set args [lrange $args 2 end] 
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveIngressLspPool"  
        return $LdpLspPoolConfig
    } else {
        array set arr $LdpLspPoolConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of LdpSession::LdpRetrieveIngressLspPool" 
    return $::mainDefine::gSuccess         
    }                        
}

############################################################################
#APIName: LdpDeleteIngressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpDeleteIngressLspPool {args} {   
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of LdpSession::LdpDeleteIngressLspPool"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpDeleteIngressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The GridName($poolname) is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    } else {
        set m_ldpLspNameList [lreplace $m_ldpLspNameList $index $index]

        #Delete relevant handles
        set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
        set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]
        stc::delete $m_hIpv4PrefixLsp                     
    }    
    
 

    #Deliver configuration command and check
    ApplyValidationCheck
                
    debugPut "exit the proc of LdpSession::LdpDeleteIngressLspPool" 
    return $::mainDefine::gSuccess         
}


############################################################################
#APIName: LdpRetrieveIngressLspPoolStatus
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveIngressLspPoolStatus {args} {   
    
     #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]         
    debugPut "enter the proc of LdpSession::LdpRetrieveIngressLspPoolStatus"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpRetrieveIngressLspPoolStatus"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The GridName($poolname) is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }

    set index [lsearch $args -lspfectype]
    if {$index != -1} {
       set lspfectype [lindex $args [expr $index + 1]]
    }

    set index [lsearch $args -lsplabel]
    if {$index != -1} {
       set lsplabel [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lspmode]
    if {$index != -1} {
       set lspmode [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lspstate]
    if {$index != -1} {
       set lspstate [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lsptype]
    if {$index != -1} {
       set lsptype [lindex $args [expr $index + 1]]
    }
                
    #Retrieve state infomation of LSP
    set LspStatus ""
    lappend LspStatus -lspfectype
    lappend LspStatus [stc::get $m_ldpLspResult -LspFecType]    
    lappend LspStatus -lsplabel
    lappend LspStatus [stc::get $m_ldpLspResult -LspLabel]    
    lappend LspStatus -lspmode
    lappend LspStatus [stc::get $m_ldpLspResult -LspMode]
    lappend LspStatus -lspstate
    lappend LspStatus [stc::get $m_ldpLspResult -LspState]
    lappend LspStatus -lsptype
    lappend LspStatus [stc::get $m_ldpLspResult -LspType]  
            
    #Return statistical items according to input parameters
    set args [lrange $args 2 end] 
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveIngressLspPoolStatus"  
        return $LspStatus
    } else {
        array set arr $LspStatus
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of LdpSession::LdpRetrieveIngressLspPoolStatus" 
    return $::mainDefine::gSuccess         
    }  
}

############################################################################
#APIName: LdpCreateEgressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpCreateEgressLspPool {args} {   
   
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of LdpSession::LdpCreateEgressLspPool"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpCreateEgressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index != -1} {
        error "The PoolName $poolname already existed,please specify another one, the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    } else {
        lappend m_ldpLspNameList $poolname
    } 
    
    set index [lsearch $args -numlsp]
    if {$index != -1} {
       set numlsp [lindex $args [expr $index + 1]]
    } else {
       set numlsp 1
    }

    set index [lsearch $args -fectype]
    if {$index != -1} {
       set fectype [lindex $args [expr $index + 1]]
    } else {
       set fectype "PREFIX"
    }

    set fectype1 [string tolower $fectype]
    if {$fectype1 == "prefix"} {
       set fectype "LDP_FEC_TYPE_PREFIX" 
    } elseif {$fectype1 == "host"} {
        set fectype "LDP_FEC_TYPE_HOST_ADDR" 
    } elseif {$fectype1 == "vc"} {
        set fectype "LDP_FEC_TYPE_VC"
    } else {
        set fectype "LDP_FEC_TYPE_PREFIX" 
        puts "Parameter $fectype not supported in LdpCreateEgressLspPool ..."
    }
     
     set index [lsearch $args -firstaddress]
    if {$index != -1} {
       set firstaddress [lindex $args [expr $index + 1]]
    } else {
       set firstaddress "192.0.1.0"
    }    
    
    set index [lsearch $args -increment]
    if {$index != -1} {
       set increment [lindex $args [expr $index + 1]]
    } else {
       set increment 1
    } 
    
    set index [lsearch $args -prefixlength]
    if {$index != -1} {
       set prefixlength [lindex $args [expr $index + 1]]
    } else {
       set prefixlength 24
    }     
        
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active "FALSE"
    }        
       
    #Configure object attributes
    stc::config $m_hLdpRouterConfig -EgressLabel "LDP_EGRESS_EXPLICIT_NULL"
          
    set m_hIpv4PrefixLsp [stc::create "Ipv4PrefixLsp" \
        -under $m_hLdpRouterConfig \
        -FecType $fectype \
        -Active $active \
        -Name $poolname ]  
    lappend LspPoolConfig($poolname) -m_hIpv4PrefixLsp
    lappend LspPoolConfig($poolname) $m_hIpv4PrefixLsp               

    set hIpv4NetworkBlock [stc::get $m_hIpv4PrefixLsp -children-Ipv4NetworkBlock]
    stc::config $hIpv4NetworkBlock \
        -StartIpList $firstaddress \
        -PrefixLength $prefixlength \
        -NetworkCount $numlsp \
        -AddrIncrement $increment  
    lappend LspPoolConfig($poolname) -hIpv4NetworkBlock
    lappend LspPoolConfig($poolname) $hIpv4NetworkBlock          
    #added by cai muyong 2011.07.10
    set ::mainDefine::gPoolCfgBlock($poolname) $hIpv4NetworkBlock
    #Deliver configuration command and check
    ApplyValidationCheck
             
    debugPut "exit the proc of LdpSession::LdpCreateEgressLspPool" 
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: LdpRetrieveEgressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveEgressLspPool {args} {   
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of LdpSession::LdpRetrieveEgressLspPool"
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpRetrieveEgressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The PoolName $poolname is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }
    
    #Retrieve handle attributes
    #puts $LspPoolConfig($poolname)
    set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
    set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]    
    set index [lsearch $LspPoolConfig($poolname) -hIpv4NetworkBlock]
    set hIpv4Network  [lindex $LspPoolConfig($poolname) [expr $index + 1]]     

    set LdpLspPoolConfig ""
    lappend LdpLspPoolConfig -fectype  
    set fectype [stc::get $m_hIpv4PrefixLsp -FecType]
    set fectype1 [string tolower $fectype]
    if {$fectype1 == "ldp_fec_type_prefix"} {
       set fectype "PREFIX" 
    } elseif {$fectype1 == "ldp_fec_type_host_addr"} {
        set fectype "HOST" 
    } elseif {$fectype1 == "ldp_fec_type_vc"} {
        set fectype "VC"
    } 

    lappend LdpLspPoolConfig $fectype
    lappend LdpLspPoolConfig -numlsp 
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -NetworkCount]    
    lappend LdpLspPoolConfig -firstaddress  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -StartIpList]     
    lappend LdpLspPoolConfig -increment  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -AddrIncrement]         
    lappend LdpLspPoolConfig -prefixlength  
    lappend LdpLspPoolConfig [stc::get $hIpv4Network -PrefixLength] 
    lappend LdpLspPoolConfig -active  
    lappend LdpLspPoolConfig [stc::get $m_hIpv4PrefixLsp -Active]    
 
    #Return statistical items according to input parameters
    set args [lrange $args 2 end] 
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveEgressLspPool"  
        return $LdpLspPoolConfig
    } else {
        array set arr $LdpLspPoolConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of LdpSession::LdpRetrieveEgressLspPool" 
    return $::mainDefine::gSuccess         
    }                        
}

############################################################################
#APIName: LdpDeleteEgressLspPool
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpDeleteEgressLspPool {args} {   
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of LdpSession::LdpDeleteEgressLspPool"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpDeleteEgressLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The GridName($poolname) is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    } else {
        set m_ldpLspNameList [lreplace $m_ldpLspNameList $index $index]
        #Delete relevant handles
        set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
        set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]
        stc::delete $m_hIpv4PrefixLsp           
    }    

    #Deliver configuration command and check
    ApplyValidationCheck
                
    debugPut "exit the proc of LdpSession::LdpDeleteEgressLspPool" 
    return $::mainDefine::gSuccess         
}


############################################################################
#APIName: LdpRetrieveEgressLspPoolStatus
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpRetrieveEgressLspPoolStatus {args} {   
    
     #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]         
    debugPut "enter the proc of LdpSession::LdpRetrieveEgressLspPoolStatus"
    
    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpRetrieveEgressLspPoolStatus"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The GridName($poolname) is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }

    set index [lsearch $args -lspfectype]
    if {$index != -1} {
       set lspfectype [lindex $args [expr $index + 1]]
    }

    set index [lsearch $args -lsplabel]
    if {$index != -1} {
       set lsplabel [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lspmode]
    if {$index != -1} {
       set lspmode [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lspstate]
    if {$index != -1} {
       set lspstate [lindex $args [expr $index + 1]]
    }
    
    set index [lsearch $args -lsptype]
    if {$index != -1} {
       set lsptype [lindex $args [expr $index + 1]]
    }
                
    #Retrieve state infomation of LSP
    set LspStatus ""
    lappend LspStatus -lspfectype
    lappend LspStatus [stc::get $m_ldpLspResult -LspFecType]    
    lappend LspStatus -lsplabel
    lappend LspStatus [stc::get $m_ldpLspResult -LspLabel]    
    lappend LspStatus -lspmode
    lappend LspStatus [stc::get $m_ldpLspResult -LspMode]
    lappend LspStatus -lspstate
    lappend LspStatus [stc::get $m_ldpLspResult -LspState]
    lappend LspStatus -lsptype
    lappend LspStatus [stc::get $m_ldpLspResult -LspType]  
            
    #Return statistical items according to input parameters
    set args [lrange $args 2 end] 
    if { $args == "" } {
        debugPut "exit the proc of LdpSession::LdpRetrieveEgressLspPoolStatus"  
        return $LspStatus
    } else {
        array set arr $LspStatus
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of LdpSession::LdpRetrieveEgressLspPoolStatus" 
    return $::mainDefine::gSuccess         
    }  
}

############################################################################
#APIName: LdpGrStart
#
#Description: 
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpGrStart {args} {    
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of LdpSession::LdpGrStart"

    stc::config $m_hLdpRouterConfig -EnableGracefulRestart TRUE
    
    #Deliver configuration command and check
    ApplyValidationCheck
    
    stc::perform LdpRestartRouter -RouterList $m_hLdpRouterConfig
                       
    debugPut "exit the proc of LdpSession::LdpGrStart" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: LdpEstablishLspPool
#
#Description: 
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpEstablishLspPool {args} {    
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of LdpSession::LdpEstablishLspPool"

    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpEstablishLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The PoolName $poolname is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }
    
    set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
    set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]       
    stc::config $m_hIpv4PrefixLsp -Active "TRUE"
    
    #Deliver configuration command and check
    ApplyValidationCheck
                           
    debugPut "exit the proc of LdpSession::LdpEstablishLspPool" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: LdpTeardownLspPool
#
#Description: 
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body LdpSession::LdpTeardownLspPool {args} {    
    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of LdpSession::LdpTeardownLspPool"

    set index [lsearch $args -poolname]
    if {$index != -1} {
       set poolname [lindex $args [expr $index + 1]]
    } else {
       error " Please specify the PoolName of LdpSession::LdpTeardownLspPool"
    }
    
    set index [lsearch $m_ldpLspNameList $poolname]
    if {$index == -1} {
        error "The PoolName $poolname is not existed,the existed PoolName(s) is(are) as following:\n$m_ldpLspNameList"
    }
    
    set index [lsearch $LspPoolConfig($poolname) -m_hIpv4PrefixLsp]
    set m_hIpv4PrefixLsp  [lindex $LspPoolConfig($poolname) [expr $index + 1]]       
    stc::config $m_hIpv4PrefixLsp -Active "FALSE"        
    
    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of LdpSession::LdpTeardownLspPool" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: LdpCreateVplsVpn
#Description: Create MPLS VPN according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body LdpSession::LdpCreateVplsVpn {args} {

    debugPut "enter the proc of LdpSession::LdpCreateVplsVpn"
    set args [ConvertAttrToLowerCase $args]
    
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
    #   set mpls1 [stc::create MplsIf -under $m_hRouter -LabelResolver Ldp -IsRange "FALSE"]
    #   set m_hMpls $mpls1
    #}
    #puts "$m_hMpls:[stc::get $m_hMpls]"
    #stc::config $m_hLdpRouterConfig -ResolvesInterface-targets $m_hMpls
  
    
    debugPut "exit the proc of LdpSession::LdpCreateVplsVpn"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: LdpCreateVplsVpnSite
#Description: Create MPLS Vpn site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body LdpSession::LdpCreateVplsVpnSite {args} {

    debugPut "enter the proc of LdpSession::LdpCreateVplsVpnSite"
    set args [ConvertAttrToLowerCase $args]
    
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
    
    #Abstract the value of IntermediateSPeIpv4Addr 
    set index [lsearch $args -intermediatespeipv4addr] 
    if {$index != -1} {
        set IntermediateSPeIpv4Addr [lindex $args [expr $index + 1]]
    } else  {
        set IntermediateSPeIpv4Addr "1.1.1.1"
    }
    
    #Abstract the value of LdpFecType 
    set index [lsearch $args -ldpfectype] 
    if {$index != -1} {
        set LdpFecType [lindex $args [expr $index + 1]]
    } else  {
        set LdpFecType "FEC_128"
    }
    
    #Abstract the value of PseudowireType 
    set index [lsearch $args -pseudowiretype] 
    if {$index != -1} {
        set PseudowireType [lindex $args [expr $index + 1]]
    } else  {
        set PseudowireType "SINGLE_SEGMENT"
    }
    
    #Abstract the value of StartVcId 
    set index [lsearch $args -startvcid] 
    if {$index != -1} {
        set StartVcId [lindex $args [expr $index + 1]]
    } else  {
        set StartVcId 1
    }
    
    #Abstract the value of VcIdStep 
    set index [lsearch $args -vcidstep] 
    if {$index != -1} {
        set VcIdStep [lindex $args [expr $index + 1]]
    } else  {
        set VcIdStep 1
    }
    
    #Abstract the value of VcIdCount 
    set index [lsearch $args -vcidcount] 
    if {$index != -1} {
        set VcIdCount [lindex $args [expr $index + 1]]
    } else  {
        set VcIdCount 1
    }
    
    #Abstract the value of VpnName 
    set index [lsearch $args -vpnname] 
    if {$index != -1} {
        set VpnName [lindex $args [expr $index + 1]]
    }
    
    #Abstract the value of TargetDevice 
    set index [lsearch $args -targetdevice] 
    if {$index != -1} {
        set TargetDevice [lindex $args [expr $index + 1]]
        set TargetDevice $::mainDefine::gHostHandle($TargetDevice)
    } else  {
        error "Please specify VpnSite associated Host Name "
    }
  
    #Abstract the value of Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }

    set m_SiteToVpnName($VpnSiteName) $VpnName
    set m_peIPv4Address($VpnSiteName) $peIpv4Address
   
    set vpnsite1 [stc::create VpnSiteInfoVplsLdp -under $m_hProject -Name $VpnSiteName] 
    stc::config $vpnsite1 -PeIpv4Addr $peIpv4Address -PeIpv4PrefixLength $peIpv4PrefixLength -IntermediateSPeIpv4Addr $IntermediateSPeIpv4Addr  

    set m_hVpnSite($VpnSiteName) $vpnsite1
    
    stc::config $TargetDevice -MemberOfVpnSite-targets " $vpnsite1 "
    
    if {[lsearch $::mainDefine::gVpnSiteList($VpnName) $vpnsite1] == -1} {
        lappend ::mainDefine::gVpnSiteList($VpnName) $vpnsite1
    }

    lappend m_vpnSiteVpnList $VpnSiteName
            
    debugPut "exit the proc of LdpSession::LdpCreateVplsVpnSite"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: LdpCreateVpnToSite
#Description: Add VPN to Site according to incoming parameter
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body LdpSession::LdpCreateVpnToSite {args} {

    debugPut "enter the proc of LdpSession::LdpCreateVpnToSite"
    set args [ConvertAttrToLowerCase $args]
    
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
            }
            set m_SiteToVpnName($VpnSiteName) $VpnName
            stc::config $m_hVpngrp($VpnName) -MemberOfVpnIdGroup-targets "$::mainDefine::gVpnSiteList($VpnName)"
        } else {
            error "VpnName $VpnName you set does not exist."
        }  
    } else {
        error "VpnSiteName $VpnSiteName you set does not exist."
    }  
    
    debugPut "exit the proc of LdpSession::LdpCreateVpnToSite"
    return $::mainDefine::gSuccess
}