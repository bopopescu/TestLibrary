#ifndef _VOIP_TONE_CFG_H_
#define _VOIP_TONE_CFG_H_

typedef struct 
{
	DJ_U16		m_index;
	DJ_U16		m_Freq;
} TYPE_ANALOG_FREQ_PARAM;
/*
[G]
Id=48
Freq=450
ToneType=DialTone
FreqIndexMask=1
EnvelopeMode = 1
On_Time=1000
Off_Time=0
TimeDeviation=10
*/
typedef struct _TYPE_ANALOG_TONE_PARAM
{
	_TYPE_ANALOG_TONE_PARAM():m_Off_Time(0),m_On_Time_Two(0),m_Off_Time_Two(0){}
	DJ_U16		m_id;
	DJ_U16		m_FreqIndexMask;
	DJ_U16		m_EnvelopeMode;
	DJ_U16		m_On_Time;
	DJ_U16		m_Off_Time;
	DJ_U16		m_On_Time_Two;
	DJ_U16		m_Off_Time_Two;
	DJ_U16		m_TimeDeviation;		// in percentage
} TYPE_ANALOG_TONE_PARAM;

typedef struct _ToneTimes
{
	//GHIJKLMNOPQRSTUV
	int iTimeOut;
	int iG;
	int iH;
	int iI;
	int iJ;
	int iK;
	int iL;
	int iM;
	int iN;

	int iOther;	
}ToneTimes;

long	ReadToneCfg ();
int		InitToneTimes();
int		ResetToneTimes(const int iTrunk);

int		UpdateToneTimes(const int iTrunk, const char TmpGtd);
int		UpdateToneTimesTimeOut(const int iTrunk);
int		GetToneTimes(const int iTrunk, const char TmpGtd);
int		GetToneTimesTimeOut(const int iTrunk);
#endif