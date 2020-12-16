; Executable name : hexdump
; Version : 1.0
; Created date : December 16, 2020
; Updated date : December 16, 2020
; Author : Olga Agafonova
; Description : An exercise from the "Assembly Language Step-by-Step" book
;
; Build using these commands or use the makefile:
; nasm -f elf -g -F stabs hexdump.asm
; ld -o hexdump hexdump.o
;
; Run it like this:
;
; ./hexdump < inputfile.txt
; 
; The input file should contain plain text. The program will generate a hex dump of the text -
; each char is converted to binary and then to hex.
;
; For example, g is 01100111 in binary. In hex, that is 67.


section .bss ; Section containing uninitialized data

    BUFFLEN equ 16          ; We read the file 16 bytes at a time
    Buff: resb BUFFLEN      ; Text buffer itself

section .data               ; Section containing initialized data

    HexStr: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",10
    HEXLEN equ $-HexStr
    Digits: db "0123456789ABCDEF"

section .text

global _start

_start:

nop                          ; keeps the debugger happy

                             ; Read a buffer full of text from stdin
Read:   mov eax, 3           ; Specify sys_read call
        mov ebx, 0           ; Specify file descriptor 0 - standard input
        
                             ; Setup registers to read from the buffer
        mov ecx, Buff        ; Pass address of the buffer to read to
        mov edx, BUFFLEN     ; Tell sys_read to read one char from input
        int 80h              ; Call sys_read
        mov ebp, eax         ; Save number of bytes read from file for later
        cmp eax, 0           ; If eax=0, sys_read reached EOF in stdin
        je Done
        
                            
        mov esi, Buff        ; Place the address of buffer into esi
        mov edi, HexStr      ; Place the address of line string into edi
        xor ecx, ecx         ; Clear line string pointer to 0

                             ; Go through the buffer and convert binary values to hex digits:
Scan:
        xor eax,eax          ; Clear eax to 0
                             ; Calculate offset into HexStr, which is the value in ecx * 3
        mov edx, ecx         ; Copy the character counter into edx
        shl edx, 1           ; Multiply pointer by 2 using left shift
        add edx, ecx         ; Complete the multiplication by 3
        
                                   ; Get a character from the buffer and put it in both eax and ebx
        mov al, byte [esi+ecx]     ; Put a byte from input buffer into al
        mov ebx, eax               ; Copy the byte in bl for the second nybble; nybble = 4 bits
        
                                   ; Look up the low nybble and insert it into the string
        and al, 0Fh                ; Mask out all but the low nybble
        mov al, byte[Digits+eax]   ; Lookup the char equivalent of nybble
        mov byte[HexStr+edx+2], al ; Write LSB (least significant bit) char digit to line string
        
                                   ; Look up high nybble character and insert it into the string
        shr bl,4                   ; Shift high 4 bits of char into low 4 bits
        mov bl,byte [Digits+ebx]   ; Look up char equivalent of nybble
        mov byte [HexStr+edx+1],bl ; Write MSB (most significant bit) digit to line string
        
                                   ; Bump the buffer pointer to the next character and see if we’re done
        inc ecx                    ; Increment line string pointer
        cmp ecx,ebp                ; Compare to the number of chars in the buffer
        jna Scan                   ; Loop back if ecx is <= number of chars in buffer
                             
                                   ; Write the hex result to stdout
        
        mov eax,4                  ; Specify sys_write call
        mov ebx,1                  ; Specify file descriptor 1: standard output
        mov ecx,HexStr             ; Pass offset of line string
        mov edx,HEXLEN             ; Pass size of the line string
        int 80h                    ; Make kernel call to display line string
        jmp Read                   ; Loop back and load file buffer again

Done:
        mov eax,1                  ; Code for exit syscall
        mov ebx,0                  ; Return a code of zero
        int 80H                    ; Make kernel call


