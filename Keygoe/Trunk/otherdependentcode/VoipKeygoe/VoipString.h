#ifndef _VOIP_STRING_H_
#define _VOIP_STRING_H_

#include "VoipDeviceRes.h"

char *GetString_EventType ( EventType_t EvtType );
char *GetString_DeviceMain ( DJ_S32	s32DeviceMain );
char *GetString_DeviceSub ( DJ_S32	s32DeviceSub );
char *GetString_ErrorCode ( DJ_S32	s32ErrorCode );
void GetString_LineState ( char *StateStr, int iLineState );
void	GetString_State (  char *StateStr, int State );
#endif //_VOIP_STRING_H_ end