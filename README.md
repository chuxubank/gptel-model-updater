# gptel-model-updater

Fetch and update model lists for [GPTel](https://github.com/karthink/gptel) backends from various LLM providers.

## Features

- Fetches available models from OpenAI-compatible APIs, Ollama, and Gemini
- Updates `gptel-backend-models` on the backend struct
- Auto-selects a preferred (backend . model) pair after update
- Supports multiple external targets (e.g., separate model for `gptel-magit`)

## Usage

```elisp
(use-package gptel-model-updater
  :ensure t
  :after gptel
  :custom
  (gptel-model-updater-backends
   '(gptel--openai gptel--ollama gptel--gemini))
  (gptel-model-updater-models
   '("OpenAI:gpt-4o" "Ollama:llama3"))
  :config
  ;; Update all backends on startup
  (gptel-model-updater-update-all))
```

## Commands

| Command | Description |
|---------|-------------|
| `gptel-model-updater-update-backend` | Update models for one backend |
| `gptel-model-updater-update-all` | Update all configured backends |
| `gptel-model-updater-select-backend-models` | Select backend/model interactively |
