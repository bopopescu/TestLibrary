#ifndef _VOIP_DEVICE_RES_H_
#define _VOIP_DEVICE_RES_H_
//设备相关操作（初始化、释放、重置、操作）

#define		MAX_FILE_NAME_LEN  256
//#define		MAX_DSP_MODULE_NUMBER_OF_XMS		2

#define		MAX_PCM_NUM_IN_THIS_DEMO			64
#define		MAX_TRUNK_NUM_IN_THIS_DEMO			(32*MAX_PCM_NUM_IN_THIS_DEMO)
#define		M_OneVoice(DevID)		AllDevice.pVoice[(DevID).m_s16ChannelID]
#define		M_OneTrunk(DevID)		AllDevice.pTrunk[(DevID).m_s16ChannelID]
#define		M_OneFax(DevID)			AllDevice.pFax[(DevID).m_s16ChannelID] 
//AllDeviceRes[(DevID).m_s8ModuleID].pFax[(DevID).m_s16ChannelID]

#define	MAX_FILE_NAME_LEN		256

#define	MAX_SEND_IODATA_DTMF_LEN	32

enum TRUNK_STATE {
	TRK_WAITOPEN = 0, 
	TRK_FREE,			
	//TRK_NOTHANDLE,
	//TRK_CALLOUT,
	TRK_SIM_CALLOUT, //摘机
	//TRK_SIM_LINK,
	TRK_SIM_ANALOG_OFFHOOK, //摘机成功
	TRK_SIM_ANALOG_DIALING, //拨号
	TRK_SIM_ANALOG_DIAL_OK, //拨号成功
	//TRK_LINK,
	TRK_CALL_OUT_CONNECT,//
	TRK_CALL_SEND_DATA,
	TRK_CALL_SEND_OK,//数据8

	TRK_CALL_IN, //有呼入事件， 开始检测呼入振铃 或触发摘机
	TRK_CALL_IN_WAIT_ANSWERCALL, //摘机
	TRK_CALL_IN_OFFHOOK, //摘机成功
	TRK_CALL_IN_WAIT_LINKOK, //连接设备
	TRK_CALL_IN_LINKOK, //连接成功 （摘机成功）

	TRK_FAX_SEND,
	TRK_FAX_SEND_OK,
	TRK_FAX_SEND_ERROR,
	TRK_FAX_RECEIVE,
	TRK_FAX_RECEIVE_OK,
	TRK_FAX_RECEIVE_ERROR,
	
	TRK_HANGUP,
	TRK_FAIL,
	TRK_WAIT_REMOVE,
};

enum FAX_STATE {
	FAX_WAITOPEN,
	FAX_FREE,
	FAX_USED,

	FAX_WAIT_REMOVE
} ;

typedef struct
{
	// ----------------
	DeviceID_t	deviceID;  
	int			iSeqID; 
	int			iModSeqID;
	int			iLineState;
	
	DeviceID_t	VocDevID;
	DeviceID_t	LinkDevID; //
	DeviceID_t	FaxDevID;

	DeviceID_t  VocDevIDRecordLinkVoc;
	DeviceID_t  VocDevIDRecordLinkTrunk;

	// -----------------
	TRUNK_STATE	State;
	int		DtmfCount;
	char	DtmfBuf[64];
	char CallerCode[20];
	char CalleeCode[20];
} TRUNK_STRUCT;

typedef struct
{
	// ----------------
	DeviceID_t	deviceID;
	int			iSeqID;
	int			iLineState;

	DeviceID_t	UsedDevID;
	FAX_STATE	State;

} FAX_STRUCT;

enum VOICE_STATE {
	VOC_WAITOPEN,
	VOC_FREE,
	VOC_USED,
	VOC_WAIT_REMOVE,
} ;

typedef struct
{
	// ----------------
	DeviceID_t	deviceID;
	int			iSeqID;

	DeviceID_t	UsedDevID;

	// ----------------
	VOICE_STATE	State;
} VOICE_STRUCT;

enum	REMOVE_STATE
{
	DSP_REMOVE_STATE_NONE	=	0,		// Do not remove the DSP hardware
	DSP_REMOVE_STATE_START	=	1,		// Ready to remove DSP hardware, wait all the Devices' Resource release
	DSP_REMOVE_STATE_READY	=	2,		// All the Devices' Resource have released, start delete DSP hardware
};

// --------------------------------------------------------------------------------
// define the structure: Single DSP's available Device Resource
typedef	struct _XMS_DSP_DEVICE_RES_DEMO
{
	_XMS_DSP_DEVICE_RES_DEMO()
	{
		lVocNum = 0;
		lVocOpened = 0;
		lVocFreeNum = 0;
		lTrunkNum = 0;
		lTrunkOpened = 0;
		lFaxNum = 0;
		lFaxOpened = 0;
		lFaxFreeNum = 0;
		pVoice = NULL;
		pTrunk = NULL;
		pFax = NULL;
	}
	~_XMS_DSP_DEVICE_RES_DEMO()
	{
		lVocNum = 0;
		lVocOpened = 0;
		lVocFreeNum = 0;
		lTrunkNum = 0;
		lTrunkOpened = 0;
		lFaxNum = 0;
		lFaxOpened = 0;
		lFaxFreeNum = 0;
		if (pVoice != NULL)
		{
			delete[] pVoice;
			pVoice = NULL;
		}
		if ( pTrunk != NULL)
		{
			delete[] pTrunk;
			pTrunk = NULL;
		}
		if (pFax != NULL)
		{
			delete[] pFax;
			pFax = NULL;
		}
	}
	long	lFlag;				// If this DSP exist, 0: not exist, 1: exist

	DeviceID_t	deviceID;		// this DSP's deviceID
	int			iSeqID;			// this DSP's Sequence ID
	bool		bOpenFlag;		// flag of OpenDevice OK
	bool		bErrFlag;		// flag of CloseDevice Event
	REMOVE_STATE	RemoveState;	// the state of stop DSP hardware

	long	lVocNum;			// the XMS_DEVMAIN_VOICE number in this DSP
	long	lVocOpened;			// the VOICE number opened by OpenDevice()
	long	lVocFreeNum;		// the free voice number in this DSP
	VOICE_STRUCT	*pVoice;	// the structer of voice, alloc as need

	long	lTrunkNum;			// the XMS_DEVMAIN_INTERFACE_CH number in this DSP
	long	lTrunkOpened;		// the Trunk number opened by OpenDevice()
	TRUNK_STRUCT	*pTrunk;	// the structer of Trunk, alloc as need
	
	long	lFaxNum;			// the XMS_DEVMAIN_FAX number in this DSP
	long	lFaxOpened;			// the Fax number opened by OpenDevice()
	long	lFaxFreeNum;		// the free fax number in this DSP
	FAX_STRUCT	*pFax;			// the structer of Fax, alloc as need

} TYPE_XMS_DSP_DEVICE_RES_DEMO;

// define the structer: use this, you can search the ModuleID & ChannelID
//           Warning: don't change this structer
typedef struct
{
    ModuleID_t      m_s8ModuleID;    /*device module type*/
    ChannelID_t     m_s16ChannelID;  /*device chan id*/
} TYPE_CHANNEL_MAP_TABLE;
// 

int		InitSystem(const char* configFile);
bool    ResInitDSPDEVICE();
void	ExitSystem();

void	ReadFromConfig(void);
void	InitAllDeviceRes (void);
void	FreeOneDeviceRes ( int ID );
void	FreeAllDeviceRes (void);

void	AddDeviceRes ( Acs_Dev_List_Head_t *pAcsDevList );
void	AddDeviceRes_Voice ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList );
void	AddDeviceRes_Trunk ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList );
void	AddDeviceRes_Fax ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList );
void	AddDeviceRes_Board ( DJ_S8 s8DspModID, Acs_Dev_List_Head_t *pAcsDevList );

void	OpenTrunkDevice ( TRUNK_STRUCT *pOneTrunk, const int iNo);
void	OpenVoiceDevice ( VOICE_STRUCT *pOneVoice, const int iNo );
void	OpenFaxDevice ( FAX_STRUCT *pOneFax, const int iNo );
void	OpenBoardDevice (  DJ_S8 s8DspModID );
void	OpenAllDevice_Dsp ( DJ_S8 s8DspModID );
void    QueryAllDevice_Dsp ( DJ_S8 s8DspModID );

void	CloseTrunkDevice ( TRUNK_STRUCT *pOneTrunk, const int iNo );
void	CloseVoiceDevice ( VOICE_STRUCT *pOneVoice, const int iNo );
void	CloseFaxDevice ( FAX_STRUCT *pOneFax, const int iNo );
void	CloseBoardDevice ( DeviceID_t *pBoardDevID );
void	CloseAllDevice_Dsp ( DJ_S8 s8DspModID );

void	OpenDeviceOK ( DeviceID_t *pDevice );
void	CloseDeviceOK ( DeviceID_t *pDevice );

void	RefreshMapTable ( void );

void	HandleDevState ( Acs_Evt_t *pAcsEvt );

//TRUNK_STRUCT 
void	InitTrunkChannel ( TRUNK_STRUCT *pOneTrunk );
void	ResetTrunk ( TRUNK_STRUCT *pOneTrunk);//, Acs_Evt_t *pAcsEvt );
void	Change_State ( TRUNK_STRUCT *pOneTrunk, TRUNK_STATE NewState );

//VOICE_STRUCT
void	Change_Voc_State ( VOICE_STRUCT *pOneVoice, VOICE_STATE NewState );
//Fax
void	Change_Fax_State ( FAX_STRUCT *pOneFax, FAX_STATE NewState );
//
void	CheckRemoveReady ( DJ_S8 s8DspModID );

void	My_DualLink ( DeviceID_t *pDev1, DeviceID_t *pDev2 );
void	My_DualUnlink ( DeviceID_t *pDev1, DeviceID_t *pDev2 );

DJ_S32	PlayTone ( DeviceID_t	*pVocDevID, int iPlayType );
DJ_S32	StopPlayTone ( DeviceID_t	*pVocDevID );

int		SearchOneFreeVoice (  TRUNK_STRUCT *pOneTrunk, DeviceID_t *pFreeVocDeviceID );
int		FreeOneFreeVoice (  DeviceID_t *pFreeVocDeviceID );
int		FreeOneFax (  DeviceID_t *pFreeFaxDeviceID );

int		SearchOneFreeFax ( DeviceID_t *pFreeFaxDeviceID );

int		GetOneFreeTrunk (  int iTrunk, DeviceID_t *pFreeTrkDeviceID );

#endif //_VOIP_DEVICE_RES_H_ end