# -*- coding: utf-8 -*-

# /*************************************************************************
#  Copyright (C), 2012-2013, SHENZHEN GONGJIN ELECTRONICS. Co., Ltd.
#  module name: MyCheck
#  class:
#       封装了基于twidted web框架用户权限验证接口实现
# 
#  Author: ATT development group
#  version: V1.0
#  date: 2013.10.11
#  change log:
#         wangjun   2013.10.11   create
# ***************************************************************************


from twisted.cred import portal, checkers, credentials, error as credError
from twisted.internet import defer
from zope.interface import Interface, implements
import MyChars


class INamedUserAvatar(Interface):
    "should have attributes username and fullname"

class NamedUserAvatar:

    implements(INamedUserAvatar)

    def __init__(self, username, fullname):

        self.username = username
        self.fullname = fullname
        
        
class PasswordDictChecker(object):

    implements(checkers.ICredentialsChecker)
    credentialInterfaces = (credentials.IUsernamePassword,)

    def __init__(self, passwords):

        "passwords: a dict-like object mapping usernames to passwords"
        self.passwords = passwords

    def requestAvatarId(self, credentials):

        username = credentials.username

        if self.passwords.has_key(username):
            if credentials.password == self.passwords[username]:
                return defer.succeed(username)

            else:
                rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_CRED_BAD_PASSWORD)
                return defer.fail(credError.UnauthorizedLogin(rsp_string_data))
        else:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_CRED_NO_SUCH_USER)
            return defer.fail(credError.UnauthorizedLogin(rsp_string_data))


class TestRealm:

    implements(portal.IRealm)

    def __init__(self, users):
        self.users = users

    def requestAvatar(self, avatarId, mind, *interfaces):

        if INamedUserAvatar in interfaces:

            fullname = self.users[avatarId]

            logout = lambda: None

            return (INamedUserAvatar,
                    NamedUserAvatar(avatarId, fullname),
                    logout)
        else:
            rsp_string_data=MyChars.get_string_value(MyChars.STRING_REQUEST_CRED_NOTDEFINE_INTERFACE)
            raise KeyError(rsp_string_data)
