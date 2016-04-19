###########################################################################
#                                                                        
#  File Name：EthernetPort.tcl                                                                                              
# 
#  Description：Definitiion of Ethernet class and its methods                                             
# 
#  Author： David.Wu
#
#  Create Time:  2007.5.10
#
#  Versioin：1.0 
# 
#  History： 
# 
##########################################################################
##########################################
#Definition of Ethernet port class
##########################################  
::itcl::class ETHPort {

    #variables
    public variable m_autoNeg 0
    public variable m_mtuSize 0
    public variable m_arpEnable 0
    public variable m_duplexMode 0
    public variable m_linkSpeed 0
    public variable m_flowControl 0
    public variable m_mediaType "ETHERNET_COPPER"
    public variable m_vlanIfNameList ""
    public variable m_hLayer2If 0
    public variable m_lacpPortConfig
    public variable m_portName
    public variable m_vlanName   
    public variable m_portType Ethernet
    public variable m_ifStack EII
    public variable m_lacpportgroup ""
    public variable m_actorkey 1
    public variable m_actorportpriority 1
    public variable m_lacpactiveity "ACTIVE"    
    public variable m_lacptimeout "LONG"
    public variable m_bridgeNameList ""
    public variable m_hLacpPortResults "" 
    public variable m_hResultDataSet ""
    public variable m_autoNegotiationMasterSlave "MASTER"
    public variable m_portMode "LAN"
	public variable m_media "COPPER"

    #Inherit from the parent class
    inherit TestPort
    #Constructor
    constructor { portName hPort portType chassisName portLocation hProject chassisIp mode} \
    { TestPort::constructor $portName $hPort $portType $chassisName $portLocation $hProject $chassisIp $mode} { 
        set ::mainDefine::objectName $portName 
        if {$mode == "inherit"} {
             uplevel 1 { 
                   uplevel 1 {    
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
                   }
              }     
        } else {
               set m_hLayer2If [stc::create EthIIIf -under $m_hPort]
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
    public method GetPortState
    public method CreateSubInt
    public method DestroySubInt  
    public method CreateArpd
    public method ConfigArpEntry
    public method DeleteArpEntry
    public method StartArpd     
    public method StopArpd     
    public method CreateLacpPort
    public method ConfigLacpPort 
    public method GetLacpPort
    public method DeleteLacpPort
    public method StartLacpPort
    public method StopLacpPort
    public method StopLacpPdu     
    public method ResumeLacpPdu      
    public method CreateStpBridge
    public method DestroyStpBridge
    public method StartStpBridge
    public method StopStpBridge   
    public method GetLacpPortStats  
}

##########################################
#Definition of Vlan sub-interface class
##########################################  
::itcl::class VlanSubInt {

    #Variables    
    public variable m_portName  0
    public variable m_vlanTag  0
    public variable m_QinQList  ""
    public variable m_vlanPriority  0
    public variable m_hVlanIf 0
    public variable m_vlanType 0x8100

    #Inherit from ETHPort
    inherit ETHPort

    #Constructor    
    constructor { portName hPort chassisName portLocation hProject chassisIp} { ETHPort::constructor $portName $hPort "ethernet" $chassisName \
                                                                          $portLocation $hProject \
                                                                          $chassisIp  inherit}  { 
        set m_portName $portName     
        set m_ifStack VlanOverEII
  
        set ::mainDefine::objectName $portName 
        set ::mainDefine::value VlanOverEII
        uplevel 1 {
           $::mainDefine::objectName configure -m_ifStack $::mainDefine::value 
        }
       
        set ::mainDefine::objectName $portName 
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set hPort $::mainDefine::result  

        set ::mainDefine::objectName $portName 
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hLayer2If]     
        }     
        set hLayer2If $::mainDefine::result  
        
        set m_hVlanIf [stc::create VlanIf -under $hPort]
        stc::config $m_hVlanIf -StackedOnEndpoint-targets $hLayer2If   

        lappend ::mainDefine::gObjectNameList $this
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }

    #Methods
    public method ConfigVlanIf
    public method ConfigPort
    #Methods for internal 
    public method GetRouterList
    public method GetHostList
   
}

############################################################################
#APIName: ConfigPort
#
#Description: Config the attributes of the port
#
#Input:  1. -MediaType MediaType:optional, specify the media type of the port
#           2. -LinkSpeed LinkSpeed:optional，speficy the port speed
#           3. -DuplexMode DuplexMode:optional, specify the duplex mode
#           4. -AutoNeg AutoNeg:optional，auto negotiation flag
#           5. -ArpEnable ArpEnable:optional，specify whether or not enable arp reply
#           6. -MtuSize MtuSize:optional，specify the MTU size of the port
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body ETHPort::ConfigPort {args}  {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of ETHPort::ConfigPort"
    set phy [stc::get $m_hPort -SupportedPhys]
    if {$phy == "ETHERNET_COPPER|ETHERNET_FIBER"} {

        #Parse MediaType parameter
        set index [lsearch $args -mediatype ] 
        if {$index != -1} {
            set MediaType  [lindex $args [expr $index + 1]]
			set m_media $MediaType
        } else  {
            set MediaType $m_media
        }
        if {[string tolower $MediaType] =="fiber"} {
              set phy "ETHERNET_FIBER"
              set m_mediaType "ETHERNET_FIBER"
        } elseif {[string tolower $MediaType] =="copper"} {
	          set phy "ETHERNET_COPPER"
              set m_mediaType "ETHERNET_COPPER"
        } else {
              error "Parameter MediaType should be FIBER/COPPER, your value is $MediaType"
        }
    
    }

    #Parse LinkSpeed parameter
    set index [lsearch $args -linkspeed ] 
    if {$index != -1} {
        set LinkSpeed  [lindex $args [expr $index + 1]]
    } else  {
        set LinkSpeed   "AUTO"
    }

    if {[string tolower $LinkSpeed] == "10m"} {
        set LinkSpeed "SPEED_10M"
    } elseif {[string tolower $LinkSpeed] == "100m"} {
        set LinkSpeed "SPEED_100M"
    } elseif {[string tolower $LinkSpeed] == "1g"} {
        set LinkSpeed "SPEED_1G"
    } elseif {[string tolower $LinkSpeed] == "10g"} {
        set LinkSpeed "SPEED_10G"
    } elseif {[string tolower $LinkSpeed] == "auto"}  {
        if {$phy == "ETHERNET_10_GIG_FIBER" || $phy == "ETHERNET_10_GIG_COPPER"} {
           set LinkSpeed "SPEED_10G"
        } else {
           set LinkSpeed "SPEED_1G"
        }     
    } else {
        error "unsuppoted port speed"
    }
    set m_linkSpeed $LinkSpeed

    #Parse DuplexMode parameter
    set index [lsearch $args -duplexmode ] 
    if {$index != -1} {
        set DuplexMode  [lindex $args [expr $index + 1]]
    } else  {
        set DuplexMode   "FULL"
    }  
    set m_duplexMode $DuplexMode

    #Parse AutoNeg parameter
    set index [lsearch $args -autoneg ] 
    if {$index != -1} {
        set AutoNeg  [lindex $args [expr $index + 1]]
        if {[string tolower $AutoNeg] == "auto"} {
            set AutoNeg "TRUE"
        }
    } else  {
        set AutoNeg   "TRUE"
    }
    
    set m_autoNeg $AutoNeg
   
    #Parse ArpEnable parameter
    set index [lsearch $args -arpenable] 
    if {$index != -1} {
        set ArpEnable [lindex $args [expr $index + 1]]
    } else  {
        set ArpEnable  "TRUE"
    }
    set m_arpEnable $ArpEnable

    set index [lsearch $args -mtusize] 
    if {$index != -1} {
        set MtuSize [lindex $args [expr $index + 1]]
    } else  {
        set MtuSize  1500
    }   
    set m_mtuSize $MtuSize

    #Parse FlowControl parameter
    set index [lsearch $args -flowcontrol] 
    if {$index != -1} {
        set FlowControl [lindex $args [expr $index + 1]]
        set FlowControl [string tolower $FlowControl]
        if {$FlowControl == "off" || $FlowControl  == "false"} {
               set FlowControl "FALSE"
        } elseif {$FlowControl == "on" || $FlowControl == "true"} {
               set FlowControl "TRUE"
        } 
    } else  {
        set FlowControl  FALSE
    }   
    set m_flowControl $FlowControl 

    #Parse AutoNegotiationMasterSlave parameter
    set index [lsearch $args -autonegotiationmasterslave] 
    if {$index != -1} {
        set AutoNegotiationMasterSlave [lindex $args [expr $index + 1]]
        set m_autoNegotiationMasterSlave $AutoNegotiationMasterSlave
    } else  {
        set AutoNegotiationMasterSlave  $m_autoNegotiationMasterSlave
    }
  
    set index [lsearch $args -portmode] 
    if {$index != -1} {
        set PortMode [lindex $args [expr $index + 1]]
        set m_portMode $PortMode
    } 

    #Get the handle 
    if {$phy == "ETHERNET_COPPER"} {
        if {[stc::get $m_hPort -children-EthernetCopper] ==""} {
            set hLinkConfig [stc::create EthernetCopper -under $m_hPort]
        } else {
            set hLinkConfig [stc::get $m_hPort -children-EthernetCopper]
        }
     } elseif {$phy == "ETHERNET_10_GIG_FIBER"} {
        set AutoNeg "FALSE"
        if {[stc::get $m_hPort -children-Ethernet10GigFiber] ==""} {
            set hLinkConfig [stc::create Ethernet10GigFiber -under $m_hPort]
        } else {
            set hLinkConfig [stc::get $m_hPort -children-Ethernet10GigFiber]
        }
     } elseif {$phy == "ETHERNET_10_GIG_COPPER"} {
         if {[stc::get $m_hPort -children-Ethernet10GigCopper] ==""} {
             set hLinkConfig [stc::create Ethernet10GigCopper -under $m_hPort]
         } else {
             set hLinkConfig [stc::get $m_hPort -children-Ethernet10GigCopper]
         }
     } else {
         if {[stc::get $m_hPort -children-EthernetFiber] ==""} {
             set hLinkConfig [stc::create EthernetFiber -under $m_hPort]
         } else {
             set hLinkConfig [stc::get $m_hPort -children-EthernetFiber]
         }
     }

     #Config port parameters
     if {$phy == "ETHERNET_FIBER"} {
         stc::config $hLinkConfig \
                   -Mtu $MtuSize -AutoNegotiationMasterSlave $AutoNegotiationMasterSlave \
                   -LineSpeed $LinkSpeed\
                   -AutoNegotiation $AutoNeg\
                   -FlowControl $FlowControl    
     } else {
         if {$LinkSpeed == "SPEED_10G"} {
             stc::config $hLinkConfig \
                        -Mtu $MtuSize -AutoNegotiationMasterSlave $AutoNegotiationMasterSlave \
                        -LineSpeed $LinkSpeed \
                        -AutoNegotiation $AutoNeg\
                        -FlowControl $FlowControl -PortMode $m_portMode
         } else {  
             stc::config $hLinkConfig \
                        -Mtu $MtuSize -AutoNegotiationMasterSlave $AutoNegotiationMasterSlave \
                        -LineSpeed $LinkSpeed\
                        -Duplex $DuplexMode\
                        -AutoNegotiation $AutoNeg\
                        -FlowControl $FlowControl    
        }   
    }

    stc::config $m_hPort -ActivePhy-targets $hLinkConfig
    stc::perform PortSetupSetActivePhy -ActivePhy $hLinkConfig

    set hArpConfig [stc::get $m_hProject -children-arpndconfig]      
    stc::config $hArpConfig -Active $ArpEnable  
    
    stc::apply

    debugPut "exit the proc of ETHPort::ConfigPort"   
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateSubInt
#
#Description: Create VlanSubInt objects
#
#Input:  1. -SubIntName SubIntName:required，specify the name of VlanIf object
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body ETHPort::CreateSubInt {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]      
    debugPut "enter the proc of ETHPort::CreateSubInt"    
    #Parse SubIntName parameter
    set index [lsearch $args -subintname] 
    if {$index != -1} {
        set SubIntName [lindex $args [expr $index + 1]]
    } else  {
        error "please specify SubIntName for CreateSubInt API"
    }

    #Check whether or not SubIntName is unique
    set index [lsearch $m_vlanIfNameList $SubIntName] 
    if {$index != -1} {
        error "the SubIntName is already exsited,please specify another one, the existed SubIntName(s) is(are):\n$m_vlanIfNameList"
    } 
    lappend m_vlanIfNameList $SubIntName
    set m_vlanName $SubIntName
    set ::mainDefine::gPortName $m_portName

    set ::mainDefine::gVlanIfName $SubIntName
    set ::mainDefine::hPort $m_hPort
  
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::chassisName [$::mainDefine::objectName cget -m_chassisName]     
    }     

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::portLocation [$::mainDefine::objectName cget -m_portLocation]     
    }     

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::hProject [$::mainDefine::objectName cget -m_hProject]     
    }     
  
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::chassisIp [$::mainDefine::objectName cget -m_chassisIp]     
    }     
    
    #Create VlanSubInt object
    uplevel 1 {
        VlanSubInt $::mainDefine::gVlanIfName $::mainDefine::gPortName $::mainDefine::hPort  $::mainDefine::chassisName \
                   $::mainDefine::portLocation  $::mainDefine::hProject  $::mainDefine::chassisIp
    }
    
    debugPut "exit the proc of  ETHPort::CreateSubInt"        
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: DestroySubInt
#
#Description: Destroy Vlan sub-interface object
#
#Input:  1. -SubIntName SubIntName:optional，specify the name of VlanIf object
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body ETHPort::DestroySubInt  {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of ETHPort::DestroySubInt"
    #Parse SubIntName parameter
    set index [lsearch $args -subintname] 
    if {$index != -1} {
        set SubIntName [lindex $args [expr $index + 1]]
    } else  {
        set SubIntName "all"
    }
    if {$SubIntName != "all"} {
        set index [lsearch $m_vlanIfNameList $SubIntName] 
        if {$index != -1} {

            set routerNameList ""
            set hostNameList "" 

            #Delete all router objects in VLAN sub-interface object
            set ::mainDefine::gSubIntName $SubIntName
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gSubIntName GetRouterList] 
            }   
            set routerNameList $::mainDefine::result
            foreach routerName $routerNameList {
               set ::mainDefine::gObjectName $SubIntName
               set ::mainDefine::gParaName $routerName
               uplevel 1 {
                  $::mainDefine::gObjectName DestroyRouter -RouterName $::mainDefine::gParaName 
               }  
            }

            #Delete all host objects in VLAN sub-interface object
            set ::mainDefine::gSubIntName $SubIntName
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gSubIntName GetHostList] 
            }   
            set hostNameList $::mainDefine::result
            foreach hostName $hostNameList {
               set ::mainDefine::gObjectName $SubIntName
               set ::mainDefine::gParaName $hostName
               uplevel 1 {
                  $::mainDefine::gObjectName DestroyHost -HostName $::mainDefine::gParaName 
               }  
            }

            set m_vlanIfNameList [lreplace $m_vlanIfNameList $index $index ]
            set ::mainDefine::gSubIntName $SubIntName
            #Destroy VlanSubInt object
            set ::mainDefine::gVlanDestroyFlag  1
            uplevel 1 {
                itcl::delete object $::mainDefine::gSubIntName 
            }   
            set ::mainDefine::gVlanDestroyFlag  0
            
        } else  {
            error "the SubIntName ($SubIntName) does not exist, the existed portnames are:\n$m_vlanIfNameList"
        } 
    } else {
     
        foreach SubIntName $m_vlanIfNameList {
            set routerNameList ""
            set hostNameList "" 
            
            #Delete all router objects in VLAN sub-interface object
            set ::mainDefine::gSubIntName $SubIntName
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gSubIntName GetRouterList] 
            }   
            set routerNameList $::mainDefine::result
            foreach routerName $routerNameList {
               set ::mainDefine::gObjectName $SubIntName
               set ::mainDefine::gParaName $routerName
               uplevel 1 {
                  $::mainDefine::gObjectName DestroyRouter -RouterName $::mainDefine::gParaName 
               }  
            }

            #删除VLAN子接口中的所有host对象
            set ::mainDefine::gSubIntName $SubIntName
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gSubIntName GetHostList] 
            }   
            set hostNameList $::mainDefine::result
            foreach hostName $hostNameList {
               set ::mainDefine::gObjectName $SubIntName
               set ::mainDefine::gParaName $hostName
               uplevel 1 {
                  $::mainDefine::gObjectName DestroyHost -HostName $::mainDefine::gParaName 
               }  
            }

            set ::mainDefine::gSubIntName $SubIntName
           set ::mainDefine::gVlanDestroyFlag  1
            uplevel 1 {
                itcl::delete object $::mainDefine::gSubIntName 
            }   
            set ::mainDefine::gVlanDestroyFlag  0            
        }    
        set m_vlanIfNameList ""
    }

    debugPut "exit the proc of ETHPort::DestroySubInt"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: ConfigVlanIf
#
#Description: Configure the parameters of VlanIf
#
#Input:  1. -VlanTag VlanTag:optional，specify VlanId of VlanIf
#           2. -QinQList QinQList:optional，specify VlanId list in QinQ
#           3. -VlanPriority VlanPriority:optional，specify the priority of VlanIf
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body VlanSubInt::ConfigVlanIf {args} {    

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of VlanSubInt::ConfigVlanIf"
  
    set index [lsearch $args -vlanid]
    if {$index == -1} { 
       set index [lsearch $args -vlantag] 
    }

    if {$index != -1} {
        set VlanTag [lindex $args [expr $index + 1]]
        set m_vlanTag $VlanTag
        stc::config $m_hVlanIf -VlanId $m_vlanTag
    } else  {
        set index [lsearch $args -qinqlist] 
        if {$index != -1} {
            set QinQList [lindex $args [expr $index + 1]]
            foreach QinQ $QinQList {
                if {[llength $QinQ] != 3} {
                    error "Error: QinQ format error, should be {VlanType VlanId VlanPriority} format!"
                }
            }
            set m_QinQList $QinQList
        } 
    }

    set index [lsearch $args -vlanpriority ] 
    if {$index != -1} {
        set VlanPriority  [lindex $args [expr $index + 1]]
    } else  {
        set VlanPriority 0        
    }
    set m_vlanPriority  $VlanPriority  
    set priority [lindex $VlanPriority 0]

    set index [lsearch $args -vlantype ] 
    if {$index != -1} {
        set VlanType  [lindex $args [expr $index + 1]]
    } else  {
        set VlanType $m_vlanType        
    }
    set m_vlanType $VlanType 
    set VlanType [lindex $VlanType 0]
    set VlanType [format %d $VlanType]

    stc::config $m_hVlanIf -Priority $priority -Tpid $VlanType
    
    debugPut "exit the proc of VlanSubInt::ConfigVlanIf "    
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetRouterList
#
#Description: Get the router list in VLAN sub-interface
#
#Input:  1. None
#
#Output: Created router list in VLAN sub-interface
#
#Coded by: David.Wu
#############################################################################
::itcl::body VlanSubInt::GetRouterList {args} {
    
    return $m_routerNameList
}

############################################################################
#APIName: GetHostList
#
#Description: get the host list in VlanSubInt object
#
#Input:  1. None
#
#Output: the host list in VlanSubInt object
#
#Coded by: David.Wu
#############################################################################
::itcl::body VlanSubInt::GetHostList {args} {
    
    return $m_hostNameList
}

############################################################################
#APIName: ConfigPort
#
#Description: Configure the parameters of VlanIf
#
#Input:  1. -VlanTag VlanTag:optional，specify VlanId of VlanIf
#           2. -QinQList QinQList:optional，specify VlanId list in QinQ
#           3. -VlanPriority VlanPriority:optional，specify the priority of VlanIf
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body VlanSubInt::ConfigPort {args} {   

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]          
    debugPut "enter the proc of VlanSubInt::ConfigPort"

    set index [lsearch $args -vlanid]
    if {$index == -1} { 
       set index [lsearch $args -vlantag] 
    }
  
    if {$index != -1} {
        set VlanTag [lindex $args [expr $index + 1]]
        set m_vlanTag $VlanTag
        stc::config $m_hVlanIf -VlanId $m_vlanTag
    } else  {
        set index [lsearch $args -qinqlist] 
        if {$index != -1} {
            set QinQList [lindex $args [expr $index + 1]]
            foreach QinQ $QinQList {
                if {[llength $QinQ] != 3} {
                    error "Error: QinQ format error, should be {VlanType VlanId VlanPriority} format!"
                }
            }
            set m_QinQList $QinQList
        } 
    }

    set index [lsearch $args -vlanpriority ] 
    if {$index != -1} {
        set VlanPriority  [lindex $args [expr $index + 1]]
    } else  {
        set VlanPriority 0        
    }
    set m_vlanPriority  $VlanPriority 
    set priority [lindex $VlanPriority 0]

    set index [lsearch $args -vlantype ] 
    if {$index != -1} {
        set VlanType  [lindex $args [expr $index + 1]]
    } else  {
        set VlanType $m_vlanType        
    }
    set m_vlanType $VlanType 
    set VlanType [lindex $VlanType 0]
    set VlanType [format %d $VlanType]

    stc::config $m_hVlanIf -Priority $priority -Tpid $VlanType
    
    debugPut "exit the proc of VlanSubInt::ConfigPort "    
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetPortState
#Description: get port state
#Input: 1. args:argument list, including
#              (1) -LinkSpeed LinkSpeed optional,link speed 
#              (2) -DuplexMode DuplexMode optional，duplex mode
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body ETHPort::GetPortState {{args }} {
       
    debugPut "enter the proc of ETHPort::GetPortState..."
    stc::apply
    set waitTime 2000
    after $waitTime

    set phy [stc::get $m_hPort -SupportedPhys]
    if {($phy == "ETHERNET_COPPER|ETHERNET_FIBER") } {
        
        set phy $m_mediaType
        if {$phy == ""} {
            set phy ETHERNET_COPPER
        }
    }
   
    #Read the port state from the STC configuration
    if {$phy == "ETHERNET_COPPER"} {
        set hLinkConfig [stc::get $m_hPort -children-EthernetCopper] 
 
        array set phyConfig  [stc::get $hLinkConfig]
         
        #parray phyConfig
        set LinkState $phyConfig(-LinkStatus)
        set LinkSpeed $phyConfig(-LineSpeedStatus)
        set DuplexMode $phyConfig(-DuplexStatus)

        set arr(-LinkState)  $LinkState
        set arr(-LinkSpeed)  $LinkSpeed
        set arr(-DuplexMode)  $DuplexMode
     } elseif {$phy == "ETHERNET_10_GIG_FIBER"} {
        set hLinkConfig [stc::get $m_hPort -children-Ethernet10GigFiber]     
        array set phyConfig  [stc::get $hLinkConfig]
        set LinkState $phyConfig(-LinkStatus)
        set LinkSpeed $phyConfig(-LineSpeed)
        set DuplexMode "FULL"

        set arr(-LinkState)  $LinkState
        set arr(-LinkSpeed)  $LinkSpeed
        set arr(-DuplexMode)  $DuplexMode
    } elseif {$phy == "ETHERNET_10_GIG_COPPER"} {
        set hLinkConfig [stc::get $m_hPort -children-Ethernet10GigCopper]     
        array set phyConfig  [stc::get $hLinkConfig]
        set LinkState $phyConfig(-LinkStatus)
        set LinkSpeed $phyConfig(-LineSpeed)
        set DuplexMode "FULL"

        set arr(-LinkState)  $LinkState
        set arr(-LinkSpeed)  $LinkSpeed
        set arr(-DuplexMode)  $DuplexMode
    } else {
        set hLinkConfig [stc::get $m_hPort -children-EthernetFiber]     
        array set phyConfig  [stc::get $hLinkConfig]
        set LinkState $phyConfig(-LinkStatus)
        set LinkSpeed $phyConfig(-LineSpeed)
        set DuplexMode "FULL"

        set arr(-LinkState)  $LinkState
        set arr(-LinkSpeed)  $LinkSpeed
        set arr(-DuplexMode)  $DuplexMode
    }

    set arr(-PhyState)  "UP"
 
    set list ""
    if {$args=="-debug" } {
        foreach name [array names phyConfig] {
            lappend list $name
            lappend list $phyConfig($name)
        }
        return $list
    }

    #Return port state
    set len [llength $args]
    if {$len == 0} {
        if {$phy == "ETHERNET_COPPER"} {
            return "-PhyState UP -LinkState $LinkState  -LinkSpeed  $LinkSpeed -DuplexMode $DuplexMode"
        } else {
            return "-PhyState UP -LinkState $LinkState  -LinkSpeed  $LinkSpeed -DuplexMode $DuplexMode"
        }
    } else {
        if {[expr $len % 2] != 0} {
            error "format args must be pairs as:-attrName attrValue "
        }  
        foreach {name value} $args {        
            set ::mainDefine::gValue $arr($name)

            set ::mainDefine::gVar $value

            uplevel 1 {
                set $::mainDefine::gVar  $::mainDefine::gValue
            }                      
        }
    }
   
    debugPut "exit the proc of ETHPort::GetPortState..."
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateArpd
#Description: 
#Input: 
#              (1) -EnableCyclicArp optional，enable cyclicARP
#              (2) -ReplyWithUniqueMacAddr optional，unique MAC addr reply
#              (3) -RetryCnt optional，ARP request retry count
#              (4) -TimeOut optional，ARP request timeout
#              (5) -LearningRate optional
#              (6) -MaxBurst optional
#              (7) -DuplicateGatewayDetection optional
#              (8) -ProcessGratuitousArpRequests optional
#              (9) -EnableUniqueMacPattern optional
#              (10) -ProcessUnsolicitedArpReplies optional
#
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body ETHPort::CreateArpd {args}  {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "Enter the proc of ETHPort::CreateArpd"
    
    #Parse parameters
    set index [lsearch $args -enablecyclicarp] 
    if {$index != -1} {
        set EnableCyclicArp [lindex $args [expr $index + 1]]
    } else  {
        set EnableCyclicArp "TRUE"
    }
    set index [lsearch $args -learningrate] 
    if {$index != -1} {
        set LearningRate [lindex $args [expr $index + 1]]
    } else  {
        set LearningRate 250
    }
    set index [lsearch $args -maxburst] 
    if {$index != -1} {
        set MaxBurst [lindex $args [expr $index + 1]]
    } else  {
        set MaxBurst 16
    }
    set index [lsearch $args -duplicategatewaydetection] 
    if {$index != -1} {
        set DuplicateGatewayDetection [lindex $args [expr $index + 1]]
    } else  {
        set DuplicateGatewayDetection "TRUE"
    }
    set index [lsearch $args -processgratuitousarprequests] 
    if {$index != -1} {
        set ProcessGratuitousArpRequests [lindex $args [expr $index + 1]]
    } else  {
        set ProcessGratuitousArpRequests "TRUE"
    }
    set index [lsearch $args -enableuniquemacpattern] 
    if {$index != -1} {
        set EnableUniqueMacPattern [lindex $args [expr $index + 1]]
    } else  {
        set EnableUniqueMacPattern "2222"
    }
    set index [lsearch $args -replywithuniquemacaddr] 
    if {$index != -1} {
        set ReplyWithUniqueMacAddr [lindex $args [expr $index + 1]]
    } else  {
        set ReplyWithUniqueMacAddr "TRUE"
    } 
    set index [lsearch $args -processunsolicitedarpreplies] 
    if {$index != -1} {
        set ProcessUnsolicitedArpReplies [lindex $args [expr $index + 1]]
    } else  {
        set ProcessUnsolicitedArpReplies "TRUE"
    } 
    set index [lsearch $args -retrycnt] 
    if {$index != -1} {
        set RetryCnt [lindex $args [expr $index + 1]]
    } else  {
        set RetryCnt 3
    } 
    set index [lsearch $args -timeout] 
    if {$index != -1} {
        set TimeOut [lindex $args [expr $index + 1]]
    } else  {
        set TimeOut 1000
    }  

    #Configure ArpNd
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]     
    }     
    set ProjHandle $::mainDefine::result  
          
    set ArpNdConfigHandle [stc::get $ProjHandle -children-ArpNdConfig]
    stc::config $ArpNdConfigHandle \
        -LearningRate $LearningRate \
        -MaxBurst $MaxBurst \
        -EnableCyclicArp $EnableCyclicArp \
        -DuplicateGatewayDetection $DuplicateGatewayDetection \
        -RetryCount $RetryCnt \
        -TimeOut $TimeOut \
        -EnableUniqueMacAddrInReply $ReplyWithUniqueMacAddr \
        -EnableUniqueMacPattern $EnableUniqueMacPattern \
        -ProcessGratuitousArpRequests $ProcessGratuitousArpRequests \
        -ProcessUnsolicitedArpReplies $ProcessUnsolicitedArpReplies \
        -Active "TRUE" 
     
    stc::apply
      
    debugPut "Exit the proc of ETHPort::CreateArpd"   
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigArpEntry
#Description: Config Arp Entry
#Input:     
#              (1) -HostName required, name of the host
#              (2) -HostNum optional, number of the host
#              (3) -GwIp optional, gateway IP address
#              (4) -GwMac optional, gateway MAC address
#              (5) -SrcIp optional，source IP address
#              (6) -SrcIpPrefix optional，source IP address prefix
#              (7) -SrcIpStep optional, source IP address step
#              (8) -SrcIpStepMask optional, source IP address step mask
#              (9) -SrcMac optional，source MAC address
#            (10) -SrcMacStep optional,source MAC address step
#            (11) -SrcMacStepMask optional，source MAC address step mask
#            (12) -SrcIpv6 optional，source IP address
#            (13) -SrcIpv6Prefix optional，source ipv6 address prefix
#            (14) -GwIpv6 optional，ipv6 gateway MAC address
#
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body ETHPort::ConfigArpEntry {args}  {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of ETHPort::ConfigArpEntry"

    set IpVersion "ipv4"     
    #Parse HostName parameter
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the HostName"
    }
       
    #Parse HostNum parameter
    set index [lsearch $args -hostnum] 
    if {$index != -1} {
        set HostNum [lindex $args [expr $index + 1]]
    } else  {
        set HostNum 1
    }
    
    #Parse GwIp parameter
    set index [lsearch $args -gwip] 
    if {$index != -1} {
        set GwIp [lindex $args [expr $index + 1]]
        set IpVersion "ipv4"     
    } else  {
        set GwIp 192.168.1.1
    }

    #Parse GwMac parameter
    set index [lsearch $args -gwmac] 
    if {$index != -1} {
        set GwMac [lindex $args [expr $index + 1]]
    } else  {
        set GwMac "00:00:01:00:00:01"
    }
    
    #Parse SrcIp parameter
    set index [lsearch $args -srcip] 
    if {$index != -1} {
        set SrcIp [lindex $args [expr $index + 1]]
        set IpVersion "ipv4"     
    } else  {
        set SrcIp 192.168.1.2
    }
    
    #Parse SrcIpPrefix parameter
    set index [lsearch $args -srcipprefix] 
    if {$index != -1} {
        set SrcIpPrefix [lindex $args [expr $index + 1]]
    } else  {
        set SrcIpPrefix 24
    }
    
    #Parse SrcIpStep parameter
    set index [lsearch $args -srcipstep] 
    if {$index != -1} {
        set SrcIpStep [lindex $args [expr $index + 1]]
         set IpVersion "ipv4"     

        set step ""
        set tmp_index [string first "." $SrcIpStep] 
        if {$tmp_index == -1} {
            for {set i 0} {$i <4} { incr i} {
                set mod1 [expr $SrcIpStep%255]
                if {$step ==""} {
                    set step $mod1
                } else  {
                    set step $mod1.$step
                }
                set SrcIpStep [expr $SrcIpStep/255]
            }
            set SrcIpStep $step
        }     
    } else  {
        set SrcIpStep "0.0.0.1"
    }

    #Parse SrcIpStepMask parameter
    set index [lsearch $args -srcipstepmask] 
    if {$index != -1} {
        set SrcIpStepMask [lindex $args [expr $index + 1]]
        set IpVersion "ipv4"     
    } else  {
        set SrcIpStepMask "255.255.255.255"
    }
    
    #Parse SrcMac parameter
    set index [lsearch $args -srcmac] 
    if {$index != -1} {
        set SrcMac [lindex $args [expr $index + 1]]
    } else  {
        set SrcMac "00:00:00:00:00:01"
    }
    
    #Parse SrcMacCount parameter
    set index [lsearch $args -srcmaccount] 
    if {$index != -1} {
        set SrcMacCount [lindex $args [expr $index + 1]]
    } else  {
        set SrcMacCount 1
    }
    
    #Parse SrcMacStep parameter
    set index [lsearch $args -srcmacstep] 
    if {$index != -1} {
        set SrcMacStep [lindex $args [expr $index + 1]]
    } else  {
        set SrcMacStep "00:00:00:00:00:01"
    } 

    set index [string first ":" $SrcMacStep] 
    if {$index == -1} {
        set step ""
        for {set i 0} {$i <6} { incr i} {
            set mod1 [expr $SrcMacStep%255]
            if {$step ==""} {
                set step [format %x $mod1]
            } else {
                set step [format %x $mod1]:$step
            }
            set SrcMacStep [expr $SrcMacStep/255]
        }

        set SrcMacStep $step
    } 

    #Parse SrcMacStepMask parameter
    set index [lsearch $args -srcmacstepmask] 
    if {$index != -1} {
        set SrcMacStepMask [lindex $args [expr $index + 1]]
    } else  {
        set SrcMacStepMask "00:00:ff:ff:ff:ff"
    } 

    #Parse SrcIpv6 parameter
    set index [lsearch $args -srcipv6] 
    if {$index != -1} {
        set SrcIpv6 [lindex $args [expr $index + 1]]
         set IpVersion "ipv6"     
    } else  {
        set SrcIpv6 "2000::2"
    } 

    #Parse SrcIpv6Prefix parameter
    set index [lsearch $args -srcipv6prefix] 
    if {$index != -1} {
        set SrcIpv6Prefix [lindex $args [expr $index + 1]]
         set IpVersion "ipv6"     
    } else  {
        set SrcIpv6Prefix 64
    } 

    #Parse GwIpv6 parameter
    set index [lsearch $args -gwipv6] 
    if {$index != -1} {
        set GwIpv6 [lindex $args [expr $index + 1]]
        set IpVersion "ipv6"     
    } else  {
        set GwIpv6 "2000::1"
    } 
    
    #Parse SrcIpv6Step parameter
    set index [lsearch $args -srcipv6step] 
    if {$index != -1} {
        set SrcIpv6Step [lindex $args [expr $index + 1]]
        set IpVersion "ipv6" 

        set step ""
        set tmp_index [string first ":" $SrcIpv6Step] 
        if {$tmp_index == -1} {
            for {set i 0} {$i <8} { incr i} {
                set mod1 [expr $SrcIpv6Step%65535]
                if {$step ==""} {
                    set step [format %x $mod1]
                } else {
                    set step [format %x $mod1]:$step
                }
                set SrcIpv6Step [expr $SrcIpv6Step/65535]
            }
            set SrcIpv6Step $step
        }     
    } else  {
        set SrcIpv6Step "::1"
    }

    #Parse SrcIpv6StepMask parameter
    set index [lsearch $args -srcipv6stepmask] 
    if {$index != -1} {
        set SrcIpv6StepMask [lindex $args [expr $index + 1]]
         set IpVersion "ipv6"     
    } else  {
        set SrcIpv6StepMask "0000::FFFF:FFFF:FFFF:FFFF"
    }   
    
    #Crate Host object and configure parameters 
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]     
    }     
    set ProjHandle $::mainDefine::result  
    
    set hHost [stc::create Host -under $ProjHandle -Name $HostName -DeviceCount $HostNum -Active "TRUE"]
    set m_hostHandle($HostName) $hHost

    set hEth [stc::create EthIIIf -under $hHost]
    set Ether1 $hEth

    if {$SrcMacCount < $HostNum} {
        stc::config $hEth \
           -SourceMac $SrcMac \
           -SrcMacStep 00:00:00:00:00:00 \
           -SrcMacStepMask $SrcMacStepMask \
           -Active "TRUE"
    } else {
        stc::config $hEth \
           -SourceMac $SrcMac \
           -SrcMacStep $SrcMacStep \
           -SrcMacStepMask $SrcMacStepMask \
           -Active "TRUE"
    }

    if {$IpVersion == "ipv4"} {           
       set hIpv4 [stc::create Ipv4If -under $hHost]
       stc::config $hIpv4 \
           -Address $SrcIp \
           -AddrStep $SrcIpStep \
           -AddrStepMask $SrcIpStepMask \
           -PrefixLength $SrcIpPrefix \
           -Gateway $GwIp \
           -GatewayMac $GwMac \
           -ResolveGatewayMac "TRUE" \
           -Active "TRUE" 

  
       set ::mainDefine::objectName $m_portName 
       uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
       }
       set ifStack $::mainDefine::result

       if {($ifStack == "EII")||[isPortNameEqualToCreator $m_portName $this] == "TRUE" } {
            stc::config $hIpv4 -StackedOnEndpoint-targets $hEth 
        } elseif {$ifStack == "VlanOverEII"} { 
            #Get vlanId
            set ::mainDefine::objectName $this
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanTag]
             }
            set vlanId $::mainDefine::result

            #Get vlanPriority
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanPriority]
             }
            set vlanPriority $::mainDefine::result

            #Get vlanType
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanType]
             }
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]

            #Get QinQList
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_QinQList]
             }
            set QinQList $::mainDefine::result

            #Get vlanIf handle
            set ::mainDefine::objectName $this
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_hVlanIf]
             }
            set hVlanIf $::mainDefine::result

            if {$hVlanIf  == -1} {
                error "vlan subif must be created  before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanTag must be configured before ConfigRouter"
            }

            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hHost -TpId $vlanType -VlanId $vlanId -Priority $vlanPriority -IdStep "0" -IdList ""] 
               stc::config $hIpv4 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $Ether1      
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
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $Ether1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv4 -StackedOnEndpoint-targets $m_vlanIfList($i)
               }
            }
      }
   } else {
       set hIpv61 [stc::create Ipv6If -under $hHost]
       stc::config $hIpv61 \
           -Address $SrcIpv6 -AddrStep $SrcIpv6Step \
           -PrefixLength $SrcIpv6Prefix \
           -Gateway $GwIpv6 \
           -AddrStepMask $SrcIpv6StepMask
       set hIpv62 [stc::create Ipv6If -under $hHost]
       stc::config $hIpv62 -Address "fe80::" -AddrStep $SrcIpv6Step -PrefixLength $SrcIpv6Prefix -Gateway $GwIpv6 


       set ::mainDefine::objectName $m_portName 
       uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
       }
       set ifStack $::mainDefine::result

       if {($ifStack == "EII")||[isPortNameEqualToCreator $m_portName $this] == "TRUE" } {
            stc::config $hIpv61 -StackedOnEndpoint-targets $hEth
            stc::config $hIpv62 -StackedOnEndpoint-targets $hEth
        #Config the iinterface when IfStack == VlanOverEII
        } elseif {$ifStack == "VlanOverEII"} { 
         
            #Get vlanId
            set ::mainDefine::objectName $this
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanTag]
             }
            set vlanId $::mainDefine::result

            #Get vlanPriority
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanPriority]
             }
            set vlanPriority $::mainDefine::result

            #Get vlanType
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanType]
             }
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]

            #Get QinQList
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::objectName cget -m_QinQList] 
            }
           
            set QinQList $::mainDefine::result

            #Get the handle of vlanIf
            set ::mainDefine::objectName $this
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_hVlanIf]
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
               stc::config $hVlanIf -StackedOnEndpoint-targets $Ether1   
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
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $Ether1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv61 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv62 -StackedOnEndpoint-targets $m_vlanIfList($i)
               }
            }
      }
 
   }     
   
    #Build the relationship of the objects
    set ::mainDefine::objectName $this 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
    }     
    set hPort $::mainDefine::result
    
    stc::config $hHost -AffiliationPort-targets $hPort
    if {$IpVersion == "ipv4" } {    

        stc::config $hHost -TopLevelIf-targets "$hIpv4"
        stc::config $hHost -PrimaryIf-targets "$hIpv4"
    } else {
        stc::config $hHost -TopLevelIf-targets " $hIpv61 $hIpv62 "
        stc::config $hHost -PrimaryIf-targets " $hIpv61 $hIpv62 "
    }


    stc::apply
            
    debugPut "exit the proc of ETHPort::ConfigArpEntry" 
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: DeleteArpEntry
#Description: Delete Arp entry
#Input: 1. args:argument list, including
#              (1) -HostName Optional,name of the host
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body ETHPort::DeleteArpEntry {args}  {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of ETHPort::DeleteArpEntry"
    
    #Parse the parameters
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify HostName"
    }
    
    #Destroy host object
    if {[info exists m_hostHandle($HostName)]} {
        set hHost $m_hostHandle($HostName)      
        stc::delete $hHost
        debugPut "exit the proc of ETHPort::DeleteArpEntry" 
        return $::mainDefine::gSuccess   
    } else {
        error "The specified HostName parameter is not exist"
    }
    
    stc::apply
    
    debugPut "exit the proc of ETHPort::DeleteArpEntry"
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: StartArpd
#Description: Start ARP/Nd
#Input: 
#              (1) -HostName Optional,the name of the host to perform Arp/Nd
#              (2) -StreamName Optional,the name of the stream to perform Arp/Nd
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body ETHPort::StartArpd {args}  {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "Enter the proc of ETHPort::StartArpd"

    #Parse the parameters
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else {
        set HostName 0
    }
    
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
    } else {
        set StreamName 0
    }

    set ::mainDefine::objectName $this 
    uplevel 1 {         
         $::mainDefine::objectName  RealStartAllCaptures    
    }

    if {$HostName != 0} {
        if {[info exists m_hostHandle($HostName)]} {  
            stc::perform ArpNdStart -HandleList $m_hostHandle($HostName)       
        } else {
            error "The specified HostName $HostName does not exist ..."
        }
    } 
   
    if {$StreamName != 0} {
       
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set PortHandle $::mainDefine::result        
        
        set streamHandleList [stc::get $PortHandle -children-streamblock]
        foreach streamHandle [stc::get $PortHandle -children-streamblock] {
            if {$StreamName == [stc::get $streamHandle -Name ]} {
                stc::perform ArpNdStart -HandleList $streamHandle    
            }
        } 
    }            
    debugPut "Exit the proc of ETHPort::StartArpd" 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopArpd
#Description: Stop Arpd
#Input: 
#              (1) -HostName optional,name of the host to perfrom Arp/Nd
#              (2) -StreamName optional,name of stream to perform Arp/Nd
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body ETHPort::StopArpd {args}  {
  
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "Enter the proc of ETHPort::StopArpd"
    
    #Parse the parameters
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else {
        set HostName 0
    }
    
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
    } else {
        set StreamName 0
    }   
    
    if {$HostName != 0} {
        if {[info exists m_hostHandle($HostName)]} {
            stc::perform ArpNdStop -HandleList $m_hostHandle($HostName)       
        } else {
            error "The specified HostName $HostName does not exist ..."
        }
    }    
    if {$StreamName != 0} {

        set ::mainDefine::objectName $m_portName 
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set PortHandle $::mainDefine::result   
        
        set streamHandleList [stc::get $PortHandle -children-streamblock]
        foreach streamHandle [stc::get $PortHandle -children-streamblock] {
            if {$StreamName == [stc::get $streamHandle -Name ]} {
                stc::perform ArpNdStop -HandleList $streamHandle    
            }
        } 
    }           
    debugPut "Exit the proc of ETHPort::StopArpd" 
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: CreateLacpPort
#
#Description: 
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::CreateLacpPort  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::CreateLacpPort "

    set index [lsearch $args -lacpportgroup]
    if {$index != -1} {
       set lacpportgroup [lindex $args [expr $index + 1]]
        set m_lacpportgroup $lacpportgroup      
    } else {
        error " Please specify the LacpPortGroup of ETHPort::CreateLacpPort"
    }   
    
    set index [lsearch $args -actorkey]
    if {$index != -1} {
       set actorkey [lindex $args [expr $index + 1]]
       set m_actorkey $actorkey
    } else {
        set actorkey 1
    } 
    
    set index [lsearch $args -actorportpriority]
    if {$index != -1} {
       set actorportpriority [lindex $args [expr $index + 1]]
       set m_actorportpriority $actorportpriority 
    } else {
        set actorportpriority 1
    }

    set index [lsearch $args -lacpactiveity]
    if {$index != -1} {
       set lacpactiveity [lindex $args [expr $index + 1]]
       set m_lacpactiveity $lacpactiveity       
    } else {
        set lacpactiveity "ACTIVE"
    }    
               
     set index [lsearch $args -lacptimeout]
    if {$index != -1} {
       set lacptimeout [lindex $args [expr $index + 1]]
       set m_lacptimeout $lacptimeout        
    } else {
        set lacptimeout "LONG"
    }     

    #Create objects
    set hLacpPortConfig [stc::create "LacpPortConfig" \
        -under $m_hPort \
        -ActorPortPriority $actorportpriority \
        -ActorKey $actorkey \
        -LacpTimeout $lacptimeout \
        -LacpActivity $lacpactiveity \
        -EnableEventLog "FALSE" \
        -UsePartialBlockState "FALSE" ]
    set m_lacpPortConfig $hLacpPortConfig
   
    #Get the hLacpGroupConfig handle from LacpGroup object
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]     
    }     
    set chassisName $::mainDefine::result   
            
    set ::mainDefine::objectName $chassisName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_lacpGroupNameList]     
    }     
    set hLacpGroupNameList $::mainDefine::result 

    set ::mainDefine::objectName $chassisName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hLacpGroupList]     
    }     
    set hLacpGroupList $::mainDefine::result      
      
    set index [lsearch $hLacpGroupNameList $lacpportgroup]
    if {$index != -1} {
       set hLacpGroupConfig [lindex $hLacpGroupList $index]
    } 

    #Build the relationship between objects
    stc::config $m_lacpPortConfig -MemberOfLag-targets " $hLacpGroupConfig "

    set m_hLacpPortResults [stc::create LacpPortResults -under $hLacpPortConfig]

    set m_hResultDataSet [stc::create "ResultDataSet" -under $m_hProject ]
    set ResultQuery [stc::create "ResultQuery" \
            -under $m_hResultDataSet \
            -ResultRootList $m_hProject \
            -ConfigClassId LacpPortConfig \
            -ResultClassId LacpPortResults ]   
     
    set a [stc::perform ResultDataSetSubscribe -ResultDataSet $m_hResultDataSet]    

    stc::apply
    
    debugPut "exit the proc of ETHPort::CreateLacpPort "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: ConfigLacpPort
#
#Description: 
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::ConfigLacpPort  {args} {
  
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::ConfigLacpPort " 

     set index [lsearch $args -lacpportgroup]
    if {$index != -1} {
       set lacpportgroup [lindex $args [expr $index + 1]]
    } else {
        set lacpportgroup $m_lacpportgroup
    } 
        
    set index [lsearch $args -actorkey]
    if {$index != -1} {
       set actorkey [lindex $args [expr $index + 1]]
    } else {
        set actorkey $m_actorkey
    } 
    
    set index [lsearch $args -actorportpriority]
    if {$index != -1} {
       set actorportpriority [lindex $args [expr $index + 1]]
    } else {
        set actorportpriority $m_actorportpriority
    }

     set index [lsearch $args -lacpactiveity]
    if {$index != -1} {
       set lacpactiveity [lindex $args [expr $index + 1]]
    } else {
        set lacpactiveity $m_lacpactiveity
    }    
               
     set index [lsearch $args -lacptimeout]
    if {$index != -1} {
       set lacptimeout [lindex $args [expr $index + 1]]
    } else {
        set lacptimeout $m_lacptimeout
    }     

    #Config the parameters
    stc::config $m_lacpPortConfig \
        -ActorPortPriority $actorportpriority \
        -ActorKey $actorkey \
        -LacpTimeout $lacptimeout \
        -LacpActivity $lacpactiveity \
        -EnableEventLog "FALSE" \
        -UsePartialBlockState "FALSE" 

    #Get the hLacpGroupConfig from LacpGroup
  
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]     
    }     
    set chassisName $::mainDefine::result  

    set ::mainDefine::objectName $chassisName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_lacpGroupNameList]     
    }     
    set hLacpGroupNameList $::mainDefine::result  

    set ::mainDefine::objectName $chassisName 
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hLacpGroupList]     
    }     
    set hLacpGroupList $::mainDefine::result  
            
    set index [lsearch $hLacpGroupNameList $lacpportgroup]
    if {$index != -1} {
       set hLacpGroupConfig [lindex $hLacpGroupList $index]
    } 

    #Build the relationship between objects
    stc::config $m_lacpPortConfig -MemberOfLag-targets " $hLacpGroupConfig "
    
    stc::apply
    
    debugPut "exit the proc of ETHPort::ConfigLacpPort "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: GetLacpPort
#
#Description: 
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::GetLacpPort  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::GetLacpPort "    

    #Config the objects
    set LacpPortConfig ""
    lappend LacpPortConfig -lacpportgroup
    lappend LacpPortConfig $m_lacpportgroup 
    lappend LacpPortConfig -actorkey
    lappend LacpPortConfig [stc::get $m_lacpPortConfig -ActorKey]
    lappend LacpPortConfig -actorportpriority
    lappend LacpPortConfig [stc::get $m_lacpPortConfig -ActorPortPriority]
    lappend LacpPortConfig -lacpactiveity
    lappend LacpPortConfig [stc::get $m_lacpPortConfig -LacpActivity]
    lappend LacpPortConfig -lacptimeout
    lappend LacpPortConfig [stc::get $m_lacpPortConfig -LacpTimeout]        
    
    #Get the result according to the input parameter
    if { $args == "" } {
        debugPut "exit the proc of IsisRouter::GetLacpPort" 
        return $LacpPortConfig
    } else {
        array set arr $LacpPortConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
        debugPut "exit the proc of ETHPort::GetLacpPort "
        return $::mainDefine::gSuccess        
    }      
}

###########################################################################
#APIName: DeleteLacpPort
#
#Description: 
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::DeleteLacpPort  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::DeleteLacpPort "

    #Delete the objects
    stc::delete $m_lacpPortConfig
    stc::delete $m_hResultDataSet
    
    stc::apply
    
    debugPut "exit the proc of ETHPort::DeleteLacpPort "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: StartLacpPort
#
#Description: Start Lacp port，begin Lacp Emulation
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::StartLacpPort  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::StartLacpPort "
 
    stc::perform ProtocolStart -ProtocolList $m_lacpPortConfig
    
    debugPut "exit the proc of ETHPort::StartLacpPort "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: StopLacpPort
#
#Description: Stop Lacp Emulation
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::StopLacpPort  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::StopLacpPort "
 
    stc::perform ProtocolStop -ProtocolList $m_lacpPortConfig
    
    debugPut "exit the proc of ETHPort::StopLacpPort "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: StopLacpPdu
#
#Description: Stop Lacp PDU
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::StopLacpPdu  {args} {
         
    debugPut "enter the proc of ETHPort::StopLacpPdu "

    stc::perform LacpStopPdus -LacpList $m_lacpPortConfig
    stc::apply
    
    debugPut "exit the proc of ETHPort::StopLacpPdu "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: ResumeLacpPdu
#
#Description: Resume Lacp PDU
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body ETHPort::ResumeLacpPdu  {args} {
         
    debugPut "enter the proc of ETHPort::ResumeLacpPdu "

    stc::perform LacpResumePdus -LacpList $m_lacpPortConfig
    stc::apply
    
    debugPut "exit the proc of ETHPort::ResumeLacpPdu "
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: GetLacpPortStats
#
#Description: Get Lacp Port stats
#
#Input:None 
#
#Output: Statistics of Lacp Port
#
#Coded by: David.Wu
#############################################################################

::itcl::body ETHPort::GetLacpPortStats {{args ""}} {
    set list ""
if {[catch { 
   
    debugPut "enter the proc of ETHPort::GetLacpPortStats"
        
    stc::perform RefreshResultView -ResultDataSet $m_hResultDataSet 
    set waitTime 2000
    after $waitTime

    #Get statistics of lacp port
    set list  [stc::get $m_hLacpPortResults]
    set list [ConvertAttrToLowerCase $list] 
    if {$args == ""} {
        debugPut "exit the proc of ETHPort::GetLacpPortStats"
        #If no parameter specified, return the whole list
        return $list
    } else {
        #If specified the attr, then return the value
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
        debugPut "exit the proc of ETHPort::GetLacpPortStats"
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
