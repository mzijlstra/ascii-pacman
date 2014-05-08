MPUTMC MACRO x, y, c, a 
    PUSH AX
    PUSH BX
    PUSH CX
    MOV BL, x
    MOV AL, y 
    MOV CL, c
    MOV CH, a
    CALL PUTMC
    POP CX
    POP BX
    POP AX
ENDM
       
width       EQU 39
height      EQU 24
level_color EQU 0000_1001b   
tl_corner   EQU 201
tr_corner   EQU 187
bl_corner   EQU 200
br_corner   EQU 188
h_piece     EQU 205    
v_piece     EQU 186

             
org 100h


MOV AH, 0       ; sub function for video mode
MOV AL, 00h     ; 40x25 text mode
INT 10h         ; set video mode now     

;MOV AH, 5       ; set active video page
;MOV AL, 2       ; select page 2
;INT 10h         ; set active page now

MOV AH, 1       ; sub function for cursor shape
MOV CH, 0001_0000b ; set cursor invisible
INT 10h         ; set cursor mode now 

; draw basic level
MPUTMC 0, 0, tl_corner, level_color  
MPUTMC width, 0, tr_corner, level_color
MPUTMC 0, height bl_corner, level_color
MPUTMC width, height, br_corner, level_color
  
MOV CL, 1
draw_top:
    MPUTMC CL, 0, h_piece, level_color
    INC CL
    CMP CL, width
JB draw_top

MOV CL, 1
draw_bot:
    MPUTMC CL, height, h_piece, level_color
    INC CL
    CMP CL, width
JB draw_bot

MOV CL, 1
draw_left:
    MPUTMC 0, CL, v_piece, level_color
    INC CL
    CMP CL, height
JB draw_left

MOV CL, 1
draw_right:
    MPUTMC width, CL, v_piece, level_color
    INC CL
    CMP CL, height
JB draw_right



JMP draw                                 

main_loop: 
    process_keys: 
        CALL GET_KEY
        JZ check_change
        
        CALL PROCESS_KEY
        CMP AX, 1
        JZ quit
 
        JMP process_keys
    
    check_change:
        CMP xd, 0
        JNE draw
        CMP yd, 0
        JNE draw
        JMP sleep
    
    draw:      
    
        MOV BL, x       ; load current x
        ADD BL, xd      ; add x delta        
        MOV AL, y       ; load current y
        ADD AL, yd      ; add y delta

        MPUTMC BL, AL, guy, 0000_1110b ; draw character 
        MPUTMC x, y, 0, 0 ; erase old character 
        
        MOV x, BL       ; set x to new x
        MOV y, AL       ; set y to new y
        MOV xd, 0       ; clear x delta
        MOV yd, 0       ; clear y delta
    
    sleep:
        MOV AH, 86h   ; sub function for BIOS wait (in micro seconds)
        MOV CX, 0001h ; higher order bits 500,000 micro seconds
        MOV DX, 0000h ; lower order bits 500,000 micro seconds
        INT 15h
    
JMP main_loop    

quit:        
MOV AH, 5       ; set active video page
MOV AL, 2       ; select page 0
INT 10h         ; set active page now
MOV AH, 0       ; sub function for video mode
MOV AL, 03h     ; 80x25 text mode
INT 10h         ; set video mode now     
RET

GET_KEY PROC
check:     
    MOV AL, 0   ; clear AL
    MOV AH, 1   ; check for key sub function
    INT 16h     ; do it now
    JZ  done_getkey    ; jump out if no key
    
    MOV AH, 0   ; get key sub function
    INT 16h     ; puts scan code in AH, char code in AL
    
done_getkey:
    RET    
ENDP   


PROCESS_KEY PROC
    CMP AL, 'q'     ; check q key
    JE exit_fail    ; quit

    CMP AL, 1Bh     ; check escape key
    JE exit_fail    ; quit                    


    CMP AH, 48h     ; check up arrow
    JE up_arrow
    CMP AH, 4Bh     ; check left arrow
    JE left_arrow
    CMP AH, 4Dh     ; check right arrow
    JE right_arrow
    CMP AH, 50h     ; check down arrow
    JE down_arrow
    JMP exit_success

up_arrow:  
    CMP y, 0
    JE exit_success
    MOV yd, -1
    JMP exit_success
    
left_arrow:        
    CMP x, 0
    JE exit_success
    MOV xd, -1
    JMP exit_success

right_arrow:   
    CMP x, width
    JE exit_success
    MOV xd, 1
    JMP exit_success
    
down_arrow:        
    CMP y, height
    JE exit_success
    MOV yd, 1
    JMP exit_success
         
         
         
exit_fail:
    MOV AX, 1       ; set return non-zero    
    RET
exit_success:
    MOV AX, 0
    RET
ENDP      

; Procedure to put characters directly into mode 03h video memory
; expects x in BL, y in AL, character in CL, and attributes in CH
PUTMC PROC
    PUSH DS 
    
    MOV AH, 80; two bytes for every char
    MUL AH     ; calculates Y offset
    XOR BH, BH ; clear BH
    SAL BL, 1  ; shift left to multiply by two
    ADD BX, AX ; put offset into BX


    MOV AX, 0B800h ; address of video memory for mode 03h
    MOV DS, AX     ; set DS to this address
    MOV [BX], CX
    
    POP DS 
    RET
ENDP

guy   db 2    ; ascii code for character  
x     db 20   ; x position of character
y     db 11   ; y position of character 

xd    db 0    ; x delta
yd    db 1    ; y delta
