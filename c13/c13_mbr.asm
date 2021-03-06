         ;代码清单13-1
         ;文件名：c13_mbr.asm
         ;文件说明：硬盘主引导扇区代码 
         ;创建日期：2011-10-28 22:35        ;设置堆栈段和栈指针 
         
         core_base_address equ 0x00040000   ;常数，内核加载的起始内存地址 zhongshu-comment 内核会加载到该物理内存地址处
         core_start_sector equ 0x00000001   ;常数，内核在磁盘的起始逻辑扇区号
    ;zhongshu-comment 9~55行，参考P13.2.2。 这些行的代码是为进入保护模式做准备
         mov ax,cs      
         mov ss,ax
         mov sp,0x7c00
      
         ;计算GDT所在的逻辑段地址
         mov eax,[cs:pgdt+0x7c00+0x02]      ;GDT的32位物理地址 
         xor edx,edx
         mov ebx,16
         div ebx                            ;分解成16位逻辑地址 
    ;zhongshu-comment 19~40行，参考P224 中下。这些行代码用于创建GDT、并安装了5个描述符(包括空描述符)
         mov ds,eax                         ;令DS指向该段以进行操作
         mov ebx,edx                        ;段内起始偏移地址 

         ;跳过0#号描述符的槽位 
         ;创建1#描述符，这是一个数据段，对应0~4GB的线性地址空间
         mov dword [ebx+0x08],0x0000ffff    ;基地址为0，段界限为0xFFFFF
         mov dword [ebx+0x0c],0x00cf9200    ;粒度为4KB，存储器段描述符 

         ;创建保护模式下初始代码段描述符
         mov dword [ebx+0x10],0x7c0001ff    ;基地址为0x00007c00，界限0x1FF 
         mov dword [ebx+0x14],0x00409800    ;粒度为1个字节，代码段描述符 

         ;建立保护模式下的堆栈段描述符      ;基地址为0x00007C00，界限0xFFFFE 
         mov dword [ebx+0x18],0x7c00fffe    ;粒度为4KB 
         mov dword [ebx+0x1c],0x00cf9600
         
         ;建立保护模式下的显示缓冲区描述符   
         mov dword [ebx+0x20],0x80007fff    ;基地址为0x000B8000，界限0x07FFF 
         mov dword [ebx+0x24],0x0040920b    ;粒度为字节
         
         ;初始化描述符表寄存器GDTR
         mov word [cs: pgdt+0x7c00],39      ;描述符表的界限   
 
         lgdt [cs: pgdt+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;中断机制尚未工作

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位
      
         ;以下进入保护模式... ...
         jmp dword 0x0010:flush             ;16位的描述符选择子：32位偏移
                                            ;清流水线并串行化处理器
         [bits 32]               
  flush:                                  
         mov eax,0x0008                     ;加载数据段(0..4GB)选择子 zhongshu-comment 段选择子0x0008=1000B，里面的描述符索引是1(二进制的位3~位15)，对应GDT中的第1个段描述符（第0个描述符是空描述符）
         mov ds,eax
      
         mov eax,0x0018                     ;加载堆栈段选择子 zhongshu-comment 段选择子0x0018=1_1000B，里面的描述符索引是11(二进制的位3~位15)，即十进制的3，对应GDT中的第3个描述符（第0个描述符是空描述符）
         mov ss,eax
         xor esp,esp                        ;堆栈指针 <- 0 
         
         ;以下加载系统核心程序 zhongshu-comment 67~93行，参考P224的最后两段~P225 13.2.3以上。作用是：从硬盘把内核程序c13_core.asm读入内存，和第八章的代码有点类似，但是因为是32位寄存器，用了很多32位的寄存器，所以稍有不同，P225的第1~3段说了不同之处
         mov edi,core_base_address      ;zhongshu-comment 内核加载的起始物理内存地址
      
         mov eax,core_start_sector      ;zhongshu-comment 内核在磁盘的起始逻辑扇区号
         mov ebx,edi                        ;起始地址 
         call read_hard_disk_0              ;以下读取程序的起始部分（一个扇区） 
      
         ;以下判断整个程序有多大
         mov eax,[edi]                      ;核心程序尺寸
         xor edx,edx 
         mov ecx,512                        ;512字节每扇区
         div ecx

         or edx,edx
         jnz @1                             ;未除尽，因此结果比实际扇区数少1 
         dec eax                            ;已经读了一个扇区，扇区总数减1 
   @1:
         or eax,eax                         ;考虑实际长度≤512个字节的情况 
         jz setup                           ;EAX=0 ?

         ;读取剩余的扇区
         mov ecx,eax                        ;32位模式下的LOOP使用ECX
         mov eax,core_start_sector
         inc eax                            ;从下一个逻辑扇区接着读
   @2:
         call read_hard_disk_0
         inc eax
         loop @2                            ;循环读，直到读完整个内核 
    ;zhongshu-comment 95~135行代码，参考P225~228 13.2.3 安装内核的段描述符
 setup:
         mov esi,[0x7c00+pgdt+0x02]         ;不可以在代码段内寻址pgdt，但可以通过4GB的段来访问 zhongshu-comment 因为该代码段貌似限制了不可读

         ;建立公用例程段描述符
         mov eax,[edi+0x04]                 ;“公用例程代码段”起始汇编地址 zhongshu-comment 内核被加载的起始物理地址是由EDI寄存器指向的。内核程序c13_core.asm偏移0x04处的一个双字，保存了内核程序公共例程段的起始汇编地址，所以edi+0x04就指向保存了“内核程序公共例程段的汇编地址”的内存单元
         mov ebx,[edi+0x08]                 ;“核心数据段”汇编地址 zhongshu-comment 道理同99行的注释
         sub ebx,eax    ;zhongshu-comment 见P222 图13-1 可知，“公共例程代码段”后面紧跟着的就是“核心数据段”，所以：公共例程代码段的汇编地址 - 核心数据段的汇编地址 = 公共例程代码段的长度（单位是字节）。
         dec ebx                            ;公用例程段界限 zhongshu-comment 对于向上扩展的段来说，段界限 = 段长度 - 1
         add eax,edi                        ;公用例程段基地址 zhongshu-comment 内核被加载的起始物理地址是由EDI寄存器指向的，而eax是公共例程代码段的汇编地址(汇编地址即：相对于程序开头的偏移量)，所以eax + edi就得到了内核程序公共例程代码段的起始物理地址
         mov ecx,0x00409800                 ;字节粒度的代码段描述符 zhongshu-comment ---- ---- 0100 ---- 1001 1000 ---- ----  位24~31、位0~7都是段起始地址的一部分，位16~19是段界限的一部分，这些位都不需要理会，因为段起始地址由EAX负责，段界限由EBX负责。ECX负责段的各种属性，这里只需要关注非“-”部分即可，不需要关注的那些位我用“-”表示了
         call make_gdt_descriptor       ;zhongshu-comment 这是104行的注释，解释那3段数字都是什么位：①G、D/B、L、AVL。 ②P、DPL(占2位)、S。 ③TYPE(占4位)
         mov [esi+0x28],eax     ;zhongshu-comment 执行了第96行代码后，ESI寄存器的内容是GDT的基地址。106~107行 参考 P228 第5段。将make_gdt_descriptor过程的返回结果edx:eax共8个字节的描述符追加到GDT中，106行先写入低32位，107行写入高32位
         mov [esi+0x2c],edx
       
         ;建立核心数据段描述符 zhongshu-comment 同98~107行
         mov eax,[edi+0x08]                 ;核心数据段起始汇编地址
         mov ebx,[edi+0x0c]                 ;核心代码段汇编地址 
         sub ebx,eax
         dec ebx                            ;核心数据段界限
         add eax,edi                        ;核心数据段基地址
         mov ecx,0x00409200                 ;字节粒度的数据段描述符 
         call make_gdt_descriptor
         mov [esi+0x30],eax
         mov [esi+0x34],edx 
      
         ;建立核心代码段描述符 zhongshu-comment 同98~107行
         mov eax,[edi+0x0c]                 ;核心代码段起始汇编地址
         mov ebx,[edi+0x00]                 ;程序总长度
         sub ebx,eax
         dec ebx                            ;核心代码段界限
         add eax,edi                        ;核心代码段基地址
         mov ecx,0x00409800                 ;字节粒度的代码段描述符
         call make_gdt_descriptor
         mov [esi+0x38],eax
         mov [esi+0x3c],edx

         mov word [0x7c00+pgdt],63          ;描述符表的界限 zhongshu-comment 在GDT中增加了3个描述符之后，修改GDT的长度为63字节，共8个描述符
                                        
         lgdt [0x7c00+pgdt]     ;zhongshu-comment 重新加载GDTR，使上面那些对GDT的修改生效。至此，c13_core.asm这个内核程序已经加载完毕。

         jmp far [edi+0x10]     ;zhongshu-comment 见67行代码可知edi是内核加载的起始物理内存地址，edi+0x10指向了c13_core.asm程序偏移0x10的那个字节，具体在c13_core.asm第28行
                                ;zhongshu-comment 这是一个间接远转移指令(参考P139 下)，需要读取[edi+0x10]处的6个字节，前4个字节是段内偏移地址，后2个字节是段选择子
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区
                                         ;EAX=逻辑扇区号
                                         ;DS:EBX=目标缓冲区地址
                                         ;返回：EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;读取的扇区数

         inc dx                          ;0x1f3
         pop eax
         out dx,al                       ;LBA地址7~0

         inc dx                          ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                       ;LBA地址15~8

         inc dx                          ;0x1f5
         shr eax,cl
         out dx,al                       ;LBA地址23~16

         inc dx                          ;0x1f6
         shr eax,cl
         or al,0xe0                      ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                     ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         ret

;----zhongshu-comment 195~217行 参考P227~228   ---------------------------------------------------------------------------
make_gdt_descriptor:                     ;构造描述符
                                         ;输入：EAX=线性基地址
                                         ;      EBX=段界限
                                         ;      ECX=属性（各属性位都在原始
                                         ;      位置，其它没用到的位置0） 
                                         ;返回：EDX:EAX=完整的描述符
         mov edx,eax    ;zhongshu-comment 201~203行 参考 P227 第4~5段
         shl eax,16                     
         or ax,bx                        ;描述符前32位(EAX)构造完毕 zhongshu-comment ebx寄存器存储了段界限的20位，bx寄存器存储了段界限的低16位，bx是ebx的低16位，剩下的4位在209~210行代码中解决
    ;zhongshu-comment 205~207行 参考 P227 第6段以及下面的配图，看配图大概就能看懂了
         and edx,0xffff0000              ;清除基地址中无关的位
         rol edx,8
         bswap edx                       ;装配基址的31~24和23~16  (80486+)
   ;zhongshu-comment 209~214行 参考 P228 3、4段
         xor bx,bx
         or edx,ebx                      ;装配段界限的高4位
      
         or edx,ecx                      ;装配属性 
      
         ret
      
;-------------------------------------------------------------------------------
         pgdt             dw 0
                          dd 0x00007e00      ;GDT的物理地址
;-------------------------------------------------------------------------------                             
         times 510-($-$$) db 0
                          db 0x55,0xaa