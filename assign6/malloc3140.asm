; 03/25/2018
; CS3140
; Assignment 6/Final Assignment
; nasm -f elf64 -g malloc3140.asm
; gcc -o malloc3140 malltest.c malloc3140.h malloc3140.o

; first six arguments are placed in rdi, rsi, rdx, rcx, r8, r9
; RBX, RBP, r12, r13, r14, r15  must be preserved through function calls. (push and pop or just don't use)

bits 64
%define SYS_BRK 12

;************************************************

; block header?
; 16 bytes
; first 8 bytes: size in bytes. this includes the header's 16 bytes + data
; last 8 bytes: size of previous block in bytes, including that block's header

;************************************************
; Allocate a block of memory capable of holding "size" bytes of user specified data. (size_t is 64 bit)
; If size is zero, a pointer to zero bytes of memory should be returned.
; Returns NULL on failure or pointer to new block on success.
; Must never return a pointer to a block of memory that is already in use by the program (ie previously malloc'ed but not yet free)
; Operates in O(n) time.
; ====== void *l_malloc(size_t size); ======        

        global l_malloc
        section .data
startHeap:      dq 0x0000000000000000
endHeap:        dq 0x0000000000000000
        section .bss
returnZero:     resq 1 
        section .text 
l_malloc:
        push r15
        push r14
        push r13
        push r12
        push rbp
        push rbx                ; pushing all these for safety; will be restored at the end of malloc
        cmp rdi, 0              ; is size 0?
        je return_zero_pointer
                                ; new_size = (user_size + 7) & -8; to round sz
        add rdi, 7
        and rdi, -8
        add rdi, 16             ; add required header size
        push rdi                ; store the rounded + required header size for later
        xor rdx, rdx
        mov rcx, [startHeap]
        cmp rdx, rcx
        jne heap_initialized    ; else, need to do brk system call
        
initialize_heap:
        call get_brk
        mov [startHeap], rax
        mov rdi, rax     
        add rdi, 0x20000        ; will always grow by 0x20000 or 128k
        mov [endHeap], rdi
        call set_brk            ; after this, we should have our heap reserved and have the start and end points in data!
                                ; remember, they are pointers!
        xor r8, r8
        mov r8, [startHeap]     ; r8 now has the *pointer* to the beginning of the heap
                                ; now we initialize block header for the single block
        xor r9, r9
        mov [r8 + 8], r9        ; no preceeding block, so size is 0.
        mov r9, 0x20000
        mov [r8], r9            ; since that's the initial size
                                ; and we're done!
heap_initialized:
        mov r8, [startHeap]     ; r8 now has a *pointer* the the top of the heap; the mem address
        mov r9, [endHeap]       ; r9 now has a *pointer* to the end of the heap; the mem address
        pop r10                 ; former rdi, aka size
        mov r11, 0x7fffffffffffffff     ; if a block is ever larger than this, we have bigger problems than i want to deal with. in decimal, this is 9223372036854775807
        xor rax, rax
                                ; in the following loop, r8 will be a pointer to the current block of heap we're checking
                                ; rax will hold a pointer to the current smallest fitting block we've found (or 0 while nothing found)
                                ; r11 will hold the size of said fitting block (or 0x7fffffffffffffff)
malloc_loop:
                                ; for each block
        mov r12, [r8]           ; get block size from header 
        and r12, 0xfffffffffffffffe     ; blank out the alloc in size, if any
        cmp r12, r10            ; compare block size to desired size
        jl malloc_next_iter     ; block size is smaller than desired size, not suitable
        cmp r12, r11            ; compare block size to current best block size
        jg malloc_next_iter     ; it's larger than the current best, not an improvement
                                ; else, it is a suitable size and an improvement     
        mov r12, [r8]           ; restore size                                
        mov r13, 1              ; check last bit for allocation. and with 1 to see if final bit is a 1
        and r13, r12
        cmp r13, 1              ; if this is equal, already allocated
        je malloc_next_iter
                                ; else it is suitable, improvement, and unalloc'd. we can set it as our best choice for now!         
        mov rax, r8             ; set pointer of best to current block
        mov r11, r12            ; set size of best block to current block's size
                                ; fall into malloc_next_iter
malloc_next_iter:                        
        mov r15, r8             ; r15 stores this block - soon "previous block" - for the purposes of extra brk, if necessary
        
        and r12, 0xfffffffffffffffe               
        add r8, r12             ; increment pointer to get to start of next block 
        cmp r8, r9
        jl malloc_loop          ; if it's equal, we hit the end of the heap and finished our search. fall through.

malloc_loop_done:
        cmp rax, 0
        je no_match_found       ; we're gonna need to break for additional size, possibly multiple times. :C. 
                                ; else, fall through
                                
match_found:
        mov r13, [rax]          ; block size header
        sub r13, r10            ; subtract desired size from found block
        mov r11, 24             ; minimum block size: header size (16) + 8 bytes, as a minimum allocation is 8 bytes
        cmp r13, r11            ; compare block "leftovers" to minimum block size
        jl malloc_nosplit       ; if less, leftovers are not large enough for a block. just use entire block.
                                ; r13 currently holds block leftovers; r10 holds desired size
malloc_split:
        mov [rax], r10          ; make block header specify desired size as "cut" size.
        mov [rax+r10], r13      ; make next block header specify leftovers as size
        mov [rax+r10+8], r10    ; make next block "prev" size pointer specify "cut" size.
                                ; fall through to nosplit
 malloc_nosplit:
        mov r13, [rax]          ; block size header
        add r13, 1              ; mark as allocated in size
        mov [rax], r13          ; and store it back
        add rax, 16             ; before we return pointer, WE MUST MAKE SURE TO SKIP HEADER
        jmp done_malloc         ; ok now we're good
        
        
no_match_found:                 ; reference for this one: pointer to the last block before we hit the end of the heap is in r15.
                                ; we did not find something suitable, so nothing useful in rax or r11. r8 should be end of heap pointer, as is r9. (aka current brk)
        add r9, 0x20000         ; grow by 0x20000 or 128k
        mov rdi, r9
        call set_brk            ; after this,  heap should be expanded.
        cmp rax, rdi            ; did it actually expand? 
        jne null_fail           ; if no, fail.
        mov [endHeap], rdi
                                ; now we need to check if we have a too-small tail at the end of old heap to merge with.
        mov r13, [r15]          ; get header size of "previous" block before hitting end of heap
        mov r11, 1
        and r13, r11            ; check if last bit is 1
        cmp r13, 1
        je malloc_lastb_allocated       ; it was allocated.
        
malloc_lastb_unallocated:
        mov r13, [r15]
        add r13, 0x20000        ; grow block by added size
        mov [r15], r13
        jmp no_match_found_cont ; r15 (last block in heap) stays the same!

malloc_lastb_allocated:       
        mov r13, [r15]          ; get block size
        add r15, r13            ; this should move pointer to current top of heap
        mov r11, 0x20000
        mov [r15], r11      ; size of new block
        mov [r15+8], r13        ; size of previous block
                                ; fall through to cont of loop with new r15
no_match_found_cont: 
        mov r13, [r15]          ; check - block size large enough now?
        cmp r13, r10
        jl no_match_found       ; if n, do this again
        mov rax, r15            ; if y, move to rax, then act as if match was originally found
        jmp match_found

null_fail:
        mov rax, 0
        
done_malloc:
        pop rbx
        pop rbp
        pop r12
        pop r13
        pop r14
        pop r15
        ret

return_zero_pointer:
        mov rax, returnZero
        jmp done_malloc

;************************************************
; Release the memory pointed to by ptr. 
; ptr may be NULL in which case no action is taken. 
; Operates in O(1) time.
; ====== void l_free(void *ptr); ======
        global l_free
        section .text 
l_free:        
        push r15
        push r14
        push r13
        push r12
        push rbp
        push rbx                ; pushing all these for safety; will be restored at the end 
        mov r9, [endHeap]       ; pointer to end of heap
        cmp rdi, 0              ; is the pointer null
        je done_free
        cmp rdi, returnZero     ; is the pointer the 0th case
        je done_free

unmark_allocation:
        sub rdi, 16             ; to get to ACTUAL block top, which is 16 bytes beforehand, the header
        mov r13, [rdi]
        and r13, 0xfffffffffffffffe              ; remove allocation bit. 
        mov [rdi], r13          ; then fall through
        
is_prev_mergable:
        mov r15, rdi            ; copy pointer
        mov r14, [rdi+8]        ; copy previous block's size
        cmp r14, 0              ; is prev block 0? we're at the start of the list
        je is_next_mergable
        sub r15, r14            ; move pointer over to previous block
        mov r14, [r15]          ; check prev block's size
        mov r12, 1              ; now check last bit for allocation. and with 1 to see if final bit is a 1
        and r14, r12
        cmp r14, 1              ; if this is equal, already allocated
        je is_next_mergable     ; else....
merge_prev:
        mov r14, [r15]          ; get prev's size
        add r14, r13            ; add current's size to merge
        mov [r15], r14
        mov rdi, r15            ; and make it the current block

is_next_mergable:  
        mov r15, rdi            ; copy pointer
        mov r14, [rdi]          ; copy own size
        add r15, r14            ; increment to next block
        cmp r15, r9             ; did we hit the end of the heap?
        jge done_free           ; if so, exit. we're done. else...
        mov r13, [r15]          ; check next block's size
        mov r12, 1              ; now check last bit for allocation. and with 1 to see if final bit is a 1
        and r13, r12
        cmp r13, 1              ; if this is equal, already allocated
        je update_next          ; if it is allocated, still need to update it in case prev was merged. fall through
merge_next:      
        mov r14, [r15]          ; get next block's size again
        mov r13, [rdi]          ; get current block's size
        add r13, r14            ; add em
        mov [rdi], r13          ; stick it back in current block. merged. fall through.
        
update_next:
        mov r13, [rdi]
        add rdi, r13
        mov r12, [endHeap]
        cmp rdi, r12
        je done_free
        mov [rdi+8], r14        ; r14 still has that size. just stick it in the appropriate location
        
done_free:
        pop rbx
        pop rbp
        pop r12
        pop r13
        pop r14
        pop r15
        ret



;************************************************
; _brk functions, transplanted here. No longer global.

; C prototypes: void *set_brk(void *new_brk);
; C prototypes: void *get_brk();

get_brk:
   xor rdi, rdi        ; set a brk increment of 0 to induce failure and learn current break
   ; just drop into set_break to finish the brk call

set_brk:
   ; The argument to brk is the address of the new brk
   ; this should be in rdi on entry
   mov eax, SYS_BRK    ; brk syscall returns new break on success or curent break on failure
   syscall
   ret
   