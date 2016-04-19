###########################################################################
#                                                                        
#  File Name：PPPoXProtocol.tcl                                                                            
#                  
# 
#  Description：Definition of PPPoE Server、PPPoE Client、PPPoL2TPLAC、PPPoL2TPLNS class
#            and tis methods
# 
#  Author： Shi Yunzhi
#
#  Create Time:  2009.11.17
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################
 
proc SplitWordAndNumber {input} {
    set pos [expr [string length $input] - 1]
    for {set i $pos} {$i >= 0} {incr i -1} {
        set byte [string range $input $i $i]
        if {$byte >= "0" && $byte <= "9"} {
        } else {
            break
        }
    }
    
    set returnList "" 
    set temp1 [string range $input 0 $i]
    lappend returnList $temp1

    set temp2 ""
     
    if {$i !=  $pos } {
        set temp2 [string range $input [expr $i + 1] $pos]
        lappend returnList $temp2
    }  

    return $returnList
}

############################################################################
#APIName: PPPoEConfigVlanIfs
#
#Description: Config PPPoE Vlan If according to input parameter
#
#Input:   args: SetSession parameters
#         m_hHost: PPPoE Host handle
#         Other Vlan parameters:
#         m_upLayerIf: Upper layer interface handle
#         m_hEthIIIf: ETH interface handle
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc PPPoEConfigVlanIfs {args m_hHost m_deviceCount m_vlanType1 m_vlanId1 m_vlanModifier1 m_vlanCount1 \
                         m_vlanType2 m_vlanId2 m_vlanModifier2 m_vlanCount2 m_upLayerIf m_hEthIIIf} {
    set loop 0
    while {[llength $args] == 1 && $loop < 4} {
       set args [eval subst $args ]
       set loop [expr $loop + 1]
    }

    set hVlanList [stc::get $m_hHost -children-VlanIf] 
    if {$hVlanList != ""} {
        #Already configured VLANIF interface
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

            #If VLANIF was not created and SetSession has associated parameter,we need create it manually    
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

::itcl::class PPPoEServer {
    #Variables
    public variable m_hPort ""
    public variable m_hProject ""
    public variable m_portName ""
    public variable m_hostName ""
    public variable m_hHost  ""
    public variable m_hRouter ""
    public variable m_hPppoeSrvCfg ""
    public variable m_hPppoeSrvPeerPool ""
    public variable m_hIpv4If ""
    public variable m_hEthIIIf ""
    public variable m_hPppIf ""
    public variable m_hPppoeIf
    public variable m_flagGateway false

    #PPPoE Server configurations
    public variable m_poolNum 1    
    public variable m_poolName ""
    public variable m_pppoeServiceName "spirent"
    public variable m_acName ""
    public variable m_maxRetryCount 5
    public variable m_sourceMacAddr "00:00:00:c0:00:01"
    public variable m_mru 1492
    public variable m_echoRequestTimer 0
    public variable m_maxConfigCount 10
    public variable m_restartTimer 3
    public variable m_maxTermination 2
    public variable m_maxFailure 5
    public variable m_authenticationRole "sut"
    public variable m_authenUsername "who"
    public variable m_authenPassword "who"
    public variable m_authenDomain "who"
    public variable m_sourceIPAddr "192.0.0.1"
    public variable m_active "true"
    public variable m_connectRate 100
    public variable m_disconnectRate 100
    public variable m_lcpConfigReqTimeout 3
    public variable m_ncpConfigReqTimeout 3
    public variable m_lcpTermReqTimeout 3
    public variable m_chapReplyTimeout 3
    public variable m_papPeerReqTimeout 3

    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1   1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2   1
    public variable m_portType "ethernet"
    
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv4 portType} {    
        set m_hPort $hPort
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv4If $hipv4
        set m_portType $portType
        
        lappend ::mainDefine::gObjectNameList $this

        #Create PPPoE Server、Peer Pool
        set pppoxPortCfg [lindex [stc::get $m_hPort -children-PppoxPortConfig] 0]
        stc::config $pppoxPortCfg -EmulationType "SERVER"
        
        set m_hPppoeSrvCfg [stc::create "PppoeServerBlockConfig" -under $m_hHost -Name $m_hostName ]
        set m_hPppoeSrvPeerPool [lindex [stc::get $m_hPppoeSrvCfg -children-PppoeServerIpv4PeerPool] 0]        
        
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
        
        #Create PPP & PPPoE interface
        set m_hPppIf [stc::create "PppIf" -under $m_hHost ]
        set m_hPppoeIf [stc::create "PppoeIf" -under $m_hHost ]
        
        #Build relationship between objects         
        stc::config $m_hIpv4If -StackedOnEndpoint-targets " $m_hPppIf "
        stc::config $m_hPppIf -StackedOnEndpoint-targets " $m_hPppoeIf "
        set hVlanList [stc::get $hHost -children-VlanIf]
        if {$hVlanList != ""} {
            foreach vlanIf $hVlanList {
                stc::config $vlanIf -IdStep "0" -IdList ""
            }
            set listLen [llength $hVlanList]
            set upVlanIf [lindex $hVlanList [expr $listLen -1]]
            stc::config $m_hPppoeIf -StackedOnEndpoint-targets " $upVlanIf "
        } else {
            stc::config $m_hPppoeIf -StackedOnEndpoint-targets " $m_hEthIIIf "
        }
        stc::config $m_hPppoeSrvCfg -UsesIf-targets " $m_hIpv4If $m_hPppoeIf "
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]              
    }

    #Methods
    public method SetSession
    public method RetrieveRouter
    public method RetrieveRouterStats
    public method Enable
    public method Disable
    public method RetryFailedSession
}

::itcl::class PPPoEClient {
    #Variables
    public variable m_hPort ""
    public variable m_hProject ""
    public variable m_portName ""
    public variable m_hostName ""    
    public variable m_hHost  ""
    public variable m_hRouter ""
    public variable m_hPppoeClientCfg ""
    public variable m_hIpv4If ""
    public variable m_hEthIIIf ""
    public variable m_hPppIf ""
    public variable m_hPppoeIf

    #PPPoE Client configurations
    public variable m_count 1
    public variable m_poolName ""
    public variable m_active true
    public variable m_localMac "00:00:00:22:00:01"
    public variable m_localMacModifier "00:00:00:00:00:01"    
    public variable m_flagGateway false
    public variable m_ipv4Gateway ""
    public variable m_flagStartOnAble true
    public variable m_maxConnectCount 1
    public variable m_flagPPPAgentCircuitId false
    public variable m_agentCircuitId "circuit @s"
    public variable m_flagPPPAgentRemoteId false 
    public variable m_remoteAgentCircuitId "remote @m-@p-@b" 
    public variable m_encapsulation1 ""
    public variable m_encapsulation2 ""
    public variable m_pppoeServerName "spirent"
    public variable m_maxConfigureAttempts 10
    public variable m_maxTerminateAttempts 2
    public variable m_maximumFailures 5
    public variable m_flagUseInterfaceMRU true
    public variable m_mru 1492
    public variable m_flagEnableIPCP true
    public variable m_advertisedIPAddress "0.0.0.0"
    public variable m_authenticationRole "papsenderorchapresponder"
    public variable m_username "who"
    public variable m_password "who"
    public variable m_usernameMode "fixed"
    public variable m_usernameCount 1
    public variable m_usernameStep 1
    public variable m_passwordMode "fixed"
    public variable m_passwordCount 1
    public variable m_passwordStep 1
    public variable m_connectRate 100
    public variable m_disconnectRate 100
    public variable m_lcpConfigReqTimeout 3
    public variable m_ncpConfigReqTimeout 3
    public variable m_lcpTermReqTimeout 3
    public variable m_chapChalReqTimeout 3
    public variable m_papReqTimeout 3
    public variable m_chapAckTimeout 3

    public variable m_pppoERetransmitTimer 1
    public variable m_pppoEMaxRetransmitCount 5

    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1   1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2   1
    public variable m_portType "ethernet"
    
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv4 portType} {    
        set m_hPort $hPort
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv4If $hipv4
        set m_portType $portType
        lappend ::mainDefine::gObjectNameList $this

        #Create PPPoE Client、Peer Pool
        set pppoxPortCfg [lindex [stc::get $m_hPort -children-PppoxPortConfig] 0]
        stc::config $pppoxPortCfg -EmulationType "CLIENT"
        set m_hPppoeClientCfg [stc::create "PppoeClientBlockConfig" -under $m_hHost -Name $m_hostName ]        
        
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
        
        #Crate PPP & PPPoE interface
        set m_hPppIf [stc::create "PppIf" -under $m_hHost ]
        set m_hPppoeIf [stc::create "PppoeIf" -under $m_hHost ]
        
        #Build relationship between objects
        stc::config $m_hIpv4If -StackedOnEndpoint-targets " $m_hPppIf "        
        stc::config $m_hPppIf -StackedOnEndpoint-targets " $m_hPppoeIf "
        set hVlanList [stc::get $hHost -children-VlanIf]
        if {$hVlanList != ""} {
            foreach vlanIf $hVlanList {
                stc::config $vlanIf -IdStep "0" -IdList ""
            }
            set listLen [llength $hVlanList]
            set upVlanIf [lindex $hVlanList [expr $listLen -1]]
            stc::config $m_hPppoeIf -StackedOnEndpoint-targets " $upVlanIf "
        } else {
            stc::config $m_hPppoeIf -StackedOnEndpoint-targets " $m_hEthIIIf "
        }
        stc::config $m_hPppoeClientCfg -UsesIf-targets " $m_hIpv4If $m_hPppoeIf "
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]              
    }

    #Methods
    public method SetSession
    public method Open
    public method Close
    public method RetrieveRouter
    public method RetrieveRouterStats
    public method CancelAttempt
    public method Abort
    public method Enable
    public method Disable
    public method RetryFailedPeer
    public method RetrieveHostState
}

::itcl::class PppoL2tpBlock {
    #Variables
    public variable m_blockType ""
    public variable m_hPort ""
    public variable m_hProject ""
    public variable m_portName ""
    public variable m_hostName ""    
    public variable m_hHost  ""
    public variable m_hRouter ""
    public variable m_hL2tpBlkCfg ""
    public variable m_hPppoL2tpBlock ""
    public variable m_hIpv4If ""
    public variable m_hIpv4If2 ""
    public variable m_hEthIIIf ""
    public variable m_hPppIf ""
    public variable m_hL2tpIf

    #PPPoL2TP Block configurations
    public variable m_testIpAddress "192.1.1.1"
    public variable m_sutIpAddress  "192.1.1.2"
    public variable m_pooLNumber 1
    public variable m_tunnelCount 1
    public variable m_poolName ""
    public variable m_peerPerTunnel 1    
    public variable m_helloTimer 60
    public variable m_maxTxCount 5
    public variable m_receiveWinSize 4
    public variable m_sourceUdpPort 1701
    public variable m_nameOfDevice "SpirentTest"
    public variable m_echoRequestTimer 0
    public variable m_maxConfigCount 10
    public variable m_restartTimer 3
    public variable m_flagACCM  false
    public variable m_maxTermination 2
    public variable m_maxFailure 5
    public variable m_authenticationRole "sut"
    public variable m_username "who"
    public variable m_password "who"
    public variable m_startIpAddr "192.1.1.1" 
    public variable m_modifier 1
    public variable m_count 1
    public variable m_connectRate 100
    public variable m_disconnectRate 100
    public variable m_enableDutAuthentication "false"
    public variable m_shareSecret "spirent"
    public variable m_l2tpHostName "sever.spirent.com"
    public variable m_localIpAddr "192.85.1.3"

    public variable m_vlanType1 ""
    public variable m_vlanId1 ""
    public variable m_vlanModifier1 ""
    public variable m_vlanCount1   1
    public variable m_vlanType2 ""
    public variable m_vlanId2 ""
    public variable m_vlanModifier2 ""
    public variable m_vlanCount2   1
    public variable m_portType "ethernet"
    
    #Constructor
    constructor {hostName hHost hPort portName hProject hipv4 blockType portType} {    
        set m_hPort $hPort
        set m_hProject $hProject
        set m_hHost $hHost
        set m_hRouter $hHost
        set m_hostName $hostName
        set m_portName $portName
        set m_hIpv4If $hipv4
        set m_blockType $blockType
        set m_portType $portType
        
        lappend ::mainDefine::gObjectNameList $this

        set pppoxPortCfg [lindex [stc::get $m_hPort -children-PppoxPortConfig] 0]
        stc::config $pppoxPortCfg -EmulationType "PPPOL2TP"
        set l2tpPortCfg [lindex [stc::get $m_hPort -children-L2tpPortConfig] 0]
        if {$m_blockType == "pppol2tplns"} {
            stc::config $l2tpPortCfg -L2tpNodeType "LNS" 
        } else {
            stc::config $l2tpPortCfg -L2tpNodeType "LAC" 
        }
        
        #Create l2tp block, Pppol2tp client or server
        set m_hL2tpBlkCfg [stc::create "L2tpv2BlockConfig" -under $m_hHost ]
        if {$blockType == "pppol2tplns"} {
            set m_hPppoL2tpBlock [stc::create "PppoL2tpv2ServerBlockConfig" -under $m_hHost ]
        } else {
            set m_hPppoL2tpBlock [stc::create "PppoL2tpv2ClientBlockConfig" -under $m_hHost ]
        }
        
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
 
        #Create PPP, l2tp, ipv4 interface
        set m_hPppIf [stc::create "PppIf" -under $m_hHost ]
        set m_hL2tpIf [stc::create "L2tpv2If" -under $m_hHost ]
        set m_hIpv4If2 [stc::create "Ipv4If" -under $m_hHost ]
        
        #Build relationship between objects
        stc::config $m_hIpv4If2 -StackedOnEndpoint-targets " $m_hPppIf "        
        stc::config $m_hPppIf -StackedOnEndpoint-targets " $m_hL2tpIf "
        stc::config $m_hL2tpIf -StackedOnEndpoint-targets " $m_hIpv4If "
        stc::config $m_hL2tpBlkCfg -UsesIf-targets " $m_hL2tpIf "
        stc::config $m_hPppoL2tpBlock -UsesIf-targets " $m_hIpv4If2 " 

        stc::config $hHost -TopLevelIf-targets " $m_hIpv4If2 "
        stc::config $hHost -PrimaryIf-targets " $m_hIpv4If2 "
    }

    #Constructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]              
    }

    #Methods
    public method SetSession
    public method Open
    public method Close
    public method RetrieveRouter
    public method RetrieveRouterStats
    public method CancelAttempt
    public method Abort
    public method Enable
    public method Disable
    public method RetryFailedPeer
}

#----------------------------PPPoE Server API------------------------------
############################################################################
#APIName: SetSession
#Description: Config PPPoE Server attributes
#Input: For the details please refer to the user guide
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::SetSession {args} {
    
    debugPut "enter the proc of PPPoE Server::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    
    #Parse PoolNum parameter
    set index [lsearch $args -poolnum]
    if {$index != -1} {
        set PoolNum [lindex $args [expr $index + 1]]
        set m_poolNum $PoolNum
    } 
    #Parse PoolName parameter
    set index [lsearch $args -poolname]
    if {$index != -1} {
        set PoolName [lindex $args [expr $index + 1]]
        set m_poolName $PoolName
    }
    #Parse PPPoEServiceName parameter
    set index [lsearch $args -pppoeservicename]
    if {$index != -1} {
        set PPPoEServiceName [lindex $args [expr $index + 1]]
        set m_pppoeServiceName $PPPoEServiceName
    } 
    #Parse ACName parameter
    set index [lsearch $args -acname]
    if {$index != -1} {
        set ACName [lindex $args [expr $index + 1]]
        set m_acName $ACName
    }
    #Parse MaxRetryCount  parameter
    set index [lsearch $args -maxretrycount]
    if {$index != -1} {
        set MaxRetryCount [lindex $args [expr $index + 1]]
        set m_maxRetryCount $MaxRetryCount
    }
    #Parse SourceMacAddr parameter
    set index [lsearch $args -sourcemacaddr]
    if {$index != -1} {
        set SourceMacAddr [lindex $args [expr $index + 1]]
        set m_sourceMacAddr $SourceMacAddr
    }  
    #Parse MRU parameter
    set index [lsearch $args -mru]
    if {$index != -1} {
        set MRU [lindex $args [expr $index + 1]]
        set m_mru $MRU
    } 
    #Parse EchoRequestTimer parameter
    set index [lsearch $args -echorequesttimer]
    if {$index != -1} {
        set EchoRequestTimer [lindex $args [expr $index + 1]]
        set m_echoRequestTimer $EchoRequestTimer
    } 
    #Parse MaxConfigCount parameter
    set index [lsearch $args -maxconfigcount]
    if {$index != -1} {
        set MaxConfigCount [lindex $args [expr $index + 1]]
        set m_maxConfigCount $MaxConfigCount
    } 
    #Parse RestartTimer parameter
    set index [lsearch $args -restarttimer]
    if {$index != -1} {
        set RestartTimer [lindex $args [expr $index + 1]]
        set m_restartTimer $RestartTimer
    } 
    #Parse MaxTermination parameter
    set index [lsearch $args -maxtermination]
    if {$index != -1} {
        set MaxTermination [lindex $args [expr $index + 1]]
        set m_maxTermination $MaxTermination
    } 
    #Parse MaxFailure parameter
    set index [lsearch $args -maxfailure]
    if {$index != -1} {
        set MaxFailure [lindex $args [expr $index + 1]]
        set m_maxFailure $MaxFailure
    } 
    #Parse AuthenticationRole parameter
    set index [lsearch $args -authenticationrole]
    if {$index != -1} {
        set AuthenticationRole [lindex $args [expr $index + 1]]
        set AuthenticationRole [string tolower $AuthenticationRole]
        set m_authenticationRole $AuthenticationRole
    } 
    #Parse AuthenUsername parameter
    set index [lsearch $args -authenusername]
    if {$index != -1} {
        set AuthenUsername [lindex $args [expr $index + 1]]
        set m_authenUsername $AuthenUsername
    } 
    #Parse AuthenPassword parameter
    set index [lsearch $args -authenpassword]
    if {$index != -1} {
        set AuthenPassword [lindex $args [expr $index + 1]]
        set m_authenPassword $AuthenPassword
    } 
    #Parse AuthenDomain parameter
    set index [lsearch $args -authendomain]
    if {$index != -1} {
        set AuthenDomain [lindex $args [expr $index + 1]]
        set m_authenDomain $AuthenDomain
    } 
    #Parse SourceIPAddr parameter
    set index [lsearch $args -sourceipaddr]
    if {$index != -1} {
        set SourceIPAddr [lindex $args [expr $index + 1]]
        set m_sourceIPAddr $SourceIPAddr
    }
    #Parse Active parameter
    set index [lsearch $args -active]
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_active $Active
    } 
    #Parse ConnectRate parameter
    set index [lsearch $args -connectrate]
    if {$index != -1} {
        set ConnectRate [lindex $args [expr $index + 1]]      
        set m_connectRate $ConnectRate
    }
    #Parse DisConnectRate parameter
    set index [lsearch $args -disconnectrate]
    if {$index != -1} {
        set DisConnectRate [lindex $args [expr $index + 1]]      
        set m_disconnectRate $DisConnectRate
    }
    #Parse LcpConfigReqTimeout parameter
    set index [lsearch $args -lcpconfigreqtimeout]
    if {$index != -1} {
        set LcpConfigReqTimeout [lindex $args [expr $index + 1]]      
        set m_lcpConfigReqTimeout $LcpConfigReqTimeout
    }
    #Parse NcpConfigReqTimeout parameter
    set index [lsearch $args -ncpconfigreqtimeout]
    if {$index != -1} {
        set NcpConfigReqTimeout [lindex $args [expr $index + 1]]      
        set m_ncpConfigReqTimeout $NcpConfigReqTimeout
    }
    #Parse LcpTermReqTimeout parameter
    set index [lsearch $args -lcptermreqtimeout]
    if {$index != -1} {
        set LcpTermReqTimeout [lindex $args [expr $index + 1]]      
        set m_lcpTermReqTimeout $LcpTermReqTimeout
    }
    #Parse ChapReplyTimeout parameter
    set index [lsearch $args -chapreplytimeout]
    if {$index != -1} {
        set ChapReplyTimeout [lindex $args [expr $index + 1]]      
        set m_chapReplyTimeout $ChapReplyTimeout
    }
    #Parse PapPeerReqTimeout parameter
    set index [lsearch $args -pappeerreqtimeout]
    if {$index != -1} {
        set PapPeerReqTimeout [lindex $args [expr $index + 1]]      
        set m_papPeerReqTimeout $PapPeerReqTimeout
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

    #Configure PPPoE VLAN interface(support 2 VLANs)
    PPPoEConfigVlanIfs $args $m_hHost $m_poolNum $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1 \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2 $m_hPppoeIf $m_hEthIIIf
    
    set connectRate $m_connectRate
    set disconnectRate $m_disconnectRate

    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    stc::config $hPppoxPortCfg -ConnectRate $connectRate -DisconnectRate $disconnectRate 
    
    switch $m_authenticationRole {
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
            error "Wrong authenticationRole,should be one of pap, chap or sut."
        }
    }

    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv4If
    }
   
    #Configure PPPoE Server
    stc::config $m_hHost -DeviceCount $m_poolNum
    if {$m_portType == "ethernet"} {
        stc::config $m_hEthIIIf -SourceMac $m_sourceMacAddr
    }
    
    stc::config $m_hPppoeSrvCfg -ServiceName $m_pppoeServiceName \
                    -MruSize $m_mru \
                    -EnableEchoRequest "TRUE" \
                    -EchoRequestGenFreq $m_echoRequestTimer \
                    -LcpConfigRequestMaxAttempts $m_maxConfigCount \
                    -NcpConfigRequestMaxAttempts $m_maxConfigCount \
                    -LcpConfigRequestTimeout $m_restartTimer \
                    -LcpTermRequestTimeout $m_restartTimer \
                    -NcpConfigRequestTimeout $m_restartTimer \
                    -LcpTermRequestMaxAttempts $m_maxTermination \
                    -MaxNaks $m_maxFailure \
                    -Authentication $Authentication \
                    -Username $m_authenUsername \
                    -Password $m_authenPassword \
                    -Active $m_active \
                    -ChapReplyTimeout $m_chapReplyTimeout  \
                    -PapPeerRequestTimeout $m_papPeerReqTimeout \
                    -LcpConfigRequestTimeout $m_lcpConfigReqTimeout \
                    -LcpTermRequestTimeout $m_lcpTermReqTimeout \
                    -NcpConfigRequestTimeout $m_ncpConfigReqTimeout 
                    
    if {[info exists ACName]} {
        stc::config $m_hPppoeSrvCfg -AcName $ACName
    }

    stc::config $m_hPppoeSrvPeerPool -StartIpList $m_sourceIPAddr 

    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of PPPoEServer::SetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RetrieveRouter
#Description: Retrieve PPPoE server attributes
#Input: For the details please refer to the user guide.
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::RetrieveRouter {args} {
   
    debugPut "enter the proc of PPPoE Server::RetrieveRouter"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    set PppoeGetRouterResult ""
    lappend PppoeGetRouterResult -poolnum
    lappend PppoeGetRouterResult [stc::get $m_hHost -DeviceCount]
    lappend PppoeGetRouterResult -pppoeservicename
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -ServiceName]
    lappend PppoeGetRouterResult -acname
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -AcName]
    if {$m_portType == "ethernet"} {
        lappend PppoeGetRouterResult -sourcemacaddr
        lappend PppoeGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
    }
    lappend PppoeGetRouterResult -poolname
    lappend PppoeGetRouterResult $m_poolName
    lappend PppoeGetRouterResult -mru
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -MruSize]
    lappend PppoeGetRouterResult -echorequesttimer
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -EchoRequestGenFreq]
    lappend PppoeGetRouterResult -maxconfigcount
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -LcpConfigRequestMaxAttempts]
    lappend PppoeGetRouterResult -restarttimer
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -LcpConfigRequestTimeout]
    lappend PppoeGetRouterResult -maxtermination
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -LcpTermRequestMaxAttempts]
    lappend PppoeGetRouterResult -maxfailure
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -MaxNaks]
    lappend PppoeGetRouterResult -authenticationrole
    set authRole [stc::get $m_hPppoeSrvCfg -Authentication]
    set authRole [string tolower $authRole] 
    switch $authRole {
        "pap" {
            set Authentication PAP
        }
        "chap_md5" {
            set Authentication CHAP
        }
        "auto" {
            set Authentication SUT
        }        
    }
    lappend PppoeGetRouterResult $authRole
    lappend PppoeGetRouterResult -authenusername
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -Username]
    lappend PppoeGetRouterResult -authenpassword
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -Password]
    lappend PppoeGetRouterResult -sourceipaddr
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvPeerPool -StartIpList]
    lappend PppoeGetRouterResult -active
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -Active]
    lappend PppoeGetRouterResult -state
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -BlockState]
    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    lappend PppoeGetRouterResult -connectrate 
    set rate [stc::get $hPppoxPortCfg -ConnectRate]
    lappend PppoeGetRouterResult $rate
    lappend PppoeGetRouterResult -disconnectrate  
    set rate [stc::get $hPppoxPortCfg -DisconnectRate ]
    lappend PppoeGetRouterResult $rate
    lappend PppoeGetRouterResult -chapreplytimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -ChapReplyTimeout ]
    lappend PppoeGetRouterResult -pappeerreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -PapPeerRequestTimeout]
    lappend PppoeGetRouterResult -lcpconfigreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -LcpConfigRequestTimeout ]
    lappend PppoeGetRouterResult -ncpconfigreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -NcpConfigRequestTimeout ]
    lappend PppoeGetRouterResult -lcptermreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeSrvCfg -LcpTermRequestTimeout ]

    lappend PppoeGetRouterResult -vlantype1
    lappend PppoeGetRouterResult $m_vlanType1
    lappend PppoeGetRouterResult -vlanid1
    lappend PppoeGetRouterResult $m_vlanId1
    lappend PppoeGetRouterResult -vlanidmodifier1
    lappend PppoeGetRouterResult $m_vlanModifier1
    lappend PppoeGetRouterResult -vlanidcount1
    lappend PppoeGetRouterResult $m_vlanCount1

    lappend PppoeGetRouterResult -vlantype2
    lappend PppoeGetRouterResult $m_vlanType2
    lappend PppoeGetRouterResult -vlanid2
    lappend PppoeGetRouterResult $m_vlanId2
    lappend PppoeGetRouterResult -vlanidmodifier2
    lappend PppoeGetRouterResult $m_vlanModifier2
    lappend PppoeGetRouterResult -vlanidcount2
    lappend PppoeGetRouterResult $m_vlanCount2

    if { $args == "" } {
        debugPut "exit the proc of PPPoEServer::RetrieveRouter" 
        return $PppoeGetRouterResult
    } else {     
       # set PppoeGetRouterResult [string tolower $PppoeGetRouterResult]
        array set arr $PppoeGetRouterResult
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
        debugPut "exit the proc of PPPoEServer::RetrieveRouter"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Retrieve PPPoE server statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::RetrieveRouterStats {args} {

    debugPut "enter the proc of PPPoE Server::RetrieveRouterStats"
    #Convert attribute of input parameters to lower case
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
    set pppoeServerResultHandle [$gChassisName cget -m_pppoeServerResultHandle ]
  
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $pppoeServerResultHandle]
    } err]} {
        return $errorCode
    }

    set hPppoeServerResults [stc::get $m_hPppoeSrvCfg -children-PppoeServerBlockResults]
    set PppoeServerStats ""

    lappend PppoeServerStats -PadiRxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -RxPadiCount]
    lappend PppoeServerStats -PadrRxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -RxPadrCount]
    lappend PppoeServerStats -PadtRxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -RxPadtCount]
    lappend PppoeServerStats -PadoTxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -TxPadoCount]
    lappend PppoeServerStats -PadsTxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -TxPadsCount]
    lappend PppoeServerStats -PadtTxCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -TxPadtCount]    
    lappend PppoeServerStats -SessionFailedCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -FailedConnectCount]
    lappend PppoeServerStats -SessionMaxEstTime 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -MaxSetupTime]
    lappend PppoeServerStats -SessionMinEstTime 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -MinSetupTime]
    lappend PppoeServerStats -SessionAveEstTime 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -AvgSetupTime]
    lappend PppoeServerStats -SessionRateAve 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -SuccSetupRate]

    lappend PppoeServerStats -SessionEstabilshedCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -SessionsUp]
    lappend PppoeServerStats -SessionAttempedCount 
    lappend PppoeServerStats [stc::get $hPppoeServerResults -Sessions]

    if { $args == "" } {
        debugPut "exit the proc of PPPoEServer::RetrieveRouterStats" 
        return $PppoeServerStats
    } else {     
        set PppoeServerStats [string tolower $PppoeServerStats]
        array set arr $PppoeServerStats
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
        debugPut "exit the proc of PPPoEServer::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: Enable
#Description: Enable PPPoE server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::Enable {args} {
    
    debugPut "enter the proc of PPPoEServer::Enable"    

    #Enable PPPoE Server
    stc::perform DeviceStart -DeviceList $m_hHost
  
    if {$::mainDefine::gSTCVersion == "2.31"} {
       stc::perform PppoxConnect -BlockList $m_hPppoeSrvCfg
    }

    debugPut "exit the proc of PPPoEServer::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Disable PPPoE server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::Disable {args} {
    
    debugPut "enter the proc of PPPoEServer::Disable"    

    #Stop PPPoE Server
    stc::perform DeviceStop -DeviceList $m_hHost

    if {$::mainDefine::gSTCVersion == "2.31"} {
       stc::perform PppoxDisconnect -BlockList $m_hPppoeSrvCfg
    }

    debugPut "exit the proc of PPPoEServer::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetryFailedSession
#Description: retry pppoe session
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEServer::RetryFailedSession {args} {
    
    debugPut "enter the proc of PPPoEServer::RetryFailedSession"    

    #retry session
    stc::perform PppoxRetry -BlockList $m_hPppoeSrvCfg

    debugPut "exit the proc of PPPoEServer::RetryFailedSession"  
    return $::mainDefine::gSuccess 
}

#---------------------------- PPPoE client API ---------------------------------
############################################################################
#APIName: SetSession
#Description: Configure PPPoE Client Router
#Input: For the details please refer to the user guide.
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::SetSession {args} {
    
    debugPut "enter the proc of PPPoEClient::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    
    #Parse Count parameter
    set index [lsearch $args -count]
    if {$index != -1} {
        set Count [lindex $args [expr $index + 1]]
        set m_count $Count
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
    #Parse LocalMac parameter
    set index [lsearch $args -localmac]
    if {$index != -1} {
        set LocalMac [lindex $args [expr $index + 1]]
        set m_localMac $LocalMac
    } 
    #Parse LocalMacModifier parameter
    set index [lsearch $args -localmacmodifier]
    if {$index != -1} {
        set LocalMacModifier [lindex $args [expr $index + 1]]
        set m_localMacModifier $LocalMacModifier
    } 
    #Parse FlagGateway parameter
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
    
    #Parse FlagStartOnAble parameter
    set index [lsearch $args -flagstartonable]
    if {$index != -1} {
        set FlagStartOnAble [lindex $args [expr $index + 1]]
        set m_flagStartOnAble $FlagStartOnAble
    } 
    #Parse MaxConnectCount parameter
    set index [lsearch $args -maxconnectcount]
    if {$index != -1} {
        set MaxConnectCount [lindex $args [expr $index + 1]]
        set m_maxConnectCount $MaxConnectCount
    } 
    #Parse FlagPPPAgentCircuitId parameter
    set index [lsearch $args -flagpppagentcircuitid]
    if {$index != -1} {
        set FlagPPPAgentCircuitId [lindex $args [expr $index + 1]]
        set FlagPPPAgentCircuitId [string tolower $FlagPPPAgentCircuitId]
        set m_flagPPPAgentCircuitId $FlagPPPAgentCircuitId
    } 
    #Parse AgentCircuitId parameter
    set index [lsearch $args -agentcircuitid]
    if {$index != -1} {
        set AgentCircuitId [lindex $args [expr $index + 1]]
        set m_agentCircuitId $AgentCircuitId
    } 
    #Parse FlagPPPAgentRemoteId parameter
    set index [lsearch $args -flagpppagentremoteid]
    if {$index != -1} {
        set FlagPPPAgentRemoteId [lindex $args [expr $index + 1]]
        set FlagPPPAgentRemoteId [string tolower $FlagPPPAgentRemoteId]
        set m_flagPPPAgentRemoteId $FlagPPPAgentRemoteId
    } 
    #Parse RemoteAgentCircuitId parameter
    set index [lsearch $args -remoteagentcircuitid]
    if {$index != -1} {
        set RemoteAgentCircuitId [lindex $args [expr $index + 1]]
        set m_remoteAgentCircuitId $RemoteAgentCircuitId
    } 
    #Parse Encapsulation1 parameter
    set index [lsearch $args -encapsulation1]
    if {$index != -1} {
        set Encapsulation1 [lindex $args [expr $index + 1]]
        set m_encapsulation1 $Encapsulation1
    } 
    #Parse Encapsulation2 parameter
    set index [lsearch $args -encapsulation2]
    if {$index != -1} {
        set Encapsulation2 [lindex $args [expr $index + 1]]
        set m_encapsulation2 $Encapsulation2
    }
    #Parse PPPoEServerName parameter
    set index [lsearch $args -pppoeservername]
    if {$index != -1} {
        set PPPoEServerName [lindex $args [expr $index + 1]]
        set m_pppoeServerName $PPPoEServerName
    } 
    #Parse MaxConfigureAttempts parameter
    set index [lsearch $args -maxconfigureattempts]
    if {$index != -1} {
        set MaxConfigureAttempts [lindex $args [expr $index + 1]]
        set m_maxConfigureAttempts $MaxConfigureAttempts
    } 
    #Parse MaxTerminateAttempts parameter
    set index [lsearch $args -maxterminateattempts]
    if {$index != -1} {
        set MaxTerminateAttempts [lindex $args [expr $index + 1]]
        set m_maxTerminateAttempts $MaxTerminateAttempts 
    } 
    #Parse MaximumFailures parameter
    set index [lsearch $args -maximumfailures]
    if {$index != -1} {
        set MaximumFailures [lindex $args [expr $index + 1]]
        set m_maximumFailures $MaximumFailures
    } 
    #Parse FlagUseInterfaceMRU parameter
    set index [lsearch $args -flaguseinterfacemru]
    if {$index != -1} {
        set FlagUseInterfaceMRU [lindex $args [expr $index + 1]]
        set $FlagUseInterfaceMRU [string tolower $FlagUseInterfaceMRU]
        set m_flagUseInterfaceMRU $FlagUseInterfaceMRU
        if {$m_flagUseInterfaceMRU == "enable"} {
            set m_flagUseInterfaceMRU true
        } elseif {$m_flagUseInterfaceMRU == "disable"} {
            set m_flagUseInterfaceMRU false 
        }        
    }
    #Parse MRU parameter
    set index [lsearch $args -mru]
    if {$index != -1} {
        set MRU [lindex $args [expr $index + 1]]
        set m_mru $MRU
    } 
    #Parse FlagEnableIPCP parameter
    set index [lsearch $args -flagenableipcp]
    if {$index != -1} {
        set FlagEnableIPCP [lindex $args [expr $index + 1]]
        set m_flagEnableIPCP $FlagEnableIPCP
    } 
    #Parse AdvertisedIPAddress parameter
    set index [lsearch $args -advertisedipaddress]
    if {$index != -1} {
        set AdvertisedIPAddress [lindex $args [expr $index + 1]]
        set m_advertisedIPAddress $AdvertisedIPAddress
    } 
    #Parse AuthenticationRole parameter
    set index [lsearch $args -authenticationrole]
    if {$index != -1} {
        set AuthenticationRole [lindex $args [expr $index + 1]]
        set AuthenticationRole [string tolower $AuthenticationRole]
        set m_authenticationRole $AuthenticationRole
    } 
    #Parse Username parameter
    set index [lsearch $args -username]
    if {$index != -1} {
        set Username [lindex $args [expr $index + 1]]        
        set m_username $Username
    }
    #Parse Password parameter
    set index [lsearch $args -password]
    if {$index != -1} {
        set Password [lindex $args [expr $index + 1]]        
        set m_password $Password
    }
    #Parse UsernameMode parameter
    set index [lsearch $args -usernamemode]
    if {$index != -1} {
        set UsernameMode [lindex $args [expr $index + 1]]
        set UsernameMode [string tolower $UsernameMode]
        set m_usernameMode $UsernameMode
    } 
    #Parse UsernameCount parameter
    set index [lsearch $args -usernamecount]
    if {$index != -1} {
        set UsernameCount [lindex $args [expr $index + 1]]
        set m_usernameCount $UsernameCount
    } 
    #Parse UsernameStep parameter
    set index [lsearch $args -usernamestep]
    if {$index != -1} {
        set UsernameStep [lindex $args [expr $index + 1]]
        set m_usernameStep $UsernameStep
    } 
    #Parse PasswordMode parameter
    set index [lsearch $args -passwordmode]
    if {$index != -1} {
        set PasswordMode [lindex $args [expr $index + 1]]
        set PasswordMode [string tolower $PasswordMode]
        set m_passwordMode $PasswordMode
    } 
    #Parse PasswordCount parameter
    set index [lsearch $args -passwordcount]
    if {$index != -1} {
        set PasswordCount [lindex $args [expr $index + 1]]
        set m_passwordCount $PasswordCount
    } 
    #Parse PasswordStep parameter
    set index [lsearch $args -passwordstep]
    if {$index != -1} {
        set PasswordStep [lindex $args [expr $index + 1]]
        set m_passwordStep $PasswordStep
    } 

    #Parse ConnectRate parameter
    set index [lsearch $args -connectrate]
    if {$index != -1} {
        set ConnectRate [lindex $args [expr $index + 1]]      
        set m_connectRate $ConnectRate
    }
    #Parse DisConnectRate parameter
    set index [lsearch $args -disconnectrate]
    if {$index != -1} {
        set DisConnectRate [lindex $args [expr $index + 1]]      
        set m_disconnectRate $DisConnectRate
    }
    #Parse LcpConfigReqTimeout parameter
    set index [lsearch $args -lcpconfigreqtimeout]
    if {$index != -1} {
        set LcpConfigReqTimeout [lindex $args [expr $index + 1]]      
        set m_lcpConfigReqTimeout $LcpConfigReqTimeout
    }
    #Parse NcpConfigReqTimeout parameter
    set index [lsearch $args -ncpconfigreqtimeout]
    if {$index != -1} {
        set NcpConfigReqTimeout [lindex $args [expr $index + 1]]      
        set m_ncpConfigReqTimeout $NcpConfigReqTimeout
    }
    #Parse LcpTermReqTimeout parameter
    set index [lsearch $args -lcptermreqtimeout]
    if {$index != -1} {
        set LcpTermReqTimeout [lindex $args [expr $index + 1]]      
        set m_lcpTermReqTimeout $LcpTermReqTimeout
    }
    #Parse ChapChalReqTimeout parameter
    set index [lsearch $args -chapchalreqtimeout]
    if {$index != -1} {
        set ChapChalReqTimeout [lindex $args [expr $index + 1]]      
        set m_chapChalReqTimeout $ChapChalReqTimeout
    }
    #Parse PapReqTimeout parameter
    set index [lsearch $args -papreqtimeout]
    if {$index != -1} {
        set PapReqTimeout [lindex $args [expr $index + 1]]      
        set m_papReqTimeout $PapReqTimeout
    }
    #Parse ChapAckTimeout parameter
    set index [lsearch $args -chapacktimeout]
    if {$index != -1} {
        set ChapAckTimeout [lindex $args [expr $index + 1]]      
        set m_chapAckTimeout $ChapAckTimeout
    }
  
    #Parse PPPoERetransmitTimer parameter
    set index [lsearch $args -pppoeretransmittimer]
    if {$index != -1} {
        set PPPoERetransmitTimer [lindex $args [expr $index + 1]]      
        set m_pppoERetransmitTimer $PPPoERetransmitTimer
    }

    #Parse PPPoEMaxRetransmitCount parameter
    set index [lsearch $args -pppoemaxretransmitcount]
    if {$index != -1} {
        set PPPoEMaxRetransmitCount [lindex $args [expr $index + 1]]      
        set m_pppoEMaxRetransmitCount $PPPoEMaxRetransmitCount
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

    #Parse VlanIdCount1 parameter
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

    #Configure PPPoE VLAN interface(support 2 VLANs)
    PPPoEConfigVlanIfs $args $m_hHost $m_count $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1 \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2 $m_hPppoeIf $m_hEthIIIf

    set connectRate $m_connectRate
    set disconnectRate $m_disconnectRate

    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    stc::config $hPppoxPortCfg -ConnectRate $connectRate -DisconnectRate $disconnectRate

    if {$m_usernameMode != "fixed"} {
        set userNameList [split $m_username "@"]
        set part1 [lindex $userNameList 0]
        set part2 [lindex $userNameList 1]
        set start 1
       
        set retList [SplitWordAndNumber $part1]
        set part1 [lindex $retList 0]
        set temp [lindex $retList 1]

        if {$temp != ""} {
            set start $temp
        } 

        if {$m_usernameMode == "decrement"} {
            set start [expr $start - $m_usernameCount * $m_usernameStep + 1]
            if {$start < 0} {
                set start 0 
            } 
        } 
     
        if {$part2 == ""} {
           set username "$part1@x($start,$m_usernameCount,$m_usernameStep,0,0)"
        } else {
           set username "$part1@x($start,$m_usernameCount,$m_usernameStep,0,0)@$part2" 
        } 
    } else {
        set username $m_username
    }

    if {$m_passwordMode != "fixed"} {
        set start 1
        set part1 $m_password

        set retList [SplitWordAndNumber $part1]
        set part1 [lindex $retList 0]
        set temp [lindex $retList 1]
  
        if {$temp != ""} {
            set start $temp
        } 

        if {$m_passwordMode == "decrement"} {
            set start [expr $start - $m_passwordCount * $m_passwordStep + 1]
            if {$start < 0} {
                set start 0 
            } 
        } 
        set password "$part1@x($start,$m_passwordCount,$m_passwordStep,0,0)" 
    } else {
        set password $m_password
    }

    switch $m_authenticationRole {
        "papsender" {
            set Authentication PAP
        }
        "chapresponder" {
            set Authentication CHAP_MD5
        }
        "papsenderorchapresponder" {
            set Authentication AUTO
        }
        default {
            error "Wrong authenticationRole,should be one of papsender, chapresponder or papsenderorchapresponder."
        }
    }    

    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv4If
    }
    
    #Configure PPPoE Client
    stc::config $m_hHost -DeviceCount $m_count
    if {$m_portType == "ethernet"} {
        stc::config $m_hEthIIIf -SourceMac $m_localMac -SrcMacStep $m_localMacModifier
    }
    
    if {$m_flagGateway == true} {
        if {$m_ipv4Gateway !=""} {
            stc::config $m_hIpv4If -Gateway $m_ipv4Gateway
        }
    }        
    if {[expr $m_flagPPPAgentCircuitId == "true" || $m_flagPPPAgentRemoteId == "true"]} {
        stc::config $m_hPppoeClientCfg -EnableRelayAgent "true"
    } 

    stc::config $m_hPppoeClientCfg -CircuitId $m_agentCircuitId \
                    -RemoteOrSessionId $m_remoteAgentCircuitId \
                    -ServiceName $m_pppoeServerName \
                    -LcpConfigRequestMaxAttempts $m_maxConfigureAttempts \
                    -NcpConfigRequestMaxAttempts $m_maxConfigureAttempts \
                    -LcpTermRequestMaxAttempts $m_maxTerminateAttempts \
                    -MaxNaks $m_maximumFailures \
                    -EnableMruNegotiation $m_flagUseInterfaceMRU \
                    -MruSize $m_mru \
                    -Authentication $Authentication \
                    -Username $username \
                    -Password $password \
                    -Active $m_active    \
                    -ChapAckTimeout $m_chapAckTimeout \
                    -ChapChalRequestTimeout $m_chapChalReqTimeout \
                    -LcpConfigRequestTimeout $m_lcpConfigReqTimeout \
                    -LcpTermRequestTimeout $m_lcpTermReqTimeout \
                    -NcpConfigRequestTimeout $m_ncpConfigReqTimeout \
                    -PapRequestTimeout $m_papReqTimeout\
                    -PadiTimeout $m_pppoERetransmitTimer \
                    -PadiMaxAttempts $m_pppoEMaxRetransmitCount \
                    -PadrTimeout $m_pppoERetransmitTimer \
                    -PadrMaxAttempts $m_pppoEMaxRetransmitCount
 
    #Apply the configuration to the chassis
    ApplyValidationCheck

    debugPut "exit the proc of PPPoEClient::SetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RetrieveRouter
#Description: Retrieve PPPoE Client Router attributes
#Input: For the details please refer to the user guide.
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::RetrieveRouter {args} {

    debugPut "enter the proc of PPPoE Client::RetrieveRouter"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    set PppoeGetRouterResult ""
    lappend PppoeGetRouterResult -encapsulation
    lappend PppoeGetRouterResult EthernetII
    lappend PppoeGetRouterResult -count
    lappend PppoeGetRouterResult [stc::get $m_hHost -DeviceCount]
    if {$m_portType == "ethernet"} {
        lappend PppoeGetRouterResult -localmac
        lappend PppoeGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
        lappend PppoeGetRouterResult -localmacmodifier
        lappend PppoeGetRouterResult [stc::get $m_hEthIIIf -SrcMacStep]
    }
    lappend PppoeGetRouterResult -flaggateway
    lappend PppoeGetRouterResult $m_flagGateway
    lappend PppoeGetRouterResult -ipv4gateway
    lappend PppoeGetRouterResult [stc::get $m_hIpv4If -Gateway]
    if {$m_portType == "ethernet"} {
        lappend PppoeGetRouterResult -sourcemacaddr
        lappend PppoeGetRouterResult [stc::get $m_hEthIIIf -SourceMac]
    }
    lappend PppoeGetRouterResult -poolname
    lappend PppoeGetRouterResult $m_poolName    
    lappend PppoeGetRouterResult -flaguseinterfacemru
    set tmpFlagUseIfMru [stc::get $m_hPppoeClientCfg -EnableMruNegotiation]
    set tmpFlagUseIfMru [string tolower $tmpFlagUseIfMru]
    if {$tmpFlagUseIfMru == "true"} {
        set tmpFlagUseIfMru enable
    } else {
        set tmpFlagUseIfMru disable
    }
    lappend PppoeGetRouterResult $tmpFlagUseIfMru
    lappend PppoeGetRouterResult -mru
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -MruSize]
    lappend PppoeGetRouterResult -flagpppagentcircuitid
    lappend PppoeGetRouterResult $m_flagPPPAgentCircuitId
    lappend PppoeGetRouterResult -agentcircuitid
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -CircuitId]
    lappend PppoeGetRouterResult -flagpppagentremoteid
    lappend PppoeGetRouterResult $m_flagPPPAgentRemoteId
    lappend PppoeGetRouterResult -remoteagentcircuitid
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -RemoteOrSessionId]
    lappend PppoeGetRouterResult -pppoeservername
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -ServiceName]
    lappend PppoeGetRouterResult -maxconfigureattempts
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -LcpConfigRequestMaxAttempts]
    lappend PppoeGetRouterResult -maxterminateattempts
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -LcpTermRequestMaxAttempts]
    lappend PppoeGetRouterResult -maximumfailures
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -MaxNaks]
    lappend PppoeGetRouterResult -authenticationrole
    set authRole [stc::get $m_hPppoeClientCfg -Authentication]
    set authRole [string tolower $authRole]
    switch $authRole {
        "pap" {
            set authRole papsender
        }
        "chap_md5" {
            set authRole CHAPResponder
        }
        "auto" {
            set authRole PAPSenderOrCHAPResponder
        }        
    }
    lappend PppoeGetRouterResult $authRole
    lappend PppoeGetRouterResult -active
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -Active]
    lappend PppoeGetRouterResult -state
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -BlockState]
    lappend PppoeGetRouterResult -usernamemode 
    lappend PppoeGetRouterResult $m_usernameMode
    lappend PppoeGetRouterResult -usernamecount 
    lappend PppoeGetRouterResult $m_usernameCount
    lappend PppoeGetRouterResult -usernamestep 
    lappend PppoeGetRouterResult $m_usernameStep
    lappend PppoeGetRouterResult -passwordmode 
    lappend PppoeGetRouterResult $m_passwordMode
    lappend PppoeGetRouterResult -passwordcount 
    lappend PppoeGetRouterResult $m_passwordCount
    lappend PppoeGetRouterResult -passwordstep 
    lappend PppoeGetRouterResult $m_passwordStep
    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    lappend PppoeGetRouterResult -connectrate 
    set rate [stc::get $hPppoxPortCfg -ConnectRate]
    lappend PppoeGetRouterResult $rate
    lappend PppoeGetRouterResult -disconnectrate  
    set rate [stc::get $hPppoxPortCfg -DisconnectRate ]
    lappend PppoeGetRouterResult $rate
    lappend PppoeGetRouterResult -chapchalreqtimeout 
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -ChapChalRequestTimeout ]
    lappend PppoeGetRouterResult -chapacktimeout  
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -ChapAckTimeout ]
    lappend PppoeGetRouterResult -paprequesttimeout 
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -PapRequestTimeout ]
    lappend PppoeGetRouterResult -lcpconfigreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -LcpConfigRequestTimeout ]
    lappend PppoeGetRouterResult -ncpconfigreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -NcpConfigRequestTimeout ]
    lappend PppoeGetRouterResult -lcptermreqtimeout
    lappend PppoeGetRouterResult [stc::get $m_hPppoeClientCfg -LcpTermRequestTimeout  ]

    lappend PppoeGetRouterResult -pppoeretransmittimer
    lappend PppoeGetRouterResult $m_pppoERetransmitTimer
    lappend PppoeGetRouterResult -pppoemaxretransmitcount
    lappend PppoeGetRouterResult $m_pppoEMaxRetransmitCount
     
    lappend PppoeGetRouterResult -vlantype1
    lappend PppoeGetRouterResult $m_vlanType1
    lappend PppoeGetRouterResult -vlanid1
    lappend PppoeGetRouterResult $m_vlanId1
    lappend PppoeGetRouterResult -vlanidmodifier1
    lappend PppoeGetRouterResult $m_vlanModifier1
    lappend PppoeGetRouterResult -vlanidcount1
    lappend PppoeGetRouterResult $m_vlanCount1

    lappend PppoeGetRouterResult -vlantype2
    lappend PppoeGetRouterResult $m_vlanType2
    lappend PppoeGetRouterResult -vlanid2
    lappend PppoeGetRouterResult $m_vlanId2
    lappend PppoeGetRouterResult -vlanidmodifier2
    lappend PppoeGetRouterResult $m_vlanModifier2
    lappend PppoeGetRouterResult -vlanidcount2
    lappend PppoeGetRouterResult $m_vlanCount2

    if {$args == "" } {
        debugPut "exit the proc of PPPoE Client::RetrieveRouter" 
        return $PppoeGetRouterResult
    } else {     
       # set PppoeGetRouterResult [string tolower $PppoeGetRouterResult]
        array set arr $PppoeGetRouterResult
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
        debugPut "exit the proc of PPPoE Client::RetrieveRouter"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Retrieve PPPoE Client statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#Modified by: Penn   2010/4/21 for IGMPoPPPOE protocol
#############################################################################
::itcl::body PPPoEClient::RetrieveRouterStats {args} {

    debugPut "enter the proc of PPPoE Client::RetrieveRouterStats"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #获取端口及host统计信息, modified by Penn 2010/4/23
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
    set PppoeClientResultHandle [$gChassisName cget -m_pppoeClientResultHandle ]
  
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $PppoeClientResultHandle]
    } err]} {
        return $errorCode
    }

    set hPppoeClientResults [stc::get $m_hPppoeClientCfg -children-PppoeClientBlockResults]
    set PppoeClientStats ""

    lappend PppoeClientStats -PadoRxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxPadoCount]
    lappend PppoeClientStats -PadsRxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxPadsCount]
    lappend PppoeClientStats -PadtRxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxPadtCount]
    lappend PppoeClientStats -PadiTxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxPadiCount]
    lappend PppoeClientStats -PadrTxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxPadrCount]
    lappend PppoeClientStats -PadtTxCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxPadtCount]
    lappend PppoeClientStats -SessionClosedCount    
    lappend PppoeClientStats [stc::get $hPppoeClientResults -DisconnectedSuccessCount]
    lappend PppoeClientStats -SessionAttempedCount
    lappend PppoeClientStats [stc::get $hPppoeClientResults -AttemptedCount]
    lappend PppoeClientStats -SessionFailedCount    
    lappend PppoeClientStats [stc::get $hPppoeClientResults -FailedConnectCount]
    lappend PppoeClientStats -SessionEstablishedCount 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -SessionsUp]    
    lappend PppoeClientStats -SessionMaxEstTime 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -MaxSetupTime]
    lappend PppoeClientStats -SessionMinEstTime 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -MinSetupTime]
    lappend PppoeClientStats -SessionAveEstTime 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -AvgSetupTime]
    lappend PppoeClientStats -LcpConfigRxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpConfigRequestCount]
    lappend PppoeClientStats -LcpConfigRxAck 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpConfigAckCount]
    lappend PppoeClientStats -LcpConfigRxNak 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpConfigNakCount]
    lappend PppoeClientStats -LcpConfigRxReject 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpConfigRejectCount]
    lappend PppoeClientStats -LcpTerminateRxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpTermRequestCount]
    lappend PppoeClientStats -LcpTerminateRxAck 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpTermAckCount]
    lappend PppoeClientStats -LcpEchoRxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpEchoRequestCount]
    lappend PppoeClientStats -LcpEchoRxReply 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -RxLcpEchoReplyCount]
    lappend PppoeClientStats -LcpConfigTxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpConfigRequestCount]
    lappend PppoeClientStats -LcpConfigTxAck 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpConfigAckCount]
    lappend PppoeClientStats -LcpConfigTxNak 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpConfigNakCount]
    lappend PppoeClientStats -LcpConfigTxReject 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpConfigRejectCount]
    lappend PppoeClientStats -LcpTerminateTxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpTermRequestCount]
    lappend PppoeClientStats -LcpTerminateTxAck 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpTermAckCount]
    lappend PppoeClientStats -LcpEchoTxRequest 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpEchoRequestCount]
    lappend PppoeClientStats -LcpEchoTxReply 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -TxLcpEchoReplyCount]
    lappend PppoeClientStats -SessionRateAve 
    lappend PppoeClientStats [stc::get $hPppoeClientResults -SuccSetupRate]

    if { $args == "" } {
        debugPut "exit the proc of PPPoEClient::RetrieveRouterStats" 
        return $PppoeClientStats
    } else {     
        set PppoeClientStats [string tolower $PppoeClientStats]
        array set arr $PppoeClientStats
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
        debugPut "exit the proc of PPPoEClient::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: Open
#Description: Start PPPoE client
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::Open {args} {
    
    debugPut "enter the proc of PPPoEClient::Open"    

    #Abort pppoe session
    stc::perform PppoxConnect -BlockList $m_hPppoeClientCfg

    debugPut "exit the proc of PPPoEClient::Open"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Close
#Description: Close pppoeHost connection
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::Close {args} {
    
    debugPut "enter the proc of PPPoEClient::Close"    

    #Abort pppoe session
    stc::perform PppoxDisconnect -BlockList $m_hPppoeClientCfg

    debugPut "exit the proc of PPPoEClient::Close"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: CancelAttempt
#Description: Cancel the attempts
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::CancelAttempt {args} {
   
    debugPut "enter the proc of PPPoEClient::CancelAttempt"    

    #Abort pppoe session
    stc::perform PppoxDisconnect -BlockList $m_hPppoeClientCfg

    debugPut "exit the proc of PPPoEClient::CancelAttempt"  
    return $::mainDefine::gSuccess 
}


############################################################################
#APIName: Abort
#Description: Abort PPPoE connection
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::Abort {args} {
   
    debugPut "enter the proc of PPPoEClient::Abort"    

    #Abort pppoe session
    stc::perform PppoxAbort -BlockList $m_hPppoeClientCfg

    debugPut "exit the proc of PPPoEClient::Abort"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Enable
#Description: Enable PPPoE server 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::Enable {args} {
   
    debugPut "enter the proc of PPPoEClient::Enable"    

    stc::config $m_hPppoeClientCfg -Active TRUE
    #Apply the configuration to the chassis
    ApplyValidationCheck
    #Enable PPPoE Server
    stc::perform DeviceStart -DeviceList $m_hHost

    if {$::mainDefine::gSTCVersion == "2.31"} {
        stc::perform PppoxConnect -BlockList $m_hPppoeClientCfg
    } 

    debugPut "exit the proc of PPPoEClient::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Disable PPPoE server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::Disable {args} {
    
    debugPut "enter the proc of PPPoEClient::Disable"    

    #Stop PPPoE Server
    stc::perform DeviceStop -DeviceList $m_hHost
    stc::config $m_hPppoeClientCfg -Active False
    #Apply the configuration to the chassis
    ApplyValidationCheck

    if {$::mainDefine::gSTCVersion == "2.31"} {
        stc::perform PppoxDisconnect -BlockList $m_hPppoeClientCfg
    }  

    debugPut "exit the proc of PPPoEClient::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetryFailedPeer
#Description: retry pppoe peer
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::RetryFailedPeer {args} {
    
    debugPut "enter the proc of PPPoEClient::RetryFailedPeer"    

    #retry session
    stc::perform PppoxRetry -BlockList $m_hPppoeClientCfg

    debugPut "exit the proc of PPPoEClient::RetryFailedPeer"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveHostState
#Description: Retrieve host state according to MAC address 
#Input: For the details please refer to the user guide.
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PPPoEClient::RetrieveHostState {args} {
  
    debugPut "enter the proc of PPPoEClient::RetrieveHostState"

    set args1 [reformatArgs $args]
    set args [ConvertAttrToLowerCase $args]

    #Parse FileName parameter
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args1 [expr $index + 1]]
    }

    #Parse Mac  parameter
    set index [lsearch $args -mac] 
    if {$index != -1} {
        set Mac [lindex $args1 [expr $index + 1]] 
        set Mac [regsub -all : $Mac ""]
        set Mac [regsub -all -- - $Mac ""]
        set Mac [regsub -all \\. $Mac ""]
    } 
    
    #Parse IpAddr  parameter
    set index [lsearch $args -ipaddr] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] IpAddr
        set IpAddr ""
    }
    #Parse SessionId  parameter
    set index [lsearch $args -sessionid] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] SessionId
        set SessionId ""
    }

    #Parse RemoteIp  parameter
    set index [lsearch $args -remoteip] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RemoteIp
        set RemoteIp ""
    }
    #Parse AgentCircuitId  parameter
    set index [lsearch $args -agentcircuitid] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AgentCircuitId
        set AgentCircuitId ""
    }
    #Parse AgentRemoteId  parameter
    set index [lsearch $args -agentremoteid] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AgentRemoteId
        set AgentRemoteId ""
    }
    #Parse NumOfAttempt  parameter
    set index [lsearch $args -numofattempt] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] NumOfAttempt
        set NumOfAttempt ""
    }
    #Parse EstablishmentPhase  parameter
    set index [lsearch $args -establishmentphase] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] EstablishmentPhase
        set EstablishmentPhase ""
    }
    #Parse State  parameter
    set index [lsearch $args -state] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] State
        set State "IDLE"
    }
    #Parse DiscoveryState  parameter
    set index [lsearch $args -discoverystate] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] DiscoveryState
        set DiscoveryState ""
    }
    #Parse FailureReason  parameter
    set index [lsearch $args -failurereason] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] FailureReason
        set FailureReason ""
    }
    #Parse StateAttempted  parameter
    set index [lsearch $args -stateattempted] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] StateAttempted
        set StateAttempted ""
    }
    #Parse StateEstablished  parameter
    set index [lsearch $args -stateestablished] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] StateEstablished
        set StateEstablished ""
    }
    #Parse StateClosed  parameter
    set index [lsearch $args -stateclosed] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] StateClosed
        set StateClosed ""
    }
    #Parse StateFailed  parameter
    set index [lsearch $args -statefailed] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] StateFailed
        set StateFailed ""
    }
    #Parse SessionLifeTime  parameter
    set index [lsearch $args -sessionlifetime] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] SessionLifeTime
        set SessionLifeTime ""
    }
    #Parse EstablishmentTime  parameter
    set index [lsearch $args -establishmenttime] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] EstablishmentTime
        set EstablishmentTime ""
    }
    
    if {[info exists FileName]} {
        stc::perform PppoxSessionInfo -BlockList $m_hPppoeClientCfg -FileName $FileName
        debugPut "exit the proc of PPPoEClient::RetrieveHostState"  
    
        return $::mainDefine::gSuccess
    }

    if {[info exists Mac]} {
        set hostState ""
        stc::perform PppoxSessionInfo -BlockList $m_hPppoeClientCfg -FileName "C:/sessions.csv"
        set fid [open "C:/sessions.csv" r]
        set i 0
        while {[gets $fid line]} {
            if {$i != 0} {
                set listLine [split $line ,]
                set temp [lindex $listLine 10]
                if {$temp == ""} {
                    break
                }
                set temp [regsub -all : $temp ""]
                set temp [regsub -all -- - $temp ""]
                set temp [regsub -all \\. $temp ""]

                if {$Mac == $temp} {
                    lappend hostState -Mac 
                    lappend hostState [lindex $listLine 10] 
                    lappend hostState -IpAddr 
                    lappend hostState [lindex $listLine 6] 
                    lappend hostState -SessionId   
                    lappend hostState [lindex $listLine 3] 
                    lappend hostState -RemoteIp  
                    lappend hostState [lindex $listLine 7] 
                    lappend hostState -NumOfAttempt  
                    lappend hostState [lindex $listLine 14] 
                    lappend hostState -FailureReason  
                    lappend hostState [lindex $listLine 5]
                    lappend hostState -StateAttempted   
                    lappend hostState [lindex $listLine 14]
                    lappend hostState -StateEstablished    
                    lappend hostState [lindex $listLine 15]
                    lappend hostState -StateClosed     
                    lappend hostState [lindex $listLine 18]
                    lappend hostState -StateFailed      
                    lappend hostState [lindex $listLine 16]
                    lappend hostState -EstablishmentTime        
                    lappend hostState [lindex $listLine 20]
                
                    set IpAddr [lindex $listLine 6] 
                    set SessionId [lindex $listLine 3] 
                    set RemoteIp [lindex $listLine 7] 
                    set NumOfAttempt [lindex $listLine 14] 
                    set State [lindex $listLine 4]
                    lappend hostState -State
                    lappend hostState $State
                    if {[string tolower $State] == "connected"} {
                        set EstablishmentPhase "Established"
                    } elseif {[string tolower $State] == "connecting" } { 
                        set IPCPConfigRequest [lindex $listLine 37]
                        set PAPConfigRequest [lindex $listLine 41]
                        set LcpConfigRequest [lindex $listLine 22]

                        if {$IPCPConfigRequest != "0" } {
                            set EstablishmentPhase "NCPOpening"   
                        } elseif {$PAPConfigRequest != "0" } {
                            set EstablishmentPhase "Authenticating"  
                        } elseif {$LcpConfigRequest != "0" } {
                            set EstablishmentPhase "LCPOpening"
                        } else {
                            set EstablishmentPhase "Discovery"
                        } 
                    } elseif {[string tolower $State] == "idle" } {
                        set EstablishmentPhase "StartWait"
                    } else {
                        set EstablishmentPhase "Inactive"
                    }
                 
                    lappend hostState -EstablishmentPhase 
                    lappend hostState $EstablishmentPhase
               
                    set TxPADI [lindex $listLine 45]
                    set RxPADI [lindex $listLine 46]
                    set TxPADR [lindex $listLine 47]
                    set RxPADS [lindex $listLine 48]
                    if {$RxPADS != "0"} {
                        set DiscoveryState "RxPADS"
                    } elseif {$TxPADR != "0"} {
                        set DiscoveryState "TxPADR"
                    } elseif {$RxPADI != "0"} {
                        set DiscoveryState "RxPADI"
                    } else {
                        set DiscoveryState "TxPADI"
                    }       
               
                    lappend hostState -DiscoveryState 
                    lappend hostState $DiscoveryState
 
                    set FailureReason [lindex $listLine 5]
                    set StateAttempted [lindex $listLine 14]
                    set StateEstablished [lindex $listLine 15]
                    set StateClosed [lindex $listLine 18]
                    set StateFailed [lindex $listLine 16]
                    set EstablishmentTime [lindex $listLine 20]
                    break
                }
            }
            incr i
        }
        close $fid
    
        catch { file delete "C:/sessions.csv" }

        debugPut "exit the proc of PPPoEClient::RetrieveHostState"  
    
        return $hostState
    }      
}


#-----------------------PppoL2tp block API (LNS or LAC)-------------------------

############################################################################
#APIName: SetSession
#Description: Configure PppoL2tp Router
#Input: For the details please refer to the user guide.
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::SetSession {args} {
   
    debugPut "enter the proc of PppoL2tpBlock::SetSession"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]
    
    #Parse TestIpAddress parameter
    set index [lsearch $args -testipaddress]
    if {$index != -1} {
        set TestIpAddress [lindex $args [expr $index + 1]]
        set m_testIpAddress $TestIpAddress
    } 
    #Parse PoolName parameter
    set index [lsearch $args -poolname]
    if {$index != -1} {
        set PoolName [lindex $args [expr $index + 1]]
        set m_poolName $PoolName
    }
    #Parse SutIpAddress parameter
    set index [lsearch $args -sutipaddress]
    if {$index != -1} {
        set SutIpAddress [lindex $args [expr $index + 1]]
        set m_sutIpAddress $SutIpAddress
    }
    #Parse PooLNumber parameter
    set index [lsearch $args -poolnumber]
    if {$index != -1} {
        set PooLNumber [lindex $args [expr $index + 1]]
        set m_pooLNumber $PooLNumber
    } 
    #Parse TunnelCount parameter
    set index [lsearch $args -tunnelcount]
    if {$index != -1} {
        set TunnelCount [lindex $args [expr $index + 1]]
        set m_tunnelCount $TunnelCount
    } 
    #Parse PeerPerTunnel parameter
    set index [lsearch $args -peerpertunnel]
    if {$index != -1} {
        set PeerPerTunnel [lindex $args [expr $index + 1]]
        set m_peerPerTunnel $PeerPerTunnel
    } 
    
    #Parse HelloTimer parameter
    set index [lsearch $args -hellotimer]
    if {$index != -1} {
        set HelloTimer [lindex $args [expr $index + 1]]
        set m_helloTimer $HelloTimer
    } 
    
    #Parse MaxTxCount parameter
    set index [lsearch $args -maxtxcount]
    if {$index != -1} {
        set MaxTxCount [lindex $args [expr $index + 1]]
        set m_maxTxCount $MaxTxCount
    } 
    #Parse ReceiveWinSize parameter
    set index [lsearch $args -receivewinsize]
    if {$index != -1} {
        set ReceiveWinSize [lindex $args [expr $index + 1]]
        set m_receiveWinSize $ReceiveWinSize
    } 
    #Parse SourceUdpPort parameter
    set index [lsearch $args -sourceudpport]
    if {$index != -1} {
        set SourceUdpPort [lindex $args [expr $index + 1]]
        set m_sourceUdpPort $SourceUdpPort
    } 
    #Parse NameOfDevice parameter
    set index [lsearch $args -nameofdevice]
    if {$index != -1} {
        set NameOfDevice [lindex $args [expr $index + 1]]
        set m_nameOfDevice $NameOfDevice
    } 
    #Parse EchoRequestTimer parameter
    set index [lsearch $args -echorequesttimer]
    if {$index != -1} {
        set EchoRequestTimer [lindex $args [expr $index + 1]]
        set m_echoRequestTimer $EchoRequestTimer
    } 
    #Parse MaxConfigCount parameter
    set index [lsearch $args -maxconfigcount]
    if {$index != -1} {
        set MaxConfigCount [lindex $args [expr $index + 1]]
        set m_maxConfigCount $MaxConfigCount
    } 
    #Parse RestartTimer parameter
    set index [lsearch $args -restarttimer]
    if {$index != -1} {
        set RestartTimer [lindex $args [expr $index + 1]]
        set m_restartTimer $RestartTimer
    } 
    #Parse FlagACCM parameter
    set index [lsearch $args -flagaccm]
    if {$index != -1} {
        set FlagACCM [lindex $args [expr $index + 1]]
        set m_flagACCM $FlagACCM
    }
    #Parse MaxTermination parameter
    set index [lsearch $args -maxtermination]
    if {$index != -1} {
        set MaxTermination [lindex $args [expr $index + 1]]
        set m_maxTermination $MaxTermination
    } 
    #Parse MaxFailure parameter
    set index [lsearch $args -maxfailure]
    if {$index != -1} {
        set MaxFailure [lindex $args [expr $index + 1]]
        set m_maxFailure $MaxFailure
    } 
    
    #Parse AuthenticationRole parameter
    set index [lsearch $args -authenticationrole]
    if {$index != -1} {
        set AuthenticationRole [lindex $args [expr $index + 1]]
        set AuthenticationRole [string tolower $AuthenticationRole]
        set m_authenticationRole $AuthenticationRole
    } 
    #Parse Username parameter
    set index [lsearch $args -username]
    if {$index != -1} {
        set Username [lindex $args [expr $index + 1]]
        set m_username $Username
    } 
    #Parse Password parameter
    set index [lsearch $args -password]
    if {$index != -1} {
        set Password [lindex $args [expr $index + 1]]
        set m_password $Password
    } 
    #Parse EnableDutAuthentication parameter
    set index [lsearch $args -enabledutauthentication]
    if {$index != -1} {
        set EnableDutAuthentication [lindex $args [expr $index + 1]]
        set m_enableDutAuthentication $EnableDutAuthentication
    }   

    #Parse FlagAuthenSut parameter
    set index [lsearch $args -flagauthensut]
    if {$index != -1} {
        set FlagAuthenSut [lindex $args [expr $index + 1]]
        set m_enableDutAuthentication $FlagAuthenSut
    }   

    #Parse ShareSecret parameter
    set index [lsearch $args -sharesecret]
    if {$index != -1} {
        set ShareSecret [lindex $args [expr $index + 1]]
        set m_shareSecret $ShareSecret
    }   
    
    #Parse ConnectRate parameter
    set index [lsearch $args -connectrate]
    if {$index != -1} {
        set ConnectRate [lindex $args [expr $index + 1]]      
        set m_connectRate $ConnectRate
    }
    #Parse DisConnectRate parameter
    set index [lsearch $args -disconnectrate]
    if {$index != -1} {
        set DisConnectRate [lindex $args [expr $index + 1]]      
        set m_disconnectRate $DisConnectRate
    }

    set connectRate $m_connectRate
    set disconnectRate $m_disconnectRate

    #Parse HostName parameter
    set index [lsearch $args -hostname]
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]      
        set m_l2tpHostName $HostName
    }

    #Parse LocalIpAddr parameter
    set index [lsearch $args -localipaddr]
    if {$index != -1} {
        set LocalIpAddr [lindex $args [expr $index + 1]]      
        set m_localIpAddr $LocalIpAddr
        stc::config $m_hIpv4If2 -Address $m_localIpAddr -Gateway [GetGatewayIp $m_localIpAddr] 
    }

    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    stc::config $hPppoxPortCfg -ConnectRate $connectRate -DisconnectRate $disconnectRate 

    if {$m_blockType == "pppol2tplns"} {
        #Parse StartIpAddr parameter
        set index [lsearch $args -startipaddr]
        if {$index != -1} {
            set StartIpAddr [lindex $args [expr $index + 1]]
            set m_startIpAddr $StartIpAddr
        } 
        #Parse Modifier parameter
        set index [lsearch $args -modifier]
        if {$index != -1} {
            set Modifier [lindex $args [expr $index + 1]]
            set m_modifier $Modifier
        } 

        #Parse Count parameter
        set index [lsearch $args -count]
        if {$index != -1} {
            set Count [lindex $args [expr $index + 1]]
            set m_count $Count
        } 
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

    #Parse VlanIdCount1 parameter
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

    #Configure PPPoE VLAN interface(support 2 VLANs)
    PPPoEConfigVlanIfs $args $m_hHost $m_pooLNumber $m_vlanType1 $m_vlanId1 $m_vlanModifier1 $m_vlanCount1 \
                       $m_vlanType2 $m_vlanId2 $m_vlanModifier2 $m_vlanCount2 $m_hIpv4If $m_hEthIIIf

    switch $m_authenticationRole {
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
            error "Wrong authenticationRole,should be one of pap, chap or sut."
        }
    }

    if {[info exists PoolName]} {
        set ::mainDefine::gPoolCfgBlock($PoolName) $m_hIpv4If2
    }
    
    #Configure Pppol2tp block
    stc::config $m_hIpv4If -Address $m_testIpAddress -Gateway $m_sutIpAddress 
    
    stc::config $m_hHost -DeviceCount $m_pooLNumber -Name $m_nameOfDevice
    
    stc::config $m_hL2tpBlkCfg -TunnelCount $m_tunnelCount \
                    -SessionsPerTunnelCount $m_peerPerTunnel \
                    -RxWindowSize $m_receiveWinSize \
                    -UdpSrcPort $m_sourceUdpPort \
                    -EnableDutAuthentication $m_enableDutAuthentication -HostName $m_l2tpHostName

    if {[string tolower $m_enableDutAuthentication] == "true" } {
        stc::config $m_hL2tpBlkCfg -TxTunnelPassword $m_shareSecret -RxTunnelPassword $m_shareSecret
    }
               
    if {[info exists HelloTimer]} {
        stc::config $m_hL2tpBlkCfg -EnableHello true -HelloTimeout $m_helloTimer
    }
                 
    stc::config $m_hPppoL2tpBlock -EnableEchoRequest "TRUE" \
                    -EchoRequestGenFreq $m_echoRequestTimer \
                    -LcpConfigRequestMaxAttempts $m_maxConfigCount \
                    -NcpConfigRequestMaxAttempts $m_maxConfigCount \
                    -LcpConfigRequestTimeout $m_restartTimer \
                    -LcpTermRequestTimeout $m_restartTimer \
                    -NcpConfigRequestTimeout $m_restartTimer \
                    -LcpTermRequestMaxAttempts $m_maxTermination \
                    -MaxNaks $m_maxFailure \
                    -Authentication $Authentication \
                    -Username $m_username \
                    -Password $m_password 
                    
    if {$m_blockType == "pppol2tplns"} {
        set hPeerPool [lindex [stc::get $m_hPppoL2tpBlock -children-PppoxServerIpv4PeerPool] 0]
        stc::config $hPeerPool -StartIpList $m_startIpAddr -AddrIncrement $m_modifier -NetworkCount $m_count
    }
    
    #Apply the configuration to the chassis
    #ApplyValidationCheck

    debugPut "exit the proc of PppoL2tpBlock::SetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RetrieveRouter
#Description: Retrieve Pppl2tp Router attributes
#Input: For the details please refer to the user guide.
#Output: None
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::RetrieveRouter {args} {
   
    debugPut "enter the proc of PppoL2tpBlock::RetrieveRouter"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    set Pppol2tpGetRouterResult ""
    lappend Pppol2tpGetRouterResult -testipaddress
    lappend Pppol2tpGetRouterResult [stc::get $m_hIpv4If -Address]
    lappend Pppol2tpGetRouterResult -sutipaddress
    lappend Pppol2tpGetRouterResult [stc::get $m_hIpv4If -Gateway]
    lappend Pppol2tpGetRouterResult -poolnumber
    lappend Pppol2tpGetRouterResult [stc::get $m_hHost -DeviceCount]
    lappend Pppol2tpGetRouterResult -tunnelcount
    lappend Pppol2tpGetRouterResult [stc::get $m_hL2tpBlkCfg -TunnelCount]
    lappend Pppol2tpGetRouterResult -peerpertunnel
    lappend Pppol2tpGetRouterResult [stc::get $m_hL2tpBlkCfg -SessionsPerTunnelCount ]
    lappend Pppol2tpGetRouterResult -poolname
    lappend Pppol2tpGetRouterResult $m_poolName
    lappend Pppol2tpGetRouterResult -hellotimer
    lappend Pppol2tpGetRouterResult [stc::get $m_hL2tpBlkCfg -HelloTimeout]
    lappend Pppol2tpGetRouterResult -receivewinsize
    lappend Pppol2tpGetRouterResult [stc::get $m_hL2tpBlkCfg -RxWindowSize  ]
    lappend Pppol2tpGetRouterResult -sourceudpport
    lappend Pppol2tpGetRouterResult [stc::get $m_hL2tpBlkCfg -UdpSrcPort ]
    lappend Pppol2tpGetRouterResult -nameofdevice
    lappend Pppol2tpGetRouterResult [stc::get $m_hHost -Name]
    lappend Pppol2tpGetRouterResult -echorequesttimer
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock  -EchoRequestGenFreq]   
    lappend Pppol2tpGetRouterResult -maxconfigcount
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -LcpConfigRequestMaxAttempts]
    lappend Pppol2tpGetRouterResult -restarttimer
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -LcpConfigRequestTimeout ]
    lappend Pppol2tpGetRouterResult -maxtermination
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -LcpTermRequestMaxAttempts  ]
    lappend Pppol2tpGetRouterResult -maxfailure
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -MaxNaks]
    lappend Pppol2tpGetRouterResult -authenticationrole
    set Authentication [stc::get $m_hPppoL2tpBlock -Authentication]
    set Authentication [string tolower $Authentication]
    switch $Authentication {
        "pap" {
            set Authentication PAP
        }
        "chap_md5" {
            set Authentication CHAP
        }
        "auto" {
            set Authentication SUT
        }        
    }
    lappend Pppol2tpGetRouterResult $Authentication
    lappend Pppol2tpGetRouterResult -username
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -Username]
    lappend Pppol2tpGetRouterResult -password
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -Password]
    lappend Pppol2tpGetRouterResult -state
    lappend Pppol2tpGetRouterResult [stc::get $m_hPppoL2tpBlock -BlockState]

    if {$m_blockType == "pppol2tplns"} {
        set hPeerPool [lindex [stc::get $m_hPppoL2tpBlock -children-PppoxServerIpv4PeerPool] 0]
        lappend Pppol2tpGetRouterResult -StartIpAddr
        lappend Pppol2tpGetRouterResult [stc::get $hPeerPool -StartIpList]
        lappend Pppol2tpGetRouterResult -Modifier
        lappend Pppol2tpGetRouterResult [stc::get $hPeerPool -AddrIncrement]
        lappend Pppol2tpGetRouterResult -Count
        lappend Pppol2tpGetRouterResult [stc::get $hPeerPool -NetworkCount]
    }

    set hPppoxPortCfg [stc::get $m_hPort -children-PppoxPortConfig ]
    lappend Pppol2tpGetRouterResult -connectrate 
    set rate [stc::get $hPppoxPortCfg -ConnectRate]
    lappend Pppol2tpGetRouterResult $rate
    lappend Pppol2tpGetRouterResult -disconnectrate  
    set rate [stc::get $hPppoxPortCfg -DisconnectRate ]
    lappend Pppol2tpGetRouterResult $rate

    lappend Pppol2tpGetRouterResult -flagauthensut  
    lappend Pppol2tpGetRouterResult $m_enableDutAuthentication

    lappend Pppol2tpGetRouterResult -hostname  
    lappend Pppol2tpGetRouterResult $m_l2tpHostName

    lappend Pppol2tpGetRouterResult -sharesecret  
    lappend Pppol2tpGetRouterResult $m_shareSecret

    lappend Pppol2tpGetRouterResult -vlantype1
    lappend Pppol2tpGetRouterResult $m_vlanType1
    lappend Pppol2tpGetRouterResult -vlanid1
    lappend Pppol2tpGetRouterResult $m_vlanId1
    lappend Pppol2tpGetRouterResult -vlanidmodifier1
    lappend Pppol2tpGetRouterResult $m_vlanModifier1
    lappend Pppol2tpGetRouterResult -vlanidcount1
    lappend Pppol2tpGetRouterResult $m_vlanCount1

    lappend Pppol2tpGetRouterResult -vlantype2
    lappend Pppol2tpGetRouterResult $m_vlanType2
    lappend Pppol2tpGetRouterResult -vlanid2
    lappend Pppol2tpGetRouterResult $m_vlanId2
    lappend Pppol2tpGetRouterResult -vlanidmodifier2
    lappend Pppol2tpGetRouterResult $m_vlanModifier2
    lappend Pppol2tpGetRouterResult -vlanidcount2
    lappend Pppol2tpGetRouterResult $m_vlanCount2

    if { $args == "" } {
        debugPut "exit the proc of PppoL2tpBlock::RetrieveRouter" 
        return $Pppol2tpGetRouterResult
    } else {     
        #set Pppol2tpGetRouterResult [string tolower $Pppol2tpGetRouterResult]
        array set arr $Pppol2tpGetRouterResult
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
        debugPut "exit the proc of PppoL2tpBlock::RetrieveRouter"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Retrieve PPPoE server statistics
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::RetrieveRouterStats {args} {

    debugPut "enter the proc of pppol2tp block::RetrieveRouterStats"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
    }
    set DeviceHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    if {$m_blockType == "pppol2tplac"} {
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_pppClientResultHandle ]
        }    
    } else {
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_pppServerResultHandle ]
        }
    }
    set PppBlockResultHandle $::mainDefine::result 
    if {$m_blockType == "pppol2tplac"} {
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_lacL2tpv2BlockResultHandle ]
        }
    } else {
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_lnsL2tpv2BlockResultHandle ]
        }
    }
    set L2tpv2BlockResultHandle $::mainDefine::result 

    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $PppBlockResultHandle]
        set errorCode [stc::perform RefreshResultView -ResultDataSet $L2tpv2BlockResultHandle]
    } err]} {
        return $errorCode
    }
    if {$m_blockType == "pppol2tplac"} {
        set hPppBlockResults [stc::get $m_hPppoL2tpBlock -children-PppClientBlockResults]
    } else {
        set hPppBlockResults [stc::get $m_hPppoL2tpBlock -children-PppServerBlockResults]
    }    
    set hL2tpBlkResults [stc::get $m_hL2tpBlkCfg -children-L2tpv2BlockResults]
    set Pppol2tpBlkStats ""

    lappend Pppol2tpBlkStats -L2tpSccrqTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxStartCcRequestCount]
    lappend Pppol2tpBlkStats -L2tpSccrpTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxStartCcReplyCount]
    lappend Pppol2tpBlkStats -L2tpScccnTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxStartCcConnectCount]
    lappend Pppol2tpBlkStats -L2tpStopScccnTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxStopCcNotifyCount]
    lappend Pppol2tpBlkStats -L2tpHelloTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxHelloCount]
    lappend Pppol2tpBlkStats -L2tpIcrqTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxIncomingCallRequestCount]
    lappend Pppol2tpBlkStats -L2tpIcrpTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxIncomingCallReplyCount]
    lappend Pppol2tpBlkStats -L2tpIccnTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxIncomingCallConnectCount]
    lappend Pppol2tpBlkStats -L2tpOcrqTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxOutgoingCallRequestCount]
    lappend Pppol2tpBlkStats -L2tpOcrpTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxOutgoingCallReplyCount]
    lappend Pppol2tpBlkStats -L2tpOccnTxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TxOutgoingCallConnectCount]
    lappend Pppol2tpBlkStats -L2tpSccrqRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxStartCcRequestCount]
    lappend Pppol2tpBlkStats -L2tpSccrpRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxStartCcReplyCount]
    lappend Pppol2tpBlkStats -L2tpScccnRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxStartCcConnectCount]
    lappend Pppol2tpBlkStats -L2tpStopScccnRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxStopCcNotifyCount]
    lappend Pppol2tpBlkStats -L2tpHelloRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxHelloCount]
    lappend Pppol2tpBlkStats -L2tpIcrqRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxIncomingCallRequestCount]
    lappend Pppol2tpBlkStats -L2tpIcrpRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxIncomingCallReplyCount]
    lappend Pppol2tpBlkStats -L2tpIccnRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxIncomingCallConnectCount]
    lappend Pppol2tpBlkStats -L2tpOcrqRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxOutgoingCallRequestCount]
    lappend Pppol2tpBlkStats -L2tpOcrpRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxOutgoingCallReplyCount]
    lappend Pppol2tpBlkStats -L2tpOccnRxCount
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -RxOutgoingCallConnectCount]

    lappend Pppol2tpBlkStats -L2tpTunnelMinEst
    set tunnelMinSetup [stc::get $hL2tpBlkResults -MinTunnelSetupTime]
    lappend Pppol2tpBlkStats $tunnelMinSetup
    lappend Pppol2tpBlkStats -L2tpTunnelMinEstRate
    if {$tunnelMinSetup != 0} {
        set minSetupRate [expr 1.0/$tunnelMinSetup]
    } else {
        set minSetupRate 0
    }
    lappend Pppol2tpBlkStats $minSetupRate
    lappend Pppol2tpBlkStats -L2tpTunnelMaxEst
    set tunnelMaxSetup [stc::get $hL2tpBlkResults -MaxTunnelSetupTime]
    lappend Pppol2tpBlkStats $tunnelMaxSetup
    lappend Pppol2tpBlkStats -L2tpTunnelMaxEstRate
    if {$tunnelMaxSetup != 0} {
        set maxSetupRate [expr 1.0/$tunnelMaxSetup]
    } else {
        set maxSetupRate 0
    }
    lappend Pppol2tpBlkStats $maxSetupRate
    lappend Pppol2tpBlkStats -L2tpTunnelAvgEst
    set tunnelAvgSetup [stc::get $hL2tpBlkResults -AvgTunnelSetupTime]
    lappend Pppol2tpBlkStats $tunnelAvgSetup
    lappend Pppol2tpBlkStats -L2tpTunnelAvgEstRate
    if {$tunnelAvgSetup != 0} {
        set avgSetupRate [expr 1.0/$tunnelAvgSetup]
    } else {
        set avgSetupRate 0
    }
    lappend Pppol2tpBlkStats $avgSetupRate
    lappend Pppol2tpBlkStats -L2tpTunnelEstRate
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -TunnelSetupRate]    
    lappend Pppol2tpBlkStats -L2tpSessionMinEst
    set sessionMinSetup [stc::get $hL2tpBlkResults -MinSessionSetupTime]
    lappend Pppol2tpBlkStats $sessionMinSetup
    lappend Pppol2tpBlkStats -L2tpSessionMinEstRate
    if {$sessionMinSetup != 0} {
        set minSetupRate [expr 1.0/$sessionMinSetup]
    } else {
        set minSetupRate 0
    }
    lappend Pppol2tpBlkStats $minSetupRate
    lappend Pppol2tpBlkStats -L2tpSessionMaxEst
    set sessionMaxSetup [stc::get $hL2tpBlkResults -MaxSessionSetupTime]
    lappend Pppol2tpBlkStats $sessionMaxSetup
    lappend Pppol2tpBlkStats -L2tpSessionMaxEstRate
    if {$sessionMaxSetup != 0} {
        set maxSetupRate [expr 1.0/$sessionMinSetup]
    } else {
        set maxSetupRate 0
    }
    lappend Pppol2tpBlkStats $maxSetupRate
    lappend Pppol2tpBlkStats -L2tpSessionAvgEst
    set sessionAvgSetup [stc::get $hL2tpBlkResults -AvgSessionSetupTime]
    lappend Pppol2tpBlkStats $sessionAvgSetup
    lappend Pppol2tpBlkStats -L2tpSessionAvgEstRate
    if {$sessionAvgSetup != 0} {
        set avgSetupRate [expr 1.0/$sessionMinSetup]
    } else {
        set avgSetupRate 0
    }
    lappend Pppol2tpBlkStats $avgSetupRate
    lappend Pppol2tpBlkStats -L2tpSessionEstRate
    lappend Pppol2tpBlkStats [stc::get $hL2tpBlkResults -SessionSetupRate]

    if {$m_blockType == "pppol2tplac"} {
        lappend Pppol2tpBlkStats -SessionAttempedCount
        lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -AttemptedCount]
    }
    lappend Pppol2tpBlkStats -SessionFailedCount
    set connFailed [stc::get $hPppBlockResults -FailedConnectCount]
    set disconnFailed [stc::get $hPppBlockResults -FailedDisconnectCount]
    lappend Pppol2tpBlkStats [expr $connFailed + $disconnFailed]
    lappend Pppol2tpBlkStats -SessionEstablishedCount 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -SessionsUp]    
    lappend Pppol2tpBlkStats -SessionMaxEstTime 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -MaxSetupTime]
    lappend Pppol2tpBlkStats -SessionMinEstTime 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -MinSetupTime]
    lappend Pppol2tpBlkStats -SessionAveEstTime 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -AvgSetupTime]
    lappend Pppol2tpBlkStats -LcpConfigRxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpConfigRequestCount]
    lappend Pppol2tpBlkStats -LcpConfigRxAck 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpConfigAckCount]
    lappend Pppol2tpBlkStats -LcpConfigRxNak 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpConfigNakCount]
    lappend Pppol2tpBlkStats -LcpConfigRxReject 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpConfigRejectCount]
    lappend Pppol2tpBlkStats -LcpTerminateRxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpTermRequestCount]
    lappend Pppol2tpBlkStats -LcpTerminateRxAck 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpTermAckCount]
    lappend Pppol2tpBlkStats -LcpEchoRxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpEchoRequestCount]
    lappend Pppol2tpBlkStats -LcpEchoRxReply 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -RxLcpEchoReplyCount]
    lappend Pppol2tpBlkStats -LcpConfigTxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpConfigRequestCount]
    lappend Pppol2tpBlkStats -LcpConfigTxAck 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpConfigAckCount]
    lappend Pppol2tpBlkStats -LcpConfigTxNak 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpConfigNakCount]
    lappend Pppol2tpBlkStats -LcpConfigTxReject 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpConfigRejectCount]
    lappend Pppol2tpBlkStats -LcpTerminateTxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpTermRequestCount]
    lappend Pppol2tpBlkStats -LcpTerminateTxAck 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpTermAckCount]
    lappend Pppol2tpBlkStats -LcpEchoTxRequest 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpEchoRequestCount]
    lappend Pppol2tpBlkStats -LcpEchoTxReply 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -TxLcpEchoReplyCount]
    lappend Pppol2tpBlkStats -SessionRateAve 
    lappend Pppol2tpBlkStats [stc::get $hPppBlockResults -SuccSetupRate]

    if { $args == "" } {
        debugPut "exit the proc of PppoL2tpBlock::RetrieveRouterStats" 
        return $Pppol2tpBlkStats
    } else {     
        set Pppol2tpBlkStats [string tolower $Pppol2tpBlkStats]
        array set arr $Pppol2tpBlkStats
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
        debugPut "exit the proc of PppoL2tpBlock::RetrieveRouterStats"   
        return $::mainDefine::gSuccess     
    }
}

############################################################################
#APIName: Open
#Description: Start PPPoL2tp protocol
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::Open {args} {
    
    debugPut "enter the proc of PppoL2tpBlock::Open"    

    #connect l2tp and pppox session
    stc::perform L2tpConnect -BlockList $m_hL2tpBlkCfg
    stc::perform PppoxConnect -BlockList $m_hPppoL2tpBlock

    debugPut "exit the proc of PppoL2tpBlock::Open"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Close
#Description: Close pppoL2tpHost connection
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::Close {args} {
    
    debugPut "enter the proc of PppoL2tpBlock::Close"    

    #Disconnect l2tp and pppox session    
    stc::perform PppoxDisConnect -BlockList $m_hPppoL2tpBlock
    stc::perform L2tpDisconnect -BlockList $m_hL2tpBlkCfg
    
    debugPut "exit the proc of PppoL2tpBlock::Close"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: CancelAttempt
#Description: Cancel the attempt
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::CancelAttempt {args} {
    
    debugPut "enter the proc of PppoL2tpBlock::CancelAttempt"    

    #Disconnect l2tp and pppox session    
    stc::perform PppoxDisConnect -BlockList $m_hPppoL2tpBlock
    stc::perform L2tpDisconnect -BlockList $m_hL2tpBlkCfg

    debugPut "exit the proc of PppoL2tpBlock::CancelAttempt"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Abort
#Description: Abort PPPoL2tp connection
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::Abort {args} {
  
    debugPut "enter the proc of PppoL2tpBlock::Abort"    

    #Abort pppoe session
    stc::perform PppoxAbort -BlockList $m_hPppoL2tpBlock
    stc::perform L2tpAbort -BlockList $m_hL2tpBlkCfg 

    debugPut "exit the proc of PppoL2tpBlock::Abort"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Enable
#Description: Enable PPPoL2tp server
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::Enable {args} {
   
    debugPut "enter the proc of PppoL2tpBlock::Enable"    

    stc::config $m_hL2tpBlkCfg -Active TRUE
    stc::config $m_hPppoL2tpBlock -Active TRUE
    #Apply the configuration to the chassis
    ApplyValidationCheck
    #Enable PPPoL2tp Server
    stc::perform DeviceStart -DeviceList $m_hHost

    debugPut "exit the proc of PppoL2tpBlock::Enable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: Disable
#Description: Stop PPPoL2tp server 
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::Disable {args} {
   
    debugPut "enter the proc of PppoL2tpBlock::Disable"    

    #Stop PPPoL2tp Server
    stc::perform DeviceStop -DeviceList $m_hHost
    
    stc::config $m_hL2tpBlkCfg -Active False
    stc::config $m_hPppoL2tpBlock -Active False
    
    #Apply the configuration to the chassis
    ApplyValidationCheck
    
    debugPut "exit the proc of PppoL2tpBlock::Disable"  
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetryFailedPeer
#Description: retry PppoL2tp peer
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body PppoL2tpBlock::RetryFailedPeer {args} {
   
    debugPut "enter the proc of PppoL2tpBlock::RetryFailedPeer"    

    #retry session
    stc::perform PppoxRetry -BlockList $m_hPppoL2tpBlock 

    debugPut "exit the proc of PppoL2tpBlock::RetryFailedPeer"  
    return $::mainDefine::gSuccess 
}
