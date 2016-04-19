###################################################################################
#                                                                        
#  Filename£ºPIMProtocol.tcl                                                                                              
# 
#  Description£ºDefinition of PIM Router class and relevant API                                    
# 
#  Creator£º Tony
#
#  Time£º 2007.6.17
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################
############################################################################
#APIName: GetGatewayIpv6
#Description: According to input IPv6 address,automatically get gateway address
#Input:  ipv6Addr - input ipv6 address
#Output: Automatically computed gateway address
#Coded by: Tony
#############################################################################
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

::itcl::class PimSession {
    #Inherit Router class
    inherit Router

    #Variables
    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName
    public variable m_routerType
    
    public variable m_hPimRouterConfig
    public variable m_hPimRouterResult ""
    public variable m_hRipRouteGenParams 
    public variable m_hIpv4If  ""
    public variable m_hIpv6If1 ""
    public variable m_hIpv6If2 ""
    public variable m_hL2If  ""
    public variable m_isInitialized "FALSE"

    #Relevant variable definition of PIM Group list 
    public variable m_PimGroupNameList  ""
    public variable m_PimGroupBlockList 
    
    #Relevant variable definition of PIM Rp Map list 
    public variable m_PimRpMapNameList ""
    public variable m_PimRpMapBlockList 
    public variable m_RpMapMulticastList

    #Configuration infomation definition of Pim Router
    public variable m_testIp "192.85.0.12"
    public variable m_PimMode "SM"
    public variable m_PimRole "RemoteRP"
    public variable m_BiDirOptionSet  "FALSE"
    public variable m_EnableBsr "FALSE"
    public variable m_BsrPriority 1
    public variable m_BootStrapMessageInterval 60
    public variable m_DrPriority 1
    public variable m_GenIdMode "FIXED"
    public variable m_HelloInterval 30
    public variable m_HelloHoldTime 105
    public variable m_JoinPruneInterval 60
    public variable m_JoinPruneRate 100
    public variable m_JoinPruneHoldTime 210
    public variable m_IpVersion "V4"
    public variable m_UpStreamNeighbor ""
    public variable m_Active "TRUE"
    
    public variable m_prefixLen 24
    public variable m_routerId  "192.0.0.1"

    public variable m_RemoterpRpAddr "192.85.1.1"
    public variable m_CrpRpAddr "192.85.1.1"
    public variable m_CrpBsrAddr "192.85.1.1"
    public variable m_CrpRpPriority 192
    public variable  m_CrpGroups  "224.0.0.1/0"

    #Relevant parameter definition of Pim Group
    public variable m_PimGroupGroupTypeList
    public variable m_PimGroupVersionList
    public variable m_PimGroupRpIpAddrList
    public variable m_PimGroupEnablingPruningList
    public variable m_PimGroupPruneStartIpAddressList
    public variable m_PimGroupPrunePrefixLengthList
    public variable m_PimGroupMulticastBlockList
    public variable m_PimGroupStartAddressList
    public variable m_PimGroupModifierList
    public variable m_PimGroupGroupCntList
    public variable m_PimGroupActiveList
  
    #Relevant parameter definition of Rp Map
    public variable m_RpMapRpIpAddrList
    public variable m_RpMapVersionList
    public variable m_RpMapRpHoldTimeList
    public variable m_RpMapGroupNameList
    public variable m_RpMapRpPriorityList
    public variable m_RpMapActiveList

    public variable m_ResultDataSet

    #Constructor
    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
     { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
        set m_routerName $routerName
        set m_routerId $routerId       
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_portType $portType

        if {$m_portType == "ethernet"} {
            set L2If1 [stc::get $hRouter -children-EthIIIf]
            set m_hMacAddress $L2If1    
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set L2If1 [stc::get $hRouter -children-HdlcIf]
            } else {
                set L2If1 [stc::get $hRouter -children-PppIf]
            }
        } 
        set m_hEthIIIf $L2If1

        #Get IPv4if object under the router object
        set m_hIpv4If [stc::get $hRouter -children-Ipv4If]   
        
        #Get IPv6if object under the router object
        set hIpv6IfList [stc::get $hRouter -children-Ipv6If]
        set m_hIpv6If1 [lindex $hIpv6IfList 0] 
        set m_hIpv6If2 [lindex $hIpv6IfList 1]  

        #Create PimRouterConfig, carry out default configuration  
        set m_hPimRouterConfig [stc::create "PimRouterConfig" \
                      -under $m_hRouter \
                      -PimMode $m_PimMode \
                      -BiDirOptionSet $m_BiDirOptionSet \
                      -EnableBsr $m_EnableBsr \
                      -BsrPriority $m_BsrPriority \
                      -Active $m_Active\
                      -BootStrapMessageInterval $m_BootStrapMessageInterval \
                      -DrPriority $m_DrPriority \
                      -GenIdMode $m_GenIdMode \
                      -HelloInterval $m_HelloInterval \
                      -HelloHoldTime $m_HelloHoldTime \
                      -JoinPruneInterval $m_JoinPruneInterval \
                      -JoinPruneHoldTime $m_JoinPruneHoldTime \
                      -IpVersion $m_IpVersion \
                      -Name "PimRouterConfig$m_routerName" ]
                                                                                               
        stc::config $m_hPimRouterConfig -UsesIf-targets $m_hIpv4If

    }

    #Destructor
    destructor {
    }

    #Method declaration
    public method PimSetSession
    public method PimRetrieveRouter
     
    public method PimCreateGroupPool
    public method PimSetGroupPool
    public method PimRemoveGroupPool
  
    #Not included in requirements, mainly used for debugging
    public method PimRetrievePimGroup

    public method PimCreateRpMap
    public method PimSetRpMap
    public method PimRemoveRpMap
 
    public method PimEnable
    public method PimDisable

    public method PimSendJoin    
    public method PimSendPrune
    public method PimSendRegister

    public method PimRetrieveRouterStats
}

############################################################################
#APIName: PimSetSession
#Description: According to input parameter, configure PIM Router
#Input:  For details see API use documentation or HELP documentaton
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSetSession {args} {
     set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimSetSession"

    #Get the value of TesterIp
    set index [lsearch $args -testerip] 
    if {$index != -1} {
        set TestIp [lindex $args [expr $index + 1]]
        set m_testIp $TestIp

        if {[isValidIPv4 $TestIp] == 1 } {
            set m_IpVersion "V4" 
            if {$m_isInitialized == "FALSE"} {
                set m_prefixLen 24  
                set m_UpStreamNeighbor "192.85.1.1"
                set  m_isInitialized "TRUE"
            } 
        } elseif {[isValidIPv6 $TestIp] == 1 } { 
            set m_IpVersion "V6" 
            if {$m_isInitialized == "FALSE"} {
                set m_prefixLen 64  
                set m_UpStreamNeighbor "fe80::1"
                set  m_isInitialized "TRUE"

                set m_RemoterpRpAddr "2001::1"
                set m_CrpRpAddr "2001::1"
                set m_CrpBsrAddr "2001::1"
            }
        } else {
            error "Invalid TesterIp.  \nexit the proc of PimSession::PimSetSession" 
        }
    } else {
         set  TestIp $m_testIp
    } 

    #Get the value of PimMode
    set index [lsearch $args -pimmode] 
    if {$index != -1} {
        set PimMode [lindex $args [expr $index + 1]]
        set m_PimMode $PimMode
    } 
     
    #Get the value of BiDirOptionSet
    set index [lsearch $args -bidiroptionset] 
    if {$index != -1} {
        set BiDirOptionSet [lindex $args [expr $index + 1]]
        set m_BiDirOptionSet $BiDirOptionSet
    } 
   
   #Get the value of PimRole
    set index [lsearch $args -pimrole] 
    if {$index != -1} {
        set PimRole [lindex $args [expr $index + 1]]
        set m_PimRole $PimRole
        if {[string tolower $m_PimRole] == "cbsr"} {
              set m_EnableBsr "TRUE"
        } else {
               set m_EnableBsr "FALSE"
        }
    } 
    
   #Get the value of DrPriority
    set index [lsearch $args -drpriority] 
    if {$index != -1} {
        set DrPriority [lindex $args [expr $index + 1]]
        set m_DrPriority $DrPriority
    } 

    #Get the value of GenIdMode
    set index [lsearch $args -genidmode] 
    if {$index != -1} {
        set GenIdMode [lindex $args [expr $index + 1]]
        set m_GenIdMode $GenIdMode
    } 
 
    #Get the value of HelloInterval
    set index [lsearch $args -hellointerval] 
    if {$index != -1} {
        set HelloInterval  [lindex $args [expr $index + 1]]
        set m_HelloInterval  $HelloInterval 
    } 

    #Get the value of HelloHoldTime
    set index [lsearch $args -helloholdtime] 
    if {$index != -1} {
        set HelloHoldTime [lindex $args [expr $index + 1]]
        set m_HelloHoldTime $HelloHoldTime
    } 

    #Get the value of JoinPruneInterval
    set index [lsearch $args -joinpruneinterval] 
    if {$index != -1} {
        set JoinPruneInterval [lindex $args [expr $index + 1]]
        set m_JoinPruneInterval $JoinPruneInterval
    } 

    #Get the value of JoinPruneRate
    set index [lsearch $args -joinprunerate] 
    if {$index != -1} {
        set JoinPruneRate [lindex $args [expr $index + 1]]
        set m_JoinPruneRate $JoinPruneRate
    } 

    #Get the value of JoinPruneHoldTime
    set index [lsearch $args -joinpruneholdtime] 
    if {$index != -1} {
        set JoinPruneHoldTime [lindex $args [expr $index + 1]]
        set m_JoinPruneHoldTime $JoinPruneHoldTime
    } 

   #Get the value of UpStreamNeighbor
    set index [lsearch $args -upstreamneighbor] 
    if {$index != -1} {
        set UpStreamNeighbor [lindex $args [expr $index + 1]]
        set m_UpStreamNeighbor $UpStreamNeighbor
    } 

    #Get the value of PrefixLength
    set index [lsearch $args -prefixlength] 
    if {$index != -1} {
        set PrefixLength [lindex $args [expr $index + 1]]
        set m_prefixLen $PrefixLength
    }

    #Get the value of RemoterpRpAddr
    set index [lsearch $args -remoterprpaddr] 
    if {$index != -1} {
        set RemoterpRpAddr [lindex $args [expr $index + 1]]
        set m_RemoterpRpAddr $RemoterpRpAddr
    } 

    #Get the value of CrpRpAddr
    set index [lsearch $args -crprpaddr] 
    if {$index != -1} {
        set CrpRpAddr [lindex $args [expr $index + 1]]
        set m_CrpRpAddr $CrpRpAddr
    } 

    #Get the value of CrpBsrAddr
    set index [lsearch $args -crpbsraddr] 
    if {$index != -1} {
        set CrpBsrAddr [lindex $args [expr $index + 1]]
        set m_CrpBsrAddr $CrpBsrAddr
    } 

    #Get the value of CrpRpPriority
    set index [lsearch $args -crprppriority] 
    if {$index != -1} {
        set CrpRpPriority [lindex $args [expr $index + 1]]
        set m_CrpRpPriority $CrpRpPriority
    } 

    #Get the value of CrpGroups
    set index [lsearch $args -crpgroups] 
    if {$index != -1} {
        set CrpGroups [lindex $args [expr $index + 1]]
        set m_CrpGroups $CrpGroups
    } 

   #Get the value of BsrPriority
    set index [lsearch $args -bsrpriority] 
    if {$index != -1} {
        set BsrPriority [lindex $args [expr $index + 1]]
        set m_BsrPriority $BsrPriority
    } 
    
    #Get the value of BSMInterval
    set index [lsearch $args -bsminterval] 
    if {$index != -1} {
        set BootStrapMessageInterval [lindex $args [expr $index + 1]]
        set m_BootStrapMessageInterval $BootStrapMessageInterval
    } 

    #Get the value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_Active $Active
    } 

    stc::config $m_hRouter -RouterId $m_routerId -Active $m_Active

    set PimRouterConfig [stc::get $m_hRouter -children-PimRouterConfig]
 
    if {$m_IpVersion == "V4"} {
        stc::config $PimRouterConfig -PimMode $m_PimMode \
                                  -BiDirOptionSet $m_BiDirOptionSet \
                                  -EnableBsr $m_EnableBsr \
                                  -BsrPriority $m_BsrPriority \
                                  -BootStrapMessageInterval $m_BootStrapMessageInterval \
                                  -DrPriority $m_DrPriority \
                                  -GenIdMode $m_GenIdMode \
                                  -HelloInterval $m_HelloInterval \
                                  -HelloHoldTime $m_HelloHoldTime \
                                  -JoinPruneInterval $m_JoinPruneInterval \
                                  -JoinPruneHoldTime $m_JoinPruneHoldTime \
                                  -IpVersion "V4" \
                                  -Active $m_Active \
                                  -UpStreamNeighborV4 $m_UpStreamNeighbor \
                                  -name "PimRouterConfig$m_routerName"

         #According to testIp, set IP address of Gateway
         set Gateway [ GetGatewayIp $m_testIp] 

         set m_hIpAddress $m_hIpv4If 
         #Find corresponding Mac address and set the address according to testIp from Host
         SetMacAddress $m_testIp

         stc::config $m_hIpv4If -Address $m_testIp -Gateway $Gateway -PrefixLength $m_prefixLen

         #Make objects associated
         stc::config $m_hRouter -AffiliationPort-targets $m_hPort
         stc::config $m_hRouter -RouterId $m_routerId -TopLevelIf-targets $m_hIpv4If 
         stc::config $m_hRouter -RouterId $m_routerId -PrimaryIf-targets  $m_hIpv4If 
         stc::config $m_hPimRouterConfig -UsesIf-targets $m_hIpv4If 

         if {$m_hIpv6If1 != ""} {
            stc::delete $m_hIpv6If1
            set m_hIpv6If1 ""
        }

        if {$m_hIpv6If2 != ""} {
            stc::delete $m_hIpv6If2
            set m_hIpv6If2 ""
        }
    } else {
         stc::config $PimRouterConfig -PimMode $m_PimMode \
                                  -BiDirOptionSet $m_BiDirOptionSet \
                                  -EnableBsr $m_EnableBsr \
                                  -BsrPriority $m_BsrPriority \
                                  -Active $m_Active \
                                  -BootStrapMessageInterval $m_BootStrapMessageInterval \
                                  -DrPriority $m_DrPriority \
                                  -GenIdMode $m_GenIdMode \
                                  -HelloInterval $m_HelloInterval \
                                  -HelloHoldTime $m_HelloHoldTime \
                                  -JoinPruneInterval $m_JoinPruneInterval \
                                  -JoinPruneHoldTime $m_JoinPruneHoldTime \
                                  -IpVersion "V6" \
                                  -Active $m_Active \
                                  -UpStreamNeighborV6 $m_UpStreamNeighbor \
                                  -name "PimRouterConfig$m_routerName"
      
        set Gateway [GetGatewayIpv6 $m_testIp]

        stc::config $m_hIpv6If1  -Gateway $Gateway  -PrefixLength $m_prefixLen
        stc::config $m_hIpv6If2 -Address $m_testIp -Gateway $Gateway  -PrefixLength $m_prefixLen
                         
        set m_hIpAddress $m_hIpv6If1
        #Find corresponding Mac address and set the address according to testip from Host
        SetMacAddress $m_testIp "Ipv6"

        #Make objects associated
        stc::config $m_hRouter -AffiliationPort-targets $m_hPort

        stc::config $m_hRouter  -TopLevelIf-targets "$m_hIpv6If1 $m_hIpv6If2"
        stc::config $m_hRouter -PrimaryIf-targets  "$m_hIpv6If1 $m_hIpv6If2"
    
        stc::config $PimRouterConfig -UsesIf-targets $m_hIpv6If1
    }
  
     #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of PimSession::PimSetSession"

    return $::mainDefine::gSuccess
  
}

############################################################################
#APIName: PimRetrieveRouter
#Description: According to input parameter, Retrieve parameters of route
#Input: For details see API use documentation or HELP documentation
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimRetrieveRouter {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimRetrieveRouter"

    set PimRouterStatus "" 
    
    lappend PimRouterStatus "-testerip"                                 
    lappend PimRouterStatus $m_testIp 
              
    lappend PimRouterStatus "-pimmode"                                 
    lappend PimRouterStatus  $m_PimMode 
        
    lappend PimRouterStatus "-bidiroptionset"                                 
    lappend PimRouterStatus  [stc::get $m_hPimRouterConfig -BiDirOptionSet]
    
    lappend PimRouterStatus "-pimrole"                                 
    lappend PimRouterStatus $m_PimRole 

    lappend PimRouterStatus "-drpriority"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -DrPriority]

    lappend PimRouterStatus "-genidmode"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -GenIdMode]
    
    lappend PimRouterStatus "-hellointerval"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -HelloInterval]

    lappend PimRouterStatus "-helloholdtime"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -HelloHoldTime]

    lappend PimRouterStatus "-joinpruneinterval"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -JoinPruneInterval]
        
    lappend PimRouterStatus "-joinpruneholdtime"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -JoinPruneHoldTime]

    lappend PimRouterStatus "-joinprunerate"                                 
    lappend PimRouterStatus $m_JoinPruneRate 

    lappend PimRouterStatus "-remoterprpaddr"                                 
    lappend PimRouterStatus $m_RemoterpRpAddr
    
    lappend PimRouterStatus "-crprpaddr"                                 
    lappend PimRouterStatus $m_CrpRpAddr

    lappend PimRouterStatus "-crpbsraddr"                                 
    lappend PimRouterStatus $m_CrpBsrAddr
    
    lappend PimRouterStatus "-crprppriority"                                 
    lappend PimRouterStatus $m_CrpRpPriority

    lappend PimRouterStatus "-crpgroups"                                 
    lappend PimRouterStatus $m_CrpGroups

    lappend PimRouterStatus "-bsrpriority"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -BsrPriority]
    
    lappend PimRouterStatus "-bsminterval"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -BootStrapMessageInterval]

    lappend PimRouterStatus "-upstreamneighbor"                                 
 
    if {$m_IpVersion == "V4"} {
        lappend PimRouterStatus [stc::get $m_hPimRouterConfig -UpStreamNeighborV4]                                 
    } else {
        lappend PimRouterStatus [stc::get $m_hPimRouterConfig -UpStreamNeighborV6]
    } 
   
    lappend PimRouterStatus "-active"         

    if {[string tolower $m_Active] == "true"} {
        lappend PimRouterStatus "Enable"
    } else {
        lappend PimRouterStatus "Disable"
    }

    lappend PimRouterStatus "-state"                                 
    lappend PimRouterStatus [stc::get $m_hPimRouterConfig -RouterState]

    if {$args == "" }  {
         debugPut "exit the proc of PimSession::PimRetrieveRouter"
         return $PimRouterStatus
    } else {
         array set arr $PimRouterStatus
         set args [ConvertAttrToLowerCase $args]

         foreach {name valueVar}  $args  {      

             set ::mainDefine::gAttrValue $arr($name)

             set ::mainDefine::gVar $valueVar
             uplevel 1 {
                 set $::mainDefine::gVar $::mainDefine::gAttrValue
             }           
        } 

        debugPut "exit the proc of PimSession::PimRetrieveRouter"

        return $::mainDefine::gSuccess
   }
}

############################################################################
#APIName: PimCreateGroupPool
#Description: Add Pimv Group to PimSession
#Input: For details see API use documentation or HELP documentation
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimCreateGroupPool {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimCreateGroupPool"
   
    #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupName"
    }
       
    #Get the value of GroupType
    set index [lsearch $args -grouptype] 
    if {$index != -1} {
        set GroupType [lindex $args [expr $index + 1]]
    } else  {
        set GroupType "STARG"
    }
    set m_PimGroupGroupTypeList($GroupName) $GroupType

    #Get the value of Version
    set index [lsearch $args -version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
    } else  {
        set Version $m_IpVersion
    }
    set m_PimGroupVersionList($GroupName) $Version

    #Get the value of RpIp
    set index [lsearch $args -rpip] 
    if {$index != -1} {
        set RpIpAddr [lindex $args [expr $index + 1]]
    } else  {
        if {$m_IpVersion == "V4"} { 
           set RpIpAddr "192.0.0.1"
        } else {
           set RpIpAddr "2000::1"
        }
    }
    set m_PimGroupRpIpAddrList($GroupName) $RpIpAddr

   #Get the value of GroupIpStart
    set index [lsearch $args -groupipstart] 
    if {$index != -1} {
        set GroupStartAddress [lindex $args [expr $index + 1]]
    } else  {
        if {$m_IpVersion == "V4"} {
           set GroupStartAddress 225.0.0.1
        } else {
           set GroupStartAddress ff1e::1
        }
    }
    set m_PimGroupStartAddressList($GroupName) $GroupStartAddress
 
    #Get the value of GroupCnt
    set index [lsearch $args -groupcnt]
    if {$index != -1} {
       set GroupCnt [lindex $args [expr $index + 1]]
    } else {
       set GroupCnt 1
    }
    set m_PimGroupGroupCntList($GroupName) $GroupCnt 

    #Get the value of GroupIpStep
    set index [lsearch $args -groupipstep]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
       if {[isValidIPv4 $Modifier] == 1 } {
           set Modifier [ipaddr2dec $Modifier]
       }
    } else {
       set Modifier 1
    }
    set m_PimGroupModifierList($GroupName) $Modifier

    #Get the value of EnablingPruning
    set index [lsearch $args -enablingpruning] 
    if {$index != -1} {
        set EnablingPruning [lindex $args [expr $index + 1]]
    } else  {
        set EnablingPruning FALSE
    }
    set m_PimGroupEnablingPruningList($GroupName) $EnablingPruning


   #Get the value of SrcIpAddr
    set index [lsearch $args -srcipaddr] 
    if {$index != -1} {
        set PruneStartIpAddress [lindex $args [expr $index + 1]]
    } else  {
        if {$m_IpVersion == "V4"} { 
           set PruneStartIpAddress "192.0.1.1"
        } else {
           set PruneStartIpAddress "2000::1"
        }
    }
    set m_PimGroupPruneStartIpAddressList($GroupName) $PruneStartIpAddress

    #Get the value of SrcIpAddrPrefix
    set index [lsearch $args -srcipAddrprefix] 
    if {$index != -1} {
        set PrunePrefixLength [lindex $args [expr $index + 1]]
    } else  {
        if {$m_IpVersion == "V4"} { 
           set PrunePrefixLength 24
        } else {
           set PrunePrefixLength 64
        }
    }
   set m_PimGroupPrunePrefixLengthList($GroupName) $PrunePrefixLength

    #Get the value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else {
        set Active TRUE 
    } 
    set m_PimGroupActiveList($GroupName) $Active

    if {$Version == "V4"} {
       set Pimv4GroupBlk [stc::create "Pimv4GroupBlk"  -under $m_hPimRouterConfig  \
           -RpIpAddr $RpIpAddr \
           -GroupType $GroupType \
           -EnablingPruning $EnablingPruning \
           -Active $Active \
           -Name "Pimv4GroupBlk$GroupName" ]

       set Pimv4PruneSrc [lindex [stc::get $Pimv4GroupBlk -children-Pimv4PruneSrc] 0]
       stc::config $Pimv4PruneSrc \
           -StartIpList $PruneStartIpAddress \
           -PrefixLength $PrunePrefixLength \
           -NetworkCount 1 \
           -AddrIncrement 1 \
           -Active $Active \
           -Name "Pimv4PruneSrc$m_routerName"

       set Pimv4JoinSrc [lindex [stc::get $Pimv4GroupBlk -children-Pimv4JoinSrc] 0]
       stc::config $Pimv4JoinSrc \
           -StartIpList $PruneStartIpAddress \
           -PrefixLength $PrunePrefixLength \
           -NetworkCount 1 \
           -AddrIncrement 1 \
           -Active $Active \
           -Name "Pimv4JoinSrc$GroupName"
      
       set Ipv4Group [stc::create "Ipv4Group" \
             -under $m_hProject \
             -Active "TRUE" \
             -Name "Ipv4Group$GroupName" ]

       set Ipv4NetworkBlock [lindex [stc::get $Ipv4Group -children-Ipv4NetworkBlock] 0]
      
       stc::config $Ipv4NetworkBlock \
            -StartIpList $GroupStartAddress \
            -PrefixLength 32 \
            -NetworkCount $GroupCnt \
            -AddrIncrement $Modifier \
            -Active "TRUE" \
            -Name "Ipv4Group$GroupName"

       stc::config $Pimv4GroupBlk -JoinedGroup-targets $Ipv4Group

       #Append created PIM Group to the list
       lappend m_PimGroupNameList  $GroupName
       set m_PimGroupBlockList($GroupName) $Pimv4GroupBlk
       set m_PimGroupMulticastBlockList($GroupName) $Ipv4Group
    } else {
        set Pimv6GroupBlock [stc::create "Pimv6GroupBlk"  -under $m_hPimRouterConfig \
            -RpIpAddr $RpIpAddr \
            -GroupType $GroupType \
           -EnablingPruning $EnablingPruning \
           -Active $Active \
           -Name "Pimv6GroupBlk$GroupName" ]

       set Pimv6JoinSrc [lindex [stc::get $Pimv6GroupBlock -children-Pimv6JoinSrc] 0]
       stc::config $Pimv6JoinSrc \
         -StartIpList  $PruneStartIpAddress \
           -PrefixLength $PrunePrefixLength \
           -NetworkCount 1 \
           -AddrIncrement 1 \
           -Active $Active \
           -Name "Pimv6JoinSrc$GroupName"

       set Pimv6PruneSrc [lindex [stc::get $Pimv6GroupBlock -children-Pimv6PruneSrc] 0]
       stc::config $Pimv6PruneSrc \
           -StartIpList  $PruneStartIpAddress \
           -PrefixLength $PrunePrefixLength \
           -NetworkCount 1 \
           -AddrIncrement 1 \
           -Active $Active \
           -Name "Pimv6PruneSrc$GroupName"
        
        set Ipv6Group [stc::create "Ipv6Group" \
            -under $m_hProject \
            -Active "TRUE" \
            -Name "Ipv6Group$GroupName" ]
       
        set Ipv6NetworkBlock [lindex [stc::get $Ipv6Group -children-Ipv6NetworkBlock] 0]
      
        stc::config $Ipv6NetworkBlock \
           -StartIpList $GroupStartAddress\
           -PrefixLength 128 \
           -NetworkCount $GroupCnt \
           -AddrIncrement $Modifier \
           -Active "TRUE" \
           -Name "Ipv6Group$GroupName"

        stc::config $Pimv6GroupBlock -JoinedGroup-targets $Ipv6Group

        #Append created PIM Group to the list
        lappend m_PimGroupNameList  $GroupName
        set m_PimGroupBlockList($GroupName) $Pimv6GroupBlock
        set m_PimGroupMulticastBlockList($GroupName) $Ipv6Group
    }

   #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }
    
    debugPut "exit the proc of PimSession::PimCreateGroupPool"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimRemoveGroupPool
#Description: Delete PIM Group
#Input:  
#             (1) GroupName GroupName  Mandatory parameter, name of PIM Group£¬for example -GroupName group1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimRemoveGroupPool {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimRemoveGroupPool"

    #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupName"
    }

    #Delete Pim Group object
    set index [lsearch $m_PimGroupNameList $GroupName] 
    if {$index == -1} {
        error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimRemoveGroupPool..."
    }
    
    stc::delete $m_PimGroupBlockList($GroupName)
    unset m_PimGroupBlockList($GroupName)
    set m_PimGroupNameList  [lreplace $m_PimGroupNameList  $index $index]

   #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of PimSession::PimRemoveGroupPool"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimSetGroupPool
#Description: Configure Pim Group
#Input:  For details see API use documentation or HELP documentation
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSetGroupPool {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimSetGroupPool"
    
    #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupName"
    }

    #Check whether Pim Group to be configured exists in the list
    set index [lsearch $m_PimGroupNameList $GroupName] 
    if {$index == -1} {
        error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimSetGroupPool..."
    }

    #Get the value of GroupType
    set index [lsearch $args -grouptype] 
    if {$index != -1} {
        set GroupType [lindex $args [expr $index + 1]]
        set m_PimGroupGroupTypeList($GroupName) $GroupType
    } else  {
        set GroupType $m_PimGroupGroupTypeList($GroupName) 
    }

    #Get the value of Version
    set index [lsearch $args -version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
        set m_PimGroupVersionList($GroupName) $Version
    } else  {
        set Version $m_PimGroupVersionList($GroupName) 
    }

    #Get the value of RpIp
    set index [lsearch $args -rpip] 
    if {$index != -1} {
        set RpIpAddr [lindex $args [expr $index + 1]]
        set m_PimGroupRpIpAddrList($GroupName) $RpIpAddr
    } else  {
        set RpIpAddr $m_PimGroupRpIpAddrList($GroupName) 
    }

   #Get the value of GroupIpStart
    set index [lsearch $args -groupipstart] 
    if {$index != -1} {
        set GroupStartAddress [lindex $args [expr $index + 1]]
        set m_PimGroupStartAddressList($GroupName)  $GroupStartAddress
    } else  {
        set GroupStartAddress $m_PimGroupStartAddressList($GroupName)
    }
  
    #Get the value of GroupCnt
    set index [lsearch $args -groupcnt]
    if {$index != -1} {
       set GroupCnt [lindex $args [expr $index + 1]]
       set m_PimGroupGroupCntList($GroupName) $GroupCnt
    } else {
        set GroupCnt $m_PimGroupGroupCntList($GroupName)
    }

    #Get the value of GroupIpStep
    set index [lsearch $args -groupipstep]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
       if {[isValidIPv4 $Modifier] == 1 } {
           set Modifier [ipaddr2dec $Modifier]
       }
       set m_PimGroupModifierList($GroupName) $Modifier
    } else {
       set Modifier $m_PimGroupModifierList($GroupName)
    }

    #Get the value of EnablingPruning
    set index [lsearch $args -enablingpruning] 
    if {$index != -1} {
        set EnablingPruning [lindex $args [expr $index + 1]]
        set m_PimGroupEnablingPruningList($GroupName) $EnablingPruning
    } else  {
        set EnablingPruning $m_PimGroupEnablingPruningList($GroupName) 
    }

    #Get the value of SrcIpAddr
    set index [lsearch $args -srcipaddr] 
    if {$index != -1} {
        set PruneStartIpAddress [lindex $args [expr $index + 1]]
        set m_PimGroupPruneStartIpAddressList($GroupName) $PruneStartIpAddress
    } else  {
        set PruneStartIpAddress $m_PimGroupPruneStartIpAddressList($GroupName) 
    }

    #Get the value of SrcIpAddrPrefix
    set index [lsearch $args -srcipAddrprefix] 
    if {$index != -1} {
        set PrunePrefixLength [lindex $args [expr $index + 1]]
        set m_PimGroupPrunePrefixLengthList($GroupName) $PrunePrefixLength
    } else  {
        set PrunePrefixLength $m_PimGroupPrunePrefixLengthList($GroupName) 
    }

    #Get the value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_PimGroupActiveList($GroupName) $Active
    } else {
        set Active $m_PimGroupActiveList($GroupName) 
    } 

    if {$Version == "V4"} { 
        set Pimv4GroupBlk $m_PimGroupBlockList($GroupName) 
   
        stc::config $Pimv4GroupBlk  -RpIpAddr $RpIpAddr \
             -GroupType $GroupType \
             -EnablingPruning $EnablingPruning \
             -Active $Active
        
        set Pimv4JoinSrc [lindex [stc::get $Pimv4GroupBlk -children-Pimv4JoinSrc] 0]
        stc::config $Pimv4JoinSrc \
               -StartIpList $PruneStartIpAddress \
               -PrefixLength $PrunePrefixLength \
               -NetworkCount 1 \
               -AddrIncrement 1 \
               -Active $Active

         set Pimv4PruneSrc [lindex [stc::get $Pimv4GroupBlk -children-Pimv4PruneSrc] 0]
         stc::config $Pimv4PruneSrc \
               -StartIpList $PruneStartIpAddress \
               -PrefixLength $PrunePrefixLength \
               -NetworkCount 1 \
               -AddrIncrement 1 \
               -Active $Active
          
         set MulticastGroupBlk $m_PimGroupMulticastBlockList($GroupName)
         set Ipv4NetworkBlock [lindex [stc::get $MulticastGroupBlk -children-Ipv4NetworkBlock] 0]
      
         stc::config $Ipv4NetworkBlock \
            -StartIpList $GroupStartAddress \
            -PrefixLength 32 \
            -NetworkCount $GroupCnt \
            -AddrIncrement $Modifier 

         stc::config $Pimv4GroupBlk -JoinedGroup-targets $MulticastGroupBlk

   } else {
        set Pimv6GroupBlk $m_PimGroupBlockList($GroupName) 
   
        stc::config $Pimv6GroupBlk -RpIpAddr $RpIpAddr \
              -GroupType $GroupType \
              -EnablingPruning $EnablingPruning \
              -Active $Active
        
        set Pimv6JoinSrc [lindex [stc::get $Pimv6GroupBlk -children-Pimv6JoinSrc] 0]
        stc::config $Pimv6JoinSrc \
              -StartIpList $PruneStartIpAddress \
              -PrefixLength $PrunePrefixLength \
              -NetworkCount 1 \
              -AddrIncrement 1 \
              -Active $Active

        set Pimv6PruneSrc [lindex [stc::get $Pimv6GroupBlk -children-Pimv6PruneSrc] 0]
        stc::config $Pimv6PruneSrc \
             -StartIpList $PruneStartIpAddress \
             -PrefixLength $PrunePrefixLength \
             -NetworkCount 1 \
             -AddrIncrement 1 \
             -Active $Active

        set MulticastGroupBlk $m_PimGroupMulticastBlockList($GroupName)
        set Ipv6NetworkBlock [lindex [stc::get $MulticastGroupBlk -children-Ipv6NetworkBlock] 0]
      
        stc::config $Ipv6NetworkBlock \
           -StartIpList $GroupStartAddress\
           -PrefixLength 128 \
           -NetworkCount $GroupCnt \
           -AddrIncrement $Modifier 

        stc::config $Pimv6GroupBlk -JoinedGroup-targets $MulticastGroupBlk
 }

   #Download configuraton
   set errorCode 1
   if {[catch {
       set errorCode [stc::apply]
   } err]} {
       return $errorCode
   }

 debugPut "exit the proc of PimSession::PimSetGroupPool"
 
 return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimRetrievePimGroup
#Description: Get parameters of PIM Group, not included in requirements, mainly used for debugging
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimRetrievePimGroup {args} {
   
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of PimSession::PimRetrievePimGroup"

    #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupName"
    }

    #Check whether Pim Group to be configured exists in the list
    set index [lsearch $m_PimGroupNameList $GroupName] 
    if {$index == -1} {
        error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimRetrievePimGroup..."
    }
    
    set PimRouterGroupConfig ""
    
    set PimGroupBlk $m_PimGroupBlockList($GroupName) 
    
    #Get the configuration results of Pimv Group
    lappend PimRouterGroupConfig "-groupname"                                 
    lappend PimRouterGroupConfig $GroupName

    lappend PimRouterGroupConfig "-grouptype"                                 
    lappend PimRouterGroupConfig [stc::get $PimGroupBlk -GroupType]

    lappend PimRouterGroupConfig "-rpip"                                 
    lappend PimRouterGroupConfig [stc::get $PimGroupBlk -RpIpAddr]

    lappend PimRouterGroupConfig "-enablingpruning"                                
    lappend PimRouterGroupConfig [stc::get $PimGroupBlk -EnablingPruning]

    lappend PimRouterGroupConfig "-active"                                
    lappend PimRouterGroupConfig [stc::get $PimGroupBlk -Active]

    lappend PimRouterGroupConfig "-version"                                
    lappend PimRouterGroupConfig $m_PimGroupVersionList($GroupName) 

    lappend PimRouterGroupConfig "-groupipstart"                                
    lappend PimRouterGroupConfig $m_PimGroupStartAddressList($GroupName)

    lappend PimRouterGroupConfig "-groupcnt"                                
    lappend PimRouterGroupConfig $m_PimGroupGroupCntList($GroupName)

    lappend PimRouterGroupConfig "-groupipstep"                                
    lappend PimRouterGroupConfig $m_PimGroupModifierList($GroupName)

    if {$m_IpVersion == "V4"} {
       set PimPruneSrc [lindex [stc::get $PimGroupBlk -children-Pimv4PruneSrc] 0]
    } else {
       set PimPruneSrc [lindex [stc::get $PimGroupBlk -children-Pimv6PruneSrc] 0]
    }
    
    lappend PimRouterGroupConfig "-srcipaddr"                                 
    lappend PimRouterGroupConfig [stc::get $PimPruneSrc -StartIpList]

    lappend PimRouterGroupConfig "-prunesourceprefix"                                 
    lappend PimRouterGroupConfig [stc::get $PimPruneSrc -PrefixLength]

    set args [lrange $args 2 end] 
   
    if {$args == ""} {
        debugPut "exit the proc of PimSession::PimRetrievePimGroup"
        return $PimRouterGroupConfig
    } else  {
        #According to input parameter, set corresponding value
        array set arr $PimRouterGroupConfig
        foreach {name valueVar}  $args {      

             set ::mainDefine::gAttrValue $arr($name)

             set ::mainDefine::gVar $valueVar
             uplevel 1 {
                 set $::mainDefine::gVar $::mainDefine::gAttrValue
             }           
        } 

        debugPut "exit the proc of PimSession::PimRetrievePimGroup"

        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: PimCreateRpMap
#Description: Add Pim RP Map to PimSession
#Input: For details see API use documentation or HELP documentation
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimCreateRpMap {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimCreateRpMap"

    #Get the value of RpMapName
    set index [lsearch $args -rpmapname] 
    if {$index != -1} {
        set RpMapName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the RpMapName.\nexit the proc of PimSession::PimCreateRpMap"
    }
     
    #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the PIM GroupName.\n exit the proc of PimSession::PimCreateRpMap"
    }

    #Check whether Pim Group to be configured exists in the list
    set index [lsearch $m_PimGroupNameList $GroupName] 
    if {$index == -1} {
        error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimSession::PimCreateRpMap..."
    }

    set m_RpMapMulticastList($RpMapName) $GroupName
       
    #Get the value of RpHoldTime
    set index [lsearch $args -rpholdtime] 
    if {$index != -1} {
        set RpHoldTime [lindex $args [expr $index + 1]]
    } else  {
        set RpHoldTime 150
    }

    set m_RpMapRpHoldTimeList($RpMapName) $RpHoldTime

    #Get the value of RpIp
    set index [lsearch $args -rpip] 
    if {$index != -1} {
        set RpIpAddr [lindex $args [expr $index + 1]]
    } else  {
        if {$m_IpVersion == "V4"} { 
           set RpIpAddr "192.0.0.1"
        } else {
           set RpIpAddr "2000::1"
        }
    }

    set m_RpMapRpIpAddrList($RpMapName) $RpIpAddr

    #Get the value of RpPriority
    set index [lsearch $args -rppriority] 
    if {$index != -1} {
        set RpPriority [lindex $args [expr $index + 1]]
    } else  {
        set RpPriority 0
    }

    set m_RpMapRpPriorityList($RpMapName) $RpPriority

    #Get the value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else {
        set Active TRUE 
    } 

    set m_RpMapActiveList($RpMapName) $Active 

    if {$m_IpVersion == "V4"} {
        #Configure Rp Map
        set PimRpMapBlk [stc::create "Pimv4RpMap" \
             -under $m_hPimRouterConfig  \
             -RpIpAddr $RpIpAddr \
             -RpHoldTime $RpHoldTime \
             -RpPriority $RpPriority \
             -Active $Active\
             -Name "Pimv4RpMap$RpMapName" ]
           
         set MulticastGroupBlk $m_PimGroupMulticastBlockList($GroupName)
         stc::config $PimRpMapBlk -JoinedGroup-targets $MulticastGroupBlk
     } else {
         #Configure Rp Map
         set PimRpMapBlk [stc::create "Pimv6RpMap" \
             -under $m_hPimRouterConfig  \
             -RpIpAddr $RpIpAddr \
             -RpHoldTime $RpHoldTime \
             -RpPriority $RpPriority \
             -Active $Active\
             -Name "Pimv6RpMap$m_routerName" ]
           
         set MulticastGroupBlk $m_PimGroupMulticastBlockList($GroupName)
         stc::config $PimRpMapBlk -JoinedGroup-targets $MulticastGroupBlk
    }

    #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }
    
    #Append created Rp Map to the Rp Map list
    lappend m_PimRpMapNameList $RpMapName
    set m_PimRpMapBlockList($RpMapName) $PimRpMapBlk
    
    debugPut "exit the proc of PimSession::PimCreateRpMap"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimRemoveRpMap
#Description: Delete PIM Rp Map
#Input:  
#     (1) RpMapName RpMapName Mandatory parameter£¬name of PIM RpMap£¬for example -RpMapName group1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimRemoveRpMap {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of PimSession::PimRemoveRpMap"

    #Get the value of RpMapName
    set index [lsearch $args -rpmapname] 
    if {$index != -1} {
        set RpMapName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the RpMapName"
    }

    #Delete Pim Rp Map object
    set index [lsearch $m_PimRpMapNameList $RpMapName] 
    if {$index == -1} {
        error "Can not find the RpMapName you have set,please set another one.\nexit the proc of PimSession::PimRemoveRpMap..."
    }
    
    stc::delete $m_PimRpMapBlockList($RpMapName)
    unset m_PimRpMapBlockList($RpMapName)
    set m_PimRapMapNameList  [lreplace $m_PimRpMapNameList  $index $index]

    stc::apply

    debugPut "exit the proc of PimSession::PimRemoveRpMap"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimSetRpMap
#Description: Configure Pim Group
#Input:  For details see API use documentation or HELP documentation
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSetRpMap {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimSetRpMap"

    #Get the value of RpMapName
    set index [lsearch $args -rpmapname] 
    if {$index != -1} {
        set RpMapName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the RpMapName"
    }
    
    #Check whether Pim Group to be configured exists in the list
    set index [lsearch $m_PimRpMapNameList $RpMapName] 
    if {$index == -1} {
        error "Can not find the RpMapName you have set,please set another one.\nexit the proc of PimSession::PimSetRpMap..."
    }
    
   #Get the value of GroupName
    set index [lsearch $args -groupname] 
    if {$index != -1} {
        set GroupName [lindex $args [expr $index + 1]]
        set m_RpMapMulticastList($RpMapName) $GroupName
    } else  {
        set GroupName $m_RpMapMulticastList($RpMapName) 
    }

    #Check whether Pim Group to be configured exists in the list
    set index [lsearch $m_PimGroupNameList $GroupName] 
    if {$index == -1} {
        error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimSession::PimSetRpMap..."
    }
       
    #Get the value of RpHoldTime
    set index [lsearch $args -rpholdtime] 
    if {$index != -1} {
        set RpHoldTime [lindex $args [expr $index + 1]]
        set m_RpMapRpHoldTimeList($RpMapName) $RpHoldTime
    } else  {
        set RpHoldTime $m_RpMapRpHoldTimeList($RpMapName) 
    }

    #Get the value of RpIp
    set index [lsearch $args -rpip] 
    if {$index != -1} {
        set RpIpAddr [lindex $args [expr $index + 1]]
        set m_RpMapRpIpAddrList($RpMapName) $RpIpAddr
    } else  {
        set RpIpAddr $m_RpMapRpIpAddrList($RpMapName) 
    }

    #Get the value of RpPriority
    set index [lsearch $args -rppriority] 
    if {$index != -1} {
        set RpPriority [lindex $args [expr $index + 1]]
        set m_RpMapRpPriorityList($RpMapName) $RpPriority
    } else  {
        set RpPriority $m_RpMapRpPriorityList($RpMapName) 
    }

    #Get the value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_RpMapActiveList($RpMapName) $Active
    } else {
        set Active $m_RpMapActiveList($RpMapName) 
    } 
     
    set PimRpMapBlk $m_PimRpMapBlockList($RpMapName) 
   
    stc::config $PimRpMapBlk -RpIpAddr $RpIpAddr \
          -RpHoldTime $RpHoldTime \
          -RpPriority $RpPriority \
          -Active $Active

   set MulticastGroupBlk $m_PimGroupMulticastBlockList($GroupName)
   stc::config $PimRpMapBlk -JoinedGroup-targets $MulticastGroupBlk

   debugPut "exit the proc of PimSession::PimSetRpMap"
 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimEnable
#Description: Start a PIM Router on a port
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimEnable {args} {
    
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimEnable"

    stc::config  $m_hRouter -Active true  
    stc::config $m_hPimRouterConfig -Active true
    stc::apply
    after 1000

    debugPut "exit the proc of PimSession::PimEnable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimDisable
#Description: Stop a PIM Router on a port
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimDisable {args} {
      
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimDisable"

    stc::config  $m_hRouter -active false 
    stc::config $m_hPimRouterConfig -Active false
    stc::apply
    after 1000

    debugPut "exit the proc of PimSession::PimDisable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimSendJoin
#Description: Make current PIM Router send Join
#Input: GroupName GroupName  Optional parameter£¬identification of PIM Group£¬for example -GroupName group1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSendJoin {args} {
    
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimSendJoin"
 
    set RouteParamList ""

    if {$args == ""} {
        for {set i 0} {$i < [llength $m_PimGroupNameList]} {incr i} {
            set GroupName [lindex $m_PimGroupNameList $i]
            set Pimv4GroupBlk $m_PimGroupBlockList($GroupName) 
            lappend RouteParamList $Pimv4GroupBlk
         }
     } else {

         #Get the value of GroupPoolList
         set index [lsearch $args -grouppoollist] 
         if {$index != -1} {
             set GroupPoolList [lindex $args [expr $index + 1]]
         } else  {
             error "Please specify the GroupPoolList.\nexit the proc of PimSession::PimSendJoin"
         }

         foreach GroupName $GroupPoolList {
              set index [lsearch $m_PimGroupNameList $GroupName] 
              if {$index == -1} {
                   error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimSession::PimSendJoin ..."
              }

              set Pimv4GroupBlk $m_PimGroupBlockList($GroupName) 
              lappend RouteParamList $Pimv4GroupBlk
         } 
    }

    if {$RouteParamList == ""} {
         puts "No creation of corresponding group"
         return $::mainDefine::gSuccess
    }
 
    stc::perform PimSendJoins -GroupList $RouteParamList 

    stc::apply
    after 1000

    debugPut "exit the proc of PimSession::PimSendJoin"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimSendPrune
#Description: Make current PIM Router send Prune
#Input: GroupName GroupName Optional parameter£¬identification of PIM Group£¬for example -GroupName group1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSendPrune {args} {
      
    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of PimSession::PimSendPrune"
 
    set RouteParamList ""

    if {$args == ""} {
        for {set i 0} {$i < [llength $m_PimGroupNameList]} {incr i} {
            set GroupName [lindex $m_PimGroupNameList $i]
            set Pimv4GroupBlk $m_PimGroupBlockList($GroupName) 
            lappend RouteParamList $Pimv4GroupBlk
         }
     } else {

         #Get the value of GroupPoolList
         set index [lsearch $args -grouppoollist] 
         if {$index != -1} {
             set GroupPoolList [lindex $args [expr $index + 1]]
         } else  {
             error "Please specify the GroupPoolList.\nexit the proc of PimSession::PimSendPrune"
         }

         foreach GroupName $GroupPoolList {
              set index [lsearch $m_PimGroupNameList $GroupName] 
              if {$index == -1} {
                   error "Can not find the GroupName you have set,please set another one.\nexit the proc of PimSession::PimSendPrune ..."
              }

              set Pimv4GroupBlk $m_PimGroupBlockList($GroupName) 
              lappend RouteParamList $Pimv4GroupBlk
         } 
    }

    if {$RouteParamList == ""} {
         puts "No creation of corresponding group"
         return $::mainDefine::gSuccess
    }
 
    stc::perform PimSendPrunes -GroupList $RouteParamList 

    stc::apply
    after 1000

    debugPut "exit the proc of PimSession::PimSendPrune"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimSendRegister
#Description: Make current PIM Router send Register
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimSendRegister {args} {
      
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of PimSession::PimSendRegister"
    
    puts "The API PimSession::PimSendRegister is not supported by STC yet ..."

    debugPut "exit the proc of PimSession::PimSendRegister"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PimRetrieveRouterStats
#Description: Get relevant statistical results of Pim
#Input:  
#     (1) numNeighbors, the number of PIM Router's neighbours
#     (2) rcvAsserts£¬ the number of received Assert messages
#     (3) rcvBootstraps£¬the number of received Bootstrap messages
#     (4) rcvCandRPAdvertisements£¬the number of received CanRPAdvertisement messages
#     (5) rcvGroupGs£¬the number of received (*,G)
#     (6) rcvGroupRPs£¬the number of received (*,*,RP)
#     (7) rcvGroupSGRPTs£¬the number of received (S,G,rpt)
#     (8) rcvGroupSGs£¬the number of received (S,G)
#     (9) rcvHellos£¬the number of received Hello messages
#     (10) rcvJoinsPrunes£¬the number of received join/prune messages
#     (11) rcvRegs£¬the number of received register messages
#     (12) rcvRegStops£¬the number of received register stop messages
#     (14) sentAsserts£¬the number of sent Assert messages
#     (15) sentBootstraps£¬the number of sent Bootstrap messages
#     (16) sendCandRPAdvertisements£¬the number of sent CanRPAdvertisement messages
#     (17) sentGroupGs£¬the number of sent (*,G)
#     (18) sentGroupRPs£¬the number of sent (*,*,RP)
#     (19) sentGroupSGRPs£¬the number of sent (S,G,rpt)
#     (20) sentGroupSGs£¬the number of sent (S,G)
#     (21) sentHellos£¬the number of sent Hello messages
#     (22) sentJoinPrunes£¬the number of sent join/prune messages
#     (23) sentRegs£¬the number of sent register messages
#     (24) sentRegStops£¬the number of sent register stop messages
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body PimSession::PimRetrieveRouterStats {args} {
    
     set args [ConvertAttrToLowerCase $args]
  
     debugPut "enter the proc of PimSession::PimRetrieveRouterStats"
    
     set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_pimRouterResultHandle]
     }
     set pimRouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $pimRouterResultHandle]
     } err]} {
         return $errorCode
     }

  
     set m_hPimRouterResult [stc::get $m_hPimRouterConfig -Children-PimRouterResults]
    #Get the result of Rip Router
    set PimRouterResult $m_hPimRouterResult 

    if {$PimRouterResult == ""} {
        error "You need to start the router before retrieving the result data"
    }

    lappend PimRouterStats "-numneighbors"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -NeighborCount]

    lappend PimRouterStats "-rcvasserts"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxAssertCount]

    lappend PimRouterStats "-rcvbootstraps"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxBootstrapCount]

    lappend PimRouterStats "-rcvcandrpadvertisements"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxCandRpAdvertCount]

    lappend PimRouterStats "-rcvgroupgs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxGroupStargCount]
    
    lappend PimRouterStats "-rcvgrouprps"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxGroupRpCount]

    lappend PimRouterStats "-rcvgroupsgrpts"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxGroupSgrptCount]

    lappend PimRouterStats "-rcvgroupsgs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxGroupSgCount]

    lappend PimRouterStats "-rcvhellos"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxHelloCount]
    
    lappend PimRouterStats "-rcvjoinsprunes"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxJoinPruneCount]

    lappend PimRouterStats "-rcvregs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxRegisterCount]

    lappend PimRouterStats "-rcvregstops"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -RxRegisterStopCount]

    lappend PimRouterStats "-sentasserts"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxAssertCount]

    lappend PimRouterStats "-sentbootstraps"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxBootstrapCount]

    lappend PimRouterStats "-sendcandrpadvertisements"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxCandRpAdvertCount]

    lappend PimRouterStats "-sentgroupgs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxGroupStargCount]
    
    lappend PimRouterStats "-sentgrouprps"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxGroupRpCount]

    lappend PimRouterStats "-sentgroupsgrps"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxGroupSgrptCount]

    lappend PimRouterStats "-sentgroupsgs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxGroupSgCount]

    lappend PimRouterStats "-senthellos"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxHelloCount]
    
    lappend PimRouterStats "-sentjoinprunes"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxJoinPruneCount]

    lappend PimRouterStats "-sentregs"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxRegisterCount]

    lappend PimRouterStats "-sentregstops"                                 
    lappend PimRouterStats [stc::get $PimRouterResult -TxRegisterStopCount]

    if {$args == ""} {
        debugPut "exit the proc of PimSession::PimRetrieveRouterStats"
        return $PimRouterStats
    } else {
        #According to input parameter, set the corresponding value
        array set arr $PimRouterStats
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }
     
       debugPut "exit the proc of PimSession::PimRetrieveRouterStats"

       return $::mainDefine::gSuccess
   }
}

