###########################################################################
#                                                                        
#  File Name：Stream.tcl                                                                                              
# 
#  Description：Definition of stream class and its methods                                           
# 
#  Author： Jaimin.Wan
#
#  Create Time:  2007.3.2
#
#  Version：1.0 
# 
#  History： 
# 
##########################################################################

##########################################
#Definition of Stream class
##########################################  
::itcl::class Stream {

    #Variables
    public variable m_hPort 0
    public variable m_portType "ethernet"
    public variable m_hProject 0
    public variable m_hStream 0
    public variable m_portLocation 0
    public variable m_pduNameList  0
    public variable m_FrameSigFlag 0
    public variable m_IPv4HeaderFlag 0
    public variable m_portName ""
    public variable m_EnableStream ""
    public variable m_streamName ""
    public variable m_streamType "Normal"

    public variable m_PduNameList  ""
    public variable m_PduHandleList 
    public variable m_typeModifierList
    public variable m_srcModifierList
    public variable m_destModifierList

    public variable m_mplsType ""
    public variable m_PriorEthHandle ""
    public variable m_EthType "AUTO"
    public variable m_dstEthMode "fixed"

    #Constructor
    constructor {portName hPort portType portLocation hProject hStream hSignature hEnableStream streamName streamType} { 
        set  m_portName $portName
        set  m_hPort  $hPort
        set  m_portType $portType 
        set  m_portLocation  $portLocation
        set  m_hProject  $hProject
        set  m_hStream  $hStream
        set  m_IPv4HeaderFlag 0
        set  m_EnableStream $hEnableStream
        set m_streamName $streamName
        set m_streamType $streamType

        if {$hSignature == "TRUE"} {
              set m_FrameSigFlag 1
        } else { 
              set  m_FrameSigFlag 0
        }
        lappend ::mainDefine::gObjectNameList $this
    }
    
    #Destructor
    destructor {
    set index [lsearch $::mainDefine::gObjectNameList $this]
    set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }
    
    public method AddEthHeaderIntoStream        
    public method AddIPv4HeaderIntoStream
    public method AddVlanHeaderIntoStream 
    public method AddIPv6HeaderIntoStream
    public method AddTcpHeaderIntoStream
    public method AddUdpHeaderIntoStream
    public method AddMplsHeaderIntoStream
    public method AddPOSHeaderIntoStream
    public method AddHDLCHeaderIntoStream
    public method AddDHCPPacketIntoStream
    public method AddGREPacketIntoStream 
    public method AddArpPacketIntoStream
    public method AddRipPacketIntoStream
    public method AddRipngPacketIntoStream
    public method AddIcmpPacketIntoStream
    public method AddOspfv2PacketIntoStream
    public method AddIcmpv6PacketIntoStream
    public method AddCustomPacketIntoStream 
    public method AddIGMPPacketIntoStream 
    public method AddPIMPacketIntoStream 
    public method AddPPPoEPacketIntoStream 
    public method AddMLDPacketIntoStream 
      
    #Methods
    public method AddPdu
    public method DestroyPdu 
    public method RemovePdu 

    #Methods internal use only
    public method  FindPdu
}

##########################################
#Definition of HeaderCreator class
##########################################  
::itcl::class HeaderCreator {

    #Variables
    public variable m_EnableStream ""
    public variable m_pduNameList ""

    #Constructor
    constructor {} { 
        lappend ::mainDefine::gObjectNameList $this
        lappend ::mainDefine::gHeaderCreatorList $this 
        set m_EnableStream $::mainDefine::gEnableStream
    }
    
    #Destructor
    destructor {
        set index [lsearch $::mainDefine::gObjectNameList $this]
        set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
        catch {
             if {$::mainDefine::gAutoDestroyPdu == "TRUE"} {
                 set ::mainDefine::gHeaderCreatorName $this
           
                 foreach pduName $m_pduNameList {
                     set ::mainDefine::gPduName $pduName
                     uplevel 1 {
                         $::mainDefine::gHeaderCreatorName DestroyPdu -PduName $::mainDefine::gPduName
                     }  
                 }
             }
        }
    }
    
    #Methods    
    public method CreateEthHeader
    public method CreateVlanHeader
    public method CreateIPV4Header
    public method CreateIPV6Header
    public method CreateTCPHeader
    public method CreateUDPHeader
    public method CreateMPLSHeader 
    public method CreatePOSHeader 
    public method CreateHDLCHeader 

    public method ConfigEthHeader
    public method ConfigVlanHeader
    public method ConfigIPV4Header
    public method ConfigIPV6Header
    public method ConfigTCPHeader
    public method ConfigUDPHeader
    public method ConfigMPLSHeader 

    public method DestroyPdu
}

############################################################################
#APIName: CreateIPV4Header
#Description: Create IPv4 header
#Input: 1. args:argument list，including
#              (1) -precedence precedence optional,priority of Tos, i.e -precedence routine
#              (2) -delay delay optional，minimum latency of Tos，i.e -delay normal
#              (3) -throughput throughput optional，maximum throughput of Tos，i.e -throughput normal
#              (4) -reliability reliability optional，reliability of Tos，i.e -reliability normal
#              (5) -identifier identifier optional，identifier for the package, i.e -identifier 0 
#              (6) -cost cost optional，Cost value, i.e -cost 0
#              (7) For other parameters, please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateIPV4Header {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateIPV4Header..."
        
    #Parse PduName parameters
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateIPV4Header API \nexit the proc of CreateIPV4Header..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateIPV4Header..."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "IPv4Header"

    set PduConfigList ""
    #Parse precedence parameter
    set index [lsearch $args -precedence] 
    if {$index != -1} {
        set precedence [lindex $args [expr $index + 1]]
    } else  {
        set precedence routine
    }  
    lappend PduConfigList -precedence
    lappend PduConfigList $precedence
    #Parse delay parameter
    set index [lsearch $args -delay] 
    if {$index != -1} {
        set delay [lindex $args [expr $index + 1]]
    } else  {
        set delay normal
    }
    lappend PduConfigList -delay
    lappend PduConfigList $delay
    
    #Parse throughput parameter
    set index [lsearch $args -throughput] 
    if {$index != -1} {
        set throughput [lindex $args [expr $index + 1]]
    } else  {
        set throughput normal
    }
    lappend PduConfigList -throughput
    lappend PduConfigList $throughput
    
    #Parse reliability parameter
    set index [lsearch $args -reliability] 
    if {$index != -1} {
        set reliability [lindex $args [expr $index + 1]]
    } else  {
        set reliability normal
    }
    lappend PduConfigList -reliability
    lappend PduConfigList $reliability

    set index [lsearch $args -cost] 
    if {$index != -1} {
        set cost [lindex $args [expr $index + 1]]
    } else  {
        set cost normalCost 
    }
    lappend PduConfigList -cost
    lappend PduConfigList $cost
    
    #Parse identifier parameter
    set index [lsearch $args -identifier] 
    if {$index != -1} {
        set identifier [lindex $args [expr $index + 1]]
    } else  {
        set identifier 0
    }
    lappend PduConfigList -identifier
    lappend PduConfigList $identifier
    
    ##Parse cost parameter
    #set index [lsearch $args -cost] 
    #if {$index != -1} {
    #    set cost [lindex $args [expr $index + 1]]
    #} else  {
    #    set cost 0
    #}
    #lappend PduConfigList -cost
    #lappend PduConfigList $cost
    #
    ##Parse reserved parameter
    #set index [lsearch $args -reserved] 
    #if {$index != -1} {
    #    set reserved [lindex $args [expr $index + 1]]
    #} else  {
    #    set reserved 0
    #}
    #lappend PduConfigList -reserved
    #lappend PduConfigList $reserved
    
    #Parse totalLength parameter
    set index [lsearch $args -totallength] 
    if {$index != -1} {
        set totalLength [lindex $args [expr $index + 1]]
    } else  {
        set totalLength 46
    } 
    lappend PduConfigList -totalLength
    lappend PduConfigList $totalLength
    
    #Parse lengthOverride parameter
    set index [lsearch $args -lengthoverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
    } else  {
        set lengthOverride false
    } 
    lappend PduConfigList -lengthOverride
    lappend PduConfigList $lengthOverride
    
    #Parse fragment parameter
    set index [lsearch $args -fragment] 
    if {$index != -1} {
        set fragment [lindex $args [expr $index + 1]]
    } else  {
        set fragment may
    } 
    lappend PduConfigList -fragment
    lappend PduConfigList $fragment
    
    #Parse lastFragment parameter
    set index [lsearch $args -lastfragment] 
    if {$index != -1} {
        set lastFragment [lindex $args [expr $index + 1]]
    } else  {
        set lastFragment last
    } 
    lappend PduConfigList -lastFragment
    lappend PduConfigList $lastFragment
    
    #Parse fragmentOffset parameter
    set index [lsearch $args -fragmentoffset] 
    if {$index != -1} {
        set fragmentOffset [lindex $args [expr $index + 1]]
    } else  {
        set fragmentOffset 0
    } 
    lappend PduConfigList -fragmentOffset
    lappend PduConfigList $fragmentOffset
    
    #Parse ttl parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set ttl [lindex $args [expr $index + 1]]
    } else  {
        set ttl 64
    } 
    lappend PduConfigList -ttl
    lappend PduConfigList $ttl
    
    #Parse ipProtocol parameter
    set index [lsearch $args -ipprotocol] 
    if {$index != -1} {
        set ipProtocol [lindex $args [expr $index + 1]]
    } else  {
        set ipProtocol 6
    } 
    lappend PduConfigList -ipProtocol
    lappend PduConfigList $ipProtocol
    
    #Parse ipProtocolMode parameter
    set index [lsearch $args -ipprotocolmode] 
    if {$index != -1} {
        set ipProtocolMode [lindex $args [expr $index + 1]]
    } else  {
        set ipProtocolMode "fixed"
    } 
    lappend PduConfigList -ipProtocolMode
    lappend PduConfigList $ipProtocolMode

    #Parse ipProtocolStep parameter
    set index [lsearch $args -ipprotocolstep] 
    if {$index != -1} {
        set ipProtocolStep [lindex $args [expr $index + 1]]
    } else  {
        set ipProtocolStep 1
    } 
    lappend PduConfigList -ipProtocolStep
    lappend PduConfigList $ipProtocolStep

    #Parse ipProtocolCount parameter
    set index [lsearch $args -ipprotocolcount] 
    if {$index != -1} {
        set ipProtocolCount [lindex $args [expr $index + 1]]
    } else  {
        set ipProtocolCount 1
    } 

    lappend PduConfigList -ipProtocolCount
    lappend PduConfigList $ipProtocolCount

    #Parse useValidChecksum parameter
    set index [lsearch $args -usevalidchecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
    } else  {
        set useValidChecksum true
    } 
    lappend PduConfigList -useValidChecksum
    lappend PduConfigList $useValidChecksum
    
    #Parse sourceIpAddr parameter
    set index [lsearch $args -sourceipaddr] 
    if {$index != -1} {
        set sourceIpAddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the sourceIpAddr of the stream \nexit the proc of CreateIPV4Header..."
    } 
    lappend PduConfigList -sourceIpAddr
    lappend PduConfigList $sourceIpAddr
    
    #Parse sourceIpMask parameter
    set index [lsearch $args -sourceipmask] 
    if {$index != -1} {
        set sourceIpMask [lindex $args [expr $index + 1]]
    } else  {
        set sourceIpMask 255.0.0.0
    } 
    lappend PduConfigList -sourceIpMask
    lappend PduConfigList $sourceIpMask
    
    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceipaddrmode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
    } else  {
        set sourceIpAddrMode fixed
    } 
    lappend PduConfigList -sourceIpAddrMode
    lappend PduConfigList $sourceIpAddrMode
    
    #Parse sourceIpAddrRepeatCount parameter
    set index [lsearch $args -sourceipaddrrepeatcount] 
    if {$index != -1} {
        set sourceIpAddrRepeatCount [lindex $args [expr $index + 1]]
    } else  {
        set sourceIpAddrRepeatCount 10
    } 
    lappend PduConfigList -sourceIpAddrRepeatCount
    lappend PduConfigList $sourceIpAddrRepeatCount
    
    #Parse sourceClass parameter
    set index [lsearch $args -sourceclass] 
    if {$index != -1} {
        set sourceClass [lindex $args [expr $index + 1]]
    } else  {
        set sourceClass classA
    }
    lappend PduConfigList -sourceClass
    lappend PduConfigList $sourceClass
    
    ##Parse enableSourceSyncFromPpp parameter
    #set index [lsearch $args -enableSourceSyncFromPpp] 
    #if {$index != -1} {
    #    set enableSourceSyncFromPpp [lindex $args [expr $index + 1]]
    #} else  {
    #    set enableSourceSyncFromPpp false
    #} 
    #lappend PduConfigList -enableSourceSyncFromPpp
    #lappend PduConfigList $enableSourceSyncFromPpp
    
    #Parse destIpAddr parameter 
    set index [lsearch $args -destipaddr] 
    if {$index != -1} {
        set destIpAddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the destIpAddr of the stream \nexit the proc of CreateIPV4Header..."
    } 
    lappend PduConfigList -destIpAddr
    lappend PduConfigList $destIpAddr
    
    #Parse destIpMask parameter
    set index [lsearch $args -destipmask] 
    if {$index != -1} {
        set destIpMask [lindex $args [expr $index + 1]]
    } else  {
        set destIpMask 255.0.0.0
    } 
    lappend PduConfigList -destIpMask
    lappend PduConfigList $destIpMask
    
    #Parse destIpAddrMode parameter
    set index [lsearch $args -destipaddrmode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
    } else  {
        set destIpAddrMode fixed
    } 

    lappend PduConfigList -destIpAddrMode
    lappend PduConfigList $destIpAddrMode
    
    #Parse destIpAddrRepeatCount parameter
    set index [lsearch $args -destipaddrrepeatcount] 
    if {$index != -1} {
        set destIpAddrRepeatCount [lindex $args [expr $index + 1]]
    } else  {
        set destIpAddrRepeatCount 10
    } 
    lappend PduConfigList -destIpAddrRepeatCount
    lappend PduConfigList $destIpAddrRepeatCount
    
    #Parse destClass parameter
    set index [lsearch $args -destclass] 
    if {$index != -1} {
        set destClass [lindex $args [expr $index + 1]]
    } else  {
        set destClass classA
    } 
    lappend PduConfigList -destClass
    lappend PduConfigList $destClass
    
    ##Parse destMacAddr parameter
    #set index [lsearch $args -destmacaddr] 
    #if {$index != -1} {
    #    set destMacAddr [lindex $args [expr $index + 1]]
    #} else  {
    #    set destMacAddr 00:00:00:00:00:01
    #} 
    #lappend PduConfigList -destMacAddr
    #lappend PduConfigList $destMacAddr
    #
    #Parse destDutIpAddr parameter
    set index [lsearch $args -destdutipaddr] 
    if {$index != -1} {
        set destDutIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set destDutIpAddr 192.85.1.1
    } 
    lappend PduConfigList -destDutIpAddr
    lappend PduConfigList $destDutIpAddr
    
    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
    } else  {
        set options AA
    } 
    lappend PduConfigList -options
    lappend PduConfigList $options
    
    #Parse gateway parameter
    set index [lsearch $args -gateway] 
    if {$index != -1} {
        set gateway [lindex $args [expr $index + 1]]
    } else  {
        set gateway 192.168.1.1
    } 
    lappend PduConfigList -gateway
    lappend PduConfigList $gateway
    
    ##Parse enableDestSyncFromPpp parameter
    #set index [lsearch $args -enabledestsyncfromppp] 
    #if {$index != -1} {
    #    set enableDestSyncFromPpp [lindex $args [expr $index + 1]]
    #} else  {
    #    set enableDestSyncFromPpp false
    #} 
    #lappend PduConfigList -enableDestSyncFromPpp
    #lappend PduConfigList $enableDestSyncFromPpp
    
    #Parse qosMode parameter
    set index [lsearch $args -qosmode] 
    if {$index != -1} {
        set qosMode [lindex $args [expr $index + 1]]
    } else  {
        set qosMode  ipV4ConfigDscp
    } 
    lappend PduConfigList -qosMode
    lappend PduConfigList $qosMode

    #Parse qosValue parameter
    set index [lsearch $args -qosvalue] 
    if {$index != -1} {
        set qosValue [lindex $args [expr $index + 1]]

        lappend PduConfigList -qosValueExist
        lappend PduConfigList "TRUE"
    } else  {
        lappend PduConfigList -qosValueExist
        lappend PduConfigList "FALSE"

        set qosValue  0
    } 
    lappend PduConfigList -qosValue
    lappend PduConfigList $qosValue

    #dscpMode and dscpValue are used to keep compatibility with original scripts
    ###############################################
    #Parse dscpMode parameter
    set index [lsearch $args -dscpmode] 
    if {$index != -1} {
        set dscpMode [lindex $args [expr $index + 1]]
    } else  {
        set dscpMode ipV4DscpDefault
    } 
    lappend PduConfigList -dscpMode
    lappend PduConfigList $dscpMode
    
    #Parse DscpValue parameter
    set index [lsearch $args -dscpvalue] 
    if {$index != -1} {
        set dscpValue [lindex $args [expr $index + 1]]
    } else  {
        set dscpValue 0x00
    }  
    lappend PduConfigList -dscpValue
    lappend PduConfigList $dscpValue
    ###############################################

    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceipaddrmode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
    } else  {
        set sourceIpAddrMode fix
    }  
    lappend PduConfigList -sourceIpAddrMode
    lappend PduConfigList $sourceIpAddrMode

    #Parse destIpAddrMode parameter
    set index [lsearch $args -destipaddrmode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
    } else  {
        set destIpAddrMode fix
    }  
    lappend PduConfigList -destIpAddrMode
    lappend PduConfigList $destIpAddrMode

    #Parse sourceIpAddrRepeatStep parameter
    set index [lsearch $args -sourceipaddrrepeatstep] 
    if {$index != -1} {
        set sourceIpAddrRepeatStep [lindex $args [expr $index + 1]]
    } else  {
        set sourceIpAddrRepeatStep 1
    }  
    lappend PduConfigList -sourceIpAddrRepeatStep
    lappend PduConfigList $sourceIpAddrRepeatStep

    #Parse destIpAddrRepeatStep parameter
    set index [lsearch $args -destipaddrrepeatstep] 
    if {$index != -1} {
        set destIpAddrRepeatStep [lindex $args [expr $index + 1]]
    } else  {
        set destIpAddrRepeatStep 1
    }  
    lappend PduConfigList -destIpAddrRepeatStep
    lappend PduConfigList $destIpAddrRepeatStep
    
    #Parse SrcDataList parameter
    set index [lsearch $args -srcdatalist] 
    if {$index != -1} {
        set srcDataList [lindex $args [expr $index + 1]]
    } else  {
        set srcDataList "NULL"
    }  
    lappend PduConfigList -srcDataList
    lappend PduConfigList $srcDataList
   
    #Parse DestDataList parameter
    set index [lsearch $args -destdatalist] 
    if {$index != -1} {
        set destDataList [lindex $args [expr $index + 1]]
    } else  {
        set destDataList "NULL"
    }  
    lappend PduConfigList -destDataList
    lappend PduConfigList $destDataList
    
    lappend ::mainDefine::gPduConfigList "$PduConfigList"
    
    debugPut "exit the proc of HeaderCreator::CreateIPV4Header..." 

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigIPV4Header
#Description: Config IPv4 header
#Input: 1. args:argument list, including
#              (1) -precedence precedence optional,priority of Tos, i.e -precedence routine
#              (2) -delay delay optional，minimum latency of Tos，i.e -delay normal
#              (3) -throughput throughput optional，maximum throughput of Tos，i.e -throughput normal
#              (4) -reliability reliability optional，reliability of Tos，i.e -reliability normal
#              (5) -identifier identifier optional，identifier for the package, i.e -identifier 0 
#              (6) -cost cost optional，Cost value, i.e -cost 0
#              (7) For other parameters, please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigIPV4Header {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::ConfigIPV4Header..."
        
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigIPV4Header API \nexit the proc of ConfigIPV4Header..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist  \nexit the proc of ConfigIPV4Header..."
    }
 
    #Parse precedence parameter
    set index [lsearch $args -precedence] 
    if {$index != -1} {
        set precedence [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-precedence" $precedence
    } 

    #Parse delay parameter
    set index [lsearch $args -delay] 
    if {$index != -1} {
        set delay [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-delay" $delay
    }
    
    #Parse throughput parameter
    set index [lsearch $args -throughput] 
    if {$index != -1} {
        set throughput [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-throughput" $throughput
    }

    #Parse reliability parameter
    set index [lsearch $args -reliability] 
    if {$index != -1} {
        set reliability [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-reliability" $reliability
    }
    
    set index [lsearch $args -cost] 
    if {$index != -1} {
        set cost [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-cost" $cost
    }

    #Parse identifier parameter
    set index [lsearch $args -identifier] 
    if {$index != -1} {
        set identifier [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-identifier" $identifier
    }

    #Parse totalLength parameter
    set index [lsearch $args -totallength] 
    if {$index != -1} {
        set totalLength [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-totalLength" $totalLength
    }
    
    #Parse lengthOverride parameter
    set index [lsearch $args -lengthoverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-lengthOverride" $lengthOverride
    } 

    #Parse fragment parameter
    set index [lsearch $args -fragment] 
    if {$index != -1} {
        set fragment [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-fragment" $fragment
    } 

    #Parse lastFragment parameter
    set index [lsearch $args -lastfragment] 
    if {$index != -1} {
        set lastFragment [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-lastFragment" $lastFragment
    }

    #Parse fragmentOffset parameter
    set index [lsearch $args -fragmentoffset] 
    if {$index != -1} {
        set fragmentOffset [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-fragmentOffset" $fragmentOffset
    }

    #Parse ttl parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set ttl [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-ttl" $ttl
    }
    
    #Parse ipProtocol parameter
    set index [lsearch $args -ipprotocol] 
    if {$index != -1} {
        set ipProtocol [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-ipProtocol" $ipProtocol
    }

    #Parse ipProtocolMode parameter
    set index [lsearch $args -ipprotocolmode] 
    if {$index != -1} {
        set ipProtocolMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-ipProtocolMode" $ipProtocolMode
    }

    #Parse ipProtocolStep parameter
    set index [lsearch $args -ipprotocolstep] 
    if {$index != -1} {
        set ipProtocolStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-ipProtocolStep" $ipProtocolStep
    }

    #Parse ipProtocolCount parameter
    set index [lsearch $args -ipprotocolcount] 
    if {$index != -1} {
        set ipProtocolCount [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-ipProtocolCount" $ipProtocolCount
    }

    #Parse useValidChecksum parameter
    set index [lsearch $args -usevalidchecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-useValidChecksum" $useValidChecksum 
    }

    #Parse sourceIpAddr parameter
    set index [lsearch $args -sourceipaddr] 
    if {$index != -1} {
        set sourceIpAddr [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpAddr" $sourceIpAddr
    } 

    #Parse sourceIpMaskparameter
    set index [lsearch $args -sourceipmask] 
    if {$index != -1} {
        set sourceIpMask [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpMask" $sourceIpMask
    }

    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceipaddrmode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpAddrMode" $sourceIpAddrMode
    } 

    #Parse sourceIpAddrRepeatCount parameter
    set index [lsearch $args -sourceipaddrrepeatcount] 
    if {$index != -1} {
        set sourceIpAddrRepeatCount [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpAddrRepeatCount" $sourceIpAddrRepeatCount
    } 

    #Parse sourceClass parameter
    set index [lsearch $args -sourceclass] 
    if {$index != -1} {
        set sourceClass [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceClass" $sourceClass
    }

    #Parse destIpAddr parameter
    set index [lsearch $args -destipaddr] 
    if {$index != -1} {
        set destIpAddr [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpAddr" $destIpAddr
    }

    #Parse destIpMask parameter
    set index [lsearch $args -destipmask] 
    if {$index != -1} {
        set destIpMask [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpMask" $destIpMask
    } 

    #Parse destIpAddrMode parameter
    set index [lsearch $args -destipaddrmode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpAddrMode" $destIpAddrMode
    } 
    
    #Parse destIpAddrRepeatCount parameter
    set index [lsearch $args -destipaddrrepeatcount] 
    if {$index != -1} {
        set destIpAddrRepeatCount [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpAddrRepeatCount" $destIpAddrRepeatCount
    } 

    #Parse destClass parameter
    set index [lsearch $args -destclass] 
    if {$index != -1} {
        set destClass [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destClass" $destClass
    } 

    #Parse destDutIpAddr parameter
    set index [lsearch $args -destdutipaddr] 
    if {$index != -1} {
        set destDutIpAddr [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destDutIpAddr" $destDutIpAddr
    }

    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-options" $options
    }
    
    #Parse qosMode parameter
    set index [lsearch $args -qosmode] 
    if {$index != -1} {
        set qosMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-qosMode" $qosMode
    }

    #Parse qosValue parameter
    set index [lsearch $args -qosvalue] 
    if {$index != -1} {
        set qosValue [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-qosValue" $qosValue
        ReplacePduAttrValue $PduName "-qosValueExist" "TRUE"
    }
  
    #dscpMode and dscpValue are used to keep compatibility with previous version
    ###############################################
    #Parse dscpMode parameter
    set index [lsearch $args -dscpmode] 
    if {$index != -1} {
        set dscpMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-dscpMode" $dscpMode
    } 

    #Parse dscpValue parameter
    set index [lsearch $args -dscpvalue] 
    if {$index != -1} {
        set dscpValue [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-dscpValue" $dscpValue
    }
   ###############################################

    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceipaddrmode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpAddrMode" $sourceIpAddrMode 
    }

    #Parse destIpAddrMode parameter
    set index [lsearch $args -destipaddrmode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpAddrMode" $destIpAddrMode
    }

    #Parse sourceIpAddrRepeatStep parameter
    set index [lsearch $args -sourceipaddrrepeatstep] 
    if {$index != -1} {
        set sourceIpAddrRepeatStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourceIpAddrRepeatStep" $sourceIpAddrRepeatStep
    }

    #Parse destIpAddrRepeatStep parameter
    set index [lsearch $args -destipaddrrepeatstep] 
    if {$index != -1} {
        set destIpAddrRepeatStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destIpAddrRepeatStep" $destIpAddrRepeatStep
    }

    #Parse SrcDataList parameter
    set index [lsearch $args -srcdatalist] 
    if {$index != -1} {
        set srcDataList [lindex $args [expr $index + 1]]
         ReplacePduAttrValue $PduName "-srcDataList" $srcDataList
    } 

    #Parse DestDataList parameter
    set index [lsearch $args -destdatalist] 
    if {$index != -1} {
        set destDataList [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destDataList" $destDataList 
    }
    
    ApplyPduConfigToStreams $PduName
    debugPut "exit the proc of HeaderCreator::ConfigIPV4Header..." 

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateIPV6Header
#Description: Create IPv6 header
#Input: 1. args:For the parameters, plese refer to the user guide
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body HeaderCreator::CreateIPV6Header {args} { 
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of HeaderCreator::CreateIPV6Header"    
   
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateIPV6Header API "
    }    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "IPv6Header"
    lappend ::mainDefine::gPduConfigList $args
    
    debugPut "exit the proc of HeaderCreator::CreateIPV6Header"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigIPV6Header
#Description: Config 
#Input: 1. args:For the parameters, plese refer to the user guide
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body HeaderCreator::ConfigIPV6Header {args} { 
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of HeaderCreator::ConfigIPV6Header"    
   
    #Parse PduName parameters
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigIPV6Header API "
    }    

    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist "
    } 
    
    set index [lsearch $::mainDefine::gPduConfigList $PduName] 
    set pduConfig [lindex $::mainDefine::gPduConfigList [expr $index + 2]]

    foreach {name valueVar}  $args {      
         set value_index [lsearch $pduConfig $name] 
         if {$value_index != -1} {
              set pduConfig [lreplace $pduConfig [expr $value_index + 1] [expr $value_index  + 1] $valueVar]
         } else {
             lappend pduConfig "$name"
             lappend pduConfig $valueVar  
         } 
     }        

    set ::mainDefine::gPduConfigList [lreplace $::mainDefine::gPduConfigList  [expr $index + 2] [expr $index + 2] $pduConfig]

    ApplyPduConfigToStreams $PduName
    debugPut "exit the proc of HeaderCreator::ConfigIPV6Header"

    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateTCPHeader
#Description: Create TCP header
#Input: 1. args:argument list, including
#              (1) -offset offset optional,offset,i.e -offset 5
#              (2) -sourcePort sourcePort required，TCP source port, i.e -sourcePort 3000
#              (3) -destPort destPort required，TCP destination port, i.e -destPort 4000 
#              (4) -sequenceNumber sequenceNumber optional,seqeunce number,i.e -sequenceNumber 0 
#              (5) For other parameters, please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateTCPHeader {args} {
     
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateTCPHeader..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateTCPHeader API \nexit the proc of CreateTCPHeader..."
    } 
    
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateTCPHeader..."
    } 
  
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "TcpHeader"
    
    set PduConfigList ""
    
    #Parse offset parameter
    set index [lsearch $args -offset] 
    if {$index != -1} {
        set offset [lindex $args [expr $index + 1]]
    } else  {
        set offset 5
    }
    lappend PduConfigList -offset
    lappend PduConfigList $offset
    
    #Parse sourcePort parameter
    set index [lsearch $args -sourceport] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the sourcePort of the stream \nexit the proc of CreateTCPHeader..."
    }
    lappend PduConfigList -sourcePort
    lappend PduConfigList $sourcePort
    
    #Parse destPort parameter
    set index [lsearch $args -destport] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the destPort of the stream \nexit the proc of CreateTCPHeader..."
    }
    lappend PduConfigList -destPort
    lappend PduConfigList $destPort
    
    #Parse sequenceNumber parameter
    set index [lsearch $args -sequencenumber] 
    if {$index != -1} {
        set sequenceNumber [lindex $args [expr $index + 1]]
    } else  {
        set sequenceNumber 0
    }
    lappend PduConfigList -sequenceNumber
    lappend PduConfigList $sequenceNumber
    
    #Parse acknowledgementNumber parameter
    set index [lsearch $args -acknowledgementnumber] 
    if {$index != -1} {
        set acknowledgementNumber [lindex $args [expr $index + 1]]
    } else  {
        set acknowledgementNumber 0
    }
    lappend PduConfigList -acknowledgementNumber
    lappend PduConfigList $acknowledgementNumber
    
    #Parse window parameter
    set index [lsearch $args -window] 
    if {$index != -1} {
        set window [lindex $args [expr $index + 1]]
    } else  {
        set window 0
    }
    lappend PduConfigList -window
    lappend PduConfigList $window
    
    #Parse urgentPointer parameter
    set index [lsearch $args -urgentpointer] 
    if {$index != -1} {
        set urgentPointer [lindex $args [expr $index + 1]]
    } else  {
        set urgentPointer 0
    }
    lappend PduConfigList -urgentPointer
    lappend PduConfigList $urgentPointer
    
    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
    } else  {
        set options ""
    }
    lappend PduConfigList -options
    lappend PduConfigList $options
    
    #Parse urgentPointerValid parameter
    set index [lsearch $args -urgentpointervalid] 
    if {$index != -1} {
        set urgentPointerValid [lindex $args [expr $index + 1]]
    } else  {
        set urgentPointerValid false
    }
    lappend PduConfigList -urgentPointerValid
    lappend PduConfigList $urgentPointerValid
    
    #Parse acknowledgeValid parameter
    set index [lsearch $args -acknowledgevalid] 
    if {$index != -1} {
        set acknowledgeValid [lindex $args [expr $index + 1]]
    } else  {
        set acknowledgeValid false
    }
    lappend PduConfigList -acknowledgeValid
    lappend PduConfigList $acknowledgeValid
    
    #Parse pushFunctionValid parameter
    set index [lsearch $args -pushfunctionvalid] 
    if {$index != -1} {
        set pushFunctionValid [lindex $args [expr $index + 1]]
    } else  {
        set pushFunctionValid false
    }
    lappend PduConfigList -pushFunctionValid
    lappend PduConfigList $pushFunctionValid
    
    #Parse resetConnection parameter
    set index [lsearch $args -resetconnection] 
    if {$index != -1} {
        set resetConnection [lindex $args [expr $index + 1]]
    } else  {
        set resetConnection false
    }
    lappend PduConfigList -resetConnection
    lappend PduConfigList $resetConnection
    
    #Parse synchronize parameter
    set index [lsearch $args -synchronize] 
    if {$index != -1} {
        set synchronize [lindex $args [expr $index + 1]]
    } else  {
        set synchronize false
    }
    lappend PduConfigList -synchronize
    lappend PduConfigList $synchronize
    
    #Parse finished parameter
    set index [lsearch $args -finished] 
    if {$index != -1} {
        set finished [lindex $args [expr $index + 1]]
    } else  {
        set finished false
    }
    lappend PduConfigList -finished
    lappend PduConfigList $finished
    
    #Parse useValidChecksum parameter
    set index [lsearch $args -usevalidchecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
    } else  {
        set useValidChecksum true        ;# 修改默认值为true, changed by lana 20130702
    }
    lappend PduConfigList -useValidChecksum
    lappend PduConfigList $useValidChecksum
    
    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    } else {
        set checksum 0
    }
    lappend PduConfigList -checksum
    lappend PduConfigList $checksum
    
    #Parse srcPortMode parameter
    set index [lsearch $args -srcportmode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
    } else {
        set srcPortMode fixed
    }
    lappend PduConfigList -srcPortMode
    lappend PduConfigList $srcPortMode
    
    #Parse srcPortStep parameter
    set index [lsearch $args -srcportstep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -srcstep] 
        if {$index != -1} {
            set srcStep [lindex $args [expr $index + 1]]
        } else {
            set srcStep 1
        }
    }
    lappend PduConfigList -srcStep
    lappend PduConfigList $srcStep
    
    #Parse dstPortMode parameter
    set index [lsearch $args -dstportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -destportmode] 
        if {$index != -1} {
            set destPortMode [lindex $args [expr $index + 1]]
        } else {
            set destPortMode fixed
        }
    }
    lappend PduConfigList -destPortMode
    lappend PduConfigList $destPortMode
    
    #Parse dstPortStep parameter
    set index [lsearch $args -dstportstep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -deststep] 
        if {$index != -1} {
            set destStep [lindex $args [expr $index + 1]]
        } else {
            set destStep 1
        }
    }
    lappend PduConfigList -destStep
    lappend PduConfigList $destStep
    
    #Parse dstPortCount parameter
    set index [lsearch $args -dstportcount] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -numdest] 
        if {$index != -1} {
            set numDest [lindex $args [expr $index + 1]]
        } else {
            set numDest 1
        }
    }
    lappend PduConfigList -numDest
    lappend PduConfigList $numDest
    
    #Parse SrcPortCount parameter
    set index [lsearch $args -srcportcount] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -numsrc] 
        if {$index != -1} {
            set numSrc [lindex $args [expr $index + 1]]
        } else {
            set numSrc 1
        }
    }
    lappend PduConfigList -numSrc
    lappend PduConfigList $numSrc
    
    lappend ::mainDefine::gPduConfigList "$PduConfigList"
    
    debugPut "exit the proc of HeaderCreator::CreateTCPHeader..."  
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigTCPHeader
#Description: Config TCP header
#Input: 1. args:argument list, including
#              (1) -offset offset optional,offset,i.e -offset 5
#              (2) -sourcePort sourcePort required，TCP source port, i.e -sourcePort 3000
#              (3) -destPort destPort required，TCP destination port, i.e -destPort 4000 
#              (4) -sequenceNumber sequenceNumber optional,seqeunce number,i.e -sequenceNumber 0 
#              (5) For other parameters, please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigTCPHeader {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::ConfigTCPHeader..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigTCPHeader API \nexit the proc of ConfigTCPHeader..."
    } 
    
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
       error "PduName($PduName) does not exist \nexit the proc of ConfigTCPHeader..."
   } 
    
    #Parse offset parameter
    set index [lsearch $args -offset] 
    if {$index != -1} {
        set offset [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-offset" $offset 
    } 

    #Parse sourcePort parameter
    set index [lsearch $args -sourceport] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourcePort" $sourcePort
    }

    #Parse destPort parameter
    set index [lsearch $args -destport] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPort" $destPort 
    }

    #Parse sequenceNumber parameter
    set index [lsearch $args -sequencenumber] 
    if {$index != -1} {
        set sequenceNumber [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sequenceNumber" $sequenceNumber 
    }

    #Parse acknowledgementNumber parameter
    set index [lsearch $args -acknowledgementnumber] 
    if {$index != -1} {
        set acknowledgementNumber [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-acknowledgementNumber" $acknowledgementNumber 
    }

    #Parse window parameter
    set index [lsearch $args -window] 
    if {$index != -1} {
        set window [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-window" $window 
    }

    #Parse urgentPointer parameter
    set index [lsearch $args -urgentpointer] 
    if {$index != -1} {
        set urgentPointer [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-urgentPointer" $urgentPointer
    }

    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-options" $options
    }

    #Parse urgentPointerValid parameter
    set index [lsearch $args -urgentpointervalid] 
    if {$index != -1} {
        set urgentPointerValid [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-urgentPointerValid" $urgentPointerValid
    }

    #Parse acknowledgeValid parameter
    set index [lsearch $args -acknowledgevalid] 
    if {$index != -1} {
        set acknowledgeValid [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-acknowledgeValid" $acknowledgeValid 
    } 

    #Parse pushFunctionValid parameter
    set index [lsearch $args -pushfunctionvalid] 
    if {$index != -1} {
        set pushFunctionValid [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-pushFunctionValid" $pushFunctionValid
    }

    #Parse resetConnection parameter
    set index [lsearch $args -resetconnection] 
    if {$index != -1} {
        set resetConnection [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-resetConnection" $resetConnection
    }
    
    #Parse synchronize parameter
    set index [lsearch $args -synchronize] 
    if {$index != -1} {
        set synchronize [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-synchronize" $synchronize
    } 

    #Parse finished parameter
    set index [lsearch $args -finished] 
    if {$index != -1} {
        set finished [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-finished" $finished    
    } 
    
    #Parse useValidChecksum parameter
    set index [lsearch $args -usevalidchecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-useValidChecksum" $useValidChecksum 
    } 

    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-checksum" $checksum
    } 

    #Parse srcPortMode parameter
    set index [lsearch $args -srcportmode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcPortMode" $srcPortMode 
    } 

    #Parse srcStep parameter
    set index [lsearch $args -srcstep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcStep" $srcStep 
    }

    #Parse srcPortStep parameter
    set index [lsearch $args -srcportstep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcStep" $srcStep 
    }

    #Parse destPortMode parameter
    set index [lsearch $args -destportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPortMode" $destPortMode 
    } 

    #Parse dstPortMode parameter
    set index [lsearch $args -dstportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPortMode" $destPortMode 
    } 

    #Parse destStep parameter
    set index [lsearch $args -deststep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destStep" $destStep 
    } 

    #Parse dstPortStep parameter
    set index [lsearch $args -dstportstep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destStep" $destStep 
    } 

    #Parse numDest parameter
    set index [lsearch $args -numdest] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numDest" $numDest
    }

    #Parse dstPortCount parameter
    set index [lsearch $args -dstportcount] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numDest" $numDest
    }

    #Parse numSrc parameter
    set index [lsearch $args -numsrc] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numSrc" $numSrc
    }

    #Parse srcPortCount parameter
    set index [lsearch $args -srcportcount] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numSrc" $numSrc
    }
    
    ApplyPduConfigToStreams $PduName

    debugPut "exit the proc of HeaderCreator::ConfigTCPHeader..."  
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateUDPHeader
#Description: Create UDP header
#Input: 1. args:argument list，including
#              (1) -sourcePort  sourcePort required,UDP source port,i.e -sourcePort 4000
#              (2) -destPort destPort required,UDP destination port, i.e -destPort 5000 
#              (3) -enableChecksum enableChecksum optional，whether or not enable checksum，i.e -enableChecksum true
#              (4) -length length optional,UDP packet length,i.e  -length 10
#              (5) For toher parameters please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateUDPHeader {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateUDPHeader..."
 
    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateUDPHeader API \nexit the proc of CreateUDPHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "UdpHeader"

    set PduConfigList ""
        
    #Parse sourcePort parameter
    set index [lsearch $args -sourceport] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the sourcePort of the stream \nexit the proc of CreateUDPHeader..."
    }
    lappend PduConfigList -sourcePort
    lappend PduConfigList $sourcePort
    
    #Parse destPort parameter
    set index [lsearch $args -destport] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the destPort of the stream \nexit the proc of CreateUDPHeader..."
    }
    lappend PduConfigList -destPort
    lappend PduConfigList $destPort
    
    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    } else  {
        set checksum 0
    }
    lappend PduConfigList -checksum
    lappend PduConfigList $checksum
    
    #Parse enableChecksum parameter
    set index [lsearch $args -enablechecksum] 
    if {$index != -1} {
        set enableChecksum [lindex $args [expr $index + 1]]
    } else  {
        set enableChecksum true
    }
    lappend PduConfigList -enableChecksum
    lappend PduConfigList $enableChecksum
    
    #Parse length parameter
    set index [lsearch $args -length] 
    if {$index != -1} {
        set length [lindex $args [expr $index + 1]]
    } else  {
        set length 10
    }
    lappend PduConfigList -length
    lappend PduConfigList $length
    
    #Parse lengthOverride parameter
    set index [lsearch $args -lengthoverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
    } else  {
        set lengthOverride false
    }
    lappend PduConfigList -lengthOverride
    lappend PduConfigList $lengthOverride
    
    #Parse enableChecksumOverride parameter
    set index [lsearch $args -enablechecksumoverride] 
    if {$index != -1} {
        set enableChecksumOverride [lindex $args [expr $index + 1]]
    } else  {
        set enableChecksumOverride false
    }
    lappend PduConfigList -enableChecksumOverride
    lappend PduConfigList $enableChecksumOverride
    
    #Parse checksumMode parameter
    set index [lsearch $args -checksummode] 
    if {$index != -1} {
        set checksumMode [lindex $args [expr $index + 1]]
    } else  {
        set checksumMode auto
    }
    lappend PduConfigList -checksumMode
    lappend PduConfigList $checksumMode
    #Parse srcPortMode parameter
    set index [lsearch $args -srcportmode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
    } else {
        set srcPortMode fixed
    }
    lappend PduConfigList -srcPortMode
    lappend PduConfigList $srcPortMode
    
    #Parse srcPortStep parameter
    set index [lsearch $args -srcportstep] 
   
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -srcstep] 

        if {$index != -1} {
           set srcStep [lindex $args [expr $index + 1]]
        } else {
           set srcStep 1
        }
    }
    lappend PduConfigList -srcStep
    lappend PduConfigList $srcStep
    
    #Parse dstPortMode parameter
    set index [lsearch $args -dstportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -destportmode] 
        if {$index != -1} {
            set destPortMode [lindex $args [expr $index + 1]]
        } else {
            set destPortMode fixed
        }
    }
    lappend PduConfigList -destPortMode
    lappend PduConfigList $destPortMode
    
    #Parse dstPortStep parameter
    set index [lsearch $args -dstportstep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -deststep] 
        if {$index != -1} {
            set destStep [lindex $args [expr $index + 1]]
        } else {
            set destStep 1
        }
    }
    lappend PduConfigList -destStep
    lappend PduConfigList $destStep
    
    #Parse dstPortCount parameter
    set index [lsearch $args -dstportcount] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -numdest] 
        if {$index != -1} {
            set numDest [lindex $args [expr $index + 1]]
        } else {
            set numDest 1
        }
    }
    lappend PduConfigList -numDest
    lappend PduConfigList $numDest
    
    #Parse srcportcount parameter
    set index [lsearch $args -srcportcount]
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
    } else {
        set index [lsearch $args -numsrc] 
        if {$index != -1} {
            set numSrc [lindex $args [expr $index + 1]]
        } else {
            set numSrc 1
        }
    } 
    lappend PduConfigList -numSrc
    lappend PduConfigList $numSrc

    lappend ::mainDefine::gPduConfigList "$PduConfigList"
 
    debugPut "exit the proc of HeaderCreator::CreateUDPHeader..." 
    return $::mainDefine::gSuccess  
}

############################################################################
#APIName: ConfigUDPHeader
#Description: Configure UDP header
#Input: 1. args:argument list，including
#              (1) -sourcePort  sourcePort required,UDP source port,i.e -sourcePort 4000
#              (2) -destPort destPort required,UDP destination port, i.e -destPort 5000 
#              (3) -enableChecksum enableChecksum optional，whether or not enable checksum，i.e -enableChecksum true
#              (4) -length length optional,UDP packet length,i.e  -length 10
#              (5) For toher parameters please refer to the user guide
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigUDPHeader {args} {

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::ConfigUDPHeader..."
 
    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigUDPHeader API \nexit the proc of ConfigUDPHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist."
    } 
        
    #Parse sourcePort parameter
    set index [lsearch $args -sourceport] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-sourcePort" $sourcePort 
    } 

    #Parse destPort parameter
    set index [lsearch $args -destport] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPort" $destPort 
    }

    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-checksum" $checksum 
    }

    #Parse enableChecksum parameter
    set index [lsearch $args -enablechecksum] 
    if {$index != -1} {
        set enableChecksum [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-enableChecksum" $enableChecksum
    }

    #Parse length parameter
    set index [lsearch $args -length] 
    if {$index != -1} {
        set length [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-length" $length
    }

    #Parse lengthOverride parameter
    set index [lsearch $args -lengthoverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-lengthOverride" $lengthOverride 
    }

    #Parse enableChecksumOverride parameter
    set index [lsearch $args -enablechecksumoverride] 
    if {$index != -1} {
        set enableChecksumOverride [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-enableChecksumOverride" $enableChecksumOverride 
    } 

    #Parse checksumMode parameter
    set index [lsearch $args -checksummode] 
    if {$index != -1} {
        set checksumMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-checksumMode" $checksumMode 
    } 

    #Parse srcPortMode parameter
    set index [lsearch $args -srcportmode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcPortMode" $srcPortMode
    }

    #Parse srcStep parameter
    set index [lsearch $args -srcstep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcStep" $srcStep
    }

    #Parse srcPortStep parameter
    set index [lsearch $args -srcportstep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-srcStep" $srcStep
    }

    #Parse destPortMode parameter
    set index [lsearch $args -destportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPortMode" $destPortMode
    }

    #Parse dstPortMode parameter
    set index [lsearch $args -dstportmode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destPortMode" $destPortMode
    }

    #Parse destStep parameter
    set index [lsearch $args -deststep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destStep" $destStep
    }

    #Parse dstPortStep parameter
    set index [lsearch $args -dstportstep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-destStep" $destStep
    }

    #Parse numDest parameter
    set index [lsearch $args -numdest] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numDest" $numDest
    }

    #Parse dstPortCount parameter
    set index [lsearch $args -dstportcount] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numDest" $numDest
    }

    #Parse numSrc parameter
    set index [lsearch $args -numsrc] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numSrc" $numSrc
    }

    #Parse srcPortCount parameter
    set index [lsearch $args -srcportcount] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numSrc" $numSrc
    }

    ApplyPduConfigToStreams $PduName

    debugPut "exit the proc of HeaderCreator::ConfigUDPHeader..." 
    return $::mainDefine::gSuccess  
}

############################################################################
#APIName: CreaseMPLSHeader
#Description: Create MPLS header
#Input: 1. args:argument list, including
#              (1) -type type optional,MPLS type, mplsUnicast or mplsMulticast, i.e -type mplsUnicast
#              (2) -label label optional, MPLS label，i.e -label 0
#              (3) -LabelCount LabelCount optional, MPLS label count，i.e -LabelCount 1
#              (4) -LabelMode LabelMode optional, MPLS label change mode, fixed |increment | decrement，i.e -LabelMode fixed
#              (5) -LabelStep LabelStep optional, MPLS label step，i.e -LabelStep 1
#              (6) -Exp Exp optional，experience value，i.e  -Exp 0
#              (7) -TTL TTL optional，TTL value，i.e -TTL 0
#              (8) -bottomOfStack bottomOfStack optional，MPLS label stack，i.e -bottomOfStack 0
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateMPLSHeader {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateMPLSHeader..."

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateMPLSHeader API \nexit the proc of CreateMPLSHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateMPLSHeader..."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "MplsHeader"

    set PduConfigList ""    
    
    #Parse type parameter
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [expr $index + 1]]
    } else  {
        set type mplsUnicast
    }
    lappend PduConfigList -type
    lappend PduConfigList $type
    
    #Parse label parameter
    set index [lsearch $args -label] 
    if {$index != -1} {
        set label [lindex $args [expr $index + 1]]
    } else  {
        set label 0
    }
    lappend PduConfigList -label
    lappend PduConfigList $label

    #Parse labelCount parameter
    set index [lsearch $args -labelcount] 
    if {$index != -1} {
        set labelCount [lindex $args [expr $index + 1]]
    } else  {
        set labelCount 1
    }
    lappend PduConfigList -labelCount
    lappend PduConfigList $labelCount

    #Parse labelMode parameter
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        set labelMode [lindex $args [expr $index + 1]]
    } else  {
        set labelMode fixed
    }
    lappend PduConfigList -labelMode
    lappend PduConfigList $labelMode

    #Parse labelStep parameter
    set index [lsearch $args -labelstep] 
    if {$index != -1} {
        set labelStep [lindex $args [expr $index + 1]]
    } else  {
        set labelStep 1
    }
    lappend PduConfigList -labelStep
    lappend PduConfigList $labelStep
    
    #Parse exp parameter
    set index [lsearch $args -exp] 
    if {$index != -1} {
        set exp [lindex $args [expr $index + 1]]
    } else  {
        set exp 0
    }
    
    if {($exp >7) || ($exp <0) } {
        error "the experimentalUse value is invalid, please set another one.\nexit the proc of CreateMPLSHeader..."
    } elseif {$exp ==7 } {
        set exp 111
    } elseif {$exp ==6 } {
        set exp 110
    } elseif {$exp ==5 } {
        set exp 101
    } elseif {$exp ==4 } {
        set exp 100
    } elseif {$exp ==3 } {
        set exp 011
    } elseif {$exp ==2 } {
        set exp 010
    } elseif {$exp ==1 } {
        set exp 001
    } elseif {$exp ==0 } {
        set exp 000
    }
    lappend PduConfigList -exp
    lappend PduConfigList $exp
    
    #Parse TTL parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set TTL [lindex $args [expr $index + 1]]
    } else  {
        set TTL 0
    }
    lappend PduConfigList -TTL
    lappend PduConfigList $TTL
    
    #Parse bottomOfStack parameter
    set index [lsearch $args -bottomofstack] 
    if {$index != -1} {
        set bottomOfStack [lindex $args [expr $index + 1]]
    } else  {
        set bottomOfStack 0
    }
    lappend PduConfigList -bottomOfStack
    lappend PduConfigList $bottomOfStack
    
    lappend ::mainDefine::gPduConfigList "$PduConfigList"
    
    debugPut "exit the proc of HeaderCreator::CreateMPLSHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigMPLSHeader
#Description: Config MPLS header
#Input: 1. args:argument list, including
#              (1) -type type optional,MPLS type, mplsUnicast or mplsMulticast, i.e -type mplsUnicast
#              (2) -label label optional, MPLS label，i.e -label 0
#              (3) -LabelCount LabelCount optional, MPLS label count，i.e -LabelCount 1
#              (4) -LabelMode LabelMode optional, MPLS label change mode, fixed |increment | decrement，i.e -LabelMode fixed
#              (5) -LabelStep LabelStep optional, MPLS label step，i.e -LabelStep 1
#              (6) -Exp Exp optional，experience value，i.e  -Exp 0
#              (7) -TTL TTL optional，TTL value，i.e -TTL 0
#              (8) -bottomOfStack bottomOfStack optional，MPLS label stack，i.e -bottomOfStack 0
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigMPLSHeader {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::ConfigMPLSHeader..."

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigMPLSHeader API \nexit the proc of ConfigMPLSHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist \nexit the proc of ConfigMPLSHeader..."
    } 
        
    #Parse type parameter
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-type" $type
    } 

    #Parse label parameter
    set index [lsearch $args -label] 
    if {$index != -1} {
        set label [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-label" $label
    }

    #Parse labelCount parameter
    set index [lsearch $args -labelcount] 
    if {$index != -1} {
        set labelCount [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-labelCount" $labelCount
    }

    #Parse labelMode parameter
    set index [lsearch $args -labelmode] 
    if {$index != -1} {
        set labelMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-labelMode" $labelMode
    }

    #Parse labelStep parameter
    set index [lsearch $args -labelstep] 
    if {$index != -1} {
        set labelStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-labelStep" $labelStep
    }

    #Parse exp parameter
    set index [lsearch $args -exp] 
    if {$index != -1} {
        set exp [lindex $args [expr $index + 1]]
    
        if {($exp >7) || ($exp <0) } {
            error "the experimentalUse value is invalid, please set another one.\nexit the proc of ConfigMPLSHeader..."
        } elseif {$exp ==7 } {
            set exp 111
        } elseif {$exp ==6 } {
            set exp 110
        } elseif {$exp ==5 } {
            set exp 101
        } elseif {$exp ==4 } {
            set exp 100
        } elseif {$exp ==3 } {
            set exp 011
        } elseif {$exp ==2 } {
            set exp 010
        } elseif {$exp ==1 } {
            set exp 001
        } elseif {$exp ==0 } {
            set exp 000
        }

        ReplacePduAttrValue $PduName "-exp" $exp
   }
    
    #Parse TTL parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set TTL [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-TTL" $TTL
    }

    #Parse bottomOfStack parameter
    set index [lsearch $args -bottomofstack] 
    if {$index != -1} {
        set bottomOfStack [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-bottomOfStack" $bottomOfStack
    }

    ApplyPduConfigToStreams $PduName

    debugPut "exit the proc of HeaderCreator::ConfigMPLSHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: AddEthHeaderIntoStream
#Description: Add Eth header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddEthHeaderIntoStream {args hStream pduName} {

    set streamBlock1 $hStream               
    #Parse daRepeatCounter parameter    
    set index [lsearch $args -daRepeatCounter] 
    if {$index != -1} {
        set daRepeatCounter [lindex $args [expr $index + 1]]
        set m_dstEthMode $daRepeatCounter
    } 
    
    #Parse DA parameter
    set index [lsearch $args -DA] 
    if {$index != -1} {
        set DA [lindex $args [expr $index + 1]]
     } 
    
    #Parse numDA parameter
    set index [lsearch $args -numDA] 
    if {$index != -1} {
        set numDA [lindex $args [expr $index + 1]]
    } 

    #提取参数daList的值
    set index [lsearch $args -daList]
    if {$index!=-1} {
        set daList [lindex $args [expr $index + 1]]
    }
    
    #Parse daStep parameter
    set index [lsearch $args -daStep] 
    if {$index != -1} {
        set daStep [lindex $args [expr $index + 1]]
     } 
    
    #Parse saRepeatCounter parameter
    set index [lsearch $args -saRepeatCounter] 
    if {$index != -1} {
        set saRepeatCounter [lindex $args [expr $index + 1]]
    } 
    
    #Parse SA parameter
    set index [lsearch $args -SA] 
    if {$index != -1} {
        set SA [lindex $args [expr $index + 1]]
    } 
    
    #Parse numSA parameter
    set index [lsearch $args -numSA] 
    if {$index != -1} {
        set numSA [lindex $args [expr $index + 1]]
    } 

    #提取参数saList的值
    set index [lsearch $args -saList]
    if {$index!=-1} {
        set saList [lindex $args [expr $index + 1]]
    }
    
    #Parse saStep parameter
    set index [lsearch $args -saStep] 
    if {$index != -1} {
        set saStep [lindex $args [expr $index + 1]]
    } 

    #Parse EthType parameter
    set index [lsearch $args -EthType] 
    if {$index != -1} {
        set EthType [lindex $args [expr $index + 1]]
    } 
   
    #Parse EthTypeMode parameter
    set index [lsearch $args -EthTypeMode] 
    if {$index != -1} {
        set EthTypeMode [lindex $args [expr $index + 1]]
    } 

    #Parse EthTypeStep parameter
    set index [lsearch $args -EthTypeStep] 
    if {$index != -1} {
        set EthTypeStep [lindex $args [expr $index + 1]]
    } 

    #Parse EthTypeCount parameter
    set index [lsearch $args -EthTypeCount] 
    if {$index != -1} {
        set EthTypeCount [lindex $args [expr $index + 1]]
    } 
   
    #Create Ether header, and config parameters
    set Ether1 [stc::create ethernet:EthernetII -under $streamBlock1]
    set m_PriorEthHandle $Ether1
 
    #Store eth header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $Ether1

    set eth_h1 [stc::get $Ether1 -Name]
    stc::config $Ether1 -dstMac $DA -srcMac $SA

    set DestinationPort $::mainDefine::gBoundStreamDstPort($m_streamName) 
    #Support BoundStream type
    if {$DestinationPort != "" } {
          set ::mainDefine::objectName $m_portName 
         set ::mainDefine::streamBlock $streamBlock1
         set ::mainDefine::streamName $m_streamName
         set ::mainDefine::DestinationPort $DestinationPort
         uplevel 1 {
             uplevel 1 {
                 $::mainDefine::objectName BindHostsToStream $::mainDefine::streamBlock $::mainDefine::streamName $::mainDefine::DestinationPort  
             }
        } 
    }

    if {[string tolower $daRepeatCounter] =="incr" || [string tolower $daRepeatCounter] =="increment" } {
        set ethModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $DA \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
            -Offset 0 -ModifierMode INCR -RecycleCount $numDA -StepValue $daStep -RepeatCount 0]

         set m_destModifierList($pduName) $ethModifier1        
    } elseif {[string tolower $daRepeatCounter] =="decr" ||  [string tolower $daRepeatCounter] =="decrement"} {
        set ethModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $DA \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
            -Offset 0 -ModifierMode DECR -RecycleCount $numDA -StepValue $daStep -RepeatCount 0]

         set m_destModifierList($pduName) $ethModifier1
    } elseif {[string tolower $daRepeatCounter] =="rand" || [string tolower $daRepeatCounter] =="random"} {
        set ethModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.dstMac \
            -Offset 0 -RecycleCount $numDA -RepeatCount 0]

        set m_destModifierList($pduName) $ethModifier1  
    } elseif {[string tolower $daRepeatCounter] =="list" } {
        set dadataList "00:10:94:00:00:01"
        if {$daList != "NULL"} {
             set dadataList $daList
        }
        set ethModifier1 [stc::create TableModifier -under $streamBlock1 -EnableStream $m_EnableStream \
            -OffsetReference $eth_h1.dstMac -Offset 0 -Data $dadataList  -RepeatCount 0]

        set m_destModifierList($pduName) $ethModifier1  
    }

    if {[string tolower $saRepeatCounter] =="incr" || [string tolower $saRepeatCounter] =="increment"} {
        set ethModifier2 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $SA \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
            -Offset 0 -ModifierMode INCR -RecycleCount $numSA -StepValue $saStep -RepeatCount 0]

        set m_srcModifierList($pduName) $ethModifier2
    } elseif {[string tolower $saRepeatCounter] =="decr" || [string tolower $saRepeatCounter] =="decrement"} {
        set ethModifier2 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $SA \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
            -Offset 0 -ModifierMode DECR -RecycleCount $numSA -StepValue $daStep -RepeatCount 0]  

        set m_srcModifierList($pduName) $ethModifier2
    } elseif {[string tolower $saRepeatCounter] =="rand" || [string tolower $saRepeatCounter] =="random"} {
        set ethModifier2 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
            -Mask "00:00:FF:FF:FF:FF" -OffsetReference $eth_h1.srcMac \
            -Offset 0 -RecycleCount $numSA -RepeatCount 0]   
        set m_srcModifierList($pduName) $ethModifier2
    } elseif {[string tolower $saRepeatCounter] =="list" } {
        set sadataList "00:10:94:00:00:01"
        if {$saList != "NULL"} {
             set sadataList $saList
        }
        set ethModifier1 [stc::create TableModifier -under $streamBlock1 -EnableStream $m_EnableStream \
            -OffsetReference $eth_h1.srcMac -Offset 0 -Data $sadataList -RepeatCount 0]

        set m_destModifierList($pduName) $ethModifier1  
    } 

    #增加对于EthType以及相关参数的支持 
    if {[info exists EthType]} { 
        if {[string tolower $EthType] != "auto"} {
            stc::config $Ether1 -etherType $EthType 
        }
    }    
       
    if {[string tolower $EthTypeMode] == "increment"} {
        set ModifierMode "INCR"
    } elseif {[string tolower $EthTypeMode] == "decrement"} {
        set ModifierMode "DECR"
    } else {
        set ModifierMode "FIXED"
    } 
       
    if {$ModifierMode == "INCR" || $ModifierMode == "DECR" } {
        set myEthType [stc::get $Ether1 -etherType]
        set ethTypeModifier [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $myEthType \
                -Mask "FFFF" -OffsetReference $eth_h1.etherType \
                -Offset 0 -ModifierMode $ModifierMode -RecycleCount $EthTypeCount -StepValue $EthTypeStep -RepeatCount 0]
        set m_typeModifierList($pduName) $ethTypeModifier
    }   
}

############################################################################
#APIName: AddVlanHeaderIntoStream
#Description: Add Vlan header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddVlanHeaderIntoStream {args hStream pduName} {
    
    set streamBlock1 $hStream
    #Parse vlanID parameter
    set index [lsearch $args -vlanID] 
    if {$index != -1} {
        set vlanID [lindex $args [expr $index + 1]]
    } 
    
    #Parse userPriority parameter
    set index [lsearch $args -userPriority] 
    if {$index != -1} {
        set userPriority [lindex $args [expr $index + 1]]
    } 
    
    #Parse cfi parameter
    set index [lsearch $args -cfi] 
    if {$index != -1} {
        set cfi [lindex $args [expr $index + 1]]
    } 
    
    #Parse mode parameter
    set index [lsearch $args -mode] 
    if {$index != -1} {
        set mode [lindex $args [expr $index + 1]]
    } 
    
    #Parse repeat parameter
    set index [lsearch $args -repeat] 
    if {$index != -1} {
        set repeat [lindex $args [expr $index + 1]]
    } 
    
    #Parse step parameter
    set index [lsearch $args -step] 
    if {$index != -1} {
        set step [lindex $args [expr $index + 1]]
    } 
    
    #Parse maskval parameter
    set index [lsearch $args -maskval] 
    if {$index != -1} {
        set maskval [lindex $args [expr $index + 1]]
    } 
    
    #Parse protocolTagId parameter
    set index [lsearch $args -protocolTagId] 
    if {$index != -1} {
        set protocolTagId [lindex $args [expr $index + 1]]
    } 
    
    #Parse Vlanstack parameter
    set index [lsearch $args -Vlanstack] 
    if {$index != -1} {
        set Vlanstack [lindex $args [expr $index + 1]]
    } 
    
    #Parse Stack parameter
    set index [lsearch $args -Stack] 
    if {$index != -1} {
        set Stack [lindex $args [expr $index + 1]]
    } 

    if {[string tolower $Vlanstack] == "single"}  {    
        #Create VLAN header, and configure parameters
        set Ether1 [stc::get $streamBlock1 -children-ethernet:EthernetII ]
        if {[llength $Ether1] != 1} {
           set Ether1 $m_PriorEthHandle
        }

        set vlans1 [stc::get $Ether1 -Children-vlans]
        if {$vlans1 == ""} {  
            set vlans1 [stc::create vlans -under $Ether1]
        } 

        set Ethername [stc::get $Ether1 -Name]
        set vlan1 [stc::get $vlans1 -Children-vlan]
        if {$vlan1 == ""} {
            set vlan1 [stc::create vlan -under $vlans1 ]
        }
        #Store header handle
        lappend m_PduNameList $pduName

        set m_PduHandleList($pduName) $vlan1

        set vlan_1 [stc::get $vlan1 -Name]
        set binUserPriority [dec2bin $userPriority 2 3]
        stc::config $vlan1 -id $vlanID -cfi $cfi -pri $binUserPriority
     
        set hex_type [ConvertHexFormat $protocolTagId]
        stc::config $vlan1 -type $hex_type
        #stc::config $Ether1 -etherType $hex_type

        #Create VlanID range modifier
        if {[string tolower $mode] =="incr" || [string tolower $mode] =="increment" } {
             set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $vlanID \
                -Mask $maskval -OffsetReference $Ethername.vlans.$vlan_1.id \
                -Offset 0 -ModifierMode INCR -RecycleCount $repeat -StepValue $step -RepeatCount 0]
             set m_srcModifierList($pduName) $VlanModifier1
        } elseif {[string tolower $mode] =="decr" || [string tolower $mode] =="decrement"} {
             set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $vlanID  \
                 -Mask $maskval -OffsetReference $Ethername.vlans.$vlan_1.id \
                 -Offset 0 -ModifierMode DECR -RecycleCount $repeat -StepValue $step -RepeatCount 0]     
              set m_srcModifierList($pduName) $VlanModifier1
        } elseif {[string tolower $mode] =="rand" || [string tolower $mode] =="random"} {
              set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                 -Mask $maskval -OffsetReference $Ethername.vlans.$vlan_1.id \
                 -Offset 0 -RecycleCount $repeat -RepeatCount 0]     
               set m_srcModifierList($pduName) $VlanModifier1
       }
   } else  {

       #Create VLAN header, and configure parameters
       set Ether1 [stc::get $streamBlock1 -children-ethernet:EthernetII ]
       if {[llength $Ether1] != 1} {
           set Ether1 $m_PriorEthHandle
       }

       set vlans1 ""
       if {$Stack == 1} {
           set vlans1 [stc::get $Ether1 -Children-vlans]
           if {$vlans1 == ""} {  
               set vlans1 [stc::create vlans -under $Ether1]
           }
       } else {
           set vlans1 [stc::get $Ether1 -children-vlans ]
       } 

       if {$vlans1 == ""}  {
            error "please create VLAN header using the Stack value equals to 1 first ..."
       }

       set Ethername [stc::get $Ether1 -Name]
     
       set vlan1 [stc::create vlan -under $vlans1 -Name vlan_$Stack]
       #Store header handle
       lappend m_PduNameList $pduName
       set m_PduHandleList($pduName) $vlan1

       set binUserPriority [dec2bin $userPriority 2 3]
       stc::config $vlan1 -id $vlanID -cfi $cfi -pri $binUserPriority

       set hex_type [ConvertHexFormat $protocolTagId]
       stc::config $vlan1 -type $hex_type
       #stc::config $Ether1 -etherType $hex_type
 
       #Create VlanID range modifier
       if {[string tolower $mode] =="incr" || [string tolower $mode] =="increment"} {
           set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $vlanID \
                     -Mask $maskval -OffsetReference $Ethername.vlans.vlan_$Stack.id \
                     -Offset 0 -ModifierMode INCR -RecycleCount $repeat -StepValue $step -RepeatCount 0]
            set m_srcModifierList($pduName) $VlanModifier1
       } elseif {[string tolower $mode] =="decr" || [string tolower $mode] =="decrement"} {
            set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $vlanID \
                     -Mask $maskval -OffsetReference $Ethername.vlans.vlan_$Stack.id \
                     -Offset 0 -ModifierMode DECR -RecycleCount $repeat -StepValue $step -RepeatCount 0]     
            set m_srcModifierList($pduName) $VlanModifier1
       } elseif {[string tolower $mode] =="rand" || [string tolower $mode] =="random"} {
            set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                     -Mask $maskval -OffsetReference $Ethername.vlans.vlan_$Stack.id \
                    -Offset 0 -RecycleCount $repeat -RepeatCount 0]  
           set m_srcModifierList($pduName) $VlanModifier1   
       }  
     }
}
proc Num2Ip {num} {
    set byte0 [expr $num & 0xff]
    set byte1 [expr ($num >> 8) & 0xff]
    set byte2 [expr ($num >> 16) & 0xff]
    set byte3 [expr ($num >> 24) & 0xff]
    return $byte3.$byte2.$byte1.$byte0
}
proc Ip2Num {ip} {
    set list [split $ip .]
    set byte0 [lindex $list 3]
    set byte1 [lindex $list 2]
    set byte2 [lindex $list 1]
    set byte3 [lindex $list 0]
    set sum 0
    
    set sum [expr $sum + $byte0]
    set sum [expr $sum + ($byte1 << 8)]
    set sum [expr $sum + ($byte2 << 16)]
    set sum [expr $sum + ($byte3 << 24)]
    
    return $sum
}

proc Num2Ipv6 {num} {
    set value0 [expr $num & 0xffff]
    set value1 [expr ($num >> 16) & 0xffff]
    
    return ::[format "%0.4x" $value1]:[format "%x" $value0]
}

############################################################################
#APIName: AddIPv4HeaderIntoStream
#Description: Add IPv4 header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddIPv4HeaderIntoStream {args hStream pduName} {       
    
    set streamBlock1 $hStream
    #Parse precedence parameter
    set index [lsearch $args -precedence] 
    if {$index != -1} {
        set precedence [lindex $args [expr $index + 1]]
    } 
    #Parse delay parameter
    set index [lsearch $args -delay] 
    if {$index != -1} {
        set delay [lindex $args [expr $index + 1]]
    } 
    #Parse throughput parameter
    set index [lsearch $args -throughput] 
    if {$index != -1} {
        set throughput [lindex $args [expr $index + 1]]
    } 
    
    #Parse reliability parameter
    set index [lsearch $args -reliability] 
    if {$index != -1} {
        set reliability [lindex $args [expr $index + 1]]
    } 
    
    #Parse identifier parameter
    set index [lsearch $args -identifier] 
    if {$index != -1} {
        set identifier [lindex $args [expr $index + 1]]
    } 
    
    ##Parse cost parameter
    set index [lsearch $args -cost] 
    if {$index != -1} {
        set cost [lindex $args [expr $index + 1]]
    } 
    #
    ##Parse reserved parameter
    #set index [lsearch $args -reserved] 
    #if {$index != -1} {
    #    set reserved [lindex $args [expr $index + 1]]
    #} 
    
    #Parse totalLength parameter
    set index [lsearch $args -totalLength] 
    if {$index != -1} {
        set totalLength [lindex $args [expr $index + 1]]
    } 
    
    #Parse lengthOverride parameter     
    set index [lsearch $args -lengthOverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
    }
    
    #Parse fragment parameter
    set index [lsearch $args -fragment] 
    if {$index != -1} {
        set fragment [lindex $args [expr $index + 1]]
    }  
    
    #Parse lastFragment parameter
    set index [lsearch $args -lastFragment] 
    if {$index != -1} {
        set lastFragment [lindex $args [expr $index + 1]]
    } 
    
    #Parse fragmentOffset parameter
    set index [lsearch $args -fragmentOffset] 
    if {$index != -1} {
        set fragmentOffset [lindex $args [expr $index + 1]]
    } 
    
    #Parse ttl parameter
    set index [lsearch $args -ttl] 
    if {$index != -1} {
        set ttl [lindex $args [expr $index + 1]]
    } 
    
    #Parse ipProtocol parameter
    set index [lsearch $args -ipProtocol] 
    if {$index != -1} {
        set ipProtocol [lindex $args [expr $index + 1]]
    } 
    
    #Parse ipProtocolMode parameter
    set index [lsearch $args -ipProtocolMode] 
    if {$index != -1} {
        set ipProtocolMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse ipProtocolStep parameter
    set index [lsearch $args -ipProtocolStep] 
    if {$index != -1} {
        set ipProtocolStep [lindex $args [expr $index + 1]]
    }

    #Parse ipProtocolCount parameter
    set index [lsearch $args -ipProtocolCount] 
    if {$index != -1} {
        set ipProtocolCount [lindex $args [expr $index + 1]]
    }

    #Parse useValidChecksum parameter
    set index [lsearch $args -useValidChecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
    } 
    
    #Parse sourceIpAddr parameter
    set index [lsearch $args -sourceIpAddr] 
    if {$index != -1} {
        set sourceIpAddr [lindex $args [expr $index + 1]]
    } 
    
    #Parse sourceIpMask parameter
    set index [lsearch $args -sourceIpMask] 
    if {$index != -1} {
        set sourceIpMask [lindex $args [expr $index + 1]]
    } 
    
    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceIpAddrMode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
    }
    
    #Parse sourceIpAddrRepeatCount parameter
    set index [lsearch $args -sourceIpAddrRepeatCount] 
    if {$index != -1} {
        set sourceIpAddrRepeatCount [lindex $args [expr $index + 1]]
    }
    
    #Parse sourceClass parameter
    set index [lsearch $args -sourceClass] 
    if {$index != -1} {
        set sourceClass [lindex $args [expr $index + 1]]
    } 
    
    ##Parse enableSourceSyncFromPpp parameter 
    #set index [lsearch $args -enableSourceSyncFromPpp] 
    #if {$index != -1} {
    #    set enableSourceSyncFromPpp [lindex $args [expr $index + 1]]
    #}
    
    #Parse destIpAddr parameter 
    set index [lsearch $args -destIpAddr] 
    if {$index != -1} {
        set destIpAddr [lindex $args [expr $index + 1]]
    }
    
    #Parse destIpMask parameter 
    set index [lsearch $args -destIpMask] 
    if {$index != -1} {
        set destIpMask [lindex $args [expr $index + 1]]
    } 
    
    #Parse destIpAddrMode parameter
    set index [lsearch $args -destIpAddrMode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
    }
    
    #Parse destIpAddrRepeatCount parameter
    set index [lsearch $args -destIpAddrRepeatCount] 
    if {$index != -1} {
        set destIpAddrRepeatCount [lindex $args [expr $index + 1]]
    } 
    
    #Parse destClass parameter
    set index [lsearch $args -destClass] 
    if {$index != -1} {
        set destClass [lindex $args [expr $index + 1]]
    }  

    ##Parse destMacAddr parameter
    #set index [lsearch $args -destMacAddr] 
    #if {$index != -1} {
    #    set destMacAddr [lindex $args [expr $index + 1]]
    #}
    #
    #Parse destDutIpAddr parameter
    set index [lsearch $args -destDutIpAddr] 
    if {$index != -1} {
        set destDutIpAddr [lindex $args [expr $index + 1]]
    } 
    
    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
    }
    
    ##Parse enableDestSyncFromPpp parameter
    #set index [lsearch $args -enableDestSyncFromPpp] 
    #if {$index != -1} {
    #    set enableDestSyncFromPpp [lindex $args [expr $index + 1]]
    #} 
    
    #Parse qosMode parameter
    set index [lsearch $args -qosMode] 
    if {$index != -1} {
        set qosMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse qosValue parameter
    set index [lsearch $args -qosValue] 
    if {$index != -1} {
        set qosValue [lindex $args [expr $index + 1]]
    } 

    #Parse qosValueExist parameter
    set qosValueExist "FALSE"
    set index [lsearch $args -qosValueExist] 
    if {$index != -1} {
        set qosValueExist [lindex $args [expr $index + 1]]
    } 

    #dscpMode and dscpValue are kept for compatibility
    ##############################################
    #Parse dscpMode parameter
    set index [lsearch $args -dscpMode] 
    if {$index != -1} {
        set dscpMode [lindex $args [expr $index + 1]]
    }
    
    #Parse dscpValue parameter
    set index [lsearch $args -dscpValue] 
    if {$index != -1} {
        set dscpValue [lindex $args [expr $index + 1]]
    }  
    ##############################################

    #Parse sourceIpAddrMode parameter
    set index [lsearch $args -sourceIpAddrMode] 
    if {$index != -1} {
        set sourceIpAddrMode [lindex $args [expr $index + 1]]
    }

    #Parse destIpAddrMode parameter
    set index [lsearch $args -destIpAddrMode] 
    if {$index != -1} {
        set destIpAddrMode [lindex $args [expr $index + 1]]
    }

    #Parse sourceIpAddrRepeatStep parameter
    set index [lsearch $args -sourceIpAddrRepeatStep] 
    if {$index != -1} {
        set sourceIpAddrRepeatStep [lindex $args [expr $index + 1]]
    }

    #Parse destIpAddrRepeatStep parameter
    set index [lsearch $args -destIpAddrRepeatStep] 
    if {$index != -1} {
        set destIpAddrRepeatStep [lindex $args [expr $index + 1]]
    }

    #Parse SrcDataList parameter
    set index [lsearch $args -srcDataList] 
    if {$index != -1} {
        set srcDataList [lindex $args [expr $index + 1]]
    }

    #Parse DestDataList parameter
    set index [lsearch $args -destDataList] 
    if {$index != -1} {
        set destDataList [lindex $args [expr $index + 1]]
    } 

    #Add the support of MplsVPN bounding
    if {[string tolower $m_streamType ] == "vpn"} {
         if {[info exists ::mainDefine::gIpv4NetworkBlock($sourceIpAddr)]} {
             catch {
                  set hSrcIpv4NetworkBlock $::mainDefine::gIpv4NetworkBlock($sourceIpAddr)
                  stc::config $streamBlock1 -SrcBinding-targets " $hSrcIpv4NetworkBlock "
                  set sourceIpAddr [stc::get $hSrcIpv4NetworkBlock -StartIpList]
             }
         }

         if {[info exists ::mainDefine::gIpv4NetworkBlock($destIpAddr)]} {
             catch {
                  set hDstIpv4NetworkBlock $::mainDefine::gIpv4NetworkBlock($destIpAddr)
                  stc::config $streamBlock1 -DstBinding-targets " $hDstIpv4NetworkBlock "
                  set destIpAddr [stc::get $hDstIpv4NetworkBlock -StartIpList]
             }
         }
    }

    #Create IPv4 header, and configure parameters
    set ipv41 [stc::create ipv4:IPv4 -under $streamBlock1 ]

    #Store header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $ipv41

    set ip1 [stc::get $ipv41 -Name]
    stc::config $ipv41 -sourceAddr $sourceIpAddr -destAddr $destIpAddr -Gateway $destDutIpAddr
    set tosDiffserv1 [stc::create tosDiffserv -under $ipv41]
    
    if {[string tolower $qosMode]== "tos"} {
        set tos1 [stc::create tos -under $tosDiffserv1]
        #puts "====tos"
        if {$qosValueExist == "FALSE"} {
            if {[string tolower $precedence] =="priority" ||[string tolower $precedence] =="1"} {
                stc::config $tos1 -precedence 1
                #puts "tos: priority"
            } elseif {[string tolower $precedence] =="immediate" ||[string tolower $precedence] =="2"} {
                stc::config $tos1 -precedence 2
                #puts "tos: immediate"
            } elseif {[string tolower $precedence] =="flash" ||[string tolower $precedence] =="3"} {
                stc::config $tos1 -precedence 3
                #puts "tos: flash"
            } elseif {[string tolower $precedence] =="flash_override" ||[string tolower $precedence] =="4"} {
                stc::config $tos1 -precedence 4
                #puts "tos: flash_override"
            } elseif {[string tolower $precedence] =="critical" ||[string tolower $precedence] =="5"} {
                stc::config $tos1 -precedence 5
                #puts "tos: critical"
            } elseif {[string tolower $precedence] =="internetwork_control" ||[string tolower $precedence] =="6"} {
                stc::config $tos1 -precedence 6
                #puts "tos: internetwork_control"
            } elseif {[string tolower $precedence] =="network_control" ||[string tolower $precedence] =="7"} {
                stc::config $tos1 -precedence 7
                #puts "tos: network_control"
            } else {
                stc::config $tos1 -precedence 0
                #puts "tos: default"
            } 
            if {[string tolower $delay] =="minimumdelay" || [string tolower $delay] == "lowdelay"} {
                stc::config $tos1 -dBit 1
                #puts "tos: minimumdelay"
            } else {
                stc::config $tos1 -dBit 0
           }
            if {[string tolower $throughput] =="maximumthruput" || [string tolower $throughput] == "highthruput"} {
                stc::config $tos1 -tBit 1
                #puts "tos: maximumthruput"
            } else {
                stc::config $tos1 -tBit  0
            } 
            
            if {[string tolower $reliability] =="maximumreliability" || [string tolower $reliability] =="highreliability"} {
                stc::config $tos1 -rBit 1
                #puts "tos: maximumreliability"
            } else {
                stc::config $tos1 -rBit 0
            }

            if {[string tolower $cost] =="minimumcost" || [string tolower $cost] =="lowcost"} {
                stc::config $tos1 -mBit 1
                #puts "tos: minimumdelay"
            } else {
                stc::config $tos1 -mBit 0
            }
        } else {
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
        }
        
    } elseif {[string tolower $qosMode]== "dscp" } {
        set diffServ1 [stc::create diffServ -under $tosDiffserv1]
     
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

    set flag1 [stc::create flags -under $ipv41]    
    if {[string tolower $fragment] == "may"} {
        stc::config $flag1 -dfBit 0 
    } else {
        stc::config $flag1 -dfBit 1
    }    
    if {[string tolower $lastFragment] == "last"} {
        stc::config $flag1 -mfBit 0 
    } else {
        stc::config $flag1 -mfBit 1
    }
    stc::config $ipv41 -identification $identifier -ttl $ttl -fragOffset $fragmentOffset
    if {[string tolower $lengthOverride] == "true"} {
        stc::config $ipv41 -totalLength $totalLength
    }

    if {($sourceIpAddrMode == "ipIncrHost") ||($sourceIpAddrMode == "ipDecrHost")} {
        set srcStep [Num2Ip $sourceIpAddrRepeatStep]
    }

    if {($destIpAddrMode == "ipIncrHost") ||($destIpAddrMode == "ipDecrHost")} {
        set dstStep [Num2Ip $destIpAddrRepeatStep]
    }

    if {($sourceIpAddrMode == "ipIncrSubnet") ||($sourceIpAddrMode == "ipDecrSubnet")} {
       set num [Ip2Num $sourceIpMask]
       set num [expr $num * $sourceIpAddrRepeatStep]
        set srcStep [Num2Ip $num]
    }

    if {($destIpAddrMode == "ipIncrSubnet") ||($destIpAddrMode == "ipDecrSubnet")} {
       set num [Ip2Num $destIpMask]
       set num [expr $num * $destIpAddrRepeatStep]
        set dstStep [Num2Ip $num]
    }
    
    if {([string tolower $sourceIpAddrMode] == "increment") || ([string tolower $sourceIpAddrMode] == "decrement")} {
        set ret [lsearch $sourceIpAddrRepeatStep "."]
        if {$ret == -1} {
            set srcStep [Num2Ip $sourceIpAddrRepeatStep]
        } else {
            set srcStep $sourceIpAddrRepeatStep
        }   
    }

    if {([string tolower $destIpAddrMode] == "increment") || ([string tolower $destIpAddrMode] == "decrement")} {
         set ret [lsearch $destIpAddrRepeatStep "."]
         if {$ret == -1} {
            set dstStep [Num2Ip $destIpAddrRepeatStep]
         } else {
            set  dstStep $destIpAddrRepeatStep 
         }  
    }

    #Create IPv4 range modifier
    if {([string tolower $sourceIpAddrMode] == "ipincrhost") || ([string tolower $sourceIpAddrMode] == "increment")} {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceIpAddr \
            -Mask "255.255.255.255" -OffsetReference $ip1.sourceAddr -StepValue $srcStep \
            -Offset 0 -ModifierMode INCR -RecycleCount $sourceIpAddrRepeatCount -RepeatCount 0]    
        set m_srcModifierList($pduName) $IPModifier1
    } elseif {([string tolower $sourceIpAddrMode] == "ipdecrhost") || ([string tolower $sourceIpAddrMode] == "decrement")} {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.sourceAddr -StepValue $srcStep \
            -Offset 0 -ModifierMode DECR -RecycleCount $sourceIpAddrRepeatCount -RepeatCount 0]
        set m_srcModifierList($pduName) $IPModifier1
    } elseif {[string tolower $sourceIpAddrMode] =="iprand" || [string tolower $sourceIpAddrMode] =="random"} {
        set IPModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
            -Mask "255.255.255.255" -OffsetReference $ip1.sourceAddr  \
            -Offset 0 -RecycleCount $sourceIpAddrRepeatCount -RepeatCount 0]   
              set m_srcModifierList($pduName) $IPModifier1
    } elseif {[string tolower $sourceIpAddrMode] =="list"} {
        set dataList "1.1.1.1"
        if {$srcDataList != "NULL"} {
             set dataList $srcDataList
        }
             
        set IPModifier1 [stc::create TableModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                  -OffsetReference $ip1.sourceAddr -Offset 0 -Data $dataList -RepeatCount 0]   
        set m_srcModifierList($pduName) $IPModifier1
    }
                     
    if {([string tolower $destIpAddrMode] == "ipincrhost") || ([string tolower $destIpAddrMode] == "increment") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.destAddr -StepValue $dstStep \
            -Offset 0 -ModifierMode INCR -RecycleCount $destIpAddrRepeatCount -RepeatCount 0]    
        set m_destModifierList($pduName) $IPModifier1
    } elseif {([string tolower $destIpAddrMode] == "ipdecrhost") || ([string tolower $destIpAddrMode] == "decrement")} {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.destAddr -StepValue $dstStep \
            -Offset 0 -ModifierMode DECR -RecycleCount $destIpAddrRepeatCount -RepeatCount 0]
        set m_destModifierList($pduName) $IPModifier1
    } elseif {[string tolower $destIpAddrMode] =="iprand" || ([string tolower $destIpAddrMode] == "random")} {
        set IPModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
            -Mask "255.255.255.255" -OffsetReference $ip1.destAddr  \
            -Offset 0 -RecycleCount $destIpAddrRepeatCount -RepeatCount 0] 
        set m_destModifierList($pduName) $IPModifier1
    } elseif {[string tolower $destIpAddrMode] =="list"} {
        set dataList "1.1.1.1"
        if {$destDataList != "NULL"} {
             set dataList $destDataList
        }

        set IPModifier1 [stc::create TableModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                 -OffsetReference $ip1.destAddr -Offset 0 -Data $dataList -RepeatCount 0] 
        set m_destModifierList($pduName) $IPModifier1
    }

    if {([string tolower $sourceIpAddrMode] == "ipdecrsubnet") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceIpAddr \
            -Mask "255.255.255.255" -OffsetReference $ip1.sourceAddr -StepValue $srcStep \
            -Offset 0 -ModifierMode INCR -RecycleCount $sourceIpAddrRepeatCount -RepeatCount 0]    
        set m_srcModifierList($pduName) $IPModifier1
    } elseif {([string tolower $sourceIpAddrMode] == "ipincrsubnet") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.sourceAddr -StepValue $srcStep \
            -Offset 0 -ModifierMode DECR -RecycleCount $sourceIpAddrRepeatCount -RepeatCount 0]
        set m_srcModifierList($pduName) $IPModifier1
    } 

    if {([string tolower $destIpAddrMode] == "ipdecrsubnet") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.destAddr -StepValue $dstStep \
            -Offset 0 -ModifierMode INCR -RecycleCount $destIpAddrRepeatCount -RepeatCount 0] 
        set m_destModifierList($pduName) $IPModifier1   
    } elseif {([string tolower $destIpAddrMode] == "ipincrsubnet")} {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destIpAddr \
            -Mask "255.255.255.255"  -OffsetReference $ip1.destAddr -StepValue $dstStep \
            -Offset 0 -ModifierMode DECR -RecycleCount $destIpAddrRepeatCount -RepeatCount 0]
         set m_destModifierList($pduName) $IPModifier1
    }        
    stc::config $ipv41 -protocol $ipProtocol

    #Set IpPrptocol modifier field
    if {[string tolower $ipProtocolMode] == "increment"} {
        set ModifierMode "INCR"
    } elseif {[string tolower $ipProtocolMode] == "decrement"} {
        set ModifierMode "DECR"
    } else {
        set ModifierMode "FIXED"
    } 
       
    if {$ModifierMode == "INCR" || $ModifierMode == "DECR" } {
        set ipv4TypeModifier [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $ipProtocol \
                -Mask 255 -OffsetReference $ip1.protocol \
                -Offset 0 -ModifierMode $ModifierMode -RecycleCount $ipProtocolCount -StepValue $ipProtocolStep -RepeatCount 0]
        set m_typeModifierList($pduName) $ipv4TypeModifier
    }
 
    catch {
        if {$m_portType == "ethernet" && [string tolower $m_EthType] == "auto"} {
            set Ether1 [lindex [stc::get $streamBlock1 -children-ethernet:EthernetII] 0]
            if {$m_mplsType == "mplsunicast"} {
                stc::config $Ether1 -etherType "8847"
            } elseif {$m_mplsType == "mplsmulticast"} {
                stc::config $Ether1 -etherType "8848"
            } elseif {$m_mplsType == "pppoesession"} {
                stc::config $Ether1 -etherType "8864"
            } else {
                stc::config $Ether1 -etherType "0800"
            }
        }
    }

    if {[string tolower $m_dstEthMode] == "autoarp"} {
        set hostHandleList [stc::get $m_hPort -AffiliatedPortSource]
        set hostHandle [lindex $hostHandleList 0]
        if {$hostHandle != ""} { 
            set ipv4If [stc::get $hostHandle -TopLevelIf]
            if {$ipv4If != ""} {
                set gatewayIp [stc::get $ipv4If -Gateway]
                debugPut "The gateway address of Host: $hostHandle is $gatewayIp"
               
                stc::config $ipv41 -Gateway $gatewayIp  
                set ::mainDefine::gStreamBindingFlag "TRUE"
            }
        }
   }
} 

############################################################################
#APIName: AddIPv6HeaderIntoStream
#Description: Add IPv6 header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddIPv6HeaderIntoStream {args hStream pduName} { 
    debugPut "enter the proc of AddIPv6HeaderIntoStream"
    
    set streamBlock1 $hStream
    #Parse precedence parameter
    set ipv6Config ""
    set ipv61 [stc::create ipv6:IPv6 -under $hStream] 
    set index [lsearch $args -destinationaddress] 
    if {$index != -1} {
        set destAddr [lindex $args [expr $index + 1]]
        stc::config $ipv61 -destAddr $destAddr
        lappend ipv6Config -destAddr
        lappend ipv6Config $destAddr
    }
    
    #addedy by WangKaichuang -20120214
    #Parse destDutIpAddr parameter
    set index [lsearch $args -destdutipaddr] 
    if {$index != -1} {
        set destDutIpAddr [lindex $args [expr $index + 1]]
        stc::config $ipv61 -Gateway $destDutIpAddr
        lappend ipv6Config -Gateway
        lappend ipv6Config $destDutIpAddr
    } 
    #addedy by WangKaichuang -20120214
    
    set index [lsearch $args -flowlabel] 
    if {$index != -1} {
        set flowLabel [lindex $args [expr $index + 1]]
        stc::config $ipv61 -flowLabel $flowLabel
        lappend ipv6Config -flowLabel
        lappend ipv6Config $flowLabel
    } 

    set index [lsearch $args -nextheader] 
    if {$index != -1} {
        set nextHeader [lindex $args [expr $index + 1]]
        stc::config $ipv61 -nextHeader $nextHeader
        lappend ipv6Config -nextHeader
        lappend ipv6Config $nextHeader
    } 

    set index [lsearch $args -payloadlen] 
    if {$index != -1} {
        set payloadLength [lindex $args [expr $index + 1]]
        stc::config $ipv61 -payloadLength $payloadLength
        lappend ipv6Config -payloadLength
        lappend ipv6Config $payloadLength
    } 

    set index [lsearch $args -sourceaddress] 
    if {$index == -1} {
        set index [lsearch $args -sourceaddres] 
    }

    if {$index != -1} {
        set sourceAddr [lindex $args [expr $index + 1]]
        stc::config $ipv61 -sourceAddr $sourceAddr
        lappend ipv6Config -sourceAddr
        lappend ipv6Config $sourceAddr
    } 

    set index [lsearch $args -hoplimit] 
    if {$index != -1} {
        set hopLimit [lindex $args [expr $index + 1]]
        stc::config $ipv61 -hopLimit $hopLimit
        lappend ipv6Config -hopLimit
        lappend ipv6Config $hopLimit
    }

    set index [lsearch $args -trafficclass] 
    if {$index != -1} {
        set trafficClass [lindex $args [expr $index + 1]]
        stc::config $ipv61 -trafficClass $trafficClass
        lappend ipv6Config -trafficClass
        lappend ipv6Config $trafficClass
    } 
    
    set ip1 [stc::get $ipv61 -Name]
    
    set index [lsearch $args -destaddressmode] 
    if {$index != -1} {
        set DestinationAddrMode [lindex $args [expr $index + 1]]
    } else {
        set DestinationAddrMode "fixed"
    }
    set index [lsearch $args -destaddressoffset] 
    if {$index != -1} {
        set DestinationAddrOffset [lindex $args [expr $index + 1]]
    } else {
        set DestinationAddrOffset 0
    }
    set index [lsearch $args -destaddressstep] 
    if {$index != -1} {
        set destinationAddrStep [lindex $args [expr $index + 1]]
       
        set ret [string first ":" $destinationAddrStep] 
        if {$ret == -1} {
              set destinationAddrStep [Num2Ipv6 $destinationAddrStep]
        }
    } else {
        set destinationAddrStep "::1"
    }
    set index [lsearch $args -destaddresscount] 
    if {$index != -1} {
        set DestinationAddrNum [lindex $args [expr $index + 1]]
    } else {
        set DestinationAddrNum 1
    }
    
    set index [lsearch $args -sourceaddressmode] 
    if {$index != -1} {
        set sourceAddrMode [lindex $args [expr $index + 1]]
    } else {
        set sourceAddrMode "fixed"
    }
    set index [lsearch $args -sourceaddressoffset] 
    if {$index != -1} {
        set sourceAddrOffset [lindex $args [expr $index + 1]]
    } else {
        set sourceAddrOffset 0
    }
    set index [lsearch $args -sourceaddressstep] 
    if {$index != -1} {
        set sourceAddrStep [lindex $args [expr $index + 1]]
        set ret [string first ":" $sourceAddrStep] 
        if {$ret == -1} {
              set sourceAddrStep [Num2Ipv6 $sourceAddrStep]
        }
    } else {
        set sourceAddrStep "::1"
    }
    set index [lsearch $args -sourceaddresscount] 
    if {$index != -1} {
        set sourceAddrNum [lindex $args [expr $index + 1]]
    } else {
        set sourceAddrNum 1
    }

    #Add the bouding of MplsVPN
    if {[string tolower $m_streamType ] == "vpn"} {
         if {[info exists ::mainDefine::gIpv6NetworkBlock($sourceAddr)]} {
             catch {
                  set hSrcIpv6NetworkBlock $::mainDefine::gIpv6NetworkBlock($sourceAddr)
                  stc::config $streamBlock1 -SrcBinding-targets " $hSrcIpv6NetworkBlock "
                  set sourceAddr [stc::get $hSrcIpv6NetworkBlock -StartIpList]
                  stc::config $ipv61 -sourceAddr $sourceAddr
             }
         }

         if {[info exists ::mainDefine::gIpv6NetworkBlock($destAddr)]} {
             catch {
                  set hDstIpv6NetworkBlock $::mainDefine::gIpv6NetworkBlock($destAddr)
                  stc::config $streamBlock1 -DstBinding-targets " $hDstIpv6NetworkBlock "
                  set destAddr [stc::get $hDstIpv6NetworkBlock -StartIpList]
                  stc::config $ipv61 -destAddr $destAddr
             }
         }
    }

    #Create IPV6 header modifier
    if {([string tolower $sourceAddrMode] == "increment") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceAddr \
            -Mask "::FFFF:FFFF" -OffsetReference $ip1.sourceAddr -StepValue $sourceAddrStep \
            -Offset $sourceAddrOffset -ModifierMode INCR -RecycleCount $sourceAddrNum -RepeatCount 0]    
        set m_srcModifierList($pduName) $IPModifier1
    } elseif {([string tolower $sourceAddrMode] == "decrement") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourceAddr \
            -Mask "::FFFF:FFFF"  -OffsetReference $ip1.sourceAddr -StepValue $sourceAddrStep \
            -Offset $sourceAddrOffset -ModifierMode DECR -RecycleCount $sourceAddrNum -RepeatCount 0]
        set m_srcModifierList($pduName) $IPModifier1
    } elseif {[string tolower $sourceAddrMode] =="random"} {
              set IPModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                 -Mask "::FFFF:FFFF" -OffsetReference $ip1.sourceAddr  \
                 -Offset $sourceAddrOffset -RecycleCount $sourceAddrNum -RepeatCount 0]   
              set m_srcModifierList($pduName) $IPModifier1
    }
    
    if {([string tolower $DestinationAddrMode] == "increment") } {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destAddr \
            -Mask "::FFFF:FFFF"  -OffsetReference $ip1.destAddr -StepValue $destinationAddrStep \
            -Offset $DestinationAddrOffset -ModifierMode INCR -RecycleCount $DestinationAddrNum -RepeatCount 0]    
        set m_destModifierList($pduName) $IPModifier1
    } elseif {([string tolower $DestinationAddrMode] == "decrement")} {
        set IPModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destAddr \
            -Mask "::FFFF:FFFF"  -OffsetReference $ip1.destAddr -StepValue $destinationAddrStep \
            -Offset $DestinationAddrOffset -ModifierMode DECR -RecycleCount $DestinationAddrNum -RepeatCount 0]
          set m_destModifierList($pduName) $IPModifier1
    } elseif {[string tolower $DestinationAddrMode] =="random"} {
              set IPModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                 -Mask "::FFFF:FFFF" -OffsetReference $ip1.destAddr  \
                 -Offset $DestinationAddrOffset -RecycleCount $DestinationAddrNum -RepeatCount 0] 
               set m_destModifierList($pduName) $IPModifier1
    }
    #Store header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $ipv61

    catch {
        if {$m_portType == "ethernet" } { 
            set Ether1 [lindex [stc::get $streamBlock1 -children-ethernet:EthernetII] 0]
            if {$m_mplsType == "mplsunicast"} {
                stc::config $Ether1 -etherType "8847"
            } elseif {$m_mplsType == "mplsmulticast"} {
                stc::config $Ether1 -etherType "8848"
            } elseif {$m_IPv4HeaderFlag == "0" } {            
                stc::config $Ether1 -etherType "86DD"
            }
        }
    }

    debugPut "exit the proc of AddIPv6HeaderIntoStream"    
    }

############################################################################
#APIName: AddTcpHeaderIntoStream
#Description: Add Tcp header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to sepcify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddTcpHeaderIntoStream {args hStream pduName} {
                
    set streamBlock1 $hStream
    #Parse offset parameter
    set index [lsearch $args -offset] 
    if {$index != -1} {
        set offset [lindex $args [expr $index + 1]]
    } 
    
    #Parse sourcePort parameter
    set index [lsearch $args -sourcePort] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
    } 
    
    #Parse destPort parameter
    set index [lsearch $args -destPort] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
    }
    
    #Parse sequenceNumber parameter
    set index [lsearch $args -sequenceNumber] 
    if {$index != -1} {
        set sequenceNumber [lindex $args [expr $index + 1]]
    } 
    
    #Parse acknowledgementNumber parameter
    set index [lsearch $args -acknowledgementNumber] 
    if {$index != -1} {
        set acknowledgementNumber [lindex $args [expr $index + 1]]
    } 
    
    #Parse window parameter
    set index [lsearch $args -window] 
    if {$index != -1} {
        set window [lindex $args [expr $index + 1]]
    } 
    
    #Parse urgentPointer parameter
    set index [lsearch $args -urgentPointer] 
    if {$index != -1} {
        set urgentPointer [lindex $args [expr $index + 1]]
    } 
    
    #Parse options parameter
    set index [lsearch $args -options] 
    if {$index != -1} {
        set options [lindex $args [expr $index + 1]]
    } 
    
    #Parse urgentPointerValid parameter
    set index [lsearch $args -urgentPointerValid] 
    if {$index != -1} {
        set urgentPointerValid [lindex $args [expr $index + 1]]
    } 
    
    #Parse acknowledgeValid parameter
    set index [lsearch $args -acknowledgeValid] 
    if {$index != -1} {
        set acknowledgeValid [lindex $args [expr $index + 1]]
    } 
    
    #Parse pushFunctionValid parameter
    set index [lsearch $args -pushFunctionValid] 
    if {$index != -1} {
        set pushFunctionValid [lindex $args [expr $index + 1]]
    }
    
    #Parse resetConnection parameter
    set index [lsearch $args -resetConnection] 
    if {$index != -1} {
        set resetConnection [lindex $args [expr $index + 1]]
    } else  {
        set resetConnection false
    }
    
    #Parse synchronize parameter
    set index [lsearch $args -synchronize] 
    if {$index != -1} {
        set synchronize [lindex $args [expr $index + 1]]
    } 
    
    #Parse finished parameter
    set index [lsearch $args -finished] 
    if {$index != -1} {
        set finished [lindex $args [expr $index + 1]]
    } 
    
    #Parse useValidChecksum parameter
    set index [lsearch $args -useValidChecksum] 
    if {$index != -1} {
        set useValidChecksum [lindex $args [expr $index + 1]]
    }
    
    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    }
    
    #Parse srcPortMode parameter
    set index [lsearch $args -srcPortMode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse srcStep parameter
    set index [lsearch $args -srcStep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
    }
    
    #Parse destPortMode parameter
    set index [lsearch $args -destPortMode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse destStep parameter
    set index [lsearch $args -destStep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
    }
    
    #Parse numDest parameter
    set index [lsearch $args -numDest] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
    }
    
    #Parse numSrc parameter
    set index [lsearch $args -numSrc] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
    } 
 
    #Create TCP header, and configure parameters
    set tcp1 [stc::create tcp:Tcp -under $streamBlock1 ]

    #Store header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $tcp1

    set tcp_1 [stc::get $tcp1 -Name]
    stc::config $tcp1 -destPort $destPort -sourcePort $sourcePort -offset $offset \
        -seqNum $sequenceNumber -ackNum $acknowledgementNumber -window $window \
        -urgentPtr $urgentPointer 
    if {[string tolower $urgentPointerValid] == "false"} {
        stc::config $tcp1 -urgBit 0
    } else {
        stc::config $tcp1 -urgBit 1
    }
    if {[string tolower $acknowledgeValid] == "false"} {
        stc::config $tcp1 -ackBit 0
    } else {
        stc::config $tcp1 -ackBit 1
    }
    if {[string tolower $pushFunctionValid] == "false"} {
        stc::config $tcp1 -pshBit 0
    } else {
        stc::config $tcp1 -pshBit 1
    }
    if {[string tolower $resetConnection] == "false"} {
        stc::config $tcp1 -rstBit 0
    } else {
        stc::config $tcp1 -rstBit 1
    }
    if {[string tolower $synchronize] == "false"} {
        stc::config $tcp1 -synBit 0
    } else {
        stc::config $tcp1 -synBit 1
    }
    if {[string tolower $finished] == "false"} {
        stc::config $tcp1 -finBit 0
    } else {
        stc::config $tcp1 -finBit 1
    }
    if {[string tolower $useValidChecksum] == "false"} {
        stc::config $tcp1 -checksum $checksum
    } 
    
    #Create TCP modifier
    if {[string tolower $srcPortMode] =="incr" || [string tolower $srcPortMode] =="increment"} {
        set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourcePort \
                  -Mask 0xFFFF -OffsetReference $tcp_1.sourcePort \
                  -Offset 0 -ModifierMode INCR -RecycleCount $numSrc -StepValue $srcStep -RepeatCount 0]
         set m_srcModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $srcPortMode] =="decr" || [string tolower $srcPortMode] =="decrement"} {
         set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourcePort \
                  -Mask 0xFFFF -OffsetReference $tcp_1.sourcePort \
                  -Offset 0 -ModifierMode DECR -RecycleCount $numSrc -StepValue $srcStep -RepeatCount 0]     
          set m_srcModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $srcPortMode] =="rand" || [string tolower $srcPortMode] =="random"} {
         set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                  -Mask 0xFFFF -OffsetReference $tcp_1.sourcePort \
                 -Offset 0 -RecycleCount $numSrc -RepeatCount 0]     
          set m_srcModifierList($pduName) $VlanModifier1
    } 
    if {[string tolower $destPortMode] =="incr" || [string tolower $destPortMode] == "increment"} {
        set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destPort \
                  -Mask 0xFFFF -OffsetReference $tcp_1.destPort \
                  -Offset 0 -ModifierMode INCR -RecycleCount $numDest -StepValue $destStep -RepeatCount 0]
         set m_destModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $destPortMode] =="decr" || [string tolower $destPortMode] == "decrement"} {
         set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destPort \
                  -Mask 0xFFFF -OffsetReference $tcp_1.destPort \
                  -Offset 0 -ModifierMode DECR -RecycleCount $numDest -StepValue $destStep -RepeatCount 0]  
          set m_destModifierList($pduName) $VlanModifier1   
    } elseif {[string tolower $destPortMode] =="rand" || [string tolower $destPortMode] == "random"} {
         set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                  -Mask 0xFFFF -OffsetReference $tcp_1.destPort \
                 -Offset 0 -RecycleCount $numDest -RepeatCount 0]     
          set m_destModifierList($pduName) $VlanModifier1
    } 

   catch {
        set ipv41 [lindex [stc::get $streamBlock1 -children-ipv4:IPv4] 0]
        if {$ipv41 != ""} {
            stc::config $ipv41 -protocol 6
        }
   }
}

############################################################################
#APIName: AddUDPHeaderIntoStream
#Description: Add UDP header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddUdpHeaderIntoStream {args hStream pduName} {
    
    set streamBlock1 $hStream               
    #Parse sourcePort parameter
    set index [lsearch $args -sourcePort] 
    if {$index != -1} {
        set sourcePort [lindex $args [expr $index + 1]]
    } 
    
    #Parse destPort parameter
    set index [lsearch $args -destPort] 
    if {$index != -1} {
        set destPort [lindex $args [expr $index + 1]]
    }
    
    #Parse checksum parameter
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    }
    
    #Parse enableChecksum parameter
    set index [lsearch $args -enableChecksum] 
    if {$index != -1} {
        set enableChecksum [lindex $args [expr $index + 1]]
    } 
    
    #Parse length parameter
    set index [lsearch $args -length] 
    if {$index != -1} {
        set length [lindex $args [expr $index + 1]]
    } 
    
    #Parse lengthOverride parameter
    set index [lsearch $args -lengthOverride] 
    if {$index != -1} {
        set lengthOverride [lindex $args [expr $index + 1]]
    }
    
    #Parse enableChecksumOverride parameter
    set index [lsearch $args -enableChecksumOverride] 
    if {$index != -1} {
        set enableChecksumOverride [lindex $args [expr $index + 1]]
    } 
    
    #Parse checksumMode parameter
    set index [lsearch $args -checksumMode] 
    if {$index != -1} {
        set checksumMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse srcPortMode parameter
    set index [lsearch $args -srcPortMode] 
    if {$index != -1} {
        set srcPortMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse srcStep parameter
    set index [lsearch $args -srcStep] 
    if {$index != -1} {
        set srcStep [lindex $args [expr $index + 1]]
    }
    
    #Parse destPortMode parameter
    set index [lsearch $args -destPortMode] 
    if {$index != -1} {
        set destPortMode [lindex $args [expr $index + 1]]
    } 
    
    #Parse destStep parameter
    set index [lsearch $args -destStep] 
    if {$index != -1} {
        set destStep [lindex $args [expr $index + 1]]
    }
    
    #Parse numDest parameter
    set index [lsearch $args -numDest] 
    if {$index != -1} {
        set numDest [lindex $args [expr $index + 1]]
    }
    
    #Parse numSrc parameter
    set index [lsearch $args -numSrc] 
    if {$index != -1} {
        set numSrc [lindex $args [expr $index + 1]]
    } 

    #Create UDP header, and configure parameters
    set udp1 [stc::create udp:Udp -under $streamBlock1 ]
    #Store header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $udp1

    set udp_1 [stc::get $udp1 -Name]
    stc::config $udp1 -destPort $destPort -sourcePort $sourcePort 
    if {[string tolower $enableChecksum] == "true"} {
        if {[string tolower $enableChecksumOverride] == "true"} {
            if {[string tolower $checksumMode] == "man" } {
                stc::config $udp1 -checksum $checksum
            }
        }
    }
    if {[string tolower $lengthOverride] == "true"} {
        stc::config $udp1 -length $length
    } 
    
    #Create UDP modifier if needed
    if {[string tolower $srcPortMode] =="incr" || [string tolower $srcPortMode] =="increment"} {
        set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourcePort \
                  -Mask 0xFFFF -OffsetReference $udp_1.sourcePort \
                  -Offset 0 -ModifierMode INCR -RecycleCount $numSrc -StepValue $srcStep -RepeatCount 0]
         set m_srcModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $srcPortMode] =="decr" || [string tolower $srcPortMode] =="decrement"} {
         set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $sourcePort \
                  -Mask 0xFFFF -OffsetReference $udp_1.sourcePort \
                  -Offset 0 -ModifierMode DECR -RecycleCount $numSrc -StepValue $srcStep -RepeatCount 0]     
          set m_srcModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $srcPortMode] =="rand" || [string tolower $srcPortMode] =="random"} {
         set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                  -Mask 0xFFFF -OffsetReference $udp_1.sourcePort \
                 -Offset 0 -RecycleCount $numSrc -RepeatCount 0]    
          set m_srcModifierList($pduName) $VlanModifier1 
    } 
    if {[string tolower $destPortMode] =="incr" || [string tolower $destPortMode] =="increment"} {
        set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destPort \
                  -Mask 0xFFFF -OffsetReference $udp_1.destPort \
                  -Offset 0 -ModifierMode INCR -RecycleCount $numDest -StepValue $destStep -RepeatCount 0]
        set m_destModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $destPortMode] =="decr" || [string tolower $destPortMode] =="decrement"} {
         set VlanModifier1 [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $destPort \
                  -Mask 0xFFFF -OffsetReference $udp_1.destPort \
                  -Offset 0 -ModifierMode DECR -RecycleCount $numDest -StepValue $destStep -RepeatCount 0]     
          set m_destModifierList($pduName) $VlanModifier1
    } elseif {[string tolower $destPortMode] =="rand" || [string tolower $destPortMode] =="random"} {
         set VlanModifier1 [stc::create RandomModifier -under $streamBlock1 -EnableStream $m_EnableStream  \
                  -Mask 0xFFFF -OffsetReference $udp_1.destPort \
                 -Offset 0 -RecycleCount $numDest -RepeatCount 0]     
          set m_destModifierList($pduName) $VlanModifier1
    }        

  catch {
        set ipv41 [lindex [stc::get $streamBlock1 -children-ipv4:IPv4] 0]
        if {$ipv41 != ""} {
            stc::config $ipv41 -protocol 17
        }
   }
}

############################################################################
#APIName: AddMplsHeaderIntoStream
#Description: Add Mpls header into certain stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddMplsHeaderIntoStream {args hStream pduName} {

    set streamBlock1 $hStream            
    
    #Parse type parameter
    set index [lsearch $args -type] 
    if {$index != -1} {
        set type [lindex $args [expr $index + 1]]
        set m_mplsType [string tolower $type]
    }
    
    #Parse label parameter
    set index [lsearch $args -label] 
    if {$index != -1} {
        set label [lindex $args [expr $index + 1]]
    } 

    #Parse labelCount parameter
    set index [lsearch $args -labelCount] 
    if {$index != -1} {
        set labelCount [lindex $args [expr $index + 1]]
    } 

    #Parse labelMode parameter
    set index [lsearch $args -labelMode] 
    if {$index != -1} {
        set labelMode [lindex $args [expr $index + 1]]
    } 

    #Parse labelStep parameter
    set index [lsearch $args -labelStep] 
    if {$index != -1} {
        set labelStep [lindex $args [expr $index + 1]]
    } 
    
    #Parse exp parameter
    set index [lsearch $args -exp] 
    if {$index != -1} {
        set exp [lindex $args [expr $index + 1]]
    } 
    
    #Parse TTL parameter
    set index [lsearch $args -TTL] 
    if {$index != -1} {
        set TTL [lindex $args [expr $index + 1]]
    }
    
    #Parse bottomOfStack parameter
    set index [lsearch $args -bottomOfStack] 
    if {$index != -1} {
        set bottomOfStack [lindex $args [expr $index + 1]]
    } 
    
    #Create MPLS header, and configure parameters
    set mpls1 [stc::create mpls:Mpls -under $streamBlock1]
    #Store header handle
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $mpls1

    stc::config $mpls1 -ttl $TTL -label $label -sBit $bottomOfStack -exp $exp
    set mpls_1 [stc::get $mpls1 -Name]
    
    #Create MPLS modifier
    if {[string tolower $labelMode] == "increment"} {
        set LabelModifier [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $label \
                  -Mask 0xFFFF -OffsetReference $mpls_1.label \
                  -Offset 0 -ModifierMode INCR -RecycleCount $labelCount -StepValue $labelStep -RepeatCount 0]
         set m_srcModifierList($pduName) $LabelModifier
    } elseif {[string tolower $labelMode] == "decrement"} {
         set LabelModifier [stc::create RangeModifier -under $streamBlock1 -EnableStream $m_EnableStream -Data $label \
                  -Mask 0xFFFF -OffsetReference $mpls_1.label \
                  -Offset 0 -ModifierMode DECR -RecycleCount $labelCount -StepValue $labelStep -RepeatCount 0]    
         set m_destModifierList($pduName) $LabelModifier
    }
    
}

############################################################################
#APIName: AddPdu
#Description: Add pdu to the stream block
#Input: 1. args:argument list. including
#              (1) -PduName PduName optional,name of the pdu,i.e -PduName head1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddPdu {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of Stream::AddPdu..."

    set ::mainDefine::objectName $this
  
     uplevel 1 {
            set ::mainDefine::result [$::mainDefine::objectName cget -m_hStream]
    }
    set streamBlock1 $::mainDefine::result
    stc::config $streamBlock1 -active true
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduNames [lindex $args [expr $index + 1]]
    } else  {
        error "please specify PduName for Stream::AddPdu API \nexit the proc of AddPdu..."
    }
 
    catch { set PduNames [string trimleft $PduNames '\{' ] }
    catch { set PduNames [string trimright $PduNames '\}' ] }
    set ::mainDefine::pduNameList $PduNames

    set  m_IPv4HeaderFlag 0
    set  m_mplsType ""

    foreach PduName $PduNames  {
     
        set index [lsearch $::mainDefine::gPduNameList $PduName] 
        if {$index == -1} {
            error "PduName($PduName) does not existed,the existed PduName(s) is(are):\n $::mainDefine::gPduNameList \nexit the proc of AddPdu..."
        } 

        set index [lsearch $::mainDefine::gPduConfigList $PduName] 
        set pduType [lindex $::mainDefine::gPduConfigList [expr $index + 1]]
        set pduConfig [lindex $::mainDefine::gPduConfigList [expr $index + 2]]
        set args $pduConfig
       
        set m_typeModifierList($PduName) ""
        set m_srcModifierList($PduName) ""
        set m_destModifierList($PduName) ""
        #Add PDUs to the stream according to pduType
        switch $pduType {
    
            EthHeader {
                AddEthHeaderIntoStream $args $streamBlock1 $PduName    
            }
            VlanHeader {
                AddVlanHeaderIntoStream $args $streamBlock1 $PduName
            }
            IPv4Header {
                AddIPv4HeaderIntoStream $args $streamBlock1 $PduName
                set m_IPv4HeaderFlag 1
            }
            IPv6Header {
                AddIPv6HeaderIntoStream $args $streamBlock1 $PduName
            }
            TcpHeader {
                AddTcpHeaderIntoStream $args $streamBlock1 $PduName
            }
            UdpHeader {
                AddUdpHeaderIntoStream $args $streamBlock1 $PduName
            }
            MplsHeader {
                AddMplsHeaderIntoStream $args $streamBlock1 $PduName
            }
            POSHeader {
               AddPOSHeaderIntoStream $args $streamBlock1 $PduName
            }  
            HDLCHeader {
               AddHDLCHeaderIntoStream $args $streamBlock1 $PduName
            }   
            DHCPPacket {
                AddDHCPPacketIntoStream $args $streamBlock1 $PduName
            }
            GREPacket  {
                AddGREPacketIntoStream $args $streamBlock1 $PduName
            }
            ArpPacket {
                AddArpPacketIntoStream $args $streamBlock1 $PduName
            }
            RipPacket {
                AddRipPacketIntoStream $args $streamBlock1 $PduName
            }
            RipngPacket {
                AddRipngPacketIntoStream $args $streamBlock1 $PduName
            }
            IcmpPacket {
                AddIcmpPacketIntoStream $args $streamBlock1 $PduName
            }
            Ospfv2Packet {
                AddOspfv2PacketIntoStream $args $streamBlock1 $PduName
            }
            Icmpv6Packet {
                AddIcmpv6PacketIntoStream $args $streamBlock1 $PduName
            }
            CustomPacket {
                AddCustomPacketIntoStream $args $streamBlock1 $PduName
            }
            IGMPPacket {
                AddIGMPPacketIntoStream $args $streamBlock1 $PduName
            }
            PIMPacket {
                AddPIMPacketIntoStream $args $streamBlock1 $PduName
            }
            PPPoEPacket {
                AddPPPoEPacketIntoStream $args $streamBlock1 $PduName
            }
            MLDPacket {
                AddMLDPacketIntoStream $args $streamBlock1 $PduName
            }    
        }
    }    

    debugPut "exit the proc of Stream::AddPdu..."  
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyPdu
#Description: destroy pdu
#Input: 1. args:argument list，including
#              (1) -PduName PduName optional,name of the pdu,i.e -PduName head1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::DestroyPdu {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of Stream::DestroyPdu..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduNames [lindex $args [expr $index + 1]]
        catch { set PduNames [string trimleft $PduNames '\{' ] }
        catch { set PduNames [string trimright $PduNames '\}' ] }
    } else  {
        set PduNames all
    }

    #Destroy the pdu
    if {[string tolower $PduNames] == "all"} {

        foreach PduName $::mainDefine::gPduNameList {
             unset PduName
       }

        set ::mainDefine::gPduNameList ""
        set ::mainDefine::gPduConfigList ""
        set ::mainDefine::gPduNameList ""

    } else {    
        foreach PduName $PduNames  {
              
             set index [lsearch $::mainDefine::gPduNameList $PduName] 
             if {$index != -1} {
                 set ::mainDefine::gPduNameList [lreplace $::mainDefine::gPduNameList $index $index ]
             }
             set index [lsearch $::mainDefine::gPduConfigList $PduName]  
             if {$index != -1} {
                  set ::mainDefine::gPduConfigList [lreplace $::mainDefine::gPduConfigList $index [expr $index + 2]]
             }
         }
    }
    
    debugPut "exit the proc of Stream::DestroyPdu..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: RemovePdu
#Description: remove pdu from the stream
#Input: 1. args:argument list，including
#              (1) -PduName PduName optional,name of the pdu,i.e -PduName head1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::RemovePdu {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of Stream::RemovePdu..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduNames [lindex $args [expr $index + 1]]
       catch { set PduNames [string trimleft $PduNames '\{' ] }
       catch { set PduNames [string trimright $PduNames '\}' ] }
    } else  {
        set PduNames all
    }
 
    if {[string tolower $PduNames] == "all"} {
          foreach PduName $m_PduNameList  {
              #catch {stc::delete $m_PduHandleList($PduName) }
              #unset m_PduHandleList($PduName)

              if {$m_typeModifierList($PduName) != ""} {
                  catch { stc::delete $m_typeModifierList($PduName) }
                  unset m_typeModifierList($PduName) 
              }

              if {$m_srcModifierList($PduName) != ""} {
                  catch { stc::delete $m_srcModifierList($PduName) }
                  unset m_srcModifierList($PduName) 
              }

              if {$m_destModifierList($PduName) != ""} {
                   catch { stc::delete $m_destModifierList($PduName) } 
                   unset m_destModifierList($PduName) 
              }
          }

          stc::config $m_hStream -frameConfig ""   
          set m_PduNameList ""
    } else {   
        foreach PduName $PduNames  {
             set index [lsearch $m_PduNameList  $PduName] 
             if {$index != -1} {
                 set m_PduNameList  [lreplace $m_PduNameList  $index $index ]
             
                 #catch { stc::delete $m_PduHandleList($PduName) }
                 #unset m_PduHandleList($PduName)

                 if {$m_typeModifierList($PduName) != ""} {
                     catch { stc::delete $m_typeModifierList($PduName) }
                     unset m_typeModifierList($PduName) 
                 }

                 if {$m_srcModifierList($PduName) != ""} {
                      catch { stc::delete $m_srcModifierList($PduName) }
                      unset m_srcModifierList($PduName) 
                 }

                 if {$m_destModifierList($PduName) != ""} {
                      catch { stc::delete $m_destModifierList($PduName) }
                      unset m_destModifierList($PduName) 
                 }
             }
         }

         stc::config $m_hStream -frameConfig "" 

         set pduNameList $m_PduNameList
         set m_PduNameList ""
         AddPdu -PduName $pduNameList
    }
    
    debugPut "exit the proc of Stream::RemovePdu..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: FindPdu
#Description: Find pdu in PDU list
#Input: 1. args:argument list，
#              (1) -PduName PduName optional,name of the pdu,i.e -PduName head1
#Output: if find the pdu and stram not in running state，then return the pdu list; otherwise return ""
#Coded by: Tony
#############################################################################
::itcl::body Stream::FindPdu {args} {
    
     #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of Stream::FindPdu..."
    
    set result ""
    #parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]

        set pdu_index [lsearch $m_PduNameList  $PduName] 
        if {$pdu_index != -1} {
              set state [stc::get $m_hStream -RunningState]
              if {$state != "RUNNING"} {
                  set result $m_PduNameList
              }
        }
    }
    
    debugPut "exit the proc of Stream::FindPdu..." 
    return $result
}

############################################################################
#APIName: CreateEthHeader
#Description: Create Eth header
#Input: 1. args:argument list，including
#              (1) -DA DA required，destination Mac address，i.e -DA 00-00-00-00-00-01
#              (2) -SA SA required，source mac address，i.e -SA 00-00-00-00-00-02
#              (3) -saRepeatCounter saRepeatCounter required，source mac step，valid range:fixed/incr/rand/decr，i.e -saRepeatCounter fixed
#              (4) -saStep saStep optional，source mac step，i.e -saStep 1
#              (5) -daRepeatCounter daRepeatCounter required,destination Mac mode，valid range:fixed/incr/rand/decr, i.e -daRepeatCounter fixed
#              (6) -daStep -numDA -numSA  optional
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateEthHeader {args} {
  
    #将输入参数转换成小写参数
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of HeaderCreator::CreateEthHeader..."

    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateEthHeader API \nexit the proc of CreateEthHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateEthHeader... "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "EthHeader"
    set PduConfigList ""
    
    #Parse daRepeatCounter parameter
    set index [lsearch $args -darepeatcounter] 
    if {$index != -1} {
        set daRepeatCounter [lindex $args [expr $index + 1]]
    } else  {
        set daRepeatCounter fixed
    }
    lappend PduConfigList -daRepeatCounter
    lappend PduConfigList $daRepeatCounter
    
    #Parse DA parameter
    set index [lsearch $args -da] 
    if {$index != -1} {
        set DA [lindex $args [expr $index + 1]]
        set DA [string map {- :} $DA]
    } else  {
        error "Please specify DA parameter \nexit the proc of CreateEthHeader..."
    }
    lappend PduConfigList -DA
    lappend PduConfigList $DA
    
    #Parse numDA parameter
    set index [lsearch $args -numda] 
    if {$index != -1} {
        set numDA [lindex $args [expr $index + 1]]
    } else  {
        set numDA 1
    }
    lappend PduConfigList -numDA
    lappend PduConfigList $numDA

    #提取参数daList的值
    set index [lsearch $args -dalist] 
    if {$index != -1} {
        set daList [lindex $args [expr $index + 1]]
    } else  {
        set daList "NULL"
    }
    lappend PduConfigList -daList
    lappend PduConfigList $daList
    
    #Parse daStep parameter
    set index [lsearch $args -dastep] 
    if {$index != -1} {
        set daStep [lindex $args [expr $index + 1]]
        set daStep [string map {- :} $daStep]
    } else  {
        set daStep 00-00-00-00-00-01
        set daStep [string map {- :} $daStep]
    }
    lappend PduConfigList -daStep
    lappend PduConfigList $daStep
    
    #Parse saRepeatCounter parameter
    set index [lsearch $args -sarepeatcounter] 
    if {$index != -1} {
        set saRepeatCounter [lindex $args [expr $index + 1]]
    } else  {
        set saRepeatCounter fixed
    }
    lappend PduConfigList -saRepeatCounter
    lappend PduConfigList $saRepeatCounter
    
    #Parse SA parameter
    set index [lsearch $args -sa] 
    if {$index != -1} {
        set SA [lindex $args [expr $index + 1]]
        set SA [string map {- :} $SA]
    } else  {
        error "Please specify SA parameter \nexit the proc of CreateEthHeader..."
    }
    lappend PduConfigList -SA
    lappend PduConfigList $SA
    
    #Parse numSA parameter
    set index [lsearch $args -numsa] 
    if {$index != -1} {
        set numSA [lindex $args [expr $index + 1]]
    } else  {
        set numSA 1
    }
    lappend PduConfigList -numSA
    lappend PduConfigList $numSA

    #提取参数saList的值
    set index [lsearch $args -salist] 
    if {$index != -1} {
        set saList [lindex $args [expr $index + 1]]
    } else  {
        set saList "NULL"
    }
    lappend PduConfigList -saList
    lappend PduConfigList $saList
    
    #Parse saStep parameter
    set index [lsearch $args -sastep] 
    if {$index != -1} {
        set saStep [lindex $args [expr $index + 1]]
        set saStep [string map {- :} $saStep]
    } else  {
        set saStep 00-00-00-00-00-01
        set saStep [string map {- :} $saStep]
    }
    lappend PduConfigList -saStep
    lappend PduConfigList $saStep

    #Parse EthType parameter
    set index [lsearch $args -ethtype] 
    if {$index != -1} {
        set EthType [lindex $args [expr $index + 1]]
        set m_EthType $EthType
        lappend PduConfigList -EthType
        lappend PduConfigList $EthType
    }     

    #Parse EthTypeMode parameter
    set index [lsearch $args -ethtypemode] 
    if {$index != -1} {
        set EthTypeMode [lindex $args [expr $index + 1]]
    } else {
        set EthTypeMode "fixed"
    }   
    lappend PduConfigList -EthTypeMode
    lappend PduConfigList $EthTypeMode  

    #Parse EthTypeStep parameter
    set index [lsearch $args -ethtypestep] 
    if {$index != -1} {
        set EthTypeStep [lindex $args [expr $index + 1]]
    } else {
        set EthTypeStep 1
    }
    lappend PduConfigList -EthTypeStep
    lappend PduConfigList $EthTypeStep  

    #Parse EthTypeCount parameter
    set index [lsearch $args -ethtypecount] 
    if {$index != -1} {
        set EthTypeCount [lindex $args [expr $index + 1]]
    } else {
        set EthTypeCount 1 
    }
    lappend PduConfigList -EthTypeCount
    lappend PduConfigList $EthTypeCount     

    lappend ::mainDefine::gPduConfigList "$PduConfigList"
    
    debugPut "exit the proc of HeaderCreator::CreateEthHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigEthHeader
#Description: Create Eth header
#Input: 1. args:argument list，including
#              (1) -DA DA required，destination Mac address，i.e -DA 00-00-00-00-00-01
#              (2) -SA SA required，source mac address，i.e -SA 00-00-00-00-00-02
#              (3) -saRepeatCounter saRepeatCounter required，source mac step，valid range:fixed/incr/rand/decr，i.e -saRepeatCounter fixed
#              (4) -saStep saStep optional，source mac step，i.e -saStep 1
#              (5) -daRepeatCounter daRepeatCounter required,destination Mac mode，valid range:fixed/incr/rand/decr, i.e -daRepeatCounter fixed
#              (6) -daStep -numDA -numSA  optional
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigEthHeader {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args] 
    debugPut "enter the proc of HeaderCreator::ConfigEthHeader..."

    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::ConfigEthHeader API \nexit the proc of ConfigEthHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist \nexit the proc of ConfigEthHeader... "
    } 
    
    #Parse daRepeatCounter parameter    
    set index [lsearch $args -darepeatcounter] 
    if {$index != -1} {
        set daRepeatCounter [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-daRepeatCounter" $daRepeatCounter
    } 

    #Parse DA parameter
    set index [lsearch $args -da] 
    if {$index != -1} {
        set DA [lindex $args [expr $index + 1]]
        set DA [string map {- :} $DA]
        ReplacePduAttrValue $PduName "-DA" $DA
    }

    #Parse numDA parameter
    set index [lsearch $args -numda] 
    if {$index != -1} {
        set numDA [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numDA" $numDA
    }

    #提取参数daList 的值
    set index [lsearch $args -dalist] 
    if {$index != -1} {
        set daList [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-daList" $daList
    }

    #提取参数daStep的值
    set index [lsearch $args -dastep] 
    if {$index != -1} {
        set daStep [lindex $args [expr $index + 1]]
        set daStep [string map {- :} $daStep]
        ReplacePduAttrValue $PduName "-daStep" $daStep
    } 

    #Parse saRepeatCounter parameter
    set index [lsearch $args -sarepeatcounter] 
    if {$index != -1} {
        set saRepeatCounter [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-saRepeatCounter" $saRepeatCounter 
    }

    #Parse SA parameter
    set index [lsearch $args -sa] 
    if {$index != -1} {
        set SA [lindex $args [expr $index + 1]]
        set SA [string map {- :} $SA]
        ReplacePduAttrValue $PduName "-SA" $SA
    } 

    #Parse numSA parameter
    set index [lsearch $args -numsa] 
    if {$index != -1} {
        set numSA [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-numSA" $numSA 
    } 

    #提取参数saList 的值
    set index [lsearch $args -saList] 
    if {$index != -1} {
        set saList [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-saList" $saList
    }

    #提取参数saStep的值
    set index [lsearch $args -sastep] 
    if {$index != -1} {
        set saStep [lindex $args [expr $index + 1]]
        set saStep [string map {- :} $saStep]
        ReplacePduAttrValue $PduName "-saStep" $saStep 
    } 

    #Parse EthType parameter
    set index [lsearch $args -ethtype] 
    if {$index != -1} {
        set EthType [lindex $args [expr $index + 1]]
        set m_EthType $EthType
        ReplacePduAttrValue $PduName "-EthType" $EthType 
    } 

    #Parse EthTypeMode parameter
    set index [lsearch $args -ethtypemode] 
    if {$index != -1} {
        set EthTypeMode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-EthTypeMode" $EthTypeMode 
    } 

    #Parse EthTypeStep parameter
    set index [lsearch $args -ethtypestep] 
    if {$index != -1} {
        set EthTypeStep [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-EthTypeStep" $EthTypeStep 
    } 

    #Parse EthTypeCount parameter
    set index [lsearch $args -ethtypecount] 
    if {$index != -1} {
        set EthTypeCount [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-EthTypeCount" $EthTypeCount 
    } 

    ApplyPduConfigToStreams $PduName

    debugPut "exit the proc of HeaderCreator::ConfigEthHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateVlanHeader
#Description: Create Vlan header
#Input: 1. args:argument list，including
#              (1) -vlanID vlanID required,Vlan Id,i.e -vlanID 1
#              (2) -userPriority userPriority required，user priority，i.e -userPriority 0
#              (3) -cfi cfi required，Cfi value，i.e -cfi 0
#              (4) -mode mode required，Vlan value change mode，valid range:fixed/incr/decr/rand, i.e -mode fixed
#              (5) -repeat repeat optional，Vlan value change count，i.e -repeat 10
#              (6) -step step optional，Vlan step，i.e -step 1
#              (7) -maskval maskval optional，Vlan mask，i.e -maskval 0000
#              (8) -protocolTagId protocolTagId required，Vlan TPID，i.e -protocolTagId 8100
#              (9) -Vlanstack Vlanstack ，Vlan stack，valid range:Single/Multiple, i.e -Vlanstack Single
#              (10)-Stack Stack required，Vlan stack Id，i.e -Stack 1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::CreateVlanHeader {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateVlanHeader..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateVlanHeader API \nexit the proc of CreateVlanHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateVlanHeader..."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "VlanHeader"

    set PduConfigList ""
        
    #Parse vlanID parameter
    set index [lsearch $args -vlanid] 
    if {$index != -1} {
        set vlanID [lindex $args [expr $index + 1]]
    } else  {
        error "please specify the vlanID of the port \nexit the proc of CreateVlanHeader..."
    }
    lappend PduConfigList -vlanID
    lappend PduConfigList $vlanID
    
    #Parse userPriority parameter
    set index [lsearch $args -userpriority] 
    if {$index != -1} {
        set userPriority [lindex $args [expr $index + 1]]
    } else  {
        set userPriority 0
    }

    lappend PduConfigList -userPriority
    lappend PduConfigList $userPriority
    
    #Parse cfi parameter
    set index [lsearch $args -cfi] 
    if {$index != -1} {
        set cfi [lindex $args [expr $index + 1]]
    } else  {
        set cfi 0
    }
    lappend PduConfigList -cfi
    lappend PduConfigList $cfi
    
    #Parse mode parameter
    set index [lsearch $args -mode] 
    if {$index != -1} {
        set mode [lindex $args [expr $index + 1]]
    } else  {
        set mode fixed
    }
    lappend PduConfigList -mode
    lappend PduConfigList $mode
    
    #Parse repeat parameter
    set index [lsearch $args -repeat] 
    if {$index != -1} {
        set repeat [lindex $args [expr $index + 1]]
    } else  {
        set repeat 10
    }
    lappend PduConfigList -repeat
    lappend PduConfigList $repeat
    
    #Parse step parameter
    set index [lsearch $args -step] 
    if {$index != -1} {
        set step [lindex $args [expr $index + 1]]
    } else  {
        set step 1
    }
    lappend PduConfigList -step
    lappend PduConfigList $step
    
    #Parse maskval parameter
    set index [lsearch $args -maskval] 
    if {$index != -1} {
        set maskval [lindex $args [expr $index + 1]]
    } else  {
        set maskval 4095
    }
    lappend PduConfigList -maskval
    lappend PduConfigList $maskval
    
    #Parse protocolTagId parameter
    set index [lsearch $args -protocoltagid] 
    if {$index != -1} {
        set protocolTagId [lindex $args [expr $index + 1]]
    } else  {
        set protocolTagId 8100
    }
    lappend PduConfigList -protocolTagId
    lappend PduConfigList $protocolTagId
    
    #Parse Vlanstack parameter
    set index [lsearch $args -vlanstack] 
    if {$index != -1} {
        set Vlanstack [lindex $args [expr $index + 1]]
    } else  {
        set Vlanstack Single
    }
    lappend PduConfigList -Vlanstack
    lappend PduConfigList $Vlanstack
    
    #Parse Stack parameter
    set index [lsearch $args -stack] 
    if {$index != -1} {
        set Stack [lindex $args [expr $index + 1]]
    } else  {
        set Stack 1
    }
    lappend PduConfigList -Stack
    lappend PduConfigList $Stack

    lappend ::mainDefine::gPduConfigList "$PduConfigList"

    debugPut "exit the proc of HeaderCreator::CreateVlanHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: ConfigVlanHeader
#Description: Config vlan header
#Input: 1. args:argument list，including
#              (1) -vlanID vlanID required,Vlan Id,i.e -vlanID 1
#              (2) -userPriority userPriority required，user priority，i.e -userPriority 0
#              (3) -cfi cfi required，Cfi value，i.e -cfi 0
#              (4) -mode mode required，Vlan value change mode，valid range:fixed/incr/decr/rand, i.e -mode fixed
#              (5) -repeat repeat optional，Vlan value change count，i.e -repeat 10
#              (6) -step step optional，Vlan step，i.e -step 1
#              (7) -maskval maskval optional，Vlan mask，i.e -maskval 0000
#              (8) -protocolTagId protocolTagId required，Vlan TPID，i.e -protocolTagId 8100
#              (9) -Vlanstack Vlanstack ，Vlan stack，valid range:Single/Multiple, i.e -Vlanstack Single
#              (10)-Stack Stack required，Vlan stack Id，i.e -Stack 1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::ConfigVlanHeader {args} {
   
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::ConfigVlanHeader..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateVlanHeader API \nexit the proc of CreateVlanHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index == -1} {
        error "PduName($PduName) does not exist \nexit the proc of ConfigVlanHeader..."
    } 
        
    #Parse vlanID parameter
    set index [lsearch $args -vlanid] 
    if {$index != -1} {
        set vlanID [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-vlanID" $vlanID
    } 

    #Parse userPriority parameter
    set index [lsearch $args -userpriority] 
    if {$index != -1} {
        set userPriority [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-userPriority" $userPriority
    }

    #Parse cfi parameter
    set index [lsearch $args -cfi] 
    if {$index != -1} {
        set cfi [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-cfi" $cfi
    } 

    #Parse mode parameter
    set index [lsearch $args -mode] 
    if {$index != -1} {
        set mode [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-mode" $mode
    }

    #Parse repeat parameter
    set index [lsearch $args -repeat] 
    if {$index != -1} {
        set repeat [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-repeat" $repeat
    }

    #Parse step parameter
    set index [lsearch $args -step] 
    if {$index != -1} {
        set step [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-step" $step
    }

    #Parse maskval parameter
    set index [lsearch $args -maskval] 
    if {$index != -1} {
        set maskval [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-maskval" $maskval
    } 

    #Parse protocolTagId parameter
    set index [lsearch $args -protocoltagid] 
    if {$index != -1} {
        set protocolTagId [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-protocolTagId" $protocolTagId
    } 

    #Parse Vlanstack parameter
    set index [lsearch $args -vlanstack] 
    if {$index != -1} {
        set Vlanstack [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-Vlanstack" $Vlanstack
    } 

    #Parse Stack parameter
    set index [lsearch $args -stack] 
    if {$index != -1} {
        set Stack [lindex $args [expr $index + 1]]
        ReplacePduAttrValue $PduName "-Stack" $Stack
    } 

    ApplyPduConfigToStreams $PduName

    debugPut "exit the proc of HeaderCreator::ConfigVlanHeader..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: DestroyPdu
#Description: Destroy PDUs created by HeaderCreator and PacketBuilder
#Input: 1. args:argument list, including
#              (1) -PduName PduName optional, name of the pdu,i.e -PduName head1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body HeaderCreator::DestroyPdu {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of HeaderCreator::DestroyPdu..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduNames [lindex $args [expr $index + 1]]
    } else  {
        set PduNames all
    }
    
    #Destroy Pdus
    if {[string tolower $PduNames] == "all"} {

        foreach PduName $::mainDefine::gPduNameList {
             unset PduName
       }

        set ::mainDefine::gPduNameList ""
        set ::mainDefine::gPduConfigList ""
        set ::mainDefine::gPduNameList ""

    } else {    
        foreach PduName $PduNames  {
              
             set index [lsearch $::mainDefine::gPduNameList $PduName] 
             if {$index != -1} {
                 set ::mainDefine::gPduNameList [lreplace $::mainDefine::gPduNameList $index $index ]
             }
             set index [lsearch $::mainDefine::gPduConfigList $PduName]  
             if {$index != -1} {
                  set ::mainDefine::gPduConfigList [lreplace $::mainDefine::gPduConfigList $index [expr $index + 2]]
             }
         }
    }
    
    debugPut "exit the proc of HeaderCreator::DestroyPdu..." 
    return $::mainDefine::gSuccess

}

############################################################################
#APIName: AddPOSHeaderIntoStream
#Description: Add POS header into stream
#Input: 
#              (1) args  argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body Stream::AddPOSHeaderIntoStream {args hStream pduName} {
    
    set streamBlock1 $hStream

    #Parse HdlcAddress parameter
    set index [lsearch $args -HdlcAddress] 
    if {$index != -1} {
        set HdlcAddress [lindex $args [expr $index + 1]]
    }

    #Parse HdlcControl parameter
    set index [lsearch $args -HdlcControl] 
    if {$index != -1} {
        set HdlcControl [lindex $args [expr $index + 1]]
    } 

    #Parse HdlcProtocol parameter
    set index [lsearch $args -HdlcProtocol] 
    if {$index != -1} {
        set HdlcProtocol [lindex $args [expr $index + 1]]
    } 
    
    #Create POS header, and configure parameters
    set pos1 [stc::create pos:POS -under $streamBlock1 ]
    stc::config $streamBlock1 -EnableStreamOnlyGeneration false
    stc::config $pos1 -address $HdlcAddress -control $HdlcControl -ProtocolType $HdlcProtocol
}

############################################################################
#APIName: CreatePOSHeader
#Description: According to input parameters, create POS header under the stream
#Input: 1. args:argument list, including
#              (1) -PduName PduName  mandatory，name of PDU, i.e -PduName pdu1
#              (2) -HdlcProtocol HdlcProtocol  optional, type of protocal, i.e -HdlcProtocol 0021
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body HeaderCreator::CreatePOSHeader {args} {
    
    #set the help infomation of API
    set index [lsearch $args -help]
    if {$index != -1} {
        puts "CreatePOSHeader API: "
        puts "-PduName PduName  mandatory，name of PDU，i.e -PduName pdu1"
        puts "-HdlcProtocol HdlcProtocol  optional，type of protocal，i.e -HdlcProtocol 0021"
        return $::gSuccess
    }

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreatePOSHeader ..."
    
    #Parse PduName parameter   
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateVlanHeader API \nexit the proc of CreatePOSHeader..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreatePOSHeader..."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "POSHeader"

    set PduConfigList ""
   
    #Parse HdlcAddress parameter
    set index [lsearch $args -hdlcaddress] 
    if {$index != -1} {
        set HdlcAddress [lindex $args [expr $index + 1]]
    } else  {
        set HdlcAddress "FF"
    }
    lappend PduConfigList -HdlcAddress
    lappend PduConfigList $HdlcAddress

    #Parse HdlcControl parameter
    set index [lsearch $args -hdlccontrol] 
    if {$index != -1} {
        set HdlcControl [lindex $args [expr $index + 1]]
    } else  {
        set HdlcControl "03"
    }
    lappend PduConfigList -HdlcControl
    lappend PduConfigList $HdlcControl
      
    #Parse HdlcProtocol parameter  
    set index [lsearch $args -hdlcprotocol] 
    if {$index != -1} {
        set HdlcProtocol [lindex $args [expr $index + 1]]
    } else  {
        set HdlcProtocol "0021"
    }
    lappend PduConfigList -HdlcProtocol
    lappend PduConfigList $HdlcProtocol
    

    lappend ::mainDefine::gPduConfigList "$PduConfigList"

    debugPut "exit the proc of HeaderCreator::CreatePOSHeader ..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: AddHDLCHeaderIntoStream
#Description: Add HDLC header into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle to specify certain stream
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body Stream::AddHDLCHeaderIntoStream {args hStream pduName} {
    
    set streamBlock1 $hStream

    #Parse HdlcAddress parameter
    set index [lsearch $args -HdlcAddress] 
    if {$index != -1} {
        set HdlcAddress [lindex $args [expr $index + 1]]
    }

    #Parse HdlcControl parameter
    set index [lsearch $args -HdlcControl] 
    if {$index != -1} {
        set HdlcControl [lindex $args [expr $index + 1]]
    } 

    #Parse HdlcProtocol parameter
    set index [lsearch $args -HdlcProtocol] 
    if {$index != -1} {
        set HdlcProtocol [lindex $args [expr $index + 1]]
    } 
    
    #Create POS header, and configure parameters
    set pos1 [stc::create hdlc:CiscoHDLC -under $streamBlock1 ]
    stc::config $streamBlock1 -EnableStreamOnlyGeneration false
    stc::config $pos1 -address $HdlcAddress -control $HdlcControl -ProtocolType $HdlcProtocol
}

############################################################################
#APIName: CreateHDLCHeader
#Description: According to input parameters,create pos header under the stream
#Input: 1. args:argument list，including
#              (1) -PduName PduName  mandatory，name of PDU，i.e -PduName pdu1
#              (2) -HdlcProtocol HdlcProtocol  optional, type of protocol, i.e -HdlcProtocol 0080
#Output: None
#Coded by: Tony
#############################################################################
::itcl::body HeaderCreator::CreateHDLCHeader {args} {
    
    #set the help infomation of API
    set index [lsearch $args -help]
    if {$index != -1} {
        puts "CreateHDLCHeader API: "
        puts "-PduName PduName  mandatory，name of PDU，i.e -PduName pdu1"
        puts "-HdlcProtocol HdlcProtocol  optional，type of protocol，i.e -HdlcProtocol 0080"
        return $::gSuccess
    }

    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]     
    debugPut "enter the proc of HeaderCreator::CreateHDLCHeader ..."
    
    #Parse PduName parameter  
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for HeaderCreator::CreateHDLCHeader API \nexit the proc of CreateHDLCHeader ..."
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one \nexit the proc of CreateHDLCHeader..."
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "HDLCHeader"

    set PduConfigList ""
   
    #Parse HdlcAddress parameter
    set index [lsearch $args -hdlcaddress] 
    if {$index != -1} {
        set HdlcAddress [lindex $args [expr $index + 1]]
    } else  {
        set HdlcAddress "0F"
    }
    lappend PduConfigList -HdlcAddress
    lappend PduConfigList $HdlcAddress

    #Parse HdlcControl parameter
    set index [lsearch $args -hdlccontrol] 
    if {$index != -1} {
        set HdlcControl [lindex $args [expr $index + 1]]
    } else  {
        set HdlcControl "00"
    }
    lappend PduConfigList -HdlcControl
    lappend PduConfigList $HdlcControl
      
    #Parse HdlcProtocol parameter
    set index [lsearch $args -hdlcprotocol] 
    if {$index != -1} {
        set HdlcProtocol [lindex $args [expr $index + 1]]
    } else  {
        set HdlcProtocol "0800"
    }
    lappend PduConfigList -HdlcProtocol
    lappend PduConfigList $HdlcProtocol
    

    lappend ::mainDefine::gPduConfigList "$PduConfigList"

    debugPut "exit the proc of HeaderCreator::CreateHDLCHeader ..." 
    return $::mainDefine::gSuccess
}
