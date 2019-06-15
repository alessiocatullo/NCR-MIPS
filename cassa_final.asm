.data
	plufile: .asciiz "plu.dat"		# Nome del file dove sono configurati gli aritcoli
	buffer: .space 24			# 24 = 22 Caratteri effettivi + char fine stringa + char a capo
	.align 2
	buffer_ean: .space 6
	line_break: .asciiz "\n"
	separator: .byte ':'			# Separatore per prelevare la descrizione ed il prezzo
	#-------------- STRINGHE UTILI------------#
	emptyPlu: .asciiz "\n\nANAGRAFICA VUOTA\n\n"
	benvenuto: .asciiz "\n\nBenvenuto/a nel software POS di cassa leader nel mercato!\nCon questo software potrai simulare una vera e propria transazione di vendita stile supermercato!\n\n"
	menu: .asciiz "\n---------MENU--------\n1- Transazione di vendita\n2- Visualizza prezzo\n3- Storico vendite\n4- Esci\n--> "
	saluti: .asciiz "\n\nGrazie per aver utilizzato POS! Ci vediamo alla prossima vendita"
	check_price_str: .asciiz "\nInserisci il codice (EAN - Max 4 caratteri) del prodotto -> "
	ean_not_founded_str: .asciiz "\nL'articolo non è presente nell'anagrafica! Controlla che il codice (EAN) sia corretto!\n"
	text_str: .asciiz "\nArticolo: "
	price_str: .asciiz " - Prezzo: "
	other_check_str: .asciiz "\nVuoi visualizzare il prezzo di un altro articolo?\n1- Si\n2- No, torna al menu\n--> "
	#-----------------------------------------#
	cart: .space 0			# Array in cui vengono salvati gli articoli venduti
	n_items: .word 0

.text
main:
	li $v0, 4
	la $a0, benvenuto
	syscall
	
	menu_loop:
	li $v0, 4
	la $a0, menu
	syscall	
		
	li $v0, 5
	syscall
	
	beq $v0, 1, start_trans
	beq $v0, 2, check_price	
	beq $v0, 3, sales_history
	beq $v0, 4, end

	j menu_loop

start_trans:
j menu_loop

#--------------- VISUALIZZA PREZZO ------------#
check_price:
	li $v0, 4
	la $a0, check_price_str
	syscall
	
	li $v0, 8
	la $a0, buffer_ean
	li $a1, 6
	syscall
	
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal findEAN
        lw $ra, 0($sp)
        addi $sp, $sp, 4

sales_history:
j menu_loop

#------------ END ---------------#
end:
	la $v0, 4
	la $a0, saluti
	syscall
	li $v0, 10
	syscall
	
#----------- FUNCTION -----------#
findEAN:
	li $v0, 13		# Open file = 13
	la $a0, plufile   	# file name
	li $a1, 0        	# 0 = Reading 1 = Write
	syscall
	move $s0, $v0      	# Salvo in $s0 il file descriptor
	readingPLU:
		li $v0, 14       	# Reading from file = 14
		move $a0, $s0      	# NON TOCCARE $s0 dove c'è il descriptor del file
		la $a1, buffer   	# Indirizzo del buffer
		li $a2, 24		# Lunghezza max riga da leggere
		syscall       	
		
		beqz $v0, ean_not_founded	# Check termine lettura
        	slt $t0, $v0, $zero
        	beq $t0, 1, ean_not_founded
        	
        	la $t0, buffer
        	lb $t1, ($t0)		# Byte della stringa del plu
        	la $t2, buffer_ean
        	lb $t3, ($t2)		# Byte dell'ean ricercato
        	lb $t4, separator
        	check_loop:
        		seq $t5, $t3, 10
        		seq $t6, $t1, $t4
        		and $t5, $t5, $t6
        		bnez $t5, ean_founded
        		bne $t1, $t3, readingPLU
        		addi $t0, $t0, 1
        		addi $t2, $t2, 1
        		lb $t1, ($t0)
        		lb $t3, ($t2)
        		j check_loop
        	
        	j readingPLU
	ean_founded:
		addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal printItem
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
		
		li   $v0, 16       # system call for close file
		move $a0, $s0      # file descriptor to close
		syscall            # close file
		
		li $v0, 4
		la $a0, text_str
		syscall
		
		li $v0, 0
		jr $ra

	ean_not_founded:
		li   $v0, 16       # system call for close file
		move $a0, $s0      # file descriptor to close
		syscall            # close file
	
		li $v0, 4
		la $a0, ean_not_founded_str
		syscall
		
		li $v0, 1
		jr $ra
other_check:
	li $v0, 4
	la $a0, other_check_str
	syscall	
	
	li $v0, 5
	syscall
	beq $v0, 1, check_price
	beq $v0, 2, menu_loop

	j other_check
	
printItem:
	li $v0, 4
	la $a0, text_str
	syscall
	
	li $v0, 9
	li $a0, 12
	syscall
	
	la $t0, ($v0)
	li $v0, 4
	la $a0, buffer
	syscall
	
	li $a0, 4
	la $a0, price_str
	syscall
	
	li $v0, 9
	li $a0, 4
	syscall
	
	jr $ra
	
add_to_cart:
	jr $ra