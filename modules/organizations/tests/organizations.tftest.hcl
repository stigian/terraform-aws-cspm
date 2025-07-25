# Organizations Module Unit Tests

provider "aws" {
  region  = "us-gov-west-1"
  profile = "cnscca-gov-mgmt"
}

# Test 1: Basic configuration with new account_type field
run "basic_configuration" {
  command = plan

  variables {
    project               = "test-org"
    control_tower_enabled = false
    aws_account_parameters = {
      "123456789012" = {
        name         = "Test-Management"
        email        = "mgmt@test.com"
        ou           = "Root"
        lifecycle    = "prod"
        account_type = "management"
      }
    }
  }

  assert {
    condition     = var.project == "test-org"
    error_message = "Project variable should be set correctly"
  }

  assert {
    condition     = var.aws_account_parameters["123456789012"].account_type == "management"
    error_message = "account_type field should be accessible"
  }
}

# Test 2: Prod/NonProd lifecycle validation
run "lifecycle_validation" {
  command = plan

  variables {
    project               = "lifecycle-test"
    control_tower_enabled = false
    aws_account_parameters = {
      "123456789012" = {
        name         = "Prod-Account"
        email        = "prod@test.com"
        ou           = "Workloads_Prod"
        lifecycle    = "prod"
        account_type = "workload"
      }
      "234567890123" = {
        name         = "NonProd-Account"
        email        = "nonprod@test.com"
        ou           = "Workloads_NonProd"
        lifecycle    = "nonprod"
        account_type = "workload"
      }
    }
    organizational_units = {
      "Workloads_Prod"    = { lifecycle = "prod" }
      "Workloads_NonProd" = { lifecycle = "nonprod" }
    }
  }

  assert {
    condition     = length(var.aws_account_parameters) == 2
    error_message = "Should accept both prod and nonprod lifecycles"
  }

  assert {
    condition     = var.aws_account_parameters["123456789012"].lifecycle == "prod"
    error_message = "Prod lifecycle should be valid"
  }

  assert {
    condition     = var.aws_account_parameters["234567890123"].lifecycle == "nonprod"
    error_message = "NonProd lifecycle should be valid"
  }
}

# Test 3: Control Tower validation with required account types
run "control_tower_validation" {
  command = plan

  variables {
    project               = "ct-test"
    control_tower_enabled = true
    aws_account_parameters = {
      "123456789012" = {
        name         = "Management-Account"
        email        = "mgmt@test.com"
        ou           = "Root"
        lifecycle    = "prod"
        account_type = "management"
      }
      "234567890123" = {
        name         = "LogArchive-Account"
        email        = "logs@test.com"
        ou           = "Security"
        lifecycle    = "prod"
        account_type = "log_archive"
      }
      "345678901234" = {
        name         = "Audit-Account"
        email        = "audit@test.com"
        ou           = "Security"
        lifecycle    = "prod"
        account_type = "audit"
      }
    }
    organizational_units = {
      "Security" = { lifecycle = "prod" }
    }
  }

  assert {
    condition = length([
      for account_id, account in var.aws_account_parameters : account
      if account.account_type == "management"
    ]) >= 1
    error_message = "Should have management account for Control Tower"
  }

  assert {
    condition = length([
      for account_id, account in var.aws_account_parameters : account
      if account.account_type == "log_archive"
    ]) >= 1
    error_message = "Should have log_archive account for Control Tower"
  }

  assert {
    condition = length([
      for account_id, account in var.aws_account_parameters : account
      if account.account_type == "audit"
    ]) >= 1
    error_message = "Should have audit account for Control Tower"
  }
}

# Test 4: Invalid lifecycle should fail
run "invalid_lifecycle_fails" {
  command = plan

  variables {
    project               = "invalid-test"
    control_tower_enabled = false
    aws_account_parameters = {
      "123456789012" = {
        name         = "Test-Account"
        email        = "test@example.com"
        ou           = "Root"
        lifecycle    = "development"  # Invalid - not prod or nonprod
        account_type = "workload"
      }
    }
  }

  expect_failures = [
    var.aws_account_parameters
  ]
}

# Test 5: Invalid email format should fail
run "invalid_email_fails" {
  command = plan

  variables {
    project               = "email-test" 
    control_tower_enabled = false
    aws_account_parameters = {
      "123456789012" = {
        name         = "Test-Account"
        email        = "invalid-email"  # Missing @ and domain
        ou           = "Root"
        lifecycle    = "prod"
        account_type = "workload"
      }
    }
  }

  expect_failures = [
    var.aws_account_parameters
  ]
}
