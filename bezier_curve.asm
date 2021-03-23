 ###################################################################################################
 #              RYSOWANIE TROJPUNKROWEJ KRZYWEJ BEZIERA NA OBRAZKU BMP
 ###################################################################################################
	.macro READ_BMP(%what, %n_bytes) 
  li $v0, 14
  move $a0, $s0
  la $a1, %what # Bedziemy wczytywac do zmiennej %what
  li $a2, %n_bytes     #->> n
  syscall
	.end_macro
	
	.macro READ_DATA(%coordinate, %register) 
# File Specifics
# format: char+3 numbers+char+3 numbers+char+3 numbers+char+3 numbers+char+3 numbers+char+3 numbers
# order: p1(x,y) p2(x,y) p3(x,y)
   # Pomijam 1 bajt spacji ->0 ->>>1
  li $v0, 14
  move $a0, $t9
  la $a1, buffer     #ladujemy w puste miejce
  li $a2, 1 #->>1
  syscall
  
  # Odczytuje coordynate ->1 ->>>3
  li $v0, 14
  move $a0, $t9   #ladujemy deskryptor
  la $a1, %coordinate   # Bedziemy wczytywac do zmiennej %coordinate
  li $a2, 3    #->>3
  syscall
  #przetwarzamy na cyfry
  la $t0, %coordinate
  lb $t1, ($t0)
  subu $t1, $t1, 48    #przetwarzamy na liczbe
  mulu $t1, $t1, 100    #robimy liczbe setna np 2->2*100=200
  addiu $t0, $t0, 1    #przechodzimy na nastepna liczbe
  lb $t2, ($t0)
  subu $t2, $t2, 48    #robimy z symbola liczbe
  mulu $t2, $t2, 10    #robimy liczbe dziesietna np 2->2*10=20
  addiu $t0, $t0, 1    #przechodzimy na nastepna liczbe
  lb $t3, ($t0)
  subu $t2, $t2, 48    #robimy z symbola liczbe
  addu $t1, $t1, $t2    # 200+20=220
  addu $t1, $t1, $t3    # 220+3=223
  move %register, $t1
	.end_macro
 
 
	.data
  # Wiadomosci tekstowe:
  file_error_text:	.asciiz "File error!\n"
  final_text: 		.asciiz "\n*** The End  ***\n"
  # Pliki
  result_file: 		.asciiz "bzr_crv.bmp" #plik docelowy
  # Dane pliki 
  name_file:		.asciiz "whiteboard.bmp" # baza
  name_file_par:	.asciiz "arguments"	   # plik z parametramy
	.align 2
  size: 	.space 4 # Rozmiar pliku
  offset: 	.space 4 # Przesuniecie do tablicy pikseli
  width: 	.space 4 # Szerokosc w pikselach
  height: 	.space 4 # Wysokosc w pikselach
  
  #Plik z parametrami
  X1_text:	.asciiz "\nThe abscissa of P1: "
  Y1_text:	.asciiz	"\nThe ordinate of P1: "
  X2_text:	.asciiz	"\nThe abscissa of P2: "
  Y2_text:	.asciiz	"\nThe ordinate of P2: "
  X3_text:	.asciiz	"\nThe abscissa of P3: "
  Y3_text:	.asciiz	"\nThe ordinate of P3: "
      .align 2
  X1:	.space 4
  Y1:	.space 4
  X2:	.space 4
  Y2:	.space 4
  X3:	.space 4
  Y3:	.space 4
  
  buffer:   .space 4 # Bufor odczytu pliku
#  tmp:        .space 4    #tylko do testowania

	.text
  .globl main
main:

  # Otwieram plik do odczytu
  li $v0, 13
  la $a0, name_file
  li $a1, 0
  li $a2, 0
  syscall
  bltz $v0, file_error # cos jest nie tak z odczytem pliku
  move $s0, $v0 # pamietamy deskryptor $s0
  
# ODCZYT PLIKU BMP
  # Pomijam "BM" ->0 ->>>2
  READ_BMP(buffer,2)

  # Odczytuje rozmiar pliku ->2 ->>>6
  READ_BMP(size,4)
  lw $s1, size # Zapamietujemy rozmiar w $s1   
        
  # Pomijam 4 bajty zarezerwowane ->6   ->>>10
  READ_BMP(buffer,4)
  
  # Odczytuje przesuniecie do tablicy pikseli  ->10  ->>>14
  READ_BMP(offset,4)
  lw $s2, offset # Zapamietujemy przesuniecie w $s2 
  
  # Pomijam 4 bajty naglowka informacyjnego  ->14  ->>>18
  READ_BMP(buffer,4)
  
  # Odczytuje szerokosc  ->18  ->>>22
  READ_BMP(width,4)
  lw $s3, width # pamietamy szerokosc pliku 
    
  # Odczytuje wysokosc        ->22  ->>>26
  READ_BMP(height,4)
  lw $s4, height # pamietamy wysokosc pliku
  
  # Zamykam plik
  li $v0, 16
  move $a0, $s0
  syscall
  
   
# ALOKACJA PAMIECI NA WCZYTANIE PLIKU
  li $v0, 9 
  move $a0, $s1 #wczytujemy pobrany rozmiar
  syscall
  move $s5, $v0 #pamietamy adres
  
# PONOWNIE OTWIERAM PLIK I ZAPISUJE JEGO ZAWARTOSC W PAMIECI OPERATYWNEJ
  # Otwieram plik do odczytu
  li $v0, 13
  la $a0, name_file    #ta nazwa jest bez \n!!!!!!!
  li $a1, 0
  li $a2, 0
  syscall
  bltz $v0, file_error # Nie udalo sie otworzyc pliku
  move $s0, $v0 # pamietamy deskryptor s0
  # zapisujemy plik do pamięci
  li $v0, 14
  move $a0, $s0 # Podaje deskryptor
  move $a1, $s5 # Bedziemy wczytywac rozmiar do zaalokowanej pamieci
  move $a2, $s1 # Odczytujemy caly plik
  syscall
  # Zamykam plik
  li $v0, 16
  move $a0, $s0
  syscall    
# KONIEC POBRANIA  PARAMETROW


# OBLICZAM PADDING NA WIERSZ
  li $t4, 4  #musimy miec 4, bo taki jest rozmiar wiersza (w bajtach)
  mulu $t0, $s3, 3 # obliczmy ile baj niesi informacji, $s3 szerokosc pliku width width/3=t0
  divu $t0, $t4 # Dzielimy wynik przez 4  t0/4=HI
  mfhi $t0 # Zapisujemy wynik do $t0    
  subu $t0, $t4, $t0 # Odejmujemy reszte od 4 aby otrzymac padding na wiersz
  divu $t0, $t4 # Dzielimy wynik przez 4 aby uniknac przypadku gdy padding == 0
  mfhi $s0 # s0=padding

#ODCZYT PLIKU Z PARAMETRAMI
  # Otwieram plik do odczytu
  li $v0, 13        
  la $a0, name_file_par           
  li $a1, 0
  li $a2, 0
  syscall
  bltz $v0, file_error # Nie udalo sie otworzyc pliku   
  move $t9, $v0 # Zapamietuje deskryptor pliku w $s0
  
# ODCZYT PLIKU

 READ_DATA(X1,$t4)
 READ_DATA(Y1,$t5)
         				
 READ_DATA(X2,$t6)
 READ_DATA(Y2,$t7)
 
 READ_DATA(X3,$t8)
 READ_DATA(Y3,$t9)
      
 # Zamykam plik
  li $v0, 16
  move $a0, $t9
  syscall

#koniec odczytu parametrow


# Sam algorytm

	move $t1, $zero 
	move $t2, $zero

	li $k0, 100  # T
	mulu $k1, $k0, $k0  # T^2
	
	#$t1 iterator
	#$t2 iterator^2
	#$t0 akumulator
	#$t3 Bx
	#$s7 By
calc:	
	beq $t1, $k0, close_file 
	addiu $t1, $t1 1#incrementation
	mul $t2, $t1, $t1 #iterator^2
	# obliczamy Bx
	mul $t3, $t8, $t2 # Bx = P2x * i^2
	mul $t0, $k0, $t1# akumulator = T*i
	subu $t0, $t0, $t2 # akumulator = akumulator - t^2 = T*i - i^2
	mul $t0, $t0, 2 # akumulator = akumulator*2 = 2*(T*i - i^2)
	mul $t0, $t0, $t6 # akumulator = akumulator*P1x = P1x * 2*(T*i - i^2)
	addu $t3, $t3, $t0 # Bx = P1x * 2*(T*i - i^2) + P2x * i^2  
	addu $t0, $k1, $t2 # akumulator = T^2 + i^2
	mul $t0, $t0, $t4 # akumulator = akumulator*P0x = P0x * (T^2 + i^2)
	addu $t3, $t3, $t0 # Bx = P1x * 2*(T*i - i^2) + P2x * i^2  + P0x * (T^2 + i^2)
	mul $t0, $k0, $t1# akumulator = T*i
	mul $t0, $t0, 2 # akumulator = akumulator*2 = 2*T*i
	mul $t0, $t0, $t4 # akumulator = akumulator*P0x = P0x * 2*T*i
	subu $t3, $t3, $t0 # Bx = P1x * 2*(T*i - i^2) + P2x * i^2  + P0x * (T^2 + i^2) - P0x * 2*T*i
	divu $t3, $k1
	mflo $t3
	
	
	# obliczamy By
	mul $s7, $t9, $t2 # By = P2y * i^2
	mul $t0, $k0, $t1# akumulator = T*i
	subu $t0, $t0, $t2 # akumulator = akumulator - t^2 = T*i - i^2
	mul $t0, $t0, 2 # akumulator = akumulator*2 = 2*(T*i - i^2)
	mul $t0, $t0, $t7 # akumulator = akumulator*P1y = P1y * 2*(T*i - i^2)
	addu $s7, $s7, $t0 # By = P1y * 2*(T*i - i^2) + P2y * i^2  
	addu $t0, $k1, $t2 # akumulator = T^2 + i^2
	mul $t0, $t0, $t5 # akumulator = akumulator*P0y = P0y * (T^2 + i^2)
	addu $s7, $s7, $t0 # By = P1y * 2*(T*i - i^2) + P2y * i^2  + P0y * (T^2 + i^2)
	mul $t0, $k0, $t1# akumulator = T*i
	mul $t0, $t0, 2 # akumulator = akumulator*2 = 2*T*i
	mul $t0, $t0, $t5 # akumulator = akumulator*P0y = P0y * 2*T*i
	subu $s7, $s7, $t0 # By = P1y * 2*(T*i - i^2) + P2y * i^2  + P0y * (T^2 + i^2) - P0y * 2*T*i
	divu $s7, $k1
	mflo $s7
	
	
#RYSOWANIE

 #liczymy to na mapie

  bgt $t3, $s3, close_file # x>width wyslismy za pole
  bgt $s7, $s4, close_file # y>height wyslismy za pole
  blez $t3, close_file # x<=0 wyslismy za pole
  blez $s7, close_file # y<=0 wyslismy za pole

  # wsk_zapisu = poczatek_bitmapy + offset + (3*width + padding)*(y - 1) + (x - 1)*3, czyli:  t0 = s5 + s2 + (3*s3 + s0)*(t9 - 1) + (t8 - 1)*3

  mul $t0, $s3, 3 #3*width
   # t0 = 3*s3
  addu $t0, $t0, $s0  #3*width + padding
  # t0 = 3*s3 + s0
  subiu $s7, $s7, 1 #y - 1
  # t9 = t9 - 1
  mul $t0, $t0, $s7 #(3*width + padding)*(y - 1)
  # t0 =  (3*s3 + s0)*(t9 - 1)
  subiu $t3, $t3, 1 #x - 1
  # t8 = t8 - 1
  mul $t3, $t3, 3 #(x - 1)*3
  # t8 = (t8 - 1)*3
  addu $t0, $t0, $t3  #(3*width + padding)*(y - 1) + (x - 1)*3
  # t0 = (3*s3 + s0)*(t9 - 1) + (t8 - 1)*3
  addu $t0, $t0, $s5 #offset + (3*width + padding)*(y - 1) + (x - 1)*3
  # t0 = s5 + (3*s3 + s0)*(t9 - 1) + (t8 - 1)*3
  addu $t0, $t0, $s2 #poczatek_bitmapy + offset + (3*width + padding)*(y - 1) + (x - 1)*3
  # t0 = s5 + s2 + (3*s3 + s0)*(t9 - 1) + (t8 - 1)*3
  # Jestesmy na miejscu - malujemy na czarno
  sb $0, ($t0)
  sb $0, 1($t0)
  sb $0, 2($t0)
  # liczymy kolejne pkt-ty
  b calc
    

# ZAPISUJEMY PLIK
close_file:
  # Otwieram plik do zapisu
  li $v0, 13
  la $a0, result_file
  li $a1, 1
  li $a2, 0
  syscall
  bltz $v0, file_error 
  move $s0, $v0 
  # Zapisuje do pliku z zaalokowanej pamieci
  li $v0, 15
  move $a0, $s0 
  move $a1, $s5 # Bedziemy pisac z zaalokowanej pamieci
  move $a2, $s1 # Zapisujemy caly plik
  syscall 
  b terminate
  
# BLAD PLIKU
file_error:
  li $v0, 4 
  la $a0, file_error_text
  syscall
    
# ZAKONCZENIE PROGRAMU
terminate:
  li $v0, 4 
  la $a0, final_text 
  syscall
  li $v0, 10
  syscall

