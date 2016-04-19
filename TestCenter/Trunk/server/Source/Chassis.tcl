###########################################################################
#                                                                        
#  File Name：Chassis.tcl                                                                                              
# 
#  Description：Definition of TestDevice class and its methods                                             
# 
#  Creator： David.Wu
#
#  Time:  2007.3.2
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

##########################################
#Definition of TestDevice class
##########################################
::itcl::class TestDevice {

    #Variable definitions
    public variable m_hProject 0                        
    public variable m_chassisIp  0 
    public variable m_labServerIp 0
    public variable m_labServerConnect "FALSE"
    public variable m_schName 0
    public variable m_hScheduler 0
    public variable m_schNum 0    
    public variable m_portNameList ""
    public variable m_hPortLocationList ""
    public variable m_chassis -1
    public variable m_rxStreamResultHandle 0
    public variable m_txStreamResultHandle 0
    public variable m_txStreamSummaryResultHandle 0      
    public variable m_rxStreamSummaryResultHandle 0    
    public variable m_testStarted 0
    public variable m_hLacpGroupList ""   
    public variable m_lacpGroupNameList ""
    public variable m_hLacpGroupConfig
    public variable m_lacpGroupConfig
    public variable m_ResultDataSet ""
    public variable m_BgpImportRouteParams ""

    public variable m_analyzerPortResultHandle 0
    public variable m_rxCpuPortResultHandle 0
    public variable m_generatorPortResultHandle 0
    public variable m_mldHostResultHandle 0
    public variable m_igmpHostResultHandle 0
    public variable m_igmpRouterResultHandle 0
    public variable m_mldRouterResultHandle 0
    public variable m_ripRouterResultHandle 0
    public variable m_pimRouterResultHandle 0
    public variable m_isisRouterResultHandle 0
    public variable m_bgpRouterResultHandle 0
    public variable m_ospfv2RouterResultHandle 0
    public variable m_ospfv3RouterResultHandle 0
    public variable m_ldpRouterResultHandle 0
    public variable m_dhcpv4serverResultHandle 0
    public variable m_dhcpv4BlockResultHandle 0
    public variable m_dhcpv6BlockResultHandle 0
    public variable m_pppoeServerResultHandle 0
    public variable m_pppoeClientResultHandle 0    
    public variable m_lacL2tpv2BlockResultHandle 0
    public variable m_lnsL2tpv2BlockResultHandle 0
    public variable m_pppClientResultHandle 0
    public variable m_pppServerResultHandle 0 

    public variable m_chassisCleaned "FALSE"
    public variable  m_resultDataSet1 0
    public variable  m_resultDataSet2 0
    
    #constructor
    constructor { chassisIp {args ""} } {
       catch {

        set ::mainDefine::gSchedulerCreated 0

        set ::mainDefine::gEventCreatedAndConfiged 0

        set ::mainDefine::gPduNameList ""
        
        set ::mainDefine::PduConfigList ""
        
        set ::mainDefine::gVlanDestroyFlag 0

        set ::mainDefine::gObjectNameList ""
        set ::mainDefine::gHeaderCreatorList  ""

        #Connect the labServer
        if {$args!=""} {
            set args [string tolower $args]
            set index [lsearch $args -labserverip]
            if {$index!=-1} {
                set labServerIp [lindex $args [expr $index+1]]
                if {$labServerIp!=""} {
                    stc::perform CSTestSessionConnectCommand -Host $labServerIp -CreateNewTestSession TRUE

                    set m_labServerIp $labServerIp
                    set m_labServerConnect TRUE  
                }
            }
        }

        #Delete the variables in memory associated with automation
        stc::perform ResetConfig -Config system1 -ExecuteSynchronous TRUE  

        #Create project  object
        set m_hProject [stc::create project]
        
        #Connect the chassis
        set chassis [stc::connect $chassisIp]
        if { $chassis == -1 } {
            puts "Connection to chassis($chassisIp) failed"
            return
        } 
       
        set m_chassisIp $chassisIp
        set m_chassis  $chassis
        
        
        set option [stc::get system1 -children-automationoptions]
        stc::config $option -loglevel ERROR

        set errorCode 1      
    
        # Subscribe the AnalyzerPortResults 
        if {[catch {
            set m_analyzerPortResultHandle [stc::subscribe -parent $m_hProject \
                                                         -resultParent $m_hProject \
                                                         -configType analyzer \
                                                         -resultType AnalyzerPortResults -interval 1]
        } err]} {
            return $errorCode
        }
            
        # Subscribe the RxCpuPortResults 
        if {[catch {
            set m_rxCpuPortResultHandle [stc::subscribe -parent $m_hProject \
                                                          -resultParent $m_hProject \
                                                          -configType analyzer \
                                                          -resultType RxCpuPortResults -interval 1]
        } err]} {
            return $errorCode
        }  
          
        # Subscribe the GeneratorPortResults      
        if {[catch {
            set m_generatorPortResultHandle [stc::subscribe -parent $m_hProject \
                                                         -resultParent $m_hProject \
                                                         -configType generator \
                                                         -resultType GeneratorPortResults -interval 1 ]  
        } err]} {
            return $errorCode
        }              
        # Subscribe the RxStreamResults        
        if {[catch {
            set m_rxStreamResultHandle [stc::subscribe -parent $m_hProject \
                      -resultParent $m_hProject \
                      -configType streamblock \
                      -ViewAttributeList "FrameCount SigFrameCount OctetCount AvgLatency AvgJitter FcsErrorFrameCount Ipv4ChecksumErrorCount DuplicateFrameCount InSeqFrameCount OutSeqFrameCount PrbsFillOctetCount PrbsBitErrorCount TcpUdpChecksumErrorCount L1BitCount" \
                      -resultType RxStreamBlockResults]    
           stc::config $m_rxStreamResultHandle -RecordsPerPage 256
        } err]} {
            return $errorCode
        }             
        # Subscribe the TxStreamResults    
        if {[catch {
            set m_txStreamResultHandle [stc::subscribe -parent $m_hProject \
                    -resultParent $m_hProject \
                    -configType streamblock \
                    -ViewAttributeList "FrameCount OctetCount L1BitCount" \
                    -resultType TxStreamBlockResults]      
            stc::config $m_txStreamResultHandle -RecordsPerPage 256
        } err]} {
            return $errorCode
        }              

        # Subscribe the txStreamResults    
        if {[catch {
            set m_txStreamSummaryResultHandle [stc::subscribe -parent $m_hProject \
                                                              -resultParent $m_hProject \
                                                              -configType streamblock \
                                                              -ViewAttributeList "OctetRate FrameRate FrameCount OctetCount L1BitCount L1BitRate" \
                                                              -resultType txStreamResults]  
            stc::config $m_txStreamSummaryResultHandle -RecordsPerPage 256
        } err]} {
            return $errorCode
        }
                
        # Subscribe the RxStreamSummaryResults    
        if {[catch {
            set m_rxStreamSummaryResultHandle [stc::subscribe -parent $m_hProject \
                                                              -configType streamblock \
                                                              -ViewAttributeList "OctetRate FrameRate L1BitCount L1BitRate" \
                                                              -resultType rxStreamSummaryResults]  
            stc::config $m_rxStreamSummaryResultHandle -RecordsPerPage 256  
        } err]} {
            return $errorCode
        }
       
        # Subscribe the MLDHostResults    
        if {[catch {         
            set m_mldHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType mldhostconfig -resultType mldhostresults -interval 1]
        } err]} {
            return $errorCode
        }

        # Subscribe the IGMPHostResults    
        if {[catch {         
            set m_igmpHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType IgmpHostConfig -resultType IgmpHostResults -interval 1]
        } err]} {
            return $errorCode
        }
  
       lappend ::mainDefine::gObjectNameList $this
       set ::mainDefine::gChassisObjectHandle $this 
    }
    set m_ResultDataSet [stc::create ResultDataSet -under $m_hProject -PageNumber 300]
    set m_BgpImportRouteParams [stc::create BgpImportRouteTableParams -under $m_hProject]
    }
    
    #destructor
    destructor {        
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }

    #Methods definition
    public method Connect 
    public method Disconnect
    public method CreateTestPort 
    public method DestroyTestPort      
    public method StartTraffic
    public method StopTraffic     
    public method CreateScheduler
    public method DestroyScheduler
    public method CleanupTest
    public method StartTest
    public method StopTest
    public method GetTestState
    public method WaitUntilTestStops
    public method CreateLacpPortGroup
    public method ConfigLacpPortGroup
    public method GetLacpPortGroup
    public method DeleteLacpPortGroup   
    public method StartRouter
    public method StopRouter
    public method ResetSession
    public method ForceReleasePort
    public method BreakLinks
    public method RestoreLinks
    public method RebootTestPort
    public method PrintInfo 
	public method ClearTestResults
   
    #Methods internal use only
    public method SetProtocolResultHandle
    public method ConfigResultOptions
    public method DeleteObject
    public method ConfigStreamSchedulingMode
    public method SubscribeResults
}

############################################################################
#APIName: SetProtocolResultHandle
#
#Description: Create Result Handle of certain protocol
#
#Input: type, the type of protocol
#
#Output: return 0 if no error
#
#Coded by: Tony
#############################################################################
::itcl::body TestDevice::SetProtocolResultHandle {type} {
      catch { 
      if {[string tolower $type] == "mldhost" } {
               # Subscribe the MLDHostResults
              if {$m_mldHostResultHandle == "0" } {  
                   debugPut "Create MLDHostResult Handle successfully"      
                   set m_mldHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                       -configType mldhostconfig -resultType mldhostresults -interval 1]
              }
        } elseif {[string tolower $type] == "mldrouter" } {
              # Subscribe the MLDRouterResults 
              if {$m_mldRouterResultHandle == "0" } {  
                    debugPut "Create MLDRouterResult Handle successfully"       
                    set m_mldRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                         -configType MldRouterConfig -resultType MldRouterResults -interval 1]
              }
        } elseif {[string tolower $type] == "igmphost" } {
               # Subscribe the IGMPHostResults 
               if {$m_igmpHostResultHandle == "0" } {   
                      debugPut "Create IGMPHostResult Handle successfully"      
                      set m_igmpHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                          -configType IgmpHostConfig -resultType IgmpHostResults -interval 1]
               }
        } elseif {[string tolower $type] == "igmprouter" } {
              # Subscribe the IGMPRouterResults
              if {$m_igmpRouterResultHandle == "0" } {   
                   debugPut "Create IGMPRouterResult Handle successfully"       
                   set m_igmpRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                        -configType IgmpRouterConfig -resultType IgmpRouterResults -interval 1]
              }
        } elseif {[string tolower $type] == "igmpopppoe" } {
              # Subscribe the IGMPHostResults
              if {$m_igmpHostResultHandle == "0" } {   
                      debugPut "Create IGMPHostResult Handle successfully"      
                      set m_igmpHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                          -configType IgmpHostConfig -resultType IgmpHostResults -interval 1]
              }              
              # Subscribe the pppoeClientResults    
              if {$m_pppoeClientResultHandle == "0" } {
                  debugPut "Create pppoeClientResults Handle successfully"      
                  set m_pppoeClientResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                        -configType PppoeClientBlockConfig -resultType PppoeClientBlockResults -interval 1]
              }                         
        } elseif {[string tolower $type] == "igmpodhcp" } {
              # Subscribe the IGMPHostResults
              if {$m_igmpHostResultHandle == "0" } {   
                      debugPut "Create IGMPHostResult Handle successfully"      
                      set m_igmpHostResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                          -configType IgmpHostConfig -resultType IgmpHostResults -interval 1]
              }
              # Subscribe the dhcpBlockResults    
              if {$m_dhcpv4BlockResultHandle == "0" } {
                  debugPut "Create dhcpBlockResults Handle successfully"      
                  set m_dhcpv4BlockResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                        -configType Dhcpv4BlockConfig -resultType Dhcpv4BlockResults -interval 1]
              }
        } elseif {[string tolower $type] == "riprouter" || [string tolower $type] == "ripngrouter"} {
             # Subscribe the RipRouterResults    
             if {$m_ripRouterResultHandle == "0" } {
                   debugPut "Create RipRouterResult Handle successfully"      
                   set m_ripRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                        -configType RipRouterConfig -resultType RipRouterResults -interval 1]
             }
      } elseif {[string tolower $type] == "pimrouter" } {
             # Subscribe the PimRouterResults    
             if {$m_pimRouterResultHandle == "0" } {
                  debugPut "Create PimRouterResult Handle successfully"               
                  set m_pimRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                       -configType PimRouterConfig -resultType PimRouterResults -interval 1]
             } 
      } elseif {[string tolower $type] == "isisrouter" } {
            # Subscribe the IsisRouterResults    
            if {$m_isisRouterResultHandle == "0" } {
                debugPut "Create IsisRouterResult Handle successfully"      
                set m_isisRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType IsisRouterConfig -resultType IsisRouterResults -interval 1]
            }
     } elseif {[string tolower $type] == "bgpv4router"  || [string tolower $type] == "bgpv6router"} {
           # Subscribe the BgpRouterResults    
            if {$m_bgpRouterResultHandle == "0" } {
                debugPut "Create BgpRouterResult Handle successfully"      
                set m_bgpRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType BgpRouterConfig -resultType BgpRouterResults -interval 1]
            }  
     } elseif {[string tolower $type] == "ospfv2router" } {
           # Subscribe the ospfv2RouterResults    
           if {$m_ospfv2RouterResultHandle == "0" } {         
                debugPut "Create Ospfv2RouterResult Handle successfully"      
                set m_ospfv2RouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                       -configType Ospfv2RouterConfig -resultType Ospfv2RouterResults -interval 1]
                set ::mainDefine::m_ospfv2RouterResultHandle  $m_ospfv2RouterResultHandle       
            }
    } elseif {[string tolower $type] == "ospfv3router" } {
          # Subscribe the ospfv3RouterResults    
          if {$m_ospfv3RouterResultHandle == "0" } { 
              debugPut "Create Ospfv3RouterResult Handle successfully"      
              set m_ospfv3RouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType Ospfv3RouterConfig -resultType Ospfv3RouterResults -interval 1]
          }
    } elseif {[string tolower $type] == "ldprouter" } {
        # Subscribe the LdpRouterResults    
        if {$m_ldpRouterResultHandle == "0" } {
            debugPut "Create LdpRouterResult Handle successfully"      
            set m_ldpRouterResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType LdpRouterConfig -resultType LdpRouterResults -interval 1]
        }
   } elseif {[string tolower $type] == "dhcpserver" } {
            # Subscribe the dhcpServerResults    
            if {$m_dhcpv4serverResultHandle == "0" } {
                debugPut "Create dhcpServerResults Handle successfully"      
                set m_dhcpv4serverResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType Dhcpv4ServerConfig -resultType Dhcpv4ServerResults -interval 1]
            }
     } elseif {[string tolower $type] == "dhcpclient" || [string tolower $type] == "dhcprelay"} {
            # Subscribe the dhcpBlockResults    
            if {$m_dhcpv4BlockResultHandle == "0" } {
                debugPut "Create dhcpBlockResults Handle successfully"      
                set m_dhcpv4BlockResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType Dhcpv4BlockConfig -resultType Dhcpv4BlockResults -interval 1]
            }
     } elseif {[string tolower $type] == "dhcpv6client" || [string tolower $type] == "dhcpv6relay"} {
            # Subscribe the dhcpv6BlockResults    
            if {$m_dhcpv6BlockResultHandle == "0" } {
                debugPut "Create dhcpv6BlockResults Handle successfully"      
                set m_dhcpv6BlockResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType Dhcpv6BlockConfig -resultType Dhcpv6BlockResults -interval 1]
            }
     } elseif {[string tolower $type] == "pppoeserver" } {
            # Subscribe the pppoeServerResults    
            if {$m_pppoeServerResultHandle == "0" } {
                debugPut "Create pppoeServerResults Handle successfully"      
                set m_pppoeServerResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType PppoeServerBlockConfig -resultType PppoeServerBlockResults -interval 1]
            }
     } elseif {[string tolower $type] == "pppoeclient" } {
            # Subscribe the pppoeClientResults    
            if {$m_pppoeClientResultHandle == "0" } {
                debugPut "Create pppoeClientResults Handle successfully"      
                set m_pppoeClientResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType PppoeClientBlockConfig -resultType PppoeClientBlockResults -interval 1]
            }
     } elseif {[string tolower $type] == "pppol2tplac" } {            
            # Subscribe the L2tpv2SessionResults   
            if {$m_lnsL2tpv2BlockResultHandle != "0"} {
                set m_lacL2tpv2BlockResultHandle $m_lnsL2tpv2BlockResultHandle
            } elseif {$m_lacL2tpv2BlockResultHandle == "0" } {
                debugPut "Create LAC L2tpv2BlockResults ResultsHandle successfully"      
                set m_lacL2tpv2BlockResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType L2tpv2BlockConfig -resultType L2tpv2BlockResults -interval 1]
            }
            # Subscribe the pppclientResults  
            if {$m_pppClientResultHandle == "0" } {
                debugPut "Create pppClientResults Handle successfully"      
                set m_pppClientResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType PppoL2tpv2ClientBlockConfig -resultType PppClientBlockResults -interval 1]
            }            
     } elseif {[string tolower $type] == "pppol2tplns"} {
            # Subscribe the L2tpv2SessionResults
            if {$m_lacL2tpv2BlockResultHandle != "0"} {
                set m_lnsL2tpv2BlockResultHandle $m_lacL2tpv2BlockResultHandle
            } elseif {$m_lnsL2tpv2BlockResultHandle == "0" } {
                debugPut "Create LNS L2tpv2BlockResults ResultsHandle successfully"      
                set m_lnsL2tpv2BlockResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType L2tpv2BlockConfig -resultType L2tpv2BlockResults -interval 1]
            }
            # Subscribe the pppServerResults  
            if {$m_pppServerResultHandle == "0" } {
                debugPut "Create pppServerResults Handle successfully"      
                set m_pppServerResultHandle [stc::subscribe -parent $m_hProject -resultParent $m_hProject \
                      -configType PppoL2tpv2ServerBlockConfig -resultType PppServerBlockResults -interval 1]
            }
     }
   }
       
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ResetSession
#
#Description: Delete all the objects except TestDevice and TestPort
#
#Input: none
#
#Output: return 0 if no error
#
#Coded by: Jaimin
#############################################################################
::itcl::body TestDevice::ResetSession {args} {

    #Convert attribute of input parameters to lower case
    set index [lsearch $args -help]
    if {$index != -1} {
        puts "ResetSession:\n"
        puts "stcChassis ResetSession"       
        return $::mainDefine::gSuccess
    }
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of TestDevice::ResetSession"  
    puts "All objects will be delete except object TestDevice and TestPort..."
    
    #Delete all the pdu objects created previously
    foreach object $::mainDefine::gHeaderCreatorList {
          set ::mainDefine::objectName $object
          uplevel 1 {     
                 catch {$::mainDefine::objectName DestroyPdu}     
          }     
    }

    #Delete all the objects except TestDevice and TestPort
    foreach object $::mainDefine::gObjectNameList {
        catch {
            if {[$object isa TestDevice]} {

            } elseif {[$object isa VlanSubInt ]} {
                puts "Object $object will be destroyed."
                catch {itcl::delete object $object}
            } elseif {[$object isa TestPort]} {
          
            } else {
                puts "Object $object will be destroyed."
                catch {itcl::delete object $object}
            }        
        }
    }

     #Reset the configuration of TestPort object
     foreach object $::mainDefine::gObjectNameList {
        catch {
            if {[$object isa TestPort]} {
                set ::mainDefine::objectName $object
                uplevel 1 {
                     $::mainDefine::objectName ResetTestPort
                }
            } 
        }
    }
  
   catch {
       set hRouterList  ""
       catch {set hRouterList [stc::get $m_hProject -children-router]}
       foreach hRouter $hRouterList {
           catch {stc::delete $hRouter}      
       }
   }

  catch {
       set hHostList  ""
       catch {set hHostList [stc::get $m_hProject -children-host]}
       foreach hHost $hHostList {
           catch {stc::delete $hHost}      
       }
   }

   catch {
       set hIpv4GroupList  ""
       catch {set hIpv4GroupList [stc::get $m_hProject -children-Ipv4Group]}
       foreach hIpv4Group $hIpv4GroupList {
           catch {stc::delete $hIpv4Group}      
       }
   }
   
  catch {
       set hVpnList  ""
       catch {set hVpnList [stc::get $m_hProject -children-VpnIdGroup]}
       foreach hVpn $hVpnList {
           catch {stc::delete $hVpn}      
       }
   }
   
   catch {
       set hVpnSiteList  ""
       catch {set hVpnSiteList [stc::get $m_hProject -children-VpnSiteInfoRfc2547]}
       foreach hVpnSite $hVpnSiteList {
           catch {stc::delete $hVpnSite}      
       }
   }
   
   catch {
       set hVpnSiteList  ""
       catch {set hVpnSiteList [stc::get $m_hProject -children-VpnSiteInfoVplsLdp]}
       foreach hVpnSite $hVpnSiteList {
           catch {stc::delete $hVpnSite}      
       }
   }
   #Reset Sequencer object
   catch {
    set sequencer_list [stc::get system1 -Children-Sequencer]
    if {$sequencer_list != ""} {
         catch {
              set sequencerState [stc::get $sequencer_list -state]
              if {$sequencerState != "IDLE" && $sequencerState != "FANALIZE"} {
                   stc::perform SequencerStop -ExecuteSynchronous TRUE
                   after 1000
              }
              stc::perform SequencerClear -ExecuteSynchronous TRUE
         }
    }
    }

    set ::mainDefine::gResultCleared 0
    set ::mainDefine::gEnableStream "TRUE"
    set ::mainDefine::gApplyConfig 0
    set ::mainDefine::gHeaderCreatorList ""
    set ::mainDefine::gTrafficProfileList ""
    set ::mainDefine::gGeneratorStarted "TRUE"  
    set ::mainDefine::gPortLevelStream "TRUE"

    set ::mainDefine::gCurrentRxPageNumber "0"
    set ::mainDefine::gCurrentTxPageNumber "0"
    set ::mainDefine::gCachedRxStreamHandleList ""
    set ::mainDefine::gCachedTxStreamHandleList ""
    set ::mainDefine::gCurrentRxSummaryPageNumber "0"
    set ::mainDefine::gCurrentTxSummaryPageNumber "0"
    set ::mainDefine::gCachedRxSummaryStreamHandleList ""
    set ::mainDefine::gCachedTxSummaryStreamHandleList ""
    set ::mainDefine::gCurrentRxFilteredPageNumber "0"
    set ::mainDefine::gCachedRxFilteredStreamHandleList ""

    set ::mainDefine::gAutoDestroyPdu "TRUE"
    set ::mainDefine::gStreamBindingFlag "FALSE"
    set ::mainDefine::gStreamScheduleMode "RATE_BASED"

    catch {
         unset ::mainDefine::gIpv4NetworkBlock 
         set ::mainDefine::gIpv4NetworkBlock(vpnname0) ""

         unset ::mainDefine::gIpv6NetworkBlock 
         set ::mainDefine::gIpv6NetworkBlock(vpnname0) ""
         
         unset ::mainDefine::gPoolCfgBlock 
         set ::mainDefine::gPoolCfgBlock(poolname0) ""
         
         unset ::mainDefine::gVpnSiteList
         set ::mainDefine::gVpnSiteList(vpnname0) ""
    }

    debugPut "exit the proc of TestDevice::ResetSession"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StartTraffic
#
#Description: Start traffic transmission
#
#Input: 1. –PortList {port1 port2},optional,the port list to start traffic transmission;
#                   if no parameter, all the ports are covered
#
#Output: return 0 if no error
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::StartTraffic {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    #debugPut "enter the proc of TestDevice::StartTraffic"    
    
    #Parse the portlist parameter
    set sargs ""
    set index [lsearch $args -portlist]
    if { $index !=-1} {
        set sargs [lindex $args [expr $index+1]]

        set ports ""
        foreach port $sargs {    
            set index [lsearch $m_portNameList  $port]
            if { $index !=-1} {
                lappend ports $port
            } 
        }  
        set sargs $ports
    } else {
        set sargs ""
    }

    #If no ports specified, all the ports will be covered
    if { [string equal $sargs ""] == 1 } {
         foreach port $m_portNameList {
             append sargs "$port "
         }
    } 

    #Parse the parameter FlagArp
    set index [lsearch $args -flagarp]
    if { $index !=-1} {
        set FlagArp [lindex $args [expr $index+1]]  
    } else {
        set FlagArp "FALSE"
    } 
    set FlagArp [string tolower $FlagArp] 

    #Get the stream handles of defined ports, and set the status of stream block to Active
    #to be ready for traffic transmission
    foreach arg $sargs {
        set ::mainDefine::objectName $arg
        uplevel 1 {     
            $::mainDefine::objectName configure -m_streamStatisticRefershed "FALSE"
        }     

        set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set hPort $::mainDefine::result
        
        foreach streamBlockHandle "[stc::get $hPort -children-StreamBlock]" {
            stc::config $streamBlockHandle -Active "TRUE"
        }
       
        set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_trafficNameList]     
        }     
        set trafficNameList $::mainDefine::result

        foreach traffic $trafficNameList {
       
              set ::mainDefine::objectName $traffic 
              uplevel 1 {         
                  set ::mainDefine::result [$::mainDefine::objectName ApplyProfileToPort "all" "profile"]
              }   
              set frameNumOfBlocking  $::mainDefine::result    
        } 
    }

    set portHandleList ""
    #Get generator handle of port object
    set genList ""
    foreach arg $sargs {
         set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set hPort $::mainDefine::result
        append genList "[stc::get $hPort -children-Generator] "
        append portHandleList "$hPort "
    }
    
    #Apply all the configurations to the chassis
    stc::apply
    after 5000

    #Clean all the statistics result
    stc::perform ResultsClearAll

    #Start port statistics functionality and port cature functionality if needed
    set testPortObjectList $m_portNameList

    foreach testPortObject $testPortObjectList {
        set ::mainDefine::objectName $testPortObject 
        uplevel 1 {         
             $::mainDefine::objectName RealStartStaEngine  0       
         }
    }
   debugPut "Finish starting all the StaEngine objects ..."

   #Start all the capture objects
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

    if {$FlagArp == "true"} {
        #Start ARP learning...
        if {$portHandleList != ""} {
            debugPut "Try to do ARP request for the port:$portHandleList ..."
            catch {stc::perform ArpNdStart -HandleList "$portHandleList"}
            after 4000
        }
    } elseif {$::mainDefine::gStreamBindingFlag == "TRUE"} {
        #Start ARP learning
        if {$portHandleList != ""} {
            debugPut "Try to do ARP request for the port:$portHandleList ..."
            catch {stc::perform ArpNdStart -HandleList "$portHandleList"}
            after 4000
        }
    }

    #Start the generator for traffic transmission
    set errorCode 1
    if {[catch {
        set errorCode [stc::perform GeneratorStart -GeneratorList $genList]
    } err]} {
        return $errorCode
    }

     set ::mainDefine::gGeneratorStarted "TRUE"  

    debugPut "exit the proc of TestDevice::StartTraffic"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StopTraffic
#
#Description: Stop traffic tranmission 
#
#Input: 1. –PortList {port1 port2},optional,the port list to stop traffic transmission;
#                   if no parameter, all the ports are covered
#
#Output: return 0 if no error
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::StopTraffic {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::StopTraffic"    
    #Parse the portlist parameter
    set sargs ""
    set index [lsearch $args -portlist]
    if { $index !=-1} {
        set sargs [lindex $args [expr $index+1]]

        set ports ""
        foreach port $sargs {    
            set index [lsearch $m_portNameList  $port]
            if { $index !=-1} {
                lappend ports $port
            } 
        }  
        set sargs $ports
    } else {
        set sargs ""
    }

    #If no ports specified, all the ports will be covered 
    if { [string equal $sargs ""] == 1 } {
         foreach port $m_portNameList {
             append sargs "$port "
         }
    } 

    #Get generator handle of port object
    set genList ""
    foreach arg $sargs {
        set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set hPort $::mainDefine::result
        append genList "[stc::get $hPort -children-Generator] "

        set generator [stc::get $hPort -children-Generator]
        set state [stc::get $generator -state]
        set loop 0
        while {$state == "PENDING_START" } {
            if {$loop == "20"} {
                debugPut "Timeout to wait for the generator to be started in PENDING_START state"
                debugPut "exit the proc of TestDevice::StopTraffic"
                return $::mainDefine::gSuccess
            }

            set loop [expr $loop + 1]
            after 500
          
            debugPut "Waiting for the generator to be started when in PENDING_START state" 
            set state [stc::get $generator -state]
        }
    }

    #Stop generator, and stop traffic transmission
   set errorCode 1
    if {[catch {
        set errorCode [stc::perform GeneratorStop -GeneratorList $genList]
    } err]} {
        return $errorCode
    }

    #Wait 5 seconds
    after 5000    

    debugPut "exit the proc of TestDevice::StopTraffic"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateScheduler
#
#Description: Create scheduler object
#
#Input: 1. -SchName SchName, required, name of Scheduler
#   
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::CreateScheduler {args} {

    set SchName ""
  
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]      
    debugPut "enter the proc of TestDevice::CreateScheduler"

    #Parse SchName parameter   
    set index [lsearch $args -schname] 
   
    if {$index != -1} {
        set SchName [lindex $args [expr $index+1]]
    } else  {
        error "please specify the shcheduler name "
    }
    set m_schName $SchName

    #Only one scheduler exists; if try to create more than one shcduler, there will be errors
    if {$m_schNum != 0} {
        error "there is only one scheduler in test"
    } else {
        set m_schNum 1
    }

    #Create Scheduler handle
    #set m_hScheduler [stc::create Sequencer -under $m_hProject -Name $SchName]
    set m_hScheduler [stc::create Sequencer -under system1 -Name $SchName]

    set ::mainDefine::gSchName $SchName

    set ::mainDefine::gHScheduler $m_hScheduler

    #Create TestScheduler object
    uplevel 1 {
        TestScheduler $::mainDefine::gSchName $::mainDefine::gSchName $::mainDefine::gHScheduler
    }
    set ::mainDefine::gSchedulerCreated 1
    debugPut "exit the proc of TestDevice::CreateScheduler"
    return $::mainDefine::gSuccess
}



############################################################################
#APIName: ClearTestResults
#
#Description: Clear Curent test results
#
#Input: 1. -PortNameList PortNameList, Port object name list
#       2. -StreamNameList StreamNameList, Stream object name list
#   
#Output: None
#
#Coded by: Jaimin.Wan
#############################################################################
::itcl::body TestDevice::ClearTestResults {{args ""}} {
    
	#Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::ClearTestResults"
    
	if {$args ==""} {
        #Clear all the traffic statistics
        stc::perform ResultsClearAll -ExecuteSynchronous TRUE	
	} else {
	    #Parse PortNameList parameter
		set index [lsearch $args -portnamelist] 
		if {$index != -1} {
			set PortNameList [lindex $args [expr $index + 1]]			
		} 
		
		#Parse StreamNameList parameter
		set index [lsearch $args -streamnamelist] 
		if {$index != -1} {
			set StreamNameList [lindex $args [expr $index + 1]]			
		} 
		if {[info exists PortNameList]} {
		    if {[string tolower $PortNameList] == "all"} {
			    set hPortList [stc::get $m_hProject -Children-Port]
				stc::perform ResultsClearAll -PortList $hPortList -ExecuteSynchronous TRUE
			
			} else {
				set portHandleList ""
				foreach PortName $PortNameList {
					 set ::mainDefine::objectName $PortName
					 uplevel 1 {         
						  set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]         
					 }  
					 set portHandle $::mainDefine::result     
					 lappend portHandleList $portHandle
				 } 
				 stc::perform ResultsClearAll -PortList $portHandleList -ExecuteSynchronous TRUE
			 }
		}
		
		if {[info exists StreamNameList]} {
		     if {[string tolower $StreamNameList] == "all"} {
			    set hPortList [stc::get $m_hProject -Children-Port]
				set streamResultsHandleList ""
				foreach hPort $hPortList {
					set streamHandleList [stc::get $hPort -children-Streamblock]
		
					foreach streamHandle $streamHandleList {
						set txStreamBlockRst [stc::get $streamHandle -children-TxStreamBlockResults]
						set rxStreamBlockRst [stc::get $streamHandle -children-RxStreamBlockResults]
						set txStreamRst [stc::get $streamHandle -children-TxStreamResults]
						set rxStreamRst [stc::get $streamHandle -children-RxStreamSummaryResults]
						if {$txStreamBlockRst !=""} {
							lappend streamResultsHandleList $txStreamBlockRst
						}
						if {$rxStreamBlockRst !=""} {
							lappend streamResultsHandleList $rxStreamBlockRst
						}
						if {$txStreamRst !=""} {
							lappend streamResultsHandleList $txStreamRst
						}
						if {$rxStreamRst !=""} {
							lappend streamResultsHandleList $rxStreamRst
						}
					}
				} 
				stc::perform ResultsClearView -ResultList $streamResultsHandleList	-ExecuteSynchronous TRUE
			
			} else {
				set streamResultsHandleList ""
				foreach StreamName $StreamNameList {
					set ::mainDefine::objectName $StreamName
				 
							uplevel 1 {        
								set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]         
							}
		
					set streamHandle $::mainDefine::result
					set txStreamBlockRst [stc::get $streamHandle -children-TxStreamBlockResults]
					set rxStreamBlockRst [stc::get $streamHandle -children-RxStreamBlockResults]
					set txStreamRst [stc::get $streamHandle -children-TxStreamResults]
					set rxStreamRst [stc::get $streamHandle -children-RxStreamSummaryResults]
					if {$txStreamBlockRst !=""} {
						lappend streamResultsHandleList $txStreamBlockRst
					}
					if {$rxStreamBlockRst !=""} {
						lappend streamResultsHandleList $rxStreamBlockRst
					}
					if {$txStreamRst !=""} {
						lappend streamResultsHandleList $txStreamRst
					}
					if {$rxStreamRst !=""} {
						lappend streamResultsHandleList $rxStreamRst
					}
				} 
				stc::perform ResultsClearView -ResultList $streamResultsHandleList	-ExecuteSynchronous TRUE
             }			 
		}	
	
	}    
    
    debugPut "exit the proc of TestDevice::ClearTestResults"
    return $::mainDefine::gSuccess
}


############################################################################
#APIName: DestroyScheduler
#
#Description: Destroy scheduler object
#
#Input: 1. -SchName SchName, required,name of Scheduler object
#   
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::DestroyScheduler {{args ""}} {

    debugPut "enter the proc of TestDevice::DestroyScheduler"

    #Destroy TestScheduler object
    itcl::delete object $m_schName 
    set m_schNum 0
    
    debugPut "exit the proc of TestDevice::DestroyScheduler"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: Connect
#
#Description: Connect STC chassis
#
#Input: 1. -IpAddr IpAddr,required，STC chassis ip address
#          2. -Port Port,optional，STC chassis TCP port
#
#Output: None
#
#Coded by: rody.ou
#############################################################################

::itcl::body TestDevice::Connect {args} {

    debugPut "enter the proc of TestDevice::Connect"
    set hChassis -1
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]   
    set index [lsearch $args -ipaddr]
    if {$index != -1} {
        set IpAddr [lindex $args [expr $index + 1]]
        set m_chassisIp $IpAddr
    } else {
        set IpAddr $m_chassisIp
    }
     
    #Connect STC Chassis
    if {$m_chassis == -1} {
        if {[catch {
            set hChassis [stc::connect $IpAddr]
            set m_chassis $hChassis
        } err ]} {
            puts "connect to chasssis ($IpAddr) failed: $err"
        }
    } else {
        puts "chasssis ($IpAddr) already connected"
        set hChassis $m_chassis
    }

    debugPut "exit the proc of TestDevice::Connect"    
    return $hChassis        
}

############################################################################
#APIName: Disconnect
#
#Description: Disconnect STC chassis
#
#Input: 1. -IpAddr IpAddr,required，STC chassis ip address
#         
#Output: None
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::Disconnect {args} {

    set success 0
  
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]      

    debugPut "enter the proc of TestDevice::Disconnect"
    set index [lsearch $args -ipaddr]
    if {$index != -1} {
        set IpAddr [lindex $args [expr $index + 1]]
    } else {
        set IpAddr $m_chassisIp
    }
    #Disconnect STC Chassis
    if {[catch {
        stc::disconnect $IpAddr
        set m_chassis -1
        } err ]} {
        puts "disconnect from chasssis ($m_chassisIp) failed: $err"
    } 
    debugPut "exit the proc of TestDevice::Disconnect"        

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateTestPort 
#
#Description: Create TestPort object
#
#Input: 1.  -PortLocation PortLocation:Required,specify the slotId/portId of the port,i.e -PortLocation 3/2
#          2.  -PortName PortName:required,specify the name of the port object,i.e. -PortName port1
#          3.  -PortType PortType:required,specify port type
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::CreateTestPort  {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::CreateTestPort"

    #Parse PortLocation parameter
    set index [lsearch $args -portlocation] 
    if {$index != -1} {
        set PortLocation [lindex $args [expr $index + 1]]
    } else  {
        #If no portlocation specified, then raise error
        error "please specify the slotId/portId of the port"
    }

    #Parse PortName parameter
    set index [lsearch $args -portname] 
    if {$index != -1} {
        set PortName [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the PortName of the port"
    }

    #Check whether PortName is unique
    set index [lsearch $m_portNameList $PortName] 
    if {$index != -1} {
        error "the portName ($PortName) already existed, please specify another one, the existing portnames are:\n $m_portNameList"
    } 
    
    #Parse PortType parameter
    set index [lsearch $args -porttype] 
    if {$index != -1} {
        set PortType [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the PortType of the port"
    }
    
    set ::mainDefine::gPortName  $PortName

    set ::mainDefine::gPortLocation  $PortLocation

    set ::mainDefine::ghProject  $m_hProject

    set ::mainDefine::gChassisIp  $m_chassisIp

    set ::mainDefine::gChassisName  $this

    set ::mainDefine::gHport ""
    
    set ::mainDefine::gPortType [string tolower $PortType]

    #According to PortLocation/PortName,create a ETHPort object
    if {[string tolower $PortType] == "ethernet"} {
        uplevel 1 {
            ETHPort $::mainDefine::gPortName $::mainDefine::gPortName $::mainDefine::gHport  $::mainDefine::gPortType\
                        $::mainDefine::gChassisName $::mainDefine::gPortLocation $::mainDefine::ghProject \
                        $::mainDefine::gChassisIp create
        } 
       #According to PortLocation/PortName,create a WanPort object  
    } elseif {[string tolower $PortType] == "wan"} {
        uplevel 1 {
            WanPort $::mainDefine::gPortName $::mainDefine::gPortName $::mainDefine::gHport $::mainDefine::gPortType \
                        $::mainDefine::gChassisName $::mainDefine::gPortLocation $::mainDefine::ghProject \
                        $::mainDefine::gChassisIp create
        } 
      #According to PortLocation/PortName,create a ATMPort object       
    } elseif {[string tolower $PortType] == "atm"} {
        uplevel 1 {
            ETHPort $::mainDefine::gPortName $::mainDefine::gPortName $::mainDefine::gHport $::mainDefine::gPortType \
                        $::mainDefine::gChassisName $::mainDefine::gPortLocation $::mainDefine::ghProject \
                        $::mainDefine::gChassisIp create
        } 
      #According to PortLocation/PortName,create a LowRatePort object  
    } elseif {[string tolower $PortType] == "lowrate"} {
        uplevel 1 {
            ETHPort $::mainDefine::gPortName $::mainDefine::gPortName $::mainDefine::gHport $::mainDefine::gPortType \
                        $::mainDefine::gChassisName $::mainDefine::gPortLocation $::mainDefine::ghProject \
                        $::mainDefine::gChassisIp create
        } 
    } else {
        error "unsupported port type:$PortType" 
    }

    lappend m_portNameList $PortName

    debugPut "exit the proc of TestDevice::CreateTestPort"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyTestPort 
#
#Description: Destroy TestPort object
#
#Input: 1. args:parameter list, including the following:
#              (1) -PortName PortName:required,specify the name of port,i.e -PortName port1
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::DestroyTestPort  {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]      
    debugPut "enter the proc of TestDevice::DestroyTestPort"

    #Parse PortName parameter
    set index [lsearch $args -portname] 
    if {$index != -1} {
        set PortName [lindex $args [expr $index + 1]]
    } else  {
        #If no PortName specified，all the ports will be covered
        set PortName "all"
    }

    #Destroy specified port
    if {$PortName != "all"} {
        set index [lsearch $m_portNameList $PortName] 
        if {$index != -1} {
            set m_portNameList [lreplace $m_portNameList $index $index ]

            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]     
            }     
            set portLocation $::mainDefine::result

            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
            set portHandle $::mainDefine::result
                         
            set ::mainDefine::gPortname $PortName

            #Destroy port object
            uplevel 1 {
                itcl::delete object $::mainDefine::gPortname 
            }      
  
            stc::release $portLocation  
            stc::delete $portHandle
        } else  {
            error "the portName ($PortName) does not exist, the existed portnames are:\n $m_portNameList"
        } 
    } else {

     set m_hPortLocationList ""
     set  portHandleList ""
     foreach portName $m_portNameList {
         set ::mainDefine::objectName $portName
         uplevel 1 {     
             set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]     
         }     
         set portLocation $::mainDefine::result
         lappend m_hPortLocationList $portLocation

         set ::mainDefine::objectName $portName
         uplevel 1 {     
             set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort ]     
         }     
         set portHandle $::mainDefine::result
         lappend portHandleList $portHandle
     }

      #Destroy all the port objects
      foreach PortName $m_portNameList {
            set ::mainDefine::gPortname $PortName
            
            uplevel 1 {
                itcl::delete object $::mainDefine::gPortname 
            }                    
     }      

     foreach portLocation $m_hPortLocationList {
          stc::release $portLocation 
     }

     foreach portHandle $portHandleList {
          stc::delete $portHandle 
     }

     set m_portNameList ""
    }
    debugPut "exit the proc of TestDevice::DestroyTestPort"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CleanupTest  
#
#Description:Cleanup all the test configuration of STC
#
#Input: None
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::CleanupTest  {{args ""}} {
  
    debugPut "enter the proc of TestDevice::CleanupTest "

    if {$m_chassisCleaned == "TRUE"} {
        debugPut "The chassis has alreay been cleaned, skip it"
        return $::mainDefine::gSuccess
    }
    set m_chassisCleaned "FALSE"

    #Get the generator handle according to the port object name
    set m_hPortLocationList ""
    foreach portName $m_portNameList {
        set ::mainDefine::objectName $portName
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]     
        }     
        
        set portLocation $::mainDefine::result
        lappend m_hPortLocationList $portLocation
           
        if {[info exists ::mainDefine::gPortScheduleMode($portName)]} {
           unset ::mainDefine::gPortScheduleMode($portName)
        } 
    }
    
    set portHandleList [stc::get $m_hProject -Children-Port]
    foreach hPort $portHandleList {
        set generator [stc::get $hPort -children-Generator]
        set state [stc::get $generator -state]
        if {$state != "STOPPED" } {
            stc::perform GeneratorStop -GeneratorList $generator -ExecuteSynchronous TRUE
        }
    }  
      
    #Destroy all the PDU objects
    foreach object $::mainDefine::gHeaderCreatorList {
          set ::mainDefine::objectName $object
          uplevel 1 {     
                 catch {$::mainDefine::objectName DestroyPdu}     
          }     
    }
   
    catch {
    #Destroy all the objects
    foreach object $::mainDefine::gObjectNameList {
        catch {itcl::delete object $object}
    }

    #Reset Sequencer object
    set sequencer_list ""
    catch {set sequencer_list [stc::get system1 -Children-Sequencer] }
    if {$sequencer_list != ""} {
         catch {
              set sequencerState [stc::get $sequencer_list -state]
              if {$sequencerState != "IDLE" && $sequencerState != "FANALIZE"} {
                   stc::perform SequencerStop -ExecuteSynchronous TRUE
                   after 1000
              }
              stc::perform SequencerClear -ExecuteSynchronous TRUE
         }
    } 

    set ::mainDefine::gHeaderCreatorList ""
    set ::mainDefine::gObjectNameList "" 
    set ::mainDefine::gTrafficProfileList ""
    set ::mainDefine::gChassisObjectHandle ""
    set ::mainDefine::gResultCleared 0
    set ::mainDefine::gEnableStream "TRUE"
    set ::mainDefine::gApplyConfig 0
    set ::mainDefine::gGeneratorStarted "TRUE"  
    set ::mainDefine::gPortLevelStream "TRUE"

    set ::mainDefine::gCurrentRxPageNumber "0"
    set ::mainDefine::gCurrentTxPageNumber "0"
    set ::mainDefine::gCachedRxStreamHandleList ""
    set ::mainDefine::gCachedTxStreamHandleList ""
    set ::mainDefine::gAutoDestroyPdu "TRUE"
    set ::mainDefine::gStreamScheduleMode "RATE_BASED"
    set ::mainDefine::routerNum 0
    set  ::mainDefine::rsvpRouterCreated 0

    foreach portLocation $m_hPortLocationList {
         catch {stc::release $portLocation} 
    }

    #Disconnect the STC chassis
    stc::disconnect $m_chassisIp

    #Delete the project handle
    if {$m_hProject != "0"} {
        stc::delete $m_hProject
    }
    }

    #Delete all the variables associaed with automation in memory
    stc::perform ResetConfig -Config system1 -ExecuteSynchronous TRUE  

    catch {
        unset ::mainDefine::gIpv4NetworkBlock 
        set ::mainDefine::gIpv4NetworkBlock(vpnname0) ""

        unset ::mainDefine::gIpv6NetworkBlock 
        set ::mainDefine::gIpv6NetworkBlock(vpnname0) ""

        unset ::mainDefine::gPoolCfgBlock 
        set ::mainDefine::gPoolCfgBlock(poolname0) ""
        
        unset ::mainDefine::gVpnSiteList
        set ::mainDefine::gVpnSiteList(vpnname0) ""
    }
    
    #Disconnect labserver
    if {$m_labServerConnect=="TRUE"} {
        stc::perform CSTestSessionDisconnectCommand -Terminate TRUE
        set m_labServerConnect "FALSE"
    } 

    #Wait 5 seconds for port release
    after 5000

    debugPut "exit the proc of TestDevice::CleanupTest "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: StartTest
#
#Description: Start the test (Start Scheduler to execute pre-defined events)
#
#Input: None                
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::StartTest {{args ""}} {

    debugPut "enter the proc of TestDevice::StartTest"
    set sargs ""

    foreach port $m_portNameList {
        append sargs "$port "
    } 

    foreach arg $sargs {
        set ::mainDefine::objectName $arg
        uplevel 1 {     
            $::mainDefine::objectName configure -m_streamStatisticRefershed "FALSE"
        }     

        set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
        }     
        set hPort $::mainDefine::result
        
        foreach streamBlockHandle "[stc::get $hPort -children-StreamBlock]" {
              stc::config $streamBlockHandle -Active "TRUE"
        }
       
        set ::mainDefine::objectName $arg
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_trafficNameList]     
        }     
        set trafficNameList $::mainDefine::result

        foreach traffic $trafficNameList {
       
              set ::mainDefine::objectName $traffic 
              uplevel 1 {         
                  set ::mainDefine::result [$::mainDefine::objectName ApplyProfileToPort "all" "profile"]
              }   
              set frameNumOfBlocking  $::mainDefine::result    
        } 
    }
    
    #Send all the configuration to the chassis
    stc::apply
    after 5000

    #Clear all the traffic statistics
    stc::perform ResultsClearAll

    if {$::mainDefine::gSchedulerCreated == 0} {
        error "you must create Scheduler before StartTest"
    } elseif {($::mainDefine::gEventCreatedAndConfiged == 0)}  {
        error "you must create Scheduler & create_config at least 1 Event before StartTest"
    }
    #开启Scheduler
    set errorCode 1
    if { [catch {       
        set errorCode [stc::perform  SequencerStart]
    } err]} {
        puts "error: $err"
        return $errorCode
    }
    set m_testStarted 1
    debugPut "exit the proc of TestDevice::StartTest"
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: StopTest
#
#Description: Stop the test (Stop Scheduler)
#
#Input: None              
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::StopTest {{args ""}} {

    debugPut "enter the proc of TestDevice::StopTest"

    if {$m_testStarted == 0} {
        error "you must StartTest before StopTest" 
    }

    #Stop Scheduler
    set errorCode 1
    if { [catch {
        set errorCode [stc::perform  SequencerStop -ExecuteSynchronous TRUE]
        after 5000
        
        # Wait for sequencer to finish
        stc::waituntilcomplete
        set portHandleList [stc::get $m_hProject -Children-Port]
        foreach hPort $portHandleList {
            set generator [stc::get $hPort -children-Generator]
            set state [stc::get $generator -state]
            if {$state != "STOPPED" } {
                stc::perform GeneratorStop -GeneratorList $generator -ExecuteSynchronous TRUE
            }
        }  
    } err]} {
        return $errorCode
    }

    debugPut "exit the proc of TestDevice::StopTest"
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: GetTestState
#
#Description: Get current test state
#
#Input: None                  
#
#Output: Current test state
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::GetTestState {{args ""}} {

    debugPut "enter the proc of TestDevice::GetTestState"

    if {$m_testStarted == 0} {
        error "you must StartTest before GetTestState" 
    }
    
    #Get current state of the Schedule
    set CurrentCommand [stc::get $m_hScheduler -CurrentCommand]
    #puts "CurrentCommand=$CurrentCommand"
    set ElapsedTime [stc::get $m_hScheduler -ElapsedTime]
    #puts "ElapsedTime=$ElapsedTime"
    set PausedCommand [stc::get $m_hScheduler -PausedCommand]
    set StoppedCommand [stc::get $m_hScheduler -StoppedCommand]
    set State [stc::get $m_hScheduler -State]
    set IsStepping [stc::get $m_hScheduler -IsStepping]

    set CurrentCommand1 ""
    set PausedCommand1 ""
    set StoppedCommand1 ""    

    set ::mainDefine::objectName $m_schName
    uplevel 1 {     
        set ::mainDefine::result [$::mainDefine::objectName cget -m_eventNameList]     
    }     
    set eventNameList $::mainDefine::result

    foreach eventName $eventNameList {

        set index [lsearch $::mainDefine::gEventNameHandleList $eventName]
        set hEvent [lindex $::mainDefine::gEventNameHandleList [expr $index + 1]]
        puts "eventName=$eventName"
        puts "hEvent=$hEvent"
        if {$hEvent == $CurrentCommand} {
            set CurrentCommand1 $eventName
        } elseif {$hEvent  == $StoppedCommand} {
            set StoppedCommand1 $eventName
        } elseif {$hEvent  == $PausedCommand} {
            set PausedCommand1 $eventName
        }        
  }

  set state ""
  
  lappend state  $CurrentCommand1

  debugPut "exit the proc of TestDevice::GetTestState"   
 
  #Return Scheduler state
  return $state
}

###########################################################################
#APIName: WaitUntilTestStops
#
#Description: Wait until test completed (Scheduler finished executing the commands)
#
#Input: None                  
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body TestDevice::WaitUntilTestStops  {{args ""}} {

    debugPut "enter the proc of TestDevice::WaitUntilTestStops "

    if {$m_testStarted == 0} { 
        error "you must StartTest before WaitUntilTestStops" 
    }
    
    set State [stc::get $m_hScheduler -State]
    #Get the status of Scheduler, if FINISHED, exit the loop, otherwise will wait until finished
    while {$State != "IDLE"} {
        puts "current state of scheduler is :$State"
        set waitTime 2
        stc::sleep $waitTime
        set State [stc::get $m_hScheduler -State]
      
    }
    puts "scheduler is already run to end"

    debugPut "exit the proc of TestDevice::WaitUntilTestStops "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: CreateLacpPortGroup
#
#Description: Create Lacp port group
#
#Input:  (1) -GroupName required Specify the Lacp port group name                
#          (2) -PortNameList required port list that Lacp port group belong to
#          (3) -ActorSystemId optional Lacp port group Mac address  
#          (4) -actorsystempriority optional Lacp port group priority 
# 
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body TestDevice::CreateLacpPortGroup  {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of TestDevice::CreateLacpPortGroup "

    set index [lsearch $args -groupname]
    if {$index != -1} {
       set groupname [lindex $args [expr $index + 1]]
    } else {
        error " Please specify the GroupName of TestDevice::CreateLacpPortGroup"
    }
    
    set index [lsearch $m_lacpGroupNameList $groupname]
    if {$index != -1} {
        error "The GroupName($groupname) already existed,please specify another one, the existed GroupName(s) is(are) as following:\n$m_lacpGroupNameList"
    } else {
        lappend m_lacpGroupNameList $groupname
    } 

    set index [lsearch $args -actorsystemid]
    if {$index != -1} {
       set actorsystemid [lindex $args [expr $index + 1]]
    } else {
        set actorsystemid "00:00:00:00:00:01"
    }
    lappend m_lacpGroupConfig($groupname) -actorsystemid
    lappend m_lacpGroupConfig($groupname) $actorsystemid

    set index [lsearch $args -actorsystempriority]
    if {$index != -1} {
       set actorsystempriority [lindex $args [expr $index + 1]]
    } else {
        set actorsystempriority 1
    }
    lappend m_lacpGroupConfig($groupname) -actorsystempriority
    lappend m_lacpGroupConfig($groupname) $actorsystempriority    
 
    #Configure LAG
    set m_hLacpGroupConfig [stc::create "LacpGroupConfig" \
        -under $m_hProject \
        -ActorSystemPriority $actorsystempriority \
        -ActorSystemId $actorsystemid \
        -Name $groupname ]
    lappend m_hLacpGroupList $m_hLacpGroupConfig             

    debugPut "exit the proc of TestDevice::CreateLacpPortGroup "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: ConfigLacpPortGroup
#
#Description: Configure Lacp port group
#
#Input:  (1) -GroupName required Specify the Lacp port group name                
#          (2) -PortNameList required port list that Lacp port group belong to
#          (3) -ActorSystemId optional Lacp port group Mac address  
#          (4) -actorsystempriority optional Lacp port group priority 
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body TestDevice::ConfigLacpPortGroup  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of TestDevice::ConfigLacpPortGroup "

    set index [lsearch $args -groupname]
    if {$index != -1} {
       set groupname [lindex $args [expr $index + 1]]
    } else {
        error " Please specify the GroupName of TestDevice::ConfigLacpPortGroup"
    }
    
    set index [lsearch $m_lacpGroupNameList $groupname]
    if {$index == -1} {
        error "The GroupName($groupname) is not existed,please specify another one, the existed GroupName(s) is(are) as following:\n$m_lacpGroupNameList"
    } 

    set index [lsearch $args -actorsystemid]
    if {$index != -1} {
       set actorsystemid [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_lacpGroupConfig($groupname) -actorsystemid]
        set actorsystemid [lindex $m_lacpGroupConfig($groupname) [expr $index + 1] ]
    }

    set index [lsearch $args -actorsystempriority]
    if {$index != -1} {
       set actorsystempriority [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $m_lacpGroupConfig($groupname) -actorsystempriority]
        set actorsystempriority [lindex $m_lacpGroupConfig($groupname) [expr $index + 1] ]
    }
 
    #Configure LAG   
    stc::config $m_hLacpGroupConfig \
        -ActorSystemPriority $actorsystempriority \
        -ActorSystemId $actorsystemid
        
    debugPut "exit the proc of TestDevice::ConfigLacpPortGroup "
    return $::mainDefine::gSuccess
}

###########################################################################
#APIName: GetLacpPortGroup
#
#Description: 
#
#Input:                 
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body TestDevice::GetLacpPortGroup  {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]           
    debugPut "enter the proc of ETHPort::GetLacpPortGroup " 
    
    set index [lsearch $args -groupname]
    if {$index != -1} {
       set groupname [lindex $args [expr $index + 1]]
    } else {
        error " Please specify the GroupName of TestDevice::ConfigLacpPortGroup"
    }
    
    set index [lsearch $m_lacpGroupNameList $groupname]
    if {$index == -1} {
        error "The GroupName($groupname) is not existed,please specify another one, the existed GroupName(s) is(are) as following:\n$m_lacpGroupNameList"
    } 

    set index [lsearch $args -actorsystemid]
    if {$index != -1} {
       set actorsystemid [lindex $args [expr $index + 1]]
    } 

    set index [lsearch $args -actorsystempriority]
    if {$index != -1} {
       set actorsystempriority [lindex $args [expr $index + 1]]
    } 

    set LacpPortGroupConfig ""
    lappend LacpPortGroupConfig -actorsystemid
    lappend LacpPortGroupConfig [stc::get $m_hLacpGroupConfig -ActorSystemId]
    lappend LacpPortGroupConfig -actorsystempriority
    lappend LacpPortGroupConfig [stc::get $m_hLacpGroupConfig -ActorSystemPriority]        
    
    set args [lrange $args 2 end] 
    if { $args == "" } {
        debugPut "exit the proc of TestDevice::ConfigLacpPortGroup" 
        return $LacpPortGroupConfig
    } else {
        array set arr $LacpPortGroupConfig
        foreach {name valueVar}  $args {      
            set ::mainDefine::gAttrValue $arr($name)

            set ::mainDefine::gVar $valueVar
            uplevel 1 {
                set $::mainDefine::gVar $::mainDefine::gAttrValue
            }            
        }        
    debugPut "exit the proc of TestDevice::ConfigLacpPortGroup"   
    return $::mainDefine::gSuccess     
    }  
}

###########################################################################
#APIName: DeleteLacpPortGroup
#
#Description: Delete Lacp port group
#
#Input:  (1) -GroupName required Specify Lacp port group
#
#Output: None
#
#Coded by: Penn.Chen
#############################################################################
::itcl::body TestDevice::DeleteLacpPortGroup  {args} {
  
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]        
    debugPut "enter the proc of TestDevice::DeleteLacpPortGroup "

    set index [lsearch $args -groupname]
    if {$index != -1} {
       set groupname [lindex $args [expr $index + 1]]
    } else {
        error " Please specify the GroupName of TestDevice::DeleteLacpPortGroup"
    }
    
    set index [lsearch $m_lacpGroupNameList $groupname]
    if {$index == -1} {
        error "The GroupName($groupname) is not exist,please specify another one, the existed GroupName(s) is(are) as following:\n$m_lacpGroupNameList"
    } else {
        set m_lacpGroupNameList [lreplace $m_lacpGroupNameList $index $index]
        set m_hLacpGroupList [lreplace $m_hLacpGroupList $index $index]            
    }
    
    #Check whether or not LacpGroup中 contains port object
    set LacpGroupPortList [stc::get m_hLacpGroupConfig -memberoflag-Sources]
    if {$LacpGroupPortList != "" } {
        error "There is(are) lacp port object $LacpGroupPortList in $groupname, can not delete Lacp Group"
    }
    
    #Delete associaed handle      
    stc::delete $m_hLacpGroupConfig
    catch {unset m_lacpGroupConfig($groupname)}
    
    debugPut "exit the proc of TestDevice::DeleteLacpPortGroup "
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: StartRouter
#
#Description: Start router object
#
#Input: 1. –PortList {port1 port2},optional,the port list to be started
#                   if no parameter, then all the ports are covered
#
#Output: return 0 for success
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::StartRouter {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::StartRouter"    
    
    set sargs ""
    set index [lsearch $args -portlist]
    if { $index !=-1} {
        set sargs [lindex $args [expr $index+1]]

        set ports ""
        #Ignore the port not in the port list
        foreach port $sargs {    
            set index [lsearch $m_portNameList  $port]
            if { $index !=-1} {
                lappend ports $port
            } 
        }  
        set sargs $ports
    } else {
        set sargs ""
    }
    
    if { [catch {
        stc::apply 
    } err]} {
         set ::mainDefine::gChassisObjectHandle $this 
         garbageCollect
         error "Apply config failed when start router, the error message is:$err" 
    }
    
    #If not specified certain port, then all the ports covered
    if { [string equal $sargs ""] == 1 } {
         foreach port $m_portNameList {
             append sargs "$port "
         }
    } 
    
    set hRouterList ""
    foreach port $sargs {
        set ::mainDefine::objectName $port
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]     
        }     
        set routerNameList $::mainDefine::result
        foreach routername  $routerNameList {
             
              set ::mainDefine::objectName $routername
             uplevel 1 {     
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]     
             }     
             set hRouter $::mainDefine::result
             lappend hRouterList  $hRouter
        }
       
    }
     
   #vlan子接口上router
   catch {
      foreach port $sargs {
          set ::mainDefine::objectName $port
          uplevel 1 {
              set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanIfNameList]
          }
          set subintList $::mainDefine::result
          foreach subint $subintList {
              set ::mainDefine::objectName $subint
              uplevel 1 {
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]
              }
              set routerlist $::mainDefine::result
              foreach router $routerlist {
                  set ::mainDefine::objectName $router
                  uplevel 1 {     
                      set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]     
                  }   
                  lappend hRouterList $::mainDefine::result
              }
          }
      }
    }
    #Start the router
    stc::perform DeviceStart -DeviceList $hRouterList

    debugPut "exit the proc of TestDevice::StartRouter"
    return $::mainDefine::gSuccess
}
############################################################################
#APIName: StopRouter
#
#Description: Stop router on the TestDevice
#
#Input: 1. –PortList {port1 port2},optional,the port list to be stopped
#                   if no parameter, then all the ports are covered
#
#Output: return 0 for success
#
#Coded by: rody.ou
#############################################################################
::itcl::body TestDevice::StopRouter {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::StopRouter"    
  
    set sargs ""
    set index [lsearch $args -portlist]
    if { $index !=-1} {
        set sargs [lindex $args [expr $index+1]]

        set ports ""
        #Ignore the port not in the port list
        foreach port $sargs {    
            set index [lsearch $m_portNameList $port]
            if { $index !=-1} {
                lappend ports $port
            } 
        }  
        set sargs $ports
    } else {
        set sargs ""
    }

    #If not specified certain port, then all the ports covered
    if { [string equal $sargs ""] == 1 } {
         foreach port $m_portNameList {
             append sargs "$port "
         }
    } 
    
    set hRouterList ""
    foreach port $sargs {
        set ::mainDefine::objectName $port
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]     
        }     
        set routerNameList $::mainDefine::result
        foreach routername  $routerNameList {
             set ::mainDefine::objectName $routername
             uplevel 1 {     
                 set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]     
             }     
             set hRouter $::mainDefine::result
             lappend hRouterList  $hRouter
        }
       
    }
    #vlan子接口上router
   catch {
      foreach port $sargs {
          set ::mainDefine::objectName $port
          uplevel 1 {
              set ::mainDefine::result [$::mainDefine::objectName cget -m_vlanIfNameList]
          }
          set subintList $::mainDefine::result
          foreach subint $subintList {
              set ::mainDefine::objectName $subint
              uplevel 1 {
                  set ::mainDefine::result [$::mainDefine::objectName cget -m_routerNameList]
              }
              set routerlist $::mainDefine::result
              foreach router $routerlist {
                  set ::mainDefine::objectName $router
                  uplevel 1 {     
                      set ::mainDefine::result [$::mainDefine::objectName cget -m_hRouter]     
                  }   
                  lappend hRouterList $::mainDefine::result
              }
          }
      }
    }
 
    #Stop the router
    stc::perform DeviceStop -DeviceList $hRouterList

    debugPut "exit the proc of TestDevice::StopRouter"
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ForceReleasePort
#
#Description: Force release a port of the STC chassis
#
#Input:    1. -PortLocation PortLocation,required，port location， slot/port specify the port on teh chassis, starting from 1
#Output: None
#
#Coded by: Shi Yunzhi
#############################################################################

::itcl::body TestDevice::ForceReleasePort {args} {

    debugPut "enter the proc of TestDevice::ForceReleasePort"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse PortLocation parameter
    set index [lsearch $args -portlocation] 
    if {$index != -1} {
        set portLocation [lindex $args [expr $index + 1]]
    } else {
        error "Please specify the port location"
    }

    set list [split $portLocation /]   

    #Only port/slot necessary
    set slotNumber [lindex $list 0]
    set portNumber [lindex $list 1]
    set pcm [stc::get system1 -children-physicalchassismanager]
    set chassislist [stc::get $pcm -children-physicalchassis] 
    set chassis [lindex $chassislist [expr [llength $chassislist] - 1]]
    set SlotSize [stc::get $chassis -SlotCount]
    if {$slotNumber > $SlotSize} {
        error "The port: $portLocation does not support on chassis, please check your parameter"  
    }
    set portCount [stc::get $chassis.physicaltestmodule.$slotNumber -PortCount]
    if {$portNumber > $portCount} {
        error "The port: $portLocation does not support on chassis, please check your parameter"  
    } 

    set portGroupSize [stc::get $chassis.physicaltestmodule.$slotNumber -PortGroupSize]
    set portGroupIndex [expr ( $portNumber / $portGroupSize ) + ( $portNumber % $portGroupSize )]
    set ownershipState [stc::get $chassis.physicaltestmodule.$slotNumber.physicalportgroup.$portGroupIndex -OwnershipState]
   
    if {$ownershipState != "OWNERSHIP_STATE_AVAILABLE"} {
        catch {
            set OwnerHostname [stc::get $chassis.physicaltestmodule.$slotNumber.physicalportgroup.$portGroupIndex -OwnerHostName]
            set loginHostName [info hostname]
            debugPut "Current port $portLocation owned by $OwnerHostname, and will be released by $loginHostName"
        }

        stc::perform ReservePort -Location $m_chassisIp/$portLocation -RevokeOwner TRUE
        # Setup logical <-> physical port mappings
        stc::perform setupPortMappings

        set isPortDestroyed "FALSE"
        foreach object $::mainDefine::gObjectNameList {
            catch {
                if {[$object isa TestPort]} {
                    set ::mainDefine::objectName $object
                    set ::mainDefine::parameter "$m_chassisIp/$portLocation" 
                    uplevel 1 {
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]
                   
                        if {$::mainDefine::result == $::mainDefine::parameter} {
                            $::mainDefine::objectName ResetTestPort
                        }
                    }

                    if {$::mainDefine::result == $::mainDefine::parameter} { 
                        set ::mainDefine::objectName $object
                        uplevel 1 {
                            set ::mainDefine::result [$::mainDefine::objectName cget -m_portName]
                        }

                        puts "Object $object will be destroyed."
                        set portName $::mainDefine::result
                        DestroyTestPort -PortName $portName 

                        set isPortDestroyed "TRUE"
                    }
                } 
            }
        }

        after 5000
    
        if {$isPortDestroyed == "FALSE"} {
            stc::perform ReleasePort -Location $m_chassisIp/$portLocation
        }
    } else {
         foreach object $::mainDefine::gObjectNameList {
            catch {
                if {[$object isa TestPort]} {
                    set ::mainDefine::objectName $object
                    set ::mainDefine::parameter "$m_chassisIp/$portLocation" 
                    uplevel 1 {
                        set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]
                   
                        if {$::mainDefine::result == $::mainDefine::parameter} {
                            $::mainDefine::objectName ResetTestPort
                        }
                    }

                    if {$::mainDefine::result == $::mainDefine::parameter} { 
                        set ::mainDefine::objectName $object
                        uplevel 1 {
                            set ::mainDefine::result [$::mainDefine::objectName cget -m_portName]
                        }

                        puts "Object $object will be destroyed."
                        set portName $::mainDefine::result
                        DestroyTestPort -PortName $portName 
                    }
                } 
            }
        }
    }
    
    debugPut "exit the proc of TestDevice::ForceReleasePort"    
    
    return $::mainDefine::gSuccess         
}

############################################################################
#APIName: ConfigResultOptions
#
#Description: Configure ResultOptions object
#
#Input:    1. -ResultViewMode result view mode，valid range:BASIC/JITTER，default value is BASIC
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::ConfigResultOptions {args} {
    
    debugPut "enter the proc of TestDevice::ConfigResultOptions"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse PortLocation parameter
    set index [lsearch $args -resultviewmode] 
    if {$index != -1} {
        set ResultViewMode [lindex $args [expr $index + 1]]
    } else {
        set ResultViewMode "BASIC"
    }

    set ResultOptions(1) [lindex [stc::get $m_hProject -children-ResultOptions] 0]
    stc::config $ResultOptions(1) \
        -ResultViewMode $ResultViewMode \
        -SaveAtEotProperties {}
 
    debugPut "exit the proc of TestDevice::ConfigResultOptions"    
    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: DeleteObject
#
#Description: Delete objects specified in parameter
#
#Input:    1. -Name name of the object
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::DeleteObject {args} {
   
    debugPut "enter the proc of TestDevice::DeleteObject"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse Name parameter
    set index [lsearch $args -name] 
    if {$index != -1} {
        set Name [lindex $args [expr $index + 1]]
    }
 
    if {[info exists Name]} {
        set index [lsearch $::mainDefine::gObjectNameList "*$Name"]  
        if { $index >= 0 } { 
            set object [lindex $::mainDefine::gObjectNameList $index]
            catch {itcl::delete object $object}
            puts "The object: $Name will be deleted ..."
        }
    }

    debugPut "exit the proc of TestDevice::DeleteObject"    
    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: ConfigStreamSchedulingMode
#
#Description: Configure stream scheduling mode
#
#Input:    1. -PortName port name
#          2. -SchedulingMode stream scheduling mode,valid range:PORT_BASED, RATE_BASED, PRIORITY_BASED,optional
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::ConfigStreamSchedulingMode {args} {
   
    debugPut "enter the proc of TestDevice::ConfigStreamSchedulingMode"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse PortName parameter
    set index [lsearch $args -portname] 
    if {$index != -1} {
        set PortNameList [lindex $args [expr $index + 1]]
    }
 
    #Parse SchedulingMode parameter
    set index [lsearch $args -schedulingmode] 
    if {$index != -1} {
        set SchedulingMode [lindex $args [expr $index + 1]]
    } else {
        set SchedulingMode "RATE_BASED"
    }

    if {[info exists PortNameList]} {
        foreach PortName $PortNameList {
            set ::mainDefine::gPortScheduleMode($PortName) $SchedulingMode
        }
        
    } else {
        set ::mainDefine::gStreamScheduleMode $SchedulingMode
    }

    debugPut "exit the proc of TestDevice::ConfigStreamSchedulingMode"    
    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: SubscribeResults
#
#Description: Write the test results to file automatically
#
#Input:    1. -FileName name of the file
#         
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::SubscribeResults {args} {
    
    debugPut "enter the proc of TestDevice::SubscribeResults"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse parameter PortName
    set index [lsearch $args -filename] 
    if {$index != -1} {
        set FileName [lindex $args [expr $index + 1]]
    } else {
        set FileName Spirent
    }
    
    set index [lsearch $args -interval] 
    if {$index != -1} {
        set interval [lindex $args [expr $index + 1]]
    } else {
        set interval 1
    }

    if {$m_resultDataSet1 != "0"} {
        stc::unsubscribe $m_resultDataSet1
    }
    set m_resultDataSet1 [stc::subscribe -Parent $m_hProject \
	                                 -resultParent $m_hProject \
	                                 -ConfigType streamblock \
	                                 -resultType TxStreamResults \
	                                 -filenamePrefix "$FileName\_RealTime_Tx" \
	                                 -viewAttributeList "FrameCount BitRate L1BitRate" \
	                                 -interval $interval]
   
    if {$m_resultDataSet2 != "0"} { 
        stc::unsubscribe $m_resultDataSet2                               
    }
    set m_resultDataSet2 [stc::subscribe -parent $m_hProject \
	                                 -resultParent $m_hProject \
	                                 -configType streamblock \
	                                 -resultType RxStreamSummaryResults \
	                                 -viewAttributeList "FrameCount BitRate L1BitRate AvgLatency MaxLatency MinLatency" \
	                                 -filenamePrefix "$FileName\_StreamSummary_Rx" \
	                                 -interval $interval]            

    debugPut "exit the proc of TestDevice::SubscribeResults"    
    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: BreakLinks
#
#Description: Break the links between STC port and DUT
#
#Input:    1. -PortName port name
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::BreakLinks {args} {
   
    debugPut "enter the proc of TestDevice::BreakLinks"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse PortName parameter
    set index [lsearch $args -portname] 
    if {$index != -1} {
        set PortNameList [lindex $args [expr $index + 1]]
    }
 
    if {[info exists PortNameList]} {
        foreach PortName $PortNameList {
            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
            set hPort $::mainDefine::result
            
            stc::perform L2TestBreakLinkCommand -Port $hPort
        }  
    } 

    debugPut "exit the proc of TestDevice::BreakLinks"    
    
    return $::mainDefine::gSuccess    
}

############################################################################
#APIName: RestoreLinks
#
#Description: Restore the links between STC port and DUT
#
#Input:    1. -PortName port name
#Output: None
#
#Coded by: Tony
#############################################################################

::itcl::body TestDevice::RestoreLinks {args} {
   
    debugPut "enter the proc of TestDevice::RestoreLinks"
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]

    #Parse PortName parameter
    set index [lsearch $args -portname] 
    if {$index != -1} {
        set PortNameList [lindex $args [expr $index + 1]]
    }
 
    if {[info exists PortNameList]} {
        foreach PortName $PortNameList {
            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
            set hPort $::mainDefine::result
            
            stc::perform L2TestRestoreLinkCommand -Port $hPort
        }  
    } 

    debugPut "exit the proc of TestDevice::RestoreLinks"    
    
    return $::mainDefine::gSuccess    
}
    
############################################################################
#APIName: RebootTestPort
#
#Description: Reboot the port
#
#Input:    1.-PortList PortList
#            2.If no parameter is specified, the Default Value will be all the TestPort object created previously.
#Output: None
#
#Coded by: Andy.zhang
#############################################################################

::itcl::body TestDevice::RebootTestPort  {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::RebootTestPort"

    #Parse PortName parameter
    set index [lsearch $args -portlist] 
    if {$index != -1} {
        set PortNameList [lindex $args [expr $index + 1]]
    } else {
        set PortNameList $m_portNameList
    }
 
    # achieve the port handle
    set hPortList ""
    foreach PortName $PortNameList {
       if {[lsearch $m_portNameList $PortName]!=-1} {
            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
            lappend hPortList $::mainDefine::result            
       } else {         
           error "the port $PortName is not exist"    
       }
    }

    # reboot the specified port
    stc::perform RebootEquipment -EquipmentList $hPortList
    debugPut "$PortNameList is reboot"

    # reserve the port
    foreach PortName $PortNameList {
        set ::mainDefine::objectName $PortName
        uplevel 1 {     
            set ::mainDefine::result [$::mainDefine::objectName cget -m_portLocation]     
        }
        set portLocation $::mainDefine::result
        stc::reserve $portLocation
    }

    stc::perform setupPortMappings
    
    debugPut "exit the proc of TestDevice::RebootTestPort"
    return $::mainDefine::gSuccess  
} 

############################################################################
#APIName: PrintInfo
#
#Description: Print port/stream info
#
#Input:    1.-PortList PortList
#            2.If no parameter is specified, the Default Value will be all the TestPort object created previously.
#Output: None
#
#Coded by: Andy.zhang
#############################################################################

::itcl::body TestDevice::PrintInfo  {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]  
    debugPut "enter the proc of TestDevice::PrintInfo"

    #Parse PortName parameter
    set index [lsearch $args -portlist] 
    if {$index != -1} {
        set PortNameList [lindex $args [expr $index + 1]]
    } else {
        set PortNameList $m_portNameList
    }
 
    # achieve the port handle
    set hPort ""
    foreach PortName $PortNameList {
       if {[lsearch $m_portNameList $PortName]!=-1} {
            set ::mainDefine::objectName $PortName
            uplevel 1 {     
                set ::mainDefine::result [$::mainDefine::objectName cget -m_hPort]     
            }     
            set hPort $::mainDefine::result 
            set Location [stc::get $hPort -Location]
            set SupportedPhys [stc::get $hPort -SupportedPhys]
            puts "======================= $PortName ======================="
            puts "Location : $Location"
            puts "SupportedPhys : $SupportedPhys"

            set hStreamList [stc::get $hPort -children-StreamBlock]
            if {$hStreamList!=""} {
                foreach hStream $hStreamList {
                    set streamBlockName [stc::get $hStream -Name]
                    set FrameLengthMode [stc::get $hStream -FrameLengthMode]
                    set FixedFrameLength [stc::get $hStream -FixedFrameLength]
                    set MinFrameLength [stc::get $hStream -MinFrameLength]
                    set MaxFrameLength [stc::get $hStream -MaxFrameLength]
                    set BurstSize [stc::get $hStream -BurstSize]
                    set LoadUnit [stc::get $hStream -LoadUnit]
                    set Load [stc::get $hStream -Load]
                    set MbpsLoad [stc::get $hStream -MbpsLoad]
                    set FrameConfig [stc::get $hStream -FrameConfig]
                    puts "---------- $streamBlockName ----------"
                    puts "FrameLengthMode : $FrameLengthMode"
                    puts "FixedFrameLength : $FixedFrameLength"
                    puts "MinFrameLength : $MinFrameLength"
                    puts "MaxFrameLength : $MaxFrameLength"
                    puts "BurstSize : $BurstSize"
                    puts "LoadUnit : $LoadUnit"
                    puts "Load : $Load"
                    puts "MbpsLoad : $MbpsLoad"
                    puts "FrameConfig : $FrameConfig"
               }
           }

       } else {         
           error "the port $PortName is not exist"    
       }
    }
    
    debugPut "exit the proc of TestDevice::PrintInfo"
    return $::mainDefine::gSuccess  
} 
proc CreateBfdConfigHLAPI {args} {
    set args [ConvertAttrPlusValueToLowerCase $args]
    #RouterRole
    #passive,active
    set index [lsearch $args -routerrole]
    if {$index != -1} {
        set routerrole [lindex $args [expr $index+1]]
    } else {
        set routerrole "active"
    }
    #TxInterval
    set index [lsearch $args -txinterval]
    if {$index != -1} {
        set txinterval [lindex $args [expr $index+1]]
    } else {
        set txinterval 50
    }
    #RxInterval
    set index [lsearch $args -rxinterval]
    if {$index != -1} {
        set rxinterval [lindex $args [expr $index+1]]
    } else {
        set rxinterval 50
    }
    #authentication
    #none,simple,md5
    set index [lsearch $args -authentication]
    if {$index != -1} {
        set authentication [lindex $args [expr $index+1]]
    } else {
        set authentication none
    }
    #password
    set index [lsearch $args -password]
    if {$index != -1} {
        set password [lindex $args [expr $index+1]]
    } else {
        set password spirent
    }
    #md5key
    set index [lsearch $args -md5key]
    if {$index != -1} {
        set md5key [lindex $args [expr $index+1]]
    } else {
        set md5key 1
    }
    set index [lsearch $args -router]
    set device [lindex $args [expr $index+1]]
    
    set index [lsearch $args -routerconfig]
    set routerconfig [lindex $args [expr $index+1]]
    set userIf [stc::get $routerconfig -UsesIf-targets]
    
    set bfdsession [stc::create "BfdRouterConfig" \
        -under $device \
        -RouterRole $routerrole \
        -TxInterval $txinterval \
        -RxInterval $rxinterval]
    
    set authenConfig [stc::get $bfdsession -children-BfdAuthenticationParams]
    if {$authenConfig == ""} {
        set authenConfig [stc::create BfdAuthenticationParams -under $bfdsession]
    }
    stc::config $authenConfig -Authentication $authentication -password $password -Md5KeyId $md5key
    return $bfdsession
}
proc SetBfdConfigHLAPI {args} {
    set args [ConvertAttrPlusValueToLowerCase $args]
    if { [catch {
            set configList ""
            set index [lsearch $args -bfdsession]
            set bfdsession [lindex $args [expr $index+1]]
            #routerrole
            set index [lsearch $args -routerrole]
            if {$index != -1} {
                lappend configList -RouterRole [lindex $args [expr $index+1]]
            }
            #txinterval
            set index [lsearch $args -txinterval]
            if {$index != -1} {
                lappend configList -TxInterval [lindex $args [expr $index+1]]
            }
            #rxinterval
            set index [lsearch $args -rxinterval]
            if {$index != -1} {
                lappend configList -RxInterval [lindex $args [expr $index+1]]
            }
            if {$configList != []} {
                foreach {att value} $configList {
                    stc::config $bfdsession $att $value
                }
            }
            
            set configList ""
            set authenCofig [stc::get $bfdsession -children-BfdAuthenticationParams]
            #authentication
            set index [lsearch $args -authentication]
            if {$index != -1} {
                lappend configList -Authentication [lindex $args [expr $index+1]]
            }
            #password
            set index [lsearch $args -password]
            if {$index != -1} {
                lappend configList -Password [lindex $args [expr $index+1]]
            }
            #md5key
            set index [lsearch $args -md5key]
            if {$index != -1} {
                lappend configList -Md5KeyId [lindex $args [expr $index+1]]
            }
            if {$configList != []} {
                foreach {att value} $configList {
                    stc::config $authenCofig $att $value
                }
            }
        } error ]} {
        puts $error
    }
}

proc UnsetBfdConfigHLAPI {args} {
    set args [ConvertAttrPlusValueToLowerCase $args]
    if { [catch {
            set index [lsearch $args -bfdsession]
            set bfdsession [lindex $args [expr $index+1]]
            
            set index [lsearch $args -routerconfig]
            set routerconfig [lindex $args [expr $index+1]]
            if {$bfdsession == ""} {
                stc::config $routerconfig -EnableBfd false
            } else {
                stc::delete $bfdsession
                stc::config $routerconfig -EnableBfd false
            }
        } error ]} {
        puts $error
    }
}
proc StartBfdHLAPI {args} {
    set args [ConvertAttrPlusValueToLowerCase $args]
    set index [lsearch $args -router]
    set router [lindex $args [expr $index+1]]
    catch {
        stc::perform BfdAdminUp -ObjectList $router
        stc::perform BfdResumePdus -ObjectList $router
    }
}
proc StopBfdHLAPI {args} {
    set args [ConvertAttrPlusValueToLowerCase $args]
    set index [lsearch $args -router]
    set router [lindex $args [expr $index+1]]
    catch {
        stc::perform BfdStopPdus -ObjectList $router
        stc::perform BfdAdmindown -ObjectList $router
    }
}