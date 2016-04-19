###########################################################################
#                                                                        
#  File Name: Event.tcl                                                                                              
# 
#  Description£ºDefinitioin of Event class and its methods                                             
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
#Definition of TestEvent class
##########################################  
::itcl::class TestEvent {

    #Variables
    public variable m_eventType 0
    public variable m_eventExecSeq 0
    public variable m_hEvent 0
    public variable m_eventName 0
    public variable m_schName ""
    public variable m_hScheduler ""
    public variable m_inserted 0
    
    #Constructor
    constructor {EventName EventType ExecSeq schName hSch} { 
        set m_eventName $EventName
        set m_eventType $EventType
        set m_eventExecSeq $ExecSeq    
        set m_schName $schName
        set m_hScheduler $hSch
        lappend ::mainDefine::gObjectNameList $this
    }
    
    public method ConfigEvent
    
    #Destructor
    destructor {
        catch {
        if {$m_inserted == 1} {
            catch {
            #stc::perform SequencerDisable -CommandList $m_hEvent
            stc::perform SequencerRemove -CommandList $m_hEvent 
            }
        }
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]       
        }
    }
}  


############################################################################
#APIName: ConfigEvent
#
#Description: Configure event
#
#Input: Parameter format is associated with event type
#            
#       
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestEvent::ConfigEvent {args} {
    
    set SchName ""
    set EventName ""
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of TestEvent::ConfigEvent"
    set m_eventType [string tolower $m_eventType]
   
    #Create/configure Event according to input parameters
    switch -- $m_eventType {
        "loop" {              
            debugPut "config Loop"
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            set index [lsearch $args -iterationcount]
            if {$index != -1} {
                set IterationCount [lindex $args [expr $index+1]]
            } else {
                set IterationCount 1
            }
            set index [lsearch $args -continuousmode]
            if {$index != -1} {
                set ContinuousMode [lindex $args [expr $index+1]]
            } else {
                set ContinuousMode "FALSE"
            } 
            
            #Create Event
            set m_hEvent [stc::create SequencerLoopCommand -under system1]
            stc::config $m_hEvent -IterationCount $IterationCount -ContinuousMode $ContinuousMode
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }
               
        "startporttraffic" {  
            debugPut "config StartPortTraffic"
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            
            set index [lsearch $args -portnamelist]
            if {$index != -1} {
                set PortNameList [lindex $args [expr $index+1]]
            } else {
                error "please specify PortNameList for StartPortTraffic"
            }
            set GenList ""
            foreach portName $PortNameList {
                set ::mainDefine::objectName $portName 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                }         
                set hPort $::mainDefine::result
                
                lappend GenList [stc::get $hPort -children-Generator]                    
            }
            #Create Event
            set m_hEvent [stc::create GeneratorStartCommand -under system1]
            stc::config $m_hEvent -GeneratorList $GenList
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }
            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent  
        }
        
        "stopporttraffic" {   
            debugPut "config StopPortTraffic"
            
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            set index [lsearch $args -portnamelist]
            if {$index != -1} {
                set PortNameList [lindex $args [expr $index+1]]
            } else {
                error "please specify PortNameList for StopPortTraffic"
            }
            set GenList ""
            foreach portName $PortNameList {
                set ::mainDefine::objectName $portName 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                }         
                set hPort $::mainDefine::result
                lappend GenList [stc::get $hPort -children-Generator]                    
            }
            #Create Event
            set m_hEvent [stc::create GeneratorStopCommand -under system1]
            stc::config $m_hEvent -GeneratorList $GenList
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent

        }
        
        "waitforsometime" { 

            debugPut "config WaitForSomeTime"
            
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            
            set index [lsearch $args -waittime]
            if {$index != -1} {
                set WaitTime [lindex $args [expr $index+1]]
            } else {
                error "please specify WaitTime for WaitForSomeTime"
            }
            #Create Event
            set m_hEvent [stc::create WaitCommand -under system1]
            stc::config $m_hEvent -WaitTime $WaitTime
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }
        
        "iterateframesize" {  
           
            debugPut "config IterateFrameSize"
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            set index [lsearch $args -framesizetype]
            if {$index != -1} {
                set FrameSizeType [lindex $args [expr $index+1]]
            } else {
                set FrameSizeType "FIXED"
            }
            set index [lsearch $args -framesizestart]
            if {$index != -1} {
                set FrameSizeStart [lindex $args [expr $index+1]]
            } else {
                set FrameSizeStart 128
            } 
            
            set index [lsearch $args -framesizeend]
            if {$index != -1} {
                set FrameSizeEnd [lindex $args [expr $index+1]]
            } else {
                set FrameSizeEnd 256
            } 
            
            set index [lsearch $args -framesizestep]
            if {$index != -1} {
                set FrameSizeStep [lindex $args [expr $index+1]]
            } else {
                set FrameSizeStep 128
            }
             
            set index [lsearch $args -fixedframesize]
            if {$index != -1} {
                set FixedFrameSize [lindex $args [expr $index+1]]
            } else {
                set FixedFrameSize 128
            } 
            
            set StreamBlockList ""
            set index [lsearch $args -streamlist]
            if {$index != -1} {
                set StreamList [lindex $args [expr $index+1]]
                
                foreach streamName $StreamList {
                    set ::mainDefine::objectName $streamName 
                    uplevel 1 {         
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                    }         
                    set hStream $::mainDefine::result
                
                    lappend StreamBlockList $hStream                   
                }
            } 
            
            #Create Event
            set m_hEvent [stc::create IterateFrameSizeCommand -under system1]
            stc::config $m_hEvent  -FrameSizeType $FrameSizeType -FrameSizeStart $FrameSizeStart \
                           -FrameSizeEnd $FrameSizeEnd -FrameSizeStep $FrameSizeStep -FixedFrameSize $FixedFrameSize 
                                   
            if {$StreamBlockList != ""} {
                stc::config $m_hEvent -StreamBlockList $StreamBlockList
            }
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }
        
        "iterateloadsize" {
        
            debugPut "config IterateLoadSize"
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            
            set index [lsearch $args -loadtype]
            if {$index != -1} {
                set LoadType [lindex $args [expr $index+1]]
            } else {
                set LoadType "FIXED"
            }
            
            set index [lsearch $args -loadunits]
            if {$index != -1} {
                set LoadUnits [lindex $args [expr $index+1]]
            } else {
                set LoadUnits "PERCENT_LINE_RATE"
            }
            
            set index [lsearch $args -loadstart]
            if {$index != -1} {
                set LoadStart [lindex $args [expr $index+1]]
            } else {
                set LoadStart 10
            } 
            
            set index [lsearch $args -loadend]
            if {$index != -1} {
                set LoadEnd [lindex $args [expr $index+1]]
            } else {
                set LoadEnd 50
            } 
            
            set index [lsearch $args -loadstep]
            if {$index != -1} {
                set LoadStep [lindex $args [expr $index+1]]
            } else {
                set LoadStep 10
            }
             
            set index [lsearch $args -fixedload]
            if {$index != -1} {
                set FixedLoad [lindex $args [expr $index+1]]
            } else {
                set FixedLoad 10
            } 
            
            set index [lsearch $args -customloadlist]
            if {$index != -1} {
                set CustomLoadList [lindex $args [expr $index+1]]
            } else {
                set CustomLoadList 0
            } 
            
            set StreamBlockList ""
            set index [lsearch $args -streamlist]
            if {$index != -1} {
                set StreamList [lindex $args [expr $index+1]]
                
                foreach streamName $StreamList {
                    set ::mainDefine::objectName $streamName 
                    uplevel 1 {         
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                    }         
                    set hStream $::mainDefine::result
                
                    lappend StreamBlockList $hStream                   
                }
            }
            
            #Create Event
            set m_hEvent [stc::create IterateLoadSizeCommand -under system1]
            stc::config $m_hEvent  -LoadType $LoadType -LoadUnits $LoadUnits -LoadStart $LoadStart \
                   -LoadEnd $LoadEnd -LoadStep $LoadStep -CustomLoadList $CustomLoadList -FixedLoad $FixedLoad 
                                   
            if {$StreamBlockList != ""} {
                stc::config $m_hEvent -StreamBlockList $StreamBlockList
            }                       
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }

       "setduration" { 

            debugPut "config SetDuration"
            
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            
            set index [lsearch $args -durationmode]
            if {$index != -1} {
                set DurationMode [lindex $args [expr $index+1]]
            } else {
                set DurationMode "SECONDS"
            }

            set index [lsearch $args -durationseconds]
            if {$index != -1} {
                set DurationSeconds [lindex $args [expr $index+1]]
            } else {
                set DurationSeconds 10
            }

            set index [lsearch $args -durationbursts]
            if {$index != -1} {
                set DurationBursts [lindex $args [expr $index+1]]
            } else {
                set DurationBursts 1000
            }

            set generatorHandleList ""

            set index [lsearch $args -portlist]
            if {$index != -1} {
                set PortList [lindex $args [expr $index+1]]
                foreach portName $PortList {
                    set ::mainDefine::objectName $portName 
                    uplevel 1 {         
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
                    }         
                    set hPort $::mainDefine::result
                    set hGeneratorHandle [stc::get $hPort -children-Generator]
                
                    lappend generatorHandleList $hGeneratorHandle                  
                }
            }


            #Create Event
            set m_hEvent [stc::create SetDurationCommand -under system1]
            if {$generatorHandleList != ""} {
                stc::config $m_hEvent -DurationMode $DurationMode -DurationSeconds $DurationSeconds \
                         -DurationBursts $DurationBursts -GeneratorList $generatorHandleList
            } else {
                stc::config $m_hEvent -DurationMode $DurationMode -DurationSeconds $DurationSeconds \
                         -DurationBursts $DurationBursts
            }  
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }

        "generatorwaitforstop" { 

            debugPut "config generatorWaitForStop"
            
            set hEvent ""
            set index [lsearch $args -parent]
            if {$index != -1} {
                set Parent [lindex $args [expr $index+1]]
                set ::mainDefine::objectName $Parent 
                uplevel 1 {         
                    set ::mainDefine::result [$::mainDefine::objectName cget -m_hEvent]         
                }         
                set hEvent $::mainDefine::result
            } 
            
            set index [lsearch $args -waittimeout]
            if {$index != -1} {
                set WaitTimeOut [lindex $args [expr $index+1]]
            } else {
                set waitTimeOut 604800
            }
            #Create Event
            set m_hEvent [stc::create GeneratorWaitForStopCommand -under system1]
            stc::config $m_hEvent -WaitTimeOut $WaitTimeOut
            #Add Event into Scheduler
            set errorCode 1
            if {[catch {
               if {$hEvent != ""} {
                   set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq -CommandParent $hEvent]
               } else {
                  set errorCode [stc::perform SequencerInsert -CommandList $m_hEvent -InsertIndex $m_eventExecSeq ]
               }
            } err]} {
                return $errorCode
            }

            lappend ::mainDefine::gEventNameHandleList $m_eventName
            lappend ::mainDefine::gEventNameHandleList $m_hEvent
        }
        default {
            error "unsupported EventType($m_eventType)"
        }
    }
   
    set ::mainDefine::gEventCreatedAndConfiged 1
    set m_inserted 1
    debugPut "exit the proc of TestEvent::ConfigEvent"
    
    return $::mainDefine::gSuccess
}
