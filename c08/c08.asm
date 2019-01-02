         ;�����嵥8-2
         ;�ļ�����c08.asm
         ;�ļ�˵�����û����� 
         ;�������ڣ�2011-5-5 18:17
         ;zhongshu-comment �û�����������135�У���������������������������
;===============================================================================
SECTION header vstart=0                     ;�����û�����ͷ���� 
    program_length  dd program_end          ;�����ܳ���[0x00]
    
    ;�û�������ڵ�
    code_entry      dw start                ;ƫ�Ƶ�ַ[0x04] ;zhongshu-comment ����һ�����ڻ���ַ���û���ַ�Ǵ�code_1�ο�ͷ��ʼ�����ƫ�����������Ǵ���������Ŀ�ͷ��ʼ���
                    dd section.code_1.start ;�ε�ַ[0x06] ;zhongshu-comment ����һ���εĻ���ַ�����Ǵ���������Ŀ�ͷ��ʼ�����ƫ����
    
    realloc_tbl_len dw (header_end - code_1_segment)/4
                                            ;���ض�λ�������[0x0a]
    
    ;���ض�λ�� ;zhongshu-comment ���ض�λ��λ���������code_1_segment��header_end֮�䡣���ض�λ�������εĻ���ַ�ļ���
    code_1_segment  dd section.code_1.start ;[0x0c] ;zhongshu-comment ���ض�λ��ĵ�1������(����˵�ǵ�1����¼)
    code_2_segment  dd section.code_2.start ;[0x10] ;zhongshu-comment ���ض�λ��ĵ�2������(����˵�ǵ�2����¼)
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c] ;zhongshu-comment ���ض�λ��ĵ�5������(����˵�ǵ�5����¼)
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;��������1��16�ֽڶ��룩 
put_string:                              ;��ʾ��(0��β)��;zhongshu-comment �ο�P142 8.4.3���ù��̽�����������DS��BX���ֱ����ַ������ڵĶε�ַ��ƫ�Ƶ�ַ
                                         ;���룺DS:BX=����ַ
         mov cl,[bx]
         or cl,cl                        ;cl=0 ? ;zhongshu-comment һ���������Լ���or���㣬����������Լ���������������Ӱ���־�Ĵ����е�ĳЩλ�����zf��λ(��zfλ����ֵΪ1)��˵��ȡ�����ַ���������־����0(����ֵ0�������ַ�0����û�������Ű�ס��)��or����Ľ����0
         jz .exit                        ;�ǵģ����������� ;zhongshu-comment ��or������Ϊ0��zfλ�ͱ���λ1��jz�жϾ�Ϊtrue������ת�����.exit����ִ��retָ��������̵��á�����������
         call put_char  ;zhongshu-comment ��һ�е�jz�ж�Ϊfalse�����Ի�ִ�и���ָ�put_char�Ĺ��̽��ܵĲ�����cl�Ĵ�����
         inc bx                          ;��һ���ַ� 
         jmp put_string ;zhongshu-comment ������ת��ָ��

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;��ʾһ���ַ� ;zhongshu-comment put_char�Ĺ��̽��ܵĲ�����cl�Ĵ�����
                                         ;���룺cl=�ַ�ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;����ȡ��ǰ���λ�� zhongshu-comment 51~63�� �ο�P143 8.4.5 ȡ��ǰ����λ��
         mov dx,0x3d4 ;zhongshu-comment 51~53��ͨ���Կ��������˿�0x3d4�����Կ�������Ҫ����0x0e�żĴ���
         mov al,0x0e
         out dx,al  ;zhongshu-comment �Կ������Ĵ����Ķ˿ں���0x3d4������ָ������0x3d4�˿�д��һ��ֵ:0x0e����ʾҪ�����Կ����0x0e����Ĵ���
         mov dx,0x3d5 ;zhongshu-comment 0x3d5���Կ������ݶ˿ڣ����ԴӸö˿ڶ�ȡ���ݣ���ȡ����������0x3d4�����˿�ָ�����Ǹ��˿ڡ�Ҳ�������ö˿�д���ݣ�д�����ݻ�д��0x3d4�����˿�ָ�����Ǹ��˿�
         in al,dx                        ;��8λ  zhongshu-comment ͨ�����ݶ˿�0x3d5��0x0e�Ŷ˿ڶ�ȡ1�ֽڵ����ݣ������͵�al��
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;��8λ zhongshu-comment ��0x0f�Ŷ˿ڶ�ȡ1�ֽڵ�����
         mov bx,ax                       ;BX=������λ�õ�16λ�� zhongshu-comment bx�����Ź���λ��
    ;zhongshu-comment 65~78�� �ο�P144 8.4.6 ����س��ͻ��з�
         cmp cl,0x0d                     ;�س�����zhongshu-comment ���cl����0x0d�����س�����ASCII�룬��ôcmpִ�н����0����ôzfλ����Ϊ1��������Ϊ0
         jnz .put_0a                     ;���ǻس�������ת�������ǲ��ǻ��е��ַ� zhongshu-comment ��zfΪ0ʱ����ת����cl������0x0dʱzf�Ż���Ϊ0������cl���ǻس�����ASCII��ʱ����Ϊ0���ͻ���ת
         mov ax,bx                       ;�˾����Զ��࣬��ȥ���󻹵ø��飬�鷳 zhongshu-comment ��cl�ǻس�����ASCII��0x0dʱ��ִ�н��������Ĵ���
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax  ;zhongshu-comment ����һ������֮��ax�еõ��˵�ǰ�����׵Ĺ��λ�õ���ֵ�����ｫax�е����ݱ��浽bx��
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;���з���
         jnz .put_other                  ;���ǻ��з�����ת���Ǿ�������ʾ�ַ�
         add bx,80   ;zhongshu-comment �ǻ��з��ͼ�80����Ϊ���ı�ģʽ�£�һ��Ҳ����ʾ80���ַ�����80���൱�ڽ�����ƶ�����ͬ�е���һ��
         jmp .roll_screen
    ;zhongshu-comment 80~88�� �ο�P145 8.4.7 ��ʾ�ɴ�ӡ�ַ�
 .put_other:                             ;���濪ʼ������ʾ�ַ�
         mov ax,0xb800  ;zhongshu-comment �����ӶμĴ���ES����Ϊָ���Դ�
         mov es,ax
         shl bx,1
         mov [es:bx],cl ;zhongshu-comment cl���ⲿ�������ù��̵Ĳ�������cl���͵��Դ�����ʾ����

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         add bx,1

 .roll_screen:  ;zhongshu-comment 94~101�� �ο�P145 8.4.8
         cmp bx,2000                     ;��곬����Ļ������
         jl .set_cursor ;zhongshu-comment ���lessС��2000������ת��������ڵ���2000�Ͳ���ת��ִ�н��������Ĵ���

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840  ;102~107�д�������ã������Ļ���һ�� zhongshu-comment 102~107�� �ο�P146 ��1�Ρ�
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920 ;zhongshu-comment �ο�P146 ��2�Ρ� ��Ļ���һ��(����25��)�ĵ�һ�еĵ�һ���ַ���λ����1920

 .set_cursor:   ;zhongshu-comment 112~123�� �ο�P146 8.4.9��2��
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
  start: ;zhongshu-comment �ο� [8.4.1 ��ʼ���μĴ�����ջ�л�] �û��������ڡ���Ϊ����������c08_mbr.asm�Ѿ�������ض�λ�����������û������ͷ�ȴ����ǳ�ʼ���������ĸ����μĴ���DS��ES��SS���Ա����ר�����Լ������ݡ��μĴ���CS�Ͳ��ó�ʼ���ˣ����Ǽ��������������£�Ҫ��Ȼ�û�������ô����ִ���أ�
         ;zhongshu-comment ��ʼִ��ʱ��DS��ESָ���û�����ͷ���Σ�ͷ�������ֽ�header��ջ�μĴ���SS��Ȼָ���������ջ�ռ䣬����SSҪ���¸�һ�£�ʹ��ָ�򱾳����ջ��
         mov ax,[stack_segment]           ;���õ��û������Լ��Ķ�ջ��zhongshu-comment 137��138�� ��ͷ��ȡ���û������Լ���ջ�εĶε�ַ�������͵��μĴ���SS
         mov ss,ax
         mov sp,stack_end   ;zhongshu-comment sp��stack pointer��ջ��ָ��Ĵ���
         
         mov ax,[data_1_segment]          ;���õ��û������Լ������ݶ� ;zhongshu-comment �ο�P141 ��2��3�Σ���Ҫ֪ʶ�㣺�����μĴ����ĳ�ʼ��˳�����Ҫ�� ��ʱdsָ�����header�Σ���header��ȡ�����ݶ�data_1�Ķε�ַ��Ȼ��data_1�Ķε�ַ��ֵ��ds
         mov ds,ax  ;zhongshu-comment dsָ���data_1

         mov bx,msg0 ;zhongshu-comment �ο� P141 8.4.2 �� P142 8.4.3��
         call put_string                  ;��ʾ��һ����Ϣ 

         push word [es:code_2_segment] ;zhongshu-comment ��ͷ�����л�ȡcode_2����εĶε�ַ���Խ����û�����֮�󣬶μĴ���ESһֱ��ָ��ͷ����header��
         mov ax,begin
         push ax                          ;����ֱ��push begin,80386+
         
         retf                             ;ת�Ƶ������2ִ�� zhongshu-comment ��������ִ��ָ��retfʱ�����ջ�н�ƫ�Ƶ�ַ�Ͷε�ַ�ֱ𵯳�������μĴ���CS��ָ��ָ��Ĵ���IP��ԡ�ҿ���
         
  continue:
         mov ax,[es:data_2_segment]       ;�μĴ���DS�л������ݶ�2 
         mov ds,ax
         
         mov bx,msg1
         call put_string                  ;��ʾ�ڶ�����Ϣ 

         jmp $ 

;===============================================================================
SECTION code_2 align=16 vstart=0          ;��������2��16�ֽڶ��룩

  begin:
         push word [es:code_1_segment]
         mov ax,continue
         push ax                          ;����ֱ��push continue,80386+
         
         retf                             ;ת�Ƶ������1����ִ�� 
         
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
           
         resb 256 ;zhongshu-comment resb��αָ�����256�ֽڵ�ջ�ռ䡣�öοռ�Ļ���ַ��Χ��0~255�����Ա��stack_end���Ļ���ַ��256

stack_end:  ;zhongshu-comment �ñ��Ӧ����ָ��stack����ε���ߵ��Ǹ���ַ��Ȼ������139����stack_end��Ϊsp������Ϊջ��ʹ���ǴӸߵ�ַ���͵�ַ��

;===============================================================================
SECTION trail align=16
program_end: