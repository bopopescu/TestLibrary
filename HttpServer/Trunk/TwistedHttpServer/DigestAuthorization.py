# -*- coding: utf-8 -*-
from hashlib import md5



def parse_request_digest_authorization_data(authorization_data, request_method):
    """
    解析客户端digest认证数据
    """
    authorization_data=authorization_data[len('Digest')+1:]

    request_auth_digest_data_dict={}
    for item in authorization_data.split(','):
        if 2 == len(item.split('=')):
            item_key=item.split('=')[0].strip()
            item_value=item.split('=')[1].strip()
            
            if item_value.find("\"") > -1 or item_value.find("'") > -1:
                item_value=item_value[1:len(item_value)-1]

            print '%s:%s' % (item_key, item_value)
            request_auth_digest_data_dict[item_key]=item_value

    #print request_auth_digest_data_dict
    request_auth_digest_data_dict['method']=request_method
    
    return request_auth_digest_data_dict


def check_digest_authorization_data(cfg_auth_digest_option, request_auth_digest_data_dict):
    """
    进行客户端digest权限验证
    """
    if request_auth_digest_data_dict:
    
        #检查Client的认证信息的其他字段（qop,nonce,response）
        if request_auth_digest_data_dict.get('realm') == cfg_auth_digest_option['realm']:

            #根据约定的口令校验权限数据
            default_auth_request_data=create_response(cfg_auth_digest_option,
                                                    request_auth_digest_data_dict)
                        
            #print 'default_auth_request_data', default_auth_request_data
            #print 'response', request_auth_digest_data_dict.get('response')
            
            if request_auth_digest_data_dict.get('response') == default_auth_request_data:
                
                #认证成功
                return True
            
    #认证失败
    return False


def create_response(dict_acs_option,message):
    """
    根据Cfg的OPtion和客户端发送过来的认证信息，构造客户端response字段的检查信息
    """
    data = dict_acs_option
    if 'qop' not in message:
        A11 = A1(message,data)
        A21 = A2(message,data)
        response = KD(H(A11),message['nonce']+H(A21))
        return response
    
    elif message['qop'] == 'auth' or message['qop'] == 'auth-int':
        A11 = A1(message,data)
        A21 = A2(message,data)
        response = KD(H(A11),message['nonce']+':'+message['nc']+':'+message['cnonce']+
                      ':'+message['qop']+':'+H(A21))
        return response


def H(s):
    return md5(s).hexdigest()


def KD(secret, data):
    return H(secret + ':' + data)


def A1(message,data):
    """
    如果客户端回复的信息中algorithm的值为MD5或者没有提供
        则A1返回就为username:realm:password
    如果algorithm的值为MD5-sess
        则A1返回就为H(username:realm:password):nonce:cnonce
    """  
    #message为CPE认证信息，data为ACS Optionx信息
    username = data['username']
    password = data['password']
    realm = data['realm']
    nonce = message['nonce']
    cnonce = message['cnonce']
    algorithm = message.get('algorithm', None)
    #检查CPE认证信息中是否包含algorithm字段，fg根据algorithm返回不同的结果
    if algorithm == 'MD5' or algorithm == None:
        return "%s:%s:%s" % (username, realm, password)
        
    elif algorithm == 'MD5-sess':
        str_1 = username+':'+realm+':'+password
        return H(str_1)+':'+nonce+':'+cnonce
    else:
        return "%s:%s:%s" % (username, realm, password)
        


def A2(message,data):
    """
    如果客户端回复信息中有qop值为'auth'h或不c存在
        则A2返回结果为method：digest_uri
    如果qop值为'auth_int'
        则A2发回method:digest_uri_H(enting_body)
    """ 
    #message为CPE认证信息，data为ACS Optionx信息
    method = message['method']
    uri = message['uri']
    qop = message.get('qop', None)
    if qop == 'auth' or qop == None:
        return method + ':' + uri
    else:
        return method+':'+uri+':'+H(body)



def test1():
    """
    测试
    """
    authorization_data='Digest username="wangjun",\
realm="ATT",\
nonce="e436807a6c7064fec53299f7c9dcd5fb",\
uri="/",\
cnonce="62a5738911df07c91805f24f2dec9a9b",\
nc=00000001,\
response="09a5872e681e3bc9a901bd4312f9df9e",\
qop="auth",\
opaque="70f6b8988bb893571cffb64506c7d7d9"'    

    cfg_auth_digest_option={}
    cfg_auth_digest_option['username']='wangjun'
    cfg_auth_digest_option['password']= '123456'
    cfg_auth_digest_option['realm']= 'ATT'

    request_auth_digest_data_dict=parse_request_digest_authorization_data(authorization_data,'GET')
    #print request_auth_digest_data_dict

    print check_digest_authorization_data(cfg_auth_digest_option,request_auth_digest_data_dict)
    

if __name__ == "__main__":   
    test1()
    
    nExit = raw_input("Press any key to end...")