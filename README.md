# 💡 FIAP - Tech Challenge Fase 3  
> API de Previsão de Preços e Classificação de Açõesda B3 com Machine Learning  

Este projeto faz parte do desafio da Fase 3 do Tech Challenge da FIAP. Ele consiste em criar uma pipeline de ingestão de dados, treino de modelos de Machine Learning e disponibilização de previsões por meio de uma API REST.

---

## 🔧 Tecnologias Utilizadas

- 🐍 Python 3.12  
- 🧪 Scikit-learn  
- 🔍 Pandas, Numpy  
- 🚀 FastAPI + Uvicorn  
- 📦 Joblib  
- 📊 Matplotlib / Seaborn (opcional)  
- 🐙 Git + GitHub  

---

## 📈 Funcionalidades

- Coleta e ingestão de dados históricos da B3
- Treinamento de modelos de:
  - Regressão (previsão de preço de fechamento futuro)
  - Classificação (sinal: compra, manter ou vender)
- Persistência dos modelos treinados (.pkl)
- Disponibilização dos modelos via API (FastAPI)
- DEMO: https://www.youtube.com/watch?v=pqZ9tURJRv0

---

## 🚀 Como Rodar Localmente

1. Clone o repositório:

```bash
git clone https://github.com/vitorefigenio/tech-challenge-fase3.git
cd tech-challenge-fase3
```

2. Crie um ambiente virtual:

```bash
python3 -m venv .venv
source .venv/bin/activate  # Mac/Linux
.venv\Scripts\activate     # Windows
```

3. Instale as dependências:

```bash
pip install -r requirements.txt
```

4. Execute o script de treinamento (se necessário):

```bash
python scripts/train_model.py
```

5. Inicie a API:

```bash
uvicorn app.main:app --reload
```

---

## 🧪 Exemplo de Requisição

POST `/predict`

```json
{
  "ativos": "B3SA3F"
}
```

Resposta:

```json
{
  "ativos": "B3SA3F",
  "previsoes": {
    "clf": 0,
    "reg": 14.89,
    "tree": 14.65
  }
}
```

> O campo `clf` representa a saída do modelo de classificação (ex: 0 = manter, 1 = comprar, 2 = vender).

---

## 🛠 Estrutura do Projeto

```
tech-challenge-fase3/
│
├── app/
|   ├── main.py
|   ├── models/
│   ├── ├── pipeline_tree.pkl
│   ├── ├── pipeline_reg.pkl
│   └── ├── ...
|   ├── utils/
|   ├── └── data_loader.py
├── data/
│   └── raw_data.csv
├── requirements.txt
└── README.md
```

---

## 📬 Contato

Desenvolvido por [Rodrigo Matheus da Silva e Vitor Efigenio Neto]
Projeto acadêmico — FIAP 2025  

---