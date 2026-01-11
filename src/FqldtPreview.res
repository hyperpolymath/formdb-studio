// SPDX-License-Identifier: AGPL-3.0-or-later
// FormDB Studio - FQLdt Preview Component

open App

type validationState =
  | NotValidated
  | Validating
  | Valid(array<string>)
  | Invalid(array<string>)

let fieldTypeToFqldt = (ft: FieldType.t): string => {
  switch ft {
  | Number({min: Some(min), max: Some(max)}) => `BoundedNat ${Int.toString(min)} ${Int.toString(max)}`
  | Number({min: Some(min), max: None}) => `Nat (>= ${Int.toString(min)})`
  | Number({min: None, max: Some(max)}) => `Nat (<= ${Int.toString(max)})`
  | Number(_) => "Int"
  | Text({required: true}) => "NonEmptyString"
  | Text({required: false}) => "Option String"
  | Confidence => "Confidence"
  | PromptScores => "PromptScores"
  }
}

let generateFqldtCode = (collection: Collection.t): string => {
  if collection.name == "" {
    "-- Enter a collection name to see generated FQLdt"
  } else {
    let fieldsCode =
      collection.fields
      ->Array.map(f => `  ${f.name} : ${fieldTypeToFqldt(f.fieldType)}`)
      ->Array.join(",\n")

    let fieldsSection = if Array.length(collection.fields) > 0 {
      `,\n${fieldsCode}`
    } else {
      ""
    }

    `CREATE COLLECTION ${collection.name} (
  id : UUID${fieldsSection}
) WITH DEPENDENT_TYPES, PROVENANCE_TRACKING;`
  }
}

@react.component
let make = (~collection: Collection.t, ~validationState: validationState) => {
  let code = generateFqldtCode(collection)

  <aside className="fqldt-preview">
    <h2> {React.string("Generated FQLdt")} </h2>
    <div className="code-block">
      <pre> {React.string(code)} </pre>
    </div>
    {switch validationState {
    | NotValidated => React.null
    | Validating =>
      <div className="validation-status">
        {React.string("Validating...")}
      </div>
    | Valid(proofs) =>
      <div className="validation-status valid">
        <span className="icon"> {React.string({js|✓|js})} </span>
        <span>
          {React.string(`Types verified. ${Int.toString(Array.length(proofs))} proofs generated.`)}
        </span>
      </div>
    | Invalid(errors) =>
      <div className="validation-status invalid">
        <span className="icon"> {React.string({js|✗|js})} </span>
        <span> {React.string(errors->Array.join(", "))} </span>
      </div>
    }}
    <div className="actions-bar">
      <button className="btn btn-secondary">
        {React.string("Copy Code")}
      </button>
      <button className="btn btn-primary">
        {React.string("Create Collection")}
      </button>
    </div>
  </aside>
}
