modify_correlation_cholesky <- function(data, target_rho) {
  sigma_target <- matrix(c(1, target_rho, target_rho, 1), nrow=2)  # Target correlation matrix
  L_orig <- chol(cor(data))  # Cholesky decomposition of original correlation
  L_target <- chol(sigma_target)  # Cholesky decomposition of target correlation
  transformed_data <- data %*% solve(L_orig) %*% L_target  # Apply transformation
  return(transformed_data)
}

modify_correlation_cholesky_3d <- function(data, sigma_target) {
  L_orig <- chol(cor(data))  # Cholesky decomposition of original correlation
  L_target <- chol(sigma_target)  # Cholesky decomposition of target correlation
  transformed_data <- data %*% solve(L_orig) %*% L_target  # Apply transformation
  return(transformed_data)
}

# Example usage:
# new_correlation <- 0.3  # Change correlation
# transformed_data_cholesky <- modify_correlation_cholesky(orig_data, new_correlation)
# cor(transformed_data_cholesky)  # Check new correlation
