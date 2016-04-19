###########################################################################
#                                                                        
#  File Name£ºLowRatePort.tcl                                                                                              
# 
#  Description£ºDefinition of STC LowRate port class                                             
# 
#  Auther£º David.Wu
#
#  Create time:  2007.5.10
#
#  version£º1.0 
# 
#  History£º 
# 
##########################################################################

##########################################
#Definition of Low Rate port class
##########################################  
::itcl::class LowRatePort {
 
    inherit TestPort
    
    constructor { portName chassisName portLocation hProject chassisIp } { TestPort::constructor $portName $chassisName $portLocation $hProject $chassisIp } { 
        lappend ::mainDefine::gObjectNameList $this
    }

    destructor {
    set index [lsearch $::mainDefine::gObjectNameList $this]
    set ::mainDefine::gObjectNameList [lreplace $::mainDefine::gObjectNameList $index $index ]
    }

}    


