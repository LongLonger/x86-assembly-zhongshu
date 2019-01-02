         ;代码清单8-1
         ;文件名：c08_mbr.asm
         ;文件说明：硬盘主引导扇区代码（加载程序） 
         ;创建日期：2011-5-5 18:17
         
         app_lba_start equ 100           ;声明常数（用户程序起始逻辑扇区号）
                                         ;常数的声明不会占用汇编地址
                                    
SECTION mbr align=16 vstart=0x7c00 ;zhongshu-comment 段内所有的汇编地址都将从0x7c00开始计算

         ;设置堆栈段和栈指针 
         mov ax,0      
         mov ss,ax
         mov sp,ax
        ;zhongshu-comment 参考P121 中部。使用cs作为段基址，之所以没有使用DS和ES，是因为他们另有安排，见20行
         mov ax,[cs:phy_base]            ;计算用于加载用户程序的逻辑段地址  ;zhongshu-comment 段寄存器cs的内容是0x0000，当ROM-bios读取主引导扇区的程序到0x7c000之后，就执行jmp 0x0000:0x7c000，所以现在cs的值就是0x0000
         mov dx,[cs:phy_base+0x02]      ;zhongshu-comment 因为8086处理器的地址是20位的，所以要用ax、dx两个寄存器才能装得下，低16位在ax，高16位在dx，实际上dx中只有低4位是我们需要的
         mov bx,16
         div bx         ;zhongshu-comment 参考P122 上面。这是32位的除法运算，32位除以16位寄存器，被除数在dx:ax，除数在bx，得到的商保存在ax、余数在dx。该次除法是为了将物理地址除以16、得到该物理地址对应的段地址，除以16就相当于是右移四位，从20位变为16位
         mov ds,ax                       ;令DS和ES指向该段以进行操作 zhongshu-comment 商保存在寄存器AX。保存的值是0x1000，用户程序c08.asm被加载到0x10000，0x10000右移四位得到逻辑段地址0x1000，所以ds保存的是用户程序的段地址
         mov es,ax                        

         ;以下读取程序的起始部分 zhongshu-comment line24~27 P128 倒数第3段，P129 顺数6~9段。 读取硬盘上app_lba_start这个扇区的内容，该扇区是用户程序c08.asm在硬盘上的起始逻辑扇区
         xor di,di  ;zhongshu-comment 将di清零。我们定义的过程是使用di:si来将28位的起始逻辑扇区号传到过程中。因为app_lba_start的值是100，不会到达高16位，所以直接清零
         mov si,app_lba_start            ;程序在硬盘上的起始逻辑扇区号 zhongshu-comment 起始逻辑扇区号占28位，
         xor bx,bx                       ;加载到DS:0x0000处 
         call read_hard_disk_0
         ;zhongshu-comment line29~55 参考P133~134
         ;以下判断整个程序有多大 ;zhongshu-comment ①用户程序最开始的4个字节存储了整个c08.asm程序的大小，单位是字节. ②将这4个字节的高16位传送到dx，低16位传送到ax. ③然后用dx:ax 除以 bx，bx的值是512字节，一个扇区的大小就是512字节，所以除法得到的商是c08.asm程序占用了多少个扇区
         mov dx,[2]                      ;曾经把dx写成了ds，花了二十分钟排错 zhongshu-comment 因为line24~27行的代码将用户程序c08.asm加载到内存[ds:bx]处，bx是从0开始的，即加载到[ds:0x0000]处。所以这里这条指令mov dx,[2]就是读取用户程序c08的第2、3字节
         mov ax,[0]                      ;zhongshu-comment 读取用户程序c08的第0、1字节
         mov bx,512                      ;512字节每扇区
         div bx
         cmp dx,0   ;zhongshu-comment ①如果该指令的结果为0，则表明刚刚的那个除法没有余数；②cmp指令结果为0，那么zf为置为1；③zf为1，那么jnz指令不跳转、执行紧跟着的代码；当zf为0，jnz指令才会跳转
         jnz @1                          ;未除尽，因此结果比实际扇区数少1 
         dec ax                          ;已经读了一个扇区，扇区总数减1 zhongshu-comment 当cmp结果为0，代表除尽了，jnz不跳转，执行36行：总扇区数减一。因为line24~27已经加载了第一个扇区的内容了，而商ax是整个程序的扇区数，所以要减一
   @1:
         cmp ax,0                        ;考虑实际长度小于等于512个字节的情况 zhongshu-comment 当商ax为0时，意味着整个c08.asm程序的大小是小于等于512字节，只占用一个扇区，但是line24~27已经读取了第一个扇区的内容了，已经读完了，没必要继续读取了
         jz direct  ;zhongshu-comment 商ax为0就跳转，跳到别的代码处，因为从硬盘读取程序这个步骤就完事了，解释见38行
         
         ;读取剩余的扇区
         push ds                         ;以下要用到并改变DS寄存器 zhongshu-comment 这里push，在55行pop出来

         mov cx,ax                       ;循环次数（剩余扇区数）zhongshu-comment 参考 P134 上面。将用户程序剩余的扇区数传送到寄存器CX，供后面的loop指令使用
   @2:
         mov ax,ds
         add ax,0x20                     ;得到下一个以512字节为边界的段地址
         mov ds,ax  
                              
         xor bx,bx                       ;每次读时，偏移地址始终为0x0000 
         inc si                          ;下一个逻辑扇区 zhongshu-comment si的值是101、102、103......
         call read_hard_disk_0
         loop @2                         ;循环读，直到读完整个功能程序 zhongshu-comment 该循环内的逻辑 参考 P134 上面

         pop ds                          ;恢复数据段基址到用户程序头部段 zhongshu-comment 将42行push的数据pop出来
      
         ;计算入口点代码段基址 zhongshu-comment line58~74 参考P134~137
   direct:
         mov dx,[0x08]  ;zhongshu-comment line58~62 参考P134 倒数第5段；P134 8.3.8的顺数第二段。默认使用了段地址ds，ds的值见16~20行
         mov ax,[0x06]  ;zhongshu-comment 参考 P134 8.3.8的顺数第二段。 59、60行执行后，dx:ax寄存器保存的是32位的“段的汇编地址”，即c08.asm 第12行的：dd section.code_1.start。现在要将dx:ax这个段的汇编地址传入到过程calc_segment_base中，计算出该段的汇编地址对应的真实物理段地址
         call calc_segment_base
         mov [0x06],ax                   ;回填修正后的入口点代码段基址 zhongshu-comment 默认使用了段地址ds，ds的值见16~20行。将刚刚计算出来的逻辑段地址写回到原处，即0x06处，因为逻辑段地址只有16位，所以只写0x06即可，不需要写0x08了
;zhongshu-comment 65~74行 参考 P137 倒数3~6段。
;开始处理段重定位表 zhongshu-comment 59~62行仅仅是处理了入口点代码段的重定位，下面65~75行开始正式处理用户程序的所有代码段，它们位于用户程序头部的段重定位表中
         mov cx,[0x0a]                   ;需要重定位的项目数量 ;zhongshu-comment 段重定位表的表项数存放在用户程序头部偏移0x0a处。循环cx次
         mov bx,0x0c                     ;重定位表首地址 ;zhongshu-comment 段重定位表的首地址存放在用户程序头部偏移0x0c处
          
 realloc:
         mov dx,[bx+0x02]                ;32位地址的高16位 
         mov ax,[bx]
         call calc_segment_base
         mov [bx],ax                     ;回填段的基址
         add bx,4                        ;下一个重定位项（每项占4个字节） 
         loop realloc 
      ;zhongshu-comment 76行代码是c08_mbr.asm程序执行的最后一行代码
         jmp far [0x04]                  ;转移到用户程序 zhongshu-comment [P138 8.3.9] 通过一个16位的间接绝对远转移指令，跳转到用户程序入口点。处理器执行该指令时：会访问段寄存器DS所指向的数据段，从偏移地址为0x04的地方取出2个字，并分别传送到代码段寄存器CS和指令指针寄存器IP，以替代他们原先的内容，该CS:IP指向了用户程序，于是处理器就去执行用户程序了
                                         ;zhongshu-comment 入口点是两个连续的字，低字是偏移地址，位于用户程序c08.asm头部段内偏移为0x04的地方，高字是段地址，位于用户程序头部内偏移为0x06的地方，而且因为加载器程序c08_mbr.asm的58~74行代码的辛勤工作，用户程序段的汇编地址是已经重定位为真实内存里的物理段地址了。
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区 zhongshu-comment 该过程有两个参数：每次读硬盘时的起始逻辑扇区号 和 读取出来的数据存储在哪。由于该过程每次只读取一个扇区，所以不需要通过传参的方式指定要读取的扇区数
                                         ;输入：DI:SI=起始逻辑扇区号
                                         ;      DS:BX=目标缓冲区地址 zhongshu-comment 从硬盘读取出来的数据存储到DS:BX所指向的内存位置
         push ax
         push bx
         push cx
         push dx
         ;zhongshu-comment line87~89 参考P126 第1步 设置要读取的扇区数。
         mov dx,0x1f2   ;zhongshu-comment 0x1f2是硬盘的端口，可以通过该端口指定要读取的扇区数
         mov al,1       ;zhongshu-comment 要读取1个扇区
         out dx,al                       ;读取的扇区数 zhongshu-comment 该过程每次只读取一个扇区，所以不需要通过传参的方式指定要读取的扇区数
         ; zhongshu-comment line91~106 参考P126 第2步 设置起始逻辑扇区号。 用于向硬盘接口写入起始逻辑扇区号，是一个28位的数字。通过寄存器传参，在调用该过程之前先将这28位的数字放到DI:SI寄存器中，低16位在寄存器SI中，高12位在寄存器DI中，然后会将DI:SI的低28位传到硬盘接口里的端口，
         inc dx                          ;0x1f3 zhongshu-comment 0x1f3是硬盘端口号，用于指定要读取的起始扇区号，28 位的扇区号太长，需要将其分成 4 段，分别写入端口 0x1f3、0x1f4、0x1f5 和 0x1f6 号端口。其中，0x1f3 号端口存放的是 0～7 位；0x1f4 号端口存放的是 8～15 位；0x1f5 号端口存放的是 16～23 位，最后 4 位在 0x1f6 号端口
         mov ax,si                       ; LBA28模式下，用28位的二进制数表示扇区号。高16位保存在寄存器DI中(只有低12位有效，高4位必须保证为0)。低16位存放在寄存器SI
         out dx,al                       ;LBA地址7~0

         inc dx                          ;0x1f4
         mov al,ah
         out dx,al                       ;LBA地址15~8

         inc dx                          ;0x1f5
         mov ax,di                       ; zhongshu-comment di的高4位是0000
         out dx,al                       ;LBA地址23~16
        ;zhongshu-comment P126 倒数第2段 下面的or运算是用来保证0x1f6这个端口的高四位一定是1110，至于低四位是以ah的的低四位为准。因为or运算是有1则1，全0为0，al的低四位是0，那or运算后并不会改变ah的低四位。
         inc dx                          ;0x1f6
         mov al,0xe0                     ;LBA28模式，主盘 zhongshu-comment 0xe0即1110 0000
         or al,ah                        ;LBA地址27~24 zhongshu-comment or运算：al=1110 0000，ah=0000 xxxx，结果：1110 xxxx
         out dx,al
        ;zhongshu-comment line108~110 P126 第3步 向端口0x1f7写入0x20，代表要读硬盘。
         inc dx                          ;0x1f7
         mov al,0x20                     ;读命令 zhongshu-comment 0x20应该是读操作的意思
         out dx,al
    ;zhongshu-comment line112~116 P127 第4步 等待硬盘准备就绪，当硬盘准备就绪后，就可以往硬盘读或写数据了，在这个例子中是读数据。
  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;不忙，且硬盘已准备好数据传输 
    ;zhongshu-comment line118~124行 P127 第5步 连续取出数据。 用于反复从硬盘接口那里取得512字节的数据，并传送到段寄存器DS所指向的数据段，没传送一个字，bx就加2，以指向下一个保存位置
         mov cx,256                      ;总共要读取的字数 zhongshu-comment cx寄存器保存了循环的次数
         mov dx,0x1f0   ;zhongshu-comment 0x1f0是硬盘的数据端口，用来读写数据的
  .readw:
         in ax,dx   ;zhongshu-comment 从硬盘的数据端口0x1f0读取2个字节，然后保存到16位寄存器ax中
         mov [bx],ax
         add bx,2
         loop .readw
    ;zhongshu-comment 126~129行，用于把调用过程前各个寄存器的内容从栈中恢复
         pop dx
         pop cx
         pop bx
         pop ax ; zhongshu-comment 先进后出
      
         ret ; zhongshu-comment 类似方法的return，结束过程调用

;-------------------------------------------------------------------------------
calc_segment_base:                       ;计算16位段地址 zhongshu-comment line134~148 参考 P134 8.8.3 用户程序重定位 这一节有对这个过程进行讲解。该过程的作用：进行一个32位的加法运算，0x10000 + dx:ax。0x10000是c08.asm程序在内存中的起始物理地址。dx:ax是c08.asm程序内各个段的汇编地址，该汇编地址是相对于程序开头计算的偏移量、从0开始计算。现在c08.asm被加载到内存，其物理起始内存地址是0x10000，那么c08.asm各个段的汇编地址对应的真实物理内存地址就是：0x10000 + ${段的汇编地址}。刚左文计算得到了段的汇编地址对应的真实物理内存地址，然后再右移4位，就得到了该段的逻辑段地址了，将得到的逻辑段地址保存在ax中、传到调用者处
                                         ;输入：DX:AX=32位物理地址
                                         ;返回：AX=16位段基地址 zhongshu-comment 因为8086处理器的段地址最大也就16位
         push dx                          
         ;zhongshu-comment 这样分两步就可以完成32位数的加法运算，step1：139行先计算低十六位，step2：140行计算高十六位。
         add ax,[cs:phy_base] ;zhongshu-comment cs的值一直都是0x0000，在本程序中没有改动过cs的值
         adc dx,[cs:phy_base+0x02] ;zhongshu-comment adc是带进位的加法，它将目的操作数和源操作数相加；然后再加上标志寄存器CF位的值(0或者1)，该cf位的值是由139行的加法运算产生的
         shr ax,4 ;zhongshu-comment 先将ax寄存器右移四位，左边空出的位用0补充
         ror dx,4 ;zhongshu-comment line142~148 参考P137。 dx寄存器的低四位会移动到dx的高四位处。解释：ror是循环右移指令，每右移1次，移出的比特既送到标志寄存器的CF位，也送进左边空出的位(即将右边移出的比特放到左边空出的位、循环的意思由此而来)
         and dx,0xf000 ;zhongshu-comment line142~148 参考P137。 上一条指令执行后，dx的低12位我们不需要了，所以用"and dx,0xf000"将低12位清零，and指令是两个1才为1、有0就肯定为0，所以和0xf000做and运算是将低12位清零、高4位保持不变
         or ax,dx ;zhongshu-comment line142~148 参考P137。将dx的高4位和ax的低12位拼接起来，是拼接、不是相加，然后保存在ax中。
                    ;zhongshu-comment 解释：or指令是有1则1、两个0就为0，因为ax右移四位之后、高四位补了0，dx执行了指令"and ax,0xf000"后低12位为0。所以or ax,dx-->ax：0000 xxxx xxxx xxxx
         pop dx  ;zhongshu-comment line142~148 参考P137。                                                                                                               ;zhongshu-comment dx: yyyy 0000 0000 0000 所以or运算得出的结果是yyyy xxxx xxxx xxxx
         
         ret

;-------------------------------------------------------------------------------
         phy_base dd 0x10000             ;用户程序被加载的物理起始地址 zhongshu-comment 即从x10000这个物理地址开始加载用户程序
         
 times 510-($-$$) db 0
                  db 0x55,0xaa