         ;代码清单9-2
         ;文件名：c09_2.asm
         ;文件说明：用于演示BIOS中断的用户程序 
         ;创建日期：2012-3-28 20:35
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code.start   ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;段重定位表项个数[0x0a]
    
    realloc_begin:
    ;段重定位表           
    code_segment    dd section.code.start   ;[0x0c]
    data_segment    dd section.data.start   ;[0x14]
    stack_segment   dd section.stack.start  ;[0x1c]
    
header_end:                
    
;===============================================================================
SECTION code align=16 vstart=0           ;定义代码段（16字节对齐） 
start:
      mov ax,[stack_segment]
      mov ss,ax
      mov sp,ss_pointer
      mov ax,[data_segment]
      mov ds,ax
      
      mov cx,msg_end-message    ;zhongshu-comment 计算有多少个字符，一个字符占一个字节，即计算两个标号之间相差多少字节。将计算结果传送到cx中，下文的loop指令会用到cx，cx用户控制循环的次数
      mov bx,message    ;zhongshu-comment message标号是字符串的首地址
      
 .putc:     ;zhongshu-comment 这里使用一种新的方式向屏幕上写字符：使用BIOS中断向屏幕上写字符，具体地说就是中断0x10的0x0e号功能，该功能用于在屏幕上的光标位置处写一个字符，并推进光标位置
      mov ah,0x0e   ;zhongshu-comment 通过ah寄存器指定使用该中断的0x0e号功能
      mov al,[bx]   ;zhongshu-comment 要显示的字符先放到al寄存器中
      int 0x10      ;zhongshu-comment 执行软中断0x10
      inc bx
      loop .putc

 .reps:
      mov ah,0x00
      int 0x16     ;zhongshu-comment 该中断返回后，用户敲击的那个键盘字符的ASCII码就保存在寄存器AL中了
      
      mov ah,0x0e
      mov bl,0x07   ;zhongshu-comment 黑底白字，字符的显示属性是放到bl寄存器吗？？
      int 0x10

      jmp .reps

;===============================================================================
SECTION data align=16 vstart=0

    message       db 'Hello, friend!',0x0d,0x0a
                  db 'This simple procedure used to demonstrate '
                  db 'the BIOS interrupt.',0x0d,0x0a
                  db 'Please press the keys on the keyboard ->'
    msg_end:
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end: