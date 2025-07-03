# **meta/**

Este diretório reúne **todos os scripts, notebooks e funções auxiliares** usados para executar a **revisão sistemática com meta‑análise e meta‑regressão**. As análises foram conduzidas em **R - 4.5.1** (modelagem estatística) e **Python - 3.10.10** (visualizações) e organizadas em duas subpastas principais.

> **Observação:** Devido à elevada heterogeneidade entre os estudos, empregou‑se um **modelo multilevel de efeitos aleatórios (3 níveis)** com estimador **REML** (equivalente ao método DerSimonian‑Laird no caso bidimensional).

---

## Análises Estatísticas em R

Scripts R que executam toda a parte inferencial:

| Arquivo  | Função principal                                     |
| -------- | ---------------------------------------------------- |
| `meta.r` | *Pipeline* completo de meta‑análise e meta‑regressão |

Principais etapas implementadas:

1. **Pré‑processamento e padronização** dos dados (normalização do *F1‑score*, conversão para *logit*, cálculo de variâncias e SEs).
2. **Meta‑análise multilevel (3 níveis)** $`metafor::rma.mv()`$:

   * Estimativa global do efeito (\*combined mean F1\* + IC 95 % + IP 95 %).
   * Cálculo detalhado de **heterogeneidade** ($\sigma^2_{L3},\sigma^2_{L2},\sigma^2_{within}$, $I^2$ entre/‑dentro dos estudos).
3. **Verificação de viés de publicação**:

   * **Funnel plot** com contornos de significância.
   * **Teste de Egger** & métodos *Trim‑and‑Fill* / Begg & Mazumdar.
4. **Forest plot global** e **leave‑one‑out** (análise de influência).
5. **Sub‑análises & moderadores**:

   * Tipo de tarefa (*segmentation\_type*).
   * Arquitetura de rede (*arch\_grp*).
   * Fonte de dados/sensor (*sensor\_cat*).
6. **Meta‑regressão** contínua (resolução espacial) e geração de curvas preditas.
7. Geração de **tabelas console‑ready** para o manuscrito.

Todos os gráficos (funnel, forest, moderadores) são salvos em PDF para inclusão direta nos apêndices.

---

## Visualizações Interativas em Python (Jupyter)

Notebooks Python responsáveis por construir painéis e figuras exploratórias a partir dos *outputs* da meta‑análise:

| Notebook           | Propósito                                               |
| ------------------ | ------------------------------------------------------- |
| `metanalise.ipynb` | Coleção de células reutilizáveis para gráficos de apoio |

Funcionalidades principais:

1. **Histogramas** de distribuição de estudos por ano.
2. **Heatmaps** interativos:

   * *Estudo × Tipo de Segmentação*.
   * *Base Architecture × Segmentation Type* (com contagem de *arms* + IDs de estudo).
   * *Base Architecture × Data Source*.
   * *Validation Strategy × Estudo*.
   * *Resolução × Faixa de F1‑score*.
3. **Gráficos de barras horizontais**: distribuição de estudos por país (anotados com ID).
4. Salvamento automático em PDF via `save_plot_pdf()` para uso direto no artigo/suplemento.

---

## Bibliotecas e Ferramentas Utilizadas

| Ambiente   | Versão  | Principais Pacotes                                                                  |
| ---------- | ------- | ----------------------------------------------------------------------------------- |
| **R**      | 4.5.1   | `metafor`, `readxl`, `dplyr`, `janitor`, `stringr`, `tibble`                        |
| **Python** | 3.10.10 | `pandas`, `numpy`, `matplotlib`, `statsmodels`, `seaborn*` (*opcional*), `openpyxl` |

\* *Seaborn é usado apenas para paletas de cores; todos os plots principais seguem as diretrizes do periódico (Matplotlib puro).*

---

### Como Reproduzir

1. Coloque o arquivo de dados (ex.: `meta_analysis_v4.xlsx`) na raiz do projeto.
2. Abra `meta/meta.r` e execute **todas as seções** em ordem; os gráficos e tabelas serão criados e devem ser exportados com Rstudio.
3. Abra `meta/metanalise.ipynb`, ajuste os caminhos para os *assets* gerados no passo 2 e **execute** as células desejadas.
