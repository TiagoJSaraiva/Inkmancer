# Inkmancer

*Read in English: [README.md](README.md)*

Você é um necromante que faz magia com carimbos. Encontre carimbos pelo mapa, grave neles a unidade que quiser e carimbe um exército de soldados de tinta. Aguente 5 minutos de ondas de inimigos até o chefe chegar.

Feito em Godot 4.7 para a FelpoJam 2026.1.

## Como jogar

- **No navegador:** https://tiagojsaraiva.github.io/Inkmancer/
- **No Windows:** baixe o `Inkmancer-windows.zip` em [Releases](https://github.com/TiagoJSaraiva/Inkmancer/releases), extraia e abra o `Inkmancer.exe`.

A versão de navegador precisa de WebGL 2 e roda melhor em Chrome, Edge ou Firefox no computador. Clique uma vez na tela do jogo para o teclado funcionar.

## Controles

| Ação | Comando |
|---|---|
| Andar | `W` `A` `S` `D` |
| Carimbada (ataque curto na direção do cursor) | Clique esquerdo |
| Invocar: o 1º clique mostra o alcance, o 2º invoca no cursor | Clique direito (2×) |
| Escolher carimbo | `1` `2` `3` `4` |
| Pausar | `P` ou `Esc` |

## Regras

1. **Encontre carimbos.** A seta na tela aponta para o mais próximo. Passe por cima para pegar.
2. **Grave o carimbo.** Escolha o tipo de unidade e distribua os pontos entre Ataque, Vida e Velocidade. A gravura não muda mais durante a partida.
   - **Guerreiro:** corpo a corpo.
   - **Arqueiro:** à distância, um alvo por vez.
   - **Canhão:** lento, com dano em área.

   A raridade define quantos pontos o carimbo tem:

   | Raridade | Pontos |
   |---|---|
   | Comum | 3 |
   | Incomum | 6 |
   | Raro | 9 |

3. **Invoque.** Cada invocação gasta tinta (a poção azul). A tinta regenera com o tempo, e cada inimigo derrotado devolve um pouco.

   | Raridade | Tinta | Recarga |
   |---|---|---|
   | Comum | 30 | 10 s |
   | Incomum | 35 | 10 s |
   | Raro | 40 | 11 s |

4. **Administre o exército.**
   - As unidades secam depois de 40, 50 ou 60 segundos, de acordo com a raridade. Elas piscam quando estão perto de sumir.
   - Você pode ter no máximo 8 unidades ao mesmo tempo.
5. **Sobreviva até 5:00.** Os inimigos ficam mais fortes a cada minuto. Quando o tempo acaba, o chefe aparece e as ondas param. Derrote o chefe para vencer.

Sua vida regenera depois de alguns segundos sem levar dano.

## Para desenvolvedores

### Rodar o projeto
1. Instale o [Godot 4.7.2](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra `game/avelino-inkmancer-3D/project.godot` no editor e aperte **F5**.

### Exportar
Os presets **Web** e **Windows Desktop** estão em `game/avelino-inkmancer-3D/export_presets.cfg`. Os builds vão para `build/` na raiz do repositório (ignorado pelo git).

```sh
cd game/avelino-inkmancer-3D
godot --headless --export-release "Web" ../../build/web/index.html
godot --headless --export-release "Windows Desktop" ../../build/windows/Inkmancer.exe
```

O preset Web é exportado sem threads. Por isso roda em hospedagem estática como o GitHub Pages, sem precisar dos cabeçalhos COOP/COEP. Os export templates do Godot 4.7.2 precisam estar instalados (*Editor → Gerenciar Modelos de Exportação*).

### Deploy automático
O workflow `.github/workflows/deploy.yml` exporta os dois builds no GitHub Actions:
- **Push no `main`:** publica a versão Web no GitHub Pages. Em *Settings → Pages → Source*, a fonte precisa estar como **GitHub Actions**.
- **Tag `v*` (ex.: `v1.0.0`):** também cria um Release com o `Inkmancer-windows.zip`.

### Onde ajustar o balanceamento

| O quê | Onde |
|---|---|
| Atributos de cada unidade | `unit/**/*.tscn` |
| Ritmo das ondas e escala dos inimigos | `spawner/spawner_manager.gd` |
| Custo, recarga, vida útil e limite de aliados | `SummonSystem.gd` |
| Tinta e ataque do jogador | `player/player.gd` |
| Tempo até o chefe | `game/game.gd` (`countdown_start_minutes`) |

## Créditos

**Equipe:** Tiago Jarruge Saraiva, Matheus Di Giacomo e Luiz Henrique Freitas.

**Modelos de terceiros** (CC BY 4.0):
- [Low poly mushrooms set](https://sketchfab.com/3d-models/low-poly-mushrooms-set-53755c7630754ac49b679e44a79c5a40), de [ClydeXYZ](https://sketchfab.com/ClydeXYZ)
- [Low poly trees](https://sketchfab.com/3d-models/low-poly-trees-51cae4a194344e8bbfbd0a4cff205f76), de [Aditya Graphical](https://sketchfab.com/Adityakm)
- [Nature environment models (Low-poly)](https://sketchfab.com/3d-models/nature-environment-models-low-poly-b687543d05384ce1a8f0429baca02f67), de [Saucy](https://sketchfab.com/saucy)

**Fonte:** Eagle Lake, de Cyreal (SIL Open Font License).

Feito com [Godot Engine](https://godotengine.org).
