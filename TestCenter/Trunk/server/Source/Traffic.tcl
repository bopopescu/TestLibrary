###########################################################################
#                                                                        
#  File Name：Traffic.tcl                                                                                              
# 
#  Description：Definition of Traffic class and its methods                                             
# 
#  Author： Jaimin.Wan
#
#  Create Time:  2007.3.2
#
#  Version：1.0 
# 
#  History： 2008/1/14 by Penn.chen, Modified CreateProfile API
# 
##########################################################################

proc AdjustNum {num1 num2} {
    set temp [expr fmod($num1,$num2)] 
    if {$temp == "0.0"} {
        return $num1
    } else {
        set a [expr $num1/$num2]
        set b [expr [expr int($a)]+1]
        set num1 [expr $b*$num2] 
        return $num1
    }
}

##########################################
#Definition of Traffic class
##########################################  
::itcl::class TrafficEngine {

    #Variables
    public variable m_portName 0
    public variable m_hPort 0
    public variable m_portType "ethernet"
    public variable m_hProject 0
    public variable m_portLocation 0
    public variable m_streamNameList   ""
    public variable m_streamBlockHandle
    public variable m_streamCount 0  
    public variable m_activeProfileName 0  
    public variable m_activeProfileNameList ""
    public variable m_IsPortConfigured "FALSE"  
    public variable m_startedProfileList ""

    #Default Traffic Profile configurations
    public variable m_trafficProfileList ""
    public variable m_trafficProfileContent
 
    public variable m_profileConfig          
    public variable m_type "CONSTANT"
    public variable m_trafficLoad 10
    public variable m_trafficLoadUnit "percent"
    public variable m_burstSize 1
    public variable m_frameNum 100
    public variable m_burstNum 100
    public variable m_blocking FALSE    
    public variable m_BurstFlag TRUE
    public variable m_streamLoadFlag
	public variable m_boundStreamFlag 0
    public variable m_streamLoadUnitFlag

    public variable m_streamName ""
    #Parameters associated with RangeModifier
    public variable m_EthSrcRangeModifierList
    public variable m_EthDstRangeModifierList
    public variable m_EthSrcTableModifierList
    public variable m_EthDstTableModifierList
    public variable m_EthSrcTableModifierAddrList
    public variable m_EthDstTableModifierAddrList
    public variable m_EthTypeRangeModifierList
    public variable m_MplsLabelRangeModifierList1
    public variable m_MplsLabelRangeModifierList2
    public variable m_MplsLabelRangeModifierList3
    public variable m_MplsLabelRangeModifierList4                  
    public variable m_VlanIdRangeModifierList
    public variable m_VlanId2RangeModifierList
    public variable m_VlanIdTableModifierList
    public variable m_VlanIdTableModifierIdList
    public variable m_VlanIdTableModifierList2
    public variable m_VlanIdTableModifierIdList2
    public variable m_Ipv4SrcRangeModifierList
    public variable m_Ipv4TypeRangeModifierList
    public variable m_Ipv4DstRangeModifierList
    public variable m_Ipv4SrcTableModifierList
    public variable m_Ipv4DstTableModifierList
    public variable m_Ipv4SrcTableModifierAddrList
    public variable m_Ipv4DstTableModifierAddrList
    public variable m_Ipv6SrcRangeModifierList
    public variable m_Ipv6DstRangeModifierList
    public variable m_Ipv6SrcTableModifierList
    public variable m_Ipv6DstTableModifierList
    public variable m_Ipv6SrcTableModifierAddrList
    public variable m_Ipv6DstTableModifierAddrList
    public variable m_UdpSrcRangeModifierList
    public variable m_UdpDstRangeModifierList 
    public variable m_TcpSrcRangeModifierList
    public variable m_TcpDstRangeModifierList
    public variable m_IcmpIdRangeModifierList
    public variable m_IcmpSeqRangeModifierList
    public variable m_ArpSrcHwRangeModifierList
    public variable m_ArpDstHwRangeModifierList
    public variable m_ArpSrcProtoRangeModifierList
    public variable m_ArpDstProtoRangeModifierList

    public variable m_IcmpCmdList
    public variable m_IcmpArgsList

    #CreateStream layer parameters 
    public variable m_CreateStreamArgsList
    public variable m_L2TypeList
    public variable m_L3TypeList
    public variable m_streamType
    public variable m_trafficPattern

    #Parameters associated with FrameLenMode
    public variable m_frameLen 
    public variable m_frameLenMode 
    public variable m_frameLenCount 
    public variable m_frameLenStep 
    public variable m_signature 

    #MPLS default parameters
    public variable m_mplsLabelList
    public variable m_mplsLabelCountList
    public variable m_mplsLabelModeList
    public variable m_mplsLabelStepList
    public variable m_mplsExpList
    public variable m_mplsTtlList
    public variable m_mplsBottomOfStackList

    #Constructor
    constructor {hPort portType portLocation hProject portName} { 
       set m_portLocation $portLocation       
       set m_hProject $hProject
       set m_hPort $hPort
       set m_portType $portType
       set m_portName $portName
       set m_activeProfileName "$portName\_Profile1" 
       set m_trafficProfileContent($portName\_Profile1) ""

       set m_IsPortConfigured "FALSE"

       #Default profile
       lappend m_trafficProfileList "$portName\_Profile1" 
       set m_profileConfig($portName\_Profile1) ""
       lappend m_profileConfig($portName\_Profile1) -type  
       lappend m_profileConfig($portName\_Profile1) $m_type           
       lappend m_profileConfig($portName\_Profile1) -trafficload  
       lappend m_profileConfig($portName\_Profile1) $m_trafficLoad     
       lappend m_profileConfig($portName\_Profile1) -trafficloadunit  
       lappend m_profileConfig($portName\_Profile1) $m_trafficLoadUnit     
       lappend m_profileConfig($portName\_Profile1) -burstsize  
       lappend m_profileConfig($portName\_Profile1) $m_burstSize     
       lappend m_profileConfig($portName\_Profile1) -framenum  
       lappend m_profileConfig($portName\_Profile1) $m_frameNum   
       lappend m_profileConfig($portName\_Profile1) -burstflag  
       lappend m_profileConfig($portName\_Profile1) "FALSE"       
       lappend m_profileConfig($portName\_Profile1) -blocking  
       lappend m_profileConfig($portName\_Profile1) $m_blocking     
      
       lappend ::mainDefine::gObjectNameList $this
    }
    
    #Destructor
    destructor {
    catch {
          foreach trafficProfile $m_trafficProfileList {
                DestroyProfile -name $trafficProfile
          }
          set m_trafficProfileList ""
    }
    catch {
      set ::mainDefine::gTrafficName $this
      uplevel 1 {
          $::mainDefine::gTrafficName DestroyStream 
      }  
    }

    set index [lsearch $::mainDefine::gObjectNameList $this]
    set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
    
    #Methods
    public method CreateProfile
    public method ConfigProfile
    public method DestroyProfile    
    public method CreateStream
    public method ConfigStream
    public method DestroyStream

    #Methods internal use only
    private method FindStreamProfileName
    private method AdjustProfileStreamLoads
    public  method ApplyProfileToPort
    public  method GetProfileContent
    public  method DeleteProfileStream
    public  method GetProfileStreamLength
    
    #Methods associated with CreateStream and ConfigStream
    private method ConfigLayerStreamParameters
    private method ConfigEthStreamParameters
    private method ConfigMplsStreamParameters    
    private method ConfigIPV4StreamParameters
    private method ConfigIPV6StreamParameters
    private method ConfigVlanStreamParameters
    private method ConfigUdpStreamParameters
    private method ConfigTcpStreamParameters
    private method ConfigIcmpCmdParameters
    private method ConfigIcmpStreamParameters
    private method ConfigArpStreamParameters
    private method ConfigStreamParameters
    private method Dec2Bin
} 

############################################################################
#APIName: FindStreamProfileName
#Description: Search the profile anem according to stream name
#Input: 1. Profile name
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body TrafficEngine::FindStreamProfileName {streamname} {

     set ret_profilename ""
     foreach profilename $m_activeProfileNameList {
           set streamname_list $m_trafficProfileContent($profilename)
           foreach stream $streamname_list {
                 if {$stream == $streamname} {
                       set ret_profilename $profilename
                       return $ret_profilename
                 }
           }
     }

     return $ret_profilename
}

############################################################################
#APIName: AdjustProfileStreamLoads
#Description: Adjust the stream block parameter in Profile automatically
#Input: 1. Profile name
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body TrafficEngine::AdjustProfileStreamLoads {name} {
      set streamname_list $m_trafficProfileContent($name)

      set StreamNum [llength $m_trafficProfileContent($name)]    
      if {$StreamNum == "0"} {
            return
      }
 
      set index [lsearch $m_profileConfig($name) -trafficload]
      set trafficLoad [lindex $m_profileConfig($name) [expr $index + 1]]   

      set index [lsearch $m_profileConfig($name) -trafficloadunit]
      set trafficLoadUnit [lindex $m_profileConfig($name) [expr $index + 1]]  
      if {[string tolower $trafficLoadUnit] =="fps"} {
          set loadUnit  FRAMES_PER_SECOND
      } elseif {[string tolower $trafficLoadUnit] =="bps"} {
          set loadUnit  BITS_PER_SECOND
      } elseif {[string tolower $trafficLoadUnit] =="kbps"} {
          set loadUnit KILOBITS_PER_SECOND
      } elseif {[string tolower $trafficLoadUnit] =="mbps"} {
          set loadUnit MEGABITS_PER_SECOND
      } else {
          set loadUnit  PERCENT_LINE_RATE
      }

      #Calculate adjusted StreamLoad parameter
      set StreamLoad [expr 1.0 * $trafficLoad/$StreamNum]
      if {$StreamLoad == "0"} {
            error "The calculated stream load can not be zero for profile:$name"
      }

      #Adjust the stream load of the streams in profile
      foreach stream $streamname_list  {     
           set index [lsearch $m_streamNameList $stream]
           if {$index != -1} {
               set ::mainDefine::objectName $stream 
               uplevel 1 { 
                    uplevel 1 {        
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                    }
               }         
               set hStream $::mainDefine::result 
               if {$m_streamLoadFlag($stream) == "TRUE" || $m_streamLoadUnitFlag($stream) == "TRUE"} {
                   if {$m_streamLoadUnitFlag($stream) == "FALSE"} {
                        stc::config $hStream -LoadUnit $loadUnit
                   }

                   if {$m_streamLoadFlag($stream) == "FALSE"} {
                        stc::config $hStream -Load $StreamLoad
                   }
               } else {
                  stc::config $hStream -Load $StreamLoad -LoadUnit $loadUnit
               } 
           }
      }           
}

############################################################################
#APIName: GetProfileStreamLength
#Description: Calculate average frame length in profile
#Input: 1. Profile name
#Output: average frame length in Profile
#Coded by: Tony.Li
#############################################################################
::itcl::body TrafficEngine::GetProfileStreamLength {name} {
      set streamname_list $m_trafficProfileContent($name)

      set StreamNum [llength $m_trafficProfileContent($name)]    
      if {$StreamNum == "0"} {
           return 0
      }
 
      set profileAvgStreamLen 0

      #For all the streams in profile, add the frame length
      foreach stream $streamname_list  {     
           set index [lsearch $m_streamNameList $stream]
           if {$index != -1} {
               set ::mainDefine::objectName $stream 
               uplevel 1 { 
                    uplevel 1 {        
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
                    }
               }         
               set hStream $::mainDefine::result 
               set streamLen [ stc::get $hStream -FixedFrameLength]
               set profileAvgStreamLen [expr $profileAvgStreamLen + $streamLen]
           }
      }   

     set  profileAvgStreamLen [expr $profileAvgStreamLen / $StreamNum]
   
     return $profileAvgStreamLen
}

############################################################################
#APIName: ApplyProfileToPort
#Description: Apply the configuration of profile to the port
#Input: 1. Profile name, if all，enable all the configurations in m_activeProfileNameList
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body TrafficEngine::ApplyProfileToPort {namelist type} {
   
     set activeProfileNameList ""
     if {$namelist == "all"} { 
         #Start all the streams in StartTraffic
         set activeProfileNameList  $m_activeProfileNameList  
     } else {
         if {$type == "profile"} {
             #Start ProfileNameList in StartTraffic
             foreach profilename $namelist { 
                  set index [lsearch $m_activeProfileNameList $profilename]
                  if {$index != -1} {
                       lappend activeProfileNameList $profilename
                  }
             }
         } else {
             #Start StreamNameList in StartTraffic
             foreach streamname $namelist { 
                  #Check whether or not streamname exists
                  set index [lsearch $m_streamNameList $streamname]
                  if {$index != -1} {
                       #If really exists，then find in active profile list
                       set ret [FindStreamProfileName $streamname]
                       if {$ret != ""} {
                            #Finally，insert into the activeProfileNameList
                            set index [lsearch $activeProfileNameList $ret]
                            if {$index == -1} {
                                lappend activeProfileNameList $ret
                            }
                       }
                  }
             }
         }
     }

     if {$activeProfileNameList  == ""} {
        puts "There are no items in the active profile name list, thus exit the configuration"
        return 0
     }

     #For fundamental parameters obtained from the first item in profile
     
     set defaultname [lindex $activeProfileNameList  end]
     set index [lsearch $m_profileConfig($defaultname) -trafficload]
     set trafficLoad [lindex $m_profileConfig($defaultname) [expr $index + 1]]   

     set index [lsearch $m_profileConfig($defaultname) -trafficloadunit]
     set trafficLoadUnit [lindex $m_profileConfig($defaultname) [expr $index + 1]]   

     set index [lsearch $m_profileConfig($defaultname) -burstsize]
     set burstSize [lindex $m_profileConfig($defaultname) [expr $index + 1]]  

     set index [lsearch $m_profileConfig($defaultname) -burstflag]
     set burstFlag [lindex $m_profileConfig($defaultname) [expr $index + 1]] 

     set index [lsearch $m_profileConfig($defaultname) -blocking]
     set blocking [lindex $m_profileConfig($defaultname) [expr $index + 1]]     

     set index [lsearch $m_profileConfig($defaultname) -type]
     set type [lindex $m_profileConfig($defaultname) [expr $index + 1]]

     set total_frameNum 0
     set total_trafficLoad 0
	

     set hGenerator [stc::get $m_hPort -children-Generator]
     set hGeneratorStatus [stc::get $hGenerator -state]
     #If the generator has already been stopped, then we need to reset m_startedProfileList   
     if {$hGeneratorStatus != "RUNNING" && $hGeneratorStatus != "PENDING_START"} {
          set m_startedProfileList  ""
     }

     #Accumulate the trafficLoad and frameNum in profile     
     foreach profilename $activeProfileNameList {
         set index [lsearch $m_profileConfig($profilename) -trafficloadunit]
         set tmp_trafficLoadUnit [lindex $m_profileConfig($profilename) [expr $index + 1]]  
         set index [lsearch $m_profileConfig($profilename) -trafficload]
         set tmp_trafficLoad [lindex $m_profileConfig($profilename) [expr $index + 1]]   
        
         if {$tmp_trafficLoadUnit != $trafficLoadUnit} { 
               set profileAvgStreamLen [GetProfileStreamLength $profilename]
    
               if {$profileAvgStreamLen != "0"} {
                     set linkConfig ""
                  
                     if { [catch {
                          set linkConfig [stc::get $m_hPort -children-EthernetCopper]
                     }  err ] } {
                          set linkConfig [stc::get $m_hPort -children-EthernetFiber]
                     }
                     set link_speed [stc::get $linkConfig -LineSpeed]
                     
                     if {$link_speed == "SPEED_10M"} {
                           set speed 10
                     } elseif {$link_speed == "SPEED_100M"} {
                           set speed 100
                     } elseif {$link_speed == "SPEED_1G"} {
                           set speed 1000
                     } elseif {$link_speed == "SPEED_10G"} {
                           set speed 10000
                     } else {
                           set speed 1000
                     }

                   set tmp_trafficLoad [ConvertTrafficLoadUnit $tmp_trafficLoad $tmp_trafficLoadUnit $trafficLoadUnit $speed $profileAvgStreamLen]   
               } else {
                   error "The average frame length of profile:$profilename is 0, there are something unual"
               }
         } 

        set total_trafficLoad [expr $total_trafficLoad + $tmp_trafficLoad ]

        set index [lsearch $m_profileConfig($profilename) -framenum]
        set tmp_frameNum [lindex $m_profileConfig($profilename) [expr $index + 1]]      
        set total_frameNum [expr $total_frameNum + $tmp_frameNum]
    }

    #Adjust the calculated value
	### addded by Jaimin 2013-07-01 Begin #############
	set index [lsearch $m_profileConfig($defaultname) -framenum]
    set frameNum [lindex $m_profileConfig($defaultname) [expr $index + 1]]
	#set frameNum $total_frameNum 
	### addded by Jaimin 2013-07-01 End #############
    
    set trafficLoad $total_trafficLoad 
    
    #If current generator in running state, then consider original generator configuration
    if {$type == "profile"} {
        set hGenerator [stc::get $m_hPort -children-Generator]
        set hGeneratorStatus [stc::get $hGenerator -state]

        if {$hGeneratorStatus == "RUNNING" || $hGeneratorStatus == "PENDING_START"} {
            set generatorConfig [stc::get $hGenerator -children-GeneratorConfig]   
            set running_traffic_load [stc::get $generatorConfig -FixedLoad]
            set trafficLoad [expr $trafficLoad + $running_traffic_load]

            set running_DurationMode [stc::get $generatorConfig -DurationMode]
            if {[string tolower $running_DurationMode] == "bursts" } {
                set running_BurstSize [stc::get $generatorConfig -BurstSize]
                set running_Duration [stc::get $generatorConfig -Duration]
                set running_FrameNum [expr $running_BurstSize * $running_Duration]
                
				set frameNum [expr $frameNum + $running_FrameNum]
            }
         }
     }

     #Adjust framenum to ensure it can be divided by BurstSize
     set frameNum [AdjustNum $frameNum $burstSize]
     set burstNum [expr $frameNum/$burstSize]     
     set frameNumOfBlocking $frameNum

     #Configure stream scheduling mode
     set streamScheduleMode "RATE_BASED"

     if {[info exists ::mainDefine::gPortScheduleMode($m_portName)]} {
         set streamScheduleMode $::mainDefine::gPortScheduleMode($m_portName)
     } else {
         set streamScheduleMode $::mainDefine::gStreamScheduleMode
     }
	 
     if {[string tolower $burstFlag] == "true" || [string tolower $type] == "burst"} {
         if {[string tolower $trafficLoadUnit] =="fps"} {
             set loadUnit  FRAMES_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="bps"} {
             set loadUnit  BITS_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="kbps"} {
             set loadUnit KILOBITS_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="mbps"} {
             set loadUnit MEGABITS_PER_SECOND
         } else {
             set loadUnit  PERCENT_LINE_RATE
         }
         set hGenerator [stc::get $m_hPort -children-Generator]
         set generatorConfig [stc::get $hGenerator -children-GeneratorConfig]   
           
         stc::config $generatorConfig -SchedulingMode $streamScheduleMode  \
                                      -BurstSize $burstSize \
                                      -DurationMode BURSTS \
                                      -Duration $burstNum  \
                                      -FixedLoad $trafficLoad \
                                      -LoadUnit $loadUnit \
                                      -InterFrameGap "12"
     } else {
         if {[string tolower $trafficLoadUnit] =="fps"} {
             set loadUnit  FRAMES_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="bps"} {
             set loadUnit  BITS_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="kbps"} {
             set loadUnit KILOBITS_PER_SECOND
         } elseif {[string tolower $trafficLoadUnit] =="mbps"} {
             set loadUnit MEGABITS_PER_SECOND
         } else {
             set loadUnit  PERCENT_LINE_RATE
         }

         set hGenerator [stc::get $m_hPort -children-Generator]
         set generatorConfig [stc::get $hGenerator -children-GeneratorConfig]    
         stc::config $generatorConfig -SchedulingMode $streamScheduleMode -DurationMode CONTINUOUS -FixedLoad $trafficLoad -LoadUnit $loadUnit
    }
    
    #If blocking is TRUE, then we need to return frameNumOfBlocking,
    #In StartTraffic, it will wait until all the packakets have been sent out
    if {[string tolower $blocking] == "true" && [string tolower $burstFlag] == "true"} {
          return $frameNumOfBlocking
    } else {
          return 0
   }
}

############################################################################
#APIName: GetProfileContent
#Description: Get the stream list in profile
#Input: 1. Profile name
#Output: None
#Coded by: Penn Chen
#############################################################################
::itcl::body TrafficEngine::GetProfileContent {name} {
       return $m_trafficProfileContent($name)
}  

############################################################################
#APIName: ConfigEthStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::ConfigEthStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################Layer 2 parameters#######################
    set EthFlag 0
    #Parse EthDstMac parameter
    set index [lsearch $args -ethdstmac] 
    
    if {$index != -1} {
        set EthDst [lindex $args [expr $index + 1]]
        set hEthList [GetEthHandle $streamblock1]
        
         #判断输入地址是否为列表形式
        set m_EthDstTableModifierAddrList($streamblock1) $EthDst
        #set EthDst [lindex $EthDst 0]
        set EthDst [join $EthDst ""]
        #???mac??????? added by michael.cai 2012.11.16
        set temp_str_list [list]
        set str_list [split $EthDst ""]
        foreach str $str_list {
            if {[regexp {( )|(:)|(-)|(\.)} $str] == 0} {
                lappend temp_str_list $str
            }
        }
        set EthDst [join [list "[lindex $temp_str_list 0][lindex $temp_str_list 1]" "[lindex $temp_str_list 2][lindex $temp_str_list 3]" "[lindex $temp_str_list 4][lindex $temp_str_list 5]" "[lindex $temp_str_list 6][lindex $temp_str_list 7]" "[lindex $temp_str_list 8][lindex $temp_str_list 9]" "[lindex $temp_str_list 10][lindex $temp_str_list 11]"] :]

        foreach hEth $hEthList {
            stc::config $hEth -dstMac $EthDst
        }
        set EthFlag 1
    } 
    
    #Parse EthSrcMac parameter
    set index [lsearch $args -ethsrcmac] 
    if {$index != -1} {
        set EthSrc [lindex $args [expr $index + 1]]
        set hEthList [GetEthHandle $streamblock1]

         #判断输入地址是否为列表形式
        set m_EthSrcTableModifierAddrList($streamblock1) $EthSrc
        #set EthSrc [lindex $EthSrc 0]
        set EthSrc [join $EthSrc ""]
        #???mac??????? added by michael.cai 2012.11.16
        set temp_str_list [list]
        set str_list [split $EthSrc ""]
        foreach str $str_list {
            if {[regexp {( )|(:)|(-)|(\.)} $str] == 0} {
                lappend temp_str_list $str
            }
        }
        set EthSrc [join [list "[lindex $temp_str_list 0][lindex $temp_str_list 1]" "[lindex $temp_str_list 2][lindex $temp_str_list 3]" "[lindex $temp_str_list 4][lindex $temp_str_list 5]" "[lindex $temp_str_list 6][lindex $temp_str_list 7]" "[lindex $temp_str_list 8][lindex $temp_str_list 9]" "[lindex $temp_str_list 10][lindex $temp_str_list 11]"] :]

        foreach hEth $hEthList {
            stc::config $hEth -srcMac $EthSrc
        }
        set EthFlag 1
    }

     #Parse EthDst parameter
    set index [lsearch $args -ethdst] 
    
    if {$index != -1} {
        set EthDst [lindex $args [expr $index + 1]]
        set hEthList [GetEthHandle $streamblock1]

        #判断输入地址是否为列表形式
        set m_EthDstTableModifierAddrList($streamblock1) $EthDst
        #set EthDst [lindex $EthDst 0]
        set EthDst [join $EthDst ""]
        #???mac??????? added by michael.cai 2012.11.16
        set temp_str_list [list]
        set str_list [split $EthDst ""]
        foreach str $str_list {
            if {[regexp {( )|(:)|(-)|(\.)} $str] == 0} {
                lappend temp_str_list $str
            }
        }
        set EthDst [join [list "[lindex $temp_str_list 0][lindex $temp_str_list 1]" "[lindex $temp_str_list 2][lindex $temp_str_list 3]" "[lindex $temp_str_list 4][lindex $temp_str_list 5]" "[lindex $temp_str_list 6][lindex $temp_str_list 7]" "[lindex $temp_str_list 8][lindex $temp_str_list 9]" "[lindex $temp_str_list 10][lindex $temp_str_list 11]"] :]


        foreach hEth $hEthList {
            stc::config $hEth -dstMac $EthDst
        }
        set EthFlag 1
    } 
    
    #Parse EthSrc parameter
    set index [lsearch $args -ethsrc] 
    if {$index != -1} {
        set EthSrc [lindex $args [expr $index + 1]]
        set hEthList [GetEthHandle $streamblock1]

        #判断输入地址是否为列表形式
        set m_EthSrcTableModifierAddrList($streamblock1) $EthSrc
        #set EthSrc [lindex $EthSrc 0]
        set EthSrc [join $EthSrc ""]
        #???mac??????? added by michael.cai 2012.11.16
        set temp_str_list [list]
        set str_list [split $EthSrc ""]
        foreach str $str_list {
            if {[regexp {( )|(:)|(-)|(\.)} $str] == 0} {
                lappend temp_str_list $str
            }
        }
        set EthSrc [join [list "[lindex $temp_str_list 0][lindex $temp_str_list 1]" "[lindex $temp_str_list 2][lindex $temp_str_list 3]" "[lindex $temp_str_list 4][lindex $temp_str_list 5]" "[lindex $temp_str_list 6][lindex $temp_str_list 7]" "[lindex $temp_str_list 8][lindex $temp_str_list 9]" "[lindex $temp_str_list 10][lindex $temp_str_list 11]"] :]

        foreach hEth $hEthList {
            stc::config $hEth -srcMac $EthSrc
        }
        set EthFlag 1
    }

    set DestinationPort $::mainDefine::gBoundStreamDstPort($m_streamName) 
    #Suuport BoundStream type
    if {$DestinationPort != "" && $EthFlag == "1"} {
         set ::mainDefine::objectName $m_portName 
         set ::mainDefine::streamBlock $streamblock1
         set ::mainDefine::streamName $m_streamName
         set ::mainDefine::DestinationPort $DestinationPort
        
        uplevel 1 {
             uplevel 1 {
                  $::mainDefine::objectName BindHostsToStream $::mainDefine::streamBlock $::mainDefine::streamName $::mainDefine::DestinationPort  
             }
        }
    }

    #Parse EthSrcMacMode/EthSrcMacStep/EthSrcMacCount/EthSrcMacOffset parameter
    set index [lsearch $args -ethsrcmode]
    if {$index == -1} {
        set index [lsearch $args -ethsrcmacmode] 
    }
    if {$index != -1} {
        set EthSrcMode [lindex $args [expr $index + 1]]        
        if {[string tolower $EthSrcMode] =="increment"} {
            set index [lsearch $args -ethsrcstep]
            if {$index == -1} {
                  set index [lsearch $args -ethsrcmacstep]
            }
            if {$index != -1} {
                set EthSrcStep [lindex $args [expr $index + 1]]
            } else {
                set EthSrcStep "00:00:00:00:00:01"
            }
            set index [lsearch $args -ethsrccount]
            if {$index == -1} {
                set index [lsearch $args -ethsrcmaccount] 
            }
            if {$index != -1} {
                set EthSrcCount [lindex $args [expr $index + 1]]
            } else {
                set EthSrcCount 1
            }
            set index [lsearch $args -ethsrcoffset]
            if {$index == -1} {
               set index [lsearch $args -ethsrcmacoffset]
            }
            if {$index != -1} {
                set EthSrcOffset [lindex $args [expr $index + 1]]
            } else {
                set EthSrcOffset 0
            }

            set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
                set eth_h1 [stc::get $hEth -Name]
                if {$m_EthSrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthSrcTableModifierList($streamblock1)
                  set m_EthSrcTableModifierList($streamblock1) ""
                } 
                if {$m_EthSrcRangeModifierList($streamblock1) == ""} {
                      set m_EthSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hEth -srcMac] \
                           -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
                           -Offset $EthSrcOffset -ModifierMode INCR -RecycleCount $EthSrcCount -StepValue $EthSrcStep -RepeatCount 0]
                } else {
                      stc::config $m_EthSrcRangeModifierList($streamblock1) -Data [stc::get $hEth -srcMac] \
                           -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
                           -Offset $EthSrcOffset -ModifierMode INCR -RecycleCount $EthSrcCount -StepValue $EthSrcStep -RepeatCount 0
                }
            }  
        } elseif {[string tolower $EthSrcMode] =="decrement"} {
            set index [lsearch $args -ethsrcstep]
            if {$index == -1} {
                  set index [lsearch $args -ethsrcmacstep]
            }
            if {$index != -1} {
                set EthSrcStep [lindex $args [expr $index + 1]]
            } else {
                set EthSrcStep "00:00:00:00:00:01"
            }
            set index [lsearch $args -ethsrccount]
            if {$index == -1} {
                set index [lsearch $args -ethsrcmaccount] 
            }
            if {$index != -1} {
                set EthSrcCount [lindex $args [expr $index + 1]]
            } else {
                set EthSrcCount 1
            }
            set index [lsearch $args -ethsrcoffset]
            if {$index == -1} {
               set index [lsearch $args -ethsrcmacoffset]
            }
            if {$index != -1} {
                set EthSrcOffset [lindex $args [expr $index + 1]]
            } else {
                set EthSrcOffset 0
            }
            set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
                set eth_h1 [stc::get $hEth -Name]
                if {$m_EthSrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthSrcTableModifierList($streamblock1)
                  set m_EthSrcTableModifierList($streamblock1) ""
                } 
                if {$m_EthSrcRangeModifierList($streamblock1) == ""} {
                     set m_EthSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hEth -srcMac] \
                         -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
                         -Offset $EthSrcOffset -ModifierMode DECR -RecycleCount $EthSrcCount -StepValue $EthSrcStep -RepeatCount 0]
                } else {
                    stc::config $m_EthSrcRangeModifierList($streamblock1) -Data [stc::get $hEth -srcMac] \
                        -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
                        -Offset $EthSrcOffset -ModifierMode DECR -RecycleCount $EthSrcCount -StepValue $EthSrcStep -RepeatCount 0
                }
            }
        } elseif {[string tolower $EthSrcMode] =="list"} {
            set index [lsearch $args -ethsrcoffset]
            if {$index == -1} {
               set index [lsearch $args -ethsrcmacoffset]
            }
            if {$index != -1} {
                set EthSrcOffset [lindex $args [expr $index + 1]]
            } else {
                set EthSrcOffset 0
            }
            set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
                set eth_h1 [stc::get $hEth -Name]
                if {$m_EthSrcRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_EthSrcRangeModifierList($streamblock1)
                  set m_EthSrcRangeModifierList($streamblock1) ""
                } 
                if {$m_EthSrcTableModifierList($streamblock1) == ""} {
                     set m_EthSrcTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_EthSrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $eth_h1.srcMac -Offset $EthSrcOffset   -RepeatCount 0]
                } else {
                     stc::config $m_EthSrcTableModifierList($streamblock1) -Data $m_EthSrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $eth_h1.srcMac -Offset $EthSrcOffset -RepeatCount 0
                }
            }
        } elseif  {[string tolower $EthSrcMode] =="fixed"} {
            if {$m_EthSrcRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_EthSrcRangeModifierList($streamblock1)
                  set m_EthSrcRangeModifierList($streamblock1) ""
            }
            if {$m_EthSrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthSrcTableModifierList($streamblock1)
                  set m_EthSrcTableModifierList($streamblock1) ""
            }      
        } else {
            error "Parameter EthSrcMacMode should be fixed/decrement/increment/list."
        }       
    }
    
    #Parse EthDstMacMode/EthDstMacStep/EthDstMacCount/EthDstMacOffset parameter
    set index [lsearch $args -ethdstmode] 
    if {$index == -1} {
        set index [lsearch $args -ethdstmacmode] 
    }
    if {$index != -1} {
        set EthDstMode [lindex $args [expr $index + 1]]        
        if {[string tolower $EthDstMode] =="increment"} {
            set index [lsearch $args -ethdststep]
            if {$index == -1} {
                set index [lsearch $args -ethdstmacstep]
            }
            if {$index != -1} {
                set EthDstStep [lindex $args [expr $index + 1]]
            } else {
                set EthDstStep "00:00:00:00:00:01"
            }
            set index [lsearch $args -ethdstcount]
            if {$index == -1} {
                 set index [lsearch $args -ethdstmaccount]
            }
            if {$index != -1} {
                set EthDstCount [lindex $args [expr $index + 1]]
            } else {
                set EthDstCount 1
            }
            set index [lsearch $args -ethdstoffset]
            if {$index == -1} {
                 set index [lsearch $args -ethdstmacoffset]
            }
            if {$index != -1} {
                set EthDstOffset [lindex $args [expr $index + 1]]
            } else {
                set EthDstOffset 0
            }
           set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
                set eth_h1 [stc::get $hEth -Name]
                if {$m_EthDstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthDstTableModifierList($streamblock1)
                  set m_EthDstTableModifierList($streamblock1) ""
                }
                if {$m_EthDstRangeModifierList($streamblock1) == ""} {
                    set m_EthDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hEth -dstMac] \
                         -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
                         -Offset $EthDstOffset -ModifierMode INCR -RecycleCount $EthDstCount -StepValue $EthDstStep -RepeatCount 0]
                 } else {
                     stc::config $m_EthDstRangeModifierList($streamblock1) -Data [stc::get $hEth -dstMac] \
                         -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
                         -Offset $EthDstOffset -ModifierMode INCR -RecycleCount $EthDstCount -StepValue $EthDstStep -RepeatCount 0
                 }
            }      
        } elseif {[string tolower $EthDstMode] =="decrement"} {
            set index [lsearch $args -ethdststep]
            if {$index == -1} {
                set index [lsearch $args -ethdstmacstep]
            }
            if {$index != -1} {
                set EthDstStep [lindex $args [expr $index + 1]]
            } else {
                set  EthDstStep "00:00:00:00:00:01"
            }
            set index [lsearch $args -ethdstcount]
            if {$index == -1} {
                 set index [lsearch $args -ethdstmaccount]
            }
            if {$index != -1} {
                set EthDstCount [lindex $args [expr $index + 1]]
            } else {
               set EthDstCount 1
            }
            set index [lsearch $args -ethdstoffset]
            if {$index == -1} {
                 set index [lsearch $args -ethdstmacoffset]
            }
            if {$index != -1} {
                set EthDstOffset [lindex $args [expr $index + 1]]
            } else {
                set EthDstOffset 0
            }
            set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
               set eth_h1 [stc::get $hEth -Name]
               if {$m_EthDstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthDstTableModifierList($streamblock1)
                  set m_EthDstTableModifierList($streamblock1) ""
                } 
                if {$m_EthDstRangeModifierList($streamblock1) == ""} {
                  set m_EthDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hEth -dstMac] \
                         -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
                         -Offset $EthDstOffset -ModifierMode DECR -RecycleCount $EthDstCount -StepValue $EthDstStep -RepeatCount 0]
                } else {
                  stc::config $m_EthDstRangeModifierList($streamblock1) -Data [stc::get $hEth -dstMac] \
                         -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
                         -Offset $EthDstOffset -ModifierMode DECR -RecycleCount $EthDstCount -StepValue $EthDstStep -RepeatCount 0
                }
            }
        } elseif {[string tolower $EthDstMode] =="list"} {
            set index [lsearch $args -ethdstoffset]
            if {$index == -1} {
               set index [lsearch $args -ethdstmacoffset]
            }
            if {$index != -1} {
                set EthDstOffset [lindex $args [expr $index + 1]]
            } else {
                set EthDstOffset 0
            }
            set hEthList [GetEthHandle $streamblock1]

            foreach hEth $hEthList {                
                set eth_h1 [stc::get $hEth -Name]
                if {$m_EthDstRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_EthDstRangeModifierList($streamblock1)
                  set m_EthDstRangeModifierList($streamblock1) ""
                }  
                if {$m_EthDstTableModifierList($streamblock1) == ""} {
                     set m_EthDstTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_EthDstTableModifierAddrList($streamblock1) \
                        -OffsetReference $eth_h1.dstMac -Offset $EthDstOffset  -RepeatCount 0]
                } else {
                     stc::config $m_EthDstTableModifierList($streamblock1) -Data $m_EthDstTableModifierAddrList($streamblock1) \
                        -OffsetReference $eth_h1.dstMac -Offset $EthDstOffset -RepeatCount 0
                }
            }
        } elseif  {[string tolower $EthDstMode] =="fixed"} {
            if {$m_EthDstRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_EthDstRangeModifierList($streamblock1)
                  set m_EthDstRangeModifierList($streamblock1) ""
             }
             if {$m_EthDstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_EthDstTableModifierList($streamblock1)
                  set m_EthDstTableModifierList($streamblock1) ""
             } 
        } elseif {[string tolower $EthDstMode] =="autoarp"} {
            #Do nothing at this moment
        } else {
            error "Parameter EthDstMacMode should be fixed/decrement/increment/list."
        }       
    }

    #Parse EthType parameter
    set index [lsearch $args -ethtype] 
    if {$index != -1} {
        set EthType [lindex $args [expr $index + 1]]
        set hEthList [GetEthHandle $streamblock1]
        foreach hEth $hEthList { 
            if {[string tolower $EthType] != "auto"} { 
                stc::config $hEth -etherType $EthType 
            }
        }
    } 
   
    #Parse EthTypeMode parameter
    set index [lsearch $args -ethtypemode] 
    if {$index != -1} {
        set EthTypeMode [lindex $args [expr $index + 1]]
          
        #Parse EthTypeStep parameter
        set index [lsearch $args -ethtypestep] 
        if {$index != -1} {
            set EthTypeStep [lindex $args [expr $index + 1]]
        } else {
            set EthTypeStep 1
        } 

        #Parse EthTypeCount parameter
        set index [lsearch $args -ethtypecount] 
        if {$index != -1} {
            set EthTypeCount [lindex $args [expr $index + 1]]
        } else {
            set EthTypeCount 1
        } 

        if {[string tolower $EthTypeMode] == "increment"} {
            set ModifierMode "INCR"
        } elseif {[string tolower $EthTypeMode] == "decrement"} {
            set ModifierMode "DECR"
        } else {
            set ModifierMode "FIXED"
        }
 
        set hEthList [GetEthHandle $streamblock1]
        foreach hEth $hEthList {
            if {$ModifierMode == "INCR" || $ModifierMode == "DECR" } {
                set eth_h1 [stc::get $hEth -Name]
                set myEthType [stc::get $hEth -etherType]
                if {$m_EthTypeRangeModifierList($streamblock1) == ""} {
                    set ethTypeModifier [stc::create RangeModifier -under $streamblock1 -Data $myEthType \
                        -Mask "FFFF" -OffsetReference $eth_h1.etherType \
                        -Offset 0 -ModifierMode $ModifierMode -RecycleCount $EthTypeCount -StepValue $EthTypeStep -RepeatCount 0]

                    set m_EthTypeRangeModifierList($streamblock1) $ethTypeModifier
                } else {
                    stc::config $m_EthTypeRangeModifierList($streamblock1) -Data $myEthType \
                        -Mask "FFFF" -OffsetReference $eth_h1.etherType \
                        -Offset 0 -ModifierMode $ModifierMode -RecycleCount $EthTypeCount -StepValue $EthTypeStep -RepeatCount 0
                }
            } else {
                if {$m_EthTypeRangeModifierList($streamblock1) != ""} {
                    stc::delete $m_EthTypeRangeModifierList($streamblock1)
                    set m_EthTypeRangeModifierList($streamblock1) ""
                }
            }
        } 
    } 

    #################Layer 2 parameters#######################

}

############################################################################
#APIName: ConfigIPV4StreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::ConfigIPV4StreamParameters {streamblock1 args} {
    set args [eval subst $args ]
     
    #Parse StreamType parameter
    set index [lsearch $args -streamtype] 
    if {$index != -1} {
        set StreamType [lindex $args [expr $index + 1]]
    } else {
        set StreamType "Normal"
    } 

   #################IP parameter configuration#######################
    
    #Parse IpSrcAddr parameter
    set index [lsearch $args -ipsrcaddr] 
    if {$index != -1} {
        set IpSrcAddr [lindex $args [expr $index + 1]]

        #Add support for MplsVPN bounding
        if {[string tolower $StreamType ] == "vpn"} {
             if {[info exists ::mainDefine::gIpv4NetworkBlock($IpSrcAddr)]} {
                 catch {
                     set hSrcIpv4NetworkBlock $::mainDefine::gIpv4NetworkBlock($IpSrcAddr)
                     stc::config $streamblock1 -SrcBinding-targets " $hSrcIpv4NetworkBlock "
                     set IpSrcAddr [stc::get $hSrcIpv4NetworkBlock -StartIpList]
                }
            }
        }

        set hIPv4List [GetIPv4Handle $streamblock1]

        #判断输入地址是否为列表形式
        set m_Ipv4SrcTableModifierAddrList($streamblock1) $IpSrcAddr
        set IpSrcAddr [lindex $IpSrcAddr 0]
        
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -sourceAddr $IpSrcAddr
        }
    }
    
    #Parse IpDstAddr parameter
    set index [lsearch $args -ipdstaddr] 
    if {$index != -1} {
        set IpDstAddr [lindex $args [expr $index + 1]]

        #Add support for MplsVPN bounding
        if {[string tolower $StreamType ] == "vpn"} {
           if {[info exists ::mainDefine::gIpv4NetworkBlock($IpDstAddr)]} {
                 catch {
                     set hDstIpv4NetworkBlock $::mainDefine::gIpv4NetworkBlock($IpDstAddr)
                     stc::config $streamblock1 -DstBinding-targets " $hDstIpv4NetworkBlock "
                     set IpDstAddr [stc::get $hSrcIpv4NetworkBlock -StartIpList]
                }
            }
        }

        set hIPv4List [GetIPv4Handle $streamblock1]

        #判断输入地址是否为列表形式
        set m_Ipv4DstTableModifierAddrList($streamblock1) $IpDstAddr
        set IpDstAddr [lindex $IpDstAddr 0]
         
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -destAddr $IpDstAddr
        }     
    }
    
    #Parse IpIdentifier parameter
    set index [lsearch $args -ipidentifier] 
    if {$index != -1} {
        set IpIdentifier [lindex $args [expr $index + 1]]
        
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -identification $IpIdentifier
        }
    }
    
    #Parse IpTtl parameter
    set index [lsearch $args -ipttl] 
    if {$index != -1} {
        set IpTttl [lindex $args [expr $index + 1]]

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -ttl $IpTttl
        }
    }
    
    #Parse IpPrecedence/IpDelay/IpThroughput/IpReliability/IpCost parameter
    set index [lsearch $args -ipprecedence] 
    if {$index != -1} {
        set IpPrecedence [lindex $args [expr $index + 1]]

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-tosDiffserv] !=""} {
                set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            } else {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
            
            if {[stc::get $tosDiffserv1 -children-tos] !=""} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]                
            } else {
                set tos1 [stc::create tos -under $tosDiffserv1]
            }

            if {$IpPrecedence >= "0" && $IpPrecedence <= "9"} {
                 stc::config $tos1 -precedence $IpPrecedence
            } else { 
                if {[string tolower $IpPrecedence] == "priority"} {
                    stc::config $tos1 -precedence 1
                } elseif {[string tolower $IpPrecedence] == "immediate"} {
                    stc::config $tos1 -precedence 2 
                } elseif {[string tolower $IpPrecedence] == "flash"} {
                    stc::config $tos1 -precedence 3
                } elseif {[string tolower $IpPrecedence] == "flash_override"} {
                    stc::config $tos1 -precedence 4
                } elseif {[string tolower $IpPrecedence] == "critical "} {
                    stc::config $tos1 -precedence 5
                } elseif {[string tolower $IpPrecedence] == "internetwork_control"} {
                    stc::config $tos1 -precedence 6
                } elseif {[string tolower $IpPrecedence] == "network_control"} {
                    stc::config $tos1 -precedence 7
                } else {
                    stc::config $tos1 -precedence 0
                } 
            }  
        }
    }
    set index [lsearch $args -ipdelay]
    if {$index != -1} {
        set IpDelay [lindex $args [expr $index + 1]]
         
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-tosDiffserv] !=""} {
                set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            } else {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
            
            if {[stc::get $tosDiffserv1 -children-tos] !=""} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]                
            } else {
                set tos1 [stc::create tos -under $tosDiffserv1]
            }
        
            if {[string tolower $IpDelay] =="lowdelay"} {
                stc::config $tos1 -dBit 1
            } else {
                stc::config $tos1 -dBit 0
            }
        }
    }
    set index [lsearch $args -ipthroughput]
    if {$index != -1} {
        set IpThroughput [lindex $args [expr $index + 1]]

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-tosDiffserv] !=""} {
                set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            } else {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
            
            if {[stc::get $tosDiffserv1 -children-tos] !=""} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]                
            } else {
                set tos1 [stc::create tos -under $tosDiffserv1]
            }
        
            if {[string tolower $IpThroughput] =="highthruput"} {
                stc::config $tos1 -tBit 1
            } else {
                stc::config $tos1 -tBit 0
            }
        }
    }
    
    set index [lsearch $args -ipreliability]
    if {$index != -1} {
        set IpReliability [lindex $args [expr $index + 1]]

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-tosDiffserv] !=""} {
                set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            } else {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
            
            if {[stc::get $tosDiffserv1 -children-tos] !=""} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]                
            } else {
                set tos1 [stc::create tos -under $tosDiffserv1]
            }
        
            if {[string tolower $IpReliability] =="highreliability"} {
                stc::config $tos1 -rBit 1
            } else {
                stc::config $tos1 -rBit 0
            }
         }
    }
    
    set index [lsearch $args -ipcost]
    if {$index != -1} {
        set IpCost [lindex $args [expr $index + 1]]
         
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-tosDiffserv] !=""} {
                set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            } else {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
            
            if {[stc::get $tosDiffserv1 -children-tos] !=""} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]                
            } else {
                set tos1 [stc::create tos -under $tosDiffserv1]
            }
        
            if {[string tolower $IpCost] =="lowcost"} {
                stc::config $tos1 -mBit 1
            } else {
                stc::config $tos1 -mBit 0
            }
        }
    }
  
    #Parse iptotalLength/IpLengthOverride parameter
    set index [lsearch $args -iptotallength] 
    if {$index != -1} {
        set totalLength [lindex $args [expr $index + 1]]
         
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            set index [lsearch $args -iplengthoverride] 
            if {$index != -1} {
                set IpLengthOverride [lindex $args [expr $index + 1]]
                if {[string tolower $IpLengthOverride] == "true"} {
                    stc::config $hIpv4 -totalLength $totalLength
                 } else {
                    puts "When IpLengthOverride is $IpLengthOverride, the parameter totalLength is invalid."
                 }                            
            } else {
                puts "When parameter IpLengthOverride is null, the parameter totalLength is invalid."
            }            
        }
    }
    
    #Parse IpFragmentOffset parameter
    set index [lsearch $args -ipfragmentoffset] 
    if {$index != -1} {
        set IpFragmentOffset [lindex $args [expr $index + 1]]
         
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -fragOffset $IpFragmentOffset
        }
    }
    
    #Parse IpFragment parameter
    set index [lsearch $args -ipfragment] 
    if {$index != -1} {
        set IpFragment [lindex $args [expr $index + 1]]

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-flags] !=""} {
                set flag1 [stc::get $hIpv4 -children-flags]                
            } else {
                set flag1 [stc::create flags -under $hIpv4]
            }    
            if {[string tolower $IpFragment] == "true"} {
                stc::config $flag1 -dfBit 1 
            } else {
                stc::config $flag1 -dfBit 0
            }            
        }
    }
    
    #Parse IpLastFragment parameter
    set index [lsearch $args -iplastfragment] 
    if {$index != -1} {
        set IpLastFragment [lindex $args [expr $index + 1]]
         
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            if {[stc::get $hIpv4 -children-flags] !=""} {
                set flag1 [stc::get $hIpv4 -children-flags]                
            } else {
                set flag1 [stc::create flags -under $hIpv4]
            }    
            if {[string tolower $IpLastFragment] == "true"} {
                stc::config $flag1 -mfBit 1 
            } else {
                stc::config $flag1 -mfBit 0
            }            
        }
    }
    
    #Parse IpProtocolType parameter
    set index [lsearch $args -ipprotocoltype] 
    if {$index != -1} {
        set IpProtocolType [lindex $args [expr $index + 1]]
        if {[string tolower $IpProtocolType] =="tcp"} {
           set IpProtocolType 6
        } elseif {[string tolower $IpProtocolType] =="udp"} {
           set IpProtocolType 17
        } elseif {[string tolower $IpProtocolType] =="icmp"} {
           set IpProtocolType 1
        } elseif {[string tolower $IpProtocolType] =="igmp"} {
           set IpProtocolType 2
        }

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            stc::config $hIpv4 -protocol $IpProtocolType
        }
    }
    
    #Parse IpSrcAddrMode/IpSrcMask/IpSrcAddrCount/IpSrcAddrStep parameter
    set index [lsearch $args -ipsrcaddrmode] 
    if {$index != -1} {
        set IpSrcAddrMode [lindex $args [expr $index + 1]]        
        if {[string tolower $IpSrcAddrMode] =="increment"} {
            set index [lsearch $args -ipsrcaddrstep]
            if {$index != -1} {
                set IpSrcAddrStep [lindex $args [expr $index + 1]]
            } else {
                set IpSrcAddrStep  "0.0.0.1"
            }
            set index [lsearch $args -ipsrcaddrcount]
            if {$index != -1} {
                set IpSrcAddrCount [lindex $args [expr $index + 1]]
            } else {
                set IpSrcAddrCount 1
            }
            set index [lsearch $args -ipsrcmask]
            if {$index != -1} {
                set IpSrcMask [lindex $args [expr $index + 1]]
            } else {
                set IpSrcMask "255.255.255.255"
            }

            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4SrcTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4SrcTableModifierList($streamblock1)
                   set m_Ipv4SrcTableModifierList($streamblock1) ""
                }
                if {$m_Ipv4SrcRangeModifierList($streamblock1) == ""} { 
                    set m_Ipv4SrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv4 -sourceAddr] \
                         -Mask 255.255.255.255  -OffsetReference $ip1.sourceAddr -StepValue $IpSrcAddrStep \
                         -Offset 0 -ModifierMode INCR -RecycleCount $IpSrcAddrCount -RepeatCount 0] 
                } else {
                     stc::config $m_Ipv4SrcRangeModifierList($streamblock1) -Data [stc::get $hIpv4 -sourceAddr] \
                          -Mask 255.255.255.255  -OffsetReference $ip1.sourceAddr -StepValue $IpSrcAddrStep \
                          -Offset 0 -ModifierMode INCR -RecycleCount $IpSrcAddrCount -RepeatCount 0 
                }
            }        
        } elseif {[string tolower $IpSrcAddrMode] =="decrement"} {
            set index [lsearch $args -ipsrcaddrstep]
            if {$index != -1} {
                set IpSrcAddrStep [lindex $args [expr $index + 1]]
            } else {
                set IpSrcAddrStep "0.0.0.1"
            }
            set index [lsearch $args -ipsrcaddrcount]
            if {$index != -1} {
                set IpSrcAddrCount [lindex $args [expr $index + 1]]
            } else {
                set IpSrcAddrCount 1
            }
            set index [lsearch $args -ipsrcmask]
            if {$index != -1} {
                set IpSrcMask [lindex $args [expr $index + 1]]
            } else {
                set IpSrcMask "255.255.255.255"
            }
             
            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4SrcTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4SrcTableModifierList($streamblock1)
                   set m_Ipv4SrcTableModifierList($streamblock1) ""
                }
                if {$m_Ipv4SrcRangeModifierList($streamblock1) == ""} { 
                    set m_Ipv4SrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv4 -sourceAddr] \
                         -Mask 255.255.255.255  -OffsetReference $ip1.sourceAddr -StepValue $IpSrcAddrStep \
                         -Offset 0 -ModifierMode DECR -RecycleCount $IpSrcAddrCount -RepeatCount 0] 
                } else {
                     stc::config $m_Ipv4SrcRangeModifierList($streamblock1) -Data [stc::get $hIpv4 -sourceAddr] \
                          -Mask 255.255.255.255  -OffsetReference $ip1.sourceAddr -StepValue $IpSrcAddrStep \
                          -Offset 0 -ModifierMode DECR -RecycleCount $IpSrcAddrCount -RepeatCount 0 
                }
            }
        } elseif {[string tolower $IpSrcAddrMode] =="list"} {

            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4SrcRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4SrcRangeModifierList($streamblock1)
                   set m_Ipv4SrcRangeModifierList($streamblock1) ""
                }
                if {$m_Ipv4SrcTableModifierList($streamblock1) == ""} { 
                    set m_Ipv4SrcTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_Ipv4SrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip1.sourceAddr -Offset 0 -RepeatCount 0] 
                } else {
                     stc::config $m_Ipv4SrcTableModifierList($streamblock1) -Data $m_Ipv4SrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip1.sourceAddr -Offset 0 -RepeatCount 0
                }
            }
        } elseif  {[string tolower $IpSrcAddrMode] =="fixed"} {
              if {$m_Ipv4SrcRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4SrcRangeModifierList($streamblock1)
                   set m_Ipv4SrcRangeModifierList($streamblock1) ""
              }
              if {$m_Ipv4SrcTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4SrcTableModifierList($streamblock1)
                   set m_Ipv4SrcTableModifierList($streamblock1) ""
              }
        
        } else {
            error "Parameter IpSrcAddrMode should be fixed/decrement/increment/list."
        }       
    }
    
    #Parse IpDstAddrMode/IpDstMask/IpDstAddrCount/IpDstAddrStep parameter
    set index [lsearch $args -ipdstaddrmode] 
    if {$index != -1} {
        set IpDstAddrMode [lindex $args [expr $index + 1]]        
        if {[string tolower $IpDstAddrMode] =="increment"} {
            set index [lsearch $args -ipdstaddrstep]
            if {$index != -1} {
                set IpDstAddrStep [lindex $args [expr $index + 1]]
            } else {
                set IpDstAddrStep "0.0.0.1"
            }
            set index [lsearch $args -ipdstaddrcount]
            if {$index != -1} {
                set IpDstAddrCount [lindex $args [expr $index + 1]]
            } else {
                set IpDstAddrCount 1
            }
            set index [lsearch $args -ipdstmask]
            if {$index != -1} {
                set IpDstMask [lindex $args [expr $index + 1]]
            } else {
                set IpDstMask "255.255.255.255"
            }

            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4DstTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4DstTableModifierList($streamblock1)
                   set m_Ipv4DstTableModifierList($streamblock1) ""
                }
               if {$m_Ipv4DstRangeModifierList($streamblock1) == ""} {
                   set m_Ipv4DstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv4 -destAddr] \
                        -Mask 255.255.255.255  -OffsetReference $ip1.destAddr -StepValue $IpDstAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $IpDstAddrCount -RepeatCount 0] 
                } else {
                     stc::config  $m_Ipv4DstRangeModifierList($streamblock1) -Data [stc::get $hIpv4 -destAddr] \
                        -Mask 255.255.255.255  -OffsetReference $ip1.destAddr -StepValue $IpDstAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $IpDstAddrCount -RepeatCount 0
                }
            }        
        } elseif {[string tolower $IpDstAddrMode] =="decrement"} {
            set index [lsearch $args -ipdstaddrstep]
            if {$index != -1} {
                set IpDstAddrStep [lindex $args [expr $index + 1]]
            } else {
                set IpDstAddrStep "0.0.0.1"
            }
            set index [lsearch $args -ipdstaddrcount]
            if {$index != -1} {
                set IpDstAddrCount [lindex $args [expr $index + 1]]
            } else {
               set IpDstAddrCount 1
            }
            set index [lsearch $args -ipdstmask]
            if {$index != -1} {
                set IpDstMask [lindex $args [expr $index + 1]]
            } else {
                set IpDstMask "255.255.255.255"
            }
             
            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4DstTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4DstTableModifierList($streamblock1)
                   set m_Ipv4DstTableModifierList($streamblock1) ""
                }
                if {$m_Ipv4DstRangeModifierList($streamblock1) == ""} {
                   set m_Ipv4DstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv4 -destAddr] \
                        -Mask 255.255.255.255  -OffsetReference $ip1.destAddr -StepValue $IpDstAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $IpDstAddrCount -RepeatCount 0] 
                } else {
                     stc::config  $m_Ipv4DstRangeModifierList($streamblock1) -Data [stc::get $hIpv4 -destAddr] \
                        -Mask 255.255.255.255  -OffsetReference $ip1.destAddr -StepValue $IpDstAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $IpDstAddrCount -RepeatCount 0
                } 
            }
        } elseif {[string tolower $IpDstAddrMode] =="list"} {

            set hIPv4List [GetIPv4Handle $streamblock1]
            foreach hIpv4 $hIPv4List {
                set ip1 [stc::get $hIpv4 -Name]
                if {$m_Ipv4DstRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4DstRangeModifierList($streamblock1)
                   set m_Ipv4DstRangeModifierList($streamblock1) ""
                }
                if {$m_Ipv4DstTableModifierList($streamblock1) == ""} { 
                    set m_Ipv4DstTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_Ipv4DstTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip1.destAddr -Offset 0 -RepeatCount 0] 
                } else {
                     stc::config $m_Ipv4DstTableModifierList($streamblock1) -Data $m_Ipv4DstTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip1.destAddr -Offset 0 -RepeatCount 0
                }
            }
        } elseif  {[string tolower $IpDstAddrMode] =="fixed"} {
             if {$m_Ipv4DstRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4DstRangeModifierList($streamblock1)
                   set m_Ipv4DstRangeModifierList($streamblock1) ""
             }
             if {$m_Ipv4DstTableModifierList($streamblock1) != ""} {
                   stc::delete $m_Ipv4DstTableModifierList($streamblock1)
                   set m_Ipv4DstTableModifierList($streamblock1) ""
             }        
        } else {
            error "Parameter IpDstAddrMode should be fixed/decrement/increment/list."
        }       
    }
    set qosValueExist "FALSE"
    #Ip Qos type，tos/dscp i.e -IpqosMode tos 
    set index [lsearch $args -ipqosmode] 
    if {$index != -1} {
        set qosMode [lindex $args [expr $index + 1]]
        set qosValueExist "TRUE"
    } else {
        set qosMode "dscp"
    } 

    set index [lsearch $args -ipqosvalue]
    if {$index != -1} {
        set qosValue [lindex $args [expr $index + 1]]
        set qosValueExist "TRUE"
    } else {
        set qosValue 0
    }

    if {$qosValueExist == "TRUE"} {

        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            set tosDiffserv1 [stc::get $hIpv4 -children-tosDiffserv]
            if {$tosDiffserv1 == "" } {
                set tosDiffserv1 [stc::create tosDiffserv -under $hIpv4]
            }
    
            if {[string tolower $qosMode]== "tos"} {
                set tos1 [stc::get $tosDiffserv1 -children-tos]
                if {$tos1 == ""} {
                    set tos1 [stc::create tos -under $tosDiffserv1]
                }
      
                set tosString ""
                set tosValue $qosValue    
                for {set i 1} {$i <=8} {incr i} {
                    set rInt [expr $tosValue%2]
                    set tosValue [expr $tosValue/2]
                    lappend tosString $rInt
                }

                set precedence [expr [lindex $tosString 7]*4 +[lindex $tosString 6]*2+[lindex $tosString 5]]
                stc::config $tos1 -precedence $precedence

                set dBit [lindex $tosString 4]
                set tBit [lindex $tosString 3]
                set rBit [lindex $tosString 2]
                set mBit [lindex $tosString 1]
                set reserved [lindex $tosString 0]
                stc::config $tos1 -dBit $dBit -tBit $tBit -rBit $rBit -mBit $mBit -reserved $reserved
            } elseif {[string tolower $qosMode] == "dscp" } {
                set diffServ1 [stc::get $tosDiffserv1 -children-diffServ]
                if {$diffServ1 == ""} {
                    set diffServ1 [stc::create diffServ -under $tosDiffserv1]
                }
     
                set idscpValue [format %d $qosValue]
                set dscpString ""
                for {set i 1} {$i <=8} {incr i} {
                    set rInt [expr $idscpValue%2]
                    set idscpValue [expr $idscpValue/2]
                    lappend dscpString $rInt
                }
                set dscpLow [expr [lindex $dscpString 0]+[lindex $dscpString 1]*2+[lindex $dscpString 2]*4]
                set dscpHigh [expr [lindex $dscpString 3]+[lindex $dscpString 4]*2+[lindex $dscpString 5]*4]
                stc::config $diffServ1 -dscpHigh $dscpHigh -dscpLow $dscpLow   
            } 
        }
    }

    #Parse ipProtocolMode parameter
    set index [lsearch $args -ipprotocolmode] 
    if {$index != -1} {
        set ipProtocolMode [lindex $args [expr $index + 1]]
          
        #Parse ipProtocolStep parameter
        set index [lsearch $args -ipprotocolstep] 
        if {$index != -1} {
            set ipProtocolStep [lindex $args [expr $index + 1]]
        } else {
            set ipProtocolStep 1
        } 

        #Parse ipProtocolCount parameter
        set index [lsearch $args -ipprotocolcount] 
        if {$index != -1} {
            set IpProtocolCount [lindex $args [expr $index + 1]]
        } else {
            set IpProtocolCount 1
        } 

        if {[string tolower $ipProtocolMode] == "increment"} {
            set ModifierMode "INCR"
        } elseif {[string tolower $ipProtocolMode] == "decrement"} {
            set ModifierMode "DECR"
        } else {
            set ModifierMode "FIXED"
        }
 
        set hIPv4List [GetIPv4Handle $streamblock1]
        foreach hIpv4 $hIPv4List {
            set ip1 [stc::get $hIpv4 -Name]
            set myProtocolType [stc::get $hIpv4 -protocol]
            if {$ModifierMode == "INCR" || $ModifierMode == "DECR" } {
                if {$m_Ipv4TypeRangeModifierList($streamblock1) == ""} {
                    set ipv4TypeModifier [stc::create RangeModifier -under $streamblock1 -Data $myProtocolType \
                        -Mask 255 -OffsetReference $ip1.protocol \
                        -Offset 0 -ModifierMode $ModifierMode -RecycleCount $IpProtocolCount -StepValue $ipProtocolStep -RepeatCount 0]

                    set m_Ipv4TypeRangeModifierList($streamblock1) $ipv4TypeModifier
                } else {
                    stc::config $m_Ipv4TypeRangeModifierList($streamblock1) -Data $myProtocolType \
                        -Mask 255 -OffsetReference $ip1.protocol \
                        -Offset 0 -ModifierMode $ModifierMode -RecycleCount $IpProtocolCount -StepValue $ipProtocolStep -RepeatCount 0
                } 
            } else {
                if {$m_Ipv4TypeRangeModifierList($streamblock1) != ""} {
                    stc::delete $m_Ipv4TypeRangeModifierList($streamblock1)
                    set m_Ipv4TypeRangeModifierList($streamblock1) ""
                }
            }
        } 
    } 

    #Set the gateway of IPv4 header if needed
    set index [lsearch $args -ethdstmode] 
    if {$index == -1} {
        set index [lsearch $args -ethdstmacmode] 
    }
    if {$index != -1} {
        set EthDstMode [lindex $args [expr $index + 1]] 

        if {[string tolower $EthDstMode] == "autoarp"} {
            set hostHandleList [stc::get $m_hPort -AffiliatedPortSource]
            set hostHandle [lindex $hostHandleList 0]
            if {$hostHandle != ""} { 
                set ipv4If [stc::get $hostHandle -TopLevelIf]
                if {$ipv4If != ""} {
                    set gatewayIp [stc::get $ipv4If -Gateway]
                    debugPut "The gateway address of Host: $hostHandle is $gatewayIp"
                    set hIPv4List [GetIPv4Handle $streamblock1] 
                    foreach hIpv4 $hIPv4List { 
                        stc::config $hIpv4 -Gateway $gatewayIp
                    }
                    set ::mainDefine::gStreamBindingFlag "TRUE"  
                }
            }
        }
    }
    #################IP Parameter configuration#######################
    
}

############################################################################
#APIName: ConfigTcpStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigTcpStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################TCP parameter configuration#######################
    
    #Parse TcpSrcPort parameter
    set index [lsearch $args -tcpsrcport] 
    if {$index != -1} {
        set TcpSrcPort [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -sourcePort $TcpSrcPort
        }
    }
    
    #Parse TcpDstPort parameter
    set index [lsearch $args -tcpdstport] 
    if {$index != -1} {
        set TcpDstPort [lindex $args [expr $index + 1]]
         
        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -destPort $TcpDstPort 
        }
    }
    
    #Parse TcpAcknowledgementNumber parameter
    set index [lsearch $args -tcpacknowledgementnumber] 
    if {$index != -1} {
        set TcpAcknowledgementNumber [lindex $args [expr $index + 1]]
         
        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -ackNum $TcpAcknowledgementNumber 
        }
    }
    
    #Parse TcpSequenceNumber parameter
    set index [lsearch $args -tcpsequencenumber] 
    if {$index != -1} {
        set TcpSequenceNumber [lindex $args [expr $index + 1]]
         
        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -seqNum $TcpSequenceNumber 
        }
    }
    
    #Parse TcpWindow parameter
    set index [lsearch $args -tcpwindow] 
    if {$index != -1} {
        set TcpWindow [lindex $args [expr $index + 1]]
        
        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -window $TcpWindow 
        }
    }
    
    #Parse TcpUrgentPointer parameter
    set index [lsearch $args -tcpurgentpointer] 
    if {$index != -1} {
        set TcpUrgentPointer [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            stc::config $hTcp -urgentPtr $TcpUrgentPointer 
        }
    }
    
    #Parse TcpSrcPortMode/TcpSrcPortCount/TcpSrcPortStep parameter
    set index [lsearch $args -tcpsrcportmode] 
    if {$index != -1} {
        set TcpSrcPortMode [lindex $args [expr $index + 1]]        
        if {[string tolower $TcpSrcPortMode] =="increment"} {
            set index [lsearch $args -tcpsrcportstep]
            if {$index != -1} {
                set TcpSrcPortStep [lindex $args [expr $index + 1]]
            } else {
                set TcpSrcPortStep 1
            }
            set index [lsearch $args -tcpsrcportcount]
            if {$index != -1} {
                set TcpSrcPortCount [lindex $args [expr $index + 1]]
            } else {
                set TcpSrcPortCount 1
            }
            
            set hTCPList [GetTCPHandle $streamblock1]
            foreach hTcp $hTCPList {
                set tcp_1 [stc::get $hTcp -Name]
                if {$m_TcpSrcRangeModifierList($streamblock1) == ""} {
                         set m_TcpSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hTcp -sourcePort] \
                                -Mask 0xFFFF  -OffsetReference $tcp_1.sourcePort -StepValue $TcpSrcPortStep \
                               -Offset 0 -ModifierMode INCR -RecycleCount $TcpSrcPortCount -RepeatCount 0]
                 } else {
                        stc::config  $m_TcpSrcRangeModifierList($streamblock1) -Data [stc::get $hTcp -sourcePort] \
                                -Mask 0xFFFF  -OffsetReference $tcp_1.sourcePort -StepValue $TcpSrcPortStep \
                               -Offset 0 -ModifierMode INCR -RecycleCount $TcpSrcPortCount -RepeatCount 0
                 } 
            }        
        } elseif {[string tolower $TcpSrcPortMode] =="decrement"} {
            set index [lsearch $args -tcpsrcportstep]
            if {$index != -1} {
                set TcpSrcPortStep [lindex $args [expr $index + 1]]
            } else {
                set TcpSrcPortStep 1
            }
            set index [lsearch $args -tcpsrcportcount]
            if {$index != -1} {
                set TcpSrcPortCount [lindex $args [expr $index + 1]]
            } else {
                set TcpSrcPortCount 1
            }

            set hTCPList [GetTCPHandle $streamblock1]
            foreach hTcp $hTCPList {
                set tcp_1 [stc::get $hTcp -Name]
                if {$m_TcpSrcRangeModifierList($streamblock1) == ""} {
                         set m_TcpSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hTcp -sourcePort] \
                                -Mask 0xFFFF  -OffsetReference $tcp_1.sourcePort -StepValue $TcpSrcPortStep \
                               -Offset 0 -ModifierMode DECR -RecycleCount $TcpSrcPortCount -RepeatCount 0]
                 } else {
                        stc::config  $m_TcpSrcRangeModifierList($streamblock1) -Data [stc::get $hTcp -sourcePort] \
                                -Mask 0xFFFF  -OffsetReference $tcp_1.sourcePort -StepValue $TcpSrcPortStep \
                               -Offset 0 -ModifierMode DECR -RecycleCount $TcpSrcPortCount -RepeatCount 0
                 }
            }
        } elseif  {[string tolower $TcpSrcPortMode] =="fixed"} {
              if {$m_TcpSrcRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_TcpSrcRangeModifierList($streamblock1) 
                   set m_TcpSrcRangeModifierList($streamblock1) ""
              } 
        
        } else {
            error "Parameter TcpSrcPortMode should be fixed/decrement/increment."
        }       
    }
    
    
    #Parse TcpDstPortMode/TcpDstPortCount/TcpDstPortStep parameter
    set index [lsearch $args -tcpdstportmode] 
    if {$index != -1} {
        set TcpDstPortMode [lindex $args [expr $index + 1]]        
        if {[string tolower $TcpDstPortMode] =="increment"} {
            set index [lsearch $args -tcpdstportstep]
            if {$index != -1} {
                set TcpDstPortStep [lindex $args [expr $index + 1]]
            } else {
                set TcpDstPortStep 1
            }
            set index [lsearch $args -tcpdstportcount]
            if {$index != -1} {
                set TcpDstPortCount [lindex $args [expr $index + 1]]
            } else {
                set TcpDstPortCount 1
            }
            set hTCPList [GetTCPHandle $streamblock1]

            foreach hTcp $hTCPList {
                set tcp_1 [stc::get $hTcp -Name]
                if {$m_TcpDstRangeModifierList($streamblock1) == ""} {
                       set m_TcpDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hTcp -destPort] \
                              -Mask 0xFFFF  -OffsetReference $tcp_1.destPort -StepValue $TcpDstPortStep \
                              -Offset 0 -ModifierMode INCR -RecycleCount $TcpDstPortCount -RepeatCount 0 ] 
                 } else {
                       stc::config  $m_TcpDstRangeModifierList($streamblock1) -Data [stc::get $hTcp -destPort] \
                              -Mask 0xFFFF  -OffsetReference $tcp_1.destPort -StepValue $TcpDstPortStep \
                              -Offset 0 -ModifierMode INCR -RecycleCount $TcpDstPortCount -RepeatCount 0 
                 }
            }     
        } elseif {[string tolower $TcpDstPortMode] =="decrement"} {
            set index [lsearch $args -tcpdstportstep]
            if {$index != -1} {
                set TcpDstPortStep [lindex $args [expr $index + 1]]
            } else {
               set TcpDstPortStep  1
            }
            set index [lsearch $args -tcpdstportcount]
            if {$index != -1} {
                set TcpDstPortCount [lindex $args [expr $index + 1]]
            } else {
               set TcpDstPortCount  1
            }

            set hTCPList [GetTCPHandle $streamblock1]
            foreach hTcp $hTCPList {
                set tcp_1 [stc::get $hTcp -Name]
       
                if {$m_TcpDstRangeModifierList($streamblock1) == ""} {
                           set m_TcpDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hTcp -destPort] \
                            -Mask 0xFFFF  -OffsetReference $tcp_1.destPort -StepValue $TcpDstPortStep \
                           -Offset 0 -ModifierMode DECR -RecycleCount $TcpDstPortCount -RepeatCount 0 ]
                 } else {
                          stc::config  $m_TcpDstRangeModifierList($streamblock1) -Data [stc::get $hTcp -destPort] \
                              -Mask 0xFFFF  -OffsetReference $tcp_1.destPort -StepValue $TcpDstPortStep \
                              -Offset 0 -ModifierMode DECR -RecycleCount $TcpDstPortCount -RepeatCount 0
                 }
            }
        } elseif  {[string tolower $TcpDstPortMode] =="fixed"} {
              if {$m_TcpDstRangeModifierList($streamblock1) != ""} {
                   stc::delete $m_TcpDstRangeModifierList($streamblock1) 
                   set m_TcpDstRangeModifierList($streamblock1) ""
              } 

        
        } else {
            error "Parameter TcpDstPortMode should be fixed/decrement/increment."
        }       
    }
    
    #Parse TcpFlagURG parameter
    set index [lsearch $args -tcpflagurg] 
    if {$index != -1} {
        set TcpFlagURG [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagURG] == "false"} {
                  stc::config $hTcp -urgBit 0
            } else {
                  stc::config $hTcp -urgBit 1
            }
        }
    }
    
    #Parse TcpFlagURG parameter
    set index [lsearch $args -tcpflagack] 
    if {$index != -1} {
        set TcpFlagACk [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagACk] == "false"} {
                 stc::config $hTcp -ackBit 0
             } else {
                 stc::config $hTcp -ackBit 1
             }
        }
    }
    
    #Parse TcpFlagPSH parameter
    set index [lsearch $args -tcpflagpsh] 
    if {$index != -1} {
        set TcpFlagPSH [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagPSH] == "false"} {
                stc::config $hTcp -pshBit 0
            } else {
                stc::config $hTcp -pshBit 1
            }
        }
    }
    
    #Parse TcpFlagRST parameter
    set index [lsearch $args -tcpflagrst] 
    if {$index != -1} {
        set TcpFlagRST [lindex $args [expr $index + 1]]
        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagRST] == "false"} {
               stc::config $hTcp -rstBit 0
            } else {
               stc::config $hTcp -rstBit 1
            }
        }
    }
    
    #Parse TcpFlagSYC parameter
    set index [lsearch $args -tcpflagsyc] 
    if {$index != -1} {
        set TcpFlagSYC [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagSYC] == "false"} {
                stc::config $hTcp -synBit 0
            } else {
                stc::config $hTcp -synBit 1
            }
        }
    }
    
    #Parse TcpFlagFIN parameter
    set index [lsearch $args -tcpflagfin] 
    if {$index != -1} {
        set TcpFlagFIN [lindex $args [expr $index + 1]]

        set hTCPList [GetTCPHandle $streamblock1]
        foreach hTcp $hTCPList {
            if {[string tolower $TcpFlagFIN] == "false"} {
                stc::config $hTcp -finBit 0
            } else {
                stc::config $hTcp -finBit 1
            }
        }
    }
    
    #Parse TcpFlagChecksum/TcpChecksum parameter
    set index [lsearch $args -tcpflagchecksum] 
    if {$index != -1} {
        set TcpFlagChecksum [lindex $args [expr $index + 1]]
        if {[string tolower $TcpFlagChecksum] == "false"} {
            set index [lsearch $args -tcpchecksum]
            if {$index != -1} {
                set TcpChecksum [lindex $args [expr $index + 1]]

                set hTCPList [GetTCPHandle $streamblock1]
                foreach hTcp $hTCPList {
                    stc::config $hTcp -checksum $TcpChecksum
                }
            } else {
                    error "Parameter TcpChecksum is necessary when TcpFlagChecksum is $TcpFlagChecksum."
            }
        }
    }
    
    #################TCP parameter configuration#######################
}

############################################################################
#APIName: ConfigUdpStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigUdpStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################UDP parameter configuration#######################
    
    #Parse UdpSrcPort parameter
    set index [lsearch $args -udpsrcport] 
    if {$index != -1} {
        set UdpSrcPort [lindex $args [expr $index + 1]]

        set hUDPList [GetUDPHandle $streamblock1]
        foreach hUdp $hUDPList {
            stc::config $hUdp -sourcePort $UdpSrcPort
        }
    }
    
    #Parse UdpDstPort parameter
    set index [lsearch $args -udpdstport] 
    if {$index != -1} {
        set UdpDstPort [lindex $args [expr $index + 1]]

        set hUDPList [GetUDPHandle $streamblock1]
        foreach hUdp $hUDPList {
            stc::config $hUdp -destPort $UdpDstPort 
        }
    }
    
    #Parse UdpSrcPortMode/UdpSrcPortCount/UdpSrcStep parameter
    set index [lsearch $args -udpsrcportmode] 
    if {$index != -1} {
        set UdpSrcPortMode [lindex $args [expr $index + 1]]        
        if {[string tolower $UdpSrcPortMode] =="increment"} {
            set index [lsearch $args -udpsrcstep]
            if {$index != -1} {
                set UdpSrcStep [lindex $args [expr $index + 1]]
            } else {
                set UdpSrcStep 1
            }
            set index [lsearch $args -udpsrcportcount]
            if {$index != -1} {
                set UdpSrcPortCount [lindex $args [expr $index + 1]]
            } else {
                set UdpSrcPortCount 1
            }

            set hUDPList [GetUDPHandle $streamblock1]
            foreach hUdp $hUDPList {
                set udp_1 [stc::get $hUdp -Name]
                if {$m_UdpSrcRangeModifierList($streamblock1) == ""} {
                    set m_UdpSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hUdp -sourcePort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.sourcePort -StepValue $UdpSrcStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $UdpSrcPortCount -RepeatCount 0] 
                 } else {
                      stc::config  $m_UdpSrcRangeModifierList($streamblock1) -Data [stc::get $hUdp -sourcePort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.sourcePort -StepValue $UdpSrcStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $UdpSrcPortCount -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $UdpSrcPortMode] =="decrement"} {
            set index [lsearch $args -udpsrcstep]
            if {$index != -1} {
                set UdpSrcStep [lindex $args [expr $index + 1]]
            } else {
               set UdpSrcStep 1
            }
            set index [lsearch $args -udpsrcportcount]
            if {$index != -1} {
                set UdpSrcPortCount [lindex $args [expr $index + 1]]
            } else {
               set UdpSrcPortCount 1
            }

            set hUDPList [GetUDPHandle $streamblock1]
            foreach hUdp $hUDPList {
                set udp_1 [stc::get $hUdp -Name]
                if {$m_UdpSrcRangeModifierList($streamblock1) == ""} {
                    set m_UdpSrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hUdp -sourcePort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.sourcePort -StepValue $UdpSrcStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $UdpSrcPortCount -RepeatCount 0] 
                 } else {
                      stc::config  $m_UdpSrcRangeModifierList($streamblock1) -Data [stc::get $hUdp -sourcePort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.sourcePort -StepValue $UdpSrcStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $UdpSrcPortCount -RepeatCount 0
                 } 
            }
        } elseif  {[string tolower $UdpSrcPortMode] =="fixed"} {
             if {$m_UdpSrcRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_UdpSrcRangeModifierList($streamblock1)
                  set $m_UdpSrcRangeModifierList($streamblock1) ""
             }
        
        } else {
            error "Parameter UdpSrcPortMode should be fixed/decrement/increment."
        }       
    }
    
    #Parse UdpDstPortMode/UdpDstPortCount/UdpDstPortStep parameter
    set index [lsearch $args -udpdstportmode] 
    if {$index != -1} {
        set UdpDstPortMode [lindex $args [expr $index + 1]]        
        if {[string tolower $UdpDstPortMode] =="increment"} {
            set index [lsearch $args -udpdstportstep]
            if {$index != -1} {
                set UdpDstPortStep [lindex $args [expr $index + 1]]
            } else {
                set UdpDstPortStep 1
            }
            set index [lsearch $args -udpdstportcount]
            if {$index != -1} {
                set UdpDstPortCount [lindex $args [expr $index + 1]]
            } else {
                set UdpDstPortCount 1
            }

            set hUDPList [GetUDPHandle $streamblock1]
            foreach hUdp $hUDPList {
                set udp_1 [stc::get $hUdp -Name]
                if {$m_UdpDstRangeModifierList($streamblock1) == ""} {
                    set m_UdpDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hUdp -destPort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.destPort -StepValue $UdpDstPortStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $UdpDstPortCount -RepeatCount 0] 
                } else {
                     stc::config $m_UdpDstRangeModifierList($streamblock1) -Data [stc::get $hUdp -destPort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.destPort -StepValue $UdpDstPortStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $UdpDstPortCount -RepeatCount 0
                }
            }        
        } elseif {[string tolower $UdpDstPortMode] =="decrement"} {
            set index [lsearch $args -udpdstportstep]
            if {$index != -1} {
                set UdpDstPortStep [lindex $args [expr $index + 1]]
            } else {
                set UdpDstPortStep 1
            }
            set index [lsearch $args -udpdstportcount]
            if {$index != -1} {
                set UdpDstPortCount [lindex $args [expr $index + 1]]
            } else {
               set UdpDstPortCount 1
            }

            set hUDPList [GetUDPHandle $streamblock1]
            foreach hUdp $hUDPList {
                set udp_1 [stc::get $hUdp -Name]
                if {$m_UdpDstRangeModifierList($streamblock1) == ""} {
                    set m_UdpDstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hUdp -destPort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.destPort -StepValue $UdpDstPortStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $UdpDstPortCount -RepeatCount 0] 
                } else {
                     stc::config $m_UdpDstRangeModifierList($streamblock1) -Data [stc::get $hUdp -destPort] \
                        -Mask 0xFFFF  -OffsetReference $udp_1.destPort -StepValue $UdpDstPortStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $UdpDstPortCount -RepeatCount 0
                } 
            }
        } elseif  {[string tolower $UdpDstPortMode] =="fixed"} {
             if {$m_UdpDstRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_UdpDstRangeModifierList($streamblock1)
                  set $m_UdpDstRangeModifierList($streamblock1) ""
             }
        } else {
            error "Parameter UdpDstPortMode should be fixed/decrement/increment."
        }       
    }
    
    #Parse Udplength/UdplengthOverride parameter
    set index [lsearch $args -udplength] 
    if {$index != -1} {
        set Udplength [lindex $args [expr $index + 1]]

        set hUDPList [GetUDPHandle $streamblock1]       
        set index [lsearch $args -udplengthoverride] 
        if {$index != -1} {
            set UdplengthOverride [lindex $args [expr $index + 1]]
            if {[string tolower $UdplengthOverride] == "true"} {
               foreach hUdp $hUDPList {
                   stc::config $hUdp -length $Udplength
               }
            } else {
               puts "When UdplengthOverride is $UdplengthOverride, the parameter Udplength is not useful."
            }                            
        } else {
            puts "When parameter UdplengthOverride is null, the parameter Udplength is not useful."
        } 
    }
    
    #Parse Udpchecksum/UdpenableChecksum parameter
    set index [lsearch $args -udpchecksum] 
    if {$index != -1} {
        set Udpchecksum [lindex $args [expr $index + 1]]

        set hUDPList [GetUDPHandle $streamblock1]       
        set index [lsearch $args -udpenablechecksum] 
        if {$index != -1} {
            set UdpenableChecksum [lindex $args [expr $index + 1]]
            if {[string tolower $UdpenableChecksum] == "true"} {
                foreach hUdp $hUDPList {
                    stc::config $hUdp -checksum $Udpchecksum
                }
            } else {
                puts "When UdpenableChecksum is $UdpenableChecksum, the parameter Udpchecksum is not useful."
            }                            
        } else {
            puts "When parameter Udpchecksum is null, the parameter Udpchecksum is not useful."
        } 
    }
    
    #################UDP parameter configuration#######################
    
}

############################################################################
#APIName: ConfigVlanStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigVlanStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################VLAN parameter configuration#######################
    
    #Parse VlanID parameter
    set index [lsearch $args -vlanid] 
    if {$index != -1} {
        set VlanID [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        
        #判断是否是列表输入
        set m_VlanIdTableModifierIdList($streamblock1) $VlanID
        set VlanID [lindex $VlanID 0]
        
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }            
            stc::config $hvlan -id $VlanID             
        }
    }
    
    #Parse VlanUserPriority parameter
    set index [lsearch $args -vlanuserpriority] 
    if {$index != -1} {
        set VlanUserPriority [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }
            set binUserPriority [dec2bin $VlanUserPriority 2 3]
            stc::config $hvlan -pri $binUserPriority
        }
    }
    
    #Parse VlanCfi parameter
    set index [lsearch $args -vlancfi] 
    if {$index != -1} {
        set VlanCfi [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }
            stc::config $hvlan -cfi $VlanCfi
        }
    }
    
    #Parse VlanidMode/VlanidStep/VlanidCount parameter
    set index [lsearch $args -vlanidmode] 
    if {$index != -1} {
        set VlanidMode [lindex $args [expr $index + 1]]        
        if {[string tolower $VlanidMode] =="increment"} {
            set index [lsearch $args -vlanidstep]
            if {$index != -1} {
                set VlanidStep [lindex $args [expr $index + 1]]
            } else {
                set VlanidStep 1
            }
            set index [lsearch $args -vlanidcount]
            if {$index != -1} {
                set VlanidCount [lindex $args [expr $index + 1]]
            } else {
                set VlanidCount 1
            }
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]
                if {$m_VlanIdTableModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList($streamblock1)
                  set m_VlanIdTableModifierList($streamblock1) ""
                }
                if {$m_VlanIdRangeModifierList($streamblock1) == ""} {               
                    set m_VlanIdRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode INCR -RecycleCount $VlanidCount -StepValue $VlanidStep -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanIdRangeModifierList($streamblock1) -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode INCR -RecycleCount $VlanidCount -StepValue $VlanidStep -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $VlanidMode] =="decrement"} {
            set index [lsearch $args -vlanidstep]
            if {$index != -1} {
                set VlanidStep [lindex $args [expr $index + 1]]
            } else {
                set VlanidStep 1
            }
            set index [lsearch $args -vlanidcount]
            if {$index != -1} {
                set VlanidCount [lindex $args [expr $index + 1]]
            } else {
               set VlanidCount 1
            }
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]
                 if {$m_VlanIdTableModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList($streamblock1)
                  set m_VlanIdTableModifierList($streamblock1) ""
                 }
                 if {$m_VlanIdRangeModifierList($streamblock1) == ""} {               
                    set m_VlanIdRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode DECR -RecycleCount $VlanidCount -StepValue $VlanidStep -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanIdRangeModifierList($streamblock1) -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode DECR -RecycleCount $VlanidCount -StepValue $VlanidStep -RepeatCount 0
                 }               
            }
         } elseif {[string tolower $VlanidMode] =="list"} {
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]
                 if {$m_VlanIdRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanIdRangeModifierList($streamblock1)
                  set m_VlanIdRangeModifierList($streamblock1) ""
                 }
                 if {$m_VlanIdTableModifierList($streamblock1) == ""} {               
                    set m_VlanIdTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_VlanIdTableModifierIdList($streamblock1) \
                        -OffsetReference $eth_h1.vlans.$vlan_1.id -Offset 0 -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanIdTableModifierList($streamblock1) -Data $m_VlanIdTableModifierIdList($streamblock1) \
                        -OffsetReference $eth_h1.vlans.$vlan_1.id -Offset 0 -RepeatCount 0
                 }               
            }
        } elseif  {[string tolower $VlanidMode] =="fixed"} {
            if {$m_VlanIdRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanIdRangeModifierList($streamblock1)
                  set m_VlanIdRangeModifierList($streamblock1) ""
            }
            if {$m_VlanIdTableModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList($streamblock1)
                  set m_VlanIdTableModifierList($streamblock1) ""
            }
        } else {
            error "Parameter VlanidMode should be fixed/decrement/increment/list."
        }       
    }
    
    #Parse VlanTypeId parameter
    set index [lsearch $args -vlantype] 
    if {$index == -1} {
        set index [lsearch $args -vlantypeid] 
    }

    if {$index != -1} {
        set VlanTypeId [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 0]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }

           set find_index [string first "0x" $VlanTypeId] 
           if {$find_index != -1} {
               set decimal [format "%u" $VlanTypeId]  
               set hex [format "%x" $decimal]
           } else {
               set hex $VlanTypeId
           }
    
           stc::config $hvlan -type $hex 
           #stc::config $hEth -etherType $hex
        }
    }
    
    #Parse VlanID2 parameter
    set index [lsearch $args -vlanid2] 
    if {$index != -1} {
        set VlanID2 [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }

        #判断是否是列表输入
        set m_VlanIdTableModifierIdList2($streamblock1) $VlanID2
        set VlanID2 [lindex $VlanID2 0]
        
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }
            stc::config $hvlan -id $VlanID2             
        }
    }
    
    #Parse VlanUserPriority2 parameter
    set index [lsearch $args -vlanuserpriority2] 
    if {$index != -1} {
        set VlanUserPriority2 [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }
            set binUserPriority [dec2bin $VlanUserPriority2 2 3]
            stc::config $hvlan -pri $binUserPriority
        }
    }
    
    #Parse VlanCfi2 parameter
    set index [lsearch $args -vlancfi2] 
    if {$index != -1} {
        set VlanCfi2 [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }
            stc::config $hvlan -cfi $VlanCfi2
        }
    }
    
    #Parse VlanidMode2/VlanidStep2/VlanidCount2 parameter
    set index [lsearch $args -vlanidmode2] 
    if {$index != -1} {
        set VlanidMode2 [lindex $args [expr $index + 1]]        
        if {[string tolower $VlanidMode2] =="increment"} {
            set index [lsearch $args -vlanidstep2]
            if {$index != -1} {
                set VlanidStep2 [lindex $args [expr $index + 1]]
            } else {
               set VlanidStep2 1
            }
            set index [lsearch $args -vlanidcount2]
            if {$index != -1} {
                set VlanidCount2 [lindex $args [expr $index + 1]]
            } else {
                set VlanidCount2 1
            }
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]
                if {$m_VlanIdTableModifierList2($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList2($streamblock1)
                  set m_VlanIdTableModifierList2($streamblock1) ""
                }
                if {$m_VlanId2RangeModifierList($streamblock1) == ""} {
                    set m_VlanId2RangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode INCR -RecycleCount $VlanidCount2 -StepValue $VlanidStep2 -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanId2RangeModifierList($streamblock1) -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode INCR -RecycleCount $VlanidCount2 -StepValue $VlanidStep2 -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $VlanidMode2] =="decrement"} {
            set index [lsearch $args -vlanidstep2]
            if {$index != -1} {
                set VlanidStep2 [lindex $args [expr $index + 1]]
            } else {
                set VlanidStep2 1 
            }
            set index [lsearch $args -vlanidcount2]
            if {$index != -1} {
                set VlanidCount2 [lindex $args [expr $index + 1]]
            } else {
                set VlanidCount2  1
            }
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]   
                if {$m_VlanIdTableModifierList2($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList2($streamblock1)
                  set m_VlanIdTableModifierList2($streamblock1) ""
                }
                if {$m_VlanId2RangeModifierList($streamblock1) == ""} {
                    set m_VlanId2RangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode DECR -RecycleCount $VlanidCount2 -StepValue $VlanidStep2 -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanId2RangeModifierList($streamblock1) -Data [stc::get $hvlan -id] \
                        -Mask 4095 -OffsetReference $eth_h1.vlans.$vlan_1.id \
                        -Offset 0 -ModifierMode DECR -RecycleCount $VlanidCount2 -StepValue $VlanidStep2 -RepeatCount 0
                 }
            }
        } elseif {[string tolower $VlanidMode2] =="list"} {
            set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
            if {$hEthList == ""} {
                error "When you create vlan head, you should create ethernet head simultaneously."
            }
            foreach hEth $hEthList {
                set eth_h1 [stc::get $hEth -Name]
                set vlans1 [stc::get $hEth -children-vlans]
                if {$vlans1 ==""} {
                    set vlans1 [stc::create vlans -under $hEth]
                }            
                set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
                if {$hvlan ==""} {
                    set hvlan [stc::create vlan -under $vlans1]
                }
                set vlan_1  [stc::get $hvlan -Name]   
                if {$m_VlanId2RangeModifierList($streamblock1) != ""} {
                    stc::delete $m_VlanId2RangeModifierList($streamblock1)
                    set m_VlanId2RangeModifierList($streamblock1) ""
                }
                if {$m_VlanIdTableModifierList2($streamblock1) == ""} {
                    set m_VlanIdTableModifierList2($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_VlanIdTableModifierIdList2($streamblock1) \
                        -OffsetReference $eth_h1.vlans.$vlan_1.id -Offset 0 -RepeatCount 0]
                 } else {
                     stc::config  $m_VlanId2RangeModifierList($streamblock1) -Data $m_VlanIdTableModifierIdList2($streamblock1) \
                        -OffsetReference $eth_h1.vlans.$vlan_1.id -Offset 0 -RepeatCount 0
                 }
            }
        } elseif  {[string tolower $VlanidMode2] =="fixed"} {
            if {$m_VlanId2RangeModifierList($streamblock1) != ""} {
                  stc::delete $m_VlanId2RangeModifierList($streamblock1)
                  set m_VlanId2RangeModifierList($streamblock1) ""
            }
            if {$m_VlanIdTableModifierList2($streamblock1) != ""} {
                  stc::delete $m_VlanIdTableModifierList2($streamblock1)
                  set m_VlanIdTableModifierList2($streamblock1) ""
            }
        } else {
            error "Parameter VlanidMode2 should be fixed/decrement/increment/list."
        }       
    }
    
    #Parse VlanTypeId2 parameter
  
    set index [lsearch $args -vlantype2] 
    if {$index == -1} {
        set index [lsearch $args -vlantypeid2] 
    }

    if {$index != -1} {
        set VlanTypeId2 [lindex $args [expr $index + 1]]
        set hEthList [stc::get $streamblock1 -children-ethernet:EthernetII]
        if {$hEthList == ""} {
            error "When you create vlan head, you should create ethernet head simultaneously."
        }
        foreach hEth $hEthList {
            set vlans1 [stc::get $hEth -children-vlans]
            if {$vlans1 ==""} {
                set vlans1 [stc::create vlans -under $hEth]
            }            
            set hvlan [lindex [stc::get $vlans1 -children-vlan] 1]
            if {$hvlan ==""} {
                set hvlan [stc::create vlan -under $vlans1]
            }

           set find_index [string first "0x" $VlanTypeId2] 
           if {$find_index != -1} {
               set decimal [format "%u" $VlanTypeId2]  
               set hex [format "%x" $decimal]
           } else {
               set hex $VlanTypeId2
           }
           
           stc::config $hvlan -type $hex
        }
    }
    
    #################VLAN parameter configuration#######################
    
}

############################################################################
#APIName: ConfigIPV6StreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigIPV6StreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################IPV6 parameter configuratioin#######################
    #Parse StreamType parameter
    set index [lsearch $args -streamtype] 
    if {$index != -1} {
        set StreamType [lindex $args [expr $index + 1]]
    } else {
        set StreamType "Normal"
    } 

    #Parse Ipv6SrcAddress parameter
    set index [lsearch $args -ipv6srcaddress] 
    if {$index != -1} {
        set Ipv6SrcAddress [lindex $args [expr $index + 1]]

        #Add the support of MplsVPN bounding
        if {[string tolower $StreamType ] == "vpn"} {
             if {[info exists ::mainDefine::gIpv6NetworkBlock($Ipv6SrcAddress)]} {
                 catch {
                     set hSrcIpv6NetworkBlock $::mainDefine::gIpv6NetworkBlock($Ipv6SrcAddress)
                     stc::config $streamblock1 -SrcBinding-targets " $hSrcIpv6NetworkBlock "
                     set Ipv6SrcAddress [stc::get $hSrcIpv6NetworkBlock -StartIpList]
                }
            }
        }

       set hIPv6List [GetIPv6Handle $streamblock1]  
       #判断输入地址是否为列表形式
       set m_Ipv6SrcTableModifierAddrList($streamblock1) $Ipv6SrcAddress
       set Ipv6SrcAddress [lindex $Ipv6SrcAddress 0]
       
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -sourceAddr $Ipv6SrcAddress
        }
    }
    
    #Parse Ipv6DstAddress parameter
    set index [lsearch $args -ipv6dstaddress] 
    if {$index != -1} {
        set Ipv6DstAddress [lindex $args [expr $index + 1]]

        #Add the support of MplsVPN bounding
        if {[string tolower $StreamType ] == "vpn"} {
             if {[info exists ::mainDefine::gIpv6NetworkBlock($Ipv6DstAddress)]} {
                 catch {
                     set hDstIpv6NetworkBlock $::mainDefine::gIpv6NetworkBlock($Ipv6DstAddress)
                     stc::config $streamblock1 -DstBinding-targets " $hDstIpv6NetworkBlock "
                     set Ipv6DstAddress [stc::get $hDstIpv6NetworkBlock -StartIpList]
                }
            }
        }

        set hIPv6List [GetIPv6Handle $streamblock1]  
       #判断输入地址是否为列表形式
        set m_Ipv6DstTableModifierAddrList($streamblock1) $Ipv6DstAddress
        set Ipv6DstAddress [lindex $Ipv6DstAddress 0]

        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -destAddr $Ipv6DstAddress
        }
    }
    
    #Parse Ipv6TrafficClass parameter
    set index [lsearch $args -ipv6trafficclass] 
    if {$index != -1} {
        set Ipv6TrafficClass [lindex $args [expr $index + 1]]

        set hIPv6List [GetIPv6Handle $streamblock1]  
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -trafficClass $Ipv6TrafficClass
        }
    }
    
    #Parse Ipv6NextHeader parameter
    set index [lsearch $args -ipv6nextheader] 
    if {$index != -1} {
        set Ipv6NextHeader [lindex $args [expr $index + 1]]

        set hIPv6List [GetIPv6Handle $streamblock1]  
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -nextHeader $Ipv6NextHeader
        }
    }
    
    #Parse Ipv6HopLimit parameter
    set index [lsearch $args -ipv6hoplimit] 
    if {$index != -1} {
        set Ipv6HopLimit [lindex $args [expr $index + 1]]

        set hIPv6List [GetIPv6Handle $streamblock1]  
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -hopLimit $Ipv6HopLimit
        }
    }
    

    #Parse Ipv6FlowLabel parameter
    set index [lsearch $args -ipv6flowlabel] 
    if {$index != -1} {
        set Ipv6FlowLabel [lindex $args [expr $index + 1]]

        set hIPv6List [GetIPv6Handle $streamblock1]  
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -flowLabel $Ipv6FlowLabel
        }
    }
    
    #Parse Ipv6PayLoadLen parameter
    set index [lsearch $args -ipv6payloadlen] 
    if {$index != -1} {
        set Ipv6PayLoadLen [lindex $args [expr $index + 1]]

        set hIPv6List [GetIPv6Handle $streamblock1]  
        foreach hIpv6 $hIPv6List {
            stc::config $hIpv6 -payloadLength $Ipv6PayLoadLen
        }
    }
    
    #Parse Ipv6SrcAddressMode/Ipv6SrcAddressCount/Ipv6SrcAddressStep parameter
    set index [lsearch $args -ipv6srcaddressmode] 
    if {$index != -1} {
        set Ipv6SrcAddressMode [lindex $args [expr $index + 1]]        
        if {[string tolower $Ipv6SrcAddressMode] =="increment"} {
            set index [lsearch $args -ipv6srcaddressstep]
            if {$index != -1} {
                set Ipv6SrcAddressStep [lindex $args [expr $index + 1]]
            } else {
                set Ipv6SrcAddressStep "0000:0000:0000:0000:0000:0000:0000:0001" 
            }
            set index [lsearch $args -ipv6srcaddresscount]
            if {$index != -1} {
                set Ipv6SrcAddressCount [lindex $args [expr $index + 1]]
            } else {
                set Ipv6SrcAddressCount  1
            }
            set index [lsearch $args -ipv6srcaddressmask]
            if {$index != -1} {
                set Ipv6SrcAddressMask [lindex $args [expr $index + 1]]
            } else {
                set Ipv6SrcAddressMask "::FFFF:FFFF"
            }

            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6SrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6SrcTableModifierList($streamblock1)
                  set m_Ipv6SrcTableModifierList($streamblock1) ""
                }
                if {$m_Ipv6SrcRangeModifierList($streamblock1) == ""} {
                    set m_Ipv6SrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv6 -sourceAddr] \
                        -Mask $Ipv6SrcAddressMask -OffsetReference $ip61.sourceAddr -StepValue $Ipv6SrcAddressStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $Ipv6SrcAddressCount -RepeatCount 0] 
                 } else {
                     stc::config $m_Ipv6SrcRangeModifierList($streamblock1) -Data [stc::get $hIpv6 -sourceAddr] \
                        -Mask $Ipv6SrcAddressMask  -OffsetReference $ip61.sourceAddr -StepValue $Ipv6SrcAddressStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $Ipv6SrcAddressCount -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $Ipv6SrcAddressMode] =="decrement"} {
            set index [lsearch $args -Ipv6SrcAddressStep]
            if {$index != -1} {
                set Ipv6SrcAddressStep [lindex $args [expr $index + 1]]
            } else {
               set  Ipv6SrcAddressStep  "0000:0000:0000:0000:0000:0000:0000:0001" 
            }
            set index [lsearch $args -ipv6srcaddresscount]
            if {$index != -1} {
                set Ipv6SrcAddressCount [lindex $args [expr $index + 1]]
            } else {
               set Ipv6SrcAddressCount 1
            }
            set index [lsearch $args -ipv6srcaddressmask]
            if {$index != -1} {
                set Ipv6SrcAddressMask [lindex $args [expr $index + 1]]
            } else {
                set Ipv6SrcAddressMask "::FFFF:FFFF"
            }

            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6SrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6SrcTableModifierList($streamblock1)
                  set m_Ipv6SrcTableModifierList($streamblock1) ""
                }
                if {$m_Ipv6SrcRangeModifierList($streamblock1) == ""} {
                    set m_Ipv6SrcRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv6 -sourceAddr] \
                        -Mask $Ipv6SrcAddressMask  -OffsetReference $ip61.sourceAddr -StepValue $Ipv6SrcAddressStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $Ipv6SrcAddressCount -RepeatCount 0] 
                 } else {
                     stc::config $m_Ipv6SrcRangeModifierList($streamblock1) -Data [stc::get $hIpv6 -sourceAddr] \
                        -Mask $Ipv6SrcAddressMask  -OffsetReference $ip61.sourceAddr -StepValue $Ipv6SrcAddressStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $Ipv6SrcAddressCount -RepeatCount 0
                 } 
            }
         } elseif {[string tolower $Ipv6SrcAddressMode] =="list"} {
            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6SrcRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6SrcRangeModifierList($streamblock1)
                  set m_Ipv6SrcRangeModifierList($streamblock1) ""
                }
                if {$m_Ipv6SrcTableModifierList($streamblock1) == ""} {
                    set m_Ipv6SrcTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_Ipv6SrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip61.sourceAddr -Offset 0 -RepeatCount 0] 
                 } else {
                     stc::config $m_Ipv6SrcTableModifierList($streamblock1) -Data $m_Ipv6SrcTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip61.sourceAddr -Offset 0 -RepeatCount 0
                 } 
            }
        } elseif  {[string tolower $Ipv6SrcAddressMode] =="fixed"} {
            if {$m_Ipv6SrcRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6SrcRangeModifierList($streamblock1)
                  set m_Ipv6SrcRangeModifierList($streamblock1) ""
            }
            if {$m_Ipv6SrcTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6SrcTableModifierList($streamblock1)
                  set m_Ipv6SrcTableModifierList($streamblock1) ""
            }
        } else {
            error "Parameter Ipv6SrcAddressMode should be fixed/decrement/increment/list."
        }       
    }
    
    #Parse Ipv6DstAddressMode/Ipv6DstAddressCount/Ipv6DstAddressStep parameter
    set index [lsearch $args -ipv6dstaddressmode] 
    if {$index != -1} {
        set Ipv6DstAddressMode [lindex $args [expr $index + 1]]        
        if {[string tolower $Ipv6DstAddressMode] =="increment"} {
            set index [lsearch $args -ipv6dstaddressstep]
            if {$index != -1} {
                set Ipv6DstAddressStep [lindex $args [expr $index + 1]]
            } else {
               set Ipv6DstAddressStep "0000:0000:0000:0000:0000:0000:0000:0001" 
            }
            set index [lsearch $args -ipv6dstaddresscount]
            if {$index != -1} {
                set Ipv6DstAddressCount [lindex $args [expr $index + 1]]
            } else {
                set Ipv6DstAddressCount 1
            }
            set index [lsearch $args -ipv6dstaddressmask]
            if {$index != -1} {
                set Ipv6DstAddressMask [lindex $args [expr $index + 1]]
            } else {
                set Ipv6DstAddressMask "::FFFF:FFFF"
            }

            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6DstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6DstTableModifierList($streamblock1)
                  set m_Ipv6DstTableModifierList($streamblock1) ""
                }
                if {$m_Ipv6DstRangeModifierList($streamblock1) == ""} {  
                    set m_Ipv6DstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv6 -destAddr] \
                        -Mask $Ipv6DstAddressMask  -OffsetReference $ip61.destAddr -StepValue $Ipv6DstAddressStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $Ipv6DstAddressCount -RepeatCount 0] 
                 } else {
                      stc::config $m_Ipv6DstRangeModifierList($streamblock1) -Data [stc::get $hIpv6 -destAddr] \
                        -Mask $Ipv6DstAddressMask  -OffsetReference $ip61.destAddr -StepValue $Ipv6DstAddressStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $Ipv6DstAddressCount -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $Ipv6DstAddressMode] =="decrement"} {
            set index [lsearch $args -ipv6dstaddressstep]
            if {$index != -1} {
                set Ipv6DstAddressStep [lindex $args [expr $index + 1]]
            } else {
                set Ipv6DstAddressStep "0000:0000:0000:0000:0000:0000:0000:0001" 
            }
            set index [lsearch $args -ipv6dstaddresscount]
            if {$index != -1} {
                set Ipv6DstAddressCount [lindex $args [expr $index + 1]]
            } else {
                set Ipv6DstAddressCount 1
            }
            set index [lsearch $args -ipv6dstaddressmask]
            if {$index != -1} {
                set Ipv6DstAddressMask [lindex $args [expr $index + 1]]
            } else {
                set Ipv6DstAddressMask "::FFFF:FFFF"
            }

            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6DstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6DstTableModifierList($streamblock1)
                  set m_Ipv6DstTableModifierList($streamblock1) ""
                }
                if {$m_Ipv6DstRangeModifierList($streamblock1) == ""} {  
                    set m_Ipv6DstRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIpv6 -destAddr] \
                        -Mask $Ipv6DstAddressMask -OffsetReference $ip61.destAddr -StepValue $Ipv6DstAddressStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $Ipv6DstAddressCount -RepeatCount 0] 
                 } else {
                      stc::config $m_Ipv6DstRangeModifierList($streamblock1) -Data [stc::get $hIpv6 -destAddr] \
                        -Mask $Ipv6DstAddressMask  -OffsetReference $ip61.destAddr -StepValue $Ipv6DstAddressStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $Ipv6DstAddressCount -RepeatCount 0
                 }
            }
        } elseif {[string tolower $Ipv6DstAddressMode] =="list"} {

            set hIPv6List [GetIPv6Handle $streamblock1]  
            foreach hIpv6 $hIPv6List {
                set ip61 [stc::get $hIpv6 -Name]
                if {$m_Ipv6DstRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6DstRangeModifierList($streamblock1)
                  set m_Ipv6DstRangeModifierList($streamblock1) ""
                }
                if {$m_Ipv6DstTableModifierList($streamblock1) == ""} {
                    set m_Ipv6DstTableModifierList($streamblock1) [stc::create TableModifier -under $streamblock1 -Data $m_Ipv6DstTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip61.destAddr -Offset 0 -RepeatCount 0] 
                 } else {
                     stc::config $m_Ipv6DstTableModifierList($streamblock1) -Data $m_Ipv6DstTableModifierAddrList($streamblock1) \
                         -OffsetReference $ip61.destAddr -Offset 0 -RepeatCount 0
                 } 
            }
        } elseif  {[string tolower $Ipv6DstAddressMode] =="fixed"} {
            if {$m_Ipv6DstRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6DstRangeModifierList($streamblock1)
                  set m_Ipv6DstRangeModifierList($streamblock1) ""
            }
            if {$m_Ipv6DstTableModifierList($streamblock1) != ""} {
                  stc::delete $m_Ipv6DstTableModifierList($streamblock1)
                  set m_Ipv6DstTableModifierList($streamblock1) ""
            }
        } else {
            error "Parameter Ipv6DstAddressMode should be fixed/decrement/increment/list."
        }       
    }
    
    #################IPV6 parameter configuratioin#######################
}

############################################################################
#APIName: ConfigArpStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigArpStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    #################ARP parameter configuration#######################
    
    #Parse ArpSrcHwAddr parameter
    set index [lsearch $args -arpsrchwaddr] 
    if {$index != -1} {
        set ArpSrcHwAddr [lindex $args [expr $index + 1]]
        set hARPList [GetARPHandle $streamblock1]
        foreach hARP $hARPList {
            stc::config $hARP -senderHwAddr $ArpSrcHwAddr
        }
    }
    
    #Parse ArpDstHwAddr parameter
    set index [lsearch $args -arpdsthwaddr] 
    if {$index != -1} {
        set ArpDstHwAddr [lindex $args [expr $index + 1]]
        set hARPList [GetARPHandle $streamblock1]
        foreach hARP $hARPList {
            stc::config $hARP -targetHwAddr $ArpDstHwAddr
        }
    }
    
    #Parse ArpOperation parameter
    set index [lsearch $args -arpoperation] 
    if {$index != -1} {
        set ArpOperation [lindex $args [expr $index + 1]]
        if {[string tolower $ArpOperation] == "arprequest"} {
            set operateCode 1
        } elseif {[string tolower $ArpOperation] == "arpreply"} {
            set operateCode 2
        } else {
            set operateCode 0
        }
           
        set hARPList [GetARPHandle $streamblock1]
     
        foreach hARP $hARPList {
            stc::config $hARP -operation $operateCode
        }
    }
    
    set index [lsearch $args -arpsrchwaddrstep]
    if {$index != -1} {
          set ArpSrcHwAddrStep [lindex $args [expr $index + 1]]
     } else {
          set  ArpSrcHwAddrStep 00:00:00:00:00:01
     }

    #Parse ArpSrcHwAddrMode/ArpSrcHwAddrCount parameter
    set index [lsearch $args -arpsrchwaddrmode] 
    if {$index != -1} {
        set ArpSrcHwAddrMode [lindex $args [expr $index + 1]]        
        if {[string tolower $ArpSrcHwAddrMode] =="increment"} {
            set index [lsearch $args -arpsrchwaddrcount]
            if {$index != -1} {
                set ArpSrcHwAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpSrcHwAddrCount 1
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpSrcHwRangeModifierList($streamblock1) == ""} { 
                    set m_ArpSrcHwRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -senderHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.senderHwAddr -StepValue $ArpSrcHwAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpSrcHwAddrCount -RepeatCount 0] 
                } else {
                    stc::config $m_ArpSrcHwRangeModifierList($streamblock1) -Data [stc::get $hARP -senderHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.senderHwAddr -StepValue $ArpSrcHwAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpSrcHwAddrCount -RepeatCount 0 
                }
            }        
        } elseif {[string tolower $ArpSrcHwAddrMode] =="decrement"} {
            set index [lsearch $args -arpsrchwaddrcount]
            if {$index != -1} {
                set ArpSrcHwAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpSrcHwAddrCount 1
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpSrcHwRangeModifierList($streamblock1) == ""} { 
                    set m_ArpSrcHwRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -senderHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.senderHwAddr -StepValue $ArpSrcHwAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpSrcHwAddrCount -RepeatCount 0] 
                } else {
                    stc::config $m_ArpSrcHwRangeModifierList($streamblock1) -Data [stc::get $hARP -senderHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.senderHwAddr -StepValue $ArpSrcHwAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpSrcHwAddrCount -RepeatCount 0 
                }
            }
        } elseif  {[string tolower $ArpSrcHwAddrMode] =="fixed"} {
            if {$m_ArpSrcHwRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_ArpSrcHwRangeModifierList($streamblock1)
                  set m_ArpSrcHwRangeModifierList($streamblock1) ""
            }
        } else {
            error "Parameter ArpSrcHwAddrMode should be fixed/decrement/increment."
        }       
    }

    set index [lsearch $args -arpdsthwaddrstep]
    if {$index != -1} {
          set ArpDstHwAddrStep [lindex $args [expr $index + 1]]
     } else {
          set  ArpDstHwAddrStep 00:00:00:00:00:01
     }
    
    #Parse ArpDstHwAddrMode/ArpDstHwAddrCount parameter
    set index [lsearch $args -arpdsthwaddrmode] 
    if {$index != -1} {
        set ArpDstHwAddrMode [lindex $args [expr $index + 1]]      
        if {[string tolower $ArpDstHwAddrMode] =="increment"} {
            set index [lsearch $args -arpdsthwaddrcount]
            if {$index != -1} {
                set ArpDstHwAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpDstHwAddrCount 1
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name] 
                if {$m_ArpDstHwRangeModifierList($streamblock1) == ""} {
                    set m_ArpDstHwRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -targetHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.targetHwAddr -StepValue $ArpDstHwAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpDstHwAddrCount -RepeatCount 0] 
                 } else {
                     stc::config $m_ArpDstHwRangeModifierList($streamblock1) -Data [stc::get $hARP -targetHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.targetHwAddr -StepValue $ArpDstHwAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpDstHwAddrCount -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $ArpDstHwAddrMode] =="decrement"} {
            set index [lsearch $args -arpdsthwaddrcount]
            if {$index != -1} {
                set ArpDstHwAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpDstHwAddrCount 1
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpDstHwRangeModifierList($streamblock1) == ""} {
                    set m_ArpDstHwRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -targetHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.targetHwAddr -StepValue $ArpDstHwAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpDstHwAddrCount -RepeatCount 0] 
                 } else {
                     stc::config $m_ArpDstHwRangeModifierList($streamblock1) -Data [stc::get $hARP -targetHwAddr] \
                        -Mask "00:00:FF:FF:FF:FF"  -OffsetReference $arp1.targetHwAddr -StepValue $ArpDstHwAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpDstHwAddrCount -RepeatCount 0
                 }
            }
        } elseif  {[string tolower $ArpDstHwAddrMode] =="fixed"} {
            if {$m_ArpDstHwRangeModifierList($streamblock1) != ""} {
                 stc::delete $m_ArpDstHwRangeModifierList($streamblock1)
                 set m_ArpDstHwRangeModifierList($streamblock1) ""
            } 
        } else {
            error "Parameter ArpDstHwAddrMode should be fixed/decrement/increment."
        }       
    }
    
    #Parse ArpSrcProtocolAddr parameter
    set index [lsearch $args -arpsrcprotocoladdr] 
    if {$index != -1} {
        set ArpSrcProtocolAddr [lindex $args [expr $index + 1]]
        
        set hARPList [GetARPHandle $streamblock1]
        foreach hARP $hARPList {
            stc::config $hARP -senderPAddr $ArpSrcProtocolAddr
        }
    }
    
    #Parse ArpDstProtocolAddr parameter
    set index [lsearch $args -arpdstprotocoladdr] 
    if {$index != -1} {
        set ArpDstProtocolAddr [lindex $args [expr $index + 1]]
       
        set hARPList [GetARPHandle $streamblock1]
        foreach hARP $hARPList {
            stc::config $hARP -targetPAddr $ArpDstProtocolAddr
        }
    }
    
    #Parse ArpSrcProtocolAddrMode/ArpSrcProtocolAddrCount/ArpSrcProtocolAddrStep parameter
    set index [lsearch $args -arpsrcprotocoladdrmode] 
    if {$index != -1} {
        set ArpSrcProtocolAddrMode [lindex $args [expr $index + 1]]        
        if {[string tolower $ArpSrcProtocolAddrMode] =="increment"} {
            set index [lsearch $args -arpsrcprotocoladdrcount]
            if {$index != -1} {
                set ArpSrcProtocolAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpSrcProtocolAddrCount 1
            }
            set index [lsearch $args -arpsrcprotocoladdrstep]
            if {$index != -1} {
                set ArpSrcProtocolAddrStep [lindex $args [expr $index + 1]]
            } else {
               set ArpSrcProtocolAddrStep "0.0.0.1"
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpSrcProtoRangeModifierList($streamblock1) == ""} {
                    set m_ArpSrcProtoRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -senderPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.senderPAddr -StepValue $ArpSrcProtocolAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpSrcProtocolAddrCount -RepeatCount 0] 
                } else {
                    stc::config  $m_ArpSrcProtoRangeModifierList($streamblock1) -Data [stc::get $hARP -senderPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.senderPAddr -StepValue $ArpSrcProtocolAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpSrcProtocolAddrCount -RepeatCount 0
                }
            }        
        } elseif {[string tolower $ArpSrcProtocolAddrMode] =="decrement"} {
            set index [lsearch $args -arpsrcprotocoladdrcount]
            if {$index != -1} {
                set ArpSrcProtocolAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpSrcProtocolAddrCount 1
            }
            set index [lsearch $args -arpsrcprotocoladdrstep]
            if {$index != -1} {
                set ArpSrcProtocolAddrStep [lindex $args [expr $index + 1]]
            } else {
                set ArpSrcProtocolAddrStep "0.0.0.1"
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpSrcProtoRangeModifierList($streamblock1) == ""} {
                    set m_ArpSrcProtoRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -senderPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.senderPAddr -StepValue $ArpSrcProtocolAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpSrcProtocolAddrCount -RepeatCount 0] 
                } else {
                    stc::config  $m_ArpSrcProtoRangeModifierList($streamblock1) -Data [stc::get $hARP -senderPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.senderPAddr -StepValue $ArpSrcProtocolAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpSrcProtocolAddrCount -RepeatCount 0
                }
            }
        } elseif  {[string tolower $ArpSrcProtocolAddrMode] =="fixed"} {
            if {$m_ArpSrcProtoRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_ArpSrcProtoRangeModifierList($streamblock1)
                  set m_ArpSrcProtoRangeModifierList($streamblock1) ""
            }
        } else {
            error "Parameter ArpSrcProtocolAddrMode should be fixed/decrement/increment."
        }       
    }
    
    #Parse ArpDstProtocolAddrMode/ArpDstProtocolAddrCount/ArpDstProtocolAddrStep parameter
    set index [lsearch $args -arpdstprotocoladdrmode] 
    if {$index != -1} {
        set ArpDstProtocolAddrMode [lindex $args [expr $index + 1]]        
        if {[string tolower $ArpSrcProtocolAddrMode] =="increment"} {
            set index [lsearch $args -arpdstprotocoladdrstep]
            if {$index != -1} {
                set ArpDstProtocolAddrStep [lindex $args [expr $index + 1]]
            } else {
                set ArpDstProtocolAddrStep "0.0.0.1"
            }
            set index [lsearch $args -arpdstprotocoladdrcount]
            if {$index != -1} {
                set ArpDstProtocolAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpDstProtocolAddrCount 1
            }

            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name]
                if {$m_ArpDstProtoRangeModifierList($streamblock1) == ""} {
                    set m_ArpDstProtoRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -targetPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.targetPAddr -StepValue $ArpDstProtocolAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpDstProtocolAddrCount -RepeatCount 0] 
                 } else {
                     stc::config  $m_ArpDstProtoRangeModifierList($streamblock1) -Data [stc::get $hARP -targetPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.targetPAddr -StepValue $ArpDstProtocolAddrStep \
                        -Offset 0 -ModifierMode INCR -RecycleCount $ArpDstProtocolAddrCount -RepeatCount 0
                 }
            }        
        } elseif {[string tolower $ArpDstProtocolAddrMode] =="decrement"} {
            set index [lsearch $args -arpdstprotocoladdrcount]
            if {$index != -1} {
                set ArpDstProtocolAddrCount [lindex $args [expr $index + 1]]
            } else {
                set ArpDstProtocolAddrCount 1
            }
            set index [lsearch $args -arpdstprotocoladdrstep]
            if {$index != -1} {
                set ArpDstProtocolAddrStep [lindex $args [expr $index + 1]]
            } else {
                set ArpDstProtocolAddrStep "0.0.0.1"
            }
            
            set hARPList [GetARPHandle $streamblock1]
            foreach hARP $hARPList {
                set arp1 [stc::get $hARP -Name] 
                if {$m_ArpDstProtoRangeModifierList($streamblock1) == ""} {
                    set m_ArpDstProtoRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hARP -targetPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.targetPAddr -StepValue $ArpDstProtocolAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpDstProtocolAddrCount -RepeatCount 0] 
                 } else {
                     stc::config  $m_ArpDstProtoRangeModifierList($streamblock1) -Data [stc::get $hARP -targetPAddr] \
                        -Mask "255.255.255.255"  -OffsetReference $arp1.targetPAddr -StepValue $ArpDstProtocolAddrStep \
                        -Offset 0 -ModifierMode DECR -RecycleCount $ArpDstProtocolAddrCount -RepeatCount 0
                 }
            }
        } elseif  {[string tolower $ArpDstProtocolAddrMode] =="fixed"} {
            if {$m_ArpDstProtoRangeModifierList($streamblock1) != ""} {
                  stc::delete $m_ArpDstProtoRangeModifierList($streamblock1)
                  set  m_ArpDstProtoRangeModifierList($streamblock1) ""
            }
        } else {
            error "Parameter ArpDstProtocolAddrMode should be fixed/decrement/increment."
        }       
    }
    
    #################ARP parameter configuration#######################

}

############################################################################
#APIName: ConfigIcmpCmdParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigIcmpCmdParameters {streamblock1 args hICMPList} {
   
   set index [lsearch $args -icmpcode]
   if {$index != -1} {
       set IcmpCode [lindex $args [expr $index + 1]]
       foreach hIcmp $hICMPList {
           stc::config $hIcmp -code $IcmpCode 
       }    
   }
            
   set index [lsearch $args -icmpid]
   if {$index != -1} {
       set IcmpId [lindex $args [expr $index + 1]]
       foreach hIcmp $hICMPList {
           stc::config $hIcmp -identifier $IcmpId
           set index [lsearch $args -icmpidmode]
           if {$index !=-1} {
               set IcmpIdMode [lindex $args [expr $index + 1]]
                            
               if {[string tolower $IcmpIdMode] =="increment"} {
                   set icpm_1 [stc::get $hIcmp -Name]
                   set index [lsearch $args -icmpidstep]
                   if {$index != -1} {
                       set IcmpIdStep [lindex $args [expr $index + 1]]
                   } else {
                       set IcmpIdStep 1 
                   }
                   set index [lsearch $args -icmpidcount]
                   if {$index != -1} {
                       set IcmpIdCount [lindex $args [expr $index + 1]]
                   } else {
                       set IcmpIdCount 1
                   }
                   if {$m_IcmpIdRangeModifierList($streamblock1) == ""} {
                       set m_IcmpIdRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIcmp -identifier] \
                            -Mask 65535  -OffsetReference $icpm_1.identifier -StepValue $IcmpIdStep \
                            -Offset 0 -ModifierMode INCR -RecycleCount $IcmpIdCount -RepeatCount 0]  
                    } else {
                         stc::config $m_IcmpIdRangeModifierList($streamblock1) -Data [stc::get $hIcmp -identifier] \
                            -Mask 65535  -OffsetReference $icpm_1.identifier -StepValue $IcmpIdStep \
                            -Offset 0 -ModifierMode INCR -RecycleCount $IcmpIdCount -RepeatCount 0
                    }
                } elseif {[string tolower $IcmpIdMode] =="decrement"} {
                   set icpm_1 [stc::get $hIcmp -Name]
                   set index [lsearch $args -icmpidstep]
                   if {$index != -1} {
                       set IcmpIdStep [lindex $args [expr $index + 1]]
                   } else {
                       set IcmpIdStep 1
                   }
                   set index [lsearch $args -icmpidcount]
                   if {$index != -1} {
                       set IcmpIdCount [lindex $args [expr $index + 1]]
                   } else {
                       set IcmpIdCount 1
                   }
                   if {$m_IcmpIdRangeModifierList($streamblock1) == ""} {
                       set m_IcmpIdRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIcmp -identifier] \
                            -Mask 65535  -OffsetReference $icpm_1.identifier -StepValue $IcmpIdStep \
                            -Offset 0 -ModifierMode DECR -RecycleCount $IcmpIdCount -RepeatCount 0]  
                    } else {
                         stc::config $m_IcmpIdRangeModifierList($streamblock1) -Data [stc::get $hIcmp -identifier] \
                            -Mask 65535  -OffsetReference $icpm_1.identifier -StepValue $IcmpIdStep \
                            -Offset 0 -ModifierMode DECR -RecycleCount $IcmpIdCount -RepeatCount 0
                    }     
                } elseif  {[string tolower $IcmpIdMode] =="fixed"} {
                    if {$m_IcmpIdRangeModifierList($streamblock1) != ""} {
                          stc::delete $m_IcmpIdRangeModifierList($streamblock1)
                          set m_IcmpIdRangeModifierList($streamblock1) ""
                    } 
                } else {
                    error "Parameter IcmpIdMode should be fixed/decrement/increment."
                } 
             }         
         }    
     }
     set index [lsearch $args -icmpseq]
     if {$index != -1} {
         set IcmpSeq [lindex $args [expr $index + 1]]
         foreach hIcmp $hICMPList {
             stc::config $hIcmp -seqNum $IcmpSeq 
             set index [lsearch $args -icmpseqmode]
             if {$index !=-1} {
                 set IcmpSeqMode [lindex $args [expr $index + 1]]
                            
                 if {[string tolower $IcmpSeqMode] =="increment"} {
                     set icpm_1 [stc::get $hIcmp -Name]
                     set index [lsearch $args -icmpseqstep]
                     if {$index != -1} {
                         set IcmpSeqStep [lindex $args [expr $index + 1]]
                     } else {
                         set IcmpSeqStep 1
                     }
                     set index [lsearch $args -icmpseqcount]
                     if {$index != -1} {
                         set IcmpSeqCount [lindex $args [expr $index + 1]]
                     } else {
                          set IcmpSeqCount 1
                     }
                     
                     if {$m_IcmpSeqRangeModifierList($streamblock1) == ""} {
                         set m_IcmpSeqRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIcmp -seqNum] \
                                -Mask 65535  -OffsetReference $icpm_1.seqNum -StepValue $IcmpSeqStep \
                                -Offset 0 -ModifierMode INCR -RecycleCount $IcmpSeqCount -RepeatCount 0]  
                     } else {
                         stc::config  $m_IcmpSeqRangeModifierList($streamblock1) -Data [stc::get $hIcmp -seqNum] \
                                -Mask 65535  -OffsetReference $icpm_1.seqNum -StepValue $IcmpSeqStep \
                                -Offset 0 -ModifierMode INCR -RecycleCount $IcmpSeqCount -RepeatCount 0
                    }
                 } elseif {[string tolower $IcmpSeqMode] =="decrement"} {
                     set icpm_1 [stc::get $hIcmp -Name]
                     set index [lsearch $args -icmpseqstep]
                     if {$index != -1} {
                         set IcmpSeqStep [lindex $args [expr $index + 1]]
                     } else {
                        set  IcmpSeqStep 1
                     }
                     set index [lsearch $args -icmpseqcount]
                     if {$index != -1} {
                         set IcmpSeqCount [lindex $args [expr $index + 1]]
                     } else {
                         set  IcmpSeqCount  1
                     }
                     if {$m_IcmpSeqRangeModifierList($streamblock1) == ""} {
                         set m_IcmpSeqRangeModifierList($streamblock1) [stc::create RangeModifier -under $streamblock1 -Data [stc::get $hIcmp -seqNum] \
                                -Mask 65535  -OffsetReference $icpm_1.seqNum -StepValue $IcmpSeqStep \
                                -Offset 0 -ModifierMode DECR -RecycleCount $IcmpSeqCount -RepeatCount 0]  
                     } else {
                         stc::config  $m_IcmpSeqRangeModifierList($streamblock1) -Data [stc::get $hIcmp -seqNum] \
                                -Mask 65535  -OffsetReference $icpm_1.seqNum -StepValue $IcmpSeqStep \
                                -Offset 0 -ModifierMode DECR -RecycleCount $IcmpSeqCount -RepeatCount 0
                    }   
                 } elseif  {[string tolower $IcmpSeqMode] =="fixed"} {
                      if {$m_IcmpSeqRangeModifierList($streamblock1) != ""} {
                            stc::delete $m_IcmpSeqRangeModifierList($streamblock1)
                            set m_IcmpSeqRangeModifierList($streamblock1) ""
                      }
        
                 } else {
                     error "Parameter IcmpSeqMode should be fixed/decrement/increment."
                 } 
              }       
          }    
     }
}

############################################################################
#APIName: ConfigIcmpStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigIcmpStreamParameters {streamblock1 args} {
    set args [eval subst $args ]
    
    set icmpParameterExist "FALSE"
    #################ICMP parameter configuration#######################
    #Parse IcmpType/IcmpCode/IcmpId/IcmpSeq parameter
    set index [lsearch $args -icmptype] 
    if {$index != -1} {
        set IcmpType [lindex $args [expr $index + 1]]
        set icmpParameterExist "TRUE"  
    } else {
        set IcmpType 0
        set icmp_index [lsearch $args "-icmp*"]
        if {$icmp_index != -1} {
           set icmpParameterExist "TRUE"  
        }  
        set IcmpType 0
    }
        
    if {$icmpParameterExist == "TRUE" } {
        if {[string tolower $IcmpType] == "3"} {
           
            set hICMPList [stc::create icmp:IcmpDestUnreach -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            set index [lsearch $args -icmpcode]
            if {$index != -1} {
                set IcmpCode [lindex $args [expr $index + 1]]
                foreach hIcmp $hICMPList {
                    stc::config $hIcmp -code $IcmpCode 
                }    
            }                        
        } elseif {[string tolower $IcmpType] =="0"} {
            
            set hICMPList [stc::create icmp:IcmpEchoReply -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList
            
       } elseif {[string tolower $IcmpType] =="8"} {
           
            set hICMPList [stc::create icmp:IcmpEchoRequest -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList
           
            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList
               
       } elseif {[string tolower $IcmpType] =="16"} {
           
            set hICMPList [stc::create icmp:IcmpInfoReply -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList   
            
       } elseif {[string tolower $IcmpType] =="15"} {
             
            set hICMPList [stc::create icmp:IcmpInfoRequest -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList   
            
       } elseif {[string tolower $IcmpType] =="12"} {
             
            set hICMPList [stc::create icmp:IcmpParameterProblem -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            set index [lsearch $args -icmpcode]
            if {$index != -1} {
                set IcmpCode [lindex $args [expr $index + 1]]
                foreach hIcmp $hICMPList {
                    stc::config $hIcmp -code $IcmpCode 
                }    
            }
       } elseif {[string tolower $IcmpType] =="5"} {
           
            set hICMPList [stc::create icmp:IcmpRedirect -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            set index [lsearch $args -icmpcode]
            if {$index != -1} {
                set IcmpCode [lindex $args [expr $index + 1]]
                foreach hIcmp $hICMPList {
                    stc::config $hIcmp -code $IcmpCode 
                }    
            }
       } elseif {[string tolower $IcmpType] =="4"} {
          
           set hICMPList [stc::create icmp:IcmpSourceQuench -under $streamblock1]
            set m_IcmpCmdList($streamblock1) $hICMPList

            set index [lsearch $args -icmpcode]
            if {$index != -1} {
                set IcmpCode [lindex $args [expr $index + 1]]
                foreach hIcmp $hICMPList {
                    stc::config $hIcmp -code $IcmpCode 
                }    
            }
        } elseif {[string tolower $IcmpType] =="11"} {
           
           set hICMPList [stc::create icmp:IcmpTimeExceeded -under $streamblock1]
           set m_IcmpCmdList($streamblock1) $hICMPList

           set index [lsearch $args -icmpcode]
            if {$index != -1} {
                set IcmpCode [lindex $args [expr $index + 1]]
                foreach hIcmp $hICMPList {
                    stc::config $hIcmp -code $IcmpCode 
                }    
            }
        } elseif {[string tolower $IcmpType] =="13"} {
           
           set hICMPList [stc::create icmp:IcmpTimestampRequest -under $streamblock1]
           set m_IcmpCmdList($streamblock1) $hICMPList

            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList
            
        } elseif {[string tolower $IcmpType] =="14"} {
          
           set hICMPList [stc::create icmp:IcmpTimestampReply -under $streamblock1]
           set m_IcmpCmdList($streamblock1) $hICMPList

            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList
        } else {
            set hICMPList [stc::create icmp:IcmpEchoRequest -under $streamblock1 -Type $IcmpType]
            set m_IcmpCmdList($streamblock1) $hICMPList
           
            ConfigIcmpCmdParameters $streamblock1 $args $hICMPList
       }
    }
    #################ICMP parameters configuration#######################
    
}

############################################################################
#APIName: ConfigStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################

::itcl::body TrafficEngine::ConfigStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    ConfigEthStreamParameters $streamblock1 $args
     
    ConfigVlanStreamParameters $streamblock1 $args
    
    ConfigIPV4StreamParameters $streamblock1 $args
    
    ConfigTcpStreamParameters $streamblock1 $args
    
    ConfigUdpStreamParameters $streamblock1 $args
        
    ConfigIPV6StreamParameters $streamblock1 $args
    
    ConfigArpStreamParameters $streamblock1 $args
    
    ConfigIcmpStreamParameters $streamblock1 $args     
}

############################################################################
#APIName: Dec2Bin
#Description: Convert Dec to Binary
#             internal use only
#Coded by: Penn
#############################################################################
::itcl::body TrafficEngine::Dec2Bin {args} {
    set byte 0
    switch $args {
        0 {set byte 000 }
        1 {set byte 001 }
        2 {set byte 010 }
        3 {set byte 011 }
        4 {set byte 100 }
        5 {set byte 101 }
        6 {set byte 110 }
        7 {set byte 111 }
        default {   error "The Exp value for mpls lable must be 0-7" }
    }
    return $byte  
}

############################################################################
#APIName: CreateProfile
#Description: Create profile in TrafficEngine
#Input: 1. args:argument list，including
#              (1) -Name Name required,Profile name
#              (2) -Type Type optional,Constant Burst
#              (3) -TrafficLoad TrafficLoad optional，profile load，i.e -StreamLoad 1000                
#              (4) -TrafficLoadUnit TrafficLoadUnit optional，traffic load unit，i.e -TrafficLoadUnit fps
#              (5) -BurstSize BurstSize, optional，Burst size
#              (6) -FrameNum FrameNum, optional，total fram number
#              (7) -Blocking blocking, blocking mode，Enable/Disable
#              (8) -DistributeMode DistributeMode
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body TrafficEngine::CreateProfile {args} {

    #Convert attribute of input parameters to lower case
    set index [lsearch $args -help] 
    if {$index != -1} {
        puts "CreateProfile API: "
        puts "-Name Name ????,Profile???"
        puts "-Type Type ????,Constant Burst"        
        puts "-TrafficLoad TrafficLoad ????,???????,? -TrafficLoad 1000 "
        puts "-TrafficLoadUnit TrafficLoadUnit ????,?????????,? -TrafficLoadUnit fps/kbps/mbps/precent "
        puts "-BurstSize BurstSize ????,Burst?????????? "
        puts "-FrameNum FrameNum, ????,????????? "        
        puts "-Blocking blocking ????,Enable/Disable"
        return $::mainDefine::gSuccess
    } 
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TrafficEngine::CreateProfile..."

    #Parse name parameter
    set index [lsearch $args -name] 
    if {$index != -1} {
        set name [lindex $args [expr $index + 1]]
    } else {
         error "You must specify the profile name in CreateProfile"
    } 

    #Check whether or not profile already exists in m_trafficProfileList
    set index [lsearch $m_trafficProfileList $name]
    if { $index != -1} {
        error "The profile name($name) is already existed, please specify another one. These existed profile names are:\n$m_trafficProfileList"
        puts "exit the proc of TrafficEngine::CreateProfile" 
        return $::mainDefine::gFail
    } else {
        lappend m_trafficProfileList $name
    }   
        
    #Parse type parameter
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [expr $index + 1]]
    } else {
        set type $m_type
    }
    lappend m_profileConfig($name) -type  
    lappend m_profileConfig($name) $type
    #Parse TrafficLoad parameter
    set index [lsearch $args -trafficload] 
    if {$index != -1} {
        set trafficLoad [lindex $args [expr $index + 1]]
    } else {
        set trafficLoad $m_trafficLoad
    }
    lappend m_profileConfig($name) -trafficload  
    lappend m_profileConfig($name) $trafficLoad
    
    #Parse TrafficLoadUnit parameter
    set index [lsearch $args -trafficloadunit] 
    if {$index != -1} {
        set trafficLoadUnit [lindex $args [expr $index + 1]]
    } else {
        set trafficLoadUnit $m_trafficLoadUnit
    }
    lappend m_profileConfig($name) -trafficloadunit  
    lappend m_profileConfig($name) $trafficLoadUnit     

    #Parse BurstSize parameter
    set index [lsearch $args -burstsize] 
    if {$index != -1} {
        set burstSize [lindex $args [expr $index + 1]]
    } else {
        set burstSize $m_burstSize
    }
    lappend m_profileConfig($name) -burstsize  
    lappend m_profileConfig($name) $burstSize     
    
    #Parse FrameNum parameter
    set index [lsearch $args -framenum] 
    if {$index != -1} {
        set frameNum [lindex $args [expr $index + 1]]
        set m_BurstFlag TRUE        
    } else {
        set frameNum $m_frameNum
        set m_BurstFlag FALSE
    }
	if {[string tolower $type] =="burst"} {
	    set m_BurstFlag TRUE
	} 

	
    lappend m_profileConfig($name) -framenum  
    lappend m_profileConfig($name) $frameNum 

    lappend m_profileConfig($name) -burstflag  
    lappend m_profileConfig($name) $m_BurstFlag 
    
    #Parse Blocking parameter
    set index [lsearch $args -blocking ]
    if {$index != -1} {
        set blocking [lindex $args [expr $index + 1]]
        if {[string tolower $blocking] =="enable"} { 
             set blocking "TRUE"
        } elseif {[string tolower $blocking] =="disable"} {
             set blocking "FALSE"
        }  
        set m_blocking $blocking
    } else {
        set blocking $m_blocking
    }      
    lappend m_profileConfig($name) -blocking  
    lappend m_profileConfig($name) $blocking 
    
    set m_trafficProfileContent($name) ""
 
    debugPut "exit the proc of TrafficEngine::CreateProfile..." 
    return $::mainDefine::gSuccess
}
    
 ############################################################################
#APIName: DestroyProfile
#Description: Destroy profile
#Input: 1. args:argument list，including
#              (1) -Name Name required,Profile name
#Output: None
#Coded by: Penn
#############################################################################
::itcl::body TrafficEngine::DestroyProfile {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TrafficEngine::DestroyProfile..."

    #Parse profilename parameter
    set index [lsearch $args -profilename] 
    if {$index != -1} {
        set name [lindex $args [expr $index + 1]]
    } else {

        #Parse name parameter
        set index [lsearch $args -name] 
        if {$index != -1} {
            set name [lindex $args [expr $index + 1]]
        }  
    }

    #Check whether or not profile already exists in m_trafficProfileList
    set index [lsearch $m_trafficProfileList $name]
    if { $index == -1} {
        error "The profile name($name) is not existed, please specify another one. These existed profile names are:\n$m_trafficProfileList"
        puts "exit the proc of TrafficEngine::DestroyProfile" 
        return $::mainDefine::gFail
    }  

    set m_trafficProfileList [lreplace $m_trafficProfileList $index $index ]
    catch {unset m_profileConfig($name) } 

    set index [lsearch $m_activeProfileNameList $name]
    if { $index != -1} {
         set m_activeProfileNameList [lreplace $m_activeProfileNameList $index $index ]
    }
    
    debugPut "exit the proc of TrafficEngine::DestroyProfile..." 
    return $::mainDefine::gSuccess
}
   
############################################################################
#APIName: ConfigProfile
#Description: Config profile parameters
#Input: 1. args:argument list，including
#              (1) -Name Name required,Profile name
#              (2) -Type Type optional,Constant Burst
#              (3) -TrafficLoad TrafficLoad optional，profile load，i.e -StreamLoad 1000                
#              (4) -TrafficLoadUnit TrafficLoadUnit optional，traffic load unit，i.e -TrafficLoadUnit fps
#              (5) -BurstSize BurstSize, optional，Burst size
#              (6) -FrameNum FrameNum, optional，total fram number
#              (7) -Blocking blocking, blocking mode，Enable/Disable
#              (8) -DistributeMode DistributeMode
#Output: None
#Coded by: Jaimin
#Modified by: Penn
#############################################################################
::itcl::body TrafficEngine::ConfigProfile {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TrafficEngine::ConfigProfile..."

    #Parse name parameter
    set index [lsearch $args -name] 
    if {$index != -1} {
        set name [lindex $args [expr $index + 1]]
    } else {
        set name [lindex $m_trafficProfileList 0]
    }
    
    #Check whether or not profile already exists in m_trafficProfileList
    set index [lsearch $m_trafficProfileList $name]
    if { $index == -1} {
        error "The profile name($name) does not exist, existed profile names are:\n$m_trafficProfileList"
        puts "exit the proc of TrafficEngine::ConfigProfile" 
        return $::mainDefine::gFail
    }
       
    #Parse type parameter
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [expr $index + 1]]
        set index [lsearch $m_profileConfig($name) -type]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $type] 

        if {[string tolower $type] == "constant"} {
            set index [lsearch $m_profileConfig($name) -burstflag]
            set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] "FALSE"] 
        }        
    } 
    
    #Parse TrafficLoad parameter
    set index [lsearch $args -trafficload] 
    if {$index != -1} {
        set trafficLoad [lindex $args [expr $index + 1]]
        set index [lsearch $m_profileConfig($name) -trafficload]
        
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $trafficLoad]         
    } 

    #Parse TrafficLoadUnit parameter
    set index [lsearch $args -trafficloadunit] 
    if {$index != -1} {
        set trafficLoadUnit [lindex $args [expr $index + 1]]
        set index [lsearch $m_profileConfig($name) -trafficloadunit]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $trafficLoadUnit]         
    }

    #Parse BurstSize parameter
    set index [lsearch $args -burstsize] 
    if {$index != -1} {
        set burstSize [lindex $args [expr $index + 1]]
        set index [lsearch $m_profileConfig($name) -burstsize]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $burstSize]        
    } 
    
    #Parse FrameNum parameter
    set index [lsearch $args -framenum] 
    if {$index != -1} {
        set m_BurstFlag TRUE      
        set frameNum [lindex $args [expr $index + 1]]
        set index [lsearch $m_profileConfig($name) -framenum]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $frameNum]

        set index [lsearch $m_profileConfig($name) -burstflag]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $m_BurstFlag]
    } 
   
    #Parse Blocking parameter
    set index [lsearch $args -blocking ]
    if {$index != -1} {
        set blocking [lindex $args [expr $index + 1]]
        if {[string tolower $blocking] =="enable"} { 
             set blocking "TRUE"
        } elseif {[string tolower $blocking] =="disable"} {
             set blocking "FALSE"
        } 
        set index [lsearch $m_profileConfig($name) -blocking]
        set m_profileConfig($name) [lreplace $m_profileConfig($name) [expr $index + 1] [expr $index + 1] $blocking]           
    } 
   
   if {$m_trafficProfileContent($name) != ""} {
        AdjustProfileStreamLoads $name
   }
 
    debugPut "exit the proc of TrafficEngine::ConfigProfile..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigLayerStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::ConfigLayerStreamParameters {streamblock1 args} {
    set args [eval subst $args ]

    set L2Flag 0
    set L3Flag 0
    #Parse L2 parameter
    set index [lsearch $args -l2] 
    if {$index != -1} {
        set L2 [lindex $args [expr $index + 1]]
        set m_L2TypeList($streamblock1) [string tolower $L2] 

        if {[string tolower $L2] =="ethernet"} {
            set eth1 [stc::create ethernet:EthernetII -under $streamblock1]   
        } elseif {[string tolower $L2] =="ethernet_vlan"} {
            set eth1 [stc::create ethernet:EthernetII -under $streamblock1]
            set vlans1 [stc::create vlans -under $eth1]
            set vlan1 [stc::create vlan -under $vlans1]                  
        } elseif {[string tolower $L2] =="ethernet_mpls"} {
            stc::create ethernet:EthernetII -under $streamblock1
            ConfigMplsStreamParameters $streamblock1 $args
        } elseif {[string tolower $L2] =="ethernet_vlan_mpls"} {
            set eth1 [stc::create ethernet:EthernetII -under $streamblock1]            
            set vlans1 [stc::create vlans -under $eth1]
            set vlan1 [stc::create vlan -under $vlans1]            
            ConfigMplsStreamParameters $streamblock1 $args
        } else {
            error "L2 parameter should be one of  the list {Ethernet | Ethernet_Vlan | Ethernet_MPLS | Ethernet_Vlan_MPLS}"
        }
    } else {
        set L2Flag 1
        set m_L2TypeList($streamblock1) "ethernet" 
    }
    
    #Parse L3 parameter
    set index [lsearch $args -l3] 
    if {$index != -1} {
        if {$m_boundStreamFlag==0} { 
			if {$L2Flag ==1} {
				stc::create ethernet:EthernetII -under $streamblock1
				set L2Flag 0
			}
		}

        set L3 [lindex $args [expr $index + 1]]
        set m_L3TypeList($streamblock1) [string tolower $L3] 

        if {[string tolower $L3] =="ipv4"} {
            stc::create ipv4:IPv4 -under $streamblock1            
        } elseif {[string tolower $L3] =="ipv6"} {
            stc::create ipv6:IPv6 -under $streamblock1
        } elseif {[string tolower $L3] =="arp"} {
            stc::create arp:ARP -under $streamblock1
        } elseif {[string tolower $L3] =="none"} {
            #stc::create ipv4:IPv4 -under $streamblock1            
        } else {
            error "L3 parameter should be one of  the list {IPv4 | IPv6 | ARP | NONE}"
        }
    } else {
        set m_L3TypeList($streamblock1) "ipv4"
        set L3Flag 1
    }
     
    set m_IcmpArgsList($streamblock1) ""

    #Parse L4 parameter
    set index [lsearch $args -l4] 
    if {$index != -1} {
        set L4 [lindex $args [expr $index + 1]]
		if {$m_boundStreamFlag==0} {
			if {$L2Flag ==1} {
				stc::create ethernet:EthernetII -under $streamblock1
				set L2Flag 0
			}
			if {$L3Flag ==1} {
				stc::create ipv4:IPv4 -under $streamblock1
				set L3Flag 0
			}
		}
		
        if {[string tolower $L4] =="tcp"} {
            stc::create tcp:Tcp -under $streamblock1
        } elseif {[string tolower $L4] =="udp"} {
            stc::create udp:Udp -under $streamblock1
        } elseif {[string tolower $L4] =="none"} {
            #stc::create tcp:Tcp -under $streamblock1
        } elseif {[string tolower $L4] =="icmp"} {
            set m_IcmpArgsList($streamblock1) $args
        }
    }
}

############################################################################
#APIName: ConfigMplsStreamParameters
#Description: Configure the parameters of stream according to input parameters
#                  internal use only
#Input: 1. streamblock1: stream handle
#         2. args:argument list
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::ConfigMplsStreamParameters {streamblock1 args} {
    set args [eval subst $args ]
    
    set mplsunicast_hex_value 8847
    set mplsmulticast_hex_value 8848
    set lable_number_flag 1   

    #Parse MplsType parameter
    set index [lsearch $args -mplstype] 
    if {$index != -1} {
        set mplstype [lindex $args [expr $index + 1]]
    } else {
        set mplstype "mplsunicast"
    }
    #Modify the eth type according to MPLS type
    set hEth [stc::get $streamblock1 -children-ethernet:EthernetII]
    if {$hEth ==""} {
        set hEth [stc::create ethernet:EthernetII -under $streamblock1]
    } 
     
    if {[string tolower $mplstype] =="mplsunicast"} {
        stc::config $hEth -etherType $mplsunicast_hex_value
    } elseif {[string tolower $mplstype] =="mplsmulticast"} {
        stc::config $hEth -etherType $mplsmulticast_hex_value              
    } else {
        error "MplsType parameter should be one of the list {MplsUnicast | MplsMulticast}"
    }    

    #Parse MplsLabel, MplsLabelCount, MplsLableMode, MplsLableStep, MplsExp, MplsTTL, MplsBottomOfStack
    set index [lsearch $args -mplslabel] 
    if {$index != -1} {
        set mplslabel1 [lindex $args [expr $index + 1]]
        set lable_number_flag 1  
        set m_mplsLabelList($streamblock1,1) $mplslabel1    
    } else {
        set mplslabel1 $m_mplsLabelList($streamblock1,1)
    }    
    set index [lsearch $args -mplslabelcount] 
    if {$index != -1} {
        set mplslabelcount1 [lindex $args [expr $index + 1]]
        set m_mplsLabelCountList($streamblock1,1) $mplslabelcount1
        set lable_number_flag 1  
    } else {
        set mplslabelcount1 $m_mplsLabelCountList($streamblock1,1)
    }         
    set index [lsearch $args -mplslabelmode] 
    if {$index != -1} {
        set mplslabelmode1 [lindex $args [expr $index + 1]]
        set m_mplsLabelModeList($streamblock1,1) $mplslabelmode1
        set lable_number_flag 1  
    } else {
        set mplslabelmode1 $m_mplsLabelModeList($streamblock1,1)
    }
    set index [lsearch $args -mplslabelstep] 
    if {$index != -1} {
        set mplslabelstep1 [lindex $args [expr $index + 1]]
        set m_mplsLabelStepList($streamblock1,1) $mplslabelstep1
        set lable_number_flag 1  
    } else {
        set mplslabelstep1 $m_mplsLabelStepList($streamblock1,1)
    }  
    set index [lsearch $args -mplsexp] 
    if {$index != -1} {
        set mplsexp1 [lindex $args [expr $index + 1]]
        set m_mplsExpList($streamblock1,1) $mplsexp1
        set lable_number_flag 1  
    } else {
        set mplsexp1 $m_mplsExpList($streamblock1,1)
    }      
    set index [lsearch $args -mplsttl] 
    if {$index != -1} {
        set mplsttl1 [lindex $args [expr $index + 1]]
        set m_mplsTtlList($streamblock1,1) $mplsttl1
        set lable_number_flag 1  
    } else {
        set mplsttl1 $m_mplsTtlList($streamblock1,1)
    }      
    set index [lsearch $args -mplsbottomofstack] 
    if {$index != -1} {
        set mplsbottomofstack1 [lindex $args [expr $index + 1]]
        set m_mplsBottomOfStackList($streamblock1,1) $mplsbottomofstack1
        set lable_number_flag 1  
    } else {
        set mplsbottomofstack1 $m_mplsBottomOfStackList($streamblock1,1)
    }    
    
    #Parse MplsLabe2, MplsLabelCount2, MplsLableMode2, MplsLableStep2, MplsExp2, MplsTTL2, MplsBottomOfStack2
    set index [lsearch $args -mplslabel2] 
    if {$index != -1} {
        set mplslabel2 [lindex $args [expr $index + 1]]
        set m_mplsLabelList($streamblock1,2) $mplslabel2    
        set lable_number_flag 2        
    } else {
        set mplslabel2 $m_mplsLabelList($streamblock1,2)
    }    
    set index [lsearch $args -mplslabelcount2] 
    if {$index != -1} {
        set mplslabelcount2 [lindex $args [expr $index + 1]]
        set m_mplsLabelCountList($streamblock1,2) $mplslabelcount2
        set lable_number_flag 2  
    } else {
        set mplslabelcount2 $m_mplsLabelCountList($streamblock1,2)
    }         
    set index [lsearch $args -mplslabelmode2] 
    if {$index != -1} {
        set mplslabelmode2 [lindex $args [expr $index + 1]]
        set m_mplsLabelModeList($streamblock1,2) $mplslabelmode2
        set lable_number_flag 2  
    } else {
        set mplslabelmode2 $m_mplsLabelModeList($streamblock1,2)
    }
    set index [lsearch $args -mplslabelstep2] 
    if {$index != -1} {
        set mplslabelstep2 [lindex $args [expr $index + 1]]
        set m_mplsLabelStepList($streamblock1,2) $mplslabelstep2
        set lable_number_flag 2  
    } else {
        set mplslabelstep2 $m_mplsLabelStepList($streamblock1,2)
    }  
    set index [lsearch $args -mplsexp2] 
    if {$index != -1} {
        set mplsexp2 [lindex $args [expr $index + 1]]
        set m_mplsExpList($streamblock1,2) $mplsexp2
        set lable_number_flag 2  
    } else {
        set mplsexp2 $m_mplsExpList($streamblock1,2)
    }      
    set index [lsearch $args -mplsttl2] 
    if {$index != -1} {
        set mplsttl2 [lindex $args [expr $index + 1]]
        set m_mplsTtlList($streamblock1,2) $mplsttl2
        set lable_number_flag 2  
    } else {
        set mplsttl2 $m_mplsTtlList($streamblock1,2)
    }      
    set index [lsearch $args -mplsbottomofstack2] 
    if {$index != -1} {
        set mplsbottomofstack2 [lindex $args [expr $index + 1]]
        set m_mplsBottomOfStackList($streamblock1,2) $mplsbottomofstack2
        set lable_number_flag 2  
    } else {
        set mplsbottomofstack2 $m_mplsBottomOfStackList($streamblock1,2)
    }     
    
    #Parse MplsLabe3, MplsLabelCount3, MplsLableMode3, MplsLableStep3, MplsExp3, MplsTTL3, MplsBottomOfStack3
    set index [lsearch $args -mplslabel3] 
    if {$index != -1} {
        set mplslabel3 [lindex $args [expr $index + 1]]
        set m_mplsLabelList($streamblock1,3) $mplslabel3
        set lable_number_flag 3        
    } else {
        set mplslabel3 $m_mplsLabelList($streamblock1,3)
    }    
    set index [lsearch $args -mplslabelcount3] 
    if {$index != -1} {
        set mplslabelcount3 [lindex $args [expr $index + 1]]
        set m_mplsLabelCountList($streamblock1,3) $mplslabelcount3
        set lable_number_flag 3    
    } else {
        set mplslabelcount3 $m_mplsLabelCountList($streamblock1,3)
    }         
    set index [lsearch $args -mplslabelmode3] 
    if {$index != -1} {
        set mplslabelmode3 [lindex $args [expr $index + 1]]
        set m_mplsLabelModeList($streamblock1,3) $mplslabelmode3
        set lable_number_flag 3    
    } else {
        set mplslabelmode3 $m_mplsLabelModeList($streamblock1,3)
    }
    set index [lsearch $args -mplslabelstep3] 
    if {$index != -1} {
        set mplslabelstep3 [lindex $args [expr $index + 1]]
        set m_mplsLabelStepList($streamblock1,3) $mplslabelstep3
        set lable_number_flag 3    
    } else {
        set mplslabelstep3 $m_mplsLabelStepList($streamblock1,3)
    }  
    set index [lsearch $args -mplsexp3] 
    if {$index != -1} {
        set mplsexp3 [lindex $args [expr $index + 1]]
        set m_mplsExpList($streamblock1,3) $mplsexp3
        set lable_number_flag 3    
    } else {
        set mplsexp3 $m_mplsExpList($streamblock1,3)
    }      
    set index [lsearch $args -mplsttl3] 
    if {$index != -1} {
        set mplsttl3 [lindex $args [expr $index + 1]]
        set m_mplsTtlList($streamblock1,3) $mplsttl3
        set lable_number_flag 3    
    } else {
        set mplsttl3 $m_mplsTtlList($streamblock1,3)
    }      
    set index [lsearch $args -mplsbottomofstack3] 
    if {$index != -1} {
        set mplsbottomofstack3 [lindex $args [expr $index + 1]]
        set m_mplsBottomOfStackList($streamblock1,3) $mplsbottomofstack3
        set lable_number_flag 3    
    } else {
        set mplsbottomofstack3 $m_mplsBottomOfStackList($streamblock1,3)
    }  
    
    #Parse MplsLabe4, MplsLabelCount4, MplsLableMode4, MplsLableStep4, MplsExp4, MplsTTL4, MplsBottomOfStack4
    set index [lsearch $args -mplslabel4] 
    if {$index != -1} {
        set mplslabel4 [lindex $args [expr $index + 1]]
        set m_mplsLabelList($streamblock1,4) $mplslabel4
        set lable_number_flag 4
    } else {
        set mplslabel4 $m_mplsLabelList($streamblock1,4) 
    }    
    set index [lsearch $args -mplslabelcount4] 
    if {$index != -1} {
        set mplslabelcount4 [lindex $args [expr $index + 1]]
        set m_mplsLabelCountList($streamblock1,4) $mplslabelcount4
        set lable_number_flag 4
    } else {
        set mplslabelcount4 $m_mplsLabelCountList($streamblock1,4)
    }         
    set index [lsearch $args -mplslabelmode4] 
    if {$index != -1} {
        set mplslabelmode4 [lindex $args [expr $index + 1]]
        set m_mplsLabelModeList($streamblock1,4) $mplslabelmode4
        set lable_number_flag 4
    } else {
        set mplslabelmode4 $m_mplsLabelModeList($streamblock1,4)
    }
    set index [lsearch $args -mplslabelstep4] 
    if {$index != -1} {
        set mplslabelstep4 [lindex $args [expr $index + 1]]
        set m_mplsLabelStepList($streamblock1,4) $mplslabelstep4
        set lable_number_flag 4
    } else {
        set mplslabelstep4 $m_mplsLabelStepList($streamblock1,4)
    }  
    set index [lsearch $args -mplsexp4] 
    if {$index != -1} {
        set mplsexp4 [lindex $args [expr $index + 1]]
        set m_mplsExpList($streamblock1,4) $mplsexp4
        set lable_number_flag 4
    } else {
        set mplsexp4 $m_mplsExpList($streamblock1,4)
    }      
    set index [lsearch $args -mplsttl4] 
    if {$index != -1} {
        set mplsttl4 [lindex $args [expr $index + 1]]
        set m_mplsTtlList($streamblock1,4) $mplsttl4
        set lable_number_flag 4
    } else {
        set mplsttl4 $m_mplsTtlList($streamblock1,4)
    }      
    set index [lsearch $args -mplsbottomofstack4] 
    if {$index != -1} {
        set mplsbottomofstack4 [lindex $args [expr $index + 1]]
        set m_mplsBottomOfStackList($streamblock1,4) $mplsbottomofstack4
        set lable_number_flag 4
    } else {
        set mplsbottomofstack4 $m_mplsBottomOfStackList($streamblock1,4)
    }     

    #Check whether or not MPLS header already exists. If exists, then overwrite them; otherwise create new MPLS headers
    set hChildrenList [stc::get $streamblock1 -children]
    set hMplsList ""

    foreach sr $hChildrenList {
        if {[string match "mpls*" $sr]} {
            lappend hMplsList $sr
        }
    }     

    for {set i 1} {$i <= $lable_number_flag} {incr i} {
        set hMpls [lindex $hMplsList [expr $i-1]]
        if {$hMpls == ""} {
            set hMpls [stc::create mpls:Mpls -under $streamblock1]
        }          
        set mpls_name [stc::get $hMpls -name] 
        set Mode [subst $[subst mplslabelmode$i]]
        set Mode [string tolower $Mode]
     
        set bottomofstack [subst $[subst mplsbottomofstack$i]]
        if {[string tolower $bottomofstack] == "auto" } {
            if {$i != $lable_number_flag} {
                set bottomofstack "0"
            } else {
                set bottomofstack "1"
            }
        }

        if {$Mode == "fixed"} {
            stc::config $hMpls \
                -label [subst $[subst mplslabel$i]] \
                -exp [Dec2Bin [subst $[subst mplsexp$i]]] \
                -ttl [subst $[subst mplsttl$i]] \
                -sBit $bottomofstack

            if {[subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] != ""} {
                stc::delete [subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]]    
                set [subst m_MplsLabelRangeModifierList$i\($streamblock1)] ""            
            }
        } elseif {$Mode == "increment"} {
            stc::config $hMpls \
                -label [subst $[subst mplslabel$i]] \
                -exp [Dec2Bin [subst $[subst mplsexp$i]]] \
                -ttl [subst $[subst mplsttl$i]] \
                -sBit $bottomofstack  
      
            if {[subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] == ""} {
                set [subst m_MplsLabelRangeModifierList$i\($streamblock1)] [stc::create RangeModifier \
                    -under $streamblock1 \
                    -EnableStream "FALSE" \
                    -Data [subst $[subst mplslabel$i]] -Mask 0xFFFF \
                    -OffsetReference $mpls_name.label \
                    -Offset 0 -RepeatCount 0 \
                    -ModifierMode INCR \
                    -RecycleCount [subst $[subst mplslabelcount$i]] \
                    -StepValue [subst $[subst mplslabelstep$i]] ]
            } else {
                stc::config [subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] \
                    -EnableStream "FALSE" \
                    -Data [subst $[subst mplslabel$i]] -Mask 0xFFFF \
                    -OffsetReference $mpls_name.label \
                    -Offset 0 -RepeatCount 0 \
                    -ModifierMode INCR \
                    -RecycleCount [subst $[subst mplslabelcount$i]] \
                    -StepValue [subst $[subst mplslabelstep$i]]
              }                
        } elseif {$Mode == "decrement"} {
            stc::config $hMpls \
                -exp [Dec2Bin [subst $[subst mplsexp$i]]] \
                -ttl [subst $[subst mplsttl$i]] \
                -sBit $bottomofstack
            
            if {[subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] == ""} {
                set [subst m_MplsLabelRangeModifierList$i\($streamblock1)] [stc::create RangeModifier \
                    -under $streamblock1 \
                    -EnableStream "FALSE" \
                    -Data [subst $[subst mplslabel$i]] -Mask 0xFFFF \
                    -OffsetReference $mpls_name.label \
                    -Offset 0 -RepeatCount 0 \
                    -ModifierMode DECR \
                    -RecycleCount [subst $[subst mplslabelcount$i]] \
                    -StepValue [subst $[subst mplslabelstep$i]] ]                 
            } else {
                stc::config [subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] \
                    -EnableStream "FALSE" \
                    -Data [subst $[subst mplslabel$i]] -Mask 0xFFFF \
                    -OffsetReference $mpls_name.label \
                    -Offset 0 -RepeatCount 0 \
                    -ModifierMode DECR \
                    -RecycleCount [subst $[subst mplslabelcount$i]] \
                    -StepValue [subst $[subst mplslabelstep$i]] 
            }        
        } else {
            error "MplsLabelMode parameter should be one of the list {fixed | increment | decrement}"
        }                       
    }           
}

############################################################################
#APIName: CreateStream
#Description: Create stream object
#              (1) -StreamName StreamName:required,name of the stream,i.e -StreamName Stream1
#              (2) -FrameLen FrameLen optional,frame length,i.e -FrameLen 128
#              (3) -StreamLoad StreamLoad optional, Stream load，i.e -StreamLoad 1000
#              (4) -StreamLoadUnit StreamLoadUnit optional，Stream load unit，i.e -StreamLoadUnit fps
#              (5) For other parameters please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::CreateStream {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TrafficEngine::CreateStream..."
    
    set StreamLoadFlag 0
    set ProfileLoadFlag 0
    
    #Parse StreamName parameter
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
        set index [lsearch $m_streamNameList $StreamName]
        if {$index != -1} {
            puts "Stream($StreamName) already exists, please specify a new one. Existing streams are: $m_streamNameList"      
            return $::mainDefine::gFail
        }        
    } else  {
        error "please specify the StreamName of the port \nexit the proc of CreateStream..."
    }
    
    set m_streamName $StreamName
    set m_frameLen($StreamName) 128
    set m_frameLenMode($StreamName) "FIXED"
    set m_frameLenCount($StreamName) 1
    set m_frameLenStep($StreamName) 1
    set m_signature($StreamName) "TRUE"

    #Parse FrameLen parameter
    set index [lsearch $args -framelen] 
    if {$index != -1} {
        set FrameLen [lindex $args [expr $index + 1]]
        set m_frameLen($StreamName) $FrameLen
    } 

    #Parse FrameLenMode parameter
    set index [lsearch $args -framelenmode] 
    if {$index != -1} {
        set FrameLenMode [lindex $args [expr $index + 1]]
        if {[string tolower $FrameLenMode] == "increment"} {
            set FrameLenMode "INCR"
        } elseif {[string tolower $FrameLenMode] == "decrement"} {
            set FrameLenMode "DECR"
        }
        set m_frameLenMode($StreamName) $FrameLenMode
    } 

    #Parse FrameLenStep parameter
    set index [lsearch $args -framelenstep] 
    if {$index != -1} {
        set FrameLenStep [lindex $args [expr $index + 1]]
        set m_frameLenStep($StreamName) $FrameLenStep
    } 

    #Parse FrameLenCount parameter
    set index [lsearch $args -framelencount] 
    if {$index != -1} {
        set FrameLenCount [lindex $args [expr $index + 1]]
        set m_frameLenCount($StreamName) $FrameLenCount       
    } 

    if {$m_frameLenMode($StreamName) == "DECR"} {
        set MinFrameLen [expr $m_frameLen($StreamName) - ($m_frameLenCount($StreamName) - 1) * $m_frameLenStep($StreamName)]
        set MaxFrameLen $m_frameLen($StreamName)
    } else {
        set MinFrameLen $m_frameLen($StreamName)
        set MaxFrameLen [expr $m_frameLen($StreamName) + ($m_frameLenCount($StreamName) - 1) * $m_frameLenStep($StreamName)]
    }
     
    #Parse EnableFcsErrorInsertion parameter
    set index [lsearch $args -enablefcserrorinsertion] 
    if {$index != -1} {
        set EnableCrcErrorInsertion [lindex $args [expr $index + 1]]
    } else {
        set EnableCrcErrorInsertion "FALSE"
    }
    
    set index [lsearch $args -vplspath] 
    if {$index != -1} {
        set VplsPath [lindex $args [expr $index + 1]]
        set index [lsearch $args -boundldp] 
        if {$index != -1} {
            set routerName [lindex $args [expr $index + 1]]
        } else {
            error "please specify the BoundLdp of the VplsPath port \nexit the proc of CreateStream..."
        }
    } else {
        set VplsPath "FALSE"
    }

    #Parse ProfileName parameter
    set index [lsearch $args -profilename] 
    if {$index != -1} {
        set ProfileLoadFlag 1    
        set profilename [lindex $args [expr $index + 1]]
        #Check whether or not profile exists in m_trafficProfileList
        set index [lsearch $m_trafficProfileList $profilename]
        if { $index == -1} {
            error "The profile name($profilename) does not exist, existed profile names are:\n$m_trafficProfileList"
            puts "exit the proc of TrafficEngine::CreateStream" 
            return $::mainDefine::gFail
        }  
        #Build the realationship between stream and profile
        lappend m_trafficProfileContent($profilename) $StreamName  
        set StreamNum [llength $m_trafficProfileContent($profilename)]   
    } else {
        set profilename [lindex $m_trafficProfileList 0]
        lappend m_trafficProfileContent($profilename) $StreamName 
        set StreamNum [llength $m_trafficProfileContent($profilename)] 
    }

    set index [lsearch $m_activeProfileNameList $profilename]
    if { $index == -1} {
         lappend m_activeProfileNameList $profilename
    }
   
    #Get the parameters in profile
    set index [lsearch $m_profileConfig($profilename) -type]
    set type [lindex $m_profileConfig($profilename) [expr $index + 1]]    
    set index [lsearch $m_profileConfig($profilename) -trafficload]
    set trafficLoad [lindex $m_profileConfig($profilename) [expr $index + 1]] 
    set index [lsearch $m_profileConfig($profilename) -trafficloadunit]
    set trafficLoadUnit [lindex $m_profileConfig($profilename) [expr $index + 1]] 
    set index [lsearch $m_profileConfig($profilename) -burstsize]
    set burstSize [lindex $m_profileConfig($profilename) [expr $index + 1]]       
    set index [lsearch $m_profileConfig($profilename) -framenum]
    set frameNum [lindex $m_profileConfig($profilename) [expr $index + 1]] 
    set index [lsearch $m_profileConfig($profilename) -blocking]
    set blocking [lindex $m_profileConfig($profilename) [expr $index + 1]]    
    
    set frameNum [AdjustNum $frameNum $burstSize]
    set burstNum [expr $frameNum/$burstSize] 
    
    set m_streamLoadFlag($StreamName) "FALSE"
    #Parse StreamLoad parameter, if not specified, then the stream laod will be profileLoad/streamNum
    set index [lsearch $args -streamload] 
    if {$index != -1} {
        set StreamLoadFlag 1        
        set StreamLoad [lindex $args [expr $index + 1]]
        set m_streamLoadFlag($StreamName) "TRUE"
    } else {
        set StreamLoad [expr $trafficLoad/$StreamNum]
    }    
       
    set m_streamLoadUnitFlag($StreamName) "FALSE"         
    #Parse StreamLoadUnit parameter
    set index [lsearch $args -streamloadunit] 
    if {$index != -1} {
        set StreamLoadUnit [lindex $args [expr $index + 1]]
        set m_streamLoadUnitFlag($StreamName) "TRUE"         
    } elseif {$trafficLoadUnit != ""} {
        set StreamLoadUnit $trafficLoadUnit
    } else  {
        set StreamLoadUnit fps
    }
    
    #Parse Burst parameter
    set index [lsearch $args -burst ]
    if {$index != -1} {
        set Burst [lindex $args [expr $index + 1]]     
    } else  {
        set Burst Constant
    }

    #Parse signature parameter
    set index [lsearch $args -insertsignature]
    if {$index != -1} {
        set Signature [lindex $args [expr $index + 1]]
        set m_signature($StreamName) $Signature
    } 
    
    #Parse controlplane parameter
    set index [lsearch $args -controlplane]
    if {$index != -1} {
        set controlplane [lindex $args [expr $index + 1]]
    } else {
        set controlplane FALSE
    }     

    #Parse enablestream parameter
    set index [lsearch $args -enablestream]
    if {$index != -1} {
        set enablestream [lindex $args [expr $index + 1]]
    } else {
        set enablestream FALSE
    }     

    #Parse srcPorts parameter
    set index [lsearch $args -srcports]
    if {$index != -1} {
        set SourcePort [lindex $args [expr $index + 1]]
    } 

    #Parse dstPorts parameter
    set index [lsearch $args -dstports]
    if {$index != -1} {
        set DestinationPort [lindex $args [expr $index + 1]]
    } else {
        set DestinationPort ""
    }  
    set ::mainDefine::gBoundStreamDstPort($StreamName) $DestinationPort

    #Parse streamType parameter
    set index [lsearch $args -streamtype]
    if {$index != -1} {
        set StreamType [lindex $args [expr $index + 1]]
    } else {
        set StreamType "normal"
    }  
    set m_streamType($StreamName) $StreamType

    #Parse DstPoolName parameter
    set index [lsearch $args -dstpoolname]
    if {$index != -1} {
        set DstPoolName [lindex $args [expr $index + 1]]
    } 
    #Parse SrcPoolName parameter
    set index [lsearch $args -srcpoolname]
    if {$index != -1} {
        set SrcPoolName [lindex $args [expr $index + 1]]
    }

    #Parse TrafficPattern parameter
    set index [lsearch $args -trafficpattern]
    if {$index != -1} {
        set TrafficPattern [lindex $args [expr $index + 1]]
    } else {
        set TrafficPattern "PAIR"
    }
    set m_trafficPattern($StreamName) $TrafficPattern

   
    #Create StreamBlock, and configure parameters
    set ::mainDefine::objectName $this
    uplevel 1 {
        set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]
    }
    set port $::mainDefine::result
    set ::mainDefine::gStreamSrcPort($StreamName) $port

    set streamBlockHdl ""
    if {[string tolower $StreamLoadUnit] =="fps"} {
        set loadUnit "FRAMES_PER_SECOND"
    } elseif {[string tolower $StreamLoadUnit] =="bps"} {
        set loadUnit "KILOBITS_PER_SECOND"
    } elseif {[string tolower $StreamLoadUnit] =="kbps"} {
        set loadUnit "KILOBITS_PER_SECOND"
    } elseif {[string tolower $StreamLoadUnit] =="mbps"} {
        set loadUnit "MEGABITS_PER_SECOND"   
    } elseif {[string tolower $StreamLoadUnit] =="percent"} {
        set loadUnit "PERCENT_LINE_RATE"
    } else {
        error "Parameter StreamLoadUnit is invalid,please set fps/bps/kbps/mbps/percent. \nexit the proc of CreateStream..."
    }

    set streamBlockHdl [stc::create streamBlock -under $port -EnableStreamOnlyGeneration TRUE -FrameConfig "" \
                  -Active TRUE -InsertSig $m_signature($StreamName) -EnableControlPlane $controlplane -EnableFcsErrorInsertion $EnableCrcErrorInsertion -FixedFrameLength $m_frameLen($StreamName) -LoadUnit $loadUnit \
                  -FrameLengthMode $m_frameLenMode($StreamName) -MinFrameLength $MinFrameLen -MaxFrameLength $MaxFrameLen -Load $StreamLoad -Name $StreamName -StepFrameLength $m_frameLenStep($StreamName)]
     
    if {[string tolower $VplsPath] =="true"} {
      set PathDescriptor1 [stc::create "PathDescriptor" \
        -under $streamBlockHdl \
        -Index "0" \
        -Active "TRUE" \
        -LocalActive "TRUE"]
    }
    #Parse FillType parameter
    set index [lsearch $args -filltype]
    if {$index != -1} {
        set FillType [lindex $args [expr $index + 1]]
        stc::config $streamBlockHdl -FillType $FillType
    } 

    #Parse ConstantFillPattern parameter
    set index [lsearch $args -constantfillpattern]
    if {$index != -1} {
        set ConstantFillPattern [lindex $args [expr $index + 1]]
        stc::config $streamBlockHdl -ConstantFillPattern $ConstantFillPattern
    } 

    #Add the support for Poolname bounding
    if {[string tolower $StreamType] != "normal" && [string tolower $StreamType] != "vpn"} {
        if {[info exists SrcPoolName]&&[info exists DstPoolName]} {

            set srcPoolBlockList ""
            set dstPoolBlockList ""

            foreach srcPoolItem $SrcPoolName {
                if {[info exists ::mainDefine::gPoolCfgBlock($srcPoolItem)]} {
                    lappend srcPoolBlockList $::mainDefine::gPoolCfgBlock($srcPoolItem) 
                } else {
                    error "Pool Name item $srcPoolItem does not exist, please check ..."
                }
            }

            foreach dstPoolItem $DstPoolName {
                if {[info exists ::mainDefine::gPoolCfgBlock($dstPoolItem)]} {
                    lappend dstPoolBlockList $::mainDefine::gPoolCfgBlock($dstPoolItem) 
                } else {
                    error "Pool Name item $dstPoolItem does not exist, please check ..."
                }
            }

            if {$srcPoolBlockList != "" && $dstPoolBlockList != "" } {
                catch {
                    stc::config $streamBlockHdl -SrcBinding-targets " $srcPoolBlockList "
                    stc::config $streamBlockHdl -DstBinding-targets " $dstPoolBlockList "
                    if {[string tolower $VplsPath] =="true"} {
                         stc::config $PathDescriptor1 -SrcBinding-targets " $srcPoolBlockList "
                         stc::config $PathDescriptor1 -DstBinding-targets " $dstPoolBlockList "
                         stc::config $PathDescriptor1 -Encapsulation-targets " $::mainDefine::gLdpBoundMplsIF($routerName) $::mainDefine::gLdpBoundMplsIF($routerName) "
                    }
                    set srcLength [llength $srcPoolBlockList]
                    set dstLength [llength $dstPoolBlockList]

                    if {$srcLength != $dstLength && [string tolower $TrafficPattern] == "pair"} {
                        stc::config $streamBlockHdl -TrafficPattern BACKBONE
                    } 
                    
                    stc::config $streamBlockHdl -EnableTxPortSendingTrafficToSelf TRUE  
                    stc::config $streamBlockHdl -EnableStreamOnlyGeneration "FALSE"
					stc::config $streamBlockHdl -ShowAllHeaders "TRUE"
	                stc::perform Streamblockupdate -Streamblock $streamBlockHdl
                    set m_boundStreamFlag 1
                    set ::mainDefine::gStreamBindingFlag "TRUE"
                    debugPut "Binding the stream block successful, source: $srcPoolBlockList, Destination: $dstPoolBlockList"
               }
            }        
        }
    }
    
    set m_streamBlockHandle($StreamName) $streamBlockHdl
    lappend m_streamNameList $StreamName
    
    set ::mainDefine::gStreamName $StreamName

    set ::mainDefine::gPortName $m_portName

    set ::mainDefine::ghPort $m_hPort

    set ::mainDefine::gPortType $m_portType

    set ::mainDefine::gPortLocation $m_portLocation  

    set ::mainDefine::ghProject $m_hProject   

    set ::mainDefine::gStreamBlockHdl $streamBlockHdl   

    set ::mainDefine::gSignature $m_signature($StreamName) 
    
    set ::mainDefine::gEnableStream $enablestream 
    
     set ::mainDefine::gStreamType $StreamType 

    #Create stream object
    uplevel 1 { 
        Stream $::mainDefine::gStreamName $::mainDefine::gPortName $::mainDefine::ghPort $::mainDefine::gPortType $::mainDefine::gPortLocation \
                   $::mainDefine::ghProject $::mainDefine::gStreamBlockHdl $::mainDefine::gSignature $::mainDefine::gEnableStream $::mainDefine::gStreamName $::mainDefine::gStreamType
    }
     
    #Adjust StreamLoad parameter in profile
    if {$StreamLoadFlag != "1"} {
          AdjustProfileStreamLoads $profilename
    }
   
    set streamblock1 $streamBlockHdl
    set m_CreateStreamArgsList($streamblock1) $args
    
    set m_EthSrcRangeModifierList($streamblock1) ""
    set m_EthDstRangeModifierList($streamblock1) ""
    set m_EthSrcTableModifierList($streamblock1) ""
    set m_EthDstTableModifierList($streamblock1) ""
    set m_EthSrcTableModifierAddrList($streamblock1) "00:10:94:00:00:02"
    set m_EthDstTableModifierAddrList($streamblock1) "00:00:01:00:00:01"
    set m_EthTypeRangeModifierList($streamblock1) ""
    set m_VlanIdRangeModifierList($streamblock1) ""
    set m_VlanId2RangeModifierList($streamblock1) ""
    set m_VlanIdTableModifierList($streamblock1) ""
    set m_VlanIdTableModifierList2($streamblock1) ""
    set m_VlanIdTableModifierIdList($streamblock1) "1"
    set m_VlanIdTableModifierIdList2($streamblock1) "1"
    set m_Ipv4TypeRangeModifierList($streamblock1) ""
    set m_Ipv4SrcRangeModifierList($streamblock1) ""
    set m_Ipv4DstRangeModifierList($streamblock1) ""
    set m_Ipv4SrcTableModifierList($streamblock1) ""
    set m_Ipv4DstTableModifierList($streamblock1) ""
    set m_Ipv4SrcTableModifierAddrList($streamblock1) "192.85.1.2"
    set m_Ipv4DstTableModifierAddrList($streamblock1) "192.0.0.1"
    set m_Ipv6SrcRangeModifierList($streamblock1) ""
    set m_Ipv6DstRangeModifierList($streamblock1) ""
    set m_Ipv6SrcTableModifierList($streamblock1) ""
    set m_Ipv6DstTableModifierList($streamblock1) ""
    set m_Ipv6SrcTableModifierAddrList($streamblock1) "2000::2"
    set m_Ipv6DstTableModifierAddrList($streamblock1) "2000::1"
    set m_UdpSrcRangeModifierList($streamblock1) ""
    set m_UdpDstRangeModifierList($streamblock1) ""
    set m_TcpSrcRangeModifierList($streamblock1) ""
    set m_TcpDstRangeModifierList($streamblock1) ""
    set m_IcmpIdRangeModifierList($streamblock1) ""
    set m_IcmpSeqRangeModifierList($streamblock1) ""
    set m_ArpSrcHwRangeModifierList($streamblock1) ""
    set m_ArpDstHwRangeModifierList($streamblock1) ""
    set m_ArpSrcProtoRangeModifierList($streamblock1) ""
    set m_ArpDstProtoRangeModifierList($streamblock1) ""       
    set m_MplsLabelRangeModifierList1($streamblock1) ""
    set m_MplsLabelRangeModifierList2($streamblock1) ""
    set m_MplsLabelRangeModifierList3($streamblock1) ""
    set m_MplsLabelRangeModifierList4($streamblock1) ""            
    set m_IcmpCmdList($streamblock1) ""

    for {set i 1} {$i <= 4} {incr i} {
       set m_mplsLabelList($streamblock1,$i) 0
       set m_mplsLabelCountList($streamblock1,$i) 1
       set m_mplsLabelModeList($streamblock1,$i) "fixed"
       set m_mplsLabelStepList($streamblock1,$i) 1
       set m_mplsExpList($streamblock1,$i) 0
       set m_mplsTtlList($streamblock1,$i) 0
       set m_mplsBottomOfStackList($streamblock1,$i) "AUTO"
    }
    
    ConfigLayerStreamParameters $streamblock1 $args

    ConfigStreamParameters $streamblock1 $args
         
    stc::config $streamBlockHdl -active false
	#stc::config $streamBlockHdl -ShowAllHeaders "TRUE"
	#stc::perform Streamblockupdate -Streamblock $streamBlockHdl
	
    debugPut "exit the proc of TrafficEngine::CreateStream..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigStream
#Description: Config stream parameters
#Input: 1. args:argument list，including
#              (1) -StreamName StreamName:required,name of the stream,i.e -StreamName Stream1
#              (2) -FrameLen FrameLen optional,frame length,i.e -FrameLen 128
#              (3) -StreamLoad StreamLoad optional, Stream load，i.e -StreamLoad 1000
#              (4) -StreamLoadUnit StreamLoadUnit optional，Stream load unit，i.e -StreamLoadUnit fps
#              (5) For other parameters please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::ConfigStream {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TrafficEngine::ConfigStream..."
    
    #Parse StreamName parameter
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the StreamName of the port \nexit the proc of ConfigStream..."
    }
    if {[info exists m_streamBlockHandle($StreamName)]} {
        set streamblock1 $m_streamBlockHandle($StreamName)    
    } else {
        error "StreamName $StreamName does not exist,please create stream first."
    }
    
    #Parse dstPorts parameter
    set index [lsearch $args -dstports]
    if {$index != -1} {
        set DestinationPort [lindex $args [expr $index + 1]]
        set ::mainDefine::gBoundStreamDstPort($StreamName) $DestinationPort
    } 

    #Parse streamType parameter
    set index [lsearch $args -streamtype]
    if {$index != -1} {
        set StreamType [lindex $args [expr $index + 1]]
    } else {
        set StreamType $m_streamType($StreamName)
    }  

    #Parse DstPoolName parameter
    set index [lsearch $args -dstpoolname]
    if {$index != -1} {
        set DstPoolName [lindex $args [expr $index + 1]]
    } 
    #Parse SrcPoolName parameter
    set index [lsearch $args -srcpoolname]
    if {$index != -1} {
        set SrcPoolName [lindex $args [expr $index + 1]]
    }

    #Parse TrafficPattern parameter
    set index [lsearch $args -trafficpattern]
    if {$index != -1} {
        set TrafficPattern [lindex $args [expr $index + 1]]
    } else {
        set TrafficPattern $m_trafficPattern($StreamName)
    } 

    #Parse FillType parameter
    set index [lsearch $args -filltype]
    if {$index != -1} {
        set FillType [lindex $args [expr $index + 1]]
        stc::config $streamblock1 -FillType $FillType
    } 

    #Parse ConstantFillPattern parameter
    set index [lsearch $args -constantfillpattern]
    if {$index != -1} {
        set ConstantFillPattern [lindex $args [expr $index + 1]]
        stc::config $streamblock1 -ConstantFillPattern $ConstantFillPattern
    } 
    
    

    #Add the support of Poolname bounding
    if {[string tolower $StreamType] == "dhcp" || [string tolower $StreamType] == "pppox" || [string tolower $StreamType] == "bgp" || [string tolower $StreamType] == "ospfv2" || [string tolower $StreamType] == "isis" || [string tolower $StreamType] == "ldp" || [string tolower $StreamType] == "host"} {
        if {[info exists SrcPoolName]&&[info exists DstPoolName]} {
            set srcPoolBlockList ""
            set dstPoolBlockList ""

            foreach srcPoolItem $SrcPoolName {
                if {[info exists ::mainDefine::gPoolCfgBlock($srcPoolItem)]} {
                    lappend srcPoolBlockList $::mainDefine::gPoolCfgBlock($srcPoolItem) 
                } else {
                    error "Pool Name item $srcPoolItem does not exist, please check ..."
                }
            }

            foreach dstPoolItem $DstPoolName {
                if {[info exists ::mainDefine::gPoolCfgBlock($dstPoolItem)]} {
                    lappend dstPoolBlockList $::mainDefine::gPoolCfgBlock($dstPoolItem) 
                } else {
                    error "Pool Name item $dstPoolItem does not exist, please check ..."
                }
            }

            if {$srcPoolBlockList != "" && $dstPoolBlockList != "" } {
                catch {
                    stc::config $streamblock1 -SrcBinding-targets " $srcPoolBlockList "
                    stc::config $streamblock1 -DstBinding-targets " $dstPoolBlockList "
                    
                    set srcLength [llength $srcPoolBlockList]
                    set dstLength [llength $dstPoolBlockList]

                    if {$srcLength != $dstLength && [string tolower $TrafficPattern] == "pair"} {
                        stc::config $streamblock1 -TrafficPattern BACKBONE
                    } 
                    
                    
                    stc::config $streamblock1 -EnableTxPortSendingTrafficToSelf TRUE  
                    stc::config $streamblock1 -EnableStreamOnlyGeneration "FALSE"
                    stc::config $streamblock1 -ShowAllHeaders "TRUE"
                    stc::perform Streamblockupdate -Streamblock $streamblock1
					set m_boundStreamFlag 1
                    set ::mainDefine::gStreamBindingFlag "TRUE"
                    debugPut "Binding the stream block successful, source: $srcPoolBlockList, Destination: $dstPoolBlockList"
               }
            }        
        }
    }
    
    

    #################Fundamental parameter configuration#######################
    
    #Parse FrameLen parameter
    set index [lsearch $args -framelen] 
    if {$index != -1} {
        set FrameLen [lindex $args [expr $index + 1]]
        set m_frameLen($StreamName) $FrameLen
        stc::config $streamblock1 -FixedFrameLength $FrameLen
    } 

    #Parse FrameLenMode parameter
    set index [lsearch $args -framelenmode] 
    if {$index != -1} {
        set FrameLenMode [lindex $args [expr $index + 1]]
        if {[string tolower $FrameLenMode] == "increment"} {
            set FrameLenMode "INCR"
        } elseif {[string tolower $FrameLenMode] == "decrement"} {
            set FrameLenMode "DECR"
        }
        set m_frameLenMode($StreamName) $FrameLenMode
        stc::config $streamblock1 -FrameLengthMode $FrameLenMode
    } 

    #Parse FrameLenStep parameter
    set index [lsearch $args -framelenstep] 
    if {$index != -1} {
        set FrameStep [lindex $args [expr $index + 1]]
        set m_frameLenStep($StreamName) $FrameStep
        stc::config $streamblock1 -StepFrameLength $FrameStep
    } 

    #Parse FrameLenCount  parameter
    set index [lsearch $args -framelencount] 
    if {$index != -1} {
        set FrameLenCount [lindex $args [expr $index + 1]]
        set m_frameLenCount($StreamName) $FrameLenCount
 
        if {$m_frameLenMode($StreamName) == "DECR"} {
            set MinFrameLen [expr $m_frameLen($StreamName) - ($m_frameLenCount($StreamName) - 1) * $m_frameLenStep($StreamName)]
            set MaxFrameLen $m_frameLen($StreamName)
        } else {
            set MinFrameLen $m_frameLen($StreamName)
            set MaxFrameLen [expr $m_frameLen($StreamName) + ($m_frameLenCount($StreamName) - 1) * $m_frameLenStep($StreamName)]
        }

        stc::config $streamblock1 -MinFrameLength $MinFrameLen -MaxFrameLength $MaxFrameLen
    } 

    #Parse InsertSignature parameter
    set index [lsearch $args -insertsignature] 
    if {$index != -1} {
        set Signature [lindex $args [expr $index + 1]]
        stc::config $streamblock1 -InsertSig $Signature
    } 
    
    #Parse StreamLoad parameter
    set index [lsearch $args -streamload] 
    if {$index != -1} {
        set StreamLoad [lindex $args [expr $index + 1]]
        stc::config $streamblock1 -Load $StreamLoad
    } 
    
    #Parse StreamLoadUnit parameter
    set index [lsearch $args -streamloadunit] 
    if {$index != -1} {
        set StreamLoadUnit [lindex $args [expr $index + 1]]
        if {[string tolower $StreamLoadUnit] =="fps"} {
            stc::config $streamblock1 -LoadUnit FRAMES_PER_SECOND
        } elseif {[string tolower $StreamLoadUnit] =="bps"} {
            stc::config $streamblock1 -LoadUnit BITS_PER_SECOND
        } elseif {[string tolower $StreamLoadUnit] =="kbps"} {
            stc::config $streamblock1 -LoadUnit KILOBITS_PER_SECOND
        } elseif {[string tolower $StreamLoadUnit] =="mbps"} {
            stc::config $streamblock1 -LoadUnit MEGABITS_PER_SECOND
        } elseif {[string tolower $StreamLoadUnit] =="percent"} {
            stc::config $streamblock1 -LoadUnit PERCENT_LINE_RATE
        } else {
            error "Parameter StreamLoadUnit is invalid,please set fps/bps/kbps/mbps/percent. \nexit the proc of ConfigStream..."
        } 
    } 
    
    #Parse StreamLoadUnit parameter
    set index [lsearch $args -profilename] 
    if {$index != -1} {
        set ProfileName [lindex $args [expr $index + 1]]
        if {[info exists m_profileConfig($ProfileName)]} {           
            stc::config $streamblock1 -IsControlledByGenerator "TRUE"          
        }
    }

    #Parse EnableFcsErrorInsertion parameter
    set index [lsearch $args -enablefcserrorinsertion] 
    if {$index != -1} {
        set EnableCrcErrorInsertion [lindex $args [expr $index + 1]]
        stc::config $streamblock1 -EnableFcsErrorInsertion $EnableCrcErrorInsertion
    }

    #################Fundamental parameter configuration#######################
    
    #################Layer Configuration##########################
    set IcmpType "FALSE"
    #Check whether or not it is l4 ICMP
    set index [lsearch $args -l4] 
    if {$index != -1} {
        set L4 [lindex $args [expr $index + 1]]
        if {[string tolower $L4] =="icmp"} {
            set IcmpType "TRUE"
            stc::config $streamblock1 -FrameConfig ""
            if {[info exists m_CreateStreamArgsList($streamblock1)]} {
               if {$m_CreateStreamArgsList($streamblock1) != ""} {
                  set m_IcmpIdRangeModifierList($streamblock1) ""
                  set m_IcmpSeqRangeModifierList($streamblock1) ""
                  
                  ConfigLayerStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigEthStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigVlanStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigIPV4StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigIPV6StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
               }
           }
        }
    } else {
       set index [lsearch $args -icmptype] 
       if {$index != -1} {
            set IcmpType "TRUE"
            stc::config $streamblock1 -FrameConfig ""
            if {[info exists m_CreateStreamArgsList($streamblock1)]} {
               if {$m_CreateStreamArgsList($streamblock1) != ""} {
                  set m_IcmpIdRangeModifierList($streamblock1) ""
                  set m_IcmpSeqRangeModifierList($streamblock1) ""
                  
                  ConfigLayerStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigEthStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigVlanStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigIPV4StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                  ConfigIPV6StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
               }
           }
        }
    }
    
    #Parse L2 parameter
    set index [lsearch $args -l2]
    if {$index != -1} {
        set L2 [string tolower [lindex $args [expr $index + 1]]]
        switch $L2 {
           ethernet {
               set eth1 [GetEthHandle $streamblock1]
               set vlans1 [stc::get $eth1 -children-vlans]
               if {$vlans1 !=""} {
                   stc::delete $vlans1               
               }  

               # remove mpls tag if it exists
               set hChildrenList [stc::get $streamblock1 -children]               
               foreach sr $hChildrenList {
                   if {[string match "mpls*" $sr]} {
                       stc::delete $sr
                   }
               }
 
               for {set i 1} {$i <= 4} {incr i} {       
                   if {[subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] != ""} {
                       stc::delete [subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]]    
                       set [subst m_MplsLabelRangeModifierList$i\($streamblock1)] ""            
                   }
               }               
           }
           ethernet_vlan {
               set eth1 [GetEthHandle $streamblock1]
               if {$eth1 ==""} {
                   set eth1 [stc::create ethernet:EthernetII -under $streamblock1]
                   set vlans1 [stc::create vlans -under $eth1]
                   set vlan1 [stc::create vlan -under $vlans1]                
               } else {
                   set eth1 [lindex [stc::get $streamblock1 -children-ethernet:EthernetII] 0]
                   set vlans1 [stc::get $eth1 -children-vlans]
                   if {$vlans1 == ""} {
                       set vlans1 [stc::create vlans -under $eth1]
                       set vlan1 [stc::create vlan -under $vlans1]    
                   } elseif {[stc::get $vlans1 -children] == ""} {
                       set vlan1 [stc::create vlan -under $vlans1]                   
                   }          
               } 
               # remove mpls tag if it exists
               set hChildrenList [stc::get $streamblock1 -children]               
               foreach sr $hChildrenList {
                   if {[string match "mpls*" $sr]} {
                       stc::delete $sr
                   }
               }
 
               for {set i 1} {$i <= 4} {incr i} {       
                   if {[subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]] != ""} {
                       stc::delete [subst $[subst m_MplsLabelRangeModifierList$i\($streamblock1)]]    
                       set [subst m_MplsLabelRangeModifierList$i\($streamblock1)] ""            
                   }
               }          
           } 
           ethernet_mpls {
               set eth1 [GetEthHandle $streamblock1]
               set vlans1 [stc::get $eth1 -children-vlans]
               if {$vlans1 !=""} {
                   stc::delete $vlans1               
               }

               if {[info exists m_L2TypeList($streamblock1)] && $m_L2TypeList($streamblock1) != "ethernet_mpls" } {
                   if {[info exists m_CreateStreamArgsList($streamblock1)] && $m_CreateStreamArgsList($streamblock1) != ""} {
                       stc::config $streamblock1 -FrameConfig ""   
                       ConfigEthStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigMplsStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigMplsStreamParameters $streamblock1 $args           
                       ConfigIPV4StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigIPV6StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                   } 
               } else {
                   ConfigMplsStreamParameters $streamblock1 $args           
               } 
           }
           ethernet_vlan_mpls {
               set eth1 [GetEthHandle $streamblock1]
               if {$eth1 ==""} {
                   set eth1 [stc::create ethernet:EthernetII -under $streamblock1]
                   set vlans1 [stc::create vlans -under $eth1]
                   set vlan1 [stc::create vlan -under $vlans1]                
               } else {
                   set eth1 [lindex [stc::get $streamblock1 -children-ethernet:EthernetII] 0]
                   set vlans1 [stc::get $eth1 -children-vlans]
                 
                   if {$vlans1 == ""} {
                       set vlans1 [stc::create vlans -under $eth1]
                       set vlan1 [stc::create vlan -under $vlans1]    
                   } elseif {[stc::get $vlans1 -children] == ""} {
                       set vlan1 [stc::create vlan -under $vlans1]                   
                   }     
               }
 
               if {[info exists m_L2TypeList($streamblock1)] && $m_L2TypeList($streamblock1) != "ethernet_vlan_mpls" } {
                   if {[info exists m_CreateStreamArgsList($streamblock1)] && $m_CreateStreamArgsList($streamblock1) != ""} {
                       stc::config $streamblock1 -FrameConfig ""   
                       ConfigEthStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigVlanStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigMplsStreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigMplsStreamParameters $streamblock1 $args
                       ConfigIPV4StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                       ConfigIPV6StreamParameters $streamblock1 $m_CreateStreamArgsList($streamblock1)
                   }   
               } else {    
                   ConfigMplsStreamParameters $streamblock1 $args
               }            
           }
           default {
               error "L2 parameter should be one of  the list {Ethernet | Ethernet_Vlan | Ethernet_MPLS | Ethernet_Vlan_MPLS}" 
           }                     
        }
        set m_L2TypeList($streamblock1) $L2    
    }     
    
    #Parse L3 parameter
    set index [lsearch $args -l3] 
    if {$index != -1} {
        set eth1 [GetEthHandle $streamblock1]
        set L3 [lindex $args [expr $index + 1]]
        set m_L3TypeList($streamblock1) [string tolower $L3] 

        if {[string tolower $L3] =="ipv4"} {
            set hIPv4List [GetIPv4Handle $streamblock1]  
        } elseif {[string tolower $L3] =="ipv6"} {
            set hIPv6List [GetIPv6Handle $streamblock1]  
        } elseif {[string tolower $L3] =="arp"} {
            set hARPList [GetARPHandle $streamblock1]
        } 
    }
    
    #Parse L4 parameter
    set index [lsearch $args -l4] 
    if {$index != -1} {
        set eth1 [GetEthHandle $streamblock1]
        if {$m_L3TypeList($streamblock1) == "ipv4"} {
            set hIPv4List [GetIPv4Handle $streamblock1]  
        }
  
        set L4 [lindex $args [expr $index + 1]]
        if {[string tolower $L4] =="tcp"} {
            set hTCPList [GetTCPHandle $streamblock1]
        } elseif {[string tolower $L4] =="udp"} {
            set hUDPList [GetUDPHandle $streamblock1]
        } elseif {[string tolower $L4] =="none"} {
            set hTCPList [GetTCPHandle $streamblock1]
        } 
    }
    
    #################Layer configuration##########################

    ConfigStreamParameters $streamblock1 $args
	
    debugPut "exit the proc of TrafficEngine::ConfigStream..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DeleteProfileStream
#Description: Delete stream from the profile
#Input: 1. args:argument list，including
#              (1) StreamName:optional,name of the stream,i.e Stream1
#Output: 0/1
#Coded by: Tony
#############################################################################
::itcl::body TrafficEngine::DeleteProfileStream {streamName} {
      #Delete stream in Profile
      set profile_name [FindStreamProfileName $streamName]
      if {$profile_name != ""} {
           set streamNameList $m_trafficProfileContent($profile_name)
           set index [lsearch $streamNameList $streamName] 
           if {$index != -1} {
                set m_trafficProfileContent($profile_name) [lreplace $m_trafficProfileContent($profile_name) $index $index]
              
                debugPut "The trafficProfileContent($profile_name) is: $m_trafficProfileContent($profile_name)"
           }
      }
 }   

############################################################################
#APIName: DestroyStream
#Description: Destroy stream
#Input: 1. args:argument list, including
#              (1) -StreamName StreamName:optional,name of the stream,i.e -StreamName Stream1
#Output: 0/1
#Coded by: Jaimin
#############################################################################
::itcl::body TrafficEngine::DestroyStream {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of TrafficEngine::DestroyStream..."

    #Parse StreamName parameter
    set index [lsearch $args -streamname] 
    if {$index != -1} {
        set StreamName [lindex $args [expr $index + 1]]
        set m_streamCount [expr $m_streamCount-1]
    } else  {
        for {set i 0} {$i < [llength $m_streamNameList]} {incr i} {
            set StreamName [lindex $m_streamNameList $i]
            DeleteProfileStream $StreamName

            catch {stc::delete $m_streamBlockHandle($StreamName)}
            set ::mainDefine::gStreamName $StreamName
            uplevel 1 {
                catch {itcl::delete object $::mainDefine::gStreamName}
            }
            unset m_streamBlockHandle($StreamName)
        }
        set m_streamCount 0
        set m_streamNameList ""
        debugPut "exit the proc of TrafficEngine::DestroyStream..." 
        return $::mainDefine::gSuccess
    }
    
    #Destroy stream object
    set index [lsearch $m_streamNameList $StreamName] 
    if {$index == -1} {
        error "Can not find the StreamName you have set,please set another one.\nexit the proc of DestroyStream..."
    }
    DeleteProfileStream $StreamName

    catch {stc::delete $m_streamBlockHandle($StreamName)}
    set ::mainDefine::gStreamName $StreamName
    uplevel 1 {
        catch {itcl::delete object $::mainDefine::gStreamName}
    } 
    unset m_streamBlockHandle($StreamName)
    set m_streamNameList [lreplace $m_streamNameList $index $index]

    debugPut "exit the proc of TrafficEngine::DestroyStream..." 
    return $::mainDefine::gSuccess
}
