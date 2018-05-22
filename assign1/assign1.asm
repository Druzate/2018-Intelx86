; 02/07/2018
; CS3140
; Assignment 1
; nasm -f elf64 -g assign1.o
; ld -o assign1 -m elf_x86_64 assign1.o

bits 64

section .text                           ;section declaration

global _start

_start:
        mov edx, 19                     ; original size of array and outer loop counter
        mov edi, 0                      ; will eventually be "passes"
        mov esi, 0                      ; keep track of current swaps (temp var)
outerloop:
        mov ecx, 0                      ; inner loop counter
        inc edi                         ; passes++                     
innerloop:                              
        mov eax, [array + ecx * 4]      ; because each double is 4 bytes
        mov ebx, [array + 4 + ecx * 4]
        cmp eax, ebx                    ; eax - ebx, set flags on result
        jge next                        ; change #1 - jump on greater or equal
        mov [array + ecx * 4], ebx      ; else, swap
        mov [array + 4 + ecx * 4], eax
        inc esi                         ; since we swapped, swaps++
next:
        inc ecx                         ; increment exc
        cmp ecx, edx                    ; compare ecx to size of current loop compare
        jl innerloop                    ; if less than, jump back to inner bubble sort loop
endinner:                               ; else
        cmp esi, 0                      ; if temp swaps are 0...
        jz pass_set                         ; array is sorted, since no swaps were performed this pass. go to cleanup
        mov ebp, [swaps]                ; else, time to add to total swaps
        add ebp, esi                        ; ebp = ebp + esi
        mov [swaps], ebp                    ; swaps = previous swaps + temp swaps
        mov esi, 0                          ; reset temp swaps
        dec edx                             ; decrement outer loop counter - the last entry is now confirmed largest
        jnz outerloop                       ; jump back to top of outer loop if nonzero
pass_set:        
        mov [passes], edi
        mov edx, 20
        mov ecx, 0
outputloop:        
        mov eax, [array + ecx * 4]      ; move array[i] to register
        mov [output + ecx * 4], eax     ; move register to output[i]
        inc ecx                         ; increment exc
        cmp ecx, edx                    ; see if we've reached end of array yet
        jl outputloop                    ; if not, repeat loop
done:
        mov edi, [swaps]                ;first syscall argument: exit code
        mov eax,60                      ;system call number (sys_exit)
        syscall                         ;"trap" to kernel
        
section .data                           ;section declaration

; This variable must remain named exactly 'array'
array: dd 7, 11, 4, 5, 19, 20, 8, 10, 9, 15, 6, 16, 12, 3, 2, 17, 14, 13, 1, 18
passes: dd 0
swaps: dd 0

section .bss
output: resb 20