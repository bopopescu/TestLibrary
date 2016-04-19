###########################################################################
#                                                                        
#  Filename：ISISProtocol.tcl                                                                                              
# 
#  Description：Definition of ISIS protocol classes and relevant API                                            
# 
#  Creator： Penn.Chen
#
#  Time： 2007.4.20
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################
############################################################################
#APIName: GetGatewayIpv6
#Description: According to input IPv6 address,automatically get gateway address
#Input:  ipv6Addr - input ipv6 address
#Output: Automatically computed gateway address
#Coded by: Penn
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

proc GetGatewayIpv4 {ipv4Addr} {
    set list [split $ipv4Addr .]
    set len [llength $list]
    set tail 1
    if {[lindex $list [expr $len - 1]] == 1} {
        set tail 2
    }
    set addr [lindex $list 0]
    for {set i 1} {$i < [expr $len - 1]} {incr i} {
        append addr .[lindex $list $i]        
    }
    append addr .$tail
    return $addr
}

::itcl::class IsisSession {
    #Inherit Router class
    inherit Router

    #Variables 
    public variable m_hPort ""
    public variable m_hProject ""
    public variable m_routerName ""
    public variable m_portName ""
    public variable m_hRouter ""
    public variable m_hEthIIIf ""
    public variable m_hIpv4If ""
    public variable m_hIpv6If1 ""
    public variable m_hIpv6If2 ""
    public variable m_hIsisRouterConfig ""
    public variable m_systemid "00:10:94:00:00:02"
    public variable m_routerid "192.85.1.1"
    public variable m_isisRouterResult ""           
    public variable m_routerNameList ""
    public variable m_gridNameList ""    
    public variable m_lspBlockNameList "" 
    public variable m_linkNameList ""
    public variable m_topNetworkList ""    
    public variable m_FlagFlapList    
    public variable m_awdTimer 5  
    public variable m_wadTimer 5
    public variable m_holdtimer 20
    public variable m_topRouterConfig 
    public variable m_isisGridConfig
    public variable m_isisNetworkConfig                  
    public variable m_isisLspGenParamsArr 
    public variable m_topRouterLinkConfig 
    public variable m_isisRouteBlockConfig 
    public variable m_hResultDataSet    
    public variable m_sequencer  ""  
    public variable m_ipProtocol "IPV4"
    public variable m_portType "ethernet"
    public variable m_firstAddressListFlag "FALSE"
      
    #Relevant configuration about ConfigRouter
    public variable m_addressfamily "IPV4"
    public variable m_ipv4addr "192.85.1.3"
    public variable m_macaddr "00:10:94:00:00:02"
    public variable m_ipv4prefixlen 24
    public variable m_ipv6addr "2000::2"
    public variable m_ipv6prefixlen 64
    public variable m_active TRUE
    public variable m_areaid 000001
    public variable m_areaid2 000002
    public variable m_areaid3 000003
    public variable m_flagrestarthelper false
    public variable m_iihinterval 5
    public variable m_maxpacketsize 1492
    public variable m_routinglevel "L2"
    public variable m_flagwidemetric true
    public variable m_metricmode "NARROW_AND_WIDE"
    public variable m_metric "1"
    #public variable m_l1metric "1"
    #public variable m_l1widemetric "1"
    #public variable m_l2metric "1"
    #public variable m_l2widemetric "1"
    public variable m_psnpinterval 2 
    public variable m_l1routerpriority 0
    public variable m_l2routerpriority 0
    

    public variable m_LocalMac "00:00:00:11:01:01"
    public variable m_LocalMacModifier "00:00:00:00:00:01"
    
    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
           { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {    
        set m_routerName $routerName   
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
      
        #Create IPv4if object under the router object
        set m_hIpv4If [stc::get $hRouter -children-Ipv4If]   
        
        #Create IPv6if object under the router object
        set hIpv6IfList [stc::get $hRouter -children-Ipv6If]
        set m_hIpv6If1 [lindex $hIpv6IfList 0] 
        set m_hIpv6If2 [lindex $hIpv6IfList 1]  
      
        #Create ISIS router object under the router object        
        set m_hIsisRouterConfig [stc::create "IsisRouterConfig" -under $m_hRouter -name $routerName ]
        
        #Make objects associated              
        stc::config $m_hIsisRouterConfig -UsesIf-targets "$m_hIpv4If "
        

        set ::mainDefine::gPoolCfgBlock($m_routerName) $m_hIpv4If
    } 

    destructor {  
    }

    public method IsisSetSession
    public method IsisRetrieveRouter
    public method IsisRetrieveRouterStats 
    public method IsisRetrieveRouterStatus          
    public method IsisEnable
    public method IsisDisable
    
    public method IsisCreateTopGrid
    public method IsisSetTopGrid   
    public method IsisDeleteTopGrid      

    public method IsisCreateTopRouter     
    public method IsisSetTopRouter 
    public method  IsisDeleteTopRouter
    
    public method IsisCreateTopRouterLink
    public method IsisSetTopRouterLink 
    public method IsisDeleteTopRouterLink 

    public method IsisCreateTopNetwork
    public method IsisSetTopNetwork 
    public method IsisDeleteTopNetwork
           
    public method IsisCreateRouteBlock 
    public method IsisSetRouteBlock 
    public method IsisDeleteRouteBlock 
    public method IsisRetrieveRouteBlock   
    public method IsisListRouteBlock        
    public method IsisAdvertiseRouteBlock
    public method IsisWithdrawRouteBlock       
    public method IsisStartFlapRouteBlock       
    public method IsisSetFlapRouteBlock
    public method IsisStopFlapRouteBlock
    
    #PHASE III added
    public method IsisSetFlap    
    public method IsisAdvertiseRouters
    public method IsisWithdrawRouters
    public method IsisAdvertiseLinks
    public method IsisWithdrawLinks
    public method IsisStartFlapLinks
    public method IsisStopFlapLinks
    public method IsisStartFlapRouters
    public method IsisStopFlapRouters
    public method IsisGraceRestartAction                    
}

############################################################################
#APIName: IsisSetSession
#
#Description: 
#
#Input:    
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetSession {args} {  
    #Transfer input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisSetSession"
 
    set index [lsearch $args -addressfamily]
    if {$index != -1} {
       set addressfamily [lindex $args [expr $index + 1]]
       set m_addressfamily $addressfamily
    } else {
       set addressfamily $m_addressfamily
    }
         
    set index [lsearch $args -ipv4addr]
    if {$index != -1} {
       set ipv4addr [lindex $args [expr $index + 1]]
       set m_ipv4addr $ipv4addr
    } else {
       set ipv4addr $m_ipv4addr
    } 

    set index [lsearch $args -macaddr]
    if {$index != -1} {
       set macaddr [lindex $args [expr $index + 1]]
       set m_macaddr $macaddr
    } else {
       set macaddr $m_macaddr
    }
    
    set index [lsearch $args -gatewayaddr]
    if {$index != -1} {
       set gatewayaddr [lindex $args [expr $index + 1]]
    } else {
       set gatewayaddr [GetGatewayIpv4 $ipv4addr]
    } 
        
    set index [lsearch $args -ipv4prefixlen]
    if {$index != -1} {
       set ipv4prefixlen [lindex $args [expr $index + 1]]
       set m_ipv4prefixlen $ipv4prefixlen
    } else {
       set ipv4prefixlen $m_ipv4prefixlen
    }   
    
    set index [lsearch $args -ipv6addr]
    if {$index != -1} {
       set ipv6addr [lindex $args [expr $index + 1]]
       set m_ipv6addr $ipv6addr
    } else {
       set ipv6addr $m_ipv6addr
    }   
    
    set index [lsearch $args -ipv6prefixlen]
    if {$index != -1} {
       set ipv6prefixlen [lindex $args [expr $index + 1]]
       set m_ipv6prefixlen $ipv6prefixlen 
    } else {
       set ipv6prefixlen $m_ipv6prefixlen
    }           

    set index [lsearch $args -ipv6gatewayaddr]
    if {$index != -1} {
       set ipv6gatewayaddr [lindex $args [expr $index + 1]]
    } else {
       set ipv6gatewayaddr [GetGatewayIpv6 $ipv6addr]
    }
    
    set index [lsearch $args -active]
    if {$index != -1} {
       set active [lindex $args [expr $index + 1]]
    } else {
       set active TRUE
    }          
    set active [string map {0 false} $active]
    set active [string map {disable false} $active]
    set active [string map {off false} $active]
    set active [string map {1 true} $active]
    set active [string map {Enable true} $active]
    set active [string map {on true} $active]
    set active [string map {on true} $active]    

    set index [lsearch $args -areaid]
    if {$index != -1} {
       set areaid [lindex $args [expr $index + 1]]
       set m_areaid $areaid
    } else {
       set areaid $m_areaid
    }    

    set index [lsearch $args -areaid2]
    if {$index != -1} {
       set areaid2 [lindex $args [expr $index + 1]]
       set m_areaid2 $areaid2
    } else {
       set areaid2 $m_areaid2
    }    

    set index [lsearch $args -areaid3]
    if {$index != -1} {
       set areaid3 [lindex $args [expr $index + 1]]
       set m_areaid3 $areaid3
    } else {
       set areaid3 $m_areaid3
    }    
        
    set index [lsearch $args -systemid]
    if {$index != -1} {
       set systemid [lindex $args [expr $index + 1]]
       set m_systemid $systemid
    } else {
       set systemid $m_systemid 
    }    

    set index [lsearch $args -routerid]
    if {$index != -1} {
        set routerid [lindex $args [expr $index + 1]]
        set m_routerid $routerid
    } else {
        set routerid $m_routerid 
    }
    
    set index [lsearch $args -flagrestarthelper]
    if {$index != -1} {
       set flagrestarthelper [lindex $args [expr $index + 1]]
       set m_flagrestarthelper $flagrestarthelper
    } else {
       set flagrestarthelper $m_flagrestarthelper
    }   
    set flagrestarthelper [string map {0 false} $flagrestarthelper]
    set flagrestarthelper [string map {disable false} $flagrestarthelper]
    set flagrestarthelper [string map {off false} $flagrestarthelper]
    set flagrestarthelper [string map {1 true} $flagrestarthelper]
    set flagrestarthelper [string map {enable true} $flagrestarthelper]
    set flagrestarthelper [string map {on true} $flagrestarthelper]
    set flagrestarthelper [string map {on true} $flagrestarthelper] 
        
    set index [lsearch $args -iihinterval]
    if {$index != -1} {
       set iihinterval [lindex $args [expr $index + 1]]
       set m_iihinterval $iihinterval
    } else {
       set iihinterval $m_iihinterval
    }    

    set index [lsearch $args -holdtimer]
    if {$index != -1} {
       set holdtimer [lindex $args [expr $index + 1]]
    } else {
       set holdtimer [expr $iihinterval*4]
       set m_holdtimer $holdtimer
    }
        
    set index [lsearch $args -maxpacketsize]
    if {$index != -1} {
       set maxpacketsize [lindex $args [expr $index + 1]]
       set m_maxpacketsize $maxpacketsize
    } else {
       set maxpacketsize $m_maxpacketsize
    }   
    
    set index [lsearch $args -routinglevel]
    if {$index != -1} {
       set routinglevel [lindex $args [expr $index + 1]]
       set m_routinglevel $routinglevel
    } else {
       set routinglevel $m_routinglevel
    }    

    set index [lsearch $args -flagwidemetric]
    if {$index != -1} {
        set flagwidemetric [lindex $args [expr $index + 1]]
    } else {
        set flagwidemetric $m_flagwidemetric
    }
    set flagwidemetric [string tolower $flagwidemetric]
    if {$flagwidemetric == false} {
        set metricmode "NARROW"
    } else {
        set metricmode "NARROW_AND_WIDE"
    }
 
    set index [lsearch $args -metricmode]
    if {$index != -1} {
       set metricmode [lindex $args [expr $index + 1]]
    }

    set m_metricmode $metricmode

    set index [lsearch $args -metric]
    if {$index != -1} {
        set metric [lindex $args [expr $index + 1]]
    } else {
        set metric $m_metric
    }   
 
    if {$flagwidemetric == false} {
        set m_l1widemetric 1
        set m_l2widemetric 1
        set m_l1metric $metric
        set m_l2metric $metric
    } else {
        set m_l1widemetric $metric
        set m_l2widemetric $metric
        set m_l1metric 1
        set m_l2metric 1
    }

    set index [lsearch $args -psnpinterval]
    if {$index != -1} {
       set psnpinterval [lindex $args [expr $index + 1]]
       set m_psnpinterval $psnpinterval
    } else {
       set psnpinterval $m_psnpinterval
    }    
    
    #Get the parameter value of TestLinkLocalAddr
    set index [lsearch $args -testlinklocaladdr] 
    if {$index != -1} {
        set TestLinkLocalAddr [lindex $args [expr $index + 1]]
    } 
    
    

    #Abstract the value of LocalMac
    set index [lsearch $args -localmac]
    if {$index != -1} {
        set LocalMac [lindex $args [expr $index + 1]]
        set m_LocalMac $LocalMac
    }
    
    #Abstract the value of LocalMacModifier
    set index [lsearch $args -localmacmodifier]
    if {$index != -1} {
        set LocalMacModifier [lindex $args [expr $index + 1]]
        set m_LocalMacModifier $LocalMacModifier
    }
    
    set addressfamily [string tolower $addressfamily]
    
    #Make conversion of parameter keywords
    switch $addressfamily {
        ipv4 {
            set ipversion "IPV4"       
        }
        ipv6 {
            set ipversion "IPV6"        
        }       
        both {
            set ipversion "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified AddressFamily is invaild"
        }
    }

    set m_ipProtocol $ipversion
     switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
        l1/l2 {
            set level "LEVEL1_AND_2"        
        }                   
        L1/L2 {
            set level "LEVEL1_AND_2"        
        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1,L2,L1/L2"
        }
    }       

    set index [lsearch $args -l2routerpriority]
    if {$index != -1} {
        set l2routerpriority [lindex $args [expr $index + 1]]
    } else {
        set l2routerpriority $m_l2routerpriority
    }

    set index [lsearch $args -l1routerpriority]
    if {$index != -1} {
        set l1routerpriority [lindex $args [expr $index + 1]]
    } else {
        set l1routerpriority $m_l1routerpriority
    }
    if {$level == "LEVEL1"} {
        set routerpriority $l1routerpriority
    } else {
        set routerpriority $l2routerpriority
    }
       
    stc::config $m_hIsisRouterConfig \
        -IpVersion $ipversion \
        -Level $level \
        -SystemId $systemid \
        -Area1 $areaid \
        -Area2 $areaid2 \
        -Area3 $areaid3 \
        -HelloInterval $iihinterval \
        -HelloMultiplier [expr $holdtimer/$iihinterval] \
        -PsnInterval $psnpinterval \
        -FloodDelay "33" \
        -LspRefreshTime "900" \
        -RetransmissionInterval "5" \
        -LspSize $maxpacketsize \
        -TeRouterId "$routerid" \
        -MetricMode $metricmode \
        -L1Metric $m_l1metric \
        -L1WideMetric $m_l2widemetric \
        -L2Metric $m_l2metric \
        -L2WideMetric $m_l2widemetric \
        -RouterPriority $routerpriority \
        -EnableGracefulRestart $flagrestarthelper \
        -T1Timer "3" \
        -RemainingTime "null" \
        -EnableEventLog "FALSE" \
        -UsePartialBlockState "FALSE" \
        -Active $active

    set hIsisLevel1TeParams [stc::get $m_hIsisRouterConfig -children-IsisLevel1TeParams]
    stc::config $hIsisLevel1TeParams \
        -SubTlv "0" \
        -BandwidthUnit "BYTES_PER_SEC" \
        -TeLocalIpv4Addr "0.0.0.0" \
        -TeRemoteIpv4Addr "0.0.0.0" \
        -TeGroup "1" \
        -TeMaxBandwidth "100000" \
        -TeRsvrBandwidth "100000" \
        -TeUnRsvrBandwidth0 "100000" \
        -TeUnRsvrBandwidth1 "100000" \
        -TeUnRsvrBandwidth2 "100000" \
        -TeUnRsvrBandwidth3 "100000" \
        -TeUnRsvrBandwidth4 "100000" \
        -TeUnRsvrBandwidth5 "100000" \
        -TeUnRsvrBandwidth6 "100000" \
        -TeUnRsvrBandwidth7 "100000"

    set hIsisLevel2TeParams [stc::get $m_hIsisRouterConfig -children-IsisLevel2TeParams]
    stc::config $hIsisLevel2TeParams \
        -SubTlv "0" \
        -BandwidthUnit "BYTES_PER_SEC" \
        -TeLocalIpv4Addr "0.0.0.0" \
        -TeRemoteIpv4Addr "0.0.0.0" \
        -TeGroup "1" \
        -TeMaxBandwidth "100000" \
        -TeRsvrBandwidth "100000" \
        -TeUnRsvrBandwidth0 "100000" \
        -TeUnRsvrBandwidth1 "100000" \
        -TeUnRsvrBandwidth2 "100000" \
        -TeUnRsvrBandwidth3 "100000" \
        -TeUnRsvrBandwidth4 "100000" \
        -TeUnRsvrBandwidth5 "100000" \
        -TeUnRsvrBandwidth6 "100000" \
        -TeUnRsvrBandwidth7 "100000" 
        
    if {[string tolower $m_portType]=="ethernet"} {        
        #Configure Ethernet head object
        stc::config $m_hEthIIIf \
            -SourceMac $macaddr
    }        
              
    if {$ipversion == "IPV4" } {
        set m_hIpAddress $m_hIpv4If

        #Find corresponding Mac address and set the address according to ipv4addr from Host
        SetMacAddress $ipv4addr

        #Configure IP head object
        stc::config $m_hIpv4If \
            -Address $ipv4addr \
            -PrefixLength $ipv4prefixlen \
            -Gateway $gatewayaddr

        if {$m_hIpv6If1 != ""} {
            stc::delete $m_hIpv6If1
            set m_hIpv6If1 ""
        }
        if {$m_hIpv6If2 != ""} {
            stc::delete $m_hIpv6If2
            set m_hIpv6If2 ""
        }

        stc::config $m_hRouter -TopLevelIf-targets "$m_hIpv4If "
        stc::config $m_hRouter -PrimaryIf-targets "$m_hIpv4If "
        stc::config $m_hIsisRouterConfig -UsesIf-targets "$m_hIpv4If "

        #Add by Andy.zhang 04.11 2012
        set ::mainDefine::gPoolCfgBlock($m_routerName) $m_hIpv4If        
        
    } elseif {$ipversion == "IPV6" } {
        stc::delete $m_hIpv4If

        set m_hIpAddress $m_hIpv6If1
        stc::config $m_hIpv6If2 \
              -Address $ipv6addr \
              -Gateway $ipv6gatewayaddr \
              -PrefixLength $ipv6prefixlen   

        #Add by Andy.zhang 04.11 2012
        set ::mainDefine::gPoolCfgBlock($m_routerName) $m_hIpv6If2 
  
        if {[info exists TestLinkLocalAddr]} { 
           stc::config $m_hIpv6If1 -Address $TestLinkLocalAddr -Gateway $ipv6gatewayaddr -PrefixLength $ipv6prefixlen  
        }

        #Find corresponding Mac address and set the address according to ipv6addr from Host
        SetMacAddress $ipv6addr "Ipv6"

        #Set object relation
        stc::config $m_hRouter -TopLevelIf-targets " $m_hIpv6If1 $m_hIpv6If2 "
        stc::config $m_hRouter -PrimaryIf-targets " $m_hIpv6If1 $m_hIpv6If2 "            
        stc::config $m_hIsisRouterConfig -UsesIf-targets " $m_hIpv6If1 "
        
    } else {
        set m_hIpAddress $m_hIpv4If

        #Find corresponding Mac address and set the address according to ipv4addr from Host
        SetMacAddress $ipv4addr

        #Configure IP head object
        stc::config $m_hIpv4If \
            -Address $ipv4addr \
            -PrefixLength $ipv4prefixlen \
            -Gateway $gatewayaddr

        stc::config $m_hIpv6If2 \
            -Address $ipv6addr \
            -Gateway $ipv6gatewayaddr \
            -PrefixLength $ipv6prefixlen  

        if {[info exists TestLinkLocalAddr]} { 
           stc::config $m_hIpv6If1 -Address $TestLinkLocalAddr -Gateway $ipv6gatewayaddr -PrefixLength $ipv6prefixlen  
        }

        stc::config $m_hRouter -TopLevelIf-targets " $m_hIpv4If $m_hIpv6If1 $m_hIpv6If2 "
        stc::config $m_hRouter -PrimaryIf-targets " $m_hIpv4If $m_hIpv6If1 $m_hIpv6If2 "  
        stc::config $m_hIsisRouterConfig -UsesIf-targets " $m_hIpv4If "   
    } 
       

    if {[string tolower $m_portType]=="ethernet"} {
        set hEthIIIf $m_hEthIIIf
        if {[info exists LocalMac]} {
            stc::config $hEthIIIf -SourceMac $m_LocalMac
        }
        if {[info exists LocalMacModifier]} {
            stc::config $hEthIIIf -SrcMacStep $m_LocalMacModifier
        }
   }
    
    #Deliver configuration command and check
    ApplyValidationCheck

    debugPut "exit the proc of IsisSession::IsisSetSession"
    return $::mainDefine::gSuccess       
}

############################################################################
#APIName: IsisRetrieveRouter
#
#Description: Get relevant statistical results about Isis
#
#Input:    (1) -AddressFamily Optional parameters, optional value is IPv4, IPv6, both
#            (2) -Ipv4Addr   Mandatory parameters, IP address of Isis Routers
#            (3) -Ipv4PrefixLen  Optional parameters, prefix length of the IP address   
#            (4) -Ipv6Addr  Mandatory parameters, IPv6 address of Isis Routers 
#            (5) -Ipv6PrefixLen  
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisRetrieveRouter {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisRetrieveRouter"

    set IsisRouterConfig ""
    if {[string tolower $m_portType]=="ethernet"} {    
        lappend IsisRouterConfig -macaddr
        lappend IsisRouterConfig [stc::get $m_hEthIIIf -SourceMac]
    }

    if {$m_ipProtocol != "IPV6"} {
        lappend IsisRouterConfig -gatewayaddr
        lappend IsisRouterConfig [stc::get $m_hIpv4If -Gateway]
        lappend IsisRouterConfig -ipv4addr
        lappend IsisRouterConfig [stc::get $m_hIpv4If -Address] 
        lappend IsisRouterConfig -ipv4prefixlen
        lappend IsisRouterConfig [stc::get $m_hIpv4If -PrefixLength] 
    }

    lappend IsisRouterConfig -addressfamily
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -IpVersion]    
    lappend IsisRouterConfig -routinglevel
    set level [stc::get $m_hIsisRouterConfig -Level]
    lappend IsisRouterConfig $level
    lappend IsisRouterConfig -systemid
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -SystemId]  
    lappend IsisRouterConfig -routerid
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -TeRouterId]
    lappend IsisRouterConfig -areaid
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -Area1]    
    lappend IsisRouterConfig -areaid2
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -Area2]    
    lappend IsisRouterConfig -areaid3
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -Area3]      
    lappend IsisRouterConfig -iihinterval
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -HelloInterval]l  
    lappend IsisRouterConfig -holdtimer
    lappend IsisRouterConfig $m_holdtimer   
    lappend IsisRouterConfig -psnpinterval
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -PsnInterval]     
    lappend IsisRouterConfig -maxpacketsize
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -LspSize]    
    lappend IsisRouterConfig -flagwidemetric
    set metricmode [stc::get $m_hIsisRouterConfig -MetricMode]
    if {$metricmode == "NARROW"} {
        set flagwidemetric false
    } else {
        set flagwidemetric true
    }
    lappend IsisRouterConfig $flagwidemetric     
    lappend IsisRouterConfig -metric
    if {$metricmode == "NARROW"} {
        if {$level == "LEVEL1"} {
            set metric [stc::get $m_hIsisRouterConfig -L1Metric]
        } else {
            set metric [stc::get $m_hIsisRouterConfig -L2Metric]
        }
    } else {
        if {$level == "LEVEL1"} {
            set metric [stc::get $m_hIsisRouterConfig -L1WideMetric]
        } else {
            set metric [stc::get $m_hIsisRouterConfig -L2WideMetric]
        }
    } 
    lappend IsisRouterConfig $metric
    #lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -L1Metric] 
    #lappend IsisRouterConfig -l1widemetric
    #lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -L1WideMetric] 
    #lappend IsisRouterConfig -l2metric
    #lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -L2Metric]    
    #lappend IsisRouterConfig -l2widemetric
    #lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -L2WideMetric]
    lappend IsisRouterConfig -flagrestarthelper
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -EnableGracefulRestart] 
    lappend IsisRouterConfig -state
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -RouterState]      
    lappend IsisRouterConfig -active
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -Active] 
    lappend IsisRouterConfig -l2routerpriority
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -RouterPriority]
    lappend IsisRouterConfig -l1routerpriority
    lappend IsisRouterConfig [stc::get $m_hIsisRouterConfig -RouterPriority]
       
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IsisSession::IsisRetrieveRouter" 
        return $IsisRouterConfig
    } else {     
        set IsisRouterConfig [string tolower $IsisRouterConfig]
        array set arr $IsisRouterConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of IsisSession::IsisRetrieveRouter"   
    return $::mainDefine::gSuccess     
    }      
}

############################################################################
#APIName: IsisRetrieveRouterStats
#
#Description: Get relevant state of Isis 
#
#Input:          
#
#Output: Return the state value of routers in the form of arrays
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisRetrieveRouterStats {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of IsisSession::IsisRetrieveRouterStats"    

    set ::mainDefine::objectName $m_portName 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
     }
     set DeviceHandle $::mainDefine::result 
        
     set ::mainDefine::objectName $DeviceHandle 
     uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_isisRouterResultHandle ]
     }
     set isisRouterResultHandle $::mainDefine::result 
     if {[catch {
         set errorCode [stc::perform RefreshResultView -ResultDataSet $isisRouterResultHandle  ]
     } err]} {
         return $errorCode
     }
 
    set hIsisRouterResults [stc::get $m_hIsisRouterConfig -children-isisrouterresults]
    set IsisRouterStats ""
    lappend IsisRouterStats -L1HelloPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL1LanHelloCount]
    lappend IsisRouterStats -L2HelloPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL2LanHelloCount] 
    lappend IsisRouterStats -PtopHelloPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxPtpHelloCount]  
    lappend IsisRouterStats -L1LspPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL1LspCount]  
    lappend IsisRouterStats -L2LspPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL2LspCount]  
    lappend IsisRouterStats -L1CsnpPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL1CsnpCount]  
    lappend IsisRouterStats -L2CsnpPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL2CsnpCount]  
    lappend IsisRouterStats -L1PsnpPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL1PsnpCount]  
    lappend IsisRouterStats -L2PsnpPacketReceived
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL2PsnpCount]     
    lappend IsisRouterStats -L1HelloPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL1LanHelloCount]
    lappend IsisRouterStats -L2HelloPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL2LanHelloCount] 
    lappend IsisRouterStats -PtopHelloPackeSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxPtpHelloCount]  
    lappend IsisRouterStats -L1LspPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL1LspCount]  
    lappend IsisRouterStats -L2LspPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL2LspCount]  
    lappend IsisRouterStats -L1CsnpPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL1CsnpCount]  
    lappend IsisRouterStats -L2CsnpPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL2CsnpCount]  
    lappend IsisRouterStats -L1PsnpPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -TxL1PsnpCount]  
    lappend IsisRouterStats -L2PsnpPacketSent
    lappend IsisRouterStats [stc::get $hIsisRouterResults -RxL2PsnpCount] 

     #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IsisSession::IsisRetrieveRouterStats" 
        return $IsisRouterStats
    } else {     
        set IsisRouterStats [string tolower $IsisRouterStats]
        array set arr $IsisRouterStats
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
        debugPut "exit the proc of IsisSession::IsisRetrieveRouterStats"
        return $::mainDefine::gSuccess     
    }      
}

############################################################################
#APIName: IsisRetrieveRouterStatus
#
#Description: 
#
#Input:          
#
#Output: Return the statistic of routers in the form of arrays
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisRetrieveRouterStatus {args} {  
    debugPut "enter the proc of IsisSession::IsisRetrieveRouterStatus"
         
    lappend IsisRouterStatus -state
    lappend IsisRouterStatus [stc::get $m_hIsisRouterConfig -RouterState]
           		      
    set retValue [GetValuesFromArray $args $IsisRouterStatus]

    debugPut "exit the proc of IsisSession::IsisRetrieveRouterStatus" 
    return $retValue
}

############################################################################
#APIName: IsisEnable
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisEnable {args} {    
    debugPut "enter the proc of IsisSession::IsisEnable"    
    stc::config $m_hRouter -Active TRUE   
    stc::config $m_hIsisRouterConfig -Active TRUE   
    
    #Deliver configuration command and check
    ApplyValidationCheck
             
    debugPut "exit the proc of IsisSession::IsisEnable"  
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: IsisDisable
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDisable {args} {      
    debugPut "enter the proc of IsisSession::IsisDisable"
    
    set hIsisRouterConfig [stc::get $m_hRouter -children-isisrouterconfig]
    stc::config $m_hRouter -Active FALSE
    stc::config $m_hIsisRouterConfig -Active FALSE 
     
    #Deliver configuration command and check
    ApplyValidationCheck
          
    debugPut "exit the proc of IsisSession::IsisDisable" 
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: IsisCreateTopRouter
#
#Description: Add an ISIS router in the test topology
#
#Input:    (1) -RouterName  Mandatory parameters, name identification of ISIS Router, each ISIS's neighbour is unique 
#            (2) -SystemId  Optional parameters
#            (4) -PseudonodeNumber  Optional parameters
#            (5) -RoutingLevel   Optional parameters 
#            (6) -FlagTe  Optional parameters
#            (7) -FlagTag  Optional parameters  
#            (8) -FlagMultiTopology  Optional parameters
#            (9) -FlagAdvetisted  Optional parameters 
#           (10) -AddressFamily  Optional parameters
#           (11) -FlagAttachedBit  Optional parameters  
#           (12) -FlagOverLoadBit  Optional parameters
#           (13) -AreaId   Optional parameters        
#           (14) -AreaIdList   Optional parameters
#           (15) -LinkNum   Optional parameters
#           (16) -RoutingLevel   Optional parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisCreateTopRouter {args} {   

    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of IsisSession::IsisCreateTopRouter"

    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify RouterName for IsisSession::IsisCreateTopRouter"
    }
    
    set index [lsearch $m_routerNameList $routername]
    if {$index != -1} {
       error "$routername already exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    }     
    lappend m_routerNameList $routername
    lappend m_topRouterConfig($routername) -routername           
    lappend m_topRouterConfig($routername) $routername  

    set index [lsearch $args -systemid]
    if {$index != -1} {
       set systemid [lindex $args [expr $index + 1]]
    } else {
       set systemid "00:00:64:c8:01:01"
    } 
    lappend m_topRouterConfig($routername) -systemid           
    lappend m_topRouterConfig($routername) $systemid  
    

    set index [lsearch $args -pseudonodenumber]
    if {$index != -1} {
       set pseudonodenumber [lindex $args [expr $index + 1]]
    } else {
       set pseudonodenumber 0
    }
    lappend m_topRouterConfig($routername) -pseudonodenumber           
    lappend m_topRouterConfig($routername) $pseudonodenumber  

       
    set index [lsearch $args -routinglevel]
    if {$index != -1} {
       set routinglevel [lindex $args [expr $index + 1]]
    } else {
       set routinglevel L2
    }
    lappend m_topRouterConfig($routername) -routinglevel           
    lappend m_topRouterConfig($routername) $routinglevel 
    
    set index [lsearch $args -flagattachedbit]
    if {$index != -1} {
       set flagattachedbit [lindex $args [expr $index + 1]]
    } else {
       set flagattachedbit "FALSE"
    } 
    lappend m_topRouterConfig($routername) -flagattachedbit           
    lappend m_topRouterConfig($routername) $flagattachedbit     

    set index [lsearch $args -flagoverloadbit]
    if {$index != -1} {
       set flagoverloadbit [lindex $args [expr $index + 1]]
    } else {
       set flagoverloadbit "FALSE"
    } 
    lappend m_topRouterConfig($routername) -flagoverloadbit           
    lappend m_topRouterConfig($routername) $flagoverloadbit           
 
     set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
       set flagte false
    }
    lappend m_topRouterConfig($routername) -flagte           
    lappend m_topRouterConfig($routername) $flagte 

        
    switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
#        l1/l2 {
#            set level "LEVEL1_AND_2"        
#        }                   
#        L1/L2 {
#            set level "LEVEL1_AND_2"        
#        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1 or L2"
        }
    }       

    if {$level != [stc::get $m_hIsisRouterConfig -level]} {
        #error "The specified RoutingLevel of TopRouter must equal to the IsisRouter level: [stc::get $m_hIsisRouterConfig -level]"  
    } 
          
    #Get object handles of emulated router
    set DefaultSystemId [stc::get $m_hIsisRouterConfig -systemid]
    set Level [stc::get $m_hIsisRouterConfig -level]
    set TeRouterId [stc::get $m_hIsisRouterConfig -TeRouterId]    

    #Check whether there is the systemid of ISIS router in current LSP
    set hIsisLsp "" 
    set hIsisLspList [stc::get $m_hIsisRouterConfig -children-isislspconfig]  
     
    foreach sr $hIsisLspList {
        set SysId [stc::get $sr -systemid]
        if {$SysId == $DefaultSystemId } {
            set hIsisLsp $sr
        }
    }
    
    if {$hIsisLsp == "" } {           
        set hIsisLsp [stc::create IsisLspConfig \
            -under $m_hIsisRouterConfig \
            -Level $level \
            -SystemId $DefaultSystemId \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active "FALSE"]
    } 
    lappend m_topRouterConfig($routername) -hIsisLspConfig  
    lappend m_topRouterConfig($routername) $hIsisLsp     

    #Create neighbor object under the ISIS Router LSP object      
    set hIsisLspNeighborConfig [stc::create IsisLspNeighborConfig \
        -under $hIsisLsp \
        -NeighborPseudonodeId $pseudonodenumber \
        -NeighborSystemId $systemid \
        -Active "FALSE" ]
    set hNbrTeParams [stc::get $hIsisLspNeighborConfig -children-TeParams] 
    stc::config $hNbrTeParams -TeGroup 1
    lappend m_topRouterConfig($routername) -hIsisLspNeighborConfig  
    lappend m_topRouterConfig($routername) $hIsisLspNeighborConfig     

    #Create neighbor LSP object and ISIS router neighbor object
    #Check whether systemId of ISIS router neighbor exists in current LSP
    set hIsisLsp "" 
    set hIsisLspList [stc::get $m_hIsisRouterConfig -children-isislspconfig]   
    foreach sr $hIsisLspList {
        set SysId [stc::get $sr -systemid]
        if {$SysId == $systemid } {
            set hIsisLsp $sr
        }
    }
    if {$hIsisLsp == "" } {           
        set hNbrIsisLspConfig [stc::create IsisLspConfig \
            -under $m_hIsisRouterConfig \
            -Level $level \
            -SystemId $systemid \
            -NeighborPseudonodeId $pseudonodenumber \
            -Att $flagattachedbit \
            -Ol $flagoverloadbit  \
            -Name $routername \
            -Active "FALSE"]   
    } 
    lappend m_topRouterConfig($routername) -hNbrIsisLspConfig        
    lappend m_topRouterConfig($routername) $hNbrIsisLspConfig 

    set hNbrIsisLspNeighborConfig [stc::create IsisLspNeighborConfig \
        -under $hNbrIsisLspConfig \
        -NeighborPseudonodeId $pseudonodenumber \
        -NeighborSystemId $DefaultSystemId \
        -Active "FALSE"   ]    
    lappend m_topRouterConfig($routername) -hNbrIsisLspNeighborConfig        
    lappend m_topRouterConfig($routername) $hNbrIsisLspNeighborConfig  
     
    #Deliver configuration command and check
    ApplyValidationCheck
         
    debugPut "exit the proc of IsisSession::IsisCreateTopRouter"    
    return $::mainDefine::gSuccess       
}


############################################################################
#APIName: IsisSetTopRouter
#
#Description: Configure an ISIS router in the test topology
#
#Input:    (1) -RouterName Mandatory parameters, name identification of ISIS Router, each ISIS's neighbour is unique  
#            (2) -SystemId  Optional parameters
#            (4) -PseudonodeNumber  Optional parameters
#            (5) -RoutingLevel   Optional parameters 
#            (6) -FlagTe  Optional parameters
#            (7) -FlagTag  Optional parameters  
#            (8) -MaxPacketSize  Optional parameters
#            (9) -FlagAdvetisted  Optional parameters 
#           (10) -AddressFamily  Optional parameters
#           (11) -FlagAttachedBit  Optional parameters  
#           (12) -FlagOverLoadBit  Optional parameters
#           (13) -AreaId   Optional parameters       
#           (14) -AreaIdList   Optional parameters
#           (15) -LinkNum   Optional parameters
#           (16) -RoutingLevel  Optional parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetTopRouter {args} {
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of IsisSession::IsisSetTopRouter"

    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify Routername for IsisSession::ConfigTopRouter"
    }
    
    set index [lsearch $m_routerNameList $routername]
    if {$index == -1} {
       error "$routername is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    } 
     
    set index [lsearch $args -systemid]
    if {$index != -1} {
       set systemid [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -systemid]
        set systemid [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    }     

    set index [lsearch $args -pseudonodenumber]
    if {$index != -1} {
       set pseudonodenumber [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -pseudonodenumber]
        set pseudonodenumber [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    }
       
    set index [lsearch $args -routinglevel]
    if {$index != -1} {
       set routinglevel [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -routinglevel]
        set routinglevel [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    } 

    set index [lsearch $args -flagattachedbit]
    if {$index != -1} {
       set flagattachedbit [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -flagattachedbit]
        set flagattachedbit [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    } 

    set index [lsearch $args -flagoverloadbit]
    if {$index != -1} {
       set flagoverloadbit [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -flagoverloadbit]
        set flagoverloadbit [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    } 
 
     set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterConfig($routername) -flagte]
        set flagte [lindex $m_topRouterConfig($routername) [expr $index + 1] ]
    }
    
     switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
#        l1/l2 {
#            set level "LEVEL1_AND_2"        
#        }                   
#        L1/L2 {
#            set level "LEVEL1_AND_2"        
#        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1 or L2"
        }
    }       
        
    #Get handles of Router LSP object
    set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
    if {$index != -1} {
       set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    }   

    set index [lsearch $m_topRouterConfig($routername) -hIsisLspNeighborConfig]
    if {$index != -1} {
       set hIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    }   
        
    set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspConfig]
    if {$index != -1} {
       set hNbrIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    }    
 
    set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspNeighborConfig]
    if {$index != -1} {
       set hNbrIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    }  
    
    #Configure object of neighbor under the object of ISIS Router LSP
    stc::config $hIsisLspNeighborConfig \
        -NeighborPseudonodeId $pseudonodenumber \
        -NeighborSystemId $systemid 
    set hNbrTeParams [stc::get $hIsisLspNeighborConfig -children-TeParams] 
    stc::config $hNbrTeParams \
        -TeGroup 1  

    # neighbor LSP and ISIS router neighbor
    stc::config $hNbrIsisLspConfig \
        -SystemId $systemid \
        -NeighborPseudonodeId $pseudonodenumber \
        -Att $flagattachedbit \
        -Ol $flagoverloadbit \
        -Name $routername 

    stc::config $hNbrIsisLspNeighborConfig \
        -NeighborPseudonodeId $pseudonodenumber \
        -NeighborSystemId [stc::get $hIsisLspConfig -SystemId]      
    
    #Deliver configuration command and check
    ApplyValidationCheck
                 
    debugPut "exit the proc of IsisSession::IsisSetTopRouter" 
    return $::mainDefine::gSuccess          
}


############################################################################
#APIName: IsisDeleteTopRouter
#
#Description: Delete an ISIS router in the test topology
#
#Input:    (1) -RouterName  Mandatory parameters, Name identification of ISIS Router, each ISIS's neighbour is unique         
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDeleteTopRouter {args} { 
    #Convert input parameters to lowercase parameters  
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of IsisSession::IsisDeleteTopRouter"
    
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify RouterName for IsisSession::IsisDeleteTopRouter"
    }  
    
    set index [lsearch $m_routerNameList $routername]
    if {$index == -1} {
        error "$RouterName is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    } else {    
        #Delete designated objects from the list     
        set m_routerNameList [lreplace $m_routerNameList $index $index]        
    }

    #Get relevant handles
    set index [lsearch $m_topRouterConfig($routername) -hIsisLspNeighborConfig]
    if {$index != -1} {
       set hIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    } 

    set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspConfig]
    if {$index != -1} {
       set hNbrIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    }    
    
    
    #Delete  object handles of the Neighbor LSP
    stc::delete $hIsisLspNeighborConfig 
    stc::delete $hNbrIsisLspConfig 
    catch {unset m_topRouterConfig($routername) }  

    #Deliver configuration command and check
    ApplyValidationCheck
                         
    debugPut "exit the proc of IsisSession::IsisDeleteTopRouter"    
    return $::mainDefine::gSuccess       
}


############################################################################
#APIName: IsisCreateTopRouterLink
#
#Description: Create link for designated ISIS Router
#
#Input:    
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisCreateTopRouterLink {args} {   
    #Convert input parameters to lowercase parameters 
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisCreateTopRouterLink"

    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify LinkName for IsisSession::IsisCreateTopRouterLink"
    } 

    set index [lsearch $m_linkNameList $linkname]
    if {$index != -1} {
        error "The LinkName($linkname) already existed, please specify another one, the existed LinkName(s) is(are) as following:\n$m_linkNameList"
    } else {
        lappend m_linkNameList $linkname
    }      
        
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
       error "please specify RouterName for IsisSession::IsisCreateTopRouterLink"
    } 
    
    set index [lsearch $m_routerNameList $routername]
    if {$index == -1} {
        error "$routername does not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    } 
    lappend m_topRouterLinkConfig($linkname) -routername        
    lappend m_topRouterLinkConfig($linkname) $routername   
              
    set index [lsearch $args -connectedname]
    if {$index != -1} {
       set connectedname [lindex $args [expr $index + 1]]
    } else {
       error "please specify ConnectedName for IsisSession::IsisCreateTopRouterLink"
    }
    
    set index [lsearch $m_routerNameList $connectedname]
    if {$index == -1} {
        error "$connectedname is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    }        
    lappend m_topRouterLinkConfig($linkname) -connectedname        
    lappend m_topRouterLinkConfig($linkname) $connectedname   
        
    set index [lsearch $args -narrowmetric]
    if {$index != -1} {
       set narrowmetric [lindex $args [expr $index + 1]]
    } else {
       set narrowmetric 1
    }         
    lappend m_topRouterLinkConfig($linkname) -narrowmetric        
    lappend m_topRouterLinkConfig($linkname) $narrowmetric 
        
    set index [lsearch $args -widemetric]
    if {$index != -1} {
       set widemetric [lindex $args [expr $index + 1]]
    } else {
       set widemetric 1
    } 
    lappend m_topRouterLinkConfig($linkname) -widemetric        
    lappend m_topRouterLinkConfig($linkname) $widemetric 
        
    set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
       set flagte false
    }                    
    lappend m_topRouterLinkConfig($linkname) -flagte        
    lappend m_topRouterLinkConfig($linkname) $flagte 
          
    #Get relevant handles of IsisRouter and NbrRouter  
    set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
    if {$index != -1} {
       set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    } 
 
    set index [lsearch $m_topRouterConfig($connectedname) -hIsisLspConfig]
    if {$index != -1} {
       set hNbrIsisLspConfig [lindex $m_topRouterConfig($connectedname) [expr $index + 1]]
    } 

    set index [lsearch $m_topRouterConfig($routername) -systemid]
    if {$index != -1} {
       set RtrSystemid [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    } 
 
    set index [lsearch $m_topRouterConfig($connectedname) -systemid]
    if {$index != -1} {
       set NbrRtrSystemid [lindex $m_topRouterConfig($connectedname) [expr $index + 1]]
    } 

    #Configure Neighbor
    set IsisLspNbrhandle [stc::create IsisLspNeighborConfig \
        -under $hIsisLspConfig \
        -NeighborSystemId $NbrRtrSystemid \
        -WideMetric $widemetric \
        -Metric $narrowmetric \
        -Active "FALSE"] 
    lappend m_topRouterLinkConfig($linkname) -IsisLspNbrhandle        
    lappend m_topRouterLinkConfig($linkname) $IsisLspNbrhandle   
    
    set NbrLspNbrHandle [stc::create IsisLspNeighborConfig \
        -under $hNbrIsisLspConfig \
        -NeighborSystemId $RtrSystemid \
        -WideMetric $widemetric \
        -Metric $narrowmetric \
        -Active "FALSE" ] 
    lappend m_topRouterLinkConfig($linkname) -NbrLspNbrHandle        
    lappend m_topRouterLinkConfig($linkname) $NbrLspNbrHandle             
    
    #Deliver configured command and check
    ApplyValidationCheck
          
    debugPut "exit the proc of IsisSession::IsisCreateTopRouterLink" 
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: IsisSetTopRouterLink
#
#Description: Configure the ISIS link which has been created
#
#Input:    (1) -LinkName  mandatory parameter,link name
#            (2) -RouterName   mandatory parameter       
#            (3) -ConnectedName   mandatory parameter    
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetTopRouterLink {args} {    
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisSetTopRouterLink"

    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify LinkName for IsisSession::ConfigTopRouterLink"
    } 
    
    set index [lsearch $m_linkNameList $linkname]
    if {$index == -1} {
        error "$RouterName is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    }
    
    set index [lsearch $args -routername]
    if {$index != -1} {
       set routername [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterLinkConfig($linkname) -routername]
        set routername [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1] ]     
    } 

    set index [lsearch $m_routerNameList $routername]
    if {$index == -1} {
        error "$RouterName is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    } 
           
    set index [lsearch $args -connectedname]
    if {$index != -1} {
       set connectedname [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterLinkConfig($linkname) -connectedname]
        set connectedname [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1] ]     
    }
    
    set index [lsearch $m_routerNameList $connectedname]
    if {$index == -1} {
        error "$connectedname is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    }        
    
    set index [lsearch $args -narrowmetric]
    if {$index != -1} {
       set narrowmetric [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterLinkConfig($linkname) -narrowmetric]
        set narrowmetric [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1] ]  
    }         
    
    set index [lsearch $args -widemetric]
    if {$index != -1} {
       set widemetric [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterLinkConfig($linkname) -widemetric]
        set widemetric [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1] ]  
    } 
    
    set index [lsearch $args -flagte]
    if {$index != -1} {
       set flagte [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_topRouterLinkConfig($linkname) -flagte]
        set flagte [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1] ]  
    }              
    
    #Get relevant handles of IsisRouterand NbrRouter 
    set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
    if {$index != -1} {
       set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    } 
 
    set index [lsearch $m_topRouterConfig($connectedname) -hIsisLspConfig]
    if {$index != -1} {
       set hNbrIsisLspConfig [lindex $m_topRouterConfig($connectedname) [expr $index + 1]]
    } 

    set index [lsearch $m_topRouterConfig($routername) -systemid]
    if {$index != -1} {
       set RtrSystemid [lindex $m_topRouterConfig($routername) [expr $index + 1]]
    } 
 
    set index [lsearch $m_topRouterConfig($connectedname) -systemid]
    if {$index != -1} {
       set NbrRtrSystemid [lindex $m_topRouterConfig($connectedname) [expr $index + 1]]
    } 
    
    set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
    if {$index != -1} {
       set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
    }    

    set index [lsearch $m_topRouterLinkConfig($linkname) -NbrLspNbrHandle]
    if {$index != -1} {
       set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
    }  

    #Configure Neighbor
    stc::config $IsisLspNbrhandle \
        -NeighborSystemId $NbrRtrSystemid \
        -WideMetric $widemetric \
        -Metric $narrowmetric 

    stc::config $NbrLspNbrHandle \
        -NeighborSystemId $RtrSystemid \
        -WideMetric $widemetric \
        -Metric $narrowmetric    
    
    #Deliver configuration command and check
    ApplyValidationCheck
 
          
    debugPut "exit the proc of IsisSession::IsisSetTopRouterLink"  
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: IsisDeleteTopRouterLink
#
#Description: 
#
#Input:       
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDeleteTopRouterLink {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisDeleteTopRouterLink"

    set index [lsearch $args -linkname]
    if {$index != -1} {
       set linkname [lindex $args [expr $index + 1]]
    } else {
       error "please specify LinkName for IsisSession::IsisDeleteTopRouterLink"
    } 
    
    set index [lsearch $m_linkNameList $linkname]
    if {$index == -1} {
        error "$RouterName is not exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
    } else {
    set m_linkNameList [lreplace $m_linkNameList $index $index]
    }  

    set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
    if {$index != -1} {
       set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
    }    
    
    set index [lsearch $m_topRouterLinkConfig($linkname) -NbrLspNbrHandle]
    if {$index != -1} {
       set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
    }  
    
    #Delete neighbor object
    stc::delete $IsisLspNbrhandle
    stc::delete $NbrLspNbrHandle
    unset m_topRouterLinkConfig($linkname)          

    #Deliver configuration command and check  
    ApplyValidationCheck
        
    debugPut "exit the proc of IsisSession::IsisDeleteTopRouterLink" 
    return $::mainDefine::gSuccess         
}



############################################################################
#APIName: IsisCreateTopNetwork
#
#Description: 
#
#Input:    (1) -NetworkName  Mandatory parameters
#            (2) -AddressFamily  Optional parameters
#            (2) -FirstAddress  Optional parameters
#            (3) -NumAddress  Optional parameters
#            (4) -Modifier Optional parameters
#            (5) -Prefixlen  Optional parameters
#            (6) -ConnectedRouterIDList  Optional parameters
#            (7) -ConnectedSysID  Optional parameters           
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisCreateTopNetwork {args} {   
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisCreateTopNetwork"
    
    set index [lsearch $args -networkname] 
    if {$index != -1} {
        set networkname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the NetworkName of IsisSession::IsisCreateTopNetwork"
    } 
    
    set index [lsearch $m_topNetworkList $networkname] 
    if {$index != -1} {
        error "$networkname already exist, the existed NetworkName(s) is(are) as following:\n$m_topNetworkList"
    }    
    lappend m_topNetworkList $networkname 

    set index [lsearch $args -connectedsysid] 
    if {$index != -1} {
        set connectedsysid [lindex $args [expr $index + 1]]
    } else  {
        set connectedsysid $m_systemid
    } 
    lappend m_isisNetworkConfig($networkname) -connectedsysid  
    lappend m_isisNetworkConfig($networkname) $connectedsysid        
         
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set addressfamily [lindex $args [expr $index + 1]]
    } else  {
        set addressfamily "IPV4"
    }    
    lappend m_isisNetworkConfig($networkname) -addressfamily  
    lappend m_isisNetworkConfig($networkname) $addressfamily   
       
    set index [lsearch $args -firstaddress] 
    if {$index != -1} {
        set firstaddress [lindex $args [expr $index + 1]]
    } else  {
        set firstaddress "101.201.1.0"
    }    
    lappend m_isisNetworkConfig($networkname) -firstaddress  
    lappend m_isisNetworkConfig($networkname) $firstaddress   
        
    set index [lsearch $args -numaddress] 
    if {$index != -1} {
        set numaddress [lindex $args [expr $index + 1]]
    } else  {
        set numaddress 1
    }    
    lappend m_isisNetworkConfig($networkname) -numaddress  
    lappend m_isisNetworkConfig($networkname) $numaddress   
        
    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set modifier [lindex $args [expr $index + 1]]
    } else  {
        set modifier "1"
    }    
    lappend m_isisNetworkConfig($networkname) -modifier  
    lappend m_isisNetworkConfig($networkname) $modifier   
    
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set prefixlen [lindex $args [expr $index + 1]]
    } else  {
        set prefixlen 24
    }   
    lappend m_isisNetworkConfig($networkname) -prefixlen  
    lappend m_isisNetworkConfig($networkname) $prefixlen   
    
    set addressfamily [string tolower $addressfamily] 
    #Make conversion of parameter keywords
    switch $addressfamily {
        ipv4 {
            set ipversion "IPV4"       
        }
        ipv6 {
            set ipversion "IPV6"        
        }       
        both {
            set ipversion "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified AddressFamily is invaild"
        }
    }
       
    #Make Legitimacy judgment of connectedsysid
    set hIsisRouterConfigList [stc::get $m_hRouter -children-isisrouterconfig]
    set hIsisLspConfig "" 
    foreach sr $hIsisRouterConfigList {
        set hIsisLspConfigList [stc::get $sr -children-isislspconfig]
        foreach hLsp $hIsisLspConfigList {
            if {[stc::get $hLsp -systemid]== $connectedsysid } {
                set hIsisLspConfig $hLsp
            }             
         }  
    }
    if {$hIsisLspConfig == ""} {
        error "Specified connectedsysid $connectedsysid does not match with any existed Isis Router"
    }
    
    switch $ipversion {
        IPV4 {
            set hIpv4IsisRoutesConfig [stc::create "Ipv4IsisRoutesConfig" -under $hIsisLspConfig ]
            set hIpv4NetworkBlock [lindex [stc::get $hIpv4IsisRoutesConfig -children-Ipv4NetworkBlock] 0]
            stc::config $hIpv4NetworkBlock \
                -StartIpList $firstaddress \
                -PrefixLength $prefixlen \
                -NetworkCount $numaddress \
                -AddrIncrement $modifier  
            lappend m_isisNetworkConfig($networkname) -IsisRoutesConfig  
            lappend m_isisNetworkConfig($networkname) $hIpv4IsisRoutesConfig
            set ::mainDefine::gPoolCfgBlock($networkname) $hIpv4NetworkBlock
        }
        IPV6 {
            set hIpv6IsisRoutesConfig [stc::create "Ipv6IsisRoutesConfig" -under $hIsisLspConfig ] 
            set hIpv6NetworkBlock [lindex [stc::get $hIpv6IsisRoutesConfig -children-Ipv6NetworkBlock] 0]
            stc::config $hIpv6NetworkBlock \
                -StartIpList $firstaddress \
                -PrefixLength $prefixlen \
                -NetworkCount $numaddress \
                -AddrIncrement $modifier   
            lappend m_isisNetworkConfig($networkname) -IsisRoutesConfig  
            lappend m_isisNetworkConfig($networkname) $hIpv6IsisRoutesConfig    
            set ::mainDefine::gPoolCfgBlock($networkname) $hIpv6NetworkBlock
        }
    }  
          
    #Deliver configuration command and check
    ApplyValidationCheck
            
    debugPut "exit the proc of IsisSession::IsisCreateTopNetwork" 
    return $::mainDefine::gSuccess         
}



############################################################################
#APIName: IsisSetTopNetwork
#
#Description: 
#
#Input:    (1) -NetworkName Mandatory parameters
#            (2) -AddressFamily Optional parameters  
#            (2) -FirstAddress Optional parameters
#            (3) -NumAddress Optional parameters
#            (4) -Modifier Optional parameters
#            (5) -Prefixlen Optional parameters
#            (6) -ConnectedRouterID Optional parameters
#            (7) -ConnectedSysID Optional parameters          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetTopNetwork {args} {   
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of IsisSession::IsisSetTopNetwork"
    set index [lsearch $args -networkname] 
    if {$index != -1} {
        set networkname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the NetworkName of IsisSession::IsisSetTopNetwork"
    } 
 
    set index [lsearch $m_topNetworkList $networkname] 
    if {$index == -1} {
        error "$networkname is not exist, the existed NetworkName(s) is(are) as following:\n$m_topNetworkList"
    }   
     
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set addressfamily [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -addressfamily]
        set addressfamily [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }    
    
    set index [lsearch $args -firstaddress] 
    if {$index != -1} {
        set firstaddress [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -firstaddress]
        set firstaddress [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }    
    
    set index [lsearch $args -numaddress] 
    if {$index != -1} {
        set numaddress [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -numaddress]
        set numaddress [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }    
    
    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set modifier [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -modifier]
        set modifier [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }    

    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set prefixlen [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -prefixlen]
        set prefixlen [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }
       
    set index [lsearch $args -connectedsysid] 
    if {$index != -1} {
        set connectedsysid [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisNetworkConfig($networkname) -connectedsysid]
        set connectedsysid [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    }    

    set addressfamily [string tolower $addressfamily] 
    #Make conversion of parameter keywords
    switch $addressfamily {
        ipv4 {
            set ipversion "IPV4"       
        }
        ipv6 {
            set ipversion "IPV6"        
        }       
        both {
            set ipversion "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified AddressFamily is invaild"
        }
    }
    
    set index [lsearch $m_isisNetworkConfig($networkname) -IsisRoutesConfig]
    set IsisRoutesConfig [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]        
    
    switch $ipversion {
        IPV4 {
            set hIpv4NetworkBlock [lindex [stc::get $IsisRoutesConfig -children-Ipv4NetworkBlock] 0]
            stc::config $hIpv4NetworkBlock \
                -StartIpList $firstaddress \
                -PrefixLength $prefixlen \
                -NetworkCount $numaddress \
                -AddrIncrement $modifier  
        }
        IPV6 {
            set hIpv6NetworkBlock [lindex [stc::get $IsisRoutesConfig -children-Ipv6NetworkBlock] 0]
            stc::config $hIpv6NetworkBlock \
                -StartIpList $firstaddress \
                -PrefixLength $prefixlen \
                -NetworkCount $numaddress \
                -AddrIncrement $modifier                                                         
        }
    }     
        
    #Deliver configuration command and check  
    ApplyValidationCheck
          
    debugPut "exit the proc of IsisSession::IsisSetTopNetwork"  
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: IsisDeleteTopNetwork
#
#Description: 
#
#Input:    (1) -NetworkName  Mandatory parameters   
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDeleteTopNetwork {args} {
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]       
    debugPut "enter the proc of IsisSession::IsisDeleteTopNetwork"
    
    set index [lsearch $args -networkname] 
    if {$index != -1} {
        set networkname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the NetworkName of IsisSession::IsisDeleteTopNetwork"
    }    
         
    set index [lsearch $m_topNetworkList $networkname] 
    if {$index == -1} {
        error "$networkname is not exist, the existed NetworkName(s) is(are) as following:\n$m_topNetworkList"
    } else {
        set m_topNetworkList [lreplace $m_topNetworkList $index $index]    
    }   

    #Delete relevant objects
    set index [lsearch $m_isisNetworkConfig($networkname) -IsisRoutesConfig]
    set IsisRoutesConfig [lindex $m_isisNetworkConfig($networkname) [expr $index + 1] ]
    stc::delete $IsisRoutesConfig
    
    catch {unset m_isisNetworkConfig($networkname)}

    #Deliver configuration command and check 
    ApplyValidationCheck
                     
    debugPut "exit the proc of IsisSession::IsisDeleteTopNetwork"  
    return $::mainDefine::gSuccess         
}


############################################################################
#APIName: IsisCreateRouteBlock
#
#Description: Create ISIS route block
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisCreateRouteBlock {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of IsisSession::IsisCreateRouteBlock"
    
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the BlockName of IsisSession::IsisCreateRouteBlock"
    } 

 
    set index [lsearch $m_lspBlockNameList $blockname]
    if {$index != -1} {
        error "The BlockName($blockname) already existed,please specify another one, the existed BlockName(s) is(are) as following:\n$m_lspBlockNameList"
    } else {
        lappend m_lspBlockNameList $blockname
    } 
        
    set index [lsearch $args -systemid] 
    if {$index != -1} {
        set systemid [lindex $args [expr $index + 1]]
    } else  {
        set systemid "00:10:94:00:00:02"
    }
    lappend m_isisRouteBlockConfig($blockname) -systemid  
    lappend m_isisRouteBlockConfig($blockname) $systemid

    set index [lsearch $args -routinglevel] 
    if {$index != -1} {
        set routinglevel [lindex $args [expr $index + 1]]
    } else  {
        set routinglevel "L2"
    } 
    lappend m_isisRouteBlockConfig($blockname) -routinglevel  
    lappend m_isisRouteBlockConfig($blockname) $routinglevel 
        
    set index [lsearch $args -routepooltype] 
    if {$index != -1} {
        set routepooltype [lindex $args [expr $index + 1]]
    } else  {
        set routepooltype "IPV4"
    }

   set routepooltype [string tolower $routepooltype] 
    #Make conversion of parameters keywords
    switch $routepooltype {
        ipv4 {
            set routepooltype "IPV4"       
        }
        ipv6 {
            set routepooltype "IPV6"        
        }       
        both {
            set routepooltype "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified routepooltype is invaild"
        }
    }     
    lappend m_isisRouteBlockConfig($blockname) -routepooltype  
    lappend m_isisRouteBlockConfig($blockname) $routepooltype 

    set index [lsearch $args -routetype] 
    if {$index != -1} {
        set routetype [lindex $args [expr $index + 1]]
    } else  {
        set routetype "INTERNAL"
    } 
    lappend m_isisRouteBlockConfig($blockname) -routetype  
    lappend m_isisRouteBlockConfig($blockname) $routetype 

    set index [lsearch $args -metrictype] 
    if {$index != -1} {
        set metrictype [lindex $args [expr $index + 1]]
    } else  {
        set metrictype "INTERNAL"
    }     
    lappend m_isisRouteBlockConfig($blockname) -metrictype  
    lappend m_isisRouteBlockConfig($blockname) $metrictype    
    
    set index [lsearch $args -firstaddress] 
    if {$index != -1} {
        set firstaddress [lindex $args [expr $index + 1]]
    } else  {
        set firstaddress 10.10.10.1
    }
    #判断输入路由是否是列表形式 add by Andy
    if {[llength $firstaddress]>1} {
        set m_firstAddressListFlag TRUE
    } else {
        set m_firstAddressListFlag FALSE
    }
    
    lappend m_isisRouteBlockConfig($blockname) -firstaddress  
    lappend m_isisRouteBlockConfig($blockname) $firstaddress    
              
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set prefixlen [lindex $args [expr $index + 1]]
    } else  {
        if {$routepooltype == "IPV4"} {
            set prefixlen 24
        } else {
            set prefixlen 64
        }
    } 
    lappend m_isisRouteBlockConfig($blockname) -prefixlen  
    lappend m_isisRouteBlockConfig($blockname) $prefixlen 
  
    set index [lsearch $args -numaddress] 
    if {$index != -1} {
        set numaddress [lindex $args [expr $index + 1]]
    } else  {
        set numaddress 10
    } 
    lappend m_isisRouteBlockConfig($blockname) -numaddress  
    lappend m_isisRouteBlockConfig($blockname) $numaddress     

    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set modifier [lindex $args [expr $index + 1]]
    } else  {
        set modifier 1
    }  
    lappend m_isisRouteBlockConfig($blockname) -modifier  
    lappend m_isisRouteBlockConfig($blockname) $modifier 
        
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set flagflap [lindex $args [expr $index + 1]]
    } else  {
        set flagflap TRUE
    }  
    set m_FlagFlapList($blockname)  $flagflap 
    lappend m_isisRouteBlockConfig($blockname) -flagflap  
    lappend m_isisRouteBlockConfig($blockname) $flagflap  

    set index [lsearch $args -flagtag]
    if {$index != -1} {
       set flagtag [lindex $args [expr $index + 1]]
    } else {
       set flagtag ""
    }        
    lappend m_isisRouteBlockConfig($blockname) -flagtag  
    lappend m_isisRouteBlockConfig($blockname) $flagtag  

    set index [lsearch $args -metric]
    if {$index != -1} {
       set metric [lindex $args [expr $index + 1]]
    } else {
       set metric "1"
    }        
    lappend m_isisRouteBlockConfig($blockname) -metric  
    lappend m_isisRouteBlockConfig($blockname) $metric
            
    set index [lsearch $args -active] 
    if {$index != -1} {
        set active [lindex $args [expr $index + 1]]
    } else  {
        set active TRUE
    }  
    lappend m_isisRouteBlockConfig($blockname) -active  
    lappend m_isisRouteBlockConfig($blockname) $active 

     switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
        l1/l2 {
            set level "LEVEL1_AND_2"        
        }                   
        L1/L2 {
            set level "LEVEL1_AND_2"        
        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1,L2,L1/L2"
        }
    }       
    
    #Configure parameters of IsisLspConfig object 
    set stc_level [stc::get $m_hIsisRouterConfig -level]
    #if {$level != $stc_level} {
        #error "The specified RoutingLevel of TopRouter must equal to the IsisRouter level: $stc_level"  
    #}
    
    #Check whether there is a designated systemid in current LSP
    set hIsisLsp "" 
    set hIsisLspList [stc::get $m_hIsisRouterConfig -children-isislspconfig]   
    foreach sr $hIsisLspList {
        set SysId [stc::get $sr -systemid]
        if {$SysId == $systemid } {
            set hIsisLsp $sr
        }
    }
    if {$level != "LEVEL1_AND_2"} {
        if {$hIsisLsp == "" } {           
           set hIsisLsp [stc::create IsisLspConfig \
               -under $m_hIsisRouterConfig \
               -Level $level \
               -SystemId $systemid \
               -NeighborPseudonodeId "0" \
               -Lifetime "1200" \
               -SeqNum "1" \
               -Att "FALSE" \
               -Ol "FALSE" \
               -CheckSum "GOOD" \
               -TeRouterId "null" \
               -Active $active]
           lappend m_isisRouteBlockConfig($blockname) -hIsisLspConfig  
           lappend m_isisRouteBlockConfig($blockname) $hIsisLsp  
       } else {
           stc::config $hIsisLsp \
               -Level $level \
               -SystemId $systemid \
               -NeighborPseudonodeId "0" \
               -Active $active
           lappend m_isisRouteBlockConfig($blockname) -hIsisLspConfig  
           lappend m_isisRouteBlockConfig($blockname) $hIsisLsp              
       }
       
       switch $routepooltype {
           IPV4 {
               set hIpv4IsisRoutesConfig [stc::create "Ipv4IsisRoutesConfig" \
                   -under $hIsisLsp \
                   -MetricType $metrictype \
                   -Metric $metric \
                   -AdminTag $flagtag \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ]
               set hIpv4NetworkBlock [lindex [stc::get $hIpv4IsisRoutesConfig -children-Ipv4NetworkBlock] 0]
               # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
               } else {
                   stc::config $hIpv4NetworkBlock \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
               }
               lappend m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig         
               lappend m_isisRouteBlockConfig($blockname) $hIpv4IsisRoutesConfig
               
  
               set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock  
                     
           }
           IPV6 {
               set hIpv6IsisRoutesConfig [stc::create "Ipv6IsisRoutesConfig" \
                   -under $hIsisLsp \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ] 
              set hIpv6NetworkBlock [lindex [stc::get $hIpv6IsisRoutesConfig -children-Ipv6NetworkBlock] 0]
              # 判断输入路由是否是列表形式  add by Andy
              if {$m_firstAddressListFlag=="TRUE" } {
                  stc::config $hIpv6NetworkBlock \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount 1 \
                       -AddrIncrement 1
              } else {
                  stc::config $hIpv6NetworkBlock \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier
              }
              lappend m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig
              lappend m_isisRouteBlockConfig($blockname) $hIpv6IsisRoutesConfig
              
       
              set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock 
                     
           }
           default {
               error "Specified RoutePoolType is invalid"
           }
       }     
    } else {          
        set hIsisLsp1 [stc::create IsisLspConfig \
            -under $m_hIsisRouterConfig \
            -Level "LEVEL1" \
            -SystemId $systemid \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active $active]
        set hIsisLsp2 [stc::create IsisLspConfig \
            -under $m_hIsisRouterConfig \
            -Level "LEVEL2" \
            -SystemId $systemid \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active $active]               
        lappend m_isisRouteBlockConfig($blockname) -hIsisLspConfig  
        lappend m_isisRouteBlockConfig($blockname) "$hIsisLsp1 $hIsisLsp2"  

        switch $routepooltype {
           IPV4 {
               set hIpv4IsisRoutesConfig1 [stc::create "Ipv4IsisRoutesConfig" \
                   -under $hIsisLsp1 \
                   -MetricType $metrictype \
                   -Metric $metric \
                   -AdminTag $flagtag \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ]
              set hIpv4NetworkBlock1 [lindex [stc::get $hIpv4IsisRoutesConfig1 -children-Ipv4NetworkBlock] 0]
              #绑定到流
               set ::mainDefine::gPoolCfgBlock($blockname) $hIpv4NetworkBlock1
              # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock1 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
               } else {
                   stc::config $hIpv4NetworkBlock1 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
               }     
               set hIpv4IsisRoutesConfig2 [stc::create "Ipv4IsisRoutesConfig" \
                   -under $hIsisLsp2 \
                   -MetricType $metrictype \
                   -Metric $metric \
                   -AdminTag $flagtag \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ]
              set hIpv4NetworkBlock2 [lindex [stc::get $hIpv4IsisRoutesConfig2 -children-Ipv4NetworkBlock] 0]
              # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock2 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
               } else {
                   stc::config $hIpv4NetworkBlock2 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
               }                      
               lappend m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig         
               lappend m_isisRouteBlockConfig($blockname) "$hIpv4IsisRoutesConfig1 $hIpv4IsisRoutesConfig2" 
           }
           IPV6 {
               set hIpv6IsisRoutesConfig1 [stc::create "Ipv6IsisRoutesConfig" \
                   -under $hIsisLsp1 \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ] 
              set hIpv6NetworkBlock1 [lindex [stc::get $hIpv6IsisRoutesConfig1 -children-Ipv6NetworkBlock] 0]
              #绑定到流
              set ::mainDefine::gPoolCfgBlock($blockname) $hIpv6NetworkBlock1
              # 判断输入路由是否是列表形式  add by Andy
              if {$m_firstAddressListFlag=="TRUE" } {
                  stc::config $hIpv6NetworkBlock1 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount 1 \
                       -AddrIncrement 1
              } else {
                  stc::config $hIpv6NetworkBlock1 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier
              }
               set hIpv6IsisRoutesConfig2 [stc::create "Ipv6IsisRoutesConfig" \
                   -under $hIsisLsp2 \
                   -RouteType $routetype \
                   -WideMetric "1" \
                   -UpDown "0" \
                   -RouteCategory "UNDEFINED" \
                   -Active "TRUE" \
                   -Name $blockname ] 
              set hIpv6NetworkBlock2 [lindex [stc::get $hIpv6IsisRoutesConfig2 -children-Ipv6NetworkBlock] 0]
              # 判断输入路由是否是列表形式  add by Andy
              if {$m_firstAddressListFlag=="TRUE" } {
                  stc::config $hIpv6NetworkBlock2 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount 1 \
                       -AddrIncrement 1
              } else {
                  stc::config $hIpv6NetworkBlock2 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier
              }                                          
             lappend m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig
             lappend m_isisRouteBlockConfig($blockname) "$hIpv6IsisRoutesConfig1 $hIpv6IsisRoutesConfig2"
                     
           }
           default {
               error "Specified RoutePoolType is invalid"
           }
       }       
    
    };# end if

    
    #Deliver configuration command and check 
    ApplyValidationCheck
      
    debugPut "exit the proc of IsisSession::IsisCreateRouteBlock"
    return $::mainDefine::gSuccess    
}


############################################################################
#APIName: IsisSetRouteBlock
#
#Description: Configure parameters of route block
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetRouteBlock {args} {
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisSetRouteBlock"
    
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the BlockName of IsisSession::IsisSetRouteBlock"
    } 
    
    #Check whether the corresponding object of blockname exists
    set index [lsearch $m_lspBlockNameList $blockname]
    if {$index == -1} {
        error "BlockName($blockname) not existed, the existed BlockName(s) is(are) as following:\n$m_lspBlockNameList"
    }      
    
    set index [lsearch $args -systemid] 
    if {$index != -1} {
        set systemid [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -systemid]
        set systemid [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]         
    }

    set index [lsearch $args -routinglevel] 
    if {$index != -1} {
        set routinglevel [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -routinglevel]
        set routinglevel [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]  
    } 
        
    set index [lsearch $args -routepooltype] 
    if {$index != -1} {
        set routepooltype [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -routepooltype]
        set routepooltype [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ] 
    } 

    set index [lsearch $args -routetype] 
    if {$index != -1} {
        set routetype [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -routetype]
        set routetype [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    } 

    set index [lsearch $args -metrictype] 
    if {$index != -1} {
        set metrictype [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -metrictype]
        set metrictype [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }  

    set index [lsearch $args -metric] 
    if {$index != -1} {
        set metric [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -metric]
        set metric [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }        
    
    set index [lsearch $args -firstaddress] 
    if {$index != -1} {
        set firstaddress [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -firstaddress]
        set firstaddress [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }   

     #判断输入路由是否是列表形式 add by Andy
    if {[llength $firstaddress]>1} {
        set m_firstAddressListFlag TRUE
    } else {
        set m_firstAddressListFlag FALSE
    }
              
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set prefixlen [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -prefixlen]
        set prefixlen [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    } 
  
    set index [lsearch $args -numaddress] 
    if {$index != -1} {
        set numaddress [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -numaddress]
        set numaddress [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }   

    set index [lsearch $args -modifier] 
    if {$index != -1} {
        set modifier [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -modifier]
        set modifier [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }  
        
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set flagflap [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -flagflap]
        set flagflap [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }  

    set index [lsearch $args -flagtag]
    if {$index != -1} {
       set flagtag [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -flagtag]
        set flagtag [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }        
        
    set index [lsearch $args -active] 
    if {$index != -1} {
        set active [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisRouteBlockConfig($blockname) -active]
        set active [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ]
    }  

     switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
#        l1/l2 {
#            set level "LEVEL1_AND_2"        
#        }                   
#        L1/L2 {
#            set level "LEVEL1_AND_2"        
#        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1,L2"
        }
    }       

    #Get handles of IsisLspConfig object according to blockname
    set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisLspConfig]
    set hIsisLspConfig  [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]
    set LspNum [llength $hIsisLspConfig]
    

    if {$LspNum == 2 } {
        set hIsisLspConfig1 [lindex $hIsisLspConfig 0]
        set hIsisLspConfig2 [lindex $hIsisLspConfig 1]    
        stc::config $hIsisLspConfig1 \
            -SystemId $systemid \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active $active
        stc::config $hIsisLspConfig2 \
            -SystemId $systemid \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active $active            
        switch $routepooltype {
            IPV4 {
                set hIpv4IsisRoutesConfig1 [stc::get $hIsisLspConfig1 -children-ipv4isisroutesconfig] 
                stc::config $hIpv4IsisRoutesConfig1 \
                    -MetricType $metrictype \
                    -Metric $metric \
                    -AdminTag $flagtag \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv4NetworkBlock1 [lindex [stc::get $hIpv4IsisRoutesConfig1 -children-Ipv4NetworkBlock] 0]
                #判断输入路由是否是列表形式 add by Andy
                if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock1 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
                } else {
                   stc::config $hIpv4NetworkBlock1 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
                } 
                set hIpv4IsisRoutesConfig2 [stc::get $hIsisLspConfig2 -children-ipv4isisroutesconfig] 
                stc::config $hIpv4IsisRoutesConfig2 \
                    -MetricType $metrictype \
                    -Metric $metric \
                    -AdminTag $flagtag \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv4NetworkBlock2 [lindex [stc::get $hIpv4IsisRoutesConfig2 -children-Ipv4NetworkBlock] 0]
               #判断输入路由是否是列表形式 add by Andy
                if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock2 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
                } else {
                   stc::config $hIpv4NetworkBlock2 \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
                }                          
            }
            IPV6 {
                set hIpv6IsisRoutesConfig1 [stc::get $hIsisLspConfig1 -children-ipv6isisroutesconfig] 
                stc::config $hIpv6IsisRoutesConfig1 \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv6NetworkBlock1 [lindex [stc::get $hIpv6IsisRoutesConfig1 -children-Ipv6NetworkBlock] 0]
               # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv6NetworkBlock1 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1
               } else {
                   stc::config $hIpv6NetworkBlock1 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount $numaddress \
                        -AddrIncrement $modifier
               } 
                set hIpv6IsisRoutesConfig2 [stc::get $hIsisLspConfig2 -children-ipv6isisroutesconfig] 
                stc::config $hIpv6IsisRoutesConfig1 \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv6NetworkBlock2 [lindex [stc::get $hIpv6IsisRoutesConfig2 -children-Ipv6NetworkBlock] 0]
               # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv6NetworkBlock2 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1
               } else {
                   stc::config $hIpv6NetworkBlock2 \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount $numaddress \
                        -AddrIncrement $modifier
               }                                           
            }
            default {
                error "Specified RoutePoolType is invalid"
            }
        }      
    } else {
        stc::config $hIsisLspConfig \
            -Level $level \
            -SystemId $systemid \
            -NeighborPseudonodeId "0" \
            -Lifetime "1200" \
            -SeqNum "1" \
            -Att "FALSE" \
            -Ol "FALSE" \
            -CheckSum "GOOD" \
            -TeRouterId "null" \
            -Active $active
            
        switch $routepooltype {
            IPV4 {
                set hIpv4IsisRoutesConfig [stc::get $hIsisLspConfig -children-ipv4isisroutesconfig] 
                stc::config $hIpv4IsisRoutesConfig \
                    -MetricType $metrictype \
                    -Metric $metric \
                    -AdminTag $flagtag \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv4NetworkBlock [lindex [stc::get $hIpv4IsisRoutesConfig -children-Ipv4NetworkBlock] 0]
               # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv4NetworkBlock \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
               } else {
                   stc::config $hIpv4NetworkBlock \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
               }
            }
            IPV6 {
                set hIpv6IsisRoutesConfig [stc::get $hIsisLspConfig -children-ipv6isisroutesconfig] 
                stc::config $hIpv6IsisRoutesConfig \
                    -RouteType $routetype \
                    -WideMetric "1" \
                    -UpDown "0" \
                    -RouteCategory "UNDEFINED" \
                    -Active "TRUE" 
               set hIpv6NetworkBlock [lindex [stc::get $hIpv6IsisRoutesConfig -children-Ipv6NetworkBlock] 0]
               # 判断输入路由是否是列表形式  add by Andy
               if {$m_firstAddressListFlag=="TRUE" } {
                   stc::config $hIpv6NetworkBlock \
                        -StartIpList $firstaddress \
                        -PrefixLength $prefixlen \
                        -NetworkCount 1 \
                        -AddrIncrement 1  
               } else {
                   stc::config $hIpv6NetworkBlock \
                       -StartIpList $firstaddress \
                       -PrefixLength $prefixlen \
                       -NetworkCount $numaddress \
                       -AddrIncrement $modifier 
               }
            }
            default {
                error "Specified RoutePoolType is invalid"
            }
        }      
    }    
  
    #Deliver configuration command and check
    ApplyValidationCheck
          
    debugPut "exit the proc of IsisSession::IsisSetRouteBlock"
    return $::mainDefine::gSuccess    
}



############################################################################
#APIName: IsisDeleteRouteBlock
#
#Description: 
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDeleteRouteBlock {args} {
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]   
    debugPut "enter the proc of IsisSession::IsisDeleteRouteBlock"
    
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the BlockName of IsisSession::IsisDeleteRouteBlock"
    } 
    
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the BlockName of IsisSession::IsisDeleteRouteBlock"
    } 
    
    #Check whether the corresponding object of blockname exists
    set index [lsearch $m_lspBlockNameList $blockname]
    if {$index == -1} {
        error "BlockName($blockname) is not existed, the existed BlockName(s) is(are) as following:\n$m_lspBlockNameList"
    } 
    
    #Delete corresponding object
    set m_lspBlockNameList [lreplace $m_lspBlockNameList $index $index]
    
    #Get handles of IsisLspConfig object according to blockname 
    set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig]
    set hIsisRoutesConfig  [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]

    stc::delete $hIsisRoutesConfig          
    catch {unset m_isisRouteBlockConfig($routername) }  

    #Deliver configuration command and check
    ApplyValidationCheck
          
    debugPut "exit the proc of IsisSession::IsisDeleteRouteBlock" 
    return $::mainDefine::gSuccess 

}


############################################################################
#APIName: IsisRetrieveRouteBlock
#
#Description: Get configuraton infomation of Route block
#
#Input:          
#
#Output: Return the configuration of RouteBlock
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisRetrieveRouteBlock {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisRetrieveRouteBlock"
    
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the BlockName of IsisSession::IsisRetrieveRouteBlock"
    } 
    
    #Check whether the corresponding object of blockname exists
    set index [lsearch $m_lspBlockNameList $blockname]
    if {$index == -1} {
        error "BlockName($blockname) is not existed, the existed BlockName(s) is(are) as following:\n$m_lspBlockNameList"
    } 

    #Get handles of IsisLspConfig object according to blockname 
    set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisLspConfig]
    set hIsisLspConfig  [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]
    set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig]
    set hIsisRouteConfig  [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]  
    set hNetworkConfig [stc::get $hIsisRouteConfig -children]
    set index [lsearch $m_isisRouteBlockConfig($blockname) -routepooltype]
    set RoutePoolType  [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]  
    set index [lsearch $m_isisRouteBlockConfig($blockname) -flagflap]
    set flagflap [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1] ] 
      
    set RouteBlockConfig ""   
    lappend RouteBlockConfig -SystemId  
    lappend RouteBlockConfig [stc::get $hIsisLspConfig -systemid]  
    lappend RouteBlockConfig -RoutingLevel  
    lappend RouteBlockConfig [stc::get $hIsisLspConfig -level] 
    lappend RouteBlockConfig -RoutePoolType  
    lappend RouteBlockConfig $RoutePoolType         
    lappend RouteBlockConfig -RouteType  
    lappend RouteBlockConfig [stc::get $hIsisRouteConfig -RouteType] 
    lappend RouteBlockConfig -MetricType  
    lappend RouteBlockConfig [stc::get $hIsisRouteConfig -MetricType]         
    lappend RouteBlockConfig -FirstAddress  
    lappend RouteBlockConfig [stc::get $hNetworkConfig -StartIpList] 
    lappend RouteBlockConfig -PrefixLen  
    lappend RouteBlockConfig [stc::get $hNetworkConfig -PrefixLength]
    lappend RouteBlockConfig -NumAddress  
    lappend RouteBlockConfig [stc::get $hNetworkConfig -NetworkCount] 
    lappend RouteBlockConfig -Modifier  
    lappend RouteBlockConfig [stc::get $hNetworkConfig -AddrIncrement]
    lappend RouteBlockConfig -FlagFlap 
    lappend RouteBlockConfig $flagflap    
    lappend RouteBlockConfig -FlagTag  
    lappend RouteBlockConfig [stc::get $hIsisRouteConfig -AdminTag]    
    lappend RouteBlockConfig -Active  
    lappend RouteBlockConfig [stc::get $hIsisLspConfig -Active] 

    set args [lrange $args 2 end] 
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IsisSession::IsisRetrieveRouteBlock" 
        return $RouteBlockConfig
    } else {     
        set RouteBlockConfig [ConvertAttrToLowerCase $RouteBlockConfig]
        array set arr $RouteBlockConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
        debugPut "exit the proc of IsisSession::IsisRetrieveRouteBlock"
        return $::mainDefine::gSuccess     
    }      
}


############################################################################
#APIName: IsisListRouteBlock
#
#Description: 
#
#Input:      (1) -BlockNameList Mandatory parameters       
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisListRouteBlock {args} {   
    set args [ConvertAttrToLowerCase $args]
   
    debugPut "enter the proc of IsisSession::IsisListRouteBlock"

    lappend BlockList -blocknamelist
    lappend BlockList $m_lspBlockNameList

    array set arr $BlockList
    foreach {name valueVar}  $args {      

         set ::mainDefine::gAttrValue $arr($name)

         set ::mainDefine::gVar $valueVar
         uplevel 1 {
             set $::mainDefine::gVar $::mainDefine::gAttrValue
         }           
    }
 
    debugPut "exit the proc of IsisSession::IsisListRouteBlock"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: IsisAdvertiseRouteBlock
#
#Description: Advertise ISIS route
#
#Input:          (1) -BlockName Mandatory parameters, name identification of ISIS route block           
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisAdvertiseRouteBlock {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisAdvertiseRouteBlock"

    #Advertise route block by calling command STC 
    stc::perform IsisReadvertiseLsps -RouterList $m_hIsisRouterConfig       

    stc::apply          
    debugPut "exit the proc of IsisSession::IsisAdvertiseRouteBlock" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisWithdrawRouteBlock
#
#Description: Withdraw ISIS route
#
#Input:                 
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisWithdrawRouteBlock {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisWithdrawRouteBlock"
     
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set blockname [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName of IsisSession::IsisWithdrawRouteBlock"
    }
    
    set index [lsearch $m_lspBlockNameList $blockname]
    if {$index == -1} {
        error "The BlockName($blockname) is not existed,please specify another one, the existed BlockName(s) is(are) as following:\n$m_lspBlockNameList"
    } 
    
    #Get IsisRoutesConfig handles in RouteBlocks
    set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig] 
    if {$index != -1} {
        set hIsisRoutesConfig [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]
    } 
    
    #Advertise route block by calling command STC                
    stc::perform IsisWithdrawIpRoutes -IsisIpRouteList $hIsisRoutesConfig
                  
    debugPut "exit the proc of IsisSession::IsisWithdrawRouteBlock"  
    return $::mainDefine::gSuccess  
}

############################################################################
#APIName: IsisStartFlapRouteBlock
#
#Description: Flap all the RouteBlock when FlagFlap is TRUE
#
#Input:                
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStartFlapRouteBlock {args} {
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisStartFlapRouteBlock"

    #Get the parameter value of FlapNumber
    set index [lsearch $args -flapnumber] 
    if {$index != -1} {
        set FlapNumber [lindex $args [expr $index + 1]]
    } else  {
        set FlapNumber 10
    }
    
    set RouteParamList ""
    for {set i 0} {$i < [llength $m_lspBlockNameList]} {incr i} {
        set blockname [lindex $m_lspBlockNameList $i]
        set index [lsearch $m_isisRouteBlockConfig($blockname) -hIsisRoutesConfig] 
        if {$index != -1} {
            set hIsisRoutesConfig [lindex $m_isisRouteBlockConfig($blockname) [expr $index + 1]]
        } 
        set FlagFlap $m_FlagFlapList($blockname) 
 
        if {$FlagFlap == "TRUE"} {
            lappend RouteParamList $hIsisRoutesConfig
        }            
    }
    
    if {$RouteParamList == "" } {
        puts "No Route Block is in the flap state"
        return $::mainDefine::gSuccess
    }

    #Create Scheduler
    if {$m_sequencer == ""} {
        set existing_sequencer [stc::get system1 -Children-Sequencer]
        if {$existing_sequencer == ""} { 
            set m_sequencer  [stc::create Sequencer -under system1 -Name "IsisScheduler$m_routerName"]
        } else {
            set m_sequencer $existing_sequencer
        }
    }

    stc::perform SequencerClear
    
    #Create cmd of loop  
    set hIsisLoop [stc::create SequencerLoopCommand -under system1 -ContinuousMode FALSE -IterationCount $FlapNumber]

    #Create cmd of waiting for a designated time before advertising Isis Route 
    set hWaitBeforeAdv [stc::create WaitCommand -under $hIsisLoop  -WaitTime $m_wadTimer]    

    #Create cmd of advertising Isis Route 
    set hAdvRoute [stc::create IsisReadvertiseLspsCommand -under $hIsisLoop -RouterList $m_hIsisRouterConfig]

    #Create cmd of waiting for a designated time before withdrawing Isis Route
    set hWaitBeforeWithdraw [stc::create WaitCommand -under $hIsisLoop -WaitTime $m_awdTimer]

    #Create cmd of withdrawing Isis Route
    set hWithdrawRoute [stc::create IsisWithdrawIpRoutesCommand -under $hIsisLoop -IsisIpRouteList $RouteParamList]

    #Insert scheduler
    stc::perform SequencerInsert -CommandList $hIsisLoop 
    #Insert cmdscheduler of advertising Isis Route
    stc::perform SequencerInsert -CommandList $hAdvRoute -CommandParent $hIsisLoop 
    #Insert cmdscheduler of waiting for a designated time before withdrawing Isis Route
    stc::perform SequencerInsert -CommandList $hWaitBeforeWithdraw  -CommandParent $hIsisLoop 
    #Insert cmdscheduler of withdrawing Isis Route
    stc::perform SequencerInsert -CommandList $hWithdrawRoute  -CommandParent $hIsisLoop 

    #Insert cmdscheduler of waiting for a designated time before advertising Isis Route
    stc::perform SequencerInsert -CommandList $hWaitBeforeAdv  -CommandParent $hIsisLoop 

    #Start Sequencer        
    stc::perform SequencerStart
    
    debugPut "exit the proc of IsisSession::IsisStartFlapRouteBlock"   
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: IsisStopFlapRouteBlock
#
#Description: Stop ISIS route flap
#
#Input:                     
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStopFlapRouteBlock {args} {    
    debugPut "enter the proc of IsisSession::IsisStopFlapRouteBlock"
       
     #Stop Sequencer        
    stc::perform SequencerStop
       
    debugPut "exit the proc of IsisSession::IsisStopFlapRouteBlock" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisSetFlapRouteBlock
#
#Description: Configure ISIS route flap
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetFlapRouteBlock {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisSetFlapRouteBlock"

    #Get the parameter value of AWDTimer
    set index [lsearch $args -awdtimer] 
    if {$index != -1} {
        set AWDTimer [lindex $args [expr $index + 1]]
        set AWDTimer [expr $AWDTimer / 1000]
        if {$AWDTimer == 0} {
             set AWDTimer 1
        }
    } else  {
        set AWDTimer 5
    }
    
    #Get the parameter value of WADTimer
    set index [lsearch $args -wdatimer] 
    if {$index != -1} {
        set WADTimer [lindex $args [expr $index + 1]]
        set WADTimer [expr $WADTimer / 1000]
        if {$WADTimer == 0} {
             set WADTimer 1
        }
    } else  {
        set WADTimer 5
    }

    set m_awdTimer $AWDTimer        
    set m_wadTimer $WADTimer   
    
    debugPut "exit the proc of IsisSession::IsisSetFlapRouteBlock" 
    return $::mainDefine::gSuccess   
}


############################################################################
#APIName: IsisCreateTopGrid
#
#Description: Create ISIS network topology for designated ISIS Router
#
#Input:          (1) -GridName Mandatory parameters, name identification of ISIS Grid
#                  (2) -GridRows Optional parameters, line number of ISIS Grid
#                  (3) -GridCols Optional parameters, column number of ISIS Grid
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisCreateTopGrid {args} {
     #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]      
    debugPut "enter the proc of IsisSession::IsisCreateTopGrid"
    
    set index [lsearch $args -gridname] 
    if {$index != -1} {
        set gridname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the GridName of IsisSession::IsisCreateTopGrid"
    }
    
    set index [lsearch $m_gridNameList $gridname]
    if {$index != -1} {
        error "The GridName($gridname) already existed,please specify another one, the existed GridName(s) is(are) as following:\n$m_gridName"
    } else {
        lappend m_gridNameList $gridname
    }    
    
    set index [lsearch $args -gridrows] 
    if {$index != -1} {
        set gridrows [lindex $args [expr $index + 1]]
    } else  {
        set gridrows 1
    }
    lappend m_isisGridConfig($gridname) -gridrows
    lappend m_isisGridConfig($gridname) $gridrows   
  
    set index [lsearch $args -gridcols] 
    if {$index != -1} {
        set gridcols [lindex $args [expr $index + 1]]
    } else  {
        set gridcols 1
    } 
    lappend m_isisGridConfig($gridname) -gridcols
    lappend m_isisGridConfig($gridname) $gridcols  
    
    set totalRoutes [expr $gridrows*$gridcols]
    if {$totalRoutes > 10000} {
        error "The maxism total topology router number generated from Grid is 10000"
    } 
      
    set index [lsearch $args -connectedrow] 
    if {$index != -1} {
        set connectedrow [lindex $args [expr $index + 1]]
    } else  {
        set connectedrow 1
    }
    lappend m_isisGridConfig($gridname) -connectedrow
    lappend m_isisGridConfig($gridname) $connectedrow  
  
    set index [lsearch $args -connectedcol] 
    if {$index != -1} {
        set connectedcol [lindex $args [expr $index + 1]]
    } else  {
        set connectedcol 1
    }   
    lappend m_isisGridConfig($gridname) -connectedcol
    lappend m_isisGridConfig($gridname) $connectedcol  
    
    set index [lsearch $args -startingrouterid] 
    if {$index != -1} {
        set startingrouterid [lindex $args [expr $index + 1]]
    } else  {
        set startingrouterid 1.1.1.1
    }
    lappend m_isisGridConfig($gridname) -startingrouterid
    lappend m_isisGridConfig($gridname) $startingrouterid     
    
    set index [lsearch $args -startingsystemid] 
    if {$index != -1} {
        set startingsystemid [lindex $args [expr $index + 1]]
    } else  {
        set startingsystemid "01:01:01:01:01:01"
    }             
    lappend m_isisGridConfig($gridname) -startingsystemid
    lappend m_isisGridConfig($gridname) $startingsystemid    
 
    set index [lsearch $args -routinglevel] 
    if {$index != -1} {
        set routinglevel [lindex $args [expr $index + 1]]
    } else  {
        set routinglevel "L2"
    }             
    lappend m_isisGridConfig($gridname) -routinglevel
    lappend m_isisGridConfig($gridname) $routinglevel  
       
    set index [lsearch $args -flagte] 
    if {$index != -1} {
        set flagte [lindex $args [expr $index + 1]]
    } else  {
        set flagte "false"
    }    
    lappend m_isisGridConfig($gridname) -flagte
    lappend m_isisGridConfig($gridname) $flagte  
    
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set flagadvertise [lindex $args [expr $index + 1]]
    } else  {
        set flagadvertise "ALL"
    } 
    lappend m_isisGridConfig($gridname) -flagadvertise
    lappend m_isisGridConfig($gridname) $flagadvertise             

    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set addressfamily [lindex $args [expr $index + 1]]
    } else  {
        set addressfamily IPV4
    }
    lappend m_isisGridConfig($gridname) -addressfamily
    lappend m_isisGridConfig($gridname) $addressfamily
    
    #routetype include: internal  external  internal_and_external
    set index [lsearch $args -routetype] 
    if {$index != -1} {
        set routetype [lindex $args [expr $index + 1]]
    } else  {
        set routetype "internal"
    }
    
    set index [lsearch $args -routenum] 
    if {$index != -1} {
        set routenum [lindex $args [expr $index + 1]]
    } else  {
        set routenum 0
    }
    set index [lsearch $args -route_ipv4_start] 
    if {$index != -1} {
        set route_ipv4_start [lindex $args [expr $index + 1]]
    } else  {
        set route_ipv4_start 1.0.0.0
    }
    set index [lsearch $args -route_ipv6_start] 
    if {$index != -1} {
        set route_ipv6_start [lindex $args [expr $index + 1]]
    } else  {
        set route_ipv6_start 2000::
    }
    
    switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
        l1/l2 {
            set level "LEVEL1_AND_2"        
        }                   
        L1/L2 {
            set level "LEVEL1_AND_2"        
        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1,L2,L1/L2"
        }
    }       
    
    set addressfamily [string tolower $addressfamily] 
    switch $addressfamily {
        ipv4 {
            set ipversion "IPV4"       
        }
        ipv6 {
            set ipversion "IPV6"        
        }
        both {
            set ipversion "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified AddressFamily is invaild"
        }
    }
    
    
    set hIsisLspGenParams [stc::create "IsisLspGenParams" \
        -under $m_hProject \
        -Level $level \
        -Ipv4AddrStart $route_ipv4_start \
        -Ipv4AddrEnd "223.255.255.255" \
        -Ipv6AddrStart $route_ipv6_start \
        -Ipv6AddrEnd "3ffe::" \
        -RouterIdStart $startingrouterid \
        -SystemIdStart $startingsystemid \
        -TeEnabled $flagte \
        -Name $gridname ]
    lappend m_isisLspGenParamsArr($gridname) -hIsisLspGenParams  
    lappend m_isisLspGenParamsArr($gridname) $hIsisLspGenParams 
    set hIpv4RouteGenParams [stc::create "Ipv4RouteGenParams" \
        -under $hIsisLspGenParams \
        -IpAddrStart $route_ipv4_start \
        -IpAddrEnd "223.255.255.255" \
        -PrefixLengthStart "24" \
        -PrefixLengthEnd "24" \
        -EmulatedRouters "NONE" \
        -SimulatedRouters "ALL" \
        -EnableIpAddrOverride "FALSE"]
    if {($ipversion == "IPV4" || $ipversion == "IPV4_AND_IPV6") && ($routetype == "internal" || $routetype == "internal_and_external")} {
        if {$routenum != 0} {
            stc::config $hIpv4RouteGenParams -Count $routenum
        }
    }
    lappend m_isisLspGenParamsArr($gridname) -hIpv4RouteGenParams  
    lappend m_isisLspGenParamsArr($gridname) $hIpv4RouteGenParams 
    
    set hIsisLspGenRouteAttrParams [stc::create "IsisLspGenRouteAttrParams" \
        -under $hIpv4RouteGenParams \
        -RouteType "INTERNAL" \
        -PrimaryMetric "1" \
        -SecondaryMetric "2"]
    
    set hIpv4RouteGenParams_External [stc::create "Ipv4RouteGenParams" \
        -under $hIsisLspGenParams \
        -IpAddrStart $route_ipv4_start \
        -IpAddrEnd "223.255.255.255" \
        -PrefixLengthStart "24" \
        -PrefixLengthEnd "24" \
        -EmulatedRouters "NONE" \
        -SimulatedRouters "ALL" \
        -EnableIpAddrOverride "FALSE"]
    if {($ipversion == "IPV4" || $ipversion == "IPV4_AND_IPV6") && ($routetype == "external" || $routetype == "internal_and_external")} {
        if {$routenum != 0} {
            stc::config $hIpv4RouteGenParams_External -Count $routenum
        }
    }
    set hIsisLspGenRouteAttrParams_External [stc::create "IsisLspGenRouteAttrParams" \
        -under $hIpv4RouteGenParams_External \
        -RouteType "EXTERNAL" \
        -PrimaryMetric "10" \
        -SecondaryMetric "20"]
    lappend m_isisLspGenParamsArr($gridname) -hIsisLspGenRouteAttrParams  
    lappend m_isisLspGenParamsArr($gridname) $hIsisLspGenRouteAttrParams 
    
    if {$ipversion != "IPV4"} {
        set hIpv6RouteGenParams [stc::create "Ipv6RouteGenParams" \
            -under $hIsisLspGenParams \
            -IpAddrStart $route_ipv6_start \
            -IpAddrEnd "3ffe::" \
            -PrefixLengthStart "64" \
            -PrefixLengthEnd "64" \
            -EmulatedRouters "NONE" \
            -SimulatedRouters "ALL" \
            -Count "0" \
            -PrefixLengthDistType "FIXED" \
            -DuplicationPercentage "0.000000" \
            -DisableRouteAggregation "FALSE" \
            -WeightRouteAssignment "BYROUTERS" \
            -EnableIpAddrOverride "FALSE" ]
        if {$routetype == "internal" || $routetype == "internal_and_external"} {
            if {$routenum != 0} {
                stc::config $hIpv6RouteGenParams -Count $routenum
            }
        }
        lappend m_isisLspGenParamsArr($gridname) -hIpv6RouteGenParams  
        lappend m_isisLspGenParamsArr($gridname) $hIpv6RouteGenParams           
            
        set hIsisLspGenRouteAttrParams [stc::create "IsisLspGenRouteAttrParams" \
            -under $hIpv6RouteGenParams \
            -RouteType "INTERNAL" \
            -PrimaryMetric "1" \
            -SecondaryMetric "2"  ]              
        lappend m_isisLspGenParamsArr($gridname) -hIsisLspGenRouteAttrParams  
        lappend m_isisLspGenParamsArr($gridname) $hIsisLspGenRouteAttrParams
        
        set hIpv6RouteGenParams_External [stc::create "Ipv6RouteGenParams" \
            -under $hIsisLspGenParams \
            -IpAddrStart $route_ipv6_start \
            -IpAddrEnd "3ffe::" \
            -PrefixLengthStart "64" \
            -PrefixLengthEnd "64" \
            -EmulatedRouters "NONE" \
            -SimulatedRouters "ALL" \
            -Count "0" \
            -PrefixLengthDistType "FIXED" \
            -DuplicationPercentage "0.000000" \
            -DisableRouteAggregation "FALSE" \
            -WeightRouteAssignment "BYROUTERS" \
            -EnableIpAddrOverride "FALSE" ]
        if {$routetype == "external" || $routetype == "internal_and_external"} {
            if {$routenum != 0} {
                stc::config $hIpv6RouteGenParams_External -Count $routenum
            }
        }
        set hIsisLspGenRouteAttrParams [stc::create "IsisLspGenRouteAttrParams" \
            -under $hIpv6RouteGenParams_External \
            -RouteType "EXTERNAL" \
            -PrimaryMetric "10" \
            -SecondaryMetric "20"  ]
    }
                  
    set hGridTopologyGenParams [stc::create "GridTopologyGenParams" \
        -under $hIsisLspGenParams \
        -Columns $gridcols \
        -Rows $gridrows \
        -AttachRowIndex $connectedrow \
        -AttachColumnIndex $connectedcol]         
    lappend m_isisLspGenParamsArr($gridname) -hGridTopologyGenParams  
    lappend m_isisLspGenParamsArr($gridname) $hGridTopologyGenParams                                                                            
 
    stc::config $hIsisLspGenParams -SelectedRouterRelation-targets "$m_hRouter"

    #Generate corresponding LSP with topo
    stc::perform RouteGenApply -GenParams $hIsisLspGenParams
   
    #Deliver configuration command and check
    ApplyValidationCheck
     
    debugPut "exit the proc of IsisSession::IsisCreateTopGrid"    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IsisSetTopGrid
#
#Description: Configure ISIS network topology which has been created
#
#Input:            (1) -GridName Mandatory parameters, name identification of ISIS Grid
#                  (2) -GridRows Mandatory parameters, line number of ISIS Grid
#                  (3) -GridCols Mandatory parameters, column number of ISIS Grid
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetTopGrid {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of IsisSession::IsisSetTopGrid"  
    
    set index [lsearch $args -gridname] 
    if {$index != -1} {
        set gridname [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the GridName of IsisSession::IsisSetTopGrid"
    }
    
    #Check whether the corresponding object of gridname exists
    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
        error "GridName($gridname) is not existed, the existed GridName(s) is(are) as following:\n$m_gridNameList"
    } 
        
    set index [lsearch $args -gridrows] 
    if {$index != -1} {
        set gridrows [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -gridrows]
        set gridrows [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }
  
    set index [lsearch $args -gridcols] 
    if {$index != -1} {
        set gridcols [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -gridcols]
        set gridcols [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    } 
      
    set index [lsearch $args -connectedrow] 
    if {$index != -1} {
        set connectedrow [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -connectedrow]
        set connectedrow [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }
  
    set index [lsearch $args -connectedcol] 
    if {$index != -1} {
        set connectedcol [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -connectedcol]
        set connectedcol [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }   
    
    set index [lsearch $args -startingrouterid] 
    if {$index != -1} {
        set startingrouterid [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -startingrouterid]
        set startingrouterid [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }
    
    set index [lsearch $args -startingsystemid] 
    if {$index != -1} {
        set startingsystemid [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -startingsystemid]
        set startingsystemid [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }             
 
    set index [lsearch $args -routinglevel] 
    if {$index != -1} {
        set routinglevel [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -routinglevel]
        set routinglevel [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }             
       
    set index [lsearch $args -flagte] 
    if {$index != -1} {
        set flagte [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -flagte]
        set flagte [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }  
    
    set index [lsearch $args -flagadvertised] 
    if {$index != -1} {
        set flagadvertise [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -flagadvertise]
        set flagadvertise [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }  
         
    set index [lsearch $args -addressfamily] 
    if {$index != -1} {
        set addressfamily [lindex $args [expr $index + 1]]
    } else  {
        set index [lsearch $m_isisGridConfig($gridname) -addressfamily]
        set addressfamily [lindex $m_isisGridConfig($gridname) [expr $index + 1] ]
    }   
    
     switch $routinglevel {
        L1 {
            set level "LEVEL1"
        }
        l1 {
            set level "LEVEL1"
        }        
        L2 {
            set level "LEVEL2"        
        }
        l2 {
            set level "LEVEL2"        
        } 
        l1/l2 {
            set level "LEVEL1_AND_2"        
        }                   
        L1/L2 {
            set level "LEVEL1_AND_2"        
        }
        default {
            error "The specified RoutingLevel is invaild, valid input should be L1,L2,L1/L2"
        }
    }       
 
    set addressfamily [string tolower $addressfamily] 
    switch $addressfamily {
        ipv4 {
            set ipversion "IPV4"       
        }
        ipv6 {
            set ipversion "IPV6"        
        }
        both {
            set ipversion "IPV4_AND_IPV6"        
        }        
        default {
            error "The specified AddressFamily is invaild"
        }
    }

    #Modify object attribute of IsisGrid
    set index [lsearch $m_isisLspGenParamsArr($gridname) -hIsisLspGenParams] 
    if {$index != -1} {
        set hIsisLspGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
    }           
    stc::config $hIsisLspGenParams \
        -TeEnabled $flagte \
        -RouterIdStart $startingrouterid \
        -SystemIdStart $startingsystemid \
        -Level $level
        
    set index [lsearch $m_isisLspGenParamsArr($gridname) -hIpv4RouteGenParams] 
    if {$index != -1} {
        set hIpv4RouteGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
    } 
   
    stc::config $hIpv4RouteGenParams \
        -IpAddrStart "1.0.0.0" \
        -IpAddrEnd "223.255.255.255" \
        -PrefixLengthStart "24" \
        -PrefixLengthEnd "24" \
        -EmulatedRouters "NONE" \
        -SimulatedRouters "ALL"     
    if {$ipversion != "IPV4"} {
        set index [lsearch $m_isisLspGenParamsArr($gridname) -hIpv6RouteGenParams] 
        if {$index != -1} {
            set hIpv6RouteGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
        }   
        stc::config $hIpv6RouteGenParams \
            -IpAddrStart "2000::" \
            -IpAddrEnd "3ffe::" \
            -PrefixLengthStart "64" \
            -PrefixLengthEnd "64" \
            -EmulatedRouters "NONE" \
            -SimulatedRouters "ALL"    
    }

    set index [lsearch $m_isisLspGenParamsArr($gridname) -hGridTopologyGenParams] 
    if {$index != -1} {
        set hGridTopologyGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
    }  
    stc::config $hGridTopologyGenParams \
        -Columns $gridcols \
        -Rows $gridrows \
        -AttachRowIndex $connectedrow \
        -AttachColumnIndex $connectedcol   
   
    #Generate corresponding LSP with topo
    stc::perform RouteGenApply -GenParams $hIsisLspGenParams
     
    #Deliver configuration command and check
    ApplyValidationCheck
       
    debugPut "exit the proc of IsisSession::IsisSetTopGrid"  
    return $::mainDefine::gSuccess         
}



############################################################################
#APIName: IsisDeleteTopGrid
#
#Description: 
#
#Input:          (1) -GridName GridName:Mandatory parameters, name identification of ISIS Grid
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisDeleteTopGrid {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisDeleteTopGrid"

    set index [lsearch $args -gridname]
    if {$index != -1} {
       set gridname [lindex $args [expr $index + 1]]
    } else {
       error "please specify GridName for IsisSession::IsisDeleteTopGrid"
    }

    set index [lsearch $m_gridNameList $gridname]
    if {$index == -1} {
       error "GridName($gridname) is not exist, the existed GridName(s) is(are) as following:\n$m_gridNameList"
    } 
    

    #Delete designated objects from the list    
    set m_gridNameList [lreplace $m_gridNameList $index $index]
    #Delete relevant handles
    set index [lsearch $m_isisLspGenParamsArr($gridname) -hGridTopologyGenParams] 
    if {$index != -1} {
        set hGridTopologyGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
    }  
    
    stc::delete $hGridTopologyGenParams
    set index [lsearch $m_isisLspGenParamsArr($gridname) -hIsisLspGenParams] 
    if {$index != -1} {
        set hIsisLspGenParams [lindex $m_isisLspGenParamsArr($gridname) [expr $index + 1]]
    }   
    stc::delete $hIsisLspGenParams
     
    catch {unset m_isisLspGenParamsArr($gridname) } 

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisDeleteTopGrid" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisAdvertiseRouters
#
#Description: 
#
#Input:          (1) -RouterNameList RouterNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisAdvertiseRouters {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisAdvertiseRouters"

    set index [lsearch $args -routernamelist]
    if {$index != -1} {
       set routernamelist [lindex $args [expr $index + 1]]
    } else {
       set routernamelist $m_routerNameList
    }

    foreach routername $routernamelist {
        set index [lsearch $m_routerNameList $routername]
        if {$index == -1} {
            error "$routername doesn't exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
        } else {
            #Get relevant handles
            set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
            if {$index != -1} {
               set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hIsisLspConfig -Active TRUE
            } 

            set index [lsearch $m_topRouterConfig($routername) -hIsisLspNeighborConfig]
            if {$index != -1} {
               set hIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hIsisLspNeighborConfig -Active TRUE
            }
                        
            set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspConfig]
            if {$index != -1} {
               set hNbrIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hNbrIsisLspConfig -Active TRUE
            }
            
            set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspNeighborConfig]
            if {$index != -1} {
               set hNbrIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hNbrIsisLspNeighborConfig -Active TRUE
            }                  
        }                
    }    

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisAdvertiseRouters" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisWithdrawRouters
#
#Description: 
#
#Input:          (1) -RouterNameList RouterNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisWithdrawRouters {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisWithdrawRouters"

    set index [lsearch $args -routernamelist]
    if {$index != -1} {
       set routernamelist [lindex $args [expr $index + 1]]
    } else {
       set routernamelist $m_routerNameList
    }

    foreach routername $routernamelist {
        set index [lsearch $m_routerNameList $routername]
        if {$index == -1} {
            error "$routername doesn't exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
        } else {
            #Get relevant handles
            set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
            if {$index != -1} {
               set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hIsisLspConfig -Active FALSE
            } 

            set index [lsearch $m_topRouterConfig($routername) -hIsisLspNeighborConfig]
            if {$index != -1} {
               set hIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hIsisLspNeighborConfig -Active FALSE
            }
                        
            set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspConfig]
            if {$index != -1} {
               set hNbrIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hNbrIsisLspConfig -Active FALSE
            }
            
            set index [lsearch $m_topRouterConfig($routername) -hNbrIsisLspNeighborConfig]
            if {$index != -1} {
               set hNbrIsisLspNeighborConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
               stc::config $hNbrIsisLspNeighborConfig -Active FALSE
            }                  
        }                
    }   

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisWithdrawRouters" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisAdvertiseLinks
#
#Description: 
#
#Input:          (1) -LinkNameList LinkNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisAdvertiseLinks {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisAdvertiseLinks"

    set index [lsearch $args -linknamelist]
    if {$index != -1} {
       set linknamelist [lindex $args [expr $index + 1]]
    } else {
       set linknamelist $m_linkNameList
    }

    foreach linkname $linknamelist {
        set index [lsearch $m_linkNameList $linkname]
        if {$index == -1} {
            error "$linkname doesn't exist, the existed LinkName(s) is(are) as following:\n$m_linkNameList"
        } else {
            #Get relevant handles
            set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
            if {$index != -1} {
               set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
               stc::config $IsisLspNbrhandle -Active TRUE
            } 

            set index [lsearch $m_topRouterLinkConfig($linkname) -NbrLspNbrHandle]
            if {$index != -1} {
               set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
               stc::config $NbrLspNbrHandle -Active TRUE
            }
        }            
    }   

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisAdvertiseLinks" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisWithdrawLinks
#
#Description: 
#
#Input:          (1) -LinkNameList LinkNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisWithdrawLinks {args} { 
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisWithdrawLinks"

    set index [lsearch $args -linknamelist]
    if {$index != -1} {
       set linknamelist [lindex $args [expr $index + 1]]
    } else {
       set linknamelist $m_linkNameList
    }
    
    foreach linkname $linknamelist {
        set index [lsearch $m_linkNameList $linkname]
        if {$index == -1} {
            error "$linkname doesn't exist, the existed LinkName(s) is(are) as following:\n$m_linkNameList"
        } else {
            #Get relevant handles
            set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
            if {$index != -1} {
               set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
               stc::config $IsisLspNbrhandle -Active FALSE
            } 

            set index [lsearch $m_topRouterLinkConfig($linkname) -NbrLspNbrHandle]
            if {$index != -1} {
               set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
               stc::config $NbrLspNbrHandle -Active FALSE
            }
        }            
    }  

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisWithdrawLinks" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisSetFlap
#
#Description: Configure flap of ISIS route protocol
#
#Input:          
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisSetFlap {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisSetFlap"

    set index [lsearch $args -awdtimer] 
    if {$index != -1} {
        set awdTimer [lindex $args [expr $index + 1]]
    } else  {
        set awdTimer 5
    }

    set index [lsearch $args -wadTimer] 
    if {$index != -1} {
        set wadTimer [lindex $args [expr $index + 1]]
    } else  {
        set wadTimer 5
    }

    set m_awdTimer $awdTimer        
    set m_wadTimer $wadTimer   
    
    debugPut "exit the proc of IsisSession::IsisSetFlap" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisStartFlapLinks
#
#Description: 
#
#Input:          (1) -LinkNameList LinkNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStartFlapLinks {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisStartFlapLinks"

    set index [lsearch $args -linknamelist]
    if {$index != -1} {
       set linknamelist [lindex $args [expr $index + 1]]
    } else {
       set linknamelist $m_linkNameList
    }

    set index [lsearch $args -flapnumber]
    if {$index != -1} {
       set flapnumber [lindex $args [expr $index + 1]]
    } else {
       set flapnumber 10
    }
        
    for {set i 0} {$i < $flapnumber} {incr i} {
        foreach linkname $linknamelist {
            set index [lsearch $m_linkNameList $linkname]
            if {$index == -1} {
                error "$linkname doesn't exist, the existed LinkName(s) is(are) as following:\n$m_linkNameList"
            } else {
                #Get relevant handles
                set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
                if {$index != -1} {
                   set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
                   stc::config $IsisLspNbrhandle -Active TRUE
                } 
        
                set index [lsearch $m_topRouterConfig($routername) -NbrLspNbrHandle]
                if {$index != -1} {
                   set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
                   stc::config $NbrLspNbrHandle -Active TRUE
                }
            }            
        }
        
        #Deliver configuration command and check
        ApplyValidationCheck    
        after $m_wadTimer   
        
        foreach linkname $linknamelist {
            set index [lsearch $m_linkNameList $routername]
            if {$index == -1} {
                error "$linkname doesn't exist, the existed LinkName(s) is(are) as following:\n$m_linkNameList"
            } else {
                #Get relevant handles
                set index [lsearch $m_topRouterLinkConfig($linkname) -IsisLspNbrhandle]
                if {$index != -1} {
                   set IsisLspNbrhandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
                   stc::config $IsisLspNbrhandle -Active FALSE
                } 
        
                set index [lsearch $m_topRouterConfig($routername) -NbrLspNbrHandle]
                if {$index != -1} {
                   set NbrLspNbrHandle [lindex $m_topRouterLinkConfig($linkname) [expr $index + 1]]
                   stc::config $NbrLspNbrHandle -Active FALSE
                }
            }            
        }
        
        #Deliver configuration command and check
        ApplyValidationCheck    
        after $m_wadTimer     
    }
                                  
    debugPut "exit the proc of IsisSession::IsisStartFlapLinks" 
    return $::mainDefine::gSuccess   
}


############################################################################
#APIName: IsisStopFlapLinks
#
#Description: 
#
#Input:          (1) -LinkNameList LinkNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStopFlapLinks {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisStopFlapLinks"

    set index [lsearch $args -linknamelist]
    if {$index != -1} {
       set linknamelist [lindex $args [expr $index + 1]]
    } else {
       set linknamelist $m_linkNameList
    }

 

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisStopFlapLinks" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisStartFlapRouters
#
#Description: 
#
#Input:          (1) -RouterNameList RouterNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStartFlapRouters {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisStartFlapRouters"

    set index [lsearch $args -routernamelist]
    if {$index != -1} {
       set routernamelist [lindex $args [expr $index + 1]]
    } else {
       set routernamelist $m_routerNameList 
    }

    set index [lsearch $args -flapnumber]
    if {$index != -1} {
       set flapnumber [lindex $args [expr $index + 1]]
    } else {
       set flapnumber 10
    }
    
    for {set i 0} {$i < $flapnumber} {incr i} {
        foreach routername $routernamelist {
            set index [lsearch $m_routerNameList $routername]
            if {$index == -1} {
                error "$routername doesn't exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
            } else {
                #Get relevant handles
                set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
                if {$index != -1} {
                   set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
                   stc::config $hIsisLspConfig -Active FALSE
                }             
            }                
        }   
        
        #Deliver configuration command and check
        ApplyValidationCheck
        after $m_wadTimer 
        
        foreach routername $routernamelist {
            set index [lsearch $m_routerNameList $routername]
            if {$index == -1} {
                error "$routername doesn't exist, the existed RouterName(s) is(are) as following:\n$m_routerNameList"
            } else {
                #Get relevant handles
                set index [lsearch $m_topRouterConfig($routername) -hIsisLspConfig]
                if {$index != -1} {
                   set hIsisLspConfig [lindex $m_topRouterConfig($routername) [expr $index + 1]]
                   stc::config $hIsisLspConfig -Active FALSE
                }             
            }                
        } 
        
        #Deliver configuration command and check
        ApplyValidationCheck
        after $m_awdTimer    
    }
                       
    debugPut "exit the proc of IsisSession::IsisStartFlapRouters" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisStopFlapRouters
#
#Description: 
#
#Input:          (1) -RouterNameList RouterNameList:Mandatory parameters
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisStopFlapRouters {args} {  
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisStopFlapRouters"

    set index [lsearch $args -routernamelist]
    if {$index != -1} {
       set routernamelist [lindex $args [expr $index + 1]]
    } else {
       set routernamelist $m_routerNameList
    }

 

    #Deliver configuration command and check
    ApplyValidationCheck
                       
    debugPut "exit the proc of IsisSession::IsisStopFlapRouters" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: IsisGraceRestartAction
#
#Description: 
#
#Input:
#
#Output: 0/1
#
#Coded by: Penn.Chen
############################################################################
::itcl::body IsisSession::IsisGraceRestartAction {args} {   
    #Convert input parameters to lowercase parameters
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of IsisSession::IsisGraceRestartAction"

    stc::config $m_hIsisRouterConfig -EnableGracefulRestart TRUE 
    
    #Deliver configuration command and check
    ApplyValidationCheck
    
    stc::perform IsisRestartIsisRouter -RouterList $m_hIsisRouterConfig
                       
    debugPut "exit the proc of IsisSession::IsisGraceRestartAction" 
    return $::mainDefine::gSuccess   
}
