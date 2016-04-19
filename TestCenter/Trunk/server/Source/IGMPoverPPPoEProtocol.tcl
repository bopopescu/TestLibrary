###########################################################################
#                                                                        
#  Filename£ºIGMPoverPPPoEProtocol.tcl                                                                                             
# 
#  Description£ºDefinition of IGMPverPPPoE Host class and relevant API
# 
#  Creator£ºPenn
#
#  Time£º 2010.4.13 
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

::itcl::class IGMPoverPPPoE {
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
    public variable m_hPPPoEHost
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
        
        set index [lsearch $::mainDefine::gObjectNameList "*$hostName\_pppoe"]   
        if { $index >= 0 } {
            set m_hPPPoEHost [lindex $::mainDefine::gObjectNameList $index]
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
        set index [lsearch $::mainDefine::gObjectNameList "*$m_hostName\_pppoe"]
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
    public method PPPoESetSession
    public method PPPoEOpen
    public method PPPoEClose
    public method PPPoERetrieveRouter
    public method PPPoERetrieveRouterStats
    public method PPPoECancelAttempt
    public method PPPoEAbort
    public method PPPoERetryFailedPeer
    public method PPPoEGetHostState
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
#Description: According to input parameter, configure IGMP over PPPoE Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::SetSession {args} {
    debugPut "enter the proc of IGMPoverPPPoE::SetSession"

    #Simultaneously call the SetSession method of PPPoEClient class and IgmpHost class,
    #Prevent parameters from being overlaping by the last call of PPPoESetSession or IgmpSetSession
    $m_hPPPoEHost SetSession $args
    $m_hIGMPHost SetSession $args

    debugPut "exit the proc of IGMPoverPPPoE::SetSession" 
    return $::mainDefine::gSuccess   
}

############################################################################
#APIName: RetrieveRouter
#Description: Get relevant statistical infomation of current Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::RetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverPPPoE::RetrieveRouter"	
    set args [ConvertAttrToLowerCase $args]

    #Call the RetrieveRouter method of PPPoEClient class  
    set PppoeRouter [$m_hPPPoEHost RetrieveRouter]       

    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::RetrieveRouter"   
        return $PppoeRouter    
    } else {
        set PppoeRouter [string tolower $PppoeRouter]
        array set arr $PppoeRouter
        foreach {name valueVar}  $args {      
           
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    }     
    debugPut "exit the proc of IGMPoverPPPoE::RetrieveRouter"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: Enable
#Description: Enable current IGMP router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::Enable {args} {
    debugPut "enter the proc of IGMPoverPPPoE::Enable"

    #Call the Enable method of IGMPHost class
    $m_hIGMPHost Enable $args
    #Call the Enable method of PPPoEClient class
    $m_hPPPoEHost Enable $args    

    debugPut "exit the proc of IGMPoverPPPoE::Enable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Disable
#Description: Disable current IGMP router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::Disable {args} {
    debugPut "enter the proc of IGMPoverPPPoE::Disable"	
	  
    #Call the Disable method of PPPoEClient class
    $m_hPPPoEHost Disable $args
    #Call the Disable method of IGMPHost class
    $m_hIGMPHost Disable $args    

    debugPut "exit the proc of IGMPoverPPPoE::Disable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PPPoESetSession
#Description: According to input parameters£¬configure PPPoE Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoESetSession {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoESetSession"
	 
    #Call the SetSession method of PPPoEClient class
    $m_hPPPoEHost SetSession $args

    debugPut "exit the proc of IGMPoverPPPoE::PPPoESetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PPPoEOpen
#Description: Start PPPoE analog simulation
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoEOpen {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoEOpen"

    #Call the PPPoEOpen method of PPPoEClient class
    $m_hPPPoEHost Open $args

    debugPut "exit the proc of IGMPoverPPPoE::PPPoEOpen"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PPPoEClose
#Description: Close the connection of pppoeHost users
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoEClose {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoEClose"
	
    #Call the PPPoEClose method of PPPoEClient class
    $m_hPPPoEHost Close $args

    debugPut "exit the proc of IGMPoverPPPoE::PPPoEClose"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: PPPoERetrieveRouter
#Description: Get current configuration infomation of simulated Router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoERetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoERetrieveRouter"	
    set args [ConvertAttrToLowerCase $args]

    #Call the RetrieveRouter method of PPPoEClient class   
    set PppoeRouter [$m_hPPPoEHost RetrieveRouter]       

    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::RetrieveRouter"   
        return $PppoeRouter    
    } else {
        set PppoeRouter [string tolower $PppoeRouter]
        array set arr $PppoeRouter
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    }      

    debugPut "exit the proc of IGMPoverPPPoE::PPPoERetrieveRouter"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: PPPoERetrieveRouterStats
#Description: Get current statistical infomation of simulated Router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoERetrieveRouterStats {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoERetrieveRouterStats"	
    set args [ConvertAttrToLowerCase $args] 
	  
    #Call the RetrieveRouterStats method of PPPoEClient class    
    set PppoeRouterStats [$m_hPPPoEHost RetrieveRouterStats]      

    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::PPPoERetrieveRouterStats"   
        return $PppoeRouterStats    
    } else {
        set PppoeRouterStats [string tolower $PppoeRouterStats]
        array set arr $PppoeRouterStats
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    } 
    	  
    debugPut "exit the proc of IGMPoverPPPoE::PPPoERetrieveRouterStats"
    return $::mainDefine::gSuccess    
}  

############################################################################
#APIName: PPPoECancelAttempt
#Description: Cancel connection which is in the process of connecting or retrying, maintain connection connected
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoECancelAttempt {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoECancelAttempt"	
	  
    #Call the CancelAttempt method of PPPoEClient class
    $m_hPPPoEHost CancelAttempt $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::PPPoECancelAttempt"
    return $::mainDefine::gSuccess      
}

############################################################################
#APIName: PPPoEAbort
#Description: Abort the connection of PPPoE£¬do not send message of aborting connection
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoEAbort {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoEAbort"	
	  
    #Call the Abort method of PPPoEClient class
    $m_hPPPoEHost Abort $args
    
    debugPut "exit the proc of IGMPoverPPPoE::PPPoEAbort"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: PPPoERetryFailedPeer
#Description: For the first online failed users, retry online operation
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoERetryFailedPeer {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoERetryFailedPeer"	
	  
    #Call the RetryPppoeHost method of PPPoEClient class
    $m_hPPPoEHost RetryPppoeHost $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::PPPoERetryFailedPeer"
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: PPPoEGetHostState
#Description: According to input MAC address, get the state infomation of a host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::PPPoEGetHostState {args} {
    debugPut "enter the proc of IGMPoverPPPoE::PPPoEGetHostState"	
    set args [ConvertAttrToLowerCase $args]
	  
    #Call the GetHostState method of PPPoEClient class 	
    set PPPoEHostState [$m_hPPPoEHost GetHostState $args]

    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::PPPoEGetHostState"   
        return $PPPoEHostState    
    } else {
        set PPPoEHostState [string tolower $PPPoEHostState]
        array set arr $PPPoEHostState
        foreach {name valueVar}  $args {      
            
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }                          
    } 

    debugPut "exit the proc of IGMPoverPPPoE::PPPoEGetHostState"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSetSession
#Description: According to input parameters, configure created IGMP Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpSetSession {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpSetSession"	
	  
    #Call the SetSession method of IGMPHost class
    $m_hIGMPHost SetSession $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpSetSession"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: IgmpCreateGroupPool
#Description:  According to input parameters, create IGMP Group for created IGMP Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpCreateGroupPool {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpCreateGroupPool"	
	  
    #Call the CreateGroupPool method of IGMPHost class
    $m_hIGMPHost CreateGroupPool $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpCreateGroupPool"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSetGroupPool
#Description: According to input parameters, configure IGMP Group's attributes of IGMP Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpSetGroupPool {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpSetGroupPool"	
	  
    #Call the ConfigGroupPool method of IGMPHost class
    $m_hIGMPHost ConfigGroupPool $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpSetGroupPool"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpDeleteGroupPool
#Description: Delete designated IGMP Group of IGMP Host by users
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpDeleteGroupPool {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpDeleteGroupPool"	
	  
    #Call the DeleteGroupPool method of IGMPHost class
    $m_hIGMPHost DeleteGroupPool $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpDeleteGroupPool"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSendReport
#Description: According to input parameter, send IGMP Join messages of designated group
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpSendReport {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpSendReport"	
	  
    #Call the SendReport method of IGMPHost class
    $m_hIGMPHost SendReport $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpSendReport"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpSendLeave
#Description:  According to input parameter, send IGMP Leave messages in the specified format
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpSendLeave {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpSendLeave"	
	  
    #Call the SendLeave method of IGMPHost class
    $m_hIGMPHost SendLeave $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::IgmpSendLeave"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpRetrieveRouterStats
#Description: Get relevant statistical infomation of current Host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpRetrieveRouterStats {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpRetrieveRouterStats"	
    set args [ConvertAttrToLowerCase $args]

    #Call the RetrieveRouterStats method of IGMPHost class  	
    set IgmpRouterStats [$m_hIGMPHost RetrieveRouterStats]
   
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::IgmpRetrieveRouterStats"   
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
     
    debugPut "exit the proc of IGMPoverPPPoE::IgmpRetrieveRouterStats"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: IgmpRetrieveRouter
#Description: Get relevant configuration infomation of current Router
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::IgmpRetrieveRouter {args} {
    debugPut "enter the proc of IGMPoverPPPoE::IgmpRetrieveRouter"	
    set args [ConvertAttrToLowerCase $args] 
 
    #Call the RetrieveRouter method of IGMPHost class	  
    set IgmpRouter [$m_hIGMPHost RetrieveRouter]
    
    #Return statistical items according to input parameters
    if { $args == "" } {
        debugPut "exit the proc of IGMPoverPPPoE::IgmpRetrieveRouter"   
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

    debugPut "exit the proc of IGMPoverPPPoE::IgmpRetrieveRouter"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: Ping
#Description: Send ICMP ECHO_REQUESTs from test instrumentation port to destination address or the host
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::Ping {args} {
    debugPut "enter the proc of IGMPoverPPPoE::Ping"	
    set args [ConvertAttrToLowerCase $args]
    set args1 $args

    set pingResultStats ""
    #Get the value of result
    set index [lsearch $args1 -result] 
    if {$index != -1} {
        set args1 [lreplace $args1 [expr $index + 1] [expr $index  + 1] "pingResultStats"]
    } 

    #Call the Ping method of IGMPHost class
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
	  
    debugPut "exit the proc of IGMPoverPPPoE::Ping"
    return $::mainDefine::gSuccess     
}

############################################################################
#APIName: SendArpRequest
#Description: Send Arp from test instrumentation port, request for mac address of SutIp, and save map list
#Input: 
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body IGMPoverPPPoE::SendArpRequest {args} {
    debugPut "enter the proc of IGMPoverPPPoE::SendArpRequest"	
	  
    #Call the SendArpRequest method of IGMPHost class
    $m_hIGMPHost SendArpRequest $args
	  
    debugPut "exit the proc of IGMPoverPPPoE::SendArpRequest"
    return $::mainDefine::gSuccess    
}