;;; gptel-model-updater-ui.el --- UI helpers for gptel-model-updater -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Misaka

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Completion and display helpers for gptel-model-updater.

;;; Code:

(defcustom gptel-model-updater-ui-annotation-column-widths
  '((model . 40)
    (description . 52)
    (capabilities . 58)
    (context-window . 8)
    (input-cost . 11)
    (output-cost . 13)
    (cutoff-date . nil))
  "Column widths used for model completion annotations.
The `model' width controls the column where annotations begin.  Other widths
control metadata columns in order.  A nil width means do not truncate that
column."
  :type '(alist :key-type (choice (const model)
                                  (const description)
                                  (const capabilities)
                                  (const context-window)
                                  (const input-cost)
                                  (const output-cost)
                                  (const cutoff-date))
                :value-type (choice (const :tag "No truncation" nil)
                                    (integer :tag "Columns")))
  :group 'gptel-model-updater)

(defun gptel-model-updater-ui--annotation-column-width (column)
  "Return configured annotation width for COLUMN."
  (cdr (assq column gptel-model-updater-ui-annotation-column-widths)))

(defun gptel-model-updater-ui--annotation-column-end (start column)
  "Return column end from START using configured width for COLUMN."
  (+ start (or (gptel-model-updater-ui--annotation-column-width column) 0)))

(defun gptel-model-updater-ui--annotation-align-to (column)
  "Return a display space aligned to COLUMN."
  (propertize " " 'display `(space :align-to ,column)))

(defun gptel-model-updater-ui--annotation-truncate (text column)
  "Return TEXT truncated to fit configured width for COLUMN."
  (when text
    (let ((width (gptel-model-updater-ui--annotation-column-width column)))
      (if (integerp width)
          (truncate-string-to-width text (max 0 (- width 2)) nil nil t)
        text))))

(defun gptel-model-updater-ui--format-model-annotation (model)
  "Return completion annotation for MODEL metadata."
  (let ((desc (get model :description))
        (caps (get model :capabilities))
        (context (get model :context-window))
        (input-cost (get model :input-cost))
        (output-cost (get model :output-cost))
        (cutoff (get model :cutoff-date)))
    (when (or desc caps context input-cost output-cost cutoff)
      (let* ((desc-column (or (gptel-model-updater-ui--annotation-column-width
                               'model)
                              40))
             (caps-column (gptel-model-updater-ui--annotation-column-end
                           desc-column 'description))
             (context-column (gptel-model-updater-ui--annotation-column-end
                              caps-column 'capabilities))
             (input-cost-column (gptel-model-updater-ui--annotation-column-end
                                 context-column 'context-window))
             (output-cost-column (gptel-model-updater-ui--annotation-column-end
                                  input-cost-column 'input-cost))
             (cutoff-column (gptel-model-updater-ui--annotation-column-end
                             output-cost-column 'output-cost)))
        (concat
         (gptel-model-updater-ui--annotation-align-to desc-column)
         (gptel-model-updater-ui--annotation-truncate desc 'description)
         " " (gptel-model-updater-ui--annotation-align-to caps-column)
         (gptel-model-updater-ui--annotation-truncate
          (when caps (prin1-to-string caps)) 'capabilities)
         " " (gptel-model-updater-ui--annotation-align-to context-column)
         (gptel-model-updater-ui--annotation-truncate
          (when context (format "%5dk" context)) 'context-window)
         " " (gptel-model-updater-ui--annotation-align-to input-cost-column)
         (gptel-model-updater-ui--annotation-truncate
          (when input-cost (format "$%5.2f in" input-cost)) 'input-cost)
         (if (and input-cost output-cost) "," " ")
         " " (gptel-model-updater-ui--annotation-align-to output-cost-column)
         (gptel-model-updater-ui--annotation-truncate
          (when output-cost (format "$%6.2f out" output-cost)) 'output-cost)
         " " (gptel-model-updater-ui--annotation-align-to cutoff-column)
         (gptel-model-updater-ui--annotation-truncate cutoff 'cutoff-date))))))

(provide 'gptel-model-updater-ui)
;;; gptel-model-updater-ui.el ends here
