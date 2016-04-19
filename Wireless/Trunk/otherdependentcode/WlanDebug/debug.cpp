#include "CommonHeadVc.h"

#pragma comment(lib,"Wlan.lib")


//add by jias 20130905
typedef struct _SecurityStruct  
{  
	//_SecurityStruct():success(-1),b(-1),auth(-1),cipher(-1){};
	BOOL    success;
    BOOL    b;  
    int		auth;  
    int		cipher;  
} SecurityStruct, *PSecurityStruct;  

//add by jias 20130905
typedef struct _ConnectionAttrStruct  
{  
	_ConnectionAttrStruct():success(-1),istate(-1),
		signalquality(0),rxrate(0),txrate(0)
	{
		memset(ssid, 0, wcslen(ssid)); //35*2
		memset(bssid, 0, wcslen(bssid));
	};
	BOOL    success;
	int			istate;
    wchar_t     ssid[35]; 
	wchar_t		bssid[35];
	int			signalquality;
	int			rxrate;
	int			txrate;
} ConnectionAttrStruct, *PConnectionAttrStruct;  

//nwf 2011-07-13;WLan 需要使用的接口
extern "C" __declspec(dllimport) int WLanConnect(wchar_t* ssid, wchar_t* strIndex=L"", int nIndex=-1, int timeout=30); 
extern "C" __declspec(dllimport) int WLanDisconnect(wchar_t* strIndex=L"", int nIndex=-1); 
extern "C" __declspec(dllimport) int WLanSetProfile(wchar_t* content, wchar_t* strIndex=L"", int nIndex=-1); 
//nwf 2011-08-22; +
extern "C" __declspec(dllimport) int WLanGetAvailableNetworkList(wchar_t* strIndex=L"", int nIndex=-1); 
extern "C" __declspec(dllimport) int WLanQueryInterface(wchar_t* strIndex=L"", int nIndex=-1,  int opCode=6); 
extern "C" __declspec(dllimport) int WLanGetProfile(wchar_t* ssid, wchar_t* strIndex=L"", int nIndex=-1);
extern "C" __declspec(dllimport) int WLanDeleteProfile(wchar_t* ssid, wchar_t* strIndex=L"", int nIndex=-1);
extern "C" __declspec(dllimport) int WLanGetDesc(wchar_t* &pDesc);
extern "C" __declspec(dllimport) int WLanDeleteProfiles(wchar_t* strIndex=L"", int nIndex=-1);
extern "C" __declspec(dllimport) int WLanIndexExist(int nIndex);
extern "C" __declspec(dllimport) int WLanGetSignalQuality(wchar_t* ssid, wchar_t* strIndex=L"", int nIndex=-1);

extern "C" __declspec(dllimport) PSecurityStruct WLanGetSecurityStruct(wchar_t* ssid, wchar_t* strIndex=L"", int nIndex=-1);
extern "C" __declspec(dllimport) PConnectionAttrStruct WLanQueryConnectionAttributes(wchar_t* strIndex=L"", int nIndex=-1);
extern "C" __declspec(dllimport) int WLanGetRet(wchar_t* &pDesc);

int printex(wchar_t* pwch)
{

	DWORD dwNum = WideCharToMultiByte(CP_OEMCP,NULL,pwch,-1,NULL,0,NULL,FALSE);
	char *psText;
	psText = new char[dwNum];
	if(!psText)
	{
		delete []psText;
	}
	WideCharToMultiByte (CP_OEMCP,NULL,pwch,-1,psText,dwNum,NULL,FALSE);
	printf("%s\n", psText);

	delete []psText;

	return 0;
}


int main( int argc, char *argv[] )
{	

	int nRet=0;
	char buf[1024]="";
	wchar_t* p=(wchar_t*)buf;

	
	char buf2[1024]="";
	wchar_t* p2=(wchar_t*)buf2;
	
	nRet = WLanGetAvailableNetworkList(L"", 0);
	WLanGetDesc(p);
	printex(p);

	WLanGetRet(p2);
	printex(p2);

	PSecurityStruct ps =  WLanGetSecurityStruct(L"ASUS-60", L"", 0);
	WLanGetDesc(p);
	printex(p);

	PConnectionAttrStruct pc = WLanQueryConnectionAttributes(L"", 0);
	WLanGetDesc(p);
	printex(p);

	nRet = WLanQueryInterface(L"", 0, 7);
	WLanGetDesc(p);
	printex(p);
	WLanGetRet(p2);
	printex(p2);
	
	getchar();
	return 0;
	if(1)
	{
		nRet = WLanQueryInterface(L"", 0, 6); //6, 7
		nRet = WLanQueryInterface(L"", 0, 7);		
		WLanGetDesc(p);
		printex(p);
	}

	if (0)
	{
		//nRet = WLanGetAvailableNetworkList(L"802.11n USB Wireless LAN Card");
		nRet = WLanGetSignalQuality(L"ChinaNet-laowang", L"", 0);
		WLanGetDesc(p);
		printex(p);
	}

	if (1)
	{
	//	nRet = WLanGetAvailableNetworkList(L"802.11n USB Wireless LAN Card");
		nRet = WLanGetAvailableNetworkList(L"", 0);
		WLanGetDesc(p);
		printex(p);
	}

	if(0)
	{
		int err_exist = 0;
		int err_times = 0;
		for(int i = 0; i < 20; i++)
		{
			nRet = WLanIndexExist(0);
			if (nRet != 1)
			{
				err_exist ++;
			}
			nRet = WLanQueryInterface(L"", 0, 6);
			if (nRet != 1)
			{
				err_times ++;
			}
			nRet = WLanConnect(L"yangjiasheng", L"", 0, 300);			
			if (nRet != 1)
			{
				err_times ++;
			}
			else
			{
				nRet = WLanQueryInterface(L"", 0, 6);
				if (nRet != 1)
				{
					err_times ++;
				}
				nRet = WLanDisconnect(L"", 0);
				nRet = WLanQueryInterface(L"", 0, 6);			
				if (nRet != 1)
				{
					err_times ++;
				}
			}
			WLanGetDesc(p);
			printex(p);		
		}
		printf("err_exist is %d\n", err_exist);
		printf("err_times is %d\n", err_times);
	}

	if(0)
	{
		nRet =WLanConnect(L"ChinaNet-laowang", L"", 0, 300); 
		WLanGetDesc(p);
		printex(p);
	}

	if (0)
	{
		nRet = WLanDisconnect(L"", 0);
		WLanGetDesc(p);
		printex(p);

	}

	if (0)
	{
		nRet =WLanDeleteProfile(L"gg", L"", 0);
		WLanGetDesc(p);
		printex(p);
	}

	if (0)
	{
		nRet =WLanDeleteProfiles(L"", 0);
		WLanGetDesc(p);
		printex(p);
	}

	if (0)
	{
		nRet = WLanGetProfile(L"ChinaNet-14", L"", 0);
		WLanGetDesc(p);
		printex(p);
	}


	if (0)
	{
		char* pch = 0;
		char buf[4096]={0};
		wchar_t* pw = 0;

		FILE* f;
		f=fopen("c:/nwf.txt","rb");
		pch=(char*)buf;
		fread(pch,sizeof(char), 4096, f);
		fclose(f);

		
		
		DWORD dwNum = MultiByteToWideChar (CP_ACP, 0, pch, -1, NULL, 0);
		wchar_t *pwText;
		pwText = new wchar_t[dwNum];
		if(!pwText)
		{
			delete []pwText;
		}
		MultiByteToWideChar (CP_ACP, 0, pch, -1, pwText, dwNum);

		nRet = WLanSetProfile(pwText, L"",0);
		delete []pwText;

		WLanGetDesc(p);
		printex(p);
		
	}


	if (0)
	{
		nRet = WLanQueryInterface(L"", 0, 7);
		WLanGetDesc(p);
		printex(p);
	}
	
	if (0)
	{
		nRet = WLanGetAvailableNetworkList(L"", 0);
		WLanGetDesc(p);
		printex(p);
	}


	getchar();
	
	return 0;
}
