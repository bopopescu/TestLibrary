###########################################################################
#                                                                        
#  Filename£ºRsvpProtocol.tcl                                                                                              
# 
#  Description£ºDefinition of STC Ethernet port classes and relevant API                                          
# 
#  Creator£º David.Wu
#
#  Time:  2007.5.10
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

##########################################
#Define RsvpRouter class
##########################################
::itcl::class RsvpSession {
    #Inherit Router class
    inherit Router
    #Variables
    public variable m_hRsvpRouterConfig ""
    public variable m_hIpv4If ""
    public variable m_hRsvpRouterResults ""
    public variable m_hRsvpLspResults ""
    public variable m_hResultDataSet ""
    public variable m_hResultDataSet1 ""
    public variable m_testerIp ""
    public variable m_dutIp ""
    public variable m_rsvpRouterConfigFromUserInput ""
    public variable m_tunnelNameList ""
    public variable m_tunnelConfig
    public variable m_hTunnel
    public variable m_hL2If ""
    public variable m_tunnelId 0
    public variable m_tunnelActive
    public variable m_portType "ethernet"
     
    #Constructor
    constructor { routerName routerType routerId hRouter portName hProject portType} \
    { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
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
        #Configure the interface protocol stack of Router 
        set m_hL2If $L2If1    
        set m_hMacAddress $m_hL2If   
        
        #Create IPv4if object under the router object
        set m_hIpv4If [stc::get $hRouter -children-Ipv4If]   
        set m_hIpAddress $m_hIpv4If 
        
        #Create RsvpRouterConfig
        set m_hRsvpRouterConfig [stc::create  RsvpRouterConfig -under $m_hRouter]
                                  
        #added by yuanfen 2011.7.20
        set ::mainDefine::gPoolCfgBlock($m_routerName) $m_hIpv4If
        
        #Create RsvpResult        
        if {$::mainDefine::rsvpRouterCreated} {
            set m_hRsvpRouterResults $::mainDefine::m_hRsvpRouterResults
            set m_hRsvpLspResults $::mainDefine::m_hRsvpLspResults
            set m_hResultDataSet $::mainDefine::m_hResultDataSet
            set m_hResultDataSet1 $::mainDefine::m_hResultDataSet1
        } else {
            set m_hRsvpRouterResults [stc::create RsvpRouterResults -under $m_hRsvpRouterConfig]
            set m_hRsvpLspResults [stc::create RsvpLspResults -under $m_hRsvpRouterConfig]
        
            #Subscribe Rsvp Result
            set m_hResultDataSet [stc::create "ResultDataSet" -under $m_hProject ]
            set m_hResultDataSet1 [stc::create "ResultDataSet" -under $m_hProject ]
        
            set ResultQuery [stc::create "ResultQuery" \
                -under $m_hResultDataSet\
                -ResultRootList $m_hProject \
                -ConfigClassId RsvpRouterConfig \
                -ResultClassId RsvpRouterResults ]   
            set ResultQuery [stc::create "ResultQuery" \
                -under $m_hResultDataSet1\
                -ResultRootList $m_hProject \
                -ConfigClassId RsvpRouterConfig \
                -ResultClassId RsvpLspResults ]          
                 
            stc::perform ResultDataSetSubscribe -ResultDataSet $m_hResultDataSet    
            stc::perform ResultDataSetSubscribe -ResultDataSet $m_hResultDataSet1 

            set  ::mainDefine::m_hRsvpRouterResults $m_hRsvpRouterResults
            set  ::mainDefine::m_hRsvpLspResults $m_hRsvpLspResults
            set  ::mainDefine::m_hResultDataSet $m_hResultDataSet
            set  ::mainDefine::m_hResultDataSet1 $m_hResultDataSet1
            set  ::mainDefine::rsvpRouterCreated 1
        }
    }
    #Destructors
    destructor {
        #Delete corresponding objects
         stc::perform ResultDataSetUnsubscribe -ResultDataSet $m_hResultDataSet -ExecuteSynchronous TRUE  
         stc::perform ResultDataSetUnsubscribe -ResultDataSet $m_hResultDataSet1 -ExecuteSynchronous TRUE  
    }
    #Method declaration
    public method RsvpSetSession
    public method RsvpCreateEgressTunnel
    public method RsvpSetEgressTunnel    
    public method RsvpCreateIngressTunnel
    public method RsvpSetIngressTunnel    
    public method RsvpDeleteTunnel
    public method RsvpEnable
    public method RsvpDisable
    public method RsvpEstablishTunnel
    public method RsvpTeardownTunnel
    public method RsvpRetrieveRouterStats
    public method RsvpRetrieveRouter
    public method RsvpRetrieveTunnelStatus
    public method RsvpStopHello
    public method RsvpResumeHello
}
############################################################################
#APIName: ApplyToChassis
#
#Description: Download configurations to stc chassis
#
#Input: None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

proc ApplyToChassis {} {
    stc::apply
}
############################################################################
#APIName: RsvpSetSession
#
#Description: Configure the attributes of Rsvp Router
#
#Input: For details see API use documentation 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpSetSession {args} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpSetSession"
    
    #Get testerip from parameter lists
    set index [lsearch $args -testerip]
    if {$index != -1} {
       set testerip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]   
       set m_testerIp $testerip
    } else {
       if {$m_testerIp == ""} {
           error "please specify testerip for RsvpSetSession(RsvpRouter)"
       } else {
           set testerip $m_testerIp
       }
    }
   #Get dutip from parameter lists
    set index [lsearch $args -dutip]
    if {$index != -1} {
       set dutip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
       set m_dutIp $dutip
    } else {
       if {$m_dutIp == ""} {
           set m_dutIp 10.1.1.2
           set dutip $m_dutIp
       } else {
           set dutip $m_dutIp
       }
    } 
 
    set args [string  map {flaggracefulrestart enablegracefulrestart} $args]
    set args [string map {flaghello enablehello} $args]
    set args [string map {flagreliabledelivery enablereliabledelivery} $args]
    set args [string map {flagresvrequestconfirmation enableresvrequestconfirmation} $args]
    set args [string map {startinglabel labelmin} $args]
    set args [string map {endinglabel labelmax} $args]    

    set len [llength $args]
    if {$len % 2 != 0} {
        error "params of RsvpSetSession(RsvpRouter) must be in the form of pairs of '-attr value' "
    }

    #Configure ipv4 interface of Rsvp router
    stc::config $m_hIpv4If -Address $testerip -Gateway $dutip
    
    #Configure rsvp router 
    eval stc::config $m_hRsvpRouterConfig $args  -DutIpAddr $dutip -Transit RSVP_TRANSIT_ACCEPT_ALL
                                                                                        
    #Find corresponding Mac address and set the address according to testerip from Host
    SetMacAddress $testerip

    ApplyToChassis   
    debugPut "exit the proc of RsvpSession::RsvpSetSession"    
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
#APIName: RsvpCreateEgressTunnel
#
#Description:Create Rsvp Egress Tunnel
#
#Input: For details see API use documentation 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpCreateEgressTunnel {args} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    #Get tunnelname from parameter lists
    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelname [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       error "please specify tunnelName for RsvpCreateEgressTunnel API"
    } 
    #Check whether tunnelName is unique
    set index [lsearch $m_tunnelNameList $tunnelname]
    if {$index != -1} {
        error "the tunnelName($tunnelname) is already existed,please specify another one, the existed tunnelName(s) is(are): \m $m_tunnelNameList"
    } 
    lappend m_tunnelNameList $tunnelname
    set args [ConvertAttrToLowerCase1 $args]
    
    #Get srcip from parameter lists
    set index [lsearch $args -srcip]
    if {$index != -1} {
       set srcip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set srcip $m_testerIp
    } 
    lappend m_tunnelConfig($tunnelname) -srcip
    lappend m_tunnelConfig($tunnelname) $srcip
    #Get dstip from parameter lists
    set index [lsearch $args -dstip]
    if {$index != -1} {
       set dstip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set dstip $m_dutIp
    }    
    lappend m_tunnelConfig($tunnelname) -dstip
    lappend m_tunnelConfig($tunnelname) $dstip
    #Get tunnelid from parameter lists
    set index [lsearch $args -tunnelid]
    if {$index != -1} {
       set tunnelid [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set tunnelid [incr m_tunnelId]
    } 
    lappend m_tunnelConfig($tunnelname) -tunnelid
    lappend m_tunnelConfig($tunnelname) $tunnelid
    set m_tunnelConfig($tunnelname,dir) RSVP_TUNNEL_EGRESS
    

set RsvpEgressTunnelParams(1) [stc::create "RsvpEgressTunnelParams" \
        -under $m_hRsvpRouterConfig \
        -SrcIpAddr $srcip \
        -DstIpAddr $dstip  -name $tunnelname -active false -tunnelid $tunnelid]
set m_tunnelActive($tunnelname) false        

set Ipv4NetworkBlock(3) [lindex [stc::get $RsvpEgressTunnelParams(1) -children-Ipv4NetworkBlock] 0]
stc::config $Ipv4NetworkBlock(3) -StartIpList $dstip
set m_hTunnel($tunnelname) $RsvpEgressTunnelParams(1) 

    #ApplyToChassis   
    debugPut "exit the proc of RsvpSession::RsvpCreateEgressTunnel"    
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
#APIName: RsvpSetEgressTunnel
#
#Description:Configure Rsvp Egress Tunnel
#Input: For details see API use documentation
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpSetEgressTunnel {args} {
debugPut "enter the proc of RsvpSession::RsvpSetEgressTunnel"    
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    #Get tunnelname from parameter lists
    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelname [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       error "please specify tunnelName for RsvpSetEgressTunnel API"
    } 
    #Check whether tunnelName is unique
    set index [lsearch $m_tunnelNameList $tunnelname]
    if {$index == -1} {
        error "the tunnelName($tunnelname) does not exist,the existed tunnelName(s) is(are): \m $m_tunnelNameList"
    } 
    
    set args [ConvertAttrToLowerCase1 $args]
    #Get srcip from parameter lists
    set index [lsearch $args -srcip]
    if {$index != -1} {
       set srcip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set index [lsearch $m_tunnelConfig($tunnelname)  -srcip]
       set srcip [lindex $m_tunnelConfig($tunnelname) [expr $index + 1]]
    } 
   set index [lsearch $m_tunnelConfig($tunnelname)  -srcip]
   set m_tunnelConfig($tunnelname) [lreplace $m_tunnelConfig($tunnelname) [incr index] $index $srcip]
 
    #Get dstip from parameter lists
    set index [lsearch $args -dstip]
    if {$index != -1} {
       set dstip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set index [lsearch $m_tunnelConfig($tunnelname)  -dstip]
       set dstip [lindex $m_tunnelConfig($tunnelname) [expr $index + 1]]
    } 
   set index [lsearch $m_tunnelConfig($tunnelname)  -dstip]
   set m_tunnelConfig($tunnelname) [lreplace $m_tunnelConfig($tunnelname) [incr index] $index $dstip]
   
    #Get tunnelid from parameter lists
    set index [lsearch $args -tunnelid]
    if {$index != -1} {
       set tunnelid [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set index [lsearch $m_tunnelConfig($tunnelname)  -tunnelid]
       set tunnelid [lindex $m_tunnelConfig($tunnelname) [expr $index + 1]]
    } 
   set index [lsearch $m_tunnelConfig($tunnelname)  -tunnelid]
   set m_tunnelConfig($tunnelname) [lreplace $m_tunnelConfig($tunnelname) [incr index] $index $tunnelid]
    

 eval stc::config $m_hTunnel($tunnelname)   -SrcIpAddr $srcip  -DstIpAddr $dstip  -tunnelid $tunnelid $args -active false  

set Ipv4NetworkBlock(3) [lindex [stc::get $m_hTunnel($tunnelname) -children-Ipv4NetworkBlock] 0]
stc::config $Ipv4NetworkBlock(3) -StartIpList $dstip

    #ApplyToChassis  

    debugPut "exit the proc of RsvpSession::RsvpSetEgressTunnel"    
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
#APIName: RsvpRetrieveRouter
#
#Description: Get attributes of Rsvp Router
#Input: For details see API use documentation 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body RsvpSession::RsvpRetrieveRouter {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpRetrieveRouter"
    set list -routerstate
    lappend list  [stc::get $m_hRsvpRouterConfig -RouterState]
    
    #Update statistical infomation of rsvp router
    stc::perform RefreshResultView -ResultDataSet $m_hResultDataSet     
    set waitTime 2000
    after $waitTime
    
    #Get and return the statistical infomation of rsvp router
    set resultHandleList [stc::get $m_hResultDataSet -ResultHandleList]
    set resultHandle ""
    foreach handle $resultHandleList {
        set parent [stc::get $handle -parent]
        if {$parent == $m_hRsvpRouterConfig} {
             set resultHandle $handle
             break
        }
    }
    if {$resultHandle != ""} {     
       lappend list -lastrxpatherrorcode
       lappend list [stc::get $resultHandle -LastRxPathErrorCode]
       lappend list -lastrxreservationerrorcode
       lappend list [stc::get $resultHandle -LastRxReservationErrorCode]
       lappend list -lasttxpatherrorcode
       lappend list [stc::get $resultHandle -LastTxPathErrorCode]
       lappend list -lasttxreservationerrorcode
       lappend list [stc::get $resultHandle -LastTxReservationErrorCode]   
    
    }
    if {$args == ""} {
        debugPut "exit the proc of RsvpSession::RsvpRetrieveRouter" 
        #If it is the designated specific attr, return all -attr value list
        return $list
    } else {
        #If specific attr is designated, set the corresponding variable value
        set args [ConvertAttrToLowerCase $args]
        set list [ConvertAttrToLowerCase $list]
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                 continue
            }
           
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                        
       debugPut "exit the proc of RsvpSession::RsvpRetrieveRouter" 
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
#APIName: RsvpCreateIngressTunnel
#
#Description: Create Rsvp Ingress Tunnel
#
#Input: For details see API use documentation
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpCreateIngressTunnel {args} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpCreateIngressTunnel"
    #Get tunnelname from parameter lists
    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelname [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       error "please specify tunnelName for RsvpCreateIngressTunnel API"
    } 
    #Check whether tunnelName is unique
    set index [lsearch $m_tunnelNameList $tunnelname]
    if {$index != -1} {
        error "the tunnelName($tunnelname) is already existed,please specify another one, the existed tunnelName(s) is(are): \n $m_tunnelNameList"
    } 
    lappend m_tunnelNameList $tunnelname
    set args [ConvertAttrToLowerCase1 $args]
    
   set args [string map {strict RSVP_STRICT} $args]   
   set args [string map {loose RSVP_LOOSE} $args]   
   set args [string map {dstip DstIpAddr} $args] 
   set args [string map {srcip SrcIpAddr} $args] 
   set args [string map {lspcnt LspCount} $args] 

    #Get pathtype from parameter lists
    set index [lsearch $args -pathtype]
    if {$index != -1} {
       set pathtype [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set pathtype RSVP_STRICT
    } 
    #Get srcip from parameter lists
    set index [lsearch $args -SrcIpAddr]
    if {$index != -1} {
       set srcip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set srcip $m_testerIp
    } 
    set m_tunnelConfig($tunnelname) ""
    lappend m_tunnelConfig($tunnelname) -srcip
    lappend m_tunnelConfig($tunnelname) $srcip

    set index [lsearch $args -DstIpAddr]
    if {$index != -1} {
       set dstip [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set dstip $m_dutIp
    } 
    lappend m_tunnelConfig($tunnelname) -dstip
    lappend m_tunnelConfig($tunnelname) $dstip
    

    #Get tunnelid from parameter lists
    set index [lsearch $args -tunnelid]
    if {$index != -1} {
       set tunnelid [lindex $args [expr $index + 1]]
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set tunnelid [incr m_tunnelId]
    } 
    lappend m_tunnelConfig($tunnelname) -tunnelid
    lappend m_tunnelConfig($tunnelname) $tunnelid    

    set m_tunnelConfig($tunnelname,dir) RSVP_TUNNEL_INGRESS

    
    
    
    ######################
    set RsvpIngressTunnelParams(1) [eval stc::create "RsvpIngressTunnelParams" \
         -under $m_hRsvpRouterConfig $args -SrcIpAddr $srcip \
         -DstIpAddr $dstip -name $tunnelname -active false -tunnelid $tunnelid]
    set  m_tunnelActive($tunnelname) false
    set Ipv4NetworkBlock(2) [lindex [stc::get $RsvpIngressTunnelParams(1) -children-Ipv4NetworkBlock] 0]
    stc::config $Ipv4NetworkBlock(2)  -StartIpList $srcip 
    set MplsIf(1) [stc::create "MplsIf" \
        -under $m_hRouter \
        -LabelResolver "Rsvp" \
        -LabelList "" \
        -TTL "64" \
        -IfCountPerLowerIf "3" \
        -IsRange "FALSE" \
        -Name $tunnelname ]
    set m_hTunnel($tunnelname)  $RsvpIngressTunnelParams(1)

    stc::config $m_hTunnel($tunnelname) -ResolvesInterface-targets $MplsIf(1)                    

    #ApplyToChassis                                                    
    debugPut "exit the proc of RsvpSession::RsvpCreateIngressTunnel"    
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
#APIName: RsvpSetIngressTunnel
#
#Description: Configure Rsvp Ingress Tunnel
#Input: For details see API use documentation 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpSetIngressTunnel {args} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpSetIngressTunnel"
    #Get tunnelname from parameter lists
    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelname [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       error "please specify tunnelName for CreateRsvpIngressTunnel API"
    } 
    #Check whether tunnelName is unique
    set index [lsearch $m_tunnelNameList $tunnelname]
    if {$index == -1} {
        error "the tunnelName($tunnelname) does not exist, the existed tunnelName(s) is(are): \n $m_tunnelNameList"
    } 
    set args [ConvertAttrToLowerCase1 $args]
    
   set args [string map {strict RSVP_STRICT} $args]   
   set args [string map {loose RSVP_LOOSE} $args]   
   set args [string map {dstip DstIpAddr} $args] 
   set args [string map {srcip SrcIpAddr} $args] 
   set args [string map {lspcnt LspCount} $args] 

    #Get pathtype from parameter lists
    set index [lsearch $args -pathtype]
    if {$index != -1} {
       set pathtype [lindex $args [expr $index + 1]]       
       set args [lreplace $args $index [expr $index + 1]]
    } else {
       set pathtype RSVP_STRICT
    } 

    ######################
    if {$m_tunnelActive($tunnelname)== "true"} {
           stc::config $m_hTunnel($tunnelname)    -active false
           ApplyToChassis  
    }
    
    eval stc::config $m_hTunnel($tunnelname)  $args  -active $m_tunnelActive($tunnelname)

    #Get srcip from parameter lists
    set index [lsearch $args -SrcIpAddr]
    if {$index != -1} {
       set srcip [lindex $args [expr $index + 1]]

       set Ipv4NetworkBlock(2) [lindex [stc::get $m_hTunnel($tunnelname) -children-Ipv4NetworkBlock] 0]
       stc::config $Ipv4NetworkBlock(2)  -StartIpList $srcip 
       set MplsIf(1) [stc::create "MplsIf" \
               -under $m_hRouter \
               -LabelResolver "Rsvp" \
               -LabelList "" \
               -TTL "64" \
               -IfCountPerLowerIf "3" \
               -IsRange "FALSE" \
               -Name $tunnelname ]

               array set temp $m_tunnelConfig($tunnelname) 
               set temp(-srcip)  $srcip

               set m_tunnelConfig($tunnelname)  ""
               foreach name [array names temp] {
                   lappend m_tunnelConfig($tunnelname) $name
                   lappend m_tunnelConfig($tunnelname) $temp($name)
               }
    }   

    #Get dstip from parameter lists
    set index [lsearch $args -DstIpAddr]
    if {$index != -1} {
       set dstip [lindex $args [expr $index + 1]]

       array set temp $m_tunnelConfig($tunnelname) 
       set temp(-dstip)  $dstip
       set m_tunnelConfig($tunnelname)  ""
       foreach name [array names temp] {
           lappend m_tunnelConfig($tunnelname) $name
           lappend m_tunnelConfig($tunnelname) $temp($name)
       }
    }  
        

    if {$m_tunnelActive($tunnelname)== "true"} {
           ApplyToChassis  
    }                                             
    debugPut "exit the proc of RsvpSession::RsvpSetIngressTunnel"    
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
#APIName: RsvpDeleteTunnel
#
#Description: Delete Rsvp Tunnel
#Input: For details see API use documentation 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpDeleteTunnel {args} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpDeleteTunnel"
    #Get tunnelname from parameter lists    
    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelnamelist [lindex $args [expr $index + 1]]       
    } else {
       set tunnelnamelist $m_tunnelNameList
    } 

    foreach name $tunnelnamelist {
        #Check whether tunnelName exists
        set index [lsearch $m_tunnelNameList $name]
        if {$index == -1} {
            error "the tunnelName($name) dose not exist,the existed tunnelName(s) is(are): \n $m_tunnelNameList"
        } 
        set m_tunnelNameList [lreplace $m_tunnelNameList $index $index]
        #Delete tunnel
        stc::delete $m_hTunnel($name)
    }
    ApplyToChassis
    
    debugPut "exit the proc of RsvpSession::RsvpDeleteTunnel"    
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
#APIName: RsvpRetrieveRouterStats
#
#Description: Get current statistical infomation of Rsvp Router
#
#Input:None 
#
#Output: Current statistical infomation of Router
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpRetrieveRouterStats {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpRetrieveRouterStats"
       
    #Update statistical infomation of rsvp router 
    stc::perform RefreshResultView -ResultDataSet $m_hResultDataSet     
    set waitTime 5000
    after $waitTime
    
    #Get and return stastical infomaion of rsvp router
    set resultHandleList [stc::get $m_hResultDataSet -ResultHandleList]
    set resultHandle ""
    foreach handle $resultHandleList {
        set parent [stc::get $handle -parent]
        if {$parent == $m_hRsvpRouterConfig} {
             set resultHandle $handle
             break
        }
    }
    if {$resultHandle == ""} {return}
     
    set list [stc::get $resultHandle]
    if {$args == ""} {
        debugPut "exit the proc of RsvpSession::RsvpRetrieveRouterStats" 
        #If it is the designated specific attr, return all -attr value list
        return $list
    } else {
        #If specific attr is designated, set the corresponding variable value
        set args [ConvertAttrToLowerCase $args]
        set list [ConvertAttrToLowerCase $list]
        array set arr $list 
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                continue
            }
            
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                        
       debugPut "exit the proc of RsvpSession::RsvpRetrieveRouterStats" 
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
#APIName: RsvpRetrieveTunnelStatus
#
#Description: Get statistical infomation of Rsvp Tunnel
#
#Input:None 
#
#Output: Current statistical infomaton of Router
#
#Coded by: David.Wu
#############################################################################
::itcl::body RsvpSession::RsvpRetrieveTunnelStatus {{args ""}} {
    set list ""
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpRetrieveTunnelStatus"
        
    #Update statistical infomation of rsvp tunnel  
    set index [lsearch $args -tunnelname]
    if {$index == -1} {
        error "please specify tunnelname for RsvpRetrieveTunnelStatus API"
    }
    set tunnelname [lindex $args [incr index]]
    set index [lsearch $m_tunnelNameList $tunnelname]
    if {$index == -1} {
        error "the tunnelname ($tunnelname) does not exist, the existed tunnelname(s) is(are):\n$m_tunnelNameList"
    }

    set index [lsearch $m_tunnelConfig($tunnelname) -srcip]
    set srcip [lindex $m_tunnelConfig($tunnelname) [incr index]]
    set index [lsearch $m_tunnelConfig($tunnelname) -dstip]
    set dstip [lindex $m_tunnelConfig($tunnelname) [incr index]]    
    

    stc::perform RefreshResultView -ResultDataSet $m_hResultDataSet1     
    set waitTime 5000
    after $waitTime
    #Get and return statistical infomation of rsvp router
    set resultHandleList [stc::get $m_hResultDataSet1 -ResultHandleList]

    if {$resultHandleList == ""} {
         debugPut "exit the proc of RsvpSession::RsvpRetrieveTunnelStatus"
         return "" 
    }
    
    set tunnelStatus ""
    foreach handle $resultHandleList {
        catch {
            set sourceIp [stc::get $handle  -SrcIpAddr]
            set DstIpAddr [stc::get $handle  -DstIpAddr]
            set dir [stc::get $handle  -Direction]             
            #puts =========================================
            #puts [stc::get $handle]
            #puts ===========================================
            if {($srcip == $sourceIp)&&($dstip==$DstIpAddr)&&($dir==$m_tunnelConfig($tunnelname,dir) )} {
                lappend tunnelStatus  -Direction
                lappend tunnelStatus "[stc::get $handle -Direction]"

                lappend tunnelStatus  -DstIpAddr
                lappend tunnelStatus "[stc::get $handle -DstIpAddr]"

                lappend tunnelStatus  -SrcIpAddr
                lappend tunnelStatus "[stc::get $handle -SrcIpAddr]"

                lappend tunnelStatus  -TunnelId
                lappend tunnelStatus "[stc::get $handle -TunnelId]"

                lappend tunnelStatus  -ExtendedTunnelId
                lappend tunnelStatus "[stc::get $handle -ExtendedTunnelId]"

                lappend tunnelStatus  -Label
                lappend tunnelStatus "[stc::get $handle -Label]"

                lappend tunnelStatus  -LspId
                lappend tunnelStatus "[stc::get $handle -LspId]"

                lappend tunnelStatus  -RxPathMsg
                lappend tunnelStatus "[stc::get $handle -RxPathMsg]"

                lappend tunnelStatus  -RxReservationMsg
                lappend tunnelStatus "[stc::get $handle -RxReservationMsg]"

                lappend tunnelStatus  -TimeStamp
                lappend tunnelStatus "[stc::get $handle -TimeStamp]"

                lappend tunnelStatus  -Tunnelstate
                lappend tunnelStatus "[stc::get $handle -Tunnelstate]"

                lappend tunnelStatus  -TxPathMsg
                lappend tunnelStatus "[stc::get $handle -TxPathMsg]"

                lappend tunnelStatus  -TxReservationMsg
                lappend tunnelStatus "[stc::get $handle -TxReservationMsg]"

                break
            }
        }        
    }

     if {$tunnelStatus == ""} {
         error "Failed to get the status of the tunnel:$tunnelname, please check ... \n exit the proc of RsvpSession::RsvpRetrieveTunnelStatus"  
         return "" 
    }
   
    set args [lrange $args 2 end] 
    if {$args == ""} {
        debugPut "exit the proc of RsvpSession::RsvpRetrieveTunnelStatus"
        #If it is the designated specific attr, return all -attr value list  
        return $tunnelStatus
    } else {
        #If specific attr is designated, set the corresponding variable value
        set args [ConvertAttrToLowerCase $args]
        set tunnelStatus [ConvertAttrToLowerCase $tunnelStatus]
        array set arr $tunnelStatus
        foreach {name valueVar}  $args {      
      
            if {![info exist arr($name)]} {
                continue
            }
            
            set ::mainDefine::gAttrValue $arr($name) 
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }     
       debugPut "exit the proc of RsvpSession::RsvpRetrieveTunnelStatus"
       return $::mainDefine::gSuccess                   
    } 
}

############################################################################
#APIName: RsvpStopHello
#
#Description: Make current rsvp router stop sending hello message
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpStopHello {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpStopHello"
    #Make current rsvp router stop sending hello message
    stc::perform RsvpRsvpStopHellos -RouterList $m_hRouter
    debugPut "exit the proc of RsvpSession::RsvpStopHello"
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
#APIName: RsvpResumeHello
#
#Description: Make current rsvp router resume sending hello message
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpResumeHello {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpResumeHello"
    #Make current rsvp router resume sending hello message
    stc::perform RsvpResumeHellos -RouterList $m_hRouter
    debugPut "exit the proc of RsvpSession::ResumeHello"
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
#APIName: RsvpEnable
#
#Description: Enable current rsvp router
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpEnable {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpEnable"
    stc::config $m_hRsvpRouterConfig -active true
    ApplyToChassis
    debugPut "exit the proc of RsvpSession::RsvpEnable"
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
#APIName: RsvpDisable
#
#Description: Disable current rsvp router
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpDisable {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpDisable"
    stc::config $m_hRsvpRouterConfig -active false
    ApplyToChassis
    debugPut "exit the proc of RsvpSession::RsvpDisable"
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
#APIName: RsvpEstablishTunnel
#
#Description: Create designated RSVP Tunnel
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpEstablishTunnel {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpEstablishTunnel"


    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelnamelist  [lindex $args [expr $index + 1]]       
    } else {
       set tunnelnamelist   $m_tunnelNameList
    } 

    foreach name $tunnelnamelist {
        #Check whether tunnelName exists
        set index [lsearch $m_tunnelNameList $name]
        if {$index == -1} {
            error "the tunnelName($name) does not exist,the existed tunnelName(s) is(are): \n $m_tunnelNameList"
        } 
        if {$m_tunnelConfig($name,dir)== "RSVP_TUNNEL_INGRESS"} {
            stc::config $m_hTunnel($name) -active true
            set m_tunnelActive($name)  true
        }
    }
    ApplyToChassis
    debugPut "exit the proc of RsvpSession::RsvpEstablishTunnel"
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
#APIName: RsvpTeardownTunnel
#
#Description:Tear down designated RSVP Tunnel
#
#Input:None 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################

::itcl::body RsvpSession::RsvpTeardownTunnel {{args ""}} {
set list ""
if {[catch { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RsvpSession::RsvpTeardownTunnel"


    set index [lsearch $args -tunnelname]
    if {$index != -1} {
       set tunnelnamelist [lindex $args [expr $index + 1]]       
    } else {
       set tunnelnamelist  $m_tunnelNameList
    } 

    foreach name $tunnelnamelist {
        #Check whether tunnelName exists
        set index [lsearch $m_tunnelNameList $name]
        if {$index == -1} {
            error "the tunnelName($name) dose not exist,the existed tunnelName(s) is(are): \n $m_tunnelNameList"
        } 
        stc::config $m_hTunnel($name) -active false
    }
    ApplyToChassis
    debugPut "exit the proc of RsvpSession::RsvpTeardownTunnel"
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
