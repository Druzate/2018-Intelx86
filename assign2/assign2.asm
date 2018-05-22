; 02/13/2018
; CS3140
; Assignment 2
; nasm -f elf64 -g assign2.asm
; ld -o assign2 -m elf_x86_64 assign2.o

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
        
        ;write one byte
        mov edi, 1              ; output to stdout (fd 1 = stdout)
        mov rsi, buff         ; buffer pointer
        mov rdx, 1              ; size t len, moving one byte at a time
        mov eax, 1              ; sys_write
        syscall
        
        jmp _start
        
done:
        mov eax,60              ; sys_exit
        mov edi, 0              ; exit code 0
        syscall                 