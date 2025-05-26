from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pandas as pd
import joblib
from utils.data_loader import carregar_dados_ativo

app = FastAPI()

# Carregamento dos modelos
modelos = {
    "clf": joblib.load("models/pipeline_clf.pkl"),
    "reg": joblib.load("models/pipeline_reg.pkl"),
    "tree": joblib.load("models/pipeline_tree.pkl")
}

class InputTicker(BaseModel):
    ativo: str

@app.post("/prever/")
def prever(input_data: InputTicker):
    ativo = input_data.ativo.upper()
    
    try:
        df = carregar_dados_ativo(ativo)
        if df.empty:
            raise ValueError("Dados não encontrados.")

        X = df.drop(columns=["data", "fechamento_proximo"])
        resultados = {}

        for nome, modelo in modelos.items():
            previsao = modelo.predict(X)
            resultados[nome] = float(previsao[-1])  # Último dia previsto

        return {
            "ativos": ativo,
            "previsoes": resultados
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
