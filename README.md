# gptel-model-updater

Fetch and update model lists for [GPTel](https://github.com/karthink/gptel) backends from various LLM providers. Models are discovered at runtime via async `curl` requests, so you never need to hardcode model lists.

## Features

- Fetches available models from OpenAI-compatible APIs, Ollama, and Gemini
- Updates `gptel-backend-models` on each backend struct automatically
- Auto-selects a preferred (backend . model) pair after update
- Supports multiple **external targets** — set separate backend/model pairs for different consumers (e.g., `gptel-magit` gets a cheap model, chat gets the flagship model)
- Async curl — no blocking, no Emacs URL library dependency

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
;; Update all backends (async curl)
(gptel-model-updater-update-all)

;; Select a model interactively
(gptel-model-updater-select-backend-models)
```

### 4. Automate on startup

```elisp
(gptel-model-updater-update-all)
;; After each backend finishes, the hook auto-selects a model
```

## Customization

### `gptel-model-updater-backends`

List of backend symbol names to manage. Each must be a bound variable holding a gptel backend struct.

### `gptel-model-updater-models`

Preferred models in `BACKEND:MODEL` format, tried in order at selection time. The first available match wins.

```elisp
(setq gptel-model-updater-models
      '("OpenAI:gpt-4o" "Gemini:gemini-2.5-pro"))
```

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

Curl timeout in seconds (default: 30).

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
