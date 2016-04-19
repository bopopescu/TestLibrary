###########################################################################
#                                                                        
#  File Name：PacketBuilder.tcl                                                                                              
# 
#  Description：Defintion of STC Packet Builder class and its methods                                           
# 
#  Author： Jaimin.Wan
#
#  Create time:  2007.5.28
#
#  version：1.0 
# 
#  History： 
# 
##########################################################################

##########################################
#Definitioin of PacketBuilder class
##########################################  
::itcl::class PacketBuilder {

    #Variables
    public variable m_pduNameList ""

    #Constructor
    constructor {} {
          lappend ::mainDefine::gObjectNameList $this
          lappend ::mainDefine::gHeaderCreatorList $this 
    }
    
    #Destructor
    destructor {
         set index [lsearch $::mainDefine::gObjectNameList $this]
         set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]

         catch {
             if {$::mainDefine::gAutoDestroyPdu == "TRUE"} {
                 set ::mainDefine::gPktBuilderName $this
                 foreach pduName $m_pduNameList {
                     set ::mainDefine::gPduName $pduName
                     uplevel 1 {
                         $::mainDefine::gPktBuilderName DestroyPdu -PduName $::mainDefine::gPduName
                     }  
                 }
             }
         }
    }
    
    #Methods
    public method CreateARPPkt
    public method CreateRipPkt
    public method CreateRipngPkt
    public method CreateOspfv2Pkt
    public method CreateICMPPkt
    public method CreateIcmpv6Pkt
    public method CreateCustomPkt    
    public method CreateDHCPPkt   
    public method CreateGREPkt
    public method CreatePIMPkt
    public method CreatePPPoEPkt
    public method CreateIGMPPkt 
    public method CreateMLDPkt 

    public method DestroyPdu
}

############################################################################
#APIName: DestroyPdu
#Description: Destroy Pdu, and it can not be used by any stream
#Input: 1. args:argument list, including
#              (1) -PduName PduName optional, name of the pdu,i.e -PduName head1
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body PacketBuilder::DestroyPdu {args} {
    
    #Convert attribute of input parameters to lower case
    set args [ConvertAttrToLowerCase $args]    
    debugPut "enter the proc of PacketBuilder::DestroyPdu..."
    
    #Parse PduName parameter
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduNames [lindex $args [expr $index + 1]]
    } else  {
        set PduNames all
    }
    
    #Destroy associated pdu 
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
    
    debugPut "exit the proc of PacketBuilder::DestroyPdu..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: CreateGREPkt
#Description: Create GRE packet
#Input: 1. args:argument list, including
#              (1) -version version required，GRE packet version，i.e -version 1
#              (2) -protocolType protocolType required，protocol type，i.e -protocolType 0800
#              (3) -checksumPresent checksumPresent optional，checksum status bit，valid range: 0/1，i.e -checksumPresent 0
#              (4) -keyPresent keyPresent optional，key status bit，valid range:0/1，i.e -keyPresent 0 
#              (5) -sequencePresent sequencePresent optional，sequence status bit，valid range:0/1，i.e  -sequencePresent 0 
#              (6) -checksum checksum optional，checksum list，format{reserved value}，i.e -checksum {0 0}
#              (7) -key key optional，key list,i.e -key 0 
#              (8) -sequence sequence optional，sequence list,i.e -sequence 0 
#Output: None
#Coded by: Jaimin Wan
#############################################################################
::itcl::body PacketBuilder::CreateGREPkt {args} {
    
    debugPut "enter the proc of PacketBuilder::CreateGREPkt..."
    
    #Parse PduName parameter    
    set index [lsearch $args -PduName] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateGREPkt API "
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "GREPacket"
    set PduConfigList ""
    
    #Parse version parameter    
    set index [lsearch $args -version] 
    if {$index != -1} {
        set version [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify version for PacketBuilder::CreateGREPkt API "
    }
    lappend PduConfigList -version
    lappend PduConfigList $version
    
    #Parse protocolType parameter    
    set index [lsearch $args -protocolType] 
    if {$index != -1} {
        set protocolType [lindex $args [expr $index + 1]]
        set protocolType [string map {0x ""} $protocolType]
    } else  {
        error "Please specify protocolType for PacketBuilder::CreateGREPkt API "
    }
    lappend PduConfigList -protocolType
    lappend PduConfigList $protocolType
    
    #Parse checksumPresent parameter    
    set index [lsearch $args -checksumPresent] 
    if {$index != -1} {
        set checksumPresent [lindex $args [expr $index + 1]]
    } else  {
        set checksumPresent 0
    }
    lappend PduConfigList -checksumPresent
    lappend PduConfigList $checksumPresent
    
    #Parse keyPresent parameter    
    set index [lsearch $args -keyPresent] 
    if {$index != -1} {
        set keyPresent [lindex $args [expr $index + 1]]
    } else  {
        set keyPresent 0
    }
    lappend PduConfigList -keyPresent
    lappend PduConfigList $keyPresent
    
    #Parse sequencePresent parameter    
    set index [lsearch $args -sequencePresent] 
    if {$index != -1} {
        set sequencePresent [lindex $args [expr $index + 1]]
    } else  {
        set sequencePresent 0
    }
    lappend PduConfigList -sequencePresent
    lappend PduConfigList $sequencePresent
    
    #Parse checksum parameter    
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    } else  {
        set checksum "0 0"
    }
    lappend PduConfigList -checksum
    lappend PduConfigList $checksum
    
    #Parse key parameter    
    set index [lsearch $args -key] 
    if {$index != -1} {
        set key [lindex $args [expr $index + 1]]
    } else  {
        set key 0
    }
    lappend PduConfigList -key
    lappend PduConfigList $key
    
    #Parse sequence parameter    
    set index [lsearch $args -sequence] 
    if {$index != -1} {
        set sequence [lindex $args [expr $index + 1]]
    } else  {
        set sequence 0
    } 
    lappend PduConfigList -sequence
    lappend PduConfigList $sequence
 
    lappend ::mainDefine::gPduConfigList "$PduConfigList"   
    
    debugPut "exit the proc of PacketBuilder::CreateGREPkt..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: AddGREPacketIntoStream
#Description: Add GRE packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddGREPacketIntoStream {args hStream pduName} { 
    
    set streamBlock1 $hStream
    #Parse version parameter    
    set index [lsearch $args -version] 
    if {$index != -1} {
        set version [lindex $args [expr $index + 1]]
    } 
    
    #Parse protocolType parameter    
    set index [lsearch $args -protocolType] 
    if {$index != -1} {
        set protocolType [lindex $args [expr $index + 1]]
        
    }
    
    #Parse checksumPresent parameter    
    set index [lsearch $args -checksumPresent] 
    if {$index != -1} {
        set checksumPresent [lindex $args [expr $index + 1]]
    }
    
    #Parse keyPresent parameter    
    set index [lsearch $args -keyPresent] 
    if {$index != -1} {
        set keyPresent [lindex $args [expr $index + 1]]
    }
    
    #Parse sequencePresent parameter    
    set index [lsearch $args -sequencePresent] 
    if {$index != -1} {
        set sequencePresent [lindex $args [expr $index + 1]]
    } 
    
    #Parse checksum parameter    
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set checksum [lindex $args [expr $index + 1]]
    } 
    
    #Parse key parameter    
    set index [lsearch $args -key] 
    if {$index != -1} {
        set key [lindex $args [expr $index + 1]]
    }
    
    #Parse sequence parameter    
    set index [lsearch $args -sequence] 
    if {$index != -1} {
        set sequence [lindex $args [expr $index + 1]]
    }
    
    set gre1 [stc::create gre:Gre -under $streamBlock1]
    #Store the packet header
    lappend m_PduNameList $pduName
    set m_PduHandleList($pduName) $gre1

    stc::config $gre1 -protocolType $protocolType -version $version -ckPresent $checksumPresent \
        -keyPresent $keyPresent -seqNumPresent $sequencePresent 
    if {$checksumPresent ==1} {
        set checksums1 [stc::create checksums -under $gre1]
        set checksum1 [stc::create GreChecksum -under $checksums1]
        stc::config $checksum1 -reserved [lindex $checksum 0] -value [lindex $checksum 1]    
    }
    if {$keyPresent ==1} {
        set keys1 [stc::create keys -under $gre1]
        set ikey1 [stc::create GreKey -under $keys1]
        stc::config $ikey1 -value $key 
    
    }
    if {$sequencePresent ==1} {
        set seqNums1 [stc::create seqNums -under $gre1]
        set seqNum1 [stc::create GreSeqNum -under $seqNums1]
        stc::config $seqNum1 -value $sequence     
    }
}  

############################################################################
#APIName: CreateDHCPPkt
#Description: Create GRE packet
#Input: 1. args:argument list, including
#              (1) -op op required，operation code，i.e -op 1
#              (2) -htype htype required，hardware address type，i.e -htype 6
#              (3) -hlen hlen required，hardware address length，i.e -hlen 6
#              (4) -hops hops required，hops，i.e -hops 0 
#              (5) -xid xid required，transanction id，i.e -xid  1 
#              (6) -secs secs required，seconds，i.e -secs 1
#              (7) -bflag bflag required，braodcast flag，i.e -bflag 1 
#              (8) -mbz15 mbz15 required，broadcast bit，i.e -mbz15 000000000000000 
#              (9) -ciaddr ciaddr required，client IP address，i.e -ciaddr 192.85.1.3 
#              (10) -yiaddr yiaddr required，tester IP address，i.e -yiaddr 192.85.1.4 
#              (11) -siaddr siaddr required，server IP address，i.e -siaddr 192.85.1.5
#              (12) -giaddr giaddr required，agent IP address，i.e -giaddr 192.85.1.6
#              (13) -chaddr chaddr required，client hardware address，i.e -chaddr 192.85.1.7
#              (14) -sname sname optional，server name，i.e -sname 0000
#              (15) -file file optional，DHCPoptional/start file name，i.e -file 0000
#              (16) -option option optional，option parameter，packet type，1:Discover 2:Offer 3:Request 4:Decline 5:Ack 6:Nak 7:Release 8:Inform，i.e -option clientIdHW
#Output: None
#Coded by: Jaimin Wan 
#############################################################################
::itcl::body PacketBuilder::CreateDHCPPkt {args} {
    
    debugPut "enter the proc of PacketBuilder::CreateDHCPPkt..."
    set args [ConvertAttrToLowerCase $args]   

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateDHCPPkt API "
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "DHCPPacket"
    set PduConfigList ""
    
    #Parse op parameter    
    set index [lsearch $args -op] 
    if {$index != -1} {
        set op [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify op for PacketBuilder::CreateDHCPPkt API "
    } 

    lappend PduConfigList -op
    lappend PduConfigList $op
    
    #Parse htype parameter    
    set index [lsearch $args -htype] 
    if {$index != -1} {
        set htype [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify htype for PacketBuilder::CreateDHCPPkt API "
    }
    
    lappend PduConfigList -htype
    lappend PduConfigList $htype

    #Parse hlen parameter    
    set index [lsearch $args -hlen] 
    if {$index != -1} {
        set hlen [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify hlen for PacketBuilder::CreateDHCPPkt API "
    }
 
    lappend PduConfigList -hlen
    lappend PduConfigList $hlen
    
    #Parse hops parameter    
    set index [lsearch $args -hops] 
    if {$index != -1} {
        set hops [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify hops for PacketBuilder::CreateDHCPPkt API "
    }
 
    lappend PduConfigList -hops
    lappend PduConfigList $hops
    
    #Parse xid parameter    
    set index [lsearch $args -xid] 
    if {$index != -1} {
        set xid [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify xid for PacketBuilder::CreateDHCPPkt API "
    }

    lappend PduConfigList -xid
    lappend PduConfigList $xid
    
    #Parse secs parameter    
    set index [lsearch $args -secs] 
    if {$index != -1} {
        set secs [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify secs for PacketBuilder::CreateDHCPPkt API "
    }
 
    lappend PduConfigList -secs
    lappend PduConfigList $secs
    
    #Parse bflag parameter    
    set index [lsearch $args -bflag] 
    if {$index != -1} {
        set bflag [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify bflag for PacketBuilder::CreateDHCPPkt API "
    }

    lappend PduConfigList -bflag
    lappend PduConfigList $bflag

    
    #Parse mbz15 parameter    
    set index [lsearch $args -mbz15] 
    if {$index != -1} {
        set mbz15 [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify mbz15 for PacketBuilder::CreateDHCPPkt API "
    }

    lappend PduConfigList -mbz15
    lappend PduConfigList $mbz15
    
    #Parse ciaddr parameter    
    set index [lsearch $args -ciaddr] 
    if {$index != -1} {
        set ciaddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify ciaddr for PacketBuilder::CreateDHCPPkt API "
    }
 
    lappend PduConfigList -ciaddr
    lappend PduConfigList $ciaddr
    
    #Parse yiaddr parameter    
    set index [lsearch $args -yiaddr] 
    if {$index != -1} {
        set yiaddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify yiaddr for PacketBuilder::CreateDHCPPkt API "
    }
  
    lappend PduConfigList -yiaddr
    lappend PduConfigList $yiaddr

    
    #Parse siaddr parameter    
    set index [lsearch $args -siaddr] 
    if {$index != -1} {
        set siaddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify siaddr for PacketBuilder::CreateDHCPPkt API "
    }
    lappend PduConfigList -siaddr
    lappend PduConfigList $siaddr 

    #Parse giaddr parameter    
    set index [lsearch $args -giaddr] 
    if {$index != -1} {
        set giaddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify giaddr for PacketBuilder::CreateDHCPPkt API "
    }
    lappend PduConfigList -giaddr
    lappend PduConfigList $giaddr

    #Parse chaddr parameter    
    set index [lsearch $args -chaddr] 
    if {$index != -1} {
        set chaddr [lindex $args [expr $index + 1]]
        set chaddr [string map {" " :} $chaddr]
    } else  {
        error "Please specify chaddr for PacketBuilder::CreateDHCPPkt API "
    }
    lappend PduConfigList -chaddr
    lappend PduConfigList $chaddr
    
    #Parse sname parameter    
    set index [lsearch $args -sname] 
    if {$index != -1} {
        set sname [lindex $args [expr $index + 1]]
    } else  {
        set sname "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    }

    lappend PduConfigList -sname
    lappend PduConfigList $sname
    
    #Parse file parameter    
    set index [lsearch $args -file] 
    if {$index != -1} {
        set file [lindex $args [expr $index + 1]]
    } else  {
        set file "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    }
    lappend PduConfigList -file
    lappend PduConfigList $file
    
    #Parse option parameter    
    set index [lsearch $args -option] 
    if {$index != -1} {
        set option [lindex $args [expr $index + 1]]
    } else  {
        set option {messageType 1}
    }
    lappend PduConfigList -option
    lappend PduConfigList $option

 
    lappend ::mainDefine::gPduConfigList "$PduConfigList"

    debugPut "exit the proc of PacketBuilder::CreateDHCPPkt..." 
    return $::mainDefine::gSuccess
}

############################################################################
#APIName: AddDHCPPacketIntoStream
#Description: Add DHCP packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Jaimin
#############################################################################
::itcl::body Stream::AddDHCPPacketIntoStream {args hStream pduName} {
    
    set streamBlock1 $hStream 
    #Parse op parameter    
    set index [lsearch $args -op] 
    if {$index != -1} {
        set op [lindex $args [expr $index + 1]]
    } 
    
    #Parse htype parameter    
    set index [lsearch $args -htype] 
    if {$index != -1} {
        set htype [lindex $args [expr $index + 1]]
    }
    
    #Parse hlen parameter    
    set index [lsearch $args -hlen] 
    if {$index != -1} {
        set hlen [lindex $args [expr $index + 1]]
    } 
    
    #Parse hops parameter    
    set index [lsearch $args -hops] 
    if {$index != -1} {
        set hops [lindex $args [expr $index + 1]]
    }
    
    #Parse xid parameter    
    set index [lsearch $args -xid] 
    if {$index != -1} {
        set xid [lindex $args [expr $index + 1]]
    }
    
    #Parse secs parameter    
    set index [lsearch $args -secs] 
    if {$index != -1} {
        set secs [lindex $args [expr $index + 1]]
    }
    
    #Parse bflag parameter    
    set index [lsearch $args -bflag] 
    if {$index != -1} {
        set bflag [lindex $args [expr $index + 1]]
    }
    
    #Parse mbz15 parameter    
    set index [lsearch $args -mbz15] 
    if {$index != -1} {
        set mbz15 [lindex $args [expr $index + 1]]
    }
    
    #Parse ciaddr parameter    
    set index [lsearch $args -ciaddr] 
    if {$index != -1} {
        set ciaddr [lindex $args [expr $index + 1]]
    }
    
    #Parse yiaddr parameter    
    set index [lsearch $args -yiaddr] 
    if {$index != -1} {
        set yiaddr [lindex $args [expr $index + 1]]
    }
    
    #Parse siaddr parameter    
    set index [lsearch $args -siaddr] 
    if {$index != -1} {
        set siaddr [lindex $args [expr $index + 1]]
    }
    
    #Parse giaddr parameter    
    set index [lsearch $args -giaddr] 
    if {$index != -1} {
        set giaddr [lindex $args [expr $index + 1]]
    }
    
    #Parse chaddr parameter    
    set index [lsearch $args -chaddr] 
    if {$index != -1} {
        set chaddr [lindex $args [expr $index + 1]]
    }
    
    #Parse sname parameter    
    set index [lsearch $args -sname] 
    if {$index != -1} {
        set sname [lindex $args [expr $index + 1]]
    }
    
    #Parse file parameter    
    set index [lsearch $args -file] 
    if {$index != -1} {
        set file [lindex $args [expr $index + 1]]
    }
    
    #Parse option parameter    
    set index [lsearch $args -option] 
    if {$index != -1} {
        set option [lindex $args [expr $index + 1]]
    }
    
    if {$op ==1} {
        set dhcpclient1 [stc::create dhcp:Dhcpclientmsg -under $streamBlock1]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $dhcpclient1

        stc::config $dhcpclient1 -messageType 1 -hardwareType $htype -haddrLen $hlen -hops $hops -xid $xid -elapsed $secs \
            -clientAddr $ciaddr -yourAddr $yiaddr -nextservAddr $siaddr -relayagentAddr $giaddr \
            -clientMac $chaddr -serverhostname $sname -bootfilename $file
        if {$bflag ==1} {
            set flags1 1$mbz15
            set bootpflags1 0
            for {set i 0} {$i <16} {incr i} {
                set bootpflags1 [expr $bootpflags1+[string index $flags1 $i]*pow(2,[expr 15-$i])]            
            }
            set bootpflags1 [format %x [expr int($bootpflags1)]]
            stc::config $dhcpclient1 -bootpflags $bootpflags1            
        } elseif {$bflag ==0} {
            set flags1 0$mbz15
            set bootpflags1 0
            for {set i 0} {$i <16} {incr i} {
                set bootpflags1 [expr $bootpflags1+[string index $flags1 $i]*pow(2,[expr 15-$i])]            
            }
            set bootpflags1 [format %x [expr int($bootpflags1)]]
            stc::config $dhcpclient1 -bootpflags $bootpflags1            
        } else {
            error "flags bit should be 0/1, your set is $flags, please set another one."
        }
        set option1 [stc::create options -under $dhcpclient1]
        set dhcpoption1 [stc::create DHCPOption -under $option1]
        #1:Discover 2:Offer 3:Request 4:Decline 5:Ack 6:Nak 7:Release 8:Inform (1,3,4,7,8为client,其他为server)
        set index [lsearch [string tolower $option] messagetype]
        if {$index != -1} {
            set code [lindex $option [expr $index + 1]]
            if {($code ==2) ||($code ==5) ||($code ==6)} {
                error "When op type is 1(client),messagetype must be 1/3/4/7/8."
            }
            set msgtype1 [stc::create messageType -under $dhcpoption1]
            stc::config $msgtype1 -code $code 
        }              
    } elseif {$op == 2} {
        set dhcpserver1 [stc::create dhcp:Dhcpservermsg -under $streamBlock1]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $dhcpserver1

        stc::config $dhcpserver1 -messageType 2 -hardwareType $htype -haddrLen $hlen -hops $hops -xid $xid -elapsed $secs \
            -clientAddr $ciaddr -yourAddr $yiaddr -nextservAddr $siaddr -relayagentAddr $giaddr \
            -clientMac $chaddr -serverhostname $sname -bootfilename $file
        if {$bflag ==1} {
            set flags1 1$mbz15
            set bootpflags1 0
            for {set i 0} {$i <16} {incr i} {
                set bootpflags1 [expr $bootpflags1+[string index $flags1 $i]*pow(2,[expr 15-$i])]            
            }
            set bootpflags1 [format %x [expr int($bootpflags1)]]
            stc::config $dhcpserver1 -bootpflags $bootpflags1            
        } elseif {$bflag ==0} {
            set flags1 0$mbz15
            set bootpflags1 0
            for {set i 0} {$i <16} {incr i} {
                set bootpflags1 [expr $bootpflags1+[string index $flags1 $i]*pow(2,[expr 15-$i])]            
            }
            set bootpflags1 [format %x [expr int($bootpflags1)]]
            stc::config $dhcpserver1 -bootpflags $bootpflags1            
        } else {
            error "flags bit should be 0/1, your set is $flags, please set another one."
        }
        set option1 [stc::create options -under $dhcpserver1]
        set dhcpoption1 [stc::create DHCPOption -under $option1]
        #1:Discover 2:Offer 3:Request 4:Decline 5:Ack 6:Nak 7:Release 8:Inform (1,3,4,7,8为client,其他为server)
        set index [lsearch [string tolower $option] messagetype]
        if {$index != -1} {
            set code [lindex $option [expr $index + 1]]
            if {($code !=2) && ($code !=5) && ($code !=6)} {
                error "When op type is 2(server),messagetype must be 2/5/6"
            }
            set msgtype1 [stc::create messageType -under $dhcpoption1]
            stc::config $msgtype1 -code $code 
        }
                 
    } else {
        error "DHCP Op type should be 1/2,your set is $op, please set another one"    
    }

    set index [lsearch [string tolower $option] message]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption2 [stc::create DHCPOption -under $option1]
        set msg1 [stc::create message -under $dhcpoption2]
        stc::config $msg1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] messagesize]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption3 [stc::create DHCPOption -under $option1]
        set msgsize1 [stc::create messageSize -under $dhcpoption3]
        stc::config $msgsize1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] optionoverload]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption4 [stc::create DHCPOption -under $option1]
        set overload1 [stc::create optionOverload -under $dhcpoption4]
        stc::config $overload1 -overload $opvalue 
    }
    set index [lsearch [string tolower $option] paramreqlist]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption5 [stc::create DHCPOption -under $option1]
        set reqlist1 [stc::create paramReqList -under $dhcpoption5]
        stc::config $reqlist1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] reqaddr]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption6 [stc::create DHCPOption -under $option1]
        set reqaddr1 [stc::create reqAddr -under $dhcpoption6]
        stc::config $reqaddr1 -reqAddr $opvalue 
    }
    set index [lsearch [string tolower $option] serverid]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption7 [stc::create DHCPOption -under $option1]
        set ireqAddr1 [stc::create serverId -under $dhcpoption7 ]
        stc::config $ireqAddr1 -reqAddr $opvalue 
    }
    set index [lsearch [string tolower $option] clientidhw]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption8 [stc::create DHCPOption -under $option1]
        set clienthw1 [stc::create clientIdHW -under $dhcpoption8]
        stc::config $clienthw1 -clientHWA $opvalue 
    }
    set index [lsearch [string tolower $option] clientidnonhw]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption9 [stc::create DHCPOption -under $option1]
        set clientnohw1 [stc::create clientIdnonHW -under $dhcpoption9]
        stc::config $clientnohw1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] customoption]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption10 [stc::create DHCPOption -under $option1]
        set cusoption1 [stc::create customOption -under $dhcpoption10]
        stc::config $cusoption1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] endofoptions]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption11 [stc::create DHCPOption -under $option1]
        set endop1 [stc::create endOfOptions -under $dhcpoption11]
        stc::config $endop1 -type $opvalue 
    }
    set index [lsearch [string tolower $option] hostname]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption12 [stc::create DHCPOption -under $option1]
        set hostname1 [stc::create hostName -under $dhcpoption12]
        stc::config $hostname1 -value $opvalue 
    }
    set index [lsearch [string tolower $option] leasetime]
    if {$index != -1} {
        set opvalue [lindex $option [expr $index + 1]]
        set dhcpoption13 [stc::create DHCPOption -under $option1]
        set leasetime1 [stc::create leaseTime -under $dhcpoption13]
        stc::config $leasetime1 -leaseTime $opvalue 
    }
}
   
############################################################################
#APIName: CreateARPPkt
#
#Description: Create ARP packet
#
#Input: arp protocol related details please refer to the user guide.
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateARPPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateARPPkt"
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateARPPkt API "
    }
    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList  "
    }
 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "ArpPacket"
    set PduConfigList ""

     set args [string tolower $args]
     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args    

    #Parse operation
    set index [lsearch $args -operation] 
    if {$index != -1} {
        set operation [lindex $args [expr $index + 1]]
    } else  {
        set operation  "arpRequest"
    }  
    lappend PduConfigList -operation
    lappend PduConfigList $operation

    #Parse sourcehardwareaddr
    set index [lsearch $args -sourcehardwareaddr] 
    if {$index != -1} {
        set sourcehardwareaddr [lindex $args [expr $index + 1]]
    } else  {
        set sourcehardwareaddr  00:00:01:00:00:02
    }
    lappend PduConfigList -sourcehardwareaddr
    lappend PduConfigList $sourcehardwareaddr

    #Parse sourceprotocoladdr
    set index [lsearch $args -sourceprotocoladdr] 
    if {$index != -1} {
        set sourceprotocoladdr [lindex $args [expr $index + 1]]
    } else  {
        set sourceprotocoladdr  0.0.0.0
    }
    lappend PduConfigList -sourceprotocoladdr
    lappend PduConfigList $sourceprotocoladdr

    #Parse desthardwareaddr
    set index [lsearch $args -desthardwareaddr ] 
    if {$index != -1} {
        set desthardwareaddr  [lindex $args [expr $index + 1]]
    } else  {
        set desthardwareaddr   00:00:00:00:00:00
    } 
    lappend PduConfigList -desthardwareaddr
    lappend PduConfigList $desthardwareaddr

    #Parse destprotocoladdr
    set index [lsearch $args -destprotocoladdr] 
    if {$index != -1} {
        set destprotocoladdr [lindex $args [expr $index + 1]]
    } else  {
        set destprotocoladdr  0.0.0.0
    }
    lappend PduConfigList -destprotocoladdr
    lappend PduConfigList $destprotocoladdr

    #Parse sourceprotocoladdrmode
    set index [lsearch $args -sourceprotocoladdrmode] 
    if {$index != -1} {
        set sourceprotocoladdrmode [lindex $args [expr $index + 1]]
    } else  {
        set sourceprotocoladdrmode  fixed
    }
    lappend PduConfigList -sourceprotocoladdrmode
    lappend PduConfigList $sourceprotocoladdrmode

    #Parse destprotocoladdrmode
    set index [lsearch $args -destprotocoladdrmode] 
    if {$index != -1} {
        set destprotocoladdrmode [lindex $args [expr $index + 1]]
    } else  {
        set destprotocoladdrmode  fixed
    }
    lappend PduConfigList -destprotocoladdrmode
    lappend PduConfigList $destprotocoladdrmode

    #Parse desthardwareaddrmode
    set index [lsearch $args -desthardwareaddrmode ] 
    if {$index != -1} {
        set desthardwareaddrmode  [lindex $args [expr $index + 1]]
    } else  {
        set desthardwareaddrmode   fixed
    }
    lappend PduConfigList -desthardwareaddrmode
    lappend PduConfigList $desthardwareaddrmode

    #Parse sourcehardwareaddrmode       
    set index [lsearch $args -sourcehardwareaddrmode] 
    if {$index != -1} {
        set sourcehardwareaddrmode [lindex $args [expr $index + 1]]
    } else  {
        set sourcehardwareaddrmode  fixed
    }
    lappend PduConfigList -sourcehardwareaddrmode
    lappend PduConfigList $sourcehardwareaddrmode

    #Parse sourceprotocoladdrrepeatcount
    set index [lsearch $args -sourceprotocoladdrrepeatcount] 
    if {$index != -1} {
        set sourceprotocoladdrrepeatcount [lindex $args [expr $index + 1]]
    } else  {
        set sourceprotocoladdrrepeatcount  1
    }
    lappend PduConfigList -sourceprotocoladdrrepeatcount
    lappend PduConfigList $sourceprotocoladdrrepeatcount

    #Parse destprotocoladdrpepeatcount    
    set index [lsearch $args -destprotocoladdrrepeatcount] 
    if {$index != -1} {
        set destprotocoladdrrepeatcount [lindex $args [expr $index + 1]]
    } else  {
        set destprotocoladdrrepeatcount  1
    }
    lappend PduConfigList -destprotocoladdrrepeatcount
    lappend PduConfigList $destprotocoladdrrepeatcount

    #Parse sourcehardwareaddrrepeatcount
    set index [lsearch $args -sourcehardwareaddrrepeatcount ] 
    if {$index != -1} {
        set sourcehardwareaddrrepeatcount  [lindex $args [expr $index + 1]]
    } else  {
        set sourcehardwareaddrrepeatcount   1
    } 
    lappend PduConfigList -sourcehardwareaddrrepeatcount
    lappend PduConfigList $sourcehardwareaddrrepeatcount

    #Parse desthardwareaddrrepeatcount       
    set index [lsearch $args -desthardwareaddrrepeatcount] 
    if {$index != -1} {
        set desthardwareaddrrepeatcount [lindex $args [expr $index + 1]]
    } else  {
        set desthardwareaddrrepeatcount  1
    }
    lappend PduConfigList -desthardwareaddrrepeatcount
    lappend PduConfigList $desthardwareaddrrepeatcount

    #Parse sourceprotocoladdrrepeatstep
    set index [lsearch $args -sourceprotocoladdrrepeatstep] 
    if {$index != -1} {
        set sourceprotocoladdrrepeatstep [lindex $args [expr $index + 1]]
    } else  {
        set sourceprotocoladdrrepeatstep  0.0.0.1
    }
    lappend PduConfigList -sourceprotocoladdrrepeatstep
    lappend PduConfigList $sourceprotocoladdrrepeatstep

    #Parse destprotocoladdrrepeatstep
    set index [lsearch $args -destprotocoladdrrepeatstep] 
    if {$index != -1} {
        set destprotocoladdrrepeatstep [lindex $args [expr $index + 1]]
    } else  {
        set destprotocoladdrrepeatstep 0.0.0.1
    }
    lappend PduConfigList -destprotocoladdrrepeatstep
    lappend PduConfigList $destprotocoladdrrepeatstep

    #Parse sourcehardwareaddrrepeatstep
    set index [lsearch $args -sourcehardwareaddrrepeatstep ] 
    if {$index != -1} {
        set sourcehardwareaddrrepeatstep  [lindex $args [expr $index + 1]]
    } else  {
        set sourcehardwareaddrrepeatstep   00-00-00-00-00-01
    } 
    lappend PduConfigList -sourcehardwareaddrrepeatstep
    lappend PduConfigList $sourcehardwareaddrrepeatstep

    #Parse desthardwareaddrrepeatstep       
    set index [lsearch $args -desthardwareaddrrepeatstep] 
    if {$index != -1} {
        set desthardwareaddrrepeatstep [lindex $args [expr $index + 1]]
    } else  {
        set desthardwareaddrrepeatstep  00-00-00-00-00-01
    }
    lappend PduConfigList -desthardwareaddrrepeatstep
    lappend PduConfigList $desthardwareaddrrepeatstep    

    lappend ::mainDefine::gPduConfigList "$PduConfigList"    
  
    debugPut "enter the proc of PacketBuilder::CreateARPPkt"    
    return $::mainDefine::gSuccess
                         
}

############################################################################
#APIName: CreateRipPkt
#
#Description: Create Rip Packet
#
#Input: For the details please refer to the user manual
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateRipPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateRipPkt"    
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateRipPkt API "
    }    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    #Store RipPkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "RipPacket"

     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args
     set args [string tolower $args]
     
    lappend ::mainDefine::gPduConfigList $args

    return $::mainDefine::gSuccess
    debugPut "exit the proc of PacketBuilder::CreateRipPkt"
    
}

############################################################################
#APIName: CreateRipngPkt
#
#Description: Create Ripng packet
#
#Input: For the details please refer to the user guide
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateRipngPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateRipngPkt"  
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateRipngPkt API "
    }    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    #Store RipngPkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "RipngPacket"

     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args  
     set args [string tolower $args]
     
    lappend ::mainDefine::gPduConfigList $args

    return $::mainDefine::gSuccess
    debugPut "enter the proc of PacketBuilder::CreateRipngPkt"
    
}
############################################################################
#APIName: CreateOspfv2Pkt
#
#Description: Create ospfv2 packet
#
#Input: For the details please refer to the user manual
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateOspfv2Pkt {args} {
    
    debugPut "enter the proc of PacketBuilder::CreateOspfv2Pkt"
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateRipngPkt API "
    }    
    set args [lreplace $args $index [expr $index + 1]]
    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    
    #Store Ospfv2Pkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "Ospfv2Packet"     

     set args [string tolower $args]
     set ::mainDefine::args $args
     if {0} {
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args   
     }
     
    lappend ::mainDefine::gPduConfigList $args  
    
    debugPut "exit the proc of PacketBuilder::CreateOspfv2Pkt"
    return $::mainDefine::gSuccess
    
}

############################################################################
#APIName: CreateICMPPkt
#
#Description: Create ICMP packet
#
#Input: For the details please refer to the user manual
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateICMPPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateICMPPkt"
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateICMPPkt API "
    }    
    set args [lreplace $args $index [expr $index + 1]]
    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) already exists,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    #Store IcmpPkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "IcmpPacket"    

     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args   

    set args [string tolower $args]

    lappend ::mainDefine::gPduConfigList $args
    
    debugPut "exit the proc of PacketBuilder::CreateICMPPkt"
    return $::mainDefine::gSuccess
     
}
############################################################################
#APIName: CreateIcmpv6Pkt
#
#Description: Create ICMPv6 packet
#
#Input: For the details please refer to the user manual
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateIcmpv6Pkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateIcmpv6Pkt"
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateIcmpv6Pkt API "
    }    
    set args [lreplace $args $index [expr $index + 1]]
    
    #Check whether or not PduName is unique
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 

    #Store Icmpv6Pkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "Icmpv6Packet"
     
     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args   
    
     set args [string tolower $args]
    lappend ::mainDefine::gPduConfigList $args

    debugPut "exit the proc of PacketBuilder::CreateIcmpv6Pkt"
    return $::mainDefine::gSuccess 
}

############################################################################
#APIName: CreateCustomPkt
#
#Description: Create Custom packet
#
#Input: 1.PduName: name of the pdu
#          2.pattern:custom packet content 
#
#Output: None
#
#Coded by: David.Wu
#############################################################################
::itcl::body PacketBuilder::CreateCustomPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreateCustomPkt"     
    set args [ConvertAttrToLowerCase $args]  

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateRipngPkt API "
    }    
    set args [lreplace $args $index [expr $index + 1]]
        
    #Check whether or not PduName is unique 
    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one,the existed PduName(s) is(are):\n$::mainDefine::gPduNameList "
    } 
    #Store CustomPkt parameter
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "CustomPacket"    

     set ::mainDefine::args $args
     uplevel 1 {
         set ::mainDefine::args [subst $::mainDefine::args]
     }
     set args $::mainDefine::args     
     set args [string tolower $args]
     
    lappend ::mainDefine::gPduConfigList $args
            
    debugPut "enter the proc of PacketBuilder::CreateCustomPkt"    
    return $::mainDefine::gSuccess     
}
############################################################################
#APIName: AddArpPacketIntoStream
#Description: Add ARP packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddArpPacketIntoStream {args hStream pduName} { 

    debugPut "enter the proc of AddArpPacketIntoStream" 
    set streamBlock1 $hStream
   
    #Parse sourceprotocoladdr parameter    
    set index [lsearch $args -sourceprotocoladdr] 
    if {$index != -1} {
        set sourceprotocoladdr [lindex $args [expr $index + 1]]
    } 
    
    #Parse destprotocoladdr parameter    
    set index [lsearch $args -destprotocoladdr] 
    if {$index != -1} {
        set destprotocoladdr [lindex $args [expr $index + 1]]
    }
    
    #Parse operation parameter    
    set index [lsearch $args -operation] 
    if {$index != -1} {
        set operation [lindex $args [expr $index + 1]]
    }
    
    #Parse sourcehardwareaddr parameter  
    set index [lsearch $args -sourcehardwareaddr] 
    if {$index != -1} {
        set sourcehardwareaddr [lindex $args [expr $index + 1]]
    }
    set sourcehardwareaddr [string map {"-" :} $sourcehardwareaddr]
    
    #Parse desthardwareaddr parameter    
    set index [lsearch $args -desthardwareaddr] 
    if {$index != -1} {
        set desthardwareaddr [lindex $args [expr $index + 1]]
    } 
    set desthardwareaddr [string map {"-" :} $desthardwareaddr]
    
    #Parse sourceprotocoladdrmode parameter    
    set index [lsearch $args -sourceprotocoladdrmode] 
    if {$index != -1} {
        set sourceprotocoladdrmode [lindex $args [expr $index + 1]]
    } 
    
    #Parse sourceprotocoladdrrepeatcount parameter    
    set index [lsearch $args -sourceprotocoladdrrepeatcount] 
    if {$index != -1} {
        set sourceprotocoladdrrepeatcount [lindex $args [expr $index + 1]]
    }
    
    #Parse destprotocoladdrmode parameter    
    set index [lsearch $args -destprotocoladdrmode] 
    if {$index != -1} {
        set destprotocoladdrmode [lindex $args [expr $index + 1]]
    }

    #Parse destprotocoladdrpepeatcount parameter    
    set index [lsearch $args -destprotocoladdrrepeatcount ] 
    if {$index != -1} {
        set destprotocoladdrrepeatcount  [lindex $args [expr $index + 1]]
    }

    #Parse sourcehardwareaddrmode parameter    
    set index [lsearch $args -sourcehardwareaddrmode] 
    if {$index != -1} {
        set sourcehardwareaddrmode [lindex $args [expr $index + 1]]
    }

    #Parse sourcehardwareaddrrepeatcount parameter    
    set index [lsearch $args -sourcehardwareaddrrepeatcount] 
    if {$index != -1} {
        set sourcehardwareaddrrepeatcount [lindex $args [expr $index + 1]]
    }

    #Parse desthardwareaddrmode parameter    
    set index [lsearch $args -desthardwareaddrmode] 
    if {$index != -1} {
        set desthardwareaddrmode [lindex $args [expr $index + 1]]
    }

    #Parse desthardwareaddrrepeatcount parameter    
    set index [lsearch $args -desthardwareaddrrepeatcount] 
    if {$index != -1} {
        set desthardwareaddrrepeatcount [lindex $args [expr $index + 1]]
    }

    #Parse destprotocoladdrrepeatstep parameter    
    set index [lsearch $args -destprotocoladdrrepeatstep] 
    if {$index != -1} {
        set destprotocoladdrrepeatstep [lindex $args [expr $index + 1]]
    }

    #Parse sourceprotocoladdrrepeatstep parameter    
    set index [lsearch $args -sourceprotocoladdrrepeatstep] 
    if {$index != -1} {
        set sourceprotocoladdrrepeatstep [lindex $args [expr $index + 1]]
    }

    #Parse sourcehardwareaddrrepeatstep parameter    
    set index [lsearch $args -sourcehardwareaddrrepeatstep] 
    if {$index != -1} {
        set sourcehardwareaddrrepeatstep [lindex $args [expr $index + 1]]
    }
    set sourcehardwareaddrrepeatstep [string map {"-" :} $sourcehardwareaddrrepeatstep]
    
    #Parse desthardwareaddrrepeatstep parameter    
    set index [lsearch $args -desthardwareaddrrepeatstep] 
    if {$index != -1} {
        set desthardwareaddrrepeatstep [lindex $args [expr $index + 1]]
    }
    set desthardwareaddrrepeatstep [string map {"-" :} $desthardwareaddrrepeatstep]

    if {[string tolower $operation] == "arprequest"} {
        set operateCode 1
    } elseif {[string tolower $operation] == "arpreply"} {
        set operateCode 2
    } else {
        set operateCode 0
    }

    set hARP [stc::create arp:ARP -under $streamBlock1] 
    stc::config $hARP -operation $operateCode -senderHwAddr $sourcehardwareaddr -senderPAddr $sourceprotocoladdr \
            -targetHwAddr $desthardwareaddr -targetPAddr $destprotocoladdr

    set arp1 [stc::get $hARP -Name]
    
    #Create RangeModifier for sourceprotocoladdr in arp header
    if {[string tolower $sourceprotocoladdrmode] == "incr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "INCR" \
                -Mask "255.255.255.255" \
                -StepValue $sourceprotocoladdrrepeatstep\
                -RecycleCount $sourceprotocoladdrrepeatcount \
                -RepeatCount "0" \
                -Data $sourceprotocoladdr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.senderPAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    } elseif {[string tolower $sourceprotocoladdrmode] == "decr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "DECR" \
                -Mask "255.255.255.255" \
                -StepValue $sourceprotocoladdrrepeatstep\
                -RecycleCount $sourceprotocoladdrrepeatcount \
                -RepeatCount "0" \
                -Data $sourceprotocoladdr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.senderPAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    }   

    #Create RangeModifier for destprotocoladdr in arp header
    if {[string tolower $destprotocoladdrmode] == "incr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "INCR" \
                -Mask "255.255.255.255" \
                -StepValue $destprotocoladdrrepeatstep\
                -RecycleCount $destprotocoladdrrepeatcount \
                -RepeatCount "0" \
                -Data $destprotocoladdr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.targetPAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    } elseif {[string tolower $destprotocoladdrmode] == "decr"} {

        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "DECR" \
                -Mask "255.255.255.255" \
                -StepValue $destprotocoladdrrepeatstep\
                -RecycleCount $destprotocoladdrrepeatcount \
                -RepeatCount "0" \
                -Data $destprotocoladdr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.targetPAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
             
    }

    #Create RangeModifier for sourcehardwareaddr in arp header
    if {[string tolower $sourcehardwareaddrmode] == "incr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "INCR" \
                -Mask "00:00:FF:FF:FF:FF" \
                -StepValue $sourcehardwareaddrrepeatstep\
                -RecycleCount $sourcehardwareaddrrepeatcount \
                -RepeatCount "0" \
                -Data $sourcehardwareaddr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.senderHwAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    } elseif {[string tolower $sourcehardwareaddrmode] == "decr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "DECR" \
                -Mask "00:00:FF:FF:FF:FF" \
                -StepValue $sourcehardwareaddrrepeatstep\
                -RecycleCount $sourcehardwareaddrrepeatcount \
                -RepeatCount "0" \
                -Data $sourcehardwareaddr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.senderHwAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    }
    
    #Create RangeModifier for desthardwareaddr in arp header
    if {[string tolower $desthardwareaddrmode] == "incr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "INCR" \
                -Mask "00:00:FF:FF:FF:FF" \
                -StepValue $desthardwareaddrrepeatstep\
                -RecycleCount $desthardwareaddrrepeatcount \
                -RepeatCount "0" \
                -Data $desthardwareaddr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.targetHwAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    } elseif {[string tolower $desthardwareaddrmode] == "decr"} {
        stc::create "RangeModifier" \
                -under $streamBlock1 \
                -ModifierMode "DECR" \
                -Mask "00:00:FF:FF:FF:FF" \
                -StepValue $desthardwareaddrrepeatstep\
                -RecycleCount $desthardwareaddrrepeatcount \
                -RepeatCount "0" \
                -Data $desthardwareaddr  \
                -EnableStream $m_EnableStream \
                -Offset "0" \
                -OffsetReference "$arp1.targetHwAddr" \
                -Active "TRUE" \
                -Name "IPv4 Modifier" 
    }

    debugPut "exit the proc of AddArpPacketIntoStream" 
}  

############################################################################
#APIName: AddRipPacketIntoStream
#Description: Add Rip packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddRipPacketIntoStream {args hStream pduName} { 

   debugPut "enter the proc of AddRipPacketIntoStream" 
   
    #Parse version
    set index [lsearch $args -version] 
    if {$index != -1} {
        set version [lindex $args [expr $index + 1]]
    } else  {
        set version 1
    }

    #Create Ripv1 packet
    if {$version == 1} {
    
        #ripv1 packet structure    
        #command (1) + version (1) + 0 (2) + { afi (2) + 0 (2) + ipaddr (4) +0 (4) + 0 (4) + metric(4) } + {} ...

        #Parse Ripv1 packet parameter
        set index [lsearch $args -ripparams] 
        if {$index != -1} {
            set ripparams [lindex $args [expr $index + 1]]
        } else  {
            error "please specify ripparams for Ripv1Packet"
        }

        set index [lsearch $ripparams -command] 
        if {$index != -1} {
            set command [lindex $ripparams [expr $index + 1]]
        } else  {
            set command request
        }     
        if {[string tolower $command] == "request"} { 
            set command 1 
        } else {
            set command 2
        }

        #Create  ripv1 object 
        set hRipv1 [stc::create rip:Ripv1 \
                                            -under $hStream\
                                            -command $command\
                                            -reserved 0\
                                            -version 1] 
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hRipv1
                                            
        set index [lsearch $ripparams -ripentries] 
        if {$index != -1} {
            set ripentries [lindex $ripparams [expr $index + 1]]
        } else  {
            error "please specify ripentries for Ripv1Packet"
        } 

        set len [llength $ripentries]
        if {$len < 1} {
            error "please specify at lease 1 ripEntry for Ripv1Packet"
        }

        #Create rip1Entries object
        set hRip1Entries [stc::create rip1Entries -under $hRipv1]

        for {set i 0} {$i < $len} {incr i} {   
            #Parse ripv1Entry parameter
            set ripEntry [lindex $ripentries $i]
            
            set index [lsearch $ripEntry -afi] 
            if {$index != -1} {
                set afi [lindex $ripEntry [expr $index + 1]]
            } else  {
                set afi  2
            }      

            set index [lsearch $ripEntry -ipaddr] 
            if {$index != -1} {
                set ipaddr [lindex $ripEntry [expr $index + 1]]
            } else  {
                error "please specify ipaddr for ripv1 entry"
            } 

            set index [lsearch $ripEntry -metric] 
            if {$index != -1} {
                set metric [lindex $ripEntry [expr $index + 1]]
            } else  {
                set metric  2
            } 
            #Add ripv1Entry into Ripv1 packet
            stc::create Rip1Entry \
                         -under $hRip1Entries\
                         -afi $afi\
                         -ipaddr $ipaddr\
                         -metric $metric
           }              
     } elseif {$version == 2} {

        #ripv2 packet structure  
        #command (1) + version (1) + routetag (2) + { afi (2) + 0 (2) + ipaddr (4) +netmask (4) + nextHop(4) + metric(4) }     

        #Parse Ripv2 packet的 parameter
        set index [lsearch $args -ripparams] 
        if {$index != -1} {
            set ripparams [lindex $args [expr $index + 1]]
        } else  {
            error "please specify ripparams for Ripv2Packet"
        }

        set index [lsearch $ripparams -command] 
        if {$index != -1} {
            set command [lindex $ripparams [expr $index + 1]]
        } else  {
            set command request
        } 
        if {[string tolower $command] == "request"} {
        set command 1 
        } else {
        set command 2
        }        
        #Create  ripv2 object
        set hRipv2 [stc::create rip:Ripv2 \
                                            -under $hStream\
                                            -command $command\
                                            -reserved 0\
                                            -version 2] 
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hRipv2

        set index [lsearch $ripparams -ripentries] 
        if {$index != -1} {
            set ripentries [lindex $ripparams [expr $index + 1]]
        } else  {
            error "please specify ripentries for Ripv2Packet"
        } 
        set len [llength $ripentries]

        set len [llength $ripentries]
        if {$len < 1} {
            error "please specify at lease 1 ripEntry for Ripv2Packet"
        }
        
        #Create ripv2Entries object
        set hRip2Entries [stc::create rip2Entries -under $hRipv2]

        for {set i 0} {$i < $len} {incr i} {   
            #Parse  ripv2Entry parameter
            set ripEntry [lindex $ripentries $i]
            
            set index [lsearch $ripEntry -afi] 
            if {$index != -1} {
                set afi [lindex $ripEntry [expr $index + 1]]
            } else  {
                set afi  2
            }      

            set index [lsearch $ripEntry -ipaddr] 
            if {$index != -1} {
                set ipaddr [lindex $ripEntry [expr $index + 1]]
            } else  {
                error "please specify ipaddr for ripv2 entry"
            } 

            set index [lsearch $ripEntry -metric] 
            if {$index != -1} {
                set metric [lindex $ripEntry [expr $index + 1]]
            } else  {
                set metric  2
            } 

            set index [lsearch $ripEntry -nexthop] 
            if {$index != -1} {
                set nexthop [lindex $ripEntry [expr $index + 1]]
            } else  {
                error "please specify nextHop for ripv2 entry"
            }

            set index [lsearch $ripEntry -subnetMask] 
            if {$index != -1} {
                set subnetMask [lindex $ripEntry [expr $index + 1]]
            } else  {
                set subnetMask  255.255.255.0
            }     

            set index [lsearch $ripEntry -routetag] 
            if {$index != -1} {
                set routetag [lindex $ripEntry [expr $index + 1]]
            } else  {
                set routetag  0
            }              
            #Add ripv2Entry into Ripv2 packet        
            stc::create Rip2Entry \
                             -under $hRip2Entries\
                             -afi $afi\
                             -ipaddr $ipaddr\
                             -metric $metric\
                             -nextHop $nexthop\
                             -routetag $routetag\
                             -subnetMask $subnetMask    
        }     
    }  
    debugPut "exit the proc of AddRipPacketIntoStream" 
    
}
############################################################################
#APIName: AddRipngPacketIntoStream
#Description: Add Ripng packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddRipngPacketIntoStream {args hStream pduName} { 

     debugPut "enter the proc of AddRipngPacketIntoStream" 
     
     #ripvng pkt packet structure
     #command (1) + version (1) + 0 (2) + { ipv6 prefix (16) +  routetag (2) +prefix len (1) + metric(1) } + {} ...

     #Parse Ripng parameter
     set ripparams $args
        
     set index [lsearch $ripparams -command] 
     if {$index != -1} {
          set command [lindex $ripparams [expr $index + 1]]
     } else  {
          set command request
     }     
     if {[string tolower $command] == "request"} { 
          set command 1 
     } else {
          set command 2
     }

     #Create Ripng object
     set hRipng [stc::create rip:Ripng -under $hStream -command $command]
     #Store the packet header
     lappend m_PduNameList $pduName
     set m_PduHandleList($pduName) $hRipng
                                            
     set index [lsearch $ripparams -rtelist] 
     if {$index != -1} {
         set rtelist [lindex $ripparams [expr $index + 1]]
     } else  {
         error "please specify rtelist for Ripng Packet "
     } 

     set len [llength $rtelist]
     if {$len < 1} {
         error "please specify at lease 1 RTE for Ripng Packet "
     }

     #Create  ripngEntries object
     set hRipngEntries [stc::create ripngEntries  -under $hRipng]

     for {set i 0} {$i < $len} {incr i} {   
         #Parse ripvngEntry parameter
         set ripEntry [lindex $rtelist $i]
            
         set index [lsearch $ripEntry -ipaddr] 
         if {$index != -1} {
             set ipaddr [lindex $ripEntry [expr $index + 1]]
         } else  {
             set ipaddr  2000::1
         }      

         set index [lsearch $ripEntry -metric] 
         if {$index != -1} {
             set metric [lindex $ripEntry [expr $index + 1]]
         } else  {
             set metric 1
         } 

         set index [lsearch $ripEntry -prefixlen] 
         if {$index != -1} {
             set prefixlen [lindex $ripEntry [expr $index + 1]]
         } else  {
             set prefixlen  64
         } 

         set index [lsearch $ripEntry -routetag] 
         if {$index != -1} {
             set routetag [lindex $ripEntry [expr $index + 1]]
         } else  {
             set routetag  0
         } 
            
        #Add ripvngEntry into Ripng packet         
        stc::create RipngEntry  \
                         -under $hRipngEntries\
                         -ipaddr $ipaddr\
                         -prefixLen $prefixlen\
                         -metric $metric\
                         -routetag $routetag
     }    
     debugPut "exit the proc of AddRipngPacketIntoStream" 
}

############################################################################
#APIName: AddIcmpPacketIntoStream
#Description: Add Icmp packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddIcmpPacketIntoStream {args hStream pduName} {

   debugPut "enter the proc of AddIcmpPacketIntoStream" 
   set streamBlock1 $hStream    
  
    #Parse IcmpType
    set index [lsearch $args -icmptype] 
    if {$index != -1} {
        set icmppkttype [lindex $args [expr $index + 1]]
    } else  {
        set icmppkttype 0
    }

    set icmppkttype_num 0
    #icmptype conversion
    if {$icmppkttype == "0"} {
        set icmppkttype "echo_reply"
    } elseif {$icmppkttype == "3"} {
        set icmppkttype "destination_unreachable"
    } elseif {$icmppkttype == "8"} {
        set icmppkttype "echo_request"
    } elseif {$icmppkttype == "16"} {
        set icmppkttype "information_reply"
    } elseif {$icmppkttype == "15"} {
        set icmppkttype "information_request"
    } elseif {$icmppkttype == "12"} {
        set icmppkttype "parameter_problem"
    } elseif {$icmppkttype == "5"} {
        set icmppkttype "redirect"
    } elseif {$icmppkttype == "4"} {
        set icmppkttype "source_quench"
    } elseif {$icmppkttype == "11"} {
        set icmppkttype "time_exceeded"
    } elseif {$icmppkttype == "13"} {
        set icmppkttype "timestamp_reply"
    } elseif {$icmppkttype == "14"} {
        set icmppkttype "timestamp_request"
    } elseif {$icmppkttype >= "0" && $icmppkttype <= "255" } {
        set icmppkttype_num $icmppkttype
        set icmppkttype "user_defined" 
    }

    #Check whether or not icmppkttype is valid
    if {([string tolower $icmppkttype] != "destination_unreachable") && \
         ([string tolower $icmppkttype] != "echo_reply") && \
         ([string tolower $icmppkttype] != "echo_request") && \
         ([string tolower $icmppkttype] != "information_reply") && \
         ([string tolower $icmppkttype] != "information_request") && \
         ([string tolower $icmppkttype] != "parameter_problem") && \
         ([string tolower $icmppkttype] != "redirect") && \
         ([string tolower $icmppkttype] != "source_quench") && \
         ([string tolower $icmppkttype] != "time_exceeded") && \
         ([string tolower $icmppkttype] != "timestamp_reply") && \
         ([string tolower $icmppkttype] != "user_defined") && \
         ([string tolower $icmppkttype] != "timestamp_request")} {

         error "icmppkttype must be one the followings:\necho_request，echo_reply，destination_unreachable，\
                source_quench，redirect，time_exceeded，parameter_problem，timestamp_request，\
                timestamp_reply，information_request，information_reply"
    }

    #Parse Code
    set index [lsearch $args -code] 
    if {$index != -1} {
        set Code [lindex $args [expr $index + 1]]
    } else  {
        set Code 0
    }

    #Parse SequNum
    set index [lsearch $args -sequnum] 
    if {$index != -1} {
        set SequNum [lindex $args [expr $index + 1]]
    } else  {
        set SequNum 0
    }

    #Parse Data
    set index [lsearch $args -data] 
    if {$index != -1} {
        set Data [lindex $args [expr $index + 1]]
    } else  {
        set Data "0000"
    }

    #Parse InternetHeader
    set index [lsearch $args -internetheader] 
    if {$index != -1} {
        set InternetHeader [lindex $args [expr $index + 1]]
    } 

    #Parse OriginalDateFragment
    set index [lsearch $args -originaldatefragment] 
    if {$index != -1} {
        set OriginalDateFragment [lindex $args [expr $index + 1]]
    } else {
        set OriginalDateFragment "0000000000000000"
    }

    #Parse GatewayInternetAdd
    set index [lsearch $args -gatewayinternetadd] 
    if {$index != -1} {
        set GatewayInternetAdd [lindex $args [expr $index + 1]]
    } else {
        set GatewayInternetAdd "192.0.0.1"
    }

    #Parse Pointer
    set index [lsearch $args -pointer] 
    if {$index != -1} {
        set Pointer [lindex $args [expr $index + 1]]
    } else {
        set Pointer 0
    }
    
    #Parse Identifier
    set index [lsearch $args -identifier] 
    if {$index != -1} {
        set Identifier [lindex $args [expr $index + 1]]
    } else {
        set Identifier 0
    }

    #Parse OriginateTimeStamp
    set index [lsearch $args -originatetimestamp] 
    if {$index != -1} {
        set OriginateTimeStamp [lindex $args [expr $index + 1]]
    } else {
        set OriginateTimeStamp 0 
    }

    #Parse ReceiveTimeStamp
    set index [lsearch $args -receivetimestamp] 
    if {$index != -1} {
        set ReceiveTimeStamp [lindex $args [expr $index + 1]]
    } else {
        set ReceiveTimeStamp 0
    }

    #Parse TransmitTimeStamp
    set index [lsearch $args -transmittimestamp] 
    if {$index != -1} {
        set TransmitTimeStamp [lindex $args [expr $index + 1]]
    } else {
        set TransmitTimeStamp 0
    }   

    set ipHdrConfig ""
        
    #Parse the iphdr parameters in Icmp pkt     
    set index [lsearch $args -internetheader] 
    if {$index != -1} {
        set iphdr [lindex $args [expr $index + 1]]
    
        foreach {attr value} $iphdr {
            lappend ipHdrConfig $attr
            lappend ipHdrConfig $value
        }               
    }

    #Create destination_unreachable packet
    if {[string tolower $icmppkttype] =="destination_unreachable"} {         

        #Create  IcmpDestUnreach object
        set hIcmpHeader [eval stc::create icmp:IcmpDestUnreach  -under $hStream -Code $Code]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                                       
        #Create ipData object                                                       
        set hIpData [stc::create ipData -under $hIcmpHeader -data $OriginalDateFragment]     

        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipHdrConfig 

    #Create icmpparameterproblem packet    
    } elseif {[string tolower $icmppkttype] =="parameter_problem"} {         

        #Create  IcmpParameterProblem  object
        set hIcmpHeader [eval stc::create icmp:IcmpParameterProblem  -under $hStream -Code $Code -Pointer $Pointer]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                                       
        #Create ipData object                                                       
        set hIpData [stc::create ipData -under $hIcmpHeader -data $OriginalDateFragment]     

        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipHdrConfig 

    #Create redirect packet    
    } elseif {[string tolower $icmppkttype] =="redirect"} {         

        #Create  IcmpRedirect  object
        set hIcmpHeader [eval stc::create icmp:IcmpRedirect  -under $hStream -Code $Code -gateway $GatewayInternetAdd]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                                       
        #Create ipData object                                                       
        set hIpData [stc::create ipData -under $hIcmpHeader -data $OriginalDateFragment]     

        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipHdrConfig 

    #Create source_quench packet    
    } elseif {[string tolower $icmppkttype] =="source_quench"} {         

        #Create  IcmpSourceQuench  object
        set hIcmpHeader [eval stc::create icmp:IcmpSourceQuench -under $hStream -Code $Code]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                                       
         #Create ipData object                                                       
        set hIpData [stc::create ipData -under $hIcmpHeader -data $OriginalDateFragment]     

        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipHdrConfig 

    #Create time_exceeded packet    
    } elseif {[string tolower $icmppkttype] =="time_exceeded"} {         

        #Create  IcmpTimeExceeded  object
        set hIcmpHeader [eval stc::create icmp:IcmpTimeExceeded   -under $hStream -Code $Code]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                                       
        #Create ipData object                                                       
        set hIpData [stc::create ipData -under $hIcmpHeader -data $OriginalDateFragment]     

        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipHdrConfig 

    #Create echo_reply packet    
    } elseif {[string tolower $icmppkttype]  == "echo_reply"} {

        #Create IcmpEchoReply object
        set hIcmpHeader [eval stc::create icmp:IcmpEchoReply -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader

        #Configure IcmpEchoReply payload attribute
        stc::config $hIcmpHeader -data $Data
                           
    #Create echo_request packet                   
    } elseif {[string tolower $icmppkttype]  == "echo_request"} {

        #Create IcmpEchoRequest object
        set hIcmpHeader [eval stc::create icmp:IcmpEchoRequest -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader

        #Configure IcmpEchoRequest payload attribute
        stc::config $hIcmpHeader -data $Data
                           
    #Create information_reply packet                   
    } elseif {[string tolower $icmppkttype]  == "information_reply"} {

        #Create IcmpInfoReply object
        set hIcmpHeader [eval stc::create icmp:IcmpInfoReply -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                   
    #Create icmpechorequest packet                   
    } elseif {[string tolower $icmppkttype]  == "information_request"} {

        #Create IcmpInfoRequest object
        set hIcmpHeader [eval stc::create icmp:IcmpInfoRequest -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                   
    #Create timestamp_reply packet                   
    } elseif {[string tolower $icmppkttype]  == "timestamp_reply"} {

        #Create IcmpTimestampReply packet
        set hIcmpHeader [eval stc::create icmp:IcmpTimestampReply   -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum \
                                      -originate $OriginateTimeStamp -transmit $TransmitTimeStamp -receive $ReceiveTimeStamp]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader
                                   
    #Create timestamp_request packet                   
    } elseif {[string tolower $icmppkttype]  == "timestamp_request"} {

        #Create IcmpTimestampReply packet
        set hIcmpHeader [eval stc::create icmp:IcmpTimestampRequest   -under $hStream -Code $Code -Identifier $Identifier -seqNum $SequNum \
                                      -originate $OriginateTimeStamp -transmit $TransmitTimeStamp -receive $ReceiveTimeStamp]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader

    #Create user_defined packet                   
    } elseif {[string tolower $icmppkttype]  == "user_defined"} {

        #Create IcmpEchoRequest object
        set hIcmpHeader [eval stc::create icmp:IcmpEchoRequest -under $hStream -Type $icmppkttype_num -Code $Code -Identifier $Identifier -seqNum $SequNum]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpHeader

        #Configure IcmpEchoRequest payload attribute
        stc::config $hIcmpHeader -data $Data              
    } 
    debugPut "exit the proc of AddIcmpPacketIntoStream" 
}

############################################################################
#APIName: AddIcmpv6PacketIntoStream
#Description: Add Icmpv6 packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddIcmpv6PacketIntoStream {args hStream pduName} {

   debugPut "enter the proc of AddIcmpv6PacketIntoStream" 
   set streamBlock1 $hStream      

   #puts "args=$args"
   #Parse  icmppkttype
    set index [lsearch $args -icmppkttype] 
    if {$index != -1} {
        set icmppkttype [lindex $args [expr $index + 1]]
    } else  {
        error "please specify icmppkttype"
    }
    #puts "icmppkttype=$icmppkttype"
    #Check whether or not icmppkttype is valid
    if {([string tolower $icmppkttype] != "icmpv6destunreach") && \
         ([string tolower $icmppkttype] != "icmpv6echoreply") && \
         ([string tolower $icmppkttype] != "icmpv6echorequest") && \
         ([string tolower $icmppkttype] != "icmpv6packettoobig") && \
         ([string tolower $icmppkttype] != "icmpv6parameterproblem") && \
         ([string tolower $icmppkttype] != "icmpv6timeexceeded") } {

         error "icmppkttype must be one the followings:\n\
         Icmpv6DestUnreach,Icmpv6EchoReply,Icmpv6EchoRequest,\
         Icmpv6PacketTooBig,Icmpv6ParameterProblem,Icmpv6TimeExceeded"
    }

    set ipv6HdrConfig ""
    set icmpv6HdrConfig ""
        
    #Parse iphdr in Icmpv6 pkt
    set index [lsearch $args -ipv6hdr] 
    if {$index != -1} {
        set ipv6hdr [lindex $args [expr $index + 1]]
    
        foreach {attr value} $ipv6hdr {
            lappend ipv6HdrConfig $attr
            lappend ipv6HdrConfig $value
        }               
   }
   #puts "ipv6HdrConfig=$ipv6HdrConfig"
   #Parse icmpv6Hdr parameters
   set index [lsearch $args -icmpv6hdr] 
   if {$index != -1} {
       set icmpv6hdr [lindex $args [expr $index + 1]]
    
       foreach {attr value} $icmpv6hdr {
             lappend icmpv6HdrConfig $attr
             lappend icmpv6HdrConfig $value
       }               
   }
   #puts "icmpv6HdrConfig=$icmpv6HdrConfig"

   #Parse payload parameter
   set index [lsearch $args -payload] 
   if {$index != -1} { 
       set payload [lindex $args [expr $index + 1]]
   } else {
       set payload "aaaa"
   }        
      
    #Create icmpv6destunreach packet
    if {[string tolower $icmppkttype] =="icmpv6destunreach"} {
        
        #Create Icmpv6DestUnreach object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6DestUnreach -under $hStream $icmpv6HdrConfig]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Create ipdata object
        set hIpData [stc::create ipData -under $hIcmpv6 -data  $payload]
     
        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipv6HdrConfig

    } elseif {[string tolower $icmppkttype] =="icmpv6packettoobig"} {
        
        #Create Icmpv6PacketTooBig  object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6PacketTooBig  -under $hStream $icmpv6HdrConfig]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Create ipdata object
        set hIpData [stc::create ipData -under $hIcmpv6 -data  $payload]
     
        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipv6HdrConfig

    } elseif {[string tolower $icmppkttype] =="icmpv6parameterproblem"} {
        
        #Create Icmpv6ParameterProblem  object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6ParameterProblem  -under $hStream $icmpv6HdrConfig]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Create ipdata object
        set hIpData [stc::create ipData -under $hIcmpv6 -data  $payload]
     
        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipv6HdrConfig

    } elseif {[string tolower $icmppkttype] =="icmpv6echorequest"} {
        
        #Create Icmpv6EchoRequest object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6EchoRequest  -under $hStream $icmpv6HdrConfig]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Configure icmp payload attribute
        stc::config $hIcmpv6 -data $payload
     
    } elseif {[string tolower $icmppkttype] =="icmpv6echoreply"} {
        
        #Create Icmpv6EchoReply   object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6EchoReply   -under $hStream $icmpv6HdrConfig]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Configure icmp payload attribute
        stc::config $hIcmpv6 -data $payload
     
    } elseif {[string tolower $icmppkttype] =="icmpv6timeexceeded"} {
        
        #Create Icmpv6DestUnreach object
        set hIcmpv6 [eval stc::create icmpv6:Icmpv6TimeExceeded  -under $hStream $icmpv6HdrConfig]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hIcmpv6
      
        #Create ipdata object
        set hIpData [stc::create ipData -under $hIcmpv6 -data $payload]
     
        #Create iphdr object
        eval stc::create iphdr -under $hIpData $ipv6HdrConfig

    } 
    debugPut "exit the proc of AddIcmpv6PacketIntoStream" 
}

############################################################################
#APIName: AddOspfv2PacketIntoStream
#Description: Add Ospfv2 packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddOspfv2PacketIntoStream {args hStream pduName} {

   debugPut "enter the proc of AddOspfv2PacketIntoStream" 
  
    #Parse  ospfv2pkttype 
    set index [lsearch $args -ospfv2pkttype] 
    if {$index != -1} {
        set ospfv2pkttype [lindex $args [expr $index + 1]]
    } else  {
        error "please specify ospfv2pkttype for Ospfv2packet"
    }

    #Check whether or not ospfv2pkttype is valid
    if {([string tolower $ospfv2pkttype] !="ospfv2dd" ) && \
         ([string tolower $ospfv2pkttype] !="ospfv2hello" ) && \
         ([string tolower $ospfv2pkttype] !="ospfv2lsr" ) && \
         ([string tolower $ospfv2pkttype] !="ospfv2lsu" ) && \
         ([string tolower $ospfv2pkttype] !="ospfv2unknown" ) && \
         ([string tolower $ospfv2pkttype] !="ospfv2lsack" )} {

        error "ospfv2pkttype must be one of the followings:\n\
        Ospfv2DD,Ospfv2Hello,Ospfv2LSR,Ospfv2LSU,Ospfv2Unknown "
    }

    #Parse ospfv2 header parameter
    set ospfv2hdrConfig ""
    set index [lsearch $args -ospfv2hdr] 
    if {$index != -1} {
        set ospfv2hdr [lindex $args [expr $index + 1]]
            
        foreach {attr value} $ospfv2hdr {
              lappend ospfv2hdrConfig $attr
              lappend ospfv2hdrConfig $value
        }
    }
     
    #Parse Ospfv2DD packet parameter, and create Ospfv2DD packet
    if {[string tolower $ospfv2pkttype] == "ospfv2dd"} {
        #ospfv2DD packet structure
        #ospf headev2 (24) + DD header (8) + LsaHeader1 (20) + LsaHeader2(20) + ...
        
         set hDD [stc::create ospfv2:Ospfv2DatabaseDescription -under $hStream]
         #Store the packet header
         lappend m_PduNameList $pduName
         set m_PduHandleList($pduName) $hDD

         eval stc::create header -under $hDD $ospfv2hdrConfig -type  2
         
         set index [lsearch $args -ddparams] 
         if {$index != -1} {
            set ddparams [lindex $args [expr $index + 1]]
         } else {
             set ddparams "not_specified"
         }

         set ddConfig ""
         if {$ddparams != "not_specified"} {
         
             set index [lsearch $ddparams -interfacemtu] 
             if {$index != -1} {
                set interfacemtu [lindex $ddparams [expr $index + 1]]
                lappend ddConfig -interfacemtu
                lappend ddConfig $interfacemtu
             }

             set index [lsearch $ddparams -sequencenumber] 
             if {$index != -1} {
                set sequencenumber [lindex $ddparams [expr $index + 1]]
                lappend ddConfig -sequencenumber
                lappend ddConfig $sequencenumber
             }
             #puts "ddConfig=$ddConfig"
             eval stc::config $hDD $ddConfig

             set index [lsearch $ddparams -lsahdrs] 
             if {$index != -1} {
                set lsaheaders [lindex $ddparams [expr $index + 1]]

                set hLsaHeaders [stc::create lsaHeaders -under $hDD]
                #puts "lsaheaders=$lsaheaders"
                foreach lsaHeader $lsaheaders {
                    set lsaHeaderConfig ""
                    foreach {attr value} $lsaHeader {
                        lappend lsaHeaderConfig $attr
                        lappend lsaHeaderConfig $value                        
                    }
                    #puts "lsaHeaderConfig=$lsaHeaderConfig"
                    eval stc::create Ospfv2LsaHeader -under $hLsaHeaders $lsaHeaderConfig -lsaLength 0

                }
            }
         }
                         
    #Parse Ospfv2Hello parameter，and create Ospfv2Hello packet                   
    } elseif {[string tolower $ospfv2pkttype] == "ospfv2hello"} {
 
        #Ospfv2Hello packet structure
        #ospfv2 header (24) + hello Pkt -nei1 (4) + nei2 (4) + nei2 (4) + ...

        set hHello [stc::create ospfv2:Ospfv2Hello -under $hStream]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hHello

        eval stc::create header -under $hHello $ospfv2hdrConfig -type 1
        #puts "ospfv2hdrConfig=$ospfv2hdrConfig"

         set index [lsearch $args -helloparams] 
         if {$index != -1} {
            set helloparams [lindex $args [expr $index + 1]]

            set index [lsearch $helloparams -neighbors ] 
            if {$index != -1} {
                set neighbors [lindex $helloparams [expr $index + 1]]
                set helloparams [lreplace $helloparams $index [expr $index + 1]]
            } else {
                set neighbors "not_specified"
            } 

            set helloConfig ""
            foreach {attr value} $helloparams {
                lappend helloConfig $attr
                lappend helloConfig $value
            }
            #puts "helloConfig=$helloConfig"
            eval stc::config $hHello $helloConfig

            if {$neighbors != "not_specified"} {
                set hNeighbors [stc::create neighbors -under $hHello]

                #puts "neighbors=$neighbors"
                foreach nei $neighbors {
                    stc::create Ospfv2Neighbor  -under $hNeighbors -neighborID $nei
                }            
            }
         }        
        
    #Parse Ospfv2LSR parameter，and create Ospfv2LSR packet          
    } elseif {[string tolower $ospfv2pkttype] == "ospfv2lsr"} {

        #Ospfv2LSR packet structure
        #ospf header (24) + lsr1 (12) + lsr2(12) + ...
        set hLsr [stc::create ospfv2:Ospfv2LinkStateRequest -under $hStream]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hLsr

        eval stc::create header -under $hLsr $ospfv2hdrConfig -type  3

         set index [lsearch $args -lsrparams] 
         if {$index != -1} {
            set lsrparams [lindex $args [expr $index + 1]]
            set hLsas [stc::create requestedLsas  -under $hLsr]

            foreach lsa $lsrparams {
                set lsaConfig ""
                foreach {attr value} $lsa {
                    lappend lsaConfig $attr
                    lappend lsaConfig $value
                }
                #puts "lsaConfig=$lsaConfig"
                eval stc::create Ospfv2RequestedLsa -under $hLsas $lsaConfig
            }

         } 
        
   #Parse Ospfv2LSR parameter，and create Ospfv2LSR packet  
    } elseif {[string tolower $ospfv2pkttype] == "ospfv2lsack"} {
  
        #Ospfv2LSR packet structure
        #ospf header (24) + lsa1 (12) + lsa2(12) + ...
        set hLsack [stc::create ospfv2:Ospfv2LinkStateAcknowledge -under $hStream]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hLsack

        eval stc::create header -under $hLsack $ospfv2hdrConfig -type 5

         set index [lsearch $args -lsackparams] 
         if {$index != -1} {
            set lsackparams [lindex $args [expr $index + 1]]
           
            set hLsas [stc::create lsaHeaders  -under $hLsack]

            foreach lsa $lsackparams {
           
                set lsaConfig ""
                foreach {attr value} $lsa {
                    lappend lsaConfig $attr
                    lappend lsaConfig $value
                }
                #puts "lsaConfig=$lsaConfig"
                eval stc::create Ospfv2LsaHeader -under $hLsas $lsaConfig -lsaLength 0
            }

         } 
        
    #Parse Ospfv2LSU parameter, and create Ospfv2LSU packet
    } elseif {[string tolower $ospfv2pkttype] == "ospfv2lsu"} {

        #Ospfv2LSU  packet structure
        #ospf header (24) + num of lsas (4) + lsa1 + lsa2
        set hLsu [stc::create ospfv2:Ospfv2LinkStateUpdate -under $hStream]
         #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hLsu

        #Create Ospfv2 Header
        eval stc::create header -under $hLsu $ospfv2hdrConfig -type 4

        set index [lsearch $args -lsuparams] 
        if {$index != -1} { 
            set lsuparams [lindex $args [expr $index + 1]]
        }

        #Calculate lsa number in lsu
        stc::config $hLsu -numberOfLsas [llength $lsuparams]
        set hLsas [stc::create updatedLsas -under $hLsu]
         #puts "lsuparams=$lsuparams"
        #Loop to create each lsa
        foreach lsa $lsuparams {

            set index [lsearch $lsa -lsatype] 
            if {$index != -1} { 
                set lsatype [lindex $lsa [expr $index + 1]]
                set lsa [lreplace $lsa $index [expr $index + 1]]
            } else {
                error "please specify lsaType for $lsa when CreateOspfv2Pkt.ospfv2lsu"
            }
            #Parse lsa Header parameter
            set index [lsearch $lsa -lsahdr] 
            if {$index != -1} { 
                set lsahdr [lindex $lsa [expr $index + 1]]
                set lsa [lreplace $lsa $index [expr $index + 1]]
            } 
            
            set lsaHdrConfig ""
            foreach {attr value} $lsahdr {
                lappend lsaHdrConfig $attr
                lappend lsaHdrConfig $value
            }

            #If it ids network lsa，Parse attachedrouters
            set index [lsearch $lsa -attachedrouters] 
            if {$index != -1} { 
                set attachedrouters [lindex $lsa [expr $index + 1]]
                set lsa [lreplace $lsa $index [expr $index + 1]]
            } else {
                set attachedrouters "not_specified"
            }            

            #Parse lsa parameter
            set lsaConfig ""
            foreach {attr value} $lsa {              
                lappend lsaConfig $attr
                lappend lsaConfig $value                              
            }               
                set hLsa [stc::create Ospfv2Lsa -under $hLsas]
                #Create lsa object according to lsa type
                switch $lsatype {
                    routerlsa {
                    #Create Router Lsa
                        eval set hRouterLsa [stc::create ospfv2RouterLsa  -under $hLsa ]
                        
                        set hRouteLsaLinks [stc::create routerLsaLinks  -under $hRouterLsa ]

                        set index [lsearch $lsa -routerlsalinks]
                        if {$index != -1} {
                            set routerlsalinks [lindex $lsa [expr $index + 1]]

                            set lsaLinkNum [llength $routerlsalinks]

                            #Create ospf lsa header
                            eval stc::create Header -under $hRouterLsa $lsaHdrConfig -lsaLength [expr 24 + 12 * $lsaLinkNum ]
                            stc::config $hRouterLsa -numberOfLinks $lsaLinkNum

                            #Loop to create RouterLsa for each LsaLlink
                            foreach lsaLink $routerlsalinks {
                           
                                set lsaLinkConfig ""
                                foreach {attr value} $lsaLink {
                                    lappend lsaLinkConfig $attr
                                    lappend lsaLinkConfig $value
                                }
                                
                                eval stc::create Ospfv2RouterLsaLink  -under $hRouteLsaLinks $lsaLinkConfig
    
                            }                            
                        } else {
                             error "please specify routerlsalinks for RouterLsa"
                        }
                        

                    }
                    networklsa {
                        #Create Network Lsa
                        
                        set hNetworkLsa [eval stc::create ospfv2NetworkLsa   -under $hLsa $lsaConfig]

                        if {$attachedrouters == "not_specified"} {
                            error "please specify attachedrouters for NetworkLsa"
                        }

                        #Calculate AttachedRouter in RouterLsa
                        set numNei [llength $attachedrouters]
                        eval stc::create Header -under $hNetworkLsa $lsaHdrConfig -lsaLength [expr 24 + 4 * $numNei ] -lsType 2

                        set hAttachedRouters [stc::create attachedRouters -under $hNetworkLsa]

                        #Loop to create each Attaeched Router
                        for {set i 0} {$i < $numNei} {incr i} {
                            stc::create Ospfv2AttachedRouter -under $hAttachedRouters -routerID [lindex $attachedrouters $i]
                        }
                        
                    }
                    summarylsa {     
                        #Create Summary Lsa
                        set hSummaryLsa [eval stc::create ospfv2SummaryLsa   -under $hLsa $lsaConfig]
                        eval stc::create Header -under $hSummaryLsa $lsaHdrConfig -lsaLength 28 -lsType 3
                    }
                    asbrsummarylsa {
                        #Create AsbrSummary Lsa
                        set hAsbrSummaryLsa [eval stc::create ospfv2SummaryAsbrLsa   -under $hLsa $lsaConfig]
                        eval stc::create Header -under $hAsbrSummaryLsa $lsaHdrConfig -lsaLength 28 -lsType 4
                    }
                    asexternallsa {
                        #Create AsExternal Lsa
                        set hAsExterNalLsa [eval stc::create ospfv2AsExternalLsa   -under $hLsa $lsaConfig]
                        eval stc::create Header -under $hAsExterNalLsa $lsaHdrConfig -lsaLength 36 -lsType 5
                    }
                    default {
                        error "unsupported lsaType($lsatype),valid lsaTypes are:routerLsa,networkLsa,summaryLsa,asbrSummaryLsa,asexternallsa"
                    }                  
                }
        }
            
    #Parse Ospfv2Unkown parameter，create Ospfv2Unkown packet                     
    } elseif {[string tolower $ospfv2pkttype] == "ospfv2unknown"} {
    
       #Ospfv2Unknown packet structure
       #ospfv2  header (24) with type=0
        set hUnkown [stc::create ospfv2:Ospfv2Unknown  -under $hStream]
        #Store the packet header
        lappend m_PduNameList $pduName
        set m_PduHandleList($pduName) $hUnkown

        eval stc::create header -under $hUnkown  $ospfv2hdrConfig  -type 0
        #puts "------------------------------"
    
    }
    debugPut "exit the proc of AddOspfv2PacketIntoStream" 
}

############################################################################
#APIName: AddCustomPacketIntoStream
#Description: Add custom packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: David.Wu
#############################################################################
::itcl::body Stream::AddCustomPacketIntoStream {args hStream pduName} {

   debugPut "enter the proc of AddCustomPacketIntoStream" 

   #Parse pattern
      set index [lsearch $args -hexstring] 
      if {$index != -1} {
           set hexstring [lindex $args [expr $index + 1]]
      } else  {
           error "please specify HexString for CustomPkt"
      }
    
      stc::config $hStream -AllowInvalidHeaders "TRUE"  
      #Create /Configure custom pkt   
      set custom1 [stc::create custom:Custom -under $hStream -pattern $hexstring ]

      #Store the packet header
      lappend m_PduNameList $pduName
      set m_PduHandleList($pduName) $custom1
                
      debugPut "exit the proc of AddCustomPacketIntoStream"     
}

############################################################################
#APIName: CreatePIMPkt
#Description: Create PIM packet under stream
#Input: 1. args:argument list, including
#              (1) -PduName required，
#              (2) -Type required，message type
#              (3) -Version optional, protocol version
#              (4) -Reserved optional，reserved bit
#              (5) -OptionType optional
#              (6) -OptionLength optional
#              (7) -OptionValue optional
#              (8) -UnicastAddrFamily optional
#              (9) -UnicastIpAddr optional
#             (10) -GroupNum optional
#             (11) -HoldTime optional
#             (12) -GroupIpAddr optional
#             (13) -GroupIpBBit optional，
#             (14) -GroupIpZBit optional，
#             (15) -SourceIpAddr optional
#             (16) -PrunedSourceIpAddr optional
#             (17) -RegBorderBit optional
#             (18) -RegNullRegBit optional
#             (19) -RegReservedField optional
#             (20) -RegEncapMultiPkt optional
#             (21) -RegGroupIpAddr optional
#             (22) -RegSourceIpAddr optional
#             (23) -AssertRptBit optional
#             (24) -AssertMetricPerf optional
#             (25) -AssertMetric optional
#
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body PacketBuilder::CreatePIMPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreatePIMPkt"

    set args [ConvertAttrToLowerCase $args]     

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreatePIMPkt "
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "PIMPacket"
    set PduConfigList ""
    
    #Parse Type parameter    
    set index [lsearch $args -type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify Message Type for PacketBuilder::CreatePIMPkt "
    } 

    lappend PduConfigList -Type
    lappend PduConfigList $Type    
    
    #Parse Version parameter    
    set index [lsearch $args -version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
    } else  {
        set Version 2
    }    

    lappend PduConfigList -Version
    lappend PduConfigList $Version
    
     #Parse Reserved parameter    
    set index [lsearch $args -reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    } else  {
        set Reserved 0
    }    

    lappend PduConfigList -Reserved
    lappend PduConfigList $Reserved   
    
    #Parse OptionType parameter    
    set index [lsearch $args -optiontype] 
    if {$index != -1} {
        set OptionType [lindex $args [expr $index + 1]]
    } else  {
        set OptionType HoldTime
    }    

    lappend PduConfigList -OptionType
    lappend PduConfigList $OptionType
    
     #Parse OptionLength parameter    
    set index [lsearch $args -optionlength] 
    if {$index != -1} {
        set OptionLength [lindex $args [expr $index + 1]]
    } else  {
        set OptionLength 2
    }    

    lappend PduConfigList -OptionLength
    lappend PduConfigList $OptionLength   
    
     #Parse OptionValue parameter    
    set index [lsearch $args -optionvalue] 
    if {$index != -1} {
        set OptionValue [lindex $args [expr $index + 1]]
    } else  {
        set OptionValue 105
    }    

    lappend PduConfigList -OptionValue
    lappend PduConfigList $OptionValue   
    
    #Parse UnicastAddrFamily parameter    
    set index [lsearch $args -unicastaddrfamily] 
    if {$index != -1} {
        set UnicastAddrFamily [lindex $args [expr $index + 1]]
    } else  {
        set UnicastAddrFamily IPv4
    }    

    lappend PduConfigList -UnicastAddrFamily
    lappend PduConfigList $UnicastAddrFamily   
    
     #Parse UnicastIpAddr parameter    
    set index [lsearch $args -unicastipaddr] 
    if {$index != -1} {
        set UnicastIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set UnicastIpAddr 192.0.0.1
    }    

    lappend PduConfigList -UnicastIpAddr
    lappend PduConfigList $UnicastIpAddr   
    
    #Parse GroupNum parameter    
    set index [lsearch $args -groupnum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    } else  {
        set GroupNum 1
    }    

    lappend PduConfigList -GroupNum
    lappend PduConfigList $GroupNum    
    
    #Parse HoldTime parameter    
    set index [lsearch $args -holdtime] 
    if {$index != -1} {
        set HoldTime [lindex $args [expr $index + 1]]
    } else  {
        set HoldTime 105
    }    

    lappend PduConfigList -HoldTime
    lappend PduConfigList $HoldTime    
    
    #Parse JoinedSourceNum parameter    
    set index [lsearch $args -joinedsourcenum] 
    if {$index != -1} {
        set JoinedSourceNum [lindex $args [expr $index + 1]]
    } else  {
        set JoinedSourceNum 1
    }    

    lappend PduConfigList -JoinedSourceNum
    lappend PduConfigList $JoinedSourceNum      
    
     #Parse PrunedSourceNum parameter    
    set index [lsearch $args -prunedsourcenum] 
    if {$index != -1} {
        set PrunedSourceNum [lindex $args [expr $index + 1]]
    } else  {
        set PrunedSourceNum 1
    }    

    lappend PduConfigList -PrunedSourceNum
    lappend PduConfigList $PrunedSourceNum     
    
    #Parse GroupIpAddr parameter    
    set index [lsearch $args -groupipaddr] 
    if {$index != -1} {
        set GroupIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set GroupIpAddr 225.0.0.1
    }    

    lappend PduConfigList -GroupIpAddr
    lappend PduConfigList $GroupIpAddr    
    
    #Parse GroupIpBBit parameter    
    set index [lsearch $args -groupipbbit] 
    if {$index != -1} {
        set GroupIpBBit [lindex $args [expr $index + 1]]
    } else  {
        set GroupIpBBit 0
    }    

    lappend PduConfigList -GroupIpBBit
    lappend PduConfigList $GroupIpBBit    
    
    #Parse GroupIpZBit parameter    
    set index [lsearch $args -groupipzbit] 
    if {$index != -1} {
        set GroupIpZBit [lindex $args [expr $index + 1]]
    } else  {
        set GroupIpZBit 0
    }    

    lappend PduConfigList -GroupIpZBit
    lappend PduConfigList $GroupIpZBit    
    
    #Parse SourceIpAddr parameter    
    set index [lsearch $args -sourceipaddr] 
    if {$index != -1} {
        set SourceIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set SourceIpAddr 192.0.0.1
    }    

    lappend PduConfigList -SourceIpAddr
    lappend PduConfigList $SourceIpAddr    
    
    #Parse PrunedSourceIpAddr parameter    
    set index [lsearch $args -prunedsourceipaddr] 
    if {$index != -1} {
        set PrunedSourceIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set PrunedSourceIpAddr 192.0.0.1
    }    

    lappend PduConfigList -PrunedSourceIpAddr
    lappend PduConfigList $PrunedSourceIpAddr        

    #Parse RegBorderBit parameter    
    set index [lsearch $args -regborderbit] 
    if {$index != -1} {
        set RegBorderBit [lindex $args [expr $index + 1]]
    } else  {
        set RegBorderBit 0
    }    

    lappend PduConfigList -RegBorderBit
    lappend PduConfigList $RegBorderBit

    #Parse RegNullRegBit parameter    
    set index [lsearch $args -regnullregbit] 
    if {$index != -1} {
        set RegNullRegBit [lindex $args [expr $index + 1]]
    } else  {
        set RegNullRegBit 0
    }    

    lappend PduConfigList -RegNullRegBit
    lappend PduConfigList $RegNullRegBit

    #Parse RegReservedField parameter    
    set index [lsearch $args -regreservedfield] 
    if {$index != -1} {
        set RegReservedField [lindex $args [expr $index + 1]]
    } else  {
        set RegReservedField 0
    }    

    lappend PduConfigList -RegReservedField
    lappend PduConfigList $RegReservedField

    #Parse RegEncapMultiPkt parameter    
    set index [lsearch $args -regencapmultipkt] 
    if {$index != -1} {
        set RegEncapMultiPkt [lindex $args [expr $index + 1]]
    } else  {
        set RegEncapMultiPkt ""
    }    

    lappend PduConfigList -RegEncapMultiPkt
    lappend PduConfigList $RegEncapMultiPkt

    #Parse RegGroupIpAddr parameter    
    set index [lsearch $args -reggroupipaddr] 
    if {$index != -1} {
        set RegGroupIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set RegGroupIpAddr 225.0.0.1
    }    

    lappend PduConfigList -RegGroupIpAddr
    lappend PduConfigList $RegGroupIpAddr

    #Parse RegSourceIpAddr parameter    
    set index [lsearch $args -regsourceipaddr] 
    if {$index != -1} {
        set RegSourceIpAddr [lindex $args [expr $index + 1]]
    } else  {
        set RegSourceIpAddr 192.0.0.1
    }    

    lappend PduConfigList -RegSourceIpAddr
    lappend PduConfigList $RegSourceIpAddr

    #Parse AssertRptBit parameter    
    set index [lsearch $args -assertrptbit] 
    if {$index != -1} {
        set AssertRptBit [lindex $args [expr $index + 1]]
    } else  {
        set AssertRptBit 0
    }    

    lappend PduConfigList -AssertRptBit
    lappend PduConfigList $AssertRptBit

    #Parse AssertMetricPerf parameter    
    set index [lsearch $args -assertmetricperf] 
    if {$index != -1} {
        set AssertMetricPerf [lindex $args [expr $index + 1]]
    } else  {
        set AssertMetricPerf 0
    }    

    lappend PduConfigList -AssertMetricPerf
    lappend PduConfigList $AssertMetricPerf

    #Parse AssertMetric parameter    
    set index [lsearch $args -assertmetric] 
    if {$index != -1} {
        set AssertMetric [lindex $args [expr $index + 1]]
    } else  {
        set AssertMetric 2
    }    

    lappend PduConfigList -AssertMetric
    lappend PduConfigList $AssertMetric


    lappend ::mainDefine::gPduConfigList "$PduConfigList"
        
    debugPut "exit the proc of PacketBuilder::CreatePIMPkt" 
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: AddPIMPacketIntoStream
#Description: Add PIM packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body Stream::AddPIMPacketIntoStream {args hStream pduName} { 
    
    #Parse Type parameter    
    set index [lsearch $args -Type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } 
    
    #Parse Version parameter    
    set index [lsearch $args -Version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
    }
    
    #Parse Reserved parameter    
    set index [lsearch $args -Reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    }

    #Parse OptionType parameter    
    set index [lsearch $args -OptionType] 
    if {$index != -1} {
        set OptionType [lindex $args [expr $index + 1]]
    }

    #Parse OptionLength parameter    
    set index [lsearch $args -OptionLength] 
    if {$index != -1} {
        set OptionLength [lindex $args [expr $index + 1]]
    }
    
    #Parse OptionValue parameter    
    set index [lsearch $args -OptionValue] 
    if {$index != -1} {
        set OptionValue [lindex $args [expr $index + 1]]
        if {$OptionType == "LanPruneDelay"} {
            set TBit [lindex $OptionValue 0]
            set LanPruneDelay [lindex $OptionValue 1]
            set OverrideInterval [lindex $OptionValue 2]
        }
    }

    #Parse UnicastAddrFamily parameter    
    set index [lsearch $args -UnicastAddrFamily] 
    if {$index != -1} {
        set UnicastAddrFamily [lindex $args [expr $index + 1]]
    }

    #Parse UnicastIpAddr parameter    
    set index [lsearch $args -UnicastIpAddr] 
    if {$index != -1} {
        set UnicastIpAddr [lindex $args [expr $index + 1]]
    }
    
    #Parse GroupNum parameter    
    set index [lsearch $args -GroupNum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    }

    #Parse HoldTime parameter    
    set index [lsearch $args -HoldTime] 
    if {$index != -1} {
        set HoldTime [lindex $args [expr $index + 1]]
    }
    
    #Parse JoinedSourceNum parameter    
    set index [lsearch $args -JoinedSourceNum] 
    if {$index != -1} {
        set JoinedSourceNum [lindex $args [expr $index + 1]]
    }   
    
    #Parse PrunedSourceNum parameter    
    set index [lsearch $args -PrunedSourceNum] 
    if {$index != -1} {
        set PrunedSourceNum [lindex $args [expr $index + 1]]
    }    

    #Parse GroupIpAddr parameter    
    set index [lsearch $args -GroupIpAddr] 
    if {$index != -1} {
        set GroupIpAddr [lindex $args [expr $index + 1]]
    }
    
    #Parse GroupIpBBit parameter    
    set index [lsearch $args -GroupIpBBit] 
    if {$index != -1} {
        set GroupIpBBit [lindex $args [expr $index + 1]]
    }

    #Parse GroupIpZBit parameter    
    set index [lsearch $args -GroupIpZBit] 
    if {$index != -1} {
        set GroupIpZBit [lindex $args [expr $index + 1]]
    }

    #Parse SourceIpAddr parameter    
    set index [lsearch $args -SourceIpAddr] 
    if {$index != -1} {
        set SourceIpAddr [lindex $args [expr $index + 1]]
    }
    
    #Parse PrunedSourceIpAddr parameter    
    set index [lsearch $args -PrunedSourceIpAddr] 
    if {$index != -1} {
        set PrunedSourceIpAddr [lindex $args [expr $index + 1]]
    }

    #Parse RegBorderBit parameter    
    set index [lsearch $args -RegBorderBit] 
    if {$index != -1} {
        set RegBorderBit [lindex $args [expr $index + 1]]
    }

    #Parse RegNullRegBit parameter    
    set index [lsearch $args -RegNullRegBit] 
    if {$index != -1} {
        set RegNullRegBit [lindex $args [expr $index + 1]]
    }
    
    #Parse RegReservedField parameter    
    set index [lsearch $args -RegReservedField] 
    if {$index != -1} {
        set RegReservedField [lindex $args [expr $index + 1]]
    }

    #Parse RegEncapMultiPkt parameter    
    set index [lsearch $args -RegEncapMultiPkt] 
    if {$index != -1} {
        set RegEncapMultiPkt [lindex $args [expr $index + 1]]
    }

    #Parse RegGroupIpAddr parameter    
    set index [lsearch $args -RegGroupIpAddr] 
    if {$index != -1} {
        set RegGroupIpAddr [lindex $args [expr $index + 1]]
    }
    
    #Parse RegSourceIpAddr parameter    
    set index [lsearch $args -RegSourceIpAddr] 
    if {$index != -1} {
        set RegSourceIpAddr [lindex $args [expr $index + 1]]
    }

    #Parse AssertRptBit parameter    
    set index [lsearch $args -AssertRptBit] 
    if {$index != -1} {
        set AssertRptBit [lindex $args [expr $index + 1]]
    }

    #Parse AssertMetricPerf parameter    
    set index [lsearch $args -AssertMetricPerf] 
    if {$index != -1} {
        set AssertMetricPerf [lindex $args [expr $index + 1]]
    }
    
    #Parse AssertMetric parameter    
    set index [lsearch $args -AssertMetric] 
    if {$index != -1} {
        set AssertMetric [lindex $args [expr $index + 1]]
    }

    switch $UnicastAddrFamily {
        IPv4 {
            set AddrFamily 1
        }
        IPv6 {
            set AddrFamily 2
        }
        HDLC {
            set AddrFamily 4
        }
    }
    
    #Configure associated objects
    switch $Type {
        Hello {
            #Configure header
            set hPim [stc::create pim:Pimv4Hello -under $hStream] 
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPim

            set hHeader [stc::create Header -under $hPim]
            stc::config $hHeader -type 0 -version $Version -reserved $Reserved
            #Configure Option
            set hOptions [stc::create Options -under $hPim]
            set hPimv4HelloOption [stc::create Pimv4HelloOption -under $hOptions]
            set hPimv4HelloOptionType [stc::create $OptionType -under $hPimv4HelloOption]
            stc::config $hPimv4HelloOptionType -length $OptionLength -value $OptionValue      
        }
        Join_Prune {
            set hPim [stc::create pim:Pimv4JoinPrune -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPim
  
            stc::config $hPim -holdTime $HoldTime -numGroups $GroupNum   
            #Configure header
            set hHeader [stc::create Header -under $hPim] 
            stc::config $hHeader -type 3 -version $Version -reserved $Reserved
            #Configure UpstreamNeighbor  
            set hUpstreamNbr [stc::create UpstreamNbr -under $hPim]
            stc::config $hUpstreamNbr -addrFamily $AddrFamily -address $UnicastIpAddr
            #Configure GroupRecords
            set hGroupRecords [stc::create groupRecords -under $hPim] 
            set hJoinPrunev4GroupRecord [stc::create JoinPrunev4GroupRecord -under $hGroupRecords]  
            stc::config $hJoinPrunev4GroupRecord -numJoin $JoinedSourceNum -numPrune $PrunedSourceNum
            set hGroupAddr [stc::create groupAddr -under $hJoinPrunev4GroupRecord]
            stc::config $hGroupAddr -address $GroupIpAddr -addrFamily UnicastAddrFamily \
                -bBit $GroupIpBBit -zBit $GroupIpZBit
            #Configure JoinedSource    
            set hJoinedSource [stc::create joinedSources -under $hJoinPrunev4GroupRecord] 
            set hSourceAddr [stc::create EncodedSourceIpv4Address -under $hJoinedSource]
            stc::config $hSourceAddr -address $SourceIpAddr 
            #Configure PrunedSource
            set hPrunedSource [stc::create prunedSources -under $hJoinPrunev4GroupRecord]
            set hSourceAddr [stc::create EncodedSourceIpv4Address -under $hPrunedSource]               
            stc::config $hSourceAddr -address $PrunedSourceIpAddr                    
        }
        Register {
            set hPim [stc::create pim:Pimv4Register -under $hStream] 
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPim

            stc::config $hPim -borderBit $RegBorderBit \
                -nullBit $RegNullRegBit -reserved $RegReservedField -multicastPacket $RegEncapMultiPkt
            set hHeader [stc::create Header -under $hPim] 
            stc::config $hHeader -type 1 -Version $Version -Reserved $Reserved              
        }
        Register_Stop {
            set hPim [stc::create pim:Pimv4RegisterStop -under $hStream]  
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPim

            #Configure Header     
            set hHeader [stc::create Header -under $hPim] 
            stc::config $hHeader -type 2 -version $Version -reserved $Reserved
            #Configure CroupAddr          
            set hGroupAddr [stc::create groupAddr -under $hPim]       
            stc::config $hGroupAddr -address $RegGroupIpAddr -addrFamily UnicastAddrFamily \
                -bBit $GroupIpBBit -zBit $GroupIpZBit            
            set hSourceAddr [stc::create sourceAddr -under $hPim]  
            stc::config $hSourceAddr -address $RegSourceIpAddr                       
        }
        Assert {
            set hPim [stc::create pim:Pimv4Assert -under $hStream]  
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPim
    
            stc::config $hPim -rBit $AssertRptBit -metricPref $AssertMetricPerf -metric $AssertMetric
            #Configure Header
            set hHeader [stc::create Header -under $hPim] 
            stc::config $hHeader -type 5 -version $Version -reserved $Reserved
            set hGroupAddr [stc::create groupAddr -under $hPim] 
            #Configure GroupAddr
            stc::config $hGroupAddr -address $GroupIpAddr -addrFamily UnicastAddrFamily \
                -bBit $GroupIpBBit -zBit $GroupIpZBit
            set hSourceAddr [stc::create sourceAddr -under $hPim] 
            stc::config $hSourceAddr -address $SourceIpAddr                    
        }
        default {
            error "The specified Type of CreatePIMPacket is invalid"
        }
    }
}  

############################################################################
#APIName: CreatePPPoEPkt
#Description: Create PPPoE packet under stream block
#Input: 1. args:argument list, including
#              (1) -PduName required
#              (2) -PPPoEType required，PPPoE packet type
#              (4) -Version optional， packet protocol version
#              (5) -Type optional， packet protocol type
#              (7) -Code optional， packet code
#              (8) -SessionId optional，transaction ID
#              (9) -Length optional， packet length
#            (10) -Tag optional， packet tag
#            (11) -TagLength optional， packet tag length(16 hex)
#            (12) -TagValue optional， packet tag value(16 hex)
#
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body PacketBuilder::CreatePPPoEPkt {args} {

    debugPut "enter the proc of PacketBuilder::CreatePPPoEPkt"
    set args [ConvertAttrToLowerCase $args]     

    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreatePPPoEPkt"
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "PPPoEPacket"
    set PduConfigList ""             

    #Parse PPPoEType parameter    
    set index [lsearch $args -pppoetype] 
    if {$index != -1} {
        set PPPoEType [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PPPoEType for PacketBuilder::CreatePPPoEPkt"
    } 
    
    lappend PduConfigList -PPPoEType
    lappend PduConfigList $PPPoEType   
 
    #Parse Version parameter    
    set index [lsearch $args -version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
    } else  {
        set Version 1
    } 
    
    lappend PduConfigList -Version
    lappend PduConfigList $Version        
        
    #Parse Type parameter    
    set index [lsearch $args -type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } else  {
        set Type 1
    } 
    
    lappend PduConfigList -Type
    lappend PduConfigList $Type   
    
    #Parse Code parameter    
    set index [lsearch $args -code] 
    if {$index != -1} {
        set Code [lindex $args [expr $index + 1]]
    } else  {
        set Code ""
    } 
    
    lappend PduConfigList -Code
    lappend PduConfigList $Code       
    
    #Parse SessionId parameter    
    set index [lsearch $args -sessionid] 
    if {$index != -1} {
        set SessionId [lindex $args [expr $index + 1]]
    } else  {
        set SessionId 0
    } 
    
    lappend PduConfigList -SessionId
    lappend PduConfigList $SessionId       
    
    #Parse Length parameter    
    set index [lsearch $args -length] 
    if {$index != -1} {
        set Length [lindex $args [expr $index + 1]]
    } else  {
        set Length 0
    } 
    
    lappend PduConfigList -Length
    lappend PduConfigList $Length      
    
    #Parse Tag parameter    
    set index [lsearch $args -tag] 
    if {$index != -1} {
        set Tag [lindex $args [expr $index + 1]]
    } else  {
        set Tag ""
    } 
    
    lappend PduConfigList -Tag
    lappend PduConfigList $Tag     
    
    #Parse TagLength parameter    
    set index [lsearch $args -taglength] 
    if {$index != -1} {
        set TagLength [lindex $args [expr $index + 1]]
    } else  {
        set TagLength 0
    } 
    
    lappend PduConfigList -TagLength
    lappend PduConfigList $TagLength    
    
      #Parse TagValue parameter    
    set index [lsearch $args -tagvalue] 
    if {$index != -1} {
        set TagValue [lindex $args [expr $index + 1]]
    } else  {
        set TagValue 0
    } 
    
    lappend PduConfigList -TagValue
    lappend PduConfigList $TagValue            

    lappend ::mainDefine::gPduConfigList "$PduConfigList"        
    
    debugPut "exit the proc of PacketBuilder::CreatePPPoEPkt" 
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: AddPPPoEPacketIntoStream
#Description: Add PPPoE packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body Stream::AddPPPoEPacketIntoStream {args hStream pduName} {     
    #Parse PPPoEType parameter    
    set index [lsearch $args -PPPoEType] 
    if {$index != -1} {
        set PPPoEType [lindex $args [expr $index + 1]]
    }
    
    #Parse Version parameter    
    set index [lsearch $args -Version] 
    if {$index != -1} {
        set Version [lindex $args [expr $index + 1]]
    } 

    #Parse Type parameter    
    set index [lsearch $args -Type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } 
    
    #Parse Code parameter    
    set index [lsearch $args -Code] 
    if {$index != -1} {
        set Code [lindex $args [expr $index + 1]]
    }    
    
    #Parse SessionId parameter    
    set index [lsearch $args -SessionId] 
    if {$index != -1} {
        set SessionId [lindex $args [expr $index + 1]]
    }    
    
    #Parse Length parameter    
    set index [lsearch $args -Length] 
    if {$index != -1} {
        set Length [lindex $args [expr $index + 1]]
    }     
    
    #Parse Tag parameter    
    set index [lsearch $args -Tag] 
    if {$index != -1} {
        set Tag [lindex $args [expr $index + 1]]
    }     
    
    #Parse TagLength parameter    
    set index [lsearch $args -TagLength] 
    if {$index != -1} {
        set TagLength [lindex $args [expr $index + 1]]
    } 
    
    #Parse TagValue parameter    
    set index [lsearch $args -TagValue] 
    if {$index != -1} {
        set TagValue [lindex $args [expr $index + 1]]
    }     
    
    #Code parameter conversion
    switch $Code {
        PADI {
            set PCode 9
        }
        PADR {
            set PCode 25
        }
        PADS {
            set PCode 101
        }
        PADO {
            set PCode 7
        }  
        PADT {
            set PCode 167
        }
        default {
            if {$PPPoEType != "PPPoE_Session" } {
                error "The specified Type of CreatePPPoEPkt is invalid"
            }
        }     
    }   
    
    set m_mplsType "pppoesession"

    #Configure associated objects
    switch $PPPoEType {
        PPPoE_Discovery {
            #Modify upper layer eth type to PPPoE_Discovery
            set ethHandle [stc::get $hStream -children-ethernet:ethernetii]
            stc::config $ethHandle -etherType 8863
            #Configure PPPoE Discovery报头
            set hPPPoE [stc::create pppoe:PPPoEDiscovery -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPPPoE

            stc::config $hPPPoE \
                -version $Version \
                -type $Type \
                -code $PCode \
                -sessionId $SessionId \
                -length $Length
            if {$Tag != "" } {
                set hTag [stc::create tags -under $hPPPoE]
                set hPPPoETag [stc::create PPPoETag -under $hTag]
                set hTag1 [stc::create $Tag -under $hPPPoETag]
                stc::config $hTag1 \
                    -length $TagLength \
                    -value $TagValue
            }
            
        }
        PPPoE_Session {
            #Modify upper layer eth type to PPPoE_Session
            set ethHandle [stc::get $hStream -children-ethernet:ethernetii]
            stc::config $ethHandle -etherType 8864       
            set hPPPoE [stc::create pppoe:PPPoESession -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hPPPoE

            stc::config $hPPPoE \
                -version $Version \
                -type $Type \
                -code $Code \
                -sessionId $SessionId \
                -length $Length     
        }
        default {
            error "The specified PPPoEType of CreatePPPoEPkt is invalid"
        }
    }
}  

############################################################################
#APIName: CreateIGMPPkt
#Description: Create IGMP packet under stream
#Input: 1. args:argument list, including
#              (1) -PduName required
#              (2) -ProtocolVer optional，Protocol version，defualt value is IGMPv2
#              (3) -ProtocolType required，IGMP message type
#              (4) -GroupStartIp optional，groups start address
#              (5) -GroupCount optional，group address count，default value is 1
#              (6) -IncreaseStep optional，increase step，default value is 1
#              (7) -MaxRespTime optional，IGMPv2 max response time
#              (8) -SFlag optional，IGMPv3Query sFalg
#              (9) -QRV optional，default is 0
#              (10) -QQIC optional，default is 0
#              (11) -SrcNum optional，IGMPv3 source address number(including Query and Report)
#              (12) -SrcIp1 optional，source IP address
#              (13) -SrcIp2 optional，source IP address
#              (14) ...
#              (15) -Reserved optional，IGMPv3Report reserved bit
#              (16) -GroupRecords optional，IGMPv3Report group records
#              (17) -GroupType optional，IGMPv3Report group type
#              (18) -AuxLen optional，IGMPv3Report Aux length
#              (19) -GroupIP optional，IGMPv3Report group IP address
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body PacketBuilder::CreateIGMPPkt {args} {
    
    debugPut "enter the proc of PacketBuilder::CreateIGMPPkt"
    set args [ConvertAttrToLowerCase $args]     
     
    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateIGMPPkt"
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "IGMPPacket"
    set PduConfigList ""   
        
    #Parse ProtocolVer parameter    
    set index [lsearch $args -protocolver] 
    if {$index != -1} {
        set ProtocolVer [lindex $args [expr $index + 1]]
    } else  {
        set ProtocolVer "IGMPv2"
    } 
    
    lappend PduConfigList -ProtocolVer
    lappend PduConfigList $ProtocolVer

    #Parse ProtocolType parameter    
    set index [lsearch $args -protocoltype] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify Message Type for PacketBuilder::CreateIGMPPkt"
    } 
    
    lappend PduConfigList -Type
    lappend PduConfigList $Type        
    
    #Parse GroupStartIp parameter    
    set index [lsearch $args -groupstartip] 
    if {$index != -1} {
        set GroupAddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupStartIp for PacketBuilder:CreateIGMPPkt"
    } 
    
    lappend PduConfigList -GroupAddr
    lappend PduConfigList $GroupAddr     
        
    #Parse GroupCount parameter    
    set index [lsearch $args -groupcount] 
    if {$index != -1} {
        set GroupCount [lindex $args [expr $index + 1]]
    } else  {
        set GroupCount 1
    } 
    
    lappend PduConfigList -GroupCount
    lappend PduConfigList $GroupCount    

    #Parse IncreaseStep parameter    
    set index [lsearch $args -increasestep] 
    if {$index != -1} {
        set IncreaseStep [lindex $args [expr $index + 1]]
    } else  {
        set IncreaseStep 1
    } 
    
    lappend PduConfigList -IncreaseStep
    lappend PduConfigList $IncreaseStep    

    #Parse MaxRespTime parameter    
    set index [lsearch $args -maxresptime] 
    if {$index != -1} {
        set MaxReponseTime [lindex $args [expr $index + 1]]
    } else  {
        set MaxReponseTime 0
    } 
    
    lappend PduConfigList -MaxReponseTime
    lappend PduConfigList $MaxReponseTime         
   
    #Parse Checksum parameter    
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set Checksum [lindex $args [expr $index + 1]]
    } else  {
        set Checksum 0
    } 
    
    lappend PduConfigList -Checksum
    lappend PduConfigList $Checksum         
   
    #Parse Sflag parameter    
    set index [lsearch $args -sflag] 
    if {$index != -1} {
        set SuppressFlag [lindex $args [expr $index + 1]]
    } else  {
        set SuppressFlag 0
    } 
    
    lappend PduConfigList -SuppressFlag
    lappend PduConfigList $SuppressFlag     

    #Parse QRV parameter    
    set index [lsearch $args -qrv] 
    if {$index != -1} {
        set QRV [lindex $args [expr $index + 1]]
    } else  {
        set QRV 0
    } 
    
    lappend PduConfigList -QRV
    lappend PduConfigList $QRV     

    #Parse QQIC parameter    
    set index [lsearch $args -qqic] 
    if {$index != -1} {
        set QQIC [lindex $args [expr $index + 1]]
    } else  {
        set QQIC 0
    } 
    
    lappend PduConfigList -QQIC
    lappend PduConfigList $QQIC     

    #Parse SrcNum parameter    
    set index [lsearch $args -srcnum] 
    if {$index != -1} {
        set SourceNum [lindex $args [expr $index + 1]]
    } else  {
        set SourceNum 0
    } 
    
    lappend PduConfigList -SourceNum
    lappend PduConfigList $SourceNum     
    
    set IpList ""
    for {set i 0} {$i < $SourceNum} {incr i} {
           set ParaName "srcip[expr $i + 1]"
           set index [lsearch $args -$ParaName] 
           if {$index != -1} {
               lappend IpList [lindex $args [expr $index + 1]]
           }
    } 
    
    if {$IpList == ""} {
         set IpList "192.0.0.1"
    }
   
    lappend PduConfigList -SrcIpList
    lappend PduConfigList $IpList     

    #Parse Reserved parameter    
    set index [lsearch $args -reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    } else  {
        set Reserved 0
    } 
    
    lappend PduConfigList -Reserved
    lappend PduConfigList $Reserved   


    #Parse GroupRecords parameter    
    set index [lsearch $args -grouprecords] 
    if {$index != -1} {
        set GroupRecords [lindex $args [expr $index + 1]]
    } else  {
        set GroupRecords TRUE
    } 
    
    lappend PduConfigList -GroupRecords
    lappend PduConfigList $GroupRecords   

    #Parse GroupNum parameter    
    set index [lsearch $args -groupnum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    } else  {
        set GroupNum 0
    } 
    
    lappend PduConfigList -GroupNum
    lappend PduConfigList $GroupNum   

    #Parse GroupType parameter    
    set index [lsearch $args -grouptype] 
    if {$index != -1} {
        set RecordType [lindex $args [expr $index + 1]]
    } else  {
        set RecordType ALLOW_NEW_SOURCES
    } 
    
    lappend PduConfigList -RecordType
    lappend PduConfigList $RecordType   


    #Parse AuxLen parameter    
    set index [lsearch $args -auxlen] 
    if {$index != -1} {
        set AuxiliaryDataLen [lindex $args [expr $index + 1]]
    } else  {
        set AuxiliaryDataLen 0
    } 
    
    lappend PduConfigList -AuxiliaryDataLen
    lappend PduConfigList $AuxiliaryDataLen   

    #Parse GroupIP parameter    
    set index [lsearch $args -groupip] 
    if {$index != -1} {
        set MulticastAddr [lindex $args [expr $index + 1]]
    } else  {
        set MulticastAddr "225.0.0.1"
    } 
    
    lappend PduConfigList -MulticastAddr
    lappend PduConfigList $MulticastAddr   

    lappend ::mainDefine::gPduConfigList "$PduConfigList"
       
    debugPut "exit the proc of PacketBuilder::CreateIGMPPkt" 
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: AddIGMPPacketIntoStream
#Description: Add PPPoE packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body Stream::AddIGMPPacketIntoStream {args hStream pduName} { 
    
    #Parse ProtocolVer parameter    
    set index [lsearch $args -ProtocolVer] 
    if {$index != -1} {
        set ProtocolVer [lindex $args [expr $index + 1]]
    }

    #Parse Type parameter    
    set index [lsearch $args -Type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } 
        
    #Parse GroupAddr parameter    
    set index [lsearch $args -GroupAddr] 
    if {$index != -1} {
        set GroupAddr [lindex $args [expr $index + 1]]
    }

    #Parse GroupCount parameter    
    set index [lsearch $args -GroupCount] 
    if {$index != -1} {
        set GroupCount [lindex $args [expr $index + 1]]
    }

    #Parse IncreaseStep parameter    
    set index [lsearch $args -IncreaseStep] 
    if {$index != -1} {
        set IncreaseStep [lindex $args [expr $index + 1]]
    }
    
    #Parse MaxReponseTime parameter    
    set index [lsearch $args -MaxReponseTime] 
    if {$index != -1} {
        set MaxReponseTime [lindex $args [expr $index + 1]]
    }    
     
    #Parse Checksum parameter    
    set index [lsearch $args -Checksum] 
    if {$index != -1} {
        set Checksum [lindex $args [expr $index + 1]]
    }

     #Parse SuppressFlag parameter    
    set index [lsearch $args -SuppressFlag] 
    if {$index != -1} {
        set SuppressFlag [lindex $args [expr $index + 1]]
    }   

    #Parse QRV parameter    
    set index [lsearch $args -QRV] 
    if {$index != -1} {
        set QRV [lindex $args [expr $index + 1]]
    }

    #Parse QQIC parameter    
    set index [lsearch $args -QQIC] 
    if {$index != -1} {
        set QQIC [lindex $args [expr $index + 1]]
    }
    
    #Parse SourceNum parameter    
    set index [lsearch $args -SourceNum] 
    if {$index != -1} {
        set SourceNum [lindex $args [expr $index + 1]]
    }    

     #Parse SrcIpList parameter    
    set index [lsearch $args -SrcIpList] 
    if {$index != -1} {
        set SrcIpList [lindex $args [expr $index + 1]]
    }    

     #Parse Reserved parameter    
    set index [lsearch $args -Reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    }   
    
     #Parse GroupRecords parameter    
    set index [lsearch $args -GroupRecords] 
    if {$index != -1} {
        set GroupRecords [lindex $args [expr $index + 1]]
    }   

    #Parse GroupNum parameter    
    set index [lsearch $args -GroupNum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    }

     #Parse RecordType parameter    
    set index [lsearch $args -RecordType] 
    if {$index != -1} {
        set RecordType [lindex $args [expr $index + 1]]
    }   

     #Parse AuxiliaryDataLen parameter    
    set index [lsearch $args -AuxiliaryDataLen] 
    if {$index != -1} {
        set AuxiliaryDataLen [lindex $args [expr $index + 1]]
    }   

     #Parse MulticastAddr parameter    
    set index [lsearch $args -MulticastAddr] 
    if {$index != -1} {
        set MulticastAddr [lindex $args [expr $index + 1]]
    }       
    
    #IGMPv3 RecordType conversion
    switch $RecordType {
        ALLOW_NEW_SOURCES {
            set RcdType 5
        }
        BLOCK_OLD_SOURCES {
            set RcdType 6
        }
        CHANGE_TO_EXCLUDE_MODE {
            set RcdType 4
        }
        CHANGE_TO_INCLUDE_MODE {
            set RcdType 3
        }  
        MODE_IS_EXCLUDE {
            set RcdType 2
        }
        MODE_IS_INCLUDE {
            set RcdType 1
        }             
   }
    
   set Type [string tolower $Type] 

   set IgmpType "unknown"
   if {[string tolower $ProtocolVer] == "igmpv1" } {
        if {$Type == "membershipreport" } {
             set IgmpType "igmpv1report"
        } elseif {$Type == "membershipquery" } {
             set IgmpType "igmpv1query"
        }
    } elseif {[string tolower $ProtocolVer] == "igmpv2" } {
        if {$Type == "membershipreport" } {
             set IgmpType "igmpv2report"
        } elseif {$Type == "membershipquery" } {
             set IgmpType "igmpv2query"
        } elseif {$Type == "leavegroup" } {
             set IgmpType "igmpv2leave"
        }
    } elseif {[string tolower $ProtocolVer] == "igmpv3" } {
       if {$Type == "membershipreport" } {
             set IgmpType "igmpv3report"
        } elseif {$Type == "membershipquery" } {
             set IgmpType "igmpv3query"
        } elseif {$Type == "leavegroup" } {
             set IgmpType "igmpv3leave"
        }
    }

    #Create IGMP packet object
    switch $IgmpType {
        igmpv1report {
            set hIgmp [stc::create igmp:Igmpv1 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp -type 2 -groupAddress $GroupAddr 
 
            if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
                           
        }
        igmpv1query {
            set hIgmp [stc::create igmp:Igmpv1 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp -type 1 -groupAddress $GroupAddr 
             if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
        }
        igmpv2report {
            set hIgmp [stc::create igmp:Igmpv2 -under $hStream]
             #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp -type 16 -maxRespTime $MaxReponseTime -groupAddress $GroupAddr 

             if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
        }
        igmpv2leave {
            set hIgmp [stc::create igmp:Igmpv2 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp -type 17 -maxRespTime $MaxReponseTime -groupAddress $GroupAddr 
             if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
        }
        igmpv2query {
            set hIgmp [stc::create igmp:Igmpv2 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp -type 11 -maxRespTime $MaxReponseTime -groupAddress $GroupAddr 
             if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
        }
        igmpv3query {
            set hIgmp [stc::create igmp:Igmpv3Query -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp
            
            stc::config $hIgmp \
                -type 11 \
                -maxRespTime $MaxReponseTime \
                -groupAddress $GroupAddr \
                -sFlag $SuppressFlag \
                -qrv $QRV \
                -qqic $QQIC \
                -numSource $SourceNum 
            set hAddrList [stc::create addrList -under $hIgmp]
            foreach SrcIp $SrcIpList {
                set hIpv4Addr [stc::create ipv4Addr -under $hAddrList]
                stc::config $hIpv4Addr -value $SrcIp
            } 

             if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }
        }
        igmpv3report {
            set hIgmp [stc::create igmp:Igmpv3Report -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hIgmp

            stc::config $hIgmp \
                -type 22 \
                -reserved $Reserved \
                -reserved2 $Reserved  -numGrpRecords $GroupNum

            set hgrpRecords [stc::create grpRecords -under $hIgmp]
            set hGrpRecord [stc::create GroupRecord -under $hgrpRecords]
            stc::config $hGrpRecord -auxDataLen $AuxiliaryDataLen \
                 -mcastAddr $MulticastAddr \
                 -recordType $RcdType  -numSource $SourceNum

            #Configure Addr List
            set hAddrList [stc::create addrList -under $hGrpRecord]
            foreach SrcIp $SrcIpList {
                set hIpv4Addr [stc::create ipv4Addr -under $hAddrList]
                stc::config $hIpv4Addr -value $SrcIp
            }  

            if {$Checksum != "0" } {
                 stc::config $hIgmp -checksum $Checksum
            }                                         
        }
        default {
            error "The specified Type of CreateIGMPPkt is invalid"
        }
    }   

    if {$GroupCount != "1" && $IgmpType != "igmpv3report" } {
        set igmp1 [stc::get $hIgmp -Name]
        set IgmpStep [Num2Ip $IncreaseStep ]

        stc::create "RangeModifier" \
                -under $hStream -EnableStream $m_EnableStream \
                -ModifierMode "INCR" \
                -Mask "255.255.255.255" \
                -StepValue $IgmpStep \
                -RecycleCount $GroupCount \
                -RepeatCount "0" \
                -Data $GroupAddr \
                -Offset "0" \
                -OffsetReference "$igmp1.groupAddress" \
                -Active "TRUE" \
                -Name "IGMP Modifier"
     } 
}  

############################################################################
#APIName: CreateMLDPkt
#Description: Create MLD packet under stream
#Input: 1. args:argument list, including
#              (1) -PduName required
#              (2) -ProtocolVer optional，Protocol version，default is MLDv1
#              (3) -ProtocolType required，MLD message type
#              (4) -GroupStartIp optional，group start IP
#              (5) -GroupCount optional，group count, default is 1
#              (6) -IncreaseStep optional，group address increase step，default is 1
#              (7) -MaxRespTime optional，MLD max response time
#              (8) -SFlag optional，MLD Query SFlag
#              (9) -QRV optional，default is 0
#              (10) -QQIC optional, default is 0
#              (11) -SrcNum optional，MLD source IP address(including Query and Report)
#              (12) -SrcIp optional，source ip address
#              (13) -Reserved optional，MLD Report reserved bit
#              (14) -GroupRecords optional，MLDv2Report group reports 
#              (15) -GroupType optional，MLDv2Report group type
#              (16) -GroupIP optional，MLDv2Report group ip address
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body PacketBuilder::CreateMLDPkt {args} {
    
    debugPut "enter the proc of PacketBuilder::CreateMLDPkt"
    set ::mainDefine::args $args
    uplevel 1 {
        set ::mainDefine::args [subst $::mainDefine::args]
    }
    set args $::mainDefine::args  

    set args [ConvertAttrToLowerCase $args]     
     
    #Parse PduName parameter    
    set index [lsearch $args -pduname] 
    if {$index != -1} {
        set PduName [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify PduName for PacketBuilder::CreateMLDPkt"
    }    

    set index [lsearch $::mainDefine::gPduNameList $PduName] 
    if {$index != -1} {
        error "PduName($PduName) is already existed,please specify another one "
    } 
    lappend ::mainDefine::gPduNameList $PduName
    lappend m_pduNameList $PduName
    lappend ::mainDefine::gPduConfigList $PduName
    lappend ::mainDefine::gPduConfigList "MLDPacket"
    set PduConfigList ""   
        
    #Parse ProtocolVer parameter    
    set index [lsearch $args -protocolver] 
    if {$index != -1} {
        set ProtocolVer [lindex $args [expr $index + 1]]
    } else  {
        set ProtocolVer "MLDv1"
    } 
    
    lappend PduConfigList -ProtocolVer
    lappend PduConfigList $ProtocolVer

    #Parse ProtocolType parameter    
    set index [lsearch $args -protocoltype] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify Message Type for PacketBuilder::CreateMLDPkt"
    } 
    
    lappend PduConfigList -Type
    lappend PduConfigList $Type        
    
    #Parse GroupStartIp parameter    
    set index [lsearch $args -groupstartip] 
    if {$index != -1} {
        set GroupAddr [lindex $args [expr $index + 1]]
    } else  {
        error "Please specify the GroupStartIp for PacketBuilder:CreateMLDPkt"
    } 
    
    lappend PduConfigList -GroupAddr
    lappend PduConfigList $GroupAddr     
        
    #Parse GroupCount parameter    
    set index [lsearch $args -groupcount] 
    if {$index != -1} {
        set GroupCount [lindex $args [expr $index + 1]]
    } else  {
        set GroupCount 1
    } 
    
    lappend PduConfigList -GroupCount
    lappend PduConfigList $GroupCount    

    #Parse IncreaseStep parameter    
    set index [lsearch $args -increasestep] 
    if {$index != -1} {
        set IncreaseStep [lindex $args [expr $index + 1]]
    } else  {
        set IncreaseStep 1
    } 
    
    lappend PduConfigList -IncreaseStep
    lappend PduConfigList $IncreaseStep    

    #Parse MaxRespTime parameter    
    set index [lsearch $args -maxresptime] 
    if {$index != -1} {
        set MaxReponseTime [lindex $args [expr $index + 1]]
    } else  {
        set MaxReponseTime 100
    } 
    
    lappend PduConfigList -MaxReponseTime
    lappend PduConfigList $MaxReponseTime         
   
    #Parse Checksum parameter    
    set index [lsearch $args -checksum] 
    if {$index != -1} {
        set Checksum [lindex $args [expr $index + 1]]
    } else  {
        set Checksum 0
    } 
    
    lappend PduConfigList -Checksum
    lappend PduConfigList $Checksum         
   
    #Parse Sflag parameter    
    set index [lsearch $args -sflag] 
    if {$index != -1} {
        set SuppressFlag [lindex $args [expr $index + 1]]
    } else  {
        set SuppressFlag 0
    } 
    
    lappend PduConfigList -SuppressFlag
    lappend PduConfigList $SuppressFlag     

    #Parse QRV parameter    
    set index [lsearch $args -qrv] 
    if {$index != -1} {
        set QRV [lindex $args [expr $index + 1]]
    } else  {
        set QRV 0
    } 
    
    lappend PduConfigList -QRV
    lappend PduConfigList $QRV     

    #Parse QQIC parameter    
    set index [lsearch $args -qqic] 
    if {$index != -1} {
        set QQIC [lindex $args [expr $index + 1]]
    } else  {
        set QQIC 0
    } 
    
    lappend PduConfigList -QQIC
    lappend PduConfigList $QQIC     

    #Parse SrcNum parameter    
    set index [lsearch $args -srcnum] 
    if {$index != -1} {
        set SourceNum [lindex $args [expr $index + 1]]
    } else  {
        set SourceNum 0
    } 
    
    lappend PduConfigList -SourceNum
    lappend PduConfigList $SourceNum     
    
    #Parse SrcIp parameter    
    set index [lsearch $args -srcip] 
    if {$index != -1} {
        set IpList [lindex $args [expr $index + 1]]
    } else  {
        set IpList ""
    }

    lappend PduConfigList -SrcIpList
    lappend PduConfigList $IpList     

    #Parse Reserved parameter    
    set index [lsearch $args -reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    } else  {
        set Reserved 0
    } 
    
    lappend PduConfigList -Reserved
    lappend PduConfigList $Reserved   

    #Parse GroupRecords parameter    
    set index [lsearch $args -grouprecords] 
    if {$index != -1} {
        set GroupRecords [lindex $args [expr $index + 1]]
    } else  {
        set GroupRecords ""
    } 
    
    lappend PduConfigList -GroupRecords
    lappend PduConfigList $GroupRecords   

    #Parse GroupRecordNum parameter    
    set index [lsearch $args -grouprecordnum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    } else  {
        set GroupNum 0
    } 
    
    lappend PduConfigList -GroupNum
    lappend PduConfigList $GroupNum   

    #Parse GroupType parameter    
    set index [lsearch $args -grouptype] 
    if {$index != -1} {
        set RecordType [lindex $args [expr $index + 1]]
    } else  {
        set RecordType ALLOW_NEW_SOURCES
    } 
    
    lappend PduConfigList -RecordType
    lappend PduConfigList $RecordType   

    #Parse GroupIP parameter    
    set index [lsearch $args -groupip] 
    if {$index != -1} {
        set MulticastAddr [lindex $args [expr $index + 1]]
    } else  {
        set MulticastAddr "FE1E::1"
    } 
    
    lappend PduConfigList -MulticastAddr
    lappend PduConfigList $MulticastAddr   

    lappend ::mainDefine::gPduConfigList "$PduConfigList"
       
    debugPut "exit the proc of PacketBuilder::CreateMLDPkt" 
    return  $::mainDefine::gSuccess
}

############################################################################
#APIName: AddMLDPacketIntoStream
#Description: Add MLD packet into stream
#Input: 
#              (1) args argument list
#              (2) hStream Stream handle，specify the stream
#Output: None
#Coded by: Penn.Chen
#############################################################################
::itcl::body Stream::AddMLDPacketIntoStream {args hStream pduName} { 
    
    #Parse ProtocolVer parameter    
    set index [lsearch $args -ProtocolVer] 
    if {$index != -1} {
        set ProtocolVer [lindex $args [expr $index + 1]]
    }

    #Parse Type parameter    
    set index [lsearch $args -Type] 
    if {$index != -1} {
        set Type [lindex $args [expr $index + 1]]
    } 
        
    #Parse GroupAddr parameter    
    set index [lsearch $args -GroupAddr] 
    if {$index != -1} {
        set GroupAddr [lindex $args [expr $index + 1]]
    }

    #Parse GroupCount parameter    
    set index [lsearch $args -GroupCount] 
    if {$index != -1} {
        set GroupCount [lindex $args [expr $index + 1]]
    }

    #Parse IncreaseStep parameter    
    set index [lsearch $args -IncreaseStep] 
    if {$index != -1} {
        set IncreaseStep [lindex $args [expr $index + 1]]
    }
    
    #Parse MaxReponseTime parameter    
    set index [lsearch $args -MaxReponseTime] 
    if {$index != -1} {
        set MaxReponseTime [lindex $args [expr $index + 1]]
    }    
     
    #Parse Checksum parameter    
    set index [lsearch $args -Checksum] 
    if {$index != -1} {
        set Checksum [lindex $args [expr $index + 1]]
    }

    #Parse SuppressFlag parameter    
    set index [lsearch $args -SuppressFlag] 
    if {$index != -1} {
        set SuppressFlag [lindex $args [expr $index + 1]]
    }   

    #Parse QRV parameter    
    set index [lsearch $args -QRV] 
    if {$index != -1} {
        set QRV [lindex $args [expr $index + 1]]
    }

    #Parse QQIC parameter    
    set index [lsearch $args -QQIC] 
    if {$index != -1} {
        set QQIC [lindex $args [expr $index + 1]]
    }
    
    #Parse SourceNum parameter    
    set index [lsearch $args -SourceNum] 
    if {$index != -1} {
        set SourceNum [lindex $args [expr $index + 1]]
    }    

    #Parse SrcIpList parameter    
    set index [lsearch $args -SrcIpList] 
    if {$index != -1} {
        set SrcIpList [lindex $args [expr $index + 1]]
    }    

    #Parse Reserved parameter    
    set index [lsearch $args -Reserved] 
    if {$index != -1} {
        set Reserved [lindex $args [expr $index + 1]]
    }   
    
    #Parse GroupRecords parameter    
    set index [lsearch $args -GroupRecords] 
    if {$index != -1} {
        set GroupRecords [lindex $args [expr $index + 1]]
    }   

    #Parse GroupNum parameter    
    set index [lsearch $args -GroupNum] 
    if {$index != -1} {
        set GroupNum [lindex $args [expr $index + 1]]
    }

    #Parse MulticastAddr parameter    
    set index [lsearch $args -MulticastAddr] 
    if {$index != -1} {
        set MulticastAddr [lindex $args [expr $index + 1]]
    }       
    
    set RecordType "ALLOW_NEW_SOURCES"
    #MLDv2 RecordType conversion
    switch $RecordType {
        ALLOW_NEW_SOURCES {
            set RcdType 5
        }
        BLOCK_OLD_SOURCES {
            set RcdType 6
        }
        CHANGE_TO_EXCLUDE_MODE {
            set RcdType 4
        }
        CHANGE_TO_INCLUDE_MODE {
            set RcdType 3
        }  
        MODE_IS_EXCLUDE {
            set RcdType 2
        }
        MODE_IS_INCLUDE {
            set RcdType 1
        }             
    }
    
   set Type [string tolower $Type] 

   set MldType "unknown"
   if {[string tolower $ProtocolVer] == "mldv1" } {
        if {$Type == "listenerdone" } {
             set MldType "mldv1listenerdone"
        } elseif {$Type == "listenerreport" } {
             set MldType "mldv1listenerreport"
        } elseif {$Type == "query" } {
             set MldType "mldv1query"
        }
    } elseif {[string tolower $ProtocolVer] == "mldv2" } {
       if {$Type == "listenerdone" } {
             set MldType "mldv2listenerdone"
        } elseif {$Type == "listenerreport" } {
             set MldType "mldv2listenerreport"
        } elseif {$Type == "query" } {
             set MldType "mldv2query"
        }
    } 

    #Create MLD packet object
    switch $MldType {
        mldv1listenerdone {
            set hMld [stc::create icmpv6:MLDv1 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hMld

            stc::config $hMld -type 132 -maxRespDelay $MaxReponseTime -mcastAddr $GroupAddr 
 
            if {$Checksum != "0" } {
                 stc::config $hMld -checksum $Checksum
            }
        }
        mldv1listenerreport {
            set hMld [stc::create icmpv6:MLDv1 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hMld

            stc::config $hMld -type 131 -maxRespDelay $MaxReponseTime -mcastAddr $GroupAddr 
             if {$Checksum != "0" } {
                 stc::config $hMld -checksum $Checksum
            }
        }
        mldv1query {
            set hMld [stc::create icmpv6:MLDv1 -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hMld

            stc::config $hMld -type 130 -maxRespDelay $MaxReponseTime -mcastAddr $GroupAddr 
             if {$Checksum != "0" } {
                 stc::config $hMld -checksum $Checksum
            }
        }
        mldv2listenerreport {
            set hMld [stc::create icmpv6:MLDv2Report -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hMld

            stc::config $hMld \
                -type 143 \
                -reserved2 $Reserved  -numGrpRecords $GroupNum

            set hgrpRecords [stc::create grpRecords -under $hMld]
            foreach grpRecord $GroupRecords {
                set itemLength [llength $grpRecord]
                set multicastAddr [lindex $grpRecord 0]
                set recordType [lindex $grpRecord 1]
                set ipv6Addr [lindex $grpRecord 2]

                set hGrpRecord [stc::create MLDv2GroupRecord -under $hgrpRecords]
                stc::config $hGrpRecord \
                    -mcastAddr $multicastAddr \
                    -recordType $recordType  -numSource 1
                #Configure Addr List
                set hAddrList [stc::create addrList -under $hGrpRecord]
                set hIpv6Addr [stc::create ipv6Addr -under $hAddrList]
                stc::config $hIpv6Addr -value $ipv6Addr
            }  
            if {$Checksum != "0" } {
                 stc::config $hMld -checksum $Checksum
            }
        }
        mldv2query {
            set hMld [stc::create icmpv6:MLDv2Query -under $hStream]
            #Store the packet header
            lappend m_PduNameList $pduName
            set m_PduHandleList($pduName) $hMld

            stc::config $hMld \
                -type 130 \
                -groupAddress $GroupAddr \
                -sFlag $SuppressFlag \
                -qrv $QRV \
                -qqic $QQIC \
                -numSource $SourceNum 
            set hAddrList [stc::create addrList -under $hMld]
            foreach SrcIp $SrcIpList {
                set hIpv6Addr [stc::create ipv6Addr -under $hAddrList]
                stc::config $hIpv6Addr -value $SrcIp
            }
            if {$Checksum != "0" } {
                 stc::config $hMld -checksum $Checksum
            }
        }
        default {
            error "The specified Type of CreateMLDPkt is invalid"
        }
    }   

    if {$GroupCount != "1" } {
        set mld1 [stc::get $hMld -Name]
        set MldStep [Num2Ipv6 $IncreaseStep ]

        if {[string tolower $ProtocolVer] == "mldv1" } {
             stc::create "RangeModifier" \
                  -under $hStream -EnableStream $m_EnableStream \
                  -ModifierMode "INCR" \
                  -Mask "::FFFF:FFFF"  \
                  -StepValue $MldStep \
                  -RecycleCount $GroupCount \
                  -RepeatCount "0" \
                  -Data $GroupAddr \
                  -Offset "0" \
                  -OffsetReference "$mld1.mcastAddr" \
                  -Active "TRUE" \
                  -Name "MLD Modifier"
        } elseif {$MldType == "mldv2query" } {
                 stc::create "RangeModifier" \
                  -under $hStream -EnableStream $m_EnableStream \
                  -ModifierMode "INCR" \
                  -Mask "::FFFF:FFFF"  \
                  -StepValue $MldStep \
                  -RecycleCount $GroupCount \
                  -RepeatCount "0" \
                  -Data $GroupAddr \
                  -Offset "0" \
                  -OffsetReference "$mld1.groupAddress" \
                  -Active "TRUE" \
                  -Name "MLD Modifier"
        }
     } 
}  
