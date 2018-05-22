; 02/27/2018
; CS3140
; Assignment 3_part1
; nasm -f elf64 -g assign3_part1.asm
; ld -o assign3_part1 -m elf_x86_64 assign3_part1.o

bits 64

section .bss     
        buff resb 1

section .text    

global _start

_start:
        
        ;read one byte
        mov edi, 0              ; int fd (fd 0 = stdin)
        mov rsi, buff           ; char *buffer
        mov rdx, 1              ; size t len; we're moving one byte at a time
        mov eax, 0              ; set sys_read code
        syscall                 ; do the actual read
        
        cmp rax, 1              ; if true, more bytes available. else, false
        jne done
        
        mov r13d, [buff]
        mov r14d, [buff]
        mov r15d, [buff]
        shr r14d, 4               ; get top 4 bits
        shl r15d, 28
        shr r15d, 28               ; get bottom 4 bits (shift twice)
     
        mov bl, [map+r14d]       ; convert to ascii of the hex using the map
        ;write first byte
        mov [buff], bl
        mov edi, 1              ; output to stdout (fd 1 = stdout)
        mov rsi, buff           ; buffer pointer
        mov rdx, 1              ; size t len, moving one byte at a time
        mov eax, 1              ; sys_write
        syscall

        mov bl, [map+r15d]       ; convert to ascii of the hex using the map
        ;write second byte
        mov [buff], bl
        mov edi, 1              ; output to stdout (fd 1 = stdout)
        mov rsi, buff           ; buffer pointer
        mov rdx, 1              ; size t len, moving one byte at a time
        mov eax, 1              ; sys_write
        syscall
        
        ;write space
        mov dl, [blank]
        mov [buff], dl
        mov edi, 1              ; output to stdout (fd 1 = stdout)
        mov rsi, buff           ; buffer pointer
        mov rdx, 1              ; size t len, moving one byte at a time
        mov eax, 1              ; sys_write
        syscall
        
        cmp r13d, 10            ; check if the character was a newline
        jne _start
        
done:
        mov eax,60              ; sys_exit
        mov edi, 0              ; exit code 0
        syscall   


section .data
        map: db "0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"
        blank: db " "