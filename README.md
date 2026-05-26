# gptel-model-updater

<!-- [![MELPA](https://melpa.org/packages/gptel-model-updater-badge.svg)](https://melpa.org/#/gptel-model-updater) -->
[![CI](https://github.com/chuxubank/gptel-model-updater/actions/workflows/ci.yml/badge.svg)](https://github.com/chuxubank/gptel-model-updater/actions/workflows/ci.yml)

Fetch model IDs for [gptel](https://github.com/karthink/gptel) backends and write them to `gptel-backend-models`.

This is a blind convenience layer: it imports model IDs only. It does not verify cost, context length, tool support, release date, deprecation state, or provider policy. Check provider documentation before using a model.

## Install

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

Or with `straight.el`:

```elisp
(straight-use-package
  '(gptel-model-updater :host github :repo "chuxubank/gptel-model-updater"))
```

## Setup

Create gptel backends with empty model lists:

```elisp
(setq gptel--my-openai
      (gptel-make-openai "OpenAI"
        :models '()
        :host "api.openai.com"
        :key 'gptel-api-key
        :stream t))

(setq gptel-model-updater-backends
      '(gptel--my-openai))
```

Update models:

```elisp
(gptel-model-updater-update-all)
```

Select a backend/model:

```elisp
(gptel-model-updater-select-all-backend-models)
```

## Filtering

Large aggregators such as OpenRouter may return many models. Use filters to keep the model list small:

```elisp
(setq gptel-model-updater-max-models 80)
(setq gptel-model-updater-include-model-regexp
      "\\`\\(openai/\\|anthropic/\\|google/\\)")
(setq gptel-model-updater-exclude-model-regexp
      "\\(preview\\|beta\\|free\\)")
```

Per-backend filters override the global settings:

```elisp
(setq gptel-model-updater-backend-filters
      '(("OpenRouter"
         :include "\\`\\(openai/\\|anthropic/\\|google/\\)"
         :exclude "\\(preview\\|beta\\|free\\)"
         :max 80)
        ("Ollama"
         :include nil
         :exclude nil
         :max nil)))
```

Omitted keys fall back to the global values. Explicit nil disables that rule for the backend.

## Options

- `gptel-model-updater-backends`: backend variables to update.
- `gptel-model-updater-models`: preferred `BACKEND:MODEL` entries.
- `gptel-model-updater-max-models`: maximum models kept after filtering, default 200.
- `gptel-model-updater-include-model-regexp`: keep only matching model names.
- `gptel-model-updater-exclude-model-regexp`: drop matching model names.
- `gptel-model-updater-backend-filters`: per-backend include/exclude/max rules.
- `gptel-model-updater-sort-models`: sort models alphabetically; default nil keeps provider order.
- `gptel-model-updater-timeout`: curl timeout in seconds.

## Commands

- `gptel-model-updater-update-backend`
- `gptel-model-updater-update-all`
- `gptel-model-updater-select-all-backend-models`
- `gptel-model-updater-select-backend-model`
- `gptel-model-updater-select-external-targets`

## Providers

- OpenAI-compatible APIs
- Ollama
- Gemini

## License

GPLv3
