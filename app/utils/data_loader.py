import pandas as pd
import numpy as np

def carregar_dados_ativo(ativo: str) -> pd.DataFrame:
    df = pd.read_csv("../data/b3-tickers-raw.csv", parse_dates=["Data"])

    file_path = "../data/b3-tickers-raw.csv"
    colunas = ['ativo', 'data', 'abertura', 'maximo', 'minimo', 'fechamento', 'volume']
    df = pd.read_csv(file_path, names=colunas, encoding='utf-8', skiprows=1, parse_dates=["data"])
    df['data'] = pd.to_datetime(df['data'], format='%Y.%m.%d')

    df = df[df["ativo"] == ativo].sort_values(by=['ativo', 'data']).copy()
    
    
    # Variáveis numéricas
    df['retorno_diario'] = df['fechamento'].pct_change()
    df['valor_mm_5'] = df['fechamento'].rolling(window=5).mean()
    df['valor_mm_20'] = df['fechamento'].rolling(window=20).mean()
    df['volatilidade_5'] = df['fechamento'].rolling(window=5).std()
    df['retorno_acumulado'] = (1 + df['retorno_diario']).cumprod() - 1
    
    df['abertura_mm_5'] = df['abertura'].rolling(window=5).mean()
    df['abertura_mm_20'] = df['abertura'].rolling(window=20).mean()
    
    df['volume_mm_5'] = df['volume'].rolling(window=5).mean()
    df['volume_mm_20'] = df['volume'].rolling(window=20).mean()

    # Criar colunas de valores anteriores
    df['fechamento_anterior'] = df['fechamento'].shift(1)
    df['volume_anterior'] = df['volume'].shift(1)

    # Variáveis categóricas
    df['fechamento_categoria'] = np.select(
        [
            df['fechamento'] > df['fechamento_anterior'],
            df['fechamento'] < df['fechamento_anterior']
        ],
        ['acima', 'abaixo'],
        default='igual'
    )

    df['volume_categoria'] = np.select(
        [
            df['volume'] > df['volume_anterior'],
            df['volume'] < df['volume_anterior']
        ],
        ['acima', 'abaixo'],
        default='igual'
    )

    df["fechamento_proximo"] = df["fechamento"].shift(-1)
    df['dia_semana'] = df['data'].dt.dayofweek
    df['mes'] = df['data'].dt.month
    
    df = df.dropna().reset_index(drop=True)
    return df
