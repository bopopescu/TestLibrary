// VoipDebug.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "VoipDebug.h"
#include <exception>
int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
 	// TODO: Place code here.

	char* p = NULL;
	char str[25] = "GHI"; 
	char  c; 

	p = str;

	c = *p;
	c = *(p + 1);
	
	//sprintf();



	printf ( "dddd");
	int r;
	char buf[1024] = {0};
	char *b = buf;	
#if 0
	try
	{	
		for (int i =  0; i < 100; i++)
		{
			InitKeygoeSystem("E:\\robotproject\\plugin\\KeygoeForVoip\\keygoe");
			CheckTrunkReady(2, 0);
			CheckTrunkReady(2, 1);
			Sleep(3000);
			ExitKeygoeSystem();
		}
	}catch (exception &e) 
	{
		char ex[255] = {0};
		sprintf(ex, e.what());
		printf(ex);
	}
#endif
#if 0
	InitKeygoeSystem("E:\\voicecard\\DJK\\VoipDebug");
	CheckTrunkReady(2, 0);
	CheckTrunkReady(2, 1);
	Sleep(3000);
	CallOutOffHook(0);
	
	if (CheckDialTone(0,5000) < 0)
	{
		return 0;
	}

	Dial(0, strlen("1006"), "1003");
	Sleep(5000);
	SendData(0, -1, "11");
	Sleep(3000);


	SetFalse(0);
	Sleep(10000);
	
	Dial(0, strlen("1006"), "1005");
	Sleep(8000);
	
	Sleep(50000);
	return 0;
	SendData(0, -1, "8888");
	
	SetFalse(0);
	Sleep(3000);

	SendData(0, -1, "55555555");	


	Sleep(20000);

#endif	
#if 1
	if(CheckCallIn(1, 10) > 0)
	{		
		//CallInOffHook(1);
		//CheckAnswerTone(0);

		SendData(0, 1, "1212");
		Sleep(1000);
		GetRecvData(1, b, 4, 10);
		Sleep(1000);
		printf(b);

		/*
		StartRecvFax(0,"E:\\voicecard\\DJK\\r3.tif");
		SendFax(1, 0, "C:\\DJKeygoe\\Temp\\r2.tif", 240);
		Sleep(2000);
		GetRecvFaxResult(0, 240);

		Sleep(100);
		ClearRecvData(1);
		SetTrunkStateToSendData(1);
		SendData(0, 1, "2424");
		int t = GetRecvData(1, b, 4, 10);
		if (t < 0)
		{
			GetTrunkLinkState(1);
			GetTrunkState(1);
		}
		*/
		/*
		SendData(1, "789789");
		//Sleep(3000);
		GetRecvData(0);
		GetTrunkLinkState(0);
		GetTrunkState(0);
		*/
		//SendData(0, "987987");
		//GetRecvData(1);
	
	}else
	{
		GetTrunkLinkState(1);
	}

	ClearCall(0);
	ClearCall(1);

	//SendData(0,"077777");
	/*
	Sleep(2000);
	sprintf(buf, GetRecvData(1));
	printf(buf);

	SendData(1,"1333333");
	
	sprintf(buf, GetRecvData(0));//GetRecvData(0);
	printf(buf);

	Sleep(2000);
	ClearCall(0);
	ClearCall(1);
	*/	
	//Sleep(60000);

	
	getchar();
	
#endif
	
	
	return 0;
}



