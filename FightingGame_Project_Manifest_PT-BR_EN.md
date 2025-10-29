# Fighting Game — Project Manifest / Manifesto do Projeto (PT-BR & EN)

**Version:** 1.0 • **Generated:** 2025-10-29 20:29:49

This file is a *portable* brief you can paste into **any chat** so the assistant instantly understands the project structure, responsibilities, and extension rules.  
Este arquivo é um resumo *portátil* para colar em **qualquer chat**, fazendo o assistente entender a estrutura, responsabilidades e regras de extensão.

---

## TL;DR (EN)
- **Engine:** Godot 4.5
- **Architecture:** n-layer — **Core**, **Controllers**, **Services**, **Presentation**, **Content**
- **Pillars:** beat 'em up, **rhythm mechanics** (BPM-driven), **local multiplayer (up to 4)**, **Dialogic 2.0**, **i18n**
- **Contract-first:** use **EventBus** signals, **Repos** for data access, and **Services** as facades to engine
- **No gameplay rules inside Presentation**; keep rules in Controllers/Services
- **Unique characters per player** in multiplayer; character combos per-character via Content + Repos

## TL;DR (PT-BR)
- **Engine:** Godot 4.5
- **Arquitetura:** n-layer — **Core**, **Controllers**, **Services**, **Presentation**, **Content**
- **Pilares:** beat ’em up, **mecânica de ritmo** (BPM), **multiplayer local (até 4)**, **Dialogic 2.0**, **i18n**
- **Contrato primeiro:** use **EventBus** (sinais), **Repos** para dados e **Services** como fachadas para a engine
- **Nada de regras na Presentation**; regras ficam em Controllers/Services
- **Personagens únicos por jogador** no multiplayer; combos por personagem via Content + Repos

---

## Directory Tree / Árvore de Pastas
```text
📁 Fighting Game/
  📁 fighting-game/
    .editorconfig /.gitattributes /.gitignore
    📁 App/
      project_input_map.gd (+ .uid)
    📁 Assets/
      📁 Aseprite/
        📁 Kelara/ (source .aseprite + .import)
    📁 Characters/
      📁 Kelara/ (exported sprites + .import)
    📁 Content/
      📁 Atlases/{SFX/hit_spark.tres, UI/hud_atlas.tres}
      📁 Balances/{combat_balance.tres, movement_balance.tres}
      📁 Dialogic/{Definitions, Themes, Timelines}
      📁 Localization/{JSON/strings.json, Locales/{EN,ES,PT}/*.po/*.csv}
      📁 Stages/Stage1/{enemy_spawn_table.tres, loot_table.tres, stage1_config.tres}
    📁 Controllers/
      camera_controller.gd, combat_controller.gd, enemy_controller.gd,
      player_controller.gd, ui_controller.gd, pause_controller.gd,
      rhythm_controller.gd, tempo_sync_controller.gd, stage_controller.gd,
      character_select_controller.gd, party_controller.gd, combo_controller.gd,
      player_spawner.gd
    📁 Core/
      📁 Bootstrap/{composition_root.gd}
      📁 Configs/{audio_buses.tres, audio_rhythm_config.tres, game_config.tres, physics_config.tres}
      📁 Errors/{domain_error.gd}
      📁 EventBus/{event_bus.gd, rhythm_events.gd, player_events.gd, team_events.gd}
      📁 I18n/{i18n_keys.gd, language_codes.gd, plural_rules.gd, text_formatter.gd}
      📁 Inputs/{actions.json, devices.json, input_reader.gd, player_profiles/}
      📁 Types/{value_objects.gd, tempo_types.gd, input_buffer.gd, combo_types.gd, player_id.gd}
      📁 Utils/{time.gd, math.gd, state.gd, dsp_window.gd}
    icon.svg (+ .import), LICENSE, project.godot
    📁 Presentation/
      📁 Scenes/{Camera/game_camera.tscn, Player/player_view.tscn, Enemies/enemy_view.tscn, Stages/stage_view.tscn, VFX/{dust_poof.tscn, hit_spark.tscn}}
      📁 Themes/{ui_theme.tscn}
      📁 UI/{HUD/{hud.tscn, health_bar.tscn, combo_counter.tscn, beat_hud.tscn, latency_calibrator_ui.tscn},
             I18n/{localized_label.tscn, localized_rich_text.tscn},
             Menus/{main_menu.tscn, pause_menu.tscn, settings_menu.tscn}}
    📁 Services/
      📁 AI/{ai_service.gd, navigation_service.gd, perception_service.gd, rhythm_ai_adapter.gd, behaviors/*.tres}
      📁 Audio/{audio_service.gd, Banks/{bgm_bank.gd, sfx_bank.gd}, beat_clock.gd, bpm_analyzer.gd, onset_detector.gd, tempo_map.gd, latency_calibrator.gd}
      📁 Combat/{combo_service.gd, hitstop_service.gd}
      📁 Data/{config_service.gd, save_service.gd, DTO/save_game_dto.gd,
               Repositories/{characters_repo.gd, combos_repo.gd, dialogic_repo.gd, i18n_repo.gd, music_repo.gd, rhythm_analysis_repo.gd, settings_repo.gd, stage_repo.gd}}
      📁 I18n/{dialog_provider.gd, i18n_service.gd, locale_repo.gd, fallback_fonts.tres}
      📁 Input/{input_router.gd}
      📁 Physics/{physics_service.gd, kinematic_adapter.gd, area_adapter.gd, collision_filters.gd, grounding_3d.gd}
      📁 Rendering/{render_service.gd, animation_service.gd, camera_rig.tscn}
    📁 SpriteFrames/{Kelara.tres}
```

---

## Autoload Contracts / Contratos de Autoload
**Register:** EventBus, InputReader, App (CompositionRoot), AudioService, RenderService, AnimationService, PhysicsService, SaveService, I18nService, DialogProvider, AIService, BeatClock, RhythmController, TempoSync, PartyController, CharacterSelectController, PlayerSpawner, ComboController, InputRouter.

**Rule (EN):** Presenters never own gameplay rules. Controllers orchestrate; Services access engine/data; Content stores data; Core is dependency-free and defines base contracts.  
**Regra (PT-BR):** Presentation não contém regras. Controllers orquestram; Services acessam engine/dados; Content guarda dados; Core não depende de ninguém e define contratos base.

---

## Event Bus — Key Signals / Sinais principais
- **Rhythm:** `OnBeat(beat_index, phase)`, `OnBar(bar_index)`, `OnTempoChange(bpm)`, `OnSwingChanged(amount)`
- **Player/Party:** `PlayerJoined(slot, device)`, `PlayerLeft(slot)`, `CharacterSelected(slot, character_id)`, `PartyReady(roster)`
- **Combat:** `AttackStarted(slot, move_id)`, `AttackLanded(attacker, defender, hit_info)`, `PlayerDamaged(slot, amount)`, `EnemyDamaged(enemy_id, amount)`
- **Stage/UI:** `StageLoaded(id)`, `StageCleared(id)`, `LocaleChanged(locale)`

> Always publish/subscribe via EventBus; avoid NodePath coupling.  
> Sempre publique/assine via EventBus; evite acoplamento por NodePath.

---

## Data Access Pattern / Padrão de Acesso a Dados
Use **Repositories** under `Services/Data/Repositories/` for any persistent or content-backed data:
- `characters_repo` (list, metadata, portraits)
- `combos_repo` (per-character combo definitions)
- `stage_repo` (spawn tables, loot, phase goals)
- `i18n_repo` / `dialogic_repo` (strings, timelines)
- `music_repo` / `rhythm_analysis_repo` (tracks, cached BPM/tempo maps)
- `settings_repo` / `player_progress_repo` (options, save slots)

Controllers **never** parse files directly. Services use Repos; Core holds contracts/utilities.

---

## Rhythm Mechanics — Integration Points / Integração
- **BeatClock** emits time grid → consumed by **TempoSyncController**
- **TempoSync** modulates: `AnimationService.speed_multiplier`, `RenderService.parallax/vfx multipliers`, combo windows (via `ComboService`)
- **LatencyCalibrator** writes user offset to `settings_repo`; BeatClock compensates
- **Design rule:** do **not** scale global physics delta — use per-system multipliers

---

## Multiplayer Local (up to 4) — Rules / Regras
- **InputRouter** maps DeviceId → PlayerSlotId (P1..P4); each maintains its own `InputBuffer`
- **CharacterSelectController** + **PartyController** enforce `unique_chars = true`
- **PlayerSpawner** instantiates the chosen character’s **View** and binds slot-specific controllers/services
- Shared **BeatClock** for all players ensures synchronized rhythm feedback

---

## Extension Guidelines / Diretrizes de Extensão
**When adding a feature / Ao adicionar uma feature:**
1) Define **signals** (EventBus) and **value types** (Core/Types) first.  
2) Create/extend **Services** (engine/data access).  
3) Orchestrate with a **Controller** (no UI code inside).  
4) Build **Presentation** (scenes/UI) that only listen and render.  
5) Put tunables in **Content/** (`Balances/*.tres`, `Characters/*`, `Stages/*`).

**Forbidden / Proibido:** gameplay logic inside `Presentation/` or direct file I/O in Controllers.

---

## Change Request Template / Template para Solicitação de Mudança
**EN**
- Goal: <what to add/change>
- Layer(s): Core / Controllers / Services / Presentation / Content
- New signals (EventBus): <list>
- Data sources (Repos/Content): <list>
- Side effects: audio, rendering, physics, save
- Tests: unit (service), integration (controller), content sanity

**PT-BR**
- Objetivo: <o que adicionar/alterar>
- Camadas: Core / Controllers / Services / Presentation / Content
- Novos sinais (EventBus): <lista>
- Fontes de dados (Repos/Content): <lista>
- Efeitos colaterais: áudio, render, física, save
- Testes: unitário (service), integração (controller), consistência de conteúdo

---

## Glossary / Glossário
- **Controller:** orchestrates use cases; subscribes to EventBus; calls Services
- **Service:** engine/data facade; no UI; may emit events
- **Repo:** data access (Content, disk, settings)
- **Presentation:** views/UI/VFX; no rules
- **Core:** contracts, types, utils, configs, EventBus
- **BeatClock/TempoSync:** rhythm grid & multipliers
- **InputRouter:** device→slot routing; per-slot input buffers
- **Party:** players P1..P4 roster with unique characters

---

## Milestone Order / Ordem de Marcos
1) Core + Input + Player movement + basic Combat  
2) Stage + Enemy + HUD + Camera  
3) Rhythm (BeatClock/BPMAnalyzer/TempoSync) + Calibrator  
4) Multiplayer (InputRouter, CharacterSelect, Party, Spawner)  
5) Per-character Combos + Balance + Polish

---

## Assistant Checklist / Checklist para Assistente
- [ ] Respect n-layer rules (no rules in Presentation) / Respeitar n-layer
- [ ] Use EventBus signals for communication / Usar EventBus
- [ ] Propose new files with clear layer placement / Propor arquivos com camada clara
- [ ] Prefer Resources (`.tres`) for tunables / Preferir `.tres` para parâmetros
- [ ] Keep characters unique per slot in multiplayer / Personagens únicos por slot
- [ ] Sync to BeatClock; don’t change global physics delta / Sincronizar ao BeatClock; não mudar delta global

---

> Paste this manifest first in any new chat to enable safe, consistent extensions.  
> Cole este manifesto primeiro em qualquer chat para habilitar extensões seguras e consistentes.
