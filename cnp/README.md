# CNP — Contract Net Protocol em JaCaMo

Implementacao do Contract Net Protocol usando o framework JaCaMo (Jason + CArtAgO + Moise).
O sistema simula n iniciadores contratando servicos de m participantes, com cada iniciador
executando i contratos em paralelo.

## Estrutura de arquivos

```
cnp/
├── cnp.jcm                   # Configuracao da MAS: lista de agentes e crencas iniciais
├── build.gradle              # Build Gradle; roda com jacamo.infra.JaCaMoLauncher
├── src/
│   └── agt/
│       ├── initiator.asl     # Logica do agente iniciador (protocolo CNP completo)
│       └── participant.asl   # Logica do agente participante (estrategias de preco)
├── experiment.py             # Gera cnp.jcm, roda JaCaMo e compara configuracoes
├── metrics.py                # Parser de linhas [METRIC] para resumo de uma rodada
├── run_experiment.sh         # Shell wrapper: roda com timeout e salva logs
└── results/                  # Criado automaticamente; guarda logs e sumarios
```

## Como o protocolo funciona

```
Initiator                              Participants
    |                                       |
    |-- broadcast cfp(ConvId, Svc, 150) --> todos
    |                                       |
    |                        (svc match) propose(ConvId, Price)
    |                        (sem match) refuse(ConvId)
    |                                       |
    |  [aguarda 3s]                         |
    |                                       |
    |-- accept_proposal(ConvId) ----------> vencedor (menor preco)
    |-- reject_proposal(ConvId) ----------> demais
    |                                       |
    |                        [executa tarefa: 500ms | 1s | 2s]
    |                                       |
    |<-- inform_done(ConvId) -------------- vencedor
    |                                       |
    | [emite linha [METRIC]]
```

Cada iniciador dispara i intencoes paralelas (uma por contrato) usando `!!run_cnp(Idx)`.
O identificador de conversa `cnp(NomeAgente, Idx)` garante que propostas de rodadas
distintas nao se misturem.

## Agentes

### initiator.asl

Crencas injetadas pelo `cnp.jcm`:
- `contracts([1,..,i])` — indices dos contratos a executar em paralelo
- `service(compute|storage|network)` — tipo de servico solicitado

Fluxo por contrato:
1. Gera `ConvId = cnp(Me, Idx)` e registra o timestamp de inicio
2. Faz broadcast do `cfp(ConvId, Svc, 150)`
3. Aguarda 3 segundos e coleta todas as crencas `propose(ConvId, _)`
4. Seleciona o menor preco com `!find_winner`
5. Envia `accept_proposal` ao vencedor e `reject_proposal` aos demais
6. Aguarda `inform_done` por ate 10 segundos
7. Emite linha `[METRIC]` com resultado, preco, numero de propostas e tempo total

### participant.asl

Crencas injetadas pelo `cnp.jcm`:
- `service(compute|storage|network)` — servico oferecido
- `strategy(random|fixed|aggressive|conservative)` — estrategia de preco

Estrategias de preco:

| Estrategia   | Precos possiveis         | Comportamento esperado          |
|--------------|--------------------------|----------------------------------|
| random       | 55, 80, 100, 120, 145    | Resultado imprevisivel           |
| fixed        | 80                       | Preco constante, competitivo     |
| aggressive   | 30, 35, 40, 45, 50       | Ganha com frequencia             |
| conservative | 100, 110, 120, 135, 150  | Raramente vence                  |

Ao receber `accept_proposal`, simula execucao com tempo aleatorio (500ms, 1s ou 2s)
e envia `inform_done` ao iniciador.

## Parametros de configuracao

O arquivo `cnp.jcm` define n, m e i:

| Parametro | Significado                          | Restricao  |
|-----------|--------------------------------------|------------|
| n         | Numero de iniciadores                | 1 < n < 200 |
| m         | Numero de participantes              | 1 < m < 50  |
| i         | Contratos paralelos por iniciador    | 0 < i < 10  |

Total de contratos na rodada = `n × i`.

Exemplo de `cnp.jcm` com n=2, m=3, i=2:

```
mas cnp {
    agent in1 : initiator.asl {
        beliefs: contracts([1,2]), service(compute)
    }
    agent in2 : initiator.asl {
        beliefs: contracts([1,2]), service(storage)
    }
    agent pa1 : participant.asl {
        beliefs: service(compute), strategy(aggressive)
    }
    agent pa2 : participant.asl {
        beliefs: service(storage), strategy(fixed)
    }
    agent pa3 : participant.asl {
        beliefs: service(network), strategy(random)
    }
}
```

## Como executar

### Rodada simples

```bash
cd cnp
./gradlew run
```

O JaCaMo nao encerra automaticamente apos os agentes terminarem. Pressione `Ctrl+C`
quando aparecer a linha `[DONE]` do ultimo contrato.

### Ver metricas de uma rodada

```bash
./gradlew run > run.log 2>&1
python3 metrics.py < run.log
```

Saida de exemplo:

```
==================================================
  CNP Metrics Summary  (15 contracts)
==================================================
  Success (done)  :   15  (100.0%)
  No bids (fail)  :    0  (0.0%)
  Timeout         :    0  (0.0%)

--- Winning Price (done contracts) ---
  min=30  max=80  mean=54.3  median=45.0

--- End-to-end Latency ms (done) ---
  min=3518  max=5027  mean=4247.5  median=4021.0

--- Proposals per contract ---
  min=3  max=4  mean=3.40

--- Results by service type ---
  compute      total=6 done=6 avg_price=38.3
  network      total=1 done=1 avg_price=40.0
  storage      total=4 done=4 avg_price=73.8

--- Winner frequency (strategy proxy) ---
  pa7      won   6 contract(s)
  pa2      won   3 contract(s)
```

### Rodar matriz de experimentos

```bash
python3 experiment.py
```

Executa as 6 configuracoes da `DEFAULT_MATRIX`, salva os logs em `results/` e imprime
uma tabela comparativa ao final. Restaura o `cnp.jcm` baseline (n=5, m=10, i=3)
automaticamente.

Para rodar uma unica configuracao sem alterar a matriz:

```bash
python3 experiment.py --n 10 --m 5 --i 2
```

Matriz padrao:

| Label         |  n |  m |  i | Total contratos | Objetivo                         |
|---------------|----|----|-----|-----------------|----------------------------------|
| n2_m5_i1      |  2 |  5 |  1 |  2              | Baseline minimo                  |
| n5_m10_i3     |  5 | 10 |  3 | 15              | Baseline principal               |
| n10_m10_i3    | 10 | 10 |  3 | 30              | Efeito de mais iniciadores       |
| n20_m10_i5    | 20 | 10 |  5 | 100             | Carga alta                       |
| n5_m3_i3      |  5 |  3 |  3 | 15              | Participantes escassos           |
| n5_m20_i3     |  5 | 20 |  3 | 15              | Participantes abundantes         |

### Rodar com shell script (log + resumo por arquivo)

```bash
./run_experiment.sh <label> <segundos>
# Exemplo:
./run_experiment.sh n5_m10_i3 25
```

Gera `results/<label>.log` e `results/<label>_summary.txt`.

## Metricas coletadas

Cada contrato emite uma linha `[METRIC]` no formato:

```
[METRIC] result=done conv=cnp(in1,2) service=compute proposals=4 winner=pa7 price=35 elapsed_ms=5019
```

| Campo        | Valores possiveis          | Descricao                              |
|--------------|----------------------------|----------------------------------------|
| result       | done / fail / timeout      | Desfecho do contrato                   |
| conv         | cnp(NomeAgente, Idx)       | Identificador unico da conversa        |
| service      | compute / storage / network | Tipo de servico solicitado             |
| proposals    | inteiro >= 0               | Propostas recebidas                    |
| winner       | nome do agente             | Vencedor (ausente em fail)             |
| price        | inteiro                    | Preco aceito (ausente em fail)         |
| elapsed_ms   | inteiro                    | Tempo total desde o CFP ate o DONE     |

## Interpretando os resultados

- **success_pct < 100%** com `fail` alto indica m muito baixo ou distribuicao de servicos
  incompativel (todos os participantes oferecem servico diferente do solicitado).
- **avg_price cai** conforme m aumenta — mais competicao reduz o preco vencedor.
- **latency ~3s** independente de n e m porque o gargalo e o `.wait(3000)` fixo do CFP.
  Variacoes acima de 3s vem do tempo de execucao simulado (500ms–2000ms).
- **proposals/cnp** sobe linearmente com m (proporcional a participantes com servico
  compativel, que e aproximadamente m/3 para a distribuicao ciclica padrao).
- **top_winner** com estrategia `aggressive` domina porque seus precos (30–50) ficam
  abaixo de qualquer outra estrategia.

## Requisitos

- JDK 17+
- Python 3.10+ (para `list[dict]` type hints em experiment.py)
- Sem dependencias Python externas (stdlib apenas)
