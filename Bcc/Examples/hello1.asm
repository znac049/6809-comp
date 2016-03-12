export	_main
_main:
!BCC_EOS
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
add	esp,*-4
mov	ebx,#.1
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
xor	eax,eax
mov	-$10[ebp],eax
!BCC_EOS
!BCC_EOS
jmp .4
.5:
push	dword -$10[ebp]
mov	ebx,#.6
push	ebx
call	_printf
add	esp,*8
!BCC_EOS
.3:
mov	eax,-$10[ebp]
inc	eax
mov	-$10[ebp],eax
.4:
mov	eax,-$10[ebp]
cmp	eax,*$A
jl 	.5
.7:
.2:
push	dword -$10[ebp]
call	_fn1
add	esp,*4
!BCC_EOS
add	esp,*4
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
! Register BX used in function main
export	_fn1
_fn1:
!BCC_EOS
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
mov	ebx,#.8
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
!BCC_EOS
!BCC_EOS
jmp .B
.C:
push	dword 8[ebp]
call	_fn2
add	esp,*4
push	eax
mov	ebx,#.D
push	ebx
call	_printf
add	esp,*8
!BCC_EOS
.A:
mov	eax,8[ebp]
dec	eax
mov	8[ebp],eax
.B:
mov	eax,8[ebp]
test	eax,eax
jg 	.C
.E:
.9:
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
! Register BX used in function fn1
export	_fn2
_fn2:
!BCC_EOS
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
mov	eax,8[ebp]
jmp .11
.12:
mov	eax,*-1
lea	esp,-$C[ebp]
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
!BCC_EOS
jmp .F
!BCC_EOS
.13:
xor	eax,eax
lea	esp,-$C[ebp]
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
!BCC_EOS
jmp .F
!BCC_EOS
.14:
mov	eax,*1
lea	esp,-$C[ebp]
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
!BCC_EOS
jmp .F
!BCC_EOS
jmp .F
.11:
sub	eax,*0
je 	.12
sub	eax,*1
je 	.13
jmp	.14
.F:
..FFFF	=	-$10
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
.data
.D:
.15:
.ascii	"i = %d"
.byte	$A
.byte	0
.8:
.16:
.ascii	"Goodbye world"
.byte	$A
.byte	0
.6:
.17:
.ascii	"i = %d"
.byte	$A
.byte	0
.1:
.18:
.ascii	"Hello world"
.byte	$A
.byte	0
.bss

! 0 errors detected
