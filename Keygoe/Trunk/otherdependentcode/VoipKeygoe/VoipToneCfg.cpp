#include "stdafx.h"
#include "DJAcsDataDef.h"
#include "VoipToneCfg.h"
#include "VoipDeviceRes.h"
#include "VoipLog.h"
#include "VoipEvent.h"

extern  char cfg_IniName[MAX_FILE_NAME_LEN];


static HANDLE g_hMutex_Tone = CreateMutex(NULL, FALSE, "Mutex_Tone");  
	//WaitForSingleObject(g_hMutex_Tone, INFINITE);   
	//ReleaseMutex(g_hMutex_Tone);  

int	g_Tone_Count;
TYPE_ANALOG_TONE_PARAM MapTable_Tone[16];
int g_Freq_Count;
TYPE_ANALOG_FREQ_PARAM MapTable_Freq[16];
ToneTimes  ToneTimesState[TRUNK_NUM_MAX];

/*************************************************************************************
return 
	0:	OK.
	-1:	Fail, m_u8CalledTableCount Invalid
	-2: Fail, m_u8CalledLen Invalid
	-3: Fail, m_u8CalledTimeOut Invalid
	-4: Fail, m_u8AreaCodeLen Invalid
	-5: Fail, m_CalledTable[x].m_u8NumLen Invalid
*************************************************************************************/
long	ReadToneCfg ()
{
	int			iTmp = 0;
	int			iFregCount = 0; 
	int			iToneCount = 0;
	char		TmpChar = '\0';
	char		TmpKey[50] = {0};

	// ------------------------ [Freq Count] ------------------------
	iFregCount = GetPrivateProfileInt ( "ConfigInfo", "FreqCount", 0, cfg_IniName);
	if ( (iFregCount < 1 || iFregCount > 16) )
		return -1;
	g_Freq_Count = (DJ_U16)iFregCount;

	for (int i = 0; i < iFregCount; i++)
	{
		MapTable_Freq[i].m_index = i;

		sprintf(TmpKey,"%d", i);
		// ------------------------ [Freq] ------------------------
		iTmp = GetPrivateProfileInt ( "Freq", TmpKey, 0, cfg_IniName);
		if ( (iTmp < 300) || (iTmp > 3400) )
			return -2;							// m_u16Freq0 Invalid, should be 300-3400 Hz
		MapTable_Freq[i].m_Freq = (DJ_U16)iTmp;
	}
	
	iToneCount = GetPrivateProfileInt( "ConfigInfo", "ToneCount", 0, cfg_IniName);
	if ( (iToneCount < 1 || iToneCount > 16) )
		return -3;
	g_Tone_Count = iToneCount;
	for (int j = 0; j < iToneCount; j++)
	{
		memset(TmpKey, 0, sizeof(TmpKey));
		TmpChar = 'G' + j;
		AddLog("ReadToneCfg %d", 1);
		memset(TmpKey, TmpChar, sizeof(TmpChar));
		AddLog(TmpKey, 1);
		// ------------------------ [Tone] -------------- ----------
		iTmp = GetPrivateProfileInt ( TmpKey, "Id", 0, cfg_IniName);
		if ( (iTmp < 48) || (iTmp > 63) )
			return -4;							
		MapTable_Tone[j].m_id = (DJ_U16) iTmp;
		
		iTmp = GetPrivateProfileInt ( TmpKey, "FreqIndexMask", 0, cfg_IniName);
		if ( (iTmp < 0) || (iTmp > 0xFFFF) )
			return -5;						
		MapTable_Tone[j].m_FreqIndexMask = (DJ_U16) iTmp;

		iTmp = GetPrivateProfileInt ( TmpKey, "EnvelopeMode", 0, cfg_IniName);
		if ( (iTmp < 0) || (iTmp > 2) )
			return -9;						
		MapTable_Tone[j].m_EnvelopeMode = (DJ_U16) iTmp;

		iTmp = GetPrivateProfileInt ( TmpKey, "On_Time", 0, cfg_IniName);
		if ( (iTmp < 100) || (iTmp > 5000) )
			return -6;						
		MapTable_Tone[j].m_On_Time = (DJ_U16) iTmp;

		//一次包络
		if (MapTable_Tone[j].m_EnvelopeMode == 1)
		{
			iTmp = GetPrivateProfileInt ( TmpKey, "Off_Time", 0, cfg_IniName);
			if ( (iTmp < 0) || (iTmp > 5000) )
				return -7;						
			MapTable_Tone[j].m_Off_Time = (DJ_U16) iTmp;
		}
		//二次包络
		if (MapTable_Tone[j].m_EnvelopeMode == 2)
		{
			
			iTmp = GetPrivateProfileInt ( TmpKey, "On_Time_Two", 0, cfg_IniName);
			if ( (iTmp < 100) || (iTmp > 5000) )
				return -6;						
			MapTable_Tone[j].m_On_Time_Two = (DJ_U16) iTmp;
			
			iTmp = GetPrivateProfileInt ( TmpKey, "Off_Time_Two", 0, cfg_IniName);
			if ( (iTmp < 0) || (iTmp > 5000) )
				return -7;						
			MapTable_Tone[j].m_Off_Time_Two = (DJ_U16) iTmp;		
			
		}

		iTmp = GetPrivateProfileInt ( TmpKey, "TimeDeviation", 10, cfg_IniName);
		if ( (iTmp < 0) || (iTmp > 50) )
			return -8;						
		MapTable_Tone[j].m_TimeDeviation = (DJ_U16) iTmp;
	}

	return 0;// OK
}

int InitToneTimes()
{
	for (int i = 0; i < TRUNK_NUM_MAX; i++)
	{
		ResetToneTimes(i);
	}
	return 1;
}

int ResetToneTimes(const int iTrunk)
{
	if (iTrunk >= TRUNK_NUM_MAX)
	{
		return -1;
	}
	WaitForSingleObject(g_hMutex_Tone, INFINITE);   

	ToneTimesState[iTrunk].iTimeOut = 0;
	ToneTimesState[iTrunk].iG = 0;
	ToneTimesState[iTrunk].iH = 0;
	ToneTimesState[iTrunk].iI = 0;
	ToneTimesState[iTrunk].iJ = 0;
	ToneTimesState[iTrunk].iK = 0;
	ToneTimesState[iTrunk].iL = 0;
	ToneTimesState[iTrunk].iM = 0;
	ToneTimesState[iTrunk].iN = 0;
	
	ToneTimesState[iTrunk].iOther = 0;
	
	ReleaseMutex(g_hMutex_Tone);  
	return 1;
}

int GetToneTimes(const int iTrunk, const char TmpGtd)
{
	int iRCount = 0;
	if (iTrunk >= TRUNK_NUM_MAX)
	{
		return -1;
	}	
	WaitForSingleObject(g_hMutex_Tone, INFINITE);   

	switch(TmpGtd) 
	{
	case 'G':
		iRCount = ToneTimesState[iTrunk].iG;
		break;
	case 'H':
		iRCount = ToneTimesState[iTrunk].iH;
		break;				
	case 'I':
		iRCount = ToneTimesState[iTrunk].iI;
		break;				
	case 'J':
		iRCount = ToneTimesState[iTrunk].iJ;
		break;				
	case 'K':
		iRCount = ToneTimesState[iTrunk].iK;
		break;				
	case 'L':
		iRCount = ToneTimesState[iTrunk].iL;
		break;				
	case 'M':
		iRCount = ToneTimesState[iTrunk].iM;
		break;				
	case 'N':
		iRCount = ToneTimesState[iTrunk].iN;
		break;
	default:
		iRCount = ToneTimesState[iTrunk].iOther;
		break;
	}
	
	ReleaseMutex(g_hMutex_Tone);  
	return iRCount;
}

int GetToneTimesTimeOut(const int iTrunk)
{
	int iRCount = 0;
	if (iTrunk >= TRUNK_NUM_MAX)
	{
		return -1;
	}	
	WaitForSingleObject(g_hMutex_Tone, INFINITE);   

	iRCount = ToneTimesState[iTrunk].iTimeOut;
	
	ReleaseMutex(g_hMutex_Tone);  
	return iRCount;
}

int UpdateToneTimes(const int iTrunk, const char TmpGtd)
{
	if (iTrunk >= TRUNK_NUM_MAX)
	{
		return -1;
	}
	WaitForSingleObject(g_hMutex_Tone, INFINITE);   
	
	switch(TmpGtd) 
	{
	case 'G':
		ToneTimesState[iTrunk].iG += 1;
		break;
	case 'H':
		ToneTimesState[iTrunk].iH += 1;
		break;				
	case 'I':
		ToneTimesState[iTrunk].iI += 1;
		break;				
	case 'J':
		ToneTimesState[iTrunk].iJ += 1;
		break;				
	case 'K':
		ToneTimesState[iTrunk].iK += 1;
		break;				
	case 'L':
		ToneTimesState[iTrunk].iL += 1;
		break;			
	case 'M':
		ToneTimesState[iTrunk].iM += 1;
		break;				
	case 'N':
		ToneTimesState[iTrunk].iN += 1;
		break;
	default:
		ToneTimesState[iTrunk].iOther += 1;
		break;
	}
	ReleaseMutex(g_hMutex_Tone);  
	return 1;
		
}

int UpdateToneTimesTimeOut(const int iTrunk)
{
	if (iTrunk >= TRUNK_NUM_MAX)
	{
		return -1;
	}
	WaitForSingleObject(g_hMutex_Tone, INFINITE);   
	
	ToneTimesState[iTrunk].iTimeOut += 1;
	
	ReleaseMutex(g_hMutex_Tone);  
	return 1;
		
}
