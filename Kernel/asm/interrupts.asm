
GLOBAL _cli
GLOBAL _sti
GLOBAL picMasterMask
GLOBAL picSlaveMask
GLOBAL haltcpu
GLOBAL _hlt

GLOBAL _irq00Handler
GLOBAL _irq01Handler
GLOBAL _irq02Handler
GLOBAL _irq03Handler
GLOBAL _irq04Handler
GLOBAL _irq05Handler
GLOBAL _irq80Handler

GLOBAL _exception0Handler
GLOBAL _exception6Handler
EXTERN load_registers

EXTERN irqDispatcher
EXTERN exceptionDispatcher
EXTERN syscallDispatcher

GLOBAL get_current_rip
GLOBAL get_current_rsp
GLOBAL get_current_gp_registers

SECTION .text

%macro pushState 0
	push r15
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rsi
	push rdi
	push rbp
	push rdx
	push rcx
	push rbx
	push rax
%endmacro

%macro popState 0
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rbp
	pop rdi
	pop rsi
	pop r8
	pop r9
	pop r10
	pop r11
	pop r12
	pop r13
	pop r14
	pop r15
%endmacro

%macro irqHandlerMaster 1
	pushState

	mov rdi, %1 ; pasaje de parametro
	call irqDispatcher

	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	popState
	iretq
%endmacro

%macro exceptionHandler 1
	pushState

	call load_registers
	mov rsi, rax

	mov rdi, %1 ; pasaje de parametro
	call exceptionDispatcher

	popState
	iretq
%endmacro


_hlt:
	sti
	hlt
	ret

_cli:
	cli
	ret


_sti:
	sti
	ret

picMasterMask:
	push rbp
    mov rbp, rsp
    mov ax, di
    out	21h,al
    pop rbp
    retn

picSlaveMask:
	push    rbp
    mov     rbp, rsp
    mov     ax, di  ; ax = mascara de 16 bits
    out	0A1h,al
    pop     rbp
    retn

;8254 Timer (Timer Tick)
_irq00Handler:
	push rax ;voy a usar RAX para pasar los punteros
	mov rax, [rsp+8]
	mov [current_rip],rax
	add rsp,24
	mov rax, [rsp+8]
	mov [current_rsp],rax
	sub rsp,24
	pop rax
	mov [current_gp_registers], rax
	mov [current_gp_registers+8], rbx
	mov [current_gp_registers+16], rcx
	mov [current_gp_registers+24], rdx
	mov [current_gp_registers+32], rbp
	mov [current_gp_registers+40], rdi
	mov [current_gp_registers+48], rsi
	mov [current_gp_registers+56], r8
	mov [current_gp_registers+64], r9
	mov [current_gp_registers+72], r10
	mov [current_gp_registers+80], r11
	mov [current_gp_registers+88], r12
	mov [current_gp_registers+96], r13
	mov [current_gp_registers+104], r14
	mov [current_gp_registers+112], r15
	pushState	
	mov rdi, 0x00 ; pasaje de parametro
	call irqDispatcher

	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	popState
	iretq

;Keyboard
_irq01Handler:
	irqHandlerMaster 1

;Cascade pic never called
_irq02Handler:
	irqHandlerMaster 2

;Serial Port 2 and 4
_irq03Handler:
	irqHandlerMaster 3

;Serial Port 1 and 3
_irq04Handler:
	irqHandlerMaster 4

;USB
_irq05Handler:
	irqHandlerMaster 5

; Se usa la convención de Linux -> vease https://alejofl.github.io/syscalls/x86_64/
_irq80Handler:
	push rbp
	push    rsp
	push    rbx
	push    r12
	push    r13
	push    r15

	mov rcx, rax ; pasaje de numero de syscall
	call syscallDispatcher

	mov rcx, rax

	; signal pic EOI (End of Interrupt)
	mov al, 20h
	out 20h, al

	mov rax, rcx

	pop r15
	pop r13
	pop r12
	pop rbx
	pop rsp
	pop rbp
	iretq


;Zero Division Exception
_exception0Handler:
	exceptionHandler 0

;Invalid Opcode Exception
_exception6Handler:
	exceptionHandler 6

haltcpu:
	cli
	hlt
	ret

get_current_rip:
	enter 0,0
	mov rax,[current_rip]
	leave
	ret

get_current_rsp:
	enter 0,0
	mov rax,[current_rsp]
	leave
	ret

get_current_gp_registers:
	enter 0,0
	mov rax,current_gp_registers
	leave
	ret


section .bss
	current_rip resq 1
	current_rsp resq 1
	current_gp_registers resq 15