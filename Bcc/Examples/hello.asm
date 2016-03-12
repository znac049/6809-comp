export	_main
_main:
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
mov	ebx,#.1
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
! Register BX used in function main
.data
.1:
.2:
.ascii	"Hello world"
.byte	$A
.byte	0
.bss

! 0 errors detected
