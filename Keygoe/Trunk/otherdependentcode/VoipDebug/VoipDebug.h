#ifndef _VOIP_DEBUG_H_
#define _VOIP_DEBUG_H_

#pragma comment(lib, "..\\VoipKeygoe\\debug\\VoipKeygoe.lib")

#ifndef DECLSPEC_IMPORT
#define DECLSPEC_IMPORT __declspec(dllimport)  
#endif
extern "C" DECLSPEC_IMPORT int InitKeygoeSystem(const char* configFile); 
extern "C" DECLSPEC_IMPORT int ClearTrunk(const int iTrunk);
extern "C" DECLSPEC_IMPORT int ExitKeygoeSystem(); 

extern "C" DECLSPEC_IMPORT int CheckTrunkReady(const int count, const int iTrunk); //检查Trunk时候准备OK

//int StartCheckDialTone(const int iTrunk);
extern "C" DECLSPEC_IMPORT int CallOutOffHook(const int iTrunk); //呼出摘机
//int StartCheckAnswerTone(const int iTrunk); 
extern "C" DECLSPEC_IMPORT int Dial(const int iTrunk, const int iLen, const char* CallNumber); //拨号

extern "C" DECLSPEC_IMPORT int SendData(const int iTrunk, const int iDTrunk, const char* dtmf); //发送DTMF
extern "C" DECLSPEC_IMPORT int GetRecvData(const int iTrunk, char * &data, const int ilen, const int seconds);	//获取收到的DTMF
extern "C" DECLSPEC_IMPORT int SetTrunkStateToSendData(const int iTrunk);
extern "C" DECLSPEC_IMPORT int ClearRecvData(const int iTrunk); //清空之前所收到的DTMF
extern "C" DECLSPEC_IMPORT int GetTrunkLinkState(const int iTrunk); 

extern "C" DECLSPEC_IMPORT int SendFax(const int iTrunk, const int iDTrunk, char* filename, const int seconds); //发传真
extern "C" DECLSPEC_IMPORT int StartRecvFax(const int iTrunk, char* filename); //准备收传真
extern "C" DECLSPEC_IMPORT int GetRecvFaxResult(const int iTrunk, const int seconds); //等待接收过程完成，并返回是否成功
//extern "C" DECLSPEC_EXPORT int GetRecvData

//int StartCheckCallIn(const int iTrunk);
extern "C" DECLSPEC_IMPORT int CheckCallIn(const int iTrunk, const int seconds = 10);	//检查当前是否是Callin状态
extern "C" DECLSPEC_IMPORT int CallInOffHook(const int iTrunk); //呼入摘机

extern "C" DECLSPEC_IMPORT int ClearCall(const int iTrunk); //挂机

extern "C" DECLSPEC_IMPORT int GetTrunkState(const int iTrunk); 
extern "C" DECLSPEC_IMPORT int GetCallInRingTimes(const int iTrunk, const int seconds = 30);  //检查呼入时话机响了多少次


extern "C" DECLSPEC_IMPORT int SetFalse(const int iTrunk); //拍叉
extern "C" DECLSPEC_IMPORT int SetFalseTime(const int iTrunk, const int iTimes); //设置拍叉时间
extern "C" DECLSPEC_IMPORT int SetFaxFile(const int iTrunk, char* filename); //设置传真文件
extern "C" DECLSPEC_IMPORT int SetFaxBps(const int iTrunk, const int iBps );

//int CheckEnd(const int iTrunk);
#endif //_VOIP_DEBUG_H_