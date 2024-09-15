locals {
  public_repos = {
      aws_github       = {
          description = "github repo configurations with terraform"
      }
      aws_organization = {
          description = "AWS organization config with terraform"
      }
  }
}

resource "github_repository" "public" {
    for_each = local.public_repos

    name = replace(each.key, "_", "-")
    description                 = each.value.description
    visibility                  = "public"
    license_template            = "mit"
    gitignore_template = "terraform"
    allow_auto_merge            = false
    allow_squash_merge          = true
    squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
    squash_merge_commit_message = "COMMIT_MESSAGES"
    allow_merge_commit          = false
    allow_rebase_merge          = false
    allow_update_branch         = true
    delete_branch_on_merge      = true
    archive_on_destroy          = true
    has_issues                  = true
    has_discussions             = false
    has_projects                = false
    has_wiki                    = false
    has_downloads               = false
    auto_init                   = true
    vulnerability_alerts        = true
    security_and_analysis {
        secret_scanning {
            status = "enabled"
        }
        secret_scanning_push_protection {
            status = "enabled"
        }
    }
}

resource "github_branch" "public_main" {
    for_each = element(github_repository.public[*], 0)

    repository = each.value.name
    branch     = "main"
}

resource "github_branch_default" "public_main" {
    for_each = element(github_repository.public[*], 0)

    repository = each.value.name
    branch     = github_branch.public_main[each.key].branch
}

resource "github_branch_protection" "public_main" {
    for_each = element(github_repository.public[*], 0)

    repository_id           = each.value.node_id
    pattern                 = "main"
    required_linear_history = true
    allows_deletions        = false
    allows_force_pushes     = false
    force_push_bypassers    = [data.github_user.ryanemcdaniel.node_id]
    required_pull_request_reviews {
        require_code_owner_reviews      = true
        required_approving_review_count = 1
        require_last_push_approval      = true
        dismiss_stale_reviews           = true
        restrict_dismissals             = true
        dismissal_restrictions          = ["/${data.github_user.ryanemcdaniel.username}"]
        pull_request_bypassers          = ["/${data.github_user.ryanemcdaniel.username}"]
    }
    required_status_checks {
        strict = true
    }
}

import {
    id = "aws-github"
    to = github_repository.public["aws_github"]
}