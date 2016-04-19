#include "StdAfx.h"
#include "VoipLog.h"
#include <stdio.h>
#include <time.h>
#include "VoipDeviceRes.h"
extern char	cfg_LogDir[MAX_FILE_NAME_LEN];
extern int  cfg_s32LogOn;
HANDLE g_hMutex_log = CreateMutex(NULL, FALSE, "LOGMutex");//INVALID_HANDLE_VALUE;  
void AddMsg ( char *str)
{
	if (cfg_s32LogOn <= 0)
	{
		return;
	}
	WaitForSingleObject(g_hMutex_log, INFINITE);   

	static	int		iTotal_ListMsg = 0;
	char			TmpStr[256] = {0};	
	static  char	FileName[MAX_FILE_NAME_LEN] = {0};

	sprintf ( TmpStr, "\n%6d: ", iTotal_ListMsg+1 );
	strcat ( TmpStr, str );

	if (0 == iTotal_ListMsg)
	{
		time_t lt; 
		lt = time(NULL); 
		sprintf(FileName, "%s\\voip%d.log", cfg_LogDir, lt);
		//sprintf(FileName, "E:\\vvvvv%d.txt", lt);
	}
	FILE* pf = fopen(FileName, "a+");
	if (pf == NULL)
	{
		ReleaseMutex(g_hMutex_log); 
		return;
	}
	fwrite(TmpStr, strlen(TmpStr), 1, pf);
	fclose(pf);

	iTotal_ListMsg ++;
	
	ReleaseMutex(g_hMutex_log);  
}

void AddLog ( const char *str, int n)
{	
	char TmpStr[256] = {0};	

	sprintf(TmpStr, str, n);
	AddMsg(TmpStr);
}
