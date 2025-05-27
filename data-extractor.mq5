//+------------------------------------------------------------------+
//|                          BOVESPA_Data_Extractor.mq5              |
//|                             Copyright 2025                        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property version   "1.00"
#property description "Extrator de dados OHLC dos ativos da BOVESPA/FRACIONARIO"
#property strict

// Incluir bibliotecas necessárias
#include <Arrays\ArrayString.mqh>

// Definição de constantes
#define DATA_FOLDER "BOVESPA\\FRACIONARIO"  // Pasta de dados
#define YEARS_TO_LOAD 5                     // Quantidade de anos a serem carregados
#define TIMEFRAME PERIOD_D1                 // Timeframe diário

// Variáveis globais
CArrayString symbolsList;                   // Lista de símbolos
int allDataFileHandle = INVALID_HANDLE;     // Handle para o arquivo com todos os dados

// Input para controle do usuário
input bool ForceReprocessing = false;      // Forçar reprocessamento mesmo se já tiver sido executado

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Iniciando Extrator de Dados BOVESPA/FRACIONARIO...");
    
    // Verificar arquivo de controle para saber se já foi executado
    string controlFileName = "data-extractor\\processamento_completo.txt";
    bool alreadyProcessed = FileIsExist(controlFileName) && !ForceReprocessing;
    
    if(alreadyProcessed)
    {
        Print("Processamento já foi concluído anteriormente. Para executar novamente, ative a opção 'ForceReprocessing'.");
        return INIT_SUCCEEDED;
    }
    
    // Verificar se o terminal está conectado ao servidor
    if(!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        Print("Erro: Terminal não está conectado ao servidor. Por favor, conecte e tente novamente.");
        return INIT_FAILED;
    }
    
    // Listar todos os símbolos disponíveis na pasta BOVESPA/FRACIONARIO
    if(!ListSymbols())
    {
        Print("Erro: Falha ao listar os símbolos da pasta BOVESPA/FRACIONARIO.");
        return INIT_FAILED;
    }
    
    // Inicializar o arquivo all.txt que conterá todos os dados
    if(!InitializeAllDataFile())
    {
        Print("Erro: Falha ao inicializar o arquivo all.txt");
        return INIT_FAILED;
    }
    
    // Processar dados e salvar em arquivos
    ProcessSymbolsData();
    
    // Fechar o arquivo all.txt
    if(allDataFileHandle != INVALID_HANDLE)
    {
        FileClose(allDataFileHandle);
        Print("Arquivo all.txt fechado com sucesso.");
    }
    
    // Criar arquivo de controle para indicar que o processamento foi concluído
    CreateControlFile(controlFileName);
    
    // Finalizar com sucesso
    Print("Processamento concluído com sucesso!");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Limpar a lista de símbolos
    symbolsList.Clear();
    
    // Garantir que o arquivo all.txt esteja fechado
    if(allDataFileHandle != INVALID_HANDLE)
    {
        FileClose(allDataFileHandle);
    }
    
    Print("Extrator de Dados finalizado.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Nada a fazer aqui, todo o processamento é feito no OnInit
}

//+------------------------------------------------------------------+
//| Inicializar o arquivo all.txt para todos os dados                |
//+------------------------------------------------------------------+
bool InitializeAllDataFile()
{
    // Criar o diretório data-extractor na pasta Files do MT5
    string dataFolder = "data-extractor";
    if(!FolderCreate(dataFolder))
    {
        int error = GetLastError();
        // Ignorar erro se a pasta já existir
        if(error != 4301) // 4301 = diretório já existe
        {
            Print("Erro: Não foi possível criar a pasta ", dataFolder, ". Código de erro: ", error);
            return false;
        }
    }
    
    // Criar o nome do arquivo
    string fileName = dataFolder + "\\all.txt";
    
    // Abrir o arquivo para escrita
    allDataFileHandle = FileOpen(fileName, FILE_WRITE|FILE_TXT);
    
    if(allDataFileHandle == INVALID_HANDLE)
    {
        Print("Erro: Não foi possível abrir o arquivo ", fileName, " para escrita. Código de erro: ", GetLastError());
        return false;
    }
    
    // Escrever cabeçalho com a coluna adicional "Ativo"
    FileWrite(allDataFileHandle, "Ativo,Data,Abertura,Máxima,Mínima,Fechamento,Volume");
    
    Print("Arquivo all.txt inicializado com sucesso.");
    return true;
}

//+------------------------------------------------------------------+
//| Função para criar arquivo de controle                            |
//+------------------------------------------------------------------+
void CreateControlFile(string fileName)
{
    // Garantir que a pasta existe
    string dataFolder = "data-extractor";
    if(!FolderCreate(dataFolder))
    {
        int error = GetLastError();
        // Ignorar erro se a pasta já existir
        if(error != 4301) // 4301 = diretório já existe
        {
            Print("Aviso: Não foi possível criar a pasta ", dataFolder, ". Código de erro: ", error);
            return;
        }
    }
    
    // Criar arquivo de controle
    int fileHandle = FileOpen(fileName, FILE_WRITE|FILE_TXT);
    if(fileHandle != INVALID_HANDLE)
    {
        datetime currentTime = TimeCurrent();
        string timeStr = TimeToString(currentTime, TIME_DATE|TIME_SECONDS);
        FileWrite(fileHandle, "Processamento concluído em: " + timeStr);
        FileWrite(fileHandle, "Total de símbolos processados: " + IntegerToString(symbolsList.Total()));
        FileClose(fileHandle);
        Print("Arquivo de controle criado: ", fileName);
    }
    else
    {
        Print("Aviso: Não foi possível criar o arquivo de controle. Código de erro: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Função para listar todos os símbolos da pasta especificada       |
//+------------------------------------------------------------------+
bool ListSymbols()
{
    Print("Listando símbolos na pasta ", DATA_FOLDER, "...");
    
    // Limpar a lista de símbolos
    symbolsList.Clear();
    
    // Obter o número total de símbolos disponíveis
    int totalSymbols = SymbolsTotal(false);
    Print("Total de símbolos no Market Watch: ", totalSymbols);
    
    // Verificar cada símbolo
    for(int i = 0; i < totalSymbols; i++)
    {
        // Obter o nome do símbolo
        string symbol = SymbolName(i, false);
        
        // Verificar se o símbolo pertence à pasta BOVESPA/FRACIONARIO
        string symbolPath = SymbolInfoString(symbol, SYMBOL_PATH);
        
        // Debug: Mostrar o caminho do símbolo para entender como está estruturado
        Print("Símbolo: ", symbol, ", Caminho: ", symbolPath);
        
        if(StringFind(symbolPath, DATA_FOLDER) != -1)
        {
            // Adicionar à lista de símbolos
            symbolsList.Add(symbol);
            Print("Símbolo encontrado: ", symbol);
        }
    }
    
    // Verificar se foram encontrados símbolos
    int foundSymbols = symbolsList.Total();
    if(foundSymbols == 0)
    {
        Print("Aviso: Nenhum símbolo encontrado na pasta ", DATA_FOLDER);
        Print("Tentando listar todos os ativos disponíveis na BOVESPA...");
        
        // Segunda tentativa: listar apenas símbolos que começam com "BOVESPA\"
        for(int i = 0; i < totalSymbols; i++)
        {
            string symbol = SymbolName(i, false);
            string symbolPath = SymbolInfoString(symbol, SYMBOL_PATH);
            
            if(StringFind(symbolPath, "BOVESPA") != -1)
            {
                Print("Encontrado ativo BOVESPA: ", symbol, ", Caminho: ", symbolPath);
            }
        }
        
        return false;
    }
    
    Print("Total de símbolos encontrados: ", foundSymbols);
    return true;
}

//+------------------------------------------------------------------+
//| Função para processar os dados dos símbolos                      |
//+------------------------------------------------------------------+
void ProcessSymbolsData()
{
    int totalSymbols = symbolsList.Total();
    
    // Calcular a data inicial (5 anos atrás a partir de hoje)
    datetime startDate = TimeCurrent() - YEARS_TO_LOAD * 365 * 24 * 60 * 60;
    datetime endDate = TimeCurrent();
    
    Print("Período de dados: de ", TimeToString(startDate, TIME_DATE), " até ", TimeToString(endDate, TIME_DATE));
    
    // Processar cada símbolo
    for(int i = 0; i < totalSymbols; i++)
    {
        string symbol = symbolsList.At(i);
        
        Print("Processando símbolo ", i+1, " de ", totalSymbols, ": ", symbol);
        
        // Processar e salvar dados do símbolo
        if(!ProcessSymbol(symbol, startDate, endDate))
        {
            Print("Aviso: Falha ao processar o símbolo ", symbol);
            continue;
        }
    }
}

//+------------------------------------------------------------------+
//| Função para processar um símbolo específico                      |
//+------------------------------------------------------------------+
bool ProcessSymbol(string symbol, datetime startDate, datetime endDate)
{
    // Selecionar o símbolo no MarketWatch para garantir que os dados estejam disponíveis
    if(!SymbolSelect(symbol, true))
    {
        Print("Erro: Não foi possível selecionar o símbolo ", symbol);
        return false;
    }
    
    // Preparar o array de dados de preço
    MqlRates rates[];
    
    // Definir o horário de início para o processamento
    datetime fromDate = startDate;
    
    // Copiar os dados do símbolo
    int copied = CopyRates(symbol, TIMEFRAME, fromDate, endDate, rates);
    
    if(copied <= 0)
    {
        Print("Erro: Não foi possível copiar os dados do símbolo ", symbol, ". Código de erro: ", GetLastError());
        return false;
    }
    
    Print("Foram copiados ", copied, " candles para o símbolo ", symbol);
    
    // Salvar os dados em um arquivo de texto individual e também no arquivo all.txt
    return SaveSymbolData(symbol, rates, copied);
}

//+------------------------------------------------------------------+
//| Função para salvar os dados do símbolo em um arquivo             |
//+------------------------------------------------------------------+
bool SaveSymbolData(string symbol, const MqlRates &rates[], int count)
{
    // Criar o diretório data-extractor na pasta Files do MT5
    string dataFolder = "data-extractor";
    if(!FolderCreate(dataFolder))
    {
        int error = GetLastError();
        // Ignorar erro se a pasta já existir (código 4301)
        if(error != 4301) // 4301 = diretório já existe
        {
            Print("Erro: Não foi possível criar a pasta ", dataFolder, ". Código de erro: ", error);
            return false;
        }
    }
    
    // Criar o nome do arquivo individual
    string fileName = dataFolder + "\\" + symbol + ".txt";
    
    // Abrir o arquivo individual para escrita
    int fileHandle = FileOpen(fileName, FILE_WRITE|FILE_TXT);
    
    if(fileHandle == INVALID_HANDLE)
    {
        Print("Erro: Não foi possível abrir o arquivo ", fileName, " para escrita. Código de erro: ", GetLastError());
        return false;
    }
    
    // Escrever cabeçalho no arquivo individual
    FileWrite(fileHandle, "Data,Abertura,Máxima,Mínima,Fechamento,Volume");
    
    // Escrever os dados no arquivo individual e também no arquivo all.txt
    for(int i = 0; i < count; i++)
    {
        // Formatar a data
        string dateStr = TimeToString(rates[i].time, TIME_DATE);
        
        // Formatar a linha para o arquivo individual
        string line = StringFormat("%s,%.4f,%.4f,%.4f,%.4f,%d", 
                                  dateStr, 
                                  rates[i].open, 
                                  rates[i].high, 
                                  rates[i].low, 
                                  rates[i].close, 
                                  rates[i].tick_volume);
        
        // Escrever no arquivo individual
        FileWrite(fileHandle, line);
        
        // Formatar a linha para o arquivo all.txt (incluindo o nome do ativo)
        string allLine = StringFormat("%s,%s,%.4f,%.4f,%.4f,%.4f,%d", 
                                     symbol,
                                     dateStr, 
                                     rates[i].open, 
                                     rates[i].high, 
                                     rates[i].low, 
                                     rates[i].close, 
                                     rates[i].tick_volume);
        
        // Escrever no arquivo all.txt
        if(allDataFileHandle != INVALID_HANDLE)
        {
            FileWrite(allDataFileHandle, allLine);
        }
    }
    
    // Fechar o arquivo individual
    FileClose(fileHandle);
    
    Print("Dados salvos com sucesso no arquivo individual: ", fileName);
    Print("Dados também adicionados ao arquivo all.txt");
    
    return true;
}