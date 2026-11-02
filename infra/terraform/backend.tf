terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/88388628/terraform/state/lab"
    lock_address   = "https://gitlab.com/api/v4/projects/88388628/terraform/state/lab/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/88388628/terraform/state/lab/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
    username       = "vinhthang"
    password       = "glpat-buMpEqRy0k1v5pjd9KR3k2M6MQpvOjEKdTpxNnZwaA8.01.171ssa8ph"
  }
}