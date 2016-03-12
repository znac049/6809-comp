!BCC_EOS
export	_main
_main:
!BCC_EOS
push	ebp
mov	ebp,esp
push	edi
push	esi
push	ebx
add	esp,*-8
mov	ebx,#.1
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
push	dword #$3FF00000
push	dword *0
lea	ebx,-$1C[ebp]
call	dtof
mov	eax,-$24[ebp]
mov	-$10[ebp],eax
add	esp,*$10
!BCC_EOS
push	dword #$40000000
push	dword *0
lea	ebx,-$1C[ebp]
call	dtof
mov	eax,-$24[ebp]
mov	-$14[ebp],eax
add	esp,*$10
!BCC_EOS
lea	ebx,-$14[ebp]
call	Fpushf
lea	ebx,-$10[ebp]
call	Fpushf
call	Fadd
lea	ebx,-$1C[ebp]
call	dtof
mov	eax,-$24[ebp]
mov	[_c],eax
add	esp,*$10
!BCC_EOS
mov	ebx,#.2
push	ebx
call	_printf
add	esp,*4
!BCC_EOS
add	esp,*8
pop	ebx
pop	esi
pop	edi
pop	ebp
ret
! Register BX used in function main
.data
.2:
.3:
.ascii	"c = %f"
.byte	$A
.byte	0
.1:
.4:
.ascii	"Hello world -- hello2.c"
.byte	$A
.byte	0
.bss
.comm	_c,4

! 0 errors detected
