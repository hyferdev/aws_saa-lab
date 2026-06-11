# Day 1 "hello world": a free, harmless resource that proves the whole loop
# (PR -> plan -> merge -> apply) works. Delete it on Day 2 when the real
# project resources start landing here.
resource "aws_ssm_parameter" "pipeline_smoke_test" {
  name  = "/saa-sprint/pipeline-check"
  type  = "String"
  value = "Hello from terraform via github actions oidc"
}

output "smoke_test_value" {
  value = aws_ssm_parameter.pipeline_smoke_test.value
}
