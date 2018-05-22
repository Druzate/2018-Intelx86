; 02/28/2018
; CS3140
; Assignment 3_part 2
; nasm -f elf64 -g assign3_part2.asm
; gcc -o assign3_part2 assign3_part2.o


bits 64


section .text 

global main             ; Allow gcc to find our function
                        ; int main(int argc, char *argv[], char *envp[]);

extern printf           ; tell nasm which c library functions
extern exit

main:
        mov r15, rsi    ; get argv pointer
        xor r13, r13
        
printloop:
        
        mov eax, 0
        mov rdi, [r15 + r13*8]
        cmp rdi, 0                      ; if we hit a 0, it's the end of the argvs
        je envloop                      
        call printf
        
        mov eax, 0
        mov rdi, newline
        call printf
        
        inc r13
        jmp printloop
        
envloop:
        inc r13         ; because the last pointer pointed to 0, the end of the argv. inc again
        mov eax, 0
        mov rdi, [r15 + r13*8]
        cmp rdi, 0      ; test here too; the end of the env variables is also a 0
        je exitprog
        call printf
        
        mov eax, 0
        mov rdi, newline
        call printf
        
        jmp envloop
        
exitprog:               ; and exit
        xor rdi, rdi    ; return value 0
        call exit
        
section .data 
        newline: db 10