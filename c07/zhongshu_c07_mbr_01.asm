
jmp near start

message:
    db '1+2+3+...+100='

start:
    mov ax, 0x7c0
    mov ds, ax
    mov si, message

    mov ax, 0xb800
    mov es, ax
    mov di, 0

    mov cx, start-message

    flag1:
        mov al,[si]
        mov [es:di], al
        mov byte [es:di+1], 0x07
        add di, 2
        inc si
        loop flag1

    ;以下计算1到100的和
    xor ax, ax
    mov cx, 1

    flag2:
        add ax, cx
        inc cx
        cmp cx, 100
        jle flag2

    xor cx, cx
    mov ss, cx
    mov sp, cx

    mov bx, 10
    xor cx, cx

    flag3:
        inc cx
        xor dx, dx
        div bx
        or dl, 0x30
        push dx
        cmp ax, 0


    jmp near $

times 454 db 0
    db 0x55, 0xaa