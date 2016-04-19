#include "StdAfx.h"
#include "VoipEvent.h"
#include "VoipString.h"
#include "VoipLog.h"
#include "VoipDeviceRes.h"
#include <exception>
#include "VoipToneCfg.h"
#include "VoipKeygoe.h"

//extern TYPE_XMS_DSP_DEVICE_RES_DEMO	AllDeviceRes[MAX_DSP_MODULE_NUMBER_OF_XMS];
extern TYPE_XMS_DSP_DEVICE_RES_DEMO	AllDevice;

extern  ACSHandle_t		g_acsHandle;	//引用程序与keygoe子系统的连接句柄

//extern char	cfg_VocPath[128];

StartCallIn	  StartCallInState[TRUNK_NUM_MAX];
extern int	g_iTotalTrunkOpened;	


extern int	g_Tone_Count;
extern TYPE_ANALOG_TONE_PARAM MapTable_Tone[16];
extern int g_Freq_Count;
extern TYPE_ANALOG_FREQ_PARAM MapTable_Freq[16];

char g_SendFax_info[255] = {0};
char g_RecvFax_info[255] = {0};

int  g_SendFax_RecordFlg = 0;
int  g_RecvFax_RecordFlg = 0;

DJ_Void EvtHandler(DJ_U32 esrParam)
{
	Acs_Evt_t *			    pAcsEvt = NULL;
	Acs_Dev_List_Head_t *   pAcsDevList = NULL;

	pAcsEvt = (Acs_Evt_t *) esrParam;
	//PrintEventInfo ( pAcsEvt );

	if (pAcsEvt == NULL)
	{
		AddLog(" EvtHandler param error %d", 1);
		return;
	}
	switch ( pAcsEvt->m_s32EventType )
	{
		//test 2013-10-12
		/*
		case XMS_EVT_SETPARAM:
			{				
				Acs_ParamProc_Data* pSetParam = (Acs_ParamProc_Data*)FetchEventData(pAcsEvt);
				AddLog("XMS_EVT_SETPARAM :m_u16ParamCmdType=[%d]", pSetParam->m_u16ParamCmdType);			
				AddLog("XMS_EVT_SETPARAM :m_s32AcsEvtState=[%d]",  pSetParam->m_s32AcsEvtState); 
			}
			break;
			*/
		case XMS_EVT_QUERY_DEVICE:
			{
				pAcsDevList = ( Acs_Dev_List_Head_t *) FetchEventData(pAcsEvt);
				AddDeviceRes ( pAcsDevList );					
			}
			break; 

		case XMS_EVT_QUERY_ONE_DSP_START:
			break;
			
		case XMS_EVT_QUERY_ONE_DSP_END:
			OpenAllDevice_Dsp ( pAcsEvt->m_DeviceID.m_s8ModuleID );
			break;
			
		case XMS_EVT_QUERY_DEVICE_END:	// Query Device List End
			RefreshMapTable ( );
			break;

		case XMS_EVT_QUERY_REMOVE_ONE_DSP_END:
			QueryAllDevice_Dsp( pAcsEvt->m_DeviceID.m_s8ModuleID );
			break;

		case XMS_EVT_OPEN_DEVICE:
			OpenDeviceOK ( &pAcsEvt->m_DeviceID );
			break;
		
		case XMS_EVT_CLOSE_DEVICE:	// before Delete DSP, DSP send event CloseDevice to the APP; call XMS_ctsCloseDevicey() can generate this Event
			CloseDeviceOK ( &pAcsEvt->m_DeviceID );
			break;

		case XMS_EVT_DEVICESTATE:
			HandleDevState ( pAcsEvt );
			break;

		case XMS_EVT_UNIFAILURE:
			{
				/*
				char TmpStr[500] = {0};
				char TmpS[200] = {0};

				// must handle this event in your real System
				Acs_UniFailure_Data * pAcsUniFailure = (Acs_UniFailure_Data *) FetchEventData(pAcsEvt);

				sprintf ( TmpS, ": %s(0x%X) dev=(%s, %d, %d),  %d ?=? %d+%d", 
				GetString_ErrorCode(pAcsUniFailure->m_s32AcsEvtErrCode), pAcsUniFailure->m_s32AcsEvtErrCode,
				GetString_DeviceMain(pAcsEvt->m_DeviceID.m_s16DeviceMain),  pAcsEvt->m_DeviceID.m_s8ModuleID, pAcsEvt->m_DeviceID.m_s16ChannelID,
				pAcsEvt->m_s32EvtSize, sizeof(Acs_Evt_t), sizeof(Acs_UniFailure_Data) );
				sprintf( TmpStr, "*** XMS_EVT_UNIFAILURE:");
				strcat ( TmpStr, TmpS );
				AddMsg( TmpStr );
				*/
			}
			break;
        case XMS_EVT_MODMONITOR:
			{
				AddMsg ("*** XMS_EVT_MODMONITOR:  \n");
			}
			break;

		default:
			if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH  )
			{
				TrunkWork ( &M_OneTrunk(pAcsEvt->m_DeviceID), pAcsEvt );
			}
			else if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_VOICE )
			{
				DeviceID_t	*pDevID;

				pDevID = &M_OneVoice(pAcsEvt->m_DeviceID).UsedDevID;

				if ( pDevID->m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH )
				{
					TrunkWork ( &M_OneTrunk(*pDevID), pAcsEvt );
				}
			}
			else if ( pAcsEvt->m_DeviceID.m_s16DeviceMain == XMS_DEVMAIN_FAX )
			{
				DeviceID_t	*pDevID;

				pDevID = &M_OneFax(pAcsEvt->m_DeviceID).UsedDevID;

				if ( pDevID->m_s16DeviceMain == XMS_DEVMAIN_INTERFACE_CH )
				{
					FaxWork ( &M_OneTrunk(*pDevID), pAcsEvt );
				}
			}
			break;
	}
}

void PrintEventInfo ( Acs_Evt_t *pAcsEvt )
{
	char	TmpStr[256];
	char	TmpS[128];
	Acs_Dev_List_Head_t * pAcsDevList = NULL;
	Acs_UniFailure_Data * pAcsUniFailure = NULL;

	if (pAcsEvt == NULL)
	{
		return;
	}

	sprintf ( TmpStr, "EVT(%4d) : ", pAcsEvt->m_s32EvtSize );
	strcat ( TmpStr, GetString_EventType ( pAcsEvt->m_s32EventType ) );
	
	switch ( pAcsEvt->m_s32EventType )
	{
	case XMS_EVT_OPEN_STREAM:
		break;

	case XMS_EVT_QUERY_DEVICE:
		pAcsDevList = (Acs_Dev_List_Head_t *) FetchEventData(pAcsEvt);
		sprintf ( TmpS, " (%s,%2d,%3d)", 
			GetString_DeviceMain(pAcsDevList->m_s32DeviceMain),
			pAcsDevList->m_s32ModuleID,
			pAcsDevList->m_s32DeviceNum );
		strcat ( TmpStr, TmpS );
		break;

	case XMS_EVT_OPEN_DEVICE:
		break;

	case XMS_EVT_UNIFAILURE:
		pAcsUniFailure = (Acs_UniFailure_Data *) FetchEventData(pAcsEvt);
		sprintf ( TmpS, ": %s(0x%X) dev=(%s, %d, %d),  %d ?=? %d+%d", 
			GetString_ErrorCode(pAcsUniFailure->m_s32AcsEvtErrCode), pAcsUniFailure->m_s32AcsEvtErrCode,
			GetString_DeviceMain(pAcsEvt->m_DeviceID.m_s16DeviceMain),  pAcsEvt->m_DeviceID.m_s8ModuleID, pAcsEvt->m_DeviceID.m_s16ChannelID,
			pAcsEvt->m_s32EvtSize, sizeof(Acs_Evt_t), sizeof(Acs_UniFailure_Data) 
			);
		strcat ( TmpStr, TmpS );
		break;
		
	default:
		break;
	}
	AddMsg ( TmpStr );
}

void TrunkWork ( TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt )
{
	Acs_CallControl_Data *	pCallControl = NULL;
	//TRUNK_STRUCT		 *	pLinkUser = NULL;
	//DeviceID_t			FreeVocDeviceID;
	Acs_GeneralProc_Data *  pGeneral=NULL;
	char					TmpStr[128] = {0};
	char					RecvData[1024] = {0};	
	char					strtmp[100] = {0};
	Acs_AnalogInterface_Data* pAnalogInterface= NULL; 

	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return ;
	}
	int iCurTrunk = pOneTrunk->deviceID.m_s16ChannelID;

	//test code start	
	//TmpGtd = My_GetGtdOrPVDCode ( pOneTrunk, pAcsEvt ); //recv viocedata  G
	//#test code end 
	CheckTone(pOneTrunk, pAcsEvt);

	//从下面移过来，任何状态下都能接收数据   move by jias 20131212
	if ( pAcsEvt->m_s32EventType == XMS_EVT_RECVIODATA )
	{
		//存buf
		My_RecvDTMFData(pOneTrunk, pAcsEvt);
	}
	// move end

	if ( pAcsEvt->m_s32EventType == XMS_EVT_CLEARCALL )	/*Clear Event*/
	{
		if ( (pOneTrunk->State != TRK_FREE) && (pOneTrunk->State != TRK_WAIT_REMOVE) )
		{
			ResetTrunk ( pOneTrunk);//, pAcsEvt );
			AddLog( "CLEARCALL and ResetTrunk iCurTrunk is %d", iCurTrunk);
			return;
		}
	}
	switch(pOneTrunk->State)
	{
	case TRK_WAITOPEN:
		break;
	case TRK_FREE:
	case TRK_CALL_IN: 
		if ( pAcsEvt->m_s32EventType == XMS_EVT_CALLIN )	/* Call In Event */
		{			
			// release the Voice for get FSK
			if ( pOneTrunk->deviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK && 0 != pOneTrunk->VocDevID.m_s16DeviceMain )	 
			{
				AddLog("XMS_EVT_CALLIN here Unlink %d", (pOneTrunk->deviceID).m_s16ChannelID);
				My_DualUnlink ( &pOneTrunk->VocDevID, &pOneTrunk->deviceID );	
				FreeOneFreeVoice (	&pOneTrunk->VocDevID );	
				memset ( &M_OneVoice(pOneTrunk->VocDevID).UsedDevID, 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				memset ( &pOneTrunk->VocDevID, 0, sizeof(DeviceID_t) ); 	// 0: didn't alloc Device
			}					
			Change_State ( pOneTrunk, TRK_CALL_IN );	
		}
		//检测振铃
		if ( pAcsEvt->m_s32EventType == XMS_EVT_ANALOG_INTERFACE ) //振铃 几次后才会产生Call In Event
		{
			pAnalogInterface = (Acs_AnalogInterface_Data*)FetchEventData(pAcsEvt);

			if   ((pAcsEvt->m_DeviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK) 
			  && (pAnalogInterface->m_u8AnalogInterfaceState == XMS_ANALOG_TRUNK_CH_RING ))
			{
				StartCallInState[iCurTrunk].RingTimes += 1; //振铃一次
				//AddLog( "Ring once %d", StartCallInState[iCurTrunk].RingTimes);
				//Change_State ( pOneTrunk, TRK_CALL_IN );
			}
		}
		break;
	
	case TRK_SIM_CALLOUT: //摘机消息
		if ( pAcsEvt->m_s32EventType == XMS_EVT_CALLOUT )	
		{
			pCallControl = (Acs_CallControl_Data *)FetchEventData(pAcsEvt);
	
			//通过消息判断 摘机是否成功
			//AddLog("m_s32AcsEvtState : %d", pCallControl->m_s32AcsEvtState); //1成功-1失败		
			if (pCallControl->m_s32AcsEvtState != 1)
			{
				Change_State(pOneTrunk, TRK_FAIL);				
			}
			if(  pAcsEvt->m_DeviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK )
			{
				Change_State(pOneTrunk, TRK_SIM_ANALOG_OFFHOOK); 
			}
			else
			{
				Change_State(pOneTrunk, TRK_FAIL); //
			}
		}
		break;

	case TRK_SIM_ANALOG_OFFHOOK: //摘机成功后
		//检查拨号音、忙音
		//移到外层，任何状态下可以检测
		break;

	case TRK_SIM_ANALOG_DIALING: //拨号
		if ( pAcsEvt->m_s32EventType == XMS_EVT_SENDIODATA )	
		{
			Acs_IO_Data* pSendData = (Acs_IO_Data *)FetchIOData(pAcsEvt);
			//判断发送的数据(拨号状态)是否正确 #TODO
			//AddLog("m_s32AcsEvtState : %d", pSendData->m_s32AcsEvtState);
			//AddLog("m_s32AcsEvtErrCode : %d", pSendData->m_s32AcsEvtErrCode);			
			//AddMsg(GetString_ErrorCode(pSendData->m_s32AcsEvtErrCode));
			//AddLog( "send size is %d", pSendData->m_u16IoDataLen);
			//AddLog( "send type is %d", pSendData->m_u16IoType);

			Change_State(pOneTrunk, TRK_SIM_ANALOG_DIAL_OK);		
		}
		break;

	case TRK_SIM_ANALOG_DIAL_OK: //拨号完成
		//检查回铃音、忙音		
		//移到外层，任何状态下可以检测
		break;

	case TRK_CALL_OUT_CONNECT: //得到回铃音 可以说话
	case TRK_CALL_SEND_DATA:	
	case TRK_CALL_SEND_OK:
	case TRK_CALL_IN_LINKOK:
		if ( pAcsEvt->m_s32EventType == XMS_EVT_DEV_TIMER )
		{
			// time out
			sprintf(strtmp,"Wait data TimeOut");
			AddMsg(strtmp);
			break;
		}
		//把接收数据的移到外面， 所有状态下都能接收DTMF码 delete by jias 20131212
		/*
		if ( pAcsEvt->m_s32EventType == XMS_EVT_RECVIODATA )
		{
			//存buf
			My_RecvDTMFData(pOneTrunk, pAcsEvt);
		}
		*/
		if ( pAcsEvt->m_s32EventType == XMS_EVT_PLAY )	/*play Over Event*/
		{
			AddLog("PLAY iCurTrunk %d", iCurTrunk);			
		}		
		if ( pAcsEvt->m_s32EventType == XMS_EVT_SENDIODATA )	/*play Over Event*/
		{
			Change_State(pOneTrunk, TRK_CALL_SEND_OK);
		}
		break;
	case TRK_HANGUP: //在上面 修改为FREE状态了
		break;
	default:
		TrunkCallIn(pOneTrunk, pAcsEvt);
	}
}
//检测各种音（G——V）
void CheckTone (TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt )
{
	char					TmpGtd;
	Acs_AnalogInterface_Data* pAnalogInterface= NULL; 

	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return ;
	}
	int iCurTrunk = pOneTrunk->deviceID.m_s16ChannelID;
	if ( pAcsEvt->m_s32EventType == XMS_EVT_DEV_TIMER )
	{		
		AddLog("Wait some Tone TimeOut", 1); 
		UpdateToneTimesTimeOut(iCurTrunk);
	}	
	TmpGtd = My_GetGtdOrPVDCode ( pOneTrunk, pAcsEvt ); 
	if ( TmpGtd != -1 )
	{	
		UpdateToneTimes(iCurTrunk, TmpGtd);
	}
}

void FaxWork ( TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt )
{
	char					TmpStr[128] = {0};
	char					StateStr[1024] = {0};	
	char					strtmp[100] = {0};

	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return;
	}
	int iCurTrunk = pOneTrunk->deviceID.m_s16ChannelID;
	
	Acs_FaxProc_Data	 *  pFaxData = NULL;
		
	if ( pAcsEvt->m_s32EventType == XMS_EVT_CLEARCALL )	/*Clear Event*/
	{
		if ( (pOneTrunk->State != TRK_FREE) && (pOneTrunk->State != TRK_WAIT_REMOVE) )
		{
			ResetTrunk ( pOneTrunk);//, pAcsEvt );
			AddLog( "FaxWork_CLEARCALL and ResetTrunk iCurTrunk is %d", iCurTrunk);
			return;
		}
	}
	switch(pOneTrunk->State)
	{
	case TRK_FAX_SEND:
		if ( pAcsEvt->m_s32EventType == XMS_EVT_SENDFAX )	/* Send Fax OK*/
		{
			//还原传真模式
			SetFaxEcm(&pOneTrunk->FaxDevID, XMS_FAX_ECM_MODE_TYPE_NORMAL);

			pFaxData = (Acs_FaxProc_Data *)FetchEventData(pAcsEvt);		
			/*
			Acs_FaxProc_Data. m_u8ErrorStep表示发送传真的最后一次的错误状态值。
			Acs_FaxProc_Data. m_u8T30SendState表示T30发送状态值。
			Acs_FaxProc_Data. m_u8RecvT30Cmd表示最后一次接收到的T30命令。
			Acs_FaxProc_Data. m_u16TotalPages表示总共发送成功的页数。
			Acs_FaxProc_Data .m_s8RemoteID表示对端号码。
			*/

			memset(g_SendFax_info, 0, sizeof(g_SendFax_info));
			sprintf ( g_SendFax_info, 
					"Send Fax EvtState = %d, EvtErrCode = %d, ErrStep = %d, T30SendState = %d, TotalPages = %d, RemoteID = %d", 
					pFaxData->m_s32AcsEvtState, 
					pFaxData->m_s32AcsEvtErrCode, 
					pFaxData->m_u8ErrorStep,
					pFaxData->m_u8T30SendState,
					pFaxData->m_u16TotalPages,
					pFaxData->m_s8RemoteID);
			AddMsg(g_SendFax_info);
			
			if (pFaxData->m_s32AcsEvtState == 1)
			{
				Change_State(pOneTrunk, TRK_FAX_SEND_OK);
			}else
			{
				Change_State(pOneTrunk, TRK_FAX_SEND_ERROR);
			}

			if (g_SendFax_RecordFlg > 0)
			{
				
				//清除
				//r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkVoc, NULL);
				XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->VocDevID), &(pOneTrunk->VocDevIDRecordLinkVoc), NULL );
				FreeOneFreeVoice ( &(pOneTrunk->VocDevIDRecordLinkVoc) );
				memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkVoc).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				memset ( &(pOneTrunk->VocDevIDRecordLinkVoc), 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				
				//清除
				//r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkVoc, NULL);
				//XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->deviceID), &(pOneTrunk->VocDevIDRecordLinkTrunk), NULL );
				FreeOneFreeVoice ( &(pOneTrunk->VocDevIDRecordLinkTrunk) );
				memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkTrunk).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				memset ( &(pOneTrunk->VocDevIDRecordLinkTrunk), 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				
				AddLog("reclear sendfax flg", 1);
				g_SendFax_RecordFlg = 0;
			}
		}
		AddLog( "Fax send %d" , iCurTrunk);
		My_GetGtdOrPVDCode ( pOneTrunk, pAcsEvt ); 
		break;

	case TRK_FAX_RECEIVE:
		if ( pAcsEvt->m_s32EventType == XMS_EVT_RECVFAX )	/* Receive Fax OK*/
		{
			//还原传真模式
			SetFaxEcm(&pOneTrunk->FaxDevID, XMS_FAX_ECM_MODE_TYPE_NORMAL);

			pFaxData = (Acs_FaxProc_Data *)FetchEventData(pAcsEvt);
			
			memset(g_RecvFax_info, 0, sizeof(g_RecvFax_info));
			sprintf ( g_RecvFax_info, 
				"Receive Fax EvtState = %d, EvtErrCode = %d, ErrStep = %d, T30SendState = %d, TotalPages = %d, RemoteID = %d", 
				pFaxData->m_s32AcsEvtState, 
				pFaxData->m_s32AcsEvtErrCode, 
				pFaxData->m_u8ErrorStep,
				pFaxData->m_u8T30SendState,
				pFaxData->m_u16TotalPages,
				pFaxData->m_s8RemoteID);
			AddMsg(g_RecvFax_info);
			
			if (pFaxData->m_s32AcsEvtState == 1)
			{
				Change_State(pOneTrunk, TRK_FAX_RECEIVE_OK);
			}else
			{
				Change_State(pOneTrunk, TRK_FAX_RECEIVE_ERROR);
			}

			if (g_RecvFax_RecordFlg > 0) //前面记录 后面才清除
			{
				//清除
				//r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkVoc, NULL);
				XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->VocDevID), &(pOneTrunk->VocDevIDRecordLinkVoc), NULL );
				FreeOneFreeVoice ( &(pOneTrunk->VocDevIDRecordLinkVoc) );
				memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkVoc).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				memset ( &(pOneTrunk->VocDevIDRecordLinkVoc), 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				
				//清除
				//r = XMS_ctsResetDevice( g_acsHandle, &pOneTrunk->VocDevIDRecordLinkVoc, NULL);
				//XMS_ctsUnlinkDevice ( g_acsHandle, &(pOneTrunk->deviceID), &(pOneTrunk->VocDevIDRecordLinkTrunk), NULL );
				FreeOneFreeVoice ( &(pOneTrunk->VocDevIDRecordLinkTrunk) );
				memset ( &M_OneVoice(pOneTrunk->VocDevIDRecordLinkTrunk).UsedDevID,	0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				memset ( &(pOneTrunk->VocDevIDRecordLinkTrunk), 0, sizeof(DeviceID_t) );		// 0: didn't alloc Device
				
				AddLog("reclear recvfax flg", 1);
				g_RecvFax_RecordFlg = 0; 	
			}		
		}
		AddLog( "Fax recv %d" , iCurTrunk);
		My_GetGtdOrPVDCode ( pOneTrunk, pAcsEvt ); 	
		break;

	case TRK_FAX_SEND_ERROR:
		break;
	case TRK_FAX_RECEIVE_ERROR:
		break;
	default:
		AddLog("FaxWork state %d", pOneTrunk->State);		
	}

}

/* Handle Play */
DJ_S32	 PlayFile ( DeviceID_t	*pVocDevID, DJ_S8 *s8FileName, DJ_U8 u8PlayTag, bool bIsQueue )
{	
	DJ_U32           i = 0;	
	PlayProperty_t  playProperty;
	RetCode_t		 r;

	if (pVocDevID == NULL || s8FileName == NULL)
	{
		return -1;
	}
	memset(&playProperty,0,sizeof(playProperty));		
	
	if ( bIsQueue )
	{
		playProperty.m_u16PlayType = XMS_PLAY_TYPE_FILE_QUEUE;	
	}
	else
	{
		playProperty.m_u16PlayType = XMS_PLAY_TYPE_FILE;	
	}
	playProperty.m_u8TaskID = u8PlayTag;

	strcpy ( playProperty.m_s8PlayContent, s8FileName );
	
	r = XMS_ctsPlay ( g_acsHandle, pVocDevID, &playProperty, NULL );

	return r;
}
void SetGtd_AnalogTrunk(DeviceID_t* pDevId)
{
	//========Set GTG Begin========
				
	CmdParamData_Voice_t cmdVoc;
	
	if ( pDevId == NULL)
	{
		return;
	}
	memset(&cmdVoc,0,sizeof(cmdVoc));

	cmdVoc.m_u8GtdCtrlValid = 1 ; //Enable GTD
	cmdVoc.m_VocGtdControl.m_u8ChannelEnable = 1;//Enable Gtd channel
	cmdVoc.m_VocGtdControl.m_u8DTMFEnable = 1;
	cmdVoc.m_VocGtdControl.m_u8MR2FEnable = 1;
	cmdVoc.m_VocGtdControl.m_u8MR2BEnable = 1;
	cmdVoc.m_VocGtdControl.m_u8GTDEnable = 1;
	cmdVoc.m_VocGtdControl.m_u8FSKEnable = 1;
	
	cmdVoc.m_VocGtdControl.m_u8EXTEnable = 0x2;		// Enable PVD Detect

	strcpy((char*)&cmdVoc.m_VocGtdControl.m_u8GTDID[0],"GHIJKLMN");

	DJ_U16 u16ParamType = VOC_PARAM_UNIPARAM;
	DJ_U16 u16ParamSize = sizeof(cmdVoc);
	void* p = (void*) &cmdVoc;

	int r = XMS_ctsSetParam( g_acsHandle,pDevId,u16ParamType,u16ParamSize,(void*)p);
	
	char szbuffer[1024];
	memset(szbuffer,0,sizeof(szbuffer));
	sprintf(szbuffer,"Set GTD ret = %d",r);
	AddMsg ( szbuffer );

	//========Set GTG End  ========
}

char My_GetGtdOrPVDCode (TRUNK_STRUCT* pOneTrunk, Acs_Evt_t *pAcsEvt )
{
	Acs_IO_Data				*pIOData = NULL;
	char					sbuffer[200];
	char					*p;
	
	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return -1;
	}
	int iCurTrunk = pOneTrunk->deviceID.m_s16ChannelID;		

	memset(sbuffer, 0, sizeof(sbuffer));
	if ( pAcsEvt->m_s32EventType == XMS_EVT_RECVIODATA )	/*IO Data Event*/
	{
		pIOData = (Acs_IO_Data *)FetchEventData(pAcsEvt);

		if ( ( ( pIOData->m_u16IoType== XMS_IO_TYPE_GTG ) 
			|| ( pIOData->m_u16IoType== XMS_IO_TYPE_PVD )
			|| ( pIOData->m_u16IoType== XMS_IO_TYPE_DTMF))
			&& ( pIOData->m_u16IoDataLen > 0 ) )
		{
			p = (char *)FetchIOData(pAcsEvt);
			sprintf(sbuffer,"(%d) My_GetGtdOrPVDCode_RECVIODATA[%s] type(%d) len(%d)", 
				iCurTrunk, 
				p, 
				pIOData->m_u16IoType,
				pIOData->m_u16IoDataLen);
			AddMsg(sbuffer);			
			/*
			//save
			pOneTrunk->DtmfBuf[pOneTrunk->DtmfCount] = *p; 
			pOneTrunk->DtmfBuf[(pOneTrunk->DtmfCount)+1] = 0; 
			pOneTrunk->DtmfCount ++;
			//
			*/
			
			return *p;
		}
		else
		{
			p = (char *)FetchIOData(pAcsEvt);
			sprintf(sbuffer,"(%d) My_GetGtdOrPVDCode_RECVIODATA2[%s] type(%d) len(%d)", 
				iCurTrunk, 
				p, 
				pIOData->m_u16IoType,
				pIOData->m_u16IoDataLen);
			AddMsg(sbuffer);
		}
	}
	return -1;	// not a good GTD
}

int My_RecvDTMFData (TRUNK_STRUCT* pOneTrunk,  Acs_Evt_t *pAcsEvt )
{

	Acs_IO_Data				*pIOData = NULL;
	char					sbuffer[200];
	char					*p;

	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return -1;
	}
	int iCurTrunk = pOneTrunk->deviceID.m_s16ChannelID;	

	memset(sbuffer,0,sizeof(sbuffer));
	if ( pAcsEvt->m_s32EventType == XMS_EVT_RECVIODATA )	/*IO Data Event*/
	{
		pIOData = (Acs_IO_Data *)FetchEventData(pAcsEvt);

		if ((( pIOData->m_u16IoType== XMS_IO_TYPE_DTMF ) )
			//|| ( pIOData->m_u16IoType== XMS_IO_TYPE_PVD )
			//|| ( pIOData->m_u16IoType== XMS_IO_TYPE_GTG )) //add
			&& ( pIOData->m_u16IoDataLen > 0 ) )
		{
			p = (char *)FetchIOData(pAcsEvt); 
			*(p+pIOData->m_u16IoDataLen) = '\0';
			//sprintf(p, (char *)FetchIOData(pAcsEvt));//, pIOData->m_u16IoDataLen);
			sprintf(sbuffer,"(%d) My_RecvDTMFData_RECVIODATA[%s] type(%d) len(%d)", 
				iCurTrunk, 
				p, 
				pIOData->m_u16IoType,
				pIOData->m_u16IoDataLen);
			AddMsg(sbuffer);
			//save
			pOneTrunk->DtmfBuf[pOneTrunk->DtmfCount] = *p; 
			pOneTrunk->DtmfBuf[(pOneTrunk->DtmfCount)+1] = 0; 
			pOneTrunk->DtmfCount ++;
			//AddLog("DtmfCount is %d", pOneTrunk->DtmfCount);
		}
		else
		{
			p = (char *)FetchIOData(pAcsEvt);
			sprintf(sbuffer,"(%d) My_RecvDTMFData_RECVIODATA[%s] type(%d) len(%d)", 
				iCurTrunk, 
				p, 
				pIOData->m_u16IoType,
				pIOData->m_u16IoDataLen);
			AddMsg(sbuffer);
		}
	}

	return -1;	// not a good GTD
}


DJ_S32	PlayDTMF ( DeviceID_t	*pVocDevID, const char *DtmfStr )
{
	DJ_U32           i = 0, len;
	DJ_U16           u16IoType = 0;
	DJ_U16           u16IoLen = 0;
	char		 	 IoDataBuf[MAX_SEND_IODATA_DTMF_LEN]={0};
	RetCode_t		 r;


	if (pVocDevID == NULL || DtmfStr == NULL)
	{
		return -1;
	}

	if ( DtmfStr == NULL )	// Stop Play Dtmf
	{
		u16IoLen = 0;
	}
	else
	{
		u16IoType = XMS_IO_TYPE_DTMF;

		len = strlen(DtmfStr);
		if ( len > MAX_SEND_IODATA_DTMF_LEN )
			len = MAX_SEND_IODATA_DTMF_LEN;
		u16IoLen = (DJ_U16) len;

		memcpy ( IoDataBuf, DtmfStr, len );
	}

	r = XMS_ctsSendIOData ( g_acsHandle, pVocDevID, u16IoType,u16IoLen,IoDataBuf);

	return	r;

}

DJ_S32	StopPlayDTMF ( DeviceID_t	*pVocDevID )
{
	if (pVocDevID == NULL)
	{
		return -1;
	}
	return PlayDTMF ( pVocDevID, NULL );
}

int TrunkCallIn(TRUNK_STRUCT *pOneTrunk, Acs_Evt_t *pAcsEvt )
{
	int iRet = -1;

	RetCode_t               r = 0;
	Acs_CallControl_Data *	pCallControl = NULL;
	TRUNK_STRUCT		 *	pLinkUser = NULL;
	DeviceID_t				FreeVocDeviceID;
	Acs_GeneralProc_Data *  pGeneral=NULL;
	char                    strDTMF[20] = {0};
	DJ_S32                  i = 0;
	
	if (pOneTrunk == NULL || pAcsEvt == NULL)
	{
		return -1;
	}
	switch(pOneTrunk->State)
	{
		case TRK_CALL_IN_WAIT_ANSWERCALL:
		
			if ( pAcsEvt->m_s32EventType == XMS_EVT_ANSWERCALL )	/*Answer Call In End Event*/
			{
				pCallControl = (Acs_CallControl_Data *)FetchEventData(pAcsEvt);
		
				if ( SearchOneFreeVoice ( pOneTrunk,  &FreeVocDeviceID ) >= 0 )
				{
					pOneTrunk->VocDevID = FreeVocDeviceID;
		
					M_OneVoice(FreeVocDeviceID).UsedDevID = pOneTrunk->deviceID; 		
					My_DualLink ( &FreeVocDeviceID, &pOneTrunk->deviceID ); 
		
					if ( pOneTrunk->deviceID.m_s16DeviceSub == XMS_DEVSUB_ANALOG_TRUNK )
					{
						SetGtd_AnalogTrunk(&FreeVocDeviceID);		// prepare for get Busy Tone
					}
					Change_State ( pOneTrunk, TRK_CALL_IN_WAIT_LINKOK );
				}
			}
			break;
		
		case TRK_CALL_IN_WAIT_LINKOK:
			if ( pAcsEvt->m_s32EventType == XMS_EVT_LINKDEVICE )	/*LinkDevice End*/
			{		
				Change_State ( pOneTrunk, TRK_CALL_IN_LINKOK );
				//PlayDTMF(&(pOneTrunk->deviceID), "852");
				//Change_State(pOneTrunk, TRK_CALL_SEND_DATA);
			}
			break;
	}
	return iRet;
}

int ResetStartCallIn()
{
	for (int i = 0; i < TRUNK_NUM_MAX; i++)
	{	
		StartCallInState[i].RingTimes = 0;
	}
	return 1;
}

void SetGTD_ToneParam ( DeviceID_t *pDevice )
{
	RetCode_t					r;
	DJ_U16						u16ParamType, u16ParamSize;
	CmdParamData_GtdFreq_t		TmpGtdFreq;
	CmdParamData_GtdProtoType_t	TmpGtdProto;

	if (pDevice == NULL)
	{
		return;
	}

	// ---------- set Freq ----------
	u16ParamType = 	BOARD_PARAM_SETGTDFREQ ;
	u16ParamSize = sizeof(CmdParamData_GtdFreq_t);

	for (int i= 0; i < g_Freq_Count; i++ )
	{
		// freq0
		TmpGtdFreq.m_u16Freq_Index = MapTable_Freq[i].m_index;
		TmpGtdFreq.m_u16Freq_Coef = MapTable_Freq[i].m_Freq;
		AddLog("index is %d", TmpGtdFreq.m_u16Freq_Index);
		AddLog("Coef is %d", TmpGtdFreq.m_u16Freq_Coef);
		r = XMS_ctsSetParam( g_acsHandle, pDevice, u16ParamType, u16ParamSize, (DJ_Void *)&TmpGtdFreq );
		if ( r < 0)
		{
			AddLog("SetGTD_ToneParam:XMS_ctsSetParam  freq fial %d", r);
		}
		else
		{
			AddLog("SetGTD_ToneParam:XMS_ctsSetParam  freq OK", r);
		}
	}

	// ---------- set Tone ----------
	u16ParamType = 	BOARD_PARAM_SETGTDTONE ;
	u16ParamSize = sizeof(CmdParamData_GtdProtoType_t);
	
	for (int j = 0; j < g_Tone_Count; j++)
	{
		memset ( &TmpGtdProto, 0, sizeof(CmdParamData_GtdProtoType_t) );
		TmpGtdProto.m_u16GtdID = MapTable_Tone[j].m_id;	
		TmpGtdProto.m_u16Freq_Mask = MapTable_Tone[j].m_FreqIndexMask;
		TmpGtdProto.m_u16Repeat_Count = 1;
		TmpGtdProto.m_u16Envelope_Mode = MapTable_Tone[j].m_EnvelopeMode;
		if (TmpGtdProto.m_u16Envelope_Mode == 0)
		{
			TmpGtdProto.m_u16Min_On_Time1 = MapTable_Tone[j].m_On_Time / 15;		// the unit is 15 ms
		}		
		if (TmpGtdProto.m_u16Envelope_Mode > 0)
		{
			TmpGtdProto.m_u16Min_On_Time1 = (MapTable_Tone[j].m_On_Time * 
				(100 - MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Max_On_Time1 =  (MapTable_Tone[j].m_On_Time * 
				(100 + MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Min_Off_Time1 =  (MapTable_Tone[j].m_Off_Time * 
				(100 - MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Max_Off_Time1 =  (MapTable_Tone[j].m_Off_Time * 
				(100 + MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
		}		
		if (TmpGtdProto.m_u16Envelope_Mode == 2)
		{
			TmpGtdProto.m_u16Min_On_Time2 = (MapTable_Tone[j].m_On_Time_Two * 
				(100 - MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Max_On_Time2 =  (MapTable_Tone[j].m_On_Time_Two * 
				(100 + MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Min_Off_Time2 =  (MapTable_Tone[j].m_Off_Time_Two * 
				(100 - MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
			TmpGtdProto.m_u16Max_Off_Time2 =  (MapTable_Tone[j].m_Off_Time_Two * 
				(100 + MapTable_Tone[j].m_TimeDeviation)/100 ) / 15;		// the unit is 15 ms
		}
		/*
		AddLog("id is %d",TmpGtdProto.m_u16GtdID);
		AddLog("mask is%d", TmpGtdProto.m_u16Freq_Mask);
		AddLog("ontime is %d", TmpGtdProto.m_u16Min_On_Time1 * 15);
		AddLog("mode is%d", TmpGtdProto.m_u16Envelope_Mode);
		*/

		r = XMS_ctsSetParam( g_acsHandle, pDevice, u16ParamType, u16ParamSize, (DJ_Void *)&TmpGtdProto );
		if ( r < 0)
		{
			AddLog("SetGTD_ToneParam:XMS_ctsSetParam  tone fial %d", r);
		}
		else
		{
			AddLog("SetGTD_ToneParam:XMS_ctsSetParam  tone ok", r);
		}
	}
	Sleep(500);
}
// end of code for Analog
