         ;代码清单6-1
         ;文件名：c06_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-4-12 22:12 
      
         jmp near start ; zhongshu-comment 主引导扇区的第一行代码，主引导扇区被加载到0x7c00:0x0000处，这时cs段寄存器=0x7c00，ip=0x0000（是rom-bios执行jmp指令跳转到这里的:cs段寄存器=0x7c00，ip=0x0000）
         
  mytext db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07,\
            'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
  number db 0,0,0,0,0
  
  start:
         mov ax,0x7c0                  ;设置数据段基地址 zhongshu-comment BIOS将主引导扇区加载到物理地址0x07c00处
         mov ds,ax
         
         mov ax,0xb800                 ;设置附加段基地址 zhongshu-comment 0xb800是显存所在段的段地址
         mov es,ax
         
         cld ;zhongshu-comment cld是方向标志清零指令，cld指令将标志寄存器FLAGS的第10位方向标志DF(Direction Flag)清零，以指示movsb、movsw指令的传送方向是正方向的，具体见P78 6.5 段之间的批量数据传送
         mov si,mytext ;zhongshu-comment 将第一条源数据的偏移地址传送到si寄存器，si用来存储源数据的偏移地址
         mov di,0 ;zhongshu-comment di寄存器用来存储目的数据的偏移地址
         mov cx,(number-mytext)/2      ;实际上等于 13 zhongshu-comment 设置要批量传送的字数到cx寄存器。因为源数据在mytext和number两个标号之间，number-mytext得到源数据的字节个数，由于下文使用了movsw传送数据，所以就除以2得到字数
         rep movsw ;zhongshu-comment 每次传送一个字(即两个字节)。单纯的movsb和movsw只能执行一次，加上指令前缀rep(即repeat重复的意思)，将重复执行movsw直到cx的内容为0，当cx=0时就跳出循环，即重复cx次。每执行一次movsw，si和di都会加2

         ;得到标号所代表的偏移地址 ;zhongshu-comment 这里为分界线，下面另起了一段没有什么关系的逻辑了，具体的逻辑解释见P80 6.6 使用循环分解数位
         mov ax,number ;zhongshu-comment 被除数的低16位保存在ax寄存器中
         
         ;计算各个数位
         mov bx,ax
         mov cx,5                      ;循环次数 
         mov si,10                     ;除数 
  digit: 
         xor dx,dx ;zhongshu-comment 将被除数的高十六位清零
         div si
         mov [bx],dl                   ;保存数位 zhongshu-comment 在8086处理器上，如果要用寄存器来提供偏移地址，只能使用BX、SI、DI、BPP81 下面6.6 使用循环分解数位
         inc bx     ;zhongshu-comment bx在这里用于偏移地址，刚上一条指令将余数保存到bx偏移地址所指向的位置，所以这里将bx加1，以便下次循环时保存到bx+1的那个地址
         loop digit ;zhongshu-comment 处理器在执行loop指令的时候，会顺序做两件事：1、将寄存器cx的内容减一. 2、判断cx减一后是否为0，如果不为0，就跳转到标号digit所在的位置处执行，否则顺序执行后面的指令
         
         ;显示各个数位 zhongshu-comment 下文使用一个循环将计算出来的各个数位传送到显示缓冲区，该缓冲区的段地址是0xB800，已经保存在es寄存器中了
         mov bx,number ;zhongshu-comment 上文计算出来的数位保存在标号number处
         mov si,4 ; zhongshu-comment 作用1：用作偏移地址。作用2：用来存储循环的次数，要循环4次。因为当sf标志位为0，jns条件转移指令就会跳转；当指令运算结果的最高位是1，sf标志位的就会置为1，假如你做的是有符号数运算，如果sf位是1，那就要注意了，证明结果是一个负数；下文有个指令dec si，会将si里的值减1，当si被减到-1时，sf标志位就被设置为1，jns就不再跳转到标号show处，也就意味着循环结束
   show:
         mov al,[bx+si]
         add al,0x30 ; zhongshu-comment 字符的ascII码
         mov ah,0x04 ; zhongshu-comment 字符的显示属性
         mov [es:di],ax ; zhongshu-comment 将字符的ascII码和显示属性两个字节传送到显存中，di：即destination index
         add di,2 ; zhongshu-comment di寄存器中存储了显存内的偏移地址，因为上一行代码往显存传入了2个字节，所以di加2
         dec si
         jns show
         
         mov word [es:di],0x0744

         jmp near $

  times 510-($-$$) db 0
                   db 0x55,0xaa