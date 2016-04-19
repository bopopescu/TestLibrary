



proc AddInfo {msg} {
    puts $msg
}

proc TclCompiler {fileList {indexFile ""}} {
    if {"" ==  $fileList} {
    #如果文件列表是空的，则直接返回1
        return 1
    }
    if {"" !=  $indexFile} {
        set indexFilePath [file dirname $indexFile]
        AddInfo "开始编译目录$indexFilePath 中的Tcl文件"
    
    }
    foreach url $fileList {
        AddInfo "正在编译文件 $url "
        if { [catch {set Result [exec tclcompiler $url]} errormsg] == 1 } {
            AddInfo "执行tclcompiler命令失败，错误信息如下： $errormsg "
            return -1
        }
    
        if {1 != [string match -nocase "*notice    Done*" $Result]} {
            AddInfo "执行tclcompiler命令失败，错误信息如下： $Result "
            return -1
        }
#        AddInfo "$url 编译成功"
    }
    
    if {"" !=  $indexFile} {
        set FileId      [open $indexFile r+]
        set indexFileInfo [read $FileId]
        close $FileId
        AddInfo "正在更新pkgIndex文件$indexFile"
        foreach url $fileList {
            set fileName [file tail $url]
            while {1} {
                set Num [string first $fileName $indexFileInfo]
                if {"-1" == $Num} {
                    break
                }
                set length [expr [string length $fileName] - 4]
                set indexFileInfo [string replace $indexFileInfo $Num [expr $Num + [expr $length + 3]] [file rootname $fileName].tbc]
            }
        }
        file delete $indexFile
        set FileId      [open $indexFile w+]
        puts -nonewline $FileId $indexFileInfo
        close $FileId
#        AddInfo "$indexFile 文件更新成功"
    }
    foreach url $fileList {    
        file delete $url
    }
    if {"" !=  $indexFile} {
        set indexFilePath [file dirname $indexFile]
        AddInfo "目录$indexFilePath 中的Tcl文件编译成功"
    }
    return 1
}


proc GetPathFile {path excludePath fileList} {
    upvar 1 $fileList filelist
    set files ""

    set files [glob -nocomplain [file join $path *]]
    
    foreach file $files {
        if {"" != $file} {
            if {1 == [file isfile $file]} {
                if {1 == [string match -nocase "*.tcl" $file]} {
                    if {1 != [string match -nocase "*pkgIndex.tcl" $file]} {
                        foreach exclude $excludePath {
                            if {1 == [string match -nocase "*$exclude*" "$file"]} {
                                set file ""
                            }
                        }
                        if {"" != $file} {
                            lappend filelist $file
                        }
                    } else {
                        continue
                    }
                }
            } else {
                set result [GetPathFile $file $excludePath filelist]
                if {"1" != $result} {
                    return $result
                }
            }
        }
    }
    return 1
}


proc GetpkgIndexFile {path excludePath pkgIndexFileList} {
    upvar 1 $pkgIndexFileList pkgindexfilelist
    set files ""

    set files [glob -nocomplain [file join $path *]]
    
    foreach file $files {
        if {"" != $file} {
            if {1 == [file isfile $file]} {
                if {1 == [string match -nocase "*.tcl" $file]} {
                    if {1 == [string match -nocase "*pkgIndex.tcl" $file]} {
                        foreach exclude $excludePath {
                            if {1 == [string match -nocase "*$exclude*" "$file"]} {
                                set file ""
                            }
                        }
                        if {"" != $file} {
                            foreach pkgindexfile $pkgindexfilelist {
                                set pkgindexfilePath [file dirname $pkgindexfile]
                                set filePath [file dirname $file]
                                if {1 == [string match -nocase "$pkgindexfilePath*" "$filePath"] || 1 == [string match -nocase "$filePath*" "$pkgindexfilePath"]} {
                                    AddInfo "发现pkgIndex.tcl文件路径存在嵌套目录，请确认信息是否正确，具体文件为：\n$file \n$pkgindexfile"
                                    return -1
                                }
                            }
                            lappend pkgindexfilelist $file
                        }
                    } else {
                        continue
                    }
                }
            } else {
                set result [GetpkgIndexFile $file $excludePath pkgindexfilelist]
                if {"1" != $result} {
                    return $result
                }                
            }
        }
    }
    return 1
}

proc Encrypt {path excludePath} {

    AddInfo "开始编译目录$path 中的Tcl文件为二进制文件。"
    
    set pkgIndexFileList ""
    set result [GetpkgIndexFile $path $excludePath pkgIndexFileList]
    if {"1" != $result} {
        return $result
    }

    foreach pkgIndexFile $pkgIndexFileList {
        set files ""
        set pkgIndexFilePath [file dirname $pkgIndexFile]
        set result [GetPathFile $pkgIndexFilePath $excludePath files]
        if {"1" != $result} {
            return $result
        }        
        set result [TclCompiler $files $pkgIndexFile]
        if {"1" != $result} {
            return $result
        }  
    }
    
    #处理根目录文件
    set files ""
    set files [glob -nocomplain [file join $path *.tcl]]
    
    foreach file $files {
        if {"" != $file} {
            if {1 == [file isfile $file]} {
                if {1 != [string match -nocase "*pkgIndex.tcl" $file]} {
                    set result [TclCompiler $file]
                    if {"1" != $result} {
                        return $result
                    }
                }
            }
        }
    }
    
    AddInfo "编译目录$path 中的Tcl文件为二进制文件完毕。"
    
    return 1
}
