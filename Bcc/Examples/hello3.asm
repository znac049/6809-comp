!BCC_EOS
!BCC_EOS
!BCC_EOS
export	_main
_main:
!BCC_EOS
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
add	esp,*-$C
mov	ebx,#.1
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
mov	al,*1
mov	-$14[ebp],al
!BCC_EOS
mov	eax,*2
mov	-$10[ebp],eax
!BCC_EOS
mov	ebx,#_var
mov	-$18[ebp],ebx
!BCC_EOS
mov	ebx,-$18[ebp]
mov	al,#$FF
mov	[ebx],al
!BCC_EOS
mov	ebx,-$18[ebp]
mov	eax,*-2
mov	4[ebx],eax
!BCC_EOS
add	esp,*$C
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
! Register BX used in function main
.data
.1:
.2:
.ascii	"Hello world -- hello3.c"
.byte	$A
.byte	0
.bss
.comm	_var,8

! 0 errors detected
