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
	header_str: .asciiz "\n\nDESCRIZIONE                     EURO\n"
	total_str: .asciiz "\n----------------------------------\n"
	total_str_articoli: .asciiz "   Articoli "
	total_str_details: .asciiz "Totale complessivo               "
	check_price_str: .asciiz "\nInserisci il codice (EAN - 4 caratteri) del prodotto -> "
	ean_not_founded_str: .asciiz "\nL'articolo non è presente nell'anagrafica! Controlla che il codice (EAN) sia corretto!\n"
	text_str: .asciiz "\nArticolo: "
	price_str: .asciiz " - Prezzo: "
	other_check_str: .asciiz "\nVuoi visualizzare il prezzo di un altro articolo?\n1- Si\n2- No, torna al menu\n--> "
	add_to_cart_str: .asciiz "\n\nArticolo aggiunto al carrello\n\n "
	cart_empty: .asciiz "\n\nCarrello vuoto\n\n"
	payment_str_1: .asciiz "\nDevi pagare ancora "
	payment_str_2: .asciiz " euro. In che modo vuoi pagare? (1 contanti, 2 pagamento elettronico): "
	payment_amount_cash: .asciiz "Inserire contanti (pagamento parziale permesso): "
	payment_print_cash: .asciiz "PAGAMENTO CONTANTI:              "
	payment_amount_card: .asciiz "Inserire carta (pagamento parziale non permesso): "
	payment_print_card: .asciiz "PAGAMENTO ELETTRONICO:           "
	
	#----------- VARIABILI PER LA TRANSAZIONE --------#
	cart: .word 0				# Stack in cui vengono salvati gli articoli venduti
	n_articoli: .word 0			# numero di articoli nel carrello
	tra_total: .word 0			# totale da pagare

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
	sw $zero, n_articoli

sell:							# loop richiesta inserimento ean
	li $v0, 4
	la $a0, check_price_str				# Richiesta inserimento ean
	syscall
	
	li $v0, 8
	la $a0, buffer_ean				# Leggo massimo 4 caratteri per aggiungere (se esiste) un articolo al carrello
	li $a1, 6					# 4 caratteri + carattere fine riga + enter
	syscall
        
	lb $s0, 0($a0)
	lb $s1, abort_char				# Se il carattere inserito è 'a' la transazione viene annullata
	beq $s1, $s0, abort
	lb $s1, total_char				# Se il carattere inserito è 't' si passa al totale
	beq $s1, $s0, total
	
	la $a0, buffer_ean 				# Passo la stringa letta
	li $a1, 0					# Booleano a 0 -> Non incremento il totale complessivo (verrà fatto nel printCart)
	
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal findEAN					# Cerco l'ean inserito sul file plu.dat
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        bnez $v0, sell					# findEAN != 0 -> jump sell
        
        la $a0, buffer_ean				# ripristino dallo stack l'ean inserito				
        
      	addi $sp, $sp, -4	
        sw $ra, 0($sp)
        jal addToCart					# findEan == 0 -> aggiungo l'articolo al carrello
        lw $ra, 0($sp)
        addi $sp, $sp, 4
	
	j sell

total:	
	lw $t0, n_articoli
	beqz $t0, endTransaction
	addi $sp, $sp, -4				# mi salvo nello stack il numero di articoli
        sw $t0, 0($sp)
	
	li $v0, 4
	la $a0, header_str				# Print stringa header
	syscall
	
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
	
	lw $t0, 0($sp)					# mi carico il numero di articoli dallo stack
        addi $sp, $sp, 4
	
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
	li $v0, 4		
	la $a0, payment_str_1
	syscall
	
	li $v0, 1
	lw $t0, tra_total
	move $a0, $t0
	syscall
	
	li $v0, 4		
	la $a0, payment_str_2
	syscall
	
	li $v0, 5					# Richiedo che forma di pagamento utilizzare
	syscall
	move $t1, $v0
	
	beq, $t1, 1, payment_cash
	beq, $t1, 2, payment_card
	j paymentMethod
	
	payment_cash:					# in caso fosse 1 = contanti
	li $v0, 4			
	la $a0, payment_amount_cash
	syscall
	
	li $v0, 5
	syscall
	move $t1, $v0					# offro la possibilità di pagare parzialmente
	li $v0, 4		
	la $a0, payment_print_cash
	syscall
	li $v0, 1		
	move $a0, $t1
	syscall
	j update_total					# Vado all'update del totale
	
	payment_card:					# in caso fosse 2 = elettronico
	li $v0, 4		
	la $a0, payment_amount_card
	syscall
	
	li $v0, 5					# Richiedo l'amount che si vuol pagare
	syscall
	move $t1, $v0
	
	bne $t1, $t0, paymentMethod			# blocco il pagamento parziale per il pagamento elettronico 
							#(si può pagare solo tutto il totale complessivo
	li $v0, 4		
	la $a0, payment_print_card
	syscall
	li $v0, 1		
	move $a0, $t1
	syscall
	j update_total					# Vado all'update del totale
	
	update_total:
	sub $t0, $t0, $t1				# Aggiorno il totale complessivo
	sw $t0, tra_total
	
	bnez $t0, paymentMethod				# Se non ho finito di pagare, jumpo all'inizio del metodo
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
	
	la $a0, buffer_ean 				# Passo la stringa inserita
	li $a1, 0					# Booleano a 0 -> non incrementare il totale complessivo
	
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
	move $s1, $a0		# mi salvo l'ean ricercato
	move $s2, $a1		# booleano 1 = incremento totale complessivo
				#	0 = non incremento totale complessivo
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
        	la $t2, ($s1)
        	lb $t3, ($t2)		# Byte dell'ean ricercato
        	lb $t4, separator	# Byte del separatore
        	check_loop:
        		seq $t5, $t3, 10	# t5 = 1 se t3 == LF 
        		seq $t6, $t1, $t4	# t6 = 1 se t4 == :
        		and $t5, $t5, $t6	# t5 and t6 allora ean trovato
        		bnez $t5, ean_founded
        		bne $t1, $t3, readingPLU	# se t1 è diverso da t3 allora passo all'ean successivo del plu
        		addi $t0, $t0, 1	# i++ sul buffer del plu
        		addi $t2, $t2, 1	# i++ sull'ean inserito
        		lb $t1, ($t0)		# leggo il carattere successivo	del plu
        		lb $t3, ($t2)		# leggo il carattere successivo dell'ean inserito
        		j check_loop
        	
        	j readingPLU
	ean_founded:
		la $a1, ($s2)	# passo il boolean alla funzione printItem
	
		addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal printItem		# Stampo l'artiocolo trovato
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

printItem:
	la $t7, ($a1)			# Booleano update tra_total
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

	read_price_loop:		# Leggo carattere per carattere fino ad arrivare al carattere di fine riga
		lb $t1, ($t0)
		beq $t1, $t3, out_price
		sb $t1, ($t4)
		addi $t0, $t0, 1
		addi $t4, $t4, 1
	j read_price_loop

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
	
	li $v0, 1
	la $a0, ($t2)
	syscall
	
	beqz $t7, end_print_line
	add $t4, $t4, $t2		# incremento il totale complessivo con il prezzo appena generato
	sw $t4, tra_total
	
	end_print_line:
	jr $ra
	
# Funzione che aggiunge l'ean al cart ed incrementa il numero di articoli venduti
addToCart:
	# in $a0 avrò l'ean
	move $t0, $a0 		# EAN
	
	la $t3, cart		# Mi carico posizione dello stack + indice stack
	lw $t4, 0($t3)
	la $t5, n_articoli
	
	li $v0, 9		# Creo spazio [9]
	li $a0, 8		# 2 parole da 4byte
	syscall
	
	lw $t0, ($t0)
	sw $t0, 0($v0)		# Salvo l'ean nello spazio creato
	sw $t4, 4($v0)		# next = *old_stack
	
	lw $t6, 0($t5)		
	addi $t6, $t6, 1	# incremento l'indice dello stack
	
	sw $v0, 0($t3)		# Aggiorno lo stack pointer al nodo appena creato
	sw $t6, n_articoli 	# Aggiorno il contatore di elementi

	li $v0, 4
	la $a0, add_to_cart_str	 # Printo "aggiunto al carrello..."
	syscall
	jr $ra

printCart:
	la $t0, n_articoli			# Mi carico il numero di articoli nel carrello
	lw $t0, 0($t0)
	la $t1, cart				# Mi carico posizione dello stack
	
	PRINT:
		lw $t2, 0($t1)
	
		li $v0, 9		# Creo spazio [9]
		li $a0, 6		# 2 parole da 4byte
		syscall
		
		la $t3, ($v0) 
		
		lb $t4, 0($t2)			# ean 0
		sb $t4, 0($v0)
		lb $t4, 1($t2)			# ean 1
		sb $t4, 1($v0)
		lb $t4, 2($t2)			# ean 2
		sb $t4, 2($v0)
		lb $t4, 3($t2)			# ean 3
		sb $t4, 3($v0)
		lb $t4, line_break
		sb $t4, 4($v0)
		la $t1, 4($t2)			# puntatore successivo
		
		addi $sp, $sp, -4		# mi salvo nello stack il pointer al nodo successivo
       	 	sw $t1, 0($sp)
       	 	addi $sp, $sp, -4		# mi salvo nello stack il numero di articoli
        	sw $t0, 0($sp)
       	 	
		la $a0, ($t3)			# Passo la stringa estratta dallo stack
		li $a1, 1			# Booleano a 0 -> Non incremento il totale complessivo (verrà fatto nel printCart)
	
		addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal findEAN			# Cerco l'ean inserito sul file plu.dat
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
		
		lw $t0, 0($sp)			# mi carico il numero di articoli dallo stack
        	addi $sp, $sp, 4
        	lw $t1, 0($sp)			# mi carico il pointer al nodo successivo
        	addi $sp, $sp, 4
		subi $t0, $t0, 1
		bgt $t0, $zero, PRINT	
	jr $ra

printPriceFormatted:				# Funzione che permette di scrivere i prezzi formattati nel modo xxx.xx
	move $t0, $a0
	li $t1, 0
	check_length:
	lb $t2, ($t1)
	
	xor $t3, $t3, $t3  # $a2 will hold reverse integer
     	li $t4, 10
     	beqz $t1, end
	loop:
     		divu $a1, $t1      # Divide number by 10
     		mflo $a1           # $a1 = quotient
    		mfhi $t2           # $t2 = reminder
     		mul $a2, $a2, $t1  # reverse=reverse*10
     		addu $a2, $a2, $t2 #         + reminder    
     		bgtz $a1, loop
	end:
	
	
	jr $ra 

# Valutare se inserire funzionalità report
reportTOTALS:
	jr $ra