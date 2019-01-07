         ;代码清单9-1
         ;文件名：c09_1.asm
         ;文件说明：用户程序
         ;创建日期：2011-4-16 22:03

;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段
    program_length  dd program_end          ;程序总长度[0x00]

    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04] ;zhongshu-comment 在119行
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
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es

  .w0:
      mov al,0x0a                        ;阻断NMI。当然，通常是不必要的
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读寄存器A
      test al,0x80                       ;测试第7位UIP
      jnz .w0                            ;以上代码对于更新周期结束中断来说
                                         ;是不必要的
      xor al,al
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(秒)
      push ax

      mov al,2
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(分)
      push ax

      mov al,4
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(时)
      push ax

      mov al,0x0c                        ;寄存器C的索引。且开放NMI
      out 0x70,al
      in al,0x71                         ;读一下RTC的寄存器C，否则只发生一次中断
                                         ;此处不考虑闹钟和周期性中断的情况
      mov ax,0xb800
      mov es,ax

      pop ax
      call bcd_to_ascii
      mov bx,12*160 + 36*2               ;从屏幕上的12行36列开始显示

      mov [es:bx],ah
      mov [es:bx+2],al                   ;显示两位小时数字

      mov al,':'
      mov [es:bx+4],al                   ;显示分隔符':'
      not byte [es:bx+5]                 ;反转显示属性

      pop ax
      call bcd_to_ascii
      mov [es:bx+6],ah
      mov [es:bx+8],al                   ;显示两位分钟数字

      mov al,':'
      mov [es:bx+10],al                  ;显示分隔符':'
      not byte [es:bx+11]                ;反转显示属性

      pop ax
      call bcd_to_ascii
      mov [es:bx+12],ah
      mov [es:bx+14],al                  ;显示两位小时数字

      mov al,0x20                        ;中断结束命令EOI
      out 0xa0,al                        ;向从片发送
      out 0x20,al                        ;向主片发送

      pop es
      pop dx
      pop cx
      pop bx
      pop ax

      iret

;-------------------------------------------------------------------------------
bcd_to_ascii:                            ;BCD码转ASCII
                                         ;输入：AL=bcd码
                                         ;输出：AX=ascii
      mov ah,al                          ;分拆成两个数字
      and al,0x0f                        ;仅保留低4位
      add al,0x30                        ;转换成ASCII

      shr ah,4                           ;逻辑右移4位
      and ah,0x0f
      add ah,0x30

      ret

;-------------------------------------------------------------------------------
start: ;zhongshu-comment 119~124行 参考 [P157 倒数第二段] [8.4.1 初始化段寄存器和栈切换] 用户程序的入口。因为加载器程序c08_mbr.asm已经完成了重定位工作，所以用户程序的头等大事是初始化处理器的各个段寄存器DS、ES、SS，以便访问专属于自己的数据。段寄存器CS就不用初始化了，那是加载器负责做的事，要不然用户程序怎么可能执行呢？
      mov ax,[stack_segment] ;zhongshu-comment 初始执行时，DS和ES指向用户程序头部段，头部段名字叫header。栈段寄存器SS依然指向加载器的栈空间，所以SS要重新改一下，使其指向本程序的栈段
      mov ss,ax
      mov sp,ss_pointer
      mov ax,[data_segment]
      mov ds,ax
    ;zhongshu-comment 126~130 将数据段里的字符串显示出来
      mov bx,init_msg                    ;显示初始信息
      call put_string

      mov bx,inst_msg                    ;显示安装信息
      call put_string
    ;zhongshu-comment 131~135行 参考P158 中段。为了修改0x70号中断对应的中断处理程序在中断向量表(IVT)中的入口点(即段地址:偏移地址)，需要先找到0x70中断处理程序入口点在IVT内的偏移量
      mov al,0x70
      mov bl,4
      mul bl                             ;计算0x70号中断在IVT中的偏移 zhongshu-comment 8位的通用寄存器或者内存单元中的数和寄存器AL中的内容相乘，结果是16位，保存在AX寄存器中
      mov bx,ax

      cli                                ;防止改动期间发生新的0x70号中断 zhongshu-comment 防止发生这样的情况：当0x70中断处理程序的入口点信息只修改了一部分时，如果这时候发生了0x70号中断，就会执行一个非预期的中断处理程序，因为入口点信息只修改了一部分。
    ;zhongshu-comment 139~145行 参考P158 中下
      push es
      mov ax,0x0000
      mov es,ax     ;zhongshu-comment 使es段寄存器指向中断向量表所在的段
      mov word [es:bx],new_int_0x70      ;偏移地址。 ;zhongshu-comment 0x70中断处理程序入口点在IVT内的偏移量在131~135行时已经计算出来了，计算的结果保存在bx中

      mov word [es:bx+2],cs              ;段地址
      pop es
    ;zhongshu-comment 接下来，设置RTC（实时时钟）的参数和工作状态，使它能够产生中断信号给8259中断控制器
      mov al,0x0b                        ;RTC寄存器B
      or al,0x80                         ;阻断NMI zhongshu-comment 0x80即1000 0000，or运算后，al的最高位一定是1。CMOS RAM的0x70端口的最高位为1，则阻断所有的NMI中断信号到达处理器
      out 0x70,al   ;zhongshu-comment 要操作0x0b这个存储单元，因为CMOS RAM只有128字节，所以只需要0x70端口的0~6bit位就能访问整个CMOS RAM了，所以即使执行了148行的代码，当前行的语义依然是：访问0x0b这个存储单元
      mov al,0x12                        ;设置寄存器B，禁止周期性中断，开放更新结束中断，BCD码，24小时制
      out 0x71,al                        ;zhongshu-comment 通过0x71数据端口往0x0b存储单元(又称寄存器B)写数据，写的内功是0x12，即0001 0010，参照表9-3可知：

      mov al,0x0c
      out 0x70,al
      in al,0x71                         ;读RTC寄存器C，复位未决的中断状态

      in al,0xa1                         ;读8259从片的IMR寄存器
      and al,0xfe                        ;清除bit 0(此位连接RTC)
      out 0xa1,al                        ;写回此寄存器

      sti                                ;重新开放中断

      mov bx,done_msg                    ;显示安装完成信息
      call put_string

      mov bx,tips_msg                    ;显示提示信息
      call put_string

      mov cx,0xb800
      mov ds,cx
      mov byte [12*160 + 33*2],'@'       ;屏幕第12行，35列

 .idle:
      hlt                                ;使CPU进入低功耗状态，直到用中断唤醒
      not byte [12*160 + 33*2+1]         ;反转显示属性
      jmp .idle

;-------------------------------------------------------------------------------
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
         mov cl,[bx]
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;是的，返回主程序
         call put_char
         inc bx                          ;下一个字符
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符
                                         ;输入：cl=字符ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符
         mov ax,bx                       ;
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al

         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;===============================================================================
SECTION data align=16 vstart=0

    init_msg       db 'Starting...',0x0d,0x0a,0

    inst_msg       db 'Installing a new interrupt 70H...',0

    done_msg       db 'Done.',0x0d,0x0a,0

    tips_msg       db 'Clock is now working.',0

;===============================================================================
SECTION stack align=16 vstart=0

                 resb 256
ss_pointer:

;===============================================================================
SECTION program_trail
program_end: