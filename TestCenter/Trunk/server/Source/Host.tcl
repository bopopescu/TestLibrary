###########################################################################
#                                                                        
#  File Name: Host.tcl                                                                                              
# 
#  Description£ºDefinition of Host class, and its methods                                             
# 
#  Author£º Tony
#
#  Create Time:  2009.01.22
#
#  Version£º1.0 
# 
#  History£º 
# 
##########################################################################
##########################################
#Definition of Host class
##########################################  
::itcl::class Host {

    #Variables
    public variable m_hostName 
    public variable m_hProject
    public variable m_portHandle 
    public variable m_hostHandle 
    public variable m_hostIpAddr
    public variable m_hostIpGw
    public variable m_IpVersion
    public variable m_aggregatePingResultStats ""
    public variable m_portType "ethernet"
    public variable m_hRouter

    #Constructor
    constructor {hostName hostHandle portHandle portName hProject hIpIf IpVersion portType} { 
        set m_hostName $hostName
        set m_hProject $hProject
        set m_portHandle $portHandle
        set m_hostHandle $hostHandle
        set m_hRouter $hostHandle
        set m_hostIpAddr [stc::get $hIpIf -Address]
        set m_hostIpGw [stc::get $hIpIf -Gateway]
        set m_IpVersion $IpVersion
        set m_portType $portType
        lappend ::mainDefine::gObjectNameList $this
    }
    
    public method Ping
    public method SendArpRequest
    
    #Methods for internal use only
    public method AggregatePingStats

    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
}  

############################################################################
#APIName: AggregatePingStats
#
#Description: Aggregate the statistics result of ping
#
#Input: attribute: the attribute, i.e -tx
#          value: the value, i.e 20
#            
#       
#Output: None
#
#Coded by: tony
#############################################################################
::itcl::body Host::AggregatePingStats {attribute value} {
  
   #Calculate packet loss automatically
   if {$attribute == "-pct_loss" } {
         set index_tx [lsearch $m_aggregatePingResultStats  "-tx"] 
         if {$index_tx != -1} {
               set tx_packets [lindex $m_aggregatePingResultStats  [expr $index_tx + 1]]
          }

         set index_rx [lsearch $m_aggregatePingResultStats  "-rx"] 
         if {$index_rx != -1} {
               set rx_packets [lindex $m_aggregatePingResultStats  [expr $index_rx + 1]]
         }
         
         if {$index_tx != -1 && $index_rx != -1} {
              if {$tx_packets  == 0} {
                    set value "0%"
              } else {
                    set value "[expr ($tx_packets - $rx_packets) * 1.0/$tx_packets * 100]%"
              }
         } else {
             set value "0%"
         }
    }

    #Deal with the minimum value
    if {$attribute == "-min" } {
         set index [lsearch $m_aggregatePingResultStats  "$attribute"] 
         if {$index != -1} {
               set read_value [lindex $m_aggregatePingResultStats  [expr $index + 1]]

               if {$read_value < $value} {
                      set value $read_value
               }
          }
    }

    #Deal with the maximum value
    if {$attribute == "-max" } {
         set index [lsearch $m_aggregatePingResultStats  "$attribute"] 
         if {$index != -1} {
               set read_value [lindex $m_aggregatePingResultStats  [expr $index + 1]]

               if {$read_value > $value} {
                      set value $read_value
               }
          }
    }

    #Deal with the average value
    if {$attribute == "-avg" } {
         set index [lsearch $m_aggregatePingResultStats  "$attribute"] 
         if {$index != -1} {
               set read_value [lindex $m_aggregatePingResultStats  [expr $index + 1]]

               set value [expr 1.0 * ($read_value + $value) / 2]
          }
    }

    #Deal with tx and rx
    if {$attribute == "-tx" || $attribute == "-rx" } {
         set index [lsearch $m_aggregatePingResultStats  "$attribute"] 
         if {$index != -1} {
               set read_value [lindex $m_aggregatePingResultStats  [expr $index + 1]]

               set value [expr $read_value + $value]
          }
    }

    #Find the item in the list, and replzce it
    set value_index [lsearch $m_aggregatePingResultStats  $attribute] 
    if {$value_index != -1} {
         set m_aggregatePingResultStats  [lreplace $m_aggregatePingResultStats  [expr $value_index + 1] [expr $value_index  + 1] $value]
    } else {
         lappend m_aggregatePingResultStats  "$attribute"
         lappend m_aggregatePingResultStats  "$value" 
    }  
}

############################################################################
#APIName: Ping
#
#Description: Send ping packet to the DUT
#
#Input: For the details please refer to the user manual
#            
#       
#Output: None
#
#Coded by: tony
#############################################################################
::itcl::body Host::Ping {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Host::Ping"

    #Parse Host parameter
    set index [lsearch $args -host] 
    if {$index != -1} {
        set HostAddr [lindex $args [expr $index + 1]]

         catch {
               set index [lsearch $::mainDefine::gObjectNameList "*$HostAddr"]
               if {$index != -1} {
                   set hostName [lindex $::mainDefine::gObjectNameList $index]
                   if {[$hostName isa Host]} {
                       set HostAddr [$hostName cget -m_hostIpAddr]     		            
                   } 
               }    
          }
    } else  {
         error " Please specify Host parameter \nexit the proc of Host::Ping ..."
    } 

    #Parse Count parameter
    set index [lsearch $args -count] 
    if {$index != -1} {
        set Count [lindex $args [expr $index + 1]]
    } else  {
        set Count 4
    } 

    #Parse Interval parameter
    set index [lsearch $args -interval] 
    if {$index != -1} {
        set Interval [lindex $args [expr $index + 1]]
        set Interval [expr $Interval/1000]
        if {$Interval == "0"} {
             set Interval 1
        }
    } else  {
        set Interval 1
    } 

    #Parse Size parameter
    set index [lsearch $args -size] 
    if {$index != -1} {
        set Size [lindex $args [expr $index + 1]]
    } else  {
        set Size 64
    } 

    #Parse Ttl parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set Ttl [lindex $args [expr $index + 1]]
    } else  {
        set Ttl 128
    } 

    #Parse the Timeout parameter
    set index [lsearch $args -timeout] 
    if {$index != -1} {
        set Timeout [lindex $args [expr $index + 1]]
    } else  {
        set Timeout 3
    } 

    #Parse Source parameter
    set index [lsearch $args -source] 
    if {$index != -1} {
        set Source [lindex $args [expr $index + 1]]
    } else  {
        set Source $m_hostIpAddr
    } 

    set error "null"
    if { [catch {
        stc::apply
      
        if {$m_IpVersion == "ipv4" } {
            array set pingStatus [stc::perform PingStart -FrameCount $Count -DeviceList $m_hostHandle -PingIpv4DstAddr $HostAddr \
                -PingIpv4SrcAddr $Source -TimeInterval $Interval -WaitForPingToFinish FALSE -ExecuteSynchronous TRUE]
        } else {
            array set pingStatus [stc::perform PingStart -FrameCount $Count -DeviceList $m_hostHandle -PingIpv6DstAddr $HostAddr \
                -PingIpv6SrcAddr $Source -TimeInterval $Interval -WaitForPingToFinish FALSE -ExecuteSynchronous TRUE] 
        }

        set processId $pingStatus(-ProcessId) 
        set PingResult [stc::get $m_portHandle -Children-PingReport]
       
        set waitCnt 0
        while {$waitCnt < 60} {
            after 1000

            set status [stc::get $PingResult -PingStatus]
            if {[string tolower $status] != "inprogress" } {
                debugPut "Ping finished, current PingStart status is $status"
                break
            }  
            set waitCnt [expr $waitCnt + 1]
        }

        if {$waitCnt == 60} {
            puts "Ping $HostAddr timeout, please check ..."
            stc::perform PingStop -DeviceList $m_hostHandle -ProcessId $processId -ExecuteSynchronous TRUE
        }  
      
    }  err ] } {
        set error $err
    }

    set PingResult [stc::get $m_portHandle -Children-PingReport]
    set AttemptedPingCnt [stc::get $PingResult -AttemptedPingCount]
    set SuccessfulPingCnt [stc::get $PingResult -SuccessfulPingCount]
    set FailedPingCnt [stc::get $PingResult -FailedPingCount]

    AggregatePingStats "-tx" "[stc::get $PingResult -AttemptedPingCount]" 
    AggregatePingStats "-rx" "[stc::get $PingResult -SuccessfulPingCount]" 

    #The folowing items will be calculated automatically
    AggregatePingStats "-max" "0" 
    AggregatePingStats "-min" "0" 
    AggregatePingStats "-avg" "0" 
    AggregatePingStats "-pct_loss" "0" 

    set pingResultStats $m_aggregatePingResultStats 
    lappend pingResultStats "-count"
    lappend pingResultStats "$SuccessfulPingCnt" 

    set totalCount [expr $SuccessfulPingCnt + 1]
    for {set i 1} {$i < $totalCount} {incr i} {
        lappend pingResultStats "\[$i-$SuccessfulPingCnt\].replyfrom"
        lappend pingResultStats "$HostAddr" 
        lappend pingResultStats "\[$i-$SuccessfulPingCnt\].bytes"
        lappend pingResultStats "64" 
        lappend pingResultStats "\[$i-$SuccessfulPingCnt\].ttl"
        lappend pingResultStats "254" 
        lappend pingResultStats "\[$i-$SuccessfulPingCnt\].time"
        lappend pingResultStats "0" 
    }

    #Deal with -log separately
    lappend pingResultStats "-log"
    lappend pingResultStats "$error" 

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

    debugPut "exit the proc of Host::Ping"
    
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: SendArpRequest
#
#Description: Send Arp Request to the DUT
#
#Input: For the details please refer to the user manual
#            
#       
#Output: None
#
#Coded by: tony
#############################################################################
::itcl::body Host::SendArpRequest {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of Host::SendArpRequest"

    #Parse Host parameter
    set index [lsearch $args -host] 
    if {$index != -1} {
        set HostAddr [lindex $args [expr $index + 1]]

        catch {
              set index [lsearch $::mainDefine::gObjectNameList "*$HostAddr"]
               if {$index != -1} {
                   set hostName [lindex $::mainDefine::gObjectNameList $index]
                   if {[$hostName isa Host]} {
                       set HostAddr [$hostName cget -m_hostIpAddr]     		            
                   } 
               }    
        }
    } else  {
         set HostAddr $m_hostIpGw 
    } 
    #puts "m_hostIpgw is $m_hostIpGw"   --lana added debug info 20130413
    #Parse Retries parameter
    set index [lsearch $args -retries] 
    if {$index != -1} {
        set Retries [lindex $args [expr $index + 1]]
    } else  {
        set Retries 3
    } 

    #Parse Timer parameter
    set index [lsearch $args -timer] 
    if {$index != -1} {
        set Timer [lindex $args [expr $index + 1]]
    } else  {
        set Timer 1
    } 

    set ArpNdConfigHandle [stc::get $m_hProject -children-ArpNdConfig]
    stc::config $ArpNdConfigHandle -RetryCount $Retries -TimeOut [expr $Timer * 1000] \
               -EnableUniqueMacAddrInReply FALSE
    
    stc::apply

    array set arpStatus [stc::perform ArpNdStart -HandleList $m_hostHandle -WaitForArpToFinish FALSE]

    set ArpResult [stc::get $m_portHandle -children-ArpNdReport]
       
    set waitCnt 0
    while {$waitCnt < 60} {
        after 1000

        set status [stc::get $ArpResult -ArpNdStatus]
        if {[string tolower $status] != "inprogress" } {
            debugPut "SendArpRequest finished, current status is $status"
            break
        }  
        set waitCnt [expr $waitCnt + 1]
    }

    if {$waitCnt == 60} {
        puts "SendArpRequest timeout, please check ..."
        stc::perform ArpNdStop -HandleList $m_hostHandle 
    }  
       
    debugPut "exit the proc of Host::SendArpRequest"
    
    return $::mainDefine::gSuccess
}
