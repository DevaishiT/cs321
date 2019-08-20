cpu "8085.tbl"
hof "int8"

org 9000h
;Gets hex digits and displays them
GTHEX: EQU 030EH   
;Expands hex digits for display 		
HXDSP: EQU 034FH
;Outputs characters to display			
OUTPUT:EQU 0389H	
;Clears the display		
CLEAR: EQU 02BEH	
;Reads keyboard		
RDKBD: EQU 03BAH	
;Takes input from KBINT		
KBINT: EQU 3CH		

;address of display
CURDT: EQU 8FF1H		
;data of display	
UPDDT: EQU 044cH	
;Updates Data field of the display		
CURAD: EQU 8FEFH		
;Updates Address field of the display
UPDAD: EQU 0440H

MVI A,00H 					
MVI B,00H 					 

LXI H,8840H
MVI M,0CH

LXI H,8841H
MVI M,11H

LXI H,8842H
MVI M,00H

LXI H,8843H
MVI M,0CH

LXI H,8840H
CALL OUTPUT
CALL RDKBD
CALL CLEAR 					

MVI A,00H
MVI B,00H
;taking the start time from user in hh::mm
Call gthex 					
MOV H,D 					
MOV L,E

;B stores the cuirrent state
;if B==0 clock is running
;if B==1 clock is paused
MVI B,00H

;check if min>60
CHN_MM:						
	MOV A,L
	CPI 60H
	JC BLK_JMP				
	MVI L,59H 

BLK_JMP:

;change hr and min
CHN_HR_MIN:						
	SHLD CURAD
	MVI A,59H

;decrement the second on each iteration
DECR_SEC:
    STA 8200H
    MVI A,0BH	
	;checking for interrupt	
    SIM
    EI	
	LDA 8200H
	;display current time
	STA CURDT				
	CALL UPDAD
	CALL UPDDT
	CALL DELAY				
    
	LDA CURDT
	CPI 00H 				
	JZ MIN
	CALL SUBTRACT_FUNCTION 				
	JMP DECR_SEC
	MIN:
	LHLD CURAD
	MOV A,L
	CPI 00H 				
	JZ HOUR					
	CALL SUBTRACT_FUNCTION 				
	MOV L,A
	JMP CHN_HR_MIN
	HOUR:					
	MVI L,59H				
	MOV A,H
	CPI 00H  				
	JZ BREAK 				
	CALL SUBTRACT_FUNCTION
	MOV H,A
	JMP CHN_HR_MIN

;if time is 00:00:00 then restart
BREAK:
	RST 5

;delay function to delay timer by 1 sec
DELAY:						
	MVI C,03H

OUTLOOP:
	LXI D,0A604H

INLOOP:						
	DCX D 					
	MOV A,D
	ORA E
	JNZ INLOOP
	DCR C
	JNZ OUTLOOP
	RET

;interrupt service routine where we will be redirected after eacfh interrupt
INTERRUPT:
    MVI A,00H
    CMP B
	;if clock was running, then pause
    JZ PAUSE
	;if clock was paused, then resume
    JMP PLAY

;to pause the clock
PAUSE:
    MVI B,01H
    ;JMP WAITFORINTERRUPT

WAITFORINTERRUPT:
	MVI A, 0BH
    SIM
    EI
    JMP WAITFORINTERRUPT

;to play the clock
PLAY:
    MVI B,00H
	LDA 8200H
    JMP DECR_SEC

;auxiliary function
SUBTRACT_FUNCTION:						 
 STA 8202H
 ANI 0FH
 CPI 00H
 JZ SUBTRACT_HELPER
 LDA 8202H
 DCR A
 RET
 SUBTRACT_HELPER:
 LDA 8202H
 SBI 07H
 RET