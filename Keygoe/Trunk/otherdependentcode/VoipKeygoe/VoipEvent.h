#ifndef _VOIP_EVENT_H_
#define _VOIP_EVENT_H_
#include "VoipDeviceRes.h"

#define TRUNK_NUM_MAX 16
typedef struct _AfterOffHook
{
	_AfterOffHook():TimeOut(0),
		DialTone(0),
		BusyTone(0),
		BusyToneEnd(0)
	{
		memset(RecvBuf, 0, sizeof(RecvBuf));
	}
	int TimeOut;
	int DialTone;
	int BusyTone;
	int BusyToneEnd;
	char RecvBuf[512];
}AfterOffHook;

typedef struct _AfterDial
{
	_AfterDial():TimeOut(0),
		AnswerTone(0),
		BusyTone(0),
		BusyToneEnd(0),
		RingTone(0),
		RingToneEnd(0)
	{
		memset(RecvBuf, 0, sizeof(RecvBuf));
	}
	int TimeOut;
	int AnswerTone;
	int BusyTone;
	int BusyToneEnd;
	int RingTone;
	int RingToneEnd;
	char RecvBuf[512];
}AfterDial;

typedef struct _StartCallIn
{
	_StartCallIn():RingTimes(0)
	{}
	int RingTimes;
}StartCallIn;


//
DJ_Void EvtHandler(DJ_U32 esrParam);
void PrintEventInfo ( Acs_Evt_t *pAcsEvt );

void TrunkWork ( TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt );
void FaxWork ( TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt );
int TrunkCallIn(TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt );

void CheckTone (TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt );


DJ_S32	 PlayFile ( DeviceID_t	*pVocDevID, DJ_S8 *s8FileName, DJ_U8 u8PlayTag, bool bIsQueue );

void SetGtd_AnalogTrunk(DeviceID_t* pDevId);
void SetGTD_ToneParam ( DeviceID_t *pDevice );
char My_GetGtdOrPVDCode ( TRUNK_STRUCT* pOneTrunk,  Acs_Evt_t *pAcsEvt );
int My_RecvDTMFData (TRUNK_STRUCT* pOneTrunk,  Acs_Evt_t *pAcsEvt );

DJ_S32	PlayDTMF ( DeviceID_t	*pVocDevID, const char *DtmfStr );
DJ_S32	StopPlayDTMF ( DeviceID_t	*pVocDevID );

int ResetStartCallIn();

#endif //_VOIP_EVENT_H_ end