/*
    V:	2
    Разработать программу, которая вводит одномерный массив A[N], формирует из элементов массива A новый массив B по правилам, указанным в таблице, и выводит его. Память под массивы может выделяться как статически, так и динамически по выбору разработчика.

Разбить решение задачи на функции следующим образом:
1.	Ввод и вывод массивов оформить как подпрограммы.
2.	Выполнение задания по варианту оформить как процедуру
3.	Организовать вывод как исходного, так и сформированного массивов
Указанные процедуры могут использовать данные напрямую (имитация процедур без параметров). Имитация работы с параметрами также допустима.

Массив B из элементов A, значение которых не совпадает с первым и последним элементами A.
*/

.globl main



.text
s_asize:
	.asciz "Enter vector size: "
s_aelement:
	.asciz "Enter a[%lu]: "

s_pA:
	.asciz "A:"

s_pB:
	.asciz "B:"

s_nb:
	.asciz "All elements in A are equal to either first or last one\n"

s_ulong:
	.asciz "\t%lu"

s_nl:
	.asciz "\n"

e_a:
	.asciz "Error reading A array\n"

e_b:
	.asciz "Error allocating B array\n"

g_ulong:
	.asciz "%lu"

read_input:
	push	%r12
	push	%r13
	push	%r14
	push	%r15

	movq	$s_asize, %rdi
	xor	%rax, %rax
	call	printf

	movq	$g_ulong, %rdi
	subq	$0x8, %rsp
	movq	%rsp, %rsi
	subq	$0x8, %rsp
	xor	%rax, %rax
	call	scanf
	movq	0x8(%rsp), %r12
	addq	$0x10, %rsp
	cmp	$0x1, %rax
	jne	.Lcount_or_alloc_error
	test	%r12, %r12
	je	.Lcount_or_alloc_error

	movq	%r12, %rdi
	shl	$0x3, %rdi
	movq	%rdi, %r13
	call	malloc
	test	%rax, %rax
	je	.Lcount_or_alloc_error

	movq	%rax, %r14
	add	%r13, %r14
	movq	%rax, %r13
	xor	%r15, %r15

.L0:
	movq	$s_aelement, %rdi
	mov	%r15, %rsi
	xor	%rax, %rax
	call	printf

	mov	$g_ulong, %rdi
	mov	%r13, %rsi
	xor	%rax, %rax
	call	scanf
	cmp	$0x1, %rax
	jne	.Litem_fill_error
	inc	%r15
	add	$0x8, %r13
	cmp	%r13, %r14
	ja	.L0

	mov	$.Lexit, %r14
	jmp	.Lrestore_array_pointer

.Lcount_or_alloc_error:
	xor	%r13, %r13
	jmp	.Lexit

.Litem_fill_error:
	mov	$.Litem_fill_error_free, %r14

.Lrestore_array_pointer:
	shl	$0x3, %r15
	sub	%r15, %r13
	jmp	*%r14

.Litem_fill_error_free:
	mov	%r13, %rdi
	call	free
	xor	%r13, %r13

.Lexit:
	mov	%r13, %rax
	mov	%r12, %rdi
	pop	%r15
	pop	%r14
	pop	%r13
	pop	%r12
	ret

count_nb:
	mov	(%rdi), %rdx
	mov	%rsi, %rcx
	mov	%rsi, %r8
	dec	%rcx
	shl	$0x3, %rcx
	shl	$0x3, %r8
	add	%rdi, %rcx
	add	%rdi, %r8
	mov	(%rcx), %rcx
	xor	%rax, %rax
	xor	%r9, %r9
	xor	%r10, %r10
.L1:
	mov	(%rdi), %rsi
	cmp	%rsi, %rdx
	lahf
	or	%ax, %r9w
	cmp	%rsi, %rcx
	lahf
	or	%ax, %r9w
	and	$0x4000, %r9
	add	%r9, %r10
	xor	%r9, %r9
	add	$0x8, %rdi
	cmp	%rdi, %r8
	ja	.L1

	mov	%r10, %rax
	shr	$0xE, %rax
	ret

fill_b:
	mov	(%rdi), %rcx
	mov	%rsi, %r8
	mov	%rsi, %r9
	dec	%r8
	shl	$0x3, %r8
	shl	$0x3, %r9
	add	%rdi, %r8
	add	%rdi, %r9
	mov	(%r8), %r10
.L2:
	mov	(%rdi), %rax
	cmp	%rax, %rcx
	je	.L2inc
	cmp	%rax, %r10
	je	.L2inc
	mov	%rax, (%rdx)
	add	$0x8, %rdx
.L2inc:
	add	$0x8, %rdi
	cmp	%rdi, %r9
	ja	.L2

	ret


println_arr:
	push	%r12
	push	%r13
	mov	%rdi, %r12
	mov	%rsi, %r13
	shl	$0x3, %r13
	add	%r12, %r13
.L3:
	mov	$s_ulong, %rdi
	mov	(%r12), %rsi
	xor	%eax, %eax
	call	printf
	add	$0x8, %r12
	cmp	%r12, %r13
	ja	.L3

	mov	$s_nl, %rdi
	xor	%rax, %rax
	call	printf
	
	pop	%r13
	pop	%r12
	ret

print_and_destroy_arr:
	push	%r12
	push	%r13
	mov	%rdi, %r12
	mov	%rsi, %r13
	mov	%rdx, %rdi
	xor	%rax, %rax
	call	printf
	mov	%r12, %rdi
	mov	%r13, %rsi
	call	println_arr
	mov	%r12, %rdi
	call	free
	pop	%r13
	pop	%r12
	ret


main:
	push	%r12
	push	%r13
	push	%r14
	push	%r15

	call	read_input
	test	%eax, %eax
	je	.LinputA_error
	mov	%rax, %r12
	mov	%rdi, %r13
	mov	%r12, %rdi
	mov	%r13, %rsi
	call	count_nb
	mov	%r13, %r14
	sub	%rax, %r14
	test	%r14, %r14
	je	.Lnb

	mov	%r14, %rdi
	shl	$0x3, %rdi
	call	malloc
	test	%rax, %rax
	je	.LmallocB_error

	mov	%rax, %r15
	mov	%r12, %rdi
	mov	%r13, %rsi
	mov	%r15, %rdx
	call	fill_b

	mov	%r12, %rdi
	mov	%r13, %rsi
	mov	$s_pA, %rdx
	call	print_and_destroy_arr

	mov	%r15, %rdi
	mov	%r14, %rsi
	mov	$s_pB, %rdx
	call	print_and_destroy_arr
	
	xor	%eax, %eax
	jmp	.Lexit1

.LinputA_error:
	mov	$e_a, %rdi
	xor	%rax, %rax
	call	printf
	mov	$-0x1, %rax
	jmp	.Lexit1

.LmallocB_error:
	mov	%r12, %rdi
	call	free
	mov	$e_b, %rdi
	xor	%rax, %rax
	call	printf
	mov	$-0x2, %rax	
	jmp	.Lexit1

.Lnb:
	mov	%r12, %rdi
	call	free
	mov	$s_nb, %rdi
	xor	%rax, %rax
	call	printf
	jmp	.Lexit1

.Lexit1:
	pop	%r15
	pop	%r14
	pop	%r13
	pop	%r12
	ret
