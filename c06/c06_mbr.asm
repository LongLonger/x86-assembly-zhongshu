         ;�����嵥6-1
         ;�ļ�����c06_mbr.asm
         ;�ļ�˵����Ӳ����������������
         ;�������ڣ�2011-4-12 22:12 
      
         jmp near start ; zhongshu-comment �����������ĵ�һ�д��룬���������������ص�0x7c00:0x0000������ʱcs�μĴ���=0x7c00��ip=0x0000����rom-biosִ��jmpָ����ת�������:cs�μĴ���=0x7c00��ip=0x0000��
         
  mytext db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07,\
            'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
  number db 0,0,0,0,0
  
  start:
         mov ax,0x7c0                  ;�������ݶλ���ַ zhongshu-comment BIOS���������������ص������ַ0x07c00��
         mov ds,ax
         
         mov ax,0xb800                 ;���ø��Ӷλ���ַ zhongshu-comment 0xb800���Դ����ڶεĶε�ַ
         mov es,ax
         
         cld ;zhongshu-comment cld�Ƿ����־����ָ�cldָ���־�Ĵ���FLAGS�ĵ�10λ�����־DF(Direction Flag)���㣬��ָʾmovsb��movswָ��Ĵ��ͷ�����������ģ������P78 6.5 ��֮����������ݴ���
         mov si,mytext ;zhongshu-comment ����һ��Դ���ݵ�ƫ�Ƶ�ַ���͵�si�Ĵ�����si�����洢Դ���ݵ�ƫ�Ƶ�ַ
         mov di,0 ;zhongshu-comment di�Ĵ��������洢Ŀ�����ݵ�ƫ�Ƶ�ַ
         mov cx,(number-mytext)/2      ;ʵ���ϵ��� 13 zhongshu-comment ����Ҫ�������͵�������cx�Ĵ�������ΪԴ������mytext��number�������֮�䣬number-mytext�õ�Դ���ݵ��ֽڸ�������������ʹ����movsw�������ݣ����Ծͳ���2�õ�����
         rep movsw ;zhongshu-comment ÿ�δ���һ����(�������ֽ�)��������movsb��movswֻ��ִ��һ�Σ�����ָ��ǰ׺rep(��repeat�ظ�����˼)�����ظ�ִ��movswֱ��cx������Ϊ0����cx=0ʱ������ѭ�������ظ�cx�Ρ�ÿִ��һ��movsw��si��di�����2

         ;�õ�����������ƫ�Ƶ�ַ ;zhongshu-comment ����Ϊ�ֽ��ߣ�����������һ��û��ʲô��ϵ���߼��ˣ�������߼����ͼ�P80 6.6 ʹ��ѭ���ֽ���λ
         mov ax,number ;zhongshu-comment �������ĵ�16λ������ax�Ĵ�����
         
         ;���������λ
         mov bx,ax
         mov cx,5                      ;ѭ������ 
         mov si,10                     ;���� 
  digit: 
         xor dx,dx ;zhongshu-comment ���������ĸ�ʮ��λ����
         div si
         mov [bx],dl                   ;������λ zhongshu-comment ��8086�������ϣ����Ҫ�üĴ������ṩƫ�Ƶ�ַ��ֻ��ʹ��BX��SI��DI��BPP81 ����6.6 ʹ��ѭ���ֽ���λ
         inc bx     ;zhongshu-comment bx����������ƫ�Ƶ�ַ������һ��ָ��������浽bxƫ�Ƶ�ַ��ָ���λ�ã��������ｫbx��1���Ա��´�ѭ��ʱ���浽bx+1���Ǹ���ַ
         loop digit ;zhongshu-comment ��������ִ��loopָ���ʱ�򣬻�˳���������£�1�����Ĵ���cx�����ݼ�һ. 2���ж�cx��һ���Ƿ�Ϊ0�������Ϊ0������ת�����digit���ڵ�λ�ô�ִ�У�����˳��ִ�к����ָ��
         
         ;��ʾ������λ zhongshu-comment ����ʹ��һ��ѭ������������ĸ�����λ���͵���ʾ���������û������Ķε�ַ��0xB800���Ѿ�������es�Ĵ�������
         mov bx,number ;zhongshu-comment ���ļ����������λ�����ڱ��number��
         mov si,4 ; zhongshu-comment ����1������ƫ�Ƶ�ַ������2�������洢ѭ���Ĵ�����Ҫѭ��4�Ρ���Ϊ��sf��־λΪ0��jns����ת��ָ��ͻ���ת����ָ�������������λ��1��sf��־λ�ľͻ���Ϊ1���������������з��������㣬���sfλ��1���Ǿ�Ҫע���ˣ�֤�������һ�������������и�ָ��dec si���Ὣsi���ֵ��1����si������-1ʱ��sf��־λ�ͱ�����Ϊ1��jns�Ͳ�����ת�����show����Ҳ����ζ��ѭ������
   show:
         mov al,[bx+si]
         add al,0x30 ; zhongshu-comment �ַ���ascII��
         mov ah,0x04 ; zhongshu-comment �ַ�����ʾ����
         mov [es:di],ax ; zhongshu-comment ���ַ���ascII�����ʾ���������ֽڴ��͵��Դ��У�di����destination index
         add di,2 ; zhongshu-comment di�Ĵ����д洢���Դ��ڵ�ƫ�Ƶ�ַ����Ϊ��һ�д������Դ洫����2���ֽڣ�����di��2
         dec si
         jns show
         
         mov word [es:di],0x0744

         jmp near $

  times 510-($-$$) db 0
                   db 0x55,0xaa