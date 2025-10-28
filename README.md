# Layered Architecture Guide (Godot 4.5) — Beat 'em up / Guia de Arquitetura em Camadas

**Language / Idioma:** [Português (pt-BR)](#português-pt-br) | [English](#english)

---

## Português (pt-BR)

### Visão geral
Este guia descreve uma arquitetura em camadas (n-layer) para um projeto Godot 4.5 de beat 'em up, usando as camadas principais **core**, **controllers**, **services**, **presentation** e **content**. O objetivo é baixo acoplamento, testabilidade e facilidade de localização (Dialogic 2.0).

### Árvore do projeto (somente estrutura)
```text
res://
  app/
    main.tscn                          # cena raiz (vazia)
    project_input_map.cfg              # opcional (mapeamento de ações)

  core/                                 # utilitários, tipos, eventos, bootstrap
    bootstrap/
      CompositionRoot.gd                # ponto de ligação entre camadas (vazio)
    event_bus/
      EventBus.gd                       # sinais/eventos globais (vazio)
    errors/
      DomainError.gd                    # tipos/constantes de erro (vazio)
    types/
      ValueObjects.gd                   # ex.: Health, Score, Damage (vazio)
    utils/
      Time.gd
      Math.gd
      State.gd
    input/
      InputReader.gd                    # traduz hardware -> comandos semânticos
      Actions.json                      # nomes de ações (Jump/Punch/etc)
    i18n/
      I18nKeys.gd                       # enum/consts de chaves de texto
      LanguageCodes.gd                  # códigos ISO/aliases
      PluralRules.gd                    # contratos de pluralização
      TextFormatter.gd                  # placeholders/format
    configs/
      GameConfig.tres                   # config geral (resource vazio)
      PhysicsConfig.tres                # gravidade, velocidades (resource)
      AudioBuses.tres                   # buses de áudio (resource)

  controllers/                          # orquestra casos de uso
    PlayerController.gd
    CombatController.gd
    StageController.gd
    PauseController.gd
    UIController.gd
    LocalizationController.gd           # troca de idioma, notifica UI
    EnemyController.gd
    CameraController.gd

  services/                             # fachadas/infra p/ engine e dados
    physics/
      PhysicsService.gd                 # alto nível (mover/overlap/ray)
      KinematicAdapter.gd               # move_and_slide etc.
      AreaAdapter.gd                    # áreas/hit/hurtboxes
      CollisionFilters.gd               # layers/masks
    audio/
      AudioService.gd                   # SFX/BGM/volumes
      banks/
        sfx_bank.tres                   # lista de sfx (resource)
        bgm_bank.tres                   # lista de bgm (resource)
    rendering/
      RenderService.gd                  # câmera, pós, shake
      AnimationService.gd               # troca de estados de anima
      CameraRig.tscn                    # rig/câmera (cena vazia)
    data/
      SaveService.gd                    # salvar/carregar jogo
      ConfigService.gd                  # opções (volume/idioma/dif.)
      repositories/
        PlayerProgressRepo.gd
        SettingsRepo.gd
        StageRepo.gd
        I18nRepo.gd                     # acesso a PO/CSV/JSON de strings
        DialogicRepo.gd                 # acesso a timelines/defs
      dto/
        SaveGameDTO.gd
    ai/
      AIService.gd                      # agenda/tick de decisão
      behaviors/
        Patrol.btres
        Chase.btres
        CombatSelector.btres
    i18n/
      I18nService.gd                    # set/get locale, load strings
      LocaleRepo.gd                     # persistência do idioma atual
      DialogProvider.gd                 # integração: Dialogic ↔ i18n
      FallbackFonts.tres                # cadeia de fontes fallback

  presentation/                         # views, UI, VFX (sem regras)
    scenes/
      stage/
        StageView.tscn
      player/
        PlayerView.tscn
      enemies/
        EnemyView.tscn                  # base genérica p/ inimigos
      vfx/
        HitSpark.tscn
        DustPoof.tscn
      camera/
        GameCamera.tscn
    ui/
      hud/
        HUD.tscn
        HealthBar.tscn
        ComboCounter.tscn
        ScoreDisplay.tscn
      menus/
        MainMenu.tscn
        PauseMenu.tscn
        SettingsMenu.tscn
      i18n/
        LocalizedLabel.tscn             # nó que lê chave e mostra texto
        LocalizedRichText.tscn
    themes/
      ui_theme.tres                     # tema UI (resource)
    fonts/
      latin_dynamic.tres
      cjk_fallback.tres
      rtl_fallback.tres

  content/                              # NOVA CAMADA: dados/recursos localizáveis
    localization/                       # textos e tabelas de tradução
      locales/
        en/
          strings.en.po                 # PO de UI/geral
          dialogic.en.csv               # falas/dialogic por ID
        pt/
          strings.pt.po
          dialogic.pt.csv
        es/
          strings.es.po
          dialogic.es.csv
      csv/
        strings.csv                     # tabela mestra (ID;en;pt;es) opcional
      json/
        strings.json                    # alternativa em JSON (opcional)
    dialogic/                           # conteúdo do Dialogic 2.0
      definitions/                      # personagens, variables (resources)
      timelines/                        # timelines que referenciam IDs (sem texto literal)
      themes/                           # caixas/estilos de diálogo
    stages/                              # dados de fases (sem lógica)
      stage1/
        Stage1Config.tres               # waves/objetivos/parametrização
        EnemySpawnTable.tres
        LootTable.tres
      stage2/
        Stage2Config.tres
    balances/                            # números de gameplay p/ tuning
      combat_balance.tres               # dano, stun, juggle limit etc.
      movement_balance.tres             # speeds, jump heights etc.
    atlases/
      sfx/
        hitspark.pngimport              # placeholders de assets
      ui/
        hud_atlas.tres
    audio/
      sfx/
        hit_light.ogg
        hit_heavy.ogg
      bgm/
        stage1_theme.ogg
        menu_theme.ogg

  tests/                                 # testes (GUT/WAT) — vazios
    core/
    controllers/
    services/
    presentation/
    content/
```

### O que cada item faz — Explicação completa (pt-BR)

#### `app/`
- **`main.tscn`**: cena raiz do jogo; ponto de entrada visual que instancia Stage, HUD e câmera (geralmente via CompositionRoot).
- **`project_input_map.cfg`**: referência opcional do mapa de ações do projeto (teclado/controle).

#### `core/` (fundação)
- **`bootstrap/CompositionRoot.gd`**: une as camadas; cria services/controllers, injeta dependências, registra handlers do EventBus, carrega a cena raiz.
- **`event_bus/EventBus.gd`**: barramento de eventos (sinais) para comunicação desacoplada entre UI, controllers e services.
- **`errors/DomainError.gd`**: enum/constantes para padronizar erros/Result.
- **`types/ValueObjects.gd`**: Value Objects imutáveis (Health, Score, Damage); validam e evitam “números mágicos”.
- **`utils/Time.gd | Math.gd | State.gd`**: helpers genéricos (tempo, matemática, máquinas de estado).
- **`input/InputReader.gd | Actions.json`**: lê Actions e publica comandos semânticos (Move/Jump/Punch) via EventBus; JSON documenta nomes de ações.
- **`i18n/*`**: chaves (`I18nKeys`), códigos de idioma, regras de plural, formatação de placeholders.
- **`configs/*`**: resources de configuração global (jogo, física, buses de áudio).

#### `controllers/` (orquestração)
- **`PlayerController.gd`**: processa comandos do jogador; decide intents (mover, pular, atacar); chama physics/anim/audio; emite eventos.
- **`CombatController.gd`**: janela de acerto, confirm/cancel, prioridade e contagem de combo.
- **`StageController.gd`**: fluxo de fase (waves, vit/derrota), usa StageRepo/StageConfig e dispara spawns.
- **`PauseController.gd`**: pausa/retoma; menus de pausa; integração com áudio/tempo.
- **`UIController.gd`**: coordena HUD/menus ao receber eventos (sem regras de gameplay).
- **`LocalizationController.gd`**: muda idioma em runtime, notifica UI/Dialogic e persiste escolha via LocaleRepo.
- **`EnemyController.gd`**: aplica decisões da IA (aproximar, atacar, recuar) integrando física e animação.
- **`CameraController.gd`**: segue alvos, limites/zonas, chama screen shake via RenderService.

#### `services/` (fachadas engine/dados)

**physics/**
- **`PhysicsService.gd`**: API de alto nível (mover personagem, ray/overlap); independente de NodePath concreto.
- **`KinematicAdapter.gd`**: implementação com `CharacterBody2D.move_and_slide(...)`.
- **`AreaAdapter.gd`**: lida com `Area2D` (hit/hurtboxes, enter/exit).
- **`CollisionFilters.gd`**: nomes/layers/masks centralizados.

**audio/**
- **`AudioService.gd`**: toca SFX/BGM; volumes/buses; crossfade; pausa/retoma.
- **`banks/*.tres`**: catálogos nomeados de sons (ex.: `punch_light`, `stage1_theme`).

**rendering/**
- **`RenderService.gd`**: câmera (follow/limites), pós-processo, tremor de tela.
- **`AnimationService.gd`**: troca de estados de anima (idle/walk/attack/hit), callbacks `AnimationFinished`.
- **`CameraRig.tscn`**: cena/rig de câmera manipulada por serviço/controlador.

**data/**
- **`SaveService.gd`**: salvar/carregar usando repositórios; serializa `SaveGameDTO`.
- **`ConfigService.gd`**: lê/escreve opções (volume, idioma, dificuldade).
- **`repositories/*`**: progressos, settings, dados de fase, strings (i18n) e Dialogic.
- **`dto/SaveGameDTO.gd`**: formato do save (schema/versão/slots).

**ai/**
- **`AIService.gd`**: agenda/tick de decisão; escolhe comportamento (BT/State).
- **`behaviors/*.btres`**: árvores de comportamento (patrulha/perseguição/combate).

**i18n/**
- **`I18nService.gd`**: `set/get locale`, resolve chave→texto, sinaliza `LocaleChanged`.
- **`LocaleRepo.gd`**: persiste idioma atual (em settings).
- **`DialogProvider.gd`**: ponte I18n ↔ Dialogic (injeta textos por ID nas timelines).
- **`FallbackFonts.tres`**: cadeia de fontes para CJK/RTL.

#### `presentation/` (visual/UI, sem regras)
- **`scenes/*`**: StageView (cenário), PlayerView/EnemyView (sprites/anim/hit/hurt), VFX (HitSpark/DustPoof), GameCamera.
- **`ui/*`**: HUD (vida/score/combo), widgets (HealthBar/ComboCounter/ScoreDisplay), menus (Main/Pause/Settings), nós localizados (LocalizedLabel/RichText).
- **`themes/ui_theme.tres`**: tema de UI.
- **`fonts/*.tres`**: fontes e fallback.

#### `content/` (dados e assets localizáveis)
- **`localization/*`**: PO/CSV/JSON de strings; `dialogic.*.csv` com falas por ID (timelines referenciam IDs, não texto literal).
- **`dialogic/*`**: definitions/timelines/themes do Dialogic (timelines usam IDs).
- **`stages/*`**: configs de fase, tabelas de spawn/loot (sem lógica).
- **`balances/*`**: números de gameplay (combate/movimento) para tuning.
- **`atlases/*`**: atlas/imports de VFX/UI.
- **`audio/*`**: SFX e BGM.

#### `tests/`
- Estrutura de testes por camada (unitários/integração; GUT/WAT).


---

## English

### Overview
This guide describes a layered (n-layer) architecture for a Godot 4.5 beat ’em up project, using **core**, **controllers**, **services**, **presentation** and **content** as the main layers. The goals are low coupling, testability and localization readiness (Dialogic 2.0).

### Project tree (structure only)
```text
res://
  app/
    main.tscn                          # root scene (empty)
    project_input_map.cfg              # optional (input actions mapping)

  core/                                 # utilities, types, events, bootstrap
    bootstrap/
      CompositionRoot.gd                # wiring point across layers (empty)
    event_bus/
      EventBus.gd                       # global signals/events (empty)
    errors/
      DomainError.gd                    # error types/constants (empty)
    types/
      ValueObjects.gd                   # e.g., Health, Score, Damage (empty)
    utils/
      Time.gd
      Math.gd
      State.gd
    input/
      InputReader.gd                    # translates hardware -> semantic commands
      Actions.json                      # action names (Jump/Punch/etc)
    i18n/
      I18nKeys.gd                       # enum/consts of text keys
      LanguageCodes.gd                  # ISO codes/aliases
      PluralRules.gd                    # pluralization contracts
      TextFormatter.gd                  # placeholders/format
    configs/
      GameConfig.tres                   # general config (empty resource)
      PhysicsConfig.tres                # gravity, speeds (resource)
      AudioBuses.tres                   # audio buses (resource)

  controllers/                          # orchestrates use cases
    PlayerController.gd
    CombatController.gd
    StageController.gd
    PauseController.gd
    UIController.gd
    LocalizationController.gd           # switches language, notifies UI
    EnemyController.gd
    CameraController.gd

  services/                             # fachadas/infra p/ engine e dados
    physics/
      PhysicsService.gd                 # high level (move/overlap/ray)
      KinematicAdapter.gd               # move_and_slide etc.
      AreaAdapter.gd                    # areas/hit/hurtboxes
      CollisionFilters.gd               # layers/masks
    audio/
      AudioService.gd                   # SFX/BGM/volumes
      banks/
        sfx_bank.tres                   # sfx list (resource)
        bgm_bank.tres                   # bgm list (resource)
    rendering/
      RenderService.gd                  # camera, post, shake
      AnimationService.gd               # animation state switching
      CameraRig.tscn                    # camera rig (empty scene)
    data/
      SaveService.gd                    # save/load game
      ConfigService.gd                  # options (volume/language/difficulty)
      repositories/
        PlayerProgressRepo.gd
        SettingsRepo.gd
        StageRepo.gd
        I18nRepo.gd                     # access to strings PO/CSV/JSON
        DialogicRepo.gd                 # access to timelines/defs
      dto/
        SaveGameDTO.gd
    ai/
      AIService.gd                      # decision tick scheduler
      behaviors/
        Patrol.btres
        Chase.btres
        CombatSelector.btres
    i18n/
      I18nService.gd                    # set/get locale, load strings
      LocaleRepo.gd                     # current language persistence
      DialogProvider.gd                 # integration: Dialogic ↔ i18n
      FallbackFonts.tres                # fallback fonts chain

  presentation/                         # views, UI, VFX (no rules)
    scenes/
      stage/
        StageView.tscn
      player/
        PlayerView.tscn
      enemies/
        EnemyView.tscn                  # generic base for enemies
      vfx/
        HitSpark.tscn
        DustPoof.tscn
      camera/
        GameCamera.tscn
    ui/
      hud/
        HUD.tscn
        HealthBar.tscn
        ComboCounter.tscn
        ScoreDisplay.tscn
      menus/
        MainMenu.tscn
        PauseMenu.tscn
        SettingsMenu.tscn
      i18n/
        LocalizedLabel.tscn             # node that reads key and displays text
        LocalizedRichText.tscn
    themes/
      ui_theme.tres                     # UI theme (resource)
    fonts/
      latin_dynamic.tres
      cjk_fallback.tres
      rtl_fallback.tres

  content/                              # NEW LAYER: localizable data/resources
    localization/                       # texts and translation tables
      locales/
        en/
          strings.en.po                 # PO de UI/geral
          dialogic.en.csv               # dialogic lines by ID
        pt/
          strings.pt.po
          dialogic.pt.csv
        es/
          strings.es.po
          dialogic.es.csv
      csv/
        strings.csv                     # optional master table (ID;en;pt;es)
      json/
        strings.json                    # alternative JSON (optional)
    dialogic/                           # Dialogic 2.0 content
      definitions/                      # characters, variables (resources)
      timelines/                        # timelines referencing IDs (no literal text)
      themes/                           # dialogue boxes/styles
    stages/                              # stage data (no logic)
      stage1/
        Stage1Config.tres               # waves/objectives/parametrization
        EnemySpawnTable.tres
        LootTable.tres
      stage2/
        Stage2Config.tres
    balances/                            # gameplay numbers for tuning
      combat_balance.tres               # damage, stun, juggle limit etc.
      movement_balance.tres             # speeds, jump heights etc.
    atlases/
      sfx/
        hitspark.pngimport              # asset placeholders
      ui/
        hud_atlas.tres
    audio/
      sfx/
        hit_light.ogg
        hit_heavy.ogg
      bgm/
        stage1_theme.ogg
        menu_theme.ogg

  tests/                                 # tests (GUT/WAT) — empty
    core/
    controllers/
    services/
    presentation/
    content/
```

### What each item does — Full explanation (EN)

#### `app/`
- **`main.tscn`**: game root scene; visual entry point that instantiates Stage, HUD and Camera (typically via CompositionRoot).
- **`project_input_map.cfg`**: optional reference for the project’s input actions (keyboard/controller).

#### `core/` (foundation)
- **`bootstrap/CompositionRoot.gd`**: wires layers together; creates services/controllers, injects dependencies, registers EventBus handlers, loads the root scene.
- **`event_bus/EventBus.gd`**: event bus (signals) for decoupled communication among UI, controllers and services.
- **`errors/DomainError.gd`**: enum/constants to standardize errors/Result.
- **`types/ValueObjects.gd`**: immutable Value Objects (Health, Score, Damage); validate and avoid “magic numbers”.
- **`utils/Time.gd | Math.gd | State.gd`**: generic helpers (time, math, state machines).
- **`input/InputReader.gd | Actions.json`**: reads Actions and publishes semantic commands (Move/Jump/Punch) through EventBus; JSON documents action names.
- **`i18n/*`**: keys (`I18nKeys`), language codes, plural rules, placeholder formatting.
- **`configs/*`**: global configuration resources (game, physics, audio buses).

#### `controllers/` (orchestration)
- **`PlayerController.gd`**: processes player commands; decides intents (move, jump, attack); calls physics/anim/audio; emits events.
- **`CombatController.gd`**: hit windows, confirm/cancel, priority and combo counting.
- **`StageController.gd`**: stage flow (waves, win/lose), uses StageRepo/StageConfig and triggers spawns.
- **`PauseController.gd`**: pause/resume; pause menus; audio/time integration.
- **`UIController.gd`**: coordinates HUD/menus on game events (no gameplay rules).
- **`LocalizationController.gd`**: runtime language switch, notifies UI/Dialogic, persists choice via LocaleRepo.
- **`EnemyController.gd`**: applies AI decisions (approach, attack, retreat) integrating physics and animation.
- **`CameraController.gd`**: follows targets, bounds/zones, triggers screen shake via RenderService.

#### `services/` (engine/data facades)

**physics/**
- **`PhysicsService.gd`**: high-level API (character movement, ray/overlap); independent from concrete NodePaths.
- **`KinematicAdapter.gd`**: implementation using `CharacterBody2D.move_and_slide(...)`.
- **`AreaAdapter.gd`**: handles `Area2D` (hit/hurtboxes, enter/exit).
- **`CollisionFilters.gd`**: centralized names/layers/masks.

**audio/**
- **`AudioService.gd`**: plays SFX/BGM; volumes/buses; crossfade; pause/resume.
- **`banks/*.tres`**: named catalogs of sounds (e.g., `punch_light`, `stage1_theme`).

**rendering/**
- **`RenderService.gd`**: camera (follow/bounds), post-processing, screen shake.
- **`AnimationService.gd`**: switches animation states (idle/walk/attack/hit), `AnimationFinished` callbacks.
- **`CameraRig.tscn`**: camera rig/scene controlled by service/controller.

**data/**
- **`SaveService.gd`**: save/load using repositories; serializes `SaveGameDTO`.
- **`ConfigService.gd`**: read/write options (volume, language, difficulty).
- **`repositories/*`**: player progress, settings, stage data, strings (i18n) and Dialogic.
- **`dto/SaveGameDTO.gd`**: save schema (version/slots).

**ai/**
- **`AIService.gd`**: decision tick scheduler; selects behavior (BT/State).
- **`behaviors/*.btres`**: behavior trees (patrol/chase/combat selector).

**i18n/**
- **`I18nService.gd`**: `set/get locale`, resolves key→string, emits `LocaleChanged`.
- **`LocaleRepo.gd`**: persists current language (in settings).
- **`DialogProvider.gd`**: bridge I18n ↔ Dialogic (injects texts by ID into timelines).
- **`FallbackFonts.tres`**: fallback font chain for CJK/RTL.

#### `presentation/` (visual/UI, no rules)
- **`scenes/*`**: StageView (environment), PlayerView/EnemyView (sprites/anim/hit/hurt), VFX (HitSpark/DustPoof), GameCamera.
- **`ui/*`**: HUD (health/score/combo), widgets (HealthBar/ComboCounter/ScoreDisplay), menus (Main/Pause/Settings), localized nodes (LocalizedLabel/RichText).
- **`themes/ui_theme.tres`**: UI theme.
- **`fonts/*.tres`**: fonts and fallbacks.

#### `content/` (localizable data & assets)
- **`localization/*`**: PO/CSV/JSON strings; `dialogic.*.csv` with lines by ID (timelines reference IDs, not literal text).
- **`dialogic/*`**: Dialogic definitions/timelines/themes (timelines use IDs).
- **`stages/*`**: stage configs, spawn/loot tables (no logic).
- **`balances/*`**: gameplay numbers (combat/movement) for tuning.
- **`atlases/*`**: atlas/imports for VFX/UI.
- **`audio/*`**: SFX and BGM.

#### `tests/`
- Test structure per layer (unit/integration; GUT/WAT).

