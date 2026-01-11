// SPDX-License-Identifier: AGPL-3.0-or-later
//! FormDB Studio - Zero-friction interface for FormDB with FQLdt
//!
//! This is the Tauri backend that bridges the ReScript UI to FormDB.

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};

/// Schema field definition from the UI
#[derive(Debug, Serialize, Deserialize)]
pub struct FieldDef {
    pub name: String,
    pub field_type: String,
    pub min: Option<i64>,
    pub max: Option<i64>,
    pub required: bool,
}

/// Collection definition from the UI
#[derive(Debug, Serialize, Deserialize)]
pub struct CollectionDef {
    pub name: String,
    pub fields: Vec<FieldDef>,
}

/// Generate FQLdt code from a visual collection definition
#[tauri::command]
fn generate_fqldt(collection: CollectionDef) -> Result<String, String> {
    let mut fql = format!(
        "CREATE COLLECTION {} (\n  id : UUID",
        collection.name
    );

    for field in &collection.fields {
        let type_str = match field.field_type.as_str() {
            "number" => {
                if let (Some(min), Some(max)) = (field.min, field.max) {
                    format!("BoundedNat {} {}", min, max)
                } else {
                    "Int".to_string()
                }
            }
            "text" => {
                if field.required {
                    "NonEmptyString".to_string()
                } else {
                    "Option String".to_string()
                }
            }
            "confidence" => "Confidence".to_string(),
            "prompt_scores" => "PromptScores".to_string(),
            _ => "String".to_string(),
        };

        fql.push_str(&format!(",\n  {} : {}", field.name, type_str));
    }

    fql.push_str("\n) WITH DEPENDENT_TYPES, PROVENANCE_TRACKING;");

    Ok(fql)
}

/// Validate FQLdt code using Lean 4 type checker
#[tauri::command]
fn validate_fqldt(code: String) -> Result<ValidationResult, String> {
    // TODO: Call Lean 4 via subprocess or FFI
    // For now, return a placeholder
    Ok(ValidationResult {
        valid: true,
        errors: vec![],
        proofs_generated: vec!["score_in_bounds".to_string()],
    })
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
    pub proofs_generated: Vec<String>,
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            generate_fqldt,
            validate_fqldt,
        ])
        .run(tauri::generate_context!())
        .expect("error while running FormDB Studio");
}
