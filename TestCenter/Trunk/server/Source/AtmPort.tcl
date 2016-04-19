###########################################################################
#                                                                        
#  File Name£ºAtmPort.tcl                                                                                              
# 
#  Description£ºDefinition of ATM port class                                             
# 
#  Author£º David.Wu
#
#  Create time:  2007.5.10
#
#  version£º1.0 
# 
#  History£º 
# 
##########################################################################

##########################################
#Definition of Atm port class
##########################################  
::itcl::class ATMPort {

   inherit TestPort
    
    constructor {portName chassisName portLocation hProject chassisIp } { TestPort::constructor $portName $chassisName $portLocation $hProject $chassisIp } { 

    }

    destructor {}
}    
