###########################################################################
#                                                                        
#  File Name£ºDHCPv4Protocol.tcl                                                                            
#                  
#  Description£ºDefinition of DHCPv4Server, Client, Relay class and its methods
# 
#  Author£º Shi Yunzhi
#
#  Create Time:  2009.11.02
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

############################################################################
#APIName: DHCPConfigVlanIfs
#
#Description: Config DHCP Vlan If according to input parameter
#
#Input:   args: ConfigRouter parameters
#         m_hHost: DHCP Host handle
#         Other Vlan parameters:
#         m_upLayerIf: Upper layer interface handle
#         m_hEthIIIf: ETH interface handle
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc DHCPConfigVlanIfs {args m_hHost m_deviceCount m_vlanType1 m_vlanId1 m_vlanModifier1 m_vlanCount1 \
                         m_vlanType2 m_vlanId2 m_vlanModifier2 m_vlanCount2 m_upLayerIf m_hEthIIIf} {
    set loop 0
    while {[llength $args] == 1 && $loop < 4} {
       set args [eval subst $args ]
       set loop [expr $loop + 1]
    }

    set hVlanList [stc::get $m_hHost -children-VlanIf] 
    if {$hVlanList != ""} {
        #Already configured VLANIF
        set firstVlanIf [lindex $hVlanList 0]

        if {$m_vlanModifier1 == 0} {
            set count1 1
        } else {
            set count1 $m_vlanCount1   
        }

        if {$count1 == 1} {
            set recycle_count1 0
        } else {
            set recycle_count1 $m_vlanCount1
        }

        if {$m_vlanModifier2 == 0} {
            set count2 1
        } else {
            set count2 $m_vlanCount2
        }

        if {$count2 == 1} {
            set recycle_count2 0
        } else {
            set recycle_count2 $m_vlanCount2
        }

        if {$m_vlanType1 != ""} {
            set hexFlag [string range $m_vlanType1 0 1]
            set vlanType1 $m_vlanType1
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType1 0x$m_vlanType1
            }
            set vlanType1 [format %d $vlanType1]
            stc::config $firstVlanIf -TpId $vlanType1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
        }
        if {$m_vlanId1 != ""} {            
            stc::config $firstVlanIf -VlanId $m_vlanId1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
        }
        if {$m_vlanModifier1 != ""} {
            stc::config $firstVlanIf -IdStep $m_vlanModifier1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
        }
        
        set secondVlanIf [lindex $hVlanList 1]
        if {$secondVlanIf != ""} {
            if {$m_vlanType2 != ""} {
                set hexFlag [string range $m_vlanType2 0 1]
                set vlanType2 $m_vlanType2
                if {[string tolower $hexFlag] != "0x" } {
                    set vlanType2 0x$m_vlanType2
                }
                set vlanType2 [format %d $vlanType2]
                stc::config $secondVlanIf -TpId $vlanType2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
            }
            if {$m_vlanId2 != ""} {                
                stc::config $secondVlanIf -VlanId $m_vlanId2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
            }
            if {$m_vlanModifier2 != ""} {
                stc::config $secondVlanIf -IdStep $m_vlanModifier2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
            }
        } elseif {$m_vlanType2 != "" || $m_vlanId2 != "" || $m_vlanModifier2 != ""} {
            set secondVlanIf [stc::create "VlanIf" -under $m_hHost -IdList "" -IdStep 0 ]
            if {$m_vlanType2 != ""} {
                set hexFlag [string range $m_vlanType2 0 1]
                set vlanType2 $m_vlanType2
                if {[string tolower $hexFlag] != "0x" } {
                    set vlanType2 0x$m_vlanType2
                }
                set vlanType2 [format %d $vlanType2]
                stc::config $secondVlanIf -TpId $vlanType2 -IfRecycleCount $count2 -IfCountPerLowerIf $count2
            }
            if {$m_vlanId2 != ""} {       
                stc::config $secondVlanIf -VlanId $m_vlanId2 -IfRecycleCount $count2 -IfCountPerLowerIf $count2
            }
            if {$m_vlanModifier2 != ""} {
                stc::config $secondVlanIf -IdStep $m_vlanModifier2 -IfRecycleCount $count2 -IfCountPerLowerIf $count2
            }

            stc::config $secondVlanIf -StackedOnEndpoint-targets $firstVlanIf
            stc::config $m_upLayerIf -StackedOnEndpoint-targets $secondVlanIf
        }
    } else {
        set index [lsearch $args "-vlan*"]
        if {$index != -1} {
            if {$m_vlanModifier1 == 0} {
                set count1 1
            } else {
                set count1 $m_vlanCount1 
            }

            if {$count1 == 1} {
                set recycle_count1 0
            } else {
                set recycle_count1 $m_vlanCount1
            }

            if {$m_vlanModifier2 == 0} {
                set count2 1
            } else {
                set count2 $m_vlanCount2  
            }

            if {$count2 == 1} {
                set recycle_count2 0
            } else {
                set recycle_count2 $m_vlanCount2
            }

            #If VLANIF was not created and ConfigRouter has associated parameter,we need create it manually  
            set firstVlanIf [stc::create "VlanIf" -under $m_hHost -IdList "" -IdStep 0 ]
            if {$m_vlanType1 != ""} {
                set hexFlag [string range $m_vlanType1 0 1]
                set vlanType1 $m_vlanType1
                if {[string tolower $hexFlag] != "0x" } {
                    set vlanType1 0x$m_vlanType1
                }
                set vlanType1 [format %d $vlanType1]
                stc::config $firstVlanIf -TpId $vlanType1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
            }

            if {$m_vlanId1 != ""} {            
                stc::config $firstVlanIf -VlanId $m_vlanId1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
            }
            if {$m_vlanModifier1 != ""} {
                stc::config $firstVlanIf -IdStep $m_vlanModifier1 -IfRecycleCount $recycle_count1 -IfCountPerLowerIf $count1
            }

            stc::config $firstVlanIf -StackedOnEndpoint-targets $m_hEthIIIf
            stc::config $m_upLayerIf -StackedOnEndpoint-targets $firstVlanIf

            if {$m_vlanType2 != "" || $m_vlanId2 != "" || $m_vlanModifier2 != ""} {
                set secondVlanIf [stc::create "VlanIf" -under $m_hHost -IdList "" -IdStep 0 ]
                if {$m_vlanType2 != ""} {
                    set hexFlag [string range $m_vlanType2 0 1]
                    set vlanType2 $m_vlanType2
                    if {[string tolower $hexFlag] != "0x" } {
                        set vlanType2 0x$m_vlanType2
                    }
                    set vlanType2 [format %d $vlanType2]
                    stc::config $secondVlanIf -TpId $vlanType2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
                }
                if {$m_vlanId2 != ""} {       
                    stc::config $secondVlanIf -VlanId $m_vlanId2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
                }
                if {$m_vlanModifier2 != ""} {
                    stc::config $secondVlanIf -IdStep $m_vlanModifier2 -IfRecycleCount $recycle_count2 -IfCountPerLowerIf $count2
                }

                stc::config $secondVlanIf -StackedOnEndpoint-targets $firstVlanIf
                stc::config $m_upLayerIf -StackedOnEndpoint-targets $secondVlanIf
            }
        } 
    }
}

::itcl::class DHCPv4Server {
    #Variables
    public variable m_hPort ""
    public variable m_hProject ""
    public variable m_portName ""
    public variable m_hostName ""    
    public variable m_hHost  ""
    public variable m_hRouter ""
    public variable m_hDhcpSrvCfg ""
    public variable m_hDhcpSrvPoolCfg ""
    public variable m_hDhcpSrvOfferOption ""
    public variable m_hDhcpSrvAckOption ""
    public variable m_hIpv4 ""
    public variable m_hEthIIIf ""
    public variable m_hDhcpSrvRelayAgentPoolCfg

    #Dhcp Server configurations
    public variable m_deviceCount 1
    public variable m_testerIpAddr  "192.0.0.2"
    public variable m_localMac    "00:00:00:11:01:01"
    public variable m_poolName    ""
    public variable m_flagGateway false
    public variable m_ipv4Gateway "192.0.0.1"
    public variable m_leaseTime   3600
    public variable m_poolStart   "192.0.0.1"
    public variable m_poolNum     "254"
    public variable m_poolModifier "0.0.0.1"
    public variable m_prefixLen   24
    public variable m_dhcpOfferOption 0
    public variable m_dhcpAckOption   0
    public variable m_active    "true"
    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1   1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2   1
    public variable m_connectRate 100
    public variable m_disconnectRate 100
    public variable m_retransmitNum 4
    public variable m_portType "ethernet"
    
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv4 portType} {    
        set m_hPort $hPort
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv4 $hipv4
        set m_portType $portType
        
        lappend ::mainDefine::gObjectNameList $this

        #Create DHCPv4 Server,block,defaultPool
        set m_hDhcpSrvCfg [stc::create "Dhcpv4ServerConfig" -under $m_hHost -Name $m_hostName ]
        set m_hDhcpSrvPoolCfg [lindex [stc::get $m_hDhcpSrvCfg -children-Dhcpv4ServerDefaultPoolConfig] 0]        

        #Create Dhcpv4ServerMsgOption handle
        set m_hDhcpSrvOfferOption [stc::create "Dhcpv4ServerMsgOption" -under $m_hDhcpSrvCfg -MsgType OFFER ]       
        #Create Dhcpv4ServerMsgOption handle
        set m_hDhcpSrvAckOption [stc::create "Dhcpv4ServerMsgOption" -under $m_hDhcpSrvCfg -MsgType ACK]
    
        #Get Ethernet interface
        #added by yuanfen 8.11 2011
        if {$m_portType == "ethernet"} {
            set EthIIIf1 [stc::get $hHost -children-EthIIIf]
            set m_hMacAddress $EthIIIf1    
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hHost -children-HdlcIf]]} {
                set EthIIIf1 [stc::get $hHost -children-HdlcIf]
            } else {
                set EthIIIf1 [stc::get $hHost -children-PppIf]
            }
        } 
        
        set m_hEthIIIf $EthIIIf1
         
        set hVlanList [stc::get $hHost -children-VlanIf]
        if {$hVlanList != ""} {
            foreach vlanIf $hVlanList {
                stc::config $vlanIf -IdStep "0" -IdList ""
            }
        } 

        #Build the relationships between objects
        stc::config $m_hDhcpSrvCfg -UsesIf-targets $m_hIpv4       
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]              
    }

    #Methods
    public method SetSession
    public method RetrieveRouter
    public method Enable
    public method Disable
    public method ForceRenew
    public method Reboot
    public method ClearStats
    public method RetrieveRouterStats
}

#DHCP client and relay Class
::itcl::class DHCPv4Client {
    #Variables
    public variable m_hPort ""
    public variable m_hProject ""
    #DHCP client or DHCP relay
    public variable m_blockType ""
    public variable m_portName ""
    public variable m_hostName ""
    public variable m_hHost ""
    public variable m_hRouter ""
    public variable m_hDhcpBlkCfg ""    
    public variable m_hIpv4 ""
    public variable m_hEthIIIf ""
    public variable m_awdtimer 5000
    public variable m_wadtimer 5000

    #Definition of Dhcp client configurations
    public variable m_hDiscoveryOptionArr 
    public variable m_hRequestOptionArr 
    public variable m_discoveryListCount 0
    public variable m_requestListCount 0
    
    public variable m_deviceCount 1
    public variable m_relayAgentIpAddr ""
    public variable m_serverIpAddr ""
    public variable m_localAgentMac "00:00:00:15:01:01"
    public variable m_clientLocalMac "00:00:00:11:01:01"
    public variable m_clientLocalMacModifier "00:00:00:00:00:01"
    public variable m_poolName ""
    public variable m_flagGateway false  
    public variable m_ipv4Gateway ""
    public variable m_flagBroadcast true
    public variable m_autoRetryNum 1
    public variable m_flagRelayAgentOption false
    public variable m_circuitId ""
    public variable m_remoteId ""
    public variable m_discoveryOptionType ""
    public variable m_discoveryOptionValue ""
    public variable m_requestOptionType ""
    public variable m_requestOptionValue ""
    public variable m_active    "true"
    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1   1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2   1
    public variable m_connectRate 100
    public variable m_disconnectRate 100
    public variable m_retransmitNum 4
    public variable m_flagRelayAgentCircuitID "FALSE"
    public variable m_flagRelayAgentRemoteID "FALSE"  
    public variable m_relayAgentPoolStart "193.169.1.100"
    public variable m_portType "ethernet"
 
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv4 blockType portType} {
    
        set m_hPort $hPort
        set m_blockType $blockType
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv4 $hipv4
        set m_portType $portType
    
        lappend ::mainDefine::gObjectNameList $this

        #Create DHCPv4 block
        set m_hDhcpBlkCfg [stc::create "Dhcpv4BlockConfig"  -under $m_hHost -Name $m_hostName ]        
        
        #Get Ethernet interface handle
        #added by yuanfen 8.11 2011
        if {$m_portType == "ethernet"} {
            set EthIIIf1 [stc::get $hHost -children-EthIIIf]
            set m_hMacAddress $EthIIIf1    
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hHost -children-HdlcIf]]} {
                set EthIIIf1 [stc::get $hHost -children-HdlcIf]
            } else {
                set EthIIIf1 [stc::get $hHost -children-PppIf]
            }
        }     
       
        set m_hEthIIIf $EthIIIf1
         
        set hVlanList [stc::get $hHost -children-VlanIf]
        if {$hVlanList != ""} {
            foreach vlanIf $hVlanList {
                stc::config $vlanIf -IdStep "0" -IdList ""
            }
        } 

        #Build the relationship between objects
        stc::config $m_hDhcpBlkCfg -UsesIf-targets $m_hIpv4       
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]              
    }

    #Methods
    public method SetSession
    public method RetrieveRouter
    public method Enable
    public method Disable
    public method Bind
    public method Release
    public method Renew
    public method Abort
    public method Reset
    public method Reboot
    public method Decline
    public method Inform
    public method RetryUnbound
    public method ResetMeasurement
    public method SetFlap
    public method StartFlap
    public method StopFlap
    public method ClearStats
    public method RetrieveRouterStats
    public method RetrieveHostState
}


############################################################################
#APIName: SetSession
#Description: Config DHCPv4 Server Router
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::SetSession {args} {
   
    debugPut "enter the proc of DHCPv4Server::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    #Parse Count parameter
    set index [lsearch $args -count]
    if {$index != -1} {
        set DeviceCount [lindex $args [expr $index + 1]]
        set m_deviceCount $DeviceCount
    } 
    #Parse TesterIpAddr parameter
    set index [lsearch $args -testeripaddr]
    if {$index != -1} {
        set TesterIpAddr [lindex $args [expr $index + 1]]
        set m_testerIpAddr $TesterIpAddr
    } else {
        set index [lsearch $args -testipaddr]
        if {$index != -1} {
            set TesterIpAddr [lindex $args [expr $index + 1]]
            set m_testerIpAddr $TesterIpAddr
        }  
    }

    #Parse LocalMac parameter
    set index [lsearch $args -localmac]
    if {$index != -1} {
        set LocalMac [lindex $args [expr $index + 1]]
        set m_localMac $LocalMac
    } 
    #Parse PoolName parameter
    set index [lsearch $args -poolname]
    if {$index != -1} {
        set PoolName [lindex $args [expr $index + 1]]
        set m_poolName $PoolName
    } 
    #Parse FlagGateway parameter
    set index [lsearch $args -flaggateway]
    if {$index != -1} {
        set FlagGateway [lindex $args [expr $index + 1]]
        set m_flagGateway $FlagGateway
        set m_flagGateway [string tolower $m_flagGateway]
    } 
    #Parse Ipv4Gateway parameter
    set index [lsearch $args -ipv4gateway]
    if {$index != -1} {
        set Ipv4Gateway [lindex $args [expr $index + 1]]
        set m_ipv4Gateway $Ipv4Gateway
    } 
     
    #Parse LeaseTime parameter
    set index [lsearch $args -leasetime]
    if {$index != -1} {
        set LeaseTime [lindex $args [expr $index + 1]]
        set m_leaseTime $LeaseTime
    } 
    
    #Parse PoolStart parameter
    set index [lsearch $args -poolstart]
    if {$index != -1} {
        set PoolStart [lindex $args [expr $index + 1]]
        set m_poolStart $PoolStart
    } 
    #Parse PoolNum parameter
    set index [lsearch $args -poolnum]
    if {$index != -1} {
        set PoolNum [lindex $args [expr $index + 1]]
        set m_poolNum $PoolNum
    } 
    
    #Parse PoolModifier parameter
    set index [lsearch $args -poolmodifier]
    if {$index != -1} {
        set PoolModifier [lindex $args [expr $index + 1]]
        set m_poolModifier $PoolModifier
        set m_poolModifier [ipaddr2DotDec $m_poolModifier]
    } 

    #Parse PrefixLen parameter
    set index [lsearch $args -prefixlen]
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
        set m_prefixLen $PrefixLen
    } 
    #Parse DhcpOfferOption parameter
    set index [lsearch $args -dhcpofferoption]
    if {$index != -1} {
        set DhcpOfferOption [lindex $args [expr $index + 1]]
        set m_dhcpOfferOption $DhcpOfferOption
    } 
    
    #Parse DhcpAckOption parameter
    set index [lsearch $args -dhcpackoption]
    if {$index != -1} {
        set DhcpAckOption [lindex $args [expr $index + 1]]
        set m_dhcpAckOption $DhcpAckOption
    } 
    #Parse Active parameter
    set index [lsearch $args -active]
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]       
        set m_active $Active
    }
    #Parse VlanType1 parameter
    set index [lsearch $args -vlantype1]
    if {$index != -1} {
        set VlanType1 [lindex $args [expr $index + 1]]      
        set m_vlanType1 $VlanType1
    }
    #Parse VlanId1 parameter
    set index [lsearch $args -vlanid1]
    if {$index != -1} {
        set VlanId1 [lindex $args [expr $index + 1]]      
        set m_vlanId1 $VlanId1
    }
    #Parse VlanModifier1 parameter
    set index [lsearch $args -vlanidmodifier1]
    if {$index != -1} {
        set VlanModifier1 [lindex $args [expr $index + 1]]      
        set m_vlanModifier1 $VlanModifier1
    } else {
        set index [lsearch $args -vlanmodifier1]
        if {$index != -1} {
            set VlanModifier1 [lindex $args [expr $index + 1]]      
            set m_vlanModifier1 $VlanModifier1
        } 
    } 

    #Parse VlanidCount1 parameter
    set index [lsearch $args -vlanidcount1]
    if {$index != -1} {
        set VlanCount1 [lindex $args [expr $index + 1]]      
        set m_vlanCount1 $VlanCount1
    }

    #Parse VlanType2 parameter
    set index [lsearch $args -vlantype2]
    if {$index != -1} {
        set VlanType2 [lindex $args [expr $index + 1]]      
        set m_vlanType2 $VlanType2
    }
    #Parse VlanId2 parameter
    set index [lsearch $args -vlanid2]
    if {$index != -1} {
        set VlanId2 [lindex $args [expr $index + 1]]      
        set m_vlanId2 $VlanId2
    }
    #Parse VlanModifier2 parameter
    set index [lsearch $args -vlanidmodifier2]
    if {$index != -1} {
        set VlanModifier2 [lindex $args [expr $index + 1]]      
        set m_vlanModifier2 $VlanModifier2
    } else {
        set index [lsearch $args -vlanmodifier2]
        if {$index != -1} {
            set VlanModifier2 [lindex $args [expr $index + 1]]      
            set m_vlanModifier2 $VlanModifier2
        } 
    } 

    #Parse VlanIdCount2 parameter
    set index [lsearch $args -vlanidcount2]
    if {$index != -1} {
        set VlanCount2 [lindex $args [expr $index + 1]]      
        set m_vlanCount2 $VlanCount2
    }

    #Parse ConnectRate parameter
    set index [lsearch $args -connectrate]
    if {$index != -1} {
        set ConnectRate [lindex $args [expr $index + 1]]      
        set m_connectRate $ConnectRate
    }
    #Parse DisconnectRate parameter
    set index [lsearch $args -disconnectrate]
    if {$index != -1} {
        set DisconnectRate [lindex $args [expr $index + 1]]      
        set m_disconnectRate $DisconnectRate
    }
    #Parse RetransmitNum parameter
    set index [lsearch $args -retransmitnum]
    if {$index != -1} {
        set RetransmitNum [lindex $args [expr $index + 1]]      
        set m_retransmitNum $RetransmitNum
    }

    set connectRate $m_connectRate
    set disconnectRate $m_disconnectRate
    
    #Config DHCPv4 Server
    set hHost $m_hHost
    set hDhcpSrvCfg $m_hDhcpSrvCfg
    
    set hIpv4If $m_hIpv4
    set hEthIIIf $m_hEthIIIf

    set hDhcpPortCfg [stc::get $m_hPort -children-Dhcpv4PortConfig ]
    stc::config $hDhcpPortCfg -RequestRate $connectRate -ReleaseRate $disconnectRate -RetryCount $m_retransmitNum
    
    stc::config $hHost -DeviceCount $m_deviceCount  
    
    if {$m_portType == "ethernet"} {
        stc::config $hEthIIIf -SourceMac $m_localMac
    }

    #Config DHCP VLAN interface£¨support 2 VLANs£©
    DHCPConfigVlanIfs $args $hHost $m_deviceCount $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1 \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2 $hIpv4If $hEthIIIf 
    
    #Config tester IP address and information associated with gateway
    stc::config $hIpv4If -Address $m_testerIpAddr  -PrefixLength $m_prefixLen
    
    if {$m_flagGateway == true} {
        if {$m_ipv4Gateway !=""} {
            stc::config $hIpv4If -Gateway $m_ipv4Gateway
        } else {
           set Ipv4Gateway [GetGatewayIp $m_testerIpAddr]
           stc::config $hIpv4If -Gateway $Ipv4Gateway
        }
    } else {
       set Ipv4Gateway [GetGatewayIp $m_testerIpAddr]
       stc::config $hIpv4If -Gateway $Ipv4Gateway
    }

    stc::config $hDhcpSrvCfg -LeaseTime $m_leaseTime -Active $m_active

    #Configure server pool address and Relay Agent pool. If m_testerIpAddr and m_poolStart in the same
    #network, then use server pool address; otherwise will use Relay Agent pool
    
    set serverIpNetmask [ipnetmask $m_testerIpAddr $m_prefixLen]
    set poolIpNetmask [ipnetmask $m_poolStart $m_prefixLen]
    if {$serverIpNetmask == $poolIpNetmask} { 
        debugPut "Config server default address pool ..."
        set hDhcpSrvPoolCfg $m_hDhcpSrvPoolCfg 
        stc::config $hDhcpSrvPoolCfg -StartIpList $m_poolStart \
                     -PrefixLength $m_prefixLen \
                     -HostAddrStep $m_poolModifier -LimitHostAddrCount "TRUE" \
                     -HostAddrCount $m_poolNum

        if {[info exists PoolName]} {
            stc::config $hDhcpSrvPoolCfg -Name $PoolName
        }    
    } else {
        if {[info exists PoolName] || $m_poolName != ""} {
            debugPut "Config relay agent address pool, pool name is:$m_poolName ..."
            if {[info exists m_hDhcpSrvRelayAgentPoolCfg($m_poolName)]} { 
                set hDhcpSrvPoolCfg $m_hDhcpSrvRelayAgentPoolCfg($m_poolName)
                stc::config $hDhcpSrvPoolCfg -StartIpList $m_poolStart -PrefixLength $m_prefixLen \
                       -HostAddrStep $m_poolModifier -LimitHostAddrCount "TRUE" \
                       -HostAddrCount $m_poolNum
            } else {
                set hDhcpSrvPoolCfg [stc::create "Dhcpv4ServerPoolConfig" \
                     -under $hDhcpSrvCfg \
                     -RouterList "" -DomainNameServerList "" \
                     -StartIpList $m_poolStart -PrefixLength $m_prefixLen \
                     -HostAddrStep $m_poolModifier -LimitHostAddrCount "TRUE" \
                     -HostAddrCount $m_poolNum -Name $m_poolName]
                set m_hDhcpSrvRelayAgentPoolCfg($m_poolName) $hDhcpSrvPoolCfg
            }
        } 

        set defaultPoolStart [stc::get $m_hDhcpSrvPoolCfg -StartIpList]
        set defaultPoolIpNetmask [ipnetmask $defaultPoolStart $m_prefixLen]
        if {$defaultPoolIpNetmask != $serverIpNetmask} {
            set testIpAddrDec [ipaddr2dec $m_testerIpAddr]
            set testIpAddrDec [expr $testIpAddrDec + 1]
            set poolStartIpAddr [dec2ipaddr $testIpAddrDec]
            stc::config $m_hDhcpSrvPoolCfg -StartIpList $poolStartIpAddr
        }
    } 
    
    #Configure the pool for stream bounding
    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv4
    }    
       
    #Configure Dhcpv4ServerMsgOption handle
    stc::config $m_hDhcpSrvOfferOption -OptionType 182 -Payload $m_dhcpOfferOption       
    #Configure Dhcpv4ServerMsgOption handle
    stc::config $m_hDhcpSrvAckOption -OptionType 152 -Payload $m_dhcpAckOption    

    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of DHCPv4Server::SetSession"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: RetrieveRouter
#Description: Get DHCPv4 Server Router atribute
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::RetrieveRouter {args} {

    debugPut "enter the proc of DHCPv4Server::RetrieveRouter"    
    set args [ConvertAttrToLowerCase $args]

    set DhcpGetRouterResult ""
    lappend DhcpGetRouterResult -state
    set state [stc::get $m_hDhcpSrvCfg -ServerState]
    if {[string tolower $state ] == "up"} {
        set state "running"
    } else {
        set state "idle"
    }

    lappend DhcpGetRouterResult $state
    lappend DhcpGetRouterResult -encapsulation
    lappend DhcpGetRouterResult EthernetII 
    if {$m_portType == "ethernet"} {
        lappend DhcpGetRouterResult -localmac
        lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
    }
    lappend DhcpGetRouterResult -poolname
    lappend DhcpGetRouterResult $m_poolName
    lappend DhcpGetRouterResult -testeripaddr
    lappend DhcpGetRouterResult [stc::get $m_hIpv4 -Address]
    lappend DhcpGetRouterResult -flaggateway
    lappend DhcpGetRouterResult $m_flagGateway 
    lappend DhcpGetRouterResult -ipv4gateway
    lappend DhcpGetRouterResult [stc::get $m_hIpv4 -Gateway]
    lappend DhcpGetRouterResult -leasetime
    lappend DhcpGetRouterResult [stc::get $m_hDhcpSrvCfg -LeaseTime]
    lappend DhcpGetRouterResult -active
    set active [stc::get $m_hDhcpSrvCfg -Active]
    set active [string tolower $active]
    if {$active == true} {
        set active Enable
    } elseif {$active == false} {
        set active Disable
    }
    lappend DhcpGetRouterResult $active
    lappend DhcpGetRouterResult -poolstart
    lappend DhcpGetRouterResult [stc::get $m_hDhcpSrvPoolCfg -StartIpList]
    lappend DhcpGetRouterResult -poolnum
    lappend DhcpGetRouterResult [stc::get $m_hDhcpSrvPoolCfg -HostAddrCount]
    lappend DhcpGetRouterResult -poolmodifier
    set PoolModifier [stc::get $m_hDhcpSrvPoolCfg -HostAddrStep]
    set PoolModifier [ipaddr2dec $PoolModifier]
    lappend DhcpGetRouterResult $PoolModifier
    lappend DhcpGetRouterResult -dhcpOfferoption
    lappend DhcpGetRouterResult [stc::get $m_hDhcpSrvOfferOption -Payload]
    lappend DhcpGetRouterResult -dhcpackoption
    lappend DhcpGetRouterResult [stc::get $m_hDhcpSrvAckOption -Payload]
    set hDhcpPortCfg [stc::get $m_hPort -children-Dhcpv4PortConfig ]
    lappend DhcpGetRouterResult -connectrate 
    set rate [stc::get $hDhcpPortCfg -RequestRate]
    lappend DhcpGetRouterResult $rate
    lappend DhcpGetRouterResult -disconnectrate  
    set rate [stc::get $hDhcpPortCfg -ReleaseRate ]
    lappend DhcpGetRouterResult $rate
    lappend DhcpGetRouterResult -retransmitnum 
    lappend DhcpGetRouterResult [stc::get $hDhcpPortCfg -RetryCount ]

    lappend DhcpGetRouterResult -vlantype1
    lappend DhcpGetRouterResult $m_vlanType1
    lappend DhcpGetRouterResult -vlanid1
    lappend DhcpGetRouterResult $m_vlanId1
    lappend DhcpGetRouterResult -vlanidmodifier1
    lappend DhcpGetRouterResult $m_vlanModifier1
    lappend DhcpGetRouterResult -vlanidcount1
    lappend DhcpGetRouterResult $m_vlanCount1

    lappend DhcpGetRouterResult -vlantype2
    lappend DhcpGetRouterResult $m_vlanType2
    lappend DhcpGetRouterResult -vlanid2
    lappend DhcpGetRouterResult $m_vlanId2
    lappend DhcpGetRouterResult -vlanidmodifier2
    lappend DhcpGetRouterResult $m_vlanModifier2
    lappend DhcpGetRouterResult -vlanidcount2
    lappend DhcpGetRouterResult $m_vlanCount2

    if { $args == "" } {
        debugPut "exit the proc of DHCPv4Server::RetrieveRouter" 
        return $DhcpGetRouterResult
    } else {     
        array set arr $DhcpGetRouterResult
#        parray arr
        foreach {name valueVar}  $args {   
            if {[array names arr $name] != ""} {
                set ::mainDefine::gAttrValue $arr($name)

                set ::mainDefine::gVar $valueVar
                uplevel 1 {
                    set $::mainDefine::gVar $::mainDefine::gAttrValue
                }          
            } else {
                puts "Info: $name parameter is not supported by Spirent TestCenter."
            }
        }        
        debugPut "exit the proc of DHCPv4Server::RetrieveRouter"   
        return $::mainDefine::gSuccess     
    }    
}

############################################################################
#APIName: Enable
#Description: Enable DHCP server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::Enable {args} {
    
    debugPut "enter the proc of DHCPv4Server::Enable"    

    #Enable DHCPv4 Server
    stc::config $m_hHost -Active TRUE   
    stc::config $m_hDhcpSrvCfg -Active TRUE
    #Apply the configuration to the chassis
    ApplyValidationCheck
    stc::perform DeviceStart -DeviceList $m_hHost    

    debugPut "exit the proc of DHCPv4Server::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Disable DHCP server 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::Disable {args} {
  
    debugPut "enter the proc of DHCPv4Server::Disable"    

    #Stop DHCPv4 Server
    stc::perform DeviceStop -DeviceList $m_hHost
    stc::config $m_hHost -Active FALSE   
    stc::config $m_hDhcpSrvCfg -Active FALSE

    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of DHCPv4Server::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: ForceRenew
#Description: Send FORCERENEW package£¬and force all the DHCP clients to request ip address
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::ForceRenew {args} {
   
    debugPut "enter the proc of DHCPv4Server::ForceRenew"    

    #Enable DHCPv4 Server
    stc::config $m_hHost -Active TRUE   
    stc::config $m_hDhcpSrvCfg -Active FALSE

    #Apply the configuratioin to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of DHCPv4Server::ForceRenew"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Reboot
#Description: Reboot DHCP server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::Reboot {args} {
  
    debugPut "enter the proc of DHCPv4Server::Reboot"    

    #Reboot DHCPv4 Server
    stc::perform Dhcpv4StopServer -ServerList $m_hHost
    after 2000
    stc::perform Dhcpv4StartServer -ServerList $m_hHost

    debugPut "exit the proc of DHCPv4Server::Reboot"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: ClearStats
#Description: Clear DHCP statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::ClearStats {args} {
    
    debugPut "enter the proc of DHCPv4Server::ClearStats"    

    #Clear DHCPv4 statistics
    stc::perform ResultsClearAllProtocol    

    debugPut "exit the proc of DHCPv4Server::ClearStats"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Get DHCP server statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Server::RetrieveRouterStats {args} {
    
    debugPut "enter the proc of DHCPv4Server::RetrieveRouterStats"    

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
    }
    set DeviceHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_dhcpv4serverResultHandle ]
    }
    set dhcpServerResultHandle $::mainDefine::result 

    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $dhcpServerResultHandle]
    } err]} {
        return $errorCode
    }

    set hDhcpServerResults [lindex [stc::get $m_hDhcpSrvCfg -children-Dhcpv4ServerResults] 0]
    set DhcpServerStats ""
       
    lappend DhcpServerStats -DiscoverRxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -RxDiscoverCount]
    lappend DhcpServerStats -RequestRxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -RxRequestCount]
    lappend DhcpServerStats -DeclineRxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -RxDeclineCount]
    lappend DhcpServerStats -ReleaseRxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -RxReleaseCount]
    lappend DhcpServerStats -ACKTxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -TxAckCount]
    lappend DhcpServerStats -NAKTxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -TxNakCount]
    lappend DhcpServerStats -OfferTxCount 
    lappend DhcpServerStats [stc::get $hDhcpServerResults -TxOfferCount]

    if { $args == "" } {
        debugPut "exit the proc of DHCPv4Server::RetrieveRouterStats" 
        return $DhcpServerStats
    } else {     
        set DhcpServerStats [string tolower $DhcpServerStats]
        array set arr $DhcpServerStats
        foreach {name valueVar}  $args {   
            if {[array names arr $name] != ""} {
                set ::mainDefine::gAttrValue $arr($name)

                set ::mainDefine::gVar $valueVar
                uplevel 1 {
                    set $::mainDefine::gVar $::mainDefine::gAttrValue
                }          
            } else {
                puts "Info: $name parameter is not supported by Spirent TestCenter."
            }
        }        
        debugPut "exit the proc of DHCPv4Server::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

#--------------------------Dhcp client & Relay API below ------------------------------

############################################################################
#APIName: SetSession
#Description: Configure DHCPv4 host atributes
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::SetSession {args} {
   
    debugPut "enter the proc of DHCPv4Client::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    #Parse Count parameter
    set index [lsearch $args -count]
    if {$index != -1} {
        set DeviceCount [lindex $args [expr $index + 1]]
        set m_deviceCount $DeviceCount
    } 
   
    #Parse RelayAgentIpAddr parameter
    set index [lsearch $args -relayagentipaddr]
    if {$index != -1} {
        set RelayAgentIpAddr [lindex $args [expr $index + 1]]
        set m_relayAgentIpAddr $RelayAgentIpAddr
    } 
    #Parse ServerIpAddr parameter
    set index [lsearch $args -serveripaddr]
    if {$index != -1} {
        set ServerIpAddr [lindex $args [expr $index + 1]]
        set m_serverIpAddr $ServerIpAddr
    }
    
    if {$m_blockType == "dhcprelay"} {
        #Parse ClientLocalMac parameter
        set index [lsearch $args -clientlocalmac]
        if {$index != -1} {
            set ClientLocalMac [lindex $args [expr $index + 1]]
            set m_clientLocalMac $ClientLocalMac
        } 
        #Parse ClientLocalMacModifier parameter
        set index [lsearch $args -clientlocalmacmodifier]
        if {$index == -1} {
            set index [lsearch $args -clientlocalmacmodifer]
        }

        if {$index != -1} {
            set ClientLocalMacModifier [lindex $args [expr $index + 1]]
            set m_clientLocalMacModifier $ClientLocalMacModifier
        } 
    } else {
        #Parse LocalMac parameter
        set index [lsearch $args -localmac]
        if {$index != -1} {
            set LocalMac [lindex $args [expr $index + 1]]
            set m_clientLocalMac $LocalMac
        } 
        #Parse LocalMacModifier parameter
        set index [lsearch $args -localmacmodifier]
        if {$index == -1} {
            set index [lsearch $args -localmacmodifer]
        }

        if {$index != -1} {
            set LocalMacModifier [lindex $args [expr $index + 1]]
            set m_clientLocalMacModifier $LocalMacModifier
        } 
    }
    #Parse LocalAgentMac parameter
    set index [lsearch $args -localagentmac]
    if {$index != -1} {
        set LocalAgentMac [lindex $args [expr $index + 1]]
        set m_localAgentMac $LocalAgentMac
    }
    #Parse LocalAgentEncap parameter
    set index [lsearch $args -localagentencap]
    if {$index != -1} {
        set LocalAgentEncap [lindex $args [expr $index + 1]]
    }
    #Parse PoolName parameter
    set index [lsearch $args -poolname]
    if {$index != -1} {
        set PoolName [lindex $args [expr $index + 1]]
        set m_poolName $PoolName
    } 
    #Parse flagGateway parameter
    set index [lsearch $args -flaggateway]
    if {$index != -1} {
        set FlagGateway [lindex $args [expr $index + 1]]
        set m_flagGateway $FlagGateway
    } 
    #Parse Ipv4Gateway parameter
    set index [lsearch $args -ipv4gateway]
    if {$index != -1} {
        set Ipv4Gateway [lindex $args [expr $index + 1]]
        set m_ipv4Gateway $Ipv4Gateway
    } 
    
    #Parse FlagBroadcast parameter
    set index [lsearch $args -flagbroadcast]
    if {$index != -1} {
        set FlagBroadcast [lindex $args [expr $index + 1]]
        set m_flagBroadcast $FlagBroadcast
    }
    
    #Parse AutoRetryNum parameter
    set index [lsearch $args -autoretrynum]
    if {$index != -1} {
        set AutoRetryNum [lindex $args [expr $index + 1]]
        set m_autoRetryNum $AutoRetryNum
    } 
    #Parse FlagRelayAgentOption parameter
    set index [lsearch $args -flagrelayagentoption]
    if {$index != -1} {
        set FlagRelayAgentOption [lindex $args [expr $index + 1]]
        set m_flagRelayAgentOption $FlagRelayAgentOption

        if {[string tolower $m_flagRelayAgentOption] == "true"} {
            set m_flagRelayAgentCircuitID "TRUE"
            set m_flagRelayAgentRemoteID "TRUE" 
        }
    } 
    
    #Parse CircuitId parameter
    set index [lsearch $args -circuitid]
    if {$index != -1} {
        set CircuitId [lindex $args [expr $index + 1]]
        set m_circuitId $CircuitId
    } 

    #Parse RemoteId parameter
    set index [lsearch $args -remoteid]
    if {$index != -1} {
        set RemoteId [lindex $args [expr $index + 1]]
        set m_remoteId $RemoteId
    } 
    #Parse DiscoveryOptionType parameter
    set index [lsearch $args -discoveryoptiontype]
    if {$index != -1} {
        set DiscoveryOptionType [lindex $args [expr $index + 1]]
        set DiscoveryOptionType [string tolower $DiscoveryOptionType]
        set m_discoveryOptionType $DiscoveryOptionType
    } 
    #Parse DiscoveryOptionValue parameter
    set index [lsearch $args -discoveryoptionvalue]
    if {$index != -1} {
        set DiscoveryOptionValue [lindex $args [expr $index + 1]]
        set m_discoveryOptionValue $DiscoveryOptionValue
    }
    #Parse RequestOptionType parameter
    set index [lsearch $args -requestoptiontype]
    if {$index != -1} {
        set RequestOptionType [lindex $args [expr $index + 1]]
        set RequestOptionType [string tolower $RequestOptionType]
        set m_requestOptionType $RequestOptionType
    }   
    #Parse RequestOptionValue parameter
    set index [lsearch $args -requestoptionvalue]
    if {$index != -1} {
        set RequestOptionValue [lindex $args [expr $index + 1]]
        set m_requestOptionValue $RequestOptionValue
    }
    #Parse Active parameter
    set index [lsearch $args -active]
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]      
        set m_active $Active
    }
    #Parse VlanType1 parameter
    set index [lsearch $args -vlantype1]
    if {$index != -1} {
        set VlanType1 [lindex $args [expr $index + 1]]      
        set m_vlanType1 $VlanType1
    }
    #Parse VlanId1 parameter
    set index [lsearch $args -vlanid1]
    if {$index != -1} {
        set VlanId1 [lindex $args [expr $index + 1]]      
        set m_vlanId1 $VlanId1
    }
    #Parse VlanModifier1 parameter
    set index [lsearch $args -vlanidmodifier1]
    if {$index != -1} {
        set VlanModifier1 [lindex $args [expr $index + 1]]      
        set m_vlanModifier1 $VlanModifier1
    } else {
        set index [lsearch $args -vlanmodifier1]
        if {$index != -1} {
            set VlanModifier1 [lindex $args [expr $index + 1]]      
            set m_vlanModifier1 $VlanModifier1
        } 
    } 

    #Parse VlanidCount1 parameter
    set index [lsearch $args -vlanidcount1]
    if {$index != -1} {
        set VlanCount1 [lindex $args [expr $index + 1]]      
        set m_vlanCount1 $VlanCount1
    }

    #Parse VlanType2 parameter
    set index [lsearch $args -vlantype2]
    if {$index != -1} {
        set VlanType2 [lindex $args [expr $index + 1]]      
        set m_vlanType2 $VlanType2
    }
    #Parse VlanId2 parameter
    set index [lsearch $args -vlanid2]
    if {$index != -1} {
        set VlanId2 [lindex $args [expr $index + 1]]      
        set m_vlanId2 $VlanId2
    }
    #Parse VlanModifier2 parameter
    set index [lsearch $args -vlanidmodifier2]
    if {$index != -1} {
        set VlanModifier2 [lindex $args [expr $index + 1]]      
        set m_vlanModifier2 $VlanModifier2
    } else {
        set index [lsearch $args -vlanmodifier2]
        if {$index != -1} {
            set VlanModifier2 [lindex $args [expr $index + 1]]      
            set m_vlanModifier2 $VlanModifier2
        } 
    } 

    #Parse VlanIdCount2 parameter
    set index [lsearch $args -vlanidcount2]
    if {$index != -1} {
        set VlanCount2 [lindex $args [expr $index + 1]]      
        set m_vlanCount2 $VlanCount2
    }

    #Parse ConnectRate parameter
    set index [lsearch $args -connectrate]
    if {$index != -1} {
        set ConnectRate [lindex $args [expr $index + 1]]      
        set m_connectRate $ConnectRate
    }
    #Parse DisconnectRate parameter
    set index [lsearch $args -disconnectrate]
    if {$index != -1} {
        set DisconnectRate [lindex $args [expr $index + 1]]      
        set m_disconnectRate $DisconnectRate
    }
    #Parse RetransmitNum parameter
    set index [lsearch $args -retransmitnum]
    if {$index != -1} {
        set RetransmitNum [lindex $args [expr $index + 1]]      
        set m_retransmitNum $RetransmitNum
    }

    #Parse FlagRelayAgentCircuitID parameter
    set index [lsearch $args -flagrelayagentcircuitid]
    if {$index != -1} {
        set FlagRelayAgentCircuitID [lindex $args [expr $index + 1]]      
        set m_flagRelayAgentCircuitID $FlagRelayAgentCircuitID
    }

    #Parse FlagRelayAgentRemoteID parameter
    set index [lsearch $args -flagrelayagentremoteid]
    if {$index != -1} {
        set FlagRelayAgentRemoteID [lindex $args [expr $index + 1]]      
        set m_flagRelayAgentRemoteID $FlagRelayAgentRemoteID
    }

    #Parse RelayAgentPoolStart parameter
    set index [lsearch $args -relayagentpoolstart]
    if {$index != -1} {
        set RelayAgentPoolStart [lindex $args [expr $index + 1]]      
        set m_relayAgentPoolStart $RelayAgentPoolStart
    }

    set connectRate $m_connectRate
    set disconnectRate $m_disconnectRate

    set hDhcpPortCfg [stc::get $m_hPort -children-Dhcpv4PortConfig ]
    stc::config $hDhcpPortCfg -RequestRate $connectRate -ReleaseRate $disconnectRate -RetryCount $m_retransmitNum

    #Configure DHCPv4 Client
    set hHost $m_hHost
    set hDhcpBlkCfg $m_hDhcpBlkCfg
    set hIpv4If $m_hIpv4
    set hEthIIIf $m_hEthIIIf

    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv4
    }
    
    stc::config $hHost -DeviceCount $m_deviceCount 

    #Configure DHCP VLAN interface£¨support 2 VLANs£©
    DHCPConfigVlanIfs $args $hHost $m_deviceCount $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1 \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2 $hIpv4If $hEthIIIf    
     
    stc::config $hDhcpBlkCfg -UseBroadcastFlag $m_flagBroadcast \
                    -EnableAutoRetry "TRUE" \
                    -RetryAttempts $m_autoRetryNum \
                    -EnableRelayAgent $m_flagRelayAgentOption \
                    -EnableCircuitId $m_flagRelayAgentCircuitID \
                    -EnableRemoteId $m_flagRelayAgentRemoteID \
                    -Active $m_active
  
    if {$m_blockType == "dhcprelay"} {
        stc::config $hDhcpBlkCfg -EnableRelayAgent TRUE
        if {[info exists RelayAgentIpAddr]} {
            stc::config $hDhcpBlkCfg -RelayAgentIpv4Addr $m_relayAgentIpAddr
        } 
        if {[info exists ServerIpAddr]} {
            stc::config $hDhcpBlkCfg -RelayServerIpv4Addr $m_serverIpAddr
        }
        stc::config $hDhcpBlkCfg -RelayClientMacAddrStart $m_clientLocalMac -RelayClientMacAddrStep $m_clientLocalMacModifier
        if {$m_portType == "ethernet"} {
            stc::config $hEthIIIf -SourceMac $m_localAgentMac
        }
    } else {
        if {[string tolower $m_flagRelayAgentOption] == "true"} {
            stc::config $hDhcpBlkCfg -RelayPoolIpv4Addr $m_relayAgentPoolStart

            if {[info exists RelayAgentIpAddr]} {
                stc::config $hDhcpBlkCfg -RelayAgentIpv4Addr $m_relayAgentIpAddr
            } 

            if {[info exists ServerIpAddr]} {
                stc::config $hDhcpBlkCfg -RelayServerIpv4Addr $m_serverIpAddr
            }
        }
        if {$m_portType == "ethernet"} {
            stc::config $hEthIIIf -SourceMac $m_clientLocalMac -SrcMacStep $m_clientLocalMacModifier
        }
    }

    if {[info exists Ipv4Gateway]} {
        if {$m_ipv4Gateway !=""} {
            stc::config $hIpv4If -Gateway $m_ipv4Gateway
        } 
    }
    
    if {[info exists CircuitId]} {
        stc::config $hDhcpBlkCfg -CircuitId $m_circuitId
    }
    if {[info exists RemoteId]} {       
        stc::config $hDhcpBlkCfg -RemoteId $m_remoteId
    }
    if {[info exists DiscoveryOptionValue]} {
        for {set i 0} {$i < $m_discoveryListCount} {incr i} {
            if {[info exists m_hDiscoveryOptionArr($i)]} {
                stc::delete $m_hDiscoveryOptionArr($i)
            }
        }
        set counter 0
        foreach optionType $m_discoveryOptionType {
            if {[string range $optionType 0 1] == "0x"} {
                set typeValue [format %d $optionType]
                set value [lindex $DiscoveryOptionValue $counter]
                set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType $typeValue -Payload $value -HexValue TRUE]
            } else {
                switch $optionType {
                    "submask" {
                        set value [lindex $DiscoveryOptionValue $counter]
                        set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType 1 -Payload $value -HexValue FALSE]                        
                    }
                    "dns" {
                        set value [lindex $DiscoveryOptionValue $counter]
                        set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType 6 -Payload $value -HexValue FALSE]                        
                    }
                    "relayagent" {
                        set value [lindex $DiscoveryOptionValue $counter]
                        set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType 82 -Payload $value -HexValue FALSE]                        
                    }
                    "gateway" {
                        set value [lindex $DiscoveryOptionValue $counter]
                        set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType 3 -Payload $value -HexValue FALSE]                        
                    }
                    "classidentifier" {
                        set value [lindex $DiscoveryOptionValue $counter]
                        set m_hDiscoveryOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType DISCOVER -OptionType 60 -Payload $value -HexValue FALSE]
                    }                                  
                }
            }
            incr counter
        }        
        set m_discoveryListCount $counter
    }

    if {[info exists RequestOptionValue]} {
        set counter 0
        for {set i 0} {$i < $m_requestListCount} {incr i} {
            if {[info exists m_hRequestOptionArr($i)]} {
                stc::delete $m_hRequestOptionArr($i)
            }
        }
        foreach optionType $m_requestOptionType {
            if {[string range $optionType 0 1] == "0x"} {
                set typeValue [format %d $optionType]
                set value [lindex $RequestOptionValue $counter]
                set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType $typeValue -Payload $value -HexValue TRUE]                
            } else {
                switch $optionType {
                    "submask" {
                        set value [lindex $RequestOptionValue $counter]
                        set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType 1 -Payload $value -HexValue FALSE]
                    }
                    "dns" {
                        set value [lindex $RequestOptionValue $counter]
                        set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType 6 -Payload $value -HexValue FALSE]                        
                    }
                    "relayagent" {
                        set value [lindex $RequestOptionValue $counter]
                        set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType 82 -Payload $value -HexValue FALSE]                        
                    }
                    "gateway" {
                        set value [lindex $RequestOptionValue $counter]
                        set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType  3  -Payload $value -HexValue FALSE]
                    }
                    "classidentifier" {
                        set value [lindex $RequestOptionValue $counter]
                        set m_hRequestOptionArr($counter) [stc::create "Dhcpv4MsgOption" -under $m_hDhcpBlkCfg -MsgType REQUEST -OptionType 60 -Payload $value -HexValue FALSE]
                    }
                }
            }
            incr counter
        }        
        set m_requestListCount $counter
    }
    
    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of DHCPv4Client::SetSession"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: RetrieveRouter
#Description: Get DHCPv4 Client Router attributes
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::RetrieveRouter {args} {
  
    debugPut "enter the proc of DHCPv4Client::RetrieveRouter"    
    set args [ConvertAttrToLowerCase $args]

    set DhcpGetRouterResult ""
    lappend DhcpGetRouterResult -state
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -BlockState]
    lappend DhcpGetRouterResult -encapsulation
    lappend DhcpGetRouterResult EthernetII 
    lappend DhcpGetRouterResult -count
    lappend DhcpGetRouterResult [stc::get $m_hHost -DeviceCount]
    if {$m_blockType == "dhcprelay"} {
        lappend DhcpGetRouterResult -relayagentipaddr
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RelayAgentIpv4Addr]
        lappend DhcpGetRouterResult -serveripaddr
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RelayServerIpv4Addr]
        lappend DhcpGetRouterResult -clientlocalmac
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RelayClientMacAddrStart]
        lappend DhcpGetRouterResult -clientlocalmacmodifier
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RelayClientMacAddrStep]
        if {$m_portType == "ethernet"} {
            lappend DhcpGetRouterResult -localagentmac
            lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
            lappend DhcpGetRouterResult -localagentencap
            lappend DhcpGetRouterResult EthernetII
        }
    } else {
        if {$m_portType == "ethernet"} {
            lappend DhcpGetRouterResult -localmac
            lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
            lappend DhcpGetRouterResult -localmacmodifier
            lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SrcMacStep]
        }
    }
    lappend DhcpGetRouterResult -testipaddr
    lappend DhcpGetRouterResult [stc::get $m_hIpv4 -Address]
    lappend DhcpGetRouterResult -flaggateway
    lappend DhcpGetRouterResult $m_flagGateway 
    lappend DhcpGetRouterResult -ipv4gateway
    lappend DhcpGetRouterResult [stc::get $m_hIpv4 -Gateway]
    lappend DhcpGetRouterResult -poolname
    lappend DhcpGetRouterResult $m_poolName
    lappend DhcpGetRouterResult -active
    set active [stc::get $m_hDhcpBlkCfg -Active]
    set active [string tolower $active]
    if {$active == true} {
        set active Enable
    } elseif {$active == false} {
        set active Disable
    }
    lappend DhcpGetRouterResult $active
    lappend DhcpGetRouterResult -flagbroadcast
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -UseBroadcastFlag]
    lappend DhcpGetRouterResult -autoretrynum
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RetryAttempts]
    lappend DhcpGetRouterResult -flagrelayagentoption
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -EnableRelayAgent]
    lappend DhcpGetRouterResult -circuitid
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -CircuitId]
    lappend DhcpGetRouterResult -remoteid
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RemoteId]
    lappend DhcpGetRouterResult -discoveryoptiontype
    lappend DhcpGetRouterResult $m_discoveryOptionType
    lappend DhcpGetRouterResult -discoveryoptionvalue
    lappend DhcpGetRouterResult $m_discoveryOptionValue
    lappend DhcpGetRouterResult -requestoptiontype
    lappend DhcpGetRouterResult $m_requestOptionType
    lappend DhcpGetRouterResult -requestoptionvalue
    lappend DhcpGetRouterResult $m_requestOptionValue
    set hDhcpPortCfg [stc::get $m_hPort -children-Dhcpv4PortConfig ]
    lappend DhcpGetRouterResult -connectrate 
    set rate [stc::get $hDhcpPortCfg -RequestRate]
    lappend DhcpGetRouterResult $rate
    lappend DhcpGetRouterResult -disconnectrate  
    set rate [stc::get $hDhcpPortCfg -ReleaseRate ]
    lappend DhcpGetRouterResult $rate
    lappend DhcpGetRouterResult -retransmitnum 
    lappend DhcpGetRouterResult [stc::get $hDhcpPortCfg -RetryCount ]

    lappend DhcpGetRouterResult -vlantype1
    lappend DhcpGetRouterResult $m_vlanType1
    lappend DhcpGetRouterResult -vlanid1
    lappend DhcpGetRouterResult $m_vlanId1
    lappend DhcpGetRouterResult -vlanidmodifier1
    lappend DhcpGetRouterResult $m_vlanModifier1
    lappend DhcpGetRouterResult -vlanidcount1
    lappend DhcpGetRouterResult $m_vlanCount1

    lappend DhcpGetRouterResult -vlantype2
    lappend DhcpGetRouterResult $m_vlanType2
    lappend DhcpGetRouterResult -vlanid2
    lappend DhcpGetRouterResult $m_vlanId2
    lappend DhcpGetRouterResult -vlanidmodifier2
    lappend DhcpGetRouterResult $m_vlanModifier2
    lappend DhcpGetRouterResult -vlanidcount2
    lappend DhcpGetRouterResult $m_vlanCount2

    if { $args == "" } {
        debugPut "exit the proc of DHCPv4Client::RetrieveRouter" 
        return $DhcpGetRouterResult
    } else {     
        #set DhcpGetRouterResult [string tolower $DhcpGetRouterResult]
        array set arr $DhcpGetRouterResult
        #parray arr
        foreach {name valueVar}  $args {   
            if {[array names arr $name] != ""} {
                set ::mainDefine::gAttrValue $arr($name)

                set ::mainDefine::gVar $valueVar
                uplevel 1 {
                    set $::mainDefine::gVar $::mainDefine::gAttrValue
                }          
            } else {
                puts "Info: $name parameter is not supported by Spirent TestCenter."
            }
        }        
        debugPut "exit the proc of DHCPv4Client::RetrieveRouter"   
        return $::mainDefine::gSuccess     
    }    
}


############################################################################
#APIName: Enable
#Description: Enable DHCP Client 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Enable {args} {
    
    debugPut "enter the proc of DHCPv4Client::Enable"    

    stc::config $m_hHost -Active TRUE   
    stc::config $m_hDhcpBlkCfg -Active TRUE
    #Apply the configuration to the chassis
    ApplyValidationCheck
    #Enable DHCPv4 Client
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of DHCPv4Client::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Disable DHCP Client
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Disable {args} {
   
    debugPut "enter the proc of DHCPv4Client::Disable"    

    #Stop DHCPv4 client
    stc::perform DeviceStop -DeviceList $m_hHost
    stc::config $m_hHost -Active FALSE   
    stc::config $m_hDhcpBlkCfg -Active FALSE

    #Apply the configuration to the chassis
    ApplyValidationCheck
    
    debugPut "exit the proc of DHCPv4Client::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Bind
#Description: dhcp client bind
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Bind {args} {
   
    debugPut "enter the proc of DHCPv4Client::Bind"    

    #DHCPv4 client bind session
    stc::perform Dhcpv4Bind -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv4Client::Bind"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Release
#Description: release dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Release {args} {
    
    debugPut "enter the proc of DHCPv4Client::Release"    

    #DHCPv4 client release session
    stc::perform Dhcpv4Release -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv4Client::Release"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Renew
#Description: renew dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Renew {args} {
   
    debugPut "enter the proc of DHCPv4Client::Renew"    

    #renew dhcp host 
    stc::perform Dhcpv4Renew -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv4Client::Renew"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Abort
#Description: Abort all the active Session of dhcp host, and force into idle state
#             
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Abort {args} {
   
    debugPut "enter the proc of DHCPv4Client::Abort"    

    #Abort dhcp host 
    stc::perform Dhcpv4Abort -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv4Client::Abort"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Reset
#Description: Reset dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Reset {args} {
  
    debugPut "enter the proc of DHCPv4Client::Reset"    

    #Reset dhcp host 
    stc::perform DeviceStop -DeviceList $m_hHost
    after 3000
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of DHCPv4Client::Reset"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: ResetMeasurement
#Description: ResetMeasurement dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::ResetMeasurement {args} {
    
    debugPut "enter the proc of DHCPv4Client::ResetMeasurement"    

    #Reset dhcp host 
    stc::perform DeviceStop -DeviceList $m_hHost
    after 3000
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of DHCPv4Client::ResetMeasurement"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Reboot
#Description: Reboot dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Reboot {args} {
   
    debugPut "enter the proc of DHCPv4Client::Reboot"    

    #reboot dhcp host 
    stc::perform DeviceStop -DeviceList $m_hHost
    after 3000
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of DHCPv4Client::Reboot"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Decline
#Description: decline dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Decline {args} {
    puts "Info: Decline method is not supported by Spirent TestCenter."
}

############################################################################
#APIName: Inform
#Description: Inform dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::Inform {args} {
    puts "Info: Inform method is not supported by Spirent TestCenter."
}

############################################################################
#APIName: RetryUnbound
#Description: RetryUnbound dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::RetryUnbound {args} {
    puts "Info: RetryUnbound method is not supported by Spirent TestCenter."
}

############################################################################
#APIName: ClearStats
#Description: Clear DHCP statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::ClearStats {args} {
   
    debugPut "enter the proc of DHCPv4Client::ClearStats"    

    #Clear DHCPv4 statistics
    stc::perform ResultsClearAllProtocol    

    debugPut "exit the proc of DHCPv4Client::ClearStats"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Get DHCP Client statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::RetrieveRouterStats {args} {
       set args [ConvertAttrToLowerCase $args]

    #get port information, modified by Penn 2010/4/21 
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
    set dhcpBlockResultHandle [$gChassisName cget -m_dhcpv4BlockResultHandle ]
      
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $dhcpBlockResultHandle]
    } err]} {
        return $errorCode
    }

    set hDhcpBlockResults [stc::get $m_hDhcpBlkCfg -children-Dhcpv4BlockResults]
    set DhcpBlockStats ""
       
    lappend DhcpBlockStats -StateBoundNum 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentBoundCount]
    lappend DhcpBlockStats -StateInitNumNum 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentIdleCount]
    lappend DhcpBlockStats -StateRequestingNum 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentAttemptCount]    
    lappend DhcpBlockStats -ACKRxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxAckCount]
    lappend DhcpBlockStats -NAKRxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxNakCount]
    lappend DhcpBlockStats -OfferRxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxOfferCount]
    lappend DhcpBlockStats -DiscoverTxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxDiscoverCount]
    lappend DhcpBlockStats -RequestTxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxRequestCount]
    lappend DhcpBlockStats -ReleaseTxCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxReleaseCount]

    if { $args == "" } {
        debugPut "exit the proc of DHCPv4Client::RetrieveRouterStats" 
        return $DhcpBlockStats
    } else {     
        set DhcpBlockStats [string tolower $DhcpBlockStats]
        array set arr $DhcpBlockStats
        foreach {name valueVar}  $args {   
            if {[array names arr $name] != ""} {
                set ::mainDefine::gAttrValue $arr($name)

                set ::mainDefine::gVar $valueVar
                uplevel 1 {
                    set $::mainDefine::gVar $::mainDefine::gAttrValue
                }          
            } else {
                puts "Info: $name parameter is not supported by Spirent TestCenter."
            }
        }        
        debugPut "exit the proc of DHCPv4Client::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: SetFlap
#
#Description:Configure the flapping parameters from bound toRelease, and from Reboot to Renew
#
#Input: 1. AWDTimer:Bound to Release (Or Renew to Abort) time interval,the unit is ms
#       2. WADTimer:Release to Bound (Or Abort to Renew) time interval,the unit is ms
#
#Output: None
#
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::SetFlap {args} {
   
    debugPut "enter the proc of DHCPv4Client::SetFlap" 
    set args [ConvertAttrToLowerCase $args] 
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
    
    debugPut "exit the proc of DHCPv4Client::SetFlap"        
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: StartFlap
#Description: start flap dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::StartFlap {args} {
   
    debugPut "enter the proc of DHCPv4Client::StartFlap"
    
    set args [ConvertAttrToLowerCase $args] 
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [incr index]]
    } else {
        set type "release"
    }
    set type [string tolower $type]

    set existing_sequencer [stc::get system1 -Children-Sequencer]
    if {$existing_sequencer == ""} { 
        set sequencer1 [stc::create Sequencer -under system1 -Name "DhcpScheduler$m_hostName"]
    } else {
        set sequencer1 $existing_sequencer
    }

    set loop1 [stc::create SequencerLoopCommand -under $sequencer1 -ContinuousMode TRUE]
    stc::perform SequencerClear
    stc::perform SequencerInsert -CommandList $loop1

    set awdtimer [expr $m_awdtimer/1000]
    if {$awdtimer == 0} {
        set awdtimer 1  
    }
    set waitTime1 [stc::create WaitCommand -under $loop1 -WaitTime $awdtimer]
    set bindDhcp1 [stc::create Dhcpv4BindCommand -under $loop1 -BlockList $m_hDhcpBlkCfg] 

    set wadtimer [expr $m_wadtimer/1000]
    if {$wadtimer == 0} {
        set wadtimer 1  
    } 
    set waitTime2 [stc::create WaitCommand -under $loop1 -WaitTime $wadtimer]
    switch $type {
        "release" {
            set releaseDhcp1 [stc::create Dhcpv4ReleaseCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
            stc::perform SequencerInsert -CommandList $releaseDhcp1 -CommandParent $loop1
            
        }
        "renew" {
            set renewDhcp1 [stc::create Dhcpv4RenewCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
            stc::perform SequencerInsert -CommandList $renewDhcp1 -CommandParent $loop1
        }
        "abort" {
            set abortDhcp1 [stc::create Dhcpv4AbortCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
            stc::perform SequencerInsert -CommandList $abortDhcp1 -CommandParent $loop1
        }
        default {
            error "Wrong type. please specify the right type: release, renew or abort."
        }
    }
    stc::perform SequencerInsert -CommandList $waitTime1 -CommandParent $loop1
    stc::perform SequencerInsert -CommandList $bindDhcp1 -CommandParent $loop1
    stc::perform SequencerInsert -CommandList $waitTime2 -CommandParent $loop1    

    stc::perform SequencerStart

    debugPut "exit the proc of DHCPv4Client::StartFlap"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: StopFlap
#Description: stop flap dhcp host 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::StopFlap {args} {
     
    debugPut "enter the proc of DHCPv4Client::StopFlap"
    
    set args [ConvertAttrToLowerCase $args] 
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [incr index]]
    } else {
        set type "release"
    }

    if {$type != "release" && $type != "renew" && $type != "abort"} {   
        error "Wrong type. please specify the right type: release, renew or abort."
    } else {
        stc::perform SequencerStop
    }

    debugPut "exit the proc of DHCPv4Client::StopFlap"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveHostState
#Description: Get host state according to input MAC address
#Input: For the details please refer to the user guide
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv4Client::RetrieveHostState {args} {
   
    set args1 [reformatArgs $args]
    set args [ConvertAttrToLowerCase $args]
    #Parse FileName parameter
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args1 [expr $index + 1]]
    }

    #Parse Mac parameter
    set index [lsearch $args -mac]
    if {$index != -1} {
        set Mac [lindex $args1 [expr $index + 1]] 
        set Mac [regsub -all : $Mac ""]
        set Mac [regsub -all -- - $Mac ""]
        set Mac [regsub -all \\. $Mac ""]
    }

    #Parse State parameter
    set index [lsearch $args -state] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] State
        set State "IDLE"
    }
    #Parse IpAddr parameter
    set index [lsearch $args -ipaddr] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IpAddr
        set IpAddr "" 
    }
    #Parse LeaseTimer parameter
    set index [lsearch $args -leasetimer] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LeaseTimer
        set LeaseTimer ""
    }
    #Parse Option82CrcuitId parameter
    set index [lsearch $args -option82crcuitId] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Option82CrcuitId
        set Option82CrcuitId ""
    }
    #Parse Option82RemoteId parameter
    set index [lsearch $args -option82remoteId] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] Option82RemoteId
        set Option82RemoteId ""
    }
    #Parse DhcpServer parameter
    set index [lsearch $args -dhcpserver] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] DhcpServer
        set DhcpServer $m_serverIpAddr
    }
    #Parse EstablishmentTimer parameter
    set index [lsearch $args -establishmenttimer] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] EstablishmentTimer
        set EstablishmentTimer ""
    }
    #Parse LeaseLeft parameter
    set index [lsearch $args -leaseleft] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] LeaseLeft
        set LeaseLeft ""
    }
    #Parse DiscoverResponseTime parameter
    set index [lsearch $args -discoverresponsetime] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] DiscoverResponseTime
        set DiscoverResponseTime ""
    }
    #Parse RequestResponseTime parameter
    set index [lsearch $args -requestresponsetime] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RequestResponseTime
        set RequestResponseTime ""
    }
    
    if {[info exists FileName]} {
        stc::perform Dhcpv4SessionInfo -BlockList $m_hDhcpBlkCfg -FileName $FileName
        
        debugPut "exit the proc of DHCPv4Client::RetrieveHostState"  
        return $::mainDefine::gSuccess
    }

    if {[info exists Mac]} {
        set hostState ""
        stc::perform Dhcpv4SessionInfo -BlockList $m_hDhcpBlkCfg -FileName "c:/sessions.csv"
        set fid [open "c:/sessions.csv" r]
        set i 0
        while {[gets $fid line]} {
            if {$i != 0} {
                set listLine [split $line ,]      
                set temp [lindex $listLine 5]
                if {$temp == ""} {
                    break
                }
                set temp [regsub -all : $temp ""]
                set temp [regsub -all -- - $temp ""]
                set temp [regsub -all \\. $temp ""]

                if {$Mac == $temp} {
                    lappend hostState -Mac 
                    lappend hostState [lindex $listLine 5] 
                    lappend hostState -State 
                    lappend hostState [lindex $listLine 3] 
                    lappend hostState -IpAddr 
                    lappend hostState [lindex $listLine 8] 
                    lappend hostState -LeaseTimer 
                    lappend hostState [lindex $listLine 9] 
                    lappend hostState -LeaseLeft 
                    lappend hostState [lindex $listLine 10] 
                    lappend hostState -DiscoverResponseTime 
                    lappend hostState [lindex $listLine 11]
                    lappend hostState -RequestResponseTime 
                    lappend hostState [lindex $listLine 12]
                    lappend hostState -EstablishmentTimer 
                    lappend hostState "0"
                
                    set State [lindex $listLine 3]
                    set IpAddr [lindex $listLine 8]
                    set LeaseTimer [lindex $listLine 9]
                    set LeaseLeft [lindex $listLine 10]
                    set DiscoverResponseTime [lindex $listLine 11]
                    set RequestResponseTime [lindex $listLine 12]
                    break
                }
            }
            incr i
        }
        close $fid
    
        catch { file delete "c:/sessions.csv" }
        debugPut "exit the proc of DHCPv4Client::RetrieveHostState"  
        return $hostState   
    }
}
