###########################################################################
#                                                                        
#  File Name£ºDHCPv6Protocol.tcl                                                                            
#                  
#  Description£ºDefinition of DHCPv6Client and its methods
# 
#  Author£º Andy.zhang
#
#  Create Time:  2012.09.20
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

############################################################################
#APIName: DHCPv6ConfigVlanIfs
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
#Coded by: Andy
#############################################################################
proc DHCPv6ConfigVlanIfs {args m_hHost m_deviceCount m_vlanType1 m_vlanId1 m_vlanModifier1 m_vlanCount1 \
                         m_vlanType2 m_vlanId2 m_vlanModifier2 m_vlanCount2 m_upLayerIf1 m_upLayerIf2 m_hEthIIIf} {
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
            stc::config $m_upLayerIf1 -StackedOnEndpoint-targets $secondVlanIf
            stc::config $m_upLayerIf2 -StackedOnEndpoint-targets $secondVlanIf
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
            stc::config $m_upLayerIf1 -StackedOnEndpoint-targets $firstVlanIf
            stc::config $m_upLayerIf2 -StackedOnEndpoint-targets $firstVlanIf

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
                stc::config $m_upLayerIf1 -StackedOnEndpoint-targets $secondVlanIf
                stc::config $m_upLayerIf2 -StackedOnEndpoint-targets $secondVlanIf
            }
        } 
    }
}

#DHCP client Class
::itcl::class DHCPv6Client {
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
    public variable m_hIpv61 ""
    public variable m_hIpv62 ""
    public variable m_hEthIIIf ""
    public variable m_awdtimer 5000
    public variable m_wadtimer 5000

    #Definition of Dhcp client configurations
    public variable m_hDiscoveryOptionArr 
    public variable m_hRequestOptionArr 
    public variable m_discoveryListCount 0
    public variable m_requestListCount 0
    public variable m_pdEmulatadDevice ""
    public variable m_deviceCount 1
    public variable m_clientLocalMac "00:00:00:11:01:01"
    public variable m_clientLocalMacModifier "00:00:00:00:00:01"
    public variable m_poolName ""
    public variable m_flagGateway false  
    public variable m_ipv6Gateway ""
    public variable m_authProtocol "DelayedAuth"
    public variable m_dhcpRealm   "spirent.com"
    public variable m_enableRebind "false"
    public variable m_enableAuth "false"
    public variable m_enableReconfigAccept "false"
    public variable m_enableRenew  "true"
    public variable m_preferredLifeTime  "604800"
    public variable m_rapidCommitMode  "disable"
    public variable m_t1Timer "302400"
    public variable m_t2Timer "483840"
    public variable m_validLifeTime "2592000"
    public variable m_active    "true"
    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1 1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2 1
    public variable m_portType "ethernet"
    public variable m_emulationMode "dhcpv6"
    public variable m_clientMacAddrStart ""
    public variable m_clientMacAddrStep ""
 
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv61 hipv62 blockType portType} {
    
        set m_hPort $hPort
        set m_blockType $blockType
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv61 $hipv61
        set m_hIpv62 $hipv62
        set m_portType $portType
    
        lappend ::mainDefine::gObjectNameList $this 
        
        #Get Ethernet interface handle
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

#--------------------------Dhcp client  API below ------------------------------

############################################################################
#APIName: SetSession
#Description: Configure DHCPv6 host atributes
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body DHCPv6Client::SetSession {args} {
   
    debugPut "enter the proc of DHCPv6Client::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    #Parse EmulationMode parameter
    set index [lsearch $args -emulationmode]
    if {$index != -1} {
        set EmulationMode [lindex $args [expr $index + 1]]
        set m_emulationMode $EmulationMode
    } 
    #Parse Count parameter
    set index [lsearch $args -count]
    if {$index != -1} {
        set DeviceCount [lindex $args [expr $index + 1]]
        set m_deviceCount $DeviceCount
    } 
    #Parse LocalMac parameter
    set index [lsearch $args -localmac]
    if {$index != -1} {
        set LocalMac [lindex $args [expr $index + 1]]
        set m_clientLocalMac $LocalMac
    } 
    #Parse LocalMacModifier parameter
    set index [lsearch $args -localmacmodifier]
    if {$index != -1} {
        set LocalMacModifier [lindex $args [expr $index + 1]]
        set m_clientLocalMacModifier $LocalMacModifier
    } 
    
    #Parse PoolName parameter
    set index [lsearch $args -poolname]
    if {$index != -1} {
        set PoolName [lindex $args [expr $index + 1]]
        set m_poolName $PoolName
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
    set index [lsearch $args -vlancount1]
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

    #Parse VlanidCount2 parameter
    set index [lsearch $args -vlancount2]
    if {$index != -1} {
        set VlanCount2 [lindex $args [expr $index + 1]]      
        set m_vlanCount2 $VlanCount2
    }
    #Parse flagGateway parameter
    set index [lsearch $args -flaggateway]
    if {$index != -1} {
        set FlagGateway [lindex $args [expr $index + 1]]
        set m_flagGateway $FlagGateway
    } 
    #Parse Ipv6Gateway parameter
    set index [lsearch $args -ipv6gateway]
    if {$index != -1} {
        set Ipv6Gateway [lindex $args [expr $index + 1]]
        set m_ipv6Gateway $Ipv6Gateway
    } 
    
    #Parse AuthProtocol parameter
    set index [lsearch $args -authprotocol]
    if {$index != -1} {
        set AuthProtocol [lindex $args [expr $index + 1]]
        set m_authProtocol $AuthProtocol
    }
    if {[string toupper $m_authProtocol]=="DELAYEDAUTH"} {
        set m_authProtocol "DELAYED_AUTH"
    } elseif {[string toupper $m_authProtocol]=="RECONFIGKEY"} {
        set m_authProtocol "RECONFIG_KEY"
    } else {
        error "Parameter AuthProtocol should be DelayedAuth or ReconfigKey"
    }

    #Parse DhcpRealm parameter
    if {$m_authProtocol!=""} {
        set index [lsearch $args -dhcprealm]
        if {$index != -1} {
            set DhcpRealm [lindex $args [expr $index + 1]]
            set m_dhcpRealm $DhcpRealm
        }
    }
    
    #Parse EnableAuth parameter
    set index [lsearch $args -enableauth]
    if {$index != -1} {
        set EnableAuth [lindex $args [expr $index + 1]]
        set m_enableAuth $EnableAuth
    } 
    #Parse EnableRebind parameter
    set index [lsearch $args -enablerebind]
    if {$index != -1} {
        set EnableRebind [lindex $args [expr $index + 1]]
        set m_enableRebind $EnableRebind
    }
    #Parse EnableReconfigAccept parameter
    set index [lsearch $args -enablereconfigaccept]
    if {$index != -1} {
        set EnableReconfigAccept [lindex $args [expr $index + 1]]
        set m_enableReconfigAccept $EnableReconfigAccept
    }
    #Parse EnableRenew parameter
    set index [lsearch $args -enablerenew]
    if {$index != -1} {
        set EnableRenew [lindex $args [expr $index + 1]]
        set m_enableRenew $EnableRenew
    }
    #Parse PreferredLifeTime parameter
    set index [lsearch $args -preferredlifetime]
    if {$index != -1} {
        set PreferredLifeTime [lindex $args [expr $index + 1]]
        set m_preferredLifeTime $PreferredLifeTime
    }
    #Parse RapidCommitMode parameter
    set index [lsearch $args -rapidcommitmode]
    if {$index != -1} {
        set RapidCommitMode [lindex $args [expr $index + 1]]
        set m_rapidCommitMode $RapidCommitMode
    }
    if {[string tolower $m_rapidCommitMode]=="true"} {
        set m_rapidCommitMode enable
    } else {
        set m_rapidCommitMode disable
    }
    #Parse T1Timer parameter
    set index [lsearch $args -t1timer]
    if {$index != -1} {
        set T1Timer [lindex $args [expr $index + 1]]
        set m_t1Timer $T1Timer
    }
    #Parse T2Timer parameter
    set index [lsearch $args -t2timer]
    if {$index != -1} {
        set T2Timer [lindex $args [expr $index + 1]]
        set m_t2Timer $T2Timer
    }
    #Parse ValidLifeTime parameter
    set index [lsearch $args -validlifetime]
    if {$index != -1} {
        set ValidLifeTime [lindex $args [expr $index + 1]]
        set m_validLifeTime $ValidLifeTime
    }
    #Parse ClientMacAddrStart parameter
    set index [lsearch $args -clientmacaddrstart]
    if {$index != -1} {
        set ClientMacAddrStart [lindex $args [expr $index + 1]]
        set m_clientMacAddrStart $ClientMacAddrStart
    }
    #Parse ClientMacAddrStep parameter
    set index [lsearch $args -clientmacaddrstep]
    if {$index != -1} {
        set ClientMacAddrStep [lindex $args [expr $index + 1]]
        set m_clientMacAddrStep $ClientMacAddrStep
    }
    #Create DHCPv6 block
    if {$m_emulationMode=="dhcpv6pd"} {
        if {$m_hDhcpBlkCfg!=""} {
            stc::delete $m_hDhcpBlkCfg
        }
        if {$m_pdEmulatadDevice!=""} {
            stc::delete $m_pdEmulatadDevice
            set m_pdEmulatadDevice ""
        }
        set m_hDhcpBlkCfg [stc::create "Dhcpv6PdBlockConfig"  -under $m_hHost -Name $m_hostName ]
    } else {
        if {$m_hDhcpBlkCfg!=""} {
            stc::delete $m_hDhcpBlkCfg
        } 
        if {$m_pdEmulatadDevice!=""} {
            stc::delete $m_pdEmulatadDevice
            set m_pdEmulatadDevice ""
        }
        set m_hDhcpBlkCfg [stc::create "Dhcpv6BlockConfig"  -under $m_hHost -Name $m_hostName ]  
        if {$m_emulationMode=="dhcpv6andpd"} {
            stc::config $m_hDhcpBlkCfg -Dhcpv6ClientMode "DHCPV6ANDPD"
        }      
    }
    #Build the relationship between objects
    stc::config $m_hDhcpBlkCfg -UsesIf-targets $m_hIpv62   
    #Configure DHCPv6 Client
    set hHost $m_hHost
    set hDhcpBlkCfg $m_hDhcpBlkCfg
    set hIpv6If1 $m_hIpv61
    set hIpv6If2 $m_hIpv62
    set hEthIIIf $m_hEthIIIf

    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv62
    }
    
    stc::config $hHost -DeviceCount $m_deviceCount

    #Configure DHCPv6 EthIIIf interface
    if {$m_portType == "ethernet"} {
            stc::config $hEthIIIf -SourceMac $m_clientLocalMac -SrcMacStep $m_clientLocalMacModifier
    }

    #Configure DHCPv6 Ipv6 GateWay
    if {[string tolower $m_flagGateway] == true} {
        if {$m_ipv6Gateway !=""} {
            stc::config $hIpv6If2 -Gateway $m_ipv6Gateway
        } 
    }
    
    #Configure DHCPv6 VLAN interface£¨support 2 VLANs£©
    DHCPv6ConfigVlanIfs $args $hHost $m_deviceCount $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1  \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2  $hIpv6If1 $hIpv6If2 $hEthIIIf    

    #Config DHCPv6 Block
    if {$m_emulationMode=="dhcpv6pd"} {       
        stc::config $hDhcpBlkCfg  -EnableRebind $m_enableRebind   \
                    -EnableReconfigAccept $m_enableReconfigAccept -EnableRenew $m_enableRenew  -PreferredLifeTime $m_preferredLifeTime  -RapidCommitMode $m_rapidCommitMode \
                    -T1Timer $m_t1Timer -T2Timer $m_t2Timer  -ValidLifetime $m_validLifeTime  -Active $m_active
    } else {
        stc::config $hDhcpBlkCfg  -AuthProtocol $m_authProtocol -EnableRebind $m_enableRebind -DhcpRealm $m_dhcpRealm  -EnableAuth $m_enableAuth  \
                    -EnableReconfigAccept $m_enableReconfigAccept -EnableRenew $m_enableRenew  -PreferredLifeTime $m_preferredLifeTime  -RapidCommitMode $m_rapidCommitMode \
                    -T1Timer $m_t1Timer -T2Timer $m_t2Timer  -ValidLifetime $m_validLifeTime  -Active $m_active
    }

    if {$m_emulationMode=="dhcpv6pd"||$m_emulationMode=="dhcpv6andpd"} {
        set pd_emulatedDevice [stc::create "EmulatedDevice" -under $m_hProject]
        set m_pdEmulatadDevice $pd_emulatedDevice
        stc::config $pd_emulatedDevice -AffiliationPort-targets $m_hPort
        stc::config $pd_emulatedDevice -DeviceCount [expr $m_deviceCount*$m_vlanCount1*$m_vlanCount2]
        set pd_ethif [stc::create "EthIIIf" -under $pd_emulatedDevice]
        if {$m_clientMacAddrStart!=""} { 
            stc::config $pd_ethif -SourceMac $m_clientMacAddrStart 
        }
        if {$m_clientMacAddrStep!=""} { 
            stc::config $pd_ethif -SrcMacStep $m_clientMacAddrStep
        }
        set pd_ipv6if [stc::create "Ipv6If" -under $pd_emulatedDevice -AddrResolver Dhcpv6 -EnableGateWayLearning TRUE -IsRange TRUE]
        if {[string tolower $m_flagGateway]=="false"} {
            stc::config $pd_ipv6if -EnableGateWayLearning FALSE
        }
        set pd_ipv6if_local [stc::create "Ipv6If" -under $pd_emulatedDevice -AddrResolver "default" -EnableGateWayLearning TRUE -IsRange TRUE -Address "fe80::"]
        if {[string tolower $m_flagGateway]=="false"} {
            stc::config $pd_ipv6if_local -EnableGateWayLearning FALSE
        }
        stc::config $pd_ipv6if -StackedOnEndpoint-targets $pd_ethif
        stc::config $pd_ipv6if_local -StackedOnEndpoint-targets $pd_ethif

        set link1 [stc::perform "LinkCreate" -DstDev $m_hHost -DstIf $m_hIpv62 -LinkType "IP Forwarding Link" -SrcDev $pd_emulatedDevice -SrcIf $pd_ipv6if] 
        set link1 [lindex $link1 [expr [lsearch $link1 -Link]+1]]
        set link2 [stc::perform "LinkCreate" -DstDev $m_hHost -DstIf $m_hIpv61 -LinkType "IP Forwarding Link" -SrcDev $pd_emulatedDevice -SrcIf $pd_ipv6if_local]
        set link2 [lindex $link2 [expr [lsearch $link2 -Link]+1]]
        set link3 [stc::perform "LinkCreate" -DstDev $m_hHost -DstIf $m_hIpv62 -LinkType "Home Gateway Link" -SrcDev $pd_emulatedDevice -SrcIf $pd_ipv6if]
        set link3 [lindex $link3 [expr [lsearch $link3 -Link]+1]]
        stc::config $link3 -ContainedLink-targets "$link1 $link2"
        stc::config $pd_emulatedDevice -TopLevelIf-targets  "$pd_ipv6if $pd_ipv6if_local"
        stc::config $pd_emulatedDevice -PrimaryIf-targets "$pd_ipv6if_local"
    }
    
    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of DHCPv6Client::SetSession"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: Enable
#Description: Enable DHCP Client 
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Enable {args} {
    
    debugPut "enter the proc of DHCPv6Client::Enable"    

    stc::config $m_hHost -Active TRUE   
    stc::config $m_hDhcpBlkCfg -Active TRUE
    if {$m_pdEmulatadDevice!=""} {
        stc::config $m_pdEmulatadDevice -Active TRUE  
    }
    #Apply the configuration to the chassis
    ApplyValidationCheck
    #Enable DHCPv6 Client
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of DHCPv6Client::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Disable DHCP Client
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Disable {args} {
   
    debugPut "enter the proc of DHCPv6Client::Disable"    

    #Stop DHCPv6 client
    stc::perform DeviceStop -DeviceList $m_hHost
    stc::config $m_hHost -Active FALSE   
    stc::config $m_hDhcpBlkCfg -Active FALSE
    if {$m_pdEmulatadDevice!=""} {
        stc::config $m_pdEmulatadDevice -Active FALSE  
    }
    #Apply the configuration to the chassis
    ApplyValidationCheck
    
    debugPut "exit the proc of DHCPv6Client::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Bind
#Description: dhcp client bind
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Bind {args} {
   
    debugPut "enter the proc of DHCPv6Client::Bind"    

    #DHCPv6 client bind session
    stc::perform Dhcpv6Bind -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv6Client::Bind"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Release
#Description: release dhcp host 
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Release {args} {
    
    debugPut "enter the proc of DHCPv6Client::Release"    

    #DHCPv6 client release session
    stc::perform Dhcpv6Release -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv6Client::Release"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Renew
#Description: renew dhcp host 
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Renew {args} {
   
    debugPut "enter the proc of DHCPv6Client::Renew"    

    #renew dhcp host 
    stc::perform Dhcpv6Renew -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv6Client::Renew"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Abort
#Description: Abort all the active Session of dhcp host, and force into idle state
#             
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::Abort {args} {
   
    debugPut "enter the proc of DHCPv6Client::Abort"    

    #Abort dhcp host 
    stc::perform Dhcpv6Abort -BlockList $m_hDhcpBlkCfg

    debugPut "exit the proc of DHCPv6Client::Abort"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: ClearStats
#Description: Clear DHCP statistics
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::ClearStats {args} {
   
    debugPut "enter the proc of DHCPv6Client::ClearStats"    

    #Clear DHCPv6 statistics
    stc::perform ResultsClearAllProtocol    

    debugPut "exit the proc of DHCPv6Client::ClearStats"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Get DHCP Client statistics
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::RetrieveRouterStats {args} {
    debugPut "enter the proc of DHCPv6Client::RetrieveRouterStats"
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
    set dhcpv6BlockResultHandle [$gChassisName cget -m_dhcpv6BlockResultHandle ]
      
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $dhcpv6BlockResultHandle]
    } err]} {
        return $errorCode
    }

    set hDhcpBlockResults [stc::get $m_hDhcpBlkCfg -children-Dhcpv6BlockResults]
    set DhcpBlockStats ""
       
    lappend DhcpBlockStats -CurrentBoundCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentBoundCount]
    lappend DhcpBlockStats -CurrentIdleCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentIdleCount]
    lappend DhcpBlockStats -CurrentAttemptCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -CurrentAttemptCount]    
    lappend DhcpBlockStats -RxAdvertiseCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxAdvertiseCount]
    lappend DhcpBlockStats -RxReconfigureCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxReconfigureCount]
    lappend DhcpBlockStats -RxReplyCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -RxReplyCount]
    lappend DhcpBlockStats -TxConfirmCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxConfirmCount]
    lappend DhcpBlockStats -TxInfoRequestCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxInfoRequestCount]
    lappend DhcpBlockStats -TxRebindCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxRebindCount]
    lappend DhcpBlockStats -TxSolicitCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxSolicitCount]
    lappend DhcpBlockStats -TxReleaseCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxReleaseCount]
    lappend DhcpBlockStats -TxRenewCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxRenewCount]
    lappend DhcpBlockStats -TxRequestCount 
    lappend DhcpBlockStats [stc::get $hDhcpBlockResults -TxRequestCount]

    if { $args == "" } {
        debugPut "exit the proc of DHCPv6Client::RetrieveRouterStats" 
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
        debugPut "exit the proc of DHCPv6Client::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: RetrieveRouter
#Description: Get DHCPv6 Client Router attributes
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::RetrieveRouter {args} {
  
    debugPut "enter the proc of DHCPv6Client::RetrieveRouter"    
    set args [ConvertAttrToLowerCase $args]

    set DhcpGetRouterResult ""
    lappend DhcpGetRouterResult -state
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -BlockState]
    lappend DhcpGetRouterResult -emulationmode
    lappend DhcpGetRouterResult $m_emulationMode
    lappend DhcpGetRouterResult -count
    lappend DhcpGetRouterResult [stc::get $m_hHost -DeviceCount]
   
    if {$m_portType == "ethernet"} {
        lappend DhcpGetRouterResult -localmac
        lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
        lappend DhcpGetRouterResult -localmacmodifier
        lappend DhcpGetRouterResult [stc::get $m_hEthIIIf -SrcMacStep]
    }
   
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

    lappend DhcpGetRouterResult -vlantype1
    lappend DhcpGetRouterResult $m_vlanType1
    lappend DhcpGetRouterResult -vlanid1
    lappend DhcpGetRouterResult $m_vlanId1
    lappend DhcpGetRouterResult -vlanidmodifier1
    lappend DhcpGetRouterResult $m_vlanModifier1
    lappend DhcpGetRouterResult -vlancount1
    lappend DhcpGetRouterResult $m_vlanCount1

    lappend DhcpGetRouterResult -vlantype2
    lappend DhcpGetRouterResult $m_vlanType2
    lappend DhcpGetRouterResult -vlanid2
    lappend DhcpGetRouterResult $m_vlanId2
    lappend DhcpGetRouterResult -vlanidmodifier2
    lappend DhcpGetRouterResult $m_vlanModifier2
    lappend DhcpGetRouterResult -vlancount2
    lappend DhcpGetRouterResult $m_vlanCount2

    lappend DhcpGetRouterResult -flaggateway
    lappend DhcpGetRouterResult $m_flagGateway 
    lappend DhcpGetRouterResult -ipv6gateway
    lappend DhcpGetRouterResult [stc::get $m_hIpv62 -Gateway]
    if {[string tolower $m_emulationMode]!="dhcpv6pd"} {
        lappend DhcpGetRouterResult -authprotocol
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -AuthProtocol]
        lappend DhcpGetRouterResult -dhcprealm
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -DhcpRealm]
        lappend DhcpGetRouterResult -enableauth
        lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -EnableAuth]
    }
    lappend DhcpGetRouterResult -enablerebind
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -EnableRebind]
    lappend DhcpGetRouterResult -enablereconfigaccept
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -EnableReconfigAccept]

    lappend DhcpGetRouterResult -enablerenew
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -EnableRenew]
    lappend DhcpGetRouterResult -preferredlifetime
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -PreferredLifeTime]
    lappend DhcpGetRouterResult -rapidcommitmode
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -RapidCommitMode]

    lappend DhcpGetRouterResult -t1timer
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -T1Timer]
    lappend DhcpGetRouterResult -t2timer
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -T2Timer]
    lappend DhcpGetRouterResult -validlifetime
    lappend DhcpGetRouterResult [stc::get $m_hDhcpBlkCfg -ValidLifetime]
    
    if {$m_pdEmulatadDevice!=""} {
        set hEthIIIf [lindex [stc::get $m_pdEmulatadDevice -children-EthIIIf] 0]
        lappend DhcpGetRouterResult -clientmacaddrstart
        lappend DhcpGetRouterResult [stc::get $hEthIIIf -SourceMac]
        lappend DhcpGetRouterResult -clientmacaddrstep
        lappend DhcpGetRouterResult [stc::get $hEthIIIf -SrcMacStep]
    }
    
    if { $args == "" } {
        debugPut "exit the proc of DHCPv6Client::RetrieveRouter" 
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
        debugPut "exit the proc of DHCPv6Client::RetrieveRouter"   
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
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::SetFlap {args} {
   
    debugPut "enter the proc of DHCPv6Client::SetFlap" 
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
    
    debugPut "exit the proc of DHCPv6Client::SetFlap"        
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: StartFlap
#Description: start flap dhcp host 
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::StartFlap {args} {
   
    debugPut "enter the proc of DHCPv6Client::StartFlap"
    
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
    set bindDhcp1 [stc::create Dhcpv6BindCommand -under $loop1 -BlockList $m_hDhcpBlkCfg] 

    set wadtimer [expr $m_wadtimer/1000]
    if {$wadtimer == 0} {
        set wadtimer 1  
    } 
    set waitTime2 [stc::create WaitCommand -under $loop1 -WaitTime $wadtimer]
    switch $type {
        "release" {
            set releaseDhcp1 [stc::create Dhcpv6ReleaseCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
            stc::perform SequencerInsert -CommandList $releaseDhcp1 -CommandParent $loop1
            
        }
        "renew" {
            set renewDhcp1 [stc::create Dhcpv6RenewCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
            stc::perform SequencerInsert -CommandList $renewDhcp1 -CommandParent $loop1
        }
        "abort" {
            set abortDhcp1 [stc::create Dhcpv6AbortCommand -under $loop1 -BlockList $m_hDhcpBlkCfg]
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

    debugPut "exit the proc of DHCPv6Client::StartFlap"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: StopFlap
#Description: stop flap dhcp host 
#Input: none
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::StopFlap {args} {
     
    debugPut "enter the proc of DHCPv6Client::StopFlap"
    
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

    debugPut "exit the proc of DHCPv6Client::StopFlap"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveHostState
#Description: Get host state according to input MAC address
#Input: For the details please refer to the user guide
#Output: none
#Coded by: Andy
#############################################################################
::itcl::body DHCPv6Client::RetrieveHostState {args} {
    debugPut "enter the proc of DHCPv6Client::RetrieveHostState" 
    set args [ConvertAttrToLowerCase $args]
    #Parse FileName parameter
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args [expr $index + 1]]
    }
    #Parse Mac parameter
    set index [lsearch $args -mac]
    if {$index != -1} {
        set Mac [lindex $args [expr $index + 1]] 
        set Mac [regsub -all : $Mac ""]
        set Mac [regsub -all -- - $Mac ""]
        set Mac [regsub -all \\. $Mac ""]
        set args1 [lreplace $args $index [expr $index + 1]]
    }
    
    if {[info exists FileName]} {
        stc::perform Dhcpv6SessionInfo -BlockList $m_hDhcpBlkCfg -FileName $FileName
        
        debugPut "exit the proc of DHCPv6Client::RetrieveHostState"  
        return $::mainDefine::gSuccess
    } else {
        stc::perform Dhcpv6SessionInfo -BlockList $m_hDhcpBlkCfg
    }
    
    if {[info exists Mac]} {
        set hDhcpv6SessionResultsList [stc::get $m_hDhcpBlkCfg -Children-Dhcpv6SessionResults]
        foreach hResults $hDhcpv6SessionResultsList {
            set temp [stc::get $hResults -MacAddr]
            set temp [regsub -all : $temp ""]
            set temp [regsub -all -- - $temp ""]
            set temp [regsub -all \\. $temp ""]
            if {$Mac == $temp} {
                set hDhcpv6SessionResults $hResults
                break
            }
        }
        if {![info exists hDhcpv6SessionResults]} {
            error "The Mac Address $Mac is not exists." 
        }
    } else {
        set hDhcpv6SessionResults [lindex [stc::get $m_hDhcpBlkCfg -Children-Dhcpv6SessionResults] 0]
    }
    set hostState ""
    lappend hostState -Dhcpv6State 
    lappend hostState [stc::get $hDhcpv6SessionResults -Dhcpv6SessionState] 
    lappend hostState -PdState 
    lappend hostState [stc::get $hDhcpv6SessionResults -PdSessionState]  
    lappend hostState -Dhcpv6Ipv6Addr 
    lappend hostState [stc::get $hDhcpv6SessionResults -Dhcpv6Ipv6Addr] 
    lappend hostState -LeaseTimer 
    lappend hostState [stc::get $hDhcpv6SessionResults -Dhcpv6LeaseRx]  
    lappend hostState -PdLeaseTimer 
    lappend hostState [stc::get $hDhcpv6SessionResults -PdLeaseRx] 
    lappend hostState -PdIpv6Addr 
    lappend hostState [stc::get $hDhcpv6SessionResults -PdIpv6Addr]
    lappend hostState -Dhcpv6PrefixLength 
    lappend hostState [stc::get $hDhcpv6SessionResults -Dhcpv6PrefixLength] 
     
    if { $args1 == "" } {
        debugPut "exit the proc of DHCPv6Client::RetrieveHostState" 
        return $hostState
    } else {     
        set hostState [string tolower $hostState]
        array set arr $hostState
        #parray arr
        foreach {name valueVar}  $args1 {   
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
        debugPut "exit the proc of DHCPv6Client::RetrieveHostState"   
        return $::mainDefine::gSuccess     
   } 
}
