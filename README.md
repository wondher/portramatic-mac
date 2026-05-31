# Portramatic

Ferramenta para criar retratos personalizados para os jogos Pathfinder da Owlcat Games
(**Pathfinder: Kingmaker** e **Pathfinder: Wrath of the Righteous**).

Cole uma URL de imagem, faça pan/zoom/crop mantendo os tamanhos corretos, e exporte
diretamente para a pasta de retratos do jogo.

![Uso](https://github.com/wabbajack-tools/portramatic/blob/main/docs/usage.gif?raw=true)

## Funcionalidades

- **Crop interativo** — arraste para mover, scroll para zoom, Alt+scroll para rotacionar
- **3 tamanhos automáticos** — Small (185×242), Medium (330×432), Full (692×1024)
- **Galeria integrada** — biblioteca com milhares de retratos pré-croppados
- **Instalação direta** — exporta direto para a pasta do jogo
- **Multi-plataforma** — Windows, macOS e Linux

## Pré-requisitos

- [.NET 10.0 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) ou superior

Verifique a instalação:

```bash
dotnet --version
# Deve mostrar 10.0.x ou superior
```

## Como Rodar

```bash
# Clone o repositório
git clone https://github.com/wondher/portramatic-mac.git
cd portramatic-mac

# Restaure as dependências
dotnet restore

# Rode o app
dotnet run --project Portramatic
```

O app abre uma janela com duas abas:
1. **Browse** — galeria de retratos com busca por tags
2. **Crop** — cole uma URL de imagem, ajuste o crop, e exporte

## Como Atualizar Dependências

```bash
# Verificar pacotes desatualizados
dotnet list package --outdated

# Atualizar um pacote específico
dotnet add Portramatic/Portramatic.csproj package Avalonia

# Atualizar todos os pacotes para a versão mais recente
dotnet add Portramatic/Portramatic.csproj package Avalonia --prerelease
```

Para atualizar o .NET SDK, baixe a versão mais recente em
[dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet/10.0).

## Como Criar uma Build

### Windows (x64)

```bash
dotnet publish Portramatic -r win-x64 -c Release \
  -p:PublishReadyToRun=true \
  --self-contained \
  -p:PublishSingleFile=true \
  -p:DebugType=embedded \
  -p:IncludeAllContentForSelfExtract=true
```

O executável fica em `publish/Portramatic.exe`.

### macOS — Apple Silicon (M1/M2/M3/M4)

```bash
# 1. Publique o binário
dotnet publish Portramatic -r osx-arm64 -c Release \
  -p:PublishReadyToRun=true \
  --self-contained \
  -p:PublishSingleFile=true \
  -p:DebugType=embedded \
  -p:IncludeAllContentForSelfExtract=true \
  -o ./publish-arm64

# 2. Gere o .app (duplo-clique para abrir, como qualquer app Mac)
./build-macos-app.sh ./publish-arm64 arm64
```

O app fica em `dist/Portramatic.app`. Copie para `/Applications` para instalar.

### macOS — Intel (x64)

```bash
# 1. Publique o binário
dotnet publish Portramatic -r osx-x64 -c Release \
  -p:PublishReadyToRun=true \
  --self-contained \
  -p:PublishSingleFile=true \
  -p:DebugType=embedded \
  -p:IncludeAllContentForSelfExtract=true \
  -o ./publish-x64

# 2. Gere o .app
./build-macos-app.sh ./publish-x64 x64
```

O app fica em `dist/Portramatic.app`.

### Gerar DMG (instalador macOS)

Adicione `--dmg` ao comando para gerar um arquivo DMG com symlink para `/Applications`:

```bash
./build-macos-app.sh ./publish-arm64 arm64 --dmg
```

O DMG fica em `dist/Portramatic-<versão>-macos-arm64.dmg`.

### Linux (x64)

```bash
dotnet publish Portramatic -r linux-x64 -c Release \
  -p:PublishReadyToRun=true \
  --self-contained \
  -p:PublishSingleFile=true \
  -p:DebugType=embedded \
  -p:IncludeAllContentForSelfExtract=true
```

O executável fica em `publish/Portramatic`. Marque como executável:
```bash
chmod +x publish/Portramatic
```

## Como Instalar Retratos no Jogo

### Opção 1: Instalação Automática

No app, faça o crop da imagem e clique em **"Install To Game Folder(s)"**.
O app detecta automaticamente a pasta do jogo.

### Opção 2: Instalação Manual

Exporte o retrato e copie a pasta gerada (nomeada com o hash MD5) para o diretório
de Portraits do jogo:

**Windows — Wrath of the Righteous:**
```
C:\Users\<seu-usuario>\AppData\LocalLow\Owlcat Games\Pathfinder Wrath Of The Righteous\Portraits\
```

**Windows — Kingmaker:**
```
C:\Users\<seu-usuario>\AppData\LocalLow\Owlcat Games\Pathfinder Kingmaker\Portraits\
```

**macOS — Wrath of the Righteous:**
```
~/Library/Application Support/Owlcat Games/Pathfinder Wrath Of The Righteous/Portraits/
```

**macOS — Kingmaker:**
```
~/Library/Application Support/Owlcat Games/Pathfinder Kingmaker/Portraits/
```

Cada retrato é uma pasta contendo:
```
<hash-md5>/
├── definition.json
├── Small.png
├── Medium.png
└── Fulllength.png
```

Após copiar, o retrato aparece no seletor de retratos do jogo.

## Estrutura do Projeto

```
Portramatic/
├── Portramatic/              # App principal (Avalonia UI + ReactiveUI)
│   ├── Views/                # Janelas e controles
│   ├── ViewModels/           # Lógica MVVM
│   ├── Controls/             # Controles customizados (CropControl)
│   ├── DTOs/                 # Data Transfer Objects
│   ├── Extensions/           # Métodos de extensão
│   └── Resources/            # Galeria embarcada (gallery.zip)
├── ThumbnailGenerator/       # Gerador de thumbnails para a galeria
├── portramatic-worker/       # Cloudflare Worker para validação de imagens
├── Definitions/              # Definições de retratos (organizadas por MD5)
└── docs/                     # GIFs de demo
```

## Tecnologias

| Tecnologia | Versão | Uso |
|------------|--------|-----|
| .NET | 10.0 LTS | Runtime |
| Avalonia UI | 12.0 | Framework UI multi-plataforma |
| ReactiveUI | 23.x | Framework MVVM |
| SkiaSharp | (via Avalonia) | Processamento de imagens |

## Licença

Este projeto é derivado do [Portramatic](https://github.com/wabbajack-tools/portramatic)
original da equipe Wabbajack.
