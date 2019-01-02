         ;代码清单5-1 
         ;文件名：c05_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-3-31 21:15 
         
         mov ax,0xb800                 ;指向文本模式的显示缓冲区
         mov es,ax

         ;以下显示字符串"Label offset:"
         mov byte [es:0x00],'L'
         mov byte [es:0x01],0x07
         mov byte [es:0x02],'a'
         mov byte [es:0x03],0x07
         mov byte [es:0x04],'b'
         mov byte [es:0x05],0x07
         mov byte [es:0x06],'e'
         mov byte [es:0x07],0x07
         mov byte [es:0x08],'l'
         mov byte [es:0x09],0x07
         mov byte [es:0x0a],' '
         mov byte [es:0x0b],0x07
         mov byte [es:0x0c],"o"
         mov byte [es:0x0d],0x07
         mov byte [es:0x0e],'f'
         mov byte [es:0x0f],0x07
         mov byte [es:0x10],'f'
         mov byte [es:0x11],0x07
         mov byte [es:0x12],'s'
         mov byte [es:0x13],0x07
         mov byte [es:0x14],'e'
         mov byte [es:0x15],0x07
         mov byte [es:0x16],'t'
         mov byte [es:0x17],0x07
         mov byte [es:0x18],':'
         mov byte [es:0x19],0x07
         ; zhongshu-comment 这里只是单纯使用number这个汇编地址(或叫偏移地址)作为被除数而已，并不是说要拿这个偏移地址去获取内存单元中的值
         mov ax,number                 ;取得标号number的偏移地址
         mov bx,10 ;zhongshu-comment 除以十进制的10，因为没有加0x前缀，所以不是十六进制

         ;设置数据段寄存器ds的基地址
         mov cx,cs ;zhongshu-comment 在上文并没有找到给cs赋值的代码，但其实cs是有值的，因为该汇编程序是会被写到硬盘的主引导扇区的，然后主引导扇区的内容被加载到内存中并开始执行时，CS寄存器会被ROM-BIOS初始化为0x0000、IP寄存器会被初始化为0x7C00(因为ROM-BIOS执行了一条指令jmp 0x0000:0x7c00)
         mov ds,cx

         ;求个位上的数字，32位除以16位，高16位在dx，低16位在ax，除完之后，商在ax，余数在dx
         mov dx,0 ;被除数是number，number不需要占32位那么多，高16位全是0，所以就直接给dx寄存器赋值为0
         div bx
         mov [0x7c00+number+0x00],dl   ;保存个位上的数字。余数在dx中，但是该余数占的位数最多也就8位，所以直接mov dl的值即可，不需要mov dx的

         ;求十位上的数字
         xor dx,dx ;上一次除法运算的商保存在ax中，dx清零之后，dx:ax继续组成被除数
         div bx
         mov [0x7c00+number+0x01],dl   ;保存十位上的数字

         ;求百位上的数字
         xor dx,dx ;最快的清0方法，寄存器之间的运算。
         div bx
         mov [0x7c00+number+0x02],dl   ;保存百位上的数字

         ;求千位上的数字
         xor dx,dx
         div bx
         mov [0x7c00+number+0x03],dl   ;保存千位上的数字

         ;求万位上的数字 
         xor dx,dx
         div bx
         mov [0x7c00+number+0x04],dl   ;保存万位上的数字

         ;以下用十进制显示标号的偏移地址
         mov al,[0x7c00+number+0x04] ;zhongshu-comment 从偏移地址0x7c00+number+0x04处取得万位上的数字
         add al,0x30 ;zhongshu-comment 数字本身的值和ASCII码相差0x30，所以加上0x30后就能得到数字对应的ASCII码
         mov [es:0x1a],al ;zhongshu-comment 将要显示的ASCII码传送到显示缓冲区中偏移地址为0x1A的位置，紧跟着上文已显示的字符串"LABEL offset:"
         mov byte [es:0x1b],0x04 ; zhongshu-comment 0x04是字符的显示属性，黑底红字、无闪烁、无加亮
         
         mov al,[0x7c00+number+0x03]
         add al,0x30
         mov [es:0x1c],al
         mov byte [es:0x1d],0x04
         
         mov al,[0x7c00+number+0x02]
         add al,0x30
         mov [es:0x1e],al
         mov byte [es:0x1f],0x04

         mov al,[0x7c00+number+0x01]
         add al,0x30
         mov [es:0x20],al
         mov byte [es:0x21],0x04

         mov al,[0x7c00+number+0x00]
         add al,0x30
         mov [es:0x22],al
         mov byte [es:0x23],0x04
         
         mov byte [es:0x24],'D'
         mov byte [es:0x25],0x07
          
   infi: jmp near infi                 ;无限循环
      
  number db 0,0,0,0,0
  
  times 203 db 0
            db 0x55,0xaa