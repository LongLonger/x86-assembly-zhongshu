




    app_lba_start equ 100   ;声明常数（用户程序其实逻辑扇区号）
                            ;常数的声明不会占用汇编地址

SECTION mbr align=16 vstart=0x7c00 ;zhongshu-comment 段内所有的汇编地址都将从0x7c00开始计算

        ;设置栈段和段指针
        mov ax,0
        mov ss,ax
        mov sp,ax

        mov ax,[cs:phy_base]    ;计算用于加载用户程序的逻辑段地址，即将程序加载到哪个段 ;zhongshu-comment 段寄存器cs的内容是0x0000，电脑刚启动时，cs的值就是0x0000
        mov dx,[cs:phy_base+0x02]
        mov bx,16
        div bx  ;zhongshu-comment 这是32位的除法运算，32位除以16位寄存器，被除数在dx:ax，除数在bx，得到的商保存在ax、余数在dx。该次除法是为了将物理地址除以16、得到该物理地址对应的段地址，除以16就相当于右移四位，从20位变为16位
        mov ds,ax   ;令ds和es指向该段 zhongshu-comment 该段的地址就是程序被加载到的地方，就是是上文刚计算出来的地址
        mov es,ax

        ;以下读取程序的起始部分
        xor di,di
        mov si,app_lba_start    ;程序在硬盘上的起始逻辑扇区号
        xor bx,bx               ;加载到DS:0x0000处
        call read_hard_disk_0


















































;-------------------------------------------------------------------------------
read_hard_disk_0:       ;从硬盘读取一个逻辑扇区 zhongshu-comment 该过程有两个参数：每次读取硬盘时的起始逻辑扇区号 和 读取出来的数据存储在哪。由于该过程每次只读取一个扇区，所以不需要通过传参的方式指定要读取的扇区数
                        ;输入：DI:SI=起始逻辑扇区号
                        ;       DS:BX=目标缓冲区地址 zhongshu-comment 从硬盘读取出来的数据存储到DS:BX所指向的内存位置
        push ax
        push bx
        push cx
        push dx

        mov dx,0x1f2
        mov al,1
        out dx,al   ;读取的扇区数

        inc dx
        mov ax,si
        out dx,al

        inc dx
        mov al,ah
        out dx,al

        inc dx
        mov ax,di
        out dx,al

        inc dx
        mov al,0xe0 ;zhongshu-comment 0xe0即1110 0000
        or al,ah
        out dx,al

        inc dx
        mov al,0x20
        out dx,al


