###########################################################################
#                                                                        
#  File Name：StatisticEngine.tcl                                                                                              
# 
#  Description：Definition of statistics engine and its methods                                             
# 
#  Author： Penn Chen
#
#  Create Time:  2007.4.27
#
#  Version：1.0 
# 
#  History：
# lana    20130926    修改统计结果保存到文件的名字，如果用户没有设置保存路径，则不保存
##########################################################################

##########################################
#Functionality:Convert from hex to dec
#Input: hex value
#Output: dec value
##########################################
proc myHex2Dec_stc { args } {
    set decimal [format "%u" $args]  
    return $decimal
}

##########################################
#Functionality:Convert from hex to dec
#Input: xx xx xx xx
#Output: xxxxxxxx
##########################################
proc GetTrigString { args } {
    set valueList [lindex $args 0]

    set list [split $valueList " "]
    set newList ""
    foreach ele $list {
        if {$ele == ""} {
            continue
        }
         set ele [format "%x" $ele]
     
         set itemLength [string length $ele] 
         if {$itemLength == 1} { 
             append newList 0$ele
         } else {
              append newList $ele
         }
    }

    return [lindex $newList 0]
}

##########################################
#Definition of StatisticEngine
##########################################   
::itcl::class StatisticEngine {
    
    #variables
    public variable m_portName 0
    public variable m_chassisName 0
    public variable m_portStreamLevel "TRUE"

    #constructor
    constructor {portName chassisName} { 
        set m_portName $portName
        set m_chassisName $chassisName

        set m_portStreamLevel $::mainDefine::gPortLevelStream 
        lappend ::mainDefine::gObjectNameList $this
    }

    #destructor
    destructor {
    set index [lsearch $::mainDefine::gObjectNameList $this]
    set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
    
    #Methods
    public method GetPortStats
    public method GetStreamStats
    public method GetHighResolutionSampleStats
	public method GetHighResolutionStreamBlockSampleStats

    #Methods internal use only
    public method CleanPortStats     
    public method SetWorkingMode
    public method GetPortStreamStats
    public method GetGlobalStreamStats
}

############################################################################
#APIName: GetPortStats
#
#Description: Get port statistics
#
#Input: 
#
#
#Output: Get statistics using list format，or get the value using parameter
#
#############################################################################
::itcl::body StatisticEngine::GetPortStats {args} {
    
    set PortStatResult ""
    
    debugPut "Enter the proc of StatisticEngine::GetPortStats"
    
    set errorCode 1
    set returnValue 1
	# Added by wan, 2013-09-25 Begin
    set args [ConvertAttrToLowerCase $args]
	#Parse filteredStream parameter
    set index [lsearch $args -filteredstream]
    if { $index !=-1} {
        set FilteredStream [lindex $args [expr $index+1]]
    } else {        
		set FilteredStream 0
	}
	
	#Parse resultPath parameter
    set index [lsearch $args -resultpath]
    if { $index !=-1} {
        set resultPath [lindex $args [expr $index+1]]
    } else {
		# lana changed，if don't set resultpath, won't save result to file
	    #set dir [file dirname [file dirname [info script]]]
        #if {[string equal $dir "."]} {
		#	set dir [pwd]
		#}        
		#set resultPath $dir
		set resultPath ""
	}
	# Added by wan, 2013-09-25 End
    if {$FilteredStream != 0 } {
         if {[catch {
                
             set ::mainDefine::objectName $m_portName 
             uplevel 1 {
                set ::mainDefine::result [$::mainDefine::objectName cget -m_filteredStreamResults]
             }
             set filteredStreamResults $::mainDefine::result  
             
             if {$filteredStreamResults == "0"} {
                 puts "You did not call the CreateFilter, ignore this parameter -FilteredStream"
                 return $returnValue 
             }

             set ::mainDefine::objectName $m_portName 
             uplevel 1 {
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
              }
              set PortHandle $::mainDefine::result  
              set hAnalyzer [stc::get $PortHandle -children-Analyzer]
             set hFilteredStreamResults [stc::get $hAnalyzer -children-filteredstreamresults]

             set GeneratorHandle [stc::get $PortHandle -children-Generator]

             set hGeneratorStatus [stc::get $GeneratorHandle -state]
             if {$hGeneratorStatus == "PENDING_STOP" } {
                 set loop 0
                 while {$hGeneratorStatus != "STOPPED" } {
                     if {$loop == "20"} {
                         debugPut "Timeout to wait for the generator to be stopped"
                         debugPut "exit the proc of StatisticEngine::GetPortStats"
                         return $errorCode
                     }

                     set loop [expr $loop + 1]
                     after 500
          
                     debugPut "Waiting for the generator to be stopped" 
                     set hGeneratorStatus [stc::get $GeneratorHandle -state]
                 }
             }

             if {$hFilteredStreamResults != "" && $hGeneratorStatus == "STOPPED" } {
                    set errorCode [stc::perform RefreshResultView -ResultDataSet $filteredStreamResults] 
             }   

             set waitTime 1000
             after $waitTime
                                     
             set resultList ""
    
             set fieldNum 10
             set sumArr(-StatsItem) "AggregateStats"
             set sumArr(-RxFrames) 0
             set sumArr(-RxSigFrames) 0
             set sumArr(-RxBytes) 0
             set sumArr(-CRCErrors) 0
             set sumArr(-RxIPv4chesumError) 0
             set sumArr(-RxDupelicated) 0
             set sumArr(-RxOutSeq) 0
             set sumArr(-RxDrop) 0
             set sumArr(-RxRateBytes) 0
             set sumArr(-RxRateFrames) 0
             #Loop until get all the results
            
             set filterVauleList ""
             set TotalPageCount [stc::get $filteredStreamResults -TotalPageCount]
             for {set currentPage 1} {$currentPage <= $TotalPageCount} {incr currentPage} {
                 stc::config $filteredStreamResults -PageNumber $currentPage
                 stc::apply

                 if {$hGeneratorStatus == "STOPPED"} {
                     stc::perform RefreshResultView -ResultDataSet $filteredStreamResults
                     after 2000
                 }
                 
                 set hList [stc::get $filteredStreamResults -resulthandlelist]             
                 foreach hResult $hList { 
                     set subList ""
                     array set arr [stc::get $hResult]
                    
                     set filterName ""
                     set filterValue ""
                     for {set i 1} {$i <= $fieldNum} {incr i} {
                         if {$arr(-FilteredName_$i) != ""}  {
                             lappend filterName $arr(-FilteredName_$i) 
                             lappend filterValue $arr(-FilteredValue_$i) 
        
                         }
                     }
    
                     set index [lsearch $filterVauleList $filterValue]
                     if {$index == -1} {
                        lappend filterVauleList $filterValue
                        set subStreamArr($filterValue,-FilterName) $filterName
                        set subStreamArr($filterValue,-FilterValue) $filterValue
                        set subStreamArr($filterValue,-RxFrames) 0
                        set subStreamArr($filterValue,-RxSigFrames) 0
                        set subStreamArr($filterValue,-RxBytes) 0
                        set subStreamArr($filterValue,-CRCErrors) 0
                        set subStreamArr($filterValue,-RxIPv4chesumError) 0
                        set subStreamArr($filterValue,-RxDupelicated) 0
                        set subStreamArr($filterValue,-RxOutSeq) 0
                        set subStreamArr($filterValue,-RxDrop) 0
                        set subStreamArr($filterValue,-RxRateBytes) 0
                        set subStreamArr($filterValue,-RxRateFrames) 0
                     }
        
                     set subStreamArr($filterValue,-RxFrames) [expr $subStreamArr($filterValue,-RxFrames) + $arr(-FrameCount)]
                     set sumArr(-RxFrames) [expr $sumArr(-RxFrames) + $arr(-FrameCount)]
        
                     set subStreamArr($filterValue,-RxSigFrames) [expr $subStreamArr($filterValue,-RxSigFrames) + $arr(-SigFrameCount)]
                     set sumArr(-RxSigFrames) [expr $sumArr(-RxSigFrames) + $arr(-SigFrameCount)]
        
                     set subStreamArr($filterValue,-RxBytes) [expr $subStreamArr($filterValue,-RxBytes) + $arr(-OctetCount)]
                     set sumArr(-RxBytes) [expr $sumArr(-RxBytes) + $arr(-OctetCount)]
        
                     set subStreamArr($filterValue,-CRCErrors) [expr $subStreamArr($filterValue,-CRCErrors) + $arr(-FcsErrorFrameCount)]
                     set sumArr(-CRCErrors) [expr $sumArr(-CRCErrors) + $arr(-FcsErrorFrameCount)]
        
                     set subStreamArr($filterValue,-RxIPv4chesumError) [expr $subStreamArr($filterValue,-RxIPv4chesumError) + $arr(-Ipv4ChecksumErrorCount)]
                     set sumArr(-RxIPv4chesumError) [expr $sumArr(-RxIPv4chesumError) + $arr(-Ipv4ChecksumErrorCount)]
        
                     set subStreamArr($filterValue,-RxDupelicated) [expr $subStreamArr($filterValue,-RxDupelicated) + $arr(-DuplicateFrameCount)]
                     set sumArr(-RxDupelicated) [expr $sumArr(-RxDupelicated) + $arr(-DuplicateFrameCount)]
        
                     set subStreamArr($filterValue,-RxOutSeq) [expr $subStreamArr($filterValue,-RxOutSeq) + $arr(-OutSeqFrameCount)]
                     set sumArr(-RxOutSeq) [expr $sumArr(-RxOutSeq) + $arr(-OutSeqFrameCount)]
        
                     set subStreamArr($filterValue,-RxRateBytes) [expr $subStreamArr($filterValue,-RxRateBytes) + $arr(-OctetRate)]
                     set sumArr(-RxRateBytes) [expr $sumArr(-RxRateBytes) + $arr(-OctetRate)]  

                     set subStreamArr($filterValue,-RxRateFrames) [expr $subStreamArr($filterValue,-RxRateFrames) + $arr(-FrameRate)]
                     set sumArr(-RxRateFrames) [expr $sumArr(-RxRateFrames) + $arr(-FrameRate)]                        
                 }
             }
             
			 
			 
             set totalStatsList ""
             foreach name [array names sumArr] {
                 lappend totalStatsList $name
                 lappend totalStatsList $sumArr($name)
             }
			 #Added by Wan, 2013-09-25 Begin
			 if {$resultPath != ""} {
				set timestamp [clock format [clock seconds] -format %Y%m%d%H%M%S]
				set fileName [file join $resultPath ${m_portName}_$timestamp.csv]
				set fid [open $fileName w]
				set row1 ""
				set row2 ""
				foreach {name value} $totalStatsList {
					 if {$row1 ==""} {
						 set row1  [lindex [split $name "-"] 1] 
					 } else {
						 set row1  "$row1,[lindex [split $name "-"] 1]"
					 }
					 if {$row2 ==""} {
						 set row2  $value 
					 } else {
						 set row2  "$row2,$value"
					 }
				}
				puts $fid "$row1"
				puts $fid "$row2"
			 }
			 #Added by Wan, 2013-09-25 End
             set reslut [subst {{$totalStatsList}}]
             
             set subStreamList ""
             set name1List ""
             set name2List ""
             foreach name [array names subStreamArr] {
                 set list [split $name ,]
                 set name1 [lindex $list 0]
                 set name2 [lindex $list 1]
                 set index [lsearch $name1List $name1]
                 if {$index == -1} {
                     lappend name1List $name1
                 }

                 set index1 [lsearch $name2List $name2]
                 if {$index1 == -1} {
                     lappend name2List $name2
                 }
             }

             foreach name1 $filterVauleList {
                set subStream ""
                foreach name2 $name2List {
                     lappend subStream $name2
                     lappend subStream $subStreamArr($name1,$name2)
                }
				#Added by Wan, 2013-09-25 Begin
				set row1 ""
				set row2 ""
				foreach {name value} $subStream {
					  if {$row1 ==""} {
						  set row1  [lindex [split $name "-"] 1] 
					  } else {
						  set row1  "$row1,[lindex [split $name "-"] 1]"
					  }
					  if {$row2 ==""} {
						  set row2  $value 
					  } else {
						  set row2  "$row2,$value"
					  }
				}
				puts $fid "Filtered Value:$name1"
				puts $fid "$row1"
				puts $fid "$row2"
				#Added by Wan, 2013-09-25 End
				
                lappend subStreamList $subStream   
             }
			 #Added by Wan, 2013-09-25 Begin
             close $fid
			 #Added by Wan, 2013-09-25 End
             set returnValue [lappend reslut $subStreamList]
             
             debugPut "exit the proc of StatisticEngine::GetPortStats"
             return $returnValue
              } err]} {
                  if {$err != $returnValue} {
                     puts "error: $err"
                     debugPut "exit the proc of StatisticEngine::GetPortStats"
                     return $errorCode
                 } else {
                     return  $returnValue
                 }
          }         
    }
    

    if {[catch {
        #Get port statitics
        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
        }
        set PortHandle $::mainDefine::result  
             
        set GeneratorHandle [stc::get $PortHandle -children-Generator]

        set ::mainDefine::objectName $m_portName 
        uplevel 1 {
             set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
        }
        set DeviceHandle $::mainDefine::result 
        
        set ::mainDefine::objectName $DeviceHandle 
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_generatorPortResultHandle ]
        }
        set TxPortResultHandle $::mainDefine::result 
        
        set ::mainDefine::objectName $DeviceHandle 
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_analyzerPortResultHandle ]
        }
        set RxPortResultHandle $::mainDefine::result 

        set hGeneratorStatus [stc::get $GeneratorHandle -state]
        if {$hGeneratorStatus == "PENDING_STOP" } {
            set loop 0
            while {$hGeneratorStatus != "STOPPED" } {
                if {$loop == "20"} {
                    debugPut "Timeout to wait for the generator to be stopped"
                    return $PortStatResult
                }

                set loop [expr $loop + 1]
                after 500
          
                debugPut "Waiting for the generator to be stopped" 
                set hGeneratorStatus [stc::get $GeneratorHandle -state]
            }
       }
       
       if {$hGeneratorStatus == "STOPPED"} {       
             if {[catch { 
                 set ::mainDefine::objectName $m_portName 
                 uplevel 1 {
                     set ::mainDefine::result [$::mainDefine::objectName cget -m_generatorStarted ]
                 }
                 set generatorStarted $::mainDefine::result

                 if {$generatorStarted == "TRUE"} {
                     after 500
                     set errorCode [stc::perform RefreshResultView -ResultDataSet $TxPortResultHandle  ]
                     after 500
                     set errorCode [stc::perform RefreshResultView -ResultDataSet $RxPortResultHandle  ]
                     after 500
                 }
             } err]} {
                return $errorCode
            }
        }
    
        set GeneratorPortResultHandle [stc::get $GeneratorHandle -children-GeneratorPortResults] 

        lappend PortStatResult "-TxFrames"
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorFrameCount]"
 
        lappend PortStatResult "-TxBytes"
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -TotalOctetCount]"

        lappend PortStatResult "-TxRateFrames"
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorFrameRate]"
        
        lappend PortStatResult "-TxRateBytes"
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle  -GeneratorOctetRate]"
      
        lappend PortStatResult "-TxSignature"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorSigFrameCount]"

        lappend PortStatResult "-TxSignatureRate"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorSigFrameRate]"        
        
        #Get port statistics
        lappend PortStatResult "-TxL1BitCount"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -L1BitCount]"   
        
        lappend PortStatResult "-TxL1BitRate"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -L1BitRate]"  
        
		#Added by Wan, 2013-09-23, Begin
        lappend PortStatResult "-TxUndersizeFrameCount"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorUndersizeFrameCount]"
		lappend PortStatResult "-TxUndersizeFrameRate"   
        lappend PortStatResult "[stc::get $GeneratorPortResultHandle -GeneratorUndersizeFrameRate]"
		
		#End
		
        set AnalyzerHandle [stc::get $PortHandle -children-Analyzer]
        set AnalyzerResultHandle [stc::get $AnalyzerHandle -children-AnalyzerPortResults] 
        set AnalyzerCpuResultHandle [stc::get $AnalyzerHandle -children-RxCpuPortResults] 
        lappend PortStatResult "-RxFrames"    
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -TotalFrameCount]"   

        lappend PortStatResult "-RxBytes"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -TotalOctetCount]"

        lappend PortStatResult "-RxRateFrames"    
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -TotalFrameRate]"   
 
         lappend PortStatResult "-RxRateBytes" 
         lappend PortStatResult "[stc::get $AnalyzerResultHandle -TotalOctetRate]"
        
        lappend PortStatResult "-RxSignature"       
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -SigFrameCount]"   

        lappend PortStatResult "-RxSignatureRate"       
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -SigFrameRate]"         

        lappend PortStatResult "-RxCRCErrors"      
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -FcsErrorFrameCount]"   
      
        lappend PortStatResult "-OverSize"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -OversizeFrameCount]"   
      
        lappend PortStatResult "-FragOrUndersize"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -UndersizeFrameCount]"      
      
        lappend PortStatResult "-RxTrigger1"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger1Count]"      
      
        lappend PortStatResult "-RxTrigger2"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger2Count]"      
      
        lappend PortStatResult "-RxTrigger3"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger3Count]"      
         
        lappend PortStatResult "-RxTrigger4"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger4Count]"      
         
        lappend PortStatResult "-RxTrigger5"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger5Count]"      
      
        lappend PortStatResult "-RxTrigger6"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger6Count]"      
      
        lappend PortStatResult "-RxTrigger7"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger7Count]"      
      
        lappend PortStatResult "-RxTrigger8"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Trigger8Count]"                  
      
        lappend PortStatResult "-RxIPv4Frames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Ipv4FrameCount]"      
      
        lappend PortStatResult "-RxIPv6Frames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Ipv6FrameCount]"      
      
        lappend PortStatResult "-RxIPv4chesumError"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -Ipv4ChecksumErrorCount]"      
               
        lappend PortStatResult "-RxJumboFrames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -JumboFrameCount]"      
      
        lappend PortStatResult "-RxVLANFrames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -VlanFrameCount]"      
      
        lappend PortStatResult "-RxPauseFrames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -PauseFrameCount]"      
      
        lappend PortStatResult "-RxMplsFrames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -MplsFrameCount]"      
      
        lappend PortStatResult "-RxIcmpFrames"     
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -IcmpFrameCount]"      
      
        lappend PortStatResult "-RxArpReplies"     
        lappend PortStatResult "[stc::get $AnalyzerCpuResultHandle -CpuArpReplyCount]"      
       
        lappend PortStatResult "-RxArpRequests"     
        lappend PortStatResult "[stc::get $AnalyzerCpuResultHandle -CpuArpRequestCount]"     
        
        lappend PortStatResult "-RxL1BitCount"   
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -L1BitCount]"   
        
        lappend PortStatResult "-RxL1BitRate"   
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -L1BitRate]" 
        
        #Added by Wan, 2013-09-23, Begin
        lappend PortStatResult "-RxUndersizeFrameCount"   
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -UndersizeFrameCount]"
		
		lappend PortStatResult "-RxUndersizeFrameRate"   
        lappend PortStatResult "[stc::get $AnalyzerResultHandle -UndersizeFrameRate]"
		#End		
        
        for {set i 1} {$i <= 6} {incr i} { 
            lappend PortStatResult "-UserDefinedFrameRate$i"   
            lappend PortStatResult "[stc::get $AnalyzerResultHandle -UserDefinedFrameRate$i]"  
            
            lappend PortStatResult "-UserDefinedFrameCount$i"   
            lappend PortStatResult "[stc::get $AnalyzerResultHandle -UserDefinedFrameCount$i]"   
        }   
     } err] } {
        debugPut "Error caught in GetPortStats on $m_portName: $err" 
    }

	#Added by Wan, 2013-09-23 Begin
	if {$resultPath != ""} {
		set timestamp [clock format [clock seconds] -format %Y%m%d%H%M%S]
		set fileName [file join $resultPath ${m_portName}_$timestamp.csv]
		set fid [open $fileName w]
		set row1 ""
		set row2 ""
		foreach {name value} $PortStatResult {
			  if {$row1 ==""} {
				  set row1  [lindex [split $name "-"] 1] 
			  } else {
				  set row1  "$row1,[lindex [split $name "-"] 1]"
			  }
			  if {$row2 ==""} {
				  set row2  $value 
			  } else {
				  set row2  "$row2,$value"
			  }
		}
		puts $fid "$row1"
		puts $fid "$row2"
		close $fid
	}
	#Added by Wan, 2013-09-23 End
	
	#Added by Wan, 2013-09-25 Begin
	set args_bak $args
	#Parse filteredstream parameter
    set index [lsearch $args -filteredstream]
    if { $index !=-1} {
		set args [concat [lrange $args 0 [expr $index -1]] [lrange $args [expr $index +2] end]]
    } 	
	#Parse resultPath parameter
    set index [lsearch $args -resultpath]
    if { $index !=-1} {
        set args [concat [lrange $args 0 [expr $index -1]] [lrange $args [expr $index +2] end]]
    } 
	#Added by Wan, 2013-09-25 End
	#Return statistics according to input parameter
    if { $args == "" } {
        debugPut "Exit the proc of StatisticEngine::GetPortStats" 
        return $PortStatResult
    } else {
        set args [ConvertAttrToLowerCase $args_bak]
        set PortStatResult [string tolower $PortStatResult]

        array set arr $PortStatResult
        foreach {name valueVar}  $args {      
            if {$name == "-filteredstream"} {
               continue
            }
			if {$name == "-resultpath"} {
               continue
            }
			set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "Exit the proc of StatisticEngine::GetPortStats"        
    }                              
}

############################################################################
#APIName: GetStreamStats
#
#Description: Get stream statistics 
#
#Input:    (1) -StreamName stream name，required,i.e -StreamName streamblock 1
#            (2) Other input parameters including -TxFrames,-TxBytes,-RxFrames,-RxBytes,-RxSigFrames,
#                 -RxAvgLatency,-RxAvgJitter,-CRCErrors,-RxIPv4chesumError,-RxDupelicated,-RxOutSeq
#
#
#
#Output: Get statistics using list format，or get the value using parameter
#
#############################################################################
::itcl::body StatisticEngine::GetStreamStats {args} {
    
    set StreamStatResult "" 
    
    debugPut "Enter the proc of StatisticEngine::GetStreamStats"    
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result

    set AnalyzerHandle [stc::get $PortHandle -children-Analyzer]
    set FilterOnStreamId [stc::get $AnalyzerHandle -FilterOnStreamId] 

    set StreamStatResult ""
    set ::mainDefine::objectName $this
    set ::mainDefine::args $args
   
    #我们设置可以取全局的流统计结果或者基于端口的流统计结果，
    #在默认的情况下，取基于端口的流统计结果，当然如果设置了filter的话，那么
    #该端口取的就是全局的流统计结果
    if {[string tolower $m_portStreamLevel ] == "true" } {
        if {[string tolower $FilterOnStreamId] == "true"} {
            uplevel 1 {
                 set ::mainDefine::result [$::mainDefine::objectName GetPortStreamStats $::mainDefine::args]
            }
            set  StreamStatResult  $::mainDefine::result      
        } else {
            uplevel 1 {
                set ::mainDefine::result [$::mainDefine::objectName GetGlobalStreamStats $::mainDefine::args]
            }
            set  StreamStatResult  $::mainDefine::result      
        }
    } else {
        uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName GetGlobalStreamStats $::mainDefine::args]
        }
        set  StreamStatResult  $::mainDefine::result      
    } 
  
    
	#Added by Wan, 2013-09-23 Begin
	set args [ConvertAttrToLowerCase $args]
	# Parse streamname parameter
	set index [lsearch $args -streamname]
    if { $index !=-1} {
		set streamName [lindex $args [expr $index+1]]
	}
	
	#Parse resultPath parameter
    set index [lsearch $args -resultpath]
    if { $index !=-1} {
        set resultPath [lindex $args [expr $index+1]]
    } else {
	    #set dir [file dirname [file dirname [info script]]]
        #if {[string equal $dir "."]} {
		#	set dir [pwd]
		#}        
		#set resultPath $dir
		set resultPath ""
	}
	if {$resultPath != ""} {
		set timestamp [clock format [clock seconds] -format %Y%m%d%H%M%S]
		set fileName [file join $resultPath ${m_portName}_${streamName}_$timestamp.csv]
		set fid [open $fileName w]
		set row1 ""
		set row2 ""
		foreach {name value} $StreamStatResult {
			  if {$row1 ==""} {
				  set row1  [lindex [split $name "-"] 1] 
			  } else {
				  set row1  "$row1,[lindex [split $name "-"] 1]"
			  }
			  if {$row2 ==""} {
				  set row2  $value 
			  } else {
				  set row2  "$row2,$value"
			  }
		}
		puts $fid "$row1"
		puts $fid "$row2"
		close $fid	
	}
	#Added by Wan, 2013-09-23 End
    #Added by Wan, 2013-09-25 Begin
	set args_bak $args
	#Parse filteredstream parameter
    set index [lsearch $args -streamname]
    if { $index !=-1} {
		set args [concat [lrange $args 0 [expr $index -1]] [lrange $args [expr $index +2] end]]
    } 	
	#Parse resultPath parameter
    set index [lsearch $args -resultpath]
    if { $index !=-1} {
        set args [concat [lrange $args 0 [expr $index -1]] [lrange $args [expr $index +2] end]]
    } 
	#Added by Wan, 2013-09-25 End
	
    if { $args == "" } {
        debugPut "Exit the proc of StatisticEngine::GetStreamStats"    
        return $StreamStatResult
    } else {
        set args [ConvertAttrToLowerCase $args_bak]
        set StreamStatResult [string tolower $StreamStatResult]

        array set arr $StreamStatResult
        foreach {name valueVar}  $args {      

            if {$name == "-streamname"} {
               continue
            }
			if {$name == "-resultpath"} {
               continue
            }

            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }           
        }    
    }
    debugPut "Exit the proc of StatisticEngine::GetStreamStats"    

    return  $::mainDefine::gSuccess 
}

############################################################################
#APIName: GetGlobalStreamStats
#
#Description: Get global stream statistics
#
#Input:    (1) -StreamName stream name，required,i.e -StreamName streamblock 1
#            (2) Other input parameters including -TxFrames,-TxBytes,-RxFrames,-RxBytes,-RxSigFrames,
#                 -RxAvgLatency,-RxAvgJitter,-CRCErrors,-RxIPv4chesumError,-RxDupelicated,-RxOutSeq
#
#
#
#Output: Get statistics using list format，or get the value using parameter
#
#############################################################################
::itcl::body StatisticEngine::GetGlobalStreamStats {args} {
    set args [eval subst $args ]

    set args_new  [ConvertAttrToLowerCase $args]

    set StreamStatResult "" 
    
    #Check stream name
    set StreamName ""
    set index [lsearch $args_new -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args_new [expr $index + 1]]
    } else  {
        error "please specify the StreamName"
    }
        
    #Get stream handle
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]
    }
    set StreamHandle $::mainDefine::result         
        
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_IPv4HeaderFlag]
    }
    set IPv4HeaderFlag $::mainDefine::result        
        
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_FrameSigFlag]
    }
    set SigFlag $::mainDefine::result 
        
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result    

    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_portName]
    }
    set SrcPortName $::mainDefine::result   
         
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
    }
    set DeviceHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_txStreamResultHandle]
    }
    set TxStreamResultHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_rxStreamResultHandle]
    }
    set RxStreamResultHandle $::mainDefine::result 

    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_txStreamSummaryResultHandle]
    }
    set TxStreamSummaryResultHandle $::mainDefine::result 
    
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_rxStreamSummaryResultHandle]
    }
    set RxStreamSummaryResultHandle $::mainDefine::result 
                  
    set errorCode 1               
    #When get the rate, it is not necessary to refresh the result
    if {[info exists ::mainDefine::gStreamSrcPort($StreamName)]} {
         set srcPortHandle $::mainDefine::gStreamSrcPort($StreamName) 
    } else {
          error "You did not create the stream yet. \nExit the proc of StatisticEngine::GetStreamStats"
    }
    set hPortGenerator [stc::get $srcPortHandle -children-generator]
    set hGeneratorStatus [stc::get $hPortGenerator -state]
    if {$hGeneratorStatus == "PENDING_STOP" } {
         set loop 0
         while {$hGeneratorStatus != "STOPPED" } {
             if {$loop == "20"} {
                 debugPut "Timeout to wait for the generator to be stopped"
                 return $StreamStatResult
             }

             set loop [expr $loop + 1]
             after 500
          
             debugPut "Waiting for the generator to be stopped" 
             set hGeneratorStatus [stc::get $hPortGenerator -state]
         }
    }

    set ::mainDefine::objectName $SrcPortName
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_streamStatisticRefershed ]
    }
    set streamStatisticRefershed $::mainDefine::result  

    if {$hGeneratorStatus == "STOPPED" && $streamStatisticRefershed == "FALSE" } { 
        set ::mainDefine::gCurrentTxPageNumber 0
        set ::mainDefine::gCurrentRxPageNumber 0

        set ::mainDefine::objectName $SrcPortName
        uplevel 1 {
            $::mainDefine::objectName configure -m_streamStatisticRefershed "TRUE" 
        }
   
        if {[catch {
            set errorCode [stc::perform RefreshResultView -ResultDataSet $TxStreamResultHandle  ]
        } err]} {
            return $errorCode
        }
        after 500
        
        if {[catch {
            set errorCode [stc::perform RefreshResultView -ResultDataSet $RxStreamResultHandle]
        } err]} {
            return $errorCode
        }
        after 500   
    }    

    set tx_h ""
    set TotalPageCount [stc::get $TxStreamResultHandle -TotalPageCount]
    if {$TotalPageCount >1 } {
       
        if {$::mainDefine::gCurrentTxPageNumber != 0} {
            set txHandleList $::mainDefine::gCachedTxStreamHandleList
            foreach txHandle $txHandleList {
                set txHandleParent [stc::get $txHandle -parent]
                set txHandleName [stc::get $txHandleParent -name]
                if { $txHandleName == $StreamName } {
                    set tx_h $txHandle
                    break
                }    
            }  
        }

        if {$tx_h == ""} {  
           set currentPage 1
           while { $currentPage <= $TotalPageCount } {
                stc::config $TxStreamResultHandle -PageNumber $currentPage
                stc::apply         
                if {[catch {
                    if {$hGeneratorStatus == "STOPPED"} {
                        set errorCode [stc::perform RefreshResultView -ResultDataSet $TxStreamResultHandle  ]
                    }  
                } err]} {
                   return $errorCode
               }
               after 500
               
               set txHandleList [stc::get $TxStreamResultHandle -resulthandlelist]
               foreach txHandle $txHandleList {
                   set txHandleParent [stc::get $txHandle -parent]
                   set txHandleName [stc::get $txHandleParent -name]
                   if { $txHandleName == $StreamName } {
                       set tx_h $txHandle
                      
                       set ::mainDefine::gCurrentTxPageNumber $currentPage
                       set ::mainDefine::gCachedTxStreamHandleList $txHandleList
                       break
                   }    
               }

               if {$tx_h != ""} {
                   break
               }
              
               incr currentPage
           };# end while
        }

        if {$tx_h == "" } {
            debugPut "can not find stream result oject in all result pages"                            
        }    
    } else {  
        set txHandleList [stc::get $TxStreamResultHandle -resulthandlelist]  
        foreach txHandle $txHandleList {
              set txHandleParent [stc::get $txHandle -parent]
              set txHandleName [stc::get $txHandleParent -name]
              if { $txHandleName == $StreamName } {
                  set tx_h $txHandle
                  break
              }    
        }
   }

   set txSummary_h ""
   if {$hGeneratorStatus != "STOPPED" } {    
       set TxStreamSummaryResultHandleList [stc::get $TxStreamSummaryResultHandle -resulthandlelist]
       foreach txHandle $TxStreamSummaryResultHandleList  {
           set txHandleParent [stc::get $txHandle -parent]
           set txHandleName [stc::get $txHandleParent -name]
           if { $txHandleName == $StreamName } {
               set txSummary_h $txHandle
               break
           }    
      }
    }
                
    if {$tx_h != "" } {  
        lappend StreamStatResult "-TxFrames"          
        lappend StreamStatResult "[stc::get $tx_h -FrameCount]"               
        if {$SigFlag == 1} {
            lappend StreamStatResult "-TxSigFrames"
            lappend StreamStatResult "[stc::get $tx_h -FrameCount]"
        } else {
            lappend StreamStatResult "-TxSigFrames"
            lappend StreamStatResult 0
        }            
                            
        lappend StreamStatResult "-TxBytes"          
        lappend StreamStatResult "[stc::get $tx_h -OctetCount]"     
             
        if {$IPv4HeaderFlag == 1} {
            lappend StreamStatResult "-TxIPv4Frames"
            lappend StreamStatResult "[stc::get $tx_h -FrameCount]"
        } else {
            lappend StreamStatResult "-TxIPv4Frames"
            lappend StreamStatResult 0
        }  
        
        if {$txSummary_h != ""} {
            lappend StreamStatResult "-TxRateBytes"          
            lappend StreamStatResult "[stc::get $txSummary_h -OctetRate]"
            lappend StreamStatResult "-TxRateFrames"          
            lappend StreamStatResult "[stc::get $txSummary_h -FrameRate]"             
            lappend StreamStatResult "-TxL1BitCount"          
            lappend StreamStatResult "[stc::get $txSummary_h -L1BitCount]"
            lappend StreamStatResult "-TxL1BitRate"          
            lappend StreamStatResult "[stc::get $txSummary_h -L1BitRate]"             
        } else {
            lappend StreamStatResult "-TxRateBytes"          
            lappend StreamStatResult 0

            lappend StreamStatResult "-TxRateFrames"          
            lappend StreamStatResult 0             
             
            lappend StreamStatResult "-TxL1BitCount"          
            lappend StreamStatResult "[stc::get $tx_h -L1BitCount]"
             
            lappend StreamStatResult "-TxL1BitRate"          
            lappend StreamStatResult 0                       
        }
    } else {
        lappend StreamStatResult "-TxFrames"          
        lappend StreamStatResult 0              
        lappend StreamStatResult "-TxSigFrames"
        lappend StreamStatResult 0
                       
        lappend StreamStatResult "-TxBytes"          
        lappend StreamStatResult 0    
        lappend StreamStatResult "-TxIPv4Frames"
        lappend StreamStatResult 0
        
        lappend StreamStatResult "-TxRateBytes"          
        lappend StreamStatResult 0

        lappend StreamStatResult "-TxRateFrames"          
        lappend StreamStatResult 0             
        
        lappend StreamStatResult "-TxL1BitRate"          
        lappend StreamStatResult 0            
    }    
    
    set rx_h ""       
    set TotalPageCount [stc::get $RxStreamResultHandle -TotalPageCount]
    if {$TotalPageCount >1 } {
        if {$::mainDefine::gCurrentRxPageNumber != 0} {
           set rxHandleList $::mainDefine::gCachedRxStreamHandleList
           foreach rxHandle $rxHandleList {
                set rxHandleParent [stc::get $rxHandle -parent]
                set rxHandleName [stc::get $rxHandleParent -name]
                if { $rxHandleName == $StreamName } {
                    set rx_h $rxHandle
                    break
                }    
            }
        }
        if {$rx_h == ""} {
            set currentPage 1
            while { $currentPage <= $TotalPageCount } {
                stc::config $RxStreamResultHandle -PageNumber $currentPage
                stc::apply         
                  if {[catch {
                    set errorCode [stc::perform RefreshResultView -ResultDataSet $RxStreamResultHandle]
                } err]} {
                    return $errorCode
                }
                after 500 

                set rxHandleList [stc::get $RxStreamResultHandle -resulthandlelist]               
               
               foreach rxHandle $rxHandleList {
                   set rxHandleParent [stc::get $rxHandle -parent]
                   set rxHandleName [stc::get $rxHandleParent -name]
                   if { $rxHandleName == $StreamName } {
                       set rx_h $rxHandle
                       set ::mainDefine::gCurrentRxPageNumber $currentPage 
                       set ::mainDefine::gCachedRxStreamHandleList $rxHandleList
                       break
                   }    
               }
 
               if {$rx_h != ""} {
                  break
               }
              
               incr currentPage
           };# end while
        }

        if {$rx_h == "" } {
            debugPut "can not find stream result oject in all result pages"                            
        }    
    } else {
        # 当stream不唯一时，获取streamName对应的句柄
        set rx_h ""
 
        set rxHandle [stc::get $RxStreamResultHandle -resulthandlelist]  
        foreach txHandle $rxHandle {
            set txHandleParent [stc::get $txHandle -parent]
            set txHandleName [stc::get $txHandleParent -name]
            if { $txHandleName == $StreamName } {
                set rx_h $txHandle
                break
            }    
         }     
    }

    set rxSummary_h ""
    if {$hGeneratorStatus != "STOPPED" } {  
        set RxStreamSummaryResultHandleList [stc::get $RxStreamSummaryResultHandle -resulthandlelist]
        foreach temp $RxStreamSummaryResultHandleList {
            set rxHandleParent [stc::get $temp -parent]
            set rxHandleName [stc::get $rxHandleParent -name]
            if {$rxHandleName == $StreamName } {
                set rxSummary_h $temp
                break
           }
        }        
     }
                  
     if {$rx_h != ""} {
         lappend StreamStatResult "-RxFrames"                         
         lappend StreamStatResult "[stc::get $rx_h -FrameCount]"                        
         lappend StreamStatResult "-RxSigFrames"                    
         lappend StreamStatResult "[stc::get $rx_h -sigFrameCount]"           
      
         lappend StreamStatResult "-RxBytes"                    
         lappend StreamStatResult "[stc::get $rx_h -OctetCount]"    

         if {$IPv4HeaderFlag == 1} {
              lappend StreamStatResult "-RxIPv4Frames"
              lappend StreamStatResult "[stc::get $rx_h -FrameCount]"
         } else {
              lappend StreamStatResult "-RxIPv4Frames"
              lappend StreamStatResult 0
         }               
     
         lappend StreamStatResult "-RxAvgLatency"                                 
         lappend StreamStatResult "[stc::get $rx_h -AvgLatency]"                              

         lappend StreamStatResult "-RxAvgJitter"                    
         lappend StreamStatResult "[stc::get $rx_h -AvgJitter]"                                 
        
         lappend StreamStatResult "-CRCErrors"                        
         lappend StreamStatResult "[stc::get $rx_h -FcsErrorFrameCount]"
         
         lappend StreamStatResult "-RxIPv4chesumError"                        
         lappend StreamStatResult "[stc::get $rx_h -Ipv4ChecksumErrorCount]"           
     
         lappend StreamStatResult "-RxDupelicated"                        
         lappend StreamStatResult "[stc::get $rx_h -DuplicateFrameCount]"           

         lappend StreamStatResult "-RxInSeq"                    
         lappend StreamStatResult "[stc::get $rx_h -InSeqFrameCount]"  
  
         lappend StreamStatResult "-RxOutSeq"                        
         lappend StreamStatResult "[stc::get $rx_h -OutSeqFrameCount]"           
 
         lappend StreamStatResult "-RxDrop"                        
         lappend StreamStatResult "[stc::get $rx_h -DroppedFrameCount]"    

         lappend StreamStatResult "-RxPrbsBytes"                        
         lappend StreamStatResult "[stc::get $rx_h -PrbsFillOctetCount]"  
                         
         lappend StreamStatResult "-RxPrbsBitErr"                        
         lappend StreamStatResult "[stc::get $rx_h -PrbsBitErrorCount]"  
        
         lappend StreamStatResult "-RxTcpUdpChecksumErr"                        
         lappend StreamStatResult "[stc::get $rx_h -TcpUdpChecksumErrorCount]"
         
         lappend StreamStatResult "-FirstArrivalTime"                        
         lappend StreamStatResult "[stc::get $rx_h -FirstArrivalTime]"
         
         lappend StreamStatResult "-LastArrivalTime"                        
         lappend StreamStatResult "[stc::get $rx_h -LastArrivalTime]"
         
         
         if {$rxSummary_h != ""} {
             lappend StreamStatResult "-RxRateBytes"               
             lappend StreamStatResult "[stc::get $rxSummary_h -OctetRate]" 

             lappend StreamStatResult "-RxRateFrames"                        
             lappend StreamStatResult "[stc::get $rxSummary_h -FrameRate]" 
             
             lappend StreamStatResult "-RxL1BitCount"          
             lappend StreamStatResult "[stc::get $rxSummary_h -L1BitCount]"

             lappend StreamStatResult "-RxL1BitRate"          
             lappend StreamStatResult "[stc::get $rxSummary_h -L1BitRate]"   
         } else {
             lappend StreamStatResult "-RxRateBytes"               
             lappend StreamStatResult 0   

             lappend StreamStatResult "-RxRateFrames"               
             lappend StreamStatResult 0   
             
             lappend StreamStatResult "-RxL1BitCount"          
             lappend StreamStatResult "[stc::get $rx_h -L1BitCount]"

             lappend StreamStatResult "-RxL1BitRate"          
             lappend StreamStatResult 0    
         }
     } else {
         lappend StreamStatResult "-RxFrames"                         
         lappend StreamStatResult 0                      
        
         lappend StreamStatResult "-RxSigFrames"                    
         lappend StreamStatResult 0
      
         lappend StreamStatResult "-RxBytes"                    
         lappend StreamStatResult 0

         lappend StreamStatResult "-RxIPv4Frames"
         lappend StreamStatResult 0               
     
         lappend StreamStatResult "-RxAvgLatency"                                 
         lappend StreamStatResult 0                              

         lappend StreamStatResult "-RxAvgJitter"                    
         lappend StreamStatResult 0                                 
        
         lappend StreamStatResult "-CRCErrors"                        
         lappend StreamStatResult 0           

         lappend StreamStatResult "-RxIPv4chesumError"                        
         lappend StreamStatResult 0           
     
         lappend StreamStatResult "-RxDupelicated"                        
         lappend StreamStatResult 0           

         lappend StreamStatResult "-RxInSeq"                    
         lappend StreamStatResult 0  
  
         lappend StreamStatResult "-RxOutSeq"                        
         lappend StreamStatResult 0           
 
         lappend StreamStatResult "-RxDrop"                        
         lappend StreamStatResult 0    

         lappend StreamStatResult "-RxPrbsBytes"                        
         lappend StreamStatResult 0  
                         
         lappend StreamStatResult "-RxPrbsBitErr"                        
         lappend StreamStatResult 0  
        
         lappend StreamStatResult "-RxTcpUdpChecksumErr"                        
         lappend StreamStatResult 0      

         lappend StreamStatResult "-RxRateBytes"               
         lappend StreamStatResult 0   

         lappend StreamStatResult "-RxRateFrames"               
         lappend StreamStatResult 0   
         
         lappend StreamStatResult "-RxL1BitCount"          
         lappend StreamStatResult 0

         lappend StreamStatResult "-RxL1BitRate"          
         lappend StreamStatResult 0
         
         lappend StreamStatResult "-FirstArrivalTime"                        
         lappend StreamStatResult 0
         
         lappend StreamStatResult "-LastArrivalTime"                        
         lappend StreamStatResult 0
    }

    return $StreamStatResult
}

############################################################################
#APIName: GetPortStreamStats
#
#Description: Get stream statistics
#
#Input:    (1) -StreamName stream name，required,i.e -StreamName streamblock 1
#            (2) Other input parameters including -TxFrames,-TxBytes,-RxFrames,-RxBytes,-RxSigFrames,
#                 -RxAvgLatency,-RxAvgJitter,-CRCErrors,-RxIPv4chesumError,-RxDupelicated,-RxOutSeq
#
#
#
#Output: Get statistics using list format，or get the value using parameter
#
#############################################################################
::itcl::body StatisticEngine::GetPortStreamStats {args} {
    
    set StreamStatResult "" 
    set streamId 0 
    
    set args [eval subst $args ]

    set args_new [ConvertAttrToLowerCase $args]

    #Check stream name
    set StreamName ""
    set index [lsearch $args_new -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args_new [expr $index + 1]]
    } else  {
        error "please specify the StreamName"
    }
        
    #Get stream handle
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]
    }
    set StreamHandle $::mainDefine::result         
        
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_IPv4HeaderFlag]
    }
    set IPv4HeaderFlag $::mainDefine::result        
        
    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_FrameSigFlag]
    }
    set SigFlag $::mainDefine::result 

    set ::mainDefine::objectName $StreamName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_portName]
    }
    set SrcPortName $::mainDefine::result 
        
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result
                
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_chassisName]
    }
    set DeviceHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_txStreamResultHandle]
    }
    set TxStreamResultHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $DeviceHandle 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_txStreamSummaryResultHandle]
    }
    set TxStreamSummaryResultHandle $::mainDefine::result 
        
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
         set ::mainDefine::result [$::mainDefine::objectName cget -m_filteredStreamResults]
    }
    set filteredStreamResults $::mainDefine::result  
          
    set errorCode 1               
    #When getting stream rate, it is not necessary to refresh results
    if {[info exists ::mainDefine::gStreamSrcPort($StreamName)]} {
         set srcPortHandle $::mainDefine::gStreamSrcPort($StreamName) 
    } else {
         error "You did not create the stream yet. \nExit the proc of StatisticEngine::GetStreamStats"
    }

    catch {
        set TotalPageCount [stc::get $TxStreamSummaryResultHandle -TotalPageCount]
        
        if {$TotalPageCount >1 } {
            if {$::mainDefine::gCurrentTxSummaryPageNumber != 0} {
                set txHandleList $::mainDefine::gCachedRxSummaryStreamHandleList
                foreach txHandle $txHandleList {
                    set txHandleParent [stc::get $txHandle -parent]
                    set txHandleName [stc::get $txHandleParent -name]
                    if { $txHandleName == $StreamName } {
                        set streamId [stc::get $txHandle -StreamId]
                        break
                    }    
                }
            }

            if {$streamId == "0"} {
                set currentPage 1
                while { $currentPage <= $TotalPageCount } {
                    stc::config $TxStreamSummaryResultHandle -PageNumber $currentPage
                    stc::apply 

                    set TxStreamSummaryResultHandleList [stc::get $TxStreamSummaryResultHandle -resulthandlelist]
                    foreach txHandle $TxStreamSummaryResultHandleList  {
                        set txHandleParent [stc::get $txHandle -parent]
                        set txHandleName [stc::get $txHandleParent -name]
                        if { $txHandleName == $StreamName } {
                            set streamId [stc::get $txHandle -StreamId]
                            set ::mainDefine::gCurrentTxSummaryPageNumber $currentPage
                            set ::mainDefine::gCachedTxSummaryStreamHandleList $TxStreamSummaryResultHandleList
                            break
                        }    
                    }
                
                    if {$streamId != "0" } {
                       break
                    }
 
                    incr currentPage
                }
            }   
        } else {
            set TxStreamSummaryResultHandleList [stc::get $TxStreamSummaryResultHandle -resulthandlelist]
            foreach txHandle $TxStreamSummaryResultHandleList  {
                set txHandleParent [stc::get $txHandle -parent]
                set txHandleName [stc::get $txHandleParent -name]
                if { $txHandleName == $StreamName } {
                    set streamId [stc::get $txHandle -StreamId]
                    break
                }    
            }
        }
    }

    set hPortGenerator [stc::get $srcPortHandle -children-generator]
    set hGeneratorStatus [stc::get $hPortGenerator -state]
    if {$hGeneratorStatus == "PENDING_STOP" } {
         set loop 0
         while {$hGeneratorStatus != "STOPPED" } {
             if {$loop == "20"} {
                 debugPut "Timeout to wait for the generator to be stopped"
                 return $StreamStatResult
             }

             set loop [expr $loop + 1]
             after 500
          
             debugPut "Waiting for the generator to be stopped" 
              set hGeneratorStatus [stc::get $hPortGenerator -state]
         }
    }

    set ::mainDefine::objectName $SrcPortName
    uplevel 1 {
          set ::mainDefine::result [$::mainDefine::objectName cget -m_streamStatisticRefershed ]
    }
    set streamStatisticRefershed $::mainDefine::result  

    if {$hGeneratorStatus == "STOPPED" && $streamStatisticRefershed == "FALSE" } {    
         set ::mainDefine::objectName $SrcPortName
        uplevel 1 {
            $::mainDefine::objectName configure -m_streamStatisticRefershed "TRUE" 
        }
   
        if {[catch {
            set errorCode [stc::perform RefreshResultView -ResultDataSet $TxStreamResultHandle  ]
        } err]} {
            return $errorCode
        }
        after 500
    
         if {[catch {
            set errorCode [stc::perform RefreshResultView -ResultDataSet $filteredStreamResults ]
        } err]} {
            return $errorCode
        }
        after 500
    }
    
    set tx_h ""
 
    set TotalPageCount [stc::get $TxStreamResultHandle -TotalPageCount]
    if {$TotalPageCount >1 } {
        set currentPage 1
        set tx_h ""
        while { $currentPage <= $TotalPageCount } {
             stc::config $TxStreamResultHandle -PageNumber $currentPage
             stc::apply         
             if {[catch {
                 if {$hGeneratorStatus == "STOPPED"} {
                     set errorCode [stc::perform RefreshResultView -ResultDataSet $TxStreamResultHandle  ]
                 }
             } err]} {
                return $errorCode
            }
            after 500
      
            set txHandleList [stc::get $TxStreamResultHandle -resulthandlelist]

            foreach txHandle $txHandleList {
                set txHandleParent [stc::get $txHandle -parent]
                set txHandleName [stc::get $txHandleParent -name]
                if { $txHandleName == $StreamName } {
                    set tx_h $txHandle
                    break
                }    
            }
 
            if {$tx_h != ""} {
                break
            }
              
            incr currentPage
        };# end while

        if {$tx_h == "" } {
            debugPut "can not find stream result oject in all result pages"                            
        }    
    } else {  
        set txHandleList [stc::get $TxStreamResultHandle -resulthandlelist]  
        foreach txHandle $txHandleList {
              set txHandleParent [stc::get $txHandle -parent]
              set txHandleName [stc::get $txHandleParent -name]
              if { $txHandleName == $StreamName } {
                  set tx_h $txHandle
                  break
              }    
        }
   }

   set txSummary_h ""
   if {$hGeneratorStatus != "STOPPED" } {     
       set TxStreamSummaryResultHandleList [stc::get $TxStreamSummaryResultHandle -resulthandlelist]
       foreach txHandle $TxStreamSummaryResultHandleList  {
           set txHandleParent [stc::get $txHandle -parent]
           set txHandleName [stc::get $txHandleParent -name]
           if { $txHandleName == $StreamName } {
               set txSummary_h $txHandle
               break
           }    
      }
   }
   
   if {$tx_h != "" } {               
       if {$txSummary_h != ""} {

           lappend StreamStatResult "-TxFrames"          
           lappend StreamStatResult "[stc::get $txSummary_h -FrameCount]" 
                        
           if {$SigFlag == 1} {
               lappend StreamStatResult "-TxSigFrames"
               lappend StreamStatResult "[stc::get $txSummary_h -FrameCount]"
           } else {
               lappend StreamStatResult "-TxSigFrames"
               lappend StreamStatResult 0
           }            
                            
           lappend StreamStatResult "-TxBytes"          
           lappend StreamStatResult "[stc::get $txSummary_h -OctetCount]"     
             
           if {$IPv4HeaderFlag == 1} {
               lappend StreamStatResult "-TxIPv4Frames"
               lappend StreamStatResult "[stc::get $txSummary_h -FrameCount]"
           } else {
               lappend StreamStatResult "-TxIPv4Frames"
               lappend StreamStatResult 0
           }

           lappend StreamStatResult "-TxRateBytes"          
           lappend StreamStatResult "[stc::get $txSummary_h -OctetRate]"  

           lappend StreamStatResult "-TxRateFrames"          
           lappend StreamStatResult "[stc::get $txSummary_h -FrameRate]"             
           
           lappend StreamStatResult "-TxL1BitCount"          
           lappend StreamStatResult "[stc::get $txSummary_h -L1BitCount]"
           
           lappend StreamStatResult "-TxL1BitRate"          
           lappend StreamStatResult "[stc::get $txSummary_h -L1BitRate]"          
       } else {

           lappend StreamStatResult "-TxFrames"          
           lappend StreamStatResult "[stc::get $tx_h -FrameCount]" 
                        
           if {$SigFlag == 1} {
               lappend StreamStatResult "-TxSigFrames"
               lappend StreamStatResult "[stc::get $tx_h -FrameCount]"
           } else {
               lappend StreamStatResult "-TxSigFrames"
               lappend StreamStatResult 0
           }            
                            
           lappend StreamStatResult "-TxBytes"          
           lappend StreamStatResult "[stc::get $tx_h -OctetCount]"     
             
           if {$IPv4HeaderFlag == 1} {
               lappend StreamStatResult "-TxIPv4Frames"
               lappend StreamStatResult "[stc::get $tx_h -FrameCount]"
           } else {
               lappend StreamStatResult "-TxIPv4Frames"
               lappend StreamStatResult 0
           }
  
           lappend StreamStatResult "-TxRateBytes"          
           lappend StreamStatResult 0

           lappend StreamStatResult "-TxRateFrames"          
           lappend StreamStatResult 0             
           
           lappend StreamStatResult "-TxL1BitCount"          
           lappend StreamStatResult "[stc::get $tx_h -L1BitCount]"

           lappend StreamStatResult "-TxL1BitRate"          
           lappend StreamStatResult 0         
       }       
    } else {
       lappend StreamStatResult "-TxFrames"          
       lappend StreamStatResult 0
                        
       lappend StreamStatResult "-TxSigFrames"
       lappend StreamStatResult 0            
                            
       lappend StreamStatResult "-TxBytes"          
       lappend StreamStatResult 0     
             
       lappend StreamStatResult "-TxIPv4Frames"
       lappend StreamStatResult 0
          
       lappend StreamStatResult "-TxRateBytes"          
       lappend StreamStatResult 0

       lappend StreamStatResult "-TxRateFrames"          
       lappend StreamStatResult 0             
       
       lappend StreamStatResult "-TxL1BitCount"          
       lappend StreamStatResult 0

       lappend StreamStatResult "-TxL1BitRate"          
       lappend StreamStatResult 0               
    }

    set resultFound 0
    set active [stc::get $StreamHandle  -Active]
    if {[string tolower $active] == "true"} {
       
         set resultFound 0
         set TotalPageCount [stc::get $filteredStreamResults -TotalPageCount]
         if {$TotalPageCount != 1} {
             for {set currentPage 1} {$currentPage <= $TotalPageCount && $streamId != 0 && $resultFound == 0} {incr currentPage} {
                 stc::config $filteredStreamResults -PageNumber  $currentPage
                 stc::apply

                 if {$hGeneratorStatus == "STOPPED"} {
                     stc::perform RefreshResultView -ResultDataSet $filteredStreamResults
                     after 2000
                 }
                 
                 set retAttr [AggregateFilteredStats $filteredStreamResults $streamId]               
                 if {$retAttr != ""} {
                     array set arr $retAttr
                     set resultFound 1           
                     break
                 }
             }  
         } else {  
             set retAttr [AggregateFilteredStats $filteredStreamResults $streamId]               
             if {$retAttr != ""} {
                 array set arr $retAttr
                 set resultFound 1           
             }            
         }
     }   
             
     if {$resultFound != 0} {
           lappend StreamStatResult "-RxFrames"                         
           lappend StreamStatResult $arr(-FrameCount)                      
        
           lappend StreamStatResult "-RxSigFrames"                    
           lappend StreamStatResult $arr(-SigFrameCount)          
      
           lappend StreamStatResult "-RxBytes"                    
           lappend StreamStatResult $arr(-OctetCount) 

           if {$IPv4HeaderFlag == 1} {
               lappend StreamStatResult "-RxIPv4Frames"
               lappend StreamStatResult $arr(-FrameCount)
           } else {
               lappend StreamStatResult "-RxIPv4Frames"
               lappend StreamStatResult 0
           }               
     
           lappend StreamStatResult "-RxAvgLatency"                                 
           lappend StreamStatResult $arr(-AvgLatency)

           lappend StreamStatResult "-RxAvgJitter"                    
           lappend StreamStatResult $arr(-AvgJitter)                                 
        
           lappend StreamStatResult "-CRCErrors"                        
           lappend StreamStatResult $arr(-FcsErrorFrameCount)           

           lappend StreamStatResult "-RxIPv4chesumError"                        
           lappend StreamStatResult $arr(-Ipv4ChecksumErrorCount)           
     
           lappend StreamStatResult "-RxDupelicated"                        
           lappend StreamStatResult $arr(-DuplicateFrameCount)           

           lappend StreamStatResult "-RxInSeq"                    
           lappend StreamStatResult $arr(-InSeqFrameCount)  
  
           lappend StreamStatResult "-RxOutSeq"                        
           lappend StreamStatResult $arr(-OutSeqFrameCount)
 
           lappend StreamStatResult "-RxDrop"                        
           lappend StreamStatResult $arr(-DroppedFrameCount)

           lappend StreamStatResult "-RxPrbsBytes"                        
           lappend StreamStatResult $arr(-PrbsFillOctetCount)  
                         
           lappend StreamStatResult "-RxPrbsBitErr"                        
           lappend StreamStatResult $arr(-PrbsBitErrorCount)  
        
           lappend StreamStatResult "-RxTcpUdpChecksumErr"                        
           lappend StreamStatResult $arr(-TcpUdpChecksumErrorCount) 
          
           lappend StreamStatResult "-RxRateBytes"               
           lappend StreamStatResult $arr(-OctetRate)

           lappend StreamStatResult "-RxRateFrames"                        
           lappend StreamStatResult $arr(-FrameRate) 
           
           lappend StreamStatResult "-RxL1BitCount"          
           lappend StreamStatResult $arr(-L1BitCount)

           lappend StreamStatResult "-RxL1BitRate"          
           lappend StreamStatResult $arr(-L1BitRate)
           
           lappend StreamStatResult "-FirstArrivalTime"          
           lappend StreamStatResult $arr(-FirstArrivalTime)
           
           lappend StreamStatResult "-LastArrivalTime"          
           lappend StreamStatResult $arr(-LastArrivalTime)
           
    } else {
           lappend StreamStatResult "-RxFrames"                         
           lappend StreamStatResult 0                      
        
           lappend StreamStatResult "-RxSigFrames"                    
           lappend StreamStatResult 0
      
           lappend StreamStatResult "-RxBytes"                    
           lappend StreamStatResult 0

           lappend StreamStatResult "-RxIPv4Frames"
           lappend StreamStatResult 0               
     
           lappend StreamStatResult "-RxAvgLatency"                                 
           lappend StreamStatResult 0                              

           lappend StreamStatResult "-RxAvgJitter"                    
           lappend StreamStatResult 0                                 
        
           lappend StreamStatResult "-CRCErrors"                        
           lappend StreamStatResult 0           

           lappend StreamStatResult "-RxIPv4chesumError"                        
           lappend StreamStatResult 0           
     
           lappend StreamStatResult "-RxDupelicated"                        
           lappend StreamStatResult 0           

           lappend StreamStatResult "-RxInSeq"                    
           lappend StreamStatResult 0  
  
           lappend StreamStatResult "-RxOutSeq"                        
           lappend StreamStatResult 0           
 
           lappend StreamStatResult "-RxDrop"                        
           lappend StreamStatResult 0    

           lappend StreamStatResult "-RxPrbsBytes"                        
           lappend StreamStatResult 0  
                         
           lappend StreamStatResult "-RxPrbsBitErr"                        
           lappend StreamStatResult 0  
        
           lappend StreamStatResult "-RxTcpUdpChecksumErr"                        
           lappend StreamStatResult 0      

          lappend StreamStatResult "-RxRateBytes"               
          lappend StreamStatResult 0   

          lappend StreamStatResult "-RxRateFrames"               
          lappend StreamStatResult 0   
          
           lappend StreamStatResult "-RxL1BitCount"          
           lappend StreamStatResult 0

           lappend StreamStatResult "-RxL1BitRate"          
           lappend StreamStatResult 0
           
           lappend StreamStatResult "-FirstArrivalTime"          
           lappend StreamStatResult 0
           
           lappend StreamStatResult "-LastArrivalTime"          
           lappend StreamStatResult 0
    }
        
    return $StreamStatResult
}

############################################################################
#APIName: CleanPortStats
#
#Description: Clean the port statistics, mainly for debug
#
#Input: 
#
#Output:    None
#
#############################################################################
::itcl::body StatisticEngine::CleanPortStats {args} {
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result

    stc::perform ResultsClearAll -PortList $PortHandle
    stc::perform ResultsClearAllProtocol
    
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: SetWorkingMode
#
#Description: set stream statistics mode
#
#Input:  -PortStreamLevel PortStreamLevel, when setting to TRUE，get port stream filtered result，
#                         when setting to FALSE, get global stream statistics result                           
#
#Output:    None
#
#############################################################################
::itcl::body StatisticEngine::SetWorkingMode {args} {

     #Convert attribute of input parameters to lower case
     set args [ConvertAttrToLowerCase $args] 

     #Parse PortStreamLevel parameter
     set index [lsearch $args -portstreamlevel] 
     if {$index != -1} {
         set PortStreamLevel [lindex $args [expr $index + 1]]
     } else  {
         set PortStreamLevel "TRUE"
     }  
     
      set m_portStreamLevel $PortStreamLevel
   
      return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetHighResolutionSampleStats    
#
#Description: Get packet content according to packet index
#
#Input: 
#              (1) -PacketIndex required, packet index
#              (2) -PacketContent optional，variable to store the obtained packet content
#
#Output: 0 success
#
#############################################################################
::itcl::body StatisticEngine::GetHighResolutionSampleStats {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "Enter the proc of TestAnalysis::GetHighResolutionSampleStats"
    
    #Get port statitics
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result 


    set ::mainDefine::objectName $stream 
    uplevel 1 {
         set ::mainDefine::result [$::mainDefine::objectName cget -m_highResolutionPortConfig]
    }
    set highResolutionPortConfig $::mainDefine::result
    #update data to get the highresolutionresult
    set attribute [stc::get $highResolutionPortConfig -TriggerStat]
    stc::perform GetHighResolutionSamplingResultCommand -configType HighResolutionSamplingPortConfig -HandleList $highResolutionPortConfig -ViewAttribute $attribute
    #get the result handle
    set resultHandle [stc::get $highResolutionPortConfig -children-result]
    if {$resultHandle == ""} {
        #if no result
        set valueList [list]
        set timeList [list]
    } else {
        #if results exists
        set valueList [stc::get $resultHandle -ValueList]
        set timeList [stc::get $resultHandle -TimeList]
    }
    
    debugPut "Exit the proc of TestAnalysis::GetHighResolutionSampleStats"
    return [list $valueList $timeList]
}

############################################################################
#APIName: GetHighResolutionStreamBlockSampleStats    
#
#Description: Get packet content according to packet index
#
#Input: 
#              (1) -PacketIndex required, packet index
#              (2) -PacketContent optional，variable to store the obtained packet content
#
#Output: 0 success
#
#############################################################################
::itcl::body StatisticEngine::GetHighResolutionStreamBlockSampleStats {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "Enter the proc of TestAnalysis::GetHighResolutionStreamBlockSampleStats"
	
	set StreamName ""
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the StreamName"
    }
    
    #Get port statitics
    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result  

    #set ::mainDefine::objectName $StreamName
	set ::mainDefine::objectName $m_portName 
    uplevel 1 {
         set ::mainDefine::result [$::mainDefine::objectName cget -m_highResolutionStreamBlockConfig]
    }
    set highResolutionStreamBlockConfig $::mainDefine::result
    #update data to get the highresolutionresult
    set attribute [stc::get $highResolutionStreamBlockConfig -TriggerStat]
    stc::perform GetHighResolutionSamplingResultCommand -configType HighResolutionSamplingStreamBlockConfig -HandleList $highResolutionStreamBlockConfig -ViewAttribute $attribute
    #get the result handle
    set resultHandle [stc::get $highResolutionStreamBlockConfig -children-result]
    if {$resultHandle == ""} {
        #if no result
        set valueList [list]
        set timeList [list]
    } else {
        #if results exists
        set valueList [stc::get $resultHandle -ValueList]
        set timeList [stc::get $resultHandle -TimeList]
    }
    
    debugPut "Exit the proc of TestAnalysis::GetHighResolutionStreamBlockSampleStats"
    return [list $valueList $timeList]
}



##########################################
#Definition of TestStatistic
##########################################   
::itcl::class TestStatistic {
 
    #Constructor
    inherit StatisticEngine
    constructor { portName chassisName} { StatisticEngine::constructor $portName $chassisName} {
        
    }

    #Destructor
    destructor {
   # set index [lsearch $::mainDefine::gObjectNameList $this]
    #set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
}

##########################################
#Definition of TestAnalysis class
##########################################   
::itcl::class TestAnalysis {

    #Variables
    variable m_captureFileName ""
    variable m_StartCaptureState "IDLE"
    variable m_captureHandle ""
    variable m_captureConfigArgs ""
    variable m_CaptureConfigState "IDLE" 
    variable m_PortHandle ""
    variable m_FilterConfigList ""
    variable m_FilterNameList ""

    #Constructor
    inherit StatisticEngine
    constructor { portName chassisName} { StatisticEngine::constructor $portName $chassisName} {
            
    }

    #Destructor
    destructor {
    }
    
    #Methods
    public method StartCapture
    public method StopCapture
    public method ConfigCaptureMode
    public method GetCapturePacket   

    #Methods internal use only
    public method RealStartCapture
    public method RealConfigCaptureMode
}

############################################################################
#APIName: StartCapture
#
#Description: Start the capture functionality
#
#Input: 
#
#
#Output: return 0 for success, otherwise return error
#
#############################################################################
::itcl::body TestAnalysis::StartCapture {args} {
    
    debugPut "Enter the proc of TestAnalysis::StartCapture"

    set ::mainDefine::objectName $m_portName 
    uplevel 1 {
         set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set PortHandle $::mainDefine::result
  
    set captureHandle [stc::get $PortHandle -children-capture ]
    set m_captureHandle $captureHandle
    set m_StartCaptureState "PENDING"

    if {$::mainDefine::gGeneratorStarted == "TRUE"} {
         RealConfigCaptureMode
         RealStartCapture
    }  

    debugPut "Exit the proc of TestAnalysis::StartCapture"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RealStartCapture
#
#Description: Real start capture functioinality
#
#Input: 
#
#
#Output: return 0 for success, otherwise return error
#
#############################################################################
::itcl::body TestAnalysis::RealStartCapture {args} {
    if {$m_StartCaptureState == "PENDING"} {
          set errorCode 1
 
          if {[catch {
               set errorCode [stc::perform CaptureStart -captureProxyId $m_captureHandle -ExecuteSynchronous TRUE ]
          } err]} {
               return $errorCode
          }
          
         debugPut "The capture functionality of port ($m_portName) is in RUNNING state "
          
          set m_StartCaptureState "RUNNING"
     }

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopCapture
#
#Description: Stop capture functionality
#
#Input: 
#
#
#Output: return 0 for success, otherwise return error
#
#############################################################################
::itcl::body TestAnalysis::StopCapture {args} {
    
    debugPut "Enter the proc of TestAnalysis::StopCapture"

    #Check whether or not the capture file already exists
    if { [file exists $m_captureFileName] } {
        file delete $m_captureFileName
    }
    
    if {$m_StartCaptureState == "RUNNING"} {
         #Wait 1 second
         set waitTime 1000
         after $waitTime
    
         set errorCode 1
         if {[catch {
              set errorCode [stc::perform CaptureStop -captureProxyId $m_captureHandle]
         } err]} {
              return $errorCode
         }

         if {[catch {
             set errorCode [stc::perform CaptureDataSave -captureProxyId $m_captureHandle -fileName $m_captureFileName -ExecuteSynchronous TRUE ]
         } err]} {
             return $errorCode
         }
        
         set m_StartCaptureState "IDLE"
     } else {
          puts "You should start the capture first before running the StopCapture ..."
     }  

    debugPut "Exit the proc of TestAnalysis::StopCapture"
    return $::mainDefine::gSuccess
}

#################################################################################
#functionality: Configure the parameters of capture offset filter
#Input: filterexpression and capture handle
#Output: success
#################################################################################
proc myConfigCaptureOffsetFilter {filtervalue captureHandle} {

    set filtNum [llength $filtervalue]
    for {set i 0} {$i < $filtNum} {incr i} {    
        set filtHdrArr($i) [lindex $filtervalue $i]
        set filtHdrArr($i) [string tolower $filtHdrArr($i)]
        set index [lsearch $filtHdrArr($i) -pattern]
		#puts "filtHdrArr($i) == $filtHdrArr($i)"
        if { $index !=-1} {
            set pattern [lindex $filtHdrArr($i) [expr $index+1]]
        } else {
            error "please specify -pattern of OFFSET filter"
        } 
        #puts "pattern:$pattern"
        set index [lsearch $filtHdrArr($i) -offset ]
        if { $index !=-1} {
            set offset [lindex $filtHdrArr($i) [expr $index+1]]
        } else {
            set offset 0
        }
		#Added by Yong @2013.8.13
		set index [lsearch $filtHdrArr($i) -condition ]
        if { $index !=-1} {
            set condition [lindex $filtHdrArr($i) [expr $index+1]]
        } else {
            set condition "TRUE"
        }
		
                
        set index [lsearch $filtHdrArr($i) -mode ]
        if { $index !=-1} {
            set mode [lindex $filtHdrArr($i) [expr $index+1]]
        } else {
            set mode "AND"
        }
        set Mode($i) $mode
        
		set find_index [string first "0x" $pattern]
        if {$find_index != -1} {
           set tmpPattern [string map {0x ""} $pattern]
        } else {
		   set tmpPattern $pattern 
		}		
        #set tmpPattern [ConvertHexFormat $pattern] 
		#puts "tmpPattern:$tmpPattern"
        set Pattern($i) $tmpPattern
        
        set patternLength [expr [string length $tmpPattern] / 2]
        set patternList ""
        set maskList ""
        for {set index 0} {$index < $patternLength} {incr index} {
              set first [expr $index * 2]
              set last [expr $first + 1]
              set hexPattern [string range $tmpPattern $first $last]
              set decPattern [format "%u" "0x$hexPattern"]
			  #puts "patternList:$patternList"
              lappend patternList $decPattern
              lappend maskList "255"
        } 
        
        set CaptureFilter [lindex [stc::get $captureHandle -children-CaptureFilter] 0]
        if {$CaptureFilter == ""} {
			
            set CaptureFilter [stc::create CaptureFilter -under $captureHanlde]
			puts "create CaptureFilter $CaptureFilter"
        }
         
        # set CaptureAnalyzerFilter($i) [stc::create "CaptureAnalyzerFilter" \
            # -under $CaptureFilter \
            # -IsSelected "TRUE" \
            # -FilterDescription "FilterName_$i" \
            # -Offset $offset \
            # -Value $patternList \
            # -Mask $maskList \
            # -FrameConfig {<frame><config><pdus></pdus></config></frame>} ]
			
		if {[string tolower $condition] == "true"} {
			 set CaptureAnalyzerFilter($i) [stc::create "CaptureAnalyzerFilter" \
				-under $CaptureFilter \
				-IsSelected "TRUE" \
				-RelationToNextFilter $Mode($i) \
				-FilterDescription "FilterName_$i" \
				-Offset $offset \
				-Value $patternList \
				-Mask $maskList \
				-FrameConfig {<frame><config><pdus></pdus></config></frame>} ]
		
		} else {
			set CaptureAnalyzerFilter($i) [stc::create "CaptureAnalyzerFilter" \
				-under $CaptureFilter \
				-IsSelected "TRUE" \
				-IsNotSelected "TRUE" \
				-RelationToNextFilter $Mode($i) \
				-FilterDescription "FilterName_$i" \
				-Offset $offset \
				-Value $patternList \
				-Mask $maskList \
				-FrameConfig {<frame><config><pdus></pdus></config></frame>} ]
		}	
    }
    
    stc::config $captureHandle \
        -CurrentFiltersUsed $filtNum \
        -CurrentFilterBytesUsed [expr $filtNum * 4]   
   
    set CaptureFilter [lindex [stc::get $captureHandle -children-CaptureFilter] 0]
    if {$CaptureFilter == ""} {
        set CaptureFilter [stc::create CaptureFilter -under $captureHanlde]
    }
   
    set expresseionList ""
    for {set i 0} {$i < $filtNum} {incr i} {
        append expressionList "(FilterName_$i==$Pattern($i))"
                
        if {$i != [expr $filtNum - 1]} {
            if {[string tolower $Mode($i)] == "and" } {
                append  expressionList "AND"
            } else {
                append  expressionList "OR"
            }   
        }
    }
             
    set ByteExpression "{Pattern$expressionList}"
      
    stc::config $CaptureFilter \
        -FilterExpression $ByteExpression    
                
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: RealConfigCaptureMode
#
#Description: Config the capture mode, called by ConfigCaptureMode
#
#Input: 1. args:argument list，including
#              (1) -FilterName optional,Filter name
#              (2) -CaptureFile optionial,specify the capture file name       
#
#Output: None
#
#############################################################################
::itcl::body TestAnalysis::RealConfigCaptureMode {args} {

    if {$m_CaptureConfigState == "PENDING" } {
    
    set args $m_captureConfigArgs
    set m_CaptureConfigState "RUNNING"
     
    set PortHandle $m_PortHandle
    set FilterConfigList $m_FilterConfigList
    set FilterNameList $m_FilterNameList
    
    #Parse filter name
    set index [lsearch $args -filtername] 
    if {$index != -1} {
        set CaptureAllPkt FALSE
        set FilterName [lindex $args [expr $index + 1]]
        set index [lsearch $FilterNameList $FilterName] 
        if {$index == -1} {
            puts "Specified filtername is not existed, existing filters are: $FilterNameList"
            return $::mainDefine::gFail
        }    
        
       #Fetch capture filter configuration
       set index [lsearch $FilterConfigList $FilterName] 
       if {$index != -1} {
           set filtername [lindex $FilterConfigList $index]
           set filtertype [lindex $FilterConfigList [expr $index+1]]
           set filtertype [string tolower $filtertype]                       
           set filtervalue [lindex $FilterConfigList [expr $index+2]]        
       } 
                    
    } else {
        set CaptureAllPkt TRUE
    }

    #To ensure Capture Filter can be used separately. You should use FilterType and FilterValue simultanously
    set index [lsearch $args -filtertype] 
    if {$index != -1} {
        set CaptureAllPkt FALSE
        set filtertype [lindex $args [expr $index + 1]]
        set filtertype [string tolower $filtertype]
    } 

    set index [lsearch $args -filtervalue] 
    if {$index != -1} {
        set CaptureAllPkt FALSE
        set filtervalue [lindex $args [expr $index + 1]]
        set filtervalue [string tolower $filtervalue]
    }
      
    #Parse CaptureFilr parameter
    set index [lsearch $args -capturefile] 
    if {$index != -1} {
        set CaptureFileName [lindex $args [expr $index + 1]]
    } else  {
        set CaptureFileName "c:/$PortHandle.pcap"        
    }
    
    set m_captureFileName $CaptureFileName

    set captureHandle [stc::get $PortHandle -children-Capture] 
    set captureFilterHandle [stc::get $captureHandle -children-CaptureFilter]
    set captureAnalyzerHandle [stc::get $captureFilterHandle -children]
    
    #Create capture filter, if capture file exists, then delete it first    
    if {$captureAnalyzerHandle != ""} {
        foreach sr $captureAnalyzerHandle {
            stc::delete $sr
        }
    }    
    
    if {$CaptureAllPkt != "TRUE"} {
 
     if {$filtertype == "stack"} {

        set filtNum [llength $filtervalue]
        set maxDepth 0
        set maxDepthIndex 0

        set frameConfig ""
        
        for {set i 0} {$i < $filtNum} {incr i} {
        
            set filtHdrArr($i) [lindex $filtervalue $i]
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
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        <srcMac>$min</srcMac></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\">\
                        </pdu></pdus></config></frame>"  
                }
                    
                eth.dstmac {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        <dstMac>$min</dstMac></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu>\
                        </pdus></config></frame>"
                }
                
                ipv4.srcip {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><sourceAddr>$min</sourceAddr>\
                        </pdu></pdus></config></frame>"  
                }
                
                ipv4.dstip {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><destAddr>$min</destAddr>\
                        </pdu></pdus></config></frame>"
                }
              
                ipv4.pro {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>$min</protocol>\
                        </pdu></pdus></config></frame>"  
                }

               any.srcport {
                    puts "Not support in this version"
                }

                any.dstport {
                    puts "Not support in this version"
                }

                vlan.pri {
                    set binUserPriority [dec2bin $min 2 3]
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        <vlans><Vlan name=\"Vlan\"><pri>$binUserPriority</pri></Vlan></vlans></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\">\
                        </pdu></pdus></config></frame>"
                }
                
                vlan.id {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                        <vlans><Vlan name=\"Vlan\"><id>$min</id></Vlan></vlans></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\">\
                        </pdu></pdus></config></frame>"
                }                

                tcp.srcport {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                         </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Tcp_1\" pdu=\"tcp:Tcp\">\
                         <sourcePort>$min</sourcePort></pdu></pdus></config></frame>"
                }
                tcp.dstport {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                         </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Tcp_1\" pdu=\"tcp:Tcp\">\
                         <destPort>$min</destPort></pdu></pdus></config></frame>"  
                }

                udp.srcport {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                         </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Udp_1\" pdu=\"udp:Udp\">\
                         <sourcePort>$min</sourcePort></pdu></pdus></config></frame>"
                }
                
                udp.dstport {
                    set frameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                         </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Udp_1\" pdu=\"udp:Udp\">\
                         <destPort>$min</destPort></pdu></pdus></config></frame>"  
                }
                default {
                    puts "Specified Stack is invalid"
                }                      
            } 
            
            set hCaptureAnalyzerFilter [stc::create "CaptureAnalyzerFilter" \
                -under $captureFilterHandle \
                -IsSelected "TRUE" \
                -IsNotSelected "FALSE" \
                -RelationToNextFilter "AND" \
                -ValueToBeMatched $min \
                -FrameConfig $frameConfig ]
            
			### Added by Jaimin 2013-06-24  Begin ############
            switch $lastProtocolField {
                vlan.pri {
                    set binUserPriority [dec2bin $min 2 3]
					stc::config $hCaptureAnalyzerFilter -FilterDescription {Vlan:Priority} \
					    -ValueToBeMatched $binUserPriority					
                }
				eth.dstmac {
				    stc::config $hCaptureAnalyzerFilter -FilterDescription {EthernetII:Destination MAC}
				}
				tcp.srcport {
					set iPattern "Pattern(IPv4 Header:Protocol==6)AND(TCP Header:Source port==$min)"
					stc::config $captureFilterHandle -FilterExpression $iPattern 
					stc::config $hCaptureAnalyzerFilter -FilterDescription {TCP Header:Source port} 					
					set hCaptureAnalyzerFilter2 [stc::create "CaptureAnalyzerFilter" \
						-under $captureFilterHandle \
						-IsSelected "TRUE" \
						-IsNotSelected "FALSE" \
						-RelationToNextFilter "AND" \
						-ValueToBeMatched 6]
					set frameconfig2 "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\"></pdu>\
								<pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>6</protocol></pdu>\
								<pdu name=\"Tcp_1\" pdu=\"tcp:Tcp\"></pdu></pdus></config></frame>"
					stc::config $hCaptureAnalyzerFilter2 -FilterDescription {IPv4 Header:Protocol} -FrameConfig $frameconfig2
					
				}
				tcp.dstport {
					set iPattern "Pattern(IPv4 Header:Protocol==6)AND(TCP Header:Destination port==$min)"
					stc::config $captureFilterHandle -FilterExpression $iPattern 
					stc::config $hCaptureAnalyzerFilter -FilterDescription {TCP Header:Destination port} 					
					set hCaptureAnalyzerFilter2 [stc::create "CaptureAnalyzerFilter" \
						-under $captureFilterHandle \
						-IsSelected "TRUE" \
						-IsNotSelected "FALSE" \
						-RelationToNextFilter "AND" \
						-ValueToBeMatched 6]
					set frameconfig2 "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\"></pdu>\
								<pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>6</protocol></pdu>\
								<pdu name=\"Tcp_1\" pdu=\"tcp:Tcp\"></pdu></pdus></config></frame>"
					stc::config $hCaptureAnalyzerFilter2 -FilterDescription {IPv4 Header:Protocol} -FrameConfig $frameconfig2
				}
				udp.srcport {
					set iPattern "Pattern(IPv4 Header:Protocol==17)AND((UDP Header:Source port==$min)"
					stc::config $captureFilterHandle -FilterExpression $iPattern 
					stc::config $hCaptureAnalyzerFilter -FilterDescription {UDP Header:Source port}
					set hCaptureAnalyzerFilter2 [stc::create "CaptureAnalyzerFilter" \
						-under $captureFilterHandle \
						-IsSelected "TRUE" \
						-IsNotSelected "FALSE" \
						-RelationToNextFilter "AND" \
						-ValueToBeMatched 17]
					set frameconfig2 "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\"></pdu>\
								<pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>17</protocol></pdu>\
								<pdu name=\"Udp_1\" pdu=\"udp:Udp\"></pdu></pdus></config></frame>"
					stc::config $hCaptureAnalyzerFilter2 -FilterDescription {IPv4 Header:Protocol} -FrameConfig $frameconfig2
				}
				udp.dstport {
					set iPattern "Pattern(IPv4 Header:Protocol==17)AND(UDP Header:Destination port==$min)"
					stc::config $captureFilterHandle -FilterExpression $iPattern 
					stc::config $hCaptureAnalyzerFilter -FilterDescription {UDP Header:Destination port}
					set hCaptureAnalyzerFilter2 [stc::create "CaptureAnalyzerFilter" \
						-under $captureFilterHandle \
						-IsSelected "TRUE" \
						-IsNotSelected "FALSE" \
						-RelationToNextFilter "AND" \
						-ValueToBeMatched 17]
					set frameconfig2 "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\"></pdu>\
								<pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>17</protocol></pdu>\
								<pdu name=\"Udp_1\" pdu=\"udp:Udp\"></pdu></pdus></config></frame>"
					stc::config $hCaptureAnalyzerFilter2 -FilterDescription {IPv4 Header:Protocol} -FrameConfig $frameconfig2
				}
            }
            ### Added by Jaimin 2013-06-24  End ############			
                                         
        } ;# end for 

    } elseif { $filtertype == "udf"} {
        error "UDF type is not supported in Capture mode,please use stack or offset type."
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

            set index [lsearch $filtHdrArr($i) -offset ]
            if { $index !=-1} {
                set offset [lindex $filtHdrArr($i) [expr $index+1]]
            } else {
                set offset 0
           }
        
           set FrameConfig ""
           switch $offset {
               0 { 
                   #pattern_mode DMAC
                   set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                       <dstMac>$pattern</dstMac></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu>\
                       </pdus></config></frame>"
               }
              6 {
                  #pattern_mode SMAC
                  set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                       <srcMac>$pattern</srcMac></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\">\
                       </pdu></pdus></config></frame>"           
              }
              12 {
                  #pattern_mode ETH_TYPE
                   set pattern [format "%x" $pattern]
                   set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                      <etherType>$pattern</etherType></pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\">\
                      </pdu></pdus></config></frame>"                         
             }
             23 {
                 #pattern_mode IP_PROTOCOL
                 set pattern [format "%x" $pattern]
                 set pattern [myHex2Dec_stc 0x$pattern]
                 set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                      </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><protocol>$pattern</protocol>\
                      </pdu></pdus></config></frame>"            
            }
            26 {
                #pattern_mode SIP 
                set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                    </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><sourceAddr>$pattern</sourceAddr>\
                    </pdu></pdus></config></frame>"            
            }
            30 {
                #pattern_mode DIP
                set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                    </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"><destAddr>$pattern</destAddr>\
                    </pdu></pdus></config></frame>"            
            }
            34 {
                #pattern_mode SPORT
                set pattern [GetTrigString $pattern]
                set pattern [myHex2Dec_stc 0x$pattern]
                set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                     </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Udp_1\" pdu=\"udp:Udp\">\
                     <sourcePort>$pattern</sourcePort></pdu></pdus></config></frame>"
            }
            36 {
                #pattern_mode DPORT
                set pattern [GetTrigString $pattern]
                set pattern [myHex2Dec_stc 0x$pattern]
                set FrameConfig "<frame><config><pdus><pdu name=\"eth1\" pdu=\"ethernet:EthernetII\">\
                     </pdu><pdu name=\"ip_1\" pdu=\"ipv4:IPv4\"></pdu><pdu name=\"Udp_1\" pdu=\"udp:Udp\">\
                     <destPort>$pattern</destPort></pdu></pdus></config></frame>"            
            }
            default {
                puts "Invalid offset for capture trigger, it should be integer as {0:DMAC 6:SMAC 12:ETH_TYPE 23:IP_PROTOCOL 26:SIP 30-DIP 34:SPORT 36:DPORT} "
            }
        }  
        
        if {$FrameConfig != ""} {
              set hCaptureAnalyzerFilter [stc::create "CaptureAnalyzerFilter" \
                   -under $captureFilterHandle \
                   -IsSelected "TRUE" \
                   -IsNotSelected "FALSE" \
                   -RelationToNextFilter "AND" \
                   -ValueToBeMatched $pattern \
                   -FrameConfig $FrameConfig ]
             }                                                
          }
     }
     #Apply configuration to the chassis  
     if {$CaptureAllPkt != "TRUE"} {
         if {$filtertype == "offset"} {
             myConfigCaptureOffsetFilter $filtervalue $captureHandle
         }
     }         
     
     if { [catch {
         stc::apply 
     } err]} {
         set ::mainDefine::gChassisObjectHandle $m_chassisName 

         garbageCollect
         error "Apply config failed when calling RealConfigCaptureMode, the error message is:$err" 
     }

    } ;# end if
    } ;#End check the PENDING state
        
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigCaptureMode
#
#Description: Config capture parameters
#
#Input: 1. args:argument list，including
#              (1) -FilterName optional,Filter name
#              (2) -CaptureFile optional,specify capture file name
#
#Output: None
#
#############################################################################
::itcl::body TestAnalysis::ConfigCaptureMode {args} {

    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args] 
 
    debugPut "Enter the proc of TestAnalysis::ConfigCaptureMode"
    
    if {$m_captureConfigArgs != $args} {
         set ::mainDefine::objectName $m_portName 
         uplevel 1 {
             set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
         }
         set PortHandle $::mainDefine::result  
    
         set ::mainDefine::objectName $m_portName     
         uplevel 1 {
               set ::mainDefine::result [$::mainDefine::objectName cget -m_filterConfigList]
         }
         set FilterConfigList $::mainDefine::result   

         set ::mainDefine::objectName $m_portName     
         uplevel 1 {
               set ::mainDefine::result [$::mainDefine::objectName cget -m_filterNameList]
         }
         set FilterNameList $::mainDefine::result       

         set m_PortHandle $PortHandle
         set m_FilterConfigList $FilterConfigList
         set m_FilterNameList $FilterNameList
    
         set m_CaptureConfigState "PENDING"
         set m_captureConfigArgs $args     
    }   
    
    debugPut "Exit the proc of TestAnalysis::ConfigCaptureMode"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: GetCapturePacket    
#
#Description: Get packet content according to packet index
#
#Input: 
#              (1) -PacketIndex required, packet index
#              (2) -PacketContent optional，variable to store the obtained packet content
#
#Output: 0 success
#
#############################################################################
::itcl::body TestAnalysis::GetCapturePacket {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "Enter the proc of TestAnalysis::GetCapturePacket"
    
    #Parse packetindex parameter
    set index [lsearch $args -packetindex] 
    if {$index != -1} {
        set PacketIndex [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the PacketIndex"
    }   
 
    set temp [stc::perform CaptureGetFrame -captureProxyId $m_captureHandle -FrameIndex $PacketIndex -ExecuteSynchronous TRUE]
    set index [lsearch $temp -PacketData]
    if {$index != -1} {
        set pktData [lindex $temp [expr $index + 1]]
        set index [lsearch $temp -DataLength]
        set dataLength [lindex $temp [expr $index + 1]]
        set index [lsearch $temp -PreambleLength]
        set preambleLength [lindex $temp [expr $index + 1]]
        set pktData [string range $pktData [expr $preambleLength * 2] [expr $dataLength * 2]]   
    } else {
        set pktData ""
    }
   
    set index [lsearch $args -packetcontent] 
    if {$index != -1} {
        set PacketContent [lindex $args [expr $index + 1]]
        set ::mainDefine::gVar $PacketContent
        set ::mainDefine::gPktContent $pktData

        uplevel 1 {
             set $::mainDefine::gVar $::mainDefine::gPktContent
        }
    }
     
    #Deal with PacketHandle
    set index [lsearch $args -packethandle] 
    if {$index != -1} {
        set PacketHandle [lindex $args [expr $index + 1]]

        PacketBuilder packet1
        packet1 CreateCustomPkt -HexString $pktData -PduName $PacketHandle 

        set ::mainDefine::gAutoDestroyPdu "FALSE"
        catch {itcl::delete object packet1}
        set ::mainDefine::gAutoDestroyPdu "TRUE"
    }

    debugPut "Exit the proc of TestAnalysis::GetCapturePacket"
    return $::mainDefine::gSuccess     
}
