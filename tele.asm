data segment
    tipChoice db 'type i to insert, s to search, u to update, d to delete, e to exit: $'
    tipSuccessfulExit db 'exit successfully... $'
    tipName db 'name? $'
    tipPhone db 'phone number? $'
    tipFail db 'this name does not exist... $'
    tipSuccessSearch db 'number: $'
    tipUpdate db 'update new phone number: $'
    tipSuccessDelete db 'delete successfully... $'
    tempName label byte     ;临时姓名
        max1   db 16
        len1   db ?
        head1  db 16 dup(?)
    tempPhone label byte    ;临时电话
        max2   db 16
        len2   db ?
        head2  db 16 dup(?)
    arr db 10 dup(16 dup(?),16 dup(?))    ;电话号码本
    shift db 0                             ;偏移值
data ends

code segment
main proc far
    assume cs:code,ds:data
    mov ax,data
    mov ds,ax
    mov es,ax

    call menu
    ret
main endp

menu proc near 
again:
    lea dx,tipChoice ;输出选项菜单:
    mov ah,09h
    int 21h
    call endl

    mov ah,01h      ;键入选项
    int 21h
    call endl

    cmp al,'e'
    jz callexit
    cmp al,'i'
    jz callinsert
    cmp al,'s'
    jz callsearch
    cmp al,'u'
    jz callupdate
    cmp al,'d'
    jz calldelete
    jmp again    ;其他字符重新载入

callexit:
    call exit
    ret
callinsert:
    call insert
    ret
callsearch:
    call search
    ret
callupdate:
    call update
    ret
calldelete:
    call delete
    ret
menu endp

exit proc near  ;结束程序
    lea dx,tipSuccessfulExit    ;提示成功退出
    mov ah,09h
    int 21h
    call endl
	mov ah,4ch
	int 21h
    ret
exit endp

insert proc near  ;插入信息
	lea dx,tipName    ;提示输入名字
    mov ah,09h
    int 21h
    call endl
    call inname     ;输入名字
    call endl

    lea dx,tipPhone    ;提示输入电话号码
    mov ah,09h
    int 21h
    call endl
    call inphone    ;输入号码
    call endl

    call store      ;存名字+号码
    jmp again       ;回到开头
    ret
insert endp

inname proc near    ;输入名字
    lea dx,tempName
    mov ah,0ah
    int 21h
    call fillTempNameBlank
    ret
inname endp

inphone proc near    ;输入号码
    lea dx,tempPhone
    mov ah,0ah
    int 21h
    call fillTempPhoneBlank
    ret
inphone endp

store proc near    ;存名字+号码shift
    lea di,arr      ;记录本首地址 + 偏移值
    add di,shift    ;赋值
    mov cl,16
    lea si,head1
    cld
    rep movsb
    mov cl,16
    lea si,head2
    cld
    rep movsb

    add shift,32    ;加上偏移值
    ret
store endp

fillTempNameBlank proc near    ;空格填不满十六位的位置
    mov al,20h      
    mov cl,len1     ;输入的name长
    xor ch,ch
    lea di,head1    ;tempName首地址
    add di,cx
    neg cx
    add cx,16
    cld
    rep stosb
    ret
fillTempNameBlank endp

fillTempPhoneBlank proc near    ;空格填不满十六位的位置
    mov al,20h
    mov cl,len2     ;输入的号码长
    xor ch,ch
    lea di,head2    ;tempPhone首地址
    add di,cx
    neg cx
    add cx,16
    cld
    rep stosb
    ret
fillTempPhoneBlank endp

search proc near  ;搜索信息
	call getname
loop1:
    mov cx,16
    lea si,head1
    lea di,arr
    add di,ax       ;偏移量
    repe cmpsb     
    jz searchsuccess
    add ax,32       ;否则ax+32继续找
    cmp ax,320      ;如果ax大于上限数组则查找失败
    jae searchfailed
    jmp loop1

searchsuccess:
    push ax
	lea dx,tipSuccessSearch    ;提示搜索成功
    mov ah,09h
    int 21h
    call endl
    pop ax

    mov cx,16       ;将找到的号码移动到tempPhone中
    lea di,head2
    lea si,arr
    add si,ax
    add si,16
    rep movsb
    
    mov cx,16       ;输出
    lea di,head2
loop2:
    mov dx,[di]
    mov ah,02h
    int 21h
    inc di
    loop loop2


    call endl
    jmp again       ;回到开头
    ret

searchfailed:
	call failure
    ret
search endp


update proc near  ;插入信息
	call getname
loop3:
    mov cx,16
    lea si,head1
    lea di,arr
    add di,ax       ;偏移量
    repe cmpsb     
    jz updatesuccess
    add ax,32       ;否则ax+32继续找
    cmp ax,320      ;如果ax大于上限数组则查找失败
    jae updatefailed
    jmp loop3

updatesuccess:
    push ax
	lea dx,tipUpdate    ;提示输入新号码
    mov ah,09h
    int 21h
    call endl

    call inphone     ;输入号码到tempPhone
    call endl

    pop ax
    mov cx,16       ;将tempPhone移到当前head2中
    lea di,arr
    lea si,head2
    add di,ax
    add di,16
    rep movsb

    jmp again       ;回到开头
    ret

updatefailed:
	call failure
    ret
update endp



delete proc near  ;插入信息
	call getname
loop4:
    mov cx,16
    lea si,head1
    lea di,arr
    add di,ax       ;偏移量
    repe cmpsb     
    jz deletesuccess
    add ax,32       ;否则ax+32继续找
    cmp ax,320      ;如果ax大于上限数组则查找失败
    jae deletefailed
    jmp loop4

deletesuccess:
    push ax
	lea dx,tipSuccessDelete    ;提示删除成功
    mov ah,09h
    int 21h
    call endl
    pop ax

    ;;;将删除位置后面所有的数据向前移动32位 共移动shift - ax位
    mov cx,shift
    sub cx,ax
    sub shift,32

    lea di,arr      ;arr + ax <- arr + ax + 32
    add di,ax
    lea si,arr
    add si,ax
    add si,32
    rep movsb

    jmp again       ;回到开头
    ret

deletefailed:
	call failure
    ret
delete endp

getname proc near
	lea dx,tipName    ;提示输入名字
    mov ah,09h
    int 21h
    call endl
    call inname     ;输入名字
    call endl
    mov ax,0
    ret
getname endp

failure proc near
	lea dx,tipFail    ;提示修改失败 没有找到这个人
    mov ah,09h
    int 21h
    call endl
    jmp again       ;回到开头
    ret
failure endp

endl proc near  ;回车换行
    push ax
    push dx
    mov ah,02h
    mov dl,0ah
    int 21h
    mov dl,0dh
    int 21h
    pop dx
    pop ax
    ret
endl endp

code ends
    end main