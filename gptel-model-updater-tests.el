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

(ert-deftest gptel-model-updater-metadata-openai-plist ()
  "models.dev metadata maps to gptel model properties."
  (let* ((backend (gptel-make-openai "metadata-openai-test"
                    :host "api.openai.com"
                    :models '()))
         (metadata
          '((openai
             (models
              (gpt-4o
               (id . "gpt-4o")
               (name . "GPT-4o")
               (attachment . t)
               (reasoning . :json-false)
               (tool_call . t)
               (structured_output . t)
               (knowledge . "2023-10")
               (modalities . ((input . ["text" "image"])
                              (output . ["text"])))
               (limit . ((context . 128000)))
               (cost . ((input . 2.5)
                        (output . 10))))))))
         (gptel-model-updater-metadata--cache metadata)
         (gptel-model-updater-metadata--cache-url gptel-model-updater-model-metadata-url))
    (gptel-model-updater-metadata-apply '(gpt-4o) backend 'openai)
    (should (equal (symbol-plist 'gpt-4o)
                   '(:description "GPT-4o"
                     :capabilities (media tool-use json url responses-api)
                     :mime-types ("image/jpeg" "image/png" "image/gif" "image/webp")
                     :context-window 128
                     :input-cost 2.5
                     :output-cost 10
                     :cutoff-date "2023-10")))))

(ert-deftest gptel-model-updater-metadata-fetch-respects-curl-setting ()
  "Metadata fetching follows `gptel-use-curl'."
  (cl-letf (((symbol-function 'gptel-model-updater-metadata--fetch-with-curl)
             (lambda (_url) 'curl))
            ((symbol-function 'gptel-model-updater-metadata--fetch-with-url)
             (lambda (_url) 'url)))
    (let ((gptel-use-curl t))
      (should (eq (gptel-model-updater-metadata--fetch "https://example.com")
                  'curl)))
    (let ((gptel-use-curl nil))
      (should (eq (gptel-model-updater-metadata--fetch "https://example.com")
                  'url)))))

(ert-deftest gptel-model-updater-metadata-user-host-mapping-wins ()
  "User host mappings override built-in provider mappings."
  (let ((backend (gptel-make-openai "metadata-host-test"
                   :host "api.openai.com"
                   :models '()))
        (gptel-model-updater-provider-host-alist
         '(("api.openai.com" . openrouter))))
    (should (eq (gptel-model-updater-metadata--provider-key
                 backend 'openai '((openai) (openrouter)))
                'openrouter))))

(provide 'gptel-model-updater-tests)
;;; gptel-model-updater-tests.el ends here
