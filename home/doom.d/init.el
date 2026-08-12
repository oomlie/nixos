;;; init.el -*- lexical-binding: t; -*-

(doom! :input

       :completion
       (vertico +icons)
       corfu

       :ui
       doom
       doom-dashboard
       doom-quit
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets

       :emacs
       dired
       electric
       undo
       vc

       :checkers
       syntax

       :tools
       (eval +overlay)
       lookup
       magit
       lsp
       tree-sitter

       :lang
       emacs-lisp
       (nix +lsp +tree-sitter)
       (rust +lsp +tree-sitter)
       (org)
       markdown
       sh
       gdscript

       :config
       (default +bindings +smartparens))
