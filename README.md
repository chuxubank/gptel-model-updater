# gptel-model-updater

[![MELPA](https://melpa.org/packages/gptel-model-updater-badge.svg)](https://melpa.org/#/gptel-model-updater)
[![CI](https://github.com/chuxubank/gptel-model-updater/actions/workflows/ci.yml/badge.svg)](https://github.com/chuxubank/gptel-model-updater/actions/workflows/ci.yml)

Fetch and update model IDs for [GPTel](https://github.com/karthink/gptel) backends from various LLM providers. Models are discovered at runtime, so you never need to hardcode model lists.

This package is intentionally a basic convenience layer. It blindly imports model IDs exposed by provider endpoints and does not verify model cost, tool support, context length, release date, deprecation state, safety policy, or other provider-specific properties. Users are responsible for checking those details before selecting a model.

## Features

- Fetches available models from OpenAI-compatible APIs, Ollama, and Gemini
- Updates `gptel-backend-models` on each backend struct automatically
- Limits model ingress globally or per backend with include/exclude regexps and a maximum model count
- Respects `gptel-use-curl`: uses async curl when enabled, otherwise Emacs `url-retrieve`
- Keeps the provider's model order by default, with optional alphabetical sorting
- Auto-selects a preferred (backend . model) pair after update
- Supports multiple **external targets** — set separate backend/model pairs for different consumers (e.g., `gptel-magit` gets a cheap model, chat gets the flagship model)

## Installation

### with `use-package` + `vc-use-package`

```elisp
(use-package gptel-model-updater
  :vc (:url "https://github.com/chuxubank/gptel-model-updater")
  :after gptel
  :custom
  (gptel-model-updater-backends
   '(gptel--my-openai gptel--my-ollama))
  (gptel-model-updater-models
   '("OpenAI:gpt-4o" "Ollama:llama3")))
```

Emacs 30+ has `vc-use-package` built-in; on earlier versions install it from [GitHub](https://github.com/slotThe/vc-use-package).

### with `straight.el`

```elisp
(straight-use-package
  '(gptel-model-updater :host github :repo "chuxubank/gptel-model-updater"))
```

## Usage

### 1. Define backends with empty model lists

```elisp
(setq gptel--my-openai
      (gptel-make-openai "MyAI"
        :models '()              ; ← empty, will be populated at runtime
        :host "api.example.com"
        :key 'gptel-api-key
        :stream t))
```

### 2. Configure which backends to manage

```elisp
(setq gptel-model-updater-backends
      '(gptel--my-openai gptel--my-ollama gptel--my-gemini))
```

### 3. Update models and select a backend/model pair

```elisp
;; Update all backends asynchronously
(gptel-model-updater-update-all)

;; Select a model interactively
(gptel-model-updater-select-backend-models)
```

### 4. Automate on startup

```elisp
(gptel-model-updater-update-all)
;; After each backend finishes, the hook auto-selects a model
```

### 5. Limit large provider model lists

Some providers may expose a very large number of models from the same endpoint. Configure ingress controls to keep completion lists and backend state small:

```elisp
;; Global defaults for every refreshed backend.
(setq gptel-model-updater-include-model-regexp
      "\\`\\(openai/\\|anthropic/\\|google/\\)")
(setq gptel-model-updater-exclude-model-regexp
      "\\(preview\\|beta\\|free\\)")
(setq gptel-model-updater-max-models 80)
```

Set `gptel-model-updater-max-models` to nil if you explicitly want to keep every fetched model that passes the regexp filters.

You can override these controls for individual backends by matching the backend display name:

```elisp
(setq gptel-model-updater-backend-filters
      '(("OpenRouter"
         :include "\\`\\(openai/\\|anthropic/\\|google/\\)"
         :exclude "\\(preview\\|beta\\|free\\)"
         :max 80)
        ("Ollama"
         :include nil
         :exclude nil
         :max nil)
        ("Gemini"
         :include "\\`gemini-"
         :max 50)))
```

Omitted keys fall back to the global values. Use explicit nil values when a backend should disable a global include, exclude, or max rule.

## Customization

### `gptel-model-updater-backends`

List of backend symbol names to manage. Each must be a bound variable holding a gptel backend struct.

### `gptel-model-updater-models`

Preferred models in `BACKEND:MODEL` format, tried in order at selection time. The first available match wins.

```elisp
(setq gptel-model-updater-models
      '("OpenAI:gpt-4o" "Gemini:gemini-2.5-pro"))
```

Preferred models still need to pass the ingress filters below. After filtering, preferred models are moved to the front before `gptel-model-updater-max-models` is applied.

### `gptel-model-updater-include-model-regexp`

Only keep fetched model names matching this regexp. The default is nil, which allows all fetched models before other filters are applied.

### `gptel-model-updater-exclude-model-regexp`

Drop fetched model names matching this regexp. The default is nil, which excludes nothing.

### `gptel-model-updater-max-models`

Maximum number of models written to each refreshed backend after regexp filtering and preferred-model ordering. The default is 200. Set it to nil to disable the limit.

### `gptel-model-updater-backend-filters`

Per-backend ingress controls. Each entry has this shape:

```elisp
(BACKEND-NAME :include INCLUDE-REGEXP :exclude EXCLUDE-REGEXP :max MAX-MODELS)
```

`BACKEND-NAME` is compared with `gptel-backend-name`. Any omitted key falls back to the corresponding global setting. Explicit nil values disable that setting for the backend.

### `gptel-model-updater-external-targets`

Set separate backend/model pairs for consumers other than the global `gptel-backend`. Each entry is:

```elisp
(BACKEND-VARIABLE MODEL-VARIABLE DISPLAY-NAME [MODEL-LIST])
```

Example — use a cheap model for `gptel-magit` commit messages:

```elisp
(setq gptel-model-updater-external-targets
      '((gptel-magit-backend gptel-magit-model "GPTel-Magit"
                             ("OpenRouter:openai/gpt-4o-mini"))))
```

Call `(gptel-model-updater-select-backend-models t)` to set external targets, or use `C-u M-x gptel-model-updater-select-backend-models` for interactive selection.

### `gptel-model-updater-after-update-hook`

Hook run after each successful model fetch. Functions receive `(backend-name backend models)`. Defaults to `gptel-model-updater-select-backend-models`, which picks the first available model from `gptel-model-updater-models`.

### `gptel-model-updater-timeout`

Request timeout in seconds for curl requests (default: 30).

### `gptel-model-updater-sort-models`

When non-nil, sort fetched models alphabetically. The default is nil, which preserves the provider's response order. Preferred entries from `gptel-model-updater-models` are still moved to the front when present.

## Scope and limitations

Automatic model updating is blind. The package only imports model IDs from provider endpoints and writes them into `gptel-backend-models`. It does not fetch or interpret model metadata, and it cannot tell whether a model is appropriate for chat, tool use, image input, long context, price-sensitive use, or production workflows.

Provider endpoints may also include deprecated, preview, restricted, expensive, or otherwise unsuitable models. Use the ingress controls above, and verify provider documentation before relying on a model.

## Commands

| Command | Description |
|---------|-------------|
| `gptel-model-updater-update-backend` | Update models for one backend (interactive) |
| `gptel-model-updater-update-all` | Update all configured backends |
| `gptel-model-updater-select-backend-models` | Select backend/model with completion; with `C-u` prefix, set external targets instead |

## Supported Providers

| Provider | Auto-detection |
|----------|---------------|
| OpenAI-compatible (`gptel-make-openai`) | Default fallback |
| Ollama (`gptel-make-ollama`) | Detected via `gptel-ollama` class |
| Gemini (`gptel-make-gemini`) | Detected via `gptel-gemini` class |

## License

GPLv3
