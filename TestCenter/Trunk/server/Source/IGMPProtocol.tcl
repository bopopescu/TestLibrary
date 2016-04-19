###########################################################################
#                                                                        
#  File Name£ºIGMPProtocol.tcl                                                                                              
# 
#  Description£ºDefinition of IGMP router, IGMP host, and its methods
# 
#  Author£º Jaimin
#
#  Create Time:  2007.4.21
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

::itcl::class IgmpHost {
    #Inherit from Host class
    inherit Host

    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hHost
    public variable m_hostName
    public variable m_hIgmpHost
    public variable m_hGroup
    public variable m_hIpv4
    public variable m_hMacAddress
    public variable m_hResultDataSet
    public variable m_portType
    
    constructor {hostName hHost hPort portName hProject hipv4 portType} \
        { Host::constructor $hostName $hHost $hPort $portName $hProject $hipv4 "ipv4" $portType} {    

        set m_hostName $hostName       
        set m_hHost $hHost
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_hIpv4 $hipv4
        set m_portType $portType
        
        #Get Ethernet interface
        #added by yuanfen 8.11 2011	
        if {$m_portType == "ethernet"} {
            set Ether1 [stc::get $hHost -children-EthIIIf]  
            set m_hMacAddress [stc::get $Ether1 -SourceMac] 
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hHost -children-HdlcIf]]} {
                set Ether1 [stc::get $hHost -children-HdlcIf]
            } else {
                set Ether1 [stc::get $hHost -children-PppIf]
            }
        }
        
        set host1 [stc::create IgmpHostConfig -under $m_hHost]
        set m_hIgmpHost $host1
        stc::config $host1 -UsesIf-targets $m_hIpv4 
        set ::mainDefine::gPoolCfgBlock($m_hostName) $m_hIpv4 
    }

    destructor {
           
    }

    public method SetSession
    public method Enable
    public method Disable
    public method CreateGroupPool
    public method SetGroupPool
    public method DeleteGroupPool
    public method RetrieveRouterStats
    public method SendLeave
    public method SendReport
   
    #Methods internal use only
    public method RetrieveMacAddress
    public method RetrieveIpv4Address
}

::itcl::class IgmpSession {
    #Inherit from Router class
    inherit Router 
    
    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName 
    public variable m_hIgmpRouter 
    public variable m_hResultDataSet  
    public variable m_hIpv4
    public variable m_portType "ethernet"
    
    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
        { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
     
        set m_routerName $routerName       
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_portType $portType
        
        #Create Igmp router handle
        set igmproute1 [stc::create IgmpRouterConfig -under $m_hRouter]
        set m_hIgmpRouter $igmproute1
	
        #Get Ipv4 interface
        set ipv4if1 [stc::get $hRouter -children-Ipv4If] 
        set m_hIpv4 $ipv4if1
        set m_hIpAddress $ipv4if1
     
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
	     
        stc::config $igmproute1 -UsesIf-targets $ipv4if1
        set ::mainDefine::gPoolCfgBlock($m_routerName) $ipv4if1
    }
    
    destructor {
    }

    public method SetSession
    public method RetrieveRouter
    public method RetrieveRouterStatus
    public method StartAllQuery
    public method StopAllQuery
    public method RetrieveRouterStats
    public method Enable
    public method Disable   

    #Methods internal use only
    public method RetrieveIpv4Address
}


############################################################################
#APIName: SetSession
#Description: Configure IGMP Host
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::SetSession {args} {
  
    debugPut "enter the proc of IgmpHost::SetSession"
    
    set args [ConvertAttrToLowerCase $args]
    
    set index [lsearch $args -srcmac] 
    if {$index != -1} {
        set SrcMac [lindex $args [expr $index + 1]]
        set Ether1 [stc::get $m_hHost -children-EthIIIf]
        stc::config $Ether1 -SourceMac $SrcMac
    }
     
    set index [lsearch $args -srcmacstep] 
    if {$index != -1} {
        set SrcMacStep [lindex $args [expr $index + 1]]
        set Ether1 [stc::get $m_hHost -children-EthIIIf]
        set step ""
        for {set i 0} {$i <6} { incr i} {
            set mod1 [expr $SrcMacStep%256]
            if {$step ==""} {
                set step [format %x $mod1]
            } else {
                set step [format %x $mod1]:$step
            }
            set SrcMacStep [expr $SrcMacStep/256]
        }
        stc::config $Ether1 -SrcMacStep $step
    } 
    
    set index [lsearch $args -ipv4addr] 
    if {$index != -1} {
        set Ipv4Addr [lindex $args [expr $index + 1]]
        stc::config $m_hIpv4 -Address $Ipv4Addr
    } 
    
    set index [lsearch $args -ipv4addrgateway] 
    if {$index != -1} {
        set Ipv4AddrGateway [lindex $args [expr $index + 1]]
        stc::config $m_hIpv4 -Gateway $Ipv4AddrGateway
    }
    
    set index [lsearch $args -ipv4addrprefixlen] 
    if {$index != -1} {
        set Ipv4AddrPrefixLen [lindex $args [expr $index + 1]]
        stc::config $m_hIpv4 -PrefixLength $Ipv4AddrPrefixLen
    }
    
    #Parse Count parameter
    set index [lsearch $args -count] 
    if {$index != -1} {
        set Count [lindex $args [expr $index + 1]]
        set Ether1 [stc::get $m_hHost -children-EthIIIf]
        #stc::config $Ether1 -IfRecycleCount $Count
        #stc::config $m_hIpv4 -IfRecycleCount $Count
        stc::config $m_hHost -DeviceCount $Count
    }
    
    #Parse Increase parameter
    set index [lsearch $args -increase] 
    if {$index != -1} {
        set Increase [lindex $args [expr $index + 1]]
        
        set step ""
        for {set i 0} {$i <4} { incr i} {
            set mod1 [expr $Increase%256]
            if {$step ==""} {
                set step $mod1
            } else {
                set step $mod1.$step
            }
            set Increase [expr $Increase/256]
        }
        stc::config $m_hIpv4 -AddrStep $step
    } 

    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        if {[string tolower $Active] =="enable" ||[string tolower $Active] =="true"} {
            stc::config $m_hIgmpHost -Active TRUE
        } else {
            stc::config $m_hIgmpHost -active FALSE
        }
    } 
     
    set index [lsearch $args -sendgrouprate] 
    if {$index != -1} {
        set SendGroupRate [lindex $args [expr $index + 1]]
        set hIgmpport [stc::get $m_hPort -children-IgmpPortConfig]
        stc::config $hIgmpport -RatePps $SendGroupRate
    }     
    
    #Parse ProtocolType parameter
    set index [lsearch $args -protocoltype] 
    if {$index != -1} {
        set ProtocolType [lindex $args [expr $index + 1]]
        set ProtocolType [string toupper $ProtocolType]
    }
    
    #Parse V1RouterPresentTimeout parameter
    set index [lsearch $args -v1routerpresenttimeout] 
    if {$index != -1} {
        set V1RouterPresentTimeout [lindex $args [expr $index + 1]]
        set V1RouterPresentTimeout [string toupper $V1RouterPresentTimeout]
    } 
    
    #Parse ForceLeave parameter
    set index [lsearch $args -forceleave] 
    if {$index != -1} {
        set ForceLeave [lindex $args [expr $index + 1]]
        set ForceLeave [string toupper $ForceLeave]
    } 
    
    #Parse ForceRobustJoin parameter
    set index [lsearch $args -forcerobustjoin] 
    if {$index != -1} {
        set ForceRobustJoin [lindex $args [expr $index + 1]]
        set ForceRobustJoin [string toupper $ForceRobustJoin]
    }
    
    #Parse UnsolicitedReportInterval parameter
    set index [lsearch $args -unsolicitedreportinterval] 
    if {$index != -1} {
        set UnsolicitedReportInterval [lindex $args [expr $index + 1]]
    } 
    
    #Parse InsertCheckSumErrors parameter
    set index [lsearch $args -insertchecksumerrors] 
    if {$index != -1} {
        set InsertCheckSumErrors [lindex $args [expr $index + 1]]
        set InsertCheckSumErrors [string toupper $InsertCheckSumErrors]
    } 
    
    #Parse InserLengthErrors parameter
    set index [lsearch $args -inserlengtherrors] 
    if {$index != -1} {
        set InserLengthErrors [lindex $args [expr $index + 1]]
        set InserLengthErrors [string toupper $InserLengthErrors]
    } 
    
    #Parse Ipv4DontFragment parameter
    set index [lsearch $args -ipv4dontfragment] 
    if {$index != -1} {
        set Ipv4DontFragment [lindex $args [expr $index + 1]]
        set Ipv4DontFragment [string toupper $Ipv4DontFragment]
    } 
    
    #Create and create IGMP Host
    set host1 $m_hIgmpHost
    if {[info exists ForceLeave]} {
        stc::config $host1 -ForceLeave $ForceLeave
    }
    if {[info exists ForceRobustJoin]} {
        stc::config $host1 -ForceRobustJoin $ForceRobustJoin 
    }
    if {[info exists UnsolicitedReportInterval]} {
        stc::config $host1 -UnsolicitedReportInterval $UnsolicitedReportInterval
    }
    if {[info exists InsertCheckSumErrors]} {
        stc::config $host1 -InsertCheckSumErrors $InsertCheckSumErrors
    }
    if {[info exists InserLengthErrors]} {
        stc::config $host1 -InsertLengthErrors $InserLengthErrors
    }
    if {[info exists Ipv4DontFragment]} {
        stc::config $host1 -Ipv4DontFragment $Ipv4DontFragment
    }
    if {[info exists ProtocolType]} {
        set ProtocolType [string toupper $ProtocolType]
        if {$ProtocolType == "IGMPV1"} {
            stc::config $host1 -Version IGMP_V1
        } elseif {$ProtocolType == "IGMPV2"} {
            stc::config $host1 -Version IGMP_V2 
            if {[info exists ProtocolType]} {
               if {[info exists V1RouterPresentTimeout]} {
                   stc::config $host1 -V1RouterPresentTimeout $V1RouterPresentTimeout
               }
            }
        } elseif {$ProtocolType == "IGMPV3"} {
            stc::config $host1 -Version IGMP_V3
        } 
    }
         
    debugPut "exit the proc of IgmpHost::SetSession"
    return $::mainDefine::gSuccess
}


::itcl::body IgmpHost::Enable {args} {

    stc::config $m_hIgmpHost -Active TRUE

}


::itcl::body IgmpHost::Disable {args} {

    stc::config $m_hIgmpHost -Active FALSE

}

############################################################################
#APIName: CreateGroupPool
#Description: Create Igmp Group under IGMP host
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::CreateGroupPool {args} {
   
    debugPut "enter the proc of IgmpHost::CreateGroupPool"
    set args [ConvertAttrToLowerCase $args]
    #set args [string tolower $args]
    
    #Parse GroupPoolName parameter
    set index [lsearch $args -grouppoolname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify GroupPoolName you want to create"
    }
    
    #Parse StartIP parameter
    set index [lsearch $args -startip] 
    if {$index != -1} {
        set StartIP [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify StartIP paramenter."
    }
    
    #Parse PrefixLen parameter
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    } else  {
        set PrefixLen 24
    }
    
    #Parse GroupCnt parameter
    set index [lsearch $args -groupcnt] 
    if {$index != -1} {
        set GroupCnt [lindex $args [expr $index + 1]]
    } else  {
        set GroupCnt 1
    }
    
    #Parse GroupIncrement parameter
    set index [lsearch $args -groupincrement] 
    if {$index != -1} {
        set GroupIncrement [lindex $args [expr $index + 1]]
    } else  {
        set GroupIncrement 1
    }
    
    #Parse SrcStartIP parameter
    set index [lsearch $args -srcstartip] 
    if {$index != -1} {
        set SrcStartIP [lindex $args [expr $index + 1]]
    } else  {
        set SrcStartIP 192.168.1.2
    }
    
    #Parse SrcCnt parameter
    set index [lsearch $args -srccnt] 
    if {$index != -1} {
        set SrcCnt [lindex $args [expr $index + 1]]
    } else  {
        set SrcCnt 1
    }
    
    #Parse SrcIncrement parameter
    set index [lsearch $args -srcincrement] 
    if {$index != -1} {
        set SrcIncrement [lindex $args [expr $index + 1]]
    } else  {
        set SrcIncrement 1
    }
    
    #Parse SrcPrefixLen parameter
    set index [lsearch $args -srcprefixlen] 
    if {$index != -1} {
        set SrcPrefixLen [lindex $args [expr $index + 1]]
    } else  {
        set SrcPrefixLen 24
    }
    
    #Parse FilterMode parameter
    set index [lsearch $args -filtermode] 
    if {$index != -1} {
        set FilterMode [lindex $args [expr $index + 1]]
        set FilterMode [string toupper $FilterMode]
    } else  {
        set FilterMode EXCLUDE
    }
    
    set group1 [stc::create IgmpGroupMembership -under $m_hIgmpHost]
    stc::config $group1 -Name $GroupName
    set m_hGroup($GroupName) $group1
    set Ipv4Group1 [stc::create Ipv4Group -under $m_hProject]
    set Ipv4NetworkBlock1 [lindex [stc::get $Ipv4Group1 -children-Ipv4NetworkBlock] 0]
    stc::config $Ipv4NetworkBlock1 -StartIpList $StartIP -PrefixLength $PrefixLen -NetworkCount $GroupCnt \
        -AddrIncrement $GroupIncrement -Active TRUE 
        
    set ::mainDefine::gPoolCfgBlock($GroupName) $Ipv4NetworkBlock1    
    
    stc::config $group1 -SubscribedGroups-targets $Ipv4Group1
    set version1 [stc::get $m_hIgmpHost -Version]
    if {[string toupper $version1] =="IGMP_V3"} {       
        stc::config $group1 -FilterMode [string toupper $FilterMode] -UserDefinedSources TRUE
        set Ipv4NetworkBlock2 [lindex [stc::get $group1 -children-Ipv4NetworkBlock] 0]
        stc::config $Ipv4NetworkBlock2 -StartIpList $SrcStartIP -PrefixLength $SrcPrefixLen \
            -NetworkCount $SrcCnt -AddrIncrement $SrcIncrement
    }
    
    debugPut "exit the proc of IgmpHost::CreateGroupPool"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: SetGroupPool
#Description: Configure IGMP Group pool
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::SetGroupPool {args} {
   
    debugPut "enter the proc of IgmpHost::SetGroupPool"
    set args [ConvertAttrToLowerCase $args]
    
    #Parse GroupPoolName parameter
    set index [lsearch $args -grouppoolname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify GroupPoolName you want to create"
    }

    if {[info exists m_hGroup($GroupName)]} {
        set group1 $m_hGroup($GroupName)
    } else {
        error "GroupName $GroupName does not exist."
    }
    
    #Parse StartIP parameter
    set index [lsearch $args -startip] 
    if {$index != -1} {
        set StartIP [lindex $args [expr $index + 1]]
    } 
    
    #Parse PrefixLen parameter
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
    } 
    
    #Parse GroupCnt parameter
    set index [lsearch $args -groupcnt] 
    if {$index != -1} {
        set GroupCnt [lindex $args [expr $index + 1]]
    }
    
    #Parse GroupIncrement parameter
    set index [lsearch $args -groupincrement] 
    if {$index != -1} {
        set GroupIncrement [lindex $args [expr $index + 1]]
    }
    
    #Parse SrcStartIP parameter
    set index [lsearch $args -srcstartip] 
    if {$index != -1} {
        set SrcStartIP [lindex $args [expr $index + 1]]
    } 
    
    #Parse SrcCnt parameter
    set index [lsearch $args -srccnt] 
    if {$index != -1} {
        set SrcCnt [lindex $args [expr $index + 1]]
    } 
    
    #Parse SrcIncrement parameter
    set index [lsearch $args -srcincrement] 
    if {$index != -1} {
        set SrcIncrement [lindex $args [expr $index + 1]]
    } 
    
    #Parse FilterMode parameter
    set index [lsearch $args -filtermode] 
    if {$index != -1} {
        set FilterMode [lindex $args [expr $index + 1]]
        set FilterMode [string toupper $FilterMode]
    }

    set Ipv4Group1 [stc::create Ipv4Group -under $m_hProject -Active TRUE]
    set Ipv4NetworkBlock1 [lindex [stc::get $Ipv4Group1 -children-Ipv4NetworkBlock] 0]
    if {[info exists StartIP]} {
        stc::config $Ipv4NetworkBlock1 -StartIpList $StartIP
    }
    if {[info exists PrefixLen]} {
        stc::config $Ipv4NetworkBlock1 -PrefixLength $PrefixLen
    }
    if {[info exists GroupCnt]} {
        stc::config $Ipv4NetworkBlock1 -NetworkCount $GroupCnt
    }
    if {[info exists GroupIncrement]} {
        stc::config $Ipv4NetworkBlock1 -AddrIncrement $GroupIncrement
    }

    stc::config $group1 -SubscribedGroups-targets $Ipv4Group1
    set version1 [stc::get $m_hIgmpHost -Version]
    if {[string toupper $version1] =="IGMP_V3"} {        
        if {[info exists FilterMode]} {
            stc::config $group1 -FilterMode [string toupper $FilterMode]
        }
        stc::config $group1 -UserDefinedSources TRUE
        
        set Ipv4NetworkBlock2 [lindex [stc::get $group1 -children-Ipv4NetworkBlock] 0]

        if {[info exists SrcStartIP]} {
            stc::config $Ipv4NetworkBlock2 -StartIpList $SrcStartIP
        }
        if {[info exists SrcPrefixLen]} {
            stc::config $Ipv4NetworkBlock2 -PrefixLength $SrcPrefixLen
        }
        if {[info exists SrcIncrement]} {
            stc::config $Ipv4NetworkBlock2 -AddrIncrement $SrcIncrement
        }
        if {[info exists SrcCnt]} {
            stc::config $Ipv4NetworkBlock2 -NetworkCount $SrcCnt
        }
    }
    debugPut "exit the proc of IgmpHost::SetGroupPool"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DeleteGroupPool
#Description: Delete IGMP Group
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::DeleteGroupPool {args} {
   
    debugPut "enter the proc of IgmpHost::DeleteGroupPool"
    set args [ConvertAttrToLowerCase $args]
    
    #Parse GroupPoolList parameter
    set index [lsearch $args -grouppoollist] 
    if {$index != -1} {
        set GroupPoolList [lindex $args [expr $index + 1]]
        catch { set GroupPoolList [string trimleft $GroupPoolList '\{' ] }
        catch { set GroupPoolList [string trimright $GroupPoolList '\}' ] }

        if {[string tolower $GroupPoolList] !="all"} {
            foreach GroupName $GroupPoolList {
                if {[info exists m_hGroup($GroupName)]} {
                    set group1 $m_hGroup($GroupName)
                    array unset m_hGroup $GroupName
                    stc::delete $group1
                } else {
                    puts "GroupName $GroupName does not exist."
                }
            }
        } else {
           foreach groupname [array names m_hGroup] {
              stc::delete $m_hGroup($groupname)
              array unset m_hGroup $groupname
           }
        }
    } 
    
    debugPut "exit the proc of IgmpHost::DeleteGroupPool"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: SendReport
#Description: Send IGMP Join packet
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::SendReport {args} {
   
    debugPut "enter the proc of IgmpHost::SendReport"
    set args [ConvertAttrToLowerCase $args]

    set hblocklist ""
    set index [lsearch $args -grouppoollist] 
    if {$index != -1} {
        set GroupPoolList [lindex $args [expr $index + 1]]
        catch { set GroupPoolList [string trimleft $GroupPoolList '\{' ] }
        catch { set GroupPoolList [string trimright $GroupPoolList '\}' ] }

        if {[string tolower $GroupPoolList] !="all"} {
            foreach GroupName $GroupPoolList {
                if {[info exists m_hGroup($GroupName)]} {
                    lappend hblocklist $m_hGroup($GroupName)
                } else {
                    puts "GroupName $GroupName does not exist."
                }
            }
        } else {
            set hblocklist [stc::get $m_hIgmpHost -children-IgmpGroupMembership]
        }
        stc::perform IgmpMldJoinGroups -BlockList $hblocklist
    }  else {
        set hblocklist [stc::get $m_hIgmpHost -children-IgmpGroupMembership]
        stc::perform IgmpMldJoinGroups -BlockList $hblocklist
    }  
    
    debugPut "exit the proc of IgmpHost::SendReport"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: SendLeave
#Description: Send IGMP Leave packet
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::SendLeave {args} {
   
    debugPut "enter the proc of IgmpHost::SendLeave"
    set args [ConvertAttrToLowerCase $args]
    
    set hblocklist ""
    set index [lsearch $args -grouppoollist] 
    if {$index != -1} {
        set GroupPoolList [lindex $args [expr $index + 1]]
        catch { set GroupPoolList [string trimleft $GroupPoolList '\{' ] }
        catch { set GroupPoolList [string trimright $GroupPoolList '\}' ] }

        if {[string tolower $GroupPoolList] !="all"} {
            foreach GroupName $GroupPoolList {
                if {[info exists m_hGroup($GroupName)]} {
                    lappend hblocklist $m_hGroup($GroupName)
                } else {
                    puts "GroupName $GroupName does not exist."
                }
            }
        } else {
            set hblocklist [stc::get $m_hIgmpHost -children-IgmpGroupMembership]
        }
        stc::perform IgmpMldLeaveGroups -BlockList $hblocklist
    }  else {
        set hblocklist [stc::get $m_hIgmpHost -children-IgmpGroupMembership]
        stc::perform IgmpMldLeaveGroups -BlockList $hblocklist
    }
    
    debugPut "exit the proc of IgmpHost::SendLeave"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RetrieveRouterStats
#Description: Get IGMP host state
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::RetrieveRouterStats {args} {
   
    debugPut "enter the proc of IgmpHost::RetrieveRouterStats"
    set args1 $args
    set args [ConvertAttrToLowerCase $args]
    
    #Parse AvgJoinLatency parameter
    set index [lsearch $args -avgjoinlatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AvgJoinLatency
    }
    
    #Parse AvgLeaveLatency parameter
    set index [lsearch $args -avgleavelatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] AvgLeaveLatency
    }
    
    #Parse MaxJoinLatency parameter
    set index [lsearch $args -maxjoinlatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MaxJoinLatency
    }
    
    #Parse MaxLeaveLatency parameter
    set index [lsearch $args -maxleavelatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MaxLeaveLatency
    }
    
    #Parse MinJoinLatency parameter
    set index [lsearch $args -minjoinlatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MinJoinLatency
    }
    
    #Parse MinLeaveLatency parameter
    set index [lsearch $args -minleavelatency] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] MinLeaveLatency
    }
    
    #Parse RxFrameCount parameter
    set index [lsearch $args -rxframecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxFrameCount
    }
    
    #Parse TxFrameCount parameter
    set index [lsearch $args -txframecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] TxFrameCount
    }
    #Parse RxIgmpCheckSumErrorCount parameter
    set index [lsearch $args -rxigmpchecksumerrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxIgmpCheckSumErrorCount
    }
    
    #Parse RxIgmpLengthErrorCount parameter
    set index [lsearch $args -rxigmplengtherrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxIgmpLengthErrorCount
    }
    #Parse RxUnknownTypeCount parameter
    set index [lsearch $args -rxunknowntypecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxUnknownTypeCount
    }
    
    #Parse ResultState parameter
    set index [lsearch $args -resultstate] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] ResultState 
    }
    
    #Parse McastCompatibilityMode parameter
    set index [lsearch $args -mcastcompatibilitymode] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] McastCompatibilityMode 
    }
    
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
    set igmpHostResultHandle [$gChassisName cget -m_igmpHostResultHandle ]

    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RefreshResultView -ResultDataSet $igmpHostResultHandle  ]
    } err]} {
        return $errorCode
    }
    
    after 2000
    set result1 [stc::get $m_hIgmpHost -children-IgmpHostResults] 
    if {$result1 != ""} {
        set igmpResult ""   
        set AvgJoinLatency [stc::get $result1 -AvgJoinLatency]
        lappend igmpResult -AvgJoinLatency
        lappend igmpResult $AvgJoinLatency
        set AvgLeaveLatency [stc::get $result1 -AvgLeaveLatency]
        lappend igmpResult -AvgLeaveLatency
        lappend igmpResult $AvgLeaveLatency
        set MaxJoinLatency [stc::get $result1 -MaxJoinLatency]
        lappend igmpResult -MaxJoinLatency
        lappend igmpResult $MaxJoinLatency
        set MaxLeaveLatency [stc::get $result1 -MaxLeaveLatency]
        lappend igmpResult -MaxLeaveLatency
        lappend igmpResult $MaxLeaveLatency
        set McastCompatibilityMode [stc::get $result1 -McastCompatibilityMode]
        lappend igmpResult -McastCompatibilityMode
        lappend igmpResult $McastCompatibilityMode
        set MinJoinLatency [stc::get $result1 -MinJoinLatency]
        lappend igmpResult -MinJoinLatency
        lappend igmpResult $MinJoinLatency
        set MinLeaveLatency [stc::get $result1 -MinLeaveLatency]
        lappend igmpResult -MinLeaveLatency
        lappend igmpResult $MinLeaveLatency
        set ResultState [stc::get $result1 -ResultState]
        lappend igmpResult -ResultState
        lappend igmpResult $ResultState
        set RxFrameCount [stc::get $result1 -RxFrameCount]
        lappend igmpResult -RxFrameCount
        lappend igmpResult $RxFrameCount
        set RxIgmpCheckSumErrorCount [stc::get $result1 -RxIgmpCheckSumErrorCount]
        lappend igmpResult -RxIgmpCheckSumErrorCount
        lappend igmpResult $RxIgmpCheckSumErrorCount
        set RxIgmpLengthErrorCount [stc::get $result1 -RxIgmpLengthErrorCount]
        lappend igmpResult -RxIgmpLengthErrorCount
        lappend igmpResult $RxIgmpLengthErrorCount
        set RxUnknownTypeCount [stc::get $result1 -RxUnknownTypeCount]
        lappend igmpResult -RxUnknownTypeCount
        lappend igmpResult $RxUnknownTypeCount
        set TxFrameCount [stc::get $result1 -TxFrameCount]
        lappend igmpResult -TxFrameCount
        lappend igmpResult $TxFrameCount
    } else {
        set igmpResult ""   
        set AvgJoinLatency 0
        lappend igmpResult -AvgJoinLatency
        lappend igmpResult $AvgJoinLatency
        set AvgLeaveLatency 0
        lappend igmpResult -AvgLeaveLatency
        lappend igmpResult $AvgLeaveLatency
        set MaxJoinLatency 0
        lappend igmpResult -MaxJoinLatency
        lappend igmpResult $MaxJoinLatency
        set MaxLeaveLatency 0
        lappend igmpResult -MaxLeaveLatency
        lappend igmpResult $MaxLeaveLatency
        set McastCompatibilityMode "V2"
        lappend igmpResult -McastCompatibilityMode
        lappend igmpResult $McastCompatibilityMode
        set MinJoinLatency 0
        lappend igmpResult -MinJoinLatency
        lappend igmpResult $MinJoinLatency
        set MinLeaveLatency 0
        lappend igmpResult -MinLeaveLatency
        lappend igmpResult $MinLeaveLatency
        set ResultState "NONE"
        lappend igmpResult -ResultState
        lappend igmpResult $ResultState
        set RxFrameCount 0
        lappend igmpResult -RxFrameCount
        lappend igmpResult $RxFrameCount
        set RxIgmpCheckSumErrorCount 0
        lappend igmpResult -RxIgmpCheckSumErrorCount
        lappend igmpResult $RxIgmpCheckSumErrorCount
        set RxIgmpLengthErrorCount 0
        lappend igmpResult -RxIgmpLengthErrorCount
        lappend igmpResult $RxIgmpLengthErrorCount
        set RxUnknownTypeCount 0
        lappend igmpResult -RxUnknownTypeCount
        lappend igmpResult $RxUnknownTypeCount
        set TxFrameCount 0
        lappend igmpResult -TxFrameCount
        lappend igmpResult $TxFrameCount
    }

    if {$args==""} {
        return $igmpResult
    }
    
    debugPut "exit the proc of IgmpHost::RetrieveRouterStats"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RetrieveIpv4Address
#Description: Retrieve current IP address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::RetrieveIpv4Address {args} {
    set IpAddress [stc::get $m_hIpv4 -address]
    return $IpAddress
}

############################################################################
#APIName: RetrieveMacAddress
#Description: Retrieve current MAC address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpHost::RetrieveMacAddress {args} {
    return $m_hMacAddress
}

############################################################################
#APIName: SetSession
#Description: Configure IGMP router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::SetSession {args} {
   
    debugPut "enter the proc of IgmpSession::SetSession"
    set args [ConvertAttrToLowerCase $args]
    
    #Parse TesterIp parameter
    set index [lsearch $args -testerip] 
    if {$index != -1} {
        set TesterIp [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify TesterIp "
    } 
    set index [lsearch $args -srcmac] 
    if {$index != -1} {
        set SrcMac [lindex $args [expr $index + 1]]
        if {$m_portType == "ethernet"} {
            stc::config $m_hMacAddress -SourceMac $SrcMac
        }
    }
        
    #Parse ProtocolType parameter
    set index [lsearch $args -protocoltype] 
    if {$index != -1} {
        set ProtocolType [lindex $args [expr $index + 1]]
        set ProtocolType [string toupper $ProtocolType]
    } 
    
    #Parse IgnoreV1Reports parameter
    set index [lsearch $args -ignorev1reports] 
    if {$index != -1} {
        set IgnoreV1Reports [lindex $args [expr $index + 1]]
        set IgnoreV1Reports [string toupper $IgnoreV1Reports]
    } 
    
    #Parse Ipv4DontFragment parameter
    set index [lsearch $args -ipv4dontfragment] 
    if {$index != -1} {
        set Ipv4DontFragment [lindex $args [expr $index + 1]]
        set Ipv4DontFragment [string toupper $Ipv4DontFragment]
    } 
    
    #Parse LastMemberQueryCount parameter
    set index [lsearch $args -lastmemberquerycount] 
    if {$index != -1} {
        set LastMemberQueryCount [lindex $args [expr $index + 1]]
    } 
    
    #Parse LastMemberQueryInterval parameter
    set index [lsearch $args -lastmemberqueryinterval] 
    if {$index != -1} {
        set LastMemberQueryInterval [lindex $args [expr $index + 1]]
    } 
    
    #Parse QueryInterval parameter
    set index [lsearch $args -queryinterval] 
    if {$index != -1} {
        set QueryInterval [lindex $args [expr $index + 1]]
    } 
    
    #Parse QueryResponseUperBound parameter
    set index [lsearch $args -queryresponseuperbound] 
    if {$index != -1} {
        set QueryResponseUperBound [lindex $args [expr $index + 1]]
    } 
    
    #Parse StartupQueryCount parameter
    set index [lsearch $args -startupquerycount] 
    if {$index != -1} {
        set StartupQueryCount [lindex $args [expr $index + 1]]
    } 
    
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        if {[string tolower $Active] =="enable" ||[string tolower $Active] =="true"} {
            stc::config $m_hIgmpRouter -Active TRUE
        } else {
            stc::config $m_hIgmpRouter -active FALSE
        }
    }
    
    set igmproute1 $m_hIgmpRouter
    if {[info exists ProtocolType]} {
        set ProtocolType [string toupper $ProtocolType]
        if {$ProtocolType =="IGMPV1"} {
            stc::config $igmproute1 -Version IGMP_V1
            if {[info exists IgnoreV1Reports]} {
                stc::config $igmproute1 -IgnoreV1Reports $IgnoreV1Reports
            }
        } elseif {$ProtocolType =="IGMPV2"} {
            stc::config $igmproute1 -Version IGMP_V2
        } elseif {$ProtocolType =="IGMPV3"} {
            stc::config $igmproute1 -Version IGMP_V3
        }
    }
    if {[info exists Ipv4DontFragment]} {
        stc::config $igmproute1 -Ipv4DontFragment  $Ipv4DontFragment
    }
    if {[info exists LastMemberQueryCount]} {
        stc::config $igmproute1 -LastMemberQueryCount $LastMemberQueryCount
    }
    if {[info exists LastMemberQueryInterval]} {
        stc::config $igmproute1 -LastMemberQueryInterval $LastMemberQueryInterval
    }
    if {[info exists QueryInterval]} {
        stc::config $igmproute1  -QueryInterval  $QueryInterval
    }
    if {[info exists QueryResponseUperBound]} {
        stc::config $igmproute1 -QueryResponseInterval $QueryResponseUperBound
    }
    if {[info exists StartupQueryCount]} {
        stc::config $igmproute1 -StartupQueryCount $StartupQueryCount
    }
    
    stc::config $m_hIpv4 -Address $TesterIp 
    SetMacAddress $TesterIp  
     
    stc::apply
    debugPut "exit the proc of IgmpSession::SetSession"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: RetrieveRouter
#Description: Retrieve router atributes
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::RetrieveRouter {args} {
    
    debugPut "enter the proc of IgmpSession::RetrieveRouter"
    set args [ConvertAttrToLowerCase $args]
    
    set routerConfig ""
    lappend routerConfig "-testerip"
    lappend routerConfig "[stc::get $m_hIpv4 -Address]"
    if {$m_portType == "ethernet"} {
        lappend routerConfig "-srcmac"
        lappend routerConfig "[stc::get $m_hMacAddress  -SourceMac]"
    }
    lappend routerConfig "-protocoltype"
    lappend routerConfig "[stc::get $m_hIgmpRouter -Version]"
    lappend routerConfig "-active"
    lappend routerConfig "[stc::get $m_hIgmpRouter -Active]"
    lappend routerConfig "-ignorev1reports"
    lappend routerConfig "[stc::get $m_hIgmpRouter -IgnoreV1Reports]"
    lappend routerConfig "-ipv4dontfragment"
    lappend routerConfig "[stc::get $m_hIgmpRouter -Ipv4DontFragment]"
    lappend routerConfig "-lastmemberquerycount"
    lappend routerConfig "[stc::get $m_hIgmpRouter -LastMemberQueryCount]"
    lappend routerConfig "-lastmemberqueryinterval"
    lappend routerConfig "[stc::get $m_hIgmpRouter -LastMemberQueryInterval]"
    lappend routerConfig "-queryinterval"
    lappend routerConfig "[stc::get $m_hIgmpRouter -QueryInterval]"
    lappend routerConfig "-queryresponseuperbound"
    lappend routerConfig "[stc::get $m_hIgmpRouter -QueryResponseInterval]"
    lappend routerConfig "-startupquerycount"
    lappend routerConfig "[stc::get $m_hIgmpRouter -StartupQueryCount]"
 
     if {$args == "" } {
        debugPut "exit the proc of IgmpSession::RetrieveRouter"
        return $routerConfig
    } else {
        array set arr $routerConfig
        foreach {name valueVar}  $args {      
 
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 
    
        debugPut "exit the proc of IgmpSession::RetrieveRouter"
        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: Enable
#Description: Enable IGMP router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::Enable {args} {

    stc::config $m_hIgmpRouter -Active TRUE
    stc::apply
}

############################################################################
#APIName: Disable
#Description: Disable IGMp router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::Disable {args} {

     stc::config $m_hIgmpRouter -Active FALSE
     stc::apply
}

############################################################################
#APIName: RetrieveRouterStatus
#Description: Retrieve IGMp router status
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::RetrieveRouterStatus {args} {
   
    debugPut "enter the proc of IgmpSession::RetrieveRouterStatus"
    set args1 $args
    set args [ConvertAttrToLowerCase $args]
    
    #Parse McastCompatibilityMode parameter
    set index [lsearch $args -mcastcompatibilitymode] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] McastCompatibilityMode
    } 
    
    #Parse State parameter
    set index [lsearch $args -state] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] State
    } 

    set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_igmpRouterResultHandle ]
     }
     set igmpRouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $igmpRouterResultHandle  ]
     } err]} {
         return $errorCode
     }

    after 2000
    set routerResult [stc::get $m_hIgmpRouter -children-IgmpRouterResults]
    set ResultList ""
    set McastCompatibilityMode [stc::get $routerResult -McastCompatibilityMode]
    lappend ResultList -McastCompatibilityMode
    lappend ResultList $McastCompatibilityMode
    set State [stc::get $routerResult -ResultState]
    lappend ResultList -State
    lappend ResultList $State
    if {$args ==""} {
        return $ResultList
    } 
    debugPut "exit the proc of IgmpSession::RetrieveRouterStatus"
    return $::mainDefine::gSuccess 

}

############################################################################
#APIName: StartAllQuery
#Description: Start IGMP query
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::StartAllQuery {args} {
   
    debugPut "enter the proc of IgmpSession::StartAllQuery"
    
    stc::perform IgmpMldStartQuerier -BlockList $m_hIgmpRouter
    
    debugPut "exit the proc of IgmpSession::StartAllQuery"
    return $::mainDefine::gSuccess 

}

############################################################################
#APIName: StopAllQuery
#Description: Stop IGMP query
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::StopAllQuery {args} {
    
    debugPut "enter the proc of IgmpSession::StopAllQuery"
    
    stc::perform IgmpMldStopQuerier -BlockList $m_hIgmpRouter
    
    debugPut "exit the proc of IgmpSession::StopAllQuery"
    return $::mainDefine::gSuccess 
}


############################################################################
#APIName: RetrieveRouterStats
#Description: Retrieve IGMP router statistics
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::RetrieveRouterStats {args} {
    
    debugPut "enter the proc of IgmpSession::RetrieveRouterStats"
    set args1 $args
    set args [ConvertAttrToLowerCase $args]
    
    #Parse RxFrameCount parameter
    set index [lsearch $args -rxframecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxFrameCount
    } 
    
    #Parameter RxIgmpCheckSumError parameter
    set index [lsearch $args -rxigmpchecksumerror] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxIgmpCheckSumError
    } 
    
    #Parse RxIgmpLengthErrorCount parameter
    set index [lsearch $args -rxigmplengtherrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxIgmpLengthErrorCount
    } 
    
    #Parse RxUnkownTypeCount parameter
    set index [lsearch $args -rxunkowntypecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxUnkownTypeCount
    } 
    
    #Parse TxFrameCount parameter
    set index [lsearch $args -txframecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] TxFrameCount
    } 

    set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_igmpRouterResultHandle ]
     }
     set igmpRouterResultHandle $::mainDefine::result
     set errorCode 1
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $igmpRouterResultHandle  ]
     } err]} {
         return $errorCode
     }

    after 2000
    set routerResult [stc::get $m_hIgmpRouter -children-IgmpRouterResults]
    set ResultList ""
    set RxFrameCount [stc::get $routerResult -RxFrameCount]
    lappend ResultList -RxFrameCount
    lappend ResultList $RxFrameCount
    set RxIgmpCheckSumError [stc::get $routerResult -RxIgmpCheckSumErrorCount]
    lappend ResultList -RxIgmpCheckSumError
    lappend ResultList $RxIgmpCheckSumError
    set RxIgmpLengthErrorCount [stc::get $routerResult -RxIgmpLengthErrorCount]
    lappend ResultList -RxIgmpLengthErrorCount
    lappend ResultList $RxIgmpLengthErrorCount
    set RxUnkownTypeCount [stc::get $routerResult -RxUnknownTypeCount]
    lappend ResultList -RxUnkownTypeCount
    lappend ResultList $RxUnkownTypeCount
    set TxFrameCount [stc::get $routerResult -TxFrameCount]
    lappend ResultList -TxFrameCount
    lappend ResultList $TxFrameCount
    if {$args ==""} {
        return $ResultList
    } 
    
    debugPut "exit the proc of IgmpSession::RetrieveRouterStats"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveIpv4Address
#Description: Retrieve current Ipv4 address
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body IgmpSession::RetrieveIpv4Address {args} {
    set IpAddress [stc::get $m_hIpv4 -address]
    return $IpAddress
}
