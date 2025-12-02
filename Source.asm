extrn GetStdHandle  :proc,                  ;Получения дескриптора - спец номера для обращения к объекту, для которого мы хотим использовать потоки чтения и записи             
      lstrlenA      :proc,                  ;Получение длины строки
      WriteConsoleA :proc,                  ;Запись символов в поток
      ReadConsoleA  :proc,                  ;Чтение символов из потока
      ExitProcess   :proc                   ;Выход из программы

.data
hStdOutput DQ ?                             ;Дескриптор вывода
hStdInput DQ ?                              ;Дескриптор ввода

sum DQ ?                                    ;Сумма чисел

St1 DB 'a = ', 0
St2 DB 'b = ', 0
St3 DB '27 + a + b = ', 0
St4 DB 'Invalid character', 13, 10, 0            
St5 DB 'Press any key to exit...', 0
St6 DB 'Number out of range', 13, 10, 0

.code

STACKALLOC macro arg                        ;Макрос выравнивания стека и выделения места под аргументы
    push R15                                ;Используем R15 для запоминания старого SP
    mov R15, RSP                            ;Запоминаем старый SP
    sub RSP, 8*4                            ;Выделяем место под __fastcall
    if arg
      sub RSP, 8*arg                        ;Если требуется, выделяем место под доп. аргументы
    endif
    and SPL, 0F0h                           ;Выравниваем стек по 16-байтовой границе
endm


NULL_FIFTH_ARG macro                        ;Макрос для обнуления пятого аргумента в WriteConsoleA и ReadConsoleA
    mov qword ptr [RSP + 32], 0             ;Отступаем по стеку на 32 байта и обнуляем пятый аргумент
endm


STACKFREE macro                             ;Макрос восстанавливления старого значения SP
    mov RSP, R15
    pop R15
endm

PrintString proc uses RAX RCX RDX R8 R9, string: qword      ;Директива uses позволяет при входе в процедуру сохранить нужные регистры в стек и при выходе восстановить их
    local bytesWritten: qword                               ;Локальная переменная, в которой мы сохраним количество записанных в консоль байт

    STACKALLOC 1                                            ;Выделяем место под 5 аргументов

    mov RCX, string                                         ;Передаём строку в RCX, строку же мы передали в string перед вызовом процедуры в RAX
    call lstrlenA                                           ;В RAX сохранится длина текста

    mov RCX, hStdOutput                                     ;Куда выводим текст
    mov RDX, string                                         ;Какой текст
    mov R8, RAX                                             ;Длина текста
    lea R9, bytesWritten                                    ;Куда сохранить количество записанных байт

    NULL_FIFTH_ARG                                          ;Обнуление пятого аргумента

    call WriteConsoleA                                      ;Выводим текст

    STACKFREE                                               ;Освобождаем стек

    ret
PrintString endp


ReadStringToNumber proc uses RBX RCX RDX R8 R9
    local readStr[64]: byte, bytesRead: dword               ;Два локальных параметра, 1 - полученная строка, 2 - сколько байт прочитали

    STACKALLOC 2                                            

    mov RCX, hStdInput                                      ;Откуда читаем текст
    lea RDX, readStr                                        ;Какой текст
    mov R8, 64                                              ;Длина считываемой строки
    lea R9, bytesRead                                       ;Сколько байт прочитали
    NULL_FIFTH_ARG

    call ReadConsoleA                                       ;Считываем строку с консоли

    xor RCX, RCX                                            ;Сбрасываем счетчик
    mov ECX, bytesRead                                      ;Записываем в него длину прочитанной строки
    sub ECX, 2                                              ;Избавимся от символов переноса строки и возврата каретки.


    push RCX                                                ;Алгоритм для проверки строки на наличие лишних минусов
                                                            ;Будем считывать строку с последнего символа до второго и
    check_minus:                                            :проверять наличие минуса, если есть - выдаём ошибку
        mov AL, readStr[RCX]
        cmp AL, '-'
        jz error
        loop check_minus

    pop RCX


    xor RBX, RBX                                           ;Обнуляем RBX, в него будем записывать число
    mov R8, 1                                              ;Используем для хранения степени десятки

    m_StringScan:
        dec RCX                                            ;Ведём счетчик для проверки, завершили ли мы проверять строку
        cmp RCX, -1

        jz scanningComplete

        xor RAX, RAX                                       ;Обнуляем RAX
        mov AL, readStr[RCX]                               ;Вводим в него очередной символ строки, обративший по индексу

        cmp al, '-'                                        ;И проверяем на наличие минуса
        jz AlIsMinus

        jmp eval                                           ;Если не минус, то переходим к анализу цифры


    eval:
        cmp AL, 30h                                        ;Проверяем, что наш очередной символ является цифрой (от 0 до 9)
        jl error
        cmp AL, 39h
        jg error

        sub RAX, 30h                                       ;Избавляем цифру от ascii кода, чтобы получить чистую цифру
        mul R8                                             ;Умножаем цифру на степень десятки
        add RBX, RAX                                       ;Добавляем цифру с правильной разрядностью в RBX
        mov RAX, 10                                        
        mul R8                                             ;Увеличиваем в 10 раз регистр R8 для работы со след. разрядом
        mov R8, RAX
        jmp m_StringScan


    error:
        mov R10, 1                                         ;Помечаем, что произошла ошибка
        STACKFREE
        ret 8


    scanningComplete:
        mov R10, 0                                          ;Сканирование прошло успешно
        mov RAX, RBX                                        ;Сохраняем результат в RAX
        STACKFREE
        ret 8


    AlIsMinus:
        neg RBX                                            ;Если 
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

