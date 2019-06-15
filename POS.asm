.data  
	plufile: .asciiz "plu.dat"
	buffer: .space 32
	lineBreak: .asciiz "\n"
.text
################################################
main:	
	jal loadPLU
	
	li $v0, 10
	syscall
	
########## LOAD PARAMS ##################
loadPLU:
	# PLU file open
	li $v0, 13		# Open file = 13
	la $a0, plufile   	# file name
	li $a1, 0        	# 0 = Reading 1 = Write
	syscall
	move $s0, $v0      	# Salvo in $s0 il file descriptor
	readingPLU:
		li $v0, 14       	# Reading from file = 14
		move $a0, $s0      	# NON TOCCARE $s0 dove c'è il descriptor del file
		la $a1, buffer   	# Indirizzo del buffer
		li $a2, 38		# Lunghezza riga da leggere
		syscall            	
		
		beq $v0, $zero, doneReading	# Check termine lettura
        	slt $t0, $v0, $zero
        	beq $t0, 1, doneReading
        	
        	la $v1,	buffer
		la $t1,	($v1)
		move $a1, $zero 
		li $a0, 0 		
		lb $a1,	($v1)
		
		strlen_loop:	
			beqz $a1, alloc_mem
			addi $a0, $a0, 1
			addi $v1, $v1, 1
			lb $a1, ($v1)
		j strlen_loop
		
		alloc_mem:
			li $v0,9 
			syscall
			
			la $t0,($v0)
			la $v1,($t1)
		copy_str:
			lb $a1,($t1)
			
	strcopy_loop:
		beqz $a1,exit_procedure #check if current byte is NULL
		sb $a1,($t0)            #store the byte at the target pointer
		addi $t0,$t0,1          #increment source ptr
		addi $t1,$t1,1          #decrement source ptr
		lb $a1,($t1)            #load next byte from source ptr
		j strcopy_loop

		j readingPLU
	
	# Close the file
	doneReading:
		li   $v0, 16       # system call for close file
		move $a0, $t9      # file descriptor to close
		syscall            # close file
	
		jr $ra
		
############## METODI USEFULL #####################