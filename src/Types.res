// SPDX-License-Identifier: AGPL-3.0-or-later
// FormDB Studio - Shared Types

module FieldType = {
  type t =
    | Number({min: option<int>, max: option<int>})
    | Text({required: bool})
    | Confidence
    | PromptScores

  let toString = (t: t) =>
    switch t {
    | Number(_) => "number"
    | Text(_) => "text"
    | Confidence => "confidence"
    | PromptScores => "prompt_scores"
    }
}

module Field = {
  type t = {
    name: string,
    fieldType: FieldType.t,
  }
}

module Collection = {
  type t = {
    name: string,
    fields: array<Field.t>,
  }

  let empty = () => {
    name: "",
    fields: [],
  }
}

// Tauri command bindings
module Tauri = {
  type invokeResult<'a>

  @module("@tauri-apps/api/core")
  external invoke: (string, 'a) => promise<'b> = "invoke"
}

// Validation state for FQLdt preview
type validationState =
  | NotValidated
  | Validating
  | Valid(array<string>)
  | Invalid(array<string>)
