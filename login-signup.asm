.model small
.stack 100h

.data
    ; Buffers de entrada
    user_buf    db 20,0,20 dup(?)    ; [max][len][datos]
    pass_buf    db 20,0,20 dup(?)    ; igual para clave

    ; Buffer para el hash en ASCII hex
    hex_buf     db 40 dup(?)
    hex_len     dw ?

    ; Archivo / lectura 
    filename    db 'key.txt',0
    handle      dw ?
    file_buf    db 64 dup(?)
    file_len    dw ?                  ; bytes que DOS devolvio al leer
    rec_off     dw 0                  ; offset de inicio de cada linea

    ; Clave secreta para cifrado unidireccional
    secret      db 5Ah

    ; Mensajes 
    msg_welcome    db 'Bienvenido al programa',13,10,'$'
    msg_menu       db '1) Login',13,10,'2) Sign Up',13,10,'Seleccione opcion: $'
    msg_enter_usr  db 13,10,'Usuario: $'
    msg_enter_pwd  db 13,10,'Clave: $'
    msg_signup_ok  db 13,10,'Registro exitoso',13,10,'$'
    msg_user_exist db 13,10,'Usuario ya existe',13,10,'$'
    msg_login_ok   db 13,10,'Login exitoso',13,10,'$'
    msg_login_fail db 13,10,'Login fallido',13,10,'$'
    msg_invalid    db 13,10,'Opcion invalida',13,10,'$'
    ch_colon       db ':'
    crlf_bytes     db 13,10

.code
start:
    mov  ax,@data
    mov  ds,ax
    mov  es,ax   
    
    call ensure_file      ; Verifica si existe el archivo
    
    jmp main_menu

main_menu:
    lea  dx,msg_welcome
    mov  ah,09h
    int 21h

    lea  dx,msg_menu
    mov  ah,09h
    int 21h

    mov  ah,01h           ; Leer opcion
    int 21h               
    sub  al,'0'           ; ASCII -> numero
    
    cmp  al,1
    je   do_login
    
    cmp  al,2
    je   do_signup   
    
    lea dx,msg_invalid
    mov ah,09h
    int 21h
    
    jmp  main_menu
                  
;-------------------------------------------------
; ensure_file:
;  - Usa INT21h/AH=43h para consultar atributos
;  - Si CF=1 (no existe), lo crea con AH=3Ch
;  - Cierra el handle recien creado
;-------------------------------------------------
ensure_file PROC
    lea  dx, filename
    mov  ah, 43h       ; Obtener los atributos del archivo
    mov  al, 0         
    int 21h
    jc   create        ; CF=1 ? fichero NO existe

    ; Si CF=0 -> existe, no hay nada que hacer
    ret

create:
    lea  dx, filename
    mov  ah, 3Ch       ; Crear archivo
    mov  cx, 0         ; Atributos normales
    int 21h
    jc   .done         ; Si falla al crear, salir
    mov  bx, ax        ; BX=handle creado

    mov  ah, 3Eh       ; Cerrar archivo
    int 21h

done:
    ret
ensure_file ENDP
        
 
;-------------------------------------------------
; do_signup: pide datos, valida existencia, cifra y guarda
;-------------------------------------------------
do_signup PROC
    ; --- Pedir usuario ---
    lea  dx,msg_enter_usr
    mov  ah,09h
    int 21h
    lea  dx,user_buf
    mov  ah,0Ah
    int 21h

    ; --- Si ya existe, mostrar mensaje y volver al menu ---
    call user_exists
    jnz  user_already     ; CF=0 y ZF=1 => usuario encontrado

    ; --- Pedir clave ---
    lea  dx,msg_enter_pwd
    mov  ah,09h
    int 21h
    lea  dx,pass_buf
    mov  ah,0Ah
    int 21h

    ; --- Cifrar y guardar ---
    call encrypt_pass
    call write_record

    lea  dx,msg_signup_ok
    mov  ah,09h
    int 21h
    jmp  main_menu

user_already:
    lea  dx,msg_user_exist
    mov  ah,09h
    int 21h
    jmp main_menu
do_signup ENDP

;-------------------------------------------------
; do_login: pide datos, cifra y verifica
;-------------------------------------------------
do_login PROC
    lea  dx,msg_enter_usr
    mov  ah,09h
    int 21h
    lea  dx,user_buf
    mov  ah,0Ah
    int 21h

    lea  dx,msg_enter_pwd
    mov  ah,09h
    int 21h
    lea  dx,pass_buf
    mov  ah,0Ah
    int 21h

    call encrypt_pass
    call verify_login
    jmp main_menu
do_login ENDP

;-------------------------------------------------
; user_exists: busca el user_buf en key.txt
; Return: ZF=1 si lo encuentra, ZF=0 si no
;-------------------------------------------------
user_exists PROC
    ; Abrir archivo
    lea  dx,filename
    mov  ah,3Dh
    mov  al,0           ; modo lectura
    int 21h

    mov  [handle],ax

    ; Leer hasta 64 bytes
    mov  ah,3Fh
    mov  bx,[handle]
    mov  cx,64
    lea  dx,file_buf
    int 21h
    mov  [file_len],ax

    ; Cerrar archivo
    mov  ah,3Eh
    mov  bx,[handle]
    int 21h

    ; Recorrer lineas buscando usuario
    xor  ax,ax
    mov  [rec_off],ax

ue_search:
    ; Fuera de los limites?
    mov  ax,[rec_off]
    cmp  ax,[file_len]
    jae  not_found

    ; Comparar user_buf con parte izquierda de la linea
    lea  si,file_buf
    add  si,ax               ; SI = inicio de linea
    lea  di,user_buf+2       ; DI = inicio de nombre
    mov  cl,[user_buf+1]
    xor  ch,ch
    rep  cmpsb               ; compara CX bytes
    jnz  ue_next_line

    ; Debe venir inmediatamente un ':'
    cmp  byte ptr [si],':'
    jne  ue_next_line

    ; Si llegamos aqui, el usuario existe
    stc                      ; CF=1
    mov  ax,1
    ret

ue_next_line:
    ; Saltar hasta CRLF
    lea  si,file_buf
    add  si,[rec_off]
  .skipCR:
    cmp byte ptr [si],0Dh
    jne .incSI
    add si,2
    jmp .updOff
  .incSI:
    inc si
    jmp .skipCR
  .updOff:
    mov ax,si
    sub ax,OFFSET file_buf
    mov [rec_off],ax
    jmp ue_search

not_found:
    clc      ; CF=0
    xor ax,ax
    ret
user_exists ENDP

;-------------------------------------------------
; encrypt_pass: cifra con ADD secret + ROL3
; y convierte a ASCII hex en hex_buf
;-------------------------------------------------
encrypt_pass PROC
    mov  cl,[pass_buf+1]
    lea  si,pass_buf+2
    lea  di,hex_buf
.enc_lp:
    lodsb
    add  al,[secret]
    rol  al,3

    ; nivel alto
    mov  ah,al
    shr  ah,4
    and  ah,0Fh
    mov  dl,ah
    call hex_to_ascii
    mov  [di],dl
    inc  di
    ; nivel bajo
    mov  dl,al
    and  dl,0Fh
    call hex_to_ascii
    mov  [di],dl
    inc  di

    dec cl
    jnz .enc_lp

    ; longitud = DI - &hex_buf
    mov  ax,di
    sub  ax,OFFSET hex_buf
    mov  [hex_len],ax
    ret
encrypt_pass ENDP

;-------------------------------------------------
; hex_to_ascii: DL=0..0F -> '0'..'9'/'A'..'F'
;-------------------------------------------------
hex_to_ascii PROC
    cmp dl,9
    jbe dt
    add dl,'A'-10
    ret
dt:
    add dl,'0'
    ret
hex_to_ascii ENDP

;-------------------------------------------------
; write_record: abre y agrega al final del archivo:
;   user_buf+':'+hex_buf+CRLF
;-------------------------------------------------
write_record PROC
    lea dx,filename
    mov ah,3Dh
    mov al,2       ; RD/WR
    int 21h
    jc   wr_create
    mov [handle],ax
    jmp wr_seek
wr_create:
    lea dx,filename
    mov ah,3Ch
    mov cx,0
    int 21h
    mov [handle],ax
wr_seek:
    ; seek al final
    mov ah,42h
    mov al,2
    xor cx,cx
    xor dx,dx
    mov bx,[handle]
    int 21h

    ; escribe usuario
    mov ah,40h
    mov bx,[handle]
    mov cl,[user_buf+1]
    xor ch,ch
    lea dx,user_buf+2
    int 21h

    ; escribe ':'
    mov ah,40h
    mov bx,[handle]
    mov cx,1
    lea dx,ch_colon
    int 21h

    ; escribe hash
    mov ah,40h
    mov bx,[handle]
    mov cx,[hex_len]
    lea dx,hex_buf
    int 21h

    ; escribe CRLF
    mov ah,40h
    mov bx,[handle]
    mov cx,2
    lea dx,crlf_bytes
    int 21h

    ; cerrar
    mov ah,3Eh
    mov bx,[handle]
    int 21h
    ret
write_record ENDP

;-------------------------------------------------
; verify_login: busca usuario y compara su hash
;-------------------------------------------------
verify_login PROC
    ; abrir para lectura
    lea dx,filename
    mov ah,3Dh
    mov al,0
    int 21h
    jc   login_fail
    mov [handle],ax

    ; leer todo
    mov ah,3Fh
    mov bx,[handle]
    mov cx,64
    lea dx,file_buf
    int 21h
    mov [file_len],ax

    ; cerrar
    mov ah,3Eh
    mov bx,[handle]
    int 21h

    ; reiniciar rec_off
    xor ax,ax
    mov [rec_off],ax

vl_search:
    ; fuera de buffer?
    mov ax,[rec_off]
    cmp ax,[file_len]
    jae login_fail

    ; comparar usuario
    lea si,file_buf
    add si,ax
    lea di,user_buf+2
    mov cl,[user_buf+1]
    xor ch,ch
    rep cmpsb
    jnz vl_next

    cmp byte ptr [si],':'
    jne vl_next
    inc si

    ; comparar hash
    lea di,hex_buf
    mov cx,[hex_len]
    rep cmpsb
    jnz vl_next

    lea dx,msg_login_ok
    mov ah,09h
    int 21h
    ret

vl_next:
    ; saltar CRLF
    lea si,file_buf
    add si,[rec_off]
  .sCR:
    cmp byte ptr [si],0Dh
    jne .iSI
    add si,2
    jmp .uOff
  .iSI:
    inc si
    jmp .sCR
  .uOff:
    mov ax,si
    sub ax,OFFSET file_buf
    mov [rec_off],ax
    jmp vl_search

login_fail:
    lea dx,msg_login_fail
    mov ah,09h
    int 21h
    ret
verify_login ENDP

    mov ah,4Ch
    int 21h
end start