         ;代码清单7-1
         ;文件名：c07_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-4-13 18:02
         
         jmp near start
	
 message db '1+2+3+...+100='
        
 start:
         mov ax,0x7c0           ;设置数据段的段基地址
         mov ds,ax ;zhongshu-comment 设置ds的值为0x7c00，即段首地址是0x7c00，这样程序的汇编地址和段内偏移地址就一致了

         mov ax,0xb800          ;设置附加段基址到显示缓冲区
         mov es,ax

         ;以下显示字符串 
         mov si,message          
         mov di,0
         mov cx,start-message ;zhongshu-comment 计算循环次数，循环次数等于字符串的长度，即字符的个数，ASCII字符占一个字节
     @g:
         mov al,[si]
         mov [es:di],al
         inc di
         mov byte [es:di],0x07
         inc di
         inc si
         loop @g

         ;以下计算1到100的和 
         xor ax,ax
         mov cx,1
     @f:
         add ax,cx
         inc cx
         cmp cx,100
         jle @f ;zhongshu-comment P91 

         ;以下计算累加和的每个数位 
         xor cx,cx              ;设置堆栈段的段基地址
         mov ss,cx
         mov sp,cx

         mov bx,10
         xor cx,cx ;zhongshu-comment 累加器的作用，用来累加总共分解出了多少个数位
     @d:
         inc cx
         xor dx,dx
         div bx
         or dl,0x30
         push dx ;zhongshu-comment div除法得到的余数保存在dx寄存器中，这里将dx的内容压入栈。对于8086处理器来说，push指令的操作数只能是16位的通用寄存器或者内存单元
         cmp ax,0 ;zhongshu-comment div除法得到的商保存在ax中。该行代码的作用是判断本次除法的商是否等于0，如果不等于0，下一行代码的判断就为true，就会跳转，在程序里也就是会继续循环
         jne @d ;zhongshu-comment 当cmp比较结果不等于0时就跳转

         ;以下显示各个数位 
     @a:
         pop dx ;zhongshu-comment 将栈顶的一个字弹出到寄存器dx中
         mov [es:di],dl ;zhongshu-comment 在本程序，我们知道dx的高8位全是0，所以直接使用低8位的dl即可，将dl的内容传送到显示缓冲区
         inc di
         mov byte [es:di],0x07 ;zhongshu-comment 0x07是字符的显示属性
         inc di ;zhongshu-comment 递增DI以指向显示缓冲区中下一个字符的位置
         loop @a
       
         jmp near $ 
       

times 510-($-$$) db 0
                 db 0x55,0xaa