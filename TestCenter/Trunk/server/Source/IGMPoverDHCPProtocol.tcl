###########################################################################
#                                                                        
#  File Name£ºIGMPoverDHCPProtocol.tcl                                                                                              
# 
#  Description£ºDefine IGMPverDHCP Host class and corresponding API implement
# 
#  Author£º Penn
#
#  Create time:  2010.4.13
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################
::itcl::class IGMPoverDHCP {
    #Inherit Host class
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
    public variable m_hDHCPHost
    public variable m_hIGMPHost

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
                
        set index [lsearch $::mainDefine::gObjectNameList "*$hostName\_dhcp"]   
        if { $index >= 0 } {
            set m_hDHCPHost [lindex $::mainDefine::gObjectNameList $index]
        } else {
            error "pppoe host handle can not be found in gObjectNameList"   
        }
        
        set index [lsearch $::mainDefine::gObjectNameList "*$hostName\_igmp"]   
        if { $index >= 0 } {
            set m_hIGMPHost [lindex $::mainDefine::gObjectNameList $index]
        } else {
            error "igmp host handle can not be found in gObjectNameList"         
        } 
    }

    destructor {
        set index [lsearch $::mainDefine::gObjectNameList "*$m_hostName\_dhcp"]
        if {$index != -1} {
            set object [lindex $::mainDefine::gObjectNameList $index]
            catch {itcl::delete object $object}
        }

        set index [lsearch $::mainDefine::gObjectNameList "*$m_hostName\_igmp"]
        if {$index != -1} {
            set object [lindex $::mainDefine::gObjectNameList $index]
            catch {itcl::delete object $object}
        }        
    }

    public method SetSession
    public method RetrieveRouter    
    public method Enable
    public method Disable
    public method DhcpSetSession
    public method DhcpBind
    public method DhcpRelease
    public method DhcpRenew
    public method DhcpAbort
    public method DhcpDecline       
    public method DhcpInform
    public method DhcpRetryUnbound
    public method DhcpReboot
    public method DhcpClearStats
    public method DhcpRetrieveRouterStats
    public method DhcpRetrieveRouter   
    public method DhcpSetFlap
    public method DhcpStartFlap     
    public method DhcpStopFlap
    public method DhcpRetrieveHostState
    public method IgmpSetSession              
    public method IgmpCreateGroupPool
    public method IgmpSetGroupPool
    public method IgmpDeleteGroupPool
    public method IgmpSendLeave
    public method IgmpSendReport
    public method IgmpRetrieveRouterStats   
    public method IgmpRetrieveRouter
    public method Ping
    public method SendArpRequest  
}

############################################################################
#APIName: SetSession
#Description: Config IGMP over DHCP Host according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::SetSession {args} {
    debugPut "enter the proc of IGMPoverDHCP::SetSession"

    #Call SetSession of DHCPClient class and IgmpHost class simultaneously
    #Prevent parameter from being covered by PPPoEConfigRouter or IgmpConfigRouter
    $m_hDHCPHost SetSession $args
    $m_hIGMPHost SetSession $args

    debugPut "exit the proc of IGMPoverDHCP::SetSession"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: RetrieveRouter
#Description: Get config information of igmpODHCP, according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::RetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverDHCP::RetrieveRouter"
    set args [ConvertAttrToLowerCase $args]

    #Call RetrieveRouter method of DHCPClient class
    set DhcpRouter [$m_hDHCPHost RetrieveRouter]       

    #Return statistics infomation according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::RetrieveRouter"   
        return $DhcpRouter    
    } else {
        set DhcpRouter [string tolower $DhcpRouter]
        array set arr $DhcpRouter
        foreach {name valueVar}  $args {      
           
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    }       
        
    debugPut "exit the proc of IGMPoverDHCP::RetrieveRouter"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: Enable
#Description: Config IGMP over DHCP Host according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::Enable {args} {
    debugPut "enter the proc of IGMPoverDHCP::Enable"

    #Call method Enable of DHCPClient class
    $m_hDHCPHost Enable $args

    #Call method Enable of IGMPHost class
    $m_hIGMPHost Enable $args   
 
    debugPut "exit the proc of IGMPoverDHCP::Enable"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: Disable
#Description: Config IGMP Host according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::Disable {args} {
    debugPut "enter the proc of IGMPoverDHCP::Disable"
    
    #Call method Disable of DHCPClient class
    $m_hDHCPHost Disable $args
    #Call method Disable of IGMPHost class
    $m_hIGMPHost Disable $args  
    
    debugPut "exit the proc of IGMPoverDHCP::Disable"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpSetSession
#Description: Config IGMP Host according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpSetSession {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpSetSession"

    #Call method SetSession of DHCPClient class
    $m_hDHCPHost SetSession $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpSetSession"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpBind 
#Description: dhcp client enter the initial state of simulation, then start the process
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpBind {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpBind"

    #Call method Bind of DHCPClient class 
    $m_hDHCPHost Bind $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpBind"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpRelease 
#Description: release dhcp host
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRelease {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRelease"
	  
    #Call method Release of DHCPClient class  
    $m_hDHCPHost Release $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpRelease"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpRenew 
#Description: renew dhcp host
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRenew {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRenew"

    #Call method Renew of DHCPClient class  
    $m_hDHCPHost Renew $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpRenew"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpAbort 
#Description: Stop dhcp host of all active Session, make state change to idle
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpAbort {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpAbort"

    #Call method Abort of DHCPClient class  
    $m_hDHCPHost Abort $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpAbort"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpDecline 
#Description: dhcp host send Decline message, deal with address conflict
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpDecline {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpDecline"
    
    #Call method Decline of DHCPClient class  
    $m_hDHCPHost Decline $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpDecline"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpInform 
#Description: dhcp host send Inform message
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpInform {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpInform"

    #Call method Inform of DHCPClient class  
    $m_hDHCPHost Inform $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpInform"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpRetryUnbound 
#Description: All failed hosts apply once again
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRetryUnbound {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRetryUnbound"
    
    #Call method RetryUnbound of DHCPClient class  
    $m_hDHCPHost RetryUnbound $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpRetryUnbound"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpReboot 
#Description: make dhcp host reboot again
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpReboot {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpReboot"
	  
    #Call method Reboot of DHCPClient class  
    $m_hDHCPHost Reboot $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpReboot"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpClearStats 
#Description: clear all the previous statistics of DHCP
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpClearStats {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpClearStats"

    #Call method ClearStats of DHCPClient class  
    $m_hDHCPHost ClearStats $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpClearStats"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpRetrieveRouterStats 
#Description: Get information of dhcp
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRetrieveRouterStats {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRetrieveRouterStats"
    set args [ConvertAttrToLowerCase $args]

    #Call method RetrieveRouterStats of DHCPClient class    
    set DhcpRouterStats [$m_hDHCPHost RetrieveRouterStats]      

    #Return statistics according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveRouterStats"   
        return $DhcpRouterStats    
    } else {
        set DhcpRouterStats [string tolower $DhcpRouterStats]
        array set arr $DhcpRouterStats
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    }    
    
    debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveRouterStats"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpRetrieveRouter 
#Description: Retrieve information of dhcp session
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRetrieveRouter"
    set args [ConvertAttrToLowerCase $args]

    #Call method RetrieveRouter of DHCPClient class   
    set DhcpRouter [$m_hDHCPHost RetrieveRouter]       

    #Return statistics according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveRouter"   
        return $DhcpRouter    
    } else {
        set DhcpRouter [string tolower $DhcpRouter]
        array set arr $DhcpRouter
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    }       
        
    debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveRouter"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: DhcpSetFlap 
#Description: Config flap parameter from bound to Release, Reboot,Renew
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpSetFlap {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpSetFlap"

    #Call method SetFlap of DHCPClient class  
    $m_hDHCPHost SetFlap $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpSetFlap"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpStartFlap 
#Description: Flap Release
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpStartFlap {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpStartFlap"
    
    #Call method StartFlap of DHCPClient class  
    $m_hDHCPHost StartFlap $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpStartFlap"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpStopFlap 
#Description: Stop flapping Release
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpStopFlap {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpStopFlap"
    
    #Call method StopFlap of DHCPClient class  
    $m_hDHCPHost StopFlap $args

    debugPut "exit the proc of IGMPoverDHCP::DhcpStopFlap"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DhcpRetrieveHostState 
#Description: Get state information of host according to incoming MAC address
#
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::DhcpRetrieveHostState {args} {
    debugPut "enter the proc of IGMPoverDHCP::DhcpRetrieveHostState"
    set args [ConvertAttrToLowerCase $args]

    #Call method RetrieveHostState of DHCPClient class  	
    set DhcpHostState [$m_hDHCPHost RetrieveHostState $args]
    
    #Return statistics according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveHostState"   
        return $DhcpHostState    
    } else {
        set DhcpHostState [string tolower $DhcpHostState]
        array set arr $DhcpHostState
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    } 
        
    debugPut "exit the proc of IGMPoverDHCP::DhcpRetrieveHostState"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IgmpSetSession
#Description: Config IGMP Host according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpSetSession {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpSetSession"
	  
    #Call method SetSession of IGMPHost  
    $m_hIGMPHost SetSession $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpSetSession"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IgmpCreateGroupPool
#Description: Create IGMP Group for IGMP Host that has been created according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpCreateGroupPool {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpCreateGroupPool"
    #Call method CreateGroupPool of IGMPHost  
    $m_hIGMPHost CreateGroupPool $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpCreateGroupPool"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSetGroupPool
#Description: Config IGMP Group attribute of IGMP Host according to the incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpSetGroupPool {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpSetGroupPool"
	  
    #Call method SetGroupPool of IGMPHost  
    $m_hIGMPHost SetGroupPool $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpSetGroupPool"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IgmpDeleteGroupPool
#Description: Delete IGMP Group of specified IGMP Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpDeleteGroupPool {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpDeleteGroupPool"
	  
    #Call method DeleteGroupPool of IGMPHost class 
    $m_hIGMPHost DeleteGroupPool $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpDeleteGroupPool"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IgmpSendReport
#Description: Send IGMP Join message of specified group according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpSendReport {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpSendReport"
	  
    #Call method SendReport of IGMPHost  
    $m_hIGMPHost SendReport $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpSendReport"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSendLeave
#Description: Send message of IGMP Leave in specified format according to incoming parameter
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpSendLeave {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpSendLeave"
	  
    #Call method SendLeave of IGMPHost  
    $m_hIGMPHost SendLeave $args

    debugPut "exit the proc of IGMPoverDHCP::IgmpSendLeave"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: IgmpRetrieveRouterStats
#Description: Get the corresponding statistics of current Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpRetrieveRouterStats {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpRetrieveRouterStats"
    set args [ConvertAttrToLowerCase $args]

    #Call method RetrieveRouterStats of IGMPHost    	
    set IgmpRouterStats [$m_hIGMPHost RetrieveRouterStats]

    #Return statistics according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::IgmpRetrieveRouterStats"   
        return $IgmpRouterStats    
    } else {
        set IgmpRouterStats [string tolower $IgmpRouterStats]
        array set arr $IgmpRouterStats
        foreach {name valueVar}  $args {      
           
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    } 
        
    debugPut "exit the proc of IGMPoverDHCP::IgmpRetrieveRouterStats"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: IgmpRetrieveRouter
#Description: Get config information of current Router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::IgmpRetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverDHCP::IgmpRetrieveRouter"
    set args [ConvertAttrToLowerCase $args]

    #Call method RetrieveRouter of IGMPHost  	  
    set IgmpRouter [$m_hIGMPHost RetrieveRouter]
    
    #Return statistics according to incoming parameter
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverDHCP::IgmpRetrieveRouter"   
        return $IgmpRouter    
    } else {
        set IgmpRouter [string tolower $IgmpRouter]
        array set arr $IgmpRouter
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    } 
        
    debugPut "exit the proc of IGMPoverDHCP::IgmpRetrieveRouter"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: Ping
#Description: Send ICMP ECHO_REQUESTs from test instrument port to destination address or host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::Ping {args} {
    debugPut "enter the proc of IGMPoverDHCP::Ping"
    set args [ConvertAttrToLowerCase $args]
    set args1 $args

    set pingResultStats ""
    #Get the value of parameter result
    set index [lsearch $args1 -result] 
    if {$index != -1} {
        set args1 [lreplace $args1 [expr $index + 1] [expr $index  + 1] "pingResultStats"]
    } 

    #Call method Ping of IGMPHost  
    $m_hIGMPHost Ping $args1

    foreach {name valueVar}  $args {  
        if {$name == "-result"} {    
            set ::mainDefine::gAttrValue $pingResultStats
            set ::mainDefine::gVar $valueVar
            
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
            break
        }        
    }

    debugPut "exit the proc of IGMPoverDHCP::Ping"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: SendArpRequest
#Description: Send Arp from test instrument port, apply for mac address of SutIp and save the mapping list
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverDHCP::SendArpRequest {args} {
    debugPut "enter the proc of IGMPoverDHCP::SendArpRequest"
    
    #Call method SendArpRequest of IGMPHost  
    $m_hIGMPHost SendArpRequest $args

    debugPut "exit the proc of IGMPoverDHCP::SendArpRequest"
    return $::mainDefine::gSuccess 
}


