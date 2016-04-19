###########################################################################
#                                                                        
#  FileName£ºpkgIndex.tcl                                                                                              
# 
#  Description£ºmain file of HLAPI, and used to reference all the files                                            
# 
#  Creator£º David.Wu
#
#  Time:  2007.3.2
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################
if {[info exists _SPIRENT_TESTCENTER_CAPI_] == 0} then {

set _SPIRENT_TESTCENTER_CAPI_ 1
package provide SptCAPI 4.00
if {![info exists gSTCVersion]} {
    set gSTCVersion 4.00
}
#Load itcl package
package require Itcl

#Name space to define the variables of this HLAPI
namespace eval mainDefine {
    #Define the return value for success
    set gSuccess 0

    #Define the return value for failure
    set gFail 1   
    
    #Variable for debug
    set gDebug 0

    #Define the output destination  
    set gOutputDst "file"

    #Default log file name
    set gLogFile "./log.txt"

    set gErrMsg ""

    set gErrCode 1

    set gGeneratorStarted "TRUE"
    
    set gEnableStream TRUE

    set gApplyConfig 0
 
    set gResultCleared 0

    set gPortLevelStream "TRUE"
    
    set gTrafficProfileContent(profile0) ""
    
    set gTrafficProfileList "" 
    set gChassisObjectHandle ""
    set gBoundStreamDstPort(stream0) ""
    set gHostHandle(unknown) ""
    set gStreamSrcPort(stream0) ""
    set gIpv4NetworkBlock(vpnname0) ""
    set gIpv6NetworkBlock(vpnname0) ""

    #Define the array to reference the object in stream bounding
    set gPoolCfgBlock(poolname0) ""

    #Whether or not have stream bouding, default is false
    set gStreamBindingFlag "FALSE"

    #Variables associated with OSPF
    set rsvpRouterCreated 0
    set ospfv2RouterCreated 0

    #Variables associated with the cache mechanism when having multiple pages for stream result
    set gCurrentRxPageNumber "0"
    set gCurrentTxPageNumber "0"
    set gCachedRxStreamHandleList ""
    set gCachedTxStreamHandleList ""

    set gCurrentRxSummaryPageNumber "0"
    set gCurrentTxSummaryPageNumber "0"
    set gCachedRxSummaryStreamHandleList ""
    set gCachedTxSummaryStreamHandleList ""

    set gCurrentRxFilteredPageNumber "0"
    set gCachedRxFilteredStreamHandleList ""

    #Whether or not delete PDU objects in PacketBuilder and HeaderCreator objects automatically
    set gAutoDestroyPdu "TRUE"

    #Whether or not check the link state in StartTraffic/StopTraffic
    set gAutoCheckLinkState "TRUE"

    #stream block schedule mode
    set gStreamScheduleMode "RATE_BASED"
    set gPortScheduleMode(port0) "RATE_BASED"
    
	set routerNum 0
    set gVpnSiteList(vpnname0) ""
    #Spirent TestCenter version
    #set gSTCVersion 4.00
 }

##########################################################################
#          ADD BY SHI JUNHUA 2008.11.24 SPIRENT COR
##########################################################################
if [catch {
    package require registry
    if [catch {
        set stcDir [registry get [subst {HKEY_LOCAL_MACHINE\\SOFTWARE\\Spirent Communications\\Spirent TestCenter\\$gSTCVersion}] TARGETDIR]
        set Title [registry get [subst {HKEY_LOCAL_MACHINE\\SOFTWARE\\Spirent Communications\\Spirent TestCenter\\$gSTCVersion\\Components\\Spirent TestCenter Application}] Title]
        set ::mainDefine::gSTCVersion "$gSTCVersion"
        } errMsg ] {
        if {[catch {
            set stcDir [registry get {HKEY_LOCAL_MACHINE\SOFTWARE\Spirent Communications\Spirent TestCenter\4.00} TARGETDIR]
            set Title [registry get {HKEY_LOCAL_MACHINE\SOFTWARE\Spirent Communications\Spirent TestCenter\4.00\Components\Spirent TestCenter Application} Title]
            set ::mainDefine::gSTCVersion "4.00"
            } err]} {
            set stcDir [registry get {HKEY_LOCAL_MACHINE\SOFTWARE\Spirent Communications\Spirent TestCenter\3.60} TARGETDIR]
            set Title [registry get {HKEY_LOCAL_MACHINE\SOFTWARE\Spirent Communications\Spirent TestCenter\3.60\Components\Spirent TestCenter Application} Title]
            set ::mainDefine::gSTCVersion "3.60"
        }
    }
    source $stcDir/$Title/SpirentTestCenter.tcl
} errMsg ] {
    puts "Loading SpirentTestCenter Package failed : $errMsg\nPlease ensure SpirentTestCenter 3.60 is installed on this PC"
    return -1
}
##########################################################################

#Loading Spirent TestCenter packages
package require SpirentTestCenter

############################################################################
#ProcName: ArrayPut
#
#Description: Print all the variables in the array
#
#Input: 1. arg:Name of the array
#
#Output: None
#
#Coded by: David.Wu
############################################################################
proc ArrayPut {arg} {

    if {[string tolower $::mainDefine::gOutputDst ] == "file" } {
    
       set fileId [open $::mainDefine::gLogFile "a"]
       foreach name [array names ::$arg] {
             puts $fileId "[subst $arg]([subst $name]) =  [subst $[subst ::[subst $arg]($name)]]"
       }
       close $fileId
        
    } elseif {[string tolower $::mainDefine::gOutputDst] == "both" } {
    
       set fileId [open $::mainDefine::gLogFile "a"]
       foreach name [array names ::$arg] {
             puts $fileId "[subst $arg]([subst $name]) =  [subst $[subst ::[subst $arg]($name)]]"
             puts "[subst $arg]([subst $name]) =  [subst $[subst ::[subst $arg]($name)]]"
       }
       close $fileId
        
    } elseif {[string tolower $::mainDefine::gOutputDst] == "stdout" } {

       foreach name [array names ::$arg] {             
             puts "[subst $arg]([subst $name]) =  [subst $[subst ::[subst $arg]($name)]]"
       }
              
    }       

}   
############################################################################
#ProcName: SetLogOption
#
#Description: Set the log parameters according to input parameters
#
#Input: 1. arg:argument list£¬including the following
#            (1)-Debug Debug:Whether or not output debug information. Enable means outputing the information¡£
#                                       The default value is Disable
#            (2)-LogTo LogTo: Destination of the output, valid range is {stdOut file both}£¬while:
#                                       stdOut: output to the screen£¬
#                                       file: output to the file
#                                       both: output to the screen and file
#            (3)-FileName FileName: Name of the log file
#Output: None
#
#Coded by: David.Wu
############################################################################
proc SetLogOption {args} {

    set index [lsearch $args -Debug] 
    if {$index != -1} {
        set Debug [lindex $args [expr $index+1]]
    } else  {
        set Debug Disable
    }

    set index [lsearch $args -LogTo] 
    if {$index != -1} {
        set LogTo [lindex $args [expr $index+1]]
    } else  {
        set LogTo "stdOut"
    }    

    if {[string tolower $Debug]== "enable" } {
        set ::mainDefine::gDebug 1
    }

    if {[string tolower $LogTo]== "file" } {
    
        set ::mainDefine::gOutputDst "file"
    
        set index [lsearch $args -FileName] 
        if {$index != -1} {
            set FileName [lindex $args [expr $index+1]]
            set ::mainDefine::gLogFile $FileName
        }
        
    } elseif {[string tolower $LogTo]== "both" } {
    
         set ::mainDefine::gOutputDst "both"
    
        set index [lsearch $args -FileName] 
        if {$index != -1} {
            set FileName [lindex $args [expr $index+1]]
            set ::mainDefine::gLogFile $FileName
        }
        
    } else {
       set ::mainDefine::gOutputDst "stdout"
    
    }    
}  
############################################################################
#ProcName: debugPut
#
#Description: Output debug information
#
#Input: 1. msg: The information to be output
#
#Output: None
#
#Coded by: David.Wu
############################################################################
proc debugPut {msg} {
    if {$::mainDefine::gDebug == 1} {
        if {[string tolower $::mainDefine::gOutputDst ] == "stdout"} {
            puts $msg
        } elseif {[string tolower $::mainDefine::gOutputDst ] == "file"} {
            set fileId [open $::mainDefine::gLogFile "a"]
            puts $fileId $msg
            close $fileId
        } elseif {[string tolower $::mainDefine::gOutputDst ] == "both"} {
            puts $msg
            set fileId [open $::mainDefine::gLogFile "a"]
            puts $fileId $msg
            close $fileId
        }
    }
} 

############################################################################
#ProcName: garbageCollect
#
#Description: garbage collecting when there are something error
#
#Input: None
#
#Output: None
#
#Coded by: Tony Li
############################################################################
proc garbageCollect {args} {
    if {$::mainDefine::gChassisObjectHandle != "" } {
         puts "Garbage collecting: free all the resources ..."
         $::mainDefine::gChassisObjectHandle ResetSession
        
         set ::mainDefine::gChassisObjectHandle ""
    }
} 

############################################################################
#APIName: ConvertAttrToLowerCase
#
#Description: Convert the attr of (-attr value) to lower case
#
#Input:   1.args:Parameter list
#
#Output: Converted parameter list
#
#Coded by: David.Wu
#############################################################################

proc ConvertAttrToLowerCase {args} {
    set loop 0
    while {[llength $args] == 1 && $loop < 4} {
       set args [eval subst $args ]
       set loop [expr $loop + 1]
    }

    set oddArgs ""

    set evenArgs ""

    set len [llength $args]

    if {[expr $len % 2] != 0} {

        error "params must be in the form of pairs: -attr value"

    }
    
    for {set i 0} {$i < $len} {incr i 2} {

        lappend evenArgs [lindex $args $i]

        set value [lindex $args [expr $i + 1]]
        if {[string tolower $value] == "enable"} {
             set value "TRUE"
        } elseif {[string tolower $value] == "disable"} {
             set value "FALSE"
        } else {
             #Do nothing here
        }
  
        lappend oddArgs $value

    }

    set evenArgs [string tolower $evenArgs] 

    set args ""

    for {set i 0} {$i < [expr $len / 2]} {incr i} {

        lappend args [lindex $evenArgs $i]

        lappend args [lindex $oddArgs $i]

    }
    return $args
}

############################################################################
#ProcName: GetErrMsg
#
#Description: Get the error message when there are something error
#
#Input: None
#
#Output: Error message
#
#Coded by: David.Wu
############################################################################
proc GetErrMsg {} {
    return $::mainDefine::gErrMsg
} 

############################################################################
#ProcName: dec2bin
#
#Description: convert dec to bin
#
#Input: None
#
#Output: Converted binary value
#
#Coded by: David.Wu
############################################################################
proc dec2bin {dec change {length 8}} { 
     set bin "" 
     set a 1 
     while {$a>0} { 
         set a [expr $dec/$change] 
         set b [expr $dec%$change] 
         set dec $a 
         set bin $b$bin 
     } 
     set len [string length $bin] 
     if {$len < $length } { 
         for {set i 0} {$i<[expr $length - $len]} {incr i} { 
             set bin 0$bin 
         } 
     } 
     return $bin 
}

############################################################################
#ProcName: SaveConfigAsXML
#
#Description: Save the Spirent TestCenter configuration as XML file
#
#Input: None
#
#Output: Saved XML file
#
#Coded by: David.Wu
############################################################################
proc SaveConfigAsXML {xmlFile} { 

     if {[file exists $xmlFile] == 1} {
         if {[file writable $xmlFile] == 1} {
             stc::perform saveasxml -filename $xmlFile
         } else {
             puts  "The file $xmlFile has already been opened by others ..."
         }
     } else {
         stc::perform saveasxml -filename $xmlFile
     }
}

############################################################################
#ProcName: ConvertRouteTable
#
#Description: Convert the route table to CISCO format
#
#Input: None
#
#Output: Converted route table file
#
#Coded by: Tony.Li
############################################################################
proc ConvertRouteTable {fileFormat inputFileName outputFileName} {
    
    #Open the input file
    set inputFile [open $inputFileName r]

    #Open the output file
    set outputFile [open $outputFileName w]
    if {$fileFormat == "SPIRENT" } {
       puts  $outputFile "    Network            Next Hop         Metric    LocPrf    Weight    Path"
        while {[gets $inputFile fileLine] >= 0} {
            set imask "" 
            if {![regexp {([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\n]+)\s*} $fileLine \
                  matches iroute imask inexthop imetric ilocprf irtprf ipath]} {
                  continue
            }
            if {$iroute == "Dest" || $imask == "Mask" } {
                  continue
            }

            if {$imask == ""} {
                   continue
            }

            set iorigin [string range $ipath end-1 end-1]
            set ipath_new [split [string range $ipath 1 end-3] " "]
            if {$imetric == "NULL"} {
                 set imetric 0
            }
 
            #if {$iorigin != "i" && $iorigin != "e" } {
                #set iorigin "i"
            #}
            set destPrefixLen [string bytelength "$iroute/$imask"]   
            if {$destPrefixLen < 17} {                                 
                 set route [format "*> %-17s%-16s%-11s%-16s%-6s" "$iroute/$imask" "$inexthop" "$imetric" "$ilocprf" "0"]
            } else {
                 set route [format "*> %-18s%-16s%-11s%-16s%-6s" "$iroute/$imask" "$inexthop" "$imetric" "$ilocprf" "0"]
            }
            
            puts $outputFile "$route$ipath_new $iorigin"
       }
   }

   #Finally close opened files
   close $inputFile
   close $outputFile
}

############################################################################
#ProcName: SplitRouteTableFile
#
#Description: Split the route table file according the input parameter
#
#Input: None
#
#Output: Splitted route table file
#
#Coded by: Tony.Li
############################################################################
proc SplitRouteTableFile {inputFileName number {type "chassis"} } {
 
    #Open input file
    set inputFile [open $inputFileName r]
    set TotalLines 0
    while {[gets $inputFile fileLine] >= 0} {
          set TotalLines [expr $TotalLines  + 1]
    }
    close $inputFile
 
    #Re-open the file
    set inputFile [open $inputFileName r]

    set  LinesPerFile [expr $TotalLines / $number + 1 ]
    if {$type == "port"} {
          if {$LinesPerFile >= 65535} {
               error "Suggest to import less than 65535 routes per router"
          }
     } 

    set fileNameList ""    
    for {set i 0} {$i < [expr $number - 1]} {incr i} {
          #Open output file
          set outputFile [open "$inputFileName$i" w]
          lappend fileNameList "$inputFileName$i"

          set j 0
          while {[gets $inputFile fileLine] >= 0} {
             set j [expr $j + 1]
            
             if {[expr $j % $LinesPerFile ] != 0} {
                 puts $outputFile "$fileLine"
             } else {
                 puts $outputFile "$fileLine"     
                 close $outputFile
                 break
            }
       }
   }
    set temp [expr $number - 1]
    lappend fileNameList "$inputFileName$temp"

    set outputFile [open "$inputFileName$temp" w]
    
    while {[gets $inputFile fileLine] >= 0} {
          puts $outputFile "$fileLine"
    }

    #Finally close all the files
    close $inputFile
    close $outputFile
  
    return $fileNameList
}

############################################################################
#ProcName: ConvertTrafficLoadUnit
#
#Description: Convert the traffic load unit according the input parameter
#
#Input: None
#
#Output: Converted result
#
#Coded by: Tony.Li
############################################################################
proc ConvertTrafficLoadUnit {TrafficLoad SrcUnit DstUnit capability FrameLen} { 

     set SrcUnit [string tolower $SrcUnit]
     set DstUnit [string tolower $DstUnit]

     if {$SrcUnit == $DstUnit} {
          return $TrafficLoad
     }

     set SrcUnit [string tolower $SrcUnit]
     set DstUnit [string tolower $DstUnit]

     #The first step is to convert to MBPS£¬and then to other units
     set mbps 0
     set result ""
     if {$SrcUnit == "percent"} {
         set mbps [expr 1.0 * $TrafficLoad /100* $capability]
     } elseif {$SrcUnit == "fps"} {
         set mbps [expr 1.0 * $TrafficLoad * $FrameLen * 8 / 1048576]
     } elseif {$SrcUnit == "bps"} {
          set mbps [expr 1.0 * $TrafficLoad / 1048576 ]
     } elseif {$SrcUnit == "kbps"} {
         set mbps [expr 1.0 * $TrafficLoad / 1024]
     } elseif {$SrcUnit == "mbps"} {
         set mbps $TrafficLoad
     }

     if {$DstUnit == "fps" } {
         set result [expr $mbps * 1048576 /8 /$FrameLen]
     } elseif {$DstUnit == "bps" } {
         set result [expr $mbps * 1048576]
     } elseif {$DstUnit == "kbps" } {
         set result [expr $mbps * 1024 ]
     } elseif {$DstUnit == "mbps" } {
         set result $mbps
     } elseif {$DstUnit == "percent" } {
         set result [expr 1.0 * $mbps / $capability *100]
     }
    
     debugPut "The converted result is: $result, unit: $DstUnit"
     return $result 
}

############################################################################
#APIName: ReplacePduAttrValue
#
#Description: Replace the value of (-attr value) to defined value
#
#Input:   1.args:Parameter list
#
#Output: Converted parameter list
#
#Coded by: David.Wu
#############################################################################

proc ReplacePduAttrValue {PduName attribute value} {
  
    set index [lsearch $::mainDefine::gPduConfigList $PduName] 
    set pduConfig [lindex $::mainDefine::gPduConfigList [expr $index + 2]]
 
    set value_index [lsearch $pduConfig $attribute] 
    if {$value_index != -1} {
         set pduConfig [lreplace $pduConfig [expr $value_index + 1] [expr $value_index  + 1] $value]
         set ::mainDefine::gPduConfigList [lreplace $::mainDefine::gPduConfigList  [expr $index + 2] [expr $index + 2] $pduConfig]
    } else {
         lappend pduConfig $attribute
         lappend pduConfig $value
         set ::mainDefine::gPduConfigList [lreplace $::mainDefine::gPduConfigList  [expr $index + 2] [expr $index + 2] $pduConfig]
    }   
}

############################################################################
#APIName: ApplyPduConfigToStreams
#
#Description: Apply the modified PDU configuration to associated stream object
#
#Input:   None
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc ApplyPduConfigToStreams {PduName} {
       foreach object $::mainDefine::gObjectNameList {
            catch {
                 if {[$object isa Stream]} {
                      set ::mainDefine::objectName $object
                      set result [$::mainDefine::objectName FindPdu -PduName $PduName]
                      if {$result != ""} {
                           #Delete original PDU£¬and enable new configuration
                           $::mainDefine::objectName RemovePdu
                           $::mainDefine::objectName AddPdu -PduName $result
                      }
                }        
           }
      }
} 

############################################################################
#APIName: ConvertHexFormat
#
#Description: Omit the 0x prefix in input hex number
#
#Input:   None
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc ConvertHexFormat {input} {
       set find_index [string first "0x" $input] 
       if {$find_index != -1} {
           set decimal [format "%u" $input]  
           set hex [format "%x" $decimal]
       } else {
           set hex $input
       }

       return $hex
}

############################################################################
#APIName: GetSubStreamStats
#
#Description: Get sub stream result of FilteredStream£¬filterId as key to search
#
#Input:   None
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetSubStreamStats {filterId subStreamStats} {
    set retArrValueList ""
    set found "FALSE"
    catch { set filterId [string trimleft $filterId '\{' ] }
    catch { set filterId [string trimright $filterId '\}' ] }

    set filterId "{$filterId }"
    set len [llength $subStreamStats]
    for {set i 0} {$i < $len} {incr i} {
        set retArrValueList [lindex $subStreamStats $i]
        set index [lsearch $retArrValueList "$filterId"] 
        if {$index != -1} {
            set found "TRUE"
            break
       } 
    }
    
    if {$found == "FALSE"} {
        set retArrValueList ""

        lappend retArrValueList "-FilterName"
        lappend retArrValueList "NULL"
         
        lappend retArrValueList "-FilterValue"
        lappend retArrValueList "$filterId"

        lappend retArrValueList "-RxFrames"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxSigFrames"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxBytes"
        lappend retArrValueList "0"

        lappend retArrValueList "-CRCErrors"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxIPv4chesumError"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxDupelicated"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxOutSeq"
        lappend retArrValueList "0"

        lappend retArrValueList "-RxDrop"
        lappend retArrValueList "0"
    }

    return $retArrValueList 
} 

############################################################################
#APIName: AggregateFilteredStats
#
#Description: Aggregate the values in the FilteredStream list
#
#Input:   None
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc AggregateFilteredStats {filteredStreamResults streamId} {
    set fieldNum 10
    set dstStreamIdMatch "FALSE"

    set attributeList {"-FrameCount" "-SigFrameCount" "-OctetCount" "-AvgLatency" "-AvgJitter" "-FcsErrorFrameCount" \
             "-Ipv4ChecksumErrorCount" "-DuplicateFrameCount" "-InSeqFrameCount" "-OutSeqFrameCount" "-DroppedFrameCount" \
             "-PrbsFillOctetCount" "-PrbsBitErrorCount" "-TcpUdpChecksumErrorCount" "-OctetRate" "-FrameRate" "-L1BitCount" "-L1BitRate" \
             "-FirstArrivalTime" "-LastArrivalTime"}

    foreach attribute $attributeList {
        set tmpResult($attribute) 0
    }   
        
    set hList [stc::get $filteredStreamResults -resulthandlelist]           
    foreach hResult $hList { 
        array set arr [stc::get $hResult]
                    
        for {set i 1} {$i <= $fieldNum} {incr i} {
             set dstStreamId $arr(-FilteredValue_$i)
             set dstFilteredName $arr(-FilteredName_$i)
             if {$dstFilteredName == "Rx Stream Id" && $streamId == $dstStreamId} {
                foreach attribute $attributeList {
                    if {$attribute == "-AvgLatency" || $attribute == "-AvgJitter"} {
                        if {$tmpResult($attribute) == 0 } {
                            set tmpResult($attribute) $arr($attribute)
                        } else { 
                            set tmpResult($attribute) [expr ($tmpResult($attribute) + $arr($attribute))/2]
                        }
                    } else { 
                        set tmpResult($attribute) [expr $tmpResult($attribute) + $arr($attribute)]
                    }
                }
                set dstStreamIdMatch "TRUE"
                break
            }
        }
    }

    set result ""
    foreach attribute $attributeList {
        lappend result $attribute
        lappend result $tmpResult($attribute) 
    }

    if {$dstStreamIdMatch == "TRUE"} {
        return $result
    } else {
        return ""
    }
}

############################################################################
#APIName: GetEthHandle
#
#Description: Get ethernet:EthernetII, if not exist then create a new one
#
#Input: Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetEthHandle {streamblock1} {
       set hEthList "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "ethernet:ethernetii*"]
       if {$index == -1} {
            set hEthList [stc::create ethernet:EthernetII -under $streamblock1]
       } else {
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
       }

       return $hEthList
}

############################################################################
#APIName: GetIPv4Handle
#
#Description: Get layer 3 IPv4 handle, if not exist then create a new one
#
#Input:   Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetIPv4Handle {streamblock1} {
       set hIPv4List "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "ipv4:ipv4*"]
       if {$index == -1} {
            set hIPv4List [stc::create ipv4:IPv4 -under $streamblock1]
       } else {
            set hIPv4List [stc::get $streamblock1 -children-ipv4:IPv4]
       }

       return $hIPv4List
}

############################################################################
#APIName: GetIPv6Handle
#
#Description: Get layer 3 IPv6 handle, if not exist then create a new one
#
#Input:   Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetIPv6Handle {streamblock1} {
       set hIPv6List "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "ipv6:ipv6*"]
       if {$index == -1} {
            set hIPv6List [stc::create ipv6:IPv6 -under $streamblock1]
       } else {
            set hIPv6List [stc::get $streamblock1 -children-ipv6:IPv6]
       }

       return $hIPv6List
}

############################################################################
#APIName: GetUDPHandle
#
#Description: Get layer 4 UDP handle, if not exist then create a new one
#
#Input:   Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetUDPHandle {streamblock1} {
       set hUDPList "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "udp:udp*"]
       if {$index == -1} {
            set hUDPList [stc::create udp:Udp -under $streamblock1]
       } else {
            set hUDPList [stc::get $streamblock1 -children-udp:Udp]
       }

       return $hUDPList
}

############################################################################
#APIName: GetTCPHandle
#
#Description: Get layer 4 TCP handle, if not exist then create a new one
#
#Input:   Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetTCPHandle {streamblock1} {
       set hTCPList "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "tcp:tcp*"]
       if {$index == -1} {
            set hTCPList [stc::create tcp:Tcp -under $streamblock1]
       } else {
            set hTCPList [stc::get $streamblock1 -children-tcp:Tcp]
       }

       return $hTCPList
}

############################################################################
#APIName: GetARPHandle
#
#Description: Get layer 3 ARP handle, if not exist then create a new one
#
#Input:   Handle of stream block
#
#Output: None
#
#Coded by: Tony
#############################################################################
proc GetARPHandle {streamblock1} {
       set hARPList "" 
       set children [stc::get $streamblock1 -children]
       set index [lsearch $children "arp:arp*"]
       if {$index == -1} {
            set hARPList [stc::create arp:ARP -under $streamblock1]
       } else {
            set hARPList [stc::get $streamblock1 -children-arp:ARP]
       }

       return $hARPList
}

############################################################################
#APIName: ipaddr2dec
#
#Description: Convert ip address to dec
#
#Input:   Ip Addr
#
#Output: Converted dec value
#
#Coded by: Tony
#############################################################################
proc ipaddr2dec {ipaddr} { 
   set list [split $ipaddr .]
   set len [llength $list]

   set dec 0
   
   set para1 [lindex $list 0]
   set para2 [lindex $list 1]
   set para3 [lindex $list 2]
   set para4 [lindex $list 3]

   set dec [expr $para4 + $para3 * 256 + $para2 *65536 + $para1 * 65536 * 256]
   return $dec
}

############################################################################
#APIName: ipaddrDotDec
#Description: Convert dec ip address to "0.0.0.1" format
#Input: ip address  dec format
#Output: Converted ip address
#Coded by: Shi Yunzhi
#############################################################################
proc ipaddr2DotDec {ip} {
    set bit0_7 [expr $ip & 0xff]
    set bit8_15 [expr ($ip >> 8) & 0xff ]
    set bit16_23 [expr ($ip >> 16) & 0xff ]
    set bit24_31 [expr ($ip >> 24) & 0xff ]

    return "$bit24_31.$bit16_23.$bit8_15.$bit0_7"
}

############################################################################
#APIName: dec2ipaddr
#
#Description: Convert ip address from dec format to "0.0.0.1" format
#
#Input: Ip address with dec format
#
#Output: Converted ip address 
#
#Coded by: Tony
#############################################################################
proc dec2ipaddr { num } {
    set ip ""
    binary scan [binary format I $num] c4 octets
    foreach oct $octets {
        lappend ip [expr ($oct & 0xff)]
    }
    return [join $ip .]
}

############################################################################
#APIName: ipnetmask
#Description: Get ip netmask of input ip address
#Input: ip netmask
#Output: return netmask
#Coded by: 
#############################################################################
proc ipnetmask { ip mask } {
    if {[string is integer $mask]} {
        set masknum [expr (0xffffffff << (32 - $mask)) & 0xffffffff]
    } else {
        set masknum [ipaddr2dec $mask]
    }
    set ipnum [ipaddr2dec $ip]
    return [dec2ipaddr [expr $ipnum & $masknum]]   
}

############################################################################
#APIName: isValidIPv4
#
#Description: Check whether or input ip address is valid
#
#Input:   Ip Addr
#
#Output: return 1 for valid ip address; return 0 for invalid ip address
#
#Coded by: Tony
#############################################################################
proc isValidIPv4 {pIP} {
    set byteList [split $pIP "."]
    if {[llength $byteList] !=4} {return 0}
    foreach i $byteList {
        if {![string is integer $i] || $i < 0 || $i > 255} {
            return 0
        }
    }
    return 1
}

############################################################################
#APIName: isValidIPv6
#
#Description: Check whether or input ipv6 address is valid
#
#Input:   Ip Addr
#
#Output: return 1 for valid ip address; return 0 for invalid ip address
#
#Coded by: Tony
#############################################################################
proc isValidIPv6 {ip} {
    if {[regexp "^:" $ip]} {set ip 0$ip}
    if {[regexp ":$" $ip]} {set ip ${ip}0}
    set quadList [split $ip :]
    if {[llength $quadList] > 8} {return 0}
    if {[llength $quadList] < 8 && [lsearch -exact $quadList {}] == -1} {return 0}
    if {[lsearch -exact $quadList {}] != -1 && [llength [lsearch -exact -all $quadList {}]] > 1} {return 0}
    foreach quad $quadList {
        if {![regexp "^\[0-9a-fA-F\]{0,4}$" $quad]} {return 0}
    }
    return 1
}

############################################################################
#APIName: isPortNameEqualToCreator
#
#Description: Check whether or not port equals to Creator
#
#Input:   PortName Creator
#
#Output: return TRUE or FALSE
#
#Coded by: Tony
#############################################################################
proc isPortNameEqualToCreator {portName creator} {

    set ret "TRUE"
    
    catch {    
        set portParaList [split $portName "::"]
        set portParaLen [llength $portParaList]

        set srcIndex [expr $portParaLen - 1]
        set compareSrc [lindex $portParaList $srcIndex]    

        set creatorParaList [split $creator "::"]
        set creatorParaLen [llength $creatorParaList]

        set dstIndex [expr $creatorParaLen - 1]
        set compareDst [lindex $creatorParaList $dstIndex]

        if {$compareSrc == $compareDst} {
           set ret "TRUE"
        } else {
           set ret "FALSE"
        } 
    }
    
    return $ret
}

############################################################################
#APIName: GetStatisticStreamResult
#
#Description: Get the handle£¨support cache mechanism£©
#
#Input: StreamName: name of the stream  StreamResultHandle£ºstreamµÄhandle, type: stream type
#       TotalPageCount: total pages of stream result   hGeneratorStatus£ºstatus of the generator   
#
#
#Output: STC stream result handle
#
#############################################################################
proc GetStatisticStreamResult {StreamName StreamResultHandle type TotalPageCount hGeneratorStatus} {
    set result_handle ""
 
    if {$type == "TxStream"} {
        set gCurrentPage $::mainDefine::gCurrentTxPageNumber
        set gCachedStreamHandleList $::mainDefine::gCachedTxStreamHandleList
    } elseif {$type == "RxStream"} { 
        set gCurrentPage $::mainDefine::gCurrentRxPageNumber
        set gCachedStreamHandleList $::mainDefine::gCachedRxStreamHandleList
    } elseif {$type == "TxSummaryStream"} {
        set gCurrentPage $::mainDefine::gCurrentTxSummaryPageNumber
        set gCachedStreamHandleList $::mainDefine::gCachedTxSummaryStreamHandleList
    } elseif {$type == "RxSummaryStream"} {
        set gCurrentPage $::mainDefine::gCurrentRxSummaryPageNumber
        set gCachedStreamHandleList $::mainDefine::gCachedRxSummaryStreamHandleList
    } elseif {$type == "RxFilteredStream"} {
        set gCurrentPage $::mainDefine::gCurrentRxFilteredPageNumber
        set gCachedStreamHandleList $::mainDefine::gCachedRxFilteredStreamHandleList
    }

    if {$gCurrentPage != 0} {
        set handleList $gCachedStreamHandleList
        foreach handle $handleList {
            set handleParent [stc::get $handle -parent]
            set handleName [stc::get $handleParent -name]
            if { $handleName == $StreamName } {
                set result_handle $handle
                break
            }    
        }  
    }

    if {$result_handle == ""} {  
        set currentPage 1
        while { $currentPage <= $TotalPageCount } {
            stc::config $StreamResultHandle -PageNumber $currentPage
            stc::apply 
        
            catch {
                if {$hGeneratorStatus == "STOPPED"} {
                    set errorCode [stc::perform RefreshResultView -ResultDataSet $StreamResultHandle  ]
                    after 500
                }  
            }
               
            set handleList [stc::get $StreamResultHandle -resulthandlelist]
            foreach handle $handleList {
                set handleParent [stc::get $handle -parent]
                set handleName [stc::get $handleParent -name]
                if {$handleName == $StreamName } {
                    set result_handle $handle
                    
                    if {$type == "TxStream"} {
                        set ::mainDefine::gCurrentTxPageNumber  $currentPage
                        set ::mainDefine::gCachedTxStreamHandleList $handleList
                    } elseif {$type == "RxStream"} { 
                        set ::mainDefine::gCurrentRxPageNumber  $currentPage
                        set ::mainDefine::gCachedRxStreamHandleList $handleList
                    } elseif {$type == "TxSummaryStream"} {
                        set ::mainDefine::gCurrentTxSummaryPageNumber  $currentPage
                        set ::mainDefine::gCachedTxSummaryStreamHandleList $handleList
                    } elseif {$type == "RxSummaryStream"} {
                        set ::mainDefine::gCurrentRxSummaryPageNumber $currentPage
                        set ::mainDefine::gCachedRxSummaryStreamHandleList $handleList
                    } elseif {$type == "RxFilteredStream"} {
                        set ::mainDefine::gCurrentRxFilteredPageNumber  $currentPage
                        set ::mainDefine::gCachedRxFilteredStreamHandleList $handleList
                    } 
                   
                    break
               }    
           }

           if {$result_handle != ""} {
               break
           }
              
           incr currentPage
       };# end while
   }
   puts $result_handle
   return $result_handle
}

############################################################################
#APIName: reformatArgs
#
#Description: If the format of args is list £¬convert it to string format
#             
#
#Input: Input parameter
#
#
#Output: Converted parameters
#
#############################################################################
proc reformatArgs {args} {
    #If the format of args is list £¬convert it to string format
    if {[llength $args] == 1} {
        set sr [lindex [lindex $args 0] 0]
    }
    return $sr
}

############################################################################
#APIName: getObjectName
#
#Description: get the name of object, omit the namespace chars
#
#Input:   name
#
#Output: return the converted result
#
#Coded by: Tony
#############################################################################
proc getObjectName {name} {

    set result $name
    
    catch {    
        set nameParaList [split $name "::"]
        set nameParaLen [llength $nameParaList]

        set index [expr $nameParaLen - 1]
        set result [lindex $nameParaList $index]    
    }
    
    return $result
}
#Load modules of HLAPI, each module contains a class or protocol
#To add a new protocol, just reference the protocol file directly
##########################################################################
#          ADD BY SHI JUNHUA 2008.11.24 SPIRENT COR
##########################################################################
set capi_oldDir [pwd]
set capi_curDir [file normalize [file dirname [info script]]]
cd $capi_curDir
##########################################################################
source ./Stream.tcl
source ./PacketBuilder.tcl
source ./Traffic.tcl
source ./StatisticEngine.tcl
source ./Host.tcl
source ./Port.tcl
source ./EthernetPort.tcl
source ./WanPort.tcl
source ./Chassis.tcl
source ./Scheduler.tcl
source ./Event.tcl
source ./GeneralRouter.tcl

source ./IGMPoverDHCPProtocol.tcl
source ./IGMPProtocol.tcl
source ./MLDProtocol.tcl
source ./DHCPv4Protocol.tcl
source ./DHCPv6Protocol.tcl
source ./PPPoXProtocol.tcl

source ./AtmPort.tcl
source ./BGPProtocol.tcl
source ./BGPv6Protocol.tcl

source ./IGMPoverPPPoEProtocol.tcl
source ./ISISProtocol.tcl
source ./LDPProtocol.tcl
source ./LowRatePort.tcl
source ./Ospfv2Protocol.tcl
source ./Ospfv3Protocol.tcl
source ./PIMProtocol.tcl
source ./RIPngProtocol.tcl
source ./RIPProtocol.tcl
source ./RsvpProtocol.tcl

##########################################################################
#          ADD BY SHI JUNHUA 2008.11.24 SPIRENT COR
##########################################################################
cd $capi_oldDir
unset capi_oldDir capi_curDir
##########################################################################
} ;#If defined
