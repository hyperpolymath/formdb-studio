// SPDX-License-Identifier: AGPL-3.0-or-later
// FormDB Studio - Main Application

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
  @module("@tauri-apps/api/core")
  external invoke: (string, 'a) => promise<'b> = "invoke"
}

// Generate FQLdt from collection definition
let generateFqldt = async (collection: Collection.t) => {
  let payload = {
    "name": collection.name,
    "fields": collection.fields->Array.map(f => {
      let (min, max, required) = switch f.fieldType {
      | Number({min, max}) => (min, max, false)
      | Text({required}) => (None, None, required)
      | _ => (None, None, false)
      }
      {
        "name": f.name,
        "field_type": f.fieldType->FieldType.toString,
        "min": min,
        "max": max,
        "required": required,
      }
    }),
  }
  await Tauri.invoke("generate_fqldt", {"collection": payload})
}

// Main App component (placeholder)
@react.component
let make = () => {
  <div className="formdb-studio">
    <header>
      <h1>{React.string("FormDB Studio")}</h1>
      <p>{React.string("Zero-friction interface for dependently-typed databases")}</p>
    </header>
    <main>
      <section className="schema-builder">
        <h2>{React.string("Create Collection")}</h2>
        <p>{React.string("Schema builder UI coming soon...")}</p>
      </section>
    </main>
  </div>
}
