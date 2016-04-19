/********************************************************************
文件名:   Wlanapi.h
作者:     ATT项目开发组
版本:     V1.0-R1B010
日期:     2009-11-03
描述:     声明Wlanapi各个接口及结构，来自MSDN
其它:     无
函数列表:
    1. ATT_BasicTime_CustomSleep
    1. ATT_BasicTime_CustomWait
    1. ATT_BasicTime_CustomGetCurrentTime
历史记录:
    1. Date:
       Author:
       Modification:
********************************************************************/

#ifndef WLAN_API_H
#define WLAN_API_H

#pragma once


#define  WLAN_MAX_INTF_NUM           256

#define  WLAN_MAX_INTF_DESC           256

#define  AVAILABLE_SSID_NUM           256
#define  DOT11_SSID_MAX_LENGTH        32
#define  WLAN_MAX_NAME_LENGTH         256
#define  WLAN_MAX_PHY_TYPE_NUMBER     8

#define  WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES 0x00000001

typedef enum _WLAN_INTERFACE_STATE {
  wlan_interface_state_not_ready               = 0,
  wlan_interface_state_connected               = 1,
  wlan_interface_state_ad_hoc_network_formed   = 2,
  wlan_interface_state_disconnecting           = 3,
  wlan_interface_state_disconnected            = 4,
  wlan_interface_state_associating             = 5,
  wlan_interface_state_discovering             = 6,
  wlan_interface_state_authenticating          = 7 
} WLAN_INTERFACE_STATE, *PWLAN_INTERFACE_STATE;

typedef struct _WLAN_INTERFACE_INFO {
  GUID                 InterfaceGuid;
  WCHAR                strInterfaceDescription[WLAN_MAX_INTF_DESC];
  WLAN_INTERFACE_STATE isState;
}WLAN_INTERFACE_INFO, *PWLAN_INTERFACE_INFO;

typedef struct _WLAN_INTERFACE_INFO_LIST {
  DWORD               dwNumberOfItems;
  DWORD               dwIndex;
  WLAN_INTERFACE_INFO InterfaceInfo[];
}WLAN_INTERFACE_INFO_LIST, *PWLAN_INTERFACE_INFO_LIST;

typedef enum _WLAN_CONNECTION_MODE {
  wlan_connection_mode_profile,
  wlan_connection_mode_temporary_profile,
  wlan_connection_mode_discovery_secure,
  wlan_connection_mode_discovery_unsecure,
  wlan_connection_mode_auto,
  wlan_connection_mode_invalid 
} WLAN_CONNECTION_MODE, *PWLAN_CONNECTION_MODE;

typedef struct _DOT11_SSID {
  ULONG uSSIDLength;
  UCHAR ucSSID[DOT11_SSID_MAX_LENGTH];
}DOT11_SSID, *PDOT11_SSID;

typedef struct _NDIS_OBJECT_HEADER {
  UCHAR  Type;
  UCHAR  Revision;
  USHORT Size;
}NDIS_OBJECT_HEADER, *PNDIS_OBJECT_HEADER;

typedef UCHAR DOT11_MAC_ADDRESS[6];
typedef DOT11_MAC_ADDRESS* PDOT11_MAC_ADDRESS;

typedef enum _DOT11_BSS_TYPE {
  dot11_BSS_type_infrastructure   = 1,
  dot11_BSS_type_independent      = 2,
  dot11_BSS_type_any              = 3 
} DOT11_BSS_TYPE, *PDOT11_BSS_TYPE;

typedef struct _DOT11_BSSID_LIST {
  NDIS_OBJECT_HEADER Header;
  ULONG              uNumOfEntries;
  ULONG              uTotalNumOfEntries;
  DOT11_MAC_ADDRESS  BSSIDs[1];
}DOT11_BSSID_LIST, *PDOT11_BSSID_LIST;

typedef struct _WLAN_CONNECTION_PARAMETERS {
  WLAN_CONNECTION_MODE wlanConnectionMode;
  LPCWSTR              strProfile;
  PDOT11_SSID          pDot11Ssid;
  PDOT11_BSSID_LIST    pDesiredBssidList;
  DOT11_BSS_TYPE       dot11BssType;
  DWORD                dwFlags;
}WLAN_CONNECTION_PARAMETERS, *PWLAN_CONNECTION_PARAMETERS;

typedef DWORD WLAN_REASON_CODE, *PWLAN_REASON_CODE;
typedef ULONG WLAN_SIGNAL_QUALITY;

typedef enum _DOT11_PHY_TYPE {
  dot11_phy_type_unknown      = 0,
  dot11_phy_type_any          = 0,
  dot11_phy_type_fhss         = 1,
  dot11_phy_type_dsss         = 2,
  dot11_phy_type_irbaseband   = 3,
  dot11_phy_type_ofdm         = 4,
  dot11_phy_type_hrdsss       = 5,
  dot11_phy_type_erp          = 6,
  dot11_phy_type_ht           = 7,
  dot11_phy_type_IHV_start    = 0x80000000,
  dot11_phy_type_IHV_end      = 0xffffffff 
} DOT11_PHY_TYPE, *PDOT11_PHY_TYPE;

typedef enum _DOT11_AUTH_ALGORITHM {
  DOT11_AUTH_ALGO_80211_OPEN         = 1,
  DOT11_AUTH_ALGO_80211_SHARED_KEY   = 2,
  DOT11_AUTH_ALGO_WPA                = 3,
  DOT11_AUTH_ALGO_WPA_PSK            = 4,
  DOT11_AUTH_ALGO_WPA_NONE           = 5,
  DOT11_AUTH_ALGO_RSNA               = 6,
  DOT11_AUTH_ALGO_RSNA_PSK           = 7,
  DOT11_AUTH_ALGO_IHV_START          = 0x80000000,
  DOT11_AUTH_ALGO_IHV_END            = 0xffffffff 
} DOT11_AUTH_ALGORITHM, *PDOT11_AUTH_ALGORITHM;

typedef enum _DOT11_CIPHER_ALGORITHM {
  DOT11_CIPHER_ALGO_NONE            = 0x00,
  DOT11_CIPHER_ALGO_WEP40           = 0x01,
  DOT11_CIPHER_ALGO_TKIP            = 0x02,
  DOT11_CIPHER_ALGO_CCMP            = 0x04,
  DOT11_CIPHER_ALGO_WEP104          = 0x05,
  DOT11_CIPHER_ALGO_WPA_USE_GROUP   = 0x100,
  DOT11_CIPHER_ALGO_RSN_USE_GROUP   = 0x100,
  DOT11_CIPHER_ALGO_WEP             = 0x101,
  DOT11_CIPHER_ALGO_IHV_START       = 0x80000000,
  DOT11_CIPHER_ALGO_IHV_END         = 0xffffffff 
} DOT11_CIPHER_ALGORITHM, *PDOT11_CIPHER_ALGORITHM;


typedef struct _WLAN_AVAILABLE_NETWORK {
  WCHAR                  strProfileName[256];
  DOT11_SSID             dot11Ssid;
  DOT11_BSS_TYPE         dot11BssType;
  ULONG                  uNumberOfBssids;
  BOOL                   bNetworkConnectable;
  WLAN_REASON_CODE       wlanNotConnectableReason;
  ULONG                  uNumberOfPhyTypes;
  DOT11_PHY_TYPE         dot11PhyTypes[WLAN_MAX_PHY_TYPE_NUMBER];
  BOOL                   bMorePhyTypes;
  WLAN_SIGNAL_QUALITY    wlanSignalQuality;
  BOOL                   bSecurityEnabled;
  DOT11_AUTH_ALGORITHM   dot11DefaultAuthAlgorithm;
  DOT11_CIPHER_ALGORITHM dot11DefaultCipherAlgorithm;
  DWORD                  dwFlags;
  DWORD                  dwReserved;
}WLAN_AVAILABLE_NETWORK, *PWLAN_AVAILABLE_NETWORK;

typedef struct _WLAN_AVAILABLE_NETWORK_LIST {
  DWORD                  dwNumberOfItems;
  DWORD                  dwIndex;
  WLAN_AVAILABLE_NETWORK Network[1];
}WLAN_AVAILABLE_NETWORK_LIST, *PWLAN_AVAILABLE_NETWORK_LIST;

typedef enum _WLAN_INTF_OPCODE {
  wlan_intf_opcode_autoconf_start                               = 0x000000000,
  wlan_intf_opcode_autoconf_enabled,
  wlan_intf_opcode_background_scan_enabled,
  wlan_intf_opcode_media_streaming_mode,
  wlan_intf_opcode_radio_state,
  wlan_intf_opcode_bss_type,
  wlan_intf_opcode_interface_state,
  wlan_intf_opcode_current_connection,
  wlan_intf_opcode_channel_number,
  wlan_intf_opcode_supported_infrastructure_auth_cipher_pairs,
  wlan_intf_opcode_supported_adhoc_auth_cipher_pairs,
  wlan_intf_opcode_supported_country_or_region_string_list,
  wlan_intf_opcode_current_operation_mode,
  wlan_intf_opcode_supported_safe_mode,
  wlan_intf_opcode_certified_safe_mode,
  wlan_intf_opcode_hosted_network_capable,
  wlan_intf_opcode_autoconf_end                                 = 0x0fffffff,
  wlan_intf_opcode_msm_start                                    = 0x10000100,
  wlan_intf_opcode_statistics,
  wlan_intf_opcode_rssi,
  wlan_intf_opcode_msm_end                                      = 0x1fffffff,
  wlan_intf_opcode_security_start                               = 0x20010000,
  wlan_intf_opcode_security_end                                 = 0x2fffffff,
  wlan_intf_opcode_ihv_start                                    = 0x30000000,
  wlan_intf_opcode_ihv_end                                      = 0x3fffffff 
} WLAN_INTF_OPCODE, *PWLAN_INTF_OPCODE;

typedef enum _WLAN_OPCODE_VALUE_TYPE {
  wlan_opcode_value_type_query_only            = 0,
  wlan_opcode_value_type_set_by_group_policy   = 1,
  wlan_opcode_value_type_set_by_user           = 2,
  wlan_opcode_value_type_invalid               = 3 
} WLAN_OPCODE_VALUE_TYPE, *PWLAN_OPCODE_VALUE_TYPE;


typedef struct _WLAN_NOTIFICATION_DATA {
  DWORD NotificationSource;
  DWORD NotificationCode;
  GUID  InterfaceGuid;
  DWORD dwDataSize;
  PVOID pData;
}WLAN_NOTIFICATION_DATA, *PWLAN_NOTIFICATION_DATA;

typedef VOID (WLAN_NOTIFICATION_CALLBACK)(
    PWLAN_NOTIFICATION_DATA ,
    PVOID 
);

typedef struct _WLAN_PROFILE_INFO {
  WCHAR strProfileName[256];
  DWORD dwFlags;
}WLAN_PROFILE_INFO, *PWLAN_PROFILE_INFO;

typedef struct _WLAN_PROFILE_INFO_LIST {
  DWORD             dwNumberOfItems;
  DWORD             dwIndex;
  WLAN_PROFILE_INFO ProfileInfo[1];
}WLAN_PROFILE_INFO_LIST, *PWLAN_PROFILE_INFO_LIST;

typedef struct _WLAN_RAW_DATA {
  DWORD dwDataSize;
  BYTE  DataBlob[1];
}WLAN_RAW_DATA, *PWLAN_RAW_DATA;


typedef struct _WLAN_SECURITY_ATTRIBUTES {
  BOOL                   bSecurityEnabled;
  BOOL                   bOneXEnabled;
  DOT11_AUTH_ALGORITHM   dot11AuthAlgorithm;
  DOT11_CIPHER_ALGORITHM dot11CipherAlgorithm;
} WLAN_SECURITY_ATTRIBUTES, *PWLAN_SECURITY_ATTRIBUTES;


typedef struct _WLAN_ASSOCIATION_ATTRIBUTES {
  DOT11_SSID          dot11Ssid;
  DOT11_BSS_TYPE      dot11BssType;
  DOT11_MAC_ADDRESS   dot11Bssid;
  DOT11_PHY_TYPE      dot11PhyType;
  ULONG               uDot11PhyIndex;
  WLAN_SIGNAL_QUALITY wlanSignalQuality;
  ULONG               ulRxRate;
  ULONG               ulTxRate;
} WLAN_ASSOCIATION_ATTRIBUTES, *PWLAN_ASSOCIATION_ATTRIBUTES;


typedef struct _WLAN_CONNECTION_ATTRIBUTES {
  WLAN_INTERFACE_STATE        isState;
  WLAN_CONNECTION_MODE        wlanConnectionMode;
  WCHAR                       strProfileName[256];
  WLAN_ASSOCIATION_ATTRIBUTES wlanAssociationAttributes;
  WLAN_SECURITY_ATTRIBUTES    wlanSecurityAttributes;
} WLAN_CONNECTION_ATTRIBUTES, *PWLAN_CONNECTION_ATTRIBUTES;



extern "C" __declspec(dllexport)  DWORD WINAPI WlanOpenHandle(
  DWORD dwClientVersion,
  PVOID pReserved,
  PDWORD pdwNegotiatedVersion,
  PHANDLE phClientHandle
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanCloseHandle(
  HANDLE hClientHandle,
  PVOID pReserved
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanEnumInterfaces(
  HANDLE hClientHandle,
  PVOID pReserved,
  PWLAN_INTERFACE_INFO_LIST *ppInterfaceList
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanConnect(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  const PWLAN_CONNECTION_PARAMETERS pConnectionParameters,
  PVOID pReserved
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanDisconnect(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  PVOID pReserved
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanGetAvailableNetworkList(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  DWORD dwFlags,
  PVOID pReserved,
  PWLAN_AVAILABLE_NETWORK_LIST *ppAvailableNetworkList
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanRegisterNotification(
  HANDLE hClientHandle,
  DWORD dwNotifSource,
  BOOL bIgnoreDuplicate,
  WLAN_NOTIFICATION_CALLBACK  funcCallback,
  PVOID pCallbackContext,
  PVOID pReserved,
  PDWORD pdwPrevNotifSource
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanQueryInterface(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  WLAN_INTF_OPCODE OpCode,
  PVOID pReserved,
  PDWORD pdwDataSize,
  PVOID *ppData,
  PWLAN_OPCODE_VALUE_TYPE pWlanOpcodeValueType
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanGetProfileList(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  PVOID pReserved,
  PWLAN_PROFILE_INFO_LIST *ppProfileList
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanDeleteProfile(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  LPCWSTR strProfileName,
  PVOID pReserved
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanGetProfile(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  LPCWSTR strProfileName,
  PVOID pReserved,
  LPWSTR *pstrProfileXml,
  DWORD *pdwFlags,
  PDWORD pdwGrantedAccess
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanSetProfile(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  DWORD dwFlags,
  LPCWSTR strProfileXml,
  LPCWSTR strAllUserProfileSecurity,
  BOOL bOverwrite,
  PVOID pReserved,
  DWORD *pdwReasonCode
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanScan(
  HANDLE hClientHandle,
  const GUID *pInterfaceGuid,
  const PDOT11_SSID pDot11Ssid,
  const PWLAN_RAW_DATA pIeData,
  PVOID pReserved
);


extern "C" __declspec(dllexport)  VOID WINAPI WlanFreeMemory(
  PVOID pMemory
);

extern "C" __declspec(dllexport)  DWORD WINAPI WlanReasonCodeToString(
  DWORD dwReasonCode,
  DWORD dwBufferSize,
  PWCHAR pStringBuffer,
  PVOID pReserved
);

typedef enum _WLAN_INTERFACE_TYPE {
  wlan_interface_type_emulated_802_11   = 0,
  wlan_interface_type_native_802_11,
  wlan_interface_type_invalid 
} WLAN_INTERFACE_TYPE, *PWLAN_INTERFACE_TYPE;

#define WLAN_MAX_PHY_INDEX 64
typedef struct _WLAN_INTERFACE_CAPABILITY {
  WLAN_INTERFACE_TYPE interfaceType;
  BOOL                bDot11DSupported;
  DWORD               dwMaxDesiredSsidListSize;
  DWORD               dwMaxDesiredBssidListSize;
  DWORD               dwNumberOfSupportedPhys;
  DOT11_PHY_TYPE      dot11PhyTypes[WLAN_MAX_PHY_INDEX];
} WLAN_INTERFACE_CAPABILITY, *PWLAN_INTERFACE_CAPABILITY;


extern "C" __declspec(dllexport)   DWORD WINAPI 
WlanGetInterfaceCapability(
	HANDLE hClientHandle,
	CONST GUID *pInterfaceGuid,
	PVOID pReserved,
	PWLAN_INTERFACE_CAPABILITY *ppCapability
);

#endif

