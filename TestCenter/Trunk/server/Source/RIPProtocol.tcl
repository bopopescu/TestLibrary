###################################################################################
#                                                                        
#  File Name£ºRIPProtocol.tcl                                                                                              
# 
#  Description£ºDefine RIP class and corresponding API implement                                      
# 
#  Author£º Tony
#
#  Create time:  2007.6.6
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

::itcl::class RipSession {
    #Inherit Router class
    inherit Router

    #Variable definitions
    public variable m_hPort
    public variable m_hProject
    public variable m_portName
    public variable m_hRouter
    public variable m_routerName
 
    public variable m_hRipRouterConfig
    public variable m_hRipRouterResult ""
    public variable m_hRipRouteGenParams 
    public variable m_Ipv4If  ""
    public variable m_hL2If  ""

    #Sequencer handler
    public variable m_sequencer ""

    #Route block list
    public variable m_RouteBlockNameList  ""
    public variable m_RouteHandleList 

    #Define the config information of Rip Router
    public variable m_suIp   "224.0.0.9"
    public variable m_testIp  "192.85.1.2"
    public variable m_metric   1
    public variable m_prefixLen 24
    public variable m_expirationInterval 180000
    public variable m_garbageInterval 120000
    public variable m_updateInterval 30000
    public variable m_triggedInterval 5000
    public variable m_updateControl false
    public variable m_routesPerUpdate  25
    public variable m_version "V2"
    public variable m_routerId "192.85.1.2"
    public variable m_updateType "MULTICAST"
    public variable m_active true
    public variable m_authentication "NONE"
    public variable m_md5KeyId 1
    public variable m_password "Spirent"

    #Configuraton related to Route Block
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

    #Parameter related to flap
    public variable m_awdTimer 5
    public variable m_wadTimer 5  

    public variable m_ResultDataSet
    public variable m_portType "ethernet"

    #Define constructor function
    constructor {routerName routerType routerId hRouter hPort portName hProject portType} \
     { Router::constructor $routerName $routerType $routerId $hRouter $portName $hProject} {     

        set m_routerName $routerName  
        set m_routerId $routerId     
        set m_hRouter $hRouter
        set m_hPort $hPort
        set m_portName $portName
        set m_hProject $hProject
        set m_portType $portType

        #Get Ipv4 interface
        set m_Ipv4If [stc::get $hRouter -children-Ipv4If]                                    
        set m_hIpAddress $m_Ipv4If 
      
        #Get Ethernet interface
        #added by yuanfen 8.9 2011
        if {[string tolower $portType]=="ethernet"} {
            set m_hL2If [stc::get $hRouter -children-EthIIIf]
            set m_hMacAddress $m_hL2If
        } else {
            if {[info exists [stc::get $hRouter -children-HdlcIf]]} {
                set m_hL2If [stc::get $hRouter -children-HdlcIf]
            } else {
                set m_hL2If [stc::get $hRouter -children-PppIf]
            }
        } 
      
        #Create RipRouterConfig and make default configuration
        set m_hRipRouterConfig [stc::create "RipRouterConfig" \
            -under $m_hRouter \
            -RipVersion $m_version \
            -UpdateType "MULTICAST" \
            -UpdateInterval 15 \
            -UpdateJitter "0" \
            -MaxRoutePerUpdate "25" \
            -InterUpdateDelay "10" \
            -ViewRoutes "FALSE" \
            -EnableEventLog "FALSE" \
            -DutIpv4Addr "224.0.0.9" \
            -DutIpv6Addr "::" \
            -UsePartialBlockState "FALSE" \
            -Active "TRUE" \
            -Name "RipRouterConfig$m_routerName" ]

        stc::config $m_hRipRouterConfig -UsesIf-targets $m_Ipv4If
    }

    #Define destructor function
    destructor {
    }

    #Declear function
    public method RipSetSession
    public method RipRetrieveRouter
    
    public method RipEnable
    public method RipDisable
    public method RipCreateRouteBlock    
    public method RipSetRouteBlock
    public method RipDeleteRouteBlock
    public method RipListRouteBlock
    public method RipRetrieveRouteBlock
    public method RipAdvertiseRouteBlock
    public method RipWithdrawRouteBlock
    public method RipStartFlapRouteBlock
    public method RipSetFlapRouteBlock 
    public method RipStopFlapRouteBlock
    public method RipRetrieveRouterStats
    public method RipRetrieveRouterStatus
}

############################################################################
#APIName: RipSetSession
#Description: Config RIP router according to the incoming parameter
#Input:  Details as API document
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipSetSession {args} {

    set args [ConvertAttrPlusValueToLowerCase $args]

    debugPut "enter the proc of RipSession::RipSetSession"

    #Get the value of parameter SutIP 
    set index [lsearch $args -sutip] 
    if {$index != -1} {
        set SuIp [lindex $args [expr $index + 1]]
        set m_suIp $SuIp
    } 
    
    #Get the value of parameter TestIP 
    set index [lsearch $args -testip] 
    if {$index != -1} {
        set TestIp [lindex $args [expr $index + 1]]
        set m_testIp $TestIp
    } 
     
    #Get the value of parameter PrefixLen 
    set index [lsearch $args -prefixlen] 
    if {$index != -1} {
        set PrefixLen [lindex $args [expr $index + 1]]
        set m_prefixLen $PrefixLen
    } 
    
    #Get the value of parameter Metric 
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
        set m_metric $Metric
    } 
    
    #Get the value of parameter UpdateInterval 
    set index [lsearch $args -updateinterval] 
    if {$index != -1} {
        set UpdateInterval [lindex $args [expr $index + 1]]
        set m_updateInterval $UpdateInterval
    } 
    
    #Get the value of parameter Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set active [lindex $args [expr $index + 1]]
    } else {
        set active true
    }
    set m_active $active
    set active [string map {0 false} $active]
    set active [string map {disable false} $active]
    set active [string map {off false} $active]
    set active [string map {1 true} $active]
    set active [string map {enable true} $active]
    set active [string map {on true} $active]
    set active [string map {on true} $active] 
     
   #Get the value of parameter RoutesPerUpdate 
    set index [lsearch $args -routesperupdate] 
    if {$index != -1} {
        set RoutesPerUpdate [lindex $args [expr $index + 1]]
        set m_routesPerUpdate $RoutesPerUpdate
    } 
 
    #Get the value of parameter Version 
    set index [lsearch $args -version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
        set m_version $Version
    } 
 
    #Get the value of parameter UpdateType 
    set index [lsearch $args -updatetype] 
    if {$index != -1} {
        set UpdateType [lindex $args [expr $index + 1]]
        set m_updateType $UpdateType
    } 

    #Get the value of parameter Authentication 
    set index [lsearch $args -authentication] 
    if {$index != -1} {
        set Authentication [lindex $args [expr $index + 1]]
        set m_authentication $Authentication
    } 

   #Get the value of parameter Md5KeyId 
    set index [lsearch $args -md5keyid] 
    if {$index != -1} {
        set Md5KeyId [lindex $args [expr $index + 1]]
        set m_md5KeyId $Md5KeyId
    } 

    #Get the value of parameter Password 
    set index [lsearch $args -password] 
    if {$index != -1} {
        set Password [lindex $args [expr $index + 1]]
        set m_password $Password
    } 

    stc::config $m_hRouter -RouterId $m_routerId -Active $m_active

    set RipRouterConfig [stc::get $m_hRouter -children-RipRouterConfig]

    set UpdateInterval [expr $m_updateInterval / 1000] 
    if {$UpdateInterval == 0} {
          set UpdateInterval 1
    }

    stc::config $RipRouterConfig -RipVersion $m_version \
                 -UpdateType $m_updateType \
                 -UpdateInterval $UpdateInterval \
                 -MaxRoutePerUpdate $m_routesPerUpdate \
                 -Active $m_active \
                 -DutIpv4Addr $m_suIp \
                 -ViewRoutes "FALSE" \
                 -EnableEventLog "FALSE" 
  
    set RipAuthenticationParams [lindex [stc::get $RipRouterConfig -children-RipAuthenticationParams] 0]
    stc::config $RipAuthenticationParams \
        -Authentication $m_authentication \
        -Password $m_password \
        -Md5KeyId $m_md5KeyId \
        -Active "TRUE"                                           
    
    #Get the value of parameter gateway 
    set index [lsearch $args -gateway] 
    if {$index != -1} {
        set gateway [lindex $args [expr $index + 1]]
        set Gateway $gateway
    } else {
        #Set the IP address according to testIp
        set Gateway [ GetGatewayIp $m_testIp] 
    }

    stc::config $m_Ipv4If -Address $m_testIp -Gateway $Gateway -PrefixLength $m_prefixLen

    #Find and config the Mac address from Host according to testIp
    SetMacAddress $m_testIp

    #Define the link between objects 
    stc::config $m_hRouter -AffiliationPort-targets $m_hPort
    stc::config $m_hRouter -RouterId $m_routerId -TopLevelIf-targets $m_Ipv4If 
    stc::config $m_hRouter -RouterId $m_routerId -PrimaryIf-targets  $m_Ipv4If 
    stc::config $m_hRipRouterConfig -UsesIf-targets $m_Ipv4If 

    #Apply and check the configuration
    #ApplyValidationCheck

    debugPut "exit the proc of RipSession::RipSetSession"

    return $::mainDefine::gSuccess
  
}

############################################################################
#APIName: RipRetrieveRouter
#Description: Get the router parameter according to incoming parameter
#Input: Details as API document
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipRetrieveRouter {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipRetrieveRouter"

    set RipRouterStatus "" 
  
    lappend RipRouterStatus "-sutip"                                 
    lappend RipRouterStatus $m_suIp 
              
    lappend RipRouterStatus "-testip"                                 
    lappend RipRouterStatus $m_testIp 
        
    lappend RipRouterStatus "-prefixlen"                                 
    lappend RipRouterStatus [stc::get $m_Ipv4If -PrefixLength]
    
    lappend RipRouterStatus "-metric"                                 
    lappend RipRouterStatus $m_metric
    
    set UpdateInterval [stc::get $m_hRipRouterConfig -UpdateInterval]
    lappend RipRouterStatus "-updateinterval"                                 
    lappend RipRouterStatus [expr $UpdateInterval * 1000]
    
    lappend RipRouterStatus "-version"                                 
    lappend RipRouterStatus [stc::get $m_hRipRouterConfig -RipVersion]

    lappend RipRouterStatus "-state"                                 
    lappend RipRouterStatus  [stc::get $m_hRipRouterConfig -RouterState]

    lappend RipRouterStatus "-routesperupdate"                                 
    lappend RipRouterStatus [stc::get $m_hRipRouterConfig -MaxRoutePerUpdate]

    lappend RipRouterStatus "-active"                                 
    lappend RipRouterStatus [stc::get $m_hRipRouterConfig -Active]

    lappend RipRouterStatus "-routerid"                                 
    lappend RipRouterStatus $m_routerId

    lappend RipRouterStatus "-updatetype"                                 
    lappend RipRouterStatus [stc::get $m_hRipRouterConfig -UpdateType]

    set RipAuthenticationParams [lindex [stc::get $m_hRipRouterConfig -children-RipAuthenticationParams] 0]

    lappend RipRouterStatus "-authentication"                                 
    lappend RipRouterStatus [stc::get $RipAuthenticationParams -Authentication]

    lappend RipRouterStatus "-password"                                 
    lappend RipRouterStatus [stc::get $RipAuthenticationParams -Password]

    lappend RipRouterStatus "-md5keyid"                                 
    lappend RipRouterStatus [stc::get $RipAuthenticationParams -Md5KeyId]

    if {$args == "" } {
        debugPut "exit the proc of RipSession::RipRetrieveRouter"

        return $RipRouterStatus
    } else {
        array set arr $RipRouterStatus
        foreach {name valueVar}  $args  {      
 
            set ::mainDefine::gAttrValue $arr($name)
            puts $arr($name)
            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 
    
        debugPut "exit the proc of RipSession::RipRetrieveRouter"

        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: RipEnable
#Description: Enable a RIP simulating neighbour on a port
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipEnable {args} {
    
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipEnable"

    stc::config  $m_hRouter -Active true  
    stc::config $m_hRipRouterConfig -Active true

    #Apply and check the configuration
    ApplyValidationCheck

    debugPut "exit the proc of RipSession::RipEnable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipDisable
#Description: Disable a RIP simulating neighbour on a port
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipDisable {args} {
      
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipDisable"

    stc::config  $m_hRouter -active false 
    stc::config $m_hRipRouterConfig -Active false

    #Apply and check the configuration
    ApplyValidationCheck

    debugPut "exit the proc of RipSession::RipDisable"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipCreateRouteBlock
#Description: Create RouteBlock for RipSession
#Input: Details as API document
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipCreateRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipCreateRouteBlock"

    #Get the value of parameter BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName\nexit the proc of RipSession::RipCreateRouteBlock"
    }
    
     #Check whether the router block waiting for configuration is in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index != -1} {
        error "The Route $BlockName you have set already exists, please select another one.\nexit the proc of RipSession::RipCreateRouteBlock..."
    }
    
    #Get the value of parameter Metric 
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
    } else  {
        set Metric 1
    }
    set m_MetricList($BlockName) $Metric

    #Get the value of parameter RouteTag 
    set index [lsearch $args -routetag] 
    if {$index != -1} {
        set RouteTag [lindex $args [expr $index + 1]]
    } else  {
        set RouteTag 0
    }
    set m_RouteTagList($BlockName) $RouteTag
    
    #Get the value of parameter NextHop 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NextHop [lindex $args [expr $index + 1]]
    } else  {
        set NextHop 192.85.0.1
    }
    set m_NextHopList($BlockName) $NextHop

    #Get the value of parameter FlagFlap 
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set FlagFlap [lindex $args [expr $index + 1]]
    } else  {
        set FlagFlap false
    }
    set m_FlagFlapList($BlockName) $FlagFlap 
 
    #Get the value of parameter StartIPAddress 
    set index [lsearch $args -startipaddress] 
    if {$index != -1} {
        set StartIPAddress [lindex $args [expr $index + 1]]
    } else  {
        set StartIPAddress 10.0.0.1
    }
    set m_StartIPAddressList($BlockName) $StartIPAddress

    #Get the value of parameter PrefixLength  
    set index [lsearch $args -prefixlength] 
    if {$index != -1} {
        set PrefixLength [lindex $args [expr $index + 1]]
    } else  {
        set PrefixLength 24
    }
    set m_PrefixLengthList($BlockName) $PrefixLength

    set index [lsearch $args -number]
    if {$index != -1} {
       set Number [lindex $args [expr $index + 1]]
    } else {
       set Number 1
    }
    set m_NumberList($BlockName) $Number

    set index [lsearch $args -modifier]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
    } else {
       set Modifier 1
    }
    set m_ModifierList($BlockName) $Modifier
 
    #Get the value of parameter Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
    } else  {
        set Active true
    }
    set m_ActiveList($BlockName) $Active

    #Get the value of parameter FlagTrafficDestination 
    set index [lsearch $args -flagtrafficdestination] 
    if {$index != -1} {
        set FlagTrafficDestination [lindex $args [expr $index + 1]]
    } else  {
        set FlagTrafficDestination true
    }
    set m_FlagTrafficDestinationList($BlockName) $FlagTrafficDestination

    #Get the value of parameter FlagAdvertise 
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
    } else  {
        set FlagAdvertise true
    }
    set m_FlagAdvertiseList($BlockName) $FlagAdvertise

    set Ripv4RouteParams [stc::create Ripv4RouteParams \
          -under $m_hRipRouterConfig \
          -NextHop $NextHop \
          -Metric $Metric \
          -RouteTag $RouteTag \
          -RouteCategory "UNDEFINED" \
          -Active $Active \
          -Name $BlockName ]

    set Ipv4NetworkBlock [lindex [stc::get $Ripv4RouteParams -children-Ipv4NetworkBlock] 0]
    stc::config $Ipv4NetworkBlock \
          -StartIpList $StartIPAddress \
          -PrefixLength $PrefixLength \
          -NetworkCount $Number \
          -AddrIncrement $Modifier \
          -Active $Active \
          -Name "Ipv4NetworkBlock$BlockName"

    #added by Andy.zhang 4.10 2012
    set ::mainDefine::gPoolCfgBlock($BlockName) $Ipv4NetworkBlock

    #Add the created router block to the Route list
    lappend m_RouteBlockNameList $BlockName
    set m_RouteHandleList($BlockName) $Ripv4RouteParams

    #Apply and check the configuration
    #ApplyValidationCheck
        
    debugPut "exit the proc of RipSession::RipCreateRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipDeleteRouteBlock
#Description: Delete RouteBlock
#Input:  
#             (1) BlockName BlockName Required parameters, RouteBlock name, for example -BlockName routeblock1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipDeleteRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipDeleteRouteBlock"

    #Get the value of parameter RouteBlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RipSession::RipDeleteRouteBlock"
    }
    
    #Delete object of Route Block
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RipSession::RipDeleteRouteBlock..."
    }
    
    stc::delete $m_RouteHandleList($BlockName)
    unset m_RouteHandleList($BlockName)
    set m_RouteBlockNameList [lreplace $m_RouteBlockNameList $index $index]

    debugPut "exit the proc of RipSession::RipDeleteRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipListRouteBlock
#Description: List all RouteBlock of RipSession
#Input: 
#            (1) RouteBlockNameList RouteBlockNameList Required parameters, RouteBlock name list, for example -RouteBlockNameList routeblocklist1
#Output: RouteBlockList.
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipListRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of RipSession::RipListRouteBlock"

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

    debugPut "exit the proc of RipSession::RipListRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipSetRouteBlock
#Description: Config RouteBlock
#Input:  Details as API document
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipSetRouteBlock {args} {

  set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipSetRouteBlock"

    #Get the value of parameter BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName"
    }
  
    #Check whether the router block waiting for configuration is in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RipSession::RipSetRouteBlock..."
    }
       
    #Get the value of parameter Metric 
    set index [lsearch $args -metric] 
    if {$index != -1} {
        set Metric [lindex $args [expr $index + 1]]
        set m_MetricList($BlockName) $Metric
    } else  {
        set Metric $m_MetricList($BlockName)
    }

    #Get the value of parameter RouteTag 
    set index [lsearch $args -routetag] 
    if {$index != -1} {
        set RouteTag [lindex $args [expr $index + 1]]
        set $m_RouteTagList($BlockName) $RouteTag
    } else  {
        set RouteTag $m_RouteTagList($BlockName)
    }

    #Get the value of parameter NextHop 
    set index [lsearch $args -nexthop] 
    if {$index != -1} {
        set NextHop [lindex $args [expr $index + 1]]
        set m_NextHopList($BlockName) $NextHop
    } else  {
        set NextHop $m_NextHopList($BlockName)
    }

    #Get the value of parameter FlagFlap 
    set index [lsearch $args -flagflap] 
    if {$index != -1} {
        set FlagFlap [lindex $args [expr $index + 1]]
        set m_FlagFlapList($BlockName) $FlagFlap 
    } else  {
        set FlagFlap $m_FlagFlapList($BlockName)
    }

    #Get the value of parameter StartIPAddress 
    set index [lsearch $args -startipaddress] 
    if {$index != -1} {
        set StartIPAddress [lindex $args [expr $index + 1]]
        set m_StartIPAddressList($BlockName) $StartIPAddress 
    } else  {
        set StartIPAddress $m_StartIPAddressList($BlockName)
    }

    #Get the value of parameter PrefixLength  
    set index [lsearch $args -prefixlength] 
    if {$index != -1} {
        set PrefixLength [lindex $args [expr $index + 1]]
        set m_PrefixLengthList($BlockName) $PrefixLength
    } else  {
        set PrefixLength $m_PrefixLengthList($BlockName)
    }
    
    #Get the value of parameter Number 
    set index [lsearch $args -number]
    if {$index != -1} {
       set Number [lindex $args [expr $index + 1]]
       set m_NumberList($BlockName) $Number
    } else {
       set Number $m_NumberList($BlockName)
    }

    #Get the value of parameter Modifier 
    set index [lsearch $args -modifier]
    if {$index != -1} {
       set Modifier [lindex $args [expr $index + 1]]
       set m_ModifierList($BlockName) $Modifier
    } else {
       set Modifier $m_ModifierList($BlockName)
    }

    #Get the value of parameter Active 
    set index [lsearch $args -active] 
    if {$index != -1} {
        set Active [lindex $args [expr $index + 1]]
        set m_ActiveList($BlockName) $Active
    } else  {
        set Active $m_ActiveList($BlockName)
    }

    #Get the value of parameter FlagTrafficDestination 
    set index [lsearch $args -flagtrafficdestination] 
    if {$index != -1} {
        set FlagTrafficDestination [lindex $args [expr $index + 1]]
        set m_FlagTrafficDestinationList($BlockName) $FlagTrafficDestination
    } else  {
        set FlagTrafficDestination $m_FlagTrafficDestinationList($BlockName) 
    }

    #Get the value of parameter FlagAdvertise 
    set index [lsearch $args -flagadvertise] 
    if {$index != -1} {
        set FlagAdvertise [lindex $args [expr $index + 1]]
        set m_FlagAdvertiseList($BlockName) $FlagAdvertise
    } else  {
        set FlagAdvertise $m_FlagAdvertiseList($BlockName) 
    }
    
    set Ripv4RouteParams $m_RouteHandleList($BlockName) 
   
    #Config the routerblock found
    stc::config $Ripv4RouteParams -NextHop $NextHop  \
          -Metric $Metric \
          -RouteTag $RouteTag \
          -RouteCategory "UNDEFINED" \
          -Active $Active \
          -Name $BlockName 
 
    set Ipv4NetworkBlock [lindex [stc::get $Ripv4RouteParams -children-Ipv4NetworkBlock] 0]
    stc::config $Ipv4NetworkBlock \
          -StartIpList $StartIPAddress \
          -PrefixLength $PrefixLength \
          -NetworkCount $Number \
          -AddrIncrement $Modifier \
          -Active $Active \
          -Name "Ipv4NetworkBlock$m_routerName"

    #Apply and check the configuration
    #ApplyValidationCheck
    
    debugPut "exit the proc of RipSession::RipSetRouteBlock"
 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipRetrieveRouteBlock
#Description: Get the parameter of Rip router block 
#Input: Details as API document
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipRetrieveRouteBlock {args} {
   
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipRetrieveRouteBlock"

    #Get the value of parameter BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName"
    }

    #Check whether the router block waiting for configuration is in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RipSession::RipRetrieveRouteBlock..."
    }
    
    set Ripv4RouteParams $m_RouteHandleList($BlockName) 

    set RipRouterBlockConfig ""

    #Get the configuration result of Rip Router Block
    lappend RipRouterBlockConfig "-blockname"                                 
    lappend RipRouterBlockConfig $BlockName

    lappend RipRouterBlockConfig "-metric"                                 
    lappend RipRouterBlockConfig [stc::get $Ripv4RouteParams -Metric]

    lappend RipRouterBlockConfig "-nexthop"                                 
    lappend RipRouterBlockConfig [stc::get $Ripv4RouteParams -NextHop]

    lappend RipRouterBlockConfig "-routetag"                                 
    lappend RipRouterBlockConfig [stc::get $Ripv4RouteParams -RouteTag]
    
    lappend RipRouterBlockConfig "-active"                                 
    lappend RipRouterBlockConfig [stc::get $Ripv4RouteParams -Active]

    lappend RipRouterBlockConfig "-flagflap"                                
    lappend RipRouterBlockConfig $m_FlagFlapList($BlockName)

    set Ipv4NetworkBlock [lindex [stc::get $Ripv4RouteParams -children-Ipv4NetworkBlock] 0]

    lappend RipRouterBlockConfig "-prefixlength"                                
    lappend RipRouterBlockConfig [stc::get $Ipv4NetworkBlock -PrefixLength]

    lappend RipRouterBlockConfig "-startipaddress"                                
    lappend RipRouterBlockConfig [stc::get $Ipv4NetworkBlock -StartIpList]

    lappend RipRouterBlockConfig "-number"                                
    lappend RipRouterBlockConfig [stc::get $Ipv4NetworkBlock -NetworkCount]

    lappend RipRouterBlockConfig "-modifier"                                
    lappend RipRouterBlockConfig [stc::get $Ipv4NetworkBlock -AddrIncrement]

    set args [lrange $args 2 end] 
   
    if {$args == ""} {
        debugPut "exit the proc of RipSession::RipRetrieveRouteBlock"
        return $RipRouterBlockConfig
    } else { 
        #Set the value according to the input parameter
        array set arr $RipRouterBlockConfig
        foreach {name valueVar}  $args {      

            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 

        debugPut "exit the proc of RipSession::RipRetrieveRouteBlock"

        return $::mainDefine::gSuccess
   }
}

############################################################################
#APIName: RipAdvertiseRouteBlock
#Description: Advertise Rip router
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipAdvertiseRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipAdvertiseRouteBlock"
    #Advertise router
    stc::perform RipReadvertiseRoute -RouterList $m_hRipRouterConfig

    debugPut "exit the proc of RipSession::RipAdvertiseRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipWithdrawRouteBlock
#Description: Withdraw Rip router
#Input:  
#           (1) BlockName BlockName Required parameters, handler of Rip router block£¬for example -BlockName routeblock1
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipWithdrawRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]
    
    debugPut "enter the proc of RipSession::RipWithdrawRouteBlock"

    #Get the value of parameter BlockName 
    set index [lsearch $args -blockname] 
    if {$index != -1} {
        set BlockName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the BlockName.\nexit the proc of RipSession::RipWithdrawRouteBlock"
    }
    
    #Check whether the router block waiting for configuration is in the list
    set index [lsearch $m_RouteBlockNameList $BlockName] 
    if {$index == -1} {
        error "Can not find the Route BlockName you have set,please set another one.\nexit the proc of RipSession::RipWithdrawRouteBlock..."
    }
    
    set Ripv4RouteParams $m_RouteHandleList($BlockName) 
    
    #Withdraw route
    stc::perform RipWithdrawRoute -RouteList $Ripv4RouteParams
    
    debugPut "exit the proc of RipSession::RipWithdrawRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipStartFlapRouteBlock
#Description: Rip router flap
#Input: None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipStartFlapRouteBlock {args} {

    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipStartFlapRouteBlock"

    #Get the value of parameter FlapNumber 
    set index [lsearch $args -flapnumber] 
    if {$index != -1} {
        set FlapNumber [lindex $args [expr $index + 1]]
    } else  {
        set FlapNumber 10
    }
 
    set RouteParamList ""
    for {set i 0} {$i < [llength $m_RouteBlockNameList]} {incr i} {
         set BlockName [lindex $m_RouteBlockNameList $i]
         set Ripv4RouteParams $m_RouteHandleList($BlockName) 
         set FlagFlap $m_FlagFlapList($BlockName) 
 
         if {[string tolower $FlagFlap] == "true"} {
             lappend RouteParamList $Ripv4RouteParams
         }            
    }

    if {$RouteParamList == "" } {
         puts "There is no Route Block able to flap"
         return $::mainDefine::gSuccess
    }

    #Create Scheduler
    if {$m_sequencer == ""} {
        set existing_sequencer [stc::get system1 -Children-Sequencer]
        if {$existing_sequencer == ""} { 
            set m_sequencer  [stc::create Sequencer -under system1 -Name "RipScheduler$m_routerName"]
        } else {
            set m_sequencer $existing_sequencer
        }
    }

    stc::perform SequencerClear
    
    #Create cyclic cmd
    set hRipLoop [stc::create SequencerLoopCommand -under system1 -ContinuousMode FALSE -IterationCount $FlapNumber]
    set m_hSequencerCmdLoop $hRipLoop

    #Create the waiting time cmd before advertising Rip Route
    set hWaitBeforeAdv [stc::create WaitCommand -under $hRipLoop  -WaitTime $m_wadTimer]

    #Create cmd for advertising Rip Route
    set hAdvRoute [stc::create RipReadvertiseRouteCommand -under $hRipLoop -RouterList $m_hRipRouterConfig]

    #Create the waiting time cmd before withdrawing Rip Route
    set hWaitBeforeWithdraw [stc::create WaitCommand -under $hRipLoop -WaitTime $m_awdTimer]

    #Create cmd for withdrawing Rip Route
    set hWithdrawRoute [stc::create RipWithdrawRouteCommand -under $hRipLoop -RouteList $RouteParamList]

    stc::perform SequencerInsert -CommandList $hRipLoop 
    #Insert the cmd for advertising Router into scheduler
    stc::perform SequencerInsert -CommandList $hAdvRoute -CommandParent $hRipLoop 
    #Insert the waiting time cmd before withdrawing Router into scheduler
    stc::perform SequencerInsert -CommandList $hWaitBeforeWithdraw  -CommandParent $hRipLoop 
    #Insert cmd for withdrawing Router into scheduler
    stc::perform SequencerInsert -CommandList $hWithdrawRoute  -CommandParent $hRipLoop 

    #Insert the waiting time cmd before advertising Router into scheduler
    stc::perform SequencerInsert -CommandList $hWaitBeforeAdv  -CommandParent $hRipLoop 

    #Start Sequencer        
    stc::perform SequencerStart

    debugPut "exit the proc of RipSession::RipStartFlapRouteBlock"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RipStopFlapRouteBlock
#Description: Stop flap Rip router
#Input:  None
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipStopFlapRouteBlock {args} {
    set args [ConvertAttrToLowerCase $args]
 
    debugPut "enter the proc of RipSession::RipStopFlapRouteBlock"

    #Stop Sequencer        
    stc::perform SequencerStop

    debugPut "exit the proc of RipSession::RipStopFlapRouteBlock"

    return $::mainDefine::gSuccess

}

############################################################################
#APIName: RipSetFlapRouteBlock
#Description: Config Rip router flap
#Input:  
#            (1) AWDTimer optional parameter, time internal between advertising end to withdrawing start, default value is 5000ms, for example -AWDTimer timer1
#            (2) WADTimer optional parameter, time internal between withdrawing end to readvertising start, default value is 5000ms, for example -WADTimer timer2
#Output: Success return 0
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipSetFlapRouteBlock {args} {
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipSetFlapRouteBlock"

    #Get the value of parameter AWDTimer 
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

    #Get the value of parameter WADTimer 
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

    debugPut "exit the proc of RipSession::RipSetFlapRouteBlock"

    return $::mainDefine::gSuccess

}

############################################################################
#APIName: RipRetrieveRouterStats
#Description: Get the statistic result of Rip
#Input:  
#                (1) RxAdvertisedUpdateCount RxAdvertisedUpdateCount optional parameter
#                (2) RxWithdrawnUpdateCount RxWithdrawnUpdateCount optional parameter
#                (3) TxAdvertiseUpdateCount TxAdvertiseUpdateCount optional parameter
#                (4) TxWithdrawnUpdateCount TxWithdrawnUpdateCount optional parameter
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipRetrieveRouterStats {args} {
    
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipRetrieveRouterStats"
     
    set m_hRipRouterResult [stc::get $m_hRipRouterConfig -Children-RipRouterResults]
    #Get the result of Rip Router
    set RipRouterResult $m_hRipRouterResult 

    if {$RipRouterResult == ""} {
          error "You need to start the router before retrieving the result data"
    }

    set RipRouterStats ""
    lappend RipRouterStats "-rxadvertisedupdatecount"                                 
    lappend RipRouterStats [stc::get $RipRouterResult -RxAdvertisedUpdateCount]

    lappend RipRouterStats "-rxwithdrawnupdatecount"                                 
    lappend RipRouterStats [stc::get $RipRouterResult -RxWithdrawnUpdateCount]

    lappend RipRouterStats "-txadvertisedupdatecount"                                 
    lappend RipRouterStats [stc::get $RipRouterResult -TxAdvertisedUpdateCount]

    lappend RipRouterStats "-txwithdrawnupdatecount"                                 
    lappend RipRouterStats [stc::get $RipRouterResult -TxWithdrawnUpdateCount]
    
    if {$args == "" } {
        debugPut "exit the proc of RipSession::RipRetrieveRouterStats"

        return $RipRouterStats
    } else {
        #Config the corresponding value according to the input parameter
        array set arr $RipRouterStats
        foreach {name valueVar}  $args {      

            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        } 
    
        debugPut "exit the proc of RipSession::RipRetrieveRouterStats"

        return $::mainDefine::gSuccess
    }
}

############################################################################
#APIName: RipRetrieveRouterStatus
#Description: Get current state of Rip Router
#Input:  (1) Status Status optional parameter
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body RipSession::RipRetrieveRouterStatus {args} {
    set args [ConvertAttrToLowerCase $args]

    debugPut "enter the proc of RipSession::RipRetrieveRouterStatus"
    
    #Get current state of Ripng Router
    set RipRouterConfig [stc::get $m_hRouter -children-RipRouterConfig]

    set RipRouterStatus ""
    lappend RipRouterStatus "-status"                                 
    lappend RipRouterStatus [stc::get $RipRouterConfig -RouterState]

    set retValue [GetValuesFromArray $args $RipRouterStatus]

    debugPut "enter the proc of RipSession::RipRetrieveRouterStatus"

    return $retValue
}