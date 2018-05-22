README

Initial commentary/thoughts on this project [NO LONGER AVAILABLE] at the bottom of the asm file. A summarized and updated version is here.

The header of each block is 16 bytes. The first 8 bytes store the current block's size, including the header's 16 bytes. The second 8 bytes store the previous block's size, again including that block's header. Additionally, the last bit of the first 8 bytes (the size) is used to indicate whether the block is allocated or not. If it is 1, the block is allocated; if it is 0, the block is free. (Printed in decimal, this means an odd number indicates allocation, while an even one indicates the block is free.)

Each time an allocation request is made, the code loops through the current heap, searching for a best-fit. If it has found nothing by the time it reaches the end of the heap, there is not enough room to satisfy the request, and the heap must grow. The code does this in set_brk syscalls of 0x20000 bytes at a time. After each syscall, it first (if applicable, ie the former last block in the heap was unallocated) merges with the former last block, then checks if the current last block in the heap is large enough to satisfy the request. If not, it performs another set_brk; rinse and repeat until there is either enough room or increasing the heap fails.

l_free goes through several steps to merge blocks. 
First, it frees the current block; then it checks the second 8 bytes of the header. It uses this to move to the previous block - if one exists - and check if it is unallocated. If it is, it adds the size of the current block (rendering the current block's header garbage), then sets the previous block to be the current one.
Whether or not a merge occured, it next jumps to the next block. If one exists, it checks if it is unallocated. If it is, it adds its size to the current block's size. (Again, the header is made garbage.)
Regardless of any of the above, it once again jumps to the block that is now after the current block. There, it updates the second 8 bytes of the header - the ones that specify the previous block's size. (If the current block was freed but could not merge with anything, this "update" will store the same data as was there before.)

The gcc command in the comments at the top of the asm builds the last test from my test code, malltest.c. Previous tests are included in a block comment at the bottom of malltest.c. In short, I performed the following tests and observed memory to ensure correctness:
1. single malloc, within original bounds
2. triple malloc, within original bounds
3. double malloc, second breaking bounds once (requiring one extra set_brk)
4. double malloc, second breaking bounds several times (requiring multiple set_brks)
5. double malloc and free
6. double malloc and double free
7. double malloc, free, and malloc fitting within the freed block
8. double malloc, free, two mallocs fitting within freed block, two frees - testing merging both sides