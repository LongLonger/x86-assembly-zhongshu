         ;代码清单11-1
         ;文件名：c11_mbr.asm
         ;文件说明：硬盘主引导扇区代码 
         ;创建日期：2011-5-16 19:54

         ;设置堆栈段和栈指针 
         mov ax,cs    ;zhongshu-comment 刚执行主引导扇区程序时cs代码段为0
         mov ss,ax
         mov sp,0x7c00
      
         ;计算GDT所在的逻辑段地址 
         mov ax,[cs:gdt_base+0x7c00]        ;低16位 
         mov dx,[cs:gdt_base+0x7c00+0x02]   ;高16位 
         mov bx,16        
         div bx            
         mov ds,ax                          ;令DS指向该段以进行操作
         mov bx,dx                          ;段内起始偏移地址 
      
         ;创建0#描述符，它是空描述符，这是处理器的要求
         mov dword [bx+0x00],0x00   ;zhongshu-comment dword是双字，共4个字节
         mov dword [bx+0x04],0x00  

         ;创建#1描述符，保护模式下的代码段描述符
         mov dword [bx+0x08],0x7c0001ff     
         mov dword [bx+0x0c],0x00409800     

         ;创建#2描述符，保护模式下的数据段描述符（文本模式下的显示缓冲区） 
         mov dword [bx+0x10],0x8000ffff     
         mov dword [bx+0x14],0x0040920b     

         ;创建#3描述符，保护模式下的堆栈段描述符
         mov dword [bx+0x18],0x00007a00
         mov dword [bx+0x1c],0x00409600

         ;初始化描述符表寄存器GDTR
         mov word [cs: gdt_size+0x7c00],31  ;描述符表的界限（总字节数减一）zhongshu-comment word用来限制31的数据长度为两字节
                                             
         lgdt [cs: gdt_size+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 ;zhongshu-comment 南桥即ICH。从0x92这个端口中读取内容到al寄存器
         or al,0000_0010B   ;zhongshu-comment 将al中的位1置为1，其他位保持不变
         out 0x92,al                        ;打开A20

         cli                                ;保护模式下中断机制尚未建立，应 
                                            ;禁止中断 
         mov eax,cr0
         or eax,1   ;zhongshu-comment 将eax的位0置为1，其他位保持不变
         mov cr0,eax                        ;设置PE位
      
         ;以下进入保护模式... ...
         jmp dword 0x0008:flush             ;16位的描述符选择子：32位偏移 ;zhongshu-comment dword的作用是什么？？ 0x0008是描述符选择子，即描述符在gdt中的起始偏移量，0x0008是gdt中的第二个描述符的起始偏移量，每一个描述符占8个字节，gdt的第一个描述符占了0~7字节
                                            ;清流水线并串行化处理器 
         [bits 32] 

    flush:
         mov cx,00000000000_10_000B         ;加载数据段选择子(0x10) zhongshu-comment 所谓段选择子，即段描述符在gdt中的起始偏移量，0x10即等于十进制的16，所以数据段描述符在gdt偏移量为16处，以及后续的7字节，共8字节，即gdt中第16~23字节是数据段描述符
         mov ds,cx  ;zhongshu-comment 在保护模式下，改变段寄存器，只需要将段选择子传送到段寄存器中即可，处理器会拿着段选择子到gdt中获取段描述符，段描述符中存有段的线性地址(在32位保护模式下不需要再左移四位了)，并将获取到的段描述符存储到描述符高速缓存器中

         ;以下在屏幕上显示"Protect mode OK."
         mov byte [0x00],'P'  
         mov byte [0x02],'r'
         mov byte [0x04],'o'
         mov byte [0x06],'t'
         mov byte [0x08],'e'
         mov byte [0x0a],'c'
         mov byte [0x0c],'t'
         mov byte [0x0e],' '
         mov byte [0x10],'m'
         mov byte [0x12],'o'
         mov byte [0x14],'d'
         mov byte [0x16],'e'
         mov byte [0x18],' '
         mov byte [0x1a],'O'
         mov byte [0x1c],'K'

         ;以下用简单的示例来帮助阐述32位保护模式下的堆栈操作 
         mov cx,00000000000_11_000B         ;加载堆栈段选择子 zhongshu-comment 该二进制数字等于24，和32行的0x18相等
         mov ss,cx
         mov esp,0x7c00

         mov ebp,esp                        ;保存堆栈指针 
         push byte '.'                      ;压入立即数（字节）zhongshu-comment 虽然现实是压入一字节，实际上32位保护模式每次压栈都会压入4字节，处理器会给你补全剩下的24位，参考P忘了。所以esp会减4，会和下文的ebp相等->jnz不会跳转->会显示'.'
         
         sub ebp,4
         cmp ebp,esp                        ;判断压入立即数时，ESP是否减4 
         jnz ghalt  ;zhongshu-comment 当ebp不等于esp，则cmp执行结果为不为0，则zf位会为0，那么会跳转到标号ghalt处
         pop eax
         mov [0x1e],al                      ;显示句点 
      
  ghalt:     
         hlt                                ;已经禁止中断，将不会被唤醒 

;-------------------------------------------------------------------------------
     
         gdt_size         dw 0  ;zhongshu-comment 字，两个字节
         gdt_base         dd 0x00007e00     ;GDT的物理地址 
                             
         times 510-($-$$) db 0
                          db 0x55,0xaa

;zhongshu-comment
;step①实模式下，初始化栈段寄存器，
;step②实模式下，安装GDT，
;step③实模式下，初始化描述符表寄存器GDTR，
;step④实模式下，打开A20地址线，
;step⑤实模式下，执行cli，进制所有中断，
;step⑥实模式下，将cr0寄存器的PE位设置为1，
;step⑦实模式下，jmp到GDT中设定的cs段，32位保护模式
;step⑧执行32位模式下的指令