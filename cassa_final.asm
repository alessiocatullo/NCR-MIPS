.data
	#-------------- VARIABILI DI FUNZIONAMENTO --------#
	plufile: .asciiz "plu.dat"		# Nome del file dove sono configurati gli aritcoli
	buffer: .space 24			# 24 = 22 Caratteri effettivi + char fine stringa + char a capo
	.align 2
	buffer_ean: .space 6			# Buffer fisso che legge gli ean da 4 caratteri
	line_break: .byte '\n'
	carriage_return: .byte '\r'
	total_char: .byte 't'
	abort_char: .byte 'a'
	separator: .byte ':'			# Separatore per prelevare la descrizione ed il prezzo
	#-------------- STRINGHE UTILI------------#
	benvenuto: .asciiz "\n\nBenvenuto/a nel software POS di cassa leader nel mercato MIPS-POS!\nCon questo software potrai simulare una vera e propria transazione di vendita stile supermercato!\n\n"
	menu: .asciiz "\n---------MENU--------\n1- Transazione di vendita\n2- Visualizza prezzo\n3- Esci\n--> "
	saluti: .asciiz "\n\nGrazie per aver utilizzato MIPS-POS!"
	saluti_end_trans: .asciiz "\n\nGrazie alla prossima!"
	begin_fiscal: .asciiz "\n\n------ INIZIO TRANSAZIONE ------\n\n"
	end_fiscal: .asciiz "\n\n------ FINE TRANSAZIONE ------\n\n"
	abort_str: .asciiz "\n\n------ TRANSAZIONE ANNULLATA------\n\n"
	total_str: .asciiz "\n------ TOTALE------\n"
	total_str_articoli: .asciiz "   Articoli "
	total_str_details: .asciiz "Totale complessivo           "
	check_price_str: .asciiz "\nInserisci il codice (EAN - 4 caratteri) del prodotto -> "
	ean_not_founded_str: .asciiz "\nL'articolo non è presente nell'anagrafica! Controlla che il codice (EAN) sia corretto!\n"
	text_str: .asciiz "\nArticolo: "
	price_str: .asciiz " - Prezzo: "
	other_check_str: .asciiz "\nVuoi visualizzare il prezzo di un altro articolo?\n1- Si\n2- No, torna al menu\n--> "
	add_to_cart_str: .asciiz "\n\nArticolo aggiunto al carrello\n\n "
	#----------- VARIABILI PER LA TRANSAZIONE --------#
	cart: .word 0				# Stack in cui vengono salvati gli articoli venduti
	n_articoli: .word 0			# numero di articoli nel carrello
	tra_total: .word 5			# totale da pagare

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
	beq $v0, 3, end					# Esci

	j menu_loop
	
###### TRANSAZIONE DI VENDITA ######
startTrans:
	li $v0, 4
	la $a0, begin_fiscal				# Print stringa inizio transazione
	syscall
	
	sw $zero, tra_total				# Azzero totale

sell:							# loop richiesta inserimento ean
	li $v0, 4
	la $a0, check_price_str				# Richiesta inserimento ean
	syscall
	
	li $v0, 8
	la $a0, buffer_ean				# Leggo massimo 4 caratteri per aggiungere (se esiste) un articolo al carrello
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
	lw $t0, tra_total
	beqz $t0, endTransaction
	
	lw $t0, n_articoli
	addi $sp, $sp, -4				# mi salvo nello stack il numero di articoli
        sw $t0, 0($sp)
	
      	addi $sp, $sp, -4	
        sw $ra, 0($sp)
        jal printCart					# stampo il contenuto del carrello
        lw $ra, 0($sp)
        addi $sp, $sp, 4
	
	li $v0, 4
	la $a0, total_str				# Print stringa totale
	syscall
	li $v0, 4
	la $a0, total_str_articoli			# Print stringa articoli
	syscall
	
	lw $ra, 0($sp)					# mi carico il numero di articoli dallo stack
        addi $t0, $sp, 4
	
	li $v0, 1
	la $a0, ($t0)					# Print # articoli
	syscall
	li $v0, 11
	lb $a0, line_break				# Print line_break
	syscall
	
	li $v0, 4
	la $a0, total_str_details			# Print stringa totale complessivo
	syscall
	
	li $v0, 1
	lw $a0, tra_total
	syscall

	li $v0, 11
	lb $a0, line_break				# Print line_break
	syscall
	
	j paymentMethod					# Vado al pagamento

abort: 
	li $v0, 4
	la $a0, abort_str				# Print stringa abort della transazione
	syscall
	j endTransaction

paymentMethod:						# Funzione che gestisce il pagamento attraverso 2 forme di pagamento
	
	j endTransaction
	
endTransaction:
	li $v0, 4
	la $a0, saluti_end_trans			# Print stringa saluti end
	syscall
	li $v0, 4
	la $a0, end_fiscal				# Print stringa abort della transazione
	syscall
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
		li   $v0, 16       # syscall per chiudere il file descriptor
		move $a0, $s0      
		syscall            
	
		li $v0, 4
		la $a0, ean_not_founded_str
		syscall
		
		li $v0, 1
		jr $ra

# Valutare se mettere other check		
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
	lb $t2, separator		# Mi salvo il separatore
	lb $t3, carriage_return		# Mi salvo il carattere di fine riga
	la $t0, buffer			# Mi salvo il buffer della parola
	addi $t0, $t0, 5 		# Salto 4 caratteri per l'ean più il ":"

	print_text_loop:		# Stampo carattere per carattere del testo
	lb $t1, ($t0)
	beq $t1, $t2, print_price
	li $v0, 11
	move $a0, $t1
	syscall
	addi $t0, $t0, 1
	j print_text_loop
	
	print_price:			# stampo Stringa "prezzo: "
	li $v0, 4
	la $a0, price_str
	syscall
	addi $t0, $t0, 1
	
	li $v0, 9			# Alloco spazio per il prezzo
	la $a0, 4
	syscall
	move $t5, $v0			# Mi salvo la posizione appena generata
	move $t4, $t5			# Genero una variabile da utilzzare per scorrere lo spazio creato

	print_price_loop:		# Leggo carattere per carattere fino ad arrivare al carattere di fine riga
	lb $t1, ($t0)
	beq $t1, $t3, out_price
	sb $t1, ($t4)
	li $v0, 11
	move $a0, $t1
	syscall
	addi $t0, $t0, 1
	addi $t4, $t4, 1
	j print_price_loop

	out_price:			# Incremento il tra_total con l'importo dell'articolo trovato
	lw $t4, tra_total		# Recupero il totale complessivo della transazione
	
	str2int: 			# convertire stringa to integer 
	li $t2, 0 			# inzializzo risultato finale $v0 = 0 
	move $t1, $t5 			# $t1 = pointer alla stringa 
	lb $t3, ($t1) 			# load $t1 = carattere
	
	LOOP_str2int:
	subu $t3, $t3, 48 		# digit = integer dal valore ascii del carattere
	mul $t2, $t2, 10 		# moltiplico il risultato finale per 10 
	add $t2, $t2, $t3 		# $v0 = $v0 * 10 + digit 
	addiu $t1, $t1, 1 		# passo al carattere successivo 
	lb $t3, ($t1) 			# load $t1 = carattere successivo
	bne $t3, $0, LOOP_str2int 	# brench se la stirnga non è finita
	
	add $t4, $t4, $t2		# incremento il totale complessivo con il prezzo appena generato
	sw $t4, tra_total
	
	jr $ra
	
# Funzione che aggiunge l'ean al cart, incrementa la size
addToCart:
	# in $a0 avrò l'ean
	move $t0, $a0 		# EAN
	
	la $t3, cart		# Mi carico posizione dello stack + indice stack
	lw $t4, 0($t3)
	la $t5, n_articoli

	li $v0, 9		# Creo spazio [9]
	li $a0, 8		# 2 parole da 4byte
	syscall

	sw $t0, 0($v0)		# Salvo l'ean nello spazio creato
	sw $t4, 4($v0)		# next = *old_stack

	lw $t6, 0($t5)		
	addi $t6, $t6, 1	# incremento l'indice dello stack

	sw $v0, 0($t3)		# Aggiorno lo stack pointer al nodo appena creato
	sw $t6, 0($t5) 		# Aggiorno il contatore di elementi

	li $v0, 4
	la $a0, add_to_cart_str				# Printo "aggiunto al carrello..."
	syscall
	jr $ra

printCart:
	jr $ra
