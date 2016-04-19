###########################################################################
#                                                                        
#  File Name: Scheduler.tcl                                                                                              
# 
#  Description£ºDefinition of Scheduler class and its methodsI                                             
# 
#  Author£º Rody.ou
#
#  Create time:  2007.5.8
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################

##########################################
#Definition of TestAsistant class
##########################################  
::itcl::class TestAssistant {

    #Constructor
    constructor { } { 
       
    }

    #Destructor
    destructor {

    }
}  

##########################################
#Definition of TestScheduler class
##########################################  
::itcl::class TestScheduler {
    #Variables
    public variable m_hScheduler 0
    public variable m_SchName 0
    public variable m_eventNameList ""
    public variable m_execSeqList ""
    public variable m_hEvent 0
    public variable m_execSeq 

    inherit TestAssistant
    #Constructor
    constructor { schName hScheduler} {TestAssistant::constructor } {
        set m_SchName $schName
        set m_hScheduler $hScheduler   
        set ::mainDefine::gEventNameHandleList ""
        lappend ::mainDefine::gObjectNameList $this
    }

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
    
    #Methods
    public method ConfigScheduler 
    public method StartScheduler  
    public method StopScheduler  
    public method CreateEvent
    public method DestroyEvent
}  

############################################################################
#APIName: ConfigScheduler
#
#Description: Config Scheduler mode
#
#Input: 1. -BreakpointList BreakpointList: optional,specify BreakPoint list
#          2. -CleanupCommand CleanupCommand:optional,specify CleanupCommand
#          3. -DisabledCommandList DisabledCommandList:optional, specify DisabledCommand list
#          4. -ErrorHandler ErrorHandler: specify ErrorHandler
#              
#
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestScheduler::ConfigScheduler {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestScheduler::ConfigScheduler"
    set config ""    
        
    #Parse BreakpointList
    set index [lsearch $args -breakpointlist] 
    if {$index != -1} {
        lappend config -BreakpointList 
        set BreakpointList [lindex $args [expr $index+1]]
        set list ""
        
        foreach Breakpoint $BreakpointList {
            set index [lsearch $::mainDefine::gEventNameHandleList $Breakpoint]
            set hEvent [lindex $::mainDefine::gEventNameHandleList [expr $index + 1]]
            lappend list $hEvent
        }    
        lappend config $list
    } 

    #Parse CleanupCommand
    set index [lsearch $args -cleanupcommand] 
    if {$index != -1} {
        set CleanupCommand [lindex $args [expr $index+1]]
        lappend config -CleanupCommand 
        set index [lsearch $::mainDefine::gEventNameHandleList $CleanupCommand]
        set list [lindex $::mainDefine::gEventNameHandleList [expr $index + 1]]          
        lappend config $list
    } 

    #Parse DisabledCommandList
    set index [lsearch $args -disabledcommandlist] 
    if {$index != -1} {
        lappend config -DisabledCommandList 
        set list ""
        set DisabledCommandList [lindex $args [expr $index+1]]
        foreach DisabledCommand $DisabledCommandList {
            set index [lsearch $::mainDefine::gEventNameHandleList $DisabledCommand]
            set hEvent [lindex $::mainDefine::gEventNameHandleList [expr $index + 1]]
            lappend list $hEvent
        }    
        lappend config $list
    } 

    #Parse ErrorHandler
    set index [lsearch $args -errorhandler] 
    if {$index != -1} {
        set ErrorHandler [lindex $args [expr $index+1]]
        lappend config -ErrorHandler 
        lappend config $ErrorHandler  
    } 

    #Configure the scheduler
    puts "config = $config"
    if {$config != ""} {
        eval stc::config  $m_hScheduler $config
    }
    debugPut "exit the proc of TestScheduler::ConfigScheduler"
    return $::mainDefine::gSuccess
    
}
###########################################################################
#APIName: StartScheduler
#
#Description: Start Scheduler to execute the command list
#
#Input: None                
#
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestScheduler::StartScheduler {{args ""}} {

    debugPut "enter the proc of TestScheduler::StartScheduler"
     #array set arr [stc::get $m_hScheduler ]
     #parray arr

    #¿ªÆôScheduler
    set errorCode 1
    if {[catch {
         set errorCode [stc::perform  SequencerStart]
     } err]} {
         return $errorCode
     }
    debugPut "exit the proc of TestScheduler::StartScheduler"
    return $::mainDefine::gSuccess
}
###########################################################################
#APIName: StopScheduler
#
#Description: Close Scheduler£¬and stop the command list in shceduler
#
#Input: None              
#
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestScheduler::StopScheduler {{args ""}} {
    
    debugPut "enter the proc of TestScheduler::StopScheduler"
   
    #Stop Scheduler
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform  SequencerStop]
     } err]} {
          return $errorCode
     }
    debugPut "exit the proc of TestScheduler::StopScheduler"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateEvent
#
#Description:Create TestEvent object
#
#Input: 1. -EventName EventName,required,specify the event name
#          2. -EventType EventType,required, specify Event type
#          3. -ExecuteSeq ExecuteSeq,required,event sequence number
#       
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestScheduler::CreateEvent {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestScheduler::CreateEvent"

    #Parse EventName
    set index [lsearch $args -eventname] 
    
    if {$index != -1} {
        set EventName [lindex $args [expr $index+1]]
    } else  {
        error "please specify the event name "
        return 0
    }

    #Check whether or not EventName already exists
    set index [lsearch $m_eventNameList $EventName] 
       
    if {$index != -1} {
        error "the EventName($EventName) is already existed, please specify another one, the existed EventName(s) is(are):\n$m_eventNameList"
    }   
    lappend m_eventNameList $EventName

    #Parse EventType
    set index [lsearch $args -eventtype] 
    if {$index != -1} {
        set EventType [lindex $args [expr $index+1]]
    } else  {
        error "please specify the event type "
    }

    #Parse ExecuteSeq
    set index [lsearch $args -executeseq] 
    if {$index != -1} {
        set ExecuteSeq [lindex $args [expr $index+1]]
    } else  {
        error "please specify the Execute Sequence "
    }

    #Check whether or not ExecuteSeq is unique
    set index [lsearch $m_execSeqList $ExecuteSeq] 
    if {$index != -1} {
        error "the ExecuteSeq($ExecuteSeq) is already existed, please specify another one , the existed ExecuteSeq(s) is(are):\n$m_execSeqList  "
    }   
    lappend m_execSeqList $ExecuteSeq
    set m_execSeq($EventName) $ExecuteSeq
    

    set ::mainDefine::gEventName $EventName

    set ::mainDefine::gEventType $EventType  
      
    set ::mainDefine::gExecSeq $ExecuteSeq   
    set ::mainDefine::gSchName $m_SchName
    set ::mainDefine::ghSch $m_hScheduler
    

    #Crate a TestEvent object
    uplevel 1 {
        TestEvent $::mainDefine::gEventName $::mainDefine::gEventName \
                       $::mainDefine::gEventType  $::mainDefine::gExecSeq \
                       $::mainDefine::gSchName  $::mainDefine::ghSch 

    }
    
    debugPut "exit the proc of TestScheduler::CreateEvent"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyEvent
#
#Description: Destroy event object
#
#Input: 1. -EventName EventName, event name
#      
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestScheduler::DestroyEvent {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TestScheduler::DestroyEvent"

    #Parse EventName
    set EventName ""
    set index [lsearch $args -eventname] 
    if {$index != -1} {
        set EventName [lindex $args [expr $index+1]]
    } else  {
        set EventName all
    }

    if {$EventName != "all"} {
        #Check whether or not EventName exists
        set index [lsearch $m_eventNameList $EventName] 
        if {$index == -1} {
            error "the EventName($EventName) does not exist,  the existed EventName(s) is(are):\n $m_eventNameList  "
        } 
    
        #Delete EventName from the list
        set m_eventNameList [lreplace $m_eventNameList $index $index ]   
    
        set index [lsearch $m_execSeqList $m_execSeq($EventName)] 
        set  m_execSeqList [lreplace $m_execSeqList $index $index ]    
        catch {unset $m_execSeq($EventName)}
    
        #Destroy Event object
        itcl::delete object $EventName
  } else {

    foreach EventName $m_eventNameList {       
        catch {unset $m_execSeq($EventName)}        
             #Destroy Event object
             itcl::delete object $EventName
        }

        set m_eventNameList ""
        set m_execSeqList ""
    }
    
    debugPut "exit the proc of TestScheduler::DestroyEvent"
    return $::mainDefine::gSuccess
}