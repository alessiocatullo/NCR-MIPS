.data
	plufile: .asciiz "plu.dat"		# Nome del file dove sono configurati gli aritcoli
	buffer: .space 24			# 24 = 22 Caratteri effettivi + char fine stringa + char a capo
	.align 2
	buffer_ean: .space 6
	line_break: .byte '\n'
	total_char: .byte 't'
	abort_char: .byte 'a'
	separator: .byte ':'			# Separatore per prelevare la descrizione ed il prezzo
	#-------------- STRINGHE UTILI------------#
	emptyPlu: .asciiz "\n\nANAGRAFICA VUOTA\n\n"
	benvenuto: .asciiz "\n\nBenvenuto/a nel software POS di cassa leader nel mercato!\nCon questo software potrai simulare una vera e propria transazione di vendita stile supermercato!\n\n"
	menu: .asciiz "\n---------MENU--------\n1- Transazione di vendita\n2- Visualizza prezzo\n3- Storico vendite\n4- Esci\n--> "
	saluti: .asciiz "\n\nGrazie per aver utilizzato POS! Ci vediamo alla prossima vendita"
	begin_fiscal: .asciiz "\n\n------ INIZIO TRANSAZIONE ------\n\n"
	end_fiscal: .asciiz "\n\n------ FINE TRANSAZIONE ------\n\n"
	abort_str: .asciiz "\n\n------ TRANSAZIONE ANNULLATA------\n\n"
	total_str: .asciiz "\n\n------ TOTALE------\n\n"
	check_price_str: .asciiz "\nInserisci il codice (EAN - Max 4 caratteri) del prodotto -> "
	ean_not_founded_str: .asciiz "\nL'articolo non è presente nell'anagrafica! Controlla che il codice (EAN) sia corretto!\n"
	text_str: .asciiz "\nArticolo: "
	price_str: .asciiz " - Prezzo: "
	other_check_str: .asciiz "\nVuoi visualizzare il prezzo di un altro articolo?\n1- Si\n2- No, torna al menu\n--> "
	add_to_cart_str: .asciiz "\n\nArticolo aggiunto al carrello\n\n "
	#-----------------------------------------#
	cart: .space 0			# Array in cui vengono salvati gli articoli venduti
	n_items: .word 0

.text
	li $v0, 4					# Messaggio di benvenuto
	la $a0, benvenuto
	syscall
	
###### MENU ######
main:
	menu_loop:					# Start menu loop
	li $v0, 4
	la $a0, menu
	syscall	
	
	li $v0, 5
	syscall
	
	beq $v0, 1, startTrans				# Transazione di vendita
	beq $v0, 2, checkPrice				# Visualizza prezzo
	beq $v0, 3, sales_history			# Recap transazione
	beq $v0, 4, end					# Esci

	j menu_loop
	
###### TRANSAZIONE DI VENDITA ######
startTrans:
	li $v0, 4
	la $a0, begin_fiscal				# Print stringa inizio transazione
	syscall

sell:							# loop richiesta inserimento ean
	li $v0, 4
	la $a0, check_price_str
	syscall
	
	li $v0, 8
	la $a0, buffer_ean				# Leggo i massimo 4 caratteri per aggiungere (se esiste) un articolo al carrello
	li $a1, 6					# 4 caratteri + carattere fine riga + enter
	syscall
	
	addi $sp, $sp, -4				# mi salvo nello stack l'ean appena inserito
        sw $a0, 0($sp)
        
	lb $s0, 0($a0)
	lb $s1, abort_char				# Se il carattere inserito è 'a' la transazione viene annullata
	beq $s1, $s0, abort
	lb $s1, total_char				# Se il carattere inserito è 't' si passa al totale
	beq $s1, $s0, total
	
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal findEAN					# Cerco l'ean inserito sul file plu.dat
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        bnez $v0, sell					# findEAN != 0 -> jump sell
        
        lw $a0, 0($sp)					# ripristino dallo stack l'ean inserito
        addi $sp, $sp, 4				
        
      	addi $sp, $sp, -4	
        sw $ra, 0($sp)
        jal addToCart					# findEan == 0 -> aggiungo l'articolo al carrello
        lw $ra, 0($sp)
        addi $sp, $sp, 4
	
	j sell

total:
	li $v0, 4
	la $a0, total_str				# Print stringa totale
	syscall
	
	li $v0, 4
	la $a0, end_fiscal				# Print stringa fine transazione
	syscall
	
	#Qui effettuo il clear di tutte le variabili
	j main
	
abort: 
	li $v0, 4
	la $a0, abort_str				# Print stringa abort della transazione
	syscall
	
	#Qui effettuo il clear di tutte le variabili
	j main
###### VISUALIZZA PREZZO ###### 
checkPrice:
	li $v0, 4
	la $a0, check_price_str
	syscall
	
	li $v0, 8
	la $a0, buffer_ean				# Leggo l'ean inserito
	li $a1, 6
	syscall
	
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal findEAN					# Se esistente stampo le informazioni dell'articolo
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        j main
###### RECAP TRANSAZIONE ######
sales_history:
j menu_loop

###### ESCI ######
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
		
otherCheck:
	li $v0, 4
	la $a0, other_check_str
	syscall	
	
	li $v0, 5
	syscall
	beq $v0, 1, checkPrice
	beq $v0, 2, menu_loop

	j otherCheck
	
printItem:
	li $v0, 4
	la $a0, text_str
	syscall
	lb $t2, separator
	lb $t3, line_break
	la $t0, buffer
	addi $t0, $t0, 5 		#Jumpo l'ean più il :

	print_text_loop:
	lb $t1, ($t0)
	beq $t1, $t2, print_price
	li $v0, 11
	move $a0, $t1
	syscall
	addi $t0, $t0, 1
	j print_text_loop
	
	print_price:
	li $v0, 4
	la $a0, price_str
	syscall
	addi $t0, $t0, 1
	
	print_price_loop:
	lb $t1, ($t0)
	beq $t1, $t3, out_price 
	li $v0, 11
	move $a0, $t1
	syscall
	addi $t0, $t0, 1
	j print_price_loop
	
	out_price:
	jr $ra
	
addToCart:						# Funzione che aggiunge l'ean al cart e ne incrementa la size							
	li $v0, 4					# Printo l'ean
	syscall
	li $v0, 4
	la $a0, add_to_cart_str				# Printo "aggiunto al carrello..."
	syscall
	jr $ra
