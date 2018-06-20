.section .data
  topoInicialHeap: .quad 0
  topoAtualHeap: .quad 0
  enderecoProxBloco: .quad 0

  str1: .string "################"
  str2: .string "+"
  str3: .string "-"
  str4: .string "Memória vazia \n"
  str5: .string "\n"

  .equ TAM_HEADER, 16
  .equ HDR_DISPONIVEL, 0
  .equ HDR_TAM_BLOCO, 8
  .equ LIVRE, 0
  .equ OCUPADO, 1
.section .text

/* ################################ INICIA ALOCADOR #################################### */

iniciaAlocador:
  pushq %rbp
  movq %rsp, %rbp

  movq $12, %rax
  movq $0, %rdi
  syscall
  movq %rax, topoInicialHeap
  movq %rax, topoAtualHeap

  popq %rbp
  ret

  /* ################################ FINALIZA ALOCADOR #################################### */

finalizaAlocador:
  pushq %rbp
  movq %rsp, %rbp

  movq topoInicialHeap, %rdi
  movq $12, %rax
  syscall

  popq %rbp
  ret

  /* ################################ ALOCA #################################### */

alocaMem:
  pushq %rbp
  movq %rsp, %rbp

  movq 8(%rbp), %rcx /* %rcx conterá o tamanho desejado para alocação, (passado como parâmetro) */
  movq topoInicialHeap, %rax /* %rax conterá o início da heap, que é a partir de onde começaremos a busca por um bloco livre */
  movq topoAtualHeap, %rbx /* %rbx conterá o valor atual da brk */

aloca_loop: /* iteração entre cada bloco de memória */
  cmpq %rbx, %rax /* mais memória é necessária se percorremos toda a heap ou se nenhum bloco foi alocado */
  je aumenta_brk

  movq HDR_TAM_BLOCO(%rax), %rdx /* %rdx conterá o tamanho do bloco atual */

  cmpq $OCUPADO, HDR_DISPONIVEL(%rax) /* se o bloco estiver indisponíel, vai para o próximo */
  je prox_bloco

  cmpq %rdx, %rcx /* se o espaço estiver disponível, compara o tamanho. Se o tamanho for suficiente, só vai */
  jle aloca

prox_bloco:
  addq $TAM_HEADER, %rax
  addq %rdx, %rax /* %rax recebe o endereço do próximo bloco de memória */

  jmp aloca_loop

aloca:
  movq $OCUPADO, HDR_DISPONIVEL(%rax) /* marca o bloco como ocupado */

  addq $TAM_HEADER, %rax /* %rax agora contém o endereço do primeiro byte de memória utilizavel do bloco, que é o que retornaremos */

  popq %rbp
  ret

aumenta_brk:
  addq $TAM_HEADER, %rbx
  addq %rcx, %rbx /* %rbx agora contém o futuro valor da brk */

  pushq %rax /* guarda o endereço contido em %rax (endereço do começo do bloco que estamos tratando), pois usaremos %rax para a syscall */

  movq $12, %rax
  movq %rbx, %rdi
  syscall /* aumenta brk */

  popq %rax
  movq $OCUPADO, HDR_DISPONIVEL(%rax) /* marca o bloco como ocupado */
  movq %rcx, HDR_TAM_BLOCO(%rax) /* insere o tamanho do bloco no campo apropriado */

  addq $TAM_HEADER, %rax /* %rax agora contém o endereço do primeiro byte de memória utilizavel do bloco, que é o que retornaremos */
  movq %rbx, topoAtualHeap /* salva o novo valor da brk */

  popq %rbp
  ret

/* ################################ DESALOCA #################################### */

desalocaMem:
  pushq %rbp
  movq %rsp, %rbp

  movq 8(%rbp), %rax /* move o endereço indicado para desalocação (passado como parâmentro), para %rax */
  subq $TAM_HEADER, %rax /* move %rax para o real início do bloco */

  movq $LIVRE, HDR_DISPONIVEL(%rax) /* indica que o bloco está livre */

  popq %rbp
  ret

  /* ################################ IMPRIME MAPA DA HEAP #################################### */

imprimeMapaHeap:
  pushq %rbp
  movq %rsp, %rbp

  movq topoInicialHeap, %rax /* %rax conterá o início da heap */
  movq topoAtualHeap, %rbx /* %rbx conterá o valor atual da brk */

  cmpq %rbx, %rax /* caso a heap esteja vazia imprime "Memória Vazia" e encerra */
  je heap_vazia

imprime_loop: /* itera entre os blocos de memória */
  cmpq %rbx, %rax /* caso todos os blocos tenham sido percorridos, encerra */
  je fim_imprime_loop

  movq HDR_TAM_BLOCO(%rax), %rdx /* %rdx conterá o tamanho do bloco atual */
  movq HDR_DISPONIVEL(%rax), %rcx /* %rcx conterá a informação se o bloco está ocupado ou não */

  addq $TAM_HEADER, %rax
  addq %rdx, %rax /* já move %rax para o endereço do próximo bloco */
  movq %rax, enderecoProxBloco

  cmpq $LIVRE, %rcx /* desvia o fluxo para imprimir os caracteres corretos */
  je imprime_bytes_livre


imprime_bytes_ocupado:
  movq $0, %rax
  movq $str1, %rdi
  call printf /* imprime os bytes correspondentes às informações gerenciais */

  movq $0, %rcx
loop_imprime_bytes_ocupado: /* loop que imprime os bytes correspondentes à memória alocada propriamente dita */
  cmpq %rcx, %rdx /* caso todos os bytes do bloco já tenham sido impressos, retorna para o imprime_loop, com %rax já contendo o endereço do próximo bloco */
  je imprime_loop

  movq $0, %rax
  movq $str3, %rdi /* imprime '-' */
  call printf

  movq enderecoProxBloco, %rax
  addq $1, %rcx
  jmp loop_imprime_bytes_ocupado


imprime_bytes_livre:
  movq $0, %rax
  movq $str1, %rdi
  call printf /* imprime os bytes correspondentes às informações gerenciais */

  movq $0, %rcx
loop_imprime_bytes_livre: /* loop que imprime os bytes correspondentes à memória alocada propriamente dita */
  cmpq %rcx, %rdx /* caso todos os bytes do bloco já tenham sido impressos, retorna para o imprime_loop, com %rax já contendo o endereço do próximo bloco */
  je imprime_loop

  movq $0, %rax
  movq $str3, %rdi /* imprime '+' */
  call printf

  movq enderecoProxBloco, %rax
  addq $1, %rcx
  jmp loop_imprime_bytes_livre

heap_vazia:
  movq $0, %rax
  movq $str4, %rdi /* imprime 'Memória vazia \n' */
  call printf

fim_imprime_loop:
  popq %rbp
  ret