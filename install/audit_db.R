library(DBI)
library(RSQLite)
library(jsonlite)

audit_ss_db <- function(ss_conn) {
  # Get all tables
  all_tables <- DBI::dbListTables(ss_conn)

  # Iterate through the tables
  for (table in all_tables) {
    message("\n🔍 Auditing table: ", table)

    # Read the full table
    df <- DBI::dbReadTable(ss_conn, table)

    # Check for duplicate team_abbr values
    dupes <- df[duplicated(df$team_abbr), ]

    # If there are any, the size will be great than zero
    if (nrow(dupes) > 0) {
      cat("Duplicates found in", table, "\n")
    } else {
      cat("No duplicates found in", table, "\n")
    }
  }
}

audit_team_pbp_db <- function(team_conn) {
  tables <- DBI::dbListTables(team_conn)

  for (table in tables) {
    cat("Cleaning table:", table, "\n")

    df <- DBI::dbReadTable(team_conn, table)
    orig_size <- nrow(df)

    # Remove rows with NA in designated columns
    df_clean <- df[!is.na(df$game_id) & !is.na(df$play_id), ]

    # Create unique key by attaching these identifiers
    combo_key <- paste(df_clean$game_id, df_clean$play_id, sep = "_")

    # Keep only the first occurrence of each (game_id, play_id) combo
    df_unique <- df_clean[!duplicated(combo_key), ]

    # Optional: make a backup of the original table
    backup_table <- paste0(table, "_backup")
    if (!backup_table %in% tables) {
      DBI::dbWriteTable(team_conn, backup_table, df)
      cat("🛟 Backup created as:", backup_table, "\n")
    }

    # Overwrite the original table with the cleaned version
    DBI::dbWriteTable(team_conn, table, df_unique, overwrite = TRUE)
    new_size <- nrow(df_unique)
    cat("✅ Cleaned:", table,
        "\n-> Original Row Num:", orig_size,
        "\n→ Rows kept:", new_size,
        "\n-> Rows removed:", (orig_size - new_size), "\n\n")

    # Immediately remove the backup table
    DBI::dbRemoveTable(team_conn, backup_table)
    cat("🗑️  Removed backup table:", backup_table, "\n\n")
  }
}

