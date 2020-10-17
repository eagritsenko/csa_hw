.global _start


# macro to call write incide the write_output function
.macro call_write
	mov	%rax, %rdx
	sub	%r8, %rdx
	mov	%r8, %rsi
	mov	$0x1, %rdi
	mov	$0x1, %rax
	syscall

.endm


# Write cyrillic char stats for uc chars from uc_begin to uc_end (excl) and for lc from lc_begin
# Works for the range of lowercase chars starting with $0xd0
.macro print_part_l uc_begin, uc_end, lc_begin
	mov	\uc_begin, %r12
	mov	\lc_begin, %r13

.Lprint_part\uc_begin:
	mov	%r12d, (%rsi)	# Write uppercase char stat prefix to buffer
	add	$0x3, %rsi
	mov	%r12w, %r9w	# Extract char code from said prefix
	shr	$0x8, %r9w
	mov	(%r10,%r9,8), %rdi # Get the char's count using it's code
	add	%rdi, %r15
	call	itoa		# Write their count to buffer
	
	mov	%rax, %rsi	# Same as above, but for lowercase ones
	mov	%r13d, (%rsi)
	add	$0x4, %rsi
	mov	%r13d, %r9d
	shr	$0x10, %r9d
	and	$0xFF, %r9w
	mov	(%r10,%r9,8), %rdi
	add	%rdi, %r15
	call	itoa

	movb	$0xA, (%rax)
	inc	%rax

	CALL_WRITE
	
	add	$0x0100, %r12w		# update char codes within their output prefixes
	add	$0x010000, %r13d
	cmp	\uc_end, %r12
	jb	.Lprint_part\uc_begin
.endm	


# write cyrillic char stats for uc chars from uc_begin to uc_end (excl) and for lc from lc_begin
# works for the range of lowercase chars starting with $0xd1
.macro print_part_u uc_begin, uc_end, lc_begin, upper_half
	mov	\uc_begin, %r12
	mov	\lc_begin, %r13

.Lprint_part\uc_begin:
	mov	%r12d, (%rsi)
	add	$0x3, %rsi
	mov	%r12w, %r9w
	shr	$0x8, %r9w
	mov	(%r10,%r9,8), %rdi
	add	%rdi, %r15
	call	itoa

	mov	%rax, %rsi
	mov	%r13d, (%rsi)
	add	$0x4, %rsi
	mov	%r13d, %r9d
	shr	$0x10, %r9d
	and	$0xFF, %r9w
	add     $0x40, %r9b		# chars starting from $0xd1 start at $0x40 offset from their minimal code
	mov	(%r10,%r9,8), %rdi
	add	%rdi, %r15
	call	itoa

	movb	$0xA, (%rax)
	inc	%rax

	CALL_WRITE

	add	$0x0100, %r12w
	add	$0x010000, %r13d
	cmp	\uc_end, %r12
	jb	.Lprint_part\uc_begin
.endm




.bss
ascii_counter:
	.zero 0x400
utf8_c_counter:
	.zero 0x800
cut:
	.zero 0x8
cut_size:
	.zero 0x8

.text

/*
	char *itoa(long val, char *at)
	Writes human readable decimal representation of val at the spepecied pointer
	Returns pointer to the byte after the lowest digit written
	Destroys %rdi, %rsi, %rax, %rcx, %r11
*/
itoa:
	mov	%rsp, %r11
.Lpush_chars:
	movq	$0xCCCCCCCCCCCCCCCD, %rax
	mulq	%rdi
	shr	$0x3, %rdx	# <- after execution of this one, %rdx contains the result of division of %rdi buy 10
	mov	%rdx, %rcx
	mov	$0xA, %rax
	mulq	%rdx
	sub	%rax, %rdi
	dec	%rsp
	add	$0x30, %dil
	movb	%dil, (%rsp)
	mov	%rcx, %rdi
	test	%rdi, %rdi
	jne	.Lpush_chars

.Lpop_chars:
	movb	(%rsp), %dl
	movb	%dl, (%rsi)
	inc	%rsp
	inc	%rsi
	cmp	%rsp, %r11
	ja	.Lpop_chars
	
	mov	%rsi, %rax
	ret




#	void write_output(char *buffer)
#	Writes character statistics stored at ascii_counter and utf8_c_counter to stdout using buffer provided
#	Destroys %rsi, %r8, %r9, %r10, %r11
write_output:
	push	%r12
	push	%r13
	push	%r14
	push	%r15
	mov	%rdi, %r8
	mov	%rdi, %rsi
	mov	$ascii_counter, %r10
	xor	%r14, %r14
	xor	%r15, %r15
	xor	%r9, %r9

	mov	$0x0941, %r12	# mov "a\t", %r12
	mov	$0x096109, %r13	# mov "\tA\t", %r13

.Lprint_lat:
	mov	%r12w, (%rsi)	# Write stats of a capital letter to buffer
	add	$0x2, %rsi
	mov	%r12b, %r9b
	mov	(%r10,%r9,8), %rdi
	add	%rdi, %r14
	call	itoa
	
	mov	%rax, %rsi	# Write stats of a lowercase letter to buffer
	mov	%r13d, (%rsi)
	add	$0x3, %rsi
	mov	%r13w, %r9w
	shr	$0x8, %r9w
	mov	(%r10,%r9,8), %rdi
	add	%rdi, %r14
	call	itoa

	movb	$0x0A, (%rax)	# Add '\n' to buffer
	inc	%rax

	CALL_WRITE		# write buffer to stdout

	inc	%r12b
	add	$0x0100, %r13w
	cmp	$0x5B, %r12b	# check if we're out of latin letters
	jb	.Lprint_lat
	
	movb	$0x0A, (%rsi)	# add '\n' to separate latin and cyrrilic stats
	inc	%rsi
	mov	$utf8_c_counter, %r10	# load cyrillic letter stats array address

	PRINT_PART_L $0x0990d0, $0x0996d0, $0x09b0d009	# print the letters until Yo,
							# Yo doesn't belong to standart alphabet range and should be explicitly handled therefore
	# begin print letter Yo stats
	movl	$0x0981d0, (%rsi)	# mov "Ё\t", (%rsi)
	add	$0x3, %rsi
	mov	$0x81, %r12
	mov	(%r10,%r12,8), %rdi
	add	%rdi, %r15
	call	itoa			# Write stats of uppercase Yo to the buffer
	mov	%rax, %rsi
	movl	$0x0991d109, (%rsi)	# mov "\tё\t", (%rsi)
	add	$0x4, %rsi
	mov	$0xd1, %r12
	mov	(%r10,%r12,8), %rdi
	add	%rdi, %r15
	call	itoa			# Write stats of lowercase Yo to the buffer
	movb	$0xA, (%rax)
	inc	%rax
	CALL_WRITE
	# end print letter Yo stats

	PRINT_PART_L $0x0996d0, $0x09a0d0, $0x09b6d009	# print the letters until Re
	# lowercase Re starts with d1, hence stats table shift occurs
	PRINT_PART_U $0x09a0d0, $0x09afd1, $0x0980d109
	

					# Now that stats for each letter are print, print amount of cyrillic and latin letters
	mov	$0x0974614C0A, %r12
	mov	%r12, (%rsi) # mov "\nLat\t"
	add	$0x5, %rsi
	mov	%r14, %rdi
	call	itoa

	mov	%rax, %rsi
	mov	$0x0980d1b8d09ad009, %r12
	mov	%r12, (%rsi) # mov "\tКир\t"
	add	$0x8, %rsi
	mov	%r15, %rdi
	call	itoa

	movb	$0x0A, (%rax)
	inc	%rax
	CALL_WRITE

	pop	%r15
	pop	%r14
	pop	%r13
	pop	%r12

	ret



/*
	long count_next(char *buffer, long length)
	Reads the next portion of UTF8 sequence bytes from stdin into the buffer updating the letter counters accordingly
	Returns 0 if nothing was read, a non-zero number otherwise
	Destroys %rdi, %rsi, %rax, %rbx, %rcx, %rdc, %r8, %r9, %r11
*/
count_next:
	xor	%rax, %rax		# Load previous parser state (unprocessed leftovers) from the dummy and destroy it
	xor	%rbx, %rbx
	xchgq	(cut), %rax
	xchgq	(cut_size), %rbx
	mov	%rax, (%rdi)		# Put previous parser state in the buffer
	add	%rbx, %rdi		# Adjust buffer ptr and available buffer space accordingly
	sub	%rbx, %rsi

	mov	%rsi, %rdx		# Call read, using buffer space left
	mov	%rdi, %rsi
	xor	%rdi, %rdi
	xor	%rax, %rax
	syscall

	test	%rax, %rax		# If no bytes have been read, return
	je	.Lret

	mov	%rax, %rdi
	add	%rsi, %rdi		# %rdi now points to the byte after the last one read
	sub	%rbx, %rsi		# Restore buffer ptr
	mov	$ascii_counter, %r8	# Load pointers of arrays to write letter starts at
	mov	$utf8_c_counter, %r9
	xor	%rcx, %rcx
	xor	%rbx, %rbx
	xor	%rax, %rax
	cld				# Start parsing
.Lread_code:
	cmp	%rdi, %rsi		# if everything provided by print is read, leave the loop
	jae	.Lexit_loop
	lodsb                           # Load current byte
        xor	%bl, %bl                # bl represents the number of bytes we expect to get
                                        # xor it, for as of now we don't expect non-starting bytes of any complex character

	mov	%al, %cl		# Get the position of the first zero bit starting from the higher bits
	not	%cl                     # A non-zero position represents the number of bytes in a complex character
	bsr	%cx, %cx
	neg	%cl
	add	$0x7, %cl
	test	%cl, %cl		# If the position is not 0, it is a comlex mulitbyte character (possibly russian)
	jne	.Lpossibly_russian
	incq	(%r8,%rax,8);		# otherwise it is a one-byte ascii char (possibly latin), increment it's counter
	jmp	.Lread_code

.Lpossibly_russian:
	sub	$0xd0, %al	# All russian ciryllic characters start with either $0xd0 or $0xd1
	cmp	$0x1, %al	# Hence, if %cl is 0 or 1 it is russian cyrillic
	ja	.Lb234		# Otherwise jump to the non-russian multibyte character handler

				# Second bytes of russian characters overlap
	shl	$0x6, %al
	mov	%al, %cl	# So if the character starts with d1, increace it's second byte by 0x40 so it fits into table
	inc	%bl		# <- Since we expect a second byte, set the number of expected bytes to 1
	cmp	%rdi, %rsi	# Check if we've read everything, if so, leave loop
	jae	.Lexit_loop
	dec	%bl		
	lodsb			# Get the second character and set the number of expected characters to 0
	add	%cl, %al	# Increment the character "code" by $0x40 if needed
	incq	(%r9,%rax,8)
	jmp	.Lread_code

.Lb234:		
	mov	%cl, %bl
	dec	%cl
	add	%rcx, %rsi
	jmp	.Lread_code

.Lexit_loop:
	mov	%rsi, %rax
	test	%bl, %bl	# Test if we've read all the bytes but still expect some as subsequent parts of the current complex character
	je	.Lret		# If not, return
	sub	%rbx, %rsi	# Otherwise, save preceeding bytes of the current complex character as the next parser state
	mov	(%rsi), %rcx
	mov	%rcx, (cut)
	mov	%rbx, (cut_size)

.Lret:
	ret

/*
	long get_stack_size(void)
	Returns max stack size for the current process
	Destroys %rdi, %rsi, %rcx, %r11
*/
get_stack_size:
	sub	$0x10, %rsp	# Reserve space for struct_rlimit
	mov	$0x61, %rax
	mov	$0x3, %rdi	# mov RLIMIT_STACK, %rdi
	mov	%rsp, %rsi
	syscall			# call getrlimit to get max stack size
	mov	(%rsp), %rax	# Save max stack size at rax
	add	$0x10, %rsp	# Restore stack pointer
	
	ret		

_start:
	push	%r12
	push	%r13

	call	get_stack_size
				# The original idea was to use, like, 90% of stack space for the buffer
				# However there apeared to be no documents on how to get the stack base pointer
	shr	$0x1, %rax	# Thus using 50% of max stack space since it works
	sub	%rax, %rsp

	mov	%rsp, %r12
	mov	%rax, %r13
				# While the number of read bytes isn't 0, read and parse stdin
.Lread_and_count:
	mov	%r12, %rdi
	mov	%r13, %rsi
	call	count_next

	test	%rax, %rax
	jne	.Lread_and_count

	mov	%r12, %rdi	# Write read chracter stats
	call	write_output
	
	add	%r13, %rsp	# free stack
	pop	%r13
	pop	%r12

	mov	$0x3C, %rax	# call exit
	xor	%rdi, %rdi
	syscall
