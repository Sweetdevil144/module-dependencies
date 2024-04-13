library(stringr)

# Recursively list all files in a directory with a specific extension
list_files_with_extension <- function(path, extension) {
  files <- list.files(path, pattern = paste0("\\.", extension, "$"), full.names = TRUE, recursive = TRUE)
  files <- files[!grepl("/tests/", files)]
  return(files)
}

# Function to extract unique PEcAn dependencies from a file
extract_pecan_dependencies <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  matches <- lines[grepl("PEcAn\\.[[:alnum:]\\.]+::[[:alnum:]_]+", lines)]
  pecan_calls <- str_extract_all(matches, "PEcAn\\.[[:alnum:]\\.]+::[[:alnum:]_]+")
  results <- list()
  for (calls in pecan_calls) {
    if (length(calls) > 0) {
      for (call in unique(calls)) {
        pkg_function <- str_split(call, "::", simplify = TRUE)
        if (length(pkg_function) == 2) {
          pkg <- pkg_function[1]
          func <- pkg_function[2]
          results[[pkg]] <- unique(c(func, results[[pkg]]))
        }
      }
    }
  }
  return(results)
}

# Main function to process all R files and extract dependencies
process_project_files <- function(project_path) {
  r_files <- list_files_with_extension(project_path, "R")
  all_deps <- data.frame(File = character(), Package = character(), Function = character(), stringsAsFactors = FALSE)

  for (file in r_files) {
    pecan_imports <- extract_pecan_dependencies(file)
    if (length(pecan_imports) > 0) {
      for (pkg in names(pecan_imports)) {
        for (func in pecan_imports[[pkg]]) {
          all_deps <- rbind(all_deps, data.frame(File = file, Package = pkg, Function = func))
        }
      }
    }
  }

  # Write results to CSV
  write.csv(all_deps, file = "pecan_dependencies.csv", row.names = FALSE)
  print("Results saved to 'pecan_dependencies.csv'")
}


process_project_files("../")
