#ifndef _VOIP_KEYGOE_H_
#define _VOIP_KEYGOE_H_

#include "VoipDeviceRes.h"

#ifndef DECLSPEC_EXPORT
#define DECLSPEC_EXPORT __declspec(dllexport)
#endif // DECLSPEC_EXPORT BOOL APIENTRY

//
extern "C" DECLSPEC_EXPORT int InitKeygoeSystem(const char* configFile); 
extern "C" DECLSPEC_EXPORT int ClearTrunk(const int iTrunk);
extern "C" DECLSPEC_EXPORT int ExitKeygoeSystem(); 

extern "C" DECLSPEC_EXPORT int WaitTrunkReady(); //检查Trunk是否准备OK
int CheckTrunkReady(const int iTrunk);

extern "C" DECLSPEC_EXPORT int CallOutOffHook(const int iTrunk); //呼出摘机
extern "C" DECLSPEC_EXPORT int Dial(const int iTrunk, const int iLen, const char* CallNumber); //拨号

extern "C" DECLSPEC_EXPORT int SendData(const int iTrunk, const char* dtmf); //发送DTMF
extern "C" DECLSPEC_EXPORT char* GetRecvData(const int iTrunk, const int ilen, const int seconds);	//获取收到的DTMF

//先不用
extern "C" DECLSPEC_EXPORT int SetTrunkStateToSendData(const int iTrunk);
//
extern "C" DECLSPEC_EXPORT int ClearRecvData(const int iTrunk); //清空之前所收到的DTMF
extern "C" DECLSPEC_EXPORT int GetTrunkLinkState(const int iTrunk); 

extern "C" DECLSPEC_EXPORT int GetRecvFaxResult(const int iTrunk, const int seconds, char *& info); //等待接收过程完成，并返回是否成功

extern "C" DECLSPEC_EXPORT int CheckCallIn(const int iTrunk, const int seconds = 10);	//检查当前是否是Callin状态
extern "C" DECLSPEC_EXPORT int CallInOffHook(const int iTrunk); //呼入摘机

extern "C" DECLSPEC_EXPORT int ClearCall(const int iTrunk); //挂机

extern "C" DECLSPEC_EXPORT int GetTrunkState(const int iTrunk); 
// 先不用
extern "C" DECLSPEC_EXPORT int GetCallInRingTimes(const int iTrunk, const int seconds = 30);  //检查呼入时话机响了多少次

//verion V1.1
extern "C" DECLSPEC_EXPORT int SendFax_prepare(const int iTrunk);
extern "C" DECLSPEC_EXPORT int SendFax(const int iTrunk, 
									   const int iBps, 
									   char* filename, 
									   const int seconds, 
									   char *& info, 
									   const int recordflg,
									   char* recordfilename_send = NULL,
									   char* recordfilename_recv = NULL);
extern "C" DECLSPEC_EXPORT int RecvFax_prepare(const int iTrunk);
extern "C" DECLSPEC_EXPORT int StartRecvFax(const int iTrunk, 
											const int iBps,
											char* filename,
											const int recordflg,
											char* recordfilename_send = NULL,
											char* recordfilename_recv = NULL);

extern "C" DECLSPEC_EXPORT int SetFlash(const int iTrunk); //拍叉
extern "C" DECLSPEC_EXPORT int SetFlashTime( const int iTimes); //设置拍叉时间
extern "C" DECLSPEC_EXPORT int SetFaxFile(const int iTrunk, char* filename); //设置传真文件
int SetFaxBps(DeviceID_t* pFaxDevID, const int iBps );
int SetFaxEcm(DeviceID_t* pFaxDevID, const int mode );//设置传真模式

extern "C" DECLSPEC_EXPORT int WaitSomeTone(const int iTrunk, char* Tones, const int milliseconds = 10000);  //检查人声，或h音
extern "C" DECLSPEC_EXPORT int UpdateTones();

extern "C" DECLSPEC_EXPORT int StartRecord(const int iTrunk, char* filename);
extern "C" DECLSPEC_EXPORT int StopRecord(const int iTrunk);
#endif //_VOIP_KEYGOE_H_ end