# Load necessary libraries
library(tools) # For parsing R code

# Define the paths to the directories and NAMESPACE file
# target_dir_path: The directory we're searching for function usage in
# source_dir_path: The directory we're extracting function names from
# namespace_path: The path to the NAMESPACE file of the source package
target_dir_path <- "modules/target_package/R"
source_dir_path <- "modules/source_package/R"
namespace_path <- "modules/source_package/NAMESPACE"

# Function to extract exported function names from NAMESPACE
# @param namespace_path: The path to the NAMESPACE file
# @return: A vector of exported function names
extract_exported_functions <- function(namespace_path) {
  lines <- readLines(namespace_path, warn = FALSE)
  exported <- grep("export\\(", lines, value = TRUE)
  exported_funcs <- gsub("export\\((.*)\\)", "\\1", exported)
  return(exported_funcs)
}

# Function to extract function names from R files
# @param source_dir_path: The path to the directory containing the R files
# @param exported_funcs: A vector of exported function names
# @return: A vector of function names that are both called in the R files and exported
extract_function_names <- function(source_dir_path, exported_funcs) {
  files <- list.files(source_dir_path, pattern = "\\.R$", full.names = TRUE)
  function_names <- c()
  for (file in files) {
    code <- readLines(file, warn = FALSE)
    funcs <- getParseData(parse(text = code), includeText = TRUE)
    if (!is.null(funcs)) {
      funcs <- funcs[funcs$token == "SYMBOL_FUNCTION_CALL", ]
      function_names <- c(function_names, unique(funcs$text))
    }
  }
  # Filter only exported functions
  function_names <- intersect(function_names, exported_funcs)
  return(unique(function_names))
}

# Function to find usage of the functions in target files
# @param target_dir_path: The path to the directory containing the target R files
# @param source_functions: A vector of function names to search for
# @return: A list where each element is a vector of R files that call a particular function
find_function_usage <- function(target_dir_path, source_functions) {
  files <- list.files(target_dir_path, pattern = "\\.R$", full.names = TRUE)
  usage_list <- list()
  for (file in files) {
    code <- readLines(file, warn = FALSE)
    for (source_function in source_functions) {
      if (grepl(paste0("\\b", source_function, "\\b"), paste(code, collapse = "\n"))) {
        usage_list[[source_function]] <- c(usage_list[[source_function]], basename(file))
      }
    }
  }
  return(usage_list)
}

# Extract exported functions from NAMESPACE
exported_source_functions <- extract_exported_functions(namespace_path)

# Extract function names from source package
source_functions <- extract_function_names(source_dir_path, exported_source_functions)

# Find and list the usage
usage <- find_function_usage(target_dir_path, source_functions)

# Print the result
print(usage)
