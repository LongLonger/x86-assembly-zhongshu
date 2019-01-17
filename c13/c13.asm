         ;代码清单13-3
         ;文件名：c13.asm
         ;文件说明：用户程序 
         ;创建日期：2011-10-30 15:19   
         
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04

         stack_seg        dd 0                    ;用于接收堆栈段选择子#0x08 ;zhongshu-comment 参考 P231 第4段；（类比：第8章加载完用户程序后也会将段地址回填到用户程序中，具体见c08_mbr.asm 59~61行代码） 该双字是为栈保留的，当内核给该栈段分配了内存之后，将把该段的选择子回填到这里（仅占用低16位，因为选择子只占用16位）
         stack_len        dd 1                    ;程序建议的堆栈大小#0x0c
                                                  ;以4KB为单位
                                                  
         prgentry         dd start                ;程序入口#0x10
         code_seg         dd section.code.start   ;代码段位置#0x14   ;zhongshu-comment 参考 P231 第7段；（类比：第8章加载完用户程序后也会将段地址回填到用户程序中，具体见c08_mbr.asm 59~61行代码）  该双字是用户程序代码段的起始汇编地址，当内核完成对用户程序的加载和重定位之后，将把该段的选择子回填到这里（仅占用低16位，因为选择子只占用16位）
         code_len         dd code_end             ;代码段长度#0x18

         data_seg         dd section.data.start   ;数据段位置#0x1c   ;zhongshu-comment 参考 P231 第9段；（类比：第8章加载完用户程序后也会将段地址回填到用户程序中，具体见c08_mbr.asm 59~61行代码）  该双字是用户程序数据段的起始汇编地址，当内核完成对用户程序的加载和重定位之后，将把该段的选择子回填到这里（仅占用低16位，因为选择子只占用16位）
         data_len         dd data_end             ;数据段长度#0x20
             
;-------------------------------------------------------------------------------
         ;符号地址检索表 zhongshu-comment 26~38行 参考 P231倒数第6段 ~ P232 13.4.2以上
         salt_items       dd (header_end-salt)/256 ;#0x24
         
         salt:                                     ;#0x28
         PrintString      db  '@PrintString'    ;zhongshu-comment 在本程序使用例程时，不会是使用标号PrintString，而不是@PrintString，@PrintString是给c13_core.asm内核程序用的
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData'
                     times 256-($-ReadDiskData) db 0
                 
header_end:

;===============================================================================
SECTION data vstart=0    
                         
         buffer times 1024 db  0         ;缓冲区

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0
start:
         mov eax,ds
         mov fs,eax
     
         mov eax,[stack_seg]
         mov ss,eax
         mov esp,0
     
         mov eax,[data_seg]
         mov ds,eax
     
         mov ebx,message_1
         call far [fs:PrintString]  ;zhongshu-comment 调用内核提供的过程
     
         mov eax,100                         ;逻辑扇区号100
         mov ebx,buffer                      ;缓冲区偏移地址
         call far [fs:ReadDiskData]          ;段间调用
     
         mov ebx,message_2
         call far [fs:PrintString]
     
         mov ebx,buffer 
         call far [fs:PrintString]           ;too.
     
         jmp far [fs:TerminateProgram]       ;将控制权返回到系统 
      
code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: