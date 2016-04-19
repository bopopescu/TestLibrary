
package provide     LOG 2.0

namespace eval LOG {

    ;# 几种level
    set LEVEL_USER                  "UserInfo"
    set LEVEL_APP                   "AppInfo"
    set LEVEL_RUN                   "RunInfo"
    set LEVEL_DEBUG                 "DebugWarn" 
    ;# dir name,也是combo filter name
    set DIR_NAME_USER               "User"
    set DIR_NAME_APP                "App"
    set DIR_NAME_RUN                "Run"
    set DIR_NAME_DEBUG              "Debug"


    ;# config
    set level                       $LEVEL_APP     ;# default
    set path                        "c:/Temp"          ;# 测试目录集入口路径 
    set printScreen                 false            ;# 是否使用puts
    set testCaseResultFileName      "测试用例执行结果统计表" ;# auto


    ;# open once
    set fileIdUser                  ""
    set fileIdApp                   ""
    set fileIdRun                   ""
    set fileIdDebug                 ""  
    set fileIdLog                   ""              ;# default & all log
}


;# 创建测试集 目录(用户的一次执行)
proc LOG::CreateTestSetPaths {args} {

    set curTime [clock second]
    set curTime [clock format $curTime -format {%Y%m%d%H%M%S}]

    ;# 添加 test name
    set rootPath    ""
    set rootPath    [format "%s_%s" $curTime "testcenter"]    
    
    ;# 一次测试的目录入口
    LOG::SetLogPath [file join "C:/Temp" $rootPath]    

    ;# 2级目录 (注意:不能含空格路径)
    set logPath [LOG::GetLogPath]
    file mkdir $logPath
    file mkdir $logPath/Debug
    file mkdir $logPath/Run
    file mkdir $logPath/App
    file mkdir $logPath/User
    
    ;# log.txt
    set LOG::fileIdLog [open  $logPath/log.txt a+]    
}


;# log模块 入口
proc LOG::Start {args} {

    ;# 支持启动参数 (一般为空)
    foreach {flag value} $args {

        switch -- $flag {

            -level
            {
                LOG::SetLogLevel $value
            }
            -print
            {
                LOG::SetPrintScreen $value
            }
            -path
            {
                LOG::SetLogPath $value
            }
            default
            {
            }
        }
    }

    ;# nwf 2011-12-23 创建目录集
    LOG::CreateTestSetPaths     
}


;# old 不再使用 (use:__FUNC__)
proc LOG::init {service} {

    return $service
}


proc LOG::GetLogLevel {} {

    return $LOG::level   
}



proc LOG::SetLogLevel {level} {

    ;# 默认级别
    set LOG::level $LOG::LEVEL_DEBUG
        
    if {-1  !=  [lsearch [list DebugWarn DebugInfo DebugErr RunInfo RunErr AppInfo AppErr UserInfo UserErr] $level] } {

        set LOG::level $level
    } else {

        ;# GUI log级别 映射到 log 级别
        set LOG::level [LOG::GetLogLevelEx $level]       
    }    
}



;# log 目录集入口 路径
proc LOG::GetLogPath {} {

    return $LOG::path
}

proc LOG::SetLogPath {path} {
    
    set LOG::path $path 
}

proc LOG::GetPrintScreen {} {

    return $LOG::printScreen
}

;# option =true or false 
;# 默认=true
proc LOG::SetPrintScreen {option} {

    set LOG::printScreen $option
}

proc LOG::GetTestCaseResultFileName {} {

    return $LOG::testCaseResultFileName 
}


;# 写日志接口集
;# 注意:对外接口顺序 有改动(Func 在 curFileName 之后)
proc LOG::TCResult    {curFileName func text} {

    LOG::Log TCResult     $curFileName $func  $text
}

proc LOG::UserErr     {curFileName func text} {

    LOG::Log UserErr      $curFileName $func  $text   
}

proc LOG::UserInfo    {curFileName func text} {

    LOG::Log UserInfo     $curFileName $func  $text   
}

proc LOG::AppErr      {curFileName func text} {

    LOG::Log AppErr       $curFileName $func  $text   
}

proc LOG::AppInfo     {curFileName func text} {

    LOG::Log AppInfo      $curFileName $func  $text
}

proc LOG::RunErr      {curFileName func text} {

    LOG::Log RunErr       $curFileName $func  $text  
}

proc LOG::RunInfo     {curFileName func text} {

    LOG::Log RunInfo      $curFileName $func  $text   
}

proc LOG::DebugErr    {curFileName func text} {

    LOG::Log DebugErr     $curFileName $func  $text   
}

proc LOG::DebugInfo   {curFileName func text} {

    LOG::Log DebugInfo    $curFileName $func  $text   
}

proc LOG::DebugWarn   {curFileName func text} {

    LOG::Log DebugWarn    $curFileName $func  $text   
}




;# +head
;# log 格式
;# Level=Debug or User
;# curFileName=调用LOG::UserInfo的tcl文件名字
;# Func=调用LOG::UserInfo的proc函数名字
;# textIn=log的内容
proc LOG::AddHead {level curFileName func text} {     

    set curTime [clock second]
    set curTime [clock format $curTime -format {%Y-%m-%d %H:%M:%S}]

    set scriptName [file tail [info script]]    

    ;# +log 头部
    set text "\[$curTime\]\[$scriptName\]\[$level\]\[$curFileName\]\[$func\]: \n\t$text\n"    

    return $text
}

;# log内部封装一次的log API
proc LOG::Log {curLevel curFileName func text} {
      
    set text [LOG::AddHead $curLevel $curFileName $func $text]    
    
    # 直接打印
    puts $text

    # 不单独保存到文件中
    #LOG::Log2File       $curLevel $text
    
}


;# 根据log level 获得 log file id
proc LOG::GetFileId {level} {

    set fileId $LOG::fileIdDebug     ;#default
    
    if {$level ==$LOG::LEVEL_USER} {

        set fileId $LOG::fileIdUser
    } elseif {$level ==$LOG::LEVEL_APP} {

        set fileId $LOG::fileIdApp
    } elseif {$level ==$LOG::LEVEL_RUN} {

        set fileId $LOG::fileIdRun
    }     

    return $fileId
}


;# 约束: 依赖testcase name
;# 在每个测试用例刚开始时调用
proc LOG::SetFilesId {} {

    set logPath         [LOG::GetLogPath]   
    set testCaseName    [TestCase::GetTestCaseName]
        
    ;#
    foreach filterLevel [list $LOG::DIR_NAME_USER $LOG::DIR_NAME_APP $LOG::DIR_NAME_RUN $LOG::DIR_NAME_DEBUG] {

        set fileName "${logPath}/$filterLevel/${testCaseName}.txt"

        if {$filterLevel == $LOG::DIR_NAME_USER} {

            catch {close $LOG::fileIdUser}    ;#关闭上一次的file(第一次为空)
            set LOG::fileIdUser [open $fileName a+]
        } elseif {$filterLevel == $LOG::DIR_NAME_APP} {

            catch {close $LOG::fileIdApp}    ;#关闭上一次的file
            set LOG::fileIdApp [open $fileName a+]
        } elseif {$filterLevel == $LOG::DIR_NAME_RUN} {

            catch {close $LOG::fileIdRun}    ;#关闭上一次的file
            set LOG::fileIdRun [open $fileName a+]
        } elseif {$filterLevel == $LOG::DIR_NAME_DEBUG} {

            catch {close $LOG::fileIdDebug}    ;#关闭上一次的file
            set LOG::fileIdDebug [open $fileName a+]
        }        
    }
}


;# Text=log的内容
proc LOG::Log2File {curLevel text} {

    set fileId      ""

    if { [catch {

        ;# log.txt
        puts $LOG::fileIdLog $text
        flush $LOG::fileIdLog
        

    } err ] } {
        
    }        
} 
