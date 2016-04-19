###########################################################################
#                                                                        
#  File Name：Ospfv2Protocol.tcl                                                                                              
# 
#  Description：Definition STC Ethernet port class and associated API                                             
# 
#  Author： David.Wu
#
#  Create time:  2007.5.10
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

##########################################
#Definition of Ospfv2Session class
##########################################
::itcl::class Ospfv2Session {
    #Inherit Router Class
    inherit Router
    #Variable definitions
    public variable m_ospfv2RouterConfig 
    public variable m_configRouterParams 
    public variable m_gridNameList ""
    public variable m_hOspfv2RouterConfig ""
    public variable m_lsaNameList ""
    public variable m_hLsaArrIndexedByLsaName 
    public variable m_lsaConfig 
    public variable m_hOspfv2Result ""
    public variable m_topNameList ""
    public variable m_topConfig
    public variable m_hLsaArrIndexedByTopName
    public variable m_linkLsaNameList ""
    public variable m_linkConfig
    public variable m_routerIp ""
    public variable m_linkNameList ""
    public variable m_hIpv4If ""
    public variable m_hResultDataSet ""
    public variable m_hGridTopologyGenParams ""
    public variable m_hL2If ""
    public variable m_hRouterLsa ""
    public variable m_sutRouterId ""
    public variable m_ospfRouterType 0
    public variable m_hRouterLsaLink ""
    public variable m_hSimulatorRouter ""
    public variable m_totalLinkList ""
    public variable m_link2RouterArr
    public variable m_summaryRouteBlockList ""
    public variable m_externalRouteBlockList   ""
    public variable m_networkList   ""
    public variable m_routerList   ""
    public variable m_handleBylinkName   
    public variable m_handleByRtrName
    public variable m_linkStatusArr 
    public variable m_routerLinkListArr 
    public variable m_linkStatus
    public variable m_awdtimer
    public variable m_wadtimer
    public variable m_gridRouterNameArrList
    public variable m_addEmulatorAsTopoRtr 0
    public variable m_firstTimeConfig 1
    public variable m_autoConnectLinkNum 0
    public variable m_routerId2RouternameArr
    public variable m_portType "ethernet"
    public variable m_viewRoutes "FALSE"
    public variable m_bfdSession ""
    
    #added by yuanfen 7.21 2011
    public variable m_LocalMac "00:00:00:11:01:01"
    public variable m_LocalMacModifier "00:00:00:00:00:01"
    
    #Constructor function
    constructor { routerName routerType routerId hRouter portName hProject portType} \
    { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {    
         
        set m_portType $portType
        #Create Ospfv2RouterConfig
        set m_hOspfv2RouterConfig [stc::create Ospfv2RouterConfig -under $m_hRouter]
        
        #Get Ipv4 interface
        set ipv4if1 [stc::get $hRouter -children-Ipv4If]  
        set m_hIpv4If $ipv4if1  
        set m_hIpAddress $m_hIpv4If
        
        #Get Ethernet interface

        if {$m_portType == "ethernet"} {
            set m_hL2If [stc::get $hRouter -children-EthIIIf]
            set m_hMacAddress $m_hL2If    
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set m_hL2If [stc::get $hRouter -children-HdlcIf]
            } else {
                set m_hL2If [stc::get $hRouter -children-PppIf]
            }
        } 
    }
    
    #Destructor Function
    destructor {
    }
    #Method Declearation
    public method Ospfv2SetSession
    public method Ospfv2RetrieveRouter
    public method Ospfv2CreateTopGrid
    public method Ospfv2RetrieveTopGrid
    public method Ospfv2RetrieveTopGridRouter
    public method Ospfv2DeleteTopGrid 
    public method Ospfv2CreateTopRouter 
    public method Ospfv2SetTopRouter
    #public method Ospfv2CreateNetworkLsa 
    public method Ospfv2RetrieveTopRouter 
    public method Ospfv2DeleteTopRouter
    public method Ospfv2CreateTopRouterLink
    public method Ospfv2SetTopRouterLink
    public method Ospfv2RetrieveTopRouterLink 
    public method Ospfv2DeleteTopRouterLink 
    public method Ospfv2CreateTopNetwork 
    public method Ospfv2CreateTopNetwork1
    public method Ospfv2SetTopNetwork
    public method Ospfv2RetrieveTopNetwork
    public method Ospfv2DeleteTopNetwork 
    public method Ospfv2CreateTopSummaryRouteBlock 
    public method Ospfv2CreateTopSummaryRouteBlock1
    public method Ospfv2SetTopSummaryRouteBlock
    public method Ospfv2SetTopSummaryRouteBlock1
    public method Ospfv2RetrieveTopSummaryRouteBlock
    public method Ospfv2DeleteTopSummaryRouteBlock 
    public method Ospfv2CreateTopExternalRouteBlock 
    public method Ospfv2SetTopExternalRouteBlock 
    public method Ospfv2CreateTopExternalRouteBlock1 
    public method Ospfv2SetTopExternalRouteBlock1     
    public method Ospfv2DeleteTopExternalRouteBlock
    public method Ospfv2CreateRouterLsa 
    public method Ospfv2CreateRouterLsaLink
    public method Ospfv2DeleteRouterLsa
    public method Ospfv2CreateNetworkLsa
    public method Ospfv2CreateNetworkLsaRouter
    public method Ospfv2DeleteNetworkLsa
    public method Ospfv2CreateAsExtLsa
    public method Ospfv2DeleteAsExtLsa
    public method Ospfv2CreateSummaryLsa
    public method Ospfv2DeleteSummaryLsa
    public method Ospfv2RetrieveRouterStats
    public method Ospfv2RetrieveTopExternalRouteBlock
    public method Ospfv2AdvertiseLsa
    public method Ospfv2ReAdvertiseLsa
    public method Ospfv2AgeLsa
    public method Ospfv2Enable
    public method Ospfv2Disable
    public method Ospfv2AdvertiseRouters
    public method Ospfv2WithdrawRouters
    public method Ospfv2AdvertiseLinks
    public method Ospfv2WithdrawLinks
    public method Ospfv2SetFlap
    public method Ospfv2StartFlapRouters
    public method Ospfv2StopFlapRouters
    public method Ospfv2StartFlapLinks
    public method Ospfv2StopFlapLinks
    public method Ospfv2GraceRestartAction
    public method Ospfv2InitOspfv2RouterParam
    public method Ospfv2ViewRouter
    public method Ospfv2SetBfd
    public method Ospfv2UnsetBfd
    public method Ospfv2StartBfd
    public method Ospfv2StopBfd
}

::itcl::body Ospfv2Session::Ospfv2InitOspfv2RouterParam {} {
    if {!$m_firstTimeConfig} {        
        return
    }
    array unset m_configRouterParams 
    set m_configRouterParams(-ipaddr) 192.85.1.1
    set m_configRouterParams(-prefixlen) 24
    set m_configRouterParams(-area) 0.0.0.0
    set m_configRouterParams(-networktype) Native
    set m_configRouterParams(-routerid) $m_routerId
    set m_configRouterParams(-pduoptionvalue) EBIT 
    set m_configRouterParams(-sutipaddress) 192.85.1.2
    set m_configRouterParams(-sutprefixlen) 24
    set m_configRouterParams(-sutrouterid) 192.85.1.2
    set m_configRouterParams(-flaggre) false
    set m_configRouterParams(-grelocal) no
    set m_configRouterParams(-greremote) no
    set m_configRouterParams(-flaggreincludechecksum) false
    set m_configRouterParams(-hellointerval) 10
    set m_configRouterParams(-deadinterval) 40
    set m_configRouterParams(-pollinterval) 40
    set m_configRouterParams(-retransmitinterval) 5
    set m_configRouterParams(-transitdelay) 100
    set m_configRouterParams(-maxlsasperpacket) 100
    set m_configRouterParams(-interfacecost) 1
    set m_configRouterParams(-routerpriority) 0
    set m_configRouterParams(-mtu) 1500
    set m_configRouterParams(-flaglsadiscardmode) true
    set m_configRouterParams(-flaghostroute) True 
    set m_configRouterParams(-graceperiod) 120
    set m_configRouterParams(-restartinterval) 0
    #added by yuanfen 7.28 2011
    set m_configRouterParams(-restarttype) 0
    set m_configRouterParams(-restartreason) software 
    set m_configRouterParams(-active) yes
    set m_configRouterParams(-authenticationtype) none
    set m_configRouterParams(-password) Spirent
    set m_configRouterParams(-md5keyid) 1
    set m_configRouterParams(-abr) false
    set m_configRouterParams(-asbr) false
    
    set templist ""
    foreach index [array names m_configRouterParams] {
        lappend templist $index
        lappend templist $m_configRouterParams($index)
    }
    set templist [string tolower $templist]

    set templist [string map {enable 1} $templist]
    set templist [string map {on 1} $templist]
    set templist [string map {true 1} $templist]

    set templist [string map {disable 0} $templist]
    set templist [string map {off 0} $templist]
    set templist [string map {false 0} $templist]

    array unset m_configRouterParams
    array set m_configRouterParams $templist   
    set m_routerIp $m_configRouterParams(-ipaddr) 

    set m_hSimulatorRouter [eval stc::create RouterLsa   \
               -under $m_hOspfv2RouterConfig\
               -AdvertisingRouterId $m_routerId\
               -LinkStateId $m_routerId\
               -name "SimulatorRouter"]  
    set m_hLsaArrIndexedByTopName($m_routerName)  $m_hSimulatorRouter      
    set m_firstTimeConfig 0
}

############################################################################
#APIName: ApplyToChassis
#
#Description: Download Configuration to STC Chassis
#
#Input: None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

proc ApplyToChassis {} {
    debugPut "Apply config to Chassis"
    stc::apply
}
############################################################################
#APIName: ConvertAttrToLowerCase1
#
#Description: Convert attribute item(attr) of parameter list(-attr value) to lower-case
#
#Input:   1.args:Parameter list
#
#Output: parameter list after being converted
#
#Coded by: David.Wu
#############################################################################

proc ConvertAttrToLowerCase1 {args} {
   set args [eval subst $args ]
   set arg [string tolower $args]
   return $arg
}
############################################################################
#APIName: Ospfv2SetSession
#
#Description: Config the attribute of Ospfv2 Router
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2SetSession {args} {
Ospfv2InitOspfv2RouterParam
set list ""
if {[catch { 
#Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    debugPut "enter the proc of Ospfv2Session::Ospfv2SetSession"
    set m_ospfv2RouterConfig ""
    
    #added by caimuyong 2011.07.20
    set index [lsearch $args -abr]
    if {$index != -1} {
        set abr [lindex $args [expr $index + 1]]
        set m_configRouterParams(-abr) $abr
        stc::config $m_hSimulatorRouter -Abr $abr
    }
    set index [lsearch $args -asbr]
    if {$index != -1} {
        set asbr [lindex $args [expr $index + 1]]
        set m_configRouterParams(-asbr) $asbr
        stc::config $m_hSimulatorRouter -Asbr $asbr
    }
    #Abstract ipaddr from parameter list
    set index [lsearch $args -ipaddr]
    if {$index != -1} {
       set ipaddr [lindex $args [expr $index + 1]]
       set m_configRouterParams(-ipaddr) $ipaddr 
       set m_routerIp $ipaddr
    } else {
       set ipaddr $m_routerIp
    }
    #Abstract prefixlen from parameter list
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
         set m_configRouterParams(-prefixlen) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-prefixlen)]} {
            set m_configRouterParams(-prefixlen) 24
        }        
    }
    set prefixlen $m_configRouterParams(-prefixlen)
    
    #Abstract area from parameter list
    set index [lsearch $args -area]
    if {$index != -1} {
         set m_configRouterParams(-area) [lindex $args [expr $index + 1]]   
    } else {
        if {![info exist m_configRouterParams(-area)]} {
            set m_configRouterParams(-area) 0.0.0.0
        }        
    }
    set area $m_configRouterParams(-area)

    #Abstract networktype from parameter list
    set index [lsearch $args -networktype]
    if {$index != -1} {
         set m_configRouterParams(-networktype) [lindex $args [expr $index + 1]]    
    } else {
        if {![info exist m_configRouterParams(-networktype)]} {
            set m_configRouterParams(-networktype) native
        }        
    }
    set networktype $m_configRouterParams(-networktype)

    #Abstract prefixlen from parameter list
    set index [lsearch $args -routerid]
    if {$index != -1} {
         set m_configRouterParams(-routerid) [lindex $args [expr $index + 1]]    
    } else {
        if {![info exist m_configRouterParams(-routerid)]} {
            set m_configRouterParams(-routerid) $m_routerId
        }        
    }
    set routerid $m_configRouterParams(-routerid)
    set m_routerId $routerid

    #Abstract pduoptionvalue from parameter list
    set index [lsearch $args -pduoptionvalue]
    if {$index != -1} {
         set m_configRouterParams(-pduoptionvalue) [lindex $args [expr $index + 1]]  
    } else {
        if {![info exist m_configRouterParams(-pduoptionvalue)]} {
            set m_configRouterParams(-pduoptionvalue) EBIT
        }        
    }
    set pduoptionvalue $m_configRouterParams(-pduoptionvalue)

    #Abstract sutipaddress from parameter list
    set index [lsearch $args -sutipaddress]
    if {$index != -1} {
         set m_configRouterParams(-sutipaddress) [lindex $args [expr $index + 1]]   
    } else {
        if {![info exist m_configRouterParams(-sutipaddress)]} {
            set m_configRouterParams(-sutipaddress) 192.85.1.2
        }        
    }
    set sutipaddress $m_configRouterParams(-sutipaddress)

    #Abstract sutprefixlen from parameter list
    set index [lsearch $args -sutprefixlen]
    if {$index != -1} {
         set m_configRouterParams(-sutprefixlen) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-sutprefixlen)]} {
            set m_configRouterParams(-sutprefixlen) $prefixlen
        }        
    }
    set sutprefixlen $m_configRouterParams(-sutprefixlen)

    #Abstract sutrouterid from parameter list
  
    set index [lsearch $args -sutrouterid]
    if {$index != -1} {
         set m_configRouterParams(-sutrouterid) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-sutrouterid)]} {
            set m_configRouterParams(-sutrouterid) 192.85.1.2
        }        
    }
    set sutrouterid $m_configRouterParams(-sutrouterid)    


    #Abstract flagneighbordr from parameter list
    set index [lsearch $args -flagneighbordr]
    if {$index != -1} {
         set m_configRouterParams(-flagneighbordr) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-flagneighbordr)]} {
            set m_configRouterParams(-flagneighbordr) false
        }        
    }
    set flagneighbordr $m_configRouterParams(-flagneighbordr)

    #Abstract hellointerval from parameter list
    set index [lsearch $args -hellointerval]
    if {$index != -1} {
         set m_configRouterParams(-hellointerval) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-hellointerval)]} {
            set m_configRouterParams(-hellointerval) 10
        }        
    }
    set hellointerval $m_configRouterParams(-hellointerval)

    #Abstract deadinterval from parameter list
    set index [lsearch $args -deadinterval]
    if {$index != -1} {
         set m_configRouterParams(-deadinterval) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-deadinterval)]} {
            set m_configRouterParams(-deadinterval) 40
        }        
    }
    set deadinterval $m_configRouterParams(-deadinterval)

    #Abstract retransmitinterval from parameter list
    set index [lsearch $args -retransmitinterval]
    if {$index != -1} {
         set m_configRouterParams(-retransmitinterval) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-retransmitinterval)]} {
            set m_configRouterParams(-retransmitinterval) 5
        }        
    }
    set retransmitinterval $m_configRouterParams(-retransmitinterval)

    #Abstract transitdelay from parameter list
    set index [lsearch $args -transitdelay]
    if {$index != -1} {
         set m_configRouterParams(-transitdelay) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-transitdelay)]} {
            set m_configRouterParams(-transitdelay) 33
        }        
    }
    set transitdelay $m_configRouterParams(-transitdelay)

    #Abstract interfacecost from parameter list
    set index [lsearch $args -interfacecost]
    if {$index != -1} {
         set m_configRouterParams(-interfacecost) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-interfacecost)]} {
            set m_configRouterParams(-interfacecost) 1
        }        
    }
    set interfacecost $m_configRouterParams(-interfacecost)

    #Abstract routerpriority from parameter list
    set index [lsearch $args -routerpriority]
    if {$index != -1} {
         set m_configRouterParams(-routerpriority) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-routerpriority)]} {
            set m_configRouterParams(-routerpriority) 0
        }        
    }
    set routerpriority $m_configRouterParams(-routerpriority)

    #Abstract mtu  from parameter list
    set index [lsearch $args -mtu]
    if {$index != -1} {
         set m_configRouterParams(-mtu) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-mtu)]} {
            set m_configRouterParams(-mtu) 1500
        }        
    }
    set mtu $m_configRouterParams(-mtu)

    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
         set m_configRouterParams(-active) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-active)]} {
            set m_configRouterParams(-active) 1
        }        
    }
    set active $m_configRouterParams(-active) 

    set index [lsearch $args -flaggracerestart]
    if {$index != -1} {
         set m_configRouterParams(-flaggracerestart) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-flaggracerestart)]} {
            set m_configRouterParams(-flaggracerestart) 0
        }        
    }
    set flaggracerestart $m_configRouterParams(-flaggracerestart)

    set index [lsearch $args -restartinterval]
    if {$index != -1} {
         set m_configRouterParams(-restartinterval) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-restartinterval)]} {
            set m_configRouterParams(-restartinterval) 0
        }        
    }
    set restartinterval $m_configRouterParams(-restartinterval)

    #added by yuanfen
    set index [lsearch $args -restarttype]
    if {$index != -1} {
         set m_configRouterParams(-restarttype) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-restarttype)]} {
            set m_configRouterParams(-restarttype) 0
        }        
    }
    set restarttype $m_configRouterParams(-restarttype)

    set index [lsearch $args -restartreason]
    if {$index != -1} {
         set m_configRouterParams(-restartreason) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-restartreason)]} {
            set m_configRouterParams(-restartreason) software
        }        
    }
    set restartreason $m_configRouterParams(-restartreason)    


    #Abstract authenticationtype from parameter list 
    set index [lsearch $args -authenticationtype]
    if {$index != -1} {
         set m_configRouterParams(-authenticationtype) [lindex $args [expr $index + 1]]
    } else {
        if {![info exist m_configRouterParams(-authenticationtype)]} {
            set m_configRouterParams(-authenticationtype) none
        }        
    }
    set authenticationtype $m_configRouterParams(-authenticationtype)

    #Abstract password from parameter list 
    set index [lsearch $args -password]
    if {$index != -1} {
         set m_configRouterParams(-password) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-password)]} {
            set m_configRouterParams(-password) Spirent
        }        
    }
    set password $m_configRouterParams(-password)

    #Abstract md5keyid from parameter list 
    set index [lsearch $args -md5keyid]
    if {$index != -1} {
         set m_configRouterParams(-md5keyid) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-md5keyid)]} {
            set m_configRouterParams(-md5keyid) 1
        }        
    }
    set md5keyid $m_configRouterParams(-md5keyid)

    #Abstract ViewRoutes from parameter list 
    set index [lsearch $args -viewroutes]
    if {$index != -1} {
         set m_configRouterParams(-ViewRoutes) [lindex $args [expr $index + 1]] 
    } else {
        if {![info exist m_configRouterParams(-ViewRoutes)]} {
            set m_configRouterParams(-ViewRoutes) "FALSE"
        }        
    }
    set m_viewRoutes $m_configRouterParams(-ViewRoutes)
    set ViewRoutes $m_configRouterParams(-ViewRoutes)
    
    
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
 
    #Config ipv4 interface of ospfv2 router
    stc::config $m_hIpv4If -Address $ipaddr\
                                      -PrefixLength $prefixlen\
                                      -Gateway [GetGatewayIp $ipaddr]
    
    
    #Config mtu interface of ospfv2 router       

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
    }         
    set hPort $::mainDefine::result 
            
    set phy [stc::get $hPort -SupportedPhys ]    
        
    if {$phy == "ETHERNET_COPPER"} {
         set hLinkConfig [stc::get $hPort -children-EthernetCopper] 
    } elseif {$phy == "ETHERNET_FIBER"} {
         set hLinkConfig [stc::get $hPort -children-EthernetFiber]          
    } elseif {$phy == "ETHERNET_10_GIG_FIBER"} {
         set hLinkConfig [stc::get $hPort -children-Ethernet10GigFiber]          
    } elseif {$phy == "ETHERNET_COPPER|ETHERNET_FIBER"} {
         
         set ::mainDefine::objectName $m_portName 
         uplevel 1 {         
             set ::mainDefine::result [$::mainDefine::objectName cget -m_mediaType]         
         }         
         set mediaType $::mainDefine::result 
    
       if {$mediaType == "ETHERNET_COPPER"} { 
           if {[stc::get $hPort -children-EthernetCopper] ==""} {
             set hLinkConfig [stc::create EthernetCopper -under $hPort]
           } else {
             set hLinkConfig [stc::get $hPort -children-EthernetCopper]
          }
       } elseif {$mediaType == "ETHERNET_FIBER"} {  
           if {[stc::get $hPort -children-EthernetFiber] ==""} {
             set hLinkConfig [stc::create EthernetFiber -under $hPort]
           } else {
             set hLinkConfig [stc::get $hPort -children-EthernetFiber]
          }       
       }           
    } else {
            error "this type of phy($phy) does not support MTU attr"
    }
    
    stc::config $hLinkConfig -Mtu $mtu      
    #Config routerId
    stc::config $m_hRouter -routerid $routerid
    #Config ospf router 
  
   eval stc::config $m_hOspfv2RouterConfig -AreaId $area\
                              -NetworkType $networktype\
                              -Options $pduoptionvalue\
                              -HelloInterval $hellointerval\
                              -RouterDeadInterval $deadinterval\
                              -RetransmitInterval $retransmitinterval\
                              -FloodDelay $transitdelay\
                              -IfCost $interfacecost\
                              -RouterPriority $routerpriority\
                              -Active [string map {0 false} [string map {1 true} $active]]   \
                              -EnableGracefulRestart $flaggracerestart\
                              -GracefulRestartType $restarttype \
                              -GracefulRestartReason $restartreason \
                              -GracefulRestartTimer $restartinterval \
                              -ViewRoutes $ViewRoutes
    
    #puts $restarttype"11"
    
    if {$authenticationtype == "simple"}  {
        set hOspfv2AuthenticationParams [stc::get $m_hOspfv2RouterConfig -children-Ospfv2AuthenticationParams]
        if {$hOspfv2AuthenticationParams == ""} {
            set hOspfv2AuthenticationParams [stc::create Ospfv2AuthenticationParams -under $m_hOspfv2RouterConfig]
        }
        stc::config $hOspfv2AuthenticationParams -Authentication $authenticationtype \
                              -Password $password                                                                 
    } elseif {$authenticationtype == "md5"} {
        set hOspfv2AuthenticationParams [stc::get $m_hOspfv2RouterConfig -children-Ospfv2AuthenticationParams]  
        
        if {$hOspfv2AuthenticationParams == ""} {
            set hOspfv2AuthenticationParams [stc::create Ospfv2AuthenticationParams -under $m_hOspfv2RouterConfig]
        }
       stc::config $hOspfv2AuthenticationParams -Authentication $authenticationtype -Password $password -Md5KeyId $md5keyid
    }
      
    if {[string tolower $m_portType]=="ethernet"} {
        set hEthIIIf $m_hL2If
        if {[info exists LocalMac]} {
            stc::config $hEthIIIf -SourceMac $m_LocalMac
        }
        if {[info exists LocalMacModifier]} {
            stc::config $hEthIIIf -SrcMacStep $m_LocalMacModifier
        }
   }

    #Find and config MAC address from host according to ipaddr 
    SetMacAddress $ipaddr
                       
    ApplyToChassis 

    #lappend m_topNameList $m_routerName
    #lappend m_routerList $m_routerName
    if {$m_addEmulatorAsTopoRtr<=0} {
        set m_topConfig($m_routerName,routerId) $m_routerId 
        Ospfv2Session::Ospfv2CreateTopRouter -routername $m_routerName -routerid $m_routerId -emulatedRtr yes
        set m_addEmulatorAsTopoRtr 1
    }
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetSession"    
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2RetrieveRouter
#
#Description: Get Attributes of Ospfv2 Router
#
#Input: None
#
#Output: Router Attributes
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveRouter {{args ""}} { 
set list ""
if {[catch { 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveRouter"
    #Return router configuration      
                                                                       
    array set list1 [stc::get $m_hOspfv2RouterConfig]  
    set args [ConvertAttrToLowerCase $args]
   
    set list ""
    foreach index [array names m_configRouterParams] {
        lappend list $index
        lappend list $m_configRouterParams($index)
    }
    lappend list -state
    lappend list $list1(-NeighborState)
    set list [ConvertAttrToLowerCase $list] 
    

    if {$args == ""} {
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveRouter"
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                        
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveRouter"
        return $::mainDefine::gSuccess
    }    
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
proc GenerateIncrIpAddr1 {ipStart  ipStep ipOffset} {
    set list [split $ipStart .]
    set sum [lindex $list 3]
    set sum [expr $sum + ([lindex $list 2] << 8)]
    set sum [expr $sum + ([lindex $list 1] << 16)]
    set sum [expr $sum + ([lindex $list 0] << 24)]

    set list [split $ipStep .]
    set sum1 [lindex $list 3]
    set sum1 [expr $sum1 + ([lindex $list 2] << 8)]
    set sum1 [expr $sum1 + ([lindex $list 1] << 16)]
    set sum1 [expr $sum1 + ([lindex $list 0] << 24)]

    #set sum1 [expr ($ipStep <<(32-$ipPrefix)) * $ipOffset]

    set sum [expr $sum + $sum1 * $ipOffset ]

    set bit0_7 [expr $sum & 0xff]
    set bit8_15 [expr ($sum >> 8) & 0xff ]
    set bit16_23 [expr ($sum >> 16) & 0xff ]
    set bit24_31 [expr ($sum >> 24) & 0xff ]

    return "$bit24_31.$bit16_23.$bit8_15.$bit0_7"

}
############################################################################
#APIName: Ospfv2CreateTopGrid
#
#Description: Create Grid in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateTopGrid {args}  {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopGrid"
    
    set lsaGenConfigList ""
    set gridConfigList ""
    #Abstract gridname from parameter list
    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
    } else {
       error "please specify GridName for CreateOspfv2Grid API"
    }
    #Check the uniqueness of gridName
    set index [lsearch $m_gridNameList -gridname]
    if {$index != -1} {
       error "The GridName($gridname) already existed,please specify another one, the existed GridName(s) is(are) as following:\\n$m_gridNameList"
    } 
    lappend m_topConfig($gridname) -gridname
    lappend m_topConfig($gridname) $gridname
    lappend m_gridNameList $gridname
    lappend gridConfigList -name
    lappend gridConfigList $gridname
    lappend m_topNameList $gridname

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract gridrows from parameter list
    set index [lsearch $args -gridrows]
    if {$index != -1} {
       set gridrows [lindex $args [expr $index + 1]]
    } else {
       set gridrows 1 
    }
    lappend m_topConfig($gridname) -gridrows 
    lappend m_topConfig($gridname) $gridrows
    lappend gridConfigList -Rows
    lappend gridConfigList $gridrows
    #Abstract gridcolumns from parameter list
    set index [lsearch $args -gridcolumns]
    if {$index != -1} {
       set gridcolumns [lindex $args [expr $index + 1]]
    } else {
       set gridcolumns 1 
    }
    lappend m_topConfig($gridname) -gridcolumns 
    lappend m_topConfig($gridname) $gridcolumns
    lappend gridConfigList -Columns
    lappend gridConfigList $gridcolumns    


    #Abstract gridlinktype from parameter list
    set index [lsearch $args -gridlinktype]
    if {$index != -1} {
       set gridlinktype [lindex $args [expr $index + 1]]
    } else {
       set gridlinktype  unumbered
    }
    lappend m_topConfig($gridname) -gridlinktype 
    lappend m_topConfig($gridname) $gridlinktype
    
    if {$gridlinktype == "numbered"} {
        lappend lsaGenConfigList -NumberedPointToPointLinkEnabled
        lappend lsaGenConfigList TRUE
    }

    #Abstract flagadvertise from parameter list
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]           
    } else {
       set flagadvertise  1
    }   
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    lappend m_topConfig($gridname) -flagadvertise 
    lappend m_topConfig($gridname) $flagadvertise   
    if {$flagadvertise == "false"} {
        lappend lsaGenConfigList -active 
        lappend lsaGenConfigList FALSE
    }
    #Abstract startingrouterid from parameter list 
    set index [lsearch $args -startingrouterid]
    if {$index != -1} {
       set startingrouterid [lindex $args [expr $index + 1]]
    } else {
       set startingrouterid 1.1.1.1
    }
    lappend m_topConfig($gridname) -startingrouterid 
    lappend m_topConfig($gridname) $startingrouterid
    lappend lsaGenConfigList  -RouterIdStart
    lappend lsaGenConfigList  $startingrouterid 

    #Abstract routeridstep from parameter list   
    set index [lsearch $args -routeridstep]
    if {$index != -1} {
       set routeridstep [lindex $args [expr $index + 1]]
    } else {
       set routeridstep 0.0.0.1
    }
    lappend m_topConfig($gridname) -routeridstep 
    lappend m_topConfig($gridname) $routeridstep
    lappend lsaGenConfigList  -RouterIdStep
    lappend lsaGenConfigList  $routeridstep
    
    set index [lsearch $args -startingteinterface]
    if {$index != -1} {
       set startingteinterface [lindex $args [expr $index + 1]]
    } else {
       set startingteinterface auto
    }
    lappend m_topConfig($gridname) -startingteinterface 
    lappend m_topConfig($gridname) $startingteinterface   

    set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
       set flagte 0
    }
    lappend m_topConfig($gridname) -flagte 
    lappend m_topConfig($gridname) $flagte   

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect 1
    }   
    lappend m_topConfig($gridname) -flagautoconnect 
    lappend m_topConfig($gridname) $flagautoconnect   

    set configBefore [stc::get $m_hOspfv2RouterConfig -children-routerlsa]
    
    #Create Ospfv2LsaGenParams
    set hOspfv2LsaGenParams [eval stc::create Ospfv2LsaGenParams  \
                                     -under $m_hProject\
                                     -SelectedRouterRelation-Targets $m_hRouter\
                                     $lsaGenConfigList ]
     set m_hLsaArrIndexedByTopName($gridname,parent)  $hOspfv2LsaGenParams                                                                                  
                                                                                 
    
   #Create GridTopologyGenParams
   set m_hGridTopologyGenParams [eval stc::create GridTopologyGenParams \
                          -under $hOspfv2LsaGenParams\
                          $gridConfigList ]      

   if {($flagautoconnect == 1)||($flagautoconnect == "on")||($flagautoconnect == "enable")||($flagautoconnect == "yes")} {
      stc::config $m_hGridTopologyGenParams \
                      -EmulatedRouterPos ATTACHED_TO_GRID \
                      -AttachColumnIndex 1 \
                      -AttachRowIndex 1    
   }                                                                                   
   set m_hLsaArrIndexedByTopName($gridname)  $m_hGridTopologyGenParams                                                                                   
     
   #Create lsa related with topo
   stc::perform RouteGenApply -GenParams $hOspfv2LsaGenParams -DeleteRoutesOnApply no

   #Delete link between Simulater and Grid
   if {!(($flagautoconnect == 1)||($flagautoconnect == "on")||($flagautoconnect == "enable")||($flagautoconnect == "yes"))} {   
       set hLinkList [stc::get $m_hSimulatorRouter -children]
       foreach hLink $hLinkList {
             set linkId [stc::get $hLink  -LinkId]
             if  {$linkId == $startingrouterid} {
                 stc::delete $hLink
             }
       }
   }
   
   #Collect information about Grid Router, such as grid router name, router id, lsa handle and so on
   set gridRouterIdList ""
   for {set i 1} {$i <=  $gridrows} {incr i} {
       for {set j 1} {$j <=  $gridcolumns} {incr j} { 
           set routername gridRouter-$gridname-$i-$j
           lappend m_gridRouterNameArrList($gridname) $routername
           lappend m_routerList $routername
           lappend m_topNameList $routername
           set offset [expr ($i - 1) * $gridcolumns + $j -1]
           set m_topConfig($routername,routerId) [GenerateIncrIpAddr1 $startingrouterid  $routeridstep $offset]
           lappend gridRouterIdList $m_topConfig($routername,routerId)
           set routerId2RouteNameArr($m_topConfig($routername,routerId)) $routername
           set m_topConfig($gridname,$i,$j) $routername
           lappend m_topConfig($routername)  -routerid 
           lappend m_topConfig($routername) $m_topConfig($routername,routerId)
           lappend m_topConfig($routername) -flagadvertise
           lappend m_topConfig($routername)  true
           lappend m_topConfig($routername) -linknum
           lappend m_topConfig($routername) 0
           lappend m_topConfig($routername) -linknamelist
           lappend m_topConfig($routername) ""
       }
   }        

   #puts "Generate the corresponding relation between routername and routerlsa"
    set hLsaList [stc::get $m_hOspfv2RouterConfig  -children]    
    foreach hLsa $hLsaList {
        catch {        
        catch {array unset temp}
        array set temp [stc::get $hLsa ]
        if {![info exists temp(-AdvertisingRouterId)]} { continue }
         set advRouterId [stc::get $hLsa -AdvertisingRouterId]
         set index [lsearch $gridRouterIdList $advRouterId] 
         if {$index != -1} {
             set routername $routerId2RouteNameArr($advRouterId)
             set  m_hLsaArrIndexedByTopName($routername) $hLsa
         }
        }
    } 
   #puts "Delete link between gridrouter and simulater"
    if {!(($flagautoconnect == 1)||($flagautoconnect == "on")||($flagautoconnect == "enable")||($flagautoconnect == "yes"))} {   
        set routername  $routerId2RouteNameArr($startingrouterid)
        set hLinkList [stc::get $m_hLsaArrIndexedByTopName($routername) -children]
        foreach hLink $hLinkList {
            set linkId [stc::get $hLink -linkId]
            if {$linkId == $m_routerId} {
                stc::delete $hLink
                break
            }
        }
    }      
   
    array set arr $m_topConfig($gridname)
    set flagadvertise $arr(-flagadvertise)
    set flagadvertise true
    if {$flagadvertise == "true"} {                     
        ApplyToChassis
    }

    set configAfter [stc::get $m_hOspfv2RouterConfig -children-routerlsa]
    set m_hLsaArrIndexedByTopName($gridname,lsa) ""
    foreach config $configAfter {
        set index [lsearch $configBefore $config]
        if {$index == -1} {
            lappend m_hLsaArrIndexedByTopName($gridname,lsa) $config
        }
    }    
   
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopGrid"    
    return $::mainDefine::gSuccess

    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2RetrieveTopGrid
#
#Description: Get name handler of Grid
#
#Input: 1.gridname:Name handler of Grid
#
#Output: Attributes of grid
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveTopGrid {args}  {
set list ""
if {[catch { 

    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopGrid"
    #Abstract gridname from parameter list   
    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify GridName for CreateOspfv2Grid API"
    }
    #Check existence of gridname
    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
       error "The GridName($gridname) does not exist, the existed GridName(s) is(are) as following:\\n$m_gridName"
    } 

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]  
    set list $m_topConfig($gridname)

    set list [ConvertAttrToLowerCase1 $list] 
    
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopGrid"                         
       return $::mainDefine::gSuccess
    }
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2DeleteTopGrid
#
#Description: delete the specified Ospf Grid
#
#Input: 1.gridname:Name handler of grid  
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopGrid {args}  {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopGrid"
    #Abstract gridname from parameter list   
    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
    } else {
       error "please specify GridName for CreateOspfv2Grid API"
    }
    #check the existence of grid
    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
       error "The GridName($gridname) does not exist, the existed GridName(s) is(are) as following:\n$m_gridNameList"
    } 
    set m_gridNameList [lreplace $m_gridNameList $index $index]
    set index [lsearch $m_topNameList $gridname]
    set m_topNameList [lreplace $m_topNameList $index $index]
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #set m_gridNameList [lindex $m_gridNameList $index $index]
    #Delete grid
    stc::delete  $m_hLsaArrIndexedByTopName($gridname)      
    stc::delete  $m_hLsaArrIndexedByTopName($gridname,parent) 
    #stc::perform RouteGenApply -GenParams $m_hLsaArrIndexedByTopName($gridname,parent)  -DeleteRoutesOnApply no
    foreach lsa $m_hLsaArrIndexedByTopName($gridname,lsa) {
        catch {stc::delete $lsa}
    }
     
    ApplyToChassis
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopGrid"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2RetrieveTopGridRouter
#
#Description: Get the configuration of TopGridRouter
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2RetrieveTopGridRouter {args} {
set list ""
if {[catch { 

    set args [ConvertAttrToLowerCase $args] 

    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopGridRouter"
    #Abstract gridname from parameter list   
    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
    } else {
       error "please specify GridName for CreateOspfv2Grid API"
    }
    #Check the existence of grid
    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
       error "The GridName($gridname) does not exist, the existed GridName(s) is(are) as following:\n$m_gridNameList"
    } 

    #Abstract routername from parameter list   
    set index [lsearch $args -routername]
    if {$index == -1}  {
       error "please specify routername for Ospfv2RetrieveTopGridRouter API"
    }     
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

  
    set index [lsearch $m_topConfig($gridname) -gridrows]
    set GridRows [lindex $m_topConfig($gridname)  [incr index]]

    set index [lsearch $m_topConfig($gridname) -gridcolumns]
    set GridColumns [lindex $m_topConfig($gridname)  [incr index]]
    
    #Abstract row from parameter list 
    set index [lsearch $args -row]
    if {$index != -1} {
       set row [lindex $args [expr $index + 1]]      
    } else {
       error "please specify row for Ospfv2RetrieveTopGridRouter API"
    }
    if {$row >$GridRows} {
       error "row can not be geater than GridRows($GridRows)"
    }

    #Abstract column from parameter list 
    set index [lsearch $args -column]
    if {$index != -1} {
       set column [lindex $args [expr $index + 1]]       
    } else {
       error "please specify column for Ospfv2RetrieveTopGridRouter API"
    }  
    if {$column >$GridColumns} {
       error "column can not be geater than GridColumns($GridColumns)"
    }            

    set ::mainDefine::routername $routername
    set ::mainDefine::routername1 $m_topConfig($gridname,$row,$column)  
    uplevel 1 {
        set $::mainDefine::routername $::mainDefine::routername1 
    }
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopGridRouter"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}


proc GenerateIncrIpAddr {ipStart ipPrefix ipStep ipOffset} {
    set list [split $ipStart .]
    set sum [lindex $list 3]
    set sum [expr $sum + ([lindex $list 2] << 8)]
    set sum [expr $sum + ([lindex $list 1] << 16)]
    set sum [expr $sum + ([lindex $list 0] << 24)]

    set sum1 [expr ($ipStep <<(32-$ipPrefix)) * $ipOffset]

    set sum [expr $sum + $sum1 ]

    set bit0_7 [expr $sum & 0xff]
    set bit8_15 [expr ($sum >> 8) & 0xff ]
    set bit16_23 [expr ($sum >> 16) & 0xff ]
    set bit24_31 [expr ($sum >> 24) & 0xff ]

    return "$bit24_31.$bit16_23.$bit8_15.$bit0_7"
}

############################################################################
#APIName: Ospfv2CreateRouterLsa
#
#Description: Create RouterLsa in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateRouterLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateRouterLsa"
    
    set stcAttrConfigList ""
    #Abstract lsaname  from parameter list  
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for CreateOspfv2RouterLsa API"
    }
   
    #Check the uniqueness of lsaname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index != -1} {
       error "The lsaname($lsaname) is already existed, please specify another one,the existed GridName(s) is(are) as following:\n$m_lsaNameList"
    }
    lappend m_lsaNameList $lsaname
    lappend m_lsaConfig($lsaname) -lsaname
    lappend m_lsaConfig($lsaname) $lsaname

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract advertisingrouter from parameter list   
    set index [lsearch $args -advertisingrouter]
    if {$index != -1} {
       set advertisingrouter [lindex $args [expr $index + 1]]         
    } else {
       set advertisingrouter $m_routerId  
    }
    lappend m_lsaConfig($lsaname) -advertisingrouter
    lappend m_lsaConfig($lsaname) $advertisingrouter   
    lappend stcAttrConfigList -AdvertisingRouterId
    lappend stcAttrConfigList $advertisingrouter
    #Abstract linkstateid  from parameter list  
    set index [lsearch $args -linkstateid]
    if {$index != -1} {
       set linkstateid [lindex $args [expr $index + 1]]       
    } else {
       set linkstateid $advertisingrouter
    }
    lappend m_lsaConfig($lsaname) -linkstateid
    lappend m_lsaConfig($lsaname) $linkstateid
    lappend stcAttrConfigList -LinkStateId
    lappend stcAttrConfigList $linkstateid
    
    #Abstract abr/asbr  from parameter list  
    set index [lsearch $args -abr]
    if {$index != -1} {
        set abr [lindex $args [expr $index + 1]]
        set abr [string map {1 true} $abr]
        set abr [string map {0 false} $abr]
        lappend m_lsaConfig($lsaname) -abr
        lappend m_lsaConfig($lsaname) $abr
        lappend stcAttrConfigList -abr
        lappend stcAttrConfigList $abr
    }
    set index [lsearch $args -asbr]
    if {$index != -1} {
        set asbr [lindex $args [expr $index + 1]]
        set asbr [string map {1 true} $asbr]
        set asbr [string map {0 false} $asbr]
        lappend m_lsaConfig($lsaname) -asbr
        lappend m_lsaConfig($lsaname) $asbr
        lappend stcAttrConfigList -asbr
        lappend stcAttrConfigList $asbr
    }
    
    #Abstract flagadvertise   from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise  1
    }
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    lappend m_lsaConfig($lsaname) -flagadvertise
    lappend m_lsaConfig($lsaname) $flagadvertise

    #Abstract flagadvertise from parameter list   
    set index [lsearch $args -flagwithdraw]
    if {$index != -1} {
       set flagwithdraw [lindex $args [expr $index + 1]]
    } else {
       set flagwithdraw  0
    }
    lappend m_lsaConfig($lsaname) -flagwithdraw
    lappend m_lsaConfig($lsaname) $flagwithdraw  

    lappend m_lsaConfig($lsaname) -numlink
    lappend m_lsaConfig($lsaname) 0
    
    #Create RouterLsa
    if {$advertisingrouter==$m_routerId} {
        set m_hLsaArrIndexedByLsaName($lsaname) $m_hSimulatorRouter
        eval stc::config $m_hSimulatorRouter $stcAttrConfigList
    } else {
        set m_hLsaArrIndexedByLsaName($lsaname) [eval stc::create RouterLsa  \
                      -under $m_hOspfv2RouterConfig\
                      $stcAttrConfigList ]
    }
    lappend m_lsaConfig($lsaname)  -lsatype
    lappend m_lsaConfig($lsaname) routerlsa                                                                              

    array set arr $m_lsaConfig($lsaname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == "true"} {
        ApplyToChassis
    }
                                                              
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateRouterLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateRouterLsaLink
#
#Description: Add Link to RouterLsa
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateRouterLsaLink {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateRouterLsaLink"    
    #Abstract lsaname from parameter list   
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2CreateRouterLsaLink API"
    }

    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist,the existed lsaname(s) is(are) as following:\n$m_lsaNameList"
    }
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

        set  stcAttrConfig ""   

        #Abstract linkid from parameter list  
        set index [lsearch $args -linkid]
        if {$index != -1} {
           set linkid [lindex $args [expr $index + 1]]
        } else {
           error "please specify linkId for Ospfv2CreateRouterLsaLink API"
        }
        lappend stcAttrConfig -linkid
        lappend stcAttrConfig $linkid

        #Abstract linkid from parameter list   
        set index [lsearch $args -linkdata]
        if {$index != -1} {
           set linkdata [lindex $args [expr $index + 1]]
            lappend stcAttrConfig -linkdata
            lappend stcAttrConfig $linkdata          
        } else {
            set linkdata "255.255.255.255"
        }
      
        #Abstract linktype from parameter list   
        set index [lsearch $args -linktype]
        if {$index != -1} {
           set linktype [lindex $args [expr $index + 1]]
        } else {
           set linktype POINT_TO_POINT 
        }
        set linktype [string map {p2p POINT_TO_POINT} $linktype]
        set linktype [string map {transit TRANSIT_NETWORK} $linktype]
        set linktype [string map {stub STUB_NETWORK} $linktype]
        
        lappend stcAttrConfig -linktype
        lappend stcAttrConfig $linktype
        #Abstract metric from parameter list   
        set index [lsearch $args -metric]
        if {$index != -1} {
           set metric [lindex $args [expr $index + 1]]
        } else {
           set metric 1 
        }
        lappend stcAttrConfig -metric
        lappend stcAttrConfig $metric 
        #Create RouterLsaLink
        set hRouterLsaLink [ stc::create RouterLsaLink -under $m_hLsaArrIndexedByLsaName($lsaname)  \
                                                  -linkid $linkid\
                                                  -linktype $linktype\
                                                  -metric $metric\
                                                  -linkdata $linkdata \
                                                  ]
        set hIpv4NetworkBlock [lindex [stc::get $hRouterLsaLink -children-Ipv4NetworkBlock] 0]
        stc::config $hIpv4NetworkBlock\
                -StartIpList $linkid \
                -PrefixLength "32" \
                -NetworkCount "1"
       
        ApplyToChassis 
        after 2000
  
        debugPut "exit the proc of Ospfv2Session::Ospfv2CreateRouterLsaLink"       
        return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2DeleteRouterLsa
#
#Description: Delete RouterLsa
#
#Input: 1.lsaname:Name handler of RouterLsa
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteRouterLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteRouterLsa"
    
    #Abstract lsaname from parameter list       
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2DeleteRouterLsa API"
    }   
    #Check the existence of lsaname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist,the existed GridName(s) is(are) as following:\n$m_lsaNameList"
    }
    set m_lsaNameList [lreplace $m_lsaNameList $index $index ]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Delete the specified lsa of lsaname
    stc::delete $m_hLsaArrIndexedByLsaName($lsaname)

    ApplyToChassis
      
    catch {unset m_hLsaArrIndexedByLsaName($lsaname)}
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteRouterLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2CreateNetworkLsa
#
#Description: Create NetworkLsa in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateNetworkLsa  {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 

    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateNetworkLsa"
    
    set stcAttrConfig ""
   #Abstract lsaname from parameter list   
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2CreateNetworkLsa API"
    }
   
    #Check the uniqueness of lsaname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index != -1} {
       error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\n$m_lsaNameList"
    }
    lappend m_lsaNameList $lsaname
    lappend m_lsaConfig($lsaname) -lsaname
    lappend m_lsaConfig($lsaname) $lsaname
    lappend stcAttrConfig -name 
    lappend stcAttrConfig $lsaname     

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract advertisingrouter from parameter list   
    set index [lsearch $args -advertisingrouter]
    if {$index != -1} {
       set advertisingrouter [lindex $args [expr $index + 1]]
    } else {
       set advertisingrouter $m_routerIp
    }
    lappend m_lsaConfig($lsaname) -advertisingrouter
    lappend m_lsaConfig($lsaname) $advertisingrouter
    lappend stcAttrConfig -AdvertisingRouterId 
    lappend stcAttrConfig $advertisingrouter

    #Abstract linkstateid from parameter list   
    set index [lsearch $args -linkstateid]
    if {$index != -1} {
       set linkstateid [lindex $args [expr $index + 1]]
    } else {
       error "please specify linkstateid for Ospfv2CreateNetworkLsa"
    }
    lappend m_lsaConfig($lsaname) -linkstateid
    lappend m_lsaConfig($lsaname) $linkstateid
    lappend stcAttrConfig -linkstateid 
    lappend stcAttrConfig $linkstateid   
    #Abstract prefixlength from parameter list   
    set index [lsearch $args -prefixlength]
    if {$index != -1} {
       set prefixlength [lindex $args [expr $index + 1]]
    } else {
       set prefixlength 24
    }
    lappend m_lsaConfig($lsaname) -prefixlength
    lappend m_lsaConfig($lsaname) $prefixlength
    lappend stcAttrConfig -prefixlength 
    lappend stcAttrConfig $prefixlength
  
    
    #Abstract flagadvertise from parameter list   
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    lappend m_lsaConfig($lsaname) -flagadvertise
    lappend m_lsaConfig($lsaname) $flagadvertise
    if {$flagadvertise == "false"} {
        lappend stcAttrConfig -active 
        lappend stcAttrConfig FALSE
    }
    #Abstract flagwithdraw from parameter list   
    set index [lsearch $args -flagwithdraw]
    if {$index != -1} {
       set flagwithdraw [lindex $args [expr $index + 1]]
    } else {
       set flagwithdraw 0
    }
    lappend m_lsaConfig($lsaname) -flagwithdraw
    lappend m_lsaConfig($lsaname) $flagwithdraw     

    #Create NetworkLsa
    set m_hLsaArrIndexedByLsaName($lsaname) [eval stc::create NetworkLsa   \
                                       -under $m_hOspfv2RouterConfig\
                                       $stcAttrConfig]
                                                                                  
    lappend m_lsaConfig($lsaname)  -lsatype
    lappend m_lsaConfig($lsaname) networklsa

    array set arr $m_lsaConfig($lsaname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == "true"} {
        ApplyToChassis
    }                                                                           

    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateNetworkLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateNetworkLsaRouter
#
#Description: Add Router to NetworkLsa
#
#Input:Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateNetworkLsaRouter {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateNetworkLsaRouter"
    
    #Abstract lsaname from parameter list   
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2CreateNetworkLsaRouter API"
    }
   
   #Abstract flagadvertise from parameter list   
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist, the existed lsaname(s) is(are) as following:\n$m_lsaNameList"
    }
    #Abstract routeridlist from parameter list   
    set index [lsearch $args -routerid]
    if {$index != -1} {
       set routeridlist [lindex $args [expr $index + 1]]
    } else {
       error "please specify routerid for Ospfv2CreateNetworkLsaRouter API"
    }    

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    foreach routerId $routeridlist {
        #Create NetworkLsaLink
        stc::create  NetworkLsaLink -under $m_hLsaArrIndexedByLsaName($lsaname) -LinkId $routerId             
    }
    
    #Abstract flagadvertise from parameter list   
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }

    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    
    if {$flagadvertise == "true"} {
        ApplyToChassis
    }
    after 2000
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateNetworkLsaRouter"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2DeleteNetworkLsa
#
#Description: Delete specified NetworkLsa
#
#Input: 1.lsaname:Name handler of NetworkLsa
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteNetworkLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteNetworkLsa"
     #Abstract lsaname from parameter list          
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2DeleteNetworkLsa API"
    }   
    #Create existence of lsanme
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist,the existed GridName(s) is(are) as following:\n$m_lsaNameList"
    }
    set m_lsaNameList [lreplace $m_lsaNameList $index $index ]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #delete lsa
    stc::delete $m_hLsaArrIndexedByLsaName($lsaname)

    ApplyToChassis    
    catch {unset m_hLsaArrIndexedByLsaName($lsaname)}
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteNetworkLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateAsExtLsa
#
#Description: Create AsExtLsa in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateAsExtLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateAsExtLsa"
    
    set stcAttrConfig ""
    #Abstract lsaname  from parameter list  
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2CreateAsExtLsa API"
    }
   
    #Check the existence of lsaname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index != -1} {
       error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\n$m_lsaNameList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
       
    #Abstract advertisingrouter  from parameter list  
    set index [lsearch $args -advertisingrouter]
    if {$index != -1} {
       set advertisingrouter [lindex $args [expr $index + 1]]
    } else {
       error "please specify advertisingrouter for Ospfv2CreateAsExtLsa"
    }

    #Abstract firstaddress from parameter list 
    set index [lsearch $args -firstaddress]
    if {$index != -1} {
       set firstaddress [lindex $args [expr $index + 1]]
    } else {
       error "please specify firstaddress for Ospfv2CreateAsExtLsa"
    }

    lappend m_lsaNameList $lsaname
    lappend m_lsaConfig($lsaname) -lsaname
    lappend m_lsaConfig($lsaname) $lsaname
    lappend stcAttrConfig -name 
    lappend stcAttrConfig $lsaname 

    lappend m_lsaConfig($lsaname) -advertisingrouter
    lappend m_lsaConfig($lsaname) $advertisingrouter
    lappend stcAttrConfig -AdvertisingRouterId 
    lappend stcAttrConfig $m_routerId

    #Abstract advertisingrouter from parameter list 
    set index [lsearch $args -type]
    if {$index != -1} {
       set type [lindex $args [expr $index + 1]]
    } else {
       set type ext
    }
    lappend m_lsaConfig($lsaname) -type
    lappend m_lsaConfig($lsaname) $type
    lappend stcAttrConfig -type 
    lappend stcAttrConfig $type
    
    #Abstract metric from parameter list   
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    lappend m_lsaConfig($lsaname) -metric
    lappend m_lsaConfig($lsaname) $metric
    lappend stcAttrConfig -metric 
    lappend stcAttrConfig $metric 
    #Abstract prefixlength from parameter list 
    set index [lsearch $args -prefixlength]
    if {$index != -1} {
       set prefixlength [lindex $args [expr $index + 1]]
    } else {
       set prefixlength 24
    }
    lappend m_lsaConfig($lsaname) -prefixlength
    lappend m_lsaConfig($lsaname) $prefixlength
    #Abstract flagebit  from parameter list
    set index [lsearch $args -flagebit]
    if {$index != -1} {
       set flagebit [lindex $args [expr $index + 1]]
    } else {
       set flagebit 0
    }
    set flagebit [string map {0 false} $flagebit]
    set flagebit [string map {disable false} $flagebit]
    set flagebit [string map {off false} $flagebit]
    set flagebit [string map {1 true} $flagebit]
    set flagebit [string map {enable true} $flagebit]
    set flagebit [string map {on true} $flagebit]
    
    lappend m_lsaConfig($lsaname) -flagebit
    lappend m_lsaConfig($lsaname) $flagebit
    
    if {$flagebit == "true"} {
        lappend stcAttrConfig -Options 
        lappend stcAttrConfig EBIT
    }    

    #Abstract flagebit from parameter list 
    set index [lsearch $args -flagnpbit]
    if {$index != -1} {
       set flagnpbit [lindex $args [expr $index + 1]]
    } else {
       set flagnpbit 0
    }
    set flagnpbit [string map {0 false} $flagnpbit]
    set flagnpbit [string map {disable false} $flagnpbit]
    set flagnpbit [string map {off false} $flagnpbit]
    set flagnpbit [string map {1 true} $flagnpbit]
    set flagnpbit [string map {enable true} $flagnpbit]
    set flagnpbit [string map {on true} $flagnpbit]
    
    lappend m_lsaConfig($lsaname) -flagnpbit
    lappend m_lsaConfig($lsaname) $flagnpbit

    if {$flagebit == "true"} {
        lappend stcAttrConfig -Options 
        lappend stcAttrConfig NPBIT
    }  
    
    #Abstract flagadvertise from parameter list  
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    lappend m_lsaConfig($lsaname) -flagadvertise
    lappend m_lsaConfig($lsaname) $flagadvertise
    if {$flagadvertise == "false"} {
        lappend stcAttrConfig -active 
        lappend stcAttrConfig FALSE
    }

    #Abstract flagadvertise from parameter list  
    set index [lsearch $args -flagadwithdraw]
    if {$index != -1} {
       set flagadwithdraw [lindex $args [expr $index + 1]]
    } else {
       set flagadwithdraw 0
    }
    lappend m_lsaConfig($lsaname) -flagadwithdraw
    lappend m_lsaConfig($lsaname) $flagadwithdraw
    
    lappend m_lsaConfig($lsaname) -firstaddress
    lappend m_lsaConfig($lsaname) $firstaddress
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier 1
    }
    lappend m_lsaConfig($lsaname) -modifier
    lappend m_lsaConfig($lsaname) $modifier
    #Abstract numaddress from parameter list 
    set index [lsearch $args -numaddress]
    if {$index != -1} {
       set numaddress [lindex $args [expr $index + 1]]
    } else {
       set numaddress 1
    }
    lappend m_lsaConfig($lsaname) -numaddress
    lappend m_lsaConfig($lsaname) $numaddress
   
    #Abstract forwardingaddress from parameter list 
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
    } else {
       set forwardingaddress 0.0.0.0
    }
    lappend m_lsaConfig($lsaname) -forwardingaddress
    lappend m_lsaConfig($lsaname) $forwardingaddress

    #Abstract externaltag from parameter list
    set index [lsearch $args -externaltag]
    if {$index != -1} {
       set externaltag [lindex $args [expr $index + 1]]
    } else {
       set externaltag 0
    }
    lappend m_lsaConfig($lsaname) -externaltag
    lappend m_lsaConfig($lsaname) $externaltag
    lappend stcAttrConfig -RouteTag 
    lappend stcAttrConfig $externaltag
 
    #Create ExternalLsaBlock
    set m_hLsaArrIndexedByLsaName($lsaname) [eval stc::create ExternalLsaBlock   \
                                          -under $m_hOspfv2RouterConfig\
                                          $stcAttrConfig]
    if {$type != "ext"} {
        stc::config $m_hOspfv2RouterConfig -Options NPBIT
        
    }                                                                              
    #Config Ipv4NetworkBlock                                                                              
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv4NetworkBlock]     
    stc::config $hIpv4NetworkBlock -NetworkCount $numaddress \
                                                       -PrefixLength $prefixlength \
                                                       -StartIpList $firstaddress\
                                                       -AddrIncrement $modifier
    set ::mainDefine::gPoolCfgBlock($lsaname) $hIpv4NetworkBlock
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  extlsa                                                       

    array set arr $m_lsaConfig($lsaname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == "true"} {
        ApplyToChassis
    }                                                   
       
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateAsExtLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2DeleteAsExtLsa
#
#Description: Delete specified ExtAsLsa
#
#Input: 1.lsaname:Name handler of ExtAsLsa
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteAsExtLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteAsExtLsa"
    #Abstract lsaname from parameter list     
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2DeleteAsExtLsa API"
    }   
    #Check the existence of lasname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist,the existed GridName(s) is(are) as following:\n$m_lsaNameList"
    }
    set m_lsaNameList [lreplace $m_lsaNameList $index $index ]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #delete lsa
    stc::delete $m_hLsaArrIndexedByLsaName($lsaname)

    ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByLsaName($lsaname)}
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteAsExtLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateSummaryLsa
#
#Description: Create SummaryLsa in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateSummaryLsa {args} {
set list ""
if {[catch { 

   set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateSummaryLsa"
    
    set stcAttrConfig ""
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2CreateSummaryLsa API"
    }   

    set index [lsearch $m_lsaNameList $lsaname]
    if {$index != -1} {
       error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\n$m_lsaNameList"
    }
         
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
   
    #Abstract advertisingrouter from parameter list 
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       #error "please specify advertisingrouter for Ospfv2CreateSummaryLsa"
       set advertisingrouterid $m_routerId
    }

    #Abstract firstaddress from parameter list 
    set index [lsearch $args -firstaddress]
    if {$index != -1} {
       set firstaddress [lindex $args [expr $index + 1]]
    } else {
      error "please specify firstaddress for Ospfv2CreateSummaryLsa"
    }

    lappend m_lsaNameList $lsaname
    lappend m_lsaConfig($lsaname) -lsaname
    lappend m_lsaConfig($lsaname) $lsaname
    lappend stcAttrConfig -name 
    lappend stcAttrConfig $lsaname

    #lappend m_lsaConfig($lsaname) -advertisingrouter
    #lappend m_lsaConfig($lsaname) $advertisingrouter
    lappend stcAttrConfig -AdvertisingRouterId 
    lappend stcAttrConfig $advertisingrouterid
    #Abstract metric from parameter list   
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    lappend m_lsaConfig($lsaname) -metric
    lappend m_lsaConfig($lsaname) $metric
    lappend stcAttrConfig -metric 
    lappend stcAttrConfig $metric 
    #Abstract prefixlength from parameter list 
    set index [lsearch $args -prefixlength]
    if {$index != -1} {
       set prefixlength [lindex $args [expr $index + 1]]
    } else {
       set prefixlength 24
    }
    lappend m_lsaConfig($lsaname) -prefixlength
    lappend m_lsaConfig($lsaname) $prefixlength      
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    lappend m_lsaConfig($lsaname) -flagadvertise
    lappend m_lsaConfig($lsaname) $flagadvertise
    if {$flagadvertise == "false"} {
        lappend stcAttrConfig -active 
        lappend stcAttrConfig FALSE
    }
     
    lappend m_lsaConfig($lsaname) -firstaddress
    lappend m_lsaConfig($lsaname) $firstaddress
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier 1
    }
    lappend m_lsaConfig($lsaname) -modifier
    lappend m_lsaConfig($lsaname) $modifier
    #Abstract numaddress from parameter list 
    set index [lsearch $args -numaddress]
    if {$index != -1} {
       set numaddress [lindex $args [expr $index + 1]]
    } else {
       set numaddress 1
    }
    lappend m_lsaConfig($lsaname) -numaddress
    lappend m_lsaConfig($lsaname) $numaddress
   

    #Create SummaryLsaBlock
    set m_hLsaArrIndexedByLsaName($lsaname) [eval stc::create SummaryLsaBlock   \
                              -under $m_hOspfv2RouterConfig\
                              $stcAttrConfig]
    #Config Ipv4NetworkBlock                                                                             
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv4NetworkBlock]     
    stc::config $hIpv4NetworkBlock -NetworkCount $numaddress \
                                                       -PrefixLength $prefixlength \
                                                       -StartIpList $firstaddress\
                                                       -AddrIncrement $modifier
    set ::mainDefine::gPoolCfgBlock($lsaname) $hIpv4NetworkBlock
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  summarylsa
    
    array set arr $m_lsaConfig($lsaname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == "true"} {
        ApplyToChassis
    }
  
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateSummaryLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: RemoveOspfSummaryLsa
#
#Description: Delete specified SummaryLsa
#
#Input: 1.lsaname:Name handler of lsa
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteSummaryLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteSummaryLsa"
    
    #Abstract lsaname from parameter list     
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       error "please specify lsaname for Ospfv2DeleteSummaryLsa API"
    }   
    #Check the existence of lsaname
    set index [lsearch $m_lsaNameList $lsaname]
    if {$index == -1} {
       error "The lsaname($lsaname) does not exist,the existed GridName(s) is(are) as following:\n$m_lsaNameList"
    }
    set m_lsaNameList [lreplace $m_lsaNameList $index $index ]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #delete lsa
    stc::delete $m_hLsaArrIndexedByLsaName($lsaname)
    ApplyToChassis
    catch {unset m_hLsaArrIndexedByLsaName($lsaname)}
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteSummaryLsa"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2RetrieveRouterStats
#
#Description: Get current statistics of Ospfv2 Router
#
#Input:None 
#
#Output: Current statistics of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveRouterStats {{args ""}} {
set list ""
if {[catch { 
   
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveRouterStats"
    set args [ConvertAttrToLowerCase $args]
    set index [lsearch $::mainDefine::gObjectNameList "*$m_portName"]   
    if { $index >= 0 } {
        set gPortName [lindex $::mainDefine::gObjectNameList $index]
    } else {
        error "port object can not be found in gObjectNameList"   
    }    
    
    set chassisName [$gPortName cget -m_chassisName]
    set index [lsearch $::mainDefine::gObjectNameList "*$chassisName"]   
    if { $index >= 0 } {
        set gChassisName [lindex $::mainDefine::gObjectNameList $index]
    } else {
        error "chassis object can not be found in gObjectNameList"   
    }
    set m_hResultDataSet [$gChassisName cget -m_ospfv2RouterResultHandle ]
    #Update statistics of ospf router
    stc::perform RefreshResultView -ResultDataSet $m_hResultDataSet     
    set waitTime 2000
    after $waitTime
    #Get and return statistics of rsvp router
    set resultHandleList [stc::get $m_hResultDataSet -ResultHandleList]
    set resultHandle ""
    foreach handle $resultHandleList {
        set parent [stc::get $handle -parent]
        if {$parent == $m_hOspfv2RouterConfig} {
             set resultHandle $handle
             break
        }
    }
    if {$resultHandle == ""} {return}

    #Get and return statistics of ospf router
    set list ""
    array set list1  [stc::get $resultHandle]
    lappend list -NumHelloReceived
    lappend list $list1(-RxHello)
    lappend list -NumDbdReceived
    lappend list $list1(-RxDd)
    lappend list -NumRtrLsaReceived
    lappend list $list1(-RxRouterLsa)
    lappend list -NumNetLsaReceived
    lappend list $list1(-RxNetworkLsa)
    lappend list -NumSum4LsaReceived
    lappend list $list1(-RxAsbrSummaryLsa)
    lappend list -NumSum3LsaReceived
    lappend list $list1(-RxSummaryLsa)
    lappend list -NumExtLsaReceived
    lappend list $list1(-RxAsExternalLsa)
    lappend list -NumType7LsaReceived
    lappend list $list1(-RxNssaLsa)

    lappend list -NumHelloSent
    lappend list $list1(-TxHello)
    lappend list -NumDbdSent
    lappend list $list1(-TxDd)
    lappend list -NumRtrLsaSent
    lappend list $list1(-TxRouterLsa)
    lappend list -NumNetLsaSent
    lappend list $list1(-TxNetworkLsa)
    lappend list -NumSum4LsaSent
    lappend list $list1(-TxAsbrSummaryLsa)
    lappend list -NumSum3LsaSent
    lappend list $list1(-TxSummaryLsa)
    lappend list -NumExtLsaSent
    lappend list $list1(-TxAsExternalLsa)
    lappend list -NumType7LsaSent
    lappend list $list1(-TxNssaLsa)

    set list [ConvertAttrToLowerCase $list] 
    if {$args == ""} {
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveRouterStats"
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveRouterStats"
        return $::mainDefine::gSuccess                        
    }    
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2CreateTopRouter
#
#Description: Create Router in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateTopRouter {args } {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopRouter"
    
    set stcAttrConfig ""
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv2CreateTopRouter"
    }  

    set index [lsearch $m_routerList $routername]
    if {$index != -1} {
       error "The routername($routername) is already existed, please specify another one,the existed routername(s) is(are) as following:\
       \n$m_routerList"
    }
    
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]   

    #Abstract routerid from parameter list 
    set index [lsearch $args -routerid]
    if {$index != -1} {
       set routerid [lindex $args [expr $index + 1]]             
    } else {
       error "please specify routerId for Ospfv2CreateTopRouter"
    }
    
    #Abstract emulatedrtr from parameter list 
    set index [lsearch $args -emulatedrtr]
    if {$index != -1} {
       set emulatedrtr [lindex $args [expr $index + 1]]
    } else {
       set emulatedrtr no 
    }
    
    #Check and ensure the uniqueness of routerId
    if {$emulatedrtr != "yes"} {
    foreach router $m_routerList {
        set rId $m_topConfig($router,routerId)
        if {$rId == $routerid} {
            error "routerId($routerid) is duplicated with routerId of existed router($router), please specify another one. "
        }
    }

    if {$routerid == $m_routerId} {
       error "routerId must be different from simulater's routerId($m_routerId)"
    }
    
    }
    
    lappend m_topConfig($routername) -routerid
    lappend m_topConfig($routername) $routerid
    set m_topConfig($routername,routerId) $routerid
    

    #Add routername to list, the position can not be front
    lappend m_topNameList $routername
    lappend m_routerList $routername
    
    #Abstract routertypevalue from parameter list 
    set index [lsearch $args -routertype]
    if {$index != -1} {
       set routertype [lindex $args [expr $index + 1]]
    } else {
       set routertype normal
    }
    lappend m_topConfig($routername) -routertype
    lappend m_topConfig($routername) $routertype
    set m_topConfig($routername,routerType) $routertype

    set routertype [string tolower $routertype]

    #Abstract FlagAdertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1 
    }        
    lappend m_topConfig($routername) -flagadvertise
    lappend m_topConfig($routername) $flagadvertise    

    set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
       set flagte 0 
    }      
    lappend m_topConfig($routername) -flagte
    lappend m_topConfig($routername) $flagte   

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect 1 
    }      
    lappend m_topConfig($routername) -flagautoconnect
    lappend m_topConfig($routername) $flagautoconnect     
    

    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]    

    set flagautoconnect [string map {0 false} $flagautoconnect]
    set flagautoconnect [string map {disable false} $flagautoconnect]
    set flagautoconnect [string map {off false} $flagautoconnect]
    set flagautoconnect [string map {1 true} $flagautoconnect]
    set flagautoconnect [string map {enable true} $flagautoconnect]
    set flagautoconnect [string map {on true} $flagautoconnect]  
    

    lappend m_topConfig($routername) -linknum
    lappend m_topConfig($routername) 0
    lappend m_topConfig($routername) -linknamelist
    lappend m_topConfig($routername) ""
    #lappend m_topConfig($routername) -connectedRtrNameList
    #lappend m_topConfig($routername) ""
    
    #Create RouterLsa according to routerType
   
    if {$emulatedrtr!="yes"} {
    switch $routertype {
        abr {
           set m_hLsaArrIndexedByTopName($routername) [eval stc::create RouterLsa   \
                                                                                  -under $m_hOspfv2RouterConfig\
                                                                                  -AdvertisingRouterId $routerid \
                                                                                  -LinkStateId $routerid\
                                                                                  -Abr TRUE\
                                                                                  -name $routername \
                                                                                  -active $flagadvertise]
                                                                                 
        }
        asbr {
            set m_hLsaArrIndexedByTopName($routername) [eval stc::create RouterLsa   \
                                                                                  -under $m_hOspfv2RouterConfig\
                                                                                  -AdvertisingRouterId $routerid\
                                                                                  -LinkStateId $routerid\
                                                                                  -asbr TRUE\
                                                                                  -name $routername \
                                                                                  -active $flagadvertise]                                                                    
        }
        vl {
            set m_hLsaArrIndexedByTopName($routername) [eval stc::create RouterLsa   \
                                                                                  -under $m_hOspfv2RouterConfig\
                                                                                  -AdvertisingRouterId $routerid\
                                                                                  -LinkStateId $routerid\
                                                                                  -Vl TRUE \
                                                                                  -active $flagadvertise \
                                                                                  -name $routername ]                                                                       
        }
        default {
            set m_hLsaArrIndexedByTopName($routername) [eval stc::create RouterLsa   \
                                                                                  -under $m_hOspfv2RouterConfig\
                                                                                  -AdvertisingRouterId $routerid\
                                                                                  -LinkStateId $routerid\
                                                                                  -name $routername \
                                                                                  -active $flagadvertise]                                                                      
        }

    }
    }
    set m_topConfig($routername,link2Emulator) no    
    if {$emulatedrtr!="yes"} { 
        if {$flagautoconnect == "true"} {
            Ospfv2CreateTopRouterLink -RouterName $routername -LinkType POINT_TO_POINT -LinkConnectedName $m_routerName -FlagAdvertise $flagadvertise -linkname link-$m_routerName-$routername.[incr m_autoConnectLinkNum]
            Ospfv2CreateTopRouterLink -RouterName $m_routerName -LinkType POINT_TO_POINT -LinkConnectedName $routername -FlagAdvertise $flagadvertise -linkname link-$routername-$m_routerName
            set m_topConfig($routername,link2Emulator) yes
        }
    }
    set m_lsaConfig($routername)  ""
    lappend m_lsaConfig($routername) -lsatype 
    lappend m_lsaConfig($routername)  routerlsa
    #ApplyToChassis 


    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopRouter"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2SetTopRouter
#
#Description: Create Router in defined format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2SetTopRouter {args } {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopRouter"
    
    set stcAttrConfig ""
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv2SetTopRouter"
    }  

    set index [lsearch $m_routerList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_routerList"
    }
    
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]   

    #Abstract routerid from parameter list 
    set routerId_old $m_topConfig($routername,routerId)
    set index [lsearch $args -routerid]
    if {$index != -1} {
       set routerid [lindex $args [expr $index + 1]]             
    } else {
        set index1 [lsearch $m_topConfig($routername) -routerid]
        set routerid [lindex $m_topConfig($routername)  [expr $index1 + 1]]
    }
    
    #Check and ensure the uniqueness of routerId    
    foreach router $m_routerList {
        set rId $m_topConfig($router,routerId)
        if {$rId == $routerid} {
            error "routerId($routerid) is duplicated with routerId of existed router($router), please specify another one. the existed routerId(s) is: \n $routerIdList"
        }
    }

    if {$routerid == $m_routerId} {
       error "routerId must be different from simulater's routerId($m_routerId)"
    }
    set index1 [lsearch $m_topConfig($routername) -routerid]
    set m_topConfig($routername) [lreplace $m_topConfig($routername) [incr index1] $index1 $routerid]
    set m_topConfig($routername,routerId) $routerid    
    
    #Abstract routertypevalue from parameter list 
    set index [lsearch $args -routertype]
    if {$index != -1} {
       set routertype [lindex $args [expr $index + 1]]
    } else {
       set index1 [lsearch $m_topConfig($routername) -routertype]
       set routertype [lindex $m_topConfig($routername) [incr index1]]
    }

    set routertype [string tolower $routertype]

    
    set index1 [lsearch $m_topConfig($routername) -routertype]
    set m_topConfig($routername) [lreplace $m_topConfig($routername) [incr index1] $index1 $routertype]
    set m_topConfig($routername,routerType) $routertype

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set index1 [lsearch $m_topConfig($routername) -flagautoconnect]
       set flagautoconnect [lindex $m_topConfig($routername) [incr index1]]
    }    

    set flagautoconnect [string map {0 false} $flagautoconnect]
    set flagautoconnect [string map {disable false} $flagautoconnect]
    set flagautoconnect [string map {off false} $flagautoconnect]
    set flagautoconnect [string map {1 true} $flagautoconnect]
    set flagautoconnect [string map {enable true} $flagautoconnect]
    set flagautoconnect [string map {on true} $flagautoconnect]  
    
    set index1 [lsearch $m_topConfig($routername) -flagautoconnect]
    set m_topConfig($routername) [lreplace $m_topConfig($routername) [incr index1] $index1 $flagautoconnect]
  
   
    #Abstract FlagAdertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]       
    } else {
       set index1 [lsearch $m_topConfig($routername) -flagadvertise]
       set flagadvertise [lindex $m_topConfig($routername) [incr index1]]
    }
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    set index1 [lsearch $m_topConfig($routername) -flagadvertise]
    set m_topConfig($routername) [lreplace $m_topConfig($routername) [incr index1] $index1 $flagadvertise]    
  
    #Create RouterLsa according to routerType
    switch $routertype {
        abr {
            stc::config $m_hLsaArrIndexedByTopName($routername)   \
                                            -AdvertisingRouterId $routerid \
                                            -LinkStateId $routerid\
                                            -Abr TRUE\
                                            -name $routername \
                                            -active $flagadvertise
                                                                                 
        }
        asbr {
            stc::config $m_hLsaArrIndexedByTopName($routername)   \
                                            -AdvertisingRouterId $routerid\
                                            -LinkStateId $routerid\
                                            -asbr TRUE\
                                            -name $routername \
                                            -active $flagadvertise                                                                 
        }
        vl {
            stc::config $m_hLsaArrIndexedByTopName($routername)   \
                                             -AdvertisingRouterId $routerid\
                                             -LinkStateId $routerid\
                                             -Vl TRUE \
                                             -name $routername \
                                             -active $flagadvertise                                                                    
        }
        default {
            stc::config $m_hLsaArrIndexedByTopName($routername)    \
                                             -AdvertisingRouterId $routerid\
                                             -LinkStateId $routerid\
                                             -name $routername \
                                             -active $flagadvertise                                                                   
        }

    }

    array set temp $m_topConfig($routername) 
    foreach linkname $temp(-linknamelist) {
        if {$m_topConfig($linkname,linkObjType) == "router"} {
            foreach hLink $m_handleBylinkName($linkname) {           
            set linkId [stc::get $hLink  -LinkId ]
            if {$linkId == $routerId_old} {
                stc::config $hLink -LinkId $routerid
            }               
          }   

       if {($flagautoconnect=="true")&&($m_topConfig($routername,link2Emulator)=="no")} {
          Ospfv2CreateTopRouterLink -RouterName $routername -LinkType POINT_TO_POINT -LinkConnectedName $m_routerName -FlagAdvertise $flagadvertise -linkname link-$routername-$m_routerName
          Ospfv2CreateTopRouterLink -RouterName $m_routerName -LinkType POINT_TO_POINT -LinkConnectedName $routername -FlagAdvertise $flagadvertise -linkname link-$m_routerName-$routername
          set m_topConfig($routername,link2Emulator) yes
       } elseif {($flagautoconnect=="false")&&($m_topConfig($routername,link2Emulator)=="yes")} {
          Ospfv2DeleteTopRouterLink -linkname  link-$m_routerName-$routername
          Ospfv2DeleteTopRouterLink -linkname  link-$routername-$m_routerName
          set m_topConfig($routername,link2Emulator) no
       }             
       } elseif {$m_topConfig($linkname,linkObjType) == "network"} {
            set list [split $m_topConfig($linkname,linkPoint) ,]
            set linkPoint [lindex $list 1]
            set children [stc::get $m_hLsaArrIndexedByTopName($linkPoint) -children]
            foreach child $children {
                set linkId [stc::get $child -LinkId ]
                if {$linkId == $routerId_old } {
                    stc::config $child  -LinkId $routerid
                    break
                }
            }
        } elseif {($m_topConfig($linkname,linkObjType) == "externalRouteBlock")||($m_topConfig($linkname,linkObjType) == "summaryRouteBlock")} {
            set list [split $m_topConfig($linkname,linkPoint) ,]
            set linkPoint [lindex $list 1]
            stc::config $m_hLsaArrIndexedByTopName($linkPoint) -AdvertisingRouterId $routerid            
        }
    }
    
    ApplyToChassis 

    Ospfv2Session::Ospfv2AdvertiseRouters -RouterNameList $routername

    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopRouter"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2RetrieveTopRouter
#
#Description:Get attribute of Router
#
#Input: 1.routername:Name handler of Router
#
#Output: Attribute of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveTopRouter {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopRouter"
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify routername for Ospfv2RetrieveTopRouter"
    }  
    #Check the existence of routername
    set index [lsearch $m_routerList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_routerList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]              
    set list "" 
    array set temp $m_topConfig($routername)
    foreach index [array names temp] {
        lappend list $index
        lappend list $temp($index)
    }    
    set list [ConvertAttrToLowerCase $list] 
    
    if {$args == ""} {
         debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopRouter"
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }  
       debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopRouter"                  
       return $::mainDefine::gSuccess    
    }  
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2DeleteTopRouter
#
#Description: Delete specified Router
#
#Input: 1.RouterName:Name handler of Router
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopRouter {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopRouter"
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv2DeleteTopRouter"
    }  
    #Check the existence of routername
    set index [lsearch $m_routerList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_routerList"
    }

    set m_routerList [lreplace $m_routerList $index $index]
    set index [lsearch $m_topNameList $routername]
    set m_topNameList [lreplace $m_topNameList $index $index]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Delete all lsa of self-2-other 
    set hLinkList [stc::get $m_hLsaArrIndexedByTopName($routername) -children]
    #Delete all lsa of other-2-self 
    foreach hLink $hLinkList {
        set linkName [stc::get $hLink -name]
        catch {unset m_linkStatus($linkName)}        
            #stc::delete $link
        set index [lsearch $m_totalLinkList $linkName]
        set m_totalLinkList [lreplace $m_totalLinkList $index $index]
        catch {unset m_handleBylinkName($linkName)}
    }   
    catch {
        foreach hObj $m_handleByRtrName($routername) {
            if {$m_topConfig($hObj,linkObjType) != "router"} {continue}     
            stc::delete $hObj
            foreach rtr [array names m_handleByRtrName] {
                set index [lsearch $m_handleByRtrName($rtr) $hObj]
                if {$index != -1} {
                     set m_handleByRtrName($rtr) [lreplace $m_handleByRtrName($rtr) $index $index]
                }
            }
            
        }
    }
    stc::delete $m_hLsaArrIndexedByTopName($routername)
    catch {unset m_topConfig($routername,routerId)}
    catch {unset m_topConfig($routername,routerType)}
    catch {unset m_handleByRtrName($routername)}    

    array set temp $m_topConfig($routername) 
    foreach linkname $temp(-linknamelist) {
        if {$m_topConfig($linkname,linkObjType) == "router"} {
        
            set linkPoint $m_topConfig($linkname,linkPoint)
            set rtrList [split $linkPoint ,]
           
            foreach rtr  $rtrList {
                if {$rtr == $routername} {continue}
                array set temp $m_topConfig($rtr)
                incr temp(-linknum) -1
                set index [lsearch $temp(-linknamelist) $linkname]
                if {$index != -1} {
                    set temp(-linknamelist) [lreplace $temp(-linknamelist) $index $index]
                
                }
                set m_topConfig($rtr) ""
                foreach name [array names temp] {
                    lappend m_topConfig($rtr) $name
                    lappend m_topConfig($rtr) $temp($name)
                }
            }            
        }
        catch {unset m_topConfig($linkname,linkPoint)}
    }        
    ApplyToChassis
    catch {unset m_topConfig($routername)}
    catch {unset m_hLsaArrIndexedByTopName($routername)}
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopRouter"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2CreateTopRouterLink
#
#Description: Create RouterLink in defined format
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2CreateTopRouterLink {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopRouterLink"

    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv2CreateTopRouterLink"
    }  
    #Check the existence of routername
    set index [lsearch $m_routerList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_routerList"
    }  

    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
        set linkname [lindex $args [expr $index + 1]]
    } else {
        error "please specify linkname for Ospfv2CreateTopRouterLink"
    }
    #set index1 [lsearch $m_topConfig($routername) -linknamelist]
    #incr index1
    #set linknamelist [lindex  $m_topConfig($routername) $index1]
    set index [lsearch $m_totalLinkList $linkname]
    if {$index != -1} {
        error "The linkname($linkname) is already existed , please specify another one,the existed linkname(s) is(are) as following:\
          \n $m_totalLinkList"
    }
    #lappend linknamelist $linkname
    #set m_topConfig($routername) [lreplace $m_topConfig($routername) $index1 $index1 $linknamelist]
    lappend  m_topConfig($routername,links,self-2-other) $linkname
    lappend m_totalLinkList $linkname
    set m_link2RouterArr($linkname) $routername

    lappend m_topConfig($linkname) -routername
    lappend m_topConfig($linkname) $routername
    
    #Abstract routername from parameter list 
    set index [lsearch $args -linkconnectedname]
    if {$index != -1} {
       set linkconnectedname [lindex $args [expr $index + 1]]
    } else {
       error "please specify linkconnectedname for Ospfv2CreateTopRouter"
    }  
    #Check the existence of routername
    set index [lsearch $m_topNameList $linkconnectedname]
    if {$index == -1} {
       error "The linkconnectedname($linkconnectedname) does not exist, the existed linkconnectedname(s) is(are) as following:\
       \n $m_topNameList"
    }     

    lappend m_topConfig($linkname) -linkconnectedname
    lappend m_topConfig($linkname) $linkconnectedname      

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    set index  [lsearch $m_topConfig($routername) -routerid]
    set routerid [lindex $m_topConfig($routername)  [expr $index + 1]]    
    lappend m_topConfig($linkname) -routerid
    lappend m_topConfig($linkname) $routerid   
    
    #Abstract linktype from parameter list 
    set index [lsearch $args -linktype]
    if {$index != -1} {
       set linktype [lindex $args [expr $index + 1]]       
    } else {
       set linktype ptop
    }
    set linktype [string map {ptp POINT_TO_POINT} $linktype]
    set linktype [string map {ptop POINT_TO_POINT} $linktype]
    set linktype [string map {nbma TRANSIT_NETWORK} $linktype]
    set linktype [string map {stub STUB_NETWORK} $linktype]
    set linktype [string map {vlink VL} $linktype]    
        
    lappend m_topConfig($linkname) -linktype
    lappend m_topConfig($linkname) $linktype        
   
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]       
    } else {
       set flagadvertise 1
    }
    #set flagadvertise 0
    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    lappend m_topConfig($linkname) -flagadvertise
    lappend m_topConfig($linkname) $flagadvertise
    

    #Abstract linkmetric from parameter list 
    set index [lsearch $args -linkmetric]
    if {$index != -1} {
       set linkmetric [lindex $args [expr $index + 1]]       
    } else {
       set linkmetric 1
    }
    lappend m_topConfig($linkname) -linkmetric
    lappend m_topConfig($linkname) $linkmetric   
    set m_topConfig($linkconnectedname,attachedRtr) $routername
      
    set m_topConfig($linkname,linkPoint) $routername,$linkconnectedname
    array set temp $m_topConfig($routername)
    incr temp(-linknum)
    lappend temp(-linknamelist) $linkname
    set m_topConfig($routername) ""
    foreach name [array names temp] {
        lappend m_topConfig($routername) $name
        lappend m_topConfig($routername) $temp($name)
    }
        
    
    set index [lsearch $m_summaryRouteBlockList $linkconnectedname]
    set index1 [lsearch $m_externalRouteBlockList $linkconnectedname]
    set index2 [lsearch $m_networkList $linkconnectedname]
    set index3 [lsearch $m_routerList $linkconnectedname]
    set m_topConfig($linkconnectedname,linkmetric) $linkmetric
    if {$index != -1} {
        set m_topConfig($linkconnectedname,linked) 1
        set m_topConfig($linkconnectedname,linkname) $linkname               
        eval Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock1 $m_topConfig($linkconnectedname)  \
        -metric $linkmetric -abrid $m_topConfig($routername,routerId) \
        -flagadvertise 1 -blockname $linkconnectedname
        set m_topConfig($linkname,linkObjType) summaryRouteBlock

    } elseif {$index1 != -1} {
        set m_topConfig($linkconnectedname,linked) 1
        set m_topConfig($linkconnectedname,linkname) $linkname
        eval Ospfv2Session::Ospfv2CreateTopExternalRouteBlock1 $m_topConfig($linkconnectedname) \
        -metric $linkmetric \
        -abrid $m_topConfig($routername,routerId)  -asbrid $m_topConfig($routername,routerId) \
        -flagadvertise 1 -blockname $linkconnectedname
        set m_topConfig($linkname,linkObjType) externalRouteBlock
        
    } elseif {$index2 != -1} {
        set m_topConfig($linkname,linked) 1
        set m_topConfig($linkconnectedname,linkname) $linkname   
        eval Ospfv2Session::Ospfv2CreateTopNetwork1 -connectedrouternamelist $routername  -flagadvertise 1\
        -networkname $linkconnectedname
        set m_topConfig($linkname,linkObjType) network
    } else { 
        array set temp $m_topConfig($linkconnectedname)
        incr temp(-linknum)
        lappend temp(-linknamelist) $linkname
        foreach name [array names temp] {
            lappend m_topConfig($linkconnectedname) $name
            lappend m_topConfig($linkconnectedname) $temp($name)
       }       

       
       set m_topConfig($linkname,linkObjType) router
       set linkotherid $m_topConfig($linkconnectedname,routerId)
       set m_hLsaArrIndexedByLsaName($linkname) [stc::create RouterLsaLink \
                                         -under $m_hLsaArrIndexedByTopName($routername)\
                                         -Active  $flagadvertise \
                                         -LinkId $linkotherid\
                                         -LinkType $linktype\
                                         -Metric $linkmetric\
                                         -Name $linkname] 

     lappend m_handleBylinkName($linkname)   $m_hLsaArrIndexedByLsaName($linkname)
     lappend m_handleByRtrName($routername)   $m_hLsaArrIndexedByLsaName($linkname) 
     lappend m_handleByRtrName($linkconnectedname)   $m_hLsaArrIndexedByLsaName($linkname) 
     set m_topConfig($m_hLsaArrIndexedByLsaName($linkname),linkObjType) router
     set m_linkStatus($linkname) false
   }
   #ApplyToChassis

    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopRouterLink"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2SetTopRouterLink {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopRouterLink"

    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
        set linkname [lindex $args [expr $index + 1]]
    } else {
        error "please specify linkname for Ospfv2SetTopRouterLink"
    }
    set index [lsearch $m_totalLinkList $linkname]
    if {$index == -1} {
        error "The linkname($linkname) dose not exist ,the existed linkname(s) is(are) as following:\
          \n $m_totalLinkList"
    }
    set routername $m_link2RouterArr($linkname)
      
  
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    set index  [lsearch $m_topConfig($routername) -routerid]
    set routerid [lindex $m_topConfig($routername)  [expr $index + 1]]    
     
    #Abstract linkmetric from parameter list 
    set index [lsearch $args -linkmetric]
    if {$index != -1} {
       set linkmetric [lindex $args [expr $index + 1]]       
    } else {
       set index [lsearch $m_topConfig($linkname) -linkmetric]
       set linkmetric [lindex $m_topConfig($linkname) [expr $index + 1]] 
    }
    set index [lsearch $m_topConfig($linkname) -linkmetric]
    set m_topConfig($linkname) [lreplace $m_topConfig($linkname) [expr $index + 1] [expr $index + 1] $linkmetric] 

    set index [lsearch $m_topConfig($linkname) -linkconnectedname]
    set linkconnectedname [lindex $m_topConfig($linkname) [expr $index + 1]]
      
    
    set index [lsearch $m_summaryRouteBlockList $linkconnectedname]
    set index1 [lsearch $m_externalRouteBlockList $linkconnectedname]
    set index2 [lsearch $m_networkList $linkconnectedname]
    set index3 [lsearch $m_routerList $linkconnectedname]
    if {$index != -1} {         
        set m_topConfig($linkconnectedname,linked) 1
        Ospfv2Session::Ospfv2SetTopSummaryRouteBlock1 $m_topConfig($linkconnectedname)  \
        -metric $linkmetric  -abrid $m_topConfig($routername,routerId)

    } elseif {$index1 != -1} {
        set m_topConfig($linkconnectedname,linked) 1
        Ospfv2Session::Ospfv2SetTopExternalRouteBlock1 $m_topConfig($linkconnectedname) \
        -metric $linkmetric -abrid $m_topConfig($routername,routerId) \
        -asbrid $m_topConfig($routername,routerId)
    } else {
       #set linkotherid $m_topConfig($linkconnectedname,routerId)
       foreach hLink $m_handleBylinkName($linkname) {
           stc::config $hLink -Metric $linkmetric
       }                                                                                                                 
    }      

    ApplyToChassis
 
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopRouterLink"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2RetrieveTopRouterLink
#
#Description: Get the attribute of RouterLink
#
#Input: 1.linklsaname:Name handler of RouterLink
#
#Output: Attribute of RouterLink
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveTopRouterLink {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopRouterLink"    
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv2RetrieveTopRouterLink"
    }  
    #Check the existence of routername
    set index [lsearch $m_routerList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_routerList"
    }    
    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify linkname for Ospfv2RetrieveTopRouterLink"
    }  

    set hLinkList [stc::get $m_hLsaArrIndexedByTopName($routername) -children]
    set linkList ""
    
    foreach hLink $hLinkList {
        set linkName1 [stc::get $hLink -name]
        lappend linkList $linkName1
        set hLink1($linkName1) $hLink
    }
    #Check the existence of linkname
    set index [lsearch $linkList $linkname]
    if {$index == -1} {
       error "The linkname($linkname) does not exist in rotuer($routername), the existed linkname(s) is(are) as following:\
       \n $linkList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
       
    #Return configuration information of link
    array set list1 [stc::get $hLink1($linkname)]
    array set list2 $m_linkConfig($routername,$linkname)
    set list ""
    lappend list -routername 
    lappend list $routername
    lappend list -linkname
    lappend list $linkname
    lappend list -linktype
    lappend list $list1(-LinkType)
    lappend list -linkotherid
    lappend list $list1(-LinkId)
    lappend list -linkinterfaceaddress
    lappend list $list1(-LinkData)
    lappend list -flagadvertise
    lappend list $list2(-flagadvertise)
    lappend list -linkmetric
    lappend list $list1(-Metric)
    set list $m_topConfig($linkname)
    set list [ConvertAttrToLowerCase $list] 
    
    if {$args == ""} {
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopRouterLink"  
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                        

        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopRouterLink"  
        return $::mainDefine::gSuccess
    }
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2DeleteTopRouterLink
#
#Description: Delete specified RouterLink
#
#Input: 1.linklsaname:Name handler of RouterLink
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopRouterLink {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopRouterLink"   
    
    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
        set linkname [lindex $args [expr $index + 1]]
    } else {
        error "please specify linkname for Ospfv2DeleteTopRouterLink"
    }

    set index [lsearch $m_totalLinkList $linkname]
    if {$index == -1} {
        error "The linkname($linkname) dose not exist , please specify another one,the existed linkname(s) is(are) as following:\
          \n $m_totalLinkList"
    }
    set m_totalLinkList [lreplace $m_totalLinkList $index $index]   
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    #delete lsa  $m_handleBylinkName
    if {$m_topConfig($linkname,linkObjType) == "router"} {
    catch {unset m_linkStatus($linkname)}
        foreach hLink $m_handleBylinkName($linkname) {
            stc::delete $hLink
            foreach router $m_routerList {
                set hLinkList $m_handleByRtrName($router)
                set index [lsearch $hLinkList $hLink]
                if {$index != -1} {
                    set hLinkList [lreplace $hLinkList [incr index] $index]
                    set m_handleByRtrName($router) $hLinkList
                }
            }
        }
        catch {unset m_handleBylinkName($linkname)}
    } else {
        Ospfv2Session::Ospfv2WithdrawLinks -linknamelist $linkname
    }
    set index [lsearch $m_totalLinkList $linkname]
    if {$index != -1} {
        set m_totalLinkList [lreplace $m_totalLinkList [incr index] $index]
    }            
    ApplyToChassis 
    
    catch {unset m_hLsaArrIndexedByLsaName($linklsaname)}
    catch {unset m_linkConfig($linklsaname) }
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopRouterLink"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
############################################################################
#APIName: Ospfv2CreateTopNetwork
#
#Description: Create Network in defined format
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2CreateTopNetwork {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopNetwork"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv2CreateTopNetwork API"
    }
   
    #Create uniqueness of networkname
    set index [lsearch $m_networkList $networkname]
    if {$index != -1} {
       error "The networkname($networkname) is already existed, please specify another one,the existed networkname(s) is(are) as following:\
       \n $m_networkList"
    }
    lappend m_topNameList $networkname
    lappend m_networkList $networkname
    lappend m_topConfig($networkname) -networkname
    lappend m_topConfig($networkname) $networkname
    set m_topConfig($networkname,linked) 0
    
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]    
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
      
    set index [lsearch $args -subnetwork]
    if {$index != -1} {
       set subnetwork [lindex $args [expr $index + 1]]
    } else {
       set subnetwork 18.12.1.0
    }
    lappend m_topConfig($networkname) -subnetwork
    lappend m_topConfig($networkname) $subnetwork
    #Abstract ddroutername from parameter list 
    
    set index [lsearch $args -drroutername]
    if {$index != -1} {
       set drroutername [lindex $args [expr $index + 1]] 
       set index [lsearch $m_topNameList $drroutername]
       if {$index == -1} {
          error "The routername($ddroutername) does not exist, the existed routername(s) is(are) as following:\n $m_routerList"
       }
       set index [lsearch $m_topConfig($drroutername) -routerid]
       set drRouterId [lindex $m_topConfig($drroutername) [expr $index + 1]]
       
    } else {
       set drRouterId $m_routerId
       set drroutername $m_routerName
    }
    lappend m_topConfig($networkname) -drroutername
    lappend m_topConfig($networkname) $drroutername
    set m_topConfig($networkname,routerId) null
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
    } else {
       set prefixlen 24
    }
    lappend m_topConfig($networkname) -prefixlen
    lappend m_topConfig($networkname) $prefixlen

    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname "not_specified"
    }
    lappend m_topConfig($networkname) -lsaname
    lappend m_topConfig($networkname) $lsaname

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect 1
    }

    set flagautoconnect [string map {0 false} $flagautoconnect]
    set flagautoconnect [string map {disable false} $flagautoconnect]
    set flagautoconnect [string map {off false} $flagautoconnect]
    set flagautoconnect [string map {1 true} $flagautoconnect]
    set flagautoconnect [string map {enable true} $flagautoconnect]
    set flagautoconnect [string map {on true} $flagautoconnect]
    
    lappend m_topConfig($networkname) -flagautoconnect
    lappend m_topConfig($networkname) $flagautoconnect
    

    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create NetworkLsa \
                                           -under $m_hOspfv2RouterConfig \
                                           -AdvertisingRouterId $drRouterId\
                                           -LinkStateId $subnetwork \
                                           -PrefixLength  $prefixlen \
                                           -active true]                                                                                         
    set  m_hLsaArrIndexedByTopName($networkname)  $m_hLsaArrIndexedByLsaName($lsaname)   

    if {$flagautoconnect == "true"} {
        set hLink [stc::create NetworkLsaLink -under $m_hLsaArrIndexedByTopName($networkname)  -LinkId $m_routerId -active false -Name emulator-$networkname]
        lappend m_handleByRtrName($m_routerName) $hLink
        set m_handleBylinkName(emulator-$networkname) $hLink
    }

    set m_lsaConfig($networkname)  ""
    lappend m_lsaConfig($networkname) -lsatype 
    lappend m_lsaConfig($networkname)  networklsa
    ApplyToChassis

    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopNetwork"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}
::itcl::body Ospfv2Session::Ospfv2CreateTopNetwork1 {args} {
set list ""

if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
   
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopNetwork_internal"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv2CreateTopNetwork_internal API"
    }
   
    #Create uniqueness of networkname
    set index [lsearch $m_networkList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) dose not exist, the existed networkname(s) is(are) as following:\
       \n $m_networkList"
    }
    
    set linkname $m_topConfig($networkname,linkname) 
    
    #Convert attribute item(attr) of parameter list to lower-case
    
    set args [ConvertAttrToLowerCase1 $args]    
     
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }

    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]
    
    

    #Abstract connectedrouternamelist from parameter list 
    set index [lsearch $args -connectedrouternamelist]
    if {$index != -1} {
       set connectedrouternamelist [lindex $args [expr $index + 1]]
    } else {
       error "please specify connectedrouternamelist for Ospfv2CreateTopNetwork_internal API"
    }

    set index [lsearch $m_topConfig($networkname) -drroutername]
    set drroutername [lindex $m_topConfig($networkname) [incr index]]
    set attachedRtr $m_topConfig($networkname,attachedRtr)
    
    set connectedRouterIdList ""
    foreach connectedroutername $connectedrouternamelist {
       #Create existence of routername
       set index [lsearch $m_routerList $connectedroutername]
       if {$index == -1} {
          error "The routername ($connectedroutername) does not exist, the existed routername(s) is(are) as following:\
          \n $m_routerList"
       } 
       set index [lsearch $m_topConfig($connectedroutername) -routerid]
       set routerid [lindex $m_topConfig($connectedroutername) [expr $index + 1] ]
       lappend connectedRouterIdList $routerid      
       set m_hLsaArrIndexedByTopName($linkname) [stc::create RouterLsaLink \
                                                 -under $m_hLsaArrIndexedByTopName($connectedroutername)\
                                                 -LinkData $m_topConfig($drroutername,routerId)\
                                                 -LinkId  $m_topConfig($drroutername,routerId)\
                                                 -LinkType "TRANSIT_NETWORK"\
                                                 -Name $linkname\
                                                 -active false\
                                                 ]
      lappend m_handleBylinkName($linkname)    $m_hLsaArrIndexedByTopName($linkname)     
      lappend m_handleByRtrName($attachedRtr) $m_hLsaArrIndexedByTopName($linkname)  
      set m_topConfig($m_hLsaArrIndexedByTopName($linkname),linkObjType) network
      set m_linkStatus($linkname) false
    }


    foreach routerId $connectedRouterIdList {
        #Create NetworkLsaLink
        set hLink [stc::create NetworkLsaLink -under $m_hLsaArrIndexedByTopName($networkname)  -LinkId $routerId -active false -Name $linkname]
        lappend m_handleBylinkName($linkname) $hLink
        lappend m_handleByRtrName($attachedRtr) $hLink
        set m_topConfig($hLink,linkObjType) network
        set m_linkStatus($linkname) false
    }  

    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopNetwork_internal"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2SetTopNetwork {args} {
set list ""

if {[catch {     
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopNetwork"
   
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv2SetTopNetwork API"
    }
   
    #Create uniqueness of networkname
    set index [lsearch $m_networkList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) dose not exist, the existed networkname(s) is(are) as following:\
       \n $m_networkList"
    }
   
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]        

    #Abstract subnetwork from parameter list 
    set index [lsearch $args -subnetwork]
    if {$index != -1} {
       set subnetwork [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($networkname) -subnetwork]
       set m_topConfig($networkname) [lreplace $m_topConfig($networkname) [incr index] $index $subnetwork]
    }
    set index [lsearch $m_topConfig($networkname) -subnetwork]
    set subnetwork [lindex $m_topConfig($networkname) [expr $index + 1]] 

    #Abstract subnetwork from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($networkname) -prefixlen]
       set m_topConfig($networkname) [lreplace $m_topConfig($networkname) [incr index] $index $prefixlen]
    }
    set index [lsearch $m_topConfig($networkname) -prefixlen]
    set prefixlen [lindex $m_topConfig($networkname) [expr $index + 1]] 
    

    stc::config  $m_hLsaArrIndexedByTopName($networkname) -LinkStateId $subnetwork  -PrefixLength  $prefixlen     
        
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopNetwork"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2RetrieveTopNetwork
#
#Description: Get the attribute of Network
#
#Input: 1.networkname:Name handler of Network
#
#Output: Attribute of Network
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveTopNetwork {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopNetwork"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify networkname for Ospfv2RetrieveTopNetwork"
    }  
    #Check the existence of networkname
    set index [lsearch $m_networkList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) does not exist, the existed routername(s) is(are) as following:\
       \n $m_networkList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Return configuration information of network
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($networkname)] 
    array set  list2 $m_topConfig($networkname)
    set list ""
    lappend list -networkname
    lappend list $networkname
    lappend list -subnetwork
    lappend list $list1(-LinkStateId)
    lappend list -prefix
    lappend list $list2(-prefix)
    lappend list -ddroutername
    lappend list $list2(-ddroutername)
    lappend list -connectedrouternamelist
    lappend list $list2(-connectedrouternamelist)
    set list $m_topConfig($networkname)
    set list [ConvertAttrToLowerCase $list]
    
    if {$args == ""} {
         debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopNetwork"
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }
        debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopNetwork"                        
        return $::mainDefine::gSuccess
    }  
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2DeleteTopNetwork
#
#Description: Delete specified Network
#
#Input: 1.networkname: name handler of NetworkN
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopNetwork {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopNetwork"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv2DeleteTopNetwork"
    }  
    # Check the existence of networkname
    set index [lsearch $m_networkList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) does not exist, the existed routername(s) is(are) as following:\
       \n $m_networkList"
    }  
    set m_networkList [lreplace $m_networkList $index $index]    
    set  index [lsearch $m_topNameList $networkname]
    set m_topNameList [lreplace $m_topNameList $index $index]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    set hLinkList [stc::get $m_hLsaArrIndexedByTopName($networkname)  -children]
    set linkNameList ""
    foreach hLink $hLinkList {
        lappend linkNameList [stc::get $hLink -name]
    }
    foreach linkName $linkNameList {
         catch {unset m_linkStatus($linkName)}
         foreach link $m_handleBylinkName($linkName) {
             stc::delete $link
         }
    }
    
    #delete network lsa
    stc::delete $m_hLsaArrIndexedByTopName($networkname)       
    ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($networkname)}
    catch {unset m_topConfig($networkname) }
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopNetwork"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateTopSummaryRouteBlock
#
#Description: Create SummaryRouteBlock in defined format
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock"
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2CreateTopSummaryRouteBlock API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index != -1} {
       error "The blockname($blockname) is already existed, please specify another one,the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }
    lappend m_summaryRouteBlockList $blockname
    lappend m_topNameList $blockname
    set m_topConfig($blockname,routerId) null
    set m_topConfig($blockname,linked) 0

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]   

    #Abstract startingaddress from parameter list    
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       set startingaddress 13.2.0.0
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix  from parameter list
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
    } else {
       set prefixlen 24
    }
    lappend m_topConfig($blockname) -prefixlen
    lappend m_topConfig($blockname) $prefixlen
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
    } else {
       set number 50
    }
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier 1
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect 1
    }
    lappend m_topConfig($blockname) -flagautoconnect
    lappend m_topConfig($blockname) $flagautoconnect
    
      
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock1 {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
   
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock_internal"
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2CreateTopSummaryRouteBlock_internal API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) dose not exist, the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }
    set linkname $m_topConfig($blockname,linkname)

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]   

    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }

    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]

    array set temp $m_topConfig($blockname)

    set m_topConfig($blockname) ""
    lappend m_topConfig($blockname) -blockname
    lappend m_topConfig($blockname) $blockname
    
    #Abstract startingaddress from parameter list    
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       set startingaddress $temp(-startingaddress)
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
    } else {
       set prefixlen $temp(-prefixlen)
    }
    lappend m_topConfig($blockname) -prefixlen
    lappend m_topConfig($blockname) $prefixlen
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
    } else {
       set number $temp(-number)
    }
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier $temp(-modifier)
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier


    #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    lappend m_topConfig($blockname) -metric
    lappend m_topConfig($blockname) $metric  

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect $temp(-flagautoconnect)
    }
    lappend m_topConfig($blockname) -flagautoconnect
    lappend m_topConfig($blockname) $flagautoconnect   

    if {$flagautoconnect == "yes"} {
        set abrid $m_routerId
    }    

    #Abstract abrid from parameter list 
    set index [lsearch $args -abrid]
    if {$index != -1} {
       set abrid [lindex $args [expr $index + 1]]
    } else {
       set abrid $m_routerId
    }

    set flag needNewLink
    if {$abrid == $m_routerId} {
        set flag needConfigSimulatorRouter
    } else {
       foreach router $m_topNameList {
         catch {
           if {$abrid == $m_topConfig($router,routerId)} {
               set flag needConfigTopRouter
               set topRouterName $router
           }
         }
       }
    }

    #Create SummaryLsaBlock
    set lsaname lsa1
    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create SummaryLsaBlock \
                                            -under $m_hOspfv2RouterConfig \
                                            -AdvertisingRouterId $abrid\
                                            -Metric $metric\
                                            -name $blockname \
                                            -active true]
    lappend m_handleBylinkName($linkname)   $m_hLsaArrIndexedByLsaName($lsaname) 
    set attachedRtr $m_topConfig($blockname,attachedRtr)
    lappend m_handleByRtrName($attachedRtr)   $m_hLsaArrIndexedByLsaName($lsaname) 
    set m_topConfig($m_hLsaArrIndexedByLsaName($lsaname),linkObjType) summaryRouteBlock
    
    set m_linkStatus($linkname) false
    #配置Ipv4NetworkBlock                                                                                                      
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv4NetworkBlock]
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock
    #判断输入路由是否为列表形式 Add by Andy
    if {$m_startingAddressListFlag(Summary)=="TRUE"} {
        stc::config $hIpv4NetworkBlock -AddrIncrement 1 \
                                                       -NetworkCount 1 \
                                                       -PrefixLength $prefixlen\
                                                       -StartIpList $startingaddress
    } else {
        stc::config $hIpv4NetworkBlock -AddrIncrement $modifier \
                                                       -NetworkCount $number \
                                                       -PrefixLength $prefixlen\
                                                       -StartIpList $startingaddress
    }
    set m_hLsaArrIndexedByTopName($blockname) $m_hLsaArrIndexedByLsaName($lsaname) 
    set m_topConfig($blockname,newLink) ""
    if {$flag == "needNewLink"} {
              
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $m_hSimulatorRouter \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $abrid  \
                -active false]
        lappend m_handleBylinkName($linkname)  $RouterLsaLink(1)  
        lappend m_handleByRtrName($attachedRtr) $RouterLsaLink(1) 
        set m_topConfig($RouterLsaLink(1),linkObjType) summaryRouteBlock
        set m_linkStatus($linkname) false
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $abrid \
                -PrefixLength "32" \
                -NetworkCount "1" 

        set linkName simulatorRouter-2-abr-$abrid 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
        
        set RouterLsa(1) [stc::create "RouterLsa" \
                -under $m_hOspfv2RouterConfig \
                -Abr true\
                -LinkStateId "0.0.0.0" \
                -Age "0" \
                -AdvertisingRouterId $abrid \
                -active false]
        lappend m_handleBylinkName($linkname)   $RouterLsa(1)  
        lappend m_handleByRtrName($attachedRtr) $RouterLsa(1) 
        set m_topConfig($RouterLsa(1),linkObjType) summaryRouteBlock
        set m_linkStatus($linkname) false
        
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $RouterLsa(1) \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $m_routerId  \
                -active false]
        lappend m_handleBylinkName($linkname)   $RouterLsaLink(1)  
        lappend m_handleByRtrName($attachedRtr) $RouterLsaLink(1)
        set m_topConfig($RouterLsaLink(1),linkObjType) summaryRouteBlock
        set m_linkStatus($linkname) false
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $m_routerId \
                -PrefixLength "32" \
                -NetworkCount "1"      

        set linkName abr-2-simulatorRouter-$abrid  
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
               
        stc::config $m_hSimulatorRouter -Abr true
    } elseif {$flag == "needConfigTopRouter"}  {
        
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -Abr true
    } 

    set m_lsaConfig($blockname)  ""
    lappend m_lsaConfig($blockname) -lsatype 
    lappend m_lsaConfig($blockname)  summarylsa

    array set arr $m_topConfig($blockname)
          
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopSummaryRouteBlock_internal"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2SetTopSummaryRouteBlock
#
#Description: Config attribute of SummaryRouteBlock
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2SetTopSummaryRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopSummaryRouteBlock"
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2SetTopSummaryRouteBlock API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) dose not exist, the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]   

    #Abstract startingaddress from parameter list    
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [incr index]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) [incr index] $index $startingaddress]    
    } 
    
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [incr index]]
       set index [lsearch $m_topConfig($blockname) -prefixlen]
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) [incr index] $index $prefixlen]      

    }
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [incr index]]
       set index  [lsearch $m_topConfig($blockname) -number]
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) [incr index] $index $number]     

    }
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [incr index]]
       set index [lsearch $m_topConfig($blockname) -modifier]
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) [incr index] $index $modifier]    

    }

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [incr index]]
       set index [lsearch $m_topConfig($blockname) -flagautoconnect]
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) [incr index] $index $flagautoconnect]    

    }
    
    if {$m_topConfig($blockname,linked)} {
        eval Ospfv2Session::Ospfv2SetTopSummaryRouteBlock1 $m_topConfig($blockname)
    }

      
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopSummaryRouteBlock"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2SetTopSummaryRouteBlock1 {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopSummaryRouteBlock_internal"
    
    set summaryLsaConfig ""
    set routeBlockConfig ""
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2SetTopSummaryRouteBlock_internal API"
    }   
    #Check the existence of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }
    #Abstract flagadvertise from parameter list 

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
  
   #Abstract startingaddress from parameter list      
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $startingaddress]
       
       lappend routeBlockConfig -StartIpList
       lappend routeBlockConfig $startingaddress
    } 
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefixlen]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefixlen]

       lappend routeBlockConfig -PrefixLength
       lappend routeBlockConfig $prefixlen
    }
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -number]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

       lappend routeBlockConfig -NetworkCount
       lappend routeBlockConfig $number
    }
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -modifier]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

       lappend routeBlockConfig -AddrIncrement
       lappend routeBlockConfig $modifier
    }

     #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]
       lappend summaryLsaConfig -metric
       lappend summaryLsaConfig $metric       
    }
 
    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagautoconnect]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagautoconnect]
    }
    if {($flagautoconnect == "enable" ) || ($flagautoconnect == "true") || ($flagautoconnect == "on") || ($flagautoconnect == 1)} {
        set flag  needConfigSimulatorRouter
    } else {
        set flag needConfigTopRouter
    }
 
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -lsaname]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $lsaname]

       set m_lsaConfig($lsaname)  ""
       lappend m_lsaConfig($lsaname) -lsatype 
       lappend m_lsaConfig($lsaname)  summarylsa
      
    }    
    if {$flag != ""} {
        foreach linkName $m_topConfig($blockname,newLink) {
            stc::delete $m_hLsaArrIndexedByTopName($linkName)
        } 
        set m_topConfig($blockname,newLink) ""        
    }
    
    if {$flag == "needNewLink"} {
     
         set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                 -under $m_hSimulatorRouter \
                 -LinkType "POINT_TO_POINT" \
                 -Metric "1" \
                 -LinkId $abrid  ]
         
         global Ipv4NetworkBlock
         set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
         stc::config $Ipv4NetworkBlock(1) \
                 -StartIpList $abrid \
                 -PrefixLength "32" \
                 -NetworkCount "1" 
 
         set linkName simulatorRouter-2-abr-$abrid 
         lappend m_topConfig($blockname,newLink) $linkName
         set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
         
         set RouterLsa(1) [stc::create "RouterLsa" \
                 -under $m_hOspfv2RouterConfig \
                 -Abr true\
                 -LinkStateId "0.0.0.0" \
                 -Age "0" \
                 -AdvertisingRouterId $abrid ]
         
         set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                 -under $RouterLsa(1) \
                 -LinkType "POINT_TO_POINT" \
                 -Metric "1" \
                 -LinkId $m_routerId  ]
         
         global Ipv4NetworkBlock
         set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
         stc::config $Ipv4NetworkBlock(1) \
                 -StartIpList $m_routerId \
                 -PrefixLength "32" \
                 -NetworkCount "1"      
 
         set linkName abr-2-simulatorRouter-$abrid  
         lappend m_topConfig($blockname,newLink) $linkName
         set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
   
     } elseif {$flag == "needConfigSimulatorRouter"}  {
     
         #stc::config $m_hSimulatorRouter -Abr true
     } elseif {$flag == "needConfigTopRouter"}  {
         #stc::config $m_hLsaArrIndexedByTopName($topRouterName) -Abr true
     } 
    
    #Config summaryLsa
    eval stc::config  $m_hLsaArrIndexedByTopName($blockname)  $summaryLsaConfig -active true
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv4NetworkBlock]
    #Config ipv4 network block
    eval stc::config $hIpv4NetworkBlock $routeBlockConfig
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock

    ApplyToChassis                                                                 
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopSummaryRouteBlock_internal"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2RetrieveTopSummaryRouteBlock
#
#Description:Get the attribute of specified SummaryRouteBlock
#
#Input: 1.blockname:Name handler of SummaryRouteBlock
#
#Output:Attribute of SummaryRouteBlock
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2RetrieveTopSummaryRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopSummaryRouteBlock"    
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify blockname for Ospfv2RetrieveTopSummaryRouteBlock"
    }  
    #Create existence of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]           

    set list $m_topConfig($blockname)
    set list [ConvertAttrToLowerCase $list] 
    if {$args == ""} {
         debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopSummaryRouteBlock"  
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }        
       debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopSummaryRouteBlock"  
       return $::mainDefine::gSuccess                
    }  
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2DeleteTopSummaryRouteBlock
#
#Description: delete specified SummaryRouteBlock
#
#Input: 1.blockname:Name handler of SummaryRouteBlock 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopSummaryRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopSummaryRouteBlock"
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2DeleteTopSummaryRouteBlock"
    }  
    #Check the existence of blockname
    set index [lsearch $m_summaryRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_summaryRouteBlockList"
    }
    set m_summaryRouteBlockList [lreplace $m_summaryRouteBlockList $index $index]
    set index [lsearch $m_topNameList $blockname]
    set m_topNameList [lreplace $m_topNameList $index $index]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($blockname)

    foreach linkName $m_topConfig($blockname,newLink) {
        stc::delete $m_hLsaArrIndexedByTopName($linkName)
    } 
    catch {unset m_topConfig($blockname,newLink)}                 

    ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($blockname)}
    catch {unset m_topConfig($blockname) }
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopSummaryRouteBlock"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2CreateTopExternalRouteBlock
#
#Description: Create ExternalRouteBlock in defined format
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2CreateTopExternalRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopExternalRouteBlock"

    #Abstract blockname from parameter list     
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2CreateTopExternalRouteBlock API"
    }  
    #Check the uniqueness of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index != -1} {
       error "The blockname($blockname) is already existed, please specify another one,the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }
    lappend m_topNameList $blockname
    lappend m_externalRouteBlockList $blockname
    set m_topConfig($blockname,routerId) null
    set m_topConfig($blockname,linked) 0
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname "not_specified"
    }
    lappend m_topConfig($blockname) -lsaname
    lappend m_topConfig($blockname) $lsaname

    #Abstract startingaddress from parameter list     
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       set startingaddress 10.10.0.0 
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
    } else {
       set prefixlen 16
    }
    lappend m_topConfig($blockname) -prefixlen
    lappend m_topConfig($blockname) $prefixlen
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
    } else {
       set number 50
    }
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier 1
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier

    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
    } else {
       set flagnssa false
    }
    
    lappend m_topConfig($blockname) -flagnssa
    lappend m_topConfig($blockname) $flagnssa
    if {$flagnssa == "false"} {
        set lsaType  EXT
    } else {
        set lsaType  NSSA
    }

    #Abstract type from parameter list 
    set index [lsearch $args -type]
    if {$index != -1} {
       set type [lindex $args [expr $index + 1]]
    } else {
       set type type_2
    }
    lappend m_topConfig($blockname) -type
    lappend m_topConfig($blockname) $type
    #Abstract forwardingaddress from parameter list 
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
    } else {
       set forwardingaddress 0.0.0.0
    }
    lappend m_topConfig($blockname) -forwardingaddress
    lappend m_topConfig($blockname) $forwardingaddress
    #Abstract externaltag from parameter list 
    set index [lsearch $args -externaltag]
    if {$index != -1} {
       set externaltag [lindex $args [expr $index + 1]]
    } else {
       set externaltag 0
    }
    lappend m_topConfig($blockname) -externaltag
    lappend m_topConfig($blockname) $externaltag
    
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active 1
    }
    #set active true
    lappend m_topConfig($blockname) -active
    lappend m_topConfig($blockname) $active     


    #Abstract flagasbr from parameter list 
    set index [lsearch $args -flagdefaultasbr]
    if {$index != -1} {
       set flagdefaultasbr [lindex $args [expr $index + 1]]
    } else {
       set flagdefaultasbr true
    }
    
    lappend m_topConfig($blockname) -flagdefaultasbr
    lappend m_topConfig($blockname) $flagdefaultasbr
    #Abstract flagasbrsummary from parameter list 
    set index [lsearch $args -flagasbrsummary]
    if {$index != -1} {
       set flagasbrsummary [lindex $args [expr $index + 1]]
    } else {
       set flagasbrsummary true
    }
    
    lappend m_topConfig($blockname) -flagasbrsummary
    lappend m_topConfig($blockname) $flagasbrsummary 

    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    
    lappend m_topConfig($blockname) -metric
    lappend m_topConfig($blockname) $metric

    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       set advertisingrouterid 0.0.0.0
    }
    
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
    } else {
       set flagautoconnect 1
    }
    
    lappend m_topConfig($blockname) -flagautoconnect
    lappend m_topConfig($blockname) $flagautoconnect   

    #Abstract advertisingrouterid from parameter list
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
     } else {
       set advertisingrouterid 0.0.0.0
     }
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid              
       
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopExternalRouteBlock"       
    return $::mainDefine::gSuccess
    } err ] }  {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2CreateTopExternalRouteBlock1 {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
   
    debugPut "enter the proc of Ospfv2Session::Ospfv2CreateTopExternalRouteBlock_internal"

    #Abstract blockname from parameter list     
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2CreateTopExternalRouteBlock_internal API"
    }  
    #Check the uniqueness of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doese not exist, the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }
    set linkname $m_topConfig($blockname,linkname)
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 0
    }

    set flagadvertise [string map {0 false} $flagadvertise]
    set flagadvertise [string map {disable false} $flagadvertise]
    set flagadvertise [string map {off false} $flagadvertise]
    set flagadvertise [string map {1 true} $flagadvertise]
    set flagadvertise [string map {enable true} $flagadvertise]
    set flagadvertise [string map {on true} $flagadvertise]

    array set temp $m_topConfig($blockname)
    set m_topConfig($blockname) ""    
    lappend m_topConfig($blockname) -blockname
    lappend m_topConfig($blockname) $blockname    

    #Abstract startingaddress from parameter list     
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       set startingaddress $temp(-startingaddress)
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
    } else {
       set prefixlen $temp(-prefixlen)
    }
    lappend m_topConfig($blockname) -prefixlen
    lappend m_topConfig($blockname) $prefixlen
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
    } else {
       set number $temp(-number)
    }
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
    } else {
       set modifier $temp(-modifier)
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier

    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
    } else {
       set flagnssa $temp(-flagnssa)
    }

    set flagnssa [string map {0 false} $flagnssa]
    set flagnssa [string map {disable false} $flagnssa]
    set flagnssa [string map {off false} $flagnssa]
    set flagnssa [string map {1 true} $flagnssa]
    set flagnssa [string map {enable true} $flagnssa]
    set flagnssa [string map {on true} $flagnssa]
    
    lappend m_topConfig($blockname) -flagnssa
    lappend m_topConfig($blockname) $flagnssa
    if {$flagnssa == "false"} {
        set lsaType  EXT
    } else {
        set lsaType  NSSA
    }

    #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    lappend m_topConfig($blockname) -metric
    lappend m_topConfig($blockname) $metric
    #Abstract type from parameter list 
    set index [lsearch $args -type]
    if {$index != -1} {
       set type [lindex $args [expr $index + 1]]
    } else {
       set type $temp(-type)
    }
    lappend m_topConfig($blockname) -type
    lappend m_topConfig($blockname) $type
    #Abstract forwardingaddress from parameter list 
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
    } else {
       set forwardingaddress $temp(-forwardingaddress)
    }
    lappend m_topConfig($blockname) -forwardingaddress
    lappend m_topConfig($blockname) $forwardingaddress
    #Abstract externaltag from parameter list 
    set index [lsearch $args -externaltag]
    if {$index != -1} {
       set externaltag [lindex $args [expr $index + 1]]
    } else {
       set externaltag $temp(-externaltag)
    }
    lappend m_topConfig($blockname) -externaltag
    lappend m_topConfig($blockname) $externaltag
    
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active $temp(-active)
    }
    lappend m_topConfig($blockname) -active
    lappend m_topConfig($blockname) $active

    #Abstract flagasbrsummary from parameter list 
    set index [lsearch $args -flagasbrsummary]
    if {$index != -1} {
       set flagasbrsummary [lindex $args [expr $index + 1]]
    } else {
       set flagasbrsummary $temp(-flagasbrsummary)
    }

    set flagasbrsummary [string map {0 false} $flagasbrsummary]
    set flagasbrsummary [string map {disable false} $flagasbrsummary]
    set flagasbrsummary [string map {off false} $flagasbrsummary]
    set flagasbrsummary [string map {1 true} $flagasbrsummary]
    set flagasbrsummary [string map {enable true} $flagasbrsummary]
    set flagasbrsummary [string map {on true} $flagasbrsummary]
    
    lappend m_topConfig($blockname) -flagasbrsummary
    lappend m_topConfig($blockname) $flagasbrsummary

    set index [lsearch $args -flagdefaultasbr]
    if {$index != -1} {
       set flagdefaultasbr [lindex $args [expr $index + 1]]
    } else {
       set flagdefaultasbr $temp(-flagdefaultasbr)
    }

    set flagdefaultasbr [string map {0 false} $flagdefaultasbr]
    set flagdefaultasbr [string map {disable false} $flagdefaultasbr]
    set flagdefaultasbr [string map {off false} $flagdefaultasbr]
    set flagdefaultasbr [string map {1 true} $flagdefaultasbr]
    set flagdefaultasbr [string map {enable true} $flagdefaultasbr]
    set flagdefaultasbr [string map {on true} $flagdefaultasbr]
    
    lappend m_topConfig($blockname) -flagdefaultasbr
    lappend m_topConfig($blockname) $flagdefaultasbr 

    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       set advertisingrouterid $temp(-advertisingrouterid)
    }
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid        
    
    if {$flagdefaultasbr == "true"} { 
        #Abstract asbrid from parameter list 

        set attachedRtr $m_topConfig($blockname,attachedRtr)    
        set asbrid $m_topConfig($attachedRtr,routerId)   

        set flag needNewLink
        if {$m_routerId == $asbrid} {
            set flag needConfigSimulatorRouter
        } else {
            foreach router $m_topNameList {
               catch {
                   if {$asbrid == $m_topConfig($router,routerId)} {
                       set flag needConfigTopRouter
                       set topRouterName $router
                       break
                   }
               }
           }
        }

        set AdvertisingRouterId $asbrid
        lappend m_topConfig($blockname) -asbrid
        lappend m_topConfig($blockname) $asbrid
        set lsaType EXT
    } else { 
        #Abstract asbrid from parameter list 
        set attachedRtr $m_topConfig($blockname,attachedRtr)    
        set abrid $m_topConfig($attachedRtr,routerId)
        set flag needNewLink
        if {$m_routerId == $abrid} {
            set flag needConfigSimulatorRouter
        } else {
            foreach router $m_topNameList {
                catch {
                   if {$abrid == $m_topConfig($router,routerId)} {
                       set flag needConfigTopRouter
                       set topRouterName $router
                       break
                   }
               }
           }
        }

        set AdvertisingRouterId $abrid
        lappend m_topConfig($blockname) -abrid
        lappend m_topConfig($blockname) $abrid
        set lsaType NSSA
    }   
    
    #Create ExternalLsaBlock
 
    set lsaname lsa1
    
    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create ExternalLsaBlock \
                                           -under $m_hOspfv2RouterConfig \
                                           -Active false \
                                           -AdvertisingRouterId $AdvertisingRouterId\
                                           -metric [incr metric $m_topConfig($blockname,linkmetric)]\
                                           -RouteTag $externaltag\
                                           -metrictype [ string map {type_ ""} $type] \
                                           -name $blockname\
                                           -Type $lsaType -active true ] 
    lappend m_handleBylinkName($linkname)    $m_hLsaArrIndexedByLsaName($lsaname)      
    set m_linkStatus($linkname) false
    set attachedRtr $m_topConfig($blockname,attachedRtr)
    set m_routerId2RouternameArr($AdvertisingRouterId) $attachedRtr
    lappend m_handleByRtrName($attachedRtr)   $m_hLsaArrIndexedByLsaName($lsaname)
    set m_topConfig($m_hLsaArrIndexedByLsaName($lsaname),linkObjType) externalRouteBlock
                                                                                                    
                                                                                                   
    #Config Ipv4NetworkBlock                                                                                                    
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv4NetworkBlock]
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock
    stc::config $hIpv4NetworkBlock -AddrIncrement $modifier \
                                                           -NetworkCount $number \
                                                           -PrefixLength $prefixlen\
                                                           -StartIpList $startingaddress
                                                          
    set m_hLsaArrIndexedByTopName($blockname) $m_hLsaArrIndexedByLsaName($lsaname)   

    set m_topConfig($blockname,newLink) ""
    if {$flag == "needNewLink"} {
        
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $m_hSimulatorRouter \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $AdvertisingRouterId  \
                -active false]
        lappend m_handleBylinkName($linkname)  $RouterLsaLink(1)     
        lappend m_handleByRtrName($attachedRtr) $RouterLsaLink(1) 
        set m_topConfig($RouterLsaLink(1),linkObjType) externalRouteBlock
        set m_linkStatus($linkname) false
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $AdvertisingRouterId \
                -PrefixLength "32" \
                -NetworkCount "1" 

        set linkName simulatorRouter-2-externalLsa-$AdvertisingRouterId 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
        
        set RouterLsa(1) [stc::create "RouterLsa" \
                -under $m_hOspfv2RouterConfig \
                -asbr true\
                -LinkStateId "0.0.0.0" \
                -Age "0" \
                -AdvertisingRouterId $AdvertisingRouterId \
                -active false]
        lappend m_handleBylinkName($linkname)   $RouterLsa(1)   
        lappend m_handleByRtrName($attachedRtr) $RouterLsa(1)   
        set m_topConfig($RouterLsa(1),linkObjType) externalRouteBlock
        set m_linkStatus($linkname) false
        
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $RouterLsa(1) \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $m_routerId \
                -active false]
        lappend m_handleBylinkName($linkname)   $RouterLsaLink(1)     
        lappend m_handleByRtrName($attachedRtr) $RouterLsaLink(1)  
        set m_topConfig($RouterLsaLink(1),linkObjType) externalRouteBlock
        set m_linkStatus($linkname) false
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $m_routerId \
                -PrefixLength "32" \
                -NetworkCount "1"      

        set linkName externalLsa-2-simulatorRouter-$AdvertisingRouterId  
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
   
        stc::config $m_hSimulatorRouter -asbr true
    } elseif {$flag == "needConfigTopRouter"}  {
  
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -asbr true
    }    
 

   set m_lsaConfig($blockname) ""
   lappend m_lsaConfig($blockname) -lsatype
   lappend m_lsaConfig($blockname) extlsa    
       
    debugPut "exit the proc of Ospfv2Session::Ospfv2CreateTopExternalRouteBlock_internal"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2SetTopExternalRouteBlock
#
#Description: Config attribute ExternalRouteBlock
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
 
::itcl::body Ospfv2Session::Ospfv2SetTopExternalRouteBlock {args} {
set list ""
if {[catch { 
   set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopExternalRouteBlock"
    

    set extLsaConfig ""
    set routeBlockConfig ""
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2SetTopExternalRouteBlock API"
    }   
    #Check the existence of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $startingaddress]
    } 

    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefixlen]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefixlen]
    }

    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -number]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]
    }

    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -modifier]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]
    }

    #Abstract flagtrafficdest from parameter list 
    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagtrafficdest]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagtrafficdest]
    }

    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnssa]
       incr index      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnssa]
    
    }

    #Abstract forwardingaddress from parameter list    
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -forwardingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $forwardingaddress]

    }

    #Abstract externaltag from parameter list 
    set index [lsearch $args -externaltag]
    if {$index != -1} {
       set externaltag [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -externaltag]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $externaltag]
    }

    
    #Abstract flagasbrsummary from parameter list 
    set index [lsearch $args -flagasbrsummary]
    if {$index != -1} {
       set flagasbrsummary [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagasbrsummary]
       incr index      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagasbrsummary]
    }

    #Abstract type from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnssa]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnssa]
    }

    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]
    }

    set index [lsearch $args -flagdefaultasbr]
    if {$index != -1} {
       set flagdefaultasbr [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagdefaultasbr]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagdefaultasbr]
    }

    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -advertisingrouterid]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $advertisingrouterid]
    }    

    #Abstract type from parameter list 
    set index [lsearch $args -type]
    if {$index != -1} {
       set type [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -type]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $type]
    }  

    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -active]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $active]
    }  

    set index [lsearch $args -flagautoconnect]
    if {$index != -1} {
       set flagautoconnect [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagautoconnect]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagautoconnect]
    }  
    
    if {$m_topConfig($blockname,linked)} {
    
        eval Ospfv2Session::Ospfv2SetTopExternalRouteBlock1 $m_topConfig($blockname) 
    }                                                         
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopExternalRouteBlock"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

::itcl::body Ospfv2Session::Ospfv2SetTopExternalRouteBlock1 {args} {
set list ""
if {[catch { 
   set args [ConvertAttrToLowerCase $args] 
  
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetTopExternalRouteBlock_internal"
    set extLsaConfig ""
    set routeBlockConfig ""
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2SetTopExternalRouteBlock_internal API"
    }   
    #Check the existence of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
   

    #Abstract flagadvertise from parameter list     
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $startingaddress]
       
       lappend routeBlockConfig -StartIpList
       lappend routeBlockConfig $startingaddress
    } 

    #Abstract prefix from parameter list 
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
       set prefixlen [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefixlen]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefixlen]

       lappend routeBlockConfig -PrefixLength
       lappend routeBlockConfig $prefixlen
    }

    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -number]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

       lappend routeBlockConfig -NetworkCount
       lappend routeBlockConfig $number
    }

    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set modifier [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -modifier]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

       lappend routeBlockConfig -AddrIncrement
       lappend routeBlockConfig $modifier
    }

    #Abstract flagtrafficdest from parameter list 
    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagtrafficdest]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagtrafficdest]
    }

    #Abstract active  from parameter list
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -active]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $active]
       if {$active == "enable" || [string tolower $active] == "true"} {
           lappend extLsaConfig -active 
           lappend extLsaConfig TRUE
       } else {

       }
    }
    set active true
     
    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnssa]
       incr index

       set flagnssa [string map {0 false} $flagnssa]
       set flagnssa [string map {disable false} $flagnssa]
       set flagnssa [string map {off false} $flagnssa]
       set flagnssa [string map {1 true} $flagnssa]
       set flagnssa [string map {enable true} $flagnssa]
       set flagnssa [string map {on true} $flagnssa] 
      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnssa]
    }

    #Abstract metric from parameter list
    set lsaConfig ""
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]
       incr metric $m_topConfig($blockname,linkmetric)
       
       lappend extLsaConfig -metric 
       lappend extLsaConfig $metric
       lappend lsaConfig -metric 
       lappend lsaConfig $metric 
    }

    #Abstract forwardingaddress from parameter list    
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -forwardingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $forwardingaddress]
    }

    #Abstract externaltag from parameter list 
    set index [lsearch $args -externaltag]
    if {$index != -1} {
       set externaltag [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -externaltag]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $externaltag]

       lappend extLsaConfig -RouteTag 
       lappend extLsaConfig $externaltag
    }

    #Abstract flagasbr from parameter list 
    set index [lsearch $args -flagasbr]
    if {$index != -1} {
       set flagasbr [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagasbr]
       incr index
 
       set flagasbr [string map {0 false} $flagasbr]
       set flagasbr [string map {disable false} $flagasbr]
       set flagasbr [string map {off false} $flagasbr]
       set flagasbr [string map {1 true} $flagasbr]
       set flagasbr [string map {enable true} $flagasbr]
       set flagasbr [string map {on true} $flagasbr] 
      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagasbr]
    }
    
    #Abstract flagasbrsummary from parameter list 
    set index [lsearch $args -flagasbrsummary]
    if {$index != -1} {
       set flagasbrsummary [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagasbrsummary]
       incr index

       set flagasbrsummary [string map {0 false} $flagasbrsummary]
       set flagasbrsummary [string map {disable false} $flagasbrsummary]
       set flagasbrsummary [string map {off false} $flagasbrsummary]
       set flagasbrsummary [string map {1 true} $flagasbrsummary]
       set flagasbrsummary [string map {enable true} $flagasbrsummary]
       set flagasbrsummary [string map {on true} $flagasbrsummary] 
      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagasbrsummary]
    }

    #Abstract flagdefaultasbr from parameter list
    set index [lsearch $args -flagdefaultasbr]
    if {$index != -1} {
       set flagdefaultasbr [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagdefaultasbr]
       incr index

       set flagdefaultasbr [string map {0 false} $flagdefaultasbr]
       set flagdefaultasbr [string map {disable false} $flagdefaultasbr]
       set flagdefaultasbr [string map {off false} $flagdefaultasbr]
       set flagdefaultasbr [string map {1 true} $flagdefaultasbr]
       set flagdefaultasbr [string map {enable true} $flagdefaultasbr]
       set flagdefaultasbr [string map {on true} $flagdefaultasbr] 
      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagdefaultasbr]
    }

    #Abstract advertisingrouterid from parameter list
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -advertisingrouterid]
       incr index      
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $advertisingrouterid]
    }       

    #Abstract type from parameter list 
    set index [lsearch $args -flagnssa]
    set flag null 
    
    if {$index!= -1} {
        set lsaType NSSA  
    } else {
        set lsaType EXT
    }    

    lappend extLsaConfig -type 
    lappend extLsaConfig $lsaType
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -lsaname]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $lsaname]
          
       set m_lsaConfig($lsaname) ""
       lappend m_lsaConfig($lsaname) -lsatype
       lappend m_lsaConfig($lsaname) extlsa
             
    }

    #Abstract prefix from parameter list 
    set index [lsearch $args -type]
    if {$index != -1} {
       set type [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -type]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $type]
       set type [string map {type_ ""} $type]

       lappend extLsaConfig -MetricType
       lappend extLsaConfig $type
    }    
 
    #Config external lsa
    eval stc::config  $m_hLsaArrIndexedByTopName($blockname)  $lsaConfig -active true 
   
    #Config Ipv4NetworkBlock
    set hIpv4NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv4NetworkBlock]    
    eval stc::config $hIpv4NetworkBlock $routeBlockConfig 
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock
     
     set AdvertisingRouterId [stc::get $m_hLsaArrIndexedByTopName($blockname)  -AdvertisingRouterId]
     set routername $m_routerId2RouternameArr($AdvertisingRouterId) 
     stc::config $m_hLsaArrIndexedByTopName($routername) -Asbr true
     if {$AdvertisingRouterId==$m_routerId} {
         stc::config $m_hSimulatorRouter -Asbr true 
     }   

    if {$flag != ""} {
        foreach link $m_topConfig($blockname,newLink)  {
            stc::delete $m_hLsaArrIndexedByTopName($link)

        }
        set m_topConfig($blockname,newLink) ""
    }
    if {$flag == "needNewLink"} {      
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $m_hSimulatorRouter \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $AdvertisingRouterId  ]
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $abrid \
                -PrefixLength "32" \
                -NetworkCount "1" 

        set linkName simulatorRouter-2-externalLsa-$AdvertisingRouterId 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
        
        set RouterLsa(1) [stc::create "RouterLsa" \
                -under $m_hOspfv2RouterConfig \
                -Abr true\
                -LinkStateId "0.0.0.0" \
                -Age "0" \
                -AdvertisingRouterId $AdvertisingRouterId ]
        
        set RouterLsaLink(1) [stc::create "RouterLsaLink" \
                -under $RouterLsa(1) \
                -LinkType "POINT_TO_POINT" \
                -Metric "1" \
                -LinkId $m_routerId  ]
        
        global Ipv4NetworkBlock
        set Ipv4NetworkBlock(1) [lindex [stc::get $RouterLsaLink(1) -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock(1) \
                -StartIpList $m_routerId \
                -PrefixLength "32" \
                -NetworkCount "1"      

        set linkName externalLsa-2-simulatorRouter-$AdvertisingRouterId  
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
   
        stc::config $m_hSimulatorRouter -Asbr true
    } elseif {$flag == "needConfigTopRouter"}  {
    
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -Asbr true
    } 
    
    ApplyToChassis                                                         
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetTopExternalRouteBlock_internal"       
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2RetrieveTopExternalRouteBlock
#
#Description: Get the attribute of specified ExternalRouteBlock
#
#Input: 1.blockname:Name handler of ExternalRouteBlock
#
#Output:Attribute of ExternalRouteBlock
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2RetrieveTopExternalRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2RetrieveTopExternalRouteBlock"
    
    #Abstract blockname from parameter list   
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify blockname for Ospfv2RetrieveTopExternalRouteBlock"
    }  
    #Check the existence of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }    

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    set  list $m_topConfig($blockname)
    set list [ConvertAttrToLowerCase $list]
    
    if {$args == ""} {
         debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopExternalRouteBlock" 
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding variable value 
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                puts "the item($name) does not exist"
                continue
            }
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                     
       debugPut "exit the proc of Ospfv2Session::Ospfv2RetrieveTopExternalRouteBlock" 
       return $::mainDefine::gSuccess   
    }  
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2DeleteTopExternalRouteBlock
#
#Description: delete specified ExternalRouteBlock
#
#Input: 1.blockname:Name handler of  ExternalRouteBlock
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2DeleteTopExternalRouteBlock {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2DeleteTopExternalRouteBlock"
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv2DeleteTopExternalRouteBlock"
    }  
    #Check the existence of blockname
    set index [lsearch $m_externalRouteBlockList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_externalRouteBlockList"
    }
    set m_externalRouteBlockList [lreplace $m_externalRouteBlockList $index $index]

    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    set index [lsearch $m_topNameList $blockname]
    set m_topNameList [lreplace $m_topNameList $index $index]
    #delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($blockname)

    foreach link $m_topConfig($blockname,newLink)  {
        stc::delete $m_hLsaArrIndexedByTopName($link)
    }
    catch {unset m_topConfig($blockname,newLink)} 
    

    ApplyToChassis    
    catch {unset m_hLsaArrIndexedByTopName($blockname)}
    catch {unset m_topConfig($blockname) }
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2DeleteTopExternalRouteBlock" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: FloodOspfLsa
#
#Description: Advertise Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2AdvertiseLsa {{args ""}} {
set list ""
if {[catch { 
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    debugPut "enter the proc of Ospfv2Session::Ospfv2AdvertiseLsa"
    #Advertise all lsa of ospfv2 router
    stc::perform Ospfv2FloodLsas  -RouterList $m_hOspfv2RouterConfig      
    debugPut "exit the proc of Ospfv2Session::Ospfv2AdvertiseLsa" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: ReAdvertiseOspfLsa
#
#Description: ReAdvertise Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2ReAdvertiseLsa {{args ""}} {
set list ""
if {[catch { 
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    debugPut "enter the proc of Ospfv2Session::Ospfv2ReAdvertiseLsa"
    #ReAdvertise all lsa of current ospfv2 router
    stc::perform Ospfv2ReadvertiseLsa  -RouterList $m_hOspfv2RouterConfig      
    debugPut "exit the proc of Ospfv2Session::Ospfv2ReAdvertiseLsa" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2AgeLsa
#
#Description:Withdraw Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2AgeLsa {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Ospfv2Session::Ospfv2AgeLsa"
    #Abstract lsanamelist from parameter list 
    set index [lsearch $args -lsanamelist] 
    if {$index != -1} {
        set lsanamelist [lindex $args [expr $index + 1]]
    } else {
        error "please specify lsaNameList for Ospfv2AgeLsa"
    }
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]    
    #Call corresponding stc api according to lsatype, age related lsa
    foreach lsaname $lsanamelist {
    
        array set lsaConfigArr $m_lsaConfig($lsaname)
        switch $lsaConfigArr(-lsatype) {
            routerlsa {
                stc::perform Ospfv2AgeRouterLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            networklsa {
                stc::perform Ospfv2AgeNetworkLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            summarylsa {
                stc::perform Ospfv2AgeSummaryLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            extlsa {
                stc::perform Ospfv2AgeExternalLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            telsa {
                stc::perform Ospfv2AgeTeLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            default {
                error "unsupported lsatype($lsaConfigArr(-lsatype))"
            }
        }
    }
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2AgeLsa" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2Enable
#
#Description:Enable ospfv2 routing simulation
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2Enable {{args ""}} {
set list ""
if {[catch { 
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    debugPut "enter the proc of Ospfv2Session::Ospfv2Enable"
    stc::config $m_hOspfv2RouterConfig -active TRUE
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2Enable" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2Disable
#
#Description: Disable ospfv2 routing simulation
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2Disable {{args ""}} {
set list ""
if {[catch { 
    #Convert attribute item(attr) of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]
    
    
    debugPut "enter the proc of Ospfv2Session::Ospfv2Disable"
    stc::config $m_hOspfv2RouterConfig -active FALSE
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2Disable" 
    return $::mainDefine::gSuccess
    } err ]} {
        if {($err == $list) } {              
            return $list
        } elseif {($err == $::mainDefine::gSuccess)} {
            return $::mainDefine::gSuccess
        } else {
            set mainDefine::gErrMsg $err
            puts "error: $err"
            return $mainDefine::gErrCode
        }
    } 
}

############################################################################
#APIName: Ospfv2AdvertiseRouters
#
#Description:Advertise Topo Router
#
#Input: -routerNameList : Topo Router that need to be advertised
#
#Output: None 
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2AdvertiseRouters {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2AdvertiseRouters" 
    set args [ConvertAttrToLowerCase $args] 
    set index [lsearch $args -routernamelist] 
    if {$index != -1} {
        set routernamelist [lindex $args [incr index]]
    } else {
        set routernamelist $m_routerList
    }
    set flag 0
    foreach rtr $routernamelist {
        set index [lsearch $m_routerList $rtr]
        if {$index == -1} {
            error "Router($rtr) does not exist, the existed Router(s) is(are):\n$m_routerList"
        }     
        if {$m_routerName==$rtr} {
            set flag 1
        }
        stc::config $m_hLsaArrIndexedByTopName($rtr) -active true   
        if {[info exist m_handleByRtrName($rtr)]} {        
        foreach hObj $m_handleByRtrName($rtr) {
            stc::config $hObj -active true
        }
        }
    }
    
    if {$flag} {
         set children [stc::get $m_hSimulatorRouter -children ]

         foreach child $children {
              stc::config $child -TosMetrics 1
         }
    }
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2AdvertiseRouters"        
}

############################################################################
#APIName: Ospfv2WithdrawRouters
#
#Description:Withdraw Topo Router that has been advertised before
#
#Input: -routerNameList : Topo Router that need to be withdrawn
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2WithdrawRouters {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2WithdrawRouters" 
    set args [ConvertAttrToLowerCase $args] 
    set index [lsearch $args -routernamelist] 
    if {$index != -1} {
        set routernamelist [lindex $args [incr index]]
    } else {
        set routernamelist $m_routerList
    }
    foreach rtr $routernamelist {
        set index [lsearch $m_routerList $rtr]
        if {$index == -1} {
            error "Router($rtr) does not exist, the existed Router(s) is(are):\n$m_routerList"
        }             
        stc::config $m_hLsaArrIndexedByTopName($rtr) -active false
           
    }
    ApplyToChassis
    debugPut "enter the proc of Ospfv2Session::Ospfv2WithdrawRouters"    
}

############################################################################
#APIName: Ospfv2AdvertiseLinks
#
#Description:Advertise Topo Link
#
#Input: -linkNameList: Topo Link that need to be advertised
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv2Session::Ospfv2AdvertiseLinks {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2AdvertiseLinks" 
    set args [ConvertAttrToLowerCase $args] 
    #parray m_handleBylinkName
    set index [lsearch $args -linknamelist] 
    if {$index != -1} {
        set linknamelist [lindex $args [incr index]]
    } else {
        set linknamelist $m_totalLinkList
    }
    foreach link $linknamelist {
        set index [lsearch $m_totalLinkList $link]
        if {$index == -1} {
            error "Link($link) does not exist, the existed Router(s) is(are):\n$m_totalLinkList"
        }
        set m_linkStatus($link) true
        foreach handle $m_handleBylinkName($link) {
            stc::config $handle -active true
        }
    }
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2AdvertiseLinks"        
}

############################################################################
#APIName: Ospfv2WithdrawLinks
#
#Description:Withdraw Topo Link
#
#Input: -linkNameList: Topo Link that need to be withdrawn
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2WithdrawLinks {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2WithdrawLinks" 
    set args [ConvertAttrToLowerCase $args] 
    set index [lsearch $args -linknamelist] 
    if {$index != -1} {
        set linknamelist [lindex $args [incr index]]
    } else {
        set linknamelist $m_totalLinkList
    }
    foreach link $linknamelist {
        set index [lsearch $m_totalLinkList $link]
        if {$index == -1} {
            error "Link($link) does not exist, the existed Router(s) is(are):\n$m_totalLinkList"
        }
        set m_linkStatus($link) false
        foreach handle $m_handleBylinkName($link) {
            stc::config $handle -active false
        }
    }
    ApplyToChassis
    debugPut "exit the proc of Ospfv2Session::Ospfv2WithdrawLinks"        
}

############################################################################
#APIName: Ospfv2SetFlap
#
#Description:Configure routing flap parameters
#
#Input: 1. AWDTimer:Time-interval from advertise to withdraw, unit is ms
#          2. WADTimer:Time-interval from withdraw to advertise, unit is ms
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2SetFlap {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2SetFlap" 
    set args [ConvertAttrToLowerCase1 $args] 
    set index [lsearch $args -awdtimer] 
    if {$index != -1} {
        set m_awdtimer [lindex $args [incr index]]
    } else {
        set m_awdtimer 5000
    }

    set index [lsearch $args -wadtimer] 
    if {$index != -1} {
        set m_wadtimer [lindex $args [incr index]]
    } else {
        set m_wadtimer 5000
    }
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetFlap"        
}

############################################################################
#APIName: Ospfv2StartFlapRouters
#
#Description:Start flapping specified Topo Router
#
#Input: RouterNameList:Specified Topo Router
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StartFlapRouters {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2StartFlapRouters" 
    set args [ConvertAttrToLowerCase $args] 

    set index [lsearch $args -routernamelist] 
    if {$index != -1} {
        set routernamelist [lindex $args [incr index]]
    } else {
        set routernamelist $m_routerList
    }

    set index [lsearch $args -flapnum] 
    if {$index != -1} {
        set flapnumber [lindex $args [incr index]]
    } else {
        set index [lsearch $args -flapnumber] 
        if {$index != -1} {
           set flapnumber [lindex $args [incr index]]
        } else {
           set flapnumber 10
        } 
    }   

    for {set i 0} {$i<$flapnumber} {incr i} {
        Ospfv2AdvertiseRouters -RouterNameList $routernamelist
        after $m_awdtimer
        Ospfv2WithdrawRouters -RouterNameList $routernamelist
        after $m_wadtimer
        Ospfv2AdvertiseRouters -RouterNameList $routernamelist
        after $m_awdtimer
    }  

    debugPut "exit the proc of Ospfv2Session::Ospfv2StartFlapRouters"        
}

############################################################################
#APIName: Ospfv2StopFlapRouters
#
#Description:Stop flapping Topo Router
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StopFlapRouters {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2StopFlapRouters" 

    debugPut "exit the proc of Ospfv2Session::Ospfv2StopFlapRouters"        
}

############################################################################
#APIName: Ospfv2StartFlapLinks
#
#Description:Start flapping Topo Link
#
#Input: LinkNameList:Specified Topo Link
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StartFlapLinks {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2StartFlapLinks" 
    set args [ConvertAttrToLowerCase $args] 

    set index [lsearch $args -linknamelist] 
    if {$index != -1} {
        set linknamelist [lindex $args [incr index]]
    } else {
        set linknamelist $m_totalLinkList
    }

    set index [lsearch $args -flapnum] 
    if {$index != -1} {
        set flapnumber [lindex $args [incr index]]
    } else {
        set index [lsearch $args -flapnumber] 
        if {$index != -1} {
           set flapnumber [lindex $args [incr index]]
        } else {
           set flapnumber 10
        } 
    }   

    for {set i 0} {$i<$flapnumber} {incr i} {
        Ospfv2AdvertiseLinks -LinkNameList $linknamelist
        after $m_awdtimer
        Ospfv2WithdrawLinks -LinkNameList $linknamelist
        after $m_wadtimer
        Ospfv2AdvertiseLinks -LinkNameList $linknamelist
        after $m_awdtimer
    }  
    debugPut "exit the proc of Ospfv2Session::Ospfv2StartFlapLinks"        
}

############################################################################
#APIName: Ospfv2StopFlapLinks
#
#Description:Stop flapping Topo Link
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StopFlapLinks {args} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2StopFlapLinks" 

    debugPut "exit the proc of Ospfv2Session::Ospfv2StopFlapLinks"        
}

############################################################################
#APIName: Ospfv2GraceRestartAction
#
#Description:ospfv2 Router do GR restart
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv2Session::Ospfv2GraceRestartAction {} {
    debugPut "enter the proc of Ospfv2Session::Ospfv2GraceRestartAction" 
    stc::perfrom Ospfv2RestartRouter -RouterList $m_hOspfv2RouterConfig
    debugPut "exit the proc of Ospfv2Session::Ospfv2GraceRestartAction"        
}

############################################################################
#APIName: Ospfv2ViewRouter
#Description: View Ospfv2 router 
#Input: 
#Output: None
#Coded by: Andy
#############################################################################
::itcl::body Ospfv2Session::Ospfv2ViewRouter {args} {

    debugPut "enter the proc of Ospfv2Session::Ospfv2ViewRouter"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    set ospfv2Router $m_hOspfv2RouterConfig
    set routerStates [stc::get $ospfv2Router -Active]
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
    stc::perform  Ospfv2ViewRoutes -FileName $FileName -RouterList $hRouter
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2ViewRouter"
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: Ospfv2SetBfd
#Description: Set bfdconfig on ospfv2router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv2Session::Ospfv2SetBfd {args} {

    debugPut "enter the proc of Ospfv2Session::Ospfv2SetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    if {$m_bfdSession == ""} {
        stc::config $m_hOspfv2RouterConfig -EnableBfd true
        lappend args -router $m_hRouter -routerconfig $m_hOspfv2RouterConfig
        set m_bfdSession [CreateBfdConfigHLAPI $args]
    } else {
        lappend args -bfdsession $m_bfdSession
        SetBfdConfigHLAPI $args
    }
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2SetBfd"
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: Ospfv2UnsetBfd
#Description: Unset bfdconfig on ospfv2router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv2Session::Ospfv2UnsetBfd {args} {

    debugPut "enter the proc of Ospfv2Session::Ospfv2UnsetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -bfdsession $m_bfdSession -routerconfig $m_hOspfv2RouterConfig
    UnsetBfdConfigHLAPI $args
    set m_bfdSession ""
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2UnsetBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Ospfv2StartBfd
#Description: start bfdconfig on ospfv2router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StartBfd {args} {

    debugPut "enter the proc of Ospfv2Session::Ospfv2StartBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StartBfdHLAPI $args
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2StartBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Ospfv2StartBfd
#Description: start bfdconfig on ospfv2router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv2Session::Ospfv2StopBfd {args} {

    debugPut "enter the proc of Ospfv2Session::Ospfv2StopBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StopBfdHLAPI $args
    
    debugPut "exit the proc of Ospfv2Session::Ospfv2StopBfd"
    return $::mainDefine::gSuccess
}