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
  type invokeResult<'a>

  @module("@tauri-apps/api/core")
  external invoke: (string, 'a) => promise<'b> = "invoke"
}

// Validation result from Rust backend
type validationResult = {
  valid: bool,
  errors: array<string>,
  proofs_generated: array<string>,
}

// Generate FQLdt from collection definition
let generateFqldt = async (collection: Collection.t): result<string, string> => {
  try {
    let payload = {
      "name": collection.name,
      "fields": collection.fields->Array.map(f => {
        let (min, max, required) = switch f.fieldType {
        | FieldType.Number({min, max}) => (min, max, false)
        | FieldType.Text({required}) => (None, None, required)
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
    let result = await Tauri.invoke("generate_fqldt", {"collection": payload})
    Ok(result)
  } catch {
  | Exn.Error(e) => Error(Exn.message(e)->Option.getOr("Unknown error"))
  }
}

// Validate FQLdt code
let validateFqldt = async (code: string): result<validationResult, string> => {
  try {
    let result = await Tauri.invoke("validate_fqldt", {"code": code})
    Ok(result)
  } catch {
  | Exn.Error(e) => Error(Exn.message(e)->Option.getOr("Unknown error"))
  }
}

// Main App component
@react.component
let make = () => {
  let (collection, setCollection) = React.useState(() => Collection.empty())
  let (validationState, setValidationState) = React.useState(() => FqldtPreview.NotValidated)

  let handleUpdateName = name => {
    setCollection(prev => {...prev, name})
  }

  let handleAddField = (field: Field.t) => {
    setCollection(prev => {
      ...prev,
      fields: prev.fields->Array.concat([field]),
    })
  }

  let handleRemoveField = index => {
    setCollection(prev => {
      ...prev,
      fields: prev.fields->Array.filterWithIndex((_, i) => i != index),
    })
  }

  // Auto-validate when collection changes
  React.useEffect1(() => {
    if collection.name != "" && Array.length(collection.fields) > 0 {
      setValidationState(_ => FqldtPreview.Validating)

      let _ = generateFqldt(collection)->Promise.then(result => {
        switch result {
        | Ok(code) =>
          validateFqldt(code)->Promise.then(validResult => {
            switch validResult {
            | Ok(r) =>
              if r.valid {
                setValidationState(_ => FqldtPreview.Valid(r.proofs_generated))
              } else {
                setValidationState(_ => FqldtPreview.Invalid(r.errors))
              }
            | Error(e) => setValidationState(_ => FqldtPreview.Invalid([e]))
            }
            Promise.resolve()
          })
        | Error(e) =>
          setValidationState(_ => FqldtPreview.Invalid([e]))
          Promise.resolve()
        }
      })->ignore
    } else {
      setValidationState(_ => FqldtPreview.NotValidated)
    }
    None
  }, [collection])

  <div className="formdb-studio">
    <header>
      <h1> {React.string("FormDB Studio")} </h1>
      <p> {React.string("Zero-friction interface for dependently-typed databases")} </p>
    </header>
    <main>
      <SchemaBuilder
        collection
        onUpdateName={handleUpdateName}
        onAddField={handleAddField}
        onRemoveField={handleRemoveField}
      />
      <FqldtPreview collection validationState />
    </main>
  </div>
}
