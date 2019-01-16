         ;代码清单13-2
         ;文件名：c13_core.asm
         ;文件说明：保护模式微型核心程序 
         ;创建日期：2011-10-26 12:11
    ;zhongshu-comment 7~30行，参考P222~223 13.2.1
         ;以下常量定义部分。内核的大部分内容都应当固定 
         core_code_seg_sel     equ  0x38    ;内核代码段选择子   ;zhongshu-comment 0011 1000，段描述符索引值是111B，即7(十进制)，GDT的第7个描述符(从0开始数)，具体可见P228 最下面的那幅图：图13-7 内核加载完成后的GDT布局
         core_data_seg_sel     equ  0x30    ;内核数据段选择子 
         sys_routine_seg_sel   equ  0x28    ;系统公共例程代码段的选择子 
         video_ram_seg_sel     equ  0x20    ;视频显示缓冲区的段选择子
         core_stack_seg_sel    equ  0x18    ;内核堆栈段选择子
         mem_0_4_gb_seg_sel    equ  0x08    ;整个0-4GB内存的段的选择子

;----zhongshu-comment 有时候，程序并不以段定义语句“SECTION 段名称”开始，在这种情况下，这些内容默认地自成一个段，直到出现了另一个段“SECTION 段名称”。本代码的16~29行就是默认地自成一段。参考P114 -------------------------------------------------------------------------
         ;以下是系统核心的头部，用于加载核心程序 zhongshu-comment 第7~12行只是声明常数，这几行代码不会占用任何一个字节，编译的时候会将下文中用到的常数变量替换为具体的数值，例如将core_code_seg_sel替换为0x38
         core_length      dd core_end       ;核心程序总长度#00

         sys_routine_seg  dd section.sys_routine.start  ;zhongshu-comment section.sys_routine.start是系统公用例程段的汇编地址，该汇编地址是相对于整个程序开头的偏移量，从0开始。“段的汇编地址”这个概念可参考P114
                                            ;系统公用例程段位置#04   zhongshu-comment 在c13_mbr.asm的99行直接用到0x04这个偏移量来取“section.sys_routine.start”这个数值

         core_data_seg    dd section.core_data.start
                                            ;核心数据段位置#08 zhongshu-comment 在c13_mbr.asm的110行直接用到0x08这个偏移量来取“section.core_data.start”这个数值

         core_code_seg    dd section.core_code.start
                                            ;核心代码段位置#0c zhongshu-comment 在c13_mbr.asm的121行直接用到0x0c这个偏移量来取“section.core_code.start”这个数值

        ;zhongshu-comment 这个核心代码段入口点在c13_mbr.asm的135行被使用
         core_entry       dd start          ;核心代码段入口点#10 zhongshu-comment start这个标号对应531行代码。start是代码段core_code的段内汇编地址，是相对代码段core_code开头的一个偏移量，将会传送到指令指针寄存器EIP
                          dw core_code_seg_sel  ;zhongshu-comment core_code_seg_sel是在第7行声明的一个常数，值是0x38。该常数是代码段core_code段描述符对应的选择子，会被传送到cs段寄存器，然后再到GDT中读出该选择子对应的段描述符到段寄存器的描述符高速缓存器中，core_code代码段的真正的段起始线性地址在描述符高速缓存器中

;===============================================================================
         [bits 32]
;===============================================================================
SECTION sys_routine vstart=0                ;系统公共例程代码段 
;-------------------------------------------------------------------------------
         ;字符串显示例程 zhongshu-comment 37~50行 参考P229 4、5段
put_string:                                 ;显示0终止的字符串并移动光标 
                                            ;输入：DS:EBX=串地址
         push ecx
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
         pop ecx
         retf                               ;段间返回 zhongshu-comment 过程返回时用了retf指令，而不是ret指令，这意味着必须以远过程调用的方式来调用该过程

;-------------------------------------------------------------------------------
put_char:                                   ;在当前光标处显示一个字符,并推进
                                            ;光标。仅用于段内调用 
                                            ;输入：CL=字符ASCII码 
         pushad

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;高字
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;低字
         mov bx,ax                          ;BX=代表光标位置的16位数

         cmp cl,0x0d                        ;回车符？
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;换行符？
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;正常显示字符
         push es
         mov eax,video_ram_seg_sel          ;0xb8000段的选择子
         mov es,eax
         shl bx,1
         mov [es:bx],cl
         pop es

         ;以下将光标位置推进一个字符
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;光标超出屏幕？滚屏
         jl .set_cursor

         push ds
         push es
         mov eax,video_ram_seg_sel
         mov ds,eax
         mov es,eax
         cld
         mov esi,0xa0                       ;小心！32位模式下movsb/w/d 
         mov edi,0x00                       ;使用的是esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;清除屏幕最底一行
         mov ecx,80                         ;32位程序应该使用ECX
  .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         pop es
         pop ds

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         ret                                

;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;从硬盘读取一个逻辑扇区
                                            ;EAX=逻辑扇区号
                                            ;DS:EBX=目标缓冲区地址
                                            ;返回：EBX=EBX+512
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;读取的扇区数

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA地址7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA地址15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA地址23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                        ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         retf                               ;段间返回 

;-------------------------------------------------------------------------------
;汇编语言程序是极难一次成功，而且调试非常困难。这个例程可以提供帮助 
put_hex_dword:                              ;在当前光标处以十六进制形式显示
                                            ;一个双字并推进光标 
                                            ;输入：EDX=要转换并显示的数字
                                            ;输出：无
         pushad
         push ds
      
         mov ax,core_data_seg_sel           ;切换到核心数据段 
         mov ds,ax
      
         mov ebx,bin_hex                    ;指向核心数据段内的转换表
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         pop ds
         popad
         retf
      
;---zhongshu-comment 232~260行代码 参考 P233 13.4.3 ----------------------------------------------------------------------------
allocate_memory:                            ;分配内存
                                            ;输入：ECX=希望分配的字节数
                                            ;输出：ECX=起始线性地址 
         push ds
         push eax
         push ebx
    ;zhongshu-comment 239~247行 参考 P234 第2段
         mov eax,core_data_seg_sel  ;zhongshu-comment 先使段寄存器ds指向内核数据段以访问标号ram_alloc所指向的内存单元，见P242行代码
         mov ds,eax
      
         mov eax,[ram_alloc]
         add eax,ecx                        ;下一次分配时的起始地址
      
         ;这里应当有检测可用内存数量的指令 zhongshu-comment 但是本过程没有实现这个逻辑
          
         mov ecx,[ram_alloc]                ;返回分配的起始地址  zhongshu-comment 当过程返回时，ECX寄存器包含了所分配内存的起始物理地址

         mov ebx,eax
         and ebx,0xfffffffc     ;zhongshu-comment c等于1100B，执行and运算后，就将ebx最低两位强制为0，这就导致ebx的值小于等于原来的值了(原来的值的最低两位可能本来就是0)
         add ebx,4                          ;强制对齐 zhongshu-comment 4等于0100B，在250行可能将最大的11B强制为0，11B等于3，然后251行加上4，所以强制对齐之后的值肯定比原来的大
         test eax,0x00000003                ;下次分配的起始地址最好是4字节对齐 zhongshu-comment 0x3等于0011，如果eax的最低两位为0，则test指令的结果是0，则zf为1，则不会执行253行代码。意思就是eax自己本来就是4字节对齐的，无需执行253行代码：即无需使用强制对齐之后的ebx的值
         cmovnz eax,ebx                     ;如果没有对齐，则强制对齐 
         mov [ram_alloc],eax                ;下次从该地址分配内存 zhongshu-comment 将eax写回标号ram_alloc处，作为下次内存分配的起始地址
                                            ;cmovcc指令可以避免控制转移 
         pop ebx
         pop eax
         pop ds

         retf

;-------------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;在GDT内安装一个新的描述符
                                            ;输入：EDX:EAX=描述符 
                                            ;输出：CX=描述符的选择子
         push eax
         push ebx
         push edx
      
         push ds
         push es
      
         mov ebx,core_data_seg_sel          ;切换到核心数据段
         mov ds,ebx

         sgdt [pgdt]                        ;以便开始处理GDT zhongshu-comment 参考P235第4段

         mov ebx,mem_0_4_gb_seg_sel     ;zhongshu-comment 将es指向4GB测内存段以操作全局描述符表GDT
         mov es,ebx

         movzx ebx,word [pgdt]              ;GDT界限 
         inc bx                             ;GDT总字节数，也是下一个描述符偏移 
         add ebx,[pgdt+2]                   ;下一个描述符的线性地址 zhongshu-comment [pgdt+2]指向的那4个字节的内存单元存储的是GDT的起始线性地址，该加法指令执行后，ebx中得到的就是新描述符的起始线性地址
      
         mov [es:ebx],eax
         mov [es:ebx+4],edx
      
         add word [pgdt],8                  ;增加一个描述符的大小   
      
         lgdt [pgdt]                        ;对GDT的更改生效 
    ;zhongshu-comment 292~297行，参考 P237 第2段。作用：给上文刚刚安装的段描述符生成对应的段选择子，保存到cx中
         mov ax,[pgdt]                      ;得到GDT界限值
         xor dx,dx
         mov bx,8
         div bx                             ;除以8，去掉余数
         mov cx,ax                          
         shl cx,3                           ;将索引号移到正确位置 

         pop es
         pop ds

         pop edx
         pop ebx
         pop eax
      
         retf 
;-------------------------------------------------------------------------------
make_seg_descriptor:                        ;构造存储器和系统的段描述符
                                            ;输入：EAX=线性基地址
                                            ;      EBX=段界限
                                            ;      ECX=属性。各属性位都在原始
                                            ;          位置，无关的位清零 
                                            ;返回：EDX:EAX=描述符
         mov edx,eax
         shl eax,16
         or ax,bx                           ;描述符前32位(EAX)构造完毕

         and edx,0xffff0000                 ;清除基地址中无关的位
         rol edx,8
         bswap edx                          ;装配基址的31~24和23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;装配段界限的高4位

         or edx,ecx                         ;装配属性

         retf

;===============================================================================
SECTION core_data vstart=0                  ;系统核心的数据段
;-------------------------------------------------------------------------------
         pgdt             dw  0             ;用于设置和修改GDT zhongshu-comment 参考P235 6段
                          dd  0

         ram_alloc        dd  0x00100000    ;下次分配内存时的起始地址

         ;符号地址检索表
         salt:
         salt_1           db  '@PrintString'
                     times 256-($-salt_1) db 0
                          dd  put_string
                          dw  sys_routine_seg_sel

         salt_2           db  '@ReadDiskData'
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0
                          dw  sys_routine_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  sys_routine_seg_sel

         salt_4           db  '@TerminateProgram'
                     times 256-($-salt_4) db 0
                          dd  return_point
                          dw  core_code_seg_sel

         salt_item_len   equ $-salt_4
         salt_items      equ ($-salt)/salt_item_len

         message_1        db  '  If you seen this message,that means we '
                          db  'are now in protect mode,and the system '
                          db  'core is loaded,and the video display '
                          db  'routine works perfectly.',0x0d,0x0a,0

         message_5        db  '  Loading user program...',0
         
         do_status        db  'Done.',0x0d,0x0a,0
         
         message_6        db  0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
                          db  '  User program terminated,control returned.',0

         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword子过程用的查找表 
         core_buf   times 2048 db 0         ;内核用的缓冲区

         esp_pointer      dd 0              ;内核用来临时保存自己的栈指针     

         cpu_brnd0        db 0x0d,0x0a,'  ',0   ;zhongshu-comment 0x0a是换行符，0x0d是回车符。最后的那个0忘了是啥意思了，貌似是字符串结束的标志？那为什么需要这个标志呢？？
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

;===============================================================================
SECTION core_code vstart=0
;-------------------------------------------------------------------------------
load_relocate_program:                      ;加载并重定位用户程序 zhongshu-comment c13_core.asm这个程序中最重要的就是这部分代码了，也是最长的一部分
                                            ;输入：ESI=起始逻辑扇区号
                                            ;返回：AX=指向用户程序头部的选择子 
         push ebx
         push ecx
         push edx
         push esi
         push edi
      
         push ds
         push es
    ;zhongshu-comment 399~404行 参考 P232 13.4.2
         mov eax,core_data_seg_sel
         mov ds,eax                         ;切换DS到内核数据段
       
         mov eax,esi                        ;读取程序头部数据 zhongshu-comment eax里的内容是用户程序的起始逻辑扇区号
         mov ebx,core_buf   ;zhongshu-comment 读出来的数据放到标号core_buff处，一般取名做内核缓冲区(其实就是一段内存区域而已)，该内核缓冲区位于内核数据段中，是在第376行声明和初始化的
         call sys_routine_seg_sel:read_hard_disk_0

         ;以下判断整个程序有多大
         mov eax,[core_buf]                 ;程序尺寸 zhongshu-comment eax里的内容是用户程序的总字节数。用户程序的总字节数就在程序开头偏移为0x00的地方(是一个双字，共4字节)，404行代码读取出来后，保存在core_buff缓冲区的首字节处
         mov ebx,eax
         and ebx,0xfffffe00                 ;使之512字节对齐（能被512整除的数， 
         add ebx,512                        ;低9位都为0 
         test eax,0x000001ff                ;程序的大小正好是512的倍数吗?  zhongshu-comment 如果程序的大小不是512字节的倍数，那么eax的低9位不全为0，那么test的执行结果不为0，所以zf为0，就会执行412行的指令
         cmovnz eax,ebx                     ;不是。使用凑整的结果 zhongshu-comment 如果程序的大小刚好是512字节的倍数，那么test执行结果为0，则zf为1，就不会执行412行代码了，那么eax就使用408行的原值了
    ;zhongshu-comment 从414~474行，参考P234 13.4.4 段的重定位和描述符的创建
         mov ecx,eax                        ;实际需要申请的内存数量 zhongshu-comment question 在程序大小不是512的倍数时，eax会将那些余数凑整，使变为512的倍数，假如程序实际上是513字节，但是凑整后就变为1024字节，后面的那511字节都是多余的
         call sys_routine_seg_sel:allocate_memory   ;zhongshu-comment 分配到手的内存块的起始物理地址在ECX中
         mov ebx,ecx                        ;ebx -> 申请到的内存首地址
         push ebx                           ;保存该首地址 zhongshu-comment 其目的是用于在后面访问用户程序头部
         xor edx,edx    ;zhongshu-comment 用户程序的总字节数在eax中，用edx:eax除以512，得到该程序在磁盘占用的扇区数，除法的商在eax中，商就是占用的扇区数
         mov ecx,512
         div ecx
         mov ecx,eax                        ;总扇区数   zhongshu-comment 除法的商在eax中，商就是占用的扇区数
      
         mov eax,mem_0_4_gb_seg_sel         ;切换DS到0-4GB的段 zhongshu-comment 使使段寄存器DS指向4GB的内存段，这样就可以加载用户程序了
         mov ds,eax
    ;zhongshu-comment 426~430行，循环读取硬盘以加载用户程序，循环次数由ECX控制，ebx中指定了程序要加载到的内存起始物理地址
         mov eax,esi                        ;起始扇区号 
  .b1:
         call sys_routine_seg_sel:read_hard_disk_0
         inc eax
         loop .b1                           ;循环读，直到读完整个用户程序

         ;建立程序头部段描述符    zhongshu-comment 上文将程序从硬盘读入内存后，接下来就是根据用户程序的头部信息来创建该程序的段描述符了
         pop edi                            ;恢复程序装载的首地址  zhongshu-comment 这是在417行压入的
         mov eax,edi                        ;程序头部起始线性地址
         mov ebx,[edi+0x04]                 ;段长度
         dec ebx                            ;段界限 
         mov ecx,0x00409200                 ;字节粒度的数据段描述符
         call sys_routine_seg_sel:make_seg_descriptor   ;zhongshu-comment 过程返回后，EDX:EAX中包含了64位的段描述符
         call sys_routine_seg_sel:set_up_gdt_descriptor ;zhongshu-comment 把438行得到的段描述符安装到GDT中。set_up_gdt_descriptor该过程需要通过EDX:EAX传入段描述符作为唯一的参数，返回时，CX中包含了那个描述符的选择子
         mov [edi+0x04],cx  ;zhongshu-comment 重要 参考 P237 第5段。将该段的选择子协会到用户程序头部，供用户程序在接管处理器控制权之后使用，实际上，在内核向用户程序转交控制权时也要用到，因为程序的入口地址在用户程序的头部

         ;建立程序代码段描述符    zhongshu-comment 443~460行 和433~440差不多
         mov eax,edi
         add eax,[edi+0x14]                 ;代码起始线性地址
         mov ebx,[edi+0x18]                 ;段长度
         dec ebx                            ;段界限
         mov ecx,0x00409800                 ;字节粒度的代码段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x14],cx

         ;建立程序数据段描述符
         mov eax,edi
         add eax,[edi+0x1c]                 ;数据段起始线性地址
         mov ebx,[edi+0x20]                 ;段长度
         dec ebx                            ;段界限
         mov ecx,0x00409200                 ;字节粒度的数据段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x1c],cx

         ;建立程序堆栈段描述符 zhongshu-comment 463~474行，参考P237 第7段~P238顶部。这是一个关于“32位保护模式下栈段的初始化”很好的例子
         mov ecx,[edi+0x0c]                 ;4KB的倍率 
         mov ebx,0x000fffff
         sub ebx,ecx                        ;得到段界限
         mov eax,4096                        
         mul dword [edi+0x0c]                         
         mov ecx,eax                        ;准备为堆栈分配内存 
         call sys_routine_seg_sel:allocate_memory
         add eax,ecx                        ;得到堆栈的高端物理地址 
         mov ecx,0x00c09600                 ;4KB粒度的堆栈段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x08],cx
    ;zhongshu-comment 476~ ，参考P238 13.4.5 重定位用户程序内的符号地址
         ;重定位SALT
         mov eax,[edi+0x04]
         mov es,eax                         ;es -> 用户程序头部 
         mov eax,core_data_seg_sel
         mov ds,eax
      
         cld

         mov ecx,[es:0x24]                  ;用户程序的SALT条目数
         mov edi,0x28                       ;用户程序内的SALT位于头部内0x2c处
  .b2: 
         push ecx
         push edi
      
         mov ecx,salt_items
         mov esi,salt
  .b3:
         push edi
         push esi
         push ecx

         mov ecx,64                         ;检索表中，每条目的比较次数 
         repe cmpsd                         ;每次比较4字节 
         jnz .b4
         mov eax,[esi]                      ;若匹配，esi恰好指向其后的地址数据
         mov [es:edi-256],eax               ;将字符串改写成偏移地址 
         mov ax,[esi+4]
         mov [es:edi-252],ax                ;以及段选择子 
  .b4:
      
         pop ecx
         pop esi
         add esi,salt_item_len
         pop edi                            ;从头比较 
         loop .b3
      
         pop edi
         add edi,256
         pop ecx
         loop .b2

         mov ax,[es:0x04]

         pop es                             ;恢复到调用此过程前的es段 
         pop ds                             ;恢复到调用此过程前的ds段
      
         pop edi
         pop esi
         pop edx
         pop ecx
         pop ebx
      
         ret
      
;-------------------------------------------------------------------------------
start:  ;zhongshu-comment 532~565行 参考P229 13.3 在内核中执行
         mov ecx,core_data_seg_sel           ;使ds指向核心数据段 zhongshu-comment core_data_seg_sel是内核数据段选择子
         mov ds,ecx

         mov ebx,message_1  ;zhongshu-comment put_string这个过程需要用到输入参数在DS和EBX中
         call sys_routine_seg_sel:put_string    ;zhongshu-comment 直接远转移指令，直接在指令中给出段选择子和段内偏移量。
                                         
         ;显示处理器品牌信息 zhongshu-comment cpuid指令返回的cpu信息保存到[ds:cpu_brand]处
         mov eax,0x80000002
         cpuid
         mov [cpu_brand + 0x00],eax
         mov [cpu_brand + 0x04],ebx
         mov [cpu_brand + 0x08],ecx
         mov [cpu_brand + 0x0c],edx
      
         mov eax,0x80000003
         cpuid
         mov [cpu_brand + 0x10],eax
         mov [cpu_brand + 0x14],ebx
         mov [cpu_brand + 0x18],ecx
         mov [cpu_brand + 0x1c],edx

         mov eax,0x80000004
         cpuid
         mov [cpu_brand + 0x20],eax
         mov [cpu_brand + 0x24],ebx
         mov [cpu_brand + 0x28],ecx
         mov [cpu_brand + 0x2c],edx

         mov ebx,cpu_brnd0
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brand
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brnd1
         call sys_routine_seg_sel:put_string

         mov ebx,message_5
         call sys_routine_seg_sel:put_string
         mov esi,50                          ;用户程序位于逻辑50扇区 zhongshu-comment 指定用户程序在磁盘的起始逻辑扇区号
         call load_relocate_program     ;zhongshu-comment 该过程的作用是：加载和重定位用户程序。该过程在387行，在同一个代码段core_code中。
      
         mov ebx,do_status
         call sys_routine_seg_sel:put_string
      
         mov [esp_pointer],esp               ;临时保存堆栈指针
       
         mov ds,ax
      
         jmp far [0x10]                      ;控制权交给用户程序（入口点）
                                             ;堆栈可能切换 

return_point:                                ;用户程序返回点
         mov eax,core_data_seg_sel           ;使ds指向核心数据段
         mov ds,eax

         mov eax,core_stack_seg_sel          ;切换回内核自己的堆栈
         mov ss,eax 
         mov esp,[esp_pointer]

         mov ebx,message_6
         call sys_routine_seg_sel:put_string

         ;这里可以放置清除用户程序各种描述符的指令
         ;也可以加载并启动其它程序
       
         hlt
            
;===============================================================================
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: