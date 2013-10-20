dosseg
.model small
.stack 64h

.data
vmode db '$'
bgcolor db 0
fgcolor db 4
fgtitle db ' Current Brush:$'
intro0 db 'I  N  S  T  R  U  C  T  I  O  N  S$'
intro1 db '===================================$'
intro2 db 'Background Color:    UP / DOWN$'
intro3 db 'Brush Color:      RIGHT / LEFT$'
intro4 db 'Exit:                  ESC $'
intro5 db ' [Press any key to start drawing]$'
title0 db '             _____  __  __  _____        _         _    $'
title1 db '     /\     / ____||  \/  ||  __ \      (_)       | |   $'
title2 db '    /  \   | (___  | \  / || |__) |__ _  _  _ __  | |_  $'
title3 db '   / /\ \   \___ \ | |\/| ||  ___// _` || || `_ \ | __| $'
title4 db '  / ____ \  ____) || |  | || |   | (_| || || | | || |_  $'
title5 db ' /_/    \_\|_____/ |_|  |_||_|    \__,_||_||_| |_| \__| $'
title6 db 'by Fernando Gonzalez$'

save_vmode macro
    mov ah, 0Fh
    int 10h
    mov bx, offset vmode
    mov [bx], al
    mov ah, 09h
    mov dx, bx
    int 21h
endm

set_vmode macro v
    mov ah, 0
    mov al, v
    int 10h
endm

update_bg macro color
    mov ah, 0Bh
    mov bl, color
    int 10h
endm

cursor macro x, y
    mov ah, 02h
    mov bh, 0
    mov dh, y
    mov dl, x
    int 10h
endm

display macro string, x, y
    cursor x, y
    mov ah, 09h
    mov dx, offset string
    int 21h
endm

clear_row macro row
    mov ah, 06h
    mov al, 0
    mov ch, row
    mov cl, 0
    mov dh, row
    mov dl, 79
    int 10h
endm

rectangle macro color, x1, x2, y1, y2
    local start, next
    mov dx, y1
    start:
        mov cx, x1
    next:
        mov ah, 0Ch
        mov al, color
        int 10h
        inc cx
        cmp cx, x2
        jne next
        inc dx
        cmp dx, y2
        jne start
endm

print_intro macro
    display title0, 10, 1
    display title1, 10, 2
    display title2, 10, 3
    display title3, 10, 4
    display title4, 10, 5
    display title5, 10, 6
    display title6, 40, 7
    display intro0, 22, 11
    display intro1, 22, 12
    display intro2, 22, 13
    display intro3, 22, 14
    display intro4, 22, 15
    display intro5, 22, 18
    ;;any_key:
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je exit
    ;;clear text after key press
    clear_row 1
    clear_row 2
    clear_row 3
    clear_row 4
    clear_row 5
    clear_row 6
    clear_row 7
    clear_row 11
    clear_row 12
    clear_row 13
    clear_row 14
    clear_row 15
    clear_row 18
endm

print_brush_color macro
    ;;Update 'current brush color' notification
    display fgtitle, 0, 0
    mov bx, offset fgcolor
    rectangle [bx], 130, 145, 0, 15
endm

paint macro x, y
    ;;Naive implementation b/c i was having trouble with automated solution
    mov bx, offset fgcolor
    mov ax, [bx]

    mov ah, 0Ch
    mov cx, x
    mov dx, y
    int 10h

    mov ah, 0Ch
    inc cx
    int 10h

    mov ah, 0Ch
    inc cx
    int 10h

    mov ah, 0Ch
    dec dx
    int 10h

    mov ah, 0Ch
    dec cx
    int 10h

    mov ah, 0Ch
    dec cx
    int 10h

    mov ah, 0Ch
    dec dx
    int 10h

    mov ah, 0Ch
    inc cx
    int 10h

    mov ah, 0Ch
    inc cx
    int 10h
endm

get_input macro
    local check, save, escape, adjust, bgup, bgdown, fgup, fgdown
    escape:
        mov ah, 06h     ;;Check keyboard buffer for input
        mov dl, 255
        int 21h
        cmp al, 1Bh     ;;Esc = exit
        je exit
    adjust:
        cmp al, 48h     ;;Up
        je bgup
        cmp al, 50h     ;;Down
        je bgdown
        cmp al, 4Dh     ;;Right
        je fgup
        cmp al, 4Bh     ;;Left
        je fgdown
        jmp check
    bgup:               ;;Move to next real bg color
        mov bx, offset bgcolor
        mov ax, [bx]
        inc al
        mov [bx], ax
        update_bg al
        jmp check
    bgdown:
        mov bx, offset bgcolor
        mov ax, [bx]
        dec al
        mov [bx], ax
        update_bg al
        jmp check
    fgup:               ;;Move to next real fg color aka paint brush color
        mov bx, offset fgcolor
        mov ax, [bx]
        inc al
        mov [bx], ax
        cmp al, 16
        je fbound1
        jmp check
        fbound1:
            mov [bx], 1
            jmp check
    fgdown:
        mov bx, offset fgcolor
        mov ax, [bx]
        dec al
        mov [bx], ax
        cmp al, 0
        je fbound2
        jmp check
        fbound2:
            mov [bx], 15
    check:          ;;Check for mouse input
        print_brush_color
        mov ax, 0003h
        int 33h
        cmp bx, 1
        je save
        jmp escape
    save:           ;;Exit when we have coordinates of where mouse was pressed
        dec dx
endm

.code
main proc
    mov ax, @data
    mov ds, ax

    call init
    call draw

    exit:
        mov bx, offset vmode    ;restore video mode on exit
        mov dl, [bx]
        set_vmode dl
        mov ah, 4Ch             ;graceful exit
        int 21h
main endp

init proc
    save_vmode
    set_vmode 12h
    print_intro
    mov ax, 1                   ;show mouse
    int 33h
    ret
init endp

draw proc
    check:
        get_input
        paint cx, dx
        jmp check
    ret
draw endp

end main
