# Projeto CNP (Contract Net Protocol)

Este projeto simula o protocolo CNP usando JaCaMo. Ha dois tipos de agentes:
initiators (iniciadores) e participants (participantes). Cada iniciador publica
um pedido de servico e seleciona a melhor proposta recebida. Os participantes
respondem com propostas baseadas na estrategia de preco.

## Visao geral do fluxo

1. Um iniciador cria um identificador de conversa (ConvId) para cada contrato.
2. O iniciador envia um CFP (call for proposal) via broadcast para todos.
3. Participantes com o servico compativel calculam um preco e respondem com
   propose; os demais respondem com refuse.
4. O iniciador espera 3 segundos por propostas.
5. Se houver propostas, escolhe o menor preco, aceita o vencedor e rejeita os
   demais.
6. O vencedor simula a execucao (500ms, 1000ms ou 2000ms) e envia inform_done.
7. O iniciador registra o resultado e as metricas.

## Agentes e responsabilidades

### Initiator (initiator.asl)

- Le contratos e tipo de servico injetados pelo arquivo cnp.jcm.
- Dispara varias execucoes do CNP em paralelo (uma por contrato).
- Envia CFP com um budget fixo (150).
- Coleta propostas e escolhe o vencedor por menor preco.
- Envia accept_proposal ao vencedor e reject_proposal aos demais.
- Aguarda confirmacao (inform_done) por ate 10 segundos.
- Emite linhas [METRIC] com resultado, tempo e dados do vencedor.

### Participant (participant.asl)

- Oferece um tipo de servico (compute, storage, network).
- Usa uma estrategia de preco:
  - random: preco entre 55 e 145
  - fixed: preco 80
  - aggressive: preco entre 30 e 50
  - conservative: preco entre 100 e 150
- Se o CFP combina com o servico, envia propose com o preco calculado.
- Se nao combina, envia refuse.
- Ao receber accept_proposal, simula execucao e envia inform_done.
- Ao receber reject_proposal, apenas registra e limpa o estado.

## Como o cnp.jcm define a simulacao

O arquivo cnp.jcm lista os agentes e injeta as crencas iniciais:

- Para cada iniciador:
  - contracts([1..i])
  - service(compute|storage|network)
- Para cada participante:
  - service(compute|storage|network)
  - strategy(random|fixed|aggressive|conservative)

Ele pode ser editado manualmente ou gerado por experiment.py.

## Etapas para executar

### 1) Executar uma rodada simples

- Rode o JaCaMo diretamente:

  ./gradlew run

Isso executa a configuracao atual em cnp.jcm e imprime os logs no terminal.

### 2) Rodar um experimento com log e metricas

- Use o script:

  ./run_experiment.sh <label> <segundos>

Exemplo:

  ./run_experiment.sh n5_m10_i3 25

Isso gera:
- results/<label>.log (log bruto)
- results/<label>_summary.txt (resumo de metricas)

### 3) Rodar a matriz de experimentos

- Execute:

  python3 experiment.py

O script gera diferentes configuracoes de n, m e i, roda o JaCaMo com timeout e
compara os resultados. Ao final, restaura o cnp.jcm baseline (n5_m10_i3).

## Metricas coletadas

As metricas sao emitidas por cada iniciador usando linhas [METRIC], contendo:

- result: done | fail | timeout
- conv: identificador da conversa
- service: tipo de servico
- proposals: numero de propostas recebidas
- winner e price: vencedor e preco (quando aplicavel)
- elapsed_ms: tempo total do contrato

O script metrics.py agrega essas metricas e imprime um resumo por execucao.

## Arquivos principais

- cnp.jcm: configuracao da MAS (agentes e crencas iniciais).
- src/agt/initiator.asl: logica do iniciador (CNP completo).
- src/agt/participant.asl: logica do participante (estrategias e execucao).
- run_experiment.sh: execucao com timeout e resumo de metricas.
- experiment.py: gera cnp.jcm e compara configuracoes.
- metrics.py: parser e resumo das linhas [METRIC].
