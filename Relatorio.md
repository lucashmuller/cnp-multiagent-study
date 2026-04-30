# Relatorio - Contract Net Protocol (CNP)

## Resumo

[Escreva 1 paragrafo curto com objetivo, metodo e principais achados.]

## 1. Introducao

[Contextualize CNP, agentes e motivacao do estudo.]

## 2. Objetivo e escopo

- Objetivo principal:
- Escopo da implementacao:
- Hipoteses ou perguntas de pesquisa:

## 3. Implementacao

### 3.1 Arquitetura do SMA

- Tipos de agentes: initiators e participants
- Responsabilidades de cada tipo
- Servicos suportados (compute, storage, network)

### 3.2 Protocolo CNP (fluxo)

1. Initiator cria ConvId e envia CFP
2. Participants respondem com propose ou refuse
3. Initiator aguarda propostas
4. Escolha do vencedor (menor preco)
5. Accept para vencedor e reject para demais
6. Participant executa tarefa e envia inform_done
7. Initiator registra metricas

### 3.3 Configuracao

- Parametros n, m, i
- Como o cnp.jcm injeta crencas iniciais
- Estrategias de preco (random, fixed, aggressive, conservative)

## 4. Metodologia experimental

### 4.1 Variaveis

- n: numero de initiators
- m: numero de participants
- i: contratos paralelos por initiator

### 4.2 Ambiente

- SO:
- CPU/RAM:
- JDK:
- Versao do JaCaMo:

### 4.3 Procedimento

- Como executar um cenario
- Como coletar logs e metricas
- Timeout e duracao de cada execucao

### 4.4 Metricas definidas

- Taxa de sucesso (done / total)
- Numero medio de propostas por contrato
- Latencia media e maxima (ms)
- Preco medio do vencedor (min, max)
- Taxa de timeout

## 5. Resultados

### 5.1 Tabela de resultados por configuracao

| n | m | i | contratos | sucesso % | propostas/contrato | latencia media (ms) | preco medio | timeouts |
|---|---|---|-----------|-----------|--------------------|---------------------|-------------|----------|
|   |   |   |           |           |                    |                     |             |          |

### 5.2 Graficos (se aplicavel)

- Grafico 1: sucesso vs n
- Grafico 2: latencia vs i
- Grafico 3: propostas vs m

## 6. Analise das variacoes de n, m, i

- Impacto de n no sucesso e latencia
- Impacto de m na concorrencia e preco
- Impacto de i na sobrecarga e timeouts

## 7. Avaliacao da abordagem por agentes

- Vantagens observadas
- Desvantagens ou limitacoes
- Adequacao do modelo BDI para CNP

## 8. Avaliacao das ferramentas

- Experiencia com JaCaMo/Jason
- Facilidade de instrumentacao e debug
- Ponto fortes e fracos da stack

## 9. Ameacas a validade e limitacoes

- Variacao de hardware/ambiente
- Amostragem e numero de execucoes
- Simplificacoes do modelo

## 10. Conclusao e trabalhos futuros

- Principais resultados
- Resposta as perguntas iniciais
- Proximos passos

## Referencias

- Contract Net Protocol: https://en.wikipedia.org/wiki/Contract_Net_Protocol
- JaCaMo: https://jacamo-lang.github.io
