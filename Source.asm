extrn GetStdHandle  :proc,
      lstrlenA      :proc,
      WriteConsoleA :proc,
      ReadConsoleA  :proc,
      ExitProcess   :proc

.data
hStdOutput DQ ?
hStdInput DQ ?

sum DQ ?

St1 DB 'a = ', 0
St2 DB 'b = ', 0
St3 DB '27 + a + b = ', 0
St4 DB 'Invalid character', 13, 10, 0
St5 DB 'Press any key to exit...', 0
St6 DB 'Number out of range', 13, 10, 0

.code

STACKALLOC macro arg
    push R15
    mov R15, RSP
    sub RSP, 8*4
    if arg
      sub RSP, 8*arg
    endif
    and SPL, 0F0h
endm


NULL_FIFTH_ARG macro
    mov qword ptr [RSP + 32], 0
endm


STACKFREE macro
    mov RSP, R15
    pop R15
endm

PrintString proc uses RAX RCX RDX R8 R9 R10 R11, string: qword
    local bytesWritten: qword

    STACKALLOC 1

    mov RCX, string
    call lstrlenA

    mov RCX, hStdOutput
    mov RDX, string
    mov R8, RAX
    lea R9, bytesWritten

    NULL_FIFTH_ARG

    call WriteConsoleA

    STACKFREE

    ret
PrintString endp


ReadStringToNumber proc uses RBX RCX RDX R8 R9
    local readStr[64]: byte, bytesRead: dword

    STACKALLOC 2

    mov RCX, hStdInput
    lea RDX, readStr
    mov R8, 64
    lea R9, bytesRead
    NULL_FIFTH_ARG

    call ReadConsoleA

    xor RCX, RCX

    mov ECX, bytesRead

    sub ECX, 2

    ;---------------
    push RCX

    check_minus:
        mov AL, readStr[RCX]
        cmp AL, '-'
        jz error
        loop check_minus

    pop RCX
    ;------------------

    xor RBX, RBX
    mov R8, 1

    m_StringScan:
        dec RCX
        cmp RCX, -1

        jz scanningComplete

        xor RAX, RAX

        mov AL, readStr[RCX]

        cmp al, '-'
        jz AlIsMinus

        jmp eval


    eval:
        cmp AL, 30h
        jl error
        cmp AL, 39h
        jg error

        sub RAX, 30h
        mul R8
        add RBX, RAX
        mov RAX, 10
        mul R8
        mov R8, RAX
        jmp m_StringScan


    error:
        mov R10, 1
        STACKFREE
        ret 8


    scanningComplete:
        mov R10, 0
        mov RAX, RBX
        STACKFREE
        ret 8


    AlIsMinus:
        neg RBX
        jmp scanningComplete

ReadStringToNumber endp


PrintValue proc uses RAX RCX RDX R8 R9 R10 R11
    ;STEP 1
    local numberStr[22]: byte

    ;STEP 2
    xor R8, R8

    ;STEP 3
    mov RAX, sum

    ;STEP 4
    bt sum, 63

    ;STEP 5
    jnc SumIsNotMinus

    mov numberStr, '-'
    inc R8
    neg RAX

    SumIsNotMinus:

    ;STEP 6
    mov RBX, 10

    ;STEP 7
    xor RCX, RCX

    ;STEP8
    Delenie:
        xor RDX, RDX

        ;STEP 9
        div RBX
        add RDX, 30h

        ;STEP 10
        push RDX
        inc RCX

        ;STEP 11
        cmp RAX, 0

        ;STEP 12
        jnz Delenie

    ;STEP 13
    PerenosVStek:
        pop RDX
        mov numberStr[R8], DL

        ;STEP 14
        inc R8
        loop PerenosVStek

    ;STEP 15
    mov numberStr[R8], 13
    mov numberStr[R8+1], 10
    mov numberStr[R8+2], 0

    ;STEP 16
    lea RAX, numberStr
    push RAX

    ;STEP 17
    call PrintString

    ;STEP 18
    ret 8
PrintValue endp


WaitAns proc uses RAX RCX RDX R8 R9 R10 R11
    ;STEP 1
    local readStr: byte, bytesRead: dword

    ;STEP 2
    STACKALLOC 1

    ;STEP 3
    lea RAX, St5
    push RAX

    ;STEP 4
    call PrintString

    ;STEP 5
    mov RCX, hStdInput
    lea RDX, readStr
    mov R8, 8
    lea R9, bytesRead
    NULL_FIFTH_ARG

    ;STEP 6
    call ReadConsoleA

    ;STEP 7
    STACKFREE
    ret
WaitAns endp


Start proc
    ;STEP 1
    sub RSP, 8*6


    ;STEP 2
    STD_OUTPUT_HANDLE equ -11
    mov RCX, STD_OUTPUT_HANDLE


    ;STEP 3
    call GetStdHandle


    ;STEP 4
    mov hStdOutput, RAX


    ;STEP 5
    STD_INPUT_HANDLE equ -10
    mov RCX, STD_INPUT_HANDLE

    call GetStdHandle
    mov hStdInput, RAX


    ;STEP 6
    lea RAX, St1
    push RAX
    call PrintString


    ;STEP 7
    call ReadStringToNumber


    ;STEP 8
    cmp R10, 1
    jz exit_error


    ;++++
    cmp RAX, -128
    jl error_range
    cmp RAX, 127
    jg error_range


    ;STEP 9
    push RAX
    mov R14, RAX

    pop RAX
    mov R8, RAX


    ;STEP 10
    lea RAX, St2
    push RAX
    call PrintString

    call ReadStringToNumber

    cmp R10, 1
    jz exit_error


    ;++++
    cmp RAX, -128
    jl error_range
    cmp RAX, 127
    jg error_range


    ;STEP 11
    push RAX
    mov R15, RAX

    pop RAX
    add R8, RAX



    ;STEP 12
    lea RAX, St3
    push RAX
    call PrintString

    ;++++
    add R8, 27

    ;STEP 13
    mov sum, R8
    call PrintValue


    ;++++
    cmp R14, R15
    js A_G

    mov sum, R15
    call PrintValue
    jmp Wait_M

    A_G:
        mov sum, R14
        call PrintValue


    ;STEP 14
    Wait_M:
        call WaitAns


    exit:
        xor RCX, RCX
        call ExitProcess

    ;+++++
    error_range:
        lea RAX, St6
        push RAX
        call PrintString
        jmp Wait_M


    ;++++
    exit_error:
        lea RAX, St4
        push RAX
        call PrintString
        jmp Wait_M

Start endp
end