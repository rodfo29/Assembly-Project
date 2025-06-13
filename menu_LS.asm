


    



inicio:                   
     mov dx,offset menu
     mov ah,09h
     int 21h              
                       
    ; Mostrar de input al usuario
    mov dx, offset mensaje
    mov ah, 09h
    int 21h

    ; Leer un car�cter (un d�gito) -> se guarda en al como ascii
    mov ah, 01h
    int 21h     
    
    ; como vamos ah operar con al para mantener seguro nuestro resultado lo guardamos en otro registro como el bl
    mov bl,al
    
    ; pasamos el valor de ascii -> numero
    sub bl,'0'                            
    
    
    
    ; verificamos si es la primera opcion del menu.
    cmp bl,1
    je primer_menu  ; saltamos a la etiqueta de la primera opcion.
    
    ; verificamos si es la segunda opcion del menu.
    cmp bl,2
    je segundo_menu
    
    ; verificamos si es la tercera opcion del menu.
    cmp bl,3
    je tercer_menu   
    
    ;verificamos si es la cuarta opcion del menu.
    cmp bl,4
    je cuarto_menu
                  
    ;verificamos si es la quinta opcion del menu.
    cmp bl,5
    je quinto_menu
    ;verificamos si es la sexta opcion del menu.
    cmp bl,6
    je sexto_menu       
    
    ;verificamos si el usuario quiere salir de la aplicacion.
    cmp bl,7
    je fin_programa
                     
                     
                     
    ; mandamos mensaje de error en caso de que el usuario ingrese una opcion no valida
    cmp bl,7
    jg opcion_invalida ; Input superior al mayor valor de opciones disponibles
    
    ; mandamos mensaje de error en caso de que el usuario ingrese una opcion no valida
    cmp bl,0
    jle opcion_invalida ; Input inferior al menor valor de opciones disponibles
    
    
    
    
      ; ============= Etiquetas =============
      
      
    ; codigo correspondiente a la primera opcion del menu
    primer_menu:     
    
           
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset primer_opcion
        mov ah,09h
        int 21h
        
        call es_par_impar ; llamamos a la subrutina para verificar si el numero es par o impar
        
        call delay
        
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start
    
    ; codigo correspondiente a la primera opcion del menu
    segundo_menu:   
                  
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset segunda_opcion ; mostramos la bienvenida a la opcion actual
        mov ah,09h
        int 21h
        
        mov dx,offset mensaje ; solicitamos el numero al usuario
        int 21h 
        
        mov ah,01h ; obtenemos el input del usuario en ascii
        int 21h                                             
        
        mov bl,al
        sub bl,'0'
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start 
        
    tercer_menu:
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset tercera_opcion
        mov ah,09h
        int 21h
        
        mov dx,offset mensaje
        int 21h 
        
        mov ah,01h
        int 21h 
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start
               
     
     cuarto_menu:
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset cuarta_opcion
        mov ah,09h
        int 21h
        
        mov dx,offset mensaje
        int 21h 
        
        mov ah,01h
        int 21h 
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start
        
        
      quinto_menu:
        
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset quinta_opcion
        mov ah,09h
        int 21h
        
        mov dx,offset mensaje
        int 21h 
        
        mov ah,01h
        int 21h 
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start
        
        
      
        sexto_menu:
        
        call limpiar_pantalla ; Limpiamos la pantalla del menu.
        mov dx,offset sexta_opcion
        mov ah,09h
        int 21h
        
        mov dx,offset mensaje
        int 21h 
        
        mov ah,01h
        int 21h 
        
        call limpiar_pantalla ; limpiamos la pantalla antes de volver al menu
        
        
        
        jmp start    
        
    fin_programa:  
               
    
        
        mov dx,offset mensaje_despedida
        mov ah,09h
        int 21h
        
        mov ah,4ch
        int 21h      
        
     
    
     opcion_invalida:
                 
        
        mov dx,offset mensaje_error
        mov ah,09h
        int 21h
        
        
        jmp start
                   
                   
                   
                   
                   
                   
         
         ; ============= Subrutinas1 =============
         
         
         
         
        ; esta funcion nos permitira limpiar la pantalla cada vez que ingresemos a una opcion en el menu.
       limpiar_pantalla proc
            mov ah, 06h     ; funci�n scroll up
            mov al, 0       ; 0 = limpiar toda la pantalla
            mov bh, 07h     ; atributo: blanco sobre negro
            mov cx, 0       ; esquina superior izquierda (fila 0, col 0)
            mov dx, 184Fh   ; esquina inferior derecha (fila 24, col 79)
            int 10h         ; interrupci�n BIOS
            ret
       limpiar_pantalla endp 
       
        ; subrutina encargada de verificar si un numero es par o impar
        es_par_impar proc 
             mov dx,offset mensaje ; solicitamos el numero al usuario
             mov ah,09h
             int 21h 
        
             mov ah,01h ;obtenemos el input del usuario en ascii
             int 21h         
        
             mov bl,al
             sub bl,'0' ;convertimos el valor de ascii a numero : ascii -> numero
             
             and bl,1 ; la operacion tiene 2 resultados posibles: 1 -> impar / 0 -> par 
             
             cmp bl,0 ; verificamos si el numero es par
             je esPar
             
            
             ; en caso de que no se cumpla la condicion el numero es impar
             mov dx,offset es_impar
             mov ah,09h
             int 21h
             ; retornamos al flujo de la subrutina
             
             
             esPar: 
             
                mov dx,offset es_par ; mostramos por pantalla el mensaje de que el numero es par
                mov ah,09h
                int 21h
                ret ; retornamos al flujo de la subrutina
                
                
          
          es_par_impar endp   
             
             
          ; subrutina encargada de congelar el menu un tiempo antes de ejecutar la siguiente instruccion
          delay proc
                push cx         ; cargamsoe en la pila el valor de cx  "prestando temporalmente" para que la subrutina lo use sin afectar el resto del programa.

                mov cx, 0c8h    ; valor grande para hacer una pausa (ajustable)
                espera:
                nop             ; instrucci�n que no hace nada (opcional)
                loop espera     ; CX se decrementa hasta 0

                pop cx          ; obtenemos el valor que tenia cx previamente ser usado en la subrutina, de esta manera no afectamos a otras partes del programa.
                ret
          delay endp   
             
            
            
    

   
    

END