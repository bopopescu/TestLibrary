###########################################################################
#                                                                        
#  File Name£ºMLDProtocol.tcl                                                                                              
# 
#  Description£ºDefinition of MLD router, MLD host, and its methods                                     
# 
#  Author£º Jaimin
#
#  Create Time:  2007.4.21
#
#  Versioin£º1.0 
# 
#  History£º 
# 
##########################################################################

::itcl::class MldHost {
    #Inherit from Host 
    inherit Host

    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hHost
    public variable m_hostName
    public variable m_hMldHost
    public variable m_hGroup
    public variable m_hIpv6
    public variable m_hResultDataSet
    public variable m_portType
    
    constructor {hostName hHost hPort portName hProject hIpv6 portType}  \
        { Host::constructor $hostName $hHost $hPort $portName $hProject $hIpv6 "ipv6" $portType} {   

        set m_hostName $hostName       
        set m_hHost $hHost
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_hIpv6 $hIpv6
        set m_portType $portType 
        
        set host1 [stc::create MldHostConfig -under $m_hHost]
        set m_hMldHost $host1
       
        stc::config $host1 -UsesIf-targets $m_hIpv6       
    }

    destructor {
    }

    public method SetSession
    public method Enable
    public method Disable
    public method CreateGroupPool
    public method SetGroupPool
    public method DeleteGroupPool
    public method SendReport
    public method SendLeave
    public method RetrieveRouterStats
   
}

::itcl::class MldSession {
    #Inherit from Router
    inherit Router
    
    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName  
    public variable m_hMldRouter  
    public variable m_hResultDataSet
    public variable m_hIpv61
    public variable m_hIpv62  
    public variable m_portType
 
    constructor {routerName routerType routerId hRouter hPort portName hProject hIpv61 hIpv62 portType} \
        { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
        
        set m_routerName $routerName       
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_hIpv61 $hIpv61
        set m_hIpv62 $hIpv62
        set m_portType $portType

        #Create Mld router handle
        set mldroute1 [stc::create MldRouterConfig -under $m_hRouter]
        set m_hMldRouter $mldroute1

        set m_hIpAddress $hIpv61

        #Get Ethernet interface
        #added by yuanfen 8.9 2011
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
        
        stc::config $mldroute1 -UsesIf-targets $hIpv61
    }
    
    destructor {
    }

    public method SetSession
    public method RetrieveRouter
    public method RetrieveRouterStats
    public method Enable
    public method Disable
    public method RetrieveRouterStatus 
    public method StartAllQuery
    public method StopAllQuery
}


############################################################################
#APIName: SetSession
#Description: Config MLD host
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::SetSession {args} {
   
    debugPut "enter the proc of MldHost::SetSession"
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
    
    set index [lsearch $args -ipv6addr] 
    if {$index != -1} {
        set Ipv6Addr [lindex $args [expr $index + 1]]
        stc::config $m_hIpv6 -Address $Ipv6Addr
    } 
    
    set index [lsearch $args -ipv6addrgateway] 
    if {$index != -1} {
        set Ipv6AddrGateway [lindex $args [expr $index + 1]]
        stc::config $m_hIpv6 -Gateway $Ipv6AddrGateway
    }
    
    set index [lsearch $args -ipv6addrprefixlen] 
    if {$index != -1} {
        set Ipv6AddrPrefixLen [lindex $args [expr $index + 1]]
        stc::config $m_hIpv6 -PrefixLength $Ipv6AddrPrefixLen
    }
    
    #Parse Count parameter
    set index [lsearch $args -count] 
    if {$index != -1} {
        set Count [lindex $args [expr $index + 1]]
        set Ether1 [stc::get $m_hHost -children-EthIIIf]
        #stc::config $Ether1 -IfRecycleCount $Count
        #stc::config $m_hIpv6 -IfRecycleCount $Count
        stc::config $m_hHost -DeviceCount $Count
    }
    
    #Parse Increase parameter
    set index [lsearch $args -increase] 
    if {$index != -1} {
        set Increase [lindex $args [expr $index + 1]]
        
        set step ""
        for {set i 0} {$i <8} { incr i} {
            set mod1 [expr $Increase%65536]
            if {$step ==""} {
                set step [format %x $mod1]
            } else {
                set step [format %x $mod1]:$step
            }
            set Increase [expr $Increase/65536]
        }
        stc::config $m_hIpv6 -AddrStep $step
    } 

    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        if {[string tolower $Active] =="enable" ||[string tolower $Active] =="true"} {
            stc::config $m_hMldHost -Active TRUE
        } else {
            stc::config $m_hMldHost -active FALSE
        }
    } 
     
    set index [lsearch $args -sendgrouprate] 
    if {$index != -1} {
        set SendGroupRate [lindex $args [expr $index + 1]]
        set hIgmpport [stc::get $m_hPort -children-MldPortConfig]
        stc::config $hIgmpport -RatePps $SendGroupRate
    }   
    
    #Parse ProtocolType parameter
    set index [lsearch $args -protocoltype] 
    if {$index != -1} {
        set ProtocolType [lindex $args [expr $index + 1]]
        set ProtocolType [string toupper $ProtocolType]
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
    
    set host1 $m_hMldHost
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
    if {[info exists ProtocolType]} {
        set ProtocolType [string toupper $ProtocolType]
        if {$ProtocolType == "MLDV1"} {
            stc::config $host1 -Version MLD_V1
        } elseif {$ProtocolType == "MLDV2"} {
            stc::config $host1 -Version MLD_V2 
        } 
    }
   
    debugPut "exit the proc of MldHost::SetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Enable
#Description: Enalbe Mld Host
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body MldHost::Enable {args} {
   
    debugPut "enter the proc of MldHost::Enable"
    stc::config $m_hMldHost -Active TRUE
    stc::apply
    stc::perform DeviceStart -DeviceList $m_hHost
    debugPut "exit the proc of MldHost::Enable"  

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Disable
#Description: Disable Mld Host
#Input: none
#Output: none
#Coded by: Shi Yunzhi
#############################################################################
::itcl::body MldHost::Disable {args} {

    debugPut "enter the proc of MldHost::Disable"
    stc::perform DeviceStop -DeviceList $m_hHost
    stc::config $m_hMldHost -Active FALSE
    stc::apply
    debugPut "exit the proc of MldHost::Disable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateGroupPool
#Description: Create MLD group pool
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::CreateGroupPool {args} {
    
    debugPut "enter the proc of MldHost::CreateGroupPool"
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
        set PrefixLen 64
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
        set SrcStartIP 2000::3
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
        set SrcPrefixLen 64
    }
    
    #Parse FilterMode parameter
    set index [lsearch $args -filtermode] 
    if {$index != -1} {
        set FilterMode [lindex $args [expr $index + 1]]
    } else  {
        set FilterMode EXCLUDE
    }
    
    set group1 [stc::create MldGroupMembership -under $m_hMldHost]
    stc::config $group1 -Name $GroupName
    set m_hGroup($GroupName) $group1
    set Ipv6Group1 [stc::create Ipv6Group -under $m_hProject]
    set Ipv6NetworkBlock1 [lindex [stc::get $Ipv6Group1 -children-Ipv6NetworkBlock] 0]
    stc::config $Ipv6NetworkBlock1 -StartIpList $StartIP -PrefixLength $PrefixLen -NetworkCount $GroupCnt \
        -AddrIncrement $GroupIncrement -Active TRUE 
        
    set ::mainDefine::gPoolCfgBlock($GroupName) $Ipv6NetworkBlock1 
         
    stc::config $group1 -SubscribedGroups-targets $Ipv6Group1
    set version1 [stc::get $m_hMldHost -Version]
    if {[string toupper $version1] =="MLD_V2"} {
        stc::config $group1 -FilterMode [string toupper $FilterMode] -UserDefinedSources TRUE
        set Ipv6NetworkBlock2 [lindex [stc::get $group1 -children-Ipv6NetworkBlock] 0]
        stc::config $Ipv6NetworkBlock2 -StartIpList $SrcStartIP -PrefixLength $SrcPrefixLen \
            -NetworkCount $SrcCnt -AddrIncrement $SrcIncrement
    }  
    
    debugPut "exit the proc of MldHost::CreateGroupPool"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: SetGroupPool
#Description: Configure MLD Group pool
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::SetGroupPool {args} {
    
    debugPut "enter the proc of MldHost::SetGroupPool"
    set args [ConvertAttrToLowerCase $args]

    #Parse GroupName parameter
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
    
    #Parse SrcPrefixLen parameter
    set index [lsearch $args -srcprefixlen] 
    if {$index != -1} {
        set SrcPrefixLen [lindex $args [expr $index + 1]]
    } 
    
    #Parse FilterMode parameter
    set index [lsearch $args -filtermode] 
    if {$index != -1} {
        set FilterMode [lindex $args [expr $index + 1]]
        set FilterMode [string toupper $FilterMode]
    }
    
    set Ipv6Group1 [stc::create Ipv6Group -under $m_hProject -Active TRUE ]
    set Ipv6NetworkBlock1 [lindex [stc::get $Ipv6Group1 -children-Ipv6NetworkBlock] 0]
    if {[info exists StartIP]} {
        stc::config $Ipv6NetworkBlock1 -StartIpList $StartIP 
    }
    if {[info exists PrefixLen]} {
        stc::config $Ipv6NetworkBlock1 -PrefixLength $PrefixLen 
    }
    if {[info exists GroupCnt]} {
        stc::config $Ipv6NetworkBlock1 -NetworkCount $GroupCnt 
    }
    if {[info exists GroupIncrement]} {
        stc::config $Ipv6NetworkBlock1 -AddrIncrement $GroupIncrement 
    }
    stc::config $group1 -SubscribedGroups-targets $Ipv6Group1
    set version1 [stc::get $m_hMldHost -Version]
    
    if {$version1 =="MLD_V2"} {
        if {[info exists FilterMode]} {
            stc::config $group1 -FilterMode [string toupper $FilterMode]
        }
        stc::config $group1 -UserDefinedSources TRUE
        
        set Ipv6NetworkBlock2 [lindex [stc::get $group1 -children-Ipv6NetworkBlock] 0]
        if {[info exists SrcStartIP]} {
            stc::config $Ipv6NetworkBlock2 -StartIpList $SrcStartIP
        }
        if {[info exists SrcPrefixLen]} {
            stc::config $Ipv6NetworkBlock2 -PrefixLength $SrcPrefixLen
        }
        if {[info exists SrcIncrement]} {
            stc::config $Ipv6NetworkBlock2 -AddrIncrement $SrcIncrement
        }
        if {[info exists SrcCnt]} {
            stc::config $Ipv6NetworkBlock2 -NetworkCount $SrcCnt
        }
    }    
    
    debugPut "exit the proc of MldHost::SetGroupPool"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: DeleteGroupPool
#Description: Delete MLD Host group pool
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::DeleteGroupPool {args} {
     
    debugPut "enter the proc of MldHost::DeleteGroupPool"
    set args [ConvertAttrToLowerCase $args]
        
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
    
    debugPut "exit the proc of MldHost::DeleteGroupPool"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: SendReport
#Description: Send Mld Report
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::SendReport {args} {
     
    debugPut "enter the proc of MldHost::SendReport"
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
            set hblocklist [stc::get $m_hMldHost -children-MldGroupMembership]
        }
        stc::perform IgmpMldJoinGroups -BlockList $hblocklist
    } else {
        set hblocklist [stc::get $m_hMldHost -children-MldGroupMembership]
        stc::perform IgmpMldJoinGroups -BlockList $hblocklist
    }
    
    debugPut "exit the proc of MldHost::SendReport"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: SendLeave
#Description: Send MLD leave
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::SendLeave {args} {
    
    debugPut "enter the proc of MldHost::SendLeave"
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
            set hblocklist [stc::get $m_hMldHost -children-MldGroupMembership]
        }
        stc::perform IgmpMldLeaveGroups -BlockList $hblocklist
    } else {
        set hblocklist [stc::get $m_hMldHost -children-MldGroupMembership]
        stc::perform IgmpMldLeaveGroups -BlockList $hblocklist
    }
    
    debugPut "exit the proc of MldHost::SendLeave"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: RetrieveRouterStats
#Description: Get MLD host statistics
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldHost::RetrieveRouterStats {args} {
   
    debugPut "enter the proc of MldHost::RetrieveRouterStats"
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
    #Parse RxMldCheckSumErrorCount parameter
    set index [lsearch $args -rxmldchecksumerrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxMldCheckSumErrorCount
    }
    
    #Parse RxMldLengthErrorCount parameter
    set index [lsearch $args -rxmldlengtherrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxMldLengthErrorCount
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
    
     set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_mldHostResultHandle ]
     }
     set mldHostResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $mldHostResultHandle  ]
     } err]} {
         return $errorCode
     }

    after 2000
    set result1 [stc::get $m_hMldHost -children-MldHostResults] 
    set mldResult ""   
    set AvgJoinLatency [stc::get $result1 -AvgJoinLatency]
    lappend mldResult -AvgJoinLatency
    lappend mldResult $AvgJoinLatency
    set AvgLeaveLatency [stc::get $result1 -AvgLeaveLatency]
    lappend mldResult -AvgLeaveLatency
    lappend mldResult $AvgLeaveLatency
    set MaxJoinLatency [stc::get $result1 -MaxJoinLatency]
    lappend mldResult -MaxJoinLatency
    lappend mldResult $MaxJoinLatency
    set MaxLeaveLatency [stc::get $result1 -MaxLeaveLatency]
    lappend mldResult -MaxLeaveLatency
    lappend mldResult $MaxLeaveLatency
    set McastCompatibilityMode [stc::get $result1 -McastCompatibilityMode]
    lappend mldResult -McastCompatibilityMode
    lappend mldResult $McastCompatibilityMode
    set MinJoinLatency [stc::get $result1 -MinJoinLatency]
    lappend mldResult -MinJoinLatency
    lappend mldResult $MinJoinLatency
    set MinLeaveLatency [stc::get $result1 -MinLeaveLatency]
    lappend mldResult -MinLeaveLatency
    lappend mldResult $MinLeaveLatency
    set ResultState [stc::get $result1 -ResultState]
    lappend mldResult -ResultState
    lappend mldResult $ResultState
    set RxFrameCount [stc::get $result1 -RxFrameCount]
    lappend mldResult -RxFrameCount
    lappend mldResult $RxFrameCount
    set RxMldCheckSumErrorCount [stc::get $result1 -RxMldCheckSumErrorCount]
    lappend mldResult -RxMldCheckSumErrorCount
    lappend mldResult $RxMldCheckSumErrorCount
    set RxMldLengthErrorCount [stc::get $result1 -RxMldLengthErrorCount]
    lappend mldResult -RxMldLengthErrorCount
    lappend mldResult $RxMldLengthErrorCount
    set RxUnknownTypeCount [stc::get $result1 -RxUnknownTypeCount]
    lappend mldResult -RxUnknownTypeCount
    lappend mldResult $RxUnknownTypeCount
    set TxFrameCount [stc::get $result1 -TxFrameCount]
    lappend mldResult -TxFrameCount
    lappend mldResult $TxFrameCount
    if {$args==""} {
        return $mldResult
    }
    
    debugPut "exit the proc of MldHost::RetrieveRouterStats"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: SetSession
#Description: Configure MLD router
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::SetSession {args} {
   
    debugPut "enter the proc of MldSession::SetSession"
    set args [ConvertAttrToLowerCase $args]
   
    #Parse TesterIp parameter
    set index [lsearch $args -testerip] 
    if {$index != -1} {
        set TesterIp [lindex $args [expr $index + 1]]
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
            stc::config $m_hMldRouter -Active TRUE
        } else {
            stc::config $m_hMldRouter -active FALSE
        }
    } 
    
    set mldroute1 $m_hMldRouter
    if {[info exists ProtocolType]} {
       set ProtocolType [string toupper $ProtocolType]
        if {$ProtocolType =="MLDV1"} {
            stc::config $mldroute1 -Version MLD_V1
        } elseif {$ProtocolType =="MLDV2"} {
            stc::config $mldroute1 -Version MLD_V2
        } 
    }
    
    if {[info exists LastMemberQueryCount]} {
        stc::config $mldroute1 -LastMemberQueryCount $LastMemberQueryCount
    }
    if {[info exists LastMemberQueryInterval]} {
        stc::config $mldroute1 -LastMemberQueryInterval $LastMemberQueryInterval
    }
    if {[info exists QueryInterval]} {
        stc::config $mldroute1  -QueryInterval  $QueryInterval
    }
    if {[info exists QueryResponseUperBound]} {
        stc::config $mldroute1 -QueryResponseInterval $QueryResponseUperBound
    }
    if {[info exists StartupQueryCount]} {
        stc::config $mldroute1 -StartupQueryCount $StartupQueryCount
    }
    stc::config $m_hIpv62 -Address $TesterIp 
    SetMacAddress $TesterIp  "Ipv6"
     
    stc::apply
    debugPut "exit the proc of MldSession::SetSession"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouter
#Description: Get router attributes
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::RetrieveRouter {args} {
    
    debugPut "enter the proc of MldSession::RetrieveRouter"
    set args [ConvertAttrToLowerCase $args]
   
    set routerConfig ""
    lappend routerConfig "-testerip"
    lappend routerConfig "[stc::get $m_hIpv61 -Address]"
    if {$m_portType == "ethernet"} {
        lappend routerConfig "-srcmac"
        lappend routerConfig "[stc::get $m_hMacAddress  -SourceMac]"
    }
    lappend routerConfig "-protocoltype"
    lappend routerConfig "[stc::get $m_hMldRouter -Version]"
    lappend routerConfig "-active"
    lappend routerConfig "[stc::get $m_hMldRouter -Active]"
    lappend routerConfig "-lastmemberquerycount"
    lappend routerConfig "[stc::get $m_hMldRouter -LastMemberQueryCount]"
    lappend routerConfig "-lastmemberqueryinterval"
    lappend routerConfig "[stc::get $m_hMldRouter -LastMemberQueryInterval]"
    lappend routerConfig "-queryinterval"
    lappend routerConfig "[stc::get $m_hMldRouter -QueryInterval]"
    lappend routerConfig "-queryresponseuperbound"
    lappend routerConfig "[stc::get $m_hMldRouter -QueryResponseInterval]"
    lappend routerConfig "-startupquerycount"
    lappend routerConfig "[stc::get $m_hMldRouter -StartupQueryCount]"
 
     if {$args == "" } {
        debugPut "exit the proc of MldSession::RetrieveRouter"
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
    
        debugPut "exit the proc of MldSession::RetrieveRouter"
        return $::mainDefine::gSuccess
    }
}

::itcl::body MldSession::Enable {args} {

    stc::config $m_hMldRouter -Active TRUE
    stc::apply
}


::itcl::body MldSession::Disable {args} {

    stc::config $m_hMldRouter -Active FALSE
    stc::apply
}

############################################################################
#APIName: RetrieveRouterStatus
#Description: Retrieve MLD router status
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::RetrieveRouterStats {args} {
   
    debugPut "enter the proc of MldSession::RetrieveRouterStats"
    set args1 $args
    set args [ConvertAttrToLowerCase $args]
    
    #Parse RxFrameCount parameter
    set index [lsearch $args -rxframecount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxFrameCount
    } 
    
    #Parse RxMldCheckSumError parameter
    set index [lsearch $args -rxmldchecksumerror] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxMldCheckSumError
    } 
    
    #Parse RxMldLengthErrorCount parameter
    set index [lsearch $args -rxmldlengtherrorcount] 
    if {$index != -1} {
        upvar [lindex $args1 [expr $index + 1]] RxMldLengthErrorCount
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
   
    after 2000
    set routerResult [lindex [stc::get $m_hMldRouter -children-MldRouterResults] 0]
    set ResultList ""
    set RxFrameCount [stc::get $routerResult -RxFrameCount]
    lappend ResultList -RxFrameCount
    lappend ResultList $RxFrameCount
    set RxMldCheckSumError [stc::get $routerResult -RxMldCheckSumErrorCount]
    lappend ResultList -RxMldCheckSumError
    lappend ResultList $RxMldCheckSumError
    set RxMldLengthErrorCount [stc::get $routerResult -RxMldLengthErrorCount ]
    lappend ResultList -RxMldLengthErrorCount
    lappend ResultList $RxMldLengthErrorCount
    set RxUnkownTypeCount [stc::get $routerResult -RxUnknownTypeCount]
    lappend ResultList -RxUnkownTypeCount
    lappend ResultList $RxUnkownTypeCount
    set TxFrameCount [stc::get $routerResult -TxFrameCount]
    lappend ResultList -TxFrameCount
    lappend ResultList $TxFrameCount  
    
    if {$args ==""} {
        return $ResultList
    }  
    
    debugPut "exit the proc of MldSession::RetrieveRouterStats"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouterStatus
#Description: Get MLD Router status
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::RetrieveRouterStatus {args} {
     
    debugPut "enter the proc of MldSession::RetrieveRouterStatus"
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
          set ::mainDefine::result [$::mainDefine::objectName cget -m_mldRouterResultHandle ]
     }
     set mldRouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $mldRouterResultHandle  ]
     } err]} {
         return $errorCode
     }

    after 2000
    set routerResult [lindex [stc::get $m_hMldRouter -children-MldRouterResults] 0]
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
    
    debugPut "exit the proc of MldSession::RetrieveRouterStatus"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: StartAllQuery
#Description: Start all MLD query
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::StartAllQuery {args} {
    
    debugPut "enter the proc of MldSession::StartAllQuery"
    
    stc::perform IgmpMldStartQuerier -BlockList $m_hMldRouter
    
    debugPut "exit the proc of MldSession::StartAllQuery"
    return $::mainDefine::gSuccess 

}

############################################################################
#APIName: StopAllQuery
#Description: Stop all MLD query
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body MldSession::StopAllQuery {args} {
    
    debugPut "enter the proc of MldSession::StopAllQuery"
    
    stc::perform IgmpMldStopQuerier -BlockList $m_hMldRouter
    
    debugPut "exit the proc of MldSession::StopAllQuery"
    return $::mainDefine::gSuccess 
}