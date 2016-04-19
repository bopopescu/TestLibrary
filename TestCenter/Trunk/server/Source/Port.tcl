###########################################################################
#                                                                        
#  File Name：Port.tcl                                                                                              
# 
#  Description：Definition of STC port class and its methods                                             
# 
#  Author： David.Wu
#
#  Create Time:  2007.3.2
#
#  Version：1.0 
# 
#  History： 
# 
#########################################################################

#Load itcl package
package require Itcl

##########################################
#Definition of TestPort class
##########################################   
::itcl::class TestPort {

    #Variables
    public variable m_hPort 0
    public variable m_portType "ethernet"
    public variable m_chassisIp 0
    public variable m_hProject 0
    public variable m_portLocation  0
    public variable m_portName 0
    public variable m_trafficNameList ""
    public variable m_staEngineList ""
    public variable m_filterNameList ""
    public variable m_filterConfigList ""    
    public variable m_hFilter
    public variable m_FilterType    
    public variable m_hostHandle 
    public variable m_chassisName 0
    public variable m_filteredStreamResults 0
    public variable m_streamBasedSchedulingSetted 0
    public variable m_blocking Disable
    public variable m_frameNumOfBlocking 0
    public variable m_stpBridgeSeq 0
    public variable m_stpInstanceVlanId 1
    public variable m_FilterOnStreamId "FALSE"
    public variable m_StaEngineState "IDLE"
    public variable m_StartCaptureState "IDLE"

    public variable m_routerNameList ""
    public variable m_hRouterList ""
    public variable m_hGeneralRouter 
    public variable m_routerNum 0
    public variable m_macRouterNum 0
    public variable m_creatorOfRouter 0
    public variable m_mode "create"
    public variable m_hAutoCreateChildrenList ""
    public variable m_trafficFlag 0

    public variable m_hostNameList ""
    public variable m_hHostList ""
    public variable m_hostTypeList
    public variable m_generatorStarted "FALSE"
    public variable m_streamStatisticRefershed "FALSE"
    public variable m_vlanIfList
    public variable m_hostHandleByIp
    public variable m_hostNameByIp

    public variable m_isARPDone "TRUE"
    
    public variable m_awdtimer 5000
    public variable m_wadtimer 5000
    
    public variable m_highResolutionPortConfig
	public variable m_highResolutionStreamBlockConfig

    #Constructor
    constructor { portName hPort portType chassisName portLocation hProject chassisIp mode}  { 
         set m_mode $mode
         set m_portType $portType
        #Create port object
        if {$mode == "create"} {
            set m_portName $portName
            set m_hPort [stc::create port -under $hProject -location //$chassisIp/$portLocation] 
            set m_hAutoCreateChildrenList [stc::get $m_hPort -children]
            set m_chassisName $chassisName

            set m_chassisIp $chassisIp
            set m_hProject $hProject
            set m_portLocation $chassisIp/$portLocation
           
            #Check the port state, and then reserve the port
            set list [split $portLocation /]   
            #Only port/slot needed
            set m_slot [lindex $list 0]
            set m_port [lindex $list 1]
            set pcm [stc::get system1 -children-physicalchassismanager]
            set chassislist [stc::get $pcm -children-physicalchassis] 
            set chassis [lindex $chassislist [expr [llength $chassislist] - 1]]
            set SlotSize [stc::get $chassis -SlotCount]
            if {$m_slot > $SlotSize} {
                 error "The port: $m_portLocation does not support on chassis, please check your parameter"  
            }
            set portCount [stc::get $chassis.physicaltestmodule.$m_slot -PortCount]
            if {$m_port > $portCount} {
                error "The port: $m_portLocation does not support on chassis, please check your parameter"  
            } 

            set portGroupSize [stc::get $chassis.physicaltestmodule.$m_slot -PortGroupSize]
            set portGroupIndex [expr ( $m_port / $portGroupSize ) + ( $m_port % $portGroupSize )]
            set status [stc::get $chassis.physicaltestmodule.$m_slot.physicalportgroup.$portGroupIndex -Status]
            set loop 0

            set LOOP_COUNT 30
            while {$status == "MODULE_STATUS_DOWN"} {
                 debugPut "The port $m_portLocation is rebooting, please wait ..."
                 if {$loop == $LOOP_COUNT} {
                      error "Timeout to wait for the port: $m_portLocation to be available"
                 }

                 set loop [expr $loop + 1]

                 #Wait 15 seconds, and then check the state
                 after 15000
                 set status [stc::get $chassis.physicaltestmodule.$m_slot.physicalportgroup.$portGroupIndex -Status]
                 set ownerShipState [stc::get $chassis.physicaltestmodule.$m_slot.physicalportgroup.$portGroupIndex -OwnershipState]
                 if {$status == "MODULE_STATUS_DOWN"} {
                      if {$ownerShipState == "OWNERSHIP_STATE_AVAILABLE" && $loop == $LOOP_COUNT} {
                          break
                      }      
                 }                    
                   
            }            

            stc::reserve $chassisIp/$portLocation

            #Link port object with physical port           
            set errorCode 1
            if {[catch {
                set errorCode [stc::perform setupPortMappings]
            } err]} {
               return $errorCode
            }    
            catch {
                if {$m_filteredStreamResults == "0" } {
                     set m_filteredStreamResults  [stc::subscribe -parent $m_hProject \
                          -resultParent $m_hPort \
                          -configType analyzer \
                          -viewAttributeList "AvgLatency AvgJitter OctetRate FrameRate FrameCount SigFrameCount OctetCount FcsErrorFrameCount Ipv4ChecksumErrorCount DuplicateFrameCount InSeqFrameCount OutSeqFrameCount DroppedFrameCount PrbsFillOctetCount PrbsBitErrorCount TcpUdpChecksumErrorCount L1BitRate L1BitCount firstarrivaltime lastarrivaltime " \
                          -interval 1 -resultType FilteredStreamResults ]   
                   stc::config $m_filteredStreamResults -RecordsPerPage 256
                }
            }

            lappend ::mainDefine::gObjectNameList $this            
        } elseif {$mode == "inherit"} {
            set m_portName $portName
            set m_hPort $hPort           
            set m_chassisName $chassisName       
            set m_chassisIp $chassisIp
            set m_hProject $hProject
            set m_portLocation $portLocation  
        }
    }

    #Destructor
    destructor  {
  
    set index [lsearch $::mainDefine::gObjectNameList $this]
    set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }

    #Method definition
    public method StartTraffic
    public method StopTraffic
    public method GetPortState
    public method CreateHost
    public method CreateVplsHost
    public method DestroyVplsHost
    public method DestroyHost
    public method CreateTraffic
    public method DestroyTraffic
    public method CreateStaEngine
    public method DestroyStaEngine
    public method CreateFilter
    public method ConfigFilter
    public method DestroyFilter   
    public method StartStaEngine
    public method StopStaEngine
    public method CreateRouter
    public method DestroyRouter
    public method StartRouter
    public method StopRouter
    public method CleanupPort
    public method BgpImportRouteTable
    public method SetFlap
    public method StartFlapRouters
    public method ConfigHighResolutionSample
    public method StartHighResolutionSample
    public method StopHighResolutionSample
	#Added by yong @2013.5.23 for highresolutionstreamblocksample
	public method ConfigHighResolutionStreamBlockSample
    public method StartHighResolutionStreamBlockSample
    public method StopHighResolutionStreamBlockSample

    #Methods for internal use only
    private method DeleteFilterHandle
    public method  GetRouterMacAddress
    public method  GetRouterSeq
    public method  ResetTestPort
    public method  SetRouterHandle
    public method  GetRouterHandle
    public method  RealStartAllCaptures
    public method  BindHostsToStream
    public method  GetStreamIndex
    public method  GetHostHandleByIp
    public method  InternalFlap

    #Method to start StaEngine to take effect 
    public method RealStartStaEngine
}


############################################################################
#APIName: CreateVplsHost
#
#Description: Create Vpls host on the port
#Input: For the details please refer to the user manual          
#
#Output: None
#
#Coded by: david.wu
#############################################################################
::itcl::body TestPort::CreateVplsHost {args} {
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of TestPort::CreateVplsHost..."
    #Parse HostName parameter
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify HostName parameter \nexit the proc of CreateVplsHost..."
    }
    #Check whether or HostName already exists
    set index [lsearch $m_hostNameList $HostName]
    if { $index !=-1} {
        error "the HostName($HostName) is already existed, please specify another one. \
        The existed HostName is (are) as following:\n$m_hostNameList"
    } 
    lappend m_hostNameList $HostName
    #Parse SubIntName parameter
    set index [lsearch $args -subintname] 
    if {$index != -1} {
        set SubIntName [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify SubIntName parameter \nexit the proc of CreateVplsHost..."
    }
	#Parse QinQList parameter
    set index [lsearch $args -qinqlist] 
    if {$index != -1} {
        set QinQList [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify QinQList parameter \nexit the proc of CreateVplsHost..."
    }
    
    #Parse MacAddr parameter
    set index [lsearch $args -macaddr] 
    if {$index != -1} {
        set MacAddr [lindex $args [expr $index + 1]]
    } else  {
        set MacAddr [GetRouterMacAddress]
    } 
    
    #Parse MacCount parameter
    set index [lsearch $args -maccount] 
    if {$index != -1} {
        set MacCount [lindex $args [expr $index + 1]]
    } else  {
        set MacCount 1
    } 
    
    #Parse MacIncrease parameter
    set index [lsearch $args -macincrease] 
    if {$index != -1} {
        set MacIncrease [lindex $args [expr $index + 1]]
    } else  {
        set MacIncrease 1
    } 

    #Parse MacStepMask parameter
    set index [lsearch $args -macstepmask] 
    if {$index != -1} {
        set MacStepMask [lindex $args [expr $index + 1]]
    } else  {
        set MacStepMask "00:00:FF:FF:FF:FF"
    } 
    
    #Create Host object and config the parameters   
    
    set ::mainDefine::objectName $this 
    uplevel 1 {         
         set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]         
    }         
    set hProject $::mainDefine::result     
    set hHost [stc::create host -under $hProject -Name $HostName -DeviceCount $MacCount]
    set m_hostHandle($HostName) $hHost
    set ::mainDefine::gHostHandle($HostName) $hHost
    lappend m_hHostList $hHost
   
    set step ""
    set index [string first ":" $MacIncrease] 
    if {$index == -1} {
    for {set i 0} {$i <6} { incr i} {
        set mod1 [expr $MacIncrease%256]
        if {$step ==""} {
            set step [format %x $mod1]
        } else {
            set step [format %x $mod1]:$step
        }
        set MacIncrease [expr $MacIncrease/256]
    }
    } else {
        set step $MacIncrease
    }
    if {$MacCount <=1} {    
        set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SourceMac $MacAddr -SrcMacStepMask $MacStepMask -SrcMacStep 00:00:00:00:00:00]
    } else {
        set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SourceMac $MacAddr -SrcMacStepMask $MacStepMask -SrcMacStep $step]
    }

    set i 0
    set m_vlanIfList(0) ""               
    set ::mainDefine::objectName $this 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
    }         
    set hPort $::mainDefine::result
    stc::config $hHost -AffiliationPort-targets $hPort
    foreach QinQ $QinQList {
        set i [expr $i + 1]
        set vlanType [lindex $QinQ 0]
        set hexFlag [string range $vlanType 0 1]
        if {[string tolower $hexFlag] != "0x" } {
              set vlanType 0x$vlanType
        }
        set vlanType [format %d $vlanType]                  
        set vlanId [lindex $QinQ 1]
        set vlanPriority [lindex $QinQ 2]
        set m_vlanIfList($i) [stc::create VlanIf -under $hHost -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType -IdStep "0" ]  
        if {$i == 1} {
              stc::config $hHost -TopLevelIf-targets " $m_vlanIfList($i) "
              stc::config $hHost -PrimaryIf-targets " $m_vlanIfList($i) "   
              set ::mainDefine::gPoolCfgBlock($SubIntName) $m_vlanIfList($i)                       
        } else {
                stc::config $m_vlanIfList([expr $i - 1]) -StackedOnEndpoint-targets $m_vlanIfList($i)
        }
        stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets " $L2If1 "
    }
    debugPut "exit the proc of TestPort::CreateVplsHost..."
    
    return  $::mainDefine::gSuccess 
}


############################################################################
#APIName: DestroyVplsHost
#Description: Destroy host object
#Input: 1. args:argument list，including the following
#              (1) -HostName HostName required,host name, i.e -HostName host1 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TestPort::DestroyVplsHost {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TestPort::DestroyVplsHost..."
    
    #Parse HostName parameter
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify HostName parameter. \nexit the proc of DestroyVplsHost..."
    }
    
    #Destroy host object
    if {[info exists m_hostHandle($HostName)]} {
        set hHost $m_hostHandle($HostName)
        set index [lsearch $m_hostNameList $HostName]
        set m_hostNameList [lreplace $m_hostNameList $index $index]
      
        set host_index [lsearch $m_hHostList $hHost]
        if {$host_index != -1} {
            set m_hHostList [lreplace $m_hHostList $host_index $host_index ]
             stc::delete $hHost
        }     
        unset m_hostHandle($HostName)
        stc::apply 
        debugPut "exit the proc of TestPort::DestroyVplsHost..." 
        return $::mainDefine::gSuccess     
    } else {
        error "The specified HostName parameter is not exist,please set another one.\nexit the proc of DestroyVplsHost..."
    }
}


############################################################################
#APIName: DeleteFilterHandle
#
#Description: Delete Filter Handle
#
#Input: 1. Filter Name              
#
#Output: None
#
#Coded by: david.wu
#############################################################################
::itcl::body TestPort::DeleteFilterHandle {FilterName} {

        if {$m_FilterType($FilterName) == "STACK"} {
            stc::delete $m_hFilter($FilterName)  
            unset m_hFilter($FilterName)      
        } elseif {$m_FilterType($FilterName) == "UDF"} {
             foreach filter $m_hFilter($FilterName) {
                 stc::delete  $filter                          
             }  
             set m_hFilter($FilterName) ""
        } else {
             set m_hFilter($FilterName) ""
        }
}

############################################################################
#APIName: CreateTraffic
#
#Description: Create TrafficEngine object
#
#Input: 1. -TrafficName TrafficName,required,Name of TrafficEngine
#
#Output: None
#
#Coded by: david.wu
#############################################################################
::itcl::body TestPort::CreateTraffic {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TestPort::CreateTraffic"

    #Parse TrafficName parameter
    set index [lsearch $args -trafficname]
    if { $index !=-1} {
        set TrafficName [lindex $args [expr $index+1]]
    } else {
        error "please specify TrafficName for CreateTraffic API"
    }
    #Check whether or not TrafficName is unique
    set index [lsearch $m_trafficNameList $TrafficName]
    if { $index != -1} {
        error "The TrafficName($TrafficName) is already existed, please specify another one. These existed TrafficNames are:\n$m_trafficNameList"
    }     

    lappend m_trafficNameList $TrafficName

    set ::mainDefine::gTrafficName $TrafficName

    set ::mainDefine::ghPort $m_hPort

    set ::mainDefine::portType $m_portType

    set ::mainDefine::gPortLocation $m_portLocation  

    set ::mainDefine::ghProject $m_hProject   

    set ::mainDefine::gPortName $m_portName    
    #Create TrafficEngine object
    if {$m_trafficFlag == 0} {
        uplevel 1 {
            TrafficEngine $::mainDefine::gTrafficName $::mainDefine::ghPort $::mainDefine::portType $::mainDefine::gPortLocation \
                                $::mainDefine::ghProject $::mainDefine::gPortName
        }
        set m_trafficFlag 1
    } else {
            error "One port has only one TrafficEngine, it can not be created twice."
    }

    debugPut "exit the proc of TestPort::CreateTraffic"
    return $::mainDefine::gSuccess
    
}

############################################################################
#APIName: DestroyTraffic
#
#Description: Destroy TrafficEngine object
#
#Input: 1. -TrafficName TrafficName,required,specify the traffic engine name              
#
#Output: None
#
#Coded by: david.wu
#############################################################################
::itcl::body TestPort::DestroyTraffic {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TestPort::DestroyTraffic"
    #Parse TrafficName parameter
    set index [lsearch $args -trafficname]
    if { $index !=-1} {
        set TrafficName [lindex $args [expr $index+1]]
    } else {
        error "please specify TrafficName for DestroyTraffic API"
    }
    #Check whether or not TrafficName is unique
    set index [lsearch $m_trafficNameList $TrafficName]
    if { $index == -1} {
        error "The TrafficName($TrafficName) dose not exist"
    } 
    ###Begin:Modified by Jaimin Wan, 02-Jan-2008 ###########################
    set ilist "" 
        for {set i 0} {$i < [llength $m_trafficNameList]} {incr i} {
            if {$i !=$index} {
                lappend ilist [lindex $m_trafficNameList $i]
            }
        }
        set m_trafficNameList $ilist
        unset ilist
    #set m_trafficNameList [lreplace $m_trafficNameList $index $index ""]
    ###End:Modified by Jaimin Wan, 02-Jan-2008 ###########################
    
    set ::mainDefine::gTrafficName $TrafficName    
    #Destroy TrafficEngine object
    uplevel 1 {
        itcl::delete object $::mainDefine::gTrafficName
    }  
 
   set m_trafficFlag 0

    debugPut "exit the proc of TestPort::DestroyTraffic"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateStaEngine
#
#Description: Create StaEngine object
#
#Input: 1. –StaEngineName staEngine,required
#          2. –type Statistics,  Statistics or Analysis, required
#              
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body TestPort::CreateStaEngine {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestPort::CreateStaEngine"

    #Parse StaEngineName parameter
    set index [lsearch $args -staenginename]
    if { $index !=-1} {
        set StaEngineName [lindex $args [expr $index+1]]
    } else {
        error "please specify StaEngineName for CreateStaEngine API"
    }
    
    #Parse StaType parameter
    set index [lsearch $args -statype]
    if { $index !=-1} {
        set StaType [lindex $args [expr $index+1]]
    } else {
        error "please specify StaType for CreateStaEngine API"
    }
    
    #Parse FilterOnStreamId parameter
    set index [lsearch $args -filteronstreamid]
    if { $index !=-1} {
        set m_FilterOnStreamId [lindex $args [expr $index+1]]
    } else {
        set m_FilterOnStreamId "FALSE"
    } 

    #Check whether or not StaEngine exists in current m_staEngineList
    set index [lsearch $m_staEngineList $StaEngineName]
    if { $index != -1} {
        error "The StaEngineName($StaEngineName) is already existed, please specify another one. \
        These existed StaEngineNames are:\n$m_staEngineList"
    }     

    set ::mainDefine::gStaEngineName $StaEngineName

    set ::mainDefine::gPortName $m_portName

    set ::mainDefine::gChassisName $m_chassisName

    #Create object according to StaType
    if {[string tolower $StaType] == "statistics"} {
         uplevel 1 {
             TestStatistic $::mainDefine::gStaEngineName $::mainDefine::gPortName  $::mainDefine::gChassisName
        }
    } elseif {[string tolower $StaType]== "analysis"} {
        uplevel 1 {
             TestAnalysis $::mainDefine::gStaEngineName $::mainDefine::gPortName $::mainDefine::gChassisName
        }
    } else {
       error "Unsupported type: $StaType, please specify StaType Statistics/Analysis for CreateStaEngine API"
    }

    lappend m_staEngineList $StaEngineName

    debugPut "exit the proc of TestPort::CreateStaEngine"

    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyStaEngine
#
#Description: Destroy StaEngine object
#
#Input: 1. –StaEngineName staEngine, required
#              
#
#Output: None
#
#Coded by: david.wu
############################################################################
::itcl::body TestPort::DestroyStaEngine {args} { 

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestPort::DestroyStaEngine"

    #Parse StaEngineName parameter
    set index [lsearch $args -staenginename]
    if { $index != -1} {
        set StaEngineNameList [lindex $args [expr $index+1]]
    } else {
        set StaEngineNameList $m_staEngineList
        debugPut "Try to delete all the StaEngine objects under the port"
    }

    foreach StaEngineName $StaEngineNameList {   
        set index [lsearch $m_staEngineList $StaEngineName]
        if { $index == -1} {
            error "The StaEngineName($StaEngineName) does not exist"
        } 

        #Delete the object
        set m_staEngineList [lreplace $m_staEngineList $index $index]

        set ::mainDefine::gStaEngineName $StaEngineName    

        uplevel 1 {
            itcl::delete object $::mainDefine::gStaEngineName
        }     
    }

    debugPut "exit the proc of TestPort::DestroyStaEngine"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: convertToBinary
#Description: Change integer to binary string.
#
#Coded by: Jaimin
############################################################################
proc convertToBinary { integer {bitlength 8} } {
    set binarynumber ""
    for { set i 0 } { $i < $bitlength } { incr i } {
        set binarynumber [expr $integer & 1]$binarynumber
        set integer [expr $integer >> 1]
    }
    return $binarynumber
}

############################################################################
#APIName: CreateFilter
#
#Description: Create Filter object
#
#Input:  1. -FilterName required,name of the filter
#          2. -FilterType required,filter type
#          3. -filtervalue required,filter value           
#
#Output: None
#
#Coded by: Penn.Chen
############################################################################
::itcl::body TestPort::CreateFilter {args} {

    debugPut "enter the proc of TestPort::CreateFilter"
    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  
    set args [ConvertAttrToLowerCase $args] 

    #Parse FilterName parameter
    set index [lsearch $args -filtername]
    if { $index !=-1} {
        set FilterName [lindex $args [expr $index+1]]
    } else {
        error "please specify FilterName for CreateFilter API"
    }    

    set index [lsearch $args -filteronstreamid]
    if { $index !=-1} {
        set FilterOnStreamId [lindex $args [expr $index+1]]
    } else {
        set FilterOnStreamId "FALSE"
    }    

    #Check whether or not the filter exists in current m_filterNameList
    set index [lsearch $m_filterNameList $FilterName]
    if { $index != -1} {
        error "The FilterName($FilterName) already exists, please specify another one. These existed FilterNames are:\n$m_filterNameList"
        puts "exit the proc of TestPort::DestroyFilter" 
        return 1
    }
    lappend m_filterConfigList $FilterName  

    #Parse FilterType parameter
    set index [lsearch $args -filtertype]
    if { $index !=-1} {
        set FilterType [lindex $args [expr $index+1]]
    } else {
        error "please specify FilterType for CreateFilter API"
    }   
     lappend m_filterConfigList $FilterType 
       
    #Save filterName in curent filterName list
    lappend m_filterNameList $FilterName         
   
    #Create filter object

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
    }         
    set PortHandle $::mainDefine::result      

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]         
    }         
    set ProjHandle $::mainDefine::result       
           
    set AnalyzerHandle [stc::get $PortHandle -children-analyzer]
    if {[string tolower $FilterType] != "offset" } {
        if {[string tolower $FilterOnStreamId] =="true"} {
            stc::config $AnalyzerHandle -FilterOnStreamId TRUE
        } else {
            stc::config $AnalyzerHandle -FilterOnStreamId FALSE
        }
    } else {
        stc::config $AnalyzerHandle -FilterOnStreamId TRUE
    }

    if {[catch {
        if {$m_filteredStreamResults == "0" } {
             set m_filteredStreamResults  [stc::subscribe -parent $ProjHandle \
                    -resultParent $PortHandle \
                    -configType analyzer \
                    -ViewAttributeList "FrameCount SigFrameCount OctetCount FcsErrorFrameCount Ipv4ChecksumErrorCount DuplicateFrameCount OutSeqFrameCount DroppedFrameCount L1BitRate L1BitCount" \
                    -resultType FilteredStreamResults ]   
             stc::config $m_filteredStreamResults -RecordsPerPage 256
        }
    } err]} {
        return $m_filteredStreamResults
    }  
   
    set args [string tolower $args]

    set index [lsearch $args -filtervalue]
    if { $index !=-1} {
        set filtervalue [lindex $args [expr $index+1]]
    } else {
        error "please specify filtervalue for CreateFilter API"
    }
    lappend m_filterConfigList $filtervalue  
    #puts "filtervalue=$filtervalue"
    
    #Config the Filter    
    if {[string tolower $FilterType] == "stack" } {   

        set filtNum [llength $filtervalue]
        set maxDepth 0
        set maxDepthIndex 0

        set frameConfig(eth.srcmac) ""
        set frameConfig(eth.dstmac) ""
        set frameConfig(vlan.id) ""
        set frameConfig(vlan.pri) ""
        set frameConfig(ipv4.srcip) ""
        set frameConfig(ipv4.dstip) ""
        set frameConfig(tcp.srcport) ""
        set frameConfig(tcp.dstport) ""
        set frameConfig(udp.srcport) ""
        set frameConfig(udp.dstport) ""
        set frameConfig(any.srcport) ""
        set frameConfig(any.dstport) ""
        set frameConfig(ipv4.protocol) ""
        set frameConfig(ipv4.tos) ""
        
        for {set i 0} {$i < $filtNum} {incr i} {
        
            set filtHdrArr($i) [lindex $filtervalue $i]
            set filtHdrArr($i) [string tolower $filtHdrArr($i)]
            set index [lsearch $filtHdrArr($i) -protocolfield]
            set protocolField [lindex $filtHdrArr($i) [expr $index + 1]]
            set depth [llength [split $protocolField :]]

            if {$depth > $maxDepth} {
                set maxDepth $depth
                set maxDepthIndex $i
            }

            set hdrList [split $protocolField :]
            
            set lastProtocolField [lindex $hdrList [expr $depth - 1]]

            set index [lsearch $filtHdrArr($i) -min]
            if { $index !=-1} {
                set min [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                error "please specify min for $filtHdrArr($i)"
            } 

            set index [lsearch $filtHdrArr($i) -max]
            if { $index !=-1} {
                set max [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                set max $min
            } 

            switch $lastProtocolField {
            
                eth.srcmac {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask FF:FF:FF:FF:FF:FF
                    } 
                    set frameConfig(eth.srcmac) "<srcMac filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</srcMac>"
                }
                    
                eth.dstmac {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask FF:FF:FF:FF:FF:FF
                    } 
                    set frameConfig(eth.dstmac) "<dstMac filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</dstMac>"
                }
                
                ipv4.srcip {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255.255.255.255
                    } 
                    set frameConfig(ipv4.srcip) "<sourceAddr filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</sourceAddr>"
                }
                
                ipv4.dstip {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255.255.255.255
                    } 
                    set frameConfig(ipv4.dstip) "<destAddr filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</destAddr>"
                }
                #################Added by Jaimin, begin##########################
                ipv4.tos {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255
                    }
                    set iMask [convertToBinary $mask]
                    set iMin [convertToBinary $min]
                    set iMax [convertToBinary $max]
                    set iMinPred [string range $iMin 0 2]
                    set iMaxPred [string range $iMax 0 2]
                    set iMaskPred [string range $iMask 0 2]
                    set iMinPred [expr [string range $iMinPred 0 0]*4+[string range $iMinPred 1 1]*2+[string range $iMinPred 2 2]]
                    set iMaxPred [expr [string range $iMaxPred 0 0]*4+[string range $iMaxPred 1 1]*2+[string range $iMaxPred 2 2]]
                    set iMaskPred [expr [string range $iMaskPred 0 0]*4+[string range $iMaskPred 1 1]*2+[string range $iMaskPred 2 2]]
                    set frameConfig(ipv4.tos) "<tosDiffserv> <tos> \
                       <precedence filterMinValue=\"$iMinPred\" filterMaxValue=\"$iMaxPred\">$iMaskPred</precedence> \
                       <dBit filterMinValue=\"[string range $iMin 3 3]\" filterMaxValue=\"[string range $iMax 3 3]\">[string range $iMask 3 3]</dBit> \
                       <tBit filterMinValue=\"[string range $iMin 4 4]\" filterMaxValue=\"[string range $iMax 4 4]\">[string range $iMask 4 4]</tBit> \
                       <rBit filterMinValue=\"[string range $iMin 5 5]\" filterMaxValue=\"[string range $iMax 5 5]\">[string range $iMask 5 5]</rBit> \
                       <mBit filterMinValue=\"[string range $iMin 6 6]\" filterMaxValue=\"[string range $iMax 6 6]\">[string range $iMask 6 6]</mBit> \
                       <reserved filterMinValue=\"[string range $iMin 7 7]\" filterMaxValue=\"[string range $iMax 7 7]\">[string range $iMask 7 7]</reserved> \
                        </tos> </tosDiffserv>"

                }
                ################Added by Jaimin, end############################
              
                ipv4.pro {
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"$min\" filterMaxValue=\"$max\">255</protocol>"
                }

               any.srcport {
                    set frameConfig(any.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                }

                any.dstport {
                    set frameConfig(any.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                }

                vlan.id {
                    set frameConfig(vlan.id) "<id filterMinValue=\"$min\" filterMaxValue=\"$max\">4095</id>"
                }                
                ########Added by Yong @ 2013.6.13 for vlan.priority begin########
				vlan.pri {
                    set min1 [dec2bin $min 2 3]
					set max1 [dec2bin $max 2 3]
					set frameConfig(vlan.pri)  "<pri filterMinValue=\"$min1\" filterMaxValue=\"$max1\">111</pri>"
                }	
				########Added by Yong @ 2013.6.13 for vlan.priority end########
                tcp.srcport {
                    set frameConfig(tcp.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"6\" filterMaxValue=\"6\">255</protocol>"
                }
                tcp.dstport {
                    set frameConfig(tcp.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"6\" filterMaxValue=\"6\">255</protocol>"
                }

                udp.srcport {
                    set frameConfig(udp.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"17\" filterMaxValue=\"17\">255</protocol>"
                }
                
                udp.dstport {
                    set frameConfig(udp.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"17\" filterMaxValue=\"17\">255</protocol>"
                }                      
            }            
        }

        set index [lsearch $filtHdrArr($maxDepthIndex) -protocolfield]
        set protocolfield [lindex $filtHdrArr($maxDepthIndex) [expr $index + 1]]
        set hdrList [split $protocolfield :]
        set lastHdr [lindex $hdrList [expr $maxDepth - 1 ]] 
        set lastHdrList [split $lastHdr .]
        set lastHdr [lindex $lastHdrList 0]
        set hdrList [lreplace $hdrList [expr $maxDepth - 1] [expr $maxDepth - 1] $lastHdr]
        
        set filterFrameConfig <frame><config><pdus>
        
        for {set currentDepth 1} {$currentDepth <= $maxDepth} {incr currentDepth} {

            set header [lindex $hdrList [expr $currentDepth - 1]]
            #puts "header=$header"

            switch $header {

                eth {
                    append filterFrameConfig "<pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">"
                    if {$frameConfig(eth.srcmac) != ""} {
                        append filterFrameConfig $frameConfig(eth.srcmac)
                    }

                    if {$frameConfig(eth.dstmac) != ""} {
                        append filterFrameConfig $frameConfig(eth.dstmac)
                    }

                    if {$currentDepth == $maxDepth } {
                        append filterFrameConfig "</pdu></pdus></config></frame>"
                    } else {
                        set nextHeader [lindex $hdrList  $currentDepth]
                        if {$nextHeader != "vlan"} {
                            append filterFrameConfig "</pdu>"
                        }
                    }
                }
                
                vlan {
                    append filterFrameConfig "<vlans><Vlan name=\"Vlan1\">"
                    if {$frameConfig(vlan.id) != ""} {
                        append filterFrameConfig $frameConfig(vlan.id)
                    }
                 ########Added by Yong @ 2013.6.13 for vlan.priority begin########
					if {$frameConfig(vlan.pri) != ""} {
						append filterFrameConfig $frameConfig(vlan.pri)
					}
					########Added by Yong @ 2013.6.13 for vlan.priority end########   
                    

                    append filterFrameConfig "</Vlan></vlans></pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }
                }
                               
                ipv4 {                
                    
                    append filterFrameConfig "<pdu name=\"IPv4_1\" pdu=\"ipv4:IPv4\">"
                    
                    if {$frameConfig(ipv4.srcip) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.srcip)
                    }

                    if {$frameConfig(ipv4.dstip) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.dstip)
                    }
                    ##### added by Jaimin, begin #################
                    
                    if {$frameConfig(ipv4.tos) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.tos)
                    }
                    ##### added by Jaimin, end   #################

                    if {$frameConfig(ipv4.protocol) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.protocol)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }
                }
                
                tcp {
                
                    append filterFrameConfig "<pdu name=\"TCP_1\" pdu=\"tcp:Tcp\">"
                    
                    if {$frameConfig(tcp.srcport) != ""} {
                        append filterFrameConfig $frameConfig(tcp.srcport)
                    }

                    if {$frameConfig(tcp.dstport) != ""} {
                        append filterFrameConfig $frameConfig(tcp.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth } {
                        append filterFrameConfig "</pdus></config></frame>"
                    }  
                }
                udp {
                
                    append filterFrameConfig "<pdu name=\"UDP_1\" pdu=\"udp:Udp\">"
                    
                    if {$frameConfig(udp.srcport) != ""} {
                        append filterFrameConfig $frameConfig(udp.srcport)
                    }

                    if {$frameConfig(udp.dstport) != ""} {
                        append filterFrameConfig $frameConfig(udp.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    } 
                }

                 any {
                
                    append filterFrameConfig "<pdu name=\"UDP_1\" pdu=\"udp:Udp\">"
                    
                    if {$frameConfig(any.srcport) != ""} {
                        append filterFrameConfig $frameConfig(any.srcport)
                    }

                    if {$frameConfig(any.dstport) != ""} {
                        append filterFrameConfig $frameConfig(any.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }  
                }
            }
        }
        
        set m_FilterType($FilterName) "STACK"
        set m_hFilter($FilterName) [stc::create  AnalyzerFrameConfigFilter \
                                                  -under $AnalyzerHandle \
                                                  -FrameConfig $filterFrameConfig\
                                                  -Active "TRUE" \
                                                  -Name $FilterName ]        
        set AnalyzerFrameConfigFilter(2) $m_hFilter($FilterName) 
        global Analyzer32BitFilter
        set Analyzer32BitFilter(1) [stc::create "Analyzer32BitFilter" \
                -under $AnalyzerFrameConfigFilter(2) \
                -LocationType "START_OF_IPV4_HDR" \
                -Index "0" \
                -Offset "12" \
                -FilterName "Source" \
                -Active "TRUE" \
                -Name "Analyzer32BitFilter 1" ]
                  
       #Create UDF filter
    } elseif { [string tolower $FilterType] == "udf" } {
        set m_FilterType($FilterName) "UDF"
        set filtNum [llength $filtervalue]
        
        for {set i 0} {$i < $filtNum} {incr i} {
        
            set filtHdrArr($i) [lindex $filtervalue $i]
            set filtHdrArr($i) [string tolower $filtHdrArr($i)]
   
            set index [lsearch $filtHdrArr($i) -pattern]        
            if { $index !=-1} {
                set pattern [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                error "please specify -pattern of UDF filter"
            } 
        
           set index [lsearch $filtHdrArr($i)  -max]
           if { $index !=-1} {
               set max [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               set max $pattern
           } 
        
           set index [lsearch $filtHdrArr($i)  -offset ]
           if { $index !=-1} {
               set offset [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               set offset 0
           }
        
           set index [lsearch $filtHdrArr($i)  -mask ]
           if { $index !=-1} {
               set mask [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               if {$pattern <= 0xffff} {
                   set mask 0xffff
               } else {
                   set mask 0xfffff
               }
           }
        
           if {$mask <= 0xffff} {
               set tmp_FilterName [stc::create "Analyzer16BitFilter" \
                                  -under $AnalyzerHandle \
                                  -Mask $mask \
                                  -StartOfRange $pattern \
                                  -EndOfRange $max \
                                  -LocationType "START_OF_FRAME" \
                                  -Offset $offset \
                                  -FilterName $FilterName \
                                  -Active "TRUE" \
                                  -Name $FilterName ]        
           } else {
                set tmp_FilterName [stc::create "Analyzer32BitFilter" \
                                  -under $AnalyzerHandle \
                                  -Mask "4294967295" \
                                  -StartOfRange $pattern \
                                  -EndOfRange $max \
                                  -LocationType "START_OF_FRAME" \
                                  -Offset $offset \
                                  -FilterName $FilterName \
                                  -Active "TRUE" \
                                  -Name $FilterName ]     
            }
            lappend m_hFilter($FilterName) $tmp_FilterName
        } 
    } elseif { [string tolower $FilterType] == "offset" } {    
         set m_FilterType($FilterName) "OFFSET"  
         lappend m_hFilter($FilterName) ""                            
    } else {
        error "invalid FilterType($FilterType),valid FilterTypes are:Stack UDF Offset"
    }
     
    debugPut "exit the proc of TestPort::CreateFilter"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigFilter
#
#Description: Config filter object
#
#Input:  1. -FilterName required,name of the filter
#          2. -FilterType required,filter type
#          3. -filtervalue required,filter value
#
#Output: None
#
#Coded by: Penn.Chen
############################################################################
::itcl::body TestPort::ConfigFilter {args} {

    debugPut "enter the proc of TestPort::ConfigFilter"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
  
    #set m_filterConfigList ""
    #Parse FilterName parameter    
    set index [lsearch $args -filtername]
    if { $index !=-1} {
        set FilterName [lindex $args [expr $index+1]]
        #Check whether filter exists in current 在m_filterNameList
        if { [lsearch $m_filterNameList $FilterName] == -1} {
            error "The FilterName($FilterName) does not exist, please specify the right one. These FilterNames are:\n$m_filterNameList"
            debugPut "exit the proc of TestPort::ConfigFilter" 
            return 1
        }
    } else {
        error "please specify FilterName for ConfigFilter API"
    } 

    set FilterOnStreamIdExist "FALSE"
    set index [lsearch $args -filteronstreamid]
    if { $index !=-1} {
        set FilterOnStreamId [lindex $args [expr $index+1]]
        set FilterOnStreamIdExist "TRUE"
    } else {
        set FilterOnStreamId "FALSE"
    }    

    #lappend m_filterConfigList $FilterName

    #Parse FilterType parameter
    set index [lsearch $args -filtertype]
    if { $index !=-1} {
        set FilterType [lindex $args [expr $index+1]]
    } else {
        error "please specify FilterType for ConfigFilter API"
    }   
    #lappend m_filterConfigList $FilterType

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
    }         
    set PortHandle $::mainDefine::result      

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {         
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]         
    }         
    set ProjHandle $::mainDefine::result       

    set AnalyzerHandle [stc::get $PortHandle -children-analyzer]
    if {$FilterOnStreamIdExist == "TRUE"} {
         if {[string tolower $FilterOnStreamId] =="true"} {
             stc::config $AnalyzerHandle -FilterOnStreamId TRUE
         } else {
             stc::config $AnalyzerHandle -FilterOnStreamId FALSE
         }
    }

    set args [string tolower $args]

    set index [lsearch $args -filtervalue]
    if { $index !=-1} {
        set filtervalue [lindex $args [expr $index+1]]
    } else {
        error "please specify filtervalue for ConfigFilter API"
    }

    set index [lsearch $m_filterConfigList $FilterName] 
    if {$index != -1} {
            set m_filterConfigList [lreplace $m_filterConfigList [expr $index + 1] [expr $index + 1] $FilterType]
            set m_filterConfigList [lreplace $m_filterConfigList [expr $index + 2] [expr $index + 2] $filtervalue]       
    }
   
    #lappend m_filterConfigList $filtervalue
    
    #Config Filter    
    if {[string tolower $FilterType] == "stack" } {   

        set filtNum [llength $filtervalue]
        set maxDepth 0
        set maxDepthIndex 0

        set frameConfig(eth.srcmac) ""
        set frameConfig(eth.dstmac) ""
        set frameConfig(vlan.id) ""
        set frameConfig(vlan.pri) ""
        set frameConfig(ipv4.srcip) ""
        set frameConfig(ipv4.dstip) ""
        set frameConfig(tcp.srcport) ""
        set frameConfig(tcp.dstport) ""
        set frameConfig(udp.srcport) ""
        set frameConfig(udp.dstport) ""
        set frameConfig(any.srcport) ""
        set frameConfig(any.dstport) ""
        set frameConfig(ipv4.protocol) ""
        set frameConfig(ipv4.tos) ""
        
        for {set i 0} {$i < $filtNum} {incr i} {
        
            set filtHdrArr($i) [lindex $filtervalue $i]
            set filtHdrArr($i) [string tolower $filtHdrArr($i)]
            set index [lsearch $filtHdrArr($i) -protocolfield]
            set protocolField [lindex $filtHdrArr($i) [expr $index + 1]]
            set depth [llength [split $protocolField :]]

            if {$depth > $maxDepth} {
                set maxDepth $depth
                set maxDepthIndex $i
            }

            set hdrList [split $protocolField :]
            
            set lastProtocolField [lindex $hdrList [expr $depth - 1]]

            set index [lsearch $filtHdrArr($i) -min]
            if { $index !=-1} {
                set min [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                error "please specify min for $filtHdrArr($i)"
            } 

            set index [lsearch $filtHdrArr($i) -max]
            if { $index !=-1} {
                set max [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                set max $min
            }     

            switch $lastProtocolField {
            
                eth.srcmac {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask FF:FF:FF:FF:FF:FF
                    } 
                    set frameConfig(eth.srcmac) "<srcMac filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</srcMac>"
                }
                    
                eth.dstmac {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask FF:FF:FF:FF:FF:FF
                    } 
                    set frameConfig(eth.dstmac) "<dstMac filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</dstMac>"
                }
                
                ipv4.srcip {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255.255.255.255
                    } 
                    set frameConfig(ipv4.srcip) "<sourceAddr filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</sourceAddr>"
                }
                
                ipv4.dstip {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255.255.255.255
                    } 
                    set frameConfig(ipv4.dstip) "<destAddr filterMinValue=\"$min\" filterMaxValue=\"$max\">$mask</destAddr>"
                }
                #################Added by Jaimin, begin##########################
                ipv4.tos {
                    set index [lsearch $filtHdrArr($i) -mask]
                    if { $index !=-1} {
                        set mask [lindex $filtHdrArr($i) [expr $index+1]]
                    } else {
                        set mask 255
                    }
                    set iMask [convertToBinary $mask]
                    set iMin [convertToBinary $min]
                    set iMax [convertToBinary $max]
                    set iMinPred [string range $iMin 0 2]
                    set iMaxPred [string range $iMax 0 2]
                    set iMaskPred [string range $iMask 0 2]
                    set iMinPred [expr [string range $iMinPred 0 0]*4+[string range $iMinPred 1 1]*2+[string range $iMinPred 2 2]]
                    set iMaxPred [expr [string range $iMaxPred 0 0]*4+[string range $iMaxPred 1 1]*2+[string range $iMaxPred 2 2]]
                    set iMaskPred [expr [string range $iMaskPred 0 0]*4+[string range $iMaskPred 1 1]*2+[string range $iMaskPred 2 2]]
                    set frameConfig(ipv4.tos) "<tosDiffserv> <tos> \
                       <precedence filterMinValue=\"$iMinPred\" filterMaxValue=\"$iMaxPred\">$iMaskPred</precedence> \
                       <dBit filterMinValue=\"[string range $iMin 3 3]\" filterMaxValue=\"[string range $iMax 3 3]\">[string range $iMask 3 3]</dBit> \
                       <tBit filterMinValue=\"[string range $iMin 4 4]\" filterMaxValue=\"[string range $iMax 4 4]\">[string range $iMask 4 4]</tBit> \
                       <rBit filterMinValue=\"[string range $iMin 5 5]\" filterMaxValue=\"[string range $iMax 5 5]\">[string range $iMask 5 5]</rBit> \
                       <mBit filterMinValue=\"[string range $iMin 6 6]\" filterMaxValue=\"[string range $iMax 6 6]\">[string range $iMask 6 6]</mBit> \
                       <reserved filterMinValue=\"[string range $iMin 7 7]\" filterMaxValue=\"[string range $iMax 7 7]\">[string range $iMask 7 7]</reserved> \
                        </tos> </tosDiffserv>"

                }
                ################Added by Jaimin, end############################
              
                ipv4.pro {
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"$min\" filterMaxValue=\"$max\">255</protocol>"
                }

                any.srcport {
                    set frameConfig(any.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                }

                any.dstport {
                    set frameConfig(any.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                }

                vlan.id {
                    set frameConfig(vlan.id) "<id filterMinValue=\"$min\" filterMaxValue=\"$max\">4095</id>"
                }
                
                ########Added by Yong @ 2013.6.13 for vlan.priority begin########
				vlan.pri {
                    set min1 [dec2bin $min 2 3]
					set max1 [dec2bin $max 2 3]
					set frameConfig(vlan.pri)  "<pri filterMinValue=\"$min1\" filterMaxValue=\"$max1\">111</pri>"
                }		
				########Added by Yong @ 2013.6.13 for vlan.priority end########                

                tcp.srcport {
                    set frameConfig(tcp.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"6\" filterMaxValue=\"6\">255</protocol>"
                }
                tcp.dstport {
                    set frameConfig(tcp.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"6\" filterMaxValue=\"6\">255</protocol>"
                }

                udp.srcport {
                    set frameConfig(udp.srcport) "<sourcePort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</sourcePort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"17\" filterMaxValue=\"17\">255</protocol>"
                }
                
                udp.dstport {
                    set frameConfig(udp.dstport) "<destPort filterMinValue=\"$min\" filterMaxValue=\"$max\">65535</destPort>"
                    set frameConfig(ipv4.protocol) "<protocol filterMinValue=\"17\" filterMaxValue=\"17\">255</protocol>"
                }                      
            }            
        }

        set index [lsearch $filtHdrArr($maxDepthIndex) -protocolfield]
        set protocolfield [lindex $filtHdrArr($maxDepthIndex) [expr $index + 1]]
        set hdrList [split $protocolfield :]
        set lastHdr [lindex $hdrList [expr $maxDepth - 1 ]] 
        set lastHdrList [split $lastHdr .]
        set lastHdr [lindex $lastHdrList 0]
        set hdrList [lreplace $hdrList [expr $maxDepth - 1] [expr $maxDepth - 1] $lastHdr]
        
        set filterFrameConfig <frame><config><pdus>
        
        for {set currentDepth 1} {$currentDepth <= $maxDepth} {incr currentDepth} {

            set header [lindex $hdrList [expr $currentDepth - 1]]
            #puts "header=$header"

            switch $header {

                eth {
                    append filterFrameConfig "<pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">"
                    if {$frameConfig(eth.srcmac) != ""} {
                        append filterFrameConfig $frameConfig(eth.srcmac)
                    }

                    if {$frameConfig(eth.dstmac) != ""} {
                        append filterFrameConfig $frameConfig(eth.dstmac)
                    }

                    if {$currentDepth == $maxDepth } {
                        append filterFrameConfig "</pdu></pdus></config></frame>"
                    } else {
                        set nextHeader [lindex $hdrList  $currentDepth]
                        if {$nextHeader != "vlan"} {
                            append filterFrameConfig "</pdu>"
                        }
                    }
                }
                
                vlan {
                    append filterFrameConfig "<vlans><Vlan name=\"Vlan1\">"
                    if {$frameConfig(vlan.id) != ""} {
                        append filterFrameConfig $frameConfig(vlan.id)
                    }
                    ########Added by Yong @ 2013.6.13 for vlan.priority begin########
					if {$frameConfig(vlan.pri) != ""} {
						append filterFrameConfig $frameConfig(vlan.pri)
					}
					########Added by Yong @ 2013.6.13 for vlan.priority end########

                    append filterFrameConfig "</Vlan></vlans></pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }
                }
                               
                ipv4 {                
                    
                    append filterFrameConfig "<pdu name=\"IPv4_1\" pdu=\"ipv4:IPv4\">"
                    
                    if {$frameConfig(ipv4.srcip) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.srcip)
                    }

                    if {$frameConfig(ipv4.dstip) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.dstip)
                    }
                    ##### added by Jaimin, begin #################
                    
                    if {$frameConfig(ipv4.tos) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.tos)
                    }
                    ##### added by Jaimin, end   #################

                    if {$frameConfig(ipv4.protocol) != ""} {
                        append filterFrameConfig $frameConfig(ipv4.protocol)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }
                }
                
                tcp {
                
                    append filterFrameConfig "<pdu name=\"TCP_1\" pdu=\"tcp:Tcp\">"
                    
                    if {$frameConfig(tcp.srcport) != ""} {
                        append filterFrameConfig $frameConfig(tcp.srcport)
                    }

                    if {$frameConfig(tcp.dstport) != ""} {
                        append filterFrameConfig $frameConfig(tcp.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth } {
                        append filterFrameConfig "</pdus></config></frame>"
                    }
                }
                udp {
                
                    append filterFrameConfig "<pdu name=\"UDP_1\" pdu=\"udp:Udp\">"
                    
                    if {$frameConfig(udp.srcport) != ""} {
                        append filterFrameConfig $frameConfig(udp.srcport)
                    }

                    if {$frameConfig(udp.dstport) != ""} {
                        append filterFrameConfig $frameConfig(udp.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }  
                }

                 any {
                
                    append filterFrameConfig "<pdu name=\"UDP_1\" pdu=\"udp:Udp\">"
                    
                    if {$frameConfig(any.srcport) != ""} {
                        append filterFrameConfig $frameConfig(any.srcport)
                    }

                    if {$frameConfig(any.dstport) != ""} {
                        append filterFrameConfig $frameConfig(any.dstport)
                    }

                    append filterFrameConfig "</pdu>"

                    if {$currentDepth == $maxDepth} {
                        append filterFrameConfig "</pdus></config></frame>"
                    }  
                }
            }
        }
        
        DeleteFilterHandle $FilterName
        set m_hFilter($FilterName) [stc::create  AnalyzerFrameConfigFilter \
                                                    -under $AnalyzerHandle \
                                                    -FrameConfig $filterFrameConfig\
                                                    -Active "TRUE" \
                                                    -Name $FilterName ]        
        set AnalyzerFrameConfigFilter(2) $m_hFilter($FilterName) 
        global Analyzer32BitFilter
        set Analyzer32BitFilter(1) [stc::create "Analyzer32BitFilter" \
                -under $AnalyzerFrameConfigFilter(2) \
                -LocationType "START_OF_IPV4_HDR" \
                -Index "0" \
                -Offset "12" \
                -FilterName "Source" \
                -Active "TRUE" \
                -Name "Analyzer32BitFilter 1" ]
         set m_FilterType($FilterName) "STACK"
         #Config UDF filter
    } elseif { [string tolower $FilterType] == "udf" } {
        DeleteFilterHandle $FilterName

        set filtNum [llength $filtervalue]

        for {set i 0} {$i < $filtNum} {incr i} {
        
            set filtHdrArr($i) [lindex $filtervalue $i]
            set filtHdrArr($i) [string tolower $filtHdrArr($i)]
   
            set index [lsearch $filtHdrArr($i) -pattern]        
            if { $index !=-1} {
                set pattern [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                error "please specify -pattern of UDF filter"
            } 
        
           set index [lsearch $filtHdrArr($i)  -max]
           if { $index !=-1} {
               set max [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               set max $pattern
           } 
        
           set index [lsearch $filtHdrArr($i)  -offset ]
           if { $index !=-1} {
               set offset [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               set offset 0
           }
        
           set index [lsearch $filtHdrArr($i)  -mask ]
           if { $index !=-1} {
               set mask [lindex $filtHdrArr($i) [expr $index+1]]
           } else {
               if {$pattern <= 0xffff} {
                   set mask 0xffff
               } else {
                   set mask 0xfffff
               }
           }
        
           if {$mask <= 0xffff} {
               set tmp_FilterName [stc::create "Analyzer16BitFilter" \
                                  -under $AnalyzerHandle \
                                  -Mask "0xffff" \
                                  -StartOfRange $pattern \
                                  -EndOfRange $max \
                                  -LocationType "START_OF_FRAME" \
                                  -Offset $offset \
                                  -FilterName $FilterName \
                                  -Active "TRUE" \
                                  -Name $FilterName ]        
        
           } else {
                set tmp_FilterName [stc::create "Analyzer32BitFilter" \
                                  -under $AnalyzerHandle \
                                  -Mask "4294967295" \
                                  -StartOfRange $pattern \
                                  -EndOfRange $max \
                                  -LocationType "START_OF_FRAME" \
                                  -Offset $offset \
                                  -FilterName $FilterName \
                                  -Active "TRUE" \
                                  -Name $FilterName ]     
        
            }
            lappend m_hFilter($FilterName) $tmp_FilterName
        }
        set m_FilterType($FilterName) "UDF"
    } elseif { [string tolower $FilterType] == "offset" } { 
         DeleteFilterHandle $FilterName   
         lappend m_hFilter($FilterName) ""  
         set m_FilterType($FilterName) "OFFSET"                                  
    } else {
        error "invalid FilterType($FilterType),valid FilterTypes are:Stack UDF "
    }
     
    debugPut "exit the proc of TestPort::ConfigFilter"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyFilter
#
#Description: Destroy Filter object
#
#Input:  1. -FilterName required,filter name, if no parameter specified,
#              all the filter objects will be destroyed
#
#Output: None
#
#Coded by: Penn.Chen
############################################################################
::itcl::body TestPort::DestroyFilter {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TestPort::DestroyFilter"
    #Parse parameters    
    set index [lsearch $args -filtername]
    if { $index != -1} {
        set FilterName [lindex $args [expr $index+1]]
        set DeleteAllFilter "FALSE"
        
        #Check whether or not filter exists in m_filterNameList
        if { [lsearch $m_filterNameList $FilterName] == -1} {
            error "The FilterName($FilterName) does not existed, please specify the right one. These existed FilterNames are:\n$m_filterNameList"
            debugPut "exit the proc of TestPort::DestroyFilter" 
            return 1
        }          
    } else {
        set DeleteAllFilter "TRUE"
    }    

    #Destroy filter object
    if {$DeleteAllFilter == "TRUE"} {
        foreach filter $m_filterNameList {
            DeleteFilterHandle $filter                     
        }
        set m_filterNameList ""   
        set m_filterConfigList ""  
    } else {
        set index [lsearch $m_filterNameList $FilterName]
        if { $index != -1} { 
            DeleteFilterHandle $FilterName

            set m_filterNameList [lreplace $m_filterNameList $index $index ]
            set index [lsearch $m_filterConfigList $FilterName]
            set m_filterConfigList [lreplace $m_filterConfigList $index [expr $index+2]]
       }        
    }        
    debugPut "exit the proc of TestPort::DestroyFilter"

    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: StartTraffic
#
#Description: Start traffic transmission of the port
#
#Input: 1. –StreamNameList {Stream1 Stream2},required,the stream list to be sent \
#               i.e –StreamNameList {Stream1 Stream2}, Stream1 and Stream2 will be started
#               if not parameter specified, all the streams on the port will be covered
#       2. -ProfileList {Profile1 Profile2},optional,profile list
#              
#
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestPort::StartTraffic {args} {
     
    set streamBlockHandleList ""
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestPort::StartTraffic"
    
    set StreamListFlag 0
    set ProfileListFlag 0

    #Parse StreamNameList or StreamList
    set sargs ""
    set index [lsearch $args -streamlist]
    if { $index == -1} {
        set index [lsearch $args -streamnamelist]
        if { $index !=-1} {
            set sargs [lindex $args [expr $index+1]]
            set StreamListFlag 1
        } else {
            set sargs ""
        }
    } else {
        set sargs [lindex $args [expr $index+1]]
        set StreamListFlag 1
    } 

    #Parse ProfileList parameter
    set index [lsearch $args -profilelist]
    if { $index !=-1} {
        set sargs ""
        set profilelist [lindex $args [expr $index+1]]
        set ProfileListFlag 1        
    } else {
        set profilelist ""
    }  

    #Parse ClearStatistic parameter
    set index [lsearch $args -clearstatistic]
    if { $index !=-1} {
        set ClearStatistic [lindex $args [expr $index+1]]  
    } else {
        set ClearStatistic 1
    }  
  
    if {$ProfileListFlag == "1" && $StreamListFlag == "1"} {
        debugPut "StreamNameList and ProfileList can not be used both"
        return $::mainDefine::gFail        
    } 
    
    #Parse FlagArp parameter
    set index [lsearch $args -flagarp]
    if { $index !=-1} {
        set FlagArp [lindex $args [expr $index+1]]  
    } else {
        set FlagArp "FALSE"
    }  
    set FlagArp [string tolower $FlagArp] 

    set trafficObject [lindex $m_trafficNameList 0]   
    set ::mainDefine::objectName $trafficObject 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_trafficProfileList]
    }
    set trafficProfileList $::mainDefine::result 
    
    set profile_sargs ""
    #Check whether profileList中 contains the profile
    foreach sr $profilelist {
        if {[lsearch $trafficProfileList $sr] == -1 } {
            puts "profile($sr) is not exist, existing traffic profiles are $trafficProfileList"
            return $::mainDefine::gSuccess            
        }
       set ::mainDefine::objectName $trafficObject
       set ::mainDefine::profileName $sr
       uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName GetProfileContent $::mainDefine::profileName]
       }
       set trafficProfileContent $::mainDefine::result
  
        foreach items $trafficProfileContent {
             lappend profile_sargs $items
        }
    }
   
    if {$profile_sargs != ""} {
        set sargs ""
        set profileNum [llength $profile_sargs ]
        
        for {set i 0} {$i < $profileNum} {incr i} {          
            set profileHdrArr($i) [lindex $profile_sargs $i]
            foreach stream $profileHdrArr($i) {
                  lappend sargs $stream
            }
        }
    }

   set portState [stc::get $m_hPort -Online]
   if {[string tolower $portState] == "false"} {
       error "The port: $m_portName is offline\nexit the proc of TestPort::StartTraffic"
   }

   if {$::mainDefine::gAutoCheckLinkState == "TRUE" } {
       array set linkStateArray [stc::perform PhyVerifyLinkUp -PortList $m_hPort]
       set linkState $linkStateArray(-PassFailState)
       if {$linkState != "PASSED"} {

           #Clear the statistics on the port
           set ::mainDefine::objectName $m_chassisName 
           uplevel 1 {         
               set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]         
           }
           set testPortObjectList $::mainDefine::result     
         
           if {$ClearStatistic == 1} {
               #All the statistics information will be cleared at this moment           
               set portHandleList ""
               foreach testPortObject $testPortObjectList {
                   set ::mainDefine::objectName $testPortObject
                   uplevel 1 {         
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                   }  
                   set portHandle $::mainDefine::result     
                  lappend portHandleList $portHandle
               } 
       
               stc::perform ResultsClearAll -PortList $portHandleList
            }

            puts "The link state of $m_portName is not UP, please check ..."
            debugPut "exit the proc of TestPort::StartTraffic"
            return $::mainDefine::gSuccess 
       }
   }

   foreach traffic $m_trafficNameList {
       
       if {$ProfileListFlag == "1"} {
             #Suppose the user inputs ProfileList
             set ::mainDefine::objectName $traffic 
             set ::mainDefine::profileName $profilelist
             uplevel 1 {         
                 set ::mainDefine::result [$::mainDefine::objectName ApplyProfileToPort $::mainDefine::profileName "profile" ]         
             }     
             set frameNumOfBlocking  $::mainDefine::result    
        } elseif {$StreamListFlag == "1"} {
             #Suppose the user inputs StreamList
             set ::mainDefine::objectName $traffic 
             set ::mainDefine::streamName $sargs
             uplevel 1 {         
                 set ::mainDefine::result [$::mainDefine::objectName ApplyProfileToPort $::mainDefine::streamName "stream"]
             }   
             set frameNumOfBlocking  $::mainDefine::result
        } else { 
             #Suppose user start all the streams on the port
             set ::mainDefine::objectName $traffic 
             uplevel 1 {         
                 set ::mainDefine::result [$::mainDefine::objectName ApplyProfileToPort "all" "profile"]
             }   
             set frameNumOfBlocking  $::mainDefine::result    
            
        }

       if {$frameNumOfBlocking != 0} {
           set m_blocking Enable
           set m_frameNumOfBlocking $frameNumOfBlocking 
       } else {
           set m_blocking Disable
       }

       set m_streamBasedSchedulingSetted 1
    }
       
    if { [string equal $sargs ""] == 1 } {
        #Start the traffic transmission of all the streams
        foreach streamBlockHandle "[stc::get $m_hPort -children-StreamBlock]" {
            stc::config $streamBlockHandle -Active "TRUE"
        }

        #Apply the configuration to the chassis  
        if { [catch {
            stc::apply 
            after 3000 
        } err]} {
            set ::mainDefine::gChassisObjectHandle $m_chassisName 
            garbageCollect
            error "Apply config failed when calling StartTraffic, the error message is:$err" 
        }

        #Start the StaEngine and captuer functionality of the port
        set ::mainDefine::objectName $m_chassisName 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]         
        }
        set testPortObjectList $::mainDefine::result     
         
        if {$ClearStatistic == 1} {
             #Clear all the traffic statistics            
             set portHandleList ""
             foreach testPortObject $testPortObjectList {
                 set ::mainDefine::objectName $testPortObject
                 uplevel 1 {         
                      set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                 }  
                 set portHandle $::mainDefine::result     
                 lappend portHandleList $portHandle
             } 
       
             stc::perform ResultsClearAll -PortList $portHandleList
        }

        if {$FlagArp == "true"} {
            #Start ARP learning
            debugPut "Try to do ARP request for the port:$m_hPort ..."
            catch {stc::perform ArpNdStart -HandleList $m_hPort}
        } elseif {$::mainDefine::gStreamBindingFlag == "TRUE"} {
            #Start ARP learning
            debugPut "Try to do ARP request for the port:$m_hPort ..."
            catch {stc::perform ArpNdStart -HandleList $m_hPort}
        }

        if {$m_StaEngineState == "PENDING"} {
              RealStartStaEngine $ClearStatistic 
        }

        foreach testPortObject $testPortObjectList {
              set ::mainDefine::objectName $testPortObject 
              set ::mainDefine::objectPara $ClearStatistic
            
              uplevel 1 {         
                    $::mainDefine::objectName RealStartStaEngine $::mainDefine::objectPara        
              }
        }
        debugPut "Finish starting all the StaEngine objects ..."

        #Start all the capture functionality
        foreach testPortObject $testPortObjectList {
             set ::mainDefine::objectName $testPortObject
              uplevel 1 {         
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_staEngineList]         
              }  
              set staEngineObjectList $::mainDefine::result     
              
              foreach staEngineObject $staEngineObjectList {

                   set ::mainDefine::objectName $staEngineObject
                   uplevel 1 {
                          set ::mainDefine::result [$::mainDefine::objectName isa TestAnalysis]
                          if {$::mainDefine::result} { 
                               $::mainDefine::objectName RealConfigCaptureMode      
                               $::mainDefine::objectName RealStartCapture  
                          }
                    } 
              }
         }
         debugPut "Finish starting all the Capture objects ..."
        
         #启动generator
         set generator [stc::get $m_hPort -children-Generator]
         set errorCode 1
         if {[catch {
             set state [stc::get $generator -state]
             if {$state == "STOPPED" } {
                   set errorCode [stc::perform GeneratorStart -GeneratorList $generator  -ExecuteSynchronous TRUE  ]    
             } elseif {$state == "RUNNING"} {
                   #Stop first, then start again
                   debugPut "The generator of port: $m_portName in running state, take actions to re-start it"
                   set errorCode [stc::perform GeneratorStop -GeneratorList $generator  -ExecuteSynchronous TRUE ]
                   after 1000 
                   set errorCode [stc::perform GeneratorStart -GeneratorList $generator  -ExecuteSynchronous TRUE ]
             }
             
             debugPut "Finish starting the traffic generator ..."
         } err]} {
            return $errorCode
        }
    } else {  
         #Start the streams in StreamNameList
         set streamList ""
         foreach traffic $m_trafficNameList {
            
            set ::mainDefine::objectName $traffic 
            uplevel 1 {         
                set ::mainDefine::result [$::mainDefine::objectName cget -m_streamNameList]         
            }         
            set streamNameList $::mainDefine::result 
    
             foreach stream $streamNameList {

                 set ::mainDefine::objectName $stream 
                 uplevel 1 {         
                     set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                 }         
                 set hStream $::mainDefine::result 
            
                 set state [stc::get $hStream -RunningState]
                 if {$state != "RUNNING"} {
                     stc::config $hStream -Active "FALSE"
                 }

                 lappend streamList $stream
             }
         }
         set hStreamList ""
         foreach stream $sargs {
             set index [lsearch $streamList $stream]
             if {$index == -1} {
                 error "the streamName($stream) does not exist. The existed streamName(s) is(are):\n $streamList"
             } else {
                 
                 set ::mainDefine::objectName $stream 
                 uplevel 1 {         
                     set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                 }         
                 set hStream $::mainDefine::result 
            
                 stc::config $hStream -Active "TRUE"
                 set state [stc::get $hStream -RunningState]
                 if {$state != "RUNNING"} {
                     lappend hStreamList $hStream
                } else {
                     debugPut "The stream $hStream already in running state, skipping it"
                }
             }
         }

         #Apply the configuration to the chassis
         if { [catch {
             stc::apply 
             after 3000 
         } err]} {
             set ::mainDefine::gChassisObjectHandle $m_chassisName 
             garbageCollect
             error "Apply config failed when calling StartTraffic, the error message is:$err" 
        }

         #Start the StaEngine of the port
         set ::mainDefine::objectName $m_chassisName 
         uplevel 1 {         
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]         
         }         
         set testPortObjectList $::mainDefine::result

         if {$ClearStatistic == 1} {
             #Clear traffic statistics            
             set portHandleList ""
             foreach testPortObject $testPortObjectList {
                 set ::mainDefine::objectName $testPortObject
                 uplevel 1 {         
                      set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                 }  
                set portHandle $::mainDefine::result     
                lappend portHandleList $portHandle
            } 
            
            stc::perform ResultsClearAll -PortList $portHandleList
        }

        if {$FlagArp == "true"} {
            #Start ARP learning ...
            debugPut "Try to do ARP request for the port:$m_hPort ..."
            catch {stc::perform ArpNdStart -HandleList $m_hPort}
        } elseif {$::mainDefine::gStreamBindingFlag == "TRUE"} {
            #Start ARP learning ...
            debugPut "Try to do ARP request for the port:$m_hPort ..."
            catch {stc::perform ArpNdStart -HandleList $m_hPort}
        }

        if {$m_StaEngineState == "PENDING"} {
              RealStartStaEngine $ClearStatistic
        }

        foreach testPortObject $testPortObjectList {
              set ::mainDefine::objectName $testPortObject 
              set ::mainDefine::objectPara $ClearStatistic
              uplevel 1 {         
                    $::mainDefine::objectName RealStartStaEngine $::mainDefine::objectPara        
              }
        }
        debugPut "Finish starting all the StaEngine objects ..."
        
        #Start the capture object
        foreach testPortObject $testPortObjectList {
             set ::mainDefine::objectName $testPortObject
              uplevel 1 {         
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_staEngineList]         
              }  
              set staEngineObjectList $::mainDefine::result     
              
              foreach staEngineObject $staEngineObjectList {

                   set ::mainDefine::objectName $staEngineObject
                   uplevel 1 {
                          set ::mainDefine::result [$::mainDefine::objectName isa TestAnalysis]
                          if {$::mainDefine::result} { 
                               $::mainDefine::objectName RealConfigCaptureMode      
                               $::mainDefine::objectName RealStartCapture  
                          }
                    } 
              }
         }
         debugPut "Finish starting all the Capture objects ..."
       
         set errorCode 1
         if {[catch {
             if {$hStreamList != ""} {
                  set errorCode [stc::perform StreamBlockStart -StreamBlockList $hStreamList  -ExecuteSynchronous TRUE ]
             }
              debugPut "Finish starting the traffic generator ..."
         } err]} {
            return $errorCode
        }
    }  
     
    if {[string tolower $m_blocking] == "enable"} {    
        set waitTime 2000
        after $waitTime 
        
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
        }         
        set PortHandle $::mainDefine::result 
                 
        set GeneratorHandle [stc::get $PortHandle -children-Generator]
        set GeneratorPortResultHandle [stc::get $GeneratorHandle -children-GeneratorPortResults]         
        set txFrames [stc::get $GeneratorPortResultHandle -GeneratorFrameCount]

        set loopCount 0  
        while {$txFrames < $m_frameNumOfBlocking} {
            puts "Waiting for transmit complete..."
            puts "Number of transmitted frames is: $txFrames"
            puts "Number of frames waiting to be transmitted is: [expr $m_frameNumOfBlocking - $txFrames]"
            set txFramesOld $txFrames 
            set waitTime 1000
            after $waitTime
        
            set txFrames [stc::get $GeneratorPortResultHandle -GeneratorFrameCount]
            if {$txFrames == $txFramesOld} {
                set loopCount [expr $loopCount + 1] 
            }

            if {$loopCount == 30} {
                puts "The StartTraffic waiting is in dead loop, please check ..."
                break  
            } 
        }
    }

    set m_generatorStarted "TRUE"
    set m_streamStatisticRefershed "FALSE"
    set ::mainDefine::gGeneratorStarted "TRUE"  

    debugPut "exit the proc of TestPort::StartTraffic"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopTraffic
#
#Description: Stop the traffic transimission of the port
#
#Input: 1. –StreamNameList {Stream1 Stream2},optional,the stream list to be stopped 
#              i.e –StreamNameList {Stream1 Stream2}, means to stop Stream1 and Stream2
#               if no parameter specified, all the streams will be covered
#         2. -ProfileList optional,the profile list to be stopped          
#              
#Output: None
#
#Coded by: rody.ou
#Modified by:Penn
#############################################################################
::itcl::body TestPort::StopTraffic {args} {
     
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestPort::StopTraffic"

    set StreamListFlag 0
    set ProfileListFlag 0

    #Parse StreamNameList or StreamList parameter
    set sargs ""
    set index [lsearch $args -streamlist]
    if { $index == -1} {
        set index [lsearch $args -streamnamelist]
        if { $index !=-1} {
            set sargs [lindex $args [expr $index+1]]
            set StreamListFlag 1
        } else {
            set sargs ""
        }
    } else {
        set sargs [lindex $args [expr $index+1]]
        set StreamListFlag 1
    } 

    #Parse ProfileList parameter
    set index [lsearch $args -profilelist]
    if { $index !=-1} {
        set sargs ""
        set profilelist [lindex $args [expr $index+1]]
        set ProfileListFlag 1        
    } else {
        set profilelist ""
    }  

    if {$ProfileListFlag == "1" && $StreamListFlag == "1"} {
        debugPut "StreamNameList and ProfileList can not be used both"
        return $::mainDefine::gFail        
    }

     set trafficObject [lindex $m_trafficNameList 0]   
     set ::mainDefine::objectName $trafficObject 
     uplevel 1 {
         set ::mainDefine::result [$::mainDefine::objectName cget -m_trafficProfileList]
     }
     set trafficProfileList $::mainDefine::result  
  
    set profile_sargs ""
    #Check whether or not profile exists in profileList
    foreach sr $profilelist {
        if {[lsearch $trafficProfileList $sr] == -1 } {
            puts "profile($sr) does not exist, existing traffic profiles are: $trafficProfileList"
            return $::mainDefine::gSuccess            
        }
       set ::mainDefine::objectName $trafficObject
       set ::mainDefine::profileName $sr
       uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName GetProfileContent $::mainDefine::profileName]
       }
       set trafficProfileContent $::mainDefine::result
       
        foreach items $trafficProfileContent {
             lappend profile_sargs $items
        }
    }
   
     if {$profile_sargs != ""} {
        set sargs ""
        set profileNum [llength $profile_sargs ]
        
        for {set i 0} {$i < $profileNum} {incr i} {          
            set profileHdrArr($i) [lindex $profile_sargs $i]
            foreach stream $profileHdrArr($i) {
                  lappend sargs $stream
            }
        }
    }

    set portState [stc::get $m_hPort -Online]
    if {[string tolower $portState] == "false"} {
         error "The port: $m_portName is offline\nexit the proc of TestPort::StopTraffic"
    }

    if {$::mainDefine::gAutoCheckLinkState == "TRUE" } {
        array set linkStateArray [stc::perform PhyVerifyLinkUp -PortList $m_hPort]
        set linkState $linkStateArray(-PassFailState)
        if {$linkState != "PASSED"} {
            puts "The link state of $m_portName is not UP, please check ..."
            debugPut "exit the proc of TestPort::StopTraffic"
            return $::mainDefine::gSuccess 
        }
    }

    if { [string equal $sargs ""] == 1 } {
         #Stop all the traffic transmission
         foreach streamBlockHandle "[stc::get $m_hPort -children-StreamBlock]" {
             stc::config $streamBlockHandle -Active "TRUE"
         }
         
         #Stop the generator
         set generator [stc::get $m_hPort -children-Generator]
         set errorCode 1
         if {[catch {
             set state [stc::get $generator -state]
             set loop 0
             while {$state == "PENDING_START" } {
                 if {$loop == "20"} {
                     debugPut "Timeout to wait for the generator to be started in PENDING_START state"
                     debugPut "exit the proc of TestPort::StopTraffic"
                     return $::mainDefine::gSuccess
                 }

                 set loop [expr $loop + 1]
                 after 500
          
                 debugPut "Waiting for the generator to be started when in PENDING_START state" 
                 set state [stc::get $generator -state]
             }

             if {$state != "STOPPED" } {
                 set errorCode [stc::perform GeneratorStop -GeneratorList $generator  -ExecuteSynchronous TRUE]
             }
         } err]} {
            return $errorCode
        }

        set generator [stc::get $m_hPort -children-Generator]
        set state [stc::get $generator -state]
        set loop 0
        while {$state != "STOPPED" } {
            if {$loop == "20"} {
                 debugPut "Timeout to wait for the generator to be stopped"
                 debugPut "exit the proc of TestPort::StopTraffic"
                 return $::mainDefine::gSuccess
            }

            set loop [expr $loop + 1]
            after 500
          
            debugPut "Waiting for the generator to be stopped" 
            set state [stc::get $generator -state]
        }
    } else {  
         #Stop the streams in StreamNameList
         set streamList ""
         foreach traffic $m_trafficNameList {

             set ::mainDefine::objectName $traffic 
             uplevel 1 {         
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_streamNameList]         
             }         
             set streamNameList $::mainDefine::result 
        
             foreach stream $streamNameList {
                 lappend streamList $stream
             }
         }
         set hStreamList ""
         foreach stream $sargs {
             set index [lsearch $streamList $stream]
             if {$index == -1} {
                 error "the streamName($stream) does not exist. The existed streamName(s) is(are):\n $streamList"
             } else {
                 
                 set ::mainDefine::objectName $stream 
                 uplevel 1 {         
                     set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                 }         
                 set hStream $::mainDefine::result 
             
                 stc::config $hStream -Active "TRUE"
                 set state [stc::get $hStream -RunningState]
                 if {$state == "RUNNING"} {
                     lappend hStreamList $hStream
                 }
             }
         }           
       
         set errorCode 1
         if {[catch {
             if {$hStreamList != ""} {
                 set errorCode [stc::perform StreamBlockStop -StreamBlockList $hStreamList -ExecuteSynchronous TRUE ]
             }
         } err]} {
            return $errorCode
        }

        set loop 0
        while {$loop < 21} {
            if {$loop == "20"} {
                 debugPut "Timeout to wait for the generator to be stopped"
                 debugPut "exit the proc of TestPort::StopTraffic"
                 return $::mainDefine::gSuccess
            }

            set loop [expr $loop + 1]

            set flag 0
            foreach hStream $hStreamList {
                  set state [stc::get $hStream -RunningState]
                  if {$state != "STOPPED"} {
                       set flag 1
                       break
                  }
            }

            if {$flag == 1} {
                 debugPut "Waiting for the generator to be stopped" 
                 after 500
            } else {
                 debugPut "exit the proc of TestPort::StopTraffic"
                 return $::mainDefine::gSuccess
            }
        }
    }
  
    debugPut "exit the proc of TestPort::StopTraffic"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetPortState
#Description: Get the port state
#Input: 1. args:argument list, including the following
#              (1) -PhyState PhyState optional,physical link state, i.e -PhyState PhyState  
#              (2) -linkState linkState optioinal，link state, i.e -linkState linkState
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TestPort::GetPortState {args} {
    #global PhyState linkState
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestPort::GetPortState..."
    
    #Set default PhyState value
    set index [lsearch $args -phystate] 
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] iPhy
        set iPhy UP
    }
    
    #Set linkState state
    set index [lsearch $args -linkstate] 
    if {$index != -1} {
        upvar [lindex $args [expr $index + 1]] ilink 
        stc::apply
        catch {set iPortlink1 [stc::get [stc::get $m_hPort -children-EthernetFiber] -LinkStatus] } err
        catch {set iPortlink2 [stc::get [stc::get $m_hPort -children-EthernetCopper] -LinkStatus] } err
        if {[info exists iPortlink1]} {
            if {[string toupper $iPortlink1] =="UP"} {
                set ilink "UP"            
            } elseif {[string toupper $iPortlink1] =="DOWN"} {
                set ilink "DOWN"
            } elseif {[string toupper $iPortlink1] =="NONE"} {
                set ilink "NOLINK"
            }        
        }
        if {[info exists iPortlink2]} {
            if {[string toupper $iPortlink2] =="UP"} {
                set ilink "UP"            
            } elseif {[string toupper $iPortlink2] =="DOWN"} {
                set ilink "DOWN"
            } elseif {[string toupper $iPortlink2] =="NONE"} {
                set ilink "NOLINK"
            }        
        }
    }    
    debugPut "exit the proc of TestPort::GetPortState..."
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateHost
#Description: Create host on the port
#Input: For the details please refer to the user manual
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TestPort::CreateHost {args} {
    
    set args [ConvertAttrToLowerCase $args]
    debugPut "enter the proc of TestPort::CreateHost..."
        
    #Parse HostName parameter
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error " Please specify HostName parameter \nexit the proc of CreateHost..."
    }

    #Check whether or HostName already exists
    set index [lsearch $m_hostNameList $HostName]
    if { $index !=-1} {
        error "the HostName($HostName) is already existed, please specify another one. \
        The existed HostName is (are) as following:\n$m_hostNameList"
    } 
    lappend m_hostNameList $HostName

    #Parse IpVersion parameter
    set index [lsearch $args -ipversion] 
    if {$index != -1} {
        set IpVersion [lindex $args [expr $index + 1]]
    } else  {
        set IpVersion ipv4
    }
    set IpVersion [string tolower $IpVersion]

    #Parse HostType parameter
    set index [lsearch $args -hosttype] 
    if {$index != -1} {
        set HostType [lindex $args [expr $index + 1]]
    } else  {
        set HostType "normal"
    }
    set HostType [string tolower $HostType]
    set m_hostTypeList($HostName) $HostType
    
    #Parse Ipv4Addr parameter
    set index [lsearch $args -ipv4addr] 
    if {$index != -1} {
        set Ipv4Addr [lindex $args [expr $index + 1]]
        set IpVersion ipv4
    } else  {
        set Ipv4Addr "192.168.1.2"
    }
    
    #Parse Ipv4StepMask parameter
    set index [lsearch $args -ipv4stepmask] 
    if {$index != -1} {
        set Ipv4StepMask [lindex $args [expr $index + 1]]
        set IpVersion ipv4
    } else  {
        set Ipv4StepMask "0.0.0.255"
    }

    #Parse Ipv4SutAddr parameter
    set index [lsearch $args -ipv4sutaddr] 
    if {$index != -1} {
        set Ipv4AddrGateway [lindex $args [expr $index + 1]]
        set IpVersion ipv4
    } else {
        set index [lsearch $args -ipv4addrgateway] 
        if {$index != -1} {
            set Ipv4AddrGateway [lindex $args [expr $index + 1]]
            set IpVersion ipv4
        } else  {
            set Ipv4AddrGateway 192.168.1.1
        }
    }
    
    #Parse Ipv4Mask parameter
    set index [lsearch $args -ipv4mask] 
    if {$index != -1} {
        set Ipv4AddrPrefixLen [lindex $args [expr $index + 1]]
        set IpVersion ipv4
    } else {
        set index [lsearch $args -ipv4addrprefixlen] 
        if {$index != -1} {
            set Ipv4AddrPrefixLen [lindex $args [expr $index + 1]]
            set IpVersion ipv4
        } else  {
            set Ipv4AddrPrefixLen 24
        }
    }
    
    #Parse Ipv6Addr parameter
    set index [lsearch $args -ipv6addr] 
    if {$index != -1} {
        set Ipv6Addr [lindex $args [expr $index + 1]]
        set IpVersion ipv6
    } else  {
        set Ipv6Addr "2000:201::1:2"
    }
    
    #Parse Ipv6StepMask parameter
    set index [lsearch $args -ipv6stepmask] 
    if {$index != -1} {
        set Ipv6StepMask [lindex $args [expr $index + 1]]
        set IpVersion ipv6
    } else  {
        set Ipv6StepMask "0000::FFFF:FFFF:FFFF:FFFF"
    }

    #Parse Ipv6LinkLocalAddr parameter
    set index [lsearch $args -ipv6linklocaladdr] 
    if {$index != -1} {
        set Ipv6LinkLocalAddr [lindex $args [expr $index + 1]]
    } else  {
        set Ipv6LinkLocalAddr fe80::
    }
    
    #Parse Ipv6SutAddr parameter
    set index [lsearch $args -ipv6sutaddr] 
    if {$index != -1} {
        set Ipv6AddrGateway [lindex $args [expr $index + 1]]
        set IpVersion ipv6
    } else { 
        set index [lsearch $args -ipv6addrgateway] 
        if {$index != -1} {
            set Ipv6AddrGateway [lindex $args [expr $index + 1]]
            set IpVersion ipv6
        } else  {
            set Ipv6AddrGateway 2000:201::1:1
        }
    }
    
    #Parse Ipv6Mask parameter
    set index [lsearch $args -ipv6mask] 
    if {$index != -1} {
        set Ipv6AddrPrefixLen [lindex $args [expr $index + 1]]
        set IpVersion ipv6
    } else {
        set index [lsearch $args -ipv6addrprefixlen] 
        if {$index != -1} {
            set Ipv6AddrPrefixLen [lindex $args [expr $index + 1]]
            set IpVersion ipv6
        } else  {
            set Ipv6AddrPrefixLen 64
        } 
    }
    
    #Parse Count parameter
    set index [lsearch $args -count] 
    if {$index != -1} {
        set Count [lindex $args [expr $index + 1]]
    } else  {
        set Count 1
    } 
    if {$IpVersion=="ipv4"} {
        if {[llength $Ipv4Addr]>1} {
            set Count [llength $Ipv4Addr]
        }
    } elseif {$IpVersion=="ipv6"} {
        if {[llength $Ipv6Addr]>1} {
            set Count [llength $Ipv6Addr]
        }
    } else {
        error "IpVersion:$IpVersion does not support."
    }
    
    
    #提取参数Increase的值
    set index [lsearch $args -increase] 
    if {$index != -1} {
        set Increase [lindex $args [expr $index + 1]]
    } else  {
        set Increase 1
    } 
    
    #Parse MacAddr parameter
    set index [lsearch $args -macaddr] 
    if {$index != -1} {
        set MacAddr [lindex $args [expr $index + 1]]
    } else  {
        set MacAddr [GetRouterMacAddress]
    } 
    
    #Parse MacCount parameter
    set index [lsearch $args -maccount] 
    if {$index != -1} {
        set MacCount [lindex $args [expr $index + 1]]
    } else  {
        set MacCount 1
    } 
    
    #Parse MacIncrease parameter
    set index [lsearch $args -macincrease] 
    if {$index != -1} {
        set MacIncrease [lindex $args [expr $index + 1]]
    } else  {
        set MacIncrease 1
    } 

    #Parse MacStepMask parameter
    set index [lsearch $args -macstepmask] 
    if {$index != -1} {
        set MacStepMask [lindex $args [expr $index + 1]]
    } else  {
        set MacStepMask "00:00:FF:FF:FF:FF"
    } 

    set pingGateway "FALSE"
    #Parse FlagPing parameter
    set index [lsearch $args -flagping] 
    if {$index != -1} {
        set FlagPing [lindex $args [expr $index + 1]]
    } else  {
        set FlagPing "enable"
    } 
   
    if {[string tolower $FlagPing] == "disable" || [string tolower $FlagPing] == "false"} {
        set FlagPing "FALSE"
    } else {
        set FlagPing "TRUE"
    }
    
    #Create Host object and config the parameters   
    
    set ::mainDefine::objectName $this 
    uplevel 1 {         
         set ::mainDefine::result [$::mainDefine::objectName cget -m_hProject]         
    }         
    set hProject $::mainDefine::result     
    set hHost [stc::create Host -under $hProject -Name $HostName -DeviceCount $Count -EnablePingResponse $FlagPing]
    lappend m_hHostList $hHost
   
    set step ""
    set index [string first ":" $MacIncrease] 
    if {$index == -1} {
    for {set i 0} {$i <6} { incr i} {
        set mod1 [expr $MacIncrease%256]
        if {$step ==""} {
            set step [format %x $mod1]
        } else {
            set step [format %x $mod1]:$step
        }
        set MacIncrease [expr $MacIncrease/256]
    }
    } else {
        set step $MacIncrease
    }
     
    if {[string tolower $m_portType] == "ethernet"} {
        if {[llength $MacAddr]>1} {
            set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SrcMacList $MacAddr -IsRange "FALSE"]
        } else {
            if {$MacCount < $Count} {    
                set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SourceMac $MacAddr -SrcMacStepMask $MacStepMask -SrcMacStep 00:00:00:00:00:00]
            } else {
                set L2If1 [stc::create EthIIIf -under $hHost -Active TRUE -SourceMac $MacAddr -SrcMacStepMask $MacStepMask -SrcMacStep $step]
            }
        }
    } else {
         set POSPhy(1) [lindex [stc::get $m_hPort -children-POSPhy] 0] 
         if {$POSPhy(1) == ""} {
            set POSPhy(1) [stc::create "POSPhy" \
               -under $m_hPort \
               -DataPathMode "NORMAL" \
               -Mtu "4470" \
               -PortSetupMode "PORTCONFIG_ONLY" \
               -Active "TRUE" \
               -LocalActive "TRUE" \
               -Name {POS Phy 1} ]
        }  
    
        set SonetConfig(1) [lindex [stc::get $POSPhy(1) -children-SonetConfig] 0]
        if {[stc::get $SonetConfig(1) -HdlcEnable] == "ENABLE"} { 
            if {$IpVersion == "ipv4"} {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV4"
            } else {
                set protocolType "HDLC_PROTOCOL_TYPE_IPV6"
            }
              
            set L2If1 [stc::create HdlcIf -under $hHost -Active TRUE \
                        -ProtocolType $protocolType ]
        } else {
            if {$IpVersion == "ipv4"} {
                set protocolType "PPP_PROTOCOL_ID_IPV4"
            } else {
                set protocolType "PPP_PROTOCOL_ID_IPV6"
            }
            set L2If1 [stc::create PppIf -under $hHost -Active TRUE \
                        -ProtocolId $protocolType ]
        }
    }    
        
    set m_hostHandle($HostName) $hHost
    set ::mainDefine::gHostHandle($HostName) $hHost

    if {$IpVersion == "ipv4"} {
        set m_hostHandleByIp($Ipv4Addr) $hHost
        set m_hostNameByIp($Ipv4Addr) $HostName

        set hIpv4 [stc::create Ipv4If -under $hHost]
        set step ""
        set index [string first "." $Increase] 
        if {$index == -1} {
            for {set i 0} {$i <4} { incr i} {
                set mod1 [expr $Increase%256]
                if {$step ==""} {
                    set step $mod1
                } else {
                    set step $mod1.$step
                }
                set Increase [expr $Increase/256]
            }
        } else {
            set step $Increase
        }
        if {[llength $Ipv4Addr]>1} {
            stc::config $hIpv4 -AddrList $Ipv4Addr -IsRange "FALSE" -GatewayList $Ipv4AddrGateway
        } else {
            stc::config $hIpv4 -Address $Ipv4Addr -PrefixLength $Ipv4AddrPrefixLen -Gateway $Ipv4AddrGateway  \
                                -AddrStepMask $Ipv4StepMask -AddrStep $step
        }
        set ::mainDefine::ipv4 $hIpv4
        set ::mainDefine::gPoolCfgBlock($HostName) $hIpv4
    
        set ::mainDefine::objectName $this 
        uplevel 1 {         
             set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
        }         
        set hPort $::mainDefine::result  
    
        stc::config $hHost -AffiliationPort-targets $hPort
        stc::config $hHost -TopLevelIf-targets $hIpv4
        stc::config $hHost -PrimaryIf-targets $hIpv4
        
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
        }
        set ifStack $::mainDefine::result
        if {$ifStack == "EII" || [isPortNameEqualToCreator $m_portName $this] == "TRUE"} {
            stc::config $hIpv4 -StackedOnEndpoint-targets $L2If1
        #配置IfStack == VlanOverEII时的接口协议栈    
        } elseif {$ifStack == "VlanOverEII"} { 
            set ::mainDefine::gVlanIfName $this
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanTag] 
            }
       
            set vlanId $::mainDefine::result

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanPriority] 
            }
           
            set vlanPriority $::mainDefine::result

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanType] 
            }
           
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_QinQList] 
            }
           
            set QinQList $::mainDefine::result

            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_hVlanIf]
            }
            set hVlanIf $::mainDefine::result

            if {$hVlanIf  == -1} {
                error "vlan subif must be created  before ConfigHost"
            }
            if {$vlanId == -1} {
                error "vlanTag must be configured before ConfigHost"
            }            

            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hHost -VlanId $vlanId -Priority $vlanPriority -TpId $vlanType] 
               stc::config $hIpv4 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1  
               set ::mainDefine::gPoolCfgBlock([getObjectName $this]) $hVlanIf   
            } else {
               set i 0               

               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]
                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  } 
                  set vlanType [format %d $vlanType]
            
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hHost -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv4 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $this]) $m_vlanIfList($i) 
               }
            }
        }  
        
    } elseif {$IpVersion == "ipv6"} {
        set m_hostHandleByIp($Ipv6Addr) $hHost
        set m_hostNameByIp($Ipv6Addr) $HostName

        set hIpv61 [stc::create Ipv6If -under $hHost]
        set step ""
        set index [string first ":" $Increase] 
        if {$index == -1} {
            for {set i 0} {$i <8} { incr i} {
                set mod1 [expr $Increase%65536]
                if {$step ==""} {
                    set step [format %x $mod1]
                } else {
                    set step [format %x $mod1]:$step
                }
                set Increase [expr $Increase/65536]
            }
        } else {
            set step $Increase 
        }
        
        set hIpv62 [stc::create Ipv6If -under $hHost]
        if {[llength $Ipv6Addr]>1} {
            set Ipv6LinkLocalAddr ""
            for {set i 0} {$i <[llength $Ipv6Addr]} { incr i} {
                lappend Ipv6LinkLocalAddr "fe80::[expr $i+1]"
            }
            stc::config $hIpv61 -AddrList $Ipv6LinkLocalAddr -Gateway [lindex $Ipv6AddrGateway 0] -GatewayList $Ipv6AddrGateway -IsRange "FALSE"
            stc::config $hIpv62 -AddrList $Ipv6Addr  -Gateway [lindex $Ipv6AddrGateway 0] -GatewayList $Ipv6AddrGateway -IsRange "FALSE"
        } else {
            stc::config $hIpv61 -Address $Ipv6LinkLocalAddr -PrefixLength $Ipv6AddrPrefixLen -Gateway $Ipv6AddrGateway \
                               -AddrStepMask $Ipv6StepMask -AddrStep $step
            stc::config $hIpv62 -Address $Ipv6Addr -PrefixLength $Ipv6AddrPrefixLen -Gateway $Ipv6AddrGateway \
                               -AddrStepMask $Ipv6StepMask -AddrStep $step
        }
        set ::mainDefine::gPoolCfgBlock($HostName) $hIpv62

        set ::mainDefine::objectName $this 
        uplevel 1 {         
             set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
        }         
        set hPort $::mainDefine::result  
        
        stc::config $hHost -AffiliationPort-targets $hPort                   
        stc::config $hHost -TopLevelIf-targets " $hIpv61 $hIpv62 "
        stc::config $hHost -PrimaryIf-targets " $hIpv61 $hIpv62 "
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_ifStack]
        }
        set ifStack $::mainDefine::result
        if {$ifStack == "EII"|| [isPortNameEqualToCreator $m_portName $this] == "TRUE"} {
            stc::config $hIpv61 -StackedOnEndpoint-targets $L2If1
            stc::config $hIpv62 -StackedOnEndpoint-targets $L2If1
  
        } elseif {$ifStack == "VlanOverEII"} { 

            set ::mainDefine::gVlanIfName $this
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanTag] 
            }
           
            set vlanId $::mainDefine::result

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanPriority] 
            }
           
            set vlanPriority $::mainDefine::result

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_vlanType] 
            }
           
            set vlanType $::mainDefine::result

            set hexFlag [string range $vlanType 0 1]
            if {[string tolower $hexFlag] != "0x" } {
                set vlanType 0x$vlanType
            }
            set vlanType [format %d $vlanType]

            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_QinQList] 
            }
           
            set QinQList $::mainDefine::result

            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::gVlanIfName cget -m_hVlanIf]
             }
            set hVlanIf $::mainDefine::result

            if {$hVlanIf  == -1} {
                error "vlan subif must be created  before ConfigRouter"
            }
            if {$vlanId == -1} {
                error "vlanTag must be configured before ConfigRouter"
            }   


            if {$QinQList == ""} {
               set hVlanIf [stc::create VlanIf -under $hHost -VlanId $vlanId -Priority $vlanPriority -TpId $vlanType] 
               stc::config $hIpv61 -StackedOnEndpoint-targets $hVlanIf 
               stc::config $hIpv62 -StackedOnEndpoint-targets $hVlanIf
               stc::config $hVlanIf -StackedOnEndpoint-targets $L2If1 
               set ::mainDefine::gPoolCfgBlock([getObjectName $this]) $hVlanIf  
            } else {
               set i 0                              
                  
               foreach QinQ $QinQList {
                  set i [expr $i + 1]
                  set vlanType [lindex $QinQ 0]
                  set hexFlag [string range $vlanType 0 1]
                  if {[string tolower $hexFlag] != "0x" } {
                      set vlanType 0x$vlanType
                  }
                  set vlanType [format %d $vlanType]
            
                  set vlanId [lindex $QinQ 1]
                  set vlanPriority [lindex $QinQ 2]
                  set m_vlanIfList($i) [stc::create VlanIf -under $hHost -IdList "" -vlanId $vlanId -Priority $vlanPriority -TpId $vlanType]   

                  if {$i == 1} {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $L2If1  
                  } else {
                       stc::config $m_vlanIfList($i) -StackedOnEndpoint-targets $m_vlanIfList([expr $i - 1])
                  }
                  
               } 

               if {$i != 0} {
                   stc::config $hIpv61 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   stc::config $hIpv62 -StackedOnEndpoint-targets $m_vlanIfList($i)
                   set ::mainDefine::gPoolCfgBlock([getObjectName $this]) $m_vlanIfList($i)
               }
            }
        }
        
        
        set ::mainDefine::ipv6 $hIpv62
    } else {
        error "IpVersion:$IpVersion does not support."
    }
    
    set ::mainDefine::hostname $HostName
    set ::mainDefine::hHost $hHost  
    set ::mainDefine::hProject $m_hProject  
    set ::mainDefine::hPort $m_hPort  
    set ::mainDefine::portname $m_portName 
    set ::mainDefine::portType $m_portType

    switch $HostType {
        igmphost {
            set ::mainDefine::gGeneratorStarted "TRUE"  
            uplevel 1 {
                IgmpHost $::mainDefine::hostname $::mainDefine::hostname $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 \
                         $::mainDefine::portType
            }
        }
        mldhost {
            set ::mainDefine::gGeneratorStarted "TRUE"  
            uplevel 1 {
                MldHost $::mainDefine::hostname $::mainDefine::hostname $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv6  \
                         $::mainDefine::portType
            }           
        }
       normal {
            if {$IpVersion == "ipv4"} {
                uplevel 1 {
                    Host $::mainDefine::hostname $::mainDefine::hostname $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv4 "ipv4" \
                         $::mainDefine::portType
                }
            } else {
                uplevel 1 {
                    Host $::mainDefine::hostname $::mainDefine::hostname $::mainDefine::hHost \
                         $::mainDefine::hPort $::mainDefine::portname $::mainDefine::hProject $::mainDefine::ipv6 "ipv6" \
                         $::mainDefine::portType
                }
            } 
       } 
    }
 
    #Apply the configurations to the chassis
    stc::apply
      
    debugPut "exit the proc of TestPort::CreateHost..."
    
    return  $::mainDefine::gSuccess 
}

############################################################################
#APIName: DestroyHost
#Description: Destroy host object
#Input: 1. args:argument list，including the following
#              (1) -HostName HostName required,host name, i.e -HostName host1 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TestPort::DestroyHost {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TestPort::DestroyHost..."
    
    #Parse HostName parameter
    set index [lsearch $args -hostname] 
    if {$index != -1} {
        set HostName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify HostName parameter. \nexit the proc of DestroyHost..."
    }
    
    #Destroy host object
    if {[info exists m_hostHandle($HostName)]} {
        set hHost $m_hostHandle($HostName)
        set index [lsearch $m_hostNameList $HostName]
        set m_hostNameList [lreplace $m_hostNameList $index $index]
      
        set host_index [lsearch $m_hHostList $hHost]
        if {$host_index != -1} {
            set m_hHostList [lreplace $m_hHostList $host_index $host_index ]
             stc::delete $hHost
        }

        set ::mainDefine::gHostName $HostName
        uplevel 1 {
             itcl::delete object $::mainDefine::gHostName
        }
     
        unset m_hostHandle($HostName)

        stc::apply 
        debugPut "exit the proc of TestPort::DestroyHost..." 
        return $::mainDefine::gSuccess     
    } else {
        error "The specified HostName parameter is not exist,please set another one.\nexit the proc of DestroyHost..."
    }

    debugPut "exit the proc of TestPort::DestroyHost..."
}

############################################################################
#APIName: RealStartStaEngine
#Description: Start the statistics functionality on the port
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::RealStartStaEngine { clearStatistics } {

    if {$m_StaEngineState == "PENDING"} {

         set AnalyzerHandle [stc::get $m_hPort -children-Analyzer]

         set state [stc::get $AnalyzerHandle -state]
         if {$state == "RUNNING" } {
              debugPut "The Analyzor of port:$m_portName in running state, take actions to re-start it"

             set errorCode [stc::perform AnalyzerStop -AnalyzerList $AnalyzerHandle -ExecuteSynchronous TRUE ]
         }

         if {$clearStatistics == 1} {
              #Clear all the previous statistics
              #stc::perform ResultClearAllTraffic -PortList $m_hPort
         }
   
         #Start the Analyzer on the port
         set errorCode 1
         if {[catch {
              set errorCode [stc::perform AnalyzerStart -AnalyzerList $AnalyzerHandle -ExecuteSynchronous TRUE ]
         } err]} {
              return $errorCode
         }
         debugPut "Finish starting StaEngine on port: $m_portName "

         set  m_StaEngineState "RUNNING"
    }

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StartStaEngine
#Description: Start StaEngine 
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::StartStaEngine { {args ""}} {
    
    debugPut "enter the proc of TestPort::StartStaEngine"

    set AnalyzerHandle [stc::get $m_hPort -children-Analyzer]
     
    #Set filterOnStreamId attribute using m_FilterOnStreamId
    if { $m_FilterOnStreamId == "TRUE" } {
        #Enable FilterOnStreamId functionality
        stc::config $AnalyzerHandle -FilterOnStreamId TRUE
    }

    set m_StaEngineState "PENDING"

    debugPut "exit the proc of TestPort::StartStaEngine"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopStaEngine
#Description: Stop StaEngine
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body TestPort::StopStaEngine {{args ""}} {

    debugPut "enter the proc of TestPort::StopStaEngine"

    set ::mainDefine::gResultCleared 0

    if {$m_StaEngineState == "RUNNING"} {
          set m_StaEngineState "IDLE"
   
         #Stop the Analyzer on the port
         set AnalyzerHandle [stc::get $m_hPort -children-Analyzer]
         set errorCode 1
         if {[catch {
             set errorCode [stc::perform AnalyzerStop -AnalyzerList $AnalyzerHandle -ExecuteSynchronous TRUE ]
         } err]} {
              return $errorCode
         }
     } else {
         puts "The StaEngine of the port is not started, no need to stop it"
     }

    debugPut "exit the proc of TestPort::StopStaEngine"

    return $::mainDefine::gSuccess
}
############################################################################
#APIName: CleanupPort
#Description: clear all the configurations on the port, but not destroy the port object
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body TestPort::CleanupPort {{args ""}} {

    debugPut "enter the proc of TestPort::CleanupPort"
  
    set children [stc::get $m_hPort -children]
    foreach child $children {
        set index [lsearch $m_hAutoCreateChildrenList $child]
        if {$index == -1} {
            catch {stc::delete $child}
        }
    }

    set affiliationChildren [stc::get $m_hPort -affiliationport-Sources]
    foreach child $affiliationChildren {
        catch {stc::delete $child}        
    }    

    debugPut "exit the proc of TestPort::CleanupPort"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetRouterMacAddress
#Description: Get current Router MAc address
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::GetRouterMacAddress {} {

    set routerSeq $m_macRouterNum
    incr m_macRouterNum
    
    set routerSeq $::mainDefine::routerNum
    incr routerSeq
    set ::mainDefine::routerNum $routerSeq
    set routerSeq1 [expr ($routerSeq/256)%256]
    set routerSeq2 [expr ($routerSeq/256/256)%256]
    set mac 00:20:94:[format "%0.2x" $routerSeq2]:[format "%0.2x" $routerSeq1]:[format "%0.2x" [expr $routerSeq%256]]
   
     return $mac
}

############################################################################
#APIName: GetRouterSeq
#Description: Get Router seqeunce number
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::GetRouterSeq {} {
       incr m_routerNum
       set routerSeq $m_routerNum

       return $routerSeq
}

############################################################################
#APIName: ResetTestPort
#Description: Reset the TestPort to initial state
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::ResetTestPort {} {
       set m_trafficNameList ""
       set m_trafficFlag 0
       set m_blocking Disable
       set m_routerNum 0
       set m_macRouterNum 0
       set m_staEngineList  ""
       set m_staEngineList ""
       set m_routerNameList ""
       set m_hostNameList ""
       set m_isARPDone "TRUE"

       catch {
       #Delete all the Router handle
       foreach hRouter $m_hRouterList {
             catch {stc::delete $hRouter}
       }
       set m_hRouterList ""
       }

       catch { 
       #Delete all the Host handle
       foreach hHost $m_hHostList {
             catch {stc::delete $hHost}
       }
       set m_hHostList ""
       }

       catch {
       #Delete all the VlanIf objects
       set vlanIfList [stc::get $m_hPort -children-VlanIf]
       foreach vlanIf $vlanIfList {
           catch {stc::delete $vlanIf}  
       } 
       }

       set m_FilterOnStreamId "TRUE"
       set AnalyzerHandle [stc::get $m_hPort -children-analyzer]
       stc::config $AnalyzerHandle -FilterOnStreamId TRUE 

       set m_frameNumOfBlocking 0
       set m_StaEngineState "IDLE"
       set m_StartCaptureState "IDLE"
       set m_streamStatisticRefershed "FALSE"
       
       catch {
            set generator [stc::get $m_hPort -children-Generator]
            set state [stc::get $generator -state]
            if {$state != "STOPPED" } {
                stc::perform GeneratorStop -GeneratorList $generator -ExecuteSynchronous TRUE
            }
        }

       #Delete all the Stream Block in the TestPort
       set hStreamblockList [stc::get $m_hPort -children-streamblock]
       foreach hStreamblock $hStreamblockList {
           catch {stc::delete $hStreamblock}      
       }

       DestroyFilter
       set m_filterNameList ""
       set m_filterConfigList ""    
       catch {unset m_hostHandleByIp}

       set ::mainDefine::objectName $this 
       uplevel 1 {
            $::mainDefine::objectName configure -m_ifStack "EII"
            $::mainDefine::objectName configure -m_vlanIfNameList ""
            $::mainDefine::objectName configure -m_bridgeNameList ""
       }

       if {[info exists ::mainDefine::gPortScheduleMode($m_portName)]} {
           unset ::mainDefine::gPortScheduleMode($m_portName)
       } 

       return $::mainDefine::gSuccess
}

############################################################################
#APIName: RealStartAllCaptures
#Description: Start all the capture objects
#Input: None
#Output: None
#Coded by: David.Wu
#############################################################################

::itcl::body TestPort::RealStartAllCaptures {} {

       set ::mainDefine::objectName $m_chassisName 
       uplevel 1 {         
          set ::mainDefine::result [$::mainDefine::objectName cget -m_portNameList]         
       }
       set testPortObjectList $::mainDefine::result     
       
       #Start all the capture object
       foreach testPortObject $testPortObjectList {
             set ::mainDefine::objectName $testPortObject
              uplevel 1 {         
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_staEngineList]         
              }  
              set staEngineObjectList $::mainDefine::result     
              
              foreach staEngineObject $staEngineObjectList {

                   set ::mainDefine::objectName $staEngineObject
                   uplevel 1 {
                          set ::mainDefine::result [$::mainDefine::objectName isa TestAnalysis]
                          if {$::mainDefine::result} { 
                               $::mainDefine::objectName RealConfigCaptureMode      
                               $::mainDefine::objectName RealStartCapture  
                          }
                    } 
              }
        }
        debugPut "Finish starting all the Capture objects ..."

       return $::mainDefine::gSuccess
}

############################################################################
#APIName: BGPImportRouteTable
#Description: Import BGP routes in the file
#Input: 
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TestPort::BgpImportRouteTable {args} {
   
    debugPut "enter the proc of TestPort::BgpImportRouteTable"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args]

    #Parse FileName parameter
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args [expr $index + 1]] 
    } else {
        error "Please specify FileName parameter you want to import."
    }

    #Parse RouterNameList parameter
    set index [lsearch $args -routernamelist] 
    if {$index != -1} {
        set RouterNameList [lindex $args [expr $index + 1]] 
    } else {
        error "Please specify RouterNameList parameter you want to import to."
    }

    set routerHandleList ""
    foreach routerName $RouterNameList {  
          set index [lsearch $m_routerNameList $routerName]
          if {$index == -1} {
                 error "the routerName($routerName) does not exist. The existed routeName(s) is(are):\n $m_routerNameList"
          } 
     
          set ::mainDefine::objectName $routerName
          uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter ]  
          } 
          lappend routerHandleList $::mainDefine::result
    }

    #Parse MaxRouteBlks parameter
    set index [lsearch $args -maxrouteblks] 
    if {$index != -1} {
        set MaxRouteBlks [lindex $args [expr $index + 1]] 
    } else {
        set MaxRouteBlks 65535
    } 

    #Parse MaxRoutesPerRouteBlock parameter
    set index [lsearch $args -maxroutesperrouteblock] 
    if {$index != -1} {
        set MaxRoutesPerRouteBlock [lindex $args [expr $index + 1]] 
    } else {
        set MaxRoutesPerRouteBlock 2500
    }
    
    #Parse seTesterIpAsNextHop parameter
    set index [lsearch $args -usetesteripasnexthop] 
    if {$index != -1} {
        set UseTesterIpAsNextHop [lindex $args [expr $index + 1]] 
    } else {
        set UseTesterIpAsNextHop TRUE
    }

    #Parse FileFormat parameter
    set index [lsearch $args -fileformat] 
    if {$index != -1} {
        set FileFormat [lindex $args [expr $index + 1]] 
    } else {
        set FileFormat "CISCO"
    }

    if {[string tolower $FileFormat ] == "Spirent"} {
          debugPut "Begin to convert the file to cisco format ..."
          set OutputFileName "./BgpRouteTable_Output.txt"
          ConvertRouteTable $FileFormat $FileName $OutputFileName
          debugPut "Finished converting the file format ..."

          set FileName $OutputFileName
    }

    set routerNum [llength $routerHandleList]
    
    debugPut "Begin to import Bgp routes, please be patient ..."

    set ::mainDefine::objectName $m_chassisName 
    uplevel 1 {         
            set ::mainDefine::result [$::mainDefine::objectName cget -m_BgpImportRouteParams]         
     }
    set BgpImportRouteParams $::mainDefine::result     
         
    stc::config $BgpImportRouteParams -MaxRouteBlks $MaxRouteBlks \
           -MaxRoutesPerRouteBlock $MaxRoutesPerRouteBlock \
           -UseTesterIpAsNextHop $UseTesterIpAsNextHop

    set i 0
   
    SplitRouteTableFile $FileName $routerNum "port"
    foreach routerHandle $routerHandleList {
        set finalName "$FileName$i"
       
        stc::config $BgpImportRouteParams -FileName $finalName -SelectedRouterRelation-targets " $routerHandle "
        stc::perform BgpImportRouteTable -ImportParams $BgpImportRouteParams -RouterList $routerHandle -ExecuteSynchronous TRUE 

        #Delete the files 
        catch {file delete $finalName }

        #Check whether or not the files have been imported
        #set bgpcfg1 [stc::get  $routerHandle -children-BgpRouterConfig]
        #set bgpblock1 [stc::get $bgpcfg1  -children-BgpIpv4RouteConfig]
        #debugPut $bgpblock1
        
         set i [expr $i + 1]
    }

     if {[string tolower $FileFormat ] == "Spirent"} {
         #Delete the files 
         catch {file delete "./BgpRouteTable_Output.txt" }
    }

    stc::apply
    debugPut "Finished importing the route table"
    
    debugPut "exit the proc of TestPort::BgpImportRouteTable"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: BindHostsToStream
#Description: Bind Host with Stream
#Input:         streamblock1: handle of stream block 
#                  streamName: the name of the stream 
#                  DestinationPort: destination port name list
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::BindHostsToStream {streamblock1 streamName DestinationPort } {
      
     foreach dstPort $DestinationPort {
         set ::mainDefine::DstObjectName $dstPort

         uplevel 1 {
                set ::mainDefine::result [$::mainDefine::DstObjectName cget -m_hPort] 
         }
        set hPort $::mainDefine::result

        lappend hPortList $hPort
   }
 
   stc::config $streamblock1 -ExpectedRxPort " $hPortList "

   return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetStreamIndex
#Description: Get stream index of the stream
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::GetStreamIndex {streamName} {
       set streamIndex -1
       set found "FALSE"
       set NotStartedStreamFlag "FALSE"
       foreach traffic $m_trafficNameList {
            
            set ::mainDefine::objectName $traffic 
            uplevel 1 {         
                set ::mainDefine::result [$::mainDefine::objectName cget -m_streamNameList]         
            }         
            set streamNameList $::mainDefine::result
            foreach stream $streamNameList {
                  set ::mainDefine::objectName $stream 
                  uplevel 1 {
                       set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]
                  }
                  set StreamHandle $::mainDefine::result
                  set active [stc::get $StreamHandle -Active]
                  if {$active == "true"} {
                       set streamIndex [expr $streamIndex + 1]
                       if {$stream == $streamName} {
                             set found "TRUE"
                             break        
                       }
                  } else {
                      set NotStartedStreamFlag  "TRUE"
                  }           
            }
       } 

      if {$found == "TRUE"} {
           if {$NotStartedStreamFlag == "TRUE"} {
                return $streamIndex 
           } else {
                set ::mainDefine::objectName $streamName
                uplevel 1 {
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]
                }
                set StreamHandle $::mainDefine::result
                set streamIndex [stc::get $StreamHandle -StreamBlockIndex]
                return $streamIndex 
           }
      } else {
           return -1
      } 
}

############################################################################
#APIName: GetHostHandleByIp
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::GetHostHandleByIp {IpAddr} {
       if {[info exists m_hostHandleByIp($IpAddr)]} {
            set hHostHandle ""
            catch { 
                set hHostHandle $m_hostHandleByIp($IpAddr)
                set HostName $m_hostNameByIp($IpAddr)
                set index [lsearch $m_hostNameList $HostName]
                if {$index == -1} {
                     set  hHostHandle ""
                }
            }
            return $hHostHandle
       } else {
           return ""
      }
}

############################################################################
#APIName: ConfigHighResolutionSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::ConfigHighResolutionSample {args} {
    debugPut "enter the proc of TestPort::ConfigHighResolutionSample"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
  
    #set m_filterConfigList ""
    #Parse FilterName parameter
    #counter,specify the attr you want to get, now support TotalBitRate
    set index [lsearch $args -counter]
    if {$index !=-1} {
        set counter [lindex $args [expr $index+1]]
    } else {
        error "please specify -counter for ConfigHighResolutionSample API"
    } 
    #counter,specify the attr you want to get, now support >= <= < > == !=
    set index [lsearch $args -condition]
    if {$index !=-1} {
        set condition [lindex $args [expr $index+1]]
        if {[string equal $condition ">="] || [string equal $condition "=>"]} {
            set condition "GREATER_THAN_OR_EQUAL"
        } elseif {[string equal $condition "<="] || [string equal $condition "=<"]} {
            set condition "LESS_THAN_OR_EQUAL"
        } elseif {[string equal $condition "<"]} {
            set condition "LESS_THAN"
        } elseif {[string equal $condition ">"]} {
            set condition "GREATER_THAN"
        } elseif {[string equal $condition "=="]} {
            set condition "EQUAL"
        } elseif {[string equal $condition "!="]} {
            set condition "NOT_EQUAL"
        }
    } else {
        error "please specify -condition for ConfigHighResolutionSample API"
    }
    
    #value,specify the value
    set index [lsearch $args -value]
    if { $index !=-1} {
        set value [lindex $args [expr $index+1]]
    } else {
        error "please specify -value for ConfigHighResolutionSample API"
    }   
    
    #valuetype, support abs/kbps/mbps/gbps
    set index [lsearch $args -valuetype]
    if { $index !=-1} {
        set valuetype [lindex $args [expr $index+1]]
        if {$valuetype == "abs"} {
            set valuetype "ABSOLUTE"
        } elseif {$valuetype == "kbps"} {
            set valuetype "KILOBITS_PER_SECOND"
        } elseif {$valuetype == "mbps"} {
            set valuetype "MEGABITS_PER_SECOND"
        } elseif {$valuetype == "gbps"} {
            set valuetype "GIGABITS_PER_SECOND"
        } else {
            set valuetype "PERCENT_BASELINE"
        }
    } else {
        error "please specify -valuetype for ConfigHighResolutionSample API"
    }
    
    #interval, unit:ms
    set index [lsearch $args -interval]
    if { $index !=-1} {
        set interval [lindex $args [expr $index+1]]
    } else {
        set interval 1
    }
    
    set m_highResolutionPortConfig [lindex [stc::get [stc::get $m_hPort -children-Analyzer] -children-HighResolutionSamplingPortConfig] 0]
    if {$m_highResolutionPortConfig == ""} {
        set m_highResolutionPortConfig [stc::create HighResolutionSamplingPortConfig -under [stc::get $m_hPort -children-Analyzer]]
    }
    stc::config $m_highResolutionPortConfig -TriggerCondition $condition \
        -TriggerStat $counter -TriggerValue $value -TriggerValueUnitMode $valuetype -SamplingInterval $interval
    
    debugPut "exit the proc of TestPort::ConfigHighResolutionSample"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StartHighResolutionSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::StartHighResolutionSample {args} {
    debugPut "enter the proc of TestPort::StartHighResolutionSample"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
    
    stc::perform HighResolutionSamplingStartCommand -ConfigClassId HighResolutionSamplingPortConfig -ResultClassId HighResolutionSamplingPortResults -HandleList project1
    
    debugPut "exit the proc of TestPort::StartHighResolutionSample"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopHighResolutionSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::StopHighResolutionSample {args} {
    debugPut "enter the proc of TestPort::StopHighResolutionSample"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
    
    stc::perform HighResolutionSamplingStopCommand -ConfigClassId HighResolutionSamplingPortConfig -ResultClassId HighResolutionSamplingPortResults -HandleList project1
    
    debugPut "exit the proc of TestPort::StopHighResolutionSample"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigHighResolutionStreamBlockSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::ConfigHighResolutionStreamBlockSample {stream args} {
    debugPut "enter the proc of TestPort::ConfigHighResolutionStreamBlockSample"
	set ::mainDefine::objectName $stream 
	uplevel 1 {         
		set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
	}         
	set hStream $::mainDefine::result

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
  
    #set m_filterConfigList ""
    #Parse FilterName parameter
    #counter,specify the attr you want to get, now support TotalBitRate
    set index [lsearch $args -counter]
    if {$index !=-1} {
        set counter [lindex $args [expr $index+1]]
    } else {
        error "please specify -counter for ConfigHighResolutionStreamBlockSample API"
    } 
    #counter,specify the attr you want to get, now support >= <= < > == !=
    set index [lsearch $args -condition]
    if {$index !=-1} {
        set condition [lindex $args [expr $index+1]]
        if {[string equal $condition ">="] || [string equal $condition "=>"]} {
            set condition "GREATER_THAN_OR_EQUAL"
        } elseif {[string equal $condition "<="] || [string equal $condition "=<"]} {
            set condition "LESS_THAN_OR_EQUAL"
        } elseif {[string equal $condition "<"]} {
            set condition "LESS_THAN"
        } elseif {[string equal $condition ">"]} {
            set condition "GREATER_THAN"
        } elseif {[string equal $condition "=="]} {
            set condition "EQUAL"
        } elseif {[string equal $condition "!="]} {
            set condition "NOT_EQUAL"
        }
    } else {
        error "please specify -condition for ConfigHighResolutionStreamBlockSample API"
    }
    
    #value,specify the value
    set index [lsearch $args -value]
    if { $index !=-1} {
        set value [lindex $args [expr $index+1]]
    } else {
        error "please specify -value for ConfigHighResolutionStreamBlockSample API"
    }   
    
    #valuetype, support abs/kbps/mbps/gbps
    set index [lsearch $args -valuetype]
    if { $index !=-1} {
        set valuetype [lindex $args [expr $index+1]]
        if {$valuetype == "abs"} {
            set valuetype "ABSOLUTE"
        } elseif {$valuetype == "kbps"} {
            set valuetype "KILOBITS_PER_SECOND"
        } elseif {$valuetype == "mbps"} {
            set valuetype "MEGABITS_PER_SECOND"
        } elseif {$valuetype == "gbps"} {
            set valuetype "GIGABITS_PER_SECOND"
        } else {
            set valuetype "PERCENT_BASELINE"
        }
    } else {
        error "please specify -valuetype for ConfigHighResolutionStreamBlockSample API"
    }
    
    #interval, unit:ms
    set index [lsearch $args -interval]
    if { $index !=-1} {
        set interval [lindex $args [expr $index+1]]
    } else {
        set interval 1
    }
	set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set hPort $::mainDefine::result 
    set m_highResolutionStreamBlockConfig [lindex [stc::get [stc::get $hPort -children-Analyzer] -children-HighResolutionSamplingStreamBlockConfig] 0]
    if {$m_highResolutionStreamBlockConfig == ""} {
		set highResolutionStreamBlockOptions [stc::create HighResolutionStreamBlockOptions -under [stc::get $hPort -children-Analyzer]]
        set m_highResolutionStreamBlockConfig [stc::create HighResolutionSamplingStreamBlockConfig -under [stc::get $hPort -children-Analyzer]]	
    }
	stc::config $highResolutionStreamBlockOptions -SamplingInterval	$interval
    stc::config $m_highResolutionStreamBlockConfig -TriggerCondition $condition \
        -TriggerStat $counter -TriggerValue $value -TriggerValueUnitMode $valuetype -SamplingInterval $interval	
	stc::config $m_highResolutionStreamBlockConfig -AffiliationHighResolutionStreamBlock-targets $hStream
    
    debugPut "exit the proc of TestPort::ConfigHighResolutionStreamBlockSample"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: StartHighResolutionStreamBlockSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::StartHighResolutionStreamBlockSample {args} {
    debugPut "enter the proc of TestPort::StartHighResolutionStreamBlockSample"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
    
    stc::perform HighResolutionSamplingStartCommand -ConfigClassId HighResolutionSamplingStreamBlockConfig -ResultClassId HighResolutionSamplingStreamBlockResults -HandleList project1
    
    debugPut "exit the proc of TestPort::StartHighResolutionStreamBlockSample"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopHighResolutionStreamBlockSample
#Description:Get Host Handle according to ip address
#Input:        
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body TestPort::StopHighResolutionStreamBlockSample {args} {
    debugPut "enter the proc of TestPort::StopHighResolutionStreamBlockSample"

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
    
    stc::perform HighResolutionSamplingStopCommand -ConfigClassId HighResolutionSamplingStreamBlockConfig -ResultClassId HighResolutionSamplingStreamBlockResults -HandleList project1
    
    debugPut "exit the proc of TestPort::StopHighResolutionStreamBlockSample"
    return $::mainDefine::gSuccess
}

