; 03/09/2018
; CS3140
; Assignment 4, aka I hate register alignment+access issues
; nasm -f elf64 -g start.asm
; nasm -f elf64 -g assign4.asm
; gcc -o assign4 main.c assign4.o start.o -nostdlib -nodefaultlibs -fno-builtin -nostartfiles

; first six arguments are placed in rdi, rsi, rdx, rcx, r8, r9
; RBX, RBP, r12, r13, r14, r15  must be preserved through function calls. (push and pop or just don't use)

;************************************************ WORKING
; int l_strlen(char *str);
; Return the length of the null terminated string, str. The null character should not be counted.
        global l_strlen
        section .text 
l_strlen:
        mov rax, 0              ; rax = 0
l_strlen_loop:
        mov cl, [rdi + rax]
        cmp cl, 0               ; compare [rdi + rax*4] to null
        je l_strlen_end         ; if null jump to l_strlen_end
        inc rax                 ; rax++
        jmp l_strlen_loop       ; jump to l_strlen_loop
l_strlen_end:
        ret                     ; return (length should already be in rax by virtue of this setup)
        
;************************************************ WORKING
; int l_strcmp(char *str1, char *str2);
; Return 0 if str1 and str2 are equal, return 1 if they are not. Note that this is not the same definition as the C standard library function strcmp.
        global l_strcmp
        section .text 
l_strcmp:
        push rbx
        mov r8, 0
        mov rax, 0
l_strcmp_loop:
        mov cl, [rdi + r8]      ; move [rdi + r8] to cl
        mov bl, [rsi + r8]      ; move [rsi + r8] to bl
        inc r8
        cmp cl, bl
        jne l_strcmp_end        ; if not equal jump to l_strcmp_end
        cmp bl, 0               ; compare to null
        jne l_strcmp_loop       ; if not equal jump to l_strcmp_loop; not at end yet
        pop rbx
        ret                     ; else, all compared and all equal - return
l_strcmp_end:
        pop rbx
        mov rax, 1              ; stuff was compared and found something NOT equal!!
        ret

        
;************************************************ WORKING
; int l_gets(int fd, char *buf, int len);
; Read at most len bytes from file fd, placing them into buffer buf. Terminate early if a new line character ('\n', 0x0A) characters is read. If a new line character is encountered, it should be stored into the output buffer and counted in the total number of bytes read. Return the total number of bytes read (which may be zero if end of file is reached or an error occurs). This function must place a null termination character after the last character read. The null termination character is not counted as part of the return count.
        global l_gets
        section .text 
l_gets:
        push r15
        push r14
        push r13      
        push r12      
        mov r15, rdx            ; len
        mov r14, 0              ; result len
        mov r13, rdi            ; fd
        mov r12, rsi            ; buff
l_gets_loop:        
        cmp r14, r15           ; compare len and result len
        je l_gets_end
        mov rdi, r13            ; set filestream
        mov rsi, r12            ; set buff
        mov rdx, 1              ; size t len; we're moving one byte at a time
        mov eax, 0              ; set sys_read code
        syscall                 ; do the actual read
        
        cmp rax, 1              ; if true, more bytes available. else, false
        jne l_gets_end
        
        inc r14
        mov bl, [r12]
        cmp bl, 10              ; compare to newline
        je l_gets_end
        
        add r12, 1              ; since we're moving one byte at a time, increment buffer pointer position
        jmp l_gets_loop

l_gets_end:
        mov r9, 0               ; now we need to null-terminate
        mov [r12+1], r9          
        mov rax, r14
        pop r12
        pop r13
        pop r14
        pop r15
        ret

        
;************************************************ WORKING
; void l_puts(const char *buf);
; Write the contents of the null terminated string buf to stdout (file descriptor 1). The null byte must not be written. If the length of the string is zero, then no bytes are to be written.
        global l_puts
        section .text 
l_puts:
        push r15
        push rbx
        mov r15, rdi            ; = rdi (aka buff)
        
l_puts_loop:
        xor rbx, rbx
        mov rbx, [r15]
        cmp bl, 0               ; cmp [r15] to null byte
        je l_puts_end           ; if equal, jump to l_puts_end
        mov edi, 1              ; output to stdout (fd 1 = stdout)
        mov rsi, r15            ; buffer pointer
        mov rdx, 1              ; size t len, moving one byte at a time
        mov eax, 1              ; sys_write
        syscall
        inc r15
        jmp l_puts_loop

l_puts_end:
        pop rbx
        pop r15
        ret


;************************************************ WORKING(? not thoroughly tested. -1 case?)   
; int l_write(int fd, char *buf, int len);
; Write len bytes from buffer buf to file fd. Return the number of bytes actually written or -1 if an error occurs.
        global l_write
        section .text 
l_write:
        push r15
        push r14
        push r13      
        push r12      
        mov r15, rdx             ; len
        mov r14, 0               ; result len
        mov r13, rdi             ; fd
        mov r12, rsi             ; buff
        
l_write_loop:
        cmp r14, r15          ; compare len and result len
        je l_write_end
        mov rdi, r13            ; set filestream
        mov rsi, r12            ; set buff
        mov rdx, 1              ; size t len; we're moving one byte at a time
        mov eax, 1              ; set sys_read code
        syscall                 ; do the actual read
        
        cmp rax, 1              ; if true, more bytes available. else, false
        jne l_write_end
        
        inc r14
        
        add r12, 1              ; since we're moving one byte at a time, increment buffer pointer position
        jmp l_write_loop

l_write_end:
        mov rax, r14
        pop r12
        pop r13
        pop r14
        pop r15
        ret

;************************************************ WORKING
; int l_open(const char *name, int flags, int mode);
; Opens the named file with the supplied flags and mode. Returns the integer file descriptor of the newly opened file or -1 if the file can't be opened.
        global l_open
        section .text 
l_open:
        ; rdi already has name
        ; rsi already has flags
        ; rdx already has mode
        mov eax, 2
        syscall
        ; returns file handle, or -1 if error. already in rax, no need to move
        ret

;************************************************ WORKING(? not thoroughly tested)
; int l_close(int fd);
; Close the indicated file. Returns 0 on success or -1 on failure.
        global l_close
        section .text 
l_close:
        ; rdi already has filehandle
        mov eax, 3
        syscall
        ; returns 0 on success or -1 on failure. already in rax, no need to move
        ret

;************************************************ WORKING
; unsigned int l_atoi(char *value);
; Perform an ASCII to decimal conversion of the decimal number contained in value. Valid characters in value include ‘0’..’9’. ANY other character is considered invalid. Your function must return the 4-byte, little endian representation of all consecutive decimal digits from the beginning of the string. You must stop the conversion when any character other than ‘0’..’9’ are reached (including the null termination byte). If the very first character in the string is invalid you must return 0. 
        global l_atoi
        section .text 
l_atoi:
        push r15
        push rbx
        mov r15, 0
        mov r8, 0
l_atoi_loop:
        xor rbx, rbx
        mov bl, [rdi+r8]        ; move single byte from "value" to bl
        inc r8                  ; r8++ for next loop
        mov cl, [zero]
        cmp bl, cl
        jl l_atoi_end          ; if < '0', invalid, jump to end
        mov cl, [nine]
        cmp bl, cl
        jg l_atoi_end          ; if > '9', invalid, jump to end
        ; otherwise.... '0' is 48, etc...
        sub bl, 48              ; so now you should have the number in decimal form.
        mov rax, 10             ; to mult by 10
        mul r15                 ; here's the interesting bit - have to shift current number by one base. (mult by 10)
        mov r15, rax            ; ^ ax = ax * rax
        add r15, rbx            ; now you can add bl to result
        jmp l_atoi_loop
l_atoi_end:
        mov rax, r15
        pop rbx
        pop r15
        ret                     ; result should be in rax, even if just 0. return. 
        
        section .data
zero db '0'
nine db '9'

;************************************************ oh god i can't believe it works
; char *l_itoa(unsigned int value, char *buffer);
; Perform the decimal to ASCII conversion of value, placing the null terminated ASCII content into buffer. You may assume that buffer is of sufficient size to hold all required characters including the null terminator (minimum of 10 bytes). This function should return a pointer to the generated buffer (ie return buffer). 
        global l_itoa
        section .text 
l_itoa:
        push r15
        push rbx
        mov r15, rsi    ; r15 is now buffer pointer
        mov r8, 0
        mov rax, rdi    ; rax/ax now holds value
l_itoa_loop:
        xor rdx, rdx
        cmp rax, 0
        je l_itoa_reverse               ; done with entire number; else -
        mov rdx, 0                      ; divide rax/ax by ten
        mov rbx, 10             
        div bx                          ; rax/10. dx now holds remainder, ax holds quotient. leave quotient in rax/ax
        add dx, 48                      ; take remainder and add 48 to convert to ascii
        mov [r15+r8], dx                ; put remainder ascii in buff[r8]
        inc r8                          ; r8++
        jmp l_itoa_loop        
l_itoa_reverse:
        ; okay now we gotta reverse the string
        ; first put in the null byte
        mov r9, 0                       ; r9 = 0
        mov [r15+r8], r9                ; buff[r8] (since already increment) = 0
        dec r8                          ; r8--
l_itoa_reverse_loop:
        cmp r8, r9                      ; cmp r8, r9
        jle l_itoa_end                  ; if r8 <= r9, jump to end
        mov bl, [r15+r8]               ; move buff[r8] to r10
        mov cl, [r15+r9]               ; move buff[r9] to r11
        mov [r15+r8], cl               ; move rll to buff[r8]
        mov [r15+r9], bl               ; move r10 to buff[r9]
        dec r8                          ; r8--
        inc r9                          ; r9++
        jmp l_itoa_reverse_loop         ; jump to reverse_loop
l_itoa_end:
        mov rax, r15    ; return original buffer pointer
        pop rbx
        pop r15
        ret

;************************************************ WORKING(? not thoroughly tested for randomness but it doesn't break)
; unsigned int l_rand(unsigned int n);
; Generate a random number in the range 0..n-1 inclusive using the following process:
        global l_rand
        section .text 
l_rand:
; 1. Open "/dev/urandom" (perhaps using l_open)
        push rdi                ; push unsigned int n
        mov rdi, urandom        ; '/dev/urandom'
        mov rsi, 0              ; O_RDONLY
        mov rdx, 0              ; mode
        mov eax, 2              ; open file
        syscall
        mov r8, rax             ; get fd into r8
; 2. Read 4 bytes from the open file (these will be a random number in the range 0..0xffffffff). Call this number: r.
        mov rdi, r8             ; set filestream
        mov rsi, buff           ; set buff
        mov rdx, 4              ; size t len; we want 4 bytes
        mov eax, 0              ; set sys_read code
        syscall                 ; do the read
; 3. Close the open file.
        mov rdi, r8             ; move fd into arg
        mov eax, 3              ; close file
        syscall
; 4. Return r % n. 
        mov rdx, 0     
        mov ax, [buff]          ; r
        pop rbx                 ; n; if I don't pop this the same way i put it in, it breaks, bcs the stack now has an incorrectly aligned return pointer. things u don't think about until they fuck u over
        div bx                  ; r/n. dx now holds modulus, ax holds quotient
        mov rax, rdx
        ret                     ; segfaults on return? wait nvm FUCKING BYTE ALIGNMENTS

        section .data
urandom db '/dev/urandom'
        section .bss     
buff resb 4

;************************************************
; void l_exit(int rc);
; Terminate the calling program with exit code rc.
        global l_exit
        section .text 
l_exit:        
        mov eax, 60              ; sys_exit
        ; mov edi, 0    - no need, exit code is already in rdi/"rc"
        syscall  
