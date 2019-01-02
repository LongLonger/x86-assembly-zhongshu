         ;代码清单8-2
         ;文件名：c08.asm
         ;文件说明：用户程序 
         ;创建日期：2011-5-5 18:17
         ;zhongshu-comment 用户程序的入口在135行！！！！！！！！！！！！！！
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04] ;zhongshu-comment 这是一个段内汇编地址，该汇编地址是从code_1段开头开始计算的偏移量，而不是从整个程序的开头开始算的
                    dd section.code_1.start ;段地址[0x06] ;zhongshu-comment 这是一个段的汇编地址，他是从整个程序的开头开始计算的偏移量
    
    realloc_tbl_len dw (header_end - code_1_segment)/4
                                            ;段重定位表项个数[0x0a]
    
    ;段重定位表 ;zhongshu-comment 段重定位表位于两个标号code_1_segment和header_end之间。段重定位表即各个段的汇编地址的集合
    code_1_segment  dd section.code_1.start ;[0x0c] ;zhongshu-comment 段重定位表的第1个表项(或者说是第1条记录)
    code_2_segment  dd section.code_2.start ;[0x10] ;zhongshu-comment 段重定位表的第2个表项(或者说是第2条记录)
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c] ;zhongshu-comment 段重定位表的第5个表项(或者说是第5条记录)
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;定义代码段1（16字节对齐） 
put_string:                              ;显示串(0结尾)。;zhongshu-comment 参考P142 8.4.3。该过程接受两个参数DS和BX，分别是字符串所在的段地址和偏移地址
                                         ;输入：DS:BX=串地址
         mov cl,[bx]
         or cl,cl                        ;cl=0 ? ;zhongshu-comment 一个数和它自己做or运算，结果还是它自己，但及打算结果会影响标志寄存器中的某些位，如果zf置位(即zf位被赋值为1)，说明取到了字符串结束标志数字0(是数值0、不是字符0，并没有用引号包住的)，or运算的结果是0
         jz .exit                        ;是的，返回主程序 ;zhongshu-comment 当or运算结果为0，zf位就被置位1，jz判断就为true，将跳转到标号.exit处、执行ret指令结束过程调用、返回主程序
         call put_char  ;zhongshu-comment 上一行的jz判断为false，所以会执行该行指令。put_char改过程接受的参数在cl寄存器中
         inc bx                          ;下一个字符 
         jmp put_string ;zhongshu-comment 无条件转移指令

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符 ;zhongshu-comment put_char改过程接受的参数在cl寄存器中
                                         ;输入：cl=字符ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;以下取当前光标位置 zhongshu-comment 51~63行 参考P143 8.4.5 取当前光标的位置
         mov dx,0x3d4 ;zhongshu-comment 51~53行通过显卡的索引端口0x3d4告诉显卡，现在要操作0x0e号寄存器
         mov al,0x0e
         out dx,al  ;zhongshu-comment 显卡索引寄存器的端口号是0x3d4，该行指令是向0x3d4端口写入一个值:0x0e，表示要操作显卡里的0x0e这个寄存器
         mov dx,0x3d5 ;zhongshu-comment 0x3d5是显卡的数据端口，可以从该端口读取数据，读取的数据来自0x3d4索引端口指定的那个端口。也可以往该端口写数据，写的数据会写往0x3d4索引端口指定的那个端口
         in al,dx                        ;高8位  zhongshu-comment 通过数据端口0x3d5从0x0e号端口读取1字节的数据，并传送到al中
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 zhongshu-comment 从0x0f号端口读取1字节的数据
         mov bx,ax                       ;BX=代表光标位置的16位数 zhongshu-comment bx保存着光标的位置
    ;zhongshu-comment 65~78行 参考P144 8.4.6 处理回车和换行符
         cmp cl,0x0d                     ;回车符？zhongshu-comment 如果cl等于0x0d，即回车符的ASCII码，那么cmp执行结果是0，那么zf位就置为1，否则置为0
         jnz .put_0a                     ;不是回车符就跳转。看看是不是换行等字符 zhongshu-comment 当zf为0时就跳转，当cl不等于0x0d时zf才会置为0，即当cl不是回车符的ASCII码时就置为0、就会跳转
         mov ax,bx                       ;此句略显多余，但去掉后还得改书，麻烦 zhongshu-comment 当cl是回车符的ASCII码0x0d时会执行紧接下来的代码
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax  ;zhongshu-comment 上文一番计算之后，ax中得到了当前行行首的光标位置的数值，这里将ax中的内容保存到bx中
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是换行符就跳转，那就正常显示字符
         add bx,80   ;zhongshu-comment 是换行符就加80，因为在文本模式下，一行也就显示80个字符，加80就相当于将光标移动到相同列的下一行
         jmp .roll_screen
    ;zhongshu-comment 80~88行 参考P145 8.4.7 显示可打印字符
 .put_other:                             ;下面开始正常显示字符
         mov ax,0xb800  ;zhongshu-comment 将附加段寄存器ES设置为指向显存
         mov es,ax
         shl bx,1
         mov [es:bx],cl ;zhongshu-comment cl是外部传进来该过程的参数，将cl传送到显存以显示出来

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:  ;zhongshu-comment 94~101行 参考P145 8.4.8
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor ;zhongshu-comment 如果less小于2000，就跳转，如果大于等于2000就不跳转，执行紧接下来的代码

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840  ;102~107行代码的作用：清除屏幕最底一行 zhongshu-comment 102~107行 参考P146 第1段。
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920 ;zhongshu-comment 参考P146 第2段。 屏幕最后一行(即第25行)的第一列的第一个字符的位置是1920

 .set_cursor:   ;zhongshu-comment 112~123行 参考P146 8.4.9第2段
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

;-------------------------------------------------------------------------------
  start: ;zhongshu-comment 参考 [8.4.1 初始化段寄存器和栈切换] 用户程序的入口。因为加载器程序c08_mbr.asm已经完成了重定位工作，所以用户程序的头等大事是初始化处理器的各个段寄存器DS、ES、SS，以便访问专属于自己的数据。段寄存器CS就不用初始化了，那是加载器负责做的事，要不然用户程序怎么可能执行呢？
         ;zhongshu-comment 初始执行时，DS和ES指向用户程序头部段，头部段名字叫header。栈段寄存器SS依然指向加载器的栈空间，所以SS要重新改一下，使其指向本程序的栈段
         mov ax,[stack_segment]           ;设置到用户程序自己的堆栈。zhongshu-comment 137、138行 从头部取得用户程序自己的栈段的段地址，并传送到段寄存器SS
         mov ss,ax
         mov sp,stack_end   ;zhongshu-comment sp即stack pointer，栈段指针寄存器
         
         mov ax,[data_1_segment]          ;设置到用户程序自己的数据段 ;zhongshu-comment 参考P141 第2、3段，重要知识点：各个段寄存器的初始化顺序很重要。 此时ds指向的是header段，从header段取得数据段data_1的段地址，然后将data_1的段地址赋值给ds
         mov ds,ax  ;zhongshu-comment ds指向段data_1

         mov bx,msg0 ;zhongshu-comment 参考 P141 8.4.2 和 P142 8.4.3。
         call put_string                  ;显示第一段信息 

         push word [es:code_2_segment] ;zhongshu-comment 从头部段中获取code_2代码段的段地址，自进入用户程序之后，段寄存器ES一直是指向头部段header的
         mov ax,begin
         push ax                          ;可以直接push begin,80386+
         
         retf                             ;转移到代码段2执行 zhongshu-comment 当处理器执行指令retf时，会从栈中将偏移地址和段地址分别弹出到代码段寄存器CS和指令指针寄存器IP，浴室控制
         
  continue:
         mov ax,[es:data_2_segment]       ;段寄存器DS切换到数据段2 
         mov ds,ax
         
         mov bx,msg1
         call put_string                  ;显示第二段信息 

         jmp $ 

;===============================================================================
SECTION code_2 align=16 vstart=0          ;定义代码段2（16字节对齐）

  begin:
         push word [es:code_1_segment]
         mov ax,continue
         push ax                          ;可以直接push continue,80386+
         
         retf                             ;转移到代码段1接着执行 
         
;===============================================================================
SECTION data_1 align=16 vstart=0

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. '
         db '2011-05-06'
         db 0

;===============================================================================
SECTION stack align=16 vstart=0
           
         resb 256 ;zhongshu-comment resb是伪指令，保留256字节的栈空间。该段空间的汇编地址范围是0~255，所以标号stack_end处的汇编地址是256

stack_end:  ;zhongshu-comment 该标号应该是指向stack这个段的最高的那个地址，然后上文139行以stack_end作为sp，是因为栈的使用是从高地址往低地址的

;===============================================================================
SECTION trail align=16
program_end: