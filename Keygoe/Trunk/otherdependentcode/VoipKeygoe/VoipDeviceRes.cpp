#include "StdAfx.h"
#include "VoipDeviceRes.h"
#include "VoipLog.h"
#include "VoipEvent.h"
#include "VoipCall.h"
#include "VoipString.h"
#include "VoipToneCfg.h"

#include <stdio.h>

//全局数据;
ACSHandle_t		g_acsHandle = -1;	//引用程序与keygoe子系统的连接句柄
int				cfg_s32DebugOn;
int             cfg_s32LogOn;
ServerID_t		cfg_ServerID;		//流程模块的配置IP、PORT
DJ_U8			g_u8UnitID = 1;     //

//CCriticalSection global_CriticalSection;
static HANDLE g_hMutex = CreateMutex(NULL, FALSE, "Mutex");   

// var about XMS_Dial.INI
char					cfg_IniName[MAX_FILE_NAME_LEN] = "";
char					cfg_LogDir[MAX_FILE_NAME_LEN] = "";

//TYPE_XMS_DSP_DEVICE_RES_DEMO	AllDeviceRes[MAX_DSP_MODULE_NUMBER_OF_XMS];
TYPE_XMS_DSP_DEVICE_RES_DEMO	AllDevice;
int						g_TrunkFlg = 0;

int						g_iTotalModule = 0;
//DJ_S8					MapTable_Module[MAX_DSP_MODULE_NUMBER_OF_XMS];

int						g_iTotalTrunk = 0;
int						g_iTotalTrunkOpened = 0;
TYPE_CHANNEL_MAP_TABLE	MapTable_Trunk[MAX_TRUNK_NUM_IN_THIS_DEMO];

int						g_iTotalVoice = 0;
int						g_iTotalVoiceOpened = 0;
int						g_iTotalVoiceFree = 0;
TYPE_CHANNEL_MAP_TABLE	MapTable_Voice[MAX_TRUNK_NUM_IN_THIS_DEMO];

int						g_iTotalFax = 0;
int						g_iTotalFaxOpened = 0;
int						g_iTotalFaxFree = 0;
TYPE_CHANNEL_MAP_TABLE	MapTable_Fax[MAX_TRUNK_NUM_IN_THIS_DEMO];
//检测音	

extern int	g_Tone_Count;
extern TYPE_ANALOG_TONE_PARAM MapTable_Tone[16];
extern int g_Freq_Count;
extern TYPE_ANALOG_FREQ_PARAM MapTable_Freq[16];

int InitSystem(const char* configFile)
{
	RetCode_t	r;
	int         iRetCode;
	char		MsgStr[160] = {0};

	if (configFile == NULL)
	{
		return -1;
	}
	sprintf(cfg_IniName, "%s\\%s", configFile, "XMS_KEYGOE.INI");
	ReadFromConfig();

	iRetCode =  ReadToneCfg ();
	if (iRetCode != 0 )
	{
		AddLog("ReadToneCfg fial %d", iRetCode);
		return -2;
	}

	ResInitDSPDEVICE();
	
	// now open ACS Server
	/* Call acsOpenStream() to connect with ACS Server */
	r = XMS_acsOpenStream ( &g_acsHandle, 
							&cfg_ServerID,
							g_u8UnitID,		// App Unit ID 
							32,				// sendQSize, in K Bytes
							32,				// recvQSize, in K Bytes
							cfg_s32DebugOn,	// Debug On/Off
							NULL);
	if ( r < 0 )
	{
		sprintf ( MsgStr, "XMS_acsOpenStream(IP Addr : %s, port : %d) FAIL. ret = %d", 
			cfg_ServerID.m_s8ServerIp, cfg_ServerID.m_u32ServerPort, r );
		AddMsg ( MsgStr );
		return -3;
	}
	else
	{
		sprintf ( MsgStr, "XMS_acsOpenStream(%s,%d) OK!", cfg_ServerID.m_s8ServerIp, cfg_ServerID.m_u32ServerPort );
		AddMsg ( MsgStr );
	}

	r = XMS_acsSetESR ( g_acsHandle, (EsrFunc)EvtHandler, 0, 1 );
	if ( r < 0 )
	{
		sprintf ( MsgStr, "XMS_acsSetESR() FAIL! ret = %d", r );
		AddMsg ( MsgStr );
		return -4;
	}
	else
	{
		sprintf ( MsgStr, "XMS_acsSetESR() OK!" );
		AddMsg ( MsgStr );
	}
	
	//清空容器
	InitAllDeviceRes ();
	
	r = XMS_acsGetDeviceList ( g_acsHandle, NULL ); 

	if ( r != ACSPOSITIVE_ACK )
	{
		sprintf ( MsgStr, "XMS_acsGetDeviceList() FAIL! ret = %d", r );
		AddMsg ( MsgStr );
		return -5;
	}
	else
	{
		sprintf ( MsgStr, "XMS_acsGetDeviceList() OK!" );
		AddMsg ( MsgStr );
	}
	
	return 1;
}


bool    ResInitDSPDEVICE()
{
	WaitForSingleObject(g_hMutex, INFINITE);
	g_TrunkFlg = 0;
	
	AllDevice.lVocNum = 0;
	AllDevice.lVocOpened = 0;
	AllDevice.lVocFreeNum = 0;
	AllDevice.lTrunkNum = 0;
	AllDevice.lTrunkOpened = 0;
	AllDevice.lFaxNum = 0;
	AllDevice.lFaxOpened = 0;
	AllDevice.lFaxFreeNum = 0;
	if (AllDevice.pVoice != NULL)
	{
		delete[] AllDevice.pVoice;
		AllDevice.pVoice = NULL;
	}
	if ( AllDevice.pTrunk != NULL)
	{
		delete[] AllDevice.pTrunk;
		AllDevice.pTrunk = NULL;
	}
	if (AllDevice.pFax != NULL)
	{
		delete[] AllDevice.pFax;
		AllDevice.pFax = NULL;
	}
	ReleaseMutex(g_hMutex);
	return true;
}

void ExitSystem() 
{
	RetCode_t	r;
	char		MsgStr[255] = {0};
	
	// close all device	
	//for (int i = 0; i < g_iTotalModule; i ++ )
	//{
	AddLog("ExitSystem:g_u8UnitID %d", g_u8UnitID);
	CloseAllDevice_Dsp ( g_u8UnitID );
	//}
	//
	if (g_acsHandle == NULL)
	{
		return;
	}

	int t = 0;
	while (t++ < 10)
	{
		if (g_iTotalTrunkOpened <= 0 && g_iTotalVoiceOpened <= 0 && g_iTotalFaxOpened <= 0)
		{
			break;
		}
		Sleep(1000);
	}
	if (t >= 10)
	{		
		AddLog("ExitSystem:g_iTotalTrunkOpened is %d", g_iTotalTrunkOpened);
		AddLog("ExitSystem:g_iTotalVoice is %d", g_iTotalVoiceOpened);
		AddLog("ExitSystem:g_iTotalFax is %d", g_iTotalFaxOpened);
	}

	r = XMS_acsCloseStream ( g_acsHandle, NULL );

	if ( r < 0 )
	{
		sprintf ( MsgStr, "XMS_acsCloseStream() FAIL! ret = %d", r );
		AddMsg ( MsgStr );
	}
	else
	{
		sprintf ( MsgStr, "XMS_acsCloseStream() OK!" );
		AddMsg ( MsgStr );
	}
	FreeAllDeviceRes ();	

	AddLog("exit ok",1);
	return;
}


// -----------------------------------------------------------------------
// 读取系统配置信息
void ReadFromConfig(void)
{
	cfg_s32LogOn = GetPrivateProfileInt ( "ConfigInfo", "LogOn", 0, cfg_IniName);
	GetPrivateProfileString("ConfigInfo","LogDir","D:\\",cfg_LogDir ,sizeof(cfg_LogDir),cfg_IniName);

	GetPrivateProfileString ( "ConfigInfo", "IpAddr", "0.0.0.0", cfg_ServerID.m_s8ServerIp, sizeof(cfg_ServerID.m_s8ServerIp), cfg_IniName);
	cfg_ServerID.m_u32ServerPort = GetPrivateProfileInt ( "ConfigInfo", "Port", 0, cfg_IniName);
	GetPrivateProfileString("ConfigInfo","UserName","",cfg_ServerID.m_s8UserName,sizeof(cfg_ServerID.m_s8UserName),cfg_IniName);
	GetPrivateProfileString("ConfigInfo","PassWord","",cfg_ServerID.m_s8UserPwd,sizeof(cfg_ServerID.m_s8UserPwd),cfg_IniName);

	cfg_s32DebugOn = GetPrivateProfileInt ( "ConfigInfo", "DebugOn", 0, cfg_IniName);	
}

//
void	InitAllDeviceRes (void)
{
	WaitForSingleObject(g_hMutex, INFINITE);
	
	// clease the AllDeviceRes, include: lFlag, all the Total, the pointer clear to NULL
	memset ( &AllDevice, 0, sizeof(AllDevice) );

	g_iTotalModule = 0;

	g_iTotalTrunk = 0;
	g_iTotalTrunkOpened = 0;
	//AllDevice.lTrunkNum

	g_iTotalVoice = 0;
	g_iTotalVoiceOpened = 0;
	g_iTotalVoiceFree = 0;

	g_iTotalFax = 0;
	g_iTotalFaxOpened = 0;
	g_iTotalFaxFree = 0;

	ReleaseMutex(g_hMutex);  
}

void	FreeOneDeviceRes ( int ID )
{
	WaitForSingleObject(g_hMutex, INFINITE);
	if ( AllDevice.pVoice != NULL )
	{
		delete [] AllDevice.pVoice;
		AllDevice.pVoice = NULL;
		AllDevice.lVocNum = 0;
	}

	if ( AllDevice.pTrunk != NULL )
	{
		delete [] AllDevice.pTrunk;
		AllDevice.pTrunk = NULL;
		AllDevice.lTrunkNum = 0;
	}

	if ( AllDevice.pFax != NULL )
	{
		delete [] AllDevice.pFax;
		AllDevice.pFax = NULL;
		AllDevice.lFaxNum = 0;
	}

	memset ( &AllDevice, 0, sizeof (TYPE_XMS_DSP_DEVICE_RES_DEMO) );
	ReleaseMutex(g_hMutex);  
}

void	FreeAllDeviceRes (void)
{
	//int		i;

	//for ( i = 0; i < MAX_DSP_MODULE_NUMBER_OF_XMS; i ++ )
	//{
	FreeOneDeviceRes ( g_u8UnitID );
	//}

	InitAllDeviceRes ();
}

//查询设备后调用，初始化数据结构容器，以及初始状态
void	AddDeviceRes ( Acs_Dev_List_Head_t *pAcsDevList )
{
	DJ_S32	s32Type, s32Num;
	DJ_S8	s8DspModID;

	if (pAcsDevList == NULL)
	{
		return;
	}
	s32Type = pAcsDevList->m_s32DeviceMain;	//主类型
	s32Num = pAcsDevList->m_s32DeviceNum;	//设备个数

	s8DspModID = (DJ_S8) pAcsDevList->m_s32ModuleID; // DSP 模块的单元ID
	if ( (s8DspModID < 0) || (s8DspModID != g_u8UnitID) )
	{
		AddMsg("AddDeviceRes fail ! invalid ModuleID");
		return;				// invalid ModuleID
	}

	WaitForSingleObject(g_hMutex, INFINITE);

	switch ( s32Type )
	{
	case XMS_DEVMAIN_VOICE:	//1
		AddDeviceRes_Voice ( s8DspModID, pAcsDevList );
		break;

	case XMS_DEVMAIN_FAX: //1
		AddDeviceRes_Fax ( s8DspModID, pAcsDevList );
		break;

	case XMS_DEVMAIN_DIGITAL_PORT:
		//AddDeviceRes_Pcm ( s8DspModID, pAcsDevList );
		break;
	
	case XMS_DEVMAIN_INTERFACE_CH://1
		AddDeviceRes_Trunk ( s8DspModID, pAcsDevList );
		break;

	case XMS_DEVMAIN_DSS1_LINK:			break;
	case XMS_DEVMAIN_SS7_LINK:			break;

	case XMS_DEVMAIN_BOARD://1
		AddDeviceRes_Board ( s8DspModID, pAcsDevList );
		break;

	case XMS_DEVMAIN_CTBUS_TS:			break;
	case XMS_DEVMAIN_VOIP:				break;
	case XMS_DEVMAIN_CONFERENCE:		break;

	case XMS_DEVMAIN_VIDEO:				break;
		break;
	}

	ReleaseMutex(g_hMutex);  
}


void	AddDeviceRes_Trunk ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList )
{
	DJ_S32	s32Num;
	int		i;
	char	TmpStr[256];

	if (pAcsDevList == NULL)
	{
		return;
	}
	s32Num = pAcsDevList->m_s32DeviceNum;

	if ( (AllDevice.lTrunkNum == 0) && (s32Num > 0) )		// the resources new added
	{
		// 
		AllDevice.pTrunk = new TRUNK_STRUCT[s32Num];
		if( !AllDevice.pTrunk )
		{
			AllDevice.lTrunkNum = 0;
			AllDevice.lTrunkOpened = 0;

			// alloc fail, maybe disp this error in your log
			sprintf ( TmpStr, "new TRUNK_STRUCT[%d] fail in AddDeviceRes_Trunk()" );
			AddMsg ( TmpStr );
		}
		else
		{
			memset ( AllDevice.pTrunk, 0, sizeof(TRUNK_STRUCT)*s32Num );
			AllDevice.lTrunkNum = s32Num;
			AllDevice.lTrunkOpened = 0;
			
			DeviceID_t	 *pDev;

			pDev = (DeviceID_t *)((BYTE *)pAcsDevList + sizeof(Acs_Dev_List_Head_t));

			for ( i = 0; i < s32Num; i ++ )
			{
				AllDevice.pTrunk[i].deviceID = pDev[i];
				AllDevice.pTrunk[i].State = TRK_WAITOPEN;
				
				//AddLog("init TRK_WAITOPEN  s8DspModID is  %d", s8DspModID);
			}
		}
	}
	else if ( (AllDevice.lTrunkNum > 0) && (s32Num == 0) )		// delete this resource
	{
		// if some devices did not close, close them
		for ( i = 0; i < AllDevice.lTrunkNum; i ++ )
		{
			if ( AllDevice.pTrunk[i].State != TRK_WAITOPEN )
			{
				CloseDeviceOK ( &AllDevice.pTrunk[i].deviceID );
			}
		}

		AllDevice.lTrunkNum = 0;
		AllDevice.lTrunkOpened = 0;

		delete [] AllDevice.pTrunk;
		AllDevice.pTrunk = NULL;
	}
	else
	{
		AddLog("AddDeviceRes_Trunk err",1);
	}
}

void	AddDeviceRes_Voice ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList )
{
	DJ_S32	s32Num;
	int		i;
	char	TmpStr[256];

	if (pAcsDevList == NULL)
	{
		return;
	}

	s32Num = pAcsDevList->m_s32DeviceNum;

	if ( (AllDevice.lVocNum == 0) && (s32Num > 0) )		// 新增加的资源
	{
		AllDevice.pVoice = new VOICE_STRUCT[s32Num];
		if( !AllDevice.pVoice )
		{
			AllDevice.lVocNum = 0;
			AllDevice.lVocOpened = 0;
			AllDevice.lVocFreeNum = 0;

			// alloc fail, maybe disp this error in your log
			sprintf ( TmpStr, "new VOICE_STRUCT[%d] fail in AddDeviceRes_Voice()" );
			AddMsg ( TmpStr );
		}
		else
		{
			AllDevice.lVocNum = s32Num;
			AllDevice.lVocOpened = 0;
			AllDevice.lVocFreeNum = 0;
			memset ( AllDevice.pVoice, 0, sizeof(VOICE_STRUCT)*s32Num );
			
			DeviceID_t	 *pDev;
			pDev = (DeviceID_t *)((BYTE *)pAcsDevList + sizeof(Acs_Dev_List_Head_t));

			for ( i = 0; i < s32Num; i ++ )
			{
				AllDevice.pVoice[i].deviceID = pDev[i];
				AllDevice.pVoice[i].State = VOC_WAITOPEN;
			}
		}
	}
	else if ( (AllDevice.lVocNum > 0) && (s32Num == 0) )		// delete this resource
	{
		// if some devices did not close, close them
		for ( i = 0; i < AllDevice.lVocNum; i ++ )
		{
			if ( AllDevice.pVoice[i].State != VOC_WAITOPEN )
				CloseDeviceOK ( &AllDevice.pVoice[i].deviceID );
		}

		AllDevice.lVocNum = 0;
		AllDevice.lVocOpened = 0;
		AllDevice.lVocFreeNum = 0;

		delete [] AllDevice.pVoice;
		AllDevice.pVoice = NULL;
	}
	else
	{
		AddLog("AddDeviceRes_Voice err",1);
	}

}

void	AddDeviceRes_Fax ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList )
{
	DJ_S32	s32Num;
	int		i;
	char	TmpStr[256];

	if (pAcsDevList == NULL)
	{
		return;
	}
	s32Num = pAcsDevList->m_s32DeviceNum;

	if ( (AllDevice.lFaxNum == 0) && (s32Num > 0) )		// the resources new added
	{
		AllDevice.pFax = new FAX_STRUCT[s32Num];
		if( !AllDevice.pFax )
		{
			AllDevice.lFaxNum = 0;
			AllDevice.lFaxOpened = 0;
			AllDevice.lFaxFreeNum = 0;

			// alloc fail, maybe disp this error in your log
			sprintf ( TmpStr, "new FAX_STRUCT[%d] fail in AddDeviceRes_Fax()" );
			AddMsg ( TmpStr );
		}
		else
		{
			AllDevice.lFaxNum = s32Num;
			AllDevice.lFaxOpened = 0;
			AllDevice.lFaxFreeNum = 0;
			memset ( AllDevice.pFax, 0, sizeof(FAX_STRUCT)*s32Num );
			
			DeviceID_t	 *pDev;
			pDev = (DeviceID_t *)((BYTE *)pAcsDevList + sizeof(Acs_Dev_List_Head_t));

			for ( i = 0; i < s32Num; i ++ )
			{
				AllDevice.pFax[i].deviceID = pDev[i];
				AllDevice.pFax[i].State = FAX_WAITOPEN;
			}
		}
	}
	else if ( (AllDevice.lFaxNum > 0) && (s32Num == 0) )		// delete this resource
	{
		// if some devices did not close, close them
		for ( i = 0; i < AllDevice.lFaxNum; i ++ )
		{
			if ( AllDevice.pFax[i].State != FAX_WAITOPEN )
				CloseDeviceOK ( &AllDevice.pFax[i].deviceID );
		}

		AllDevice.lFaxNum = 0;
		AllDevice.lFaxOpened = 0;
		AllDevice.lFaxFreeNum = 0;

		delete [] AllDevice.pFax;
		AllDevice.pFax = NULL;
	}
	else
	{
		AddLog("AddDeviceRes_Fax err",1);
	}
}


void	AddDeviceRes_Board ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList )
{
	DJ_S32	s32Num;
	if (pAcsDevList == NULL)
	{
		return;
	}

	s32Num = pAcsDevList->m_s32DeviceNum;

	if ( (AllDevice.lFlag == 0) && (s32Num > 0) )		// the resources new added
	{
		DeviceID_t	 *pDev;
		pDev = (DeviceID_t *)((BYTE *)pAcsDevList + sizeof(Acs_Dev_List_Head_t));

		AllDevice.deviceID = pDev[0];			
		AllDevice.bOpenFlag = false;
		AllDevice.bErrFlag = false;
		AllDevice.RemoveState = DSP_REMOVE_STATE_NONE;
	}
	else if ( (AllDevice.lFlag == 1) && (s32Num == 0) )	// delete this resource
	{
		// if some devices did not close, close them
		if ( AllDevice.bOpenFlag != false )
		{
			CloseDeviceOK ( &AllDevice.deviceID );
		}

		memset ( &AllDevice.deviceID, 0, sizeof(DeviceID_t) );
	}
	else
	{
		AddLog("AddDeviceRes_Board err",1);
	}

}

// --------------------------------------------------------------------------------
void	OpenTrunkDevice ( TRUNK_STRUCT *pOneTrunk, const int iNo )
{
	RetCode_t	r;

	if (pOneTrunk == NULL)
	{
		return;
	}
	
	if ( pOneTrunk->State == TRK_WAITOPEN )		// not Open yet
	{
		r = XMS_ctsOpenDevice ( g_acsHandle, &pOneTrunk->deviceID, NULL );
		if ( r < 0 )
		{
			AddLog ( "XMS_ctsOpenDevice Fail in OpenTrunkDevice()  %d", iNo );
		}	
	}
}

void	OpenVoiceDevice ( VOICE_STRUCT *pOneVoice, const int iNo )
{
	RetCode_t	r;
	if (pOneVoice == NULL)
	{
		return;
	}

	if ( pOneVoice->State == VOC_WAITOPEN )		// not Open yet
	{
		r = XMS_ctsOpenDevice ( g_acsHandle, &pOneVoice->deviceID, NULL );
		if ( r < 0 )
		{
			AddLog ( "XMS_ctsOpenDevice Fail in OpenVoiceDevice() %d", iNo );
		}
	}
}
void	OpenFaxDevice ( FAX_STRUCT *pOneFax, const int iNo )
{
	RetCode_t	r;
	if (pOneFax == NULL)
	{
		return;
	}
	if ( pOneFax->State == FAX_WAITOPEN )		// not Open yet
	{
		r = XMS_ctsOpenDevice ( g_acsHandle, &pOneFax->deviceID, NULL );
		if ( r < 0 )
		{
			AddLog ( "XMS_ctsOpenDevice Fail in OpenFaxDevice()! %d", iNo );
		}
	}
}
void	OpenBoardDevice (  DJ_S8 s8DspModID )
{
	RetCode_t	r;

	if ( AllDevice.bOpenFlag == false )	// not Open yet
	{
		r = XMS_ctsOpenDevice ( g_acsHandle, &AllDevice.deviceID, NULL );

		if ( r < 0 )
		{
			AddMsg ( "XMS_ctsOpenDevice Fail in OpenBoardDevice()!" );
		}
		else
		{
			AddLog("OpenBoardDevice ok", 1);
		}
	}
}

void	QueryAllDevice_Dsp ( DJ_S8 s8DspModID )
{
	WaitForSingleObject(g_hMutex, INFINITE);  
	AllDevice.lFlag = 0;		// Remove DSP Over 
	ReleaseMutex(g_hMutex);  
}

//call XMS_ctsOpenDevice 打开设备
void	OpenAllDevice_Dsp ( DJ_S8 s8DspModID )
{
	int	i;

	WaitForSingleObject(g_hMutex, INFINITE);
	AllDevice.lFlag = 1; 	// this DSP can use

	AllDevice.bErrFlag = false;
	AllDevice.RemoveState = DSP_REMOVE_STATE_NONE;

	// Open Board
	OpenBoardDevice ( s8DspModID );

	// pVoice
	for ( i = 0; i < AllDevice.lVocNum; i++ )
	{
		//#TODO 控制下打开的数量？？ 46
		OpenVoiceDevice ( &AllDevice.pVoice[i], i );
		//AddLog("OpenVoiceDevice %d", i);
	}

	// pTrunk
	for ( i = 0; i < AllDevice.lTrunkNum; i++ )
	{
		//#TODO 控制下打开的数量？？ 16
		OpenTrunkDevice ( &AllDevice.pTrunk[i], i);
		//AddLog("OpenTrunkDevice %d", i);
	}

	// pFax
	for ( i = 0; i < AllDevice.lFaxNum; i++ )
	{
		OpenFaxDevice ( &AllDevice.pFax[i], i );
		//AddLog("OpenFaxDevice %d", i);
	}
	ReleaseMutex(g_hMutex);  
}
//
//响应XMS_ctsOpenDevice 产生的消息，修改打开设备后的状态
void	OpenDeviceOK ( DeviceID_t *pDevice )
{
	TRUNK_STRUCT	*pOneTrunk;
	VOICE_STRUCT	*pOneVoice;
	int				iTrunkId;
	int				iTrunkBit;

	if (pDevice == NULL)
	{
		AddLog("OpenDeviceOK err", 1);
		return;
	}
	WaitForSingleObject(g_hMutex, INFINITE);

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_BOARD )
	{
		AllDevice.deviceID.m_CallID = pDevice->m_CallID;		// this line is very important, must before all operation
		AllDevice.bOpenFlag = true;

		SetGTD_ToneParam(pDevice); 
	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH )
	{
		if (AllDevice.pTrunk == NULL)
		{
			AddLog("OpenDeviceOK pTrunk err", 1);
		}
		pOneTrunk = &M_OneTrunk(*pDevice);
		pOneTrunk->deviceID.m_CallID = pDevice->m_CallID;		// this line is very important, must before all operation

		InitTrunkChannel ( pOneTrunk );
		//1007
		//XMS_ctsResetDevice ( g_acsHandle, pDevice, NULL );
		//XMS_ctsGetDevState ( g_acsHandle, pDevice, NULL );

		// modify the count
		g_iTotalTrunkOpened ++;
		AllDevice.lTrunkOpened ++;

		//add 20131023 表示哪些Trunk可用
		iTrunkId = pDevice->m_s16ChannelID;
		iTrunkBit = 1 << iTrunkId;
		g_TrunkFlg |= iTrunkBit;

		if ( pOneTrunk->deviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK ) //in use
		{
			// Set AnalogTrunk
			void* p = NULL;
			
			CmdParamData_AnalogTrunk_t cmdAnalogTrunk;
			DJ_U16 u16ParamType = ANALOGTRUNK_PARAM_UNIPARAM ;
			DJ_U16 u16ParamSize = sizeof(CmdParamData_AnalogTrunk_t);

			memset(&cmdAnalogTrunk,0,sizeof(cmdAnalogTrunk));

			cmdAnalogTrunk.m_u16CallInRingCount = 1;
			cmdAnalogTrunk.m_u16CallInRingTimeOut = 6000; //6 seconds

			p = (void*)&cmdAnalogTrunk;

			RetCode_t r;

			r = XMS_ctsSetParam( g_acsHandle, & pOneTrunk->deviceID, u16ParamType, u16ParamSize, (DJ_Void *)p );
			if (r < 0)
			{
				char szbuffer[1024];
				memset(szbuffer,0,sizeof(szbuffer));
				sprintf(szbuffer,"Set AnalogTrunk  ret = %d\n",r);
				AddMsg ( szbuffer );
			}
		}
	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_VOICE )
	{
		if (AllDevice.pVoice == NULL)
		{
			AddLog("OpenDeviceOK pVoice err", 1);
		}
		pOneVoice = &M_OneVoice(*pDevice);

		pOneVoice->deviceID.m_CallID = pDevice->m_CallID;		// this is very important
		Change_Voc_State ( pOneVoice, VOC_FREE);

		g_iTotalVoiceOpened ++;
		g_iTotalVoiceFree ++;
		AllDevice.lVocOpened ++;
		AllDevice.lVocFreeNum ++;
	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_FAX )
	{
		if (AllDevice.pFax == NULL)
		{
			AddLog("OpenDeviceOK pFax err", 1);
		}
		M_OneFax(*pDevice).deviceID.m_CallID = pDevice->m_CallID;		// this is very important

		// init the Device: Fax
		//1007
		//XMS_ctsResetDevice ( g_acsHandle, pDevice, NULL );
		//XMS_ctsGetDevState ( g_acsHandle, pDevice, NULL );
		
		Change_Fax_State ( &M_OneFax(*pDevice), FAX_FREE);

		// modify the Count

		g_iTotalFaxOpened ++;
		g_iTotalFaxFree ++;
		AllDevice.lFaxOpened ++;
		AllDevice.lFaxFreeNum ++;
	}

	ReleaseMutex(g_hMutex);  
}
// --------------------------------------------------------------------------------
//相应XMS_ctsCloseDevice产生的消息，修改关闭后的状态
void	CloseDeviceOK ( DeviceID_t *pDevice )
{
	TRUNK_STRUCT	*pOneTrunk;
	VOICE_STRUCT	*pOneVoice;
	
	if (pDevice == NULL)
	{
		return;
	}
	WaitForSingleObject(g_hMutex, INFINITE);

	if ( pDevice->m_s8ModuleID != g_u8UnitID)
	{
		AddLog("CloseDeviceOK: err m_s8ModuleID is %d", pDevice->m_s8ModuleID);
		return ;
	}

	AllDevice.bErrFlag = true;

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_BOARD )
	{
		AllDevice.bOpenFlag = false;
	}

	if (AllDevice.pTrunk == NULL)
	{
		AddLog("CloseDeviceOK pTrunk err %d", 888);
	}
	if (AllDevice.pFax == NULL)
	{
		AddLog("CloseDeviceOK pFax err %d", 888);
	}
	if (AllDevice.pVoice == NULL)
	{
		AddLog("CloseDeviceOK pVoice err %d", 888);
	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH )
	{
		pOneTrunk = &M_OneTrunk(*pDevice);

		Change_State ( pOneTrunk, TRK_WAITOPEN );

		// modify the count
		g_iTotalTrunkOpened --;
		AllDevice.lTrunkOpened --;
	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_VOICE )
	{
		pOneVoice = &M_OneVoice(*pDevice);

		Change_Voc_State ( pOneVoice, VOC_WAITOPEN);

		g_iTotalVoiceOpened --;
		g_iTotalVoiceFree --;
		AllDevice.lVocOpened --;
		AllDevice.lVocFreeNum --;

	}

	if ( pDevice->m_s16DeviceMain == XMS_DEVMAIN_FAX )
	{
		Change_Fax_State ( &M_OneFax(*pDevice), FAX_WAITOPEN );

		// modify the Count
		g_iTotalFaxOpened --;
		g_iTotalFaxFree --;
		AllDevice.lFaxOpened --;
		AllDevice.lFaxFreeNum --;
	}
	ReleaseMutex(g_hMutex);  
}


// --------------------------------------------------------------------------------
void	CloseTrunkDevice ( TRUNK_STRUCT *pOneTrunk, const int iNo )
{
	RetCode_t	r;
	if (pOneTrunk == NULL)
	{
		return;
	}
	pOneTrunk->State= TRK_WAITOPEN;

	r = XMS_ctsCloseDevice ( g_acsHandle, &pOneTrunk->deviceID, NULL );
	if ( r < 0 )
	{
		AddLog ( "XMS_ctsCloseDevice Fail in CloseTrunkDevice()! %d", iNo );
	}
}

void	CloseVoiceDevice ( VOICE_STRUCT *pOneVoice, const int iNo )
{
	RetCode_t	r;
	if (pOneVoice == NULL)
	{
		return;
	}
	r = XMS_ctsCloseDevice ( g_acsHandle, &pOneVoice->deviceID, NULL );
	if ( r < 0 )
	{
		AddLog ( "XMS_ctsCloseDevice Fail in CloseVoiceDevice()! %d", iNo );
	}
}

void	CloseFaxDevice ( FAX_STRUCT *pOneFax, const int iNo )
{
	RetCode_t	r;
	if (pOneFax == NULL)
	{
		return;
	}
	r = XMS_ctsCloseDevice ( g_acsHandle, &pOneFax->deviceID, NULL );
	if ( r < 0 )
	{
		AddLog( "XMS_ctsCloseDevice Fail in CloseFaxDevice()! %d", iNo );
	}
}

void	CloseBoardDevice ( DeviceID_t *pBoardDevID )
{
	RetCode_t	r;
	if (pBoardDevID == NULL)
	{
		return;
	}

	r = XMS_ctsCloseDevice ( g_acsHandle, pBoardDevID, NULL );

	if ( r < 0 )
	{
		AddMsg ( "XMS_ctsCloseDevice Fail in CloseBoardDevice()!" );
	}		
	else
	{
		AddLog("CloseBoardDevice ok", 1);
	}
}
//call XMS_ctsCloseDevice 关闭设备
void	CloseAllDevice_Dsp ( DJ_S8 s8DspModID )
{
	int			 i;
	
	// pTrunk
	for ( i = 0; i < AllDevice.lTrunkNum; i++ )
	{
		CloseTrunkDevice ( &AllDevice.pTrunk[i], i );
		//AddLog("CloseTrunkDevice %d", i);
	}

	// pVoice
	for ( i = 0; i < AllDevice.lVocNum; i++ )
	{
		CloseVoiceDevice ( &AllDevice.pVoice[i], i );
		//AddLog("CloseVoiceDevice %d", i);
	}

	// pFax
	for ( i = 0; i < AllDevice.lFaxNum; i++ )
	{
		CloseFaxDevice ( &AllDevice.pFax[i], i );
		//AddLog("CloseFaxDevice %d", i);
	}
	// close Board
	CloseBoardDevice ( &AllDevice.deviceID );

}


void	RefreshMapTable ( void )
{
	int		j;
	int		TrkCount, VocCount, ModuleCount, FaxCount;
	int		iModSeqID;

	WaitForSingleObject(g_hMutex, INFINITE);  

	// Remember the AllDeviceRes's Interface,Voice,PCM channel
	ModuleCount = TrkCount = VocCount = FaxCount = 0;
	//for ( i = 0; i < MAX_DSP_MODULE_NUMBER_OF_XMS; i ++ )
	//{
	 if ( AllDevice.lFlag == 1 )
	 {
		// DSP Module
		AllDevice.iSeqID = ModuleCount;
		//MapTable_Module[ModuleCount] = i;
		ModuleCount ++;

		 // Voice Channel
		 for ( j = 0; j < AllDevice.lVocNum; j ++ )
		 {
			AllDevice.pVoice[j].iSeqID = VocCount;
			MapTable_Voice[VocCount].m_s8ModuleID = AllDevice.pVoice[j].deviceID.m_s8ModuleID;
			MapTable_Voice[VocCount].m_s16ChannelID = AllDevice.pVoice[j].deviceID.m_s16ChannelID;
			VocCount ++;
		 }
		 // Fax Channel
		 for ( j = 0; j < AllDevice.lFaxNum; j ++ )
		 {
			AllDevice.pFax[j].iSeqID = FaxCount;
			MapTable_Fax[FaxCount].m_s8ModuleID = AllDevice.pFax[j].deviceID.m_s8ModuleID;
			MapTable_Fax[FaxCount].m_s16ChannelID = AllDevice.pFax[j].deviceID.m_s16ChannelID;
			FaxCount ++;
		 }

		 // Interface Channel
		 iModSeqID = 0;
		 for ( j = 0; j < AllDevice.lTrunkNum; j ++ )
		 {
			AllDevice.pTrunk[j].iSeqID = TrkCount;
			MapTable_Trunk[TrkCount].m_s8ModuleID = AllDevice.pTrunk[j].deviceID.m_s8ModuleID;
			MapTable_Trunk[TrkCount].m_s16ChannelID = AllDevice.pTrunk[j].deviceID.m_s16ChannelID;
			TrkCount ++;

			if ( AllDevice.pTrunk[j].deviceID.m_s16DeviceSub != XMS_DEVSUB_UNUSABLE )
			{
				// Available Channel
				AllDevice.pTrunk[j].iModSeqID = iModSeqID;
				iModSeqID ++;
			}			
		 }
	 }
	//}

	g_iTotalModule = ModuleCount;
	AddLog("RefreshMapTable:g_iTotalModule is %d", g_iTotalModule);

	g_iTotalTrunk = TrkCount;
	g_iTotalVoice = VocCount;
	g_iTotalFax = FaxCount;
	
	ReleaseMutex(g_hMutex);  
}

// -------------------------------------------------------------------------------------------------
//接收查询转换或者open后的消息，接收设置的当前状态
void	HandleDevState ( Acs_Evt_t *pAcsEvt )
{
	TRUNK_STRUCT	*pOneTrunk;
	Acs_GeneralProc_Data *pGeneralData = NULL;
	char TmpStr[255] = {0};

	if (pAcsEvt == NULL)
	{
		AddLog("HandleDevState err", 1);
		return;
	}
	int r  = WaitForSingleObject(g_hMutex, 10000/*INFINITE*/);   
	if (WAIT_TIMEOUT == r)
	{
		AddLog("HandleDevState WaitForSingleObject timeout", 1);
		return;
	}

	pGeneralData = (Acs_GeneralProc_Data *)FetchEventData(pAcsEvt);
	if (pGeneralData == NULL)
	{
		AddLog("HandleDevState pGeneralData is null", 1);
	}

	//test 2013-10-12
	/*
	AddLog("pGeneralData->m_s32DeviceState is %d", pGeneralData->m_s32DeviceState);
	if (pGeneralData->m_s32DeviceState ==  DES_FAX_SETPARAM)
	{
		AddLog(" user set pa", 1);
	}
	*/
	if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH )
	{

		if (AllDevice.pTrunk == NULL)
		{
			AddLog("HandleDevState pTrunk err",1);
		}
		pOneTrunk = &M_OneTrunk(pAcsEvt->m_DeviceID);

		pOneTrunk->iLineState = pGeneralData->m_s32DeviceState;
		//GetString_LineState(TmpStr, pOneTrunk->iLineState);
		
		//AddLog("CurTrunk %d State is:", pOneTrunk->deviceID.m_s16ChannelID);
		//AddMsg(TmpStr);
	}
	
	if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_FAX )
	{
		if (AllDevice.pFax == NULL)
		{
			AddLog("HandleDevState pFax err",1);
		}
		M_OneFax(pAcsEvt->m_DeviceID).iLineState = pGeneralData->m_s32DeviceState;
	}
	/*
	if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_VOICE )
	{
		if (AllDeviceRes[(pAcsEvt->m_DeviceID).m_s8ModuleID].pVoice == NULL)
		{
			AddLog("HandleDevState pVoice err",1);
		}
		M_OneVoice(pAcsEvt->m_DeviceID).iLineState = pGeneralData->m_s32DeviceState;
	}
	*/

	ReleaseMutex(g_hMutex);  
}

//初始化 TRUNK_STRUCT
void	InitTrunkChannel ( TRUNK_STRUCT *pOneTrunk )
{
	char TmpStr[255] = {0};

	if (pOneTrunk == NULL)
	{
		return;
	}
	Change_State ( pOneTrunk, TRK_FREE );
	
	memset ( &pOneTrunk->VocDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Voc Device
	memset ( &pOneTrunk->LinkDevID, 0, sizeof(DeviceID_t) );	// 0: didn't alloc Link Device
	memset ( &pOneTrunk->FaxDevID, 0, sizeof(DeviceID_t) );	

	//初始化很多公共变量
	AddLog("InitTrunkChannel call ResetXX", 1);
	ResetStartCallIn();
	
	AddLog("InitTrunkChannel call ResetXX OK", 1);
}

void ResetTrunk ( TRUNK_STRUCT *pOneTrunk)//, Acs_Evt_t *pAcsEvt_888 )
{
	TRUNK_STRUCT		 * pLinkUser = NULL;

	if (pOneTrunk == NULL)
	{
		return;
	}
	// free the link dev
	if ( pOneTrunk->LinkDevID.m_s16DeviceMain != 0 )
	{
		My_DualUnlink ( &pOneTrunk->LinkDevID, &pOneTrunk->deviceID );

		pLinkUser = &M_OneTrunk(pOneTrunk->LinkDevID);

		My_DualLink ( &pLinkUser->VocDevID, &pLinkUser->deviceID );
		//PlayTone ( &pLinkUser->VocDevID, 2 );		// busy tone

		memset ( &pLinkUser->LinkDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Link Device
	}

	// free the used Voice Resource
	if ( pOneTrunk->VocDevID.m_s16DeviceMain != 0 )
	{
		My_DualUnlink ( &pOneTrunk->VocDevID, &pOneTrunk->deviceID );

		FreeOneFreeVoice (  &pOneTrunk->VocDevID );

		memset ( &M_OneVoice(pOneTrunk->VocDevID).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
		memset ( &pOneTrunk->VocDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
	}

	// free the used Fax Resource
	if ( pOneTrunk->FaxDevID.m_s16DeviceMain != 0 )
	{
		// stop send or receive fax
		if ( pOneTrunk->State == TRK_FAX_SEND )
		{
			XMS_ctsStopSendFax ( g_acsHandle, &pOneTrunk->FaxDevID, NULL );
		}
		else if ( pOneTrunk->State == TRK_FAX_RECEIVE )
		{
			XMS_ctsStopReceiveFax ( g_acsHandle, &pOneTrunk->FaxDevID, NULL );
		}

		// free the fax device
		FreeOneFax ( &pOneTrunk->FaxDevID );

		memset ( &M_OneFax(pOneTrunk->FaxDevID).UsedDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
		memset ( &pOneTrunk->FaxDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
	}

	InitTrunkChannel ( pOneTrunk );
}

void	Change_State ( TRUNK_STRUCT *pOneTrunk, TRUNK_STATE NewState )
{
	if (pOneTrunk == NULL)
	{
		return;
	}
	pOneTrunk->State = NewState;
	
	char TmpStr[512] = {0};
	char StateStr[100] = {0}; 
	sprintf(TmpStr, "Change_State (%d, %d)", pOneTrunk->deviceID.m_s8ModuleID, pOneTrunk->deviceID.m_s16ChannelID);

	switch( pOneTrunk->State ) 
	{
	case TRK_WAITOPEN:
		strcpy(StateStr,"Wait Open"); 
		break;

	case TRK_FREE:		
		strcpy(StateStr,"Free"); 
		break ;

	case TRK_SIM_CALLOUT:
		strcpy(StateStr,"SimCallOut");
		break;

	case TRK_SIM_ANALOG_OFFHOOK	:
		strcpy(StateStr,"TRK_SIM_ANALOG_OFFHOOK");
		break;
		
	case TRK_SIM_ANALOG_DIALING	:
		strcpy(StateStr,"TRK_SIM_ANALOG_DIALING");
		break;
	case TRK_SIM_ANALOG_DIAL_OK:
		strcpy(StateStr,"ANALOG_DIAL_OK");
		break;
	
	case TRK_CALL_OUT_CONNECT:
		strcpy(StateStr, "CALL_OUT_CONNECT");
		break;
		
	case TRK_CALL_SEND_DATA:
		strcpy(StateStr, "SEND_DATA");
		break;

	case TRK_CALL_SEND_OK:
		strcpy(StateStr, "SEND_OK");
		break;

	case TRK_HANGUP:
		strcpy(StateStr, "HangUp");
		break;
		
	case TRK_FAIL:
		strcpy(StateStr,"FAIL");
		break;

	case TRK_CALL_IN:
		strcpy(StateStr,"TRK_CALL_IN");
		break;

	case TRK_CALL_IN_WAIT_ANSWERCALL:
		strcpy(StateStr,"IN_WAIT_ANSWERCALL");
		break;

	case TRK_CALL_IN_OFFHOOK:
		strcpy(StateStr,"CALL_IN_OFFHOOK");
		break;
	case TRK_CALL_IN_WAIT_LINKOK:
		strcpy(StateStr,"IN_WAIT_LINKOK");
		break;
	case TRK_CALL_IN_LINKOK:
		strcpy(StateStr,"IN_LINKOK");
		break;
	//fax
	case TRK_FAX_SEND:
		strcpy(StateStr,"TRK_FAX_SEND");
		break;
	case TRK_FAX_RECEIVE:
		strcpy(StateStr,"TRK_FAX_RECEIVE");
		break;
	case TRK_FAX_SEND_OK:
		strcpy(StateStr,"TRK_FAX_SEND_OK");
		break;
	case TRK_FAX_SEND_ERROR:
		strcpy(StateStr,"TRK_FAX_SEND_ERROR");
		break;
	case TRK_FAX_RECEIVE_OK:
		strcpy(StateStr,"TRK_FAX_RECEIVE_OK");
		break;
	case TRK_FAX_RECEIVE_ERROR:
		strcpy(StateStr,"TRK_FAX_RECEIVE_ERROR");
		break;
	default:
		strcpy(StateStr,"other");
		break;
	}
	
	strcat(TmpStr, StateStr);	
	AddMsg(TmpStr); 

	// Check if ready to remove DSP hardware
	if ( (AllDevice.RemoveState == DSP_REMOVE_STATE_START)
		&& (NewState == TRK_FREE) )
	{
		pOneTrunk->State = TRK_WAIT_REMOVE;
		CheckRemoveReady ( pOneTrunk->deviceID.m_s8ModuleID );
	}
}

void	Change_Voc_State ( VOICE_STRUCT *pOneVoice, VOICE_STATE NewState )
{
	if (pOneVoice == NULL)
	{
		return;
	}
	pOneVoice->State = NewState;

	// Check if ready to remove DSP hardware
	if ( (AllDevice.RemoveState == DSP_REMOVE_STATE_START)
		&& (NewState == VOC_FREE) )
	{
		pOneVoice->State = VOC_WAIT_REMOVE;

		CheckRemoveReady ( pOneVoice->deviceID.m_s8ModuleID );
	}
}

void	Change_Fax_State ( FAX_STRUCT *pOneFax, FAX_STATE NewState )
{
	if (pOneFax == NULL)
	{
		return;
	}
	pOneFax->State = NewState;	

	// Check if ready to remove DSP hardware
	if ( (AllDevice.RemoveState == DSP_REMOVE_STATE_START)
		&& (NewState == FAX_FREE) )
	{
		pOneFax->State = FAX_WAIT_REMOVE;

		CheckRemoveReady ( pOneFax->deviceID.m_s8ModuleID );
	}
}

// -------------------------------------------------------------------------------------------------
void	CheckRemoveReady ( DJ_S8 s8DspModID )
{
	int			i;

	// check device : INTERFACE_CH
	for ( i = 0; i < AllDevice.lTrunkNum; i ++ )
	{
		if ( (AllDevice.pTrunk[i].State != TRK_WAITOPEN)
			&& (AllDevice.pTrunk[i].State != TRK_WAIT_REMOVE) 
			/*&& (AllDevice.pTrunk[i].State != TRK_NOTHANDLE)*/ )
		{
			return;
		}

		if ( AllDevice.pTrunk[i].deviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_USER )
		{
			
		}
	}

	// check device : VOICE
	for ( i = 0; i < AllDevice.lVocNum; i ++ )
	{
		if ( (AllDevice.pVoice[i].State != VOC_WAITOPEN)
			&& (AllDevice.pVoice[i].State != VOC_WAIT_REMOVE) )
		{
			return;
		}
	}

	// all device in this DSP is ready for remove 
	AllDevice.RemoveState = DSP_REMOVE_STATE_READY;
}

void	My_DualLink ( DeviceID_t *pDev1, DeviceID_t *pDev2 )
{
	if (pDev1 == NULL || pDev2 == NULL)
	{
		return;
	}
	XMS_ctsLinkDevice ( g_acsHandle, pDev1, pDev2, NULL ); 
	XMS_ctsLinkDevice ( g_acsHandle, pDev2, pDev1, NULL ); 
}

void	My_DualUnlink ( DeviceID_t *pDev1, DeviceID_t *pDev2 )
{
	if (pDev1 == NULL || pDev2 == NULL)
	{
		return;
	}
	XMS_ctsUnlinkDevice ( g_acsHandle, pDev1, pDev2, NULL ); 
	XMS_ctsUnlinkDevice ( g_acsHandle, pDev2, pDev1, NULL ); 
}


// -------------------------------------------------------------------------------------
DJ_S32	PlayTone ( DeviceID_t	*pVocDevID, int iPlayType )
{
	DJ_U32           i = 0;	
	DJ_U16           u16IoLen = 0;
	DJ_U16           u16IoType = 0;
	RetCode_t		 r;
	char		 	 IoDataBuf[MAX_SEND_IODATA_DTMF_LEN]={0};
	
	if (pVocDevID == NULL)
	{
		return 0;
	}
	if ( iPlayType == -1 )	// Stop Play Tone
	{
		u16IoLen = 0;
		u16IoType = XMS_IO_TYPE_GTG;
	}
	else
	{
		u16IoType = XMS_IO_TYPE_GTG;
		u16IoLen = 1;

		switch ( iPlayType )
		{
		case 0:		// Dial Tone
			IoDataBuf[0] = 'G';
			break;
		case 1:		// Ring Back Tone
			IoDataBuf[0] = 'H';
			break;
		case 2:		// Busy Tone
			IoDataBuf[0] = 'I';
			break;
		}
	}

	r = XMS_ctsSendIOData ( g_acsHandle, pVocDevID, u16IoType,u16IoLen,IoDataBuf);

	return	r;

}

DJ_S32	StopPlayTone ( DeviceID_t	*pVocDevID )
{
	return PlayTone ( pVocDevID, -1 );
}

int		SearchOneFreeVoice (  TRUNK_STRUCT *pOneTrunk, DeviceID_t *pFreeVocDeviceID )
{

	DJ_S8			s8ModID;
	DJ_S16			s16ChID;
	int				i;
	static	int		iLoopStart = 0;
	VOICE_STRUCT	*pOneVoice;

	if (pOneTrunk == NULL || pFreeVocDeviceID == NULL)
	{
		return 0;
	}
	s8ModID = pOneTrunk->deviceID.m_s8ModuleID;

	// Fix relationship between Trunk & Voice
	s16ChID = pOneTrunk->deviceID.m_s16ChannelID;
	
	i = pOneTrunk->iModSeqID;

	if (s8ModID != g_u8UnitID)
	{
		AddLog("SearchOneFreeVoice: err s8ModID is %d",  s8ModID);
		return -1;
	}
#if 0 //重复用这个 
	
	if ( i < AllDevice.lVocNum ) //区别 重复用这个 不是遍历
	{
		pOneVoice = &AllDevice.pVoice[i];
		if ( pOneVoice->State != VOC_WAITOPEN )
		{
			*pFreeVocDeviceID = pOneVoice->deviceID;

			// use this voice device 
			Change_Voc_State ( pOneVoice, VOC_USED);
			AddLog("SearchOneFreeVoice reuse id is %d", (pOneVoice->deviceID).m_s16ChannelID);
			AllDevice.lVocFreeNum--;
			g_iTotalVoiceFree --;
			return i;
		}
	}
#else //遍历
	
	for ( i = 0; i < AllDevice.lVocNum; i ++ )
	{
		pOneVoice = &AllDevice.pVoice[i];
		if ( pOneVoice->State == VOC_FREE )
		{
			*pFreeVocDeviceID = pOneVoice->deviceID;

			// use this voice device 
			Change_Voc_State ( pOneVoice, VOC_USED);
			AddLog("SearchOneFreeVoice notreuse id is %d", (pOneVoice->deviceID).m_s16ChannelID);
			AllDevice.lVocFreeNum--;
			g_iTotalVoiceFree --;
			return i;
		}
	}
	 
#endif
	return -1;	
	//del some
}

int		FreeOneFreeVoice (  DeviceID_t *pFreeVocDeviceID )
{
	DJ_S8	s8ModID;

	if (pFreeVocDeviceID == NULL)
	{
		return 0;
	}
	s8ModID = pFreeVocDeviceID->m_s8ModuleID;
	if ( AllDevice.lFlag == 1 )
	{
		Change_Voc_State ( &M_OneVoice(*pFreeVocDeviceID), VOC_FREE);

		AllDevice.lVocFreeNum++;
		g_iTotalVoiceFree ++;
		AddLog("add g_iTotalVoiceFree is %d", g_iTotalVoiceFree);
		return	0;		// OK
	}

	return -1;			// invalid VocDeviceID
}

int		FreeOneFax (  DeviceID_t *pFreeFaxDeviceID )
{
	DJ_S8	s8ModID;

	if (pFreeFaxDeviceID == NULL)
	{
		return 0;
	}
	s8ModID = pFreeFaxDeviceID->m_s8ModuleID;
	if ( AllDevice.lFlag == 1 )
	{
		Change_Fax_State ( &M_OneFax(*pFreeFaxDeviceID), FAX_FREE);

		AllDevice.lFaxFreeNum++;
		g_iTotalFaxFree ++;

		return	0;		// OK
	}

	return -1;			// invalid VocDeviceID
}

int	 GetOneFreeTrunk (  int iTrunk, DeviceID_t *pFreeTrkDeviceID )
{
	DJ_S8	s8ModID;
	DJ_S16	s16ChID;
	char TmpStr[255] = {0};

	if (pFreeTrkDeviceID == NULL)
	{
		return 0;
	}
	s8ModID = MapTable_Trunk[iTrunk].m_s8ModuleID;
	s16ChID = MapTable_Trunk[iTrunk].m_s16ChannelID;

	sprintf( TmpStr, "GetOneFreeTrunk s8ModID is %d, ChannelID is %d", s8ModID, s16ChID);
	AddMsg( TmpStr );

	if ( ( AllDevice.pTrunk[s16ChID].iLineState == DCS_FREE )
		&& AllDevice.pTrunk[s16ChID].deviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK )
	{
		*pFreeTrkDeviceID = AllDevice.pTrunk[s16ChID].deviceID;
		return iTrunk;
	}
	
	return -1;
}


int		SearchOneFreeFax ( DeviceID_t *pFreeFaxDeviceID )
{
	int				i;
	static	int		iLoopStart = 0;
	FAX_STRUCT		*pOneFax;
	DJ_S8			s8SearchModID;
	long			lNowMaxFreeNum;

	if (pFreeFaxDeviceID == NULL)
	{
		return 0;
	}
	// Search in Max free resource module
	if (-1)
	{
		s8SearchModID = -1;
		lNowMaxFreeNum = -1;
		//for ( i = 0; i < g_iTotalModule; i ++ )
		//{
		if ( AllDevice.lFaxFreeNum > lNowMaxFreeNum )
		{
			s8SearchModID = g_u8UnitID;
			lNowMaxFreeNum = AllDevice.lFaxFreeNum;
		}
		//}
	}
	else
	{
		s8SearchModID = g_iTotalModule;
	}

	for ( i = 0; i < AllDevice.lFaxNum; i ++ )
	{
		pOneFax = &AllDevice.pFax[i];
		if ( pOneFax->State == FAX_FREE )
		{
			*pFreeFaxDeviceID = pOneFax->deviceID;

			// use this fax device 
			Change_Fax_State ( pOneFax, FAX_USED);

			AllDevice.lFaxFreeNum--;
			g_iTotalFaxFree --;

			return i;
		}
	}

	return -1;
}

int		FreeFaxRecordVoice (  TRUNK_STRUCT *pOneTrunk )
{
	RetCode_t r;
	return 1;
	/*
	pOneTrunk->VocDevIDRecordLinkVoc = FreeVocDeviceID_ForFax1;
	M_OneVoice(FreeVocDeviceID_ForFax1).UsedDevID = pOneTrunk->deviceID; 
	r = XMS_ctsLinkDevice ( g_acsHandle, &(pOneTrunk->VocDevID), &FreeVocDeviceID_ForFax1, NULL ); 
	
	pOneTrunk->VocDevIDRecordLinkVoc = FreeVocDeviceID_ForFax2;
	M_OneVoice(FreeVocDeviceID_ForFax2).UsedDevID = pOneTrunk->deviceID; 
	r = XMS_ctsLinkDevice ( g_acsHandle, &(pOneTrunk->deviceID), &FreeVocDeviceID_ForFax2, NULL ); 
	*/
	
	// free the original Voc Device
	//r = XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->VocDevID), &pOneTrunk->VocDevIDRecordLinkVoc, NULL ); 
	r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkVoc, NULL);
	
	AddLog( "FreeFaxRecordVoice rest VocDevIDRecordLinkVoc %d ", r);
	FreeOneFreeVoice ( &pOneTrunk->VocDevIDRecordLinkVoc );

	memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkVoc).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
	memset ( &pOneTrunk->VocDevIDRecordLinkVoc, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device

	// free the original Voc Device
	//r = XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->deviceID), &pOneTrunk->VocDevIDRecordLinkTrunk, NULL );	
	r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkTrunk, NULL);
	AddLog( "FreeFaxRecordVoice rest VocDevIDRecordLinkTrunk %d ", r);
	FreeOneFreeVoice ( &pOneTrunk->VocDevIDRecordLinkTrunk );

	memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkTrunk).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
	memset ( &pOneTrunk->VocDevIDRecordLinkTrunk, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device

	return 1;
}