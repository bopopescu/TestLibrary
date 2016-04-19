###########################################################################
#                                                                        
#  File Name：Ospfv3Protocol.tcl                                                                                              
# 
#  Description：Define STC Ethernet port class and associated API                                             
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
#Define Ospfv3Session class
##########################################
::itcl::class Ospfv3Session {
    #Inherit Router Class
    inherit Router
    #Variable definitions
    public variable m_Ospfv3RouterConfig ""
    public variable m_inputConfig "" 
    public variable m_gridNameList ""
    public variable m_hOspfv3RouterConfig ""
    public variable m_lsaNameList ""
    public variable m_hLsaArrIndexedByLsaName 
    public variable m_lsaConfig 
    public variable m_hOspfv3Result ""
    public variable m_topNameList ""
    public variable m_topConfig
    public variable m_hLsaArrIndexedByTopName
    public variable m_linkLsaNameList ""
    public variable m_linkConfig
    public variable m_routerIp ""
    public variable m_linkNameList ""
    public variable m_ipv6IfAddr ""
    public variable m_hIpv6If1 ""
    public variable m_hIpv6If2 ""
    public variable m_hResultDataSet ""
    public variable m_hGridTopologyGenParams ""
    public variable m_configRouterParams
    public variable m_hL2If1 ""
    public variable m_hSimulatorRouter ""
    public variable m_portType "ethernet"
    public variable m_startingAddressListFlag
    public variable m_bfdSession ""
    
    #Constructor function
    constructor { routerName routerType routerId hRouter portName hProject hIpv61 hIpv62 portType} \
    { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
        
        set m_portType $portType
        #Create Ospfv3RouterConfig
        set m_hOspfv3RouterConfig [stc::create  Ospfv3RouterConfig -under $m_hRouter]

        #Get Ethernet interface
        if {$m_portType == "ethernet"} {
            set m_hL2If1 [stc::get $hRouter -children-EthIIIf] 
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set m_hL2If1 [stc::get $hRouter -children-HdlcIf]
            } else {
                set m_hL2If1 [stc::get $hRouter -children-PppIf]
            }
        } 
        
        set m_hMacAddress $m_hL2If1 
        
        set m_hIpv6If1 $hIpv61
        set m_hIpv6If2 $hIpv62
     
        set m_hIpAddress $m_hIpv6If1 

        #Create Ospfv3Result
        set m_hOspfv3Result [stc::create Ospfv3RouterResults -under $m_hOspfv3RouterConfig ]
    }

     #Destructor Function
    destructor {
    }

    #Method Declearation
    public method Ospfv3SetSession
    public method Ospfv3RetrieveRouter
    public method Ospfv3Enable
    public method Ospfv3Disable
    public method Ospfv3CreateTopGrid
    public method Ospfv3RetrieveTopGrid
    public method Ospfv3DeleteTopGrid 
    public method Ospfv3CreateTopRouter
    public method Ospfv3RetrieveTopRouter 
    public method Ospfv3DeleteTopRouter
    public method Ospfv3CreateTopRouterLink
    public method Ospfv3DeleteTopRouterLink 
    public method Ospfv3RetrieveTopRouterLink 
    public method Ospfv3CreateTopNetwork
    public method Ospfv3DeleteTopNetwork
    public method Ospfv3RetrieveTopNetwork
    public method Ospfv3CreateTopExternalPrefixRouteBlock
    public method Ospfv3SetTopExternalPrefixRouteBlock
    public method Ospfv3RetrieveTopExternalPrefixRouteBlock
    public method Ospfv3DeleteTopExternalPrefixRouteBlock
    public method Ospfv3CreateTopInterAreaPrefixRouteBlock
    public method Ospfv3SetTopInterAreaPrefixRouteBlock
    public method Ospfv3RetrieveTopInterAreaPrefixRouteBlock
    public method Ospfv3DeleteTopInterAreaPrefixRouteBlock

    public method Ospfv3CreateTopIntraAreaPrefixRouteBlock
    public method Ospfv3SetTopIntraAreaPrefixRouteBlock
    public method Ospfv3RetrieveTopIntraAreaPrefixRouteBlock
    public method Ospfv3DeleteTopIntraAreaPrefixRouteBlock

    public method Ospfv3RetrieveRouterStats    
    public method Ospfv3RetrieveRouterStatus 
    public method Ospfv3AdvertiseOspfLsa
    public method Ospfv3ReAdvertiseOspfLsa
    public method Ospfv3AgeOspfLsa
    
    public method Ospfv3SetBfd
    public method Ospfv3UnsetBfd
    public method Ospfv3StartBfd
    public method Ospfv3StopBfd
}
############################################################################
#APIName: Ospfv3ApplyToChassis
#
#Description: Apply Configuration to STC Chassis
#
#Input: None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

proc Ospfv3ApplyToChassis {} {
    debugPut "Apply config to Chassis"
    stc::apply
}

proc GetGatewayIpv6 {ipv6Addr} {
    set list [split $ipv6Addr :]
    set len [llength $list]
    set tail 1
    if {[lindex $list [expr $len - 1]] == 1} {
        set tail 2
    }
    set addr [lindex $list 0]
    for {set i 1} {$i < [expr $len - 1]} {incr i} {
        append addr :[lindex $list $i]        
    }
    append addr :$tail
    return $addr
}
proc ExternalRoutetagConvert {routeTag} {
set byte1 [expr ($routeTag >> 24) & 0xff]
set byte2 [expr ($routeTag >> 16) & 0xff]
set byte3 [expr ($routeTag >> 8) & 0xff]
set byte4 [expr $routeTag  & 0xff]
return $byte1.$byte2.$byte3.$byte4
}
############################################################################
#APIName: Ospfv3SetSession
#
#Description: Config the attribute of Ospfv3 Router
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3SetSession {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3SetSession"
    set m_inputConfig ""
    set m_Ospfv3RouterConfig ""
    #Abstract ipaddr from parameter list
    set index [lsearch $args -ipaddr]
    if {$index != -1} {
       set ipaddr [lindex $args [expr $index + 1]]
       set m_configRouterParams(-ipaddr) $ipaddr 
       set m_routerIp $ipaddr
    } else {
       if {$m_routerIp == ""} {
           error "please specify IpAddr for Ospfv3SetSession(Ospfv2)"
       } else {
           set ipaddr $m_routerIp
       }
    }
    #Abstract prefixlen from parameter list
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
         set m_configRouterParams(-prefixlen) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-prefixlen)]} {
            set m_configRouterParams(-prefixlen) 64
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
            set m_configRouterParams(-networktype) broadcast
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
            set m_configRouterParams(-pduoptionvalue) "V6BIT|RBIT|EBIT"
        }        
    }
    set pduoptionvalue $m_configRouterParams(-pduoptionvalue)

    #Abstract sutipaddress from parameter list  
    set index [lsearch $args -sutipaddress]
    if {$index != -1} {
         set m_configRouterParams(-sutipaddress) [lindex $args [expr $index + 1]]   
    } else {
        if {![info exist m_configRouterParams(-sutipaddress)]} {
            set m_configRouterParams(-sutipaddress) 2000::1
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
            set m_configRouterParams(-sutrouterid) 1.1.1.2
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

    #Abstract mtu from parameter list  
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
            set m_configRouterParams(-active) enable
        }        
    }
    set active $m_configRouterParams(-active)

    #Abstract authenticationtype from parameter list  
    set index [lsearch $args -instanceid]
    if {$index != -1} {
         set m_configRouterParams(-instanceid) [lindex $args [expr $index + 1]]     
    } else {
        if {![info exist m_configRouterParams(-instanceid)]} {
            set m_configRouterParams(-instanceid) 0
        }        
    }
    set instanceid $m_configRouterParams(-instanceid)

    #Get the value of TestLinkLocalAddr
    set index [lsearch $args -testlinklocaladdr] 
    if {$index != -1} {
        set TestLinkLocalAddr [lindex $args [expr $index + 1]]
    } 
    if {[info exists TestLinkLocalAddr]} { 
        stc::config $m_hIpv6If1 -Address $TestLinkLocalAddr -PrefixLength $prefixlen -Gateway [GetGatewayIpv6 $TestLinkLocalAddr]]     
    }

    #Abstract password from parameter list                                                              
    #Config ipv6 interface of ospfv3 router
    stc::config $m_hIpv6If2 -Address $ipaddr\
                                         -PrefixLength $prefixlen\
                                         -Gateway [GetGatewayIpv6 $ipaddr]]                                                   
    #Config mtu interface of ospfv3 router               
    
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
    #Config ospfv3 router
    set active [string map {enable true} $active]
    set active [string map {on true} $active]
    set active [string map {1 true} $active]
    set active [string map {disabel false} $active]
    set active [string map {off false} $active]
    set active [string map {0 false} $active]

    set flagneighbordr [string map {enable true} $flagneighbordr]
    set flagneighbordr [string map {on true} $flagneighbordr]
    set flagneighbordr [string map {1 true} $flagneighbordr]
    set flagneighbordr [string map {disabel false} $flagneighbordr]
    set flagneighbordr [string map {off false} $flagneighbordr]
    set flagneighbordr [string map {0 false} $flagneighbordr]

    if {$flagneighbordr == "true"} {
        set routerpriority 255
    }
    
    stc::config $m_hRouter  -routerid $routerid
    eval stc::config $m_hOspfv3RouterConfig   -AreaId  $area\
                                                                        -NetworkType $networktype\
                                                                        -Options $pduoptionvalue\
                                                                        -HelloInterval $hellointerval\
                                                                        -RouterDeadInterval $deadinterval\
                                                                        -RetransmitInterval $retransmitinterval\
                                                                        -FloodDelay $transitdelay\
                                                                        -IfCost $interfacecost\
                                                                        -RouterPriority $routerpriority\
                                                                        -InstanceId $instanceid\
                                                                        -active $active
    set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]       
    set m_topConfig(simulator,routerType) "0"
  
    #Find and config the Mac address from Host according to ipaddr
    SetMacAddress $ipaddr "Ipv6"

    Ospfv3ApplyToChassis
             
    debugPut "exit the proc of Ospfv3Session::Ospfv3SetSession"    
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
#APIName: Ospfv3RetrieveRouter
#
#Description: Get the attribute of Ospfv2 Router
#
#Input: None
#
#Output: Attribute of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveRouter {{args ""}} { 
set list ""
if {[catch { 
   #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveRouter"
    #Return configuration information of ospfv3 router
    debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveRouter"    

    array set list1 [stc::get $m_hOspfv3RouterConfig]  
    set list ""
    lappend list -area
    lappend list $list1(-AreaId)
    lappend list -networktype
    lappend list $list1(-NetworkType)
    lappend list -pduoptionvalue
    lappend list $list1(-Options)
    lappend list -hellointerval
    lappend list $list1(-HelloInterval)
    lappend list -deadinterval
    lappend list $list1(-RouterDeadInterval)
    lappend list -retransmitinterval
    lappend list $list1(-RetransmitInterval)
    lappend list -transitdelay
    lappend list $list1(-FloodDelay)
    lappend list -interfacecost
    lappend list $list1(-IfCost)
    lappend list -routerpriority
    lappend list $list1(-RouterPriority)
    lappend list -active
    lappend list $list1(-Active)
    lappend list -ipaddr
    lappend list $m_routerIp
    lappend list -prefixlen
    lappend list $m_configRouterParams(-prefixlen)
    lappend list -flagneighbordr
    lappend list $m_configRouterParams(-flagneighbordr)
    lappend list -instanceid
    lappend list $m_configRouterParams(-instanceid)
    lappend list -state
    lappend list $list1(-NeighborState)
    
    set list [ConvertAttrToLowerCase $list]  
    
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
#APIName: Ospfv3CreateTopGrid
#
#Description: Create Grid of specified format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopGrid {args}  {
set list ""
if {[catch { 

    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopGrid"
    
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
    set index [lsearch $m_topNameList -gridname]
    if {$index != -1} {
       error "The GridName($gridname) already existed,please specify another one, the existed GridName(s) is(are) as following:\\n $m_topNameList"
    } 
    lappend m_topConfig($gridname) -gridname
    lappend m_topConfig($gridname) $gridname
    lappend m_gridNameList $gridname
    lappend gridConfigList -name
    lappend gridConfigList $gridname
    lappend $m_topNameList $gridname
    set m_topConfig($gridname,routerId) ""

    #Convert attr of parameter list to lower-case
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

    set index [lsearch $args -connectedgridrows]
    if {$index != -1} {
       set connectedgridrows [lindex $args [expr $index + 1]]
    } else {
       set connectedgridrows 1
    }
    lappend m_topConfig($gridname) -connectedgridrows 
    lappend m_topConfig($gridname) $connectedgridrows
    lappend gridConfigList -AttachRowIndex
    lappend gridConfigList $connectedgridrows
    #Abstract connectedgridcolumns from parameter list 
    set index [lsearch $args -connectedgridcolumns]
    if {$index != -1} {
       set connectedgridcolumns [lindex $args [expr $index + 1]]
    } else {
       set connectedgridcolumns 1
    }
    lappend m_topConfig($gridname) -connectedgridcolumns 
    lappend m_topConfig($gridname) $connectedgridcolumns
    lappend gridConfigList -AttachColumnIndex
    lappend gridConfigList  $connectedgridcolumns

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
       error "please specify startingrouterid for Ospfv3CreateTopGrid "
    }
    lappend m_topConfig($gridname) -startingrouterid 
    lappend m_topConfig($gridname) $startingrouterid
    lappend lsaGenConfigList  -RouterIdStart
    lappend lsaGenConfigList  $startingrouterid 

    #Abstract startingrouterid from parameter list    
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
    
    #Create Ospfv2LsaGenParams 
    set hOspfv2LsaGenParams [eval stc::create Ospfv3LsaGenParams  \
                                                                                 -under $m_hProject\
                                                                                 -SelectedRouterRelation-Targets $m_hRouter\
                                                                                 -active TRUE\
                                                                                 $lsaGenConfigList ]
   set m_hLsaArrIndexedByTopName($gridname,parent)  $hOspfv2LsaGenParams                                                                                
    
   #Create GridTopologyGenParams 
   set m_hGridTopologyGenParams [eval stc::create GridTopologyGenParams \
                                                                                 -under $hOspfv2LsaGenParams\
                                                                                 -active TRUE\
                                                                                 $gridConfigList ]      
   set m_hLsaArrIndexedByTopName($gridname)  $m_hGridTopologyGenParams                                                                                    
     
   #Delete corresponding lsa of grid topo
    stc::perform RouteGenApply -GenParams $hOspfv2LsaGenParams
    array set arr $m_topConfig($gridname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {                     
        Ospfv3ApplyToChassis
    }
    
   
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopGrid"    
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
#APIName: Ospfv3RetrieveTopGrid
#
#Description: Get Name handler of Grid
#
#Input: 1.gridname:Name handler of Grid 
#
#Output: Attribute of Grid
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopGrid {args}  {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopGrid"
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

    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase1 $args]  
      
    #Return configuration of grid
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($gridname,parent)]
    array set list2 [stc::get $m_hLsaArrIndexedByTopName($gridname)]
    set list ""
    lappend list -gridname
    lappend list $list2(-Name)
    lappend list -startingrouterid
    lappend list $list1(-RouterIdStart)
    lappend list -routeridstep
    lappend list $list1(-RouterIdStep)
    lappend list -gridrows
    lappend list $list2(-Rows)
    lappend list -gridcolumns
    lappend list $list2(-Columns)
    lappend list -connectedgridrows
    lappend list $list2(-AttachRowIndex)
    lappend list -connectedgridcolumns
    lappend list $list2(-AttachColumnIndex) 
    set list [ConvertAttrToLowerCase $list] 
    
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
        debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopGrid"                         
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
#APIName: Ospfv3DeleteTopGrid
#
#Description: Delete specified Ospf Grid
#
#Input: 1.gridname:Name handler of Grid
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopGrid {args}  {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopGrid"
      #Abstract gridname from parameter list   
    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
    } else {
       error "please specify GridName for CreateOspfv2Grid API"
    }
    #Check existence of gridnamde
    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
       error "The GridName($gridname) does not exist, the existed GridName(s) is(are) as following:\n$m_gridName"
    } 
 
    set m_gridNameList [lindex $m_gridNameList $index $index]
    #Delete grid
    stc::delete  $m_hLsaArrIndexedByTopName($gridname)
    stc::perform RouteGenApply -GenParams $m_hLsaArrIndexedByTopName($gridname,parent)
    stc::delete $m_hLsaArrIndexedByTopName($gridname,parent)    
    catch {unset m_hLsaArrIndexedByTopName($gridname)}
    catch {unset m_hLsaArrIndexedByTopName($gridname,parent)}
    
    Ospfv3ApplyToChassis
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopGrid"       
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
#APIName: Ospfv3RetrieveRouterStats
#
#Description: Retrieve current statistics of Ospfv2 Router
#
#Input:None 
#
#Output: Current statistics of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveRouterStats {{args ""}} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveRouterStats"
    Ospfv3ApplyToChassis
    debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveRouterStats" 
    #Refresh statistics of ospfv3 router
     set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_ospfv3RouterResultHandle ]
     }
     set ospfv3RouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $ospfv3RouterResultHandle  ]
     } err]} {
         return $errorCode
     }
    
    set waitTime 2000
    after $waitTime
    #Get and return statistics of ospfv3 router
    array set list1 [stc::get $m_hOspfv3Result]
    set list ""
    lappend list -numhelloreceived
    lappend list $list1(-RxHello)
    lappend list -numdbdreceived
    lappend list $list1(-RxDd)
    lappend list -numrtrlsareceived
    lappend list $list1(-RxRouterLsa)
    lappend list -numnetlsareceived
    lappend list $list1(-RxNetworkLsa)
    lappend list -numsuminterprefixlsareceived
    lappend list $list1(-RxInterAreaPrefixLsa)
    lappend list -numsuminterrouterlsareceived
    lappend list $list1(-RxInterAreaRouterLsa)
    lappend list -numextlsareceived
    lappend list $list1(-RxAsExternalLsa)
    lappend list -intraprefixlsareceived
    lappend list $list1(-RxIntraAreaPrefixLsa)
    lappend list -numtype7lsareceived
    lappend list $list1(-RxNssaLsa)

    lappend list -numhellosent
    lappend list $list1(-TxHello)
    lappend list -numdbdsent
    lappend list $list1(-TxDd)
    lappend list -numrtrlsasent
    lappend list $list1(-TxRouterLsa)
    lappend list -numnetlsasent
    lappend list $list1(-TxNetworkLsa)
    lappend list -numsuminterprefixlsasent
    lappend list $list1(-TxInterAreaPrefixLsa)
    lappend list -numsuminterrouterlsasent
    lappend list $list1(-TxInterAreaRouterLsa)
    lappend list -numextlsasent
    lappend list $list1(-TxAsExternalLsa)
    lappend list -intraprefixlsasent
    lappend list $list1(-TxIntraAreaPrefixLsa)
    lappend list -numtype7lsasent
    lappend list $list1(-TxNssaLsa)

    
    set args [ConvertAttrToLowerCase $args]

    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
#APIName: Ospfv3CreateTopRouter
#
#Description: Create Router of spedified format
#
#Input: Details as API document
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopRouter {args } {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopRouter"
    
    set stcAttrConfig ""
    #Abstract routername from parameter list     
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv3CreateTopRouter"
    }  
    #Check the uniqueness of routername
    set index [lsearch $m_topNameList $routername]
    if {$index != -1} {
       error "The routername($routername) is already existed, please specify another one,the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }
    #Abstract routerlsaname from parameter list     
    set index [lsearch $args -routerlsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]

       set index [lsearch $m_lsaNameList $lsaname]
       if {$index != -1} {
           error "the lsaname($lsaname) is already exist,please specify another one.the existed lsaname(s) is(are):\n $m_lsaNameList"
       }       
    } else {
       set lsaname $routername
    }
    lappend m_topConfig($routername) -routerlsaname
    lappend m_topConfig($routername) $lsaname

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]       
    } else {
       set flagadvertise 1
    }
    lappend m_topConfig($routername) -flagadvertise
    lappend m_topConfig($routername) $flagadvertise    
    #Abstract routerid from parameter list     
    set index [lsearch $args -routerid]
    if {$index != -1} {
       set routerid [lindex $args [expr $index + 1]]             
    } else {
       error "please specify routerId for Ospfv3CreateTopRouter"
    }
    lappend m_topConfig($routername) -routerid
    lappend m_topConfig($routername) $routerid
    set m_topConfig($routername,routerId) $routerid

    #Check and ensure the uniqueness of routerId
    set routerIdList ""
    foreach router $m_topNameList {
        lappend routerIdList $m_topConfig($router,routerId)
        
    }
    
    foreach router $m_topNameList {
        set rId $m_topConfig($router,routerId)
        if {$rId == $routerid} {
            error "routerId($routerid) is duplicated with routerId of existed router($router), please specify another one. the existed routerId(s) is: \n $routerIdList"
        }
    }
    #Add to list, the position can not be front
    lappend m_topNameList $routername
    
    
    #Abstract routertypevalue from parameter list 
    set index [lsearch $args -routertypevalue]
    if {$index != -1} {
       set routertypevalue [lindex $args [expr $index + 1]]
    } else {
       set routertypevalue normal
    }
   lappend m_topConfig($routername) -routertypevalue
   lappend m_topConfig($routername) $routertypevalue  
   
   set routertypevalue [string map {normal 0} $routertypevalue]
   set routertypevalue [string map {abr BBIT} $routertypevalue]
   set routertypevalue [string map {asbr EBIT} $routertypevalue]
   set routertypevalue [string map {vl VBIT} $routertypevalue]
   set m_topConfig($routername,routerType) $routertypevalue

    lappend m_topConfig($routername) -linknum
    lappend m_topConfig($routername) 0
    lappend m_topConfig($routername) -linknamelist
    lappend m_topConfig($routername) ""

    #Create Ospfv3RouterLsa
    set m_hLsaArrIndexedByLsaName($lsaname) [eval stc::create Ospfv3RouterLsa   \
                                                                                  -under $m_hOspfv3RouterConfig\
                                                                                  -AdvertisingRouterId $routerid\
                                                                                  -LinkStateId 0\
                                                                                  -routertype $routertypevalue]
    set m_hLsaArrIndexedByTopName($routername)  $m_hLsaArrIndexedByLsaName($lsaname)   
    
             

    set m_lsaConfig($lsaname)  ""
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  routerlsa
    
    array set arr $m_topConfig($routername)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopRouter"       
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
#APIName: Ospfv3RetrieveTopRouter
#
#Description:Retrieve attribute of Router
#
#Input: 1.routername:Name handler of Router
#
#Output: Attribute of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopRouter {args} {
set list ""
if {[catch { 
    set args [ConvertAttrToLowerCase $args] 

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopRouter"
    #Abstract routername from parameter list  
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify routername for Ospfv3RetrieveTopRouter"
    }  
    #Check existence of routername
    set index [lsearch $m_topNameList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }
           
    #Return configuration infomation of router
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($routername)]
    puts "m_topConfig($routername)=$m_topConfig($routername)"
    array set list2 $m_topConfig($routername)
    lappend list -routerid
    lappend list $list1(-AdvertisingRouterId)
    lappend list -routertypevalue
    lappend list $list2(-routertypevalue)
    lappend list -linknum
    lappend list $list2(-linknum)
    lappend list -linknamelist
    lappend list $list2(-linknamelist)
    set list [ConvertAttrToLowerCase $list] 
    
    if {$args == ""} {
         debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopRouter"
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
       debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopRouter"                  
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
#APIName: Ospfv3DeleteTopRouter
#
#Description: Delete specified Router
#
#Input: 1.RouterName:Name handler of Router
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopRouter {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]


    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopRouter"
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv3RetrieveTopRouter"
    }  
    #Check existence of routername
    set index [lsearch $m_topNameList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }

    set m_topNameList [lreplace $m_topNameList $index $index]
    #Delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($routername)
    #Delete all lsa of other-2-self all lsa of
    #parray m_topConfig
    if {[info exist m_topConfig($routername,links,other-2-self)]} {
        foreach link $m_topConfig($routername,links,other-2-self) {
            stc::delete $m_hLsaArrIndexedByTopName($link) 
        }
    }
    catch {unset $m_topConfig($routername,links,other-2-self)}
    catch {unset $m_topConfig($routername,links,self-2-other)}
    catch {unset $m_topConfig($routername,routerId)}
    #Delete routername form list
    set index [lsearch $m_topConfig($routername) -routerlsaname]
    if {$index != -1} {
        set routerlsaname [lindex $m_topConfig($routername) [expr $index + 1]]

        set index [lsearch $m_lsaNameList $routerlsaname]
        if {$index != -1} {
            set m_lsaNameList [lreplace $m_lsaNameList $index $index]
        }
    }


    Ospfv3ApplyToChassis
    catch {unset m_topConfig($routername)}
    catch {unset m_hLsaArrIndexedByTopName($routername)}
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopRouter"       
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
#APIName: Ospfv3CreateTopRouterLink
#
#Description: Create RouterLink of specified format 
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopRouterLink {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopRouterLink"
    
     #Abstract routername from parameter list  
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv3CreateTopRouter"
    }  
    #Check existence of routername
    set index [lsearch $m_topNameList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }    
    
    #Abstract linkname from parameter list  
    set index [lsearch $args -linkname]
    if {$index != -1} {
        set linkname [lindex $args [expr $index + 1]]
    } else {
        error "please specify linkname for Ospfv3CreateTopRouterLink"
    }
    set index1 [lsearch $m_topConfig($routername) -linknamelist]
    incr index1
    set linknamelist [lindex  $m_topConfig($routername) $index1]
    set index [lsearch $linknamelist $linkname]
    if {$index != -1} {
        error "The linkname($linkname) is already existed in router($routername), please specify another one,the existed linkname(s) is(are) as following:\
          \n $linknamelist"
    }
    lappend linknamelist $linkname
    set $m_topConfig($routername) [lreplace $m_topConfig($routername) $index1 $index1 $linknamelist]
    lappend  m_topConfig($routername,links,self-2-other) $linkname

    set args [ConvertAttrToLowerCase1 $args]     
    
    #Abstract linktype from parameter list 
    set index [lsearch $args -linktype]
    if {$index != -1} {
       set linktype [lindex $args [expr $index + 1]]       
    } else {
       set linktype p2p
    }
    lappend m_linkConfig($routername,$linkname) -linktype
    lappend m_linkConfig($routername,$linkname) $linktype
    set linktype [string map {p2p POINT_TO_POINT} $linktype]
    set linktype [string map {transit TRANSIT_NETWORK} $linktype]
    set linktype [string map {vl VIRTUAL_LINK} $linktype]
    
    #Abstract neighborrouterid from parameter list 
    set index [lsearch $args -neighborrouterid]
    if {$index != -1} {
       set neighborrouterid [lindex $args [expr $index + 1]]       
    } else {
       error "please specify neighborrouterid for Ospfv3CreateTopRouterLink"
    }
    lappend m_linkConfig($routername,$linkname) -neighborrouterid
    lappend m_linkConfig($routername,$linkname) $neighborrouterid
    #Abstract linkinterfaceaddress from parameter list 
    set index [lsearch $args -linkinterfaceaddress]
    if {$index != -1} {
       set linkinterfaceaddress [lindex $args [expr $index + 1]]       
    } else {
       error "please specify linkinterfaceaddress for Ospfv3CreateTopRouterLink"
    }
    lappend m_linkConfig($routername,$linkname) -linkinterfaceaddress
    lappend m_linkConfig($routername,$linkname) $linkinterfaceaddress
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]       
    } else {
       set flagadvertise 1
    }
    lappend m_linkConfig($routername,$linkname) -flagadvertise
    lappend m_linkConfig($routername,$linkname) $flagadvertise
    if {$flagadvertise == 0} {
        set active FALSE
    } else {
        set active TRUE
    }

    #Abstract linkmetric from parameter list 
    set index [lsearch $args -linkmetric]
    if {$index != -1} {
       set linkmetric [lindex $args [expr $index + 1]]       
    } else {
       set linkmetric 1
    }
    lappend m_linkConfig($routername,$linkname) -linkmetric
    lappend m_linkConfig($routername,$linkname) $linkmetric
    #Abstract linkinterfaceid from parameter list 
    set index [lsearch $args -linkinterfaceid]
    if {$index != -1} {
       set linkinterfaceid [lindex $args [expr $index + 1]]       
    } else {
       set linkinterfaceid 0
    }
    lappend m_linkConfig($routername,$linkname) -linkinterfaceid
    lappend m_linkConfig($routername,$linkname) $linkinterfaceid
    #Abstract neighborinterfaceid from parameter list 
    set index [lsearch $args -neighborinterfaceid]
    if {$index != -1} {
       set neighborinterfaceid [lindex $args [expr $index + 1]]       
    } else {
       set neighborinterfaceid 1
    }
    lappend m_linkConfig($routername,$linkname) -neighborinterfaceid
    lappend m_linkConfig($routername,$linkname) $neighborinterfaceid

   #Create Ospfv3RouterLsaIf
    set linklsaname linklsa1

    set m_hLsaArrIndexedByLsaName($linklsaname) [stc::create "Ospfv3RouterLsaIf" \
                -under $m_hLsaArrIndexedByTopName($routername) \
                -IfType "POINT_TO_POINT" \
                -Metric "1" \
                -NeighborRouterId $neighborrouterid\
                -name $linkname]                                                                                                          
                                                                                                    
  
    
    set m_hLsaArrIndexedByTopName($routername,$linkname) $m_hLsaArrIndexedByLsaName($linklsaname)        
    #Increase linknum
    set index [lsearch $m_topConfig($routername) -linknum]
    if {$index != -1} {
        set linknum [lindex $m_topConfig($routername) [expr $index + 1]]
        incr linknum
        incr index
        set m_topConfig($routername) [lreplace $m_topConfig($routername) $index $index $linknum]
        
    }
    #Add linkname to list
    set index [lsearch $m_topConfig($routername) -linknamelist]
    if {$index != -1} {
    
        set linknamelist [lindex $m_topConfig($routername) [expr $index + 1]]        
        lappend linknamelist $linkname
        
        incr index
        set m_topConfig($routername)  [lreplace $m_topConfig($routername) $index $index $linknamelist]
        

    }

    if {($linktype == "POINT_TO_POINT") ||($linktype == "VIRTUAL_LINK")} {
        set linkName ""
        if {$neighborrouterid == $m_routerId} {
           #Create linkLsa of simulator-2-self 
            set linkName simulatorRouter-2-$routername
            lappend  m_topConfig($routername,links,other-2-self) $linkName
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]                                                                                                          
            set m_hLsaArrIndexedByTopName($linkName) [stc::create "Ospfv3RouterLsaIf" \
                                                                                                           -under $m_hSimulatorRouter \
                                                                                                           -IfType $linktype \
                                                                                                           -Metric "1" \
                                                                                                           -NeighborRouterId $m_topConfig($routername,routerId)]                                                                                                              
        
        } else {
            #Create linkLsa of topRouter-2-self
            set topRouter ""
            foreach router $m_topNameList {
                if {$m_topConfig($router,routerId) == $neighborrouterid} {
                    set topRouter $router
                    break
                }
            }
            if {$topRouter != ""} {
                set linkName $topRouter-2-$routername
                lappend  m_topConfig($routername,links,other-2-self) $linkName      
                set m_hLsaArrIndexedByTopName($linkName) [stc::create Ospfv3RouterLsaIf \
                                                                                                              -under $m_hLsaArrIndexedByTopName($topRouter)\
                                                                                                              -IfType $linktype \
                                                                                                              -NeighborRouterId $m_topConfig($routername,routerId)]                                                                                                                  

            }
        }
    }  
    
    array set arr $m_linkConfig($routername,$linkname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }  
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopRouterLink"       
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
#APIName: Ospfv3RetrieveTopRouterLink
#
#Description: Retrieve the attribute of RouterLink
#
#Input: 1.linklsaname:Name handler of RouterLink
#
#Output: Attribute of RouterLink
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopRouterLink {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]


    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopRouterLink"

    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for AddTopRouter"
    }
    #Check existence of routername
    set index [lsearch $m_topNameList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    } 
        
    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify linkname for Ospfv3RetrieveTopRouter"
    }  
    #Check existence of linkname
    set index1 [lsearch $m_topConfig($routername) -linknamelist]
    incr index1
    set linkList [lindex $m_topConfig($routername) $index1]
    set index [lsearch $linkList $linkname]
    if {$index == -1} {
       error "The linkname($linkname) does not exist in router($routername), the existed routername(s) is(are) as following:\
       \n $linkList"
    }              
    #Return config information of link
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($routername,$linkname)]
    array set list2 $m_linkConfig($routername,$linkname)
    set list ""
    lappend list -routername
    lappend list $routername
    lappend list -linkname
    lappend list $linkname
    lappend list -linktype
    lappend list $list2(-linktype)
    lappend list -linkinterfaceid
    lappend list $list1(-IfId)
    lappend list -neighborinterfaceid
    lappend list $list1(-NeighborIfId)
    lappend list -flagadvertise
    lappend list $list2(-flagadvertise)
    lappend list -neighborrouterid
    lappend list $list1(-NeighborRouterId)
    lappend list -linkinterfaceaddress
    lappend list $list2(-linkinterfaceaddress)
    lappend list -linkmetric
    lappend list $list1(-Metric)
    set args [ConvertAttrToLowerCase $args]
     debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopRouterLink"
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
#APIName: Ospfv3DeleteTopRouterLink
#
#Description: Delete specified RouterLink
#
#Input: 1.linklsaname:Name handler of RouterLink
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopRouterLink {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]


    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopRouterLink"
    
    #Abstract routername from parameter list 
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify routername for Ospfv3CreateTopRouter"
    }
    #Check existence of routername
    set index [lsearch $m_topNameList $routername]
    if {$index == -1} {
       error "The routername($routername) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    } 
        
    #Abstract linkname from parameter list 
    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify linkname for Ospfv3RetrieveTopRouter"
    }  
    #Check existence of linkname
    set index1 [lsearch $m_topConfig($routername) -linknamelist]
    incr index1
    set linkList [lindex $m_topConfig($routername) $index1]
    set index [lsearch $linkList $linkname]
    if {$index == -1} {
       error "The linkname($linkname) does not exist in router($routername), the existed routername(s) is(are) as following:\
       \n $linkList"
    }  
    set linkList [lreplace $linkList $index $index]
    set m_topConfig($routername) [lreplace $m_topConfig($routername) $index1 $index1 $linkList]
    #Delete lsa  
    stc::delete $m_hLsaArrIndexedByTopName($routername,$linkname)

    #Decrease linknum
    set index [lsearch $m_topConfig($routername) -linknum]
    set linknum [lindex $m_topConfig($routername) [expr $index + 1]]
    incr linknum -1
    incr index
    set m_topConfig($routername) [lreplace $m_topConfig($routername) $index $index $linknum]
    #Delete linkname from list
    set index [lsearch $m_topConfig($routername) -linknamelist]
    if {$index != -1} {
        set linknamelist [lindex $m_topConfig($routername) [expr $index + 1]]

        set index1 [lsearch $linknamelist $linkname]         
        if {$index1 != -1} {
            set linknamelist  [lreplace $linknamelist $index1 $index1 ]
            incr index 
            set m_topConfig($routername) [lreplace $m_topConfig($routername) $index $index $linknamelist]
             
        }

    }
    Ospfv3ApplyToChassis   
    
    catch {unset m_hLsaArrIndexedByLsaName($linklsaname)}
    catch {unset m_linkConfig($routername,$linkname) }
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopRouterLink"       
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
#APIName: Ospfv3CreateTopNetwork
#
#Description: Create Network of specified format 
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopNetwork {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopNetwork"
    
    #Abstract networkname from parameter list    
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv3CreateTopNetwork API"
    }
   
    #Check the uniqueness of networkname
    set index [lsearch $m_topNameList $networkname]
    if {$index != -1} {
       error "The networkname($networkname) is already existed, please specify another one,the existed networkname(s) is(are) as following:\
       \n $m_topNameList"
    }
    lappend m_topNameList $networkname
    lappend m_topConfig($networkname) -networkname
    lappend m_topConfig($networkname) $networkname

    #Abstract connectedrouternamelist from parameter list 
    set index [lsearch $args -connectedrouternamelist]
    if {$index != -1} {
       set connectedrouternamelist [lindex $args [expr $index + 1]]
    } else {
       error "please specify connectedrouternamelist for Ospfv3CreateTopNetwork API"
    }
    lappend m_topConfig($networkname) -connectedrouternamelist
    lappend m_topConfig($networkname) $connectedrouternamelist

    #Abstract ddroutername from parameter list 
    set index [lsearch $args -ddroutername]
    if {$index != -1} {
       set ddroutername [lindex $args [expr $index + 1]] 
       set index [lsearch $m_topNameList $ddroutername]
       if {$index == -1} {
          error "The routername($ddroutername) does not exist, the existed routername(s) is(are) as following:\n $m_topNameList"
       }
       set index [lsearch $m_topConfig($ddroutername) -routerid]
       set ddRouterId [lindex $m_topConfig($ddroutername) [expr $index + 1]]
    } else {
       set ddRouterId $m_routerId
       set ddroutername "not_specified"
    }
    lappend m_topConfig($networkname) -ddroutername
    lappend m_topConfig($networkname) $ddroutername    
    set m_topConfig($networkname,routerId) ""

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    lappend m_topConfig($networkname) -flagadvertise
    lappend m_topConfig($networkname) $flagadvertise
    #Abstract subnetwork from parameter list       
    set index [lsearch $args -subnetwork]
    if {$index != -1} {
       set subnetwork [lindex $args [expr $index + 1]]
    } else {
       error "please specify subnetwork for Ospfv3CreateTopNetwork API"
    }
    lappend m_topConfig($networkname) -subnetwork
    lappend m_topConfig($networkname) $subnetwork

    #Abstract prefix from parameter list 
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
    } else {
       set prefix 64
    }
    lappend m_topConfig($networkname) -prefix
    lappend m_topConfig($networkname) $prefix
   


    set connectedRouterIdList ""
    foreach connectedroutername $connectedrouternamelist {

       set index [lsearch $m_topNameList $connectedroutername]
       if {$index == -1} {
          error "The routername ($connectedroutername)in connectedRouterIdList does not exist, the existed routername(s) is(are) as following:\
          \n $m_topNameList"
       } 
       set index [lsearch $m_topConfig($connectedroutername) -routerid]
       set routerid [lindex $m_topConfig($connectedroutername) [expr $index + 1] ]
       lappend connectedRouterIdList $routerid       
       
       #Create linkLsa of connectedroutername-2-dr 
       set linkName $connectedroutername-2-$networkname
       lappend m_topConfig($networkname,links,other-2-self) $linkName
       set m_hLsaArrIndexedByTopName($linkName) [stc::create Ospfv3RouterLsaIf \
                                                                                                          -under $m_hLsaArrIndexedByTopName($connectedroutername)\
                                                                                                          -IfType "TRANSIT_NETWORK"\
                                                                                                          -Name $linkName\
                                                                                                          -NeighborRouterId $ddRouterId]       
    }
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname $networkname
    }
    lappend m_topConfig($networkname) -lsaname
    lappend m_topConfig($networkname) $lsaname

    if {$lsaname != "not_specified"} {
        set index [lsearch $m_lsaNameList $lsaname]
        if {$index != -1} {
           error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\
           \n $m_lsaNameList"
        }
        lappend m_lsaNameList $lsaname 
    }
    #Create Ospfv3NetworkLsa
    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create Ospfv3NetworkLsa \
                                                                                                -under $m_hOspfv3RouterConfig \
                                                                                                -AdvertisingRouterId $ddRouterId]
    set  m_hLsaArrIndexedByTopName($networkname)  $m_hLsaArrIndexedByLsaName($lsaname)                                                                                                
    

    foreach routerId $connectedRouterIdList {
        #Create Ospfv3AttachedRouter
        stc::create Ospfv3AttachedRouter -under $m_hLsaArrIndexedByLsaName($lsaname) -RouterId $routerId

    }   

    set m_lsaConfig($lsaname)  ""
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  networklsa
    
    array set arr $m_topConfig($networkname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopNetwork"       
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
#APIName: Ospfv3RetrieveTopNetwork
#
#Description: Retrieve attribute of Network
#
#Input: 1.networkname:Name handler of Network
#
#Output: Attribute of Network
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopNetwork {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopNetwork"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify networkname for Ospfv3RetrieveTopNetwork"
    }  
    #Create existence of networkname
    set index [lsearch $m_topNameList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopNetwork"       
    #Return config information of network
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($networkname)]
    array set list2 $m_topConfig($networkname)
    set list ""
    lappend list -networkname
    lappend list $networkname
    lappend list -subnetwork
    lappend list $list1(-LinkStateId)
    lappend list -ddroutername
    lappend list $list2(-ddroutername)
    lappend list -connectedrouternamelist
    lappend list $list2(-connectedrouternamelist)
    set args [ConvertAttrToLowerCase $args]
    
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
#APIName: Ospfv3DeleteTopNetwork
#
#Description: Delete specified Network
#
#Input: 1.networkname:Name handler of Network
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopNetwork {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopNetwork"
    
    #Abstract networkname from parameter list 
    set index [lsearch $args -networkname]
    if {$index != -1} {
       set networkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify networkname for Ospfv3DeleteTopNetwork"
    }  
    #Check existence of networkname
    set index [lsearch $m_topNameList $networkname]
    if {$index == -1} {
       error "The networkname($networkname) does not exist, the existed routername(s) is(are) as following:\
       \n $m_topNameList"
    }     

    set m_topNameList [lreplace $m_topNameList $index $index]
    #Delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($networkname)
    #Delete router included by network
    #Delete link from connnectedRouter of network to dr
    foreach linkName $m_topConfig($networkname,links,other-2-self) {
       if {[info exist m_hLsaArrIndexedByTopName($linkName)]} {
            stc::delete $m_hLsaArrIndexedByTopName($linkName) 
        }
    }
    catch {unset m_topConfig($networkname,links,other-2-self)}            
    Ospfv3ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($networkname)}
    catch {unset m_topConfig($networkname) }
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopNetwork"       
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
#APIName: Ospfv3CreateTopInterAreaPrefixRouteBlock
#
#Description: Create InterAreaPrefixRouteBlock of specified format
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopInterAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]


    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopInterAreaPrefixRouteBlock"

    set m_startingAddressListFlag(InterArea) "FALSE"
    
    #Abstract blockname from parameter list    
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv3CreateTopInterAreaPrefixRouteBlock API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index != -1} {
       error "The blockname($blockname) is already existed, please specify another one,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
    lappend m_topNameList $blockname
    set m_topConfig($blockname,routerId) ""
    #Abstract lsaname from parameter list   
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname $blockname
    }
    lappend m_topConfig($blockname) -lsaname
    lappend m_topConfig($blockname) $lsaname
    #Check the uniqueness of lsaname
    if {$lsaname != "not_specified"} {
        set index [lsearch $m_lsaNameList $lsaname]
        if {$index != -1} {
           error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\
           \n $m_lsaNameList"
        }
        lappend m_lsaNameList $lsaname 
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    lappend m_topConfig($blockname) -flagadvertise
    lappend m_topConfig($blockname) $flagadvertise
    #Abstract startingaddress from parameter list       
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       error "please specify startingaddress for CreateOspfTopSummaryRouteBlock API"
    }
    # Add by Andy
    if {[llength $startingaddress]>1} {
        set  m_startingAddressListFlag(InterArea) "TRUE"
    } else {
        set m_startingAddressListFlag(InterArea) "FALSE"
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
    } else {
       set prefix 64
    }
    lappend m_topConfig($blockname) -prefix
    lappend m_topConfig($blockname) $prefix
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$m_startingAddressListFlag(InterArea)=="TRUE"} {
       set number 1
    } else {
       if {$index != -1} {
           set number [lindex $args [expr $index + 1]]
       } else {
           set number 1
       }
    }
   
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$m_startingAddressListFlag(InterArea)=="TRUE"} {
       set modifier 1
    } else {
       if {$index != -1} {
          set modifier [lindex $args [expr $index + 1]]
       } else {
          set modifier 1
       }
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier
    #Abstract flagtrafficdest from parameter list 

    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
    } else {
       set flagtrafficdest 1
    }
    lappend m_topConfig($blockname) -flagtrafficdest
    lappend m_topConfig($blockname) $flagtrafficdest
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active enable
    }
    lappend m_topConfig($blockname) -active
    lappend m_topConfig($blockname) $active

    if {$active == "enable" || [string tolower $active] == "true"} {
        set active TRUE
    } else {
        set active FALSE
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

    #Abstract metrictype from parameter list 
    set index [lsearch $args -metrictype]
    if {$index != -1} {
       set metrictype [lindex $args [expr $index + 1]]
    } else {
       set metrictype 1
    }
    lappend m_topConfig($blockname) -metrictype
    lappend m_topConfig($blockname) $metrictype

    #Abstract advertisingrouterid from parameter list 
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       error "please specify advertisingrouterid for CreateOspfTopSummaryRouteBlock API"
    }
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
    } else {
       set flagpbit 0
    }
    lappend m_topConfig($blockname) -flagpbit
    lappend m_topConfig($blockname) $flagpbit
    if {$flagpbit == 1} {
     append bitOption PBIT
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
    } else {
       set flagnubit 0
    }
    lappend m_topConfig($blockname) -flagnubit
    lappend m_topConfig($blockname) $flagnubit
    if {$flagnubit == 1} {
     append bitOption |NUBIT
    }
    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
    } else {
       set flaglabit 0
    }
    lappend m_topConfig($blockname) -flaglabit
    lappend m_topConfig($blockname) $flaglabit
    if {$flaglabit == 1} {
     append bitOption |LABIT
    }

    if {$bitOption == ""} {
        set bitOption 0
    }
    #Create Ospfv3InterAreaPrefixLsaBlk
    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create Ospfv3InterAreaPrefixLsaBlk \
                                                                                                      -under $m_hOspfv3RouterConfig \
                                                                                                      -Active $active\
                                                                                                      -AdvertisingRouterId $advertisingrouterid\
                                                                                                      -name $blockname\
                                                                -Metric $metric -PrefixOptions $bitOption]
    #Config Ipv6NetworkBlock                                                                                                      
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv6NetworkBlock]
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock
    stc::config $hIpv6NetworkBlock -AddrIncrement $modifier \
                                                       -NetworkCount $number \
                                                       -PrefixLength $prefix\
                                                       -StartIpList $startingaddress                                                                                                       
    set m_hLsaArrIndexedByTopName($blockname) $m_hLsaArrIndexedByLsaName($lsaname)   
    puts "m_hLsaArrIndexedByTopName($blockname) =$m_hLsaArrIndexedByTopName($blockname) "

    set flag ""
    if {$advertisingrouterid == $m_routerId} {
         set flag needConfigSimulatorRouter
    } else {
        set topRouterName ""
        foreach router $m_topNameList {
            if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                set flag needConfigTopRouter
                set topRouterName $router
                break
            }
        }
        if {$topRouterName == ""} {
            set flag needNewLink
        }
    }

    if {$flag == "needNewLink"} {
    puts "needNewLink"
        #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                -under $m_hSimulatorRouter \
                -IfType "POINT_TO_POINT" \
                -Metric "1" \
                -NeighborRouterId $advertisingrouterid]
    
        set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 

        set index [lsearch $m_topNameList $advertisingrouterid]
        if {$index == -1} {
           puts "create new router lsa"
            set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                    -under $m_hOspfv3RouterConfig \
                    -RouterType BBIT\
                   -AdvertisingRouterId $advertisingrouterid ]
            set m_topConfig($advertisingrouterid,routerType) "BBIT"
            
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $RouterLsa(1) \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $m_routerId]
    
            set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)   
            set m_hLsaArrIndexedByTopName($advertisingrouterid) $RouterLsa(1)  
            lappend m_topNameList $advertisingrouterid
            set m_topConfig($advertisingrouterid,routerId) $advertisingrouterid
        }
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
    puts "needConfigSimulatorRouter"
        #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        append m_topConfig(simulator,routerType) "|BBIT"
        set m_topConfig(simulator,routerType) "BBIT"
        stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType) 
        
    } elseif {$flag == "needConfigTopRouter"}  {
    puts "needConfigTopRouter"
        append m_topConfig($topRouterName,routerType) "|BBIT"
        set m_topConfig($topRouterName,routerType) "BBIT"
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType)
    }        

    set m_lsaConfig($lsaname)  ""
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  interareaprefixlsa

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
       
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopInterAreaPrefixRouteBlock"       
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
#APIName: Ospfv3SetTopInterAreaPrefixRouteBlock
#
#Description: Config attribute of InterAreaPrefixRouteBlock
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3SetTopInterAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]


    debugPut "enter the proc of Ospfv3Session::Ospfv3SetTopInterAreaPrefixRouteBlock"
    

    set extLsaConfig ""
    set routeBlockConfig ""
      #Abstract blockname from parameter list   
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for CreateOspfTopSummaryRouteBlock API"
    }   
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagadvertise]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagadvertise]
       
       lappend routeBlockConfig -flagadvertise
       lappend routeBlockConfig $flagadvertise
    } 
    #Abstract startingaddress from parameter list         
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $startingaddress]
       
       lappend routeBlockConfig -StartIpList
       lappend routeBlockConfig $startingaddress

       # Add by Andy
       if {[llength $startingaddress]>1} {
           set  m_startingAddressListFlag(InterArea) "TRUE"
       } else {
           set m_startingAddressListFlag(InterArea) "FALSE"
       }
    } 
    #Abstract prefix from parameter list     
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefix]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefix]

       lappend routeBlockConfig -PrefixLength
       lappend routeBlockConfig $prefix
    }
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$m_startingAddressListFlag(InterArea)=="TRUE"} {
       set number 1
       set index [lsearch $m_topConfig($blockname) -number]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

       lappend routeBlockConfig -NetworkCount
       lappend routeBlockConfig $number
    } else {
       if {$index != -1} {
          set number [lindex $args [expr $index + 1]]
          set index [lsearch $m_topConfig($blockname) -number]
          incr index
          set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

          lappend routeBlockConfig -NetworkCount
          lappend routeBlockConfig $number
       }
    }
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$m_startingAddressListFlag(InterArea)=="TRUE"} {
       set modifier 1
       set index [lsearch $m_topConfig($blockname) -modifier]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

       lappend routeBlockConfig -AddrIncrement
       lappend routeBlockConfig $modifier
    } else {
       if {$index != -1} {
          set modifier [lindex $args [expr $index + 1]]
          set index [lsearch $m_topConfig($blockname) -modifier]
          incr index
          set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

          lappend routeBlockConfig -AddrIncrement
          lappend routeBlockConfig $modifier
       }
    }
    #Abstract flagtrafficdest from parameter list 
    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagtrafficdest]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagtrafficdest]
    }
    #Abstract active from parameter list 
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
           lappend extLsaConfig -active 
           lappend extLsaConfig FALSE
       }
    }
    #Abstract advertisingrouterid from parameter list 
    set flag ""
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -advertisingrouterid]
       set formeradvertisingrouterid [lindex $m_topConfig($blockname) [expr $index + 1]]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $advertisingrouterid]

       lappend extLsaConfig -AdvertisingRouterId
       lappend extLsaConfig $advertisingrouterid
       
       set flag newTop
      
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
       lappend m_lsaConfig($lsaname)  interareaprefixlsa
      
    }
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagpbit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagpbit]

       if {$flagpbit == 1} {
           append bitOption PBIT
       }
      
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnubit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnubit]

       if {$flagnubit == 1} {
           append bitOption |NUBIT
       }
      
    }

    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flaglabit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flaglabit]

       if {$flaglabit == 1} {
           append bitOption |LABIT
       }
      
    }

    if {$bitOption == ""} {
        set bitOption 0
    }

    
   lappend extLsaConfig -PrefixOptions
   lappend extLsaConfig $bitOption
    #Abstract forwardingaddress from parameter list 
   set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -forwardingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $forwardingaddress]

       lappend extLsaConfig -forwardingaddr
       lappend extLsaConfig $forwardingaddress
      
    }
    #Abstract flagasbr from parameter list      
    set index [lsearch $args -flagasbr]
    if {$index != -1} {
       set flagasbr [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagasbr]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagasbr]

       lappend extLsaConfig -lsType
       lappend extLsaConfig AS_EXT_LSA
      
    }
    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnssa]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnssa]

       lappend extLsaConfig -lsType
       lappend extLsaConfig NSSA_LSA
      
    }
    #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]

        lappend extLsaConfig -Metric
       lappend extLsaConfig $metric
    }
    #Abstract metrictype from parameter list 
    set index [lsearch $args -metrictype]
    if {$index != -1} {
       set metrictype [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metrictype]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metrictype]
    }
    #Config InterAreaPrefixLsa 
    eval stc::config  $m_hLsaArrIndexedByTopName($blockname)  $extLsaConfig
    puts "m_hLsaArrIndexedByTopName($blockname) = $m_hLsaArrIndexedByTopName($blockname) "
    #Config Ipv6NetworkBlock
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]    
    eval stc::config $hIpv6NetworkBlock $routeBlockConfig
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock

    if {$flag == "newTop" } {
        set flag ""
        if {$advertisingrouterid == $m_routerId} {
             set flag needConfigSimulatorRouter
        } else {
            set topRouterName ""
            foreach router $m_topNameList {
                if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                    set flag needConfigTopRouter
                    set topRouterName $router
                    break
                }
            }
            if {$topRouterName == ""} {
                 if {$formeradvertisingrouterid != $advertisingrouterid} {
                     set flag needNewLink
                 }
            }
        }
    
        if {$flag == "needNewLink"} {
        puts "needNewLink"
           
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $m_hSimulatorRouter \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $advertisingrouterid]
        
            set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
            set m_topConfig($advertisingrouterid,routerType) "BBIT"
            set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                    -under $m_hOspfv3RouterConfig \
                    -RouterType BBIT\
                   -AdvertisingRouterId $advertisingrouterid ]
            
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $RouterLsa(1) \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $m_routerId]
    
            set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
      
        } elseif {$flag == "needConfigSimulatorRouter"}  {
        puts "needConfigSimulatorRouter"
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
            append m_topConfig(simulator,routerType) "|BBIT"
            set m_topConfig(simulator,routerType) "BBIT"
            stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType)
        } elseif {$flag == "needConfigTopRouter"}  {
        puts "needConfigTopRouter"
            append m_topConfig($topRouterName,routerType) "|BBIT"
            set m_topConfig($topRouterName,routerType) "BBIT"
            stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType)
        }     
    }

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
                                                              
    debugPut "exit the proc of Ospfv3Session::Ospfv3SetTopInterAreaPrefixRouteBlock"       
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
#APIName: Ospfv3RetrieveTopInterAreaPrefixRouteBlock
#
#Description:Retrieve attribute of InterAreaPrefixRouteBlock
#
#Input: 1.blockname:Name handler of InterAreaPrefixRouteBlock
#
#Output: Attribute of InterAreaPrefixRouteBlock
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopInterAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopInterAreaPrefixRouteBlock"   
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify blockname for Ospfv3RetrieveTopInterAreaPrefixRouteBlock"
    }  
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
               
    #Return config information of InterAreaPrefixlRouteBlock
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($blockname)]
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]
    array set list2 [stc::get $hIpv6NetworkBlock]
    array set list3 $m_topConfig($blockname)
    set list ""
    lappend list -blockname
    lappend list $blockname
    lappend list -startingaddress
    lappend list $list2(-StartIpList)
    lappend list -prefix
    lappend list $list2(-PrefixLength)
    lappend list -number
    lappend list $list2(-NetworkCount)
    lappend list -modifier
    lappend list $list2(-AddrIncrement)
    lappend list -flagnubit
    lappend list $list3(-flagnubit)
    lappend list -flaglabit
    lappend list $list3(-flaglabit)
    set args [ConvertAttrToLowerCase $args]
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
        debugPut "exit the proc of Ospfv3Session::RetrieveOspfTopInterAreaPrefixlRouteBlock"
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
#APIName: Ospfv3DeleteTopInterAreaPrefixRouteBlock
#
#Description: Delete specified InterAreaPrefixRouteBlock
#
#Input: 1.blockname:Name handler of InterAreaPrefixRouteBlock
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopInterAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopInterAreaPrefixRouteBlock"
    #Abstract blockname from parameter list     
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv3DeleteTopInterAreaPrefixRouteBlock"
    }  
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set m_topNameList [lreplace $m_topNameList $index $index]
    #Delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($blockname)
    #foreach link $m_topConfig($blockname,newLink)  {
    #           stc::delete $m_hLsaArrIndexedByTopName($link)
    #}
    catch {unset m_topConfig($blockname,newLink)} 

    Ospfv3ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($blockname)}
    catch {unset m_topConfig($blockname) }
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopInterAreaPrefixRouteBlock"       
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
#APIName: Ospfv3CreateTopExternalPrefixRouteBlock
#
#Description: Create ExternalPrefixRouteBlock of specified format 
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopExternalPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopExternalPrefixRouteBlock"

    set m_startingAddressListFlag(External) "FALSE"
    
     #Abstract blockname from parameter list   
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for CreateOspfTopSummaryRouteBlock API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index != -1} {
       error "The blockname($blockname) is already existed, please specify another one,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
    lappend m_topNameList $blockname
    set m_topConfig($blockname,routerId) ""
    #Abstract lsaname from parameter list 
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname $blockname
    }
    lappend m_topConfig($blockname) -lsaname
    lappend m_topConfig($blockname) $lsaname

    if {$lsaname != "not_specified"} {
        set index [lsearch $m_lsaNameList $lsaname]
        if {$index != -1} {
           error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\
           \n $m_lsaNameList"
        }
        lappend m_lsaNameList $lsaname 
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    lappend m_topConfig($blockname) -flagadvertise
    lappend m_topConfig($blockname) $flagadvertise
      
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       error "please specify startingaddress for CreateOspfTopSummaryRouteBlock API"
    }

    # Add by Andy
    if {[llength $startingaddress]>1} {
        set  m_startingAddressListFlag(External) "TRUE"
    } else {
        set m_startingAddressListFlag(External) "FALSE"
    }
    
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
    } else {
       set prefix 64
    }
    lappend m_topConfig($blockname) -prefix
    lappend m_topConfig($blockname) $prefix
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$m_startingAddressListFlag(External)=="TRUE"} {
        set number 1
    } else {
        if {$index != -1} {
           set number [lindex $args [expr $index + 1]]
        } else {
           set number 1
        }
    }
    lappend m_topConfig($blockname) -number
    lappend m_topConfig($blockname) $number
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$m_startingAddressListFlag(External)=="TRUE"} {
        set modifier 1
    } else {
        if {$index != -1} {
           set modifier [lindex $args [expr $index + 1]]
        } else {
           set modifier 1
        }
    }
    lappend m_topConfig($blockname) -modifier
    lappend m_topConfig($blockname) $modifier
    #Abstract flagtrafficdest from parameter list 
    
    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
    } else {
       set flagtrafficdest 1
    }
    lappend m_topConfig($blockname) -flagtrafficdest
    lappend m_topConfig($blockname) $flagtrafficdest
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active enable
    }
    lappend m_topConfig($blockname) -active
    lappend m_topConfig($blockname) $active

    if {$active == "enable" || [string tolower $active] == "true"} {
        set active TRUE
    } else {
        set active FALSE
    }
    #Abstract advertisingrouterid from parameter list 
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       set advertisingrouterid $m_routerId
    }
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
    } else {
       set flagpbit 0
    }
    lappend m_topConfig($blockname) -flagpbit
    lappend m_topConfig($blockname) $flagpbit
    if {$flagpbit == 1} {
     append bitOption PBIT
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
    } else {
       set flagnubit 0
    }
    lappend m_topConfig($blockname) -flagnubit
    lappend m_topConfig($blockname) $flagnubit
    if {$flagnubit == 1} {
     append bitOption |NUBIT
    }
    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
    } else {
       set flaglabit 0
    }
    lappend m_topConfig($blockname) -flaglabit
    lappend m_topConfig($blockname) $flaglabit
    if {$flaglabit == 1} {
     append bitOption |LABIT
    }

    if {$bitOption == ""} {
        set bitOption 0
    }
    #Abstract forwardingaddress from parameter list 
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
    } else {
       set forwardingaddress $m_routerIp
    }
    lappend m_topConfig($blockname) -forwardingaddress
    lappend m_topConfig($blockname) $forwardingaddress
    #Abstract flagasbr from parameter list 
    set lsType NONE
    set index [lsearch $args -flagasbr]
    if {$index != -1} {
       set flagasbr [lindex $args [expr $index + 1]]
    } else {
       set flagasbr 1
    }
    lappend m_topConfig($blockname) -flagasbr
    lappend m_topConfig($blockname) $flagasbr

    if {$flagasbr == 1} {
        set lsType AS_EXT_LSA
    }

    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
    } else {
       set flagnssa 0
    }
    lappend m_topConfig($blockname) -flagnssa
    lappend m_topConfig($blockname) $flagnssa

    if {$flagnssa == 1} {
        set lsType NSSA_LSA
    }
    #Abstract metrictype from parameter list 
    set index [lsearch $args -metrictype]
    if {$index != -1} {
       set metrictype [lindex $args [expr $index + 1]]
    } else {
       set metrictype false
    }
    if {$metrictype == 1} {
        set metrictype false 
    } else {
        set metrictype true 
    }
    lappend m_topConfig($blockname) -metrictype
    lappend m_topConfig($blockname) $metrictype
    #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric 1
    }
    lappend m_topConfig($blockname) -metric
    lappend m_topConfig($blockname) $metric
    #Abstract externalroutetag from parameter list 
    set index [lsearch $args -externalroutetag]
    if {$index != -1} {
       set externalroutetag [lindex $args [expr $index + 1]]
    } else {
       set externalroutetag 0
    }
    set externalroutetag [ExternalRoutetagConvert $externalroutetag]
    lappend m_topConfig($blockname) -externalroutetag
    lappend m_topConfig($blockname) $externalroutetag
    
    #Create Ospfv3AsExternalLsaBlock
       
 set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create "Ospfv3AsExternalLsaBlock" \
        -under $m_hOspfv3RouterConfig \
        -RefLsType "0" \
        -MetricType "FALSE" \
        -Metric "$metric" \
        -LsType "AS_EXT_LSA" \
        -ForwardingAddr "null" \
        -ExternalRouteTag "null" \
        -AdminTag "0" \
        -RefLinkStateId "0" \
        -PrefixOptions "0" \
        -Age "0" \
        -LinkStateId "1" \
        -AdvertisingRouterId $advertisingrouterid \
        -SeqNum "2147483649" \
        -CheckSum "GOOD" \
        -RouteCategory "UNIQUE" \
        -Active "TRUE" \
        -LocalActive "TRUE" \
        -Name "Ospfv3AsExternalLsaBlock 7" ]        
   #Config Ipv6NetworkBlock                                                                                                      
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv6NetworkBlock]   
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock
    stc::config $hIpv6NetworkBlock -AddrIncrement $modifier \
                                                       -NetworkCount $number \
                                                       -PrefixLength $prefix\
                                                       -StartIpList $startingaddress
    set m_hLsaArrIndexedByTopName($blockname) $m_hLsaArrIndexedByLsaName($lsaname)   
    set flag ""
    if {$advertisingrouterid == $m_routerId} {
         set flag needConfigSimulatorRouter
    } else {
        set topRouterName ""
        foreach router $m_topNameList {
            if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                set flag needConfigTopRouter
                set topRouterName $router
                break
            }
        }
        if {$topRouterName == ""} {
             set flag needNewLink            
        }
    }

    if {$flag == "needNewLink"} {
    puts "needNewLink"
       #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                -under $m_hSimulatorRouter \
                -IfType "POINT_TO_POINT" \
                -Metric "1" \
                -NeighborRouterId $advertisingrouterid]
    
        set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
        
        set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                -under $m_hOspfv3RouterConfig \
                -RouterType EBIT\
                 -Options "V6BIT|EBIT|RBIT" \
               -AdvertisingRouterId $advertisingrouterid ]
        set m_topConfig($advertisingrouterid,routerType) "EBIT"              
        
        set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                -under $RouterLsa(1) \
                -IfType "POINT_TO_POINT" \
                -Metric "1" \
                -NeighborRouterId $m_routerId]

        set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
    puts "needConfigSimulatorRouter"
        #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        append m_topConfig(simulator,routerType) "|EBIT"
        set m_topConfig(simulator,routerType) "EBIT"
        stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType)  -Options "V6BIT|EBIT|RBIT"
    } elseif {$flag == "needConfigTopRouter"}  {
    puts "needConfigTopRouter"
        append m_topConfig($topRouterName,routerType) "|EBIT"
        set m_topConfig($topRouterName,routerType) "EBIT"
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType)  -Options "V6BIT|EBIT|RBIT"
    }    
        

    set m_lsaConfig($lsaname)  ""
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  extlsa

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
       
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopExternalPrefixRouteBlock"       
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
###########################################################################
#APIName: Ospfv3SetTopExternalPrefixRouteBlock
#
#Description: Config attribute of ExternalPrefixRouteBlock
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3SetTopExternalPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3SetTopExternalPrefixRouteBlock"
    

    set ExternalLsaConfig ""
    set routeBlockConfig ""
    #Abstract blockname from parameter list    
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for CreateOspfTopSummaryRouteBlock API"
    }   
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagadvertise]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagadvertise]
       
       lappend routeBlockConfig -flagadvertise
       lappend routeBlockConfig $flagadvertise
    } 
    #Abstract startingaddress from parameter list         
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -startingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $startingaddress]
       
       lappend routeBlockConfig -StartIpList
       lappend routeBlockConfig $startingaddress

       #Add by Andy
       if {[llength $startingaddress]>1} {
           set  m_startingAddressListFlag(External) "TRUE"
       } else {
           set m_startingAddressListFlag(External) "FALSE"
       }
    } 
    #Abstract prefix from parameter list     
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefix]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefix]

       lappend routeBlockConfig -PrefixLength
       lappend routeBlockConfig $prefix
    }
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$m_startingAddressListFlag(External)=="TRUE"} {
       set number 1
       set index [lsearch $m_topConfig($blockname) -number]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

       lappend routeBlockConfig -NetworkCount
       lappend routeBlockConfig $number 
    } else {
       if {$index != -1} {
          set number [lindex $args [expr $index + 1]]
          set index [lsearch $m_topConfig($blockname) -number]
          incr index
          set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $number]

          lappend routeBlockConfig -NetworkCount
          lappend routeBlockConfig $number   
       }
    }
    
    #Abstract modifier from parameter list 
    set index [lsearch $args -modifier]
    if {$m_startingAddressListFlag(External)=="TRUE"} {
       set modifier 1
       set index [lsearch $m_topConfig($blockname) -modifier]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

       lappend routeBlockConfig -AddrIncrement
       lappend routeBlockConfig $modifier
    } else {
       if {$index != -1} {
          set modifier [lindex $args [expr $index + 1]]
          set index [lsearch $m_topConfig($blockname) -modifier]
          incr index
          set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $modifier]

          lappend routeBlockConfig -AddrIncrement
          lappend routeBlockConfig $modifier
       }
    }
    #Abstract flagtrafficdest from parameter list 
    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagtrafficdest]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagtrafficdest]
    }
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -active]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $active]
       if {$active == "enable" || [string tolower $active] == "true"} {
           lappend ExternalLsaConfig -active 
           lappend ExternalLsaConfig TRUE
       } else {
           lappend ExternalLsaConfig -active 
           lappend ExternalLsaConfig  FALSE
       }
    }
    #Abstract Metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]

       lappend ExternalLsaConfig -Metric
       lappend ExternalLsaConfig $metric
    }
    #Abstract advertisingrouterid from parameter list 
    set flag ""
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -advertisingrouterid]
       set formeradvertisingrouterid [lindex  $m_topConfig($blockname) [expr $index + 1]]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $advertisingrouterid]

       lappend ExternalLsaConfig  -AdvertisingRouterId
       lappend ExternalLsaConfig  $advertisingrouterid
       set flag needConfigTop
      
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
       lappend m_lsaConfig($lsaname)  extlsa
      
    }
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagpbit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagpbit]

       if {$flagpbit == 1} {
           append bitOption PBIT
       }
      
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnubit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnubit]

       if {$flagnubit == 1} {
           append bitOption |NUBIT
       }
      
    }

    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flaglabit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flaglabit]

       if {$flaglabit == 1} {
           append bitOption |LABIT
       }
      
    }

    if {$bitOption == ""} {
        set bitOption 0
    }

    
   lappend ExternalLsaConfig  -PrefixOptions
   lappend ExternalLsaConfig  $bitOption    
    #Abstract externalroutetag from parameter list 
    set index [lsearch $args -externalroutetag]
    if {$index != -1} {
       set externalroutetag [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -externalroutetag]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $externalroutetag]

       lappend ExternalLsaConfig  -AdminTag
       lappend ExternalLsaConfig  $externalroutetag
      
    }    

    #Config ExternalPrefixRouteBlock
    eval stc::config  $m_hLsaArrIndexedByTopName($blockname)  $ExternalLsaConfig -AdminTag 5
    #Config Ipv6NetworkBlock
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]    
    eval stc::config $hIpv6NetworkBlock $routeBlockConfig
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock

    if {$flag == "needConfigTop"} {
        set flag ""
        if {$advertisingrouterid == $m_routerId} {
             set flag needConfigSimulatorRouter
        } else {
            set topRouterName ""
            foreach router $m_topNameList {
                if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                    set flag needConfigTopRouter
                    set topRouterName $router
                    break
                }
            }
            if {$topRouterName == ""} {
                if {$formeradvertisingrouterid != $advertisingrouterid} {
                    set flag needNewLink
                }
            }
        }
    
        if {$flag == "needNewLink"} {
        puts "needNewLink"
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $m_hSimulatorRouter \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $advertisingrouterid]
        
            set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
            
            set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                    -under $m_hOspfv3RouterConfig \
                    -RouterType EBIT\
                    -Options "V6BIT|EBIT|RBIT" \
                   -AdvertisingRouterId $advertisingrouterid ]
            append m_topConfig($advertisingrouterid,routerType) "|EBIT"      
            set m_topConfig($advertisingrouterid,routerType) "EBIT"
            
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $RouterLsa(1) \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $m_routerId]
    
            set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
      
        } elseif {$flag == "needConfigSimulatorRouter"}  {
        puts "needConfigSimulatorRouter"
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
            append m_topConfig(simulator,routerType) "|EBIT"
            set m_topConfig(simulator,routerType) "EBIT"
            stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType)  -Options "V6BIT|EBIT|RBIT"
        } elseif {$flag == "needConfigTopRouter"}  {
        puts "needConfigTopRouter"
            append m_topConfig($topRouterName,routerType) "|EBIT"
            set m_topConfig($topRouterName,routerType) "EBIT"
            stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType) -Options "V6BIT|EBIT|RBIT"
        }        
    }

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
                                                              
    debugPut "exit the proc of Ospfv3Session::Ospfv3SetTopExternalPrefixRouteBlock"       
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
#APIName: Ospfv3RetrieveTopExternalPrefixRouteBlock
#
#Description:Retrieve the attribute of specified ExternalPrefixRouteBlock
#
#Input: 1.blockname:Name handler of ExternalPrefixRouteBlock
#
#Output: Attribute of ExternalPrefixRouteBlock
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopExternalPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopExternalPrefixRouteBlock"
    
     #Abstract blockname from parameter list   
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify blockname for RetrieveOspfTopSummaryRouteBlock"
    }  
    #Create existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
           
    #Return config information of ExternalPrefixRouteBlock
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($blockname)]
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]
    array set list2 [stc::get $hIpv6NetworkBlock]
    array set list3 $m_topConfig($blockname)
    set list ""
    lappend list -blockname
    lappend list $blockname
    lappend list -startingaddress
    lappend list $list2(-StartIpList)
    lappend list -prefix
    lappend list $list2(-PrefixLength)
    lappend list -number
    lappend list $list2(-NetworkCount)
    lappend list -modifier
    lappend list $list2(-AddrIncrement)
    lappend list -forwardingaddress
    lappend list $list3(-forwardingaddress)
    lappend list -flagasbr
    lappend list $list3(-flagasbr)
    lappend list -advertisingrouterid
    lappend list $list1(-AdvertisingRouterId)
    lappend list -metrictype
    lappend list $list1(-MetricType)
    lappend list -metric
    lappend list $list1(-Metric)
    lappend list -externalroutetag
    lappend list $list1(-AdminTag)
    lappend list -flagnubit
    lappend list $list3(-flagnubit)
    lappend list -flaglabit
    lappend list $list3(-flaglabit)
    lappend list -flagnssa
    lappend list $list3(-flagnssa)
    set args [ConvertAttrToLowerCase $args]
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
        debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopExternalPrefixRouteBlock"
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
#APIName: Ospfv3DeleteTopExternalPrefixRouteBlock
#
#Description: Delete specified ExternalPrefixRouteBlock 
#
#Input: 1.blockname:Name handler of ExternalPrefixRouteBlock
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopExternalPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopExternalPrefixRouteBlock"
    #Abstract blockname from parameter list     
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for DeleteOspfTopSummaryRouteBlock"
    }  
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set m_topNameList [lreplace $m_topNameList $index $index]
    #Delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($blockname)
    #Delete corresponding link of new top
    catch {
    foreach link $m_topConfig($blockname,newLink)  {
       
        stc::delete $m_hLsaArrIndexedByTopName($link)
    }
    }
    catch {unset m_topConfig($blockname,newLink)}     

    Ospfv3ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($blockname)}
    catch {unset m_topConfig($blockname) }
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopExternalPrefixRouteBlock"       
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
#APIName: Ospfv3AdvertiseOspfLsa
#
#Description: Advertise Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv3Session::Ospfv3AdvertiseOspfLsa {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of Ospfv3Session::Ospfv3AdvertiseOspfLsa"
    #Advertise all lsa of ospfv3 router
    stc::perform Ospfv3ReadvertiseLsa  -RouterList $m_hOspfv3RouterConfig      
    debugPut "exit the proc of Ospfv3Session::Ospfv3AdvertiseOspfLsa" 
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
#APIName: Ospfv3ReAdvertiseOspfLsa
#
#Description: ReAdvertise Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv3Session::Ospfv3ReAdvertiseOspfLsa {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of Ospfv3Session::Ospfv3ReAdvertiseOspfLsa"
    #Readvertise all lsa of ospfv3 router
    stc::perform Ospfv3ReadvertiseLsa  -RouterList $m_hOspfv3RouterConfig      
    debugPut "exit the proc of Ospfv3Session::Ospfv3ReAdvertiseOspfLsa" 
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
#APIName: Ospfv3AgeOspfLsa
#
#Description:Withdraw Ospf Lsa
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv3Session::Ospfv3AgeOspfLsa {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of Ospfv3Session::Ospfv3AgeOspfLsa"
    #Abstract lsanamelist from parameter list 
    set index [lsearch $args -lsanamelist] 
    if {$index != -1} {
        set lsanamelist [lindex $args [expr $index + 1]]
    } else {
        error "please specify lsaNameList for Ospfv3AgeOspfLsa"
    }

    foreach lsaname $lsanamelist {
        #Call corresponding stc api according to lsatype, age related lsa
        array set lsaConfigArr $m_lsaConfig($lsaname)
        switch $lsaConfigArr(-lsatype) {
            routerlsa {
                stc::perform Ospfv3AgeRouterLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            networklsa {
                stc::perform Ospfv3AgeNetworkLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            interareaprefixlsa {
                stc::perform Ospfv3AgeInterAreaPrefixLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            intraareaprefixlsa {
                stc::perform Ospfv3AgeIntraAreaPrefixLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            extlsa {
                stc::perform Ospfv3AgeExternalLsa -LsaList $m_hLsaArrIndexedByLsaName($lsaname) 
            }
            default {
                error "unsupported lsatype($lsaConfigArr(-lsatype))"
            }

        }

    }    
    debugPut "exit the proc of Ospfv3Session::Ospfv3AgeOspfLsa" 
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
#APIName: Ospfv3Enable
#
#Description:Enable ospfv3 Routing Simulation
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv3Session::Ospfv3Enable {{args ""}} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of Ospfv3Session::Ospfv3Enable"
    stc::config $m_hOspfv3RouterConfig -active TRUE
    debugPut "exit the proc of Ospfv3Session::Ospfv3Enable" 
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
#APIName: Ospfv3Disable
#
#Description:Disable ospfv3 Routing Simulation
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body Ospfv3Session::Ospfv3Disable {{args ""}} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of Ospfv3Session::Ospfv3Disable"
    stc::config $m_hOspfv3RouterConfig -active FALSE
    debugPut "exit the proc of Ospfv3Session::Ospfv3Disable" 
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
#APIName: Ospfv3CreateTopIntraAreaPrefixRouteBlock
#
#Description: Create InterAreaPrefixRouteBlock of specified format 
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3CreateTopIntraAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of Ospfv3Session::Ospfv3CreateTopIntraAreaPrefixRouteBlock"
    
    #Abstract blockname from parameter list    
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv3CreateTopIntraAreaPrefixRouteBlock API"
    }
   
    #Check the uniqueness of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index != -1} {
       error "The blockname($blockname) is already existed, please specify another one,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
    lappend m_topNameList $blockname
    set m_topConfig($blockname,routerId) ""
    #Abstract lsaname from parameter list   
    set index [lsearch $args -lsaname]
    if {$index != -1} {
       set lsaname [lindex $args [expr $index + 1]]
    } else {
       set lsaname $blockname
    }
    lappend m_topConfig($blockname) -lsaname
    lappend m_topConfig($blockname) $lsaname
    #Check the uniqueness of lsaname
    if {$lsaname != "not_specified"} {
        set index [lsearch $m_lsaNameList $lsaname]
        if {$index != -1} {
           error "The lsaname($lsaname) is already existed, please specify another one,the existed lsaname(s) is(are) as following:\
           \n $m_lsaNameList"
        }
        lappend m_lsaNameList $lsaname 
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
    } else {
       set flagadvertise 1
    }
    lappend m_topConfig($blockname) -flagadvertise
    lappend m_topConfig($blockname) $flagadvertise
    #Abstract startingaddress from parameter list       
    set index [lsearch $args -startingaddress]
    if {$index != -1} {
       set startingaddress [lindex $args [expr $index + 1]]
    } else {
       error "please specify startingaddress for Ospfv3CreateTopIntraAreaPrefixRouteBlock API"
    }
    lappend m_topConfig($blockname) -startingaddress
    lappend m_topConfig($blockname) $startingaddress
    #Abstract prefix from parameter list 
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
    } else {
       set prefix 64
    }
    lappend m_topConfig($blockname) -prefix
    lappend m_topConfig($blockname) $prefix
    #Abstract number from parameter list 
    set index [lsearch $args -number]
    if {$index != -1} {
       set number [lindex $args [expr $index + 1]]
    } else {
       set number 1
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
    #Abstract flagtrafficdest from parameter list 

    set index [lsearch $args -flagtrafficdest]
    if {$index != -1} {
       set flagtrafficdest [lindex $args [expr $index + 1]]
    } else {
       set flagtrafficdest 1
    }
    lappend m_topConfig($blockname) -flagtrafficdest
    lappend m_topConfig($blockname) $flagtrafficdest
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active enable
    }
    lappend m_topConfig($blockname) -active
    lappend m_topConfig($blockname) $active

    if {$active == "enable"} {
        set active TRUE
    } else {
        set active FALSE
    }
    #Abstract advertisingrouterid from parameter list 
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       error "please specify advertisingrouterid for Ospfv3CreateTopIntraAreaPrefixRouteBlock API"
    }
    lappend m_topConfig($blockname) -advertisingrouterid
    lappend m_topConfig($blockname) $advertisingrouterid
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
    } else {
       set flagpbit 0
    }
    lappend m_topConfig($blockname) -flagpbit
    lappend m_topConfig($blockname) $flagpbit
    if {$flagpbit == 1} {
     append bitOption PBIT
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
    } else {
       set flagnubit 0
    }
    lappend m_topConfig($blockname) -flagnubit
    lappend m_topConfig($blockname) $flagnubit
    if {$flagnubit == 1} {
     append bitOption |NUBIT
    }
    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
    } else {
       set flaglabit 0
    }
    lappend m_topConfig($blockname) -flaglabit
    lappend m_topConfig($blockname) $flaglabit
    if {$flaglabit == 1} {
     append bitOption |LABIT
    }

    if {$bitOption == ""} {
        set bitOption 0
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

    #Abstract metrictype from parameter list 
    set index [lsearch $args -metrictype]
    if {$index != -1} {
       set metrictype [lindex $args [expr $index + 1]]
    } else {
       set metrictype 1
    }
    lappend m_topConfig($blockname) -metrictype
    lappend m_topConfig($blockname) $metrictype

    #Abstract refadvertisingrouterid from parameter list 
    set index [lsearch $args -refadvertisingrouterid]
    if {$index != -1} {
       set refadvertisingrouterid [lindex $args [expr $index + 1]]
    } else {
       set refadvertisingrouterid "0.0.0.0"
    }
    lappend m_topConfig($blockname) -refadvertisingrouterid
    lappend m_topConfig($blockname) $refadvertisingrouterid

    #Abstract reflstype from parameter list 
    set index [lsearch $args -reflstype]
    if {$index != -1} {
       set reflstype [lindex $args [expr $index + 1]]
    } else {
       set reflstype 0
    }
    lappend m_topConfig($blockname) -reflstype
    lappend m_topConfig($blockname) $reflstype

    #Create Ospfv3InterAreaPrefixLsaBlk
    set  m_hLsaArrIndexedByLsaName($lsaname) [stc::create Ospfv3IntraAreaPrefixLsaBlk \
                                                          -under $m_hOspfv3RouterConfig \
                                                          -Active $active\
                                                          -AdvertisingRouterId $advertisingrouterid \
                                                          -RefAdvertisingRouterId $refadvertisingrouterid \
                                                          -RefLsType $reflstype \
                                                          -name $blockname\
                                                          -PrefixMetric $metric -PrefixOptions $bitOption]
    #Config Ipv6NetworkBlock                                                                                                      
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByLsaName($lsaname) -children-Ipv6NetworkBlock] 
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock
    stc::config $hIpv6NetworkBlock -AddrIncrement $modifier \
                                                       -NetworkCount $number \
                                                       -PrefixLength $prefix\
                                                       -StartIpList $startingaddress                                                                                                       
    set m_hLsaArrIndexedByTopName($blockname) $m_hLsaArrIndexedByLsaName($lsaname)   
    puts "m_hLsaArrIndexedByTopName($blockname) =$m_hLsaArrIndexedByTopName($blockname) "

    set flag ""
    if {$advertisingrouterid == $m_routerId} {
         set flag needConfigSimulatorRouter
    } else {
        set topRouterName ""
        foreach router $m_topNameList {
            if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                set flag needConfigTopRouter
                set topRouterName $router
                break
            }
        }
        if {$topRouterName == ""} {
            set flag needNewLink
        }
    }

    if {$flag == "needNewLink"} {
        #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                -under $m_hSimulatorRouter \
                -IfType "POINT_TO_POINT" \
                -Metric "1" \
                -NeighborRouterId $advertisingrouterid]
    
        set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
        lappend m_topConfig($blockname,newLink) $linkName
        set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 

        set index [lsearch $m_topNameList $advertisingrouterid]
        if {$index == -1} {
            set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                    -under $m_hOspfv3RouterConfig \
                    -RouterType BBIT\
                   -AdvertisingRouterId $advertisingrouterid ]
            set m_topConfig($advertisingrouterid,routerType) "BBIT"
            
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $RouterLsa(1) \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $m_routerId]
    
            set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)   
            set m_hLsaArrIndexedByTopName($advertisingrouterid) $RouterLsa(1)  
            lappend m_topNameList $advertisingrouterid
            set m_topConfig($advertisingrouterid,routerId) $advertisingrouterid
        }
  
    } elseif {$flag == "needConfigSimulatorRouter"}  {
        #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
        append m_topConfig(simulator,routerType) "|BBIT"
        set m_topConfig(simulator,routerType) "BBIT"
        stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType) 
        
    } elseif {$flag == "needConfigTopRouter"}  {
        append m_topConfig($topRouterName,routerType) "|BBIT"
        set m_topConfig($topRouterName,routerType) "BBIT"
        stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType)
    }        

    set m_lsaConfig($lsaname)  ""
    lappend m_lsaConfig($lsaname) -lsatype 
    lappend m_lsaConfig($lsaname)  intraareaprefixlsa

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
       
    debugPut "exit the proc of Ospfv3Session::Ospfv3CreateTopIntraAreaPrefixRouteBlock"       
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
#APIName: Ospfv3SetTopIntraAreaPrefixRouteBlock
#
#Description: Config attribute of IntraAreaPrefixRouteBlock
#
#Input: Details as API document 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3SetTopIntraAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3SetTopIntraAreaPrefixRouteBlock"
    

    set extLsaConfig ""
    set routeBlockConfig ""
      #Abstract blockname from parameter list   
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv3SetTopIntraAreaPrefixRouteBlock API"
    }   
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) doset not exist,the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set args [ConvertAttrToLowerCase1 $args]
    
    #Abstract flagadvertise from parameter list 
    set index [lsearch $args -flagadvertise]
    if {$index != -1} {
       set flagadvertise [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagadvertise]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagadvertise]
       
       lappend routeBlockConfig -flagadvertise
       lappend routeBlockConfig $flagadvertise
    } 
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
    set index [lsearch $args -prefix]
    if {$index != -1} {
       set prefix [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -prefix]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $prefix]

       lappend routeBlockConfig -PrefixLength
       lappend routeBlockConfig $prefix
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
    #Abstract active from parameter list 
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -active]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $active]
       if {$active == "enable"} {
           lappend extLsaConfig -active 
           lappend extLsaConfig TRUE
       } else {
           lappend extLsaConfig -active 
           lappend extLsaConfig FALSE
       }
    }
    #Abstract advertisingrouterid from parameter list 
    set flag ""
    set index [lsearch $args -advertisingrouterid]
    if {$index != -1} {
       set advertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -advertisingrouterid]
       set formeradvertisingrouterid [lindex $m_topConfig($blockname) [expr $index + 1]]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $advertisingrouterid]

       lappend extLsaConfig -AdvertisingRouterId
       lappend extLsaConfig $advertisingrouterid
       
       set flag newTop
      
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
       lappend m_lsaConfig($lsaname)  intraareaprefixlsa
      
    }
    #Abstract flagpbit from parameter list 
    set bitOption ""
    set index [lsearch $args -flagpbit]
    if {$index != -1} {
       set flagpbit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagpbit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagpbit]

       if {$flagpbit == 1} {
           append bitOption PBIT
       }
      
    }
    #Abstract flagnubit from parameter list 
    set index [lsearch $args -flagnubit]
    if {$index != -1} {
       set flagnubit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnubit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnubit]

       if {$flagnubit == 1} {
           append bitOption |NUBIT
       }
    }

    #Abstract flaglabit from parameter list 
    set index [lsearch $args -flaglabit]
    if {$index != -1} {
       set flaglabit [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flaglabit]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flaglabit]

       if {$flaglabit == 1} {
           append bitOption |LABIT
       }
      
    }

    if {$bitOption == ""} {
        set bitOption 0
    }
    
    lappend extLsaConfig -PrefixOptions
    lappend extLsaConfig $bitOption
    #Abstract forwardingaddress from parameter list 
    set index [lsearch $args -forwardingaddress]
    if {$index != -1} {
       set forwardingaddress [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -forwardingaddress]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $forwardingaddress]

       lappend extLsaConfig -forwardingaddr
       lappend extLsaConfig $forwardingaddress      
    }

    #Abstract flagasbr from parameter list      
    set index [lsearch $args -flagasbr]
    if {$index != -1} {
       set flagasbr [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagasbr]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagasbr]

       lappend extLsaConfig -lsType
       lappend extLsaConfig AS_EXT_LSA      
    }

    #Abstract flagnssa from parameter list 
    set index [lsearch $args -flagnssa]
    if {$index != -1} {
       set flagnssa [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -flagnssa]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $flagnssa]

       lappend extLsaConfig -lsType
       lappend extLsaConfig NSSA_LSA
      
    }

    #Abstract metric from parameter list 
    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metric]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metric]

       lappend extLsaConfig -PrefixMetric
       lappend extLsaConfig $metric
    }

    #Abstract metrictype from parameter list 
    set index [lsearch $args -metrictype]
    if {$index != -1} {
       set metrictype [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -metrictype]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $metrictype]
    }

    #Abstract advertisingrouterid from parameter list 
    set index [lsearch $args -refadvertisingrouterid]
    if {$index != -1} {
       set refadvertisingrouterid [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -refadvertisingrouterid]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $refadvertisingrouterid]

       lappend extLsaConfig -refadvertisingrouterid
       lappend extLsaConfig $refadvertisingrouterid      

    }

    #Abstract reflstype from parameter list 
    set index [lsearch $args -reflstype]
    if {$index != -1} {
       set reflstype [lindex $args [expr $index + 1]]
       set index [lsearch $m_topConfig($blockname) -reflstype]
       incr index
       set m_topConfig($blockname) [lreplace $m_topConfig($blockname) $index $index $reflstype]

       lappend extLsaConfig -reflstype
       lappend extLsaConfig $reflstype
    } 

    #Config InterAreaPrefixLsa 
    eval stc::config  $m_hLsaArrIndexedByTopName($blockname)  $extLsaConfig
    #Config Ipv6NetworkBlock
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]    
    eval stc::config $hIpv6NetworkBlock $routeBlockConfig
    #绑定到流
    set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock

    if {$flag == "newTop" } {
        set flag ""
        if {$advertisingrouterid == $m_routerId} {
             set flag needConfigSimulatorRouter
        } else {
            set topRouterName ""
            foreach router $m_topNameList {
                if {$m_topConfig($router,routerId)  == $advertisingrouterid} {
                    set flag needConfigTopRouter
                    set topRouterName $router
                    break
                }
            }
            if {$topRouterName == ""} {
                 if {$formeradvertisingrouterid != $advertisingrouterid} {
                     set flag needNewLink
                 }
            }
        }
    
        if {$flag == "needNewLink"} {
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $m_hSimulatorRouter \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $advertisingrouterid]
        
            set linkName simulatorRouter-2-externalLsa-$advertisingrouterid 
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsaLink(1) 
            set m_topConfig($advertisingrouterid,routerType) "BBIT"
            set RouterLsa(1) [stc::create "Ospfv3RouterLsa" \
                    -under $m_hOspfv3RouterConfig \
                    -RouterType BBIT\
                   -AdvertisingRouterId $advertisingrouterid ]
            
            set RouterLsaLink(1) [stc::create "Ospfv3RouterLsaIf" \
                    -under $RouterLsa(1) \
                    -IfType "POINT_TO_POINT" \
                    -Metric "1" \
                    -NeighborRouterId $m_routerId]
    
            set linkName externalLsa-2-simulatorRouter-$advertisingrouterid  
            lappend m_topConfig($blockname,newLink) $linkName
            set m_hLsaArrIndexedByTopName($linkName) $RouterLsa(1)                  
      
        } elseif {$flag == "needConfigSimulatorRouter"}  {
            #set m_hSimulatorRouter [stc::create Ospfv3RouterLsa -under $m_hOspfv3RouterConfig -AdvertisingRouterId $m_routerId]   
            append m_topConfig(simulator,routerType) "|BBIT"
            set m_topConfig(simulator,routerType) "BBIT"
            stc::config $m_hSimulatorRouter -RouterType $m_topConfig(simulator,routerType)
        } elseif {$flag == "needConfigTopRouter"}  {
            append m_topConfig($topRouterName,routerType) "|BBIT"
            set m_topConfig($topRouterName,routerType) "BBIT"
            stc::config $m_hLsaArrIndexedByTopName($topRouterName) -RouterType $m_topConfig($topRouterName,routerType)
        }     
    }

    array set arr $m_topConfig($blockname)
    set flagadvertise $arr(-flagadvertise)
    if {$flagadvertise == 1} {
        Ospfv3ApplyToChassis
    }
                                                              
    debugPut "exit the proc of Ospfv3Session::Ospfv3SetTopIntraAreaPrefixRouteBlock"       
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
#APIName: RetrieveTopIntraAreaPrefixlRouteBlock
#
#Description:Retrieve attribute of specified IntraAreaPrefixRouteBlock
#
#Input: 1.blockname:Name handler of IntraAreaPrefixRouteBlock
#
#Output: Attribute of IntraAreaPrefixRouteBlock
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3RetrieveTopIntraAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3RetrieveTopIntraAreaPrefixRouteBlock"   
    
    #Abstract blockname from parameter list 
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]  ]
    } else {
       error "please specify blockname for Ospfv3RetrieveTopIntraAreaPrefixRouteBlock"
    }  
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }
               
    #Return config information of InterAreaPrefixlRouteBlock
    array set list1 [stc::get $m_hLsaArrIndexedByTopName($blockname)]
    set hIpv6NetworkBlock [stc::get $m_hLsaArrIndexedByTopName($blockname) -children-Ipv6NetworkBlock]
    array set list2 [stc::get $hIpv6NetworkBlock]
    array set list3 $m_topConfig($blockname)
    set list ""
    lappend list -blockname
    lappend list $blockname
    lappend list -startingaddress
    lappend list $list2(-StartIpList)
    lappend list -prefix
    lappend list $list2(-PrefixLength)
    lappend list -number
    lappend list $list2(-NetworkCount)
    lappend list -modifier
    lappend list $list2(-AddrIncrement)
    lappend list -flagnubit
    lappend list $list3(-flagnubit)
    lappend list -flaglabit
    lappend list $list3(-flaglabit)
    set args [ConvertAttrToLowerCase $args]
    if {$args == ""} {
        #if there is no attr specified, return all the lists of -attr value
        return $list
    } else {
        #if there is attr specified, config the corresponding value
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
        debugPut "exit the proc of Ospfv3Session::Ospfv3RetrieveTopIntraAreaPrefixRouteBlock"
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
#APIName: Ospfv3DeleteTopIntraAreaPrefixRouteBlock
#
#Description: Delete specified IntraAreaPrefixRouteBlock
#
#Input: 1.blockname:Name handler of IntraAreaPrefixRouteBlock
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body Ospfv3Session::Ospfv3DeleteTopIntraAreaPrefixRouteBlock {args} {
set list ""
if {[catch { 
    #Convert attr of parameter list to lower-case
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of Ospfv3Session::Ospfv3DeleteTopIntraAreaPrefixRouteBlock"
    #Abstract blockname from parameter list     
    set index [lsearch $args -blockname]
    if {$index != -1} {
       set blockname [lindex $args [expr $index + 1]]
    } else {
       error "please specify blockname for Ospfv3DeleteTopIntraAreaPrefixRouteBlock"
    }  
    #Check existence of blockname
    set index [lsearch $m_topNameList $blockname]
    if {$index == -1} {
       error "The blockname($blockname) does not exist, the existed blockname(s) is(are) as following:\
       \n $m_topNameList"
    }

    set m_topNameList [lreplace $m_topNameList $index $index]
    #Delete lsa
    stc::delete $m_hLsaArrIndexedByTopName($blockname)
    #foreach link $m_topConfig($blockname,newLink)  {
    #           stc::delete $m_hLsaArrIndexedByTopName($link)
    #}
    catch {unset m_topConfig($blockname,newLink)} 

    Ospfv3ApplyToChassis
    
    catch {unset m_hLsaArrIndexedByTopName($blockname)}
    catch {unset m_topConfig($blockname) }
    debugPut "exit the proc of Ospfv3Session::Ospfv3DeleteTopIntraAreaPrefixRouteBlock"       
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
#APIName: Ospfv3SetBfd
#Description: Set bfdconfig on ospfv3router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv3Session::Ospfv3SetBfd {args} {

    debugPut "enter the proc of Ospfv3Session::Ospfv3SetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    if {$m_bfdSession == ""} {
        stc::config $m_hOspfv3RouterConfig -EnableBfd true
        lappend args -router $m_hRouter -routerconfig $m_hOspfv3RouterConfig
        set m_bfdSession [CreateBfdConfigHLAPI $args]
    } else {
        lappend args -bfdsession $m_bfdSession
        SetBfdConfigHLAPI $args
    }
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3SetBfd"
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: Ospfv3UnsetBfd
#Description: Unset bfdconfig on ospfv3router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv3Session::Ospfv3UnsetBfd {args} {

    debugPut "enter the proc of Ospfv3Session::Ospfv3UnsetBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -bfdsession $m_bfdSession -routerconfig $m_hOspfv3RouterConfig
    UnsetBfdConfigHLAPI $args
    set m_bfdSession ""
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3UnsetBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Ospfv3StartBfd
#Description: start bfdconfig on ospfv3router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv3Session::Ospfv3StartBfd {args} {

    debugPut "enter the proc of Ospfv3Session::Ospfv3StartBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StartBfdHLAPI $args
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3StartBfd"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Ospfv3StartBfd
#Description: start bfdconfig on ospfv3router
#Input: 
#Output: None
#Coded by: michael.cai
#############################################################################
::itcl::body Ospfv3Session::Ospfv3StopBfd {args} {

    debugPut "enter the proc of Ospfv3Session::Ospfv3StopBfd"
    #set args [string tolower $args]
    set args1 $args
    set args [ConvertAttrPlusValueToLowerCase $args]
    
    lappend args -router $m_hRouter
    StopBfdHLAPI $args
    
    debugPut "exit the proc of Ospfv3Session::Ospfv3StopBfd"
    return $::mainDefine::gSuccess
}
