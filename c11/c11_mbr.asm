         ;�����嵥11-1
         ;�ļ�����c11_mbr.asm
         ;�ļ�˵����Ӳ���������������� 
         ;�������ڣ�2011-5-16 19:54

         ;���ö�ջ�κ�ջָ�� 
         mov ax,cs    ;zhongshu-comment ��ִ����������������ʱcs�����Ϊ0
         mov ss,ax
         mov sp,0x7c00
      
         ;����GDT���ڵ��߼��ε�ַ 
         mov ax,[cs:gdt_base+0x7c00]        ;��16λ 
         mov dx,[cs:gdt_base+0x7c00+0x02]   ;��16λ 
         mov bx,16        
         div bx            
         mov ds,ax                          ;��DSָ��ö��Խ��в���
         mov bx,dx                          ;������ʼƫ�Ƶ�ַ 
      
         ;����0#�����������ǿ������������Ǵ�������Ҫ��
         mov dword [bx+0x00],0x00   ;zhongshu-comment dword��˫�֣���4���ֽ�
         mov dword [bx+0x04],0x00  

         ;����#1������������ģʽ�µĴ����������
         mov dword [bx+0x08],0x7c0001ff     
         mov dword [bx+0x0c],0x00409800     

         ;����#2������������ģʽ�µ����ݶ����������ı�ģʽ�µ���ʾ�������� 
         mov dword [bx+0x10],0x8000ffff     
         mov dword [bx+0x14],0x0040920b     

         ;����#3������������ģʽ�µĶ�ջ��������
         mov dword [bx+0x18],0x00007a00
         mov dword [bx+0x1c],0x00409600

         ;��ʼ����������Ĵ���GDTR
         mov word [cs: gdt_size+0x7c00],31  ;��������Ľ��ޣ����ֽ�����һ��zhongshu-comment word��������31�����ݳ���Ϊ���ֽ�
                                             
         lgdt [cs: gdt_size+0x7c00]
      
         in al,0x92                         ;����оƬ�ڵĶ˿� ;zhongshu-comment ���ż�ICH����0x92����˿��ж�ȡ���ݵ�al�Ĵ���
         or al,0000_0010B   ;zhongshu-comment ��al�е�λ1��Ϊ1������λ���ֲ���
         out 0x92,al                        ;��A20

         cli                                ;����ģʽ���жϻ�����δ������Ӧ 
                                            ;��ֹ�ж� 
         mov eax,cr0
         or eax,1   ;zhongshu-comment ��eax��λ0��Ϊ1������λ���ֲ���
         mov cr0,eax                        ;����PEλ
      
         ;���½��뱣��ģʽ... ...
         jmp dword 0x0008:flush             ;16λ��������ѡ���ӣ�32λƫ�� ;zhongshu-comment dword��������ʲô���� 0x0008��������ѡ���ӣ�����������gdt�е���ʼƫ������0x0008��gdt�еĵڶ�������������ʼƫ������ÿһ��������ռ8���ֽڣ�gdt�ĵ�һ��������ռ��0~7�ֽ�
                                            ;����ˮ�߲����л������� 
         [bits 32] 

    flush:
         mov cx,00000000000_10_000B         ;�������ݶ�ѡ����(0x10) zhongshu-comment ��ν��ѡ���ӣ�������������gdt�е���ʼƫ������0x10������ʮ���Ƶ�16���������ݶ���������gdtƫ����Ϊ16�����Լ�������7�ֽڣ���8�ֽڣ���gdt�е�16~23�ֽ������ݶ�������
         mov ds,cx  ;zhongshu-comment �ڱ���ģʽ�£��ı�μĴ�����ֻ��Ҫ����ѡ���Ӵ��͵��μĴ����м��ɣ������������Ŷ�ѡ���ӵ�gdt�л�ȡ�������������������д��жε����Ե�ַ(��32λ����ģʽ�²���Ҫ��������λ��)��������ȡ���Ķ��������洢�����������ٻ�������

         ;��������Ļ����ʾ"Protect mode OK."
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

         ;�����ü򵥵�ʾ������������32λ����ģʽ�µĶ�ջ���� 
         mov cx,00000000000_11_000B         ;���ض�ջ��ѡ���� zhongshu-comment �ö��������ֵ���24����32�е�0x18���
         mov ss,cx
         mov esp,0x7c00

         mov ebp,esp                        ;�����ջָ�� 
         push byte '.'                      ;ѹ�����������ֽڣ�zhongshu-comment ��Ȼ��ʵ��ѹ��һ�ֽڣ�ʵ����32λ����ģʽÿ��ѹջ����ѹ��4�ֽڣ�����������㲹ȫʣ�µ�24λ���ο�P���ˡ�����esp���4��������ĵ�ebp���->jnz������ת->����ʾ'.'
         
         sub ebp,4
         cmp ebp,esp                        ;�ж�ѹ��������ʱ��ESP�Ƿ��4 
         jnz ghalt  ;zhongshu-comment ��ebp������esp����cmpִ�н��Ϊ��Ϊ0����zfλ��Ϊ0����ô����ת�����ghalt��
         pop eax
         mov [0x1e],al                      ;��ʾ��� 
      
  ghalt:     
         hlt                                ;�Ѿ���ֹ�жϣ������ᱻ���� 

;-------------------------------------------------------------------------------
     
         gdt_size         dw 0  ;zhongshu-comment �֣������ֽ�
         gdt_base         dd 0x00007e00     ;GDT�������ַ 
                             
         times 510-($-$$) db 0
                          db 0x55,0xaa

;zhongshu-comment
;step��ʵģʽ�£���ʼ��ջ�μĴ�����
;step��ʵģʽ�£���װGDT��
;step��ʵģʽ�£���ʼ����������Ĵ���GDTR��
;step��ʵģʽ�£���A20��ַ�ߣ�
;step��ʵģʽ�£�ִ��cli�����������жϣ�
;step��ʵģʽ�£���cr0�Ĵ�����PEλ����Ϊ1��
;step��ʵģʽ�£�jmp��GDT���趨��cs�Σ�32λ����ģʽ
;step��ִ��32λģʽ�µ�ָ��