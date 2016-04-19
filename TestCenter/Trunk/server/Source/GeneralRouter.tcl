###########################################################################
#                                                                        
#  File Name：GeneralRouter.tcl                                                                                              
# 
#  Description：Definition of router class and its methods                                             
# 
#  Author： David.Wu
#
#  Create Time:  2007.5.10
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

##########################################
#Definition of Router class
##########################################
::itcl::class Router {
    #Variables
    public variable m_routerType ""
    public variable m_routerName  ""                       
    public variable m_routerId   ""
    public variable m_portName ""
    public variable m_hProject ""
    public variable m_hRouter ""
    public variable m_hMacAddress ""
    public variable m_hIpAddress ""
    
    public variable m_hSequencerCmdLoop ""
    
    #Constructor
    constructor { routerName routerType routerId hRouter portName hProject} {        
        set m_routerName $routerName
        set m_routerType $routerType
        set m_routerId $routerId
        set m_portName $portName
        set m_hProject $hProject
        set m_hRouter $hRouter
        lappend ::mainDefine::gObjectNameList $this
    }
    #Destructor
    destructor {
       #stc::delete $m_hRouter  
       set index [lsearch $::mainDefine::gObjectNameList $this]
       set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
        
     }

     #Methods internal use only
     public method GetMacAddress
     public method GetIpAddress

     public method SetMacAddress
}

############################################################################
#APIName: GetMacAddress
#Description: Get current MAC address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Router::GetMacAddress {args} {
    set macAddress [stc::get $m_hMacAddress -SourceMac] 
    return $macAddress
}


############################################################################
#APIName: createInternalHost
#Description: Create internal host
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
proc createInternalHost {hProject hPort portName type creator portType} {

    #Create host, and configure parameters   
           
    set hProject $hProject
    set m_portName $portName
    set m_hPort $hPort
    
    #added by yuanfen
    set m_portType $portType
    
    if {$type ==1} {
        set IpVersion ipv4
    } else {
        set IpVersion ipv6
    }
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
       uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName GetRouterMacAddress]
        }
    }
    set mac1  $::mainDefine::result   
    set hHost [stc::create Host -under $hProject]
    stc::config $hHost -name $::mainDefine::routername
    set HostName [stc::get $hHost -name]
    stc::config $hHost -RouterId $::mainDefine::routerid
    
    if {$m_portType == "ethernet"} {
        set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SourceMac $mac1]
    } elseif {$m_portType == "wan"} {   
    
        #added by yuanfen 8.11 2011
        set POSPhy(1) [lindex [stc::get $hPort -children-POSPhy] 0] 
        if {$POSPhy(1) == ""} {
            set POSPhy(1) [stc::create "POSPhy" \
               -under $hPort \
               -DataPathMode "NORMAL" \
               -Mtu "4470" \
               -PortSetupMode "PORTCONFIG_ONLY" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {POS Phy 1} ]
        }  
    
        set SonetConfig(1) [lindex [stc::get $POSPhy(1) -children-SonetConfig] 0]
        if {[stc::get $SonetConfig(1) -HdlcEnable] == "ENABLE"} { 
            if {$IpVersion == "ipv4"} {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV4"
            } else {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV6"
            }
              
            set L2If1 [stc::create HdlcIf -under $hHost -Active TRUE \
                        -ProtocolType $protocolType ]
        } else {
            if {$IpVersion == "ipv4"} {
                set protocolType "PPP_PROTOCOL_ID_IPV4"
            } else {
                set protocolType "PPP_PROTOCOL_ID_IPV6"
            }
            set L2If1 [stc::create PppIf -under $hHost -Active TRUE \
                        -ProtocolId $protocolType ]
        }
    } else { 
        #Do nothing until now  
    }
   
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
         uplevel 1 {
             set ::mainDefine::result [$::mainDefine::objectName GetRouterSeq]
         }
    }
    set routerSeq  $::mainDefine::result     
    #Add by Andy.zhang
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
       uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
        }
    }
    set chassisName  $::mainDefine::result  
     set ::mainDefine::objectName $chassisName 
    uplevel 1 {
       uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]
        }
    }
    set portNameList $::mainDefine::result
    set portSeq [lsearch $portNameList $m_portName] 
    
    if {$IpVersion == "ipv4"} {
        set hIpv4 [stc::create Ipv4If -under $hHost]
        set routerSeq [expr $routerSeq%254]
        set ipaddr "192.85.1.$routerSeq"
        stc::config $hIpv4 -Address $ipaddr
        set ::mainDefine::ipv4 $hIpv4
        set hPort $m_hPort 
        stc::config $hHost -AffiliationPort-targets $hPort
        stc::config $hHost -TopLevelIf-targets $hIpv4
        stc::config $hHost -PrimaryIf-targets $hIpv4
        set ::mainDefine::gPoolCfgBlock($HostName) $hIpv4
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
            }
        }
        set ifStack $::mainDefine::result
        if {($ifStack == "EII")||[isPortNameEqualToCreator $portName $creator] == "TRUE" } {

            stc::config $hIpv4 -StackedOnEndpoint-targets $L2If1
        #Configure the interface when IfStack == VlanOverEII
        } elseif {$ifStack == "VlanOverEII"} {
          
            set ::mainDefine::gVlanIfName $creator 
            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanTag] 
                }
              }
            set vlanId $::mainDefine::result


            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanPriority] 
                }
            }
           
            set vlanPriority $::mainDefine::result

            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanType] 
                }
            }
           
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]


            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_QinQList] 
                }
            }
           
            set QinQList $::mainDefine::result
            uplevel 1 {
                 uplevel 1 {
                     set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_hVlanIf]
                 }
             }
            set hVlanIf $::mainDefine::result
            if {$hVlanIf  == -1} {
                error "vlan subif must be created  before ConfigHost"
            }
            if {$vlanId == -1} {
                error "vlanTag must be configured before ConfigHost"
            }            
          
            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hHost -TpId $vlanType -VlanId $vlanId -Priority $vlanPriority -IdStep "0" -IdList ""] 
               stc::config $hIpv4 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1  
               set ::mainDefine::gPoolCfgBlock([getObjectName $creator]) $hVlanIf   
            } else {
               set i 0
               set m_vlanIfList(0) ""               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]
                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
                  
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hHost -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv4 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $creator]) $m_vlanIfList($i)  
               }
            }
        }  
        
    } elseif {$IpVersion == "ipv6"} {
        set hIpv61 [stc::create Ipv6If -under $hHost]
        #set ipaddr1 "fe80:0:$portSeq\::$routerSeq"
        set ipaddr1 "fe80::$portSeq:$routerSeq"
        set ipaddr2 "2000::$routerSeq"        
        stc::config $hIpv61 -Address $ipaddr1
        set hIpv62 [stc::create Ipv6If -under $hHost]
        stc::config $hIpv62 -Address $ipaddr2 -Gateway "2000::1"
     
        set hPort $m_hPort  
        stc::config $hHost -AffiliationPort-targets $hPort                   
        stc::config $hHost -TopLevelIf-targets " $hIpv61 $hIpv62 "
        stc::config $hHost -PrimaryIf-targets " $hIpv62 "
        set ::mainDefine::gPoolCfgBlock($HostName) $hIpv62

        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
            } 
        }
        set ifStack $::mainDefine::result
       if {($ifStack == "EII")||[isPortNameEqualToCreator $portName $creator] == "TRUE" } {
            stc::config $hIpv61 -StackedOnEndpoint-targets $L2If1
            stc::config $hIpv62 -StackedOnEndpoint-targets $L2If1
  
        } elseif {$ifStack == "VlanOverEII"} { 
            set ::mainDefine::gVlanIfName $creator 
            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanTag] 
                } 
              }
            set vlanId $::mainDefine::result
            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanPriority] 
                }
            }
           
            set vlanPriority $::mainDefine::result

            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanType] 
                }
            }
           
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]


            uplevel 1 {
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_QinQList] 
                }
            }
           
            set QinQList $::mainDefine::result
            uplevel 1 {
                 uplevel 1 {
                     set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_hVlanIf]
                 }
             }
            set hVlanIf $::mainDefine::result

            if {$hVlanIf  == -1} {
                error "vlan subif must be created  before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanTag must be configured before ConfigRouter"
            }            

            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hHost -VlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""] 
               stc::config $hIpv61 -StackedOnEndpoint-targets $hVlanIf 
               stc::config $hIpv62 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1  
               set ::mainDefine::gPoolCfgBlock([getObjectName $creator]) $hVlanIf
            } else {
               set i 0
               set m_vlanIfList(0) ""               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]

                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
            
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hHost -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv61 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv62 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $creator]) $m_vlanIfList($i)
               }
            }
        }
        set ::mainDefine::ipv61 $hIpv61
        set ::mainDefine::ipv62 $hIpv62
        set ::mainDefine::ipv6 $hIpv62
    } else {
        error "IpVersion:$IpVersion does not support."
    }
       
    set ::mainDefine::hostname $HostName
    set ::mainDefine::hHost $hHost  
    set ::mainDefine::hProject $hProject  
    set ::mainDefine::hPort $m_hPort  
    set ::mainDefine::portname $m_portName
    
    #added by yuanfen
    set ::mainDefine::portType $m_portType
}

############################################################################
#APIName: createInternalRouter
#Description: Create internal Router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
proc createInternalRouter {hProject hPort portName routerId type creator portType} {

    #Create Router object and configure parameters
    if {$type == 1} {
        set IpVersion ipv4
    } elseif {$type == 2} {  
        set IpVersion ipv6 
    } else {
        set IpVersion both
    }

    set m_portName $portName 
    set m_creator $creator
    
    #added by yuanfen
    set m_portType $portType
    
    set index [lsearch $::mainDefine::gObjectNameList "*$portName"]
    if {$index != -1} {
        set portName [lindex $::mainDefine::gObjectNameList $index]
    }

    set mac1 [$portName GetRouterMacAddress]  
    set hRouter [stc::create Router  \
	       -under $hProject \
	       -routerid $routerId]

    stc::config $hRouter -name $::mainDefine::routername
    set routerName [stc::get $hRouter -name]
     
    if {$m_portType == "ethernet"} {
        set L2If1 [stc::create EthIIIf -under $hRouter -Active TRUE -SourceMac $mac1]
    } elseif {$m_portType == "wan"} {   
    
        #added by yuanfen 8.11 2011
        set POSPhy(1) [lindex [stc::get $hPort -children-POSPhy] 0] 
        if {$POSPhy(1) == ""} {
            set POSPhy(1) [stc::create "POSPhy" \
               -under $hPort \
               -DataPathMode "NORMAL" \
               -Mtu "4470" \
               -PortSetupMode "PORTCONFIG_ONLY" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {POS Phy 1} ]
        }  
    
        set SonetConfig(1) [lindex [stc::get $POSPhy(1) -children-SonetConfig] 0]
        if {[stc::get $SonetConfig(1) -HdlcEnable] == "ENABLE"} { 
            if {$IpVersion == "ipv4"} {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV4"
            } else {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV6"
            }
              
            set L2If1 [stc::create HdlcIf -under $hRouter -Active TRUE \
                        -ProtocolType $protocolType ]
        } else {
            if {$IpVersion == "ipv4"} {
                set protocolType "PPP_PROTOCOL_ID_IPV4"
            } else {
                set protocolType "PPP_PROTOCOL_ID_IPV6"
            }
            set L2If1 [stc::create PppIf -under $hRouter -Active TRUE \
                        -ProtocolId $protocolType ]
        }
    } else { 
        #Do nothing until now  
    }
    
    set routerSeq [$portName GetRouterSeq] 
    #Add by Andy.zhang
    set chassisName  [$portName cget -m_chassisName]
    set portNameList [$chassisName cget -m_portNameList]
    set portSeq [lsearch $portNameList $m_portName] 
    
    if {$IpVersion == "ipv4"} {
        set hIpv4 [stc::create Ipv4If -under $hRouter]
        set ::mainDefine::ipv4 $hIpv4 
        set routerSeq [expr $routerSeq%254]
        set ipaddr "192.85.1.$routerSeq"
        stc::config $hIpv4 -Address $ipaddr
        
        stc::config $hRouter -AffiliationPort-targets $hPort
        stc::config $hRouter -TopLevelIf-targets $hIpv4
        stc::config $hRouter -PrimaryIf-targets $hIpv4
        set ::mainDefine::gPoolCfgBlock($routerName) $hIpv4
        
        set ifStack [$portName cget -m_ifStack]
        
        if {($ifStack == "EII")||[isPortNameEqualToCreator $m_portName $m_creator] == "TRUE" } {
            stc::config $hIpv4 -StackedOnEndpoint-targets $L2If1
        #Configure the interface when IfStack == VlanOverEII
        } elseif {$ifStack == "VlanOverEII"} {
            set index [lsearch $::mainDefine::gObjectNameList "*$creator"]
            if {$index != -1} {
                set creator [lindex $::mainDefine::gObjectNameList $index]
            }
          
            set vlanId [$creator cget -m_vlanTag] 
            set vlanPriority [$creator cget -m_vlanPriority] 

            set vlanType [$creator cget -m_vlanType] 
            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]
           
            set QinQList [$creator cget -m_QinQList] 
            set hVlanIf [$creator cget -m_hVlanIf] 
            if {$hVlanIf  == -1} {
                error "vlan subif must be created before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanId must be configured before ConfigRouter"
            }            
          
            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hRouter -TpId $vlanType -VlanId $vlanId -Priority $vlanPriority -IdStep "0" -IdList ""] 
               stc::config $hIpv4 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1  
               set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $hVlanIf   
            } else {
               set i 0
               set m_vlanIfList(0) ""               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]
                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
                  
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hRouter -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }                  
               } 

               if {$i != 0} {
                   stc::config $hIpv4 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $m_vlanIfList($i) 
               }
            }
        }  
        
    } elseif {$IpVersion == "ipv6"} { 
        set hIpv61 [stc::create Ipv6If -under $hRouter]
        #set ipaddr1 "fe80:0:$portSeq\::$routerSeq"
        set ipaddr1 "fe80::$portSeq:$routerSeq"
        set ipaddr2 "2000::$routerSeq"        
        stc::config $hIpv61 -Address $ipaddr1
        set hIpv62 [stc::create Ipv6If -under $hRouter]
        stc::config $hIpv62 -Address $ipaddr2 -Gateway "2000::1"
         
        stc::config $hRouter -AffiliationPort-targets $hPort                   
        stc::config $hRouter -TopLevelIf-targets " $hIpv61 $hIpv62 "
        stc::config $hRouter -PrimaryIf-targets " $hIpv61 $hIpv62 "
        set ::mainDefine::gPoolCfgBlock($routerName) $hIpv62

        set ifStack [$portName cget -m_ifStack]     
        if {($ifStack == "EII")||[isPortNameEqualToCreator $m_portName $m_creator] == "TRUE" } {
            stc::config $hIpv61 -StackedOnEndpoint-targets $L2If1
            stc::config $hIpv62 -StackedOnEndpoint-targets $L2If1
  
        } elseif {$ifStack == "VlanOverEII"} { 
            set index [lsearch $::mainDefine::gObjectNameList "*$creator"]
            if {$index != -1} {
                set creator [lindex $::mainDefine::gObjectNameList $index]
            }
            set vlanId [$creator cget -m_vlanTag] 
            set vlanPriority [$creator cget -m_vlanPriority] 

            set vlanType [$creator cget -m_vlanType] 
            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]
           
            set QinQList [$creator cget -m_QinQList] 
            set hVlanIf [$creator cget -m_hVlanIf] 
            if {$hVlanIf  == -1} {
                error "vlan subif must be created before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanId must be configured before ConfigRouter"
            }            

            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hRouter -VlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""] 
               stc::config $hIpv61 -StackedOnEndpoint-targets $hVlanIf 
               stc::config $hIpv62 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1 
               set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $hVlanIf  
            } else {
               set i 0
               set m_vlanIfList(0) ""               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]

                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
            
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hRouter -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }                  
               } 

               if {$i != 0} {
                   stc::config $hIpv61 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv62 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $m_vlanIfList($i) 
               }
            }
        }
        
        set ::mainDefine::ipv61 $hIpv61
        set ::mainDefine::ipv62 $hIpv62

        #Configure the interface for stream bounding
        set ::mainDefine::ipv6 $hIpv62
    } else {
        set hIpv61 [stc::create Ipv6If -under $hRouter]
        #set ipaddr1 "fe80:0:$portSeq\::$routerSeq"
        set ipaddr1 "fe80::$portSeq:$routerSeq"
        set ipaddr2 "2000::$routerSeq"        
        stc::config $hIpv61 -Address $ipaddr1
        set hIpv62 [stc::create Ipv6If -under $hRouter]
        stc::config $hIpv62 -Address $ipaddr2 -Gateway "2000::1"          
      
        set hIpv4 [stc::create Ipv4If -under $hRouter]
        set ::mainDefine::ipv4 $hIpv4
        set routerSeq [expr $routerSeq%254]
        set ipaddr "192.85.1.$routerSeq"
        stc::config $hIpv4 -Address $ipaddr
      
        #By default, the router will be on top of the Ipv4 interface  
        stc::config $hRouter -AffiliationPort-targets $hPort
        stc::config $hRouter -TopLevelIf-targets $hIpv4
        stc::config $hRouter -PrimaryIf-targets $hIpv4
        set ::mainDefine::gPoolCfgBlock($routerName) $hIpv4
        
        set ifStack [$portName cget -m_ifStack]     
        if {($ifStack == "EII")||[isPortNameEqualToCreator $m_portName $m_creator] == "TRUE" } {
            stc::config $hIpv4 -StackedOnEndpoint-targets $L2If1
            stc::config $hIpv61 -StackedOnEndpoint-targets $L2If1
            stc::config $hIpv62 -StackedOnEndpoint-targets $L2If1
  
        } elseif {$ifStack == "VlanOverEII"} { 
            set index [lsearch $::mainDefine::gObjectNameList "*$creator"]
            if {$index != -1} {
                set creator [lindex $::mainDefine::gObjectNameList $index]
            }
            set vlanId [$creator cget -m_vlanTag] 
            set vlanPriority [$creator cget -m_vlanPriority] 

            set vlanType [$creator cget -m_vlanType] 
            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]
           
            set QinQList [$creator cget -m_QinQList] 
            set hVlanIf [$creator cget -m_hVlanIf] 
            if {$hVlanIf  == -1} {
                error "vlan subif must be created before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanId must be configured before ConfigRouter"
            }            

            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hRouter -VlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]
               stc::config $hIpv4 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hIpv61 -StackedOnEndpoint-targets $hVlanIf 
               stc::config $hIpv62 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1 
               set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $hVlanIf  
            } else {
               set i 0
               set m_vlanIfList(0) ""               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]

                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
            
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hRouter -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" -IdList ""]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }                  
               } 

               if {$i != 0} {
                   stc::config $hIpv4 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv61 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv62 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $m_creator]) $m_vlanIfList($i) 
               }
            }
        }
        
        set ::mainDefine::ipv61 $hIpv61
        set ::mainDefine::ipv62 $hIpv62

        #Configure the interface for stream bounding
        set ::mainDefine::ipv6 $hIpv62
    }
       
    set ::mainDefine::hRouter $hRouter  
    set ::mainDefine::hProject $hProject  
    set ::mainDefine::hPort $hPort  
    set ::mainDefine::portname $m_portName
    
    #added by yuanfen
    set ::mainDefine::portType $m_portType
    
}

############################################################################
#APIName: SetMacAddress
#Description: Set current MAC address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Router::SetMacAddress {HostIpAddr {IpVersion "Ipv4"}} {
     set ::mainDefine::objectName $m_portName   
     set ::mainDefine::paraName $HostIpAddr
     uplevel 1 {  
         uplevel 1 {  
               set ::mainDefine::result [$::mainDefine::objectName GetHostHandleByIp $::mainDefine::paraName]
         }
    }    

    set hostHandle $::mainDefine::result 

     if {$hostHandle != ""} {       
           catch {
                debugPut  "Set MAC and IP address according to HOST configuration, host handle: $hostHandle "

                set EthIf1 [stc::get $hHostHandle -Children-EthIIIf]
                set macAddress [stc::get $EthIf1 -SourceMac]
                stc::config $m_hMacAddress -SourceMac $macAddress
                
                if {$IpVersion == "Ipv4"} {
                    set IpIf1 [stc::get $hHostHandle -Children-Ipv4If]
                    set m_hIpAddress $IpIf1
                } else {
                    set IpIf1 [stc::get $hHostHandle  -Children-Ipv6If]
                    set m_hIpAddress $IpIf1
                }
           }
     }

    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: GetIpAddress
#Description: Get current IP address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Router::GetIpAddress {args} {
    set IpAddress [stc::get $m_hIpAddress -address]
    return $IpAddress
}

::itcl::body TestPort::SetRouterHandle {routername hRouter} {
       set m_hGeneralRouter($routername) $hRouter
}

::itcl::body TestPort::GetRouterHandle {routername} {
       return $m_hGeneralRouter($routername)
}

############################################################################
#APIName: CreateRouter
#
#Description: Create Router object
#
#Input:  1.RouterName: Specify the Router name
#           2.RouteType:Specify Router type
#           3.RouterId:Specify RouterId
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestPort::CreateRouter {args} {
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    debugPut  "enter the proc of TestPort::CreateRouter "
    #Parse RouterName parameter
    
    set index [lsearch $args -routername]
    if { $index !=-1} {
        set routername [lindex $args [expr $index+1]]
    } else {
        error "please specify RouterName for CreateRouter API"
    }
    #Check whether or not RouterName already exists
    set index [lsearch $m_routerNameList $routername]
    if { $index !=-1} {
        error "the RouterName($routername) is already existed, please specify another one. \
        The existed RouterName is (are) as following:\n$m_routerNameList"
    }  
    #Parse RouterType parameter
    set index [lsearch $args -routertype]
    if { $index !=-1} {
        set routertype [lindex $args [expr $index+1]]
    } else {
        error "please specify routertype for CreateRouter API"
    }
    
    set routertype [string tolower $routertype]

    
    #Parse RouterId parameter
    set index [lsearch $args -routerid]
    if { $index !=-1} {
        set routerid [lindex $args [expr $index+1]]
    } else {
        set routerid 1.1.1.1
    }    

    set hRouter ""

    set m_hGeneralRouter($routername) $hRouter
    
    set ::mainDefine::routername $routername
    set ::mainDefine::routertype $routertype
    set ::mainDefine::routerid $routerid
    set ::mainDefine::hRouter $hRouter  
    set ::mainDefine::hProject $m_hProject  
    set ::mainDefine::hPort $m_hPort  
    set ::mainDefine::portname $m_portName 
    set m_creatorOfRouter $this

    #Parse relatedrouter parameter added by caimuyong 2011.08.09
    set relatedRouter ""
    set index [lsearch $args -relatedrouter]
    if { $index !=-1} {
        set relatedRouter [lindex $args [expr $index+1]]
        set ::mainDefine::objectName $relatedRouter
        uplevel 1 {  
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]
        }
        set relatedRouter $::mainDefine::result
    }
    
    set ::mainDefine::objectName $m_portName   
    set ::mainDefine::value $this
    uplevel 1 {  
       $::mainDefine::objectName configure -m_creatorOfRouter $::mainDefine::value 
    }    
 
    set ::mainDefine::chassisName $m_chassisName    
    uplevel 1 {  
       $::mainDefine::chassisName SetProtocolResultHandle  $::mainDefine::routertype
    } 

    #Create Router according to router type
    switch $routertype {
        ospfv2router {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            }
            uplevel 1 {
                Ospfv2Session $::mainDefine::routername $::mainDefine::routername \
                $::mainDefine::routertype $::mainDefine::routerid $::mainDefine::hRouter\
                $::mainDefine::portname   $::mainDefine::hProject $::mainDefine::portType   
            }
            set hRouter $::mainDefine::hRouter
            set m_hGeneralRouter($routername) $::mainDefine::hRouter
        }
        ospfv3router {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
                set hIpv6IfList [stc::get $relatedRouter -children-Ipv6If]
                set ::mainDefine::ipv61 [lindex $hIpv6IfList 0] 
                set ::mainDefine::ipv62 [lindex $hIpv6IfList 1]  
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 2 $this $m_portType
            }
            uplevel 1 {
                Ospfv3Session $::mainDefine::routername $::mainDefine::routername \
                $::mainDefine::routertype $::mainDefine::routerid $::mainDefine::hRouter\
                $::mainDefine::portname   $::mainDefine::hProject $::mainDefine::ipv61 $::mainDefine::ipv62\
                $::mainDefine::portType
            }
            set hRouter $::mainDefine::hRouter
            set m_hGeneralRouter($routername) $::mainDefine::hRouter
        }
        
        isisrouter {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 3 $this $m_portType
            }
            uplevel 1 {
                IsisSession $::mainDefine::routername $::mainDefine::routername \
                               $::mainDefine::routertype $::mainDefine::routerid \
                               $::mainDefine::hRouter  $::mainDefine::hPort \
                               $::mainDefine::portname  $::mainDefine::hProject\
                               $::mainDefine::gPortType
            }   
            set hRouter $::mainDefine::hRouter
            set m_hGeneralRouter($routername) $::mainDefine::hRouter         
        }
        
        riprouter {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            }
            uplevel 1 {
                RipSession $::mainDefine::routername $::mainDefine::routername \
                               $::mainDefine::routertype $::mainDefine::routerid \
                               $::mainDefine::hRouter  $::mainDefine::hPort \
                               $::mainDefine::portname  $::mainDefine::hProject\
                               $::mainDefine::portType
            } 
            set hRouter $::mainDefine::hRouter
            set m_hGeneralRouter($routername) $::mainDefine::hRouter          
        }
        
        ripngrouter {
             if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
                set hIpv6IfList [stc::get $relatedRouter -children-Ipv6If]
                set ::mainDefine::ipv61 [lindex $hIpv6IfList 0] 
                set ::mainDefine::ipv62 [lindex $hIpv6IfList 1]  
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 2 $this $m_portType
            } 
            uplevel 1 {
                RIPngSession $::mainDefine::routername $::mainDefine::routername \
                               $::mainDefine::routertype $::mainDefine::routerid \
                               $::mainDefine::hRouter  $::mainDefine::hPort \
                               $::mainDefine::portname  $::mainDefine::hProject \
                               $::mainDefine::ipv61 $::mainDefine::ipv62 $::mainDefine::portType
            }
            set hRouter $::mainDefine::hRouter 
            set m_hGeneralRouter($routername) $::mainDefine::hRouter           
        }
        
        bgpv4router {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            }
            uplevel 1 {
                BgpV4Session $::mainDefine::routername $::mainDefine::routername \
                                    $::mainDefine::routertype $::mainDefine::routerid \
                                    $::mainDefine::hRouter $::mainDefine::hPort \
                                    $::mainDefine::portname $::mainDefine::hProject $::mainDefine::portType  
            }            
            set hRouter $::mainDefine::hRouter
            set m_hGeneralRouter($routername) $::mainDefine::hRouter
        }

        bgpv6router {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
                set hIpv6IfList [stc::get $relatedRouter -children-Ipv6If]
                set ::mainDefine::ipv61 [lindex $hIpv6IfList 0] 
                set ::mainDefine::ipv62 [lindex $hIpv6IfList 1]  
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 2 $this $m_portType
            } 
            uplevel 1 {
                  BgpV6Session $::mainDefine::routername $::mainDefine::routername \
                                    $::mainDefine::routertype $::mainDefine::routerid \
                                    $::mainDefine::hRouter $::mainDefine::hPort \
                                    $::mainDefine::portname $::mainDefine::hProject\
                                    $::mainDefine::ipv61 $::mainDefine::ipv62 $::mainDefine::portType   
            } 
            set hRouter $::mainDefine::hRouter  
            set m_hGeneralRouter($routername) $::mainDefine::hRouter         
        }

        ldprouter {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            }
            uplevel 1 {
                LdpSession $::mainDefine::routername $::mainDefine::routername \
                               $::mainDefine::routertype $::mainDefine::routerid \
                               $::mainDefine::hRouter  $::mainDefine::hPort \
                               $::mainDefine::portname  $::mainDefine::hProject $::mainDefine::portType   
            } 
            set hRouter $::mainDefine::hRouter 
            set m_hGeneralRouter($routername) $::mainDefine::hRouter         
        }
        
        rsvprouter {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            }
            uplevel 1 {
                RsvpSession $::mainDefine::routername $::mainDefine::routername \
                                 $::mainDefine::routertype $::mainDefine::routerid $::mainDefine::hRouter\
                                 $::mainDefine::portname   $::mainDefine::hProject $::mainDefine::portType  
            } 
            set hRouter $::mainDefine::hRouter 
            set m_hGeneralRouter($routername) $::mainDefine::hRouter           
        }

        igmprouter {
            createInternalRouter $m_hProject $m_hPort $m_portName $routerid 1 $this $m_portType
            uplevel 1 {
                IgmpSession $::mainDefine::routername $::mainDefine::routername \
                                 $::mainDefine::routertype $::mainDefine::routerid $::mainDefine::hRouter\
                                  $::mainDefine::hPort $::mainDefine::portname   $::mainDefine::hProject\
                                  $::mainDefine::portType
            } 
            set hRouter $::mainDefine::hRouter 
            set m_hGeneralRouter($routername) $::mainDefine::hRouter          
        }
       
        mldrouter {
            createInternalRouter $m_hProject $m_hPort $m_portName $routerid 2 $this $m_portType
            uplevel 1 {
                MldSession $::mainDefine::routername $::mainDefine::routername \
                                 $::mainDefine::routertype $::mainDefine::routerid $::mainDefine::hRouter\
                                  $::mainDefine::hPort $::mainDefine::portname   $::mainDefine::hProject\
                                  $::mainDefine::ipv61 $::mainDefine::ipv62 $::mainDefine::portType    
            }   
            set hRouter $::mainDefine::hRouter  
            set m_hGeneralRouter($routername) $::mainDefine::hRouter       
        }
               
        pimrouter {
            if {$relatedRouter != ""} {
                set ::mainDefine::hRouter $relatedRouter
            } else {
                createInternalRouter $m_hProject $m_hPort $m_portName $routerid 3 $this $m_portType
            }             
             uplevel 1 {
                    PimSession $::mainDefine::routername $::mainDefine::routername \
                                $::mainDefine::routertype $::mainDefine::routerid \
                                $::mainDefine::hRouter  $::mainDefine::hPort \
                                $::mainDefine::portname  $::mainDefine::hProject \
                                $::mainDefine::portType
             }
             set hRouter $::mainDefine::hRouter
             set m_hGeneralRouter($routername) $::mainDefine::hRouter             
        }
       
        igmphost {         
             set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                IgmpHost $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 \
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        mldhost {
             set ::mainDefine::gGeneratorStarted "TRUE"  
            createInternalHost $m_hProject $m_hPort $m_portName 2 $this $m_portType
            uplevel 1 {
                MldHost $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject\
                         $::mainDefine::ipv6 $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        dhcpserver {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                DHCPv4Server $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject \
                         $::mainDefine::ipv4 $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        dhcpclient {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                DHCPv4Client $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::routertype\
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        dhcpv6client {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 2 $this $m_portType
            uplevel 1 {
                DHCPv6Client $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv61 $::mainDefine::ipv62 $::mainDefine::routertype\
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        dhcprelay {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                DHCPv4Client $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::routertype \
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        pppoeserver {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                PPPoEServer $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        pppoeclient {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                PPPoEClient $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        pppol2tplac {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                PppoL2tpBlock $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::routertype \
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        pppol2tplns {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                PppoL2tpBlock $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::routertype \
                         $::mainDefine::portType
            }
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }
        
        igmpodhcp {         
            set ::mainDefine::gGeneratorStarted "TRUE"     
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                IgmpHost $::mainDefine::routername\_igmp $::mainDefine::routername $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 \
                         $::mainDefine::portType
            }
            uplevel 1 {
                DHCPv4Client $::mainDefine::routername\_dhcp $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::routertype \
                         $::mainDefine::portType
            }
            uplevel 1 {
                IGMPoverDHCP $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::portType         
            }                       
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        } 
        
        igmpopppoe {         
            set ::mainDefine::gGeneratorStarted "TRUE"
            createInternalHost $m_hProject $m_hPort $m_portName 1 $this $m_portType
            uplevel 1 {
                IgmpHost $::mainDefine::routername\_igmp $::mainDefine::routername $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 \
                         $::mainDefine::portType
            }
            uplevel 1 {
                PPPoEClient $::mainDefine::routername\_pppoe $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::portType
            }
            uplevel 1 {
                IGMPoverPPPoE $::mainDefine::routername $::mainDefine::routername $::mainDefine::hHost $::mainDefine::hPort \
                         $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 $::mainDefine::portType        
            }                        
            set hRouter $::mainDefine::hHost
            set m_hGeneralRouter($routername) $hRouter
        }               
        default {
           if {$hRouter != "" } {
               stc::delete $hRouter
            }   
            error "Unsupported RouterType($routertype),the valid RouterTypes are:\n\
                    OspfRouter,IsisRouter,RipRouter,BgpRouter,LdpRouter,RsvpRouter,IgmpRouter,MldRouter,PimRouter"
        }

    }
    #Add RouterName in the list
    lappend m_routerNameList  $routername
    
    if {$relatedRouter == ""} {
        lappend m_hRouterList $hRouter
    }
    
    debugPut  "exit the proc of TestPort::CreateRouter "
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: DestroyRouter
#
#Description: Destroy Router object
#
#Input:  1.RouterName: Specify the router name
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::DestroyRouter {args} {
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    
    debugPut  "enter the proc of TestPort::DestroyRouter "
    
    #Parse routername parameter
    set index [lsearch $args -routername]
    if { $index !=-1} {
        set RouterNames [lindex $args [expr $index+1]]
    } else {

        set ::mainDefine::objectName $this 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]         
        }         
        set RouterNames $::mainDefine::result          
    }
   
    #Destroy the router specified in routername
    foreach routername $RouterNames {
        set index [lsearch $m_routerNameList $routername]
        if {$index != -1} {
            set m_routerNameList [lreplace $m_routerNameList $index $index ]

            set ::mainDefine::routername $routername
            uplevel 1 {
                itcl::delete object $::mainDefine::routername   
            }
           
            set ::mainDefine::objectName $this 
            set ::mainDefine::routername $routername
            uplevel 1 {         
                set ::mainDefine::result [$::mainDefine::objectName GetRouterHandle $::mainDefine::routername]         
            }         
           
            set hRouter $::mainDefine::result
            
            set index [lsearch $m_hRouterList $hRouter]
            if {$index == -1} {
               error "the RouterHandle($hRouter) does not exist, the existed RouterHandle(s) is(are) as following:\n$m_hRouterList"
            }
        
            set m_hRouterList [lreplace $m_hRouterList $index $index ]

            stc::delete $hRouter
        } else {
            puts "the RouterName($routername) does not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
        }                        
    }              
        
   debugPut  "exit the proc of TestPort::DestroyRouter "
   return $::mainDefine::gSuccess
}

############################################################################
#APIName: StartRouter
#
#Description: Start router
#
#Input:  1.-routerList routerList:specify the router to be started
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::StartRouter {args} {
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
   
    debugPut  "enter the proc of TestPort::StartRouter "
    
    #Parse routerList parameter
    #set args [string tolower $args]
    set index [lsearch $args -routerlist]
    if { $index !=-1} {
        set routerlist [lindex $args [expr $index+1]]
    } else {
        set ::mainDefine::objectName $this 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]         
        }         
        set routerlist $::mainDefine::result            
    }
    set hRouterList ""
    if { [catch {
        stc::apply 
    } err]} {
         set ::mainDefine::gChassisObjectHandle $m_chassisName 
         garbageCollect
         error "Apply config failed when start router, the error message is:$err" 
    }
  
    #Start the router specified in routerList
    foreach routername $routerlist {

        set ::mainDefine::objectName $this 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]         
        }         
        set routerlist $::mainDefine::result   
        
        set index [lsearch $routerlist $routername] 
        if {$index == -1} {
            error "the RouterName($routername) doese not exist, the existed RouterName(s) is(are) as following:\n $routerlist"
        }
        
        set ::mainDefine::objectName $routername 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]         
        }         
        set hRouter $::mainDefine::result 

        lappend hRouterList  $hRouter
    }
 
    set ::mainDefine::objectName $m_chassisName 
    uplevel 1 {         
         set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]         
     }
     set testPortObjectList $::mainDefine::result     

     foreach testPortObject $testPortObjectList {
           set ::mainDefine::objectName $testPortObject 
           set ::mainDefine::objectPara "0"
            
           uplevel 1 {         
                    $::mainDefine::objectName RealStartStaEngine $::mainDefine::objectPara        
           }
     }
     debugPut "Finish starting all the StaEngine objects ..."

    #Start all the capture object
    foreach testPortObject $testPortObjectList {
          set ::mainDefine::objectName $testPortObject
          uplevel 1 {         
               set ::mainDefine::result [$::mainDefine::objectName cget -m_staEngineList]         
          }  
          set staEngineObjectList $::mainDefine::result     
              
          foreach staEngineObject $staEngineObjectList {

                set ::mainDefine::objectName $staEngineObject
                uplevel 1 {
                      set ::mainDefine::result [$::mainDefine::objectName isa TestAnalysis]
                      if {$::mainDefine::result} { 
                            $::mainDefine::objectName RealConfigCaptureMode      
                            $::mainDefine::objectName RealStartCapture  
                      }
                 } 
            }
      }
     debugPut "Finish starting all the Capture objects ..."
  
    if {$hRouterList != ""} {
         stc::perform DeviceStart -DeviceList $hRouterList -ExecuteSynchronous TRUE
    } else {
         debugPut "The router list is empty, skipping start it"
    }
              
    set ::mainDefine::gGeneratorStarted "TRUE"  

    debugPut  "exit the proc of TestPort::StartRouter "
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: StopRouter
#
#Description: Stoop router
#
#Input:   1.-routerList routerList:Specify the router to be stopped
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::StopRouter {args} {
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
   
    debugPut  "enter the proc of TestPort::StopRouter "
    #Parse routerList parameter
    set index [lsearch $args -routerlist]
    if { $index !=-1} {
        set routerlist [lindex $args [expr $index+1]]
    } else {
        set routerlist $m_routerNameList
    }
    #Stop all the router specified in routerList
    set hRouterList ""
    foreach routerName $routerlist {
        set index [lsearch $m_routerNameList $routerName] 
        if {$index == -1} {
            error "the RouterName($routerName) doese not exist, the existed RouterName(s) is(are) as following:\n $m_routerNameList"
        }
        
        set ::mainDefine::objectName $routerName 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]         
        }         
        set hRouter $::mainDefine::result
        lappend hRouterList $hRouter
    }

    if {$hRouterList != ""} {
         stc::perform DeviceStop -DeviceList $hRouterList -ExecuteSynchronous TRUE
    } else {
         debugPut "The router list is empty, skipping stop it"
    }
      
    debugPut  "exit the proc of TestPort::StopRouter "
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: SetFlap
#
#Description: Flap router
#
#Input:   1. AWDTimer:Bound to Release (Or Renew to Abort) time interval,the unit is ms
#         2. WADTimer:Release to Bound (Or Abort to Renew) time interval,the unit is ms
#
#Output: None
#
#Coded by: Michael.Cai
#date:2011.08.05
#############################################################################
::itcl::body TestPort::SetFlap {args} {
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    debugPut  "enter the proc of TestPort::SetFlap "
    #Parse routerList parameter
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
    
    debugPut "exit the proc of TestPort::SetFlap"        
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: StartFlapRouters
#
#Description: StartFlap router
#
#Input:   1.-routerList routerList:Specify the router to be Flapped
#         2.-protocol protocol:Specify the protocol to be Flapped
#
#Output: None
#
#Coded by: Michael.Cai
#date:2011.08.05
#############################################################################
::itcl::body TestPort::StartFlapRouters {args} {
    debugPut "enter the proc of TestPort::StartFlapRouters" 
    set args [ConvertAttrToLowerCase $args] 
    
    set index [lsearch $args -protocol] 
    if {$index != -1} {
        set protocol [lindex $args [incr index]]
    } else {
        error "缺少必选参数-protocol! 取值范围为ospfv2/ospfv3/bgp/isis"
    }
    
    set index [lsearch $args -routernamelist] 
    if {$index != -1} {
        set routernamelist [lindex $args [incr index]]
    } else {
        set ::mainDefine::objectName $this 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]         
        }         
        set routernamelist $::mainDefine::result            
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
    set hRouters [list]
    foreach routername $routernamelist {
        set ::mainDefine::objectName $routername
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]         
        }
        lappend hRouters $::mainDefine::result
    }
    
    for {set i 0} {$i<$flapnumber} {incr i} {
        InternalFlap -protocol $protocol -flag true -routers $hRouters
        after $m_awdtimer
        InternalFlap -protocol $protocol -flag false -routers $hRouters
        after $m_wadtimer
        InternalFlap -protocol $protocol -flag true -routers $hRouters
        after $m_awdtimer
    }  

    debugPut "exit the proc of TestPort::StartFlapRouters" 
}

::itcl::body TestPort::InternalFlap {args} {
    set index [lsearch $args -protocol] 
    if {$index != -1} {
        set protocol [lindex $args [incr index]]
    }
    set index [lsearch $args -flag] 
    if {$index != -1} {
        set flag [lindex $args [incr index]]
    }
    set index [lsearch $args -routers] 
    if {$index != -1} {
        set hRouters [lindex $args [incr index]]
    }
    switch $protocol {
        ospfv2 {
            catch {
                foreach router $hRouters {
                    set ospfv2config [stc::get $router -children-Ospfv2RouterConfig]
                    if {$ospfv2config == ""} {
                        continue
                    }
                    foreach ele [stc::get $ospfv2config -Children-AsbrSummaryLsa] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv2config -Children-ExternalLsaBlock] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv2config -Children-NetworkLsa] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv2config -Children-RouterLsa] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv2config -Children-SummaryLsaBlock] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv2config -Children-TeLsa] {
                        stc::config $ele -active $flag
                    }
                }
            }
        }
        ospfv3 {
            catch {
                foreach router $hRouters {
                    set ospfv3config [stc::get $router -children-Ospfv3RouterConfig]
                    if {$ospfv3config == ""} {
                        continue
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3AsExternalLsaBlock] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3InterAreaPrefixLsaBlk] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3InterAreaRouterLsaBlock] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3IntraAreaPrefixLsaBlk] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3LinkLsaBlk] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3NetworkLsa] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3NssaLsaBlock] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $ospfv3config -Children-Ospfv3RouterLsa] {
                        stc::config $ele -active $flag
                    }
                }
            }
        }
        bgp {
            catch {
                foreach router $hRouters {
                    set bgpconfig [stc::get $router -children-BgpRouterConfig]
                    if {$bgpconfig == ""} {
                        continue
                    }
                    foreach ele [stc::get $bgpconfig -Children-BgpIpv4RouteConfig] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $bgpconfig -Children-BgpIpv4VplsConfig] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $bgpconfig -Children-BgpIpv6RouteConfig] {
                        stc::config $ele -active $flag
                    }
                    foreach ele [stc::get $bgpconfig -Children-BgpIpv6VplsConfig] {
                        stc::config $ele -active $flag
                    }
                }
            }
        }
        isis {
            catch {
                foreach router $hRouters {
                    set bgpconfig [stc::get $router -children-IsisRouterConfig]
                    if {$bgpconfig == ""} {
                        continue
                    }
                    foreach ele [stc::get $bgpconfig -Children-IsisLspConfig] {
                        stc::config $ele -active $flag
                    }
                }
            }
        }
    }
    stc::apply
}

############################################################################
#APIName: GetGatewayIp
#
#Description: Generate gateway address according to ip address
#                  If the last byte of ip address is 1, return 2
#                  If the last byte of ip address is 2, return 1
#
#Input:   1.ip:Specify the ip address
#
#Output: 相应的gateway address
#
#Coded by: David.Wu
#############################################################################

proc GetGatewayIp {ip} {
    set list [split $ip .]
    set byte0 [lindex $list 0]
    set byte1 [lindex $list 1]
    set byte2 [lindex $list 2]
    set byte3 [lindex $list 3]

    if {$byte3 == 1} {
        set byte3 2
    } else {
        set byte3 1
    }
    return $byte0.$byte1.$byte2.$byte3
}

############################################################################
#APIName: CheckKeyWord
#
#Description: 
#
#Input:   1.attribute：the attribute to be checked
#
#Output: If in the key word list, return 1; otherwise return 0
#
#Coded by: Tony
#############################################################################
set ::mainDefine::gKeyWordList {"-RouterName" "-BlockName" "-RouterType" "-GroupName" "-RpMapName" "-RouteBlockNameList" "-MulticastGroupName" \
                      "-IpVersion"  "-VpnName" "-VpnSiteName" "-RouteBlockName" "-RouteTarget" "-VpnNameList" "-GroupPoolList" "-GroupPoolName" "-Password"}
proc CheckKeyWord {attribute} {
       set keyWordList  [string tolower $::mainDefine::gKeyWordList]
       set length [llength $keyWordList]
       
       for {set i 0} {$i < $length} {incr i } {
           set value [lindex $keyWordList $i]
           if {$attribute == $value} {
                 return 1
            } 
       }
      
      return 0
}
############################################################################
#APIName: ConvertAttrPlusValueToLowerCase
#
#Description: Convert the attribute and value to lower case
#
#Input:   1.args:argument list
#
#Output: Converted argument list
#
#Coded by: David.Wu
#revised by :Yun.Lu 2011.05.16
#############################################################################
proc ConvertAttrPlusValueToLowerCase {args} {
    set loop 0
    while {[llength $args] == 1 && $loop < 4} {
       set args [eval subst $args ]
       set loop [expr $loop + 1]
    }

    set oddArgs ""

    set evenArgs ""

    set len [llength $args]

    if {[expr $len % 2] != 0} {

        error "params must be in the form of pairs: -attr value"

    }
    
    for {set i 0} {$i < $len} {incr i 2} {

        lappend evenArgs [lindex $args $i]

        set value [lindex $args [expr $i + 1]]
        if {[string tolower $value] == "enable"} {
             set value "TRUE"
        } elseif {[string tolower $value] == "disable"} {
             set value "FALSE"
        } else {
             #Do nothing here
        }
  
        lappend oddArgs $value

    }

    set evenArgs [string tolower $evenArgs]
    set oddArgs [string tolower $oddArgs] 

    set args ""

    for {set i 0} {$i < [expr $len / 2]} {incr i} {

        lappend args [lindex $evenArgs $i]

        lappend args [lindex $oddArgs $i]

    }
    return $args
}

############################################################################
#APIName: GetValuesFromArray
#
#Description: Get value from array according to variable name
#
#Input:   1.args:argument list
#            2.The array that contains the variable
#
#Output: If args is NULL, return the whole array; otherwise return the value according to attribute
#
#Coded by: Tony.Li
#############################################################################

proc GetValuesFromArray {args array} {

    if {$args == "" } {
        return $array
    } else {
        set args [ConvertAttrToLowerCase $args]
        set array [string tolower $array]

        array set arr $array
        foreach {name valueVar}  $args {      

            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }   
       return $::mainDefine::gSuccess
  }  
}

############################################################################
#APIName: GetRouterMacAddress
#
#Description: Get router MAC address
#
#Input:   1.args: name of port
#           
#
#Output: Returned MAc address
#
#Coded by: Tony.Li
#############################################################################

proc GetRouterMacAddress {portName} {

    set ::mainDefine::objectName $portName 
    uplevel 2 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNum]         
    }         
    set routerSeq $::mainDefine::result    
    incr routerSeq
    
    set ::mainDefine::value $routerSeq
    set ::mainDefine::objectName $portName   
    uplevel 2 {  
       $::mainDefine::objectName configure -m_routerNum $::mainDefine::value 
    }  
    
    set routerSeq $::mainDefine::routerNum
    incr routerSeq
    set ::mainDefine::routerNum $routerSeq
    set routerSeq1 [expr ($routerSeq/256)%256]
    set routerSeq2 [expr ($routerSeq/256/256)%256]
    set mac 00:20:94:[format "%0.2x" $routerSeq2]:[format "%0.2x" $routerSeq1]:[format "%0.2x" [expr $routerSeq%256]]
   
     return $mac
}

############################################################################
#APIName: ApplyValidationCheck
#
#Description: Check the errors of stc::apply
#
#Input:   
#           
#
#Output: If there are errors during stc::apply, return error and errorCode
#
#Coded by: Penn.Chen
#############################################################################

proc ApplyValidationCheck {} {
    if { [catch {
        stc::apply 
    } err]} {
        set ::mainDefine::gErrMsg $err
        return  $::mainDefine::gErrCode    
    }    
}
