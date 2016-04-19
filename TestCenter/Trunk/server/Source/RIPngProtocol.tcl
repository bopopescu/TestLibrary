###################################################################################
#                                                                        
#  Filename：RIPngProtocol.tcl                                                                                              
# 
#  Description：Definition of RIPng class and relevant API                                     
# 
#  Creator： Tony
#
#  Time:  2007.6.11
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

############################################################################
#APIName: GetGatewayIpv6
#Description: According to input IPv6 address, automatically get the gateway address
#Input:  ipv6Addr - input IPv6 address
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

::itcl::class RIPngSession {
    #Inherit Router class
    inherit Router

    #Variables
    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName
 
    public variable m_hRIPngRouterConfig
    public variable m_hRIPngRouterResult ""
    public variable m_hIpv6If1 ""
    public variable m_hIpv6If2 ""
    public variable m_hL2If  ""

    #Corresponding handles of Sequencer
    public variable m_sequencer ""

    #Created Route block list
    public variable m_RouteBlockNameList  ""
    public variable m_RouteHandleList 

    #Definition of 's configuration infomation
    public variable m_suIp   "3FFE::1"
    public variable m_testIp  "3FFE::2"
    public variable m_metric   1
    public variable m_prefixLen 64
    public variable m_expirationInterval 180000
    public variable m_garbageInterval 120000
    public variable m_updateInterval 30000
    public variable m_triggeeedInterval 5000
    public variable m_updateControl false
    public variable m_routesPerUpdate  25

    public variable m_version "NG"
    public variable m_routerId "192.85.1.2"
    public variable m_updateType "MULTICAST"
    public variable m_linkLocalAddr  "fe80::1"
    public variable m_active "true"

    #Relevant configuration of Route Block
    public variable m_MetricList
    public variable m_FlagFlapList
    public variable m_RouteTagList
    public variable m_NextHopList
    public variable m_StartIPAddressList
    public variable m_PrefixLengthList
    public variable m_NumberList
    public variable m_ModifierList
    public variable m_ActiveList 
    public variable m_FlagTrafficDestinationList
    public variable m_FlagAdvertiseList

    #Relevant parameters of flap
    public variable m_awdTimer 5
    public variable m_wadTimer 5 

    public variable m_ResultDataSet  
    public variable m_portType "ethernet"

    #Constructor
    constructor {routerName routerType routerId hRouter hPort portName hProject hIpv61 hIpv62 portType} \
    { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     
        set m_routerName $routerName       
        set m_hRouter $hRouter
        set m_routerId $routerId
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_portType $portType        

        #Crete RIPngRouterConfig, conduct default configuration  
        set m_hRIPngRouterConfig [stc::create "RipRouterConfig" \
            -under $m_hRouter \
            -RipVersion $m_version \
            -UpdateType "MULTICAST" \
            -UpdateInterval $m_updateInterval \
            -UpdateJitter "0" \
            -MaxRoutePerUpdate "25" \
            -InterUpdateDelay "10" \
            -ViewRoutes "FALSE" \
            -EnableEventLog "FALSE" \
            -UsePartialBlockState "FALSE" \
            -Active "FALSE" \
            -Name "RIPngRouterConfig$m_routerName" ]

        #Get Ipv6 interface
        set m_hIpv6If1 $hIpv61
        set m_hIpv6If2 $hIpv62
        
        set m_hIpAddress $m_hIpv6If1

        #Get Ethernet interface
        #added by yuanfen
        if {$m_portType == "ethernet"} {
            set m_hL2If [stc::get $hRouter -children-EthIIIf]
            set m_hMacAddress $m_hL2If
        } elseif {$m_portType == "wan"} {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set m_hL2If [stc::get $hRouter -children-HdlcIf]
            } else {
                set m_hL2If [stc::get $hRouter -children-PppIf]
            }
        }                                                                                                           
    
        stc::config $m_hRIPngRouterConfig -UsesIf-targets $m_hIpv6If1   
    }

    #Destructor
    destructor {
    }

    #Declare methods
    public method RipngSetSession
    public method RipngRetrieveRouter
    
    public method RipngEnable
    public method RipngDisable
    public method RipngCreateRouteBlock    
    public method RipngSetRouteBlock
    public method RipngDeleteRouteBlock
    public method RipngListRouteBlock
    public method RipngRetrieveRouteBlock
    public method RipngAdvertiseRouteBlock
    public method RipngWithdrawRouteBlock
    public method RipngStartFlapRouteBlock
    public method RipngSetFlapRouteBlock
    public method RipngStopFlapRouteBlock
    public method RipngRetrieveRouterStats
    public method RipngRetrieveRouterStatus
}

############################################################################
#APIName: RipngSetSession
#Description: According to input parameters, configure RIP routing
#Input: For details see API use documentation and HELP documentation
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngSetSession {args} {

    set args [ConvertAttrPlusValueToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngSetSession"

    #Get the parameter value of SuIP
    set index [lsearch $args -sutip] 
    if {$index != -1} {
        set SuIp [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the IP address of the DUT"
    }
    
    set m_suIp $SuIp
    
    #Get the parameter value of TestIP
    set index [lsearch $args -testip] 
    if {$index != -1} {
        set TestIp [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify the IP address of the RIP Router\nexit the proc of RIPngRouter::RipngSetSession"
    }
    
    set m_testIp $TestIp
     
    #Get the parameter value of PrefixLen
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
        set m_prefixLen $PrefixLen
    } 
    
    #Get the parameter value of Metric
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
        set m_metric $Metric
    } 
    
    #Get the parameter value of UpdateInterval
    set index [lsearch $args -updateinterval] 
    if {$index != -1} {
        set UpdateInterval [lindex $args [expr $index + 1]]
        set m_updateInterval $UpdateInterval
    } 
    
    #Get the parameter value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
         set m_active $Active
    }

    #Get the parameter value of RoutesPerUpdate
    set index [lsearch $args -routesperupdate] 
    if {$index != -1} {
        set RoutesPerUpdate [lindex $args [expr $index + 1]]
        set m_routesPerUpdate $RoutesPerUpdate
    } 
 
    #Get the parameter value of UpdateType
    set index [lsearch $args -updatetype] 
    if {$index != -1} {
        set UpdateType [lindex $args [expr $index + 1]]
        set m_updateType $UpdateType
    }

    #Get the parameter value of UpdateType
    set index [lsearch $args -testlinklocaladdr] 
    if {$index != -1} {
        set LinkLocalAddr [lindex $args [expr $index + 1]]
        set m_linkLocalAddr $LinkLocalAddr
    } 

    stc::config $m_hRouter -RouterId $m_routerId  -Active $m_active 

    set RipRouterConfig [stc::get $m_hRouter -children-RipRouterConfig]
   
    #Set RipngRouterConfig
    set RipngRouterConfig [lindex [stc::get $RipRouterConfig \
                             -children-RipngRouterConfig] 0]
    stc::config $RipngRouterConfig \
        -Active $m_active  \
        -Name "RipngRouterConfig$m_routerName"

    set Gateway [GetGatewayIpv6 $m_testIp]

    stc::config $m_hIpv6If1  -Address $m_linkLocalAddr  -Gateway $Gateway -PrefixLength $m_prefixLen
    stc::config $m_hIpv6If2 -Address $m_testIp -Gateway $Gateway -PrefixLength $m_prefixLen 
                             
     #Find corresponding Mac address and set the address according to testerIp from Host
    SetMacAddress $m_testIp "Ipv6"

    #Make the association definition between objects
    stc::config $m_hRouter -AffiliationPort-targets $m_hPort

    stc::config $RipRouterConfig -UsesIf-targets $m_hIpv6If1

    set UpdateInterval [expr $m_updateInterval / 1000] 
    if {$UpdateInterval == 0} {
        set UpdateInterval 1
    }

    #Set RipRouterConfig according to input parameter
    stc::config $RipRouterConfig -RipVersion $m_version \
                -UpdateType $m_updateType \
                -UpdateInterval $UpdateInterval \
                -MaxRoutePerUpdate $m_routesPerUpdate \
                -Active $m_active  \
                -DutIpv6Addr $SuIp \
                -ViewRoutes "FALSE" \
                -EnableEventLog "FALSE" 
    #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of RIPngRouter::RipngSetSession"

    return $::mainDefine::gSuccess
  
}

############################################################################
#APIName: RipngRetrieveRouter
#Description: According to input parameter, get router's parameter根据传入参数，获取路由的参数
#Input:  For details see API use documentation and HELP documentation
#Output: Router parameter list 
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngRetrieveRouter {args} {

  set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngRetrieveRouter"

    set RIPngRouterStatus "" 
    
    lappend RIPngRouterStatus "-sutip"                                 
    lappend RIPngRouterStatus $m_suIp 
              
    lappend RIPngRouterStatus "-testip"                                 
    lappend RIPngRouterStatus $m_testIp 
        
    lappend RIPngRouterStatus "-prefixlen"                                 
    lappend RIPngRouterStatus $m_prefixLen
    
    lappend RIPngRouterStatus "-metric"                                 
    lappend RIPngRouterStatus $m_metric
    
    set UpdateInterval [stc::get $m_hRIPngRouterConfig -UpdateInterval]
    lappend RIPngRouterStatus "-updateinterval"                                 
    lappend RIPngRouterStatus [expr $UpdateInterval * 1000]
    
    lappend RIPngRouterStatus "-version"                                 
    lappend RIPngRouterStatus  [stc::get $m_hRIPngRouterConfig -RipVersion]
    
    lappend RIPngRouterStatus "-state"                                 
    lappend RIPngRouterStatus  [stc::get $m_hRIPngRouterConfig -RouterState]

    lappend RIPngRouterStatus "-routesperupdate"                                 
    lappend RIPngRouterStatus [stc::get $m_hRIPngRouterConfig -MaxRoutePerUpdate]

    lappend RIPngRouterStatus "-active"                                 
    lappend RIPngRouterStatus [stc::get $m_hRIPngRouterConfig -Active]

    lappend RIPngRouterStatus "-routerid"                                 
    lappend RIPngRouterStatus $m_routerId

    lappend RIPngRouterStatus "-updatetype"                                 
    lappend RIPngRouterStatus [stc::get $m_hRIPngRouterConfig -UpdateType]

    lappend RIPngRouterStatus "-testlinklocaladdr"                                 
    lappend RIPngRouterStatus $m_linkLocalAddr

    if {$args == ""} {
        debugPut "exit the proc of RIPngSession::RipngRetrieveRouter"

        return $RIPngRouterStatus
    } else {
        array set arr $RIPngRouterStatus
        foreach {name valueVar}  $args  {      

            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 
    
        debugPut "exit the proc of RIPngSession::RipngRetrieveRouter"

        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: RipngEnable
#Description: Enable a RIP simulation neighbour in a port
#Input: None
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngEnable {args} {
    
    set args [ConvertAttrToLowerCase $args]
     
    debugPut "enter the proc of RIPngSession::RipngEnable"

    stc::config  $m_hRouter -Active true  
    stc::config $m_hRIPngRouterConfig -Active true

    stc::apply 
    after 1000

    debugPut "exit the proc of RIPngSession::RipngEnable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngDisable
#Description: Disable a RIP simulation neighbour in a port
#Input: None
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngDisable {args} {
      
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngDisable"

    stc::config  $m_hRouter -active false 
    stc::config $m_hRIPngRouterConfig -Active false

    stc::apply 
    after 1000

    debugPut "exit the proc of RIPngSession::RipngDisable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngCreateRouteBlock
#Description: Add RouteBlock to RIPngRouter
#Input:  For details see API use documentation and HELP documentation
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngCreateRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngCreateRouteBlock"

    #Get the parameter value of BlockName
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RIPngSession::RipngCreateRouteBlock"
    }
       
     #Check Check whether router block to be configured exists in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index != -1} {
        error "The Route $BlockName you have set already exists, please select another one.\nexit the proc of RIPngSession::RipngCreateRouteBlock..."
    }
    
     #Get the parameter value of Metric
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
    } else  {
        set Metric $m_metric
    }
    set m_MetricList($BlockName) $Metric

    #Get the parameter value of RouteTag
    set index [lsearch $args -routetag] 
    if {$index != -1} {
        set RouteTag [lindex $args [expr $index + 1]]
    } else  {
        set RouteTag 0
    }
    set m_RouteTagList($BlockName) $RouteTag
    
    #Get the parameter value of NextHop
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NextHop [lindex $args [expr $index + 1]]
    } else  {
        set NextHop fe80::1
    }
    set m_NextHopList($BlockName) $NextHop

    #Get the parameter value of FlagFlap
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set FlagFlap [lindex $args [expr $index + 1]]
    } else  {
        set FlagFlap false
    }
    set m_FlagFlapList($BlockName) $FlagFlap 
 
    #Get the parameter value of StartIPAddress
    set index [lsearch $args -startipaddress] 
    if {$index != -1} {
        set StartIPAddress [lindex $args [expr $index + 1]]
    } else  {
        set StartIPAddress 3ffe::1
    }
    set m_StartIPAddressList($BlockName) $StartIPAddress

    #Get the parameter value of PrefixLength
    set index [lsearch $args -prefixlength] 
    if {$index != -1} {
        set PrefixLength [lindex $args [expr $index + 1]]
    } else  {
        set PrefixLength 64
    }
    set m_PrefixLengthList($BlockName) $PrefixLength

    set index [lsearch $args -number]
    if {$index != -1} {
       set Number [lindex $args [expr $index + 1]]
    } else {
       set Number 1
    }
    set m_NumberList($BlockName) $Number

    set index [lsearch $args -modify]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
    } else {
       set Modifier 1
    }
    set m_ModifierList($BlockName) $Modifier
 
    #Get the parameter value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }
    set m_ActiveList($BlockName) $Active

    #Get the parameter value of FlagTrafficDestination
    set index [lsearch $args -flagtrafficdestination] 
    if {$index != -1} {
        set FlagTrafficDestination [lindex $args [expr $index + 1]]
    } else  {
        set FlagTrafficDestination true
    }
    set m_FlagTrafficDestinationList($BlockName) $FlagTrafficDestination

    #Get the parameter value of FlagAdvertise
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
    } else  {
        set FlagAdvertise true
    }
    set m_FlagAdvertiseList($BlockName) $FlagAdvertise

    set RipngRouteParams [stc::create RipngRouteParams \
          -under $m_hRIPngRouterConfig \
          -NextHop $NextHop \
          -Metric $Metric \
          -RouteTag $RouteTag \
          -RouteCategory "UNDEFINED" \
          -Active $Active \
          -Name $BlockName ]

    set Ipv6NetworkBlock [lindex [stc::get $RipngRouteParams -children-Ipv6NetworkBlock] 0]
    stc::config $Ipv6NetworkBlock \
          -StartIpList $StartIPAddress \
          -PrefixLength $PrefixLength \
          -NetworkCount $Number \
          -AddrIncrement $Modifier \
          -Active $Active \
          -Name "Ipv6NetworkBlock$BlockName"

    #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }
    
    #Add the created router block to Router's list
    lappend m_RouteBlockNameList $BlockName
    set m_RouteHandleList($BlockName) $RipngRouteParams
    
    debugPut "exit the proc of RIPngSession::RipngCreateRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngDeleteRouteBlock
#Description: Delete RouteBlock
#Input:  BlockName BlockName  Mandatory parameters，the name of RouteBlock，for example -BlockName routeblock1
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngDeleteRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngDeleteRouteBlock"

    #Get the parameter value of RouteBlockName
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RIPngSession::RipngDeleteRouteBlock"
    }
    
    #Delete the Route Block object
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RIPngSession::RipngDeleteRouteBlock..."
    }
    
    stc::delete $m_RouteHandleList($BlockName)
    unset m_RouteHandleList($BlockName)
    set m_RouteBlockNameList [lreplace $m_RouteBlockNameList $index $index]

    debugPut "exit the proc of RIPngSession::RipngDeleteRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngListRouteBlock
#Description: Display all RouteBlock of RIPngRouter
#Input: RouteBlockNameList RouteBlockNameList Mandatory parameters，name list of RouteBlock，for example -RouteBlockNameList routeblocklist1
#Output: RouteBlockList.
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngListRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of RIPngSession::RipngListRouteBlock"

    set RouterBlockList ""
    lappend RouterBlockList "-blocknamelist"                                 
    lappend RouterBlockList $m_RouteBlockNameList
        
    array set arr $RouterBlockList
    foreach {name valueVar}  $args {      

         set ::mainDefine::gAttrValue $arr($name)

         set ::mainDefine::gVar $valueVar
         uplevel 1 {
             set $::mainDefine::gVar $::mainDefine::gAttrValue
         }           
    } 

    debugPut "exit the proc of RIPngSession::RipngListRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngSetRouteBlock
#Description: Configure RouteBlock
#Input:  For details see API use documentation and HELP documentation
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngSetRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of RIPngSession::RipngSetRouteBlock"

    #Get the parameter value of BlockName
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RIPngSession::RipngSetRouteBlock"
    }
      
    #Check whether router block to be configured exists in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RIPng::RipngSetRouteBlock..."
    }

    #Get the parameter value of Metric
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
        set m_MetricList($BlockName) $Metric
    } else  {
        set Metric $m_MetricList($BlockName)
    }

    #Get the parameter value of RouteTag
    set index [lsearch $args -routetag] 
    if {$index != -1} {
        set RouteTag [lindex $args [expr $index + 1]]
        set $m_RouteTagList($BlockName) $RouteTag
    } else  {
        set RouteTag $m_RouteTagList($BlockName)
    }

    #Get the parameter value of NextHop
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NextHop [lindex $args [expr $index + 1]]
        set m_NextHopList($BlockName) $NextHop
    } else  {
        set NextHop $m_NextHopList($BlockName)
    }

    #Get the parameter value of FlagFlap
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set FlagFlap [lindex $args [expr $index + 1]]
        set m_FlagFlapList($BlockName) $FlagFlap 
    } else  {
        set FlagFlap $m_FlagFlapList($BlockName)
    }

    #Get the parameter value of StartIPAddress
    set index [lsearch $args -startipaddress] 
    if {$index != -1} {
        set StartIPAddress [lindex $args [expr $index + 1]]
        set m_StartIPAddressList($BlockName) $StartIPAddress 
    } else  {
        set StartIPAddress $m_StartIPAddressList($BlockName)
    }

    #Get the parameter value of PrefixLength
    set index [lsearch $args -prefixlength] 
    if {$index != -1} {
        set PrefixLength [lindex $args [expr $index + 1]]
        set m_PrefixLengthList($BlockName) $PrefixLength
    } else  {
        set PrefixLength $m_PrefixLengthList($BlockName)
    }
    
    #Get the parameter value of Number
    set index [lsearch $args -number]
    if {$index != -1} {
       set Number [lindex $args [expr $index + 1]]
       set m_NumberList($BlockName) $Number
    } else {
       set Number $m_NumberList($BlockName)
    }

    #Get the parameter value of Modifier
    set index [lsearch $args -modify]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
       set m_ModifierList($BlockName) $Modifier
    } else {
       set Modifier $m_ModifierList($BlockName)
    }

    #Get the parameter value of Active
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_ActiveList($BlockName) $Active
    } else  {
        set Active $m_ActiveList($BlockName)
    }

    #Get the parameter value of FlagTrafficDestination
    set index [lsearch $args -flagtrafficdestination] 
    if {$index != -1} {
        set FlagTrafficDestination [lindex $args [expr $index + 1]]
        set m_FlagTrafficDestinationList($BlockName) $FlagTrafficDestination
    } else  {
        set FlagTrafficDestination $m_FlagTrafficDestinationList($BlockName) 
    }

    #Get the parameter value of FlagAdvertise
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
        set m_FlagAdvertiseList($BlockName) $FlagAdvertise
    } else  {
        set FlagAdvertise $m_FlagAdvertiseList($BlockName) 
    }
    
    set RipngRouteParams $m_RouteHandleList($BlockName) 
    
    #Configure the found router block
    stc::config $RipngRouteParams  -NextHop $NextHop \
          -Metric $Metric \
          -RouteTag $RouteTag \
          -RouteCategory "UNDEFINED" \
          -Active $Active \
          -Name $BlockName 

    set Ipv6NetworkBlock [lindex [stc::get $RipngRouteParams -children-Ipv6NetworkBlock] 0]
    stc::config $Ipv6NetworkBlock \
          -StartIpList $StartIPAddress \
          -PrefixLength $PrefixLength \
          -NetworkCount $Number \
          -AddrIncrement $Modifier \
          -Active $Active \
          -Name "Ipv6NetworkBlock$m_routerName"

    #Download configuration
    set errorCode 1
    if {[catch {
        set errorCode [stc::apply]
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of RIPngSession::RipngSetRouteBlock"
 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngRetrieveRouteBlock
#Description: Get the parameter of RIP router
#Input:  For details see API use documentation and HELP documentation
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngRetrieveRouteBlock {args} {
   
    set args [ConvertAttrToLowerCase $args]
     
    debugPut "enter the proc of RIPngSession::RipngRetrieveRouteBlock"

    #Get the parameter value of BlockName
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RIPngSession::RipngRetrieveRouteBlock"
    }

    #Check whether router block to be configured exists in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RIPngSession::RipngRetrieveRouteBlock..."
    }
    
    set RipngRouteParams $m_RouteHandleList($BlockName) 

    set RIPngRouterBlockConfig ""

    #Get the configuration result of Ripng Router Block
    lappend RIPngRouterBlockConfig "-blockname"                                 
    lappend RIPngRouterBlockConfig $BlockName

    lappend RIPngRouterBlockConfig "-metric"                                 
    lappend RIPngRouterBlockConfig [stc::get $RipngRouteParams -Metric]

    lappend RIPngRouterBlockConfig "-nexthop"                                 
    lappend RIPngRouterBlockConfig [stc::get $RipngRouteParams -NextHop]

    lappend RIPngRouterBlockConfig "-routetag"                                 
    lappend RIPngRouterBlockConfig [stc::get $RipngRouteParams -RouteTag]
    
    lappend RIPngRouterBlockConfig "-active"                                 
    lappend RIPngRouterBlockConfig [stc::get $RipngRouteParams -Active]

    lappend RIPngRouterBlockConfig "-flagflap"                                
    lappend RIPngRouterBlockConfig $m_FlagFlapList($BlockName)

    set Ipv6NetworkBlock [lindex [stc::get $RipngRouteParams -children-Ipv6NetworkBlock] 0]

    lappend RIPngRouterBlockConfig "-prefixlength"                                
    lappend RIPngRouterBlockConfig [stc::get $Ipv6NetworkBlock -PrefixLength]

    lappend RIPngRouterBlockConfig "-startipaddress"                                
    lappend RIPngRouterBlockConfig [stc::get $Ipv6NetworkBlock -StartIpList]

    lappend RIPngRouterBlockConfig "-number"                                
    lappend RIPngRouterBlockConfig [stc::get $Ipv6NetworkBlock -NetworkCount]

    lappend RIPngRouterBlockConfig "-modify"                                
    lappend RIPngRouterBlockConfig [stc::get $Ipv6NetworkBlock -AddrIncrement]

    set args [lrange $args 2 end] 

    if {$args == ""} {
        debugPut "exit the proc of  RIPngSession::RipngRetrieveRouteBlock"
        return $RIPngRouterBlockConfig
    } else { 

       #According to input parameter, set the corresponding value
       array set arr $RIPngRouterBlockConfig
       foreach {name valueVar}  $args {
           set ::mainDefine::gAttrValue $arr($name)

           set ::mainDefine::gVar $valueVar
           uplevel 1 {
               set $::mainDefine::gVar $::mainDefine::gAttrValue
           }           
       } 

      debugPut "exit the proc of RIPngSession::RipngRetrieveRouteBlock"

      return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: RipngAdvertiseRouteBlock
#Description: Advertise RIP routing
#Input:  None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngAdvertiseRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngAdvertiseRouteBlock"
    
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RipReadvertiseRoute -RouterList $m_hRIPngRouterConfig]
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of RIPngSession::RipngAdvertiseRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngWithdrawRouteBlock
#Description: Withdraw Rip routing
#Input: 
#              (1) BlockName BlockName  Mandatory parameters，identification of Rip router block，for example -BlockName routeblock1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngWithdrawRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of RIPngSession::RipngWithdrawRouteBlock"

    #Get the parameter value of BlockName
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RIPngSession::RipngWithdrawRouteBlock"
    }
    
    #Check whether router block to be configured exists in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RIPngSession::RipngWithdrawRouteBlock..."
    }
    
    set RipngRouteParams $m_RouteHandleList($BlockName) 
    
    #Delete corresponding routing
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform RipWithdrawRoute -RouteList $RipngRouteParams]
    } err]} {
        return $errorCode
    }
    
    debugPut "exit the proc of RIPngSession::RipngWithdrawRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngStartFlapRouteBlock
#Description: Rip routing flap
#Input: None
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngStartFlapRouteBlock {args} {

     set args [ConvertAttrToLowerCase $args]

     debugPut "enter the proc of RIPngSession::RipngStartFlapRouteBlock"

     #Get the parameter value of FlapNumber
     set index [lsearch $args -flapnumber] 
     if {$index != -1} {
         set FlapNumber [lindex $args [expr $index + 1]]
     } else  {
         set FlapNumber 10
     }
     
     set RouteParamList ""
     for {set i 0} {$i < [llength $m_RouteBlockNameList]} {incr i} {
          set BlockName [lindex $m_RouteBlockNameList $i]
          set RipngRouteParams $m_RouteHandleList($BlockName) 
          set FlagFlap $m_FlagFlapList($BlockName) 
 
          if {[string tolower $FlagFlap] == "true"} {
                lappend RouteParamList $RipngRouteParams
          }            
     }

     if {$RouteParamList == "" } {
         puts "没有Route Block处于可进行震荡的状态"
         return $::mainDefine::gSuccess
     }

     #Create Scheduler
     if {$m_sequencer == ""} {
        set existing_sequencer [stc::get system1 -Children-Sequencer]
        if {$existing_sequencer == ""} { 
            set m_sequencer  [stc::create Sequencer -under system1 -Name "RipngScheduler$m_routerName"]
        } else {
            set m_sequencer $existing_sequencer
        }
     }

    stc::perform SequencerClear
    
    #Create loop cmd
    set hRipLoop [stc::create SequencerLoopCommand -under system1 -ContinuousMode FALSE -IterationCount $FlapNumber]

    #Create cmd of waiting for designated time before advertising Rip Route
    set hWaitBeforeAdv [stc::create WaitCommand -under $hRipLoop  -WaitTime $m_wadTimer]

    #Create cmd of advertising Rip Route
    set hAdvRoute [stc::create RipReadvertiseRouteCommand -under $hRipLoop -RouterList $m_hRIPngRouterConfig]

    #Create cmd of waiting for designated time before withdrawing Rip Route
    set hWaitBeforeWithdraw [stc::create WaitCommand -under $hRipLoop -WaitTime $m_awdTimer]

    #Create cmd of withdrawing Rip Route
    set hWithdrawRoute [stc::create RipWithdrawRouteCommand -under $hRipLoop -RouteList $RouteParamList]

    #Insert to scheduler
    stc::perform SequencerInsert -CommandList $hRipLoop 
    #Insert cmd of advertising Rip Route to scheduler
    stc::perform SequencerInsert -CommandList $hAdvRoute -CommandParent $hRipLoop 
    #Insert cmdscheduler of waiting for designated time before withdrawing Rip Route
    stc::perform SequencerInsert -CommandList $hWaitBeforeWithdraw -CommandParent $hRipLoop 
    #Insert cmdscheduler of withdrawing Rip Route
    stc::perform SequencerInsert -CommandList $hWithdrawRoute  -CommandParent $hRipLoop 

    #Insert cmdscheduler of waiting for designated time before advertising Rip Route
    stc::perform SequencerInsert -CommandList $hWaitBeforeAdv  -CommandParent $hRipLoop 

    #Start Sequencer        
    stc::perform SequencerStart

    debugPut "exit the proc of RIPngSession::RipngStartFlapRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipngStopFlapRouteBlock
#Description: Stop the Rip routing flap
#Input:  None
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngStopFlapRouteBlock {args} {
    set args [ConvertAttrToLowerCase $args]
 
    debugPut "enter the proc of RIPngSession::RipngStopFlapRouteBlock"

    #Stop Sequencer        
    stc::perform SequencerStop

    debugPut "exit the proc of RIPngSession::RipngStopFlapRouteBlock"

    return $::mainDefine::gSuccess

}

############################################################################
#APIName: RipngSetFlapRouteBlock
#Description: Configure the Rip routing flap
#Input:  
#                (1) AWDTimer Optional parameters，Spacing interval between finishing advertising and starting withdrawing ，default value is 5000ms，for example -AWDTimer timer1
#                (2) WADTimer Optional parameters，Spacing interval between finishing withdrawing and starting advertising again，default value is 5000ms，for example -WADTimer timer2
#Output: success  return 0
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngSetFlapRouteBlock {args} {
     set args [ConvertAttrToLowerCase $args]
 
     debugPut "enter the proc of RIPngSession::RipngSetFlapRouteBlock"

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
    
    set m_awdTimer $AWDTimer

    #Get the parameter value of WADTimer
    set index [lsearch $args -wadtimer] 
    if {$index != -1} {
        set WADTimer [lindex $args [expr $index + 1]]
        set WADTimer [expr $WADTimer / 1000]
        if {$WADTimer == 0} {
             set WADTimer 1
        }
    } else  {
        set WADTimer 5
    }

    set m_wadTimer $WADTimer

    debugPut "exit the proc of RIPngSession::RipngSetFlapRouteBlock"

    return $::mainDefine::gSuccess

}

############################################################################
#APIName: RipngRetrieveRouterStats
#Description: Get relevant statistical result of Rip
#Input:  
#             (1) RxAdvertisedUpdateCount RxAdvertisedUpdateCount  Optional parameters
#             (2) RxWithdrawnUpdateCount RxWithdrawnUpdateCount  Optional parameters
#             (3) TxAdvertiseUpdateCount TxAdvertiseUpdateCount  Optional parameters
#             (4) TxWithdrawnUpdateCount TxWithdrawnUpdateCount  Optional parameters
#Output: Return the list of statistic
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngRetrieveRouterStats {args} {
     
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RIPngSession::RipngRetrieveRouterStats"
    
    set m_hRIPngRouterResult [stc::get $m_hRIPngRouterConfig -Children-RipRouterResults]
    #Get the result of Rip Router
    set RIPngRouterResult $m_hRIPngRouterResult 

    if {$RIPngRouterResult == ""} {
        error "You need to start the router before retrieving the result data"
    }

    set RIPngRouterStats ""
    lappend RIPngRouterStats "-rxadvertisedupdatecount"                                 
    lappend RIPngRouterStats [stc::get $RIPngRouterResult -RxAdvertisedUpdateCount]

    lappend RIPngRouterStats "-rxwithdrawnupdatecount"                                 
    lappend RIPngRouterStats [stc::get $RIPngRouterResult -RxWithdrawnUpdateCount]

    lappend RIPngRouterStats "-txadvertisedupdatecount"                                 
    lappend RIPngRouterStats [stc::get $RIPngRouterResult -TxAdvertisedUpdateCount]

    lappend RIPngRouterStats "-txwithdrawnupdatecount"                                 
    lappend RIPngRouterStats [stc::get $RIPngRouterResult -TxWithdrawnUpdateCount]
    
    if {$args == "" } {
        debugPut "exit the proc of RIPngSession::RipngRetrieveRouterStats"

        return $RIPngRouterStats
    } else {
        #According to input parameter, set the corresponding value
        array set arr $RIPngRouterStats
        foreach {name valueVar}  $args {      
 
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 
    
        debugPut "exit the proc of RIPngSession::RipngRetrieveRouterStats"

        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: RipngRetrieveRouterStatus
#Description: Get current state of Rip Router
#Input:  (1) Status Status  Optional parameters  
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RIPngSession::RipngRetrieveRouterStatus {args} {
      set args [ConvertAttrToLowerCase $args]

      debugPut "enter the proc of RIPngSession::RipngRetrieveRouterStatus"

      #Get current state of Ripng Router
      set RIPngRouterConfig [stc::get $m_hRouter -children-RipRouterConfig]

      set RIPngRouterStatus ""
      lappend RIPngRouterStatus "-status"                                 
      lappend RIPngRouterStatus [stc::get $RIPngRouterConfig -RouterState]

      set retValue [GetValuesFromArray $args $RIPngRouterStatus]

      debugPut "enter the proc of RIPngSession::RipngRetrieveRouterStatus"

      return $retValue
}