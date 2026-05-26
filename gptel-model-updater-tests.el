;;; gptel-model-updater-tests.el --- Tests for gptel-model-updater -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Misaka

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Unit tests for pure model parsing and filtering helpers.

;;; Code:

(require 'ert)
(require 'gptel-model-updater)

(ert-deftest gptel-model-updater-parse-models-keeps-provider-order ()
  "Model parsing preserves provider order and removes duplicates."
  (let ((gptel-model-updater-sort-models nil))
    (should
     (equal (gptel-model-updater--parse-models
             '(((id . "b")) ((id . "a")) ((id . "b")))
             'openai)
            '(b a)))))

(ert-deftest gptel-model-updater-parse-models-sorts-when-enabled ()
  "Model parsing sorts alphabetically when requested."
  (let ((gptel-model-updater-sort-models t))
    (should
     (equal (gptel-model-updater--parse-models
             '(((id . "b")) ((id . "a")))
             'openai)
            '(a b)))))

(ert-deftest gptel-model-updater-prepare-models-applies-global-ingress ()
  "Global ingress filters include, exclude, prefer, and limit models."
  (let ((gptel-model-updater-include-model-regexp "openai/\\|google/")
        (gptel-model-updater-exclude-model-regexp "4o-mini")
        (gptel-model-updater-max-models 2)
        (gptel-model-updater-backend-filters nil))
    (should
     (equal (gptel-model-updater--prepare-models
             '(openai/gpt-4o anthropic/claude google/gemini openai/gpt-4o-mini)
             '("OpenRouter:google/gemini")
             "OpenRouter")
            '(google/gemini openai/gpt-4o)))))

(ert-deftest gptel-model-updater-prepare-models-applies-backend-overrides ()
  "Backend-specific filters override global ingress filters."
  (let ((gptel-model-updater-include-model-regexp "local/")
        (gptel-model-updater-exclude-model-regexp nil)
        (gptel-model-updater-max-models 1)
        (gptel-model-updater-backend-filters
         '(("Ollama" :include nil :exclude nil :max nil))))
    (should
     (equal (gptel-model-updater--prepare-models
             '(openai/gpt-4o local/llama google/gemini)
             nil
             "Ollama")
            '(openai/gpt-4o local/llama google/gemini)))))

(provide 'gptel-model-updater-tests)
;;; gptel-model-updater-tests.el ends here
